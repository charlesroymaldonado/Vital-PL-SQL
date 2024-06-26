create or replace package PKG_SLV_TAREAS is
  /**********************************************************************************************************
  * Author  : CMALDONADO_C
  * Created : 13/02/2020 01:45:03 P.m.
  * %v Paquete para gesti�n y asignaci�n de tareas SLV
  **********************************************************************************************************/
  -- Tipos de datos

  TYPE CURSOR_TYPE IS REF CURSOR;

  TYPE arr_cdarticulo IS TABLE OF CHAR(8) INDEX BY PLS_INTEGER;

  --Procedimientos y Funciones
  PROCEDURE GetListaConsolidadoM(p_Cursor OUT CURSOR_TYPE);

  PROCEDURE GetListaArmadores(p_Cursor OUT CURSOR_TYPE);

  PROCEDURE GetArticulosConsolidadoM(p_idConsolidadoM IN Tblslvconsolidadom.Idconsolidadom%type,
                                     p_Cursor         OUT CURSOR_TYPE);

  PROCEDURE GetArticulosConsolidadoComi(p_Idconsolidadocomi IN Tblslvconsolidadocomi.Idconsolidadocomi%type,
                                        p_Cursor            OUT CURSOR_TYPE);

  PROCEDURE SetAsignaArticulosArmador(p_cdArticulos   IN arr_cdarticulo,
                                      p_idConsolidado IN integer,
                                      p_TipoTarea     IN tblslvtipotarea.cdtipo%type,
                                      p_IdPersona     IN personas.idpersona%type,
                                      p_IdArmador     IN personas.idpersona%type,
                                      p_Ok            OUT number,
                                      p_error         OUT varchar2);

  PROCEDURE GetIngreso(p_login     IN cuentasusuarios.dsloginname%type,
                       p_password  IN cuentasusuarios.vlpassword%type,
                       p_idpersona OUT personas.idpersona%type,
                       p_esarmador  OUT tblslvtipotarea.icgeneraremito%type,
                       p_Ok        OUT number,
                       p_error     OUT varchar2);

  PROCEDURE GetlistadoPicking(p_IdPersona          IN personas.idpersona%type,
                              p_idRemito           OUT tblslvremito.idremito%type,
                              p_NroCarreta         OUT tblslvremito.nrocarreta%type,
                              p_icGeneraRemito     OUT tblslvtipotarea.icgeneraremito%type,
                              p_IdTarea            OUT tblslvtarea.idtarea%type,
                              p_Tarea              OUT  varchar2,     
                              p_Ok                 OUT number,
                              p_error              OUT varchar2,
                              p_Cursor             OUT CURSOR_TYPE);
                              
  PROCEDURE SetRegistrarPicking(p_IdPersona  IN personas.idpersona%type,
                                p_idRemito   IN tblslvremito.idremito%type,
                                p_NroCarreta IN tblslvremito.nrocarreta%type,
                                p_cdBarras   IN barras.cdeancode%type,
                                p_cantidad   IN tblslvtareadet.qtunidadmedidabase%type,
                                p_cdarticulo IN tblslvtareadet.cdarticulo%type,
                                p_IdTarea    IN tblslvtarea.idtarea%type,
                                p_Ok         OUT number,
                                p_error      OUT varchar2);
  PROCEDURE GetPrioridadTarea(p_IdArmador       IN   personas.idpersona%type,
                              p_Cursor          OUT  CURSOR_TYPE);                            
                                
  FUNCTION SetPrioridadTarea(p_IdTarea            tblslvtarea.idtarea%type,
                            p_Prioridad          tblslvtarea.prioridad%type) 
                                RETURN INTEGER;                                

-- SOLO PARA PROBAR

FUNCTION limpiar_tarea(p_IdTarea            tblslvtarea.idtarea%type) 
                                RETURN INTEGER;

end PKG_SLV_TAREAS;
/
create or replace package body PKG_SLV_TAREAS is
/***************************************************************************************************
*  %v 13/02/2020  ChM - Parametros globales del PKG
****************************************************************************************************/
--c_qtDecimales                                  CONSTANT number := 2; -- cantidad de decimales para redondeo
 g_cdSucursal      sucursales.cdsucursal%type := trim(getvlparametro('CDSucursal',
                                                                      'General'));
  c_ConsolidadoMulti CONSTANT tblslvtipotarea.cdtipo%type := 1; 
   c_ConsolidadoComi CONSTANT tblslvtipotarea.cdtipo%type := 5;                                                                     
 /****************************************************************************************************
  * %v 13/02/2020 - ChM  Versi�n inicial GetListaConsolidadoM
  * %v 13/02/2020 - ChM  lista los consolidados Multicanal distintos de estado 3 (finalizado)
  *****************************************************************************************************/
  PROCEDURE GetListaConsolidadoM(p_Cursor     OUT CURSOR_TYPE) IS
   
   v_modulo varchar2(100) := 'PKG_SLV_TAREAS.GetListaConsolidadoM';
  
    BEGIN             
      OPEN p_Cursor FOR 
             Select distinct m.idconsolidadom, 
                    'Consolidado M: '||m.idconsolidadom||
                    ' Creado: '||to_char(m.dtinsert,'dd/mm/yyyy') NroConsolidado        
               from tblslvconsolidadom m,
                    tblslvconsolidadomdet det             
              where m.idconsolidadom = det.idconsolidadom
                and m.cdestado in (1,2) --estado consolidado multicanal no finalizado               
                --valida no listar consolidadoM ya asignados totalmente al armador
                and det.cdarticulo not in(select td.cdarticulo  
                                            from tblslvtarea ta, 
                                                 tblslvtareadet td
                                           where ta.idtarea=td.idtarea
                                             and ta.idconsolidadom=m.idconsolidadom
                                             and ta.idpersona= m.idpersona
                                             and ta.cdtipo= c_ConsolidadoMulti); 
    EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       '  Error: ' || SQLERRM);                           
    END GetListaConsolidadoM;
    
 /****************************************************************************************************
  * %v 13/02/2020 - ChM  Versi�n inicial GetListaArmadores
  * %v 13/02/2020 - ChM  lista todas las personas del grupo Armadores
  *****************************************************************************************************/
  PROCEDURE GetListaArmadores(p_Cursor     OUT CURSOR_TYPE) IS
   
   v_modulo varchar2(100) := 'PKG_SLV_TAREAS.GETlistaArmadores';
  
    BEGIN             
      OPEN p_Cursor FOR 
             Select pe.Idpersona,
                    upper(pe.dsnombre) || ' ' || upper(pe.dsapellido) Armador 
               from permisos p, 
                    personas pe
              where p.idpersona = pe.idpersona
                and upper(p.nmgrupotarea)='EXPEDICION' 
           order by Armador;

    EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       '  Error: ' || SQLERRM);                           
  END GetListaArmadores;    
    
 /****************************************************************************************************
  * %v 13/02/2020 - ChM  Versi�n inicial GetArticulosConsolidadoM
  * %v 13/02/2020 - ChM  lista los articulos que conforman un IdConsolidadoM
  *****************************************************************************************************/
  PROCEDURE GetArticulosConsolidadoM(p_idConsolidadoM  IN  Tblslvconsolidadom.Idconsolidadom%type,
                                     p_Cursor          OUT CURSOR_TYPE) IS
   
   v_modulo varchar2(100) := 'PKG_SLV_TAREAS.GetArticulosConsolidadoM';
  
    BEGIN             
      OPEN p_Cursor FOR 
             Select m.idconsolidadom, 
                    gs.cdgrupo||' - ' ||gs.dsgruposector||' ('||sec.dssector || ')' Sector,
                    det.cdarticulo cdArticulo,
                    art.cdarticulo || '- ' || des.vldescripcion Articulo,
                    PKG_SLVArticulos.SetFormatoArticulos(art.cdarticulo,det.qtunidadmedidabase) Cantidad
               from tblslvconsolidadom m,
                    tblslvconsolidadomdet det,
                    tblslv_grupo_sector gs,
                    sectores sec,
                    descripcionesarticulos des,
                    articulos art
              where m.idconsolidadom = det.idconsolidadom
                and det.cdarticulo = art.cdarticulo
                and det.idgrupo_sector = gs.idgrupo_sector
                and m.cdestado in (1,2) --estado consolidado multicanal no finalizado 
                and sec.cdsector = gs.cdsector
                and art.cdarticulo = des.cdarticulo
                and gs.cdsucursal =  g_cdSucursal
                and m.idconsolidadom = p_idConsolidadoM
                --valida no listar articulos ya asignados al armador
                and det.cdarticulo not in(select td.cdarticulo  
                                            from tblslvtarea ta, 
                                                 tblslvtareadet td
                                           where ta.idtarea=td.idtarea
                                             and ta.idconsolidadom=m.idconsolidadom
                                             and ta.idpersona= m.idpersona
                                             and ta.cdtipo= c_ConsolidadoMulti); 
    EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       '  Error: ' || SQLERRM);                           
  END GetArticulosConsolidadoM;   
       
 /****************************************************************************************************
  * %v 14/02/2020 - ChM  Versi�n inicial GetArticulosConsolidadoComi
  * %v 14/02/2020 - ChM  lista los articulos que conforman un IdConsolidadoComi
  *****************************************************************************************************/
  PROCEDURE GetArticulosConsolidadoComi(p_IdconsolidadoComi  IN  Tblslvconsolidadocomi.Idconsolidadocomi%type,
                                        p_Cursor             OUT CURSOR_TYPE) IS
   
   v_modulo varchar2(100) := 'PKG_SLV_TAREAS.GetArticulosConsolidadoComi';
  
    BEGIN             
      OPEN p_Cursor FOR 
             Select cm.idconsolidadocomi, 
                    gs.cdgrupo||' - ' ||gs.dsgruposector||' ('||sec.dssector || ')' Sector,
                    cdet.cdarticulo cdArticulo,
                    art.cdarticulo || '- ' || des.vldescripcion Articulo,
                    PKG_SLVArticulos.SetFormatoArticulos(art.cdarticulo,cdet.qtunidadmedidabase) Cantidad
               from tblslvconsolidadocomi cm,
                    tblslvconsolidadocomidet cdet,
                    tblslv_grupo_sector gs,
                    sectores sec,
                    descripcionesarticulos des,
                    articulos art
              where cm.idconsolidadocomi = cdet.idconsolidadocomi
                and cdet.cdarticulo = art.cdarticulo
                and cdet.idgrupo_sector = gs.idgrupo_sector
                and cm.cdestado in (34,35) --estado de consolidado comisionista no finalizado 
                and sec.cdsector = gs.cdsector
                and art.cdarticulo = des.cdarticulo
                and gs.cdsucursal =  g_cdSucursal
                and cm.idconsolidadocomi = p_IdconsolidadoComi 
                --valida no listar articulos ya asignados al armador
                and cdet.cdarticulo not in(select td.cdarticulo  
                                            from tblslvtarea ta, 
                                                 tblslvtareadet td
                                           where ta.idtarea=td.idtarea
                                             and ta.idconsolidadocomi=cm.idconsolidadocomi
                                             and ta.idpersona= cm.idpersona
                                             and ta.cdtipo= c_ConsolidadoComi); 
    EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       '  Error: ' || SQLERRM);                           
  END GetArticulosConsolidadoComi;  
  
  /****************************************************************************************************
  * %v 14/02/2020 - ChM  Versi�n inicial SetAsignaArtConsolidadoM
  * %v 14/02/2020 - ChM  crea las tareas de picking por armador solo para tblslvconsolidadoM
  *****************************************************************************************************/
  PROCEDURE SetAsignaArtConsolidadoM (p_cdArticulos    IN  arr_cdarticulo,
                                      p_idConsolidado  IN  integer,
                                      p_IdPersona      IN  personas.idpersona%type,
                                      p_IdArmador      IN  personas.idpersona%type,
                                      p_Ok             OUT number) IS
                                      
    v_modulo    varchar2(100) := 'PKG_SLV_TAREAS.SetAsignaArtConsolidadoM';
    v_error     varchar2(200);
    v_prioridad integer;
    
  BEGIN
     
       select nvl(max(ta.prioridad),0)+1
         into v_prioridad
         from tblslvtarea ta 
        where ta.idpersonaarmador = p_IdArmador
          --diferente de finalizada la tarea
          and ta.cdestado not in (6,17,24,32,35)
          -- verifica la prioridad del actual dia  
          and to_char(ta.dtinsert,'dd/mm/yyyy') = to_char(sysdate,'dd/mm/yyyy');
       
      --inserta la cabezera de la tarea
      insert into tblslvtarea 
             values (seq_tarea.nextval,
                     null, --idfaltante
                     p_idConsolidado, --idconsolidadoM
                     null, --idconsolidadopedido
                     null, --idconsolidadocomi
                     1,    --TipoTarea 1 ConsolidadoM
                     p_IdPersona, 
                     p_IdArmador, 
                     null,  --dtinicio   
                     null,  --dtfin
                     v_prioridad,  --prioridad
                     4,    -- cdestado TareaConsolidadoM
                     sysdate, --dtinsert
                     null   --dtupdate
                     );
    --itera cada articulo del arreglo            
    FOR i IN 1 .. p_cdArticulos.count LOOP 
         --inserta el detalle de la tarea asignada por Armador por articulo 
         v_error := 'Falla INSERT tblslvtareadet IdPersona: ' ||
                 p_IdPersona||' Armador: '||p_IdArmador||
                 ' Articulo: ' ||p_cdArticulos(i);
           insert into tblslvtareadet  
                select seq_tareadet.nextval,
                       seq_tarea.currval,
                       det.cdarticulo,
                       det.qtunidadmedidabase,
                       null,   --qtunidadmedidabasepicking
                       null,   --qtpiezas
                       null,   --qtpiezaspicking
                       sysdate,--dtinsert
                       null,    --dtupdate
                       0        --icfinalizado
                  from tblslvconsolidadomdet det,
                       tblslvconsolidadom m
                 where det.idconsolidadom=m.idconsolidadom
                   and m.idpersona=p_IdPersona
                   and det.idconsolidadom=p_idConsolidado
                   and det.cdarticulo=p_cdArticulos(i);
        IF SQL%ROWCOUNT = 0  THEN      --valida insert de la tabla tblslvtareadet 
           n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       ' Detalle Error: ' || v_error);
   	       p_Ok:=0;  
           ROLLBACK;                                
           RETURN;
        END IF;             
    END LOOP;
    --actualiza el estado del consolidadoM a 2 
     v_error := 'Falla UPDATE tblslvconsolidadom IdPersona: ' ||
      p_IdPersona||' Armador: '||p_IdArmador;
    UPDATE tblslvconsolidadom m
       SET m.cdestado = 2 --en curso
     WHERE m.idconsolidadom = p_idConsolidado
       AND m.idpersona = p_IdPersona;
       IF SQL%ROWCOUNT = 0  THEN      --valida insert de la tabla tblslvconsolidadom
           n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       ' Detalle Error: ' || v_error);
   	       p_Ok:=0;  
           ROLLBACK;                                
           RETURN;
        END IF;     
     p_Ok:=1;
  EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       ' Detalle Error: ' || v_error||                                     
                                       ' Error: ' || SQLERRM);
      p_Ok    := 0;
      ROLLBACK;
  END SetAsignaArtConsolidadoM;    
  
  /****************************************************************************************************
  * %v 14/02/2020 - ChM  Versi�n inicial SetAsignaArtConsolidadoComi
  * %v 14/02/2020 - ChM  crea las tareas de picking por armador solo para tblslvconsolidadoComi
  *****************************************************************************************************/
  PROCEDURE SetAsignaArtConsolidadoComi (p_cdArticulos    IN  arr_cdarticulo,
                                         p_idConsolidado  IN  integer,
                                         p_IdPersona      IN  personas.idpersona%type,
                                         p_IdArmador      IN  personas.idpersona%type,
                                         p_Ok             OUT number) IS
                                      
    v_modulo  varchar2(100) := 'PKG_SLV_TAREAS.SetAsignaArtConsolidadoComi';
    v_error   varchar2(200);
    v_prioridad integer;
    
  BEGIN
       select nvl(max(ta.prioridad),0)+1
         into v_prioridad
         from tblslvtarea ta 
        where ta.idpersonaarmador = p_IdArmador
          --diferente de finalizada la tarea
          and ta.cdestado not in (6,17,24,32,35)
          -- verifica la prioridad del actual dia  
          and to_char(ta.dtinsert,'dd/mm/yyyy') = to_char(sysdate,'dd/mm/yyyy');
           
      --inserta la cabezera de la tarea
      insert into tblslvtarea 
             values (seq_tarea.nextval,
                     null, --idfaltante
                     null, --idconsolidadoM
                     null, --idconsolidadopedido
                     p_idConsolidado, --idconsolidadocomi
                     5,    --TipoTarea 5 ConsolidadoComi de la tabla tblslvtarea
                     p_IdPersona, 
                     p_IdArmador, 
                     null,  --dtinicio   
                     null,  --dtfin
                     v_prioridad,  --prioridad
                     33,    -- cdestado 33 asignado TareaConsolidadoComi de la tabla tblslvestado
                     sysdate, --dtinsert
                     null   --dtupdate
                     );
    --itera cada articulo del arreglo            
    FOR i IN 1 .. p_cdArticulos.count LOOP 
         --inserta el detalle de la tarea asignada por Armador por articulo 
         v_error := 'Falla INSERT tblslvtareadet IdPersona: ' ||
                 p_IdPersona||' Armador: '||p_IdArmador||
                 ' Articulo: ' ||p_cdArticulos(i);
           insert into tblslvtareadet  
                select seq_tareadet.nextval,
                       seq_tarea.currval,
                       det.cdarticulo,
                       det.qtunidadmedidabase,
                       null,   --qtunidadmedidabasepicking
                       null,   --qtpiezas
                       null,   --qtpiezaspicking
                       sysdate,--dtinsert
                       null,    --dtupdate
                       0       --icfinalizado
                  from tblslvconsolidadocomidet det,
                       tblslvconsolidadocomi m
                 where det.idconsolidadocomi=m.idconsolidadocomi
                   and m.idpersona=p_IdPersona
                   and det.idconsolidadocomi=p_idConsolidado
                   and det.cdarticulo=p_cdArticulos(i);
        IF SQL%ROWCOUNT = 0  THEN      --valida insert de la tabla tblslvtareadet 
           n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       ' Detalle Error: ' || v_error);
   	       p_Ok:=0;  
           ROLLBACK;                                
           RETURN;
        END IF;             
    END LOOP;
     --actualiza el estado del consolidadoComi a 26 
     v_error := 'Falla UPDATE tblslvconsolidadocomi IdPersona: ' ||
      p_IdPersona||' Armador: '||p_IdArmador;
    UPDATE tblslvconsolidadocomi com
       SET com.cdestado = 26 --en curso
     WHERE com.idconsolidadocomi = p_idConsolidado
       AND com.idpersona = p_IdPersona; 
     IF SQL%ROWCOUNT = 0  THEN      --valida insert de la tabla tblslvconsolidadocomi
           n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       ' Detalle Error: ' || v_error);
   	       p_Ok:=0;  
           ROLLBACK;                                
           RETURN;
        END IF;       
     p_Ok:=1;
  EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       ' Detalle Error: ' || v_error||                                     
                                       '  Error: ' || SQLERRM);
      p_Ok    := 0;
      ROLLBACK;
  END SetAsignaArtConsolidadoComi;   
   
  /****************************************************************************************************
  * %v 14/02/2020 - ChM  Versi�n inicial SetAsignaArticulosArmador
  * %v 14/02/2020 - ChM  crea las tareas de picking por armador con la lista de articulos
  *****************************************************************************************************/
  PROCEDURE SetAsignaArticulosArmador(p_cdArticulos    IN  arr_cdarticulo,
                                      p_idConsolidado  IN  integer,
                                      p_TipoTarea      IN  tblslvtipotarea.cdtipo%type,                         
                                      p_IdPersona      IN  personas.idpersona%type,
                                      p_IdArmador      IN  personas.idpersona%type,
                                      p_Ok             OUT number,
                                      p_error          OUT varchar2) IS
    
  BEGIN
    
    --TipoTarea 1 ConsolidadoM
    if p_TipoTarea = 1 then
      SetAsignaArtConsolidadoM(p_cdArticulos,p_idConsolidado,p_IdPersona,p_IdArmador,p_Ok);
      if p_Ok <> 1 then
        p_Ok    := 0;
        p_error := 'Error Asignando Armadores. Comuniquese con Sistemas!';
        ROLLBACK;
        RETURN;
       end if;
     end if;   
    --TipoTarea 5 ConsolidadoComi
    if p_TipoTarea = 5 then
      SetAsignaArtConsolidadoComi(p_cdArticulos,p_idConsolidado,p_IdPersona,p_IdArmador,p_Ok);
      if p_Ok <> 1 then
        p_Ok    := 0;
        p_error := 'Error Asignando Armadores. Comuniquese con Sistemas!';
        ROLLBACK;
        RETURN;
       end if;          
    end if; 
     COMMIT; 
  END SetAsignaArticulosArmador;    
    
  /****************************************************************************************************
  * %v 17/02/2020 - ChM  Versi�n inicial GetIngreso
  * %v 17/02/2020 - ChM  valida que el armador este autorizado para ingresar al sistema
  *****************************************************************************************************/
  PROCEDURE GetIngreso       (p_login      IN  cuentasusuarios.dsloginname%type,
                              p_password   IN  cuentasusuarios.vlpassword%type,
                              p_idpersona  OUT personas.idpersona%type,
                              p_esarmador  OUT tblslvtipotarea.icgeneraremito%type,    
                              p_Ok         OUT number,
                              p_error      OUT varchar2) IS
                              
    v_modulo      varchar2(100) := 'PKG_SLV_TAREAS.GetIngreso';  
    v_idpersona   personas.idpersona%type;
    --v_cur_tarea   CURSOR_TYPE;
    
  BEGIN
    -- armador sergio torreblanca
      p_idpersona:= '{FD95DC1D-F3CD-4216-B87D-6BEBEE72D4E5}  ' ; --borrar 
      p_ok := 1;
      p_esarmador:=1;
      return; --borrar
    p_ok:=PosApp.PosLogin.DoLogin(p_login, p_password, p_idpersona, p_error);
--    GetTareasByUserId(v_cur_tarea,p_idpersona);  -- OJOO utilizar para validar el permiso del usuario autentificado
    --si esta autentificado revisa si es armador
    if p_ok = 0  then 
     Select pe.Idpersona
       into v_idpersona
       from permisos p, 
            personas pe
      where p.idpersona = pe.idpersona
        and upper(p.nmgrupotarea) = 'EXPEDICION' 
        and pe.idpersona = p_idpersona
        and rownum = 1;
     if(v_idpersona = p_idpersona) then
       p_esarmador:=1; --1 solo si es armador  OOOOJOOOO falta validar control
       p_ok:=1;
       p_error:=null;   
       return; 
     else
       p_ok:=0;
       p_error:='Usuario Autentificado no Armador!. Acceso Negado!!!'; 
     end if; 
   else 
      p_Ok:= 0;
      p_error:='No Autorizado para Ingresar al Sistema!';   
   end if; 
  EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       ' Error: ' || SQLERRM);
      p_Ok    := 0;
      p_error:='Error al Ingresar. Comuniquese con sistemas!';     
  END GetIngreso;      
 
 /****************************************************************************************************
  * %v 17/02/2020 - ChM  Versi�n inicial GetCarreta
  * %v 17/02/2020 - ChM  verifica si el pedido tiene carreta en curso para picking
  *****************************************************************************************************/
  
  PROCEDURE GetCarreta(p_IdPersona      IN   personas.idpersona%type,
                       p_IdTarea        IN   tblslvtarea.idtarea%type,
                       p_idRemito       OUT  tblslvremito.idremito%type,               
                       p_NroCarreta     OUT  tblslvremito.nrocarreta%type) IS
  BEGIN  
      p_idRemito:=0;               
      p_NroCarreta:=0;     
      select re.idremito,
             re.nrocarreta
        into p_idRemito,
             p_NroCarreta
        from tblslvremito re,
             tblslvtarea  ta
       where re.cdestado = 36 --remito en curso
         and ta.idpersonaarmador = p_IdPersona --id armador 
         and re.idtarea = ta.idtarea
         and re.idtarea = p_IdTarea 
         and rownum = 1;
  EXCEPTION
  WHEN NO_DATA_FOUND THEN 
    p_idRemito := 0;         
    p_NroCarreta := 0; 
  WHEN OTHERS THEN  
    p_idRemito := 0;         
    p_NroCarreta := 0;          
  END GetCarreta;                      
 
 /****************************************************************************************************
  * %v 17/02/2020 - ChM  Versi�n inicial GetlistadoPicking
  * %v 17/02/2020 - ChM  para un armador, lista los articulos pendientes para picking en tarea
  *****************************************************************************************************/
  
  PROCEDURE GetlistadoPicking(p_IdPersona         IN   personas.idpersona%type,
                              p_idRemito          OUT  tblslvremito.idremito%type,               
                              p_NroCarreta        OUT  tblslvremito.nrocarreta%type,                  
                              p_icGeneraRemito    OUT  tblslvtipotarea.icgeneraremito%type,  
                              p_IdTarea           OUT  tblslvtarea.idtarea%type,
                              p_Tarea             OUT  varchar2,       
                              p_Ok                OUT  number,
                              p_error             OUT  varchar2,
                              p_Cursor            OUT  CURSOR_TYPE) IS
                              
    v_modulo                 varchar2(100) := 'PKG_SLV_TAREAS.GetlistadoPicking'; 
    
  BEGIN
     p_idRemito:=0;               
     p_NroCarreta:=0;                  
     p_icGeneraRemito:=0;
     p_IdTarea:=0;
     p_Tarea:='';
    for tarea in 
      (select ta.idtarea,
              tip.dstarea,
              ta.idpedfaltante,
              ta.idconsolidadom,
              ta.idconsolidadopedido,
              ta.idconsolidadocomi,
              tip.icgeneraremito             
         from tblslvtarea ta,
              tblslvtipotarea tip         
        where ta.cdtipo = tip.cdtipo
          and ta.idpersonaarmador = p_IdPersona
           -- tareas disponibles segun tblslvtipotarea  OOOJOOO tarea de faltantes
          and ta.cdestado in (4,5, 15,16, 22,23,30,31,33,34)
     order by ta.prioridad) 
    loop
     begin
       --descripci�n del tipo de tarea
       p_Tarea := tarea.dstarea||' N� '||tarea.idpedfaltante||tarea.idconsolidadom
       ||tarea.idconsolidadopedido||tarea.idconsolidadocomi;
       p_IdTarea := tarea.idtarea;
       p_icGeneraRemito := tarea.icgeneraremito;
       
       if tarea.icgeneraremito = 1 then --verifica si genera remito
          getcarreta(p_IdPersona,tarea.idtarea,p_idRemito,p_NroCarreta); 
       end if;  
        
     open p_cursor for 
           select dta.cdarticulo Cdarticulo,
                  dta.cdarticulo||' - '||des.vldescripcion Articulo, 
                  PKG_SLVArticulos.GetCodigoDeBarra(dta.cdarticulo,'BTO') Barras,
                  PKG_SLVArticulos.SetFormatoArticulos(dta.cdarticulo,
                  (nvl(dta.qtunidadmedidabase,0)-nvl(dta.qtunidadmedidabasepicking,0))) Cantidad,
                  PKG_SLVArticulos.GetUbicacionArticulos(dta.cdarticulo) Ubicacion,
                  PKG_SLVArticulos.CalcularPesoUnidadBase(dta.cdarticulo,dta.qtunidadmedidabase) Peso 
             from tblslvtarea ta,
                  tblslvtareadet dta,
                  descripcionesarticulos des,
                  tblslvtipotarea tip  
            where ta.idtarea = dta.idtarea
              and ta.idtarea = tarea.idtarea 
              --id de la tarea de mayor prioridad
              and ta.cdtipo = tip.cdtipo
              and dta.cdarticulo = des.cdarticulo
              -- articulo no finalizado   
              and dta.icfinalizado = 0  
              and rownum=1
         order by Ubicacion ASC,
                  Peso DESC;
    EXCEPTION
      WHEN OTHERS THEN
           n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       ' Error: ' || SQLERRM);
           p_Ok    := 0;
           p_error:='Error en Listado. Comuniquese con sistemas!'; 
           return;           
      end;
      p_Ok := 1;
      p_error:=null;        
      return;        
    end loop;      
   p_Ok := 0;
   p_error:='No existen Tareas Pendientes!'; 
  EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       ' Error: ' || SQLERRM);
      p_Ok    := 0;
      p_error:='Error en Listado. Comuniquese con sistemas!';     
  END GetlistadoPicking;  
   /****************************************************************************************************
  * %v 19/02/2020 - ChM  Versi�n inicial VerificaTareaPicking
  * %v 19/02/2020 - ChM  para un armador y una tarea verifica si quedan articulos por pikear
  *****************************************************************************************************/
  FUNCTION VerificaTareaPicking(p_IdPersona   personas.idpersona%type,
                                p_IdTarea     tblslvtarea.idtarea%type) 
                                RETURN INTEGER IS
                                
    v_modulo      varchar2(100) := 'PKG_SLV_TAREAS.VerificaTareaPicking';                              
    v_estado      integer:=0; 
    
    BEGIN
         select count(*)
           into v_estado 
           from tblslvtarea ta,
                tblslvtareadet dta       
          where ta.idtarea = dta.idtarea
            and ta.idtarea = p_IdTarea
            and ta.idpersonaarmador = p_IdPersona
            --  tareas disponibles segun tblslvtipotarea  
            and ta.cdestado in (4,5,7,8,15,16,22,23,30,31,33,34) --OJO tareas faltantes
            --  indica que aun quedan articulos por picking en la tarea
            and dta.icfinalizado = 0; 
   if v_estado <> 0 then
     return 1; -- devuelve 1 si aun se deben pickear articulos
   else
     return 0; -- devuelve 0 si no hay articulos para pickear
   end if;
   return -1;
  EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       ' Error: ' || SQLERRM);
      return -1;                                           
  END VerificaTareaPicking;
  
   /****************************************************************************************************
  * %v 20/02/2020 - ChM  Versi�n inicial VerificaPersonaTarea
  * %v 20/02/2020 - ChM  para un armador y una tarea verifica si la tiene asignada
  *****************************************************************************************************/
  FUNCTION VerificaPersonaTarea(p_IdPersona   personas.idpersona%type,
                                p_IdTarea     tblslvtarea.idtarea%type) 
                                RETURN INTEGER IS
                                
    v_modulo      varchar2(100) := 'PKG_SLV_TAREAS.VerificaPersonaTarea';                              
    v_estado      integer:=0; 
    
    BEGIN
         select count(*)
           into v_estado 
           from tblslvtarea ta,
                tblslvtareadet dta       
          where ta.idtarea = dta.idtarea
            and ta.idtarea = p_IdTarea
            and ta.idpersonaarmador = p_IdPersona
            --  tareas asignadas o en curso segun tblslvtipotarea  
            and ta.cdestado in (4,5,7,8, 15,16, 22,23,30,31,33,34); 
   if v_estado <> 0 then
     return 1; -- devuelve 1 si la tarea esta asignada al armador
   end if;
     return 0; -- devuelve 0 si la tarea no esta asignada al armador
  EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       ' Error: ' || SQLERRM);
      return 0;                                           
  END VerificaPersonaTarea;
  
     /****************************************************************************************************
  * %v 20/02/2020 - ChM  Versi�n inicial SetInsertarRemito
  * %v 20/02/2020 - ChM  inserta remito
  *****************************************************************************************************/
  FUNCTION SetInsertarRemito(p_IdTarea               tblslvtarea.idtarea%type,
                             p_NroCarreta            tblslvremito.nrocarreta%type) 
                             RETURN INTEGER IS
                                
    v_modulo      varchar2(100) := 'PKG_SLV_TAREAS.SetInsertarRemito'; 
    v_idremito    tblslvremito.idremito%type;                         
  BEGIN
   insert into  tblslvremito 
        values (seq_remito.nextval,    --idremito
                p_IdTarea,              --idtarea
                p_NroCarreta,          --NroCarreta
                36,                    --Cdestado 36 remito en curso
                sysdate,               --dtremito
                null);                 --dtupdate     
   IF SQL%ROWCOUNT = 0  THEN 
     n_pkg_vitalpos_log_general.write(2,
                  'Modulo: ' || v_modulo ||
                  ' imposible insertar remito para la carreta: '||p_NroCarreta);
     return 0; -- devuelve 0 si no inserta
   END IF;
   --devuelve el idremito insertado
   select seq_remito.currval
     into v_idremito
     from dual;
     return v_idremito; 
  EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       ' Error: ' || SQLERRM);
      return 0;                                           
  END SetInsertarRemito;  
  
  /****************************************************************************************************
  * %v 26/02/2020 - ChM  Versi�n inicial SetDetalleRemito
  * %v 26/02/2020 - ChM  actualiza en detalle remito la cantidad ingresada en piking 
  *****************************************************************************************************/
 
  FUNCTION SetDetalleRemito(p_idRemito         tblslvremito.idremito%type,
                            p_idTarea          tblslvremito.idtarea%type,
                            p_cdArticulo       tblslvtareadet.cdarticulo%type,
                            p_cantidad         tblslvtareadet.qtunidadmedidabasepicking%type) 
                            return integer IS    
                            
   v_modulo                        varchar2(100) := 'PKG_SLV_TAREAS.SetDetalleRemito';                         
   v_res                           integer :=0;
   v_idremitodet                   tblslvremitodet.idremitodet%type:= null;
   v_qtunidadmedidabasepicking     tblslvremitodet.qtunidadmedidabasepicking%type:=null;
    
  BEGIN
   --verifica si existe remito en curso   
   select count(*)
     into v_res 
     from tblslvremito re
    where re.cdestado = 36  --Cdestado 36 remito en curso
      and re.idremito = p_idRemito
      and re.idtarea = p_idtarea;
        
      if v_res>0 then
        --verifica si existe articulo en proceso de remito y busca la cantidad picking
         select det.idremitodet,
                det.qtunidadmedidabasepicking
           into v_idremitodet,
                v_qtunidadmedidabasepicking
           from tblslvremitodet det
          where det.idremito = p_idRemito
            and det.cdarticulo=p_cdArticulo;
        -- si encuentra detalle actualiza la cantidad picking
        if v_idremitodet is not null then
          update tblslvremitodet det
             set det.qtunidadmedidabasepicking = nvl(v_qtunidadmedidabasepicking,0)+p_cantidad,
                 det.dtupdate = sysdate 
           where det.idremitodet = v_idremitodet
             and det.idremito = p_idRemito
             and det.cdarticulo = p_cdArticulo;
             IF SQL%ROWCOUNT = 0  THEN 
                n_pkg_vitalpos_log_general.write(2,
                                 'Modulo: ' || v_modulo ||
                                 ' imposible Actualizar detalle del remito : '||p_idRemito);
                                  return 0; -- devuelve 0 si no actualiza
             END IF;
         else --si no encuentra el detalle inserto el articulo en tblslvremitodet
           insert into tblslvremitodet
                values (seq_remitodet.nextval,
                        p_idRemito,
                        p_cdArticulo,
                        p_cantidad,
                        null, --qtpiezaspicking
                        sysdate,
                        null); 
            IF SQL%ROWCOUNT = 0  THEN 
                n_pkg_vitalpos_log_general.write(2,
                                 'Modulo: ' || v_modulo ||
                                 ' imposible insertar detalle del remito : '||p_idRemito);
                                  return 0; -- devuelve 0 si no inserta
             END IF;               
          end if;
          commit;  
        else
        return 0; -- devuelve 0 si no inserta ni actualiza  
      end if;  --if v_res>0 
      
    return 1;
   EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       ' Error: ' || SQLERRM);
      return 0;     
     
  END SetDetalleRemito;
    
   /****************************************************************************************************
  * %v 20/02/2020 - ChM  Versi�n inicial SetFinalizarRemito
  * %v 20/02/2020 - ChM  cambia el estado del remito a finalizado
  *****************************************************************************************************/
  FUNCTION SetFinalizarRemito(p_idremito      tblslvremito.idremito%type) 
                           RETURN INTEGER IS
                                
    v_modulo      varchar2(100) := 'PKG_SLV_TAREAS.SetFinalizarRemito';                              
    BEGIN
        update tblslvremito r
           set r.cdestado=37,
               r.dtupdate = sysdate
         where r.idremito = p_idremito;
  if SQL%ROWCOUNT = 0  then
     n_pkg_vitalpos_log_general.write(2,
                  'Modulo: ' || v_modulo ||
                  ' imposible actualizar remito numero: '||p_idremito);
     return 0; -- devuelve 0 si no actualiza
  end if;  
     return 1; -- devuelve 1 si actualiza
  EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       ' Error: ' || SQLERRM);
      return 0;                                           
  END SetFinalizarRemito; 
  
  /****************************************************************************************************
  * %v 21/02/2020 - ChM  Versi�n inicial SetEstadoTarea
  * %v 21/02/2020 - ChM  actualiza estado de la tarea segun parametro 1 en curso 0 finalizado
  *****************************************************************************************************/
  FUNCTION SetEstadoTarea(p_IdTarea          tblslvtarea.idtarea%type,
                          p_band             integer default 1) 
                           return integer IS    
                           
   v_tipo                 tblslvtarea.cdtipo%type; 
   v_modulo               varchar2(100) := 'PKG_SLV_TAREAS.SetEstadoTarea';  
                                                                        
  BEGIN    
     select ta.cdtipo
         into v_tipo
         from tblslvtarea ta
        where ta.idtarea = p_IdTarea;  
       --tipo consolidadoM     
       if v_tipo=1 then
         if p_band = 1 then -- 1 en curso 0 finalizado
           update tblslvtarea ta
              set ta.cdestado = 5,
                  ta.dtupdate = sysdate,
                  ta.dtinicio = sysdate
            where ta.idtarea = p_IdTarea;
         else
           update tblslvtarea ta
              set ta.cdestado = 6,
                  ta.dtupdate = sysdate,
                  ta.dtfin = sysdate
            where ta.idtarea = p_IdTarea;
         end if;  
       end if;
        --tipo faltante consolidadoM     
        if v_tipo=2 then
          if p_band = 1 then -- 1 en curso 0 finalizado
           update tblslvtarea ta
              set ta.cdestado = 8,
                  ta.dtupdate = sysdate,
                  ta.dtinicio = sysdate
            where ta.idtarea = p_IdTarea;
         else
           update tblslvtarea ta
              set ta.cdestado = 9,
                  ta.dtupdate = sysdate,
                  ta.dtfin = sysdate
            where ta.idtarea = p_IdTarea;
         end if;  
       end if;
        --tipo consolidado pedido   
        if v_tipo=3 then
           if p_band = 1 then -- 1 en curso 0 finalizado
           update tblslvtarea ta
              set ta.cdestado = 16,
                  ta.dtupdate = sysdate,
                  ta.dtinicio = sysdate
            where ta.idtarea = p_IdTarea;
         else
           update tblslvtarea ta
              set ta.cdestado = 17,
                  ta.dtupdate = sysdate,
                  ta.dtfin = sysdate
            where ta.idtarea = p_IdTarea;
         end if;  
       end if;
        --tipo faltante consolidado pedido   
        if v_tipo=4 then
           if p_band = 1 then -- 1 en curso 0 finalizado
           update tblslvtarea ta
              set ta.cdestado = 19,
                  ta.dtupdate = sysdate,
                  ta.dtinicio = sysdate
            where ta.idtarea = p_IdTarea;
         else
           update tblslvtarea ta
              set ta.cdestado = 20,
                  ta.dtupdate = sysdate,
                  ta.dtfin = sysdate
            where ta.idtarea = p_IdTarea;
         end if;  
       end if;
        --tipo consolidado comisionista
        if v_tipo=5 then
           if p_band = 1 then -- 1 en curso 0 finalizado
           update tblslvtarea ta
              set ta.cdestado = 34,
                  ta.dtupdate = sysdate,
                  ta.dtinicio = sysdate
            where ta.idtarea = p_IdTarea;
         else
           update tblslvtarea ta
              set ta.cdestado = 35,
                  ta.dtupdate = sysdate,
                  ta.dtfin = sysdate
            where ta.idtarea = p_IdTarea;
         end if;  
       end if;
        --tipo faltante consolidado comisionista
        if v_tipo=6 then
           if p_band = 1 then -- 1 en curso 0 finalizado
           update tblslvtarea ta
              set ta.cdestado = 31,
                  ta.dtupdate = sysdate,
                  ta.dtinicio = sysdate
            where ta.idtarea = p_IdTarea;
         else
           update tblslvtarea ta
              set ta.cdestado = 32,
                  ta.dtupdate = sysdate,
                  ta.dtfin = sysdate
            where ta.idtarea = p_IdTarea;
         end if;  
       end if;
      if SQL%ROWCOUNT = 0  then 
               n_pkg_vitalpos_log_general.write(2,
                   'Modulo: ' || v_modulo ||
                   ' imposible actualizar estado de la tarea: '||p_IdTarea);
              return -1; -- devuelve -1 si no actualiza
          end if;         
    return 1; -- devuelve 1 si actualiza    
  EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       ' Error: ' || SQLERRM);
      return 0;       
  END SetEstadoTarea;      
  /****************************************************************************************************
  * %v 20/02/2020 - ChM  Versi�n inicial SetDetalleTarea
  * %v 20/02/2020 - ChM  actualiza en detalle la cantidad ingresada en piking para una tarea
  *****************************************************************************************************/
  FUNCTION SetDetalleTarea(p_IdTarea          tblslvtarea.idtarea%type,
                           p_cdArticulo       tblslvtareadet.cdarticulo%type,
                           p_cantidad         tblslvtareadet.qtunidadmedidabasepicking%type,
                           p_cdunidad         barras.cdunidad%type,
                           p_icgeneraremito   tblslvtipotarea.icgeneraremito%type,
                           p_idRemito         tblslvremito.idremito%type) 
                           return integer IS    
                           
    v_modulo               varchar2(100) := 'PKG_SLV_TAREAS.SetDetalleTarea';                                                
    v_cantidad_base        tblslvtareadet.qtunidadmedidabase%type;
    v_cantidad_pick        tblslvtareadet.qtunidadmedidabasepicking%type;
    v_cantidad             tblslvtareadet.qtunidadmedidabase%type;
    V_UxB                  number;
    v_res                  integer;
    v_ini                  integer;
                 
  BEGIN
    --recupera el valor picking del detalle tarea
     select nvl(dta.qtunidadmedidabase,0),
            nvl(dta.qtunidadmedidabasepicking,0)
       into v_cantidad_base,
            v_cantidad_pick
       from tblslvtareadet dta
      where dta.idtarea = p_IdTarea
        and dta.cdarticulo = p_cdArticulo;
        
     --revisa si es null dtinicio para atualizar en tblslvtarea
     select count(*)
       into v_ini
       from tblslvtarea ta
      where ta.dtinicio is null
        and ta.idtarea=p_IdTarea;
    
     if v_ini>=1 then
        -- pone la tarea en curso 1 en el parametro
       if SetEstadoTarea(p_IdTarea,1)<>1 then
          return -1; -- devuelve -1 si no actualiza
        end if;  
     end if;
     --si es diferente a UN se multiplica por UxB   
     if p_cdunidad <> 'UN' then
       V_UxB:=posapp.n_pkg_vitalpos_materiales.GetUxB(p_cdArticulo);
       v_cantidad:=p_cantidad*V_UxB;
     else 
       v_cantidad:=p_cantidad;  
     end if; 
            
     --Valida que lo ingresado para picking sea menor a lo almacenado en detalle tarea
     if v_cantidad <= (v_cantidad_base-v_cantidad_pick) then
        v_cantidad := v_cantidad_pick+v_cantidad;
       update tblslvtareadet dta
          set dta.qtunidadmedidabasepicking = v_cantidad,
              dta.dtupdate = sysdate
        where dta.idtarea = p_IdTarea
          and dta.cdarticulo = p_cdArticulo;           
       if SQL%ROWCOUNT = 0  then 
          n_pkg_vitalpos_log_general.write(2,
                  'Modulo: ' || v_modulo ||
                  ' imposible actualizar articulo: '||p_cdArticulo);
          return -1; -- devuelve -1 si no actualiza
       end if;
       
      --verifica si genera remito y numero de remito existe e inserta en detalle remito
       if p_icgeneraremito = 1 and p_idRemito <> 0 then
          v_res:=SetDetalleRemito(p_idRemito,p_idTarea,p_cdArticulo,v_cantidad); 
          if v_res <> 1 then
            return -1; -- devuelve -1 si no inserta remito
            end if;
       end if;        
     else
       return  -2;  --devuelve -2 si la cantidad no es correcta
     end if; --fin del if valida cantidad
     
   return 1; -- devuelve 1 si actualiza    
   EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       ' Error: ' || SQLERRM);
      return 0;     
     
  END SetDetalleTarea;
                               
                            
    /****************************************************************************************************
  * %v 21/02/2020 - ChM  Versi�n inicial SetFindetalleTarea
  * %v 21/02/2020 - ChM  actualiza el icfinalizado del detalle tarea
  *****************************************************************************************************/
  FUNCTION SetFindetalleTarea(p_IdTarea          tblslvtarea.idtarea%type,
                              p_cdArticulo       tblslvtareadet.cdarticulo%type) 
                       return integer IS    
                           
    v_modulo               varchar2(100) := 'PKG_SLV_TAREAS.SetFindetalleTarea';                                                
   
  BEGIN
   
     --actualiza el detalle tarea a finalizado 
       update tblslvtareadet dta
          set dta.icfinalizado = 1,
              dta.dtupdate = sysdate
        where dta.idtarea = p_IdTarea
              
          and dta.cdarticulo = p_cdArticulo;           
       if SQL%ROWCOUNT = 0  then 
          n_pkg_vitalpos_log_general.write(2,
                  'Modulo: ' || v_modulo ||
                  ' imposible actualizar articulo: '||p_cdArticulo);
          return -1; -- devuelve -1 si no actualiza
        end if; 
   return 1; -- devuelve 1 si actualiza     
   EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       ' Error: ' || SQLERRM);
      return 0;     
     
  END SetFindetalleTarea;                
  
  /****************************************************************************************************
  * %v 20/02/2020 - ChM  Versi�n inicial VerificaDetalleTarea
  * %v 20/02/2020 - ChM  verifica si la cantida piking es igual a la cantidad base en la tarea para cerrar linea
  *****************************************************************************************************/
  FUNCTION VerificaDetalleTarea(p_IdTarea          tblslvtarea.idtarea%type,
                                p_cdArticulo       tblslvtareadet.cdarticulo%type) 
                           return integer IS    
                           
    v_modulo               varchar2(100) := 'PKG_SLV_TAREAS.SetDetalleTarea';                                                
    v_cantidad_base       tblslvtareadet.qtunidadmedidabase%type;
    v_cantidad_pick       tblslvtareadet.qtunidadmedidabasepicking%type;
   
  BEGIN
    
     select nvl(dta.qtunidadmedidabase,0),
            nvl(dta.qtunidadmedidabasepicking,0)
       into v_cantidad_base,
            v_cantidad_pick
       from tblslvtareadet dta
      where dta.idtarea = p_IdTarea
        and dta.cdarticulo = p_cdArticulo;
     if v_cantidad_base=v_cantidad_pick then
       return 1; -- devuelve 1 si son iguales
     end if;
   return 0;    
   EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       ' Error: ' || SQLERRM);
      return 0;     
     
  END VerificaDetalleTarea;
  
  /****************************************************************************************************
  * %v 28/02/2020 - ChM  Versi�n inicial SetFinalizarConsolidados
  * %v 28/02/2020 - ChM  finalizar los consolidados que cumplan con todo los picking
  *****************************************************************************************************/
  FUNCTION SetFinalizarConsolidados(p_IdTarea            tblslvtarea.idtarea%type) 
                                RETURN INTEGER IS  
                           
    v_modulo              varchar2(100) := 'PKG_SLV_TAREAS.SetFinalizarConsolidados';                                                
    v_cant                number;
   
  BEGIN
    NULL;
 for tarea in
 (select ta.idpedfaltante,
         ta.idconsolidadom,
         ta.idconsolidadopedido,
         ta.idconsolidadocomi,
         ta.cdtipo        
    from tblslvtarea ta        
   where ta.idtarea = p_IdTarea)
 loop
 if tarea.idconsolidadopedido is not null then
   select count(*) 
     into  v_cant
     from tblslvconsolidadopedidodet det
    where det.idconsolidadopedido = tarea.idconsolidadopedido
    --verifica sin son distintas las cantidades asginadas y pickiadas
      and nvl(det.qtunidadmedidabasepicking,0) <> nvl(det.qtunidadesmedidabase,0);
    --verifica piezas pesables  
      --and det.qtpiezas <> det.qtpiezaspicking;
      
   --si conteo es 0 se finaliza el consolidadoPedido
   if v_cant = 0 and tarea.idconsolidadopedido is not null then
      update tblslvconsolidadopedido pe
         set pe.cdestado = 12, --cerrado el consolidadoPedido
             pe.dtupdate = sysdate
       where pe.idconsolidadopedido = tarea.idconsolidadopedido;
       if SQL%ROWCOUNT = 0  then 
          n_pkg_vitalpos_log_general.write(2,
                  'Modulo: ' || v_modulo ||
                  ' imposible FINALIZAR Consolidado Pedido: '||tarea.idconsolidadopedido);
          return 0; -- devuelve 0 si no actualiza
       end if;      
   end if; 
 end if;
 if tarea.idpedfaltante is not null then  
   select count(*) 
     into  v_cant
     from tblslvpedfaltantedet det
    where det.idpedfaltante = tarea.idpedfaltante
    --verifica sin son distintas las cantidades asginadas y pickiadas
       and nvl(det.qtunidadmedidabasepicking,0) <> nvl(det.qtunidadmedidabase,0);
    --verifica piezas pesables  
      --and det.qtpiezas <> det.qtpiezaspicking;
      
   --si conteo es 0 se finaliza el ConsolidadoPedidoFaltante
   if v_cant = 0 and tarea.idpedfaltante is not null then
      update tblslvpedfaltante f
         set f.cdestado = 20, --finalizado el consolidado pedido faltante
             f.dtupdate = sysdate
       where f.idpedfaltante = tarea.idpedfaltante;
       if SQL%ROWCOUNT = 0  then 
          n_pkg_vitalpos_log_general.write(2,
                  'Modulo: ' || v_modulo ||
                  ' imposible FINALIZAR Faltante Pedido: '||tarea.idpedfaltante);
          return 0; -- devuelve 0 si no actualiza
       end if;      
   end if; 
 end if;
 if tarea.idconsolidadom is not null then 
   select count(*) 
     into  v_cant
     from tblslvconsolidadomdet det
    where det.idconsolidadom = tarea.idconsolidadom
    --verifica sin son distintas las cantidades asginadas y pickiadas
      and nvl(det.qtunidadmedidabasepicking,0) <> nvl(det.qtunidadmedidabase,0);
    --verifica piezas pesables  
      --and det.qtpiezas <> det.qtpiezaspicking;
      
   --si conteo es 0 se finaliza el consolidadoM
   if v_cant = 0 and tarea.idconsolidadom is not null then
      update tblslvconsolidadom m
         set m.cdestado = 3, --finalizado el consolidadoM
             m.dtupdate = sysdate
       where m.idconsolidadom = tarea.idconsolidadom;
       if SQL%ROWCOUNT = 0  then 
          n_pkg_vitalpos_log_general.write(2,
                  'Modulo: ' || v_modulo ||
                  ' imposible FINALIZAR ConsolidadoM: '||tarea.idconsolidadom);
          return 0; -- devuelve 0 si no actualiza
       end if;      
   end if; 
 end if; 
 if tarea.idconsolidadocomi is not null then
   select count(*) 
     into  v_cant
     from tblslvconsolidadocomidet det
    where det.idconsolidadocomi = tarea.idconsolidadocomi
    --verifica sin son distintas las cantidades asginadas y pickiadas
      and nvl(det.qtunidadmedidabasepicking,0) <> nvl(det.qtunidadmedidabase,0);
    --verifica piezas pesables  
      --and det.qtpiezas <> det.qtpiezaspicking;
      
   --si conteo es 0 se finaliza el consolidadocomi 
   if v_cant = 0 and tarea.idconsolidadocomi is not null then
      update tblslvconsolidadocomi com
         set com.cdestado = 27, --finalizado el consolidadocomi
             com.dtupdate = sysdate
       where com.idconsolidadocomi = tarea.idconsolidadocomi;
       if SQL%ROWCOUNT = 0  then 
          n_pkg_vitalpos_log_general.write(2,
                  'Modulo: ' || v_modulo ||
                  ' imposible FINALIZAR Consolidadocomi: '||tarea.idconsolidadocomi);
          return 0; -- devuelve 0 si no actualiza
       end if;      
   end if; 
  end if;   
   end loop;  
    
   return 1; 
     EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       ' Error: ' || SQLERRM);
      return 0;       
  END SetFinalizarConsolidados;
   
  /****************************************************************************************************
  * %v 21/02/2020 - ChM  Versi�n inicial SetFinalizarTarea
  * %v 21/02/2020 - ChM  Actualiza los objetos de la tarea y el estado a finalizado
  *****************************************************************************************************/
  FUNCTION SetFinalizarTarea(p_IdPersonaArmador   personas.idpersona%type,
                             p_IdTarea            tblslvtarea.idtarea%type) 
                                RETURN INTEGER IS  
                           
    v_modulo              varchar2(100) := 'PKG_SLV_TAREAS.SetFinalizarTarea';                                                
   
  BEGIN
 
 for tarea in
 (select ta.idpedfaltante,
         ta.idconsolidadom,
         ta.idconsolidadopedido,
         ta.idconsolidadocomi,
         ta.cdtipo,
         ta.idpersona,
         dta.qtunidadmedidabasepicking,
         dta.qtpiezaspicking,
         dta.cdarticulo
    from tblslvtarea ta,
         tblslvtareadet dta
   where ta.idtarea = dta.idtarea
     and ta.idtarea = p_IdTarea
     and ta.idpersonaarmador = p_IdPersonaArmador  
     --  tareas no finalizadas segun la tblslvestado
     and ta.cdestado not in (6,9,17,24,32,35)    
    --  verifica que el detalle esta finalizado
     and dta.icfinalizado = 1)
  loop
     --actualiza la cantidad picking en consolidadoM y FaltantesconsolidadoM
     if tarea.cdtipo in(1,2) and tarea.idconsolidadom is not null then    
      update tblslvconsolidadomdet dm
          set (qtunidadmedidabasepicking,
              qtpiezaspicking) =
              (select nvl(dm.qtunidadmedidabasepicking,0)+tarea.qtunidadmedidabasepicking unidad,
                     nvl(dm.qtpiezaspicking,0)+tarea.qtpiezaspicking pieza
                from tblslvconsolidadomdet dm
               where dm.idconsolidadom = tarea.idconsolidadom
                 and dm.cdarticulo = tarea.cdarticulo)
        where dm.idconsolidadom = tarea.idconsolidadom
          and dm.cdarticulo = tarea.cdarticulo;  
                    
        if SQL%ROWCOUNT = 0  then 
          n_pkg_vitalpos_log_general.write(2,
                  'Modulo: ' || v_modulo ||
                  ' imposible actualizar ConsolidadoM: '||tarea.idconsolidadom);
          return 0; -- devuelve 0 si no actualiza
       end if;   
      end if;  
     --actualiza la cantidad picking en consolidadocomi y FaltanteConsolidadocomi
     if tarea.cdtipo in(5,6) and tarea.idconsolidadocomi is not null then
      
      update tblslvconsolidadocomidet dc
          set (qtunidadmedidabasepicking,
              qtpiezaspicking) =
              (select nvl(dc.qtunidadmedidabasepicking,0)+tarea.qtunidadmedidabasepicking unidad,
                     nvl(dc.qtpiezaspicking,0)+tarea.qtpiezaspicking pieza
                from tblslvconsolidadocomidet dc
               where dc.idconsolidadocomi = tarea.idconsolidadocomi
                 and dc.cdarticulo = tarea.cdarticulo)
        where dc.idconsolidadocomi = tarea.idconsolidadocomi
          and dc.cdarticulo = tarea.cdarticulo;  
                    
        if SQL%ROWCOUNT = 0  then 
          n_pkg_vitalpos_log_general.write(2,
                  'Modulo: ' || v_modulo ||
                  ' imposible actualizar Consolidadocomi: '||tarea.idconsolidadocomi);
          return 0; -- devuelve 0 si no actualiza
       end if;   
      end if;  
       --actualiza la cantidad picking en consolidado pedido
     if tarea.cdtipo = 3 and tarea.idconsolidadopedido is not null then    
      update tblslvconsolidadopedidodet dp
          set (qtunidadmedidabasepicking,
              qtpiezaspicking) =
              (select nvl(dp.qtunidadmedidabasepicking,0)+tarea.qtunidadmedidabasepicking unidad,
                     nvl(dp.qtpiezaspicking,0)+tarea.qtpiezaspicking pieza
                from tblslvconsolidadopedidodet dp
               where dp.idconsolidadopedido = tarea.idconsolidadopedido
                 and dp.cdarticulo = tarea.cdarticulo)
        where dp.idconsolidadopedido = tarea.idconsolidadopedido
          and dp.cdarticulo = tarea.cdarticulo;  
                    
        if SQL%ROWCOUNT = 0  then 
          n_pkg_vitalpos_log_general.write(2,
                  'Modulo: ' || v_modulo ||
                  ' imposible actualizar Consolidado pedido: '||tarea.idconsolidadopedido);
          return 0; -- devuelve 0 si no actualiza
       end if;   
      end if;                 
  end loop;   
  
  -- pone la tarea Finalizada. 0 en el parametro
  if SetEstadoTarea(p_IdTarea,0)<>1 then
     return 0; -- devuelve 0 si no actualiza
  end if; 
  --Finaliza el consolidado de la tarea si no quedan cantidades por piking
  if  SetFinalizarConsolidados(p_IdTarea) <>1 then
     return 0; -- devuelve 0 si no actualiza
  end if;  
  return 1; 
  EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       ' Error: ' || SQLERRM);
      return 0;     
     
  END SetFinalizarTarea;

 /****************************************************************************************************
  * %v 19/02/2020 - ChM  Versi�n inicial SetRegistrarPicking
  * %v 19/02/2020 - ChM  para un armador, registra el picking del articulo en tarea detalle
  *****************************************************************************************************/
  
  PROCEDURE SetRegistrarPicking(p_IdPersona      IN   personas.idpersona%type,
                                p_idRemito       IN   tblslvremito.idremito%type,               
                                p_NroCarreta     IN   tblslvremito.nrocarreta%type,                  
                                p_cdBarras       IN   barras.cdeancode%type,
                                p_cantidad       IN   tblslvtareadet.qtunidadmedidabase%type,
                                p_cdarticulo     IN   tblslvtareadet.cdarticulo%type,
                                p_IdTarea        IN   tblslvtarea.idtarea%type,            
                                p_Ok             OUT  number,
                                p_error          OUT  varchar2) IS
                              
    v_modulo                 varchar2(100) := 'PKG_SLV_TAREAS.SetRegistrarPicking';  
    v_idremito               tblslvremito.idremito%type;
    v_NroCarreta             tblslvremito.nrocarreta%type;
    v_icgeneraremito         tblslvtipotarea.icgeneraremito%type:=0;
    v_cdunidad               barras.cdunidad%type;
    v_res                    integer;
   BEGIN
     --verifica si cantidad es negativa
     if p_cantidad < 0 then
       p_Ok:=0;
       p_error:='Imposible Registrar Cantidad Negativa!';
       rollback;
       return;
     end if;
    
     -- valida si la tarea pertenece al armador y esta asignada o en curso
      if VerificaPersonaTarea(p_IdPersona,p_IdTarea) = 0 then  
          p_Ok:=0;
          p_error:='Tarea no Asignada o Finalizada!';
          rollback;
          return;
      end if;   
       
     -- validar si la tarea genera remito 
     select tp.icgeneraremito
       into v_icgeneraremito
       from tblslvtarea ta,
            tblslvtipotarea tp
      where ta.cdtipo = tp.cdtipo
        and ta.idtarea = p_IdTarea
        and ta.idpersonaarmador = p_IdPersona
        and rownum = 1; 
        
     --asigna el remito IN a la variable del procedimiento   
     v_idremito:=p_idRemito;
        
     if v_icgeneraremito = 1 then --if genera remito   
      -- si p_idremito = 0 and p_NroCarreta <> 0  se desea crear una nueva carreta    
     if p_idremito = 0 and p_NroCarreta <> 0 and upper(trim(p_cdBarras)) <> 'F' then
        v_idremito:=0;
        GetCarreta(p_IdPersona,p_IdTarea,v_idRemito,v_NroCarreta);
        if v_idremito <> 0 then
           p_Ok:=0;
           p_error:='Tiene Asignaciones Pendientes no Finalizadas!';
           rollback;
           return;
        else
         --verifica si aun quedan detalle de tareas por piking
         if VerificaTareaPicking(p_IdPersona,p_IdTarea) = 1 then
          --crear remito
           v_idremito:=SetInsertarRemito(p_IdTarea,p_NroCarreta);
           if v_idremito = 0 then
              p_Ok:=0;
              p_error:='No es posible Crear el Remito. Comuniquese con Sistemas!';
              rollback;
              return;
           end if;
         end if;  
        end if;
     end if;
     
        --valida si la carreta y remito esta en cero 
        if p_idremito = 0 and p_NroCarreta = 0 then
           p_Ok:=0;
           p_error:='Remito y Carreta en Cero 0!';
           rollback;
           return;
        end if;
        
     --valida si codigo de barra en f y existe remito lo finaliza
     if upper(trim(p_cdBarras)) ='F' and p_idremito <> 0 then
         if SetFinalizarRemito(p_idremito)=0 then
           p_Ok:=0;
           p_error:='No es posible Actualizar Remito: '||p_idremito||'Comuniquese con Sistemas!';
           rollback;
           return;
         else -- se finaliza remito y termina el procedimiento
           p_Ok:=1;     
           commit; 
           return;  
         end if;
      else
          if p_idremito = 0 then
           p_Ok:=0;
           p_error:='No es posible Finalizar Remito en 0 Comuniquese con Sistemas!';
           rollback;
           return;
          end if; 
      end if;  
     end if; --if genera remito
     
    if v_icgeneraremito = 0 then --if NO genera remito
      --verifica codigo de barras en f para pedidos sin remito
       if upper(trim(p_cdBarras)) ='F' then 
           p_Ok:=0;
           p_error:='No Aplica Remito y Carreta para este pedido!'; 
           rollback;
           return; 
       end if;
    end if;
        
   if length (p_cdarticulo)>1 and p_cantidad >= 0  then
      --verifica si cantidad es mayor a cero para verificar codigo de barras
      if p_cantidad > 0 then
         --devuelve la unidad de medida del articulo segun codigo de barra
         v_cdunidad:=pkg_slvarticulos.GetValidaArticuloBarras(p_cdArticulo,p_cdBarras);
        else
         -- si es cero por defecto UN y no verifica el codigo de barras
         v_cdunidad:='UN';
      end if;    
     if v_cdunidad = '-' then
          p_Ok:=0;
          p_error:='El Codigo de Barra no corresponde al Articulo!';
          rollback;
          return;
      else
        -- actualiza la cantidad picking
          v_res:=SetDetalleTarea(p_IdTarea,p_cdArticulo,p_cantidad,v_cdunidad,v_icgeneraremito,v_idremito); 
          --La Cantidad picking Supera la Cantidad Base
          if v_res = -2 then
             p_Ok:=0;
             p_error:='La Cantidad picking Supera la Cantidad Base!';
             rollback;
             return;
          end if; 
          --error no aplico update al detalle tarea
           if v_res = -1 then
             p_Ok:=0;
             p_error:='Falla Actualizar Piking. Comuniquese con sistemas!';
             rollback;
             return;         
          end if;    
      end if; --if v_cdunidad 
    end if; -- if p_cdarticulo>1  
    
    
     --verifica si se desea cerrar el proceso de picking del articulo de la tarea 
     if p_cantidad = 0 then
        --valida si el codigo de articulo y el id de la tarea poseen valores
        if p_cdArticulo is null or p_IdTarea is null then
            p_Ok:=0;
            p_error:='No es Posible Finalizar Linea.Articulo o ID Tarea NULO!';
            rollback;
            return;
        end if;
         --finaliza la linea del detalle tarea  
         if SetFindetalleTarea(p_IdTarea,p_cdArticulo)<> 1 then
            p_Ok:=0;
            p_error:='No es Posible Finalizar Linea.Comuniquese con Sistemas!';
            rollback;
            return;
         end if;      
      end if;
    
   
      --verifica si debe finalizar linea por cantidades alcanzadas
     if VerificaDetalleTarea(p_IdTarea,p_cdArticulo) = 1 then
         if SetFindetalleTarea(p_IdTarea,p_cdArticulo)<> 1 then
            p_Ok:=0;
            p_error:='No es Posible Finalizar Linea2.Comuniquese con Sistemas!';
            rollback;
            return;
         end if; 
     end if;  
     
     --verifica si NO existe lineas pendientes por picking. Finaliza piking de la tarea
         if VerificaTareaPicking(p_IdPersona,p_IdTarea) = 0 then
            if v_icgeneraremito = 1 then --if SI genera remito
                if SetFinalizarRemito(p_idremito)=0 then
                    p_Ok:=0;
                    p_error:='No es posible Actualizar Remito: '||p_idremito||'Comuniquese con Sistemas!';
                    rollback;
                   return;
                end if;
              end if;
              --finaliza Tarea        
            if SetFinalizarTarea(p_IdPersona,p_IdTarea) <> 1 then
                p_Ok:=0;
                p_error:='Falla Finalizar Tarea.Comuniquese con Sistemas!';
                rollback;
                return;
            end if;         
         end if; 
     p_Ok:=1;     
    commit;   
    EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       ' Error: ' || SQLERRM);
      rollback;                                 
      p_Ok    := 0;
      p_error:='Error en Piking. Comuniquese con sistemas!';        
  
   END SetRegistrarPicking;       
  /****************************************************************************************************
  * %v 04/03/2020 - ChM  Versi�n inicial listar Prioridades Tareas por Armador
  *****************************************************************************************************/
 PROCEDURE GetPrioridadTarea(p_IdArmador       IN   personas.idpersona%type,
                             p_Cursor          OUT  CURSOR_TYPE) IS 
                                                    
   v_modulo              varchar2(100) := 'PKG_SLV_TAREAS.GetPrioridadTarea';                             
   
 BEGIN   
  OPEN p_Cursor FOR 
       select ta.idtarea,
              ta.prioridad,
              tip.dstarea||': '||
              ta.idpedfaltante||
              ta.idconsolidadom||
              ta.idconsolidadopedido
              ||ta.idconsolidadocomi||'  Creado: '||ta.dtinsert descripcion 
         from tblslvtarea ta,
              tblslvtipotarea tip         
        where ta.cdtipo = tip.cdtipo
          and ta.idpersonaarmador = p_IdArmador
           -- tareas disponibles Asignado y en curso segun tblslvtipotarea  OOOJOOO tarea de faltantes
          and ta.cdestado in (4,5, 15,16, 22,23,30,31,33,34)
     order by ta.prioridad;

  EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       ' Error: ' || SQLERRM);    
 END GetPrioridadTarea;

  /****************************************************************************************************
  * %v 04/03/2020 - ChM  Versi�n inicial Cambiar Prioridades Tareas
  *****************************************************************************************************/
 FUNCTION SetPrioridadTarea(p_IdTarea            tblslvtarea.idtarea%type,
                            p_Prioridad          tblslvtarea.prioridad%type) 
                                RETURN INTEGER IS   
                                
   v_modulo              varchar2(100) := 'PKG_SLV_TAREAS.SetPrioridadTarea';                             
   
 BEGIN   
   update tblslvtarea ta
     set ta.prioridad = p_Prioridad
   where ta.idtarea = p_IdTarea;
   if SQL%ROWCOUNT = 0  then 
      rollback;
      return 0; -- devuelve 0 si no actualiza
   end if;  
  commit;
  return 1; 
  EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       ' Error: ' || SQLERRM);
      return 0;     
 END SetPrioridadTarea;
 /****************************************************************************************************
  * %v 28/02/2020 - ChM  Versi�n inicial borrar tareas por prueba
  * %v 28/02/2020 - ChM  Borrado y limpieza de tarea y consolidado
  *****************************************************************************************************/
 FUNCTION limpiar_tarea(p_IdTarea            tblslvtarea.idtarea%type) 
                                RETURN INTEGER IS   
   v_modulo              varchar2(100) := 'PKG_SLV_TAREAS.limpiar_tarea';                             
 BEGIN
for tarea in
 (select ta.idpedfaltante,
         ta.idconsolidadom,
         ta.idconsolidadopedido,
         ta.idconsolidadocomi,
         ta.cdtipo,
         ta.idpersona,
         dta.qtunidadmedidabasepicking,
         dta.qtpiezaspicking,
         dta.cdarticulo
    from tblslvtarea ta,
         tblslvtareadet dta
   where ta.idtarea = dta.idtarea
     and ta.idtarea = p_IdTarea 
     --  verifica que el detalle esta finalizado
     and dta.icfinalizado = 1)
  loop
     --actualiza la cantidad picking en consolidadoM y FaltantesconsolidadoM
     if tarea.cdtipo in(1,2) and tarea.idconsolidadom is not null then    
      update tblslvconsolidadomdet dm
          set qtunidadmedidabasepicking=NULL,
              qtpiezaspicking =NULL
        where dm.idconsolidadom = tarea.idconsolidadom
          and dm.cdarticulo = tarea.cdarticulo;  
                    
        if SQL%ROWCOUNT = 0  then 
          rollback;
          return 0; -- devuelve 0 si no actualiza
       end if;   
      end if;  
     --actualiza la cantidad picking en consolidadocomi y FaltanteConsolidadocomi
     if tarea.cdtipo in(5,6) and tarea.idconsolidadocomi is not null then
      
      update tblslvconsolidadocomidet dc
          set qtunidadmedidabasepicking=NULL,
              qtpiezaspicking =NULL
        where dc.idconsolidadocomi = tarea.idconsolidadocomi
          and dc.cdarticulo = tarea.cdarticulo;  
                    
        if SQL%ROWCOUNT = 0  then 
          rollback;
          return 0; -- devuelve 0 si no actualiza
       end if;   
      end if;  
       --actualiza la cantidad picking en consolidado pedido
     if tarea.cdtipo = 3 and tarea.idconsolidadopedido is not null then    
      update tblslvconsolidadopedidodet dp
          set dp.qtunidadmedidabasepicking=NULL,
              dp.qtpiezaspicking =NULL
        where dp.idconsolidadopedido = tarea.idconsolidadopedido
          and dp.cdarticulo = tarea.cdarticulo;  
                    
        if SQL%ROWCOUNT = 0  then 
          rollback;
          return 0; -- devuelve 0 si no actualiza
       end if;   
      end if;                 
  end loop;   
  --limpia la tarea
  update tblslvtarea ta
     set (ta.dtinicio,
         ta.dtfin,
         ta.cdestado) =
         (select null,null,ta.cdestado-1 cdestado
            from tblslvtarea ta
           where ta.idtarea=p_IdTarea  
           )
     where ta.idtarea=p_IdTarea;
     if SQL%ROWCOUNT = 0  then 
          rollback;
          return 0; -- devuelve 0 si no actualiza
       end if;  
  --limpia la detalle tarea
  
  update tblslvtareadet det
     set det.qtunidadmedidabasepicking=null,
         det.qtpiezaspicking=null,
         det.icfinalizado=0
   where det.idtarea=p_IdTarea;
    if SQL%ROWCOUNT = 0  then 
          rollback;
          return 0; -- devuelve 0 si no actualiza
       end if;  
  commit;
  return 1; 
  EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       ' Error: ' || SQLERRM);
      return 0;     
   END limpiar_tarea;
  
    
end PKG_SLV_TAREAS;
/
