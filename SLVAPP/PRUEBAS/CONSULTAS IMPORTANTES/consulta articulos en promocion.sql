SELECT aa.cdarticulo,da.vldescripcion,p.vigencia_desde,p.vigencia_hasta,p.id_promo
     FROM tblpromo p,
          tblpromo_tipo t,
          tblpromo_accion a,
          tblpromo_accion_articulo aa,
          tblpromo_canal k,
          tblpromo_sucursal s,
          descripcionesarticulos da
    WHERE     p.id_promo_tipo = t.id_promo_tipo
          and da.cdarticulo = aa.cdarticulo
          AND p.id_promo = a.id_promo
          AND a.id_promo_accion = aa.id_promo_accion
          and p.id_promo = k.id_promo
          and p.id_promo = s.id_promo
          AND t.id_promo_grupo = 1 -- que sea promo y no cup�n
          AND p.id_promo_estado = 1 -- activa
          and k.id_canal = 'TE' -- canal del pedido
          and s.cdsucursal = '0010' -- sucursal del pedido
        --  and aa.cdarticulo = '159952'-- articulo a distribuir
          
         -- and trunc(to_date('21/07/2020','dd/mm/yyyy')) between p.vigencia_desde and p.vigencia_hasta --vigente el d�a que se tom� el pedido          
         and da.vldescripcion like '%kg%' ;
         
SELECT *     
FROM tblpromo p 
where p.id_promo='9E8EB86D6572C68EE05310C8A8C07BA2';