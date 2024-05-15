CREATE OR REPLACE PACKAGE PKG_SLV_DISTRIBUCION is
  /**********************************************************************************************************
  * Author  : CMALDONADO_C
  * Created : 29/05/2020 12:50:03 p.m.
  * %v Paquete para la DISTRIBUCION de pedidos en SLV
  **********************************************************************************************************/
  -- Tipos de datos

  TYPE CURSOR_TYPE IS REF CURSOR;
  
  
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
   v_pedfal Tblslvpedfaltante.Idpedfaltante%type := null;
 
 BEGIN
   
   --verifico si el faltante esta finalizado y se puede distribuir
   begin
     select f.idpedfaltante 
       into v_pedfal
       from tblslvpedfaltante f
      where f.cdestado = C_FinalizaFaltaConsolidaPedido
        and f.idpedfaltante = p_IdPedFaltante;
   exception 
     when no_data_found then
       v_pedfal:=null;
   end;
    if v_pedfal is null then  
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
   --ojo falta validar si no inserta porque la distribución dio cero ( redondeo) para todos los articulos      
   IF SQL%ROWCOUNT = 0 THEN
     n_pkg_vitalpos_log_general.write(2,
                                      'Modulo: ' || v_modulo ||
                                      '  Detalle Error: ' || v_error);
     p_Ok    := 0;
     p_error := 'Error en insert tblslvdistribucionpedfaltante. Comuniquese con Sistemas!';
     ROLLBACK;
     RETURN;
   END IF;
   
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
 *****************************************************************************************************/
 
 PROCEDURE SetDistribucionPedidos(p_idpersona     IN personas.idpersona%type,
                                  p_IdPedidos     IN Tblslvconsolidadopedido.Idconsolidadopedido%type,
                                  p_Ok            OUT number,
                                  p_error         OUT varchar2) IS
 
   v_modulo varchar2(100) := 'PKG_SLV_DISTRIBUCION.SetDistribucionPedidoFaltante';
   v_error  varchar2(250);
   v_ped    Tblslvconsolidadopedido.Idconsolidadopedido%type:= null;
 
 BEGIN
   
 --verifico si el pedido es de comisionista
   begin
     select cp.idconsolidadopedido
       into v_ped
       from tblslvconsolidadopedido cp
      where cp.idconsolidadocomi is not null
        and cp.idconsolidadopedido = p_IdPedidos;
   exception 
     when no_data_found then
       v_ped:=null;
   end;
    if v_ped is not null then  
       p_Ok    := 0;
       p_error := 'Error consolidado pedido de Comisionista no Reparto. No es posible distribuir.';
       RETURN;    
    end if;
    
   --verifico si el pedido esta cerrado y se puede distribuir
   begin
     select cp.idconsolidadopedido
       into v_ped
       from tblslvconsolidadopedido cp
      where cp.cdestado = C_CerradoConsolidadoPedido
        and cp.idconsolidadopedido = p_IdPedidos;
   exception 
     when no_data_found then
       v_ped:=null;
   end;
    if v_ped is null then  
       p_Ok    := 0;
       p_error := 'Error consolidado pedido no finalizado. No es posible distribuir.';
       RETURN;    
    end if;
   --calcula los porcentajes que se aplicarán en la distribución de pedidos 
   PorcDistribConsolidado(p_IdPedidos,p_Ok,p_error);
   if P_OK = 0 then
     ROLLBACK;
     RETURN;
    END IF; 
     
   --inserto la distribución del pedido en tblslvpedidoconformado
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
              round(cpd.qtunidadmedidabasepicking * (pdi.porcdist/100),0) qtbase,
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
