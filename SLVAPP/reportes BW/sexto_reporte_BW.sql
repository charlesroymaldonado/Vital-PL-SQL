        select cp.idconsolidadopedido,
               cp.dtinsert dtinicio,
               cp.dtupdate dtfin,
               cp.id_canal,
               cp.cdsucursal ||'- '||su.dssucursal sucursal,
               dp.cdarticulo,
               --valida pesables
               decode (dp.qtpiezas,0,dp.qtunidadmedidabase,dp.qtpiezas) promos_solicitadas,
               decode (dm.qtpiezas,0,dm.qtunidadmedidabase,dm.qtpiezas) promos_facturadas
          from tblslvconsolidadopedido          cp,              
               tblslvconsolidadopedidorel       cprel,
               pedidos                          pe,
               detallepedidos                   dp,               
               movmateriales                    mm,
               Detallemovmateriales             dm,              
               sucursales                       su
         where cp.idconsolidadopedido = cprel.idconsolidadopedido          
           and cprel.idpedido = pe.idpedido
           and cp.cdsucursal = su.cdsucursal
           and pe.idpedido = mm.idpedido
           and pe.idpedido = dp.idpedido  
           and mm.idmovmateriales = dm.idmovmateriales
           and dp.cdarticulo = dm.cdarticulo 
           --excluyo linea de promo
           and dp.icresppromo = 0 
           --solo articulos con promo
           and dp.cdpromo is not null    
         -- and cp.idconsolidadopedido = &p_idconsolidado
