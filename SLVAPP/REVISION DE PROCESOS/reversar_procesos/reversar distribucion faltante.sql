select * from tblslvtipotarea;
select * from tblslvestado;
select * from tblslvpedfaltante pf
where pf.idpedfaltante = &P_F;
select * from tblslvpedfaltanterel pfrel
where pfrel.idpedfaltante = &P_F;

--distribucion involucrada
select * from tblslvdistribucionpedfaltante dpf
where dpf.idpedfaltanterel in (select pfrel.idpedfaltanterel from tblslvpedfaltanterel pfrel
where pfrel.idpedfaltante = &P_F);

--consolidado pedido involucrada
select * from tblslvconsolidadopedido cp
where cp.idconsolidadopedido in (select pfrel.idconsolidadopedido from tblslvpedfaltanterel pfrel
where pfrel.idpedfaltante = &P_F);

--detalle consolidado pedido involucrada
select * from tblslvconsolidadopedidodet cpd
where cpd.idconsolidadopedido in (select pfrel.idconsolidadopedido from tblslvpedfaltanterel pfrel
where pfrel.idpedfaltante = &P_F);
--actualizo los articulos afectaos por la distribuicion 
--for update

--distribucion involucrada
select *from tblslvdistribucionpedfaltante dpf
where dpf.idpedfaltanterel in (select pfrel.idpedfaltanterel from tblslvpedfaltanterel pfrel
where pfrel.idpedfaltante = &P_F)

--ajsute involucrado
select * from tblslvajustedistribucion aj 
  where aj.iddistribucionpedfaltante in (select dpf.iddistribucionpedfaltante from tblslvdistribucionpedfaltante dpf
where dpf.idpedfaltanterel in (select pfrel.idpedfaltanterel from tblslvpedfaltanterel pfrel
where pfrel.idpedfaltante = &P_F) );

--remitos involucrados
select * from tblslvremito re
where re.idpedfaltanterel in (select pfrel.idpedfaltanterel from tblslvpedfaltanterel pfrel
where pfrel.idpedfaltante = &P_F);
--remitos detalle involucrados
select dre.* from tblslvremitodet dre,tblslvremito re
where re.idremito=dre.idremito
and re.idpedfaltanterel in (select pfrel.idpedfaltanterel from tblslvpedfaltanterel pfrel
where pfrel.idpedfaltante = &P_F);



-- actualizo tblslvpedfaltante a estado finalizado
update tblslvpedfaltante pf
   set pf.cdestado = 20
   where pf.idpedfaltante= &P_F;
   
-- actualizo tblslvpedfaltante a estado en curso
update tblslvconsolidadopedido cp
   set cp.cdestado = 11
   where cp.idconsolidadopedido in (select pfrel.idconsolidadopedido from tblslvpedfaltanterel pfrel
where pfrel.idpedfaltante = &P_F);

--delete de remitos involucrados
 delete tblslvremito re
where re.idpedfaltanterel in (select pfrel.idpedfaltanterel from tblslvpedfaltanterel pfrel
where pfrel.idpedfaltante = &P_F)
and re.idremito=96;
--delete de detalle remitos involucrados
delete tblslvremitodet rd1
where rd1.idremitodet in (
select dre.idremitodet from tblslvremitodet dre,tblslvremito re
where re.idremito=dre.idremito
and re.idpedfaltanterel in (select pfrel.idpedfaltanterel from tblslvpedfaltanterel pfrel
where pfrel.idpedfaltante = &P_F))
and rd1.idremito = 96;


--delete tblslvajustedistribucion
delete tblslvajustedistribucion aj 
  where aj.iddistribucionpedfaltante in (select dpf.iddistribucionpedfaltante from tblslvdistribucionpedfaltante dpf
where dpf.idpedfaltanterel in (select pfrel.idpedfaltanterel from tblslvpedfaltanterel pfrel
where pfrel.idpedfaltante = &P_F) );
--borrar distribucion involucrada
delete tblslvdistribucionpedfaltante dpf
where dpf.idpedfaltanterel in (select pfrel.idpedfaltanterel from tblslvpedfaltanterel pfrel
where pfrel.idpedfaltante = &P_F); 

-- finalmente actualizo tblslvconsolidadopedido a estado cerrado
update tblslvconsolidadopedido cp
   set cp.cdestado = 12
   where cp.idconsolidadopedido in (select pfrel.idconsolidadopedido from tblslvpedfaltanterel pfrel
where pfrel.idpedfaltante = &P_F);

