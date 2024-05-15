        select cp.idconsolidadopedido pedido,
               pe.idpedido,                           
               pe.id_canal,
               cp.cdsucursal ||'- '||su.dssucursal sucursal,
               pe.dtaplicacion dtToma_Pedido,
               '-' dtHora_sincronizacion,
               '-' dtHora_liberacion,
               cp.dtinsert dtHora_bajado_pedido,
                                              --fecha de inicio de la primera tarea comi       
               nvl(nvl2(cp.idconsolidadocomi,(select min(ta.dtinicio) 
                  from tblslvtarea ta 
                 where ta.idconsolidadocomi = cp.idconsolidadocomi),
                  --fecha de inicio de la primera tarea pedido     
                 (select min(ta.dtinicio) 
                  from tblslvtarea ta 
                 where ta.idconsolidadopedido = cp.idconsolidadopedido)),'01/01/9999') dtHora_armado_inicio,
               mm.dtaplicacion dtFacturado_Finalizado_Pedido, 
                --fecha de fin ultimo remito comi                       
               nvl(nvl2(cp.idconsolidadocomi,(select max(cr.dtfin) 
                  from tblslvtarea          ta,
                       tblslvremito         re,
                       tblslvcontrolremito  cr 
                 where ta.idconsolidadocomi = cp.idconsolidadocomi
                   and ta.idtarea = re.idtarea
                   and re.idremito = cr.idremito), 
                 --fecha de fin ultimo remito pedido
                 (select max(cr.dtfin) 
                    from tblslvtarea          ta,
                         tblslvremito         re,
                         tblslvcontrolremito  cr 
                   where ta.idconsolidadopedido = cp.idconsolidadopedido
                     and ta.idtarea = re.idtarea
                     and re.idremito = cr.idremito)),'01/01/9999') dtHora_control,
               'SAP' dtHora_checkout,
               'SAP' dtHora_rendicion
          from tblslvconsolidadopedido          cp,              
               tblslvconsolidadopedidorel       cprel,
               pedidos                          pe,                          
               movmateriales                    mm,                         
               sucursales                       su
         where cp.idconsolidadopedido = cprel.idconsolidadopedido          
           and cprel.idpedido = pe.idpedido
           and cp.cdsucursal = su.cdsucursal
           and pe.idpedido = mm.idpedido          
         -- and cp.idconsolidadopedido = &p_idconsolidado
      order by cp.idconsolidadopedido
