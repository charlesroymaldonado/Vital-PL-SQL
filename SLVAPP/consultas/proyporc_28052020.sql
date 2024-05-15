--total  pedido
                   select cpd.cdarticulo, 
                          sum(cpd.qtunidadesmedidabase) qtbase                          
                     from tblslvconsolidadopedido cp,
                          tblslvconsolidadopedidorel prel,
                          tblslvpedfaltante pf,
                          tblslvpedfaltanterel pfrel,
                          tblslvconsolidadopedidodet cpd,
                          tblslvpedfaltantedet pfd,
                          pedidos p                    
                    where p.idpedido = prel.idpedido
                      and prel.idconsolidadopedido = cp.idconsolidadopedido
                      and cpd.idconsolidadopedido = cp.idconsolidadopedido
                      and pfrel.idconsolidadopedido = cp.idconsolidadopedido
                      and pfrel.idpedfaltante = pf.idpedfaltante
                      and pf.idpedfaltante = pfd.idpedfaltante
                      and pfd.cdarticulo = cpd.cdarticulo
                      and pf.idpedfaltante = &p_idFaltante
                 group by cpd.cdarticulo;
--total por pedido articulo                 
                   select p.idpedido,
                          cp.idconsolidadom,                          
                          cpd.cdarticulo, 
                          sum(cpd.qtunidadesmedidabase) qtbase
                     from tblslvconsolidadopedido cp,
                          tblslvconsolidadopedidorel prel,
                          tblslvpedfaltante pf,
                          tblslvpedfaltanterel pfrel,
                          tblslvconsolidadopedidodet cpd,
                          tblslvpedfaltantedet pfd,
                          pedidos p                    
                    where p.idpedido = prel.idpedido
                      and prel.idconsolidadopedido = cp.idconsolidadopedido
                      and cpd.idconsolidadopedido = cp.idconsolidadopedido
                      and pfrel.idconsolidadopedido = cp.idconsolidadopedido
                      and pfrel.idpedfaltante = pf.idpedfaltante
                      and pf.idpedfaltante = pfd.idpedfaltante
                      and pfd.cdarticulo = cpd.cdarticulo
                      and pf.idpedfaltante = &p_idFaltante
                 group by p.idpedido,
                          cp.idconsolidadom, 
                          cpd.cdarticulo
                 order by 1                 
