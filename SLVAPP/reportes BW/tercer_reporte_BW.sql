            select nvl(nvl(ta.idconsolidadopedido,ta.idconsolidadocomi),
                   (select distinct cp.idconsolidadopedido 
                     from tblslvremito             r1,
                          tblslvpedfaltanterel     pfr,
                          tblslvconsolidadopedido  cp
                    where r1.idpedfaltanterel = pfr.idpedfaltanterel
                      and r1.idremito = re.idremito
                      and pfr.idconsolidadopedido = cp.idconsolidadopedido)) pedido,         
                      
                   cr.dtinicio,
                   cr.dtfin,
                                                      
                  nvl2(ta.idconsolidadocomi,'CO',nvl2(ta.idconsolidadopedido,
                                                    (select distinct cp.id_canal 
                                                       from tblslvconsolidadopedido  cp
                                                      where cp.idconsolidadopedido = ta.idconsolidadopedido),
                                                    (select distinct cp.id_canal 
                                                       from tblslvremito             r1,
                                                            tblslvpedfaltanterel     pfr,
                                                            tblslvconsolidadopedido  cp
                                                      where r1.idpedfaltanterel = pfr.idpedfaltanterel
                                                        and r1.idremito = re.idremito
                                                        and pfr.idconsolidadopedido = cp.idconsolidadopedido)) ) Canal,   
                   re.idremito||' - '||re.nrocarreta remito_rollCarreta,
                   pc.dsnombre || pc.dsapellido PersonaControl,
                   nvl((select pc.dsnombre || pc.dsapellido
                      from personas p,
                           tblslvremito r,
                           tblslvtarea  t
                     where r.idremito = re.idremito 
                       and r.idtarea = t.idtarea
                       and t.idpersonaarmador = p.idpersona),'Distribución Automática') Armador,
                   re.cdsucursal ||'- '||su.dssucursal sucursal,               
                   A.cdarticulo, 
                   A.cantidad,                
                   case 
                    when A.Cantidad > 0 then 'S'
                    when A.Cantidad < 0 then 'F'
                   end TipoAjuste                  
             from ( select B.cdarticulo,
                           B.idcontrolremito,
                           --valida pesables
                           decode (B.cantpiezas,0,B.cantbase,B.cantpiezas) cantidad
                      from (select crd.cdarticulo,
                                    crd.idcontrolremito,              
                                    (sum(crd.qtdiferenciaunidadmbase-nvl(crd.qtajusteunidadmbase,0))) cantbase,
                                     sum(crd.qtdiferenciapiezas-nvl(crd.qtajustepiezas,0)) cantpiezas                                       
                               from tblslvcontrolremitodet            crd                          
                            --  where crd.idcontrolremito = &v_idControl                    
                           group by crd.cdarticulo,
                                    crd.idcontrolremito        
                           )B
                   )A,
                   tblslvcontrolremito            cr,
                   tblslvremito                   re
                   left join (tblslvtarea          ta)
                          on (re.idtarea = ta.idtarea),
                   sucursales                     su,
                   Personas                       pc   
              where A.idcontrolremito = cr.idcontrolremito
                and cr.idremito = re.idremito
                and cr.idpersonacontrol = pc.idpersona
                and re.cdsucursal = su.cdsucursal
                and A.cantidad<>0
           order by re.idremito;
         
