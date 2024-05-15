CREATE OR REPLACE PACKAGE PKG_SLV_DISTRIBUCION is
  /**********************************************************************************************************
  * Author  : CHARLES ROY MALDONADO DUARTE
  * Created : 29/05/2020 12:50:03 p.m.
  * %v Paquete para la DISTRIBUCION de pedidos en SLV
  **********************************************************************************************************/
  -- Tipos de datos

  TYPE CURSOR_TYPE IS REF CURSOR;
  --tabla en memoria para la distribución de los pesables
   TYPE PESABLE IS RECORD   (
    IDCONSOLIDADOPEDIDO     TBLSLVCONSOLIDADOPEDIDO.IDCONSOLIDADOPEDIDO%TYPE,
    TIPOTAREA               TBLSLVTIPOTAREA.CDTIPO%TYPE,
    CDARTICULO              TBLSLVCONSOLIDADOPEDIDODET.CDARTICULO%TYPE,
    QTUNIDADMEDIDABASEPIK   TBLSLVCONSOLIDADOPEDIDODET.QTUNIDADMEDIDABASEPICKING%TYPE,
    QTPIEZASPIK             TBLSLVCONSOLIDADOPEDIDODET.QTPIEZASPICKING%TYPE,
    BANDERA                 INTEGER
    );

   TYPE PESABLES IS TABLE OF PESABLE INDEX BY BINARY_INTEGER;
   PESABLES_P PESABLES;
   PESABLES_F PESABLES;
   PESABLES_C PESABLES;
   DISTRIB  PESABLES;
   

 PROCEDURE  SetDistribucion     (p_idpersona     IN personas.idpersona%type,
                                 p_Idconsolidado IN Tblslvconsolidadopedido.Idconsolidadopedido%type,
                                 p_TipoTarea     IN tblslvtipotarea.cdtipo%type,
                                 p_Ok            OUT number,
                                 p_error         OUT varchar2);
   --USO INTERNO DEL PKG
  FUNCTION alternaRedondeo(P_j    integer)
                          return INTEGER;

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
  C_FacturadoConsolidadoPedido       CONSTANT tblslvestado.cdestado%type := 14;
  C_FinalizadoConsolidadoComi        CONSTANT tblslvestado.cdestado%type := 27;
  C_DistribuidoConsolidadoComi       CONSTANT tblslvestado.cdestado%type := 28;
  C_FacturadoConsolidadoComi         CONSTANT tblslvestado.cdestado%type := 29;
  
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
  * %v 30/06/2020 - ChM  Versión inicial alternaRedondeo
  * %v 30/06/2020 - ChM  devuelve 1 o 0 según corresponda
  *****************************************************************************************************/
  FUNCTION alternaRedondeo(P_j    integer)
                          return INTEGER is
  BEGIN
    RETURN P_J+1;
  END alternaRedondeo;

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
     WHEN NO_DATA_FOUND THEN 
        RETURN 0;    
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
       --  excluyo linea de promo
       and dp.icresppromo = 0
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
                                   p_qtbasepromo         OUT tblslvpordistrib.qtunidadmedidabase%type,
                                   p_qtpiezaspromo       OUT tblslvpordistrib.qtpiezas%type,
                                   p_Ok                  OUT number,
                                   p_error               OUT varchar2) is

    v_modulo                       varchar2(100) := 'PKG_SLV_DISTRIBUCION.PorcDistribConsolidado';
    v_error                        varchar2(250);

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
               artpromo,
               qtunidadmedidabase,
               qtpiezas,
               totalconsolidado,
               porcdist,
               dtinsert)
       select p.idpedido,
              cp.idconsolidadopedido,
              c_TareaConsolidadoPedido,
              dp.cdarticulo,
              MarcaPromoP(p_idconsolidado,dp.cdarticulo),
              sum(dp.qtunidadmedidabase) qtbase,
              sum(dp.qtpiezas) qtpiezas,
              TotalArtConsolidado(p_idconsolidado,dp.cdarticulo) totalart,
              sum(dp.qtunidadmedidabase)/
              TotalArtConsolidado(p_idconsolidado,dp.cdarticulo) porc,
              sysdate
         from tblslvconsolidadopedido cp,
              tblslvconsolidadopedidorel prel,
              pedidos p,
              detallepedidos dp
        where p.idpedido = dp.idpedido
          and p.idpedido = prel.idpedido
          and cp.idconsolidadopedido = prel.idconsolidadopedido
          and cp.idconsolidadopedido = p_Idconsolidado
          --  excluyo linea de promo
          and dp.icresppromo = 0
     group by p.idpedido,
              cp.idconsolidadopedido,
              dp.cdarticulo;
      IF SQL%ROWCOUNT = 0  THEN
          n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       '  Detalle Error: ' || v_error);
   	      p_Ok:=0;
          p_error:='Error. Comuniquese con Sistemas!';
          ROLLBACK;
          RETURN;
       END IF;

   -- retorna marca para indicar que existen artículos en promo
   begin
    select nvl(sum(di.qtunidadmedidabase),0) qtbase,
           nvl(sum(di.qtpiezas),0) qtpiezas
      into P_qtbasepromo,
           P_qtpiezaspromo
      from tblslvpordistrib di
           --solo promos
     where di.artpromo <> 0
       and di.cdtipo = c_TareaConsolidadoPedido
       and di.idconsolidado = p_Idconsolidado;
    exception
      when others then
          P_qtbasepromo:=0;
          P_qtpiezaspromo:=0;
     end;

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
    WHEN NO_DATA_FOUND THEN 
        RETURN 0; 
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
       --  excluyo linea de promo
       and dp.icresppromo = 0
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
                            p_qtbasepromo         OUT tblslvpordistrib.qtunidadmedidabase%type,
                            p_qtpiezaspromo       OUT tblslvpordistrib.qtpiezas%type,
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
               artpromo,
               qtunidadmedidabase,
               qtpiezas,
               totalconsolidado,
               porcdist,
               dtinsert)
       select p.idpedido,
              cc.idconsolidadocomi,
              c_TareaConsolidadoComi,
              dp.cdarticulo,
              MarcaPromoC(p_idconsolidado,dp.cdarticulo),
              sum (dp.qtunidadmedidabase) qtbase,
              sum (dp.qtpiezas) qtpiezas,
              TotalArtComi(p_idconsolidado,dp.cdarticulo) totalart,
              sum(dp.qtunidadmedidabase)/
              TotalArtComi(p_idconsolidado,dp.cdarticulo) porc,
              sysdate
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
          --  excluyo linea de promo
          and dp.icresppromo = 0
          and cc.idconsolidadocomi = p_Idconsolidado
     group by p.idpedido,
              cc.idconsolidadocomi,
              dp.cdarticulo;
      IF SQL%ROWCOUNT = 0  THEN
          n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       '  Detalle Error: ' || v_error);
   	      p_Ok:=0;
          p_error:='Error. Comuniquese con Sistemas!';
          ROLLBACK;
          RETURN;
       END IF;

 -- retorna marca para indicar que existen artículos en promo
   begin
    select nvl(sum(di.qtunidadmedidabase),0) qtbase,
           nvl(sum(di.qtpiezas),0) qtpiezas
      into P_qtbasepromo,
           P_qtpiezaspromo
      from tblslvpordistrib di
           --solo promos
     where di.artpromo <> 0
       and di.cdtipo = c_TareaConsolidadoPedido
       and di.idconsolidado = p_Idconsolidado;
    exception
      when others then
          P_qtbasepromo:=0;
          P_qtpiezaspromo:=0;
     end;

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
    WHEN NO_DATA_FOUND THEN 
        RETURN 0; 
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
                                 p_qtbasepromo         OUT tblslvpordistrib.qtunidadmedidabase%type,
                                 p_qtpiezaspromo       OUT tblslvpordistrib.qtpiezas%type,
                                 p_Ok                  OUT number,
                                 p_error               OUT varchar2) is

    v_modulo       varchar2(100) := 'PKG_SLV_DISTRIBUCION.PorcDistribFaltantes';
    v_error        varchar2(250);
    v_Alterna      integer:=0;
  BEGIN
    --valido que los pedidos que componen el faltante no esten a facturar o facturado 
    begin
      select count(cp.idconsolidadopedido) 
        into v_Alterna
        from tblslvconsolidadopedido cp,
             tblslvpedfaltanterel    frel,
             tblslvpedfaltante       pf
       where cp.idconsolidadopedido = frel.idconsolidadopedido
         and frel.idpedfaltante = pf.idpedfaltante
         and pf.idpedfaltante = p_idconsolidado 
         and cp.cdestado in (C_AFacturarConsolidadoPedido,C_FacturadoConsolidadoPedido);
      exception
        when no_data_found then
          v_Alterna:=0;
        when others then
          v_Alterna:=-1;     
      end;
    if v_Alterna <> 0 then
       n_pkg_vitalpos_log_general.write(2,
                                      'Modulo: ' || v_modulo ||
                                      '  Detalle Error: existen pedidos ya facturados');
     p_Ok    := 0;
     p_error:='existen pedidos ya facturados. Imposible distribuir faltante';
     ROLLBACK;
     RETURN;
    end if;
  
  --borro porcentajes para el consolidado faltante
  v_error:=' Error en insert tblslvpordistrib';
  delete tblslvpordistrib pdf
   where pdf.idconsolidado = p_idconsolidado
     and pdf.cdtipo = c_TareaConsolidaPedidoFaltante;

  insert into tblslvpordistrib
          (idpedido,
           idconsolidado,
           cdtipo,
           cdarticulo,
           artpromo,
           qtunidadmedidabase,
           qtpiezas,
           totalconsolidado,
           porcdist,
           dtinsert)
    select p.idpedido,
           pf.idpedfaltante,
           c_TareaConsolidaPedidoFaltante,
           cpd.cdarticulo,
           MarcaPromoF(p_idconsolidado,cpd.cdarticulo),
           sum(cpd.qtunidadesmedidabase-cpd.qtunidadmedidabasepicking) qtbase,
           sum(cpd.qtpiezas-cpd.qtpiezaspicking) qtpiezas,
           PKG_SLV_DISTRIBUCION.TotalArtfaltante(p_idconsolidado,cpd.cdarticulo) totalart,
           sum(cpd.qtunidadesmedidabase-cpd.qtunidadmedidabasepicking)/
           PKG_SLV_DISTRIBUCION.TotalArtfaltante(p_idconsolidado,cpd.cdarticulo) porc,
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
           cpd.cdarticulo;

      IF SQL%ROWCOUNT = 0  THEN
          n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       '  Detalle Error: ' || v_error);
   	      p_Ok:=0;
          p_error:='Error. Comuniquese con Sistemas!';
          ROLLBACK;
          RETURN;
       END IF;
   -- retorna marca para indicar que existen artículos en promo
   begin
    select nvl(sum(di.qtunidadmedidabase),0) qtbase,
           nvl(sum(di.qtpiezas),0) qtpiezas
      into P_qtbasepromo,
           P_qtpiezaspromo
      from tblslvpordistrib di
           --solo promos
     where di.artpromo <> 0
       and di.cdtipo = c_TareaConsolidadoPedido
       and di.idconsolidado = p_Idconsolidado;
    exception
      when others then
          P_qtbasepromo:=0;
          P_qtpiezaspromo:=0;
     end;

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
  * %v 27/06/2020 - ChM  Versión inicial VerificaDiferenciasC
  * %v 2706/2020 - ChM  revisa si existen diferencias entre lo insertado en tblslvpedidoconformado
                         y tblslvconsolidadopedidodet y aplica ajustes
  *****************************************************************************************************/
  FUNCTION VerificaDiferenciasC(p_IdComi     tblslvconsolidadopedido.idconsolidadopedido%type)
                                return number is

 --  v_qtbase                   tblslvpedidoconformado.qtunidadmedidabase%type:=0;
 --  v_dif                      number;
   v_modulo                   varchar2(100) := 'PKG_SLV_DISTRIBUCION.VerificaDiferenciasC';
   v_error                    varchar2(250);

  BEGIN


    v_error:=' Error en Cursor cpedido';
    --cursor del total del articulo en consolidadopedido
    for ccomi in
      (select cc.idconsolidadocomi,
              ccd.cdarticulo,
              sum(ccd.qtunidadmedidabasepicking)qtbase,
              sum(ccd.qtpiezaspicking)
         from pedidos                      pe,
              detallepedidos               dpe,
              tblslvconsolidadopedidorel   cprel,
              tblslvconsolidadopedido      cp,
              tblslvconsolidadocomi        cc,
              tblslvconsolidadocomidet     ccd
        where pe.idpedido = dpe.idpedido
          and pe.idpedido = cprel.idpedido
          and cprel.idconsolidadopedido = cp.idconsolidadopedido
          and cp.idconsolidadocomi = cc.idconsolidadocomi
          and cc.idconsolidadocomi = ccd.idconsolidadocomi
          and ccd.cdarticulo = dpe.cdarticulo         
          --excluyo promo
          and dpe.icresppromo = 0
          and cc.idconsolidadocomi = p_IdComi
     group by pe.idpedido,
              dpe.cdarticulo,
              dpe.sqdetallepedido,
              dpe.cdunidadmedida)
     loop
     /*  begin
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
              --error EN DESARROLLO
              return 0;

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
            --error EN DESARROLLO
            return 0;
          end if;*/
          null;
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
  END VerificaDiferenciasC;

 /****************************************************************************************************
  * %v 29/06/2020 - ChM  Versión inicial TempDistrib
  * %v 29/06/2020 - ChM crea la tabla temporal de los artículos disponibles del consolidado SEGUN TAREA
  *****************************************************************************************************/
   FUNCTION TempDistrib(p_idconsolidado    tblslvconsolidadom.idconsolidadom%type,
                        p_tipotarea          tblslvtipotarea.cdtipo%type                 
                         ) RETURN NUMBER is

    v_modulo       varchar2(100) := 'PKG_SLV_DISTRIBUCION.TempDistrib';
    v_i            integer:=0;

    BEGIN
     DISTRIB.DELETE; 
     --Creo la tabla en memoria de los artículos disponibles para el idconsolidado pedido
    IF p_tipotarea = c_TareaConsolidadoPedido THEN
    FOR dist IN
            (select cpd.cdarticulo,                    
                    nvl(sum(cpd.qtunidadmedidabasepicking),0) qtbase,
                    nvl(sum(cpd.qtpiezaspicking),0) qtpiezas                          
               from tblslvconsolidadopedido      cp,
                    tblslvconsolidadopedidodet   cpd
              where cp.idconsolidadopedido = cpd.idconsolidadopedido 
                --valida solo valores piquiados
                and nvl(cpd.qtunidadmedidabasepicking,0)>0             
                and cp.idconsolidadopedido = p_idconsolidado 
                --  valida no incluir articulo de promo
                and cpd.cdarticulo not in (select pd.cdarticulo 
                                             from tblslvpordistrib pd 
                                            where pd.idconsolidado = p_idconsolidado 
                                              and pd.cdtipo=c_TareaConsolidadoPedido
                                              -- 1 articulos en promo
                                              and pd.artpromo = 1)               
           group by cpd.cdarticulo
           order by 1)
    LOOP
      v_i:=v_i+1;  
      DISTRIB(v_i).IDCONSOLIDADOPEDIDO:=p_idconsolidado;
      DISTRIB(v_i).CDARTICULO:=dist.cdarticulo;
      DISTRIB(v_i).TIPOTAREA:=c_TareaConsolidadoPedido;
      DISTRIB(v_i).QTUNIDADMEDIDABASEPIK:=dist.qtbase;
      DISTRIB(v_i).QTPIEZASPIK:=dist.qtpiezas;
      --bandera cero 0 indica NO Pesables 1 pesable
      if DISTRIB(v_i).QTPIEZASPIK <> 0 then
         DISTRIB(v_i).BANDERA:=1;
         --unidada base en cero si es pesable
         DISTRIB(v_i).QTUNIDADMEDIDABASEPIK:=0;
      else 
         DISTRIB(v_i).BANDERA:=0;  
      end if;       
      END LOOP;
    END IF;  
     --Creo la tabla en memoria de los artículos disponibles para el consolidado comisionista
    IF p_tipotarea = c_TareaConsolidadoComi THEN
    FOR dist IN
            (select ccd.cdarticulo,
                    nvl(sum(ccd.qtunidadmedidabasepicking),0) qtbase,
                    nvl(sum(ccd.qtpiezaspicking),0) qtpiezas                          
               from tblslvconsolidadocomi      cc,
                    tblslvconsolidadocomidet   ccd
              where cc.idconsolidadocomi = ccd.idconsolidadocomi 
                --valida solo valores piquiados
                and nvl(ccd.qtunidadmedidabasepicking,0)>0            
                and cc.idconsolidadocomi = p_idconsolidado
                --  valida no incluir articulo de promo
                and ccd.cdarticulo not in (select pd.cdarticulo 
                                             from tblslvpordistrib pd 
                                            where pd.idconsolidado = p_idconsolidado 
                                              and pd.cdtipo=c_TareaConsolidadoComi
                                              -- 1 articulos en promo
                                              and pd.artpromo = 1) 
           group by ccd.cdarticulo
           order by 1)
    LOOP
      v_i:=v_i+1;  
      DISTRIB(v_i).IDCONSOLIDADOPEDIDO:=p_idconsolidado;
      DISTRIB(v_i).CDARTICULO:=dist.cdarticulo;
      DISTRIB(v_i).TIPOTAREA:=c_TareaConsolidadoComi;
      DISTRIB(v_i).QTUNIDADMEDIDABASEPIK:=dist.qtbase;
      DISTRIB(v_i).QTPIEZASPIK:=dist.qtpiezas;
      --bandera cero 0 indica NO Pesables 1 pesable
      if DISTRIB(v_i).QTPIEZASPIK <> 0 then
         DISTRIB(v_i).BANDERA:=1;
          --unidada base en cero si es pesable
         DISTRIB(v_i).QTUNIDADMEDIDABASEPIK:=0;
      else 
         DISTRIB(v_i).BANDERA:=0;  
      end if;       
      END LOOP;
    END IF;  
     --Creo la tabla en memoria de los artículos disponibles para el consolidado Faltante
    IF p_tipotarea = c_TareaConsolidaPedidoFaltante THEN
    FOR dist IN
            (select pfd.cdarticulo,
                    nvl(sum(pfd.qtunidadmedidabasepicking),0) qtbase,
                    nvl(sum(pfd.qtpiezaspicking),0) qtpiezas                          
               from tblslvpedfaltante               pf,
                    tblslvpedfaltantedet            pfd
              where pf.idpedfaltante = pfd.idpedfaltante 
                --valida solo valores piquiados
                and nvl(pfd.qtunidadmedidabasepicking,0)>0         
                and pf.idpedfaltante = p_idconsolidado
                --  valida no incluir articulo de promo
                and pfd.cdarticulo not in (select pd.cdarticulo 
                                             from tblslvpordistrib pd 
                                            where pd.idconsolidado = p_idconsolidado 
                                              and pd.cdtipo=c_TareaConsolidaPedidoFaltante
                                              -- 1 articulos en promo
                                              and pd.artpromo = 1)                
           group by pfd.cdarticulo
           order by 1)
    LOOP
      v_i:=v_i+1;  
      DISTRIB(v_i).IDCONSOLIDADOPEDIDO:=p_idconsolidado;
      DISTRIB(v_i).CDARTICULO:=dist.cdarticulo;
      DISTRIB(v_i).TIPOTAREA:=c_TareaConsolidaPedidoFaltante;
      DISTRIB(v_i).QTUNIDADMEDIDABASEPIK:=dist.qtbase;
      DISTRIB(v_i).QTPIEZASPIK:=dist.qtpiezas;
      --bandera cero 0 indica NO Pesables 1 pesable
      if DISTRIB(v_i).QTPIEZASPIK <> 0 then
         DISTRIB(v_i).BANDERA:=1;
          --unidada base en cero si es pesable
         DISTRIB(v_i).QTUNIDADMEDIDABASEPIK:=0;
      else 
         DISTRIB(v_i).BANDERA:=0;  
      end if;       
      END LOOP;
    END IF; 
    --valida si el pedido solo tiene articulos de promo por distribuir 
    --las promo no usan DISTRIB pero se deben distribuir
    IF v_i = 0 THEN 
      BEGIN
        select COUNT(*)
          into v_i
          from tblslvpordistrib pd 
          where pd.idconsolidado = p_idconsolidado 
            and pd.cdtipo=c_TareaConsolidadoPedido
            -- 1 articulos en promo
            and pd.artpromo = 1;
       EXCEPTION
         WHEN OTHERS THEN
           v_i := 0;     
        END;
     END IF;
    RETURN v_i;
    EXCEPTION      
      WHEN OTHERS THEN
        n_pkg_vitalpos_log_general.write(2,
                                         'Modulo: ' || v_modulo ||
                                         '  Error: ' || SQLERRM);
        RETURN 0;

  END TempDistrib;
 
 /****************************************************************************************************
  * %v 29/06/2020 - ChM  Versión inicial DisponibilidadP
  * %v 29/06/2020 - ChM crea la tabla temporal de los artículos disponibles del consolidado pedido
  *****************************************************************************************************/
   FUNCTION Disponibilidad(p_idconsolidado    tblslvconsolidadom.idconsolidadom%type,
                           P_tipotarea        tblslvtipotarea.cdtipo%type,                    
                           p_cdarticulo       tblslvconsolidadomdet.cdarticulo%type,
                           p_qtbase           tblslvconsolidadomdet.qtunidadmedidabase%type, 
                       --    p_qtbaseReal       tblslvconsolidadomdet.qtunidadmedidabase%type,                            
                           p_qtpiezas         tblslvconsolidadomdet.qtpiezas%type
--                           ,
                       --    p_qtpiezasReal     tblslvconsolidadomdet.qtpiezas%type                                                                     
                           ) RETURN NUMBER is

    v_modulo       varchar2(100) := 'PKG_SLV_DISTRIBUCION.Disponibilidad';
    v_i            integer:=1;
    V_cant         tblslvconsolidadomdet.qtunidadmedidabase%type:=0;

    BEGIN
    v_i := DISTRIB.FIRST;
    While v_i Is Not Null Loop 
      --busca el articulo del pedido   
      if DISTRIB(v_i).IDCONSOLIDADOPEDIDO = p_idconsolidado and
         DISTRIB(v_i).TIPOTAREA = P_tipotarea  and
         DISTRIB(v_i).CDARTICULO = p_cdarticulo then
          --no pesables           
          if p_qtbase >= 0 then
            --verifica si queda disponible la cantidad para asignarla a la factura No Pesables BANDERA = 0
            if (DISTRIB(v_i).QTUNIDADMEDIDABASEPIK-p_qtbase)>=0 and DISTRIB(v_i).BANDERA = 0 then
                DISTRIB(v_i).QTUNIDADMEDIDABASEPIK:=DISTRIB(v_i).QTUNIDADMEDIDABASEPIK-p_qtbase;                
                if p_qtbase=0 then                                 
                    --si hay disponible asigno uno solo hasta no disponible
                    -- verifica si existen articulos disponibles
                     if (DISTRIB(v_i).QTUNIDADMEDIDABASEPIK)>0  then
                         DISTRIB(v_i).QTUNIDADMEDIDABASEPIK:=DISTRIB(v_i).QTUNIDADMEDIDABASEPIK-1;
                         v_cant:=1;
                         return v_cant;
                     else
                        --si no hay disponibilidad devuelve 0 
                        v_cant:=0;
                        return v_cant;
                     end if;             
                  else
                   v_cant:=p_qtbase;
                   return v_cant;
                end if;      
            else
                --asigno lo ultimo disponible                                  
                v_cant:=DISTRIB(v_i).QTUNIDADMEDIDABASEPIK;
                DISTRIB(v_i).QTUNIDADMEDIDABASEPIK:=0;
                return v_cant;               
            end if;
          end if;
          --pesables  
          if p_qtpiezas >= 0 then
          --verifica si queda disponible la cantidad para asignarla a la factura Solo Pesables BANDERA 1
            if (DISTRIB(v_i).QTPIEZASPIK-p_qtpiezas)>=0 and DISTRIB(v_i).BANDERA = 1 then
                DISTRIB(v_i).QTPIEZASPIK:=DISTRIB(v_i).QTPIEZASPIK-p_qtpiezas;
                if p_qtpiezas=0 then                  
                    --si hay disponible asigno uno solo hasta no disponible
                    -- verifica si existen articulos disponibles
                     if (DISTRIB(v_i).QTPIEZASPIK)>0  then
                         DISTRIB(v_i).QTPIEZASPIK:=DISTRIB(v_i).QTPIEZASPIK-1;
                         v_cant:=1;
                         return v_cant;
                     else
                      --si no hay disponibilidad devuelve 0 
                      v_cant:=0;
                      return v_cant;
                     end if;                
                  else
                   v_cant:=p_qtpiezas;
                   return v_cant;
                end if; 
            else                                 
                v_cant:=DISTRIB(v_i).QTPIEZASPIK;
                DISTRIB(v_i).QTPIEZASPIK:=0; 
                return v_cant;              
            end if;   
          end if;
         
      end if;       
       v_i:= DISTRIB.NEXT(v_i);
    End loop;
    RETURN v_cant;
    EXCEPTION
      WHEN OTHERS THEN
        n_pkg_vitalpos_log_general.write(2,
                                         'Modulo: ' || v_modulo ||
                                         '  Error: ' || SQLERRM);
        RETURN 0;

  END Disponibilidad; 
  
  
 /****************************************************************************************************
  * %v 30/06/2020 - ChM  Versión inicial ValidaDistribucion
  * %v 30/06/2020 - ChM  revisa si todos los articulos disponibles se distribuyeron sino error
  *****************************************************************************************************/
   Procedure ValidaDistribucion(p_idconsolidado       IN  tblslvconsolidadom.idconsolidadom%type,
                                P_tipotarea           IN  tblslvtipotarea.cdtipo%type,
                                p_Ok                  OUT number,
                                p_error               OUT varchar2                                                                               
                                ) is
   v_i            integer:=1;
   v_modulo       varchar2(100) := 'PKG_SLV_DISTRIBUCION.ValidaDistribucion';
  Begin
   v_i:= DISTRIB.FIRST;
  While v_i Is Not Null Loop
     --verifica si esta libre algún articulo ERROR
     if (DISTRIB(v_i).QTPIEZASPIK <> 0 or DISTRIB(v_i).QTUNIDADMEDIDABASEPIK <>0) and 
         DISTRIB(v_i).IDCONSOLIDADOPEDIDO = p_idconsolidado and
         DISTRIB(v_i).TIPOTAREA = P_tipotarea then      
         p_Ok    := 0;
         p_error := 'Error en DISTRIBUCIÓN. Comuniquese con Sistemas!';
         n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       '  Detalle Error: Quedan ARTICULOS por distribuir' 
                                       ||'  Error: ' || SQLERRM);
         RETURN;
     end if;
     v_i:= DISTRIB.NEXT(v_i);
   End Loop;
    p_Ok    := 1;
    p_error := '';
    RETURN;
   end;
  /****************************************************************************************************
  * %v 17/06/2020 - ChM  Versión inicial TempPesablesP
  * %v 17/06/2020 - ChM crea la tabla temporal de los pesables disponibles del consolidado pedido
  *****************************************************************************************************/
   FUNCTION TempPesablesP(p_idconsolidado    tblslvconsolidadom.idconsolidadom%type
                         ) RETURN NUMBER is

    v_modulo       varchar2(100) := 'PKG_SLV_DISTRIBUCION.TempPesablesP';
    v_i            integer:=1;

    BEGIN
    PESABLES_P.DELETE;  
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
                from tblslvconsolidadopedido           cp,
                     tblslvconsolidadopedidodet        cpd,
                     tblslvpedfaltanterel              pfrel,
                     tblslvremito                      re,
                     tblslvremitodet                   red
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
                 and cp.idconsolidadopedido = p_idconsolidado
            order by 1,2)--ordeno por articulo para mejorar la distribución
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
      PESABLES_F.DELETE; 
    --Creo la tabla en memoria de los pesables disponibles para el id consolidado FALTANTE
    FOR PES IN
             (select pf.idpedfaltante,
                     red.cdarticulo,
                     red.qtunidadmedidabasepicking,
                     red.qtpiezaspicking
                from tblslvpedfaltante                     pf,
                     tblslvpedfaltantedet                  pfd,
                     tblslvtarea                           ta,
                     tblslvremito                          re,
                     tblslvremitodet                       red
               where pf.idpedfaltante = pfd.idpedfaltante
                 and pf.idpedfaltante = ta.idpedfaltante
                 and ta.idtarea = re.idtarea
                 and re.idremito = red.idremito
                 and pfd.cdarticulo = red.cdarticulo
                 --solo pesables
                 and pfd.qtpiezas<>0
                 --valido solo pesables con picking mayores a cero
                 and pfd.qtpiezaspicking > 0
                 and pf.idpedfaltante = p_idconsolidado
            order by 1,2)--ordeno por articulo para mejorar la distribución
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
      PESABLES_C.DELETE; 
    --Creo la tabla en memoria de los pesables disponibles para el consolidado comi
    FOR PES IN
             (--consulta para los remitos de tarea
              select cc.idconsolidadocomi,
                     red.cdarticulo,
                     red.qtunidadmedidabasepicking,
                     red.qtpiezaspicking
                from tblslvconsolidadocomi     cc,
                     tblslvconsolidadocomidet  ccd,
                     tblslvtarea               ta,
                     tblslvremito              re,
                     tblslvremitodet           red
               where cc.idconsolidadocomi = ccd.idconsolidadocomi
                 and cc.idconsolidadocomi = ta.idconsolidadocomi
                 and ta.idtarea = re.idtarea
                 and re.idremito = red.idremito
                 and ccd.cdarticulo = red.cdarticulo
                 --solo pesables
                 and ccd.qtpiezas<>0
                 --valido solo pesables con picking mayores a cero
                 and ccd.qtpiezaspicking > 0
                 and cc.idconsolidadocomi = p_idconsolidado
            order by 1,2)--ordeno por articulo para mejorar la distribución
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

    v_modulo                       varchar2(100) := 'PKG_SLV_DISTRIBUCION.DistPesablesP';
    i                              Binary_Integer := 0;
    v_resto                        detallepedidos.qtpiezas%type;
    v_error                        varchar2(250);
    v_Alterna                      integer:=1;
    
  BEGIN
    for pes in(
       select pe.idpedido,
              dpe.cdarticulo,
              dpe.cdunidadmedida, 
              cpd.qtpiezaspicking qtpiezas,
              pdi.porcdist,                           
              round(cpd.qtpiezaspicking * pdi.porcdist,0) qtpiezaspicking,
              dpe.qtpiezas qtpiezasReal,
              dpe.ampreciounitario,
              dpe.vluxb,
              dpe.dsobservacion,
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
          -- solo pesables
          and nvl(cpd.qtpiezas,0)<>0          
          --excluyo promo
          and dpe.icresppromo = 0
          --excluyo comisionistas
          and cp.idconsolidadocomi is null
          and cp.idconsolidadopedido = p_idconsolidado
     order by 2)--ordeno por articulo para mejorar la distribución
    loop
     --trunc+1 las filas pares si aplica para ajustar las decimales
       If mod(v_Alterna,2)=0 
         and (pes.qtpiezas * pes.porcdist)-round(pes.qtpiezas * pes.porcdist,0)<=0.5 then
              pes.qtpiezaspicking:=trunc(pes.qtpiezas * pes.porcdist)+1;               
      end if;  
      v_Alterna:=v_Alterna+1;       
    --verifica si existe disponiblidad para el articulo y se puede insertar en tblslvpedidoconformado
    pes.qtpiezaspicking:=Disponibilidad(p_idconsolidado,c_TareaConsolidadoPedido,pes.cdarticulo,-1,pes.qtpiezaspicking);
    if pes.qtpiezaspicking > 0 then     
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
            v_error:=' Error en insert tblslvpedidoconformado '||p_idconsolidado;
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
               --pes.qtunidadpedido igual al distribuido del pesable
               PESABLES_P(i).QTUNIDADMEDIDABASEPIK,
               PESABLES_P(i).QTUNIDADMEDIDABASEPIK,
               PESABLES_P(i).QTPIEZASPIK,
               pes.ampreciounitario,
               --calcula amlinea
               PESABLES_P(i).QTUNIDADMEDIDABASEPIK*pes.ampreciounitario,
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
                    p_error:='Error. Comuniquese con Sistemas!';
                    ROLLBACK;
                    RETURN;
                END IF;
         end if;
         i:= PESABLES_P.NEXT(i);
       End Loop;
    end if;  --fin if cantidad disponible   
    end loop;
  --verifico si queda algún pesable por asignar
  i := PESABLES_P.FIRST;
  While i Is Not Null Loop
     --verifica si esta libre el pesable para asignarlo al primer pedido libre
     if PESABLES_P(i).BANDERA = 0
        and PESABLES_P(i).IDCONSOLIDADOPEDIDO = p_idconsolidado then        
         p_Ok    := 0;
         p_error := 'Error en DISTRIBUCIÓN  Pesables. Comuniquese con Sistemas!';
         n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       '  Detalle Error: Quedan pesables por distribuir' 
                                       ||'  Error: ' || SQLERRM);
         RETURN;
     end if;
     i:= PESABLES_P.NEXT(i);
   End Loop;
  p_Ok    := 1;
  p_error := null;
  EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       '  Detalle Error: ' || v_error
                                       ||'  Error: ' || SQLERRM);
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
    v_error              varchar2(250);
     v_Alterna           integer:=1;
  BEGIN
    for pes in
             ( select frel.idpedfaltanterel,
                      frel.idconsolidadopedido,
                      fd.cdarticulo,
                      pe.idpedido,
                      fd.qtpiezaspicking qtpiezas,
                      pdis.porcdist,   
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
                  and nvl(fd.qtpiezas,0)<>0
                  --con valor pickiado
                  and nvl(fd.qtpiezaspicking, 0) > 0                  
                  and cf.idpedfaltante = p_IdPedFaltante
             order by 2)--ordeno por articulo para mejorar la distribución
    loop
    --trunc+1 las filas pares si aplica para ajustar las decimales
     If mod(v_Alterna,2)=0 
       and (pes.qtpiezas * pes.porcdist)-round(pes.qtpiezas * pes.porcdist,0)<=0.5 then
            pes.qtdistb:=trunc(pes.qtpiezas * pes.porcdist)+1;               
    end if;  
    v_Alterna:=v_Alterna+1;   
    --verifica si existe disponiblidad para el articulo y se puede insertar en tblslvdistribucionpedfaltante
    pes.qtdistb:=Disponibilidad(p_IdPedFaltante,c_TareaConsolidaPedidoFaltante,pes.cdarticulo,-1,pes.qtdistb);
    if pes.qtdistb > 0 then  
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
              v_error:=' Error en insert tblslvdistribucionpedfaltante '||p_IdPedFaltante;
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
                         PESABLES_F(i).QTUNIDADMEDIDABASEPIK,
                         PESABLES_F(i).QTPIEZASPIK
                         );
                         IF SQL%ROWCOUNT = 0 THEN
                              n_pkg_vitalpos_log_general.write(2,
                                                'Modulo: ' || v_modulo ||
                                                '  Detalle Error: ' || v_error);
                              p_Ok    := 0;
                              p_error:='Error. Comuniquese con Sistemas!';
                              ROLLBACK;
                              RETURN;
                          END IF;
         end if;
         i:= PESABLES_F.NEXT(i);
       End Loop;
    end if;   
    end loop;
  --verifico si queda algún pesable por asignar
  i := PESABLES_F.FIRST;
  While i Is Not Null Loop
     --verifica si esta libre el pesable para asignarlo al primer pedido libre
     if PESABLES_F(i).BANDERA = 0
        and PESABLES_F(i).IDCONSOLIDADOPEDIDO = p_IdPedFaltante then      
         p_Ok    := 0;
         p_error := 'Error en DISTRIBUCIÓN Pesables. Comuniquese con Sistemas!';
         n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       '  Detalle Error: Quedan pesables por distribuir' 
                                       ||'  Error: ' || SQLERRM);
         RETURN;
     end if;
     i:= PESABLES_F.NEXT(i);
   End Loop;
  p_Ok    := 1;
  p_error := null;
  EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       '  Detalle Error: ' || v_error
                                       ||'  Error: ' || SQLERRM);
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
    v_error              varchar2(250);
    v_Alterna            integer:=1;

  BEGIN
    for pes in(
       select pe.idpedido,
              dpe.cdarticulo,
              dpe.cdunidadmedida,
              ccd.qtpiezaspicking qtpiezas,
              pdi.porcdist,   
              round(ccd.qtpiezaspicking * pdi.porcdist,0) qtpiezaspicking,
              dpe.ampreciounitario,
              dpe.vluxb,
              dpe.dsobservacion dsobservacion,
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
          -- solo pesables
          and nvl(ccd.qtpiezas,0)<>0
          --excluyo promo
          and dpe.icresppromo = 0
          and cc.idconsolidadocomi = p_idconsolidado
     order by 2)--ordeno por articulo para mejorar la distribución
    loop
   --trunc+1 las filas pares. si aplica para ajustar las decimales
     If mod(v_Alterna,2)=0 
       and (pes.qtpiezas * pes.porcdist)-round(pes.qtpiezas * pes.porcdist,0)<=0.5 then
            pes.qtpiezaspicking:=trunc(pes.qtpiezas * pes.porcdist)+1;               
    end if;  
    v_Alterna:=v_Alterna+1;   
    --verifica si existe disponiblidad para el articulo y se puede insertar en tblslvpedidoconformado
     pes.qtpiezaspicking:=Disponibilidad(p_idconsolidado,c_TareaConsolidadoComi,pes.cdarticulo,-1,pes.qtpiezaspicking);
     if pes.qtpiezaspicking > 0 then 
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
            v_error:=' Error en insert tblslvpedidoconformado '||p_idconsolidado;
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
              --pes.qtunidadpedido igual al distribuido del pesable
               PESABLES_C(i).QTUNIDADMEDIDABASEPIK,
               PESABLES_C(i).QTUNIDADMEDIDABASEPIK,
               PESABLES_C(i).QTPIEZASPIK,
               pes.ampreciounitario,
              --calcula amlinea
               PESABLES_C(i).QTUNIDADMEDIDABASEPIK*pes.ampreciounitario,
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
                    p_error:='Error. Comuniquese con Sistemas!';
                    ROLLBACK;
                    RETURN;
                END IF;
         end if;
         i:= PESABLES_C.NEXT(i);
       End Loop;
    end if; --pes.qtpiezaspicking  
    end loop;
  --verifico si queda algún pesable por asignar
  i := PESABLES_C.FIRST;
  While i Is Not Null Loop
     --verifica si esta libre el pesable para asignarlo al primer pedido libre
     if PESABLES_C(i).BANDERA = 0
        and PESABLES_C(i).IDCONSOLIDADOPEDIDO = p_idconsolidado then      
         p_Ok    := 0;
         p_error := 'Error en DISTRIBUCIÓN Pesables. Comuniquese con Sistemas!';
         n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       '  Detalle Error: Quedan pesables por distribuir' 
                                       ||'  Error: ' || SQLERRM);
         RETURN;
     end if;
     i:= PESABLES_C.NEXT(i);
   End Loop;
  p_Ok    := 1;
  p_error := null;
  EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       '  Detalle Error: ' || v_error
                                       ||'  Error: ' || SQLERRM);
      p_Ok    := 0;
      p_error := 'Error en Pesables. Comuniquese con Sistemas!';

  END DistPesablesC;

 /****************************************************************************************************
  * %v 25/06/2020 - ChM  Versión inicial DistribPromoPesableP
  * %v 25/06/2020 - ChM  distribuye los articulos pesables en promo del consolidado pedido
  *****************************************************************************************************/
  PROCEDURE DistribPromoPesableP(p_idconsolidado       IN  tblslvconsolidadom.idconsolidadom%type,
                                 p_Ok                  OUT number,
                                 p_error               OUT varchar2) is

    v_modulo                   varchar2(100) := 'PKG_SLV_DISTRIBUCION.DistribPromoPesableP';
    v_error                    varchar2(250);
    i                          Binary_Integer := 0;
    v_resto                    detallepedidos.qtpiezas%type;
    v_artant                   tblslvconsolidadopedidodet.cdarticulo%type default null;
    v_piezasbaseant            tblslvconsolidadopedidodet.qtunidadesmedidabase%type default null;

  BEGIN
  --solo articulos en promo ordenados por el que menos compró en cantidad
  for promo in(
             select pe.idpedido,
                    dpe.cdarticulo,
                    dpe.cdunidadmedida,                 
                    pdi.qtpiezas,
                    dpe.ampreciounitario,
                    dpe.vluxb,
                    dpe.dsobservacion,
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
                -- solo articulos en promo
                and pdi.artpromo <> 0
                --valida el tipo de tarea consolidado Pedido en la tabla distribución
                and pdi.cdtipo = c_TareaConsolidadoPedido
                -- solo pesables
                and nvl(cpd.qtpiezas,0)<>0                
                --excluyo linea de promo
                and dpe.icresppromo = 0
                --excluyo comisionistas
                and cp.idconsolidadocomi is null
                and cp.idconsolidadopedido = p_idconsolidado
                 -- ordenados por el que menos compró en cantidad y artículos solo así funciona esta lógica
                 order by pdi.qtpiezas,
                          dpe.cdarticulo)
          loop
            --verifica si el articulo cambio
            if v_artant is not null and promo.cdarticulo <> v_artant then
               --verifica si  distribuyó todo la promo sino error
                v_error:= 'Error en distribución de promociones pesables: '||
                          'ConsoPedido N°'||p_idconsolidado||'Pedido N°'||promo.idpedido||
                          'Articulo N°'||promo.cdarticulo;
               if v_piezasbaseant > 0 then
                   n_pkg_vitalpos_log_general.write(2,
                                                    'Modulo: ' || v_modulo ||
                                                    '  Detalle Error: ' || v_error);
                   p_Ok    := 0;
                   p_error := 'Error en distribución de promociones pesables. Comuniquese con Sistemas!';
                   ROLLBACK;
                   RETURN;
                end if;
               --variables a NULL para buscar la cantidad a distribuir del proximo Artículo
               v_artant:=null;
               v_piezasbaseant:=null;
           end if;
            --busca el total en el consolidado pedido del articulo a distribuir solo si v_unidadbaseant is null
            if v_piezasbaseant is null then
              begin
              select cpd.cdarticulo,
                     sum(cpd.qtpiezaspicking) qtpieza
                into v_artant,
                     v_piezasbaseant
                from tblslvconsolidadopedido        cp,
                     tblslvconsolidadopedidodet     cpd
               where cp.idconsolidadopedido = cpd.idconsolidadopedido
                 and cp.idconsolidadopedido = p_Idconsolidado
                 and cpd.cdarticulo = promo.cdarticulo
            group by cpd.cdarticulo;
             exception
               when others then
                  v_piezasbaseant:=null;
                  v_artant:=null;
             end;
            end if;
          --inserta en tblslvpedidoconformado solo los articulos con cantidades disponibles
          if v_piezasbaseant is not null and v_piezasbaseant>0 then
            --valida si la cantidad asignada es mayor al total. Se asigna el total
            if promo.qtpiezas > v_piezasbaseant then
               promo.qtpiezas:=v_piezasbaseant;
            end if;
            --inserción de pesables uno a uno
             v_resto:=promo.qtpiezas;
             i := PESABLES_P.FIRST;
             While i Is Not Null and v_resto > 0 Loop
               --verifica si esta libre el pesable para asignarlo al pedido
               if PESABLES_P(i).BANDERA = 0
                  and PESABLES_P(i).IDCONSOLIDADOPEDIDO = p_idconsolidado
                  and PESABLES_P(i).CDARTICULO = promo.cdarticulo then

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
                     promo.idpedido,
                     promo.cdarticulo,
                     SecuenciaPedConformado(promo.idpedido)+1,
                     promo.cdunidadmedida,
                     --pes.qtunidadpedido igual al distribuido del pesable
                     PESABLES_P(i).QTUNIDADMEDIDABASEPIK,
                     PESABLES_P(i).QTUNIDADMEDIDABASEPIK,
                     PESABLES_P(i).QTPIEZASPIK,
                     promo.ampreciounitario,
                     --calcula amlinea
                     PESABLES_P(i).QTUNIDADMEDIDABASEPIK*promo.ampreciounitario,
                     promo.vluxb,
                     promo.dsobservacion,
                     promo.icresppromo,
                     promo.cdpromo,
                     sysdate,
                     null);
                     IF SQL%ROWCOUNT = 0 THEN
                          n_pkg_vitalpos_log_general.write(2,
                                            'Modulo: ' || v_modulo ||
                                            '  Detalle Error: ' || v_error);
                          p_Ok    := 0;
                          p_error:='Error. Comuniquese con Sistemas!';
                          ROLLBACK;
                          RETURN;
                      END IF;
               end if;
               i:= PESABLES_P.NEXT(i);
             End Loop;
            --resta al total lo que se asignó al articulo
            v_piezasbaseant:=v_piezasbaseant-promo.qtpiezas;
          end if;
         end loop;
    p_Ok:=1;
    p_error:='';
  EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       '  Detalle Error: ' || v_error ||
                                       '  Error: ' || SQLERRM);
       p_Ok:=0;
       p_error := 'Error en Promociones Pesables. Comuniquese con Sistemas!';
      ROLLBACK;
  END DistribPromoPesableP;

  /****************************************************************************************************
  * %v 18/06/2020 - ChM  Versión inicial DistribPromoP
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
  PROCEDURE DistribPromoP(p_idconsolidado       IN  tblslvconsolidadom.idconsolidadom%type,
                          p_Ok                  OUT number,
                          p_error               OUT varchar2) is

    v_modulo                   varchar2(100) := 'PKG_SLV_DISTRIBUCION.DistribPromoP';
    v_error                    varchar2(250);
    v_artant                   tblslvconsolidadopedidodet.cdarticulo%type default null;
    v_unidadbaseant            tblslvconsolidadopedidodet.qtunidadesmedidabase%type default null;
    v_cdunidadmedida           tblslvpedidoconformado.cdunidadmedida%type;
    v_qtunidadpedido           tblslvpedidoconformado.qtunidadpedido%type;
    v_vluxb                    tblslvpedidoconformado.vluxb%type;

  BEGIN
  --solo articulos en promo ordenados por el que menos compró en cantidad
  for promo in(
             select pe.idpedido,
                    dpe.cdarticulo,
                    pdi.qtunidadmedidabase qtunidadesmedidabase,
                    pdi.qtpiezas,
                    dpe.ampreciounitario,
                    dpe.dsobservacion,
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
                --  valida solo articulos en promo
                and pdi.artpromo = 1
                --  valida el tipo de tarea consolidado Pedido en la tabla distribución
                and pdi.cdtipo = c_TareaConsolidadoPedido
                --  excluyo pesables
                and nvl(cpd.qtpiezas,0)=0                
                --  excluyo linea de promo
                and dpe.icresppromo = 0
                --excluyo comisionistas
                and cp.idconsolidadocomi is null
                and cp.idconsolidadopedido = p_idconsolidado
           -- ordenados por el que menos compró en cantidad y artículos solo así funciona esta lógica
           order by pdi.qtunidadmedidabase,
                    dpe.cdarticulo)
          loop
            --verifica si el articulo cambio
            if v_artant is not null and promo.cdarticulo <> v_artant then
               --verifica si  distribuyó todo la promo sino error
                v_error:= 'Error en distribución de promociones: '||
                          'ConsoPedido N°'||p_idconsolidado||'Pedido N°'||promo.idpedido||
                          'Articulo N°'||promo.cdarticulo;
               if v_unidadbaseant > 0 then
                   n_pkg_vitalpos_log_general.write(2,
                                                    'Modulo: ' || v_modulo ||
                                                    '  Detalle Error: ' || v_error);
                   p_Ok    := 0;
                   p_error := 'Error en distribución de promociones. Comuniquese con Sistemas!';
                   ROLLBACK;
                   RETURN;
                end if;
               --variables a NULL para buscar la cantidad a distribuir del proximo Artículo
               v_artant:=null;
               v_unidadbaseant:=null;
           end if;
            --busca el total en el consolidado pedido del articulo a distribuir solo si v_unidadbaseant is null
            if v_unidadbaseant is null then
              begin
              select cpd.cdarticulo,
                     sum(cpd.qtunidadmedidabasepicking) qtbase
                into v_artant,
                     v_unidadbaseant
                from tblslvconsolidadopedido        cp,
                     tblslvconsolidadopedidodet     cpd
               where cp.idconsolidadopedido = cpd.idconsolidadopedido
                 and cp.idconsolidadopedido = p_Idconsolidado
                 and cpd.cdarticulo = promo.cdarticulo
            group by cpd.cdarticulo;
             exception
               when others then
                  v_unidadbaseant:=null;
                  v_artant:=null;
             end;
            end if;
          --inserta en tblslvpedidoconformado solo los articulos con cantidades disponibles
          if v_unidadbaseant is not null and v_unidadbaseant>0 then
            --valida si la cantidad asignada es mayor al total. Se asigna el total
            if promo.qtunidadesmedidabase > v_unidadbaseant then
               promo.qtunidadesmedidabase:=v_unidadbaseant;
            end if;
            --inserto la distribución del pedido en tblslvpedidoconformado
                v_error:= 'Error en insert en tblslvpedidoconformado';
                --calculo la unidad de medida
                v_cdunidadmedida:=PKG_SLV_ARTICULO.GET_UNIDADMEDIDA(promo.qtunidadesmedidabase,promo.cdarticulo);
                --calculo el nuevo vluxb
                v_vluxb:=PKG_SLV_ARTICULO.GetUXBArticulo(promo.cdarticulo,v_cdunidadmedida);
                --calculo el nuevo qtunidadpedido
                v_qtunidadpedido:= PKG_SLV_ARTICULO.CONVERTIRUNIDADES(promo.cdarticulo,promo.qtunidadesmedidabase,'UN',v_cdunidadmedida, 0);
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
                        (promo.idpedido,
                         promo.cdarticulo,
                         SecuenciaPedConformado(promo.idpedido)+1,
                         v_cdunidadmedida,
                         v_qtunidadpedido,
                         promo.qtunidadesmedidabase,
                         promo.qtpiezas,
                         promo.ampreciounitario,
                         --multiplica la nueva cantidad base x el amprecio pra el nuevo valor de amlinea
                         promo.qtunidadesmedidabase*promo.ampreciounitario,
                         v_vluxb,
                         promo.dsobservacion,
                         promo.icresppromo,
                         promo.cdpromo,
                         promo.dtinsert,
                         promo.dtupdate);
                   IF SQL%ROWCOUNT = 0 THEN
                   n_pkg_vitalpos_log_general.write(2,
                                                    'Modulo: ' || v_modulo ||
                                                    '  Detalle Error: ' || v_error);
                   p_Ok    := 0;
                   p_error:='Error. Comuniquese con Sistemas!';
                   ROLLBACK;
                   RETURN;
                 END IF;
            --resta al total lo que se asignó al articulo
            v_unidadbaseant:=v_unidadbaseant-promo.qtunidadesmedidabase;
          end if;
         end loop;
    p_Ok:=1;
    p_error:='';
  EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       '  Detalle Error: ' || v_error ||
                                       '  Error: ' || SQLERRM);
      p_Ok:=0;
      p_error := 'Error en Promociones. Comuniquese con Sistemas!';
      ROLLBACK;
  END DistribPromoP;
  /****************************************************************************************************
  * %v 26/06/2020 - ChM  Versión inicial DistribPromoPesableF
  * %v 26/06/2020 - ChM  distribuye los articulos pesables en promo del consolidado Faltante
  *****************************************************************************************************/
  PROCEDURE DistribPromoPesableF(p_IdPedFaltante       IN  tblslvconsolidadom.idconsolidadom%type,
                                 p_Ok                  OUT number,
                                 p_error               OUT varchar2) is

    v_modulo                   varchar2(100) := 'PKG_SLV_DISTRIBUCION.DistribPromoPesableF';
    v_error                    varchar2(250);
    i                          Binary_Integer := 0;
    v_resto                    detallepedidos.qtpiezas%type;
    v_artant                   tblslvconsolidadopedidodet.cdarticulo%type default null;
    v_piezasbaseant            tblslvconsolidadopedidodet.qtunidadesmedidabase%type default null;

  BEGIN
 --solo articulos en promo ordenados por el que menos le falto en cantidad
  for promo in(
             select frel.idpedfaltanterel,
                    fd.cdarticulo,
                    fd.qtpiezas
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
                --solo articulos en promo
                and pdis.artpromo <> 0
                and fd.cdarticulo = pdis.cdarticulo
                and cpd.cdarticulo = fd.cdarticulo
                -- solo pesables
                and nvl(fd.qtpiezas,0)<>0
                and cf.idpedfaltante = p_IdPedFaltante
           -- ordenados por el que menos le faltó en cantidad y artículos solo así funciona esta lógica
           order by fd.qtpiezas,
                    fd.cdarticulo)
          loop
            --verifica si el articulo cambio
            if v_artant is not null and promo.cdarticulo <> v_artant then
               --verifica si distribuyó todo la promo sino error
                v_error:= 'Error en distribución de promociones: '||
                          'FaltantePedido N°'||p_IdPedFaltante||
                          ' Articulo N°'||promo.cdarticulo;
               if v_piezasbaseant  > 0 then
                   n_pkg_vitalpos_log_general.write(2,
                                                    'Modulo: ' || v_modulo ||
                                                    '  Detalle Error: ' || v_error);
                   p_Ok    := 0;
                   p_error := 'Error en distribución de promociones. Comuniquese con Sistemas!';
                   ROLLBACK;
                   RETURN;
                end if;
               --variables a NULL para buscar la cantidad a distribuir del proximo Artículo
               v_artant:=null;
               v_piezasbaseant:=null;
           end if;
            --busca el total en el consolidado faltante del articulo a distribuir solo si v_unidadbaseant is null
            if v_piezasbaseant is null then
              begin
                select pfd.cdarticulo,
                       sum(pfd.qtpiezas) qtbase
                  into v_artant,
                       v_piezasbaseant
                  from tblslvpedfaltante          pf,
                       tblslvpedfaltantedet       pfd
                 where pf.idpedfaltante = pfd.idpedfaltante
                   and pf.idpedfaltante = p_IdPedFaltante
                   and pfd.cdarticulo = promo.cdarticulo
              group by pfd.cdarticulo;
             exception
               when others then
                  v_piezasbaseant:=null;
                  v_artant:=null;
             end;
            end if;
          --inserta en tblslvdistribucionpedfaltante  solo los articulos con cantidades disponibles
          if v_piezasbaseant is not null and v_piezasbaseant >0 then
            --valida si la cantidad asignada es mayor al total. Se asigna el total
            if promo.qtpiezas > v_piezasbaseant then
               promo.qtpiezas:=v_piezasbaseant;
            end if;
            --inserto la distribución del faltante en tblslvdistribucionpedfaltante
             v_resto:=promo.qtpiezas;
             i := PESABLES_F.FIRST;
             While i Is Not Null and v_resto > 0 Loop
               --verifica si esta libre el pesable para asignarlo al pedido
               if PESABLES_F(i).BANDERA = 0
                  and PESABLES_F(i).IDCONSOLIDADOPEDIDO = p_IdPedFaltante
                  and PESABLES_F(i).CDARTICULO = promo.cdarticulo then

                  --marco el pesable como asignado
                  PESABLES_F(i).BANDERA:=1;

                  --se va restando el qtpiezaspick a la cantidad de piezas solicitadas
                  v_resto:=v_resto-PESABLES_F(i).QTPIEZASPIK;

                  --se inserta el valor del pesable uno a uno en tblslvdistribucionpedfaltante
                    v_error:=' Error en insert tblslvdistribucionpedfaltante '||p_IdPedFaltante;
                  insert into tblslvdistribucionpedfaltante
                              (iddistribucionpedfaltante,
                              idpedfaltanterel,
                              cdarticulo,
                              qtunidadmedidabase,
                              qtpiezas)
                       values
                              (seq_distribucionpedfaltante.nextval,
                               promo.idpedfaltanterel,
                               promo.cdarticulo,
                               PESABLES_F(i).QTUNIDADMEDIDABASEPIK,
                               PESABLES_F(i).QTPIEZASPIK
                               );
                               IF SQL%ROWCOUNT = 0 THEN
                                    n_pkg_vitalpos_log_general.write(2,
                                                      'Modulo: ' || v_modulo ||
                                                      '  Detalle Error: ' || v_error);
                                    p_Ok    := 0;
                                    p_error:='Error. Comuniquese con Sistemas!';
                                    ROLLBACK;
                                    RETURN;
                                END IF;
               end if;
               i:= PESABLES_F.NEXT(i);
             End Loop;
            --resta al total lo que se asignó al articulo
            v_piezasbaseant:=v_piezasbaseant-promo.qtpiezas;
          end if;
         end loop;
    p_Ok:=1;
    p_error:='';
  EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       '  Detalle Error: ' || v_error ||
                                       '  Error: ' || SQLERRM);
      p_Ok:=0;
      p_error := 'Error en Promociones. Comuniquese con Sistemas!';
      ROLLBACK;
  END DistribPromoPesableF;

  /****************************************************************************************************
  * %v 26/06/2020 - ChM  Versión inicial DistribPromoF
  * %v 26/06/2020 - ChM  distribuye los articulos en promo del consolidado faltante
  *****************************************************************************************************/
  PROCEDURE DistribPromoF(p_IdPedFaltante       IN  tblslvconsolidadom.idconsolidadom%type,
                          p_Ok                  OUT number,
                          p_error               OUT varchar2) is

    v_modulo                   varchar2(100) := 'PKG_SLV_DISTRIBUCION.DistribPromoF';
    v_error                    varchar2(250);
    v_artant                   tblslvconsolidadopedidodet.cdarticulo%type default null;
    v_unidadbaseant            tblslvconsolidadopedidodet.qtunidadesmedidabase%type default null;

  BEGIN
  --solo articulos en promo ordenados por el que menos le falto en cantidad
  for promo in(
             select frel.idpedfaltanterel,
                    fd.cdarticulo,
                    fd.qtunidadmedidabase,
                    fd.qtpiezas
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
                --solo articulos en promo
                and pdis.artpromo <> 0
                and fd.cdarticulo = pdis.cdarticulo
                and cpd.cdarticulo = fd.cdarticulo
                -- excluyo pesables
                and nvl(fd.qtpiezas,0)=0
                and cf.idpedfaltante = p_IdPedFaltante
           -- ordenados por el que menos le faltó en cantidad y artículos solo así funciona esta lógica
           order by fd.qtunidadmedidabase,
                    fd.cdarticulo)
          loop
            --verifica si el articulo cambio
            if v_artant is not null and promo.cdarticulo <> v_artant then
               --verifica si distribuyó todo la promo sino error
                v_error:= 'Error en distribución de promociones: '||
                          'FaltantePedido N°'||p_IdPedFaltante||
                          ' Articulo N°'||promo.cdarticulo;
               if v_unidadbaseant > 0 then
                   n_pkg_vitalpos_log_general.write(2,
                                                    'Modulo: ' || v_modulo ||
                                                    '  Detalle Error: ' || v_error);
                   p_Ok    := 0;
                   p_error := 'Error en distribución de promociones. Comuniquese con Sistemas!';
                   ROLLBACK;
                   RETURN;
                end if;
               --variables a NULL para buscar la cantidad a distribuir del proximo Artículo
               v_artant:=null;
               v_unidadbaseant:=null;
           end if;
            --busca el total en el consolidado faltante del articulo a distribuir solo si v_unidadbaseant is null
            if v_unidadbaseant is null then
              begin
                select pfd.cdarticulo,
                       sum(pfd.qtunidadmedidabasepicking) qtbase
                  into v_artant,
                       v_unidadbaseant
                  from tblslvpedfaltante          pf,
                       tblslvpedfaltantedet       pfd
                 where pf.idpedfaltante = pfd.idpedfaltante
                   and pf.idpedfaltante = p_IdPedFaltante
                   and pfd.cdarticulo = promo.cdarticulo
              group by pfd.cdarticulo;
             exception
               when others then
                  v_unidadbaseant:=null;
                  v_artant:=null;
             end;
            end if;
          --inserta en tblslvdistribucionpedfaltante  solo los articulos con cantidades disponibles
          if v_unidadbaseant is not null and v_unidadbaseant>0 then
            --valida si la cantidad asignada es mayor al total. Se asigna el total
            if promo.qtunidadmedidabase > v_unidadbaseant then
               promo.qtunidadmedidabase:=v_unidadbaseant;
            end if;
            --inserto la distribución del faltante en tblslvdistribucionpedfaltante
             insert into tblslvdistribucionpedfaltante
                         (iddistribucionpedfaltante,
                          idpedfaltanterel,
                          cdarticulo,
                          qtunidadmedidabase,
                          qtpiezas)
                          values
                          (seq_distribucionpedfaltante.nextval,
                           promo.idpedfaltanterel,
                           promo.cdarticulo,
                           promo.qtunidadmedidabase,
                           promo.qtpiezas);
                   IF SQL%ROWCOUNT = 0 THEN
                   n_pkg_vitalpos_log_general.write(2,
                                                    'Modulo: ' || v_modulo ||
                                                    '  Detalle Error: ' || v_error);
                   p_Ok    := 0;
                   p_error:='Error. Comuniquese con Sistemas!';
                   ROLLBACK;
                   RETURN;
                 END IF;
            --resta al total lo que se asignó al articulo
            v_unidadbaseant:=v_unidadbaseant-promo.qtunidadmedidabase;
          end if;
         end loop;
    p_Ok:=1;
    p_error:='';
  EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       '  Detalle Error: ' || v_error ||
                                       '  Error: ' || SQLERRM);
      p_Ok:=0;
      p_error := 'Error en Promociones. Comuniquese con Sistemas!';
      ROLLBACK;
  END DistribPromoF;
 -------------------------------------------------------------------------------------------------------
  /****************************************************************************************************
  * %v 25/06/2020 - ChM  Versión inicial DistribPromoPesableC
  * %v 25/06/2020 - ChM  distribuye los articulos pesables en promo del consolidado comisionista
  *****************************************************************************************************/
  PROCEDURE DistribPromoPesableC(p_idconsolidado       IN  tblslvconsolidadom.idconsolidadom%type,
                                 p_Ok                  OUT number,
                                 p_error               OUT varchar2) is

    v_modulo                   varchar2(100) := 'PKG_SLV_DISTRIBUCION.DistribPromoPesableC';
    v_error                    varchar2(250);
    i                          Binary_Integer := 0;
    v_resto                    detallepedidos.qtpiezas%type;
    v_artant                   tblslvconsolidadopedidodet.cdarticulo%type default null;
    v_piezasbaseant            tblslvconsolidadopedidodet.qtunidadesmedidabase%type default null;

  BEGIN
  --solo articulos en promo ordenados por el que menos compró en cantidad
  for promo in(
             select pe.idpedido,
                    dpe.cdarticulo,
                    dpe.cdunidadmedida,
                    --solo lo solicitado para ese pedido
                    pdi.qtpiezas,
                    dpe.ampreciounitario,
                    dpe.vluxb,
                    dpe.dsobservacion dsobservacion,
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
                    tblslvpordistrib             pdi,
                    tblslvconsolidadopedidodet   cpd
              where pe.idpedido = dpe.idpedido
                and pe.idpedido = cprel.idpedido
                and cprel.idconsolidadopedido = cp.idconsolidadopedido
                and cp.idconsolidadocomi = cc.idconsolidadocomi
                and cc.idconsolidadocomi = ccd.idconsolidadocomi
                and ccd.cdarticulo = dpe.cdarticulo
                and cpd.idconsolidadopedido = cp.idconsolidadopedido
                and cpd.cdarticulo = ccd.cdarticulo
                and pdi.idpedido = pe.idpedido
                and pdi.idconsolidado = cc.idconsolidadocomi
                and pdi.cdarticulo = ccd.cdarticulo
                -- solo articulos EN promo
                and pdi.artpromo <> 0
                --valida el tipo de tarea consolidado comi en la tabla distribución
                and pdi.cdtipo = c_TareaConsolidadoComi
                -- solo pesables
                and nvl(ccd.qtpiezas,0)<>0               
                --excluyo promo
                and dpe.icresppromo = 0
                and cc.idconsolidadocomi = p_idconsolidado
                 -- ordenados por el que menos compró en cantidad y artículos solo así funciona esta lógica
                 order by pdi.qtpiezas,
                          dpe.cdarticulo)
          loop
            --verifica si el articulo cambio
            if v_artant is not null and promo.cdarticulo <> v_artant then
               --verifica si  distribuyó todo la promo sino error
                v_error:= 'Error en distribución de promociones pesables: '||
                          'ConsoPedido N°'||p_idconsolidado||'Pedido N°'||promo.idpedido||
                          'Articulo N°'||promo.cdarticulo;
               if v_piezasbaseant > 0 then
                   n_pkg_vitalpos_log_general.write(2,
                                                    'Modulo: ' || v_modulo ||
                                                    '  Detalle Error: ' || v_error);
                   p_Ok    := 0;
                   p_error := 'Error en distribución de promociones pesables. Comuniquese con Sistemas!';
                   ROLLBACK;
                   RETURN;
                end if;
               --variables a NULL para buscar la cantidad a distribuir del proximo Artículo
               v_artant:=null;
               v_piezasbaseant:=null;
           end if;
            --busca el total en el consolidado COMI del articulo a distribuir solo si v_unidadbaseant is null
            if v_piezasbaseant is null then
              begin
              select ccd.cdarticulo,
                       sum(ccd.qtpiezaspicking) qtbase
                  into v_artant,
                       v_piezasbaseant
                  from tblslvconsolidadocomi              cc,
                       tblslvconsolidadocomidet           ccd
                 where cc.idconsolidadocomi = ccd.idconsolidadocomi
                   and cc.idconsolidadocomi = p_Idconsolidado
                   and ccd.cdarticulo = promo.cdarticulo
              group by ccd.cdarticulo;
             exception
               when others then
                  v_piezasbaseant:=null;
                  v_artant:=null;
             end;
            end if;
          --inserta en tblslvpedidoconformado solo los articulos con cantidades disponibles
          if v_piezasbaseant is not null and v_piezasbaseant>0 then
            --valida si la cantidad asignada es mayor al total. Se asigna el total
            if promo.qtpiezas > v_piezasbaseant then
               promo.qtpiezas:=v_piezasbaseant;
            end if;
            --inserción de pesables uno a uno
             v_resto:=promo.qtpiezas;
             i := PESABLES_C.FIRST;
             While i Is Not Null and v_resto > 0 Loop
               --verifica si esta libre el pesable para asignarlo al pedido
               if PESABLES_C(i).BANDERA = 0
                  and PESABLES_C(i).IDCONSOLIDADOPEDIDO = p_idconsolidado
                  and PESABLES_C(i).CDARTICULO = promo.cdarticulo then

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
                     promo.idpedido,
                     promo.cdarticulo,
                     SecuenciaPedConformado(promo.idpedido)+1,
                     promo.cdunidadmedida,
                     --pes.qtunidadpedido igual al distribuido del pesable
                     PESABLES_C(i).QTUNIDADMEDIDABASEPIK,
                     PESABLES_C(i).QTUNIDADMEDIDABASEPIK,
                     PESABLES_C(i).QTPIEZASPIK,
                     promo.ampreciounitario,
                     --calcula amlinea
                     PESABLES_C(i).QTUNIDADMEDIDABASEPIK*promo.ampreciounitario,
                     promo.vluxb,
                     promo.dsobservacion,
                     promo.icresppromo,
                     promo.cdpromo,
                     sysdate,
                     null);
                     IF SQL%ROWCOUNT = 0 THEN
                          n_pkg_vitalpos_log_general.write(2,
                                            'Modulo: ' || v_modulo ||
                                            '  Detalle Error: ' || v_error);
                          p_Ok    := 0;
                          p_error:='Error. Comuniquese con Sistemas!';
                          ROLLBACK;
                          RETURN;
                      END IF;
               end if;
               i:= PESABLES_C.NEXT(i);
             End Loop;
            --resta al total lo que se asignó al articulo
            v_piezasbaseant:=v_piezasbaseant-promo.qtpiezas;
          end if;
         end loop;
    p_Ok:=1;
    p_error:='';
  EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       '  Detalle Error: ' || v_error ||
                                       '  Error: ' || SQLERRM);
       p_Ok:=0;
       p_error := 'Error en Promociones Pesables. Comuniquese con Sistemas!';
      ROLLBACK;
  END DistribPromoPesableC;

  /****************************************************************************************************
  * %v 26/06/2020 - ChM  Versión inicial DistribPromoC
  * %v 26/06/2020 - ChM  distribuye los articulos en promo del consolidado comisionista
  *****************************************************************************************************/
  PROCEDURE DistribPromoC(p_idconsolidado       IN  tblslvconsolidadom.idconsolidadom%type,
                          p_Ok                  OUT number,
                          p_error               OUT varchar2) is

    v_modulo                   varchar2(100) := 'PKG_SLV_DISTRIBUCION.DistribPromoC';
    v_error                    varchar2(250);
    v_artant                   tblslvconsolidadopedidodet.cdarticulo%type default null;
    v_unidadbaseant            tblslvconsolidadopedidodet.qtunidadesmedidabase%type default null;
    v_cdunidadmedida           tblslvpedidoconformado.cdunidadmedida%type;
    v_qtunidadpedido           tblslvpedidoconformado.qtunidadpedido%type;
    v_vluxb                    tblslvpedidoconformado.vluxb%type;

  BEGIN
  --solo articulos en promo ordenados por el que menos compró en cantidad
  for promo in(
             select pe.idpedido,
                    dpe.cdarticulo,
                    --solo lo solicitado para el idpedido
                    pdi.qtunidadmedidabase qtunidadesmedidabase,
                    pdi.qtpiezas,
                    dpe.ampreciounitario,
                    dpe.dsobservacion,
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
                    tblslvpordistrib             pdi,
                    tblslvconsolidadopedidodet   cpd
              where pe.idpedido = dpe.idpedido
                and pe.idpedido = cprel.idpedido
                and cprel.idconsolidadopedido = cp.idconsolidadopedido
                and cp.idconsolidadocomi = cc.idconsolidadocomi
                and cc.idconsolidadocomi = ccd.idconsolidadocomi
                and ccd.cdarticulo = dpe.cdarticulo
                and cpd.idconsolidadopedido = cp.idconsolidadopedido
                and cpd.cdarticulo = ccd.cdarticulo
                and pdi.idpedido = pe.idpedido
                and pdi.idconsolidado = cc.idconsolidadocomi
                and pdi.cdarticulo = ccd.cdarticulo
                -- solo articulos EN promo
                and pdi.artpromo <> 0
                --valida el tipo de tarea consolidado Comi en la tabla distribución
                and pdi.cdtipo = c_TareaConsolidadoComi
                -- excluyo pesables
                and nvl(ccd.qtpiezas,0)=0                
                --excluyo lineas de promo
                and dpe.icresppromo = 0
                and cc.idconsolidadocomi = p_idconsolidado
           -- ordenados por el que menos compró en cantidad y artículos solo así funciona esta lógica
           order by pdi.qtunidadmedidabase,
                    dpe.cdarticulo)
          loop
            --verifica si el articulo cambio
            if v_artant is not null and promo.cdarticulo <> v_artant then
               --verifica si  distribuyó todo la promo sino error
                v_error:= 'Error en distribución de promociones: '||
                          'ConsoPedido N°'||p_idconsolidado||'Pedido N°'||promo.idpedido||
                          'Articulo N°'||promo.cdarticulo;
               if v_unidadbaseant > 0 then
                   n_pkg_vitalpos_log_general.write(2,
                                                    'Modulo: ' || v_modulo ||
                                                    '  Detalle Error: ' || v_error);
                   p_Ok    := 0;
                   p_error := 'Error en distribución de promociones. Comuniquese con Sistemas!';
                   ROLLBACK;
                   RETURN;
                end if;
               --variables a NULL para buscar la cantidad a distribuir del proximo Artículo
               v_artant:=null;
               v_unidadbaseant:=null;
           end if;
            --busca el total en el consolidado comi del articulo a distribuir solo si v_unidadbaseant is null
            if v_unidadbaseant is null then
              begin
                select ccd.cdarticulo,
                       sum(ccd.qtunidadmedidabasepicking) qtbase
                  into v_artant,
                       v_unidadbaseant
                  from tblslvconsolidadocomi              cc,
                       tblslvconsolidadocomidet           ccd
                 where cc.idconsolidadocomi = ccd.idconsolidadocomi
                   and cc.idconsolidadocomi = p_Idconsolidado
                   and ccd.cdarticulo = promo.cdarticulo
              group by ccd.cdarticulo;
             exception
               when others then
                  v_unidadbaseant:=null;
                  v_artant:=null;
             end;
            end if;
          --inserta en tblslvpedidoconformado solo los articulos con cantidades disponibles
          if v_unidadbaseant is not null and v_unidadbaseant>0 then
            --valida si la cantidad asignada es mayor al total. Se asigna el total
            if promo.qtunidadesmedidabase > v_unidadbaseant then
               promo.qtunidadesmedidabase:=v_unidadbaseant;
            end if;
            --inserto la distribución del pedido en tblslvpedidoconformado
                v_error:= 'Error en insert en tblslvpedidoconformado';
                --calculo la unidad de medida
                v_cdunidadmedida:=PKG_SLV_ARTICULO.GET_UNIDADMEDIDA(promo.qtunidadesmedidabase,promo.cdarticulo);
                --calculo el nuevo vluxb
                v_vluxb:=PKG_SLV_ARTICULO.GetUXBArticulo(promo.cdarticulo,v_cdunidadmedida);
                --calculo el nuevo qtunidadpedido
                v_qtunidadpedido:= PKG_SLV_ARTICULO.CONVERTIRUNIDADES(promo.cdarticulo,promo.qtunidadesmedidabase,'UN',v_cdunidadmedida, 0);
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
                        (promo.idpedido,
                         promo.cdarticulo,
                         SecuenciaPedConformado(promo.idpedido)+1,
                         v_cdunidadmedida,
                         v_qtunidadpedido,
                         promo.qtunidadesmedidabase,
                         promo.qtpiezas,
                         promo.ampreciounitario,
                         --multiplica la nueva cantidad base x el amprecio pra el nuevo valor de amlinea
                         promo.qtunidadesmedidabase*promo.ampreciounitario,
                         v_vluxb,
                         promo.dsobservacion,
                         promo.icresppromo,
                         promo.cdpromo,
                         promo.dtinsert,
                         promo.dtupdate);
                   IF SQL%ROWCOUNT = 0 THEN
                   n_pkg_vitalpos_log_general.write(2,
                                                    'Modulo: ' || v_modulo ||
                                                    '  Detalle Error: ' || v_error);
                   p_Ok    := 0;
                   p_error:='Error. Comuniquese con Sistemas!';
                   ROLLBACK;
                   RETURN;
                 END IF;
            --resta al total lo que se asignó al articulo
            v_unidadbaseant:=v_unidadbaseant-promo.qtunidadesmedidabase;
          end if;
         end loop;
    p_Ok:=1;
    p_error:='';
  EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       '  Detalle Error: ' || v_error ||
                                       '  Error: ' || SQLERRM);
      p_Ok:=0;
      p_error := 'Error en Promociones. Comuniquese con Sistemas!';
      ROLLBACK;
  END DistribPromoC;
 /****************************************************************************************************
 * %v 05/06/2020 - ChM  Versión inicial SetDistribucionPedidoFaltante
 * %v 05/06/2020 - ChM  procedimiento para la distribución de los faltantes de pedidos
 * %v 05/06/2020 - ChM  Falta la distribución de pesables y promos además validar redondeos
 *****************************************************************************************************/

 PROCEDURE SetDistribucionPedidoFaltante(p_idpersona     IN personas.idpersona%type,
                                         p_IdPedFaltante IN Tblslvpedfaltante.Idpedfaltante%type,
                                         p_Ok            OUT number,
                                         p_error         OUT varchar2) IS

   v_modulo                        varchar2(100) := 'PKG_SLV_DISTRIBUCION.SetDistribucionPedidoFaltante';
   v_error                         varchar2(250);
   v_pedfal                        Tblslvpedfaltante.Cdestado%type := null;
   v_qtbasepromo                   tblslvpordistrib.qtunidadmedidabase%type;
   v_qtpiezaspromo                 tblslvpordistrib.qtpiezas%type;
   v_Alterna                       integer:=1;

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
   PorcDistribFaltantes(p_IdPedFaltante,v_qtbasepromo,v_qtpiezaspromo,p_Ok,p_error);
   if P_OK = 0 then
     ROLLBACK;
     RETURN;
    END IF;
    
     --cargo la tabla en memoria con los articulos a distribuir del consolidado faltante
    v_pedfal:=TempDistrib(p_IdPedFaltante,c_TareaConsolidaPedidoFaltante);
    
    --verifico si el consolidado faltante no tiene picking
    if v_pedfal = 0 then
       p_Ok    := 0;
       p_error := 'Error consolidado Faltante N° '||p_IdPedFaltante|| 'no tiene artículos a Distribuir.';
       RETURN;
    end if;   
    
   --inserto la distribución  del faltante
    v_error:= 'Error en insert tblslvdistribucionpedfaltante';
   for falt in
                  (select frel.idpedfaltanterel,
                          frel.idconsolidadopedido,
                          fd.cdarticulo,
                          fd.qtunidadmedidabasepicking,
                          pdis.porcdist,
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
                      -- solo articulos sin promo
                      and pdis.artpromo = 0
                      --valida el tipo de tarea de faltante en la tabla distribución
                      and pdis.cdtipo = c_TareaConsolidaPedidoFaltante
                      and pdis.idpedido = pe.idpedido
                      and pdis.cdarticulo = cpd.cdarticulo                    
                      and fd.cdarticulo = pdis.cdarticulo
                      and cpd.cdarticulo = fd.cdarticulo
                      -- excluyo pesables
                      and nvl(fd.qtpiezas,0)=0
                      --con valor pickiado
                      and nvl(fd.qtunidadmedidabasepicking, 0) > 0                      
                      and cf.idpedfaltante = p_IdPedFaltante
                 order by 3)--ordeno por articulo para mejorar la distribución
   loop
    --trunc+1 las filas pares si aplica para ajustar las decimales
     If mod(v_Alterna,2)=0 
        and (falt.qtunidadmedidabasepicking * falt.porcdist)-round(falt.qtunidadmedidabasepicking * falt.porcdist,0)<=0.5 then
         falt.qtdistb:=trunc(falt.qtunidadmedidabasepicking * falt.porcdist)+1;
    end if;  
    v_Alterna:=v_Alterna+1;  
   --verifica si existe disponiblidad para el articulo y se puede insertar en tblslvdistribucionpedfaltante
   falt.qtdistb:=Disponibilidad(p_IdPedFaltante,c_TareaConsolidaPedidoFaltante,falt.cdarticulo,falt.qtdistb,-1);
   if falt.qtdistb > 0 then       
     insert into tblslvdistribucionpedfaltante
                 (iddistribucionpedfaltante,
                  idpedfaltanterel,
                  cdarticulo,
                  qtunidadmedidabase,
                  qtpiezas)
          values (seq_distribucionpedfaltante.nextval,
                  falt.idpedfaltanterel,
                  falt.cdarticulo,
                  falt.QTDISTB,
                  falt.qtpiezaspicking);
         IF SQL%ROWCOUNT = 0 THEN
             n_pkg_vitalpos_log_general.write(2,
                                              'Modulo: ' || v_modulo ||
                                              '  Detalle Error: ' || v_error);
             p_Ok    := 0;
             p_error:='Error. Comuniquese con Sistemas!';
             ROLLBACK;
             RETURN;
         END IF;             
   end if;  
   end loop;                      

  --cargo la tabla en memoria con los pesables del consolidado faltante
  v_pedfal:=TempPesablesF(p_IdPedFaltante);

  --verifica si existen pesables en el pedido y los distribuye
  if v_pedfal > 1 then
    --verifica si existen pesables en promo, si es así los distribuye  
     if v_qtpiezaspromo > 0 then
         DistribPromoPesableF(p_IdPedFaltante,p_ok,p_error);
         if p_Ok  = 0 then
           rollback;
           return;
         end if;
     end if;
     DistPesablesF(p_IdPedFaltante,p_ok,p_error);
     if p_Ok  = 0 then
       rollback;
       return;
     end if;
    end if;
   --verifica si existen promos, si es así las distribuye   
   if v_qtbasepromo > 0 then
         DistribPromoF(p_IdPedFaltante,p_ok,p_error);
         if p_Ok  = 0 then
           rollback;
           return;
         end if;
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
     p_error:='Error. Comuniquese con Sistemas!';
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
     p_error:='Error. Comuniquese con Sistemas!';
     ROLLBACK;
     RETURN;
   END IF;
 --Valida si todos los articulos se distribuyeron correctamente
   ValidaDistribucion(p_IdPedFaltante,c_TareaConsolidaPedidoFaltante,p_Ok,p_error);  
    if p_Ok  = 0 then
         rollback;
         return;
       end if; 
  --Actualizo la tabla tblslvconsolidadopedidodet con los articulos encontrados en la distribucion de faltante  
  for detpedido in
       (select dfa.cdarticulo,
               cp.idconsolidadopedido,               
               sum(dfa.qtunidadmedidabase) base,
               sum(dfa.qtpiezas) piezas
          from tblslvconsolidadopedido            cp,
               tblslvdistribucionpedfaltante      dfa,
               tblslvpedfaltanterel               frel
         where cp.idconsolidadopedido = frel.idconsolidadopedido
           and dfa.idpedfaltanterel = frel.idpedfaltanterel
           and frel.idpedfaltante = p_IdPedFaltante
      group by dfa.cdarticulo,
               cp.idconsolidadopedido)
  loop    
    v_error:= 'Error en update tblslvconsolidadopedidodet';    
    update tblslvconsolidadopedidodet c
       set c.qtunidadmedidabasepicking = c.qtunidadmedidabasepicking+detpedido.base,
           c.qtpiezaspicking = nvl(c.qtpiezaspicking,0)+detpedido.piezas
     where c.idconsolidadopedido = detpedido.idconsolidadopedido
       and c.cdarticulo = detpedido.cdarticulo;
    IF SQL%ROWCOUNT = 0 THEN
     n_pkg_vitalpos_log_general.write(2,
                                      'Modulo: ' || v_modulo ||
                                      '  Detalle Error: ' || v_error);
     p_Ok    := 0;
     p_error:='Error. Comuniquese con Sistemas!';
     ROLLBACK;
     RETURN;
   END IF;
  end loop;
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

   v_modulo                       varchar2(100) := 'PKG_SLV_DISTRIBUCION.SetDistribucionPedidos';
   v_error                        varchar2(250);
   v_ped                          Tblslvconsolidadopedido.Idconsolidadopedido%type:= null;
   v_estado                       tblslvconsolidadopedido.cdestado%type:=null;
   v_cdunidadmedida               tblslvpedidoconformado.cdunidadmedida%type;
   v_qtunidadpedido               tblslvpedidoconformado.qtunidadpedido%type;
   v_vluxb                        tblslvpedidoconformado.vluxb%type;
   v_qtbasepromo                  tblslvpordistrib.qtunidadmedidabase%type;
   v_qtpiezaspromo                tblslvpordistrib.qtpiezas%type;
   v_Alterna                      integer:=1;
   v_pedfal                       tblslvpedfaltante.idpedfaltante%type:=null;
   
 BEGIN
   --select para validar que el pedido no es parte de un consolidado faltante sin distribuir
      begin
      v_error := 'Falla validación con pedidos Faltantes';
      select pf.idpedfaltante
        into v_pedfal
        from tblslvpedfaltante        pf,
             tblslvpedfaltanterel     pfrel,
             tblslvconsolidadopedido  cp
       where pf.idpedfaltante = pfrel.idpedfaltante
         and pfrel.idconsolidadopedido = cp.idconsolidadopedido
         and cp.idconsolidadopedido = p_IdPedidos
         and pf.cdestado <> C_DistribFaltanteConsolidaPed;         
      if v_pedfal is not null then
          p_Ok    := 0;
          p_error := 'Error el pedido pertenece al Faltante N°: '||v_pedfal|| 'sin distribuir';
          return;
      end if;
      exception
        when no_data_found then
         null;
      end; 
      
          
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
    if v_estado in (C_AFacturarConsolidadoPedido,C_FacturadoConsolidadoPedido) then
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

   --calcula los porcentajes que se aplicarán en la distribución de pedidos
   PorcDistribConsolidado(p_IdPedidos,v_qtbasepromo,v_qtpiezaspromo,p_Ok,p_error);
   if P_OK = 0 then
     ROLLBACK;
     RETURN;
    END IF;
    
    --cargo la tabla en memoria con los articulos a distribuir del consolidado pedido
   v_ped:=TempDistrib(p_IdPedidos,c_TareaConsolidadoPedido);
   
   --verifico si el consolidado pedido no tiene picking
    if v_ped = 0 then
       p_Ok    := 0;
       p_error := 'Error consolidado pedido N° '||p_IdPedidos|| ' no tiene artículos a facturar.';
       RETURN;
    end if; 

 --inserto la distribución del pedido en tblslvpedidoconformado
 v_error:= 'Error en insert en tblslvpedidoconformado';
 for conformado in(
                   select pe.idpedido,
                          dpe.cdarticulo,
                          cpd.qtunidadmedidabasepicking,
                          pdi.porcdist,
                          round(cpd.qtunidadmedidabasepicking * pdi.porcdist,0) qtbase,
                          dpe.qtunidadmedidabase qtbaseReal,                         
                          cpd.qtpiezaspicking,
                          dpe.ampreciounitario,
                          dpe.dsobservacion,
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
                      -- excluyo pesables
                      and nvl(cpd.qtpiezas,0)=0                      
                      --excluyo promo
                      and dpe.icresppromo = 0
                      --excluyo comisionistas
                      and cp.idconsolidadocomi is null
                      and cp.idconsolidadopedido = p_IdPedidos
                 order by 2)--ordeno por articulo para mejorar la distribución
     loop
       --trunc+1 las filas pares si aplica para ajustar las decimales
       If mod(v_Alterna,2)=0 
          and (conformado.qtunidadmedidabasepicking * conformado.porcdist)-round(conformado.qtunidadmedidabasepicking * conformado.porcdist,0)<=0.5 then
           conformado.qtbase:=trunc(conformado.qtunidadmedidabasepicking * conformado.porcdist)+1;
      end if;  
      v_Alterna:=v_Alterna+1;                       
       --verifica si existe disponiblidad para el articulo y se puede insertar en tblslvpedidoconformado
       conformado.qtbase:=Disponibilidad(p_IdPedidos,c_TareaConsolidadoPedido,conformado.cdarticulo,conformado.qtbase,-1);
       if conformado.qtbase > 0 then         
       --calculo la unidad de medida
       v_cdunidadmedida:=PKG_SLV_ARTICULO.GET_UNIDADMEDIDA(conformado.qtbase,conformado.cdarticulo);
        --calculo el nuevo vluxb
       v_vluxb:=PKG_SLV_ARTICULO.GetUXBArticulo(conformado.cdarticulo,v_cdunidadmedida);
       --calculo el nuevo qtunidadpedido
       v_qtunidadpedido:= PKG_SLV_ARTICULO.CONVERTIRUNIDADES(conformado.cdarticulo,conformado.qtbase,'UN',v_cdunidadmedida, 0);
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
                     SecuenciaPedConformado(conformado.idpedido)+1,
                     v_cdunidadmedida,
                     v_qtunidadpedido,
                     conformado.qtbase,
                     conformado.qtpiezaspicking,
                     conformado.ampreciounitario,
                     --multiplica la nueva cantidad base x el amprecio pra el nuevo valor de amlinea
                     conformado.qtbase*conformado.ampreciounitario,
                     v_vluxb,
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
             p_error:='Error. Comuniquese con Sistemas!';
             ROLLBACK;
             RETURN;
           END IF;
       end if;-- fin del if disponibilidad    
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
     p_error:='Error. Comuniquese con Sistemas!';
     ROLLBACK;
     RETURN;
   END IF;
   --cargo la tabla en memoria con los pesables del consolidado pedido
  v_ped:=TempPesablesP(p_IdPedidos);

  --verifica si existen pesables en el pedido y los distribuye
  if v_ped > 1 then
    --verifica si existen pesables en promo, si es así los distribuye 
     if v_qtpiezaspromo > 0 then
         DistribPromoPesableP(p_IdPedidos,p_ok,p_error);
         if p_Ok  = 0 then
           rollback;
           return;
         end if;
     end if;
     DistPesablesP(p_IdPedidos,p_ok,p_error);
     if p_Ok  = 0 then
       rollback;
       return;
     end if;
    end if;
   --verifica si existen promos, si es así las distribuye   
   if v_qtbasepromo > 0 then
         DistribPromoP(p_IdPedidos,p_ok,p_error);
         if p_Ok  = 0 then
           rollback;
           return;
         end if;
   end if;    
   
   --Valida si todos los articulos se distribuyeron correctamente
   ValidaDistribucion(p_IdPedidos,c_TareaConsolidadoPedido,p_Ok,p_error);  
    if p_Ok  = 0 then
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
               p_error:='Error. Comuniquese con Sistemas!';
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

   v_modulo                       varchar2(100) := 'PKG_SLV_DISTRIBUCION.SetDistribucionComi';
   v_error                        varchar2(250);
   v_ped                          Tblslvconsolidadopedido.Idconsolidadopedido%type:= null;
   v_estado                       tblslvconsolidadopedido.cdestado%type:=null;
   v_cdunidadmedida               tblslvpedidoconformado.cdunidadmedida%type;
   v_qtunidadpedido               tblslvpedidoconformado.qtunidadpedido%type;
   v_vluxb                        tblslvpedidoconformado.vluxb%type;
   v_qtbasepromo                  tblslvpordistrib.qtunidadmedidabase%type;
   v_qtpiezaspromo                tblslvpordistrib.qtpiezas%type;
   v_Alterna                      integer:=1;

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
    if v_estado in (C_DistribuidoConsolidadoComi,C_FacturadoConsolidadoComi) then
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
    
   --calcula los porcentajes que se aplicarán en la distribución de consolidados comi
     PorcDistribComi(p_IdComi,v_qtbasepromo,v_qtpiezaspromo,p_Ok,p_error);
     if P_OK = 0 then
      rollback;
       return;
      end if;
    
    --cargo la tabla en memoria con los articulos a distribuir del consolidado comi
    v_ped:=TempDistrib(p_IdComi,c_TareaConsolidadoComi);
    
    --verifico si el consolidado comi no tiene picking
    if v_ped = 0 then
       p_Ok    := 0;
       p_error := 'Error consolidado comisionista N° '||p_IdComi|| 'no tiene artículos a facturar.';
       RETURN;
    end if;

 --inserto la distribución del pedido en tblslvpedidoconformado
 v_error:= 'Error en insert en tblslvpedidoconformado';
 for conformado in(
                  select pe.idpedido,
                          dpe.cdarticulo,
                          ccd.qtunidadmedidabasepicking,
                          pdi.porcdist,
                          round(ccd.qtunidadmedidabasepicking * pdi.porcdist,0)qtbase,
                          ccd.qtpiezaspicking,
                          dpe.ampreciounitario,
                          dpe.dsobservacion,
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
                      -- excluyo pesables
                      and nvl(ccd.qtpiezas,0)=0                     
                      --excluyo promo
                      and dpe.icresppromo = 0
                      and cc.idconsolidadocomi = p_IdComi
                 order by 2)--ordeno por articulo para mejorar la distribución
     loop
         --trunc+1 las filas pares si aplica para ajustar las decimales
         If mod(v_Alterna,2)=0 
            and (conformado.qtunidadmedidabasepicking * conformado.porcdist)-round(conformado.qtunidadmedidabasepicking * conformado.porcdist,0)<=0.5 then
             conformado.qtbase:=trunc(conformado.qtunidadmedidabasepicking * conformado.porcdist)+1;
        end if;  
        v_Alterna:=v_Alterna+1;    
        --verifica si existe disponiblidad para el articulo y se puede insertar en tblslvpedidoconformado
       conformado.qtbase:=Disponibilidad(p_IdComi,c_TareaConsolidadoComi,conformado.cdarticulo,conformado.qtbase,-1);
       if conformado.qtbase > 0 then  
        --calculo la unidad de medida
       v_cdunidadmedida:=PKG_SLV_ARTICULO.GET_UNIDADMEDIDA(conformado.qtbase,conformado.cdarticulo);
        --calculo el nuevo vluxb
       v_vluxb:=PKG_SLV_ARTICULO.GetUXBArticulo(conformado.cdarticulo,v_cdunidadmedida);
       --calculo el nuevo qtunidadpedido
       v_qtunidadpedido:= PKG_SLV_ARTICULO.CONVERTIRUNIDADES(conformado.cdarticulo,conformado.qtbase,'UN',v_cdunidadmedida, 0);
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
                     SecuenciaPedConformado(conformado.idpedido)+1,
                     v_cdunidadmedida,
                     v_qtunidadpedido,
                     conformado.qtbase,
                     conformado.qtpiezaspicking,
                     conformado.ampreciounitario,
                     --multiplica la nueva cantidad base x el amprecio pra el nuevo valor de amlinea
                     conformado.qtbase*conformado.ampreciounitario,
                     v_vluxb,
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
             p_error:='Error. Comuniquese con Sistemas!';
             ROLLBACK;
             RETURN;
           END IF;
       end if; --conformado.qtbase
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
     p_error:='Error. Comuniquese con Sistemas!';
     ROLLBACK;
     RETURN;
   END IF;

  --cargo la tabla en memoria con los pesables del consolidado COMI
  v_ped:=TempPesablesC(p_IdComi);

  --verifica si existen pesables en el pedido y los distribuye
  if v_ped > 1 then
    --verifica si existen pesables en promo, si es así los distribuye  
     if v_qtpiezaspromo > 0 then
         DistribPromoPesableC(p_IdComi,p_ok,p_error);
         if p_Ok  = 0 then
           rollback;
           return;
         end if;
     end if;
     DistPesablesC(p_IdComi,p_ok,p_error);
     if p_Ok  = 0 then
       rollback;
       return;
     end if;     
    end if;
   --verifica si existen promos, si es así las distribuye   
   if v_qtbasepromo > 0 then
         DistribPromoC(p_IdComi,p_ok,p_error);
         if p_Ok  = 0 then
           rollback;
           return;
         end if;
   end if;     

   --Valida si todos los articulos se distribuyeron correctamente
   ValidaDistribucion(p_IdComi,c_TareaConsolidadoComi,p_Ok,p_error);  
    if p_Ok  = 0 then
         rollback;
         return;
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
     p_error:='Error. Comuniquese con Sistemas!';
     ROLLBACK;
     RETURN;
   END IF;
   --Actualizó la tabla tblslvconsolidadopedidodet con los datos del picking del comi
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
                 and cp.idconsolidadocomi = p_IdComi
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
             p_error:='Error. Comuniquese con Sistemas!';
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
           and cp.idconsolidadocomi = p_IdComi;
           IF SQL%ROWCOUNT = 0 THEN
               n_pkg_vitalpos_log_general.write(2,
                                                'Modulo: ' || v_modulo ||
                                                '  Detalle Error: ' || v_error);
               p_Ok    := 0;
               p_error:='Error. Comuniquese con Sistemas!';
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
