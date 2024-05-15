create or replace package PKG_MERGE_DATOS_VTEX is

  -- Author  : CMALDONADO
  -- Created : 12/11/2020 7:43:10 a. m.
  -- Purpose : para manejar los datos de integraci�n con plataforma VTEX
  
   type cursor_type Is Ref Cursor;

  type t_product is table of vtexproduct%rowtype index by binary_integer;
  type t_product_pipe is table of vtexproduct%rowtype;
  
  type t_SKU is table of Vtexsku%rowtype index by binary_integer;
  type t_SKU_pipe is table of vtexSKU%rowtype;
  
  FUNCTION GETFACTOR (P_CDARTICULO ARTICULOS_S.CDARTICULO%TYPE) RETURN INTEGER;
  
  Function Pipeproducts Return t_product_pipe pipelined;
  Function PipeSKUS Return t_SKU_pipe pipelined;
  
  PROCEDURE CargarProduct;
  PROCEDURE RefrescarProduct;
  PROCEDURE CargarSKU;
  PROCEDURE RefrescarSKU;  
  PROCEDURE CargarStock;
  

end PKG_MERGE_DATOS_VTEX;
/
create or replace package body PKG_MERGE_DATOS_VTEX is
 g_l_product t_product;
 g_1_SKU t_SKU;
 
/**************************************************************************************************
* prepara una cadena de texto para el estandar URL
* %v 20/11/2020 - ChM 
***************************************************************************************************/
FUNCTION FORMATOURL( S IN VARCHAR2 ) RETURN VARCHAR2 IS

TMP VARCHAR2(255);
BEGIN

     TMP:= LOWER(S);
     TMP:= REPLACE(TMP,' ','-');
     TMP:= REPLACE(TMP,'�','a');
     TMP:= REPLACE(TMP,'�','e');
     TMP:= REPLACE(TMP,'�','i');
     TMP:= REPLACE(TMP,'�','o');
     TMP:= REPLACE(TMP,'�','u');
     TMP:= REPLACE(TMP,'�','a');
     TMP:= REPLACE(TMP,'�','e');
     TMP:= REPLACE(TMP,'�','i');
     TMP:= REPLACE(TMP,'�','o');
     TMP:= REPLACE(TMP,'�','u');
     TMP:= REPLACE(TMP,'�','n');
     TMP:= REGEXP_REPLACE (TMP,'[^a-zA-Z0-9\/_-]','-' );     
     TMP:= REGEXP_REPLACE (TMP,'-+','-' );
     TMP:= REGEXP_REPLACE (TMP,'-?(.*)','\1' );
     TMP:= REGEXP_REPLACE (TMP,'(.*)-$','\1' );
     
     RETURN TMP;
   
END FORMATOURL; 
/**************************************************************************************************
* devuelve el facto del articulo
* %v 20/11/2020 - ChM 
***************************************************************************************************/
  FUNCTION GETFACTOR (P_CDARTICULO ARTICULOS_S.CDARTICULO%TYPE) RETURN INTEGER IS
    V_FACTOR INTEGER:=1;
    BEGIN
      select max(pc.factor) 
        into V_FACTOR 
        from tbllista_precio_central_s pc 
       where pc.cdarticulo=p_cdarticulo;
       RETURN V_FACTOR;
  EXCEPTION
  WHEN OTHERS THEN
    RETURN 1;
END  GETFACTOR;
  
    
/**************************************************************************************************
* Carga en una tabla global en memoria los datos de todos los art�culos activos en AC
* %v 16/11/2020 - ChM 
***************************************************************************************************/
PROCEDURE CargarTablaProduct IS
  v_Modulo varchar2(100) := 'PKG_MERGE_DATOS_VTEX.CargarTablaProduct';
  i        binary_integer := 1;

BEGIN

  for r_product in (  SELECT distinct BB.* FROM
                      (select distinct null productID, 
                             nvl2(trim(ae.vldescripcion),ae.vldescripcion,da.vldescripcion) name,
                             NVL((select 
                             distinct nvl(vc.departmentid,-1) -- -1 NO CATALOGADO
                                 from vtexcatalog vc
                                where vc.departmentname = upper(trim(d.dsdepartamento))
                                   and rownum = 1),-1) departmentID, 
                             NVL((select 
                             distinct NVL(vc.categoryid,-1) -- -1 NO CATALOGADO
                                 from vtexcatalog vc
                                where vc.categoryname = upper(trim(u.dsuniverso))
                                   and rownum = 1),-1) categoryID,  
                             NVL((select 
                                distinct NVL(vc.subcategoryid,-1) -- -1 NO CATALOGADO
                                 from vtexcatalog vc
                                where  vc.subcategoryname =upper(trim(c.dscategoria))
                                   and rownum = 1),-1) subcategoryID,                
                             NVL((select 
                             distinct NVL(vb.brandid,-1)  -- -1 SIN MARCA
                                 from vtexbrand vb
                                where upper(trim(ae.vlmarca))=vb.name
                                  and rownum = 1),-1) Brandid,
                             nvl2(trim(ae.vldescripcion),ae.vldescripcion,da.vldescripcion)||'-'||to_number(ar.cdarticulo) linkid,
                             ar.cdarticulo refid,
                             --estado 07 articulo activo pero no visible al cliente
                             DECODE(ar.cdestadoplu,'07',0,1) isvisible,  
                             nvl2(trim(ae.vldescripcion),ae.vldescripcion,da.vldescripcion) description,
                             ar.dtinsertplu releasedate,
                             1 isactive,  
                             1 icnuevo,
                             sysdate dtinsert,
                             null dtupdate,
                             case
                              when exists (select 1 from tbl_aux_art_unidad au
                                           where au.dsuniverso = u.dsuniverso
                                           and au.dscategoria = c.dscategoria
                                           and au.dssubcategoria = sc.dssubcategoria
                                           )
                                    or ar.cdunidadventaminima not in ('BTO','UN') -- son pesables
                                then GETFACTOR(ar.cdarticulo)
                              else null                                 
                              end  factor, 
                             n_pkg_vitalpos_materiales_s.GetUxB(ar.cdarticulo) UXB,                            
                             null observacion,
                             0 icprocesado, --indica se debe procesar a VTEX
                             null dtprocesado                              
                       from articulos_s                    ar,
                            descripcionesarticulos_s       da,
                            tblarticulonombreecommerce_s   ae,
                            tblctgryarticulocategorizado_s a,
                            tblctgrydepartamento_s         d,
                            tblctgryuniverso_s             u,
                            tblctgrycategoria_s            c,
                            tblctgrysubcategoria_s         sc,
                            tblctgrysegmento_s             s,
                            tblctgrysubsegmento_s          ss,
                            tblctgrysectorc_S              tse,
                            tblivaarticulo_s               tiva
                      where ar.cdarticulo = da.cdarticulo                        
                        and ar.cdestadoplu in('00','07')  --OJO 00 activo para la venta 07 no visible 03 articulo desactivado permanentemente
                        and tiva.cdarticulo(+) = ar.cdarticulo
                        and not exists
                      (select 1
                               from articulosnocomerciales_s t
                              where t.cdarticulo = a.cdarticulo)
                        and not exists
                      (select 1
                               from articulos_excluidos h
                              where h.cdarticulo = ar.cdarticulo) --agrego tabla articulos excluidos 
                        and substr(ar.cdarticulo, 1, 1) <> 'A'
                        and a.cdarticulo = ae.cdarticulo (+)
                        and a.cddepartamento = d.cddepartamento(+)
                        and a.cduniverso = u.cduniverso(+)
                        and a.cdcategoria = c.cdcategoria(+)
                        and a.cdsubcategoria = sc.cdsubcategoria(+)
                        and a.cdsegmento = s.cdsegmento(+)
                        and a.cdsubsegmento = ss.cdsubsegmento(+)
                        and a.cdsectorc = tse.cdserctorc
                        and a.cdarticulo = ar.cdarticulo
                        and ar.cddrugstore not in ('EX', 'DE', 'CP'))BB
                         -- validacion para listar solo articulos catalogados en VTEX
                   WHERE TO_CHAR(BB.DEPARTMENTID||BB.CATEGORYID||BB.SUBCATEGORYID) IN (SELECT TO_CHAR(VC.DEPARTMENTID||VC.CATEGORYID||VC.SUBCATEGORYID) 
                                                                                         FROM  VTEXCATALOG  VC)
                     --excluyo los no catalogados
                     AND BB.DEPARTMENTID<>-1
                     AND BB.CATEGORYID<> -1 
                     AND BB.SUBCATEGORYID<>-1
                     AND BB.BRANDID <> -1) loop
                    
    g_l_product(i).productid := r_product.productid;
    g_l_product(i).name := r_product.name;
    g_l_product(i).departmentid := r_product.departmentid;
    g_l_product(i).categoryid := r_product.categoryid;
    g_l_product(i).subcategoryid := r_product.subcategoryid;
    g_l_product(i).brandid := r_product.brandid;
    g_l_product(i).linkid := r_product.linkid;
    g_l_product(i).refid := r_product.refid;
    g_l_product(i).isvisible := r_product.isvisible;
    g_l_product(i).description := r_product.description;
    g_l_product(i).releasedate := r_product.releasedate;
    g_l_product(i).isactive := r_product.isactive;
    g_l_product(i).icnuevo := r_product.icnuevo;
    g_l_product(i).dtinsert := r_product.dtinsert;
    g_l_product(i).dtupdate := r_product.dtupdate;
    g_l_product(i).factor := r_product.factor;
    --valida uxb
    if r_product.uxb = 1 then
      r_product.uxb:=null;
    end if;  
    g_l_product(i).uxb := r_product.uxb;
    g_l_product(i).observacion := r_product.observacion;
    g_l_product(i).icprocesado := r_product.icprocesado;
    g_l_product(i).dtprocesado := r_product.dtprocesado;
    i := i + 1;
  end loop;

EXCEPTION
  WHEN OTHERS THEN
    pkg_log_general.write(1,
                          'Modulo: ' || v_Modulo || '  Error: ' || SQLERRM);
END  CargarTablaProduct;

/**************************************************************************************************
* Devuelve todos los datos de la tabla de VTEXPRODUCT en memoria
* %v 16/11/2020 - ChM
***************************************************************************************************/
FUNCTION Pipeproducts RETURN t_product_pipe
  PIPELINED IS
  i binary_integer := 0;
BEGIN
  i := g_l_product.FIRST;
  while i is not null loop
    pipe row(g_l_product(i));
    i := g_l_product.NEXT(i);
  end loop;
  return;
EXCEPTION
  when others then
    null;
END Pipeproducts;

/**************************************************************************************************
* Carga datos de todas los articulos para la carga inicial de productos de VTEXPRODUCT
* %v 16/11/2020 - ChM
***************************************************************************************************/
PROCEDURE CargarProduct IS
  v_Modulo varchar2(100) := 'PKG_MERGE_DATOS_VTEX.CargarProduct';

BEGIN

  execute immediate 'truncate table vtexproduct';
  g_l_product.delete;
  -- llena la tabla en memoria
  CargarTablaproduct;
  -- la inserta en la definitiva
  insert into vtexproduct
    select * From Table(Pipeproducts);

  commit;

EXCEPTION
  WHEN OTHERS THEN
    pkg_log_general.write(1,
                          'Modulo: ' || v_Modulo || '  Error: ' || SQLERRM);
END CargarProduct;

/**************************************************************************************************
* Carga productos nuevos y actualiza los modificados de la tabla VTEXPRODUCT
* Si el articulo esta activo (1) en VTEX y se dio de Baja en AC (03) tambien actualiza la baja a VTEX (0)
* %v 16/11/2020 - ChM
***************************************************************************************************/
PROCEDURE RefrescarProduct IS
  v_Modulo varchar2(100) := 'PKG_MERGE_DATOS_VTEX.RefrescarProduct';

BEGIN

  g_l_product.delete;
  -- llena la tabla en memoria con los articulos activos de AC
  CargarTablaProduct;
  -- la inserta en una temporal para despues comparar

      insert into tmp_vtexproduct
       select productid,
              name,
              departmentid,
              categoryid,
              subcategoryid,
              brandid,
              linkid,
              refid,
              isvisible,
              description,
              releasedate,
              isactive,
              icnuevo,
              dtinsert,
              dtupdate,
              factor,
              uxb,
              observacion,
              icprocesado,
              dtprocesado      
        From Table(Pipeproducts);

  -- no hago commit porque elimina los datos cargados -- commit;

  merge into vtexproduct vp
  using tmp_vtexproduct tvp
  on (vp.refid = tvp.refid)
  when not matched then -- altas
    insert
      (productid,
      name,
      departmentid,
      categoryid,
      subcategoryid,
      brandid,
      linkid,
      refid,
      isvisible,
      description,
      releasedate,
      isactive,
      icnuevo,
      dtinsert,
      dtupdate,
      factor,
      uxb,
      observacion,
      icprocesado,
      dtprocesado)
    values
      (tvp.productid,
      tvp.name,
      tvp.departmentid,
      tvp.categoryid,
      tvp.subcategoryid,
      tvp.brandid,
      tvp.linkid,
      tvp.refid,
      tvp.isvisible,
      tvp.description,
      tvp.releasedate,
      tvp.isactive,
      tvp.icnuevo,
      tvp.dtinsert,
      tvp.dtupdate,
      tvp.factor,
      tvp.uxb,
      tvp.observacion,
      tvp.icprocesado,
      tvp.dtprocesado)
  when matched then -- modificaciones
     update 
        set vp.productid = tvp.productid,
            vp.name = tvp.name,
            vp.departmentid = tvp.departmentid,
            vp.categoryid = tvp.categoryid,
            vp.subcategoryid = tvp.subcategoryid,
            vp.brandid = tvp.brandid,
            vp.linkid = tvp.linkid,
            vp.refid = tvp.refid,
            vp.isvisible = tvp.isvisible,
            vp.description = tvp.description,
            vp.releasedate = tvp.releasedate,
            vp.isactive = tvp.isactive,
            vp.icnuevo = 0, --se setea en 0 porque se esta actualizando            
            vp.dtupdate = sysdate,
            vp.factor = tvp.factor,
            vp.uxb = tvp.uxb,
            vp.observacion = tvp.observacion,
            vp.icprocesado = tvp.icprocesado,  
            vp.dtprocesado = tvp.dtprocesado
       where -- solo se actualizan si hubo algun cambio     
            vp.name <> tvp.name
         or vp.departmentid <> tvp.departmentid
         or vp.categoryid <> tvp.categoryid
         or vp.subcategoryid <> tvp.subcategoryid
         or vp.brandid <> tvp.brandid
         or vp.linkid <> tvp.linkid
         or vp.isvisible <> tvp.isvisible
         or vp.description <> tvp.description
         or vp.releasedate <> tvp.releasedate
         or vp.isactive <> tvp.isactive
         or vp.factor <> tvp.factor
         or vp.uxb <> tvp.uxb;      
         
       
        --esto ocurre cuando un articulo de AC viene en estado 03
        --esta logica pone active 0 baja definitiva de un articulo en VTEX
        --solo si a�n esta active en 1
        update vtexproduct vp 
          set vp.isactive = 0,
              vp.icprocesado = 0 -- 0 para procesar en API de VTEX              
          where vp.isactive = 1  -- solo doy de baja los activos
            and vp.refid in (select distinct ar.cdarticulo                         
                               from articulos_s                    ar                            
                              where ar.cdestadoplu = '03'  --03 articulo desactivado permanentemente                        
                                and not exists
                              (select 1
                                       from articulosnocomerciales_s t
                                      where t.cdarticulo = ar.cdarticulo)
                                and not exists
                              (select 1
                                       from articulos_excluidos h
                                      where h.cdarticulo = ar.cdarticulo) --agrego tabla articulos excluidos 
                                and substr(ar.cdarticulo, 1, 1) <> 'A'                        
                                and ar.cddrugstore not in ('EX', 'DE', 'CP')); 
  commit;

EXCEPTION
  WHEN OTHERS THEN
    pkg_log_general.write(1,
                          'Modulo: ' || v_Modulo || '  Error: ' || SQLERRM);
END RefrescarProduct;
--------------------------------------------------------------------------------------------------------------
 
/*************************************************************************************************************
* Carga en una tabla global en memoria los datos de todos los art�culos activos en AC en los SKU por product
* %v 17/11/2020 - ChM 
*************************************************************************************************************/
PROCEDURE CargarTablaSKU IS
  v_Modulo varchar2(100) := 'PKG_MERGE_DATOS_VTEX.CargarTablaSKU';
  i        binary_integer := 1;

BEGIN

  for r_SKU in 
    ( select distinct ar.cdarticulo SKUid,
             ar.cdarticulo refid,
             nvl2(trim(ae.vldescripcion),ae.vldescripcion,da.vldescripcion) skuname,                              
             vp.isactive, --utilizo el isactive del producto padre para activar o no el SKU hijo
             ar.dtinsertplu CREATIONDATE,  
             n_pkg_vitalpos_materiales_s.GetCodigoBarras (ar.cdarticulo) EAN,                          
             null dtupdate,  
             0 icprocesado,                          
             null observacion,
             sysdate dtinsert,                             
             null dtprocesado                              
       from articulos_s                    ar,
            descripcionesarticulos_s       da,
            tblarticulonombreecommerce_s   ae,
            tblctgryarticulocategorizado_s a,
            tblctgrydepartamento_s         d,
            tblctgryuniverso_s             u,
            tblctgrycategoria_s            c,
            tblctgrysubcategoria_s         sc,
            tblctgrysegmento_s             s,
            tblctgrysubsegmento_s          ss,
            tblctgrysectorc_S              tse,
            tblivaarticulo_s               tiva,
            VTEXPRODUCT                    VP
      where ar.cdarticulo = da.cdarticulo                        
        and ar.cdestadoplu = '00'
        and tiva.cdarticulo(+) = ar.cdarticulo
        and not exists
      (select 1
               from articulosnocomerciales_s t
              where t.cdarticulo = a.cdarticulo)
        and not exists
      (select 1
               from articulos_excluidos h
              where h.cdarticulo = ar.cdarticulo) --agrego tabla articulos excluidos 
        and substr(ar.cdarticulo, 1, 1) <> 'A'
        and a.cdarticulo = ae.cdarticulo (+)
        and a.cddepartamento = d.cddepartamento(+)
        and a.cduniverso = u.cduniverso(+)
        and a.cdcategoria = c.cdcategoria(+)
        and a.cdsubcategoria = sc.cdsubcategoria(+)
        and a.cdsegmento = s.cdsegmento(+)
        and a.cdsubsegmento = ss.cdsubsegmento(+)
        and a.cdsectorc = tse.cdserctorc
        and a.cdarticulo = ar.cdarticulo
        and ar.cddrugstore not in ('EX', 'DE', 'CP')
        --valida solo articulos ya registrado en la VTEXPRODUCT
        and ar.cdarticulo = vp.refid ) loop
      g_1_sku(i).skuid := r_SKU.Skuid;
 	    g_1_sku(i).Refid := r_SKU.Refid;
      g_1_sku(i).skuName := r_SKU.skuName;
      g_1_sku(i).Isactive := r_SKU.Isactive;
      g_1_sku(i).Creationdate := r_SKU.Creationdate;
      g_1_sku(i).Ean := r_SKU.Ean;
      g_1_sku(i).Dtupdate := r_SKU.Dtupdate;
      g_1_sku(i).Icprocesado := r_SKU.Icprocesado;
      g_1_sku(i).Observacion := r_SKU.Observacion;
      g_1_sku(i).Dtinsert := r_SKU.Dtinsert;
      g_1_sku(i).Dtprocesado := r_SKU.Dtprocesado;
    i := i + 1;
  end loop;

EXCEPTION
  WHEN OTHERS THEN
    pkg_log_general.write(1,
                          'Modulo: ' || v_Modulo || '  Error: ' || SQLERRM);
END  CargarTablaSKU;

/**************************************************************************************************
* Devuelve todos los datos de la tabla de VTEXSKU en memoria
* %v 17/11/2020 - ChM
***************************************************************************************************/
FUNCTION PipeSKUs RETURN t_SKU_pipe
  PIPELINED IS
  i binary_integer := 0;
BEGIN
  i := g_1_SKU.FIRST;
  while i is not null loop
    pipe row(g_1_SKU(i));
    i := g_1_SKU.NEXT(i);
  end loop;
  return;
EXCEPTION
  when others then
    null;
END PipeSKUs;

/**************************************************************************************************
* Carga datos de todas los articulos para la carga inicial de SKUs de VTEXSKU
* %v 17/11/2020 - ChM
***************************************************************************************************/
PROCEDURE CargarSKU IS
  v_Modulo varchar2(100) := 'PKG_MERGE_DATOS_VTEX.CargarSKU';

BEGIN

  execute immediate 'truncate table vtexSKU';
  g_1_SKU.delete;
  -- llena la tabla en memoria
  CargarTablaSKU;
  -- la inserta en la definitiva
  insert into vtexSKU
    select * From Table(PipeSKUs);

  commit;

EXCEPTION
  WHEN OTHERS THEN
    pkg_log_general.write(1,
                          'Modulo: ' || v_Modulo || '  Error: ' || SQLERRM);
END CargarSKU;

/**************************************************************************************************
* Carga SKUS nuevos y actualiza los modificados de la tabla VTEXSKU
* %v 17/11/2020 - ChM
***************************************************************************************************/
PROCEDURE RefrescarSKU IS
  v_Modulo varchar2(100) := 'PKG_MERGE_DATOS_VTEX.RefrescarSKU';

BEGIN

  g_1_SKU.delete;
  -- llena la tabla en memoria con los SKUS activos de AC
  CargarTablaSKU;
  -- la inserta en una temporal para despues comparar

      insert into tmp_vtexSKU ts
              (ts.skuid,
               ts.refid,
               ts.skuname,
               ts.isactive,
               ts.creationdate,
               ts.ean,
               ts.unitmultiplier,
               ts.measurementunit,
               ts.dtupdate,
               ts.icprocesado,
               ts.observacion,
               ts.dtinsert,
               ts.dtprocesado)
        select s.skuid,
               s.refid,
               s.skuname,
               s.isactive,
               s.creationdate,
               s.ean,
               s.unitmultiplier,
               s.measurementunit,
               s.dtupdate,
               s.icprocesado,
               s.observacion,
               s.dtinsert,
               s.dtprocesado    
       From Table(PipeSKUs) s;

  -- no hago commit porque elimina los datos cargados -- commit;

  merge into vtexsku vs
  using tmp_vtexsku tvs
  on (vs.refid = tvs.refid)
  when not matched then -- altas
    insert
      (skuid,
       refid,
       skuname,
       isactive,
       creationdate,
       ean,
       unitmultiplier,
       measurementunit,
       dtupdate,
       icprocesado,
       observacion,
       dtinsert,
       dtprocesado)
    values
      (tvs.skuid,
       tvs.refid,
       tvs.skuname,
       tvs.isactive,
       tvs.creationdate,
       tvs.ean,
       tvs.unitmultiplier,
       tvs.measurementunit,
       tvs.dtupdate,
       tvs.icprocesado,
       tvs.observacion,
       tvs.dtinsert,
       tvs.dtprocesado)
  when matched then -- modificaciones
      update 
         set vs.skuname = tvs.skuname,
             vs.isactive = tvs.isactive,
             vs.creationdate = tvs.creationdate,
             vs.ean = tvs.ean,
             vs.unitmultiplier = tvs.unitmultiplier,
             vs.measurementunit = tvs.measurementunit,
             vs.dtupdate = sysdate,
             vs.icprocesado = tvs.icprocesado,
             vs.observacion = tvs.observacion,
             vs.dtinsert = tvs.dtinsert,
             vs.dtprocesado = tvs.dtprocesado
       where -- solo se actualizan si hubo algun cambio     
             vs.skuname <> tvs.skuname
          or vs.isactive <> tvs.isactive
          or vs.creationdate <> tvs.creationdate
          or vs.ean <> tvs.ean
          or vs.unitmultiplier <> tvs.unitmultiplier
          or vs.measurementunit <> tvs.measurementunit
          or vs.icprocesado <> tvs.icprocesado
          or vs.observacion <> tvs.observacion
          or vs.dtinsert <> tvs.dtinsert
          or vs.dtprocesado <> tvs.dtprocesado;     
   
  commit;

EXCEPTION
  WHEN OTHERS THEN
    pkg_log_general.write(1,
                          'Modulo: ' || v_Modulo || '  Error: ' || SQLERRM);
END RefrescarSKU;

/**************************************************************************************************
* Carga datos de todas el stock del almacen 01
* %v 24/11/2020 - ChM
***************************************************************************************************/

PROCEDURE CargarStock IS
  v_Modulo varchar2(100) := 'PKG_MERGE_DATOS_VTEX.CargarStock';

BEGIN

  execute immediate 'truncate table VTEXStock';
  
  insert into VTEXStock
    (cdalmacen,cdarticulo, cdsucursal, qtstock)
      with stock as(
          select aa.cdalmacen, 
                 aa.cdarticulo, 
                 vse.cdsucursal, 
                 sum(aa.qtstock) qtstock
            from articulosalmacen_s aa, 
                 vtexsellers vse,
                 vtexsku vs  --verifica si existe el sku
           where aa.cdarticulo = vs.refid
             and aa.cdsucursal = vse.cdsucursal    -- solo veo stock de sucursales de en vtex
             and vse.cdsucursal <>'9999'           --excluyo principal de vtex
             and aa.cdalmacen = substr(aa.cdsucursal, 3, 2) || '01    '
           group by aa.cdalmacen,vse.cdsucursal, aa.cdarticulo),
      --valida stock a 0 si no cumple cxon el umbral establecido por compras     
      ventas as (
             select ar.cdarticulo,
                    st.cantbtos              
               from articulos_s                    ar,
                    tblstockventas                 st,                           
                    tblctgryarticulocategorizado_s a,
                    tblctgrydepartamento_s         d,
                    tblctgryuniverso_s             u,
                    tblctgrycategoria_s            c,
                    tblctgrysubcategoria_s         sc,
                    tblctgrysegmento_s             s,
                    tblctgrysubsegmento_s          ss,
                    tblctgrysectorc_s              tse
              where  ar.cdestadoplu in('00','07')  --ojo 00 activo para la venta 07 no visible                         
                and not exists
              (select 1
                       from articulosnocomerciales_s t
                      where t.cdarticulo = a.cdarticulo) 
                and not exists                             
              (select 1
                       from articulos_excluidos h
                      where h.cdarticulo = ar.cdarticulo) --agrego tabla articulos excluidos 
                and not exists
                (select 1
                   from aux_art_sinstock b
                  where b.cdarticulo = a.cdarticulo)        
                and substr(ar.cdarticulo, 1, 1) <> 'a'                       
                and a.cddepartamento = d.cddepartamento(+)
                and a.cduniverso = u.cduniverso(+)
                and a.cdcategoria = c.cdcategoria(+)
                and a.cdsubcategoria = sc.cdsubcategoria(+)
                and a.cdsegmento = s.cdsegmento(+)
                and a.cdsubsegmento = ss.cdsubsegmento(+)
                and a.cdsectorc = tse.cdserctorc
                and a.cdarticulo = ar.cdarticulo
                and ar.cddrugstore not in ('ex', 'de', 'cp')
                and tse.dssectorc = st.dssectorc
                and d.dsdepartamento = st.dsdepartamento
                and u.dsuniverso = st.dsuniverso
                and c.dscategoria = st.dscategoria
                and sc.dssubcategoria = st.dssubcategoria
                and nvl (s.dssegmento, 'x') = nvl (st.dssegmento, 'x')) 
         select s.cdalmacen,
                s.cdarticulo,
                s.cdsucursal,
                case
                when (s.qtstock / n_pkg_vitalpos_materiales_s.getuxb(s.cdarticulo)) >= nvl (v.cantbtos, '0')
                then
                   s.qtstock
                else
                   0
             end
                as qtstock
          from stock s
          left join ventas v on (s.cdarticulo=v.cdarticulo);

  commit;

EXCEPTION WHEN OTHERS THEN
  pkg_log_general.write(1, 'Modulo: ' || v_Modulo || '  Error: ' || SQLERRM);
END CargarStock;


end PKG_MERGE_DATOS_VTEX;
/
