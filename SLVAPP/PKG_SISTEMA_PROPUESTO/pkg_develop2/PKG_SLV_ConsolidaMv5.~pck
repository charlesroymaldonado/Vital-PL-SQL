create or replace package PKG_SLV_ConsolidaM is
  /**********************************************************************************************************
  * Author  : CMALDONADO_C
  * Created : 20/01/2020 05:05:03 p.m.
  * %v Paquete para la consolidación de pedidos en SLV
  **********************************************************************************************************/
  -- Tipos de datos

  TYPE CURSOR_TYPE IS REF CURSOR;

  TYPE arr_IdentidadComi IS TABLE OF CHAR(40) INDEX BY PLS_INTEGER;

  TYPE arr_TransIdZona IS TABLE OF CHAR(55) INDEX BY PLS_INTEGER;

  TYPE arr_TransId IS TABLE OF VARCHAR2(50) INDEX BY PLS_INTEGER;

  --Procedimientos y Funciones
  PROCEDURE GetPedidosSinConsolidar(p_dthasta        IN DATE,
                                    p_idcanal        IN VARCHAR2,
                                    p_idcomisionista IN arr_IdentidadComi,
                                    p_cursor         OUT CURSOR_TYPE);

  PROCEDURE GetComisionistas(p_Cursor OUT CURSOR_TYPE);

  PROCEDURE GetPreVisualizarPedidos(p_QtBtoConsolidar IN NUMBER,
                                    p_TransId         IN arr_TransId,
                                    p_IdComisionista  IN arr_IdentidadComi,
                                    p_idPersona       IN personas.idpersona%type,
                                    p_Cursor          OUT CURSOR_TYPE);

  PROCEDURE GetDetallePedidos(p_TransId        IN pedidos.transid%type,
                              p_IdComisionista IN pedidos.idcomisionista%type,
                              p_Sucursal       OUT sucursales.dssucursal%type,
                              p_Cuit           OUT entidades.cdcuit%type,
                              p_RazonSocial    OUT entidades.dsrazonsocial%type,
                              p_Canal          OUT pedidos.id_canal%type,
                              p_AmTotal        OUT pedidos.ammonto%type,
                              p_Cursor         OUT CURSOR_TYPE);

  PROCEDURE GetZonaComisionistas(p_IdComisionista IN arr_IdentidadComi,
                                 p_Cursor         OUT CURSOR_TYPE);

  PROCEDURE SetZonaComisionistas(p_TransidZona IN arr_TransIdZona,
                                 p_Ok          OUT number,
                                 p_error       OUT varchar2);

  PROCEDURE SetConsolidadoMultiCanal(p_IdPersona IN personas.idpersona%type,
                                  p_Ok        OUT number,
                                  p_error     OUT varchar2);

end PKG_SLV_ConsolidaM;
/
create or replace package body PKG_SLV_ConsolidaM is
  /***************************************************************************************************
  *  %v 21/01/2020  ChM - Parametros globales privados
  ****************************************************************************************************/

  g_RolComisionista rolesentidades.cdrol%Type := getvlparametro('CdRolComisionista',
                                                                'General');
  g_cdSucursal      sucursales.cdsucursal%type := trim(getvlparametro('CDSucursal',
                                                                      'General'));
  c_qtDecimales   CONSTANT number := 2; -- cantidad de decimales para redondeo
  c_pedi_liberado CONSTANT pedidos.icestadosistema%type := 2;
  --fecha de pedidos segun paramentros del sistema para difinir fecha desde
  g_FechaPedidos date := SYSDATE -
                         To_Number(getVlParametro('DiasPedidos', 'General'));
  /**************************************************************************************************
  * Pedidos MultiCanal
  * %v 29/01/2020 - ChM. Versión Inicial
  ***************************************************************************************************/

  PROCEDURE GetPedidosMultiCanal(p_DtHasta        IN DATE,
                                 p_IdComisionista IN arr_IdentidadComi,
                                 p_Cursor         OUT CURSOR_TYPE) IS
  
    v_modulo varchar2(100) := 'PKG_SLVConsolidaM.GetPedidosMultiCanal';
    v_idcomi varchar2(3000);
  
  BEGIN
    --concatena en un string el arreglo de comisionistas
    v_idcomi := '''' || trim(p_idcomisionista(1)) || '''';
    FOR i IN 2 .. p_idcomisionista.count LOOP
      v_idcomi := v_idcomi || ',''' || trim(p_idcomisionista(i)) || '''';
    END LOOP;
    IF (v_idcomi IS NOT NULL) THEN
      OPEN p_cursor FOR
        SELECT pe.transid TRANSID, --devuelve todos los pedidos de reparto
               NULL IDCOMISIONISTA,
               pe.id_canal CANAL,
               trunc(pe.dtentrega) DTENTREGA,
               e.CDCUIT CUIT,
               e.dsrazonsocial RAZONSOCIAL,
               de.dscalle || ' ' || de.dsnumero || ' (' ||
               trim(de.cdcodigopostal) || ') ' || lo.dslocalidad || ' - ' ||
               pro.dsprovincia DIRECCION,
               round(SUM(pe.ammonto), c_qtDecimales) MONTO
          FROM pedidos              pe,
               documentos           do,
               direccionesentidades de,
               localidades          lo,
               provincias           pro,
               sucursales           su,
               entidades            e
         WHERE pe.iddoctrx = do.iddoctrx
           and do.identidadreal = e.identidad
           AND do.identidadreal = de.identidad
           AND pe.cdtipodireccion = de.cdtipodireccion
           AND pe.sqdireccion = de.sqdireccion
           and de.cdpais = pro.cdpais
           and de.cdprovincia = pro.cdprovincia
           and de.cdpais = lo.cdpais
           and de.cdprovincia = lo.cdprovincia
           AND de.cdlocalidad = lo.cdlocalidad
           AND do.cdsucursal = su.cdsucursal
           AND do.cdcomprobante = 'PEDI'
           AND pe.dtaplicacion >= g_FechaPedidos
           AND pe.dtentrega <= p_dthasta
           AND pe.icestadosistema = c_pedi_liberado
           AND pe.id_canal <> 'CO'
           AND pe.id_canal <> 'SA'
           AND nvl(pe.iczonafranca, 0) = 0
           AND pe.idcnpedido is null -- null para caja navideña
           AND do.cdsucursal = g_cdSucursal
         GROUP BY pe.transid,
                  e.CDCUIT,
                  pe.dtentrega,
                  pe.id_canal,
                  e.dsrazonsocial,
                  de.dscalle,
                  de.dsnumero,
                  de.cdcodigopostal,
                  lo.dslocalidad,
                  pro.dsprovincia
        UNION ALL
        SELECT NULL TRANSID, --devuelve todos los pedidos de comisionistas
               pe.idcomisionista IDCOMISIONISTA,
               pe.id_canal CANAL,
               trunc(SYSDATE) DTENTREGA,
               e.CDCUIT CUIT,
               e.dsrazonsocial RAZONSOCIAL,
               '-' DIRECCION,
               round(SUM(pe.ammonto), 2) MONTO
          FROM pedidos pe, documentos do, entidades e
         WHERE pe.iddoctrx = do.iddoctrx
           and pe.idcomisionista = e.identidad
           and do.cdcomprobante = 'PEDI'
           AND pe.icestadosistema = c_pedi_liberado
           and pe.id_canal = 'CO'
           and nvl(pe.iczonafranca, 0) = 0
           AND do.dtdocumento >= g_FechaPedidos
           and pe.idcnpedido is null
           and do.cdsucursal = g_cdSucursal
           AND trim(pe.idcomisionista) in
               (SELECT TRIM(SUBSTR(txt,
                                   INSTR(txt, ',', 1, level) + 1,
                                   INSTR(txt, ',', 1, level + 1) -
                                   INSTR(txt, ',', 1, level) - 1)) AS u
                  FROM (SELECT replace(',' || v_idcomi || ',', '''', '') AS txt
                          FROM dual)
                CONNECT BY level <=
                           LENGTH(txt) - LENGTH(REPLACE(txt, ',', '')) - 1) --convierte cadena con COMA (,) en tabla
         GROUP BY pe.idcomisionista,
                  e.CDCUIT,
                  trunc(SYSDATE),
                  pe.id_canal,
                  e.dsrazonsocial
         ORDER BY 4 DESC;
    
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       '  Error: ' || SQLERRM);
    
  END GetPedidosMultiCanal;

  /**************************************************************************************************
  * Pedidos de Reparto
  * %v 21/01/2020 - ChM. Versión Inicial
  * se filtra fecha desde-hasta con pedidos.dtentrega
  ***************************************************************************************************/
  PROCEDURE GetPedidosReparto(p_DtHasta IN DATE, p_Cursor OUT CURSOR_TYPE) IS
  
    v_modulo varchar2(100) := 'PKG_SLVConsolidaM.GetPedidosReparto';
  BEGIN
    OPEN p_cursor FOR
      SELECT pe.transid TRANSID, --devuelve todos los pedidos de reparto
             NULL IDCOMISIONISTA,
             pe.id_canal CANAL,
             trunc(pe.dtentrega) DTENTREGA,
             e.CDCUIT CUIT,
             e.dsrazonsocial RAZONSOCIAL,
             de.dscalle || ' ' || de.dsnumero || ' (' ||
             trim(de.cdcodigopostal) || ') ' || lo.dslocalidad || ' - ' ||
             pro.dsprovincia DIRECCION,
             round(SUM(pe.ammonto), c_qtDecimales) MONTO
        FROM pedidos              pe,
             documentos           do,
             direccionesentidades de,
             localidades          lo,
             provincias           pro,
             sucursales           su,
             entidades            e
       WHERE pe.iddoctrx = do.iddoctrx
         and do.identidadreal = e.identidad
         AND do.identidadreal = de.identidad
         AND pe.cdtipodireccion = de.cdtipodireccion
         AND pe.sqdireccion = de.sqdireccion
         and de.cdpais = pro.cdpais
         and de.cdprovincia = pro.cdprovincia
         and de.cdpais = lo.cdpais
         and de.cdprovincia = lo.cdprovincia
         AND de.cdlocalidad = lo.cdlocalidad
         AND do.cdsucursal = su.cdsucursal
         AND do.cdcomprobante = 'PEDI'
         AND pe.dtaplicacion >= g_FechaPedidos
         AND pe.dtentrega <= p_dthasta
         AND pe.icestadosistema = c_pedi_liberado
         AND pe.id_canal <> 'CO'
         AND pe.id_canal <> 'SA'
         AND nvl(pe.iczonafranca, 0) = 0
         AND pe.idcnpedido is null -- null para caja navideña
         AND do.cdsucursal = g_cdSucursal
       GROUP BY pe.transid,
                e.CDCUIT,
                pe.dtentrega,
                pe.id_canal,
                e.dsrazonsocial,
                de.dscalle,
                de.dsnumero,
                de.cdcodigopostal,
                lo.dslocalidad,
                pro.dsprovincia
       ORDER BY trunc(pe.dtentrega), pro.dsprovincia, lo.dslocalidad DESC;
  EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       '  Error: ' || SQLERRM);
  END GetPedidosReparto;

  /**************************************************************************************************
  * Pedidos de Comisionistas
  * %v 21/01/2020 - ChM. Versión Inicial
  * se filtra fecha del documentos.dtdocumento con g_FechaPedidos
  ***************************************************************************************************/

  PROCEDURE GetPedidosComisionistas(p_IdComisionista IN arr_IdentidadComi,
                                    p_Cursor         OUT CURSOR_TYPE) IS
  
    v_modulo varchar2(100) := 'PKG_SLVConsolidaM.GetPedidoscomisionistas';
    v_idcomi varchar2(3000);
  BEGIN
    v_idcomi := '''' || trim(p_idcomisionista(1)) || '''';
    FOR i IN 2 .. p_idcomisionista.count LOOP
      v_idcomi := v_idcomi || ',''' || trim(p_idcomisionista(i)) || '''';
    END LOOP;
    IF (v_idcomi IS NOT NULL) THEN
      OPEN p_cursor FOR
        SELECT NULL TRANSID, --devuelve todos los pedidos de comisionistas
               pe.idcomisionista IDCOMISIONISTA,
               pe.id_canal CANAL,
               trunc(SYSDATE) DTENTREGA,
               e.CDCUIT CUIT,
               e.dsrazonsocial RAZONSOCIAL,
               '-' DIRECCION,
               round(SUM(pe.ammonto), 2) MONTO
          FROM pedidos pe, documentos do, entidades e
         WHERE pe.iddoctrx = do.iddoctrx
           and pe.idcomisionista = e.identidad
           and do.cdcomprobante = 'PEDI'
           AND pe.icestadosistema = c_pedi_liberado
           and pe.id_canal = 'CO'
           and nvl(pe.iczonafranca, 0) = 0
           AND do.dtdocumento >= g_FechaPedidos
           and pe.idcnpedido is null
           and do.cdsucursal = g_cdSucursal
           AND trim(pe.idcomisionista) in
               (SELECT TRIM(SUBSTR(txt,
                                   INSTR(txt, ',', 1, level) + 1,
                                   INSTR(txt, ',', 1, level + 1) -
                                   INSTR(txt, ',', 1, level) - 1)) AS u
                  FROM (SELECT replace(',' || v_idcomi || ',', '''', '') AS txt
                          FROM dual)
                CONNECT BY level <=
                           LENGTH(txt) - LENGTH(REPLACE(txt, ',', '')) - 1)
         GROUP BY pe.idcomisionista,
                  e.CDCUIT,
                  trunc(SYSDATE),
                  pe.id_canal,
                  e.dsrazonsocial
         ORDER BY 4 DESC;
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       '  Error: ' || SQLERRM);
  END GetPedidoscomisionistas;

  /**************************************************************************************************
  * Armar grilla de pedidos para armar consolidados
  * %v 21/01/2020 - ChM. Versión Inicial
  ***************************************************************************************************/

  PROCEDURE GetPedidosSinConsolidar(p_DtHasta        IN DATE,
                                    p_IdCanal        IN VARCHAR2,
                                    p_IdComisionista IN arr_IdentidadComi,
                                    p_Cursor         OUT CURSOR_TYPE) IS
  
    v_modulo  varchar2(100) := 'PKG_SLVConsolidaM.GetPedidosSinConsolidar';
    v_dtHasta date;
  
  BEGIN
    v_dtHasta := to_date(to_char(p_DtHasta, 'dd/mm/yyyy') || ' 23:59:59',
                         'dd/mm/yyyy hh24:mi:ss');
  
    IF INSTR(p_idcanal, 'CO') <> 0 AND
       (INSTR(p_idcanal, 'VE') <> 0 OR INSTR(p_idcanal, 'TE') <> 0) THEN
      GetPedidosMultiCanal(v_dtHasta, p_IdComisionista, p_Cursor);
    ELSE
      IF INSTR(p_idcanal, 'CO') = 0 THEN
        GetPedidosReparto(v_dtHasta, p_Cursor);
      END IF;
      IF INSTR(p_idcanal, 'CO') <> 0 THEN
        GetPedidosComisionistas(p_idcomisionista, p_Cursor);
      END IF;
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       '  Error: ' || SQLERRM);
  END GetPedidosSinConsolidar;

  /****************************************************************************************************
  * %v 21/01/2020 - ChM  Versión inicial listado de comisionistas
  *****************************************************************************************************/

  PROCEDURE GetComisionistas(p_Cursor OUT CURSOR_TYPE) IS
  
    v_modulo varchar2(100) := 'PKG_SLVConsolidadoM.GetComisionistas';
  
  BEGIN
    OPEN p_Cursor FOR
    --comisionistas de la tabla tblinfocomisionista
    /*SELECT IDENT IdComisionista, CUIT || '- ' || RAZON RazonSocial
                FROM (SELECT DISTINCT e.identidad     IDENT,
                                      e.cdcuit        CUIT,
                                      e.dsrazonsocial RAZON
                        FROM entidades e, tblinfocomisionista co
                       WHERE e.identidad = co.idcomisionista
                         AND co.cdsucursal = g_cdSucursal 
                         AND e.cdmainsucursal = g_cdSucursal
                       ORDER BY 3);*/
    --Listado general con el rol comisionista               
      SELECT IDENT IdComisionista, CUIT || '- ' || RAZON RazonSocial
        FROM (SELECT DISTINCT e.identidad     IDENT,
                              e.cdcuit        CUIT,
                              e.dsrazonsocial RAZON
                FROM entidades e, rolesentidades r --,pedidos p
               WHERE e.cdestadooperativo = 'A'
                 AND TRIM(e.cdmaincanal) = 'VC'
                 AND e.cdmainsucursal = g_cdSucursal
                 AND R.IDENTIDAD = E.IDENTIDAD
                 AND r.CDROL = g_RolComisionista
              --AND p.idcomisionista=e.identidad --filtra solo con pedidos
               ORDER BY 3);
  EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       '  Error: ' || SQLERRM);
    
  END GetComisionistas;

  /****************************************************************************************************
  * %v 23/01/2020 - ChM  Versión inicial PreVisualizar pedidos a consolidar
  *****************************************************************************************************/
  PROCEDURE GetPreVisualizarPedidos(p_QtBtoConsolidar IN NUMBER,
                                    p_TransId         IN arr_TransId,
                                    p_IdComisionista  IN arr_IdentidadComi,
                                    p_idPersona       IN personas.idpersona%type,
                                    p_Cursor          OUT CURSOR_TYPE) IS
  
    v_modulo varchar2(100) := 'PKG_SLVConsolidadoM.GetPreVisualizarPedidos';
    v_error  varchar2(150);
  BEGIN
    v_error := 'Error al borrar persona: ' || p_idPersona;
    DELETE tbltmpslvConsolidadoM M where M.IDPERSONA = p_idPersona;
    IF (p_TransId(1) IS NOT NULL) THEN
      FOR i IN 1 .. p_TransId.Count LOOP
        v_error := 'Error al insertar tbltmpslvConsolidadoM TransId: ' ||
                   p_TransId(i);
        insert into tbltmpslvConsolidadoM --inserta en la tmp los posibles consolidados Multicanal
          select sys_guid(),
                 p_idPersona,
                 null comi,
                 P.canal,
                 p_QtBtoConsolidar bot,
                 P.transid,
                 null
            from (select distinct ped.id_canal canal, ped.transid transid
                    from pedidos ped
                   where ped.transid = p_TransId(i)) P;
      END LOOP;
    END IF;
    IF (p_IdComisionista(1) IS NOT NULL) THEN
      FOR i IN 1 .. p_IdComisionista.Count LOOP
        v_error := 'Error al insertar tbltmpslvConsolidadoM IdComisionista: ' ||
                   p_IdComisionista(i);
        insert into tbltmpslvConsolidadoM --inserta en la tmp los posibles consolidados Multicanal comisionistas
          select sys_guid(),
                 p_idPersona,
                 p_IdComisionista(i) comi,
                 P.canal,
                 p_QtBtoConsolidar bot,
                 P.transid,
                 null
            from (select distinct ped.id_canal canal, ped.transid transid
                    from pedidos ped, documentos do
                   where ped.iddoctrx = do.iddoctrx
                     and do.dtdocumento >= g_FechaPedidos
                     and ped.idcomisionista = p_IdComisionista(i)) P;
      END LOOP;
    END IF;
    IF (p_TransId(1) IS NOT NULL OR p_IdComisionista(1) IS NOT NULL) THEN
      v_error := 'Error cursor de pedidos a consolidar multicanal';
      OPEN P_Cursor FOR --cursor de pedidos a consolidar multicanal
        SELECT gs2.cdgrupo || ' - ' || gs2.dsgruposector || ' (' ||
               sec.dssector || ')' Sector,
               A.cod || '- ' || A.desc_art articulo,
               trunc((A.cant / A.uxb), 0) || ' BTO/ ' || mod(A.cant, A.uxb) || --divide las cantidades por bulto y unidad 
               ' UN' cantidad,
               trunc((A.stock / A.uxb), 0) || ' BTO/ ' ||
               mod(A.stock, A.uxb) || ' UN' stock,
               A.uxb,
               A.ubicacion
          FROM (select gs.cdsector SECTOR,
                       art.cdarticulo COD,
                       des.vldescripcion DESC_ART,
                       SUM(detped.qtunidadmedidabase) CANT,
                       PKG_SLV_Articulos.GetStockArticulos(art.cdarticulo) STOCK,
                       posapp.n_pkg_vitalpos_materiales.GetUxB(art.cdarticulo) UXB,
                       PKG_SLV_Articulos.GetUbicacionArticulos(ART.cdarticulo) UBICACION
                  from pedidos                ped,
                       documentos             docped,
                       detallepedidos         detped,
                       articulos              art,
                       descripcionesarticulos des,
                       tblslv_grupo_sector    gs,
                       tbltmpslvconsolidadom  mm
                 where ped.iddoctrx = docped.iddoctrx
                   and ped.idpedido = detped.idpedido
                   and art.cdarticulo = detped.cdarticulo
                   and ped.icestadosistema = c_pedi_liberado
                   and docped.cdsucursal = g_cdsucursal
                   and gs.cdsucursal = g_cdsucursal
                   and ped.transid = mm.transid
                   and mm.idpersona = p_idPersona 
                   and art.cdarticulo = des.cdarticulo
                   and trim(gs.cdsector) =
                       trim(decode(trim(art.cdidentificador),
                                   '01',
                                   '26',
                                   art.cdsector))
                   and gs.cdsucursal = g_cdsucursal
                 group by gs.cdsector, art.cdarticulo, des.vldescripcion
                 order by 1, 3) A,
               sectores sec,
               tblslv_grupo_sector gs2
         WHERE trunc((cant / uxb), 0) >= p_QtBtoConsolidar --mayor a bultos a consolidar
           AND A.sector = sec.cdsector
           AND sec.cdsector = gs2.cdsector
           AND gs2.cdsucursal = g_cdsucursal;
        COMMIT;                                            --commit si devuelve todos los datos   
      ELSE
        ROLLBACK;                                         --si no existe TransID o idComisionista rollback;
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       'Detalle Error: ' || v_error ||
                                       '  Error: ' || SQLERRM);
      ROLLBACK;
  END GetPreVisualizarPedidos;

  /****************************************************************************************************
  * %v 28/01/2020 - ChM  Versión inicial Detalle de pedidos de reparto o comisionista
  * %v devuelve un cursor con el detalle de articulos segun transid o idcomisionista
  *****************************************************************************************************/
  PROCEDURE GetDetallePedidos(p_TransId        IN pedidos.transid%type,
                              p_IdComisionista IN pedidos.idcomisionista%type,
                              p_Sucursal       OUT sucursales.dssucursal%type,
                              p_Cuit           OUT entidades.cdcuit%type,
                              p_RazonSocial    OUT entidades.dsrazonsocial%type,
                              p_Canal          OUT pedidos.id_canal%type,
                              p_AmTotal        OUT pedidos.ammonto%type,
                              p_Cursor         OUT CURSOR_TYPE) IS
  
    v_modulo varchar2(100) := 'PKG_SLVConsolidadoM.GetDetallePedidos';
    v_error  varchar2(150);
  BEGIN
    IF p_TransId IS NOT NULL THEN
      v_error := 'Error datos generales del pedido TransID: ' || p_TransId;
      select distinct su.dssucursal,
                      e.cdcuit,
                      e.dsrazonsocial,
                      ped.id_canal,
                      ped.Ammonto
        into p_Sucursal, p_Cuit, p_RazonSocial, p_Canal, p_AmTotal --datos generales del pedido
        from pedidos ped, documentos docped, entidades e, sucursales su
       where ped.iddoctrx = docped.iddoctrx
         and docped.cdsucursal = su.cdsucursal
         and docped.identidadreal = e.identidad
         and ped.transid = p_TransId
         AND ped.icestadosistema = c_pedi_liberado
         AND ped.id_canal <> 'CO'
         AND ped.id_canal <> 'SA'
         AND nvl(ped.iczonafranca, 0) = 0
         AND ped.idcnpedido is null
         AND docped.cdsucursal = g_cdSucursal;
      v_error := 'Error cursor de Articulos TransID: ' || p_TransId;
      OPEN P_Cursor FOR
        SELECT A.COD,
               A.DESC_ART,
               trunc((A.cant / A.uxb), 0) || ' BTO/ ' || mod(A.cant, A.uxb) ||
               ' UN' cantidad
          FROM (select art.cdarticulo COD, --detalle de los articulos de los pedidos
                       des.vldescripcion DESC_ART,
                       SUM(detped.qtunidadmedidabase) CANT,
                       posapp.n_pkg_vitalpos_materiales.GetUxB(art.cdarticulo) UXB
                  from pedidos                ped,
                       documentos             docped,
                       detallepedidos         detped,
                       articulos              art,
                       descripcionesarticulos des
                 where ped.iddoctrx = docped.iddoctrx
                   and ped.idpedido = detped.idpedido
                   and art.cdarticulo = detped.cdarticulo
                   and ped.transid = p_TransId
                   and art.cdarticulo = des.cdarticulo
                   and ped.icestadosistema = c_pedi_liberado
                   and ped.id_canal <> 'CO'
                   and ped.id_canal <> 'SA'
                   and nvl(ped.iczonafranca, 0) = 0
                   and ped.idcnpedido is null
                   and docped.cdsucursal = g_cdSucursal
                 group by art.cdarticulo, des.vldescripcion
                 order by 2) A;
    END IF;
    IF p_IdComisionista IS NOT NULL THEN
      v_error := 'Error datos generales del comisionista IdComisionista: ' ||
                 p_IdComisionista;
      select su.dssucursal,
             e.cdcuit CUIT,
             e.dsrazonsocial RAZONSOCIAL,
             ped.id_canal CANAL,
             sum(ped.Ammonto) ammonto
        into p_Sucursal, p_Cuit, p_RazonSocial, p_Canal, p_AmTotal --datos generales del comisionista
        from pedidos ped, documentos docped, entidades e, sucursales su
       where ped.iddoctrx = docped.iddoctrx
         and docped.cdsucursal = su.cdsucursal
         and ped.idcomisionista = e.identidad
         and ped.idcomisionista = p_IdComisionista
         and ped.icestadosistema = c_pedi_liberado
         and ped.id_canal = 'CO'
         and nvl(ped.iczonafranca, 0) = 0
         and ped.idcnpedido is null
         and docped.cdsucursal = g_cdSucursal
         and docped.dtdocumento >= g_FechaPedidos
       group by su.dssucursal, ped.id_canal, e.cdcuit, e.dsrazonsocial;
      v_error := 'Error cursor Articulos comisionista IdComisionista: ' ||
                 p_IdComisionista;
      OPEN P_Cursor FOR
        SELECT A.COD, --detalle de los articulos de los comisionistas
               A.DESC_ART,
               trunc((A.cant / A.uxb), 0) || ' BTO/ ' || mod(A.cant, A.uxb) ||
               ' UN' cantidad
          FROM (select art.cdarticulo COD,
                       des.vldescripcion DESC_ART,
                       SUM(detped.qtunidadmedidabase) CANT,
                       posapp.n_pkg_vitalpos_materiales.GetUxB(art.cdarticulo) UXB
                  from pedidos                ped,
                       documentos             docped,
                       detallepedidos         detped,
                       articulos              art,
                       descripcionesarticulos des
                 where ped.iddoctrx = docped.iddoctrx
                   and ped.idpedido = detped.idpedido
                   and art.cdarticulo = detped.cdarticulo
                   and ped.idcomisionista = p_IdComisionista
                   and art.cdarticulo = des.cdarticulo
                   AND ped.icestadosistema = c_pedi_liberado
                   AND ped.id_canal = 'CO'
                   AND nvl(ped.iczonafranca, 0) = 0
                   AND ped.idcnpedido is null
                   AND docped.cdsucursal = g_cdSucursal
                   AND docped.dtdocumento >= g_FechaPedidos
                 group by art.cdarticulo, des.vldescripcion
                 order by 2) A;
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       'Detalle del Error: ' || v_error ||
                                       '  Error: ' || SQLERRM);
  END GetDetallePedidos;
  /****************************************************************************************************
  * %v 27/01/2020 - ChM  Versión inicial GetZonaComisionistas
  * %v 27/01/2020 - ChM  lista los pedidos de comisionista para establecer zonas
  *****************************************************************************************************/
  PROCEDURE GetZonaComisionistas(p_IdComisionista IN arr_IdentidadComi,
                                 p_Cursor         OUT CURSOR_TYPE) IS
  
    v_modulo varchar2(100) := 'PKG_SLVConsolidaM.GetZonaComisionistas';
    v_error  varchar2(150);
    v_idcomi varchar2(3000);
  
  BEGIN
    v_error  := 'Error al procesar el arreglo de comisionistas';
    IF (p_IdComisionista(1) IS NOT NULL) THEN                      --valida null del arreglo
        v_idcomi := '''' || trim(p_idcomisionista(1)) || '''';
        FOR i IN 2 .. p_IdComisionista.count 
           LOOP
             v_idcomi := v_idcomi || ',''' || trim(p_idcomisionista(i)) || '''';
           END LOOP;
    ELSE
        v_idcomi := NULL;     
    END IF;      
    IF (v_idcomi IS NOT NULL) THEN
      v_error := 'Error en cursor Zonas por Comisionista';
      OPEN p_cursor FOR
        SELECT DISTINCT cm.transid TRANSID,
                        to_number(o.dsobservacion) NROORDEN,
                        ecomi.dsrazonsocial COMISIONISTA,
                        e.cdcuit CUIT,
                        e.dsrazonsocial RAZONSOCIAL,
                        de.dscalle || ' ' || de.dsnumero || ' (' ||
                        trim(de.cdcodigopostal) || ') ' || lo.dslocalidad ||
                        ' - ' || pro.dsprovincia DIRECCION,
                        trunc(pe.dtentrega) DTENTREGA
          FROM pedidos               pe,
               entidades             e,
               documentos            do,
               direccionesentidades  de,
               localidades           lo,
               provincias            pro,
               observacionespedido   o,
               tbltmpslvconsolidadom cm,         --zonas segun lo seleccionado en la temporal
               entidades             eComi
         WHERE pe.iddoctrx = do.iddoctrx
           AND pe.transid = cm.transid
           AND pe.idcomisionista = ecomi.identidad
           AND do.identidadreal = e.identidad
           AND do.identidadreal = de.identidad
           AND pe.cdtipodireccion = de.cdtipodireccion
           AND pe.sqdireccion = de.sqdireccion
           AND de.cdpais = pro.cdpais
           AND de.cdprovincia = pro.cdprovincia
           AND de.cdpais = lo.cdpais
           AND de.cdprovincia = lo.cdprovincia
           AND de.cdlocalidad = lo.cdlocalidad
           AND pe.idpedido = o.idpedido
           AND do.cdsucursal = g_cdSucursal
           AND trim(cm.idcomisionista) in
               (SELECT TRIM(SUBSTR(txt,
                                   INSTR(txt, ',', 1, level) + 1,
                                   INSTR(txt, ',', 1, level + 1) -
                                   INSTR(txt, ',', 1, level) - 1)) AS u
                  FROM (SELECT replace(',' || v_idcomi || ',', '''', '') AS txt
                          FROM dual)
                CONNECT BY level <=
                           LENGTH(txt) - LENGTH(REPLACE(txt, ',', '')) - 1)
         ORDER BY trunc(pe.dtentrega);
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       ' Detalle del error: ' || v_error ||
                                       '  Error: ' || SQLERRM);
  END GetZonaComisionistas;

  /****************************************************************************************************
  * %v 28/01/2020 - ChM  Versión inicial SetZonaComisionistas
  * %v 28/01/2020 - ChM  establece las zonas de los comisionistas por transId en la tbltmpslvconsolidadom
  *****************************************************************************************************/
  PROCEDURE SetZonaComisionistas(p_TransidZona IN arr_TransIdZona,
                                 p_Ok          OUT number,
                                 p_error       OUT varchar2) IS
  
    v_modulo  varchar2(100) := 'PKG_SLVConsolidaM.SetZonaComisionistas';
    v_error   varchar2(150);
    v_TransId pedidos.transid%type;
    v_Zona    tbltmpslvconsolidadom.grupo%type;
  
  BEGIN
    IF (p_TransIdZona(1) IS NOT NULL) THEN
      FOR i IN 1 .. p_TransIdZona.count LOOP
        v_TransId := trim(substr(P_TransIdZona(i), 1, 50));
        v_Zona    := to_number(substr(P_TransIdZona(i), 51, 2));
        v_error   := 'TransIDZona: ' || P_TransIdZona(i);
        UPDATE tbltmpslvconsolidadom M --actualiza la zona según comisionistas
           SET M.GRUPO = v_Zona
         WHERE M.TRANSID = v_TransId;
      END LOOP;
      COMMIT;
      p_Ok    := 1;
      p_error := null;
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       'Detalle Error: ' || v_error ||
                                       '  Error: ' || SQLERRM);
      p_Ok    := 0;
      p_error := 'Error Actualizando Grupo. Comuniquese con Sistemas!';
      ROLLBACK;
  END SetZonaComisionistas;
  /****************************************************************************************************
  * %v 31/01/2020 - ChM  Versión inicial SetPedidosConsolidarM
  * %v 04/02/2020 - ChM  inserta los consolidados previzualizados 
  *****************************************************************************************************/
  PROCEDURE SetConsolidadoMultiCanal(p_IdPersona IN personas.idpersona%type,
                                     p_Ok        OUT number,
                                     p_error     OUT varchar2) IS
    v_modulo          varchar2(100) := 'PKG_SLV_ConsolidaM.SetConsolidadoMultiCanal';
    v_error           varchar2(250);
    v_QtBtoConsolidar tbltmpslvconsolidadom.qtbtoconsolidar%type;
  BEGIN
    -- obtiene cantidad de bultos a consolidar del idpersona
    v_error := 'Error Select Cantidad Bultos a Consolidar';
    SELECT mm.qtbtoconsolidar
      INTO v_QtBtoConsolidar
      FROM tbltmpslvConsolidadoM MM
     WHERE MM.idpersona = p_idPersona
       AND ROWNUM = 1;
  
    -- maestro de consolidadom
    v_error := 'Falla insert tblslvconsolidadoM IdPesona: ' || p_IdPersona;
    INSERT INTO tblslvconsolidadoM
    VALUES
      (seq_consolidadom.nextval, 0, p_IdPersona, 1, SYSDATE, NULL);
  
    -- detalle de consolidadom con articulos de cantidad mayor a v_QtBtoConsolidar
    v_error := 'Falla insert tblslvconsolidadoMdet IdPesona: ' ||
               p_IdPersona;
    INSERT INTO tblslvconsolidadoMdet
      SELECT seq_consolidadomdet.nextval,
             seq_consolidadom.currval,
             A.COD,
             A.CANT,
             0                           qtpiezas,
             null                        qtundpicking,
             null                        qtpiezaspicking,
             gs.idgrupo_sector --Sector del Articulo
        FROM (select detped.cdarticulo COD,
                     SUM(detped.qtunidadmedidabase) CANT,
                     posapp.n_pkg_vitalpos_materiales.GetUxB(detped.cdarticulo) UXB
                from pedidos ped, documentos docped, detallepedidos detped
               where ped.iddoctrx = docped.iddoctrx
                 and ped.icestadosistema = c_pedi_liberado
                 and nvl(detped.qtpiezas, 0) = 0 --valida en el consolidado no pesables
                 and ped.idpedido = detped.idpedido
                 and nvl(ped.iczonafranca, 0) = 0 --valida zona franca
                 and ped.idcnpedido is null --valida cesta navideña
                 and detped.icresppromo <> 0 --valida que no sea promo
                 AND docped.cdsucursal = g_cdSucursal
                 and ped.transid in
                     (select mm.transid
                        from tbltmpslvConsolidadoM MM
                       where MM.idpersona = p_idPersona)
               group by detped.cdarticulo) A,
             articulos art,
             tblslv_grupo_sector gs
       where trunc((cant / uxb), 0) >= v_qtbtoconsolidar --mayor a bultos a consolidar
         and art.cdarticulo = a.cod
         and trim(gs.cdsector) =
             trim(decode(trim(art.cdidentificador),
                         '01',
                         '26',
                         art.cdsector))
         and gs.cdsucursal = g_cdsucursal;
    -- recorre todos los pedidos para reparto agrupados por cliente 
    v_error := 'Falla cursor de agrupar por cliente (IDENTIDAD) IdPesona: ' ||
               p_IdPersona;
    FOR PEDIDO IN (select p.identidad
                     from tbltmpslvconsolidadom m, pedidos p, documentos d
                    where m.transid = p.transid
                      and d.iddoctrx = p.iddoctrx
                      and d.identidadreal = p.identidad
                      and m.idpersona = p_idPersona
                      and m.idcomisionista is null
                      and m.idcanal <> 'CO'
                      and d.cdsucursal = g_cdSucursal
                    group by p.identidad)
    
     LOOP
      -- insert maestro de consolidadopedido de reparto
      v_error := 'Falla INSERT INTO tblslvconsolidadopedido IdPesona: ' ||
                 p_IdPersona || ' Cliente: ' || PEDIDO.IDENTIDAD;
      INSERT INTO tblslvconsolidadopedido
      VALUES
        (seq_consolidadopedido.nextval,
         PEDIDO.IDENTIDAD,
         10,
         seq_consolidadom.currval,
         p_IdPersona,
         NULL,
         SYSDATE,
         NULL);
    
      --insert de consolidadopedidorel en relacion con pedidoconsolidado de reparto 
      v_error := 'Falla INSERT INTO tblslvconsolidadopedidorel IdPesona: ' ||
                 p_IdPersona || ' Cliente: ' || PEDIDO.IDENTIDAD;
      INSERT INTO tblslvconsolidadopedidorel
        SELECT seq_consolidadopedidorel.nextval,
               A.IDPEDIDO,
               seq_consolidadopedido.currval
          FROM (select p.idpedido
                  from tbltmpslvconsolidadom m, pedidos p, documentos d
                 where m.transid = p.transid
                   and d.iddoctrx = p.iddoctrx
                   and d.identidadreal = p.identidad
                   and m.idpersona = p_idPersona
                   and d.cdsucursal = g_cdSucursal
                   and m.idcomisionista is null
                   and m.idcanal <> 'CO'
                 group by p.idpedido) A;
    
      -- insert detalle de consolidado pedido detalle de reparto   
      v_error := 'Falla INSERT INTO tblslvconsolidadopedidodet IdPesona: ' ||
                 p_IdPersona || ' Cliente: ' || PEDIDO.IDENTIDAD;
      INSERT INTO tblslvconsolidadopedidodet
        SELECT seq_consolidadopedidodet.nextval,
               seq_consolidadopedido.currval,
               A.COD,
               A.CANT,
               A.PIEZAS,
               null                             qtundpicking,
               null                             qtpiezaspicking,
               gs.idgrupo_sector --Sector del Articulo
          FROM (select detped.cdarticulo COD,
                       SUM(detped.qtunidadmedidabase) CANT,
                       SUM(nvl(detped.qtpiezas, 0)) PIEZAS
                  from pedidos ped, documentos docped, detallepedidos detped
                 where ped.iddoctrx = docped.iddoctrx
                   and ped.idpedido = detped.idpedido
                   and docped.identidadreal = ped.identidad
                   and ped.identidad = PEDIDO.identidad --valida identidad del cliente
                   and nvl(ped.iczonafranca, 0) = 0 --valida zona franca
                   and ped.idcnpedido is null --valida cesta navideña
                   and detped.icresppromo <> 0 --valida que no sea promo REVISAR LA MARCA DE ESPECIFICO
                   and ped.icestadosistema = c_pedi_liberado
                   and ped.id_canal <> 'CO'
                   and ped.idcomisionista is null
                   and docped.cdsucursal = g_cdSucursal
                   and ped.transid in
                       (select mm.transid
                          from tbltmpslvConsolidadoM MM
                         where MM.idpersona = p_idPersona
                           and MM.idcomisionista is null
                           and MM.idcanal <> 'CO')
                 group by detped.cdarticulo) A,
               articulos art,
               tblslv_grupo_sector gs
         where art.cdarticulo = a.cod
           and trim(gs.cdsector) =
               trim(decode(trim(art.cdidentificador),
                           '01',
                           '26',
                           art.cdsector))
           and gs.cdsucursal = g_cdsucursal;
    end loop; --loop clientes  reparto     
  
    --recorre los comisionistas por grupo o zona  en la tbltmpslvconsolidadom
    v_error := 'Falla cursor de agrupar por comisionista y Zona IdPesona: ' ||
               p_IdPersona;
    FOR COMI IN (select NVL(m.grupo, 0) grupo, m.idcomisionista
                   from tbltmpslvconsolidadom m
                  where m.idpersona = p_IdPersona
                    and m.idcomisionista is not null
                  group by m.grupo, m.idcomisionista) LOOP
      -- insert maestro de consolidado comisionista
      v_error := 'Falla INSERT INTO tblslvconsolidadocomi IdPesona: ' ||
                 p_IdPersona || ' Comisionista: ' || comi.idcomisionista;
      INSERT INTO tblslvconsolidadocomi
      VALUES
        (seq_consolidadocomi.nextval,
         seq_consolidadom.currval,
         COMI.GRUPO,
         p_IdPersona,
         25,
         SYSDATE,
         NULL);
    
      -- insert del detalle de consolidado comisionistas 
      v_error := 'Falla INSERT INTO tblslvconsolidadocomidet IdPesona: ' ||
                 p_IdPersona || ' Comisionista: ' || comi.idcomisionista;
      INSERT INTO tblslvconsolidadocomidet
        SELECT seq_consolidadocomidet.nextval,
               seq_consolidadocomi.currval,
               A.COD,
               A.CANT,
               A.PIEZAS,
               null                           qtundpicking,
               null                           qtpiezaspicking,
               gs.idgrupo_sector --Sector del Articulo
          FROM (select detped.cdarticulo COD,
                       SUM(detped.qtunidadmedidabase) CANT,
                       SUM(nvl(detped.qtpiezas, 0)) PIEZAS
                  from pedidos ped, documentos docped, detallepedidos detped
                 where ped.iddoctrx = docped.iddoctrx
                   and ped.idpedido = detped.idpedido
                   and nvl(ped.iczonafranca, 0) = 0 --valida zona franca
                   and ped.idcnpedido is null --valida cesta navideña
                   and detped.icresppromo <> 0 --valida que no sea promo REVISAR LA MARCA DE ESPECIFICO
                   AND ped.icestadosistema = c_pedi_liberado
                   AND ped.id_canal = 'CO'
                   AND docped.cdsucursal = g_cdSucursal
                   and ped.transid in
                       (select mm.transid
                          from tbltmpslvConsolidadoM MM
                         where MM.idpersona = p_idPersona
                           and MM.idcomisionista = COMI.idcomisionista
                           and MM.grupo = COMI.GRUPO)
                 group by detped.cdarticulo) A,
               articulos art,
               tblslv_grupo_sector gs
         where art.cdarticulo = a.cod
           and trim(gs.cdsector) =
               trim(decode(trim(art.cdidentificador),
                           '01',
                           '26',
                           art.cdsector))
           and gs.cdsucursal = g_cdsucursal;
    
      -- consolidadopedido del comisionista agrupado por cliente
      v_error := 'Falla cursor agrupar por comisionista y cliente IdPesona: ' ||
                 p_IdPersona || 'Comisionista: ' || comi.idcomisionista;
      FOR PEDIDOCOMI IN (select p.identidad
                           from tbltmpslvconsolidadom m,
                                pedidos               p,
                                documentos            d
                          where m.transid = p.transid
                            and d.iddoctrx = p.iddoctrx
                            and d.identidadreal = p.identidad
                            and d.cdsucursal = g_cdSucursal
                            and m.idpersona = p_idPersona
                            and m.idcomisionista = COMI.idcomisionista
                            and m.grupo = COMI.GRUPO
                          group by p.identidad) LOOP
        -- insert maestro de consolidadopedido por comisionista por cliente
        v_error := 'Falla INSERT INTO tblslvconsolidadopedido Cliente: ' ||
                   pedidocomi.identidad || ' Comisionista: ' ||
                   comi.idcomisionista;
        INSERT INTO tblslvconsolidadopedido
        VALUES
          (seq_consolidadopedido.nextval,
           PEDIDOCOMI.IDENTIDAD,
           10,
           NULL,
           p_IdPersona,
           seq_consolidadocomi.currval,
           SYSDATE,
           NULL);
      
        --insert de consolidadopedidorel en relacion con pedidoconsolidado comisionista 
        v_error := 'Falla INSERT INTO tblslvconsolidadopedidorel Cliente: ' ||
                   pedidocomi.identidad || ' Comisionista: ' ||
                   comi.idcomisionista;
        INSERT INTO tblslvconsolidadopedidorel
          SELECT seq_consolidadopedidorel.nextval,
                 A.idpedido,
                 seq_consolidadopedido.currval
            FROM (select p.idpedido
                    from tbltmpslvconsolidadom m, pedidos p, documentos d
                   where m.transid = p.transid
                     and d.iddoctrx = p.iddoctrx
                     and d.identidadreal = p.identidad
                     and d.cdsucursal = g_cdSucursal
                     and m.idpersona = p_idPersona
                     and m.idcomisionista = COMI.idcomisionista
                     and m.grupo = COMI.GRUPO
                   group by p.idpedido) A;
      
        -- insert detalle de consolidadopedidodetalle del comisionista por cliente  
        v_error := 'Falla INSERT INTO tblslvconsolidadopedidodet Cliente: ' ||
                   pedidocomi.identidad || ' Comisionista: ' ||
                   comi.idcomisionista;
        INSERT INTO tblslvconsolidadopedidodet
          SELECT seq_consolidadopedidodet.nextval,
                 seq_consolidadopedido.currval,
                 A.COD,
                 A.CANT,
                 A.PIEZAS,
                 null                             qtundpicking,
                 null                             qtpiezaspicking,
                 gs.idgrupo_sector --Sector del Articulo
            FROM (select detped.cdarticulo COD,
                         SUM(detped.qtunidadmedidabase) CANT,
                         SUM(nvl(detped.qtpiezas, 0)) PIEZAS
                    from pedidos        ped,
                         documentos     docped,
                         detallepedidos detped
                   where ped.iddoctrx = docped.iddoctrx
                     and ped.idpedido = detped.idpedido
                     and docped.identidadreal = ped.identidad
                     and ped.identidad = PEDIDOCOMI.identidad --valida identidad del cliente
                     and ped.idcomisionista = COMI.idcomisionista --valida comisionista del pedido 
                     and nvl(ped.iczonafranca, 0) = 0 --valida zona franca
                     and ped.idcnpedido is null --valida cesta navideña
                     and detped.icresppromo <> 0 --valida que no sea promo REVISAR LA MARCA DE ESPECIFICO
                     AND ped.icestadosistema = c_pedi_liberado
                     AND ped.id_canal = 'CO'
                     AND docped.cdsucursal = g_cdSucursal
                     and ped.transid in
                         (select mm.transid
                            from tbltmpslvConsolidadoM MM
                           where MM.idpersona = p_idPersona
                             and MM.idcomisionista = COMI.idcomisionista
                             and MM.grupo = COMI.GRUPO)
                   group by detped.cdarticulo) A,
                 articulos art,
                 tblslv_grupo_sector gs
           where art.cdarticulo = a.cod
             and trim(gs.cdsector) =
                 trim(decode(trim(art.cdidentificador),
                             '01',
                             '26',
                             art.cdsector))
             and gs.cdsucursal = g_cdsucursal;
      END LOOP; --loop clientes comisionistas            
    END LOOP; --loop comisionistas por grupo                      
    --elimino la temporal despues de crear los objetos de todos los tipos de pedido
    v_error := 'Falla DELETE tbltmpslvconsolidadom idPersona: ' ||
               p_IdPersona;
    DELETE tbltmpslvconsolidadom M WHERE M.IDPERSONA = p_IdPersona;
  
    p_Ok    := 1;
    p_error := null;
    COMMIT;
  EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       '  Detalle Error: ' || v_error ||
                                       '  Error: ' || SQLERRM);
      p_Ok    := 0;
      p_error := 'Imposible Realizar Consolidado. Comuniquese con Sistemas!';
      ROLLBACK;
  END SetConsolidadoMultiCanal;
end PKG_SLV_ConsolidaM;
/
