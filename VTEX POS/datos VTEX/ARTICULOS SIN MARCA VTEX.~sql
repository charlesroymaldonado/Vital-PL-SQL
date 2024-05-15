SELECT distinct BB.* FROM
                      (select distinct AR.CDARTICULO, 
                             nvl2(trim(ae.vldescripcion),ae.vldescripcion,da.vldescripcion) name,
                             NVL((select 
                             distinct nvl(vc.departmentid,-1) -- -1 NO CATALOGADO
                                 from vtexcatalog vc
                                where vc.departmentname = upper(trim(d.dsdepartamento))
                                   and rownum = 1),-1) departmentID, 
                             NVL((select 
                             distinct NVL(vc.categoryid,-1) -- -1 NO CATALOGADO
                                 from vtexcatalog vc
                                where vc.categoryname = upper(trim(u.dsuniverso))
                                   and rownum = 1),-1) categoryID,  
                             NVL((select 
                                distinct NVL(vc.subcategoryid,-1) -- -1 NO CATALOGADO
                                 from vtexcatalog vc
                                where  vc.subcategoryname =upper(trim(c.dscategoria))
                                   and rownum = 1),-1) subcategoryID,                
                             NVL((select 
                             distinct NVL(vb.brandid,-1)  -- -1 SIN MARCA
                                 from vtexbrand vb
                                where upper(trim(ae.vlmarca))=vb.name
                                  and rownum = 1),-1) Brandid,                                  
                                  ae.vlmarca                                                         
                       from articulos_s                    ar,
                            descripcionesarticulos_s       da,
                            tblarticulonombreecommerce_s   ae,
                            tblctgryarticulocategorizado_s a,
                            tblctgrydepartamento_s         d,
                            tblctgryuniverso_s             u,
                            tblctgrycategoria_s            c,
                            tblctgrysubcategoria_s         sc,
                            tblctgrysegmento_s             s,
                            tblctgrysubsegmento_s          ss,
                            tblctgrysectorc_S              tse,
                            tblivaarticulo_s               tiva
                      where ar.cdarticulo = da.cdarticulo                        
                        and ar.cdestadoplu in('00','07')  --OJO 00 activo para la venta 07 no visible 03 articulo desactivado permanentemente
                        and tiva.cdarticulo(+) = ar.cdarticulo
                        and not exists
                      (select 1
                               from articulosnocomerciales_s t
                              where t.cdarticulo = a.cdarticulo)
                        and not exists
                      (select 1
                               from articulos_excluidos h
                              where h.cdarticulo = ar.cdarticulo) --agrego tabla articulos excluidos 
                        and substr(ar.cdarticulo, 1, 1) <> 'A'
                        and a.cdarticulo = ae.cdarticulo (+)
                        and a.cddepartamento = d.cddepartamento(+)
                        and a.cduniverso = u.cduniverso(+)
                        and a.cdcategoria = c.cdcategoria(+)
                        and a.cdsubcategoria = sc.cdsubcategoria(+)
                        and a.cdsegmento = s.cdsegmento(+)
                        and a.cdsubsegmento = ss.cdsubsegmento(+)
                        and a.cdsectorc = tse.cdserctorc
                        and a.cdarticulo = ar.cdarticulo
                        and ar.cddrugstore not in ('EX', 'DE', 'CP'))BB
                        
                         -- validacion para listar solo articulos catalogados en VTEX
                   WHERE TO_CHAR(BB.DEPARTMENTID||BB.CATEGORYID||BB.SUBCATEGORYID) IN (SELECT TO_CHAR(VC.DEPARTMENTID||VC.CATEGORYID||VC.SUBCATEGORYID) 
                                                                                         FROM  VTEXCATALOG  VC)
                     AND BB.BRANDID =-1
                                                                                      
                     
                     
