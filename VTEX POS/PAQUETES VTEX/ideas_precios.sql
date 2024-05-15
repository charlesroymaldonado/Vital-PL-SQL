select* from VTEXPRODUCT;
select* from VTEXSKU;
select* from VTEXPRICE;

--lista los articulos en VTEX con precio de lista agregados hoy
select * 
  from tblprecio p,
       vtexsku   vs 
 where p.cdarticulo = vs.refid
   and p.id_precio_tipo = 'PL'
   and p.id_canal in ('VE','CO')
   and p.dtvigenciadesde=&p_fecha;

--lista los articulos en VTEX que no tienen precio en VTEXPRICE
select * 
  from vtexsku   vs 
 where  vs.refid not in (select vp.refid from vtexprice vp)   
   
--lista los articulos en VTEX con precio de oferta agregados hoy
select * 
  from tblprecio p,
       vtexsku   vs 
 where p.cdarticulo = vs.refid
   and p.id_precio_tipo = 'OF'
   and p.id_canal in ('VE','CO')
   and p.dtvigenciadesde=&p_fecha; 

   
  
