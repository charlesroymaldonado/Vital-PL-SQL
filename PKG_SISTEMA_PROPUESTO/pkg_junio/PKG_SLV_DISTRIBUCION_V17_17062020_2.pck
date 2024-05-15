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
    IDPEDIDO                PEDIDOS.IDPEDIDO%TYPE
    );

   TYPE PESABLES IS TABLE OF PESABLE INDEX BY BINARY_INTEGER;
   PESABLES_P PESABLES;
  
 PROCEDURE SetDistribucionPedidoFaltante(p_idpersona     IN personas.idpersona%type,
                                         p_IdPedFaltante IN Tblslvpedfaltante.Idpedfaltante%type,
                                         p_Ok            OUT number,
                                         p_error         OUT varchar2); 
  
 PROCEDURE SetDistribucionPedidos(p_idpersona     IN personas.idpersona%type,
                                  p_IdPedidos     IN Tblslvconsolidadopedido.Idconsolidadopedido%type,
                                  p_Ok            OUT number,
                                  p_error         OUT varchar2);
  --USO INTERNO DEL PKG
  
  FUNCTION TotalArtConsolidado(p_idconsolidado    tblslvconsolidadom.idconsolidadom%type,
                               p_CdArticulo        articulos.cdarticulo%type)
                                return number;                                                                    
                                   
  FUNCTION TotalArtfaltante(p_idconsolidado     tblslvconsolidadom.idconsolidadom%type,
                            p_CdArticulo        articulos.cdarticulo%type)
                                return number;   
                                
  FUNCTION DistPesables (p_idconsolidado       tblslvconsolidadom.idconsolidadom%type,
                         p_idpedido            pedidos.idpedido%type,
                         p_cdarticulo          detallepedidos.cdarticulo%type,
                         p_qtpiezas            detallepedidos.qtpiezas%type
                        )RETURN NUMBER;                              
                                
-- BORRAR Solo PARA DESARROLLO

PROCEDURE PorcDistribConsolidado(p_idconsolidado       IN  tblslvconsolidadom.idconsolidadom%type,
                                   p_Ok                  OUT number,
                                   p_error               OUT varchar2);                                 
                                
end PKG_SLV_DISTRIBUCION;
/
CREATE OR REPLACE PACKAGE BODY PKG_SLV_DISTRIBUCION is
  /***************************************************************************************************
  *  %v 29/05/2020  ChM - Parametros globales privados
  ****************************************************************************************************/
  c_TareaConsolidadoPedido           CONSTANT tblslvtipotarea.cdtipo%type := 25;
  c_TareaConsolidaPedidoFaltante     CONSTANT tblslvtipotarea.cdtipo%type := 40;
   
  C_FinalizaFaltaConsolidaPedido     CONSTANT tblslvestado.cdestado%type := 20;
  C_DistribFaltanteConsolidaPed      CONSTANT tblslvestado.cdestado%type := 21;
  C_CerradoConsolidadoPedido         CONSTANT tblslvestado.cdestado%type := 12;
  C_AFacturarConsolidadoPedido       CONSTANT tblslvestado.cdestado%type := 13;
  --C_FacturadoConsolidadoPedido                       CONSTANT tblslvestado.cdestado%type := 14;
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
               dtinsert)
       select p.idpedido,
              cp.idconsolidadopedido,
              c_TareaConsolidadoPedido,
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
  * %v 29/05/2020 - ChM  calcula el total del faltante de un artículo de un idfaltante          
  *****************************************************************************************************/ 
  FUNCTION TotalArtfaltante(p_idconsolidado     tblslvconsolidadom.idconsolidadom%type,
                            p_CdArticulo        articulos.cdarticulo%type)
                                return number is
   v_cantArt                    number(14,2):=0;
                               
  BEGIN
    --aun que nunca deberia ser cero un faltante. decode evita la división por cero 
    select decode(sum(cpd.qtunidadesmedidabase-cpd.qtunidadmedidabasepicking),0,-1
                  ,sum(cpd.qtunidadesmedidabase-cpd.qtunidadmedidabasepicking)) qtbase
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
     dtinsert)
    select p.idpedido,
           pf.idpedfaltante,
           c_TareaConsolidaPedidoFaltante,
           cpd.cdarticulo,
           sum(cpd.qtunidadesmedidabase-cpd.qtunidadmedidabasepicking) qtbase,
           PKG_SLV_DISTRIBUCION.TotalArtfaltante(p_idconsolidado,cpd.cdarticulo) totalart,
           ROUND((sum(cpd.qtunidadesmedidabase-cpd.qtunidadmedidabasepicking)/
           PKG_SLV_DISTRIBUCION.TotalArtfaltante(p_idconsolidado,cpd.cdarticulo))*100) porc,
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
  FUNCTION VerificaDiferenciasP(p_idcosolidadoP     tblslvconsolidadopedido.idconsolidadopedido%type,
                                p_difPesables       integer)
                                return number is
                                
   v_qtbase                   tblslvpedidoconformado.qtunidadmedidabase%type:=0;
   v_dif                      number; 
   v_modulo                   varchar2(100) := 'PKG_SLV_DISTRIBUCION.VerificaDiferenciasP';
   v_error                    varchar2(250);
    
  BEGIN
     --verifico si queda algún pesable por asignar
    if p_difPesables>=1 then
     null;
    end if;   
    
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
        --con valor pickiado
        and nvl(fd.qtunidadmedidabasepicking, 0) > 0
        --excluyo pesables
        and nvl(fd.qtpiezas,0) = 0    
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
          --verifico si existe diferencia y actualizo el ajuste
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
  * %v 17/06/2020 - ChM  Versión inicial TempPesables
  * %v 17/06/2020 - ChM crea la tabla temporal de los pesables disponibles del idpedido
  *****************************************************************************************************/ 
   FUNCTION TempPesables(p_idconsolidado    tblslvconsolidadom.idconsolidadom%type
                        ) RETURN NUMBER is
                           
    v_modulo       varchar2(100) := 'PKG_SLV_DISTRIBUCION.TempPesables';
    v_i            integer:=1;            
    
    BEGIN  
    --Creo la tabla en memoria de los pesables disponibles para el idconsolidado 
    FOR PES IN
             (select cp.idconsolidadopedido,
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
                 and cp.idconsolidadopedido = p_idconsolidado)
    LOOP
      PESABLES_P(v_i).IDCONSOLIDADOPEDIDO:=pes.idconsolidadopedido;
      PESABLES_P(v_i).CDARTICULO:=pes.cdarticulo;     
      PESABLES_P(v_i).QTUNIDADMEDIDABASEPIK:=pes.qtunidadmedidabasepicking;
      PESABLES_P(v_i).QTPIEZASPIK:=pes.qtpiezaspicking;
      --IDPEDIDO en 0 cero indica pesable no asignado
      PESABLES_P(v_i).IDPEDIDO:=0;
      v_i:=v_i+1;
      END LOOP;             
    RETURN v_i;    
    EXCEPTION
      WHEN OTHERS THEN
        n_pkg_vitalpos_log_general.write(2,
                                         'Modulo: ' || v_modulo ||                                       
                                         '  Error: ' || SQLERRM);
        RETURN 0;

  END TempPesables;
  
 /****************************************************************************************************
  * %v 17/06/2020 - ChM  Versión inicial DistPesables
  * %v 17/06/2020 - ChM  distribuye los pesables del consolidado pedido según porcentaje
  *****************************************************************************************************/ 
  FUNCTION DistPesables (p_idconsolidado       tblslvconsolidadom.idconsolidadom%type,
                         p_idpedido            pedidos.idpedido%type,
                         p_cdarticulo          detallepedidos.cdarticulo%type,
                         p_qtpiezas            detallepedidos.qtpiezas%type
                        )RETURN NUMBER is
                           
    v_modulo             varchar2(100) := 'PKG_SLV_DISTRIBUCION.DistPesables';  
    i                    Binary_Integer := 0;
    v_resto              detallepedidos.qtpiezas%type;      
    v_qtunidadmedidabase tblslvconsolidadopedidodet.qtunidadmedidabasepicking%type:=0;
    
  BEGIN
   v_resto:=p_qtpiezas;
   i := PESABLES_P.FIRST;
   While i Is Not Null and v_resto > 0 Loop
     --verifica si esta libre el pesable para asignarlo al pedido
     if PESABLES_P(i).IDPEDIDO = 0 
        and PESABLES_P(i).IDCONSOLIDADOPEDIDO = p_idconsolidado 
        and PESABLES_P(i).CDARTICULO = p_cdarticulo then
        --asigno el pesable al pedido
        PESABLES_P(i).IDPEDIDO:=p_idpedido;
        --se va restando el qtpiezaspick a la cantidad de piezas solicitadas
        v_resto:=v_resto-PESABLES_P(i).QTPIEZASPIK;
        --se va sumando qtunidadmedidabasepik para devolverla en la función
        v_qtunidadmedidabase:= v_qtunidadmedidabase+PESABLES_P(i).QTUNIDADMEDIDABASEPIK;
     end if; 
     i:= PESABLES_P.NEXT(i);
   End Loop;
  return v_qtunidadmedidabase;  
  EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       '  Error: ' || SQLERRM);
     return 0;

  END DistPesables;
   
    
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
            round(fd.qtunidadmedidabasepicking * (pdis.porcdist / 100),0) QTDISTB,
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
        and fd.cdarticulo = pdis.cdarticulo
        and cpd.cdarticulo = fd.cdarticulo
        --con valor pickiado
        and nvl(fd.qtunidadmedidabasepicking, 0) > 0
        --excluyo pesables
        and nvl(fd.qtpiezas,0) = 0
        --solo inserto los mayores a cero
        and round(fd.qtunidadmedidabasepicking * (pdis.porcdist / 100),0) > 0        
        and cf.idpedfaltante = p_IdPedFaltante
      order by 3) A ;
   IF SQL%ROWCOUNT = 0 THEN
     n_pkg_vitalpos_log_general.write(2,
                                      'Modulo: ' || v_modulo ||
                                      '  Detalle Error: ' || v_error);
     p_Ok    := 0;
     p_error := 'Error en insert tblslvdistribucionpedfaltante. Comuniquese con Sistemas!';
     ROLLBACK;
     RETURN;
   END IF;
   --verifico las diferencias que pudo generar los porcentajes de distribución de faltantes  
   p_Ok    := VerificaDiferenciasFal(p_IdPedFaltante);
   if p_Ok  = 0 then
     p_ok    := 0;
     p_error := 'error en procentajes de Distribución. comuniquese con sistemas!';
     rollback;
     return;
   end if;
   --creo los remitos de distribución de faltantes
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
  
  --Actualizo la tabla tblslvconsolidadopedido con los articulos encontrados en el faltante
  v_error:= 'Error en update tblslvconsolidadopedidodet'; 
  update tblslvconsolidadopedidodet c
   set c.qtunidadmedidabasepicking = 
       (select (cpd.qtunidadmedidabasepicking+dfa.qtunidadmedidabase)suma 
          from tblslvconsolidadopedido cp,
               tblslvconsolidadopedidodet cpd,
               tblslvdistribucionpedfaltante dfa,
               tblslvpedfaltanterel frel
         where cp.idconsolidadopedido = cpd.idconsolidadopedido
           and cp.idconsolidadopedido = frel.idconsolidadopedido
           and dfa.idpedfaltanterel = frel.idpedfaltanterel
           and dfa.cdarticulo = cpd.cdarticulo
           --excluyo pesables
           and nvl(cpd.qtpiezas,0) = 0
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
                   --excluyo pesables
                   and nvl(cpd.qtpiezas,0) = 0
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
    
 -----------------------------------------------------------------------------------------------
 /****************************************************************************************************
 * %v 05/06/2020 - ChM  Versión inicial SetDistribucionPedidos
 * %v 05/06/2020 - ChM  procedimiento para la distribución de los pedidos
 * %v 05/06/2020 - ChM  Falta la distribución de pesables y promos además validar redondeos
 * %v 12/06/2020 - ChM  inserto en la detpedidoconformado
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
   
 --verifico si el consolidado pedido es de comisionista
   begin
     select cp.idconsolidadopedido
       into v_ped
       from tblslvconsolidadopedido cp
      where cp.idconsolidadocomi is not null
        and cp.idconsolidadopedido = p_IdPedidos;
   exception 
     when no_data_found then
       p_Ok    := 0;
       p_error := 'Error consolidado pedido no existe.';
       RETURN;  
   end;
    if v_ped is not null then  
       p_Ok    := 0;
       p_error := 'Error consolidado pedido de Comisionista no Reparto. No es posible distribuir.';
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
       p_error := 'Error consolidado pedido no existe.';
       RETURN;  
   end;
    if v_ped = 0 then  
       p_Ok    := 0;
       p_error := 'Error consolidado pedido no tiene artículos a facturar.';
       RETURN;    
    end if;    
    
   begin
     select cp.cdestado
       into v_estado
       from tblslvconsolidadopedido cp
      where cp.idconsolidadopedido = p_IdPedidos;
   exception 
     when no_data_found then
       p_Ok    := 0;
       p_error := 'Error consolidado pedido no existe.';
       RETURN;   
   end;
    --verifico si el pedido ya esta Facturado
    if v_estado = C_AFacturarConsolidadoPedido then  
       p_Ok    := 0;
       p_error := 'Error consolidado pedido ya facturado.';
       RETURN;    
    end if; 
   --verifico si el pedido esta cerrado y se puede distribuir  
    if v_ped <> C_CerradoConsolidadoPedido then  
       p_Ok    := 0;
       p_error := 'Error consolidado pedido no cerrado. No es posible distribuir.';
       RETURN;    
    end if;
    
   --calcula los porcentajes que se aplicarán en la distribución de pedidos 
   PorcDistribConsolidado(p_IdPedidos,p_Ok,p_error);
   if P_OK = 0 then
     ROLLBACK;
     RETURN;
    END IF; 
    
  --cargo la tabla en memoria con los pesables del consolidado pedido
  v_ped:=TempPesables(p_IdPedidos);   
  
   --inserto la distribución del pedido en tblslvpedidoconformado
 v_error:= 'Error en insert en tblslvpedidoconformado';    
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
              round(cpd.qtunidadmedidabasepicking * (pdi.porcdist/100),0)qtbase,
              cpd.qtpiezaspicking,       
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
          --valida el tipo de tarea consolidado Pedido en la tabla distribución
          and pdi.cdtipo = c_TareaConsolidadoPedido
          --solo inserto para facturar los mayores a cero 
          and round(cpd.qtunidadmedidabasepicking * (pdi.porcdist/100),0)>0                 
          -- excluyo pesables
          and nvl(cpd.qtpiezas,0)=0
          --valida cesta navideña
          and pe.idcnpedido is null 
          --excluyo promo
          and dpe.icresppromo = 0 
          --excluyo comisionistas
          and cp.idconsolidadocomi is null
          and cp.idconsolidadopedido = p_IdPedidos;
          IF SQL%ROWCOUNT = 0 THEN
             n_pkg_vitalpos_log_general.write(2,
                                              'Modulo: ' || v_modulo ||
                                              '  Detalle Error: ' || v_error);
             p_Ok    := 0;
             p_error := 'Error en inserttblslvpedidoconformado. Comuniquese con Sistemas!';
             ROLLBACK;
             RETURN;
           END IF;    
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
   
   --verifico las diferencias que pudo generar los porcentajes de distribución     
   p_Ok    := VerificaDiferenciasP(p_IdPedidos,v_ped);
   if p_Ok  = 0 then
     p_ok    := 0;
     p_error := 'error en procentajes de Distribución. comuniquese con sistemas!';
     rollback;
     return;
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
 END SetDistribucionPedidos;
 
end PKG_SLV_DISTRIBUCION;
/
