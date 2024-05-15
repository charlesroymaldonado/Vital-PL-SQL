CREATE OR REPLACE TRIGGER trg_rep_tblslvtarea
    after insert or update on SLVAPP.tblslvtarea for each row                                
declare
   v_modulo          varchar2(100) := 'trg_rep_tblslvtarea';
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
   
   --inserta solo si es tarea de pedido
   --elimino la condici�n por reportes de BW
 --  if :new.idconsolidadopedido is not null then
      --Insertar la acci�n de r�plica
      insert into tblReplica
        (idreplica, vlnombretabla, cdaccion, idtabla, cdestado, dtcambioestado)
      values
        (seq_tblreplica.nextval, 'tblslvtarea', v_Accion,:new.idtarea, REPLICAS_GENERAL.get_estado_inicial, sysdate);
   -- end if;    

exception when others then
   n_pkg_vitalpos_log_general.write(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM);

end;
/