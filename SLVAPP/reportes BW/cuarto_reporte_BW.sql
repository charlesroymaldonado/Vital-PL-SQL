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
                   re.cdsucursal ||'- '||su.dssucursal sucursal,               
                   A.cdarticulo, 
                   A.cantidad Cantidad_UN,
                   A.cantidadBTO Cantidad_BTO
             from ( select B.cdarticulo,
                           B.idcontrolremito,                           
                           --valida pesables
                           decode (B.cantpiezas,0,B.cantbase,B.cantpiezas) cantidad,
                           decode (B.cantpiezas,0,round(B.cantbase/B.UxB),0) cantidadBTO
                      from (select crd.cdarticulo,
                                   crd.idcontrolremito,
                                   nvl((SELECT to_number(trim(ua.vlcontador),'999999999999.99')
                                          FROM UnidadesArticulo ua
                                         WHERE ua.CDArticulo = crd.cdarticulo
                                           AND ua.CDUnidad = 'BTO'
                                           AND ROWNUM = 1),1) UxB,              
                                   (sum(crd.qtunidadmedidabasepicking)) cantbase,
                                    sum(crd.qtpiezaspicking) cantpiezas                                       
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
         
