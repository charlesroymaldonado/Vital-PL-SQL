
 --pasar a estado 12 cerrado para refacturar 
  select * 
  from tblslvconsolidadopedido cp
  where cp.idconsolidadopedido=&p_idconsolidado
  for update;
  --borrar la DETPEDIDOCONFORMADO
  delete DETPEDIDOCONFORMADO dpc
  where dpc.idpedido in (
                        select pc.idpedido                                    
                          from tblslvpedidoconformado       pc,
                               tblslvconsolidadopedido      cp,
                               tblslvconsolidadopedidorel   cprel,
                               pedidos                      pe,
                               descripcionesarticulos       des
                         where pe.idpedido = cprel.idpedido
                           and cprel.idconsolidadopedido = cp.idconsolidadopedido
                           and pc.idpedido = pe.idpedido
                           and pc.cdarticulo = des.cdarticulo
                           and cp.idconsolidadopedido = &p_idconsolidado );
  --borrar la tblslvpedidoconformado pc
  delete tblslvpedidoconformado pc
  where pc.idpedido in (
                        select pc.idpedido                                    
                          from tblslvpedidoconformado       pc,
                               tblslvconsolidadopedido      cp,
                               tblslvconsolidadopedidorel   cprel,
                               pedidos                      pe,
                               descripcionesarticulos       des
                         where pe.idpedido = cprel.idpedido
                           and cprel.idconsolidadopedido = cp.idconsolidadopedido
                           and pc.idpedido = pe.idpedido
                           and pc.cdarticulo = des.cdarticulo
                           and cp.idconsolidadopedido = &p_idconsolidado )
