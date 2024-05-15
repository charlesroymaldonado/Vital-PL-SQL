create or replace view view_dw_slvcontrolremito as
select nvl(ta.idtarea,0) idtarea,
                   nvl(ta.cdtipo,0) cdtipotarea,
                   nvl(nvl(ta.idconsolidadopedido,ta.idconsolidadocomi),
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
                                                        and pfr.idconsolidadopedido = cp.idconsolidadopedido))) Canal,
                   re.idremito,
                   re.nrocarreta,
                   cr.idpersonacontrol,
                   nvl(ta.idpersonaarmador,'Distribución Automática') idArmador,
                   re.cdsucursal,
                   A.cdarticulo,
                   A.UxB,
                   A.qtbase_UN,
                   A.cantidaddif qtajuste_UN,
                   case
                    when A.Cantidaddif > 0 then 'S'
                    when A.Cantidaddif < 0 then 'F'
                      else '-'
                   end TipoAjuste
             from ( select B.cdarticulo,
                           B.idcontrolremito,
                           --valida pesables
                           nvl(decode(B.cantpiezas,0,B.cantbase,B.cantpiezas),0) qtbase_UN,
                           decode (B.difpiezas,0,B.difbase,B.difpiezas) cantidaddif,
                          nvl2(B.cantpiezas,pkg_slv_articulo.getuxbarticulo(B.cdarticulo,decode(B.cantpiezas,0,'BTO','KG')),1) UxB
                      from (select crd.cdarticulo,
                                   crd.idcontrolremito,
                                   (crd.qtdiferenciaunidadmbase-nvl(crd.qtajusteunidadmbase,0)) difbase,
                                    crd.qtdiferenciapiezas-nvl(crd.qtajustepiezas,0) difpiezas,
                                    crd.qtunidadmedidabasepicking cantbase,
                                    crd.qtpiezaspicking cantpiezas
                               from tblslvcontrolremitodet            crd
                            --  where crd.idcontrolremito = &v_idControl
                           )B
                    )A,
                    tblslvcontrolremito            cr,
                    tblslvremito                   re
                    left join (tblslvtarea          ta)
                          on (re.idtarea = ta.idtarea)
              where A.idcontrolremito = cr.idcontrolremito
                and cr.idremito = re.idremito
           order by re.idremito
;
