        select 
      distinct do.cdcomprobante,
               do.cdpuntoventa,
               do.sqcomprobante,
               dmm.*
          from tblslvconsolidadopedido     cp,
               tblslvconsolidadopedidorel  cprel,
               pedidos                     pe,
               detallepedidos              dp,
               movmateriales               mm,
               detallemovmateriales        dmm,
               documentos                  do
         where cp.idconsolidadopedido = cprel.idconsolidadopedido
           and cprel.idpedido = pe.idpedido
           and pe.idpedido = mm.idpedido
           and pe.idpedido = dp.idpedido
           and mm.idmovmateriales = do.idmovmateriales
           and mm.idmovmateriales = dmm.idmovmateriales          
           and cp.idconsolidadopedido = &p_idconsolidado;
           
                   select 
      distinct do.cdcomprobante,
               do.cdpuntoventa,
               do.sqcomprobante,
               dmm.*
          from tblslvconsolidadopedido     cp,
               tblslvconsolidadopedidorel  cprel,
               pedidos                     pe,
               detallepedidos              dp,
               movmateriales               mm,
               detallemovmateriales        dmm,
               documentos                  do
         where cp.idconsolidadopedido = cprel.idconsolidadopedido
           and cprel.idpedido = pe.idpedido
           and pe.idpedido = mm.idpedido
           and pe.idpedido = dp.idpedido
           and mm.idmovmateriales = do.idmovmateriales
           and mm.idmovmateriales = dmm.idmovmateriales          
           and cp.idconsolidadocomi = &p_idcomi;
