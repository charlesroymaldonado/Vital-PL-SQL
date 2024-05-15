CREATE OR REPLACE VIEW V_LETRA_GUIA_ESTADO AS
SELECT "IDPEDIDO", "NROGUIA", "ESTADO"
       FROM (SELECT DISTINCT
                    TRIM (fg.cdsucursal) || cp.idconsolidado_pedido idpedido,
                    fg.sqcomprobante nroguia,
                    ec.dsestado estado
               FROM tblslv_consolidado_pedido cp,
                    tblslv_consolidado_pedido_rel rel,
                    pedidos pe,
                    documentos fc,
                    movmateriales mm,
                    tbldetalleguia dg,
                    documentos fg,
                    guiasdetransporte gt,
                    estadocomprobantes ec
              WHERE     rel.idconsolidado_pedido = cp.idconsolidado_pedido
                    AND pe.idpedido = rel.idpedido_pos
                    AND mm.idpedido = pe.idpedido
                    AND fc.idmovmateriales = mm.idmovmateriales
                    AND dg.iddoctrx = fc.iddoctrx
                    AND fg.iddoctrx = gt.iddoctrx
                    AND gt.idguiadetransporte = dg.idguiadetransporte
                    AND ec.cdcomprobante = fg.cdcomprobante
                    AND gt.icestado = ec.cdestado
                    AND mm.id_canal <> 'SA'
                    AND fc.dtdocumento > TRUNC (SYSDATE) - 30
             UNION ALL
             SELECT DISTINCT
                       TRIM (fg.cdsucursal)
                    || FC.sqcomprobante
                    || SUBSTR (fc.cdcomprobante, 4, 1)
                    || SUBSTR (fc.cdpuntoventa, 1, 4)
                       idpedido,
                    fg.sqcomprobante nroguia,
                    ec.dsestado estado
               FROM pedidos pe,
                    documentos fc,
                    documentos dp,
                    movmateriales mm,
                    tbldetalleguia dg,
                    documentos fg,
                    guiasdetransporte gt,
                    estadocomprobantes ec
              WHERE     mm.idpedido = pe.idpedido
                    AND fc.idmovmateriales = mm.idmovmateriales
                    AND dg.iddoctrx = fc.iddoctrx
                    AND fg.iddoctrx = gt.iddoctrx
                    AND dp.iddoctrx = pe.iddoctrx
                    AND gt.idguiadetransporte = dg.idguiadetransporte
                    AND ec.cdcomprobante = fg.cdcomprobante
                    AND gt.icestado = ec.cdestado
                    AND mm.id_canal = 'SA'
                    AND fc.dtdocumento > TRUNC (SYSDATE) - 30) v
   ORDER BY v.idpedido, v.nroguia;
