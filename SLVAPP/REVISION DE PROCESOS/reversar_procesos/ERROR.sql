select cp.idconsolidadom, count(cp.idconsolidadopedido) 
  from tblslvconsolidadopedido cp 
group by cp.idconsolidadom;



select pfr.idpedfaltante from tblslvpedfaltanterel pfr where pfr.idpedfaltante not in (select pf.idpedfaltante from tblslvpedfaltante pf)

delete tblslvpedfaltanterel pfr where pfr.idpedfaltante not in (select pf.idpedfaltante from tblslvpedfaltante pf)

delete tblslvajustedistribucion aj where aj.idpedfaltante in(select pfr.idpedfaltante from tblslvpedfaltanterel pfr where pfr.idpedfaltante not in (select pf.idpedfaltante from tblslvpedfaltante pf))
delete tblslvdistribucionpedfaltante dpf where dpf.idpedfaltanterel in (select pfr.idpedfaltanterel from tblslvpedfaltanterel pfr where pfr.idpedfaltante not in (select pf.idpedfaltante from tblslvpedfaltante pf))
delete tblslvremitodet rd
delete tblslvremito re where re.idpedfaltanterel in (select pfr.idpedfaltanterel from tblslvpedfaltanterel pfr where pfr.idpedfaltante not in (select pf.idpedfaltante from tblslvpedfaltante pf))