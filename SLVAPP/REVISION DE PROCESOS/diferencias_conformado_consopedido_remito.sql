      with conforma  as(select cp.idconsolidadopedido,
                               pcf.cdarticulo,
                               sum(pcf.qtunidadmedidabase) qtbase,
                               sum(pcf.qtpiezas) qtpiezas
                          from tblslvconsolidadopedido cp,
                               tblslvconsolidadopedidorel prel,
                               tblslvpedidoconformado     pcf
                         where cp.idconsolidadopedido = prel.idconsolidadopedido
                           and pcf.idpedido = prel.idpedido
                          -- and cp.idconsolidadopedido = &p_IdPedidos
                      group by cp.idconsolidadopedido,
                               pcf.cdarticulo),
         consopedido as(select cp.idconsolidadopedido,
                               cpd.cdarticulo,
                               cpd.qtunidadmedidabasepicking qtbase,
                               cpd.qtpiezaspicking qtpiezas
                          from tblslvconsolidadopedido cp,
                               tblslvconsolidadopedidodet cpd
                         where cp.idconsolidadopedido = cpd.idconsolidadopedido
                          -- and cp.idconsolidadopedido = &p_IdPedidos
                        ),
          remito     as( select A.cdarticulo,
                                A.idconsolidadopedido,
                                sum(A.qtbase) qtbase,
                                sum(A.qtpiezas) qtpiezas
                           from ( select cp.idconsolidadopedido,
                                         rd.cdarticulo,
                                         sum(rd.qtpiezaspicking) qtpiezas,
                                         sum(rd.qtunidadmedidabasepicking) qtbase
                                    from tblslvremito                      re,
                                         tblslvremitodet                   rd,
                                         tblslvtarea                       ta,
                                         tblslvconsolidadopedido           cp
                                   where re.idremito = rd.idremito                
                                     and re.idtarea = ta.idtarea
                                     and ta.idconsolidadopedido = cp.idconsolidadopedido    
                                    -- and ta.idconsolidadopedido = &p_IdPedidos
                                group by rd.cdarticulo,
                                         cp.idconsolidadopedido
                               union all
                                 --consulta los remitos de distribución
                                  select cp.idconsolidadopedido,
                                         rd.cdarticulo,
                                         sum(rd.qtpiezaspicking) qtpiezas,
                                         sum(rd.qtunidadmedidabasepicking) qtbase
                                    from tblslvremito                      re,
                                         tblslvremitodet                   rd,
                                         tblslvpedfaltanterel              frel,
                                         tblslvconsolidadopedido           cp
                                   where re.idremito = rd.idremito                
                                     and re.idpedfaltanterel = frel.idpedfaltanterel
                                     and frel.idconsolidadopedido = cp.idconsolidadopedido    
                                    -- and frel.idconsolidadopedido = &p_IdPedidos
                                group by cp.idconsolidadopedido,
                                         rd.cdarticulo)A
                                group by A.idconsolidadopedido,
                                         A.cdarticulo
                             )                  
      select conforma.idconsolidadopedido,
             conforma.cdarticulo,
             conforma.qtbase,
             conforma.qtpiezas,
             consopedido.qtbase,
             consopedido.qtpiezas,
             remito.qtbase,
             remito.qtpiezas     
        from conforma,
             consopedido,
             remito
       where conforma.idconsolidadopedido = consopedido.idconsolidadopedido(+)
         and conforma.cdarticulo = consopedido.cdarticulo(+)
         and conforma.idconsolidadopedido = remito.idconsolidadopedido(+)
         and conforma.cdarticulo = remito.cdarticulo(+)
        -- revisa diferencias con remito
         --and (conforma.qtbase-remito.qtbase <> 0 or conforma.qtpiezas- remito.qtpiezas <> 0)
         -- revisa diferencias con consopedido
         and (conforma.qtbase-consopedido.qtbase <> 0 or conforma.qtpiezas- consopedido.qtpiezas <> 0);
