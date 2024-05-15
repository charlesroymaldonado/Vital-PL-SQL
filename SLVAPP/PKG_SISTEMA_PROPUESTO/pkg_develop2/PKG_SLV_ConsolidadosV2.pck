create or replace package PKG_SLV_Consolidados is
  /**********************************************************************************************************
  * Author  : CMALDONADO_C
  * Created : 20/01/2020 05:05:03 p.m.
  * %v Paquete para la consolidación de pedidos en SLV
  **********************************************************************************************************/
  -- Tipos de datos

  TYPE CURSOR_TYPE IS REF CURSOR;

  TYPE arr_IdentidadComi IS TABLE OF CHAR(40) INDEX BY PLS_INTEGER;

  TYPE arr_TransIdZona IS TABLE OF CHAR(50) INDEX BY PLS_INTEGER;

  TYPE arr_TransId IS TABLE OF CHAR(50) INDEX BY PLS_INTEGER;

  --Procedimientos y Funciones
  
  PROCEDURE GetConsolidado (p_DtDesde        IN DATE,
                             p_DtHasta        IN DATE,
                             p_TipoTarea      IN  tblslvtipotarea.cdtipo%type,
                             p_Cursor         OUT CURSOR_TYPE);
                             
  PROCEDURE GetArtPanelConsolidado (p_idConsolidado  IN  Tblslvconsolidadom.Idconsolidadom%type,
                                          p_TipoTarea     IN  tblslvtipotarea.cdtipo%type,                  
                                          p_Cursor        OUT CURSOR_TYPE);  
  
  PROCEDURE GetArtFaltaConsolidado (p_idConsolidado   IN  Tblslvconsolidadom.Idconsolidadom%type,
                                    p_TipoTarea       IN  tblslvtipotarea.cdtipo%type,                                     
                                    p_Cursor          OUT CURSOR_TYPE);                                          
  --para uso interno del paquete                                                                                                                        
                                     
  FUNCTION SinAsigConsolidadoM(p_idconsolidadom   tblslvconsolidadom.idconsolidadom%type)
                           return integer;                                    
  FUNCTION SinAsigConsolidadoMFaltante(p_idconsolidadom   tblslvconsolidadom.idconsolidadom%type)
                           return integer;   
  FUNCTION ConsolidadoMFaltante(p_idconsolidadom   tblslvconsolidadom.idconsolidadom%type)
                           return integer;
  FUNCTION SinAsigConsolidadoPedido(p_idconsolidadopedido   tblslvconsolidadopedido.idconsolidadopedido%type)
                           return integer;                                 
  FUNCTION ConsolidadoPedidoFaltante(p_idconsolidadopedido   tblslvconsolidadopedido.idconsolidadopedido%type)
                           return integer; 
  FUNCTION SinAsigpedfaltante(p_idpedfaltante   tblslvpedfaltante.idpedfaltante%type)
                           return integer;
  FUNCTION PedFaltante(p_idpedfaltante   tblslvpedfaltante.idpedfaltante%type)
                           return integer;
  FUNCTION SinAsigConsolidadoComi(p_idconsolidadoComi   tblslvconsolidadocomi.idconsolidadocomi%type)
                           return integer;
  FUNCTION SinAsigConsolidadoComiFaltante(p_idconsolidadoComi   tblslvconsolidadocomi.idconsolidadocomi%type)
                           return integer;
  FUNCTION ConsolidadoComiFaltante(p_idconsolidadoComi   tblslvconsolidadocomi.idconsolidadocomi%type)
                           return integer;                                                                                                                                                            
end PKG_SLV_Consolidados;
/
create or replace package body PKG_SLV_Consolidados is
  /***************************************************************************************************
  *  %v 21/01/2020  ChM - Parametros globales privados
  ****************************************************************************************************/
  g_cdSucursal      sucursales.cdsucursal%type := trim(getvlparametro('CDSucursal',
                                                                      'General'));

  c_TareaConsolidadoMulti            CONSTANT tblslvtipotarea.cdtipo%type := 1; 
  c_TareaConsolidaMultiFaltante      CONSTANT tblslvtipotarea.cdtipo%type := 2; 
  c_TareaConsolidadoPedido           CONSTANT tblslvtipotarea.cdtipo%type := 3; 
  c_TareaConsolidaPedidoFaltante     CONSTANT tblslvtipotarea.cdtipo%type := 4; 
  c_TareaConsolidadoComi             CONSTANT tblslvtipotarea.cdtipo%type := 5; 
  c_TareaConsolidadoComiFaltante     CONSTANT tblslvtipotarea.cdtipo%type := 6;
  
  /**************************************************************************************************
  * %v 09/03/2020 - ChM  Obtener Consolidado Multicanal por fechas
  * %v 09/03/2020 - ChM. Versión Inicial
  ***************************************************************************************************/

  PROCEDURE GetConsolidadoMC(p_DtDesde        IN DATE,
                             p_DtHasta        IN DATE,
                             p_Cursor         OUT CURSOR_TYPE) IS
  
    v_modulo  varchar2(100) := 'PKG_SLV_Consolidados.GetConsolidadoMC';
    v_dtHasta date;
    v_dtDesde date;
  
  BEGIN
    v_dtDesde := to_date(to_char(p_DtDesde, 'dd/mm/yyyy') || ' 23:59:59',
                         'dd/mm/yyyy hh24:mi:ss');
    v_dtHasta := to_date(to_char(p_DtHasta, 'dd/mm/yyyy') || ' 23:59:59',
                         'dd/mm/yyyy hh24:mi:ss');
                 
     OPEN p_Cursor FOR 
             Select m.idconsolidadom, 
                    to_char(m.dtinsert,'dd/mm/yyyy') fecha,
                    est.dsestado,
                    PKG_SLV_Consolidados.SinAsigConsolidadoM(m.idconsolidadom) articulosSinAsignar,
                    PKG_SLV_Consolidados.ConsolidadoMFaltante(m.idconsolidadom) tieneFaltante,
                    PKG_SLV_Consolidados.SinAsigConsolidadoMFaltante(m.idconsolidadom) tieneFaltanteSinAsignar
               from tblslvconsolidadom m,
                    tblslvestado est            
              where est.cdestado = m.cdestado                 
                and m.dtinsert between v_dtDesde and v_dtHasta
           order by m.idconsolidadom;                     
             
   EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       '  Error: ' || SQLERRM);
  END GetConsolidadoMC;
  
  /**************************************************************************************************
  * %v 09/04/2020 - ChM  Obtener Consolidado Pedidos por fechas
  * %v 09/04/2020 - ChM. Versión Inicial
  ***************************************************************************************************/

  PROCEDURE GetConsolidadoPedido(p_DtDesde        IN DATE,
                                 p_DtHasta        IN DATE,
                                 p_Cursor         OUT CURSOR_TYPE) IS
  
    v_modulo  varchar2(100) := 'PKG_SLV_Consolidados.GetConsolidadoPedido';
    v_dtHasta date;
    v_dtDesde date;
  
  BEGIN
    v_dtDesde := to_date(to_char(p_DtDesde, 'dd/mm/yyyy') || ' 23:59:59',
                         'dd/mm/yyyy hh24:mi:ss');
    v_dtHasta := to_date(to_char(p_DtHasta, 'dd/mm/yyyy') || ' 23:59:59',
                         'dd/mm/yyyy hh24:mi:ss');
                 
     OPEN p_Cursor FOR 
             Select p.idconsolidadopedido,
                    to_char(p.dtinsert,'dd/mm/yyyy') fecha,
                    est.dsestado,
                    PKG_SLV_Consolidados.SinAsigConsolidadoPedido(p.idconsolidadopedido)  articulosSinAsignar,
                    PKG_SLV_Consolidados.ConsolidadoPedidoFaltante(p.idconsolidadopedido) tieneFaltante
               from tblslvconsolidadopedido p,
                    tblslvestado est            
              where est.cdestado = p.cdestado                 
                and p.dtinsert between v_dtDesde and v_dtHasta
           order by p.idconsolidadopedido;                     
             
   EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       '  Error: ' || SQLERRM);
  END GetConsolidadoPedido;
  
  /**************************************************************************************************
  * %v 09/04/2020 - ChM  Obtener Consolidado Pedidos Faltantes por fechas
  * %v 09/04/2020 - ChM. Versión Inicial
  ***************************************************************************************************/

  PROCEDURE GetConsolidadoPedidoFaltante(p_DtDesde        IN DATE,
                                         p_DtHasta        IN DATE,
                                         p_Cursor         OUT CURSOR_TYPE) IS
  
    v_modulo  varchar2(100) := 'PKG_SLV_Consolidados.GetConsolidadoPedidoFaltante';
    v_dtHasta date;
    v_dtDesde date;
  
  BEGIN
    v_dtDesde := to_date(to_char(p_DtDesde, 'dd/mm/yyyy') || ' 23:59:59',
                         'dd/mm/yyyy hh24:mi:ss');
    v_dtHasta := to_date(to_char(p_DtHasta, 'dd/mm/yyyy') || ' 23:59:59',
                         'dd/mm/yyyy hh24:mi:ss');
                 
     OPEN p_Cursor FOR 
             Select p.idpedfaltante, 
                    to_char(p.dtinsert,'dd/mm/yyyy') fecha,
                    est.dsestado,
                    PKG_SLV_Consolidados.SinAsigPedFaltante(p.idpedfaltante)  articulosSinAsignar,
                    PKG_SLV_Consolidados.PedFaltante(p.idpedfaltante) tieneFaltante
               from tblslvpedfaltante p,
                    tblslvestado est            
              where est.cdestado = p.cdestado                 
                and p.dtinsert between v_dtDesde and v_dtHasta
           order by p.idpedfaltante;                     
             
   EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       '  Error: ' || SQLERRM);
  END  GetConsolidadoPedidoFaltante;
  
  /**************************************************************************************************
  * %v 09/04/2020 - ChM  Obtener Consolidado Comisionista por fechas
  * %v 09/04/2020 - ChM. Versión Inicial
  ***************************************************************************************************/

  PROCEDURE GetConsolidadoComi(p_DtDesde        IN DATE,
                               p_DtHasta        IN DATE,
                               p_Cursor         OUT CURSOR_TYPE) IS
  
    v_modulo  varchar2(100) := 'PKG_SLV_Consolidados.GetConsolidadoComi';
    v_dtHasta date;
    v_dtDesde date;
  
  BEGIN
    v_dtDesde := to_date(to_char(p_DtDesde, 'dd/mm/yyyy') || ' 23:59:59',
                         'dd/mm/yyyy hh24:mi:ss');
    v_dtHasta := to_date(to_char(p_DtHasta, 'dd/mm/yyyy') || ' 23:59:59',
                         'dd/mm/yyyy hh24:mi:ss');
                 
     OPEN p_Cursor FOR 
             Select c.idconsolidadocomi, 
                    to_char(c.dtinsert,'dd/mm/yyyy') fecha,
                    est.dsestado,
                    PKG_SLV_Consolidados.SinAsigConsolidadoComi(c.idconsolidadocomi) articulosSinAsignar,
                    PKG_SLV_Consolidados.ConsolidadoComiFaltante(c.idconsolidadocomi) tieneFaltante,
                    PKG_SLV_Consolidados.SinAsigConsolidadoComiFaltante(c.idconsolidadocomi) tieneFaltanteSinAsignar
               from tblslvconsolidadocomi c,
                    tblslvestado est            
              where est.cdestado = c.cdestado                 
                and c.dtinsert between v_dtDesde and v_dtHasta
           order by c.idconsolidadocomi;                     
             
   EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       '  Error: ' || SQLERRM);
  END GetConsolidadoComi;
  
  /****************************************************************************************************
  * %v 09/04/2020 - ChM  Versión inicial GetConsolidados
  * %v 09/04/2020 - ChM  Obtener Consolidados por fecha
  *****************************************************************************************************/
  PROCEDURE GetConsolidado (p_DtDesde         IN DATE,
                             p_DtHasta        IN DATE,
                             p_TipoTarea      IN  tblslvtipotarea.cdtipo%type,
                             p_Cursor         OUT CURSOR_TYPE) IS
    
  BEGIN
       
     --TipoTarea 1,2 ConsolidadoM y ConsolidadoMFaltante
     if p_TipoTarea in (c_TareaConsolidadoMulti,c_TareaConsolidaMultiFaltante) then
      GetConsolidadoMC(p_DtDesde,p_DtHasta,p_Cursor); 
     end if;  
     --TipoTarea 3 Consolidado pedido
     if p_TipoTarea = c_TareaConsolidadoPedido then
      GetConsolidadoPedido(p_DtDesde,p_DtHasta,p_Cursor); 
     end if; 
     --TipoTarea 4 Faltantes Consolidado pedido
     if p_TipoTarea = c_TareaConsolidaPedidoFaltante then
      GetConsolidadoPedidoFaltante(p_DtDesde,p_DtHasta,p_Cursor); 
     end if;     
    --TipoTarea 5,6 ConsolidadoComi y ConsolidadoComiFaltante
    if p_TipoTarea in (c_TareaConsolidadoComi,c_TareaConsolidadoComiFaltante) then
      GetConsolidadoComi(p_DtDesde,p_DtHasta,p_Cursor);  
    end if; 
    
  END GetConsolidado;   
  
  
  /****************************************************************************************************
  * %v 09/04/2020 - ChM  Versión inicial GetArticulosPanelConsolidadoM
  * %v 09/04/2020 - ChM  lista los articulos que conforman un ConsolidadoM
  *****************************************************************************************************/
  PROCEDURE GetArtPanelConsolidadoM(p_idConsolidadoM  IN  Tblslvconsolidadom.Idconsolidadom%type,
                                    p_Cursor          OUT CURSOR_TYPE) IS
   
   v_modulo varchar2(100) := 'PKG_SLV_Consolidados.GetArtPanelConsolidadoM';
  
    BEGIN             
      OPEN p_Cursor FOR 
            select A.Sector,
                   A.articulo,
                   PKG_SLVArticulos.SetFormatoArticulos(A.uxb,A.base) Cantidad, 
                   PKG_SLVArticulos.SetFormatoArticulos(A.uxb,A.picking) Cantidad_picking,
                   PKG_SLVArticulos.SetFormatoArticulos(A.uxb,A.diferencia) Diferencia,
                   PKG_SLVArticulos.SetFormatoArticulos(A.uxb,A.stock) stock,
                   A.uxb,
                   A.Ubicacion
              from (Select gs.cdgrupo||' - ' ||gs.dsgruposector||' ('||sec.dssector || ')' Sector,
                           art.cdarticulo || '- ' || des.vldescripcion Articulo,
                           art.cdarticulo,
                           det.qtunidadmedidabase base,
                           det.qtunidadmedidabasepicking picking,
                           (det.qtunidadmedidabase-det.qtunidadmedidabasepicking) diferencia,
                           PKG_SLV_Articulos.GetStockArticulos(art.cdarticulo) STOCK,
                           posapp.n_pkg_vitalpos_materiales.GetUxB(art.cdarticulo) UXB,
                           PKG_SLVArticulos.GetUbicacionArticulos(ART.cdarticulo) UBICACION
                      from tblslvconsolidadom m,
                           tblslvconsolidadomdet det,
                           tblslv_grupo_sector gs,
                           sectores sec,
                           descripcionesarticulos des,
                           articulos art
                     where m.idconsolidadom = det.idconsolidadom
                       and det.cdarticulo = art.cdarticulo
                       and det.idgrupo_sector = gs.idgrupo_sector
                       and sec.cdsector = gs.cdsector
                       and art.cdarticulo = des.cdarticulo
                       and gs.cdsucursal = g_cdSucursal
                       and m.idconsolidadom = p_idConsolidadoM) A; 
   
    EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       '  Error: ' || SQLERRM);                           
  END GetArtPanelConsolidadoM; 
  
    /****************************************************************************************************
  * %v 09/04/2020 - ChM  Versión inicial GetArtPanelConsolidaPedido
  * %v 09/04/2020 - ChM  lista los articulos que conforman un ConsolidadoPedido
  *****************************************************************************************************/
  PROCEDURE GetArtPanelConsolidaPedido(p_idConsolidadoPedido  IN  Tblslvconsolidadopedido.Idconsolidadopedido%type,
                                       p_Cursor               OUT CURSOR_TYPE) IS
   
   v_modulo varchar2(100) := 'PKG_SLV_Consolidados.GetArtPanelConsolidaPedido';
  
    BEGIN             
      OPEN p_Cursor FOR 
            select A.Sector,
                   A.articulo,
                   PKG_SLVArticulos.SetFormatoArticulos(A.uxb,A.base) Cantidad, 
                   PKG_SLVArticulos.SetFormatoArticulos(A.uxb,A.picking) Cantidad_picking,
                   PKG_SLVArticulos.SetFormatoArticulos(A.uxb,A.diferencia) Diferencia,
                   PKG_SLVArticulos.SetFormatoArticulos(A.uxb,A.stock) stock,
                   A.uxb,
                   A.Ubicacion
              from (Select gs.cdgrupo||' - ' ||gs.dsgruposector||' ('||sec.dssector || ')' Sector,
                           art.cdarticulo || '- ' || des.vldescripcion Articulo,
                           art.cdarticulo,
                           det.qtunidadesmedidabase base,
                           det.qtunidadmedidabasepicking picking,
                           (det.qtunidadesmedidabase-det.qtunidadmedidabasepicking) diferencia,
                           PKG_SLV_Articulos.GetStockArticulos(art.cdarticulo) STOCK,
                           posapp.n_pkg_vitalpos_materiales.GetUxB(art.cdarticulo) UXB,
                           PKG_SLVArticulos.GetUbicacionArticulos(ART.cdarticulo) UBICACION
                      from tblslvconsolidadopedido p,
                           tblslvconsolidadopedidodet det,
                           tblslv_grupo_sector gs,
                           sectores sec,
                           descripcionesarticulos des,
                           articulos art
                     where p.idconsolidadopedido = det.idconsolidadopedido
                       and det.cdarticulo = art.cdarticulo
                       and det.idgrupo_sector = gs.idgrupo_sector
                       and sec.cdsector = gs.cdsector
                       and art.cdarticulo = des.cdarticulo                       
                       and gs.cdsucursal = g_cdSucursal
                       and p.idconsolidadopedido = p_idConsolidadoPedido) A; 
   
    EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       '  Error: ' || SQLERRM);                           
  END GetArtPanelConsolidaPedido; 
  
  /****************************************************************************************************
  * %v 09/04/2020 - ChM  Versión inicial GetArtPanelPedFaltante
  * %v 09/04/2020 - ChM  lista los articulos que conforman un Consolidado pedido Faltante
  *****************************************************************************************************/
  PROCEDURE GetArtPanelPedFaltante (p_idPedFaltante   IN  Tblslvpedfaltante.Idpedfaltante%type,
                                    p_Cursor          OUT CURSOR_TYPE) IS
   
   v_modulo varchar2(100) := 'PKG_SLV_Consolidados.GetArtPanelPedFaltante';
  
    BEGIN             
      OPEN p_Cursor FOR 
            select A.Sector,
                   A.articulo,
                   PKG_SLVArticulos.SetFormatoArticulos(A.uxb,A.base) Cantidad, 
                   PKG_SLVArticulos.SetFormatoArticulos(A.uxb,A.picking) Cantidad_picking,
                   PKG_SLVArticulos.SetFormatoArticulos(A.uxb,A.diferencia) Diferencia,
                   PKG_SLVArticulos.SetFormatoArticulos(A.uxb,A.stock) stock,
                   A.uxb,
                   A.Ubicacion
              from (Select gs.cdgrupo||' - ' ||gs.dsgruposector||' ('||sec.dssector || ')' Sector,
                           art.cdarticulo || '- ' || des.vldescripcion Articulo,
                           art.cdarticulo,
                           det.qtunidadmedidabase base,
                           det.qtunidadmedidabasepicking picking,
                           (det.qtunidadmedidabase-det.qtunidadmedidabasepicking) diferencia,
                           PKG_SLV_Articulos.GetStockArticulos(art.cdarticulo) STOCK,
                           posapp.n_pkg_vitalpos_materiales.GetUxB(art.cdarticulo) UXB,
                           PKG_SLVArticulos.GetUbicacionArticulos(ART.cdarticulo) UBICACION
                      from tblslvpedfaltante pf,
                           tblslvpedfaltantedet det,
                           tblslv_grupo_sector gs,
                           sectores sec,
                           descripcionesarticulos des,
                           articulos art
                     where pf.idpedfaltante = det.idpedfaltante
                       and det.cdarticulo = art.cdarticulo
                       and det.idgrupo_sector = gs.idgrupo_sector
                       and sec.cdsector = gs.cdsector
                       and art.cdarticulo = des.cdarticulo                       
                       and gs.cdsucursal = g_cdSucursal
                       and pf.idpedfaltante = p_idPedFaltante) A; 
   
    EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       '  Error: ' || SQLERRM);                           
  END GetArtPanelPedFaltante;  
  
  /****************************************************************************************************
  * %v 09/04/2020 - ChM  Versión inicial GetArtPanelConsolidadoComi
  * %v 09/04/2020 - ChM  lista los articulos que conforman un Consolidado Comisionista
  *****************************************************************************************************/
  PROCEDURE GetArtPanelConsolidadoComi(p_idConsolidadoComi  IN  Tblslvconsolidadocomi.Idconsolidadocomi%type,
                                       p_Cursor             OUT CURSOR_TYPE) IS
   
   v_modulo varchar2(100) := 'PKG_SLV_Consolidados.GetArtPanelConsolidadoComi';
  
    BEGIN             
      OPEN p_Cursor FOR 
            select A.Sector,
                   A.articulo,
                   PKG_SLVArticulos.SetFormatoArticulos(A.uxb,A.base) Cantidad, 
                   PKG_SLVArticulos.SetFormatoArticulos(A.uxb,A.picking) Cantidad_picking,
                   PKG_SLVArticulos.SetFormatoArticulos(A.uxb,A.diferencia) Diferencia,
                   PKG_SLVArticulos.SetFormatoArticulos(A.uxb,A.stock) stock,
                   A.uxb,
                   A.Ubicacion
              from (Select gs.cdgrupo||' - ' ||gs.dsgruposector||' ('||sec.dssector || ')' Sector,
                           art.cdarticulo || '- ' || des.vldescripcion Articulo,
                           art.cdarticulo,
                           det.qtunidadmedidabase base,
                           det.qtunidadmedidabasepicking picking,
                           (det.qtunidadmedidabase-det.qtunidadmedidabasepicking) diferencia,
                           PKG_SLV_Articulos.GetStockArticulos(art.cdarticulo) STOCK,
                           posapp.n_pkg_vitalpos_materiales.GetUxB(art.cdarticulo) UXB,
                           PKG_SLVArticulos.GetUbicacionArticulos(ART.cdarticulo) UBICACION
                      from tblslvconsolidadocomi cm,
                           tblslvconsolidadocomidet det,
                           tblslv_grupo_sector gs,
                           sectores sec,
                           descripcionesarticulos des,
                           articulos art
                     where cm.idconsolidadocomi = det.idconsolidadocomi
                       and det.cdarticulo = art.cdarticulo
                       and det.idgrupo_sector = gs.idgrupo_sector
                       and sec.cdsector = gs.cdsector
                       and art.cdarticulo = des.cdarticulo
                       and gs.cdsucursal = g_cdSucursal
                       and cm.idconsolidadocomi = p_idConsolidadoComi) A; 
   
    EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       '  Error: ' || SQLERRM);                           
  END GetArtPanelConsolidadoComi; 

  /****************************************************************************************************
  * %v 09/04/2020 - ChM  Versión inicial GetArtPanelConsolidado
  * %v 09/04/2020 - ChM  Lista los articulos que componen un idconsolidado panel
  *****************************************************************************************************/
  PROCEDURE GetArtPanelConsolidado (p_idConsolidado   IN  Tblslvconsolidadom.Idconsolidadom%type,
                                    p_TipoTarea       IN  tblslvtipotarea.cdtipo%type,                                     
                                    p_Cursor          OUT CURSOR_TYPE) IS
    
  BEGIN
       
     --TipoTarea 1,2 ConsolidadoM y ConsolidadoMFaltante
     if p_TipoTarea in (c_TareaConsolidadoMulti,c_TareaConsolidaMultiFaltante) then
      GetArtPanelConsolidadoM(p_idConsolidado,p_Cursor); 
     end if;  
     --TipoTarea 3 Consolidado pedido
     if p_TipoTarea = c_TareaConsolidadoPedido then
      GetArtPanelConsolidaPedido(p_idConsolidado,p_Cursor); 
     end if; 
     --TipoTarea 4 Faltantes Consolidado pedido
     if p_TipoTarea = c_TareaConsolidaPedidoFaltante then
      GetArtPanelPedFaltante(p_idConsolidado,p_Cursor); 
     end if;     
    --TipoTarea 5,6 ConsolidadoComi y ConsolidadoComiFaltante
    if p_TipoTarea in (c_TareaConsolidadoComi,c_TareaConsolidadoComiFaltante) then
      GetArtPanelConsolidadoComi(p_idConsolidado,p_Cursor); 
    end if; 
    
  END GetArtPanelConsolidado;  
   
  /****************************************************************************************************
  * %v 13/04/2020 - ChM  Versión inicial GetArticulosFaltaConsolidadoM
  * %v 09/04/2020 - ChM  lista solo los articulos Faltantes que conforman un ConsolidadoM
  *****************************************************************************************************/
  PROCEDURE GetArtFaltaConsolidadoM(p_idConsolidadoM  IN  Tblslvconsolidadom.Idconsolidadom%type,
                                    p_Cursor          OUT CURSOR_TYPE) IS
   
   v_modulo varchar2(100) := 'PKG_SLV_Consolidados.GetArtFaltaConsolidadoM';
  
    BEGIN             
      OPEN p_Cursor FOR 
            select A.Sector,
                   A.articulo,
                   PKG_SLVArticulos.SetFormatoArticulos(A.uxb,A.base) Cantidad, 
                   PKG_SLVArticulos.SetFormatoArticulos(A.uxb,A.picking) Cantidad_picking,
                   PKG_SLVArticulos.SetFormatoArticulos(A.uxb,A.diferencia) Diferencia,
                   PKG_SLVArticulos.SetFormatoArticulos(A.uxb,A.stock) stock,
                   A.uxb,
                   A.Ubicacion
              from (Select gs.cdgrupo||' - ' ||gs.dsgruposector||' ('||sec.dssector || ')' Sector,
                           art.cdarticulo || '- ' || des.vldescripcion Articulo,
                           art.cdarticulo,
                           det.qtunidadmedidabase base,
                           det.qtunidadmedidabasepicking picking,
                           (det.qtunidadmedidabase-det.qtunidadmedidabasepicking) diferencia,
                           PKG_SLV_Articulos.GetStockArticulos(art.cdarticulo) STOCK,
                           posapp.n_pkg_vitalpos_materiales.GetUxB(art.cdarticulo) UXB,
                           PKG_SLVArticulos.GetUbicacionArticulos(ART.cdarticulo) UBICACION
                      from tblslvconsolidadom m,
                           tblslvconsolidadomdet det,
                           tblslv_grupo_sector gs,
                           sectores sec,
                           descripcionesarticulos des,
                           articulos art
                     where m.idconsolidadom = det.idconsolidadom
                       and det.cdarticulo = art.cdarticulo
                       and det.idgrupo_sector = gs.idgrupo_sector
                       and sec.cdsector = gs.cdsector
                       and art.cdarticulo = des.cdarticulo
                       --valida mostrar solo los que tienen diferencia
                       and(det.qtunidadmedidabase-nvl(det.qtunidadmedidabasepicking,0))<>0
                       and gs.cdsucursal = g_cdSucursal
                       and m.idconsolidadom = p_idConsolidadoM) A; 
   
    EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       '  Error: ' || SQLERRM);                           
  END GetArtFaltaConsolidadoM; 
  
  /****************************************************************************************************
  * %v 13/04/2020 - ChM  Versión inicial GetArtFaltaConsolidaPedido
  * %v 13/04/2020 - ChM  lista solo los articulos faltantes que conforman un ConsolidadoPedido
  *****************************************************************************************************/
  PROCEDURE GetArtFaltaConsolidaPedido(p_idConsolidadoPedido  IN  Tblslvconsolidadopedido.Idconsolidadopedido%type,
                                       p_Cursor               OUT CURSOR_TYPE) IS
   
   v_modulo varchar2(100) := 'PKG_SLV_Consolidados.GetArtFaltaConsolidaPedido';
  
    BEGIN             
      OPEN p_Cursor FOR 
            select A.Sector,
                   A.articulo,
                   PKG_SLVArticulos.SetFormatoArticulos(A.uxb,A.base) Cantidad, 
                   PKG_SLVArticulos.SetFormatoArticulos(A.uxb,A.picking) Cantidad_picking,
                   PKG_SLVArticulos.SetFormatoArticulos(A.uxb,A.diferencia) Diferencia,
                   PKG_SLVArticulos.SetFormatoArticulos(A.uxb,A.stock) stock,
                   A.uxb,
                   A.Ubicacion
              from (Select gs.cdgrupo||' - ' ||gs.dsgruposector||' ('||sec.dssector || ')' Sector,
                           art.cdarticulo || '- ' || des.vldescripcion Articulo,
                           art.cdarticulo,
                           det.qtunidadesmedidabase base,
                           det.qtunidadmedidabasepicking picking,
                           (det.qtunidadesmedidabase-det.qtunidadmedidabasepicking) diferencia,
                           PKG_SLV_Articulos.GetStockArticulos(art.cdarticulo) STOCK,
                           posapp.n_pkg_vitalpos_materiales.GetUxB(art.cdarticulo) UXB,
                           PKG_SLVArticulos.GetUbicacionArticulos(ART.cdarticulo) UBICACION
                      from tblslvconsolidadopedido p,
                           tblslvconsolidadopedidodet det,
                           tblslv_grupo_sector gs,
                           sectores sec,
                           descripcionesarticulos des,
                           articulos art
                     where p.idconsolidadopedido = det.idconsolidadopedido
                       and det.cdarticulo = art.cdarticulo
                       and det.idgrupo_sector = gs.idgrupo_sector
                       and sec.cdsector = gs.cdsector
                       and art.cdarticulo = des.cdarticulo                       
                       and gs.cdsucursal = g_cdSucursal
                       and p.idconsolidadopedido = p_idConsolidadoPedido
                       --valida mostrar solo los que tienen diferencia
                       and (det.qtunidadesmedidabase-nvl(det.qtunidadmedidabasepicking,0)<>0)) A; 
   
    EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       '  Error: ' || SQLERRM);                           
  END GetArtFaltaConsolidaPedido; 
  
  /****************************************************************************************************
  * %v 13/04/2020 - ChM  Versión inicial GetArtFaltaPedFaltante
  * %v 13/04/2020 - ChM  lista solo los articulos Faltantes que conforman un Consolidado pedido Faltante
  *****************************************************************************************************/
  PROCEDURE GetArtFaltaPedFaltante (p_idPedFaltante   IN  Tblslvpedfaltante.Idpedfaltante%type,
                                    p_Cursor          OUT CURSOR_TYPE) IS
   
   v_modulo varchar2(100) := 'PKG_SLV_Consolidados.GetArtFaltaPedFaltante';
  
    BEGIN             
      OPEN p_Cursor FOR 
            select A.Sector,
                   A.articulo,
                   PKG_SLVArticulos.SetFormatoArticulos(A.uxb,A.base) Cantidad, 
                   PKG_SLVArticulos.SetFormatoArticulos(A.uxb,A.picking) Cantidad_picking,
                   PKG_SLVArticulos.SetFormatoArticulos(A.uxb,A.diferencia) Diferencia,
                   PKG_SLVArticulos.SetFormatoArticulos(A.uxb,A.stock) stock,
                   A.uxb,
                   A.Ubicacion
              from (Select gs.cdgrupo||' - ' ||gs.dsgruposector||' ('||sec.dssector || ')' Sector,
                           art.cdarticulo || '- ' || des.vldescripcion Articulo,
                           art.cdarticulo,
                           det.qtunidadmedidabase base,
                           det.qtunidadmedidabasepicking picking,
                           (det.qtunidadmedidabase-det.qtunidadmedidabasepicking) diferencia,
                           PKG_SLV_Articulos.GetStockArticulos(art.cdarticulo) STOCK,
                           posapp.n_pkg_vitalpos_materiales.GetUxB(art.cdarticulo) UXB,
                           PKG_SLVArticulos.GetUbicacionArticulos(ART.cdarticulo) UBICACION
                      from tblslvpedfaltante pf,
                           tblslvpedfaltantedet det,
                           tblslv_grupo_sector gs,
                           sectores sec,
                           descripcionesarticulos des,
                           articulos art
                     where pf.idpedfaltante = det.idpedfaltante
                       and det.cdarticulo = art.cdarticulo
                       and det.idgrupo_sector = gs.idgrupo_sector
                       and sec.cdsector = gs.cdsector
                       and art.cdarticulo = des.cdarticulo                       
                       and gs.cdsucursal = g_cdSucursal
                       and pf.idpedfaltante = p_idPedFaltante
                       --valida mostrar solo los que tienen diferencia
                       and (det.qtunidadmedidabase-nvl(det.qtunidadmedidabasepicking,0)<>0)) A; 
   
    EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       '  Error: ' || SQLERRM);                           
  END GetArtFaltaPedFaltante;  
  
  /****************************************************************************************************
  * %v 13/04/2020 - ChM  Versión inicial GetArtFaltaConsolidadoComi
  * %v 13/04/2020 - ChM  lista solo los articulos Faltantes que conforman un Consolidado Comisionista
  *****************************************************************************************************/
  PROCEDURE GetArtFaltaConsolidadoComi(p_idConsolidadoComi  IN  Tblslvconsolidadocomi.Idconsolidadocomi%type,
                                       p_Cursor             OUT CURSOR_TYPE) IS
   
   v_modulo varchar2(100) := 'PKG_SLV_Consolidados.GetArtFaltaConsolidadoComi';
  
    BEGIN             
      OPEN p_Cursor FOR 
            select A.Sector,
                   A.articulo,
                   PKG_SLVArticulos.SetFormatoArticulos(A.uxb,A.base) Cantidad, 
                   PKG_SLVArticulos.SetFormatoArticulos(A.uxb,A.picking) Cantidad_picking,
                   PKG_SLVArticulos.SetFormatoArticulos(A.uxb,A.diferencia) Diferencia,
                   PKG_SLVArticulos.SetFormatoArticulos(A.uxb,A.stock) stock,
                   A.uxb,
                   A.Ubicacion
              from (Select gs.cdgrupo||' - ' ||gs.dsgruposector||' ('||sec.dssector || ')' Sector,
                           art.cdarticulo || '- ' || des.vldescripcion Articulo,
                           art.cdarticulo,
                           det.qtunidadmedidabase base,
                           det.qtunidadmedidabasepicking picking,
                           (det.qtunidadmedidabase-det.qtunidadmedidabasepicking) diferencia,
                           PKG_SLV_Articulos.GetStockArticulos(art.cdarticulo) STOCK,
                           posapp.n_pkg_vitalpos_materiales.GetUxB(art.cdarticulo) UXB,
                           PKG_SLVArticulos.GetUbicacionArticulos(ART.cdarticulo) UBICACION
                      from tblslvconsolidadocomi cm,
                           tblslvconsolidadocomidet det,
                           tblslv_grupo_sector gs,
                           sectores sec,
                           descripcionesarticulos des,
                           articulos art
                     where cm.idconsolidadocomi = det.idconsolidadocomi
                       and det.cdarticulo = art.cdarticulo
                       and det.idgrupo_sector = gs.idgrupo_sector
                       and sec.cdsector = gs.cdsector
                       and art.cdarticulo = des.cdarticulo
                       --valida mostrar solo los que tienen diferencia
                       and (det.qtunidadmedidabase-nvl(det.qtunidadmedidabasepicking,0))<>0
                       and gs.cdsucursal = g_cdSucursal
                       and cm.idconsolidadocomi = p_idConsolidadoComi) A; 
   
    EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       '  Error: ' || SQLERRM);                           
  END GetArtFaltaConsolidadoComi; 

  /****************************************************************************************************
  * %v 13/04/2020 - ChM  Versión inicial GetArtFaltaConsolidado
  * %v 13/04/2020 - ChM  Lista solo los articulos faltantes que componen un idconsolidado panel
  *****************************************************************************************************/
  PROCEDURE GetArtFaltaConsolidado (p_idConsolidado   IN  Tblslvconsolidadom.Idconsolidadom%type,
                                    p_TipoTarea       IN  tblslvtipotarea.cdtipo%type,                                     
                                    p_Cursor          OUT CURSOR_TYPE) IS
    
  BEGIN
       
     --TipoTarea 1,2 ConsolidadoM y ConsolidadoMFaltante
     if p_TipoTarea in (c_TareaConsolidadoMulti,c_TareaConsolidaMultiFaltante) then
      GetArtFaltaConsolidadoM(p_idConsolidado,p_Cursor); 
     end if;  
     --TipoTarea 3 Consolidado pedido
     if p_TipoTarea = c_TareaConsolidadoPedido then
      GetArtFaltaConsolidaPedido(p_idConsolidado,p_Cursor); 
     end if; 
     --TipoTarea 4 Faltantes Consolidado pedido
     if p_TipoTarea = c_TareaConsolidaPedidoFaltante then
      GetArtFaltaPedFaltante(p_idConsolidado,p_Cursor); 
     end if;     
    --TipoTarea 5,6 ConsolidadoComi y ConsolidadoComiFaltante
    if p_TipoTarea in (c_TareaConsolidadoComi,c_TareaConsolidadoComiFaltante) then
      GetArtFaltaConsolidadoComi(p_idConsolidado,p_Cursor); 
    end if; 
    
  END GetArtFaltaConsolidado;  

  /**************************************************************************************************
  * %v 10/03/2020 - ChM  devuelve 1 si existen articulos sin asignar en ConsolidadoM
  * %v 10/03/2020 - ChM. Versión Inicial
  ***************************************************************************************************/
  FUNCTION SinAsigConsolidadoM(p_idconsolidadom   tblslvconsolidadom.idconsolidadom%type)
                           return integer is
      v_modulo  varchar2(100) := 'PKG_SLV_Consolidados.SinAsigConsolidadoM';                    
      v_cont     integer;                     
  BEGIN  
        Select count(m.idconsolidadom) 
          into v_cont    
               from tblslvconsolidadom m,
                    tblslvconsolidadomdet det             
              where m.idconsolidadom = det.idconsolidadom
                and m.idconsolidadom = p_idconsolidadom 
                --valida no listar consolidadoM ya asignados totalmente al armador
                and det.cdarticulo not in(select td.cdarticulo  
                                            from tblslvtarea ta, 
                                                 tblslvtareadet td
                                           where ta.idtarea=td.idtarea
                                             and ta.idconsolidadom=m.idconsolidadom
                                             and ta.idpersona= m.idpersona
                                             and ta.cdtipo=c_TareaConsolidadoMulti);
      if v_cont <> 0 then
         return 1;
      end if;
         return 0;  
    EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       '  Error: ' || SQLERRM);                                           
      return 0;                                 
    END SinAsigConsolidadoM;
   /**************************************************************************************************
  * %v 10/03/2020 - ChM  devuelve 1 si existen articulos sin asignar en ConsolidadoM Faltantes tipo 2 de la tarea
  * %v 10/03/2020 - ChM. Versión Inicial
  ***************************************************************************************************/
  FUNCTION SinAsigConsolidadoMFaltante(p_idconsolidadom   tblslvconsolidadom.idconsolidadom%type)
                           return integer is
      v_modulo  varchar2(100) := 'PKG_SLV_Consolidados.SinAsigConsolidadoMFaltante';                    
      v_cont     integer;                     
  BEGIN  
        Select count(m.idconsolidadom) 
          into v_cont    
               from tblslvconsolidadom m,
                    tblslvconsolidadomdet det             
              where m.idconsolidadom = det.idconsolidadom
                and m.idconsolidadom = p_idconsolidadom 
                --valida que no existan articulos sin picking
                and det.qtunidadmedidabasepicking is not null
                --valida que exista diferencia entre picking y unidad base, estos son los faltantes
                and abs(nvl(det.qtunidadmedidabase,0)-nvl(det.qtunidadmedidabasepicking,0))<>0
                --valida no listar consolidadoM Faltantes ya asignados totalmente al armador
                and det.cdarticulo not in(select td.cdarticulo  
                                            from tblslvtarea ta, 
                                                 tblslvtareadet td
                                           where ta.idtarea=td.idtarea
                                             and ta.idconsolidadom=m.idconsolidadom
                                             and ta.idpersona= m.idpersona
                                             and ta.cdtipo=c_TareaConsolidaMultiFaltante);
      if v_cont <> 0 then
         return 1;
      end if;
         return 0;  
    EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       '  Error: ' || SQLERRM);                                           
      return 0;                                 
    END SinAsigConsolidadoMFaltante;  
    
    /**************************************************************************************************
  * %v 10/03/2020 - ChM  devuelve 1 si existen articulos con Faltantes en ConsolidadoM
  * %v 10/03/2020 - ChM. Versión Inicial
  ***************************************************************************************************/
  FUNCTION ConsolidadoMFaltante(p_idconsolidadom   tblslvconsolidadom.idconsolidadom%type)
                           return integer is
      v_modulo  varchar2(100) := 'PKG_SLV_Consolidados.ConsolidadoMFaltante';                    
      v_cont     integer;                     
  BEGIN  
        Select count(m.idconsolidadom) 
          into v_cont    
               from tblslvconsolidadom m,
                    tblslvconsolidadomdet det             
              where m.idconsolidadom = det.idconsolidadom
                and m.idconsolidadom = p_idconsolidadom 
                --valida no contar articulos sin picking
                and det.qtunidadmedidabasepicking is not null
                --valida que exista diferencia entre picking y unidad base, estos son los faltantes
                and abs(nvl(det.qtunidadmedidabase,0)-nvl(det.qtunidadmedidabasepicking,0))<>0;
      if v_cont <> 0 then
         return 1;
      end if;
         return 0;  
    EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       '  Error: ' || SQLERRM);                                           
      return 0;                                 
    END ConsolidadoMFaltante;  
 
    /**************************************************************************************************
  * %v 09/04/2020 - ChM  devuelve 1 si existen articulos sin asignar en ConsolidadoPedido
  * %v 09/04/2020 - ChM. Versión Inicial
  ***************************************************************************************************/
  FUNCTION SinAsigConsolidadoPedido(p_idconsolidadopedido   tblslvconsolidadopedido.idconsolidadopedido%type)
                           return integer is
      v_modulo  varchar2(100) := 'PKG_SLV_Consolidados.SinAsigConsolidadoPedido';                    
      v_cont     integer;                     
  BEGIN  
        Select count(p.idconsolidadopedido) 
          into v_cont    
               from tblslvconsolidadopedido p,
                    tblslvconsolidadopedidodet det             
              where p.idconsolidadopedido = det.idconsolidadopedido
                and p.idconsolidadopedido = p_idconsolidadopedido 
                --valida no listar consolidadoPedido ya asignados totalmente al armador
                and det.cdarticulo not in(select td.cdarticulo  
                                            from tblslvtarea ta, 
                                                 tblslvtareadet td
                                           where ta.idtarea=td.idtarea
                                             and ta.idconsolidadopedido=p.idconsolidadopedido
                                             and ta.idpersona= p.idpersona
                                             and ta.cdtipo=c_TareaConsolidadoPedido);
      if v_cont <> 0 then
         return 1;
      end if;
         return 0;  
    EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       '  Error: ' || SQLERRM);                                           
      return 0;                                 
    END SinAsigConsolidadoPedido;
  
    /**************************************************************************************************
  * %v 09/04/2020 - ChM  devuelve 1 si existen articulos con Faltantes en ConsolidadoPedido
  * %v 09/04/2020 - ChM. Versión Inicial
  ***************************************************************************************************/
  FUNCTION ConsolidadoPedidoFaltante(p_idconsolidadopedido   tblslvconsolidadopedido.idconsolidadopedido%type)
                           return integer is
      v_modulo  varchar2(100) := 'PKG_SLV_Consolidados.ConsolidadoPedidoFaltante';                    
      v_cont     integer;                     
  BEGIN  
        Select count(p.idconsolidadopedido) 
          into v_cont    
               from tblslvconsolidadopedido p,
                    tblslvconsolidadopedidodet det             
              where p.idconsolidadopedido = det.idconsolidadopedido
                and p.idconsolidadopedido = p_idconsolidadopedido
                --valida no contar articulos sin picking
                and det.qtunidadmedidabasepicking is not null
                --valida que exista diferencia entre picking y unidad base, estos son los faltantes
                and abs(nvl(det.qtunidadesmedidabase,0)-nvl(det.qtunidadmedidabasepicking,0))<>0;
      if v_cont <> 0 then
         return 1;
      end if;
         return 0;  
    EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       '  Error: ' || SQLERRM);                                           
      return 0;                                 
    END ConsolidadoPedidoFaltante;  
 
/**************************************************************************************************
  * %v 09/04/2020 - ChM  devuelve 1 si existen articulos sin asignar en PedFaltante
  * %v 09/04/2020 - ChM. Versión Inicial
  ***************************************************************************************************/
  FUNCTION SinAsigpedfaltante(p_idpedfaltante   tblslvpedfaltante.idpedfaltante%type)
                           return integer is
      v_modulo  varchar2(100) := 'PKG_SLV_Consolidados.SinAsigpedfaltante';                    
      v_cont     integer;                     
  BEGIN  
        Select count(pf.idpedfaltante) 
          into v_cont    
               from tblslvpedfaltante pf,
                    tblslvpedfaltantedet det             
              where pf.idpedfaltante = det.idpedfaltante
                and pf.idpedfaltante = p_idpedfaltante 
                --valida no listar pedido Faltante ya asignados totalmente al armador
                and det.cdarticulo not in(select td.cdarticulo  
                                            from tblslvtarea ta, 
                                                 tblslvtareadet td
                                           where ta.idtarea=td.idtarea
                                             and ta.idpedfaltante = pf.idpedfaltante
                                             and ta.idpersona= pf.idpersona
                                             and ta.cdtipo=c_TareaConsolidaPedidoFaltante);
      if v_cont <> 0 then
         return 1;
      end if;
         return 0;  
    EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       '  Error: ' || SQLERRM);                                           
      return 0;                                 
    END SinAsigpedfaltante;
    
    /**************************************************************************************************
  * %v 09/04/2020 - ChM  devuelve 1 si existen articulos con Faltantes en PedFaltante
  * %v 09/04/2020 - ChM. Versión Inicial
  ***************************************************************************************************/
  FUNCTION PedFaltante(p_idpedfaltante   tblslvpedfaltante.idpedfaltante%type)
                           return integer is
      v_modulo  varchar2(100) := 'PKG_SLV_Consolidados.PedFaltante';                    
      v_cont     integer;                     
  BEGIN  
        Select count(pf.idpedfaltante) 
          into v_cont    
               from tblslvpedfaltante pf,
                    tblslvpedfaltantedet det             
              where pf.idpedfaltante = det.idpedfaltante
                and pf.idpedfaltante = p_idpedfaltante 
                --valida no contar articulos sin picking
                and det.qtunidadmedidabasepicking is not null
                --valida que exista diferencia entre picking y unidad base, estos son los faltantes
                and abs(nvl(det.qtunidadmedidabase,0)-nvl(det.qtunidadmedidabasepicking,0))<>0;
      if v_cont <> 0 then
         return 1;
      end if;
         return 0;  
    EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       '  Error: ' || SQLERRM);                                           
      return 0;                                 
    END PedFaltante;  

/**************************************************************************************************
  * %v 09/04/2020 - ChM  devuelve 1 si existen articulos sin asignar en ConsolidadoComi
  * %v 09/04/2020 - ChM. Versión Inicial
  ***************************************************************************************************/
  FUNCTION SinAsigConsolidadoComi(p_idconsolidadoComi   tblslvconsolidadocomi.idconsolidadocomi%type)
                           return integer is
      v_modulo  varchar2(100) := 'PKG_SLV_Consolidados.SinAsigConsolidadoComi';                    
      v_cont     integer;                     
  BEGIN  
        Select count(cm.idconsolidadocomi) 
          into v_cont    
               from tblslvconsolidadocomi cm,
                    tblslvconsolidadocomidet det             
              where cm.idconsolidadocomi = det.idconsolidadocomi
                and cm.idconsolidadocomi = p_idconsolidadoComi
                --valida no listar consolidadoComi ya asignados totalmente al armador
                and det.cdarticulo not in(select td.cdarticulo  
                                            from tblslvtarea ta, 
                                                 tblslvtareadet td
                                           where ta.idtarea=td.idtarea
                                             and ta.idconsolidadocomi = cm.idconsolidadocomi
                                             and ta.idpersona= cm.idpersona
                                             and ta.cdtipo=c_TareaConsolidadoComi);
      if v_cont <> 0 then
         return 1;
      end if;
         return 0;  
    EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       '  Error: ' || SQLERRM);                                           
      return 0;                                 
    END SinAsigConsolidadoComi;
   /**************************************************************************************************
  * %v 09/04/2020 - ChM  devuelve 1 si existen articulos sin asignar en ConsolidadoCOMI Faltantes 
  * %v 09/04/2020 - ChM. Versión Inicial
  ***************************************************************************************************/
  FUNCTION SinAsigConsolidadoComiFaltante(p_idconsolidadoComi   tblslvconsolidadocomi.idconsolidadocomi%type)
                           return integer is
      v_modulo  varchar2(100) := 'PKG_SLV_Consolidados.SinAsigConsolidadoComiFaltante';                    
      v_cont     integer;                     
  BEGIN  
        Select count(cm.idconsolidadocomi) 
          into v_cont    
               from tblslvconsolidadocomi cm,
                    tblslvconsolidadocomidet det             
              where cm.idconsolidadocomi = det.idconsolidadocomi
                and cm.idconsolidadocomi = p_idconsolidadoComi
                --valida que no existan articulos sin picking
                and det.qtunidadmedidabasepicking is not null
                --valida que exista diferencia entre picking y unidad base, estos son los faltantes
                and abs(nvl(det.qtunidadmedidabase,0)-nvl(det.qtunidadmedidabasepicking,0))<>0
                --valida no listar consolidadoComi Faltantes ya asignados totalmente al armador
                and det.cdarticulo not in(select td.cdarticulo  
                                            from tblslvtarea ta, 
                                                 tblslvtareadet td
                                           where ta.idtarea=td.idtarea
                                             and ta.idconsolidadocomi=cm.idconsolidadocomi
                                             and ta.idpersona= cm.idpersona
                                             and ta.cdtipo=c_TareaConsolidadoComiFaltante);
      if v_cont <> 0 then
         return 1;
      end if;
         return 0;  
    EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       '  Error: ' || SQLERRM);                                           
      return 0;                                 
    END SinAsigConsolidadoComiFaltante;  
    
    /**************************************************************************************************
  * %v 09/04/2020 - ChM  devuelve 1 si existen articulos con Faltantes en ConsolidadoComi
  * %v 09/04/2020 - ChM. Versión Inicial
  ***************************************************************************************************/
  FUNCTION ConsolidadoComiFaltante(p_idconsolidadoComi   tblslvconsolidadocomi.idconsolidadocomi%type)
                           return integer is
      v_modulo  varchar2(100) := 'PKG_SLV_Consolidados.ConsolidadoComiFaltante';                    
      v_cont     integer;                     
  BEGIN  
        Select count(cm.idconsolidadocomi) 
          into v_cont    
               from tblslvconsolidadocomi cm,
                    tblslvconsolidadocomidet det             
              where cm.idconsolidadocomi = det.idconsolidadocomi
                and cm.idconsolidadocomi = p_idconsolidadoComi
                --valida no contar articulos sin picking
                and det.qtunidadmedidabasepicking is not null
                --valida que exista diferencia entre picking y unidad base, estos son los faltantes
                and abs(nvl(det.qtunidadmedidabase,0)-nvl(det.qtunidadmedidabasepicking,0))<>0;
      if v_cont <> 0 then
         return 1;
      end if;
         return 0;  
    EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       '  Error: ' || SQLERRM);                                           
      return 0;                                 
    END ConsolidadoComiFaltante;  
     
    
     
    
end PKG_SLV_Consolidados;
/
