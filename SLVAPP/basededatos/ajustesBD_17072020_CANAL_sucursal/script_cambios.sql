
alter table TBLSLVCONSOLIDADOPEDIDO add id_canal varchar2(2) not null;

alter table TBLSLVCONSOLIDADOPEDIDO modify cdsucursal not null;
alter table TBLSLVCONSOLIDADOPEDIDODET modify cdsucursal not null;

alter table TBLSLVCONSOLIDADOM modify cdsucursal not null;
alter table TBLSLVCONSOLIDADOMDET modify cdsucursal not null;


alter table TBLSLVTAREA modify cdsucursal not null;
alter table TBLSLVTAREADET modify cdsucursal not null;

alter table TBLSLVREMITO modify cdsucursal not null;
alter table TBLSLVREMITODET modify cdsucursal not null;


-- Create/Recreate primary, unique and foreign key constraints 

alter table TBLSLVCONSOLIDADOPEDIDO
  add constraint FK_SUCURSALES_CONSOPEDIDO foreign key (CDSUCURSAL)
  references POSAPP.sucursales (CDSUCURSAL);
  
alter table TBLSLVCONSOLIDADOPEDIDODET
  add constraint FK_SUCURSALES_CONSOLIDPEDDET foreign key (CDSUCURSAL)
  references POSAPP.sucursales (CDSUCURSAL);

alter table TBLSLVCONSOLIDADOM
  add constraint FK_SUCURSALES_CONSOLIDADOM foreign key (CDSUCURSAL)
  references POSAPP.sucursales (CDSUCURSAL);
  
alter table TBLSLVCONSOLIDADOMDET
  add constraint FK_SUCURSALES_CONSOLIDADOMDET foreign key (CDSUCURSAL)
  references POSAPP.sucursales (CDSUCURSAL);

alter table TBLSLVTAREA
  add constraint FK_SUCURSALES_TAREA foreign key (CDSUCURSAL)
  references POSAPP.sucursales (CDSUCURSAL);
  
alter table TBLSLVTAREADET
  add constraint FK_SUCURSALES_TAREADET foreign key (CDSUCURSAL)
  references POSAPP.sucursales (CDSUCURSAL);
  
alter table TBLSLVREMITO
  add constraint FK_SUCURSALES_REMITO foreign key (CDSUCURSAL)
  references POSAPP.sucursales (CDSUCURSAL);

alter table TBLSLVREMITODET
  add constraint FK_SUCURSALES_REMITODET foreign key (CDSUCURSAL)
  references POSAPP.sucursales (CDSUCURSAL); 
  

  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  