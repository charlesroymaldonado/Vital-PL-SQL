create or replace package PKG_SLV_TAREAS is
  /**********************************************************************************************************
  * Author  : CMALDONADO_C
  * Created : 13/02/2020 01:45:03 P.m.
  * %v Paquete para gestión y asignación de tareas SLV
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

  PROCEDURE GetIngresoArmador(p_login     IN cuentasusuarios.dsloginname%type,
                              p_password  IN cuentasusuarios.vlpassword%type,
                              p_idpersona OUT personas.idpersona%type,
                              p_Ok        OUT number,
                              p_error     OUT varchar2);

  PROCEDURE GetlistadoPicking(p_IdPersona      IN personas.idpersona%type,
                              p_idRemito       OUT tblslvremito.idremito%type,
                              p_NroCarreta     OUT tblslvremito.nrocarreta%type,
                              p_icGeneraRemito OUT tblslvtipotarea.icgeneraremito%type,
                              p_IdTarea        OUT tblslvtarea.idtarea%type,
                              p_Ok             OUT number,
                              p_error          OUT varchar2,
                              p_Cursor         OUT CURSOR_TYPE);
  PROCEDURE SetRegistrarPicking(p_IdPersona  IN personas.idpersona%type,
                                p_idRemito   IN tblslvremito.idremito%type,
                                p_NroCarreta IN tblslvremito.nrocarreta%type,
                                p_cdBarras   IN barras.cdtipocodigobarra%type,
                                p_cantidad   IN tblslvtareadet.qtunidadmedidabase%type,
                                p_cdarticulo IN tblslvtareadet.cdarticulo%type,
                                p_IdTarea    IN tblslvtarea.idtarea%type,
                                p_Ok         OUT number,
                                p_error      OUT varchar2);

end PKG_SLV_TAREAS;
/
create or replace package body PKG_SLV_TAREAS is
/***************************************************************************************************
*  %v 13/02/2020  ChM - Parametros globales del PKG
****************************************************************************************************/
--c_qtDecimales                                  CONSTANT number := 2; -- cantidad de decimales para redondeo
 g_cdSucursal      sucursales.cdsucursal%type := trim(getvlparametro('CDSucursal',
                                                                      'General'));
 /****************************************************************************************************
  * %v 13/02/2020 - ChM  Versión inicial GetListaConsolidadoM
  * %v 13/02/2020 - ChM  lista los consolidados Multicanal distintos de estado 3 (finalizado)
  *****************************************************************************************************/
  PROCEDURE GetListaConsolidadoM(p_Cursor     OUT CURSOR_TYPE) IS
   
   v_modulo varchar2(100) := 'PKG_SLV_TAREAS.GetListaConsolidadoM';
  
    BEGIN             
      OPEN p_Cursor FOR 
             select m.idconsolidadom,
                    to_char(m.dtinsert,'dd/mm/yyyy')||' - '||m.idconsolidadom NroConsolidado                               
               from tblslvconsolidadom m
              where m.cdestado <> 3;
    EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       '  Error: ' || SQLERRM);                           
    END GetListaConsolidadoM;
    
 /****************************************************************************************************
  * %v 13/02/2020 - ChM  Versión inicial GetListaArmadores
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
                and upper(p.nmgrupotarea)='EXPEDICION' ;

    EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       '  Error: ' || SQLERRM);                           
  END GetListaArmadores;    
    
 /****************************************************************************************************
  * %v 13/02/2020 - ChM  Versión inicial GetArticulosConsolidadoM
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
                    PKG_SLV_Articulos.SetFormatoArticulos(art.cdarticulo,det.qtunidadmedidabase) Cantidad
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
                                             and ta.cdtipo=1); --tblslvtipotarea  1 ConsolidadoM
    EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       '  Error: ' || SQLERRM);                           
  END GetArticulosConsolidadoM;   
       
 /****************************************************************************************************
  * %v 14/02/2020 - ChM  Versión inicial GetArticulosConsolidadoComi
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
                    PKG_SLV_Articulos.SetFormatoArticulos(art.cdarticulo,cdet.qtunidadmedidabase) Cantidad
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
                                             and ta.cdtipo=5); --tblslvtipotarea  5 ConsolidadoComi
    EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       '  Error: ' || SQLERRM);                           
  END GetArticulosConsolidadoComi;  
  
  /****************************************************************************************************
  * %v 14/02/2020 - ChM  Versión inicial SetAsignaArtConsolidadoM
  * %v 14/02/2020 - ChM  crea las tareas de picking por armador solo para tblslvconsolidadoM
  *****************************************************************************************************/
  PROCEDURE SetAsignaArtConsolidadoM (p_cdArticulos    IN  arr_cdarticulo,
                                      p_idConsolidado  IN  integer,
                                      p_IdPersona      IN  personas.idpersona%type,
                                      p_IdArmador      IN  personas.idpersona%type,
                                      p_Ok             OUT number) IS
                                      
    v_modulo  varchar2(100) := 'PKG_SLV_TAREAS.SetAsignaArtConsolidadoM';
    v_error   varchar2(200);
    v_prioridad integer;
    
  BEGIN
      begin
       select max(ta.prioridad)+1
         into v_prioridad
         from tblslvtarea ta 
        where ta.idpersona = p_IdPersona
          and ta.idpersonaarmador = p_IdArmador
          and ta.idconsolidadom = p_idConsolidado
          and ta.dtinsert = trunc(sysdate);
      exception
      when no_data_found then
          v_prioridad:=1;
      end;
  
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
                       null,   --idremito
                       det.cdarticulo,
                       det.qtunidadmedidabase,
                       null,   --qtunidadmedidabasepicking
                       null,   --qtpiezas
                       null,   --qtpiezaspicking
                       sysdate,--dtinsert
                       null,    --dtupdate
                       null    --icfinalizado
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
     p_Ok:=1;
     COMMIT;
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
  * %v 14/02/2020 - ChM  Versión inicial SetAsignaArtConsolidadoComi
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
      begin
       select max(ta.prioridad)+1
         into v_prioridad
         from tblslvtarea ta 
        where ta.idpersona = p_IdPersona
          and ta.idpersonaarmador = p_IdArmador
          and ta.idconsolidadocomi = p_idConsolidado
          and ta.dtinsert = trunc(sysdate);
      exception
      when no_data_found then
          v_prioridad:=1;
      end;
      
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
                       null,   --idremito
                       det.cdarticulo,
                       det.qtunidadmedidabase,
                       null,   --qtunidadmedidabasepicking
                       null,   --qtpiezas
                       null,   --qtpiezaspicking
                       sysdate,--dtinsert
                       null,    --dtupdate
                       null     --icfinalizado
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
     p_Ok:=1;
     COMMIT;
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
  * %v 14/02/2020 - ChM  Versión inicial SetAsignaArticulosArmador
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
        RETURN;
       end if;
     end if;   
    --TipoTarea 5 ConsolidadoComi
    if p_TipoTarea = 5 then
      SetAsignaArtConsolidadoComi(p_cdArticulos,p_idConsolidado,p_IdPersona,p_IdArmador,p_Ok);
      if p_Ok <> 1 then
        p_Ok    := 0;
        p_error := 'Error Asignando Armadores. Comuniquese con Sistemas!';
        RETURN;
       end if;          
    end if;   
 
  END SetAsignaArticulosArmador;    
    
  /****************************************************************************************************
  * %v 17/02/2020 - ChM  Versión inicial GetIngresoArmador
  * %v 17/02/2020 - ChM  valida que el armador este autorizado para ingresar al sistema
  *****************************************************************************************************/
  PROCEDURE GetIngresoArmador(p_login      IN  cuentasusuarios.dsloginname%type,
                              p_password   IN  cuentasusuarios.vlpassword%type,
                              p_idpersona  OUT personas.idpersona%type,
                              p_esarmador  OUT tblslvtipotarea.icgeneraremito%type,    
                              p_Ok         OUT number,
                              p_error      OUT varchar2) IS
                              
    v_modulo      varchar2(100) := 'PKG_SLV_TAREAS.GetIngresoArmador';  
    v_idpersona   personas.idpersona%type;
    
  BEGIN
      p_idpersona:= '{FD95DC1D-F3CD-4216-B87D-6BEBEE72D4E5}  ' ; --borrar 
      p_ok := 1;
      p_esarmador:=1;
      return; --borrar
    p_ok:=PosApp.PosLogin.DoLogin(p_login, p_password, p_idpersona, p_error); 
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
  END GetIngresoArmador;      
 
 /****************************************************************************************************
  * %v 17/02/2020 - ChM  Versión inicial GetCarreta
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
         and ta.idtarea = p_IdTarea --id de la tarea
         and (ta.idconsolidadocomi is null or re.idconsolidadocomi = ta.idconsolidadocomi)   
         and (ta.idconsolidadopedido is null or re.idconsolidadopedido = ta.idconsolidadopedido)
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
  * %v 17/02/2020 - ChM  Versión inicial GetlistadoPicking
  * %v 17/02/2020 - ChM  para un armador, lista los articulos pendientes para picking en tarea
  *****************************************************************************************************/
  
  PROCEDURE GetlistadoPicking(p_IdPersona      IN   personas.idpersona%type,
                              p_idRemito       OUT  tblslvremito.idremito%type,               
                              p_NroCarreta     OUT  tblslvremito.nrocarreta%type,                  
                              p_icGeneraRemito OUT  tblslvtipotarea.icgeneraremito%type,  
                              p_IdTarea        OUT  tblslvtarea.idtarea%type,       
                              p_Ok             OUT  number,
                              p_error          OUT  varchar2,
                              p_Cursor         OUT  CURSOR_TYPE) IS
                              
    v_modulo      varchar2(100) := 'PKG_SLV_TAREAS.GetlistadoPicking';  
    
  BEGIN
     p_idRemito:=0;               
     p_NroCarreta:=0;                  
     p_icGeneraRemito:=0;
     p_IdTarea:=0;
    for tarea in 
      (select ta.idtarea,
              tip.icgeneraremito
         from tblslvtarea ta,
              tblslvtipotarea tip         
        where ta.cdtipo = tip.cdtipo
          and ta.idpersonaarmador = p_IdPersona --id del Armador 
          and ta.cdestado in (4,5, 15,16, 22,23, 33,34) --tareas disponibles segun tblslvtipotarea  
     order by ta.prioridad) 
    loop
     begin
       
       p_IdTarea := tarea.idtarea;
       p_icGeneraRemito := tarea.icgeneraremito;
       
       if tarea.icgeneraremito = 1 then --verifica si genera remito
          getcarreta(p_IdPersona,tarea.idtarea,p_idRemito,p_NroCarreta); 
       end if;  
        
     open p_cursor for 
           select dta.cdarticulo Cdarticulo,
                  dta.cdarticulo||' - '||des.vldescripcion Articulo, 
                  PKG_SLV_Articulos.GetCodigoDeBarra(dta.cdarticulo,'BTO') Barras,
                  PKG_SLV_Articulos.SetFormatoArticulos(dta.cdarticulo,dta.qtunidadmedidabase) Cantidad,
                  PKG_SLV_Articulos.GetUbicacionArticulos(dta.cdarticulo) Ubicacion,
                  PKG_SLV_Articulos.CalcularPesoUnidadBase(dta.cdarticulo,dta.qtunidadmedidabase) Peso 
             from tblslvtarea ta,
                  tblslvtareadet dta,
                  descripcionesarticulos des,
                  tblslvtipotarea tip  
            where ta.idtarea = dta.idtarea
              and ta.idtarea = tarea.idtarea --id de la tarea de mayor prioridad
              and ta.cdtipo = tip.cdtipo
              and dta.cdarticulo = des.cdarticulo    
              and dta.qtunidadmedidabasepicking is null
              and dta.qtpiezaspicking is null
         order by 4 ASC,
                  5 DESC;
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
  * %v 19/02/2020 - ChM  Versión inicial VerificaTareaPicking
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
            --indica que aun quedan articulos por picking en la tarea
            and dta.qtunidadmedidabasepicking is null; 
   if v_estado <> 0 then
     return 1; -- devuelve 1 si aun se deben pickear articulos
   else
     return 0; -- devuelve 0 si no hay articulos para pickear
   end if;
  EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       ' Error: ' || SQLERRM);
      return 0;                                           
  END VerificaTareaPicking;
 /****************************************************************************************************
  * %v 19/02/2020 - ChM  Versión inicial SetRegistrarPicking
  * %v 19/02/2020 - ChM  para un armador, registra el picking del articulo en tarea detalle
  *****************************************************************************************************/
  
  PROCEDURE SetRegistrarPicking(p_IdPersona      IN   personas.idpersona%type,
                                p_idRemito       IN   tblslvremito.idremito%type,               
                                p_NroCarreta     IN   tblslvremito.nrocarreta%type,                  
                                p_cdBarras       IN   barras.cdtipocodigobarra%type,
                                p_cantidad       IN   tblslvtareadet.qtunidadmedidabase%type,
                                p_cdarticulo     IN   tblslvtareadet.cdarticulo%type,
                                p_IdTarea        IN   tblslvtarea.idtarea%type,            
                                p_Ok             OUT  number,
                                p_error          OUT  varchar2) IS
                              
    v_modulo                 varchar2(100) := 'PKG_SLV_TAREAS.SetRegistrarPicking';  
    v_idremito               tblslvremito.idremito%type;
    v_NroCarreta             tblslvremito.nrocarreta%type;
    v_icgeneraremito         tblslvtipotarea.icgeneraremito%type:=0;
    v_idconsolidadopedido    tblslvtarea.idconsolidadopedido%type;
    v_idconsolidadocomi      tblslvtarea.idconsolidadocomi%type;
    v_idpedfaltante          tblslvtarea.idpedfaltante%type; --revisar faltantes
    
   BEGIN
       
     -- validar si la tarea genera remito 
     select tp.icgeneraremito,
            ta.idconsolidadopedido,
            ta.idconsolidadocomi,
            ta.idpedfaltante
       into v_icgeneraremito,
            v_idconsolidadopedido,
            v_idconsolidadocomi,     
            v_idpedfaltante    
       from tblslvtarea ta,
            tblslvtipotarea tp
      where ta.cdtipo = tp.cdtipo
        and ta.idtarea = p_IdTarea
        and ta.idpersonaarmador = p_IdPersona
        and rownum = 1;
     --si genera remito   
     if v_icgeneraremito = 1 then
      -- si p_idremito = 0 and p_NroCarreta <> 0  se desea crear una nueva carreta    
     if p_idremito = 0 and p_NroCarreta <> 0 then
        v_idremito:=0;
        GetCarreta(p_IdPersona,p_IdTarea,v_idRemito,v_NroCarreta);
        if v_idremito <> 0 then
           p_Ok:=0;
           p_error:='Tiene Asignaciones Pendientes no Finalizadas!';
           return;
        else
         if VerificaTareaPicking(p_IdPersona,p_IdTarea) = 1 then
          --crear remito si aun quedan detalle de tareas por piking
            insert into tblslvremito 
                 values(seq_remito.nextval,    --idremito
                        v_idconsolidadocomi,   --idconsolidadocomi 
                        v_idconsolidadopedido, --idconsolidadopedido
                        null,                  --idpedfaltanterel REVISAR
                        p_NroCarreta,          --NroCarreta
                        36,                    --Cdestado 36 remito en curso
                        sysdate,               --dtremito
                        sysdate,               --dtinsert
                        null);                 --dtupdate                                    
          else
             p_Ok:=0;
             p_error:='No Existen Articulos por Picking Para esta Tarea!';
           return;  
         end if;  
        end if;
     end if;
     end if; --genera remito
   
    
    EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       ' Error: ' || SQLERRM);
      p_Ok    := 0;
      p_error:='Error en Piking. Comuniquese con sistemas!';        
  
   END SetRegistrarPicking;       
    
end PKG_SLV_TAREAS;
/
