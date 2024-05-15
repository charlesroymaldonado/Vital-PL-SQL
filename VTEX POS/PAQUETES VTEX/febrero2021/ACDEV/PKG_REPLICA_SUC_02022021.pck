CREATE OR REPLACE PACKAGE PKG_REPLICA_SUC IS

TYPE cur_typ        IS REF CURSOR;

TYPE t_tblReplica IS RECORD(
   IDREPLICA     number,
   VLNOMVRETABLA varchar2(100),
   CDACCION      varchar2(3),
   IDTABLA       varchar2(40),
   IDCOMPUESTO   varchar2(2000)
);

TYPE t_Columna IS RECORD( VLNOMBRECOLUMNA varchar2(100) );

TYPE reg_ListaInsert IS RECORD( id varchar2(40) );

TYPE tab_ListaInsert IS TABLE OF reg_ListaInsert INDEX BY BINARY_INTEGER;

procedure TraerCierreLote(p_servidor in  sucursales.servidor%type, -- RLC, 10/08/16 SOLO PARA PROBAR CON TEST, QUITAR
                          p_cdAccion in  varchar2,
                          p_id       in  varchar2,
                          p_ok       out integer );

procedure Iniciar(p_servidor in sucursales.servidor%type default null);

procedure TraerImpDocumentoDetalle (p_servidor in  sucursales.servidor%type,
                                  p_cdAccion in  varchar2,
                                  p_id       in  varchar2,
                                  p_ok       out integer );
                                  
procedure TraerDetallemovmateriales (p_servidor in  sucursales.servidor%type,
                                  p_cdAccion in  varchar2,
                                  p_id       in  varchar2,
                                  p_idCompuesto in  varchar2,
                                  p_ok       out integer );                                  


function GetIdPorPosicion(p_idCompuesto in varchar2,
                          p_vlPosicion  in integer)
return varchar2;

function GetActiva(p_cdSucursal in sucursales.cdsucursal%type)
return integer;





END;
/
CREATE OR REPLACE PACKAGE BODY PKG_REPLICA_SUC IS
/**************************************************************************************************
* ESTE PKG SOLO ESTA EN AC - Replicar desde la sucursale hacia AC y desde AC hacia la sucursales
*
* *********************************************
* *** ATENCION                              ***
* *********************************************
* - En los casos que solo deba replicarse desde AC hacia la sucursal deberá usarse vista materializada.
* - El mecanismo de replica bi-direccional es más complejo y deberá usarse SOLO en pocos casos.
* - Este mecanismo NO envía datos generados en la sucursal A hacia la sucursal B.
* - Este mecanismo replica solo acciones de INSERT y UPDATE (NO REPLICA ACCIONES DELETE).
* - Para que una tabla pueda replicarse por este mecanismo debe tener una PK de un solo campo generada
*   por el sys_guid().  Si se desea replicarla de forma bi-direccional la tabla debe tener el campo
*   cdsucursal.
*
* *********************************************
* *** INSTRUCCIONES PARA REPLICAR UNA TABLA ***
* *********************************************
* Instrucciones para replicar los datos desde la sucursal hacia AC (parado en la sucursal).
* - Crear un trigger de la tabla.  Tomar como ejemplo el trg_rep_tblcobranza (Cuando sea posible se debe evitar el uso
    de la v_cdSucursal dentro del trigger utilizando en su lugar :new.cdSucursal como está en trg_rep_tblcuenta).
* - Generar un sinónimo público a la tabla.
* - Otorgar grants de SELECT_POSAPP_ROLE, INSERT_POSAPP_ROLE, UPDATE_POSAPP_ROLE, DELETE_POSAPP_ROLE sobre la tabla
*
* Instrucciones adicionales si se desea una réplica bi-direccional (parado en AC).
* - Crear el mismo trigger de la tabla que se usó en la sucursal pero ahora en AC. Tomar como ejemplo el trg_rep_tblcuenta
*   (NUNCA debe usarse la v_cdSucursal dentro del trigger).
*
* Ya sea que se necesite la réplica solo hacia AC o bi-direccional se deberá modificar el código
* del PKG_REPLICA_SUC que está en AC.
*
* *********************************************
* *** DESCRIPCION DEL MECANISMO DE REPLICA  ***
* *********************************************
* Básicamente el mecanismo funciona de la siguiente forma.
* -Cuando se hace insert o update en una tabla programada para replicarse se dispara un trigger que escribe en la tblReplica.
* -En AC existe un job que automáticamente ejecuta el PKG_REPLICA_SUC.Iniciar que es el encargado de Traer datos
*  hacia AC y de Llevar datos hacia la sucursal.
*
* *********************************************
* *** MONITOREAR LAS REPLICAS               ***
* *********************************************
* Para saber el estado de las replicas en una sucursal se debe consultar la tblReplica. El estado indica si fue o
* no replicado (1=A replicar y 3=Replicado).
*
* En AC también existe la tblReplica para aquellos datos que AC debe enviar a la sucursal y por lo tanto también se puede
* consultar su estado.
* Adicionalmente en AC existe la tblReplicaControl en dónde se deja un resumen de la última corrida de réplica.
* En esta tabla se puede ver la fecha y hora de inicio, fecha y hora de fin o el error que no permitió finalizar.  También
* puede ver cuántos registros se replicaron OK y cuantos tuvieron algún error.  En caso de error el PKG loguea (como siempre)
* en la tbllog_general.
*
* *********************************************
* *** PARAMETROS DE CONTROL                 ***
* *********************************************
* g_CantMaxTraer     = Cantidad Máxima de registros que se trae por cada corrida (Ej: 500 registros).
* g_CantMaxLlevar    = Cantidad Máxima de registros que se llevan por cada corrida (Ej: 500 registros).
* g_CantMaxMinutos   = Cantidad Máxima de minutos para llevar o traer datos, pasado este tiempo aborta (Ej: 10 minutos).
*
* %v 03/06/2014 - MarianoL
***************************************************************************************************/

g_vlRegistrosOK    number := 0;
g_vlRegistrosError number := 0;
g_ListaInsert      tab_ListaInsert;

g_CantMaxTraer     number := 1000;  --Cantidad Máxima de registros que se trae por cada corrida
g_CantMaxLlevar    number := 1000;  --Cantidad Máxima de registros que se llevan por cada corrida
g_CantMaxMinutos   number := 10;   --Cantidad Máxima de minutos para llevar o traer datos

c_servidorcc       varchar2(4) := 'cc'; --Servidor de CallCenter

/**************************************************************************************************
* Grabar log de replicas en tabla de log nueva solo para errores de replicas.
* %v 17/04/2018 - IAquilano
***************************************************************************************************/

PROCEDURE GrabarLog (
                 pi_codigo  tbllog_general.id_log_general%type,
                 pi_mensaje tbllog_general.mensaje%type
        ) IS

PRAGMA AUTONOMOUS_TRANSACTION;

CURSOR c_tbllog_replica IS
SELECT machine, program
FROM   v$session
WHERE  audsid=userenv('SESSIONID');

BEGIN

FOR r_tbllog_replica IN c_tbllog_replica LOOP
    INSERT INTO tbllog_replica
    (id_log_general, codigo, mensaje, FECHA_ULTIMA_MODIFICACION, usuario, programa, maquina)
    VALUES
    (sys_guid(),pi_codigo, pi_mensaje, systimestamp, user, r_tbllog_replica.program, r_tbllog_replica.machine);
    COMMIT;
END LOOP;
END GrabarLog;

/**************************************************************************************************
* Devuelve la lista de campos separados por coma (que no forman parte de la PK) de una tabla
* %v 03/06/2014 - MarianoL
***************************************************************************************************/
function GetCamposTabla(p_strTabla varchar2)
return varchar2
is
   v_modulo           varchar2(100) := 'PKG_REPLICA_SUC.GetCamposTabla';
   v_Return           varchar2(4000) := '';
   v_Columna          t_Columna;
   v_EsPrimeraColumna number := 1;
begin

   for v_Columna in (Select column_name
                       From user_tab_columns
                      Where table_name = upper(p_strTabla)
                        And data_type Not In ('LONG', 'BLOB', 'CLOB')
                     Minus
                     Select cc.column_name
                       From user_cons_columns cc, user_constraints c
                      Where cc.OWNER = c.OWNER
                        And cc.CONSTRAINT_NAME = c.CONSTRAINT_NAME
                        And cc.TABLE_NAME = c.TABLE_NAME
                        And c.CONSTRAINT_TYPE = 'P'
                        And c.TABLE_NAME = upper(p_strTabla))
   loop
      if v_EsPrimeraColumna = 1 then
         v_Return := v_Return || v_Columna.Column_Name;
         v_EsPrimeraColumna := 0;
      else
         v_Return := v_Return || ',' || v_Columna.Column_Name;
      end if;
   end loop;

   return v_Return;

exception when others then
   GrabarLog(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM);
   return(null);
end GetCamposTabla;

/**************************************************************************************************
* Esta función fue creada para que otros PKG no necesiten verificar si el enlace con la sucursal está ok
* ya que cuando el enlace está caido demora mucho en responder.  En lugar de eso se puede llamar a esta
* función que verifica si el enlace está activo y si ya fue previamete marcado con error
* en la tblreplicaactiva.
* %v 30/12/2015 - MarianoL
***************************************************************************************************/
function GetActiva(p_cdSucursal in sucursales.cdsucursal%type)
return integer
is
   v_icReplicaActiva    tblreplicaactiva.icreplicaactiva%type;
   v_vlCantErrorEnlace  tblreplicaactiva.vlcantidaderrorenlace%type;

begin

   select ra.icreplicaactiva, nvl(ra.vlcantidaderrorenlace,0)
   into v_icReplicaActiva, v_vlCantErrorEnlace
   from tblreplicaactiva ra
   where ra.cdsucursal = p_cdSucursal;

   if v_icReplicaActiva = 0 or v_vlCantErrorEnlace > 0 then
      return 0; --Replica no activa o con error de enlace
   else
      return 1; --Replica no activa o con error de enlace
   end if;

exception when others then
   return 0;
end GetActiva;

/**************************************************************************************************
* Verifica si hay enlace con la sucursal.  Devuelve 1 si hay enlace.
* %v 27/08/2015 - MarianoL
* %v 26/05/2017 - JBodnar: Si la replica no esta activa retorna corte de enlace
***************************************************************************************************/
function GetEnlaceOK(p_servidor in char)
return integer
is
   v_Return     integer := 0;
   v_Intentos   integer := 0;
   v_cdsucursal sucursales.cdsucursal%type;

begin
   --Si la replica no esta activa retorna corte de enlace
   select s.cdsucursal
   into v_cdsucursal
   from sucursales s
   where s.servidor = p_servidor;

   If GetActiva(v_cdsucursal)= 0 then
     v_Return := 0;
     return v_Return;
   end if;

   while (v_Intentos < 5) and (v_Return = 0)
   loop
      v_Intentos := v_Intentos + 1;

      --Verificar si hay enlace con la sucursal
      if REPLICAS_GENERAL.CHECK_DBLINK(p_servidor) then
         v_Return := 1;
      else
         DBMS_LOCK.SLEEP(1);  --Esperar 1 segundo para volver a intentar
      end if;

   end loop;

   return v_Return;

exception when others then
   return 0;
end GetEnlaceOK;

/**************************************************************************************************
* Dada una clave compuesta y una posición, devuelve el valor que hay en esa posición.
* El p_idCompusta debe contener una serie de valores separados por coma.
* Ej: '268E3490B4CFA2DDE050A8C03CDF5D6A        ,2       ,1'
* %v 10/12/2015 - MarianoL
***************************************************************************************************/
function GetIdPorPosicion(p_idCompuesto in varchar2,
                          p_vlPosicion  in integer)
return varchar2
is
   v_Return    varchar2(1000) := null;
   v_desde     integer;
   v_hasta     integer;

begin

   if p_vlPosicion = 1 then
      v_desde := 1;
   else
      v_desde := instr(p_idCompuesto, ',' , 1, p_vlPosicion-1) + 1;
   end if;

   v_hasta := instr(p_idCompuesto||',', ',' , 1, p_vlPosicion) - 1;

   v_Return := substr(p_idCompuesto, v_desde, v_hasta-v_desde+1);

   v_Return := replace(v_Return,''''); --Sacarle las comillas

   return v_Return;

exception when others then
   return null;
end GetIdPorPosicion;

/**************************************************************************************************
* ReplicarTodasSucursales
* Agendar el registro para ser replicado a todas las sucursales salvo la de origen
* %v 16/12/2015 - MarianoL
* %v 05/04/2018 - JBodnar: Replica a todas menos al parametro recibido que es un default
***************************************************************************************************/
procedure ReplicarTodasSucursales(p_ServidorOrigen in sucursales.servidor%type,
                                  p_vlNombreTabla  in tblreplica.vlnombretabla%type,
                                  p_cdAccion       in tblreplica.cdaccion%type,
                                  p_id             in tblreplica.idtabla%type,
                                  p_idCompuesto    in tblreplica.idcompuesto%type,
                                  p_cdsucursal     in sucursales.cdsucursal%type default null)
is
   v_modulo           varchar2(100) := 'PKG_REPLICA_SUC.ReplicarTodasSucursales';
begin

   --Agendar la réplica hacia el resto de las sucursales
   for v_RegSucursal in (select s.cdsucursal
                         from sucursales s
                         where s.servidor is not null
                           and lower(s.servidor) not in ('ac')
                           and lower(s.servidor) <> nvl(lower(p_ServidorOrigen),'X')
                         order by s.cdsucursal)
   loop
      --Solo replica en las sucursales distintas
      if trim(nvl(p_cdsucursal,'x')) <>  trim(v_RegSucursal.Cdsucursal) then
        --Insertar la acción de réplica
        insert into tblReplica
        (idreplica, vlnombretabla, cdaccion, idtabla, cdestado, dtcambioestado, cdsucursal, idcompuesto)
        values
        (seq_tblreplica.nextval, p_vlNombreTabla, p_cdAccion, p_id, REPLICAS_GENERAL.get_estado_inicial, sysdate, v_RegSucursal.Cdsucursal, p_idCompuesto);
      end if;

   end loop;

exception when others then
   GrabarLog(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM);
end ReplicarTodasSucursales;

/**************************************************************************************************
* ReplicarUnicaSucursal
* Envia el dato de la sucursal origen a solo una sucursal destino
* %v 02/08/2016 - JBodnar
***************************************************************************************************/
procedure ReplicarUnicaSucursal  (p_SucursalDestino in sucursales.cdsucursal%type,
                                  p_vlNombreTabla   in tblreplica.vlnombretabla%type,
                                  p_cdAccion        in tblreplica.cdaccion%type,
                                  p_id              in tblreplica.idtabla%type)
is
   v_modulo           varchar2(100) := 'PKG_REPLICA_SUC.ReplicarUnicaSucursal';
begin

    --Insertar la acción de réplica
    insert into tblReplica
    (idreplica, vlnombretabla, cdaccion, idtabla, cdestado, dtcambioestado, cdsucursal)
    values
    (seq_tblreplica.nextval, p_vlNombreTabla, p_cdAccion, p_id, REPLICAS_GENERAL.get_estado_inicial, sysdate, p_SucursalDestino);

exception when others then
   GrabarLog(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM);
end ReplicarUnicaSucursal;

/**************************************************************************************************
* VerificarExistaEntidad
* Verificar que la entidad exista, en caso que no exista la inserta
* %v 16/12/2015 - MarianoL
***************************************************************************************************/
procedure VerificarExistaEntidad(p_Servidor   in sucursales.servidor%type,
                                 p_idEntidad in entidades.identidad%type)
is
   v_modulo           varchar2(100) := 'PKG_REPLICA_SUC.VerificarExistaEntidad';
   v_Existe           integer;
   v_SQL              varchar2(4000);

begin

   --Verificar si existe
   v_SQL := 'select count(*) from entidades@'||p_Servidor||' where identidad = '''||p_idEntidad||'''';
   execute immediate v_SQL into v_Existe;

   --Si no existe hay que insertarla
   if v_Existe = 0 then
      v_SQL := 'insert into entidades@' || p_servidor;
      v_SQL := v_SQL || ' (select * from entidades where identidad =''' || p_idEntidad ||''')';
      execute immediate v_SQL;
   end if;

   return;

exception when others then
   GrabarLog(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM);
end VerificarExistaEntidad;

/**************************************************************************************************
* VerificarExistaPersona
* Verificar que la persona exista, en caso que no exista la inserta
* %v 16/12/2015 - MarianoL
***************************************************************************************************/
procedure VerificarExistaPersona(p_Servidor  in sucursales.servidor%type,
                                 p_idPersona in personas.idpersona%type)
is
   v_modulo           varchar2(100) := 'PKG_REPLICA_SUC.VerificarExistaPersona';
   v_Existe           integer;
   v_SQL              varchar2(4000);
   v_cdLegajo         personas.cdlegajo%type;
   v_dsCuil           personas.dscuil%type;
   v_nudocumento      personas.nudocumento%type;

begin
   if p_idPersona is null then
      return;
   end if;

   --Verificar si existe
   v_SQL := 'select count(*) from personas@'||p_Servidor||' where idpersona = '''||p_idPersona||'''';
   execute immediate v_SQL into v_Existe;

   --Si no existe hay que insertarla
   if v_Existe = 0 then
      begin
         v_SQL := 'insert into personas@' || p_servidor;
         v_SQL := v_SQL || ' (select * from personas where idpersona =''' || p_idPersona ||''')';
         execute immediate v_SQL;
      exception when DUP_VAL_ON_INDEX then
         --eliminar otras personas que tengan el mismo legajo
         select p.cdlegajo, p.dscuil, p.nudocumento
         into v_cdLegajo, v_dsCuil, v_nuDocumento
         from personas p
         where p.idpersona = p_idPersona;

         if v_cdLegajo is not null then
            --Eliminar el legajo
            v_SQL := 'update personas@'||p_servidor||' set cdlegajo = null where cdlegajo =''' || v_cdLegajo ||'''';
            execute immediate v_SQL;

            --Eliminar el CUIL
            v_SQL := 'update personas@'||p_servidor||' set dscuil = null where dscuil =''' || v_dsCuil ||'''';
            execute immediate v_SQL;

            --Eliminar el Documento
            v_SQL := 'update personas@'||p_servidor||' set nudocumento = null where nudocumento = ' || v_nudocumento ;
            execute immediate v_SQL;

            --Intentar nuevamente insertar la persona
            v_SQL := 'insert into personas@' || p_servidor;
            v_SQL := v_SQL || ' (select * from personas where idpersona =''' || p_idPersona ||''')';
            execute immediate v_SQL;
         end if;
      end;
   end if;

   return;

exception when others then
   GrabarLog(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM||' Suc: '||p_Servidor||' Sql: '||v_SQL);
   raise;
end VerificarExistaPersona;

/**************************************************************************************************
* VerificarExistaUsuario
* Verificar que la persona exista, en la tabla de cuentasusuarios
* %v 28/12/2015 - JBodnar
***************************************************************************************************/
procedure VerificarExistaUsuario(p_Servidor  in sucursales.servidor%type,
                                 p_idPersona in personas.idpersona%type)
is
   v_modulo           varchar2(100) := 'PKG_REPLICA_SUC.VerificarExistaUsuario';
   v_Existe           integer;
   v_SQL              varchar2(4000);

begin
   if p_idPersona is null then
      return;
   end if;

   --Verificar si existe
   v_SQL := 'select count(*) from cuentasusuarios@'||p_Servidor||' where idpersona = '''||p_idPersona||'''';
   execute immediate v_SQL into v_Existe;

   --Si no existe hay que insertarla
   if v_Existe = 0 then
      v_SQL := 'insert into cuentasusuarios@' || p_servidor;
      v_SQL := v_SQL || ' (select * from cuentasusuarios where idpersona =''' || p_idPersona ||''')';
      execute immediate v_SQL;
   end if;

   return;

exception when others then
   GrabarLog(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM);
end VerificarExistaUsuario;

/**************************************************************************************************
* Marcar el registro como ya insertado
* %d Una vez que un registro es insertado el proceso ignorará los updates que vengan luego ya que
*    no producirán cambios sobre el registro y de esta forma se mejora la performance.
* %v 03/06/2014 - MarianoL
***************************************************************************************************/
procedure SetRegistroInsertado(p_id in varchar2)
is
   v_modulo           varchar2(100) := 'PKG_REPLICA_SUC.SetRegistroInsertado';
   i                  BINARY_INTEGER := 0;
begin

   i := g_ListaInsert.COUNT + 1;
   g_ListaInsert(i).id := p_id;

exception when others then
   GrabarLog(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM);
end SetRegistroInsertado;

/**************************************************************************************************
* Verificar si el registro fue insertardo en esta corrida
* %d Una vez que un registro es insertado el proceso ignorará los updates que vengan luego ya que
*    no producirán cambios sobre el registro y de esta forma se mejora la performance.
* %v 03/06/2014 - MarianoL
***************************************************************************************************/
function GetRegistroInsertado(p_id in varchar2)
return number
is
   v_modulo           varchar2(100) := 'PKG_REPLICA_SUC.GetRegistroInsertado';
   i                  BINARY_INTEGER := 0;
begin

   i := g_ListaInsert.FIRST;
   WHILE i IS NOT NULL LOOP
      if g_ListaInsert(i).id = p_id then
         return(1);  --Ya fue insertado
      end if;
      i := g_ListaInsert.NEXT(i);
   END LOOP;

   return(0); --No fue insertado

exception when others then
   GrabarLog(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM);
end GetRegistroInsertado;

/**************************************************************************************************
* Marcar la instancia para evitar recursividad
* %v 03/06/2014 - MarianoL
***************************************************************************************************/
procedure DetenerTriggerAC
is
   v_modulo           varchar2(100) := 'PKG_REPLICA_SUC.DetenerTriggerAC';
begin

   if replicas_general.SET_MARCA_INSTANCIA(1) <> 1 then
      GrabarLog(2, 'Modulo: '||v_modulo||'  Error al marcar la instancia en AC.');
   end if;

exception when others then
   GrabarLog(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM);
end DetenerTriggerAC;

/**************************************************************************************************
* Marcar la instancia para evitar recursividad
* %v 03/06/2014 - MarianoL
***************************************************************************************************/
procedure DetenerTriggerSucursal(p_servidor in  sucursales.servidor%type)
is
   v_modulo           varchar2(100) := 'PKG_REPLICA_SUC.DetenerTriggerSucursal';
   strSQL             varchar2(4000);
   v_marca_instancia  number;
begin

   strSQL := 'BEGIN :1 := REPLICAS_GENERAL.SET_MARCA_INSTANCIA@';
   strSQL := strSQL || p_servidor || '(1); end;';
   EXECUTE IMMEDIATE strSQL USING in out v_marca_instancia;
   IF v_marca_instancia != 1 THEN
      GrabarLog(2, 'Modulo: '||v_modulo||'  Error al marcar la instancia en la sucursal.');
   END IF;

exception when others then
   GrabarLog(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM ||' suc: '||p_servidor);
end DetenerTriggerSucursal;

/**************************************************************************************************
* Graba la feha y hora de inicio de replica en la tblReplicaControl
* %v 03/06/2014 - MarianoL
* %v 18/07/2016 - APW - en el update de tblreplicaactiva pongo en 1 el indicador
***************************************************************************************************/
procedure MarcarInicioReplica(p_cdSucursal in sucursales.cdsucursal%type)
is
   v_modulo           varchar2(100) := 'PKG_REPLICA_SUC.MarcarInicioReplica';
   v_existe           number;
begin

   --Ver si hay que hacer insert o update
   select count(*)
   into v_existe
   from tblreplicacontrol rc
   where rc.cdsucursal = p_cdSucursal;

   if v_existe = 0 then
      insert into tblreplicacontrol (cdsucursal, dtinicioreplica, vlregistrosok, vlregistroserror)
      values (p_cdSucursal, sysdate, g_vlRegistrosOK, g_vlRegistrosError);
   else
      update tblreplicacontrol rc
      set rc.dtinicioreplica = sysdate,
          rc.dtfinreplicaok = null,
          rc.dserror = 'Replicando...',
          rc.vlregistrosok = g_vlRegistrosOK,
          rc.vlregistroserror = g_vlRegistrosError
      where rc.cdsucursal = p_cdSucursal;
   end if;

   --Updatear contador de errores
   update tblreplicaactiva ra
   set ra.vlcantidaderrorenlace = null,
       ra.dterrorenlace = null,
       ra.icreplicaactiva = 1
   where ra.cdsucursal = p_cdSucursal;

   commit;
   return;

exception when others then
   GrabarLog(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM ||' suc: '||p_cdSucursal);
   raise;
end MarcarInicioReplica;

/**************************************************************************************************
* Graba la feha y hora del fin de replica en la tblReplicaControl
* %v 03/06/2014 - MarianoL
***************************************************************************************************/
procedure MarcarFinReplica(p_cdSucursal in sucursales.cdsucursal%type)
is
   v_modulo           varchar2(100) := 'PKG_REPLICA_SUC.MarcarFinReplica';

begin

   update tblreplicacontrol rc
   set rc.dtfinreplicaok = sysdate,
       rc.dserror = null,
       rc.vlregistrosok = g_vlRegistrosOK,
       rc.vlregistroserror = g_vlRegistrosError
   where rc.cdsucursal = p_cdSucursal;

   commit;
   return;

exception when others then
   GrabarLog(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM ||' suc: '||p_cdSucursal);
   raise;
end MarcarFinReplica;

/**************************************************************************************************
* Graba el error de replica en la tblReplicaControl
* %v 03/06/2014 - MarianoL
***************************************************************************************************/
procedure MarcarErrorReplica(p_cdSucursal in sucursales.cdsucursal%type,
                             p_dsError    in tblreplicacontrol.dserror%type)
is
   v_modulo            varchar2(100) := 'PKG_REPLICA_SUC.MarcarErrorReplica';
   v_vlCantErrorEnlace number;

begin

   --Grabar error en el monitor de réplicas
   update tblreplicacontrol rc
   set rc.dtfinreplicaok = null,
       rc.dserror = p_dsError,
       rc.vlregistrosok = g_vlRegistrosOK,
       rc.vlregistroserror = g_vlRegistrosError
   where rc.cdsucursal = p_cdSucursal;

   --Calular la cantidad de intentos con error
   select nvl(ra.vlcantidaderrorenlace,0) + 1
   into v_vlCantErrorEnlace
   from tblreplicaactiva ra
   where ra.cdsucursal = p_cdSucursal;

   --Updatear el contador
   update tblreplicaactiva ra
   set ra.vlcantidaderrorenlace = v_vlCantErrorEnlace,
       ra.dterrorenlace = sysdate
   where ra.cdsucursal = p_cdSucursal;

   --En caso de 3 intentos con error, desactivar la réplica con la sucursal
   if v_vlCantErrorEnlace >= 3 then
      update tblreplicaactiva ra
      set ra.icreplicaactiva = 0
      where ra.cdsucursal = p_cdSucursal;
   end if;

   commit;
   return;

exception when others then
   GrabarLog(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM ||' suc: '||p_cdSucursal);
   raise;
end MarcarErrorReplica;

/**************************************************************************************************
* Replica la tabla IpuestosDocumentos
* %v 06/04/2015 - APW
* %v 14/03/2016 - APW - Lo mantenemos hasta que se migren al nuevo esquema de impuestos todas las sucursales
************************************************************************************************************************************
No tiene una columna id que sea pk, con lo que se complica traer de a 1 fila por vez
Preferimos, en lugar de que tenga una trigger propio, traer los datos cuando se crea el documento
***********************************************************************************************************************************/
procedure TraerImpuestosDocumentos(p_servidor in  sucursales.servidor%type,
                          p_cdAccion in  varchar2,
                          p_id       in  varchar2,
                          p_ok       out integer )
is
   v_modulo           varchar2(100) := 'PKG_REPLICA_SUC.TraerImpuestosDocumentos';
   v_SQL              varchar2(4000);
   v_Cursor           cur_typ;
   v_Registro         impuestosdocumentos%rowtype;

begin
   p_ok := 0;

   --Buscar los datos en la sucursal -- todas las filas de impuestos de 1 documento
   v_SQL := 'select * from impuestosdocumentos@' || p_servidor || ' where iddoctrx=''' || p_id ||'''';

   open v_Cursor for v_SQL;
   loop
      fetch v_Cursor into v_Registro;
      exit when v_Cursor%notfound;

       --Hacer insert en AC
       if p_cdAccion = REPLICAS_GENERAL.GET_ACCION_INSERT then
          insert into impuestosdocumentos values v_Registro;
       else
           if p_cdAccion = REPLICAS_GENERAL.GET_ACCION_UPDATE then
             begin
                 --Hacer update en AC
                  update impuestosdocumentos
                  set amtasa = v_Registro.Amtasa,
                      vltasa = v_registro.vltasa
                  where iddoctrx = v_Registro.Iddoctrx
                  and   sqlineaimpuesto = v_Registro.Sqlineaimpuesto
                  and   cdtasa = v_Registro.Cdtasa
                  and   cdimpuesto = v_Registro.Cdimpuesto;
              exception when no_data_found then
                -- por si todavía no habían llegado
                insert into impuestosdocumentos values v_Registro;
              end;
           end if;
       end if;
   end loop;

   p_ok := 1;
   return;

exception when others then
   GrabarLog(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM ||' suc: '||p_servidor||' id: '||p_id);
end TraerImpuestosDocumentos;



/**************************************************************************************************
* Replica la tabla tblimpdocumento
* %v 04/03/2016 - JBodnar
***********************************************************************************************************************************/
procedure TraerImpDocumento(p_servidor in  sucursales.servidor%type,
                            p_cdAccion in  varchar2,
                            p_id       in  varchar2,
                            p_ok       out integer )
is
   v_modulo           varchar2(100) := 'PKG_REPLICA_SUC.TraerImpDocumento';
   v_SQL              varchar2(4000);
   v_Cursor           cur_typ;
   v_Registro         tblimpdocumento%rowtype;

begin
   p_ok := 0;

   --Buscar los datos en la sucursal
   v_SQL := 'select * from tblimpdocumento@' || p_servidor || ' where idimpdocumento=''' || p_id ||'''';

   open v_Cursor for v_SQL;
   fetch v_Cursor into v_Registro;

   --Hacer insert o update en AC
   if p_cdAccion = REPLICAS_GENERAL.GET_ACCION_INSERT then
      insert into tblimpdocumento values v_Registro;
   elsif p_cdAccion = REPLICAS_GENERAL.GET_ACCION_UPDATE then
      update tblimpdocumento set row = v_Registro where idimpdocumento  = p_id;
   end if;

   close v_Cursor;

   p_ok := 1;
   return;

exception when others then
   GrabarLog(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM ||' suc: '||p_servidor||' id: '||p_id);
end TraerImpDocumento;

/**************************************************************************************************
* Replica la tabla tblimpexencion
* %v 04/03/2016 - JBodnar
***********************************************************************************************************************************/
procedure TraerImpExencion (p_servidor in  sucursales.servidor%type,
                            p_cdAccion in  varchar2,
                            p_id       in  varchar2,
                            p_ok       out integer )
is
   v_modulo           varchar2(100) := 'PKG_REPLICA_SUC.TraerImpExencion';
   v_SQL              varchar2(4000);
   v_Cursor           cur_typ;
   v_Registro         tblimpexencion%rowtype;

begin
   p_ok := 0;

   --Buscar los datos en la sucursal
   v_SQL := 'select * from tblimpexencion@' || p_servidor || ' where idimpexcencion =''' || p_id ||'''';

   open v_Cursor for v_SQL;
   fetch v_Cursor into v_Registro;

   --Hacer insert o update en AC
   if p_cdAccion = REPLICAS_GENERAL.GET_ACCION_INSERT then
      insert into tblimpexencion values v_Registro;
   elsif p_cdAccion = REPLICAS_GENERAL.GET_ACCION_UPDATE then
      update tblimpexencion set row = v_Registro where idimpexcencion  = p_id;
   end if;

    --Agendar la réplica hacia el resto de las sucursales
   ReplicarTodasSucursales(p_servidor, 'tblimpexencion', p_cdAccion, p_id, null);

   close v_Cursor;

   p_ok := 1;
   return;

exception when others then
   GrabarLog(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM ||' suc: '||p_servidor||' id: '||p_id);
end TraerImpExencion;

/**************************************************************************************************
* Replica la tabla tblimpreduccion
* %v 04/03/2016 - JBodnar
***********************************************************************************************************************************/
procedure TraerImpReduccion (p_servidor in  sucursales.servidor%type,
                            p_cdAccion in  varchar2,
                            p_id       in  varchar2,
                            p_ok       out integer )
is
   v_modulo           varchar2(100) := 'PKG_REPLICA_SUC.TraerImpReduccion';
   v_SQL              varchar2(4000);
   v_Cursor           cur_typ;
   v_Registro         tblimpreduccion%rowtype;

begin
   p_ok := 0;

   --Buscar los datos en la sucursal
   v_SQL := 'select * from tblimpreduccion@' || p_servidor || ' where idreduccion =''' || p_id ||'''';

   open v_Cursor for v_SQL;
   fetch v_Cursor into v_Registro;

   --Hacer insert o update en AC
   if p_cdAccion = REPLICAS_GENERAL.GET_ACCION_INSERT then
      insert into tblimpreduccion values v_Registro;
   elsif p_cdAccion = REPLICAS_GENERAL.GET_ACCION_UPDATE then
      update tblimpreduccion set row = v_Registro where idreduccion  = p_id;
   end if;

    --Agendar la réplica hacia el resto de las sucursales
   ReplicarTodasSucursales(p_servidor, 'tblimpreduccion', p_cdAccion, p_id, null);


   close v_Cursor;

   p_ok := 1;
   return;

exception when others then
   GrabarLog(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM ||' suc: '||p_servidor||' id: '||p_id);
end TraerImpReduccion;

/**************************************************************************************************
* Replica la tabla tbldescuentoempleado
* %v 04/03/2016 - JBodnar
***********************************************************************************************************************************/
procedure TraerDescuentoEmpleado (p_servidor in  sucursales.servidor%type,
                            p_cdAccion in  varchar2,
                            p_id       in  varchar2,
                            p_ok       out integer )
is
   v_modulo           varchar2(100) := 'PKG_REPLICA_SUC.TraerDescuentoEmpleado';
   v_SQL              varchar2(4000);
   v_Cursor           cur_typ;
   v_Registro         tbldescuentoempleado%rowtype;

begin
   p_ok := 0;

   --Buscar los datos en la sucursal
   v_SQL := 'select * from tbldescuentoempleado@' || p_servidor || ' where iddescuentoempleado =''' || p_id ||'''';

   open v_Cursor for v_SQL;
   fetch v_Cursor into v_Registro;

   --Hacer insert o update en AC
   if p_cdAccion = REPLICAS_GENERAL.GET_ACCION_INSERT then
      insert into tbldescuentoempleado values v_Registro;
   elsif p_cdAccion = REPLICAS_GENERAL.GET_ACCION_UPDATE then
      update tbldescuentoempleado set row = v_Registro where iddescuentoempleado  = p_id;
   end if;

   --Agendar la réplica hacia el resto de las sucursales
   ReplicarTodasSucursales(p_servidor, 'tbldescuentoempleado', p_cdAccion, p_id, null);

   close v_Cursor;

   p_ok := 1;
   return;

exception when others then
   GrabarLog(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM ||' suc: '||p_servidor||' id: '||p_id);
end TraerDescuentoEmpleado;

/**************************************************************************************************
* Replica la tabla tbllogestadopedidos
* %v 21/04/2016 APW
***********************************************************************************************************************************/
procedure TraerEstadoPedidos (p_servidor in  sucursales.servidor%type,
                            p_cdAccion in  varchar2,
                            p_id       in  varchar2,
                            p_ok       out integer )
is
   v_modulo           varchar2(100) := 'PKG_REPLICA_SUC.TraerEstadoPedidos';
   v_SQL              varchar2(4000);
   v_Cursor           cur_typ;
   v_Registro         tbllogestadopedidos%rowtype;

begin
   p_ok := 0;

   --Buscar los datos en la sucursal
   v_SQL := 'select * from tbllogestadopedidos@' || p_servidor || ' where IDLOGESTADOPEDIDOS =''' || p_id ||'''';

   open v_Cursor for v_SQL;
   fetch v_Cursor into v_Registro;

   --Hacer insert en AC
   if p_cdAccion = REPLICAS_GENERAL.GET_ACCION_INSERT then
      insert into tbllogestadopedidos values v_Registro;
   end if;

   close v_Cursor;

   p_ok := 1;
   return;

exception when others then
   GrabarLog(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM ||' suc: '||p_servidor||' id: '||p_id);
end TraerEstadoPedidos;

/**************************************************************************************************
* Replica la tabla Documentos
* %v 03/06/2014 - MarianoL
* %v 06/04/2015 - APW
***************************************************************************************************/
procedure TraerDocumentos(p_servidor in  sucursales.servidor%type,
                          p_cdAccion in  varchar2,
                          p_id       in  varchar2,
                          p_ok       out integer)
is
   v_modulo           varchar2(100) := 'PKG_REPLICA_SUC.TraerDocumentos';
   v_SQL              varchar2(4000);
   v_Cursor           cur_typ;
   v_Registro         documentos%rowtype;

begin
   p_ok := 0;

   --Buscar los datos en la sucursal
   v_SQL := 'select * from documentos@' || p_servidor || ' where iddoctrx=''' || p_id ||'''';
   open v_Cursor for v_SQL;
   fetch v_Cursor into v_Registro;

   --Hacer insert o update en AC
   if p_cdAccion = REPLICAS_GENERAL.GET_ACCION_INSERT then
      insert into documentos values v_Registro;
      --- inserta también impuestosdocumentos
      TraerImpuestosdocumentos(p_servidor, p_cdAccion, p_id, p_ok);
   elsif p_cdAccion = REPLICAS_GENERAL.GET_ACCION_UPDATE then
      update documentos set row = v_Registro where iddoctrx = p_id;
      --- actualiza también impuestosdocumentos
      TraerImpuestosdocumentos(p_servidor, p_cdAccion, p_id, p_ok);
   end if;

   close v_Cursor;

   p_ok := 1;
   return;

exception when others then
   GrabarLog(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM ||' suc: '||p_servidor||' id: '||p_id);
end TraerDocumentos;




/**************************************************************************************************
* Replica la tabla tbldocumentodeuda
* %v 10/07/2014 - JBodnar
***************************************************************************************************/
procedure TraerDocumentoDeuda(p_servidor in  sucursales.servidor%type,
                              p_cdAccion in  varchar2,
                              p_id       in  varchar2,
                              p_ok       out integer )
is
   v_modulo           varchar2(100) := 'PKG_REPLICA_SUC.TraerDocumentoDeuda';
   v_SQL              varchar2(4000);
   v_Cursor           cur_typ;
   v_Registro         tbldocumentodeuda%rowtype;

begin
   p_ok := 0;

   --Buscar los datos en la sucursal
   v_SQL := 'select * from tbldocumentodeuda@' || p_servidor || ' where iddocumentodeuda =''' || p_id ||'''';
   open v_Cursor for v_SQL;
   fetch v_Cursor into v_Registro;

   --Hacer insert o update en AC
   if p_cdAccion = REPLICAS_GENERAL.GET_ACCION_INSERT then
      insert into tbldocumentodeuda values v_Registro;
   elsif p_cdAccion = REPLICAS_GENERAL.GET_ACCION_UPDATE then
      update tbldocumentodeuda set row = v_Registro where iddocumentodeuda  = p_id;
   end if;

   close v_Cursor;

   p_ok := 1;
   return;

exception when others then
   GrabarLog(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM ||' suc: '||p_servidor||' id: '||p_id);
end TraerDocumentoDeuda;

/**************************************************************************************************
* Replica la tabla tbldocumentodeuda
* %v 10/07/2014 - JBodnar
***************************************************************************************************/
procedure TraerTransaccion(p_servidor in  sucursales.servidor%type,
                           p_cdAccion in  varchar2,
                           p_id       in  varchar2,
                           p_ok       out integer )
is
   v_modulo           varchar2(100) := 'PKG_REPLICA_SUC.TraerTransaccion';
   v_SQL              varchar2(4000);
   v_Cursor           cur_typ;
   v_Registro         tbltransaccion%rowtype;

begin
   p_ok := 0;

   --Buscar los datos en la sucursal
   v_SQL := 'select * from tbltransaccion@' || p_servidor || ' where idtransaccion =''' || p_id ||'''';
   open v_Cursor for v_SQL;
   fetch v_Cursor into v_Registro;

   --Hacer insert o update en AC
   if p_cdAccion = REPLICAS_GENERAL.GET_ACCION_INSERT then
      insert into tbltransaccion values v_Registro;
   elsif p_cdAccion = REPLICAS_GENERAL.GET_ACCION_UPDATE then
      update tbltransaccion set row = v_Registro where idtransaccion  = p_id;
   end if;

   close v_Cursor;

   p_ok := 1;
   return;

exception when others then
   GrabarLog(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM ||' suc: '||p_servidor||' id: '||p_id);
end TraerTransaccion;


/**************************************************************************************************
* Replica la tabla tblcontrolstock
* %v 10/07/2014 - JBodnar
***************************************************************************************************/
procedure TraerControlStock(p_servidor in  sucursales.servidor%type,
                            p_cdAccion in  varchar2,
                            p_id       in  varchar2,
                            p_ok       out integer )
is
   v_modulo           varchar2(100) := 'PKG_REPLICA_SUC.TraerControlStock';
   v_SQL              varchar2(4000);
   v_Cursor           cur_typ;
   v_Registro         tblcontrolstock%rowtype;
begin
   p_ok := 0;

   --Buscar los datos en la sucursal
   v_SQL := 'select * from tblcontrolstock@' || p_servidor || ' where idcontrolstock =''' || p_id ||'''';
   open v_Cursor for v_SQL;
   fetch v_Cursor into v_Registro;

   --Hacer insert o update en AC
   if p_cdAccion = REPLICAS_GENERAL.GET_ACCION_INSERT then
      insert into tblcontrolstock values v_Registro;
   elsif p_cdAccion = REPLICAS_GENERAL.GET_ACCION_UPDATE then
      update tblcontrolstock set row = v_Registro where idcontrolstock = p_id;
   end if;

   close v_Cursor;

   p_ok := 1;
   return;

exception when others then
   GrabarLog(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM ||' suc: '||p_servidor||' id: '||p_id);
end TraerControlStock;

/**************************************************************************************************
* Replica la tabla tblcontrolstockestadistica
* %v 01/12/2015 - MarianoL
***************************************************************************************************/
procedure TraerControlStockEstad(p_servidor in  sucursales.servidor%type,
                                 p_cdAccion in  varchar2,
                                 p_id       in  varchar2,
                                 p_ok       out integer )
is
   v_modulo           varchar2(100) := 'PKG_REPLICA_SUC.TraerControlStockEstad';
   v_SQL              varchar2(4000);
   v_Cursor           cur_typ;
   v_Registro         tblcontrolstockestadistica%rowtype;
begin
   p_ok := 0;

   --Buscar los datos en la sucursal
   v_SQL := 'select * from tblcontrolstockestadistica@' || p_servidor || ' where idcontrolstockestadistica =''' || p_id ||'''';
   open v_Cursor for v_SQL;
   fetch v_Cursor into v_Registro;

   --Hacer insert o update en AC
   if p_cdAccion = REPLICAS_GENERAL.GET_ACCION_INSERT then
      insert into tblcontrolstockestadistica values v_Registro;
   elsif p_cdAccion = REPLICAS_GENERAL.GET_ACCION_UPDATE then
      update tblcontrolstockestadistica set row = v_Registro where idcontrolstockestadistica = p_id;
   end if;

   close v_Cursor;

   p_ok := 1;
   return;

exception when others then
   GrabarLog(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM ||' suc: '||p_servidor||' id: '||p_id);
end TraerControlStockEstad;

/**************************************************************************************************
* Replica la tabla tbltesoro
* %v 16/07/2014 MatiasG: v1.0
***************************************************************************************************/
procedure TraerTesoro(p_servidor in  sucursales.servidor%type,
                      p_cdAccion in  varchar2,
                      p_id       in  varchar2,
                      p_ok       out integer )
is
   v_modulo           varchar2(100) := 'PKG_REPLICA_SUC.TraerTesoro';
   v_SQL              varchar2(4000);
   v_Cursor           cur_typ;
   v_Registro         tbltesoro%rowtype;

begin
   p_ok := 0;

   --Buscar los datos en la sucursal
   v_SQL := 'select * from tbltesoro@' || p_servidor || ' where idtesoro=''' || p_id ||'''';

   open v_Cursor for v_SQL;
   fetch v_Cursor into v_Registro;

   --Hacer insert o update en AC
   if p_cdAccion = REPLICAS_GENERAL.GET_ACCION_INSERT then
      insert into tbltesoro values v_Registro;
   elsif p_cdAccion = REPLICAS_GENERAL.GET_ACCION_UPDATE then
      update tbltesoro set row = v_Registro where idtesoro = p_id;
   end if;

   close v_Cursor;

   p_ok := 1;
   return;

exception when others then
   GrabarLog(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM ||' suc: '||p_servidor||' id: '||p_id);
end TraerTesoro;

/**************************************************************************************************
* Replica la tabla tbldiferenciacaja
* %v 16/07/2014 MatiasG: v1.0
***************************************************************************************************/
procedure TraerDiferenciaCaja(p_servidor in  sucursales.servidor%type,
                      p_cdAccion in  varchar2,
                      p_id       in  varchar2,
                      p_ok       out integer )
is
   v_modulo           varchar2(100) := 'PKG_REPLICA_SUC.TraerDiferenciaCaja';
   v_SQL              varchar2(4000);
   v_Cursor           cur_typ;
   v_Registro         tbldiferenciacaja%rowtype;

begin
   p_ok := 0;

   --Buscar los datos en la sucursal
   v_SQL := 'select * from tbldiferenciacaja@' || p_servidor || ' where iddiferenciacaja=''' || p_id ||'''';

   open v_Cursor for v_SQL;
   fetch v_Cursor into v_Registro;

   --Hacer insert o update en AC
   if p_cdAccion = REPLICAS_GENERAL.GET_ACCION_INSERT then
      insert into tbldiferenciacaja values v_Registro;
   elsif p_cdAccion = REPLICAS_GENERAL.GET_ACCION_UPDATE then
      update tbldiferenciacaja set row = v_Registro where iddiferenciacaja = p_id;
   end if;

   close v_Cursor;

   p_ok := 1;
   return;

exception when others then
   GrabarLog(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM ||' suc: '||p_servidor||' id: '||p_id);
end TraerDiferenciaCaja;

/**************************************************************************************************
* Replica la tabla tblmovcaja
* %v 29/07/2014 JBodnar: v1.0
***************************************************************************************************/
procedure TraerMovCaja(p_servidor in  sucursales.servidor%type,
                      p_cdAccion in  varchar2,
                      p_id       in  varchar2,
                      p_ok       out integer )
is
   v_modulo           varchar2(100) := 'PKG_REPLICA_SUC.TraerMovCaja';
   v_SQL              varchar2(4000);
   v_Cursor           cur_typ;
   v_Registro         tblmovcaja%rowtype;

begin
   p_ok := 0;

   --Buscar los datos en la sucursal
   v_SQL := 'select * from tblmovcaja@' || p_servidor || ' where idmovcaja=''' || p_id ||'''';

   open v_Cursor for v_SQL;
   fetch v_Cursor into v_Registro;

   --Hacer insert o update en AC
   if p_cdAccion = REPLICAS_GENERAL.GET_ACCION_INSERT then
      insert into tblmovcaja values v_Registro;
   elsif p_cdAccion = REPLICAS_GENERAL.GET_ACCION_UPDATE then
      update tblmovcaja set row = v_Registro where idmovcaja = p_id;
   end if;

   close v_Cursor;

   p_ok := 1;
   return;

exception when others then
   GrabarLog(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM ||' suc: '||p_servidor||' id: '||p_id);
end TraerMovCaja;

/**************************************************************************************************
* Replica la tabla tblaliviodetalle
* %v 29/07/2014 JBodnar: v1.0
***************************************************************************************************/
procedure TraerAlivioDetalle(p_servidor in  sucursales.servidor%type,
                            p_cdAccion in  varchar2,
                            p_id       in  varchar2,
                            p_ok       out integer )
is
   v_modulo           varchar2(100) := 'PKG_REPLICA_SUC.TraerAlivioDetalle';
   v_SQL              varchar2(4000);
   v_Cursor           cur_typ;
   v_Registro         tblaliviodetalle%rowtype;

begin
   p_ok := 0;

   --Buscar los datos en la sucursal
   v_SQL := 'select * from tblaliviodetalle@' || p_servidor || ' where idaliviodetalle=''' || p_id ||'''';

   open v_Cursor for v_SQL;
   fetch v_Cursor into v_Registro;

   --Hacer insert o update en AC
   if p_cdAccion = REPLICAS_GENERAL.GET_ACCION_INSERT then
      insert into tblaliviodetalle values v_Registro;
   elsif p_cdAccion = REPLICAS_GENERAL.GET_ACCION_UPDATE then
      update tblaliviodetalle set row = v_Registro where idaliviodetalle = p_id;
   end if;

   close v_Cursor;

   p_ok := 1;
   return;

exception when others then
   GrabarLog(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM ||' suc: '||p_servidor||' id: '||p_id);
end TraerAlivioDetalle;

/**************************************************************************************************
* Replica la tabla TraerMovMateriales
* %v 03/06/2014 - MarianoL
* %v 10/08/2020 - cdickson_c -- agrego actualización de detallemovmateriales y tblimpdocumentodetalle
***************************************************************************************************/
procedure TraerMovMateriales(p_servidor in  sucursales.servidor%type,
                                p_cdAccion in  varchar2,
                                p_id       in  varchar2,
                                p_ok       out integer )
is
   v_modulo           varchar2(100) := 'PKG_REPLICA_SUC.TraerMovMateriales';
   v_SQL              varchar2(4000);
   v_Cursor           cur_typ;
   v_Registro         movmateriales%rowtype;

begin
   p_ok := 0;

   --Buscar los datos en la sucursal
   v_SQL := 'select * from movmateriales@' || p_servidor || ' where idmovmateriales=''' || p_id ||'''';
   open v_Cursor for v_SQL;
   fetch v_Cursor into v_Registro;

   --Hacer insert o update en AC
   if p_cdAccion = REPLICAS_GENERAL.GET_ACCION_INSERT then
      insert into movmateriales values v_Registro;
     -- 
     --Trae de la sucursal detalle de movimiento de materiales con igual IDMOVMATERIALES
     -- 
     Execute immediate  
     'Begin Insert into detallemovmateriales Select * From detallemovmateriales@' || 
       p_servidor || '  s Where IDMOVMATERIALES=''' || p_id ||''''||'; End;';
     --
     --Trae de la sucursal detalle de imp documento con igual IDMOVMATERIALES
     --
     Execute immediate
     'Begin Insert into tblimpdocumentodetalle Select * From tblimpdocumentodetalle@' || 
       p_servidor || '  s Where IDMOVMATERIALES=''' || p_id ||''''||'; End;'; 
     --
   elsif p_cdAccion = REPLICAS_GENERAL.GET_ACCION_UPDATE then
      update movmateriales set row = v_Registro where idmovmateriales = p_id;
   end if;

   close v_Cursor;

   p_ok := 1;
   return;

exception when others then
   GrabarLog(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM ||' suc: '||p_servidor||' id: '||p_id);
end TraerMovMateriales;

/**************************************************************************************************
* Replica la tabla TblCuenta
* %v 03/06/2014 - MarianoL
***************************************************************************************************/
procedure TraerCuenta(p_servidor in  sucursales.servidor%type,
                            p_cdAccion in  varchar2,
                            p_id       in  varchar2,
                            p_ok       out integer )
is
   v_modulo           varchar2(100) := 'PKG_REPLICA_SUC.TraerCuenta';
   v_SQL              varchar2(4000);
   v_Cursor           cur_typ;
   v_Registro         tblcuenta%rowtype;

begin
   p_ok := 0;

   --Buscar los datos en la sucursal
   v_SQL := 'select * from tblcuenta@' || p_servidor || ' where idcuenta =''' || p_id ||'''';
   open v_Cursor for v_SQL;
   fetch v_Cursor into v_Registro;

   --Hacer insert o update en AC
   if p_cdAccion = REPLICAS_GENERAL.GET_ACCION_INSERT then
      insert into tblcuenta values v_Registro;
   elsif p_cdAccion = REPLICAS_GENERAL.GET_ACCION_UPDATE then
      update tblcuenta set row = v_Registro where idcuenta = p_id;
   end if;


   --Agendar la réplica hacia la unica sucursal destino CC
   ReplicarUnicaSucursal('9998    ', 'tblcuenta', p_cdAccion, p_id);

   close v_Cursor;

   p_ok := 1;
   return;

exception when others then
   GrabarLog(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM ||' suc: '||p_servidor||' id: '||p_id);
end TraerCuenta;

/**************************************************************************************************
* Replica la tabla TblAmpliacionCredito
* %v 03/06/2014 - MarianoL
***************************************************************************************************/
procedure TraerAmpliacionCredito(p_servidor in  sucursales.servidor%type,
                                       p_cdAccion in  varchar2,
                                       p_id       in  varchar2,
                                       p_ok       out integer )
is
   v_modulo           varchar2(100) := 'PKG_REPLICA_SUC.TraerAmpliacionCredito';
   v_SQL              varchar2(4000);
   v_Cursor           cur_typ;
   v_Registro         tblampliacioncredito%rowtype;

begin
   p_ok := 0;

   --Buscar los datos en la sucursal
   v_SQL := 'select * from tblampliacioncredito@' || p_servidor || ' where idampliacion =''' || p_id ||'''';
   open v_Cursor for v_SQL;
   fetch v_Cursor into v_Registro;

   --Hacer insert o update en AC
   if p_cdAccion = REPLICAS_GENERAL.GET_ACCION_INSERT then
      insert into tblampliacioncredito values v_Registro;
   elsif p_cdAccion = REPLICAS_GENERAL.GET_ACCION_UPDATE then
      update tblampliacioncredito set row = v_Registro where idampliacion = p_id;
   end if;

   close v_Cursor;

   p_ok := 1;
   return;

exception when others then
   GrabarLog(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM ||' suc: '||p_servidor||' id: '||p_id);
end TraerAmpliacionCredito;

/**************************************************************************************************
* Replica la tabla TblIngreso
* %v 03/06/2014 - MarianoL
***************************************************************************************************/
procedure TraerIngreso(p_servidor in  sucursales.servidor%type,
                             p_cdAccion in  varchar2,
                             p_id       in  varchar2,
                             p_ok       out integer )
is
   v_modulo           varchar2(100) := 'PKG_REPLICA_SUC.TraerIngreso';
   v_SQL              varchar2(4000);
   v_Cursor           cur_typ;
   v_Registro         tblingreso%rowtype;

begin
   p_ok := 0;

   --Buscar los datos en la sucursal
   v_SQL := 'select * from tblingreso@' || p_servidor || ' where idingreso =''' || p_id ||'''';
   open v_Cursor for v_SQL;
   fetch v_Cursor into v_Registro;

   --Hacer insert o update en AC
   if p_cdAccion = REPLICAS_GENERAL.GET_ACCION_INSERT then
      insert into tblingreso values v_Registro;
   elsif p_cdAccion = REPLICAS_GENERAL.GET_ACCION_UPDATE then
      update tblingreso set row = v_Registro where idingreso = p_id;
   end if;

   close v_Cursor;

   p_ok := 1;
   return;

exception when others then
   GrabarLog(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM ||' suc: '||p_servidor||' id: '||p_id);
end TraerIngreso;

/**************************************************************************************************
* Replica la tabla TblMovCuenta
* %v 03/06/2014 - MarianoL
***************************************************************************************************/
procedure TraerMovCuenta(p_servidor in  sucursales.servidor%type,
                             p_cdAccion in  varchar2,
                             p_id       in  varchar2,
                             p_ok       out integer )
is
   v_modulo           varchar2(100) := 'PKG_REPLICA_SUC.TraerMovCuenta';
   v_SQL              varchar2(4000);
   v_Cursor           cur_typ;
   v_Registro         tblmovcuenta%rowtype;

begin
   p_ok := 0;

   --Buscar los datos en la sucursal
   v_SQL := 'select * from tblmovcuenta@' || p_servidor || ' where idmovcuenta =''' || p_id ||'''';
   open v_Cursor for v_SQL;
   fetch v_Cursor into v_Registro;

   --Hacer insert o update en AC
   if p_cdAccion = REPLICAS_GENERAL.GET_ACCION_INSERT then
      insert into tblmovcuenta values v_Registro;
   elsif p_cdAccion = REPLICAS_GENERAL.GET_ACCION_UPDATE then
      update tblmovcuenta set row = v_Registro where idmovcuenta  = p_id;
   end if;

   close v_Cursor;

   p_ok := 1;
   return;

exception when others then
   GrabarLog(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM ||' suc: '||p_servidor||' id: '||p_id);
end TraerMovCuenta;

/**************************************************************************************************
* Replica la tabla TblCobranza
* %v 03/06/2014 - MarianoL
***************************************************************************************************/
procedure TraerCobranza(p_servidor in  sucursales.servidor%type,
                              p_cdAccion in  varchar2,
                              p_id       in  varchar2,
                              p_ok       out integer )
is
   v_modulo           varchar2(100) := 'PKG_REPLICA_SUC.TraerCobranza';
   v_SQL              varchar2(4000);
   v_Cursor           cur_typ;
   v_Registro         tblcobranza%rowtype;

begin
   p_ok := 0;

   --Buscar los datos en la sucursal
   v_SQL := 'select * from tblcobranza@' || p_servidor || ' where idcobranza  =''' || p_id ||'''';
   open v_Cursor for v_SQL;
   fetch v_Cursor into v_Registro;

   --Hacer insert o update en AC
   if p_cdAccion = REPLICAS_GENERAL.GET_ACCION_INSERT then
      insert into tblcobranza values v_Registro;
   elsif p_cdAccion = REPLICAS_GENERAL.GET_ACCION_UPDATE then
      update tblcobranza set row = v_Registro where idcobranza = p_id;
   end if;

   close v_Cursor;

   p_ok := 1;
   return;

exception when others then
   GrabarLog(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM ||' suc: '||p_servidor||' id: '||p_id);
end TraerCobranza;

/**************************************************************************************************
* Replica la tabla tblTarjeta
* %v 03/06/2014 - MarianoL
***************************************************************************************************/
procedure TraerTarjeta(p_servidor in  sucursales.servidor%type,
                       p_cdAccion in  varchar2,
                       p_id       in  varchar2,
                       p_ok       out integer )
is
   v_modulo           varchar2(100) := 'PKG_REPLICA_SUC.TraerTarjeta';
   v_SQL              varchar2(4000);
   v_Cursor           cur_typ;
   v_Registro         tbltarjeta%rowtype;

begin
   p_ok := 0;

   --Buscar los datos en la sucursal
   v_SQL := 'select * from tbltarjeta@' || p_servidor || ' where idingreso   =''' || p_id ||'''';
   open v_Cursor for v_SQL;
   fetch v_Cursor into v_Registro;

   --Hacer insert o update en AC
   if p_cdAccion = REPLICAS_GENERAL.GET_ACCION_INSERT then
      insert into tbltarjeta values v_Registro;
   elsif p_cdAccion = REPLICAS_GENERAL.GET_ACCION_UPDATE then
      update tbltarjeta set row = v_Registro where idingreso = p_id;
   end if;

   close v_Cursor;

   p_ok := 1;
   return;

exception when others then
   GrabarLog(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM ||' suc: '||p_servidor||' id: '||p_id);
end TraerTarjeta;


/**************************************************************************************************
* Replica la tabla tblelectronico
* %v 02/07/2018 - JBodnar
***************************************************************************************************/
procedure TraerElectronico (p_servidor in  sucursales.servidor%type,
                            p_cdAccion in  varchar2,
                            p_id       in  varchar2,
                            p_ok       out integer )
is
   v_modulo           varchar2(100) := 'PKG_REPLICA_SUC.TraerElectronico';
   v_SQL              varchar2(4000);
   v_Cursor           cur_typ;
   v_Registro         tblelectronico%rowtype;

begin
   p_ok := 0;

   --Buscar los datos en la sucursal
   v_SQL := 'select * from tblelectronico@' || p_servidor || ' where idingreso   =''' || p_id ||'''';
   open v_Cursor for v_SQL;
   fetch v_Cursor into v_Registro;

   --Hacer insert o update en AC
   if p_cdAccion = REPLICAS_GENERAL.GET_ACCION_INSERT then
      insert into tblelectronico values v_Registro;
   elsif p_cdAccion = REPLICAS_GENERAL.GET_ACCION_UPDATE then
      update tblelectronico set row = v_Registro where idingreso = p_id;
   end if;

   close v_Cursor;

   p_ok := 1;
   return;

exception when others then
   GrabarLog(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM ||' suc: '||p_servidor||' id: '||p_id);
end TraerElectronico;

/**************************************************************************************************
* Replica la tabla tblCheque
* %v 03/06/2014 - MarianoL
***************************************************************************************************/
procedure TraerCheque(p_servidor in  sucursales.servidor%type,
                      p_cdAccion in  varchar2,
                      p_id       in  varchar2,
                      p_ok       out integer )
is
   v_modulo           varchar2(100) := 'PKG_REPLICA_SUC.TraerCheque';
   v_SQL              varchar2(4000);
   v_Cursor           cur_typ;
   v_Registro         tblcheque%rowtype;

begin
   p_ok := 0;

   --Buscar los datos en la sucursal
   v_SQL := 'select * from tblcheque@' || p_servidor || ' where idingreso =''' || p_id ||'''';
   open v_Cursor for v_SQL;
   fetch v_Cursor into v_Registro;

   --Hacer insert o update en AC
   if p_cdAccion = REPLICAS_GENERAL.GET_ACCION_INSERT then
      insert into tblcheque values v_Registro;
   elsif p_cdAccion = REPLICAS_GENERAL.GET_ACCION_UPDATE then
      update tblcheque set row = v_Registro where idingreso = p_id;
   end if;

   close v_Cursor;

   p_ok := 1;
   return;

exception when others then
   GrabarLog(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM ||' suc: '||p_servidor||' id: '||p_id);
end TraerCheque;

/**************************************************************************************************
* Replica la tabla TraerPosnetBanco
* %v 03/06/2014 - MarianoL
***************************************************************************************************/
procedure TraerPosnetBanco(p_servidor in  sucursales.servidor%type,
                           p_cdAccion in  varchar2,
                           p_id       in  varchar2,
                           p_ok       out integer )
is
   v_modulo           varchar2(100) := 'PKG_REPLICA_SUC.TraerPosnetBanco';
   v_SQL              varchar2(4000);
   v_Cursor           cur_typ;
   v_Registro         tblposnetbanco%rowtype;

begin
   p_ok := 0;

   --Buscar los datos en la sucursal
   v_SQL := 'select * from tblposnetbanco@' || p_servidor || ' where idingreso =''' || p_id ||'''';
   open v_Cursor for v_SQL;
   fetch v_Cursor into v_Registro;

   --Hacer insert o update en AC
   if p_cdAccion = REPLICAS_GENERAL.GET_ACCION_INSERT then
      insert into tblposnetbanco values v_Registro;
   elsif p_cdAccion = REPLICAS_GENERAL.GET_ACCION_UPDATE then
      update tblposnetbanco set row = v_Registro where idingreso = p_id;
   end if;

   close v_Cursor;

   p_ok := 1;
   return;

exception when others then
   GrabarLog(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM ||' suc: '||p_servidor||' id: '||p_id);
end TraerPosnetBanco;

/**************************************************************************************************
* Replica la tabla tblInterdeposito
* %v 03/06/2014 - MarianoL
***************************************************************************************************/
procedure TraerInterdeposito(p_servidor in  sucursales.servidor%type,
                             p_cdAccion in  varchar2,
                             p_id       in  varchar2,
                             p_ok       out integer )
is
   v_modulo           varchar2(100) := 'PKG_REPLICA_SUC.TraerInterdeposito';
   v_SQL              varchar2(4000);
   v_Cursor           cur_typ;
   v_Registro         tblinterdeposito%rowtype;

begin
   p_ok := 0;

   --Buscar los datos en la sucursal
   v_SQL := 'select * from tblinterdeposito@' || p_servidor || ' where idingreso =''' || p_id ||'''';
   open v_Cursor for v_SQL;
   fetch v_Cursor into v_Registro;

   --Hacer insert o update en AC
   if p_cdAccion = REPLICAS_GENERAL.GET_ACCION_INSERT then
      insert into tblinterdeposito values v_Registro;
   elsif p_cdAccion = REPLICAS_GENERAL.GET_ACCION_UPDATE then
      update tblinterdeposito set row = v_Registro where idingreso = p_id;
   end if;

   close v_Cursor;

   p_ok := 1;
   return;

exception when others then
   GrabarLog(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM ||' suc: '||p_servidor||' id: '||p_id);
end TraerInterdeposito;

/**************************************************************************************************
* Replica la tabla tblTicket
* %v 03/06/2014 - MarianoL
***************************************************************************************************/
procedure TraerTicket(p_servidor in  sucursales.servidor%type,
                      p_cdAccion in  varchar2,
                      p_id       in  varchar2,
                      p_ok       out integer )
is
   v_modulo           varchar2(100) := 'PKG_REPLICA_SUC.TraerTicket';
   v_SQL              varchar2(4000);
   v_Cursor           cur_typ;
   v_Registro         tblticket%rowtype;

begin
   p_ok := 0;

   --Buscar los datos en la sucursal
   v_SQL := 'select * from tblticket@' || p_servidor || ' where idingreso =''' || p_id ||'''';
   open v_Cursor for v_SQL;
   fetch v_Cursor into v_Registro;

   --Hacer insert o update en AC
   if p_cdAccion = REPLICAS_GENERAL.GET_ACCION_INSERT then
      insert into tblticket values v_Registro;
   elsif p_cdAccion = REPLICAS_GENERAL.GET_ACCION_UPDATE then
      update tblticket set row = v_Registro where idingreso = p_id;
   end if;

   close v_Cursor;

   p_ok := 1;
   return;

exception when others then
   GrabarLog(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM ||' suc: '||p_servidor||' id: '||p_id);
end TraerTicket;

/**************************************************************************************************
* Replica la tabla TraerCierreLote
* %v 14/08/2014 - JBodnar
***************************************************************************************************/
procedure TraerCierreLote(p_servidor in  sucursales.servidor%type,
                          p_cdAccion in  varchar2,
                          p_id       in  varchar2,
                          p_ok       out integer )
is
   v_modulo           varchar2(100) := 'PKG_REPLICA_SUC.TraerCierreLote';
   v_SQL              varchar2(4000);
   v_Cursor           cur_typ;
   v_Registro         tblcierrelote%rowtype;

begin
   p_ok := 0;

   --Buscar los datos en la sucursal
   v_SQL := 'select * from tblcierrelote@' || p_servidor || ' where idingreso =''' || p_id ||'''';
   open v_Cursor for v_SQL;
   fetch v_Cursor into v_Registro;

   --Hacer insert o update en AC
   if p_cdAccion = REPLICAS_GENERAL.GET_ACCION_INSERT then
      insert into tblcierrelote values v_Registro;
   elsif p_cdAccion = REPLICAS_GENERAL.GET_ACCION_UPDATE then
      update tblcierrelote set row = v_Registro where idingreso = p_id;
   end if;

   close v_Cursor;

   p_ok := 1;
   return;

exception when others then
   GrabarLog(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM ||' suc: '||p_servidor||' id: '||p_id);
end TraerCierreLote;

/**************************************************************************************************
* Replica la tabla tblMonedaOrigen
* %v 03/06/2014 - MarianoL
***************************************************************************************************/
procedure TraerMonedaOrigen(p_servidor in  sucursales.servidor%type,
                            p_cdAccion in  varchar2,
                            p_id       in  varchar2,
                            p_ok       out integer )
is
   v_modulo           varchar2(100) := 'PKG_REPLICA_SUC.TraerMonedaOrigen';
   v_SQL              varchar2(4000);
   v_Cursor           cur_typ;
   v_Registro         tblmonedaorigen%rowtype;

begin
   p_ok := 0;

   --Buscar los datos en la sucursal
   v_SQL := 'select * from tblmonedaorigen@' || p_servidor || ' where idingreso =''' || p_id ||'''';
   open v_Cursor for v_SQL;
   fetch v_Cursor into v_Registro;

   --Hacer insert o update en AC
   if p_cdAccion = REPLICAS_GENERAL.GET_ACCION_INSERT then
      insert into tblmonedaorigen values v_Registro;
   elsif p_cdAccion = REPLICAS_GENERAL.GET_ACCION_UPDATE then
      update tblmonedaorigen set row = v_Registro where idingreso = p_id;
   end if;

   close v_Cursor;

   p_ok := 1;
   return;

exception when others then
   GrabarLog(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM ||' suc: '||p_servidor||' id: '||p_id);
end TraerMonedaOrigen;

/**************************************************************************************************
* Replica la tabla tblRetencion
* %v 03/06/2014 - MarianoL
***************************************************************************************************/
procedure TraerRetencion(p_servidor in  sucursales.servidor%type,
                         p_cdAccion in  varchar2,
                         p_id       in  varchar2,
                         p_ok       out integer )
is
   v_modulo           varchar2(100) := 'PKG_REPLICA_SUC.TraerRetencion';
   v_SQL              varchar2(4000);
   v_Cursor           cur_typ;
   v_Registro         tblretencion%rowtype;

begin
   p_ok := 0;

   --Buscar los datos en la sucursal
   v_SQL := 'select * from tblretencion@' || p_servidor || ' where idingreso =''' || p_id ||'''';
   open v_Cursor for v_SQL;
   fetch v_Cursor into v_Registro;

   --Hacer insert o update en AC
   if p_cdAccion = REPLICAS_GENERAL.GET_ACCION_INSERT then
      insert into tblretencion values v_Registro;
   elsif p_cdAccion = REPLICAS_GENERAL.GET_ACCION_UPDATE then
      update tblretencion set row = v_Registro where idingreso = p_id;
   end if;

   close v_Cursor;

   p_ok := 1;
   return;

exception when others then
   GrabarLog(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM ||' suc: '||p_servidor||' id: '||p_id);
end TraerRetencion;

/**************************************************************************************************
* Replica la tabla tblpagaredetalle
* %v 03/06/2014 - MarianoL
***************************************************************************************************/
procedure TraerPagareDetalle(p_servidor in  sucursales.servidor%type,
                             p_cdAccion in  varchar2,
                             p_id       in  varchar2,
                             p_ok       out integer )
is
   v_modulo           varchar2(100) := 'PKG_REPLICA_SUC.TraerPagareDetalle';
   v_SQL              varchar2(4000);
   v_Cursor           cur_typ;
   v_Registro         tblpagaredetalle%rowtype;

begin
   p_ok := 0;

   --Buscar los datos en la sucursal
   v_SQL := 'select * from tblpagaredetalle@' || p_servidor || ' where idpagaredetalle =''' || p_id ||'''';
   open v_Cursor for v_SQL;
   fetch v_Cursor into v_Registro;

   --Hacer insert o update en AC
   if p_cdAccion = REPLICAS_GENERAL.GET_ACCION_INSERT then
      insert into tblpagaredetalle values v_Registro;
   elsif p_cdAccion = REPLICAS_GENERAL.GET_ACCION_UPDATE then
      update tblpagaredetalle set row = v_Registro where idpagaredetalle = p_id;
   end if;

   close v_Cursor;

   p_ok := 1;
   return;

exception when others then
   GrabarLog(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM ||' suc: '||p_servidor||' id: '||p_id);
end TraerPagareDetalle;

/**************************************************************************************************
* Replica la tabla tblautorizacioncheque
* %v 03/06/2014 - MarianoL
***************************************************************************************************/
procedure TraerAutorizacionCheque(p_servidor in  sucursales.servidor%type,
                                  p_cdAccion in  varchar2,
                                  p_id       in  varchar2,
                                  p_ok       out integer )
is
   v_modulo           varchar2(100) := 'PKG_REPLICA_SUC.TraerAutorizacionCheque';
   v_SQL              varchar2(4000);
   v_Cursor           cur_typ;
   v_Registro         tblautorizacioncheque%rowtype;

begin
   p_ok := 0;

   --Buscar los datos en la sucursal
   v_SQL := 'select * from tblautorizacioncheque@' || p_servidor || ' where idautorizacion =''' || p_id ||'''';
   open v_Cursor for v_SQL;
   fetch v_Cursor into v_Registro;

   --Hacer insert o update en AC
   if p_cdAccion = REPLICAS_GENERAL.GET_ACCION_INSERT then
      insert into tblautorizacioncheque values v_Registro;
   elsif p_cdAccion = REPLICAS_GENERAL.GET_ACCION_UPDATE then
      update tblautorizacioncheque set row = v_Registro where idautorizacion = p_id;
   end if;

   close v_Cursor;

   p_ok := 1;
   return;

exception when others then
   GrabarLog(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM ||' suc: '||p_servidor||' id: '||p_id);
end TraerAutorizacionCheque;

/**************************************************************************************************
* Replica la tabla tblposnet_transmitido
* %v 03/06/2014 - MarianoL
***************************************************************************************************/
procedure TraerPosnet_Transmitido(p_servidor in  sucursales.servidor%type,
                                  p_cdAccion in  varchar2,
                                  p_id       in  varchar2,
                                  p_ok       out integer )
is
   v_modulo           varchar2(100) := 'PKG_REPLICA_SUC.TraerPosnet_Transmitido';
   v_SQL              varchar2(4000);
   v_Cursor           cur_typ;
   v_Registro         tblposnet_transmitido%rowtype;

begin
   p_ok := 0;

   --Buscar los datos en la sucursal
   v_SQL := 'select * from tblposnet_transmitido@' || p_servidor || ' where idtransmitido =''' || p_id ||'''';
   open v_Cursor for v_SQL;
   fetch v_Cursor into v_Registro;

   --Hacer insert o update en AC
   if p_cdAccion = REPLICAS_GENERAL.GET_ACCION_INSERT then
      insert into tblposnet_transmitido values v_Registro;
   elsif p_cdAccion = REPLICAS_GENERAL.GET_ACCION_UPDATE then
      update tblposnet_transmitido set row = v_Registro where idtransmitido = p_id;
   end if;

   close v_Cursor;

   p_ok := 1;
   return;

exception when others then
   GrabarLog(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM ||' suc: '||p_servidor||' id: '||p_id);
end TraerPosnet_Transmitido;

/**************************************************************************************************
* Replica la tabla tblclnotadecredito
* %v 26/01/2015 - MartinM
***************************************************************************************************/
procedure TraerClNotaDeCredito(p_servidor in  sucursales.servidor%type,
                               p_cdAccion in  varchar2,
                               p_id       in  varchar2,
                               p_ok       out integer )
is
   v_modulo           varchar2(100) := 'PKG_REPLICA_SUC.TraerClNotaDeCredito';
   v_SQL              varchar2(4000);
   v_Cursor           cur_typ;
   v_Registro         tblclnotadecredito%rowtype;

begin
   p_ok := 0;

   --Buscar los datos en la sucursal
   v_SQL := 'select * from tblclnotadecredito@' || p_servidor || ' where idnotadecredito =''' || p_id ||'''';
   open v_Cursor for v_SQL;
   fetch v_Cursor into v_Registro;

   --Hacer insert o update en AC
   if p_cdAccion = REPLICAS_GENERAL.GET_ACCION_INSERT then
      insert into tblclnotadecredito values v_Registro;
   elsif p_cdAccion = REPLICAS_GENERAL.GET_ACCION_UPDATE then
      update tblclnotadecredito set row = v_Registro where idnotadecredito = p_id;
   end if;

   close v_Cursor;

   p_ok := 1;
   return;

exception when others then
   GrabarLog(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM ||' suc: '||p_servidor||' id: '||p_id);
end TraerClNotaDeCredito;

/**************************************************************************************************
* Replica la tabla tblclnotadecredito
* %v 26/01/2015 - MartinM
***************************************************************************************************/
procedure TraerComisionistaCobrar(p_servidor in  sucursales.servidor%type ,
                                   p_cdAccion in             varchar2      ,
                                   p_id       in             varchar2      ,
                                   p_ok       out            integer       )
is
   v_modulo           varchar2(100) := 'PKG_REPLICA_SUC.TraerComisionistaCobrar';
   v_SQL              varchar2(4000);
   v_Cursor           cur_typ;
   v_Registro         tblcomisionistacobrar%rowtype;

begin
   p_ok := 0;

   --Buscar los datos en la sucursal
   v_SQL := 'select * from tblcomisionistacobrar@' || p_servidor || ' where idcomisionistacobrar =''' || p_id ||'''';
   open v_Cursor for v_SQL;
   fetch v_Cursor into v_Registro;

   --Hacer insert o update en AC
   if p_cdAccion = REPLICAS_GENERAL.GET_ACCION_INSERT then
      insert into tblcomisionistacobrar values v_Registro;
   elsif p_cdAccion = REPLICAS_GENERAL.GET_ACCION_UPDATE then
      update tblcomisionistacobrar set row = v_Registro where idcomisionistacobrar = p_id;
   end if;

   close v_Cursor;

   p_ok := 1;
   return;

exception when others then
   GrabarLog(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM ||' suc: '||p_servidor||' id: '||p_id);
end TraerComisionistaCobrar;

/**************************************************************************************************
* Replica la tabla tbltmp_guia_comis_cheque
* %v 15/10/2015 - MartinM
***************************************************************************************************/
procedure TraerTMPCargaCheque(p_servidor in  sucursales.servidor%type,
                              p_cdAccion in  varchar2,
                              p_id       in  varchar2,
                              p_ok       out integer )
is
   v_modulo           varchar2(100) := 'PKG_REPLICA_SUC.TraerTMPCargaCheque';
   v_SQL              varchar2(4000);
   v_Cursor           cur_typ;
   v_Registro         tblguiacomischequeavalidar%rowtype;

begin
   p_ok := 0;

   --Buscar los datos en la sucursal
   v_SQL := 'select * from tblguiacomischequeavalidar@' || p_servidor || ' where idtmpguiacomischeque =''' || p_id ||'''';
   open v_Cursor for v_SQL;
   fetch v_Cursor into v_Registro;

   --Hacer insert o update en AC
   if p_cdAccion = REPLICAS_GENERAL.GET_ACCION_INSERT then
      insert into tblguiacomischequeavalidar values v_Registro;
   elsif p_cdAccion = REPLICAS_GENERAL.GET_ACCION_UPDATE then
      update tblguiacomischequeavalidar
         set row = v_Registro
       where idtmpguiacomischeque = p_id
         and icNoaceptado = 0;
   end if;

   close v_Cursor;

   p_ok := 1;
   return;

exception when others then
   GrabarLog(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM ||' suc: '||p_servidor||' id: '||p_id);
end TraerTMPCargaCheque;

/**************************************************************************************************
* Replica la tabla tblguiacomisautorizasaldo
* %v 04/12/2015 - MartinM
***************************************************************************************************/
procedure TraerGuiaComisAutorizaSaldo(p_servidor in  sucursales.servidor%type,
                                      p_cdAccion in             varchar2     ,
                                      p_id       in             varchar2     ,
                                      p_ok       out            integer      )
is
   v_modulo           varchar2(100) := 'PKG_REPLICA_SUC.TraerGuiaComisAutorizaSaldo';
   v_SQL              varchar2(4000);
   v_Cursor           cur_typ;
   v_Registro         tblguiacomisautorizasaldo%rowtype;

begin
   p_ok := 0;

   --Buscar los datos en la sucursal
   v_SQL := 'select * from tblguiacomisautorizasaldo@' || p_servidor || ' where idautorizasaldo =''' || p_id ||'''';
   open v_Cursor for v_SQL;
   fetch v_Cursor into v_Registro;

   --Hacer insert o update en AC
   if p_cdAccion = REPLICAS_GENERAL.GET_ACCION_INSERT then
      insert into tblguiacomisautorizasaldo values v_Registro;
   elsif p_cdAccion = REPLICAS_GENERAL.GET_ACCION_UPDATE then
      update tblguiacomisautorizasaldo
         set row = v_Registro
       where idautorizasaldo = p_id;
   end if;

   close v_Cursor;

   p_ok := 1;
   return;

exception when others then
   GrabarLog(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM ||' suc: '||p_servidor||' id: '||p_id);
end TraerGuiaComisAutorizaSaldo;

/**************************************************************************************************
* Replica la tabla tblruteovendedor
* %v 05/11/2015 - JBodnar
* %v 31/03/2016 - APW: contemplo delete
***************************************************************************************************/
procedure TraerRuteoVendedor (p_servidor in  sucursales.servidor%type,
                              p_cdAccion in  varchar2,
                              p_id       in  varchar2,
                              p_ok       out integer )
is
   v_modulo           varchar2(100) := 'PKG_REPLICA_SUC.TraerRuteoVendedor';
   v_SQL              varchar2(4000);
   v_Cursor           cur_typ;
   v_Registro         tblruteovendedor%rowtype;

begin
   p_ok := 0;

   --Buscar los datos en la sucursal
   v_SQL := 'select * from tblruteovendedor@' || p_servidor || ' where idruteovendedor =''' || p_id ||'''';
   open v_Cursor for v_SQL;
   fetch v_Cursor into v_Registro;

   --Hacer insert o update or delete en AC
   if p_cdAccion = REPLICAS_GENERAL.GET_ACCION_INSERT then
      insert into tblruteovendedor values v_Registro;
   elsif p_cdAccion = REPLICAS_GENERAL.GET_ACCION_UPDATE then
      update tblruteovendedor
         set row = v_Registro
       where idruteovendedor = p_id;
   elsif p_cdAccion = REPLICAS_GENERAL.GET_ACCION_DELETE then
      delete  tblruteovendedor
       where idruteovendedor = p_id;
   end if;

   close v_Cursor;

   p_ok := 1;
   return;

exception when others then
   GrabarLog(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM ||' suc: '||p_servidor||' id: '||p_id);
end TraerRuteoVendedor;

/**************************************************************************************************
* Replica la tabla tblclcontracargo
* %v 02/02/2015 - MartinM
***************************************************************************************************/
procedure TraerClContraCargo(p_servidor in  sucursales.servidor%type,
                             p_cdAccion in  varchar2,
                             p_id       in  varchar2,
                             p_ok       out integer )
is
   v_modulo           varchar2(100) := 'PKG_REPLICA_SUC.TraerClContraCargo';
   v_SQL              varchar2(4000);
   v_Cursor           cur_typ;
   v_Registro         tblclcontracargo%rowtype;

begin
   p_ok := 0;

   --Buscar los datos en la sucursal
   v_SQL := 'select * from tblclcontracargo@' || p_servidor || ' where idcontracargo =''' || p_id ||'''';
   open v_Cursor for v_SQL;
   fetch v_Cursor into v_Registro;

   --Hacer insert o update en AC
   if p_cdAccion = REPLICAS_GENERAL.GET_ACCION_INSERT then
      insert into tblclcontracargo values v_Registro;
   elsif p_cdAccion = REPLICAS_GENERAL.GET_ACCION_UPDATE then
      update tblclcontracargo set row = v_Registro where idcontracargo = p_id;
   end if;

   close v_Cursor;

   p_ok := 1;
   return;

exception when others then
   GrabarLog(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM ||' suc: '||p_servidor||' id: '||p_id);
end TraerClContraCargo;

/**************************************************************************************************
* Replica la tabla tblRendicionGuia
* %v 27/08/2015 - MartinM
***************************************************************************************************/
procedure TraerRendicionGuia(p_servidor in  sucursales.servidor%type,
                             p_cdAccion in  varchar2,
                             p_id       in  varchar2,
                             p_ok       out integer )
is
   v_modulo           varchar2(100) := 'PKG_REPLICA_SUC.TraerRendicionGuia';
   v_SQL              varchar2(4000);
   v_Cursor           cur_typ;
   v_Registro         tblrendicionguia%rowtype;

begin
   p_ok := 0;

   --Buscar los datos en la sucursal
   v_SQL := 'select * from tblrendicionguia@' || p_servidor || ' where idrendicionguia =''' || p_id ||'''';
   open v_Cursor for v_SQL;
   fetch v_Cursor into v_Registro;

   --Hacer insert o update en AC
   if p_cdAccion = REPLICAS_GENERAL.GET_ACCION_INSERT then
      insert into tblrendicionguia values v_Registro;
   elsif p_cdAccion = REPLICAS_GENERAL.GET_ACCION_UPDATE then
      update tblrendicionguia set row = v_Registro where idrendicionguia = p_id;
   end if;

   close v_Cursor;

   p_ok := 1;
   return;

exception when others then
   GrabarLog(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM ||' suc: '||p_servidor||' id: '||p_id);
end TraerRendicionGuia;

/**************************************************************************************************
* Replica la tabla tblingresoestado_ac
* %v 03/06/2014 - MarianoL
***************************************************************************************************/
procedure TraerIngresoEstadoAc(p_servidor in  sucursales.servidor%type,
                               p_cdAccion in  varchar2,
                               p_id       in  varchar2,
                               p_ok       out integer )
is
   v_modulo           varchar2(100) := 'PKG_REPLICA_SUC.TraerIngresoEstadoAc';
   v_SQL              varchar2(4000);
   v_Cursor           cur_typ;
   v_Registro         tblingresoestado_ac%rowtype;

begin
   p_ok := 0;

   --Buscar los datos en la sucursal
   v_SQL := 'select * from tblingresoestado_ac@' || p_servidor || ' where idingresoestadoac =''' || p_id ||'''';
   open v_Cursor for v_SQL;
   fetch v_Cursor into v_Registro;

   --Hacer insert o update en AC
   if p_cdAccion = REPLICAS_GENERAL.GET_ACCION_INSERT then
      insert into tblingresoestado_ac values v_Registro;
   elsif p_cdAccion = REPLICAS_GENERAL.GET_ACCION_UPDATE then
      update tblingresoestado_ac set row = v_Registro where idingresoestadoac = p_id;
   end if;

   close v_Cursor;

   p_ok := 1;
   return;

exception when others then
   GrabarLog(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM ||' suc: '||p_servidor||' id: '||p_id);
end TraerIngresoEstadoAc;

/**************************************************************************************************
* Replica la tabla guiasdetransporte
* %v 09/09/2014 - JBodnar
***************************************************************************************************/
procedure TraerGuiasTransporte(p_servidor in  sucursales.servidor%type,
                               p_cdAccion in  varchar2,
                               p_id       in  varchar2,
                               p_ok       out integer )
is
   v_modulo           varchar2(100) := 'PKG_REPLICA_SUC.TraerGuiasTransporte';
   v_SQL              varchar2(4000);
   v_Cursor           cur_typ;
   v_Registro         guiasdetransporte%rowtype;

begin
   p_ok := 0;

   --Buscar los datos en la sucursal
   v_SQL := 'select * from guiasdetransporte@' || p_servidor || ' where idguiadetransporte=''' || p_id ||'''';
   open v_Cursor for v_SQL;
   fetch v_Cursor into v_Registro;

   --Hacer insert o update en AC
   if p_cdAccion = REPLICAS_GENERAL.GET_ACCION_INSERT then
      insert into guiasdetransporte values v_Registro;
   elsif p_cdAccion = REPLICAS_GENERAL.GET_ACCION_UPDATE then
      update guiasdetransporte set row = v_Registro where idguiadetransporte = p_id;
   end if;

   close v_Cursor;

   p_ok := 1;
   return;

exception when others then
   GrabarLog(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM ||' suc: '||p_servidor||' id: '||p_id);
end TraerGuiasTransporte;

/**************************************************************************************************
* Replica la tabla detalleguiadetransporte
* %v 22/09/2014 - JBodnar
***************************************************************************************************/
procedure TraerDetGuiaTransporte(p_servidor in  sucursales.servidor%type,
                               p_cdAccion in  varchar2,
                               p_id       in  varchar2,
                               p_ok       out integer )
is
   v_modulo           varchar2(100) := 'PKG_REPLICA_SUC.TraerDetGuiaTransporte';
   v_SQL              varchar2(4000);
   v_Cursor           cur_typ;
   v_Registro         tbldetalleguia%rowtype;

begin
   p_ok := 0;

   --Buscar los datos en la sucursal
   v_SQL := 'select * from tbldetalleguia@' || p_servidor || ' where iddetalleguia=''' || p_id ||'''';
   open v_Cursor for v_SQL;
   fetch v_Cursor into v_Registro;

   --Hacer insert o update en AC
   if p_cdAccion = REPLICAS_GENERAL.GET_ACCION_INSERT then
      insert into tbldetalleguia values v_Registro;
   elsif p_cdAccion = REPLICAS_GENERAL.GET_ACCION_UPDATE then
      update tbldetalleguia set row = v_Registro where iddetalleguia = p_id;
   end if;

   close v_Cursor;

   p_ok := 1;
   return;

exception when others then
   GrabarLog(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM ||' suc: '||p_servidor||' id: '||p_id);
end TraerDetGuiaTransporte;

/**************************************************************************************************
* Replica la tabla tbldireccioncuenta
* %v 27/10/2014 - JBodnar
***************************************************************************************************/
procedure TraerDireccionCuenta(p_servidor in  sucursales.servidor%type,
                               p_cdAccion in  varchar2,
                               p_id       in  varchar2,
                               p_ok       out integer )
is
   v_modulo           varchar2(100) := 'PKG_REPLICA_SUC.TraerDireccionCuenta';
   v_SQL              varchar2(4000);
   v_Cursor           cur_typ;
   v_Registro         tbldireccioncuenta%rowtype;

begin
   p_ok := 0;

   --Buscar los datos en la sucursal
   v_SQL := 'select * from tbldireccioncuenta@' || p_servidor || ' where iddireccioncuenta=''' || p_id ||'''';
   open v_Cursor for v_SQL;
   fetch v_Cursor into v_Registro;

   --Hacer insert o update en AC
   if p_cdAccion = REPLICAS_GENERAL.GET_ACCION_INSERT then
      insert into tbldireccioncuenta values v_Registro;
   elsif p_cdAccion = REPLICAS_GENERAL.GET_ACCION_UPDATE then
      update tbldireccioncuenta set row = v_Registro where iddireccioncuenta = p_id;
   end if;

   --Agendar la réplica hacia la unica sucursal destino CC
   ReplicarUnicaSucursal('9998    ', 'tbldireccioncuenta', p_cdAccion, p_id);

   close v_Cursor;

   p_ok := 1;
   return;

exception when others then
   GrabarLog(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM ||' suc: '||p_servidor||' id: '||p_id);
end TraerDireccionCuenta;

/**************************************************************************************************
* Replica la tabla tbldeudatrans
* %v 12/12/2014 - JBodnar
***************************************************************************************************/
procedure TraerDeudaTrans(p_servidor in  sucursales.servidor%type,
                               p_cdAccion in  varchar2,
                               p_id       in  varchar2,
                               p_ok       out integer )
is
   v_modulo           varchar2(100) := 'PKG_REPLICA_SUC.TraerDeudaTrans';
   v_SQL              varchar2(4000);
   v_Cursor           cur_typ;
   v_Registro         tbldeudatrans%rowtype;

begin
   p_ok := 0;

   --Buscar los datos en la sucursal
   v_SQL := 'select * from tbldeudatrans@' || p_servidor || ' where iddeudatrans=''' || p_id ||'''';
   open v_Cursor for v_SQL;
   fetch v_Cursor into v_Registro;

   --Hacer insert o update en AC
   if p_cdAccion = REPLICAS_GENERAL.GET_ACCION_INSERT then
      insert into tbldeudatrans values v_Registro;
   elsif p_cdAccion = REPLICAS_GENERAL.GET_ACCION_UPDATE then
      update tbldeudatrans set row = v_Registro where iddeudatrans = p_id;
   end if;

   close v_Cursor;

   p_ok := 1;
   return;

exception when others then
   GrabarLog(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM ||' suc: '||p_servidor||' id: '||p_id);
end TraerDeudaTrans;

/**************************************************************************************************
* Replica la tabla tbldocumento_salida
* %v 17/12/2014 - JBodnar
***************************************************************************************************/
procedure TraerDocSalida(p_servidor in  sucursales.servidor%type,
                               p_cdAccion in  varchar2,
                               p_id       in  varchar2,
                               p_ok       out integer )
is
   v_modulo           varchar2(100) := 'PKG_REPLICA_SUC.TraerDocSalida';
   v_SQL              varchar2(4000);
   v_Cursor           cur_typ;
   v_Registro         tbldocumento_salida%rowtype;

begin
   p_ok := 0;

   --Buscar los datos en la sucursal
   v_SQL := 'select * from tbldocumento_salida@' || p_servidor || ' where idfacturasalida=''' || p_id ||'''';
   open v_Cursor for v_SQL;
   fetch v_Cursor into v_Registro;

   --Hacer insert o update en AC
   if p_cdAccion = REPLICAS_GENERAL.GET_ACCION_INSERT then
      insert into tbldocumento_salida values v_Registro;
   elsif p_cdAccion = REPLICAS_GENERAL.GET_ACCION_UPDATE then
      update tbldocumento_salida set row = v_Registro where idfacturasalida = p_id;
   end if;

   close v_Cursor;

   p_ok := 1;
   return;

exception when others then
   GrabarLog(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM ||' suc: '||p_servidor||' id: '||p_id);
end TraerDocSalida;


/**************************************************************************************************
* Replica la tabla pedidos
* %v 08/04/2015 - JBodnar
***************************************************************************************************/
procedure TraerPedidos(p_servidor in  sucursales.servidor%type,
                       p_cdAccion in  varchar2,
                       p_id       in  varchar2,
                       p_ok       out integer )
is
   v_modulo           varchar2(100) := 'PKG_REPLICA_SUC.TraerPedidos';
   v_SQL              varchar2(4000);
   v_Cursor           cur_typ;
   v_Registro         pedidos%rowtype;

begin
   p_ok := 0;

   --Buscar los datos en la sucursal
   v_SQL := 'select * from pedidos@' || p_servidor || ' where idpedido=''' || p_id ||'''';
   open v_Cursor for v_SQL;
   fetch v_Cursor into v_Registro;

   --Hacer update en AC solo del campo icestadosistema
   if p_cdAccion = REPLICAS_GENERAL.GET_ACCION_UPDATE then
      update pedidos p set p.icestadosistema = v_Registro.Icestadosistema where idpedido = p_id;
   end if;

   close v_Cursor;

   p_ok := 1;
   return;

exception when others then
   GrabarLog(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM ||' suc: '||p_servidor||' id: '||p_id);
end TraerPedidos;

/**************************************************************************************************
* Replica la tabla tbldocumento_control
* %v 20/08/2015 - JBodnar
***************************************************************************************************/
procedure TraerDocControl(p_servidor in  sucursales.servidor%type,
                               p_cdAccion in  varchar2,
                               p_id       in  varchar2,
                               p_ok       out integer )
is
   v_modulo           varchar2(100) := 'PKG_REPLICA_SUC.TraerDocControl';
   v_SQL              varchar2(4000);
   v_Cursor           cur_typ;
   v_Registro         tbldocumento_control%rowtype;

begin
   p_ok := 0;

   --Buscar los datos en la sucursal
   v_SQL := 'select * from tbldocumento_control@' || p_servidor || ' where idcontrol=''' || p_id ||'''';
   open v_Cursor for v_SQL;
   fetch v_Cursor into v_Registro;

   --Hacer insert o update en AC
   if p_cdAccion = REPLICAS_GENERAL.GET_ACCION_INSERT then
      insert into tbldocumento_control values v_Registro;
   elsif p_cdAccion = REPLICAS_GENERAL.GET_ACCION_UPDATE then
      update tbldocumento_control set row = v_Registro where idcontrol = p_id;
   end if;

   close v_Cursor;

   p_ok := 1;
   return;

exception when others then
   GrabarLog(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM ||' suc: '||p_servidor||' id: '||p_id);
end TraerDocControl;

/**************************************************************************************************
* Replica la tabla tblorigendocumento
* %v 08/09/2015 - MarianoL
***************************************************************************************************/
procedure TraerOrigenDocumento(p_servidor in  sucursales.servidor%type,
                               p_cdAccion in  varchar2,
                               p_id       in  varchar2,
                               p_ok       out integer )
is
   v_modulo           varchar2(100) := 'PKG_REPLICA_SUC.TraerOrigenDocumento';
   v_SQL              varchar2(4000);
   v_Cursor           cur_typ;
   v_Registro         tblorigendocumento%rowtype;

begin
   p_ok := 0;

   --Buscar los datos en la sucursal
   v_SQL := 'select * from tblorigendocumento@' || p_servidor || ' where cdorigendocumento =''' || p_id ||'''';
   open v_Cursor for v_SQL;
   fetch v_Cursor into v_Registro;

   --Hacer insert o update en AC
   if p_cdAccion = REPLICAS_GENERAL.GET_ACCION_INSERT then
      insert into tblorigendocumento values v_Registro;
   elsif p_cdAccion = REPLICAS_GENERAL.GET_ACCION_UPDATE then
      update tblorigendocumento set row = v_Registro where cdorigendocumento  = p_id;
   end if;

   close v_Cursor;

   p_ok := 1;
   return;

exception when others then
   GrabarLog(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM ||' suc: '||p_servidor||' id: '||p_id);
end TraerOrigenDocumento;

/**************************************************************************************************
* Replica la tabla tblguiacomistransferencia, tabla que guarda la relacion de la transferencia de
* los comisionistas y sus clientes en una guía.
* %v 30/09/2015 - MartinM
***************************************************************************************************/
procedure TraerGuiaComisTransferencia(p_servidor in  sucursales.servidor%type,
                                      p_cdAccion in  varchar2                ,
                                      p_id       in  varchar2                ,
                                      p_ok       out integer                 )
is
   v_modulo           varchar2(100) := 'PKG_REPLICA_SUC.TraerGuiaComisTransferencia';
   v_SQL              varchar2(4000);
   v_Cursor           cur_typ;
   v_Registro         tblguiacomistransferencia%rowtype;

begin
   p_ok := 0;

   --Buscar los datos en la sucursal
   v_SQL := 'select * from tblguiacomistransferencia@' || p_servidor || ' where idguiacomistransferencia =''' || p_id ||'''';
   open v_Cursor for v_SQL;
   fetch v_Cursor into v_Registro;

   --Hacer insert o update en AC
   if p_cdAccion = REPLICAS_GENERAL.GET_ACCION_INSERT then
      insert into tblguiacomistransferencia values v_Registro;
   end if;

   close v_Cursor;

   p_ok := 1;
   return;

exception when others then
   GrabarLog(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM ||' suc: '||p_servidor||' id: '||p_id);
end TraerGuiaComisTransferencia;

/**************************************************************************************************
* Replica la tabla cuentasusuarios
* %v 09/12/2015 - MarianoL
***************************************************************************************************/
procedure TraerCuentasUsuarios(p_servidor in  sucursales.servidor%type,
                               p_cdAccion in  varchar2                ,
                               p_id       in  varchar2                ,
                               p_ok       out integer                 )
is
   v_modulo           varchar2(100) := 'PKG_REPLICA_SUC.TraerCuentasUsuarios';
   v_SQL              varchar2(4000);
   v_Cursor           cur_typ;
   v_Registro         cuentasusuarios%rowtype;

begin
   p_ok := 0;

   --Buscar los datos en la sucursal
   v_SQL := 'select * from cuentasusuarios@' || p_servidor || ' where idpersona =''' || p_id ||'''';
   open v_Cursor for v_SQL;
   fetch v_Cursor into v_Registro;

   --Hacer insert o update en AC
   if p_cdAccion = REPLICAS_GENERAL.GET_ACCION_INSERT then
      insert into cuentasusuarios values v_Registro;
   elsif p_cdAccion = REPLICAS_GENERAL.GET_ACCION_UPDATE then
      update cuentasusuarios set row = v_Registro where idpersona  = p_id;
   end if;

   --Si el usuario tiene cdSucursal = '9999' hay que agendar la réplica para todas las sucursales
   if trim(v_Registro.Cdsucursal) = '9999' then
      --Agendar la réplica hacia el resto de las sucursales
      ReplicarTodasSucursales(p_servidor, 'cuentasusuarios', p_cdAccion, p_id, null);
   end if;

   close v_Cursor;

   p_ok := 1;
   return;

exception when others then
   GrabarLog(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM ||' suc: '||p_servidor||' id: '||p_id);
end TraerCuentasUsuarios;

/**************************************************************************************************
* Replica la tabla entidades
* %v 18/11/2015 - MarianoL
***************************************************************************************************/
procedure TraerEntidades(p_servidor in  sucursales.servidor%type,
                         p_cdAccion in  varchar2,
                         p_id       in  varchar2,
                         p_ok       out integer )
is
   v_modulo           varchar2(100) := 'PKG_REPLICA_SUC.TraerEntidades';
   v_SQL              varchar2(4000);
   v_Cursor           cur_typ;
   v_Registro         entidades%rowtype;

begin
   p_ok := 0;

   --Buscar los datos en la sucursal
   v_SQL := 'select * from entidades@' || p_servidor || ' where identidad =''' || p_id ||'''';
   open v_Cursor for v_SQL;
   fetch v_Cursor into v_Registro;

   --Hacer insert o update en AC
   if p_cdAccion = REPLICAS_GENERAL.GET_ACCION_INSERT then
      insert into entidades values v_Registro;
   elsif p_cdAccion = REPLICAS_GENERAL.GET_ACCION_UPDATE then
      update entidades set row = v_Registro where identidad = p_id;
   end if;

   --Agendar la réplica hacia el resto de las sucursales
   ReplicarTodasSucursales(p_servidor, 'entidades', p_cdAccion, p_id, null);

   close v_Cursor;

   p_ok := 1;
   return;

exception when others then
   GrabarLog(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM ||' suc: '||p_servidor||' id: '||p_id);
end TraerEntidades;

/**************************************************************************************************
* Replica la tabla infoimpuestosentidades
* %v 18/11/2015 - MarianoL
***************************************************************************************************/
procedure TraerInfoImpuestosEntidades(p_servidor in  sucursales.servidor%type,
                                      p_cdAccion in  varchar2,
                                      p_id       in  varchar2,
                                      p_ok       out integer )
is
   v_modulo           varchar2(100) := 'PKG_REPLICA_SUC.TraerInfoImpuestosEntidades';
   v_SQL              varchar2(4000);
   v_Cursor           cur_typ;
   v_Registro         infoimpuestosentidades%rowtype;

begin
   p_ok := 0;

   --Buscar los datos en la sucursal
   v_SQL := 'select * from infoimpuestosentidades@' || p_servidor || ' where identidad =''' || p_id ||'''';
   open v_Cursor for v_SQL;
   fetch v_Cursor into v_Registro;

   --Hacer insert o update en AC
   if p_cdAccion = REPLICAS_GENERAL.GET_ACCION_INSERT then
      insert into infoimpuestosentidades values v_Registro;
   elsif p_cdAccion = REPLICAS_GENERAL.GET_ACCION_UPDATE then
      update infoimpuestosentidades set row = v_Registro where identidad = p_id;
   elsif p_cdAccion = REPLICAS_GENERAL.GET_ACCION_DELETE then
      delete infoimpuestosentidades where identidad = p_id;
   end if;

   --Agendar la réplica hacia el resto de las sucursales
   ReplicarTodasSucursales(p_servidor, 'infoimpuestosentidades', p_cdAccion, p_id, null);

   close v_Cursor;

   p_ok := 1;
   return;

exception when others then
   GrabarLog(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM ||' suc: '||p_servidor||' id: '||p_id);
end TraerInfoImpuestosEntidades;

/**************************************************************************************************
* Replica la tabla tjclientescf
* %v 16/12/2015 - MarianoL
***************************************************************************************************/
procedure TraerTarjetasEntidades(p_servidor in  sucursales.servidor%type,
                                 p_cdAccion in  varchar2,
                                 p_id       in  varchar2,
                                 p_ok       out integer )
is
   v_modulo           varchar2(100) := 'PKG_REPLICA_SUC.TraerTarjetasEntidades';
   v_SQL              varchar2(4000);
   v_Cursor           cur_typ;
   v_Registro         tjclientescf%rowtype;

begin
   p_ok := 0;

   --Buscar los datos en la sucursal
   v_SQL := 'select * from tjclientescf@' || p_servidor || ' where identidad =''' || p_id ||'''';
   open v_Cursor for v_SQL;
   fetch v_Cursor into v_Registro;

   --Hacer insert o update en AC
   if p_cdAccion = REPLICAS_GENERAL.GET_ACCION_INSERT then
      insert into tjclientescf values v_Registro;
   elsif p_cdAccion = REPLICAS_GENERAL.GET_ACCION_UPDATE then
      update tjclientescf set row = v_Registro where identidad = p_id;
   elsif p_cdAccion = REPLICAS_GENERAL.GET_ACCION_DELETE then
      delete tjclientescf where identidad = p_id;
   end if;

   --Agendar la réplica hacia el resto de las sucursales
   ReplicarTodasSucursales(p_servidor, 'tjclientescf', p_cdAccion, p_id, null);

   close v_Cursor;

   p_ok := 1;
   return;

exception when others then
   GrabarLog(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM ||' suc: '||p_servidor||' id: '||p_id);
end TraerTarjetasEntidades;

/**************************************************************************************************
* Replica la tabla rolesentidades
* ATENCION: esta es una tabla antigua que tiene PK compuesta por más de un campo, por
*           este motivo cambia la forma de buscar el dato.
* %v 18/11/2015 - MarianoL
***************************************************************************************************/
procedure TraerRolesEntidades(p_servidor    in  sucursales.servidor%type,
                              p_cdAccion    in  varchar2,
                              p_id          in  varchar2,
                              p_idCompuesto in  varchar2,
                              p_ok          out integer )
is
   v_modulo           varchar2(100) := 'PKG_REPLICA_SUC.TraerRolesEntidades';
   v_SQL              varchar2(4000);
   v_Cursor           cur_typ;
   v_Registro         rolesentidades%rowtype;
   v_idEntidad        rolesentidades.identidad%type;
   v_cdRol            rolesentidades.cdrol%type;

begin
   p_ok := 0;

   --Decodificar el id compuesto en cada campo
   v_idEntidad := GetIdPorPosicion(p_idCompuesto,1);
   v_cdRol     := GetIdPorPosicion(p_idCompuesto,2);

   --Buscar los datos en la sucursal
   v_SQL := 'select * from rolesentidades@'||p_servidor||' where identidad = '''||v_idEntidad||''' and cdrol = '''||v_cdRol||'''';
   open v_Cursor for v_SQL;
   fetch v_Cursor into v_Registro;

   --Hacer insert o update en AC
   if p_cdAccion = REPLICAS_GENERAL.GET_ACCION_INSERT then
      insert into rolesentidades values v_Registro;
   elsif p_cdAccion = REPLICAS_GENERAL.GET_ACCION_UPDATE then
      update rolesentidades set row = v_Registro where identidad = v_idEntidad and cdrol = v_cdRol;
   elsif p_cdAccion = REPLICAS_GENERAL.GET_ACCION_DELETE then
      delete rolesentidades where identidad = v_idEntidad and cdrol = v_cdRol;
   end if;

   --Agendar la réplica hacia el resto de las sucursales
   ReplicarTodasSucursales(p_servidor, 'rolesentidades', p_cdAccion, p_id, p_idCompuesto);

   close v_Cursor;

   p_ok := 1;
   return;

exception when others then
   GrabarLog(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM ||' suc: '||p_servidor||' id: '||p_id);
end TraerRolesEntidades;

/**************************************************************************************************
* Replica la tabla contactosentidades
* ATENCION: esta es una tabla antigua que tiene PK compuesta por más de un campo, por
*           este motivo cambia la forma de buscar el dato.
* %v 15/12/2015 - MarianoL
***************************************************************************************************/
/**************************************************************************************************
* Replica la tabla contactosentidades
* ATENCION: esta es una tabla antigua que tiene PK compuesta por más de un campo, por
*           este motivo cambia la forma de buscar el dato.
* %v 15/12/2015 - MarianoL
* %v 08/08/2016 RicardoC, se incluye nuevamente cdformadecontacto en clave compuesta
*    Se corrigió en el v_SQL y en el update.
***************************************************************************************************/
procedure TraerContactosEntidades(p_servidor    in  sucursales.servidor%type,
                                  p_cdAccion    in  varchar2,
                                  p_id          in  varchar2,
                                  p_idCompuesto in  varchar2,
                                  p_ok          out integer )
is
   v_modulo            varchar2(100) := 'PKG_REPLICA_SUC.TraerContactosEntidades';
   v_SQL               varchar2(4000);
   v_Cursor            cur_typ;
   v_Registro          contactosentidades%rowtype;
   v_idEntidad         contactosentidades.identidad%type;
   v_cdFormaContacto   contactosentidades.cdformadecontacto%type;
   v_sqContactoEntidad contactosentidades.sqcontactoentidad%type;


begin
   p_ok := 0;

   --Decodificar el id compuesto en cada campo
   v_idEntidad         := GetIdPorPosicion(p_idCompuesto,1);
   v_cdFormaContacto   := GetIdPorPosicion(p_idCompuesto,2); --No usar más porque la aplicación cambia este dato!!!
   v_sqContactoEntidad := GetIdPorPosicion(p_idCompuesto,3);

   --Buscar los datos en la sucursal
   v_SQL := 'select * from contactosentidades@'||p_servidor||' where identidad = '''||v_idEntidad||''' and cdformadecontacto='''||v_cdFormaContacto
         ||''' and sqcontactoentidad='||v_sqContactoEntidad;

   open v_Cursor for v_SQL;
   fetch v_Cursor into v_Registro;

   --Hacer insert o update en AC
   if p_cdAccion = REPLICAS_GENERAL.GET_ACCION_INSERT then
      insert into contactosentidades values v_Registro;
   elsif p_cdAccion = REPLICAS_GENERAL.GET_ACCION_UPDATE then
      update contactosentidades set row = v_Registro where identidad = v_idEntidad and cdformadecontacto = v_cdFormaContacto and sqcontactoentidad = v_sqContactoEntidad;
   elsif p_cdAccion = REPLICAS_GENERAL.GET_ACCION_DELETE then
      delete contactosentidades where identidad = v_idEntidad and cdformadecontacto = v_cdFormaContacto and sqcontactoentidad = v_sqContactoEntidad;
   end if;

   --Agendar la réplica hacia el resto de las sucursales
   ReplicarTodasSucursales(p_servidor, 'contactosentidades', p_cdAccion, p_id, p_idCompuesto);

   close v_Cursor;

   p_ok := 1;
   return;

exception when others then
   GrabarLog(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM ||' suc: '||p_servidor||' id: '||p_id);
end TraerContactosEntidades;

/**************************************************************************************************
* Replica la tabla direccionesentidades
* ATENCION: esta es una tabla antigua que tiene PK compuesta por más de un campo, por
*           este motivo cambia la forma de buscar el dato.
* %v 15/12/2015 - MarianoL
***************************************************************************************************/
procedure TraerDireccionesEntidades(p_servidor    in  sucursales.servidor%type,
                                    p_cdAccion    in  varchar2,
                                    p_id          in  varchar2,
                                    p_idCompuesto in  varchar2,
                                    p_ok          out integer )
is
   v_modulo          varchar2(100) := 'PKG_REPLICA_SUC.TraerDireccionesEntidades';
   v_SQL             varchar2(4000);
   v_Cursor          cur_typ;
   v_Registro        direccionesentidades%rowtype;
   v_idEntidad       direccionesentidades.identidad%type;
   v_cdTipoDireccion direccionesentidades.cdtipodireccion%type;
   v_sqDireccion     direccionesentidades.sqdireccion%type;

begin
   p_ok := 0;

   --Decodificar el id compuesto en cada campo
   v_idEntidad       := GetIdPorPosicion(p_idCompuesto,1);
   v_cdTipoDireccion := GetIdPorPosicion(p_idCompuesto,2);
   v_sqDireccion     := GetIdPorPosicion(p_idCompuesto,3);

   --Buscar los datos en la sucursal
   v_SQL := 'select * from direccionesentidades@'||p_servidor||' where identidad = '''||v_idEntidad||
            ''' and cdtipodireccion = '''||v_cdTipoDireccion||''' and sqdireccion='||v_sqDireccion;
   open v_Cursor for v_SQL;
   fetch v_Cursor into v_Registro;

   --Hacer insert o update en AC
   if p_cdAccion = REPLICAS_GENERAL.GET_ACCION_INSERT then
      insert into direccionesentidades values v_Registro;
   elsif p_cdAccion = REPLICAS_GENERAL.GET_ACCION_UPDATE then
      update direccionesentidades set row = v_Registro where identidad = v_idEntidad and cdtipodireccion = v_cdTipoDireccion
             and sqdireccion = v_sqDireccion;
   elsif p_cdAccion = REPLICAS_GENERAL.GET_ACCION_DELETE then
      delete direccionesentidades where identidad = v_idEntidad and cdtipodireccion = v_cdTipoDireccion
             and sqdireccion = v_sqDireccion;
   end if;

   --Agendar la réplica hacia el resto de las sucursales
   ReplicarTodasSucursales(p_servidor, 'direccionesentidades', p_cdAccion, p_id, p_idCompuesto);

   close v_Cursor;

   p_ok := 1;
   return;

exception when others then
   GrabarLog(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM ||' suc: '||p_servidor||' id: '||p_id);
end TraerDireccionesEntidades;

/**************************************************************************************************
* Replica la tabla clientescomisionistas
* ATENCION: esta es una tabla antigua que tiene PK compuesta por más de un campo, por
*           este motivo cambia la forma de buscar el dato.
* %v 15/12/2015 - MarianoL
***************************************************************************************************/
procedure TraerClientesComisionistas(p_servidor    in  sucursales.servidor%type,
                                     p_cdAccion    in  varchar2,
                                     p_id          in  varchar2,
                                     p_idCompuesto in  varchar2,
                                     p_ok          out integer )
is
   v_modulo          varchar2(100) := 'PKG_REPLICA_SUC.TraerClientesComisionistas';
   v_SQL             varchar2(4000);
   v_Cursor          cur_typ;
   v_Registro        clientescomisionistas%rowtype;
   v_idComisionista  clientescomisionistas.idcomisionista%type;
   v_idEntidad       clientescomisionistas.identidad%type;

begin
   p_ok := 0;

   --Decodificar el id compuesto en cada campo
   v_idComisionista := GetIdPorPosicion(p_idCompuesto,1);
   v_idEntidad      := GetIdPorPosicion(p_idCompuesto,2);

   --Buscar los datos en la sucursal
   v_SQL := 'select * from clientescomisionistas@'||p_servidor||' where idcomisionista = '''||v_idComisionista||
            ''' and identidad = '''||v_idEntidad||'''';
   open v_Cursor for v_SQL;
   fetch v_Cursor into v_Registro;

   --Hacer insert o update en AC
   if p_cdAccion = REPLICAS_GENERAL.GET_ACCION_INSERT then
      insert into clientescomisionistas values v_Registro;
   elsif p_cdAccion = REPLICAS_GENERAL.GET_ACCION_UPDATE then
      update clientescomisionistas set row = v_Registro where idcomisionista = v_idComisionista and identidad = v_idEntidad;
   elsif p_cdAccion = REPLICAS_GENERAL.GET_ACCION_DELETE then
      delete clientescomisionistas where idcomisionista = v_idComisionista and identidad = v_idEntidad;
   end if;

   close v_Cursor;

   p_ok := 1;
   return;

exception when others then
   GrabarLog(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM ||' suc: '||p_servidor||' id: '||p_id);
end TraerClientesComisionistas;

/**************************************************************************************************
* Replica la tabla acumcfvital
* ATENCION: esta es una tabla antigua que tiene PK compuesta por más de un campo, por
*           este motivo cambia la forma de buscar el dato.
* %v 15/12/2015 - MarianoL
***************************************************************************************************/
procedure TraerAcumCfVital(p_servidor    in  sucursales.servidor%type,
                           p_cdAccion    in  varchar2,
                           p_id          in  varchar2,
                           p_idCompuesto in  varchar2,
                           p_ok          out integer )
is
   v_modulo          varchar2(100) := 'PKG_REPLICA_SUC.TraerAcumCfVital';
   v_SQL             varchar2(4000);
   v_Cursor          cur_typ;
   v_Registro        acumcfvital%rowtype;
   v_idPersona       acumcfvital.idpersona%type;
   v_cdSucursal      acumcfvital.cdsucursal%type;
   v_dtAcumulado     varchar2(10);

begin
   p_ok := 0;

   --Decodificar el id compuesto en cada campo
   v_idPersona   := GetIdPorPosicion(p_idCompuesto,1);
   v_cdSucursal  := GetIdPorPosicion(p_idCompuesto,2);
   v_dtAcumulado := GetIdPorPosicion(p_idCompuesto,3);

   --Buscar los datos en la sucursal
   v_SQL := 'select * from acumcfvital@'||p_servidor||' where idpersona = '''||v_idPersona||
            ''' and cdsucursal = '''||v_cdSucursal||''' and dtyearmonth = to_date('''||v_dtAcumulado||''' ,''dd/mm/yyyy'')';
   open v_Cursor for v_SQL;
   fetch v_Cursor into v_Registro;

   --Hacer insert o update en AC
   if p_cdAccion = REPLICAS_GENERAL.GET_ACCION_INSERT then
      insert into acumcfvital values v_Registro;
   elsif p_cdAccion = REPLICAS_GENERAL.GET_ACCION_UPDATE then
      update acumcfvital set row = v_Registro where idpersona = v_idPersona and cdsucursal = v_cdSucursal and dtyearmonth = to_date(v_dtAcumulado,'dd/mm/yyyy');
   elsif p_cdAccion = REPLICAS_GENERAL.GET_ACCION_DELETE then
      delete acumcfvital where idpersona = v_idPersona and cdsucursal = v_cdSucursal and dtyearmonth = to_date(v_dtAcumulado,'dd/mm/yyyy');
   end if;

   --Agendar la réplica hacia el resto de las sucursales
   ReplicarTodasSucursales(p_servidor, 'acumcfvital', p_cdAccion, p_id, p_idCompuesto);

   close v_Cursor;

   p_ok := 1;
   return;

exception when others then
   GrabarLog(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM ||' suc: '||p_servidor||' id: '||p_id);
end TraerAcumCfVital;

/**************************************************************************************************
* Replica la tabla TblImpAcumulador
* %v 04/03/2016 - JBodnar
***************************************************************************************************/
procedure TraerImpAcumulador(p_servidor in  sucursales.servidor%type,
                             p_cdAccion in  varchar2,
                             p_id       in  varchar2,
                             p_ok       out integer )
is
   v_modulo           varchar2(100) := 'PKG_REPLICA_SUC.TraerImpAcumulador';
   v_SQL              varchar2(4000);
   v_Cursor           cur_typ;
   v_Registro         tblimpacumulador%rowtype;

begin
   p_ok := 0;

   --Buscar los datos en la sucursal
   v_SQL := 'select * from tblimpacumulador@' || p_servidor || ' where idimpacumulador  =''' || p_id ||'''';
   open v_Cursor for v_SQL;
   fetch v_Cursor into v_Registro;

   --Hacer insert o update en AC
   if p_cdAccion = REPLICAS_GENERAL.GET_ACCION_INSERT then
      insert into tblimpacumulador values v_Registro;
   elsif p_cdAccion = REPLICAS_GENERAL.GET_ACCION_UPDATE then
      update tblimpacumulador set row = v_Registro where idimpacumulador = p_id;
   end if;

   --Agendar la réplica hacia el resto de las sucursales
   ReplicarTodasSucursales(p_servidor, 'tblimpacumulador', p_cdAccion, p_id, null);

   close v_Cursor;

   p_ok := 1;
   return;

exception when others then
   GrabarLog(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM ||' suc: '||p_servidor||' id: '||p_id);
end TraerImpAcumulador;

/**************************************************************************************************
* Replica la tabla ubicacionarticulos
* ATENCION: esta es una tabla antigua que tiene PK compuesta por más de un campo, por
*           este motivo cambia la forma de buscar el dato.
* %v 12/04/2016 - APW
***************************************************************************************************/
procedure TraerUbicacionArticulos(p_servidor    in  sucursales.servidor%type,
                                  p_cdAccion    in  varchar2,
                                  p_id          in  varchar2,
                                  p_idCompuesto in  varchar2,
                                  p_ok          out integer )
is
   v_modulo          varchar2(100) := 'PKG_REPLICA_SUC.TraerUbicacionArticulos';
   v_SQL             varchar2(4000);
   v_Cursor          cur_typ;
   v_Registro        ubicacionarticulos%rowtype;
   v_cdalmacen       ubicacionarticulos.cdalmacen%type;
   v_cdsucursal      ubicacionarticulos.cdsucursal%type;
   v_cdarticulo      ubicacionarticulos.cdarticulo%type;

begin
   p_ok := 0;

   --Decodificar el id compuesto en cada campo
   v_cdalmacen       := GetIdPorPosicion(p_idCompuesto,1);
   v_cdsucursal     := GetIdPorPosicion(p_idCompuesto,2);
   v_cdarticulo     := GetIdPorPosicion(p_idCompuesto,3);

   --Buscar los datos en la sucursal
   v_SQL := 'select * from ubicacionarticulos@'||p_servidor||' where cdalmacen = '''||v_cdalmacen||
            ''' and cdsucursal = '''||v_cdsucursal||''' and cdarticulo='||v_cdarticulo;
   open v_Cursor for v_SQL;
   fetch v_Cursor into v_Registro;

   --Hacer insert o update en AC
   if p_cdAccion = REPLICAS_GENERAL.GET_ACCION_INSERT then
      insert into ubicacionarticulos values v_Registro;
   elsif p_cdAccion = REPLICAS_GENERAL.GET_ACCION_UPDATE then
      update ubicacionarticulos
             set row = v_Registro
             where cdalmacen = v_cdalmacen
             and cdsucursal = v_cdsucursal
             and cdarticulo = v_cdarticulo;
   elsif p_cdAccion = REPLICAS_GENERAL.GET_ACCION_DELETE then
      delete ubicacionarticulos
      where cdalmacen = v_cdalmacen
             and cdsucursal = v_cdsucursal
             and cdarticulo = v_cdarticulo;
   end if;

   close v_Cursor;

   p_ok := 1;
   return;

exception when others then
   GrabarLog(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM ||' suc: '||p_servidor||' id: '||p_id);
end TraerUbicacionArticulos;

/**************************************************************************************************
* Replica la tabla tblcontrolpuertacomentario
* %v 16/05/2016 - APW
***************************************************************************************************/
procedure TraerControlPuertaComentario(p_servidor in  sucursales.servidor%type,
                                       p_cdAccion in  varchar2,
                                       p_id       in  varchar2,
                                       p_ok       out integer )
is
   v_modulo           varchar2(100) := 'PKG_REPLICA_SUC.TraerControlPuertaComentario';
   v_SQL              varchar2(4000);
   v_Cursor           cur_typ;
   v_Registro         tblcontrolpuertacomentario%rowtype;

begin
   p_ok := 0;

   --Buscar los datos en la sucursal
   v_SQL := 'select * from tblcontrolpuertacomentario@' || p_servidor || ' where IDCONTROLPUESTACOMENTARIO =''' || p_id ||'''';
   open v_Cursor for v_SQL;
   fetch v_Cursor into v_Registro;

   --Hacer insert o update en AC
   if p_cdAccion = REPLICAS_GENERAL.GET_ACCION_INSERT then
      insert into tblcontrolpuertacomentario values v_Registro;
   elsif p_cdAccion = REPLICAS_GENERAL.GET_ACCION_UPDATE then
      update tblcontrolpuertacomentario set row = v_Registro where IDCONTROLPUESTACOMENTARIO = p_id;
   elsif p_cdAccion = REPLICAS_GENERAL.GET_ACCION_DELETE then
      delete tblcontrolpuertacomentario where IDCONTROLPUESTACOMENTARIO = p_id;
   end if;

   close v_Cursor;

   p_ok := 1;
   return;

exception when others then
   GrabarLog(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM ||' suc: '||p_servidor||' id: '||p_id);
end TraerControlPuertaComentario;


/**************************************************************************************************
* Replica la tabla tblcontrolstockhistorico
* %v 16/05/2016 - APW
***************************************************************************************************/
procedure TraerControlStockHist(p_servidor in  sucursales.servidor%type,
                                p_cdAccion in  varchar2,
                                p_id       in  varchar2,
                                p_ok       out integer )
is
   v_modulo           varchar2(100) := 'PKG_REPLICA_SUC.TraerControlStockHist';
   v_SQL              varchar2(4000);
   v_Cursor           cur_typ;
   v_Registro         tblcontrolstockhistorico%rowtype;

begin
   p_ok := 0;

   --Buscar los datos en la sucursal
   v_SQL := 'select * from tblcontrolstockhistorico@' || p_servidor || ' where IDCONTROLSTOCKHIST =''' || p_id ||'''';
   open v_Cursor for v_SQL;
   fetch v_Cursor into v_Registro;

   --Hacer insert o update en AC
   if p_cdAccion = REPLICAS_GENERAL.GET_ACCION_INSERT then
      insert into tblcontrolstockhistorico values v_Registro;
   elsif p_cdAccion = REPLICAS_GENERAL.GET_ACCION_UPDATE then
      update tblcontrolstockhistorico set row = v_Registro where IDCONTROLSTOCKHIST = p_id;
   elsif p_cdAccion = REPLICAS_GENERAL.GET_ACCION_DELETE then
      delete tblcontrolstockhistorico where IDCONTROLSTOCKHIST = p_id;
   end if;

   close v_Cursor;

   p_ok := 1;
   return;

exception when others then
   GrabarLog(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM ||' suc: '||p_servidor||' id: '||p_id);
end TraerControlStockHist;


/**************************************************************************************************
* Replica la tabla tblcontrolstockdetalle
* %v 16/05/2016 - APW
***************************************************************************************************/
procedure TraerControlStockDet(p_servidor in  sucursales.servidor%type,
                                p_cdAccion in  varchar2,
                                p_id       in  varchar2,
                                p_ok       out integer )
is
   v_modulo           varchar2(100) := 'PKG_REPLICA_SUC.TraerControlStockDet';
   v_SQL              varchar2(4000);
   v_Cursor           cur_typ;
   v_Registro         tblcontrolstockdetalle%rowtype;

begin
   p_ok := 0;

   --Buscar los datos en la sucursal
   v_SQL := 'select * from tblcontrolstockdetalle@' || p_servidor || ' where IDCONTROLSTOCKDETALLE =''' || p_id ||'''';
   open v_Cursor for v_SQL;
   fetch v_Cursor into v_Registro;

   --Hacer insert o update en AC
   if p_cdAccion = REPLICAS_GENERAL.GET_ACCION_INSERT then
      insert into tblcontrolstockdetalle values v_Registro;
   elsif p_cdAccion = REPLICAS_GENERAL.GET_ACCION_UPDATE then
      update tblcontrolstockdetalle set row = v_Registro where IDCONTROLSTOCKDETALLE = p_id;
   elsif p_cdAccion = REPLICAS_GENERAL.GET_ACCION_DELETE then
      delete tblcontrolstockdetalle where IDCONTROLSTOCKDETALLE = p_id;
   end if;

   close v_Cursor;

   p_ok := 1;
   return;

exception when others then
   GrabarLog(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM ||' suc: '||p_servidor||' id: '||p_id);
end TraerControlStockDet;

/**************************************************************************************************
* Replica la tabla tblauditoria
* %v 24/06/2016 - JBodnar
***************************************************************************************************/
procedure TraerAuditoria(p_servidor in  sucursales.servidor%type,
                                p_cdAccion in  varchar2,
                                p_id       in  varchar2,
                                p_ok       out integer )
is
   v_modulo           varchar2(100) := 'PKG_REPLICA_SUC.TraerAuditoria';
   v_SQL              varchar2(4000);
   v_Cursor           cur_typ;
   v_Registro         tblauditoria%rowtype;

begin
   p_ok := 0;

   --Buscar los datos en la sucursal
   v_SQL := 'select * from tblauditoria@' || p_servidor || ' where idauditoria =''' || p_id ||'''';
   open v_Cursor for v_SQL;
   fetch v_Cursor into v_Registro;

   --Hacer insert o update en AC
   if p_cdAccion = REPLICAS_GENERAL.GET_ACCION_INSERT then
      insert into tblauditoria values v_Registro;
   elsif p_cdAccion = REPLICAS_GENERAL.GET_ACCION_UPDATE then
      update tblauditoria set row = v_Registro where idauditoria = p_id;
   elsif p_cdAccion = REPLICAS_GENERAL.GET_ACCION_DELETE then
      delete tblauditoria where idauditoria = p_id;
   end if;

   close v_Cursor;

   p_ok := 1;
   return;

exception when others then
   GrabarLog(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM ||' suc: '||p_servidor||' id: '||p_id);
end TraerAuditoria;


/**************************************************************************************************
* Replica la tabla auditoria
* %v 12/07/2016 - APW
***************************************************************************************************/
procedure TraerAuditoriaVieja(p_servidor in  sucursales.servidor%type,
                                p_cdAccion in  varchar2,
                                p_id       in  varchar2,
                                p_ok       out integer )
is
   v_modulo           varchar2(100) := 'PKG_REPLICA_SUC.TraerAuditoriaVieja';
   v_SQL              varchar2(4000);
   v_Cursor           cur_typ;
   v_Registro         auditoria%rowtype;

begin
   p_ok := 0;

   --Buscar los datos en la sucursal
   v_SQL := 'select * from auditoria@' || p_servidor || ' where idauditoria =''' || p_id ||'''';
   open v_Cursor for v_SQL;
   fetch v_Cursor into v_Registro;

   --Hacer insert o update en AC
   if p_cdAccion = REPLICAS_GENERAL.GET_ACCION_INSERT then
      insert into auditoria values v_Registro;
   elsif p_cdAccion = REPLICAS_GENERAL.GET_ACCION_UPDATE then
      update auditoria set row = v_Registro where idauditoria = p_id;
   elsif p_cdAccion = REPLICAS_GENERAL.GET_ACCION_DELETE then
      delete auditoria where idauditoria = p_id;
   end if;

   close v_Cursor;

   p_ok := 1;
   return;

exception when others then
   GrabarLog(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM ||' suc: '||p_servidor||' id: '||p_id);
end TraerAuditoriaVieja;

/**************************************************************************************************
* Replica la tabla TblTraspasoTrans
* %v 02/08/2016 - JBodnar
***************************************************************************************************/
procedure TraerTraspasoTrans(p_servidor in  sucursales.servidor%type,
                             p_cdAccion in  varchar2,
                             p_id       in  varchar2,
                             p_ok       out integer )
is
   v_modulo           varchar2(100) := 'PKG_REPLICA_SUC.TraerTraspasoTrans';
   v_SQL              varchar2(4000);
   v_Cursor           cur_typ;
   v_Registro         tbltraspasotrans%rowtype;

begin
   p_ok := 0;

   --Buscar los datos en la sucursal
   v_SQL := 'select * from tbltraspasotrans@' || p_servidor || ' where idtraspasotrans  =''' || p_id ||'''';
   open v_Cursor for v_SQL;
   fetch v_Cursor into v_Registro;

   --Hacer insert o update en AC
   if p_cdAccion = REPLICAS_GENERAL.GET_ACCION_INSERT then
      insert into tbltraspasotrans values v_Registro;
   elsif p_cdAccion = REPLICAS_GENERAL.GET_ACCION_UPDATE then
      update tbltraspasotrans set row = v_Registro where idtraspasotrans = p_id;
   end if;

   --Agendar la réplica hacia la unica sucursal destino
   ReplicarUnicaSucursal(v_Registro.Cdsucursaldestino, 'tbltraspasotrans', p_cdAccion, p_id);

   close v_Cursor;

   p_ok := 1;
   return;

exception when others then
   GrabarLog(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM ||' suc: '||p_servidor||' id: '||p_id);
end TraerTraspasoTrans;

/**************************************************************************************************
* Replica la tabla tbldonacion
* %v 26/08/2016 - JBodnar
***************************************************************************************************/
procedure TraerDonacion (p_servidor in  sucursales.servidor%type,
                         p_cdAccion in  varchar2,
                         p_id       in  varchar2,
                         p_ok       out integer )
is
   v_modulo           varchar2(100) := 'PKG_REPLICA_SUC.TraerDonacion';
   v_SQL              varchar2(4000);
   v_Cursor           cur_typ;
   v_Registro         tbldonacion%rowtype;

begin
   p_ok := 0;

   --Buscar los datos en la sucursal
   v_SQL := 'select * from tbldonacion@' || p_servidor || ' where idingreso =''' || p_id ||'''';
   open v_Cursor for v_SQL;
   fetch v_Cursor into v_Registro;

   --Hacer insert o update en AC
   if p_cdAccion = REPLICAS_GENERAL.GET_ACCION_INSERT then
      insert into tbldonacion values v_Registro;
   elsif p_cdAccion = REPLICAS_GENERAL.GET_ACCION_UPDATE then
      update tbldonacion set row = v_Registro where idingreso = p_id;
   end if;

   close v_Cursor;

   p_ok := 1;
   return;

exception when others then
   GrabarLog(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM ||' suc: '||p_servidor||' id: '||p_id);
end TraerDonacion;

/**************************************************************************************************
* Replica la tabla tblreclamoposnet
* %v 20/04/2017 - JBodnar
***************************************************************************************************/
procedure TraerReclamoPosnet (p_servidor in  sucursales.servidor%type,
                              p_cdAccion in  varchar2,
                              p_id       in  varchar2,
                              p_ok       out integer )
is
   v_modulo           varchar2(100) := 'PKG_REPLICA_SUC.TraerReclamoPosnet';
   v_SQL              varchar2(4000);
   v_Cursor           cur_typ;
   v_Registro         tblreclamoposnet%rowtype;

begin
   p_ok := 0;

   --Buscar los datos en la sucursal
   v_SQL := 'select * from tblreclamoposnet@' || p_servidor || ' where idreclamo =''' || p_id ||'''';
   open v_Cursor for v_SQL;
   fetch v_Cursor into v_Registro;

   --Hacer insert o update en AC
   if p_cdAccion = REPLICAS_GENERAL.GET_ACCION_INSERT then
      insert into tblreclamoposnet values v_Registro;
   elsif p_cdAccion = REPLICAS_GENERAL.GET_ACCION_UPDATE then
      update tblreclamoposnet set row = v_Registro where idreclamo = p_id;
   end if;

   close v_Cursor;

   p_ok := 1;
   return;

exception when others then
   GrabarLog(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM ||' suc: '||p_servidor||' id: '||p_id);
end TraerReclamoPosnet;

/**************************************************************************************************
* Replica la tabla tblreclamoposnetdet
* %v 20/04/2017 - JBodnar
***************************************************************************************************/
procedure TraerReclamoPosnetDet (p_servidor in  sucursales.servidor%type,
                              p_cdAccion in  varchar2,
                              p_id       in  varchar2,
                              p_ok       out integer )
is
   v_modulo           varchar2(100) := 'PKG_REPLICA_SUC.TraerReclamoPosnetDet';
   v_SQL              varchar2(4000);
   v_Cursor           cur_typ;
   v_Registro         tblreclamoposnetdet%rowtype;

begin
   p_ok := 0;

   --Buscar los datos en la sucursal
   v_SQL := 'select * from tblreclamoposnetdet@' || p_servidor || ' where idreclamodet =''' || p_id ||'''';
   open v_Cursor for v_SQL;
   fetch v_Cursor into v_Registro;

   --Hacer insert o update en AC
   if p_cdAccion = REPLICAS_GENERAL.GET_ACCION_INSERT then
      insert into tblreclamoposnetdet values v_Registro;
   elsif p_cdAccion = REPLICAS_GENERAL.GET_ACCION_UPDATE then
      update tblreclamoposnetdet set row = v_Registro where idreclamodet = p_id;
   end if;

   close v_Cursor;

   p_ok := 1;
   return;

exception when others then
   GrabarLog(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM ||' suc: '||p_servidor||' id: '||p_id);
end TraerReclamoPosnetDet;

/**************************************************************************************************
* Replica la tabla tblreclamoobservacion
* %v 20/04/2017 - JBodnar
***************************************************************************************************/
procedure TraerReclamoObservacion (p_servidor in  sucursales.servidor%type,
                              p_cdAccion in  varchar2,
                              p_id       in  varchar2,
                              p_ok       out integer )
is
   v_modulo           varchar2(100) := 'PKG_REPLICA_SUC.TraerReclamoObservacion';
   v_SQL              varchar2(4000);
   v_Cursor           cur_typ;
   v_Registro         tblreclamoobservacion %rowtype;

begin
   p_ok := 0;

   --Buscar los datos en la sucursal
   v_SQL := 'select * from tblreclamoobservacion@' || p_servidor || ' where idobservacion =''' || p_id ||'''';
   open v_Cursor for v_SQL;
   fetch v_Cursor into v_Registro;

   --Hacer insert o update en AC
   if p_cdAccion = REPLICAS_GENERAL.GET_ACCION_INSERT then
      insert into tblreclamoobservacion values v_Registro;
   elsif p_cdAccion = REPLICAS_GENERAL.GET_ACCION_UPDATE then
      update tblreclamoobservacion set row = v_Registro where idobservacion = p_id;
   end if;

   close v_Cursor;

   p_ok := 1;
   return;

exception when others then
   GrabarLog(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM ||' suc: '||p_servidor||' id: '||p_id);
end TraerReclamoObservacion;

/**************************************************************************************************
* Replica la tabla tblentidadaplicacion
* %v 23/08/2017 - JBodnar
* %v 05/04/2018 - JBodnar: Replica a todas menos a CC
***************************************************************************************************/
procedure TraerEntidadAplicacion (p_servidor in  sucursales.servidor%type,
                                  p_cdAccion in  varchar2,
                                  p_id       in  varchar2,
                                  p_ok       out integer )
is
   v_modulo           varchar2(100) := 'PKG_REPLICA_SUC.TraerEntidadAplicacion';
   v_SQL              varchar2(4000);
   v_Cursor           cur_typ;
   v_Registro         tblentidadaplicacion%rowtype;

begin
   p_ok := 0;

   --Buscar los datos en la sucursal
   v_SQL := 'select * from tblentidadaplicacion@' || p_servidor || ' where identidadaplicacion =''' || p_id ||'''';
   open v_Cursor for v_SQL;
   fetch v_Cursor into v_Registro;

   --Hacer insert o update en AC
   if p_cdAccion = REPLICAS_GENERAL.GET_ACCION_INSERT then
      insert into tblentidadaplicacion values v_Registro;
   elsif p_cdAccion = REPLICAS_GENERAL.GET_ACCION_UPDATE then
      update tblentidadaplicacion set row = v_Registro where identidadaplicacion = p_id;
   end if;

  --Agendar la réplica hacia el resto de las sucursales menos a CC
   ReplicarTodasSucursales(p_servidor, 'tblentidadaplicacion', p_cdAccion, p_id, null, '9998    ');

   close v_Cursor;

   p_ok := 1;
   return;

exception when others then
   GrabarLog(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM ||' suc: '||p_servidor||' id: '||p_id);
end TraerEntidadAplicacion;

/**************************************************************************************************
* Replica la tabla tblcnpresupuesto
* %v 12/07/2017 - JBodnar
***************************************************************************************************/
procedure TraerCNpresupuesto (p_servidor in  sucursales.servidor%type,
                              p_cdAccion in  varchar2,
                              p_id       in  varchar2,
                              p_ok       out integer )
is
   v_modulo           varchar2(100) := 'PKG_REPLICA_SUC.TraerCNpresupuesto';
   v_SQL              varchar2(4000);
   v_Cursor           cur_typ;
   v_Registro         tblcnpresupuesto %rowtype;

begin
   p_ok := 0;

   --Buscar los datos en la sucursal
   v_SQL := 'select * from tblcnpresupuesto@' || p_servidor || ' where idcnpresupuesto =''' || p_id ||'''';
   open v_Cursor for v_SQL;
   fetch v_Cursor into v_Registro;

   --Hacer insert o update en AC
   if p_cdAccion = REPLICAS_GENERAL.GET_ACCION_INSERT then
      insert into tblcnpresupuesto values v_Registro;
   elsif p_cdAccion = REPLICAS_GENERAL.GET_ACCION_UPDATE then
      update tblcnpresupuesto set row = v_Registro where idcnpresupuesto = p_id;
   end if;

   close v_Cursor;

   p_ok := 1;
   return;

exception when others then
   GrabarLog(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM ||' suc: '||p_servidor||' id: '||p_id);
end TraerCNpresupuesto;

/**************************************************************************************************
* Replica la tabla tblcnpresupuestopedido
* %v 12/07/2017 - JBodnar
***************************************************************************************************/
procedure TraerCNpresupuestopedido (p_servidor in  sucursales.servidor%type,
                              p_cdAccion in  varchar2,
                              p_id       in  varchar2,
                              p_ok       out integer )
is
   v_modulo           varchar2(100) := 'PKG_REPLICA_SUC.TraerCNpresupuestopedido';
   v_SQL              varchar2(4000);
   v_Cursor           cur_typ;
   v_Registro         tblcnpresupuestopedido %rowtype;

begin
   p_ok := 0;

   --Buscar los datos en la sucursal
   v_SQL := 'select * from tblcnpresupuestopedido@' || p_servidor || ' where idcnpresupuestopedido =''' || p_id ||'''';
   open v_Cursor for v_SQL;
   fetch v_Cursor into v_Registro;

   --Hacer insert o update en AC
   if p_cdAccion = REPLICAS_GENERAL.GET_ACCION_INSERT then
      insert into tblcnpresupuestopedido values v_Registro;
   elsif p_cdAccion = REPLICAS_GENERAL.GET_ACCION_UPDATE then
      update tblcnpresupuestopedido set row = v_Registro where idcnpresupuestopedido = p_id;
   end if;

   close v_Cursor;

   p_ok := 1;
   return;

exception when others then
   GrabarLog(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM ||' suc: '||p_servidor||' id: '||p_id);
end TraerCNpresupuestopedido;

/**************************************************************************************************
* Replica la tabla tblcnpedido
* %v 12/07/2017 - JBodnar
***************************************************************************************************/
procedure TraerCNpedido (p_servidor in  sucursales.servidor%type,
                              p_cdAccion in  varchar2,
                              p_id       in  varchar2,
                              p_ok       out integer )
is
   v_modulo           varchar2(100) := 'PKG_REPLICA_SUC.TraerCNpedido';
   v_SQL              varchar2(4000);
   v_Cursor           cur_typ;
   v_Registro         tblcnpedido %rowtype;

begin
   p_ok := 0;

   --Buscar los datos en la sucursal
   v_SQL := 'select * from tblcnpedido@' || p_servidor || ' where idcnpedido =''' || p_id ||'''';
   open v_Cursor for v_SQL;
   fetch v_Cursor into v_Registro;

   --Hacer insert o update en AC
   if p_cdAccion = REPLICAS_GENERAL.GET_ACCION_INSERT then
      insert into tblcnpedido values v_Registro;
   elsif p_cdAccion = REPLICAS_GENERAL.GET_ACCION_UPDATE then
      update tblcnpedido set row = v_Registro where idcnpedido = p_id;
   end if;

   close v_Cursor;

   p_ok := 1;
   return;

exception when others then
   GrabarLog(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM ||' suc: '||p_servidor||' id: '||p_id);
end TraerCNpedido;

/**************************************************************************************************
* Replica la tabla tblcnfactura
* %v 12/07/2017 - JBodnar
***************************************************************************************************/
procedure TraerCNfactura (p_servidor in  sucursales.servidor%type,
                              p_cdAccion in  varchar2,
                              p_id       in  varchar2,
                              p_ok       out integer )
is
   v_modulo           varchar2(100) := 'PKG_REPLICA_SUC.TraerCNfactura';
   v_SQL              varchar2(4000);
   v_Cursor           cur_typ;
   v_Registro         tblcnfactura%rowtype;

begin
   p_ok := 0;

   --Buscar los datos en la sucursal
   v_SQL := 'select * from tblcnfactura@' || p_servidor || ' where idcnfactura =''' || p_id ||'''';
   open v_Cursor for v_SQL;
   fetch v_Cursor into v_Registro;

   --Hacer insert o update en AC
   if p_cdAccion = REPLICAS_GENERAL.GET_ACCION_INSERT then
      insert into tblcnfactura values v_Registro;
   elsif p_cdAccion = REPLICAS_GENERAL.GET_ACCION_UPDATE then
      update tblcnfactura set row = v_Registro where idcnfactura = p_id;
   end if;

   close v_Cursor;

   p_ok := 1;
   return;

exception when others then
   GrabarLog(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM ||' suc: '||p_servidor||' id: '||p_id);
end TraerCNfactura;

/**************************************************************************************************
* Replica la tabla tblliberacioncuenta
* %v 01/03/2018 - JBodnar
***************************************************************************************************/
procedure TraerLiberacionCuenta(p_servidor in  sucursales.servidor%type,
                                p_cdAccion in  varchar2,
                                p_id       in  varchar2,
                                p_ok       out integer )
is
   v_modulo           varchar2(100) := 'PKG_REPLICA_SUC.TraerLiberacionCuenta';
   v_SQL              varchar2(4000);
   v_Cursor           cur_typ;
   v_Registro         tblliberacioncuenta%rowtype;

begin
   p_ok := 0;

   --Buscar los datos en la sucursal
   v_SQL := 'select * from tblliberacioncuenta@' || p_servidor || ' where idliberacion=''' || p_id ||'''';
   open v_Cursor for v_SQL;
   fetch v_Cursor into v_Registro;

   --Hacer insert o update en AC
   if p_cdAccion = REPLICAS_GENERAL.GET_ACCION_INSERT then
      insert into tblliberacioncuenta values v_Registro;
   elsif p_cdAccion = REPLICAS_GENERAL.GET_ACCION_UPDATE then
      update tblliberacioncuenta set row = v_Registro where idliberacion = p_id;
   end if;

   close v_Cursor;

   p_ok := 1;
   return;

exception when others then
   GrabarLog(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM ||' suc: '||p_servidor||' id: '||p_id);
end TraerLiberacionCuenta;

/**************************************************************************************************
* Replica la tabla tblAnticipoClienteAux
* %v 12/03/2018 - JBodnar
***************************************************************************************************/
procedure TraerAnticipoClienteAux(p_servidor in  sucursales.servidor%type,
                                  p_cdAccion in  varchar2,
                                  p_id       in  varchar2,
                                  p_ok       out integer )
is
   v_modulo           varchar2(100) := 'PKG_REPLICA_SUC.TraerAnticipoClienteAux';
   v_SQL              varchar2(4000);
   v_Cursor           cur_typ;
   v_Registro         tblanticipoclienteaux%rowtype;

begin
   p_ok := 0;

   --Buscar los datos en la sucursal
   v_SQL := 'select * from tblanticipoclienteaux@' || p_servidor || ' where idanticipo=''' || p_id ||'''';
   open v_Cursor for v_SQL;
   fetch v_Cursor into v_Registro;

   --Hacer insert o update en AC
   if p_cdAccion = REPLICAS_GENERAL.GET_ACCION_INSERT then
      insert into tblanticipoclienteaux values v_Registro;
   elsif p_cdAccion = REPLICAS_GENERAL.GET_ACCION_UPDATE then
      update tblanticipoclienteaux set row = v_Registro where idanticipo = p_id;
   end if;

   close v_Cursor;

   p_ok := 1;
   return;

exception when others then
   GrabarLog(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM ||' suc: '||p_servidor||' id: '||p_id);
end TraerAnticipoClienteAux;

/**************************************************************************************************
* Replica la tabla tblslv_consolidado
* %v 18/09/2018 - JBodnar
* %v 04/02/2019 - APW - Agrego sucursal en update para des-duplicar
***************************************************************************************************/
procedure TraerConsolidado(p_servidor in  sucursales.servidor%type,
                                  p_cdAccion in  varchar2,
                                  p_id       in  varchar2,
                                  p_ok       out integer )
is
   v_modulo           varchar2(100) := 'PKG_REPLICA_SUC.TraerConsolidado';
   v_SQL              varchar2(4000);
   v_Cursor           cur_typ;
   v_Registro         tblslv_consolidado%rowtype;

begin
   p_ok := 0;

   --Buscar los datos en la sucursal
   v_SQL := 'select * from tblslv_consolidado@' || p_servidor || ' where IDCONSOLIDADO=''' || p_id ||'''';
   open v_Cursor for v_SQL;
   fetch v_Cursor into v_Registro;

   --Hacer insert o update en AC
   if p_cdAccion = REPLICAS_GENERAL.GET_ACCION_INSERT then
      insert into tblslv_consolidado values v_Registro;
   elsif p_cdAccion = REPLICAS_GENERAL.GET_ACCION_UPDATE then
      update tblslv_consolidado
      set row = v_Registro
      where IDCONSOLIDADO = p_id
      and cdsucursal = v_Registro.Cdsucursal;
   end if;

   close v_Cursor;

   p_ok := 1;
   return;

exception when others then
   GrabarLog(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM ||' suc: '||p_servidor||' id: '||p_id);
end TraerConsolidado;




/**************************************************************************************************
* Replica la tabla tblslv_consolidado_pedido de SLVAPP
* %v 18/09/2018 - JBodnar
* %v 04/02/2019 - APW - Agrego sucursal para des-duplicar
***************************************************************************************************/
procedure TraerConsolidado_pedido(p_servidor in  sucursales.servidor%type,
                                  p_cdAccion in  varchar2,
                                  p_id       in  varchar2,
                                  p_ok       out integer )
is
   v_modulo           varchar2(100) := 'PKG_REPLICA_SUC.TraerConsolidado_pedido';
   v_SQL              varchar2(4000);
   v_Cursor           cur_typ;
   v_Registro         tblslv_consolidado_pedido%rowtype;

begin
   p_ok := 0;

   --Buscar los datos en la sucursal
   v_SQL := 'select cp.*, s.cdsucursal from tblslv_consolidado_pedido@' || p_servidor || ' cp, sucursales s where IDCONSOLIDADO_PEDIDO=''' || p_id ||''' and s.servidor = '''||p_servidor||'''';
   open v_Cursor for v_SQL;
   fetch v_Cursor into v_Registro;

   --Hacer insert o update en AC
   if p_cdAccion = REPLICAS_GENERAL.GET_ACCION_INSERT then
      insert into tblslv_consolidado_pedido values v_Registro;
   elsif p_cdAccion = REPLICAS_GENERAL.GET_ACCION_UPDATE then
      update tblslv_consolidado_pedido
        set row = v_Registro
        where IDCONSOLIDADO_PEDIDO = p_id
        and cdsucursal = v_Registro.Cdsucursal;
   end if;

   close v_Cursor;

   p_ok := 1;
   return;

exception when others then
   GrabarLog(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM ||' suc: '||p_servidor||' id: '||p_id);
end TraerConsolidado_pedido;



/**************************************************************************************************
* Replica la tabla tblslv_consolidado_pedido_rel
* %v 24/10/2018 - JBodnar
* %v 04/02/2019 - APW - Agrego sucursal para des-duplicar
***************************************************************************************************/
procedure TraerConsolidado_pedido_rel(p_servidor in  sucursales.servidor%type,
                                  p_cdAccion in  varchar2,
                                  p_id       in  varchar2,
                                  p_ok       out integer )
is
   v_modulo           varchar2(100) := 'PKG_REPLICA_SUC.TraerConsolidado_pedido_rel';
   v_SQL              varchar2(4000);
   v_Cursor           cur_typ;
   v_Registro         tblslv_consolidado_pedido_rel%rowtype;

begin
   p_ok := 0;

   --Buscar los datos en la sucursal
   v_SQL := 'select cpr.*, s.cdsucursal from tblslv_consolidado_pedido_rel@' || p_servidor || ' cpr, sucursales s where IDCONSOLIDADOPEDREL=''' || p_id ||''' and s.servidor = '''||p_servidor||'''';
   open v_Cursor for v_SQL;
   fetch v_Cursor into v_Registro;

   --Hacer insert o update en AC
   if p_cdAccion = REPLICAS_GENERAL.GET_ACCION_INSERT then
      insert into tblslv_consolidado_pedido_rel values v_Registro;
   elsif p_cdAccion = REPLICAS_GENERAL.GET_ACCION_UPDATE then
      update tblslv_consolidado_pedido_rel
         set row = v_Registro
         where IDCONSOLIDADOPEDREL = p_id
         and cdsucursal = v_Registro.Cdsucursal;
   end if;

   close v_Cursor;

   p_ok := 1;
   return;

exception when others then
   GrabarLog(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM ||' suc: '||p_servidor||' id: '||p_id);
end TraerConsolidado_pedido_rel;

/**************************************************************************************************
* Replica la tabla tblslvconsolidadom (SLVM)
* %v 29/08/2020 - APW 
***************************************************************************************************/
procedure TraerConsolidadoM(p_servidor in  sucursales.servidor%type,
                            p_cdAccion in  varchar2,
                            p_id       in  varchar2,
                            p_ok       out integer )
is
   v_modulo           varchar2(100) := 'PKG_REPLICA_SUC.TraerConsolidadoM';
   v_SQL              varchar2(4000);
   v_Cursor           cur_typ;
   v_Registro         tblslvconsolidadom%rowtype;

begin
   p_ok := 0;

   --Buscar los datos en la sucursal
   v_SQL := 'select * from tblslvconsolidadom@' || p_servidor || ' where IDCONSOLIDADOM=''' || p_id ||'''';
   open v_Cursor for v_SQL;
   fetch v_Cursor into v_Registro;

   --Hacer insert o update en AC
   if p_cdAccion = REPLICAS_GENERAL.GET_ACCION_INSERT then
      insert into tblslvconsolidadom values v_Registro;
   elsif p_cdAccion = REPLICAS_GENERAL.GET_ACCION_UPDATE then
      update tblslvconsolidadom
      set row = v_Registro
      where IDCONSOLIDADOM = p_id
      and cdsucursal = v_Registro.Cdsucursal;
   end if;

   close v_Cursor;

   p_ok := 1;
   return;

exception when others then
   GrabarLog(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM ||' suc: '||p_servidor||' id: '||p_id);
end TraerConsolidadoM;

/**************************************************************************************************
* Replica la tabla tblslvconsolidadomdet (SLVM)
* %v 07/09/2020 - APW 
***************************************************************************************************/
procedure TraerConsolidadoDetM(p_servidor in  sucursales.servidor%type,
                            p_cdAccion in  varchar2,
                            p_id       in  varchar2,
                            p_ok       out integer )
is
   v_modulo           varchar2(100) := 'PKG_REPLICA_SUC.TraerConsolidadetM';
   v_SQL              varchar2(4000);
   v_Cursor           cur_typ;
   v_Registro         tblslvconsolidadomdet%rowtype;

begin
   p_ok := 0;

   --Buscar los datos en la sucursal
   v_SQL := 'select * from tblslvconsolidadomdet@' || p_servidor || ' where IDCONSOLIDADOMDET=''' || p_id ||'''';
   open v_Cursor for v_SQL;
   fetch v_Cursor into v_Registro;

   --Hacer insert o update en AC
   if p_cdAccion = REPLICAS_GENERAL.GET_ACCION_INSERT then
      insert into tblslvconsolidadomdet values v_Registro;
   elsif p_cdAccion = REPLICAS_GENERAL.GET_ACCION_UPDATE then
      update tblslvconsolidadomdet
      set row = v_Registro
      where IDCONSOLIDADOMDET = p_id
      and cdsucursal = v_Registro.Cdsucursal;
   end if;

   close v_Cursor;

   p_ok := 1;
   return;

exception when others then
   GrabarLog(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM ||' suc: '||p_servidor||' id: '||p_id);
end TraerConsolidadoDetM;

/**************************************************************************************************
* Replica la tabla tblslvconsolidadopedido (SLVM)
* %v 29/08/2020 - APW 
***************************************************************************************************/
procedure TraerConsolidadoPedidoM(p_servidor in  sucursales.servidor%type,
                                  p_cdAccion in  varchar2,
                                  p_id       in  varchar2,
                                  p_ok       out integer )
is
   v_modulo           varchar2(100) := 'PKG_REPLICA_SUC.TraerConsolidadoPedidoM';
   v_SQL              varchar2(4000);
   v_Cursor           cur_typ;
   v_Registro         tblslvconsolidadopedido%rowtype;

begin
   p_ok := 0;

   --Buscar los datos en la sucursal
   v_SQL := 'select cp.* from tblslvconsolidadopedido@' || p_servidor || ' cp where IDCONSOLIDADOPEDIDO=''' || p_id ||'''';
   open v_Cursor for v_SQL;
   fetch v_Cursor into v_Registro;

   --Hacer insert o update en AC
   if p_cdAccion = REPLICAS_GENERAL.GET_ACCION_INSERT then
      insert into tblslvconsolidadopedido values v_Registro;
   elsif p_cdAccion = REPLICAS_GENERAL.GET_ACCION_UPDATE then
      update tblslvconsolidadopedido
        set row = v_Registro
        where IDCONSOLIDADOPEDIDO = p_id
        and cdsucursal = v_Registro.Cdsucursal;
   end if;

   close v_Cursor;

   p_ok := 1;
   return;

exception when others then
   GrabarLog(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM ||' suc: '||p_servidor||' id: '||p_id);
end TraerConsolidadoPedidoM;

/**************************************************************************************************
* Replica la tabla tblslvconsolidadopedidorel (SLVM)
* %v 29/08/2020 - APW 
***************************************************************************************************/
procedure TraerConsolidadoPedidoRelM(p_servidor in  sucursales.servidor%type,
                                     p_cdAccion in  varchar2,
                                     p_id       in  varchar2,
                                     p_ok       out integer )
is
   v_modulo           varchar2(100) := 'PKG_REPLICA_SUC.TraerConsolidadoPedidoRelM';
   v_SQL              varchar2(4000);
   v_Cursor           cur_typ;
   v_Registro         tblslvconsolidadopedidorel%rowtype;

begin
   p_ok := 0;

   --Buscar los datos en la sucursal
   v_SQL := 'select cp.* from tblslvconsolidadopedidorel@' || p_servidor || ' cp where IDCONSOLIDADOPEDIDOREL=''' || p_id ||'''';
   open v_Cursor for v_SQL;
   fetch v_Cursor into v_Registro;

   --Hacer insert o update en AC
   if p_cdAccion = REPLICAS_GENERAL.GET_ACCION_INSERT then
      insert into tblslvconsolidadopedidorel values v_Registro;
   elsif p_cdAccion = REPLICAS_GENERAL.GET_ACCION_UPDATE then
      update tblslvconsolidadopedidorel
        set row = v_Registro
        where IDCONSOLIDADOPEDIDOREL = p_id
        and cdsucursal = v_Registro.Cdsucursal;
   end if;

   close v_Cursor;

   p_ok := 1;
   return;

exception when others then
   GrabarLog(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM ||' suc: '||p_servidor||' id: '||p_id);
end TraerConsolidadoPedidoRelM;

/**************************************************************************************************
* Replica la tabla tblslvremito (SLVM)
* %v 07/09/2020 - APW 
***************************************************************************************************/
procedure TraerRemitoM(p_servidor in  sucursales.servidor%type,
                                     p_cdAccion in  varchar2,
                                     p_id       in  varchar2,
                                     p_ok       out integer )
is
   v_modulo           varchar2(100) := 'PKG_REPLICA_SUC.TraerRemitoM';
   v_SQL              varchar2(4000);
   v_Cursor           cur_typ;
   v_Registro         tblslvremito%rowtype;

begin
   p_ok := 0;

   --Buscar los datos en la sucursal
   v_SQL := 'select cp.* from tblslvremito@' || p_servidor || ' cp where IDREMITO=''' || p_id ||'''';
   open v_Cursor for v_SQL;
   fetch v_Cursor into v_Registro;

   --Hacer insert o update en AC
   if p_cdAccion = REPLICAS_GENERAL.GET_ACCION_INSERT then
      insert into tblslvremito values v_Registro;
   elsif p_cdAccion = REPLICAS_GENERAL.GET_ACCION_UPDATE then
      update tblslvremito
        set row = v_Registro
        where IDREMITO = p_id
        and cdsucursal = v_Registro.Cdsucursal;
   end if;

   close v_Cursor;

   p_ok := 1;
   return;

exception when others then
   GrabarLog(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM ||' suc: '||p_servidor||' id: '||p_id);
end TraerRemitoM;

/**************************************************************************************************
* Replica la tabla tblslvcontrolvremito (SLVM)
* %v 07/09/2020 - APW 
***************************************************************************************************/
procedure TraerControlRemitoM(p_servidor in  sucursales.servidor%type,
                                     p_cdAccion in  varchar2,
                                     p_id       in  varchar2,
                                     p_ok       out integer )
is
   v_modulo           varchar2(100) := 'PKG_REPLICA_SUC.TraerControlRemitoM';
   v_SQL              varchar2(4000);
   v_Cursor           cur_typ;
   v_Registro         tblslvcontrolremito%rowtype;

begin
   p_ok := 0;

   --Buscar los datos en la sucursal
   v_SQL := 'select cp.* from tblslvcontrolremito@' || p_servidor || ' cp where IDCONTROLREMITO=''' || p_id ||'''';
   open v_Cursor for v_SQL;
   fetch v_Cursor into v_Registro;

   --Hacer insert o update en AC
   if p_cdAccion = REPLICAS_GENERAL.GET_ACCION_INSERT then
      insert into tblslvcontrolremito values v_Registro;
   elsif p_cdAccion = REPLICAS_GENERAL.GET_ACCION_UPDATE then
      update tblslvcontrolremito
        set row = v_Registro
        where IDCONTROLREMITO = p_id
        and cdsucursal = v_Registro.Cdsucursal;
   end if;

   close v_Cursor;

   p_ok := 1;
   return;

exception when others then
   GrabarLog(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM ||' suc: '||p_servidor||' id: '||p_id);
end TraerControlRemitoM;


/**************************************************************************************************
* Replica la tabla tblslvcontrolremitodet (SLVM)
* %v 07/09/2020 - APW 
***************************************************************************************************/
procedure TraerControlRemitoDetM(p_servidor in  sucursales.servidor%type,
                                     p_cdAccion in  varchar2,
                                     p_id       in  varchar2,
                                     p_ok       out integer )
is
   v_modulo           varchar2(100) := 'PKG_REPLICA_SUC.TraerControlRemitoDetM';
   v_SQL              varchar2(4000);
   v_Cursor           cur_typ;
   v_Registro         tblslvcontrolremitodet%rowtype;

begin
   p_ok := 0;

   --Buscar los datos en la sucursal
   v_SQL := 'select cp.* from tblslvcontrolremitodet@' || p_servidor || ' cp where IDCONTROLREMITODET=''' || p_id ||'''';
   open v_Cursor for v_SQL;
   fetch v_Cursor into v_Registro;

   --Hacer insert o update en AC
   if p_cdAccion = REPLICAS_GENERAL.GET_ACCION_INSERT then
      insert into tblslvcontrolremitodet values v_Registro;
   elsif p_cdAccion = REPLICAS_GENERAL.GET_ACCION_UPDATE then
      update tblslvcontrolremitodet
        set row = v_Registro
        where IDCONTROLREMITODET = p_id
        and cdsucursal = v_Registro.Cdsucursal;
   end if;

   close v_Cursor;

   p_ok := 1;
   return;

exception when others then
   GrabarLog(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM ||' suc: '||p_servidor||' id: '||p_id);
end TraerControlRemitoDetM;


/**************************************************************************************************
* Replica la tabla tblslvtarea (SLVM)
* %v 07/09/2020 - APW 
***************************************************************************************************/
procedure TraerTareaM(p_servidor in  sucursales.servidor%type,
                                     p_cdAccion in  varchar2,
                                     p_id       in  varchar2,
                                     p_ok       out integer )
is
   v_modulo           varchar2(100) := 'PKG_REPLICA_SUC.TraerTareaM';
   v_SQL              varchar2(4000);
   v_Cursor           cur_typ;
   v_Registro         tblslvtarea%rowtype;

begin
   p_ok := 0;

   --Buscar los datos en la sucursal
   v_SQL := 'select cp.* from tblslvtarea@' || p_servidor || ' cp where IDTAREA=''' || p_id ||'''';
   open v_Cursor for v_SQL;
   fetch v_Cursor into v_Registro;

   --Hacer insert o update en AC
   if p_cdAccion = REPLICAS_GENERAL.GET_ACCION_INSERT then
      insert into tblslvtarea values v_Registro;
   elsif p_cdAccion = REPLICAS_GENERAL.GET_ACCION_UPDATE then
      update tblslvtarea
        set row = v_Registro
        where IDTAREA = p_id
        and cdsucursal = v_Registro.Cdsucursal;
   end if;

   close v_Cursor;

   p_ok := 1;
   return;

exception when others then
   GrabarLog(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM ||' suc: '||p_servidor||' id: '||p_id);
end TraerTareaM;


/**************************************************************************************************
* Replica la tabla tblslvtareadet (SLVM)
* %v 07/09/2020 - APW 
***************************************************************************************************/
procedure TraerTareaDetM(p_servidor in  sucursales.servidor%type,
                                     p_cdAccion in  varchar2,
                                     p_id       in  varchar2,
                                     p_ok       out integer )
is
   v_modulo           varchar2(100) := 'PKG_REPLICA_SUC.TraerTareaDetM';
   v_SQL              varchar2(4000);
   v_Cursor           cur_typ;
   v_Registro         tblslvtareadet%rowtype;

begin
   p_ok := 0;

   --Buscar los datos en la sucursal
   v_SQL := 'select cp.* from tblslvtareadet@' || p_servidor || ' cp where IDTAREADET=''' || p_id ||'''';
   open v_Cursor for v_SQL;
   fetch v_Cursor into v_Registro;

   --Hacer insert o update en AC
   if p_cdAccion = REPLICAS_GENERAL.GET_ACCION_INSERT then
      insert into tblslvtareadet values v_Registro;
   elsif p_cdAccion = REPLICAS_GENERAL.GET_ACCION_UPDATE then
      update tblslvtareadet
        set row = v_Registro
        where IDTAREADET = p_id
        and cdsucursal = v_Registro.Cdsucursal;
   end if;

   close v_Cursor;

   p_ok := 1;
   return;

exception when others then
   GrabarLog(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM ||' suc: '||p_servidor||' id: '||p_id);
end TraerTareaDetM;


/**************************************************************************************************
* Replica la tabla tblslvpedfaltanterel (SLVM)
* %v 07/09/2020 - APW 
***************************************************************************************************/
procedure TraerPedFaltanteRelM(p_servidor in  sucursales.servidor%type,
                                     p_cdAccion in  varchar2,
                                     p_id       in  varchar2,
                                     p_ok       out integer )
is
   v_modulo           varchar2(100) := 'PKG_REPLICA_SUC.TraerTareaDetM';
   v_SQL              varchar2(4000);
   v_Cursor           cur_typ;
   v_Registro         tblslvpedfaltanterel%rowtype;

begin
   p_ok := 0;

   --Buscar los datos en la sucursal
   v_SQL := 'select cp.* from tblslvpedfaltanterel@' || p_servidor || ' cp where IDPEDFALTANTEREL=''' || p_id ||'''';
   open v_Cursor for v_SQL;
   fetch v_Cursor into v_Registro;

   --Hacer insert o update en AC
   if p_cdAccion = REPLICAS_GENERAL.GET_ACCION_INSERT then
      insert into tblslvpedfaltanterel values v_Registro;
   elsif p_cdAccion = REPLICAS_GENERAL.GET_ACCION_UPDATE then
      update tblslvpedfaltanterel
        set row = v_Registro
        where IDPEDFALTANTEREL = p_id
        and cdsucursal = v_Registro.Cdsucursal;
   end if;

   close v_Cursor;

   p_ok := 1;
   return;

exception when others then
   GrabarLog(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM ||' suc: '||p_servidor||' id: '||p_id);
end TraerPedFaltanteRelM;
/**************************************************************************************************
* Replica la tabla detallemovmateriales
* %v 19/02/2019 - JBodnar
* %v 20/08/2010 - cdickson_c se modifica para traer solo por update
***************************************************************************************************/
procedure TraerDetallemovmateriales (p_servidor in  sucursales.servidor%type,
                                  p_cdAccion in  varchar2,
                                  p_id       in  varchar2,
                                  p_idCompuesto in  varchar2,
                                  p_ok       out integer )
is
   v_modulo           varchar2(100) := 'PKG_REPLICA_SUC.TraerDetallemovmateriales';
   v_SQL              varchar2(4000);
   v_Cursor           cur_typ;
   v_idmovmateriales  detallemovmateriales.idmovmateriales%type;
   v_sqdetalle        detallemovmateriales.sqdetallemovmateriales%type;
   v_Registro         detallemovmateriales%rowtype;

begin
   p_ok := 0;

   --Decodificar el id compuesto en cada campo
   v_idmovmateriales := GetIdPorPosicion(p_idCompuesto,1);
   v_sqdetalle       := GetIdPorPosicion(p_idCompuesto,2);

   --Buscar los datos en la sucursal
   v_SQL := 'select * from detallemovmateriales@' || p_servidor || '  s where IDMOVMATERIALES=''' || v_idmovmateriales ||''' and sqdetallemovmateriales=''' ||v_sqdetalle||'''';
   open v_Cursor for v_SQL;
   fetch v_Cursor into v_Registro;

   --Hacer insert o update en AC
   if /*p_cdAccion = REPLICAS_GENERAL.GET_ACCION_INSERT then
      insert into detallemovmateriales values v_Registro;
   elsif*/ p_cdAccion = REPLICAS_GENERAL.GET_ACCION_UPDATE then
      update detallemovmateriales
         set row = v_Registro
         where IDMOVMATERIALES = v_idmovmateriales and sqdetallemovmateriales = v_sqdetalle;
   end if;

   p_ok := 1;
   return;

exception when others then
   GrabarLog(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM ||' suc: '||p_servidor||' id: '||p_id);
end TraerDetallemovmateriales;

/**************************************************************************************************
* Replica la tabla tblslv_remito
* %v 19/02/2019 - Iaquilano
* %v 19/09/2019 - IAquilano: Agrego sucursal a la tabla.
***************************************************************************************************/
procedure TraerRemitoSLV(p_servidor in  sucursales.servidor%type,
                                  p_cdAccion in  varchar2,
                                  p_id       in  varchar2,
                                  p_ok       out integer )
is
   v_modulo           varchar2(100) := 'PKG_REPLICA_SUC.TraerRemitoSLV';
   v_SQL              varchar2(4000);
   v_Cursor           cur_typ;
   v_Registro         tblslv_remito%rowtype;

begin
   p_ok := 0;

   --Buscar los datos en la sucursal
   v_SQL := 'select cpr.*, s.cdsucursal from tblslv_remito@' || p_servidor || ' cpr, sucursales s where IDREMITO=''' || p_id||''' and s.servidor = '''||p_servidor||'''';
   open v_Cursor for v_SQL;
   fetch v_Cursor into v_Registro;

   --Hacer insert o update en AC
   if p_cdAccion = REPLICAS_GENERAL.GET_ACCION_INSERT then
      insert into tblslv_remito values v_Registro;
   elsif p_cdAccion = REPLICAS_GENERAL.GET_ACCION_UPDATE then
      update tblslv_remito
         set row = v_Registro
         where IDREMITO = p_id;
   end if;

   close v_Cursor;

   p_ok := 1;
   return;

exception when others then
   GrabarLog(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM ||' suc: '||p_servidor||' id: '||p_id);
end TraerRemitoSlv;
/**************************************************************************************************
* Replica la tabla tblimpdocumentodetalle
* %v 19/02/2019 - JBodnar
* %v 10/08/2020 - cdickson_c se modifica para hacer solo update
***************************************************************************************************/
procedure TraerImpDocumentoDetalle (p_servidor in  sucursales.servidor%type,
                                  p_cdAccion in  varchar2,
                                  p_id       in  varchar2,
                                  p_ok       out integer )
is
   v_modulo           varchar2(100) := 'PKG_REPLICA_SUC.TraerImpDocumentoDetalle';
   v_SQL              varchar2(4000);
   v_Cursor           cur_typ;
   v_Registro         tblimpdocumentodetalle%rowtype;

begin
   p_ok := 0;

   --Buscar los datos en la sucursal
   v_SQL := 'select * from tblimpdocumentodetalle@' || p_servidor || '  where IDIMPDOCUMENTODETALLE=''' || p_id ||'''';
   open v_Cursor for v_SQL;
   fetch v_Cursor into v_Registro;

   --Hacer insert o update en AC
   if /*p_cdAccion = REPLICAS_GENERAL.GET_ACCION_INSERT then
      insert into tblimpdocumentodetalle values v_Registro;
   elsif*/ p_cdAccion = REPLICAS_GENERAL.GET_ACCION_UPDATE then
      update tblimpdocumentodetalle
         set row = v_Registro
         where IDIMPDOCUMENTODETALLE = p_id;
   end if;

   p_ok := 1;
   return;

exception when others then
   GrabarLog(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM ||' suc: '||p_servidor||' id: '||p_id);
end TraerImpDocumentoDetalle;

/**************************************************************************************************
* Replica la tabla cierressucursal
* %v 08/03/2019 - JBodnar
***************************************************************************************************/
procedure TraerCierreSucursal (p_servidor in  sucursales.servidor%type,
                                  p_cdAccion in  varchar2,
                                  p_id       in  varchar2,
                                  p_idCompuesto in  varchar2,
                                  p_ok       out integer )
is
   v_modulo           varchar2(100) := 'PKG_REPLICA_SUC.TraerCierreSucursal';
   v_SQL              varchar2(4000);
   v_Cursor           cur_typ;
   v_cdsucursal       cierressucursal.cdsucursal%type;
   v_dtcierre         cierressucursal.dtcierre%type;
   v_Registro         cierressucursal%rowtype;

begin
   p_ok := 0;

   --Decodificar el id compuesto en cada campo
   v_cdsucursal := GetIdPorPosicion(p_idCompuesto,1);
   v_dtcierre   := to_date(GetIdPorPosicion(p_idCompuesto,2),'dd/mm/yyyy');

   --Buscar los datos en la sucursal
   v_SQL := 'select * from cierressucursal@' || p_servidor || ' where cdsucursal =''' || v_cdsucursal ||''' and DTCIERRE=''' ||v_dtcierre||'''';
   open v_Cursor for v_SQL;
   fetch v_Cursor into v_Registro;

   --Hacer insert o update en AC
   if p_cdAccion = REPLICAS_GENERAL.GET_ACCION_INSERT then
      insert into cierressucursal values v_Registro;
   elsif p_cdAccion = REPLICAS_GENERAL.GET_ACCION_UPDATE then
      update cierressucursal
         set row = v_Registro
         where cdsucursal = v_cdsucursal and DTCIERRE = v_dtcierre;
   end if;

   close v_Cursor;

   p_ok := 1;
   return;

exception when others then
   GrabarLog(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM ||' suc: '||p_servidor||' id: '||p_id);
end TraerCierreSucursal;

/**************************************************************************************************
* Replica la tabla tblentidadmercadopago
* %v 01/03/2019 - JBodnar
***************************************************************************************************/
procedure TraerEntidadMp (p_servidor in  sucursales.servidor%type,
                                  p_cdAccion in  varchar2,
                                  p_id       in  varchar2,
                                  p_ok       out integer )
is
   v_modulo           varchar2(100) := 'PKG_REPLICA_SUC.TraerEntidadMp';
   v_SQL              varchar2(4000);
   v_Cursor           cur_typ;
   v_Registro         tblentidadmercadopago%rowtype;

begin
   p_ok := 0;

   --Buscar los datos en la sucursal
   v_SQL := 'select * from tblentidadmercadopago@' || p_servidor || ' where IDENTIDADMP=''' || p_id ||'''';
   open v_Cursor for v_SQL;
   fetch v_Cursor into v_Registro;

   --Hacer insert o update en AC
   if p_cdAccion = REPLICAS_GENERAL.GET_ACCION_INSERT then
      insert into tblentidadmercadopago values v_Registro;
   elsif p_cdAccion = REPLICAS_GENERAL.GET_ACCION_UPDATE then
      update tblentidadmercadopago
         set row = v_Registro
         where IDENTIDADMP = p_id;
   end if;

   close v_Cursor;

   p_ok := 1;
   return;

exception when others then
   GrabarLog(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM ||' suc: '||p_servidor||' id: '||p_id);
end TraerEntidadMp;


/**************************************************************************************************
* Replica la tabla tblcierrelotesalon
* %v 20/03/2019 - JBodnar
***************************************************************************************************/
procedure TraerCierreLoteSalon (p_servidor in  sucursales.servidor%type,
                                  p_cdAccion in  varchar2,
                                  p_id       in  varchar2,
                                  p_ok       out integer )
is
   v_modulo           varchar2(100) := 'PKG_REPLICA_SUC.TraerCierreLoteSalon';
   v_SQL              varchar2(4000);
   v_Cursor           cur_typ;
   v_Registro         tblcierrelotesalon%rowtype;

begin
   p_ok := 0;

   --Buscar los datos en la sucursal
   v_SQL := 'select * from tblcierrelotesalon@' || p_servidor || ' where IDCIERRELOTESALON=''' || p_id ||'''';
   open v_Cursor for v_SQL;
   fetch v_Cursor into v_Registro;

   --Hacer insert o update en AC
   if p_cdAccion = REPLICAS_GENERAL.GET_ACCION_INSERT then
      insert into tblcierrelotesalon values v_Registro;
   elsif p_cdAccion = REPLICAS_GENERAL.GET_ACCION_UPDATE then
      update tblcierrelotesalon
         set row = v_Registro
         where IDCIERRELOTESALON = p_id;
   end if;

   close v_Cursor;

   p_ok := 1;
   return;

exception when others then
   GrabarLog(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM ||' suc: '||p_servidor||' id: '||p_id);
end TraerCierreLoteSalon;

/**************************************************************************************************
* Replica la tabla tblclsube
* %v 27/06/2019 - JBodnar
***************************************************************************************************/
procedure TraerSube (p_servidor in  sucursales.servidor%type,
                                  p_cdAccion in  varchar2,
                                  p_id       in  varchar2,
                                  p_ok       out integer )
is
   v_modulo           varchar2(100) := 'PKG_REPLICA_SUC.TraerSube';
   v_SQL              varchar2(4000);
   v_Cursor           cur_typ;
   v_Registro         tblclsube%rowtype;

begin
   p_ok := 0;

   --Buscar los datos en la sucursal
   v_SQL := 'select * from tblclsube@' || p_servidor || ' where idclsube=''' || p_id ||'''';
   open v_Cursor for v_SQL;
   fetch v_Cursor into v_Registro;

   --Hacer insert o update en AC
   if p_cdAccion = REPLICAS_GENERAL.GET_ACCION_INSERT then
      insert into tblclsube values v_Registro;
   elsif p_cdAccion = REPLICAS_GENERAL.GET_ACCION_UPDATE then
      update tblclsube
         set row = v_Registro
         where idclsube = p_id;
   end if;

   close v_Cursor;

   p_ok := 1;
   return;

exception when others then
   GrabarLog(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM ||' suc: '||p_servidor||' id: '||p_id);
end TraerSube;

/**************************************************************************************************
* Replica la tabla TblTraerDocumentocodigoAfip
* %v 25/07/2019 - JBodnar
***************************************************************************************************/
procedure TraerDocumentocodigoAfip (p_servidor in  sucursales.servidor%type,
                                  p_cdAccion in  varchar2,
                                  p_id       in  varchar2,
                                  p_ok       out integer )
is
   v_modulo           varchar2(100) := 'PKG_REPLICA_SUC.TraerDocumentocodigoAfip';
   v_SQL              varchar2(4000);
   v_Cursor           cur_typ;
   v_Registro         tbldocumentocodigoafip%rowtype;

begin
   p_ok := 0;

   --Buscar los datos en la sucursal
   v_SQL := 'select * from tbldocumentocodigoafip@' || p_servidor || ' where iddocumentocodigoafip=''' || p_id ||'''';
   open v_Cursor for v_SQL;
   fetch v_Cursor into v_Registro;

   --Hacer insert o update en AC
   if p_cdAccion = REPLICAS_GENERAL.GET_ACCION_INSERT then
      insert into tbldocumentocodigoafip values v_Registro;
   elsif p_cdAccion = REPLICAS_GENERAL.GET_ACCION_UPDATE then
      update tbldocumentocodigoafip
         set row = v_Registro
         where iddocumentocodigoafip = p_id;
   end if;

   close v_Cursor;

   p_ok := 1;
   return;

exception when others then
   GrabarLog(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM ||' suc: '||p_servidor||' id: '||p_id);
end TraerDocumentocodigoAfip;

/**************************************************************************************************
* Replica la tabla interfazmovalmacen
* %v 05/08/2019 - JBodnar
***************************************************************************************************/
procedure TraerInterfazmovalmacen (p_servidor in  sucursales.servidor%type,
                                  p_cdAccion in  varchar2,
                                  p_id       in  varchar2,
                                  p_ok       out integer )
is
   v_modulo           varchar2(100) := 'PKG_REPLICA_SUC.TraerInterfazmovalmacen';
   v_SQL              varchar2(4000);
   v_Cursor           cur_typ;
   v_Registro         interfazmovalmacen%rowtype;

begin
   p_ok := 0;

   --Buscar los datos en la sucursal
   v_SQL := 'select * from interfazmovalmacen@' || p_servidor || ' where idmovalmacen=''' || p_id ||'''';
   open v_Cursor for v_SQL;
   fetch v_Cursor into v_Registro;

   --Hacer insert o update en AC
   if p_cdAccion = REPLICAS_GENERAL.GET_ACCION_INSERT then
      insert into interfazmovalmacen values v_Registro;
   elsif p_cdAccion = REPLICAS_GENERAL.GET_ACCION_UPDATE then
      update interfazmovalmacen
         set row = v_Registro
         where idmovalmacen = p_id;
   end if;

   close v_Cursor;

   p_ok := 1;
   return;

exception when others then
   GrabarLog(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM ||' suc: '||p_servidor||' id: '||p_id);
end TraerInterfazmovalmacen;

/**************************************************************************************************
* Replica de la tabla tbldatoscliente 
* %v 24/09/2020 - ChM DNI de consumidor final para pedidos de canales TE,VE,CO
***************************************************************************************************/
procedure TraerDatosCliente(p_servidor in  sucursales.servidor%type,
                               p_cdAccion in  varchar2,
                               p_id       in  varchar2,
                               p_ok       out integer)
is
   v_modulo           varchar2(100) := 'PKG_REPLICA_SUC.TraerTblDatosCliente';
   v_SQL              varchar2(4000);
   v_Cursor           cur_typ;
   v_Registro         tbldatoscliente%rowtype;

begin
   p_ok := 0;

   --Buscar los datos en la sucursal
   v_SQL := 'select * from tbldatoscliente@' || p_servidor || ' where iddatoscli=''' || p_id ||'''';
   open v_Cursor for v_SQL;
   fetch v_Cursor into v_Registro;

   --Hacer insert o update en AC
   if p_cdAccion = REPLICAS_GENERAL.GET_ACCION_INSERT then
      insert into tbldatoscliente values v_Registro;      
   elsif p_cdAccion = REPLICAS_GENERAL.GET_ACCION_UPDATE then
      update tbldatoscliente set row = v_Registro where iddatoscli = p_id;      
   end if;

   close v_Cursor;

   p_ok := 1;
   return;

exception when others then
   GrabarLog(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM ||' suc: '||p_servidor||' id: '||p_id);
end TraerDatosCliente;

/**************************************************************************************************
* Dada una sucursal comienza el proceso de replica desde la sucursal hacia AC
* %v 03/06/2014 - MarianoL
* %v 26/01/2015 - MartinM: Agrego la replicación de la Tabla TblClNotaDeCredito
* %v 02/02/2015 - MartinM: Agrego la replicación de la Tabla TblClContraCargo
* %v 23/12/2015 - MartinM: Agrego la replicación de la tabla tblguiacomisautorizasaldo
* %v 18/09/2018 - JBodnar: Agrego la replicación de tblslv_consolidado y tblslv_consolidado_pedido
* %v 27/06/2019 - JBodnar: Agrego la replicación de tblclsube
* %v 29/08/2020 - APW: Agrego replicas de SLVM para LETRA
* %v 07/09/2020 - APW: Agrego relicas de SLVM para BW
***************************************************************************************************/
procedure Traer(p_servidor   in  sucursales.servidor%type)
is
   v_modulo           varchar2(100) := 'PKG_REPLICA_SUC.Traer';
   v_SQL              varchar2(4000);
   v_CurReplica       cur_typ;
   v_RegReplica       t_tblReplica;
   v_ok               number;
   v_Procesar         number;
   v_dtInicioProc     date := sysdate;
begin

   --Eliminar la lista de elementos insertados
   g_ListaInsert.DELETE;

   --Armar el query con los datos a Traer
   v_SQL :=          'select idreplica, vlnombretabla, cdaccion, idtabla, idcompuesto ';
   v_SQL := v_SQL || '  from (select idreplica, vlnombretabla, cdaccion, idtabla, idcompuesto ';
   v_SQL := v_SQL || '          from tblreplica@' || p_servidor;
   v_SQL := v_SQL || '         where cdestado = ''' || REPLICAS_GENERAL.estado_inicial ||'''';
   v_SQL := v_SQL || '         order by idreplica)';
   v_SQL := v_SQL || ' where rownum <= '  || g_CantMaxTraer ;
   
   --Recorrer los registros de la tblReplica de la sucursal
   open v_CurReplica for v_SQL;
   loop
      fetch v_CurReplica into v_RegReplica;
      exit when v_CurReplica%notfound;

      v_ok := 0;
      v_Procesar := 1;

      --Para mejorar la performance y minimizar el trafico:
      -- una vez que un id fue insertado se ignoran los update sucesivos del mismo id ya que no van a alterar el registro
      if v_RegReplica.CDACCION = REPLICAS_GENERAL.GET_ACCION_INSERT then     --Acción de insert:
         SetRegistroInsertado(v_RegReplica.IDTABLA);                         --Marcar el registro como insertado
      elsif v_RegReplica.CDACCION = REPLICAS_GENERAL.GET_ACCION_UPDATE and v_RegReplica.IDTABLA <> 'X'then  --Acción de update:
         if GetRegistroInsertado(v_RegReplica.IDTABLA) = 1 then              --Verificar si anteriormente fue insertado...
            v_Procesar := 0;                                                 --No procesar el update
            v_ok := 1;
         end if;
      end if;

      if v_Procesar = 1 then
         --Traer cada registro hacia AC
         if v_RegReplica.VLNOMVRETABLA = 'documentos' then 
            TraerDocumentos(p_servidor, v_RegReplica.CDACCION, v_RegReplica.IDTABLA, v_ok);
         elsif v_RegReplica.VLNOMVRETABLA = 'movmateriales' then
            TraerMovMateriales(p_servidor, v_RegReplica.CDACCION, v_RegReplica.IDTABLA, v_ok);
         elsif v_RegReplica.VLNOMVRETABLA = 'tblcuenta' then
            TraerCuenta(p_servidor, v_RegReplica.CDACCION, v_RegReplica.IDTABLA, v_ok);
         elsif v_RegReplica.VLNOMVRETABLA = 'tblmovcaja' then
            TraerMovCaja(p_servidor, v_RegReplica.CDACCION, v_RegReplica.IDTABLA, v_ok);
         elsif v_RegReplica.VLNOMVRETABLA = 'tblaliviodetalle' then
            TraerAlivioDetalle(p_servidor, v_RegReplica.CDACCION, v_RegReplica.IDTABLA, v_ok);
         elsif v_RegReplica.VLNOMVRETABLA = 'tblampliacioncredito' then
            TraerAmpliacionCredito(p_servidor, v_RegReplica.CDACCION, v_RegReplica.IDTABLA, v_ok);
         elsif v_RegReplica.VLNOMVRETABLA = 'tblingreso' then
            TraerIngreso(p_servidor, v_RegReplica.CDACCION, v_RegReplica.IDTABLA, v_ok);
         elsif v_RegReplica.VLNOMVRETABLA = 'tblmovcuenta' then
            TraerMovCuenta(p_servidor, v_RegReplica.CDACCION, v_RegReplica.IDTABLA, v_ok);
         elsif v_RegReplica.VLNOMVRETABLA = 'tblcobranza' then
            TraerCobranza(p_servidor, v_RegReplica.CDACCION, v_RegReplica.IDTABLA, v_ok);
         elsif v_RegReplica.VLNOMVRETABLA = 'tblelectronico' then
            TraerElectronico(p_servidor, v_RegReplica.CDACCION, v_RegReplica.IDTABLA, v_ok);
         elsif v_RegReplica.VLNOMVRETABLA = 'tbltarjeta' then
            TraerTarjeta(p_servidor, v_RegReplica.CDACCION, v_RegReplica.IDTABLA, v_ok);
         elsif v_RegReplica.VLNOMVRETABLA = 'tblcheque' then
            TraerCheque(p_servidor, v_RegReplica.CDACCION, v_RegReplica.IDTABLA, v_ok);
         elsif v_RegReplica.VLNOMVRETABLA = 'tblposnetbanco' then
            TraerPosnetBanco(p_servidor, v_RegReplica.CDACCION, v_RegReplica.IDTABLA, v_ok);
         elsif v_RegReplica.VLNOMVRETABLA = 'tblinterdeposito' then
            TraerInterdeposito(p_servidor, v_RegReplica.CDACCION, v_RegReplica.IDTABLA, v_ok);
         elsif v_RegReplica.VLNOMVRETABLA = 'tblticket' then
            TraerTicket(p_servidor, v_RegReplica.CDACCION, v_RegReplica.IDTABLA, v_ok);
         elsif v_RegReplica.VLNOMVRETABLA = 'tblcierrelote' then
            TraerCierreLote(p_servidor, v_RegReplica.CDACCION, v_RegReplica.IDTABLA, v_ok);
         elsif v_RegReplica.VLNOMVRETABLA = 'tblmonedaorigen' then
            TraerMonedaOrigen(p_servidor, v_RegReplica.CDACCION, v_RegReplica.IDTABLA, v_ok);
         elsif v_RegReplica.VLNOMVRETABLA = 'tblretencion' then
            TraerRetencion(p_servidor, v_RegReplica.CDACCION, v_RegReplica.IDTABLA, v_ok);
         elsif v_RegReplica.VLNOMVRETABLA = 'tblpagaredetalle' then
            TraerPagareDetalle(p_servidor, v_RegReplica.CDACCION, v_RegReplica.IDTABLA, v_ok);
         elsif v_RegReplica.VLNOMVRETABLA = 'tblautorizacioncheque' then
            TraerAutorizacionCheque(p_servidor, v_RegReplica.CDACCION, v_RegReplica.IDTABLA, v_ok);
         elsif v_RegReplica.VLNOMVRETABLA = 'tblposnet_transmitido' then
            TraerPosnet_Transmitido(p_servidor, v_RegReplica.CDACCION, v_RegReplica.IDTABLA, v_ok);
         elsif v_RegReplica.VLNOMVRETABLA = 'tblclnotadecredito' then
            TraerClNotaDeCredito(p_servidor, v_RegReplica.CDACCION, v_RegReplica.IDTABLA, v_ok);
         elsif v_RegReplica.VLNOMVRETABLA = 'tblclcontracargo' then
            TraerClContraCargo(p_servidor, v_RegReplica.CDACCION, v_RegReplica.IDTABLA, v_ok);
         elsif v_RegReplica.VLNOMVRETABLA = 'tblingresoestado_ac' then
            TraerIngresoEstadoAc(p_servidor, v_RegReplica.CDACCION, v_RegReplica.IDTABLA, v_ok);
         elsif v_RegReplica.VLNOMVRETABLA = 'tbldocumentodeuda' then
            TraerDocumentoDeuda(p_servidor, v_RegReplica.CDACCION, v_RegReplica.IDTABLA, v_ok);
         elsif v_RegReplica.VLNOMVRETABLA = 'tbltesoro' then
            TraerTesoro(p_servidor, v_RegReplica.CDACCION, v_RegReplica.IDTABLA, v_ok);
         elsif v_RegReplica.VLNOMVRETABLA = 'tbldiferenciacaja' then
            TraerDiferenciaCaja(p_servidor, v_RegReplica.CDACCION, v_RegReplica.IDTABLA, v_ok);
         elsif v_RegReplica.VLNOMVRETABLA = 'guiasdetransporte' then
            TraerGuiasTransporte(p_servidor, v_RegReplica.CDACCION, v_RegReplica.IDTABLA, v_ok);
         elsif v_RegReplica.VLNOMVRETABLA = 'tbldetalleguia' then
            TraerDetGuiaTransporte(p_servidor, v_RegReplica.CDACCION, v_RegReplica.IDTABLA, v_ok);
         elsif v_RegReplica.VLNOMVRETABLA = 'tbldireccioncuenta' then
            TraerDireccionCuenta(p_servidor, v_RegReplica.CDACCION, v_RegReplica.IDTABLA, v_ok);
         elsif v_RegReplica.VLNOMVRETABLA = 'tbldeudatrans' then
            TraerDeudaTrans(p_servidor, v_RegReplica.CDACCION, v_RegReplica.IDTABLA, v_ok);
         elsif v_RegReplica.VLNOMVRETABLA = 'tblcontrolstock' then
            TraerControlStock(p_servidor, v_RegReplica.CDACCION, v_RegReplica.IDTABLA, v_ok);
         elsif v_RegReplica.VLNOMVRETABLA = 'tblcontrolstockestadistica' then
            TraerControlStockEstad(p_servidor, v_RegReplica.CDACCION, v_RegReplica.IDTABLA, v_ok);
         elsif v_RegReplica.VLNOMVRETABLA = 'tbldocumento_salida' then
            TraerDocSalida(p_servidor, v_RegReplica.CDACCION, v_RegReplica.IDTABLA, v_ok);
         elsif v_RegReplica.VLNOMVRETABLA = 'tbltransaccion' then
            Traertransaccion(p_servidor, v_RegReplica.CDACCION, v_RegReplica.IDTABLA, v_ok);
         elsif v_RegReplica.VLNOMVRETABLA = 'pedidos' then
            TraerPedidos(p_servidor, v_RegReplica.CDACCION, v_RegReplica.IDTABLA, v_ok);
         elsif v_RegReplica.VLNOMVRETABLA = 'tbldocumento_control' then
            TraerDocControl(p_servidor, v_RegReplica.CDACCION, v_RegReplica.IDTABLA, v_ok);
         elsif v_RegReplica.VLNOMVRETABLA = 'tblorigendocumento' then
            TraerOrigenDocumento(p_servidor, v_RegReplica.CDACCION, v_RegReplica.IDTABLA, v_ok);
         elsif v_RegReplica.VLNOMVRETABLA = 'tblrendicionguia' then
            TraerRendicionGuia(p_servidor, v_RegReplica.CDACCION, v_RegReplica.IDTABLA, v_ok);
         elsif v_RegReplica.VLNOMVRETABLA = 'tblguiacomistransferencia' then
            TraerGuiaComisTransferencia(p_servidor, v_RegReplica.CDACCION, v_RegReplica.IDTABLA, v_ok);
         elsif v_RegReplica.VLNOMVRETABLA = 'tblguiacomisautorizasaldo' then
            TraerGuiaComisAutorizaSaldo(p_servidor, v_RegReplica.CDACCION, v_RegReplica.IDTABLA, v_ok);
         elsif v_RegReplica.VLNOMVRETABLA = 'tblguiacomischequeavalidar' then
            TraerTMPCargaCheque(p_servidor, v_RegReplica.CDACCION, v_RegReplica.IDTABLA, v_ok);
         elsif v_RegReplica.VLNOMVRETABLA = 'tblruteovendedor' then
            TraerRuteoVendedor(p_servidor, v_RegReplica.CDACCION, v_RegReplica.IDTABLA, v_ok);
         elsif v_RegReplica.VLNOMVRETABLA = 'tblcomisionistacobrar' then
            TraerComisionistaCobrar(p_servidor, v_RegReplica.CDACCION, v_RegReplica.IDTABLA, v_ok);
         elsif v_RegReplica.VLNOMVRETABLA = 'cuentasusuarios' then
            TraerCuentasUsuarios(p_servidor, v_RegReplica.CDACCION, v_RegReplica.IDTABLA, v_ok);
         elsif v_RegReplica.VLNOMVRETABLA = 'entidades' then
            TraerEntidades(p_servidor, v_RegReplica.CDACCION, v_RegReplica.IDTABLA, v_ok);
         elsif v_RegReplica.VLNOMVRETABLA = 'infoimpuestosentidades' then
            TraerInfoImpuestosEntidades(p_servidor, v_RegReplica.CDACCION, v_RegReplica.IDTABLA, v_ok);
         elsif v_RegReplica.VLNOMVRETABLA = 'tjclientescf' then
            TraerTarjetasEntidades(p_servidor, v_RegReplica.CDACCION, v_RegReplica.IDTABLA, v_ok);
         elsif v_RegReplica.VLNOMVRETABLA = 'rolesentidades' then
            TraerRolesEntidades(p_servidor, v_RegReplica.CDACCION, v_RegReplica.IDTABLA, v_RegReplica.IDCOMPUESTO, v_ok);
         elsif v_RegReplica.VLNOMVRETABLA = 'contactosentidades' then
            TraerContactosEntidades(p_servidor, v_RegReplica.CDACCION, v_RegReplica.IDTABLA, v_RegReplica.IDCOMPUESTO, v_ok);
         elsif v_RegReplica.VLNOMVRETABLA = 'direccionesentidades' then
            TraerDireccionesEntidades(p_servidor, v_RegReplica.CDACCION, v_RegReplica.IDTABLA, v_RegReplica.IDCOMPUESTO, v_ok);
         elsif v_RegReplica.VLNOMVRETABLA = 'clientescomisionistas' then
            TraerClientesComisionistas(p_servidor, v_RegReplica.CDACCION, v_RegReplica.IDTABLA,  v_RegReplica.IDCOMPUESTO, v_ok);
         elsif v_RegReplica.VLNOMVRETABLA = 'acumcfvital' then
            TraerAcumCfVital(p_servidor, v_RegReplica.CDACCION, v_RegReplica.IDTABLA,  v_RegReplica.IDCOMPUESTO, v_ok);
         elsif v_RegReplica.VLNOMVRETABLA = 'tblimpacumulador' then
            TraerImpAcumulador(p_servidor, v_RegReplica.CDACCION, v_RegReplica.IDTABLA, v_ok);
         elsif v_RegReplica.VLNOMVRETABLA = 'tblimpdocumento' then
            TraerImpDocumento(p_servidor, v_RegReplica.CDACCION, v_RegReplica.IDTABLA, v_ok);
         elsif v_RegReplica.VLNOMVRETABLA = 'tblimpexencion' then
            TraerImpExencion(p_servidor, v_RegReplica.CDACCION, v_RegReplica.IDTABLA, v_ok);
         elsif v_RegReplica.VLNOMVRETABLA = 'tblimpreduccion' then
            TraerImpReduccion(p_servidor, v_RegReplica.CDACCION, v_RegReplica.IDTABLA, v_ok);
         elsif v_RegReplica.VLNOMVRETABLA = 'tbldescuentoempleado' then
            TraerDescuentoEmpleado(p_servidor, v_RegReplica.CDACCION, v_RegReplica.IDTABLA, v_ok);
         elsif v_RegReplica.VLNOMVRETABLA = 'ubicacionarticulos' then
            TraerUbicacionArticulos(p_servidor, v_RegReplica.CDACCION, v_RegReplica.IDTABLA, v_RegReplica.IDCOMPUESTO, v_ok);
         elsif v_RegReplica.VLNOMVRETABLA = 'tbllogestadopedidos' then
            TraerEstadoPedidos(p_servidor, v_RegReplica.CDACCION, v_RegReplica.IDTABLA, v_ok);
         elsif v_RegReplica.VLNOMVRETABLA = 'tblcontrolstockhistorico' then
            TraerControlStockHist(p_servidor, v_RegReplica.CDACCION, v_RegReplica.IDTABLA, v_ok);
         elsif v_RegReplica.VLNOMVRETABLA = 'tblcontrolstockdetalle' then
            TraerControlStockDet(p_servidor, v_RegReplica.CDACCION, v_RegReplica.IDTABLA, v_ok);
         elsif v_RegReplica.VLNOMVRETABLA = 'tblcontrolpuertacomentario' then
            TraerControlPuertaComentario(p_servidor, v_RegReplica.CDACCION, v_RegReplica.IDTABLA, v_ok);
         elsif v_RegReplica.VLNOMVRETABLA = 'tblauditoria' then
            TraerAuditoria(p_servidor, v_RegReplica.CDACCION, v_RegReplica.IDTABLA, v_ok);
         elsif v_RegReplica.VLNOMVRETABLA = 'auditoria' then
            TraerAuditoriaVieja(p_servidor, v_RegReplica.CDACCION, v_RegReplica.IDTABLA, v_ok);
         elsif v_RegReplica.VLNOMVRETABLA = 'tbltraspasotrans' then
            TraerTraspasoTrans(p_servidor, v_RegReplica.CDACCION, v_RegReplica.IDTABLA, v_ok);
         elsif v_RegReplica.VLNOMVRETABLA = 'tbldonacion' then
            TraerDonacion(p_servidor, v_RegReplica.CDACCION, v_RegReplica.IDTABLA, v_ok);
         elsif v_RegReplica.VLNOMVRETABLA = 'tblcnpresupuesto' then
            TraerCNpresupuesto (p_servidor, v_RegReplica.CDACCION, v_RegReplica.IDTABLA, v_ok);
         elsif v_RegReplica.VLNOMVRETABLA = 'tblcnpresupuestopedido' then
            TraerCNpresupuestopedido (p_servidor, v_RegReplica.CDACCION, v_RegReplica.IDTABLA, v_ok);
         elsif v_RegReplica.VLNOMVRETABLA = 'tblcnpedido' then
            TraerCNpedido (p_servidor, v_RegReplica.CDACCION, v_RegReplica.IDTABLA, v_ok);
         elsif v_RegReplica.VLNOMVRETABLA = 'tblcnfactura' then
            TraerCNfactura (p_servidor, v_RegReplica.CDACCION, v_RegReplica.IDTABLA, v_ok);
         elsif v_RegReplica.VLNOMVRETABLA = 'tblreclamoposnet' then
            TraerReclamoPosnet(p_servidor, v_RegReplica.CDACCION, v_RegReplica.IDTABLA, v_ok);
         elsif v_RegReplica.VLNOMVRETABLA = 'tblreclamoposnetdet' then
            TraerReclamoPosnetDet(p_servidor, v_RegReplica.CDACCION, v_RegReplica.IDTABLA, v_ok);
         elsif v_RegReplica.VLNOMVRETABLA = 'tblreclamoobservacion' then
            TraerReclamoObservacion (p_servidor, v_RegReplica.CDACCION, v_RegReplica.IDTABLA, v_ok);
         elsif v_RegReplica.VLNOMVRETABLA = 'tblentidadaplicacion' then
            TraerEntidadAplicacion (p_servidor, v_RegReplica.CDACCION, v_RegReplica.IDTABLA, v_ok);
         elsif v_RegReplica.VLNOMVRETABLA = 'tblliberacioncuenta' then
            TraerLiberacionCuenta (p_servidor, v_RegReplica.CDACCION, v_RegReplica.IDTABLA, v_ok);
         elsif v_RegReplica.VLNOMVRETABLA = 'tblanticipoclienteaux' then
            TraerAnticipoClienteAux (p_servidor, v_RegReplica.CDACCION, v_RegReplica.IDTABLA, v_ok);
         elsif v_RegReplica.VLNOMVRETABLA = 'tblslv_consolidado' then
            TraerConsolidado (p_servidor, v_RegReplica.CDACCION, v_RegReplica.IDTABLA, v_ok);
         elsif v_RegReplica.VLNOMVRETABLA = 'tblslv_consolidado_pedido' then
            TraerConsolidado_pedido (p_servidor, v_RegReplica.CDACCION, v_RegReplica.IDTABLA, v_ok);
         elsif v_RegReplica.VLNOMVRETABLA = 'tblslv_consolidado_pedido_rel' then
            TraerConsolidado_pedido_rel (p_servidor, v_RegReplica.CDACCION, v_RegReplica.IDTABLA, v_ok);
         elsif v_RegReplica.VLNOMVRETABLA = 'tblentidadmercadopago' then
            TraerEntidadMP (p_servidor, v_RegReplica.CDACCION, v_RegReplica.IDTABLA, v_ok);
         elsif v_RegReplica.VLNOMVRETABLA = 'cierressucursal' then
            TraerCierreSucursal (p_servidor, v_RegReplica.CDACCION, v_RegReplica.IDTABLA, v_RegReplica.IDCOMPUESTO, v_ok);
         elsif v_RegReplica.VLNOMVRETABLA = 'detallemovmateriales' then
            TraerDetallemovmateriales (p_servidor, v_RegReplica.CDACCION, v_RegReplica.IDTABLA, v_RegReplica.IDCOMPUESTO, v_ok);
         elsif v_RegReplica.VLNOMVRETABLA = 'tblimpdocumentodetalle' then
            TraerImpDocumentoDetalle (p_servidor, v_RegReplica.CDACCION, v_RegReplica.IDTABLA, v_ok);
         elsif v_RegReplica.VLNOMVRETABLA = 'tbldocumentocodigoafip' then
            TraerDocumentocodigoAfip (p_servidor, v_RegReplica.CDACCION, v_RegReplica.IDTABLA, v_ok);
   -- a partir de aca los que se necesitan para V360
         elsif v_RegReplica.VLNOMVRETABLA = 'tblslv_remito' then
            TraerRemitoSLV (p_servidor, v_RegReplica.CDACCION, v_RegReplica.IDTABLA, v_ok);
         
         elsif v_RegReplica.VLNOMVRETABLA = 'tblcierrelotesalon' then
            TraerCierreLoteSalon (p_servidor, v_RegReplica.CDACCION, v_RegReplica.IDTABLA, v_ok);
         elsif v_RegReplica.VLNOMVRETABLA = 'tblclsube' then
            TraerSube (p_servidor, v_RegReplica.CDACCION, v_RegReplica.IDTABLA, v_ok);
         elsif v_RegReplica.VLNOMVRETABLA = 'interfazmovalmacen' then
            TraerInterfazmovalmacen (p_servidor, v_RegReplica.CDACCION, v_RegReplica.IDTABLA, v_ok);
 
     -- a partir de aca los de SLVM para LETRA
         elsif v_RegReplica.VLNOMVRETABLA = 'tblslvconsolidadom' then
            TraerConsolidadoM (p_servidor, v_RegReplica.CDACCION, v_RegReplica.IDTABLA, v_ok);
         elsif v_RegReplica.VLNOMVRETABLA = 'tblslvconsolidadopedido' then
            TraerConsolidadoPedidoM (p_servidor, v_RegReplica.CDACCION, v_RegReplica.IDTABLA, v_ok);
         elsif v_RegReplica.VLNOMVRETABLA = 'tblslvconsolidadopedidorel' then
            TraerConsolidadoPedidoRelM (p_servidor, v_RegReplica.CDACCION, v_RegReplica.IDTABLA, v_ok);
     -- a partir de aca los de SLVM para BW
        elsif v_RegReplica.VLNOMVRETABLA = 'tblslvconsolidadomdet' then
            TraerConsolidadoDetM (p_servidor, v_RegReplica.CDACCION, v_RegReplica.IDTABLA, v_ok);
        elsif v_RegReplica.VLNOMVRETABLA = 'tblslvremito' then
            TraerRemitoM (p_servidor, v_RegReplica.CDACCION, v_RegReplica.IDTABLA, v_ok);
        elsif v_RegReplica.VLNOMVRETABLA = 'tblslvcontrolremito' then
            TraerControlRemitoM (p_servidor, v_RegReplica.CDACCION, v_RegReplica.IDTABLA, v_ok);
        elsif v_RegReplica.VLNOMVRETABLA = 'tblslvcontrolremitodet' then
            TraerControlRemitoDetM (p_servidor, v_RegReplica.CDACCION, v_RegReplica.IDTABLA, v_ok);
        elsif v_RegReplica.VLNOMVRETABLA = 'tblslvtarea' then
            TraerTareaM (p_servidor, v_RegReplica.CDACCION, v_RegReplica.IDTABLA, v_ok);
        elsif v_RegReplica.VLNOMVRETABLA = 'tblslvtareadet' then
            TraerTareaDetM (p_servidor, v_RegReplica.CDACCION, v_RegReplica.IDTABLA, v_ok);
        elsif v_RegReplica.VLNOMVRETABLA = 'tblslvpedfaltanterel' then
            TraerPedFaltanteRelM (p_servidor, v_RegReplica.CDACCION, v_RegReplica.IDTABLA, v_ok);
            
     -- a partir de aca los de DNI PEDIDOS TE;VE;CO
        elsif v_RegReplica.VLNOMVRETABLA = 'tbldatoscliente' then
            TraerDatosCliente (p_servidor, v_RegReplica.CDACCION, v_RegReplica.IDTABLA, v_ok);       
  ---
         else
            GrabarLog(2, 'Modulo: '||v_Modulo||' No sabe como traer datos de la tabla '||v_RegReplica.VLNOMVRETABLA||' hacia AC.');
            v_ok := 0;
         end if;
      end if;

      --Si se pudo Traer en AC, marcarlo como replicado y hacer commit
      if v_ok = 1 then
         g_vlRegistrosOK := g_vlRegistrosOK + 1;
         v_SQL := 'update tblreplica@'||p_servidor||' set cdestado = '''||REPLICAS_GENERAL.estado_enviado||''''||', dtcambioestado= sysdate';
         v_SQL := v_SQL || ' where idreplica = ' || v_RegReplica.IDREPLICA;
         EXECUTE IMMEDIATE v_SQL;
         commit;
      else
         g_vlRegistrosError := g_vlRegistrosError + 1;
         rollback;
      end if;

      --Controlar si la replica está demorando mucho
      if ( (sysdate-v_dtInicioProc)*24*60) > g_CantMaxMinutos then
         return;
      end if;

   end loop;

   return;

exception when others then
   GrabarLog(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM||' suc: '||p_servidor);
end Traer;

/**************************************************************************************************
* Replica la tabla TblCuenta hacia la sucursal
* %v 03/06/2014 - MarianoL
***************************************************************************************************/
procedure LlevarCuenta(p_servidor in  sucursales.servidor%type,
                       p_cdAccion in  varchar2,
                       p_id       in  varchar2,
                       p_ok       out integer )
is
   v_modulo           varchar2(100) := 'PKG_REPLICA_SUC.LlevarCuenta';
   v_SQL              varchar2(4000);
   v_Campos           varchar2(4000);
begin

   p_ok := 0;

   --Hacer insert o update en la sucursal
   if p_cdAccion = REPLICAS_GENERAL.GET_ACCION_INSERT then
      v_SQL := 'insert into tblcuenta@' || p_servidor;
      v_SQL := v_SQL || ' (select * from tblcuenta c where c.idcuenta =''' || p_id ||''')';

   elsif p_cdAccion = REPLICAS_GENERAL.GET_ACCION_UPDATE then
      v_Campos := GetCamposTabla('tblcuenta');
      v_SQL := 'update tblcuenta@' || p_servidor || ' set ';
      v_SQL := v_SQL || ' ('|| v_Campos ||') =  (select '|| v_Campos ||' from tblcuenta c where c.idcuenta =''' || p_id ||''')';
      v_SQL := v_SQL || ' where idcuenta =''' || p_id ||'''';

   end if;

   execute immediate v_SQL;

   p_ok := 1;
   return;

exception when others then
   GrabarLog(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM ||' suc: '||p_servidor||' id: '||p_id);
end LlevarCuenta;

/**************************************************************************************************
* Replica la tabla TblDireccionCuenta hacia la sucursal
* %v 26/05/2017 - JBodnar
* %v 11/09/2017 - APW - Corregí error en nombre de tabla
***************************************************************************************************/
procedure LlevarDireccionCuenta(p_servidor in  sucursales.servidor%type,
                                p_cdAccion in  varchar2,
                                p_id       in  varchar2,
                                p_ok       out integer )
is
   v_modulo           varchar2(100) := 'PKG_REPLICA_SUC.LlevarDireccionCuenta';
   v_SQL              varchar2(4000);
   v_Campos           varchar2(4000);
begin

   p_ok := 0;

   --Hacer insert o update en la sucursal
   if p_cdAccion = REPLICAS_GENERAL.GET_ACCION_INSERT then
      v_SQL := 'insert into tbldireccioncuenta@' || p_servidor;
      v_SQL := v_SQL || ' (select * from tbldireccioncuenta c where c.iddireccioncuenta =''' || p_id ||''')';

   elsif p_cdAccion = REPLICAS_GENERAL.GET_ACCION_UPDATE then
      v_Campos := GetCamposTabla('tbldireccioncuenta');
      v_SQL := 'update tbldireccioncuenta@' || p_servidor || ' set ';
      v_SQL := v_SQL || ' ('|| v_Campos ||') =  (select '|| v_Campos ||' from tbldireccioncuenta c where c.iddireccioncuenta =''' || p_id ||''')';
      v_SQL := v_SQL || ' where iddireccioncuenta =''' || p_id ||'''';

   end if;

   execute immediate v_SQL;

   p_ok := 1;
   return;

exception when others then
   GrabarLog(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM ||' suc: '||p_servidor||' id: '||p_id);
end LlevarDireccionCuenta;

/**************************************************************************************************
* Replica la tabla LlevarClientesComisionistas hacia la sucursal
* %v 26/05/2017 - JBodnar
***************************************************************************************************/
procedure LlevarClientesComisionistas(p_servidor in  sucursales.servidor%type,
                                      p_cdAccion in  varchar2,
                                      p_id       in  varchar2,
                                      p_idCompuesto in  varchar2,
                                      p_ok       out integer )
is
   v_modulo           varchar2(100) := 'PKG_REPLICA_SUC.LlevarClientesComisionistas';
   v_SQL              varchar2(4000);
   v_Campos           varchar2(4000);
   v_idComisionista  clientescomisionistas.idcomisionista%type;
   v_idEntidad       clientescomisionistas.identidad%type;
begin

   p_ok := 0;

   --Decodificar el id compuesto en cada campo
   v_idComisionista := GetIdPorPosicion(p_idCompuesto,1);
   v_idEntidad      := GetIdPorPosicion(p_idCompuesto,2);

   --Hacer insert o update en la sucursal
   if p_cdAccion = REPLICAS_GENERAL.GET_ACCION_INSERT then
      v_SQL := 'insert into clientescomisionistas@' || p_servidor;
      v_SQL := v_SQL || ' (select * from clientescomisionistas c where c.idcomisionista =''' || v_idComisionista ||''' and identidad = '''||v_idEntidad||'''';

   elsif p_cdAccion = REPLICAS_GENERAL.GET_ACCION_UPDATE then
      v_Campos := GetCamposTabla('clientescomisionistas');
      v_SQL := 'update clientescomisionistas@' || p_servidor || ' set ';
      v_SQL := v_SQL || ' ('|| v_Campos ||') =  (select '|| v_Campos ||' from clientescomisionistas c where c.idcomisionista =''' || v_idComisionista ||''' and identidad = '''||v_idEntidad||'''';

   end if;

   execute immediate v_SQL;

   p_ok := 1;
   return;

exception when others then
   GrabarLog(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM ||' suc: '||p_servidor||' id: '||p_id);
end LlevarClientesComisionistas;

/**************************************************************************************************
* Replica la tabla documentos hacia la sucursal
* %v 06/03/2017 - JBodnar
***************************************************************************************************/
procedure LlevarDocumento (p_servidor in  sucursales.servidor%type,
                           p_cdAccion in  varchar2,
                           p_id       in  varchar2,
                           p_ok       out integer )
is
   v_modulo           varchar2(100) := 'PKG_REPLICA_SUC.LlevarDocumento';
   v_SQL              varchar2(4000);
   v_Campos           varchar2(4000);
begin

   p_ok := 0;

   --Update en la sucursal
   If p_cdAccion = REPLICAS_GENERAL.GET_ACCION_UPDATE then
      v_Campos := GetCamposTabla('documentos');
      v_SQL := 'update documentos@' || p_servidor || ' set ';
      v_SQL := v_SQL || ' ('|| v_Campos ||') =  (select '|| v_Campos ||' from documentos d where d.iddoctrx =''' || p_id ||''')';
      v_SQL := v_SQL || ' where iddoctrx =''' || p_id ||'''';

   end if;

   execute immediate v_SQL;

   p_ok := 1;
   return;

exception when others then
   GrabarLog(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM ||' suc: '||p_servidor||' id: '||p_id);
end LlevarDocumento;

/**************************************************************************************************
* Replica la tabla guiasdetransporte
* %v 23/06/2015 - JBodnar
* %v 11/09/2018 - IAquilano - Evito replicar a cc
***************************************************************************************************/
procedure LlevarDeudaTrans(p_servidor in  sucursales.servidor%type,
                               p_cdAccion in  varchar2,
                               p_id       in  varchar2,
                               p_ok       out integer )
is
   v_modulo           varchar2(100) := 'PKG_REPLICA_SUC.LlevarDeudaTrans';
   v_SQL              varchar2(4000);
   v_Campos           varchar2(4000);
begin

   p_ok := 0;
   --Controlo servidor, si es cc no hago nada
   If p_servidor = c_servidorcc then
     return;
   end if;
   --Hacer insert o update en la sucursal
   if p_cdAccion = REPLICAS_GENERAL.GET_ACCION_INSERT then
      v_SQL := 'insert into tbldeudatrans@' || p_servidor;
      v_SQL := v_SQL || ' (select * from tbldeudatrans c where c.iddeudatrans =''' || p_id ||''')';

   elsif p_cdAccion = REPLICAS_GENERAL.GET_ACCION_UPDATE then
      v_Campos := GetCamposTabla('tbldeudatrans');
      v_SQL := 'update tbldeudatrans@' || p_servidor || ' set ';
      v_SQL := v_SQL || ' ('|| v_Campos ||') =  (select '|| v_Campos ||' from tbldeudatrans c where c.iddeudatrans =''' || p_id ||''')';
      v_SQL := v_SQL || ' where iddeudatrans =''' || p_id ||'''';

   end if;

   execute immediate v_SQL;

   p_ok := 1;
   return;

exception when others then
   GrabarLog(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM ||' suc: '||p_servidor||' id: '||p_id);
end LlevarDeudaTrans;

/**************************************************************************************************
* Replica la tabla tblAmpliacionCredito hacia la sucursal
* %v 03/06/2014 - MarianoL
***************************************************************************************************/
procedure LlevarAmpliacionCredito(p_servidor in  sucursales.servidor%type,
                                  p_cdAccion in  varchar2,
                                  p_id       in  varchar2,
                                  p_ok       out integer )
is
   v_modulo           varchar2(100) := 'PKG_REPLICA_SUC.LlevarAmpliacionCredito';
   v_SQL              varchar2(4000);
   v_Campos           varchar2(4000);

begin
   p_ok := 0;

   --Hacer insert o update en la sucursal
   if p_cdAccion = REPLICAS_GENERAL.GET_ACCION_INSERT then
      v_SQL := 'insert into tblAmpliacionCredito@' || p_servidor;
      v_SQL := v_SQL || ' (select * from tblAmpliacionCredito c where c.idampliacion =''' || p_id ||''')';

   elsif p_cdAccion = REPLICAS_GENERAL.GET_ACCION_UPDATE then
      v_Campos := GetCamposTabla('tblAmpliacionCredito');
      v_SQL := 'update tblAmpliacionCredito@' || p_servidor || ' set ';
      v_SQL := v_SQL || ' ('|| v_Campos ||') =  (select '|| v_Campos ||' from tblAmpliacionCredito c where c.idampliacion =''' || p_id ||''')';
      v_SQL := v_SQL || ' where idampliacion =''' || p_id ||'''';

   end if;

   execute immediate v_SQL;

   p_ok := 1;
   return;

exception when others then
   GrabarLog(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM ||' suc: '||p_servidor||' id: '||p_id);

end LlevarAmpliacionCredito;

/**************************************************************************************************
* Replica la tabla tblposnet_transmitido hacia la sucursal
* %v 03/06/2014 - MarianoL
* %v 11/09/2018 - IAquilano - Evito replicar a cc
***************************************************************************************************/
procedure LlevarPosnet_Transmitido(p_servidor in  sucursales.servidor%type,
                                  p_cdAccion in  varchar2,
                                  p_id       in  varchar2,
                                  p_ok       out integer )
is
   v_modulo           varchar2(100) := 'PKG_REPLICA_SUC.LlevarPosnet_Transmitido';
   v_SQL              varchar2(4000);
   v_Campos           varchar2(4000);

begin
   p_ok := 0;
   --Controlo servidor, si es cc no hago nada
   If p_servidor = c_servidorcc then
     return;
   end if;
   --Hacer insert o update en la sucursal
   if p_cdAccion = REPLICAS_GENERAL.GET_ACCION_INSERT then
      v_SQL := 'insert into tblposnet_transmitido@' || p_servidor;
      v_SQL := v_SQL || ' (select * from tblposnet_transmitido c where c.idtransmitido =''' || p_id ||''')';

   elsif p_cdAccion = REPLICAS_GENERAL.GET_ACCION_UPDATE then
      v_Campos := GetCamposTabla('tblposnet_transmitido');
      v_SQL := 'update tblposnet_transmitido@' || p_servidor || ' set ';
      v_SQL := v_SQL || ' ('|| v_Campos ||') =  (select '|| v_Campos ||' from tblposnet_transmitido c where c.idtransmitido =''' || p_id ||''')';
      v_SQL := v_SQL || ' where idtransmitido =''' || p_id ||'''';

   end if;

   execute immediate v_SQL;

   p_ok := 1;
   return;

exception when others then
   GrabarLog(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM ||' suc: '||p_servidor||' id: '||p_id);

end LlevarPosnet_Transmitido;

/**************************************************************************************************
* Replica la tabla tblclnotadecredito hacia la sucursal
* %v 26/01/2015 - MartinM
* %v 11/09/2018 - IAquilano - Evito replicar a cc
***************************************************************************************************/
procedure LlevarCLNotaDeCredito(p_servidor in  sucursales.servidor%type,
                                p_cdAccion in  varchar2,
                                p_id       in  varchar2,
                                p_ok       out integer )
is
   v_modulo           varchar2(100) := 'PKG_REPLICA_SUC.LlevarCLNotaDeCredito';
   v_SQL              varchar2(4000);
   v_Campos           varchar2(4000);

begin
   p_ok := 0;
   --Controlo servidor, si es cc no hago nada
   If p_servidor = c_servidorcc then
     return;
   end if;

   --Hacer insert o update en la sucursal
   if p_cdAccion = REPLICAS_GENERAL.GET_ACCION_INSERT then
      v_SQL := 'insert into tblclnotadecredito@' || p_servidor;
      v_SQL := v_SQL || ' (select * from tblclnotadecredito c where c.idnotadecredito =''' || p_id ||''')';
   elsif p_cdAccion = REPLICAS_GENERAL.GET_ACCION_UPDATE then
      v_Campos := GetCamposTabla('tblclnotadecredito');
      v_SQL := 'update tblclnotadecredito@' || p_servidor || ' set ';
      v_SQL := v_SQL || ' ('|| v_Campos ||') =  (select '|| v_Campos ||' from tblclnotadecredito c where c.idnotadecredito =''' || p_id ||''')';
      v_SQL := v_SQL || ' where idnotadecredito =''' || p_id ||'''';
   end if;

   execute immediate v_SQL;

   p_ok := 1;
   return;

exception when others then
   GrabarLog(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM ||' suc: '||p_servidor||' id: '||p_id);
end LlevarCLNotaDeCredito;

/**************************************************************************************************
* Replica la tabla tblcomisionistacobrar hacia la sucursal
* %v 26/01/2015 - MartinM
* %v 11/09/2018 - IAquilano - Evito replicar a cc
***************************************************************************************************/
procedure LlevarComisionistaCobrar(p_servidor in  sucursales.servidor%type,
                                    p_cdAccion in  varchar2,
                                    p_id       in  varchar2,
                                    p_ok       out integer )
is
   v_modulo           varchar2(100) := 'PKG_REPLICA_SUC.LlevarComisionistaCobrar';
   v_SQL              varchar2(4000);
   v_Campos           varchar2(4000);

begin
   p_ok := 0;
   --Controlo servidor, si es cc no hago nada
   If p_servidor = c_servidorcc then
     return;
   end if;
   --Hacer insert o update en la sucursal
   if p_cdAccion = REPLICAS_GENERAL.GET_ACCION_INSERT then
      v_SQL := 'insert into tblcomisionistacobrar@' || p_servidor;
      v_SQL := v_SQL || ' (select * from tblcomisionistacobrar c where c.idcomisionistacobrar =''' || p_id ||''')';
   elsif p_cdAccion = REPLICAS_GENERAL.GET_ACCION_UPDATE then
      v_Campos := GetCamposTabla('tblcomisionistacobrar');
      v_SQL := 'update tblcomisionistacobrar@' || p_servidor || ' set ';
      v_SQL := v_SQL || ' ('|| v_Campos ||') =  (select '|| v_Campos ||' from tblcomisionistacobrar c where c.idcomisionistacobrar =''' || p_id ||''')';
      v_SQL := v_SQL || ' where idcomisionistacobrar =''' || p_id ||'''';
   end if;

   execute immediate v_SQL;

   p_ok := 1;
   return;

exception when others then
   GrabarLog(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM ||' suc: '||p_servidor||' id: '||p_id);
end LlevarComisionistaCobrar;

/**************************************************************************************************
* Replica la tabla tbltmp_guia_comis_cheque hacia la sucursal
* %v 20/10/2015 - MartinM
* %v 11/09/2018 - IAquilano - Evito replicar a cc
***************************************************************************************************/
procedure LlevarTMPCargaCheque (p_servidor in  sucursales.servidor%type,
                                p_cdAccion in  varchar2,
                                p_id       in  varchar2,
                                p_ok       out integer )
is
   v_modulo           varchar2(100) := 'PKG_REPLICA_SUC.LlevarTMPCargaCheque';
   v_SQL              varchar2(4000);
   v_Campos           varchar2(4000);

begin
   p_ok := 0;
   --Controlo servidor, si es cc no hago nada
   If p_servidor = c_servidorcc then
     return;
   end if;
   --Hacer insert o update en la sucursal
   if p_cdAccion = REPLICAS_GENERAL.GET_ACCION_INSERT then
      v_SQL := 'insert into tblguiacomischequeavalidar@' || p_servidor;
      v_SQL := v_SQL || ' (select * from tblguiacomischequeavalidar c where c.idtmpguiacomischeque =''' || p_id ||''')';
   elsif p_cdAccion = REPLICAS_GENERAL.GET_ACCION_UPDATE then
      v_Campos := GetCamposTabla('tblguiacomischequeavalidar');
      v_SQL := 'update tblguiacomischequeavalidar@' || p_servidor || ' set ';
      v_SQL := v_SQL || ' ('|| v_Campos ||') =  (select '|| v_Campos ||' from tblguiacomischequeavalidar c where c.idtmpguiacomischeque =''' || p_id ||''')';
      v_SQL := v_SQL || ' where idtmpguiacomischeque =''' || p_id ||'''';
   end if;

   execute immediate v_SQL;

   p_ok := 1;
   return;

exception when others then
   GrabarLog(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM ||' suc: '||p_servidor||' id: '||p_id);
end LlevarTMPCargaCheque;

/**************************************************************************************************
* Replica la tabla tblguiacomisautorizasaldo hacia la sucursal
* %v 04/12/2015 - MartinM
* %v 11/09/2018 - IAquilano - Evito replicar a cc
***************************************************************************************************/
procedure LlevarGuiaComisAutorizaSaldo(p_servidor in  sucursales.servidor%type,
                                       p_cdAccion in             varchar2     ,
                                       p_id       in             varchar2     ,
                                       p_ok       out            integer      )
IS

   v_modulo           varchar2(100) := 'PKG_REPLICA_SUC.LlevarGuiaComisAutorizaSaldo';
   v_SQL              varchar2(4000);
   v_Campos           varchar2(4000);

begin

   p_ok := 0;
   --Controlo servidor, si es cc no hago nada
   If p_servidor = c_servidorcc then
     return;
   end if;
   --Hacer insert o update en la sucursal
   if p_cdAccion = REPLICAS_GENERAL.GET_ACCION_INSERT then
      v_SQL := 'insert into tblguiacomisautorizasaldo@' || p_servidor;
      v_SQL := v_SQL || ' (select * from tblguiacomisautorizasaldo c where c.idautorizasaldo =''' || p_id ||''')';
   elsif p_cdAccion = REPLICAS_GENERAL.GET_ACCION_UPDATE then
      v_Campos := GetCamposTabla('tblguiacomisautorizasaldo');
      v_SQL := 'update tblguiacomisautorizasaldo@' || p_servidor || ' set ';
      v_SQL := v_SQL || ' ('|| v_Campos ||') =  (select '|| v_Campos ||' from tblguiacomisautorizasaldo c where c.idautorizasaldo =''' || p_id ||''')';
      v_SQL := v_SQL || ' where idautorizasaldo =''' || p_id ||'''';
   end if;

   execute immediate v_SQL;

   p_ok := 1;
   return;

exception when others then
   GrabarLog(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM ||' suc: '||p_servidor||' id: '||p_id);
end LlevarGuiaComisAutorizaSaldo;

/**************************************************************************************************
* Replica la tabla tblclcontracargo hacia la sucursal
* %v 02/02/2015 - MartinM
* %v 11/09/2018 - IAquilano - Evito replicar a cc
***************************************************************************************************/
procedure LlevarCLContraCargo(p_servidor in  sucursales.servidor%type,
                                p_cdAccion in  varchar2,
                                p_id       in  varchar2,
                                p_ok       out integer )
is
   v_modulo           varchar2(100) := 'PKG_REPLICA_SUC.LlevarCLContraCargo';
   v_SQL              varchar2(4000);
   v_Campos           varchar2(4000);

begin
   p_ok := 0;
   --Controlo servidor, si es cc no hago nada
   If p_servidor = c_servidorcc then
     return;
   end if;
   --Hacer insert o update en la sucursal
   if p_cdAccion = REPLICAS_GENERAL.GET_ACCION_INSERT then
      v_SQL := 'insert into tblclcontracargo@' || p_servidor;
      v_SQL := v_SQL || ' (select * from tblclcontracargo c where c.idcontracargo =''' || p_id ||''')';

   elsif p_cdAccion = REPLICAS_GENERAL.GET_ACCION_UPDATE then
      v_Campos := GetCamposTabla('tblclcontracargo');
      v_SQL := 'update tblclcontracargo@' || p_servidor || ' set ';
      v_SQL := v_SQL || ' ('|| v_Campos ||') =  (select '|| v_Campos ||' from tblclcontracargo c where c.idcontracargo =''' || p_id ||''')';
      v_SQL := v_SQL || ' where idcontracargo =''' || p_id ||'''';
   end if;

   execute immediate v_SQL;

   p_ok := 1;
   return;

exception when others then
   GrabarLog(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM ||' suc: '||p_servidor||' id: '||p_id);

end LlevarCLContraCargo;

/**************************************************************************************************
* Replica la tabla tblingresoestado_ac hacia la sucursal
* %v 03/06/2014 - MarianoL
* %v 11/09/2018 - IAquilano - Evito replicar a cc
***************************************************************************************************/
procedure LlevarIngresoEstadoAc(p_servidor in  sucursales.servidor%type,
                              p_cdAccion in  varchar2,
                              p_id       in  varchar2,
                              p_ok       out integer )
is
   v_modulo           varchar2(100) := 'PKG_REPLICA_SUC.LlevarIngresoEstadoAc';
   v_SQL              varchar2(4000);
   v_Campos           varchar2(4000);

begin
   p_ok := 0;
   --Controlo servidor, si es cc no hago nada
   If p_servidor = c_servidorcc then
     return;
   end if;
   --Hacer insert o update en la sucursal
   if p_cdAccion = REPLICAS_GENERAL.GET_ACCION_INSERT then
      v_SQL := 'insert into tblingresoestado_ac@' || p_servidor;
      v_SQL := v_SQL || ' (select * from tblingresoestado_ac c where c.idingresoestadoac =''' || p_id ||''')';

   elsif p_cdAccion = REPLICAS_GENERAL.GET_ACCION_UPDATE then
      v_Campos := GetCamposTabla('tblingresoestado_ac');
      v_SQL := 'update tblingresoestado_ac@' || p_servidor || ' set ';
      v_SQL := v_SQL || ' ('|| v_Campos ||') =  (select '|| v_Campos ||' from tblingresoestado_ac c where c.idingresoestadoac =''' || p_id ||''')';
      v_SQL := v_SQL || ' where idingresoestadoac =''' || p_id ||'''';

   end if;

   execute immediate v_SQL;

   p_ok := 1;
   return;

exception when others then
   GrabarLog(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM ||' suc: '||p_servidor||' id: '||p_id);

end LlevarIngresoEstadoAc;

/**************************************************************************************************
* Replica la tabla TblCuenta hacia la sucursal
* %v 03/06/2014 - MarianoL
* %v 11/09/2018 - IAquilano - Evito replicar a cc
***************************************************************************************************/
procedure LlevarControlStock(p_servidor in  sucursales.servidor%type,
                             p_cdAccion in  varchar2,
                             p_id       in  varchar2,
                             p_ok       out INTEGER)
is
   v_modulo           varchar2(100) := 'PKG_REPLICA_SUC.LlevarControlStock';
   v_SQL              varchar2(4000);
   v_Campos           varchar2(4000);
begin

   p_ok := 0;
   --Controlo servidor, si es cc no hago nada
   If p_servidor = c_servidorcc then
     return;
   end if;
   --Hacer insert o update en la sucursal
   if p_cdAccion = REPLICAS_GENERAL.GET_ACCION_INSERT then
      v_SQL := 'insert into tblcontrolstock@' || p_servidor;
      v_SQL := v_SQL || ' (select * from tblcontrolstock c where c.idcontrolstock  =''' || p_id ||''')';

   elsif p_cdAccion = REPLICAS_GENERAL.GET_ACCION_UPDATE then
      v_Campos := GetCamposTabla('tblcontrolstock');
      v_SQL := 'update tblcontrolstock@' || p_servidor || ' set ';
      v_SQL := v_SQL || ' ('|| v_Campos ||') =  (select '|| v_Campos ||' from tblcontrolstock c where c.idcontrolstock  =''' || p_id ||''')';
      v_SQL := v_SQL || ' where idcontrolstock  =''' || p_id ||'''';

   end if;

   execute immediate v_SQL;

   p_ok := 1;
   return;

exception when others then
   GrabarLog(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM ||' suc: '||p_servidor||' id: '||p_id);
end LlevarControlStock;

/**************************************************************************************************
* Replica la tabla LlevarPermisos hacia la sucursal
* %v 14/01/2016 - MarianoL
* %v 11/09/2018 - IAquilano - Evito replicar a cc
***************************************************************************************************/
procedure LlevarPermisos(p_servidor in  sucursales.servidor%type,
                         p_cdAccion in  varchar2,
                         p_id       in  varchar2,
                         p_ok       out INTEGER)
is
   v_modulo           varchar2(100) := 'PKG_REPLICA_SUC.LlevarPermisos';
   v_SQL              varchar2(4000);
   v_Campos           varchar2(4000);
   v_idPersona        personas.idpersona%type;

begin

   p_ok := 0;
   --Controlo servidor, si es cc no hago nada
   If p_servidor = c_servidorcc then
     return;
   end if;
   --Hacer insert o update o delete en la sucursal
   if p_cdAccion = REPLICAS_GENERAL.GET_ACCION_INSERT then
      --Buscar la persona de la cuenta
      select p.idpersona
      into v_idPersona
      from permisos p
      where p.idpermiso = p_id;

      --Verificar que exista la cuenta del usuario
      VerificarExistaUsuario(p_servidor, v_idPersona);

      v_SQL := 'insert into permisos@' || p_servidor;
      v_SQL := v_SQL || ' (select * from permisos where idpermiso  =''' || p_id ||''')';

   elsif p_cdAccion = REPLICAS_GENERAL.GET_ACCION_UPDATE then
      v_Campos := GetCamposTabla('permisos');
      v_SQL := 'update permisos@' || p_servidor || ' set ';
      v_SQL := v_SQL || ' ('|| v_Campos ||') =  (select '|| v_Campos ||' from permisos where idpermiso  =''' || p_id ||''')';
      v_SQL := v_SQL || ' where idpermiso  =''' || p_id ||'''';

   else
      v_SQL := 'delete permisos@' || p_servidor;
      v_SQL := v_SQL || ' where idpermiso  =''' || p_id ||'''';

   end if;

   execute immediate v_SQL;

   p_ok := 1;
   return;

exception when others then
   GrabarLog(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM ||' suc: '||p_servidor||' id: '||p_id);
end LlevarPermisos;

/**************************************************************************************************
* Replica la tabla GrupoTareas hacia la sucursal
* %v 14/01/2016 - MarianoL
***************************************************************************************************/
procedure LlevarGrupoTareas(p_servidor in  sucursales.servidor%type,
                            p_cdAccion in  varchar2,
                            p_id       in  varchar2,
                            p_ok       out INTEGER)
is
   v_modulo           varchar2(100) := 'PKG_REPLICA_SUC.LlevarGrupoTareas';
   v_SQL              varchar2(4000);
   v_Campos           varchar2(4000);

begin

   p_ok := 0;

   --Hacer insert o update o delete en la sucursal
   if p_cdAccion = REPLICAS_GENERAL.GET_ACCION_INSERT then
      v_SQL := 'insert into grupotareas@' || p_servidor;
      v_SQL := v_SQL || ' (select * from grupotareas where nmgrupotarea  =''' || p_id ||''')';

   elsif p_cdAccion = REPLICAS_GENERAL.GET_ACCION_UPDATE then
      v_Campos := GetCamposTabla('grupotareas');
      v_SQL := 'update grupotareas@' || p_servidor || ' set ';
      v_SQL := v_SQL || ' ('|| v_Campos ||') =  (select '|| v_Campos ||' from grupotareas where nmgrupotarea  =''' || p_id ||''')';
      v_SQL := v_SQL || ' where nmgrupotarea  =''' || p_id ||'''';

   else
      v_SQL := 'delete grupotareas@' || p_servidor;
      v_SQL := v_SQL || ' where nmgrupotarea  =''' || p_id ||'''';

   end if;

   execute immediate v_SQL;

   p_ok := 1;
   return;

exception when others then
   GrabarLog(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM ||' suc: '||p_servidor||' id: '||p_id);
end LlevarGrupoTareas;

/**************************************************************************************************
* Replica la tabla Tareas hacia la sucursal
* %v 14/01/2016 - MarianoL
***************************************************************************************************/
procedure LlevarTareas(p_servidor in  sucursales.servidor%type,
                       p_cdAccion in  varchar2,
                       p_id       in  varchar2,
                       p_ok       out INTEGER)
is
   v_modulo           varchar2(100) := 'PKG_REPLICA_SUC.LlevarTareas';
   v_SQL              varchar2(4000);
   v_Campos           varchar2(4000);

begin

   p_ok := 0;

   --Hacer insert o update o delete en la sucursal
   if p_cdAccion = REPLICAS_GENERAL.GET_ACCION_INSERT then
      v_SQL := 'insert into tareas@' || p_servidor;
      v_SQL := v_SQL || ' (select * from tareas where nmtarea  =''' || p_id ||''')';

   elsif p_cdAccion = REPLICAS_GENERAL.GET_ACCION_UPDATE then
      v_Campos := GetCamposTabla('tareas');
      v_SQL := 'update tareas@' || p_servidor || ' set ';
      v_SQL := v_SQL || ' ('|| v_Campos ||') =  (select '|| v_Campos ||' from tareas where nmtarea  =''' || p_id ||''')';
      v_SQL := v_SQL || ' where nmtarea  =''' || p_id ||'''';

   else
      v_SQL := 'delete tareas@' || p_servidor;
      v_SQL := v_SQL || ' where nmtarea  =''' || p_id ||'''';

   end if;

   execute immediate v_SQL;

   p_ok := 1;
   return;

exception when others then
   GrabarLog(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM ||' suc: '||p_servidor||' id: '||p_id);
end LlevarTareas;

/**************************************************************************************************
* Replica la tabla TareasGrupoTareas hacia la sucursal
* %v 14/01/2016 - MarianoL
***************************************************************************************************/
procedure LlevarTareasGrupoTareas(p_servidor    in  sucursales.servidor%type,
                                  p_cdAccion    in  varchar2,
                                  p_id          in  varchar2,
                                  p_idCompuesto in  varchar2,
                                  p_ok          out integer )
is
   v_modulo           varchar2(100) := 'PKG_REPLICA_SUC.LlevarTareasGrupoTareas';
   v_SQL              varchar2(4000);
   v_Campos           varchar2(4000);
   v_nmGrupoTarea     tareasgrupotareas.nmgrupotarea%type;
   v_nmTarea          tareasgrupotareas.nmtarea%type;

begin
   p_ok := 0;

   --Decodificar el id compuesto en cada campo
   v_nmGrupoTarea := GetIdPorPosicion(p_idCompuesto,1);
   v_nmTarea      := GetIdPorPosicion(p_idCompuesto,2);

   --Hacer insert o update en la sucursal
   if p_cdAccion = REPLICAS_GENERAL.GET_ACCION_INSERT then
      v_SQL := 'insert into tareasgrupotareas@' || p_servidor;
      v_SQL := v_SQL || ' (select * from tareasgrupotareas where nmgrupotarea='''||v_nmGrupoTarea||''' and nmtarea='''||v_nmTarea||''')';

   elsif p_cdAccion = REPLICAS_GENERAL.GET_ACCION_UPDATE then
      v_Campos := GetCamposTabla('tareasgrupotareas');
      v_SQL := 'update tareasgrupotareas@' || p_servidor || ' set ';
      v_SQL := v_SQL || ' ('|| v_Campos ||') =  (select '|| v_Campos ||' from tareasgrupotareas where nmgrupotarea='''||v_nmGrupoTarea||''' and nmtarea='''||v_nmTarea||''')';
      v_SQL := v_SQL || ' where nmgrupotarea='''||v_nmGrupoTarea||''' and nmtarea='''||v_nmTarea||'''';

   else
      v_SQL := 'delete tareasgrupotareas@' || p_servidor;
      v_SQL := v_SQL || ' where nmgrupotarea='''||v_nmGrupoTarea||''' and nmtarea='''||v_nmTarea||'''';

   end if;

   execute immediate v_SQL;

   p_ok := 1;
   return;

exception when others then
   GrabarLog(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM ||' suc: '||p_servidor||' id: '||p_id||' SQL: '|| v_SQL);
end LlevarTareasGrupoTareas;

/**************************************************************************************************
* Replica la tabla CuentasUsuarios hacia la sucursal
* %v 27/10/2014 - MarianoL
***************************************************************************************************/
procedure LlevarCuentasUsuarios(p_servidor in  sucursales.servidor%type,
                                p_cdAccion in  varchar2,
                                p_id       in  varchar2,
                                p_ok       out INTEGER)
is
   v_modulo           varchar2(100) := 'PKG_REPLICA_SUC.LlevarCuentasUsuarios';
   v_SQL              varchar2(4000);
   v_Campos           varchar2(4000);

begin

   p_ok := 0;

   --Hacer insert o update o delete en la sucursal
   if p_cdAccion = REPLICAS_GENERAL.GET_ACCION_INSERT then
      v_SQL := 'insert into cuentasusuarios@' || p_servidor;
      v_SQL := v_SQL || ' (select * from cuentasusuarios where idpersona  =''' || p_id ||''')';

   elsif p_cdAccion = REPLICAS_GENERAL.GET_ACCION_UPDATE then
      v_Campos := GetCamposTabla('cuentasusuarios');
      v_SQL := 'update cuentasusuarios@' || p_servidor || ' set ';
      v_SQL := v_SQL || ' ('|| v_Campos ||') =  (select '|| v_Campos ||' from cuentasusuarios where idpersona  =''' || p_id ||''')';
      v_SQL := v_SQL || ' where idpersona  =''' || p_id ||'''';

   else
      v_SQL := 'delete cuentasusuarios@' || p_servidor;
      v_SQL := v_SQL || ' where idpersona  =''' || p_id ||'''';

   end if;

   execute immediate v_SQL;

   p_ok := 1;
   return;

exception when others then
   GrabarLog(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM ||' suc: '||p_servidor||' id: '||p_id);
end LlevarCuentasUsuarios;

/**************************************************************************************************
* Replica la tabla entidades hacia la sucursal
* %v 18/11/2015 - MarianoL
***************************************************************************************************/
procedure LlevarEntidades(p_servidor in  sucursales.servidor%type,
                          p_cdAccion in  varchar2,
                          p_id       in  varchar2,
                          p_ok       out integer )
is
   v_modulo           varchar2(100) := 'PKG_REPLICA_SUC.LlevarEntidades';
   v_SQL              varchar2(4000);
   v_Campos           varchar2(4000);
begin

   p_ok := 0;

   --Hacer insert o update en la sucursal
   if p_cdAccion = REPLICAS_GENERAL.GET_ACCION_INSERT then
      v_SQL := 'insert into entidades@' || p_servidor;
      v_SQL := v_SQL || ' (select * from entidades where identidad =''' || p_id ||''')';

   elsif p_cdAccion = REPLICAS_GENERAL.GET_ACCION_UPDATE then
      --Verificar si existe la entidad, sino insertarla
      VerificarExistaEntidad(p_servidor, p_id);

      v_Campos := GetCamposTabla('entidades');
      v_SQL := 'update entidades@' || p_servidor || ' set ';
      v_SQL := v_SQL || ' ('|| v_Campos ||') =  (select '|| v_Campos ||' from entidades where identidad =''' || p_id ||''')';
      v_SQL := v_SQL || ' where identidad =''' || p_id ||'''';

   end if;

   execute immediate v_SQL;

   p_ok := 1;
   return;

exception when others then
   GrabarLog(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM ||' suc: '||p_servidor||' id: '||p_id);
end LlevarEntidades;

/**************************************************************************************************
* Replica la tabla infoimpuestosentidades hacia la sucursal
* %v 18/11/2015 - MarianoL
***************************************************************************************************/
procedure LlevarInfoImpuestosEntidades(p_servidor in  sucursales.servidor%type,
                                       p_cdAccion in  varchar2,
                                       p_id       in  varchar2,
                                       p_ok       out integer )
is
   v_modulo           varchar2(100) := 'PKG_REPLICA_SUC.LlevarInfoImpuestosEntidades';
   v_SQL              varchar2(4000);
   v_Campos           varchar2(4000);
begin

   p_ok := 0;

   --Verificar si existe la entidad, sino insertarla
   VerificarExistaEntidad(p_servidor, p_id);

   --Hacer insert o update en la sucursal
   if p_cdAccion = REPLICAS_GENERAL.GET_ACCION_INSERT then
      v_SQL := 'insert into infoimpuestosentidades@' || p_servidor;
      v_SQL := v_SQL || ' (select * from infoimpuestosentidades where identidad =''' || p_id ||''')';

   elsif p_cdAccion = REPLICAS_GENERAL.GET_ACCION_UPDATE then
      v_Campos := GetCamposTabla('infoimpuestosentidades');
      v_SQL := 'update infoimpuestosentidades@' || p_servidor || ' set ';
      v_SQL := v_SQL || ' ('|| v_Campos ||') =  (select '|| v_Campos ||' from infoimpuestosentidades where identidad =''' || p_id ||''')';
      v_SQL := v_SQL || ' where identidad =''' || p_id ||'''';

   else
      v_SQL := 'delete infoimpuestosentidades@' || p_servidor;
      v_SQL := v_SQL || ' where identidad  =''' || p_id ||'''';

   end if;

   execute immediate v_SQL;

   p_ok := 1;
   return;

exception when others then
   GrabarLog(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM ||' suc: '||p_servidor||' id: '||p_id);
end LlevarInfoImpuestosEntidades;

/**************************************************************************************************
* Replica la tabla tjclientescf hacia la sucursal
* %v 18/11/2015 - MarianoL
***************************************************************************************************/
procedure LlevarTarjetasEntidades(p_servidor in  sucursales.servidor%type,
                                  p_cdAccion in  varchar2,
                                  p_id       in  varchar2,
                                  p_ok       out integer )
is
   v_modulo           varchar2(100) := 'PKG_REPLICA_SUC.LlevarTarjetasEntidades';
   v_SQL              varchar2(4000);
   v_Campos           varchar2(4000);
   v_idPersona1       personas.idpersona%type;
   v_idPersona2       personas.idpersona%type;
begin

   p_ok := 0;

   --Verificar si existe la entidad, sino insertarla
   VerificarExistaEntidad(p_servidor, p_id);

   begin
      --Buscar las personas
      select t.idpersonaresponsable, t.idpersona
      into v_idPersona1, v_idPersona2
      from tjclientescf t
      where t.identidad = p_id;

      --Verificar si existe la persona, sino insertarla
      VerificarExistaPersona(p_servidor, v_idPersona1);
      VerificarExistaPersona(p_servidor, v_idPersona2);

   exception when others then
      null;
   end;

   --Hacer insert o update en la sucursal
   if p_cdAccion = REPLICAS_GENERAL.GET_ACCION_INSERT then
      v_SQL := 'insert into tjclientescf@' || p_servidor;
      v_SQL := v_SQL || ' (select * from tjclientescf where identidad =''' || p_id ||''')';

   elsif p_cdAccion = REPLICAS_GENERAL.GET_ACCION_UPDATE then
      v_Campos := GetCamposTabla('tjclientescf');
      v_SQL := 'update tjclientescf@' || p_servidor || ' set ';
      v_SQL := v_SQL || ' ('|| v_Campos ||') =  (select '|| v_Campos ||' from tjclientescf where identidad =''' || p_id ||''')';
      v_SQL := v_SQL || ' where identidad =''' || p_id ||'''';

   else
      v_SQL := 'delete tjclientescf@' || p_servidor;
      v_SQL := v_SQL || ' where idpersona  =''' || p_id ||'''';

   end if;

   execute immediate v_SQL;

   p_ok := 1;
   return;

exception when others then
   GrabarLog(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM ||' suc: '||p_servidor||' id: '||p_id);
end LlevarTarjetasEntidades;

/**************************************************************************************************
* Replica la tabla rolesentidades hacia la sucursal
* %v 15/12/2015 - MarianoL
***************************************************************************************************/
procedure LlevarRolesEntidades(p_servidor    in  sucursales.servidor%type,
                               p_cdAccion    in  varchar2,
                               p_id          in  varchar2,
                               p_idCompuesto in  varchar2,
                               p_ok          out integer )
is
   v_modulo           varchar2(100) := 'PKG_REPLICA_SUC.LlevarRolesEntidades';
   v_SQL              varchar2(4000);
   v_Campos           varchar2(4000);
   v_idEntidad        rolesentidades.identidad%type;
   v_cdRol            rolesentidades.cdrol%type;

begin
   p_ok := 0;

   --Decodificar el id compuesto en cada campo
   v_idEntidad := GetIdPorPosicion(p_idCompuesto,1);
   v_cdRol     := GetIdPorPosicion(p_idCompuesto,2);

   --Verificar si existe la entidad, sino insertarla
   VerificarExistaEntidad(p_servidor, v_idEntidad);

   --Hacer insert o update en la sucursal
   if p_cdAccion = REPLICAS_GENERAL.GET_ACCION_INSERT then
      v_SQL := 'insert into rolesentidades@' || p_servidor;
      v_SQL := v_SQL || ' (select * from rolesentidades where identidad='''||v_idEntidad||''' and cdrol='''||v_cdRol||''')';

   elsif p_cdAccion = REPLICAS_GENERAL.GET_ACCION_UPDATE then
      v_Campos := GetCamposTabla('rolesentidades');
      v_SQL := 'update rolesentidades@' || p_servidor || ' set ';
      v_SQL := v_SQL || ' ('|| v_Campos ||') =  (select '|| v_Campos ||' from rolesentidades where identidad='''||v_idEntidad||''' and cdrol='''||v_cdRol||''')';
      v_SQL := v_SQL || ' where identidad='''||v_idEntidad||''' and cdrol='''||v_cdRol||'''';

   else
      v_SQL := 'delete rolesentidades@' || p_servidor;
      v_SQL := v_SQL || ' where identidad='''||v_idEntidad||''' and cdrol='''||v_cdRol||'''';

   end if;

   execute immediate v_SQL;

   p_ok := 1;
   return;

exception when others then
   GrabarLog(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM ||' suc: '||p_servidor||' id: '||p_id||' SQL: '|| v_SQL);
end LlevarRolesEntidades;

/**************************************************************************************************
* Replica la tabla contactosentidades hacia la sucursal
* %v 15/12/2015 - MarianoL
* %v 08/08/2016 RicardoC, se incluye nuevamente cdformadecontacto en clave compuesta
*               - Se modifica para Insert, Update, Delete
***************************************************************************************************/
procedure LlevarContactosEntidades(p_servidor    in  sucursales.servidor%type,
                                   p_cdAccion    in  varchar2,
                                   p_id          in  varchar2,
                                   p_idCompuesto in  varchar2,
                                   p_ok          out integer )
is
   v_modulo            varchar2(100) := 'PKG_REPLICA_SUC.LlevarContactosEntidades';
   v_SQL               varchar2(4000);
   v_Campos            varchar2(4000);
   v_idEntidad         contactosentidades.identidad%type;
   v_cdFormaContacto   contactosentidades.cdformadecontacto%type;
   v_sqContactoEntidad contactosentidades.sqcontactoentidad%type;


begin
   p_ok := 0;

   --Decodificar el id compuesto en cada campo
   v_idEntidad         := GetIdPorPosicion(p_idCompuesto,1);
   v_cdFormaContacto   := GetIdPorPosicion(p_idCompuesto,2); --No usar más porque la aplicación cambia este dato!!!
   v_sqContactoEntidad := GetIdPorPosicion(p_idCompuesto,3);

   --Verificar si existe la entidad, sino insertarla
   VerificarExistaEntidad(p_servidor, v_idEntidad);

   --Hacer insert o update en la sucursal
   if p_cdAccion = REPLICAS_GENERAL.GET_ACCION_INSERT then
      v_SQL := 'insert into contactosentidades@' || p_servidor;
      v_SQL := v_SQL || ' (select * from contactosentidades where identidad='''||v_idEntidad||''' and cdformadecontacto='''||v_cdFormaContacto
                     ||''' and sqcontactoentidad='||v_sqContactoEntidad||')';

   elsif p_cdAccion = REPLICAS_GENERAL.GET_ACCION_UPDATE then
      v_Campos := GetCamposTabla('contactosentidades');
      v_SQL := 'update contactosentidades@' || p_servidor || ' set ';

/*      v_SQL := v_SQL || ' ('|| v_Campos ||') =  (select '|| v_Campos
                     ||' from contactosentidades where identidad='''||v_idEntidad||''' and sqcontactoentidad='||v_sqContactoEntidad||')';*/

      v_SQL := v_SQL || ' ('|| v_Campos ||') =  (select '|| v_Campos
                     ||' from contactosentidades where identidad='''||v_idEntidad||''' and cdformadecontacto='''
                     ||v_cdFormaContacto||''' and sqcontactoentidad='||v_sqContactoEntidad||')';

      v_SQL := v_SQL || ' where identidad='''||v_idEntidad||''' and cdformadecontacto='''||v_cdFormaContacto
                     ||''' and sqcontactoentidad='||v_sqContactoEntidad;

   else
      v_SQL := 'delete contactosentidades@' || p_servidor;
      v_SQL := v_SQL || ' where identidad='''||v_idEntidad
            ||''' and cdformadecontacto='''||v_cdFormaContacto
            ||''' and sqcontactoentidad='||v_sqContactoEntidad;

   end if;

   execute immediate v_SQL;

   p_ok := 1;
   return;

exception when others then
   GrabarLog(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM ||' suc: '||p_servidor||' id: '||p_id||' SQL: '|| v_SQL);
end LlevarContactosEntidades;

/**************************************************************************************************
* Replica la tabla contactosentidades hacia la sucursal
* %v 15/12/2015 - MarianoL
***************************************************************************************************/
procedure LlevarDireccionesEntidades(p_servidor    in  sucursales.servidor%type,
                                     p_cdAccion    in  varchar2,
                                     p_id          in  varchar2,
                                     p_idCompuesto in  varchar2,
                                     p_ok          out integer )
is
   v_modulo          varchar2(100) := 'PKG_REPLICA_SUC.LlevarDireccionesEntidades';
   v_SQL             varchar2(4000);
   v_Campos          varchar2(4000);
   v_idEntidad       direccionesentidades.identidad%type;
   v_cdTipoDireccion direccionesentidades.cdtipodireccion%type;
   v_sqDireccion     direccionesentidades.sqdireccion%type;


begin
   p_ok := 0;

   --Decodificar el id compuesto en cada campo
   v_idEntidad       := GetIdPorPosicion(p_idCompuesto,1);
   v_cdTipoDireccion := GetIdPorPosicion(p_idCompuesto,2);
   v_sqDireccion     := GetIdPorPosicion(p_idCompuesto,3);

   --Verificar si existe la entidad, sino insertarla
   VerificarExistaEntidad(p_servidor, v_idEntidad);

   --Hacer insert o update en la sucursal
   if p_cdAccion = REPLICAS_GENERAL.GET_ACCION_INSERT then
      v_SQL := 'insert into direccionesentidades@' || p_servidor;
      v_SQL := v_SQL || ' (select * from direccionesentidades where identidad='''||v_idEntidad||
               ''' and cdtipodireccion='''||v_cdTipoDireccion||''' and sqdireccion='||v_sqDireccion||')';

   elsif p_cdAccion = REPLICAS_GENERAL.GET_ACCION_UPDATE then
      v_Campos := GetCamposTabla('direccionesentidades');
      v_SQL := 'update direccionesentidades@' || p_servidor || ' set ';
      v_SQL := v_SQL || ' ('|| v_Campos ||') =  (select '|| v_Campos ||' from direccionesentidades where identidad='''||v_idEntidad||''' and cdtipodireccion='''||v_cdTipoDireccion||''' and sqdireccion='||v_sqDireccion||')';
      v_SQL := v_SQL || ' where identidad='''||v_idEntidad||''' and cdtipodireccion='''||v_cdTipoDireccion||''' and sqdireccion='||v_sqDireccion;

   else
      v_SQL := 'delete direccionesentidades@' || p_servidor;
      v_SQL := v_SQL || ' where identidad='''||v_idEntidad||''' and cdtipodireccion='''||v_cdTipoDireccion||''' and sqdireccion='||v_sqDireccion;

   end if;

   execute immediate v_SQL;

   p_ok := 1;
   return;

exception when others then
   GrabarLog(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM ||' suc: '||p_servidor||' id: '||p_id||' SQL: '|| v_SQL);
end LlevarDireccionesEntidades;

/**************************************************************************************************
* Replica la tabla acumcfvital hacia la sucursal
* %v 15/12/2015 - MarianoL
* %v 11/09/2018 - IAquilano - Evito replicar a cc
***************************************************************************************************/
procedure LlevarAcumCfVital(p_servidor    in  sucursales.servidor%type,
                            p_cdAccion    in  varchar2,
                            p_id          in  varchar2,
                            p_idCompuesto in  varchar2,
                            p_ok          out integer )
is
   v_modulo          varchar2(100) := 'PKG_REPLICA_SUC.LlevarAcumCfVital';
   v_SQL             varchar2(4000);
   v_Campos          varchar2(4000);
   v_idPersona       acumcfvital.idpersona%type;
   v_cdSucursal      acumcfvital.cdsucursal%type;
   v_dtAcumulado     varchar2(100);

begin
   p_ok := 0;
   --Controlo servidor, si es cc no hago nada
   If p_servidor = c_servidorcc then
     return;
   end if;
   --Decodificar el id compuesto en cada campo
   v_idPersona   := GetIdPorPosicion(p_idCompuesto,1);
   v_cdSucursal  := GetIdPorPosicion(p_idCompuesto,2);
   v_dtAcumulado := 'to_date('''||GetIdPorPosicion(p_idCompuesto,3)||''',''dd/mm/yyyy'')';

   --Verificar si existe la entidad, sino insertarla
   VerificarExistaPersona(p_servidor, v_idPersona);

   --Hacer insert o update en la sucursal
   if p_cdAccion = REPLICAS_GENERAL.GET_ACCION_INSERT then
      v_SQL := 'insert into acumcfvital@' || p_servidor;
      v_SQL := v_SQL || ' (select * from acumcfvital where idpersona='''||v_idPersona||
               ''' and cdsucursal='''||v_cdSucursal||''' and dtyearmonth ='||v_dtAcumulado||')';

   elsif p_cdAccion = REPLICAS_GENERAL.GET_ACCION_UPDATE then
      v_Campos := GetCamposTabla('acumcfvital');
      v_SQL := 'update acumcfvital@' || p_servidor || ' set ';
      v_SQL := v_SQL || ' ('|| v_Campos ||') =  (select '|| v_Campos ||' from acumcfvital where idpersona='''||v_idPersona||''' and cdsucursal='''||v_cdSucursal||''' and dtyearmonth='||v_dtAcumulado||')';
      v_SQL := v_SQL || ' where idpersona='''||v_idPersona||''' and cdsucursal='''||v_cdSucursal||''' and dtyearmonth='||v_dtAcumulado;

   else
      v_SQL := 'delete acumcfvital@' || p_servidor;
      v_SQL := v_SQL || ' where idpersona='''||v_idPersona||''' and cdsucursal='''||v_cdSucursal||''' and dtyearmonth='||v_dtAcumulado;

   end if;

   execute immediate v_SQL;

   p_ok := 1;
   return;

exception when others then
   GrabarLog(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM ||' suc: '||p_servidor||' id: '||p_id||' SQL: '|| v_SQL);
end LlevarAcumCfVital;

/**************************************************************************************************
* Replica la tabla Personas hacia la sucursal
* %v 14/01/2016 - MarianoL
***************************************************************************************************/
procedure LlevarPersonas(p_servidor in  sucursales.servidor%type,
                         p_cdAccion in  varchar2,
                         p_id       in  varchar2,
                         p_ok       out INTEGER)
is
   v_modulo           varchar2(100) := 'PKG_REPLICA_SUC.LlevarPersonas';
   v_SQL              varchar2(4000):= NULL;
   v_Campos           varchar2(4000);

begin

   p_ok := 0;


   VerificarExistaPersona(p_servidor, p_id);

   --Hacer insert o update o delete en la sucursal
   if p_cdAccion = REPLICAS_GENERAL.GET_ACCION_INSERT then
      null;  --No hay que hacer nada porque el VerificarExistePersona si no existe lo inserta
--      v_SQL := 'insert into personas@' || p_servidor;
--      v_SQL := v_SQL || ' (select * from personas where idpersona  =''' || p_id ||''')';

   elsif p_cdAccion = REPLICAS_GENERAL.GET_ACCION_UPDATE then
      v_Campos := GetCamposTabla('personas');
      v_SQL := 'update personas@' || p_servidor || ' set ';
      v_SQL := v_SQL || ' ('|| v_Campos ||') =  (select '|| v_Campos ||' from personas where idpersona  =''' || p_id ||''')';
      v_SQL := v_SQL || ' where idpersona  =''' || p_id ||'''';

   else
      v_SQL := 'delete personas@' || p_servidor;
      v_SQL := v_SQL || ' where idpersona =''' || p_id ||'''';

   end if;

   if v_SQL is not null then
      execute immediate v_SQL;
   end if;

   p_ok := 1;
   return;

exception when others then
   GrabarLog(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM ||' suc: '||p_servidor||' id: '||p_id);
end LlevarPersonas;


/**************************************************************************************************
* Replica la tabla Roles hacia la sucursal
* %v 14/01/2016 - MarianoL
***************************************************************************************************/
procedure LlevarRoles(p_servidor in  sucursales.servidor%type,
                      p_cdAccion in  varchar2,
                      p_id       in  varchar2,
                      p_ok       out INTEGER)
is
   v_modulo           varchar2(100) := 'PKG_REPLICA_SUC.LlevarRoles';
   v_SQL              varchar2(4000);
   v_Campos           varchar2(4000);

begin
   p_ok := 0;

   --Hacer insert o update o delete en la sucursal
   if p_cdAccion = REPLICAS_GENERAL.GET_ACCION_INSERT then
      v_SQL := 'insert into roles@' || p_servidor;
      v_SQL := v_SQL || ' (select * from roles where cdrol  =''' || p_id ||''')';

   elsif p_cdAccion = REPLICAS_GENERAL.GET_ACCION_UPDATE then
      v_Campos := GetCamposTabla('roles');
      v_SQL := 'update roles@' || p_servidor || ' set ';
      v_SQL := v_SQL || ' ('|| v_Campos ||') =  (select '|| v_Campos ||' from roles where cdrol  =''' || p_id ||''')';
      v_SQL := v_SQL || ' where cdrol  =''' || p_id ||'''';

   else
      v_SQL := 'delete roles@' || p_servidor;
      v_SQL := v_SQL || ' where cdrol =''' || p_id ||'''';

   end if;

   execute immediate v_SQL;

   p_ok := 1;
   return;

exception when others then
   GrabarLog(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM ||' suc: '||p_servidor||' id: '||p_id);
end LlevarRoles;

/**************************************************************************************************
* Replica la tabla rolespersonas hacia la sucursal
* %v 14/01/2016 - MarianoL
* %v 11/09/2018 - IAquilano - Evito replicar a cc
***************************************************************************************************/
procedure LlevarRolesPersonas(p_servidor    in  sucursales.servidor%type,
                              p_cdAccion    in  varchar2,
                              p_id          in  varchar2,
                              p_idCompuesto in  varchar2,
                              p_ok          out integer )
is
   v_modulo          varchar2(100) := 'PKG_REPLICA_SUC.LlevarRolesPersonas';
   v_SQL             varchar2(4000);
   v_Campos          varchar2(4000);
   v_cdRol           rolespersonas.cdrol%type;
   v_idPersona       rolespersonas.idpersona%type;

begin
   p_ok := 0;
   --Controlo servidor, si es cc no hago nada
   If p_servidor = c_servidorcc then
     return;
   end if;
   --Decodificar el id compuesto en cada campo
   v_cdRol     := GetIdPorPosicion(p_idCompuesto,1);
   v_idPersona := GetIdPorPosicion(p_idCompuesto,2);

   --Verificar si existe la entidad, sino insertarla
   VerificarExistaPersona(p_servidor, v_idPersona);

   --Hacer insert o update en la sucursal
   if p_cdAccion = REPLICAS_GENERAL.GET_ACCION_INSERT then
      v_SQL := 'insert into rolespersonas@' || p_servidor;
      v_SQL := v_SQL || ' (select * from rolespersonas where cdrol='''||v_cdRol||
               ''' and idpersona='''||v_idPersona||''')';

   elsif p_cdAccion = REPLICAS_GENERAL.GET_ACCION_UPDATE then
      v_Campos := GetCamposTabla('rolespersonas');
      v_SQL := 'update rolespersonas@' || p_servidor || ' set ';
      v_SQL := v_SQL || ' ('|| v_Campos ||') =  (select '|| v_Campos ||' from rolespersonas where cdrol='''||v_cdRol||''' and idpersona='''||v_idPersona||''')';
      v_SQL := v_SQL || ' where cdrol='''||v_cdRol||''' and idpersona='''||v_idPersona||'''';

   else
      v_SQL := 'delete rolespersonas@' || p_servidor;
      v_SQL := v_SQL || ' where cdrol='''||v_cdRol||''' and idpersona='''||v_idPersona||'''';

   end if;

   execute immediate v_SQL;

   p_ok := 1;
   return;

exception when others then
   GrabarLog(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM ||' suc: '||p_servidor||' id: '||p_id||' SQL: '|| v_SQL);
end LlevarRolesPersonas;

/**************************************************************************************************
* Replica la tabla tblDocumentoDeuda hacia la sucursal
* %v 02/03/2016 - JBodnar
* %v 11/09/2018 - IAquilano - Evito replicar a cc
***************************************************************************************************/
procedure LlevarDocumentoDeuda(p_servidor in  sucursales.servidor%type,
                               p_cdAccion in  varchar2,
                               p_id       in  varchar2,
                               p_ok       out integer )
is
   v_modulo           varchar2(100) := 'PKG_REPLICA_SUC.LlevarDocumentoDeuda';
   v_SQL              varchar2(4000);
   v_Campos           varchar2(4000);

begin
   p_ok := 0;
   --Controlo servidor, si es cc no hago nada
   If p_servidor = c_servidorcc then
     return;
   end if;
   --Hacer insert o update en la sucursal
   if p_cdAccion = REPLICAS_GENERAL.GET_ACCION_INSERT then
      v_SQL := 'insert into tbldocumentodeuda@' || p_servidor;
      v_SQL := v_SQL || ' (select * from tbldocumentodeuda c where c.iddocumentodeuda =''' || p_id ||''')';

   elsif p_cdAccion = REPLICAS_GENERAL.GET_ACCION_UPDATE then
      v_Campos := GetCamposTabla('tbldocumentodeuda');
      v_SQL := 'update tbldocumentodeuda@' || p_servidor || ' set ';
      v_SQL := v_SQL || ' ('|| v_Campos ||') =  (select '|| v_Campos ||' from tbldocumentodeuda c where c.iddocumentodeuda =''' || p_id ||''')';
      v_SQL := v_SQL || ' where iddocumentodeuda =''' || p_id ||'''';

   end if;

   execute immediate v_SQL;

   p_ok := 1;
   return;

exception when others then
   GrabarLog(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM ||' suc: '||p_servidor||' id: '||p_id);

end LlevarDocumentoDeuda;

/**************************************************************************************************
* Replica la tabla tblimpacumulador hacia la sucursal
* %v 04/03/2016 - JBodnar
***************************************************************************************************/
procedure LlevarImpAcumulador(p_servidor in  sucursales.servidor%type,
                              p_cdAccion in  varchar2,
                              p_id       in  varchar2,
                              p_ok       out integer )
is
   v_modulo           varchar2(100) := 'PKG_REPLICA_SUC.LlevarImpAcumulador';
   v_SQL              varchar2(4000);
   v_Campos           varchar2(4000);
begin

   p_ok := 0;

   --Hacer insert o update en la sucursal
   if p_cdAccion = REPLICAS_GENERAL.GET_ACCION_INSERT then
      v_SQL := 'insert into tblimpacumulador@' || p_servidor;
      v_SQL := v_SQL || ' (select * from tblimpacumulador where idimpacumulador =''' || p_id ||''')';

   elsif p_cdAccion = REPLICAS_GENERAL.GET_ACCION_UPDATE then

      v_Campos := GetCamposTabla('tblimpacumulador');
      v_SQL := 'update tblimpacumulador@' || p_servidor || ' set ';
      v_SQL := v_SQL || ' ('|| v_Campos ||') =  (select '|| v_Campos ||' from tblimpacumulador where idimpacumulador  =''' || p_id ||''')';
      v_SQL := v_SQL || ' where idimpacumulador =''' || p_id ||'''';

   end if;

   execute immediate v_SQL;

   p_ok := 1;
   return;

exception when others then
   GrabarLog(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM ||' suc: '||p_servidor||' id: '||p_id);
end LlevarImpAcumulador;

/**************************************************************************************************
* Replica la tabla tbldescuentoempleado hacia la sucursal
* %v 01/06/2016 - JBodnar
***************************************************************************************************/
procedure LlevarDescuentoEmpleado (p_servidor in  sucursales.servidor%type,
                                   p_cdAccion in  varchar2,
                                   p_id       in  varchar2,
                                   p_ok       out integer )
is
   v_modulo           varchar2(100) := 'PKG_REPLICA_SUC.LlevarDescuentoEmpleado';
   v_SQL              varchar2(4000);
   v_Campos           varchar2(4000);
begin

   p_ok := 0;

   --Hacer insert o update en la sucursal
   if p_cdAccion = REPLICAS_GENERAL.GET_ACCION_INSERT then
      v_SQL := 'insert into tbldescuentoempleado@' || p_servidor;
      v_SQL := v_SQL || ' (select * from tbldescuentoempleado where iddescuentoempleado =''' || p_id ||''')';

   elsif p_cdAccion = REPLICAS_GENERAL.GET_ACCION_UPDATE then

      v_Campos := GetCamposTabla('tbldescuentoempleado');
      v_SQL := 'update tbldescuentoempleado@' || p_servidor || ' set ';
      v_SQL := v_SQL || ' ('|| v_Campos ||') =  (select '|| v_Campos ||' from tbldescuentoempleado where iddescuentoempleado  =''' || p_id ||''')';
      v_SQL := v_SQL || ' where iddescuentoempleado =''' || p_id ||'''';

   end if;

   execute immediate v_SQL;

   p_ok := 1;
   return;

exception when others then
   GrabarLog(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM ||' suc: '||p_servidor||' id: '||p_id);
end LlevarDescuentoEmpleado;

/**************************************************************************************************
* Replica la tabla tblimpexencion hacia la sucursal
* %v 04/03/2016 - JBodnar
***************************************************************************************************/
procedure LlevarImpExencion  (p_servidor in  sucursales.servidor%type,
                              p_cdAccion in  varchar2,
                              p_id       in  varchar2,
                              p_ok       out integer )
is
   v_modulo           varchar2(100) := 'PKG_REPLICA_SUC.LlevarImpExencion';
   v_SQL              varchar2(4000);
   v_Campos           varchar2(4000);
begin

   p_ok := 0;

   --Hacer insert o update en la sucursal
   if p_cdAccion = REPLICAS_GENERAL.GET_ACCION_INSERT then
      v_SQL := 'insert into tblimpexencion@' || p_servidor;
      v_SQL := v_SQL || ' (select * from tblimpexencion where idimpexcencion =''' || p_id ||''')';

   elsif p_cdAccion = REPLICAS_GENERAL.GET_ACCION_UPDATE then

      v_Campos := GetCamposTabla('tblimpexencion');
      v_SQL := 'update tblimpexencion@' || p_servidor || ' set ';
      v_SQL := v_SQL || ' ('|| v_Campos ||') =  (select '|| v_Campos ||' from tblimpexencion where idimpexcencion   =''' || p_id ||''')';
      v_SQL := v_SQL || ' where idimpexcencion =''' || p_id ||'''';

   end if;

   execute immediate v_SQL;

   p_ok := 1;
   return;

exception when others then
   GrabarLog(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM ||' suc: '||p_servidor||' id: '||p_id);
end LlevarImpExencion;

/**************************************************************************************************
* Replica la tabla tblEntidadAplicacion hacia la sucursal
* %v 26/10/2017 - IAquilano
* %v 11/09/2018 - IAquilano - Evito replicar a cc
***************************************************************************************************/
procedure LlevarEntidadAplicacion  (p_servidor in  sucursales.servidor%type,
                              p_cdAccion in  varchar2,
                              p_id       in  varchar2,
                              p_ok       out integer )
is
   v_modulo           varchar2(100) := 'PKG_REPLICA_SUC.LlevarEntidadAplicacion';
   v_SQL              varchar2(4000);
   v_Campos           varchar2(4000);
begin

   p_ok := 0;
   --Controlo servidor, si es cc no hago nada
   If p_servidor = c_servidorcc then
     return;
   end if;
   --Hacer insert o update en la sucursal
   if p_cdAccion = REPLICAS_GENERAL.GET_ACCION_INSERT then
      v_SQL := 'insert into tblentidadaplicacion@' || p_servidor;
      v_SQL := v_SQL || ' (select * from tblentidadaplicacion where identidadaplicacion =''' || p_id ||''')';

   elsif p_cdAccion = REPLICAS_GENERAL.GET_ACCION_UPDATE then

      v_Campos := GetCamposTabla('tblentidadaplicacion');
      v_SQL := 'update tblentidadaplicacion@' || p_servidor || ' set ';
      v_SQL := v_SQL || ' ('|| v_Campos ||') =  (select '|| v_Campos ||' from tblentidadaplicacion where identidadaplicacion   =''' || p_id ||''')';
      v_SQL := v_SQL || ' where identidadaplicacion =''' || p_id ||'''';

   end if;

   execute immediate v_SQL;

   p_ok := 1;
   return;

exception when others then
   GrabarLog(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM ||' suc: '||p_servidor||' id: '||p_id);
end LlevarEntidadAplicacion;

/**************************************************************************************************
* Replica la tabla tblimpreduccion hacia la sucursal
* %v 04/03/2016 - JBodnar
***************************************************************************************************/
procedure LlevarImpReduccion  (p_servidor in  sucursales.servidor%type,
                              p_cdAccion in  varchar2,
                              p_id       in  varchar2,
                              p_ok       out integer )
is
   v_modulo           varchar2(100) := 'PKG_REPLICA_SUC.LlevarImpReduccion';
   v_SQL              varchar2(4000);
   v_Campos           varchar2(4000);
begin

   p_ok := 0;

   --Hacer insert o update en la sucursal
   if p_cdAccion = REPLICAS_GENERAL.GET_ACCION_INSERT then
      v_SQL := 'insert into tblimpreduccion@' || p_servidor;
      v_SQL := v_SQL || ' (select * from tblimpreduccion where idreduccion =''' || p_id ||''')';

   elsif p_cdAccion = REPLICAS_GENERAL.GET_ACCION_UPDATE then

      v_Campos := GetCamposTabla('tblimpreduccion');
      v_SQL := 'update tblimpreduccion@' || p_servidor || ' set ';
      v_SQL := v_SQL || ' ('|| v_Campos ||') =  (select '|| v_Campos ||' from tblimpreduccion where idreduccion   =''' || p_id ||''')';
      v_SQL := v_SQL || ' where idreduccion =''' || p_id ||'''';

   end if;

   execute immediate v_SQL;

   p_ok := 1;
   return;

exception when others then
   GrabarLog(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM ||' suc: '||p_servidor||' id: '||p_id);
end LlevarImpReduccion;

/**************************************************************************************************
* Replica la tabla LlevarAsientoSap hacia la sucursal
* %v 29/06/2016 - MarianoL
* %v 11/09/2018 - IAquilano - Evito replicar a cc
***************************************************************************************************/
procedure LlevarAsientoSap(p_servidor in  sucursales.servidor%type,
                           p_cdAccion in  varchar2,
                           p_id       in  varchar2,
                           p_ok       out integer )
is
   v_modulo           varchar2(100) := 'PKG_REPLICA_SUC.LlevarAsientoSap';
   v_SQL              varchar2(4000);
   v_Campos           varchar2(4000);
begin

   p_ok := 0;
   --Controlo servidor, si es cc no hago nada
   If p_servidor = c_servidorcc then
     return;
   end if;
   --Hacer insert o update en la sucursal
   if p_cdAccion = REPLICAS_GENERAL.GET_ACCION_INSERT then
      v_SQL := 'insert into tblclasientosap@' || p_servidor;
      v_SQL := v_SQL || ' (select * from tblclasientosap where idclasientosap =''' || p_id ||''')';

   elsif p_cdAccion = REPLICAS_GENERAL.GET_ACCION_UPDATE then

      v_Campos := GetCamposTabla('tblclasientosap');
      v_SQL := 'update tblclasientosap@' || p_servidor || ' set ';
      v_SQL := v_SQL || ' ('|| v_Campos ||') =  (select '|| v_Campos ||' from tblclasientosap where idclasientosap =''' || p_id ||''')';
      v_SQL := v_SQL || ' where idclasientosap =''' || p_id ||'''';

   end if;

   execute immediate v_SQL;

   p_ok := 1;
   return;

exception when others then
   GrabarLog(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM ||' suc: '||p_servidor||' id: '||p_id);
end LlevarAsientoSap;

/**************************************************************************************************
* Replica la tabla tbltraspasotrans hacia la sucursal
* %v 02/08/2016 - JBodnar
* %v 11/09/2018 - IAquilano - Evito replicar a cc
***************************************************************************************************/
procedure LlevarTraspasoTrans (p_servidor in  sucursales.servidor%type,
                               p_cdAccion in  varchar2,
                               p_id       in  varchar2,
                               p_ok       out integer )
is
   v_modulo           varchar2(100) := 'PKG_REPLICA_SUC.LlevarTraspasoTrans';
   v_SQL              varchar2(4000);
   v_Campos           varchar2(4000);
begin

   p_ok := 0;
   --Controlo servidor, si es cc no hago nada
   If p_servidor = c_servidorcc then
     return;
   end if;
   --Hacer insert o update en la sucursal
   if p_cdAccion = REPLICAS_GENERAL.GET_ACCION_INSERT then
      v_SQL := 'insert into tbltraspasotrans@' || p_servidor;
      v_SQL := v_SQL || ' (select * from tbltraspasotrans where idtraspasotrans =''' || p_id ||''')';

   elsif p_cdAccion = REPLICAS_GENERAL.GET_ACCION_UPDATE then

      v_Campos := GetCamposTabla('tbltraspasotrans');
      v_SQL := 'update tbltraspasotrans@' || p_servidor || ' set ';
      v_SQL := v_SQL || ' ('|| v_Campos ||') =  (select '|| v_Campos ||' from tbltraspasotrans where idtraspasotrans =''' || p_id ||''')';
      v_SQL := v_SQL || ' where idtraspasotrans =''' || p_id ||'''';

   end if;

   execute immediate v_SQL;

   p_ok := 1;
   return;

exception when others then
   GrabarLog(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM ||' suc: '||p_servidor||' id: '||p_id);
end LlevarTraspasoTrans;

/**************************************************************************************************
* Replica la tabla tblreclamoposnet hacia la sucursal
* %v 24/04/2017 - JBodnar
* %v 11/09/2018 - IAquilano - Evito replicar a cc
***************************************************************************************************/
procedure LlevarReclamoPosnet (p_servidor in  sucursales.servidor%type,
                               p_cdAccion in  varchar2,
                               p_id       in  varchar2,
                               p_ok       out integer )
is
   v_modulo           varchar2(100) := 'PKG_REPLICA_SUC.LlevarReclamoPosnet';
   v_SQL              varchar2(4000);
   v_Campos           varchar2(4000);
begin

   p_ok := 0;
   --Controlo servidor, si es cc no hago nada
   If p_servidor = c_servidorcc then
     return;
   end if;
   --Hacer insert o update en la sucursal
   if p_cdAccion = REPLICAS_GENERAL.GET_ACCION_INSERT then
      v_SQL := 'insert into tblreclamoposnet@' || p_servidor;
      v_SQL := v_SQL || ' (select * from tblreclamoposnet where idreclamo =''' || p_id ||''')';

   elsif p_cdAccion = REPLICAS_GENERAL.GET_ACCION_UPDATE then

      v_Campos := GetCamposTabla('tblreclamoposnet');
      v_SQL := 'update tblreclamoposnet@' || p_servidor || ' set ';
      v_SQL := v_SQL || ' ('|| v_Campos ||') =  (select '|| v_Campos ||' from tblreclamoposnet where idreclamo =''' || p_id ||''')';
      v_SQL := v_SQL || ' where idreclamo =''' || p_id ||'''';

   end if;

   execute immediate v_SQL;

   p_ok := 1;
   return;

exception when others then
   GrabarLog(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM ||' suc: '||p_servidor||' id: '||p_id);
end LlevarReclamoPosnet;

/**************************************************************************************************
* Replica la tabla tblreclamoobservacion hacia la sucursal
* %v 24/04/2017 - JBodnar
* %v 11/09/2018 - IAquilano - Evito replicar a cc
***************************************************************************************************/
procedure LlevarReclamoObservacion (p_servidor in  sucursales.servidor%type,
                                    p_cdAccion in  varchar2,
                                    p_id       in  varchar2,
                                    p_ok       out integer )
is
   v_modulo           varchar2(100) := 'PKG_REPLICA_SUC.LlevarReclamoObservacion';
   v_SQL              varchar2(4000);
   v_Campos           varchar2(4000);
begin

   p_ok := 0;
   --Controlo servidor, si es cc no hago nada
   If p_servidor = c_servidorcc then
     return;
   end if;
   --Hacer insert o update en la sucursal
   if p_cdAccion = REPLICAS_GENERAL.GET_ACCION_INSERT then
      v_SQL := 'insert into tblreclamoobservacion@' || p_servidor;
      v_SQL := v_SQL || ' (select * from tblreclamoobservacion where idobservacion =''' || p_id ||''')';

   elsif p_cdAccion = REPLICAS_GENERAL.GET_ACCION_UPDATE then

      v_Campos := GetCamposTabla('tblreclamoobservacion');
      v_SQL := 'update tblreclamoobservacion@' || p_servidor || ' set ';
      v_SQL := v_SQL || ' ('|| v_Campos ||') =  (select '|| v_Campos ||' from tblreclamoobservacion where idobservacion =''' || p_id ||''')';
      v_SQL := v_SQL || ' where idobservacion =''' || p_id ||'''';

   end if;

   execute immediate v_SQL;

   p_ok := 1;
   return;

exception when others then
   GrabarLog(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM ||' suc: '||p_servidor||' id: '||p_id);
end LlevarReclamoObservacion;

/**************************************************************************************************
* Replica la tabla tblcnpresupuesto hacia la sucursal
* %v 12/07/2017 - JBodnar
* %v 11/09/2018 - IAquilano - Evito replicar a cc
***************************************************************************************************/
procedure LlevarCNpresupuesto (p_servidor in  sucursales.servidor%type,
                               p_cdAccion in  varchar2,
                               p_id       in  varchar2,
                               p_ok       out integer )
is
   v_modulo           varchar2(100) := 'PKG_REPLICA_SUC.LlevarCNpresupuesto';
   v_SQL              varchar2(4000);
   v_Campos           varchar2(4000);
begin

   p_ok := 0;
   --Controlo servidor, si es cc no hago nada
   If p_servidor = c_servidorcc then
     return;
   end if;
   --Hacer insert o update en la sucursal
   if p_cdAccion = REPLICAS_GENERAL.GET_ACCION_INSERT then
      v_SQL := 'insert into tblcnpresupuesto@' || p_servidor;
      v_SQL := v_SQL || ' (select * from tblcnpresupuesto where idcnpresupuesto =''' || p_id ||''')';

   elsif p_cdAccion = REPLICAS_GENERAL.GET_ACCION_UPDATE then

      v_Campos := GetCamposTabla('tblcnpresupuesto');
      v_SQL := 'update tblcnpresupuesto@' || p_servidor || ' set ';
      v_SQL := v_SQL || ' ('|| v_Campos ||') =  (select '|| v_Campos ||' from tblcnpresupuesto where idcnpresupuesto =''' || p_id ||''')';
      v_SQL := v_SQL || ' where idcnpresupuesto =''' || p_id ||'''';

   end if;

   execute immediate v_SQL;

   p_ok := 1;
   return;

exception when others then
   GrabarLog(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM ||' suc: '||p_servidor||' id: '||p_id);
end LlevarCNpresupuesto;

/**************************************************************************************************
* Replica la tabla idcnpresupuestopedido hacia la sucursal
* %v 12/07/2017 - JBodnar
* %v 11/09/2018 - IAquilano - Evito replicar a cc
***************************************************************************************************/
procedure LlevarCNpresupuestopedido (p_servidor in  sucursales.servidor%type,
                               p_cdAccion in  varchar2,
                               p_id       in  varchar2,
                               p_ok       out integer )
is
   v_modulo           varchar2(100) := 'PKG_REPLICA_SUC.LlevarCNpresupuestopedido';
   v_SQL              varchar2(4000);
   v_Campos           varchar2(4000);
begin

   p_ok := 0;
   --Controlo servidor, si es cc no hago nada
   If p_servidor = c_servidorcc then
     return;
   end if;
   --Hacer insert o update en la sucursal
   if p_cdAccion = REPLICAS_GENERAL.GET_ACCION_INSERT then
      v_SQL := 'insert into tblcnpresupuestopedido@' || p_servidor;
      v_SQL := v_SQL || ' (select * from tblcnpresupuestopedido where idcnpresupuestopedido =''' || p_id ||''')';

   elsif p_cdAccion = REPLICAS_GENERAL.GET_ACCION_UPDATE then

      v_Campos := GetCamposTabla('tblcnpresupuestopedido');
      v_SQL := 'update tblcnpresupuestopedido@' || p_servidor || ' set ';
      v_SQL := v_SQL || ' ('|| v_Campos ||') =  (select '|| v_Campos ||' from tblcnpresupuestopedido where idcnpresupuestopedido =''' || p_id ||''')';
      v_SQL := v_SQL || ' where idcnpresupuestopedido =''' || p_id ||'''';

   end if;

   execute immediate v_SQL;

   p_ok := 1;
   return;

exception when others then
   GrabarLog(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM ||' suc: '||p_servidor||' id: '||p_id);
end LlevarCNpresupuestopedido;

/**************************************************************************************************
* Replica la tabla tblcnpedido hacia la sucursal
* %v 12/07/2017 - JBodnar
* %v 11/09/2018 - IAquilano - Evito replicar a cc
***************************************************************************************************/
procedure LlevarCNpedido (p_servidor in  sucursales.servidor%type,
                               p_cdAccion in  varchar2,
                               p_id       in  varchar2,
                               p_ok       out integer )
is
   v_modulo           varchar2(100) := 'PKG_REPLICA_SUC.LlevarCNpedido';
   v_SQL              varchar2(4000);
   v_Campos           varchar2(4000);
begin

   p_ok := 0;
   --Controlo servidor, si es cc no hago nada
   If p_servidor = c_servidorcc then
     return;
   end if;
   --Hacer insert o update en la sucursal
   if p_cdAccion = REPLICAS_GENERAL.GET_ACCION_INSERT then
      v_SQL := 'insert into tblcnpedido@' || p_servidor;
      v_SQL := v_SQL || ' (select * from tblcnpedido where idcnpedido =''' || p_id ||''')';

   elsif p_cdAccion = REPLICAS_GENERAL.GET_ACCION_UPDATE then

      v_Campos := GetCamposTabla('tblcnpedido');
      v_SQL := 'update tblcnpedido@' || p_servidor || ' set ';
      v_SQL := v_SQL || ' ('|| v_Campos ||') =  (select '|| v_Campos ||' from tblcnpedido where idcnpedido =''' || p_id ||''')';
      v_SQL := v_SQL || ' where idcnpedido =''' || p_id ||'''';

   end if;

   execute immediate v_SQL;

   p_ok := 1;
   return;

exception when others then
   GrabarLog(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM ||' suc: '||p_servidor||' id: '||p_id);
end LlevarCNpedido;

/**************************************************************************************************
* Replica la tabla tblcnfactura hacia la sucursal
* %v 12/07/2017 - JBodnar
* %v 11/09/2018 - IAquilano - Evito replicar a cc
***************************************************************************************************/
procedure LlevarCNfactura (p_servidor in  sucursales.servidor%type,
                               p_cdAccion in  varchar2,
                               p_id       in  varchar2,
                               p_ok       out integer )
is
   v_modulo           varchar2(100) := 'PKG_REPLICA_SUC.LlevarCNfactura';
   v_SQL              varchar2(4000);
   v_Campos           varchar2(4000);
begin

   p_ok := 0;
   --Controlo servidor, si es cc no hago nada
   If p_servidor = c_servidorcc then
     return;
   end if;
   --Hacer insert o update en la sucursal
   if p_cdAccion = REPLICAS_GENERAL.GET_ACCION_INSERT then
      v_SQL := 'insert into tblcnfactura@' || p_servidor;
      v_SQL := v_SQL || ' (select * from tblcnfactura where idcnfactura =''' || p_id ||''')';

   elsif p_cdAccion = REPLICAS_GENERAL.GET_ACCION_UPDATE then

      v_Campos := GetCamposTabla('tblcnfactura');
      v_SQL := 'update tblcnfactura@' || p_servidor || ' set ';
      v_SQL := v_SQL || ' ('|| v_Campos ||') =  (select '|| v_Campos ||' from tblcnfactura where idcnfactura =''' || p_id ||''')';
      v_SQL := v_SQL || ' where idcnfactura =''' || p_id ||'''';

   end if;

   execute immediate v_SQL;

   p_ok := 1;
   return;

exception when others then
   GrabarLog(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM ||' suc: '||p_servidor||' id: '||p_id);
end LlevarCNfactura;

/**************************************************************************************************
* Dada una sucursal comienza el proceso de replica desde AC hacia la sucursal
* %v 03/06/2014 - MarianoL
* %v 26/01/2015 - MartinM: Agrego la replicación de la tabla tblclnotadecredito
* %v 02/02/2015 - MartinM: Agrego la replicación de la tabla tblclContraCargo
* %v 23/12/2015 - MartinM: Agrego la replicación de la tabla tblguiacomisautorizasaldo
***************************************************************************************************/
procedure Llevar(p_servidor   in  sucursales.servidor%type,
                         p_Sucursal   in  sucursales.cdsucursal%type)
is
   v_modulo           varchar2(100) := 'PKG_REPLICA_SUC.LlevarSucursal';
   v_RegReplica       tblreplica%rowtype;
   v_ok               number;
   v_dtInicioProc     date := sysdate;
begin

   --Armar el query con los datos a Llevar
   for v_RegReplica in (select *
                          from (select *
                                  from tblreplica
                                 where cdestado = REPLICAS_GENERAL.estado_inicial
                                   and cdsucursal = p_Sucursal
                                 order by idreplica)
                         where rownum <= g_CantMaxLlevar)
   loop
      v_ok := 0;

      --Llevar cada registro hacia la sucursal
      if v_RegReplica.Vlnombretabla = 'tblcuenta' then
         LlevarCuenta(p_servidor, v_RegReplica.CDACCION, v_RegReplica.IDTABLA, v_ok);
      elsif v_RegReplica.Vlnombretabla = 'tblampliacioncredito' then
         LlevarAmpliacionCredito(p_servidor, v_RegReplica.CDACCION, v_RegReplica.IDTABLA, v_ok);
      elsif v_RegReplica.Vlnombretabla = 'tblposnet_transmitido' then
         LlevarPosnet_Transmitido(p_servidor, v_RegReplica.CDACCION, v_RegReplica.IDTABLA, v_ok);
      elsif v_RegReplica.Vlnombretabla = 'tblclnotadecredito' then
         LlevarCLNotaDeCredito(p_servidor, v_RegReplica.CDACCION, v_RegReplica.IDTABLA, v_ok);
      elsif v_RegReplica.Vlnombretabla = 'tblclcontracargo' then
         LlevarCLContraCargo(p_servidor, v_RegReplica.CDACCION, v_RegReplica.IDTABLA, v_ok);
      elsif v_RegReplica.Vlnombretabla = 'tblcomisionistacobrar' then
         LlevarComisionistaCobrar(p_servidor, v_RegReplica.CDACCION, v_RegReplica.IDTABLA, v_ok);
      elsif v_RegReplica.Vlnombretabla = 'tblingresoestado_ac' then
         LlevarIngresoEstadoAc(p_servidor, v_RegReplica.CDACCION, v_RegReplica.IDTABLA, v_ok);
      elsif v_RegReplica.Vlnombretabla = 'tblcontrolstock' then
         LlevarControlStock(p_servidor, v_RegReplica.CDACCION, v_RegReplica.IDTABLA, v_ok);
      elsif v_RegReplica.Vlnombretabla = 'tbldeudatrans' then
         LlevarDeudaTrans(p_servidor, v_RegReplica.CDACCION, v_RegReplica.IDTABLA, v_ok);
      elsif v_RegReplica.Vlnombretabla = 'tblguiacomischequeavalidar' then
         LlevarTMPCargaCheque(p_servidor, v_RegReplica.CDACCION, v_RegReplica.IDTABLA, v_ok);
      elsif v_RegReplica.Vlnombretabla = 'permisos' then
         LlevarPermisos(p_servidor, v_RegReplica.CDACCION, v_RegReplica.IDTABLA, v_ok);
      elsif v_RegReplica.Vlnombretabla = 'grupotareas' then
         LlevarGrupoTareas(p_servidor, v_RegReplica.CDACCION, v_RegReplica.IDTABLA, v_ok);
      elsif v_RegReplica.Vlnombretabla = 'tareas' then
         LlevarTareas(p_servidor, v_RegReplica.CDACCION, v_RegReplica.IDTABLA, v_ok);
      elsif v_RegReplica.Vlnombretabla = 'tareasgrupotareas' then
         LlevarTareasGrupoTareas(p_servidor, v_RegReplica.CDACCION, v_RegReplica.IDTABLA, v_RegReplica.Idcompuesto, v_ok);
      elsif v_RegReplica.Vlnombretabla = 'cuentasusuarios' then
         LlevarCuentasUsuarios(p_servidor, v_RegReplica.CDACCION, v_RegReplica.IDTABLA, v_ok);
      elsif v_RegReplica.Vlnombretabla = 'entidades' then
         LlevarEntidades(p_servidor, v_RegReplica.CDACCION, v_RegReplica.IDTABLA, v_ok);
      elsif v_RegReplica.Vlnombretabla = 'infoimpuestosentidades' then
         LlevarInfoImpuestosEntidades(p_servidor, v_RegReplica.CDACCION, v_RegReplica.IDTABLA, v_ok);
      elsif v_RegReplica.Vlnombretabla = 'tjclientescf' then
         LlevarTarjetasEntidades(p_servidor, v_RegReplica.CDACCION, v_RegReplica.IDTABLA, v_ok);
      elsif v_RegReplica.Vlnombretabla = 'rolesentidades' then
         LlevarRolesEntidades(p_servidor, v_RegReplica.CDACCION, v_RegReplica.IDTABLA, v_RegReplica.Idcompuesto, v_ok);
      elsif v_RegReplica.Vlnombretabla = 'contactosentidades' then
        LlevarContactosEntidades(p_servidor, v_RegReplica.CDACCION, v_RegReplica.IDTABLA, v_RegReplica.Idcompuesto, v_ok);
      elsif v_RegReplica.Vlnombretabla = 'tblguiacomisautorizasaldo' then
         LlevarGuiaComisAutorizaSaldo(p_servidor, v_RegReplica.CDACCION, v_RegReplica.IDTABLA, v_ok);
      elsif v_RegReplica.Vlnombretabla = 'direccionesentidades' then
         LlevarDireccionesEntidades(p_servidor, v_RegReplica.CDACCION, v_RegReplica.IDTABLA, v_RegReplica.Idcompuesto, v_ok);
      elsif v_RegReplica.Vlnombretabla = 'acumcfvital' then
         LlevarAcumCfVital(p_servidor, v_RegReplica.CDACCION, v_RegReplica.IDTABLA, v_RegReplica.Idcompuesto, v_ok);
      elsif v_RegReplica.Vlnombretabla = 'personas' then
         LlevarPersonas(p_servidor, v_RegReplica.CDACCION, v_RegReplica.IDTABLA, v_ok);
       elsif v_RegReplica.Vlnombretabla = 'roles' then
         LlevarRoles(p_servidor, v_RegReplica.CDACCION, v_RegReplica.IDTABLA, v_ok);
      elsif v_RegReplica.Vlnombretabla = 'rolespersonas' then
         LlevarRolesPersonas(p_servidor, v_RegReplica.CDACCION, v_RegReplica.IDTABLA, v_RegReplica.Idcompuesto, v_ok);
      elsif v_RegReplica.Vlnombretabla = 'tbldocumentodeuda' then
         LlevarDocumentoDeuda(p_servidor, v_RegReplica.CDACCION, v_RegReplica.IDTABLA, v_ok);
      elsif v_RegReplica.Vlnombretabla = 'tblimpacumulador' then
         LlevarImpAcumulador(p_servidor, v_RegReplica.CDACCION, v_RegReplica.IDTABLA, v_ok);
      elsif v_RegReplica.Vlnombretabla = 'tbldescuentoempleado' then
         LlevarDescuentoEmpleado(p_servidor, v_RegReplica.CDACCION, v_RegReplica.IDTABLA, v_ok);
      elsif v_RegReplica.Vlnombretabla = 'tblimpexencion' then
         LlevarImpExencion(p_servidor, v_RegReplica.CDACCION, v_RegReplica.IDTABLA, v_ok);
      elsif v_RegReplica.Vlnombretabla = 'tblimpreduccion' then
         LlevarImpReduccion(p_servidor, v_RegReplica.CDACCION, v_RegReplica.IDTABLA, v_ok);
      elsif v_RegReplica.Vlnombretabla = 'tblclasientosap' then
         LlevarAsientoSap(p_servidor, v_RegReplica.CDACCION, v_RegReplica.IDTABLA, v_ok);
      elsif v_RegReplica.Vlnombretabla = 'tbltraspasotrans' then
         LlevarTraspasoTrans(p_servidor, v_RegReplica.CDACCION, v_RegReplica.IDTABLA, v_ok);
      elsif v_RegReplica.Vlnombretabla = 'documentos' then
         LlevarDocumento(p_servidor, v_RegReplica.CDACCION, v_RegReplica.IDTABLA, v_ok);
      elsif v_RegReplica.Vlnombretabla = 'tblcnpresupuesto' then
         LlevarCNpresupuesto (p_servidor, v_RegReplica.CDACCION, v_RegReplica.IDTABLA, v_ok);
      elsif v_RegReplica.Vlnombretabla = 'tblcnpresupuestopedido' then
         LlevarCNpresupuestopedido (p_servidor, v_RegReplica.CDACCION, v_RegReplica.IDTABLA, v_ok);
      elsif v_RegReplica.Vlnombretabla = 'tblcnpedido' then
         LlevarCNpedido (p_servidor, v_RegReplica.CDACCION, v_RegReplica.IDTABLA, v_ok);
      elsif v_RegReplica.Vlnombretabla = 'tblcnfactura' then
         LlevarCNfactura (p_servidor, v_RegReplica.CDACCION, v_RegReplica.IDTABLA, v_ok);
      elsif v_RegReplica.Vlnombretabla = 'tblreclamoposnet' then
         LlevarReclamoPosnet(p_servidor, v_RegReplica.CDACCION, v_RegReplica.IDTABLA, v_ok);
      elsif v_RegReplica.Vlnombretabla = 'tblreclamoobservacion' then
         LlevarReclamoObservacion (p_servidor, v_RegReplica.CDACCION, v_RegReplica.IDTABLA, v_ok);
      elsif v_RegReplica.Vlnombretabla = 'tbldireccioncuenta' then
         LlevarDireccionCuenta (p_servidor, v_RegReplica.CDACCION, v_RegReplica.IDTABLA, v_ok);
      elsif v_RegReplica.Vlnombretabla = 'tblentidadaplicacion' then
         LlevarEntidadAplicacion(p_servidor, v_RegReplica.CDACCION, v_RegReplica.IDTABLA, v_ok);
      else
         GrabarLog(2, 'Modulo: '||v_Modulo||' Error: La tabla '||v_RegReplica.Vlnombretabla||' no puede ser replicada de AC hacia la sucursal.');
         v_ok := 0;
      end if;

      --Si se pudo Llevar a la sucursal, marcarlo como replicado y hacer commit
      if v_ok = 1 then
         g_vlRegistrosOK := g_vlRegistrosOK + 1;
         update tblreplica set cdestado = REPLICAS_GENERAL.estado_enviado, DTCAMBIOESTADO=sysdate
         where idreplica = v_RegReplica.IDREPLICA;
         commit;
      else
         g_vlRegistrosError := g_vlRegistrosError + 1;
         rollback;
      end if;

      --Controlar si la replica está demorando mucho
      if ( (sysdate-v_dtInicioProc)*24*60) > g_CantMaxMinutos then
         return;
      end if;

   end loop;

   return;

exception when others then
   GrabarLog(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM ||' suc: '||p_servidor);

end Llevar;

/**************************************************************************************************
* Iniciar las replicas
* %v 03/06/2014 - MarianoL
***************************************************************************************************/
procedure Iniciar(p_servidor in sucursales.servidor%type default null)
is

   v_modulo           varchar2(100) := 'PKG_REPLICA_SUC.Iniciar';
   v_RegSucursal      sucursales%rowtype;
   v_lockHandle       varchar2(200);
   v_lockResult       number;
   v_lockTimeOut_Seg  integer      := 1800;  --Número de segundos que se mantendrá el bloqueo
   v_lockWait         integer      := 1;     --Número de segundos que queremos permanecer esperando a que se libere el bloqueo si otro lo tiene bloqueado
   v_lockRelease_on_commit boolean := false; --True indica que el bloqueo debe liberarse al ejecutar COMMIT o ROLLBACK, si es false debe liberarse manualmente

begin

   --Es necesario cambiarlo para que cada sucursal tenga su propio lock
   v_modulo := 'PKG_REPLICA_SUC.Iniciar ' || p_servidor;

   -- *** Inicio Lock ***
   -- Este sistema de lockeo lo utilizo para evitar que se ejecute el procedure más de una vez
   dbms_lock.allocate_unique(v_modulo, v_lockHandle, v_lockTimeOut_Seg);  --Genera un id para el contenído del v_Modulo que dura v_lockTimeOut_Seg

   v_lockResult := dbms_lock.request(v_lockHandle, dbms_lock.x_mode, v_lockWait, v_lockRelease_on_commit);  --Genera un lock para ese id
   If v_lockResult <> 0 Then  --Si no se pudo generar el lock es porque ya está corriendo
      return;
   end if;
   -- *** Fin Lock ***

   --Recorrer la tabla de sucursales y Traer cada una
   for v_RegSucursal in (select s.*
                         from sucursales s
                         where s.servidor is not null
                          -- and s.servidor in ('sf','tr','cc')--not in ('ac')
                           and lower(s.servidor) = p_servidor--nvl(lower(p_servidor),lower(s.servidor))
                         order by s.cdsucursal)

   loop

      --Limpio las variables de ok y errores para cada sucursal
      g_vlRegistrosOK    := 0;
      g_vlRegistrosError := 0;

      --Verificar si hay enlace con la sucursal
      if GetEnlaceOK(v_RegSucursal.Servidor) = 0 then
         MarcarErrorReplica(v_RegSucursal.Cdsucursal, 'No hay enlace con la sucursal.');
      else
         MarcarInicioReplica(v_RegSucursal.Cdsucursal);
         DetenerTriggerAC;
         DetenerTriggerSucursal(v_RegSucursal.Servidor);
         Traer(v_RegSucursal.Servidor);
         Llevar(v_RegSucursal.Servidor, v_RegSucursal.Cdsucursal);
         MarcarFinReplica(v_RegSucursal.Cdsucursal);
      end if;

   end loop;

   -- *** Libero el lockeo ***
   v_lockResult := dbms_lock.release(v_lockHandle);
   if v_lockResult <> 0 then
      GrabarLog(2, 'Modulo: '||v_Modulo||'  Error al liberar el lock: ' || v_lockResult);
   end if;

   return;

exception when others then
   -- *** Libero el lockeo ***
   v_lockResult := dbms_lock.release(v_lockHandle);
   if v_lockResult <> 0 then
      GrabarLog(2, 'Modulo: '||v_Modulo||'  Error al liberar el lock: ' || v_lockResult);
   end if;
  --Registro el error
   GrabarLog(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM);

end Iniciar;



END;
/
