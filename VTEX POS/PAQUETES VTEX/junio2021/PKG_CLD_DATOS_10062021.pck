CREATE OR REPLACE PACKAGE PKG_CLD_DATOS is

  type cursor_type Is Ref Cursor;

  type t_product is table of VTEXPRODUCT%ROWTYPE index by binary_integer;
  type t_product_pipe is table of VTEXPRODUCT%ROWTYPE;


  type t_SKU is table of VTEXSKU%ROWTYPE index by binary_integer;
  type t_SKU_pipe is table of VTEXSKU%ROWTYPE;

  TYPE arr_refid IS TABLE OF VARCHAR(100) INDEX BY PLS_INTEGER;

  type t_clients is table of VTEXCLIENTS%ROWTYPE index by binary_integer;
  type t_clients_pipe is table of VTEXCLIENTS%ROWTYPE;

  FUNCTION GETPrecioconIVA (p_cdarticulo articulos.cdarticulo%type,
                            p_cdsucursal sucursales.cdsucursal%type,
                            p_precio     tblprecio.amprecio%type) RETURN NUMBER;

 FUNCTION GETMULTIPLICADOR (P_CDARTICULO ARTICULOS.CDARTICULO%TYPE,
                            P_ID_CANAL   TBLLISTA_PRECIO_CENTRAL.ID_CANAL%TYPE DEFAULT 'VE') RETURN INTEGER;

  Function Pipeproducts Return t_product_pipe pipelined;
  Function PipeSKUS Return t_SKU_pipe pipelined;

  PROCEDURE CargarProduct;
  PROCEDURE RefrescarProduct;
  PROCEDURE CargarSKU;
  PROCEDURE RefrescarSKU;
  PROCEDURE CargarStock;
  Procedure RefrescarClientesApp;
  PROCEDURE RefrescarPreciosVTEX (p_Fecha IN tblprecio.dtvigenciadesde%type);
  FUNCTION RevisaPromoTodasSucursales (  P_ID_PROMO   VTEXPROMOTION.ID_PROMO_POS%TYPE,
                                         P_FECHA      TBLARTICULO_TAPA.VIGENCIADESDE%TYPE
                                       ) RETURN INTEGER;
  PROCEDURE RefrescarPromos (p_Fecha IN tblprecio.dtvigenciadesde%type);

  FUNCTION RevisaOfertaPromo ( P_CDARTICULO ARTICULOS.CDARTICULO%TYPE,
                               P_FECHA      TBLARTICULO_TAPA.VIGENCIADESDE%TYPE,
                               P_TIPO       VTEXCOLLECTION.ID_TIPO%TYPE) RETURN INTEGER;

  PROCEDURE CargarCollection (p_Fecha IN Tblarticulo_Tapa.Vigenciadesde%type);
  FUNCTION revisarmultipleUxB (p_id_promo TBLPROMO.ID_PROMO%type) RETURN integer;
  FUNCTION CantSKU (p_id_promo TBLPROMO.ID_PROMO%type) RETURN integer;
  FUNCTION promoSKU (p_id_promo TBLPROMO.ID_PROMO%type) RETURN integer;
  FUNCTION FnLeyendaPromoCorta(p_id_promo IN tblpromo.id_promo%type)  return varchar2;
  FUNCTION LeyendasPromoCucarda(p_id_promo tblpromo.id_promo%type) RETURN varchar2;

  FUNCTION GetAgente ( p_identidad    in entidades.identidad%type,
                       p_cdsucursal   in sucursales.cdsucursal%type)
                       RETURN VTEXCLIENTS.IDAGENT%type;

  FUNCTION Getcanal ( p_identidad    in entidades.identidad%type,
                      p_cdsucursal   in sucursales.cdsucursal%type)
                      RETURN VTEXCLIENTS.ID_CANAL%type;


   FUNCTION BajaClients RETURN INTEGER;

   PROCEDURE RefrescarClients;

   FUNCTION BajaAddress RETURN INTEGER;

   PROCEDURE RefrescarAddress;


end PKG_CLD_DATOS;
/
CREATE OR REPLACE PACKAGE BODY PKG_CLD_DATOS is

 g_l_product t_product;
 g_1_SKU t_SKU;
 g_l_clients t_clients;
 --tipo de cliente para subir a VTEX
 g_tipocliente varchar2(15):= 'TiendaOnline';

  /*****************************************************************************************
  * %v 04/10/2017 - IAquilano - Actualizo datos en la tabla clientes
  * %v 09/11/2017 - IAquilano - Agrego controles en las exceptions para loguear errores.
  * %v 08/05/2019 - IAquilano - Modifico agregando IF para controlar VPV innecesaria para comi
  * %v 14/02/2020 - IAguilano - Modifico para controlar marca para VitalDigital
  * %v 02/03/2020 - IAquilano - Agrego NVL a la comparativa de la tarjeta cliente fidelizado
  * %v 13/03/2020 - IAquilano - Agrego update de la razon social
  * %v 16/03/2020 - IAquilano - Bloqueo de consumidor final a la aplicacion vital digital.
* %v 22/12/2020 - IAquilano - Agrego l�gica de TiendaOnline
  * %v 19/4/2021  - APW - Corrijo deshabiliaci�n/iccomi, etc.
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
    v_iccf           integer;
    v_icactivo       integer;
    v_cantactivas    integer;

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
           and de.icactiva = '1'
           and ta.idcuenta <> '123456789'--filtramos las cuentas que venian
           and ta.vlaplicacion <> 'TiendaOnline';--filtramos la aplicacion tiendaonline

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

    v_iccomi := 0;
    v_icactivo := 0;

    --contamos cuantas aplicaciones activas tiene, por si alguna cuenta se deshabilito.
    select count(*)
    into v_cantactivas
    from tblentidadaplicacion tc
    where tc.idcuenta = r.idcuenta
    and tc.icactivo = 1
    and tc.vlaplicacion <> 'TiendaOnline';

    --Si no tiene aplicaciones habilitadas, marco en la clientesapp como cuenta desactivada para aplicaciones y me voy del loop.
    if v_cantactivas = 0 then
      update tblclientes_s tc
      set tc.icactivo = 0,
          tc.iccomi = 0,
          tc.icprocesado = 0
      where tc.idcuenta = r.idcuenta;

      GOTO end_loop;
    end if;

    --tiene al menos una aplicacion activa
    v_icactivo := 1;
    -- veo si corresponde ICCOMI
    select count(*)
      into v_iccomi
      from tblentidadaplicacion ta
     where ta.idcuenta = r.idcuenta
       and ta.icactivo = 1
       and ta.vlaplicacion = 'Vital Digital';

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
                 and ta.idcuenta <> '123456789'
                 and ta.vlaplicacion <> 'TiendaOnline'--filtramos la aplicacion tiendaonline
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
           and ta.icactivo = 1
           and ta.vlaplicacion <> 'TiendaOnline';

        --Si tiene mas de una habilitada, asumo que tiene vital digital (comi)

        If v_cantapp > 1 then
          v_icrequieretjcf := 1; -- la necesita para MiVital
          v_iccomi         := 1; -- la necesita para entrar a VitalDigital
        else
          -- sino busco que app tiene habilitada
          begin
            select distinct decode(ta.vlaplicacion,
                                   'Vital Digital',
                                   1,
                                   0),
                            taa.icrequieretjcf
              into v_iccomi, v_icrequieretjcf
              from tblentidadaplicacion ta, tblaplicacionautorizacion taa
             where ta.vlaplicacion = taa.vlaplicacion
               and ta.idcuenta = r.idcuenta
               and ta.vlaplicacion <> 'TiendaOnline';
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
                                 'Vital Digital',
                                 1,
                                 0),
                          taa.icrequieretjcf
            into v_iccomi, v_icrequieretjcf
            from tblentidadaplicacion ta, tblaplicacionautorizacion taa
           where ta.vlaplicacion = taa.vlaplicacion
             and ta.idcuenta = r.idcuenta
             and ta.vlaplicacion <> 'TiendaOnline';
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
   v_signo              number:=1;

  BEGIN
    if p_precio<0 then
      v_signo:=-1;
    else
      v_signo:=1;
    end if;
--Buscar el IVA del art�culo
   v_PorcIva := PKG_PRECIO.GetIvaArticulo(p_cdarticulo);

   --busca impuesto interno del articulo
   v_ImpInt  := pkg_impuesto_central.GetImpuestoInterno(p_cdsucursal, p_cdarticulo);

   --calcular precio con iva
   v_precioConIva := (abs(p_precio)-v_ImpInt)*(1+(v_PorcIva/100));

   --suma impuesto interno
   v_precioConIva := v_precioConIva + v_ImpInt;

   --redondeo amprecio a dos decimales
   v_precioConIva := round(v_precioConIva,2);

 RETURN  v_precioConIva*v_signo;

 END GETPrecioconIVA;

/**************************************************************************************************
* devuelve el factor del articulo
* %v 20/11/2020 - ChM
* %v 12/3/2021 - APW - Agrego tabla nueva de factor
* %v 10/06/2021 - ChM - Agrego logica de UV desDe tabla provicional de ventas
***************************************************************************************************/
  FUNCTION GETMULTIPLICADOR (P_CDARTICULO ARTICULOS.CDARTICULO%TYPE,
                             P_ID_CANAL   TBLLISTA_PRECIO_CENTRAL.ID_CANAL%TYPE DEFAULT 'VE') RETURN INTEGER IS
    V_MULTIPLICADOR INTEGER:=1;
    BEGIN
     /* select max(f.factor)
      into V_FACTOR
      from tblfactor f
      where f.cdarticulo = P_CDARTICULO;

      if v_factor is null then
        SELECT CASE WHEN UV<=1 THEN 1
                    ELSE UV
               END CASE    
          INTO V_MULTIPLICADOR
          FROM (
                select max(NVL(pc.factor,0)) uv                 
                  from tbllista_precio_central pc
                 where pc.cdarticulo=p_cdarticulo
               )A;
       end if;*/
     select UV.UV
       into V_MULTIPLICADOR  
       from VTEXUNIDADVENTA UV
      where UV.CDARTICULO = P_CDARTICULO
        and uv.id_canal=P_ID_CANAL;
       RETURN V_MULTIPLICADOR;
  EXCEPTION
    --si no lo encuentra busca el UxB
    WHEN NO_DATA_FOUND THEN
      V_MULTIPLICADOR:= n_pkg_vitalpos_materiales.GetUxB(P_CDARTICULO);
      IF V_MULTIPLICADOR = 0 THEN
        RETURN 1;
      ELSE
        RETURN V_MULTIPLICADOR; 
      END IF;    
    WHEN OTHERS THEN
         RETURN 1;
END  GETMULTIPLICADOR;


/**************************************************************************************************
* Carga en una tabla global en memoria los datos de todos los art�culos activos en AC
* %v 16/11/2020 - ChM
* %v 18/05/2021 - ChM Elimino el factor y agrego multiplicador
***************************************************************************************************/
PROCEDURE CargarTablaProduct IS

  v_Modulo varchar2(100) := 'PKG_CLD_DATOS.CargarTablaProduct';
 -- i        binary_integer := 1;
    CURSOR c_product IS
      select distinct to_number(ar.cdarticulo) productID,
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
             decode(n_pkg_vitalpos_materiales.GetUxB(ar.cdarticulo),0,1,n_pkg_vitalpos_materiales.GetUxB(ar.cdarticulo)) UXB,
             null observacion,
             0 icprocesado, --indica se debe procesar a VTEX
             null dtprocesado,
             trim(ac.VARIEDADNAME) VARIEDADNAME
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
        and vc.subcategoryid =ac.subcategoryid;
    BEGIN
       OPEN c_product;
     FETCH c_product  BULK COLLECT INTO g_l_product;      --cargo el cursor en la tabla en memoria
     CLOSE c_product;
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
* %v 18/05/2021 - ChM Elimino el factor y agrego multiplicador
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
           tvp.uxb,
           tvp.observacion,
           tvp.icprocesado,
           tvp.dtprocesado,
           tvp.variedad From Table(Pipeproducts) tvp;

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
* %v 18/05/2021 - ChM Elimino el factor y agrego multiplicador
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
      uxb,
      observacion,
      icprocesado,
      dtprocesado,
      variedad)
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
      tvp.uxb,
      tvp.observacion,
      tvp.icprocesado,
      tvp.dtprocesado,
      tvp.variedad)
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
            vp.uxb = tvp.uxb,
            vp.observacion = tvp.observacion,
            vp.icprocesado = tvp.icprocesado,
            vp.dtprocesado = tvp.dtprocesado,
            vp.variedad = tvp.variedad
       where -- solo se actualizan si hubo algun cambio
            vp.name <> tvp.name
         or vp.departmentid <> tvp.departmentid
         or vp.categoryid <> tvp.categoryid
         or vp.subcategoryid <> tvp.subcategoryid
         or nvl(vp.variedad,0) <> nvl(tvp.variedad,0)
         or vp.brandid <> tvp.brandid
         or vp.linkid <> tvp.linkid
         or vp.isvisible <> tvp.isvisible
         or vp.description <> tvp.description
         or vp.releasedate <> tvp.releasedate
         or vp.isactive <> tvp.isactive
         or nvl(vp.uxb,0) <> nvl(tvp.uxb,0);

        --esto ocurre cuando un articulo de AC viene en estado 03
        --esta logica pone active 0 baja definitiva de un articulo en VTEX
        --solo si a�n esta active en 1
        update vtexproduct vp
          set vp.isactive = 0,
              vp.icprocesado = 0, -- 0 para procesar en API de VTEX
              vp.dtprocesado = null,
              vp.observacion = null,
              vp.icnuevo = 0,
              vp.dtupdate = sysdate
          where vp.isactive = 1  -- solo doy de baja los activos
            and vp.refid in (select ar.cdarticulo
                               from articulos                    ar
                              where ar.cdestadoplu in ('03','01')  --03 articulo desactivado permanentemente 01 no habilitado para la venta
                                and substr(ar.cdarticulo, 1, 1) <> 'A'
                                and nvl(ar.cddrugstore,'XX') not in ('EX', 'DE', 'CP')
                              union --art�culos no comerciales
                             select t.cdarticulo
                               from articulosnocomerciales t
                              union --art�culos excluidos
                             select h.cdarticulo
                               from articulos_excluidos h
                               );
  commit;

EXCEPTION
  WHEN OTHERS THEN
    n_pkg_vitalpos_log_general.write(1,
                          'Modulo: ' || v_Modulo || '  Error: ' || SQLERRM);
END RefrescarProduct;
/*************************************************************************************************************
* Carga en una tabla global en memoria los datos de todos los art�culos activos en AC en los SKU por product
* %v 17/11/2020 - ChM
* %v 19/05/2021 - ChM ajusto si el art�culo no tiene barras el SKU este inactivo
*************************************************************************************************************/
PROCEDURE CargarTablaSKU IS
  v_Modulo varchar2(100) := 'PKG_CLD_DATOS.CargarTablaSKU';

  CURSOR c_sku IS
      select distinct
             vp.refid SKUid,
             vp.refid,
             vp.name skuname,
             --ajusto si el art�culo no tiene barras el SKU este inactivo
             nvl2(n_pkg_vitalpos_materiales.GetCodigoBarras(vp.refid),1,0) isactive,
             vp.releasedate CREATIONDATE,
             pkg_cld_datos.GETMULTIPLICADOR(vp.refid) unitmultiplier,
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
     set vp.icprocesado = 0,-- 0 para procesar en API de VTEX
         vp.observacion=null,
         vp.dtprocesado=null,
         vp.dtupdate=sysdate
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
         vp.dtprocesado=null,
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
* %v 20/05/2021 - ChM agrego unitmiltiplier
***************************************************************************************************/

PROCEDURE CargarStock IS

   v_Modulo           varchar2(100) := 'PKG_CLD_DATOS.CargarStock';
   v_qtstock          articulosalmacen.qtstock%type;

  CURSOR c_stock IS
            with stock as(
          select aa.cdalmacen,
                 aa.cdarticulo,
                 aa.cdsucursal,
                 sum(aa.qtstock) qtstock,
                 vs.unitmultiplier
            from articulosalmacen aa,
                -- vtexsellers vse,
                 vtexsku vs  --verifica si existe el sku
           where aa.cdarticulo = vs.refid
              -- solo veo stock de sucursales activas en vtex
             and aa.cdsucursal in (select vse.cdsucursal from vtexsellers vse where vse.icactivo = 1)
             and aa.cdalmacen = substr(aa.cdsucursal, 3, 2) || '01    '
           group by aa.cdalmacen,aa.cdsucursal, aa.cdarticulo,vs.unitmultiplier),
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
                end   as qtstock,
                s.unitmultiplier
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
        --verifica si cambia el stock lo actualiza
        if (v_qtstock*r_stock(i).unitmultiplier)  <> r_stock(i).qtstock then
           update vtexstock vs
              set vs.qtstock  = (r_stock(i).qtstock/r_stock(i).unitmultiplier),
                  vs.dtupdate = sysdate,
                  vs.icprocesado = 0,
                  vs.dtprocesado=null,
                  vs.observacion=null
            where vs.cdalmacen = r_stock(i).cdalmacen
              and vs.cdsucursal = r_stock(i).cdsucursal
              and vs.cdarticulo = r_stock(i).cdarticulo;
         end if;
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
                 (r_stock(i).qtstock/r_stock(i).unitmultiplier),
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
                       and vs.icactivo = 1
                       and vs.cdsucursal = p.cdsucursal)
          -- solo sucursales activas en VTEX
          and p.cdsucursal in ( select distinct vs.cdsucursal
                         from vtexsellers vs
                        where vs.cdsucursal<>'9999'
                          and vs.icactivo = 1)
         and p.dtvigenciadesde=pc_fecha
    order by p.dtmodificacion asc;
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
                  vp.icprocesado = 0,
                  vp.dtprocesado = null,
                  vp.observacion =null
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
                  vp.icprocesado = 0,
                  vp.dtprocesado = null,
                  vp.observacion = null
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

/**************************************************************************************************
* verifica si la oferta esta disponible para todas las sucursales activas en VTEXsellers
* %v 09/03/2021 - ChM
***************************************************************************************************/
  FUNCTION RevisaOfertaPromo ( P_CDARTICULO ARTICULOS.CDARTICULO%TYPE,
                               P_FECHA      TBLARTICULO_TAPA.VIGENCIADESDE%TYPE,
                               P_TIPO       VTEXCOLLECTION.ID_TIPO%TYPE) RETURN INTEGER IS

    V_CDARTICULO ARTICULOS.CDARTICULO%TYPE;

    BEGIN
      FOR suc IN
        (  select distinct
                  vs.cdsucursal
             from vtexsellers vs
            where vs.icactivo = 1
              --excluyo la 9999
              and vs.cdsucursal<>'9999    ')
      LOOP
        IF (P_TIPO='OF') THEN
            BEGIN
              select distinct vp.refid
                into v_cdarticulo
                from vtexprice vp
               where vp.cdsucursal=suc.cdsucursal
                 and p_fecha between vp.dtfromof and vp.dttoof
                 and vp.priceof is not null
                 and vp.refid=p_cdarticulo;
             EXCEPTION
               WHEN NO_DATA_FOUND THEN
               RETURN 0;
             END;
         END IF;
        IF (P_TIPO='PR') THEN
            BEGIN
              select distinct vps.refid
                into v_cdarticulo
                from vtexpromotion     vp,
                     vtexpromotionsku  vps
               where vp.id_promo_pos=vps.id_promo_pos
                 and vp.cdsucursal=suc.cdsucursal
                 and p_fecha between vp.begindateutc and vp.enddateutc
                 and vps.refid=p_cdarticulo;
             EXCEPTION
               WHEN NO_DATA_FOUND THEN
               RETURN 0;
             END;
         END IF;
     END LOOP;
    RETURN 1;
  EXCEPTION
  WHEN OTHERS THEN
    RETURN 0;
END  RevisaOfertaPromo;

 /*******************************************************************************************************
* Carga de todas las sucursales la informaci�n de TAPA, ofertas y promociones en las colecciones de VTEX
* %v 09/03/2021 - ChM
* %V 20/05/2021 - ChM inserto los SKUs de las colecciones de oferta por sucursal y canal 'CU'
*********************************************************************************************************/

PROCEDURE CargarCollection (p_Fecha IN Tblarticulo_Tapa.Vigenciadesde%type) IS
  v_Modulo varchar2(100) := 'PKG_CLD_DATOS.CargarCollection';

BEGIN
  --limpio todas los sku de las distintas colecciones
  delete VTEXCollectionSKU vcs;

  --recupero todas las colecciones por sucursal, tipo y canal
  for colle in
      (select collectionid,
              id_tipo,
              cdsucursal,
              id_canal
         from vtexcollection
         -- Solo colecciones vigentes
       -- where p_fecha between dtfrom and dtto
       )
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
         --inserto los SKUs de las colecciones de oferta y promociones por sucursal y canal
        if colle.id_tipo = 'OF' then
          --insert de las ofertas
           insert into VTEXCOLLECTIONSKU
                      (collectionid,skuid, refid)
                      select distinct
                             colle.collectionid,
                             vsk.skuid,
                             pre.refid
                        from vtexprice        pre,
                             vtexsku          vsk
                       where pre.refid = vsk.refid
                         --solo articulos vigentes de la vtexprecio
                         and p_fecha between pre.dtfromof and pre.dttoof
                         --solo precios en VTEX
                         and pre.icprocesado=1
                         --solo ofertas
                         and pre.priceof is not null
                          --todas las sucursales si es para la 9999
                         and case
                             when colle.cdsucursal='9999    ' AND RevisaOfertaPromo(pre.refid,P_FECHA,'OF') = 1 then 1
                             when colle.cdsucursal=pre.cdsucursal then 1
                               else 0
                             end = 1
                         and case
                             when colle.id_canal = 'DISTRIBU' and pre.id_canal in ('VE','CO') then 1
                             when pre.id_canal=colle.id_canal then 1
                             else 0
                             end = 1
                         -- excluyo articulos de la tapa
                         and pre.refid not in (select distinct art.cdarticulo
                                                      from tblarticulo_tapa art
                                                     where p_fecha between art.vigenciadesde and art.vigenciahasta
                                                       and art.cdsucursal = colle.cdsucursal
                                                        --no filtro canal en tapa por no estar definidos VE y CO solo DISTRIBU
                                                       --and art.cdcanal = colle.id_canal
                                                       )
          	          --insert de los articulos en PROMOCION
                      UNION
                      select distinct
                             colle.collectionid,
                             vps.skuid,
                             vps.refid
                        from vtexpromotion vp,
                             vtexpromotionsku vps
                       where vp.id_promo_pos = vps.id_promo_pos
                         --solo promociones activas
                         and vp.isactive = 1
                         --solo promos en vtex
                         and vp.icprocesado = 1
                          --todas las sucursales si es para la 9999
                         and case
                             when colle.cdsucursal='9999    ' AND RevisaOfertaPromo(vps.refid,P_FECHA,'PR') = 1 then 1
                             when colle.cdsucursal=vp.cdsucursal then 1
                               else 0
                             end = 1
                         and case
                             when colle.id_canal = 'DISTRIBU' and vp.id_canal in ('VE','CO') then 1
                             when vp.id_canal=colle.id_canal then 1
                             else 0
                             end = 1
                         --solo articulos vigentes de la vtexpromotion
                         and p_fecha between vp.begindateutc and vp.enddateutc
                          -- excluyo articulos de la tapa
                         and vps.refid not in (select distinct art.cdarticulo
                                                      from tblarticulo_tapa art
                                                     where p_fecha between art.vigenciadesde and art.vigenciahasta
                                                       and art.cdsucursal = colle.cdsucursal
                                                       --no filtro canal en tapa por no estar definidos VE y CO solo DISTRIBU
                                                       --and art.cdcanal = colle.id_canal
                                               );

         end if;
         --inserto los SKUs de las colecciones de oferta por sucursal y canal
        if colle.id_tipo = 'CU' then
          --insert de las ofertas
           insert into VTEXCOLLECTIONSKU
                      (collectionid,skuid, refid)
                      select distinct
                             colle.collectionid,
                             vsk.skuid,
                             pre.refid
                        from vtexprice        pre,
                             vtexsku          vsk
                       where pre.refid = vsk.refid
                         --solo articulos vigentes de la vtexprecio
                         and p_fecha between pre.dtfromof and pre.dttoof
                         --solo precios en VTEX
                         and pre.icprocesado=1
                         --solo ofertas
                         and pre.priceof is not null
                          --todas las sucursales si es para la 9999
                         and case
                             when colle.cdsucursal='9999    ' AND RevisaOfertaPromo(pre.refid,P_FECHA,'OF') = 1 then 1
                             when colle.cdsucursal=pre.cdsucursal then 1
                               else 0
                             end = 1
                         and case
                             when colle.id_canal = 'DISTRIBU' and pre.id_canal in ('VE','CO') then 1
                             when pre.id_canal=colle.id_canal then 1
                             else 0
                             end = 1;

         end if;
   end loop;
  commit;
EXCEPTION WHEN OTHERS THEN
  n_pkg_vitalpos_log_general.write(1, 'Modulo: ' || v_Modulo || '  Error: ' || SQLERRM);
  rollback;
END CargarCollection;

/**************************************************************************************************
* verifica si la promo esta disponible para todas las sucursales activas en VTEXsellers
* %v 19/05/2021 - ChM
***************************************************************************************************/
  FUNCTION RevisaPromoTodasSucursales (  P_ID_PROMO   VTEXPROMOTION.ID_PROMO_POS%TYPE,
                                         P_FECHA      TBLARTICULO_TAPA.VIGENCIADESDE%TYPE
                                       ) RETURN INTEGER IS

    V_ID_PROMO   VTEXPROMOTION.ID_PROMO_POS%TYPE;

    BEGIN
      FOR suc IN
        (  select distinct
                  vs.cdsucursal
             from vtexsellers vs
            where vs.icactivo = 1
              --excluyo la 9999
              and vs.cdsucursal<>'9999    ')
      LOOP
         BEGIN
          select distinct vp.id_promo_pos
            into V_ID_PROMO
            from vtexpromotion     vp
           where vp.cdsucursal=suc.cdsucursal
             and vp.id_promo_pos = P_ID_PROMO
             and p_fecha between vp.begindateutc and vp.enddateutc;
         EXCEPTION
           WHEN NO_DATA_FOUND THEN
           RETURN 0;
         END;
     END LOOP;
    RETURN 1;
  EXCEPTION
  WHEN OTHERS THEN
    RETURN 0;
END  RevisaPromoTodasSucursales;

/*************************************************************************************************************
* Actualiz� los datos de todas las promociones vigentes en AC en la tabla VTEXPROMOTION
* %v 29/12/2020 - ChM
* %v 14/04/2021 - ChM agrego ajuste para estado -2 promociones con m�s de 100 SKUS
* %v 18/05/2021 - ChM elimino las promociones tipo 1 NxM ajustes generales para la nueva caracteristica de VTEX
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
                  when pkg_CLD_DATOS.cantSKU(R.ID_PROMO) >=100 then -2
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
            AND trim(CANAL.ID_CANAL) in (select distinct vs.id_canal from vtexsellers vs where vs.icactivo = 1 and vs.cdsucursal=SUC.CDSUCURSAL) --Canales activos en VTEX
            AND R.ID_PROMO_TIPO = 7;

        TYPE lv_promo is table of c_promo%rowtype;
        r_promo        lv_promo;
        promo          vtexpromotion%rowtype;

BEGIN

     OPEN c_promo;
     FETCH c_promo  BULK COLLECT INTO r_promo;      --cargo el cursor en la tabla en memoria
     CLOSE c_promo;
      FOR i IN 1 .. r_promo.COUNT LOOP
        --verifica si es multiple UxB -1 o m�s de 100 sku -2 no la carga en vtexpromotion
        IF r_promo(i).uxb>=0 THEN
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
        END IF;
     END LOOP;
     /*--verifica si la promo se cumple para todas las sucursales
     for c_promos in
         (select distinct vp.id_promo_pos
            from vtexpromotion vp
           where p_fecha between vp.begindateutc and vp.enddateutc)
     loop
    --si la promo no esta en todas las sucursales se borra
    if RevisaPromoTodasSucursales (c_promos.id_promo_pos,P_FECHA) = 0 then
      delete vtexpromotionsku psku
       where psku.id_promo_pos = c_promos.id_promo_pos;
      delete vtexpromotion p
       where p.id_promo_pos = c_promos.id_promo_pos;
    end if;
     end loop;*/
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
* revisa la cantidad de SKUs que contiene la promo que recibe como parametro
* si es menor a 100 devuelve cantidad de SKU sino -2
* %v 14/04/2021 - ChM
***************************************************************************************************/
FUNCTION CantSKU (p_id_promo TBLPROMO.ID_PROMO%type) RETURN integer IS

  v_cant          integer:=0;

BEGIN
        select count(*)
          into v_cant
          from (
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
                  and p.id_promo = p_id_Promo) A
                  ;
   return v_cant;
EXCEPTION
  when others then
    return -2;
END CantSKU;

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
* recupera el id comisionista o vendedor del cliente seg�n corresponda
* %v 08/02/2021 - ChM
* %v 13/04/2021 - ChM incorporo el filtro por sucursal para canal TE y VE los vendedores y TELE
                      pueden atender la misma entidad en diferentes sucursales.
***************************************************************************************************/
FUNCTION GetAgente ( p_identidad    in entidades.identidad%type,
                     p_cdsucursal   in sucursales.cdsucursal%type)
                     RETURN VTEXCLIENTS.IDAGENT%type IS

     v_id          clientescomisionistas.idcomisionista%type:=null;
     v_id2         clientescomisionistas.idcomisionista%type:=null;
     v_id3         clientescomisionistas.idcomisionista%type:=null;

 BEGIN
   --busco el comisionista que atiende al cliente
    select cc.idcomisionista
      into v_id
      from clientescomisionistas cc
     where cc.identidad = p_identidad;
     BEGIN
        select cv.idviajante
          into v_id2
          from clientesviajantesvendedores cv
          --buscar los datos correspondientes al max(dthasta)
         where cv.dthasta = (select max(cv2.dthasta)
                               from clientesviajantesvendedores cv2)
           and cv.identidad = p_identidad
           and cv.cdsucursal = p_cdsucursal;
          --verifica si la identidad se encuentra en las dos tablas
          if v_id2 is not null then
            RETURN 'RCOyVE';  --agente registrado en comi y vendedor
          else
            RETURN v_id;
            end if;
     EXCEPTION
        WHEN TOO_MANY_ROWS THEN
             RETURN 'DCOyVE';  --agente duplicado en comi y vendedor
         WHEN NO_DATA_FOUND THEN
           --buscar el agente telemarketing
           BEGIN
            select ct.idpersona
              into v_id3
              from clientestelemarketing ct
             where ct.identidad = p_identidad
               and ct.cdsucursal = p_cdsucursal
               and ct.icactivo = 1;
             --verifica si la identidad se encuentra en las 2 tablas
            if v_id3 is not null then
              RETURN 'RCOyTE';  --agente registrado en comi y telemarketing
            else
              RETURN v_id;
              end if;
            EXCEPTION
              WHEN TOO_MANY_ROWS THEN
                  RETURN 'DTE';  --agente duplicado en telemarketing
              WHEN OTHERS THEN
                  RETURN v_id;
           END;
        WHEN OTHERS THEN
           RETURN v_id;
     END;
 EXCEPTION
   WHEN TOO_MANY_ROWS THEN
       RETURN 'DCO';  --agente duplicado en comi
   WHEN NO_DATA_FOUND THEN
        BEGIN
            select cv.idviajante
              into v_id
              from clientesviajantesvendedores cv
              --buscar los datos correspondientes al max(dthasta)
             where cv.dthasta = (select max(cv2.dthasta)
                                   from clientesviajantesvendedores cv2)
               and cv.identidad = p_identidad
               and cv.cdsucursal = p_cdsucursal;
             --buscar el agente telemarketing
             BEGIN
              select ct.idpersona
                into v_id3
                from clientestelemarketing ct
               where ct.identidad = p_identidad
                 and ct.cdsucursal = p_cdsucursal
                 and ct.icactivo = 1;
               --verifica si la identidad se encuentra en las 2 tablas
              if v_id3 is not null then
                RETURN 'RVEyTE';  --agente registrado en vendedor y telemarketing
              else
                RETURN v_id;
                end if;
              EXCEPTION
                WHEN TOO_MANY_ROWS THEN
                    RETURN 'DTE';  --agente duplicado en telemarketing
                WHEN OTHERS THEN
                    RETURN v_id;
             END;
        EXCEPTION
           WHEN TOO_MANY_ROWS THEN
             RETURN 'DVE';  --agente duplicado en vendedor
           WHEN NO_DATA_FOUND THEN
             --buscar el agente telemarketing
             BEGIN
              select ct.idpersona
                into v_id3
                from clientestelemarketing ct
               where ct.identidad = p_identidad
                 and ct.cdsucursal = p_cdsucursal
                 and ct.icactivo = 1;
                RETURN v_id3;
              EXCEPTION
                WHEN TOO_MANY_ROWS THEN
                    RETURN 'DTE';  --agente duplicado en telemarketing
                WHEN OTHERS THEN
                    RETURN 'NOAGT';
             END;
            WHEN OTHERS THEN
             RETURN 'NOAGT';  --error en busqueda de agente
        END;
   WHEN OTHERS THEN
         RETURN 'NOAGT';  --error en busqueda de agente
  END GetAgente;

  /**************************************************************************************************
* recupera el id comisionista o vendedor del cliente seg�n corresponda
* %v 08/02/2021 - ChM
* %v 13/04/2021 - ChM incorporo el filtro por sucursal para canal TE y VE los vendedores y TELE
                      pueden atender la misma entidad en diferentes sucursales.
***************************************************************************************************/
FUNCTION Getcanal ( p_identidad    in entidades.identidad%type,
                    p_cdsucursal   in sucursales.cdsucursal%type)
                   RETURN VTEXCLIENTS.ID_CANAL%type IS

     v_id           clientescomisionistas.idcomisionista%type:=null;
     v_id2          clientescomisionistas.idcomisionista%type:=null;
     v_id3          clientescomisionistas.idcomisionista%type:=null;

 BEGIN
   --busco el comisionista que atiende al cliente
    select cc.idcomisionista
      into v_id
      from clientescomisionistas cc
     where cc.identidad = p_identidad;
     BEGIN
         select cv.idviajante
                  into v_id2
                  from clientesviajantesvendedores cv
                  --buscar los datos correspondientes al max(dthasta)
                 where cv.dthasta = (select max(cv2.dthasta)
                                       from clientesviajantesvendedores cv2)
                   and cv.identidad = p_identidad
                   and cv.cdsucursal = p_cdsucursal;
          --verifica si la identidad se encuentra en las dos tablas
          if v_id2 is not null then
            RETURN 'NO';
          else
            RETURN 'CO';
            end if;
     EXCEPTION
        WHEN TOO_MANY_ROWS THEN
             RETURN 'NO';
        WHEN NO_DATA_FOUND THEN
             --buscar el CANAl en telemarketing
             BEGIN
              select ct.idpersona
                into v_id3
                from clientestelemarketing ct
               where ct.identidad = p_identidad
                 and ct.cdsucursal = p_cdsucursal
                 and ct.icactivo = 1;
               --verifica si la identidad se encuentra en las 2 tablas
               if v_id3 is not null then
                  RETURN 'NO';  --agente registrado en comi y telemarketing
               else
                  RETURN 'VE';
               end if;
             EXCEPTION
               WHEN TOO_MANY_ROWS THEN
                    RETURN 'NO';
               WHEN OTHERS THEN
                    RETURN 'CO';
             END;
        WHEN OTHERS THEN
           RETURN 'CO';
     END;
 EXCEPTION
   WHEN TOO_MANY_ROWS THEN
       RETURN 'NO';
   WHEN NO_DATA_FOUND THEN
        BEGIN
            select cv.idviajante
              into v_id2
              from clientesviajantesvendedores cv
              --buscar los datos correspondientes al max(dthasta)
             where cv.dthasta = (select max(cv2.dthasta)
                                   from clientesviajantesvendedores cv2)
               and cv.identidad = p_identidad
               and cv.cdsucursal = p_cdsucursal;
               --buscar el CANAl en telemarketing
             BEGIN
              select ct.idpersona
                into v_id3
                from clientestelemarketing ct
               where ct.identidad = p_identidad
                 and ct.cdsucursal = p_cdsucursal
                 and ct.icactivo = 1;
               --verifica si la identidad se encuentra en las 2 tablas
               if v_id3 is not null then
                  RETURN 'NO';  --agente registrado en vendedor y telemarketing
               else
                  RETURN 'VE';
               end if;
             EXCEPTION
               WHEN TOO_MANY_ROWS THEN
                    RETURN 'NO';
               WHEN OTHERS THEN
                    RETURN 'VE';
             END;
        EXCEPTION
           WHEN TOO_MANY_ROWS THEN
             RETURN 'NO';
           WHEN NO_DATA_FOUND THEN
              --buscar el CANAl en telemarketing
             BEGIN
              select ct.idpersona
                into v_id3
                from clientestelemarketing ct
               where ct.identidad = p_identidad
                 and ct.cdsucursal = p_cdsucursal
                 and ct.icactivo = 1;
               RETURN 'VE';
             EXCEPTION
               WHEN OTHERS THEN
                    RETURN 'NO';
             END;
            WHEN OTHERS THEN
             RETURN 'NO';
        END;
   WHEN OTHERS THEN
         RETURN 'NO';
  END Getcanal;

/**************************************************************************************************
* Carga en una tabla global en memoria los datos de todos los cliente  activos o inactivos en AC
  para subida en aplicaci�n VTEX.
* %v 05/02/2021 - ChM
***************************************************************************************************/
PROCEDURE CargarTablaClients (p_icactive  IN  vtexclients.icactive%type) IS

  v_Modulo varchar2(100) := 'PKG_CLD_DATOS.CargarTablaClients';

 cursor c_Clients is
      (select
       distinct
                ta.idcuenta id_cuenta,
                '1' clientsid_vtex,
                e.cdcuit cuit,
                e.dsrazonsocial razonsocial,
                ta.mail email,
                ta.cdsucursal,
                ta.icactivo icative,
                sysdate dtinsert,
                sysdate dtupdate,
                0 icprocesado,
                null dtprocesado,
                null observacion,
                'CL'  AGENT,
                PKG_CLD_DATOS.GetAgente(e.identidad,tc.cdsucursal) idagent,
                PKG_CLIENTE_CENTRAL.GetHabilitBebidaAlcoholica(e.identidad) ICALCOHOL,
                PKG_CLD_DATOS.GetCanal(e.identidad,tc.cdsucursal) id_canal,
                nvl(e.dsnombrefantasia,e.dsrazonsocial) fantasia,
                null icrevisadopos
           from tblentidadaplicacion ta,
                entidades            e,
                tblcuenta            tc
          where ta.identidad = e.identidad
            and tc.idcuenta = ta.idcuenta
            and ta.vlaplicacion = g_tipocliente
            and ta.icactivo = p_icactive
             --solo las entidades modificadas los ultimos 7 dias en tblentidadaplicacion no es posible por los cambios de idagente
           -- and ta.dtupdate>=trunc(sysdate-7)
      );
BEGIN
      g_l_clients.delete;
      OPEN c_Clients;
     FETCH c_Clients  BULK COLLECT INTO g_l_clients;      --cargo el cursor en la tabla en memoria
     CLOSE c_clients;
EXCEPTION
  WHEN OTHERS THEN
    n_pkg_vitalpos_log_general.write(1,
                          'Modulo: ' || v_Modulo || '  Error: ' || SQLERRM);
END  CargarTablaClients;

/**************************************************************************************************
* CU 02 Baja de Clientes B2B POS VTEX
* rsi�n: 1.2 18/03/2021
* Dependencias:	RAC, VTEX
* Precondici�n:	Los clientes est�n disponibles en la BD POS.
*               Los datos de baja solo ser�n manejados por POS y llevados a VTEX por integraci�n API.
*               El correo electr�nico es dato �nico en VTEX.
*               El correo electr�nico es dato m�ltiple en POS.
*               El idcuenta es el dato �nico en POS.
*
* Descripci�n:	El sistema debe dar de baja los clientes B2B de POS registrados en VTEX.
*               Secuencia Normal:
*  Paso	Acci�n
* 	1	  El sistema debe dar de baja los clientes INACTIVOS de POS marcados como �Tiendaonline� a VTEX.
* 	2	  En la baja de clientes se debe verificar si el idcuenta existe y est� registrado en VTEX si
*       es as� paso 3, sino tiene registro en VTEX elimina el registro y las direcciones asociadas.
* 	3	  Blanquea el idcuenta, marca inactivo el registro y actualiza inactivas las direcciones asociadas.
*
* %v 18/03/2021 - ChM
***************************************************************************************************/
FUNCTION BajaClients RETURN INTEGER IS

  v_Modulo            varchar2(100) := 'PKG_CLD_DATOS.BajaClients';
  v_clients           vtexclients%rowtype;
  v_cont              integer:=0;
BEGIN
      -- llena la tabla en memoria con los Clients inactivos de AC
  CargarTablaClients(0);

      FOR i IN 1 .. g_l_Clients.COUNT LOOP
          BEGIN
              select *
                into v_clients
                from vtexclients vc
               where vc.id_cuenta = g_l_Clients(i).id_cuenta
                 --verifica si ya tiene registro en VTEX
                 and vc.clientsid_vtex <>'1';
                 --Blanquea el idcuenta, marca inactivo el registro
                 UPDATE vtexclients vc2
                    SET vc2.id_cuenta = '1',
                        vc2.icactive = 0,
                        vc2.dtupdate = sysdate,
                        vc2.icprocesado = 0,
                        vc2.dtprocesado = null,
                        vc2.observacion = null
                  WHERE vc2.id_cuenta = v_clients.id_cuenta
                    AND vc2.clientsid_vtex = v_clients.clientsid_vtex;
                --actualiza inactivas las direcciones asociadas.
                  UPDATE vtexaddress va
                    SET va.id_cuenta = '1',
                        va.icactive = 0,
                        va.dtupdate = sysdate,
                        va.icprocesado = 0,
                        va.dtprocesado = null,
                        va.observacion = null
                  WHERE va.id_cuenta = v_clients.id_cuenta
                    AND va.clientsid_vtex = v_clients.clientsid_vtex;
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              --verifica si la idcuenta existe y no tiene registro en VTEX
              select count(*)
                into v_cont
                from vtexclients vc
               where vc.id_cuenta = g_l_Clients(i).id_cuenta
                 and vc.clientsid_vtex = '1';
               -- borro direcciones y idcuenta del cliente
               if nvl(v_cont,0)<>0 then
                   delete vtexaddress va
                    where va.id_cuenta = g_l_Clients(i).id_cuenta
                      and va.clientsid_vtex = g_l_Clients(i).clientsid_vtex;
                   delete vtexclients vcc
                    where vcc.id_cuenta = g_l_Clients(i).id_cuenta
                      and vcc.clientsid_vtex = g_l_Clients(i).clientsid_vtex;
               end if;
            WHEN OTHERS THEN
                  n_pkg_vitalpos_log_general.write(1,
                           'Modulo: ' || v_Modulo || '  Error: ' || SQLERRM);
                   ROLLBACK;
                   RETURN 0;
          END;
      END LOOP;
RETURN 1;
EXCEPTION
  WHEN OTHERS THEN
    n_pkg_vitalpos_log_general.write(1,
                          'Modulo: ' || v_Modulo || '  Error: ' || SQLERRM);
     ROLLBACK;
     RETURN 0;
END  BajaClients;
/**************************************************************************************************
* insert de  clientes en  VTEXCLIENTS
* %v 08/02/2021 - ChM
***************************************************************************************************/
FUNCTION InsertClients (p_clients vtexclients%rowtype) RETURN INTEGER IS

 v_Modulo varchar2(100) := 'PKG_CLD_DATOS.InsertClients';

 BEGIN
  insert into vtexclients vc
            ( vc.id_cuenta,
              vc.clientsid_vtex,
              vc.cuit,
              vc.razonsocial,
              vc.dsnombrefantasia,
              vc.email,
              vc.cdsucursal,
              vc.icactive,
              vc.dtinsert,
              vc.dtupdate,
              vc.icprocesado,
              vc.dtprocesado,
              vc.observacion,
              vc.idagent,
              vc.agent,
              vc.icalcohol,
              vc.id_canal)
     values
            ( p_clients.id_cuenta,
              p_clients.clientsid_vtex,
              p_clients.cuit,
              p_clients.razonsocial,
              p_clients.dsnombrefantasia,
              p_clients.email,
              p_clients.cdsucursal,
              p_clients.icactive,
              p_clients.dtinsert,
              p_clients.dtupdate,
              p_clients.icprocesado,
              p_clients.dtprocesado,
              p_clients.observacion,
              p_clients.idagent,
              p_clients.agent,
              p_clients.icalcohol,
              p_clients.id_canal);
  RETURN 1;
  EXCEPTION
  WHEN OTHERS THEN
     n_pkg_vitalpos_log_general.write(1,
                          'Modulo: ' || v_Modulo || '  Error: ' || SQLERRM);
     ROLLBACK;
     RETURN 0;

  END  InsertClients;

/**************************************************************************************************
* delete   clientes en  VTEXCLIENTS
* %v 18/03/2021 - ChM
***************************************************************************************************/
FUNCTION DeleteClients (p_clients vtexclients%rowtype) RETURN INTEGER IS

 v_Modulo varchar2(100) := 'PKG_CLD_DATOS.DeleteClients';

 BEGIN
    --elimina todas las direcciones asociadas al cliente
     delete vtexaddress va
      where va.id_cuenta = p_clients.id_cuenta
        and va.clientsid_vtex = p_clients.clientsid_vtex;
     --elimina al cliente
     delete vtexclients vc
      where vc.id_cuenta = p_clients.id_cuenta
        and vc.clientsid_vtex = p_clients.clientsid_vtex;
  RETURN 1;
  EXCEPTION
  WHEN OTHERS THEN
     n_pkg_vitalpos_log_general.write(1,
                          'Modulo: ' || v_Modulo || '  Error: ' || SQLERRM);
     ROLLBACK;
     RETURN 0;
  END  DeleteClients;


/*************************************************************************************************************
* CU 03 Alta de Clientes B2B POS VTEX
* Versi�n: 1.2 18/03/2021
* Dependencias:	RAC, VTEX
* Precondici�n:	Los clientes est�n disponibles en la BD POS.
*               Los datos de alta y cambios solo ser�n manejados por POS y llevados a VTEX por integraci�n API.
*               El correo electr�nico es dato �nico en VTEX.
*               El correo electr�nico es dato m�ltiple en POS.
*               El idcuenta es el dato �nico en POS.
*               Para que esto funcione se deben correr primero las bajas de clientes en VTEX.
* Descripci�n:	El sistema debe dar el alta de los clientes B2B registrados en POS a VTEX, adem�s mantener los
*               cambios  de clientes disponibles en POS para Tienda en l�nea.
* Secuencia Normal:	Paso	Acci�n
*                   	1	  El sistema debe dar el alta de los clientes marcados como �Tiendaonline� en POS a VTEX.
*                     2	  En el alta de clientes se debe verificar si el idcuenta existe si es as� verificar si se
*                         solicit� un cambio de correo va al paso 3 si es el mismo correo va al paso 5.
*                         Si no existe idcuenta va al paso 4
* 	                  3	  Si un cliente realiza cambio de correo electr�nico en POS el sistema debe buscar
*                         por idcuenta y realizar la baja del cliente en VTEX para ese idcuenta (borro el idcuenta
*                         en 1 e inactivar las direcciones asociadas), posterior a esto buscar si el correo
*                         electr�nico existe si es as� paso 6, sino lo encuentra realizar el alta para un nuevo
*                         cliente en VTEX con el mismo idcuenta. Si aplica excepci�n 1 se inserta el nuevo idcuenta.
* 	                  4	  Si no existe registro en VTEX se verificar si el correo se encuentra registrado e inactivo
*                         de ser as� se mantiene el idclienteVTEX y se actualiza el idcuenta al mismo y todos los
*                         datos de la nueva cuenta, adem�s se inactivan las direcciones asociadas al idcuenta que se
*                         modific� y se dan de alta las direcciones del nuevo idcuenta.
*                         Si aplica excepci�n 1 se inserta el nuevo idcuenta
* 	                  5	  Si se solicita cambio de datos del cliente (no correo) se actualizan todos los datos por
*                         cambio en POS para actualizar de VTEX.
* 	                  6	  Al correo encontrado le actualizo idcuenta y todos los datos del cliente los actualizo
*                         con la informaci�n del nuevo idcuenta. Si aplica excepci�n 1 se inserta el nuevo idcuenta.
* Post condici�n:	Los clientes con estado inactivos se borran de VTEX por API.
* Excepciones:	1	Para el paso 3, 4 y 6 si el cliente no tiene asociado idcliente_VTEX
                (no registrado en VTEX) se elimina el registro del idcuenta asociado y sus direcciones
* %v 18/03/2021 - ChM
***************************************************************************************************/
PROCEDURE RefrescarClients IS

  v_Modulo varchar2(100) := 'PKG_CLD_DATOS.RefrescarClients';
  v_clients vtexclients%rowtype;

BEGIN
  --Para que esto funcione se deben correr primero las bajas de clientes en VTEX.
  if BajaClients = 0 then
    n_pkg_vitalpos_log_general.write(1,
                          'Modulo: ' || v_Modulo || '  Error: no es posible realizar la baja de Clientes');
    rollback;
    return;
  else
    commit;
  end if;

  -- llena la tabla en memoria con los Clientes activos de AC
  CargarTablaClients(1);

      FOR i IN 1 .. g_l_Clients.COUNT LOOP
          BEGIN
          select *
            into v_clients
            from vtexclients vc
           where vc.id_cuenta = g_l_Clients(i).id_cuenta;
           --si lo encuentra verifica si cambio el email
           if v_clients.email <> g_l_Clients(i).email then
           -- si ya esta registrado en VTEX
            if v_clients.clientsid_vtex<>'1' then
                -- realizar la baja del cliente en VTEX para ese idcuenta borro el idcuenta en 1
                update vtexclients vc
                     set vc.icactive=0,
                         vc.id_cuenta = '1',
                         vc.dtupdate=sysdate,
                         vc.icprocesado=0,
                         vc.dtprocesado=null,
                         vc.observacion=null
                   where vc.id_cuenta = v_clients.id_cuenta
                     and vc.clientsid_vtex = v_clients.clientsid_vtex;
                 --e inactivar las direcciones asociadas
                  update vtexaddress va
                     set va.id_cuenta = '1',
                         va.icactive = 0,
                         va.dtupdate = sysdate,
                         va.icprocesado = 0,
                         va.dtprocesado = null,
                         va.observacion = null
                   where va.id_cuenta = v_clients.id_cuenta
                     and va.clientsid_vtex = v_clients.clientsid_vtex;

                 --posterior a esto buscar si el correo electr�nico existe si es as� paso 6
                    BEGIN
                    select *
                      into v_clients
                      from vtexclients vc
                     where vc.email = g_l_Clients(i).email;
                     --Al correo encontrado le actualizo idcuenta y todos los datos del cliente los actualizo
                     --con la informaci�n del nuevo idcuenta. Solo si esta registrado el mail en VTEX
                     if(v_clients.clientsid_vtex <> '1') then --if 2
                          update vtexclients vc
                             set vc.id_cuenta=g_l_Clients(i).id_cuenta,
                                 vc.cuit=g_l_Clients(i).cuit,
                                 vc.razonsocial=g_l_Clients(i).razonsocial,
                                 vc.email=g_l_Clients(i).email,
                                 vc.cdsucursal=g_l_Clients(i).cdsucursal,
                                 vc.icactive=g_l_Clients(i).icactive,
                                 vc.icalcohol=g_l_Clients(i).icalcohol,
                                 vc.agent=g_l_Clients(i).agent,
                                 vc.idagent=g_l_Clients(i).idagent,
                                 vc.id_canal=g_l_Clients(i).id_canal,
                                 vc.dsnombrefantasia=g_l_Clients(i).dsnombrefantasia,
                                 vc.dtupdate=sysdate,
                                 vc.icprocesado=0,
                                 vc.dtprocesado=null,
                                 vc.observacion=null
                           where vc.id_cuenta = v_clients.id_cuenta
                             and vc.clientsid_vtex = v_clients.clientsid_vtex;
                         --actualiz� INACTIVAS LAS vtexaddress anteriores y les asocio el idcuenta
                           update vtexaddress va
                              set va.icactive = 0,
                                  va.id_cuenta = g_l_Clients(i).id_cuenta,
                                  va.dtupdate=sysdate,
                                  va.icprocesado=0,
                                  va.dtprocesado=null,
                                  va.observacion=null
                            where va.id_cuenta = v_clients.id_cuenta
                              and va.clientsid_vtex = v_clients.clientsid_vtex;
                     else    --if 2
                        --(no registrado en VTEX) se elimina el registro del idcuenta asociado y sus direcciones
                         If DeleteClients(g_l_Clients(i))=0 then rollback; return; end if;
                        --Si aplica excepci�n 1 se inserta el nuevo idcuenta.
                         If insertClients(g_l_Clients(i))=0 then rollback; return; end if;
                     end if; --if 2
                      EXCEPTION
                    --si no lo encuentra INSERTA UN NUEVO CLIENTE
                    WHEN NO_DATA_FOUND THEN
                      If insertClients(g_l_Clients(i))=0 then rollback; return; end if;
                    WHEN OTHERS THEN
                      n_pkg_vitalpos_log_general.write(1,
                          'Modulo: ' || v_Modulo || '  Error: en la busqueda de mail de Clientes');
                      rollback;
                      return;
                   END;
              else    --clients.clientsid_vtex<>'1'
                --(no registrado en VTEX) se elimina el registro del idcuenta asociado y sus direcciones
                 If DeleteClients(g_l_Clients(i))=0 then rollback; return; end if;
                --Si aplica excepci�n 1 se inserta el nuevo idcuenta.
                 If insertClients(g_l_Clients(i))=0 then rollback; return; end if;
              end if; --clients.clientsid_vtex<>'1'
          else
              -- Si se solicita cambio de datos del cliente (no correo) se actualizan todos los datos por
              -- cambio en POS para actualizar de VTEX.
               if(v_clients.razonsocial <> g_l_Clients(i).razonsocial or v_clients.cdsucursal <> g_l_Clients(i).cdsucursal
                  or v_clients.icactive <> g_l_Clients(i).icactive or v_clients.idagent<> g_l_Clients(i).idagent
                  or v_clients.email <> g_l_Clients(i).email or v_clients.icalcohol <> g_l_Clients(i).icalcohol
                  or v_clients.id_canal <> g_l_Clients(i).id_canal or v_clients.dsnombrefantasia <> g_l_Clients(i).dsnombrefantasia) then
                    update vtexclients vc
                       set vc.razonsocial=g_l_Clients(i).razonsocial,
                           vc.email=g_l_Clients(i).email,
                           vc.cdsucursal=g_l_Clients(i).cdsucursal,
                           vc.icactive=g_l_Clients(i).icactive,
                           vc.icalcohol=g_l_Clients(i).icalcohol,
                           vc.idagent=g_l_Clients(i).idagent,
                           vc.id_canal=g_l_Clients(i).id_canal,
                           vc.dsnombrefantasia = g_l_Clients(i).dsnombrefantasia,
                           vc.dtupdate=sysdate,
                           vc.icprocesado=0,
                           vc.dtprocesado=null,
                           vc.observacion=null
                     where vc.id_cuenta = v_clients.id_cuenta
                       and vc.clientsid_vtex = v_clients.clientsid_vtex;
               end if;
           end if;
      	EXCEPTION
          --si no encuentra el idcuenta
          WHEN NO_DATA_FOUND THEN
              --busca por email. se verificar si el correo se encuentra registrado
              BEGIN
              select *
                into v_clients
                from vtexclients vc
               where vc.email = g_l_Clients(i).email;
               --e ianctivo (no tiene cuenta asociada el correo encontrado)
               if v_clients.id_cuenta = '1' then --if  3
                 --de ser as� se mantiene el clientsid_VTEX y se actualiza el idcuenta al mismo y todos los
                 -- datos de la nueva cuenta, adem�s se inactivan las direcciones asociadas al idcuenta que se modific�
                  if v_clients.clientsid_vtex <> '1' then -- if 4
                    update vtexclients vc
                       set vc.id_cuenta=g_l_Clients(i).id_cuenta,
                           vc.cuit=g_l_Clients(i).cuit,
                           vc.razonsocial=g_l_Clients(i).razonsocial,
                           vc.email=g_l_Clients(i).email,
                           vc.cdsucursal=g_l_Clients(i).cdsucursal,
                           vc.icactive=g_l_Clients(i).icactive,
                           vc.icalcohol=g_l_Clients(i).icalcohol,
                           vc.agent=g_l_Clients(i).agent,
                           vc.idagent=g_l_Clients(i).idagent,
                           vc.id_canal=g_l_Clients(i).id_canal,
                           vc.dsnombrefantasia=g_l_Clients(i).dsnombrefantasia,
                           vc.dtupdate=sysdate,
                           vc.icprocesado=0,
                           vc.dtprocesado=null,
                           vc.observacion=null
                     where vc.id_cuenta = v_clients.id_cuenta
                       and vc.clientsid_vtex = v_clients.clientsid_vtex;
                   --actualiz� INACTIVAS LAS vtexaddress anteriores para consistencia de datos
                     update vtexaddress va
                        set va.icactive = 0,
                            va.id_cuenta = g_l_Clients(i).id_cuenta,
                            va.dtupdate=sysdate,
                            va.icprocesado=0,
                            va.dtprocesado=null,
                            va.observacion=null
                      where va.id_cuenta = v_clients.id_cuenta
                        and va.clientsid_vtex = v_clients.clientsid_vtex;
                  else    --if 4
                        --(no registrado en VTEX) se elimina el registro del idcuenta asociado y sus direcciones
                         If DeleteClients(g_l_Clients(i))=0 then rollback; return; end if;
                        --Si aplica excepci�n 1 se inserta el nuevo idcuenta.
                         If insertClients(g_l_Clients(i))=0 then rollback; return; end if;
                  end if; --if 4
                  else --if 3
                  n_pkg_vitalpos_log_general.write(2, 'Modulo: '||v_modulo||'  Error: correo '
                                  || g_l_Clients(i).email||' idcuenta: '||v_clients.id_cuenta );
                  rollback;
                  return;
                end if; --if 3
                EXCEPTION
              --si no lo encuentra INSERTA UN NUEVO CLIENTE
              WHEN NO_DATA_FOUND THEN
                If insertClients(g_l_Clients(i))=0 then rollback; return; end if;
                   END;
          WHEN others THEN
              n_pkg_vitalpos_log_general.write(2, 'Modulo: '||v_modulo||'  Error: en buscar correo ' || SQLERRM);
             rollback;
                return;
       END;
     END LOOP;

  commit;

EXCEPTION
  WHEN OTHERS THEN
    n_pkg_vitalpos_log_general.write(1,
                          'Modulo: ' || v_Modulo || '  Error: ' || SQLERRM);
END RefrescarClients;

/**************************************************************************************************
* dar de baja direcciones de todos los clientes ACTIVOS en la VTEXCLIENTS
* que estan inactivas en POS
* %v 09/02/2021 - ChM
***************************************************************************************************/
FUNCTION BajaAddress RETURN INTEGER IS

  v_Modulo varchar2(100) := 'PKG_CLD_DATOS.BajaAddress';

    CURSOR c_ADDRESS IS
    select distinct
           tdc.idcuenta,
           vc.clientsid_vtex,
           de.cdtipodireccion,
           de.sqdireccion,
           de.cdcodigopostal,
           de.dscalle,
           de.dsnumero,
           l.dslocalidad,
           pp.dsprovincia,
           de.icactiva icactive
      from entidades              e,
           direccionesentidades   de,
           localidades            l,
           provincias             pp,
           tbldireccioncuenta     tdc,
           tblcuenta              c,
           tblentidadaplicacion   ta,
           vtexclients            vc,
           vtexaddress             va
     where e.identidad = de.identidad
       and e.identidad = tdc.identidad
       and e.identidad = c.identidad
       and c.idcuenta = tdc.idcuenta
       and de.cdtipodireccion = tdc.cdtipodireccion
       and de.sqdireccion = tdc.sqdireccion
       and de.cdpais = l.cdpais
       and de.cdprovincia = l.cdprovincia
       and de.cdlocalidad = l.cdlocalidad
       and de.cdpais = pp.cdpais
       and de.cdprovincia = pp.cdprovincia
       and e.identidad = de.identidad
       and e.identidad = ta.identidad
       --solo direcciones INactivas
       and de.icactiva = 0
       -- solo cuentas de clientes en VTEXCLIENTS
       and c.idcuenta = vc.id_cuenta
       --solo cuentas existentes y activas en VTEXADRESS
       and va.id_cuenta = tdc.idcuenta
       and va.cdtipodireccion = de.cdtipodireccion
       and va.sqdireccion = de.sqdireccion
       and va.icactive = 1
       ;

        TYPE lv_address  is table of c_ADDRESS%rowtype;
        r_address        lv_address;

    CURSOR c_ADDRESS_DIR IS
         --direcciones disponibles en VTEXADRESS que no est�n en TBLDIRECCIONCUENTA
          select va.id_cuenta,
                 va.cdtipodireccion,
                 va.sqdireccion
            from vtexaddress  va,
                 vtexclients vc
                 --solo direcciones activas en vtexadress
           where va.icactive = 1
             and vc.id_cuenta = va.id_cuenta
             --solo clientes activos en vtexclients
             and vc.icactive = 1
           minus
          select dc.idcuenta,
                 dc.cdtipodireccion,
                 dc.sqdireccion
            from tbldireccioncuenta dc
              ;
     TYPE lv_address_dir  is table of c_ADDRESS_dir%rowtype;
        r_address_dir        lv_address_dir;

BEGIN

     OPEN c_ADDRESS;
     FETCH c_ADDRESS  BULK COLLECT INTO r_address;      --cargo el cursor en la tabla en memoria
     CLOSE c_address;
      FOR i IN 1 .. r_address.COUNT LOOP
              --inactivo en VTEXADRESS direcciones inactivas en POS
                update vtexaddress va
                   set va.icactive = 0,
                       va.dtupdate=sysdate,
                       va.icprocesado=0,
                       va.dtprocesado=null,
                       va.observacion=null
                 where va.id_cuenta = r_address(i).idcuenta
                   and va.clientsid_vtex = r_address(i).clientsid_vtex
                   and va.cdtipodireccion = r_address(i).cdtipodireccion
                   and va.sqdireccion = r_address(i).sqdireccion;
       END LOOP;


     OPEN c_ADDRESS_dir;
     FETCH c_ADDRESS_dir  BULK COLLECT INTO r_address_dir;      --cargo el cursor en la tabla en memoria
     CLOSE c_address_dir;
      FOR i IN 1 .. r_address_dir.COUNT LOOP
              --inactivo en VTEXADRESS direcciones que no est�n en TBLDIRECCIONCUENTA
                update vtexaddress va
                   set va.icactive = 0,
                       va.dtupdate=sysdate,
                       va.icprocesado=0,
                       va.dtprocesado=null,
                       va.observacion=null
                 where va.id_cuenta = r_address_dir(i).id_cuenta
                  -- and va.clientsid_vtex = r_adress(i).clientsid_vtex
                   and va.cdtipodireccion = r_address_dir(i).cdtipodireccion
                   and va.sqdireccion = r_address_dir(i).sqdireccion
                   --solo activas en vtexclients
                   and va.icactive = 1;
       END LOOP;
  RETURN 1;
  commit;
 EXCEPTION
    WHEN OTHERS THEN
         n_pkg_vitalpos_log_general.write(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM);
             rollback;
             return 0;
  END BajaAddress;

/**************************************************************************************************
* Refrescar las direcciones de los clientes en VTEXADDRESS
* inserta o actualiza las direcciones de todos los clientes ACTIVOS en la VTEXCLIENTS
* %v 09/02/2021 - ChM
***************************************************************************************************/
PROCEDURE RefrescarAddress IS

  v_Modulo varchar2(100) := 'PKG_CLD_DATOS.RefrescarAddress';

  CURSOR c_ADDRESS IS
    select distinct
           tdc.idcuenta,
           vc.clientsid_vtex,
           de.cdtipodireccion,
           de.sqdireccion,
           de.cdcodigopostal,
           de.dscalle,
           de.dsnumero,
           l.dslocalidad,
           pp.dsprovincia,
           de.icactiva icactive
      from entidades              e,
           direccionesentidades   de,
           localidades            l,
           provincias             pp,
           tbldireccioncuenta     tdc,
           tblcuenta              c,
           tblentidadaplicacion   ta,
           vtexclients            vc
     where e.identidad = de.identidad
       and e.identidad = tdc.identidad
       and e.identidad = c.identidad
       and c.idcuenta = tdc.idcuenta
       and de.cdtipodireccion = tdc.cdtipodireccion
       and de.sqdireccion = tdc.sqdireccion
       and de.cdpais = l.cdpais
       and de.cdprovincia = l.cdprovincia
       and de.cdlocalidad = l.cdlocalidad
       and de.cdpais = pp.cdpais
       and de.cdprovincia = pp.cdprovincia
       and e.identidad = de.identidad
       and e.identidad = ta.identidad
       --solo direcciones activas
       and de.icactiva = 1
       -- solo cuentas activas de clientes en VTEXCLIENTS
       and c.idcuenta = vc.id_cuenta
       and vc.icactive = 1
       --solo las entidades modificadas los ultimos 7 dias en tblentidadaplicacion
       and ta.dtupdate>=trunc(sysdate-7)
       ;

        TYPE lv_address  is table of c_ADDRESS%rowtype;
        r_address        lv_address;
        address          vtexaddress%rowtype;

BEGIN
    -- primero se llama las bajas de direcciones en VTEX.
  if BajaAddress = 0 then
    n_pkg_vitalpos_log_general.write(1,
                          'Modulo: ' || v_Modulo || '  Error: no es posible realizar la baja de direcciones');
  else
    commit;
  end if;


     OPEN c_ADDRESS;
     FETCH c_ADDRESS  BULK COLLECT INTO r_address;      --cargo el cursor en la tabla en memoria
     CLOSE c_address;
      FOR i IN 1 .. r_address.COUNT LOOP
        BEGIN
          select *
            into address
            from vtexaddress va
           where va.id_cuenta = r_address(i).idcuenta
             and va.clientsid_vtex = r_address(i).clientsid_vtex
             and va.cdtipodireccion = r_address(i).cdtipodireccion
             and va.sqdireccion = r_address(i).sqdireccion;
           --si lo encuentra verifica si algo cambio en las direcciones y actualiza
           if(address.cdpostal <> r_address(i).cdcodigopostal or address.dscalle <> r_address(i).dscalle or
              address.dsnumcalle <> r_address(i).dsnumero or address.dslocalidad <> r_address(i).dslocalidad or
              address.dsprovincia <> r_address(i).dsprovincia or address.icactive <> r_address(i).icactive ) then
                update vtexaddress va
                   set va.cdpostal=r_address(i).cdcodigopostal,
                       va.dscalle=r_address(i).dscalle,
                       va.dsnumcalle=r_address(i).dsnumero,
                       va.dslocalidad=r_address(i).dslocalidad,
                       va.dsprovincia=r_address(i).dsprovincia,
                       va.icactive=r_address(i).icactive,
                       va.dtupdate=sysdate,
                       va.icprocesado=0,
                       va.dtprocesado=null,
                       va.observacion=null
                 where va.id_cuenta = r_address(i).idcuenta
                   and va.clientsid_vtex = r_address(i).clientsid_vtex
                   and va.cdtipodireccion = r_address(i).cdtipodireccion
                   and va.sqdireccion = r_address(i).sqdireccion;
             end if;
      	EXCEPTION
          --si no lo encuentra inserta la direcci�n
          WHEN NO_DATA_FOUND THEN
           insert into vtexaddress va
                 ( va.id_cuenta,
                   va.clientsid_vtex,
                   va.cdtipodireccion,
                   va.sqdireccion,
                   va.cdpostal,
                   va.dscalle,
                   va.dsnumcalle,
                   va.dslocalidad,
                   va.dsprovincia,
                   va.icactive,
                   va.dtinsert,
                   va.dtupdate,
                   va.icprocesado,
                   va.dtprocesado,
                   va.observacion
                 )
          values ( r_address(i).idcuenta,
                   r_address(i).clientsid_vtex,
                   r_address(i).cdtipodireccion,
                   r_address(i).sqdireccion,
                   r_address(i).cdcodigopostal,
                   r_address(i).dscalle,
                   r_address(i).dsnumero,
                   r_address(i).dslocalidad,
                   r_address(i).dsprovincia,
                   r_address(i).icactive,
                   sysdate,
                   sysdate,
                   0,
                   null,
                   null);

             IF  SQL%ROWCOUNT = 0  THEN      --valida update de zona
                  n_pkg_vitalpos_log_general.write(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM
                                                  ||' Id cuenta: '||r_address(i).idcuenta ||'Id_VTEX: '||r_address(i).clientsid_vtex);
                  ROLLBACK;
                  RETURN;
                END IF;

          WHEN others THEN
              n_pkg_vitalpos_log_general.write(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM
                                                  ||' Id cuenta: '||r_address(i).idcuenta );
             rollback;
             return;
       END;
     END LOOP;
    --inserta informaci�n de clientes que no tienen direcci�n asociada se le agrega la direcci�n comercial �nica
 insert into vtexaddress va
        select distinct
               cu.idcuenta,
               vc.clientsid_vtex,
               de.cdtipodireccion,
               max(de.sqdireccion)sqdireccion,
               de.cdcodigopostal,
               de.dscalle,
               de.dsnumero dsnumcalle,
               l.dslocalidad,
               pp.dsprovincia,
               de.icactiva icactive,
               sysdate dtinsert,
               sysdate dtupdate,
               0 icprocesado,
               null dtprocesado,
               null observacion,
               null iddireccion_vtex,
               null icrevisadopos
          from direccionesentidades de,
               tblcuenta            cu,
               localidades          l,
               provincias           pp,
               vtexclients          vc
         where de.identidad = cu.identidad
           and de.cdlocalidad = l.cdlocalidad
           and de.cdpais = l.cdpais
           and de.cdprovincia = l.cdprovincia
           and de.cdprovincia= pp.cdprovincia
           and de.cdpais = pp.cdpais
           and vc.id_cuenta = cu.idcuenta
           --ubico la direccion comercial del cliente activa
           and de.cdtipodireccion = 2
           and de.icactiva = 1
           and cu.idcuenta in (
                              --listo los clientes sin direccion asignada
                              select vc.id_cuenta
                                from vtexclients vc
                               where vc.id_cuenta not in (select va.id_cuenta
                                                            from vtexaddress va)
                              )
      group by cu.idcuenta,
               vc.clientsid_vtex,
               de.cdtipodireccion,
               de.cdcodigopostal,
               de.dscalle,
               de.dsnumero,
               l.dslocalidad,
               pp.dsprovincia,
               de.icactiva;
     commit;
 EXCEPTION
    WHEN OTHERS THEN
         n_pkg_vitalpos_log_general.write(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM);
             rollback;
             return;
  END RefrescarAddress;
/**************************************************************************************************
* recupera el canal comisionista, vendedor o telemarketing del cliente seg�n corresponda
* %v 27/04/2021 - ChM
***************************************************************************************************/
FUNCTION GetcanalREPORTE ( p_identidad    in entidades.identidad%type,
                           p_cdsucursal   in sucursales.cdsucursal%type)
                           RETURN VTEXCLIENTS.ID_CANAL%type IS

     v_id           clientescomisionistas.idcomisionista%type:=null;
     v_id2          clientescomisionistas.idcomisionista%type:=null;
     v_id3          clientescomisionistas.idcomisionista%type:=null;

 BEGIN
   --busco el comisionista que atiende al cliente
    select cc.idcomisionista
      into v_id
      from clientescomisionistas cc
     where cc.identidad = p_identidad;
     BEGIN
         select cv.idviajante
                  into v_id2
                  from clientesviajantesvendedores cv
                  --buscar los datos correspondientes al max(dthasta)
                 where cv.dthasta = (select max(cv2.dthasta)
                                       from clientesviajantesvendedores cv2)
                   and cv.identidad = p_identidad
                   and cv.cdsucursal = p_cdsucursal;
          --verifica si la identidad se encuentra en las dos tablas
          if v_id2 is not null then
            RETURN 'NO';
          else
            RETURN 'CO';
            end if;
     EXCEPTION
        WHEN TOO_MANY_ROWS THEN
             RETURN 'NO';
        WHEN NO_DATA_FOUND THEN
             --buscar el CANAl en telemarketing
             BEGIN
              select ct.idpersona
                into v_id3
                from clientestelemarketing ct
               where ct.identidad = p_identidad
                 and ct.cdsucursal = p_cdsucursal;
               --verifica si la identidad se encuentra en las 2 tablas
               if v_id3 is not null then
                  RETURN 'NO';  --agente registrado en comi y telemarketing
               else
                  RETURN 'TE';
               end if;
             EXCEPTION
               WHEN TOO_MANY_ROWS THEN
                    RETURN 'NO';
               WHEN OTHERS THEN
                    RETURN 'CO';
             END;
        WHEN OTHERS THEN
           RETURN 'CO';
     END;
 EXCEPTION
   WHEN TOO_MANY_ROWS THEN
       RETURN 'NO';
   WHEN NO_DATA_FOUND THEN
        BEGIN
            select cv.idviajante
              into v_id2
              from clientesviajantesvendedores cv
              --buscar los datos correspondientes al max(dthasta)
             where cv.dthasta = (select max(cv2.dthasta)
                                   from clientesviajantesvendedores cv2)
               and cv.identidad = p_identidad
               and cv.cdsucursal = p_cdsucursal;
               --buscar el CANAl en telemarketing
             BEGIN
              select ct.idpersona
                into v_id3
                from clientestelemarketing ct
               where ct.identidad = p_identidad
                 and ct.cdsucursal = p_cdsucursal;
               --verifica si la identidad se encuentra en las 2 tablas
               if v_id3 is not null then
                  RETURN 'NO';  --agente registrado en vendedor y telemarketing
               else
                  RETURN 'VE';
               end if;
             EXCEPTION
               WHEN TOO_MANY_ROWS THEN
                    RETURN 'NO';
               WHEN OTHERS THEN
                    RETURN 'VE';
             END;
        EXCEPTION
           WHEN TOO_MANY_ROWS THEN
             RETURN 'NO';
           WHEN NO_DATA_FOUND THEN
              --buscar el CANAl en telemarketing
             BEGIN
              select ct.idpersona
                into v_id3
                from clientestelemarketing ct
               where ct.identidad = p_identidad
                 and ct.cdsucursal = p_cdsucursal;
               RETURN 'TE';
             EXCEPTION
               WHEN OTHERS THEN
                    RETURN 'NO';
             END;
            WHEN OTHERS THEN
             RETURN 'NO';
        END;
   WHEN OTHERS THEN
         RETURN 'NO';
  END GetcanalREPORTE;

end PKG_CLD_DATOS;
/
