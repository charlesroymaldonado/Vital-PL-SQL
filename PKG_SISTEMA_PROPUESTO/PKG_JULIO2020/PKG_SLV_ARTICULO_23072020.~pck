CREATE OR REPLACE PACKAGE PKG_SLV_ARTICULO is
/**********************************************************************************************************
 * Author  : CHARLES MALDONADO
 * Created : 23/01/2020 11:17:03 a.m.
 * %v Paquete para información de articulos de SLV
 **********************************************************************************************************/
 -- Tipos de datos
 TYPE cursor_type IS REF CURSOR;

  --Procedimientos y Funciones
  FUNCTION GetStockArticulos(p_CDArticulo Articulos.CDARTICULO%Type)
                             return int;

  FUNCTION GetUbicacionArticulos(p_CDArticulo Articulos.CDARTICULO%Type)
                                return UBICACIONARTICULOS.CDUBICACION%Type;

  FUNCTION SetFormatoArticulosCod(p_CDArticulo  Articulos.CDARTICULO%Type,
                                  p_qtArticulo  number)
                                  return varchar2;

  PROCEDURE GetcdArticuloxBarras(p_cdeancode    IN   Barras.Cdeancode%type,
                                 p_cdArticulo   OUT  Articulos.CDARTICULO%Type,               
                                 p_cdunidad     OUT  barras.cdunidad%type,
                                 p_cantidad     OUT  tblslvtareadet.qtunidadmedidabase%type);                                                                   

  FUNCTION GetCodigoDeBarra(p_cdArticulo      Articulos.CDARTICULO%Type,
                            p_cdUnidad        UnidadesMedida.CDUNIDAD%Type)
                            return varchar2;

  FUNCTION CalcularPesoUnidadBase (p_CDArticulo Articulos.CDARTICULO%Type,
                                   p_qtArticulo number)
                                   RETURN number;
          
  PROCEDURE GetValidaArticuloBarras(p_cdArticulo   IN   Articulos.CDARTICULO%Type,
                                    p_cdeancode    IN   Barras.Cdeancode%type,
                                    p_cdunidad     OUT  barras.cdunidad%type,
                                    p_cantidad     OUT  tblslvtareadet.qtunidadmedidabase%type);  
                                    
  FUNCTION GetUnidadVentaMinimaArt(p_cdArticulo     Articulos.CDARTICULO%Type)
                                     RETURN char; 
                                                                     
  FUNCTION ConvertirUnidades
    (
        strPLU      IN Articulos.CDArticulo%TYPE,
        Cant        IN NUMBER,
        strUniDesde IN UnidadesMedida.CDUNIDAD%TYPE,
        strUniHasta IN UnidadesMedida.CDUNIDAD%TYPE := NULL,
        intMenorUni IN INTEGER := 0 
    ) RETURN NUMBER;
    
  FUNCTION GET_UNIDADMEDIDA(P_CANT NUMBER, CDARTICULO articulos.cdarticulo%type)
                            RETURN CHAR;
                            
   function GET_UNIDADMEDIDABASE(p_cdarticulo articulos.cdarticulo%type) 
                                 return char;   
   
   FUNCTION GetUXBArticulo(p_cdarticulo in detallepedidos.cdarticulo%TYPE,
                           p_unidadMedida in detallepedidos.cdunidadmedida%TYPE)
                           RETURN NUMBER;                                    
                                
                                                                  
end PKG_SLV_ARTICULO;
/
CREATE OR REPLACE PACKAGE BODY PKG_SLV_ARTICULO is
/***************************************************************************************************
*  %v 23/01/2020  ChM - Parametros globales privados
****************************************************************************************************/
    g_cdSucursal sucursales.cdsucursal%type     := trim(getvlparametro('CDSucursal', 'General'));
    --c_qtDecimales                                CONSTANT number := 2; -- cantidad de decimales para redondeo

 /**************************************************************************************************
* %v 23/01/2020  ChM - obtiene el stock de Articulos de la sucursal en unidades
***************************************************************************************************/
    FUNCTION GetStockArticulos(p_CDArticulo Articulos.CDARTICULO%Type)
            return int IS
        varStock  int;
    BEGIN
        SELECT t.stock
        INTO varStock
            FROM tblctrlstockart t
            WHERE t.cdarticulo = p_CDArticulo;

        RETURN varStock;

        EXCEPTION
                 WHEN NO_DATA_FOUND Then
                RETURN 0;

    END GetStockArticulos;
 /**************************************************************************************************
* %v 23/01/2020  ChM - obtiene ubicacion del articulo en la sucursal
***************************************************************************************************/
    FUNCTION GetUbicacionArticulos(p_CDArticulo Articulos.CDARTICULO%Type)
       return UBICACIONARTICULOS.CDUBICACION%Type IS

    strUbicacion   UBICACIONARTICULOS.CDUBICACION%Type;
    BEGIN
           SELECT cdubicacion
             INTO strUbicacion
             FROM UBICACIONARTICULOS ua
            WHERE ua.CDARTICULO = p_CDArticulo
              AND ua.CDSUCURSAL = g_cdSucursal 
               AND ROWNUM < 2;

            return NVL(strUbicacion,'99S/U');

        EXCEPTION
                 WHEN NO_DATA_FOUND Then
                 return '99S/U';

                 WHEN OTHERS Then
                 return '99S/U';

    END GetUbicacionArticulos;

/**************************************************************************************************
* %v 11/03/2020  ChM - Formatea una cantidad de articulos  con codigo y cantidad en BTO/UN
* %v 26/05/2020  ChM - Agrego validación de pesables
***************************************************************************************************/
    FUNCTION SetFormatoArticulosCod(p_CDArticulo  Articulos.CDARTICULO%Type,
                                    p_qtArticulo  number)
            RETURN varchar2 IS
            V_formato         varchar2(20);
            V_UxB             number;
            v_cdunidad        barras.cdunidad%type;
    BEGIN
     if p_qtArticulo is not null then
       --verifica si la unidad de medida del articulo es un pesable
       begin
       select b.cdunidad 
         into v_cdunidad
         from barras b
        where b.icprincipal = 1
          and b.cdarticulo = p_CDArticulo
          and b.cdunidad in ('KG','PZA')
          and rownum=1;
       exception
         when others then  
            v_cdunidad:='-';
        end;  
        --valida si es pesable devuelve PZA
        if v_cdunidad in ('KG','PZA') then 
          V_formato:= p_qtArticulo||' PZA';
        else  
          V_UxB:=posapp.n_pkg_vitalpos_materiales.GetUxB(p_CDArticulo);
          V_formato:=trunc((p_qtArticulo/V_UxB),0)||' BTO/ '||MOD(p_qtArticulo,V_UxB)||' UN';
        end if;
     else
        V_formato:='-';
     end if;
      RETURN v_formato;

    END SetFormatoArticulosCod;


/**************************************************************************************************
* %v 13/07/2020  ChM - recibe codigo de barras devuelve cdarticulo
*                       devuelve la unidad de medida y su cantidad si es un pesable
***************************************************************************************************/

    PROCEDURE GetcdArticuloxBarras(p_cdeancode    IN   Barras.Cdeancode%type,
                                   p_cdArticulo   OUT  Articulos.CDARTICULO%Type,               
                                   p_cdunidad     OUT  barras.cdunidad%type,
                                   p_cantidad     OUT  tblslvtareadet.qtunidadmedidabase%type)
                                      IS
                                      
       v_codigoBarr        barras.cdeancode%type;
       v_esAuto            integer;
       v_descFr            integer;

    BEGIN
        p_cdunidad:='-';
        p_cantidad:=0;
        p_cdArticulo:='-';
        --limpia el codigo de barras (cdeancode) para buscarlo en la tabla barras
        posapp.pkg_CU.ParsearCodigo(p_cdeancode,p_cantidad,v_codigoBarr,v_esAuto,v_descFr);

        select b.cdunidad,
               b.cdarticulo
          into p_cdunidad,
               p_cdArticulo
          from barras b
         where b.cdeancode =  v_codigoBarr
           and rownum = 1;
        --si no es pesable la cantidad se va en cero
        if p_cdunidad not in ('KG','PZA') then
            p_cantidad:=0;
        end if;    
        EXCEPTION          
           WHEN OTHERS THEN
             p_cdunidad:='-';
             p_cdArticulo:='-';
    END GetcdArticuloxBarras;

/**************************************************************************************************
* %v 17/02/2020  ChM - obtine el codigo de barra de un articulo según su unidad de medida
***************************************************************************************************/

     FUNCTION GetCodigoDeBarra(p_cdArticulo      Articulos.CDARTICULO%Type,
                              p_cdUnidad        UnidadesMedida.CDUNIDAD%Type)
            return varchar2 is --BARRAS.CDEANCODE%TYPE IS

        v_CodigoBarra  varchar2(100); --barras.cdeancode%type;

    BEGIN
        select cdeancode
          into v_codigobarra
          from barras
         where cdarticulo = p_cdArticulo
           and cdunidad = p_cdUnidad
           and icprincipal = 1
           and rownum = 1;

        return nvl(v_CodigoBarra,'-');

        EXCEPTION WHEN NO_DATA_FOUND THEN
          BEGIN
              select b.cdeancode
                into v_codigobarra
                from barras b, unidadesmedida u
               where b.cdarticulo = p_cdArticulo
                 and b.cdunidad = u.cdunidad
                 and u.icmostrarencu = 1
                 and u.cdunidad = p_cdUnidad
                 and rownum = 1
            order by b.icprincipal desc;
              return nvl(v_CodigoBarra,'-');
           EXCEPTION WHEN OTHERS THEN
              return ('-');
         END; 
    END GetCodigoDeBarra;


/**************************************************************************************************
* %v 18/02/2020  ChM - obtine el peso del articulo en kg o litros segun unidad de medida base
***************************************************************************************************/
    FUNCTION CalcularPesoUnidadBase (p_CDArticulo  Articulos.CDARTICULO%Type,
                                     p_qtArticulo  number)
              RETURN number IS

         v_modulo         varchar2(100) := 'PKG_SLV_ARTICULO.CalcularPesoUnidadBase';
         v_largo          unidadesarticulo.vllargo%type;
         v_peso           unidadesarticulo.vlpesoneto%type;
         v_volumen        unidadesarticulo.vlvolumen%type;
         v_ulargo         unidadesarticulo.cdunidadlargo%type;
         v_upeso          unidadesarticulo.cdunidadpeso%type;
         v_uvol           unidadesarticulo.cdunidadvolumen%type;
         v_unidadminima   unidadesarticulo.cdunidad%type;
         v_qtunidadenvase unidadesarticulo.qtunidadesenvase%type;

    BEGIN
     SELECT u.cdunidad,
            u.vllargo,
            u.cdunidadlargo,
            u.vlvolumen,
            u.cdunidadvolumen,
            u.vlpesoneto,
            u.cdunidadpeso,
            u.qtunidadesenvase
       INTO v_unidadminima,
            v_largo,
            v_ulargo,
            v_volumen,
            v_uvol,
            v_peso,
            v_upeso,
            v_qtunidadenvase
       FROM articulos a,
            unidadesarticulo u
      WHERE a.cdarticulo = p_cdarticulo
        AND a.cdarticulo = u.cdarticulo
        AND a.cdunidadventaminima = u.cdunidad;

     -- calculo por peso del contenido
     IF v_peso <> 0 THEN
       IF v_upeso = 'KG' THEN
          RETURN p_qtArticulo*v_peso;
       END IF;
       IF v_upeso = 'G' THEN
          RETURN ((p_qtArticulo*v_peso)/1000);
       END IF;
     END IF;
     -- calculo por volumen del contenido
     IF v_volumen <> 0 THEN
       IF v_uvol = 'L' THEN
          RETURN p_qtArticulo*v_volumen;
       END IF;
     END IF;

     IF v_unidadminima = 'KG' THEN
       -- es pesable, el peso indormado es por KG
       RETURN p_qtArticulo;
     END IF;
      RETURN 0;
     EXCEPTION
       WHEN NO_DATA_FOUND THEN
         RETURN 0;
      WHEN OTHERS THEN
         n_pkg_vitalpos_log_general.write(2, 'Modulo: ' || v_modulo
                                         || '  Error: ' || SQLERRM);
         RETURN 0;
    END CalcularPesoUnidadBase;

/**************************************************************************************************
* %v 20/02/2020  ChM - valida si el codigo de barras corresponde al cdarticulo 
*                       devuelve la unidad de medida y su cantidad si es un pesable
***************************************************************************************************/

    PROCEDURE GetValidaArticuloBarras(p_cdArticulo   IN   Articulos.CDARTICULO%Type,
                                      p_cdeancode    IN   Barras.Cdeancode%type,
                                      p_cdunidad     OUT  barras.cdunidad%type,
                                      p_cantidad     OUT  tblslvtareadet.qtunidadmedidabase%type)
                                      IS
                                      
       v_codigoBarr        barras.cdeancode%type;
       v_esAuto            integer;
       v_descFr            integer;

    BEGIN
        p_cdunidad:='-';
        p_cantidad:=0;
        --limpia el codigo de barras (cdeancode) para buscarlo en la tabla barras
        posapp.pkg_CU.ParsearCodigo(p_cdeancode,p_cantidad,v_codigoBarr,v_esAuto,v_descFr);

        select b.cdunidad
          into p_cdunidad
          from barras b
         where b.cdarticulo = p_cdArticulo
           and b.cdeancode =  v_codigoBarr
          -- and b.icprincipal=1
           and rownum = 1;
        --si no es pesable la cantidad se va en cero
        if p_cdunidad not in ('KG','PZA') then
            p_cantidad:=0;
        end if;    
        EXCEPTION
           WHEN NO_DATA_FOUND THEN
             p_cdunidad:='-';
           WHEN OTHERS THEN
             p_cdunidad:='-';
    END GetValidaArticuloBarras;

  /**************************************************************************************************
* %v 20/07/2020  ChM - valida si la unidad de medida del cdarticulo corresponde a su unidad minima de venta                      
***************************************************************************************************/

    FUNCTION GetUnidadVentaMinimaArt(p_cdArticulo     Articulos.CDARTICULO%Type)
                                     RETURN char   IS
                                      
     V_cdunidad       articulos.cdunidadventaminima%type;
      
    BEGIN
        
        select art.cdunidadventaminima
          into V_cdunidad
          from articulos art              
         where art.cdestadoplu='00' -- articulos activos para venta
           --excluyo no comerciales y las unidades base          
           and art.cdunidadventaminima not in('%','KG','PZA','PAL','UN')   
           and art.cdarticulo = p_cdArticulo
           and rownum=1;       
         return V_cdunidad;  
                  
        EXCEPTION
           WHEN NO_DATA_FOUND THEN
             return '-';
           WHEN OTHERS THEN
             return '-';
    END GetUnidadVentaMinimaArt;  

/**************************************************************************************************
* %v 25/06/2020  ChM - versión inicial ConvertirAUnidades
* %v 25/06/2020  ChM - procedimiento tomado del PKG_SLV_ARTICULOS sin modificación del anterior SLV 
*                      para las unidades a utilizar en TBLSLVPEDIDOCONFORMADO
***************************************************************************************************/

  PROCEDURE ConvertirAUnidades
    (
        r_cursor        OUT cursor_type,
        pCdArticulo    IN Articulos.CDArticulo%TYPE,
        pCdCantidad    IN NUMBER,
        pCdUnidadDesde IN UnidadesMedida.CDUNIDAD%TYPE,
        pCdUnidadHasta IN UnidadesMedida.CDUNIDAD%TYPE := NULL,
        pMenorUnidad   IN INTEGER := 0 -- Si paso 1 quiero obtener la cantidad en la menor Unidad
    ) AS
    BEGIN
        OPEN r_cursor FOR
            SELECT ConvertirUnidades(pCdArticulo,
                                                               pCdCantidad,
                                                               pCdUnidadDesde,
                                                               pCdUnidadHasta,
                                                               pMenorUnidad)
              FROM DUAL;
    END;

/**************************************************************************************************
* %v 25/06/2020  ChM - versión inicial ConvertirUnidades
* %v 25/06/2020  ChM - procedimiento tomado del PKG_SLV_ARTICULOS sin modificación del anterior 
*                      SLV para las unidades a utilizar en TBLSLVPEDIDOCONFORMADO
***************************************************************************************************/

  FUNCTION ConvertirUnidades
    (
        strPLU      IN Articulos.CDArticulo%TYPE,
        Cant        IN NUMBER,
        strUniDesde IN UnidadesMedida.CDUNIDAD%TYPE,
        strUniHasta IN UnidadesMedida.CDUNIDAD%TYPE := NULL,
        intMenorUni IN INTEGER := 0 -- Si paso 1 quiero obtener la cantidad en la menor Unidad
    ) RETURN NUMBER IS

        rv    NUMBER := 0;
        qtDec UnidadesMedida.QTDECIMALES%TYPE;
        tmp   NUMBER := 0;
    BEGIN

        SELECT QTDecimales
          INTO qtDec
          FROM UnidadesMedida
         WHERE CDUnidad = strUniDesde;

        -- Si el qtDecimal es nulo asumo que es igual a 0 (cero)
        IF qtDec IS NULL THEN
            qtDec := 0;
        END IF;

        -- Hago la conversion de la Unidad Desde contra la Unidad de Medida Base
        BEGIN
            SELECT ROUND(Cant * (VlContador / decode(VlDenominador, 0, 1, VlDenominador)),
                         qtDec)
              INTO rv
              FROM UnidadesArticulo
             WHERE CDArticulo = strPLU
               AND CDUnidad = strUniDesde;

            -- Si no Existe el Registro para el Articulo y la Unidad Desde devuelvo 0
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                RETURN 0;
        END;

        -- Si intMenorUni es mayor que 0 (cero) devuelvo la conversion contra la menor Unidad
        IF intMenorUni > 0 THEN
            RETURN rv;
        END IF;

        -- Obtengo la cantidad de Decimales para la Unidad Hasta
        SELECT QTDecimales
          INTO qtDec
          FROM UnidadesMedida
         WHERE CDUnidad = strUniDesde;

        -- Si el qtDecimal es nulo asumo que es igual a 0 (cero)
        IF qtDec IS NULL THEN
            qtDec := 0;
        END IF;

        -- Obtengo el valor de 1 Unidad Hasta en funcion de la Unidad de Medida Base
        tmp := ConvertirUnidades(strPLU,
                                 1,
                                 strUniHasta,
                                 NULL,
                                 1);

         IF tmp = 0 THEN
            tmp := 1;
        END IF;

        rv := ROUND((rv / tmp),
                    qtDec);

        RETURN rv;
    END ConvertirUnidades;
    
/**************************************************************************************************
* %v 25/06/2020  ChM - versión inicial GET_UNIDADMEDIDA
* %v 25/06/2020  ChM - procedimiento tomado del PKG_SLV_ARTICULOS sin modificación del anterior 
*                      SLV para las unidades a utilizar en TBLSLVPEDIDOCONFORMADO
***************************************************************************************************/
    FUNCTION GET_UNIDADMEDIDA(P_CANT NUMBER, CDARTICULO articulos.cdarticulo%type)
      RETURN CHAR IS
       v_modulo         varchar2(100) := 'PKG_SLV_ARTICULO.GET_UNIDADMEDIDA';
       v_umed articulos.cdunidadmedidabase%type:=null;
       v_unidades number;

      BEGIN
      v_unidades:=0;
      v_umed:=GET_UNIDADMEDIDABASE(CDARTICULO);
      if trim(v_umed)='KG' then
        RETURN 'PZA';
      else
        v_unidades:=PKG_SLV_ARTICULO.CONVERTIRUNIDADES(CDARTICULO,
                                                             1,
                                                             'BTO',
                                                             'UN',
                                                             0);
        CASE
          WHEN (P_CANT /v_unidades ) -
               ROUND((P_CANT / v_unidades)) = 0 THEN
            RETURN 'BTO';
          ELSE
            RETURN 'UN';
        END CASE;
    END IF;
      EXCEPTION
        WHEN OTHERS THEN
          n_pkg_vitalpos_log_general.write(2, 'Modulo: ' || v_modulo
                                         || '  Error: ' || SQLERRM);                        
          RAISE;

      END GET_UNIDADMEDIDA;
  
/**************************************************************************************************
* %v 25/06/2020  ChM - versión inicial GET_UNIDADMEDIDABASE
* %v 25/06/2020  ChM - procedimiento tomado del PKG_SLV_ARTICULOS sin modificación del anterior SLV 
*                       para las unidades a utilizar en TBLSLVPEDIDOCONFORMADO
***************************************************************************************************/ 
    function GET_UNIDADMEDIDABASE(p_cdarticulo articulos.cdarticulo%type) return char is
      v_cdUnidad   varchar2(8);
       v_modulo    varchar2(100) := 'PKG_SLV_ARTICULO.GET_UNIDADMEDIDABASE';
    begin
        select cdunidadmedidabase
        into v_cdUnidad
        from articulos
        where articulos.cdarticulo = p_cdarticulo;
      return v_cdUnidad;
    exception
      when others then
       n_pkg_vitalpos_log_general.write(2, 'Modulo: ' || v_modulo
                                         || '  Error: ' || SQLERRM);                      
        raise;
    end GET_UNIDADMEDIDABASE;

/**************************************************************************************************
* %v 25/06/2020  ChM - versión inicial GET_UNIDADMEDIDABASE
* %v 25/06/2020  ChM - procedimiento tomado del PKG_COMIDISTRIB sin modificación del anterior SLV 
*                      para las unidades a utilizar en TBLSLVPEDIDOCONFORMADO
* %v 25/06/2020  ChM - Agrego manejo de exception                    
***************************************************************************************************/ 

    FUNCTION GetUXBArticulo(p_cdarticulo in detallepedidos.cdarticulo%TYPE,
                            p_unidadMedida in detallepedidos.cdunidadmedida%TYPE)RETURN NUMBER IS
     v_uxb number;
     begin
     v_uxb:=0;
      SELECT   to_number(trim(ua.vlcontador),'999999999999.99')
      into v_uxb
                  FROM UnidadesArticulo ua
                 WHERE ua.CDArticulo = p_cdarticulo
                   AND ua.CDUnidad = p_unidadMedida;
     return v_uxb;
     exception
       when others then
        return 0; 
     end GetUXBArticulo;

end PKG_SLV_ARTICULO;
/
