CREATE OR REPLACE PACKAGE PKG_SLV_CONTROL is
  /**********************************************************************************************************
  * Author  : CHARLES MALDONADO
  * Created : 01/07/2020 03:45:03 p.m.
  * %v Paquete para gestión y control de REMITOS SLV
  **********************************************************************************************************/
  -- Tipos de datos

  TYPE CURSOR_TYPE IS REF CURSOR;
  
  -- para uso publico del paquete
  PROCEDURE GetControl(p_idremito           IN  tblslvremito.idremito%type,
                       p_idpersona          IN  personas.idpersona%type,
                       p_idControl          OUT tblslvcontrolremito.idcontrolremito%type,
                       p_Ok                 OUT number,
                       p_error              OUT varchar2);
                       
  PROCEDURE SetControl(p_idControl          IN  tblslvremito.idremito%type,                      
                       p_cdarticulo         IN  articulos.cdarticulo%type,
                       p_qtunidadbase       IN  tblslvremitodet.qtunidadmedidabasepicking%type,
                       p_qtpiezas           IN  tblslvremitodet.qtpiezaspicking%type,
                       p_Cursor             OUT CURSOR_TYPE,
                       p_Ok                 OUT number,
                       p_error              OUT varchar2);                                                                                                                                                                         

end PKG_SLV_CONTROL;
/
CREATE OR REPLACE PACKAGE BODY PKG_SLV_CONTROL is
/***************************************************************************************************
*  %v 01/07/2020  ChM - Parametros globales del PKG
****************************************************************************************************/


  --costante de tblslvestado
 -- C_EnCursoRemito                    CONSTANT tblslvestado.cdestado%type := 36;
  C_FinalizadoRemito                 CONSTANT tblslvestado.cdestado%type := 37;
  C_IniciaControl                    CONSTANT tblslvestado.cdestado%type := 43;
  C_Controlado                       CONSTANT tblslvestado.cdestado%type := 44; 
  
  /****************************************************************************************************
  * %v 03/07/2020 - ChM  Versión inicial GetControl
  * %v 03/07/2020 - ChM  recibe un idremito para iniciar su control 
  *                      OOOOOJOOOOO falta agregar la validación si el remito se controla
  *****************************************************************************************************/
  PROCEDURE GetControl(p_idremito           IN  tblslvremito.idremito%type,
                       p_idpersona          IN  personas.idpersona%type,
                       p_idControl          OUT tblslvcontrolremito.idcontrolremito%type,
                       p_Ok                 OUT number,
                       p_error              OUT varchar2) IS
                       
    v_modulo           varchar2(100) := 'PKG_SLV_CONTROL.GetControl';
    v_estado           tblslvremito.cdestado%type:=null;
    v_error            varchar2(250);      
    
   BEGIN
     --valida si el remito existe 
    begin
      select re.cdestado
        into v_estado
        from tblslvremito re
       where re.idremito=p_idremito;
     exception
       when no_data_found then
          p_Ok    := 0;
          p_error := 'Error Remito N° '||p_idremito||' no existe.';
       return;  
      end;
    --verifica si esta finalizado
    if v_estado <> C_FinalizadoRemito then
       p_Ok    := 0;
       p_error := 'Error Remito N° '||p_idremito||' No Finalizado.';
       RETURN;
    end if; 
     --valida si existe el remito en tblslvcontrolremito obtiene el idcontrol
       begin        
            select cr.idcontrolremito,
                   cr.cdestado                   
              into p_idControl,
                   v_estado                   
              from tblslvcontrolremito cr
             where cr.idremito = p_idremito; 
           exception        
             -- si no existe lo crea    
           when no_data_found then
            v_error:='Falla Insert tblslvcontrolremito';
            p_idControl:=seq_controlremito.nextval;
            insert into tblslvcontrolremito
                   (idcontrolremito,
                    idremito,
                    cdestado,
                    idpersonacontrol,
                    qtcontrol,
                    dtinicio,
                    dtfin)
             values (p_idControl,
                     p_idremito,
                     C_IniciaControl,
                     p_idpersona,
                     1,
                     sysdate,
                     null);
            IF SQL%ROWCOUNT = 0 THEN
              n_pkg_vitalpos_log_general.write(2,
                                              'Modulo: ' || v_modulo ||
                                              '  Detalle Error: ' || v_error);
              p_Ok    := 0;
              p_error:='Error. Comuniquese con Sistemas!';
              ROLLBACK;
              RETURN;
            END IF; 
            p_Ok    := 1;
            p_error := '';
            commit;
            return;   
         end;
     --verifica si esta Controlado
    if v_estado = C_Controlado then
       p_Ok    := 0;
       p_error := 'Remito N° '||p_idremito||' Ya Controlado.';
       RETURN;
    end if;      
    p_Ok    := 1;
    p_error := '';
    return;       
    EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       ' Error: ' || SQLERRM);
      p_Ok    := 0;
      p_error:='Error Control Remito. Comuniquese con Sistemas!';
  END GetControl;
  
  /****************************************************************************************************
  * %v 01/07/2020 - ChM  Versión inicial SetControl
  * %v 01/07/2020 - ChM  recibe un idcontrol para inserta los articulos
  *****************************************************************************************************/
  PROCEDURE SetControl(p_idControl          IN  tblslvremito.idremito%type,                      
                       p_cdarticulo         IN  articulos.cdarticulo%type,
                       p_qtunidadbase       IN  tblslvremitodet.qtunidadmedidabasepicking%type,
                       p_qtpiezas           IN  tblslvremitodet.qtpiezaspicking%type,
                       p_Cursor             OUT CURSOR_TYPE,
                       p_Ok                 OUT number,
                       p_error              OUT varchar2) IS

    v_modulo           varchar2(100) := 'PKG_SLV_CONTROL.SetControl';
    v_estado           tblslvremito.cdestado%type:=null;
    v_error            varchar2(250); 
    v_idcontroldet     tblslvcontrolremitodet.idcontrolremitodet%type;
    v_qtcontrol        tblslvcontrolremito.qtcontrol%type;     
    v_qtbase           tblslvcontrolremitodet.qtunidadmedidabasepicking%type;
  BEGIN
    
      --valida si existe el p_idControl en tblslvcontrolremito 
       begin        
            select cr.cdestado,
                   cr.qtcontrol                   
              into v_estado,
                   v_qtcontrol                   
              from tblslvcontrolremito cr
             where cr.idcontrolremito = p_idControl; 
       exception               
          when no_data_found then
             p_Ok    := 0;
             p_error := 'Error Control Remito N° '||p_idControl||' No existe.';
            return; 
       end;
       
      --verifica si esta Controlado
      if v_estado = C_Controlado then
         p_Ok    := 0;
         p_error := 'Error Control Remito N° '||p_idControl||' Ya Controlado.';
         RETURN;
      end if;  
      --verifica si existe el detalle 
       begin   
         --si es picking de pesable qtunidadmedidabasepicking cero 0
            if p_qtpiezas <> 0 then
              v_qtbase:=0;
              else
              v_qtbase:=p_qtunidadbase;  
              end if;  
            select crd.idcontrolremitodet      
              into v_idControldet            
              from tblslvcontrolremitodet crd
             where crd.idcontrolremito = p_idControl
               and crd.cdarticulo = p_cdarticulo; 
             -- si existe actualiza la cantidad picking
             v_error:='Falla update tblslvcontrolremitodet';
             update tblslvcontrolremitodet crd
                set crd.qtunidadmedidabasepicking = nvl(crd.qtunidadmedidabasepicking,0)+v_qtbase,
                    crd.qtpiezaspicking = nvl(crd.qtpiezaspicking,0)+p_qtpiezas,
                    crd.dtupdate = sysdate
              where crd.idcontrolremitodet = v_idcontroldet
                and crd.idcontrolremito = p_idControl
                and crd.cdarticulo = p_cdarticulo; 
             IF SQL%ROWCOUNT = 0 THEN
                 n_pkg_vitalpos_log_general.write(2,
                                                  'Modulo: ' || v_modulo ||
                                                  '  Detalle Error: ' || v_error);
                 p_Ok    := 0;
                 p_error:='Error al actualizar Artículo';
                 ROLLBACK;
                 RETURN;
             END IF;                   
           exception        
             -- si no existe lo crea    
           when no_data_found then       
                -- inserto en tblslvcontrolremitodet      
                v_error:='Falla Insert tblslvcontrolremitodet';
                insert into tblslvcontrolremitodet
                           (idcontrolremitodet,
                            idcontrolremito,
                            cdarticulo,
                            qtdiferenciaunidadmbase,
                            qtdiferenciapiezas,
                            qtunidadmedidabasepicking,
                            qtpiezaspicking,
                            dtinsert,
                            dtupdate)
                     values (seq_controlremitodet.nextval,
                             p_idControl,
                             p_cdarticulo,
                             0,
                             0,
                             v_qtbase,
                             p_qtpiezas,
                             sysdate,
                             null);
                  IF SQL%ROWCOUNT = 0 THEN
                     n_pkg_vitalpos_log_general.write(2,
                                                      'Modulo: ' || v_modulo ||
                                                      '  Detalle Error: ' || v_error);
                     p_Ok    := 0;
                     p_error:='Error al insertar Artículo';
                     ROLLBACK;
                     RETURN;
                 END IF;  
      end; 
   --valida si el qtcontrol es 1 devuelve lo piqueado sin diferencias
   if v_qtcontrol = 1 then
     open p_Cursor for 
           select crd.cdarticulo Cdarticulo,
                  crd.cdarticulo||' - '||des.vldescripcion Articulo,
                  PKG_SLV_Articulo.SetFormatoArticuloscod(crd.cdarticulo,
                  --valida pesables
                  decode(nvl(sum(crd.qtpiezaspicking),0),0,
                  (nvl(sum(crd.qtunidadmedidabasepicking),0)),
                  nvl(sum(crd.qtpiezaspicking),0))) Cantidad                     
             from tblslvcontrolremitodet crd,
                  descripcionesarticulos des  
            where crd.idcontrolremito = p_idControl
              and crd.cdarticulo = des.cdarticulo
              --solo muestro las piqueadas por primera vez
              and (crd.qtdiferenciaunidadmbase = 0 or crd.qtdiferenciapiezas = 0)
              -- que tenga cantidad ingresada
              and (nvl(crd.qtunidadmedidabasepicking,0)<>0 or nvl(crd.qtpiezaspicking,0)<>0);
     end if;
     --valida si el qtcontrol es diferente de 1 devuelve lo piqueado con diferencias
   if v_qtcontrol <> 1 then
     open p_Cursor for 
           select crd.cdarticulo Cdarticulo,
                  crd.cdarticulo||' - '||des.vldescripcion Articulo,
                  PKG_SLV_Articulo.SetFormatoArticuloscod(crd.cdarticulo,
                  --valida pesables
                  decode(nvl(sum(crd.qtpiezaspicking),0),0,
                  (nvl(sum(crd.qtunidadmedidabasepicking),0)),
                  nvl(sum(crd.qtpiezaspicking),0))) Cantidad                     
             from tblslvcontrolremitodet crd,
                  descripcionesarticulos des  
            where crd.idcontrolremito = p_idControl
              and crd.cdarticulo = des.cdarticulo
              --solo muestra los artículos con diferencias
              and (crd.qtdiferenciaunidadmbase <> 0 or crd.qtdiferenciapiezas <> 0);
     end if;
    p_Ok:=1;
    p_error:='';
    commit;
  EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       ' Error: ' || SQLERRM);
      p_Ok    := 0;
      p_error:='Error Control Remito. Comuniquese con Sistemas!';
  END SetControl;
  
   /****************************************************************************************************
  * %v 03/07/2020 - ChM  Versión inicial SetControlarRemito
  * %v 03/07/2020 - ChM  recibe un idcontrol para validar contra el remito
  *****************************************************************************************************/
  PROCEDURE SetControlarRemito(p_idControl          IN  tblslvremito.idremito%type,
                               p_Ok                 OUT number,
                               p_error              OUT varchar2) IS

    v_modulo           varchar2(100) := 'PKG_SLV_CONTROL.SetControl';
    v_estado           tblslvremito.cdestado%type:=null;
    v_error            varchar2(250); 
    v_idremito         tblslvcontrolremito.idremito%type;  
    v_qtcontrol        tblslvcontrolremito.qtcontrol%type:=0;
    v_band             integer:=0;   
    
  BEGIN
     --valida si existe el p_idControl en tblslvcontrolremito 
     begin        
          select cr.cdestado,
                 cr.idremito,
                 cr.qtcontrol                
            into v_estado,
                 v_idremito,
                 v_qtcontrol               
            from tblslvcontrolremito cr
           where cr.idcontrolremito = p_idControl; 
     exception               
        when no_data_found then
           p_Ok    := 0;
           p_error := 'Error Control Remito N° '||p_idControl||' No existe.';
          return; 
     end;
    
     --valida si existe el p_idControl en tblslvcontrolremitodet y se piqueo algo
     begin        
          select crd.idcontrolremitodet              
            into v_band              
            from tblslvcontrolremitodet crd
           where crd.idcontrolremito = p_idControl
           -- verifica que se piqueo algo 
             and nvl(crd.qtunidadmedidabasepicking,0)<>0
             and nvl(crd.qtpiezaspicking,0)<>0
             and rownum=1; 
      exception
      when no_data_found then
        n_pkg_vitalpos_log_general.write(2,
                                        'Modulo: ' || v_modulo ||
                                        '  Control de Remito Sin detalle Piqueado ');
        p_Ok    := 0;
        p_error := 'Error Control Remito N° '||p_idControl||' No tiene artículos picking.';
        ROLLBACK;
        RETURN;           
    end;   
       
    --verifica si esta Controlado
    if v_estado = C_Controlado then
       p_Ok    := 0;
       p_error := 'Error Control Remito N° '||p_idControl||' Ya Controlado.';
       RETURN;
    end if;  
   --busca las diferencias del control con el remito y las actualiza en el tblslvcontrolremitodet
      v_band:=0;
      for control in
          (select cr.idremito,
                  crd.idcontrolremitodet,         
                  crd.cdarticulo,
                  crd.qtunidadmedidabasepicking,
                  crd.qtpiezaspicking
             from tblslvcontrolremito       cr,
                  tblslvcontrolremitodet    crd
            where cr.idcontrolremito = crd.idcontrolremito         
              and cr.idcontrolremito = p_idControl)   
       loop
          for remito in
             (select rd.cdarticulo,
                     sum(rd.qtunidadmedidabasepicking) qtbase,
                     sum(rd.qtpiezaspicking) qtpiezas               
                from tblslvremitodet rd
               where rd.idremito = control.idremito
                 and rd.cdarticulo = control.cdarticulo
            group by rd.cdarticulo)
         loop
            --Actualiza las diferencias
            v_band:=1;
            --limpio qtbase si es pesable
            if remito.qtpiezas <>0 then
               remito.qtbase:=0; 
            end if;  
             v_error:='Falla UPDATE tblslvcontrolremitodet';
            update tblslvcontrolremitodet crd
               --decode para limpiar qtunidadmedidabasepicking a cero si es pesable
               set crd.qtdiferenciaunidadmbase = nvl(crd.qtunidadmedidabasepicking,0)-remito.qtbase,
                   crd.qtdiferenciapiezas = nvl(crd.qtpiezaspicking,0) - remito.qtpiezas,
                   crd.dtupdate=sysdate
             where crd.idcontrolremito = p_idControl
               and crd.cdarticulo = control.cdarticulo
               and crd.idcontrolremitodet = control.idcontrolremitodet;
              IF SQL%ROWCOUNT = 0 THEN
                     n_pkg_vitalpos_log_general.write(2,
                                                      'Modulo: ' || v_modulo ||
                                                      '  Detalle Error: ' || v_error);
                     p_Ok    := 0;
                     p_error:='Error. Comuniquese con Sistemas';
                     ROLLBACK;
                     RETURN;
                 END IF;       
         end loop; 
         -- si no existe en remito v_band en cero es sobrante se actualiza todo como diferencia negativa    
         if v_band = 0 then              
             v_error:='Falla UPDATE tblslvcontrolremitodet';
            update tblslvcontrolremitodet crd               
               set crd.qtdiferenciaunidadmbase = nvl(-crd.qtunidadmedidabasepicking,0),
                   crd.qtdiferenciapiezas = nvl(-crd.qtpiezaspicking,0),
                   crd.dtupdate=sysdate
             where crd.idcontrolremito = p_idControl
               and crd.cdarticulo = control.cdarticulo
               and crd.idcontrolremitodet = control.idcontrolremitodet;
              IF SQL%ROWCOUNT = 0 THEN
                     n_pkg_vitalpos_log_general.write(2,
                                                      'Modulo: ' || v_modulo ||
                                                      '  Detalle Error: ' || v_error);
                     p_Ok    := 0;
                     p_error:='Error. Comuniquese con Sistemas';
                     ROLLBACK;
                     RETURN;
                 END IF;       
           else
             --pone la bandera a cero para revisar en remito el siguiente articulo a controlar
             v_band:=0;
           end if;         
    end loop; 
    --listado de articulos del remito que no están en el control
      for remito in
             (select rd.cdarticulo,
                     sum(rd.qtunidadmedidabasepicking) qtbase,
                     sum(rd.qtpiezaspicking) qtpiezas               
                from tblslvremitodet rd
               where rd.idremito = v_idremito
                  -- devuelve solo los cdarticulos de remito que no estan en tblslvcontrolremitodet
                 and rd.cdarticulo not in (select crd.cdarticulo
                                             from tblslvcontrolremitodet crd
                                            where crd.idcontrolremito = p_idControl) 
            group by rd.cdarticulo)
       loop
         --limpio qtbase si es pesable
        if remito.qtpiezas <>0 then
           remito.qtbase:=0; 
        end if;  
        --si estan en remito y no controlado lo inserto en tblslvcontrolremitodet  
        --con diferencias negativas y valor de picking null   
        v_error:='Falla Insert tblslvcontrolremitodet';
        insert into tblslvcontrolremitodet
                   (idcontrolremitodet,
                    idcontrolremito,
                    cdarticulo,
                    qtdiferenciaunidadmbase,
                    qtdiferenciapiezas,
                    qtunidadmedidabasepicking,
                    qtpiezaspicking,
                    dtinsert,
                    dtupdate)
             values (seq_controlremitodet.nextval,
                     p_idControl,
                     remito.cdarticulo,
                     -remito.qtbase,
                     -remito.qtpiezas,
                     null,
                     null,
                     sysdate,
                     null);
          IF SQL%ROWCOUNT = 0 THEN
             n_pkg_vitalpos_log_general.write(2,
                                              'Modulo: ' || v_modulo ||
                                              '  Detalle Error: ' || v_error);
             p_Ok    := 0;
             p_error:='Error al insertar Artículo';
             ROLLBACK;
             RETURN;
         END IF; 
       end loop;
     
    --valida si no hay diferencias  
    v_band:=-1;
    select count (*)
      into v_band
      from tblslvcontrolremitodet    crd
     where crd.idcontrolremito = p_idControl
       and crd.qtdiferenciaunidadmbase = 0 
       and crd.qtdiferenciapiezas = 0;
     --paso tblslvcontrolremito estado controlado  
     if v_band = 0  then
        v_error:='Falla UPDATE tblslvcontrolremito';
       update tblslvcontrolremito cr
          set cr.cdestado = C_Controlado,
              cr.dtfin = sysdate
        where cr.idcontrolremito=p_idControl;
              IF SQL%ROWCOUNT = 0 THEN
                 n_pkg_vitalpos_log_general.write(2,
                                                  'Modulo: ' || v_modulo ||
                                                  '  Detalle Error: ' || v_error);
                 p_Ok    := 0;
                 p_error:='Error. Comuniquese con Sistemas';
                 ROLLBACK;
                 RETURN;
             END IF;
       --si remito controlado termina procedimiento          
       p_Ok:=1;
       p_error:='';
       commit;  
       RETURN;        
     end if;

  --valido si es el primer control del remito y llega a esta condición hay diferencias
  if  v_qtcontrol = 1 then
       --actualiza a 2 tblslvcontrolremito, para iniciar el segundo piking
       v_error:='Falla UPDATE tblslvcontrolremito';
       update tblslvcontrolremito cr
          set cr.qtcontrol=2
        where cr.idcontrolremito=p_idControl;
              IF SQL%ROWCOUNT = 0 THEN
                 n_pkg_vitalpos_log_general.write(2,
                                                  'Modulo: ' || v_modulo ||
                                                  '  Detalle Error: ' || v_error);
                 p_Ok    := 0;
                 p_error:='Error. Comuniquese con Sistemas';
                 ROLLBACK;
                 RETURN;
             END IF;
            --actualiza a null en tblslvcontrolremitodet los picking con diferencias para volver a piquear  
            v_error:='Falla UPDATE tblslvcontrolremitodet';        
            update tblslvcontrolremitodet crd               
               set crd.qtunidadmedidabasepicking = null,
                   crd.qtdiferenciapiezas = null,
                   crd.dtupdate = sysdate
             where crd.idcontrolremito = p_idControl
               and (crd.qtdiferenciaunidadmbase<>0 or crd.qtdiferenciapiezas <>0);
              IF SQL%ROWCOUNT = 0 THEN
                 n_pkg_vitalpos_log_general.write(2,
                                                  'Modulo: ' || v_modulo ||
                                                  '  Detalle Error: ' || v_error);
                 p_Ok    := 0;
                 p_error:='Error. Comuniquese con Sistemas';
                 ROLLBACK;
                 RETURN;
             END IF; 
   --actualiza a estado 2 y termina procedimiento          
   p_Ok:=0;
   p_error := 'Control Remito N° '||p_idControl||' con diferencias, por favor volver a controlar.';
   commit;  
   RETURN;             
  end if; 
  --valido si es el segundo control del remito y llega a esta condición hay diferencias
  if  v_qtcontrol = 2 then
     --actualiza a CONTROLADO la tblslvcontrolremito
       v_error:='Falla UPDATE tblslvcontrolremito';
       update tblslvcontrolremito cr
          set cr.cdestado = C_Controlado,
              cr.dtfin = sysdate
        where cr.idcontrolremito=p_idControl;
              IF SQL%ROWCOUNT = 0 THEN
                 n_pkg_vitalpos_log_general.write(2,
                                                  'Modulo: ' || v_modulo ||
                                                  '  Detalle Error: ' || v_error);
                 p_Ok    := 0;
                 p_error:='Error. Comuniquese con Sistemas';
                 ROLLBACK;
                 RETURN;
             END IF;
   p_Ok:=0;
   p_error := 'Control Remito N° '||p_idControl||' Controlado con diferencias por favor ver Reporte.';
   commit;  
   RETURN;             
  end if; 
  EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       ' Error: ' || SQLERRM);
      p_Ok    := 0;
      p_error:='Error Control Remito. Comuniquese con Sistemas!';
  END SetControlarRemito;
  

end PKG_SLV_CONTROL;
/
