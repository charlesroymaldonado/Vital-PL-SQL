CREATE OR REPLACE TRIGGER trg_rep_detallepedidos
    after insert ON POSAPP.DETALLEPEDIDOS  for each row
declare
   v_modulo          varchar2(100) := 'trg_rep_detallepedidos';
   v_Accion          varchar2(3);
  -- v_cdSucursal      sucursales.cdsucursal%type;
begin
 
   --Verificar si el trigger se disparó por causa del usuario o por causa del mecanismo de réplica.
   if replicas_general.get_marca_instancia is not null then  --Si se disparó por causa de AC
      return;                                                --Salir sin hacer nada
   end if;
  -- if :new.id_canal in ('CO') and :new.transid like '%-PGF' then-- solo para replica por faltantes de comisionistas en la sucursal
      
       --Verificar el tipo de acción
       v_Accion := REPLICAS_GENERAL.get_accion_insert;

     /*  --Buscar la sucursal
       v_cdSucursal := getvlparametro('CDSucursal', 'General');*/

       --Insertar la acción de réplica
       insert into tblReplica
       (idreplica, vlnombretabla, cdaccion, idtabla, cdestado, dtcambioestado)
       values
       (seq_tblreplica.nextval, 'detallepedidos', v_Accion, :new.sqdetallepedido, REPLICAS_GENERAL.get_estado_inicial, sysdate);
  -- end if;
exception when others then
   n_pkg_vitalpos_log_general.write(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM);

end;
/
