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
                                                                        
  PROCEDURE GrupoArtComisionista(p_idComi            IN  tblslvconsolidadocomi.idconsolidadocomi%type,
                                 p_DsComisionista    OUT entidades.dsrazonsocial%type,                                   
                                 p_Cursor            OUT CURSOR_TYPE);
                                 
  PROCEDURE GrupoArtPedidoXComisionista(p_idComi            IN  tblslvconsolidadocomi.idconsolidadocomi%type,
                                        p_DsComisionista    OUT entidades.dsrazonsocial%type,                                   
                                        p_Cursor            OUT CURSOR_TYPE);                                 
                                 
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
  /****************************************************************************************************
  * %v 24/07/2020 - ChM  Versión inicial GrupoArtComisionista
  * %v 24/07/2020 - ChM  lista los articulos de un comisionista por grupos
  *****************************************************************************************************/
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
                        des.vldescripcion;           
    EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       '  Error: ' || SQLERRM);
  END GrupoArtComisionista;
  
  ----------------------------------------------------------------------
  /****************************************************************************************************
  * %v 24/07/2020 - ChM  Versión inicial GrupoArtPedidoXComisionista
  * %v 24/07/2020 - ChM  lista los artículos de un comisionista por grupos y por pedidos
  *****************************************************************************************************/
  PROCEDURE GrupoArtPedidoXComisionista(p_idComi            IN  tblslvconsolidadocomi.idconsolidadocomi%type,
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
                         A.idconsolidadopedido Pedido,    
                         A.Cliente,
                         A.cdarticulo || '- ' || des.vldescripcion Articulo,
                         PKG_SLV_Articulo.SetFormatoArticulosCod(A.cdarticulo,
                         --formato en piezas si es pesable  
                         decode(sum(A.qtpieza),0,sum(A.qtbase),sum(A.qtpieza))) cantidad,
                         PKG_SLV_REPORTE.CarretaXComi(p_idComi,A.cdArticulo) carreta                        
                    from
                       (select to_number(nvl(op.dsobservacion,0)) grupo,                               
                               cp.idconsolidadopedido,
                               TRIM(NVL (e.dsrazonsocial, e.dsnombrefantasia))||' ('||TRIM(e.cdcuit)||')' Cliente,                              
                               cpd.cdarticulo,
                               cpd.qtunidadmedidabasepicking qtbase,
                               cpd.qtpiezaspicking           qtpieza                   
                          from tblslvconsolidadopedido     cp,
                               entidades                   e,
                               tblslvconsolidadopedidodet  cpd,
                               tblslvconsolidadopedidorel  cprel,
                               pedidos                     pe,
                               observacionespedido         op
                         where cp.idconsolidadopedido = cpd.idconsolidadopedido                         
                           and cp.identidad = e.identidad
                           and cp.idconsolidadopedido = cprel.idconsolidadopedido
                           and pe.idpedido = cprel.idpedido                        
                           and pe.idpedido = op.idpedido --falto(+)   Preguntar a LEti si es necesario incluir los nulos 
                           --solo articulos con picking
                           and nvl(cpd.qtunidadmedidabasepicking,0)>0                                           
                           and cp.idconsolidadocomi = p_idComi) A,
                        descripcionesarticulos des                        
                  where A.cdarticulo = des.cdarticulo                              
               group by A.Grupo,
                        A.idconsolidadopedido,
                        A.Cliente,                        
                        A.cdarticulo,
                        des.vldescripcion
               order by A.idconsolidadopedido;                        
                
    EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       '  Error: ' || SQLERRM);
  END GrupoArtPedidoXComisionista;
  
  
  
  
  
  
  
  
  
  
END PKG_SLV_REPORTE;
/
