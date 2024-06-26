select ROWNUM,SECTOR,
       COD||'- '||DESC_ART ARTICULO,
       TRUNC((CANT/UxB),0)||' BTO/ '||MOD(CANT,UxB)||' UN' CANTIDAD,  
       TRUNC((STOCK/UxB),0)||' BTO/ '||MOD(STOCK,UxB)||' UN' STOCK,
       UBICACION 
FROM (select ART.CDSECTOR SECTOR,
       ART.cdarticulo COD, 
       DES.VLDESCRIPCION DESC_ART,
       sum(DETPED.QTUNIDADMEDIDABASE)  CANT,
       PKG_SLVArticulos.GetStockArticulos(art.cdarticulo) STOCK,
       posapp.n_pkg_vitalpos_materiales.GetUxB(art.cdarticulo) UXB,
       PKG_SLVArticulos.GetUbicacionArticulos(ART.cdarticulo) UBICACION
  from pedidos                ped,
       documentos             docped,
       detallepedidos         detped,
       articulos              art,
       DESCRIPCIONESARTICULOS DES
 where ped.iddoctrx = docped.iddoctrx
   and ped.idpedido = detped.idpedido
   and art.cdarticulo = detped.cdarticulo
   and ped.transid in ('MALEGREAOFFMDM')
   AND ART.CDARTICULO = DES.CDARTICULO
 GROUP BY ART.CDSECTOR,
          ART.cdarticulo,
          DES.VLDESCRIPCION)
WHERE TRUNC((CANT/UxB),0)>= 4 
--CANTIDAD MAXIMA DE BULTOS A CONSOLIDAR          
