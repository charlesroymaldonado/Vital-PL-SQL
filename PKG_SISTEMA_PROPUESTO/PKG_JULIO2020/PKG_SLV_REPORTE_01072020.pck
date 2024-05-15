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
          select pfr.idconsolidadopedido,'(' || trim(e.cdcuit) ||')' || e.dsrazonsocial as Cliente,   gs.cdgrupo || ' - ' || gs.dsgruposector || ' (' ||
               sec.dssector || ')' Sector,
               --codigo de barras 
               decode(dpf.qtpiezas,0,
               PKG_SLV_ARTICULO.GetCodigoDeBarra(dpf.cdarticulo,'UN'),
               PKG_SLV_ARTICULO.GetCodigoDeBarra(dpf.cdarticulo,'KG')) barras,
               dpf.cdarticulo || '- ' || da.vldescripcion articulo,
               PKG_SLV_Articulo.SetFormatoArticulosCod(dpf.cdarticulo,dpf.qtunidadmedidabase) cantidad, --ojo, no contemplo piezas
               posapp.n_pkg_vitalpos_materiales.GetUxB(dpf.cdarticulo) UXB,
               r.idremito nroRemito
          from tblslvdistribucionpedfaltante dpf, 
               tblslvpedfaltanterel pfr, 
               tblslvconsolidadopedido cp, 
               entidades e, 
               descripcionesarticulos da,
               sectores sec,
               tblslv_grupo_sector gs,
               articulos art, 
               tblslvremito r
          where dpf.idpedfaltanterel=pfr.idpedfaltanterel
          and pfr.idconsolidadopedido=cp.idconsolidadopedido
          and pfr.idpedfaltante=p_idconsFaltantes
          and cp.identidad=e.identidad
          and dpf.cdarticulo=da.cdarticulo
          and dpf.cdarticulo=art.cdarticulo
          and art.cdsector = sec.cdsector          
          and sec.cdsector = gs.cdsector 
          and r.idpedfaltanterel=pfr.idpedfaltanterel
          order by pfr.idconsolidadopedido, gs.cdgrupo, dpf.cdarticulo;
      p_Ok    := 1;
      p_error := null;       
  EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       'Detalle Error: ' || v_error ||
                                       '  Error: ' || SQLERRM);
      p_Ok:=0;
      p_error:='No es posible mostrar la distribucion de los faltantes. Comuniquese con Sistemas.';
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

  
  
  
  
  
  
  
  
  
  
END PKG_SLV_REPORTE;
/
