--actualizar los pedidos a estado 2 para volver a consolidar
update pedidos p set p.icestadosistema = 2 
 where p.idpedido in (select cprel.idpedido
                       from tblslvconsolidadopedidorel cprel,
                            tblslvconsolidadopedido    cp
                      where cprel.idconsolidadopedido = cp.idconsolidadopedido
                        and cp.idconsolidadom = &p_idconsolidadoM);

                                      
--borrar la DETPEDIDOCONFORMADO
delete DETPEDIDOCONFORMADO dpc
where dpc.idpedido in (select cprel.idpedido                                
                         from tblslvconsolidadopedidorel   cprel,
                              tblslvconsolidadopedido      cp                       
                        where cprel.idconsolidadopedido = cp.idconsolidadopedido
                          and cp.idconsolidadom  = &p_idconsolidadoM);
                        
  --borrar la tblslvpedidoconformado pc
delete tblslvpedidoconformado pc
 where pc.idpedido in (select cprel.idpedido                                
                         from tblslvconsolidadopedidorel   cprel,
                              tblslvconsolidadopedido      cp                       
                        where cprel.idconsolidadopedido = cp.idconsolidadopedido
                          and cp.idconsolidadom  = &p_idconsolidadoM);
                          
                        
--borrar la distribucion porcentual de la distribucion de pedidos
delete tblslvpordistrib pod 
 where pod.idpedido in (select cprel.idpedido                                
                         from tblslvconsolidadopedidorel   cprel,
                              tblslvconsolidadopedido      cp                       
                        where cprel.idconsolidadopedido = cp.idconsolidadopedido
                          and cp.idconsolidadom  = &p_idconsolidadoM); 
                          

--borrar la tabla tblslvconsolidadopedidorel
delete tblslvconsolidadopedidorel cprel
 where cprel.idconsolidadopedido in (select cp.idconsolidadopedido
                                       from tblslvconsolidadopedido    cp
                                      where cp.idconsolidadom = &p_idconsolidadoM);
                                      
 -----------------------------CONTROL DE REMITOS DE LA DISTRIBUCION AUTOMATICA--------------------------------------------------                          
                          
--borrar el conteo detalle
delete tblslvconteodet cond 
 where cond.idconteo in ( select co.idconteo
                            from tblslvconteo co
                           where co.idcontrolremito in  (select cr.idcontrolremito
                                                           from tblslvcontrolremito cr
                                                          where cr.idremito in (select
                                                                              distinct re.idremito
                                                                                  from tblslvremito re
                                                                                 where re.idpedfaltanterel in (select pfrel.idpedfaltanterel 
                                                                                                                 from tblslvpedfaltanterel    pfrel,
                                                                                                                      tblslvconsolidadopedido cp
                                                                                                                where pfrel.idconsolidadopedido = cp.idconsolidadopedido
                                                                                                                  and cp.idconsolidadom = &p_idconsolidadoM))));                           
                                    
--borrar el conteo 
delete tblslvconteo co 
 where co.idcontrolremito in (select cr.idcontrolremito
                                 from tblslvcontrolremito cr
                                where cr.idremito in (select
                                                    distinct re.idremito
                                                        from tblslvremito re
                                                       where re.idpedfaltanterel in (select pfrel.idpedfaltanterel 
                                                                                       from tblslvpedfaltanterel    pfrel,
                                                                                            tblslvconsolidadopedido cp
                                                                                      where pfrel.idconsolidadopedido = cp.idconsolidadopedido
                                                                                        and cp.idconsolidadom = &p_idconsolidadoM)));                          
                          
--borrar el control remito detalle
delete tblslvcontrolremitodet crd
 where crd.idcontrolremito in (select cr.idcontrolremito
                                 from tblslvcontrolremito cr
                                where cr.idremito in (select
                                                    distinct re.idremito
                                                        from tblslvremito re
                                                       where re.idpedfaltanterel in (select pfrel.idpedfaltanterel 
                                                                                       from tblslvpedfaltanterel    pfrel,
                                                                                            tblslvconsolidadopedido cp
                                                                                      where pfrel.idconsolidadopedido = cp.idconsolidadopedido
                                                                                        and cp.idconsolidadom = &p_idconsolidadoM)));                                            
--borrar el control remito
delete tblslvcontrolremito cr
 where cr.idremito in (select 
                       distinct  re.idremito
                            from tblslvremito re
                           where re.idpedfaltanterel in (select pfrel.idpedfaltanterel 
                                                           from tblslvpedfaltanterel    pfrel,
                                                                tblslvconsolidadopedido cp
                                                          where pfrel.idconsolidadopedido = cp.idconsolidadopedido
                                                            and cp.idconsolidadom = &p_idconsolidadoM));                                     

 -----------------------------CONTROL DE REMITOS DE LA TAREA DEL PEDIDO--------------------------------------------------
 --borrar el conteo detalle
delete tblslvconteodet cond 
 where cond.idconteo in ( select co.idconteo
                            from tblslvconteo co
                           where co.idcontrolremito in  (select cr.idcontrolremito
                                                           from tblslvcontrolremito cr
                                                          where cr.idremito in (  select 
                                                                                distinct re.idremito
                                                                                    from tblslvtarea ta,
                                                                                         tblslvremito re
                                                                                   where ta.idtarea=re.idtarea                                                     
                                                                                     and ta.idconsolidadopedido in (select cp.idconsolidadopedido
                                                                                                                      from tblslvconsolidadopedido cp
                                                                                                                     where cp.idconsolidadom = &p_idconsolidadoM))));                           
                                    
--borrar el conteo 
delete tblslvconteo co 
 where co.idcontrolremito in (select cr.idcontrolremito
                                 from tblslvcontrolremito cr
                                where cr.idremito in (select 
                                                    distinct re.idremito
                                                        from tblslvtarea ta,
                                                             tblslvremito re
                                                       where ta.idtarea=re.idtarea                                                     
                                                         and ta.idconsolidadopedido in (select cp.idconsolidadopedido
                                                                                          from tblslvconsolidadopedido cp
                                                                                         where cp.idconsolidadom = &p_idconsolidadoM)));                          
                          
--borrar el control remito detalle
delete tblslvcontrolremitodet crd
 where crd.idcontrolremito in (select cr.idcontrolremito
                                 from tblslvcontrolremito cr
                                where cr.idremito in (select 
                                                    distinct re.idremito
                                                        from tblslvtarea ta,
                                                             tblslvremito re
                                                       where ta.idtarea=re.idtarea                                                     
                                                         and ta.idconsolidadopedido in (select cp.idconsolidadopedido
                                                                                          from tblslvconsolidadopedido cp
                                                                                         where cp.idconsolidadom = &p_idconsolidadoM)));                                            
--borrar el control remito
delete tblslvcontrolremito cr
 where cr.idremito in(select 
                    distinct re.idremito
                        from tblslvtarea ta,
                             tblslvremito re
                       where ta.idtarea=re.idtarea                                                     
                         and ta.idconsolidadopedido in (select cp.idconsolidadopedido
                                                          from tblslvconsolidadopedido cp
                                                         where cp.idconsolidadom = &p_idconsolidadoM));   
-----------------------------CONTROL DE REMITOS DE LA TAREA DEL COMISIONISTA--------------------------------------------------
 --borrar el conteo detalle
delete tblslvconteodet cond 
 where cond.idconteo in ( select co.idconteo
                            from tblslvconteo co
                           where co.idcontrolremito in  (select cr.idcontrolremito
                                                           from tblslvcontrolremito cr
                                                          where cr.idremito in (  select 
                                                                                distinct re.idremito
                                                                                    from tblslvtarea ta,
                                                                                         tblslvremito re
                                                                                   where ta.idtarea=re.idtarea                                                     
                                                                                     and ta.idconsolidadocomi  in  (select cc.idconsolidadocomi
                                                                                                                      from tblslvconsolidadocomi cc
                                                                                                                     where cc.idconsolidadom = &p_idconsolidadoM))));                           
                                    
--borrar el conteo 
delete tblslvconteo co 
 where co.idcontrolremito in (select cr.idcontrolremito
                                 from tblslvcontrolremito cr
                                where cr.idremito in (select 
                                                    distinct re.idremito
                                                        from tblslvtarea ta,
                                                             tblslvremito re
                                                       where ta.idtarea=re.idtarea                                                     
                                                         and ta.idconsolidadocomi  in  (select cc.idconsolidadocomi
                                                                                          from tblslvconsolidadocomi cc
                                                                                         where cc.idconsolidadom = &p_idconsolidadoM)));                          
                          
--borrar el control remito detalle
delete tblslvcontrolremitodet crd
 where crd.idcontrolremito in (select cr.idcontrolremito
                                 from tblslvcontrolremito cr
                                where cr.idremito in (select 
                                                    distinct re.idremito
                                                        from tblslvtarea ta,
                                                             tblslvremito re
                                                       where ta.idtarea=re.idtarea                                                     
                                                         and ta.idconsolidadocomi  in  (select cc.idconsolidadocomi
                                                                                          from tblslvconsolidadocomi cc
                                                                                         where cc.idconsolidadom = &p_idconsolidadoM)));                                            
--borrar el control remito
delete tblslvcontrolremito cr
 where cr.idremito in(select 
                    distinct re.idremito
                        from tblslvtarea ta,
                             tblslvremito re
                       where ta.idtarea=re.idtarea                                                     
                         and ta.idconsolidadocomi  in  (select cc.idconsolidadocomi
                                                          from tblslvconsolidadocomi cc
                                                         where cc.idconsolidadom = &p_idconsolidadoM));                                                                                              
                                      

--delete de detalle remito involucrados en la distribucion de faltantes
delete tblslvremitodet rd1
where rd1.idremito in (select 
                       distinct  re.idremito
                            from tblslvremito re
                           where re.idpedfaltanterel in (select pfrel.idpedfaltanterel 
                                                           from tblslvpedfaltanterel    pfrel,
                                                                tblslvconsolidadopedido cp
                                                          where pfrel.idconsolidadopedido = cp.idconsolidadopedido
                                                            and cp.idconsolidadom = &p_idconsolidadoM));      
                             
--delete de remito involucrados en la distribucion de faltantes
 delete tblslvremito re
where re.idpedfaltanterel in(select pfrel.idpedfaltanterel 
                               from tblslvpedfaltanterel    pfrel,
                                    tblslvconsolidadopedido cp
                              where pfrel.idconsolidadopedido = cp.idconsolidadopedido
                                and cp.idconsolidadom = &p_idconsolidadoM);
                                
--borrar detalle de remito del consolidado multicanal desde la tarea reparto
delete tblslvremitodet rd where rd.idremito in (  select 
                                                distinct re.idremito
                                                    from tblslvtarea ta,
                                                         tblslvremito re
                                                   where ta.idtarea=re.idtarea                                                     
                                                     and ta.idconsolidadopedido in (select cp.idconsolidadopedido
                                                                                      from tblslvconsolidadopedido cp
                                                                                     where cp.idconsolidadom = &p_idconsolidadoM)); 
--borrar detalle de remito del consolidado multicanal desde la tarea comisionistas
delete tblslvremitodet rd where rd.idremito in (  select 
                                                distinct re.idremito
                                                    from tblslvtarea ta,
                                                         tblslvremito re
                                                   where ta.idtarea=re.idtarea                                                     
                                                     and ta.idconsolidadocomi  in  (select cc.idconsolidadocomi
                                                                                      from tblslvconsolidadocomi cc
                                                                                     where cc.idconsolidadom = &p_idconsolidadoM));     
--borrar detalle de remito del consolidado multicanal desde la tarea FALTANTES
delete tblslvremitodet rd where rd.idremito in (  select 
                                                distinct re.idremito
                                                    from tblslvtarea ta,
                                                         tblslvremito re
                                                   where ta.idtarea=re.idtarea                                                     
                                                     and ta.idpedfaltante  in ( select pfr.idpedfaltante
                                                                                  from tblslvpedfaltanterel pfr 
                                                                                 where pfr.idconsolidadopedido in (select cp.idconsolidadopedido
                                                                                                                     from tblslvconsolidadopedido cp
                                                                                                                    where cp.idconsolidadom = &p_idconsolidadoM))); 
--borrar detalle de remito del consolidado multicanal desde la tarea MULTICANAL
delete tblslvremitodet rd where rd.idremito in (  select 
                                                distinct re.idremito
                                                    from tblslvtarea ta,
                                                         tblslvremito re
                                                   where ta.idtarea=re.idtarea                                                     
                                                     and ta.idconsolidadom   = &p_idconsolidadoM);                                                                                                                                                                                                                                                                                                                                                       
                                                   
--borrar remito del consolidado pedido desde la tarea reparto
delete tblslvremito r where r.idremito in(  select 
                                          distinct re.idremito
                                              from tblslvtarea ta,
                                                   tblslvremito re
                                             where ta.idtarea=re.idtarea                                                     
                                               and ta.idconsolidadopedido in(select cp.idconsolidadopedido
                                                                               from tblslvconsolidadopedido cp
                                                                              where cp.idconsolidadom = &p_idconsolidadoM));    
                                                                                                          
--borrar remito del consolidado pedido desde la tarea comisionistas
delete tblslvremito r where r.idremito in(  select 
                                          distinct re.idremito
                                              from tblslvtarea ta,
                                                   tblslvremito re
                                             where ta.idtarea=re.idtarea                                                     
                                               and ta.idconsolidadocomi in(select cc.idconsolidadocomi
                                                                             from tblslvconsolidadocomi cc
                                                                            where cc.idconsolidadom = &p_idconsolidadoM)); 
                                                                              
--borrar remito del consolidado multicanal desde la tarea FALTANTES
delete tblslvremito r where r.idremito in (  select 
                                                distinct re.idremito
                                                    from tblslvtarea ta,
                                                         tblslvremito re
                                                   where ta.idtarea=re.idtarea                                                     
                                                     and ta.idpedfaltante  in ( select pfr.idpedfaltante
                                                                                  from tblslvpedfaltanterel pfr 
                                                                                 where pfr.idconsolidadopedido in (select cp.idconsolidadopedido
                                                                                                                     from tblslvconsolidadopedido cp
                                                                                                                    where cp.idconsolidadom = &p_idconsolidadoM))); 
--borrar remito del consolidado multicanal desde la tarea MULTICANAL
delete tblslvremito r where r.idremito in (  select 
                                                distinct re.idremito
                                                    from tblslvtarea ta,
                                                         tblslvremito re
                                                   where ta.idtarea=re.idtarea                                                     
                                                     and ta.idconsolidadom   = &p_idconsolidadoM); 
                                                     
                                                     
--borrar tareas detalle del consolidadoM
delete tblslvtareadet td  where td.idtarea in ( select 
                                              distinct ta.idtarea
                                                  from tblslvtarea ta
                                                 where ta.idconsolidadom  = &p_idconsolidadoM); 
                                               
--borrar detalle tareas del pedido 
delete tblslvtareadet td  where td.idtarea in (select ta.idtarea 
                                                 from tblslvtarea ta
                                                where ta.idconsolidadopedido in (select cp.idconsolidadopedido
                                                                                   from tblslvconsolidadopedido cp
                                                                                  where cp.idconsolidadom = &p_idconsolidadoM));
--borrar detalle tareas del comisionista
delete tblslvtareadet td  where td.idtarea in (select ta.idtarea 
                                                 from tblslvtarea ta
                                                where ta.idconsolidadocomi in (select cc.idconsolidadocomi
                                                                                   from tblslvconsolidadocomi cc
                                                                                  where cc.idconsolidadom = &p_idconsolidadoM));  
                                                                                                                                                                  
--borrar detalle tareas del faltante
delete tblslvtareadet td  where td.idtarea in (select ta.idtarea 
                                                 from tblslvtarea ta
                                                where ta.idpedfaltante in ( select pfr.idpedfaltante
                                                                              from tblslvpedfaltanterel pfr 
                                                                             where pfr.idconsolidadopedido in (select cp.idconsolidadopedido
                                                                                                                 from tblslvconsolidadopedido cp
                                                                                                                where cp.idconsolidadom = &p_idconsolidadoM)));
--borrar tareas  del consolidadoM
delete tblslvtarea ta  where ta.idtarea in ( select 
                                              distinct ta.idtarea
                                                  from tblslvtarea ta
                                                 where ta.idconsolidadom  = &p_idconsolidadoM); 
                                               
--borrar tareas del pedido 
delete tblslvtarea ta  where ta.idtarea in ( select ta.idtarea 
                                               from tblslvtarea ta
                                              where ta.idconsolidadopedido in (select cp.idconsolidadopedido
                                                                                   from tblslvconsolidadopedido cp
                                                                                  where cp.idconsolidadom = &p_idconsolidadoM));
--borrar tareas del comisionista
delete tblslvtarea ta  where ta.idtarea in(select ta.idtarea 
                                             from tblslvtarea ta
                                            where ta.idconsolidadocomi in (select cc.idconsolidadocomi
                                                                               from tblslvconsolidadocomi cc
                                                                              where cc.idconsolidadom = &p_idconsolidadoM));  
                                                                                                                                                                  
--borrar tareas del faltante
delete tblslvtarea ta  where ta.idtarea in ( select ta.idtarea 
                                               from tblslvtarea ta
                                              where ta.idpedfaltante in ( select pfr.idpedfaltante
                                                                            from tblslvpedfaltanterel pfr 
                                                                           where pfr.idconsolidadopedido in (select cp.idconsolidadopedido
                                                                                                               from tblslvconsolidadopedido cp
                                                                                                              where cp.idconsolidadom = &p_idconsolidadoM)));                                                                                                                where cp.idconsolidadom = &p_idconsolidadoM)));  
                                                                                                   
--delete tblslvajustedistribucion
delete tblslvajustedistribucion aj 
 where aj.iddistribucionpedfaltante in (select dpf.iddistribucionpedfaltante 
                                          from tblslvdistribucionpedfaltante dpf
                                         where dpf.idpedfaltanterel in (select pfrel.idpedfaltanterel 
                                                                          from tblslvpedfaltanterel pfrel
                                                                         where pfrel.idconsolidadopedido in (select cp.idconsolidadopedido
                                                                                                              from tblslvconsolidadopedido cp
                                                                                                              where cp.idconsolidadom = &p_idconsolidadoM)));
--borrar distribucion involucrada
delete tblslvdistribucionpedfaltante dpf
 where dpf.idpedfaltanterel in (select pfrel.idpedfaltanterel 
                                  from tblslvpedfaltanterel pfrel
                                 where pfrel.idconsolidadopedido in(select cp.idconsolidadopedido
                                                                      from tblslvconsolidadopedido cp
                                                                     where cp.idconsolidadom = &p_idconsolidadoM));                                                                      
--borrar detalle de los faltantes del consolidadoM
delete tblslvpedfaltantedet pfd 
 where pfd.idpedfaltante in ( select pfr.idpedfaltante
                                from tblslvpedfaltanterel pfr 
                               where pfr.idconsolidadopedido in (select cp.idconsolidadopedido
                                                                   from tblslvconsolidadopedido cp
                                                                  where cp.idconsolidadom = &p_idconsolidadoM));
                                                                  
 --borrar la distribucion porcentual de los faltantes distribuidos
delete tblslvpordistribfaltantes podf 
 where podf.idpedfaltante in (select pfr.idpedfaltante
                                from tblslvpedfaltanterel pfr 
                               where pfr.idconsolidadopedido in (select cp.idconsolidadopedido
                                                                   from tblslvconsolidadopedido cp
                                                                  where cp.idconsolidadom = &p_idconsolidadoM));                                                           
                                                                                               
--borrar la relacion de pedidos con faltantes
delete tblslvpedfaltanterel pfr 
 where pfr.idconsolidadopedido in (select cp.idconsolidadopedido
                                     from tblslvconsolidadopedido cp
                                    where cp.idconsolidadom = &p_idconsolidadoM); 
                                    

 --borrar pedidos con faltantes                                     
 delete tblslvpedfaltante pf where pf.idpedfaltante not in (select pfr.idpedfaltante from tblslvpedfaltanterel pfr );
 
--borrar detalle del consolidado pedido
delete tblslvconsolidadopedidodet cpd 
 where cpd.idconsolidadopedido in (select cp.idconsolidadopedido
                                     from tblslvconsolidadopedido cp
                                    where cp.idconsolidadom = &p_idconsolidadoM); 
 
--borrar el consolidado pedido
delete tblslvconsolidadopedido cp 
 where cp.idconsolidadom = &p_idconsolidadoM; 
 
 --borrar detalle del consolidado comisionista
delete tblslvconsolidadocomidet ccd
 where ccd.idconsolidadocomi in  ( select cc.idconsolidadocomi
                                     from tblslvconsolidadocomi cc
                                    where cc.idconsolidadom = &p_idconsolidadoM); 
 
--borrar el consolidado  comisionista
delete tblslvconsolidadocomi cc
 where cc.idconsolidadom = &p_idconsolidadoM; 
 
 --borrar detalle del consolidado M
delete tblslvconsolidadomdet cmd
 where cmd.idconsolidadom = &p_idconsolidadoM; 
 
--borrar el consolidado M
delete tblslvconsolidadom cm
 where cm.idconsolidadom = &p_idconsolidadoM; 

 
 
