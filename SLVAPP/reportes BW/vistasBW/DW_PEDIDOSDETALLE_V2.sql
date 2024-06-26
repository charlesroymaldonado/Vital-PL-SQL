CREATE OR REPLACE VIEW DW_PEDIDOSDETALLE_V2 AS
SELECT dp.idpedido idpedido,
          dp.sqdetallepedido sqdetallepedido,
          p.iddoctrx iddoctrx,
          TRIM (dp.cdarticulo) cdarticulo,
          trim(dp.cdpromo)        cdpromo,
          decode(nvl(dp.icresppromo,0), 0, '0', '1')     icpromo,
          TRIM (dp.dsobservacion) dsobservacion,
          dp.qtunidadpedido qtunidadpedido,
          TRIM (dp.cdunidadmedida) cdunidadmedida,
          dp.vluxb vluxb,
          dp.qtunidadmedidabase qtunidadmedidabase,
          dp.qtpiezas qtpiezas,
          dp.ampreciounitario ampreciounitario,
          dp.amlinea amlinea,
          d.dtdocumento,
          TRIM (d.cdsucursal) cdsucursal
     FROM documentos d,
          pedidos p,
          detallepedidos dp,
          parametrossistema ps
    WHERE     1 = 1
          AND dp.idpedido = p.idpedido
          AND d.iddoctrx = p.iddoctrx
          AND ps.nmparametrosistema = 'CDSucursal'
          AND ps.vlparametro = TRIM (d.cdsucursal)
          AND NOT EXISTS
                     (SELECT 1
                        FROM slvapp.tblslvpedidogeneradoxfaltante pxf
                       WHERE pxf.idpedidogen = p.idpedido);
