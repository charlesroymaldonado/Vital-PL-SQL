select * from tblslvtareadet;
select * from tblslvtarea;
update tblslvconsolidadomdet m
set m.qtunidadmedidabasepicking=null
where m.idconsolidadom=1;
delete tblslvtareadet;
delete tblslvtarea;
