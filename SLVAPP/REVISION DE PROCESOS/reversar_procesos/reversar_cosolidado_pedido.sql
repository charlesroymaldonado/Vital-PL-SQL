------revisar si el consolidado pedido esta en una distribucion de faltantes borrarla primero----------------------------------
select distinct pfrel.idpedfaltante 
 from tblslvpedfaltanterel pfrel
where pfrel.idconsolidadopedido = &p_idpedido;
--busca los consolidados pedidos que tambien forman parte del consolidado faltante
select distinct pfrel.idconsolidadopedido
 from tblslvpedfaltanterel pfrel
where pfrel.idconsolidadopedido = &p_idpedido;
--actualiza los pedidos involucrados a estado 12 cerrado para permitir generar de nuevo un consolidado de faltantes sin el pedido que borré
update tblslvconsolidadopedido cp
   set cp.cdestado = 12
 where cp.idconsolidadopedido in (select pfrel.idconsolidadopedido 
                                    from tblslvpedfaltanterel pfrel
                                   where pfrel.idpedfaltante = &P_Faltante);
                                   

--delete de detalle remito involucrados en la distribucion de faltantes
delete tblslvremitodet rd1
where rd1.idremito in (select 
                       distinct  re.idremito
                            from tblslvremito re
                           where re.idpedfaltanterel in (select pfrel.idpedfaltanterel 
                                                           from tblslvpedfaltanterel pfrel
                                                          where pfrel.idpedfaltante = &P_Faltante));      
                             
--delete de remito involucrados en la distribucion de faltantes
 delete tblslvremito re
where re.idpedfaltanterel in(select pfrel.idpedfaltanterel 
                               from tblslvpedfaltanterel pfrel
                              where pfrel.idpedfaltante = &P_Faltante);
                              
--delete tblslvajustedistribucion
delete tblslvajustedistribucion aj 
 where aj.iddistribucionpedfaltante in (select dpf.iddistribucionpedfaltante 
                                          from tblslvdistribucionpedfaltante dpf
                                         where dpf.idpedfaltanterel in (select pfrel.idpedfaltanterel 
                                                                          from tblslvpedfaltanterel pfrel
                                                                         where pfrel.idpedfaltante = &P_Faltante));
--borrar distribucion involucrada
delete tblslvdistribucionpedfaltante dpf
 where dpf.idpedfaltanterel in (select pfrel.idpedfaltanterel 
                                  from tblslvpedfaltanterel pfrel
                                 where pfrel.idpedfaltante = &P_Faltante); 
                                 
--borrar la relacion de pedidos con faltantes
delete tblslvpedfaltanterel pfr 
 where pfr.idpedfaltante = &P_Faltante;

--borrar la distribucion porcentual de los faltantes distribuidos
delete tblslvpordistribfaltantes podf 
 where podf.idpedfaltante = &P_Faltante;
 
--borrar detalle de remito del consolidado faltante 
delete tblslvremitodet rd where rd.idremito in (  select 
                                                distinct re.idremito
                                                    from tblslvtarea ta,
                                                         tblslvremito re
                                                   where ta.idtarea=re.idtarea                                                     
                                                     and ta.idpedfaltante=&P_Faltante); 
--borrar  remito del consolidado Faltante
delete tblslvremito r where r.idremito in(  select 
                                          distinct re.idremito
                                              from tblslvtarea ta,
                                                   tblslvremito re
                                             where ta.idtarea=re.idtarea                                                     
                                               and ta.idpedfaltante=&P_Faltante);                                                     
--borrar tareas del Faltante
delete tblslvtareadet td  where td.idtarea in (select ta.idtarea 
                                                 from tblslvtarea ta
                                                where ta.idpedfaltante=&P_Faltante);

--borrar tareas del Faltante
delete tblslvtarea ta where ta.idpedfaltante=&P_Faltante;                                                     
                                  
--borrar detalle de pedidos faltantes
delete tblslvpedfaltantedet pfd
 where pfd.idpedfaltante = &P_Faltante;
 
--borrar consolidado pedido faltantes
delete tblslvpedfaltante pf
 where pf.idpedfaltante = &P_Faltante; 
---------------------------------OJO REVISAR SI LOS OTROS PEDIDOS DEL FALTANTE YA ESTAN EN POSCONFORMADO PARA TAMBIEN BORRARLOS Y REFACTURAR-------------------------------------------------------------------------------------------
--xxxxxxxxxxxxxxxxxxxxxxxxxxaplicar este borrado para los pedidos parte del faltante para que se pueda hacer de nuevo el consolidado de faltantes y la facturacion
--borrar la DETPEDIDOCONFORMADO
delete DETPEDIDOCONFORMADO dpc
where dpc.idpedido in (select cprel.idpedido                                
                         from tblslvconsolidadopedidorel   cprel                       
                        where cprel.idconsolidadopedido = &p_idpedido);
                        
  --borrar la tblslvpedidoconformado pc
delete tblslvpedidoconformado pc
 where pc.idpedido in (select cprel.idpedido                                   
                         from tblslvconsolidadopedidorel   cprel                       
                        where cprel.idconsolidadopedido = &p_idpedido);
                        
--borrar la distribucion porcentual de la distribucion de pedidos
delete tblslvpordistrib pod 
 where pod.idconsolidado = &p_idpedido;
--xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
--borrar detalle de remito del consolidado pedido desde la tarea
delete tblslvremitodet rd where rd.idremito in (  select 
                                                distinct re.idremito
                                                    from tblslvtarea ta,
                                                         tblslvremito re
                                                   where ta.idtarea=re.idtarea                                                     
                                                     and ta.idconsolidadopedido=&p_idpedido);                                                     
                                                   
--borrar remito del consolidado pedido desde la tarea
delete tblslvremito r where r.idremito in(  select 
                                          distinct re.idremito
                                              from tblslvtarea ta,
                                                   tblslvremito re
                                             where ta.idtarea=re.idtarea                                                     
                                               and ta.idconsolidadopedido=&p_idpedido);
                                               
--borrar detalle tareas del pedido 
delete tblslvtareadet td  where td.idtarea in (select ta.idtarea 
                                                 from tblslvtarea ta
                                                where ta.idconsolidadopedido=&p_idpedido);

--borrar tareas del pedido
delete tblslvtarea ta where ta.idconsolidadopedido=&p_idpedido;

--actualizar los pedidos a estado 2 para volver a consolidar
update pedidos p set p.icestadosistema = 2 
 where p.idpedido in (select cprel.idpedido
                       from tblslvconsolidadopedidorel cprel
                      where cprel.idconsolidadopedido = &p_idpedido);

--borrar la tabla tblslvconsolidadopedidorel
delete tblslvconsolidadopedidorel cprel
 where cprel.idconsolidadopedido = &p_idpedido; 

--borrar detalle del consolidado pedido
delete tblslvconsolidadopedidodet cpd 
 where cpd.idconsolidadopedido = &p_idpedido; 
 
--borrar el consolidado pedido
delete tblslvconsolidadopedido cp 
 where cp.idconsolidadopedido = &p_idpedido; 
