create or replace package PKG_ASIGNA_TELEK_CLIENTE is

  /**********************************************************************************************************
  * Author  : CHARLES ROY MALDONADO DUARTE
  * Created : 11/03/2021 11:00:00 a.m.
  * %v Paquete para la DISTRIBUCION de pedidos con marca de CF de clientes con cuenta a los DNI asignados
  **********************************************************************************************************/
  -- Tipos de datos

  TYPE CURSOR_TYPE IS REF CURSOR;
  --tabla en memoria para la distribución del detalle pedido
   TYPE PED IS RECORD   (
                     IDPEDIDO                VARCHAR2(4000),--LSTADO DE PEDIDOS PADRES
                     CDARTICULO              DETALLEPEDIDOS.CDARTICULO%TYPE, 
                     CDPROMO                 DETALLEPEDIDOS.CDPROMO%TYPE,                         
                     ICRESPPROMO             DETALLEPEDIDOS.ICRESPPROMO%TYPE,   
                     QTBASE                  DETALLEPEDIDOS.QTUNIDADMEDIDABASE%TYPE,
                     QTPIEZAS                DETALLEPEDIDOS.QTPIEZAS%TYPE,
                     PRECIOUNITARIO          DETALLEPEDIDOS.AMPRECIOUNITARIO%TYPE,
                     UXB                     DETALLEPEDIDOS.VLUXB%TYPE,
                     OBSERVACION             OBSERVACIONESPEDIDO.DSOBSERVACION%TYPE,      
                     BANDERA                 INTEGER
                     );

   TYPE     PEDIDO_DIS IS TABLE OF PED INDEX BY BINARY_INTEGER;
   

end PKG_ASIGNA_TELEK_CLIENTE;
/
create or replace package body PKG_ASIGNA_TELEK_CLIENTE is

  /**************************************************************************************************
  *
  * %v 27/04/2021 ChM
  **************************************************************************************************/
  
  --Divido entre 1.21 para descontar del maxino monto el IVA
  --g_MaxMontoDni         number := TO_NUMBER(getvlparametro('MaxMontoDni','General'))/1.21;
 -- g_MaxBTODni           number := 10;--TO_NUMBER(getvlparametro('MaxBTODni','General')); OJO falta definir
--  g_dtOperativa         DATE := N_PKG_VITALPOS_CORE.GetDT();

  /************************************************************************************************************
  * valida si el articulo que recibe es un NON FOOD para excluirlo de BTO 
  * %v 19/03/2021 ChM: v1.0
  ************************************************************************************************************/
   FUNCTION validaNONFOOD ( p_cdarticulo         articulos.cdarticulo%type) 
                            RETURN integer is      
      v_cdarticulo          articulos.cdarticulo%type:=null;
    BEGIN
        select 
      distinct c.cdarticulo
          into v_cdarticulo
          from tblctgryarticulocategorizado c,
               tblctgrysectorc              s
         where c.cdarticulo = p_cdarticulo
           and c.cdsectorc = s.cdserctorc
           and s.dssectorc = 'NON FOOD';
    RETURN 1;    
    EXCEPTION
    WHEN OTHERS THEN      
     RETURN 0;
  END validaNONFOOD;
        

end  PKG_ASIGNA_TELEK_CLIENTE;
/
