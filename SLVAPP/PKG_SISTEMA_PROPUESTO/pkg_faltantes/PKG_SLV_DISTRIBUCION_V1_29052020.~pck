CREATE OR REPLACE PACKAGE PKG_SLV_DISTRIBUCION is
  /**********************************************************************************************************
  * Author  : CMALDONADO_C
  * Created : 29/05/2020 12:50:03 p.m.
  * %v Paquete para la DISTRIBUCION de pedidos en SLV
  **********************************************************************************************************/
  -- Tipos de datos

  TYPE CURSOR_TYPE IS REF CURSOR;
  
  FUNCTION TotalArtConsolidado(p_idconsolidado    tblslvconsolidadom.idconsolidadom%type,
                               p_CdArticulo        articulos.cdarticulo%type)
                                return number;                                                                    
  PROCEDURE PorcDistribConsolidado(p_idconsolidado      IN  tblslvconsolidadom.idconsolidadom%type,
                                   p_Ok                  OUT number,
                                   p_error               OUT varchar2); 
                                   
  FUNCTION TotalArtfaltante(p_idconsolidado     tblslvconsolidadom.idconsolidadom%type,
                            p_CdArticulo        articulos.cdarticulo%type)
                                return number;    
                                
  PROCEDURE PorcDistribFaltantes(p_idconsolidado       IN  tblslvconsolidadom.idconsolidadom%type,
                                 p_Ok                  OUT number,
                                 p_error               OUT varchar2);                                                             

end PKG_SLV_DISTRIBUCION;
/
CREATE OR REPLACE PACKAGE BODY PKG_SLV_DISTRIBUCION is
  /***************************************************************************************************
  *  %v 29/05/2020  ChM - Parametros globales privados
  ****************************************************************************************************/
  /****************************************************************************************************
  * %v 29/05/2020 - ChM  Versión inicial TotalArtConsolidado
  * %v 29/05/2020 - ChM  calcula el total en qtbase de un artículo para un consolidado pedido               
  *****************************************************************************************************/ 
  FUNCTION TotalArtConsolidado(p_idconsolidado     tblslvconsolidadom.idconsolidadom%type,
                               p_CdArticulo        articulos.cdarticulo%type)
                                return number is
   v_cantArt                    number(14,2):=0;
                               
  BEGIN
    select sum(dp.qtunidadmedidabase) qtbase
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
  * %v 29/05/2020 - ChM  Versión inicial PorcDistribConsolidadoM
  * %v 29/05/2020 - ChM  calcula el procentaje de participación en
  *                      un articulo de pedido con respecto a todo el consolidadopedido
  *****************************************************************************************************/ 
  PROCEDURE PorcDistribConsolidado(p_idconsolidado      IN  tblslvconsolidadom.idconsolidadom%type,
                                   p_Ok                  OUT number,
                                   p_error               OUT varchar2) is
                           
    v_modulo       varchar2(100) := 'PKG_SLV_DISTRIBUCION.PorcDistribConsolidado';
    v_error        varchar2(250);
    
  BEGIN
  v_error:=' Error en insert tblslvpordistrib';
  
  --borro porcentajes para el consolidado
  delete tblslvpordistrib pd
   where pd.idconsolidadopedido = p_idconsolidado;
   
  insert into tblslvpordistrib
              (idpedido,
               idconsolidadopedido,
               cdarticulo,
               qtunidadmedidabase,
               totalconsolidado,
               porcdist,
               dtinsert)
       select p.idpedido,
              cp.idconsolidadopedido,
              dp.cdarticulo,
              sum(dp.qtunidadmedidabase) qtbase,
              TotalArtConsolidado(p_idconsolidado,dp.cdarticulo) totalart,
              ROUND((sum(dp.qtunidadmedidabase)/
              TotalArtConsolidado(p_idconsolidado,dp.cdarticulo))*100) porc,
              sysdate
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
              dp.cdarticulo 
     order by dp.cdarticulo;
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
  END PorcDistribConsolidado;
  
   /****************************************************************************************************
  * %v 29/05/2020 - ChM  Versión inicial TotalArtConsolidado
  * %v 29/05/2020 - ChM  calcula el total en qtbase de un artículo para un idfaltante          
  *****************************************************************************************************/ 
  FUNCTION TotalArtfaltante(p_idconsolidado     tblslvconsolidadom.idconsolidadom%type,
                            p_CdArticulo        articulos.cdarticulo%type)
                                return number is
   v_cantArt                    number(14,2):=0;
                               
  BEGIN
    select sum(cpd.qtunidadesmedidabase) qtbase
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
  * %v 29/05/2020 - ChM  calcula el procentaje de participación en
  *                      un articulo de pedido con respecto a un idfaltante
  *****************************************************************************************************/ 
  PROCEDURE PorcDistribFaltantes(p_idconsolidado       IN  tblslvconsolidadom.idconsolidadom%type,
                                 p_Ok                  OUT number,
                                 p_error               OUT varchar2) is
                           
    v_modulo       varchar2(100) := 'PKG_SLV_DISTRIBUCION.PorcDistribFaltantes';
    v_error        varchar2(250);
    
  BEGIN
  v_error:=' Error en insert tblslvpordistribfal';
  
  --borro porcentajes para el consolidado faltante
  delete tblslvpordistribfal pdf
   where pdf.idpedfaltante = p_idconsolidado;
   
  insert into tblslvpordistribfal
    (idpedido,
     idpedfaltante,
     cdarticulo,
     qtunidadmedidabase,
     totalconsolidado,
     porcdist,
     dtinsert)
    select p.idpedido,
           pf.idpedfaltante,
           cpd.cdarticulo,
           sum(cpd.qtunidadesmedidabase) qtbase,
           TotalArtfaltante(p_idconsolidado,cpd.cdarticulo) totalart,
           ROUND((sum(cpd.qtunidadesmedidabase)/
           TotalArtfaltante(p_idconsolidado,cpd.cdarticulo))*100) porc,
           sysdate
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
           cpd.cdarticulo     
  order by cpd.cdarticulo;

      IF SQL%ROWCOUNT = 0  THEN      
          n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       '  Detalle Error: ' || v_error);
   	      p_Ok:=0;
          p_error:='Error en insert tblslvpordistribfal. Comuniquese con Sistemas!';
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
  * %v 27/05/2020 - ChM  Versión inicial SetDistribucionPedidoFaltante
  * %v 27/05/2020 - ChM  procedimiento para la distribucion de los faltantes de pedidos
  *****************************************************************************************************/ 

 PROCEDURE SetDistribucionPedidoFaltante(p_idpersona           IN  personas.idpersona%type,
                                         p_IdPedFaltante       IN  Tblslvpedfaltante.Idpedfaltante%type,
                                         p_Ok                  OUT number,
                                         p_error               OUT varchar2) IS

    v_modulo       varchar2(100) := 'PKG_SLV_DISTRIBUCION.SetDistribucionPedidoFaltante';
    v_error        varchar2(250);
   -- v_idpedido     pedidos.idpedido%type := null;
    
  BEGIN
    --Actualizo en tblslvpedfaltanterel para la persona que distribuye y la fecha de distribución
    update tblslvpedfaltanterel frel
    set frel.dtdistribucion = sysdate,
        frel.idpersonadistribucion = p_idpersona
    where frel.idpedfaltante=p_IdPedFaltante; 
    IF SQL%ROWCOUNT = 0  THEN      
          n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       '  Detalle Error: ' || v_error);
   	      p_Ok:=0;
          p_error:='Error en update tblslvpedfaltanterel. Comuniquese con Sistemas!';
          ROLLBACK;
          RETURN;
       END IF;  
    
       for faltante in 
                (select frel.idpedfaltanterel,
                        fd.cdarticulo,      
                        fd.qtunidadmedidabasepicking,
                        fd.qtpiezaspicking
                   from tblslvpedfaltante cf,
                        tblslvpedfaltantedet fd,
                        tblslvpedfaltanterel frel,
                        tblslvconsolidadopedido cp,
                        tblslvconsolidadopedidodet cpd          
                  where cf.idpedfaltante = fd.idpedfaltante       
                    and cf.idpedfaltante = frel.idpedfaltante
                    and frel.idconsolidadopedido = cp.idconsolidadopedido
                    and cp.idconsolidadopedido = cpd.idconsolidadopedido
                    and fd.cdarticulo = cpd.cdarticulo
                    --solo artículos pikiados
                    and fd.qtunidadmedidabasepicking is not null
                    --con valor pickiado
                    and fd.qtunidadmedidabasepicking > 0
                    and cf.idpedfaltante = p_IdPedFaltante)
      loop              
       --Calculo y guardo el porcentaje que se debe aplicar para la distribución de cada cdarticulo 
      
                   
      
      null;         
      end loop;             
      
    --inserto en tblslvdistribucionpedfaltante los cdarticulo que se pikearon en el faltante
    /*insert into tblslvdistribucionpedfaltante
                (iddistribucionpedfaltante,
                 idpedfaltanterel,
                 cdarticulo,
                 qtunidadmedidabase,
                 qtpiezas)
                 select seq_distribucionpedfaltante.nextval,
                        frel.idpedfaltanterel,
                        fd.cdarticulo,      
                        fd.qtunidadmedidabasepicking,
                        fd.qtpiezaspicking
                   from tblslvpedfaltante cf,
                        tblslvpedfaltantedet fd,
                        tblslvpedfaltanterel frel,
                        tblslvconsolidadopedido cp,
                        tblslvconsolidadopedidodet cpd          
                  where cf.idpedfaltante = fd.idpedfaltante       
                    and cf.idpedfaltante = frel.idpedfaltante
                    and frel.idconsolidadopedido = cp.idconsolidadopedido
                    and cp.idconsolidadopedido = cpd.idconsolidadopedido
                    and fd.cdarticulo = cpd.cdarticulo
                    --solo artículos pikiados
                    and fd.qtunidadmedidabasepicking is not null
                    --con valor pickiado
                    and fd.qtunidadmedidabasepicking > 0
                    and cf.idpedfaltante = p_IdPedFaltante;        
    IF SQL%ROWCOUNT = 0  THEN      
          n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       '  Detalle Error: ' || v_error);
   	      p_Ok:=0;
          p_error:='Error en insert tblslvdistribucionpedfaltante. Comuniquese con Sistemas!';
          ROLLBACK;
          RETURN;
       END IF;   */
    p_Ok:=1;
    p_error:='';   
    commit;
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
    
end PKG_SLV_DISTRIBUCION;
/
