create or replace package PKG_TELEMARKETING is

  /**********************************************************************************************************
  * Author  : CHARLES ROY MALDONADO DUARTE
  * Created : 11/03/2021 11:00:00 a.m.
  * %v Paquete para la DISTRIBUCION de pedidos con marca de CF de clientes con cuenta a los DNI asignados
  **********************************************************************************************************/
  -- Tipos de datos

  TYPE CURSOR_TYPE IS REF CURSOR;
  PROCEDURE listadoCALL (Cur_Out      Out Cursor_Type);   

end PKG_TELEMARKETING;
/
create or replace package body PKG_TELEMARKETING is

  /**********************************************************************************************************************
  * CU 08 CRUD de usuarios Telemarketing asignados a Clientes 
  * Versión: 1.0 27/04/2021
  * Dependencias:  POS
  * Precondición:  El listado de clientes se generará de objetos ya disponibles en la BD.
  * Descripción:  El sistema debe mantener actualizada la información de asociación de los empleados 
                  de telemarketing al listado de clientes de las cuales son responsables de atender en la plataforma VTEX. 
  * Secuencia Normal:  
  * Paso  Acción
  *  1  El sistema genera un listado de los clientes disponibles para asociarles el empleado telemarketing que lo atenderá. 
  *  2  El sistema recibe el idcliente que se desea asociar al empleado call.
  *  3  El sistema genera un listado de los empleados Telemarketing (tipo 6 en objeto personas) disponibles para asociarlo 
  *     al cliente, si el cliente ya posee una asociación activa se indica con marca de activo en el listado.
  *  4  Se reciben los datos para el alta de asociación compuesta por: id empleado del call center, identificación del 
  *     cliente y la información de la persona que lo autoriza. 
  *  5  Si existen asociaciones previas se marcan como inactivas.
  *  6  Si se recibe null en el id empleado call se marca como inactiva cualquier asociación existente para el cliente.
  *  7  Si se recibe una asociación existente pero inactiva se marca activa.
  *  8	Si los datos de asociación son correctos se da de alta y se marca como activa.
  *  Post condición: Si se recibe null en id cliente se devuelve el listado de empleados call completo disponible para 
  *                  asociar a cualquier cliente.	
  *  Excepciones:	
  *  Comentarios:	
  * %v 27/04/2021 ChM
  **************************************************************************************************/

  /************************************************************************************************************
  * genera un listado de los empleados de telemarketing disponibles para asociar al cliente rol 6
  * %v 27/04/2021 ChM: v1.0
  ************************************************************************************************************/
   PROCEDURE listadoCALL (Cur_Out      Out Cursor_Type) IS 
   
    v_modulo        varchar2(100) := 'PKG_TELEMARKETING.listadoCALL';

  BEGIN
    OPEN cur_out FOR
       select p.idpersona,
              p.dsnombre ||' '||p.dsapellido||' '||'DNI: '||p.nudocumento||' Legajo: '||p.cdlegajo CALL       
         from personas      p,
              rolespersonas rp 
        where p.idpersona = rp.idpersona
           --solo empleados telemarketing
          and rp.cdrol = 6
           --solo personas activas
          and p.icactivo = 1; 
  EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(1,
                            'Modulo: ' || v_Modulo || '  Error: ' ||
                            SQLERRM);
      return;
  END listadoCALL;

  /************************************************************************************************************
  * Alta de asociación de clientes al empleado de callcenter que lo atenderá 
  * %v 27/04/2021 ChM: v1.0
  ************************************************************************************************************/
   PROCEDURE SETAsociarClienteCall ( P_identidad             In  clientestelemarketing.identidad%type default null,
                                     P_cdsucursal            In  clientestelemarketing.cdsucursal%type default null,
                                     P_idpersona             In  clientestelemarketing.idpersona%type default null,       
                                     P_idpersonaresponsable  In  clientestelemarketing.idpersonaresponsable%type,
                                     p_Ok                    Out number,
                                     p_error                 Out varchar2,
                                     Cur_Out                 Out Cursor_Type) IS 
   
    v_modulo        varchar2(100) := 'PKG_TELEMARKETING.SETAsociarClienteCall';

  BEGIN
    -- Si se recibe null en identidad se devuelve el listado de empleados call disponible para asociar.	
     if P_identidad is null then 
            OPEN cur_out FOR
               select p.idpersona,
                      p.dsnombre ||' '||p.dsapellido||' '||'DNI: '||p.nudocumento||' Legajo: '||p.cdlegajo CALL       
                 from personas      p,
                      rolespersonas rp 
                where p.idpersona = rp.idpersona
                   --solo empleados telemarketing
                  and rp.cdrol = 6
                   --solo personas activas
                  and p.icactivo = 1; 
            p_Ok:=1;
            p_error:= Null;      
     end if;             
  EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(1,
                            'Modulo: ' || v_Modulo || '  Error: ' ||
                            SQLERRM);
      return;
  END SETAsociarClienteCall;        

end  PKG_TELEMARKETING;
/
