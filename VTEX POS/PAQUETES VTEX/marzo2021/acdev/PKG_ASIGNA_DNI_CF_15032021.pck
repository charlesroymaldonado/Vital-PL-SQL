create or replace package PKG_ASIGNA_DNI_CF is

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
                     PRECIO                  DETALLEPEDIDOS.AMPRECIOUNITARIO%TYPE,
                     UXB                     DETALLEPEDIDOS.VLUXB%TYPE,
                     OBSERVACION             OBSERVACIONESPEDIDO.DSOBSERVACION%TYPE,      
                     BANDERA                 INTEGER
                     );

   TYPE     PEDIDO_DIS IS TABLE OF PED INDEX BY BINARY_INTEGER;
   
   DISTRIB        PEDIDO_DIS;
   
   FUNCTION Dividir_Pedido_DNICF( p_cdcuit          entidades.cdcuit%TYPE,
                  	              p_dtPedido        pedidos.dtaplicacion%TYPE,
                                  p_cdTipoDireccion pedidos.cdtipodireccion%TYPE,
                                  p_sqDireccion     pedidos.sqdireccion%TYPE) RETURN INTEGER;
   

end PKG_ASIGNA_DNI_CF;
/
create or replace package body PKG_ASIGNA_DNI_CF is

  /**************************************************************************************************
  * Este PKG se encarga de CU 01 Dividir Pedidos de Clientes B2B con cuenta a CF.
      Versión: 1.1 11/03/2021
      Dependencias:	Emisión de pedidos de venta móvil, telemarketing, Vital Digital y VTEX.
      Precondición:  Debe existir un parámetro de base de datos que define el monto máximo 
                     de facturación mensual por DNI de consumidor final (CF).
                     Existirá un parámetro de base de datos (BD) que define la cantidad de bultos (BTO)
                     máxima diaria por material que puede adquirir un DNI de CF.
                     El RAC Vital asignará el listado de DNIs disponibles, asociados al cliente con cuenta 
                     al que se facturará como CF.
                     Revisar y aplicar las exclusiones de control de bultos de grupos de artículos. 
                     Revisar la exclusión de artículo electro en el PKG_CU de la sucursal para aplicarla.
                     No separar los artículos en promoción de los pedidos analizados.
      Descripción:  El sistema debe distribuir todos los pedidos marcados a CF de un cliente con cuenta 
                    que reciba para procesar. Esto se asignará según listado de DNI disponibles para el 
                    cliente, con la restricción de no sobrepasar el monto máximo mensual ni la cantidad 
                    de bultos diaria por material de cada DNI, además se respeta la no separación de 
                    artículos en promoción. 
      Secuencia Normal:  Paso  Acción
                          1  En el pkg_pedido_central.ValidarPedidos se procesarán todos los pedidos 
                             de los distintos canales VE,TE,CO de perdidos de CF en icestadosistema (0,-1,19 y 20)
                          2  El sistema recibe el CUIT, fecha y datos de dirección del cliente e inicia 
                             el proceso de cálculo. 
                          3  El proceso genera un listado de los artículos disponibles en los pedidos marcado como CF 
                             asociados al cliente ingresado.
                          4  Se listan los DNI del cliente con el saldo mensual  disponible de cada uno, para 
                             la asociación de pedidos a CF.
                          5  Según disponibilidad de saldo se asocian los artículos a cada DNI disponible del cliente.
                          6  Por cada material que se agrega se valida no sobrepasar la cantidad diaria de BTO 
                             según parámetro, tomando en cuenta para este cálculo todos los pedidos por procesar 
                             o en la cola de ese día para el DNI que se asociará.
                          7  El sistema crea nuevos pedidos con la división necesaria para la distribución de CF 
                             y marca los pedidos iniciales para que no viajen a la sucursal. 
                             El resultado de los nuevos pedidos no guardará relación con los pedidos originales.
      Post condición:  Si el sistema por restricciones no logra asignar el total de los pedidos del cliente el RAC 
                       deberá asignar más DNI.
      Excepciones:  Si el sistema por restricciones no logra asignar el total de los pedidos del cliente por monto 
                    máximo marca en estado 19 todos los pedidos analizados; para el caso por cantidad de BTO 
                    sobrepasada estado 20.
                    El pedido puede ser cambiado a compra como cliente con cuenta por parte de crédito.
      Comentarios:  El monto máximo a CF mensual es: 50.000 $
                    La cantidad de bultos y unidades diarias por material es: 15 
                     El número de DNI disponibles es variable y está definido por el RAC de la sucursal que 
                     atiende al cliente. 
  * %v 11/03/2021 ChM
  **************************************************************************************************/
  
  --Divido entre 1.21 para descontar del maxino monto el IVA
  g_MaxMontoDni         number := TO_NUMBER(getvlparametro('MaxMontoDni','General'))/1.21;
  g_MaxBTODni           number := 15;--TO_NUMBER(getvlparametro('MaxMontoDni','General'))/1.21; OJO falta definir
  
  /****************************************************************************************************
  * %v 12/03/2021 - ChM  Versión inicial TempDistrib
  * %v 12/03/2021 - ChM crea la tabla temporal de los artículos disponibles de los pedidos a asignar DNI
  *****************************************************************************************************/
   FUNCTION TempDistrib(p_cdcuit          entidades.cdcuit%TYPE,
                  	    p_dtPedido        pedidos.dtaplicacion%TYPE,
                        p_cdTipoDireccion pedidos.cdtipodireccion%TYPE,
                        p_sqDireccion     pedidos.sqdireccion%TYPE) RETURN NUMBER is

    v_modulo       varchar2(100) := 'PKG_ASIGNA_DNI_CF.TempDistrib';  
    
    CURSOR DET (p_cdcuit          entidades.cdcuit%TYPE,
                p_dtPedido        pedidos.dtaplicacion%TYPE,
                p_cdTipoDireccion pedidos.cdtipodireccion%TYPE,
                p_sqDireccion     pedidos.sqdireccion%TYPE)IS
                
          SELECT dp.idpedido,
                 dp.cdarticulo,
                 dp.cdpromo,
                 dp.icresppromo,
                 sum(dp.qtunidadmedidabase) qtbase,
                 sum(dp.qtpiezas) qtpiezas,
                 avg(dp.ampreciounitario) preciounitario, 
                 n_pkg_vitalpos_materiales.GetUxB(dp.cdarticulo) UXB,
                 op.dsobservacion,
                 0 bandera                
            FROM pedidos                 pe
                 left join (observacionespedido     op) 
                 on (pe.idpedido = op.idpedido),
                 documentos              do,
                 tx_pedidos_insert       tx,
                 detallepedidos          dp                 
           WHERE pe.iddoctrx = do.iddoctrx             
             AND TRUNC(pe.dtaplicacion) = p_dtPedido    --11/12/2020
             AND pe.cdtipodireccion = p_cdTipoDireccion -- para prueba 1
             AND pe.sqdireccion = p_sqDireccion         -- para prueba 4
             AND tx.cdcuit = p_cdcuit                   --20-94031884-0  
             AND pe.idpedido = tx.idpedido
             AND pe.idpedido = dp.idpedido
             --solo artículos sin promo
             AND dp.cdpromo is null
             --excluyo linea de promo
             AND dp.icresppromo = 0             
             --SOLO pedidos no validados o en estado 19 y 20
             AND pe.icestadosistema in (0,-1,19,20)
        GROUP BY dp.idpedido,
                 dp.cdarticulo,
                 dp.cdpromo,
                 dp.icresppromo,
                 op.dsobservacion              
        ORDER BY 2;   
  BEGIN
      
     DISTRIB.DELETE;
     --Creo la tabla en memoria de los artículos disponibles DE LOS PEDIDOS
     OPEN DET(p_cdcuit,p_dtPedido,p_cdTipoDireccion,p_sqDireccion);
     FETCH DET BULK COLLECT INTO DISTRIB;      --cargo el cursor en la tabla en memoria
     CLOSE DET;
     
     RETURN 1;
  EXCEPTION
      WHEN OTHERS THEN
        n_pkg_vitalpos_log_general.write(2,
                                         'Modulo: ' || v_modulo ||
                                         '  Error: ' || SQLERRM);
        RETURN 0;

  END TempDistrib;
  
  /************************************************************************************************************
  * devuelve el saldo disponible para un cliente que recibe durante el mes de en curso 
  * tomando en cuenta las excepciones de articulos
  * %v 15/03/2021 ChM: v1.0
  ************************************************************************************************************/
   FUNCTION SaldoDNICF ( p_iddatoscli         tblacumdnireparto.iddatoscli%type) 
                         RETURN tblacumdnireparto.amdocumento%type is
      v_Modulo    VARCHAR2(100) := 'PKG_ASIGNA_DNI_CF.SaldoDNICF';
    BEGIN
    
    NULL;
    COMMIT;
    RETURN 1;    
    EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_Modulo || ' Error: ' ||
                                       SQLERRM);
     ROLLBACK;
     RETURN 0;
  END SaldoDNICF;
    
  /************************************************************************************************************
  * devuelve la cantidad de bultos disponibles del DNI y articulo que recibe durante el día analizado
  * tomando en cuenta las excepciones de articulos
  * %v 15/03/2021 ChM: v1.0
  ************************************************************************************************************/
   FUNCTION BTOXArticuloDNICF ( p_iddatoscli         tblacumdnireparto.iddatoscli%type,
                                p_cdarticulo         articulos.cdarticulo%type) 
                                RETURN number is
      v_Modulo    VARCHAR2(100) := 'PKG_ASIGNA_DNI_CF.BTOXArticuloDNICF';
    BEGIN
    
    NULL;
    COMMIT;
    RETURN 1;    
    EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_Modulo || ' Error: ' ||
                                       SQLERRM);
     ROLLBACK;
     RETURN 0;
  END BTOXArticuloDNICF;
    
  /************************************************************************************************************
  * divide y asigna DNI disponibles para consumidores finales en clientes de pedidos de reparto y comi con cuenta
  * %v 12/03/2021 ChM: v1.0
  ************************************************************************************************************/
  FUNCTION  Dividir_Pedido_DNICF ( p_cdcuit          entidades.cdcuit%TYPE,
                  	               p_dtPedido        pedidos.dtaplicacion%TYPE,
                                   p_cdTipoDireccion pedidos.cdtipodireccion%TYPE,
                                   p_sqDireccion     pedidos.sqdireccion%TYPE) RETURN INTEGER IS

    v_Modulo    VARCHAR2(100) := 'PKG_ASIGNA_DNI_CF.Dividir_Pedido_DNICF';
    v_dtDesde   date;
    v_dtHasta   date;
    v_monto     tblacumdnireparto.amdocumento%type:=0;
    PRAGMA AUTONOMOUS_TRANSACTION;
  BEGIN
    --rango ultimo mes
    v_dtDesde := trunc(sysdate,'mm');
    v_dtHasta := to_date(to_char(sysdate, 'dd/mm/yyyy') || ' 23:59:59','dd/mm/yyyy hh24:mi:ss');
    
    --select * from pedidodniconformado;
    --recorro cada pedido del cliente para asignar DNI
    FOR PED IN
         (SELECT pe.idpedido,
                 pe.iddoctrx,
                 do.dtdocumento,
                 pe.dtaplicacion,
                 pe.ammonto,
                 do.identidadreal
            FROM pedidos                 pe,
                 documentos              do,
                 tx_pedidos_insert       tx
           WHERE pe.iddoctrx = do.iddoctrx
             AND TRUNC(pe.dtaplicacion) = p_dtPedido
             AND pe.cdtipodireccion = p_cdTipoDireccion
             AND pe.sqdireccion = p_sqDireccion
             AND pe.idpedido = tx.idpedido
             --SOLO pedidos no validados o en estado 19
             AND pe.icestadosistema in (0,-1,19,20)
             AND tx.cdcuit = p_cdcuit)
    LOOP
      FOR DNI IN
            (SELECT DC.IDDATOSCLI,
                    DC.DNI,
                    DC.nombre,
                    DC.domicilio,
                    DC.cdsucursal
               FROM tbldatoscliente         dc
              WHERE dc.identidad = PED.IDENTIDADREAL
                AND dc.icactivo = 1 --verifica DNI Activo
             )
      LOOP
         v_monto:=0;
         --sumo lo disponible para el primer cliente el ultimo mes
         begin
             select nvl(sum(adr.amdocumento),0)
               into v_monto
               from tblacumdnireparto adr
              where adr.iddatoscli = DNI.IDDATOSCLI
                and adr.dtdocumento between v_dtDesde and v_dtHasta;
         exception
           when others then
             v_monto:=0;
         end;
          --comparo si el monto del pedido esta por debajo de lo disponible del parametro maximo por DNI al mes
            if v_monto+PED.AMMONTO <= g_MaxMontoDni then
               --inserto tblacumDNIreparto
               insert into tblacumdnireparto
                           (idacumdni,
                            iddoctrx,
                            iddatoscli,
                            dtdocumento,
                            amdocumento,
                            cdsucursal
                            )
                    values (sys_guid(),
                            PED.IDDOCTRX,
                            DNI.IDDATOSCLI,
                            PED.DTDOCUMENTO,
                            PED.AMMONTO,
                            DNI.CDSUCURSAL
                           );
               IF  SQL%ROWCOUNT = 0  THEN
                    n_pkg_vitalpos_log_general.write(2,
                     'Modulo: ' || v_modulo ||
                     '  Detalle Error: insertando tblacumdnireparto IDpedido: '||ped.idpedido);
                    ROLLBACK;
                    RETURN 0;
                  END IF;
              --actualizo el documento
              update documentos doc
                 set doc.dsreferencia = '['||p_cdcuit||']{'||DNI.NOMBRE||'|'||DNI.DNI||'|'||DNI.DOMICILIO||'}'
               where doc.iddoctrx = PED.IDDOCTRX;
              IF  SQL%ROWCOUNT = 0  THEN
                    n_pkg_vitalpos_log_general.write(2,
                     'Modulo: ' || v_modulo ||
                     '  Detalle Error: actualizando documento IDDOCTRX: '||ped.iddoctrx);
                    ROLLBACK;
                    RETURN 0;
               END IF;
               --actualizo el pedido
              update pedidos pe
                 set pe.dsreferencia = '['||p_cdcuit||']{'||DNI.NOMBRE||'|'||DNI.DNI||'|'||DNI.DOMICILIO||'}'
               where pe.idpedido = PED.IDPEDIDO;
              IF  SQL%ROWCOUNT = 0  THEN
                    n_pkg_vitalpos_log_general.write(2,
                     'Modulo: ' || v_modulo ||
                     '  Detalle Error: actualizando pedido : '||ped.idpedido);
                    ROLLBACK;
                    RETURN 0;
               END IF;
               --pone en -1 para indicar que logro insertar el pedido
               PED.AMMONTO:=-1;
               EXIT WHEN PED.AMMONTO = -1;
             else
               --sigue buscando otro DNI con disponiblidad
               continue;
            end if;
      END LOOP;
       -- si pasa por todos los DNI y no logra insertar la cantidad del pedido error
       if PED.AMMONTO <> -1 then
          rollback;
          return 0;
       end if;
    END LOOP;
    COMMIT;
    return 1;
  EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_Modulo || ' Error: ' ||
                                       SQLERRM);
     ROLLBACK;
     RETURN 0;
  END Dividir_Pedido_DNICF;
  
     

end PKG_ASIGNA_DNI_CF;
/
