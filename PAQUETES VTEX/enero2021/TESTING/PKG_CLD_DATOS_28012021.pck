CREATE OR REPLACE PACKAGE PKG_CLD_DATOS is

  type cursor_type Is Ref Cursor;

  TYPE PRODUCT IS RECORD (
        productid     INTEGER,
        name          VARCHAR2(140),
        departmentid  INTEGER,
        categoryid    INTEGER,
        subcategoryid INTEGER,
        brandid       INTEGER,
        linkid        VARCHAR2(160),
        refid         CHAR(8),
        isvisible     INTEGER,
        description   VARCHAR2(140),
        releasedate   DATE,
        isactive      INTEGER,
        icnuevo       INTEGER,
        dtinsert      DATE,
        dtupdate      DATE,
        factor        INTEGER,
        uxb           INTEGER,
        vtaxunidad    CHAR(8),
        observacion   VARCHAR2(4000),
        icprocesado   INTEGER,
        dtprocesado   DATE);

  type t_product is table of PRODUCT index by binary_integer;
  type t_product_pipe is table of PRODUCT;

 
  type t_SKU is table of VTEXSKU%ROWTYPE index by binary_integer;
  type t_SKU_pipe is table of VTEXSKU%ROWTYPE;
  
  TYPE arr_refid IS TABLE OF VARCHAR(100) INDEX BY PLS_INTEGER;
  
  FUNCTION GETPrecioSinIVA (p_cdarticulo articulos.cdarticulo%type,
                            p_cdsucursal sucursales.cdsucursal%type,
                            p_precio     tblprecio.amprecio%type) RETURN NUMBER; 

  FUNCTION GETPrecioconIVA (p_cdarticulo articulos.cdarticulo%type,
                            p_cdsucursal sucursales.cdsucursal%type,
                            p_precio     tblprecio.amprecio%type) RETURN NUMBER;

  FUNCTION GETFACTOR (P_CDARTICULO ARTICULOS.CDARTICULO%TYPE) RETURN INTEGER;

  Function Pipeproducts Return t_product_pipe pipelined;
  Function PipeSKUS Return t_SKU_pipe pipelined;

  PROCEDURE CargarProduct;
  PROCEDURE RefrescarProduct;
  PROCEDURE CargarSKU;
  PROCEDURE RefrescarSKU;
  PROCEDURE CargarStock;
  Procedure RefrescarClientesApp;
  PROCEDURE RefrescarPreciosVTEX (p_Fecha IN tblprecio.dtvigenciadesde%type);
  PROCEDURE RefrescarPromos (p_Fecha IN tblprecio.dtvigenciadesde%type);
  FUNCTION revisarmultipleUxB (p_id_promo TBLPROMO.ID_PROMO%type) RETURN integer; 
  FUNCTION promoSKU (p_id_promo TBLPROMO.ID_PROMO%type) RETURN integer;
  FUNCTION FnLeyendaPromoCorta(p_id_promo IN tblpromo.id_promo%type)  return varchar2;
  FUNCTION LeyendasPromoCucarda(p_id_promo tblpromo.id_promo%type) RETURN varchar2;
  PROCEDURE GetPedidosVtex (Cur_Out Out Cursor_Type);
  
  PROCEDURE InsertarPedidoPOS (p_pedidoid_vtex       IN  vtexpedidos.pedidoid_vtex%type,
                              p_cabecera            IN  varchar2,
                              p_detalle             IN  arr_refId);
  

end PKG_CLD_DATOS;
/
CREATE OR REPLACE PACKAGE BODY PKG_CLD_DATOS is

 g_l_product t_product;
 g_1_SKU t_SKU;

  /*****************************************************************************************
  * %v 04/10/2017 - IAquilano - Actualizo datos en la tabla clientes
  * %v 09/11/2017 - IAquilano - Agrego controles en las exceptions para loguear errores.
  * %v 08/05/2019 - IAquilano - Modifico agregando IF para controlar VPV innecesaria para comi
  * %v 14/02/2020 - IAguilano - Modifico para controlar marca para VitalDigital
  * %v 02/03/2020 - IAquilano - Agrego NVL a la comparativa de la tarjeta cliente fidelizado
  * %v 13/03/2020 - IAquilano - Agrego update de la razon social
  * %v 16/03/2020 - IAquilano - Bloqueo de consumidor final a la aplicacion vital digital.
  ******************************************************************************************/
  Procedure RefrescarClientesApp Is

    --v_modulo       VARCHAR2(100) := 'PKG_CLD_DATOS.RefrescarTablaClientes';
    v_codigovpv      tjclientescf.vlcodbar%type;
    v_fechaemision   varchar2(10);
    v_calle          direccionesentidades.dscalle%type;
    v_numerocalle    direccionesentidades.dsnumero%type;
    v_localidad      localidades.dslocalidad%type;
    v_codigopostal   direccionesentidades.cdcodigopostal%type;
    v_provincia      provincias.dsprovincia%type;
    v_esvpvdorada    integer;
    v_mail           tblentidadaplicacion.mail%type; --agreego variable mail
    v_idcuenta       tblentidadaplicacion.idcuenta%type; -- agrego variable cuenta
    v_icrequieretjcf integer;
    v_iccomi         integer;
    v_razonsocial    entidades.dsrazonsocial%type;
    v_cantapp        integer;
    v_situacioniva   integer;
    v_cantactivas    integer;
    v_iccf           integer;
    v_icactivo       integer;

  Begin

    -- Proceso actualizaciones
    -- Para las cuentas ya ingresadas en GWV
    for r in (select * from tblclientes_s) loop
      -- levanto los datos de POS y comparo
      Begin
        select distinct nvl(tv.vlcodbar,0) vlcodbar,
                        trunc(nvl(nvl(tv.fchultimareimp, tv.fchalta),sysdate)),
                        de.dscalle,
                        de.dsnumero,
                        l.dslocalidad,
                        de.cdcodigopostal,
                        p.dsprovincia,
                        case (select 1
                            from tblvpventidad te
                           where te.identidad = e.identidad)
                          when 1 then
                           '1'
                          else
                           '0'
                        end esvpvdorada,
                        ta.mail,
                        ta.idcuenta,
                        e.dsrazonsocial
          into v_codigovpv,
               v_fechaemision,
               v_calle,
               v_numerocalle,
               v_localidad,
               v_codigopostal,
               v_provincia,
               v_esvpvdorada,
               v_mail,
               v_idcuenta,
               v_razonsocial
          from tblentidadaplicacion ta,
               entidades            e,
               tblcuenta            tc,
               tjclientescf         tv,
               direccionesentidades de,
               localidades          l,
               provincias           p
         where ta.idcuenta = r.idcuenta
           and ta.identidad = e.identidad
           and tv.identidad(+) = ta.identidad
           and de.identidad = ta.identidad
           and tc.idcuenta = ta.idcuenta
           and l.cdlocalidad = de.cdlocalidad
           and de.cdpais = p.cdpais
           and de.cdprovincia = p.cdprovincia
           and de.cdpais = l.cdpais
           and de.cdprovincia = l.cdprovincia
           and de.cdtipodireccion = '2'
           and de.icactiva = '1';

      EXCEPTION
        WHEN NO_DATA_FOUND then
          GOTO end_loop;
        WHEN OTHERS THEN
          pkg_control.GrabarMensaje(sys_guid(),
                                    null,
                                    sysdate,
                                    ' Error select del update',
                                    'IDCUENTA: ' || r.idcuenta ||
                                    ' Error ORA: ' || sqlerrm,
                                    0);
          GOTO end_loop;
      End;

    --contamos cuantas aplicaciones activas tiene, por si alguna cuenta se deshabilito.
    select count(*)
    into v_cantactivas
    from tblentidadaplicacion tc
    where tc.idcuenta = r.idcuenta
    and tc.icactivo = 1;

    --Si no tiene aplicaciones habilitadas, marco en la clientesapp como cuenta desactivada para aplicaciones y me voy del loop.
    If v_cantactivas = 0 then
      update tblclientes_s tc
      set tc.icactivo = 0,
          tc.icprocesado = 0
      where tc.idcuenta = r.idcuenta;

      GOTO end_loop;

    else --tiene al menos una aplicacion activa

       IF v_cantactivas > 1 then
          --si tiene mas de una aplicacion activa, asumimos que tiene comi
           v_iccomi := 1;
           v_icactivo := 1;
         else
          -- si tiene una aplicacion sola, busco cual es la activa
          select distinct decode(ta.vlaplicacion,
                                   'MiVital',
                                   0,
                                   'Vital Digital',
                                   1)
              into v_iccomi
              from tblentidadaplicacion ta, tblaplicacionautorizacion taa
             where ta.vlaplicacion = taa.vlaplicacion
               and ta.idcuenta = r.idcuenta
               and ta.icactivo = 1;

               v_icactivo := 1;
         End if;
       end if;

      --Busco situacion de iva
      select distinct ie.cdsituacioniva
        into v_situacioniva
        from tblentidadaplicacion ta, infoimpuestosentidades ie
       where ta.identidad = ie.identidad
         and ta.idcuenta = r.idcuenta;

    --Si es Consumidor Final lo marco
      IF v_situacioniva = 48 then
        v_iccf := 1;
        else
        v_iccf := 0;

      end if;

    --Actualizamos ahora con todos los valores nuevos la Clientesapp
      Begin
        Update tblclientes_s tc
           set tc.email        = v_mail,
               tc.codigovpv    = v_codigovpv,
               tc.fechaemision = v_fechaemision,
               tc.calle        = v_calle,
               tc.numerocalle  = v_numerocalle,
               tc.localidad    = v_localidad,
               tc.codigopostal = v_codigopostal,
               tc.provincia    = v_provincia,
               tc.esvpvdorada  = v_esvpvdorada,
               tc.dtupdate     = sysdate,
               tc.razonsocial  = v_razonsocial,
               tc.iccomi       = v_iccomi,
               tc.iccf         = v_iccf,--agrego marca consumidor final
               tc.icactivo     = v_icactivo,--agrego la columna activo
               tc.icprocesado  = 0 --agregamos columna de procesado
         where tc.idcuenta = r.idcuenta
           and (nvl(r.codigovpv, '0') <> v_codigovpv or
               nvl(trunc(r.fechaemision),sysdate) <> v_fechaemision or
               r.calle <> v_calle or
               r.numerocalle <> v_numerocalle or
               r.localidad <> v_localidad or
               r.codigopostal <> v_codigopostal or
               r.provincia <> v_provincia or
               nvl(r.esvpvdorada, 0) <> v_esvpvdorada or
               r.razonsocial <> v_razonsocial or
               r.email <> v_mail or
               r.iccomi <> v_iccomi or
               r.iccf <> v_iccf or
               r.icactivo <> v_icactivo);

      EXCEPTION
        WHEN others THEN
          pkg_control.GrabarMensaje(sys_guid(),
                                    null,
                                    sysdate,
                                    'Error en Update de todos los campos',
                                    sqlerrm,
                                    0);
          GOTO end_loop;
      End;

      commit;

      <<end_loop>>
      null;
    end loop; --finalizo el loop

    Commit; --Finalizo el update con este commit

    -- Proceso Altas.
    -- todos los clientes con alguna aplicaci�n activa que no esten en GWV
    For r in (select ta.idcuenta,
                     ta.identidad,
                     ta.mail,
                     count(distinct(ta.vlaplicacion)) cantapp,
                     ie.cdsituacioniva
                from tblentidadaplicacion ta, infoimpuestosentidades ie
               where ta.idcuenta not in (select idcuenta from tblclientes_s)
                 and ta.icactivo = 1
                 and ie.identidad = ta.identidad
               group by ta.idcuenta,
                        ta.identidad,
                        ta.mail,
                        ie.cdsituacioniva) loop
      -- si tiene 2 o mas app distintas, directamente asumo que tiene VitalDigital (comi)
      IF r.cantapp > 1 then
        --Busco si tiene mas de una app habilitada
        select count(*)
          into v_cantapp
          from tblentidadaplicacion ta
         where ta.idcuenta = r.idcuenta
           and ta.icactivo = 1;
        --Si tiene mas de una habilitada, asumo que tiene vital digital (comi)
        If v_cantapp > 1 then
          v_icrequieretjcf := 1; -- la necesita para MiVital
          v_iccomi         := 1; -- la necesita para entrar a VitalDigital
        else
          -- sino busco que app tiene habilitada
          begin
            select distinct decode(ta.vlaplicacion,
                                   'MiVital',
                                   0,
                                   'Vital Digital',
                                   1),
                            taa.icrequieretjcf
              into v_iccomi, v_icrequieretjcf
              from tblentidadaplicacion ta, tblaplicacionautorizacion taa
             where ta.vlaplicacion = taa.vlaplicacion
               and ta.idcuenta = r.idcuenta;
          EXCEPTION
            when others then
              v_icrequieretjcf := 1;
              v_iccomi         := 0;
          end;
        end if;
      else
        -- sino busco que app tiene habilitada
        begin
          select distinct decode(ta.vlaplicacion,
                                 'MiVital',
                                 0,
                                 'Vital Digital',
                                 1),
                          taa.icrequieretjcf
            into v_iccomi, v_icrequieretjcf
            from tblentidadaplicacion ta, tblaplicacionautorizacion taa
           where ta.vlaplicacion = taa.vlaplicacion
             and ta.idcuenta = r.idcuenta;
        EXCEPTION
          when others then
            v_icrequieretjcf := 1;
            v_iccomi         := 0;
        end;
      end if;

      -- Marca consumidores finales a vital digital
        IF r.cdsituacioniva = 48 then
        v_iccf := 1;
        else
        v_iccf := 0;

      end if;

      Begin
        IF v_icrequieretjcf = 0 then
          --si no necesito vpv
          --INSERT
          insert into tblclientes_s
            (email,
             razonsocial,
             cuit,
             idcuenta,
             nombrecuenta,
             sucursal,
             codigovpv,
             esvpvdorada,
             fechaemision,
             calle,
             numerocalle,
             localidad,
             codigopostal,
             provincia,
             iccomi,
             icprocesado,
             icactivo,
             iccf)
            select distinct ta.mail,
                            e.dsrazonsocial,
                            e.cdcuit,
                            ta.idcuenta,
                            tc.nombrecuenta,
                            to_number(ta.cdsucursal),
                            null,
                            null,
                            null,
                            de.dscalle,
                            de.dsnumero,
                            l.dslocalidad,
                            de.cdcodigopostal,
                            p.dsprovincia,
                            v_iccomi,
                            '0' as icprocesado,
                            '1' as icactivo,
                            v_iccf
              from tblentidadaplicacion ta,
                   entidades            e,
                   tblcuenta            tc,
                   direccionesentidades de,
                   localidades          l,
                   provincias           p
             where ta.idcuenta = r.idcuenta
               and ta.identidad = e.identidad
               and de.identidad = ta.identidad
               and tc.idcuenta = ta.idcuenta
               and l.cdlocalidad = de.cdlocalidad
               and de.cdpais = p.cdpais
               and de.cdprovincia = p.cdprovincia
               and de.cdpais = l.cdpais
               and de.cdprovincia = l.cdprovincia
               and de.cdtipodireccion = '2'
               and de.icactiva = '1';

        Else
          --si necesito vpv

          insert into tblclientes_s
            (email,
             razonsocial,
             cuit,
             idcuenta,
             nombrecuenta,
             sucursal,
             codigovpv,
             esvpvdorada,
             fechaemision,
             calle,
             numerocalle,
             localidad,
             codigopostal,
             provincia,
             iccomi,
             icprocesado,
             icactivo,
             iccf)
            select distinct ta.mail,
                            e.dsrazonsocial,
                            e.cdcuit,
                            ta.idcuenta,
                            tc.nombrecuenta,
                            to_number(ta.cdsucursal),
                            tv.vlcodbar,
                            case (select 1
                                from tblvpventidad te
                               where te.identidad = e.identidad)
                              when 1 then
                               '1'
                              else
                               '0'
                            end esvpvdorada,
                            trunc(nvl(tv.fchultimareimp, tv.fchalta)),
                            de.dscalle,
                            de.dsnumero,
                            l.dslocalidad,
                            de.cdcodigopostal,
                            p.dsprovincia,
                            v_iccomi,
                            '0' as icprocesado,
                            '1' as icactivo,
                            v_iccf
              from tblentidadaplicacion ta,
                   entidades            e,
                   tblcuenta            tc,
                   tjclientescf         tv,
                   direccionesentidades de,
                   localidades          l,
                   provincias           p
             where ta.idcuenta = r.idcuenta
               and ta.identidad = e.identidad
               and tv.identidad = ta.identidad(+)
               and de.identidad = ta.identidad
               and tc.idcuenta = ta.idcuenta
               and l.cdlocalidad = de.cdlocalidad
               and de.cdpais = p.cdpais
               and de.cdprovincia = p.cdprovincia
               and de.cdpais = l.cdpais
               and de.cdprovincia = l.cdprovincia
               and de.cdtipodireccion = '2'
               and de.icactiva = '1';
        end if;

        commit;

      EXCEPTION
        WHEN others THEN
          pkg_control.GrabarMensaje(sys_guid(),
                                    null,
                                    sysdate,
                                    'Error en el insert',
                                    ' Error ORA: ' || sqlerrm ||
                                    ', r.idcuenta: ' || r.idcuenta ||
                                    ' ,r.identidad' || r.identidad ||
                                    ', mail:' || r.mail,
                                    0);
          GOTO end_loop;

      End;
      <<end_loop>>
      null;
    end loop;
    commit;

  EXCEPTION
    WHEN OTHERS THEN
      pkg_control.GrabarMensaje(sys_guid(),
                                null,
                                sysdate,
                                'Error en refresco de clientes cld',
                                ' Error ORA: ' || sqlerrm,
                                0);

  End RefrescarClientesApp;
  
/**************************************************************************************************
* devuelve el precio sin IVA del articulo que recibe
* %v 27/01/2021 - ChM
***************************************************************************************************/
  FUNCTION GETPrecioSinIVA (p_cdarticulo articulos.cdarticulo%type,
                            p_cdsucursal sucursales.cdsucursal%type,
                            p_precio     tblprecio.amprecio%type) RETURN NUMBER IS

   v_ImpInt             number;
   v_PorcIva            number;
   v_precioSinIva       number:=p_precio;

  BEGIN
--Buscar el IVA del art�culo
   v_PorcIva := PKG_PRECIO.GetIvaArticulo(p_cdarticulo);

   --busca impuesto interno del articulo
   v_ImpInt  := pkg_impuesto_central.GetImpuestoInterno(p_cdsucursal, p_cdarticulo);

   --calcular precio SIN iva
   v_precioSinIva := (p_precio-v_ImpInt)/(1+(v_PorcIva/100));

   --suma impuesto interno
   v_precioSinIva := v_precioSinIva + v_ImpInt;

   --redondeo amprecio a dos decimales
   v_precioSinIva := round(v_precioSinIva,2);

 RETURN  v_precioSinIva;

 END GETPrecioSinIVA;


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
* devuelve el precio con IVA del articulo que recibe
* %v 10/12/2020 - ChM
***************************************************************************************************/
  FUNCTION GETPrecioconIVA (p_cdarticulo articulos.cdarticulo%type,
                            p_cdsucursal sucursales.cdsucursal%type,
                            p_precio     tblprecio.amprecio%type) RETURN NUMBER IS

   v_ImpInt             number;
   v_PorcIva            number;
   v_precioConIva       number:=p_precio;

  BEGIN
--Buscar el IVA del art�culo
   v_PorcIva := PKG_PRECIO.GetIvaArticulo(p_cdarticulo);

   --busca impuesto interno del articulo
   v_ImpInt  := pkg_impuesto_central.GetImpuestoInterno(p_cdsucursal, p_cdarticulo);

   --calcular precio con iva
   v_precioConIva := (p_precio-v_ImpInt)*(1+(v_PorcIva/100));

   --suma impuesto interno
   v_precioConIva := v_precioConIva + v_ImpInt;

   --redondeo amprecio a dos decimales
   v_precioConIva := round(v_precioConIva,2);

 RETURN  v_precioConIva;

 END GETPrecioconIVA;

/**************************************************************************************************
* devuelve el facto del articulo
* %v 20/11/2020 - ChM
***************************************************************************************************/
  FUNCTION GETFACTOR (P_CDARTICULO ARTICULOS.CDARTICULO%TYPE) RETURN INTEGER IS
    V_FACTOR INTEGER:=1;
    BEGIN
      select max(pc.factor)
        into V_FACTOR
        from tbllista_precio_central pc
       where pc.cdarticulo=p_cdarticulo;
       RETURN nvl(V_FACTOR,1);
  EXCEPTION
  WHEN OTHERS THEN
    RETURN 1;
END  GETFACTOR;


/**************************************************************************************************
* Carga en una tabla global en memoria los datos de todos los art�culos activos en AC
* %v 16/11/2020 - ChM
***************************************************************************************************/
PROCEDURE CargarTablaProduct IS
  v_Modulo varchar2(100) := 'PKG_CLD_DATOS.CargarTablaProduct';
  i        binary_integer := 1;



BEGIN
     for r_product in
      (select distinct to_number(ar.cdarticulo) productID,
             nvl(trim(ae.vldescripcion),da.vldescripcion) name,
             vc.departmentid,
             vc.categoryid,
             vc.subcategoryid,
             NVL(vb.brandid,99999) brandid, --MARCA GENERICA
             nvl(trim(ae.vldescripcion),da.vldescripcion)||'-'||to_number(ar.cdarticulo) linkid,
             ar.cdarticulo refid,
             --estado 07 articulo activo pero no visible al cliente
             DECODE(trim(ar.cdestadoplu),'07',0,1) isvisible,
             nvl(trim(ae.vldescripcion),da.vldescripcion) description,
             ar.dtinsertplu releasedate,
             1 isactive,
             1 icnuevo,
             sysdate dtinsert,
             null dtupdate,
             pkg_cld_datos.GETFACTOR(ar.cdarticulo) factor,
             case
              when exists (select 1 from tbl_aux_art_unidad au
                           where au.dsuniverso = u.dsuniverso
                           and au.dscategoria = c.dscategoria
                           and au.dssubcategoria = sc.dssubcategoria
                           )
                    or ar.cdunidadventaminima not in ('BTO','UN') -- son pesables
                then ar.cdunidadventaminima
              else 'BTO'
              end  vtaxunidad,
             n_pkg_vitalpos_materiales.GetUxB(ar.cdarticulo) UXB,
             null observacion,
             0 icprocesado, --indica se debe procesar a VTEX
             null dtprocesado
       from articulos                    ar,
            descripcionesarticulos       da,
            tblarticulonombreecommerce   ae,
            tblctgryarticulocategorizado a,
            VTEXARTICULOSCATEGORIZADOS   ac,
            tblctgrydepartamento         d,
            tblctgryuniverso             u,
            tblctgrycategoria            c,
            tblctgrysubcategoria         sc,
            vtexbrand                    vb,
            vtexcatalog                  vc
      where ar.cdarticulo = da.cdarticulo
        and ar.cdestadoplu in('00','07')  --OJO 00 activo para la venta 07 no visible 03 articulo desactivado permanentemente
        and not exists
      (select 1
               from articulosnocomerciales t
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
        and a.cdarticulo = ar.cdarticulo
        and NVL(ar.cddrugstore,'XX') not in ('EX', 'DE', 'CP')
        and upper(trim(ae.vlmarca))= vb.name(+)
        and a.cdarticulo = ac.cdarticulo
        and vc.departmentid = ac.departmentid
        and vc.categoryid = ac.categoryid
        and vc.subcategoryid =ac.subcategoryid)
    LOOP
    --procesar cada una de las filas
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
        g_l_product(i).dtupdate := r_product.dtupdate;      --cargo el cursor en la tabla en memoria
        g_l_product(i).factor := r_product.factor;
        g_l_product(i).uxb := r_product.uxb;
        g_l_product(i).vtaxunidad := r_product.vtaxunidad;
        g_l_product(i).observacion := r_product.observacion;
        g_l_product(i).icprocesado := r_product.icprocesado;
        g_l_product(i).dtprocesado := r_product.dtprocesado;

     --verifica si se vende por BTO y UxB diferente de 1
     --null en factor articulo solo se vende x BTO
    if g_l_product(i).vtaxunidad = 'BTO' and g_l_product(i).uxb <> 1 then
       g_l_product(i).factor:=null;
    end if;

    --valida si uxb = 1 null para VTEX
    if g_l_product(i).uxb = 1 then
      g_l_product(i).uxb:=null;
    end if;
    i:=i+1;
   END LOOP;

EXCEPTION
  WHEN OTHERS THEN
    n_pkg_vitalpos_log_general.write(1,
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
  v_Modulo varchar2(100) := 'PKG_CLD_DATOS.CargarProduct';

BEGIN

  DELETE vtexproduct;
  g_l_product.delete;
  -- llena la tabla en memoria
  CargarTablaproduct;
  -- la inserta en la definitiva
  insert into vtexproduct
    select tvp.productid,
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
           tvp.dtprocesado From Table(Pipeproducts) tvp;

  commit;

EXCEPTION
  WHEN OTHERS THEN
    n_pkg_vitalpos_log_general.write(1,
                          'Modulo: ' || v_Modulo || '  Error: ' || SQLERRM);
END CargarProduct;

/**************************************************************************************************
* Carga productos nuevos y actualiza los modificados de la tabla VTEXPRODUCT
* Si el articulo esta activo (1) en VTEX y se dio de Baja en AC (03) tambien actualiza la baja a VTEX (0)
* %v 16/11/2020 - ChM
***************************************************************************************************/
PROCEDURE RefrescarProduct IS
  v_Modulo varchar2(100) := 'PKG_CLD_DATOS.RefrescarProduct';

BEGIN

  g_l_product.delete;
  -- llena la tabla en memoria con los articulos activos de AC
  CargarTablaProduct;

  merge into vtexproduct vp
  using (select *
           From Table(Pipeproducts)) tvp
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
        set vp.name = tvp.name,
            vp.departmentid = tvp.departmentid,
            vp.categoryid = tvp.categoryid,
            vp.subcategoryid = tvp.subcategoryid,
            vp.brandid = tvp.brandid,
            vp.linkid = tvp.linkid,
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
         or nvl(vp.factor,0) <> nvl(tvp.factor,0)
         or nvl(vp.uxb,0) <> nvl(tvp.uxb,0);

        --esto ocurre cuando un articulo de AC viene en estado 03
        --esta logica pone active 0 baja definitiva de un articulo en VTEX
        --solo si a�n esta active en 1
        update vtexproduct vp
          set vp.isactive = 0,
              vp.icprocesado = 0, -- 0 para procesar en API de VTEX
              vp.dtupdate = sysdate
          where vp.isactive = 1  -- solo doy de baja los activos
            and vp.refid in (select distinct ar.cdarticulo
                               from articulos                    ar
                              where ar.cdestadoplu in ('03','01')  --03 articulo desactivado permanentemente 01 no habilitado para la venta
                                and not exists
                              (select 1
                                       from articulosnocomerciales t
                                      where t.cdarticulo = ar.cdarticulo)
                                and not exists
                              (select 1
                                       from articulos_excluidos h
                                      where h.cdarticulo = ar.cdarticulo) --agrego tabla articulos excluidos
                                and substr(ar.cdarticulo, 1, 1) <> 'A'
                                and nvl(ar.cddrugstore,'XX') not in ('EX', 'DE', 'CP')
                                and exists --verifica que el articulo exista en VTEX
                                (select 1
                                        from vtexproduct vp
                                       where vp.refid = ar.cdarticulo));
  commit;

EXCEPTION
  WHEN OTHERS THEN
    n_pkg_vitalpos_log_general.write(1,
                          'Modulo: ' || v_Modulo || '  Error: ' || SQLERRM);
END RefrescarProduct;
/*************************************************************************************************************
* Carga en una tabla global en memoria los datos de todos los art�culos activos en AC en los SKU por product
* %v 17/11/2020 - ChM
*************************************************************************************************************/
PROCEDURE CargarTablaSKU IS
  v_Modulo varchar2(100) := 'PKG_CLD_DATOS.CargarTablaSKU';

  CURSOR c_sku IS
      select distinct
             vp.refid SKUid,
             vp.refid,
             vp.name skuname,
             vp.isactive, --utilizo el isactive del producto padre para activar o no el SKU hijo
             vp.releasedate CREATIONDATE,
             1 unitmultiplier,
             'UN' measurementunit,
             null dtupdate,
             0 icprocesado,
             null observacion,
             sysdate dtinsert,
             null dtprocesado,
             nvl(n_pkg_vitalpos_materiales.GetCodigoBarras (vp.refid),0) EAN
        from VTEXPRODUCT      VP;
BEGIN
      OPEN c_sku;
     FETCH c_sku  BULK COLLECT INTO g_1_SKU;      --cargo el cursor en la tabla en memoria
     CLOSE c_sku;
EXCEPTION
  WHEN OTHERS THEN
    n_pkg_vitalpos_log_general.write(1,
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
  v_Modulo varchar2(100) := 'PKG_CLD_DATOS.CargarSKU';

BEGIN

  delete vtexSKU;
  g_1_SKU.delete;
  -- llena la tabla en memoria
  CargarTablaSKU;
  -- la inserta en la definitiva
  insert into vtexSKU
    select * From Table(PipeSKUs);
--actualizar a icporcesado=0 del producto cuando se modifique un SKU
  update vtexproduct vp
     set vp.icprocesado = 0,
         vp.observacion=null,
         vp.dtupdate=sysdate-- 0 para procesar en API de VTEX
   where vp.refid in (select vs.refid from vtexsku vs where vs.icprocesado = 0);
  commit;

EXCEPTION
  WHEN OTHERS THEN
    n_pkg_vitalpos_log_general.write(1,
                          'Modulo: ' || v_Modulo || '  Error: ' || SQLERRM);
END CargarSKU;

/**************************************************************************************************
* Carga SKUS nuevos y actualiza los modificados de la tabla VTEXSKU
* %v 17/11/2020 - ChM
***************************************************************************************************/
PROCEDURE RefrescarSKU IS
  v_Modulo varchar2(100) := 'PKG_CLD_DATOS.RefrescarSKU';

BEGIN

  g_1_SKU.delete;
  -- llena la tabla en memoria con los SKUS activos de AC
  CargarTablaSKU;

  merge into vtexsku vs
  using (select *
       From Table(PipeSKUs)) tvs
  on (vs.refid = tvs.refid)
  when not matched then -- altas
    insert
      (skuid,
       refid,
       skuname,
       isactive,
       creationdate,
       unitmultiplier,
       measurementunit,
       dtupdate,
       icprocesado,
       observacion,
       dtinsert,
       dtprocesado,
       ean)
    values
      (tvs.skuid,
       tvs.refid,
       tvs.skuname,
       tvs.isactive,
       tvs.creationdate,
       tvs.unitmultiplier,
       tvs.measurementunit,
       tvs.dtupdate,
       tvs.icprocesado,
       tvs.observacion,
       tvs.dtinsert,
       tvs.dtprocesado,
       tvs.ean)
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
          or vs.measurementunit <> tvs.measurementunit;
--actualizar a icporcesado=0 del producto cuando se modifique un SKU
  update vtexproduct vp
     set vp.icprocesado = 0,
         vp.observacion=null,
         vp.dtupdate=sysdate-- 0 para procesar en API de VTEX
   where vp.refid in (select vs.refid from vtexsku vs where vs.icprocesado = 0);
  commit;

EXCEPTION
  WHEN OTHERS THEN
   n_pkg_vitalpos_log_general.write(1,
                          'Modulo: ' || v_Modulo || '  Error: ' || SQLERRM);
END RefrescarSKU;

/**************************************************************************************************
* Carga datos de todas las sucursales el stock del almacen 01
* %v 17/12/2020 - ChM
***************************************************************************************************/

PROCEDURE CargarStock IS

   v_Modulo           varchar2(100) := 'PKG_CLD_DATOS.CargarStock';
   v_qtstock          articulosalmacen.qtstock%type;
  CURSOR c_stock IS
            with stock as(
          select aa.cdalmacen,
                 aa.cdarticulo,
                 aa.cdsucursal,
                 sum(aa.qtstock) qtstock
            from articulosalmacen aa,
                -- vtexsellers vse,
                 vtexsku vs  --verifica si existe el sku
           where aa.cdarticulo = vs.refid
              -- solo veo stock de sucursales activas en vtex
             and aa.cdsucursal in (select vse.cdsucursal from vtexsellers vse where vse.icactivo = 1)
             and aa.cdalmacen = substr(aa.cdsucursal, 3, 2) || '01    '             
           group by aa.cdalmacen,aa.cdsucursal, aa.cdarticulo),
      --valida stock a 0 si no cumple con el umbral establecido por compras
      ventas as (
             select ar.cdarticulo,
                    st.cantbtos
               from articulos                    ar,
                    tblstockventas               st,
                    tblctgryarticulocategorizado a,
                    tblctgrydepartamento         d,
                    tblctgryuniverso             u,
                    tblctgrycategoria            c,
                    tblctgrysubcategoria         sc,
                    tblctgrysegmento             s,
                    tblctgrysubsegmento          ss,
                    tblctgrysectorc              tse
              where  ar.cdestadoplu in('00','07')  --00 activo para la venta 07 no visible
                and not exists
              (select 1
                       from articulosnocomerciales t
                      where t.cdarticulo = a.cdarticulo)
                and not exists
              (select 1
                       from articulos_excluidos h
                      where h.cdarticulo = ar.cdarticulo) --agrego tabla articulos excluidos
                /*and not exists
                (select 1
                   from aux_art_sinstock b
                  where b.cdarticulo = a.cdarticulo)    */
                and substr(ar.cdarticulo, 1, 1) <> 'a'
                and a.cddepartamento = d.cddepartamento(+)
                and a.cduniverso = u.cduniverso(+)
                and a.cdcategoria = c.cdcategoria(+)
                and a.cdsubcategoria = sc.cdsubcategoria(+)
                and a.cdsegmento = s.cdsegmento(+)
                and a.cdsubsegmento = ss.cdsubsegmento(+)
                and a.cdsectorc = tse.cdserctorc
                and a.cdarticulo = ar.cdarticulo
                and nvl(ar.cddrugstore,'XX') not in ('ex', 'de', 'cp')
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
                when (s.qtstock / DECODE(n_pkg_vitalpos_materiales.getuxb(s.cdarticulo),0,1,n_pkg_vitalpos_materiales.getuxb(s.cdarticulo))) >= nvl (v.cantbtos, '0')
                then
                   s.qtstock
                else
                   0
             end
                as qtstock
          from stock s
          left join ventas v on (s.cdarticulo=v.cdarticulo);

    TYPE lv_stock is table of c_stock%rowtype;
         r_stock     lv_stock;


BEGIN

   OPEN c_stock;
     FETCH c_stock  BULK COLLECT INTO r_stock; --cargo el cursor en la tabla en memoria
     CLOSE c_stock;
     FOR i IN 1 .. r_stock.COUNT LOOP
       BEGIN
         select vs.qtstock
           into v_qtstock
           from vtexstock vs
          where vs.cdalmacen = r_stock(i).cdalmacen
            and vs.cdsucursal = r_stock(i).cdsucursal
            and vs.cdarticulo = r_stock(i).cdarticulo;
           --si lo encuentra actualiza
           update vtexstock vs
              set vs.qtstock  = r_stock(i).qtstock,
                  vs.dtupdate = sysdate,
                  vs.icprocesado = 0
            where vs.cdalmacen = r_stock(i).cdalmacen
              and vs.cdsucursal = r_stock(i).cdsucursal
              and vs.cdarticulo = r_stock(i).cdarticulo;
      	EXCEPTION
          --si no lo encuentra inserta
          WHEN NO_DATA_FOUND THEN
           insert into vtexstock vs
                  (vs.cdalmacen,
                   vs.cdsucursal,
                   vs.cdarticulo,
                   vs.qtstock,
                   vs.icprocesado,
                   vs.dtprocesado,
                   vs.observacion,
                   vs.dtinsert,
                   vs.dtupdate)
          values (r_stock(i).cdalmacen,
                  r_stock(i).cdsucursal,
                  r_stock(i).cdarticulo,
                  r_stock(i).qtstock,
                  0,
                  null,
                  null,
                  sysdate,
                  null);
          WHEN others THEN
              n_pkg_vitalpos_log_general.write(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM
                                                  ||'articulo : '||r_stock(i).cdarticulo);
       END;
     END LOOP;


  commit;

EXCEPTION WHEN OTHERS THEN
  n_pkg_vitalpos_log_general.write(1, 'Modulo: ' || v_Modulo || '  Error: ' || SQLERRM);
  rollback;
END CargarStock;


  /***************************************************************************************************
   * %v 04/12/2020 - ChM - Actualiz� precios VTEX en GWV de la tabla VTEXPRICE
   ***************************************************************************************************/
  PROCEDURE RefrescarPreciosVTEX (p_Fecha IN tblprecio.dtvigenciadesde%type) IS

      v_modulo       VARCHAR2(100) := 'PKG_CLD_DATOS.RefrescarPreciosVTEX';
      v_priceOF      tblprecio.amprecio%type:=null;
      v_pricepl      tblprecio.amprecio%type:=null;
      v_dtfromof     tblprecio.dtvigenciadesde%type:=null;
      v_dttoof       tblprecio.dtvigenciahasta%type:=null;

       --lista los articulos(SKU) en VTEX con precio de oferta o lista, agregados en la fecha del parametro
      CURSOR c_precio (pc_Fecha tblprecio.dtvigenciadesde%type,pc_tipo tblprecio.id_precio_tipo%type) IS
      select p.cdarticulo,
             p.cdsucursal,
             p.id_canal,
             p.dtvigenciadesde,
             p.dtvigenciahasta,
             p.amprecio,
             GETPrecioconIVA (p.cdarticulo,p.cdsucursal,p.amprecio) precioconiva
        from tblprecio p,
             vtexsku   vs
       where p.cdarticulo = vs.refid
         and p.id_precio_tipo = pc_tipo
         --solo canales activos de VTEX
         and p.id_canal in (select distinct vs.id_canal
                      from vtexsellers vs
                     where vs.cdsucursal<>'9999'
                       and vs.icactivo = 1)
          -- solo sucursales activas en VTEX
          and p.cdsucursal in ( select distinct vs.cdsucursal
                         from vtexsellers vs
                        where vs.cdsucursal<>'9999' 
                          and vs.icactivo = 1)
         and p.dtvigenciadesde=pc_fecha;

        TYPE lv_precios is table of c_precio%rowtype;
        r_precio       lv_precios;
        of_precio      lv_precios;

  BEGIN

  --inserta los articulos en VTEX que no tienen precio en VTEXPRICE pero existen en tblprecio
  for P in
     (select distinct
             p.cdsucursal,
             p.cdarticulo,
             p.id_canal
        from tblprecio p
       where p.id_precio_tipo = 'PL' --solo precios lista
         --solo canales de VTEX
         and p.id_canal in (select distinct vs.id_canal
                              from vtexsellers vs
                             where vs.cdsucursal<>'9999'
                               and vs.icactivo = 1)
         -- solo sucursales en VTEX
         and p.cdsucursal in ( select distinct vs.cdsucursal
                                 from vtexsellers vs
                                where vs.cdsucursal<>'9999'
                                  and vs.icactivo = 1)
          --vigentes para la fecha
         and p_fecha between p.dtvigenciadesde and p.dtvigenciahasta
         --lista los articulos en VTEX que no tienen precio en VTEXPRICE
         and p.cdarticulo in (  select
                              distinct vs.refid
                                  from vtexsku   vs
                                 where vs.refid not in (select vp.refid from vtexprice vp)))

    loop
        --busca el precio de la ultima oferta actualizada para el articulo en la sucursal
        begin
        select A.amprecio,
               A.dtvigenciadesde,
               A.dtvigenciahasta
          into v_priceOF,v_dtfromof,v_dttoof
          from (select pre.amprecio,
                       pre.dtvigenciadesde,
                       pre.dtvigenciahasta,
                       pre.dtmodificacion
                  from tblprecio pre
                 where pre.cdsucursal = p.cdsucursal
                   and pre.id_canal = p.id_canal
                   and pre.cdarticulo = p.cdarticulo
                   and pre.id_precio_tipo = 'OF'
                   --vigentes para la fecha
                   and p_fecha between pre.dtvigenciadesde and pre.dtvigenciahasta
              order by pre.dtmodificacion desc
                ) A
       --recupero solo la oferta ultima actulizada
       where  rownum = 1;
       v_priceOF:=GETPrecioconIVA(p.cdarticulo,p.cdsucursal,v_priceOF);
      exception
        when others then
         v_priceOF:=null;
         v_dtfromof:=null;
         v_dttoof:=null;
      end;
      --recupero el precio PL unico del cursor ultimo actualizado
      begin
        select A.amprecio
          into v_pricepl
          from (select pre.amprecio,
                       pre.dtmodificacion
                  from tblprecio pre
                 where pre.cdsucursal = p.cdsucursal
                   and pre.id_canal = p.id_canal
                   and pre.cdarticulo = p.cdarticulo
                   and pre.id_precio_tipo = 'PL'
                   --vigentes para la fecha
                   and p_fecha between pre.dtvigenciadesde and pre.dtvigenciahasta
              order by pre.dtmodificacion desc
                ) A
       --recupero solo precio PL ultimo actulizado
       where  rownum = 1;
        v_pricepl:=GETPrecioconIVA (p.cdarticulo,p.cdsucursal,v_pricepl);
      exception
        when others then
          v_pricepl:=null;
      end;
      insert into vtexprice vp
                 (vp.cdsucursal,
                  vp.skuid,
                  vp.refid,
                  vp.id_canal,
                  vp.pricepl,
                  vp.priceof,
                  vp.dtfromof,
                  vp.dttoof,
                  vp.dtinsert,
                  vp.dtupdate,
                  vp.icprocesado,
                  vp.dtprocesado)
           values (p.cdsucursal,
                   to_number(p.cdarticulo),
                   p.cdarticulo,
                   p.id_canal,
                   v_pricepl,
                   v_priceOF,
                   v_dtfromof,
                   v_dttoof,
                   sysdate,
                   null,
                   0,
                   null);
      end loop;

    -- Carga o actualiza los precios lista de los articulos de vtex que se agregaron en la fecha del parametro

      OPEN c_precio(p_Fecha,'PL');
     FETCH c_precio  BULK COLLECT INTO r_precio;      --cargo el cursor en la tabla en memoria
     CLOSE c_precio;
     FOR i IN 1 .. r_precio.COUNT LOOP
       BEGIN
          select vp.pricepl
            into v_pricepl
            from vtexprice vp
           where vp.refid = r_precio(i).cdarticulo
             and vp.cdsucursal = r_precio(i).cdsucursal
             and vp.id_canal = r_precio(i).id_canal;
           --si lo encuentra actualiza
           update vtexprice vp
              set vp.pricepl = r_precio(i).precioconiva,
                  vp.dtupdate = sysdate,
                  vp.icprocesado = 0
            where vp.refid = r_precio(i).cdarticulo
              and vp.cdsucursal = r_precio(i).cdsucursal
              and vp.id_canal = r_precio(i).id_canal;
      	EXCEPTION
          --si no lo encuentra inserta
          WHEN NO_DATA_FOUND THEN
           insert into vtexprice vp
                 (vp.cdsucursal,
                  vp.skuid,
                  vp.refid,
                  vp.id_canal,
                  vp.pricepl,
                  vp.priceof,
                  vp.dtfromof,
                  vp.dttoof,
                  vp.dtinsert,
                  vp.dtupdate,
                  vp.icprocesado,
                  vp.dtprocesado)
          values (r_precio(i).cdsucursal,
                  to_number(r_precio(i).cdarticulo),
                  r_precio(i).cdarticulo,
                  r_precio(i).id_canal,
                  r_precio(i).precioconiva,
                  null,
                  null,
                  null,
                  SYSDATE,
                  null,
                  0,
                  null);
          WHEN others THEN
              n_pkg_vitalpos_log_general.write(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM
                                                  ||'articulo PL: '||r_precio(i).cdarticulo);
       END;
     END LOOP;

     -- Carga o actualiza los precios oferta de los articulos de vtex que se agregaron en la fecha del parametro
      OPEN c_precio(p_Fecha,'OF');
     FETCH c_precio  BULK COLLECT INTO of_precio;      --cargo el cursor en la tabla en memoria
     CLOSE c_precio;
     FOR i IN 1 .. of_precio.COUNT LOOP
       BEGIN
          select vp.pricepl
            into v_pricepl
            from vtexprice vp
           where vp.refid = of_precio(i).cdarticulo
             and vp.cdsucursal = of_precio(i).cdsucursal
             and vp.id_canal = of_precio(i).id_canal;
           --si lo encuentra actualiza
           update vtexprice vp
              set vp.priceof = of_precio(i).precioconiva,
                  vp.dtfromof = of_precio(i).dtvigenciadesde,
                  vp.dttoof = of_precio(i).dtvigenciahasta,
                  vp.dtupdate = sysdate,
                  vp.icprocesado = 0
            where vp.refid = of_precio(i).cdarticulo
              and vp.cdsucursal =of_precio(i).cdsucursal
              and vp.id_canal =of_precio(i).id_canal;
      	EXCEPTION
          --si no lo encuentra inserta
          WHEN NO_DATA_FOUND THEN
           insert into vtexprice vp
                 (vp.cdsucursal,
                  vp.skuid,
                  vp.refid,
                  vp.id_canal,
                  vp.pricepl,
                  vp.priceof,
                  vp.dtfromof,
                  vp.dttoof,
                  vp.dtinsert,
                  vp.dtupdate,
                  vp.icprocesado,
                  vp.dtprocesado)
          values (of_precio(i).cdsucursal,
                  to_number(of_precio(i).cdarticulo),
                  of_precio(i).cdarticulo,
                  of_precio(i).id_canal,
                  of_precio(i).precioconiva, --sino existe en VTEXPRICE se carga PL=OF
                  of_precio(i).precioconiva,
                  of_precio(i).dtvigenciadesde,
                  of_precio(i).dtvigenciahasta,
                  SYSDATE,
                  null,
                  0,
                  null);
          WHEN others THEN
              n_pkg_vitalpos_log_general.write(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM
                                                  ||'articulo en oferta: '||of_precio(i).cdarticulo);
       END;
     END LOOP;

  commit;
  EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM);
      rollback;
     /* pkg_control.GrabarMensaje(sys_guid(),
                                null,
                                sysdate,
                                'Error: '||v_modulo,
                                ' Error ORA: ' || sqlerrm,
                                0);
*/
  End  RefrescarPreciosVTEX;

 /*******************************************************************************************************
* Carga de todas las sucursales la informaci�n de TAPA, ofertas y promociones en las colecciones de VTEX
* %v 16/12/2020 - ChM
*********************************************************************************************************/

PROCEDURE CargarCollection (p_Fecha IN Tblarticulo_Tapa.Vigenciadesde%type) IS
  v_Modulo varchar2(100) := 'PKG_CLD_DATOS.CargarCollection';

BEGIN
  --OOOJJOOO FALTA guardar un historico de colecciones actualizadas en VTEX
  --limpio todas los sku de las distintas colecciones vigentes que se actualizar�n
  delete VTEXCollectionSKU vcs
   where vcs.collectionid in  (select collectionid
                                 from vtexcollection
                                 -- Solo coleciones vigentes
                                where p_fecha between dtfrom and dtto);

  --recupero todas las colecciones por sucursal, tipo y canal
  for colle in
      (select collectionid,
              id_tipo,
              cdsucursal,
              id_canal
         from vtexcollection
         -- Solo coleciones vigentes
        where p_fecha between dtfrom and dtto)
   loop
        --inserto los SKUs de las tapas por sucursal y canal
        if colle.id_tipo = 'TA' then
           insert into VTEXCOLLECTIONSKU
                      (collectionid,skuid, refid)
                      select colle.collectionid,
                             vsk.skuid,
                             art.cdarticulo
                        from tblarticulo_tapa art,
                             vtexsku          vsk
                       where art.cdarticulo = vsk.refid
                         --solo articulos vigentes de la TAPA
                         and p_fecha between art.vigenciadesde and art.vigenciahasta
                         and art.cdsucursal = colle.cdsucursal
                         and art.cdcanal = colle.id_canal;
         end if;
         --inserto los SKUs de las coleciones de oferta y promociones por sucursal y canal
        if colle.id_tipo = 'OF' then
          --insert de las ofertas
           insert into VTEXCOLLECTIONSKU
                      (collectionid,skuid, refid)
                      select colle.collectionid,
                             vsk.skuid,
                             pre.cdarticulo
                        from tblprecio        pre,
                             vtexsku          vsk
                       where pre.cdarticulo = vsk.refid
                         --solo articulos vigentes de la tblprecio
                         and p_fecha between pre.dtvigenciadesde and pre.dtvigenciahasta
                         --solo ofertas
                         and pre.id_precio_tipo='OF'
                         and pre.cdsucursal = colle.cdsucursal
                         and pre.id_canal = colle.id_canal
                         -- excluyo articulos de la tapa
                         and pre.cdarticulo not in (select art.cdarticulo
                                                      from tblarticulo_tapa art
                                                     where p_fecha between art.vigenciadesde and art.vigenciahasta
                                                       and art.cdsucursal = colle.cdsucursal
                                                       and art.cdcanal = colle.id_canal);
         --OOOJJJOOOOO pendiente agregar aqui el insert de los articulos en PROMOCION
         end if;
   end loop
  commit;

EXCEPTION WHEN OTHERS THEN
  n_pkg_vitalpos_log_general.write(1, 'Modulo: ' || v_Modulo || '  Error: ' || SQLERRM);
  rollback;
END CargarCollection;

/*************************************************************************************************************
* Actualiz� los datos de todas las promociones vigentes en AC en la tabla VTEXPROMOTION
* %v 29/12/2020 - ChM
*************************************************************************************************************/
PROCEDURE RefrescarPromos (p_Fecha IN tblprecio.dtvigenciadesde%type) IS
  v_Modulo varchar2(100) := 'PKG_CLD_DATOS.RefrescarPromos';

 CURSOR c_promo IS
         SELECT distinct 
                R.ID_PROMO,
                R.CDPROMO,                              
                R.NOMBRE,
                SUC.CDSUCURSAL,
                r.id_promo_estado,
                R.ID_PROMO_TIPO TIPO,
                r.multiproducto,
                CP.VALOR ValorCond,
                VP1.NOMBRE UnidadCond,
                AP.VALOR ValorAcc,
                R.vigencia_desde,
                R.vigencia_hasta,
                canal.id_canal,
                r.fecha_ultima_modificacion,
                PKG_CLD_DATOS.LeyendasPromoCucarda(r.id_promo) cucarda,
                PKG_CLD_DATOS.FNLeyendaPromoCorta(r.id_promo) leyenda,
                case 
                  when VP1.NOMBRE = 'Bulto' then
                       pkg_CLD_DATOS.revisarmultipleUxB (R.ID_PROMO) 
                  else 
                       1
                   end UxB
           FROM TBLPROMO                     R,
                TBLPROMO_CONDICION           C,
                TBLPROMO_CONDICION_PARAMETRO CP,
                TBLPROMO_CONDICION_PARAMETRO CP2,
                TBLPROMO_CONDICION_PARAMETRO CP3,
                TBLPROMO_TIPO_CONDICION      TC,
                TBLPROMO_TIPO_ACCION         TA,
                TBLPROMO_ACCION              A,
                TBLPROMO_ACCION_PARAMETRO    AP,
                TBLPROMO_ACCION_PARAMETRO    AP2,
                TBLPROMO_SUCURSAL            SUC,
                TBLPROMO_CANAL               CANAL,
                TBLPROMO_VALOR_PERMITIDO     VP1,
                TBLPROMO_VALOR_PERMITIDO     VP2
          WHERE 1 = 1
            AND C.ID_PROMO = R.ID_PROMO
            AND TC.ID_PROMO_TIPO_CONDICION = C.ID_PROMO_TIPO_CONDICION
            AND SUC.ID_PROMO = C.ID_PROMO
            AND CANAL.ID_PROMO = C.ID_PROMO
            AND CP.ID_PROMO_CONDICION = C.ID_PROMO_CONDICION
            AND CP.ID_PROMO_PARAMETRO = 6 --Parametro Cantidad
            AND CP2.ID_PROMO_CONDICION = C.ID_PROMO_CONDICION
            AND CP2.ID_PROMO_PARAMETRO = 10 --Parametro Fidelizacion
            AND CP3.ID_PROMO_CONDICION = C.ID_PROMO_CONDICION
            AND CP3.ID_PROMO_PARAMETRO = 7 --Parametro Tipo Unidad
            AND VP1.ID_PROMO_VALOR_PERMITIDO = CP3.VALOR
            AND A.ID_PROMO = R.ID_PROMO
            AND TA.ID_PROMO_TIPO_ACCION = A.ID_PROMO_TIPO_ACCION
            AND AP.ID_PROMO_ACCION = A.ID_PROMO_ACCION
            AND AP.ID_PROMO_PARAMETRO IN (6, 8) --Acci�n 6=Cantidad , 8=Porcentaje Descuento (Si cambia esto hay que controlar la interfaz de stock)
            AND AP2.ID_PROMO_ACCION(+) = A.ID_PROMO_ACCION
            AND AP2.ID_PROMO_PARAMETRO(+) = 7 --Parametro Tipo Unidad
            AND VP2.ID_PROMO_VALOR_PERMITIDO(+) = AP2.VALOR
            AND p_fecha between r.VIGENCIA_DESDE AND r.VIGENCIA_HASTA
            AND SUC.CDSUCURSAL in (select distinct vs.cdsucursal from vtexsellers vs where vs.icactivo = 1) --Sucursales activas en VTEX
            AND trim(CANAL.ID_CANAL) in (select distinct vs.id_canal from vtexsellers vs where vs.icactivo = 1) --Canales activos en VTEX
            AND R.ID_PROMO_TIPO in (1,7);
        
        TYPE lv_promo is table of c_promo%rowtype;
        r_promo        lv_promo;
        promo          vtexpromotion%rowtype;
        
BEGIN
     --eliminar las promociones no vigentes para la fecha del parametro
     delete vtexpromotionsku ps where ps.id_promo_pos in (select vp.id_promo_pos from vtexpromotion vp where vp.enddateutc<p_fecha);
     delete vtexpromotion vp where vp.enddateutc<p_fecha;
   
     OPEN c_promo;
     FETCH c_promo  BULK COLLECT INTO r_promo;      --cargo el cursor en la tabla en memoria
     CLOSE c_promo;
      FOR i IN 1 .. r_promo.COUNT LOOP
       BEGIN
          select *
            into promo
            from vtexpromotion vp
           where vp.id_promo_pos = r_promo(i).id_promo
             and vp.cdsucursal = r_promo(i).cdsucursal
             and vp.id_canal = r_promo(i).id_canal;
           --si lo encuentra verifica si algo cambio de las condiciones de la promo y actualiza
           if(promo.name <> r_promo(i).nombre or promo.type <> r_promo(i).tipo or 
              promo.begindateutc <> r_promo(i).vigencia_desde or promo.enddateutc <> r_promo(i).vigencia_hasta or
              promo.isactive <> r_promo(i).id_promo_estado or promo.multiproducto <> r_promo(i).multiproducto or
              promo.valorcond <> r_promo(i).valorcond or promo.unidadcond <> r_promo(i).unidadcond or
              promo.valoracc <> r_promo(i).valoracc or promo.dtmodificacion_pos <> r_promo(i).fecha_ultima_modificacion or
              promo.dscucarda <> r_promo(i).cucarda or promo.dsleyendacorta <> r_promo(i).leyenda or promo.uxb <> r_promo(i).uxb) then
              
                update vtexpromotion vp
                   set vp.name = r_promo(i).nombre,
                       vp.type =  r_promo(i).tipo,
                       vp.begindateutc = r_promo(i).vigencia_desde,
                       vp.enddateutc = r_promo(i).vigencia_hasta,
                       vp.isactive = r_promo(i).id_promo_estado,
                       vp.multiproducto = r_promo(i).multiproducto,
                       vp.valorcond = r_promo(i).valorcond,
                       vp.unidadcond = r_promo(i).unidadcond,
                       vp.valoracc = r_promo(i).valoracc,
                       vp.dtmodificacion_pos = r_promo(i).fecha_ultima_modificacion,
                       vp.icprocesado = 0,
                       vp.dtprocesado = null,
                       vp.dtupdate = sysdate,
                       vp.observacion = null,
                       vp.dscucarda = r_promo(i).cucarda,
                       vp.dsleyendacorta = r_promo(i).leyenda,
                       vp.uxb = r_promo(i).uxb
                 where vp.id_promo_pos = r_promo(i).id_promo
                   and vp.cdsucursal = r_promo(i).cdsucursal
                   and vp.id_canal = r_promo(i).id_canal;
                   --borrar e insertar los SKU de la Promoci�n
                    if(promoSKU (r_promo(i).id_promo)=1)then
                n_pkg_vitalpos_log_general.write(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM
                                                  ||' error al cargar articulos a la Promoci�n error: '||r_promo(i).id_promo);                                                 
              end if;
           end if;        
      	EXCEPTION
          --si no lo encuentra inserta
          WHEN NO_DATA_FOUND THEN
           insert into vtexpromotion vp
                 ( vp.id_promo_pos,
                   vp.id_promo_vtex,
                   vp.name,
                   vp.id_canal,
                   vp.cdsucursal,
                   vp.type,
                   vp.begindateutc,
                   vp.enddateutc,
                   vp.isactive,
                   vp.multiproducto,
                   vp.valorcond,
                   vp.unidadcond,
                   vp.valoracc,
                   vp.dtmodificacion_pos,
                   vp.icprocesado,                   
                   vp.observacion,
                   vp.dtinsert,
                   vp.dtupdate,
                   vp.dscucarda,
                   vp.dsleyendacorta,
                   vp.uxb,
                   vp.cdpromo)
          values ( r_promo(i).id_promo,
                   null,
                   r_promo(i).nombre,
                   r_promo(i).id_canal,
                   r_promo(i).cdsucursal,
                   r_promo(i).tipo,
                   r_promo(i).vigencia_desde,
                   r_promo(i).vigencia_hasta,
                   r_promo(i).id_promo_estado,
                   r_promo(i).multiproducto,
                   r_promo(i).valorcond,
                   r_promo(i).unidadcond,
                   r_promo(i).valoracc,
                   r_promo(i).fecha_ultima_modificacion,
                   0,
                   null,                   
                   sysdate,
                   null,
                   r_promo(i).cucarda,
                   r_promo(i).leyenda,
                   r_promo(i).uxb,
                   r_promo(i).cdpromo);
               --borrar e insertar los SKU de la Promoci�n     
              if(promoSKU (r_promo(i).id_promo)=1)then
                n_pkg_vitalpos_log_general.write(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM
                                                  ||' error al cargar articulos a la Promoci�n error: '||r_promo(i).id_promo);
                rollback;                                  
                return;                                  
              end if;
          WHEN others THEN
              n_pkg_vitalpos_log_general.write(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM
                                                  ||'Promoci�n error: '||r_promo(i).id_promo);
             rollback;                                  
                return;                                          
       END;  
     END LOOP;
     commit;
EXCEPTION
  WHEN OTHERS THEN
    n_pkg_vitalpos_log_general.write(1,
                          'Modulo: ' || v_Modulo || '  Error: ' || SQLERRM);
    rollback;                                  
    return;                               
END  RefrescarPromos;
/**************************************************************************************************
* revisa si la promoci�n multiproducto tiene varios UXB por ahora no se pasan esas promos a VTEX
* %v 18/01/2021 - ChM
***************************************************************************************************/
FUNCTION revisarmultipleUxB (p_id_promo TBLPROMO.ID_PROMO%type) RETURN integer 
  IS
  v_cantidad integer:=0;
BEGIN
            select count(*) 
            into v_cantidad
              from
              (
            select distinct                    
                   n_pkg_vitalpos_materiales.GetUxB(aa.cdarticulo) UXB
              from tblpromo                 p, 
                   tblpromo_accion          a, 
                   tblpromo_accion_articulo aa, 
                   tblpromo_canal           c, 
                   tblpromo_sucursal        s
              where p.id_promo = s.id_promo
              and p.id_promo = c.id_promo
              and p.id_promo = a.id_promo
              and a.id_promo_accion = aa.id_promo_accion             
              and p.id_promo = p_id_Promo);
             -- verifico en las multiproducto de bultos si tiene diferentes UxB retorna -1
             if v_cantidad > 1 then
                return -1;
             else
              --retorna el UXB unico 
            select distinct                    
                   n_pkg_vitalpos_materiales.GetUxB(aa.cdarticulo) UXB
                   into v_cantidad
              from tblpromo                 p, 
                   tblpromo_accion          a, 
                   tblpromo_accion_articulo aa, 
                   tblpromo_canal           c, 
                   tblpromo_sucursal        s
              where p.id_promo = s.id_promo
              and p.id_promo = c.id_promo
              and p.id_promo = a.id_promo
              and a.id_promo_accion = aa.id_promo_accion             
              and p.id_promo = p_id_Promo;
              return v_cantidad;
               end if;
               
EXCEPTION
  when others then
    return -1;
END revisarmultipleUxB;
/**************************************************************************************************
* borrar y cargar todos los SKU de una IDPROMO que recibe como parametro
* %v 29/12/2020 - ChM
***************************************************************************************************/
FUNCTION promoSKU (p_id_promo TBLPROMO.ID_PROMO%type) RETURN integer 
  IS
  
BEGIN
   delete vtexpromotionSKU vps where vps.id_promo_pos = p_id_promo;
    insert into vtexpromotionSKU vps         
            select distinct 
                   p_id_promo,
                   vs.skuid,
                   aa.cdarticulo 
              from tblpromo                 p, 
                   tblpromo_accion          a, 
                   tblpromo_accion_articulo aa, 
                   tblpromo_canal           c, 
                   tblpromo_sucursal        s,
                   vtexSKU                  vs
              where p.id_promo = s.id_promo
              and p.id_promo = c.id_promo
              and p.id_promo = a.id_promo
              and a.id_promo_accion = aa.id_promo_accion
              and vs.refid = aa.cdarticulo
              and vs.isactive = 1 --solo skus activos
              and p.id_promo = p_id_Promo;
              
   commit;
   return 0;
EXCEPTION
  when others then
    rollback;
    return 1;
END promoSKU;
/**************************************************************************************************
  * Arma las leyendas cortas para las promos
  * 12/06/2017 - IAquilano
***************************************************************************************************/
FUNCTION FnLeyendaPromoCorta(p_id_promo IN tblpromo.id_promo%type)
  return varchar2 IS

  v_modulo        varchar2(100) := 'PKG_CLD_DATOS.FnLeyendaPromoCorta';
  v_ciclico       tblpromo.ciclico%type;
  v_cant_cond     integer;
  v_uni_cond      varchar2(10);
  v_lleva         varchar2(3);
  v_paga          varchar2(3);
  v_porcentaje    varchar2(2);
  v_tipo          tblpromo.id_promo_tipo%type;
  v_cliente       tblpromo_condicion_parametro.valor%type;
  v_leyenda       varchar2(200) := '';
  v_vigenciadesde date;
  v_vigenciahasta date;

BEGIN
  begin
    select p.id_promo_tipo, p.ciclico
      into v_tipo, v_ciclico
      from tblpromo p
     where p.id_promo = p_id_promo;
  exception
    when others then
      return v_leyenda;
  end;

  if v_tipo = 1 then

    select distinct trim(cp.valor),
                    trim(upper(vp1.nombre)),
                    trim(ap.valor),
                    trim(cp2.valor),
                    p.vigencia_desde,
                    p.vigencia_hasta
      into v_lleva,
           v_uni_cond,
           v_paga,
           v_cliente,
           v_vigenciadesde,
           v_vigenciahasta
      from tblpromo                     p,
           tblpromo_condicion           c,
           tblpromo_condicion_parametro cp,
           tblpromo_condicion_parametro cp2,
           tblpromo_condicion_parametro cp3,
           tblpromo_accion              a,
           tblpromo_accion_parametro    ap,
           tblpromo_valor_permitido     vp1
     where p.id_promo = p_id_promo
       and c.id_promo = p.id_promo
       and c.id_promo_condicion = cp.id_promo_condicion
       and cp.id_promo_parametro = 6 --parametro cantidad
       and c.id_promo_condicion = cp3.id_promo_condicion
       and cp3.id_promo_parametro = 7 --parametro tipo unidad
       and cp3.valor = vp1.id_promo_valor_permitido
       and cp.id_promo_condicion = cp2.id_promo_condicion
       and cp2.id_promo_parametro = 10 -- parametro fidelizacion
       and p.id_promo = a.id_promo
       and a.id_promo_accion = ap.id_promo_accion
       and ap.id_promo_parametro = 6 --acci�n 6=cantidad
       and rownum = 1;

    if v_lleva > 1 then
      case v_uni_cond
        when 'UNIDAD' then
          v_uni_cond := ' UNIDADES';
        when 'BULTO' then
          v_uni_cond := ' BULTOS';
        when 'PIEZA' then
          v_uni_cond := ' PIEZAS';
      end case;
    end if;

    if (v_cliente <> '8') then
      -- no es para fidelizados
      /*If v_lleva > 1 then
        v_leyenda := 'Lleva ' || trim(v_lleva) || ' ' || v_uni_cond ||
                     'ES ' || 'y paga ' || trim(v_paga);
      else*/
        v_leyenda := 'Lleva ' || trim(v_lleva) || ' ' || trim(v_uni_cond) || ' ' ||
                     'y paga ' || trim(v_paga);
   /*   End If;*/
    end if;
  end if;

  if v_tipo = 7 then
    select distinct trim(cp.valor),
                    trim(upper(vp1.nombre)),
                    trim(ap.valor),
                    trim(cp2.valor),
                    p.vigencia_desde,
                    p.vigencia_hasta
      into v_cant_cond,
           v_uni_cond,
           v_porcentaje,
           v_cliente,
           v_vigenciadesde,
           v_vigenciahasta
      from tblpromo                     p,
           tblpromo_condicion           c,
           tblpromo_condicion_parametro cp,
           tblpromo_condicion_parametro cp2,
           tblpromo_condicion_parametro cp3,
           tblpromo_accion              a,
           tblpromo_accion_parametro    ap,
           tblpromo_valor_permitido     vp1
     where p.id_promo = p_id_promo
       and c.id_promo = p.id_promo
       and c.id_promo_condicion = cp.id_promo_condicion
       and cp.id_promo_parametro = 6 --parametro cantidad
       and cp3.id_promo_condicion = c.id_promo_condicion
       and cp3.id_promo_parametro = 7 --parametro tipo unidad
       and vp1.id_promo_valor_permitido = cp3.valor
       and cp.id_promo_condicion = cp2.id_promo_condicion
       and cp2.id_promo_parametro = 10 -- parametro fidelizacion
       and a.id_promo = p.id_promo
       and ap.id_promo_accion = a.id_promo_accion
       and ap.id_promo_parametro in (8)
       and rownum = 1; -- 8=porcentaje descuento

    if v_cant_cond > 1 then
      case v_uni_cond
        when 'UNIDAD' then
          v_uni_cond := ' UNIDADES';
        when 'BULTO' then
          v_uni_cond := ' BULTOS';
        when 'PIEZA' then
          v_uni_cond := ' PIEZAS';
      end case;
    end if;

    if v_cant_cond = 1 and v_uni_cond = 'UNIDAD' then
      v_leyenda := null; -- se decide despu�s, va el factor
    else
      if v_ciclico = 0 then
        v_leyenda := 'desde ';
      else
        v_leyenda := 'cada ';
      end if;
      v_leyenda := v_leyenda || trim(v_cant_cond) || ' ' || v_uni_cond;
    end if;

    if v_ciclico = 0 then
      v_leyenda := 'desde ' || trim(v_cant_cond) || ' ' || v_uni_cond;
    else
      v_leyenda := 'cada ' || trim(v_cant_cond) || ' ' || v_uni_cond;
    end if;

  end if;

  return v_leyenda;

EXCEPTION
  WHEN OTHERS THEN 
    n_pkg_vitalpos_log_general.write(2,
                          'Modulo: ' || v_modulo || ' Promo: ' ||
                          p_id_promo || ' Error: ' || SQLERRM);
    return null;
END FnLeyendaPromoCorta;

/**************************************************************************************************
  * Arma las leyendas para la cucarda
  * %v 12/06/2017 - IAquilano
***************************************************************************************************/

FUNCTION LeyendasPromoCucarda(p_id_promo tblpromo.id_promo%type) RETURN varchar2 IS

  v_modulo     varchar2(100) := 'PKG_CLD_DATOS.LeyendasPromoCucarda';
  v_ciclico    tblpromo.ciclico%type;
  v_cant_cond  integer;
  v_uni_cond   varchar2(10);
  v_lleva      varchar2(3);
  v_paga       varchar2(3);
  v_porcentaje varchar2(2);
  v_tipo       tblpromo.id_promo_tipo%type;
  v_promoaccion varchar2(30):=null;

BEGIN
  select p.id_promo_tipo, p.ciclico
    into v_tipo, v_ciclico
    from tblpromo p
   where p.id_promo = p_id_promo;

  if v_tipo = 1 then

    select trim(cp.valor), trim(upper(vp1.nombre)), trim(ap.valor)
      into v_lleva, v_uni_cond, v_paga
      from tblpromo                     p,
           tblpromo_condicion           c,
           tblpromo_condicion_parametro cp,
           tblpromo_condicion_parametro cp3,
           tblpromo_accion              a,
           tblpromo_accion_parametro    ap,
           tblpromo_valor_permitido     vp1
     where p.id_promo = p_id_promo
       and c.id_promo = p.id_promo
       and c.id_promo_condicion = cp.id_promo_condicion
       and cp.id_promo_parametro = 6 --parametro cantidad
       and c.id_promo_condicion = cp3.id_promo_condicion
       and cp3.id_promo_parametro = 7 --parametro tipo unidad
       and cp3.valor = vp1.id_promo_valor_permitido
       and p.id_promo = a.id_promo
       and a.id_promo_accion = ap.id_promo_accion
       and ap.id_promo_parametro = 6 --acci�n 6=cantidad
    ;

    v_promoaccion := trim(v_lleva) || 'X' || trim(v_paga);
    if v_uni_cond = 'BULTO' then
      -- solo aclaro si es bultos (por ahora son las 4+1 que no se comunican)
      v_promoaccion := v_promoaccion || ' (BTO)';
    end if;
  end if;

  if v_tipo = 7 then
    select trim(cp.valor), trim(upper(vp1.nombre)), trim(ap.valor)
      into v_cant_cond, v_uni_cond, v_porcentaje
      from tblpromo                     p,
           tblpromo_condicion           c,
           tblpromo_condicion_parametro cp,
           tblpromo_condicion_parametro cp3,
           tblpromo_accion              a,
           tblpromo_accion_parametro    ap,
           tblpromo_valor_permitido     vp1
     where p.id_promo = p_id_promo
       and c.id_promo = p.id_promo
       and c.id_promo_condicion = cp.id_promo_condicion
       and cp.id_promo_parametro = 6 --parametro cantidad
       and cp3.id_promo_condicion = c.id_promo_condicion
       and cp3.id_promo_parametro = 7 --parametro tipo unidad
       and vp1.id_promo_valor_permitido = cp3.valor
       and a.id_promo = p.id_promo
       and ap.id_promo_accion = a.id_promo_accion
       and ap.id_promo_parametro in (8); -- 8=porcentaje descuento

    v_promoaccion := '-' || trim(v_porcentaje) || '% '; --porcentaje de descuento

  end if;
  return v_promoaccion;
EXCEPTION
  WHEN OTHERS THEN
   n_pkg_vitalpos_log_general.write(2,
                          'Modulo: ' || v_modulo || ' Promo: ' ||
                          p_id_promo||' Error: '|| SQLERRM);
   return null;                       

END LeyendasPromoCucarda;

/**************************************************************************************************
* Devuelve los pedidos que est�n pendientes por traer de VTEX para AC
* %v 15/01/2021 - ChM
***************************************************************************************************/
PROCEDURE GetPedidosVtex (Cur_Out Out Cursor_Type) IS
  
  v_modulo        varchar2(100) := 'PKG_CLD_DATOS.GetPedidosVtex';
  
BEGIN
  OPEN Cur_Out FOR
   select p.pedidoid_vtex
     from vtexpedidos p
    where p.icprocesado = 0 --solo pedidos por procesar
     --devulve de 1 en 1 los pedidos
      and rownum = 1;
   
EXCEPTION
  when others then
      n_pkg_vitalpos_log_general.write(2,
                            'Modulo: ' || v_Modulo || '  Error: ' ||
                            SQLERRM);
      return;
END GetPedidosVtex;

/**************************************************************************************************
* cambia el estado de la tabla vtexpedidos seg�n parametro de entrada del procedimiento
* 1 procesado OK 2 Procesado con error 
* %v 22/01/2021 - ChM
***************************************************************************************************/
FUNCTION SetVtexPedidos (p_pedidoid_vtex         vtexpedidos.pedidoid_vtex%type,
                         p_idpedido_pos          vtexpedidos.idpedido_pos%type, 
                         p_icprocesado           vtexpedidos.icprocesado%type,
                         p_observacion           vtexpedidos.observacion%type) return integer is
                        
  v_Modulo varchar2(100) := 'PKG_CLD_DATOS.SETVTEXPEDIDOS';

BEGIN
  update vtexpedidos vp
     set vp.icprocesado = p_icprocesado,
         vp.idpedido_pos = p_idpedido_pos,
         vp.dtprocesado = sysdate,
         vp.observacion = p_observacion
   where vp.pedidoid_vtex = p_pedidoid_vtex;    
  return 1;
  commit;
EXCEPTION
  WHEN OTHERS THEN
    n_pkg_vitalpos_log_general.write(1,
                          'Modulo: ' || v_Modulo || '  Error: ' || SQLERRM);
    rollback;                      
    return 0;                      
END SetVtexPedidos;

/**************************************************************************************************
* Inserta los pedidos de VTEX para AC
* %v 22/01/2021 - ChM
***************************************************************************************************/
PROCEDURE InsertarPedidoPOS (p_pedidoid_vtex       IN  vtexpedidos.pedidoid_vtex%type,
                             p_cabecera            IN  varchar2,
                             p_detalle             IN  arr_refId) IS
  
  v_modulo                   varchar2(100) := 'PKG_CLD_DATOS.InsertarPedidoPOS';
  v_iddoctrx                 documentos.iddoctrx%type;
  v_cdsucursal               vtexsellers.cdsucursal%type:=null;
  v_id_canal                 vtexsellers.id_canal%type:=null;
  v_identidad                entidades.identidad%type;
  v_identidadReal            entidades.identidad%type; 
  v_cdcuit                   entidades.cdcuit%type; 
  v_idvendedor               personas.idpersona%type; 
  v_idcomisionista           entidades.identidad%type;
  v_icorigen                 pedidos.icorigen%type:=4;--0-Normal 1-Especificos 2-viejos sin identificar  3-Salon 4-Ecommerce 
  v_idcuenta                 tblcuenta.idcuenta%type;
  v_cdsituacioniva           pedidos.cdsituacioniva%type;
  v_qtmateriales             integer:=0;
  v_ammonto                  number:=0;
  v_idpedido                 pedidos.idpedido%type;
  v_icretiraensucu           pedidos.icretirasucursal%type:=0;
  v_cdtipodireccion          tbldireccioncuenta.cdtipodireccion%type;
  v_sqdireccion              tbldireccioncuenta.sqdireccion%type;
  v_icestadosistema          pedidos.icestadosistema%type:=0; --listo para Validar en PKG_PEDIDO_CENTRAL
  v_dsreferencia             pedidos.dsreferencia%type:=null; --OOOOJJJJOOOOO dsreferencia de CF se va null porque PKG_PEDIDO_CENTRAL validar le asignar� DNI de CF
  v_dtentrega                pedidos.dtentrega%type:=sysdate+2;--2 dias despues de subido a POS
  --items
  v_cdarticulo               vtexproduct.refid%type;   
  v_price                    vtexprice.pricepl%type;
  v_quantity                 vtexstock.qtstock%type;
  v_idpromo_vtex             vtexpromotion.id_promo_vtex%type;
  v_qtpiezas                 detallepedidos.qtpiezas%type:=0; --en vtex por ahora no existen pesables
  v_vluxb                    detallepedidos.vluxb%type;
  v_vlcantidad               detallepedidos.qtunidadpedido%type;            
  v_cdunidadmedida           detallepedidos.cdunidadmedida%type;
  v_cdpromo                  tblpromo.cdpromo%type;
  v_dsarticulo               detallepedidos.dsarticulo%type;
  v_icresppromo              detallepedidos.icresppromo%type;
  v_ampreciounitario         detallepedidos.ampreciounitario%type;
  v_amlinea                  detallepedidos.amlinea%type;                             
  v_observacion              observacionespedido.dsobservacion%type;
  v_limitedividepedido       number:= n_pkg_vitalpos_core.GETVLPARAMETRO('MAX_PEDIDO_CF','General');

  
BEGIN
  /*o	Texto del 1 + 3 el affiliateId
    o	Texto el  4 + 1  el salesChannel
    o	Texto del 5 + 40  el idCuenta  (cliente)
    o	Texto del 45 + 60  el email (cliente)Texto del 
    o	Texto 105 + 1 marca de Consumidor Final. 1 CF 0 Cliente
    o	Texto del 106 + 30 value Monto total pedido.
    o	 Texto del 136 + 40 id vendedor o comi.
    o	Texto del 176 + 1 icretiraensucursal 0 no 1 si.
    o	Texto del 177 + 8  cdtipodireccion.
    o	Texto del 185 + 3 sqdireccion.
    o	Texto del 188 + 100 observaci�n.
  */
  --cabecera para vendedor PRUEBAS
-- p_cabecera:='VLH137C1BBB794844E8CE05000CB3C00415C        vendedor@unet.edu.vevendedor@unet.edu.vevendedor@unet.edu.ve02500                          232AA03211C6863FE05000C83C001F36        12       1   pruebavendedor';
 --cabecera para comi
--  p_cabecera:='CLH237C1BBB794844E8CE05000CB3C00415C        comisionista@unet.edu.vecomisionista@unet.edu.vecomisionista05500                          4B7C2D073AA4304EE053100000CEA5C6        12       1   pruebacomi'

  --recupero el cdsucursal y el ID_canal seg�n el affiliateId
   begin
      select vs.cdsucursal, vs.id_canal
        into v_cdsucursal,v_id_canal
        from vtexsellers vs
       where vs.afiliado = trim(substr(p_cabecera,1,3))
       --solo sucursales activas 
         and vs.icactivo = 1;
   exception 
     when others then
         if(SetVtexPedidos (p_pedidoid_vtex,null,2,'No existe la sucursal o no esta activa')=0) then         
           RETURN;  
         end if;  
   end;
   
   --recupero el id cuenta del cliente y la identidad real entidades
   begin
              select cu.idcuenta,cu.identidad
                into v_idcuenta,v_identidadReal
                from tblcuenta cu
               where cu.idcuenta = trim(substr(p_cabecera,5,40));
               --si es cliente registrado identidad igual a identidad real
               v_identidad:=v_identidadReal;
    exception 
         when others then
             if(SetVtexPedidos (p_pedidoid_vtex,null,2,'No se encuentra la cuenta del cliente: '||trim(substr(p_cabecera,5,40)))=0) then         
               RETURN;  
             end if;  
             RETURN;  
   end; 
   
   --recupero el CUIT del cliente
   begin
             select e.cdcuit
               into v_cdcuit
               from entidades e
              where e.identidad = v_identidadReal;
    exception 
         when others then
             if(SetVtexPedidos (p_pedidoid_vtex,null,2,'No se encuentra CUIT del cliente: '||v_identidadReal)=0) then         
               RETURN;  
             end if;  
             RETURN;  
   end; 
    --Averiguo la Situacion de IVA 1 si es CF o cliente registrado
    if trim(substr(p_cabecera,105,1)) = 1 then
      v_cdsituacioniva := '2';
      --si es CF identidad IdCfReparto
      v_identidad:='IdCfReparto';     
    else
      v_cdsituacioniva := '1';      
    end if;
 
  --Averiguo el monto total del pedido, 
  --divido por 100 por que vtex envia los dos decimales en los ultimos 2 digitos
    v_ammonto:= to_number(trim(substr(p_cabecera,106,30)))/100;      
       
    --recupera el ID Comi o ID vendedor
   begin
            if v_id_canal ='VE' then
              select per.idpersona
                into v_idvendedor
                from personas per 
               where per.idpersona = substr(p_cabecera,136,40);
             end if;  
            if v_id_canal ='CO' then
              select e.identidad
                into v_idcomisionista
                from entidades e
               where e.identidad = substr(p_cabecera,136,40);
             end if;   
    exception 
         when others then
             if(SetVtexPedidos (p_pedidoid_vtex,null,2,'No existe ID vendedor o comisionista: '||substr(p_cabecera,136,40)||' canal: '||v_id_canal)=0) then         
               RETURN;  
             end if;
             RETURN;   
   end;   
    --indica si el pedido se retira en sucursal  
    v_icretiraensucu := trim(substr(p_cabecera,176,1));     
    --indica cdtipodireccion
    v_cdtipodireccion := substr(p_cabecera,177,8); 
    --indica sqdireccion 
    v_sqdireccion:= to_number(trim(substr(p_cabecera,185,3)));  
    
    --observaciones del pedido
    v_observacion:= trim(substr(p_cabecera,188,100));
    
    --Averiguo la cantidad de articulos distintos que tiene el pedido  OOOOJJOOOOOO falta restar las lineas de promo
    v_qtmateriales:=p_detalle.Count;
    if v_qtmateriales = 0 then 
       if(SetVtexPedidos (p_pedidoid_vtex,null,2,'Pedido sin articulos: '||trim(substr(p_cabecera,5,45)))=0) then         
               RETURN;  
       end if;
       RETURN;   
    end if;
    
    --si es CF y ammomto superior al limite dividir pedido
    if v_cdsituacioniva = 2 and v_ammonto > v_limitedividepedido then
         v_icestadosistema:=-1; --pedido preparado para dividir        
    end if;
    
              
 --inserto datos en documentos con tipo de comprobante PEDI
  INSERT INTO documentos
      (iddoctrx           , idmovmateriales       , idmovtrx                         , cdsucursal     , identidad        , cdcomprobante ,
       cdestadocomprobante, idpersona             , sqcomprobante                    , sqsistema      , dtdocumento      , amdocumento   ,
       icorigen           , amnetodocumento       , qtreimpresiones                  , amrecargo      , cdtipocomprobante, dsreferencia  ,
       icspool            , iccajaunificada       , cdpuntoventa                     , idcuenta       , identidadreal    , idtransaccion )
  VALUES
      (sys_guid()         , NULL                  , NULL                             , v_cdsucursal   , v_identidad      , 'PEDI'        ,
       '1'                , NULL                  , OBTENERCONTADORNUMCOMPROB('PEDI'), CONTADORSISTEMA, SYSDATE          , v_ammonto     ,
       v_icorigen         , v_ammonto             , 0                                , 0              , NULL             , v_dsreferencia,
       NULL               , NULL                  , NULL                             , v_idcuenta     , v_identidadReal  , NULL          )
  RETURNING iddoctrx INTO v_iddoctrx;
  
  IF  SQL%ROWCOUNT = 0  THEN      --valida insert 
   	 if(SetVtexPedidos (p_pedidoid_vtex,null,2,'Error al insertar documento del pedido VTEX'||p_pedidoid_vtex)=0) then  
                     rollback;         
                     RETURN;                            
     end if; 
     rollback;  
     RETURN;       
    END IF;

  --Inserto el registro cabecera en la tabla pedidos (uso el mismo transid del de la transaccion de VTEX)
  insert into pedidos
  (idpedido          , identidad       , idpersonaresponsable  , dspersona  , iddoctrx        , qtmateriales  , dsreferencia     ,
   cdcondicionventa  , cdsituacioniva  , icestadosistema       , cdlugar    , dtaplicacion    , dtentrega     , cdtipodireccion  ,
   idvendedor        , sqdireccion     , ammonto               , icorigen   , idcomisionista  , id_canal      , transid          ,
   icretirasucursal  , iczonafranca  )
  values
  (sys_guid()        , v_identidad     , NULL                   , null        , v_iddoctrx      , v_qtmateriales ,v_dsreferencia      ,
   null              , v_cdsituacioniva, v_icestadosistema      , 3           , sysdate         , v_dtentrega    , v_cdtipodireccion ,
   v_idvendedor      , v_sqdireccion   , v_ammonto              , null        , v_idcomisionista, v_id_canal     , p_pedidoid_vtex   ,
   v_icretiraensucu  , null  )
   RETURNING idpedido  INTO v_idpedido;
   
   IF  SQL%ROWCOUNT = 0  THEN      --valida insert 
   	 if(SetVtexPedidos (p_pedidoid_vtex,null,2,'Error al insertar idpedido POs del pedido VTEX'||p_pedidoid_vtex)=0) then   
                     rollback;  
                     RETURN;  
                        
     end if;
     rollback; 
     RETURN;         
    END IF;
   
   --isertar los items del pedido si el arreglo trae datos
    IF (p_detalle(1) IS NOT NULL and LENGTH(TRIM(p_detalle(1)))>1) THEN
       FOR i IN 1 .. p_detalle.Count LOOP
         
          --o	Texto del 1 + 8 refId
          --o	Texto del 9 + 20 price  (2 �ltimos d�gitos decimal)
          --o	Texto del 29 + 6 quantity
          --o	Texto del 35 + 40  identifier (promo id VTEX) si no existe no se env�a.
          --o	Texto del 75 + 1 marca de promo (1) si la l�nea es promo (0) si la l�nea es producto 
        --  p_detalle(1):='0158777 4669                100                                           0';
          v_cdarticulo:=substr(p_detalle(i),1,8);          
          v_price:=to_number(trim(substr(p_detalle(i),9,20)))/100;          
          v_quantity:=to_number(substr(p_detalle(i),29,6)); --la cantidad en VTEX viene solo en unidades UN
          v_idpromo_vtex:=trim(substr(p_detalle(i),35,40));
          v_icresppromo:=to_number(substr(p_detalle(i),75,1));
          
          -- busco el  UxB del articulo 
          v_vluxb:=nvl(n_pkg_vitalpos_materiales.GetUxB(v_cdarticulo),0);
          
           -- obtengo el precio unitario sin iva
          v_ampreciounitario:= pkg_cld_datos.getpreciosiniva(v_cdarticulo,v_cdsucursal,v_price); 
          
          --valor de la linea
          v_amlinea:= v_quantity*v_ampreciounitario;
          
          --si la divisi�n es exacta y vluxb > 1 se pasa BTO sino UN
          if v_vluxb>1 and mod((v_quantity/v_vluxb),2)=0 then
            v_vlcantidad:=v_quantity/v_vluxb;
            v_cdunidadmedida:='BTO';            
          else
            v_vlcantidad:=v_quantity;
            v_cdunidadmedida:='UN';
          end if;      
               
          --busco el cdpromo 
          begin
            --verifica si existe cdpromo_vtex
            if LENGTH(TRIM(v_idpromo_vtex))>1 then
                select 
              distinct tp.cdpromo
                  into v_cdpromo
                  from vtexpromotion vp, 
                       tblpromo      tp
                 where vp.id_promo_pos = tp.id_promo
                   and vp.id_promo_vtex = v_idpromo_vtex;
            else
              v_cdpromo:=null;       
            end if;                   
            exception 
              when others then
               if(SetVtexPedidos (p_pedidoid_vtex,null,2,'Error al intentar recuperar promocion articulo: '||v_cdarticulo)=0) then         
                               rollback;
                               RETURN;  
                                      
               end if; 
               rollback;
               RETURN;                       
          end; 
          --busco la descripci�n del producto 
          begin
             if LENGTH(TRIM(v_cdarticulo))>1 then
               select substr(vp.name,1,50) 
                 into v_dsarticulo
                 from vtexproduct vp 
                where vp.refid = v_cdarticulo;
              else
                v_dsarticulo:=null;   
             end if;
            exception 
              when others then
                if(SetVtexPedidos (p_pedidoid_vtex,null,2,'Error al intentar recuperar descripcion del articulo: '||v_cdarticulo)=0) then         
                               rollback;  
                               RETURN;  
                                    
               end if; 
               rollback;  
               RETURN;               
          end;
                     
          insert into detallepedidos
          (idpedido           , sqdetallepedido , cdunidadmedida   , cdarticulo      , qtunidadpedido, qtunidadmedidabase  , qtpiezas     ,
           ampreciounitario   , amlinea         , vluxb            , dsobservacion   , icresppromo   , cdpromo             , dsarticulo   )
          values
          (v_idpedido         , i               , v_cdunidadmedida , v_cdarticulo    , v_vlcantidad  , v_quantity          , v_qtpiezas   ,
           v_ampreciounitario , v_amlinea       , v_vluxb          , NULL            , v_icresppromo , v_cdpromo           , v_dsarticulo);  
           
           IF  SQL%ROWCOUNT = 0  THEN      --valida insert 
             if(SetVtexPedidos (p_pedidoid_vtex,null,2,'Error al insertar detalle del pedido VTEX'||p_pedidoid_vtex||'cdarticulo: '||v_cdarticulo)=0) then         
                             rollback;  
                             RETURN;       
             end if; 
             rollback;  
             RETURN;   
            END IF;           
                              
       END LOOP;        
          
     ELSE     
     if(SetVtexPedidos (p_pedidoid_vtex,null,2,'No existen articulos en el pedido: '||v_idpedido)=0) then         
                     rollback;  
                     RETURN;       
     end if; 
     rollback;  
     RETURN;  
     END IF;
 
 
  -- Inserto un registro en tx_pedidos_insert para que el pedido sea considerado en la cola de pedidos del SLV
  insert into tx_pedidos_insert
  (iddoctrx  , idpedido          , cdsucursal  , cdcuit  )
  values
  (v_iddoctrx, v_idpedido        , v_cdsucursal, v_cdcuit);
  
  IF  SQL%ROWCOUNT = 0  THEN      --valida insert 
   	 if(SetVtexPedidos (p_pedidoid_vtex,null,2,'Error al insertar tx_pedidos_insert del pedido VTEX'||p_pedidoid_vtex)=0) then         
                     rollback;  
                     RETURN;       
     end if; 
     rollback;  
     RETURN;   
    END IF;

  -- Inserto las observaciones 
  if length(v_observacion)>1 then
    insert into observacionespedido
               (idpedido, dsobservacion)
    values
               (v_idpedido, v_observacion);
               
     IF  SQL%ROWCOUNT = 0  THEN      --valida insert 
   	 if(SetVtexPedidos (p_pedidoid_vtex,null,2,'Error al insertar observaciones del pedido VTEX'||p_pedidoid_vtex)=0) then         
                     rollback;  
                     RETURN;  
     end if; 
     rollback;  
     RETURN;  
    END IF;           
  end if;             
  
  --si es CF y ammomto superior al limite inserto para dividir pedido
    if v_cdsituacioniva = 2 and v_ammonto > v_limitedividepedido then
       INSERT INTO tx_pedidos_particionar
             (idpedido,limite,fecha)
             VALUES
             (v_idpedido,v_limitedividepedido,sysdate);
             
        IF  SQL%ROWCOUNT = 0  THEN      --valida insert 
           if(SetVtexPedidos (p_pedidoid_vtex,null,2,'Error al insertar tx_pedidos_particionar del pedido VTEX'||p_pedidoid_vtex)=0) then         
                           rollback;  
                           RETURN;                            
           end if;
           rollback;   
           RETURN;  
        END IF;      
    end if;
  if(SetVtexPedidos (p_pedidoid_vtex,null,1,'Insertado en POS Correctamente!')=0) then         
                           rollback;  
                           RETURN;                             
  end if; 
  COMMIT;   
  EXCEPTION
    WHEN OTHERS THEN
      if(SetVtexPedidos (p_pedidoid_vtex,null,2, 'Modulo: ' || v_Modulo || '  Error: ' ||SQLERRM)=0) then         
                      rollback;   
                       RETURN;  
       end if;               
   	  ROLLBACK;
      RETURN;  
END InsertarPedidoPOS;

end PKG_CLD_DATOS;
/
