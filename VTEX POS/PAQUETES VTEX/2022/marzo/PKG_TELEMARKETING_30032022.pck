create or replace package PKG_TELEMARKETING is

  /**********************************************************************************************************
  * Author  : CHARLES ROY MALDONADO DUARTE
  * Created : 11/03/2021 11:00:00 a.m.
  * %v Paquete para la DISTRIBUCION de pedidos con marca de CF de clientes con cuenta a los DNI asignados
  **********************************************************************************************************/
  -- Tipos de datos

  TYPE CURSOR_TYPE IS REF CURSOR;

   PROCEDURE SETAsociarClienteCall ( P_identidad             In  carteraclientes.identidad%type default null,
                                     P_cdsucursal            In  carteraclientes.cdsucursal%type default null,
                                     P_idpersona             In  carteraclientes.idpersona%type default null,       
                                     P_idpersonaresponsable  In  carteraclientes.idpersonaresponsable%type,
                                     p_Ok                    Out number,
                                     p_error                 Out varchar2,
                                     Cur_Out                 Out Cursor_Type);

   PROCEDURE listadoCALL ( P_identidad             In  carteraclientes.identidad%type default null,
                           P_cdsucursal            In  carteraclientes.cdsucursal%type default null,
                           Cur_Out                 In Out Cursor_Type);                                

end PKG_TELEMARKETING;
/
create or replace package body PKG_TELEMARKETING is

  /**********************************************************************************************************************
  * CU 08 CRUD de usuarios Telemarketing asignados a Clientes 
  * Versión: 1.0 30/04/2021
  * Dependencias:	POS
  * Precondición:	El listado de clientes se generará de objetos ya disponibles en la BD.
  * Descripción:	El sistema debe mantener actualizada la información de asociación de los empleados de telemarketer al 
  * listado de clientes de las cuales son responsables de atender en la plataforma VTEX. 
  * Secuencia Normal:	Paso	Acción
	*                     1	   Si se recibe null en id cliente se devuelve el listado de empleados telemarketer completo 
                             disponible para asociar a cualquier cliente.
	*	                    2	   El sistema recibe el idcliente que se desea asociar al empleado telemarketer.
  *	                    3	   El sistema genera un listado de los empleados TLK,VE,Viajante (tipo 6,11,31 en objeto personas) 
  *                          disponibles para asociarlo al cliente que recibe, si el cliente ya posee una asociación 
  *                          activa se indica con marca de activo en el listado.
  *                    	4	   Se reciben los datos para el alta de asociación compuesta por: id empleado del telemarketer, 
  *                          identificación del cliente y la información de la persona que lo autoriza. 
	*                     5	   Si existen asociaciones previas se marcan como inactivas.
	*                     6	   Si se recibe -1 en el id empleado telemarketer se marca como inactiva cualquier asociación 
  *                          existente para el cliente.
  *                   	7	   Si se recibe una asociación existente pero inactiva se marca activa.
	*                     8	   Si los datos de asociación son correctos se da de alta y se marca como activa.
  *  Post condición:	Siempre debe enviarse una persona responsable del cambio de asignación del empleado telemarketer
  *                   
  *  Excepciones:	
  *  Comentarios:	
  * %v 30/04/2021 ChM
  **************************************************************************************************/

  /************************************************************************************************************
  * genera un listado de los empleados de telemarketing disponibles para asociar al cliente rol 6
  * %v 27/04/2021 ChM: v1.0
  * %v 30/03/2022 ChM: agrego los roles vendedor y viajante
  ************************************************************************************************************/
   PROCEDURE listadoCALL ( P_identidad             In  carteraclientes.identidad%type default null,
                           P_cdsucursal            In  carteraclientes.cdsucursal%type default null,
                           Cur_Out                 In Out Cursor_Type) IS 
   
    v_modulo        varchar2(100) := 'PKG_TELEMARKETING.listadoCALL';

  BEGIN
    
    OPEN cur_out FOR
       select p.idpersona,
              p.dsnombre ||' '||p.dsapellido||' '||LISTAGG(r.dsrol, '/') WITHIN GROUP (ORDER BY r.dsrol) CALL,  
              LISTAGG(r.dsrol, '/') WITHIN GROUP (ORDER BY r.dsrol) rol,                                
              'ACTIVO' estado      
         from personas      p,
              rolespersonas rp,
              roles         r 
        where p.idpersona = rp.idpersona
           --solo empleados telemarketing, Vendedor, Vendedor Viajante
          and rp.cdrol in (6,11,31)
          and r.cdrol = rp.cdrol
           --solo personas activas
          and p.icactivo = 1          
          and p.idpersona in ( select ct.idpersona
                                 from carteraclientes ct        
                                where trim(ct.identidad) =  nvl(trim(p_identidad),-1)
                                  and trim(ct.cdsucursal) =  nvl(trim(p_cdsucursal),-1)
                                     --solo relaciones activas
                                  and ct.icactivo = 1)
       group by p.idpersona,              
               p.dsnombre,
               p.dsapellido                             
     UNION all
       select p.idpersona,
              p.dsnombre ||' '||p.dsapellido||' '||LISTAGG(r.dsrol, '/') WITHIN GROUP (ORDER BY r.dsrol) CALL,  
              LISTAGG(r.dsrol, '/') WITHIN GROUP (ORDER BY r.dsrol) rol,                             
             '0' estado      
         from personas      p,
              rolespersonas rp,
              roles         r  
        where p.idpersona = rp.idpersona
           --solo empleados telemarketing, Vendedor, Vendedor Viajante
          and rp.cdrol in (6,11,31)
          and r.cdrol = rp.cdrol
           --solo personas activas
          and p.icactivo = 1          
          and p.idpersona not in ( select ct.idpersona
                                     from carteraclientes ct        
                                    where trim(ct.identidad) = nvl(trim(p_identidad),-1)
                                      and trim(ct.cdsucursal) =  nvl(trim(p_cdsucursal),-1)
                                      --solo relaciones activas
                                      and ct.icactivo = 1) 
      group by p.idpersona,              
               p.dsnombre,
               p.dsapellido                                                                 
      order by estado,rol  
          ; 
  EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(1,
                            'Modulo: ' || v_Modulo || '  Error: ' ||
                            SQLERRM);
      return;
  END listadoCALL;

  /************************************************************************************************************
  * Alta de asociación de clientes al empleado de callcenter que lo atenderá 
  * %v 30/04/2021 ChM: v1.0
  ************************************************************************************************************/
   PROCEDURE SETAsociarClienteCall ( P_identidad             In  carteraclientes.identidad%type default null,
                                     P_cdsucursal            In  carteraclientes.cdsucursal%type default null,
                                     P_idpersona             In  carteraclientes.idpersona%type default null,       
                                     P_idpersonaresponsable  In  carteraclientes.idpersonaresponsable%type,
                                     p_Ok                    Out number,
                                     p_error                 Out varchar2,
                                     Cur_Out                 Out Cursor_Type) IS 
   
    v_modulo        varchar2(100) := 'PKG_TELEMARKETING.SETAsociarClienteCall';
    v_iDcliente     carteraclientes.idcliente%type:=null;
    
  BEGIN
    --siempre debe enviarse una persona responsable del cambio
    if P_idpersonaresponsable is null then
       p_Ok:=0;
       p_error:= 'Siempre debe enviarse una persona responsable del cambio';
       return;
    end if;         
    -- Si se recibe null en identidad se devuelve el listado de empleados call disponible para asociar.	
     if P_identidad is null then 
            PKG_TELEMARKETING.listadoCALL(P_identidad,P_cdsucursal,Cur_out);           
     else
       --si se indica id cliente con cdsucursal en null error
           if P_cdsucursal is null then
             p_Ok:=0;
             p_error:= 'Debe indicar la sucursal del cliente';
             return;               
           end if;
              
        --verifico si el parametro p_idpersona es -1 indica limpiar las asociaciones activas
        if P_idpersona='-1' then
           --update para limpiar toda asociacion del cliente y la sucursal
           update carteraclientes ct
              set ct.icactivo = 0,
                  ct.idpersonaresponsable=P_idpersonaresponsable,
                  ct.dtupdate=sysdate
            where ct.identidad = P_identidad
              and ct.cdsucursal = P_cdsucursal
              --actualizo solo activas
              and ct.icactivo = 1 ;           
        else
          --si idcliente y idpersona (empleado) tiene valor indica actualizar activo el empleado al cliente         
          if P_idpersona is not null then
            -- busca si existe la asociacion 
            begin
             select ct.idcliente
               into v_iDcliente
               from carteraclientes ct        
              where ct.identidad =  p_identidad
                and ct.cdsucursal = p_cdsucursal
                and ct.idpersona = P_idpersona;
               --se inactivan toda asociación anteriores activas
              --update para limpiar toda asociacion activa del cliente y la sucursal
               update carteraclientes ct
                  set ct.icactivo = 0,
                      ct.idpersonaresponsable=P_idpersonaresponsable,
                      ct.dtupdate=sysdate
                where ct.identidad = P_identidad
                  and ct.cdsucursal = P_cdsucursal
                  --actualizo solo activas
                  and ct.icactivo = 1 ;    
              --si existe la asociacion entonces la activa   
              update carteraclientes ct
              set ct.icactivo = 1,
                  ct.idpersonaresponsable=P_idpersonaresponsable,
                  ct.dtupdate=sysdate
            where ct.identidad = P_identidad
              and ct.cdsucursal = P_cdsucursal             
              and ct.idpersona = P_idpersona;                
             exception 
                when no_data_found then
                  --update para limpiar toda asociacion activa del cliente y la sucursal
                     update carteraclientes ct
                        set ct.icactivo = 0,
                            ct.idpersonaresponsable=P_idpersonaresponsable,
                            ct.dtupdate=sysdate
                      where ct.identidad = P_identidad
                        and ct.cdsucursal = P_cdsucursal
                        --actualizo solo activas
                        and ct.icactivo = 1 ;    
                   --si no existe asociacion la inserta
                   insert into carteraclientes ct 
                               (ct.idcliente,
                                ct.identidad,
                                ct.idpersona,
                                ct.cdsucursal,
                                ct.icactivo,
                                ct.idpersonaresponsable,
                                ct.dtinsert,
                                ct.dtupdate)
                        values (sys_guid(),
                                P_identidad,
                                P_idpersona,
                                P_cdsucursal,
                                1,--activo
                                P_idpersonaresponsable,
                                sysdate,
                                sysdate);                               
                when too_many_rows then 
                  --si hay mas de una asociación error 
                    n_pkg_vitalpos_log_general.write(1,
                            'Modulo: ' || v_Modulo ||' el cliente : '||p_identidad||'
                             de la sucursal: '||P_cdsucursal||'tiene más de una asociacion con:'
                             ||p_idpersona|| '  Error: ' ||
                            SQLERRM);
                    p_Ok:=0;
                    p_error:= 'Error comuniquese con sistemas!';
                    rollback;
                    return; 
               when others then
                    n_pkg_vitalpos_log_general.write(1,
                            'Modulo: ' || v_Modulo || '  Error: ' ||
                            SQLERRM);
                    p_Ok:=0;
                    p_error:= 'Error comuniquese con sistemas!';
                    rollback;
                    return;      
             end;  
          end if;  
        end if;
        --llama la carga en el cursor de listado de empleados call
        PKG_TELEMARKETING.listadoCALL(P_identidad, P_cdsucursal,Cur_out);            
        p_Ok:=1;
        p_error:= Null;
        commit;
        return;  
     end if;
     --si p_idpersona es null solo devuelve el listado de empleados call asociados o no
     p_Ok:=1;
     p_error:= Null;               
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
