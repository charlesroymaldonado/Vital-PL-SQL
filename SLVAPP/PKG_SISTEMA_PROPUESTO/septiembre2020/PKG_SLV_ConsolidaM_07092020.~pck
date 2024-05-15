CREATE OR REPLACE PACKAGE PKG_SLV_ConsolidaM is
  /**********************************************************************************************************
  * Author  : CHARLES ROY MALDONADO DUARTE
  * Created : 20/01/2020 05:05:03 p.m.
  * %v Paquete para la consolidación de pedidos en SLV
  **********************************************************************************************************/
  -- Tipos de datos

  TYPE CURSOR_TYPE IS REF CURSOR;

  TYPE arr_IdentidadComi IS TABLE OF CHAR(40) INDEX BY PLS_INTEGER;

  TYPE arr_TransIdZona IS TABLE OF VARCHAR(50) INDEX BY PLS_INTEGER;

  TYPE arr_TransId IS TABLE OF VARCHAR(50) INDEX BY PLS_INTEGER;
  
  TYPE arr_IdConsoPedido IS TABLE OF CHAR(14) INDEX BY PLS_INTEGER;
  
  --Procedimientos y Funciones
  PROCEDURE GetPedidosSinConsolidar(p_dthasta        IN DATE,
                                    p_idcanal        IN VARCHAR2,
                                    p_idcomisionista IN arr_IdentidadComi,
                                    p_cursor         OUT CURSOR_TYPE);

  PROCEDURE GetComisionistas(p_Cursor OUT CURSOR_TYPE);

  PROCEDURE GetPreVisualizarPedidos(p_QtBtoConsolidar IN  NUMBER,
                                    p_TransId         IN  arr_TransId,
                                    --p_IdComisionista  IN  arr_IdentidadComi,
                                    p_idPersona       IN  personas.idpersona%type,
                                    p_Ok              OUT number,
                                    p_error           OUT varchar2,
                                    p_Cursor          OUT CURSOR_TYPE);

  PROCEDURE GetDetallePedidos(p_TransId        IN pedidos.transid%type,
                             -- p_IdComisionista IN pedidos.idcomisionista%type,
                              p_Sucursal       OUT sucursales.dssucursal%type,
                              p_Cuit           OUT entidades.cdcuit%type,
                              p_RazonSocial    OUT entidades.dsrazonsocial%type,
                              p_Canal          OUT pedidos.id_canal%type,
                              p_AmTotal        OUT pedidos.ammonto%type,
                              p_Cursor         OUT CURSOR_TYPE);

  PROCEDURE GetZonaComisionistas(p_idPersona      IN personas.idpersona%type,
                                 p_Cursor         OUT CURSOR_TYPE);

  PROCEDURE SetZonaComisionistas(p_TransidZona IN arr_TransIdZona,
                                 p_Ok          OUT number,
                                 p_error       OUT varchar2);

  PROCEDURE SetConsolidadoMultiCanal(p_IdPersona        IN  personas.idpersona%type,
                                     p_IdConsolidadoM   OUT Tblslvconsolidadom.Idconsolidadom%type,
                                     p_Ok               OUT number,
                                     p_error            OUT varchar2);
                                     
 PROCEDURE SetConsolidadoPedidosFaltante(p_idpersona           IN  personas.idpersona%type,
                                         p_IdconsolidadoPedido IN  arr_IdConsoPedido,  
                                         p_IdPedFaltante       OUT Tblslvpedfaltante.Idpedfaltante%type,
                                         p_Ok                  OUT number,
                                         p_error               OUT varchar2);                                                                                                        



end PKG_SLV_ConsolidaM;
/
CREATE OR REPLACE PACKAGE BODY PKG_SLV_ConsolidaM is
  /***************************************************************************************************
  *  %v 21/01/2020  ChM - Parametros globales privados
  ****************************************************************************************************/

 -- g_RolComisionista rolesentidades.cdrol%Type := getvlparametro('CdRolComisionista','General');
  g_cdSucursal      sucursales.cdsucursal%type := trim(getvlparametro('CDSucursal','General'));
  c_qtDecimales     CONSTANT number := 2; -- cantidad de decimales para redondeo
  c_pedi_liberado   CONSTANT pedidos.icestadosistema%type := 2;
  --fecha de pedidos segun paramentros del sistema para difinir fecha desde
  g_FechaPedidos     date := SYSDATE -
                         To_Number(getVlParametro('DiasPedidos', 'General'));
                         
  C_CerradoConsolidadoPedido         CONSTANT tblslvestado.cdestado%type := 12;
  C_AFacturarConsolidadoPedido       CONSTANT tblslvestado.cdestado%type := 13;
  C_FacturadoConsolidadoPedido       CONSTANT tblslvestado.cdestado%type := 14;                       
  /**************************************************************************************************
  * Pedidos MultiCanal
  * %v 29/01/2020 - ChM. Versión Inicial
  * %v 16/06/2020 - LM   Se adapta para que devuelva todos los pedidos de CO
  ***************************************************************************************************/

  PROCEDURE GetPedidosMultiCanal(p_DtHasta        IN DATE,
                                 p_IdComisionista IN arr_IdentidadComi,
                                 p_Cursor         OUT CURSOR_TYPE) IS

    v_modulo varchar2(100) := 'PKG_SLV_ConsolidaM.GetPedidosMultiCanal';
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
               round(SUM(pe.ammonto), c_qtDecimales) MONTO,
               '-' COMISIONISTA,
               '-' ORDEN,
               0 FALTANTECOMI   
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
        --   AND do.cdsucursal = g_cdSucursal
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
            SELECT pe.transid TRANSID, --devuelve todos los pedidos de reparto
                 pe.idcomisionista IDCOMISIONISTA,
                 pe.id_canal CANAL,
                 trunc(pe.dtentrega) DTENTREGA,
                 e.CDCUIT CUIT,
                 e.dsrazonsocial RAZONSOCIAL,
                 de.dscalle || ' ' || de.dsnumero || ' (' ||
                 trim(de.cdcodigopostal) || ') ' || lo.dslocalidad || ' - ' ||
                 pro.dsprovincia DIRECCION,
                 round(SUM(pe.ammonto), 2) MONTO,
                 trim(ecomi.dsrazonsocial) || ' (' || trim(ecomi.cdcuit) || ')'  COMISIONISTA,
                 nvl(o.dsobservacion,'-') orden,
                 case
                 when PE.TRANSID like '%-PGF%' then 1 else 0 end FALTANTECOMI  
            FROM pedidos              pe,
                 documentos           do,
                 direccionesentidades de,
                 localidades          lo,
                 provincias           pro,
                 sucursales           su,
                 entidades            e,
                 entidades            eComi,
                 observacionespedido  o
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
             AND do.dtdocumento >= g_FechaPedidos
             AND pe.icestadosistema = c_pedi_liberado
             AND pe.id_canal = 'CO'
             AND pe.id_canal <> 'SA'
             AND pe.idcomisionista=ecomi.identidad
             and pe.idpedido=o.idpedido
             AND trim(pe.idcomisionista) in
                   (SELECT TRIM(SUBSTR(txt,
                                       INSTR(txt, ',', 1, level) + 1,
                                       INSTR(txt, ',', 1, level + 1) -
                                       INSTR(txt, ',', 1, level) - 1)) AS u
                      FROM (SELECT replace(',' || v_idcomi || ',', '''', '') AS txt
                              FROM dual)
                    CONNECT BY level <=
                               LENGTH(txt) - LENGTH(REPLACE(txt, ',', '')) - 1)
             AND nvl(pe.iczonafranca, 0) = 0
             AND pe.idcnpedido is null -- null para caja navideña
         --    AND do.cdsucursal = g_cdSucursal
           GROUP BY pe.transid,
                    pe.idcomisionista,
                    ecomi.dsrazonsocial,
                    ecomi.cdcuit,
                    e.CDCUIT,
                    pe.dtentrega,
                    pe.id_canal,
                    e.dsrazonsocial,
                    de.dscalle,
                    de.dsnumero,
                    de.cdcodigopostal,
                    lo.dslocalidad,
                    pro.dsprovincia,
                    o.dsobservacion  
           ORDER BY 4 DESC;
        /*SELECT NULL TRANSID, --devuelve todos los pedidos de comisionistas
               pe.idcomisionista IDCOMISIONISTA,
               pe.id_canal CANAL,
               trunc(SYSDATE) DTENTREGA,
               e.CDCUIT CUIT,
               e.dsrazonsocial RAZONSOCIAL,
               '-' DIRECCION,
               round(SUM(pe.ammonto), 2) MONTO
          FROM pedidos pe,
               documentos do,
               entidades e
         WHERE pe.iddoctrx = do.iddoctrx
           and pe.idcomisionista = e.identidad
           and do.cdcomprobante = 'PEDI'
           AND pe.icestadosistema = c_pedi_liberado
           and pe.id_canal = 'CO'
           and nvl(pe.iczonafranca, 0) = 0
           and pe.idcnpedido is null --valida cesta navideña
           AND do.dtdocumento >= g_FechaPedidos
           and pe.idcnpedido is null
        --   and do.cdsucursal = g_cdSucursal
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
         ORDER BY 4 DESC;*/

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
    * %v 16/06/2020 - LM   Se adapta para que devuelva todos los pedidos de CO
  ***************************************************************************************************/
  PROCEDURE GetPedidosReparto(p_DtHasta IN DATE, p_Cursor OUT CURSOR_TYPE) IS

    v_modulo varchar2(100) := 'PKG_SLV_ConsolidaM.GetPedidosReparto';
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
             round(SUM(pe.ammonto), c_qtDecimales) MONTO,
             '-' COMISIONISTA,
             '-' ORDEN,
             0 FALTANTECOMI  
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
     --    AND do.cdsucursal = g_cdSucursal
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
  * %v 16/06/2020 - LM   Se adapta para que devuelva todos los pedidos de CO
  ***************************************************************************************************/

  PROCEDURE GetPedidosComisionistas(p_IdComisionista IN arr_IdentidadComi,
                                    p_Cursor         OUT CURSOR_TYPE) IS

    v_modulo varchar2(100) := 'PKG_SLV_ConsolidaM.GetPedidoscomisionistas';
    v_idcomi varchar2(3000);
  BEGIN
    v_idcomi := '''' || trim(p_idcomisionista(1)) || '''';
    FOR i IN 2 .. p_idcomisionista.count LOOP
      v_idcomi := v_idcomi || ',''' || trim(p_idcomisionista(i)) || '''';
    END LOOP;
    IF (v_idcomi IS NOT NULL) THEN
      OPEN p_cursor FOR
           SELECT pe.transid TRANSID, --devuelve todos los pedidos de reparto
                 pe.idcomisionista IDCOMISIONISTA,
                 pe.id_canal CANAL,
                 trunc(pe.dtentrega) DTENTREGA,
                 e.CDCUIT CUIT,
                 e.dsrazonsocial RAZONSOCIAL,
                 de.dscalle || ' ' || de.dsnumero || ' (' ||
                 trim(de.cdcodigopostal) || ') ' || lo.dslocalidad || ' - ' ||
                 pro.dsprovincia DIRECCION,
                 round(SUM(pe.ammonto), 2) MONTO,
                 trim(ecomi.dsrazonsocial) || ' (' || trim(ecomi.cdcuit) || ')'  COMISIONISTA,
                 nvl(o.dsobservacion,'-') orden,
                 case
                 when PE.TRANSID like '%-PGF%' then 1 else 0 end FALTANTECOMI  
            FROM pedidos              pe,
                 documentos           do,
                 direccionesentidades de,
                 localidades          lo,
                 provincias           pro,
                 sucursales           su,
                 entidades            e,
                 entidades            eComi,
                 observacionespedido  o
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
             AND do.dtdocumento >= g_FechaPedidos
             AND pe.icestadosistema = c_pedi_liberado
             AND pe.id_canal = 'CO'
             AND pe.id_canal <> 'SA'
             AND pe.idcomisionista=ecomi.identidad
             and pe.idpedido=o.idpedido
             AND trim(pe.idcomisionista) in
                   (SELECT TRIM(SUBSTR(txt,
                           INSTR(txt, ',', 1, level) + 1,
                           INSTR(txt, ',', 1, level + 1) -
                           INSTR(txt, ',', 1, level) - 1)) AS u
                      FROM (SELECT replace(',' || v_idcomi || ',', '''', '') AS txt
                              FROM dual)
                    CONNECT BY level <=
                               LENGTH(txt) - LENGTH(REPLACE(txt, ',', '')) - 1)
             AND nvl(pe.iczonafranca, 0) = 0
             AND pe.idcnpedido is null -- null para caja navideña
         --    AND do.cdsucursal = g_cdSucursal
           GROUP BY pe.transid,
                    pe.idcomisionista,
                    ecomi.dsrazonsocial,
                    ecomi.cdcuit,
                    e.CDCUIT,
                    pe.dtentrega,
                    pe.id_canal,
                    e.dsrazonsocial,
                    de.dscalle,
                    de.dsnumero,
                    de.cdcodigopostal,
                    lo.dslocalidad,
                    pro.dsprovincia,
                    o.dsobservacion  
           ORDER BY trunc(pe.dtentrega), pro.dsprovincia, lo.dslocalidad DESC;
        /*SELECT NULL TRANSID, --devuelve todos los pedidos de comisionistas
               pe.idcomisionista IDCOMISIONISTA,
               pe.id_canal CANAL,
               trunc(SYSDATE) DTENTREGA,
               e.CDCUIT CUIT,
               e.dsrazonsocial RAZONSOCIAL,
               '-' DIRECCION,
               round(SUM(pe.ammonto), 2) MONTO
          FROM pedidos pe,
               documentos do,
               entidades e
         WHERE pe.iddoctrx = do.iddoctrx
           and pe.idcomisionista = e.identidad
           and do.cdcomprobante = 'PEDI'
           AND pe.icestadosistema = c_pedi_liberado
           and pe.id_canal = 'CO'
           and nvl(pe.iczonafranca, 0) = 0
           and pe.idcnpedido is null --valida cesta navideña
           AND do.dtdocumento >= g_FechaPedidos
           and pe.idcnpedido is null
          -- and do.cdsucursal = g_cdSucursal
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
         ORDER BY 4 DESC;*/
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

    v_modulo  varchar2(100) := 'PKG_SLV_ConsolidaM.GetPedidosSinConsolidar';
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

    v_modulo varchar2(100) := 'PKG_SLV_ConsolidaM.GetComisionistas';

  BEGIN
    OPEN p_Cursor FOR
    --comisionistas de la tabla tblinfocomisionista
    SELECT IDENT IdComisionista, CUIT || '- ' || RAZON RazonSocial
                FROM (SELECT DISTINCT e.identidad     IDENT,
                                      e.cdcuit        CUIT,
                                      e.dsrazonsocial RAZON
                        FROM entidades e, tblinfocomisionista co
                       WHERE e.identidad = co.idcomisionista
                         AND co.cdsucursal = g_cdSucursal
                       --  AND e.cdmainsucursal = g_cdSucursal
                       ORDER BY 3);
    --Listado general con el rol comisionista
/*      SELECT IDENT IdComisionista, CUIT || '- ' || RAZON RazonSocial
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
               ORDER BY 3);*/
  EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       '  Error: ' || SQLERRM);

  END GetComisionistas;
 /****************************************************************************************************
  * %v 05/03/2020 - ChM  Versión inicial VerificarBultosConsolidar
  *****************************************************************************************************/
  FUNCTION VerificarBultosConsolidar(p_QtBtoConsolidar NUMBER,
                                     p_idPersona       personas.idpersona%type)
                                     RETURN INTEGER IS
   v_modulo varchar2(100) := 'PKG_SLV_ConsolidaM.VerificarBultosConsolidar';  
   v_detalle     integer;
    BEGIN
         SELECT count(*)  
          INTO v_detalle
          FROM (select SUM(detped.qtunidadmedidabase) CANT,
                       detped.cdarticulo
                  from pedidos                ped,
                       detallepedidos         detped,          
                       tbltmpslvconsolidadom  mm
                 where ped.idpedido = detped.idpedido
                   and ped.icestadosistema = c_pedi_liberado             
                   and nvl(ped.iczonafranca, 0) = 0 --valida zona franca
                   and ped.idcnpedido is null --valida cesta navideña
                   and detped.icresppromo = 0 --valida que no sea promo             
                   --excluyo pesables
                   and (detped.qtpiezas is null or detped.qtpiezas<=0)              
                   and ped.transid = mm.transid
                   and mm.idpersona = p_idPersona                   
                 group by detped.cdarticulo) A                
         WHERE trunc(A.cant / (posapp.n_pkg_vitalpos_materiales.GetUxB(A.cdarticulo))) >= p_QtBtoConsolidar; --mayor a bultos a consolidar       
      return v_detalle;
      EXCEPTION
    WHEN NO_DATA_FOUND THEN
      return 0;
      WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||' Error: ' || SQLERRM);
      return 0;
      END VerificarBultosConsolidar;

  /****************************************************************************************************
  * %v 23/01/2020 - ChM  Versión inicial PreVisualizar pedidos a consolidar
  * %v 16/06/2020 - LM   se previsualiza por transid, ya no se unifica por comisionista
  *****************************************************************************************************/
  PROCEDURE GetPreVisualizarPedidos(p_QtBtoConsolidar IN  NUMBER,
                                    p_TransId         IN  arr_TransId,
                                    --p_IdComisionista  IN  arr_IdentidadComi,
                                    p_idPersona       IN  personas.idpersona%type,
                                    p_Ok              OUT number,
                                    p_error           OUT varchar2,
                                    p_Cursor          OUT CURSOR_TYPE) IS

    v_modulo varchar2(100) := 'PKG_SLV_ConsolidaM.GetPreVisualizarPedidos';
    v_error  varchar2(150);
  BEGIN
    v_error := 'Error al borrar persona: ' || p_idPersona;
    DELETE tbltmpslvConsolidadoM M where M.IDPERSONA = p_idPersona;

    IF (p_TransId(1) IS NOT NULL and LENGTH(TRIM(p_TransId(1)))>1) THEN
      FOR i IN 1 .. p_TransId.Count LOOP
        v_error := 'Error al insertar tbltmpslvConsolidadoM TransId: ' ||
                   p_TransId(i);
     insert into tbltmpslvConsolidadoM --inserta en la tmp los posibles consolidados Multicanal
                 (idtmpconsolidadom,
                 idpersona,
                 idcomisionista,
                 idcanal,
                 qtbtoconsolidar,
                 transid,
                 grupo)
          select sys_guid(),
                 p_idPersona,
                 p.idcomi,
                 P.canal,
                 p_QtBtoConsolidar bot,
                 P.transid,
                 null
            from (select ped.id_canal canal,
                         ped.transid transid,
                         ped.idcomisionista idcomi
                    from pedidos ped
                   where ped.transid = p_TransId(i)
                     and ped.dtaplicacion >= g_FechaPedidos
                     --and ped.id_canal <> 'CO'
                     and ped.icestadosistema = c_pedi_liberado
                     and rownum = 1) P;
        IF SQL%ROWCOUNT = 0  THEN      --valida insert de la tabla tbltmpslvConsolidadoM
           n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       ' Detalle Error: ' || v_error);
           p_Ok:=0;
           p_error:='Error no es Posible Vizualizar. Comuniquese con Sistemas!';
   	       ROLLBACK;
           RETURN;
        END IF;    
      END LOOP;
    END IF;

   /* IF (p_IdComisionista(1) IS NOT NULL and LENGTH(TRIM(p_IdComisionista(1)))>1) THEN
      FOR i IN 1 .. p_IdComisionista.Count LOOP
        v_error := 'Error al insertar tbltmpslvConsolidadoM IdComisionista: ' ||
                   p_IdComisionista(i);
        --inserta en la tmp los posibles consolidados Multicanal comisionistas
     insert into tbltmpslvConsolidadoM
                 (idtmpconsolidadom,
                 idpersona,
                 idcomisionista,
                 idcanal,
                 qtbtoconsolidar,
                 transid,
                 grupo)
          select sys_guid(),
                 p_idPersona,
                 p_IdComisionista(i) comi,
                 P.canal,
                 p_QtBtoConsolidar bot,
                 P.transid,
                 null
            from (select ped.id_canal canal,
                         ped.transid transid
                    from pedidos ped
                   where ped.dtaplicacion >= g_FechaPedidos
                     and ped.id_canal = 'CO'
                     and ped.icestadosistema = c_pedi_liberado
                     and ped.idcomisionista = rpad(p_IdComisionista(i),40,' ')
                     --and rownum = 1
                     ) P;
         --valida insert de la tabla tbltmpslvConsolidadoM
        IF SQL%ROWCOUNT = 0  THEN
           n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       ' Detalle Error: ' || v_error);
           p_Ok:=0;
           p_error:='Error no es Posible Vizualizar. Comuniquese con Sistemas!';
   	       ROLLBACK;   	
           RETURN;
        END IF;       
      END LOOP;
    END IF;*/
    IF (p_TransId(1) IS NOT NULL /*OR p_IdComisionista(1) IS NOT NULL*/) THEN
     --verifica si existen articulos para consolidar segun el numero de bultos
     if VerificarBultosConsolidar(p_QtBtoConsolidar,p_idPersona) = 0 then
         p_Ok:=0;
         p_error:='Error no Existen Artículos para Visualizar con Cantidad de Bultos Superior a: '||to_char(p_QtBtoConsolidar);
         rollback;
         return;
     end if;     
      v_error := 'Error cursor de pedidos a consolidar multicanal';
      OPEN P_Cursor FOR --cursor de pedidos a consolidar multicanal
       SELECT gs.cdgrupo || ' - ' || gs.dsgruposector || ' (' ||
               sec.dssector || ')' Sector,
               --codigo de barras 
               decode(A.basepza,0,
               PKG_SLV_ARTICULO.GetCodigoDeBarra(A.COD,'UN'),
               PKG_SLV_ARTICULO.GetCodigoDeBarra(A.COD,'KG')) barras,
               A.cod || '- ' || des.vldescripcion articulo,
               PKG_SLV_Articulo.SetFormatoArticulosCod(A.COD,
               --formato en piezas si es pesable  
               decode(A.basepza,0,A.cant,A.basepza))cantidad, 
               PKG_SLV_Articulo.SetFormatoArticulosCod(A.COD,PKG_SLV_Articulo.GetStockArticulos(A.COD)) stock,
               posapp.n_pkg_vitalpos_materiales.GetUxB(A.COD) UXB,
               PKG_SLV_Articulo.GetUbicacionArticulos(A.COD) UBICACION
          FROM (select detped.cdarticulo COD,                       
                       SUM(detped.qtunidadmedidabase) CANT,
                       SUM(detped.qtpiezas) basepza                            
                  from pedidos                ped,
                       detallepedidos         detped,                                                
                       tbltmpslvconsolidadom  mm
                 where ped.idpedido = detped.idpedido              
                   and ped.icestadosistema = '2'
                   and nvl(ped.iczonafranca, 0) = 0 --valida zona franca
                   and ped.idcnpedido is null --valida cesta navideña
                   and detped.icresppromo = 0 --valida que no sea promo
                   and ped.transid = mm.transid
                   and mm.idpersona = p_idPersona                 
                   --excluyo pesables
                   and (detped.qtpiezas is null or detped.qtpiezas<=0)
                 group by detped.cdarticulo) A,
               sectores sec,
               articulos art,
               descripcionesarticulos des, 
               tblslv_grupo_sector gs
         WHERE trunc(cant / posapp.n_pkg_vitalpos_materiales.GetUxB(A.COD), 0) >= p_QtBtoConsolidar --mayor a bultos a consolidar
           AND art.cdarticulo = A.cod  
           AND art.cdsector = sec.cdsector          
           AND sec.cdsector = gs.cdsector 
           AND art.cdarticulo = des.cdarticulo  
           and art.cdidentificador <>'01' --no se deben consolidar los especificos / SKU sensibles         
           AND gs.cdsucursal = g_cdsucursal;
         COMMIT;
         p_Ok    := 1;
         p_error := null; 
         commit;                                           --commit si devuelve todos los datos
      ELSE
        ROLLBACK;                                         --si no existe TransID o idComisionista rollback;
    END IF;
     --   n_pkg_vitalpos_log_general.write(2,'GetPreVisualizarPedidos FIN: '||sysdate);
  EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       'Detalle Error: ' || v_error ||
                                       '  Error: ' || SQLERRM);
      p_Ok:=0;
      p_error:='Error no es Posible Vizualizar. Comuniquese con Sistemas!';
      ROLLBACK;
  END GetPreVisualizarPedidos;

  /****************************************************************************************************
  * %v 28/01/2020 - ChM  Versión inicial Detalle de pedidos de reparto o comisionista
  * %v devuelve un cursor con el detalle de articulos segun transid o idcomisionista
  * %v 16/06/2020 - LM   devuelve el detalle de pedidos por transid de comi
  *****************************************************************************************************/
  PROCEDURE GetDetallePedidos(p_TransId        IN pedidos.transid%type,
                              --p_IdComisionista IN pedidos.idcomisionista%type,
                              p_Sucursal       OUT sucursales.dssucursal%type,
                              p_Cuit           OUT entidades.cdcuit%type,
                              p_RazonSocial    OUT entidades.dsrazonsocial%type,
                              p_Canal          OUT pedidos.id_canal%type,
                              p_AmTotal        OUT pedidos.ammonto%type,
                              p_Cursor         OUT CURSOR_TYPE) IS

    v_modulo varchar2(100) := 'PKG_SLV_ConsolidaM.GetDetallePedidos';
    v_error  varchar2(150);
  BEGIN
    --IF p_TransId IS NOT NULL THEN
      v_error := 'Error datos generales del pedido TransID: ' || p_TransId;
      select su.dssucursal,
             e.cdcuit,
             e.dsrazonsocial,
             ped.id_canal,
             sum(ped.Ammonto) Ammonto
        into p_Sucursal,
             p_Cuit,
             p_RazonSocial,
             p_Canal,
             p_AmTotal --datos generales del pedido
        from pedidos ped,
             documentos docped,
             entidades e,
             sucursales su
       where ped.iddoctrx = docped.iddoctrx
         and docped.cdsucursal = su.cdsucursal
         and docped.identidadreal = e.identidad
         and ped.transid = p_TransId
         and ped.icestadosistema = c_pedi_liberado
         --and ped.id_canal <> 'CO'
         and ped.id_canal <> 'SA'
         and nvl(ped.iczonafranca, 0) = 0
         and ped.idcnpedido is null
     --    and docped.cdsucursal = g_cdSucursal
    group by su.dssucursal,
             e.cdcuit,
             e.dsrazonsocial,
             ped.id_canal;
      v_error := 'Error cursor de Articulos TransID: ' || p_TransId;
      OPEN P_Cursor FOR
        SELECT A.COD,
               A.DESC_ART, 
               --codigo de barras 
               decode(A.CANTPZA,0,
               PKG_SLV_ARTICULO.GetCodigoDeBarra(A.COD,'UN'),
               PKG_SLV_ARTICULO.GetCodigoDeBarra(A.COD,'KG')) barras,                               
               PKG_SLV_Articulo.SetFormatoArticulosCod(A.COD,
               --formato en piezas si es pesable  
               decode(A.CANTPZA,0,A.cant,A.cantpza))cantidad        
          FROM (select art.cdarticulo COD, --detalle de los articulos de los pedidos
                       des.vldescripcion DESC_ART,
                       SUM(detped.qtunidadmedidabase) CANT,
                       SUM(nvl(detped.qtpiezas,0)) CANTPZA
                    --   posapp.n_pkg_vitalpos_materiales.GetUxB(art.cdarticulo) UXB
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
                   --and ped.id_canal <> 'CO'
                   and ped.id_canal <> 'SA'
                   and nvl(ped.iczonafranca, 0) = 0 --valida zona franca
                   and ped.idcnpedido is null --valida cesta navideña
                   and detped.icresppromo = 0 --valida que no sea promo                  
        --           and docped.cdsucursal = g_cdSucursal
              group by art.cdarticulo, 
                       des.vldescripcion
              order by des.vldescripcion) A;
  --  END IF;
  /*  IF p_IdComisionista IS NOT NULL THEN
      v_error := 'Error datos generales del comisionista IdComisionista: ' ||
                 p_IdComisionista;
      select su.dssucursal,
             e.cdcuit CUIT,
             e.dsrazonsocial RAZONSOCIAL,
             ped.id_canal CANAL,
             sum(ped.Ammonto) Ammonto
        into p_Sucursal,
             p_Cuit,
             p_RazonSocial,
             p_Canal,
             p_AmTotal --datos generales del comisionista
        from pedidos ped,
             documentos docped,
             entidades e,
             sucursales su
       where ped.iddoctrx = docped.iddoctrx
         and docped.cdsucursal = su.cdsucursal
         and ped.idcomisionista = e.identidad
         and ped.idcomisionista = p_IdComisionista
         and ped.icestadosistema = c_pedi_liberado
         and ped.id_canal = 'CO'
         and nvl(ped.iczonafranca, 0) = 0
         and ped.idcnpedido is null
      --   and docped.cdsucursal = g_cdSucursal
         and docped.dtdocumento >= g_FechaPedidos
    group by su.dssucursal, 
             ped.id_canal, 
             e.cdcuit, 
             e.dsrazonsocial;
      v_error := 'Error cursor Articulos comisionista IdComisionista: ' ||
                 p_IdComisionista;
      OPEN P_Cursor FOR
        SELECT A.COD, --detalle de los articulos de los comisionistas
               A.DESC_ART,
               --codigo de barras 
               decode(A.CANTPZA,0,
               PKG_SLV_ARTICULO.GetCodigoDeBarra(A.COD,'UN'),
               PKG_SLV_ARTICULO.GetCodigoDeBarra(A.COD,'KG')) barras,
               PKG_SLV_Articulo.SetFormatoArticulosCod(A.COD,
               --formato en piezas si es pesable  
               decode(A.CANTPZA,0,A.cant,A.cantpza)) Cantidad    
          FROM (select art.cdarticulo COD,
                       des.vldescripcion DESC_ART,
                       SUM(detped.qtunidadmedidabase) CANT,
                       SUM(detped.qtpiezas) CANTPZA
                    --   posapp.n_pkg_vitalpos_materiales.GetUxB(art.cdarticulo) UXB
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
                   and ped.icestadosistema = c_pedi_liberado
                   and ped.id_canal = 'CO'
                   and nvl(ped.iczonafranca, 0) = 0 --valida zona franca
                   and ped.idcnpedido is null --valida cesta navideña
                   and detped.icresppromo = 0 --valida que no sea promo
                --   and docped.cdsucursal = g_cdSucursal
                   and docped.dtdocumento >= g_FechaPedidos
              group by art.cdarticulo, des.vldescripcion
              order by des.vldescripcion) A;
    END IF;*/
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
  PROCEDURE GetZonaComisionistas(p_idPersona      IN personas.idpersona%type,
                                 p_Cursor         OUT CURSOR_TYPE) IS

    v_modulo varchar2(100) := 'PKG_SLV_ConsolidaM.GetZonaComisionistas';
    v_error  varchar2(150);

  BEGIN

    IF (p_idPersona IS NOT NULL) THEN
      v_error := 'Error en cursor Zonas por Comisionista';
      OPEN p_cursor FOR
        SELECT DISTINCT cm.transid TRANSID,
                        to_number(o.dsobservacion) NROORDEN,
                        ecomi.dsrazonsocial COMISIONISTA,
                        e.dsrazonsocial||' ('||trim(e.cdcuit)||')' RAZONSOCIAL,
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
           and nvl(pe.iczonafranca, 0) = 0 --valida zona franca
           and pe.idcnpedido is null --valida cesta navideña
           AND pe.cdtipodireccion = de.cdtipodireccion
           AND pe.sqdireccion = de.sqdireccion
           AND de.cdpais = pro.cdpais
           AND de.cdprovincia = pro.cdprovincia
           AND de.cdpais = lo.cdpais
           AND de.cdprovincia = lo.cdprovincia
           AND de.cdlocalidad = lo.cdlocalidad
           AND pe.idpedido = o.idpedido
        --   AND do.cdsucursal = g_cdSucursal
           AND pe.idcomisionista = cm.idcomisionista
           AND cm.idpersona=p_idPersona
           AND cm.idcanal = 'CO'
         ORDER BY ecomi.dsrazonsocial,
                  o.dsobservacion,
                  trunc(pe.dtentrega);
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

    v_modulo  varchar2(100) := 'PKG_SLV_ConsolidaM.SetZonaComisionistas';
    v_error   varchar2(150);
    v_TransId pedidos.transid%type;
    v_Zona    tbltmpslvconsolidadom.grupo%type;   

  BEGIN
    IF (p_TransIdZona(1) IS NOT NULL) THEN
      FOR i IN 1 .. p_TransIdZona.count LOOP
        v_TransId := trim(substr(P_TransIdZona(i), 1, (INSTR(P_TransIdZona(i),':')-1)));       
        v_Zona    := trunc(to_number(substr(P_TransIdZona(i), INSTR(P_TransIdZona(i),':')+1, LENGTH(P_TransIdZona(i)))));
        v_error   := 'TransIDZona: ' || P_TransIdZona(i);

        UPDATE tbltmpslvconsolidadom M --actualiza la zona según comisionistas
           SET M.GRUPO = v_Zona
         WHERE trim(M.TRANSID) = v_TransId;

     IF  SQL%ROWCOUNT = 0  THEN      --valida update de zona
   	  p_Ok    := 0;
      p_error := 'Error Actualizando Grupo. Comuniquese con Sistemas!';
      ROLLBACK;
      RETURN;
    END IF;
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
  * %V 14/05/2020 - ChM  Agrego QTBTOCONSOLIDAR
  *****************************************************************************************************/
  PROCEDURE SetConsolidadoMultiCanal(p_IdPersona        IN  personas.idpersona%type,
                                     p_IdConsolidadoM   OUT Tblslvconsolidadom.Idconsolidadom%type,
                                     p_Ok               OUT number,
                                     p_error            OUT varchar2) IS
    v_modulo          varchar2(100) := 'PKG_SLV_ConsolidaM.SetConsolidadoMultiCanal';
    v_error           varchar2(250);
    v_QtBtoConsolidar tbltmpslvconsolidadom.qtbtoconsolidar%type;
    v_grupo           number :=0;
    v_sqCP            integer;
  BEGIN

    SELECT COUNT(*)
      INTO v_grupo
      FROM tbltmpslvConsolidadoM MM
     WHERE MM.idpersona = p_idPersona
       AND MM.idcanal = 'CO'
       AND MM.GRUPO IS NULL;

   IF v_grupo <> 0  THEN      --valida grupos de comisionistas en NULL
     p_Ok:=0;
     p_error:='Error faltan zonas por asignar en comisionistas!';
     return;
   END IF;

    -- obtiene cantidad de bultos a consolidar del idpersona
    v_error := 'Error Select Cantidad Bultos a Consolidar';
    SELECT mm.qtbtoconsolidar
      INTO v_QtBtoConsolidar
      FROM tbltmpslvConsolidadoM MM
     WHERE MM.idpersona = p_idPersona
       AND ROWNUM = 1;

    IF v_QtBtoConsolidar < 0  THEN      --valida bultos a consolidar
     p_Ok:=0;
     p_error:='Error Imposible Consolidar Bultos menor a cero. Comuniquese con Sistemas! ';
     return;
    END IF;
    n_pkg_vitalpos_log_general.write(2, 'Modulo: ' || v_modulo ||
                                     ' Inicia proceso maestro detalle: pedidos multicanal ');
    -- maestro de consolidadom
    v_error := 'Falla insert tblslvconsolidadoM IdPersona: ' || p_IdPersona;
    INSERT INTO tblslvconsolidadoM
    (idconsolidadom,qtconsolidado,idpersona,cdestado,dtinsert,dtupdate,Cdsucursal)
    VALUES
      (seq_consolidadom.nextval, v_QtBtoConsolidar, p_IdPersona, 1, SYSDATE, NULL,g_cdSucursal);

    -- IdConsolidadoM para el parametro de salida p_IdConsolidadoM
    select seq_consolidadom.currval
      into p_IdConsolidadoM from dual;

    -- insert del detalle de consolidadom con articulos de cantidad mayor a v_QtBtoConsolidar
    v_error := 'Falla insert tblslvconsolidadoMdet IdPersona: ' ||
               p_IdPersona;
    INSERT INTO tblslvconsolidadoMdet
                (idconsolidadomdet,
                idconsolidadom,
                cdarticulo,
                qtunidadmedidabase,
                qtpiezas,
                qtunidadmedidabasepicking,
                qtpiezaspicking,
                idgrupo_sector,
                Cdsucursal)
      SELECT seq_consolidadomdet.nextval,
             seq_consolidadom.currval,
             A.COD,
             A.CANT,
             0                           qtpiezas,
             null                        qtundpicking,
             null                        qtpiezaspicking,
             gs.idgrupo_sector, --Sector del Articulo,
             g_cdSucursal
        FROM (select detped.cdarticulo COD,
                     SUM(detped.qtunidadmedidabase) CANT,
                     posapp.n_pkg_vitalpos_materiales.GetUxB(detped.cdarticulo) UXB
                from pedidos ped,
                     detallepedidos detped,
                     tbltmpslvConsolidadoM mm
               where ped.icestadosistema = c_pedi_liberado                
                 and ped.idpedido = detped.idpedido
                 and nvl(ped.iczonafranca, 0) = 0 --valida zona franca
                 and ped.idcnpedido is null --valida cesta navideña
                 and detped.icresppromo = 0 --valida que no sea promo
                 and ped.transid = mm.transid
                 and mm.idpersona = p_idPersona
                 --excluyo pesables
                 and (detped.qtpiezas is null or detped.qtpiezas<=0)
               group by detped.cdarticulo) A,
             articulos art,
             tblslv_grupo_sector gs
       WHERE trunc((cant / uxb), 0) >= v_qtbtoconsolidar --mayor a bultos a consolidar
         AND art.cdarticulo = a.cod
         AND art.cdidentificador <>'01' --no se deben consolidar los especificos / SKU sensibles
         AND trim(gs.cdsector) =trim(art.cdsector)
         AND gs.cdsucursal = g_cdsucursal;

    IF  SQL%ROWCOUNT = 0  THEN      --valida insert tblslvconsolidadoMdet
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       '  Detalle Error: ' || v_error);
   	  p_Ok:=0;
      p_error:='Error en Consolidar. Comuniquese con Sistemas!';
      ROLLBACK;
      RETURN;
    END IF;
    n_pkg_vitalpos_log_general.write(2, 'Modulo: ' || v_modulo ||
                                     ' Finaliza proceso maestro detalle: pedidos multicanal  ');
    n_pkg_vitalpos_log_general.write(2, 'Modulo: ' || v_modulo ||
                                     ' Inicia proceso maestro detalle: pedidos de reparto  ');                                 
    -- recorre todos los pedidos para reparto agrupados por cliente
    v_error := 'Falla cursor de agrupar por cliente (IDENTIDAD) IdPersona: ' ||
               p_IdPersona;
    FOR PEDIDO IN (select d.identidadreal,
                          p.id_canal,
                          trunc(p.dtaplicacion) dtaplicacion,
                          p.cdtipodireccion,
                          p.sqdireccion,
                          LISTAGG(p.idpedido, ''',''') WITHIN GROUP (ORDER BY p.idpedido) idpedido    
                     from tbltmpslvconsolidadom m,
                          pedidos p,
                          documentos d
                    where m.transid = p.transid
                      and d.iddoctrx = p.iddoctrx
                     -- and d.identidadreal = p.identidad
                      and m.idpersona = p_idPersona
                      and m.idcomisionista is null
                      and m.idcanal <> 'CO'
                   --   and d.cdsucursal = g_cdSucursal
                    group by d.identidadreal,
                             p.id_canal,                             
                             trunc(p.dtaplicacion),
                             p.cdtipodireccion,
                             p.sqdireccion)

     LOOP
       --agrega comillas en la cadena agrupada
       PEDIDO.IDPEDIDO:=''''||PEDIDO.IDPEDIDO||'''';
      -- insert maestro de consolidadopedido de reparto
      v_error := 'Falla INSERT tblslvconsolidadopedido IdPersona: ' ||
                 p_IdPersona || ' Cliente: ' || PEDIDO.identidadreal;
      INSERT INTO tblslvconsolidadopedido
                  (idconsolidadopedido,
                  identidad,
                  cdestado,
                  idconsolidadom,
                  idpersona,
                  idconsolidadocomi,
                  dtinsert,
                  dtupdate,
                  id_canal,
                  cdsucursal)
           VALUES
                  (seq_consolidadopedido.nextval,
                  PEDIDO.identidadreal,
                  10,
                  seq_consolidadom.currval,
                  p_IdPersona,
                  NULL,
                  SYSDATE,
                  NULL,
                  PEDIDO.id_canal,
                  g_cdSucursal);
     IF SQL%ROWCOUNT = 0  THEN      --valida insert tblslvconsolidadopedido
        n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       '  Detalle Error: ' || v_error);
   	    p_Ok:=0;
        p_error:='Error en Consolidar. Comuniquese con Sistemas!';
        ROLLBACK;
        RETURN;
      END IF;  
      v_sqCP:=seq_consolidadopedido.currval;           
      --insert de consolidadopedidorel en relacion con pedidoconsolidado de reparto
      v_error := 'Falla INSERT tblslvconsolidadopedidorel IdPersona: ' ||
                 p_IdPersona || ' Cliente: ' || PEDIDO.identidadreal;
      INSERT INTO tblslvconsolidadopedidorel
                  (idconsolidadopedidorel,
                  idpedido,
                  idconsolidadopedido,
                  cdsucursal)
           SELECT seq_consolidadopedidorel.nextval,
                  A.IDPEDIDO,
                  v_sqCP,
                  g_cdSucursal
                   -- lista los pedidos agrupados en PEDIDO.IDPEDIDO para el insert en pedidorel
             FROM ( SELECT SUBSTR(txt,
                           INSTR(txt, ',', 1, level) + 1,
                           INSTR(txt, ',', 1, level + 1) -
                           INSTR(txt, ',', 1, level) - 1) AS IDPEDIDO
                      FROM (SELECT replace(',' || PEDIDO.IDPEDIDO || ',', '''', '') AS txt
                              FROM dual)
                CONNECT BY level <=
                           LENGTH(txt) - LENGTH(REPLACE(txt, ',', '')) - 1) A; 
     IF SQL%ROWCOUNT = 0  THEN      --valida insert tblslvconsolidadopedidorel
        n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       '  Detalle Error: ' || v_error);
   	    p_Ok:=0;
        p_error:='Error en Consolidar. Comuniquese con Sistemas!';
        ROLLBACK;
        RETURN;
      END IF;

      -- insert detalle de consolidado pedido detalle de reparto
      v_error := 'Falla INSERT tblslvconsolidadopedidodet IdPersona: ' ||
                 p_IdPersona || ' Cliente: ' || PEDIDO.identidadreal;
      INSERT INTO tblslvconsolidadopedidodet
                  (idconsolidadopedidodet,
                  idconsolidadopedido,
                  cdarticulo,
                  qtunidadesmedidabase,
                  qtpiezas,
                  qtunidadmedidabasepicking,
                  qtpiezaspicking,
                  idgrupo_sector,
                  cdsucursal)
        SELECT seq_consolidadopedidodet.nextval,
               v_sqCP,
               A.COD,
               A.CANT,
               A.PIEZAS,
               null                             qtundpicking,
               null                             qtpiezaspicking,
               gs.idgrupo_sector,                --Sector del Articulo
               g_cdSucursal
          FROM (select detped.cdarticulo COD,
                       SUM(detped.qtunidadmedidabase) CANT,
                       SUM(nvl(detped.qtpiezas, 0)) PIEZAS
                  from detallepedidos               detped,                       
                       tblslvconsolidadopedidorel   prel
                 where detped.idpedido = prel.idpedido
                   and detped.icresppromo = 0 --valida que no sea promo
                   and prel.idconsolidadopedido = v_sqCP -- todos los pedidos de prel que componen el conso pedido
                 group by detped.cdarticulo) A,
               articulos art,
               tblslv_grupo_sector gs
         WHERE art.cdarticulo = a.cod
           AND trim(gs.cdsector) =
               trim(decode(trim(art.cdidentificador),
                           '01',
                           '26',
                           art.cdsector))
           AND gs.cdsucursal = g_cdsucursal;

     IF SQL%ROWCOUNT = 0  THEN      --valida insert tblslvconsolidadopedidodet
        n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       '  Detalle Error: ' || v_error);
   	    p_Ok:=0;
        p_error:='Error en Consolidar. Comuniquese con Sistemas!';
        ROLLBACK;
        RETURN;
      END IF;

    END LOOP; --loop clientes  reparto
    n_pkg_vitalpos_log_general.write(2, 'Modulo: ' || v_modulo ||
                                     ' Finaliza proceso maestro detalle: pedidos de reparto  '); 
                                     
    n_pkg_vitalpos_log_general.write(2, 'Modulo: ' || v_modulo ||
                                     ' Inicia proceso maestro detalle: pedidos de Comisionistas  ');                                        
    --recorre los comisionistas por grupo o zona  en la tbltmpslvconsolidadom
    v_error := 'Falla cursor de agrupar por comisionista y Zona IdPersona: ' ||
               p_IdPersona;
    FOR COMI IN (select NVL(m.grupo, 0) grupo, 
                        m.idcomisionista
                   from tbltmpslvconsolidadom m
                  where m.idpersona = p_IdPersona
                    and m.idcomisionista is not null
                    and m.idcanal = 'CO'
                  group by m.grupo, m.idcomisionista)
    LOOP
      -- insert maestro de consolidado comisionista
      v_error := 'Falla INSERT tblslvconsolidadocomi IdPersona: ' ||
                 p_IdPersona || ' Comisionista: ' || comi.idcomisionista || ' Grupo: '||comi.grupo;
      INSERT INTO tblslvconsolidadocomi
                  (idconsolidadocomi,
                  idconsolidadom,
                  grupo,
                  idpersona,
                  cdestado,
                  dtinsert,
                  dtupdate,
                  idcomisionista)
           VALUES
                  (seq_consolidadocomi.nextval,
                  seq_consolidadom.currval,
                  COMI.GRUPO,
                  p_IdPersona,
                  25, --consolidadocomi creado tblslvestado
                  SYSDATE,
                  NULL,
                  COMI.IDCOMISIONISTA);

      -- insert del detalle de consolidado comisionistas
      v_error := 'Falla INSERT tblslvconsolidadocomidet IdPersona: ' ||
                 p_IdPersona || ' Comisionista: ' || comi.idcomisionista || ' Grupo: '||comi.grupo;
      INSERT INTO tblslvconsolidadocomidet
                  (idconsolidadocomidet,
                  idconsolidadocomi,
                  cdarticulo,
                  qtunidadmedidabase,
                  qtpiezas,
                  qtunidadmedidabasepicking,
                  qtpiezaspicking,
                  idgrupo_sector)
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
                     from pedidos ped,
                          detallepedidos detped,
                          tbltmpslvConsolidadoM mm
                    where ped.idpedido = detped.idpedido
                      and nvl(ped.iczonafranca, 0) = 0 --valida zona franca
                      and ped.idcnpedido is null --valida cesta navideña
                      and detped.icresppromo = 0 --valida que no sea promo
                      and ped.icestadosistema = c_pedi_liberado
                      and ped.id_canal = 'CO'
                      and ped.transid = mm.transid
                      and mm.idpersona = p_idPersona
                      and mm.idcomisionista = COMI.idcomisionista
                      and mm.grupo = COMI.GRUPO
                 group by detped.cdarticulo) A,
                          articulos art,
                          tblslv_grupo_sector gs
             WHERE art.cdarticulo = A.cod
               AND trim(gs.cdsector) =
                   trim(decode(trim(art.cdidentificador),
                           '01',
                           '26',
                           art.cdsector))
               AND gs.cdsucursal = g_cdsucursal
            ;

     IF SQL%ROWCOUNT = 0  THEN      --valida insert tblslvconsolidadocomidet
        n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       '  Detalle Error: ' || v_error);
   	    p_Ok:=0;
        p_error:='Error en Consolidar. Comuniquese con Sistemas!';
        ROLLBACK;
        RETURN;
      END IF;

      -- consolidadopedido del comisionista agrupado por cliente
      v_error := 'Falla cursor agrupar por comisionista y cliente IdPersona: ' ||
                 p_IdPersona || ' Comisionista: ' || comi.idcomisionista || ' Grupo: '||comi.grupo;
      FOR PEDIDOCOMI IN (select d.identidadreal
                           from tbltmpslvconsolidadom m,
                                pedidos               p,
                                documentos            d
                          where m.transid = p.transid
                            and d.iddoctrx = p.iddoctrx 
                            and m.idpersona = p_idPersona
                            and m.idcomisionista = COMI.idcomisionista
                            and m.grupo = COMI.GRUPO
                          group by d.identidadreal) LOOP
        -- insert maestro de consolidadopedido por comisionista por cliente
        v_error := 'Falla INSERT tblslvconsolidadopedido Cliente: ' ||
                   pedidocomi.identidadreal || ' IdPersona: ' ||
                   p_IdPersona || ' Comisionista: ' ||
                   comi.idcomisionista || ' Grupo: '||comi.grupo;
        INSERT INTO tblslvconsolidadopedido
                    (idconsolidadopedido,
                    identidad,
                    cdestado,
                    idconsolidadom,
                    idpersona,
                    idconsolidadocomi,
                    dtinsert,
                    dtupdate,
                    id_canal,
                    cdsucursal)
             VALUES
                    (seq_consolidadopedido.nextval,
                    PEDIDOCOMI.identidadreal,
                    10,
                    seq_consolidadom.currval,
                    p_IdPersona,
                    seq_consolidadocomi.currval,
                    SYSDATE,
                    NULL,
                    'CO',
                    g_cdSucursal);

        --insert de consolidadopedidorel en relacion con pedidoconsolidado comisionista
        v_error := 'Falla INSERT tblslvconsolidadopedidorel Cliente: '  ||
                   pedidocomi.identidadreal || ' IdPersona: ' ||
                   p_IdPersona || ' Comisionista: ' ||
                   comi.idcomisionista || ' Grupo: '||comi.grupo;
        INSERT INTO tblslvconsolidadopedidorel
                    (idconsolidadopedidorel,
                    idpedido,
                    idconsolidadopedido,
                    cdsucursal)
             SELECT seq_consolidadopedidorel.nextval,
                    A.idpedido,
                    seq_consolidadopedido.currval,
                    g_cdSucursal
               FROM (select p.idpedido
                       from tbltmpslvconsolidadom m,
                            pedidos               p,
                            documentos            d
                      where m.transid = p.transid
                        and d.iddoctrx = p.iddoctrx
                        and m.idpersona = p_idPersona
                        and d.identidadreal = PEDIDOCOMI.identidadreal --valida identidad del cliente
                        and m.idcomisionista = COMI.idcomisionista
                        and m.grupo = COMI.GRUPO
                   group by p.idpedido) A;

     IF SQL%ROWCOUNT = 0  THEN      --valida insert tblslvconsolidadopedidorel
        n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       '  Detalle Error: ' || v_error);
   	    p_Ok:=0;
        p_error:='Error en Consolidar. Comuniquese con Sistemas!';
        ROLLBACK;
        RETURN;
      END IF;

        -- insert detalle de consolidadopedidodetalle del comisionista por cliente
        v_error := 'Falla INSERT tblslvconsolidadopedidodet Cliente: '  ||
                   pedidocomi.identidadreal || ' IdPersona: ' ||
                   p_IdPersona || ' Comisionista: ' ||
                   comi.idcomisionista || ' Grupo: '||comi.grupo;
      INSERT INTO tblslvconsolidadopedidodet
                  (idconsolidadopedidodet,
                  idconsolidadopedido,
                  cdarticulo,
                  qtunidadesmedidabase,
                  qtpiezas,
                  qtunidadmedidabasepicking,
                  qtpiezaspicking,
                  idgrupo_sector,
                  cdsucursal)
           SELECT seq_consolidadopedidodet.nextval,
                  seq_consolidadopedido.currval,
                  A.COD,
                  A.CANT,
                  A.PIEZAS,
                  null                             qtundpicking,
                  null                             qtpiezaspicking,
                  gs.idgrupo_sector,
                  g_cdSucursal --Sector del Articulo
             FROM (select detped.cdarticulo COD,
                          SUM(detped.qtunidadmedidabase) CANT,
                          SUM(nvl(detped.qtpiezas, 0)) PIEZAS
                     from pedidos        ped,
                          detallepedidos detped,
                          documentos     d,
                          tbltmpslvConsolidadoM mm
                    where ped.idpedido = detped.idpedido
                      and d.iddoctrx = ped.iddoctrx
                      and d.identidadreal = PEDIDOCOMI.identidadreal --valida identidad del cliente
                      and ped.idcomisionista = COMI.idcomisionista --valida comisionista del pedido
                      and nvl(ped.iczonafranca, 0) = 0 --valida zona franca
                      and ped.idcnpedido is null --valida cesta navideña
                      and detped.icresppromo = 0 --valida que no sea promo
                      and ped.icestadosistema = c_pedi_liberado
                      and ped.id_canal = 'CO'
                      and ped.transid = mm.transid
                      and mm.idpersona = p_idPersona
                      and mm.idcomisionista = COMI.idcomisionista
                      and mm.grupo = COMI.GRUPO
                 group by detped.cdarticulo) A,
                          articulos art,
                          tblslv_grupo_sector gs
            WHERE art.cdarticulo = a.cod
              AND trim(gs.cdsector) =
                  trim(decode(trim(art.cdidentificador),
                             '01',
                             '26',
                             art.cdsector))
              AND gs.cdsucursal = g_cdsucursal
              ;

      IF SQL%ROWCOUNT = 0  THEN      --valida insert tblslvconsolidadopedidodet
        n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       '  Detalle Error: ' || v_error);
   	    p_Ok:=0;
        p_error:='Error en Consolidar. Comuniquese con Sistemas!';
        ROLLBACK;
        RETURN;
      END IF;

      END LOOP; --loop clientes comisionistas
    END LOOP; --loop comisionistas por grupo
     n_pkg_vitalpos_log_general.write(2, 'Modulo: ' || v_modulo ||
                                     ' Finaliza proceso maestro detalle: pedidos de Comisionistas  ');        
     --Actualizo los pedidos a estado 3
    v_error := 'Falla UPDATE Pedidos a estado 3 idPersona: ' ||
               p_IdPersona;
    UPDATE pedidos ped
       SET ped.icestadosistema=3
     WHERE ped.transid in (select m.transid
                             from tbltmpslvconsolidadom M
                            where m.idpersona = p_IdPersona);

     IF SQL%ROWCOUNT = 0  THEN      --valida UPDATE Pedidos
        n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       '  Detalle Error: ' || v_error);
   	    p_Ok:=0;
        p_error:='Error en Consolidar. Comuniquese con Sistemas!';
        ROLLBACK;
        RETURN;
      END IF;

    --elimino la temporal despues de crear los objetos de todos los tipos de pedido
    v_error := 'Falla DELETE tbltmpslvconsolidadom idPersona: ' ||
               p_IdPersona;
    DELETE tbltmpslvconsolidadom M
     WHERE M.IDPERSONA = p_IdPersona;

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
  
  /****************************************************************************************************
  * %v 19/05/2020 - ChM  Versión inicial SetConsolidadoPedidosFaltante
  * %v 19/05/2020 - ChM  procedimiento para generar el consolidado de faltantes de pedidos
  * %v 26/05/2020 - ChM  Agrego validacion de Pesables
  *****************************************************************************************************/ 

 PROCEDURE SetConsolidadoPedidosFaltante(p_idpersona           IN  personas.idpersona%type,
                                         p_IdconsolidadoPedido IN  arr_IdConsoPedido,  
                                         p_IdPedFaltante       OUT Tblslvpedfaltante.Idpedfaltante%type,
                                         p_Ok                  OUT number,
                                         p_error               OUT varchar2) IS

    v_modulo       varchar2(100) := 'PKG_SLV_ConsolidaM.SetConsolidadoPedidosFaltante';
    v_error        varchar2(250);
    v_idpedido     pedidos.idpedido%type := null;
    v_estado       tblslvconsolidadopedido.cdestado%type:=null;
    
  BEGIN
    FOR i IN 1 .. p_IdconsolidadoPedido.count LOOP
     --select para validar que el pedido no este facturado    
       begin
       select cp.idconsolidadopedido,
              cp.cdestado
         into v_idpedido,
              v_estado
         from tblslvconsolidadopedido cp
        where cp.idconsolidadopedido = to_number(p_IdconsolidadoPedido(i));
     exception
       when no_data_found then
         p_Ok    := 0;
         p_error := 'Pedido '|| to_char(v_idpedido) ||' no existe.';
         RETURN;
     end;
      --verifico si el pedido ya esta Facturado
      if v_estado in (C_AFacturarConsolidadoPedido,C_FacturadoConsolidadoPedido) then
         p_Ok    := 0;
         p_error := 'Pedido '|| to_char(v_idpedido) ||' ya facturado';
         RETURN;
      end if;
      --verifico si el pedido esta cerrado 
      if v_estado = C_CerradoConsolidadoPedido then
         p_Ok    := 0;
         p_error := 'Pedido '|| to_char(v_idpedido) ||' ya finalizado';
         RETURN;
      end if;
      --select para validar que el consolidado pedido no sea parte de un pedfaltante 
      begin 
      v_error := 'Falla validación con pedidos Faltantes rel';
      select cp.idconsolidadopedido 
        into v_idpedido
        from tblslvconsolidadopedido cp,
             tblslvpedfaltanterel fre             
       where cp.idconsolidadopedido = fre.idconsolidadopedido
         and cp.idconsolidadopedido = to_number(p_IdconsolidadoPedido(i))    
         and rownum=1;           
      if v_idpedido is not null then
          p_Ok    := 0;
          p_error := 'Pedido '|| to_char(v_idpedido) ||' ya es parte de un consolidado faltante.';
          return;
       end if;
      exception
        when no_data_found then
          v_idpedido:=null;
      end;
 
    --valida que el pedido tenga faltantes en su detalle y no este null así aseguro que pikió  
    begin
    v_error := 'Falla validación con detalle de consolidado pedidos Faltantes';  
    select cp.idconsolidadopedido 
      into v_idpedido     
      from tblslvconsolidadopedido cp,
           tblslvconsolidadopedidodet cpd,
           tblslvconsolidadopedidorel prel,
           pedidos pe
     where cp.idconsolidadopedido = prel.idconsolidadopedido
       and pe.idpedido = prel.idpedido
       and cp.idconsolidadopedido = cpd.idconsolidadopedido
       and case 
             --verifica si es pesable 
             when  cpd.qtpiezas<>0 
               and cpd.qtpiezas-nvl(cpd.qtpiezaspicking,0) <> 0 then 1
             --verifica los no pesable
             when  cpd.qtpiezas = 0 
               and cpd.qtunidadesmedidabase-nvl(cpd.qtunidadmedidabasepicking,0) <> 0 then 1
           end = 1   
       --valida que el articulo se pikeo anteriormente   
       and cpd.qtunidadmedidabasepicking is not null
       and cp.idconsolidadopedido = to_number(p_IdconsolidadoPedido(i))    
       and rownum=1;     
     exception
        when no_data_found then
           p_Ok    := 0;
          p_error := 'Pedido '|| to_char(v_idpedido) ||' no tiene artículos faltantes';
          return;
      end;  
    END LOOP; --fin loop pedidos 
    
     -- inserto en el maestro de pedfaltante  
    v_error := 'Falla insert tblslvpedfaltante ';
    INSERT INTO tblslvpedfaltante
                (idpedfaltante,
                 idpersona,           
                 cdestado,
                 dtinsert,
                 dtupdate)
        VALUES (seq_pedfaltante.nextval,
                p_IdPersona,
                18, --FaltanteConsolidadoPedido Creado
                SYSDATE, 
                NULL);
    --devuelve el idpedfaltante creado            
    p_IdPedFaltante :=  seq_pedfaltante.currval;    
    --valida insert tblslvpedfaltante
    IF SQL%ROWCOUNT = 0  THEN      
        n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       '  Detalle Error: ' || v_error);
   	    p_Ok:=0;
        p_error:='Error. Comuniquese con Sistemas!';
        ROLLBACK;
        RETURN;
     END IF;
    
    --inserto en tblslvpedfaltanterel para luego hacer la distribución
     FOR i IN 1 .. p_IdconsolidadoPedido.count 
       LOOP 
         v_error:= 'falla insertando tblslvpedfaltanterel. Pedido: '||p_IdconsolidadoPedido(i);   
         insert into tblslvpedfaltanterel
                     (idpedfaltanterel,
                      idpedfaltante,
                      idconsolidadopedido,
                      dtdistribucion,
                      idpersonadistribucion,
                      dtinsert,
                      dtupdate,
                      cdsucursal)
               values (seq_pedfaltanterel.nextval,
                       seq_pedfaltante.currval,
                       to_number(p_IdconsolidadoPedido(i)),
                       null,
                       null,
                       sysdate,
                       null,
                       g_cdSucursal);
      IF SQL%ROWCOUNT = 0  THEN      
        n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       '  Detalle Error: ' || v_error);
   	    p_Ok:=0;
        p_error:='Error. Comuniquese con Sistemas!';
        ROLLBACK;
        RETURN;
     END IF;       
       END LOOP;
    -- inserto en el detalle de pedfaltantedet  
    v_error := 'Falla insert tblslvpedfaltantedet ';
    INSERT INTO tblslvpedfaltantedet
                (idpedfaltantedet,
                 idpedfaltante,
                 cdarticulo,           
                 qtunidadmedidabase,
                 qtpiezas,
                 qtunidadmedidabasepicking,
                 qtpiezaspicking,
                 idgrupo_sector)
                 select seq_pedfaltantedet.nextval,
                        seq_pedfaltante.currval,
                        A.cdarticulo,                       
                        A.faltante,
                        A.piezas,
                        null,
                        null,
                        A.sector
                   from (select cpd.cdarticulo,                       
                                sum(nvl(cpd.qtunidadesmedidabase,0)-
                                nvl(cpd.qtunidadmedidabasepicking,0)) faltante,
                                sum(nvl(cpd.qtpiezas,0)-
                                nvl(cpd.qtpiezaspicking,0)) piezas,
                                cpd.idgrupo_sector sector
                           from tblslvconsolidadopedido cp,
                                tblslvconsolidadopedidodet cpd
                          where cp.idconsolidadopedido = cpd.idconsolidadopedido
                            --valida insertar solo los articulos faltantes en su detalle 
                            and case 
                                 --verifica si es pesable 
                                 when cpd.qtpiezas<>0 
                                  and cpd.qtpiezas-nvl(cpd.qtpiezaspicking,0) <> 0 then 1
                                 --verifica los no pesable
                                 when cpd.qtpiezas = 0 
                                  and cpd.qtunidadesmedidabase-nvl(cpd.qtunidadmedidabasepicking,0) <> 0 then 1
                                end = 1   
                            --valida que el articulo se pikeo anteriormente   
                            and cpd.qtunidadmedidabasepicking is not null
                            --solo los idconsolidadopedido de faltante
                            and cp.idconsolidadopedido in 
                                (  select
                                 distinct fr.idconsolidadopedido
                                     from tblslvpedfaltanterel fr
                                    where fr.idpedfaltante=p_IdPedFaltante)
                       group by cpd.cdarticulo,
                                cpd.idgrupo_sector ) A;
       --valida insert tblslvpedfaltantedet
       IF SQL%ROWCOUNT = 0  THEN      
          n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       '  Detalle Error: ' || v_error);
   	      p_Ok:=0;
          p_error:='Error. Comuniquese con Sistemas!';
          ROLLBACK;
          RETURN;
       END IF;
    p_Ok:=1;
    p_error:='';   
    commit;
    EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       '  Detalle Error: ' || v_error ||
                                       '  Error: ' || SQLERRM);
      p_Ok    := 0;
      p_error := 'Imposible Realizar Consolidado de Pedidos Faltantes. Comuniquese con Sistemas!';
      ROLLBACK;
  END SetConsolidadoPedidosFaltante; 
  
  
end PKG_SLV_ConsolidaM;
/
