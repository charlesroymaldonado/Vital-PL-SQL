--22/06/2020
insert into tblslvestado values(43,'Inicia Control','IniciaControl');
insert into tblslvestado values(44,'Controlado','Controlado');
insert into tblslvestado values(45,'Controlado Con Error','ControladoConError');

alter table TBLSLVTIPOTAREA add iccontrolaremito inteGER default 0;

 update tblslvtipotarea tt
    set tt.iccontrolaremito=1
  where tt.cdtipo in (25,50)
  
  