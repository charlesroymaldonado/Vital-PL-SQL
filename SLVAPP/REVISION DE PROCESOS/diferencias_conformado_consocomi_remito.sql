      with conforma  as(select cp.idconsolidadocomi,
                               pcf.cdarticulo,
                               sum(pcf.qtunidadmedidabase) qtbase,
                               sum(pcf.qtpiezas) qtpiezas
                          from tblslvconsolidadopedido cp,
                               tblslvconsolidadopedidorel prel,
                               tblslvpedidoconformado     pcf
                         where cp.idconsolidadopedido = prel.idconsolidadopedido
                           and pcf.idpedido = prel.idpedido
                           and cp.idconsolidadocomi is not null
                         --  and cp.idconsolidadocomi = &p_IdPedidos
                      group by cp.idconsolidadocomi,
                               pcf.cdarticulo),
         consopedido as(select cp.idconsolidadocomi,
                               cpd.cdarticulo,
                               sum(cpd.qtunidadmedidabasepicking) qtbase,
                               sum(cpd.qtpiezaspicking) qtpiezas
                          from tblslvconsolidadopedido cp,
                               tblslvconsolidadopedidodet cpd
                         where cp.idconsolidadopedido = cpd.idconsolidadopedido
                           and cp.idconsolidadocomi is not null
                          -- and cp.idconsolidadocomi = &p_IdPedidos
                      group by cp.idconsolidadocomi,
                               cpd.cdarticulo
                          
                        ),
          remito     as(select cc.idconsolidadocomi,
                               rd.cdarticulo,
                               sum(rd.qtpiezaspicking) qtpiezas,
                               sum(rd.qtunidadmedidabasepicking) qtbase
                          from tblslvremito                      re,
                               tblslvremitodet                   rd,
                               tblslvtarea                       ta,                               
                               tblslvconsolidadocomi             cc
                         where re.idremito = rd.idremito                
                           and re.idtarea = ta.idtarea                          
                           and ta.idconsolidadocomi = cc.idconsolidadocomi
                         --  and ta.idconsolidadocomi = &p_IdPedidos
                      group by rd.cdarticulo,
                               cc.idconsolidadocomi
                       order by cc.idconsolidadocomi,rd.cdarticulo                                    
                             )                  
      select conforma.idconsolidadocomi,
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
       where conforma.idconsolidadocomi = consopedido.idconsolidadocomi(+)
         and conforma.cdarticulo = consopedido.cdarticulo(+)
         and conforma.idconsolidadocomi = remito.idconsolidadocomi(+)
         and conforma.cdarticulo = remito.cdarticulo(+)
        -- revisa diferencias con remito
        -- and (conforma.qtbase-remito.qtbase <> 0 or conforma.qtpiezas- remito.qtpiezas <> 0)
         -- revisa diferencias con consopedido
        and (conforma.qtbase-consopedido.qtbase <> 0 or conforma.qtpiezas- consopedido.qtpiezas <> 0)
       order by conforma.idconsolidadocomi,
                conforma.cdarticulo;
