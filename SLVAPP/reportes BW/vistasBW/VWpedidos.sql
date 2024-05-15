CREATE OR REPLACE VIEW VIEW_DW_SLVPEDIDOSFACTURADOS AS
        select nvl2(cp.idconsolidadocomi,cp.idconsolidadocomi, cp.idconsolidadopedido) pedido,
               cp.id_canal,
               cp.dtinsert dtinicio,
               cp.dtupdate dtfin,      
               cp.cdsucursal,
               nvl2(dp.cdpromo,1,0) icpromo,
               dp.cdarticulo,
               pkg_slv_articulo.getuxbarticulo(dp.cdarticulo,decode(nvl(dp.qtpiezas,0),0,'BTO','KG'))UxB,
               dp.qtunidadmedidabase qtsolicitada,
               dm.qtunidadmedidabase qtfacturada,               
               (SELECT t.stock
                FROM tblctrlstockart t
                WHERE t.cdarticulo = dp.cdarticulo) qtStock,
               pe.dtaplicacion dtTomaPedido,
               pe.dtaplicacion dtsincronizacion,            
               '-' dtliberacion, --ojo falta la información de estado 2 del pedido en AC
               (select cm.dtinsert 
                  from tblslvconsolidadom cm
                 where cm.idconsolidadom = cp.idconsolidadom) dtbajada_pedido
          from tblslvconsolidadopedido          cp,
               tblslvconsolidadopedidorel       cprel,
               pedidos                          pe,
               detallepedidos                   dp,
               movmateriales                    mm,
               Detallemovmateriales             dm
         where cp.idconsolidadopedido = cprel.idconsolidadopedido
           and cprel.idpedido = pe.idpedido
           and pe.idpedido = mm.idpedido
           and pe.idpedido = dp.idpedido
           and mm.idmovmateriales = dm.idmovmateriales
           and dp.cdarticulo = dm.cdarticulo
           --excluyo linea de promo
           and dp.icresppromo = 0
         -- and cp.idconsolidadopedido = &p_idconsolidado
;
