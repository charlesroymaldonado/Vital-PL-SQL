create or replace trigger trg_log_vtexclients
  before update or delete on vtexclients
  for each row
declare
      v_modulo          varchar2(100) := 'trg_log_vtexclients';
      v_transaction     VARCHAR2(10);
begin
   -- determine the transaction type
   v_transaction := CASE  
                    WHEN UPDATING THEN 'UPD'
                    WHEN DELETING THEN 'DLT'
                    end;
  insert into vtexclientslog l  
              (l.id_cuenta,
               l.clientsid_vtex,
               l.cuit,
               l.razonsocial,
               l.email,
               l.cdsucursal,
               l.icactive,
               l.dtinsert,
               l.dtupdate,
               l.icprocesado,
               l.dtprocesado,
               l.observacion,
               l.agent,
               l.idagent,
               l.icalcohol,
               l.id_canal,
               l.dsnombrefantasia,
               l.icrevisadopos,
               l.tipo_accion)
       values (:old.id_cuenta,
               :old.clientsid_vtex,
               :old.cuit,
               :old.razonsocial,
               :old.email,
               :old.cdsucursal,
               :old.icactive,
               :old.dtinsert,
               :old.dtupdate,
               :old.icprocesado,
               :old.dtprocesado,
               :old.observacion,
               :old.agent,
               :old.idagent,
               :old.icalcohol,
               :old.id_canal,
               :old.dsnombrefantasia,
               :old.icrevisadopos,
               v_transaction); 
exception when others then
   n_pkg_vitalpos_log_general.write(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM);               
end log;
/
