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



end PKG_SLV_DISTRIBUCION;
/
CREATE OR REPLACE PACKAGE BODY PKG_SLV_DISTRIBUCION is
  /***************************************************************************************************
  *  %v 29/05/2020  ChM - Parametros globales del paquete
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
  C_AfacturarConsolidadoComi         CONSTANT tblslvestado.cdestado%type := 28;
  C_FacturadoConsolidadoComi         CONSTANT tblslvestado.cdestado%type := 29;

  PROCEDURE AjustarDistribucion(p_IdPedFaltante IN Tblslvpedfaltante.Idpedfaltante%type,
                                 p_Ok            OUT number,
                                 p_error         OUT varchar2);

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
        and dp.cdpromo is not null
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
              -- se cambia A 1 para forzar distribución como promo
              1,
             -- MarcaPromoP(p_idconsolidado,dp.cdarticulo),
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
      p_Ok:=0;
      p_error:='Error. Comuniquese con Sistemas!';
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
       --  solo promociones
       and dp.cdpromo is not null
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
       and di.cdtipo = c_TareaConsolidadoComi
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
      p_Ok:=0;
      p_error:='Error. Comuniquese con Sistemas!';
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
       --  solo promociones
       and dp.cdpromo is not null
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
           tblslvpedfaltante          pf,
           tblslvpedfaltanterel       pfrel,
           tblslvconsolidadopedidodet cpd,
           tblslvpedfaltantedet       pfd
     where cpd.idconsolidadopedido = cp.idconsolidadopedido
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
     p_error:='Existen pedidos ya facturados. Imposible distribuir faltante';
     ROLLBACK;
     RETURN;
    end if;

  --borro porcentajes para el consolidado faltante
  v_error:=' Error en insert tblslvpordistribfaltantes';
  delete TBLSLVPORDISTRIBFALTANTES  pdf
   where pdf.idpedfaltante = p_idconsolidado
     and pdf.cdtipo = c_TareaConsolidaPedidoFaltante;

  insert into tblslvpordistribfaltantes
          (idporcdistribfaltantes,
           idconsolidadopedido,
           idpedfaltante,
           cdtipo,
           cdarticulo,
           artpromo,
           qtunidadmedidabase,
           qtpiezas,
           totalconsolidado,
           porcdist,
           dtinsert)
    select SYS_GUID(),
           A.* 
      from (select to_char(cp.idconsolidadopedido) idconsolidadopedido,
                   pf.idpedfaltante,
                   c_TareaConsolidaPedidoFaltante,
                   cpd.cdarticulo,
                   PKG_SLV_DISTRIBUCION.MarcaPromoF(p_idconsolidado,cpd.cdarticulo),
                   sum(cpd.qtunidadesmedidabase-cpd.qtunidadmedidabasepicking) qtbase,
                   sum(cpd.qtpiezas-cpd.qtpiezaspicking) qtpiezas,
                   PKG_SLV_DISTRIBUCION.TotalArtfaltante(p_idconsolidado,cpd.cdarticulo) totalart,
                   sum(cpd.qtunidadesmedidabase-cpd.qtunidadmedidabasepicking)/
                   PKG_SLV_DISTRIBUCION.TotalArtfaltante(p_idconsolidado,cpd.cdarticulo) porc,
                   sysdate
              from tblslvconsolidadopedido    cp,
                   tblslvpedfaltante          pf,
                   tblslvpedfaltanterel       pfrel,
                   tblslvconsolidadopedidodet cpd,
                   tblslvpedfaltantedet       pfd
             where cpd.idconsolidadopedido = cp.idconsolidadopedido
               and pfrel.idconsolidadopedido = cp.idconsolidadopedido
               and pfrel.idpedfaltante = pf.idpedfaltante
               and pf.idpedfaltante = pfd.idpedfaltante
               and pfd.cdarticulo = cpd.cdarticulo
               and pf.idpedfaltante = p_idconsolidado
          group by cp.idconsolidadopedido,
                   pf.idpedfaltante,
                   cpd.cdarticulo)A
          --valida no insertar artículos que no tienen faltante
          where A.qtbase>0         
          order by A.cdarticulo;

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
      from tblslvpordistribfaltantes di
           --solo promos
     where di.artpromo <> 0
       and di.cdtipo = c_TareaConsolidaPedidoFaltante
       and di.idpedfaltante = p_Idconsolidado;
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
      p_Ok:=0;
      p_error:='Error. Comuniquese con Sistemas!';
      ROLLBACK;

  END PorcDistribFaltantes;

 /****************************************************************************************************
  * %v 29/06/2020 - ChM  Versión inicial TempDistrib
  * %v 29/06/2020 - ChM crea la tabla temporal de los artículos disponibles del consolidado SEGUN TAREA
  *****************************************************************************************************/
   FUNCTION TempDistrib(p_idconsolidado    tblslvconsolidadom.idconsolidadom%type,
                        p_tipotarea          tblslvtipotarea.cdtipo%type
                         ) RETURN NUMBER is

    v_modulo       varchar2(100) := 'PKG_SLV_DISTRIBUCION.TempDistrib';
    v_i            integer:=0;
    v_cdunidad     articulos.cdunidadventaminima%type;
    v_uxb          number;
    v_qtbase       tblslvconsolidadopedidodet.qtunidadmedidabasepicking%type;
    BEGIN
     DISTRIB.DELETE;
     --Creo la tabla en memoria de los artículos disponibles para el idconsolidado pedido
    IF p_tipotarea = c_TareaConsolidadoPedido THEN
    FOR dist IN
            (select cpd.cdarticulo,
                    sum(nvl(cpd.qtunidadmedidabasepicking,0)) qtbase,
                    sum(nvl(cpd.qtpiezaspicking,0)) qtpiezas
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
      v_qtbase:=dist.qtbase;
      --valida unidad minima de venta si es BTO obtiene el UxB y divide la cantidad
      v_cdunidad:= PKG_SLV_ARTICULO.GetUnidadVentaMinimaArt(dist.cdarticulo);
      if trim(v_cdunidad) IN ('BTO','CA') then
         v_uxb:=PKG_SLV_ARTICULO.GetUXBArticulo(dist.cdarticulo,v_cdunidad);
         v_qtbase:=dist.qtbase/v_uxb;
         --valido si la división no es exacta error en picking en unidad minima de venta
         if (v_qtbase-trunc(v_qtbase))<>0 then
           return -1;
         end if;
      end if;
      DISTRIB(v_i).QTUNIDADMEDIDABASEPIK:=v_qtbase;
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
    END IF;
     --Creo la tabla en memoria de los artículos disponibles para el consolidado comisionista
    IF p_tipotarea = c_TareaConsolidadoComi THEN
    FOR dist IN
            (select ccd.cdarticulo,
                    sum(nvl(ccd.qtunidadmedidabasepicking,0)) qtbase,
                    sum(nvl(ccd.qtpiezaspicking,0)) qtpiezas
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
      v_qtbase:=dist.qtbase;
      --valida unidad minima de venta si es BTO obtiene el UxB y divide la cantidad
      v_cdunidad:= PKG_SLV_ARTICULO.GetUnidadVentaMinimaArt(dist.cdarticulo);
      if trim(v_cdunidad) IN ('BTO','CA') then
         v_uxb:=PKG_SLV_ARTICULO.GetUXBArticulo(dist.cdarticulo,v_cdunidad);
         v_qtbase:=dist.qtbase/v_uxb;
         --valido si la división no es exacta error en picking en unidad minima de venta
         if (v_qtbase-trunc(v_qtbase))<>0 then
           return -1;
         end if;
      end if;
      DISTRIB(v_i).QTUNIDADMEDIDABASEPIK:=v_qtbase;
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
      --valida si el comi solo tiene articulos de promo por distribuir
    --las promo no usan DISTRIB pero se deben distribuir
    IF v_i = 0 THEN
      BEGIN
        select COUNT(*)
          into v_i
          from tblslvpordistrib pd
          where pd.idconsolidado = p_idconsolidado
            and pd.cdtipo=c_TareaConsolidadoComi
            -- 1 articulos en promo
            and pd.artpromo = 1;
       EXCEPTION
         WHEN OTHERS THEN
           v_i := 0;
        END;
     END IF;
    RETURN v_i;
    END IF;
     --Creo la tabla en memoria de los artículos disponibles para el consolidado Faltante
    IF p_tipotarea = c_TareaConsolidaPedidoFaltante THEN
    FOR dist IN
            (select pfd.cdarticulo,
                    sum(nvl(pfd.qtunidadmedidabasepicking,0)) qtbase,
                    sum(nvl(pfd.qtpiezaspicking,0)) qtpiezas
               from tblslvpedfaltante               pf,
                    tblslvpedfaltantedet            pfd
              where pf.idpedfaltante = pfd.idpedfaltante
                --valida solo valores piquiados
                and nvl(pfd.qtunidadmedidabasepicking,0)>0
                and pf.idpedfaltante = p_idconsolidado
                --  valida no incluir articulo de promo
                and pfd.cdarticulo not in (select pd.cdarticulo
                                             from tblslvpordistribfaltantes pd
                                            where pd.idpedfaltante = p_idconsolidado
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
      v_qtbase:=dist.qtbase;
      --valida unidad minima de venta si es BTO obtiene el UxB y divide la cantidad
      v_cdunidad:= PKG_SLV_ARTICULO.GetUnidadVentaMinimaArt(dist.cdarticulo);
      if trim(v_cdunidad) IN ('BTO','CA') then
         v_uxb:=PKG_SLV_ARTICULO.GetUXBArticulo(dist.cdarticulo,v_cdunidad);
         v_qtbase:=dist.qtbase/v_uxb;
         --valido si la división no es exacta error en picking en unidad minima de venta
         if (v_qtbase-trunc(v_qtbase))<>0 then
           return -1;
         end if;
      end if;
      DISTRIB(v_i).QTUNIDADMEDIDABASEPIK:=v_qtbase;
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
         --valida si el pedido solo tiene articulos de promo por distribuir
    --las promo no usan DISTRIB pero se deben distribuir
    IF v_i = 0 THEN
      BEGIN
        select COUNT(*)
          into v_i
          from tblslvpordistribfaltantes pd
          where pd.idpedfaltante = p_idconsolidado
            and pd.cdtipo=c_TareaConsolidaPedidoFaltante
            -- 1 articulos en promo
            and pd.artpromo = 1;
       EXCEPTION
         WHEN OTHERS THEN
           v_i := 0;
        END;
     END IF;
    RETURN v_i;
    END IF;
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
                           p_qtpiezas         tblslvconsolidadomdet.qtpiezas%type
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
                                       ||'Pedido: ' ||DISTRIB(v_i).IDCONSOLIDADOPEDIDO
                                       ||'Articulo: '|| DISTRIB(v_i).CDARTICULO
                                       ||'Cantidad PZA: '|| DISTRIB(v_i).QTPIEZASPIK
                                       ||'Cantidad UN: '|| DISTRIB(v_i).QTUNIDADMEDIDABASEPIK
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
                 and re.idpedfaltanterel = pfrel.idpedfaltanterel
                 and re.idremito = red.idremito
                 and cpd.cdarticulo = red.cdarticulo
                 --solo pesables
                 and cpd.qtpiezas<>0
                 --valido solo pesables con picking mayores a cero
                 and cpd.qtpiezaspicking > 0
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
       select distinct
              pe.idpedido,
              dpe.cdarticulo,
              dpe.cdunidadmedida,
              cpd.qtpiezaspicking qtpiezas,
              pdi.porcdist,
              round(cpd.qtpiezaspicking * pdi.porcdist,0) qtpiezaspicking,
              dpe.qtpiezas necesita,
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
     -- ordenados por el que menos le faltó en artículo
     order by dpe.cdarticulo,
              cpd.qtpiezaspicking)--ordeno por articulo para mejorar la distribución
    loop
     --trunc+1 las filas impares si aplica para ajustar las decimales
       If mod(v_Alterna,2)<>0
         and (pes.qtpiezas * pes.porcdist)-trunc(pes.qtpiezas * pes.porcdist)<=0.5 then
              pes.qtpiezaspicking:=trunc(pes.qtpiezas * pes.porcdist)+1;
          --valido si el redondeo sobrepasa lo solicitado ajusto a necesidad
         if pes.qtpiezaspicking > pes.necesita then
            pes.qtpiezaspicking := pes.necesita;
         end if;
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
             ( select distinct
                      frel.idpedfaltanterel,
                      frel.idconsolidadopedido,
                      fd.cdarticulo,
                      fd.qtpiezaspicking qtpiezas,
                      cpd.qtpiezas-cpd.qtpiezaspicking necesita,
                      pdis.porcdist,
                      --aplico el porcentaje a distribuir a los faltantes encontrados y redondeo
                      round(fd.qtpiezaspicking * pdis.porcdist,0) QTDISTB
                 from tblslvpedfaltante          cf,
                      tblslvpedfaltantedet       fd,
                      tblslvpedfaltanterel       frel,
                      tblslvconsolidadopedido    cp,
                      tblslvconsolidadopedidodet cpd,
                      tblslvpordistribfaltantes  pdis
                where cf.idpedfaltante = fd.idpedfaltante
                  and cf.idpedfaltante = fd.idpedfaltante
                  and cp.idconsolidadopedido = cpd.idconsolidadopedido
                  and cf.idpedfaltante = frel.idpedfaltante
                  and frel.idconsolidadopedido = cp.idconsolidadopedido
                  and frel.idpedfaltante = cf.idpedfaltante
                  and pdis.idpedfaltante = cf.idpedfaltante
                  --valida el tipo de tarea de faltante en la tabla distribución
                  and pdis.cdtipo = c_TareaConsolidaPedidoFaltante
                  and pdis.idconsolidadopedido = cp.idconsolidadopedido
                  and pdis.cdarticulo = cpd.cdarticulo
                  -- solo articulos sin promo
                  and pdis.artpromo = 0
                  and fd.cdarticulo = pdis.cdarticulo
                  and cpd.cdarticulo = fd.cdarticulo
                  -- solo pesables
                  and nvl(fd.qtpiezas,0)<>0
                  --con valor pickiado
                  and nvl(fd.qtpiezaspicking, 0) > 0
                  --valida no insertar articulos que no necesitan faltantes
                  and (cpd.qtpiezas-cpd.qtpiezaspicking)>0
                  and cf.idpedfaltante = p_IdPedFaltante
            -- ordenados por el que menos le faltó en artículo y cantidad 
             order by fd.cdarticulo,
                      cpd.qtpiezas-cpd.qtpiezaspicking)--ordeno por articulo para mejorar la distribución
    loop

    --trunc+1 las filas impares si aplica para ajustar las decimales
       If mod(v_Alterna,2)<>0
       and (pes.qtpiezas * pes.porcdist)-trunc(pes.qtpiezas * pes.porcdist)<=0.5 then
            pes.qtdistb:=trunc(pes.qtpiezas * pes.porcdist)+1;
         --valido si el redondeo sobrepasa lo solicitado ajusto a necesidad
         if pes.qtdistb > pes.necesita then
            pes.qtdistb:= pes.necesita;
         end if;
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
       select distinct
              pe.idpedido,
              dpe.cdarticulo,
              dpe.cdunidadmedida,
              ccd.qtpiezaspicking qtpiezas,
              pdi.porcdist,
              round(ccd.qtpiezaspicking * pdi.porcdist,0) qtpiezaspicking,
              dpe.qtpiezas necesita,
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
      -- ordenados por el que menos le faltó en artículo 
     order by dpe.cdarticulo,
              dpe.qtpiezas)--ordeno por articulo para mejorar la distribución
    loop
   --trunc+1 las filas impares si aplica para ajustar las decimales
       If mod(v_Alterna,2)<>0
       and (pes.qtpiezas * pes.porcdist)-trunc(pes.qtpiezas * pes.porcdist)<=0.5 then
            pes.qtpiezaspicking:=trunc(pes.qtpiezas * pes.porcdist)+1;
          --valido si el redondeo sobrepasa lo solicitado ajusto a necesidad
         if pes.qtpiezaspicking > pes.necesita then
            pes.qtpiezaspicking := pes.necesita;
         end if;
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
             select distinct
                    pe.idpedido,
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
                 -- ordenados por el que menos compró en artículo y cantidad solo así funciona esta lógica
           order by dpe.cdarticulo,
                    pdi.qtpiezas)
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
             select distinct
                    pe.idpedido,
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
            -- ordenados por el que menos compró en artículo y cantidad solo así funciona esta lógica
           order by dpe.cdarticulo,
                    pdi.qtunidadmedidabase)

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
             select distinct
                    frel.idpedfaltanterel,
                    fd.cdarticulo,
                    pdis.qtpiezas
               from tblslvpedfaltante          cf,
                    tblslvpedfaltantedet       fd,
                    tblslvpedfaltanterel       frel,
                    tblslvconsolidadopedido    cp,
                    tblslvconsolidadopedidodet cpd,
                    tblslvpordistribfaltantes  pdis
              where cf.idpedfaltante = fd.idpedfaltante
                and cf.idpedfaltante = fd.idpedfaltante
                and cp.idconsolidadopedido = cpd.idconsolidadopedido
                and cf.idpedfaltante = frel.idpedfaltante
                and frel.idconsolidadopedido = cp.idconsolidadopedido
                and frel.idpedfaltante = cf.idpedfaltante
                and pdis.idpedfaltante = cf.idpedfaltante
                --valida el tipo de tarea de faltante en la tabla distribución
                and pdis.cdtipo = c_TareaConsolidaPedidoFaltante
                and pdis.idconsolidadopedido=cp.idconsolidadopedido
                and pdis.cdarticulo = cpd.cdarticulo
                --solo articulos en promo
                and pdis.artpromo <> 0
                and fd.cdarticulo = pdis.cdarticulo
                and cpd.cdarticulo = fd.cdarticulo
                -- solo pesables
                and nvl(fd.qtpiezas,0)<>0
                --con valor pickiado
                and nvl(fd.qtpiezaspicking, 0) > 0
                and cf.idpedfaltante = p_IdPedFaltante
           -- ordenados por el que menos le faltó en artículo y cantidad solo así funciona esta lógica
           order by fd.cdarticulo,
                    pdis.qtpiezas)

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
                       sum(pfd.qtpiezaspicking) qtbase
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
             select distinct
                    frel.idpedfaltanterel,
                    fd.cdarticulo,
                    pdis.qtunidadmedidabase,
                    pdis.qtpiezas
               from tblslvpedfaltante          cf,
                    tblslvpedfaltantedet       fd,
                    tblslvpedfaltanterel       frel,
                    tblslvconsolidadopedido    cp,
                    tblslvconsolidadopedidodet cpd,
                    tblslvpordistribfaltantes  pdis
              where cf.idpedfaltante = fd.idpedfaltante
                and cf.idpedfaltante = fd.idpedfaltante
                and cp.idconsolidadopedido = cpd.idconsolidadopedido
                and cf.idpedfaltante = frel.idpedfaltante
                and frel.idconsolidadopedido = cp.idconsolidadopedido
                and frel.idpedfaltante = cf.idpedfaltante
                and pdis.idpedfaltante = cf.idpedfaltante
                --valida el tipo de tarea de faltante en la tabla distribución
                and pdis.cdtipo = c_TareaConsolidaPedidoFaltante
                and pdis.idconsolidadopedido=cp.idconsolidadopedido
                and pdis.cdarticulo = cpd.cdarticulo
                --solo articulos en promo
                and pdis.artpromo <> 0
                and fd.cdarticulo = pdis.cdarticulo
                and cpd.cdarticulo = fd.cdarticulo
                -- excluyo pesables
                and nvl(fd.qtpiezas,0)=0
                --con valor pickiado
                and nvl(fd.qtunidadmedidabasepicking, 0) > 0
                and cf.idpedfaltante = p_IdPedFaltante
           -- ordenados por el que menos le faltó en artículo y cantidad solo así funciona esta lógica
           order by fd.cdarticulo,
                    pdis.qtunidadmedidabase)

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
             select distinct
                    pe.idpedido,
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
                 -- ordenados por el que menos compró en artículo y cantidad solo así funciona esta lógica
                 order by dpe.cdarticulo,
                          pdi.qtpiezas)
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
             select distinct
                    pe.idpedido,
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
           -- ordenados por el que menos compró en artículo y cantidad solo así funciona esta lógica
           order by dpe.cdarticulo,
                    pdi.qtunidadmedidabase)

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
  * %v 20/07/2020 - ChM  Versión inicial ValidaIndivisibles
  * %v 20/07/2020 - ChM  calcula el total en qtbase de un artículo para un consolidado Comisionista
  *****************************************************************************************************/
  PROCEDURE ValidaIndivisibles(p_CdArticulo   IN     articulos.cdarticulo%type,
                               p_qtbase       IN OUT tblslvconsolidadopedidodet.qtunidadmedidabasepicking%type,
                               p_UxB          OUT    detallepedidos.vluxb%type)
                               is
   v_modulo                        varchar2(100) := 'PKG_SLV_DISTRIBUCION.ValidaIndivisibles';
   v_cdunidad                     articulos.cdunidadventaminima%type;
  -- v_uxb                          number;
  -- v_qtbase                       tblslvconsolidadopedidodet.qtunidadmedidabasepicking%type;

  BEGIN
    p_UxB:=0;
    --valida unidad minima de venta si es BTO obtiene el UxB y divide la cantidad
      v_cdunidad:= PKG_SLV_ARTICULO.GetUnidadVentaMinimaArt(p_CdArticulo);
      if trim(v_cdunidad) IN ('BTO','CA') then
         p_uxb:=PKG_SLV_ARTICULO.GetUXBArticulo(p_CdArticulo,v_cdunidad);
         p_qtbase:=p_qtbase/p_uxb;
         --valido si la división no es exacta error en picking en unidad minima de venta
         if (p_qtbase-trunc(p_qtbase))<>0 then
           n_pkg_vitalpos_log_general.write(2,
                                              'Modulo: ' || v_modulo ||
                                              '  Detalle Error: artículo '||p_CdArticulo||
                                              'indivisible, mal picking división inexacta');
           p_UxB:=-1;
           RETURN;
         end if;
      end if;
  END ValidaIndivisibles;
 /****************************************************************************************************
 * %v 05/06/2020 - ChM  Versión inicial SetDistribucionPedidoFaltante
 * %v 05/06/2020 - ChM  procedimiento para la distribución de los faltantes de pedidos
 * %v 05/06/2020 - ChM  Falta la distribución de pesables y promos además validar redondeos
 * %v 07/08/2020 - ChM  agrego finalizar distribución de faltantes sin datos picking en tblslvpedfantantedet 
 * %v 3/12/2020 - LM  seteo uxb=1 cuando no es indivisible y obligo a dividir por el uxb al buscar el restante
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
   v_conso                         integer:=0;
   --manejo de indivisibles
   v_uxb                          detallepedidos.vluxb%type:=0;

 BEGIN

   begin
     select f.cdestado
       into v_pedfal
       from tblslvpedfaltante f
      where f.idpedfaltante = p_IdPedFaltante;
   exception
     when no_data_found then
       p_Ok    := 0;
       p_error := 'Pedido faltante no existe.';
       RETURN;
   end;
   --verifico si el faltante esta distribuido
    if v_pedfal = C_DistribFaltanteConsolidaPed then
       p_Ok    := 0;
       p_error := 'Pedido faltante ya distribuido.';
       RETURN;
    end if;
   --verifico si el faltante esta finalizado y se puede distribuir
     if v_pedfal <> C_FinalizaFaltaConsolidaPedido then
       p_Ok    := 0;
       p_error := 'Pedido faltante no finalizado. No es posible distribuir.';
       RETURN;
    end if;
    --agrego finalizar distribución de faltantes sin datos picking en tblslvpedfantantedet
    --verifico si el consolidado faltante no tiene picking termina distribución sin error
         begin
           v_conso:=0;
           select count(*)
             into v_conso
             from tblslvpedfaltante pf,
                  tblslvpedfaltantedet pfd
            where pf.idpedfaltante = pfd.idpedfaltante
              and nvl(pfd.qtunidadmedidabasepicking,0)<>0
              and pf.idpedfaltante = p_IdPedFaltante;
         exception
           when no_data_found then
             p_Ok    := 0;
             p_error := 'Pedido faltante no existe.';
             RETURN;
         end;
          if v_conso = 0 then
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
             --cuando el faltante no tenga detalle piquiado
             --actualiza los faltantes a distribuido y termina sin error
             p_Ok    := 1;
             p_error := '';
             RETURN;
          end if;

    --select para validar que el pedido no esta en tblslvdistribucionpedfaltante
      begin
        select count(*)
          into v_pedfal
          from tblslvdistribucionpedfaltante      dfa,
               tblslvpedfaltanterel               frel
         where dfa.idpedfaltanterel = frel.idpedfaltanterel
           and frel.idpedfaltante = p_IdPedFaltante;
      if v_pedfal > 0 then
          p_Ok    := 0;
          p_error := 'Pedido Faltante '||to_char(p_IdPedFaltante)||' ya distribuido';
          return;
      end if;
      exception
        when no_data_found then
         null;
      end;
     v_pedfal:=null;

   --calcula los porcentajes que se aplicarán en la distribución de faltantes
   PorcDistribFaltantes(p_IdPedFaltante,v_qtbasepromo,v_qtpiezaspromo,p_Ok,p_error);
   if P_OK = 0 then
     ROLLBACK;
     RETURN;
    END IF;

     --cargo la tabla en memoria con los articulos a distribuir del consolidado faltante
    v_pedfal:=TempDistrib(p_IdPedFaltante,c_TareaConsolidaPedidoFaltante);

    --valida si hay error en picking de indivisibles
    if v_pedfal = -1 then
       p_Ok    := 0;
       p_error := 'Pedido '||to_char(p_IdPedFaltante)|| ' Tiene error de artículos indivisibles. Comuniquese con sistemas!';
       RETURN;
    end if;

    --verifico si el consolidado faltante no tiene picking
    if v_pedfal = 0 then
       p_Ok    := 0;
       p_error := 'Pedido Faltante '||to_char(p_IdPedFaltante)|| 'no tiene artículos a Distribuir.';
       RETURN;
    end if;

   --inserto la distribución  del faltante
    v_error:= 'Error en insert tblslvdistribucionpedfaltante';
   for falt in
                  (select distinct
                          frel.idpedfaltanterel,
                          frel.idconsolidadopedido,
                          fd.cdarticulo,
                          fd.qtunidadmedidabasepicking,
                          cpd.qtunidadesmedidabase-cpd.qtunidadmedidabasepicking necesita,
                          pdis.porcdist,
                          0 QTDISTB,
                          fd.qtpiezaspicking
                     from tblslvpedfaltante          cf,
                          tblslvpedfaltantedet       fd,
                          tblslvpedfaltanterel       frel,
                          tblslvconsolidadopedido    cp,
                          tblslvconsolidadopedidodet cpd,
                          tblslvpordistribfaltantes  pdis
                    where cf.idpedfaltante = fd.idpedfaltante
                      and cf.idpedfaltante = fd.idpedfaltante
                      and cp.idconsolidadopedido = cpd.idconsolidadopedido
                      and cf.idpedfaltante = frel.idpedfaltante
                      and frel.idconsolidadopedido = cp.idconsolidadopedido
                      and frel.idpedfaltante = cf.idpedfaltante
                      and pdis.idpedfaltante = cf.idpedfaltante
                      -- solo articulos sin promo
                      and pdis.artpromo = 0
                      --valida el tipo de tarea de faltante en la tabla distribución
                      and pdis.cdtipo = c_TareaConsolidaPedidoFaltante
                      and pdis.idconsolidadopedido = cp.idconsolidadopedido
                      and pdis.cdarticulo = cpd.cdarticulo
                      and fd.cdarticulo = pdis.cdarticulo
                      and cpd.cdarticulo = fd.cdarticulo
                      -- excluyo pesables
                      and nvl(fd.qtpiezas,0)=0
                      --con valor pickiado
                      and nvl(fd.qtunidadmedidabasepicking, 0) > 0
                      --valida no insertar articulos que no necesitan faltantes
                      and (cpd.qtunidadesmedidabase-cpd.qtunidadmedidabasepicking)>0
                      and cf.idpedfaltante = p_IdPedFaltante
                 -- ordenados por el que menos le faltó en artículo
                 order by fd.cdarticulo,
                          cpd.qtunidadesmedidabase-cpd.qtunidadmedidabasepicking)--ordeno por articulo para mejorar la distribución
   loop
    --valida unidad minima de venta (Indivisibles)
      ValidaIndivisibles(falt.cdarticulo,falt.qtunidadmedidabasepicking,v_uxb);
      if v_uxb = -1 then
         p_Ok    := 0;
         p_error := 'Pedido '||to_char(p_IdPedFaltante)|| ' Tiene error de artículo '||falt.cdarticulo|| ' indivisible';
         RETURN;
      else --seteo uxb en 1
        if v_uxb=0 then
          v_uxb:=1;
        end if;
      end if;

      -- multiplico por el porcentaje a distribuir
      falt.qtdistb:=round(falt.qtunidadmedidabasepicking*falt.porcdist,0);

    ---trunc+1 las filas impares si aplica para ajustar las decimales
       If mod(v_Alterna,2)<>0
        and (falt.qtunidadmedidabasepicking * falt.porcdist)-trunc(falt.qtunidadmedidabasepicking * falt.porcdist)<=0.5 then
         falt.qtdistb:=trunc(falt.qtunidadmedidabasepicking * falt.porcdist)+1;
         --valido si el redondeo sobrepasa lo solicitado ajusto a necesidad
         --obligo a dividir por el uxb, por los indivisibles. LM
         if falt.qtdistb > (falt.necesita/v_uxb) then
            falt.qtdistb:= (falt.necesita/v_uxb);
         end if;
    end if;
    v_Alterna:=v_Alterna+1;
   --verifica si existe disponiblidad para el articulo y se puede insertar en tblslvdistribucionpedfaltante
   falt.qtdistb:=Disponibilidad(p_IdPedFaltante,c_TareaConsolidaPedidoFaltante,falt.cdarticulo,falt.qtdistb,-1);

   if falt.qtdistb > 0 then

    --multiplica si es necesario el ajuste de los indivisibles
      if v_uxb <> 0 then
         falt.qtdistb:=falt.qtdistb*v_uxb;
      end if;

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
  --verifica la distribución de bultos para redondear decimales en BTO
  --inserta en la tblslvAjusteDistribucion
  AjustarDistribucion(p_IdPedFaltante,p_Ok,p_error);
  if p_Ok  = 0 then
     rollback;
     return;
   end if;

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
    else
     --commit de distribución sin actualizar consolidadopedido ni generar remito
     --asi se puede reversar la distribución si falla.  
      n_pkg_vitalpos_log_general.write(2,
                                      'Modulo: ' || v_modulo ||
                                      '  Detalle Error: Commit distribución exitoso!!' );
      commit;
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
    --valida si la distribucion de faltante sobrepaso lo solicitado error
    begin
    v_conso:=0;
    select count(*)
      into v_conso
      from tblslvconsolidadopedidodet c
     where c.idconsolidadopedido = detpedido.idconsolidadopedido
       and c.cdarticulo = detpedido.cdarticulo
       --cuento si la distribucion intenta pasar del valor solicitado
       and case 
            --valida pesables
            when c.qtpiezas = 0 and nvl(c.qtunidadesmedidabase,0) < nvl(c.qtunidadmedidabasepicking,0) then 1
            when c.qtpiezas <> 0 and nvl(c.qtpiezas,0) < nvl(c.qtpiezaspicking,0) then 1 
              else 0 
            end = 1; 
     if v_conso <> 0  then
        n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                      '  Detalle Error: Articulo: '||detpedido.cdarticulo||
                                      'Pedido: '||detpedido.idconsolidadopedido||
                                      'distribución intenta asignar más de lo solicitado');
         p_Ok    := 0;
         p_error:='Error. Comuniquese con Sistemas!';
         rollback;
         return;
       end if;
    exception
    when others then
      null;
    end;
  end loop;
  v_error:= 'Error en insertar remitos';

  --creo los remitos de distribución de faltantes por los diferentes pedidos distribuidos
   for dist_rem in
       (  select
        distinct df.idpedfaltanterel
            from tblslvdistribucionpedfaltante df,
                 tblslvpedfaltanterel frel
           where df.idpedfaltanterel = frel.idpedfaltanterel
             and frel.idpedfaltante = p_IdPedFaltante
             --validacion necesario por ajuste en nueva distribucion de BTO
             --para no insertar en remito valores en 0
             and df.qtunidadmedidabase>0)
   loop
    p_Ok:=PKG_SLV_REMITOS.SetInsertarRemitoFaltante(dist_rem.idpedfaltanterel);
   end loop;
   if p_Ok = 0 then
     p_Ok    := 0;
     p_error := 'Error. Comuniquese con Sistemas!';
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
 * %v 3/12/2020 - LM  seteo uxb=1 cuando no es indivisible y obligo a dividir por el uxb al buscar el restante
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

   --manejo de indivisibles
   v_uxb                          detallepedidos.vluxb%type:=0;

 BEGIN

   --select para validar que el pedido no es parte de un consolidado faltante sin distribuir
      begin
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
          p_error := 'El pedido '||to_char(p_IdPedidos)||' pertenece al faltante '||to_char(v_pedfal)|| 'sin distribuir';
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
       p_error := 'Pedido '||to_char(p_IdPedidos)||' no existe.';
       RETURN;
   end;
    --verifico si el pedido ya esta Facturado
    if v_estado in (C_AFacturarConsolidadoPedido,C_FacturadoConsolidadoPedido) then
       p_Ok    := 0;
       p_error := 'Pedido '||to_char(p_IdPedidos)||' ya facturado.';
       RETURN;
    end if;
    --verifico si el pedido esta cerrado y se puede distribuir
    if v_estado <> C_CerradoConsolidadoPedido then
       p_Ok    := 0;
       p_error := 'Pedido '||to_char(p_IdPedidos)||' no finalizado. No es posible Facturar.';
       RETURN;
    end if;
    --select para validar que el pedido no esta en tblslvpedidoconformado
      begin
      select count(*)
          into v_pedfal
          from tblslvpedidoconformado       pc,
               tblslvconsolidadopedido      cp,
               tblslvconsolidadopedidorel   cprel,
               pedidos                      pe
         where pe.idpedido = cprel.idpedido
           and cprel.idconsolidadopedido = cp.idconsolidadopedido
           and pc.idpedido = pe.idpedido
           and cp.idconsolidadopedido = p_IdPedidos;
      if v_pedfal > 0 then
          p_Ok    := 0;
          p_error := 'Pedido '||to_char(p_IdPedidos)||' ya distribuido';
          return;
      end if;
      exception
        when no_data_found then
         null;
      end;

   --calcula los porcentajes que se aplicarán en la distribución de pedidos
   PorcDistribConsolidado(p_IdPedidos,v_qtbasepromo,v_qtpiezaspromo,p_Ok,p_error);
   if P_OK = 0 then
     ROLLBACK;
     RETURN;
    END IF;

    --cargo la tabla en memoria con los artículos a distribuir del consolidado pedido
   v_ped:=TempDistrib(p_IdPedidos,c_TareaConsolidadoPedido);

   --valida si hay error en picking de indivisibles
    if v_ped = -1 then
       p_Ok    := 0;
       p_error := 'Pedido '||to_char(p_IdPedidos)|| ' Tiene error de artículos indivisibles. Comuniquese con sistemas!';
       RETURN;
    end if;

   --verifico si el consolidado pedido no tiene picking
    if v_ped = 0 then
       p_Ok    := 0;
       p_error := 'Pedido '||to_char(p_IdPedidos)|| ' no tiene artículos a facturar.';
       RETURN;
    end if;

 --inserto la distribución del pedido en tblslvpedidoconformado
 v_error:= 'Error en insert en tblslvpedidoconformado';
 for conformado in(
                   select distinct
                          pe.idpedido,
                          dpe.cdarticulo,
                          dpe.qtunidadmedidabase necesita,
                          cpd.qtunidadmedidabasepicking,
                          pdi.porcdist,
                          0 qtbase,
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
                 -- ordenados por el que menos le faltó en artículo
                 order by dpe.cdarticulo,
                          dpe.qtunidadmedidabase)--ordeno por articulo para mejorar la distribución
     loop

       --valida unidad minima de venta (Indivisibles)
      ValidaIndivisibles(conformado.cdarticulo,conformado.qtunidadmedidabasepicking,v_uxb);
      if v_uxb = -1 then
         p_Ok    := 0;
         p_error := 'Pedido '||to_char(p_IdPedidos)|| ' Tiene error de artículo '||conformado.cdarticulo|| ' indivisible';
         RETURN;
        else --seteo uxb en 1
        if v_uxb=0 then
          v_uxb:=1;
        end if;  
      end if;

      -- multiplico por el porcentaje a distribuir
      conformado.qtbase:=round(conformado.qtunidadmedidabasepicking *conformado.porcdist,0);

       --trunc+1 las filas impares si aplica para ajustar las decimales
       If mod(v_Alterna,2)<>0
          and (conformado.qtunidadmedidabasepicking * conformado.porcdist)-trunc(conformado.qtunidadmedidabasepicking * conformado.porcdist,0)<=0.5 then
           conformado.qtbase:=trunc(conformado.qtunidadmedidabasepicking * conformado.porcdist)+1;
           --valido si el redondeo sobrepasa lo solicitado ajusto a necesidad
         --obligo a dividir por el uxb, por los indivisibles. LM       
         if conformado.qtbase > (conformado.necesita/v_uxb) then
            conformado.qtbase := (conformado.necesita/v_uxb);
         end if;
      end if;
      v_Alterna:=v_Alterna+1;
       --verifica si existe disponiblidad para el articulo y se puede insertar en tblslvpedidoconformado
       conformado.qtbase:=Disponibilidad(p_IdPedidos,c_TareaConsolidadoPedido,conformado.cdarticulo,conformado.qtbase,-1);

     if conformado.qtbase > 0 then

       --multiplica si es necesario el ajuste de los indivisibles
      if v_uxb <> 0 then
         conformado.qtbase:=conformado.qtbase*v_uxb;
      end if;

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
      --valida si existen diferencias entre consolidadopedidodet y pedidoconformado
      v_ped:=0;
      with conforma  as(select cp.idconsolidadopedido,
                               pcf.cdarticulo,       
                               sum(pcf.qtunidadmedidabase) qtbase,
                               sum(pcf.qtpiezas) qtpiezas
                          from tblslvconsolidadopedido cp,
                               tblslvconsolidadopedidorel prel,
                               tblslvpedidoconformado     pcf
                         where cp.idconsolidadopedido = prel.idconsolidadopedido
                           and pcf.idpedido = prel.idpedido
                           and cp.idconsolidadopedido = p_IdPedidos  
                      group by cp.idconsolidadopedido,
                               pcf.cdarticulo),                         
         consopedido as(select cp.idconsolidadopedido,
                               cpd.cdarticulo,             
                               cpd.qtunidadmedidabasepicking qtbaseP,
                               cpd.qtpiezaspicking qtpiezasP
                          from tblslvconsolidadopedido cp,
                               tblslvconsolidadopedidodet cpd
                         where cp.idconsolidadopedido = cpd.idconsolidadopedido
                           and cp.idconsolidadopedido = p_IdPedidos)
      select count(*)
        into v_ped
        from conforma, 
             consopedido
       where conforma.idconsolidadopedido = consopedido.idconsolidadopedido
         and conforma.cdarticulo = consopedido.cdarticulo 
         and (conforma.qtbase-consopedido.qtbaseP <> 0 or conforma.qtpiezas- consopedido.qtpiezasP <> 0);     
     if v_ped <> 0 then             
        n_pkg_vitalpos_log_general.write(2,
                                      'Modulo: ' || v_modulo ||
                                      '  Detalle Error: ERROR con pedidoconformado!' );
        p_Ok    := 0;
        p_error := 'Error. Comuniquese con Sistemas!';                          
        ROLLBACK;
        RETURN;
     end if; 
     v_ped:=0;
        --valida si existen diferencias entre consolidadopedidodet lo solicitado por el cliente y pedidoconformado 
      with conforma  as(select cp.idconsolidadopedido,
                               pcf.cdarticulo,       
                               sum(pcf.qtunidadmedidabase) qtbase,
                               sum(pcf.qtpiezas) qtpiezas
                          from tblslvconsolidadopedido cp,
                               tblslvconsolidadopedidorel prel,
                               tblslvpedidoconformado     pcf
                         where cp.idconsolidadopedido = prel.idconsolidadopedido
                           and pcf.idpedido = prel.idpedido
                           and cp.idconsolidadopedido = p_IdPedidos  
                      group by cp.idconsolidadopedido,
                               pcf.cdarticulo),                         
         consopedido as(select cp.idconsolidadopedido,
                               cpd.cdarticulo,             
                               cpd.qtunidadesmedidabase qtbaseP,
                               cpd.qtpiezas qtpiezasP
                          from tblslvconsolidadopedido cp,
                               tblslvconsolidadopedidodet cpd
                         where cp.idconsolidadopedido = cpd.idconsolidadopedido
                           and cp.idconsolidadopedido = p_IdPedidos)
      select count(*)
        into v_ped
        from conforma, 
             consopedido
       where conforma.idconsolidadopedido = consopedido.idconsolidadopedido
         and conforma.cdarticulo = consopedido.cdarticulo 
         --verifica si se esta facturando más de lo solicitado por el cliente
         and (conforma.qtbase-consopedido.qtbaseP > 0 or conforma.qtpiezas- consopedido.qtpiezasP > 0);   
          
     if v_ped <> 0 then             
        n_pkg_vitalpos_log_general.write(2,
                                      'Modulo: ' || v_modulo ||
                                      '  Detalle Error: ERROR se esta facturando mas de lo solicitado!' );
        p_Ok    := 0;
        p_error := 'Error. Comuniquese con Sistemas!';                          
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
       p_error := 'Imposible enviar a Facturar el Pedido. Comuniquese con Sistemas!';
       ROLLBACK;
 END SetDistribucionPedidos;

  /****************************************************************************************************
 * %v 19/06/2020 - ChM  Versión inicial SetDistribucionComi
 * %v 19/06/2020 - ChM  procedimiento para la distribución de los pedidos de comisionista 
 * %v 3/12/2020 - LM  seteo uxb=1 cuando no es indivisible y obligo a dividir por el uxb al buscar el restante
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
    --manejo de indivisibles
   v_uxb                          detallepedidos.vluxb%type:=0;

 BEGIN

   begin
     select cc.cdestado
       into v_estado
       from tblslvconsolidadocomi cc
      where cc.idconsolidadocomi = p_IdComi;
   exception
     when no_data_found then
       p_Ok    := 0;
       p_error := 'Pedido comisionista '||to_char(p_IdComi)||' no existe.';
       RETURN;
   end;
    --verifico si el pedido comi ya esta distribuido
    if v_estado in (C_AfacturarConsolidadoComi,C_FacturadoConsolidadoComi) then
       p_Ok    := 0;
       p_error := 'Pedido comisionista '||to_char(p_IdComi)||' ya distribuido.';
       RETURN;
    end if;
   --verifico si el pedido esta cerrado y se puede distribuir
    if v_estado <> C_FinalizadoConsolidadoComi  then
       p_Ok    := 0;
       p_error := 'Pedido comisionista '||to_char(p_IdComi)||' no finalizado. No es posible Facturar.';
       RETURN;
    end if;

      --select para validar que el pedido no esta en tblslvpedidoconformado
      begin
      select count(*)
          into v_ped
          from tblslvpedidoconformado       pc,
               tblslvconsolidadopedido      cp,
               tblslvconsolidadopedidorel   cprel,
               pedidos                      pe
         where pe.idpedido = cprel.idpedido
           and cprel.idconsolidadopedido = cp.idconsolidadopedido
           and pc.idpedido = pe.idpedido
           and cp.idconsolidadocomi = p_IdComi;
      if v_ped > 0 then
          p_Ok    := 0;
          p_error := 'Pedido comisionista '||to_char(p_IdComi)||' ya distribuido';
          return;
      end if;
      exception
        when no_data_found then
         null;
      end;
     v_ped:=null;

   --calcula los porcentajes que se aplicarán en la distribución de consolidados comi
     PorcDistribComi(p_IdComi,v_qtbasepromo,v_qtpiezaspromo,p_Ok,p_error);
     if P_OK = 0 then
      rollback;
       return;
      end if;

    --cargo la tabla en memoria con los articulos a distribuir del consolidado comi
    v_ped:=TempDistrib(p_IdComi,c_TareaConsolidadoComi);

    --valida si hay error en picking de indivisibles
    if v_ped = -1 then
       p_Ok    := 0;
       p_error := 'Pedido '||to_char(p_IdComi)|| ' Tiene error de artículos indivisibles. Comuniquese con sistemas!';
       RETURN;
    end if;

    --verifico si el consolidado comi no tiene picking
    if v_ped = 0 then
       p_Ok    := 0;
       p_error := 'Pedido comisionista '||to_char(p_IdComi)|| 'no tiene artículos a facturar.';
       RETURN;
    end if;

 --inserto la distribución del pedido en tblslvpedidoconformado
 v_error:= 'Error en insert en tblslvpedidoconformado';
 for conformado in(
                   select distinct
                          pe.idpedido,
                          dpe.cdarticulo,
                          ccd.qtunidadmedidabasepicking,
                          dpe.qtunidadmedidabase necesita,
                          pdi.porcdist,
                          0 qtbase,
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
                 -- ordenados por el que menos le faltó en artículo
                 order by dpe.cdarticulo,
                          dpe.qtunidadmedidabase)--ordeno por articulo para mejorar la distribución
     loop

      --valida unidad minima de venta (Indivisibles)
      ValidaIndivisibles(conformado.cdarticulo,conformado.qtunidadmedidabasepicking,v_uxb);
      if v_uxb = -1 then
         p_Ok    := 0;
         p_error := 'Pedido '||to_char(p_IdComi)|| ' Tiene error de artículo '||conformado.cdarticulo|| ' indivisible';
         RETURN;
        else --seteo uxb en 1
        if v_uxb=0 then
          v_uxb:=1;
        end if;  
      end if;

     -- multiplico por el porcentaje a distribuir
      conformado.qtbase:=round(conformado.qtunidadmedidabasepicking *conformado.porcdist,0);

         --trunc+1 las filas impares si aplica para ajustar las decimales
       If mod(v_Alterna,2)<>0
            and (conformado.qtunidadmedidabasepicking * conformado.porcdist)-trunc(conformado.qtunidadmedidabasepicking * conformado.porcdist)<=0.5 then           
             conformado.qtbase:=trunc(conformado.qtunidadmedidabasepicking * conformado.porcdist)+1;
               --valido si el redondeo sobrepasa lo solicitado ajusto a necesidad
         --obligo a dividir por el uxb, por los indivisibles. LM       
         if conformado.qtbase > (conformado.necesita/v_uxb) then
            conformado.qtbase := (conformado.necesita/v_uxb);
         end if;
        end if;
        v_Alterna:=v_Alterna+1;
        --verifica si existe disponiblidad para el articulo y se puede insertar en tblslvpedidoconformado
       conformado.qtbase:=Disponibilidad(p_IdComi,c_TareaConsolidadoComi,conformado.cdarticulo,conformado.qtbase,-1);

       if conformado.qtbase > 0 then

       --multiplica si es necesario el ajuste de los indivisibles
      if v_uxb <> 0 then
         conformado.qtbase:=conformado.qtbase*v_uxb;
      end if;

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

    --Actualizo la tabla tblslvconsolidadocomi a estado C_AfacturarConsolidadoComi
   v_error:= 'Error en update tblslvconsolidadocomi a estado "A facturar"';
   update tblslvconsolidadocomi cc
      set cc.cdestado = C_AfacturarConsolidadoComi,
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
     --valida si existen diferencias entre consolidadopedidodet y pedidoconformado
      v_ped:=0;
      with conforma  as(select cp.idconsolidadopedido,
                               pcf.cdarticulo,       
                               sum(pcf.qtunidadmedidabase) qtbase,
                               sum(pcf.qtpiezas) qtpiezas
                          from tblslvconsolidadopedido cp,
                               tblslvconsolidadopedidorel prel,
                               tblslvpedidoconformado     pcf
                         where cp.idconsolidadopedido = prel.idconsolidadopedido
                           and pcf.idpedido = prel.idpedido
                           and cp.idconsolidadocomi = p_IdComi 
                      group by cp.idconsolidadopedido,
                               pcf.cdarticulo),                         
         consopedido as(select cp.idconsolidadopedido,
                               cpd.cdarticulo,             
                               cpd.qtunidadmedidabasepicking qtbaseP,
                               cpd.qtpiezaspicking qtpiezasP
                          from tblslvconsolidadopedido cp,
                               tblslvconsolidadopedidodet cpd
                         where cp.idconsolidadopedido = cpd.idconsolidadopedido
                           and cp.idconsolidadocomi = p_IdComi)
      select count(*)
        into v_ped
        from conforma, 
             consopedido
       where conforma.idconsolidadopedido = consopedido.idconsolidadopedido
         and conforma.cdarticulo = consopedido.cdarticulo 
         and (conforma.qtbase-consopedido.qtbaseP <> 0 or conforma.qtpiezas- consopedido.qtpiezasP <> 0);     
     if v_ped <> 0 then
        n_pkg_vitalpos_log_general.write(2,
                                      'Modulo: ' || v_modulo ||
                                      '  Detalle Error: ERROR con pedidoconformado!' );
        p_Ok    := 0;
        p_error := 'Error. Comuniquese con Sistemas!';                          
        ROLLBACK;
        RETURN;
     end if;                
     v_ped:=0;
        --valida si existen diferencias entre consolidadopedidodet lo solicitado por el cliente y pedidoconformado        
      with conforma  as(select cp.idconsolidadopedido,
                               pcf.cdarticulo,
                               sum(pcf.qtunidadmedidabase) qtbase,
                               sum(pcf.qtpiezas) qtpiezas
                          from tblslvconsolidadopedido cp,
                               tblslvconsolidadopedidorel prel,
                               tblslvpedidoconformado     pcf
                         where cp.idconsolidadopedido = prel.idconsolidadopedido
                           and pcf.idpedido = prel.idpedido
                           and cp.idconsolidadocomi = p_IdComi
                      group by cp.idconsolidadopedido,
                               pcf.cdarticulo),
         consopedido as(select cp.idconsolidadopedido,
                               cpd.cdarticulo,
                               cpd.qtunidadesmedidabase qtbaseP,--suma lo solicitado
                               cpd.qtpiezas qtpiezasP
                          from tblslvconsolidadopedido cp,
                               tblslvconsolidadopedidodet cpd
                         where cp.idconsolidadopedido = cpd.idconsolidadopedido
                           and cp.idconsolidadocomi = p_IdComi)
      select count(*)
        into v_ped
        from conforma,
             consopedido
       where conforma.idconsolidadopedido = consopedido.idconsolidadopedido
         and conforma.cdarticulo = consopedido.cdarticulo
         --verifica si se esta facturando más de lo solicitado por el cliente
         and (conforma.qtbase-consopedido.qtbaseP > 0 or conforma.qtpiezas- consopedido.qtpiezasP > 0);     
          
     if v_ped <> 0 then             
        n_pkg_vitalpos_log_general.write(2,
                                      'Modulo: ' || v_modulo ||
                                      '  Detalle Error: se esta facturando mas de lo solicitado!' );
        p_Ok    := 0;
        p_error := 'Error. Comuniquese con Sistemas!';                          
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
       p_error := 'Imposible enviar a Facturar el Pedido comisionista. Comuniquese con Sistemas!';
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

  /****************************************************************************************************
  * %v 31/07/2020 - ChM  Versión inicial ReajustarFaltante
  * %v 31/07/2020 - ChM  procedimiento para Reajustar la distribución de Faltante en proporción al UxB
  *****************************************************************************************************/
  PROCEDURE  ReajustarFaltante  (p_IdPedFaltante IN Tblslvpedfaltante.Idpedfaltante%type,
                                 p_cdarticulo    IN Articulos.cdarticulo%type,
                                 p_Ok            OUT number,
                                 p_error         OUT varchar2) IS

  v_modulo                       varchar2(100) := 'PKG_SLV_DISTRIBUCION.ReajustarFaltante';
  v_error                        varchar2(250);
  v_diferencia                   tblslvdistribucionpedfaltante.qtunidadmedidabase%type:=0;
  v_uxb                          number;
  v_cantidad                     tblslvdistribucionpedfaltante.qtunidadmedidabase%type:=0;
  BEGIN
    --UxB del articulo
   v_uxb:=PKG_SLV_ARTICULO.GetUXBArticulo(p_cdarticulo,'BTO');

    --valida si UxB es menor o igual a 1 nada que ajustar
    if  v_uxb <=1 then
      p_ok:=1;
      p_error:=null;
      return;
    end if;

    --suma el total de la diferencia que se debe ajustar
    select sum(nd.qtundbasediferencia)
      into v_diferencia
      from tblslvAjusteDistribucion nd
     where nd.cdarticulo=p_cdarticulo
       and nd.idpedfaltante = p_IdPedFaltante;

    --valida si la diferencia es 0 nada que ajustar
    if v_diferencia = 0 then
      p_ok:=1;
      p_error:=null;
      return;
    end if;

     --valida si la diferencia total es menor al UxB salir sin ajustar
    if v_diferencia < v_uxb then
      p_ok:=1;
      p_error:=null;
      return;
    end if;
    --proceso de reajuste de distribución
    for ajuste in
       (select nd.iddistribucionpedfaltante,
               nd.qtnecesita
          from tblslvAjusteDistribucion nd
         where nd.cdarticulo = p_cdarticulo
           and nd.idpedfaltante = p_IdPedFaltante
          --ordenado de mayor a menor para favorecer al que menos pidio
          order by nd.qtunidadbasenueva
           )
    loop
      --rompe el ciclo sino hay diferencias a distribuir
      EXIT WHEN v_diferencia <= 0;
      --verifica si el articulo necesita
      --(sino necesita no se puede ajustar nada; el faltante completó el pedido)
      if ajuste.qtnecesita> 0 then
          --verifica si la diferencia a distribuir alcanza para la necesidad
          if v_diferencia-ajuste.qtnecesita>0 then
             v_cantidad:=ajuste.qtnecesita;
             v_diferencia:=v_diferencia-ajuste.qtnecesita;
          else
             v_cantidad:=v_diferencia;
             v_diferencia:=0;
          end if;
          --actualiza la cantidad en el articulo del renglon de la distribución
          v_error:='Error Actualizando tblslvAjusteDistribucion';
          update tblslvAjusteDistribucion nd
             set nd.qtunidadbasenueva = nd.qtunidadbasenueva+v_cantidad
           where nd.cdarticulo = p_cdarticulo
             and nd.iddistribucionpedfaltante = ajuste.iddistribucionpedfaltante
             and nd.idpedfaltante = p_IdPedFaltante;
          IF SQL%ROWCOUNT = 0 THEN
               n_pkg_vitalpos_log_general.write(2,
                                                'Modulo: ' || v_modulo ||
                                                '  Detalle Error: ' || v_error);
               p_Ok    := 0;
               p_error:='Error. Comuniquese con Sistemas!';
               ROLLBACK;
               RETURN;
           END IF;
           --marca el ajuste del articulo para la nueva distribución
            v_error:='Error Actualizando tblslvAjusteDistribucion marca de ajuste';
          update tblslvAjusteDistribucion nd
             set nd.icnuevadistribucion = 1,
                 nd.dtupdate = sysdate
           where nd.cdarticulo = p_cdarticulo
             and nd.idpedfaltante = p_IdPedFaltante;
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
     --Actuliza la nueva distribución en tblslvdistribucionpedfaltante
    for nueva in
       (select nd.iddistribucionpedfaltante,
               nd.cdarticulo,
               nd.qtunidadbasenueva
          from tblslvAjusteDistribucion nd
          --solo actualizo las ajustadas en la nueva distribución
         where nd.icnuevadistribucion = 1
           and nd.cdarticulo = p_cdarticulo
           and nd.idpedfaltante = p_IdPedFaltante)
     loop
         v_error:='Error Actualizando tblslvdistribucionpedfaltante';
          update tblslvdistribucionpedfaltante dpf
             set dpf.qtunidadmedidabase=nueva.qtunidadbasenueva
           where dpf.iddistribucionpedfaltante = nueva.iddistribucionpedfaltante
             and dpf.cdarticulo = nueva.cdarticulo;
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

   p_Ok    := 1;
   p_error := '';
   EXCEPTION
     WHEN OTHERS THEN
       n_pkg_vitalpos_log_general.write(2,
                                        'Modulo: ' || v_modulo ||
                                        '  Detalle Error: ' || v_error ||
                                        '  Error: ' || SQLERRM);
       p_Ok    := 0;
       p_error := 'Error. Comuniquese con Sistemas!';
       ROLLBACK;
  END ReajustarFaltante;

/****************************************************************************************************
  * %v 03/08/2020 - ChM  Versión inicial AjustarDistribucion
  * %v 03/08/2020 - ChM  procedimiento para insertar en tblslvAjusteDistribucion creada
  *                      para el ajuste de los BTO en la distribución de faltantes
  *****************************************************************************************************/
  PROCEDURE AjustarDistribucion(p_IdPedFaltante IN Tblslvpedfaltante.Idpedfaltante%type,
                              p_Ok            OUT number,
                              p_error         OUT varchar2) IS

   v_modulo                       varchar2(100) := 'PKG_SLV_DISTRIBUCION.AjustarDistribucion';
   v_error                        varchar2(250);

  BEGIN
    v_error:='Error insert tblslvAjusteDistribucion ';
    insert into tblslvAjusteDistribucion nd
             (nd.idpedfaltante,
              nd.iddistribucionpedfaltante,
              nd.cdarticulo,
              nd.qtunidadmedidabase,
              nd.qtnecesita,
              nd.qtuxb,
              nd.qtbto,
              nd.qtunidadbasenueva,
              nd.icnuevadistribucion,
              nd.qtundbasediferencia,
              nd.dtinsert,
              nd.dtupdate)
              select A.idpedfaltante,
                     A.iddistribucionpedfaltante,
                     A.cdarticulo,
                     A.qtunidadmedidabase,
                     A.necesita,
                     A.UxB,
                     A.BTO,
                     A.UxB*A.BTO UNIDADES,
                     0 icAjustarDistribucion,
                     A.qtunidadmedidabase-(A.BTO* A.UxB) DIFERENCIA,
                     sysdate,
                     null
                      from
                         (select pf.idpedfaltante,
                                 dtf.iddistribucionpedfaltante,
                                 dtf.cdarticulo,
                                 dtf.qtunidadmedidabase,
                                 cpd.qtunidadesmedidabase-nvl(cpd.qtunidadmedidabasepicking,0) necesita,
                                 PKG_SLV_ARTICULO.GetUXBArticulo(dtf.cdarticulo,'BTO') UxB,
                                 TRUNC(dtf.qtunidadmedidabase/
                                 --manejo el error de division por cero
                                 DECODE(PKG_SLV_ARTICULO.GetUXBArticulo(dtf.cdarticulo,'BTO'),0
                                 ,-1,PKG_SLV_ARTICULO.GetUXBArticulo(dtf.cdarticulo,'BTO'))) BTO
                            from tblslvdistribucionpedfaltante dtf,
                                 tblslvpedfaltanterel          frel,
                                 tblslvpedfaltante             pf,
                                 tblslvconsolidadopedido       cp,
                                 tblslvconsolidadopedidodet    cpd
                           where pf.idpedfaltante = frel.idpedfaltante
                             and frel.idpedfaltanterel = dtf.idpedfaltanterel
                             and cp.idconsolidadopedido = frel.idconsolidadopedido
                             and cp.idconsolidadopedido = cpd.idconsolidadopedido
                             and dtf.cdarticulo = cpd.cdarticulo
                             --excluyo pesables
                             and nvl(dtf.qtpiezas,0)=0
                             --excluyo articulos en promocion
                             and dtf.cdarticulo not in (select pd.cdarticulo
                                                          from tblslvpordistribfaltantes pd
                                                         where pd.idpedfaltante=p_IdPedFaltante
                                                           and pd.cdtipo=c_TareaConsolidaPedidoFaltante
                                                           and pd.artpromo = 1)
                             and pf.idpedfaltante = p_IdPedFaltante) A
                            order by A.cdarticulo;

--sino inserta nada, no hay nada que ajustar. Termina el proceso OK!
 IF SQL%ROWCOUNT = 0 THEN
       p_Ok    := 1;
       p_error := '';
       RETURN;
   END IF;
   --ajusta los BTO por artículo en la nueva distribución
   for ajustar in
     (select distinct nd.cdarticulo
        from tblslvAjusteDistribucion nd
       where nd.idpedfaltante = p_IdPedFaltante)
   loop
     ReajustarFaltante(p_IdPedFaltante,ajustar.cdarticulo,p_Ok,p_error);
     if p_Ok  = 0 then
         rollback;
         return;
       end if;
     end loop;

   p_Ok    := 1;
   p_error := '';
   EXCEPTION
     WHEN OTHERS THEN
       n_pkg_vitalpos_log_general.write(2,
                                        'Modulo: ' || v_modulo ||
                                        '  Detalle Error: ' || v_error ||
                                        '  Error: ' || SQLERRM);
       p_Ok    := 0;
       p_error := 'Error. Comuniquese con Sistemas!';
       ROLLBACK;
  END AjustarDistribucion;


end PKG_SLV_DISTRIBUCION;
/
