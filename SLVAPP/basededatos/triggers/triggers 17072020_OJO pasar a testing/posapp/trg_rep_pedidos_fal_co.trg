CREATE OR REPLACE TRIGGER POSAPP.trg_rep_pedidos_fal_co
    after insert ON POSAPP.PEDIDOS  for each row
declare
   v_modulo          varchar2(100) := 'trg_rep_pedidos_fal_co';
   v_Accion          varchar2(3);
  
begin
 
   --Verificar si el trigger se disparó por causa del usuario o por causa del mecanismo de réplica.
   if replicas_general.get_marca_instancia is not null then  --Si se disparó por causa de AC
      return;                                                --Salir sin hacer nada
   end if;
   if :new.id_canal = 'CO'  then-- solo para replica por faltantes de comisionistas en la sucursal
      
       --Verificar el tipo de acción
       v_Accion := REPLICAS_GENERAL.get_accion_insert; 
   
       --Insertar la acción de réplica
       insert into tblReplica
       (idreplica, vlnombretabla, cdaccion, idtabla, cdestado, dtcambioestado)
       values
       (seq_tblreplica.nextval, 'pedidos', v_Accion, :new.idpedido, REPLICAS_GENERAL.get_estado_inicial, sysdate);
   end if;
exception when others then
   n_pkg_vitalpos_log_general.write(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM);

end;
/
