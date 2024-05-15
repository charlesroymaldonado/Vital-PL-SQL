create or replace view view_dw_slvpedidosfacturados as
select nvl2(cp.idconsolidadocomi,cp.idconsolidadocomi, cp.idconsolidadopedido) pedido,               
               cp.id_canal,
               pe.idpedido idpedidoPOS,
               cp.dtinsert dtinicio,
               cp.dtupdate dtfin,
               cp.cdsucursal,
              (select max(lp.dtmodif)
                 from tbllogestadopedidos lp
                where lp.icestadosistema = 2
                  and lp.idpedido = pe.idpedido) dtliberacion,
               (select cm.dtinsert
                  from tblslvconsolidadom cm
                 where cm.idconsolidadom = cp.idconsolidadom) dtbajada_pedido
          from tblslvconsolidadopedido          cp,
               tblslvconsolidadopedidorel       cprel,
               pedidos                          pe
         where cp.idconsolidadopedido = cprel.idconsolidadopedido
           and cprel.idpedido = pe.idpedido;
