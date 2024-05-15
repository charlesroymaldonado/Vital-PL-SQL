select * from tblslvconsolidadopedido;

update tblslvconsolidadopedido cp
set cp.id_canal ='CO',
    cp.cdsucursal='0010'
where cp.idconsolidadocomi is not null;

update tblslvconsolidadopedido cp
set cp.id_canal ='TE',
    cp.cdsucursal='0010'
where cp.idconsolidadocomi is null;

select * from tblslvconsolidadopedidodet;

update tblslvconsolidadopedidodet cpd
set cpd.cdsucursal='0010';

select * from tblslvconsolidadom;

update tblslvconsolidadom 
set cdsucursal='0010';

select * from tblslvconsolidadomdet;

update tblslvconsolidadomdet 
set cdsucursal='0010';

select * from tblslvtarea;

update tblslvtarea 
set cdsucursal='0010';

select * from tblslvtareadet;

update tblslvtareadet
set cdsucursal='0010';

select * from tblslvremito;

update tblslvremito
set cdsucursal='0010';

select * from tblslvremitodet;

update tblslvremitodet 
set cdsucursal='0010';

select * from tblslvControlRemito;

update tblslvcontrolremito
set cdsucursal='0010';

select * from tblslvControlRemitoDet;

update tblslvcontrolremitodet
set cdsucursal='0010';



