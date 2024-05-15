        select cp.idconsolidadopedido pedido,
               cp.dtinsert dtinicio,
               cp.dtupdate dtfin,
               cp.id_canal,
               cp.cdsucursal ||'- '||su.dssucursal sucursal,
               dp.cdarticulo,
               --valida pesables
               decode (dp.qtpiezas,0,dp.qtunidadmedidabase,dp.qtpiezas) SKU_solicitados,
               decode (dm.qtpiezas,0,dm.qtunidadmedidabase,dm.qtpiezas) SKU_facturados,
               (SELECT t.stock            
                FROM tblctrlstockart t
                WHERE t.cdarticulo = dp.cdarticulo) Stock_SKU
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
         -- and cp.idconsolidadopedido = &p_idconsolidado
