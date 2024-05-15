CREATE OR REPLACE PACKAGE PKG_CLD_DATOS is

  type cursor_type Is Ref Cursor;

  TYPE PRODUCT IS RECORD (
        productid     INTEGER,
        name          VARCHAR2(60),
        departmentid  INTEGER,
        categoryid    INTEGER,
        subcategoryid INTEGER,
        brandid       INTEGER,
        linkid        VARCHAR2(100),
        refid         CHAR(8),
        isvisible     INTEGER,
        description   VARCHAR2(60),
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

  TYPE SKU IS RECORD (
        skuid           INTEGER,
        refid           CHAR(8),
        skuname         VARCHAR2(60),
        isactive        INTEGER,
        creationdate    DATE,
        unitmultiplier  INTEGER,
        measurementunit VARCHAR2(20),
        dtupdate        DATE,
        icprocesado     INTEGER,
        observacion     VARCHAR2(4000),
        dtinsert        DATE ,
        dtprocesado     DATE,
        ean             VARCHAR2(100));

  type t_SKU is table of SKU index by binary_integer;
  type t_SKU_pipe is table of SKU;

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
    -- todos los clientes con alguna aplicación activa que no esten en GWV
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
* prepara una cadena de texto para el estandar URL
* %v 20/11/2020 - ChM
***************************************************************************************************/
FUNCTION FORMATOURL( S IN VARCHAR2 ) RETURN VARCHAR2 IS

TMP VARCHAR2(255);
BEGIN

     TMP:= LOWER(S);
     TMP:= REPLACE(TMP,' ','-');
     TMP:= REPLACE(TMP,'á','a');
     TMP:= REPLACE(TMP,'é','e');
     TMP:= REPLACE(TMP,'í','i');
     TMP:= REPLACE(TMP,'ó','o');
     TMP:= REPLACE(TMP,'ú','u');
     TMP:= REPLACE(TMP,'à','a');
     TMP:= REPLACE(TMP,'è','e');
     TMP:= REPLACE(TMP,'ì','i');
     TMP:= REPLACE(TMP,'ò','o');
     TMP:= REPLACE(TMP,'ù','u');
     TMP:= REPLACE(TMP,'ñ','n');
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
--Buscar el IVA del artículo
   v_PorcIva := PKG_PRECIO.GetIvaArticulo(p_cdarticulo);

   --busca impuesto interno del articulo
   v_ImpInt  := pkg_impuesto_central.GetImpuestoInterno(p_cdsucursal, p_cdarticulo);

   --clacular precio con iva
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
* Carga en una tabla global en memoria los datos de todos los artículos activos en AC
* %v 16/11/2020 - ChM
***************************************************************************************************/
PROCEDURE CargarTablaProduct IS
  v_Modulo varchar2(100) := 'PKG_MERGE_DATOS_VTEX.CargarTablaProduct';
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
  v_Modulo varchar2(100) := 'PKG_MERGE_DATOS_VTEX.CargarProduct';

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
  v_Modulo varchar2(100) := 'PKG_MERGE_DATOS_VTEX.RefrescarProduct';

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
        --solo si aún esta active en 1
        update vtexproduct vp
          set vp.isactive = 0,
              vp.icprocesado = 0 -- 0 para procesar en API de VTEX
          where vp.isactive = 1  -- solo doy de baja los activos
            and vp.refid in (select distinct ar.cdarticulo
                               from articulos                    ar
                              where ar.cdestadoplu = '03'  --03 articulo desactivado permanentemente
                                and not exists
                              (select 1
                                       from articulosnocomerciales t
                                      where t.cdarticulo = ar.cdarticulo)
                                and not exists
                              (select 1
                                       from articulos_excluidos h
                                      where h.cdarticulo = ar.cdarticulo) --agrego tabla articulos excluidos
                                and substr(ar.cdarticulo, 1, 1) <> 'A'
                                and ar.cddrugstore not in ('EX', 'DE', 'CP')
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
--------------------------------------------------------------------------------------------------------------

/*************************************************************************************************************
* Carga en una tabla global en memoria los datos de todos los artículos activos en AC en los SKU por product
* %v 17/11/2020 - ChM
*************************************************************************************************************/
PROCEDURE CargarTablaSKU IS
  v_Modulo varchar2(100) := 'PKG_MERGE_DATOS_VTEX.CargarTablaSKU';

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
  v_Modulo varchar2(100) := 'PKG_MERGE_DATOS_VTEX.CargarSKU';

BEGIN

  delete vtexSKU;
  g_1_SKU.delete;
  -- llena la tabla en memoria
  CargarTablaSKU;
  -- la inserta en la definitiva
  insert into vtexSKU
    select * From Table(PipeSKUs);

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
  v_Modulo varchar2(100) := 'PKG_MERGE_DATOS_VTEX.RefrescarSKU';

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

   v_Modulo           varchar2(100) := 'PKG_MERGE_DATOS_VTEX.CargarStock';
   v_qtstock          articulosalmacen.qtstock%type;
  CURSOR c_stock IS
            with stock as(
          select aa.cdalmacen,
                 aa.cdarticulo,
                 vse.cdsucursal,
                 sum(aa.qtstock) qtstock
            from articulosalmacen aa,
                 vtexsellers vse,
                 vtexsku vs  --verifica si existe el sku
           where aa.cdarticulo = vs.refid
             and aa.cdsucursal = vse.cdsucursal    -- solo veo stock de sucursales en vtex
             and vse.cdsucursal <>'9999'           --excluyo principal de vtex
             and aa.cdalmacen = substr(aa.cdsucursal, 3, 2) || '01    '
           group by aa.cdalmacen,vse.cdsucursal, aa.cdarticulo),
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
                when (s.qtstock / DECODE(n_pkg_vitalpos_materiales.getuxb(s.cdarticulo),0,1)) >= nvl (v.cantbtos, '0')
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
   * %v 04/12/2020 - ChM - Actualizó precios VTEX en GWV de la tabla VTEXPRICE
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
         --solo canales de VTEX
         and p.id_canal in (select distinct vs.id_canal
                      from vtexsellers vs
                     where vs.cdsucursal<>'9999')
          -- solo sucursales en VTEX
          and p.cdsucursal in ( select distinct vs.cdsucursal
                         from vtexsellers vs
                        where vs.cdsucursal<>'9999')
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
                             where vs.cdsucursal<>'9999')
         -- solo sucursales en VTEX
         and p.cdsucursal in ( select distinct vs.cdsucursal
                                 from vtexsellers vs
                                where vs.cdsucursal<>'9999')
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
* Carga de todas las sucursales la información de TAPA, ofertas y promociones en las colecciones de VTEX
* %v 16/12/2020 - ChM
*********************************************************************************************************/

/*PROCEDURE CargarCollection (p_Fecha IN Tblarticulo_Tapa.Vigenciadesde%type) IS
  v_Modulo varchar2(100) := 'PKG_MERGE_DATOS_VTEX.CargarCollection';

BEGIN
  --OOOJJOOO FALTA guardar un historico de colecciones actualizadas en VTEX
  --limpio todas los sku de las distintas colecciones vigentes que se actualizarán
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
END CargarCollection;*/

end PKG_CLD_DATOS;
/
