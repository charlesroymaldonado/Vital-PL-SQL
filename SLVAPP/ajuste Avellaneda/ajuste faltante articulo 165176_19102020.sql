select * from tblslvremito r where r.idtarea = 31 ;

select * from tblslvremito r where r.idremito= 74 ;


select * from tblslvremitodet rd where rd.idremito= 76 and rd.cdarticulo= '0165176'; --for update;

select * from tblslvpedfaltantedet fd where fd.idpedfaltante in (select pfrel.idpedfaltante from tblslvpedfaltanterel pfrel where pfrel.idpedfaltanterel=12 )
  and fd.cdarticulo= '0165176';--for update;
  
 select * from tblslvconsolidadopedidodet pd where pd.idconsolidadopedido= 12 and pd.cdarticulo= '0165176';-- for update;
 
 select * from tblslvtareadet td where td.idtarea in (select ta.idtarea from tblslvtarea ta where ta.idpedfaltante=7 )
     and td.cdarticulo= '0165176';-- for update;
     
 select * from tblslvdistribucionpedfaltante dp where dp.idpedfaltanterel in (select r.idpedfaltanterel from tblslvremito r where r.idremito= 76)
  and dp.cdarticulo= '0165176';--   for update;
  
  select * from tblslvajustedistribucion ad where ad.idpedfaltante = 7 and ad.cdarticulo= '0165176';-- for update;  

  
  select * from tblslvconsolidadopedido cp where cp.idconsolidadopedido in (select pfrel.idconsolidadopedido from tblslvpedfaltanterel pfrel where pfrel.idpedfaltanterel=12 );
