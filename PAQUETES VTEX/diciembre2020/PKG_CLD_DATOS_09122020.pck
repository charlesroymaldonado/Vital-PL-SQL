CREATE OR REPLACE PACKAGE PKG_CLD_DATOS is


  Procedure RefrescarClientesApp;
  PROCEDURE RefrescarPreciosVTEX (p_Fecha IN tblprecio.dtvigenciadesde%type);

end PKG_CLD_DATOS;
/
CREATE OR REPLACE PACKAGE BODY PKG_CLD_DATOS is

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
  
  /***************************************************************************************************
   * %v 04/12/2020 - ChM - Actualizó precios VTEX en GWV de la tabla VTEXPRICE 
   ***************************************************************************************************/
  PROCEDURE RefrescarPreciosVTEX (p_Fecha IN tblprecio.dtvigenciadesde%type) IS
    
      v_modulo       VARCHAR2(100) := 'PKG_CLD_DATOS.RefrescarPreciosVTEX';
      v_priceOF      tblprecio.amprecio%type:=null;
      v_pricepl      tblprecio.amprecio%type:=null;
      v_dtfromof     tblprecio.dtvigenciadesde%type:=null;
      v_dttoof       tblprecio.dtvigenciahasta%type:=null;
      
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
      
      -- Carga o actualiza los precios de los articulos de vtex que se agregaron en la fecha del parametro
      merge into vtexprice vp
      using ( --lista los articulos(SKU) en VTEX con precio de lista agregados en la fecha del parametro
              select p.cdarticulo,
                     p.cdsucursal,
                     p.id_canal,
                     p.amprecio  --OOOOOOOJOOOOOOOOOOOOO        ALTA AGREGAR IMPUESTO OOOOOOOOOOOOOOOJJJJJJJOOOOOOOOOOOOOOOOOO
                from tblprecio p,
                     vtexsku   vs 
               where p.cdarticulo = vs.refid
                 and p.id_precio_tipo = 'PL'
                 --solo canales de VTEX
                 and p.id_canal in (select distinct vs.id_canal
                              from vtexsellers vs 
                             where vs.cdsucursal<>'9999')
                  -- solo sucursales en VTEX
                  and p.cdsucursal in ( select distinct vs.cdsucursal 
                                 from vtexsellers vs 
                                where vs.cdsucursal<>'9999')
                 and p.dtvigenciadesde=p_fecha) lpc
      on (vp.refid = lpc.cdarticulo
          and vp.cdsucursal = lpc.cdsucursal
          and vp.id_canal = lpc.id_canal)
      when not matched then -- altas     
           insert(vp.cdsucursal,
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
          values (lpc.cdsucursal,
                  to_number(lpc.cdarticulo),
                  lpc.cdarticulo,                                
                  lpc.id_canal,
                  lpc.amprecio,
                  null,
                  null,
                  null,
                  SYSDATE,
                  null,                  
                  0,
                  null)     
      when matched then -- modificaciones
            update set  
                   vp.pricepl = lpc.amprecio,
                   vp.dtupdate = sysdate,
                   vp.icprocesado = 0;                  
   
 
      -- Actualiza los precios de oferta de los articulos de vtex que se agregaron en la fecha del parametro
      merge into vtexprice vp
      using ( --lista los articulos en VTEX con precio de oferta agregados en la fecha del parametro
              select p.cdarticulo,
                     p.cdsucursal,
                     p.id_canal,
                     p.dtvigenciadesde,
                     p.dtvigenciahasta,
                     p.amprecio  --OOOOOOOJOOOOOOOOOOOOO        ALTA AGREGAR IMPUESTO OOOOOOOOOOOOOOOJJJJJJJOOOOOOOOOOOOOOOOOO
                from tblprecio p,
                     vtexsku   vs 
               where p.cdarticulo = vs.refid
                 and p.id_precio_tipo = 'OF'
                 --solo canales de VTEX
                 and p.id_canal in (select distinct vs.id_canal
                              from vtexsellers vs 
                             where vs.cdsucursal<>'9999')
                  -- solo sucursales en VTEX
                  and p.cdsucursal in ( select distinct vs.cdsucursal 
                                 from vtexsellers vs 
                                where vs.cdsucursal<>'9999')
                 and p.dtvigenciadesde=p_fecha) lpc
      on (vp.refid = lpc.cdarticulo
          and vp.cdsucursal = lpc.cdsucursal
          and vp.id_canal = lpc.id_canal)
      when not matched then -- altas  de solo ofertas no debería existir nunca   
           insert(vp.cdsucursal,
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
          values (lpc.cdsucursal,
                  to_number(lpc.cdarticulo),
                  lpc.cdarticulo,                                
                  lpc.id_canal,
                  lpc.amprecio, --sino existe en VTEXPRICE se carga PL=OF
                  lpc.amprecio,
                  lpc.dtvigenciadesde,
                  lpc.dtvigenciahasta,
                  SYSDATE,
                  null,                  
                  0,
                  null)     
      when matched then -- modificaciones
            update set  
                   vp.priceof = lpc.amprecio,
                   vp.dtfromof = lpc.dtvigenciadesde,
                   vp.dttoof = lpc.dtvigenciahasta,
                   vp.dtupdate = sysdate,                    
                   vp.icprocesado = 0;  
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
  
  
  
end PKG_CLD_DATOS;
/
