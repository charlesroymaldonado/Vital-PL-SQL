select *
 from tblslvconsolidadopedido cp,
      tblslvconsolidadopedidodet cpd
where cp.idconsolidadopedido=cpd.idconsolidadopedido;      
select ped.idpedido,
             cp.idconsolidadom,
             dped.cdarticulo,
             sum(dped.qtunidadmedidabase) qtbase,
             0 p_total
        from pedidos                    ped,
             detallepedidos             dped,
             documentos                 doc,
             tblslvconsolidadopedidorel rel,
             tblslvconsolidadopedido    cp             
       where ped.iddoctrx = doc.iddoctrx
         and doc.cdcomprobante = 'PEDI'
         and ped.idpedido = dped.idpedido
         and dped.icresppromo = 0
         and cp.idconsolidadopedido = rel.idconsolidadopedido
         and ped.idpedido = rel.idpedido
         and cp.idconsolidadom = &p_idconsolidado
         and dped.cdarticulo = &p_cdart
       group by ped.idpedido,
             cp.idconsolidadom,
             dped.cdarticulo;

select sum(dped.qtunidadmedidabase) qtbase
            
        from pedidos                    ped,
             detallepedidos             dped,
             documentos                 doc,
             tblslvconsolidadopedidorel rel,
             tblslvconsolidadopedido    cp             
       where ped.iddoctrx = doc.iddoctrx
         and doc.cdcomprobante = 'PEDI'
         and ped.idpedido = dped.idpedido
         and dped.icresppromo = 0
         and cp.idconsolidadopedido = rel.idconsolidadopedido
         and ped.idpedido = rel.idpedido
         and cp.idconsolidadom = &p_idconsolidado
         and dped.cdarticulo = &p_cdart
                  
