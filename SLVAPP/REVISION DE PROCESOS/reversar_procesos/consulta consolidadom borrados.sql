select * from  tblslvconsolidadopedido cp where cp.idconsolidadom=&p_idconsoM;
select * from  tblslvconsolidadopedido cp where cp.idconsolidadom=&p_idconsoM;
select * from  tblslvconsolidadom cm where cm.idconsolidadom=&p_idconsoM;


select * 
  from tblslvconsolidadopedidorel prel 
 where prel.idconsolidadopedido in (select cp.idconsolidadopedido 
                                      from tblslvconsolidadopedido cp 
                                     where cp.idconsolidadom=&p_idconsoM);

select pf.*, cp.idconsolidadom 
  from tblslvpedfaltanterel pf,
       tblslvdistribucionpedfaltante dpf,
       tblslvconsolidadopedido cp
 where pf.idpedfaltanterel = dpf.idpedfaltanterel
   and cp.idconsolidadopedido = pf.idconsolidadopedido;
 
     
