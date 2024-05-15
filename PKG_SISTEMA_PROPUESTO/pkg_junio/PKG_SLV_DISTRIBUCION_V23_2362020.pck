CREATE OR REPLACE PACKAGE PKG_SLV_DISTRIBUCION is
  /**********************************************************************************************************
  * Author  : CMALDONADO_C
  * Created : 29/05/2020 12:50:03 p.m.
  * %v Paquete para la DISTRIBUCION de pedidos en SLV
  **********************************************************************************************************/
  -- Tipos de datos

  TYPE CURSOR_TYPE IS REF CURSOR;
  --tabla en memoria para la distribución de los pesables
   TYPE PESABLE IS RECORD   (
    IDCONSOLIDADOPEDIDO     TBLSLVCONSOLIDADOPEDIDO.IDCONSOLIDADOPEDIDO%TYPE,
    CDARTICULO              TBLSLVCONSOLIDADOPEDIDODET.CDARTICULO%TYPE,
    QTUNIDADMEDIDABASEPIK   TBLSLVCONSOLIDADOPEDIDODET.QTUNIDADMEDIDABASEPICKING%TYPE,
    QTPIEZASPIK             TBLSLVCONSOLIDADOPEDIDODET.QTPIEZASPICKING%TYPE,
    BANDERA                 INTEGER
    );

   TYPE PESABLES IS TABLE OF PESABLE INDEX BY BINARY_INTEGER;
   PESABLES_P PESABLES;
   PESABLES_F PESABLES;
   PESABLES_C PESABLES;
                                
 PROCEDURE  SetDistribucion     (p_idpersona     IN personas.idpersona%type,
                                 p_Idconsolidado IN Tblslvconsolidadopedido.Idconsolidadopedido%type,
                                 p_TipoTarea     IN tblslvtipotarea.cdtipo%type,
                                 p_Ok            OUT number,
                                 p_error         OUT varchar2);                                                              
  --USO INTERNO DEL PKG
  
  FUNCTION SecuenciaPedConformado(p_idpedido          tblslvpedidoconformado.idpedido%type)
                                  return number;
  FUNCTION MarcaPromoP(p_idconsolidado     tblslvconsolidadom.idconsolidadom%type,
                       p_CdArticulo        articulos.cdarticulo%type)
                       return integer;                                  
                                  
  FUNCTION TotalArtConsolidado(p_idconsolidado    tblslvconsolidadom.idconsolidadom%type,
                               p_CdArticulo        articulos.cdarticulo%type)
                                return number; 
                                 
  FUNCTION MarcaPromoC(p_idconsolidado     tblslvconsolidadom.idconsolidadom%type,
                       p_CdArticulo        articulos.cdarticulo%type)
                       return integer;
                                                       
  FUNCTION TotalArtComi(p_idconsolidado     tblslvconsolidadom.idconsolidadom%type,
                        p_CdArticulo        articulos.cdarticulo%type)
                        return number;  
                        
  FUNCTION MarcaPromoF(p_idconsolidado     tblslvconsolidadom.idconsolidadom%type,
                       p_CdArticulo        articulos.cdarticulo%type)
                       return integer;                                                                                                                       
                                   
  FUNCTION TotalArtfaltante(p_idconsolidado     tblslvconsolidadom.idconsolidadom%type,
                            p_CdArticulo        articulos.cdarticulo%type)
                                return number;                                                          
                                
-- BORRAR Solo PARA DESARROLLO

end PKG_SLV_DISTRIBUCION;
/
CREATE OR REPLACE PACKAGE BODY PKG_SLV_DISTRIBUCION is
  /***************************************************************************************************
  *  %v 29/05/2020  ChM - Parametros globales privados
  ****************************************************************************************************/
  c_TareaConsolidadoPedido           CONSTANT tblslvtipotarea.cdtipo%type := 25;
  c_TareaConsolidaPedidoFaltante     CONSTANT tblslvtipotarea.cdtipo%type := 40;
  c_TareaConsolidadoComi             CONSTANT tblslvtipotarea.cdtipo%type := 50;
   
  C_FinalizaFaltaConsolidaPedido     CONSTANT tblslvestado.cdestado%type := 20;
  C_DistribFaltanteConsolidaPed      CONSTANT tblslvestado.cdestado%type := 21;
  C_CerradoConsolidadoPedido         CONSTANT tblslvestado.cdestado%type := 12;
  C_AFacturarConsolidadoPedido       CONSTANT tblslvestado.cdestado%type := 13;
  C_FinalizadoConsolidadoComi        CONSTANT tblslvestado.cdestado%type := 27;
  C_DistribuidoConsolidadoComi       CONSTANT tblslvestado.cdestado%type := 28;
   
  /****************************************************************************************************
  * %v 19/06/2020 - ChM  Versión inicial SecuenciaPedConformado
  * %v 19/06/2020 - ChM  devuelve el max valor del item de la secuencia en tblslvPedidoConformado         
  *****************************************************************************************************/ 
  FUNCTION SecuenciaPedConformado(p_idpedido          tblslvpedidoconformado.idpedido%type)
                                  return number is
                                  
   v_item                    tblslvpedidoconformado.sqdetallepedido%type:=0;
                               
  BEGIN
    select nvl(max(pc.sqdetallepedido),0)
      into v_item 
      from tblslvPedidoConformado  pc
     where pc.idpedido=p_idpedido;
  RETURN v_item;
     EXCEPTION
    WHEN OTHERS THEN
      RETURN v_item;
  END SecuenciaPedConformado;
  
  /****************************************************************************************************
  * %v 23/06/2020 - ChM  Versión inicial MarcaPromoP
  * %v 23/06/2020 - ChM  si el articulo es promo lo marca en tblslvporcdistrb              
  *****************************************************************************************************/ 
  FUNCTION MarcaPromoP(p_idconsolidado     tblslvconsolidadom.idconsolidadom%type,
                       p_CdArticulo        articulos.cdarticulo%type)
                       return integer is
                                
   v_promo                  integer:=0;
                               
  BEGIN
     select 1
       into v_promo           
       from tblslvconsolidadopedido cp,
            tblslvconsolidadopedidorel prel,
            pedidos p,
            detallepedidos dp
      where p.idpedido = dp.idpedido
        and p.idpedido = prel.idpedido
        --  solo promociones
        and dp.icresppromo <> 0
        and cp.idconsolidadopedido = prel.idconsolidadopedido
        and cp.idconsolidadopedido = p_Idconsolidado
        and dp.cdarticulo = p_cdarticulo
        and rownum=1;
  RETURN nvl(v_promo,0);
     EXCEPTION
    WHEN OTHERS THEN
     RETURN nvl(v_promo,0);
  END MarcaPromoP;
  
  
  /****************************************************************************************************
  * %v 29/05/2020 - ChM  Versión inicial TotalArtConsolidado
  * %v 29/05/2020 - ChM  calcula el total en qtbase de un artículo para un consolidado pedido               
  *****************************************************************************************************/ 
  FUNCTION TotalArtConsolidado(p_idconsolidado     tblslvconsolidadom.idconsolidadom%type,
                               p_CdArticulo        articulos.cdarticulo%type)
                                return number is
                                
   v_cantArt                    number(14,2):=-1;
                               
  BEGIN
    select nvl(sum(dp.qtunidadmedidabase),-1) qtbase
      into v_cantArt
      from tblslvconsolidadopedido cp,
           tblslvconsolidadopedidorel prel,
           pedidos p,
           detallepedidos dp
     where p.idpedido = dp.idpedido
       and p.idpedido = prel.idpedido
       and cp.idconsolidadopedido = prel.idconsolidadopedido
       and cp.idconsolidadopedido = p_Idconsolidado   
       and dp.cdarticulo = p_CdArticulo;
  RETURN V_cantArt;
     EXCEPTION
    WHEN OTHERS THEN
      RETURN V_cantArt;
  END TotalArtConsolidado;
  
  /****************************************************************************************************
  * %v 29/05/2020 - ChM  Versión inicial PorcDistribConsolidado
  * %v 29/05/2020 - ChM  calcula el procentaje de participación en
  *                      un articulo de pedido con respecto a todo el consolidadopedido
  *****************************************************************************************************/ 
  PROCEDURE PorcDistribConsolidado(p_idconsolidado       IN  tblslvconsolidadom.idconsolidadom%type,
                                   p_Ok                  OUT number,
                                   p_error               OUT varchar2) is
                           
    v_modulo       varchar2(100) := 'PKG_SLV_DISTRIBUCION.PorcDistribConsolidado';
    v_error        varchar2(250);
    
  BEGIN
  v_error:=' Error en insert tblslvpordistrib';
  
  --borro porcentajes para el consolidado
  delete tblslvpordistrib pdf
   where pdf.idconsolidado = p_idconsolidado
     and pdf.cdtipo = c_TareaConsolidadoPedido;
   
  insert into tblslvpordistrib
              (idpedido,
               idconsolidado,
               cdtipo,
               cdarticulo,
               qtunidadmedidabase,
               totalconsolidado,
               porcdist,
               dtinsert,
               artpromo)
       select p.idpedido,
              cp.idconsolidadopedido,
              c_TareaConsolidadoPedido,
              dp.cdarticulo,
              sum(dp.qtunidadmedidabase) qtbase,
              TotalArtConsolidado(p_idconsolidado,dp.cdarticulo) totalart,
              sum(dp.qtunidadmedidabase)/
              TotalArtConsolidado(p_idconsolidado,dp.cdarticulo) porc,
              sysdate,
              MarcaPromoP(p_idconsolidado,dp.cdarticulo)
         from tblslvconsolidadopedido cp,
              tblslvconsolidadopedidorel prel,
              pedidos p,
              detallepedidos dp
        where p.idpedido = dp.idpedido
          and p.idpedido = prel.idpedido
          and cp.idconsolidadopedido = prel.idconsolidadopedido
          and cp.idconsolidadopedido = p_Idconsolidado   
     group by p.idpedido,
              cp.idconsolidadopedido,
              dp.cdarticulo;
      IF SQL%ROWCOUNT = 0  THEN      
          n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       '  Detalle Error: ' || v_error);
   	      p_Ok:=0;
          p_error:='Error en insert tblslvpordistrib. Comuniquese con Sistemas!';
          ROLLBACK;
          RETURN;
       END IF; 
  --     
       
       
       
    p_Ok:=1;
    p_error:='';
    COMMIT;        
  EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       '  Detalle Error: ' || v_error ||
                                       '  Error: ' || SQLERRM);
      ROLLBACK;
  END PorcDistribConsolidado;
  
   /****************************************************************************************************
  * %v 23/06/2020 - ChM  Versión inicial MarcaPromoC
  * %v 23/06/2020 - ChM  si el articulo es promo lo marca en tblslvporcdistrb              
  *****************************************************************************************************/ 
  FUNCTION MarcaPromoC(p_idconsolidado     tblslvconsolidadom.idconsolidadom%type,
                       p_CdArticulo        articulos.cdarticulo%type)
                       return integer is
                                
   v_promo                  integer:=0;
                               
  BEGIN
    select 1
      into v_promo             
      from tblslvconsolidadopedido cp,          
           tblslvconsolidadopedidorel prel,
           tblslvconsolidadocomi cc,
           tblslvconsolidadocomidet ccd,
           pedidos p,
           detallepedidos dp
     where p.idpedido = dp.idpedido
       and p.idpedido = prel.idpedido
       and cp.idconsolidadopedido = prel.idconsolidadopedido       
       and cc.idconsolidadocomi = cp.idconsolidadocomi
       and cc.idconsolidadocomi = ccd.idconsolidadocomi
        --incluyo solo promo son los diferentes de cero
       and dp.icresppromo <> 0 
       and ccd.cdarticulo = dp.cdarticulo  
       and cc.idconsolidadocomi = p_Idconsolidado      
       and ccd.cdarticulo = p_CdArticulo
       and rownum=1;
  RETURN nvl(v_promo,0);
     EXCEPTION
    WHEN OTHERS THEN
     RETURN nvl(v_promo,0);
  END MarcaPromoC;
  
  /****************************************************************************************************
  * %v 19/06/2020 - ChM  Versión inicial TotalArtComi
  * %v 19/06/2020 - ChM  calcula el total en qtbase de un artículo para un consolidado Comisionista               
  *****************************************************************************************************/ 
  FUNCTION TotalArtComi(p_idconsolidado     tblslvconsolidadom.idconsolidadom%type,
                        p_CdArticulo        articulos.cdarticulo%type)
                        return number is
   v_cantArt                    number(14,2):=-1;
                               
  BEGIN
    select nvl(sum(dp.qtunidadmedidabase),-1) qtbase
      into v_cantArt
      from tblslvconsolidadopedido cp,          
           tblslvconsolidadopedidorel prel,
           tblslvconsolidadocomi cc,
           tblslvconsolidadocomidet ccd,
           pedidos p,
           detallepedidos dp
     where p.idpedido = dp.idpedido
       and p.idpedido = prel.idpedido
       and cp.idconsolidadopedido = prel.idconsolidadopedido       
       and cc.idconsolidadocomi = cp.idconsolidadocomi
       and cc.idconsolidadocomi = ccd.idconsolidadocomi
       and cc.idconsolidadocomi = p_Idconsolidado 
       and ccd.cdarticulo = dp.cdarticulo       
       and ccd.cdarticulo = p_CdArticulo;
  RETURN V_cantArt;
     EXCEPTION
    WHEN OTHERS THEN
      RETURN V_cantArt;
  END TotalArtComi;
  
  /****************************************************************************************************
  * %v 19/06/2020 - ChM  Versión inicial PorcDistribComi
  * %v 19/06/2020 - ChM  calcula el procentaje de participación en
  *                      un articulo de pedido comisionista con respecto a todo el consolidado comi
  *****************************************************************************************************/ 
  PROCEDURE PorcDistribComi(p_idconsolidado       IN  tblslvconsolidadom.idconsolidadom%type,
                            p_Ok                  OUT number,
                            p_error               OUT varchar2) is
                           
    v_modulo       varchar2(100) := 'PKG_SLV_DISTRIBUCION.PorcDistribComi';
    v_error        varchar2(250);
    
  BEGIN
  v_error:=' Error en insert tblslvpordistrib';
  
  --borro porcentajes para el consolidado Comi
  delete tblslvpordistrib pdf
   where pdf.idconsolidado = p_idconsolidado
     and pdf.cdtipo = c_TareaConsolidadoComi;
   
  insert into tblslvpordistrib
              (idpedido,
               idconsolidado,
               cdtipo,
               cdarticulo,
               qtunidadmedidabase,
               totalconsolidado,
               porcdist,
               dtinsert,
               artpromo)
       select p.idpedido,
              cc.idconsolidadocomi,
              c_TareaConsolidadoComi,
              dp.cdarticulo,
              sum (dp.qtunidadmedidabase) qtbase,
              TotalArtComi(p_idconsolidado,dp.cdarticulo) totalart,
              sum(dp.qtunidadmedidabase)/
              TotalArtComi(p_idconsolidado,dp.cdarticulo) porc,
              sysdate,
              MarcaPromoC(p_idconsolidado,dp.cdarticulo)
         from tblslvconsolidadopedido cp,
              tblslvconsolidadopedidorel prel,
              tblslvconsolidadocomi cc,
              tblslvconsolidadocomidet ccd,
              pedidos p,
              detallepedidos dp
        where p.idpedido = dp.idpedido
          and p.idpedido = prel.idpedido
          and cp.idconsolidadopedido = prel.idconsolidadopedido
          and cc.idconsolidadocomi = cp.idconsolidadocomi
          and cc.idconsolidadocomi = ccd.idconsolidadocomi
          and ccd.cdarticulo = dp.cdarticulo
          and cc.idconsolidadocomi = p_Idconsolidado   
     group by p.idpedido,
              cc.idconsolidadocomi,
              dp.cdarticulo;
      IF SQL%ROWCOUNT = 0  THEN      
          n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       '  Detalle Error: ' || v_error);
   	      p_Ok:=0;
          p_error:='Error en insert tblslvpordistrib. Comuniquese con Sistemas!';
          ROLLBACK;
          RETURN;
       END IF; 
    p_Ok:=1;
    p_error:='';
    COMMIT;        
  EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       '  Detalle Error: ' || v_error ||
                                       '  Error: ' || SQLERRM);
      ROLLBACK;
  END PorcDistribComi;
  
  /****************************************************************************************************
  * %v 23/06/2020 - ChM  Versión inicial MarcaPromoF
  * %v 23/06/2020 - ChM  si el articulo es promo lo marca en tblslvporcdistrb              
  *****************************************************************************************************/ 
  FUNCTION MarcaPromoF(p_idconsolidado     tblslvconsolidadom.idconsolidadom%type,
                       p_CdArticulo        articulos.cdarticulo%type)
                       return integer is
                                
   v_promo                  integer:=0;
                               
  BEGIN
    select 1
      into v_promo 
      from tblslvconsolidadopedido    cp,
           tblslvconsolidadopedidorel prel,
           tblslvpedfaltante          pf,
           tblslvpedfaltanterel       pfrel,
           tblslvconsolidadopedidodet cpd,
           tblslvpedfaltantedet       pfd,
           pedidos                    p,
           detallepedidos             dp
     where p.idpedido = prel.idpedido
       and p.idpedido = dp.idpedido
       and prel.idconsolidadopedido = cp.idconsolidadopedido
       and cpd.idconsolidadopedido = cp.idconsolidadopedido
       and pfrel.idconsolidadopedido = cp.idconsolidadopedido
       and pfrel.idpedfaltante = pf.idpedfaltante
       and pf.idpedfaltante = pfd.idpedfaltante
       and pfd.cdarticulo = cpd.cdarticulo
       and dp.cdarticulo = cpd.cdarticulo
       --  incluyo solo promo son los diferentes de cero
       and dp.icresppromo <> 0 
       and pf.idpedfaltante = p_idconsolidado   
       and cpd.cdarticulo = p_CdArticulo
       and rownum=1;
  RETURN nvl(v_promo,0);
     EXCEPTION
    WHEN OTHERS THEN
     RETURN nvl(v_promo,0);
  END MarcaPromoF;
  
   /****************************************************************************************************
  * %v 29/05/2020 - ChM  Versión inicial TotalArtConsolidado
  * %v 29/05/2020 - ChM  calcula el total del faltante de un artículo de un idfaltante          
  *****************************************************************************************************/ 
  FUNCTION TotalArtfaltante(p_idconsolidado     tblslvconsolidadom.idconsolidadom%type,
                            p_CdArticulo        articulos.cdarticulo%type)
                                return number is
   v_cantArt                    number(14,2):=-1;
                               
  BEGIN
    --nunca deberia ser cero un faltante. decode evita la división por cero 
    select nvl(decode(sum(cpd.qtunidadesmedidabase-cpd.qtunidadmedidabasepicking),0,-1
                  ,sum(cpd.qtunidadesmedidabase-cpd.qtunidadmedidabasepicking)),-1) qtbase
      into v_cantArt
      from tblslvconsolidadopedido    cp,
           tblslvconsolidadopedidorel prel,
           tblslvpedfaltante          pf,
           tblslvpedfaltanterel       pfrel,
           tblslvconsolidadopedidodet cpd,
           tblslvpedfaltantedet       pfd,
           pedidos                    p
     where p.idpedido = prel.idpedido
       and prel.idconsolidadopedido = cp.idconsolidadopedido
       and cpd.idconsolidadopedido = cp.idconsolidadopedido
       and pfrel.idconsolidadopedido = cp.idconsolidadopedido
       and pfrel.idpedfaltante = pf.idpedfaltante
       and pf.idpedfaltante = pfd.idpedfaltante
       and pfd.cdarticulo = cpd.cdarticulo
       and pf.idpedfaltante = p_idconsolidado   
       and cpd.cdarticulo = p_CdArticulo;
  RETURN V_cantArt;
     EXCEPTION
    WHEN OTHERS THEN
      RETURN V_cantArt;
  END TotalArtfaltante;
  
  /****************************************************************************************************
  * %v 29/05/2020 - ChM  Versión inicial PorcDistribFaltantes
  * %v 29/05/2020 - ChM  calcula el procentaje de participación de faltantes en
  *                      un articulo con respecto al total del faltante del articulo en el pedido
  * %v 05/06/2020 - ChM  Aplicada la logica para los porcentajes de faltante 
                         aplicando Criterio B aprobado por Lerea y Pagani hoy
  *****************************************************************************************************/ 
  PROCEDURE PorcDistribFaltantes(p_idconsolidado       IN  tblslvconsolidadom.idconsolidadom%type,
                                 p_Ok                  OUT number,
                                 p_error               OUT varchar2) is
                           
    v_modulo       varchar2(100) := 'PKG_SLV_DISTRIBUCION.PorcDistribFaltantes';
    v_error        varchar2(250);
    
  BEGIN
  v_error:=' Error en insert tblslvpordistrib';
  
  --borro porcentajes para el consolidado faltante
  delete tblslvpordistrib pdf
   where pdf.idconsolidado = p_idconsolidado
     and pdf.cdtipo = c_TareaConsolidaPedidoFaltante;
   
  insert into tblslvpordistrib
    (idpedido,
     idconsolidado,
     cdtipo,
     cdarticulo,
     qtunidadmedidabase,
     totalconsolidado,
     porcdist,
     dtinsert,
     artpromo)
    select p.idpedido,
           pf.idpedfaltante,
           c_TareaConsolidaPedidoFaltante,
           cpd.cdarticulo,
           sum(cpd.qtunidadesmedidabase-cpd.qtunidadmedidabasepicking) qtbase,
           PKG_SLV_DISTRIBUCION.TotalArtfaltante(p_idconsolidado,cpd.cdarticulo) totalart,
           sum(cpd.qtunidadesmedidabase-cpd.qtunidadmedidabasepicking)/
           PKG_SLV_DISTRIBUCION.TotalArtfaltante(p_idconsolidado,cpd.cdarticulo) porc,
           sysdate,
           MarcaPromoF(p_idconsolidado,cpd.cdarticulo)
      from tblslvconsolidadopedido    cp,
           tblslvconsolidadopedidorel prel,
           tblslvpedfaltante          pf,
           tblslvpedfaltanterel       pfrel,
           tblslvconsolidadopedidodet cpd,
           tblslvpedfaltantedet       pfd,
           pedidos                    p
     where p.idpedido = prel.idpedido
       and prel.idconsolidadopedido = cp.idconsolidadopedido
       and cpd.idconsolidadopedido = cp.idconsolidadopedido
       and pfrel.idconsolidadopedido = cp.idconsolidadopedido
       and pfrel.idpedfaltante = pf.idpedfaltante
       and pf.idpedfaltante = pfd.idpedfaltante
       and pfd.cdarticulo = cpd.cdarticulo
       and pf.idpedfaltante = p_idconsolidado
  group by p.idpedido, 
           pf.idpedfaltante,
           cpd.cdarticulo;

      IF SQL%ROWCOUNT = 0  THEN      
          n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       '  Detalle Error: ' || v_error);
   	      p_Ok:=0;
          p_error:='Error en insert tblslvpordistrib. Comuniquese con Sistemas!';
          ROLLBACK;
          RETURN;
       END IF; 
    p_Ok:=1;
    p_error:='';
    COMMIT;        
  EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       '  Detalle Error: ' || v_error ||
                                       '  Error: ' || SQLERRM);
      ROLLBACK;

  END PorcDistribFaltantes;
  
   
  /****************************************************************************************************
  * %v 08/06/2020 - ChM  Versión inicial VerificaDiferenciasP
  * %v 08/06/2020 - ChM  revisa si existen diferencias entre lo insertado en tblslvpedidoconformado 
                         y tblslvtblslvconsolidadopedidodet y aplica ajustes
  *****************************************************************************************************/ 
  FUNCTION VerificaDiferenciasP(p_idcosolidadoP     tblslvconsolidadopedido.idconsolidadopedido%type)
                                return number is
                                
   v_qtbase                   tblslvpedidoconformado.qtunidadmedidabase%type:=0;
   v_dif                      number; 
   v_modulo                   varchar2(100) := 'PKG_SLV_DISTRIBUCION.VerificaDiferenciasP';
   v_error                    varchar2(250);
    
  BEGIN
   
    
    v_error:=' Error en Cursor cpedido';  
    --cursor del total del articulo en consolidadopedido                            
    for cpedido in 
      (select dpe.cdarticulo,                          
              round(sum(cpd.qtunidadmedidabasepicking)) qtbase                          
         from pedidos                      pe,
              detallepedidos               dpe,
              tblslvconsolidadopedidorel   cprel,        
              tblslvconsolidadopedido      cp,
              tblslvconsolidadopedidodet   cpd               
        where pe.idpedido = dpe.idpedido
          and pe.idpedido = cprel.idpedido
          and cprel.idconsolidadopedido = cp.idconsolidadopedido
          and cp.idconsolidadopedido = cpd.idconsolidadopedido
          and cpd.cdarticulo = dpe.cdarticulo        
          -- excluyo pesables
          and nvl(cpd.qtpiezas,0)=0
          --valida cesta navideña
          and pe.idcnpedido is null 
          --excluyo promo
          and dpe.icresppromo = 0 
          --excluyo comisionistas
          and cp.idconsolidadocomi is null
          --verifica que se haya piquiado algo para ese artículo
          and cpd.qtunidadmedidabasepicking>0
          and cp.idconsolidadopedido = p_idcosolidadoP
     group by pe.idpedido,
              dpe.cdarticulo,
              dpe.sqdetallepedido,
              dpe.cdunidadmedida)
     loop
       begin
         --suma la cantidad del articulo de la tblslvpedidoconformado para comparar
         --con el total del articulo en el consolidado pedido
         v_error:=' Error en select tblslvpedidoconformado';   
         select sum(pc.qtunidadmedidabase)
           into v_qtbase 
           from tblslvpedidoconformado pc
          where pc.cdarticulo = cpedido.cdarticulo
            --suma la cantidad de articulos de todos los pedidos que conforman el consolidado pedido
            and pc.idpedido in 
                      (select pe.idpedido           
                         from pedidos  pe,
                              tblslvconsolidadopedidorel cprel, 
                              tblslvconsolidadopedido cp
                        where pe.idpedido = cprel.idpedido
                          and cp.idconsolidadopedido = cprel.idconsolidadopedido
                          and cp.idconsolidadopedido = p_idcosolidadoP);                                       
        exception
          --sino encuentra el artículo es por que la distribución porcentual dio menor a 0.5 
          --entonces lo resuelvo al insertar en tblslvpedidoconformado con la cantidad del cursor
           when no_data_found then 
             v_error:=' Error en insert tblslvpedidoconformado';                
             insert into tblslvpedidoconformado
                         (idpedido,
                          cdarticulo,
                          sqdetallepedido,
                          cdunidadmedida,
                          qtunidadpedido,
                          qtunidadmedidabase,
                          qtpiezas,
                          ampreciounitario,
                          amlinea,
                          vluxb,
                          dsobservacion,
                          icrespromo,
                          cdpromo,
                          dtinsert,
                          dtupdate)
                   select pe.idpedido,
                          dpe.cdarticulo,
                          dpe.sqdetallepedido,
                          dpe.cdunidadmedida,
                          dpe.qtunidadpedido,
                          cpedido.qtbase,--cantidad faltante
                          cpd.qtpiezas,
                          dpe.ampreciounitario,
                          dpe.amlinea,
                          dpe.vluxb,
                          nvl(op.dsobservacion,'-') dsobservacion,
                          dpe.icresppromo,
                          dpe.cdpromo,
                          sysdate dtinsert,
                          null dtupdate  
                     from pedidos                      pe
                left join observacionespedido          op
                       on (pe.idpedido = op.dsobservacion),
                          detallepedidos               dpe,
                          tblslvconsolidadopedidorel   cprel,        
                          tblslvconsolidadopedido      cp,
                          tblslvconsolidadopedidodet   cpd                                
                    where pe.idpedido = dpe.idpedido
                      and pe.idpedido = cprel.idpedido
                      and cprel.idconsolidadopedido = cp.idconsolidadopedido
                      and cp.idconsolidadopedido = cpd.idconsolidadopedido
                      and cpd.cdarticulo = dpe.cdarticulo
                      --filtra por valores del cursor                   
                      and dpe.cdarticulo = cpedido.cdarticulo
                      and cp.idconsolidadopedido = p_idcosolidadoP
                      --verifica insertar un pedido que aun tenga faltante
                      and (cpd.qtunidadesmedidabase-cpd.qtunidadmedidabasepicking)>=cpedido.qtbase
                      --solo inserto en el primer pedido que encuentre y cumpla las condiciones
                      and rownum=1;
           IF SQL%ROWCOUNT = 0  THEN      
                n_pkg_vitalpos_log_general.write(2,
                                             'Modulo: ' || v_modulo ||
                                             '  Detalle Error: ' || v_error);               
                ROLLBACK;
                RETURN 0; 
           END IF;          
       when others then
          n_pkg_vitalpos_log_general.write(2,
                                           'modulo: ' || v_modulo ||
                                           '  detalle error: ' || v_error ||
                                           '  error: ' || sqlerrm);
          rollback;
          return 0;               
       end;         
          --verifico si existe diferencia y actualizo el ajuste
          v_dif := cpedido.qtbase-v_qtbase;
          if v_dif <> 0 then
            v_error:=' Error en update tblslvpedidoconformado';   
             update tblslvpedidoconformado pc1
                set (pc1.qtunidadmedidabase,
                    pc1.dtupdate)=
                    (select pc.qtunidadmedidabase+v_dif,
                           sysdate
                         from pedidos                      pe,                    
                              detallepedidos               dpe,
                              tblslvconsolidadopedidorel   cprel,        
                              tblslvconsolidadopedido      cp,
                              tblslvconsolidadopedidodet   cpd,
                              tblslvpedidoconformado       pc                                
                        where pe.idpedido = dpe.idpedido
                          and pe.idpedido = cprel.idpedido
                          and cprel.idconsolidadopedido = cp.idconsolidadopedido
                          and cp.idconsolidadopedido = cpd.idconsolidadopedido
                          and cpd.cdarticulo = dpe.cdarticulo
                          and pc.idpedido = pe.idpedido
                          and pc.cdarticulo = dpe.cdarticulo
                          and pc.sqdetallepedido = dpe.sqdetallepedido
                          --filtra por valores del cursor                   
                          and dpe.cdarticulo = cpedido.cdarticulo
                          and cp.idconsolidadopedido = p_idcosolidadoP
                          --verifica actualizar un pedido que aun tenga faltante
                          and (pc.qtunidadpedido-pc.qtunidadmedidabase)>=abs(v_dif)
                          --solo actualizo en el primer pedido que encuentre y cumpla las condiciones
                          and rownum=1)
              where EXISTS
                      (select 1
                         from pedidos                      pe,                    
                              detallepedidos               dpe,
                              tblslvconsolidadopedidorel   cprel,        
                              tblslvconsolidadopedido      cp,
                              tblslvconsolidadopedidodet   cpd,
                              tblslvpedidoconformado       pc                                
                        where pe.idpedido = dpe.idpedido
                          and pe.idpedido = cprel.idpedido
                          and cprel.idconsolidadopedido = cp.idconsolidadopedido
                          and cp.idconsolidadopedido = cpd.idconsolidadopedido
                          and cpd.cdarticulo = dpe.cdarticulo
                          and pc.idpedido = pe.idpedido
                          and pc.cdarticulo = dpe.cdarticulo
                          and pc.sqdetallepedido = dpe.sqdetallepedido
                          --filtra por valores del cursor                   
                          and dpe.cdarticulo = cpedido.cdarticulo
                          and cp.idconsolidadopedido = p_idcosolidadoP
                          --verifica actualizar un pedido que aun tenga faltante
                          and (pc.qtunidadpedido-pc.qtunidadmedidabase)>=abs(v_dif)
                          --solo actualizo en el primer pedido que encuentre y cumpla las condiciones
                          and rownum=1);          
             IF SQL%ROWCOUNT = 0  THEN      
                n_pkg_vitalpos_log_general.write(2,
                                             'Modulo: ' || v_modulo ||
                                             '  Detalle Error: ' || v_error);               
                ROLLBACK;
                RETURN 0; 
             END IF;    
          end if;  
       end loop;               
  RETURN 1;
     EXCEPTION
    WHEN OTHERS THEN
       n_pkg_vitalpos_log_general.write(2,
                                           'modulo: ' || v_modulo ||
                                           '  detalle error: ' || v_error ||
                                           '  error: ' || sqlerrm);
          rollback;  
      RETURN 0;
  END VerificaDiferenciasP;
  
  /****************************************************************************************************
  * %v 08/06/2020 - ChM  Versión inicial VerificaDiferenciasFal
  * %v 08/06/2020 - ChM  revisa si existen diferencias entre lo insertado en  tblslvdistribucionpedfaltante
                         y tblslvtblslvconsolidadopedidodet y aplica ajustes
  *****************************************************************************************************/ 
  FUNCTION VerificaDiferenciasFal(p_idPedidoFal     tblslvconsolidadopedido.idconsolidadopedido%type)
                                return number is
                                
   v_qtbase                   tblslvdistribucionpedfaltante.qtunidadmedidabase%type:=0;
   v_dif                      number; 
   v_modulo                   varchar2(100) := 'PKG_SLV_DISTRIBUCION.VerificaDiferenciasFal';
   v_error                    varchar2(250);
    
  BEGIN
    v_error:=' Error en Cursor cpedido';                              
    for pedfaltante in 
      (     select frel.idpedfaltanterel,           
            fd.cdarticulo,            
            round(fd.qtunidadmedidabasepicking) qtbase
       from tblslvpedfaltante          cf,
            tblslvpedfaltantedet       fd,
            tblslvpedfaltanterel       frel,
            tblslvconsolidadopedido    cp,
            tblslvconsolidadopedidodet cpd,
            tblslvconsolidadopedidorel cprel,
            pedidos                    pe
      where cf.idpedfaltante = fd.idpedfaltante
        and cf.idpedfaltante = fd.idpedfaltante
        and cp.idconsolidadopedido = cpd.idconsolidadopedido
        and cf.idpedfaltante = frel.idpedfaltante
        and frel.idconsolidadopedido = cp.idconsolidadopedido
        and frel.idpedfaltante = cf.idpedfaltante
        and cprel.idconsolidadopedido = cp.idconsolidadopedido
        and cprel.idpedido = pe.idpedido
        and cpd.cdarticulo = fd.cdarticulo
        -- excluyo pesables
        and nvl(cpd.qtpiezas,0)=0
        --con valor pickiado
        and case
            when fd.qtpiezas = 0  and fd.qtunidadmedidabasepicking > 0 then 1
          --  when fd.qtpiezas <> 0 and fd.qtpiezaspicking > 0 then 1      
            end = 1          
        and cf.idpedfaltante = p_idPedidoFal)
     loop
       begin
         v_error:=' Error en select tblslvdistribucionpedfaltante';   
         select sum(df.qtunidadmedidabase)
           into v_qtbase 
           from tblslvdistribucionpedfaltante df
          where df.idpedfaltanterel =  pedfaltante.idpedfaltanterel
            and df.cdarticulo =  pedfaltante.cdarticulo;          
        exception
          --sino encuentra el articulo es por que la distribución porcentual dio menor a 0.5 
          --entonces lo resuelvo al insertar en tblslvdistribucionpedfaltante con la cantidad del cursor
           when no_data_found then 
             v_error:=' Error en insert tblslvdistribucionpedfaltante';                
             insert into tblslvdistribucionpedfaltante
                   (iddistribucionpedfaltante,
                    idpedfaltanterel,
                    cdarticulo,
                    qtunidadmedidabase,
                    qtpiezas)
                   select seq_distribucionpedfaltante.nextval,
                          A.idpedfaltanterel,           
                          A.cdarticulo,
                          pedfaltante.qtbase,
                          A.qtpiezaspicking
                     from      
                  (select frel.idpedfaltanterel,
                          frel.idconsolidadopedido,
                          fd.cdarticulo,            
                          fd.qtpiezaspicking
                     from tblslvpedfaltante          cf,
                          tblslvpedfaltantedet       fd,
                          tblslvpedfaltanterel       frel,
                          tblslvconsolidadopedido    cp,
                          tblslvconsolidadopedidodet cpd,
                          tblslvconsolidadopedidorel cprel,           
                          pedidos                    pe
                    where cf.idpedfaltante = fd.idpedfaltante
                      and cf.idpedfaltante = fd.idpedfaltante
                      and cp.idconsolidadopedido = cpd.idconsolidadopedido
                      and cf.idpedfaltante = frel.idpedfaltante
                      and frel.idconsolidadopedido = cp.idconsolidadopedido
                      and frel.idpedfaltante = cf.idpedfaltante
                      and cprel.idconsolidadopedido = cp.idconsolidadopedido
                      and cprel.idpedido = pe.idpedido                      
                      and cpd.cdarticulo = fd.cdarticulo
                       --filtra por valores del cursor           
                      and frel.idpedfaltanterel = pedfaltante.idpedfaltanterel
                      and fd.cdarticulo = pedfaltante.cdarticulo) A;
                     IF SQL%ROWCOUNT = 0  THEN      
                          n_pkg_vitalpos_log_general.write(2,
                                                       'Modulo: ' || v_modulo ||
                                                       '  Detalle Error: ' || v_error);               
                          ROLLBACK;
                          RETURN 0; 
                     END IF;          
       when others then
          n_pkg_vitalpos_log_general.write(2,
                                           'modulo: ' || v_modulo ||
                                           '  detalle error: ' || v_error ||
                                           '  error: ' || sqlerrm);
          rollback;
          return 0;               
       end;         
          --verifico si existe diferencia y actualizo el ajuste OJO FALTA PESABLES
          v_dif :=  pedfaltante.qtbase-v_qtbase;
          if v_dif <> 0 then
            v_error:=' Error en update tblslvdistribucionpedfaltante';   
             update tblslvdistribucionpedfaltante pf
                set pf.qtunidadmedidabase = pf.qtunidadmedidabase+v_dif                    
              where pf.idpedfaltanterel = pedfaltante.idpedfaltanterel
                and pf.cdarticulo = pedfaltante.cdarticulo;
             IF SQL%ROWCOUNT = 0  THEN      
                n_pkg_vitalpos_log_general.write(2,
                                             'Modulo: ' || v_modulo ||
                                             '  Detalle Error: ' || v_error);               
                ROLLBACK;
                RETURN 0; 
             END IF;    
          end if;  
       end loop;              
  RETURN 1;
     EXCEPTION
    WHEN OTHERS THEN
       n_pkg_vitalpos_log_general.write(2,
                                           'modulo: ' || v_modulo ||
                                           '  detalle error: ' || v_error ||
                                           '  error: ' || sqlerrm);
          rollback;  
      RETURN 0;
  END VerificaDiferenciasFal;
  
  /****************************************************************************************************
  * %v 17/06/2020 - ChM  Versión inicial TempPesablesP
  * %v 17/06/2020 - ChM crea la tabla temporal de los pesables disponibles del consolidado pedido
  *****************************************************************************************************/ 
   FUNCTION TempPesablesP(p_idconsolidado    tblslvconsolidadom.idconsolidadom%type
                         ) RETURN NUMBER is
                           
    v_modulo       varchar2(100) := 'PKG_SLV_DISTRIBUCION.TempPesablesP';
    v_i            integer:=1;            
    
    BEGIN  
    --Creo la tabla en memoria de los pesables disponibles para el idconsolidado 
    FOR PES IN
             (--consulta para los remitos de tarea
             select cp.idconsolidadopedido,
                     red.cdarticulo,
                     red.qtunidadmedidabasepicking,
                     red.qtpiezaspicking
                from tblslvconsolidadopedido cp,
                     tblslvconsolidadopedidodet cpd,
                     tblslvtarea ta,
                     tblslvremito re,
                     tblslvremitodet red
               where cp.idconsolidadopedido = cpd.idconsolidadopedido
                 and cp.idconsolidadopedido = ta.idconsolidadopedido
                 and ta.idtarea = re.idtarea
                 and re.idremito = red.idremito
                 and cpd.cdarticulo = red.cdarticulo
                 --solo pesables
                 and cpd.qtpiezas<>0
                 --valido solo pesables con picking mayores a cero
                 and cpd.qtpiezaspicking > 0
                 --valido no comisionistas 
                 and cp.idconsolidadocomi is null
                 and cp.idconsolidadopedido = p_idconsolidado
               union all
               --Consulta para remitos de distribucion faltantes
              select cp.idconsolidadopedido,
                     red.cdarticulo,
                     red.qtunidadmedidabasepicking,
                     red.qtpiezaspicking
                from tblslvconsolidadopedido cp,
                     tblslvconsolidadopedidodet cpd,
                     tblslvpedfaltanterel pfrel,                   
                     tblslvremito re,
                     tblslvremitodet red
               where cp.idconsolidadopedido = cpd.idconsolidadopedido
                 and cp.idconsolidadopedido = pfrel.idconsolidadopedido
                 and pfrel.idpedfaltante = re.idpedfaltanterel
                 and re.idremito = red.idremito
                 and cpd.cdarticulo = red.cdarticulo
                 --solo pesables
                 and cpd.qtpiezas<>0
                 --valido solo pesables con picking mayores a cero
                 and cpd.qtpiezaspicking > 0
                 --valido no comisionistas 
                 and cp.idconsolidadocomi is null
                 and cp.idconsolidadopedido = p_idconsolidado)
    LOOP
      PESABLES_P(v_i).IDCONSOLIDADOPEDIDO:=pes.idconsolidadopedido;
      PESABLES_P(v_i).CDARTICULO:=pes.cdarticulo;     
      PESABLES_P(v_i).QTUNIDADMEDIDABASEPIK:=pes.qtunidadmedidabasepicking;
      PESABLES_P(v_i).QTPIEZASPIK:=pes.qtpiezaspicking;
      --BANDERA en 0 cero indica pesable no asignado
      PESABLES_P(v_i).BANDERA:=0;
      v_i:=v_i+1;
      END LOOP;             
    RETURN v_i;    
    EXCEPTION
      WHEN OTHERS THEN
        n_pkg_vitalpos_log_general.write(2,
                                         'Modulo: ' || v_modulo ||                                       
                                         '  Error: ' || SQLERRM);
        RETURN 0;

  END TempPesablesP;
  
  /****************************************************************************************************
  * %v 18/06/2020 - ChM  Versión inicial TempPesablesF
  * %v 18/06/2020 - ChM crea la tabla temporal de los pesables disponibles del consolidado Faltante
  *****************************************************************************************************/
   FUNCTION TempPesablesF(p_idconsolidado    tblslvconsolidadom.idconsolidadom%type
                         ) RETURN NUMBER is
                           
    v_modulo       varchar2(100) := 'PKG_SLV_DISTRIBUCION.TempPesablesF';
    v_i            integer:=1;            
    
    BEGIN  
    --Creo la tabla en memoria de los pesables disponibles para el id consolidado FALTANTE
    FOR PES IN
             (select pf.idpedfaltante,
                     red.cdarticulo,
                     red.qtunidadmedidabasepicking,
                     red.qtpiezaspicking
                from tblslvpedfaltante pf,
                     tblslvpedfaltantedet pfd,
                     tblslvtarea ta,
                     tblslvremito re,
                     tblslvremitodet red
               where pf.idpedfaltante = pfd.idpedfaltante
                 and pf.idpedfaltante = ta.idpedfaltante
                 and ta.idtarea = re.idtarea
                 and re.idremito = red.idremito
                 and pfd.cdarticulo = red.cdarticulo
                 --solo pesables
                 and pfd.qtpiezas<>0
                 --valido solo pesables con picking mayores a cero
                 and pfd.qtpiezaspicking > 0
                 and pf.idpedfaltante = p_idconsolidado)
    LOOP
      PESABLES_F(v_i).IDCONSOLIDADOPEDIDO:=pes.idpedfaltante;
      PESABLES_F(v_i).CDARTICULO:=pes.cdarticulo;     
      PESABLES_F(v_i).QTUNIDADMEDIDABASEPIK:=pes.qtunidadmedidabasepicking;
      PESABLES_F(v_i).QTPIEZASPIK:=pes.qtpiezaspicking;
      --BANDERA en 0 cero indica pesable no asignado
      PESABLES_F(v_i).BANDERA:=0;
      v_i:=v_i+1;
      END LOOP;             
    RETURN v_i;    
    EXCEPTION
      WHEN OTHERS THEN
        n_pkg_vitalpos_log_general.write(2,
                                         'Modulo: ' || v_modulo ||                                       
                                         '  Error: ' || SQLERRM);
        RETURN 0;

  END TempPesablesF;
  
  /****************************************************************************************************
  * %v 19/06/2020 - ChM  Versión inicial TempPesablesC
  * %v 19/06/2020 - ChM crea la tabla temporal de los pesables disponibles del consolidado COMI
  *****************************************************************************************************/ 
   FUNCTION TempPesablesC(p_idconsolidado    tblslvconsolidadom.idconsolidadom%type
                         ) RETURN NUMBER is
                           
    v_modulo       varchar2(100) := 'PKG_SLV_DISTRIBUCION.TempPesablesC';
    v_i            integer:=1;            
    
    BEGIN  
    --Creo la tabla en memoria de los pesables disponibles para el consolidado comi
    FOR PES IN
             (--consulta para los remitos de tarea
              select cc.idconsolidadocomi,
                     red.cdarticulo,
                     red.qtunidadmedidabasepicking,
                     red.qtpiezaspicking
                from tblslvconsolidadocomi cc,
                     tblslvconsolidadocomidet ccd,
                     tblslvtarea ta,
                     tblslvremito re,
                     tblslvremitodet red
               where cc.idconsolidadocomi = ccd.idconsolidadocomi
                 and cc.idconsolidadocomi = ta.idconsolidadocomi
                 and ta.idtarea = re.idtarea
                 and re.idremito = red.idremito
                 and ccd.cdarticulo = red.cdarticulo
                 --solo pesables
                 and ccd.qtpiezas<>0
                 --valido solo pesables con picking mayores a cero
                 and ccd.qtpiezaspicking > 0
                 and cc.idconsolidadocomi = p_idconsolidado)
    LOOP
      PESABLES_C(v_i).IDCONSOLIDADOPEDIDO:=pes.idconsolidadocomi;
      PESABLES_C(v_i).CDARTICULO:=pes.cdarticulo;     
      PESABLES_C(v_i).QTUNIDADMEDIDABASEPIK:=pes.qtunidadmedidabasepicking;
      PESABLES_C(v_i).QTPIEZASPIK:=pes.qtpiezaspicking;
      --BANDERA en 0 cero indica pesable no asignado
      PESABLES_C(v_i).BANDERA:=0;
      v_i:=v_i+1;
      END LOOP;             
    RETURN v_i;    
    EXCEPTION
      WHEN OTHERS THEN
        n_pkg_vitalpos_log_general.write(2,
                                         'Modulo: ' || v_modulo ||                                       
                                         '  Error: ' || SQLERRM);
        RETURN 0;

  END TempPesablesC;
  
 /****************************************************************************************************
  * %v 17/06/2020 - ChM  Versión inicial DistPesablesP
  * %v 17/06/2020 - ChM  distribuye los pesables del consolidado pedido según porcentaje
  *****************************************************************************************************/ 
  PROCEDURE DistPesablesP(p_idconsolidado      IN  tblslvconsolidadom.idconsolidadom%type,
                          p_Ok                  OUT number,
                          p_error               OUT varchar2
                         )is
                           
    v_modulo             varchar2(100) := 'PKG_SLV_DISTRIBUCION.DistPesablesP';  
    i                    Binary_Integer := 0;
    v_resto              detallepedidos.qtpiezas%type;     
    v_error                    varchar2(250);
        
  BEGIN
    for pes in(
       select pe.idpedido,
              dpe.cdarticulo,              
              dpe.cdunidadmedida,
              dpe.qtunidadpedido,
              cpd.qtunidadmedidabasepicking,            
              round(cpd.qtpiezaspicking * pdi.porcdist,0) qtpiezaspicking,
              dpe.ampreciounitario,
              dpe.amlinea,
              dpe.vluxb,
              nvl(dpe.dsobservacion,'-') dsobservacion,
              dpe.icresppromo,
              dpe.cdpromo,
              sysdate dtinsert,
              null dtupdate  
         from pedidos                      pe,
              detallepedidos               dpe,
              tblslvconsolidadopedidorel   cprel,        
              tblslvconsolidadopedido      cp,
              tblslvconsolidadopedidodet   cpd,
              tblslvpordistrib             pdi                
        where pe.idpedido = dpe.idpedido
          and pe.idpedido = cprel.idpedido
          and cprel.idconsolidadopedido = cp.idconsolidadopedido
          and cp.idconsolidadopedido = cpd.idconsolidadopedido
          and cpd.cdarticulo = dpe.cdarticulo
          and pdi.idpedido = pe.idpedido
          and pdi.idconsolidado = cp.idconsolidadopedido
          and pdi.cdarticulo = cpd.cdarticulo           
          -- solo articulos sin promo
          and pdi.artpromo = 0     
          --valida el tipo de tarea consolidado Pedido en la tabla distribución
          and pdi.cdtipo = c_TareaConsolidadoPedido
         --solo inserto para facturar los mayores a cero
          and round(cpd.qtpiezaspicking * pdi.porcdist,0)>0
          -- solo pesables
          and nvl(cpd.qtpiezas,0)<>0
          --valida cesta navideña
          and pe.idcnpedido is null 
          --excluyo promo
          and dpe.icresppromo = 0 
          --excluyo comisionistas
          and cp.idconsolidadocomi is null
          and cp.idconsolidadopedido = p_idconsolidado)
    loop
       v_resto:=pes.qtpiezaspicking;
       i := PESABLES_P.FIRST;       
       While i Is Not Null and v_resto > 0 Loop
         
         --verifica si esta libre el pesable para asignarlo al pedido
         if PESABLES_P(i).BANDERA = 0 
            and PESABLES_P(i).IDCONSOLIDADOPEDIDO = p_idconsolidado 
            and PESABLES_P(i).CDARTICULO = pes.cdarticulo then
            
            --marco el pesable como asignado
            PESABLES_P(i).BANDERA:=1;

            --se va restando el qtpiezaspick a la cantidad de piezas solicitadas
            v_resto:=v_resto-PESABLES_P(i).QTPIEZASPIK;
            
            --se inserta el valor del pesable uno a uno en tblslvpedidoconformado
            v_error:=' Error en insert tblslvpedidoconformado';   
            insert into tblslvpedidoconformado
             (idpedido,
              cdarticulo,
              sqdetallepedido,
              cdunidadmedida,
              qtunidadpedido,
              qtunidadmedidabase,
              qtpiezas,
              ampreciounitario,
              amlinea,
              vluxb,
              dsobservacion,
              icrespromo,
              cdpromo,
              dtinsert,
              dtupdate)
              values
              (
               pes.idpedido,
               pes.cdarticulo,
               SecuenciaPedConformado(pes.idpedido)+1,
               pes.cdunidadmedida,
               pes.qtunidadpedido,
               PESABLES_P(i).QTUNIDADMEDIDABASEPIK,
               PESABLES_P(i).QTPIEZASPIK,
               pes.ampreciounitario,
               pes.amlinea,
               pes.vluxb,
               pes.dsobservacion,
               pes.icresppromo,
               pes.cdpromo,
               sysdate,
               null);
               IF SQL%ROWCOUNT = 0 THEN
                    n_pkg_vitalpos_log_general.write(2,
                                      'Modulo: ' || v_modulo ||
                                      '  Detalle Error: ' || v_error);
    	              p_Ok    := 0;
                    p_error := 'Error en insert tblslvpedidoconformado. Comuniquese con Sistemas!';
                    ROLLBACK;
                    RETURN;
                END IF;
         end if; 
         i:= PESABLES_P.NEXT(i);
       End Loop;
    end loop;     
  --verifico si queda algún pesable por asignar   
  i := PESABLES_P.FIRST;       
  While i Is Not Null Loop       
     --verifica si esta libre el pesable para asignarlo al primer pedido libre
     if PESABLES_P(i).BANDERA = 0 
        and PESABLES_P(i).IDCONSOLIDADOPEDIDO = p_idconsolidado then 
        --OOOJJJJOOO falta por los redondeos ajustar aqui 
         p_Ok    := 0;
         p_error := 'Error en DISTRIBUCIÓN Pesables. Comuniquese con Sistemas!';   
     end if; 
     i:= PESABLES_P.NEXT(i);
   End Loop;  
  p_Ok    := 1;
  p_error := null; 
  EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       '  Error: ' || SQLERRM);
      p_Ok    := 0;
      p_error := 'Error en Pesables. Comuniquese con Sistemas!';                                  

  END DistPesablesP;
   
  
  /****************************************************************************************************
  * %v 17/06/2020 - ChM  Versión inicial DistPesablesF
  * %v 17/06/2020 - ChM  distribuye los pesables del consolidado Faltante según porcentaje
  *****************************************************************************************************/ 
  PROCEDURE DistPesablesF(p_IdPedFaltante       IN  tblslvconsolidadom.idconsolidadom%type,
                          p_Ok                  OUT number,
                          p_error               OUT varchar2
                         )is
                           
    v_modulo             varchar2(100) := 'PKG_SLV_DISTRIBUCION.DistPesablesF';  
    i                    Binary_Integer := 0;
    v_resto              detallepedidos.qtpiezas%type;     
    v_error                    varchar2(250);
        
  BEGIN
    for pes in
             ( select frel.idpedfaltanterel,
                      frel.idconsolidadopedido,
                      fd.cdarticulo,
                      pe.idpedido,
                      --aplico el porcentaje a distribuir a los faltantes encontrados y redondeo 
                      round(fd.qtpiezaspicking * pdis.porcdist,0) QTDISTB                               
                 from tblslvpedfaltante          cf,
                      tblslvpedfaltantedet       fd,
                      tblslvpedfaltanterel       frel,
                      tblslvconsolidadopedido    cp,
                      tblslvconsolidadopedidodet cpd,
                      tblslvconsolidadopedidorel cprel,
                      tblslvpordistrib           pdis,
                      pedidos                    pe
                where cf.idpedfaltante = fd.idpedfaltante
                  and cf.idpedfaltante = fd.idpedfaltante
                  and cp.idconsolidadopedido = cpd.idconsolidadopedido
                  and cf.idpedfaltante = frel.idpedfaltante
                  and frel.idconsolidadopedido = cp.idconsolidadopedido
                  and frel.idpedfaltante = cf.idpedfaltante
                  and cprel.idconsolidadopedido = cp.idconsolidadopedido
                  and cprel.idpedido = pe.idpedido
                  and pdis.idconsolidado = cf.idpedfaltante
                  --valida el tipo de tarea de faltante en la tabla distribución
                  and pdis.cdtipo = c_TareaConsolidaPedidoFaltante
                  and pdis.idpedido = pe.idpedido
                  and pdis.cdarticulo = cpd.cdarticulo
                  -- solo articulos sin promo
                  and pdis.artpromo = 0
                  and fd.cdarticulo = pdis.cdarticulo
                  and cpd.cdarticulo = fd.cdarticulo
                  -- solo pesables
                  and nvl(fd.qtpiezas,0)=0
                  --con valor pickiado
                  and nvl(fd.qtpiezaspicking, 0) > 0
                  --solo inserto los mayores a cero
                  and round(fd.qtpiezaspicking * pdis.porcdist,0) > 0   
                  and cf.idpedfaltante = p_IdPedFaltante
              )
    loop
       v_resto:=pes.qtdistb;
       i := PESABLES_F.FIRST;       
       While i Is Not Null and v_resto > 0 Loop         
         --verifica si esta libre el pesable para asignarlo al pedido
         if PESABLES_F(i).BANDERA = 0 
            and PESABLES_F(i).IDCONSOLIDADOPEDIDO = p_IdPedFaltante 
            and PESABLES_F(i).CDARTICULO = pes.cdarticulo then
            
            --marco el pesable como asignado
            PESABLES_F(i).BANDERA:=1;

            --se va restando el qtpiezaspick a la cantidad de piezas solicitadas
            v_resto:=v_resto-PESABLES_F(i).QTPIEZASPIK;
            
            --se inserta el valor del pesable uno a uno en tblslvdistribucionpedfaltante
              v_error:=' Error en insert tblslvdistribucionpedfaltante';   
            insert into tblslvdistribucionpedfaltante
                        (iddistribucionpedfaltante,
                        idpedfaltanterel,
                        cdarticulo,
                        qtunidadmedidabase,
                        qtpiezas)
                 values
                        (seq_distribucionpedfaltante.nextval,
                         pes.idpedfaltanterel,
                         pes.cdarticulo,                        
                         PESABLES_P(i).QTUNIDADMEDIDABASEPIK,
                         PESABLES_P(i).QTPIEZASPIK
                         );
                         IF SQL%ROWCOUNT = 0 THEN
                              n_pkg_vitalpos_log_general.write(2,
                                                'Modulo: ' || v_modulo ||
                                                '  Detalle Error: ' || v_error);
                              p_Ok    := 0;
                              p_error := 'Error en insert tblslvdistribucionpedfaltante. Comuniquese con Sistemas!';
                              ROLLBACK;
                              RETURN;
                          END IF;
         end if; 
         i:= PESABLES_F.NEXT(i);
       End Loop;
    end loop;     
  --verifico si queda algún pesable por asignar   
  i := PESABLES_F.FIRST;       
  While i Is Not Null Loop       
     --verifica si esta libre el pesable para asignarlo al primer pedido libre
     if PESABLES_F(i).BANDERA = 0 
        and PESABLES_F(i).IDCONSOLIDADOPEDIDO = p_IdPedFaltante then        
        --OOOJJJJOOO falta por los redondeos ajustar aqui 
         p_Ok    := 0;
         p_error := 'Error en DISTRIBUCIÓN Pesables. Comuniquese con Sistemas!';   
     end if; 
     i:= PESABLES_F.NEXT(i);
   End Loop;  
  p_Ok    := 1;
  p_error := null; 
  EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       '  Error: ' || SQLERRM);
      p_Ok    := 0;
      p_error := 'Error en Pesables. Comuniquese con Sistemas!';                                  

  END DistPesablesF;
  
  /****************************************************************************************************
  * %v 19/06/2020 - ChM  Versión inicial DistPesablesC
  * %v 19/06/2020 - ChM  distribuye los pesables del consolidado COMI según porcentaje
  *****************************************************************************************************/ 
  PROCEDURE DistPesablesC(p_idconsolidado      IN  tblslvconsolidadom.idconsolidadom%type,
                          p_Ok                  OUT number,
                          p_error               OUT varchar2
                         )is
                           
    v_modulo             varchar2(100) := 'PKG_SLV_DISTRIBUCION.DistPesablesC';  
    i                    Binary_Integer := 0;
    v_resto              detallepedidos.qtpiezas%type;     
    v_error                    varchar2(250);
        
  BEGIN
    for pes in(
       select pe.idpedido,
              dpe.cdarticulo,              
              dpe.cdunidadmedida,
              dpe.qtunidadpedido,
              ccd.qtunidadmedidabasepicking,
              round(ccd.qtpiezaspicking * pdi.porcdist,0) qtpiezaspicking,       
              dpe.ampreciounitario,
              dpe.amlinea,
              dpe.vluxb,
              nvl(dpe.dsobservacion,'-') dsobservacion,
              dpe.icresppromo,
              dpe.cdpromo,
              sysdate dtinsert,
              null dtupdate  
         from pedidos                      pe,   
              detallepedidos               dpe,
              tblslvconsolidadopedidorel   cprel,        
              tblslvconsolidadopedido      cp,
              tblslvconsolidadocomi        cc,
              tblslvconsolidadocomidet     ccd,                         
              tblslvpordistrib             pdi        
        where pe.idpedido = dpe.idpedido
          and pe.idpedido = cprel.idpedido
          and cprel.idconsolidadopedido = cp.idconsolidadopedido
          and cp.idconsolidadocomi = cc.idconsolidadocomi
          and cc.idconsolidadocomi = ccd.idconsolidadocomi
          and ccd.cdarticulo = dpe.cdarticulo
          and pdi.idpedido = pe.idpedido
          and pdi.idconsolidado = cc.idconsolidadocomi
          and pdi.cdarticulo = ccd.cdarticulo
          -- solo articulos sin promo
          and pdi.artpromo = 0
          --valida el tipo de tarea consolidado Pedido en la tabla distribución
          and pdi.cdtipo = c_TareaConsolidadoComi
          --solo inserto para facturar los mayores a cero 
          and round(ccd.qtpiezaspicking * pdi.porcdist,0)>0                 
          -- solo pesables
          and nvl(ccd.qtpiezas,0)<>0
          --valida cesta navideña
          and pe.idcnpedido is null 
          --excluyo promo
          and dpe.icresppromo = 0 
          and cc.idconsolidadocomi = p_idconsolidado)
    loop
       v_resto:=pes.qtpiezaspicking;
       i := PESABLES_C.FIRST;       
       While i Is Not Null and v_resto > 0 Loop
         
         --verifica si esta libre el pesable para asignarlo al pedido
         if PESABLES_C(i).BANDERA = 0 
            and PESABLES_C(i).IDCONSOLIDADOPEDIDO = p_idconsolidado 
            and PESABLES_C(i).CDARTICULO = pes.cdarticulo then
            
            --marco el pesable como asignado
            PESABLES_C(i).BANDERA:=1;

            --se va restando el qtpiezaspick a la cantidad de piezas solicitadas
            v_resto:=v_resto-PESABLES_C(i).QTPIEZASPIK;
            
            --se inserta el valor del pesable uno a uno en tblslvpedidoconformado
            v_error:=' Error en insert tblslvpedidoconformado';   
            insert into tblslvpedidoconformado
             (idpedido,
              cdarticulo,
              sqdetallepedido,
              cdunidadmedida,
              qtunidadpedido,
              qtunidadmedidabase,
              qtpiezas,
              ampreciounitario,
              amlinea,
              vluxb,
              dsobservacion,
              icrespromo,
              cdpromo,
              dtinsert,
              dtupdate)
              values
              (
               pes.idpedido,
               pes.cdarticulo,
               SecuenciaPedConformado(pes.idpedido)+1,
               pes.cdunidadmedida,
               pes.qtunidadpedido,
               PESABLES_C(i).QTUNIDADMEDIDABASEPIK,
               PESABLES_C(i).QTPIEZASPIK,
               pes.ampreciounitario,
               pes.amlinea,
               pes.vluxb,
               pes.dsobservacion,
               pes.icresppromo,
               pes.cdpromo,
               sysdate,
               null);
               IF SQL%ROWCOUNT = 0 THEN
                    n_pkg_vitalpos_log_general.write(2,
                                      'Modulo: ' || v_modulo ||
                                      '  Detalle Error: ' || v_error);
    	              p_Ok    := 0;
                    p_error := 'Error en insert tblslvpedidoconformado. Comuniquese con Sistemas!';
                    ROLLBACK;
                    RETURN;
                END IF;
         end if; 
         i:= PESABLES_C.NEXT(i);
       End Loop;
    end loop;     
  --verifico si queda algún pesable por asignar   
  i := PESABLES_C.FIRST;       
  While i Is Not Null Loop       
     --verifica si esta libre el pesable para asignarlo al primer pedido libre
     if PESABLES_C(i).BANDERA = 0 
        and PESABLES_C(i).IDCONSOLIDADOPEDIDO = p_idconsolidado then 
        --OOOJJJJOOO falta por los redondeos ajustar aqui 
         p_Ok    := 0;
         p_error := 'Error en DISTRIBUCIÓN Pesables. Comuniquese con Sistemas!';   
     end if; 
     i:= PESABLES_C.NEXT(i);
   End Loop;  
  p_Ok    := 1;
  p_error := null; 
  EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       '  Error: ' || SQLERRM);
      p_Ok    := 0;
      p_error := 'Error en Pesables. Comuniquese con Sistemas!';                                  

  END DistPesablesC;
    
 /****************************************************************************************************
  * %v 18/06/2020 - ChM  Versión inicial DistribPromoPedido
  * %v 18/06/2020 - ChM  distribuye los articulos en promo del consolidado pedido
  * %v 02/06/2020 - Lerea Promociones:
  *                 No recuerdo cual es la lógica actual! La premisa es completar desde los pedidos 
  *                 más chicos a los más grandes, donde tendremos N pedidos full y puede que no sobre
  *                 mas o que sobre y cae sobre N+1 (no alcanzará la promo pero no podemos despickear
  *                 lo pickeado) y ya N+2 en adelante no tendrán SKU de la promo. Sería el caso que 
  *                 vimos recién de “Menor a Mayor” donde los que más piden, menos prioridad tendrán 
  *                 (incluso probabilidad de no recibir promo alguna).
  *                 Así fue la definición de Luciano, si es necesario lo revalidamos.
  *****************************************************************************************************/ 
  PROCEDURE DistribPromoPedido(p_idconsolidado       IN  tblslvconsolidadom.idconsolidadom%type,
                               p_Ok                  OUT number,
                               p_error               OUT varchar2) is
                           
    v_modulo       varchar2(100) := 'PKG_SLV_DISTRIBUCION.DistribPromoPedido';
    v_error        varchar2(250);
    
  BEGIN
  v_error:=' Error en insert tblslvpordistrib';
  --solo articulos en promo ordenados por el que menos compró en cantidad
  for promo in(
              select d.idconsolidado,
                     d.cdarticulo,
                     d.porcdist 
               from tblslvpordistrib d
              where d.cdtipo = c_TareaConsolidadoPedido
                and d.idconsolidado=p_idconsolidado
                -- valida solo articulos en promo
                and d.artpromo = 1
           order by d.qtunidadmedidabase,
                    d.cdarticulo) 
          loop
            null;
          end loop;
    p_Ok:=1;
    p_error:='';        
  EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       '  Detalle Error: ' || v_error ||
                                       '  Error: ' || SQLERRM);
      ROLLBACK;
  END DistribPromoPedido;
   
 /****************************************************************************************************
 * %v 05/06/2020 - ChM  Versión inicial SetDistribucionPedidoFaltante
 * %v 05/06/2020 - ChM  procedimiento para la distribución de los faltantes de pedidos
 * %v 05/06/2020 - ChM  Falta la distribución de pesables y promos además validar redondeos
 *****************************************************************************************************/
 
 PROCEDURE SetDistribucionPedidoFaltante(p_idpersona     IN personas.idpersona%type,
                                         p_IdPedFaltante IN Tblslvpedfaltante.Idpedfaltante%type,
                                         p_Ok            OUT number,
                                         p_error         OUT varchar2) IS
 
   v_modulo varchar2(100) := 'PKG_SLV_DISTRIBUCION.SetDistribucionPedidoFaltante';
   v_error  varchar2(250);
   v_pedfal Tblslvpedfaltante.Cdestado%type := null;
 
 BEGIN
   begin
     select f.cdestado
       into v_pedfal
       from tblslvpedfaltante f
      where f.idpedfaltante = p_IdPedFaltante;
   exception 
     when no_data_found then
       p_Ok    := 0;
       p_error := 'Error consolidado pedido faltante no existe.';
       RETURN;  
   end;
   --verifico si el faltante esta distribuido  
    if v_pedfal = C_DistribFaltanteConsolidaPed then  
       p_Ok    := 0;
       p_error := 'Error pedido faltante ya distribuido.';
       RETURN;    
    end if;
   --verifico si el faltante esta finalizado y se puede distribuir
     if v_pedfal <> C_FinalizaFaltaConsolidaPedido then  
       p_Ok    := 0;
       p_error := 'Error pedido faltante no finalizado. No es posible distribuir.';
       RETURN;    
    end if;
   
   --calcula los porcentajes que se aplicarán en la distribución de faltantes   
   PorcDistribFaltantes(p_IdPedFaltante,p_Ok,p_error);
   if P_OK = 0 then
     ROLLBACK;
     RETURN;
    END IF; 
     
   --inserto la distribución  del faltante
    v_error:= 'Error en insert tblslvdistribucionpedfaltante'; 
   insert into tblslvdistribucionpedfaltante
     (iddistribucionpedfaltante,
      idpedfaltanterel,
      cdarticulo,
      qtunidadmedidabase,
      qtpiezas)
     select seq_distribucionpedfaltante.nextval,
            A.idpedfaltanterel,           
            A.cdarticulo,
            A.QTDISTB,
            A.qtpiezaspicking
       from      
    (select frel.idpedfaltanterel,
            frel.idconsolidadopedido,
            fd.cdarticulo,
            --aplico el porcentaje a distribuir a los faltantes encontrados y redondeo 
            round(fd.qtunidadmedidabasepicking * pdis.porcdist,0) QTDISTB,
            fd.qtpiezaspicking           
       from tblslvpedfaltante          cf,
            tblslvpedfaltantedet       fd,
            tblslvpedfaltanterel       frel,
            tblslvconsolidadopedido    cp,
            tblslvconsolidadopedidodet cpd,
            tblslvconsolidadopedidorel cprel,
            tblslvpordistrib           pdis,
            pedidos                    pe
      where cf.idpedfaltante = fd.idpedfaltante
        and cf.idpedfaltante = fd.idpedfaltante
        and cp.idconsolidadopedido = cpd.idconsolidadopedido
        and cf.idpedfaltante = frel.idpedfaltante
        and frel.idconsolidadopedido = cp.idconsolidadopedido
        and frel.idpedfaltante = cf.idpedfaltante
        and cprel.idconsolidadopedido = cp.idconsolidadopedido
        and cprel.idpedido = pe.idpedido
        and pdis.idconsolidado = cf.idpedfaltante
        --valida el tipo de tarea de faltante en la tabla distribución
        and pdis.cdtipo = c_TareaConsolidaPedidoFaltante
        and pdis.idpedido = pe.idpedido
        and pdis.cdarticulo = cpd.cdarticulo
        --Excluyo articulos de promo
        and pdis.artpromo = 0
        and fd.cdarticulo = pdis.cdarticulo
        and cpd.cdarticulo = fd.cdarticulo
        -- excluyo pesables
        and nvl(fd.qtpiezas,0)=0
        --con valor pickiado
        and nvl(fd.qtunidadmedidabasepicking, 0) > 0
        --solo inserto los mayores a cero
        and round(fd.qtunidadmedidabasepicking * pdis.porcdist,0) > 0         
        and cf.idpedfaltante = p_IdPedFaltante) A ;
   IF SQL%ROWCOUNT = 0 THEN
     n_pkg_vitalpos_log_general.write(2,
                                      'Modulo: ' || v_modulo ||
                                      '  Detalle Error: ' || v_error);
     p_Ok    := 0;
     p_error := 'Error en insert tblslvdistribucionpedfaltante. Comuniquese con Sistemas!';
     ROLLBACK;
     RETURN;
   END IF;
   --verifico las diferencias que pudo generar los porcentajes de distribución de faltantes  OJO Revisar
   /*p_Ok    := VerificaDiferenciasFal(p_IdPedFaltante);
   if p_Ok  = 0 then
     p_ok    := 0;
     p_error := 'error en procentajes de Distribución. comuniquese con sistemas!';
     rollback;
     return;
   end if;*/
   
  --cargo la tabla en memoria con los pesables del consolidado faltante
  v_pedfal:=TempPesablesF(p_IdPedFaltante); 
    
  --verifica si existen pesables en el pedido y los distribuye
  if v_pedfal > 1 then 
     DistPesablesF(p_IdPedFaltante,p_ok,p_error);
     if p_Ok  = 0 then
       rollback;
       return;
     end if;
    end if;
   --creo los remitos de distribución de faltantes DISTINCT por los diferentes pedidos distribuidos
   for dist_rem in
       (  select 
        distinct df.idpedfaltanterel 
            from tblslvdistribucionpedfaltante df)
   loop
    p_Ok:=PKG_SLV_REMITOS.SetInsertarRemitoFaltante(dist_rem.idpedfaltanterel);
   end loop;
   if p_Ok = 0 then  
     p_Ok    := 0;
     p_error := 'Error en la creación de Remitos de faltante.Comuniquese con Sistemas!';
     ROLLBACK;
     RETURN;    
   end if;
   
  --Actualizo la tabla tblslvpedfaltante a estado distribuido
   v_error:= 'Error en update tblslvpedfaltante a estado distribuido'; 
   update tblslvpedfaltante pf
      set pf.cdestado=C_DistribFaltanteConsolidaPed,
          pf.dtupdate=sysdate
    where pf.idpedfaltante = p_IdPedFaltante;
   IF SQL%ROWCOUNT = 0 THEN
     n_pkg_vitalpos_log_general.write(2,
                                      'Modulo: ' || v_modulo ||
                                      '  Detalle Error: ' || v_error);
     p_Ok    := 0;
     p_error := 'Error en update tblslvpedfaltante a estado distribuido. Comuniquese con Sistemas!';
     ROLLBACK;
     RETURN;
   END IF;
   
  --Actualizo en tblslvpedfaltanterel para la persona que distribuye y la fecha de distribución
   v_error:= 'Error en update tblslvpedfaltanterel'; 
   update tblslvpedfaltanterel frel
      set frel.dtdistribucion        = sysdate,
          frel.idpersonadistribucion = p_idpersona,
          frel.dtupdate = sysdate
    where frel.idpedfaltante = p_IdPedFaltante;
   IF SQL%ROWCOUNT = 0 THEN
     n_pkg_vitalpos_log_general.write(2,
                                      'Modulo: ' || v_modulo ||
                                      '  Detalle Error: ' || v_error);
     p_Ok    := 0;
     p_error := 'Error en update tblslvpedfaltanterel. Comuniquese con Sistemas!';
     ROLLBACK;
     RETURN;
   END IF;
  
  --Actualizo la tabla tblslvconsolidadopedido con los articulos encontrados en la distribucion de faltante OJO revisar PESABLES
  v_error:= 'Error en update tblslvconsolidadopedidodet'; 
  update tblslvconsolidadopedidodet c
   set (c.qtunidadmedidabasepicking,c.qtpiezaspicking) = 
       (select (cpd.qtunidadmedidabasepicking+dfa.qtunidadmedidabase)base,
               (cpd.qtpiezaspicking+dfa.qtpiezas) piezas   
          from tblslvconsolidadopedido cp,
               tblslvconsolidadopedidodet cpd,
               tblslvdistribucionpedfaltante dfa,
               tblslvpedfaltanterel frel
         where cp.idconsolidadopedido = cpd.idconsolidadopedido
           and cp.idconsolidadopedido = frel.idconsolidadopedido
           and dfa.idpedfaltanterel = frel.idpedfaltanterel
           and dfa.cdarticulo = cpd.cdarticulo
           -- excluyo pesables
        --  and nvl(cpd.qtpiezas,0)=0
           and frel.idpedfaltante = p_IdPedFaltante
           and cpd.idconsolidadopedidodet=c.idconsolidadopedidodet)   
  where EXISTS (select 1                      
                  from tblslvconsolidadopedido cp,
                       tblslvconsolidadopedidodet cpd,
                       tblslvdistribucionpedfaltante dfa,
                       tblslvpedfaltanterel frel
                 where cp.idconsolidadopedido = cpd.idconsolidadopedido
                   and cp.idconsolidadopedido = frel.idconsolidadopedido
                   and dfa.idpedfaltanterel = frel.idpedfaltanterel
                   and dfa.cdarticulo = cpd.cdarticulo
                   -- excluyo pesables
                 --  and nvl(cpd.qtpiezas,0)=0
                   and frel.idpedfaltante = p_IdPedFaltante
                   and cpd.idconsolidadopedidodet = c.idconsolidadopedidodet); 
   IF SQL%ROWCOUNT = 0 THEN
     n_pkg_vitalpos_log_general.write(2,
                                      'Modulo: ' || v_modulo ||
                                      '  Detalle Error: ' || v_error);
     p_Ok    := 0;
     p_error := 'Error en update tblslvconsolidadopedidodet. Comuniquese con Sistemas!';
     ROLLBACK;
     RETURN;
   END IF;                    
   p_Ok    := 1;
   p_error := '';
 EXCEPTION
   WHEN OTHERS THEN
     n_pkg_vitalpos_log_general.write(2,
                                      'Modulo: ' || v_modulo ||
                                      '  Detalle Error: ' || v_error ||
                                      '  Error: ' || SQLERRM);
     p_Ok    := 0;
     p_error := 'Imposible Realizar Consolidado de Pedidos Faltantes. Comuniquese con Sistemas!';
     ROLLBACK;
 END SetDistribucionPedidoFaltante;
    
 
 /****************************************************************************************************
 * %v 05/06/2020 - ChM  Versión inicial SetDistribucionPedidos
 * %v 05/06/2020 - ChM  procedimiento para la distribución de los pedidos
 * %v 18/06/2020 - ChM  agrego pesables
 *****************************************************************************************************/
 
 PROCEDURE SetDistribucionPedidos(p_idpersona     IN personas.idpersona%type,
                                  p_IdPedidos     IN Tblslvconsolidadopedido.Idconsolidadopedido%type,
                                  p_Ok            OUT number,
                                  p_error         OUT varchar2) IS
 
   v_modulo varchar2(100) := 'PKG_SLV_DISTRIBUCION.SetDistribucionPedidoFaltante';
   v_error  varchar2(250);
   v_ped    Tblslvconsolidadopedido.Idconsolidadopedido%type:= null;
   v_estado tblslvconsolidadopedido.cdestado%type:=null;
 
 BEGIN
 
   begin
     select cp.cdestado
       into v_estado
       from tblslvconsolidadopedido cp
      where cp.idconsolidadopedido = p_IdPedidos;
   exception 
     when no_data_found then
       p_Ok    := 0;
       p_error := 'Error consolidado pedido N° '||p_IdPedidos||' no existe.';
       RETURN;   
   end;
    --verifico si el pedido ya esta Facturado
    if v_estado = C_AFacturarConsolidadoPedido then  
       p_Ok    := 0;
       p_error := 'Error consolidado pedido N° '||p_IdPedidos||' ya facturado.';
       RETURN;    
    end if; 
   --verifico si el pedido esta cerrado y se puede distribuir  
    if v_estado <> C_CerradoConsolidadoPedido then  
       p_Ok    := 0;
       p_error := 'Error consolidado pedido N° '||p_IdPedidos||' no cerrado. No es posible Facturar.';
       RETURN;    
    end if;

   --verifico si el consolidado pedido no tiene picking
   begin
     select count(*)
       into v_ped
       from tblslvconsolidadopedido cp,
            tblslvconsolidadopedidodet cpd
      where cpd.idconsolidadopedido = cp.idconsolidadopedido
        and nvl(cpd.qtunidadmedidabasepicking,0)<>0
        and cp.idconsolidadopedido = p_IdPedidos;
   exception 
     when no_data_found then
       p_Ok    := 0;
       p_error := 'Error consolidado pedido N° '||p_IdPedidos||' no existe.';
       RETURN;  
   end;
    if v_ped = 0 then  
       p_Ok    := 0;
       p_error := 'Error consolidado pedido N° '||p_IdPedidos|| 'no tiene artículos a facturar.';
       RETURN;    
    end if;    
    
   --calcula los porcentajes que se aplicarán en la distribución de pedidos 
   PorcDistribConsolidado(p_IdPedidos,p_Ok,p_error);
   if P_OK = 0 then
     ROLLBACK;
     RETURN;
    END IF; 
    
 --inserto la distribución del pedido en tblslvpedidoconformado
 v_error:= 'Error en insert en tblslvpedidoconformado';    
 for conformado in(
                   select pe.idpedido,
                          dpe.cdarticulo,
                          SecuenciaPedConformado(pe.idpedido)+1 secuencia,
                          dpe.cdunidadmedida,
                          dpe.qtunidadpedido,
                          round(cpd.qtunidadmedidabasepicking * pdi.porcdist,0)qtbase,
                          cpd.qtpiezaspicking,       
                          dpe.ampreciounitario,
                          dpe.amlinea,
                          dpe.vluxb,
                          nvl(dpe.dsobservacion,'-') dsobservacion,
                          dpe.icresppromo,
                          dpe.cdpromo,
                          sysdate dtinsert,
                          null dtupdate  
                     from pedidos                      pe,   
                          detallepedidos               dpe,
                          tblslvconsolidadopedidorel   cprel,        
                          tblslvconsolidadopedido      cp,
                          tblslvconsolidadopedidodet   cpd,
                          tblslvpordistrib             pdi        
                    where pe.idpedido = dpe.idpedido
                      and pe.idpedido = cprel.idpedido
                      and cprel.idconsolidadopedido = cp.idconsolidadopedido
                      and cp.idconsolidadopedido = cpd.idconsolidadopedido
                      and cpd.cdarticulo = dpe.cdarticulo
                      and pdi.idpedido = pe.idpedido
                      and pdi.idconsolidado = cp.idconsolidadopedido
                      and pdi.cdarticulo = cpd.cdarticulo
                      -- solo articulos sin promo
                      and pdi.artpromo = 0
                      --valida el tipo de tarea consolidado Pedido en la tabla distribución
                      and pdi.cdtipo = c_TareaConsolidadoPedido
                      --solo inserto para facturar los mayores a cero 
                      and round(cpd.qtunidadmedidabasepicking * pdi.porcdist,0)>0                 
                      -- excluyo pesables
                      and nvl(cpd.qtpiezas,0)=0
                      --valida cesta navideña
                      and pe.idcnpedido is null 
                      --excluyo promo
                      and dpe.icresppromo = 0 
                      --excluyo comisionistas
                      and cp.idconsolidadocomi is null
                      and cp.idconsolidadopedido = p_IdPedidos)
     loop
       insert into tblslvpedidoconformado
                   (idpedido,
                    cdarticulo,
                    sqdetallepedido,
                    cdunidadmedida,
                    qtunidadpedido,
                    qtunidadmedidabase,
                    qtpiezas,
                    ampreciounitario,
                    amlinea,
                    vluxb,
                    dsobservacion,
                    icrespromo,
                    cdpromo,
                    dtinsert,
                    dtupdate)
                    values 
                    (conformado.idpedido,
                     conformado.cdarticulo,
                     conformado.secuencia,
                     conformado.cdunidadmedida,
                     conformado.qtunidadpedido,
                     conformado.qtbase,
                     conformado.qtpiezaspicking,
                     conformado.ampreciounitario,
                     conformado.amlinea,
                     conformado.vluxb,
                     conformado.dsobservacion,
                     conformado.icresppromo,
                     conformado.cdpromo,
                     conformado.dtinsert,
                     conformado.dtupdate);
         IF SQL%ROWCOUNT = 0 THEN
             n_pkg_vitalpos_log_general.write(2,
                                              'Modulo: ' || v_modulo ||
                                              '  Detalle Error: ' || v_error);                                            
             p_Ok    := 0;
             p_error := 'Error en inserttblslvpedidoconformado. Comuniquese con Sistemas!';
             ROLLBACK;
             RETURN;
           END IF;   
       end loop;           
  --Actualizo la tabla tblslvconsolidado pedido a estado C_AFacturarConsolidadoPedido
   v_error:= 'Error en update tblslvconsolidado a estado "a Facturar"'; 
   update tblslvconsolidadopedido cp
      set cp.cdestado = C_AFacturarConsolidadoPedido,
          cp.idpersona = p_idpersona,
          cp.dtupdate = sysdate
    where cp.idconsolidadopedido = p_IdPedidos;
   IF SQL%ROWCOUNT = 0 THEN
     n_pkg_vitalpos_log_general.write(2,
                                      'Modulo: ' || v_modulo ||
                                      '  Detalle Error: ' || v_error);
     p_Ok    := 0;
     p_error := 'Error en update tblslvconsolidado a estado "a Facturar". Comuniquese con Sistemas!';
     ROLLBACK;
     RETURN;
   END IF;
   
   --verifico las diferencias que pudo generar los porcentajes de distribución OJO REVISAR    
   /*p_Ok    := VerificaDiferenciasP(p_IdPedidos);
   if p_Ok  = 0 then
     p_ok    := 0;
     p_error := 'error en procentajes de Distribución. comuniquese con sistemas!';
     rollback;
     return;
   end if;*/
  
  --cargo la tabla en memoria con los pesables del consolidado pedido
  v_ped:=TempPesablesP(p_IdPedidos); 
    
  --verifica si existen pesables en el pedido y los distribuye
  if v_ped > 1 then 
     DistPesablesP(p_IdPedidos,p_ok,p_error);
     if p_Ok  = 0 then
       rollback;
       return;
     end if;
    end if;
   -- inserto en la DETPEDIDOCONFORMADO
   v_error:= 'Error en insert en DETPEDIDOCONFORMADO'; 
   insert into DETPEDIDOCONFORMADO
               (idpedido,
                sqdetallepedido,
                cdunidadmedida,
                cdarticulo,
                qtunidadpedido,
                qtunidadmedidabase,
                qtpiezas,
                ampreciounitario,
                amlinea,
                vluxb,
                dsobservacion,
                icresppromo,
                cdpromo,
                dsarticulo)
        select pc.idpedido,
               pc.sqdetallepedido,
               pc.cdunidadmedida,
               pc.cdarticulo,
               pc.qtunidadpedido,
               pc.qtunidadmedidabase,
               pc.qtpiezas,
               pc.ampreciounitario,
               pc.amlinea,
               pc.vluxb,
               pc.dsobservacion,
               pc.icrespromo,
               pc.cdpromo,
               des.vldescripcion
          from tblslvpedidoconformado       pc,
               tblslvconsolidadopedido      cp,
               tblslvconsolidadopedidorel   cprel,
               pedidos                      pe,
               descripcionesarticulos       des
         where pe.idpedido = cprel.idpedido
           and cprel.idconsolidadopedido = cp.idconsolidadopedido
           and pc.idpedido = pe.idpedido
           and pc.cdarticulo = des.cdarticulo
           and cp.idconsolidadopedido = p_IdPedidos;
           IF SQL%ROWCOUNT = 0 THEN
               n_pkg_vitalpos_log_general.write(2,
                                                'Modulo: ' || v_modulo ||
                                                '  Detalle Error: ' || v_error);
               p_Ok    := 0;
               p_error := 'Error en insert en DETPEDIDOCONFORMADO. Comuniquese con Sistemas!';
               ROLLBACK;
               RETURN;
           END IF;   
   p_Ok    := 1;
   p_error := '';
   EXCEPTION
     WHEN OTHERS THEN
       n_pkg_vitalpos_log_general.write(2,
                                        'Modulo: ' || v_modulo ||
                                        '  Detalle Error: ' || v_error ||
                                        '  Error: ' || SQLERRM);
       p_Ok    := 0;
       p_error := 'Imposible enviar a Facturar el Consolidado Pedido  N° '||p_IdPedidos||'. Comuniquese con Sistemas!';
       ROLLBACK;
 END SetDistribucionPedidos;
 
  /****************************************************************************************************
 * %v 19/06/2020 - ChM  Versión inicial SetDistribucionComi
 * %v 19/06/2020 - ChM  procedimiento para la distribución de los pedidos de comisionista
 *****************************************************************************************************/
 
 PROCEDURE SetDistribucionComi(p_idpersona     IN personas.idpersona%type,
                               p_IdComi        IN Tblslvconsolidadopedido.Idconsolidadopedido%type,
                               p_Ok            OUT number,
                               p_error         OUT varchar2) IS
 
   v_modulo varchar2(100) := 'PKG_SLV_DISTRIBUCION.SetDistribucionComi';
   v_error  varchar2(250);
   v_ped    Tblslvconsolidadopedido.Idconsolidadopedido%type:= null;
   v_estado tblslvconsolidadopedido.cdestado%type:=null;
 
 BEGIN
        
   begin
     select cc.cdestado
       into v_estado
       from tblslvconsolidadocomi cc
      where cc.idconsolidadocomi = p_IdComi;
   exception 
     when no_data_found then
       p_Ok    := 0;
       p_error := 'Error consolidado comisionista N° '||p_IdComi||' no existe.';
       RETURN;   
   end;
    --verifico si el pedido comi ya esta distribuido
    if v_estado = C_DistribuidoConsolidadoComi then  
       p_Ok    := 0;
       p_error := 'Error consolidado Comisionista N° '||p_IdComi||' ya Distribuido.';
       RETURN;    
    end if; 
   --verifico si el pedido esta cerrado y se puede distribuir  
    if v_estado <> C_FinalizadoConsolidadoComi  then  
       p_Ok    := 0;
       p_error := 'Error consolidado comisionista N° '||p_IdComi||' no finalizado. No es posible Facturar.';
       RETURN;    
    end if;

   --verifico si el consolidado comi no tiene picking
   begin
     select count(*)
       into v_ped
       from tblslvconsolidadocomi cc,
            tblslvconsolidadocomidet ccd
      where ccd.idconsolidadocomi=cc.idconsolidadocomi
        and nvl(ccd.qtunidadmedidabasepicking,0)<>0
        and cc.idconsolidadocomi = p_IdComi;
   exception 
     when no_data_found then
       p_Ok    := 0;
       p_error := 'Error consolidado comisionista N° '||p_IdComi||' no existe.';
       RETURN;  
   end;
    if v_ped = 0 then  
       p_Ok    := 0;
       p_error := 'Error consolidado comisionista N° '||p_IdComi|| 'no tiene artículos a facturar.';
       RETURN;    
    end if;    
    
   --calcula los porcentajes que se aplicarán en la distribución de consolidados comi
   PorcDistribComi(p_IdComi,p_Ok,p_error);
   if P_OK = 0 then
    rollback;
     return;
    end if;
    
 --inserto la distribución del pedido en tblslvpedidoconformado
 v_error:= 'Error en insert en tblslvpedidoconformado';    
 for conformado in(
                  select pe.idpedido,
                          dpe.cdarticulo,
                          SecuenciaPedConformado(pe.idpedido)+1 secuencia,
                          dpe.cdunidadmedida,
                          dpe.qtunidadpedido,
                          round(ccd.qtunidadmedidabasepicking * pdi.porcdist,0)qtbase,
                          ccd.qtpiezaspicking,       
                          dpe.ampreciounitario,
                          dpe.amlinea,
                          dpe.vluxb,
                          nvl(dpe.dsobservacion,'-') dsobservacion,
                          dpe.icresppromo,
                          dpe.cdpromo,
                          sysdate dtinsert,
                          null dtupdate  
                     from pedidos                      pe,   
                          detallepedidos               dpe,
                          tblslvconsolidadopedidorel   cprel,        
                          tblslvconsolidadopedido      cp,
                          tblslvconsolidadocomi        cc,
                          tblslvconsolidadocomidet     ccd,                         
                          tblslvpordistrib             pdi        
                    where pe.idpedido = dpe.idpedido
                      and pe.idpedido = cprel.idpedido
                      and cprel.idconsolidadopedido = cp.idconsolidadopedido
                      and cp.idconsolidadocomi = cc.idconsolidadocomi
                      and cc.idconsolidadocomi = ccd.idconsolidadocomi
                      and ccd.cdarticulo = dpe.cdarticulo
                      and pdi.idpedido = pe.idpedido
                      and pdi.idconsolidado = cc.idconsolidadocomi
                      and pdi.cdarticulo = ccd.cdarticulo
                      -- solo articulos sin promo
                      and pdi.artpromo = 0
                      --valida el tipo de tarea consolidado Pedido en la tabla distribución
                      and pdi.cdtipo = c_TareaConsolidadoComi
                      --solo inserto para facturar los mayores a cero 
                      and round(ccd.qtunidadmedidabasepicking * pdi.porcdist,0)>0                 
                      -- excluyo pesables
                      and nvl(ccd.qtpiezas,0)=0
                      --valida cesta navideña
                      and pe.idcnpedido is null 
                      --excluyo promo
                      and dpe.icresppromo = 0 
                      and cc.idconsolidadocomi = p_IdComi)
     loop
       insert into tblslvpedidoconformado
                   (idpedido,
                    cdarticulo,
                    sqdetallepedido,
                    cdunidadmedida,
                    qtunidadpedido,
                    qtunidadmedidabase,
                    qtpiezas,
                    ampreciounitario,
                    amlinea,
                    vluxb,
                    dsobservacion,
                    icrespromo,
                    cdpromo,
                    dtinsert,
                    dtupdate)
                    values 
                    (conformado.idpedido,
                     conformado.cdarticulo,
                     conformado.secuencia,
                     conformado.cdunidadmedida,
                     conformado.qtunidadpedido,
                     conformado.qtbase,
                     conformado.qtpiezaspicking,
                     conformado.ampreciounitario,
                     conformado.amlinea,
                     conformado.vluxb,
                     conformado.dsobservacion,
                     conformado.icresppromo,
                     conformado.cdpromo,
                     conformado.dtinsert,
                     conformado.dtupdate);
         IF SQL%ROWCOUNT = 0 THEN
             n_pkg_vitalpos_log_general.write(2,
                                              'Modulo: ' || v_modulo ||
                                              '  Detalle Error: ' || v_error);                                            
             p_Ok    := 0;
             p_error := 'Error en inserttblslvpedidoconformado. Comuniquese con Sistemas!';
             ROLLBACK;
             RETURN;
           END IF;   
       end loop;       
       
    --Actualizo la tabla tblslvconsolidadocomi a estado C_DistribuidoConsolidadoComi  
   v_error:= 'Error en update tblslvconsolidadocomi a estado "Distribuido"'; 
   update tblslvconsolidadocomi cc
      set cc.cdestado = C_DistribuidoConsolidadoComi,
          cc.idpersona = p_idpersona,
          cc.dtupdate = sysdate
    where cc.idconsolidadocomi = p_IdComi;
   IF SQL%ROWCOUNT = 0 THEN
     n_pkg_vitalpos_log_general.write(2,
                                      'Modulo: ' || v_modulo ||
                                      '  Detalle Error: ' || v_error);
     p_Ok    := 0;
     p_error := 'Error en update tblslvconsolidadocomi a estado "Distribuido". Comuniquese con Sistemas!';
     ROLLBACK;
     RETURN;
   END IF;         
    
   --verifico las diferencias que pudo generar los porcentajes de distribución OJO FALTA    
  /* p_Ok    := VerificaDiferenciasC(p_IdPedidos);
   if p_Ok  = 0 then
     p_ok    := 0;
     p_error := 'error en procentajes de Distribución. comuniquese con sistemas!';
     rollback;
     return;
   end if;*/
  
  --cargo la tabla en memoria con los pesables del consolidado COMI
  v_ped:=TempPesablesC(p_IdComi); 
    
  --verifica si existen pesables en el pedido y los distribuye  
  if v_ped > 1 then 
     DistPesablesC(p_IdComi,p_ok,p_error);
     if p_Ok  = 0 then
       rollback;
       return;
     end if;
    end if;
    
   --Actualizo la tabla tblslvconsolidado pedido a estado C_AFacturarConsolidadoPedido
   v_error:= 'Error en update tblslvconsolidado a estado "a Facturar"'; 
   update tblslvconsolidadopedido cp
      set cp.cdestado = C_AFacturarConsolidadoPedido,
          cp.idpersona = p_idpersona,
          cp.dtupdate = sysdate
    where cp.idconsolidadocomi = p_IdComi;
   IF SQL%ROWCOUNT = 0 THEN
     n_pkg_vitalpos_log_general.write(2,
                                      'Modulo: ' || v_modulo ||
                                      '  Detalle Error: ' || v_error);
     p_Ok    := 0;
     p_error := 'Error en update tblslvconsolidado a estado "a Facturar". Comuniquese con Sistemas!';
     ROLLBACK;
     RETURN;
   END IF; 
   --Actualizo la tabla tblslvconsolidadopedidodet con los datos del picking del comi
   for ped in (
              select cpd.idconsolidadopedidodet,
                     cp.idconsolidadopedido,
                     pc.cdarticulo,               
                     sum(pc.qtunidadmedidabase) qtbase,
                     sum(pc.qtpiezas) qtpiezas,
                     cpd.idgrupo_sector
                from tblslvpedidoconformado       pc,
                     tblslvconsolidadopedido      cp,
                     tblslvconsolidadopedidodet   cpd,
                     tblslvconsolidadopedidorel   cprel,
                     pedidos                      pe              
               where pe.idpedido = cprel.idpedido
                 and cprel.idconsolidadopedido = cp.idconsolidadopedido
                 and pc.idpedido = pe.idpedido
                 and cp.idconsolidadopedido = cpd.idconsolidadopedido
                 and pc.cdarticulo = cpd.cdarticulo
                --solo los consolidados del comisionistas
                 and cp.idconsolidadopedido in 
                                           (select cp2.idconsolidadopedido 
                                              from tblslvconsolidadopedido cp2
                                             where cp2.idconsolidadocomi = p_IdComi) 
            group by cpd.idconsolidadopedidodet,
                     cp.idconsolidadopedido,
                     pc.cdarticulo,                         
                     cpd.idgrupo_sector) 
    loop 
      update tblslvconsolidadopedidodet cpd
         set cpd.qtunidadmedidabasepicking = ped.qtbase,
             cpd.qtpiezaspicking = ped.qtpiezas
       where cpd.idconsolidadopedidodet = ped.idconsolidadopedidodet
         and cpd.idconsolidadopedido = ped.idconsolidadopedido
         and cpd.cdarticulo = ped.cdarticulo 
         and cpd.idgrupo_sector = ped.idgrupo_sector;   
      IF SQL%ROWCOUNT = 0 THEN
             n_pkg_vitalpos_log_general.write(2,
                                              'Modulo: ' || v_modulo ||
                                              '  Detalle Error: ' || v_error);                                            
             p_Ok    := 0;
             p_error := 'Error actualizando tblslvconsolidadopedidodet . Comuniquese con Sistemas!';
             ROLLBACK;
             RETURN;
           END IF;   
      end loop;                 
    
    
   -- inserto en la DETPEDIDOCONFORMADO
   v_error:= 'Error en insert en DETPEDIDOCONFORMADO'; 
   insert into DETPEDIDOCONFORMADO
               (idpedido,
                sqdetallepedido,
                cdunidadmedida,
                cdarticulo,
                qtunidadpedido,
                qtunidadmedidabase,
                qtpiezas,
                ampreciounitario,
                amlinea,
                vluxb,
                dsobservacion,
                icresppromo,
                cdpromo,
                dsarticulo)
        select pc.idpedido,
               pc.sqdetallepedido,
               pc.cdunidadmedida,
               pc.cdarticulo,
               pc.qtunidadpedido,
               pc.qtunidadmedidabase,
               pc.qtpiezas,
               pc.ampreciounitario,
               pc.amlinea,
               pc.vluxb,
               pc.dsobservacion,
               pc.icrespromo,
               pc.cdpromo,
               des.vldescripcion
          from tblslvpedidoconformado       pc,
               tblslvconsolidadopedido      cp,
               tblslvconsolidadopedidorel   cprel,
               pedidos                      pe,
               descripcionesarticulos       des
         where pe.idpedido = cprel.idpedido
           and cprel.idconsolidadopedido = cp.idconsolidadopedido
           and pc.idpedido = pe.idpedido
           and pc.cdarticulo = des.cdarticulo
           and cp.idconsolidadopedido = p_IdComi;
           IF SQL%ROWCOUNT = 0 THEN
               n_pkg_vitalpos_log_general.write(2,
                                                'Modulo: ' || v_modulo ||
                                                '  Detalle Error: ' || v_error);
               p_Ok    := 0;
               p_error := 'Error en insert en DETPEDIDOCONFORMADO. Comuniquese con Sistemas!';
               ROLLBACK;
               RETURN;
           END IF;   
   p_Ok    := 1;
   p_error := '';
   EXCEPTION
     WHEN OTHERS THEN
       n_pkg_vitalpos_log_general.write(2,
                                        'Modulo: ' || v_modulo ||
                                        '  Detalle Error: ' || v_error ||
                                        '  Error: ' || SQLERRM);
       p_Ok    := 0;
       p_error := 'Imposible enviar a Facturar el Consolidado Comisionista. Comuniquese con Sistemas!';
       ROLLBACK;
 END SetDistribucionComi;
 
 
 /****************************************************************************************************
  * %v 22/06/2020 - ChM  Versión inicial SetDistribucion
  * %v 22/06/2020 - ChM  procedimiento para la distribución de los pedidos 
  *****************************************************************************************************/
  PROCEDURE SetDistribucion     (p_idpersona     IN personas.idpersona%type,
                                 p_Idconsolidado IN Tblslvconsolidadopedido.Idconsolidadopedido%type,
                                 p_TipoTarea     IN tblslvtipotarea.cdtipo%type,
                                 p_Ok            OUT number,
                                 p_error         OUT varchar2) IS

  BEGIN
  
   --TipoTarea 25 
   if p_TipoTarea = c_TareaConsolidadoPedido then
      SetDistribucionPedidos(p_idpersona,p_Idconsolidado,p_Ok,p_error);
     if p_Ok <> 1 then      
        ROLLBACK;
        RETURN;
       end if;
   end if;
   --TipoTarea 40
   if p_TipoTarea = c_TareaConsolidaPedidoFaltante then
      SetDistribucionPedidoFaltante(p_idpersona,p_Idconsolidado,p_Ok,p_error);
    if p_Ok <> 1 then       
        ROLLBACK;
        RETURN;
       end if;
   end if;
   --TipoTarea 50
   if p_TipoTarea = c_TareaConsolidadoComi  then
      SetDistribucionComi(p_idpersona,p_Idconsolidado,p_Ok,p_error);
    if p_Ok <> 1 then
        ROLLBACK;
        RETURN;
       end if;
   end if;
  commit;  
  END SetDistribucion;

 
end PKG_SLV_DISTRIBUCION;
/
