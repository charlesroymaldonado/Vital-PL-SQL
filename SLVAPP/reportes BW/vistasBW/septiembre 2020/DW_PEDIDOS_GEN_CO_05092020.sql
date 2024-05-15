CREATE OR REPLACE VIEW DW_PEDIDOS_GEN_CO AS
SELECT d.iddoctrx iddoctrx,
          pxf.idpedido idpedidopadre,
          p.idpedido idpedidohijo,
          TRIM (d.cdsucursal) cdsucursal,
          TRIM (d.cdestadocomprobante) cdestadocomprobante,
          TRIM (d.cdcomprobante) cdcomprobante,
          TRIM (d.cdpuntoventa) cdpuntoventa,
          d.sqcomprobante sqcomprobante,
          d.dtdocumento,
          p.dtentrega,
          p.dtaplicacion,
          d.identidad,                                 --> entidades
          p.idpersonaresponsable,                   --> personas
          p.idvendedor,                                --> personas
          TRIM (p.cdcondicionventa) cdcondicionventa,
          TRIM (p.cdlugar) cdlugar,
          TRIM (p.cdsituacioniva) cdsituacioniva,
          p.icestadosistema icestadosistema,
          TRIM (r.tiporenta) tiporenta,
          NVL (r.renta_ori, 0) renta_ori,
          NVL (p.qtmateriales, 0) qtmateriales,
          NVL (d.amdocumento, 0) amdocumento,
          NVL (d.amnetodocumento, 0) amnetodocumento,
          NVL (d.amrecargo, 0) amrecargo,
          EsPedidoDeReplica (p.idpedido) EsPedidoDeReplica,
          SUBSTR (d.dsreferencia, 2, 13) AS dsreferencia,
          -- si es TE el pkg averigua si en realidad es EC
          DECODE (p.id_canal,
                  'TE', pkg_canal.GetCanalVentaPedidoBW (p.idpedido),
                  p.id_canal)
             AS canal,
          p.transid AS transid,
          p.idcomisionista AS idcomisionista
     FROM documentos d,
          pedidos p,
          tblslvpedidogeneradoxfaltante pxf,
          rentapedidos r/*,
          parametrossistema ps*/
    WHERE     1 = 1
          AND d.iddoctrx = p.iddoctrx
          AND d.iddoctrx = r.iddoctrx(+)
         /* AND ps.nmparametrosistema = 'CDSucursal'
          AND ps.vlparametro = TRIM (d.cdsucursal)*/
          AND p.idpedido = pxf.idpedidogen
;
