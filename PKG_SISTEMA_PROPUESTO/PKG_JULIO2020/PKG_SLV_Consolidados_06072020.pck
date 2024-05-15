CREATE OR REPLACE PACKAGE PKG_SLV_Consolidados is
  /**********************************************************************************************************
  * Author  : CHARLES ROY MALDONADO DUARTE
  * Created : 20/01/2020 05:05:03 p.m.
  * %v Paquete para la consolidación de pedidos en SLV
  **********************************************************************************************************/
  -- Tipos de datos

  TYPE CURSOR_TYPE IS REF CURSOR;

  --Procedimientos y Funciones
 PROCEDURE SetEstadoConsolidadoFacturado  (p_DtDesde        IN DATE,
                                           p_DtHasta        IN DATE) ;

  PROCEDURE GetConsolidado  (p_DtDesde        IN DATE,
                             p_DtHasta        IN DATE,
                             p_TipoTarea      IN tblslvtipotarea.cdtipo%type,
                             p_idcomi         IN pedidos.idcomisionista%type default null,
                             p_Cursor         OUT CURSOR_TYPE);

    PROCEDURE GetArtPanelConsolidado (p_idConsolidado   IN  Tblslvconsolidadom.Idconsolidadom%type,
                                    p_TipoTarea       IN  tblslvtipotarea.cdtipo%type,                                   
                                    p_DsSucursal      OUT sucursales.dssucursal%type,                       
                                    p_CursorCAB       OUT CURSOR_TYPE,                
                                    p_Cursor          OUT CURSOR_TYPE);
                                    
  PROCEDURE SetFinalizarConsolidados(p_idConsolidado   IN  Tblslvconsolidadom.Idconsolidadom%type,
                                     p_TipoTarea       IN  tblslvtipotarea.cdtipo%type,                                    
                                     p_Ok              OUT number,
                                     p_error           OUT varchar2);                                     
                                    
  FUNCTION SectorConsolidadoM(p_IdTarea          tblslvtarea.idtarea%type,
                              p_cdArticulo       tblslvtareadet.cdarticulo%type)
                              return varchar2;  
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
  FUNCTION SinAsigFaltanteConsoFaltante(p_idconsolidado  tblslvpedfaltante.idpedfaltante%type)
                           return integer;                          
  FUNCTION SinAsigConsolidadoComi(p_idconsolidadoComi   tblslvconsolidadocomi.idconsolidadocomi%type)
                           return integer;
  FUNCTION SinAsigConsolidadoComiFaltante(p_idconsolidadoComi   tblslvconsolidadocomi.idconsolidadocomi%type)
                           return integer;
  FUNCTION ConsolidadoComiFaltante(p_idconsolidadoComi   tblslvconsolidadocomi.idconsolidadocomi%type)
                           return integer;
end PKG_SLV_Consolidados;
/
CREATE OR REPLACE PACKAGE BODY PKG_SLV_Consolidados is
  /***************************************************************************************************
  *  %v 21/01/2020  ChM - Parametros globales privados
  ***************************************************************************************************/
  g_cdSucursal      sucursales.cdsucursal%type := trim(getvlparametro('CDSucursal', 'General'));

  c_TareaConsolidadoMulti            CONSTANT tblslvtipotarea.cdtipo%type := 10;
  c_TareaConsolidaMultiFaltante      CONSTANT tblslvtipotarea.cdtipo%type := 20;
  c_TareaConsolidadoPedido           CONSTANT tblslvtipotarea.cdtipo%type := 25;
  c_ReporteFaltantePedido            CONSTANT tblslvtipotarea.cdtipo%type := 28;
  c_TareaConsolidaPedidoFaltante     CONSTANT tblslvtipotarea.cdtipo%type := 40;
  c_TareaFaltanteConsolFaltante      CONSTANT tblslvtipotarea.cdtipo%type := 44;
  c_ReporteFaltaConsoFaltante        CONSTANT tblslvtipotarea.cdtipo%type := 45;
  c_TareaConsolidadoComi             CONSTANT tblslvtipotarea.cdtipo%type := 50;
  c_TareaConsolidadoComiFaltante     CONSTANT tblslvtipotarea.cdtipo%type := 60;
  
   --costante de tblslvestado

    
    C_FinalizadoConsolidadoM                           CONSTANT tblslvestado.cdestado%type := 3;
    C_FinalizadoTareaConsolidadoM                      CONSTANT tblslvestado.cdestado%type := 6;
    C_FinalizaTareaFaltaConsolidaM                     CONSTANT tblslvestado.cdestado%type := 9;
    C_CerradoConsolidadoPedido                         CONSTANT tblslvestado.cdestado%type := 12;
    C_AFacturarConsolidadoPedido                       CONSTANT tblslvestado.cdestado%type := 13;
    C_FacturadoConsolidadoPedido                       CONSTANT tblslvestado.cdestado%type := 14;
    C_FinalizaTareaConsolidaPedido                     CONSTANT tblslvestado.cdestado%type := 17;
    C_FinalizaFaltaConsolidaPedido                     CONSTANT tblslvestado.cdestado%type := 20;
    C_DistribFaltanteConsolidaPed                      CONSTANT tblslvestado.cdestado%type := 21;
    C_FinalizaTareaFaltaConsoliPed                     CONSTANT tblslvestado.cdestado%type := 24;
    C_FinalizadoConsolidadoComi                        CONSTANT tblslvestado.cdestado%type := 27;
    C_DistribuidoConsolidadoComi                       CONSTANT tblslvestado.cdestado%type := 28;
    C_FacturadoConsolidadoComi                         CONSTANT tblslvestado.cdestado%type := 29;
    C_FinalizaTareaFaltaConsolComi                     CONSTANT tblslvestado.cdestado%type := 32;
    C_FinalizaTareaConsolidaComi                       CONSTANT tblslvestado.cdestado%type := 35;
    C_FinalizadoTareaFaltConFalt                       CONSTANT tblslvestado.cdestado%type := 42;

  /**************************************************************************************************
  * %v 09/03/2020 - ChM  Obtener Consolidado Multicanal por fechas
  * %v 09/03/2020 - ChM. Versión Inicial
  ***************************************************************************************************/

  PROCEDURE GetConsolidadoMC(p_DtDesde        IN DATE,
                             p_DtHasta        IN DATE,
                             p_Cursor         OUT CURSOR_TYPE) IS

    v_modulo  varchar2(100) := 'PKG_SLV_Consolidados.GetConsolidadoMC';

  BEGIN
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
                and m.dtinsert between p_dtDesde and p_dtHasta
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
  * %v 14/05/2020 - ChM  agrego la fecha cuit y razón social del pedido
  ***************************************************************************************************/

  PROCEDURE GetConsolidadoPedido(p_DtDesde        IN DATE,
                                 p_DtHasta        IN DATE,
                                 p_Cursor         OUT CURSOR_TYPE) IS

    v_modulo  varchar2(100) := 'PKG_SLV_Consolidados.GetConsolidadoPedido';

  BEGIN
   
     OPEN p_Cursor FOR
             Select 
           Distinct p.idconsolidadom,
                    to_char(p.dtinsert,'dd/mm/yyyy') fecha,
                    p.idconsolidadopedido,
                    trunc(pe.dtaplicacion) dtaplicacion,
                    e.cdcuit,
                    e.dsrazonsocial,
                    est.dsestado,
                    --devuelve el idtarea
                    (select nvl(max(ta.idtarea),0) 
                       from tblslvtarea ta
                      where ta.cdtipo = c_TareaConsolidadoPedido
                        and ta.idconsolidadopedido = p.idconsolidadopedido) idtarea,
                     --devuelve cantidad de tareas                    
                    (select count(ta.idtarea) 
                       from tblslvtarea ta
                      where ta.cdtipo = c_TareaConsolidadoPedido
                        and ta.idconsolidadopedido = p.idconsolidadopedido) cantTareas,                         
                    PKG_SLV_Consolidados.SinAsigConsolidadoPedido(p.idconsolidadopedido)  articulosSinAsignar,
                    PKG_SLV_Consolidados.ConsolidadoPedidoFaltante(p.idconsolidadopedido) tieneFaltante
               from tblslvconsolidadopedido p,
                    entidades e,
                    pedidos pe,
                    tblslvconsolidadopedidorel rel,
                    tblslvestado est
              where est.cdestado = p.cdestado
                and p.identidad = e.identidad
                --valida que no sean pedidos de comisionistas
                and p.idconsolidadocomi is null
                and rel.idconsolidadopedido = p.idconsolidadopedido
                and rel.idpedido = pe.idpedido            
                and p.dtinsert between p_dtDesde and p_dtHasta
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

  BEGIN
   
     OPEN p_Cursor FOR
             Select p.idpedfaltante,
                    to_char(p.dtinsert,'dd/mm/yyyy') fecha,
                    est.dsestado,
                    PKG_SLV_Consolidados.SinAsigPedFaltante(p.idpedfaltante)  articulosSinAsignar,
                    PKG_SLV_Consolidados.PedFaltante(p.idpedfaltante) tieneFaltante,
                    PKG_SLV_Consolidados.SinAsigFaltanteConsoFaltante(p.idpedfaltante) tieneFaltanteSinAsignar                    
               from tblslvpedfaltante p,
                    tblslvestado est
              where est.cdestado = p.cdestado
                and p.dtinsert between p_dtDesde and p_dtHasta
           order by p.idpedfaltante;

   EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       '  Error: ' || SQLERRM);
  END  GetConsolidadoPedidoFaltante;

  /**************************************************************************************************
  * %v 09/04/2020 - ChM  Obtener Consolidado Comisionista por fechas
  * %v 02/01/2020 - ChM. agrego filtro por p_idcomi
  ***************************************************************************************************/

  PROCEDURE GetConsolidadoComi(p_DtDesde        IN DATE,
                               p_DtHasta        IN DATE,
                               p_idcomi         IN pedidos.idcomisionista%type default null,
                               p_Cursor         OUT CURSOR_TYPE) IS

    v_modulo  varchar2(100) := 'PKG_SLV_Consolidados.GetConsolidadoComi';

  BEGIN
   
     OPEN p_Cursor FOR
             Select distinct
                    c.idconsolidadocomi,
                    to_char(c.dtinsert,'dd/mm/yyyy') fecha,
                     e.dsrazonsocial ||' ('||trim(e.cdcuit)||')' razonsocial,
                    est.dsestado,
                    --cuenta todos los pedidos asociados al comisionista
                    (select count(*) 
                       from tblslvconsolidadopedido cp2 
                      where cp2.idconsolidadocomi=c.idconsolidadocomi) cant_clientes,                      
                    PKG_SLV_Consolidados.SinAsigConsolidadoComi(c.idconsolidadocomi) articulosSinAsignar,
                    PKG_SLV_Consolidados.ConsolidadoComiFaltante(c.idconsolidadocomi) tieneFaltante,
                    PKG_SLV_Consolidados.SinAsigConsolidadoComiFaltante(c.idconsolidadocomi) tieneFaltanteSinAsignar
               from tblslvconsolidadocomi c,
                    entidades e,                    
                    tblslvestado est
              where est.cdestado = c.cdestado
                and c.idcomisionista = e.identidad
                and (p_idcomi is null or c.idcomisionista=p_idcomi)
                and c.dtinsert between p_dtDesde and p_dtHasta          
           order by c.idconsolidadocomi;

   EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       '  Error: ' || SQLERRM);
  END GetConsolidadoComi;

  /****************************************************************************************************
  * %v 09/04/2020 - ChM  Versión inicial GetConsolidados
  * %v 02/06/2020 - ChM  Obtener Consolidados por fecha
  * %v 12/06/2020 - ChM  agrego Tarea Faltante Consolidado Faltante
  * %v 17/06/2020 - LM   actualizo los estados del consolidado pedido y consolidado comisionista
  *****************************************************************************************************/
  PROCEDURE GetConsolidado  (p_DtDesde        IN DATE,
                             p_DtHasta        IN DATE,
                             p_TipoTarea      IN tblslvtipotarea.cdtipo%type,
                             p_idcomi         IN pedidos.idcomisionista%type default null,
                             p_Cursor         OUT CURSOR_TYPE) IS
  v_dtHasta date;
  v_dtDesde date;                             
                            
  BEGIN
    v_dtDesde := trunc(p_DtDesde);
    v_dtHasta := to_date(to_char(p_DtHasta, 'dd/mm/yyyy') || ' 23:59:59',
                         'dd/mm/yyyy hh24:mi:ss');

    --verifico los estados para actualizar los facturados
    SetEstadoConsolidadoFacturado(v_dtDesde, v_dtHasta);

     --TipoTarea 10,20 ConsolidadoM y ConsolidadoMFaltante
     if p_TipoTarea in (c_TareaConsolidadoMulti,c_TareaConsolidaMultiFaltante) then
      GetConsolidadoMC(v_DtDesde,v_DtHasta,p_Cursor);
     end if;
     --TipoTarea 25 Consolidado pedido
     if p_TipoTarea = c_TareaConsolidadoPedido then
      GetConsolidadoPedido(v_DtDesde,v_DtHasta,p_Cursor);
     end if;
     --TipoTarea 40,44 Faltantes Consolidado pedido
     if p_TipoTarea in(c_TareaConsolidaPedidoFaltante,c_TareaFaltanteConsolFaltante) then
      GetConsolidadoPedidoFaltante(v_DtDesde,v_DtHasta,p_Cursor);
     end if;
    --TipoTarea 5,6 ConsolidadoComi y ConsolidadoComiFaltante
    if p_TipoTarea in (c_TareaConsolidadoComi,c_TareaConsolidadoComiFaltante) then
      GetConsolidadoComi(v_DtDesde,v_DtHasta,p_idcomi,p_Cursor);
    end if;

  END GetConsolidado;


  /****************************************************************************************************
  * %v 17/06/2020 - LM  Versión inicial 
  * Actualiza los estados de los consolidados pedidos y de comisionista
  *****************************************************************************************************/
 PROCEDURE SetEstadoConsolidadoFacturado  (p_DtDesde        IN DATE,
                                           p_DtHasta        IN DATE) IS
                           
  BEGIN
--consolidados pedidos
         UPDATE tblslvconsolidadopedido cpu
           SET cpu.cdestado = C_facturadoConsolidadoPedido
         WHERE cpu.idconsolidadopedido IN
               (SELECT CP.Idconsolidadopedido
                  FROM DOCUMENTOS DOCU,
                       PEDIDOS PED,
                       tblslvconsolidadopedidorel CPR,
                       tblslvconsolidadopedido CP 
                 WHERE PED.IDDOCTRX = DOCU.IDDOCTRX
                   AND PED.IDPEDIDO = CPR.Idpedido
                   AND CPR.IDCONSOLIDADOPEDIDO = CP.IDCONSOLIDADOPEDIDO 
                   AND CP.Cdestado = C_AFacturarConsolidadoPedido
                   AND PED.ICESTADOSISTEMA IN (4,5)
                   AND TRUNC(cp.Dtinsert) BETWEEN TRUNC(NVL(p_DtDesde, SYSDATE))
                                                         AND TRUNC(NVL(p_DtHasta, SYSDATE)+1));
--consolidados comisionista
         UPDATE tblslvconsolidadocomi ccu
           SET ccu.cdestado = C_FacturadoConsolidadoComi
         WHERE ccu.idconsolidadocomi IN
               (SELECT distinct CP.Idconsolidadocomi
                  FROM DOCUMENTOS DOCU,
                       PEDIDOS PED,
                       tblslvconsolidadopedidorel CPR,
                       tblslvconsolidadopedido CP,
                       tblslvconsolidadocomi CONS
                 WHERE PED.IDDOCTRX = DOCU.IDDOCTRX
                   AND PED.IDPEDIDO = CPR.IDPEDIDO
                   AND CPR.IDCONSOLIDADOPEDIDO = CP.IDCONSOLIDADOPEDIDO
                   AND CONS.IDCONSOLIDADOCOMI = CP.Idconsolidadocomi
                   AND CONS.Cdestado = C_DistribuidoConsolidadoComi
                   AND PED.ICESTADOSISTEMA IN (4,5)
                   AND TRUNC(CONS.Dtinsert) BETWEEN TRUNC(NVL(p_DtDesde, SYSDATE))
                                                         AND TRUNC(NVL(p_DtHasta, SYSDATE)+1));

  END SetEstadoConsolidadoFacturado;


  /****************************************************************************************************
  * %v 09/04/2020 - ChM  Versión inicial GetArticulosPanelConsolidadoM
  * %v 09/04/2020 - ChM  lista los articulos que conforman un ConsolidadoM
  * %v 14/05/2020 - ChM  Ajustes de nuevos parametros para ver faltantes
  * %v 26/05/2020 - ChM  Agrego validacion de Pesables
  *****************************************************************************************************/
  PROCEDURE GetArtPanelConsolidadoM(p_idConsolidadoM  IN  Tblslvconsolidadom.Idconsolidadom%type,
                                    p_TipoTarea       IN  tblslvtipotarea.cdtipo%type,
                                    p_CursorCAB       OUT CURSOR_TYPE,
                                    p_Cursor          OUT CURSOR_TYPE) IS

   v_modulo varchar2(100) := 'PKG_SLV_Consolidados.GetArtPanelConsolidadoM';

    BEGIN
      begin
      OPEN p_CursorCAB FOR 
      select m.idconsolidadom,
             m.dtinsert fechapedidom,
             m.idconsolidadom idconsolidado,
             sysdate fechapedido, 
             '-' cliente,
             '-' dsobservacion,
             '-' domicilio,
             '-' vendedor,
             to_char(m.qtconsolidado)||' BTO' bultos
        from tblslvconsolidadom m 
       where m.idconsolidadom = p_idConsolidadoM
         and rownum = 1;
      exception
        when others then
          NULL;
      end;
      OPEN p_Cursor FOR
            select A.Sector,
                   A.articulo,
                   --codigo de barras 
                   decode(A.basepza,0,
                   PKG_SLV_ARTICULO.GetCodigoDeBarra(A.COD,'UN'),
                   PKG_SLV_ARTICULO.GetCodigoDeBarra(A.COD,'KG')) barras,                    
                   PKG_SLV_Articulo.SetFormatoArticulosCod(A.COD,
                   --formato en piezas si es pesable  
                   decode(A.basepza,0,A.base,A.basepza)) Cantidad,                    
                   PKG_SLV_Articulo.SetFormatoArticulosCod(A.COD,
                   decode(A.basepza,0,A.picking,A.pickingpza)) Cantidad_picking, 
                   PKG_SLV_Articulo.SetFormatoArticulosCod(A.COD,
                   decode(A.basepza,0,A.diferencia,A.diferenciapza)) Diferencia,                   
                   PKG_SLV_Articulo.SetFormatoArticulosCod(A.COD,A.stock) stock,
                   A.uxb,
                   A.Ubicacion
              from (Select gs.cdgrupo||' - ' ||gs.dsgruposector||' ('||sec.dssector || ')' Sector,
                           art.cdarticulo || '- ' || des.vldescripcion Articulo,
                           art.cdarticulo COD,
                           det.qtunidadmedidabase base,
                           det.qtpiezas basepza,                        
                           det.qtunidadmedidabasepicking picking,
                           det.qtpiezaspicking pickingpza,
                           (det.qtunidadmedidabase-nvl(det.qtunidadmedidabasepicking,0)) diferencia,
                           (det.qtpiezas-nvl(det.qtpiezaspicking,0)) diferenciapza,
                           PKG_SLV_Articulos.GetStockArticulos(art.cdarticulo) STOCK,
                           posapp.n_pkg_vitalpos_materiales.GetUxB(art.cdarticulo) UXB,
                           PKG_SLV_Articulo.GetUbicacionArticulos(ART.cdarticulo) UBICACION     
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
                       and m.idconsolidadom = p_idConsolidadoM
                       --valida mostrar solo los faltantes cuando es tipo consolidado faltantes                      
                       and case 
                           --verifica si es pesable 
                            when det.qtpiezas<>0
                             and p_TipoTarea = c_TareaConsolidaMultiFaltante
                             and (det.qtpiezas-nvl(det.qtpiezaspicking,0) <> 0) then 1
                            --verifica los no pesable
                            when det.qtpiezas = 0 
                             and p_TipoTarea = c_TareaConsolidaMultiFaltante 
                             and (det.qtunidadmedidabase-nvl(det.qtunidadmedidabasepicking,0) <> 0)  then 1
                            --verifica consolidado M  
                            when p_TipoTarea = c_TareaConsolidadoMulti then 1
                           end = 1       
                        ) A;

    EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       '  Error: ' || SQLERRM);
  END GetArtPanelConsolidadoM;

    /****************************************************************************************************
  * %v 09/04/2020 - ChM  Versión inicial GetArtPanelConsolidaPedido
  * %v 09/04/2020 - ChM  lista los articulos que conforman un ConsolidadoPedido
  * %v 20/05/2020 - ChM  Agrego fatantes de pedido para reportes
  * %v 26/05/2020 - ChM  Agrego validacion de Pesables  
  * %v 11/06/2020 - LM   se agrega al vendedor en el reporte
  *****************************************************************************************************/
  PROCEDURE GetArtPanelConsolidaPedido(p_idConsolidadoPedido  IN  Tblslvconsolidadopedido.Idconsolidadopedido%type,
                                       p_TipoTarea            IN  tblslvtipotarea.cdtipo%type,                       
                                       p_CursorCAB            OUT CURSOR_TYPE,
                                       p_Cursor               OUT CURSOR_TYPE) IS

   v_modulo varchar2(100) := 'PKG_SLV_Consolidados.GetArtPanelConsolidaPedido';

    BEGIN
      begin
      OPEN p_CursorCAB FOR    
           select cp.idconsolidadom Idconsolidadom,
                  cp.dtinsert fechapedidom,
                  cp.idconsolidadopedido Idconsolidado,
                  cp.dtinsert fechapedido,
                  e.cdcuit||
                  NVL (e.dsrazonsocial, e.dsnombrefantasia) cliente,
                  nvl(op.dsobservacion,'-') dsobservacion,
                  de.dscalle||' '||
                  de.dsnumero||' CP ('||
                  trim(de.cdcodigopostal)||') '|| 
                  l.dslocalidad|| ' - '|| 
                  p.dsprovincia domicilio,
                  upper(pervend.dsnombre) || ' ' 
                  || upper(pervend.dsapellido) vendedor,
                  '-' bultos
             from pedidos                      pe           
        left join observacionespedido          op
               on (pe.idpedido = op.idpedido),
                  entidades                    e,                
                  tblslvconsolidadopedido      cp,
                  tblslvconsolidadopedidorel   pre,
                  direccionesentidades         de, 
                  localidades                  l,
                  provincias                   p,
                  personas                     pervend
            where cp.identidad=de.identidad
              --valida que no sean pedidos de comisionistas
              and cp.idconsolidadocomi is null
              and cp.identidad = e.identidad
              and pe.sqdireccion=de.sqdireccion
              and pe.cdtipodireccion=de.cdtipodireccion
              and de.cdlocalidad=l.cdlocalidad
              and de.cdprovincia=p.cdprovincia              
              and cp.idconsolidadopedido = pre.idconsolidadopedido
              and pre.idpedido = pe.idpedido
              and pe.idpersonaresponsable=pervend.idpersona
              and rownum = 1
              and cp.idconsolidadopedido = p_idConsolidadoPedido;
      exception
        when others then
           null;
      end;
      OPEN p_Cursor FOR
            select A.Sector,
                   A.articulo,
                   --codigo de barras 
                   decode(A.basepza,0,
                   PKG_SLV_ARTICULO.GetCodigoDeBarra(A.COD,'UN'),
                   PKG_SLV_ARTICULO.GetCodigoDeBarra(A.COD,'KG')) barras, 
                   PKG_SLV_Articulo.SetFormatoArticulosCod(A.COD,
                   --formato en piezas si es pesable  
                   decode(A.basepza,0,A.base,A.basepza)) Cantidad,                    
                   PKG_SLV_Articulo.SetFormatoArticulosCod(A.COD,
                   decode(A.basepza,0,A.picking,A.pickingpza)) Cantidad_picking, 
                   PKG_SLV_Articulo.SetFormatoArticulosCod(A.COD,
                   decode(A.basepza,0,A.diferencia,A.diferenciapza)) Diferencia,
                   PKG_SLV_Articulo.SetFormatoArticulosCod(A.COD,A.stock) stock,
                   A.uxb,
                   A.Ubicacion
              from (Select gs.cdgrupo||' - ' ||gs.dsgruposector||' ('||sec.dssector || ')' Sector,
                           art.cdarticulo || '- ' || des.vldescripcion Articulo,
                           art.cdarticulo COD,
                           det.qtunidadesmedidabase base,
                           det.qtpiezas basepza,
                           det.qtunidadmedidabasepicking picking,
                           det.qtpiezaspicking pickingpza,
                           (det.qtunidadesmedidabase-nvl(det.qtunidadmedidabasepicking,0)) diferencia,
                           (det.qtpiezas-nvl(det.qtpiezaspicking,0)) diferenciapza,
                           PKG_SLV_Articulos.GetStockArticulos(art.cdarticulo) STOCK,
                           posapp.n_pkg_vitalpos_materiales.GetUxB(art.cdarticulo) UXB,
                           PKG_SLV_Articulo.GetUbicacionArticulos(ART.cdarticulo) UBICACION
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
                       --valida mostrar solo los faltantes cuando es tipo consolidado faltantes                      
                       and case 
                           --verifica si es pesable 
                            when det.qtpiezas<>0
                             and p_TipoTarea = c_ReporteFaltantePedido
                             and (det.qtpiezas-nvl(det.qtpiezaspicking,0) <> 0) then 1
                            --verifica los no pesable
                            when det.qtpiezas = 0 
                             and p_TipoTarea = c_ReporteFaltantePedido 
                             and (det.qtunidadesmedidabase-nvl(det.qtunidadmedidabasepicking,0) <> 0)  then 1
                             --verifica consolidado pedido 
                            when p_TipoTarea = c_TareaConsolidadoPedido then 1  
                           end = 1         
                    ) A;

    EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       '  Error: ' || SQLERRM);
  END GetArtPanelConsolidaPedido;

  /****************************************************************************************************
  * %v 09/04/2020 - ChM  Versión inicial GetArtPanelPedFaltante
  * %v 09/04/2020 - ChM  lista los articulos que conforman un Consolidado pedido Faltante
  * %v 20/05/2020 - ChM  Agrego fatantes de pedido para reportes
  * %v 26/05/2020 - ChM  Agrego validacion de Pesables 
  * %v 12/06/2020 - ChM  agrego Tarea Faltante Consolidado Faltante
  *****************************************************************************************************/
  PROCEDURE GetArtPanelPedFaltante (p_idPedFaltante   IN  Tblslvpedfaltante.Idpedfaltante%type,
                                    p_TipoTarea       IN  tblslvtipotarea.cdtipo%type,
                                    p_CursorCAB       OUT CURSOR_TYPE,
                                    p_Cursor          OUT CURSOR_TYPE) IS

   v_modulo varchar2(100) := 'PKG_SLV_Consolidados.GetArtPanelPedFaltante';

    BEGIN
      begin
      OPEN p_CursorCAB FOR 
      select 0 idconsolidadom,
             sysdate fechapedidom,
             pf.idpedfaltante idconsolidado,
             pf.dtinsert fechapedido, 
             '-' cliente,
             '-' dsobservacion,
             '-' domicilio,
             '-' vendedor,
             '-' bultos
        from tblslvpedfaltante pf
       where pf.idpedfaltante = p_idPedFaltante  
         and rownum =1;
      exception
        when others then
             null;
      end;
      OPEN p_Cursor FOR
            select A.Sector,
                   A.articulo,
                   --codigo de barras 
                   decode(A.basepza,0,
                   PKG_SLV_ARTICULO.GetCodigoDeBarra(A.COD,'UN'),
                   PKG_SLV_ARTICULO.GetCodigoDeBarra(A.COD,'KG')) barras, 
                   PKG_SLV_Articulo.SetFormatoArticulosCod(A.COD,
                   --formato en piezas si es pesable  
                   decode(A.basepza,0,A.base,A.basepza)) Cantidad,                    
                   PKG_SLV_Articulo.SetFormatoArticulosCod(A.COD,
                   decode(A.basepza,0,A.picking,A.pickingpza)) Cantidad_picking, 
                   PKG_SLV_Articulo.SetFormatoArticulosCod(A.COD,
                   decode(A.basepza,0,A.diferencia,A.diferenciapza)) Diferencia,
                   PKG_SLV_Articulo.SetFormatoArticulosCod(A.COD,A.stock) stock,
                   A.uxb,
                   A.Ubicacion
              from (Select gs.cdgrupo||' - ' ||gs.dsgruposector||' ('||sec.dssector || ')' Sector,
                           art.cdarticulo || '- ' || des.vldescripcion Articulo,
                           art.cdarticulo COD,
                           det.qtunidadmedidabase base,
                           det.qtpiezas basepza,
                           det.qtunidadmedidabasepicking picking,
                           det.qtpiezaspicking pickingpza,
                           (det.qtunidadmedidabase-nvl(det.qtunidadmedidabasepicking,0)) diferencia,
                           (det.qtpiezas-nvl(det.qtpiezaspicking,0)) diferenciapza,
                           PKG_SLV_Articulos.GetStockArticulos(art.cdarticulo) STOCK,
                           posapp.n_pkg_vitalpos_materiales.GetUxB(art.cdarticulo) UXB,
                           PKG_SLV_Articulo.GetUbicacionArticulos(ART.cdarticulo) UBICACION
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
                       --valida mostrar solo los faltantes cuando es tipo consolidado faltantes                       
                       and case 
                           --verifica si es pesable 
                            when det.qtpiezas<>0
                             and p_TipoTarea in (c_ReporteFaltaConsoFaltante,c_TareaFaltanteConsolFaltante)
                             and (det.qtpiezas-nvl(det.qtpiezaspicking,0) <> 0) then 1
                            --verifica los no pesable
                            when det.qtpiezas = 0 
                             and p_TipoTarea in (c_ReporteFaltaConsoFaltante,c_TareaFaltanteConsolFaltante)
                             and (det.qtunidadmedidabase-nvl(det.qtunidadmedidabasepicking,0) <> 0)  then 1
                             --verifica consolidado pedido faltante
                            when p_TipoTarea = c_TareaConsolidaPedidoFaltante then 1    
                           end = 1         
                     ) A;    

    EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       '  Error: ' || SQLERRM);
  END GetArtPanelPedFaltante;

  /****************************************************************************************************
  * %v 09/04/2020 - ChM  Versión inicial GetArtPanelConsolidadoComi
  * %v 09/04/2020 - ChM  lista los articulos que conforman un Consolidado Comisionista
  * %v 14/05/2020 - ChM  Ajustes de nuevos parametros para ver faltantes
  * %v 26/05/2020 - ChM  Agrego validacion de Pesables 
  *****************************************************************************************************/
  PROCEDURE GetArtPanelConsolidadoComi(p_idConsolidadoComi  IN  Tblslvconsolidadocomi.Idconsolidadocomi%type,
                                       p_TipoTarea          IN  tblslvtipotarea.cdtipo%type,
                                       p_CursorCAB          OUT CURSOR_TYPE,
                                       p_Cursor             OUT CURSOR_TYPE) IS

   v_modulo varchar2(100) := 'PKG_SLV_Consolidados.GetArtPanelConsolidadoComi';

    BEGIN
      begin
      OPEN p_CursorCAB FOR 
      select c.idconsolidadom,
             cm.dtinsert fechapedidom,
             c.idconsolidadocomi idconsolidado,
             c.dtinsert fechapedido, 
             '-' cliente,
             '-' dsobservacion,
             '-' domicilio,
             '-' vendedor,
             '-' bultos
        from tblslvconsolidadocomi c,
             tblslvconsolidadom cm
       where c.idconsolidadocomi = p_idConsolidadoComi
         and c.idconsolidadom = cm.idconsolidadom
         and rownum =1;
      exception
        when others then
           null;
      end;
      OPEN p_Cursor FOR
            select A.Sector,
                   A.articulo,
                   --codigo de barras 
                   decode(A.basepza,0,
                   PKG_SLV_ARTICULO.GetCodigoDeBarra(A.COD,'UN'),
                   PKG_SLV_ARTICULO.GetCodigoDeBarra(A.COD,'KG')) barras, 
                   PKG_SLV_Articulo.SetFormatoArticulosCod(A.COD,
                   --formato en piezas si es pesable  
                   decode(A.basepza,0,A.base,A.basepza)) Cantidad,                    
                   PKG_SLV_Articulo.SetFormatoArticulosCod(A.COD,
                   decode(A.basepza,0,A.picking,A.pickingpza)) Cantidad_picking, 
                   PKG_SLV_Articulo.SetFormatoArticulosCod(A.COD,
                   decode(A.basepza,0,A.diferencia,A.diferenciapza)) Diferencia,
                   PKG_SLV_Articulo.SetFormatoArticulosCod(A.COD,A.stock) stock,
                   A.uxb,
                   A.Ubicacion
              from (Select gs.cdgrupo||' - ' ||gs.dsgruposector||' ('||sec.dssector || ')' Sector,
                           art.cdarticulo || '- ' || des.vldescripcion Articulo,
                           art.cdarticulo COD,
                           det.qtunidadmedidabase base,
                           det.qtpiezas basepza,
                           det.qtunidadmedidabasepicking picking,
                           det.qtpiezaspicking pickingpza,
                           (det.qtunidadmedidabase-nvl(det.qtunidadmedidabasepicking,0)) diferencia,
                           (det.qtpiezas-nvl(det.qtpiezaspicking,0)) diferenciapza,
                           PKG_SLV_Articulos.GetStockArticulos(art.cdarticulo) STOCK,
                           posapp.n_pkg_vitalpos_materiales.GetUxB(art.cdarticulo) UXB,
                           PKG_SLV_Articulo.GetUbicacionArticulos(ART.cdarticulo) UBICACION
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
                       and cm.idconsolidadocomi = p_idConsolidadoComi 
                       --valida mostrar solo los faltantes cuando es tipo consolidado faltantes
                       --tambien muestra los no pikeados como faltantes 
                       and case 
                           --verifica si es pesable 
                            when det.qtpiezas<>0
                             and p_TipoTarea = c_TareaConsolidadoComiFaltante
                             and (det.qtpiezas-nvl(det.qtpiezaspicking,0) <> 0) then 1
                            --verifica los no pesable
                            when det.qtpiezas = 0 
                             and p_TipoTarea = c_TareaConsolidadoComiFaltante 
                             and (det.qtunidadmedidabase-nvl(det.qtunidadmedidabasepicking,0) <> 0)  then 1
                             --verifica consolidado Comi
                            when p_TipoTarea = c_TareaConsolidadoComi then 1    
                           end = 1         
                    ) A;    

    EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       '  Error: ' || SQLERRM);
  END GetArtPanelConsolidadoComi;

  /****************************************************************************************************
  * %v 09/04/2020 - ChM  Versión inicial GetArtPanelConsolidado
  * %v 09/04/2020 - ChM  Lista los articulos que componen un idconsolidado panel
  * %v 14/05/2020 - ChM  Ajustes de nuevos parametros
  * %v 20/05/2020 - ChM  Agrego fatantes de pedido para reportes
  * %v 12/06/2020 - ChM  agrego Tarea Faltante Consolidado Faltante
  *****************************************************************************************************/
  PROCEDURE GetArtPanelConsolidado (p_idConsolidado   IN  Tblslvconsolidadom.Idconsolidadom%type,
                                    p_TipoTarea       IN  tblslvtipotarea.cdtipo%type,                                   
                                    p_DsSucursal      OUT sucursales.dssucursal%type,                       
                                    p_CursorCAB       OUT CURSOR_TYPE,                
                                    p_Cursor          OUT CURSOR_TYPE) IS

  BEGIN
     begin
     select su.dssucursal
      into p_DsSucursal
      from sucursales su
     where su.cdsucursal = g_cdSucursal
       and rownum=1;
     exception
        when others then
          p_DsSucursal:='-'; 
      end;                             
     --TipoTarea 10,20 ConsolidadoM y ConsolidadoMFaltante
     if p_TipoTarea in (c_TareaConsolidadoMulti,c_TareaConsolidaMultiFaltante) then
      GetArtPanelConsolidadoM(p_idConsolidado,p_TipoTarea,p_CursorCAB,p_Cursor);
     end if;
     --TipoTarea 25 Consolidado pedido
     if p_TipoTarea in (c_TareaConsolidadoPedido,c_ReporteFaltantePedido)then
      GetArtPanelConsolidaPedido(p_idConsolidado,p_TipoTarea,p_CursorCAB,p_Cursor);
     end if;
     --TipoTarea 40,44,45 Faltantes Consolidado pedido, Faltantes Consolidado Faltantes, reporte faltante de conso faltantes 
     if p_TipoTarea in (c_TareaConsolidaPedidoFaltante,c_ReporteFaltaConsoFaltante,c_TareaFaltanteConsolFaltante) then
      GetArtPanelPedFaltante(p_idConsolidado,p_TipoTarea,p_CursorCAB,p_Cursor);
     end if;
    --TipoTarea 5,6 ConsolidadoComi y ConsolidadoComiFaltante
    if p_TipoTarea in (c_TareaConsolidadoComi,c_TareaConsolidadoComiFaltante) then
      GetArtPanelConsolidadoComi(p_idConsolidado,p_TipoTarea,p_CursorCAB,p_Cursor);
    end if;

  END GetArtPanelConsolidado;

  /****************************************************************************************************
  * %v 03/06/2020 - ChM  Versión inicial SetFinalizarConsolidadosM
  * %v 03/06/2020 - ChM  finalizar los consolidadosM que reciba como parametro
  *****************************************************************************************************/
  PROCEDURE SetFinalizarConsolidadosM(p_idConsolidado   IN  Tblslvconsolidadom.Idconsolidadom%type,                                                                         
                                      p_Ok              OUT number,
                                      p_error           OUT varchar2) IS

    v_modulo               varchar2(100) := 'PKG_SLV_CONSOLIDADOS.SetFinalizarConsolidadosM';
    v_tarea                varchar2(2000):='_';
    v_ped                  tblslvconsolidadomdet.idconsolidadom%type; 
    v_estado               tblslvconsolidadom.cdestado%type;
  BEGIN
          begin
             select cm.cdestado
               into v_estado
               from tblslvconsolidadom cm
              where cm.idconsolidadom = p_idConsolidado;
           exception
             when no_data_found then
               p_Ok    := 0;
               p_error := 'Error consolidado pedido N° '||p_idConsolidado||' no existe.';
               RETURN;
           end;
            --verifico si el pedido ya esta Finalizado
            if v_estado = C_FinalizadoConsolidadoM then
               p_Ok    := 0;
               p_error := 'Error consolidado Multicanal N° '||p_idConsolidado||' ya Finalizado.';
               RETURN;
            end if;
            
           --verifica si tiene tareas sin finalizar
          begin
            select LISTAGG(ta.idtarea, ', ')
                   WITHIN GROUP (ORDER BY ta.idtarea) tareas
              into v_tarea
              from tblslvtarea ta
             where ta.idconsolidadom = p_idConsolidado
               and ta.cdestado not in (C_FinalizadoTareaConsolidadoM,C_FinalizaTareaFaltaConsolidaM)
               and ta.idconsolidadom is not null
          group by ta.idconsolidadom;
          if v_tarea <> '_' then
              p_Ok:=0;
              p_error:=' No es posible FINALIZAR ConsolidadoM: '
              ||p_idConsolidado||' las tareas: '||v_tarea||' no se han finalizado';
              return;
          end if;
       exception
        when no_data_found then
              v_tarea:= '_';
       end;   
        --verifica si tiene detalle de consolidado sin picking
        begin
          v_tarea:= '_';
           select LISTAGG(md.idconsolidadomdet, ', ')
                  WITHIN GROUP (ORDER BY md.idconsolidadomdet) detalle
             into v_tarea
             from tblslvconsolidadom m,
                  tblslvconsolidadomdet md   
            where m.idconsolidadom = md.idconsolidadom
              and md.qtunidadmedidabasepicking is null
              and m.idconsolidadom=p_idConsolidado
         group by m.idconsolidadom;
         if v_tarea <> '_' then
              p_Ok:=0;
              p_error:=' No es posible FINALIZAR ConsolidadoM: '
              ||p_idConsolidado||' tiene articulos sin asignar';
              return;
          end if;           
       exception
        when no_data_found then
              null;
       end;
       --verifico si el consolidado m no tiene picking
         begin
           select count(*)
             into v_ped
             from tblslvconsolidadom cm,
                  tblslvconsolidadomdet cmd
            where cm.idconsolidadom = cmd.idconsolidadom
              and nvl(cmd.qtunidadmedidabasepicking,0)<>0
              and cm.idconsolidadom = p_idConsolidado;
         exception 
           when no_data_found then
             p_Ok    := 0;
             p_error := 'Error consolidado multicanal no existe.';
             RETURN;  
         end;
          if v_ped = 0 then  
             p_Ok    := 0;
             p_error := 'Error consolidado multicanal no tiene artículos picking.';
             RETURN;    
          end if;    
                 
        --Actualizo a finalizado el consolidadoM
        update tblslvconsolidadom m
           set m.cdestado = C_FinalizadoConsolidadoM,
               m.dtupdate = sysdate             
         where m.idconsolidadom=p_idConsolidado;
         if SQL%ROWCOUNT = 0  then
          p_Ok:=0;
          p_error:=' No es posible update FINALIZAR ConsolidadoM: '||p_idConsolidado;
          rollback;    
          return; 
       end if;
    
  EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       ' Error: ' || SQLERRM);
      p_Ok:=0;
      p_error:=' No es posible FINALIZAR ConsolidadoM: '||p_idConsolidado||'. Comuniquese con Sistemas!';
  END SetFinalizarConsolidadosM; 
  
  /****************************************************************************************************
  * %v 03/06/2020 - ChM  Versión inicial SetFinalizarConsolidadosP
  * %v 03/06/2020 - ChM  finalizar los consolidados Pedidos que reciba como parametro
  *****************************************************************************************************/
  PROCEDURE SetFinalizarConsolidadosP(p_idConsolidado   IN  Tblslvconsolidadom.Idconsolidadom%type,                                                                         
                                      p_Ok              OUT number,
                                      p_error           OUT varchar2) IS

    v_modulo               varchar2(100) := 'PKG_SLV_CONSOLIDADOS.SetFinalizarConsolidadosP';
    v_tarea                varchar2(2000):='_';
    v_ped                  Tblslvconsolidadopedido.Idconsolidadopedido%type:= null;
    v_estado               tblslvconsolidadopedido.cdestado%type;
  BEGIN
           begin
             select cp.cdestado
               into v_estado
               from tblslvconsolidadopedido cp
              where cp.idconsolidadopedido = p_idConsolidado;
           exception
             when no_data_found then
               p_Ok    := 0;
               p_error := 'Error consolidado pedido N° '||p_idConsolidado||' no existe.';
               RETURN;
           end;
            --verifico si el pedido ya esta Facturado
            if v_estado in (C_AFacturarConsolidadoPedido,C_FacturadoConsolidadoPedido) then
               p_Ok    := 0;
               p_error := 'Error consolidado pedido N° '||p_idConsolidado||' ya facturado.';
               RETURN;
            end if;
            --verifico si el pedido esta cerrado
            if v_estado = C_CerradoConsolidadoPedido then
               p_Ok    := 0;
               p_error := 'Error consolidado pedido N° '||p_idConsolidado||' Ya cerrado.';
               RETURN;
            end if;                                                            

           --verifica si tiene tareas sin finalizar
          begin
            select LISTAGG(ta.idtarea, ', ')
                   WITHIN GROUP (ORDER BY ta.idtarea) tareas
              into v_tarea
              from tblslvtarea ta
             where ta.idconsolidadopedido = p_idConsolidado
               and ta.cdestado <> C_FinalizaTareaConsolidaPedido
               and ta.idconsolidadopedido is not null
          group by ta.idconsolidadopedido;
          if v_tarea <> '_' then
              p_Ok:=0;
              p_error:=' No es posible FINALIZAR Consolidado Pedido: '
              ||p_idConsolidado||' las tareas: '||v_tarea||' no se han finalizado';
              return;
          end if;
       exception
        when no_data_found then
              v_tarea:= '_';
       end;   
        --verifica si tiene detalle de consolidado sin picking
        begin
          v_tarea:= '_';
           select LISTAGG(pd.idconsolidadopedidodet, ', ')
                  WITHIN GROUP (ORDER BY pd.idconsolidadopedidodet) detalle
             into v_tarea
             from tblslvconsolidadopedido p,
                  tblslvconsolidadopedidodet pd  
            where p.idconsolidadopedido = pd.idconsolidadopedido
              and pd.qtunidadmedidabasepicking is null
              and p.idconsolidadopedido=p_idConsolidado
         group by p.idconsolidadopedido;
         if v_tarea <> '_' then
              p_Ok:=0;
              p_error:=' No es posible FINALIZAR Consolidado Pedido: '
              ||p_idConsolidado||' tiene articulos sin asignar';
              return;
          end if;           
       exception
        when no_data_found then
              null;
       end;  
       
        --verifico si el consolidado pedido no tiene picking
         begin
           select count(*)
             into v_ped
             from tblslvconsolidadopedido cp,
                  tblslvconsolidadopedidodet cpd
            where cpd.idconsolidadopedido = cp.idconsolidadopedido
              and nvl(cpd.qtunidadmedidabasepicking,0)<>0
              and cp.idconsolidadopedido = p_idConsolidado;
         exception 
           when no_data_found then
             p_Ok    := 0;
             p_error := 'Error consolidado pedido no existe.';
             RETURN;  
         end;
          if v_ped = 0 then  
             p_Ok    := 0;
             p_error := 'Error consolidado pedido no tiene artículos picking.';
             RETURN;    
          end if;    
       
        --Actualizo a finalizado el consolidado pedido
        update tblslvconsolidadopedido p
           set p.cdestado = C_CerradoConsolidadoPedido,
               p.dtupdate = sysdate             
         where p.idconsolidadopedido=p_idConsolidado;
         if SQL%ROWCOUNT = 0  then
          p_Ok:=0;
          p_error:=' No es posible update FINALIZAR Consolidado Pedido: '||p_idConsolidado;
          rollback;    
          return; 
       end if;
    
  EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       ' Error: ' || SQLERRM);
      p_Ok:=0;
      p_error:=' No es posible FINALIZAR Consolidado Pedido: '||p_idConsolidado||'. Comuniquese con Sistemas!';
  END SetFinalizarConsolidadosP; 

  /****************************************************************************************************
  * %v 03/06/2020 - ChM  Versión inicial SetFinalizarConsolidadosF
  * %v 03/06/2020 - ChM  finalizar los consolidados Pedidos faltantes que reciba como parametro
  *****************************************************************************************************/
  PROCEDURE SetFinalizarConsolidadosF(p_idConsolidado   IN  Tblslvconsolidadom.Idconsolidadom%type,                                                                         
                                      p_Ok              OUT number,
                                      p_error           OUT varchar2) IS

    v_modulo               varchar2(100) := 'PKG_SLV_CONSOLIDADOS.SetFinalizarConsolidadosF';
    v_tarea                varchar2(2000):='_';
    v_ped                  Tblslvpedfaltante.Idpedfaltante%type:= null;
  BEGIN
        
          begin
           select f.cdestado
             into v_ped
             from tblslvpedfaltante f
            where f.idpedfaltante = p_idConsolidado;
         exception
           when no_data_found then
             p_Ok    := 0;
             p_error := 'Error consolidado pedido faltante no existe.';
             RETURN;
         end;
         --verifico si el faltante esta distribuido
          if v_ped = C_DistribFaltanteConsolidaPed then
             p_Ok    := 0;
             p_error := 'Error pedido faltante ya distribuido.';
             RETURN;
          end if;
          
         --verifico si el faltante esta finalizado 
         if v_ped = C_FinalizaFaltaConsolidaPedido then
           p_Ok    := 0;
           p_error := 'Error pedido faltante ya finalizado.';
           RETURN;
        end if;
    
           --verifica si tiene tareas sin finalizar
          begin
            select LISTAGG(ta.idtarea, ', ')
                   WITHIN GROUP (ORDER BY ta.idtarea) tareas
              into v_tarea
              from tblslvtarea ta
             where ta.idpedfaltante = p_idConsolidado
               and ta.cdestado not in (C_FinalizaTareaFaltaConsoliPed,C_FinalizadoTareaFaltConFalt)
               and ta.idpedfaltante is not null
          group by ta.idpedfaltante;
          if v_tarea <> '_' then
              p_Ok:=0;
              p_error:=' No es posible FINALIZAR Consolidado Faltante: '
              ||p_idConsolidado||' las tareas: '||v_tarea||' no se han finalizado';
              return;
          end if;
       exception
        when no_data_found then
              v_tarea:= '_';
       end;   
        --verifica si tiene detalle de consolidado sin picking
        begin
          v_tarea:= '_';
           select LISTAGG(pfd.idpedfaltantedet, ', ')
                  WITHIN GROUP (ORDER BY pfd.idpedfaltantedet) detalle
             into v_tarea
             from tblslvpedfaltante pf,
                  tblslvpedfaltantedet pfd  
            where pf.idpedfaltante = pfd.idpedfaltante
              and pfd.qtunidadmedidabasepicking is null
              and pf.idpedfaltante=p_idConsolidado
         group by pf.idpedfaltante;
         if v_tarea <> '_' then
              p_Ok:=0;
              p_error:=' No es posible FINALIZAR Consolidado Faltante: '
              ||p_idConsolidado||' tiene articulos sin asignar';
              return;
          end if;           
       exception
        when no_data_found then
              null;
       end;   
       
       --verifico si el consolidado faltante no tiene picking
         begin
           select count(*)
             into v_ped
             from tblslvpedfaltante pf,
                  tblslvpedfaltantedet pfd
            where pf.idpedfaltante = pfd.idpedfaltante
              and nvl(pfd.qtunidadmedidabasepicking,0)<>0
              and pf.idpedfaltante = p_idConsolidado;
         exception 
           when no_data_found then
             p_Ok    := 0;
             p_error := 'Error consolidado faltante no existe.';
             RETURN;  
         end;
          if v_ped = 0 then  
             p_Ok    := 0;
             p_error := 'Error consolidado faltante no tiene artículos picking.';
             RETURN;    
          end if;    
          
        --Actualizo a finalizado el consolidado faltante
        update tblslvpedfaltante pf
           set pf.cdestado = C_FinalizaFaltaConsolidaPedido,
               pf.dtupdate = sysdate             
         where pf.idpedfaltante = p_idConsolidado;
         if SQL%ROWCOUNT = 0  then
          p_Ok:=0;
          p_error:=' No es posible update FINALIZAR Consolidado Faltante: '||p_idConsolidado;
          rollback;    
          return; 
       end if;
    
  EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       ' Error: ' || SQLERRM);
      p_Ok:=0;
      p_error:=' No es posible FINALIZAR Consolidado Faltante: '||p_idConsolidado||'. Comuniquese con Sistemas!';
  END SetFinalizarConsolidadosF; 
  
    /****************************************************************************************************
  * %v 03/06/2020 - ChM  Versión inicial SetFinalizarConsolidadosC
  * %v 03/06/2020 - ChM  finalizar los consolidados Comisionista que reciba como parametro
  *****************************************************************************************************/
  PROCEDURE SetFinalizarConsolidadosC(p_idConsolidado   IN  Tblslvconsolidadom.Idconsolidadom%type,                                                                         
                                      p_Ok              OUT number,
                                      p_error           OUT varchar2) IS

    v_modulo               varchar2(100) := 'PKG_SLV_CONSOLIDADOS.SetFinalizarConsolidadosC';
    v_tarea                varchar2(2000):='_';
    v_ped                  Tblslvconsolidadocomi.Idconsolidadocomi%type:= null;
    v_estado               tblslvconsolidadocomi.cdestado%type;
  BEGIN
    
          begin
           select cc.cdestado
             into v_estado
             from tblslvconsolidadocomi cc
            where cc.idconsolidadocomi = p_idConsolidado;
         exception
           when no_data_found then
             p_Ok    := 0;
             p_error := 'Error consolidado comisionista N° '||p_idConsolidado||' no existe.';
             RETURN;
         end;
          --verifico si el pedido comi ya esta distribuido
          if v_estado in (C_DistribuidoConsolidadoComi,C_FacturadoConsolidadoComi) then
             p_Ok    := 0;
             p_error := 'Error consolidado Comisionista N° '||p_idConsolidado||' ya Distribuido.';
             RETURN;
          end if;
         --verifico si el pedido esta cerrado y se puede distribuir
          if v_estado = C_FinalizadoConsolidadoComi  then
             p_Ok    := 0;
             p_error := 'Error consolidado comisionista N° '||p_idConsolidado||' ya finalizado.';
             RETURN;
          end if;
  
           --verifica si tiene tareas sin finalizar
          begin
            select LISTAGG(ta.idtarea, ', ')
                   WITHIN GROUP (ORDER BY ta.idtarea) tareas
              into v_tarea
              from tblslvtarea ta
             where ta.idconsolidadocomi = p_idConsolidado
               and ta.cdestado not in (C_FinalizaTareaConsolidaComi,C_FinalizaTareaFaltaConsolComi)
               and ta.idconsolidadocomi is not null
          group by ta.idconsolidadocomi;
          if v_tarea <> '_' then
              p_Ok:=0;
              p_error:=' No es posible FINALIZAR Consolidado Comisionista: '
              ||p_idConsolidado||' las tareas: '||v_tarea||' no se han finalizado';
              return;
          end if;
       exception
        when no_data_found then
              v_tarea:= '_';
       end;   
        --verifica si tiene detalle de consolidado sin picking
        begin
          v_tarea:= '_';
           select LISTAGG(cd.idconsolidadocomidet, ', ')
                  WITHIN GROUP (ORDER BY cd.idconsolidadocomidet) detalle
             into v_tarea
             from tblslvconsolidadocomi c,
                  tblslvconsolidadocomidet cd   
            where c.idconsolidadocomi = cd.idconsolidadocomi
              and cd.qtunidadmedidabasepicking is null
              and c.idconsolidadocomi=p_idConsolidado
         group by c.idconsolidadocomi;
         if v_tarea <> '_' then
              p_Ok:=0;
              p_error:=' No es posible FINALIZAR Consolidado Comisionista: '
              ||p_idConsolidado||' tiene articulos sin asignar';
              return;
          end if;           
       exception
        when no_data_found then
              null;
       end;   
       
       --verifico si el consolidado comisionista no tiene picking
         begin
           select count(*)
             into v_ped
             from tblslvconsolidadocomi cc,
                  tblslvconsolidadocomidet ccd
            where cc.idconsolidadocomi = ccd.idconsolidadocomi
              and nvl(ccd.qtunidadmedidabasepicking,0)<>0
              and cc.idconsolidadocomi = p_idConsolidado;
         exception 
           when no_data_found then
             p_Ok    := 0;
             p_error := 'Error consolidado comisionista no existe.';
             RETURN;  
         end;
          if v_ped = 0 then  
             p_Ok    := 0;
             p_error := 'Error consolidado comisionista no tiene artículos picking.';
             RETURN;    
          end if;    
       
        --Actualizo a finalizado el consolidado Comisionista
        update tblslvconsolidadocomi c
           set c.cdestado = C_FinalizadoConsolidadoComi,
               c.dtupdate = sysdate             
         where c.idconsolidadocomi = p_idConsolidado;
         if SQL%ROWCOUNT = 0  then
          p_Ok:=0;
          p_error:=' No es posible update FINALIZAR Consolidado Comisionista: '||p_idConsolidado;
          rollback;    
          return; 
       end if;
    
  EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       ' Error: ' || SQLERRM);
      p_Ok:=0;
      p_error:=' No es posible FINALIZAR Consolidado Comisionista: '||p_idConsolidado||'. Comuniquese con Sistemas!';
  END SetFinalizarConsolidadosC; 

/****************************************************************************************************
  * %v 03/06/2020 - ChM  Versión inicial SetFinalizarConsolidados
  * %v 03/06/2020 - ChM  finalizar los consolidados que reciba como parametro
  * %v 12/06/2020 - ChM  agrego Tarea Faltante Consolidado Faltante
  *****************************************************************************************************/
  PROCEDURE SetFinalizarConsolidados(p_idConsolidado   IN  Tblslvconsolidadom.Idconsolidadom%type,
                                     p_TipoTarea       IN  tblslvtipotarea.cdtipo%type,                                     
                                     p_Ok              OUT number,
                                     p_error           OUT varchar2) IS

  BEGIN
     p_Ok:=1;
     p_error:='';
     --TipoTarea 10,20 ConsolidadoM y ConsolidadoMFaltante
     if p_TipoTarea in (c_TareaConsolidadoMulti,c_TareaConsolidaMultiFaltante) then
         SetFinalizarConsolidadosM(p_idConsolidado,p_Ok,p_error);
     end if;   
     --TipoTarea 25 Consolidado pedido
     if p_TipoTarea = c_TareaConsolidadoPedido then
       SetFinalizarConsolidadosP(p_idConsolidado,p_Ok,p_error);
     end if;
     --TipoTarea 40,44 Faltantes Consolidado pedido y Faltantes Consolidado Faltantes
     if p_TipoTarea in (c_TareaConsolidaPedidoFaltante,c_TareaFaltanteConsolFaltante) then
        SetFinalizarConsolidadosF(p_idConsolidado,p_Ok,p_error);
     end if;
     --TipoTarea 5,6 ConsolidadoComi y ConsolidadoComiFaltante
     if p_TipoTarea in (c_TareaConsolidadoComi,c_TareaConsolidadoComiFaltante) then
      SetFinalizarConsolidadosC(p_idConsolidado,p_Ok,p_error);
     end if;
     if p_ok <> 1 then
        rollback;
        return; 
     end if;    
     p_Ok:=1;
     p_error:='';
     commit;  
  END SetFinalizarConsolidados; 

/****************************************************************************************************
  * %v 19/05/2020 - ChM  Versión inicial SectorConsolidadoM
  * %v 19/05/2020 - ChM  si el articulo está en un consolidadoM devuelve sector sino NULL
  *****************************************************************************************************/
  FUNCTION SectorConsolidadoM(p_IdTarea          tblslvtarea.idtarea%type,
                              p_cdArticulo       tblslvtareadet.cdarticulo%type)
                       return varchar2 IS
    v_idconsolidadopedido  tblslvtarea.idconsolidadopedido%type;
    v_idconsolidadocomi    tblslvtarea.idconsolidadocomi%type;
    v_sector               varchar2(50):= null;
    
  BEGIN
    --obtengo el idconsolidadopedio o idconsolidadocomi de la tarea y el artículo
        select 
      distinct ta.idconsolidadopedido,
               ta.idconsolidadocomi 
          into v_idconsolidadopedido,
               v_idconsolidadocomi     
          from tblslvtarea ta,
               tblslvtareadet dta
         where dta.idtarea = ta.idtarea    
           and ta.idtarea = p_idtarea
           and dta.cdarticulo = p_cdarticulo;
   -- valida si son ambos null devuelve sector null        
    if v_idconsolidadopedido is null and v_idconsolidadocomi is null then
       return null; 
      end if;
 
    select '999 - Consolidado a desconsolidar ' sector 
      into v_sector  
      from tblslvconsolidadom cm,
           tblslvconsolidadomdet md
     where md.idconsolidadom = cm.idconsolidadom
       --revisa si el articulo esta en consolidado
       and md.cdarticulo = p_cdArticulo
       --valida que exista cantidad en el consolidadoM
       and nvl(md.qtunidadmedidabasepicking,0)>0
       --valida que el articulo este en el consolidadoM
       and (cm.idconsolidadom in 
              (select p.idconsolidadom 
                 from tblslvconsolidadopedido p
                where p.idconsolidadopedido=v_idconsolidadopedido)
            or 
            cm.idconsolidadom in 
              (select c.idconsolidadom 
                 from tblslvconsolidadocomi c
                where c.idconsolidadocomi=v_idconsolidadocomi) 
       )
       and rownum=1;
       
      return v_sector; 
       
     EXCEPTION
    WHEN OTHERS THEN
      return null;    
  END ;   

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
                and case 
                    --verifica si es pesable 
                     when det.qtpiezas<>0 
                      and det.qtpiezas-nvl(det.qtpiezaspicking,0) <> 0 then 1
                     --verifica los no pesable
                     when det.qtpiezas = 0 
                      and det.qtunidadmedidabase-nvl(det.qtunidadmedidabasepicking,0) <> 0 then 1
                    end = 1 
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
                and case 
                    --verifica si es pesable 
                     when det.qtpiezas<>0 
                      and det.qtpiezas-nvl(det.qtpiezaspicking,0) <> 0 then 1
                     --verifica los no pesable
                     when det.qtpiezas = 0 
                      and det.qtunidadmedidabase-nvl(det.qtunidadmedidabasepicking,0) <> 0 then 1
                    end = 1;
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
                and case 
                    --verifica si es pesable 
                     when det.qtpiezas<>0 
                      and det.qtpiezas-nvl(det.qtpiezaspicking,0) <> 0 then 1
                     --verifica los no pesable
                     when det.qtpiezas = 0 
                      and det.qtunidadesmedidabase-nvl(det.qtunidadmedidabasepicking,0) <> 0 then 1
                    end = 1;
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
                and case 
                    --verifica si es pesable 
                     when det.qtpiezas<>0 
                      and det.qtpiezas-nvl(det.qtpiezaspicking,0) <> 0 then 1
                     --verifica los no pesable
                     when det.qtpiezas = 0 
                      and det.qtunidadmedidabase-nvl(det.qtunidadmedidabasepicking,0) <> 0 then 1
                    end = 1;
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
  * %v 12/06/2020 - ChM  devuelve 1 si existen articulos sin asignar en Faltante Consolidado Faltantes
  * %v 12/06/2020 - ChM. Versión Inicial
  ***************************************************************************************************/
  FUNCTION SinAsigFaltanteConsoFaltante(p_idconsolidado  tblslvpedfaltante.idpedfaltante%type)
                           return integer is
      v_modulo  varchar2(100) := 'PKG_SLV_Consolidados.SinAsigFaltanteConsoFaltante;';
      v_cont     integer;
  BEGIN
        Select count(pf.idpedfaltante)
          into v_cont
               from tblslvpedfaltante pf,
                    tblslvpedfaltantedet detf
              where pf.idpedfaltante = detf.idpedfaltante
                and pf.idpedfaltante = p_idconsolidado
                --valida que no existan articulos sin picking
                and detf.qtunidadmedidabasepicking is not null
                --valida que exista diferencia entre picking y unidad base, estos son los faltantes
                and case 
                    --verifica si es pesable 
                     when detf.qtpiezas<>0 
                      and detf.qtpiezas-nvl(detf.qtpiezaspicking,0) <> 0 then 1
                     --verifica los no pesable
                     when detf.qtpiezas = 0 
                      and detf.qtunidadmedidabase-nvl(detf.qtunidadmedidabasepicking,0) <> 0 then 1
                    end = 1
                --valida no listar Faltantes consolidado Faltantes ya asignados totalmente al armador
                and detf.cdarticulo not in(select td.cdarticulo
                                            from tblslvtarea ta,
                                                 tblslvtareadet td
                                           where ta.idtarea=td.idtarea
                                             and ta.idpedfaltante=pf.idpedfaltante
                                             and ta.idpersona= pf.idpersona
                                             and ta.cdtipo=c_TareaFaltanteConsolFaltante);
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
    END SinAsigFaltanteConsoFaltante;

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
                and case 
                    --verifica si es pesable 
                     when det.qtpiezas<>0 
                      and det.qtpiezas-nvl(det.qtpiezaspicking,0) <> 0 then 1
                     --verifica los no pesable
                     when det.qtpiezas = 0 
                      and det.qtunidadmedidabase-nvl(det.qtunidadmedidabasepicking,0) <> 0 then 1
                    end = 1
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
                and case 
                    --verifica si es pesable 
                     when det.qtpiezas<>0 
                      and det.qtpiezas-nvl(det.qtpiezaspicking,0) <> 0 then 1
                     --verifica los no pesable
                     when det.qtpiezas = 0 
                      and det.qtunidadmedidabase-nvl(det.qtunidadmedidabasepicking,0) <> 0 then 1
                    end = 1;
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
