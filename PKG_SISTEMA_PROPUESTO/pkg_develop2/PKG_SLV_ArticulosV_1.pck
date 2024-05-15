create or replace package PKG_SLV_Articulos is
/**********************************************************************************************************
 * Author  : CMALDONADO_C
 * Created : 23/01/2020 11:17:03 a.m.
 * %v Paquete para información de articulos de SLV
 **********************************************************************************************************/
 -- Tipos de datos


  --Procedimientos y Funciones
  FUNCTION GetStockArticulos(p_CDArticulo Articulos.CDARTICULO%Type)return int;
  
  FUNCTION GetUbicacionArticulos(p_CDArticulo Articulos.CDARTICULO%Type)
    return UBICACIONARTICULOS.CDUBICACION%Type;
    
  FUNCTION SetFormatoArticulos(p_CDArticulo Articulos.CDARTICULO%Type,p_qtArticulo number)
    return varchar2; 
     
  FUNCTION GetCodigoDeBarra(strArticulo     Articulos.CDARTICULO%Type,
                          strUnidadMedida   UnidadesMedida.CDUNIDAD%Type)
   return varchar2;

end PKG_SLV_ARTICULOS;
/
create or replace package body PKG_SLV_Articulos is
/***************************************************************************************************
*  %v 23/01/2020  ChM - Parametros globales privados
****************************************************************************************************/
g_cdSucursal sucursales.cdsucursal%type     := '0013';--trim(getvlparametro('CDSucursal', 'General'));
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
          AND ua.CDSUCURSAL = g_cdSucursal;
       --   AND ROWNUM < 2;

        return strUbicacion;

    EXCEPTION
             WHEN NO_DATA_FOUND Then
             return '';

END GetUbicacionArticulos;
/**************************************************************************************************
* %v 23/01/2020  ChM - Formatea una cantidad de articulos en BTO/UN
***************************************************************************************************/
FUNCTION SetFormatoArticulos(p_CDArticulo Articulos.CDARTICULO%Type,p_qtArticulo number)
        RETURN varchar2 IS
        V_formato         varchar2(20);
        V_UxB             number;
BEGIN
  V_UxB:=posapp.n_pkg_vitalpos_materiales.GetUxB(p_CDArticulo);
  V_formato:=trunc((p_qtArticulo/V_UxB),0)||' BTO/ '||MOD(p_qtArticulo,V_UxB)||' UN';
  RETURN v_formato;

END SetFormatoArticulos;

/**************************************************************************************************
* %v 17/02/2020  ChM - obtine el codigo de barra de un articulo según su unidad de medida
***************************************************************************************************/

FUNCTION GetCodigoDeBarra(strArticulo      Articulos.CDARTICULO%Type,
                          strUnidadMedida  UnidadesMedida.CDUNIDAD%Type)
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

    EXCEPTION WHEN NO_DATA_FOUND THEN
      select b.cdeancode
        into varcodigobarra
        from barras b, unidadesmedida u
       where b.cdarticulo = strarticulo
         and b.cdunidad = u.cdunidad
         and u.icmostrarencu = 1
         and rownum = 1
    order by b.icprincipal desc;
      return varcodigobarra;
END GetCodigoDeBarra;



end PKG_SLV_ARTICULOS;
/
