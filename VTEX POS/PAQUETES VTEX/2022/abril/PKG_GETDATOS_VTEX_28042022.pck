CREATE OR REPLACE PACKAGE PKG_GETDATOS_VTEX is
  -- Author  : CMALDONADO
  -- Created : 12/11/2020 8:14:18 a. m.
  -- Purpose : para manejar los datos de integraci�n con plataforma VTEX

   TYPE CURSOR_TYPE IS REF CURSOR;

   TYPE arr_refid IS TABLE OF VARCHAR(4000) INDEX BY PLS_INTEGER;

   --temporal
PROCEDURE GetBrands(Cur_Out Out Cursor_Type);
PROCEDURE GetCat(Cur_Out Out Cursor_Type);

   PROCEDURE GetProduct( p_id_canal In  vtexproduct.id_canal%type,
                         Cur_Out    Out Cursor_Type);

   PROCEDURE GetSku( p_id_canal In vtexsku.id_canal%type,
                     Cur_Out Out Cursor_Type);

   PROCEDURE SetProduct(p_refId            IN arr_refId,
                        p_id_canal         IN vtexproduct.id_canal%type,
                        p_Ok               OUT number,
                        p_error            OUT varchar2);

   PROCEDURE SetSku(p_refId       IN arr_refId,
                    p_id_canal    IN vtexsku.id_canal%type,
                    p_Ok          OUT number,
                    p_error       OUT varchar2);

   PROCEDURE GetSucursales (p_main     in integer default 0,
                           p_idcanal  in integer default 0,
                           Cur_Out    Out Cursor_Type);

  PROCEDURE GetStock (p_cdSucursal  In sucursales.cdsucursal%type,
                      p_id_canal    In vtexstock.id_canal%type,
                      Cur_Out       Out Cursor_Type);

  PROCEDURE SetStock (p_refId       IN arr_refId,
                      p_id_canal    IN vtexstock.id_canal%type,
                      p_Ok          OUT number,
                      p_error       OUT varchar2);

  PROCEDURE GetOffer ( p_id_canal   In  vtexpromotion.id_canal%type,
                       Cur_Out      Out Cursor_Type);

  PROCEDURE SetOffer ( p_id_canal     IN   vtexsellers.id_canal%type,
                       p_cdsucursal   IN   vtexsellers.cdsucursal%type);

  PROCEDURE GetPrice ( p_cdsucursal In sucursales.cdsucursal%type,
                       p_id_canal   In vtexprice.id_canal%type,
                       Cur_Out      Out Cursor_Type);

  PROCEDURE SetPrice (p_refId IN arr_refId,
                      p_Ok    OUT number,
                      p_error OUT varchar2);

  PROCEDURE GetCollection (p_id_canal    In  vtexcollection.id_canal%type,
                           Cur_Out       Out Cursor_Type);

  PROCEDURE GetCollectionSKU ( p_id_canal    In  vtexcollection.id_canal%type,
                               Cur_Out       Out Cursor_Type);

  PROCEDURE SetCollectionSKU (p_refId IN arr_refId,
                              p_Ok    OUT number,
                              p_error OUT varchar2);

  PROCEDURE GetPromotion (-- p_cdsucursal In sucursales.cdsucursal%type,
                           p_idcanal    In vtexsellers.id_canal%type default 'VE',
                           Cur_Out      Out Cursor_Type);

  PROCEDURE SetPromotion (p_refId IN arr_refId,
                          p_Ok    OUT number,
                          p_error OUT varchar2);

  PROCEDURE SetPedidosVtex (p_pedidoid_vtex  IN  vtexorders.pedidoid_vtex%type,
                           	p_id_canal       IN  vtexorders.id_canal%type,
                            p_Ok             OUT number,
                            p_error          OUT varchar2);


 PROCEDURE GetClients (p_id_canal       IN  vtexclients.id_canal%type,
                       Cur_Out          Out Cursor_Type);

  PROCEDURE SetClients (p_refId IN arr_refId,
                        p_Ok    OUT number,
                        p_error OUT varchar2);

  PROCEDURE GetAddress ( p_id_canal       IN  vtexclients.id_canal%type,
                         Cur_Out          Out Cursor_Type);

  PROCEDURE SetAddress  (p_refId IN arr_refId,
                        p_Ok    OUT number,
                        p_error OUT varchar2);


   PROCEDURE verificarOFFER;

end PKG_GETDATOS_VTEX;
/
CREATE OR REPLACE PACKAGE BODY PKG_GETDATOS_VTEX is
  /***********************************************************************************************
  * Temporal code, Hilmer
  ************************************************************************************************/

  PROCEDURE GetBrands(Cur_Out Out Cursor_Type) IS

    v_modulo varchar2(100) := 'PKG_GetDatos_VTEX.GetBrands';

  BEGIN

    OPEN cur_out FOR
     select * from vtexbrand;
  EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(1,
                            'Modulo: ' || v_Modulo || '  Error: ' ||
                            SQLERRM);
      return;
  END GetBrands;
    /***********************************************************************************************
  * Temporal code, Hilmer
  ************************************************************************************************/

  PROCEDURE GetCat(Cur_Out Out Cursor_Type) IS

    v_modulo varchar2(100) := 'PKG_GetDatos_VTEX.GetCat';

  BEGIN

    OPEN cur_out FOR
     select * from VTexCatalog;
  EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(1,
                            'Modulo: ' || v_Modulo || '  Error: ' ||
                            SQLERRM);
      return;
  END GetCat;

  /***********************************************************************************************
  * %v 13/11/2020 - ChM - Obtiene cursor con todos los productos no procesados en VTEX de los at�culos
  *                       nuevos o modificados en AC
  * %v 27/07/2021 - ChM - Agrego id_canal, canales definen sites distintos en VTEX
  * %v 05/10/2021 - ChM - incorporo el campo MultipleEan por ahora solo paso codigo de barra principal
  ************************************************************************************************/

  PROCEDURE GetProduct( p_id_canal In  vtexproduct.id_canal%type,
                        Cur_Out    Out Cursor_Type) IS

    v_modulo varchar2(100) := 'PKG_GetDatos_VTEX.GetProduct';

  BEGIN

    OPEN cur_out FOR
      SELECT vp.productid id,
             vp.name,
             vp.departmentid,
             vp.subcategoryid categoryid,
             vp.brandid,
             vp.linkid, -- OJO falta concatenar el parametro del vinculo donde se alojan todos los productos
             trim(vp.refid) refid,
             vp.isvisible,
             vp.name Description,
             --en blanco para modificar con valor para insertar
             decode(vp.icnuevo,1,vp.name,'') Descriptionshort, --explicar al front que si va sin valor no lo actualice
             vp.releasedate,
             --en blanco para modificar con valor para insertar
             decode(vp.icnuevo,1,vp.refid,'') KeyWords, --falta concatenar los cdbarras pricipales del articulo
             decode(vp.icnuevo,1,vp.name,'') Title,
             vp.isactive,
             decode(vp.icnuevo,1,vp.name,'') MetaTagDescription,
             decode(vp.icnuevo,1,0,'') ShowWithoutStock, --por defecto 1 para insert sin valor para update
             1 Score,
             vp.variedad,
             decode(nvl(vp.uxb,1),1,null,vp.uxb || ' Unidades x Bulto') as uxb,
             vp.MultipleEan
        FROM vtexproduct vp,
             vtexcatalog vc
       WHERE vp.departmentid = vc.departmentid
         AND vp.categoryid = vc.categoryid
         AND vp.subcategoryid = vc.subcategoryid
         AND vp.id_canal = p_id_canal
         AND vp.icprocesado = 0; --lista solo productos por procesar
  EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(1,
                            'Modulo: ' || v_Modulo || '  Error: ' ||
                            SQLERRM);
      return;
  END GetProduct;

  /***********************************************************************************************
  * %v 13/11/2020 - ChM - Obtiene cursor con todos los SKU no procesados en VTEX de los at�culos
  *                       nuevos o modificados en AC
  * %v 27/07/2021 - ChM - Agrego id_canal, canales definen sites distintos en VTEX
  ************************************************************************************************/

  PROCEDURE GetSku( p_id_canal In vtexsku.id_canal%type,
                    Cur_Out Out Cursor_Type) IS

    v_modulo        varchar2(100) := 'PKG_GetDatos_VTEX.GetSku';
    v_urlimages     parametrossistema.vlparametro%type:=getvlparametro('VTEX_URLImagenes', 'ConfigVTEX');
  BEGIN

    OPEN cur_out FOR
      SELECT vs.skuid id,
             vp.productid,
             vs.isactive,
             vp.name,
             trim(vs.refid) refid,
             1 PackagedHeight,
             1 PackagedLength,
             1 PackagedWidth,
             1 PackagedWeightKg,
             vs.creationdate,
             vs.ean,
             vs.measurementunit,
             vs.unitmultiplier,
             v_urlimages||to_number(vs.refid)||'.jpg' ImageURL
        FROM vtexproduct vp,
             vtexsku     vs
       WHERE vp.refid = vs.refid
         AND vs.id_canal = vp.id_canal
         AND vs.id_canal =p_id_canal
         --and vs.icprocesado = 0; --lista solo SKU por procesar
         ;
  EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(1,
                            'Modulo: ' || v_Modulo || '  Error: ' ||
                            SQLERRM);
      return;
  END GetSku;

  /***********************************************************************************************
  * %v 13/11/2020 - ChM - Actualiza a procesado el listado de productos que recibe del arr_refid
  * %v 27/07/2021 - ChM - Agrego id_canal, canales definen sites distintos en VTEX
  ************************************************************************************************/

  PROCEDURE SetProduct (p_refId            IN arr_refId,
                        p_id_canal         IN vtexproduct.id_canal%type,
                        p_Ok               OUT number,
                        p_error            OUT varchar2) IS

    v_modulo               varchar2(100) := 'PKG_GetDatos_VTEX.SetProduct';
    v_refid                vtexproduct.refid%type;
    v_icprocesado          vtexproduct.icprocesado%type;
    v_productID            vtexproduct.productid%type;
    v_observacion          vtexproduct.observacion%type;

  BEGIN

     IF (p_refId(1) IS NOT NULL and LENGTH(TRIM(p_refId(1)))>1) THEN
       FOR i IN 1 .. p_refId.Count LOOP
          --separa del arreglo del 1-8 char del refid equivalente al cdarticulo
          --el caracter 9 EL estado puede ser : 1 procesado sin error, 2 procesado con error
          --los siguientes del 10 al 18 (8 caracteres) se dejan para la secuencia del productoid de VTEX
          v_refid:=lpad((trim(substr(p_refId(i),1,8))),7,0);
          v_icprocesado:=to_number(substr(p_refId(i),9,1));
          v_productID:=to_number(substr(p_refId(i),10,8));
          v_observacion:= substr(p_refId(i),18,3999);
         --actualiza a procesado el articulo del arreglo
         begin
             update vtexproduct vp
                set vp.icprocesado=v_icprocesado,
                    vp.productid = v_productID,
                    vp.observacion = v_observacion,
                    vp.dtprocesado = sysdate
              where vp.refid = v_refid
                and vp.id_canal = p_id_canal;
             exception
               when others then
                   n_pkg_vitalpos_log_general.write(1,
                                       'Modulo: ' || v_modulo ||
                                       ' Detalle Error: cdarticulo ' || v_refid ||
                                       ' icprocesado ' || v_icprocesado ||
                                       ' ProductoID ' || v_productID ||
                                       ' ID_canal ' || p_id_canal);

         end;
       END LOOP;
     ELSE
      p_Ok:=0;
      p_error:='Error Arreglo Vacio no es posible Actualizar Productos';
   	  ROLLBACK;
      RETURN;
     END IF;
  COMMIT;
  p_Ok:=1;
  EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(1,
                            'Modulo: ' || v_Modulo || '  Error: ' ||
                            SQLERRM);
      p_Ok:=0;
      p_error:='Error no es posible Actualizar Productos';
   	  ROLLBACK;
      RETURN;
  END SetProduct;

  /***********************************************************************************************
  * %v 13/11/2020 - ChM - Actualiza a procesado el listado de sku que recibe del arr_refid
  * %v 27/07/2021 - ChM - Agrego id_canal, canales definen sites distintos en VTEX
  ************************************************************************************************/

  PROCEDURE SetSku(p_refId       IN arr_refId,
                   p_id_canal    IN vtexsku.id_canal%type,
                   p_Ok          OUT number,
                   p_error       OUT varchar2) IS

    v_modulo               varchar2(100) := 'PKG_GetDatos_VTEX.SetSKU';
    v_SKUid                vtexsku.skuid%type;
    v_icprocesado          vtexproduct.icprocesado%type;
    v_productID            vtexproduct.productid%type;
    v_observacion          vtexsku.observacion%type;

  BEGIN

     IF (p_refId(1) IS NOT NULL and LENGTH(TRIM(p_refId(1)))>1) THEN
       FOR i IN 1 .. p_refId.Count LOOP
          --separa del arreglo del 1-8 char del skuid equivalente al cdarticulo
          --el caracter 9 EL estado puede ser : 1 procesado sin error, 2 procesado con error
          --los siguientes del 10 al 18 (8 caracteres) se dejan para la secuencia del productoid de VTEX
          v_SKUid:=lpad((trim(substr(p_refId(i),1,8))),7,0);
          v_icprocesado:=to_number(substr(p_refId(i),9,1));
          v_productID:=to_number(substr(p_refId(i),10,8));
          v_observacion:= substr(p_refId(i),18,3999);
         --actualiza a procesado el SKU del arreglo
         begin
             update Vtexsku vs
                set vs.icprocesado=v_icprocesado,
                    vs.observacion=v_observacion,
                    vs.dtprocesado = sysdate
              where vs.skuid = v_SKUid
                and vs.id_canal = p_id_canal;
             exception
               when others then
                   n_pkg_vitalpos_log_general.write(1,
                                       'Modulo: ' || v_modulo ||
                                       ' Detalle Error: cdarticulo ' || v_SKUid ||
                                       ' icprocesado ' || v_icprocesado ||
                                       ' ProductoID ' || v_productID||
                                       ' ID_canal ' || p_id_canal);

         end;
       END LOOP;
     ELSE
      p_Ok:=0;
      p_error:='Error Arreglo Vacio no es posible Actualizar SKU';
   	  ROLLBACK;
      RETURN;
     END IF;
  COMMIT;
  p_Ok:=1;
  EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(1,
                            'Modulo: ' || v_Modulo || '  Error: ' ||
                            SQLERRM);
      p_Ok:=0;
      p_error:='Error no es posible Actualizar SKU';
   	  ROLLBACK;
      RETURN;
  END SetSku;

  /*******************************************************************************************************
  * %v 24/11/2020 - ChM - Obtiene cursor con todas las sucursales disponibles
  *                       con informaci�n necesaria para establecer conexion con VTEX
  *                       si p_main = 1 solo devuelve la conexi�n al main de vtex sucursal 9999
  *                       si p_idcanal = 1 devuelve solo la conexi�n al canal vendedor VE de cada sucursal
  ********************************************************************************************************/

  PROCEDURE GetSucursales (p_main     in integer default 0,
                           p_idcanal  in integer default 0,
                           Cur_Out    Out Cursor_Type) IS

    v_modulo        varchar2(100) := 'PKG_GetDatos_VTEX.GetSucursales';

  BEGIN
    IF p_main = 1 THEN
        OPEN cur_out FOR
          select *
            from vtexsellers vs
            where vs.cdsucursal ='9999'
              and (p_idcanal=0 or vs.id_canal='VE')
              and vs.icactivo = 1
              ;
    ELSE
        OPEN cur_out FOR
          select *
            from vtexsellers vs
           where vs.cdsucursal <>'9999'
             and (p_idcanal=0 or vs.id_canal='VE')
             and vs.icactivo = 1
             ;
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(1,
                            'Modulo: ' || v_Modulo || '  Error: ' ||
                            SQLERRM);
      return;
  END GetSucursales;

  /*******************************************************************************************************
  * %v 24/11/2020 - ChM - Obtiene cursor con SKUID y STOCK necesarios para subir a VTEX
  * %v 10/05/2021 - ChM - Solo sucursales activas
  * %v 19/05/2021 - ChM - Divido entre la unidad multiplicadora para la subida a VTEX
  * %v 27/07/2021 - ChM - Agrego id_canal, canales definen sites distintos en VTEX
  ********************************************************************************************************/

  PROCEDURE GetStock (p_cdSucursal  In sucursales.cdsucursal%type,
                      p_id_canal    In vtexstock.id_canal%type,
                      Cur_Out       Out Cursor_Type) IS

    v_modulo        varchar2(100) := 'PKG_GetDatos_VTEX.GetStock';

  BEGIN
     OPEN cur_out FOR
         select vst.cdarticulo SKU_refid,
                vst.qtstock
           from vtexstock   vst,
                vtexproduct vp,
                vtexsellers vs
          where vst.cdsucursal = p_cdsucursal
           -- Solo sucursales activas
            and vst.cdsucursal = vs.cdsucursal
            and vs.icactivo = 1
            and vst.cdarticulo = vp.refid
            and vst.id_canal = vp.id_canal
            and vst.id_canal = vs.id_canal
            and vst.id_canal = p_id_canal
            --solo productos procesados y activos en VTEX
            and vp.icprocesado = 1
            and vp.dtprocesado is not null
            and vp.isactive = 1
            --solo stock por procesar
            and vst.icprocesado in (0,2);

  EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(1,
                            'Modulo: ' || v_Modulo || '  Error: ' ||
                            SQLERRM);
      return;
  END GetStock;

  /***********************************************************************************************
  * %v 15/12/2020 - ChM - Actualiza a procesado el listado de stock que recibe del arr_refid
  * %v 27/07/2021 - ChM - Agrego id_canal, canales definen sites distintos en VTEX
  ************************************************************************************************/

  PROCEDURE SetStock (p_refId       IN arr_refId,
                      p_id_canal    IN vtexstock.id_canal%type,
                      p_Ok          OUT number,
                      p_error       OUT varchar2) IS

    v_modulo               varchar2(100) := 'PKG_GetDatos_VTEX.SetStock';
    v_sku_refid            vtexstock.cdarticulo%type;
    v_icprocesado          vtexstock.icprocesado%type;
    v_cdsucursal           vtexstock.cdsucursal%type;
    v_observacion          varchar2(3999);

  BEGIN

     IF (p_refId(1) IS NOT NULL and LENGTH(TRIM(p_refId(1)))>1) THEN
       FOR i IN 1 .. p_refId.Count LOOP
          v_sku_refid:=trim(substr(p_refId(i),1,8));
          v_icprocesado:=to_number(substr(p_refId(i),9,1));
          v_cdsucursal:=rpad((trim(substr(p_refId(i),10,4))),8,' ');
          v_observacion:= substr(p_refId(i),14,3999);
         --actualiza a procesado el articulo del arreglo
         begin
             update Vtexstock vs
                set vs.icprocesado = v_icprocesado,
                    vs.dtprocesado = sysdate,
                    vs.observacion = v_observacion
              where vs.cdarticulo = v_sku_refid
                and vs.id_canal = p_id_canal
                and vs.cdsucursal = v_cdsucursal;

             exception
               when others then
                   n_pkg_vitalpos_log_general.write(1,
                                       'Modulo: ' || v_modulo ||
                                       ' Detalle Error: cdarticulo ' || v_sku_refid ||
                                       ' icprocesado ' || v_icprocesado);

         end;
       END LOOP;
     ELSE
      p_Ok:=0;
      p_error:='Error arreglo vacio no es posible actualizar Stock';
   	  ROLLBACK;
      RETURN;
     END IF;
  COMMIT;
  p_Ok:=1;
  EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(1,
                            'Modulo: ' || v_Modulo || '  Error: ' ||
                            SQLERRM);
      p_Ok:=0;
      p_error:='Error no es posible actualizar Stock';
   	  ROLLBACK;
      RETURN;
  END SetStock;


  /***********************************************************************************************
  * %v 09/12/2020 - ChM - Obtiene cursor con todos los precios no procesados en VTEX de los at�culos
  *                       nuevos o modificados en AC
  * %v 27/07/2021 - ChM - Agrego id_canal, canales definen sites distintos en VTEX
  * %v 17/08/2021 - ChM - Agrego validaci�n para no subir ofertas con a�o 9999
  * %v 18/03/2022 - ChM - Agrego precios PA
  ************************************************************************************************/

  PROCEDURE GetPrice ( p_cdsucursal In sucursales.cdsucursal%type,
                       p_id_canal   In vtexprice.id_canal%type,
                       Cur_Out      Out Cursor_Type) IS

    v_modulo        varchar2(100) := 'PKG_GetDatos_VTEX.GetPrice';

  BEGIN

    OPEN cur_out FOR
     SELECT vpr.cdsucursal,
             vpr.id_canal,
             vs.id_canal_vtex,
             vpr.skuid,
             case
               --si tiene PA vigente remplaza el PL
               when vpr.dttopa>=trunc(sysdate) then
                   vpr.pricepa
                  else
                    vpr.pricepl
             end pricepl,
             vpr.priceof,
             vpr.dtfromof,
             vpr.dttoof
        FROM vtexprice   vpr,
             vtexsellers vs,
             vtexproduct  vp
       WHERE vs.cdsucursal = vpr.cdsucursal
         and vpr.id_canal = vs.id_canal
         and vpr.cdsucursal = p_cdsucursal
         and vpr.id_canal = p_id_canal
         and vs.icactivo = 1 --solo sucursales activas
         and vpr.icprocesado = 0 --lista solo precios por procesar
         and vp.refid = vpr.refid
         and vp.id_canal = vpr.id_canal
         and vp.icprocesado = 1 --solo articulos procesados
         and trim(EXTRACT(YEAR FROM NVL(vpr.dttoof,to_date('01/01/01','dd/mm/yy'))))<> 9999 --valida no devolver ofertas infinitas
         order by vpr.skuid;
  EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(1,
                            'Modulo: ' || v_Modulo || '  Error: ' ||
                            SQLERRM);
      return;
  END GetPrice;

/* ******************************************************************************************************* *
CU 07 Alta CSV de ofertas y precios a Master DATA de POS a VTEX
Versi�n: 1.0 08/04/2021
Dependencias:	POS, VTEX
Precondici�n:
Descripci�n:	El sistema debe generar un archivo CSV por cada sucursal y sus diferentes canales
              que contenga la informaci�n de las ofertas vigentes diarias por art�culos y subirlo
              a master data de VTEX v�a API cada vez que se actualice o cambie un precio de oferta.
Secuencia Normal:	Paso	Acci�n
	                1	    El sistema genera un listado de los art�culos con precios de oferta vigentes
                        por sucursal y canal, para enviarlo v�a API en formato CSV, un archivo por cada sucursal.
	                2	    Por cada sucursal bien procesada por la API, POS recibe una marca de procesado
                        correctamente, evitando enviar al listado de art�culos con informaci�n de
                        sucursales ya procesadas.
	                3	    Una vez que la API realice la carga de todos los datos por sucursal, realiza
                        un llamado a POS para verificar si existen precios procesados a VTEX con fecha
                        superior a la fecha de marca de subida de CSV, si es as� POS marca la sucursal
                        correspondiente para reprocesar y el proceso regresa al paso 1.
	                4	    Si no existen ofertas con fecha posterior a la generaci�n de CSV, el proceso
                        finaliza. Por no existir sucursales por procesar.
Post condici�n:
Excepciones:
Comentarios:	*/

 /***********************************************************************************************
  * %v 08/04/202 - ChM - verifico si existen precios de oferta procesados despues del
  *                      dtprocesadocsv ajusto para reprocesar las sucursales
  * %v 8/5/2021 - APW - solo ofertas vigentes
  * %v 03/06/2021 - ChM - Agrego validaci�n para promociones
  * %v 21/03/2022 - ChM - Agrego PA de la tabla vtexprice
  ************************************************************************************************/

  PROCEDURE verificarOFFER IS

    v_modulo        varchar2(100) := 'PKG_GetDatos_VTEX.verificarOFFER';

  BEGIN
    --revisa ofertas
   for p in
     (select count(*) valida,
             vs.cdsucursal,
             vs.id_canal
       from vtexprice   vp,
            vtexsellers vs
      where vp.cdsucursal=vs.cdsucursal
        and vp.id_canal=vs.id_canal
        --solo sucursales activas
        and vs.icactivo = 1
        --solo precios en VTEX correctamente
        and vp.icprocesado=1
         --solo ofertas
        and (vp.priceof is not null OR vp.pricePA is not null)
        and (vp.dttoof >= trunc(sysdate) OR vp.dttoPA >= trunc(sysdate))
        --solo sucursales ya procesadas
        and vs.iccsv=1
        --solo precios con dtprocesado superior al dtprocesadocsv de vtexsellers
        and (vp.dtprocesado > vs.dtprocesadocsv or vs.dtprocesadocsv is null)
   group by vs.cdsucursal,
            vs.id_canal
     )
   loop
        --si existen precios procesados actualizo para volver a subir CSV de Sucursal
        if nvl(p.valida,0) <> 0 then
           update vtexsellers vs
              set vs.iccsv = 0,
                  vs.dtprocesadocsv=null
            where vs.cdsucursal=p.cdsucursal
              and vs.id_canal=p.id_canal;
        end if;
    end loop;
    --revisa Promociones
   for p in
     (select count(*) valida,
             vs.cdsucursal,
             vs.id_canal
       from vtexpromotion   vp,
            vtexsellers vs
      where vp.cdsucursal=vs.cdsucursal
        and vp.id_canal=vs.id_canal
        --solo sucursales activas
        and vs.icactivo = 1
        --solo promociones en VTEX correctamente
        and vp.icprocesado=1
        --solo promos vigentes ChM comento 2/3/2022
       -- and vp.enddateutc >= trunc(sysdate)
        --solo sucursales ya procesadas
        and vs.iccsv=1
        --solo promociones con dtprocesado superior al dtprocesadocsv de vtexsellers
        and (vp.dtprocesado > vs.dtprocesadocsv or vs.dtprocesadocsv is null)
   group by vs.cdsucursal,
            vs.id_canal
     )
   loop
        --si existen promos procesadas actualizo para volver a subir CSV de Sucursal
        if nvl(p.valida,0) <> 0 then
           update vtexsellers vs
              set vs.iccsv = 0,
                  vs.dtprocesadocsv=null
            where vs.cdsucursal=p.cdsucursal
              and vs.id_canal=p.id_canal;
        end if;
    end loop;
    commit;
    return;
  EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(1,
                            'Modulo: ' || v_Modulo || '  Error: ' ||
                            SQLERRM);
      rollback;
      return;
  END verificarOFFER;

  /***********************************************************************************************
  * %v 03/06/2021 - ChM - Obtiene cursor con todos los precios en oferta y promociones por canal y sucursal
                          de articulos y precios ya procesados en VTEX
  * %v 29/06/2021 - ChM - Agrego validaci�n de solo subir promociones en isactive = 1
  * %v 27/07/2021 - ChM - Agrego id_canal, canales definen sites distintos en VTEX
  * %v 18/01/2022 - ChM - id_promo_hija y id_canal en vtexpromotion por ajsute promos multiplie UxB <> UV
  * %v 18/03/2022 - ChM - Agrego precios PA
  * %v 29/03/2022 - ChM - ajusto leyenda
  ************************************************************************************************/

  PROCEDURE GetOffer ( p_id_canal   In  vtexpromotion.id_canal%type,
                       Cur_Out      Out Cursor_Type) IS

    v_modulo        varchar2(100) := 'PKG_GetDatos_VTEX.GetOffer';

  BEGIN

    OPEN cur_out FOR
      SELECT distinct
             vpr.skuid,
             vo.dscucarda name,
             case
               --verifica si tiene oferta vigente
               when vpr.dttoof>=trunc(sysdate) then
                   vpr.priceof
               --verifica si tiene PA vigente
               when vpr.dttoPA>=trunc(sysdate) then
                   vpr.pricePA
                else
                  vpr.pricepl
              end pricepl,
             case
               --verifica si tiene oferta vigente
               when vpr.dttoof>=trunc(sysdate) then
                   round(vpr.priceof-(vpr.priceof*(vo.valoracc/100)),2)
               --verifica si tiene PA vigente
               when vpr.dttoPA>=trunc(sysdate) then
                   round(vpr.pricePA-(vpr.pricePA*(vo.valoracc/100)),2)
                else
                  round(vpr.pricepl-(vpr.pricepl*(vo.valoracc/100)),2)
              end priceof,
             vo.enddateutc dttoof,
--             vo.valorcond*vo.uxb cantminima,
             vs.id_canal_vtex,
             vs.cdsucursal_vtex,
             -- 29/03/2022 - ChM - ajusto leyenda
             --extraigo el valor condici�n de la leyenda para simpre buscar el original de la promo Padre
             case
                when (INSTR(vo.dsleyendacorta,'BULTO')<>0 and INSTR(vo.dsleyendacorta,'cada')<> 0) then
                    'desde '||to_number(regexp_substr(vo.dsleyendacorta, '\d+'))*vp.uxb||'  UNIDADES'
                when (INSTR(vo.dsleyendacorta,'BULTO')<> 0 and INSTR(vo.dsleyendacorta,'desde')<> 0) then
                    'desde '||to_number(regexp_substr(vo.dsleyendacorta, '\d+'))*vp.uxb||'  UNIDADES'
                else
                  vo.dsleyendacorta
             end dsleyendacorta,
             'Progressive' type
          --   vk.skuid||vs.id_canal_vtex
        FROM vtexprice        vpr,
             vtexsellers      vs,
             vtexproduct      vp,
             vtexsku          vk,
             vtexpromotion    vo,
             vtexpromotionsku vos
       WHERE vs.cdsucursal = vpr.cdsucursal
         and vpr.id_canal = vs.id_canal
         and vpr.id_canal = p_id_canal
         and vs.icactivo = 1 --solo sucursales activas
         and vpr.icprocesado = 1 --lista solo precios procesados
         and vp.refid = vpr.refid
         and vp.id_canal = vpr.id_canal
         and vp.icprocesado = 1 --solo articulos procesados
         --solo promociones aun vigentes
         and vo.enddateutc>=trunc(sysdate)
         --solo sucursales que no se genero el CSV
         and vs.iccsv = 0
         and vp.refid = vk.refid
         and vp.id_canal = vk.id_canal
         and vo.id_promo_pos = vos.id_promo_pos
         and vo.id_canal = vpr.id_canal
          --ChM 15112021
         and vo.cdsucursal = vs.cdsucursal
         and vo.icprocesado = 1 --solo promociones procesadas
         and vos.id_promo_hija = vo.id_promo_hija
         and vos.id_canal = vo.id_canal
         and vos.skuid = vk.skuid
         and vos.refid = vk.refid
         and vo.isactive = 1
       --  and vp.refid='0176304'
       UNION
      SELECT distinct
             vpr.skuid,
             'Oferta' name,
             vpr.pricepl,
             vpr.priceof,
             vpr.dttoof,
           --  vk.unitmultiplier cantminima,
             vs.id_canal_vtex,
             vs.cdsucursal_vtex,
             ' ' dsleyendacorta,
             'nominal' type
         --    vk.skuid||vs.id_canal_vtex
        FROM vtexprice    vpr,
             vtexsellers  vs,
             vtexproduct  vp,
             vtexsku      vk
       WHERE vs.cdsucursal = vpr.cdsucursal
         and vpr.id_canal = vs.id_canal
         and vpr.id_canal = p_id_canal
         and vs.icactivo = 1 --solo sucursales activas
         and vpr.icprocesado = 1 --lista solo precios procesados
         and vp.refid = vpr.refid
         and vp.id_canal = vpr.id_canal
         and vp.icprocesado = 1 --solo articulos procesados
         --solo precios de oferta
         and vpr.priceof is not null
         --solo ofertas aun vigentes
         and vpr.dttoof>=trunc(sysdate)
         --solo sucursales que no se genero el CSV
         and vs.iccsv = 0
         and vp.refid = vk.refid
         and vp.id_canal = vk.id_canal
         --excluyo articulos en promociones del primer select
         and vk.skuid||vs.id_canal_vtex not in (SELECT distinct
                                                       vos.skuid||vs.id_canal_vtex
                                                  FROM vtexprice        vpr,
                                                       vtexsellers      vs,
                                                       vtexproduct      vp,
                                                       vtexsku          vk,
                                                       vtexpromotion    vo,
                                                       vtexpromotionsku vos
                                                 WHERE vs.cdsucursal = vpr.cdsucursal
                                                   and vpr.id_canal = vs.id_canal
                                                   and vpr.id_canal = p_id_canal
                                                   and vs.icactivo = 1 --solo sucursales activas
                                                   and vpr.icprocesado = 1 --lista solo precios procesados
                                                   and vp.refid = vpr.refid
                                                   and vp.id_canal = vpr.id_canal
                                                   and vp.icprocesado = 1 --solo articulos procesados
                                                   --solo promociones aun vigentes
                                                   and vo.enddateutc>=trunc(sysdate)
                                                   --solo sucursales que no se genero el CSV
                                                   and vs.iccsv = 0
                                                   and vp.refid = vk.refid
                                                   and vp.id_canal = vk.id_canal
                                                   and vo.id_promo_pos = vos.id_promo_pos
                                                   and vo.id_canal = vpr.id_canal
                                                   and vos.id_promo_hija = vo.id_promo_hija
                                                   and vos.id_canal = vo.id_canal
                                                    --ChM 15112021
                                                   and vo.cdsucursal = vs.cdsucursal
                                                   and vo.icprocesado = 1 --solo promociones procesadas
                                                   and vos.skuid = vk.skuid
                                                   and vos.refid = vk.refid
                                                    and vo.isactive = 1
                                                 --  and vos.skuid='176304'
                                                )
        UNION
          SELECT distinct
                 vpr.skuid,
                 'Oportunidad' name,
                 vpr.pricepl,
                 vpr.pricepa,
                 vpr.dttopa,
               --  vk.unitmultiplier cantminima,
                 vs.id_canal_vtex,
                 vs.cdsucursal_vtex,
                 ' ' dsleyendacorta,
                 'opportunity' type
             --    vk.skuid||vs.id_canal_vtex
            FROM vtexprice    vpr,
                 vtexsellers  vs,
                 vtexproduct  vp,
                 vtexsku      vk
           WHERE vs.cdsucursal = vpr.cdsucursal
             and vpr.id_canal = vs.id_canal
             and vpr.id_canal = p_id_canal
             and vs.icactivo = 1 --solo sucursales activas
             and vpr.icprocesado = 1 --lista solo precios procesados
             and vp.refid = vpr.refid
             and vp.id_canal = vpr.id_canal
             and vp.icprocesado = 1 --solo articulos procesados
             --solo precios de acercamiento
             and vpr.pricepa is not null
             --solo PA aun vigentes
             and vpr.dttoPA>=trunc(sysdate)
             --solo sucursales que no se genero el CSV
             and vs.iccsv = 0
             and vp.refid = vk.refid
             and vp.id_canal = vk.id_canal
             --excluyo articulos en promociones del primer select Y OFERTAS DEL SEGUNDO
             and vk.skuid||vs.id_canal_vtex not in (SELECT distinct
                                                           vos.skuid||vs.id_canal_vtex
                                                      FROM vtexprice        vpr,
                                                           vtexsellers      vs,
                                                           vtexproduct      vp,
                                                           vtexsku          vk,
                                                           vtexpromotion    vo,
                                                           vtexpromotionsku vos
                                                     WHERE vs.cdsucursal = vpr.cdsucursal
                                                       and vpr.id_canal = vs.id_canal
                                                       and vpr.id_canal = p_id_canal
                                                       and vs.icactivo = 1 --solo sucursales activas
                                                       and vpr.icprocesado = 1 --lista solo precios procesados
                                                       and vp.refid = vpr.refid
                                                       and vp.id_canal = vpr.id_canal
                                                       and vp.icprocesado = 1 --solo articulos procesados
                                                       --solo promociones aun vigentes
                                                       and vo.enddateutc>=trunc(sysdate)
                                                       --solo sucursales que no se genero el CSV
                                                       and vs.iccsv = 0
                                                       and vp.refid = vk.refid
                                                       and vp.id_canal = vk.id_canal
                                                       and vo.id_promo_pos = vos.id_promo_pos
                                                       and vo.id_canal = vpr.id_canal
                                                       and vos.id_promo_hija = vo.id_promo_hija
                                                       and vos.id_canal = vo.id_canal
                                                        --ChM 15112021
                                                       and vo.cdsucursal = vs.cdsucursal
                                                       and vo.icprocesado = 1 --solo promociones procesadas
                                                       and vos.skuid = vk.skuid
                                                       and vos.refid = vk.refid
                                                       and vo.isactive = 1
                                                     --  and vos.skuid='176304'
                                                   UNION
                                                  SELECT distinct
                                                         vk.skuid||vs.id_canal_vtex
                                                    FROM vtexprice    vpr,
                                                         vtexsellers  vs,
                                                         vtexproduct  vp,
                                                         vtexsku      vk
                                                   WHERE vs.cdsucursal = vpr.cdsucursal
                                                     and vpr.id_canal = vs.id_canal
                                                     and vpr.id_canal = p_id_canal
                                                     and vs.icactivo = 1 --solo sucursales activas
                                                     and vpr.icprocesado = 1 --lista solo precios procesados
                                                     and vp.refid = vpr.refid
                                                     and vp.id_canal = vpr.id_canal
                                                     and vp.icprocesado = 1 --solo articulos procesados
                                                     --solo precios de oferta
                                                     and vpr.priceof is not null
                                                     --solo ofertas aun vigentes
                                                     and vpr.dttoof>=trunc(sysdate)
                                                     --solo sucursales que no se genero el CSV
                                                     and vs.iccsv = 0
                                                     and vp.refid = vk.refid
                                                     and vp.id_canal = vk.id_canal
                                                  )
            --  and vp.refid='0176304'
      ORDER BY 1;
  EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(1,
                            'Modulo: ' || v_Modulo || '  Error: ' ||
                            SQLERRM);
      return;
  END GetOffer;
  /***********************************************************************************************
  * %v 08/04/2021 - ChM - marca en tblcontrolprocesocentral que se proceso correctamente la
  *                       carga del CSV de ofertas en masterdata VTEX
  * %v 27/07/2021 - ChM - Agrego id_canal, canales definen sites distintos en VTEX
  * %v 09/09/2021 - ChM - Ajusto update para todas las sucursales o la que recibe
  ************************************************************************************************/

  PROCEDURE SetOffer ( p_id_canal     IN   vtexsellers.id_canal%type,
                       p_cdsucursal   IN   vtexsellers.cdsucursal%type) IS

    v_modulo        varchar2(100) := 'PKG_GetDatos_VTEX.SetOffer';

  BEGIN
     update vtexsellers vs
        set vs.iccsv = 1,
            vs.dtprocesadocsv=sysdate
      where (p_cdsucursal='9999    ' or vs.cdsucursal = p_cdsucursal)
        and vs.id_canal = p_id_canal
        --solo sucurales activas del canal
        and vs.icactivo = 1;
     commit;
  EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(1,
                            'Modulo: ' || v_Modulo || '  Error: ' ||
                            SQLERRM);
      rollback;
      return;
  END SetOffer;

  /***********************************************************************************************
  * %v 09/12/2020 - ChM - Actualiza a procesado el listado de precios que recibe del arr_refid
  ************************************************************************************************/

  PROCEDURE SetPrice (p_refId IN arr_refId,
                      p_Ok    OUT number,
                      p_error OUT varchar2) IS

    v_modulo               varchar2(100) := 'PKG_GetDatos_VTEX.SetPrice';
    v_skuid                vtexprice.skuid%type;
    v_icprocesado          vtexprice.icprocesado%type;
    v_cdsucursal           vtexprice.cdsucursal%type;
    v_id_canal             vtexprice.id_canal%type;
    v_observacion          varchar2(3999);

  BEGIN

     IF (p_refId(1) IS NOT NULL and LENGTH(TRIM(p_refId(1)))>1) THEN
       FOR i IN 1 .. p_refId.Count LOOP
          --separa del arreglo del 1-8 char del skuid equivalente al cdarticulo
          --el caracter 9 el estado puede ser : 1 procesado sin error, 2 procesado con error
          -- el carater 10 al 14 cd sucursal
          -- el carater 15 al 16 id_canal
          v_skuid:=to_number(substr(p_refId(i),1,8));
          v_icprocesado:=to_number(substr(p_refId(i),9,1));
          v_cdsucursal:=rpad((trim(substr(p_refId(i),10,4))),8,' ');
          v_id_canal:=upper(trim(substr(p_refId(i),14,2)));
          v_observacion:= substr(p_refId(i),16,3999);
         --actualiza a procesado el articulo del arreglo
         begin
             update vtexprice vp
                set vp.icprocesado = v_icprocesado,
                    vp.dtprocesado = sysdate,
                    vp.observacion = v_observacion
              where vp.skuid = v_skuid
                and vp.cdsucursal = v_cdsucursal
                and vp.id_canal = v_id_canal;

             exception
               when others then
                   n_pkg_vitalpos_log_general.write(1,
                                       'Modulo: ' || v_modulo ||
                                       ' Detalle Error: cdarticulo ' || v_skuid ||
                                       ' icprocesado ' || v_icprocesado);

         end;
       END LOOP;
     ELSE
      p_Ok:=0;
      p_error:='Error Arreglo Vacio no es posible Actualizar Precios';
   	  ROLLBACK;
      RETURN;
     END IF;
  COMMIT;
  p_Ok:=1;
  EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(1,
                            'Modulo: ' || v_Modulo || '  Error: ' ||
                            SQLERRM);
      p_Ok:=0;
      p_error:='Error no es posible Actualizar Precios';
   	  ROLLBACK;
      RETURN;
  END SetPrice;
  /*******************************************************************************************************
  * %v 16/12/2020 - ChM - Obtiene cursor con todas las colecciones necesarias para solicitar fecha de
  *                       vigencia de las mismas a VTEX
  * %v 27/07/2021 - ChM - Agrego id_canal, canales definen sites distintos en VTEX
  ********************************************************************************************************/

  PROCEDURE GetCollection (p_id_canal    In  vtexcollection.id_canal%type,
                           Cur_Out       Out Cursor_Type) IS

    v_modulo        varchar2(100) := 'PKG_GetDatos_VTEX.GetCollection';

  BEGIN
     OPEN cur_out FOR
          select vc.*,
                 nvl((select count(*)
                     from vtexcollectionsku vk
                    where vk.collectionid=vc.collectionid),0) icskus
            from vtexcollection vc
           where vc.id_canal = p_id_canal;
            /*
  select collectionid,
         name,
         id_tipo,
         dtfrom,
         dtto,
         cdsucursal,
         id_canal,
         case
           when icskus > 1000 then
            1000
           else
            icskus
         end icskus
    from (select vc.*,
                 nvl((select count(*)
                       from vtexcollectionsku vk
                      where vk.collectionid = vc.collectionid),
                     0) icskus
            from vtexcollection vc
           where vc.id_canal = p_id_canal);
  */
  EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(1,
                            'Modulo: ' || v_Modulo || '  Error: ' ||
                            SQLERRM);
      return;
  END GetCollection;

  /***********************************************************************************************
  * %v 16/12/2020 - ChM - Actualiza fecha de vigencia de las colecciones de VTEX a POS
                          de esta manera se cargan los SKU solo en Colecciones Vigentes en VTEX
  ************************************************************************************************/

  PROCEDURE SetCollection (p_collectionID IN vtexcollection.collectionid%type,
                           p_dtfrom       IN vtexcollection.dtfrom%type,
                           p_dtto         IN vtexcollection.dtto%type,
                           p_Ok           OUT number,
                           p_error        OUT varchar2) IS

    v_modulo               varchar2(100) := 'PKG_GetDatos_VTEX.SetCollection';

  BEGIN

     update Vtexcollection vc
        set vc.dtfrom = p_dtfrom,
            vc.dtto = p_dtto
      where vc.collectionid = p_collectionID;

  COMMIT;
  p_Ok:=1;
  EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(1,
                               'Modulo: ' || v_modulo ||
                               ' Detalle Error: collectionID ' || p_collectionID ||'  Error: ' ||SQLERRM);
      p_Ok:=0;
      p_error:='Error no es posible actualizar collection';
   	  ROLLBACK;
      RETURN;
  END SetCollection;

   /*******************************************************************************************************
  * %v 16/12/2020 - ChM - Obtiene cursor con todas los SKUS y idColletion que se deben agregar a una
  *                       colecci�n de VTEX
  * %v 24/06/2021 - ChM - Ajusto filtrar solo  skus procesados correctamente en VTEX
  *                       quedarian pendientes los SKU que no han subido por error para carga cuando suban
  * %v 27/07/2021 - ChM - Agrego id_canal, canales definen sites distintos en VTEX
  * %v 28/04/2022 - ChM - agrego orden de skus
  ********************************************************************************************************/

  PROCEDURE GetCollectionSKU ( p_id_canal    In  vtexcollection.id_canal%type,
                               Cur_Out       Out Cursor_Type) IS

    v_modulo        varchar2(100) := 'PKG_GetDatos_VTEX.GetCollectionSKU';

  BEGIN
     OPEN cur_out FOR
         select vs.collectionid,
                 vs.skuid,
                 vs.refid
            from vtexcollectionSKU vs,
                 vtexcollection    vc,
                 vtexsku           sku
           where vs.collectionid = vc.collectionid
             and vs.icprocesado = 0
             and sku.refid= vs.refid
             --solo skus procesados
             and sku.icprocesado=1
             and sku.id_canal = vc.id_canal
             and vc.id_canal = p_id_canal
        order by vs.orden    
            ;

  EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(1,
                            'Modulo: ' || v_Modulo || '  Error: ' ||
                            SQLERRM);
      return;
  END GetCollectionSKU;

  /***********************************************************************************************
  * %v 16/12/2020 - ChM - Actualiza a procesado el SKU de la Collection que recibe en arreglo
  ************************************************************************************************/

  PROCEDURE SetCollectionSKU (p_refId IN arr_refId,
                              p_Ok    OUT number,
                              p_error OUT varchar2) IS

    v_modulo               varchar2(100) := 'PKG_GetDatos_VTEX.SetCollectionSKU';
    v_collectionID         vtexcollectionsku.collectionid%type;
    v_refid                vtexcollectionsku.refid%type;
    v_icprocesado          vtexcollectionsku.icprocesado%type;
    v_observacion          varchar2(3999);

  BEGIN

     IF (p_refId(1) IS NOT NULL and LENGTH(TRIM(p_refId(1)))>1) THEN
       FOR i IN 1 .. p_refId.Count LOOP

          -- el carater 1 al 4 collectionID
          -- el carater 5 al 6 icprocesado
          -- el caracter del 6 en adelante observacion

          v_collectionID:=lpad((trim(substr(p_refId(i),1,4))),8,0);
          v_icprocesado:=lpad((trim(substr(p_refId(i),5,1))),8,0);
          v_observacion:= substr(p_refId(i),6,3999);
         --actualiza a procesado el sku
         begin
             update Vtexcollectionsku vs
                set vs.icprocesado = v_icprocesado,
                    vs.dtprocesado = sysdate,
                    vs.observacion = v_observacion
              where vs.collectionid = v_collectionID;
             exception
               when others then
                   n_pkg_vitalpos_log_general.write(1,
                                       'Modulo: ' || v_modulo ||
                                       ' Detalle Error: cdarticulo ' || v_refid ||
                                       ' icprocesado ' || v_icprocesado);

         end;
       END LOOP;
     ELSE
      p_Ok:=0;
      p_error:='Error arreglo vacio no es posible actualizar collectionSKU';
   	  ROLLBACK;
      RETURN;
     END IF;
  COMMIT;
  p_Ok:=1;
  EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(1,
                            'Modulo: ' || v_Modulo || '  Error: ' ||
                            SQLERRM);
      p_Ok:=0;
      p_error:='Error no es posible actualizar collectionSKU';
   	  ROLLBACK;
      RETURN;
  END SetCollectionSKU;

   /***********************************************************************************************
  * %v 30/12/2020 - ChM - Obtiene cursor con todas las promociones no procesadas en VTEX
  * %v 18/06/2021 - ChM - divido por el minimo UV para convertir multiplicador
  * %v 01/07/2021 - ChM - Ajusto el calculo para promociones de mutiple UxB con igual UV
  * %v 14/07/2021 - ChM - Agrego cdpostal para las promociones
  * %v 27/07/2021 - ChM - Agrego id_canal, canales definen sites distintos en VTEX
  * %v 17/08/2021 - ChM - Agrego validaci�n para no subir promociones con a�o 9999
  * %v 13/01/2022 - ChM - se agrega id_promo_hija para resolver promos multiple UxB
  * %v 18/01/2022 - ChM - agrego id_canal en vtexpromotion por ajuste promos multiplie UxB <> UV
  ************************************************************************************************/

  PROCEDURE GetPromotion (-- p_cdsucursal In sucursales.cdsucursal%type,
                           p_idcanal    In vtexsellers.id_canal%type default 'VE',
                           Cur_Out      Out Cursor_Type) IS

    v_modulo        varchar2(100) := 'PKG_GetDatos_VTEX.GetPromotion';

  BEGIN

    OPEN cur_out FOR
        SELECT A.id_promo_pos,
               A.id_promo_hija,
               A.id_promo_vtex,
               A.name,
               A.begindateutc,
               A.enddateutc,
               A.isactive,
               A.percentualDiscountValue,
               A.percentualDiscountValueList,
               to_char(id_canal_vtex) idsSalesChannel,
               LISTAGG(trim(A.cdpostal), ', ') WITHIN GROUP (ORDER BY A.cdpostal) cdpostal,
               A.minimumQuantityBuyTogether,
               A.quantityToAffectBuyTogether,
               A.enableBuyTogetherPerSku,
               A.listSku1BuyTogether,
               A.type,
               A.cucarda,
               A.descripcion,
               A.cdpromo
          FROM (
         SELECT DISTINCT
                     vp.id_promo_pos,
                     vp.id_promo_hija,
                     vp.id_promo_vtex,
                     vp.name,
                     vp.begindateutc,
                     vp.enddateutc,
                     DECODE(vp.isactive,1,1,0) isactive,--desaticvar si es diferente de 1
                     DECODE(vp.type,1,100,vp.valoracc) percentualDiscountValue,
                     --multiplica x UxB para convertir bultos en unidades VTEX
                     DECODE(vp.type,1,null,'[{' ||
                        -- divido por el minimo UV para convertir multiplicador, si uxb es cero no se divide
                        decode(vp.Uxb,0,vp.valorcond,ceil((vp.valorcond*vp.uxb)/vp.minuv))||', ' ||vp.valoracc||'}]') percentualDiscountValueList,
                     --concatena las politicas comerciales separadas por coma
                     --1 canal main
                     /*(select distinct LISTAGG(vs2.id_canal_vtex, ', ') WITHIN GROUP (ORDER BY vs2.id_canal_vtex)
                       from vtexpromotion vp2,
                            vtexsellers   vs2
                      where vp2.id_promo_pos=vp.id_promo_pos
                        and vp2.cdsucursal=vp.cdsucursal
                        and vp2.cdsucursal=vs2.cdsucursal
                        and vp2.id_canal=vs2.id_canal
                        --solo sucursales activas
                        and vs2.icactivo=1) idsSalesChannel,*/
                        vs.id_canal_vtex,
                        vs.cdpostal,
                        -- divido por el minimo UV para convertir multiplicador, si uxb es cero no se divide
                        decode(vp.Uxb,0,vp.valorcond,ceil((vp.valorcond*vp.uxb)/vp.minuv)) minimumQuantityBuyTogether,
                        --Para tipo 7 = null Para tipo 1= los que van gratis LA RESTA ENTRE VALOR COND-VALOR ACC
                        --multiplica x UxB para convertir bultos en unidades VTEX
                       DECODE(vp.uxb,0,DECODE(vp.type,1,vp.valorcond-vp.valoracc,null),DECODE(vp.type,1,vp.valorcond-vp.valoracc,null)*vp.uxb) quantityToAffectBuyTogether,
                        --TRUE si monoproducto
                        DECODE(vp.multiproducto,0,1)enableBuyTogetherPerSku,
                     --concatena los SKUS separados por coma
                     ( select distinct LISTAGG(vps.skuid, ', ') WITHIN GROUP (ORDER BY vps.skuid)
                              from Vtexpromotionsku vps
                             where vps.id_promo_pos=vp.id_promo_pos
                               and vps.id_promo_hija=vp.id_promo_hija
                               and vps.id_canal=vp.id_canal) listSku1BuyTogether,
                        --Tipo 7 = "progressive" Tipo 1 = "forThePriceOf"
                        DECODE(vp.type,1,'forThePriceOf',7,'progressive') type,
                        vp.dscucarda cucarda,
                        case
                          when (INSTR(vp.dsleyendacorta,'BULTO')<>0 and INSTR(vp.dsleyendacorta,'cada')<> 0) then
                              'desde '||DECODE(VP.UXB,0,vp.valorcond,vp.valorcond*vp.uxb)||'  UNIDADES'
                          when (INSTR(vp.dsleyendacorta,'BULTO')<> 0 and INSTR(vp.dsleyendacorta,'desde')<> 0) then
                              'desde '||DECODE(VP.UXB,0,vp.valorcond,vp.valorcond*vp.uxb)||'  UNIDADES'
                          else
                            vp.dsleyendacorta
                        end descripcion,
                     --   trim(vp.id_promo_vtex) id_promo_vtex,
                        vp.cdpromo
                FROM vtexpromotion vp,
                     vtexsellers vs
               WHERE vs.cdsucursal = vp.cdsucursal
                 and vs.id_canal = vp.id_canal
                 and vs.icactivo = 1 --solo sucursales activas
                -- and vp.cdsucursal = p_cdsucursal
                 and vp.id_canal=p_idcanal --solo canal del parametro
                 and vp.icprocesado = 0 --lista solo promociones por procesar
                 --   valida o incluir solo promos con SKUs
                 and vp.id_promo_pos||vp.id_promo_hija||vp.id_canal  in ( select distinct vps.id_promo_pos||vps.id_promo_hija||vps.id_canal from Vtexpromotionsku vps)
                 -- verifica no incluir promos con multiproducto de diferentes UxB o con m�s de 100 SKUS
                 and vp.uxb>=0
                 and trim(EXTRACT(YEAR FROM vp.enddateutc))<> 9999 --valida no devolver promociones infinitas

              )A
              group by A.id_promo_pos,
                       A.id_promo_hija,
                       A.id_promo_vtex,
                       A.name,
                       A.begindateutc,
                       A.enddateutc,
                       A.isactive,
                       A.percentualDiscountValue,
                       A.id_canal_vtex,
                       A.percentualDiscountValueList,
                       A.minimumQuantityBuyTogether,
                       A.quantityToAffectBuyTogether,
                       A.enableBuyTogetherPerSku,
                       A.listSku1BuyTogether,
                       A.type,
                       A.cucarda,
                       A.descripcion,
                       A.cdpromo
                    ;
  EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(1,
                            'Modulo: ' || v_Modulo || '  Error: ' ||
                            SQLERRM);
      return;
  END GetPromotion;


 /***********************************************************************************************
  * %v 30/12/2020 - ChM - Actualiza a procesado el listado de promociones que recibe del arr_refid
  * %v 13/01/2022 - ChM - se agrega id_promo_hija para resolver promos multiple UxB
  ************************************************************************************************/

  PROCEDURE SetPromotion (p_refId IN arr_refId,
                          p_Ok    OUT number,
                          p_error OUT varchar2) IS

    v_modulo               varchar2(100) := 'PKG_GetDatos_VTEX.SetPromotion';
    v_idpromo_pos          vtexpromotion.id_promo_pos%type;
    v_idpromo_vtex         vtexpromotion.id_promo_vtex%type;
    v_id_promo_hija        vtexpromotion.id_promo_hija%type;
    v_icprocesado          vtexpromotion.icprocesado%type;
    v_cdsucursal           vtexpromotion.cdsucursal%type;
    v_id_canal             vtexpromotion.id_canal%type;
    v_observacion          vtexpromotion.observacion%type;

  BEGIN

     IF (p_refId(1) IS NOT NULL and LENGTH(TRIM(p_refId(1)))>1) THEN
       FOR i IN 1 .. p_refId.Count LOOP
          -- Cambio el tama�o del acuerdo de 32 + 4 m�s
          --separa del arreglo del 1-32 char del idpromo_pos
          -- 33 '-'
          --separa del arreglo del 34-37 char del id_promo_hija
          --separa del arreglo del 38-78 char del idpromo_vtex
          --el caracter 77 el estado puede ser : 1 procesado sin error, 2 procesado con error
          -- el carater 78 al 82 cdsucursal
          -- el carater 82 al 84 id_canal
          -- observacion 84 hasta 3900
          v_idpromo_pos:=trim(substr(p_refId(i),1,32));
          v_id_promo_hija:=to_number(trim(substr(p_refId(i),34,3)));
          v_idpromo_vtex:=trim(substr(p_refId(i),37,40));
          v_icprocesado:=to_number(substr(p_refId(i),77,1));
          v_cdsucursal:=rpad((trim(substr(p_refId(i),78,4))),8,' ');
          v_id_canal:=upper(trim(substr(p_refId(i),82,2)));
          v_observacion:= substr(p_refId(i),84,3900);
         --actualiza a procesado el articulo del arreglo
         begin
             update vtexpromotion vp
                set vp.id_promo_vtex = v_idpromo_vtex,
                    vp.icprocesado = v_icprocesado,
                    vp.dtprocesado = sysdate,
                    vp.observacion = v_observacion
              where vp.id_promo_pos = v_idpromo_pos
                and vp.id_promo_hija=v_id_promo_hija
             --   and vp.cdsucursal = v_cdsucursal
                and vp.id_canal = v_id_canal
                     ;

             exception
               when others then
                   n_pkg_vitalpos_log_general.write(1,
                                       'Modulo: ' || v_modulo ||
                                       ' Detalle Error: promotion ID ' || v_idpromo_pos ||
                                       ' icprocesado ' || v_icprocesado);

         end;
       END LOOP;
     ELSE
      p_Ok:=0;
      p_error:='Error Arreglo Vacio no es posible Actualizar Promociones';
   	  ROLLBACK;
      RETURN;
     END IF;
  COMMIT;
  p_Ok:=1;
  EXCEPTION
    WHEN OTHERS THEN
           n_pkg_vitalpos_log_general.write(1,
                               'Modulo: ' || v_modulo ||
                               ' Detalle Error: promotion ID ' || v_idpromo_pos ||
                               ' icprocesado ' || v_icprocesado);
      p_Ok:=0;
      p_error:='Error no es posible Actualizar Promociones';
   	  ROLLBACK;
      RETURN;
  END SetPromotion;

 /*******************************************************************************************************
  * %v 15/01/2021 - ChM - inserta el pedido de VTEX que llega a VITAL para entrar en la cola y ser
  *                       procesado por AC.
  * %v 27/07/2021 - ChM - Agrego id_canal, canales definen sites distintos en VTEX
  ********************************************************************************************************/

  PROCEDURE SetPedidosVtex (p_pedidoid_vtex  IN  vtexorders.pedidoid_vtex%type,
                           	p_id_canal       IN  vtexorders.id_canal%type,
                            p_Ok             OUT number,
                            p_error          OUT varchar2) IS

    v_modulo                varchar2(100) := 'PKG_GetDatos_VTEX.SetPedidosVtex';
    v_pedidoid_vtex         vtexorders.pedidoid_vtex%type:=null;

  BEGIN
    --verifica si el id pedido vtex ya existe en la tabla
    begin
        select distinct
               vo.pedidoid_vtex
          into v_pedidoid_vtex
          from vtexorders vo
         where vo.pedidoid_vtex = p_pedidoid_vtex
           and vo.id_canal = p_id_canal;
        if v_pedidoid_vtex is not null then
            p_Ok:=0;
            p_error:='Error el pedido VTEX ya existe';
            RETURN;
        end if;
    exception
      when others then
      v_pedidoid_vtex:=null;
    end;
     insert into vtexorders
                 (pedidoid_vtex,
                 idpedido_pos,
                 icprocesado,
                 dtprocesado,
                 observacion,
                 id_canal )
          values (p_pedidoid_vtex,
                 null,
                 0, --estado 0 pendiente por pasar a AC
                 sysdate,
                 null,
                 p_id_canal);
  commit;
   p_Ok:=1;
  EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(1,
                            'Modulo: ' || v_Modulo || '  Error: ' ||
                            SQLERRM||'detalle del error ID pedido VTEX: '||p_pedidoid_vtex);
      p_Ok:=0;
      p_error:='Error al insertar pedido de VTEX ' || SQLERRM;
   	  ROLLBACK;
      RETURN;
  END SetPedidosVtex;

 /***********************************************************************************************
  * %v 08/02/2021 - ChM - Obtiene cursor con todos los clientes nuevos o modificados en AC
  *                        no procesados en VTEX
  * %v 27/07/2021 - ChM - Agrego id_canal, canales definen sites distintos en VTEX
  * %v 11/01/2022 - ChM - Ajusto id_canal_alta
  ************************************************************************************************/

  PROCEDURE GetClients (p_id_canal       IN  vtexclients.id_canal%type,
                        Cur_Out          Out Cursor_Type) IS

    v_modulo        varchar2(100) := 'PKG_GetDatos_VTEX.GetClients';

  BEGIN

    OPEN cur_out FOR
            select distinct
             vc.clientsid_vtex,
             vc.id_cuenta,
             vc.agent,
             vc.icactive approved,
             vs.id_canal_vtex canal,
             vc.cuit corporateDocument,
             vc.razonsocial corporateName,
             vc.dsnombrefantasia TradeName,
             1 isCorporate,
             vc.icalcohol reba,
             vs.cdpostal,
             vs.cdsucursal_vtex sucursal,
             vc.email,
             vc.idagent customerClass
        from vtexclients vc,
             vtexsellers vs,
             vtexaddress  va
       where vc.cdsucursal = vs.cdsucursal
         and  vs.id_canal= NVL2(vc.id_canal_alta,vc.id_canal_alta,vc.id_canal)
         --solo clientes en sucursales activas en vtex
         and vs.icactivo = 1
         and va.id_cuenta = vc.id_cuenta--solo clientes con direcci�n
         and vc.icprocesado = 0 --solo pendientes por procesar
         and case
                --Alta solo clientes con agentes validos
                 when vc.icactive=1 and length(vc.idagent)>10 then
                     vs.id_canal
                 when vc.icactive=0  then
                    NVL2(vc.id_canal_alta,vc.id_canal_alta,vc.id_canal)
                end = p_id_canal
         ;
  EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(1,
                            'Modulo: ' || v_Modulo || '  Error: ' ||
                            SQLERRM);
      return;
  END GetClients;

  /***********************************************************************************************
  * %v 08/02/2021 - ChM - Actualiza a procesado el listado de clients que recibe del arr_refid
  * %v 22/07/2021 - ChM -agrego validacion para no recibir v_clientsid_vtex = 1
  * %v 16/09/2021 - ChM - Agrego eliminar los clientes con id_cuenta en 1
  * %V 06/01/2021 - ChM - Agrego id_canal_alta para mejora de bajas son agente asignado
  ************************************************************************************************/

  PROCEDURE SetClients (p_refId          IN  arr_refId,
                        p_Ok             OUT number,
                        p_error          OUT varchar2) IS

    v_modulo               varchar2(100) := 'PKG_GetDatos_VTEX.SetClients';
    v_id_cuenta            vtexclients.id_cuenta%type;
    v_clientsid_vtex       vtexclients.clientsid_vtex%type;
    v_icprocesado          vtexclients.icprocesado%type;
    v_observacion          vtexclients.observacion%type;
    v_id_canal             vtexclients.id_canal%type;
    v_id_canal_alta        vtexclients.id_canal_alta%type;

  BEGIN

     IF (p_refId(1) IS NOT NULL and LENGTH(TRIM(p_refId(1)))>1) THEN
       FOR i IN 1 .. p_refId.Count LOOP
          --separa del arreglo del 1 + 40 char del idcuenta
          --separa del arreglo del 41 + 40 char del clientsid_vtex
          --el caracter 81 + 1  el estado puede ser : 1 procesado sin error, 2 procesado con error
          --separa del arreglo 82 + 3900 observacion
          v_id_cuenta:=trim(substr(p_refId(i),1,40));
          v_clientsid_vtex:=nvl(trim(substr(p_refId(i),41,40)),1);
          v_icprocesado:=to_number(substr(p_refId(i),81,1));
          v_observacion:= substr(p_refId(i),82,3900);

          --verifica si v_clientsid_vtex = 1 error
          if trim(v_clientsid_vtex) is null or trim(v_clientsid_vtex)='1' then
            p_Ok:=0;
            p_error:='Error envio de clientsid_vtex en 1 o null';
   	        ROLLBACK;
            RETURN;
          end if;

          --eliminar los clientes con id_cuenta en 1 y sus direcciones
          if trim(v_id_cuenta)='1' then
              begin
                     delete vtexaddress va
                      where va.id_cuenta = v_id_cuenta
                        and va.clientsid_vtex = v_clientsid_vtex;
                     delete vtexclients vc
                      where vc.id_cuenta = v_id_cuenta
                        and vc.clientsid_vtex=v_clientsid_vtex;
                 exception
                   when others then
                       n_pkg_vitalpos_log_general.write(1,
                                           'Modulo: ' || v_modulo ||
                                           ' Detalle Error: id VTEX ' || v_clientsid_vtex ||
                                           ' icprocesado ' || v_icprocesado);

              end;
             --si borra no actualiza
             continue;
          else
             --actualiza a procesado el cliente del arreglo
             begin
                 update vtexclients vc
                    set vc.clientsid_vtex = v_clientsid_vtex,
                        vc.icprocesado = v_icprocesado,
                        vc.dtprocesado = sysdate,
                        vc.observacion = v_observacion
                  where vc.id_cuenta = v_id_cuenta
                    --actualizo nuevos o actuales clientes
                    --Comento por ajuste en delete de API de alta a VTEX ahora los idvtex varian siempre CHM 14/10/2021
                    --and (vc.clientsid_vtex = '1' or vc.clientsid_vtex=v_clientsid_vtex)
                  ;
                  --actualizo las direcciones asociadas al cliente para la consistencia de la BD
                    update vtexaddress va
                       set va.clientsid_vtex = v_clientsid_vtex
                     where va.id_cuenta = v_id_cuenta
                     --actualizo nuevos o actuales clientes
                      --Comento por ajuste en delete de API de alta a VTEX ahora los idvtex varian siempre CHM 14/10/2021
                     -- and (va.clientsid_vtex = '1' or va.clientsid_vtex=v_clientsid_vtex)
                       ;
               --busco el valor de canal de alta del cliente
               select c.id_canal_alta,
                      c.id_canal
                 into v_id_canal_alta,
                      v_id_canal
                 from vtexclients c
                where c.id_cuenta=v_id_cuenta
                  and c.clientsid_vtex=v_clientsid_vtex
                  and rownum=1;
                 --si es null lo actulizo al canal original
                if v_id_canal_alta is null then
                   update vtexclients vc
                      set vc.dtprocesado = sysdate,
                          vc.id_canal_alta=v_id_canal
                  where vc.id_cuenta = v_id_cuenta
                    and vc.clientsid_vtex = v_clientsid_vtex;
                end if;
             exception
               when others then
                   n_pkg_vitalpos_log_general.write(1,
                                       'Modulo: ' || v_modulo ||
                                       ' Detalle Error: id Cuenta ' || v_id_cuenta ||
                                       ' icprocesado ' || v_icprocesado);

              end;
          end if;
       END LOOP;
     ELSE
      p_Ok:=0;
      p_error:='Error Arreglo Vacio no es posible Actualizar Clientes';
   	  ROLLBACK;
      RETURN;
     END IF;
  COMMIT;
  p_Ok:=1;
  EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(1,
                            'Modulo: ' || v_Modulo || '  Error: ' ||
                            SQLERRM);
      p_Ok:=0;
      p_error:='Error no es posible Actualizar Clientes. Det: ' || SQLERRM;
   	  ROLLBACK;
      RETURN;
  END SetClients;
  /***********************************************************************************************
  * %v 09/02/2021 - ChM - Obtiene cursor con todas las direcciones de clientes nuevas o modificadas en AC
  *                        no procesados en VTEX
  * %v 27/07/2021 - ChM - Agrego id_canal, canales definen sites distintos en VTEX
  ************************************************************************************************/

  PROCEDURE GetAddress ( p_id_canal       IN  vtexclients.id_canal%type,
                         Cur_Out          Out Cursor_Type) IS

    v_modulo        varchar2(100) := 'PKG_GetDatos_VTEX.GetAddress';

  BEGIN

    OPEN cur_out FOR
          select distinct
                 va.id_cuenta,
                 va.clientsid_vtex,
                 va.iddireccion_vtex,
                 va.cdtipodireccion||lpad(to_char(va.sqdireccion),2,' ') reference,
                -- va.cdpostal PostalCode,
                 vs.cdpostal PostalCode,
                 va.dscalle street,
                 va.dsnumcalle number_street,
                 va.dsprovincia ||', '|| va.dslocalidad Barrio,
                 vs.dslocalidad city,
                 vs.dsprovincia state,
                 va.icactive
            from vtexaddress  va,
                 vtexclients  vc,
                 vtexsellers  vs
           where va.id_cuenta = vc.id_cuenta
             and va.clientsid_vtex = vc.clientsid_vtex
             and vc.id_canal = p_id_canal
             and vc.cdsucursal = vs.cdsucursal
             and vc.id_canal = vs.id_canal
             --  solo pendientes por procesar
             and va.icprocesado = 0
             --solo direcciones que ya tienen clientsid_vtex
             and va.clientsid_vtex <> '1'
             --no envio anulaciones nunca creadas en VTEX
             and case
                 	when va.icactive = 0 and va.iddireccion_vtex is null then 0
                    else 1
                 end = 1
         ;
  EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(1,
                            'Modulo: ' || v_Modulo || '  Error: ' ||
                            SQLERRM);
      return;
  END GetAddress;

  /***********************************************************************************************
  * %v 09/02/2021 - ChM - Actualiza a procesado el listado de direcciones que recibe del arr_refid
  ************************************************************************************************/

  PROCEDURE SetAddress  (p_refId IN arr_refId,
                        p_Ok    OUT number,
                        p_error OUT varchar2) IS

    v_modulo               varchar2(100) := 'PKG_GetDatos_VTEX.SetAddress';
    v_id_cuenta            vtexaddress.id_cuenta%type;
    v_clientsid_vtex       vtexaddress.clientsid_vtex%type;
    v_iddireccion_vtex     vtexaddress.iddireccion_vtex%type;
    v_cdtipodireccion      vtexaddress.cdtipodireccion%type;
    v_sqdireccion          vtexaddress.sqdireccion%type;
    v_icprocesado          vtexaddress.icprocesado%type;
    v_observacion          vtexaddress.observacion%type;


  BEGIN

     IF (p_refId(1) IS NOT NULL and LENGTH(TRIM(p_refId(1)))>1) THEN
       FOR i IN 1 .. p_refId.Count LOOP
          --separa del arreglo del 1 + 40 char del idcuenta
          --separa del arreglo del 41 + 40 char del clientsid_vtex
          --separa del arreglo del 81 + 40 char del iddireccion_vtex
          --separa del arreglo del 121 + 8 char del cdtipodireccion
          --separa del arreglo del 129 + 2 char del sqdireccion
          --el caracter 131 + 1  el estado puede ser : 1 procesado sin error, 2 procesado con error
          --separa del arreglo 132 + 3850 observacion
          v_id_cuenta:=trim(substr(p_refId(i),1,40));
          v_clientsid_vtex:=trim(substr(p_refId(i),41,40));
          v_iddireccion_vtex:=trim(substr(p_refId(i),81,40));
          v_cdtipodireccion:=trim(substr(p_refId(i),121,8));
          v_sqdireccion:= to_number(substr(p_refId(i),129,2));
          v_icprocesado:=to_number(substr(p_refId(i),131,1));
          v_observacion:= substr(p_refId(i),132,3850);

          --verifica si v_clientsid_vtex = 1 error
          if trim(v_clientsid_vtex) is null or trim(v_clientsid_vtex)='1' then
            p_Ok:=0;
            p_error:='Error envio de clientsid_vtex en 1 o null';
   	        ROLLBACK;
            RETURN;
          end if;

         --actualiza a procesado la direcci�n del arreglo
         begin
                --actualizo las direcciones asociadas al cliente
                update vtexaddress va
                   set va.iddireccion_vtex = v_iddireccion_vtex,
                       va.icprocesado = v_icprocesado,
                       va.dtprocesado = sysdate,
                       va.observacion = v_observacion
                 where va.id_cuenta = v_id_cuenta
                   and va.clientsid_vtex = v_clientsid_vtex
                   and va.cdtipodireccion = v_cdtipodireccion
                   and va.sqdireccion = v_sqdireccion;
             exception
               when others then
                   n_pkg_vitalpos_log_general.write(1,
                                       'Modulo: ' || v_modulo ||
                                       ' Detalle Error: id Cuenta ' || v_id_cuenta ||
                                       ' icprocesado ' || v_icprocesado);

         end;
       END LOOP;
     ELSE
      p_Ok:=0;
      p_error:='Error Arreglo Vacio no es posible Actualizar Direcciones';
   	  ROLLBACK;
      RETURN;
     END IF;
  COMMIT;
  p_Ok:=1;
  EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(1,
                            'Modulo: ' || v_Modulo || '  Error: ' ||
                            SQLERRM);
      p_Ok:=0;
      p_error:='Error no es posible Actualizar Direcciones';
   	  ROLLBACK;
      RETURN;
  END SetAddress;

end PKG_GETDATOS_VTEX;
/
