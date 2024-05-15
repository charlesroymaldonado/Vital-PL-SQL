CREATE OR REPLACE TRIGGER trg_rep_consolidadopedido
    after insert or update ON SLVAPP.TBLSLVCONSOLIDADOPEDIDO  for each row
declare
   v_modulo          varchar2(100) := 'trg_rep_consolidadopedido';
   v_Accion          varchar2(3);
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

   --Insertar la acción de réplica
   insert into tblReplica
   (idreplica, vlnombretabla, cdaccion, idtabla, cdestado, dtcambioestado, cdsucursal)
   values
   (seq_tblreplica.nextval, 'tblslvconsolidadopedido', v_Accion, :new.IDCONSOLIDADOPEDIDO, REPLICAS_GENERAL.get_estado_inicial, sysdate, :new.cdsucursal);

exception when others then
   n_pkg_vitalpos_log_general.write(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM);

end;
/
