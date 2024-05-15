CREATE OR REPLACE TRIGGER trg_rep_consolidadopedidodet
    after insert or update ON SLVAPP.TBLSLVCONSOLIDADOPEDIDODET  for each row
declare
   v_modulo          varchar2(100) := 'trg_rep_consolidadopedidodet';
   v_Accion          varchar2(3);
 --  v_cdSucursal      sucursales.cdsucursal%type;
begin

   --Verificar si el trigger se disparó por causa del usuario o por causa del mecanismo de réplica.
   if replicas_general.get_marca_instancia is not null then  --Si se disparó por causa de AC
      return;                                                --Salir sin hacer nada
   end if;

   --Verificar el tipo de acción
   if inserting then
      v_Accion := REPLICAS_GENERAL.get_accion_insert;

   elsif updating then
      v_Accion := REPLICAS_GENERAL.get_accion_update;

   end if;

   --Buscar la sucursal
  -- v_cdSucursal := getvlparametro('CDSucursal', 'General');

   --Insertar la acción de réplica
   insert into tblReplica
   (idreplica, vlnombretabla, cdaccion, idtabla, cdestado, dtcambioestado/*, cdsucursal*/)
   values
   (seq_tblreplica.nextval, 'tblslvconsolidadopedidodet', v_Accion, :new.idconsolidadopedidodet, REPLICAS_GENERAL.get_estado_inicial, sysdate/*, v_cdSucursal*/);

exception when others then
   n_pkg_vitalpos_log_general.write(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM);

end;
/
