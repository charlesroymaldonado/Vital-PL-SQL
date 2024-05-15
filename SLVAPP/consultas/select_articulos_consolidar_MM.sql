           select  art.cdarticulo cod, 
                   sum(detped.qtunidadmedidabase),
                       pkg_slvarticulos.getstockarticulos(art.cdarticulo) stock,
                       posapp.n_pkg_vitalpos_materiales.getuxb(art.cdarticulo) uxb,
                       pkg_slvarticulos.getubicacionarticulos(art.cdarticulo) ubicacion
             from pedidos                ped,
                  documentos             docped,
                  detallepedidos         detped,
                  articulos              art
             where ped.iddoctrx = docped.iddoctrx
                   and ped.idpedido = detped.idpedido
                   and art.cdarticulo = detped.cdarticulo
                   and ped.transid in (select mm.transid from tbltmpslvconsolidadom mm)--lista pedidos solo de la tbltmpslvconsolidam
             group by art.cdarticulo


select * from tblslvconsolidadomdet
select * from tblslvconsolidadom
