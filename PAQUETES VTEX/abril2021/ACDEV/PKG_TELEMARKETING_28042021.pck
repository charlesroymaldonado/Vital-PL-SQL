create or replace package PKG_TELEMARKETING is

  /**********************************************************************************************************
  * Author  : CHARLES ROY MALDONADO DUARTE
  * Created : 11/03/2021 11:00:00 a.m.
  * %v Paquete para la DISTRIBUCION de pedidos con marca de CF de clientes con cuenta a los DNI asignados
  **********************************************************************************************************/
  -- Tipos de datos

  TYPE CURSOR_TYPE IS REF CURSOR;

  PROCEDURE SETAsociarClienteCall ( P_identidad             In  clientestelemarketing.identidad%type default null,
                                    P_cdsucursal            In  clientestelemarketing.cdsucursal%type default null,
                                    P_idpersona             In  clientestelemarketing.idpersona%type default null,       
                                    P_idpersonaresponsable  In  clientestelemarketing.idpersonaresponsable%type,
                                    p_Ok                    Out number,
                                    p_error                 Out varchar2,
                                    Cur_Out                 Out Cursor_Type);   

end PKG_TELEMARKETING;
/
create or replace package body PKG_TELEMARKETING is

  /**********************************************************************************************************************
  * CU 08 CRUD de usuarios Telemarketing asignados a Clientes 
  * Versi�n: 1.0 27/04/2021
  * Dependencias:  POS
  * Precondici�n:  El listado de clientes se generar� de objetos ya disponibles en la BD.
  * Descripci�n:  El sistema debe mantener actualizada la informaci�n de asociaci�n de los empleados 
                  de telemarketing al listado de clientes de las cuales son responsables de atender en la plataforma VTEX. 
  * Secuencia Normal:  
  * Paso  Acci�n
  *  1  Si se recibe null en id cliente se devuelve el listado de empleados call completo disponible para 
  *     asociar a cualquier cliente.	
  *  2  El sistema recibe el idcliente que se desea asociar al empleado call.
  *  3  El sistema genera un listado de los empleados Telemarketing (tipo 6 en objeto personas) disponibles para asociarlo 
  *     al cliente, si el cliente ya posee una asociaci�n activa se indica con marca de activo en el listado.
  *  4  Se reciben los datos para el alta de asociaci�n compuesta por: id empleado del call center, identificaci�n del 
  *     cliente y la informaci�n de la persona que lo autoriza. 
  *  5  Si existen asociaciones previas se marcan como inactivas.
  *  6  Si se recibe null en el id empleado call se marca como inactiva cualquier asociaci�n existente para el cliente.
  *  7  Si se recibe una asociaci�n existente pero inactiva se marca activa.
  *  8	Si los datos de asociaci�n son correctos se da de alta y se marca como activa.
  *  Post condici�n: 
  *  Excepciones:	
  *  Comentarios:	
  * %v 27/04/2021 ChM
  **************************************************************************************************/

  /************************************************************************************************************
  * genera un listado de los empleados de telemarketing disponibles para asociar al cliente rol 6
  * %v 27/04/2021 ChM: v1.0
  ************************************************************************************************************/
   PROCEDURE listadoCALL ( P_identidad             In  clientestelemarketing.identidad%type default null,
                           P_cdsucursal            In  clientestelemarketing.cdsucursal%type default null,
                           Cur_Out                 In Out Cursor_Type) IS 
   
    v_modulo        varchar2(100) := 'PKG_TELEMARKETING.listadoCALL';

  BEGIN
    
    OPEN cur_out FOR
       select p.idpersona,
              p.dsnombre ||' '||p.dsapellido||' '||'DNI: '||p.nudocumento||' Legajo: '||p.cdlegajo CALL, 
              'ACTIVO' estado      
         from personas      p,
              rolespersonas rp 
        where p.idpersona = rp.idpersona
           --solo empleados telemarketing
          and rp.cdrol = 6
           --solo personas activas
          and p.icactivo = 1          
          and p.idpersona in ( select ct.idpersona
                                 from clientestelemarketing ct        
                                where ct.identidad =  nvl(p_identidad,-1)
                                  and ct.cdsucursal =  nvl(p_cdsucursal,-1)
                                     --solo relaciones activas
                                  and ct.icactivo = 1)
     UNION
     select p.idpersona,
              p.dsnombre ||' '||p.dsapellido||' '||'DNI: '||p.nudocumento||' Legajo: '||p.cdlegajo CALL, 
             '0' estado      
         from personas      p,
              rolespersonas rp 
        where p.idpersona = rp.idpersona
           --solo empleados telemarketing
          and rp.cdrol = 6
           --solo personas activas
          and p.icactivo = 1          
          and p.idpersona not in ( select ct.idpersona
                                     from clientestelemarketing ct        
                                    where ct.identidad = nvl(p_identidad,-1)
                                      and ct.cdsucursal =  nvl(p_cdsucursal,-1)
                                      --solo relaciones activas
                                      and ct.icactivo = 1)                                  
          ; 
  EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(1,
                            'Modulo: ' || v_Modulo || '  Error: ' ||
                            SQLERRM);
      return;
  END listadoCALL;

  /************************************************************************************************************
  * Alta de asociaci�n de clientes al empleado de callcenter que lo atender� 
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
    --siempre debe enviarse una persona respomsable del cambio
    if P_idpersonaresponsable is null then
       p_Ok:=0;
       p_error:= 'Siempre debe enviarse una persona respomsable del cambio';
       return;
    end if;         
    -- Si se recibe null en identidad se devuelve el listado de empleados call disponible para asociar.	
     if P_identidad is null then 
            PKG_TELEMARKETING.listadoCALL(P_identidad,P_cdsucursal,Cur_out);
            p_Ok:=1;
            p_error:= Null;
            return;
     else
       --si se indica id cliente con cdsucursal en null error
           if P_cdsucursal is null then
             p_Ok:=0;
             p_error:= 'Debe indicar la sucursal del cliente';
             return;
           else  
             --si se indica id cliente y sucursal se devuelve el listado con marca
             --de asignaci�n activa si existe sino listado general para asignar
             PKG_TELEMARKETING.listadoCALL(P_identidad, P_cdsucursal,Cur_out);            
           end if;
              
        --verifico si el parametro p_idpersona es null indica listar asociaciones activas del cliente que recibe            
        if P_idpersona is null then
           null; 
        else
          --si idcliente y idpersona (empleado) tiene valor indica actualizar activo el empleado al cliente
          --se inactivan toda asociaci�n anterior
          null;
        end if;
     end if;             
  EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(1,
                            'Modulo: ' || v_Modulo || '  Error: ' ||
                            SQLERRM);
      p_Ok:=0;
      p_error:= 'Error comuniquese con sistemas!';
  END SETAsociarClienteCall;        

end  PKG_TELEMARKETING;
/