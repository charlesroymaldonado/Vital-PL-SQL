CREATE OR REPLACE TRIGGER trg_rep_tblslvremito
    after insert or update on SLVAPP.tblslvremito 
    for each row                                
declare
   v_modulo          varchar2(100) := 'trg_rep_tblslvremito';
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

   --Insertar la acción de réplica
   insert into tblReplica
   (idreplica, vlnombretabla, cdaccion, idtabla, cdestado, dtcambioestado)
   values
   (seq_tblreplica.nextval, 'tblslvremito', v_Accion,:new.idremito, REPLICAS_GENERAL.get_estado_inicial, sysdate);

exception when others then
   n_pkg_vitalpos_log_general.write(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM);

end;
/
