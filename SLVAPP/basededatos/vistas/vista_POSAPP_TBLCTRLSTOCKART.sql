create materialized view POSAPP.TBLCTRLSTOCKART
on prebuilt table
refresh force on demand
as
WITH --STOCK INICIAL
     stockinicialsap AS (  SELECT tblst.cdarticulo, SUM (tblst.qtstock) qtstock
                             FROM (SELECT aa.cdarticulo, aa.qtstock
                                     FROM articulosalmacen aa
                                    WHERE aa.cdalmacen =
                                             SUBSTR (
                                                getvlparametro ('CDSucursal',
                                                                'General'),
                                                3,
                                                2)
                                             || '01    '
                                          AND aa.cdsucursal =
                                                 getvlparametro ('CDSucursal',
                                                                 'General')
                                                 || '    '
                                   UNION
                                   -- Stock inicial en el almacen carniceria
                                   SELECT aa.cdarticulo, aa.qtstock
                                     FROM articulosalmacen aa
                                    WHERE aa.cdalmacen =
                                             'CA'
                                             || SUBSTR (
                                                   getvlparametro (
                                                      'CDSucursal',
                                                      'General'),
                                                   3,
                                                   2)
                                             || '    '
                                          AND aa.cdsucursal =
                                                 getvlparametro ('CDSucursal',
                                                                 'General')
                                                || '    ') tblst
                         GROUP BY tblst.cdarticulo),
     --CANTIDAD FACTURADA
     CantFacturada
        AS (  SELECT dm.cdarticulo,
                     NVL (SUM (NVL (dm.QTUnidadMedidaBase, 0)), 0)
                        QTUnidadMedidaBase
                FROM detalleMovMateriales dm,
                     comprobantes c,
                     filtroestadoscomprobantes f,
                     documentos d
               WHERE     NOT EXISTS
                                (SELECT ar.CDArticulo
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
                     AND d.Dtdocumento > TRUNC (SYSDATE)
            GROUP BY dm.cdarticulo),
     -- CANTIDAD FACTURAS PROFORMA
     CantFacturasProf
        AS (  SELECT dm.cdarticulo,
                     NVL (SUM (NVL (dm.QTUnidadMedidaBase, 0)), 0)
                        QTUnidadMedidaBase
                FROM detalleMovMateriales dm,
                     (SELECT d.*
                        FROM documentos d
                       WHERE     d.cdestadocomprobante IN (1, 2)
                             AND d.idcuenta IS NOT NULL
                             AND d.identidadreal IS NOT NULL
                             AND d.cdcomprobante LIKE '%PROF%'
                             AND d.dtdocumento > TRUNC (SYSDATE)) facturasprof
               WHERE dm.idmovmateriales = facturasprof.idmovmateriales
            GROUP BY dm.cdarticulo),
     -- CANTIDAD PICKEADA
     CantPickeada AS (  SELECT tablapick.cdarticulo, SUM (qtpick) qtpick
                          FROM (  SELECT cpd.cdarticulo,
                                         NVL (
                                            SUM (
                                               NVL (cpd.qtunidadmedidabasepicking, 0)),
                                            0)
                                            qtpick
                                    FROM slvapp.tblslvconsolidadopedidodet cpd,
                                         (SELECT DISTINCT cp.idconsolidadopedido
                                            FROM slvapp.tblslvconsolidadopedido cp,                                               
                                                 slvapp.tblslvconsolidadopedidorel cpr,
                                                 pedidos p
                                           WHERE cp.idconsolidadopedido =
                                                        cpr.idconsolidadopedido
                                                 AND cpr.idpedido =
                                                        p.idpedido
                                                 AND p.id_canal IN ('TE', 'VE')
                                                 AND cp.dtinsert >
                                                        SYSDATE - 15
                                                 AND cp.cdestado <> 10 -- creado
                                                 AND NOT EXISTS
                                                            (SELECT 1
                                                               FROM movmateriales mm
                                                              WHERE mm.idpedido =
                                                                       p.idpedido)
                                                 AND NOT EXISTS
                                                            (SELECT 1
                                                               FROM direccionesentidades de,
                                                                    documentos docp
                                                              WHERE docp.iddoctrx =
                                                                       p.iddoctrx
                                                                    AND docp.
                                                                        identidadreal =
                                                                           de.
                                                                           identidad
                                                                    AND p.
                                                                        cdtipodireccion =
                                                                           de.
                                                                           cdtipodireccion
                                                                    AND p.
                                                                        sqdireccion =
                                                                           de.
                                                                           sqdireccion
                                                                    AND de.
                                                                        cdprovincia =
                                                                           '23')) con
                                   WHERE cpd.idconsolidadopedido =
                                            con.idconsolidadopedido
                                GROUP BY cpd.cdarticulo
                                UNION ALL
                                  SELECT cd.cdarticulo,
                                         NVL (
                                            SUM (
                                               NVL (cd.qtunidadmedidabasepicking, 0)),
                                            0)
                                            qtpick
                                    FROM slvapp.tblslvconsolidadopedidodet  cd,
                                         (SELECT DISTINCT cp.idconsolidadopedido
                                            FROM slvapp.tblslvconsolidadopedido cp,                                               
                                                 slvapp.tblslvconsolidadopedidorel cpr,
                                                 pedidos p
                                           WHERE cp.idconsolidadopedido =
                                                        cpr.idconsolidadopedido
                                                 AND cpr.idpedido =
                                                        p.idpedido
                                                 AND p.id_canal IN ('CO')
                                                 AND cp.dtinsert >
                                                        SYSDATE - 15
                                                 AND cp.cdestado <> 10 -- creado
                                                 AND NOT EXISTS
                                                            (SELECT 1
                                                               FROM movmateriales mm
                                                              WHERE mm.idpedido =
                                                                       p.idpedido)
                                                 AND NOT EXISTS
                                                            (SELECT 1
                                                               FROM direccionesentidades de,
                                                                    documentos docp
                                                              WHERE docp.iddoctrx =
                                                                       p.iddoctrx
                                                                    AND docp.
                                                                        identidadreal =
                                                                           de.
                                                                           identidad
                                                                    AND p.
                                                                        cdtipodireccion =
                                                                           de.
                                                                           cdtipodireccion
                                                                    AND p.
                                                                        sqdireccion =
                                                                           de.
                                                                           sqdireccion
                                                                    AND de.
                                                                        cdprovincia =
                                                                           '23')) con
                                   WHERE cd.idconsolidadopedido = con.idconsolidadopedido
                                GROUP BY cd.cdarticulo) tablapick
                      GROUP BY tablapick.cdarticulo),
     --CANTIDAD POR FACTURAS EN CONTROL
     CantCtrlPuertaFact
        AS (  SELECT ms.cdarticulo,
                     NVL (SUM (NVL (ms.QTUnidadMedidaBase, 0)), 0)
                        QTUnidadMedidaBase
                FROM tblcontrolpuertamovstock ms
               WHERE ms.dtmovstock > TRUNC (SYSDATE) AND ms.cdoperacion = 'FC'
            GROUP BY ms.cdarticulo),
     --CANTIDAD POR NOTAS DE CREDITO
     CantPorNC
        AS (  SELECT dm.cdarticulo,
                     NVL (SUM (NVL (dm.QTUnidadMedidaBase, 0)), 0)
                        QTUnidadMedidaBase
                FROM detalleMovMateriales dm,
                     tbldocumento_control tc,
                     tblmotivodocumento tm,
                     filtroestadoscomprobantes f,
                     documentos d
               WHERE     NOT EXISTS
                                (SELECT arnc.CDArticulo
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
                     AND d.Dtdocumento > TRUNC (SYSDATE)
            GROUP BY dm.CdArticulo),
     -- CANTIDAD NOTAS DE CREDITO POR CONTROL
     CantNCCtrlPuerta
        AS (  SELECT ms.cdarticulo,
                     NVL (SUM (NVL (ms.QTUnidadMedidaBase, 0)), 0)
                        QTUnidadMedidaBase
                FROM tblcontrolpuertamovstock ms
               WHERE ms.dtmovstock > TRUNC (SYSDATE) AND ms.cdoperacion = 'NC'
            GROUP BY ms.cdarticulo)
--ARMO EL SELECT
SELECT aaa.cdarticulo,
       (  NVL (ssa.qtstock, 0)
        - NVL (cfa.QTUnidadMedidaBase, 0)
        - NVL (cfp.QTUnidadMedidaBase, 0)
        - NVL (ccp.qtpick, 0)
        - NVL (ccf.QTUnidadMedidaBase, 0)
        + NVL (cnc.QTUnidadMedidaBase, 0)
        + NVL (cncc.QTUnidadMedidaBase, 0))
          stock
  FROM articulos aaa,
       stockinicialsap ssa,
       CantFacturada cfa,
       CantFacturasProf cfp,
       CantPickeada ccp,
       CantCtrlPuertaFact ccf,
       CantPorNC cnc,
       CantNCCtrlPuerta cncc
WHERE     aaa.cdarticulo = ssa.cdarticulo(+)
       AND aaa.cdarticulo = cfa.cdarticulo(+)
       AND aaa.cdarticulo = cfp.cdarticulo(+)
       AND aaa.cdarticulo = ccf.cdarticulo(+)
       AND aaa.cdarticulo = cnc.cdarticulo(+)
       AND aaa.cdarticulo = cncc.cdarticulo(+)
       AND aaa.cdarticulo = ccp.cdarticulo(+);
