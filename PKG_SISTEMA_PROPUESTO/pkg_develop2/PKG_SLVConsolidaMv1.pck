create or replace package PKG_SLVConsolidaM is
  /**********************************************************************************************************
  * Author  : CMALDONADO_C
  * Created : 20/01/2020 05:05:03 p.m.
  * %v Paquete para la consolidaci�n de pedidos en SLV
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

  PROCEDURE SetPedidosConsolidarM(p_IdPersona IN personas.idpersona%type,
                                  p_Ok        OUT number,
                                  p_error     OUT varchar2);

end PKG_SLVConsolidaM;
/
create or replace package body PKG_SLVConsolidaM is
  /***************************************************************************************************
  *  %v 21/01/2020  ChM - Parametros globales privados
  ****************************************************************************************************/

  g_RolComisionista rolesentidades.cdrol%Type := getvlparametro('CdRolComisionista',
                                                                'General');
  g_cdSucursal      sucursales.cdsucursal%type := trim(getvlparametro('CDSucursal',
                                                                      'General'));
  c_qtDecimales   CONSTANT number := 2; -- cantidad de decimales para redondeo
  c_pedi_liberado CONSTANT pedidos.icestadosistema%type := 2;
  g_FechaPedidos  date := SYSDATE -
                              To_Number(getVlParametro('DiasPedidos',
                                                       'General'));
                                                        --para prueba '20/10/2015';
  /**************************************************************************************************
  * Pedidos MultiCanal
  * %v 29/01/2020 - ChM. Versi�n Inicial
  ***************************************************************************************************/

  PROCEDURE GetPedidosMultiCanal(p_DtHasta        IN DATE,
                                 p_IdComisionista IN arr_IdentidadComi,
                                 p_Cursor         OUT CURSOR_TYPE) IS
  
    v_modulo varchar2(100) := 'PKG_SLVConsolidaM.GetPedidosMultiCanal';
    v_idcomi varchar2(3000);
  
  BEGIN
    v_idcomi := '''' || trim(p_idcomisionista(1)) || '''';
    FOR i IN 2 .. p_idcomisionista.count LOOP
      v_idcomi := v_idcomi || ',''' || trim(p_idcomisionista(i)) || '''';
    END LOOP;
    IF (v_idcomi IS NOT NULL) THEN
      OPEN p_cursor FOR
        SELECT pe.transid TRANSID,
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
           AND nvl(pe.iczonafranca, 0) = 0
           AND pe.idcnpedido is null -- null para caja navide�a
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
        SELECT NULL TRANSID,
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
  * %v 21/01/2020 - ChM. Versi�n Inicial
  * se filtra fecha desde-hasta con pedidos.dtentrega
  ***************************************************************************************************/
  PROCEDURE GetPedidosReparto(p_DtHasta IN DATE,
                              p_Cursor  OUT CURSOR_TYPE) IS
  
    v_modulo varchar2(100) := 'PKG_SLVConsolidaM.GetPedidosReparto';
  BEGIN
    OPEN p_cursor FOR
      SELECT pe.transid TRANSID,
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
         AND nvl(pe.iczonafranca, 0) = 0
         AND pe.idcnpedido is null -- null para caja navide�a
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
       ORDER BY trunc(pe.dtentrega), pro.dsprovincia, lo.dslocalidad;
  EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       '  Error: ' || SQLERRM);
  END GetPedidosReparto;

  /**************************************************************************************************
  * Pedidos de Comisionistas
  * %v 21/01/2020 - ChM. Versi�n Inicial
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
        SELECT NULL TRANSID,
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
  * %v 21/01/2020 - ChM. Versi�n Inicial
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
      GetPedidosMultiCanal(v_dtHasta,
                           p_IdComisionista,
                           p_Cursor);
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
  * %v 21/01/2020 - ChM  Versi�n inicial listado de comisionista
  *****************************************************************************************************/

  PROCEDURE GetComisionistas(p_Cursor OUT CURSOR_TYPE) IS
  
    v_modulo varchar2(100) := 'PKG_SLVConsolidadoM.GetComisionistas';
  
  BEGIN
    OPEN p_Cursor FOR
      SELECT IDENT IdComisionista, CUIT || '- ' || RAZON RazonSocial
        FROM (SELECT DISTINCT e.identidad     IDENT,
                              e.cdcuit        CUIT,
                              e.dsrazonsocial RAZON
                FROM entidades e, rolesentidades r --,pedidos p
               WHERE e.cdestadooperativo = 'A'
                 AND TRIM(e.cdmaincanal) = 'VC'
                 AND TRIM(e.cdmainsucursal) = TRIM(g_cdSucursal)
                 AND R.IDENTIDAD = E.IDENTIDAD
                 AND TRIM(r.CDROL) = TRIM(g_RolComisionista)
              --AND p.idcomisionista=e.identidad --filtra solo con pedidos
               ORDER BY 3);
  EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       '  Error: ' || SQLERRM);
    
  END GetComisionistas;

  /****************************************************************************************************
  * %v 23/01/2020 - ChM  Versi�n inicial PreVisualizar pedidos a consolidar
  *****************************************************************************************************/
  PROCEDURE GetPreVisualizarPedidos(p_QtBtoConsolidar IN NUMBER,
                                    p_TransId         IN arr_TransId,
                                    p_IdComisionista  IN arr_IdentidadComi,
                                    p_idPersona       IN personas.idpersona%type,
                                    p_Cursor          OUT CURSOR_TYPE) IS
  
    v_modulo varchar2(100) := 'PKG_SLVConsolidadoM.GetPreVisualizarPedidos';
  BEGIN
    DELETE tbltmpslvConsolidadoM M where M.IDPERSONA = p_idPersona;
  
    IF (p_TransId.count > 0) THEN
      FOR i IN 1 .. p_TransId.Count LOOP
        insert into tbltmpslvConsolidadoM --inserta en la tmp los posibles consolidados Multicanal
          select sys_guid(),
                 p_idPersona,
                 NULL comi,
                 P.canal,
                 p_QtBtoConsolidar bot,
                 P.transid,
                 null
            from (select distinct ped.id_canal canal, ped.transid transid
                    from pedidos ped
                   where ped.transid = p_TransId(i)) P;
      END LOOP;
      COMMIT;
    END IF;
    IF (p_IdComisionista.count > 0) THEN
      FOR i IN 1 .. p_IdComisionista.Count LOOP
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
      COMMIT;
    END IF;
    IF (p_IdComisionista.COUNT > 0 OR p_TransId.COUNT > 0) THEN
      OPEN P_Cursor FOR --cursor de pedidos a consolidar multicanal
        SELECT sector,
               cod || '- ' || desc_art articulo,
               trunc((cant / uxb), 0) || ' BTO/ ' || mod(cant, uxb) ||
               ' UN' cantidad,
               trunc((stock / uxb), 0) || ' BTO/ ' || mod(stock, uxb) ||
               ' UN' stock,
               uxb,
               ubicacion
          FROM (select art.cdsector SECTOR,
                       art.cdarticulo COD,
                       des.vldescripcion DESC_ART,
                       SUM(detped.qtunidadmedidabase) CANT,
                       PKG_SLVArticulos.GetStockArticulos(art.cdarticulo) STOCK,
                       posapp.n_pkg_vitalpos_materiales.GetUxB(art.cdarticulo) UXB,
                       PKG_SLVArticulos.GetUbicacionArticulos(ART.cdarticulo) UBICACION
                  from pedidos                ped,
                       documentos             docped,
                       detallepedidos         detped,
                       articulos              art,
                       descripcionesarticulos des
                 where ped.iddoctrx = docped.iddoctrx
                   and ped.idpedido = detped.idpedido
                   and art.cdarticulo = detped.cdarticulo
                   AND ped.icestadosistema = c_pedi_liberado
                   and ped.transid in
                       (select mm.transid
                          from tbltmpslvConsolidadoM MM
                         where MM.idpersona = p_idPersona)
                   and art.cdarticulo = des.cdarticulo
                 group by art.cdsector, art.cdarticulo, des.vldescripcion)
         WHERE trunc((cant / uxb), 0) >= p_QtBtoConsolidar --CANTIDAD MAXIMA DE BULTOS A CONSOLIDAR   
        ;
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       '  Error: ' || SQLERRM);
  END GetPreVisualizarPedidos;

  /****************************************************************************************************
  * %v 28/01/2020 - ChM  Versi�n inicial Detalle de pedidos de reparto o comisionista
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
  
  BEGIN
    IF p_TransId IS NOT NULL THEN
      select distinct su.dssucursal,
                      e.cdcuit,
                      e.dsrazonsocial,
                      ped.id_canal,
                      ped.Ammonto
        into p_Sucursal, p_Cuit, p_RazonSocial, p_Canal, p_AmTotal
        from pedidos ped, documentos docped, entidades e, sucursales su
       where ped.iddoctrx = docped.iddoctrx
         and docped.cdsucursal = su.cdsucursal
         and docped.identidadreal = e.identidad
         and ped.transid = p_TransId
         AND ped.icestadosistema = c_pedi_liberado
         AND ped.id_canal <> 'CO'
         AND nvl(ped.iczonafranca, 0) = 0
         AND ped.idcnpedido is null
         AND docped.cdsucursal = g_cdSucursal;
    
      OPEN P_Cursor FOR
        SELECT A.COD,
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
                   and ped.transid = p_TransId
                   and art.cdarticulo = des.cdarticulo
                   and ped.icestadosistema = c_pedi_liberado
                   and ped.id_canal <> 'CO'
                   and nvl(ped.iczonafranca, 0) = 0
                   and ped.idcnpedido is null
                   and docped.cdsucursal = g_cdSucursal
                 group by art.cdarticulo, des.vldescripcion) A;
    END IF;
    IF p_IdComisionista IS NOT NULL THEN
      select su.dssucursal,
             e.cdcuit CUIT,
             e.dsrazonsocial RAZONSOCIAL,
             ped.id_canal CANAL,
             sum(ped.Ammonto) ammonto
        into p_Sucursal, p_Cuit, p_RazonSocial, p_Canal, p_AmTotal
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
      OPEN P_Cursor FOR
        SELECT A.COD,
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
                 group by art.cdarticulo, des.vldescripcion) A;
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       '  Error: ' || SQLERRM);
  END GetDetallePedidos;
  /****************************************************************************************************
  * %v 27/01/2020 - ChM  Versi�n inicial GetZonaComisionistas
  * %v 27/01/2020 - ChM  lista los pedidos de comisionista para establecer zonas
  *****************************************************************************************************/
  PROCEDURE GetZonaComisionistas(p_IdComisionista IN arr_IdentidadComi,
                                 p_Cursor         OUT CURSOR_TYPE) IS
  
    v_modulo varchar2(100) := 'PKG_SLVConsolidaM.GetZonaComisionistas';
    v_idcomi varchar2(3000);
  
  BEGIN
    v_idcomi := '''' || trim(p_idcomisionista(1)) || '''';
    FOR i IN 2 .. p_IdComisionista.count LOOP
      v_idcomi := v_idcomi || ',''' || trim(p_idcomisionista(i)) || '''';
    END LOOP;
    IF (v_idcomi IS NOT NULL) THEN
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
               tbltmpslvconsolidadom cm,
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
                                       '  Error: ' || SQLERRM);
  END GetZonaComisionistas;

  /****************************************************************************************************
  * %v 28/01/2020 - ChM  Versi�n inicial SetZonaComisionistas
  * %v 28/01/2020 - ChM  establece las zonas de los comisionistas por transId en la tbltmpslvconsolidadom
  *****************************************************************************************************/
  PROCEDURE SetZonaComisionistas(p_TransidZona IN arr_TransIdZona,
                                 p_Ok          OUT number,
                                 p_error       OUT varchar2) IS
  
    v_modulo  varchar2(100) := 'PKG_SLVConsolidaM.SetZonaComisionistas';
    v_TransId pedidos.transid%type;
    v_Zona    tbltmpslvconsolidadom.grupo%type;
  
  BEGIN
    IF (p_TransIdZona.count > 0) THEN
      FOR i IN 1 .. p_TransIdZona.count LOOP
        v_TransId := trim(substr(P_TransIdZona(i), 1, 50));
        v_Zona    := to_number(substr(P_TransIdZona(i), 51, 2));
        UPDATE tbltmpslvconsolidadom M
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
                                       '  Error: ' || SQLERRM);
      p_Ok    := 0;
      p_error := 'No Update Error: ' || SQLERRM;
      ROLLBACK;
  END SetZonaComisionistas;
  /****************************************************************************************************
  * %v 31/01/2020 - ChM  Versi�n inicial SetPedidosConsolidarM
  * %v 04/02/2020 - ChM  inserta los consolidados previzualizados 
  *****************************************************************************************************/
  PROCEDURE SetPedidosConsolidarM(p_IdPersona IN personas.idpersona%type,
                                  p_Ok        OUT number,
                                  p_error     OUT varchar2) IS
    v_modulo          varchar2(100) := 'PKG_SLVConsolidaM.SetPedidosConsolidar';
    v_QtBtoConsolidar tbltmpslvconsolidadom.qtbtoconsolidar%type;
  BEGIN
    -- obtiene cantidad de bultos a consolidar del idpersona
    SELECT mm.qtbtoconsolidar
      INTO v_QtBtoConsolidar
      FROM tbltmpslvConsolidadoM MM
     WHERE MM.idpersona = p_idPersona
       AND ROWNUM = 1;
  
    -- maestro de consolidadom
    INSERT INTO tblslvconsolidadoM
    VALUES
      (seq_consolidadom.nextval, 0, p_IdPersona, 1, SYSDATE, NULL);
  
    -- detalle de consolidadom mayores a qtbultosconsolidar
    INSERT INTO tblslvconsolidadoMdet
      SELECT seq_consolidadomdet.nextval,
             seq_consolidadom.currval,
             A.COD,
             A.CANT,
             0                           QTPIEZAS,
             null                        qtundpicking,
             null                        qtpiezaspicking
        FROM (select detped.cdarticulo COD,
                     SUM(detped.qtunidadmedidabase) CANT,
                     posapp.n_pkg_vitalpos_materiales.GetUxB(detped.cdarticulo) UXB
                from pedidos ped, documentos docped, detallepedidos detped
               where ped.iddoctrx = docped.iddoctrx
                 and ped.icestadosistema = c_pedi_liberado
                 and nvl(detped.qtpiezas, 0) = 0 --valida en el consolidado no pesables
                 and ped.idpedido = detped.idpedido
                 and nvl(ped.iczonafranca, 0) = 0 --valida zona franca
                 and ped.idcnpedido is null --valida cesta navide�a
                 and detped.icresppromo <> 0 --valida que no sea promo
                 AND docped.cdsucursal = g_cdSucursal
                 and ped.transid in
                     (select mm.transid
                        from tbltmpslvConsolidadoM MM
                       where MM.idpersona = p_idPersona)
               group by detped.cdarticulo) A
       WHERE trunc((cant / uxb), 0) >= v_QtBtoConsolidar; --mayor a bultos a consolidar
  
    -- pedidos para reparto por cliente  
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
    
      -- insert detalle de consolidadopedidodetalle de reparto     
      INSERT INTO tblslvconsolidadopedidodet
        SELECT seq_consolidadopedidodet.nextval,
               seq_consolidadopedido.currval,
               A.COD,
               A.CANT,
               A.PIEZAS,
               null                             qtundpicking,
               null                             qtpiezaspicking
          FROM (select detped.cdarticulo COD,
                       SUM(detped.qtunidadmedidabase) CANT,
                       SUM(nvl(detped.qtpiezas, 0)) PIEZAS
                  from pedidos ped, documentos docped, detallepedidos detped
                 where ped.iddoctrx = docped.iddoctrx
                   and ped.idpedido = detped.idpedido
                   and docped.identidadreal = ped.identidad
                   and ped.identidad = PEDIDO.identidad --valida identidad del cliente
                   and nvl(ped.iczonafranca, 0) = 0 --valida zona franca
                   and ped.idcnpedido is null --valida cesta navide�a
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
                 group by detped.cdarticulo) A;
    END LOOP; --loop clientes  reparto     
  
    --comisionistas por grupo en la tbltmpslvconsolidadom
    FOR COMI IN (select NVL(m.grupo, 0) grupo, m.idcomisionista
                   from tbltmpslvconsolidadom m
                  where m.idpersona = p_IdPersona
                    and m.idcomisionista is not null
                  group by m.grupo, m.idcomisionista) LOOP
      -- insert maestro de consolidado comisionista
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
      INSERT INTO tblslvconsolidadocomidet
        SELECT seq_consolidadocomidet.nextval,
               seq_consolidadocomi.currval,
               A.COD,
               A.CANT,
               A.PIEZAS,
               null                           qtundpicking,
               null                           qtpiezaspicking
          FROM (select detped.cdarticulo COD,
                       SUM(detped.qtunidadmedidabase) CANT,
                       SUM(nvl(detped.qtpiezas, 0)) PIEZAS
                  from pedidos ped, documentos docped, detallepedidos detped
                 where ped.iddoctrx = docped.iddoctrx
                   and ped.idpedido = detped.idpedido
                   and nvl(ped.iczonafranca, 0) = 0 --valida zona franca
                   and ped.idcnpedido is null --valida cesta navide�a
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
                 group by detped.cdarticulo) A;
    
      -- consolidadopedido del comisionista agrupado por cliente
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
        -- insert maestro de consolidadopedido del comisionista
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
        INSERT INTO tblslvconsolidadopedidorel
          SELECT seq_consolidadopedidorel.nextval,
                 A.IDPEDIDO,
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
      
        -- insert detalle de consolidadopedidodetalle del comisionista       
        INSERT INTO tblslvconsolidadopedidodet
          SELECT seq_consolidadopedidodet.nextval,
                 seq_consolidadopedido.currval,
                 A.COD,
                 A.CANT,
                 A.PIEZAS,
                 null                             qtundpicking,
                 null                             qtpiezaspicking
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
                     and ped.idcnpedido is null --valida cesta navide�a
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
                   group by detped.cdarticulo) A;
      END LOOP; --loop clientes comisionistas            
    END LOOP; --loop comisionistas por grupo  
  
    --elimino la temporal despues de crear los objetos
    DELETE tbltmpslvconsolidadom M WHERE M.IDPERSONA = p_IdPersona;
  
    p_Ok    := 1;
    p_error := null;
    COMMIT;
  EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       '  Error: ' || SQLERRM);
      p_Ok    := 0;
      p_error := 'No INSERT Error: ' || SQLERRM;
      ROLLBACK;
  END SetPedidosConsolidarM;
end PKG_SLVConsolidaM;
/