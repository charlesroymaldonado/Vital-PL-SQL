CREATE OR REPLACE PACKAGE PKG_SLV_TAREAS is
  /**********************************************************************************************************
  * Author  : CMALDONADO_C
  * Created : 13/02/2020 01:45:03 P.m.
  * %v Paquete para gestión y asignación de tareas SLV
  **********************************************************************************************************/
  -- Tipos de datos

  TYPE CURSOR_TYPE IS REF CURSOR;

  TYPE arr_cdarticulo IS TABLE OF CHAR(8) INDEX BY PLS_INTEGER;




  --Procedimientos y Funciones
  PROCEDURE GetListaConsolidados(p_TipoTarea      IN  tblslvtipotarea.cdtipo%type,
                                 p_Cursor         OUT CURSOR_TYPE );

  PROCEDURE GetListaArmadores(p_Cursor OUT CURSOR_TYPE);

  PROCEDURE GetAsignaArticulosArmador(p_idConsolidado  IN  integer,
                                      p_TipoTarea      IN  tblslvtipotarea.cdtipo%type,
                                      p_Cursor         OUT CURSOR_TYPE );

  PROCEDURE SetAsignaArticulosArmador(p_cdArticulos   IN arr_cdarticulo,
                                      p_idConsolidado IN integer,
                                      p_TipoTarea     IN tblslvtipotarea.cdtipo%type,
                                      p_IdPersona     IN personas.idpersona%type,
                                      p_IdArmador     IN personas.idpersona%type,
                                      p_cdModoIngreso IN tblslvtarea.cdmodoingreso%type,
                                      p_Ok            OUT number,
                                      p_error         OUT varchar2);

  PROCEDURE GetTareaAsigConsolidado(p_idConsolidado   IN  Integer,
                                    p_TipoTarea       IN  Tblslvtipotarea.cdtipo%type,
                                    p_Cursor          OUT CURSOR_TYPE);
                                    
  PROCEDURE GetArticulosbarrasXTarea(p_IdTarea       IN  tblslvtarea.idtarea%type,                         
                                     p_Cursor        OUT CURSOR_TYPE);                                    

  PROCEDURE GetIngreso(p_login     IN cuentasusuarios.dsloginname%type,
                       p_password  IN cuentasusuarios.vlpassword%type,
                       p_idpersona OUT personas.idpersona%type,
                       p_esarmador  OUT tblslvtipotarea.icgeneraremito%type,
                       p_Ok        OUT number,
                       p_error     OUT varchar2);

  PROCEDURE GetlistadoPicking(p_IdPersona         IN   personas.idpersona%type  default null,
                              p_IdtareaManual     IN   tblslvtarea.idtarea%type default null,
                              P_tipoTareaManual   IN   tblslvtarea.cdtipo%type  default null,
                              p_idRemito          OUT  tblslvremito.idremito%type,
                              p_NroCarreta        OUT  tblslvremito.nrocarreta%type,
                              p_icGeneraRemito    OUT  tblslvtipotarea.icgeneraremito%type,
                              p_IdTarea           OUT  tblslvtarea.idtarea%type,
                              p_Tarea             OUT  varchar2,
                              P_DsArmador         OUT  personas.dsnombre%type,
                              p_Ok                OUT  number,
                              p_error             OUT  varchar2,
                              p_Cursor            OUT  CURSOR_TYPE);                                                   

  PROCEDURE SetRegistrarPickingM(p_idRemito         IN   tblslvremito.idremito%type default null,
                                p_NroCarreta       IN   tblslvremito.nrocarreta%type,
                                p_cdBarras         IN   barras.cdeancode%type,
                                p_cantidad         IN   tblslvtareadet.qtunidadmedidabase%type,
                                p_IdTarea          IN   tblslvtarea.idtarea%type,                        
                                p_IdPersonaManual  IN   personas.idpersona%type default null,
                                p_cdmodoingreso    IN   tblslvtarea.cdmodoingreso%type default 0,
                                p_FinTarea         OUT  number,
                                p_Ok               OUT  number,
                                p_error            OUT  varchar2);
                                
  PROCEDURE SetRegistrarPicking(p_IdPersona        IN   personas.idpersona%type,
                                p_idRemito         IN   tblslvremito.idremito%type default null,
                                p_NroCarreta       IN   tblslvremito.nrocarreta%type,
                                p_cdBarras         IN   barras.cdeancode%type,
                                p_cantidad         IN   tblslvtareadet.qtunidadmedidabase%type,
                                p_cdarticulo       IN   tblslvtareadet.cdarticulo%type,
                                p_IdTarea          IN   tblslvtarea.idtarea%type, 
                                p_FinTarea         OUT  number,                               
                                p_Ok               OUT  number,
                                p_error            OUT  varchar2);                                 

  PROCEDURE GetPrioridadTarea(p_IdArmador       IN   personas.idpersona%type,
                              p_Cursor          OUT  CURSOR_TYPE);

  FUNCTION SetPrioridadTarea(p_IdTarea            tblslvtarea.idtarea%type,
                             p_Prioridad          tblslvtarea.prioridad%type)
                                RETURN INTEGER;
                                                                  
  PROCEDURE GetArticulosXTarea(p_IdTarea      IN  tblslvtarea.idtarea%type,
                               p_DsSucursal   OUT sucursales.dssucursal%type,                   
                               p_CursorCAB    OUT CURSOR_TYPE,                                       
                               p_Cursor       OUT CURSOR_TYPE);

  PROCEDURE SetPausaTarea(p_IdPersona   IN   personas.idpersona%type,
                          p_IdArmador   IN   personas.idpersona%type,
                          p_Ok          OUT  number,
                          p_error       OUT  varchar2);

  PROCEDURE SetFinalizaPausaTarea(p_IdArmador   IN   personas.idpersona%type,
                                  p_Ok          OUT  number,
                                  p_error       OUT  varchar2);

  PROCEDURE SetLiberarArmador(p_IdArmador   IN   personas.idpersona%type,
                              p_Ok          OUT  number,
                              p_error       OUT  varchar2);

end PKG_SLV_TAREAS;
/
CREATE OR REPLACE PACKAGE BODY PKG_SLV_TAREAS is
/***************************************************************************************************
*  %v 13/02/2020  ChM - Parametros globales del PKG
****************************************************************************************************/
--c_qtDecimales                                  CONSTANT number := 2; -- cantidad de decimales para redondeo
 g_cdSucursal      sucursales.cdsucursal%type := trim(getvlparametro('CDSucursal',
                                                                      'General'));

  c_TareaHandHeld                    CONSTANT tblslvtarea.cdmodoingreso%type := 0;

  c_TareaConsolidadoMulti            CONSTANT tblslvtipotarea.cdtipo%type := 10;
  c_TareaConsolidaMultiFaltante      CONSTANT tblslvtipotarea.cdtipo%type := 20;
  c_TareaConsolidadoPedido           CONSTANT tblslvtipotarea.cdtipo%type := 25;
  c_TareaConsolidaPedidoFaltante     CONSTANT tblslvtipotarea.cdtipo%type := 40;
  c_TareaConsolidadoComi             CONSTANT tblslvtipotarea.cdtipo%type := 50;
  c_TareaConsolidadoComiFaltante     CONSTANT tblslvtipotarea.cdtipo%type := 60;
  c_TareaPausa                       CONSTANT tblslvtipotarea.cdtipo%type := 70;
   --costante de tblslvestado
C_CreadoConsolidadoM                               CONSTANT tblslvestado.cdestado%type := 1;
C_EnCursoConsolidadoM                              CONSTANT tblslvestado.cdestado%type := 2;
C_FinalizadoConsolidadoM                           CONSTANT tblslvestado.cdestado%type := 3;
C_AsignadoTareaConsolidadoM                        CONSTANT tblslvestado.cdestado%type := 4;
C_EnCursoTareaConsolidadoM                         CONSTANT tblslvestado.cdestado%type := 5;
C_FinalizadoTareaConsolidadoM                      CONSTANT tblslvestado.cdestado%type := 6;
C_AsignadoTareaFaltaConsolidaM                     CONSTANT tblslvestado.cdestado%type := 7;
C_EnCursoTareaFaltaConsolidaM                      CONSTANT tblslvestado.cdestado%type := 8;
C_FinalizaTareaFaltaConsolidaM                     CONSTANT tblslvestado.cdestado%type := 9;
C_CreadoConsolidadoPedido                          CONSTANT tblslvestado.cdestado%type := 10;
C_EnCursoConsolidadoPedido                         CONSTANT tblslvestado.cdestado%type := 11;
C_CerradoConsolidadoPedido                         CONSTANT tblslvestado.cdestado%type := 12;
C_AFacturarConsolidadoPedido                       CONSTANT tblslvestado.cdestado%type := 13;
C_FacturadoConsolidadoPedido                       CONSTANT tblslvestado.cdestado%type := 14;
C_AsignadoTareaConsolidaPedido                     CONSTANT tblslvestado.cdestado%type := 15;
C_EnCursoTareaConsolidaPedido                      CONSTANT tblslvestado.cdestado%type := 16;
C_FinalizaTareaConsolidaPedido                     CONSTANT tblslvestado.cdestado%type := 17;
C_CreadoFaltanConsolidaPedido                      CONSTANT tblslvestado.cdestado%type := 18;
C_EnCursoFaltanConsolidaPedido                     CONSTANT tblslvestado.cdestado%type := 19;
C_FinalizaFaltaConsolidaPedido                     CONSTANT tblslvestado.cdestado%type := 20;
C_DistribFaltaConsolidaPedido                      CONSTANT tblslvestado.cdestado%type := 21;
C_AsignadoTareaFaltaConsoliPed                     CONSTANT tblslvestado.cdestado%type := 22;
C_EnCursoTareaFaltaConsoliPed                      CONSTANT tblslvestado.cdestado%type := 23;
C_FinalizaTareaFaltaConsoliPed                     CONSTANT tblslvestado.cdestado%type := 24;
C_CreadoConsolidadoComi                            CONSTANT tblslvestado.cdestado%type := 25;
C_EnCursoConsolidadoComi                           CONSTANT tblslvestado.cdestado%type := 26;
C_FinalizadoConsolidadoComi                        CONSTANT tblslvestado.cdestado%type := 27;
C_DistribuidoConsolidadoComi                       CONSTANT tblslvestado.cdestado%type := 28;
C_FacturadoConsolidadoComi                         CONSTANT tblslvestado.cdestado%type := 29;
C_AsignadoTareaFaltaConsoComi                      CONSTANT tblslvestado.cdestado%type := 30;
C_EnCursoTareaFaltaConsoComi                       CONSTANT tblslvestado.cdestado%type := 31;
C_FinalizaTareaFaltaConsolComi                     CONSTANT tblslvestado.cdestado%type := 32;
C_AsignadoTareaConsolidadoComi                     CONSTANT tblslvestado.cdestado%type := 33;
C_EnCursoTareaConsolidadoComi                      CONSTANT tblslvestado.cdestado%type := 34;
C_FinalizaTareaConsolidaComi                       CONSTANT tblslvestado.cdestado%type := 35;
C_EnCursoRemito                                    CONSTANT tblslvestado.cdestado%type := 36;
C_FinalizadoRemito                                 CONSTANT tblslvestado.cdestado%type := 37;
C_AsignadoTareaPausa                               CONSTANT tblslvestado.cdestado%type := 38;
C_FinalizadoTareaPausa                             CONSTANT tblslvestado.cdestado%type := 39;
 /****************************************************************************************************
  * %v 13/02/2020 - ChM  Versión inicial GetListaConsolidadoM
  * %v 13/02/2020 - ChM  lista los consolidados Multicanal
  *****************************************************************************************************/
  PROCEDURE GetListaConsolidadoM(p_TipoTarea  IN  tblslvtipotarea.cdtipo%type,
                                 p_Cursor     OUT CURSOR_TYPE) IS

   v_modulo varchar2(100) := 'PKG_SLV_TAREAS.GetListaConsolidadoM';

    BEGIN
      OPEN p_Cursor FOR
             Select 
           distinct m.idconsolidadom idconsolidadom,
                    'Consolidado M: '||m.idconsolidadom||
                    ' Creado: '||to_char(m.dtinsert,'dd/mm/yyyy') NroConsolidado
               from tblslvconsolidadom m,
                    tblslvconsolidadomdet det
              where m.idconsolidadom = det.idconsolidadom
                and m.cdestado in (C_CreadoConsolidadoM,C_EnCursoConsolidadoM) --estado consolidado multicanal no finalizado
                --valida si es tarea faltante que el articulo se pikeo en tarea anterior
                and decode(p_TipoTarea,c_TareaConsolidaMultiFaltante,det.qtunidadmedidabasepicking,1) is not null
                --valida si es tarea faltante listar solo los que tienen diferencia
                and decode(p_TipoTarea,c_TareaConsolidaMultiFaltante,(det.qtunidadmedidabase-det.qtunidadmedidabasepicking),1)<>0
                --valida no listar consolidadoM ya asignados totalmente al armador
                and det.cdarticulo not in(select td.cdarticulo
                                            from tblslvtarea ta,
                                                 tblslvtareadet td
                                           where ta.idtarea=td.idtarea
                                             and ta.idconsolidadom=m.idconsolidadom
                                             and ta.idpersona= m.idpersona
                                             and ta.cdtipo= p_TipoTarea);
    EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       '  Error: ' || SQLERRM);
    END GetListaConsolidadoM;

  /****************************************************************************************************
  * %v 13/03/2020 - ChM  Versión inicial GetlistadoConsolidadoPedido
  * %v 13/03/2020 - ChM  lista los consolidados Pedido
  *****************************************************************************************************/
  PROCEDURE GetlistaConsolidadoPedido(p_TipoTarea  IN  tblslvtipotarea.cdtipo%type,
                                      p_Cursor     OUT CURSOR_TYPE) IS

   v_modulo varchar2(100) := 'PKG_SLV_TAREAS.GetlistadoConsolidadoPedido';

    BEGIN
      OPEN p_Cursor FOR
             Select 
           distinct p.idconsolidadopedido idconsolidadom,
                    'Consolidado Pedido: '||p.idconsolidadopedido||
                    ' Creado: '||to_char(p.dtinsert,'dd/mm/yyyy') NroConsolidado
               from tblslvconsolidadopedido p,
                    tblslvconsolidadopedidodet det
              where p.idconsolidadopedido= det.idconsolidadopedido
                --estado consolidado pedidos no finalizado
                and p.cdestado in (C_CreadoConsolidadoPedido,C_EnCursoConsolidadoPedido) 
                --valida que no sean pedidos de comisionistas
                and p.idconsolidadocomi is null
                --valida no listar consolidado pedido ya asignados totalmente al armador
                and det.cdarticulo not in(select td.cdarticulo
                                            from tblslvtarea ta,
                                                 tblslvtareadet td
                                           where ta.idtarea=td.idtarea
                                             and ta.idconsolidadopedido=p.idconsolidadopedido
                                             and ta.idpersona= p.idpersona
                                             and ta.cdtipo= p_TipoTarea);
    EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       '  Error: ' || SQLERRM);
    END GetListaConsolidadoPedido;

  /****************************************************************************************************
  * %v 13/03/2020 - ChM  Versión inicial GetlistaConsolidadoComi
  * %v 13/03/2020 - ChM  lista los consolidados comisionistas
  *****************************************************************************************************/
  PROCEDURE GetlistaConsolidadoComi(p_TipoTarea  IN  tblslvtipotarea.cdtipo%type,
                                    p_Cursor     OUT CURSOR_TYPE) IS

   v_modulo varchar2(100) := 'PKG_SLV_TAREAS.GetlistaConsolidadoComi';

    BEGIN
      OPEN p_Cursor FOR
             Select 
           distinct c.idconsolidadocomi idconsolidadom,
                    'Consolidado Comi: '||c.idconsolidadocomi||
                    ' Creado: '||to_char(c.dtinsert,'dd/mm/yyyy') NroConsolidado
               from tblslvconsolidadocomi c,
                    tblslvconsolidadocomidet cdet
              where c.idconsolidadocomi = cdet.idconsolidadocomi
                --estado consolidado comisionistas no finalizado
                and c.cdestado in (C_CreadoConsolidadoComi,C_EnCursoConsolidadoComi)
                --valida si es tarea faltante que el articulo se pikeo en tarea anterior
                and decode(p_TipoTarea,c_TareaConsolidadoComiFaltante,cdet.qtunidadmedidabasepicking,1) is not null
                --valida si es tarea faltante listar solo los que tienen diferencia
                and decode(p_TipoTarea,c_TareaConsolidadoComiFaltante,(cdet.qtunidadmedidabase-cdet.qtunidadmedidabasepicking),1)<>0
                --valida no listar consolidado comisionistas ya asignados totalmente al armador
                and cdet.cdarticulo not in(select td.cdarticulo
                                            from tblslvtarea ta,
                                                 tblslvtareadet td
                                           where ta.idtarea=td.idtarea
                                             and ta.idconsolidadocomi = c.idconsolidadocomi
                                             and ta.idpersona = c.idpersona
                                             and ta.cdtipo= p_TipoTarea);
    EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       '  Error: ' || SQLERRM);
    END GetlistaConsolidadoComi;

    /****************************************************************************************************
  * %v 13/03/2020 - ChM  Versión inicial GetlistadoFaltantePedido
  * %v 13/03/2020 - ChM  lista los faltantes de Pedido
  *****************************************************************************************************/
  PROCEDURE GetlistadoFaltantePedido(p_TipoTarea  IN  tblslvtipotarea.cdtipo%type,
                                        p_Cursor     OUT CURSOR_TYPE) IS

   v_modulo varchar2(100) := 'PKG_SLV_TAREAS.GetlistadoFaltantePedido';

    BEGIN
      OPEN p_Cursor FOR
             Select 
           distinct pf.idpedfaltante idconsolidadom,
                    'Faltante Pedido: '||pf.idpedfaltante||
                    ' Creado: '||to_char(pf.dtinsert,'dd/mm/yyyy') NroConsolidado
               from tblslvpedfaltante pf,
                    tblslvpedfaltantedet det
              where pf.idpedfaltante = det.idpedfaltante
                --estado faltante de pedidos no finalizado
                and pf.cdestado in (C_CreadoFaltanConsolidaPedido,C_EnCursoFaltanConsolidaPedido) 
                --valida no listar faltante de pedido ya asignados totalmente al armador
                and det.cdarticulo not in(select td.cdarticulo
                                            from tblslvtarea ta,
                                                 tblslvtareadet td
                                           where ta.idtarea = td.idtarea
                                             and ta.idpedfaltante = pf.idpedfaltante
                                             and ta.idpersona = pf.idpersona
                                             and ta.cdtipo = p_TipoTarea);
    EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       '  Error: ' || SQLERRM);
    END GetlistadoFaltantePedido;

 /****************************************************************************************************
  * %v 13/03/2020 - ChM  Versión inicial GetListaConsolidados
  * %v 13/03/2020 - ChM  Lista los consolidados según tipo de tarea
  *****************************************************************************************************/
  PROCEDURE GetListaConsolidados(p_TipoTarea      IN  tblslvtipotarea.cdtipo%type,
                                 p_Cursor         OUT CURSOR_TYPE ) IS

  BEGIN

     --TipoTarea 1,2 ConsolidadoM y ConsolidadoMFaltante
     if p_TipoTarea in (c_TareaConsolidadoMulti,c_TareaConsolidaMultiFaltante) then
      GetListaConsolidadoM(p_TipoTarea,p_Cursor);
     end if;
     --TipoTarea 3 Consolidado pedido
     if p_TipoTarea = c_TareaConsolidadoPedido then
      GetlistaConsolidadoPedido(p_TipoTarea,p_Cursor);
     end if;
     --TipoTarea 4 Faltantes Consolidado pedido
     if p_TipoTarea = c_TareaConsolidaPedidoFaltante then
      GetlistadoFaltantePedido(p_TipoTarea,p_Cursor);
     end if;
     --TipoTarea 5,6 ConsolidadoComi y ConsolidadoComiFaltante
     if p_TipoTarea in (c_TareaConsolidadoComi,c_TareaConsolidadoComiFaltante) then
      GetlistaConsolidadoComi(p_TipoTarea,p_Cursor);
     end if;

  END GetListaConsolidados;

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
                and upper(p.nmgrupotarea)='EXPEDICION'
           order by Armador;

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
                                     p_TipoTarea       IN  tblslvtipotarea.cdtipo%type,
                                     p_Cursor          OUT CURSOR_TYPE) IS

   v_modulo varchar2(100) := 'PKG_SLV_TAREAS.GetArticulosConsolidadoM';

    BEGIN
      OPEN p_Cursor FOR
             Select m.idconsolidadom idconsolidado,
                    gs.cdgrupo||' - ' ||gs.dsgruposector||' ('||sec.dssector || ')' Sector,
                    det.cdarticulo cdArticulo,
                    art.cdarticulo || '- ' || des.vldescripcion Articulo,
                    PKG_SLVArticulos.SetFormatoArticuloscod(art.cdarticulo,det.qtunidadmedidabase) Cantidad
               from tblslvconsolidadom m,
                    tblslvconsolidadomdet det,
                    tblslv_grupo_sector gs,
                    sectores sec,
                    descripcionesarticulos des,
                    articulos art
              where m.idconsolidadom = det.idconsolidadom
                and det.cdarticulo = art.cdarticulo
                and det.idgrupo_sector = gs.idgrupo_sector
                --estado consolidado multicanal diferende de finalizado
                and m.cdestado <> C_FinalizadoConsolidadoM
                and sec.cdsector = gs.cdsector
                and art.cdarticulo = des.cdarticulo
                and gs.cdsucursal =  g_cdSucursal
                and m.idconsolidadom = p_idConsolidadoM
                --valida si es tarea faltante que el articulo se pikeo en tarea anterior
                and decode(p_TipoTarea,c_TareaConsolidaMultiFaltante,det.qtunidadmedidabasepicking,1) is not null
                --valida si es tarea faltante listar solo los que tienen diferencia
                and decode(p_TipoTarea,c_TareaConsolidaMultiFaltante,(det.qtunidadmedidabase-det.qtunidadmedidabasepicking),1)<>0
                --valida no listar articulos ya asignados al armador
                and det.cdarticulo not in(select td.cdarticulo
                                            from tblslvtarea ta,
                                                 tblslvtareadet td
                                           where ta.idtarea=td.idtarea
                                             and ta.idconsolidadom=m.idconsolidadom
                                             and ta.idpersona= m.idpersona
                                             and ta.cdtipo= p_TipoTarea);
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
  PROCEDURE GetArticulosConsolidadoComi(p_IdconsolidadoComi IN  Tblslvconsolidadocomi.Idconsolidadocomi%type,
                                        p_TipoTarea         IN  tblslvtipotarea.cdtipo%type,
                                        p_Cursor            OUT CURSOR_TYPE) IS

   v_modulo varchar2(100) := 'PKG_SLV_TAREAS.GetArticulosConsolidadoComi';

    BEGIN
      OPEN p_Cursor FOR
             Select cm.idconsolidadocomi idconsolidado,
                    gs.cdgrupo||' - ' ||gs.dsgruposector||' ('||sec.dssector || ')' Sector,
                    cdet.cdarticulo cdArticulo,
                    art.cdarticulo || '- ' || des.vldescripcion Articulo,
                    PKG_SLVArticulos.SetFormatoArticuloscod(art.cdarticulo,cdet.qtunidadmedidabase) Cantidad
               from tblslvconsolidadocomi cm,
                    tblslvconsolidadocomidet cdet,
                    tblslv_grupo_sector gs,
                    sectores sec,
                    descripcionesarticulos des,
                    articulos art
              where cm.idconsolidadocomi = cdet.idconsolidadocomi
                and cdet.cdarticulo = art.cdarticulo
                and cdet.idgrupo_sector = gs.idgrupo_sector
                --estado de consolidado comisionista distinto a finalizado, facturado y distribuido
                and cm.cdestado not in (C_FinalizadoConsolidadoComi,C_FacturadoConsolidadoComi,C_DistribuidoConsolidadoComi)
                and sec.cdsector = gs.cdsector
                and art.cdarticulo = des.cdarticulo
                and gs.cdsucursal =  g_cdSucursal
                and cm.idconsolidadocomi = p_IdconsolidadoComi
                --valida si es tarea faltante que el articulo se pikeo en tarea anterior
                and decode(p_TipoTarea,c_TareaConsolidadoComiFaltante,cdet.qtunidadmedidabasepicking,1) is not null
                --valida si es tarea faltante listar solo los que tienen diferencia
                and decode(p_TipoTarea,c_TareaConsolidadoComiFaltante,(cdet.qtunidadmedidabase-cdet.qtunidadmedidabasepicking),1)<>0
                --valida no listar articulos ya asignados al armador
                and cdet.cdarticulo not in(select td.cdarticulo
                                            from tblslvtarea ta,
                                                 tblslvtareadet td
                                           where ta.idtarea=td.idtarea
                                             and ta.idconsolidadocomi=cm.idconsolidadocomi
                                             and ta.idpersona= cm.idpersona
                                             and ta.cdtipo= p_TipoTarea);
    EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       '  Error: ' || SQLERRM);
  END GetArticulosConsolidadoComi;

  /****************************************************************************************************
  * %v 12/03/2020 - ChM  Versión inicial GetArticulosConsolidadoPedido
  * %v 12/03/2020 - ChM  lista los articulos que conforman un IdConsolidadoPedido
  *****************************************************************************************************/
  PROCEDURE GetArticulosConsolidadoPedido(p_Idconsolidadopedido IN  Tblslvconsolidadopedido.Idconsolidadopedido %type,
                                          p_TipoTarea           IN  tblslvtipotarea.cdtipo%type,
                                          p_Cursor              OUT CURSOR_TYPE) IS

   v_modulo varchar2(100) := 'PKG_SLV_TAREAS.GetArticulosConsolidadoPedido';

    BEGIN
      OPEN p_Cursor FOR
             Select cp.idconsolidadopedido idconsolidado,
                    gs.cdgrupo||' - ' ||gs.dsgruposector||' ('||sec.dssector || ')' Sector,
                    cdet.cdarticulo cdArticulo,
                    art.cdarticulo || '- ' || des.vldescripcion Articulo,
                    PKG_SLVArticulos.SetFormatoArticuloscod(art.cdarticulo,cdet.qtunidadesmedidabase) Cantidad
               from tblslvconsolidadopedido cp,
                    tblslvconsolidadopedidodet cdet,
                    tblslv_grupo_sector gs,
                    sectores sec,
                    descripcionesarticulos des,
                    articulos art
              where cp.idconsolidadopedido = cdet.idconsolidadopedido
                and cdet.cdarticulo = art.cdarticulo
                and cdet.idgrupo_sector = gs.idgrupo_sector
                --estado de consolidadopedido distinto a cerrado, A facturar y facturado
                and cp.cdestado not in (C_CerradoConsolidadoPedido,C_AFacturarConsolidadoPedido,C_FacturadoConsolidadoPedido)
                and sec.cdsector = gs.cdsector
                and art.cdarticulo = des.cdarticulo
                and gs.cdsucursal =  g_cdSucursal
                and cp.idconsolidadopedido = p_Idconsolidadopedido
                --valida no listar articulos ya asignados al armador
                and cdet.cdarticulo not in(select td.cdarticulo
                                            from tblslvtarea ta,
                                                 tblslvtareadet td
                                           where ta.idtarea=td.idtarea
                                             and ta.idconsolidadopedido=cp.idconsolidadopedido
                                             and ta.idpersona= cp.idpersona
                                             and ta.cdtipo= p_TipoTarea);
    EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       '  Error: ' || SQLERRM);
  END GetArticulosConsolidadoPedido;

   /****************************************************************************************************
  * %v 12/03/2020 - ChM  Versión inicial GetArticuloPedidoFaltantes
  * %v 12/03/2020 - ChM  lista los articulos que conforman un pedidoFaltante
  *****************************************************************************************************/
  PROCEDURE GetArticuloPedidoFaltantes(p_idpedidoFaltante  IN  Tblslvpedfaltante.Idpedfaltante%type,
                                       p_TipoTarea         IN  tblslvtipotarea.cdtipo%type,
                                       p_Cursor            OUT CURSOR_TYPE) IS

   v_modulo varchar2(100) := 'PKG_SLV_TAREAS.GetArticuloPedidoFaltantes';

    BEGIN
      OPEN p_Cursor FOR
             Select f.idpedfaltante idconsolidado,
                    gs.cdgrupo||' - ' ||gs.dsgruposector||' ('||sec.dssector || ')' Sector,
                    detf.cdarticulo cdArticulo,
                    art.cdarticulo || '- ' || des.vldescripcion Articulo,
                    PKG_SLVArticulos.SetFormatoArticuloscod(art.cdarticulo,detf.qtunidadmedidabase) Cantidad
               from tblslvpedfaltante f,
                    tblslvpedfaltantedet detf,
                    tblslv_grupo_sector gs,
                    sectores sec,
                    descripcionesarticulos des,
                    articulos art
              where f.idpedfaltante = detf.idpedfaltante
                and detf.cdarticulo = art.cdarticulo
                and detf.idgrupo_sector = gs.idgrupo_sector
                 --estado faltante pedido no finalizado, no distribuido
                and f.cdestado not in (C_FinalizaFaltaConsolidaPedido,C_DistribFaltaConsolidaPedido)
                and sec.cdsector = gs.cdsector
                and art.cdarticulo = des.cdarticulo
                and gs.cdsucursal =  g_cdSucursal
                and f.idpedfaltante = p_idPedidoFaltante
                --valida no listar articulos ya asignados al armador
                and detf.cdarticulo not in(select td.cdarticulo
                                            from tblslvtarea ta,
                                                 tblslvtareadet td
                                           where ta.idtarea=td.idtarea
                                             and ta.idpedfaltante=f.idpedfaltante
                                             and ta.idpersona= f.idpersona
                                             and ta.cdtipo= p_TipoTarea);
    EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       '  Error: ' || SQLERRM);
  END GetArticuloPedidoFaltantes;

  /****************************************************************************************************
  * %v 12/03/2020 - ChM  Versión inicial GetAsignaArticulosArmador
  * %v 12/03/2020 - ChM  lista de articulos disponibles según tipo de tarea para asignar a los armadores
  *****************************************************************************************************/
  PROCEDURE GetAsignaArticulosArmador(p_idConsolidado  IN  integer,
                                      p_TipoTarea      IN  tblslvtipotarea.cdtipo%type,
                                      p_Cursor         OUT CURSOR_TYPE ) IS

  BEGIN

     --TipoTarea 1,2 ConsolidadoM y ConsolidadoMFaltante
     if p_TipoTarea in (c_TareaConsolidadoMulti,c_TareaConsolidaMultiFaltante) then
      GetArticulosConsolidadoM(p_idConsolidado,p_TipoTarea,p_Cursor);
     end if;
     --TipoTarea 3 Consolidado pedido
     if p_TipoTarea = c_TareaConsolidadoPedido then
      GetArticulosConsolidadoPedido(p_idConsolidado,p_TipoTarea,p_Cursor);
     end if;
     --TipoTarea 4 Faltantes Consolidado pedido
     if p_TipoTarea = c_TareaConsolidaPedidoFaltante then
      GetArticuloPedidoFaltantes(p_idConsolidado,p_TipoTarea,p_Cursor);
     end if;
    --TipoTarea 5,6 ConsolidadoComi y ConsolidadoComiFaltante
    if p_TipoTarea in (c_TareaConsolidadoComi,c_TareaConsolidadoComiFaltante) then
      GetArticulosConsolidadoComi(p_idConsolidado,p_TipoTarea,p_Cursor);
    end if;

  END GetAsignaArticulosArmador;

  /****************************************************************************************************
  * %v 14/02/2020 - ChM  Versión inicial SetAsignaArtConsolidadoM
  * %v 14/02/2020 - ChM  crea las tareas de picking por armador solo para tblslvconsolidadoM
  * %v 13/04/2020 - ChM  valido si es tarea faltante insertar la diferencia en la tarea sino inserta qtunidadmedidabase
  *****************************************************************************************************/
  PROCEDURE SetAsignaArtConsolidadoM (p_cdArticulos    IN  arr_cdarticulo,
                                      p_idConsolidado  IN  integer,
                                      p_TipoTarea      IN  tblslvtipotarea.cdtipo%type,
                                      p_IdPersona      IN  personas.idpersona%type,
                                      p_IdArmador      IN  personas.idpersona%type,
                                      p_cdModoIngreso  IN  tblslvtarea.cdmodoingreso%type,
                                      p_Ok             OUT number) IS

    v_modulo    varchar2(100) := 'PKG_SLV_TAREAS.SetAsignaArtConsolidadoM';
    v_error     varchar2(200);
    v_prioridad integer;
    v_cdestado  tblslvtarea.cdestado%type;

  BEGIN

      if p_TipoTarea = c_TareaConsolidadoMulti then
        v_cdestado:= C_AsignadoTareaConsolidadoM; --Asignado TareaConsolidadoM en tblslvestado
      end if;
      if p_TipoTarea = c_TareaConsolidaMultiFaltante then
        v_cdestado:= C_AsignadoTareaFaltaConsolidaM; --Asignado TareaFaltanteConsolidadoM  en tblslvestado
      end if;

       select nvl(max(ta.prioridad),0)+1
         into v_prioridad
         from tblslvtarea ta
        where ta.idpersonaarmador = p_IdArmador
          --diferente de finalizada la tarea
          and ta.cdestado not in (6,9,17,24,32,35)
          -- verifica la prioridad del actual dia
          and to_char(ta.dtinsert,'dd/mm/yyyy') = to_char(sysdate,'dd/mm/yyyy');

      --inserta la cabezera de la tarea
        insert into tblslvtarea
                    (idtarea,
                    idpedfaltante,
                    idconsolidadom,
                    idconsolidadopedido,
                    idconsolidadocomi,
                    cdtipo,
                    idpersona,
                    idpersonaarmador,
                    dtinicio,
                    dtfin,
                    prioridad,
                    cdestado,
                    dtinsert,
                    dtupdate,
                    cdmodoingreso)
             values (seq_tarea.nextval,
                     null, --idfaltante
                     p_idConsolidado, --idconsolidadoM
                     null, --idconsolidadopedido
                     null, --idconsolidadocomi
                     p_TipoTarea,    --TipoTarea
                     p_IdPersona,
                     p_IdArmador,
                     null,  --dtinicio
                     null,  --dtfin
                     v_prioridad,  --prioridad
                     v_cdestado,
                     sysdate, --dtinsert
                     null,   --dtupdate
                     p_cdModoIngreso);
    --itera cada articulo del arreglo
    FOR i IN 1 .. p_cdArticulos.count LOOP
         --inserta el detalle de la tarea asignada por Armador por articulo
         v_error := 'Falla INSERT tblslvtareadet IdPersona: ' ||
                 p_IdPersona||' Armador: '||p_IdArmador||
                 ' Articulo: ' ||p_cdArticulos(i);
           insert into tblslvtareadet
                       (idtareadet,
                       idtarea,
                       cdarticulo,
                       qtunidadmedidabase,
                       qtunidadmedidabasepicking,
                       qtpiezas,
                       qtpiezaspicking,
                       dtinsert,
                       dtupdate,
                       icfinalizado,
                       idgrupo_sector)
                select seq_tareadet.nextval,
                       seq_tarea.currval,
                       det.cdarticulo,
                       --valida si es tarea faltante insertar la diferencia en la tarea sino inserta qtunidadmedidabase
                       decode(p_TipoTarea,c_TareaConsolidaMultiFaltante,
                             (det.qtunidadmedidabase-nvl(det.qtunidadmedidabasepicking,0)),
                              det.qtunidadmedidabase) qtunidadmedidabase,
                       null,   --qtunidadmedidabasepicking
                       null,   --qtpiezas
                       null,   --qtpiezaspicking
                       sysdate,--dtinsert
                       null,    --dtupdate
                       0,        --icfinalizado
                       det.idgrupo_sector
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
       SET m.cdestado = C_EnCursoConsolidadoM --en curso
     WHERE m.idconsolidadom = p_idConsolidado
       AND m.idpersona = p_IdPersona;
       IF SQL%ROWCOUNT = 0  THEN      --valida update de la tabla tblslvconsolidadom
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
  * %v 14/02/2020 - ChM  Versión inicial SetAsignaArtConsolidadoComi
  * %v 14/02/2020 - ChM  crea las tareas de picking por armador solo para tblslvconsolidadoComi
  * %v 13/04/2020 - ChM  valido si es tarea faltante insertar la diferencia en la tarea sino inserta qtunidadmedidabase
  *****************************************************************************************************/
  PROCEDURE SetAsignaArtConsolidadoComi (p_cdArticulos    IN  arr_cdarticulo,
                                         p_idConsolidado  IN  integer,
                                         p_TipoTarea      IN  tblslvtipotarea.cdtipo%type,
                                         p_IdPersona      IN  personas.idpersona%type,
                                         p_IdArmador      IN  personas.idpersona%type,
                                         p_cdModoIngreso  IN  tblslvtarea.cdmodoingreso%type,
                                         p_Ok             OUT number) IS

    v_modulo    varchar2(100) := 'PKG_SLV_TAREAS.SetAsignaArtConsolidadoComi';
    v_error     varchar2(200);
    v_prioridad integer;
    v_cdestado  tblslvtarea.cdestado%type;
  BEGIN

      if p_TipoTarea = c_TareaConsolidadoComi then
        v_cdestado:= C_AsignadoTareaConsolidadoComi; --Asignado TareaConsolidadoComi en tblslvestado
      end if;
      if p_TipoTarea = c_TareaConsolidadoComiFaltante then
        v_cdestado:= C_AsignadoTareaFaltaConsoComi; --Asignado TareaFaltanteConsolidadoComi  en tblslvestado
      end if;

       select nvl(max(ta.prioridad),0)+1
         into v_prioridad
         from tblslvtarea ta
        where ta.idpersonaarmador = p_IdArmador
          --diferente de finalizada la tarea
          and ta.cdestado not in (6,9,17,24,32,35)
          -- verifica la prioridad del actual dia
          and to_char(ta.dtinsert,'dd/mm/yyyy') = to_char(sysdate,'dd/mm/yyyy');

      --inserta la cabezera de la tarea
        insert into tblslvtarea
                    (idtarea,
                    idpedfaltante,
                    idconsolidadom,
                    idconsolidadopedido,
                    idconsolidadocomi,
                    cdtipo,
                    idpersona,
                    idpersonaarmador,
                    dtinicio,
                    dtfin,
                    prioridad,
                    cdestado,
                    dtinsert,
                    dtupdate,
                    cdmodoingreso)
             values (seq_tarea.nextval,
                     null, --idfaltante
                     null, --idconsolidadoM
                     null, --idconsolidadopedido
                     p_idConsolidado, --idconsolidadocomi
                     p_TipoTarea,
                     p_IdPersona,
                     p_IdArmador,
                     null,  --dtinicio
                     null,  --dtfin
                     v_prioridad,  --prioridad
                     v_cdestado,
                     sysdate, --dtinsert
                     null,   --dtupdate
                     p_cdModoIngreso);
    --itera cada articulo del arreglo
    FOR i IN 1 .. p_cdArticulos.count LOOP
         --inserta el detalle de la tarea asignada por Armador por articulo
         v_error := 'Falla INSERT tblslvtareadet IdPersona: ' ||
                 p_IdPersona||' Armador: '||p_IdArmador||
                 ' Articulo: ' ||p_cdArticulos(i);
           insert into tblslvtareadet
                       (idtareadet,
                       idtarea,
                       cdarticulo,
                       qtunidadmedidabase,
                       qtunidadmedidabasepicking,
                       qtpiezas,
                       qtpiezaspicking,
                       dtinsert,
                       dtupdate,
                       icfinalizado,
                       idgrupo_sector)
                select seq_tareadet.nextval,
                       seq_tarea.currval,
                       det.cdarticulo,
                       --valida si es tarea faltante insertar la diferencia en la tarea, sino inserta qtunidadmedidabase
                       decode(p_TipoTarea,c_TareaConsolidadoComiFaltante,
                             (det.qtunidadmedidabase-nvl(det.qtunidadmedidabasepicking,0)),
                              det.qtunidadmedidabase) qtunidadmedidabase,
                       null,   --qtunidadmedidabasepicking
                       null,   --qtpiezas
                       null,   --qtpiezaspicking
                       sysdate,--dtinsert
                       null,    --dtupdate
                       0,       --icfinalizado
                       det.idgrupo_sector
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
       SET com.cdestado = C_EnCursoConsolidadoComi --en curso
     WHERE com.idconsolidadocomi = p_idConsolidado
       AND com.idpersona = p_IdPersona;
     IF SQL%ROWCOUNT = 0  THEN      --valida update de la tabla tblslvconsolidadocomi
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
  * %v 12/03/2020 - ChM  Versión inicial SetAsignaArtConsolidadoPedido
  * %v 12/03/2020 - ChM  crea las tareas de picking por armador solo para tblslvconsolidadoPedido
  *****************************************************************************************************/
  PROCEDURE SetAsignaArtConsolidadoPedido (p_cdArticulos    IN  arr_cdarticulo,
                                           p_idConsolidado  IN  integer,
                                           p_TipoTarea      IN  tblslvtipotarea.cdtipo%type,
                                           p_IdPersona      IN  personas.idpersona%type,
                                           p_IdArmador      IN  personas.idpersona%type,
                                           p_cdModoIngreso  IN  tblslvtarea.cdmodoingreso%type,
                                           p_Ok             OUT number) IS

    v_modulo    varchar2(100) := 'PKG_SLV_TAREAS.SetAsignaArtConsolidadoPedido';
    v_error     varchar2(200);
    v_prioridad integer;
    v_cdestado  tblslvtarea.cdestado%type;

  BEGIN

      if p_TipoTarea = c_TareaConsolidadoPedido then
        v_cdestado:= C_AsignadoTareaConsolidaPedido; --Asignado TareaConsolidadoPedido en tblslvestado
      end if;

       select nvl(max(ta.prioridad),0)+1
         into v_prioridad
         from tblslvtarea ta
        where ta.idpersonaarmador = p_IdArmador
          --diferente de finalizada la tarea
          and ta.cdestado not in (6,9,17,24,32,35)
          -- verifica la prioridad del actual dia
          and to_char(ta.dtinsert,'dd/mm/yyyy') = to_char(sysdate,'dd/mm/yyyy');

      --inserta la cabezera de la tarea
        insert into tblslvtarea
                    (idtarea,
                    idpedfaltante,
                    idconsolidadom,
                    idconsolidadopedido,
                    idconsolidadocomi,
                    cdtipo,
                    idpersona,
                    idpersonaarmador,
                    dtinicio,
                    dtfin,
                    prioridad,
                    cdestado,
                    dtinsert,
                    dtupdate,
                    cdmodoingreso)
             values (seq_tarea.nextval,
                     null, --idfaltante
                     null, --idconsolidadoM
                     p_idConsolidado, --idconsolidadopedido
                     null, --idconsolidadocomi
                     p_TipoTarea,    --TipoTarea
                     p_IdPersona,
                     p_IdArmador,
                     null,  --dtinicio
                     null,  --dtfin
                     v_prioridad,  --prioridad
                     v_cdestado,
                     sysdate, --dtinsert
                     null,   --dtupdate
                     p_cdModoIngreso );
    --itera cada articulo del arreglo
    FOR i IN 1 .. p_cdArticulos.count LOOP
         --inserta el detalle de la tarea asignada por Armador por articulo
         v_error := 'Falla INSERT tblslvtareadet IdPersona: ' ||
                 p_IdPersona||' Armador: '||p_IdArmador||
                 ' Articulo: ' ||p_cdArticulos(i);
           insert into tblslvtareadet
                       (idtareadet,
                       idtarea,
                       cdarticulo,
                       qtunidadmedidabase,
                       qtunidadmedidabasepicking,
                       qtpiezas,
                       qtpiezaspicking,
                       dtinsert,
                       dtupdate,
                       icfinalizado,
                       idgrupo_sector)
                select seq_tareadet.nextval,
                       seq_tarea.currval,
                       det.cdarticulo,
                       det.qtunidadesmedidabase,
                       null,   --qtunidadmedidabasepicking
                       null,   --qtpiezas
                       null,   --qtpiezaspicking
                       sysdate,--dtinsert
                       null,    --dtupdate
                       0,        --icfinalizado
                       det.idgrupo_sector
                  from tblslvconsolidadopedidodet det,
                       tblslvconsolidadopedido p
                 where det.idconsolidadopedido=p.idconsolidadopedido
                   and p.idpersona=p_IdPersona
                   and p.idconsolidadopedido=p_idConsolidado
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
    --actualiza el estado del consolidadopedido a 11 en curso
     v_error := 'Falla UPDATE tblslvconsolidadoPedido IdPersona: ' ||
      p_IdPersona||' Armador: '||p_IdArmador;
    UPDATE tblslvconsolidadopedido p
       SET p.cdestado = C_EnCursoConsolidadoPedido --en curso
     WHERE p.idconsolidadopedido = p_idConsolidado
       AND p.idpersona = p_IdPersona;
       IF SQL%ROWCOUNT = 0  THEN      --valida update de la tabla tblslvconsolidadopedido
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
  END SetAsignaArtConsolidadoPedido;

  /****************************************************************************************************
  * %v 12/03/2020 - ChM  Versión inicial SetAsignaArtPedidoFaltantes
  * %v 12/03/2020 - ChM  crea las tareas de picking por armador solo para tblslvPedFaltante
  *****************************************************************************************************/
  PROCEDURE SetAsignaArtPedidoFaltantes(p_cdArticulos    IN  arr_cdarticulo,
                                        p_idConsolidado  IN  integer,
                                        p_TipoTarea      IN  tblslvtipotarea.cdtipo%type,
                                        p_IdPersona      IN  personas.idpersona%type,
                                        p_IdArmador      IN  personas.idpersona%type,
                                        p_cdModoIngreso  IN  tblslvtarea.cdmodoingreso%type,
                                        p_Ok             OUT number) IS

    v_modulo    varchar2(100) := 'PKG_SLV_TAREAS.SetAsignaArtPedidoFaltantes';
    v_error     varchar2(200);
    v_prioridad integer;
    v_cdestado  tblslvtarea.cdestado%type;

  BEGIN

      if p_TipoTarea = c_TareaConsolidaPedidoFaltante then
        v_cdestado:= C_AsignadoTareaFaltaConsoliPed; --Asignado TareaFaltanteConsolidadoPedido en tblslvestado
      end if;

       select nvl(max(ta.prioridad),0)+1
         into v_prioridad
         from tblslvtarea ta
        where ta.idpersonaarmador = p_IdArmador
          --diferente de finalizada la tarea
          and ta.cdestado not in (6,9,17,24,32,35)
          -- verifica la prioridad del actual dia
          and to_char(ta.dtinsert,'dd/mm/yyyy') = to_char(sysdate,'dd/mm/yyyy');

      --inserta la cabezera de la tarea
        insert into tblslvtarea
                    (idtarea,
                    idpedfaltante,
                    idconsolidadom,
                    idconsolidadopedido,
                    idconsolidadocomi,
                    cdtipo,
                    idpersona,
                    idpersonaarmador,
                    dtinicio,
                    dtfin,
                    prioridad,
                    cdestado,
                    dtinsert,
                    dtupdate,
                    cdmodoingreso)
             values (seq_tarea.nextval,
                     p_idConsolidado, --idfaltante
                     null, --idconsolidadoM
                     null, --idconsolidadopedido
                     null, --idconsolidadocomi
                     p_TipoTarea,
                     p_IdPersona,
                     p_IdArmador,
                     null,  --dtinicio
                     null,  --dtfin
                     v_prioridad,  --prioridad
                     v_cdestado,
                     sysdate, --dtinsert
                     null,   --dtupdate
                     p_cdModoIngreso);
    --itera cada articulo del arreglo
    FOR i IN 1 .. p_cdArticulos.count LOOP
         --inserta el detalle de la tarea asignada por Armador por articulo
         v_error := 'Falla INSERT tblslvtareadet IdPersona: ' ||
                 p_IdPersona||' Armador: '||p_IdArmador||
                 ' Articulo: ' ||p_cdArticulos(i);
           insert into tblslvtareadet
                       (idtareadet,
                       idtarea,
                       cdarticulo,
                       qtunidadmedidabase,
                       qtunidadmedidabasepicking,
                       qtpiezas,
                       qtpiezaspicking,
                       dtinsert,
                       dtupdate,
                       icfinalizado,
                       idgrupo_sector)
                select seq_tareadet.nextval,
                       seq_tarea.currval,
                       det.cdarticulo,
                       det.qtunidadmedidabase,
                       null,   --qtunidadmedidabasepicking
                       null,   --qtpiezas
                       null,   --qtpiezaspicking
                       sysdate,--dtinsert
                       null,    --dtupdate
                       0,        --icfinalizado
                       det.idgrupo_sector
                  from tblslvpedfaltantedet det,
                       tblslvpedfaltante pf
                 where det.idpedfaltante=pf.idpedfaltante
                   and pf.idpersona=p_IdPersona
                   and pf.idpedfaltante=p_idConsolidado
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
    --actualiza el estado del Faltante consolidado pedido a 19 en curso
     v_error := 'Falla UPDATE tblslvpedfaltante IdPersona: ' ||
      p_IdPersona||' Armador: '||p_IdArmador;
    UPDATE tblslvpedfaltante pf
       SET pf.cdestado = C_EnCursoFaltanConsolidaPedido --en curso
     WHERE pf.idpedfaltante = p_idConsolidado
       AND pf.idpersona = p_IdPersona;
       IF SQL%ROWCOUNT = 0  THEN      --valida update de la tabla tblslvpedfaltante
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
  END SetAsignaArtPedidoFaltantes;

  /****************************************************************************************************
  * %v 12/03/2020 - ChM  Versión inicial SetAsignaArticulosArmador
  * %v 12/03/2020 - ChM  crea las tareas de picking por armador con la lista de articulos
  *****************************************************************************************************/
  PROCEDURE SetAsignaArticulosArmador(p_cdArticulos    IN  arr_cdarticulo,
                                      p_idConsolidado  IN  integer,
                                      p_TipoTarea      IN  tblslvtipotarea.cdtipo%type,
                                      p_IdPersona      IN  personas.idpersona%type,
                                      p_IdArmador      IN  personas.idpersona%type,
                                      p_cdModoIngreso  IN  tblslvtarea.cdmodoingreso%type,
                                      p_Ok             OUT number,
                                      p_error          OUT varchar2) IS

  BEGIN

     if p_TipoTarea is null or p_cdArticulos is null or p_idConsolidado is null or p_IdPersona is null or  p_IdArmador is null then
        p_Ok    := 0;
        p_error := 'Error Asignando Armadores. Campos de entrada en NULL. Comuniquese con Sistemas!';
        ROLLBACK;
        RETURN;
     end if;

     --TipoTarea 1,2 ConsolidadoM y ConsolidadoMFaltante
     if p_TipoTarea in (c_TareaConsolidadoMulti,c_TareaConsolidaMultiFaltante) then
      SetAsignaArtConsolidadoM(p_cdArticulos,p_idConsolidado,p_TipoTarea,p_IdPersona,p_IdArmador,p_cdModoIngreso,p_Ok);
      if p_Ok <> 1 then
        p_Ok    := 0;
        p_error := 'Error Asignando Armadores. Comuniquese con Sistemas!';
        ROLLBACK;
        RETURN;
       end if;
     end if;
    --TipoTarea 3 ConsolidadoPedido
    if p_TipoTarea = c_TareaConsolidadoPedido then
      SetAsignaArtConsolidadoPedido(p_cdArticulos,p_idConsolidado,p_TipoTarea,p_IdPersona,p_IdArmador,p_cdModoIngreso,p_Ok);
      if p_Ok <> 1 then
        p_Ok    := 0;
        p_error := 'Error Asignando Armadores. Comuniquese con Sistemas!';
        ROLLBACK;
        RETURN;
       end if;
    end if;
    --TipoTarea 4 Faltante Consolidado Pedido
    if p_TipoTarea = c_TareaConsolidaPedidoFaltante then
      SetAsignaArtPedidoFaltantes(p_cdArticulos,p_idConsolidado,p_TipoTarea,p_IdPersona,p_IdArmador,p_cdModoIngreso,p_Ok);
      if p_Ok <> 1 then
        p_Ok    := 0;
        p_error := 'Error Asignando Armadores. Comuniquese con Sistemas!';
        ROLLBACK;
        RETURN;
       end if;
    end if;
    --TipoTarea 5,6 ConsolidadoComi y ConsolidadoComi faltante
    if p_TipoTarea in (c_TareaConsolidadoComi,c_TareaConsolidadoComiFaltante) then
      SetAsignaArtConsolidadoComi(p_cdArticulos,p_idConsolidado,p_TipoTarea,p_IdPersona,p_IdArmador,p_cdModoIngreso,p_Ok);
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
  * %v 14/05/2020 - ChM  Versión inicial GetTareaAsigConsolidado
  * %v 14/05/2020 - ChM  lista las tareas que conforman un Consolidado
  * %v 15/05/2020 - ChM  Agrego datos del remito y carreta si los genera
  *****************************************************************************************************/
  PROCEDURE GetTareaAsigConsolidado(p_idConsolidado   IN  Integer,
                                    p_TipoTarea       IN  Tblslvtipotarea.cdtipo%type,
                                    p_Cursor          OUT CURSOR_TYPE) IS
  v_modulo varchar2(100) := 'PKG_SLV_TAREAS.GetTareaAsigConsolidado';
    BEGIN
      OPEN p_Cursor FOR
       select COALESCE
              (ta.idpedfaltante,
              ta.idconsolidadom,
              ta.idconsolidadopedido,
              ta.idconsolidadocomi
              )idConsolidado,
              ta.idtarea,
              decode(ta.cdmodoingreso,0,'HandHeld','Manual') modoingreso,
              p.dsnombre||' '||p.dsapellido Armador,
              e.dsestado Estado,
              nvl(re.nrocarreta,0) roll, 
              nvl(re.idremito,0) carreta                                     
         from tblslvtarea ta 
    left join (tblslvremito re)
           on (re.idtarea= ta.idtarea),
              personas p,
              tblslvestado e
        where ta.idpersonaarmador = p.idpersona
          and ta.cdestado = e.cdestado
          and case when p_tipoTarea = c_TareaConsolidadoMulti        
                    and ta.idconsolidadom = p_idConsolidado then 1
                   when p_tipoTarea = c_TareaConsolidaMultiFaltante  
                    and ta.idconsolidadom = p_idConsolidado then 1
                   when p_tipoTarea = c_TareaConsolidadoPedido       
                    and ta.idconsolidadopedido = p_idConsolidado then 1 
                   when p_tipoTarea = c_TareaConsolidaPedidoFaltante 
                    and ta.idpedfaltante = p_idConsolidado then 1
                   when p_tipoTarea = c_TareaConsolidadoComi         
                    and ta.idconsolidadocomi = p_idConsolidado then 1
                   when p_tipoTarea = c_TareaConsolidadoComiFaltante 
                    and ta.idconsolidadocomi = p_idConsolidado then 1       
              end = 1    
          and ta.cdtipo = p_tipoTarea
     order by ta.prioridad;
 
   EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       '  Error: ' || SQLERRM);
  END GetTareaAsigConsolidado;

  /****************************************************************************************************
  * %v 17/02/2020 - ChM  Versión inicial GetIngreso
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
       p_error:='Usuario autentificado no Armador!. acceso negado!!!';
     end if;
   else
      p_Ok:= 0;
      p_error:='No autorizado para ingresar al Sistema!';
   end if;
  EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       ' Error: ' || SQLERRM);
      p_Ok    := 0;
      p_error:='Error al ingresar. Comuniquese con Sistemas!';
  END GetIngreso;

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
       where re.cdestado = C_EnCursoRemito --remito en curso
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
  * %v 16/05/2020 - ChM  Versión inicial GetArticulosXTarea
  * %v 16/05/2020 - ChM  Listado de detalle de articulos que conforman una tarea
  *****************************************************************************************************/
  PROCEDURE GetArticulosbarrasXTarea(p_IdTarea       IN  tblslvtarea.idtarea%type,                         
                                     p_Cursor        OUT CURSOR_TYPE) IS
    
    v_modulo      varchar2(100) := 'PKG_SLV_TAREAS_DES.GetArticulosbarrasXTarea';
    
  BEGIN
    OPEN p_Cursor FOR
           select tdet.idtarea, 
                  b.cdeancode, 
                  b.cdunidad, 
                  b.cdarticulo
             from Tblslvtareadet tdet, 
                  barras b
            where b.cdarticulo = tdet.cdarticulo
              and tdet.idtarea = p_idTarea 
              -- LETI esto que Significa??
              and b.icprincipal = 1;
  EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       '  Error: ' || SQLERRM);
  END GetArticulosbarrasXTarea;

   /****************************************************************************************************
  * %v 09/05/2020 - ChM  Versión inicial ArtBarraxTarea
  * %v 09/05/2020 - ChM  devuelve el cdarticulo asociado a un codigo de barras y un idTarea
  *****************************************************************************************************/

  PROCEDURE ArtBarraxTarea(p_IdTarea          IN   tblslvtarea.idtarea%type,
                           p_cdBarras         IN   barras.cdeancode%type,
                           p_cdarticulo       OUT  tblslvtareadet.cdarticulo%type,
                           p_Ok               OUT  number,
                           p_error            OUT  varchar2) IS
  BEGIN
      select det.cdarticulo
        into p_cdarticulo
        from barras ba,
             tblslvtarea  ta,
             tblslvtareadet det
       where ta.idtarea = p_IdTarea
         and det.idtarea = ta.idtarea
         and det.cdarticulo = ba.cdarticulo
         and ba.cdeancode = p_cdBarras
         and rownum = 1;
     p_Ok    := 1;
     p_error:= Null;
  EXCEPTION
  WHEN NO_DATA_FOUND THEN
     p_Ok    := 0;
     p_error:='codigo de barras no pertenece a un artículo de la tarea: '||p_IdTarea;
  WHEN OTHERS THEN
     p_Ok    := 0;
     p_error:='Error al buscar CdArticulo!';
  END ArtBarraxTarea;

 /****************************************************************************************************
  * %v 17/02/2020 - ChM  Versión inicial GetlistadoPicking
  * %v 17/02/2020 - ChM  para un armador, lista los articulos pendientes para picking en tarea
  * %v 08/05/2020 - ChM  ajustes de todo el proceso para adecuación de picking manual
  *****************************************************************************************************/

  PROCEDURE GetlistadoPicking(p_IdPersona         IN   personas.idpersona%type  default null,
                              p_IdtareaManual     IN   tblslvtarea.idtarea%type default null,
                              P_tipoTareaManual   IN   tblslvtarea.cdtipo%type  default null,
                              p_idRemito          OUT  tblslvremito.idremito%type,
                              p_NroCarreta        OUT  tblslvremito.nrocarreta%type,
                              p_icGeneraRemito    OUT  tblslvtipotarea.icgeneraremito%type,
                              p_IdTarea           OUT  tblslvtarea.idtarea%type,
                              p_Tarea             OUT  varchar2,
                              P_DsArmador         OUT  personas.dsnombre%type,
                              p_Ok                OUT  number,
                              p_error             OUT  varchar2,
                              p_Cursor            OUT  CURSOR_TYPE) IS

    v_modulo                 varchar2(100) := 'PKG_SLV_TAREAS.GetlistadoPicking';
    v_cdtipotarea            tblslvtarea.cdtipo%type := null;
    v_cdmodoingreso          tblslvtarea.cdmodoingreso%type := null;

  BEGIN
     p_idRemito:=0;
     p_NroCarreta:=0;
     p_icGeneraRemito:=0;
     p_IdTarea:=0;
     p_Tarea:='';

      --valida si es tarea handheld
     if p_IdtareaManual is null then
       --valida si no existe armador asignado
       if p_IdPersona is null then
          p_Ok    := 0;
          p_error:='Error en Tarea. Armador no identificado para picking con Handheld.';
          return;
         end if;
     end if;

        --valida si es tarea manual
       if p_IdtareaManual is not null then
         select ta.cdtipo,
                ta.cdModoIngreso
           into v_cdtipotarea,
                v_cdmodoingreso
           from tblslvtarea ta
          where ta.idtarea = p_IdtareaManual
            and rownum=1;
         --valida si el tipo tarea corresponde con en el parametro, esto es necesario para no confundir con remito
         if v_cdtipotarea <> P_tipoTareaManual and P_tipoTareaManual is not null then
            p_Ok    := 0;
            p_error:='Error la Tarea: '||p_IdtareaManual||' no corresponde al tipo '||P_tipoTareaManual||' enviado!';
            return;
         end if;
      end if;

    for tarea in
      (select ta.idtarea,
              ta.cdtipo,
              tip.dstarea,
              ta.idpedfaltante,
              ta.idconsolidadom,
              ta.idconsolidadopedido,
              ta.idconsolidadocomi,
              tip.icgeneraremito,
              ta.cdModoIngreso,
              ta.idpersonaarmador
         from tblslvtarea ta,
              tblslvtipotarea tip
        where ta.cdtipo = tip.cdtipo
          and (p_IdPersona is null or ta.idpersonaarmador = p_IdPersona)
           -- tareas disponibles segun tblslvtipotarea  Asignado o en curso
          and ta.cdestado in (4,5,7,8,15,16,22,23,30,31,33,34)
          --devuelve de un solo registro
          and rownum=1
          --filtra por p_IdtareaManual si existe
          and (p_IdtareaManual is null or ta.idtarea = p_IdtareaManual)
          and (P_tipoTareaManual is null or ta.cdtipo = P_tipoTareaManual)
     order by ta.prioridad)
    loop
     begin

        --valida si el cdmodoingreso es handheld y la tarea es manual error
        if tarea.cdmodoingreso = c_TareaHandHeld then
          if tarea.idtarea = p_IdtareaManual and p_IdtareaManual is not null then
             p_Ok    := 0;
             p_error:='Error la tarea: '||p_IdtareaManual||' esta definida para picking con HandHeld!';
             return;
          end if;
        end if;

       --descripción del tipo de tarea
       p_Tarea := tarea.dstarea||' N° '||tarea.idpedfaltante||tarea.idconsolidadom
       ||tarea.idconsolidadopedido||tarea.idconsolidadocomi;
       p_IdTarea := tarea.idtarea;
       p_icGeneraRemito := tarea.icgeneraremito;
       --verifica si genera remito obtine la carreta del armador
       if tarea.icgeneraremito = 1 then
          getcarreta(tarea.idpersonaarmador,tarea.idtarea,p_idRemito,p_NroCarreta);
       end if;

    --devuelve la descripción del armador
     begin
        Select upper(pe.dsnombre) || ' ' || upper(pe.dsapellido) Armador
          into P_DsArmador
          from personas pe
         where pe.idpersona = tarea.idpersonaarmador;
     exception
       when others then
         P_DsArmador:='-';
     end;
     --valida si el cdmodoingreso es handheld devuelve articulos para HH
     if tarea.cdmodoingreso = c_TareaHandHeld then
     open p_cursor for
           select dta.cdarticulo Cdarticulo,
                  dta.cdarticulo||' - '||des.vldescripcion Articulo,
                  PKG_SLVArticulos.GetCodigoDeBarra(dta.cdarticulo,'BTO') Barras,
                  PKG_SLVArticulos.SetFormatoArticuloscod(dta.cdarticulo,
                  (nvl(dta.qtunidadmedidabase,0)-nvl(dta.qtunidadmedidabasepicking,0))) Cantidad,
                  PKG_SLVArticulos.GetUbicacionArticulos(dta.cdarticulo) Ubicacion,
                  PKG_SLVArticulos.CalcularPesoUnidadBase(dta.cdarticulo,dta.qtunidadmedidabase) Peso
             from tblslvtarea ta,
                  tblslvtareadet dta,
                  descripcionesarticulos des,
                  tblslvtipotarea tip
            where ta.idtarea = dta.idtarea
              --id de la tarea de mayor prioridad
              and ta.idtarea = tarea.idtarea
              and ta.cdtipo = tip.cdtipo
              and dta.cdarticulo = des.cdarticulo
              -- articulo no finalizado
              and dta.icfinalizado = 0
              --devuelve de un solo registro
              and rownum=1
         order by Ubicacion ASC,
                  Peso DESC;
     else
       -- verifica si genera remito devuelve datos de remito
       if tarea.icgeneraremito = 1 then
        open p_cursor for
           select dre.cdarticulo Cdarticulo,
                  dre.cdarticulo||' - '||des.vldescripcion Articulo,
                  PKG_SLVArticulos.SetFormatoArticuloscod(dre.cdarticulo,
                  (nvl(dre.qtunidadmedidabasepicking,0))) Cantidad
             from tblslvremito re,
                  tblslvremitodet dre,
                  descripcionesarticulos des
            where dre.cdarticulo = des.cdarticulo
              and re.idremito = dre.idremito
              and re.idtarea = tarea.idtarea
              and re.idremito = p_idRemito;
         else
           -- verifica si no genera remito devuelve datos de la tarea
           open p_cursor for
           select dta.cdarticulo Cdarticulo,
                  dta.cdarticulo||' - '||des.vldescripcion Articulo,
                  PKG_SLVArticulos.SetFormatoArticuloscod(dta.cdarticulo,
                  (nvl(dta.qtunidadmedidabasepicking,0))) Cantidad
             from tblslvtarea ta,
                  tblslvtareadet dta,
                  descripcionesarticulos des,
                  tblslvtipotarea tip
            where ta.idtarea = dta.idtarea
              --id de la tarea de mayor prioridad
              and ta.idtarea = tarea.idtarea
              and ta.cdtipo = tip.cdtipo
              and dta.cdarticulo = des.cdarticulo
              -- articulo no finalizado
              and dta.qtunidadmedidabasepicking is not null;
       end if; --genera remito
     end if;--if HH
    EXCEPTION
      WHEN OTHERS THEN
           n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       ' Error: ' || SQLERRM);
           p_Ok    := 0;
           p_error:='Error en listado. Comuniquese con Sistemas!';
           return;
      end;
      p_Ok := 1;
      p_error:=null;
      return;
    end loop;
   p_Ok := 0;
   p_error:='No existen tareas Pendientes!';
  EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       ' Error: ' || SQLERRM);
      p_Ok    := 0;
      p_error:='Error en listado. Comuniquese con sistemas!';
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
            --  tareas disponibles segun tblslvtipotarea  Asignado o en curso
            and ta.cdestado in (4,5,7,8,15,16,22,23,30,31,33,34)
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
  * %v 20/02/2020 - ChM  Versión inicial VerificaPersonaTarea
  * %v 20/02/2020 - ChM  para un armador y una tarea verifica si la tiene asignada
  * %v 16/03/2020 - ChM  Agrego finalizar pausa Armador si existen pausas registradas para el día
  *****************************************************************************************************/
  FUNCTION VerificaPersonaTarea(p_IdPersona   personas.idpersona%type,
                                p_IdTarea     tblslvtarea.idtarea%type)
                                RETURN INTEGER IS

    v_modulo      varchar2(100) := 'PKG_SLV_TAREAS.VerificaPersonaTarea';
    v_estado      integer:=0;
    v_p_Ok        number;
    v_p_error     varchar2(150);
    BEGIN
      --verifica si existen pausas registradas
      select count(*)
         into v_estado
         from tblslvtarea ta
        where ta.idpersonaarmador = p_IdPersona
          --valida solo tareas del dia
          and trunc(ta.dtinsert,'dd/mm/yyyy') = trunc(sysdate,'dd/mm/yyyy')
          and ta.cdestado = C_AsignadoTareaPausa; --tarea Asignada en pausa
      -- si tiene pausa la finaliza
      if v_estado <> 0 then
        SetFinalizaPausaTarea(p_IdPersona,v_p_Ok,v_p_error);
        if v_p_OK = 0 then
          return 0; --devuelve 0 si tiene pausa y no logra finalizarla
       end if;
       end if;
      --verifica si la tarea esta asignada al armador
      v_estado:=0;
         select count(*)
           into v_estado
           from tblslvtarea ta,
                tblslvtareadet dta
          where ta.idtarea = dta.idtarea
            and ta.idtarea = p_IdTarea
            and ta.idpersonaarmador = p_IdPersona
            --  tareas asignadas o en curso segun tblslvtipotarea
            and ta.cdestado in (4,5,7,8,15,16,22,23,30,31,33,34);
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
  * %v 20/02/2020 - ChM  Versión inicial SetInsertarRemito
  * %v 20/02/2020 - ChM  inserta remito
  *****************************************************************************************************/
  FUNCTION SetInsertarRemito(p_IdTarea               tblslvtarea.idtarea%type,
                             p_NroCarreta            tblslvremito.nrocarreta%type)
                             RETURN INTEGER IS

    v_modulo      varchar2(100) := 'PKG_SLV_TAREAS.SetInsertarRemito';
    v_idremito    tblslvremito.idremito%type;
  BEGIN
   insert into tblslvremito
               (idremito,
               idtarea,
               idpedfaltanterel,
               nrocarreta,
               cdestado,
               dtremito,
               dtupdate)
        values (seq_remito.nextval,    --idremito
                p_IdTarea,              --idtarea
                null,                   --idpedfaltanterel
                p_NroCarreta,          --NroCarreta
                C_EnCursoRemito,      --Cdestado 36 remito en curso
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
  * %v 26/02/2020 - ChM  Versión inicial SetDetalleRemito
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
   --LETY. sale por nulls
   v_cantdetrem                    integer :=0;

  BEGIN
   --verifica si existe remito en curso
   select count(*)
     into v_res
     from tblslvremito re
    where re.cdestado = C_EnCursoRemito  --Cdestado 36 remito en curso
      and re.idremito = p_idRemito
      and re.idtarea = p_idtarea;

      if v_res>0 then
        --verifica si existe articulo en proceso de remito y busca la cantidad picking
        --LETY. cambio la forma de comparar si existe en el detalle remito
         select count(*)
           into v_cantdetrem
           from tblslvremitodet det
          where det.idremito = p_idRemito
            and det.cdarticulo=p_cdArticulo;
        -- si encuentra detalle actualiza la cantidad picking
        --LETY. verifica si encontro el articulo en el remito
        if v_cantdetrem>0 then
          select det.idremitodet,
                det.qtunidadmedidabasepicking
           into v_idremitodet,
                v_qtunidadmedidabasepicking
           from tblslvremitodet det
          where det.idremito = p_idRemito
            and det.cdarticulo=p_cdArticulo;
        
         update tblslvremitodet det
             set det.qtunidadmedidabasepicking = nvl(v_qtunidadmedidabasepicking,0)+p_cantidad,
                 det.dtupdate = sysdate
           where det.idremitodet = v_idremitodet
             and det.idremito = p_idRemito
             and det.cdarticulo = p_cdArticulo;
             IF SQL%ROWCOUNT = 0  THEN
                n_pkg_vitalpos_log_general.write(2,
                                 'Modulo: ' || v_modulo ||
                                 ' imposible actualizar detalle del remito : '||p_idRemito);
                                  return 0; -- devuelve 0 si no actualiza
             END IF;
         else --si no encuentra el detalle inserto el articulo en tblslvremitodet
           insert into tblslvremitodet
                       (idremitodet,
                       idremito,
                       cdarticulo,
                       qtunidadmedidabasepicking,
                       qtpiezaspicking,
                       dtinsert,
                       dtupdate)
                values (seq_remitodet.nextval,
                        p_idRemito,
                        p_cdArticulo,
                        p_cantidad,
                        null, --qtpiezaspicking
                        sysdate,
                        sysdate); --LETY. tiro error en el dtupdate en null
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
  * %v 20/02/2020 - ChM  Versión inicial SetFinalizarRemito
  * %v 20/02/2020 - ChM  cambia el estado del remito a finalizado
  *****************************************************************************************************/
  FUNCTION SetFinalizarRemito(p_idremito      tblslvremito.idremito%type)
                           RETURN INTEGER IS

    v_modulo      varchar2(100) := 'PKG_SLV_TAREAS.SetFinalizarRemito';
    BEGIN
        update tblslvremito r
           set r.cdestado=C_FinalizadoRemito, --remito finalizado
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
  * %v 21/02/2020 - ChM  Versión inicial SetEstadoTarea
  * %v 21/02/2020 - ChM  actualiza estado de la tarea segun parametro 1 en curso 0 finalizado
  *****************************************************************************************************/
  FUNCTION SetEstadoTarea(p_IdTarea          tblslvtarea.idtarea%type,
                          p_band             integer default 1)
                           return integer IS

   v_tipotarea            tblslvtarea.cdtipo%type;
   v_modulo               varchar2(100) := 'PKG_SLV_TAREAS.SetEstadoTarea';

  BEGIN
     select ta.cdtipo
         into v_tipotarea
         from tblslvtarea ta
        where ta.idtarea = p_IdTarea;
       --tipo consolidadoM
       if v_tipotarea = c_TareaConsolidadoMulti then
         if p_band = 1 then -- 1 en curso 0 finalizado
           update tblslvtarea ta
              set ta.cdestado = C_EnCursoTareaConsolidadoM,
                  ta.dtupdate = sysdate,
                  ta.dtinicio = sysdate
            where ta.idtarea = p_IdTarea;
         else
           update tblslvtarea ta
              set ta.cdestado = C_FinalizadoTareaConsolidadoM,
                  ta.dtupdate = sysdate,
                  ta.dtfin = sysdate
            where ta.idtarea = p_IdTarea;
         end if;
       end if;
        --tipo faltante consolidadoM
        if v_tipotarea = c_TareaConsolidaMultiFaltante then
          if p_band = 1 then -- 1 en curso 0 finalizado
           update tblslvtarea ta
              set ta.cdestado = C_EnCursoTareaFaltaConsolidaM,
                  ta.dtupdate = sysdate,
                  ta.dtinicio = sysdate
            where ta.idtarea = p_IdTarea;
         else
           update tblslvtarea ta
              set ta.cdestado = C_FinalizaTareaFaltaConsolidaM,
                  ta.dtupdate = sysdate,
                  ta.dtfin = sysdate
            where ta.idtarea = p_IdTarea;
         end if;
       end if;
        --tipo consolidado pedido
        if v_tipotarea = c_TareaConsolidadoPedido then
           if p_band = 1 then -- 1 en curso 0 finalizado
           update tblslvtarea ta
              set ta.cdestado = C_EnCursoTareaConsolidaPedido,
                  ta.dtupdate = sysdate,
                  ta.dtinicio = sysdate
            where ta.idtarea = p_IdTarea;
         else
           update tblslvtarea ta
              set ta.cdestado = C_FinalizaTareaConsolidaPedido,
                  ta.dtupdate = sysdate,
                  ta.dtfin = sysdate
            where ta.idtarea = p_IdTarea;
         end if;
       end if;
        --tipo faltante consolidado pedido
        if v_tipotarea = c_TareaConsolidaPedidoFaltante then
           if p_band = 1 then -- 1 en curso 0 finalizado
           update tblslvtarea ta
              set ta.cdestado = C_EnCursoTareaFaltaConsoliPed,
                  ta.dtupdate = sysdate,
                  ta.dtinicio = sysdate
            where ta.idtarea = p_IdTarea;
         else
           update tblslvtarea ta
              set ta.cdestado = C_FinalizaTareaFaltaConsoliPed,
                  ta.dtupdate = sysdate,
                  ta.dtfin = sysdate
            where ta.idtarea = p_IdTarea;
         end if;
       end if;
        --tipo consolidado comisionista
        if v_tipotarea = c_TareaConsolidadoComi then
           if p_band = 1 then -- 1 en curso 0 finalizado
           update tblslvtarea ta
              set ta.cdestado = C_EnCursoTareaConsolidadoComi,
                  ta.dtupdate = sysdate,
                  ta.dtinicio = sysdate
            where ta.idtarea = p_IdTarea;
         else
           update tblslvtarea ta
              set ta.cdestado = C_FinalizaTareaConsolidaComi,
                  ta.dtupdate = sysdate,
                  ta.dtfin = sysdate
            where ta.idtarea = p_IdTarea;
         end if;
       end if;
        --tipo faltante consolidado comisionista
        if v_tipotarea = c_TareaConsolidadoComiFaltante then
           if p_band = 1 then -- 1 en curso 0 finalizado
           update tblslvtarea ta
              set ta.cdestado = C_EnCursoTareaFaltaConsoComi,
                  ta.dtupdate = sysdate,
                  ta.dtinicio = sysdate
            where ta.idtarea = p_IdTarea;
         else
           update tblslvtarea ta
              set ta.cdestado = C_FinalizaTareaFaltaConsolComi,
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
  * %v 20/02/2020 - ChM  Versión inicial SetDetalleTarea
  * %v 20/02/2020 - ChM  actualiza en detalle la cantidad ingresada en piking para una tarea
  * %v 11/05/2020 - ChM  verifica si la cantidad a regisitrar es mayor a cero, sino, no la agrega al remito
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
      --verifica si la cantidad a regisitrar es mayor a cero, sino, no la agrega al remito.
       if p_icgeneraremito = 1 and p_idRemito <> 0 and v_cantidad > 0 then
         --LETY. cambio el v_cantidad por el p_cantidad, porque el v_cantidad ya tiene la suma del picking de la tarea... y me sumaba todo de nuevo
          v_res:=SetDetalleRemito(p_idRemito,p_idTarea,p_cdArticulo,p_cantidad);
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
  * %v 21/02/2020 - ChM  Versión inicial SetFindetalleTarea
  * %v 21/02/2020 - ChM  actualiza el icfinalizado del detalle tarea
  *****************************************************************************************************/
  FUNCTION SetFindetalleTarea(p_IdTarea          tblslvtarea.idtarea%type,
                              p_cdArticulo       tblslvtareadet.cdarticulo%type)
                       return integer IS

    v_modulo               varchar2(100) := 'PKG_SLV_TAREAS.SetFindetalleTarea';

  BEGIN

     --actualiza el detalle tarea a finalizado 1
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
  * %v 20/02/2020 - ChM  Versión inicial VerificaDetalleTarea
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
  * %v 28/02/2020 - ChM  Versión inicial SetFinalizarConsolidados
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
         set pe.cdestado = C_CerradoConsolidadoPedido, --cerrado el consolidadoPedido
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
         set f.cdestado = C_FinalizaFaltaConsolidaPedido, --finalizado el consolidado pedido faltante
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
         set m.cdestado = C_FinalizadoConsolidadoM, --finalizado el consolidadoM
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
         set com.cdestado = C_FinalizadoConsolidadoComi, --finalizado el consolidadocomi
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
  * %v 21/02/2020 - ChM  Versión inicial SetFinalizarTarea
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
         nvl(dta.qtunidadmedidabasepicking,0) qtunidadmedidabasepicking,
         nvl(dta.qtpiezaspicking,0) qtpiezaspicking,
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
     if tarea.cdtipo in(c_TareaConsolidadoMulti,c_TareaConsolidaMultiFaltante) and tarea.idconsolidadom is not null then
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
     if tarea.cdtipo in(c_TareaConsolidadoComi,c_TareaConsolidadoComiFaltante) and tarea.idconsolidadocomi is not null then

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
     if tarea.cdtipo = c_TareaConsolidadoPedido and tarea.idconsolidadopedido is not null then
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
      --actualiza la cantidad picking en faltante de pedido
     if tarea.cdtipo = c_TareaConsolidaPedidoFaltante and tarea.idpedfaltante is not null then
      update tblslvpedfaltantedet df
          set (df.qtunidadmedidabasepicking,
              df.qtpiezaspicking) =
              (select nvl(df.qtunidadmedidabasepicking,0)+tarea.qtunidadmedidabasepicking unidad,
                     nvl(df.qtpiezaspicking,0)+tarea.qtpiezaspicking pieza
                from tblslvpedfaltantedet df
               where df.idpedfaltante = tarea.idpedfaltante
                 and df.cdarticulo = tarea.cdarticulo)
        where df.idpedfaltante = tarea.idpedfaltante
          and df.cdarticulo = tarea.cdarticulo;

        if SQL%ROWCOUNT = 0  then
          n_pkg_vitalpos_log_general.write(2,
                  'Modulo: ' || v_modulo ||
                  ' imposible actualizar Faltantes de Pedido: '||tarea.idpedfaltante);
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
  * %v 11/05/2020 - ChM  Versión inicial SetFinTarea
  * %v 11/05/2020 - ChM  Finaliza la tarea por completo y agrea 0 en los faltantes si existen
  *                     (creada para picking manual)
  *****************************************************************************************************/
  PROCEDURE SetFinTarea(p_IdTarea          IN tblslvtarea.idtarea%type,
                        p_idRemito         IN tblslvremito.idremito%type default null,
                        p_IdPersonaArmador IN personas.idpersona%type,
                        p_Ok               OUT number,
                        p_error            OUT varchar2) IS
  
    v_modulo varchar2(100) := 'PKG_SLV_TAREAS.SetFinTarea';
  
  BEGIN
    --pone en cero lo faltante por pickear  y actuliza directo el detalle tarea a finalizado
    update tblslvtareadet dta
       set dta.qtunidadmedidabasepicking = 0 --faltante
     where dta.idtarea = p_IdTarea
       and dta.qtunidadmedidabasepicking is null;  
     
    update tblslvtareadet dta
       set dta.icfinalizado = 1 --finalizado
     where dta.idtarea = p_IdTarea
       and dta.icfinalizado <> 1;
       
    --verifica si NO existe lineas pendientes por picking. Finaliza piking de la tarea      
    if VerificaTareaPicking(p_IdPersonaArmador, p_IdTarea) = 0 then
      if p_idremito <> 0 then
        -- SI genera remito finaliza remito
        if SetFinalizarRemito(p_idremito) = 0 then
          p_Ok    := 0;
          p_error := 'No es posible actualizar Remito: ' || p_idremito ||
                     'Comuniquese con Sistemas!';
          rollback;
          return;
        end if;
      end if;
      --finaliza Tarea
      if SetFinalizarTarea(p_IdPersonaArmador, p_IdTarea) <> 1 then     
        p_Ok    := 0;
        p_error := 'Falla finalizar tarea. Comuniquese con Sistemas!';
        rollback;
        return;
      end if;
    end if;
    p_Ok    := 1;
    p_error := ' ';
    commit;
  EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo || ' Error: ' ||
                                       SQLERRM);
      rollback;
      p_Ok    := 0;
      p_error := 'Error al finalizar tarea. Comuniquese con sistemas!';
      
  END SetFinTarea;
  
   /****************************************************************************************************
  * %v 11/05/2020 - ChM  Versión inicial SetRegistrarPickingM
  * %v 11/05/2020 - ChM  para un idpersona registra el picking manual
  *****************************************************************************************************/
  
  PROCEDURE SetRegistrarPickingM(p_idRemito         IN   tblslvremito.idremito%type default null,
                                 p_NroCarreta       IN   tblslvremito.nrocarreta%type,
                                 p_cdBarras         IN   barras.cdeancode%type,
                                 p_cantidad         IN   tblslvtareadet.qtunidadmedidabase%type,                                
                                 p_IdTarea          IN   tblslvtarea.idtarea%type,
                                 p_IdPersonaManual  IN   personas.idpersona%type default null,
                                 p_cdmodoingreso    IN   tblslvtarea.cdmodoingreso%type default 0,
                                 p_FinTarea         OUT  number,
                                 p_Ok               OUT  number,
                                 p_error            OUT  varchar2) IS
                                
  v_modulo                 varchar2(100) := 'PKG_SLV_TAREAS.SetRegistrarPickingM';
  v_cdmodoingreso          tblslvtarea.cdmodoingreso%type := null;
  v_idpersonaarmador       tblslvtarea.idpersonaarmador%type;                              
  v_cdarticulo             tblslvtareadet.cdarticulo%type;
                                
  BEGIN
     --  valida modoIngreso de la tblslvtarea(tabla) es igual al p_cdModoIngreso (parametro)
   select ta.cdModoIngreso,
          ta.idpersonaarmador
     into v_cdmodoingreso,
          v_idpersonaarmador
     from tblslvtarea ta
    where ta.idtarea = p_Idtarea
      and rownum=1;
   --necesario para no confundir con remito  
   if v_cdmodoingreso <> p_cdmodoingreso  then
      p_Ok    := 0;
      p_error:='Error la Tarea: '||p_Idtarea||' no corresponde al tipo picking enviado!';
      return;
   end if;

   -- verifica el idpersona segun el tipo tarea Manual
   if v_cdmodoingreso <> c_TareaHandHeld  then
      if p_IdPersonaManual is null then
         p_Ok    := 0;
         p_error:='Error la Tarea: '||p_Idtarea||' está en modo ingreso MANUAL con IdPersona en NULL';
         return;
      end if;
   end if;
   
   --valida si se desea finalizar la tarea
   if p_cdBarras = 'FIN' then
     SetFinTarea (p_IdTarea,p_idRemito,v_idpersonaarmador,p_Ok,p_error);
   if p_Ok = 0 then
     return;
   end if; 
    p_FinTarea:=1;
   else 
       --LETY. no me dejaba finalizar el remito, salia por exception de barras no pertenece a tarea
       if p_cdBarras = 'F' then
          v_cdarticulo:='';
       else
           --verifica si el p_cdbarras pertenece a un articulo de la tarea manual
         ArtBarraxTarea(p_IdTarea,
                        p_cdBarras,
                        v_cdarticulo,
                        p_Ok,
                        p_error);
          if p_Ok = 0 then
             return;
          end if; 
       end if;  
                  
   --invoca registrar picking con el idpersonaarmador de la tarea y el cdarticulo correcto
      SetRegistrarPicking(v_idpersonaarmador,
                          p_idRemito,
                          p_NroCarreta,
                          p_cdBarras,
                          p_cantidad,
                          v_cdarticulo,
                          p_IdTarea, 
                          p_FinTarea,                               
                          p_Ok,
                          p_error);
      if p_Ok = 0 then
         return;
      end if; 
   end if; --if p_cdBarras = 'FIN' 
   p_ok := 1;
   p_error :=' ';            
   EXCEPTION
   WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       ' Error: ' || SQLERRM);
      p_Ok    := 0;
      p_error:='Error en Piking. Comuniquese con sistemas!';

   END SetRegistrarPickingM;    

 /****************************************************************************************************
  * %v 19/02/2020 - ChM  Versión inicial SetRegistrarPicking
  * %v 19/02/2020 - ChM  para un armador, registra el picking del articulo en tarea detalle
  *****************************************************************************************************/

  PROCEDURE SetRegistrarPicking(p_IdPersona        IN   personas.idpersona%type,
                                p_idRemito         IN   tblslvremito.idremito%type default null,
                                p_NroCarreta       IN   tblslvremito.nrocarreta%type,
                                p_cdBarras         IN   barras.cdeancode%type,
                                p_cantidad         IN   tblslvtareadet.qtunidadmedidabase%type,
                                p_cdarticulo       IN   tblslvtareadet.cdarticulo%type,
                                p_IdTarea          IN   tblslvtarea.idtarea%type,   
                                p_FinTarea         OUT  number,                             
                                p_Ok               OUT  number,
                                p_error            OUT  varchar2) IS

    v_modulo                 varchar2(100) := 'PKG_SLV_TAREAS.SetRegistrarPicking';
    v_idremito               tblslvremito.idremito%type;
    v_NroCarreta             tblslvremito.nrocarreta%type;
    v_icgeneraremito         tblslvtipotarea.icgeneraremito%type:=0;
    v_cdunidad               barras.cdunidad%type;
    v_res                    integer;
    
   BEGIN
     --indica tarea no finalizada
      p_FinTarea:=0;                       
     --verifica si cantidad es negativa
     if p_cantidad < 0 then
       p_Ok:=0;
       p_error:='Imposible registrar cantidad negativa!';
       rollback;
       return;
     end if;

     -- valida si la tarea pertenece al armador y esta asignada o en curso
      if VerificaPersonaTarea(p_IdPersona,p_IdTarea) = 0  then
          p_Ok:=0;
          p_error:='Tarea no asignada o finalizada!';
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
      --LETY. cambio p_idremito por v_idremito
     if v_idremito = 0 and p_NroCarreta <> 0 and upper(trim(p_cdBarras)) <> 'F' then
        v_idremito:=0;
        GetCarreta(p_IdPersona,p_IdTarea,v_idRemito,v_NroCarreta);
        if v_idremito <> 0 then
           p_Ok:=0;
           p_error:='Tiene asignaciones pendientes no finalizadas!';
           rollback;
           return;
        else
         --verifica si aun quedan detalle de tareas por piking
         if VerificaTareaPicking(p_IdPersona,p_IdTarea) = 1 then
          --crear remito
           v_idremito:=SetInsertarRemito(p_IdTarea,p_NroCarreta);
           if v_idremito = 0 then
              p_Ok:=0;
              p_error:='No es posible crear el Remito. Comuniquese con Sistemas!';
              rollback;
              return;
           end if;
            
         end if;
        end if;
     end if;

        --valida si la carreta y remito esta en cero
        --LETY. Cambio p_idremito por v_idremito
        if v_idremito = 0 and p_NroCarreta = 0 then
           p_Ok:=0;
           p_error:='Remito y carreta en cero 0!';
           rollback;
           return;
        end if;

     --valida si codigo de barra en f si existe remito lo finaliza
     --LETY. Cambio p_idremito por v_idremito
     if upper(trim(p_cdBarras)) ='F' and v_idremito <> 0 then
         if SetFinalizarRemito(v_idremito)=0 then
           p_Ok:=0;
           p_error:='No es posible actualizar Remito: '||v_idremito||'Comuniquese con Sistemas!';
           rollback;
           return;
         else -- se finaliza remito y termina el procedimiento
           p_Ok:=1;
           commit;
           return;
         end if;
      else
          if v_idremito = 0 then
           p_Ok:=0;
           p_error:='No es posible finalizar Remito en 0. Comuniquese con Sistemas!';
           rollback;
           return;
          end if;
      end if;
     end if; --if genera remito

    if v_icgeneraremito = 0 then --if NO genera remito
      --verifica codigo de barras en f para pedidos sin remito
       if upper(trim(p_cdBarras)) ='F' then
           p_Ok:=0;
           p_error:='No aplica Remito y carreta para este pedido!';
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
          p_error:='El Codigo de barra no corresponde al Artículo!';
          rollback;
          return;
      else
        -- actualiza la cantidad picking
          v_res:=SetDetalleTarea(p_IdTarea,p_cdArticulo,p_cantidad,v_cdunidad,v_icgeneraremito,v_idremito);
          --La Cantidad picking Supera la Cantidad Base
          if v_res = -2 then
             p_Ok:=0;
             p_error:='La cantidad ingresada supera la cantidad pedida!';
             rollback;
             return;
          end if;
          --error no aplico update al detalle tarea
           if v_res = -1 then
             p_Ok:=0;
             p_error:='Falla actualizar piking. Comuniquese con sistemas!';
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
            p_error:='No es posible finalizar linea. Artículo o ID tarea NULO!';
            rollback;
            return;
        end if;
         --finaliza la linea del detalle tarea
         if SetFindetalleTarea(p_IdTarea,p_cdArticulo)<> 1 then
            p_Ok:=0;
            p_error:='No es posible finalizar linea. Comuniquese con Sistemas!';
            rollback;
            return;
         end if;
      end if;


      --verifica si debe finalizar linea por cantidades alcanzadas
     if VerificaDetalleTarea(p_IdTarea,p_cdArticulo) = 1 then
         if SetFindetalleTarea(p_IdTarea,p_cdArticulo)<> 1 then
            p_Ok:=0;
            p_error:='No es posible finalizar linea2. Comuniquese con Sistemas!';
            rollback;
            return;
         end if;
     end if;

     --verifica si NO existe lineas pendientes por picking. Finaliza piking de la tarea
         if VerificaTareaPicking(p_IdPersona,p_IdTarea) = 0 then
            if v_icgeneraremito = 1 then --if SI genera remito
              --LETY. cambio p_idremito por v_idremito
                if SetFinalizarRemito(v_idremito)=0 then
                    p_Ok:=0;
                    p_error:='No es posible actualizar remito: '||v_idremito||'Comuniquese con Sistemas!';
                    rollback;
                   return;
                end if;
              end if;
              --finaliza Tarea
            if SetFinalizarTarea(p_IdPersona,p_IdTarea) <> 1 then
                p_Ok:=0;
                p_error:='Falla finalizar tarea. Comuniquese con Sistemas!';
                rollback;
                return;
             else 
               --indica tarea finalizada
               p_FinTarea:=1;   
            end if;
         end if;
     p_Ok:=1;
     p_error :=' '; 
    commit;
    EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       ' Error: ' || SQLERRM);
      rollback;
      p_Ok    := 0;
      p_error:='Error en piking. Comuniquese con sistemas!';

   END SetRegistrarPicking;

  /****************************************************************************************************
  * %v 04/03/2020 - ChM  Versión inicial listar Prioridades Tareas por Armador
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
           -- tareas disponibles Asignado y en curso segun tblslvtipotarea
          and ta.cdestado in (4,5,7,8,15,16,22,23,30,31,33,34)
     order by ta.prioridad;

  EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       ' Error: ' || SQLERRM);
 END GetPrioridadTarea;

  /****************************************************************************************************
  * %v 04/03/2020 - ChM  Versión inicial Cambiar Prioridades Tareas
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
  * %v 13/05/2020 - ChM  Versión inicial GetArticulosXTarea
  * %v 13/05/2020 - ChM  Listado de detalle de articulos que conforman una tarea
  * %v 15/05/2020 - ChM  Incorporo cursor para cabecera de pedido
  *****************************************************************************************************/
  PROCEDURE GetArticulosXTarea(p_IdTarea      IN  tblslvtarea.idtarea%type,
                               p_DsSucursal   OUT sucursales.dssucursal%type,                   
                               p_CursorCAB    OUT CURSOR_TYPE,                                       
                               p_Cursor       OUT CURSOR_TYPE) IS

    v_modulo      varchar2(100) := 'PKG_SLV_TAREAS.GetArticulosXTarea';
    v_tipotarea   tblslvtarea.cdtipo%type;
  BEGIN
    --descripcion de la sucursal
    begin
    select su.dssucursal
      into p_DsSucursal
      from sucursales su
     where su.cdsucursal = g_cdSucursal
       and rownum=1;
     exception
       when others then
         p_DsSucursal:='_';  
    end;   
    --define el tipo de tarea
    begin
    select ta.cdtipo
      into v_tipotarea
      from tblslvtarea ta
     where ta.idtarea = p_IdTarea
       and rownum=1;
     exception
       when others then
        v_tipotarea:='-';  
    end;
    --cursor de cabecera para pedidos   
    if v_TipoTarea = c_TareaConsolidadoPedido then
       OPEN p_CursorCAB FOR  
           select ta.cdtipo TipoTarea,        
                  cp.idconsolidadom Idconsolidado,
                  ta.idconsolidadopedido Idconsolidadopedido,
                  ta.dtinsert fechaconsolidado,
                  upper(pe.dsnombre) || ' ' 
                  || upper(pe.dsapellido) Armador,
                  pe.idpedido,
                  pe.dtaplicacion fechapedido, 
                  e.cdcuit||
                  NVL (e.dsrazonsocial, e.dsnombrefantasia) cliente,
                  nvl(op.dsobservacion,'-') dsobservacion,
                  de.dscalle||' '||
                  de.dsnumero||' CP ('||
                  trim(de.cdcodigopostal)||') '|| 
                  l.dslocalidad|| ' - '|| 
                  p.dsprovincia domicilio
             from pedidos pe,
                  entidades e,
                  tblslvtarea ta,
                  personas pe,
                  observacionespedido op,
                  tblslvconsolidadopedido cp,
                  tblslvconsolidadopedidorel pre,
                  direccionesentidades de, 
                  localidades l,
                  provincias p
            where cp.identidad=de.identidad
              and pe.sqdireccion=de.sqdireccion
              and pe.cdtipodireccion=de.cdtipodireccion
              and de.cdlocalidad=l.cdlocalidad
              and de.cdprovincia=p.cdprovincia 
              and pe.identidad = e.identidad
              and pe.idpedido = op.idpedido
              and cp.idconsolidadopedido = pre.idconsolidadopedido
              and pre.idpedido = pe.idpedido
              and cp.idconsolidadopedido = ta.idconsolidadopedido
              and ta.idpersonaarmador = pe.idpersona
              and ta.idtarea = p_IdTarea;
    --cursor de cabecera para todos los demás documentos POR AHORA...  
    else  
    OPEN p_CursorCAB FOR    
         select ta.cdtipo TipoTarea,
                coalesce(
                ta.idpedfaltante,
                ta.idconsolidadom,
                ta.idconsolidadopedido,
                ta.idconsolidadocomi) Idconsolidado,
                0 Idconsolidadopedido,
                ta.dtinsert fechaconsolidado,
                upper(pe.dsnombre) || ' ' || upper(pe.dsapellido) Armador,
                sysdate fechapedido, 
                '-' cliente,
                '-' dsobservacion,
                '-' domicilio
           from tblslvtarea ta,
                personas pe
          where ta.idtarea = p_IdTarea
            and ta.idpersonaarmador = pe.idpersona
            and rownum=1;
    end if; --cursor cabecera
    --cursor de detalle de articulos
     OPEN p_Cursor FOR
            select A.Sector,
                   A.articulo,
                   PKG_SLVArticulos.SetFormatoArticulos(A.uxb,A.base) Cantidad,
                 --  PKG_SLVArticulos.SetFormatoArticulos(A.uxb,A.picking) Cantidad_picking,
                   PKG_SLVArticulos.SetFormatoArticulos(A.uxb,A.stock) stock,
                   A.uxb,
                   A.Ubicacion
              from (Select gs.cdgrupo||' - ' ||gs.dsgruposector||' ('||sec.dssector || ')' Sector,
                           art.cdarticulo || '- ' || des.vldescripcion Articulo,
                           art.cdarticulo,
                           det.qtunidadmedidabase base,
                         --  det.qtunidadmedidabasepicking picking,
                           PKG_SLV_Articulos.GetStockArticulos(art.cdarticulo) STOCK,
                           posapp.n_pkg_vitalpos_materiales.GetUxB(art.cdarticulo) UXB,
                           PKG_SLVArticulos.GetUbicacionArticulos(ART.cdarticulo) UBICACION
                      from tblslvtarea ta,
                           tblslvtareadet det,
                           tblslv_grupo_sector gs,
                           sectores sec,
                           descripcionesarticulos des,
                           articulos art
                     where ta.idtarea = det.idtarea
                       and det.cdarticulo = art.cdarticulo
                       and det.idgrupo_sector = gs.idgrupo_sector
                       and sec.cdsector = gs.cdsector
                       and art.cdarticulo = des.cdarticulo
                       and gs.cdsucursal = g_cdSucursal
                       and ta.idtarea = p_idTarea) A;
  EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       '  Error: ' || SQLERRM);
  END GetArticulosXTarea;

  /****************************************************************************************************
  * %v 16/03/2020 - ChM  Versión inicial SetPausaTarea
  * %v 16/03/2020 - ChM  inserta una pausa al armador que recibe autorizado por idpersona
  *****************************************************************************************************/
  PROCEDURE SetPausaTarea(p_IdPersona   IN   personas.idpersona%type,
                          p_IdArmador   IN   personas.idpersona%type,
                          p_Ok          OUT  number,
                          p_error       OUT  varchar2) IS

   v_modulo      varchar2(100) := 'PKG_SLV_TAREAS.SetPausaTarea';
   v_prioridad   tblslvtarea.prioridad%type:=null;

    BEGIN
       select ta.prioridad
         into v_prioridad
         from tblslvtarea ta,
              tblslvtareadet det
        where ta.idtarea = det.idtarea
          and ta.idpersonaarmador = p_IdArmador
          --valida solo tareas del dia
          and trunc(ta.dtinsert,'dd/mm/yyyy') = trunc(sysdate,'dd/mm/yyyy')
          --valida tareas iniciadas o finalizadas
          and ta.dtinicio is not null
          and rownum=1
     order by ta.dtinicio desc;

       if v_prioridad is null then
          p_Ok:=0;
          p_error:='El Armador no tiene Tareas Finalizadas, ni en Curso!';
          return;
        end if;
        --OOJOO Preguntar si se puede agregar observación a la tarea para la pausa.
        --inserta la cabezera de la pausa de la tarea
        insert into tblslvtarea
                    (idtarea,
                    idpedfaltante,
                    idconsolidadom,
                    idconsolidadopedido,
                    idconsolidadocomi,
                    cdtipo,
                    idpersona,
                    idpersonaarmador,
                    dtinicio,
                    dtfin,
                    prioridad,
                    cdestado,
                    dtinsert,
                    dtupdate,
                    cdmodoingreso)
             values (seq_tarea.nextval,
                     null, --idfaltante
                     null, --idconsolidadoM
                     null, --idconsolidadopedido
                     null, --idconsolidadocomi
                     c_TareaPausa,    --TipoTarea 7 Pausa Tarea
                     p_IdPersona,
                     p_IdArmador,
                     sysdate,  --dtinicio
                     null,  --dtfin
                     v_prioridad,  --prioridad
                     C_AsignadoTareaPausa,    --tblslvestado 38 pausa asignada
                     sysdate, --dtinsert
                     null,   --dtupdate
                     1);   --pausa aplioca solo para HANDHELP
    EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       '  Error: ' || SQLERRM);
  END SetPausaTarea;

  /****************************************************************************************************
  * %v 16/03/2020 - ChM  Versión inicial SetFinalizaPausaTarea
  * %v 16/03/2020 - ChM  Finaliza la pausa al armador que recibe
  *****************************************************************************************************/
  PROCEDURE SetFinalizaPausaTarea(p_IdArmador   IN   personas.idpersona%type,
                                  p_Ok          OUT  number,
                                  p_error       OUT  varchar2) IS

   v_modulo      varchar2(100) := 'PKG_SLV_TAREAS.SetFinalizaPausaTarea';
   v_idtarea     tblslvtarea.idtarea%type:=null;

    BEGIN
      select ta.idtarea
         into v_idtarea
         from tblslvtarea ta
        where ta.idpersonaarmador = p_IdArmador
          --valida solo tareas del dia
          and trunc(ta.dtinsert,'dd/mm/yyyy') = trunc(sysdate,'dd/mm/yyyy')
          and ta.cdestado = C_AsignadoTareaPausa --tarea Asignada en pausa
     order by ta.dtinicio;

       if v_idtarea is null then
          p_Ok:=0;
          p_error:='El Armador no tiene Pausas iniciadas!';
          return;
        end if;

    update tblslvtarea ta
       set ta.cdestado = C_FinalizadoTareaPausa, --finaliza tarea
           ta.dtfin = sysdate
     where ta.idtarea = v_IdTarea;

   if SQL%ROWCOUNT = 0  then
      p_Ok:=0;
      p_error:='Imposible Finalizar Pausa. Comuniquese con Sistemas!';
      rollback;
      return;
   end if;

  commit;
  p_Ok:=1;

   EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       '  Error: ' || SQLERRM);
  END SetFinalizaPausaTarea;

  /****************************************************************************************************
  * %v 16/03/2020 - ChM  Versión inicial SetLiberarArmador
  * %v 16/03/2020 - ChM  Finaliza y libera las tareas de un armador que recibe
  *****************************************************************************************************/
  PROCEDURE SetLiberarArmador(p_IdArmador   IN   personas.idpersona%type,
                              p_Ok          OUT  number,
                              p_error       OUT  varchar2) IS

   v_modulo                   varchar2(100) := 'PKG_SLV_TAREAS.SetLiberarArmador';
   v_tarea                    number;
   v_icgeneraremito           tblslvtipotarea.icgeneraremito%type;
   v_idremito                 tblslvremito.idremito%type;

    BEGIN
      select count(*)
         into v_tarea
         from tblslvtarea ta,
              tblslvtareadet det
        where ta.idtarea = det.idtarea
          and ta.idpersonaarmador = p_IdArmador
           -- tareas disponibles Asignadas
          and ta.cdestado in (select e.cdestado
                                from tblslvestado e
                               where e.dsestado like '%Asignado%'
                                 --pausa tarea
                                 and e.cdestado <> 38);
       if v_tarea <> 0 then
       --elimina todas las tareas asignadas al armador
        delete tblslvtareadet det
         where det.idtarea in(select ta.idtarea
                                from tblslvtarea ta
                               where ta.idpersonaarmador = p_IdArmador
                                  -- tareas disponibles Asignadas
                                 and ta.cdestado in (select e.cdestado
                                                       from tblslvestado e
                                                      where e.dsestado like '%Asignado%'
                                                        --pausa tarea
                                                        and e.cdestado <> 38));
        if SQL%ROWCOUNT = 0  then
          p_Ok:=0;
          p_error:='Imposible Eliminar Detalle de Tareas Asignadas. Comuniquese con Sistemas!';
          rollback;
          return;
        end if;

      delete tblslvtarea ta
       where ta.idpersonaarmador = p_IdArmador
         and ta.idtarea in (select e.cdestado
                              from tblslvestado e
                             where e.dsestado like '%Asignado%'
                              --pausa tarea
                               and e.cdestado <> 38);
        if SQL%ROWCOUNT = 0  then
          p_Ok:=0;
          p_error:='Imposible Eliminar Tareas Asignadas. Comuniquese con Sistemas!';
          rollback;
          return;
        end if;
     end if;   --fin if tareas asignadas

  --recorre las tareas en curso para finalizar picking del detalle tarea
   for curso in
      (select det.idtarea,det.cdarticulo
         from tblslvtarea ta,
              tblslvtareadet det
        where ta.idtarea = det.idtarea
          and ta.idpersonaarmador = p_IdArmador
           -- tareas disponibles en curso
          and ta.cdestado in (select e.cdestado
                              from tblslvestado e
                             where e.dsestado like '%En Curso%')
          --renglon no finalizado
          and det.icfinalizado <> 1
          --renglon iniciado en picking
          and det.qtunidadmedidabasepicking is not null)
   loop
     v_tarea:=SetFindetalleTarea(curso.idtarea,curso.cdarticulo);
     if(v_tarea <> 0) then
         p_Ok:=0;
         p_error:='Imposible Finalizar Tarea: '||'curso.idtarea'||'Articulo: '||curso.cdarticulo||' Comuniquese con Sistemas!';
         rollback;
         return;
     end if;
   end loop;

    --elimina todo el detalle de tarea en curso del armador que no se han pikiado
    delete tblslvtareadet det
         where det.idtarea in(select ta.idtarea
                                from tblslvtarea ta
                               where ta.idpersonaarmador = p_IdArmador
                                  -- tareas disponibles en curso
                                 and ta.cdestado in (select e.cdestado
                                                       from tblslvestado e
                                                      where e.dsestado like '%En Curso%'))
          --renglon no finalizado
          and det.icfinalizado <> 1
          --renglon no iniciado el picking
          and det.qtunidadmedidabasepicking is null;

    -- finaliza las tareas en curso de un armador
    for curso in
      (select ta.idtarea
         from tblslvtarea ta
        where ta.idpersonaarmador = p_IdArmador
           -- tareas disponibles en curso
          and ta.cdestado in (select e.cdestado
                              from tblslvestado e
                             where e.dsestado like '%En Curso%'))
   loop
     v_tarea:=SetFinalizarTarea(p_IdArmador ,curso.idtarea);
     if(v_tarea <> 0) then
         p_Ok:=0;
         p_error:='Imposible Finalizar Tarea: '||'curso.idtarea'||' Comuniquese con Sistemas!';
         rollback;
         return;
     end if;

     -- validar si la tarea genera remito
     select tp.icgeneraremito
       into v_icgeneraremito
       from tblslvtarea ta,
            tblslvtipotarea tp
      where ta.cdtipo = tp.cdtipo
        and ta.idtarea = curso.idtarea
        and ta.idpersonaarmador = p_IdArmador
        and rownum = 1;
     --si genera remito lo finaliza
     if v_icgeneraremito = 1 then
       select re.idremito
         into v_idremito
         from tblslvremito re
        where re.idtarea = curso.idtarea
          and rownum = 1;
        if SetFinalizarRemito(v_idremito)=0 then
           p_Ok:=0;
           p_error:='No es posible Actualizar Remito: '||v_idremito||'Comuniquese con Sistemas!';
           rollback;
           return;
        end if;
     end if;

   end loop;
    commit;
     p_Ok:=1;
    EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       '  Error: ' || SQLERRM);
  END SetLiberarArmador;

end PKG_SLV_TAREAS;
/
