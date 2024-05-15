CREATE OR REPLACE PACKAGE SLVAPP.PKG_SLV_REPORTES AS
/******************************************************************************
      Nombre: PKG_SLV_REPORTES
    Descripción: Manejo de todo lo relacionado con reportes

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        27/02/2013   Nicolas Arroyo     versión inicial
******************************************************************************/

 TYPE cursor_type IS REF CURSOR;

  PROCEDURE ReporteFaltantesPorFecha(r_cursor    OUT cursor_type,
                                     pFechaDesde IN date,
                                     pFechaHasta IN date);

  PROCEDURE ReporteMarbetePedido(r_cursor OUT cursor_type,
    pIdconsolidado_pedido IN tblslv_consolidado_pedido.idconsolidado_pedido%TYPE);

PROCEDURE ReporteTiemposArmadoPag(r_cursor    OUT cursor_type,
                               pIdArmador  IN  tblslv_armadores.idarmador%TYPE,
                               pFechaDesde IN  Date,
                               pFechaHasta IN  Date);

  PROCEDURE ReporteTiemposArmado(r_cursor    OUT cursor_type,
                                 pIdArmador  IN  tblslv_armadores.idarmador%TYPE,
                                 pFechaDesde IN  Date,
                                 pFechaHasta IN  Date);



  PROCEDURE ReporteDiferenciasFactura(r_cursor OUT cursor_type,
                                      pFechaPedido IN date);

  PROCEDURE ReporteTiemposArmadoGralPag(r_cursor OUT cursor_type,
    pFechaDesde IN Date,
    pFechaHasta IN Date);
    
  PROCEDURE ReporteTiemposArmadoGeneral(r_cursor OUT cursor_type,
    pFechaDesde IN Date,
    pFechaHasta IN Date);

  PROCEDURE ReporteErroresArmador(r_cursor    OUT cursor_type,
                                  pIdArmador  IN TBLSLV_ARMADORES.IDARMADOR%TYPE  default null,
                                  pFechaDesde IN Date,
                                  pFechaHasta IN Date,
                                pidCanal       IN TBLSLV_ERRORESARMADOR.id_canal%TYPE);

PROCEDURE ReporteTiempoArmadoComi(r_cursor OUT cursor_type,
                                      pFechaDesde IN Date,
                                      pFechaHasta IN Date,
                                      pIdArmador IN tblslv_consolidado_sector.idarmador%TYPE);


PROCEDURE ReporteDiferenciasFacComi(r_cursor OUT cursor_type,
                                    pFechaPedido IN date);


PROCEDURE ReporteFaltantesXFechaComi(r_cursor    OUT cursor_type,
                                   pFechaDesde IN date,
                                   pFechaHasta IN date,
                                   pIdComisionista IN pedidos.idcomisionista%TYPE);

PROCEDURE GetNombreImpresora (r_cursor    OUT cursor_type );

PROCEDURE RepoControlTiempoFactPagSLV (r_cursor    OUT cursor_type
  ,p_fecha Movmateriales.Dtaplicacion%TYPE );

PROCEDURE RepoControlTiempoFactSLV (r_cursor    OUT cursor_type
  ,p_fecha Movmateriales.Dtaplicacion%TYPE );

PROCEDURE RepoControlTiempoFactComi(r_cursor    OUT cursor_type
  ,p_fecha Movmateriales.Dtaplicacion%TYPE );

END PKG_SLV_REPORTES;
/
CREATE OR REPLACE PACKAGE BODY SLVAPP.PKG_SLV_REPORTES  AS

/*
Modificado por Juan Bodnar
Fecha: 07/01/2014
Se modifica la consulta del cursor tomando como referencia la view  SLVAPP.VIEW_SLV_PEDI_FALTANTES de produccion
Se adapta para que reciba los parametros de fecha desde y hasta
Modificado por IAquilano
Fecha: 20/09/2018 - Llamado a la funcion de stock que mira la VM
*/
PROCEDURE ReporteFaltantesPorFecha(r_cursor    OUT cursor_type,
                                   pFechaDesde IN date,
                                   pFechaHasta IN date)
IS
BEGIN
    OPEN r_cursor FOR
    SELECT suc.dssucursal sucursal,
            to_char(cons.fecha_consolidado,'dd/mm/yyyy') fechaconsolidado,
            sec.dssector gruposector,
            pick.cdarticulo|| ' - ' || dart.vldescripcion articulo,
            round(pedi.precioun,3) preciounitario,
            SUM (pedi.pedidoUn) unidades_pedidas,
            SUM (pick.pickUn) unidades_pickeadas,
            SUM (nvl(pedi.pedidoUn,0) - nvl(pick.pickUn,0)) faltantes,
            round(AVG (pkg_slv_articulos.GetStockArticulos(pick.cdarticulo)),3) stock,
            /*PKG_SLV_ARTICULOS.CONVERTIRUNIDADES(pick.cdarticulo,1,'BTO','UN',0)*/posapp.n_pkg_vitalpos_materiales.GetUxB(pick.cdarticulo) UXB,
            PKG_SLV_ARTICULOS.GETUBICACIONARTICULOS(pick.cdarticulo,suc.cdsucursal) UBICACION
       FROM (  SELECT cons.idconsolidado,
                      dp.cdarticulo,
                      AVG (dp.ampreciounitario) precioun,
                      SUM (NVL (dp.qtunidadmedidabase, 0) + NVL (dp.qtpiezas, 0))
                         pedidoUn
                 FROM tblslv_consolidado_pedido cped,
                      tblslv_consolidado cons,
                      tblslv_consolidado_pedido_rel cpr,
                      detallepedidos dp
                WHERE     cons.idconsolidado = cped.idconsolidado
                      AND cped.idconsolidado_pedido = cpr.idconsolidado_pedido
                      AND cpr.idpedido_pos = dp.idpedido
                      AND DP.ICRESPPROMO <> 1
                      AND cped.IDESTADO IN (4, 5, 9)
                      and (cped.id_canal is null or cped.id_canal<>'CO')
             GROUP BY cons.idconsolidado, dp.cdarticulo) pedi,
            (  SELECT cons.idconsolidado,
                      cpd.cdarticulo,
                      AVG (NVL (cpd.qtstock, 0)) StockUN,
                      SUM (NVL (cpd.qtunidadbasepicking, 0)
                                                           ) pickUn
                 FROM tblslv_consolidado_pedido cped,
                      tblslv_consolidado_pedido_det cpd,
                      tblslv_consolidado cons
                WHERE cons.idconsolidado = cped.idconsolidado
                      AND cped.idconsolidado_pedido = cpd.idconsolidado_pedido
                      AND cped.IDESTADO IN (4, 5, 9)
                      and (cped.id_canal is null or cped.id_canal<>'CO')
             GROUP BY cons.idconsolidado, cpd.cdarticulo) pick,
            tblslv_consolidado cons,
            sucursales suc,
            descripcionesarticulos dart,
            sectores sec,
            articulos art
      WHERE     pedi.idconsolidado = pick.idconsolidado
            AND pedi.cdarticulo = pick.cdarticulo
            AND pedi.cdarticulo = dart.cdarticulo
            AND pedi.idconsolidado = cons.idconsolidado
            AND cons.cdsucursal = suc.cdsucursal
            AND pedi.cdarticulo = art.cdarticulo
            AND art.cdsector = sec.cdsector
            AND (pedi.pedidoUn - pick.pickUn)>0
            AND TRUNC(CONS.FECHA_CONSOLIDADO) BETWEEN TRUNC(NVL(pFechaDesde, SYSDATE)) AND TRUNC(NVL(pFechaHasta, SYSDATE))
   GROUP BY suc.dssucursal ,suc.cdsucursal,
            cons.fecha_consolidado ,
            sec.dssector ,
            pick.cdarticulo|| ' - ' || dart.vldescripcion ,
            pedi.precioun,
            pick.cdarticulo  ;

END ReporteFaltantesPorFecha;


PROCEDURE ReporteMarbetePedido(r_cursor OUT cursor_type,
    pIdconsolidado_pedido IN tblslv_consolidado_pedido.idconsolidado_pedido%TYPE)
    IS

    BEGIN
        OPEN r_cursor FOR
        SELECT    cp.idconsolidado_pedido PedidoNumero
                  ,cp.idestado Estado
                  ,cp.idconsolidado ConsolidadoNumero
                  ,to_char(cp.fecha_pedido, 'dd/MM/yyyy') FechaPedido
                  ,to_char(cp.fecha_entrega, 'dd/MM/yyyy') FechaEntrega
                  ,suc.dssucursal Sucursal
                  --  Formato Cliente
                  ,'(' || TRIM (ent.cdcuit) || ') '
                  || NVL (ent.dsrazonsocial, ent.dsnombrefantasia) Cliente
                  -- Formato Direccion
                  ,dirent.dscalle || ' ' || dirent.dsnumero
                  || '(' || dirent.cdcodigopostal || ') '
                  || ' ' || loc.dslocalidad || ' - ' || pro.dsprovincia
                  || ' - ' || pa.dspais Direccion
           FROM   tblslv_consolidado_pedido cp
                  ,tblslv_consolidado cons
                  ,entidades ent
                  ,direccionesentidades dirent
                  ,paises pa
                  ,provincias pro
                  ,localidades loc
                  ,sucursales suc

          WHERE   cp.idconsolidado_pedido = pIdconsolidado_pedido
                  AND cons.idconsolidado = cp.idconsolidado
                  AND suc.cdsucursal = cons.cdsucursal
                  AND ent.identidad = cp.identidad
                  AND dirent.identidad = ent.identidad
                  AND dirent.cdtipodireccion = cp.cdtipodireccion
                  AND dirent.sqdireccion = cp.sqdireccion
                  AND dirent.cdpais=pa.cdpais
                  AND dirent.cdpais=pro.cdpais
                  AND dirent.cdpais=loc.cdpais
                  AND dirent.cdprovincia=pro.cdprovincia
                  and dirent.cdprovincia=loc.cdprovincia
                  AND dirent.cdlocalidad=loc.cdlocalidad(+);
    END ReporteMarbetePedido;

PROCEDURE ReporteTiemposArmadoPag(r_cursor    OUT cursor_type,
                               pIdArmador  IN  tblslv_armadores.idarmador%TYPE,
                               pFechaDesde IN  Date,
                               pFechaHasta IN  Date)
IS
BEGIN
    OPEN r_cursor FOR
    select  distinct cpd.idconsolidado_pedido || '_'||cpd.pagina PedidoNumero
            ,suc.dssucursal Sucursal
            ,arm.nombre || ' ' ||  arm.apellido armador
            ,to_char(cpd.fecha_asignado, 'dd/MM/yyyy hh:mi') fecha_asignado
            --,to_char(cpd.fecha_cierre, 'dd/MM/yyyy hh:mi') fecha_cierre
            ,to_char(cpd.fecha_fin_armado, 'dd/MM/yyyy hh:mi') fecha_fin_armado
            --,trunc(1440 * (cpd.fecha_fin_armado - cpd.fecha_asignado)) tiempoarmado
            ,trunc(avg(1440 * (cpd.fecha_fin_armado - cpd.fecha_asignado))) tiempoarmado
    from    tblslv_consolidado_ped_pag cpd
            ,tblslv_consolidado_pedido cp
            ,tblslv_consolidado c
            ,tblslv_armadores arm
            ,sucursales suc
    where   cpd.idarmador is not null
    and     arm.idarmador = cpd.idarmador
    and     suc.cdsucursal = arm.cdsucursal
    and     cpd.fecha_fin_armado is not null
    and     cp.idconsolidado_pedido = cpd.idconsolidado_pedido
    and     c.idconsolidado = cp.idconsolidado
    and     arm.idarmador = nvl(pIdArmador, arm.idarmador)
    and     trunc(c.fecha_consolidado) between
            trunc(nvl(pFechaDesde, c.fecha_consolidado))
            and trunc(nvl(pFechaHasta, c.fecha_consolidado))
      group by cpd.idconsolidado_pedido,suc.dssucursal,arm.nombre || ' ' ||  arm.apellido,to_char(cpd.fecha_asignado, 'dd/MM/yyyy hh:mi'),
        to_char(cpd.fecha_fin_armado, 'dd/MM/yyyy hh:mi'); --,to_char(cpd.fecha_cierre, 'dd/MM/yyyy hh:mi');

END ReporteTiemposArmadoPag;

PROCEDURE ReporteTiemposArmado(r_cursor    OUT cursor_type,
                               pIdArmador  IN  tblslv_armadores.idarmador%TYPE,
                               pFechaDesde IN  Date,
                               pFechaHasta IN  Date)
IS
BEGIN
    OPEN r_cursor FOR
    select  distinct cpd.idconsolidado_pedido PedidoNumero
            ,suc.dssucursal Sucursal
            ,arm.nombre || ' ' ||  arm.apellido armador
            ,to_char(cpd.fecha_asignado, 'dd/MM/yyyy hh:mi') fecha_asignado
            --,to_char(cpd.fecha_cierre, 'dd/MM/yyyy hh:mi') fecha_cierre
            ,to_char(cpd.fecha_fin_armado, 'dd/MM/yyyy hh:mi') fecha_fin_armado
            --,trunc(1440 * (cpd.fecha_fin_armado - cpd.fecha_asignado)) tiempoarmado
            ,trunc(avg(1440 * (cpd.fecha_fin_armado - cpd.fecha_asignado))) tiempoarmado
    from    tblslv_consolidado_pedido_det cpd
            ,tblslv_consolidado_pedido cp
            ,tblslv_consolidado c
            ,tblslv_armadores arm
            ,sucursales suc
    where   cpd.idarmador is not null
    and     arm.idarmador = cpd.idarmador
    and     suc.cdsucursal = arm.cdsucursal
    and     cpd.fecha_fin_armado is not null
    and     cp.idconsolidado_pedido = cpd.idconsolidado_pedido
    and     c.idconsolidado = cp.idconsolidado
    and     arm.idarmador = nvl(pIdArmador, arm.idarmador)
    and     trunc(c.fecha_consolidado) between
            trunc(nvl(pFechaDesde, c.fecha_consolidado))
            and trunc(nvl(pFechaHasta, c.fecha_consolidado))
      group by cpd.idconsolidado_pedido,suc.dssucursal,arm.nombre || ' ' ||  arm.apellido,to_char(cpd.fecha_asignado, 'dd/MM/yyyy hh:mi'),
        to_char(cpd.fecha_fin_armado, 'dd/MM/yyyy hh:mi'); --,to_char(cpd.fecha_cierre, 'dd/MM/yyyy hh:mi');

END ReporteTiemposArmado;

PROCEDURE ReporteDiferenciasFactura(r_cursor OUT cursor_type,
                                    pFechaPedido IN date)
IS
BEGIN
    OPEN r_cursor FOR
       SELECT   PICK.IDCONSOLIDADO_PEDIDO,
               TRUNC(CP.FECHA_PEDIDO) FECHA_PEDIDO,
               ENT.DSRAZONSOCIAL RAZON_SOCIAL,
               ENT.CDCUIT CUIT,
               PICK.CDARTICULO,
               DA.VLDESCRIPCION ARTICULO,
               SUM(NVL(PICK.CANT, 0)) CANT_PICKING,
               SUM(NVL(FACTU.CANT, 0)) CANT_FACTU
          FROM (SELECT   CPR.IDCONSOLIDADO_PEDIDO,
                         DMM.CDARTICULO,
                         SUM(  DMM.QTUNIDADMEDIDABASE
                             + nvl(DMM.QTPIEZAS,0)) CANT
                    FROM TBLSLV_CONSOLIDADO_PEDIDO_REL CPR,
                         TBLSLV_CONSOLIDADO_PEDIDO CP,
                         MOVMATERIALES MM,
                         DETALLEMOVMATERIALES DMM,
                         PEDIDOS PEDI
                   WHERE MM.IDPEDIDO = CPR.IDPEDIDO_POS
                     AND DMM.IDMOVMATERIALES = MM.IDMOVMATERIALES
                     AND MM.IDPEDIDO = PEDI.IDPEDIDO
                     AND CPR.IDCONSOLIDADO_PEDIDO = CP.IDCONSOLIDADO_PEDIDO
                     AND CP.FECHA_PEDIDO >= TRUNC(NVL(pFechaPedido, SYSDATE))
                     AND PEDI.ICESTADOSISTEMA >3--IN(4, 5)
                     AND CP.Id_Canal<>'CO'
                     AND ( DMM.Icresppromo=0
                          OR DMM.DSOBSERVACION IS NULL)
                GROUP BY CPR.IDCONSOLIDADO_PEDIDO,
                         DMM.CDARTICULO) FACTU,
               (SELECT DISTINCT CPD.IDCONSOLIDADO_PEDIDO,
                       CPD.CDARTICULO,
                       (
                       select sum( nvl( CPD2.QTUNIDADBASEPICKING,0)
                        + nvl(CPD2.QTPIEZASPICKING,0)) from tblslv_consolidado_pedido_det cpd2
                       where cpd2.idconsolidado_pedido=cpd.idconsolidado_pedido
                       and cpd2.cdarticulo=cpd.cdarticulo
                       ) CANT
                  FROM TBLSLV_CONSOLIDADO_PEDIDO_DET CPD,
                       TBLSLV_CONSOLIDADO_PEDIDO CP,
                       TBLSLV_CONSOLIDADO_PEDIDO_REL CPR,
                       PEDIDOS PEDI
                 WHERE CPD.IDCONSOLIDADO_PEDIDO = CPR.IDCONSOLIDADO_PEDIDO
                 AND   CPR.IDPEDIDO_POS = PEDI.IDPEDIDO
                 AND   CPR.IDCONSOLIDADO_PEDIDO = CP.IDCONSOLIDADO_PEDIDO
                 AND   PEDI.ICESTADOSISTEMA >3--IN(4, 5)
                 AND CP.Id_Canal<>'CO'
                 AND   CP.FECHA_PEDIDO >= TRUNC(NVL(pFechaPedido, SYSDATE))
                 ) PICK,
               TBLSLV_CONSOLIDADO_PEDIDO CP,
               DESCRIPCIONESARTICULOS DA,
               ENTIDADES ENT
         WHERE PICK.CDARTICULO = FACTU.CDARTICULO(+)
           AND PICK.IDCONSOLIDADO_PEDIDO = FACTU.IDCONSOLIDADO_PEDIDO(+)
           AND CP.IDCONSOLIDADO_PEDIDO = PICK.IDCONSOLIDADO_PEDIDO
           AND PICK.CDARTICULO = DA.CDARTICULO
           AND ENT.IDENTIDAD = CP.IDENTIDAD
           AND CP.Id_Canal<>'CO'
           AND TRUNC(CP.FECHA_PEDIDO) = TRUNC(NVL(pFechaPedido, SYSDATE))
      GROUP BY PICK.IDCONSOLIDADO_PEDIDO,
               TRUNC(CP.FECHA_PEDIDO),
               ENT.DSRAZONSOCIAL,
               ENT.CDCUIT,
               PICK.CDARTICULO,
               DA.VLDESCRIPCION
        HAVING SUM(NVL(PICK.CANT, 0)) <> SUM(NVL(FACTU.CANT, 0));
      --ORDER BY PICK.CDARTICULO;

END ReporteDiferenciasFactura;

PROCEDURE ReporteTiemposArmadoGralPag(r_cursor OUT cursor_type,
                                      pFechaDesde IN Date,
                                      pFechaHasta IN Date)
IS
BEGIN
    OPEN r_cursor FOR
          SELECT SUC.DSSUCURSAL SUCURSAL
                ,ARM.NOMBRE || ' ' || ARM.APELLIDO ARMADOR
                ,PEDIDET.IDCONSOLIDADO_PEDIDO ||'_'|| PEDIDET.Pagina  PEDIDO
                ,TO_CHAR (PEDIDET.FECHA_ASIGNADO, 'dd/MM/yyyy hh:mi') COMIENZO
                ,TO_CHAR (PEDIDET.FECHA_FIN_ARMADO, 'dd/MM/yyyy hh:mi') FIN
                ,TRUNC (AVG (1440 * (PEDIDET.FECHA_FIN_ARMADO - PEDIDET.FECHA_ASIGNADO))) TIEMPOARMADO
                ,nvl( CANT_BTO.CANT_BTO,0) SOLO_BTO
                ,CANT_UN.CANTIDADUNIDADES TOTAL_UN
                ,nvl( ROUND(CANT_BTO.CANT_BTO / TRUNC (AVG (1440 * (PEDIDET.FECHA_FIN_ARMADO - PEDIDET.FECHA_ASIGNADO))),4),0) PROD_BTO
                ,ROUND(CANT_UN.CANTIDADUNIDADES / TRUNC (AVG (1440 * (PEDIDET.FECHA_FIN_ARMADO - PEDIDET.FECHA_ASIGNADO))),4) PROD_UN
             FROM TBLSLV_CONSOLIDADO_PED_PAG PEDIDET
                ,TBLSLV_ARMADORES ARM
                ,SUCURSALES SUC
                ,(  SELECT SUM (QTUNIDADBASEPICKING) CANTIDADUNIDADES
                          ,IDCONSOLIDADO_PEDIDO, pagina
                      FROM TBLSLV_CONSOLIDADO_PEDIDO_DET
                  GROUP BY IDCONSOLIDADO_PEDIDO, pagina) CANT_UN
                ,(  SELECT RTO.IDCONSOLIDADO_PEDIDO, pagina
                          ,SUM (TRUNC (RD.QTUNIDADBASEPICKING / UA.VLCONTADOR)) CANT_BTO
                      FROM TBLSLV_REMITO_DETALLE RD
                          ,BARRAS B
                          ,TBLSLV_REMITO RTO
                          ,ARTICULOS ART
                          ,UNIDADESARTICULO UA
                          ,tblslv_consolidado_pedido_det dett
                     WHERE RD.CDEANCODE = B.CDEANCODE
                       AND RD.IDREMITO = RTO.IDREMITO
                       AND ART.CDARTICULO = B.CDARTICULO
                       AND ART.CDARTICULO = UA.CDARTICULO
                       AND B.CDUNIDAD = UA.CDUNIDAD
                       AND B.CDUNIDAD = 'BTO'
                       AND RD.IDCONSOLIDADOPEDDET=dett.idconsolidadopeddet
                  GROUP BY RTO.IDCONSOLIDADO_PEDIDO, dett.pagina) CANT_BTO
                ,DETALLEPEDIDOS DP
                ,TBLSLV_CONSOLIDADO_PEDIDO_REL CPR
                ,TBLSLV_CONSOLIDADO CONS
                ,TBLSLV_CONSOLIDADO_PEDIDO CP
           WHERE (FECHA_ASIGNADO IS NOT NULL
             AND FECHA_FIN_ARMADO IS NOT NULL)
             AND ARM.IDARMADOR = PEDIDET.IDARMADOR
             AND SUC.CDSUCURSAL = ARM.CDSUCURSAL
             AND CANT_UN.IDCONSOLIDADO_PEDIDO(+) = PEDIDET.IDCONSOLIDADO_PEDIDO
             AND CANT_UN.pagina=PEDIDET.Pagina
             AND CANT_BTO.IDCONSOLIDADO_PEDIDO (+) = PEDIDET.IDCONSOLIDADO_PEDIDO
             AND CANT_BTO.pagina=PEDIDET.Pagina
             AND PEDIDET.IDCONSOLIDADO_PEDIDO = CPR.IDCONSOLIDADO_PEDIDO
             AND DP.IDPEDIDO = CPR.IDPEDIDO_POS
             AND CONS.IDCONSOLIDADO = CP.IDCONSOLIDADO
             --Se agrega el filtro de Id_Canal LM 13/01/2014
             AND ((CP.Id_Canal is null ) or
             (trim(CP.Id_Canal) <> 'CO'))
             AND CP.IDCONSOLIDADO_PEDIDO = PEDIDET.IDCONSOLIDADO_PEDIDO
             AND TRUNC (CONS.FECHA_CONSOLIDADO) BETWEEN TRUNC(NVL(pFechaDesde, SYSDATE))
                                                    AND TRUNC(NVL(pFechaHasta, SYSDATE))
        GROUP BY PEDIDET.IDCONSOLIDADO_PEDIDO, PEDIDET.Pagina
                ,SUC.DSSUCURSAL
                ,ARM.NOMBRE || ' ' || ARM.APELLIDO
                ,TO_CHAR(PEDIDET.FECHA_ASIGNADO, 'dd/MM/yyyy hh:mi')
                ,TO_CHAR(PEDIDET.FECHA_FIN_ARMADO, 'dd/MM/yyyy hh:mi')
                ,CANT_BTO.CANT_BTO
                ,CANT_UN.CANTIDADUNIDADES
          HAVING TRUNC(AVG(1440 * (PEDIDET.FECHA_FIN_ARMADO - PEDIDET.FECHA_ASIGNADO))) > 0;

END ReporteTiemposArmadoGralPag;

PROCEDURE ReporteTiemposArmadoGeneral(r_cursor OUT cursor_type,
                                      pFechaDesde IN Date,
                                      pFechaHasta IN Date)
IS
BEGIN
    OPEN r_cursor FOR
          SELECT SUC.DSSUCURSAL SUCURSAL
                ,ARM.NOMBRE || ' ' || ARM.APELLIDO ARMADOR
                ,PEDIDET.IDCONSOLIDADO_PEDIDO PEDIDO
                ,TO_CHAR (PEDIDET.FECHA_ASIGNADO, 'dd/MM/yyyy hh:mi') COMIENZO
                ,TO_CHAR (PEDIDET.FECHA_FIN_ARMADO, 'dd/MM/yyyy hh:mi') FIN
                ,TRUNC (AVG (1440 * (PEDIDET.FECHA_FIN_ARMADO - PEDIDET.FECHA_ASIGNADO))) TIEMPOARMADO
                ,nvl( CANT_BTO.CANT_BTO,0) SOLO_BTO
                ,CANT_UN.CANTIDADUNIDADES TOTAL_UN
                ,nvl( ROUND(CANT_BTO.CANT_BTO / TRUNC (AVG (1440 * (PEDIDET.FECHA_FIN_ARMADO - PEDIDET.FECHA_ASIGNADO))),4),0) PROD_BTO
                ,ROUND(CANT_UN.CANTIDADUNIDADES / TRUNC (AVG (1440 * (PEDIDET.FECHA_FIN_ARMADO - PEDIDET.FECHA_ASIGNADO))),4) PROD_UN
             FROM TBLSLV_CONSOLIDADO_PEDIDO_DET PEDIDET
                ,TBLSLV_ARMADORES ARM
                ,SUCURSALES SUC
                ,(  SELECT SUM (QTUNIDADBASEPICKING) CANTIDADUNIDADES
                          ,IDCONSOLIDADO_PEDIDO
                      FROM TBLSLV_CONSOLIDADO_PEDIDO_DET
                  GROUP BY IDCONSOLIDADO_PEDIDO) CANT_UN
                ,(  SELECT RTO.IDCONSOLIDADO_PEDIDO
                          ,SUM (TRUNC (RD.QTUNIDADBASEPICKING / UA.VLCONTADOR)) CANT_BTO
                      FROM TBLSLV_REMITO_DETALLE RD
                          ,BARRAS B
                          ,TBLSLV_REMITO RTO
                          ,ARTICULOS ART
                          ,UNIDADESARTICULO UA
                     WHERE RD.CDEANCODE = B.CDEANCODE
                       AND RD.IDREMITO = RTO.IDREMITO
                       AND ART.CDARTICULO = B.CDARTICULO
                       AND ART.CDARTICULO = UA.CDARTICULO
                       AND B.CDUNIDAD = UA.CDUNIDAD
                       AND B.CDUNIDAD = 'BTO'
                  GROUP BY RTO.IDCONSOLIDADO_PEDIDO) CANT_BTO
                ,DETALLEPEDIDOS DP
                ,TBLSLV_CONSOLIDADO_PEDIDO_REL CPR
                ,TBLSLV_CONSOLIDADO CONS
                ,TBLSLV_CONSOLIDADO_PEDIDO CP
           WHERE (FECHA_ASIGNADO IS NOT NULL
             AND FECHA_FIN_ARMADO IS NOT NULL)
             AND ARM.IDARMADOR = PEDIDET.IDARMADOR
             AND SUC.CDSUCURSAL = ARM.CDSUCURSAL
             AND CANT_UN.IDCONSOLIDADO_PEDIDO = PEDIDET.IDCONSOLIDADO_PEDIDO
             AND CANT_BTO.IDCONSOLIDADO_PEDIDO (+) = PEDIDET.IDCONSOLIDADO_PEDIDO
             AND PEDIDET.IDCONSOLIDADO_PEDIDO = CPR.IDCONSOLIDADO_PEDIDO
             AND DP.IDPEDIDO = CPR.IDPEDIDO_POS
             AND CONS.IDCONSOLIDADO = CP.IDCONSOLIDADO
             --Se agrega el filtro de Id_Canal LM 13/01/2014
             AND ((CP.Id_Canal is null ) or
             (trim(CP.Id_Canal) <> 'CO'))
             AND CP.IDCONSOLIDADO_PEDIDO = PEDIDET.IDCONSOLIDADO_PEDIDO
             AND TRUNC (CONS.FECHA_CONSOLIDADO) BETWEEN TRUNC(NVL(pFechaDesde, SYSDATE))
                                                    AND TRUNC(NVL(pFechaHasta, SYSDATE))
        GROUP BY PEDIDET.IDCONSOLIDADO_PEDIDO
                ,SUC.DSSUCURSAL
                ,ARM.NOMBRE || ' ' || ARM.APELLIDO
                ,TO_CHAR(PEDIDET.FECHA_ASIGNADO, 'dd/MM/yyyy hh:mi')
                ,TO_CHAR(PEDIDET.FECHA_FIN_ARMADO, 'dd/MM/yyyy hh:mi')
                ,CANT_BTO.CANT_BTO
                ,CANT_UN.CANTIDADUNIDADES
          HAVING TRUNC(AVG(1440 * (PEDIDET.FECHA_FIN_ARMADO - PEDIDET.FECHA_ASIGNADO))) > 0;

END ReporteTiemposArmadoGeneral;
 /*
   Modificado por LMendez 23/12/2013
   Se agrego el parametro pCdCanal
   */
PROCEDURE ReporteErroresArmador(r_cursor    OUT cursor_type,
                                pIdArmador  IN TBLSLV_ARMADORES.IDARMADOR%TYPE  default null,
                                pFechaDesde IN Date,
                                pFechaHasta IN Date,
                                pidCanal       IN TBLSLV_ERRORESARMADOR.id_canal%TYPE)
IS
BEGIN
    OPEN r_cursor FOR
        SELECT ERR.IDARMADOR ID_ARMADOR,
               ARM.LEGAJO LEGAJO,
               ARM.NOMBRE || ' ' || ARM.APELLIDO ARMADOR,
               ERR.IDREMITO ID_REMITO,
               ERR.CDARTICULO ID_ARTICULO,
               nvl(DA.VLDESCRIPCION,'Producto No Existente') ARTICULO,
               ERR.CDEANCODE EANCODE,
               ERR.QTUNIDADPICKING CANTIDAD,
               nvl(ERR.CDUNIDAD,'---') ID_UNIDAD,
               TRUNC(ERR.FECHA) FECHA
          FROM TBLSLV_ERRORESARMADOR ERR,
               TBLSLV_ARMADORES ARM,
               DESCRIPCIONESARTICULOS DA
         WHERE ERR.IDARMADOR = ARM.IDARMADOR
           AND ERR.CDARTICULO = DA.CDARTICULO(+)
           and (trim(pidCanal) is null or trim(nvl(ERR.id_canal,''))=trim(nvl(pidCanal,'')))
           AND ERR.IDARMADOR = NVL(pIdArmador, ERR.IDARMADOR)
           AND TRUNC(ERR.FECHA) BETWEEN TRUNC(NVL(pFechaDesde, ERR.FECHA))
                                    AND TRUNC(NVL(pFechaHasta, ERR.FECHA))
      ORDER BY 4, 3, 5;
END ReporteErroresArmador;

/*
Creado por Juan Bodnar
Fecha: 14/01/2014
ReporteTiempoArmadoComi
*/

PROCEDURE ReporteTiempoArmadoComi (r_cursor OUT cursor_type,
                                      pFechaDesde IN Date,
                                      pFechaHasta IN Date,
                                      pIdArmador IN tblslv_consolidado_sector.idarmador%TYPE)
IS
BEGIN
    OPEN r_cursor FOR
       select SUC.DSSUCURSAL SUCURSAL
,gs.dsgruposector || '-' || s.dssector DSGrupoSector
                ,ARM.NOMBRE || ' ' || ARM.APELLIDO ARMADOR
                ,cs.IDCONSOLIDADO Consolidado
                ,TO_CHAR (cs.DTFECHA_ASIGNADO, 'dd/MM/yyyy hh:mi') COMIENZO
                ,TO_CHAR (cs.DTFECHA_CIERRE, 'dd/MM/yyyy hh:mi') FIN
                ,TRUNC (AVG (1440 * (cs.DTFECHA_CIERRE - cs.DTFECHA_ASIGNADO))) TIEMPOARMADO
                ,nvl( CANT_BTO.CANT_BTO,0) SOLO_BTO
                ,CANT_UN.CANTIDADUNIDADES TOTAL_UN
               ,nvl( ROUND(CANT_BTO.CANT_BTO / TRUNC (AVG (1440 * (cs.DTFECHA_CIERRE - cs.DTFECHA_ASIGNADO))),4),0) PROD_BTO
             ,ROUND(CANT_UN.CANTIDADUNIDADES / TRUNC (AVG (1440 * (cs.DTFECHA_CIERRE - cs.DTFECHA_ASIGNADO))),4) PROD_UN
from
tblslv_armadores arm,
 tblslv_grupo_sector gs,
 posapp.sectores s
   ,(  SELECT SUM (nvl(ccd.cantidadunidadpicking,0)) CANTIDADUNIDADES
                          ,ccd.idgrupo_sector,ccd.idconsolidado
                   FROM tblslv_consolidado_detalle ccd , tblslv_consolidado_sector cs1, tblslv_consolidado co
                       where (pIdArmador=0 or nvl(cs1.idarmador,0)=pIdArmador)
                       and ccd.idconsolidado=cs1.idconsolidado
                       and ccd.idgrupo_sector=cs1.idgrupo_sector
                       and ccd.idconsolidado=co.idconsolidado
                       and CO.FECHA_CONSOLIDADO BETWEEN  TRUNC(NVL(pFechaDesde, SYSDATE)) AND TRUNC(NVL(pFechaHasta, SYSDATE))
                  GROUP BY ccd.idgrupo_sector,ccd.idconsolidado) CANT_UN
,(  SELECT cd.idgrupo_sector, cd.idconsolidado
                          ,SUM (TRUNC (RCD.QTUNIDADBASEPICKING / UA.VLCONTADOR)) CANT_BTO
                      FROM tblslv_remito_comisionista_det RCD
                          ,BARRAS B
                          ,tblslv_remito_comisionista RTO
                          ,ARTICULOS ART
                          ,UNIDADESARTICULO UA
                          ,tblslv_consolidado_detalle cd
                          ,tblslv_consolidado_sector cs2, tblslv_consolidado co
                     WHERE RCD.CDEANCODE = B.CDEANCODE
                       AND RCD.IDREMITO_COMISIONISTA = RTO.Idremito_Comisionista
                       AND ART.CDARTICULO = B.CDARTICULO
                       AND ART.CDARTICULO = UA.CDARTICULO
                       AND B.CDUNIDAD = UA.CDUNIDAD
                       and cs2.idgrupo_sector=cd.idgrupo_sector
                       and cs2.idconsolidado=cd.idconsolidado
                       AND rcd.idconsolidado_det=cd.idconsolidado_detalle
                       and cd.idconsolidado = co.idconsolidado
                       and co.FECHA_CONSOLIDADO BETWEEN  TRUNC(NVL(pFechaDesde, SYSDATE)) AND TRUNC(NVL(pFechaHasta, SYSDATE))
                       AND B.CDUNIDAD = 'BTO'
                       and (pIdArmador=0 or nvl(cs2.idarmador,0)=pIdArmador)
                  GROUP BY cd.idgrupo_sector, cd.idconsolidado) CANT_BTO
 ,SUCURSALES SUC,
tblslv_consolidado c,
tblslv_consolidado_detalle cd,
tblslv_consolidado_sector cs,
tblslv_consolidado_pedido cp/*,
tblslv_sector_grupoarticulos sga*/
where c.idconsolidado=cd.idconsolidado
and cd.idgrupo_sector=cs.idgrupo_sector
and cd.idconsolidado=cs.idconsolidado
and cs.idgrupo_sector=gs.idgrupo_sector
and gs.cdsector=s.cdsector
/*and gs.cdsecgrupoart=sga.cdsecgrupoart
and sga.cdsector=s.cdsector*/
and cs.idarmador=arm.idarmador
and cp.idconsolidado=c.idconsolidado
and trim(cp.id_canal)='CO'
AND trim(SUC.CDSUCURSAL) = trim(ARM.CDSUCURSAL)
and Cant_bto.idconsolidado (+)=cs.idconsolidado
and cant_bto.idgrupo_sector (+)=cs.idgrupo_sector
AND CANT_UN.idconsolidado=cs.idconsolidado
AND CANT_UN.idgrupo_sector=cs.idgrupo_sector
AND CANT_UN.CANTIDADUNIDADES>0
--AND CANT_BTO.CANT_BTO>0 --Comento esta linea porque no esta trayendome todos los sectores que se pickearon LM 07/02/2014
AND(C.FECHA_CONSOLIDADO) BETWEEN  TRUNC(NVL(pFechaDesde, SYSDATE))
AND TRUNC(NVL(pFechaHasta, SYSDATE))
GROUP BY cs.IDCONSOLIDADO
                ,SUC.DSSUCURSAL
                ,gs.dsgruposector || '-' || s.dssector
                ,ARM.NOMBRE || ' ' || ARM.APELLIDO
                ,TO_CHAR(cs.DTFECHA_ASIGNADO, 'dd/MM/yyyy hh:mi')
                ,TO_CHAR(cs.DTFECHA_CIERRE, 'dd/MM/yyyy hh:mi')
                ,CANT_BTO.CANT_BTO
                ,CANT_UN.CANTIDADUNIDADES
         HAVING TRUNC(AVG(1440 * (cs.DTFECHA_CIERRE - cs.DTFECHA_ASIGNADO))) > 0;
END ReporteTiempoArmadoComi;

PROCEDURE ReporteDiferenciasFacComi(r_cursor OUT cursor_type,
                                    pFechaPedido IN date)
IS
BEGIN
    OPEN r_cursor FOR
          SELECT   PICK.IDCONSOLIDADO,
               PKG_SLV_COMISIONISTA.GetNomComisionista(pick.idconsolidado) Comisionista,
               TRUNC(C.FECHA_CONSOLIDADO) FECHA,
               PICK.CDARTICULO,
               DA.VLDESCRIPCION ARTICULO,
               SUM(NVL(PICK.CANT, 0)) CANT_PICKING,
               SUM(NVL(FACTU.CANT, 0)) CANT_FACTU
          FROM (SELECT   CP.IDCONSOLIDADO,
                         DMM.CDARTICULO,
                        case when nvl(dmm.qtpiezas,0)>0 then
                           sum(dmm.qtpiezas)
                           else
                         SUM(  DMM.QTUNIDADMEDIDABASE
                             ) end CANT
                    FROM TBLSLV_CONSOLIDADO_PEDIDO_REL CPR,
                         TBLSLV_CONSOLIDADO_PEDIDO CP,
                         MOVMATERIALES MM,
                         DETALLEMOVMATERIALES DMM,
                         PEDIDOS PEDI,
                         tblslv_consolidado c
                   WHERE MM.IDPEDIDO = CPR.IDPEDIDO_POS
                     AND DMM.IDMOVMATERIALES = MM.IDMOVMATERIALES
                     AND c.idconsolidado=cp.idconsolidado
                     AND MM.IDPEDIDO = PEDI.IDPEDIDO
                     AND PEDI.id_canal='CO'
                     AND CPR.IDCONSOLIDADO_PEDIDO = CP.IDCONSOLIDADO_PEDIDO
                     AND c.fecha_consolidado >= TRUNC(NVL(pFechaPedido, SYSDATE))
                    -- AND PEDI.ICESTADOSISTEMA IN(4, 5)
                     AND ( DMM.Icresppromo=0
                          OR DMM.DSOBSERVACION IS NULL)
                GROUP BY CP.IDCONSOLIDADO,
                         DMM.CDARTICULO,
                         dmm.qtpiezas) FACTU,-- facturado
               (SELECT DISTINCT CD.IDCONSOLIDADO,
                       CD.CDARTICULO,
                         (
                       case when nvl(cd.qtpiezaspicking,0)>0 then
                         nvl(cd.qtpiezaspicking,0)
                         else
                        nvl( CD.CANTIDADUNIDADPICKING,0)
                       end
                       ) CANT
                  FROM TBLSLV_CONSOLIDADO_DETALLE CD,
                       TBLSLV_CONSOLIDADO_PEDIDO CP,
                       TBLSLV_CONSOLIDADO_PEDIDO_REL CPR,
                       PEDIDOS PEDI,
                       tblslv_consolidado c
                 WHERE CD.IDCONSOLIDADO = CP.Idconsolidado
                 AND c.idconsolidado=cp.idconsolidado
                 AND   CPR.IDPEDIDO_POS = PEDI.IDPEDIDO
                 AND   CPR.IDCONSOLIDADO_PEDIDO = CP.IDCONSOLIDADO_PEDIDO
                 AND   PEDI.ICESTADOSISTEMA IN(4, 5)
                  AND PEDI.id_canal='CO'
                 AND   c.fecha_consolidado >= TRUNC(NVL(pFechaPedido, SYSDATE))
                 ) PICK,    --pickeado
               TBLSLV_CONSOLIDADO C,
               DESCRIPCIONESARTICULOS DA
         WHERE PICK.CDARTICULO = FACTU.CDARTICULO(+)
           AND PICK.IDCONSOLIDADO = FACTU.IDCONSOLIDADO(+)
           AND C.IDCONSOLIDADO = PICK.IDCONSOLIDADO
           AND PICK.CDARTICULO = DA.CDARTICULO
           AND TRUNC(C.FECHA_CONSOLIDADO) >= TRUNC(NVL(pFechaPedido, SYSDATE))
      GROUP BY PICK.IDCONSOLIDADO,
               TRUNC(C.FECHA_CONSOLIDADO),
               PICK.CDARTICULO,
               DA.VLDESCRIPCION
        HAVING SUM(NVL(PICK.CANT, 0)) <> SUM(NVL(FACTU.CANT, 0));
END ReporteDiferenciasFacComi;

/* Reporte Faltantes por Fecha comisionistas Nuevo
Agrupado por Comisionista,fecha y articulos. LM 09/06/2014
*/
PROCEDURE ReporteFaltantesXFechaComi(r_cursor    OUT cursor_type,
                                   pFechaDesde IN date,
                                   pFechaHasta IN date,
                                   pIdComisionista IN pedidos.idcomisionista%TYPE)
 IS
BEGIN
    OPEN r_cursor FOR
    select suc.dssucursal sucursal,
           e.dsrazonsocial Nom_Comi,
           cff.fecha_consolidado fechaconsolidado,
           sec.dsgruposector gruposector,
           (pedi.cdarticulo || ' - ' || da.vldescripcion) articulo,
           round(avg(pedi.preciounitario), 3) preciounitario,
           sum(pedi.cantPedido) unidades_pedidas,
           sum(nvl(facturado.cantFact, 0)) unidades_pickeadas,
           sum(pedi.cantPedido) - sum(nvl(facturado.cantFact, 0)) faltantes,
           round(avg(cdff.qtstock), 3) stock,
           pedi.UXB,
           PKG_SLV_ARTICULOS.GETUBICACIONARTICULOS(pedi.cdarticulo, cff.cdsucursal) UBICACION,
           sum(pedi.CantPiezaPed) piezas_Ped,
           sum(facturado.piezasFact) piezas_Fact
    from (select detConformado.Idpedido,
                 detConformado.Cdarticulo,
                 sum(nvl(detConformado.Qtunidadmedidabase, 0)) CantFact,
                 sum(nvl(detConformado.qtpiezas,0)) piezasFact
          from (select dpc2.idpedido,
                       dpc2.qtunidadmedidabase,
                       dpc2.cdarticulo,
                       dpc2.qtpiezas
                from tblslv_interfaz_pos_conformado dpc2,
                     tblslv_consolidado_pedido_rel  cprF2,
                     tblslv_consolidado_pedido      cpF2,
                     tblslv_consolidado             cf2,
                     pedidos                        pf2
                where dpc2.idpedido = cprf2.idpedido_pos
                   and cprf2.idconsolidado_pedido = cpf2.idconsolidado_pedido
                   and cpf2.idconsolidado = cf2.idconsolidado
                   and pf2.idcomisionista = pIdComisionista
                   and pf2.idpedido = cprf2.idpedido_pos
                   and not exists
                          (select 1
                           from tblslv_pedidogeneradoxfaltante pgf -- no es generado
                           where pgf.idpedidogen = pf2.idpedido)
                   and cpf2.id_canal = 'CO'
                   and cf2.fecha_consolidado between  TRUNC(NVL(pFechaDesde, SYSDATE)) AND TRUNC(NVL(pFechaHasta, SYSDATE))
                union all
                --consoildado generado
                select pgxf.idpedido,
                       dppcf.qtunidadmedidabase,
                       dppcf.cdarticulo,
                       dppcf.qtpiezas
                  from tblslv_pedidogeneradoxfaltante pgxf,
                       tblslv_interfaz_pos_conformado dppcF,
                       tblslv_consolidado_pedido_rel  cprF,
                       tblslv_consolidado_pedido      cpf,
                       tblslv_consolidado             cf,
                       pedidos                        pf
                 where pgxf.idpedidogen = dppcf.idpedido
                   and pgxf.idpedido = cprf.idpedido_pos
                   and cprf.idconsolidado_pedido = cpf.idconsolidado_pedido
                   and cpf.idconsolidado = cf.idconsolidado
                   and cpf.id_canal = 'CO'
                   and pf.idcomisionista = pIdComisionista
                   and pf.idpedido = pgxf.idpedido
                   and cf.fecha_consolidado between  TRUNC(NVL(pFechaDesde, SYSDATE)) AND TRUNC(NVL(pFechaHasta, SYSDATE))
                   ) detConformado
         group by detConformado.Idpedido, detConformado.Cdarticulo) facturado,
        (select dp.idpedido,
               p.idcomisionista,
               dp.cdarticulo,
               sum(dp.qtunidadmedidabase) CantPedido,
               sum(nvl(dp.qtpiezas,0)) CantPiezaPed,
               max(dp.vluxb) UXB,
               round(avg(dp.amprecioUnitario), 3) preciounitario
          from pedidos                       p,
               detallepedidos                dp,
               tblslv_consolidado_pedido_rel cpr,
               tblslv_consolidado_pedido     cp,
               tblslv_consolidado            c
         where p.idpedido = dp.idpedido
           and p.idpedido = cpr.idpedido_pos
           and cpr.idconsolidado_pedido = cp.idconsolidado_pedido
           and cp.idconsolidado = c.idconsolidado
           and not exists
         (select 1
                  from tblslv_pedidogeneradoxfaltante pp
                 where p.idpedido = pp.IdPedidoGen)
           and c.fecha_consolidado between  TRUNC(NVL(pFechaDesde, SYSDATE)) AND TRUNC(NVL(pFechaHasta, SYSDATE))
       and (dp.icresppromo is null or dp.icresppromo = 0)
           and p.id_canal = 'CO'
           and p.idcomisionista = pIdComisionista
        group by p.idcomisionista, dp.idpedido, dp.cdarticulo) pedi,
       tblslv_consolidado_pedido_rel cprff,
       tblslv_consolidado_pedido cpff,
       tblslv_consolidado cff,
       tblslv_consolidado_detalle cdff,
       posapp.descripcionesarticulos da,
       tblslv_grupo_sector sec,
       sucursales suc,
       entidades e
 where pedi.idpedido = facturado.idPedido(+)
   and pedi.cdarticulo = facturado.cdarticulo(+)
   and pedi.idpedido = cprff.idpedido_pos
   and cpff.idconsolidado = cff.idconsolidado
   and pedi.cdarticulo = cdff.cdarticulo
   and cff.idconsolidado = cdff.idconsolidado
   and cdff.cdarticulo = da.cdarticulo
   and cdff.idgrupo_sector = sec.idgrupo_sector
   and cprff.idconsolidado_pedido = cpff.idconsolidado_pedido
   and cff.cdsucursal = suc.cdsucursal
   and pedi.idcomisionista = e.identidad
  --   and (pedi.cantPedido - nvl(facturado.cantFact, 0)) > 0
and (  (nvl(pedi.CantPiezaPed,0)>0 and pedi.CantPiezaPed>nvl(facturado.piezasFact,0))
                  or ( nvl(pedi.CantPiezaPed,0)=0 and
                  pedi.cantPedido   > nvl(facturado.cantFact,0)))
 group by suc.dssucursal,
          e.dsrazonsocial,
          cff.fecha_consolidado,
          sec.dsgruposector,
          pedi.cdarticulo,
          da.vldescripcion,
          pedi.UXB,
          cff.cdsucursal
 order by suc.dssucursal,
          e.dsrazonsocial,
          cff.fecha_consolidado,
          pedi.cdarticulo;

END ReporteFaltantesXFechaComi;
/* Reporte Faltantes por Fecha comisionistas LM 12/02/2014

PROCEDURE ReporteFaltantesXFechaComiX(r_cursor    OUT cursor_type,
                                   pFechaDesde IN date,
                                   pFechaHasta IN date,
                                   pIdComisionista IN pedidos.idcomisionista%TYPE)
IS
BEGIN
    OPEN r_cursor FOR
       SELECT suc.dssucursal sucursal,
            pkg_slv_comisionista.GetNomComisionista(cons.idconsolidado) Nom_Comi,
            cons.fecha_consolidado fechaconsolidado,
            sec.dssector gruposector,
            pick.cdarticulo|| ' - ' || dart.vldescripcion articulo,
            round(pedi.precioun,3) preciounitario,
            SUM (pedi.pedidoUn) unidades_pedidas,
            SUM (pick.pickUn) unidades_pickeadas,
            SUM (pedi.pedidoUn - pick.pickUn) faltantes,
            round(AVG (pick.StockUN),3) stock,
            PKG_SLV_ARTICULOS.CONVERTIRUNIDADES(pick.cdarticulo,1,'BTO','UN',0) UXB,
            PKG_SLV_ARTICULOS.GETUBICACIONARTICULOS(pick.cdarticulo,suc.cdsucursal) UBICACION
       FROM (  SELECT cons.idconsolidado,
                      dp.cdarticulo,
                      AVG (dp.ampreciounitario) precioun,
                      SUM (NVL (dp.qtunidadmedidabase, 0) + NVL (dp.qtpiezas, 0))
                         pedidoUn
               FROM tblslv_consolidado_pedido cped,
                      tblslv_consolidado cons,
                      tblslv_consolidado_pedido_rel cpr,
                      (select ddp.*,p.idcomisionista from pedidos p,detallepedidos ddp where p.idpedido=ddp.idpedido
                      and p.idcomisionista=pIdComisionista )dp
                WHERE     cons.idconsolidado = cped.idconsolidado
                      AND cped.idconsolidado_pedido = cpr.idconsolidado_pedido
                      AND cpr.idpedido_pos = dp.idpedido
                      AND (cped.id_canal ='CO')
                      AND DP.ICRESPPROMO <> 1
             GROUP BY cons.idconsolidado, dp.cdarticulo, dp.idcomisionista) pedi,
            (  SELECT distinct cd.idconsolidado,
                      cd.cdarticulo,
                     NVL (cd.qtstock, 0) StockUN,
                      NVL (cd.cantidadunidadpicking, 0)
                                                            pickUn
                 FROM tblslv_consolidado_pedido cped,
                      tblslv_consolidado_detalle cd
                WHERE cd.idconsolidado = cped.idconsolidado
                      AND (cped.id_canal ='CO')
             ) pick,
            tblslv_consolidado cons,
            sucursales suc,
            descripcionesarticulos dart,
            sectores sec,
            articulos art
      WHERE     pedi.idconsolidado = pick.idconsolidado
            AND pedi.cdarticulo = pick.cdarticulo
            AND pedi.cdarticulo = dart.cdarticulo
            AND pedi.idconsolidado = cons.idconsolidado
            AND cons.cdsucursal = suc.cdsucursal
            AND pedi.cdarticulo = art.cdarticulo
            AND art.cdsector = sec.cdsector
            AND TRIM(DECODE(TRIM(art.CDIDENTIFICADOR),'01','26',art.CDSECTOR))=trim(sec.cdsector)
            and  (pedi.pedidoUn - pick.pickUn) >0
            AND TRUNC(CONS.FECHA_CONSOLIDADO) BETWEEN
            TRUNC(NVL(pFechaDesde, SYSDATE)) AND TRUNC(NVL(pFechaHasta, SYSDATE))
   GROUP BY suc.dssucursal ,suc.cdsucursal,
            cons.fecha_consolidado ,
            cons.idconsolidado,
            sec.dssector ,
            pick.cdarticulo|| ' - ' || dart.vldescripcion ,
            pedi.precioun,
            pick.cdarticulo  ;
END ReporteFaltantesXFechaComiX;
*/
PROCEDURE GetNombreImpresora (r_cursor    OUT cursor_type )
   AS
   BEGIN
     OPEN r_cursor FOR
           select  posapp.getvlparametro('CdImpresoraComi', 'General') p_impresora
           from dual;
   END GetNombreImpresora;

PROCEDURE RepoControlTiempoFactPagSLV (r_cursor    OUT cursor_type
  ,p_fecha Movmateriales.Dtaplicacion%TYPE )
   AS
   BEGIN
     OPEN r_cursor FOR
select distinct cpd.idconsolidado_pedido || '_'||cpd.pagina PEDIDO,
       to_char(ped.dtaplicacion,'dd/mm/yyyy') "FECHA_PEDIDO",
       to_char(cpd.fecha_asignado, 'dd/mm/yy hh24:mi') "ASIGNADO",
       to_char(cpd.fecha_fin_armado, 'dd/mm/yy hh24:mi') "FIN_ARMADO",
       to_char(mm.dtaplicacion, 'dd/mm/yy hh24:mi') "FACTURADO"
from pedidos ped,
     movmateriales mm,
     slvapp.tblslv_consolidado_pedido_rel cpr,
     slvapp.tblslv_consolidado_ped_pag cpd
where ped.idpedido = mm.idpedido
and   mm.dtaplicacion > trunc(p_fecha)
and (ped.id_canal is null or ped.id_canal<>'CO')
and   ped.idpedido = cpr.idpedido_pos
and   cpr.idconsolidado_pedido = cpd.idconsolidado_pedido;
  END RepoControlTiempoFactPagSLV;

PROCEDURE RepoControlTiempoFactSLV (r_cursor    OUT cursor_type
  ,p_fecha Movmateriales.Dtaplicacion%TYPE )
   AS
   BEGIN
     OPEN r_cursor FOR
select distinct cpd.idconsolidado_pedido PEDIDO,
       to_char(ped.dtaplicacion,'dd/mm/yyyy') "FECHA_PEDIDO",
       to_char(cpd.fecha_asignado, 'dd/mm/yy hh24:mi') "ASIGNADO",
       to_char(cpd.fecha_fin_armado, 'dd/mm/yy hh24:mi') "FIN_ARMADO",
       to_char(mm.dtaplicacion, 'dd/mm/yy hh24:mi') "FACTURADO"
from pedidos ped,
     movmateriales mm,
     slvapp.tblslv_consolidado_pedido_rel cpr,
     slvapp.tblslv_consolidado_pedido_det cpd
where ped.idpedido = mm.idpedido
and   mm.dtaplicacion > trunc(p_fecha)
and (ped.id_canal is null or ped.id_canal<>'CO')
and   ped.idpedido = cpr.idpedido_pos
and   cpr.idconsolidado_pedido = cpd.idconsolidado_pedido;
  END RepoControlTiempoFactSLV;

PROCEDURE RepoControlTiempoFactComi(r_cursor    OUT cursor_type
  ,p_fecha Movmateriales.Dtaplicacion%TYPE )
   AS
   BEGIN
     OPEN r_cursor FOR
select distinct cd.idconsolidado Consolidado,
       e.dsrazonsocial Comisionista,
       gs.dsgruposector Sector,
       to_char(max(ped.dtaplicacion),'dd/mm/yyyy') "FECHA_PEDIDO",
       to_char(max(cs.dtfecha_asignado), 'dd/mm/yy hh24:mi') "ASIGNADO",
       to_char(max(cs.dtfecha_cierre), 'dd/mm/yy hh24:mi') "FIN_ARMADO",
       to_char(max(mm.dtaplicacion), 'dd/mm/yy hh24:mi') "FACTURADO"
from pedidos ped,
     movmateriales mm,
     slvapp.tblslv_consolidado_pedido_rel cpr,
     slvapp.tblslv_consolidado_pedido cp,
     slvapp.tblslv_consolidado_detalle cd,
     slvapp.tblslv_consolidado_sector cs,
     slvapp.tblslv_grupo_sector gs,
     entidades e
     where ped.idpedido = mm.idpedido
and   trunc(mm.dtaplicacion) = trunc(p_fecha)
and (ped.id_canal ='CO')
and   ped.idpedido = cpr.idpedido_pos
and cp.idconsolidado=cd.idconsolidado
and   cpr.idconsolidado_pedido = cp.idconsolidado_pedido
and cs.idgrupo_sector=cd.idgrupo_sector
and cs.idconsolidado=cd.idconsolidado
and cs.idgrupo_sector=gs.idgrupo_sector
and ped.idcomisionista=e.identidad
group by cd.idconsolidado,e.dsrazonsocial,gs.dsgruposector
order by cd.idconsolidado;
 END RepoControlTiempoFactComi;

END PKG_SLV_REPORTES;
/
