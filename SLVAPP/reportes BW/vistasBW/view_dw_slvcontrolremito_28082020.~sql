create or replace view view_dw_slvcontrolremito as
            select nvl(ta.idtarea,0) idtarea,
                   nvl(ta.cdtipo,0) cdtipotarea,
                   nvl(nvl(ta.idconsolidadopedido,ta.idconsolidadocomi),
                   (select distinct cp.idconsolidadopedido
                     from tblslvremito            r1,
                          tblslvpedfaltanterel     pfr,
                          tblslvconsolidadopedido  cp
                    where r1.idpedfaltanterel = pfr.idpedfaltanterel
                      and r1.cdsucursal =pfr.cdsucursal
                      and r1.idremito = re.idremito
                      and pfr.idconsolidadopedido = cp.idconsolidadopedido
                      and pfr.cdsucursal = cp.cdsucursal)) pedido,
                   TO_CHAR (cr.dtinicio, 'yyyymmdd') AS FECHAINICIO,
                   TO_CHAR (cr.dtinicio, 'HH24:MI:SS') AS HORAINICIO,
                   cr.dtinicio dtinicio,
                   TO_CHAR (cr.dtfin, 'yyyymmdd') AS FECHAFIN,
                   TO_CHAR (cr.dtfin, 'HH24:MI:SS') AS HORAFIN,
                   cr.dtfin,
                   --verifica si ta.idconsolidadocomi es not null el canal es CO
                   -- si es null verifica si ta.idconsolidadopedido es not null busca canal del tblslvconsolidadopedido 
                   --si es null ta.idconsolidadopedido busca el canal del remito de generación automática
                  nvl2(ta.idconsolidadocomi,'CO',nvl2(ta.idconsolidadopedido,
                                                    (select distinct cp2.id_canal
                                                       from tblslvconsolidadopedido  cp2
                                                      where cp2.idconsolidadopedido = ta.idconsolidadopedido
                                                        and cp2.cdsucursal = ta.cdsucursal),
                                                    (select distinct cp2.id_canal
                                                       from tblslvremito             r2,
                                                            tblslvpedfaltanterel     pfr2,
                                                            tblslvconsolidadopedido  cp2
                                                      where r2.idpedfaltanterel = pfr2.idpedfaltanterel
                                                        and r2.cdsucursal = pfr2.cdsucursal
                                                        and r2.idremito = re.idremito
                                                        and r2.cdsucursal =re.cdsucursal
                                                        and pfr2.idconsolidadopedido = cp2.idconsolidadopedido
                                                        and pfr2.cdsucursal = cp2.cdsucursal))) Canal,
                   re.idremito,
                   re.nrocarreta,
                   cr.idpersonacontrol,
                   nvl(ta.idpersonaarmador,'Distribución Automática') idArmador,
                   re.cdsucursal,
                   A.cdarticulo,
                   A.UxB VLUxB,
                   A.qtbase_UN,
                   A.cantidaddif qtajuste_UN,
                   case
                    when A.Cantidaddif > 0 then 'S'
                    when A.Cantidaddif < 0 then 'F'
                      else '-'
                   end TipoAjuste
             from ( select B.cdarticulo,
                           B.idcontrolremito,
                           B.cdsucursal,
                           --valida pesables
                           nvl(decode(B.cantpiezas,0,B.cantbase,B.cantpiezas),0) qtbase_UN,
                           decode (B.difpiezas,0,B.difbase,B.difpiezas) cantidaddif,
                          nvl2(B.cantpiezas,pkg_slv_articulo.getuxbarticulo(B.cdarticulo,decode(B.cantpiezas,0,'BTO','KG')),1) UxB
                      from (select crd.cdarticulo,
                                   crd.idcontrolremito,
                                   crd.cdsucursal,
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
                and A.cdsucursal = cr.cdsucursal                
                and cr.idremito = re.idremito
                and cr.cdsucursal = re.cdsucursal
           order by re.idremito
;
