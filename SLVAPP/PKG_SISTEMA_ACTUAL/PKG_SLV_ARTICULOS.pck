CREATE OR REPLACE PACKAGE SLVAPP.PKG_SLV_ARTICULOS AS
/******************************************************************************
      Nombre: PKG_SLV_ARTICULOS
 Descripción: Manejo de todo lo relacionado con articulos

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        05/02/2013   Sergio Ale     versión inicial
******************************************************************************/

 TYPE cursor_type IS REF CURSOR;
 IdEstadoActivo CONSTANT Articulos.cdEstadoPlu%TYPE := '00';

 FUNCTION GetUbicacionArticulos(strArticulo Articulos.CDARTICULO%Type,
            strSucursal Sucursales.CDSUCURSAL%Type) return UBICACIONARTICULOS.CDUBICACION%Type;

 FUNCTION GetStockArticulos(strArticulo Articulos.CDARTICULO%Type/*,
                strSucursal Sucursales.CDSUCURSAL%Type*/) return int;

 PROCEDURE ObtenerStocks  (cur_out OUT cursor_type, pCdSucursal IN Sucursales.CDSucursal%TYPE := NULL );

 PROCEDURE ConvertirAUnidades
    (
        r_cursor        OUT cursor_type,
        pCdArticulo    IN Articulos.CDArticulo%TYPE,
        pCdCantidad    IN NUMBER,
        pCdUnidadDesde IN UnidadesMedida.CDUNIDAD%TYPE,
        pCdUnidadHasta IN UnidadesMedida.CDUNIDAD%TYPE := NULL,
        pMenorUnidad   IN INTEGER := 0 -- Si paso 1 quiero obtener la cantidad en la menor Unidad
    );

 FUNCTION ConvertirUnidades
    (
        strPLU      IN Articulos.CDArticulo%TYPE,
        Cant        IN NUMBER,
        strUniDesde IN UnidadesMedida.CDUNIDAD%TYPE,
        strUniHasta IN UnidadesMedida.CDUNIDAD%TYPE := NULL,
        intMenorUni IN INTEGER := 0 -- Si paso 1 quiero obtener la cantidad en la menor Unidad
    ) RETURN NUMBER;


 FUNCTION GetCodigoDeBarra(strArticulo Articulos.CDARTICULO%Type,
                strUnidadMedida UnidadesMedida.CDUNIDAD%Type)
        return varchar2; -- BARRAS.CDEANCODE%TYPE;
FUNCTION TieneCodBarra(strArticulo Articulos.CDARTICULO%Type)
        return varchar2;


PROCEDURE BuscarArticulo(r_cursor OUT cursor_type,
                         pEanCode IN barras.CDEANCODE%Type);

FUNCTION GET_UNIDADMEDIDA(P_CANT NUMBER, CDARTICULO articulos.cdarticulo%type) RETURN CHAR;

function GET_UNIDADMEDIDABASE(p_cdarticulo articulos.cdarticulo%type) return char;
END PKG_SLV_ARTICULOS;
/
CREATE OR REPLACE PACKAGE BODY SLVAPP.PKG_SLV_ARTICULOS  AS

FUNCTION GetUbicacionArticulos(strArticulo Articulos.CDARTICULO%Type, strSucursal Sucursales.CDSUCURSAL%Type) return UBICACIONARTICULOS.CDUBICACION%Type IS

strUbicacion   UBICACIONARTICULOS.CDUBICACION%Type;

BEGIN
       SELECT cdubicacion
         INTO strUbicacion
         FROM UBICACIONARTICULOS ua
        WHERE ua.CDARTICULO = strArticulo
          AND ua.CDSUCURSAL = strSucursal
          AND ROWNUM < 2;

        return strUbicacion;

    EXCEPTION
             WHEN NO_DATA_FOUND Then
             return '';

END GetUbicacionArticulos;

/**************************************************************************************************
* Devuelve el stock de un artículo en una sucursal
* %v 08/08/2017 - APW - Filtra solo almacén salón
* %v 13/09/2018 - IAquilano - Cambio para que lea desde la VM
***************************************************************************************************/
FUNCTION GetStockArticulos(strArticulo Articulos.CDARTICULO%Type/*,
                strSucursal Sucursales.CDSUCURSAL%Type*/)
        return int IS

    varStock  int;

BEGIN
    SELECT t.stock /*NVL(SUM(St.Stock), 0) STOCK*/
    INTO varStock
        FROM tblctrlstockart t
        where t.cdarticulo = strArticulo;/*Articulos Art,

       (SELECT CdArticulo, aa.QTStock Stock
        FROM ArticulosAlmacen aa, Almacenes al
        WHERE aa.CDSucursal = strSucursal
        AND al.CDAlmacen = aa.CDAlmacen
        AND al.CDSucursal = aa.CDSucursal
        AND aa.CdArticulo = strArticulo
        AND substr(al.cdalmacen,3,2) = '01'
        UNION ALL
        SELECT CdArticulo, sd.QTStock Stock
        FROM StockDiario sd, Almacenes   al
        WHERE sd.CDSucursal = strSucursal
        AND al.CDAlmacen = sd.CDAlmacen
        AND al.CDSucursal = sd.CDSucursal
        AND sd.CdArticulo = strArticulo
        AND substr(al.cdalmacen,3,2) = '01') St
        

    WHERE Art.CdArticulo = St.CdArticulo
    AND Art.CdEstadoPLU = IdEstadoActivo
    AND ART.CDARTICULO = strArticulo;*/

    return varStock;

    EXCEPTION
             WHEN NO_DATA_FOUND Then
             return 0;

END GetStockArticulos;

/**************************************************************************************************
* Devuelve el stock de un artículo en una sucursal
* %v 08/08/2017 - APW - Filtra solo almacén salón
***************************************************************************************************/
PROCEDURE ObtenerStocks
    (
        cur_out     OUT cursor_type,
        pCdSucursal IN Sucursales.CDSucursal%TYPE := NULL
    ) AS
        vSucursal Sucursales.CDSucursal%TYPE;
    BEGIN


        OPEN cur_out FOR
            SELECT Art.CdArticulo,
                   SUM(St.Stock) STOCK
              FROM Articulos Art,
                   (SELECT CdArticulo,
                           aa.QTStock Stock
                      FROM ArticulosAlmacen aa,
                           Almacenes        al
                     WHERE aa.CDSucursal = vSucursal
                       AND al.CDAlmacen = aa.CDAlmacen
                       AND al.CDSucursal = aa.CDSucursal
                       AND substr(al.cdalmacen,3,2) = '01'
                    UNION
                    SELECT CdArticulo,
                           sd.QTStock Stock
                      FROM StockDiario sd,
                           Almacenes   al
                     WHERE sd.CDSucursal = vSucursal
                       AND al.CDAlmacen = sd.CDAlmacen
                       AND al.CDSucursal = sd.CDSucursal
                        AND substr(al.cdalmacen,3,2) = '01'
                        ) St
             WHERE Art.CdArticulo = St.CdArticulo
               AND Art.CdEstadoPLU = IdEstadoActivo
               AND NOT EXISTS (SELECT 1
                      FROM ArticulosNoComerciales
                     WHERE Art.CdArticulo = CdArticulo)
               AND St.Stock > 0
             GROUP BY Art.CdArticulo;
    END;


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


FUNCTION GetCodigoDeBarra(strArticulo Articulos.CDARTICULO%Type,
                strUnidadMedida UnidadesMedida.CDUNIDAD%Type)
        return varchar2 is --BARRAS.CDEANCODE%TYPE IS

    varCodigoBarra  varchar2(100); --barras.cdeancode%type;

BEGIN
    select cdeancode
    into varcodigobarra
    from barras
    where cdarticulo = strarticulo
    and cdunidad = strunidadmedida
    and icprincipal = 1
    and rownum = 1;

    return varCodigoBarra;

    EXCEPTION
             WHEN NO_DATA_FOUND Then
                select b.cdeancode
                into varcodigobarra
                from barras b, unidadesmedida u
                where b.cdarticulo = strarticulo
              --  and cdunidad = 'UN'
                and b.cdunidad = u.cdunidad
                and u.icmostrarencu = 1
                and rownum = 1
                order by b.icprincipal desc;
                return varcodigobarra;

END GetCodigoDeBarra;

FUNCTION TieneCodBarra(strArticulo Articulos.CDARTICULO%Type)
        return varchar2 is --BARRAS.CDEANCODE%TYPE IS

    varCantCodB  integer; --barras.cdeancode%type;

BEGIN
    select count( cdeancode)
    into varCantCodB
    from barras
    where cdarticulo = strarticulo
    and icprincipal = 1;

    return varCantCodB;

    EXCEPTION
             WHEN NO_DATA_FOUND Then
              varCantCodB:=0 ;
    return varCantCodB;

END TieneCodBarra;


PROCEDURE BuscarArticulo(r_cursor OUT cursor_type,
                         pEanCode IN barras.CDEANCODE%Type)
    IS
    BEGIN
        OPEN r_cursor FOR
        SELECT B.CDARTICULO,
               B.CDUNIDAD,
               DA.VLDESCRIPCION,
               B.CDEANCODE
          FROM BARRAS B, DESCRIPCIONESARTICULOS DA
         WHERE B.CDARTICULO = DA.CDARTICULO
           AND B.CDEANCODE = pEanCode;

    END BuscarArticulo;

FUNCTION GET_UNIDADMEDIDA(P_CANT NUMBER, CDARTICULO articulos.cdarticulo%type)
  RETURN CHAR IS

   v_umed articulos.cdunidadmedidabase%type;
   v_unidades number;

  BEGIN
  v_umed:=null;
  v_unidades:=0;
  v_umed:=GET_UNIDADMEDIDABASE(CDARTICULO);
  if trim(v_umed)='KG' then
    RETURN 'PZA';
  else
    v_unidades:=PKG_SLV_ARTICULOS.CONVERTIRUNIDADES(CDARTICULO,
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
      PKG_SLV_COMMON.LOGWRITE('PKG_SLV_ARTICULOS',
                              'GET_UNIDADMEDIDA ERROR:' || SQLERRM);
      RAISE;

  END GET_UNIDADMEDIDA;

function GET_UNIDADMEDIDABASE(p_cdarticulo articulos.cdarticulo%type) return char is
  v_cdUnidad   varchar2(8);

begin
    select cdunidadmedidabase
    into v_cdUnidad
    from articulos
    where articulos.cdarticulo = p_cdarticulo;
  return v_cdUnidad;
exception
  when others then
    pkg_slv_common.logwrite('PKG_SLV_ARTICULOS',
                            'GetUnidadMedida error:' || sqlerrm);
    raise;
end GET_UNIDADMEDIDABASE;

END PKG_SLV_ARTICULOS;
/
