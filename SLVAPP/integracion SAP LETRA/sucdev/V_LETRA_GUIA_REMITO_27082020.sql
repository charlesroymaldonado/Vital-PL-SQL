CREATE OR REPLACE VIEW V_LETRA_GUIA_REMITO AS
SELECT "IDPEDIDO",
            "NROGUIA",
            "ESTADO",
            "NROREMITO"
       FROM ( SELECT DISTINCT
                    TRIM (fg.cdsucursal) || rel.idconsolidadopedido idpedido,
                    fg.sqcomprobante nroguia,
                    ec.dsestado estado,
                    '3' || LPAD (TO_CHAR (re.idremito), 9, '0') nroremito
               FROM tblslvremito                      re,
                    tblslvtarea                       ta, 
                    tblslvconsolidadopedidorel        rel,
                    pedidos                           pe,
                    documentos                        fc,
                    movmateriales                     mm,
                    tbldetalleguia                    dg,
                    documentos                        fg,
                    guiasdetransporte                 gt,
                    estadocomprobantes                ec
              WHERE     rel.idconsolidadopedido = ta.idconsolidadopedido
                    AND ta.idtarea = re.idtarea
                    AND pe.idpedido = rel.idpedido
                    AND mm.idpedido = pe.idpedido
                    AND fc.idmovmateriales = mm.idmovmateriales
                    AND dg.iddoctrx = fc.iddoctrx
                    AND fg.iddoctrx = gt.iddoctrx
                    AND gt.idguiadetransporte = dg.idguiadetransporte
                    AND ec.cdcomprobante = fg.cdcomprobante
                    AND gt.icestado = ec.cdestado
                    AND fc.dtdocumento > TRUNC (SYSDATE) - 30
          UNION ALL
          --remitos de distribución automática
             SELECT DISTINCT
                    TRIM (fg.cdsucursal) || rel.idconsolidadopedido idpedido,
                    fg.sqcomprobante nroguia,
                    ec.dsestado estado,
                    '3' || LPAD (TO_CHAR (re.idremito), 9, '0') nroremito
               FROM tblslvremito                      re,                    
                    tblslvpedfaltanterel              frel,
                    tblslvconsolidadopedidorel        rel,
                    pedidos                           pe,
                    documentos                        fc,
                    movmateriales                     mm,
                    tbldetalleguia                    dg,
                    documentos                        fg,
                    guiasdetransporte                 gt,
                    estadocomprobantes                ec
              WHERE     re.idpedfaltanterel = frel.idpedfaltanterel
                    AND frel.idconsolidadopedido = rel.idconsolidadopedido                    
                    AND pe.idpedido = rel.idpedido
                    AND mm.idpedido = pe.idpedido
                    AND fc.idmovmateriales = mm.idmovmateriales
                    AND dg.iddoctrx = fc.iddoctrx
                    AND fg.iddoctrx = gt.iddoctrx
                    AND gt.idguiadetransporte = dg.idguiadetransporte
                    AND ec.cdcomprobante = fg.cdcomprobante
                    AND gt.icestado = ec.cdestado
                    AND fc.dtdocumento > TRUNC (SYSDATE) - 30         
             UNION ALL
            --pedidos de salon 
             SELECT DISTINCT
                       TRIM (fg.cdsucursal)
                    || FG.sqcomprobante
                    || SUBSTR (fg.cdcomprobante, 4, 1)
                    || SUBSTR (fg.cdpuntoventa, 1, 4)
                       idpedido,
                    dgt.sqcomprobante nroguia,
                    ec.dsestado estado,
                    co.cdcodbardgi || LPAD (TO_CHAR (fg.sqsistema), 14, '0')
                       nroremito
               FROM guiasdetransporte g,
                    documentos dgt,
                    documentos fg,
                    tbldetalleguia dg,
                    movmateriales mm,
                    pedidos pe,
                    documentos dpe,
                    estadocomprobantes ec,
                    comprobantes co
              WHERE     g.iddoctrx = dgt.iddoctrx
                    AND fg.iddoctrx = dg.iddoctrx
                    AND g.idguiadetransporte = dg.idguiadetransporte
                    AND mm.idpedido = pe.idpedido
                    AND mm.idmovmateriales = fg.idmovmateriales
                    AND dpe.iddoctrx = pe.iddoctrx
                    AND ec.cdestado = g.icestado
                    AND dgt.cdcomprobante = ec.cdcomprobante
                    AND pe.id_canal = 'SA'
                    AND co.cdcomprobante = fg.cdcomprobante
                    AND pe.dtaplicacion > TRUNC (SYSDATE) - 30) v
   ORDER BY v.idpedido, v.NROGUIA ASC;
