select * 
  from tblslvconsolidadom cm
 where  cm.idconsolidadom = &P_IDCONSO;

select cmd.* 
  from tblslvconsolidadom cm,
       tblslvconsolidadomdet    cmd
 where cm.idconsolidadom=cmd.idconsolidadom
   and cm.idconsolidadom = &P_IDCONSO;
   
select * 
  from tblslvtarea t,
       tblslvtareadet td         
 where t.idtarea = td.idtarea 
   and t.idtarea = &P_IDTAREA;   


select * 
  from tblslvconsolidadopedido cp
 where cp.idconsolidadom = &P_IDCONSO;
     
select cpd.* 
  from tblslvconsolidadopedido cp,
       tblslvconsolidadopedidodet   cpd
 where cp.idconsolidadopedido=cpd.idconsolidadopedido
   and cp.idconsolidadom = &P_IDCONSO;
  

select * 
  from tblslvconsolidadocomi cc
 where cc.idconsolidadom = &P_IDCONSO;    
  
select * 
  from tblslvconsolidadocomi cc,
       tblslvconsolidadocomidet   ccd
 where cc.idconsolidadocomi=ccd.idconsolidadocomi
   and cc.idconsolidadom = &P_IDCONSO;   
   
