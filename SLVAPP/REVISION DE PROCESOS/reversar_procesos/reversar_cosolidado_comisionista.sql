--borrar la DETPEDIDOCONFORMADO
delete DETPEDIDOCONFORMADO dpc
where dpc.idpedido in (select cprel.idpedido                                
                         from tblslvconsolidadopedidorel   cprel,
                              tblslvconsolidadopedido      cp,
                              tblslvconsolidadocomi        cc                       
                        where cp.idconsolidadopedido = cprel.idconsolidadopedido 
                          and cp.idconsolidadocomi = cc.idconsolidadocomi 
                          and cc.idconsolidadocomi = &p_idcomi);
                        
--borrar la tblslvpedidoconformado pc
delete tblslvpedidoconformado pc
 where pc.idpedido in (select cprel.idpedido                                
                         from tblslvconsolidadopedidorel   cprel,
                              tblslvconsolidadopedido      cp,
                              tblslvconsolidadocomi        cc                       
                        where cp.idconsolidadopedido = cprel.idconsolidadopedido 
                          and cp.idconsolidadocomi = cc.idconsolidadocomi 
                          and cc.idconsolidadocomi = &p_idcomi);
                        
--borrar la distribucion porcentual de la distribucion de pedidos comi
delete tblslvpordistrib pod 
 where pod.idconsolidado = &p_idcomi;

--borrar detalle de remito del consolidado pedido desde la tarea
delete tblslvremitodet rd where rd.idremito in (  select 
                                                distinct re.idremito
                                                    from tblslvtarea ta,
                                                         tblslvremito re
                                                   where ta.idtarea=re.idtarea                                                     
                                                     and ta.idconsolidadocomi=&p_idcomi);                                                     
                                                   
--borrar remito del consolidado pedido desde la tarea
delete tblslvremito r where r.idremito in(  select 
                                          distinct re.idremito
                                              from tblslvtarea ta,
                                                   tblslvremito re
                                             where ta.idtarea=re.idtarea                                                     
                                               and ta.idconsolidadocomi=&p_idcomi);
                                               
--borrar detalle tareas del pedido 
delete tblslvtareadet td  where td.idtarea in (select ta.idtarea 
                                                 from tblslvtarea ta
                                                where ta.idconsolidadocomi=&p_idcomi);

--borrar tareas del pedido
delete tblslvtarea ta where ta.idconsolidadocomi=&p_idcomi;

--actualizar los pedidos a estado 2 para volver a consolidar
update pedidos p set p.icestadosistema = 2 
 where p.idpedido in (select cprel.idpedido
                       from tblslvconsolidadopedidorel cprel
                      where cprel.idconsolidadopedido in(select cp.idconsolidadopedido 
                                                           from tblslvconsolidadopedido cp
                                                          where cp.idconsolidadocomi=&p_idcomi));

--borrar detalle del consolidado pedido
delete tblslvconsolidadopedidodet cpd 
 where cpd.idconsolidadopedido in (select cp.idconsolidadopedido 
                                     from tblslvconsolidadopedido cp
                                    where cp.idconsolidadocomi=&p_idcomi);
 
--borrar el consolidado pedido
delete tblslvconsolidadopedido cp 
 where cp.idconsolidadopedido  in (select cp.idconsolidadopedido 
                                     from tblslvconsolidadopedido cp
                                    where cp.idconsolidadocomi=&p_idcomi);
                                    
--borrar el consolidado comisionista detalle
delete tblslvconsolidadocomidet ccd
 where ccd.idconsolidadocomi = &p_idcomi;     

--borrar el consolidado comisionista 
delete tblslvconsolidadocomi cc
 where cc.idconsolidadocomi = &p_idcomi;                                   
