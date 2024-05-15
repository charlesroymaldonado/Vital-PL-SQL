select distinct *
from tblslvpordistribfaltantes p
where p.idpedfaltante=&p_faltante
and p.cdtipo=40 
order by p.cdarticulo;

select * from tblslvpedfaltante pf where pf.idpedfaltante=&p_faltante;

select * from tblslvpedfaltantedet fd where fd.idpedfaltante=&p_faltante
order by fd.cdarticulo;

select * from tblslvpedfaltanterel pfr, tblslvdistribucionpedfaltante distfalt
where pfr.idpedfaltante=&p_faltante
and pfr.idpedfaltanterel=distfalt.idpedfaltanterel
order by distfalt.cdarticulo;

select * from tblslvremito r,
              tblslvremitodet rd,
              tblslvpedfaltanterel frel
where r.idpedfaltanterel = frel.idpedfaltanterel
  and frel.idpedfaltante = &p_faltante
  and r.idremito = rd.idremito;
  
select * 
  from tblslvajustedistribucion ad
 where ad.idpedfaltante=&p_faltante
 order by ad.cdarticulo;

select * 
  from tblslvconsolidadopedidodet pd 
 where pd.idconsolidadopedido in (select pf.idconsolidadopedido 
                                    from tblslvpedfaltanterel pf 
                                   where pf.idpedfaltante=&p_faltante)
order by pd.cdarticulo;                                   

--para borrar distribuciones
/*delete tblslvAjusteDistribucion aj where aj.idpedfaltante = &P_fal;
delete from tblslvdistribucionpedfaltante pf where pf.idpedfaltanterel in (select pfal.idpedfaltanterel from tblslvpedfaltanterel pfal where pfal.idpedfaltante = &P_fal);
update tblslvpedfaltante pfa set pfa.cdestado = 20--finalizado
where pfa.idpedfaltante=&P_fal;*/
