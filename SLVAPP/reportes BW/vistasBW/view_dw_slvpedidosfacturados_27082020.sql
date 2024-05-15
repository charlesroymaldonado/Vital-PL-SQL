create or replace view view_dw_slvpedidosfacturados as
SELECT A.PEDIDO, 
       A.id_canal,
       A.idpedidoPOS,
       TO_CHAR (A.dtinsert, 'yyyymmdd') AS FECHAINICIO,
       TO_CHAR (A.dtinsert, 'HH24:MI:SS') AS HORAINICIO,
       TO_CHAR (A.dtupdate, 'yyyymmdd') AS FECHAFIN,
       TO_CHAR (A.dtupdate, 'HH24:MI:SS') AS HORAFIN,
       A.cdsucursal,
       TO_CHAR (A.dtliberacion, 'yyyymmdd') AS FECHALIBERACION,
       TO_CHAR (A.dtliberacion, 'HH24:MI:SS') AS HORALIBERACION,
       TO_CHAR (A.dtbajada_pedido, 'yyyymmdd') AS FECHABAJADA_PEDIDO,
       TO_CHAR (A.dtbajada_pedido, 'HH24:MI:SS') AS HORABAJADA_PEDIDO
  FROM (select nvl2(cp.idconsolidadocomi,cp.idconsolidadocomi, cp.idconsolidadopedido) pedido,
                         cp.id_canal,
                         pe.idpedido idpedidoPOS,                         
                         cp.dtinsert,                         
                         cp.dtupdate,
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
                     and cprel.idpedido = pe.idpedido)A;
