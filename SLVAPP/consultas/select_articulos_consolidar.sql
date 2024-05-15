 select ART.CDSECTOR SECTOR,
             A.cdarticulo||'- '||DES.VLDESCRIPCION ARTICULO,
            SUM(A.cantidad)CANTIDAD,
             --A.cantidadOriginal,
             PKG_SLVArticulos.GetStockArticulos(art.cdarticulo),
             PKG_SLVArticulos.GetUbicacionArticulos(ART.cdarticulo),
             posapp.n_pkg_vitalpos_materiales.GetUxB(art.cdarticulo) vluxb
             --cdunidadmedida
        from (select detped.cdarticulo,
                     detped.cdunidadmedida,
                     sum(CASE
                           WHEN (detped.cdunidadmedida = 'BTO' or
                                detped.cdunidadmedida = 'CA') THEN
                            detped.VLUXB * detped.QTUNIDADPEDIDO
                           ELSE
                            detped.QTUNIDADPEDIDO
                         END) AS cantidad,
                     detped.VLUXB vluxb,
                     --sum(detped.qtunidadpedido) cantidadOriginal,
                     sum(nvl(detped.qtpiezas, 0)) piezas
                from pedidos        ped,
                     documentos     docped,
                     detallepedidos detped,
                     articulos      art
               where ped.iddoctrx = docped.iddoctrx
                 and ped.idpedido = detped.idpedido
                 and art.cdarticulo = detped.cdarticulo
                 and ped.transid in ('MALEGREAOFFMDM')
               group by detped.cdarticulo,
                        detped.cdunidadmedida,
                        detped.VLUXB) A,
             ARTICULOS ART,
             DESCRIPCIONESARTICULOS DES
       WHERE ART.CDARTICULO = DES.CDARTICULO
         AND A.CDARTICULO = ART.CDARTICULO
       GROUP BY ART.CDSECTOR, A.cdarticulo, DES.VLDESCRIPCION, PKG_SLVArticulos.GetStockArticulos(art.cdarticulo),
             PKG_SLVArticulos.GetUbicacionArticulos(ART.cdarticulo)
             , posapp.n_pkg_vitalpos_materiales.GetUxB(art.cdarticulo)
--             , vluxb,cdunidadmedida
             
        
