CREATE OR REPLACE PACKAGE PKG_SLV_CONTROL is
  /**********************************************************************************************************
  * Author  : CHARLES MALDONADO
  * Created : 01/07/2020 03:45:03 p.m.
  * %v Paquete para gestión y control de REMITOS SLV
  **********************************************************************************************************/
  -- Tipos de datos

  TYPE CURSOR_TYPE IS REF CURSOR;
  
                                                                                                                                                                           

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
  * %v 01/07/2020 - ChM  Versión inicial SetControl
  * %v 01/07/2020 - ChM  recibe un idremito para iniciar su control inserta los articulos
  *****************************************************************************************************/
  PROCEDURE SetControl(p_idremito           IN  tblslvremito.idremito%type,
                       p_idpersona          IN  personas.idpersona%type,
                       p_cdarticulo         IN  articulos.cdarticulo%type default null,
                       p_qtunidadbase       IN  tblslvremitodet.qtunidadmedidabasepicking%type default 0,
                       p_qtpiezas           IN  tblslvremitodet.qtpiezaspicking%type default 0,
                       p_Ok                 OUT number,
                       p_error              OUT varchar2) IS

    v_modulo      varchar2(100) := 'PKG_SLV_CONTROL.SetControl';
    v_estado      tblslvremito.cdestado%type:=null;
    v_error       varchar2(250);
    v_idcontrol   tblslvcontrolremito.idcontrolremito%type;
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
    --verifico si esta finalizado
    if v_estado <> C_FinalizadoRemito then
       p_Ok    := 0;
       p_error := 'Error Remito N° '||p_idremito||' No Finalizado.';
       RETURN;
    end if; 
    --si p_cdarticulo es nulo solo creo tblslvcontrolremito OJO REVISAR SI SE PUEDE CREAR EL UK DE IDREMITO
    if p_cdarticulo is null  then
        v_error:='Falla Insert tblslvcontrolremito';
        insert into tblslvcontrolremito
                   (idcontrolremito,
                    idremito,
                    cdestado,
                    idpersonacontrol,
                    qtcontrol,
                    dtinicio,
                    dtfin)
             values (seq_controlremito.nextval,
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
    else --si p_cdarticulo tiene valor 
       --valida si existe el remito el tblslvcontrolremito obtiene el idcontrol
       begin        
            select cr.idcontrolremito
              into v_idcontrol
              from tblslvcontrolremito cr
             where cr.idremito=p_idremito
             -- control no terminado
               and cr.cdestado <> C_Controlado; 
           exception            
           when no_data_found then
            p_Ok    := 0;
            p_error := 'Error Remito N° '||p_idremito||' no creado el control.';
            return;   
         end;
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
                     v_idcontrol,
                     p_cdarticulo,
                     0,
                     0,
                     p_qtunidadbase,
                     p_qtpiezas,
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

end PKG_SLV_CONTROL;
/
