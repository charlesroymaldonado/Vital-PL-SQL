create materialized view TBLCTRLSTOCKART
on prebuilt table
refresh force on demand
as
WITH --STOCK INICIAL
stockinicialsap AS
 (SELECT tblst.cdarticulo, SUM(tblst.qtstock) qtstock
    FROM (SELECT aa.cdarticulo, aa.qtstock
            FROM articulosalmacen aa
           WHERE aa.cdalmacen =
                 SUBSTR(getvlparametro('CDSucursal', 'General'), 3, 2) ||
                 '01    '
             AND aa.cdsucursal =
                 getvlparametro('CDSucursal', 'General') || '    '
          UNION
          -- Stock inicial en el almacen carniceria
          SELECT aa.cdarticulo, aa.qtstock
            FROM articulosalmacen aa
           WHERE aa.cdalmacen =
                 'CA' ||
                 SUBSTR(getvlparametro('CDSucursal', 'General'), 3, 2) ||
                 '    '
             AND aa.cdsucursal =
                 getvlparametro('CDSucursal', 'General') || '    ') tblst
   GROUP BY tblst.cdarticulo),
--CANTIDAD FACTURADA
CantFacturada AS
 (SELECT dm.cdarticulo,
         NVL(SUM(NVL(dm.QTUnidadMedidaBase, 0)), 0) QTUnidadMedidaBase
    FROM detalleMovMateriales      dm,
         comprobantes              c,
         filtroestadoscomprobantes f,
         documentos                d
   WHERE NOT EXISTS (SELECT ar.CDArticulo
            FROM ArticulosNOComerciales ar
           WHERE ar.cdarticulo = dm.cdarticulo)
     AND dm.cdarticulo > '0000003'
     AND dm.cdarticulo NOT LIKE 'A%'
     AND dm.idmovmateriales = d.idmovmateriales
     AND dm.icresppromo <> 1
     AND c.cdmovimiento IS NOT NULL
     AND c.cdcomprobante = d.cdcomprobante
     AND f.cdoperacion = '33'
     AND f.cdestado = d.cdestadocomprobante
     AND f.cdcomprobante = d.cdcomprobante
     AND d.Dtdocumento > TRUNC(SYSDATE)
   GROUP BY dm.cdarticulo),
-- CANTIDAD FACTURAS PROFORMA
CantFacturasProf AS
 (SELECT dm.cdarticulo,
         NVL(SUM(NVL(dm.QTUnidadMedidaBase, 0)), 0) QTUnidadMedidaBase
    FROM detalleMovMateriales dm,
         (SELECT d.*
            FROM documentos d
           WHERE d.cdestadocomprobante IN (1, 2)
             AND d.idcuenta IS NOT NULL
             AND d.identidadreal IS NOT NULL
             AND d.cdcomprobante LIKE '%PROF%'
             AND d.dtdocumento > TRUNC(SYSDATE)) facturasprof
   WHERE dm.idmovmateriales = facturasprof.idmovmateriales
   GROUP BY dm.cdarticulo),
-- CANTIDAD PICKEADA
CantPickeada AS
 (SELECT tablapick.cdarticulo, SUM(qtpick) qtpick
    FROM ( --- SLV Multicanal
          SELECT td.cdarticulo,
                  NVL(SUM(NVL(td.qtunidadmedidabasepicking, 0)), 0) qtpick
            FROM tblslvtarea ta,
                  tblslvtareadet td,
                  (SELECT DISTINCT cp.idconsolidadopedido
                     FROM tblslvconsolidadopedido cp,

                          tblslvconsolidadopedidorel cpr,
                          pedidos                    p
                    WHERE cp.idconsolidadopedido = cpr.idconsolidadopedido
                      AND cpr.idpedido = p.idpedido
                      AND p.id_canal IN ('TE', 'VE')
                      AND cp.dtinsert > SYSDATE - 15
                      AND cp.cdestado <> 14 --facturado pedido
                      AND NOT EXISTS (SELECT 1
                             FROM movmateriales mm
                            WHERE mm.idpedido = p.idpedido)
                      AND NOT EXISTS
                    (SELECT 1
                             FROM direccionesentidades de, documentos docp
                            WHERE docp.iddoctrx = p.iddoctrx
                              AND docp. identidadreal = de. identidad
                              AND p. cdtipodireccion = de. cdtipodireccion
                              AND p. sqdireccion = de. sqdireccion
                              AND de. cdprovincia = '23')) con
           WHERE ta.idconsolidadopedido = con.idconsolidadopedido
             and ta.idtarea = td.idtarea
           GROUP BY td.cdarticulo
          UNION ALL
          -- union con remitos de distribucion de faltantes
          SELECT rd.cdarticulo,
                  NVL(SUM(NVL(rd.qtunidadmedidabasepicking, 0)), 0) qtpick
            FROM tblslvremito re,
                  tblslvremitodet rd,
                  tblslvpedfaltanterel pf,
                  (SELECT DISTINCT cp.idconsolidadopedido
                     FROM tblslvconsolidadopedido cp,

                          tblslvconsolidadopedidorel cpr,
                          pedidos                    p
                    WHERE cp.idconsolidadopedido = cpr.idconsolidadopedido
                      AND cpr.idpedido = p.idpedido
                      AND p.id_canal IN ('TE', 'VE')
                      AND cp.dtinsert > SYSDATE - 15
                      AND cp.cdestado <> 14 --facturado pedido
                      AND NOT EXISTS (SELECT 1
                             FROM movmateriales mm
                            WHERE mm.idpedido = p.idpedido)
                      AND NOT EXISTS
                    (SELECT 1
                             FROM direccionesentidades de, documentos docp
                            WHERE docp.iddoctrx = p.iddoctrx
                              AND docp. identidadreal = de. identidad
                              AND p. cdtipodireccion = de. cdtipodireccion
                              AND p. sqdireccion = de. sqdireccion
                              AND de. cdprovincia = '23')) con2
           WHERE re.idremito = rd.idremito
             and re.idpedfaltanterel = pf.idpedfaltanterel
             and pf.idconsolidadopedido = con2.idconsolidadopedido
           GROUP BY rd.cdarticulo
          UNION ALL
          SELECT td.cdarticulo,
                  NVL(SUM(NVL(td.qtunidadmedidabasepicking, 0)), 0) qtpick
            FROM tblslvtarea ta,
                  tblslvtareadet td,
                  (SELECT DISTINCT cp.idconsolidadocomi
                     FROM tblslvconsolidadopedido cp,
                          slvapp.tblslvconsolidadocomi cc,
                          tblslvconsolidadopedidorel cpr,
                          pedidos                    p
                    WHERE cp.idconsolidadopedido = cpr.idconsolidadopedido
                      AND cc.idconsolidadocomi = cp.idconsolidadocomi
                      AND cpr.idpedido = p.idpedido
                      AND cc.cdestado <> 29 --facturado pedido
                      AND p.id_canal IN ('CO')
                      AND cp.dtinsert > SYSDATE - 15
                      AND NOT EXISTS (SELECT 1
                             FROM movmateriales mm
                            WHERE mm.idpedido = p.idpedido)
                      AND NOT EXISTS
                    (SELECT 1
                             FROM direccionesentidades de, documentos docp
                            WHERE docp.iddoctrx = p.iddoctrx
                              AND docp. identidadreal = de. identidad
                              AND p. cdtipodireccion = de. cdtipodireccion
                              AND p. sqdireccion = de. sqdireccion
                              AND de. cdprovincia = '23')) con
           WHERE ta.idconsolidadocomi = con.idconsolidadocomi
             and ta.idtarea = td.idtarea
           GROUP BY td.cdarticulo
          --- SLV Viejo
          UNION ALL
          SELECT cpd.cdarticulo,
                  NVL(SUM(NVL(cpd.QTUNIDADBASEPICKING, 0)), 0) qtpick
            FROM tblslv_consolidado_pedido_det cpd,
                  (SELECT DISTINCT cp.idconsolidado_pedido
                     FROM tblslv_consolidado_pedido     cp,
                          tblslv_consolidado            c,
                          tblslv_consolidado_pedido_rel cpr,
                          pedidos                       p
                    WHERE c.idconsolidado = cp.idconsolidado
                      AND cp.idconsolidado_pedido = cpr.idconsolidado_pedido
                      AND cpr.idpedido_pos = p.idpedido
                      AND p.id_canal IN ('TE', 'VE')
                      AND c.fecha_consolidado > SYSDATE - 15
                      AND cp.idestado <> 9
                      AND NOT EXISTS (SELECT 1
                             FROM movmateriales mm
                            WHERE mm.idpedido = p.idpedido)
                      AND NOT EXISTS
                    (SELECT 1
                             FROM direccionesentidades de, documentos docp
                            WHERE docp.iddoctrx = p.iddoctrx
                              AND docp. identidadreal = de. identidad
                              AND p. cdtipodireccion = de. cdtipodireccion
                              AND p. sqdireccion = de. sqdireccion
                              AND de. cdprovincia = '23')) con
           WHERE cpd.idconsolidado_pedido = con.idconsolidado_pedido
           GROUP BY cpd.cdarticulo
          UNION ALL
          SELECT cd.cdarticulo,
                  NVL(SUM(NVL(cd.cantidadunidadpicking, 0)), 0) qtpick
            FROM tblslv_consolidado_detalle cd,
                  (SELECT DISTINCT cp.idconsolidado
                     FROM tblslv_consolidado_pedido     cp,
                          tblslv_consolidado            c,
                          tblslv_consolidado_pedido_rel cpr,
                          pedidos                       p
                    WHERE c.idconsolidado = cp.idconsolidado
                      AND cp.idconsolidado_pedido = cpr.idconsolidado_pedido
                      AND cpr.idpedido_pos = p.idpedido
                      AND p.id_canal IN ('CO')
                      AND c.fecha_consolidado > SYSDATE - 15
                      AND c.idestado <> 12
                      AND NOT EXISTS (SELECT 1
                             FROM movmateriales mm
                            WHERE mm.idpedido = p.idpedido)
                      AND NOT EXISTS
                    (SELECT 1
                             FROM direccionesentidades de, documentos docp
                            WHERE docp.iddoctrx = p.iddoctrx
                              AND docp. identidadreal = de. identidad
                              AND p. cdtipodireccion = de. cdtipodireccion
                              AND p. sqdireccion = de. sqdireccion
                              AND de. cdprovincia = '23')) con
           WHERE cd.idconsolidado = con.idconsolidado
           GROUP BY cd.cdarticulo) tablapick
   GROUP BY tablapick.cdarticulo),
--CANTIDAD POR FACTURAS EN CONTROL
CantCtrlPuertaFact AS
 (SELECT ms.cdarticulo,
         NVL(SUM(NVL(ms.QTUnidadMedidaBase, 0)), 0) QTUnidadMedidaBase
    FROM tblcontrolpuertamovstock ms
   WHERE ms.dtmovstock > TRUNC(SYSDATE)
     AND ms.cdoperacion = 'FC'
   GROUP BY ms.cdarticulo),
--CANTIDAD POR NOTAS DE CREDITO
CantPorNC AS
 (SELECT dm.cdarticulo,
         NVL(SUM(NVL(dm.QTUnidadMedidaBase, 0)), 0) QTUnidadMedidaBase
    FROM detalleMovMateriales      dm,
         tbldocumento_control      tc,
         tblmotivodocumento        tm,
         filtroestadoscomprobantes f,
         documentos                d
   WHERE NOT EXISTS (SELECT arnc.CDArticulo
            FROM ArticulosNOComerciales arnc
           WHERE arnc.CDArticulo = dm.CdArticulo)
     AND dm.CdArticulo > '0000003'
     AND dm.CdArticulo NOT LIKE 'A%'
     AND dm.idmovmateriales = d.idmovmateriales
     AND dm.icresppromo <> 1
     AND d.iddoctrx = tc.iddoctrxgen(+)
     AND tc.idmotivodoc = tm.idmotivodoc(+)
     AND f.cdoperacion = '49'
     AND f.cdestado = d.cdestadocomprobante
     AND f.cdcomprobante = d.cdcomprobante
     AND d.Dtdocumento > TRUNC(SYSDATE)
   GROUP BY dm.CdArticulo),
-- CANTIDAD NOTAS DE CREDITO POR CONTROL
CantNCCtrlPuerta AS
 (SELECT ms.cdarticulo,
         NVL(SUM(NVL(ms.QTUnidadMedidaBase, 0)), 0) QTUnidadMedidaBase
    FROM tblcontrolpuertamovstock ms
   WHERE ms.dtmovstock > TRUNC(SYSDATE)
     AND ms.cdoperacion = 'NC'
   GROUP BY ms.cdarticulo)
--ARMO EL SELECT
SELECT aaa.cdarticulo,
       (NVL(ssa.qtstock, 0) - NVL(cfa.QTUnidadMedidaBase, 0) -
       NVL(cfp.QTUnidadMedidaBase, 0) - NVL(ccp.qtpick, 0) -
       NVL(ccf.QTUnidadMedidaBase, 0) + NVL(cnc.QTUnidadMedidaBase, 0) +
       NVL(cncc.QTUnidadMedidaBase, 0)) stock
  FROM articulos          aaa,
       stockinicialsap    ssa,
       CantFacturada      cfa,
       CantFacturasProf   cfp,
       CantPickeada       ccp,
       CantCtrlPuertaFact ccf,
       CantPorNC          cnc,
       CantNCCtrlPuerta   cncc
 WHERE aaa.cdarticulo = ssa.cdarticulo(+)
   AND aaa.cdarticulo = cfa.cdarticulo(+)
   AND aaa.cdarticulo = cfp.cdarticulo(+)
   AND aaa.cdarticulo = ccf.cdarticulo(+)
   AND aaa.cdarticulo = cnc.cdarticulo(+)
   AND aaa.cdarticulo = cncc.cdarticulo(+)
   AND aaa.cdarticulo = ccp.cdarticulo(+);
