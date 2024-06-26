CREATE OR REPLACE TRIGGER trg_rep_pedgeneradoxfaltante
    after insert or update ON SLVAPP.tblslvpedidogeneradoxfaltante  for each row
declare
   v_modulo          varchar2(100) := 'trg_rep_pedidogeneradoxfaltante';
   v_Accion          varchar2(3);
begin

   --Verificar si el trigger se dispar� por causa del usuario o por causa del mecanismo de r�plica.
   if replicas_general.get_marca_instancia is not null then  --Si se dispar� por causa de AC
      return;                                                --Salir sin hacer nada
   end if;

   --Verificar el tipo de acci�n
   if inserting then
      v_Accion := REPLICAS_GENERAL.get_accion_insert;

   elsif updating then
      v_Accion := REPLICAS_GENERAL.get_accion_update;

   end if;

   --Insertar la acci�n de r�plica
   insert into tblReplica
   (idreplica, vlnombretabla, cdaccion, idtabla, cdestado, dtcambioestado)
   values
   (seq_tblreplica.nextval, 'tblslvpedidogeneradoxfaltante', v_Accion, :new.idpedidogen, REPLICAS_GENERAL.get_estado_inicial, sysdate);

exception when others then
   n_pkg_vitalpos_log_general.write(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM);

end;
/
