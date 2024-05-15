CREATE OR REPLACE VIEW DW_PEDIDOS_V2 AS
SELECT d.iddoctrx iddoctrx,
          p.idpedido idpedido,
          TRIM (d.cdsucursal) cdsucursal,
          TRIM (d.cdestadocomprobante) cdestadocomprobante,
          TRIM (d.cdcomprobante) cdcomprobante,
          TRIM (d.cdpuntoventa) cdpuntoventa,
          d.sqcomprobante sqcomprobante,
          TO_CHAR (d.dtdocumento, 'yyyymmdd') fechadocumento,
          TO_CHAR (p.dtentrega, 'yyyymmdd') fechaentrega,
          TO_CHAR (p.dtaplicacion, 'yyyymmdd') fechaaplicacion,
          d.dtdocumento dtdocumento,
          p.dtentrega dtentrega,
          TO_CHAR (p.dtaplicacion, 'hh24miss') dtaplicacion,
          d.identidad identidad,                                 --> entidades
          p.idpersonaresponsable idresponsable,                   --> personas
          p.idvendedor idvendedor,                                --> personas
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
          rentapedidos r/*,
          parametrossistema ps*/
    WHERE     1 = 1
          AND d.iddoctrx = p.iddoctrx
          AND d.iddoctrx = r.iddoctrx(+)
         /* AND ps.nmparametrosistema = 'CDSucursal'
          AND ps.vlparametro = TRIM (d.cdsucursal)*/
          AND NOT EXISTS
                     (SELECT 1
                        FROM slvapp.tblslvpedidogeneradoxfaltante pxf
                       WHERE pxf.idpedidogen = p.idpedido)
;
