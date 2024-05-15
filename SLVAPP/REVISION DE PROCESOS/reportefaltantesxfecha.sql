          with conforma as  ( select A.idpedido,
                                     A.cdarticulo,
                                     sum(A.qtpiezas) qtpiezas,
                                     sum(A.qtbase) qtbase
                                from (select pc.idpedido,          	                                                                        
                                             pc.cdarticulo,
                                             pc.qtpiezas qtpiezas,
                                             pc.qtunidadmedidabase qtbase             
                                        from tblslvpedidoconformado      pc,
                                             tblslvconsolidadopedidorel  prel,
                                             tblslvconsolidadopedido     cp
                                       where pc.idpedido = prel.idpedido
                                         and prel.idconsolidadopedido = cp.idconsolidadopedido                                 
                                         --solo pedidos facturados
                                         and cp.cdestado in (13,14)
                                         -- Excluyo pedidos generados por faltantes de Comi
                                         and pc.idpedido not in (select pgf.idpedidogen 
                                                                     from tblslvpedidogeneradoxfaltante pgf)
                                         and cp.dtinsert between &v_dtDesde and &v_dtHasta 
                                         and (&p_idconsolidadoPedi=0 or cp.idconsolidadopedido = &p_idconsolidadoPedi)
                                         and (&p_idconsolidadoComi=0 or cp.idconsolidadocomi = &p_idconsolidadoComi)
                                   union all 
                                      --agrego pedidos de faltantes de comi
                                      select pgf.idpedido,                                                                                    
                                             pc.cdarticulo,
                                             pc.qtpiezas qtpiezas,
                                             pc.qtunidadmedidabase qtbase             
                                        from tblslvpedidoconformado        pc,
                                             tblslvconsolidadopedidorel    prel,
                                             tblslvconsolidadopedido       cp,
                                             tblslvpedidogeneradoxfaltante pgf
                                       where pc.idpedido = prel.idpedido
                                         and pc.idpedido = pgf.idpedidogen
                                         and prel.idconsolidadopedido = cp.idconsolidadopedido                                 
                                         --solo pedidos facturados
                                         and cp.cdestado in (13,14)
                                         and cp.dtinsert between &v_dtDesde and &v_dtHasta
                                         ) A                                        
                             group by A.idpedido,                                                                        
                                      A.cdarticulo  
                             ),
                  pedido as  (select p.idpedido,
                                     cp.dtinsert,
                                     dp.cdarticulo,
                                     cp.cdsucursal,
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
                                 and p.idpedido not in (select pgf.idpedidogen 
                                                          from tblslvpedidogeneradoxfaltante pgf)
                                 and cp.dtinsert between &v_dtDesde and &v_dtHasta
                                 and (&p_idconsolidadoPedi=0 or cp.idconsolidadopedido = &p_idconsolidadoPedi)
                                 and (&p_idconsolidadoComi=0 or cp.idconsolidadocomi = &p_idconsolidadoComi)                                
                            group by p.idpedido,
                                     cp.dtinsert,
                                     cp.cdsucursal,
                                     dp.cdarticulo)    
                select su.dssucursal sucursal,
                       to_char(pe.dtinsert,'dd/mm/yyyy') FechaConsolidado,
                       sec.dssector Sector, 
                       pe.cdarticulo || '- ' || des.vldescripcion Articulo,
                       round(avg(pe.precioun),3) preciounitario,
                       PKG_SLV_Articulo.SetFormatoArticulosCod(pe.cdarticulo,
                       --valida pesables
                       sum(decode(pe.qtpiezas,0,pe.qtbase,pe.qtpiezas))) unidades_pedidas,
                       PKG_SLV_Articulo.SetFormatoArticulosCod(pe.cdarticulo,
                       --valida pesables
                       nvl(sum(decode(co.qtpiezas,0,co.qtbase,co.qtpiezas)),0)) unidades_pickeadas,
                       PKG_SLV_Articulo.SetFormatoArticulosCod(pe.cdarticulo,
                       abs(sum((nvl(decode(co.qtpiezas,0,co.qtbase,co.qtpiezas),0)-decode(pe.qtpiezas,0,pe.qtbase,pe.qtpiezas))))) Faltantes,                   
                       posapp.n_pkg_vitalpos_materiales.GetUxB(pe.cdarticulo) UXB,
                       PKG_SLV_Articulo.GetUbicacionArticulos(pe.cdarticulo) UBICACION                            
                  from pedido                 pe
                  left join(conforma          co)
                       on (co.idpedido = pe.idpedido
                           and co.cdarticulo = pe.cdarticulo),
                       sucursales             su,
                       articulos              art,
                       descripcionesarticulos des,                                    
                       sectores               sec
                 where pe.cdsucursal = su.cdsucursal 
                   and art.cdarticulo = pe.cdarticulo
                   and art.cdsector = sec.cdsector              
                   and art.cdarticulo = des.cdarticulo
                   and case 
                         --verifica si es pesable 
                          when pe.qtpiezas<>0
                           and (nvl(co.qtpiezas,0)-pe.qtpiezas <> 0) then 1
                          --verifica los no pesable
                          when pe.qtpiezas = 0 
                           and (nvl(co.qtbase,0)-pe.qtbase <> 0)  then 1
                       else 0    
                       end = 1  
              group by su.dssucursal, 
                       to_char(pe.dtinsert,'dd/mm/yyyy'),
                       sec.dssector,
                       pe.cdarticulo,
                       pe.cdarticulo || '- ' || des.vldescripcion                      
              order by to_date(FechaConsolidado,'dd/mm/yyyy') desc,
                       Sector;   
