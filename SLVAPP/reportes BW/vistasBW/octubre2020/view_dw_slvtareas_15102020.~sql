create or replace view view_dw_slvtareas as
       select ta.idtarea,
              ta.cdtipo cdtipotarea,
              tt.dstarea dstipotarea,
              coalesce(
                ta.idpedfaltante,
                ta.idconsolidadom,
                ta.idconsolidadopedido,
                ta.idconsolidadocomi) pedido,                       
              ta.idpersonaarmador,
              case
                when ta.idpedfaltante is not null then 'F (TE+VE)'
                when ta.idconsolidadom is not null then 'MC'
                when ta.idconsolidadopedido is not null then
                   (select cp.id_canal
                     from tblslvconsolidadopedido cp
                    where cp.idconsolidadopedido = ta.idconsolidadopedido
                      and cp.cdsucursal = ta.cdsucursal)
               when ta.idconsolidadocomi is not null then 'CO'
              end id_canal,
              ta.cdsucursal,
              TO_CHAR (ta.dtinicio, 'yyyymmdd') AS FECHAINICIO,
              TO_CHAR (ta.dtinicio, 'HH24:MI:SS') AS HORAINICIO,
              ta.dtinicio,
              TO_CHAR (ta.dtfin, 'yyyymmdd') AS FECHAFIN,
              TO_CHAR (ta.dtfin, 'HH24:MI:SS') AS HORAFIN,
              ta.dtfin,
              td.cdarticulo,
              --precio promedio
              case 
                when ta.idconsolidadocomi is not null then
                     (select round(avg(dp.ampreciounitario),2) 
                        from tblslvconsolidadopedidorel prel,
                             pedidos                    pe,
                             detallepedidos             dp
                       where dp.icresppromo <> 1
                         and pe.idpedido = dp.idpedido
                         and prel.idpedido = pe.idpedido
                         and dp.cdarticulo = td.cdarticulo
                         and prel.idconsolidadopedido in (select cp2.idconsolidadopedido 
                                                            from tblslvconsolidadopedido cp2 
                                                           where cp2.idconsolidadocomi = ta.idconsolidadocomi)) 
               when ta.idconsolidadopedido is not null then
                     (select round(avg(dp.ampreciounitario),2) 
                        from tblslvconsolidadopedidorel prel,
                             pedidos                    pe,
                             detallepedidos             dp
                       where dp.icresppromo <> 1
                         and pe.idpedido = dp.idpedido
                         and prel.idpedido = pe.idpedido
                         and dp.cdarticulo = td.cdarticulo
                         and prel.idconsolidadopedido = ta.idconsolidadopedido) 
               /* when ta.idconsolidadom is not null then
                     (select round(avg(dp.ampreciounitario),2) 
                        from tblslvconsolidadopedidorel prel,
                             pedidos                    pe,
                             detallepedidos             dp
                       where dp.icresppromo <> 1
                         and pe.idpedido = dp.idpedido
                         and prel.idpedido = pe.idpedido
                         and dp.cdarticulo = td.cdarticulo
                         and prel.idconsolidadopedido in (select cp2.idconsolidadopedido 
                                                            from tblslvconsolidadopedido cp2 
                                                           where cp2.idconsolidadom = ta.idconsolidadom)) 
                 when ta.idpedfaltante is not null then
                     (select round(avg(dp.ampreciounitario),2) 
                        from tblslvconsolidadopedidorel prel,
                             pedidos                    pe,
                             detallepedidos             dp
                       where dp.icresppromo <> 1
                         and pe.idpedido = dp.idpedido
                         and prel.idpedido = pe.idpedido
                         and dp.cdarticulo = td.cdarticulo
                         and prel.idconsolidadopedido in (select cp2.idconsolidadopedido 
                                                            from tblslvconsolidadopedido cp2,
                                                                 tblslvpedfaltanterel    frel 
                                                           where cp2.idconsolidadopedido = frel.idconsolidadopedido
                                                             and frel.idpedfaltante = ta.idpedfaltante))    */                                     
                                                                                                              
               else 0                                                   
              end PRECIO_PROMEDIO,
              -- cambiar este paquete el AC
              pkg_slv_articulo.getuxbarticulo(td.cdarticulo,decode(td.qtpiezas,0,'BTO','KG'))VLUxB,
              decode(td.qtpiezas,0,td.qtunidadmedidabase,td.qtpiezas) qtsolicitada,
              decode(td.qtpiezas,0,td.qtunidadmedidabasepicking,td.qtpiezaspicking) qtpicking,
              nvl(re.idremito,0) idremito,
              nvl(re.nrocarreta,'-') nrocarreta
         from tblslvtarea             ta,
              tblslvRemito            re,
              tblslvtareadet          td,
              tblslvTipoTarea         tt
         where ta.idtarea = td.idtarea
          and ta.cdsucursal = td.cdsucursal
          and ta.cdtipo = tt.cdtipo
          and ta.idtarea = re.idtarea(+)
          and ta.cdsucursal = re.cdsucursal(+)
          -- solo tareas iniciadas
          and ta.dtinicio is not null;
