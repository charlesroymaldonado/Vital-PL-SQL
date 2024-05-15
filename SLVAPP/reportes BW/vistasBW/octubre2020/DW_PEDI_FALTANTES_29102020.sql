CREATE OR REPLACE VIEW DW_PEDI_FALTANTES
(sucursal, fecha_consolidado, articulo, precio_promedio_unidad, stock, unidades_pedidas, unidades_pickeadas, unidades_faltantes, canal)
AS
with conforma as  ( select A.idpedido,
                             A.id_canal,
                             A.cdarticulo,
                             sum(A.qtpiezas) qtpiezas,
                             sum(A.qtbase) qtbase
                        from (select pc.idpedido,
                                     cp.id_canal,
                                     pc.cdarticulo,
                                     pc.qtpiezas qtpiezas,
                                     pc.qtunidadmedidabase qtbase
                                from slvapp.tblslvpedidoconformado      pc,
                                     tblslvconsolidadopedidorel  prel,
                                     tblslvconsolidadopedido     cp
                               where pc.idpedido = prel.idpedido
                                 and prel.idconsolidadopedido = cp.idconsolidadopedido
                                 --solo pedidos facturados
                                 and cp.cdestado in (13,14)
                                 -- Excluyo pedidos generados por faltantes de Comi
                                 and not exists (select 1
                                                   from tblslvpedidogeneradoxfaltante pgf
                                                   where pgf.idpedidogen=pc.idpedido
                                         )
                              --   and cp.dtinsert between &v_dtDesde and &v_dtHasta
                           union all
                              --agrego suma de articulos de pedidos de faltantes de comi
                              select pgf.idpedido,
                                     cp.id_canal,
                                     pc.cdarticulo,
                                     pc.qtpiezas qtpiezas,
                                     pc.qtunidadmedidabase qtbase
                                from slvapp.tblslvpedidoconformado        pc,
                                     tblslvconsolidadopedidorel    prel,
                                     tblslvconsolidadopedido       cp,
                                     tblslvpedidogeneradoxfaltante pgf
                               where pc.idpedido = prel.idpedido
                                 and pc.idpedido = pgf.idpedidogen
                                 and prel.idconsolidadopedido = cp.idconsolidadopedido
                                 --solo pedidos facturados
                                 and cp.cdestado in (13,14)
                              --   and cp.dtinsert between &v_dtDesde and &v_dtHasta
                              ) A
                     group by A.idpedido,
                              A.cdarticulo,
                              A.id_canal
                     ),
          pedido as  (select p.idpedido,
                             cp.dtinsert,
                             dp.cdarticulo,
                             cp.cdsucursal,
                             cp.id_canal,
                             sum(dp.qtpiezas) qtpiezas,
                             sum(dp.qtunidadmedidabase) qtbase,
                             avg(dp.ampreciounitario) precioun
                        from pedidos                     p,
                             detallepedidos              dp,
                             tblslvconsolidadopedidorel  prel,
                             tblslvconsolidadopedido     cp
                       where p.idpedido = dp.idpedido
                         and p.idpedido = prel.idpedido
                         and cp.idconsolidadopedido = prel.idconsolidadopedido
                         --excluyo linea de promo
                         and dp.icresppromo = 0
                         --solo pedidos facturados
                         and cp.cdestado in (13,14)
                         -- Excluyo pedidos generados por faltantes de Comi
                         and  not exists (select 1
                                            from tblslvpedidogeneradoxfaltante pgf
                                            where pgf.idpedidogen=p.idpedido
                                         )
                       --  and cp.dtinsert between &v_dtDesde and &v_dtHasta
                    group by p.idpedido,
                             cp.dtinsert,
                             cp.cdsucursal,
                             cp.id_canal,
                             dp.cdarticulo)
        select pe.cdsucursal sucursal,
               to_char(pe.dtinsert,'yyyymmdd') FechaConsolidado,
               pe.cdarticulo,
               round(avg(pe.precioun),3) preciounitario,
               null stock,
               sum(decode(pe.qtpiezas,0,pe.qtbase,pe.qtpiezas)) unidades_pedidas,
               nvl(sum(decode(co.qtpiezas,0,co.qtbase,co.qtpiezas)),0) unidades_pickeadas,
               abs(sum((nvl(decode(co.qtpiezas,0,co.qtbase,co.qtpiezas),0)-decode(pe.qtpiezas,0,pe.qtbase,pe.qtpiezas)))) Faltantes,
                pe.id_canal
              -- posapp.n_pkg_vitalpos_materiales.GetUxB(pe.cdarticulo) UXB
          from pedido                 pe
          left join(conforma          co)
               on (    co.idpedido = pe.idpedido
                   and co.cdarticulo = pe.cdarticulo
                   and co.id_canal = pe.id_canal),
               articulos              art
         where art.cdarticulo = pe.cdarticulo
           and case
                 --verifica si es pesable
                  when pe.qtpiezas<>0
                   and (nvl(co.qtpiezas,0)-pe.qtpiezas <> 0) then 1
                  --verifica los no pesable
                  when pe.qtpiezas = 0
                   and (nvl(co.qtbase,0)-pe.qtbase <> 0)  then 1
               else 0
               end = 1
           and co.id_canal<>'CO'
      group by pe.cdsucursal,
               to_char(pe.dtinsert,'yyyymmdd'),
               pe.cdarticulo,
               pe.id_canal,
               pe.cdarticulo
      order by to_date(FechaConsolidado,'yyyymmdd') desc
;
