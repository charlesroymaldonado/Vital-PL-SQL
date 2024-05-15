CREATE OR REPLACE PACKAGE PKG_SLV_REPORTE AS
/******************************************************************************
      Nombre: PKG_SLV_REPORTES
    Descripción: Manejo de todo lo relacionado con reportes del SLVM

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        11/06/2020   Charles Maldonado     versión inicial
******************************************************************************/

 TYPE cursor_type IS REF CURSOR; 
  
 TYPE arr_IdConsofaltante IS TABLE OF CHAR(14) INDEX BY PLS_INTEGER;
  
  PROCEDURE GetReporteDistribFaltantes(p_idconsFaltantes IN  tblslvpedfaltante.idpedfaltante%type,
                                       p_personaDistrib  OUT varchar2,
                                       p_sucursal        OUT varchar2,
                                       p_fechaDistrib    OUT date, 
                                       p_Ok              OUT number,
                                       p_error           OUT varchar2,
                                       p_Cursor          OUT CURSOR_TYPE);
                                    
  PROCEDURE RepArtFaltantePedFaltante(p_idpedidoFaltante  IN  arr_IdConsofaltante, 
                                      p_DsSucursal        OUT sucursales.dssucursal%type,    
                                      p_Cursor            OUT CURSOR_TYPE);  
                                                                        
/*  PROCEDURE GrupoArtComisionista(p_idComi            IN  tblslvconsolidadocomi.idconsolidadocomi%type,
                                 p_DsComisionista    OUT entidades.dsrazonsocial%type,                                   
                                 p_Cursor            OUT CURSOR_TYPE);
                                 */
                                 
  PROCEDURE TotalArtComisionista(p_idComi            IN  tblslvconsolidadocomi.idconsolidadocomi%type,
                                 p_DsComisionista    OUT entidades.dsrazonsocial%type,                                   
                                 p_Cursor            OUT CURSOR_TYPE);
                                 
  PROCEDURE GrupoArtPedidoXComisionista(p_idComi            IN  tblslvconsolidadocomi.idconsolidadocomi%type,
                                        p_DsComisionista    OUT entidades.dsrazonsocial%type,                                   
                                        p_Cursor            OUT CURSOR_TYPE);  
                                                                       
  PROCEDURE FacturadoCarretaComisionista(p_idComi            IN  tblslvconsolidadocomi.idconsolidadocomi%type,
                                         p_CursorCAB         OUT CURSOR_TYPE,                                   
                                         p_Cursor            OUT CURSOR_TYPE);                                            
                                         
   PROCEDURE DiferenciaPickeadoFacturado(p_IdPedidos       IN  Tblslvconsolidadom.Idconsolidadom%type default 0,
                                        p_dtfechadesde    IN  DATE,
                                        p_dtfechahasta    IN  DATE,                       
                                        p_TipoTarea       IN  tblslvtipotarea.cdtipo%type default 0,
                                        p_Cursor          OUT CURSOR_TYPE);                                              
                                                                              
  PROCEDURE FaltanteRealXFecha(p_dtfechadesde      IN  DATE,
                               p_dtfechahasta      IN  DATE, 
                         --      p_idconsolidadoPedi IN  tblslvconsolidadopedido.idconsolidadopedido%type default 0,
                       --        p_idconsolidadoComi IN  tblslvconsolidadopedido.idconsolidadopedido%type default 0,
                               p_Cursor          OUT CURSOR_TYPE);
                               
                                                       
 -- Uso interno del Paquete
  FUNCTION CarretaXComi(p_idComi          tblslvconsolidadocomi.idconsolidadocomi%type,
                        p_cdArticulo      articulos.cdarticulo%type)
                        return varchar2;
 FUNCTION ClienteXGrupoXComi(p_idComi          tblslvconsolidadocomi.idconsolidadocomi%type,
                             p_grupo           number)
                       return varchar2;  
                                     
                                 
END PKG_SLV_REPORTE;
/
CREATE OR REPLACE PACKAGE BODY PKG_SLV_REPORTE  AS
/***************************************************************************************************
*  %v 11/06/2020  ChM - Parametros globales del PKG
****************************************************************************************************/
--c_qtDecimales                                  CONSTANT number := 2; -- cantidad de decimales para redondeo
  g_cdSucursal      sucursales.cdsucursal%type := trim(getvlparametro('CDSucursal','General'));
  C_FinalizaFaltaConsolidaPedido                     CONSTANT tblslvestado.cdestado%type := 20;
  C_DistribFaltaConsolidaPedido                      CONSTANT tblslvestado.cdestado%type := 21;
  
  
  c_TareaConsolidadoPedido           CONSTANT tblslvtipotarea.cdtipo%type := 25; 
  c_TareaConsolidadoComi             CONSTANT tblslvtipotarea.cdtipo%type := 50;
    
  /****************************************************************************************************
  * %v 11/06/2020 - LM  Reporte de la distribucion del consolidado de faltantes de reparto
  * %v 13/06/2020 - ChM Incorporó codigo de barras.
  * %v 18/07/2020 - ChM Ajusto pesables Cliente y orden por remito
                    LISTAGG(to_char(r.idremito), ', ')
                    WITHIN GROUP (ORDER BY to_char(r.idremito)) 
  *****************************************************************************************************/
  PROCEDURE GetReporteDistribFaltantes(p_idconsFaltantes IN  tblslvpedfaltante.idpedfaltante%type,
                                       p_personaDistrib  OUT varchar2,
                                       p_sucursal        OUT varchar2,
                                       p_fechaDistrib    OUT date, 
                                       p_Ok              OUT number,
                                       p_error           OUT varchar2,
                                       p_Cursor          OUT CURSOR_TYPE) IS

    v_modulo varchar2(100) := 'PKG_SLV_REPORTE.GetReporteDistribFaltantes';
    v_error  varchar2(150);
    v_estado tblslvpedfaltante.cdestado%type:=0;
  BEGIN
      select pf.cdestado into v_estado
      from tblslvpedfaltante pf
      where pf.idpedfaltante=p_idconsFaltantes;  
      
      if v_estado <> C_DistribFaltaConsolidaPedido  then
        p_Ok:=0;
        p_error:= 'El Consolidado Faltante aun no fue distribuido.';
        p_fechaDistrib:=sysdate;
        p_personaDistrib:='-';
        p_sucursal:='-';
        return;
      end if;
  
       begin --sucursal
       select su.dssucursal
        into p_sucursal
        from sucursales su
       where trim(su.cdsucursal) =   trim( getvlparametro('CDSucursal', 'General'))
         and rownum=1;
       exception
          when others then
            p_sucursal:='-'; 
        end; 
      --datos persona que distribuyo y fecha
         select distinct p.dsnombre ||' ' ||  p.dsapellido, pfr.dtdistribucion
                into p_personaDistrib, p_fechaDistrib
         from personas p, tblslvpedfaltanterel pfr, tblslvconsolidadopedido cp 
         where p.idpersona=pfr.idpersonadistribucion
         and  pfr.idpedfaltante=p_idconsFaltantes
         and pfr.idconsolidadopedido=cp.idconsolidadopedido;
  
      OPEN P_Cursor FOR --cursor de distribucion de consolidado de faltantes
        select pfr.idconsolidadopedido,
               TRIM(NVL (e.dsrazonsocial, e.dsnombrefantasia))||' ('||TRIM(e.cdcuit)||')' as Cliente, 
               gs.cdgrupo || ' - ' || gs.dsgruposector || ' (' ||
               sec.dssector || ')' Sector,
               --codigo de barras 
               decode(dpf.qtpiezas,0,
               PKG_SLV_ARTICULO.GetCodigoDeBarra(dpf.cdarticulo,'UN'),
               PKG_SLV_ARTICULO.GetCodigoDeBarra(dpf.cdarticulo,'KG')) barras,
               dpf.cdarticulo || '- ' || da.vldescripcion articulo,
               PKG_SLV_Articulo.SetFormatoArticulosCod(art.cdarticulo,
               --formato en piezas si es pesable  
               decode(dpf.qtpiezas,0,dpf.qtunidadmedidabase,dpf.qtpiezas)) Cantidad,
               posapp.n_pkg_vitalpos_materiales.GetUxB(art.cdarticulo) UXB,
               r.idremito nroRemito       
          from tblslvdistribucionpedfaltante dpf, 
               tblslvpedfaltanterel          pfr, 
               tblslvconsolidadopedido       cp, 
               entidades                     e, 
               descripcionesarticulos        da,
               sectores                      sec,
               tblslv_grupo_sector           gs,
               articulos                     art, 
               tblslvremito                  r
        where dpf.idpedfaltanterel=pfr.idpedfaltanterel
          and pfr.idconsolidadopedido=cp.idconsolidadopedido
          and pfr.idpedfaltante=p_idconsFaltantes
          and cp.identidad=e.identidad
          and dpf.cdarticulo=da.cdarticulo
          and dpf.cdarticulo=art.cdarticulo
          and art.cdsector = sec.cdsector          
          and sec.cdsector = gs.cdsector 
          and r.idpedfaltanterel=pfr.idpedfaltanterel
     order by nroRemito,
              pfr.idconsolidadopedido, 
              gs.cdgrupo, 
              dpf.cdarticulo;
      p_Ok    := 1;
      p_error := null;       
  EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       'Detalle Error: ' || v_error ||
                                       '  Error: ' || SQLERRM);
      p_Ok:=0;
      p_error:='No es posible mostrar la distribución de los faltantes. Comuniquese con Sistemas.';
      ROLLBACK;
  END GetReporteDistribFaltantes;
  
  
   /****************************************************************************************************
  * %v 12/03/2020 - ChM  Versión inicial RepArtFaltantePedFaltante
  * %v 12/03/2020 - ChM  lista los articulos faltantes de un arreglo de consolidado pedido Faltante
  *****************************************************************************************************/
  PROCEDURE RepArtFaltantePedFaltante(p_idpedidoFaltante  IN  arr_IdConsofaltante, 
                                      p_DsSucursal        OUT sucursales.dssucursal%type,    
                                      p_Cursor            OUT CURSOR_TYPE) IS

   v_modulo                           varchar2(100) := 'PKG_SLV_REPORTE.GetArticuloPedidoFaltantes';
   v_idpedidoFaltante                 varchar2(3000);
    BEGIN
       --concatena en un string del arreglo de p_idpedidoFaltante
    v_idpedidoFaltante := '''' || trim(p_idpedidoFaltante(1)) || '''';
    FOR i IN 2 .. p_idpedidoFaltante.count LOOP
      v_idpedidoFaltante := v_idpedidoFaltante || ',''' || trim(p_idpedidoFaltante(i)) || '''';
    END LOOP;
    
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
      --cursor de detalle del reporte  
      OPEN p_Cursor FOR
             Select gs.cdgrupo||' - ' ||gs.dsgruposector||' ('||sec.dssector || ')' Sector,
                    --codigo de barras 
                    decode(A.difpiezas,0,
                    PKG_SLV_ARTICULO.GetCodigoDeBarra(art.cdarticulo,'UN'),
                    PKG_SLV_ARTICULO.GetCodigoDeBarra(art.cdarticulo,'KG')) barras,
                    art.cdarticulo || '- ' || des.vldescripcion Articulo,
                    PKG_SLV_Articulo.SetFormatoArticulosCod(art.cdarticulo,
                    --formato en piezas si es pesable  
                    decode(A.difpiezas,0,A.difunidad,A.difpiezas)) Cantidad,
                    posapp.n_pkg_vitalpos_materiales.GetUxB(art.cdarticulo) UXB                   
               from (
                     select detf.cdarticulo,
                            detf.idgrupo_sector,
                            sum(detf.qtunidadmedidabase-nvl(detf.qtunidadmedidabasepicking,0)) difunidad,   
                            sum(detf.qtpiezas-nvl(detf.qtpiezaspicking,0)) difpiezas
                       from tblslvpedfaltante f,
                            tblslvpedfaltantedet detf                                              
                      where f.idpedfaltante = detf.idpedfaltante
                        --estado faltante pedido no finalizado, no distribuido
                        and f.cdestado not in (C_FinalizaFaltaConsolidaPedido,C_DistribFaltaConsolidaPedido)
                        --filtra los del parametro p_idpedidoFaltante
                        and lpad(to_char(f.idpedfaltante),14,'0') in (SELECT TRIM(SUBSTR(txt,
                                           INSTR(txt, ',', 1, level) + 1,
                                           INSTR(txt, ',', 1, level + 1) -
                                           INSTR(txt, ',', 1, level) - 1)) AS u
                          FROM (SELECT replace(',' || v_idpedidoFaltante || ',', '''', '') AS txt
                                  FROM dual)
                        CONNECT BY level <=
                                   LENGTH(txt) - LENGTH(REPLACE(txt, ',', '')) - 1)
                        --valida listar solo faltantes
                        and case 
                             --verifica si es pesable 
                             when detf.qtpiezas<>0                      
                              and detf.qtpiezas-nvl(detf.qtpiezaspicking,0) <> 0 then 1
                             --verifica los no pesable
                             when detf.qtpiezas = 0                       
                              and detf.qtunidadmedidabase-nvl(detf.qtunidadmedidabasepicking,0) <> 0 then 1                     
                            end = 1 
                   group by detf.cdarticulo,
                            detf.idgrupo_sector)A,
                            sectores sec,
                            descripcionesarticulos des,
                            tblslv_grupo_sector gs, 
                            articulos art
                      where A.cdarticulo = art.cdarticulo
                        and A.idgrupo_sector = gs.idgrupo_sector
                        and sec.cdsector = gs.cdsector
                        and art.cdarticulo = des.cdarticulo
                        and gs.cdsucursal =  g_cdSucursal;
    EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       '  Error: ' || SQLERRM);
  END RepArtFaltantePedFaltante;
 /****************************************************************************************************
  * %v 24/07/2020 - ChM  Versión inicial CarretaXComi
  * %v 24/07/2020 - ChM  devuelve las carretas donde se encuentra un artículo del Comi
  *****************************************************************************************************/
  FUNCTION CarretaXComi(p_idComi          tblslvconsolidadocomi.idconsolidadocomi%type,
                        p_cdArticulo      articulos.cdarticulo%type)
                        return varchar2 is
  v_carreta          varchar2(50):='-';                        
  BEGIN                                        
    select LISTAGG(A.nrocarreta, ',') 
           WITHIN GROUP (ORDER BY A.nrocarreta) nrocarreta
      into v_carreta
      from      
         (select re.nrocarreta           
            from tblslvtarea ta,
                 tblslvremito re,
                 tblslvremitodet rd
           where ta.idtarea = re.idtarea
             and re.idremito = rd.idremito
             and rd.cdarticulo = p_cdarticulo
             and ta.idconsolidadocomi = p_idComi    
        group by re.nrocarreta)A; 
     return v_carreta;   
   EXCEPTION
    WHEN OTHERS THEN
     return '-';  
  END CarretaXComi;
  /****************************************************************************************************
  * %v 24/07/2020 - ChM  Versión inicial ClienteXGrupoXComi
  * %v 24/07/2020 - ChM  devuelve los clientes de un grupo del Comi
  *****************************************************************************************************/
  FUNCTION ClienteXGrupoXComi(p_idComi          tblslvconsolidadocomi.idconsolidadocomi%type,
                              p_grupo           number)
                        return varchar2 is
                        
  v_clientes          varchar2(3500):='-';  
                        
  BEGIN                                        
    select LISTAGG(A.cliente, ', ') 
               WITHIN GROUP (ORDER BY A.cliente) Clientes 
      into v_clientes           
      from         
           (select distinct NVL (e.dsrazonsocial, e.dsnombrefantasia)||' ('||TRIM(e.cdcuit)||')' Cliente                                                 
              from entidades                   e,                     
                   tblslvconsolidadopedido     cp,
                   tblslvconsolidadopedidorel  cprel,
                   pedidos                     pe,
                   observacionespedido         op                    
             where cp.identidad = e.identidad  
               and cp.idconsolidadopedido = cprel.idconsolidadopedido
               and pe.idpedido = cprel.idpedido
               and pe.idpedido = op.idpedido    
               and cp.idconsolidadocomi = p_idComi                                     
               and to_number(nvl(op.dsobservacion,0)) = p_grupo) A;
     return v_clientes;   
   EXCEPTION
    WHEN OTHERS THEN
     return '-';  
  END ClienteXGrupoXComi;
/*  \****************************************************************************************************
  * %v 24/07/2020 - ChM  Versión inicial GrupoArtComisionista
  * %v 24/07/2020 - ChM  lista los articulos de un comisionista por grupos
  *****************************************************************************************************\
  PROCEDURE GrupoArtComisionista(p_idComi            IN  tblslvconsolidadocomi.idconsolidadocomi%type,
                                 p_DsComisionista    OUT entidades.dsrazonsocial%type,                                   
                                 p_Cursor            OUT CURSOR_TYPE) IS

   v_modulo                           varchar2(100) := 'PKG_SLV_REPORTE.GrupoArtComisionista';
  
    BEGIN
       --descripcion del comisionista
        begin
        select to_char(cc.idconsolidadocomi)||' - '||TRIM(NVL (e.dsrazonsocial, e.dsnombrefantasia))||' ('||TRIM(e.cdcuit)||')' razonsocial
          into p_DsComisionista
          from tblslvconsolidadocomi cc,
               entidades             e 
         where cc.idcomisionista = e.identidad
           and cc.idconsolidadocomi = p_idComi
           and rownum=1;
         exception
           when others then
             p_DsComisionista:='-'; 
        end;          
      --cursor de detalle del reporte  
      OPEN p_Cursor FOR
                  select A.Grupo,               
                         PKG_SLV_REPORTE.ClienteXGrupoXComi(p_idComi,A.Grupo) Clientes,
                         A.cdarticulo || '- ' || des.vldescripcion Articulo,
                         PKG_SLV_Articulo.SetFormatoArticulosCod(A.cdarticulo,
                         --formato en piezas si es pesable  
                         decode(sum(A.qtpieza),0,sum(A.qtbase),sum(A.qtpieza))) cantidad,
                         PKG_SLV_REPORTE.CarretaXComi(p_idComi,A.cdArticulo) carreta                        
                    from
                       (select to_number(nvl(op.dsobservacion,0)) Grupo,                            
                               cpd.cdarticulo,
                               cpd.qtunidadmedidabasepicking qtbase,
                               cpd.qtpiezaspicking           qtpieza                   
                          from tblslvconsolidadopedido     cp,
                               tblslvconsolidadopedidodet  cpd,
                               tblslvconsolidadopedidorel  cprel,
                               pedidos                     pe,
                               observacionespedido         op 
                         where cp.idconsolidadopedido = cpd.idconsolidadopedido 
                           and cp.idconsolidadopedido = cprel.idconsolidadopedido
                           and pe.idpedido = cprel.idpedido
                           and pe.idpedido = op.idpedido  --falto(+)   Preguntar a LEti si es necesario incluir los nulos                                                                        
                           --solo articulos con picking
                           and nvl(cpd.qtunidadmedidabasepicking,0)>0                 
                           and cp.idconsolidadocomi = p_idComi) A,
                        descripcionesarticulos des
                  where A.cdarticulo = des.cdarticulo      
               group by A.Grupo,
                        A.cdarticulo,
                        des.vldescripcion
               order by carreta;                  
    EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       '  Error: ' || SQLERRM);
  END GrupoArtComisionista;*/
  
  
    /****************************************************************************************************
  * %v  09/09/2020 - LM. totalizado de articulos por carreta
  *****************************************************************************************************/
  PROCEDURE TotalArtComisionista(p_idComi            IN  tblslvconsolidadocomi.idconsolidadocomi%type,
                                 p_DsComisionista    OUT entidades.dsrazonsocial%type,                                   
                                 p_Cursor            OUT CURSOR_TYPE) IS

   v_modulo                           varchar2(100) := 'PKG_SLV_REPORTE.TotalArtComisionista';
  
    BEGIN
       --descripcion del comisionista
        begin
        select to_char(cc.idconsolidadocomi)||' - '||TRIM(NVL (e.dsrazonsocial, e.dsnombrefantasia))||' ('||TRIM(e.cdcuit)||')' razonsocial
          into p_DsComisionista
          from tblslvconsolidadocomi cc,
               entidades             e 
         where cc.idcomisionista = e.identidad
           and cc.idconsolidadocomi = p_idComi
           and rownum=1;
         exception
           when others then
             p_DsComisionista:='-'; 
        end;          
      --cursor de detalle del reporte  
      OPEN p_Cursor FOR
               
                select rd.cdarticulo|| '- ' || da.vldescripcion Articulo ,PKG_SLV_Articulo.SetFormatoArticulosCod(rd.cdarticulo,
                             --formato en piezas si es pesable  
                  decode(sum(nvl(rd.qtpiezaspicking,0)),0,sum(nvl(rd.qtunidadmedidabasepicking,0)),sum(nvl(rd.qtpiezaspicking,0))))  Cantidad, r.nrocarreta Carreta

                from  tblslvtarea t, tblslvremito r, tblslvremitodet rd, descripcionesarticulos da
                where   t.idconsolidadocomi=p_idComi
                and t.idtarea=r.idtarea
                and r.idremito=rd.idremito
                and rd.cdarticulo=da.cdarticulo
                group by t.idconsolidadocomi, r.nrocarreta, rd.cdarticulo, da.vldescripcion
                 order by r.nrocarreta, rd.cdarticulo;  
    EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       '  Error: ' || SQLERRM);
  END TotalArtComisionista;
  
  
  /****************************************************************************************************
  * %v 24/07/2020 - ChM  Versión inicial GrupoArtPedidoXComisionista
  * %v 24/07/2020 - ChM  lista los artículos de un comisionista por grupos y por pedidos
  * %v 09/09/2020 - LM   se corrige reporte
  *****************************************************************************************************/
  PROCEDURE GrupoArtPedidoXComisionista(p_idComi            IN  tblslvconsolidadocomi.idconsolidadocomi%type,
                                        p_DsComisionista    OUT entidades.dsrazonsocial%type,                                   
                                        p_Cursor            OUT CURSOR_TYPE) IS

   v_modulo                           varchar2(100) := 'PKG_SLV_REPORTE.GrupoArtPedidoXComisionista';
  
    BEGIN
       --descripcion del comisionista
        begin
        select to_char(cc.idconsolidadocomi)||' - '||TRIM(NVL (e.dsrazonsocial, e.dsnombrefantasia))||' ('||TRIM(e.cdcuit)||')' razonsocial
          into p_DsComisionista
          from tblslvconsolidadocomi cc,
               entidades             e 
         where cc.idcomisionista = e.identidad
           and cc.idconsolidadocomi = p_idComi
           and rownum=1;
         exception
           when others then
             p_DsComisionista:='-'; 
        end;          
      --cursor de detalle del reporte  
      OPEN p_Cursor FOR
                 
            with conforma  as(select cp.idconsolidadocomi,
                                   prel.idpedido,
                                   pcf.cdarticulo,
                                   cp.identidad,
                                   sum(pcf.qtunidadmedidabase) qtbase,
                                   sum(pcf.qtpiezas) qtpiezas
                              from tblslvconsolidadopedido cp,
                                   tblslvconsolidadopedidorel prel,
                                   tblslvpedidoconformado     pcf
                             where cp.idconsolidadopedido = prel.idconsolidadopedido
                               and pcf.idpedido = prel.idpedido
                               and cp.idconsolidadocomi is not null
                               and cp.idconsolidadocomi = p_idComi
                          group by cp.idconsolidadocomi,
                                   prel.idpedido,
                                   cp.identidad,
                                   pcf.cdarticulo
                          ),
                remito as( select A.idconsolidadocomi,--agrupo para concatenar los nrocarreta
                                  A.cdarticulo,
                                  LISTAGG(re2.nrocarreta, ' / ') WITHIN GROUP (ORDER BY re2.nrocarreta) carreta, 
                                  sum(A.qtbase) qtbase,
                                  sum(A.qtpiezas) qtpiezas
                            from (select cc.idconsolidadocomi,--agrupo para la suma del detalle remito
                                         re.idremito,
                                         rd.cdarticulo,
                                         sum(rd.qtpiezaspicking) qtpiezas,
                                         sum(rd.qtunidadmedidabasepicking) qtbase
                                    from tblslvremito                      re,
                                         tblslvremitodet                   rd,
                                         tblslvtarea                       ta,                               
                                         tblslvconsolidadocomi             cc
                                   where re.idremito = rd.idremito                
                                     and re.idtarea = ta.idtarea                          
                                     and ta.idconsolidadocomi = cc.idconsolidadocomi
                                     and ta.idconsolidadocomi = p_idComi
                                group by rd.cdarticulo,
                                         re.idremito,
                                         cc.idconsolidadocomi) A,
                                 tblslvremito re2        
                           where re2.idremito = A.idremito
                        group by A.idconsolidadocomi,
                                 A.cdarticulo  
                          )         
          select to_number(nvl(op.dsobservacion,'0')) Pedido, round(to_number( nvl(op.dsobservacion, 0)) / 100)grupo ,e.dsrazonsocial ||' ('|| e.cdcuit ||')' cliente, conforma.cdarticulo|| '- ' || des.vldescripcion Articulo,              
                 PKG_SLV_Articulo.SetFormatoArticulosCod(conforma.cdarticulo,
                 --formato en piezas si es pesable  
                 decode(sum(remito.qtpiezas),0,sum(conforma.qtbase),sum(conforma.qtpiezas))) cantidad,
                 remito.carreta                
            from conforma,             
                 remito,
                 descripcionesarticulos des, observacionespedido op, entidades e
           where conforma.idconsolidadocomi = remito.idconsolidadocomi
             and conforma.cdarticulo = remito.cdarticulo
             and conforma.cdarticulo = des.cdarticulo
             and conforma.idpedido=op.idpedido (+)
             and conforma.identidad=e.identidad
             group by e.cdcuit, e.dsrazonsocial,op.dsobservacion, conforma.cdarticulo, des.vldescripcion, remito.carreta
        order by op.dsobservacion, carreta;               
       
                
    EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       '  Error: ' || SQLERRM);
  END GrupoArtPedidoXComisionista;
  
   /****************************************************************************************************
  * %v 09/09/2020 - ChM  Versión inicial FacturadoCarretaComisionista
  * %v 09/09/2020 - ChM  lista los articulos facturados de un comisionista agrupado y ordenado por carreta
  *****************************************************************************************************/
  PROCEDURE FacturadoCarretaComisionista(p_idComi            IN  tblslvconsolidadocomi.idconsolidadocomi%type,
                                         p_CursorCAB         OUT CURSOR_TYPE,                                   
                                         p_Cursor            OUT CURSOR_TYPE) IS

   v_modulo                           varchar2(100) := 'PKG_SLV_REPORTE.FacturadoCarretaComisionista';
  
   BEGIN
      OPEN p_CursorCAB FOR    
           select distinct
                  su.dssucursal, 
                  cc.idconsolidadom    IdconsolidadoM,
                  cc.idconsolidadocomi IdconsolidadoComi,
                  trunc(cc.dtinsert)   fechaconsolidadoComi,                                    
                  TRIM(NVL (e.dsrazonsocial, e.dsnombrefantasia))||' ('||TRIM(e.cdcuit)||')' cliente                  
             from entidades                 e,
                  tblslvconsolidadocomi     cc,
                  tblslvconsolidadopedido   cp,                                 
                  sucursales                su
            where cc.idcomisionista = e.identidad
              and cc.idconsolidadocomi = cp.idconsolidadocomi             
              and cc.idconsolidadocomi = p_idComi
              and cp.cdsucursal = su.cdsucursal;    
    --cursor de detalle del reporte  
    OPEN p_Cursor FOR
      with conforma  as(select cp.idconsolidadocomi,
                               pcf.cdarticulo,
                               sum(pcf.qtunidadmedidabase) qtbase,
                               sum(pcf.qtpiezas) qtpiezas
                          from tblslvconsolidadopedido cp,
                               tblslvconsolidadopedidorel prel,
                               tblslvpedidoconformado     pcf
                         where cp.idconsolidadopedido = prel.idconsolidadopedido
                           and pcf.idpedido = prel.idpedido
                           and cp.idconsolidadocomi is not null
                           and cp.idconsolidadocomi = p_idComi
                      group by cp.idconsolidadocomi,
                               pcf.cdarticulo
                      ),
            remito as( select A.idconsolidadocomi,--agrupo para concatenar los nrocarreta
                              A.cdarticulo,
                              LISTAGG(re2.nrocarreta, ',') WITHIN GROUP (ORDER BY re2.nrocarreta) carreta, 
                              sum(A.qtbase) qtbase,
                              sum(A.qtpiezas) qtpiezas
                        from (select cc.idconsolidadocomi,--agrupo para la suma del detalle remito
                                     re.idremito,
                                     rd.cdarticulo,
                                     sum(rd.qtpiezaspicking) qtpiezas,
                                     sum(rd.qtunidadmedidabasepicking) qtbase
                                from tblslvremito                      re,
                                     tblslvremitodet                   rd,
                                     tblslvtarea                       ta,                               
                                     tblslvconsolidadocomi             cc
                               where re.idremito = rd.idremito                
                                 and re.idtarea = ta.idtarea                          
                                 and ta.idconsolidadocomi = cc.idconsolidadocomi
                                 and ta.idconsolidadocomi = p_idComi
                            group by rd.cdarticulo,
                                     re.idremito,
                                     cc.idconsolidadocomi) A,
                             tblslvremito re2        
                       where re2.idremito = A.idremito
                    group by A.idconsolidadocomi,
                             A.cdarticulo  
                      )         
      select conforma.cdarticulo|| '- ' || des.vldescripcion Articulo,              
             PKG_SLV_Articulo.SetFormatoArticulosCod(conforma.cdarticulo,
             --formato en piezas si es pesable  
             decode(remito.qtpiezas,0,remito.qtbase,remito.qtpiezas)) cantidad,
             remito.carreta                
        from conforma,             
             remito,
             descripcionesarticulos des
       where conforma.idconsolidadocomi = remito.idconsolidadocomi
         and conforma.cdarticulo = remito.cdarticulo
         and conforma.cdarticulo = des.cdarticulo
    order by carreta;               
    EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       '  Error: ' || SQLERRM);
  END FacturadoCarretaComisionista;
   
  /****************************************************************************************************
  * %v 07/09/2020 - ChM  Versión inicial DiferenciaPickeadoFacturado
  * %v 07/09/2020 - ChM  lista los articulos de un comisionista por grupos
  *****************************************************************************************************/
  PROCEDURE DiferenciaPickeadoFacturado(p_IdPedidos       IN  Tblslvconsolidadom.Idconsolidadom%type default 0,
                                        p_dtfechadesde    IN  DATE,
                                        p_dtfechahasta    IN  DATE,                       
                                        p_TipoTarea       IN  tblslvtipotarea.cdtipo%type default 0,
                                        p_Cursor          OUT CURSOR_TYPE) IS

   v_modulo                           varchar2(100) := 'PKG_SLV_REPORTE.DiferenciaPickeadoFacturado';
   v_dtDesde date;
   v_dtHasta date;
    
  BEGIN

    v_dtDesde := trunc(p_dtfechadesde);
    v_dtHasta := to_date(to_char(p_dtfechahasta, 'dd/mm/yyyy') || ' 23:59:59','dd/mm/yyyy hh24:mi:ss');
    
    if p_TipoTarea = 0 then
         OPEN p_Cursor FOR
               with conformaC  as(select cp.idconsolidadocomi,
                                         pcf.cdarticulo,
                                         sum(pcf.qtunidadmedidabase) qtbase,
                                         sum(pcf.qtpiezas) qtpiezas
                                    from tblslvconsolidadopedido cp,
                                         tblslvconsolidadopedidorel prel,
                                         tblslvpedidoconformado     pcf
                                   where cp.idconsolidadopedido = prel.idconsolidadopedido
                                     and pcf.idpedido = prel.idpedido
                                     and cp.idconsolidadocomi is not null
                                     and cp.dtinsert between v_dtDesde and v_dtHasta    
                                group by cp.idconsolidadocomi,
                                         pcf.cdarticulo),
                        consoC as(select cp.idconsolidadocomi,
                                         cpd.cdarticulo,
                                         sum(cpd.qtunidadmedidabasepicking) qtbase,
                                         sum(cpd.qtpiezaspicking) qtpiezas
                                    from tblslvconsolidadopedido cp,
                                         tblslvconsolidadopedidodet cpd
                                   where cp.idconsolidadopedido = cpd.idconsolidadopedido
                                     and cp.idconsolidadocomi is not null
                                     and cp.dtinsert between v_dtDesde and v_dtHasta    
                                group by cp.idconsolidadocomi,
                                         cpd.cdarticulo                           
                                  ),
                     conforma as (select cp.idconsolidadopedido,
                                         pcf.cdarticulo,
                                         sum(pcf.qtunidadmedidabase) qtbase,
                                         sum(pcf.qtpiezas) qtpiezas
                                    from tblslvconsolidadopedido cp,
                                         tblslvconsolidadopedidorel prel,
                                         tblslvpedidoconformado     pcf
                                   where cp.idconsolidadopedido = prel.idconsolidadopedido
                                     and pcf.idpedido = prel.idpedido
                                     and cp.idconsolidadocomi is null
                                     and cp.dtinsert between v_dtDesde and v_dtHasta   
                                group by cp.idconsolidadopedido,
                                         pcf.cdarticulo),
                   consopedido as(select cp.idconsolidadopedido,
                                         cpd.cdarticulo,
                                         cpd.qtunidadmedidabasepicking qtbase,
                                         cpd.qtpiezaspicking qtpiezas
                                    from tblslvconsolidadopedido cp,
                                         tblslvconsolidadopedidodet cpd
                                   where cp.idconsolidadopedido = cpd.idconsolidadopedido
                                   	 and cp.idconsolidadocomi is null
                                     and cp.dtinsert between v_dtDesde and v_dtHasta   
                                  )                                  
                select (select tt.dstarea||': '
                          from tblslvtipotarea tt 
                         where tt.cdtipo = c_TareaConsolidadoComi)||
                       conformaC.idconsolidadocomi     ||' - '||
                       to_char(cc.dtinsert,'dd/mm/yyyy') ||' - '||
                       NVL (e.dsrazonsocial, e.dsnombrefantasia)||' ('||TRIM(e.cdcuit)||')'  idconsolidado,
                       conformaC.cdarticulo|| '- ' || des.vldescripcion Articulo,
                       --valida pesable 
                       decode(conformaC.qtpiezas,0,conformaC.qtbase,conformaC.qtpiezas) cantidad_conformado, 
                       decode(consoC.qtpiezas,0,consoC.qtbase,consoC.qtpiezas) cantidad_consopedido    
                  from conformaC,
                       consoC,             
                       descripcionesarticulos des,
                       entidades              e,
                       tblslvconsolidadocomi  cc
                 where conformaC.idconsolidadocomi = consoC.idconsolidadocomi(+)
                   and conformaC.cdarticulo = consoC.cdarticulo(+)  
                   and conformaC.cdarticulo = des.cdarticulo 
                   and e.identidad = cc.idcomisionista
                   and cc.idconsolidadocomi = consoC.idconsolidadocomi             
                   -- revisa diferencias con consopedido
                   and (conformaC.qtbase-consoC.qtbase <> 0 or conformaC.qtpiezas- consoC.qtpiezas <> 0)
       UNION ALL                 
                select (select tt.dstarea||': '
                          from tblslvtipotarea tt 
                         where tt.cdtipo = c_TareaConsolidadoPedido)||
                       conforma.idconsolidadopedido ||' - '||
                       to_char(cp.dtinsert,'dd/mm/yyyy') ||' - '||
                       NVL (e.dsrazonsocial, e.dsnombrefantasia)||' ('||TRIM(e.cdcuit)||')' idconsolidado,                
                       conforma.cdarticulo|| '- ' || des.vldescripcion Articulo,
                       --valida pesable 
                       decode(conforma.qtpiezas,0,conforma.qtbase,conforma.qtpiezas) cantidad_conformado, 
                       decode(consopedido.qtpiezas,0,consopedido.qtbase,consopedido.qtpiezas) cantidad_consopedido     
                  from conforma,
                       consopedido,
                       descripcionesarticulos  des,
                       entidades               e,
                       tblslvconsolidadopedido cp
                 where conforma.idconsolidadopedido = consopedido.idconsolidadopedido(+)
                   and conforma.cdarticulo = consopedido.cdarticulo(+) 
                   and conforma.cdarticulo = des.cdarticulo
                   and e.identidad = cp.identidad
                   and cp.idconsolidadopedido = consopedido.idconsolidadopedido
                   --revisa diferencias con consopedido
                   and (conforma.qtbase-consopedido.qtbase <> 0 or conforma.qtpiezas- consopedido.qtpiezas <> 0)
              order by idconsolidado,
                       ARTICULO;
    end if;
    
    
       if p_TipoTarea = c_TareaConsolidadoComi then
         OPEN p_Cursor FOR
          with conforma  as(select cp.idconsolidadocomi,
                                   pcf.cdarticulo,
                                   sum(pcf.qtunidadmedidabase) qtbase,
                                   sum(pcf.qtpiezas) qtpiezas
                              from tblslvconsolidadopedido cp,
                                   tblslvconsolidadopedidorel prel,
                                   tblslvpedidoconformado     pcf
                             where cp.idconsolidadopedido = prel.idconsolidadopedido
                               and pcf.idpedido = prel.idpedido
                               and cp.idconsolidadocomi is not null
                               and cp.idconsolidadocomi = p_IdPedidos
                          group by cp.idconsolidadocomi,
                                   pcf.cdarticulo),
             consopedido as(select cp.idconsolidadocomi,
                                   cpd.cdarticulo,
                                   sum(cpd.qtunidadmedidabasepicking) qtbase,
                                   sum(cpd.qtpiezaspicking) qtpiezas
                              from tblslvconsolidadopedido cp,
                                   tblslvconsolidadopedidodet cpd
                             where cp.idconsolidadopedido = cpd.idconsolidadopedido
                               and cp.idconsolidadocomi is not null
                               and cp.idconsolidadocomi = p_IdPedidos
                          group by cp.idconsolidadocomi,
                                   cpd.cdarticulo                           
                            )             
          select (select tt.dstarea||': '
                    from tblslvtipotarea tt 
                   where tt.cdtipo = c_TareaConsolidadoComi)||
                 conforma.idconsolidadocomi     ||' - '||
                 to_char(cc.dtinsert,'dd/mm/yyyy') ||' - '||
                 NVL (e.dsrazonsocial, e.dsnombrefantasia)||' ('||TRIM(e.cdcuit)||')'  idconsolidado,
                 conforma.cdarticulo|| '- ' || des.vldescripcion Articulo,
                 --valida pesable 
                 decode(conforma.qtpiezas,0,conforma.qtbase,conforma.qtpiezas) cantidad_conformado, 
                 decode(consopedido.qtpiezas,0,consopedido.qtbase,consopedido.qtpiezas) cantidad_consopedido    
            from conforma,
                 consopedido,             
                 descripcionesarticulos des,
                 entidades              e,
                 tblslvconsolidadocomi  cc
           where conforma.idconsolidadocomi = consopedido.idconsolidadocomi(+)
             and conforma.cdarticulo = consopedido.cdarticulo(+)  
             and conforma.cdarticulo = des.cdarticulo 
             and e.identidad = cc.idcomisionista
             and cc.idconsolidadocomi = consopedido.idconsolidadocomi               
             -- revisa diferencias con consopedido
             and (conforma.qtbase-consopedido.qtbase <> 0 or conforma.qtpiezas- consopedido.qtpiezas <> 0)
           order by conforma.idconsolidadocomi,
                    conforma.cdarticulo;
         end if;
       if p_TipoTarea = c_TareaConsolidadoPedido then
         OPEN p_Cursor FOR
           with conforma  as (select cp.idconsolidadopedido,
                                     pcf.cdarticulo,
                                     sum(pcf.qtunidadmedidabase) qtbase,
                                     sum(pcf.qtpiezas) qtpiezas
                                from tblslvconsolidadopedido cp,
                                     tblslvconsolidadopedidorel prel,
                                     tblslvpedidoconformado     pcf
                               where cp.idconsolidadopedido = prel.idconsolidadopedido
                                 and pcf.idpedido = prel.idpedido
                                 and cp.idconsolidadocomi is null
                                 and cp.idconsolidadopedido = p_IdPedidos
                            group by cp.idconsolidadopedido,
                                     pcf.cdarticulo),
               consopedido as(select cp.idconsolidadopedido,
                                     cpd.cdarticulo,
                                     cpd.qtunidadmedidabasepicking qtbase,
                                     cpd.qtpiezaspicking qtpiezas
                                from tblslvconsolidadopedido cp,
                                     tblslvconsolidadopedidodet cpd
                               where cp.idconsolidadopedido = cpd.idconsolidadopedido
                                 and cp.idconsolidadocomi is null
                                 and cp.idconsolidadopedido = p_IdPedidos
                              )             
            select (select tt.dstarea||': '
                      from tblslvtipotarea tt 
                     where tt.cdtipo = c_TareaConsolidadoPedido)||
                   conforma.idconsolidadopedido ||' - '||
                   to_char(cp.dtinsert,'dd/mm/yyyy') ||' - '||
                   NVL (e.dsrazonsocial, e.dsnombrefantasia)||' ('||TRIM(e.cdcuit)||')'  idconsolidado,
                   conforma.cdarticulo|| '- ' || des.vldescripcion Articulo,
                   --valida pesable 
                   decode(conforma.qtpiezas,0,conforma.qtbase,conforma.qtpiezas) cantidad_conformado, 
                   decode(consopedido.qtpiezas,0,consopedido.qtbase,consopedido.qtpiezas) cantidad_consopedido     
              from conforma,
                   consopedido,
                   descripcionesarticulos  des,
                   entidades               e,
                   tblslvconsolidadopedido cp
             where conforma.idconsolidadopedido = consopedido.idconsolidadopedido(+)
               and conforma.cdarticulo = consopedido.cdarticulo(+) 
               and conforma.cdarticulo = des.cdarticulo
               and e.identidad = cp.identidad
               and cp.idconsolidadopedido = consopedido.idconsolidadopedido
               --revisa diferencias con consopedido
               and (conforma.qtbase-consopedido.qtbase <> 0 or conforma.qtpiezas- consopedido.qtpiezas <> 0)
          order by conforma.idconsolidadopedido,
                   conforma.cdarticulo;
         end if;  
    EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       '  Error: ' || SQLERRM);
  END DiferenciaPickeadoFacturado; 
  

/****************************************************************************************************
  * %v 21/09/2020 - ChM  Versión inicial FaltanteRealXFecha
  * %v 21/09/2020 - ChM  lista las diferencias del conformado y pedido pos
  *****************************************************************************************************/
  PROCEDURE FaltanteRealXFecha(p_dtfechadesde      IN  DATE,
                               p_dtfechahasta      IN  DATE, 
                         --     p_idconsolidadoPedi IN  tblslvconsolidadopedido.idconsolidadopedido%type default 0,
                     --          p_idconsolidadoComi IN  tblslvconsolidadopedido.idconsolidadopedido%type default 0,
                               p_Cursor          OUT CURSOR_TYPE)
                               is
    v_modulo                           varchar2(100) := 'PKG_SLV_REPORTE.FaltanteRealXFecha';
   v_dtDesde date;
   v_dtHasta date;
    
  BEGIN

    v_dtDesde := trunc(p_dtfechadesde);
    v_dtHasta := to_date(to_char(p_dtfechahasta, 'dd/mm/yyyy') || ' 23:59:59','dd/mm/yyyy hh24:mi:ss');
                                         
     OPEN p_Cursor FOR
          with conforma as  ( select A.idpedido,
                                     A.cdarticulo,
                                     sum(A.qtpiezas) qtpiezas,
                                     sum(A.qtbase) qtbase
                                from (select pc.idpedido,          	                                                                        
                                             pc.cdarticulo,
                                             pc.qtpiezas qtpiezas,
                                             pc.qtunidadmedidabase qtbase             
                                        from tblslvpedidoconformado      pc,
                                             tblslvconsolidadopedidorel  prel,
                                             tblslvconsolidadopedido     cp
                                       where pc.idpedido = prel.idpedido
                                         and prel.idconsolidadopedido = cp.idconsolidadopedido                                 
                                         --solo pedidos facturados
                                         and cp.cdestado in (13,14)
                                         -- Excluyo pedidos generados por faltantes de Comi
                                         and not exists (select 1 
                                                           from tblslvpedidogeneradoxfaltante pgf
                                                           where pgf.idpedidogen=pc.idpedido
                                                 )
                                         and cp.dtinsert between v_dtDesde and v_dtHasta 
                                   --      and (p_idconsolidadoPedi=0 or cp.idconsolidadopedido = p_idconsolidadoPedi)
                                 --        and (p_idconsolidadoComi=0 or cp.idconsolidadocomi = p_idconsolidadoComi) 
                                   union all 
                                      --agrego suma de articulos de pedidos de faltantes de comi
                                      select pgf.idpedido,                                                                                    
                                             pc.cdarticulo,
                                             pc.qtpiezas qtpiezas,
                                             pc.qtunidadmedidabase qtbase             
                                        from tblslvpedidoconformado        pc,
                                             tblslvconsolidadopedidorel    prel,
                                             tblslvconsolidadopedido       cp,
                                             tblslvpedidogeneradoxfaltante pgf
                                       where pc.idpedido = prel.idpedido
                                         and pc.idpedido = pgf.idpedidogen
                                         and prel.idconsolidadopedido = cp.idconsolidadopedido                                 
                                         --solo pedidos facturados
                                         and cp.cdestado in (13,14)
                                         and cp.dtinsert between v_dtDesde and v_dtHasta                                   
                                      ) A                                        
                             group by A.idpedido,                                                                        
                                      A.cdarticulo  
                             ),
                  pedido as  (select p.idpedido,
                                     cp.dtinsert,
                                     dp.cdarticulo,
                                     cp.cdsucursal,
                                     sum(dp.qtpiezas) qtpiezas,
                                     sum(dp.qtunidadmedidabase) qtbase,
                                     avg(dp.ampreciounitario) precioun           
                                from pedidos                     p,
                                     detallepedidos              dp,
                                     tblslvconsolidadopedidorel  prel,
                                     tblslvconsolidadopedido     cp
                               where p.idpedido = dp.idpedido    
                                 and p.idpedido = prel.idpedido
                                 and cp.idconsolidadopedido = prel.idconsolidadopedido
                                 --excluyo linea de promo
                                 and dp.icresppromo = 0 
                                 --solo pedidos facturados
                                 and cp.cdestado in (13,14)
                                 -- Excluyo pedidos generados por faltantes de Comi
                                 and  not exists (select 1 
                                                    from tblslvpedidogeneradoxfaltante pgf
                                                    where pgf.idpedidogen=p.idpedido
                                                 )                                                       
                                 and cp.dtinsert between v_dtDesde and v_dtHasta 
                            --     and (p_idconsolidadoPedi=0 or cp.idconsolidadopedido = p_idconsolidadoPedi)
                            --     and (p_idconsolidadoComi=0 or cp.idconsolidadocomi = p_idconsolidadoComi)                                     
                            group by p.idpedido,
                                     cp.dtinsert,
                                     cp.cdsucursal,
                                     dp.cdarticulo)    
                select su.dssucursal sucursal,
                       to_char(pe.dtinsert,'dd/mm/yyyy') FechaConsolidado,
                       sec.dssector Sector, 
                       pe.cdarticulo || '- ' || des.vldescripcion Articulo,
                       round(avg(pe.precioun),3) preciounitario,
                       PKG_SLV_Articulo.SetFormatoArticulosCod(pe.cdarticulo,
                       --valida pesables
                       sum(decode(pe.qtpiezas,0,pe.qtbase,pe.qtpiezas))) unidades_pedidas,
                       PKG_SLV_Articulo.SetFormatoArticulosCod(pe.cdarticulo,
                       --valida pesables
                       nvl(sum(decode(co.qtpiezas,0,co.qtbase,co.qtpiezas)),0)) unidades_pickeadas,
                       PKG_SLV_Articulo.SetFormatoArticulosCod(pe.cdarticulo,
                       abs(sum((nvl(decode(co.qtpiezas,0,co.qtbase,co.qtpiezas),0)-decode(pe.qtpiezas,0,pe.qtbase,pe.qtpiezas))))) Faltantes,                   
                       posapp.n_pkg_vitalpos_materiales.GetUxB(pe.cdarticulo) UXB,
                       PKG_SLV_Articulo.GetUbicacionArticulos(pe.cdarticulo) UBICACION                            
                  from pedido                 pe
                  left join(conforma          co)
                       on (    co.idpedido = pe.idpedido
                           and co.cdarticulo = pe.cdarticulo),
                       sucursales             su,
                       articulos              art,
                       descripcionesarticulos des,                                    
                       sectores               sec
                 where pe.cdsucursal = su.cdsucursal 
                   and art.cdarticulo = pe.cdarticulo
                   and art.cdsector = sec.cdsector              
                   and art.cdarticulo = des.cdarticulo
                   and case 
                         --verifica si es pesable 
                          when pe.qtpiezas<>0
                           and (nvl(co.qtpiezas,0)-pe.qtpiezas <> 0) then 1
                          --verifica los no pesable
                          when pe.qtpiezas = 0 
                           and (nvl(co.qtbase,0)-pe.qtbase <> 0)  then 1
                       else 0    
                       end = 1  
              group by su.dssucursal, 
                       to_char(pe.dtinsert,'dd/mm/yyyy'),
                       sec.dssector,
                       pe.cdarticulo,
                       pe.cdarticulo || '- ' || des.vldescripcion                    
              order by to_date(FechaConsolidado,'dd/mm/yyyy') desc,
                       Sector;   
   EXCEPTION
    WHEN OTHERS THEN
     n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       '  Error: ' || SQLERRM);
  END FaltanteRealXFecha;  
END PKG_SLV_REPORTE;
/
