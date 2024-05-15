CREATE OR REPLACE PACKAGE PKG_PEDIDO_CENTRAL IS

   TYPE cursor_type IS REF CURSOR;

   PROCEDURE GetPedidosTrabados(p_sucursales IN VARCHAR2,
                                p_idEntidad  IN entidades.identidad%TYPE,
                                p_idCuenta   IN tblcuenta.idcuenta%TYPE,
                                p_fechaDesde IN DATE,
                                p_fechaHasta IN DATE,
                                cur_out      OUT cursor_type);

   PROCEDURE ValidarPedidos;

   --PROCEDURE ValidarPedidosOld;

   FUNCTION HayEnlace(p_cdsucursal in sucursales.cdsucursal%type,
                      p_servidor in sucursales.servidor%type)   return integer;

   PROCEDURE TransferirPedidos;

   PROCEDURE GetEstadoPedidos(p_cur_out OUT cursor_type);

   FUNCTION GetFacPromedio(p_IdCuenta IN tblcuenta.idcuenta%TYPE) RETURN NUMBER;

   PROCEDURE GetCuentaPorDomicilio(p_idEntidad       IN entidades.identidad%TYPE,
                                   p_cdTipoDireccion IN direccionesentidades.cdtipodireccion%TYPE,
                                   p_sqdireccion     IN direccionesentidades.sqdireccion%type,
                                   p_cdsucursal      IN sucursales.cdsucursal%type,
                                   p_idCuenta        OUT tblcuenta.idcuenta%type,
                                   p_ok              OUT INTEGER,
                                   p_error           OUT VARCHAR2  );
                                   
    FUNCTION GetCuentaPorDomicilio(p_idEntidad       IN entidades.identidad%TYPE,
                                   p_cdTipoDireccion IN direccionesentidades.cdtipodireccion%TYPE,
                                   p_sqdireccion     IN direccionesentidades.sqdireccion%type,
                                   p_cdsucursal      IN sucursales.cdsucursal%type) 
   RETURN varchar2;

    Function GetFormaOperacion(p_cdCuit     In entidades.cdcuit%Type,
                              p_cdSucursal In tblcuenta.cdsucursal%Type) return integer ;

    FUNCTION GetNombreResponsable (p_id_canal pedidos.id_canal%type,
                               p_idpersona personas.idpersona%type,
                               p_idvendedor personas.idpersona%type,
                               p_idcomisionista entidades.identidad%type)
   RETURN varchar2;

   PROCEDURE TransferirPedido(p_idEntidad       IN pedidos.identidad%TYPE,
                              p_dtPedido        IN pedidos.dtaplicacion%TYPE,
                              p_cdTipoDireccion IN pedidos.cdtipodireccion%TYPE,
                              p_sqDireccion     IN pedidos.sqdireccion%TYPE,
                              p_idpersona       IN personas.idpersona%TYPE default null,
                              p_ok              OUT INTEGER,
                              p_error           OUT VARCHAR2);

END;
/
CREATE OR REPLACE PACKAGE BODY PKG_PEDIDO_CENTRAL IS

  /**************************************************************************************************
  * Este PKG tiene 2 procesos principales:
  * ValidarPedidos:
  * Tiene que validar la informacion crediticia de la cuenta del cliente para evaluar si el pedido esta o no en condiciones
  * de enviarse a la sucursal para su armado
  * TransferirPedido:
  * Es un proceso que mueve el pedido a la sucursal correspondiente y entre las tareas
  * valida la conexion, verifica la sucursal del cliente, y otros datos del cliente del pedido
  * %v 05/08/2014 JBodnar: v1.0
  * %v 05/07/2016 RCigana: Se agrega l�gica de sucursal de armado
  **************************************************************************************************/

  --Globales
  g_PorcLibera          number := Getvlparametro('PorcLiberacion',
                                                 'General');
  g_MesesPromedio       number := Getvlparametro('MesesPromedio', 'General');
  g_DiasVencido         number := Getvlparametro('ICDiaNoFacturacion',
                                                 'General');
  g_idcfreparto         entidades.identidad%TYPE := GETVLPARAMETRO('IdCfReparto',
                                                                   'General');
  g_max_consumidorfinal number := TO_NUMBER(GETVLPARAMETRO('Max_ConsumidorFinal',
                                                           'General')) / 1.21;
  g_max_itemsCF         number := TO_NUMBER(getvlparametro('CntItemsCF',
                                                           'General'));
  g_DeudaMaxima         NUMBER := getvlparametro('DeudaMaxima', 'General');
  g_MontoMaximo         number := getvlparametro('AmMaximoPedido',
                                                 'General'); --Hasta este monto no traba
  g_dtOperativa         DATE := N_PKG_VITALPOS_CORE.GetDT();
  
  g_MaxMontoDni         number := TO_NUMBER(getvlparametro('MaxMontoDni',
                                                 'General')); 

  FUNCTION GetNombreResponsable(p_id_canal       pedidos.id_canal%type,
                                p_idpersona      personas.idpersona%type,
                                p_idvendedor     personas.idpersona%type,
                                p_idcomisionista entidades.identidad%type)
    RETURN varchar2 IS

    v_Modulo      VARCHAR2(100) := 'PKG_PEDIDO_CENTRAL.GetNombreResponsable';
    v_responsable varchar2(100);

  BEGIN
    case p_id_canal
      when 'TE' then
        v_responsable := pkg_reporte_central.GetPersona(p_idpersona);
      when 'VE' then
        v_responsable := pkg_reporte_central.GetPersona(p_idvendedor);
      when 'CO' then
        select dsrazonsocial
          into v_responsable
          from entidades
         where identidad = p_idcomisionista;
      else
        v_responsable := null;
    end case;

    return v_responsable;

  EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_Modulo || ' Error: ' ||
                                       SQLERRM);
      RAISE;
  END GetNombreResponsable;

  FUNCTION HayEnlace(p_cdsucursal in sucursales.cdsucursal%type,
                     p_servidor   in sucursales.servidor%type) return integer is

    v_Modulo VARCHAR2(100) := 'PKG_PEDIDO_CENTRAL.HayEnlace';

  BEGIN
    if pkg_replica_suc.GetActiva(p_cdsucursal) = 0 then
      return 0;
    end if;

    IF NOT Replicas_General.CHECK_DBLINK(p_servidor) THEN
      return 0;
    END IF;

    return 1;
  EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_Modulo || ' Error: ' ||
                                       SQLERRM);
      RAISE;
  END HayEnlace;

  /************************************************************************************************************
  * Retorna los pedidos que estan en estado Anulado o A liberar por Creditos
  * Estos los tiene que evaluar creditos para liberarlos
  * %v 05/08/2014 JBodnar: v1.0
  * %v 20/08/2015 - APW - En lugar de saldo devuelve poder de compra
  * %v 14/10/2014 - APW - Corrijo b�squeda de direcci�n y razon social para estado 7
  * %v 21/10/2015 - APW - Agrego sucursal y canal
  * %v 11/03/2019 - LM - Se agregan las columnas esPBCL y esMP
  * %v 13/03/2019 - LM - se agrega si es CF concatenada en el CUIT
  ************************************************************************************************************/
  PROCEDURE GetPedidosTrabados(p_sucursales IN VARCHAR2,
                               p_idEntidad  IN entidades.identidad%TYPE,
                               p_idCuenta   IN tblcuenta.idcuenta%TYPE,
                               p_fechaDesde IN DATE,
                               p_fechaHasta IN DATE,
                               cur_out      OUT cursor_type) IS
    v_Modulo    VARCHAR2(100) := 'PKG_PEDIDO_CENTRAL.GetPedidosTrabados';
    v_idReporte VARCHAR2(40) := '';
  BEGIN
    --Perminte que el parametro de sucursales pueda tener una o varias sucursales
    --Se reutiliza el filtro de los reportes
    v_idReporte := PKG_REPORTE_CENTRAL.SetSucursalesSeleccionadas(p_sucursales);

    OPEN cur_out FOR
      SELECT pi.cdcuit ||' '|| decode(pe.identidad,do.identidadreal,' ','(CF)')  cdcuit,
             en.dsrazonsocial,
             do.identidadreal identidad,
             do.idcuenta,
             trunc(pe.dtaplicacion) Fecha,
             de.cdtipodireccion,
             de.sqdireccion,
             pkg_pedido_central.GetNombreResponsable(pe.id_canal,
                                                     pe.idpersonaresponsable,
                                                     pe.idvendedor,
                                                     pe.idcomisionista) responsableventa,
             -- Formato Direccion
             de.dscalle || ' ' || de.dsnumero || ' (' ||
             TRIM(de.cdcodigopostal) || ') ' || lo.dslocalidad Direccion,
             ec.dsestado,
             ec.cdestado,
             pkg_cuenta_central.GetSaldoTotal(NVL(p_idEntidad,
                                                  do.identidadreal)) saldo,
             SUM(pe.ammonto) Monto,
             su.dssucursal,
             pe.id_canal,
             decode(en.cdforma, null,'NO','SI') esPBCL,
             (select case
                     when count(*)>0 then
                       'SI'
                     else
                       'NO'
                       end case
             from TBLENTIDADMERCADOPAGO mp
             where mp.identidad=en.identidad) esMP
        FROM pedidos                   pe,
             documentos                do,
             tx_pedidos_insert         pi,
             direccionesentidades      de,
             localidades               lo,
             entidades                 en,
             estadocomprobantes        ec,
             tbltmp_sucursales_reporte rs,
             sucursales                su
       WHERE pe.iddoctrx = do.iddoctrx
         AND do.iddoctrx = pi.iddoctrx
         AND en.identidad = do.identidadreal
         AND pe.icestadosistema = ec.cdestado
         AND do.cdcomprobante = 'PEDI'
         AND ec.cdcomprobante = 'PEDI'
         AND de.identidad = do.identidadreal
         AND de.cdtipodireccion = pe.cdtipodireccion
         AND de.sqdireccion = pe.sqdireccion
         and lo.cdpais = de.cdpais
         and lo.cdprovincia = de.cdprovincia
         AND lo.cdlocalidad = de.cdlocalidad
         AND pi.cdsucursal = rs.cdsucursal
         AND en.cdestadooperativo = 'A' --Activo
         and su.cdsucursal = pi.cdsucursal
         AND rs.idreporte = v_idReporte
         AND pe.icestadosistema in (11, 12, 13, 14, 17) --Trabado por credito
         AND do.identidadreal = NVL(p_idEntidad, en.identidad)
         AND do.idcuenta = NVL(p_idCuenta, do.idcuenta)
         AND pe.dtaplicacion BETWEEN TRUNC(p_fechaDesde) AND
             TRUNC(p_fechaHasta + 1)
       GROUP BY pi.cdcuit,
                pe.identidad,
                en.dsrazonsocial,
                do.identidadreal,
                do.idcuenta,
                trunc(pe.dtaplicacion),
                de.cdtipodireccion,
                pkg_pedido_central.GetNombreResponsable(pe.id_canal,
                                                        pe.idpersonaresponsable,
                                                        pe.idvendedor,
                                                        pe.idcomisionista),
                de.sqdireccion,
                de.dscalle || ' ' || de.dsnumero || ' (' ||
                TRIM(de.cdcodigopostal) || ') ' || lo.dslocalidad,
                ec.dsestado,
                ec.cdestado,
                su.dssucursal,
                pe.id_canal,
                en.identidad,
                en.cdforma
      UNION
      SELECT pi.cdcuit ||' '|| decode(pe.identidad,en.identidad,' ','(CF)')  cdcuit,
             en.dsrazonsocial dsrazonsocial,
             do.identidadreal identidad,
             do.idcuenta,
             trunc(pe.dtaplicacion) Fecha,
             de.cdtipodireccion,
             de.sqdireccion,
             pkg_pedido_central.GetNombreResponsable(pe.id_canal,
                                                     pe.idpersonaresponsable,
                                                     pe.idvendedor,
                                                     pe.idcomisionista) responsableventa,
             de.dscalle || ' ' || de.dsnumero || ' (' ||
             TRIM(de.cdcodigopostal) || ') ' || lo.dslocalidad Direccion,
             ec.dsestado,
             ec.cdestado,
             pkg_cuenta_central.GetSaldo(p_idCuenta) saldo,
             SUM(pe.ammonto) Monto,
             su.dssucursal,
             pe.id_canal,
             decode(en.cdforma, null,'NO','SI') esPBCL,
             (select case
                     when count(*)>0 then
                       'SI'
                     else
                       'NO'
                       end case
             from TBLENTIDADMERCADOPAGO mp
             where mp.identidad=en.identidad) esMP
        FROM pedidos                   pe,
             documentos                do,
             tx_pedidos_insert         pi,
             direccionesentidades      de,
             localidades               lo,
             entidades                 en,
             estadocomprobantes        ec,
             tbltmp_sucursales_reporte rs,
             sucursales                su
       WHERE pe.iddoctrx = do.iddoctrx
         AND do.iddoctrx = pi.iddoctrx
         AND pi.cdcuit = en.cdcuit
         AND pi.cdsucursal = su.cdsucursal
         AND en.cdestadooperativo = 'A' --Activo
         AND pe.icestadosistema = ec.cdestado
         AND en.identidad = de.identidad
         AND pe.cdtipodireccion = de.cdtipodireccion
         AND pe.sqdireccion = de.sqdireccion
         and de.cdpais = lo.cdpais
         and de.cdprovincia = lo.cdprovincia
         AND de.cdlocalidad = lo.cdlocalidad
         AND do.cdcomprobante = 'PEDI'
         AND ec.cdcomprobante = 'PEDI'
         AND pi.cdsucursal = rs.cdsucursal
         AND rs.idreporte = v_idReporte
         AND pe.icestadosistema = 7 -- Datos incompletos
         AND en.identidad = NVL(p_idEntidad, en.identidad)
         AND pe.dtaplicacion BETWEEN TRUNC(p_fechaDesde) AND
             TRUNC(p_fechaHasta + 1)
       GROUP BY pi.cdcuit,
                pe.identidad,
                en.dsrazonsocial,
                do.identidadreal,
                do.idcuenta,
                trunc(pe.dtaplicacion),
                de.cdtipodireccion,
                de.sqdireccion,
                pkg_pedido_central.GetNombreResponsable(pe.id_canal,
                                                        pe.idpersonaresponsable,
                                                        pe.idvendedor,
                                                        pe.idcomisionista),
                de.dscalle || ' ' || de.dsnumero || ' (' ||
                TRIM(de.cdcodigopostal) || ') ' || lo.dslocalidad,
                ec.dsestado,
                ec.cdestado,
                su.dssucursal,
                pe.id_canal,
                en.identidad,
                en.cdforma;

    --Perminte que el parametro de sucursales pueda tener una o varias sucursales
    --Limpia las sucursales para el filtro
    PKG_REPORTE_CENTRAL.CleanSucursalesSeleccionadas(v_idReporte);
  EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_Modulo || ' Error: ' ||
                                       SQLERRM);
      RAISE;
  END GetPedidosTrabados;

  /************************************************************************************************************
  * Cambia el estado a un grupo de pedidos Cliente/fecha/domicilio y lo deja trabado a evaluar por creditos
  * %v 05/08/2014 JBodnar: v1.0
  ************************************************************************************************************/
  PROCEDURE TrabarGrupoDePedidos(p_cdcuit          IN entidades.cdcuit%TYPE,
                                 p_dtPedido        IN pedidos.dtaplicacion%TYPE,
                                 p_cdTipoDireccion IN pedidos.cdtipodireccion%TYPE,
                                 p_sqDireccion     IN pedidos.sqdireccion%TYPE,
                                 p_cdEstado        IN estadocomprobantes.cdestado%TYPE) IS
    v_Modulo VARCHAR2(100) := 'PKG_PEDIDO_CENTRAL.TrabarGrupoDePedidos';
  BEGIN
    UPDATE pedidos pe
       SET pe.icestadosistema = p_cdEstado --A liberar por Creditos
     WHERE TRUNC(pe.dtaplicacion) = p_dtPedido
       AND pe.cdtipodireccion = p_cdTipoDireccion
       AND pe.sqdireccion = p_sqDireccion
       AND pe.idpedido in
           (select p.idpedido
              from pedidos p, documentos d, tx_pedidos_insert tx
             where p.idpedido = tx.idpedido
               AND p.iddoctrx = d.iddoctrx
               and tx.cdcuit = p_cdcuit);
    COMMIT;
  EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_Modulo || ' Error: ' ||
                                       SQLERRM);
      RAISE;
  END TrabarGrupoDePedidos;

  /************************************************************************************************************
  * asigna DNI disponibles para consumidores finales en clientes de pedidos de reparto y comi con cuenta 
  * %v 17/09/2020 ChM: v1.0
  ************************************************************************************************************/
  FUNCTION  AcumDNIReparto(p_cdcuit          entidades.cdcuit%TYPE,
                           p_dtPedido        pedidos.dtaplicacion%TYPE,
                           p_cdTipoDireccion pedidos.cdtipodireccion%TYPE,
                           p_sqDireccion     pedidos.sqdireccion%TYPE) RETURN INTEGER IS
                           
    v_Modulo    VARCHAR2(100) := 'PKG_PEDIDO_CENTRAL.AcumDNIReparto';
    v_dtDesde   date;
    v_dtHasta   date;
    v_monto     tblacumdnireparto.amdocumento%type:=0;   
    
  BEGIN
    --rango ultimo mes
    v_dtDesde := trunc(sysdate,'mm');
    v_dtHasta := to_date(to_char(sysdate, 'dd/mm/yyyy') || ' 23:59:59','dd/mm/yyyy hh24:mi:ss');
    --recorro cada pedido del cliente para asignar DNI
    FOR PED IN
         (SELECT pe.idpedido,
                 pe.iddoctrx,
                 do.dtdocumento,
                 pe.dtaplicacion,
                 pe.ammonto,
                 do.identidadreal 
            FROM pedidos                 pe,
                 documentos              do
           WHERE pe.iddoctrx = do.iddoctrx
             AND TRUNC(pe.dtaplicacion) = p_dtPedido
             AND pe.cdtipodireccion = p_cdTipoDireccion
             AND pe.sqdireccion = p_sqDireccion
             AND pe.idpedido in
                 (select p.idpedido
                    from pedidos p, documentos d, tx_pedidos_insert tx
                   where p.idpedido = tx.idpedido
                     AND p.iddoctrx = d.iddoctrx
                     and tx.cdcuit = p_cdcuit))
    LOOP
      --OOOJOOO ESTA VALIDACION NO SIRVE PARA PEDIDOS CON NONFOOD O PROMOCIONES GRANDES PORQUE EL PKG DIVIDIR NO SEPARA LAS PROMOS A�N SI SUPERAN EL MONTO MINIMO PARA CF
      --verifica si el monto supera lo estipulado por el maximo para consumidor final error
     /* if PED.AMMONTO>g_max_consumidorfinal then --usar la dividir pedidos OJO PENDIENTE
         return 0; 
      end if;  */
      FOR DNI IN
            (SELECT DC.IDDATOSCLI,
                    DC.DNI,
                    DC.nombre,
                    DC.domicilio                    
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
                            amdocumento
                            )
                    values (sys_guid(),
                            PED.IDDOCTRX,
                            DNI.IDDATOSCLI,
                            PED.DTDOCUMENTO,
                            PED.AMMONTO 
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
    return 1;               
    COMMIT;
  EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_Modulo || ' Error: ' ||
                                       SQLERRM);
      RAISE;
  END AcumDNIReparto;

  /************************************************************************************************************
  * Cambia el estado todos los pedidos de un cliente y lo deja trabado a evaluar por creditos
  * %v 05/08/2014 JBodnar: v1.0
  * %v 07/12/2018 - IAquilano: Agrego que no trabe los pedidos que vienen de consumidor final reparto
  ************************************************************************************************************/
  PROCEDURE TrabarPedidosPorCliente(p_cdcuit   IN entidades.cdcuit%TYPE,
                                    p_cdEstado IN estadocomprobantes.cdestado%TYPE) IS
    v_Modulo VARCHAR2(100) := 'PKG_PEDIDO_CENTRAL.TrabarPedidosPorCliente';
  BEGIN
    UPDATE pedidos pe
       SET pe.icestadosistema = p_cdEstado
     WHERE pe.idpedido in
           (select p.idpedido
              from pedidos p, documentos d, tx_pedidos_insert tx
             where p.idpedido = tx.idpedido
               AND p.iddoctrx = d.iddoctrx
               and tx.cdcuit = p_cdcuit);
    COMMIT;

  EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_Modulo || ' Error: ' ||
                                       SQLERRM);
      RAISE;
  END TrabarPedidosPorCliente;

  /************************************************************************************************************
  * Dado un pedido retorna el servidor de la sucursal de la cuenta
  * %v 05/08/2014 JBodnar: v1.0
  ************************************************************************************************************/
  FUNCTION GeServidorPedido(p_IdPedido IN pedidos.idpedido%TYPE) RETURN CHAR IS
    v_Modulo   VARCHAR2(100) := 'PKG_PEDIDO_CENTRAL.GeServidorPedido';
    v_Servidor sucursales.servidor%TYPE;
  BEGIN
    SELECT su.servidor
      INTO v_Servidor
      FROM tblcuenta cu, documentos do, pedidos pe, sucursales su
     WHERE cu.idcuenta = do.idcuenta
       AND do.iddoctrx = pe.iddoctrx
       AND su.cdsucursal = cu.cdsucursal
       AND pe.idpedido = p_IdPedido;
    RETURN v_Servidor;
  EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_Modulo || ' Error: ' ||
                                       SQLERRM);
      RAISE;
  END GeServidorPedido;

  /************************************************************************************************************
  * Retorna la cuenta asociada al domicilio del cliente
  * %v 05/08/2014 JBodnar: v1.0
  ************************************************************************************************************/
  PROCEDURE GetCuentaPorDomicilio(p_idEntidad       IN entidades.identidad%TYPE,
                                  p_cdTipoDireccion IN direccionesentidades.cdtipodireccion%TYPE,
                                  p_sqdireccion     IN direccionesentidades.sqdireccion%type,
                                  p_cdsucursal      IN sucursales.cdsucursal%type,
                                  p_idCuenta        OUT tblcuenta.idcuenta%type,
                                  p_ok              OUT INTEGER,
                                  p_error           OUT VARCHAR2) as
   
  v_modulo    VARCHAR2(100) := 'PKG_PEDIDO_CENTRAL.GetCuentaPorDomicilio';
  
  BEGIN

    p_ok := 1;

    begin
      --Busca la cuenta por cliente/direccion/sucursal
      SELECT dc.idcuenta
        INTO p_idCuenta
        FROM tbldireccioncuenta dc
       WHERE dc.identidad = p_idEntidad
         AND dc.cdtipodireccion = p_cdTipoDireccion
         and dc.sqdireccion = p_sqdireccion
         and dc.cdsucursal = p_cdsucursal;
    exception
      when others then
        --Busco la cuenta de la comercial activa
        begin
          SELECT dc.idcuenta
            INTO p_idCuenta
            FROM tbldireccioncuenta dc
           WHERE dc.identidad = p_idEntidad
             AND dc.cdtipodireccion = '2' --Comercial
             and dc.cdsucursal = p_cdsucursal;
        exception
          when no_data_found then
            p_ok    := 0;
            p_error := 'No se pudo asignar cuenta, Identidad: '||p_identidad;
            return;
        --agrego otro control de exception por si retorna mas de un valor
         when too_many_rows then
            p_ok    := 0;
            p_error := 'Mas de una cuenta comercial, Identidad: '||p_identidad;
      --Grabo log de errores con la identidad
        n_pkg_vitalpos_log_general.write(2, 'Modulo: ' || v_Modulo || ' Error: Mas de una cuenta comercial, Identidad: '||p_identidad);
            return;
        end;
    end;

  EXCEPTION
    WHEN OTHERS THEN
      p_ok    := 0;
      p_error := '  Error: ' || SQLERRM;
  END GetCuentaPorDomicilio;

  /************************************************************************************************************
  * Retorna la cuenta asociada al domicilio del cliente
  * %v 13/04/2018
  ************************************************************************************************************/
  FUNCTION GetCuentaPorDomicilio(p_idEntidad       IN entidades.identidad%TYPE,
                                 p_cdTipoDireccion IN direccionesentidades.cdtipodireccion%TYPE,
                                 p_sqdireccion     IN direccionesentidades.sqdireccion%type,
                                 p_cdsucursal      IN sucursales.cdsucursal%type)
    RETURN varchar2 is
    v_idcuenta tblcuenta.idcuenta%type;
    v_ok       integer;
    v_error    varchar2(1000);

  BEGIN

    GetCuentaPorDomicilio(p_idEntidad,
                          p_Cdtipodireccion,
                          p_sqdireccion,
                          p_cdsucursal,
                          v_idcuenta,
                          v_ok,
                          v_error);
    return v_idcuenta;

  EXCEPTION
    WHEN OTHERS THEN
      return null;
  END GetCuentaPorDomicilio;

  /************************************************************************************************************
  * Dado una cuenta retorna el promedio mensual de facturacion para los meses declarados en el parametro del sistema
  * %v 05/08/2014 JBodnar: v1.0
  * %v 31/03/2015 APW -- cambios en tabla historica + cuenta 2
  ************************************************************************************************************/
  FUNCTION GetFacPromedio(p_IdCuenta IN tblcuenta.idcuenta%TYPE)
    RETURN NUMBER IS
    v_Modulo   VARCHAR2(100) := 'PKG_PEDIDO_CENTRAL.GetFacPromedio';
    v_totalfac number;
    v_cuenta2  tblcuenta.idcuenta%type;

  BEGIN

    pkg_cuenta_central.GetCuentaHija(p_IdCuenta, '2', v_cuenta2);

    -- Acumula de todos los canales y de todas las cuentas del cliente
    select sum(f.amfacturacion)
      into v_totalfac
      from tblfacturacionhistorica f
     where f.idcuenta in (p_IdCuenta, v_cuenta2)
       and f.aniomes >
           trunc(last_day(add_months(sysdate - 15, -g_MesesPromedio)));

    IF nvl(v_totalfac, 0) = 0 THEN
      --No tiene historial, se usa el monto fijo para que lo trabe
      RETURN g_MontoMaximo;
    ELSE
      --Entre el promedio y el monto maximo retorna el mayor
      IF round(v_totalfac / g_MesesPromedio, 2) < g_MontoMaximo THEN
        RETURN g_MontoMaximo;
      ELSE
        RETURN round(v_totalfac / g_MesesPromedio, 2);
      END IF;
    END IF;

  EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_Modulo || ' Error: ' ||
                                       SQLERRM);
      RAISE;
  END GetFacPromedio;

  /************************************************************************************************************
  * Actualiza datos del consumidor final. Es copia del proceso que esta actualmente en produccion
  * %v 05/08/2014 JBodnar: v1.0
  * %v 24/08/2015 - APW: Selecciona entidades con estado operativo activo
  ************************************************************************************************************/
  PROCEDURE ActualizarCF(p_iddoctrx DOCUMENTOS.iddoctrx%TYPE) IS
    v_cdcuit      ENTIDADES.cdcuit%TYPE;
    v_identidadCF ENTIDADES.identidad%TYPE;
    v_sucursal    ENTIDADES.Cdmainsucursal%TYPE;
  BEGIN
    SELECT TRIM(TRANSLATE(dsreferencia, '[]', '  ')), cdsucursal
      INTO v_cdcuit, v_sucursal
      FROM DOCUMENTOS
     WHERE iddoctrx = p_iddoctrx;
    SELECT identidad
      INTO v_identidadCF
      FROM ENTIDADES e
     WHERE e.cdcuit = v_cdcuit
       AND e.cdestadooperativo = 'A';
    UPDATE DOCUMENTOS
       SET identidad = v_identidadCF, dsreferencia = NULL
     WHERE iddoctrx = p_iddoctrx;
    --Actualiza el CF en el pedido
    UPDATE PEDIDOS
       SET identidad = v_identidadCF
     WHERE iddoctrx = p_iddoctrx;
    COMMIT;
  END ActualizarCF;

  /************************************************************************************************************
  * Completa los campos de IDCUENTA/IDENTIDADREAL en segun los datos del cliente
  * Si la compra es de consumidor final fidelizado tengo que guardar los datos del cliente real en su cuenta
  * %v 05/08/2014 JBodnar: v1.0
  * %v 18/08/2015 - APW - Cambio el tratamiento de pedidos de comisionista
  * %v 24/08/2015 - APW - Selecciona entidades con estado operativo activo
  * %v 14/09/2015 - APW - Simplifico ciclo
  * %v 24/11/2015 - APW - Agrego registro de error de direcci�n inexistente
  * %v 02/06/2017 - APW - Agrego control si no pudo completar la cuenta
  * %v 18/12/2018 - IAquilano: Cambio control de estado por idcuenta en null
  ************************************************************************************************************/
  PROCEDURE CompletarDatos(p_cdcuit          IN entidades.cdcuit%type,
                           p_sucursal        IN documentos.cdsucursal%type,
                           p_sucursal_armado IN documentos.cdsucursal%type, -- RLC 27/07 Se agrega surursal armado
                           p_idcuenta        OUT documentos.idcuenta%type,
                           p_identidadreal   out documentos.identidadreal%type,
                           p_ok              OUT INTEGER,
                           p_error           OUT VARCHAR2) IS
                           
    v_modulo    VARCHAR2(100) := 'PKG_PEDIDO_CENTRAL.CompletarDatos';
    v_existedir integer := 0;
    v_identidad documentos.identidad%type;

  BEGIN
    p_ok := 1;

    BEGIN
      SELECT e.identidad
        INTO p_identidadreal
        FROM entidades e
       WHERE e.cdcuit = p_cdcuit
         AND e.cdestadooperativo = 'A';
    EXCEPTION
      WHEN OTHERS THEN
        p_ok    := 0;
        p_error := 'Error al buscar entidad asociada al cuit';
        Return;
    END;

    --Recorre los pedidos agrupando por Cliente/Fecha/Direccion/Monto
    FOR v_RegDatos IN (SELECT do.iddoctrx,
                              do.dsreferencia,
                              pe.sqdireccion,
                              pe.cdtipodireccion,
                              do.identidad,
                              do.idcuenta,
                              do.identidadreal,
                              pe.idcomisionista,
                              pe.idpedido,
                              pe.id_canal
                         FROM documentos        do,
                              pedidos           pe,
                              tx_pedidos_insert pi
                        WHERE pe.iddoctrx = do.iddoctrx
                          AND pi.cdcuit = p_cdcuit
                          AND do.cdcomprobante = 'PEDI'
                          --AND pe.icestadosistema in (0, 7) --Completa datos si esta en estado Creado o Datos incompletos
                          and do.idcuenta is null--desestimamos estados y buscamos cuenta nula para completar
                          AND pe.idpedido = pi.idpedido
                          AND do.cdsucursal = p_sucursal) LOOP
      -- ANTES QUE NADA, por el error de TLK - veo si la direcci�n es v�lida
      select count(*)
        into v_existedir
        from direccionesentidades de
       where de.identidad = p_identidadreal
         and de.cdtipodireccion = v_RegDatos.Cdtipodireccion
         and de.sqdireccion = v_RegDatos.sqdireccion;
      if v_existedir = 0 then
        p_ok    := 0;
        p_error := 'Direccion inexistente';
        pkg_control.GrabarMensaje(sys_guid(),
                                  null,
                                  sysdate,
                                  'Grupo de Pedidos con Direccion inexistente',
                                  ' cli ' || p_identidadreal || ' cd ' ||
                                  v_RegDatos.Cdtipodireccion || ' sq ' ||
                                  v_RegDatos.Sqdireccion,
                                  0);
        Return;
      end if;
      --Busco la cuenta del cliente/direccion
      GetCuentaPorDomicilio(p_identidadreal,
                            v_RegDatos.Cdtipodireccion,
                            v_RegDatos.sqdireccion,
                            p_sucursal_armado,
                            p_idcuenta,
                            p_ok,
                            p_error);
      
      if p_ok <> 0 then
        -- Si le asign� un cliente distinto (no CF), lo cambio en el pedido (mientras haya cuit duplicado)
        v_identidad := v_RegDatos.Identidad;
        if v_identidad <> 'IdCfReparto' and v_identidad <> p_identidadreal then
          v_identidad := p_identidadreal;
          update pedidos p
             set p.identidad = v_identidad
           where p.idpedido = v_RegDatos.Idpedido;
        end if;
        --Actualizo los datos en documentos (tambi�n la entidad si cambi�)
        UPDATE documentos dd
           SET dd.identidadreal = p_identidadreal,
               dd.idcuenta      = p_idcuenta,
               dd.identidad     = v_identidad
         WHERE dd.iddoctrx = v_RegDatos.Iddoctrx;
      else
      --Si el completar datos da error, grabo la identidad con error en el log  
        n_pkg_vitalpos_log_general.write(2, 'Modulo: ' || v_Modulo || ' Error: ' ||p_error);
        return; -- APW - para que suba el error de que no pudo completar la cuenta
      end if;
    END LOOP;
    COMMIT;
  EXCEPTION
    WHEN OTHERS THEN
      p_ok    := 0;
      p_error := '  Error: ' || SQLERRM;
  END CompletarDatos;

  /************************************************************************************************************
  * Proceso de replica de pedidos que ingresar a AC y van a la sucursal que le corresponde al cliente
  * Se transfieren todos los pedidos que estan en estado 1 agrupados por Cliente/Fecha/Direccion
  * %v 04/12/2015 - MarianoL: Mejorar la performance en caso de falta de enlace con la sucursal
  * %v 09/12/2015 - APW: Antes era TransferirPedido
  ************************************************************************************************************/
  PROCEDURE TransferirPedidosOld IS

    v_modulo                VARCHAR2(100) := 'PKG_PEDIDO_CENTRAL.TransferirPedidos';
    v_rv                    NUMBER;
    v_Servidor              sucursales.servidor%TYPE;
    v_error                 tblcontrolmensaje.dsmensaje%type;
    v_lockHandle            VARCHAR2(200);
    v_lockResult            NUMBER;
    v_lockTimeOut_Seg       INTEGER := 300; --N�mero de segundos que se mantendr� el bloqueo
    v_lockWait              INTEGER := 1; --N�mero de segundos que queremos permanecer esperando a que se libere el bloqueo si otro lo tiene bloqueado
    v_lockRelease_on_commit BOOLEAN := FALSE; --True indica que el bloqueo debe liberarse al ejecutar COMMIT o ROLLBACK, si es false debe liberarse manualmente

    CURSOR c_Suc IS
      SELECT distinct pi.cdsucursal, su.servidor
        FROM TX_PEDIDOS_INSERT pi, pedidos pe, documentos do, sucursales su
       WHERE pe.idpedido = pi.idpedido
         AND do.iddoctrx = pi.iddoctrx
         AND do.cdcomprobante = 'PEDI'
         AND pe.icestadosistema = 1 -- los que est�n listos para ser transferidos
         AND not exists
       (select 1
                from tblreplicacontrol r -- Evito las sucursales en la r�plica detecto corte de enlace
               where r.cdsucursal = pi.cdsucursal
                 and r.dserror = 'No hay enlace con la sucursal.');

    CURSOR c_RegPed(p_suc varchar2) IS
      SELECT pi.idpedido,
             pi.iddoctrx,
             pi.cdcuit,
             pe.ammonto,
             do.cdcomprobante,
             pe.dtaplicacion,
             do.cdsucursal
        FROM TX_PEDIDOS_INSERT pi, pedidos pe, documentos do
       WHERE pe.idpedido = pi.idpedido
         AND do.iddoctrx = pi.iddoctrx
         AND do.cdcomprobante = 'PEDI'
         AND pe.icestadosistema = 1 -- los que est�n listos para ser transferidos
         and do.cdsucursal = p_suc
       order by pe.dtaplicacion, do.cdsucursal, pi.cdcuit;

  BEGIN

    -- *** Inicio Lock ***
    -- Este sistema de lockeo lo utilizo para evitar que se llame al procedure m�s de una vez con el mismo pedido de forma simultanea
    dbms_lock.allocate_unique(v_Modulo, v_lockHandle, v_lockTimeOut_Seg); --Genera un id para el conten�do del v_Modulo que dura v_lockTimeOut_Seg
    v_lockResult := dbms_lock.request(v_lockHandle,
                                      dbms_lock.x_mode,
                                      v_lockWait,
                                      v_lockRelease_on_commit); --Genera un lock para ese id
    IF v_lockResult <> 0 THEN
      --No se pudo generar el lock
      RETURN;
    END IF;
    -- *** Fin Lock ***

    -- Recorro las sucursales que tienen pedidos a enviar
    FOR v_RegSuc IN c_Suc LOOP

      --Valida la conexion con el servidor destino
      IF NOT Replicas_General.CHECK_DBLINK(v_Servidor) THEN
        GOTO end_loop_suc; -- CONTINUE en 11g
      END IF;

      --Busco el servidor de la surcursal del pedido
      v_Servidor := v_RegSuc.servidor;

      --Recorro los pedidos de esa sucursal para enviarlos
      FOR v_RegPed IN c_RegPed(v_RegSuc.cdsucursal) LOOP
        --Transfiere todos los datos del pedido a la sucursal
        pkg_Datos_Sucursal.TX_DOCUMENTOS(v_RegPed.Iddoctrx,
                                         v_rv,
                                         v_Servidor);
        IF v_rv = 1 THEN
          v_error := 'Error al transferir el documento ' ||
                     v_RegPed.Iddoctrx || ' al servidor ' || v_Servidor;
          pkg_control.GrabarMensaje(sys_guid(),
                                    v_RegSuc.cdsucursal,
                                    sysdate,
                                    v_modulo,
                                    v_error,
                                    0);
          n_pkg_vitalpos_log_general.write(2,
                                           'Modulo: ' || v_Modulo || ' - ' ||
                                           v_error);
          ROLLBACK;
          GOTO end_loop; -- CONTINUE en 11g
        END IF;

        --Cambio el estado del pedido a Liberado para armar=2
        UPDATE pedidos
           SET icestadosistema = 2
         WHERE idpedido = v_RegPed.Idpedido;

        pkg_Datos_Sucursal.TX_PEDIDOS(v_RegPed.Idpedido, v_rv, v_Servidor);
        IF v_rv = 1 THEN
          v_error := 'Error al transferir el documento ' ||
                     v_RegPed.Iddoctrx || ' al servidor ' || v_Servidor;
          pkg_control.GrabarMensaje(sys_guid(),
                                    v_RegSuc.cdsucursal,
                                    sysdate,
                                    v_modulo,
                                    v_error,
                                    0);
          n_pkg_vitalpos_log_general.write(2,
                                           'Modulo: ' || v_Modulo || ' - ' ||
                                           v_error);
          ROLLBACK;
          GOTO end_loop; -- CONTINUE en 11g
        END IF;

        pkg_Datos_Sucursal.TX_DETALLEPEDIDOS(v_RegPed.Idpedido,
                                             v_rv,
                                             v_Servidor);
        IF v_rv = 1 THEN
          v_error := 'Error al transferir el documento ' ||
                     v_RegPed.Iddoctrx || ' al servidor ' || v_Servidor;
          pkg_control.GrabarMensaje(sys_guid(),
                                    v_RegSuc.cdsucursal,
                                    sysdate,
                                    v_modulo,
                                    v_error,
                                    0);
          n_pkg_vitalpos_log_general.write(2,
                                           'Modulo: ' || v_Modulo || ' - ' ||
                                           v_error);
          ROLLBACK;
          GOTO end_loop; -- CONTINUE en 11g
        END IF;

        pkg_Datos_Sucursal.TX_OBSERVACIONESPEDIDO(v_RegPed.Idpedido,
                                                  v_rv,
                                                  v_Servidor);
        IF v_rv = 1 THEN
          v_error := 'Error al transferir el documento ' ||
                     v_RegPed.Iddoctrx || ' al servidor ' || v_Servidor;
          pkg_control.GrabarMensaje(sys_guid(),
                                    v_RegSuc.cdsucursal,
                                    sysdate,
                                    v_modulo,
                                    v_error,
                                    0);
          n_pkg_vitalpos_log_general.write(2,
                                           'Modulo: ' || v_Modulo || ' - ' ||
                                           v_error);
          ROLLBACK;
          GOTO end_loop; -- CONTINUE en 11g
        END IF;

        --Elimina el pedido de la tabla despues que lo envio a la sucursal
        DELETE FROM TX_PEDIDOS_INSERT WHERE idpedido = v_RegPed.Idpedido;

        --Confirmo
        COMMIT;
        <<end_loop>> -- ESTO ESTA EN REEMPLAZO DE LA SENTENCIA CONTINUE QUE ESTA DISPONIBLE EN LA VERSION 11g
        NULL;

      END LOOP;

      <<end_loop_suc>> -- ESTO ESTA EN REEMPLAZO DE LA SENTENCIA CONTINUE QUE ESTA DISPONIBLE EN LA VERSION 11g
      NULL;

    END LOOP;

    -- *** Libero el lockeo ***
    v_lockResult := dbms_lock.release(v_lockHandle);
    if v_lockResult <> 0 then
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_Modulo ||
                                       '  Error al liberar el lock: ' ||
                                       v_lockResult);
    end if;

    --Deja registro de la operacion en la tabla de control de procesos automaticos
    PKG_PROCESOAUTOMATICO_CENTRAL.GrabarControlProceso('PROCESO AUTOMATICO CENTRAL',
                                                       'Transferir Pedidos',
                                                       1,
                                                       NULL);

  EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_Modulo || ' Error: ' ||
                                       SQLERRM);
      ROLLBACK;
      -- *** Libero el lockeo ***
      v_lockResult := dbms_lock.release(v_lockHandle);
      IF v_lockResult <> 0 THEN
        n_pkg_vitalpos_log_general.write(2,
                                         'Modulo: ' || v_Modulo ||
                                         '  Error al liberar el lock: ' ||
                                         v_lockResult);
      END IF;
      PKG_PROCESOAUTOMATICO_CENTRAL.GrabarControlProceso('PROCESO AUTOMATICO CENTRAL',
                                                         'Transferir Pedidos',
                                                         0,
                                                         SQLERRM);
      RAISE;
  END TransferirPedidosOld;

  /************************************************************************************************************
  * Marca los pedidos que est�n en condiciones de ser transferidos
  * Se transfieren todos los pedidos que estan agrupados por Cliente/Fecha/Direccion
  * %v 05/08/2014 JBodnar: v1.0
  * %v 26/08/2015 JBodnar: Se agrega el parametro p_idpersona por defecto para grabar la nueva tblauditoriapedido
  * %v 07/10/2015 - JB: No transfiere pedidos de monto cero
  * %v 09/12/2015 - APW: ANTES ERA EL TransferirPedido que directamente copiaba a la sucursal, ahora lo hace otro proceso
  ************************************************************************************************************/
  PROCEDURE MarcarPedidoATransferir(p_idEntidad       IN pedidos.identidad%TYPE,
                                    p_dtPedido        IN pedidos.dtaplicacion%TYPE,
                                    p_cdTipoDireccion IN pedidos.cdtipodireccion%TYPE,
                                    p_sqDireccion     IN pedidos.sqdireccion%TYPE,
                                    p_idpersona       IN personas.idpersona%TYPE default null,
                                    p_ok              OUT INTEGER,
                                    p_error           OUT VARCHAR2) IS

    v_modulo    VARCHAR2(100) := 'PKG_PEDIDO_CENTRAL.MarcarPedidoATransferir';
    v_amlinea   DETALLEPEDIDOS.amlinea%TYPE;
    v_nrolinea  NUMBER;
    v_dtllegaac DATE;

    CURSOR c_RegPed IS
      SELECT pi.idpedido,
             pi.iddoctrx,
             pi.cdcuit,
             pe.ammonto,
             do.cdcomprobante,
             pe.dtaplicacion,
             do.cdsucursal
        FROM TX_PEDIDOS_INSERT pi, pedidos pe, documentos do
       WHERE pe.idpedido = pi.idpedido
         AND do.iddoctrx = pi.iddoctrx
         AND do.cdcomprobante = 'PEDI'
         AND trim(do.identidadreal) = trim(p_idEntidad)
         AND TRUNC(pe.dtaplicacion) = p_dtPedido
         AND pe.cdtipodireccion = p_cdTipoDireccion
         AND pe.sqdireccion = p_sqDireccion;
  BEGIN
    p_ok := 0;

    --Recorro cada pedido para enviarlo a la sucursal
    FOR v_RegPed IN c_RegPed LOOP

      --Si el monto del pedido es cero no lo transfiere y continua con el siguiente
      IF v_RegPed.Ammonto = 0 THEN
        --Elimina el pedido de la tabla
        DELETE FROM TX_PEDIDOS_INSERT WHERE idpedido = v_RegPed.Idpedido;

        GOTO end_loop; -- CONTINUE en 11g
      END IF;

      --- Corregir para facturar al cuit del cliente de reparto
      IF p_idEntidad = RPAD(g_idcfreparto, 40) THEN
        IF v_RegPed.Ammonto > g_max_consumidorfinal THEN
          ActualizarCF(v_RegPed.Iddoctrx);
        ELSE
          v_amlinea  := 0;
          v_nrolinea := 0;
          FOR r IN (SELECT amlinea
                      FROM DETALLEPEDIDOS
                     WHERE idpedido = v_RegPed.Idpedido
                     ORDER BY sqdetallepedido) LOOP
            BEGIN
              v_amlinea  := v_amlinea + r.amlinea;
              v_nrolinea := v_nrolinea + 1;
              IF v_amlinea > g_max_consumidorfinal OR
                 v_nrolinea > g_max_itemsCF THEN
                ActualizarCF(v_RegPed.Iddoctrx);
                EXIT;
              END IF;
            END;
          END LOOP; --DEL DETALLEPEDIDO
        END IF; -- DEL MONTO
      END IF; --DEL CF

      --Cambio el estado del pedido a "A transferir" = 1
      UPDATE pedidos
         SET icestadosistema = 1
       WHERE idpedido = v_RegPed.Idpedido;

      --Buscar la fecha y hora que llego a AC
      begin
        select lg.dtlog
          into v_dtllegaac
          from logtimestamp lg
         where lg.id = v_RegPed.Iddoctrx
           and lg.cdestado = '-5   ';
      exception
        when no_data_found then
          --- no deber�a pasar!!
          v_dtllegaac := v_RegPed.Dtaplicacion;
      end;

      --Graba la tabla de auditoria para saber quien libero
      --Si la persona es null es una liberacion automatica
      insert into tblauditoriapedido
        (idauditoriapedido, idpedido, idpersona, dtllegaac, dtviajasuc)
      values
        (sys_guid(), v_RegPed.Idpedido, p_idpersona, v_dtllegaac, sysdate);

      --Confirmo
      COMMIT;
      <<end_loop>> -- ESTO ESTA EN REEMPLAZO DE LA SENTENCIA CONTINUE QUE ESTA DISPONIBLE EN LA VERSION 11g
      NULL;

    END LOOP;

    p_ok    := 1;
    p_error := '';

  EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_Modulo ||
                                       '  Error: ' || SQLERRM);
      p_ok    := 0;
      p_error := '  Error: ' || SQLERRM;
      RAISE;
  END MarcarPedidoATransferir;

  /************************************************************************************************************
  * Solamente llama al MarcarPedidoATransferir
  * Lo dejo para no modificar el llamado desde la web
  * Antes directamente se forzaba la copia, ahora se marcan para ser copiados por otro proceso
  * %v 29/12/2015 - APW
  ************************************************************************************************************/
  PROCEDURE TransferirPedido(p_idEntidad       IN pedidos.identidad%TYPE,
                             p_dtPedido        IN pedidos.dtaplicacion%TYPE,
                             p_cdTipoDireccion IN pedidos.cdtipodireccion%TYPE,
                             p_sqDireccion     IN pedidos.sqdireccion%TYPE,
                             p_idpersona       IN personas.idpersona%TYPE default null,
                             p_ok              OUT INTEGER,
                             p_error           OUT VARCHAR2) IS

    v_modulo VARCHAR2(100) := 'PKG_PEDIDO_CENTRAL.TransferirPedido';

  BEGIN

    MarcarPedidoATransferir(p_idEntidad,
                            p_dtPedido,
                            p_cdTipoDireccion,
                            p_sqDireccion,
                            p_idpersona,
                            p_ok,
                            p_error);

  EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_Modulo ||
                                       '  Error: ' || SQLERRM);
      p_ok    := 0;
      p_error := '  Error: ' || SQLERRM;
      RAISE;
  END TransferirPedido;

  /************************************************************************************************************
  * Dado un cliente retorna el monto todas de los pedidos del dia
  * %v 05/08/2014 JBodnar: v1.0
  ************************************************************************************************************/
  PROCEDURE ValidaMontoPedido(p_cdCuit        IN entidades.cdcuit%TYPE,
                              p_amTotalPedido OUT pedidos.ammonto%TYPE) IS
    v_Modulo VARCHAR2(100) := 'PKG_PEDIDO_CENTRAL.ValidaMontoPedido';
  BEGIN
    BEGIN
      SELECT SUM(pe.ammonto)
        INTO p_amTotalPedido
        FROM TX_PEDIDOS_INSERT pi, pedidos pe, documentos do
       WHERE pi.idpedido = pe.idpedido
         AND do.iddoctrx = pe.iddoctrx
         AND do.cdcomprobante = 'PEDI'
         AND pi.cdcuit = p_cdCuit;
    EXCEPTION
      WHEN no_data_found THEN
        p_amTotalPedido := 0;
    END;
  EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_Modulo ||
                                       '  Error: ' || SQLERRM);
  END ValidaMontoPedido;

  /****************************************************************************************
  * Dada una cuenta busco que forma de operacion tiene configurado el cliente
  * %v 28/05/2015 - JBodnar: v1.0
  * %v 24/08/2015 - APW: Selecciona entidades con estado operativo activo
  * %v 10/09/2015 - JBodnar: Cambia la forma de mirar si es PB. Si tiene configurados comercios en la sucursal es PB
  *****************************************************************************************/
  Function GetFormaOperacion(p_cdCuit     In entidades.cdcuit%Type,
                             p_cdSucursal In tblcuenta.cdsucursal%Type)
    return integer Is
    v_Modulo               Varchar2(100) := 'PKG_PEDIDO_CENTRAL.GetFormaOperacion';
    v_TieneEstablecimiento Integer;
    v_cdForma              entidades.cdforma%type;
  Begin

    select ee.cdforma
      into v_cdForma
      from entidades ee
     where ee.cdcuit = p_cdCuit
       and ee.cdestadooperativo = 'A'; --Activo;

    select count(*)
      into v_TieneEstablecimiento
      from tblcuenta c, entidades ee
     where ee.cdcuit = p_cdCuit
       and c.identidad = ee.identidad
       and c.cdsucursal = p_cdSucursal
       and ee.cdestadooperativo = 'A' --Activo
       and exists (select 1
              from tblestablecimiento es
             where es.idcuenta = c.idcuenta
               and es.cdsucursal = p_cdSucursal); --Existen establecimientos para esa sucursal

    --Si tiene establecimientos configurados para la sucursal y ademas es forma PB retorna que opera como PB en esa sucursal
    If v_TieneEstablecimiento > 0 and v_cdForma = '4' then
      Return 1;
    else
      Return 0;
    end if;
  Exception
    When Others Then
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_Modulo ||
                                       '  Error: ' || Sqlerrm);
  End GetFormaOperacion;

  /****************************************************************************************
  * Dada una cuenta busco el saldo de la cuenta asociada (1 si es la 2, 2 si es la 1)
  * %v 04/10/2016 - APW
  *****************************************************************************************/
  FUNCTION GetSaldoOtraCuenta(p_idcuenta tblcuenta.idcuenta%type)
    return number is
    v_Modulo Varchar2(100) := 'PKG_PEDIDO_CENTRAL.GetSaldoOtraCuenta';
    v_saldo  number;
    v_tipo   tblcuenta.cdtipocuenta%type;
    v_otra   tblcuenta.idpadre%type;

  BEGIN
    select c.cdtipocuenta, c.idpadre
      into v_tipo, v_otra
      from tblcuenta c
     where c.idcuenta = p_idcuenta;

    if v_tipo = '1' then
      -- si es la 1, busco la de CF
      select c.idcuenta
        into v_otra
        from tblcuenta c
       where c.idpadre = p_idcuenta;
    end if;

    v_saldo := pkg_cuenta_central.GetSaldo(v_otra);
    return v_saldo;

  Exception
    When Others Then
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_Modulo ||
                                       '  Error: ' || Sqlerrm);
  END GetSaldoOtraCuenta;

  /************************************************************************************************************
  * Promedio de acreditaciones PB de los ultimos 90 dias mirando la ultima semana
  * %v 06/09/2017 JBodnar: v1.0
  * %v 08/05/2018 JBodnar: v1.0: Pasa de mirar 7 a ultimos 14 dias de acreditaciones
  ************************************************************************************************************/
  FUNCTION GetAcredPosnet(p_IdEntidad IN tblcuenta.identidad%TYPE)
    RETURN NUMBER IS
    v_Modulo   VARCHAR2(100) := 'PKG_PEDIDO_CENTRAL.GetAcredPosnet';
    v_promedio number;
    v_dias     integer;

  BEGIN

    Begin
      --Mira si acredito en la ultima semana
      select count(distinct trunc(i.dtingreso))
        into v_dias
        from tblposnetbanco p, tblingreso i, tblcuenta c, entidades e
       where p.idingreso = i.idingreso
         and i.idcuenta = c.idcuenta
         and c.identidad = e.identidad
         and e.identidad = p_IdEntidad
         and i.dtingreso > sysdate - 14; /*Dias*/
      --Si no tiene acreditaciones sale con promedio cero
      If v_dias = 0 then
        return 0;
      end if;

      --Si acredito mira el promedio de los ultimos 90 dias por cinco
      select round((sum(monto) / 90) * 5 /*Dias*/)
        into v_promedio
        from (select dtacred, sum(monto) monto
                from (select trunc(i.dtingreso) dtacred,
                             sum(i.amingreso) monto
                        from tblposnetbanco p,
                             tblingreso     i,
                             tblcuenta      c,
                             entidades      e
                       where p.idingreso = i.idingreso
                         and i.idcuenta = c.idcuenta
                         and c.identidad = e.identidad
                         and e.identidad = p_IdEntidad
                       group by i.dtingreso)
               group by dtacred
              having dtacred > sysdate - 90 /*Dias*/
              );
    exception
      when others then
        return 0;
    end;

    return v_promedio;

  EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_Modulo || ' Error: ' ||
                                       SQLERRM);
      RAISE;
  END GetAcredPosnet;




  /************************************************************************************************************
  * Dada una cierre de reglas evalua los pedidos ingresados al sistema y los deja en un estado listo para ser enviado
  * a la surcursal para que se arme
  * Reglas
  * Para Clientes con Carpeta Crediticia, PB, o CL:
  * 1-Si la fecha del pedido esta vencida (Par�metro de 7 d�as) se traba.
  * 2-Si tiene traba crediticia (No puede usar cr�dito / No puede facturar) se traba.
  * 3-Si el monto del pedido es mayor al Saldo + Cr�dito + 30% se traba.
  * Para clientes en efectivo(sin carpeta crediticia):
  * 4-Si el monto del pedido es mayor al Promedio de Compra + 30% se traba. (ANALIZAR SI CORRESPONDE)
  *****************************************************
  * Estado de los pedidos:
  * Ingresado=0
  * Bajo Promedio de Compra=14
  * Sin Cr�dito Disponible=13
  * Fecha Vencida=12
  * Traba Crediticia=11
  * Liberado para armar=2
  * Anulado=6 --Cuando el pedido esta vencido
  * %v 28/05/2015 JBodnar: v1.0
  ***********************************************************************************************************
  * %v 20/08/2015 - APW - Quito el tratamiento especial de direcciones para IdCfReparto
                         - Cambio el tratamiento de IdCfReparto en control de cr�dito para trabar
  * %v 24/08/2015 - APW: Selecciona entidades con estado operativo activo
  * %v 13/10/2015 - APW - Cambio de lugar la asignaci�n de entidad real
  * %v 19/10/2015 - APW - Corrijo error en busqueda de vencidos
  * %v 12/12/2015 - APW - Restrinjo filtro de vencidos por fecha, para que haga m�s r�pido
  * %v 09/12/2015 - APW - Deja de enviar - Solo marca - llama a MarcarPedidoATransferir en lugar de TransferirPedido
  * %v 14/06/2016 - APW - Agrego trunc(dtaplicacion) al grupo de pedidos
  * %v 07/07/2016 RCigana: Se recupera sucursal de armado, se busca por sucursal de armado
  * %v 28/07/16 RLC, Busca ID de Suc y Suc<>Armado y si encuentra, fuerza a entrar a CompletarDatos
  * %V 10/08/16 RLC, Se agrega condici�n a busq de pedidos para que no traiga los que estan en err tx suc orig
  * %v 04/10/2016 - APW: agrego que compare tambi�n saldo de otra cuenta
  * %v 16/01/2017 - APW: Modifico sucursal por la que valida tipo de operaci�n para que tome la de armado
  * %v 09/03/2017 -  JB: Los pedidos de canal comisionista y los de zona franca no se validan y pasar directamente a la sucursal
  * %v 06/07/2017 -  JB: Nueva exception para clientes con baja operativa
  * %v 06/09/2017 -  JB: Cambios en la l�gica del la validacion segun documento ValidacionPedidos_v3_20170509.pdf
  * %v 11/04/2018 -  JB: Cambios en la l�gica del la validacion segun documento ValidacionPedidos_v3_20181104.pdf
  * %v 19/04/2018 -  JB: Cambios en la l�gica para que mire el saldo sin valor absoluto y se cambio el parametro de deuda maxima
  * %v 21/06/2018 -  JB: Se sube el g_MontoMaximo de 30000 a 50000 y se modifica la l�gica segun flujo enviado por cr�ditos
  * %v 31/07/2018 -  JB: Mira el par�metro para saber si borra el usuario de TEST
  * %v 07/12/2018 - IAquilano: Agrego el llamado al completar datos para todos los pedidos.
  * %v 17/09/2020 - ChM  agrego DNI de CF disponible en tblacumdnireparto para pedidos TE,VE,CO
  * %v 06/10/2020 - ChM  Agrego aplicar DNI de CF solo para pedidos de consumidor final
  ************************************************************************************************************/
  PROCEDURE ValidarPedidos IS
    v_modulo                VARCHAR2(100) := 'PKG_PEDIDO_CENTRAL.ValidarPedidos';
    v_Saldo                 NUMBER;
    v_SaldoOtra             NUMBER;
    v_CredDisp              NUMBER;
    v_IdentidadReal         entidades.identidad%type;
    v_MotivoTraba1          estadocomprobantes.cdestado%type := '11      '; --Traba Crediticia
    v_MotivoTraba2          estadocomprobantes.cdestado%type := '12      '; --Fecha Vencida
    v_MotivoTraba3          estadocomprobantes.cdestado%type := '13      '; --Saldo Insuficiente
    v_MotivoTraba4          estadocomprobantes.cdestado%type := '14      '; --Bajo Promedio de Compra
    v_MotivoTraba5          estadocomprobantes.cdestado%type := '17      '; --Saldo Negativo
    v_MotivoTraba6          estadocomprobantes.cdestado%type := '19      '; --DNI CF no disponible 
    v_ok                    INTEGER;
    v_error                 VARCHAR(100);
    v_lockHandle            VARCHAR2(200);
    v_lockResult            NUMBER;
    v_lockTimeOut_Seg       INTEGER := 300; --N�mero de segundos que se mantendr� el bloqueo
    v_lockWait              INTEGER := 1; --N�mero de segundos que queremos permanecer esperando a que se libere el bloqueo si otro lo tiene bloqueado
    v_lockRelease_on_commit BOOLEAN := FALSE; --True indica que el bloqueo debe liberarse al ejecutar COMMIT o ROLLBACK, si es false debe liberarse manualmente
    v_HayCtaSucDistSucArm   INTEGER; -- 28/07/16 RLC, Para Buscar ID de Suc y Suc<>Armado

  BEGIN
    -- *** Inicio Lock ***
    -- Este sistema de lockeo lo utilizo para evitar que se llame al procedure m�s de una vez con el mismo pedido de forma simultanea
    dbms_lock.allocate_unique(v_Modulo, v_lockHandle, v_lockTimeOut_Seg); --Genera un id para el conten�do del v_Modulo que dura v_lockTimeOut_Seg
    v_lockResult := dbms_lock.request(v_lockHandle,
                                      dbms_lock.x_mode,
                                      v_lockWait,
                                      v_lockRelease_on_commit); --Genera un lock para ese id
    IF v_lockResult <> 0 THEN
      --No se pudo generar el lock
      RETURN;
    END IF;
    -- *** Fin Lock ***

    --- Borra los PEDREF que corresponden a sucursales migradas
    delete from tx_pedidos_insert tx
     where tx.cdsucursal IN (SELECT cdsucursal FROM tblmigracion)
       and exists (select 1
              from documentos d
             where d.cdcomprobante = 'PEDREF'
               and d.iddoctrx = tx.iddoctrx);

    --- Borra de la cola los pedidos vencidos cuando se pas� el doble de tiempo de vencimiento
    delete from tx_pedidos_insert tx
     where tx.idpedido in
           (select p.idpedido
              from pedidos p
             where p.dtaplicacion < trunc(sysdate) - (g_DiasVencido * 2)
               and p.dtaplicacion > trunc(sysdate) - (g_DiasVencido * 4) -- para que demore menos la consulta
            );

    --Mira el par�metro para saber si borra
    if getvlparametro('UserTest','General')=1 then
    -- Quito de la cola de procesos los que llegaron desde el usuario de prueba, para que no se procesen
    delete from tx_pedidos_insert tx
     where tx.idpedido in
         (select p.idpedido
          from pedidos p
          where p.transid like 'TEST%');
    end if;



    --Recorre los pedidos agrupando por Cliente/Fecha/Direccion/Monto
    --07/07/2016 RCigana: Se recupera sucursal de armado, se busca por sucursal de armado
    -- 10/08/16 RLC, Se agrega condici�n a busq de pedidos para que no traiga los que estan en err tx suc orig
    FOR v_RegPed IN (SELECT pe.identidad,
                            pi.cdcuit,
                            do.idcuenta,
                            pe.id_canal,
                            trunc(pe.dtaplicacion) Fecha,
                            pe.cdtipodireccion,
                            pe.sqdireccion,
                            do.cdsucursal,
                            pe.iczonafranca,
                            sa.cdsucursal_armado, -- Se recupera sucursal de armado
                            COUNT(pe.idpedido) Cantidad,
                            SUM(pe.ammonto) Monto
                       FROM tx_pedidos_insert pi,
                            pedidos           pe,
                            documentos        do,
                            tblsucursalarmado sa
                      WHERE pi.idpedido = pe.idpedido
                        AND do.iddoctrx = pi.iddoctrx
                        AND do.cdcomprobante = 'PEDI'
                        AND pi.cdsucursal IN
                            (SELECT cdsucursal FROM tblmigracion) --Solo procesa pedidos de sucursales migradas
                        AND pe.icestadosistema <> 1 -- si ya est�n marcados para liberar no los revisa
                        and pi.cdsucursal = sa.cdsucursal -- RC Por sucursal contra la tabla de suc armado 27/07
                        and nvl(pi.icerrtfsucori, 0) <> 1
                      GROUP BY pe.identidad,
                               pi.cdcuit,
                               do.idcuenta,
                               pe.id_canal,
                               trunc(pe.dtaplicacion),
                               pe.cdtipodireccion,
                               pe.sqdireccion,
                               do.cdsucursal,
                               pe.iczonafranca,
                               sa.cdsucursal_armado) LOOP



     -- 28/07/16 RLC, Busca ID de Suc y Suc<>Armado
      select decode(count(*), 0, 0, 1)
        into v_HayCtaSucDistSucArm
        from tblcuenta
       where idcuenta = v_RegPed.Idcuenta
         and cdsucursal = v_RegPed.Cdsucursal
         and v_RegPed.Cdsucursal <> v_RegPed.Cdsucursal_Armado;

      --Completa los datos de IDENTIDADREAL / IDCUENTA si no vienen en el ingreso del pedido
      IF (v_RegPed.Idcuenta IS NULL or v_HayCtaSucDistSucArm = 1) THEN
        -- 28/07/16 RLC, si no trae ID o es de Suc y Suc<>Armado
        --Completa los datos de cuenta y identidad real
        -- 07/07/2016 RCigana: Se recupera sucursal de armado, se busca por sucursal de armado
        CompletarDatos(v_RegPed.Cdcuit,
                       v_RegPed.cdsucursal,
                       v_RegPed.cdsucursal_armado,
                       v_RegPed.Idcuenta,
                       v_IdentidadReal,
                       v_ok,
                       v_error);

        --Cambia el estado si no puede completar los datos del pedido
        IF v_ok = 0 THEN
          --Se deja el pedido en estado=7 (Datos incompletos)
          --07/07/2016 RCigana: Se recupera sucursal de armado, se busca por sucursal de armado
          update pedidos p1
             set p1.icestadosistema = 7
           where p1.idpedido in
                 (select p.idpedido
                    from pedidos           p,
                         tx_pedidos_insert tx,
                         tblsucursalarmado sa
                   where p.identidad = v_RegPed.Identidad
                     and p.cdtipodireccion = v_RegPed.Cdtipodireccion
                     and p.sqdireccion = v_RegPed.Sqdireccion
                     and p.icestadosistema = 0 --Ingresado
                     and p.id_canal = v_RegPed.Id_Canal
                     and p.idpedido = tx.idpedido
                     and tx.cdsucursal = sa.cdsucursal
                     and sa.cdsucursal_armado = v_RegPed.cdsucursal_armado
                     and tx.cdcuit = v_RegPed.cdcuit);

          GOTO end_loop; -- CONTINUE en 11g
        END IF;

        IF v_IdentidadReal IS NOT NULL THEN
          v_RegPed.Identidad := v_IdentidadReal;
        END IF;

        --Si puede completar los datos deja el pedido en estado 0 nuevamente para ser evaluado
        IF v_ok = 1 THEN
          --Se deja el pedido en estado=0 (Creado)
          --07/07/2016 RCigana: Se recupera sucursal de armado, se busca por sucursal de armado
          update pedidos p1
             set p1.icestadosistema = 0
           where p1.idpedido in
                 (select p.idpedido
                    from pedidos           p,
                         tx_pedidos_insert tx,
                         tblsucursalarmado sa
                   where p.identidad = v_RegPed.Identidad
                     and p.cdtipodireccion = v_RegPed.Cdtipodireccion
                     and p.sqdireccion = v_RegPed.Sqdireccion
                     and p.icestadosistema = 7 --Datos Incompletos
                     and p.id_canal = v_RegPed.Id_Canal
                     and p.idpedido = tx.idpedido
                     and tx.cdsucursal = sa.cdsucursal
                     and sa.cdsucursal_armado = v_RegPed.cdsucursal_armado
                     and tx.cdcuit = v_RegPed.cdcuit);

          GOTO end_loop; -- CONTINUE en 11g
        END IF;

      END IF;

      --Busca la identidad real
      begin
        select ee.identidad
          into v_IdentidadReal
          from entidades ee
         where ee.cdcuit = v_RegPed.Cdcuit
           and ee.cdestadooperativo = 'A';
      exception
        when TOO_MANY_ROWS then
          pkg_control.GrabarMensaje(sys_guid(),
                                    null,
                                    sysdate,
                                    'Error al validar pedido',
                                    'CUIT duplicado ' || v_RegPed.Cdcuit,
                                    0);
          GOTO end_loop; -- CONTINUE en 11
        when no_data_found then
          pkg_control.GrabarMensaje(sys_guid(),
                                    null,
                                    sysdate,
                                    'Pedido con baja operativa',
                                    'CUIT ' || v_RegPed.Cdcuit,
                                    0);
          GOTO end_loop; -- CONTINUE en 11
      end;

      --Si el canal es comisionista o zona franca no se traba el pedido
      IF (TRIM(v_RegPed.Id_Canal) in ('VE', 'SA')) or
         (v_RegPed.Id_Canal = 'TE' and v_RegPed.Iczonafranca = '0') THEN

        --Trabo el grupo de pedidos porque esta vencida la fecha
        IF v_RegPed.Fecha < trunc(g_dtOperativa - g_DiasVencido) THEN
          TrabarGrupoDePedidos(v_RegPed.Cdcuit,
                               v_RegPed.Fecha,
                               v_RegPed.Cdtipodireccion,
                               v_RegPed.Sqdireccion,
                               v_MotivoTraba2);

          GOTO end_loop; -- CONTINUE en 11g
        END IF;

        --Si tiene traba crediticia se deja todos los pedidos a liberar por creditos
        IF pkg_cuenta_central.IsTrabaOK(v_RegPed.Idcuenta) = 1 THEN
          TrabarPedidosPorCliente(v_RegPed.Cdcuit, v_MotivoTraba1);

          GOTO end_loop; -- CONTINUE en 11g
        END IF;

        --Buscar el saldo y el credito disponible
        pkg_cuenta_central.GetSaldo(v_RegPed.Idcuenta, v_Saldo);
        pkg_credito_central.GetDisponible(v_RegPed.Idcuenta, v_CredDisp);

        --Busco la deuda de la otra cuenta
        v_SaldoOtra := GetSaldoOtraCuenta(v_RegPed.Idcuenta);
        -- considero saldo la suma de los dos -- en CF solo puede haber deuda que reste, no $$ a favor
        v_Saldo := v_Saldo + v_SaldoOtra;

        --Si es consumidor final lo libera:
        -- cuando el monto sea inferior a un par�metro y la deuda menor a otro par�metro
        -- o
        -- cuando  monto sea inferior al promedio de compra y tenga deuda menor a un par�metro
        if trim(v_RegPed.Identidad) = 'IdCfReparto' then          
          if (v_Saldo < g_DeudaMaxima) then
            TrabarGrupoDePedidos(v_RegPed.Cdcuit,
                                 v_RegPed.Fecha,
                                 v_RegPed.Cdtipodireccion,
                                 v_RegPed.Sqdireccion,
                                 v_MotivoTraba5);

            GOTO end_loop; -- CONTINUE en 11g
          else
            if (v_RegPed.Monto >= g_MontoMaximo) then

              if (v_RegPed.Monto > (GetFacPromedio(v_RegPed.Idcuenta) *
                 (1 + (to_number(g_PorcLibera) / 100)))) then

                TrabarGrupoDePedidos(v_RegPed.Cdcuit,
                                     v_RegPed.Fecha,
                                     v_RegPed.Cdtipodireccion,
                                     v_RegPed.Sqdireccion,
                                     v_MotivoTraba4);

                GOTO end_loop; -- CONTINUE en 11g
              end if;

            end if;
          end if;                 
        else
          --Si el cliente es PosnetBanco
          IF GetFormaOperacion(v_RegPed.Cdcuit, v_RegPed.Cdsucursal_Armado) = 1 THEN
            --Si el poder de compra no alcanza
            --Mira Dispnible + Saldo + Promedio de Acreditaciones
            IF v_RegPed.Monto > (v_Saldo + v_CredDisp) +
               (GetAcredPosnet(v_RegPed.Identidad)) THEN
              TrabarGrupoDePedidos(v_RegPed.Cdcuit,
                                   v_RegPed.Fecha,
                                   v_RegPed.Cdtipodireccion,
                                   v_RegPed.Sqdireccion,
                                   v_MotivoTraba3);

              GOTO end_loop; -- CONTINUE en 11g
            END IF;
          else

              if (v_Saldo < g_DeudaMaxima) then
                TrabarGrupoDePedidos(v_RegPed.Cdcuit,
                                     v_RegPed.Fecha,
                                     v_RegPed.Cdtipodireccion,
                                     v_RegPed.Sqdireccion,
                                     v_MotivoTraba5);

                GOTO end_loop; -- CONTINUE en 11g
              else
                if (v_RegPed.Monto >= g_MontoMaximo) then

                  if (v_RegPed.Monto > (GetFacPromedio(v_RegPed.Idcuenta) * (1 +
                     (to_number(g_PorcLibera) / 100)))) then

                    TrabarGrupoDePedidos(v_RegPed.Cdcuit,
                                         v_RegPed.Fecha,
                                         v_RegPed.Cdtipodireccion,
                                         v_RegPed.Sqdireccion,
                                         v_MotivoTraba4);

                    GOTO end_loop; -- CONTINUE en 11g
                  end if;
              end if;
            END IF;
          END IF;
        end if;
      END IF;
      --agrego DNI disponible en tblacumdnireparto ChM 17/09/2020
      --Agrego aplicar DNI de CF solo para pedidos de consumidor final ChM 06/10/2020
      -------------------------------OOOOOOOOOOOOJOJJJJJJJJJJJJJJJOOOOOOOOOOO------------------
      --PARA LOS PEDIDOS DE TELEMARKETING SE ASIGNAN DNI CF DE ACUMDNI DE AC ""NO SE TOMAR� EN CUENTA EL MANEJO PROPIO DEL PROVEEDOR DE TELE""
           IF (TRIM(v_RegPed.Id_Canal) in ('VE', 'TE', 'CO')) and trim(v_RegPed.Identidad) = 'IdCfReparto'  THEN
              -- asigna DNI a los pedidos de consumidor final seg�n disponibilidad
              IF AcumDNIReparto (v_RegPed.Cdcuit, v_RegPed.Fecha, v_RegPed.Cdtipodireccion,v_RegPed.Sqdireccion)<> 1 THEN
                 TrabarGrupoDePedidos(v_RegPed.Cdcuit,
                                      v_RegPed.Fecha,
                                      v_RegPed.Cdtipodireccion,
                                      v_RegPed.Sqdireccion,
                                      v_MotivoTraba6);
                  GOTO end_loop; -- CONTINUE en 11g                    
                END IF;
           END IF;      
      --Si paso bien todas las reglas marco todos los pedidos del grupo para ser enviados a la sucursal
      MarcarPedidoATransferir(v_IdentidadReal,
                              v_RegPed.Fecha,
                              v_RegPed.Cdtipodireccion,
                              v_RegPed.Sqdireccion,
                              null,
                              v_ok,
                              v_error);

      IF v_ok = 0 THEN
        n_pkg_vitalpos_log_general.write(2,
                                         'Modulo: ' || v_modulo ||
                                         '  Error: ' || v_error);
      END IF;
      <<end_loop>> -- ESTO ESTA EN REEMPLAZO DE LA SENTENCIA CONTINUE QUE ESTA DISPONIBLE EN LA VERSION 11g
      NULL;
    END LOOP;

    -- *** Libero el lockeo ***
    v_lockResult := dbms_lock.release(v_lockHandle);
    if v_lockResult <> 0 then
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_Modulo ||
                                       '  Error al liberar el lock: ' ||
                                       v_lockResult);
    end if;

    --Deja registro de la operacion en la tabla de control de procesos automaticos
    PKG_PROCESOAUTOMATICO_CENTRAL.GrabarControlProceso('PROCESO AUTOMATICO CENTRAL',
                                                       'Validar Pedidos',
                                                       1,
                                                       NULL);
  EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_Modulo || ' Error: ' ||
                                       SQLERRM);
      ROLLBACK;
      -- *** Libero el lockeo ***
      v_lockResult := dbms_lock.release(v_lockHandle);
      IF v_lockResult <> 0 THEN
        n_pkg_vitalpos_log_general.write(2,
                                         'Modulo: ' || v_Modulo ||
                                         '  Error al liberar el lock: ' ||
                                         v_lockResult);
      END IF;
      PKG_PROCESOAUTOMATICO_CENTRAL.GrabarControlProceso('PROCESO AUTOMATICO CENTRAL',
                                                         'Validar Pedidos',
                                                         0,
                                                         SQLERRM);
      RAISE;
  END ValidarPedidos;

  /************************************************************************************************************
  * Listado de estados de los pedidos
  * %v 05/08/2014 MatiasH: v1.0
  ************************************************************************************************************/
  PROCEDURE GetEstadoPedidos(p_cur_out OUT cursor_type) IS
    v_Modulo VARCHAR2(100) := 'PKG_PEDIDO_CENTRAL.GetEstadoPedidos';
  BEGIN
    OPEN p_cur_out FOR
      SELECT cc.cdestado, cc.dsestado
        FROM estadocomprobantes cc
       WHERE cc.cdcomprobante = 'PEDI'
       ORDER BY 1;
  EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_Modulo || ' Error: ' ||
                                       SQLERRM);
      RAISE;
  END GetEstadoPedidos;

  /************************************************************************************************************
  * Marca con error en tx_pedidos_insert los pedidos de una sucursal
  * %v 06/07/2016 - RCigana: v1.0
  ************************************************************************************************************/
  PROCEDURE MarcarErrorTxPedIns(p_idPedido in char) IS
    PRAGMA AUTONOMOUS_TRANSACTION;
    v_Modulo VARCHAR2(100) := 'PKG_PEDIDO_CENTRAL.MarcarErrorTxPedIns';
  BEGIN

    update tx_pedidos_insert
       set icerrtfsucori = 1
     where idpedido = p_idPedido;

    commit;
    return;

  EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_Modulo || ' Error: ' ||
                                       SQLERRM);
      RAISE;
  END MarcarErrorTxPedIns;

  /************************************************************************************************************
  * Transfiere los pedidos de un grupo clientes/fecha/direccion
  * %v 22/12/2015 - APW
  * %v 29/02/2016 - APW: Controlo si hay enlace en cada pedido para evitar que se cuelgue o que queden inconsistentes los datos
  * %v 06/07/2016 - RCigana: Primero transfiero todo a sucursal de armado, luego solo cabeceras a sucursal orig
  *                 Controlo en cada caso conexi�n y que no haya sido marcada c/err tx suc en tx_pedidos_insert
  * %v 07/12/2018 - IAquilano: Controlo la sucursal de armado
  * %v 18/03/2019 - JBodnar: Nuevo estado 18 de pedidos a CF para revisar en la sucursal
  * %v 17/09/2020 - ChM Elimino el estado 18 ahora se maneja el estado 19 de AcumDNIReparto para los CF de Reparto y comi
  ************************************************************************************************************/
  PROCEDURE TransferirGrupoPedidos(p_idEntidad       IN pedidos.identidad%TYPE,
                                   p_dtPedido        IN pedidos.dtaplicacion%TYPE,
                                   p_cdTipoDireccion IN pedidos.cdtipodireccion%TYPE,
                                   p_sqDireccion     IN pedidos.sqdireccion%TYPE,
                                   p_servidor        IN sucursales.servidor%TYPE,
                                   p_sucursal_armado IN sucursales.cdsucursal%TYPE,
                                   p_servidor_armado IN sucursales.servidor%TYPE,
                                   p_ok              OUT INTEGER,
                                   p_error           OUT VARCHAR2) IS

    v_modulo VARCHAR2(100) := 'PKG_DATOS_SUCURSAL.TransferirGrupoPedidos';
    v_rv     NUMBER;

    CURSOR c_RegPed IS
      SELECT pi.idpedido,
             pi.iddoctrx,
             pi.cdcuit,
             pe.ammonto,
             do.cdcomprobante,
             pe.dtaplicacion,
             do.cdsucursal,
             pi.icerrtfsucori,
             do.identidad
        FROM TX_PEDIDOS_INSERT pi, pedidos pe, documentos do, tblsucursalarmado sa
       WHERE pe.idpedido = pi.idpedido
         AND do.iddoctrx = pi.iddoctrx
         AND do.cdcomprobante = 'PEDI'
         AND trim(do.identidadreal) = trim(p_idEntidad)
         AND TRUNC(pe.dtaplicacion) = p_dtPedido
         AND pe.cdtipodireccion = p_cdTipoDireccion
         AND pe.sqdireccion = p_sqDireccion
         and do.cdsucursal = sa.cdsucursal
         and sa.cdsucursal_armado=p_sucursal_armado;--agrego sucursal de armado
  BEGIN
    p_ok := 0;

    --Recorro cada pedido para enviarlo a la sucursal
    FOR v_RegPed IN c_RegPed LOOP
      --Si el monto del pedido es cero no lo transfiere y continua con el siguiente
      IF v_RegPed.Ammonto = 0 THEN
        --Elimina el pedido de la tabla
        DELETE FROM TX_PEDIDOS_INSERT WHERE idpedido = v_RegPed.Idpedido;
        GOTO end_loop; -- CONTINUE en 11g
      END IF;

      -- Si se cort� en medio del grupo, cancelo
      -- 06/07/16 RCigana: Se pregunta por el servidor de armado
      if HayEnlace(p_sucursal_armado, p_servidor_armado) = 0 then
        rollback;
        return;
      end if;

      -- 06/07/16 RCigana: Primero transfiero lo necesario a Servidor Armado, si no est� marcado como error tx_pedidos_insert
      IF Nvl(v_RegPed.icerrtfsucori, 0) = 0 then
        -- 05/07/16 RCigana: Los documentos se transfieren primero al servidor de armado
        pkg_Datos_Sucursal.TX_DOCUMENTOS(v_RegPed.Iddoctrx,
                                         v_rv,
                                         p_servidor_armado);
        IF v_rv = 1 THEN
          pkg_control.GrabarMensaje(sys_guid(),
                                    null,
                                    sysdate,
                                    'Error al transferir documento a ' ||
                                    p_servidor_armado,
                                    ' iddoctrx= ' || v_RegPed.Iddoctrx,
                                    0);
          ROLLBACK;
          return;
        END IF;


         --Si es consumidor final se actualiza nuevo estado
         if v_RegPed.Identidad = 'IdCfReparto                             ' then
         /* --Cambio el estado del pedido a "Liberado para armar=2" para mandarlo en ese estado
          UPDATE pedidos
             SET icestadosistema = 18 --A revisar
           WHERE idpedido = v_RegPed.Idpedido;*/
           null;
         else
          --Cambio el estado del pedido a "Liberado para armar=2" para mandarlo en ese estado
          UPDATE pedidos
             SET icestadosistema = 2
           WHERE idpedido = v_RegPed.Idpedido;
         end if;

        -- 06/07/16 RCigana: La cabecera se transfiere primero al servidor de armado
        pkg_Datos_Sucursal.TX_PEDIDOS(v_RegPed.Idpedido,
                                      v_rv,
                                      p_servidor_armado);
        IF v_rv = 1 THEN
          pkg_control.GrabarMensaje(sys_guid(),
                                    null,
                                    sysdate,
                                    'Error al transferir pedido a ' ||
                                    p_servidor_armado,
                                    ' idpedido= ' || v_RegPed.idpedido,
                                    0);
          ROLLBACK;
          return;
        END IF;

        -- 06/07/16 RCigana: Los detalles se transfieren al servidor de armado
        pkg_Datos_Sucursal.TX_DETALLEPEDIDOS(v_RegPed.Idpedido,
                                             v_rv,
                                             p_servidor_armado);
        IF v_rv = 1 THEN
          pkg_control.GrabarMensaje(sys_guid(),
                                    null,
                                    sysdate,
                                    'Error al transferir detalle pedido a ' ||
                                    p_servidor,
                                    ' idpedido= ' || v_RegPed.idpedido,
                                    0);
          ROLLBACK;
          return;
        END IF;

        -- 06/07/16 RCigana: Las observaciones se transfieren al servidor de armado
        pkg_Datos_Sucursal.TX_OBSERVACIONESPEDIDO(v_RegPed.Idpedido,
                                                  v_rv,
                                                  p_servidor_armado);
        IF v_rv = 1 THEN
          pkg_control.GrabarMensaje(sys_guid(),
                                    null,
                                    sysdate,
                                    'Error al transferir observaciones pedido a ' ||
                                    p_servidor_armado,
                                    ' idpedido= ' || v_RegPed.idpedido,
                                    0);
          ROLLBACK;
          return;
        END IF;
        -- 06/07/16 RCigana: FIN Primero transfiero lo necesario a Servidor Armado, si esta activo
      END IF;

      -- Si sucursal armado distinta de sucursal (Debo transmitir cabeceras y documentos a sucursal original)
      IF p_servidor_armado <> p_servidor then
        -- 06/07/16 RCigana: Luego transfiero lo necesario a Servidor original, si esta activo y no est� marcado como error tx_pedidos_insert
        IF HayEnlace(v_RegPed.Cdsucursal, p_servidor) = 1 then
          -- 11/07/16 RCigana: Los documentos se transfieren luego al servidor original
          -- Solo si hay enlace y no hubo error de transmisi�n a la Suc Original
          IF (Nvl(v_RegPed.icerrtfsucori, 0) = 0) then
            pkg_Datos_Sucursal.TX_DOCUMENTOS(v_RegPed.Iddoctrx,
                                             v_rv,
                                             p_Servidor);
            IF v_rv = 1 THEN
              pkg_control.GrabarMensaje(sys_guid(),
                                        null,
                                        sysdate,
                                        'Error al transferir documento a ' ||
                                        p_Servidor,
                                        ' iddoctrx= ' || v_RegPed.Iddoctrx,
                                        0);
              ROLLBACK;
              return;
            END IF;

            -- 05/07/16 RCigana: La cabecera se transfiere luego al servidor original
            -- Se agrega 1 como ultimo par�metro para transmisi�n de cabecera a Suc. orig. con estado distinto a 2.
            pkg_Datos_Sucursal.TX_PEDIDOS(v_RegPed.Idpedido,
                                          v_rv,
                                          p_Servidor,
                                          1);

            IF v_rv = 1 THEN
              pkg_control.GrabarMensaje(sys_guid(),
                                        null,
                                        sysdate,
                                        'Error al transferir pedido a ' ||
                                        p_servidor,
                                        ' idpedido= ' || v_RegPed.idpedido,
                                        0);
              ROLLBACK;
              return;
            END IF;
            -- 06/07/16 RCigana: FIN Luego transfiero lo necesario a Servidor original, si esta activo
          END IF;
        ELSE
          -- 07/07/16 RCigana: marco el pedido con error tx en tx_pedidos_insert, si esta inactiva sucursal
          -- Se usa procedure porque tiene Commit autonomo
          MarcarErrorTxPedIns(v_RegPed.Idpedido);
        END IF;
        -- FIN Si sucursal armado distinta de sucursal (Debo transmitir cabeceras y documentos a sucursal original)
      END IF;

      --Elimina el pedido de la tabla despues de que lo envio a la sucursal
      -- 07/07/16 RCigana: Solo elimino aquellos que no tienen marca error
      DELETE FROM TX_PEDIDOS_INSERT
       WHERE idpedido = v_RegPed.Idpedido
         AND Nvl(icerrtfsucori, 0) = 0;

      <<end_loop>>
      NULL;

    END LOOP;

    --- Confirmo todos o ninguno!
    COMMIT;

    p_ok    := 1;
    p_error := '';

  EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_Modulo ||
                                       '  Error: ' || SQLERRM);
      p_ok    := 0;
      p_error := '  Error: ' || SQLERRM;
      RAISE;
  END TransferirGrupoPedidos;

  /************************************************************************************************************
  * Re Transfiere los pedidos que dieron error en tx suc origen (Solo cabeceras)
  * %v 06/07/2016 - RCigana: v1.0
  ************************************************************************************************************/
  PROCEDURE ReTransfGrupoPedidos(p_idEntidad       IN pedidos.identidad%TYPE,
                                 p_dtPedido        IN pedidos.dtaplicacion%TYPE,
                                 p_cdTipoDireccion IN pedidos.cdtipodireccion%TYPE,
                                 p_sqDireccion     IN pedidos.sqdireccion%TYPE,
                                 p_servidor        IN sucursales.servidor%TYPE,
                                 p_ok              OUT INTEGER,
                                 p_error           OUT VARCHAR2) IS

    v_modulo VARCHAR2(100) := 'PKG_DATOS_SUCURSAL.ReTransfGrupoPedidos';
    v_rv     NUMBER;

    CURSOR c_RegPed IS
      SELECT pi.idpedido,
             pi.iddoctrx,
             pi.cdcuit,
             pe.ammonto,
             do.cdcomprobante,
             pe.dtaplicacion,
             do.cdsucursal,
             pi.icerrtfsucori
        FROM TX_PEDIDOS_INSERT pi, pedidos pe, documentos do
       WHERE pe.idpedido = pi.idpedido
         AND do.iddoctrx = pi.iddoctrx
         AND do.cdcomprobante = 'PEDI'
         AND trim(do.identidadreal) = trim(p_idEntidad)
         AND TRUNC(pe.dtaplicacion) = p_dtPedido
         AND pe.cdtipodireccion = p_cdTipoDireccion
         AND pe.sqdireccion = p_sqDireccion
         AND nvl(pi.icerrtfsucori, 0) = 1;
  BEGIN
    p_ok := 0;

    --Recorro cada pedido para enviarlo a la sucursal
    FOR v_RegPed IN c_RegPed LOOP
      NULL;
      --Si no hay enlace, salgo sin hacer nada
      IF HayEnlace(v_RegPed.Cdsucursal, p_servidor) = 0 then

        ROLLBACK;
        return;
      END IF;

      -- 07/07/16 RCigana: Luego transfiero lo necesario a Servidor original, si esta activo y no est� marcado como error tx_pedidos_insert
      IF HayEnlace(v_RegPed.Cdsucursal, p_servidor) = 1 then
        -- 06/07/16 RCigana: Los documentos se transfieren luego al servidor original
        pkg_Datos_Sucursal.TX_DOCUMENTOS(v_RegPed.Iddoctrx,
                                         v_rv,
                                         p_Servidor);
        IF v_rv = 1 THEN
          pkg_control.GrabarMensaje(sys_guid(),
                                    null,
                                    sysdate,
                                    'Error al re-transferir documento a ' ||
                                    p_Servidor,
                                    ' iddoctrx= ' || v_RegPed.Iddoctrx,
                                    0);
          ROLLBACK;
          return;
        END IF;

        -- 05/07/16 RCigana: La cabecera se transfiere luego al servidor original
        -- Se agrega 1 como ultimo par�metro para transmisi�n de cabecera a Suc. orig. con estado distinto a 2.
        pkg_Datos_Sucursal.TX_PEDIDOS(v_RegPed.Idpedido,
                                      v_rv,
                                      p_Servidor,
                                      1);

        IF v_rv = 1 THEN
          pkg_control.GrabarMensaje(sys_guid(),
                                    null,
                                    sysdate,
                                    'Error al re-transferir pedido a ' ||
                                    p_servidor,
                                    ' idpedido= ' || v_RegPed.idpedido,
                                    0);
          ROLLBACK;
          return;
        END IF;
        -- 06/07/16 RCigana: FIN Luego transfiero lo necesario a Servidor original, si esta activo
      END IF;

      --Elimina el pedido de la tabla despues de que lo envio a la sucursal original
      -- 07/07/16 RCigana: Si llego hasta aca es porque transfirio OK a suc original
      DELETE FROM TX_PEDIDOS_INSERT WHERE idpedido = v_RegPed.Idpedido;

      <<end_loop>>
      NULL;

    END LOOP;

    --- Confirmo todos o ninguno!
    COMMIT;

    p_ok    := 1;
    p_error := '';

  EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_Modulo ||
                                       '  Error: ' || SQLERRM);
      p_ok    := 0;
      p_error := '  Error: ' || SQLERRM;
      RAISE;
  END ReTransfGrupoPedidos;

  /**************************************************************************************************
  * Iniciar transferencia de pedidos
  * %v 22/12/2015 - APW
  * %v 05/07/2016 RCigana: Se recupera sucursal de armado y servidor de armado
  ***************************************************************************************************/
  procedure TransferirPedidos is

    v_modulo                varchar2(100) := 'PKG_PEDIDO_CENTRAL.TransferirPedidos';
    v_lockHandle            varchar2(200);
    v_lockResult            number;
    v_lockTimeOut_Seg       integer := 1800; --N�mero de segundos que se mantendr� el bloqueo
    v_lockWait              integer := 1; --N�mero de segundos que queremos permanecer esperando a que se libere el bloqueo si otro lo tiene bloqueado
    v_lockRelease_on_commit boolean := false; --True indica que el bloqueo debe liberarse al ejecutar COMMIT o ROLLBACK, si es false debe liberarse manualmente
    v_ok                    INTEGER;
    v_error                 VARCHAR(100);

  begin

    -- *** Inicio Lock ***
    -- Este sistema de lockeo lo utilizo para evitar que se ejecute el procedure m�s de una vez
    dbms_lock.allocate_unique(v_modulo, v_lockHandle, v_lockTimeOut_Seg); --Genera un id para el conten�do del v_Modulo que dura v_lockTimeOut_Seg

    v_lockResult := dbms_lock.request(v_lockHandle,
                                      dbms_lock.x_mode,
                                      v_lockWait,
                                      v_lockRelease_on_commit); --Genera un lock para ese id
    If v_lockResult <> 0 Then
      --Si no se pudo generar el lock es porque ya est� corriendo
      return;
    end if;
    -- *** Fin Lock ***

    -- Recorro por sucursal - 05/07/2016 RCigana, se recupera sucursal y servidor de armado
    for v_RegS in (select distinct s.cdsucursal,
                                   s.servidor,
                                   sa.cdsucursal_armado cdsucursal_armado,
                                   s2.servidor          servidor_armado
                     from sucursales        s,
                          tx_pedidos_insert tx,
                          tblsucursalarmado sa,
                          sucursales        s2
                    where s.cdsucursal = tx.cdsucursal
                      and s.cdsucursal = sa.cdsucursal
                      and s2.cdsucursal = sa.cdsucursal_armado
                    order by s.cdsucursal)

     loop
      -- 05/07/16 RCigana: Si no hay enlace de la sucursal de armado
      if HayEnlace(v_RegS.Cdsucursal_armado, v_RegS.Servidor_armado) = 0 then
        GOTO end_loop; -- CONTINUE en 11g
      end if;

      -- Agrupo los pedidos marcados para transferir
      for v_RegPed in (SELECT distinct pi.cdcuit,
                                       do.identidadreal,
                                       trunc(pe.dtaplicacion) fpedido,
                                       pe.cdtipodireccion,
                                       pe.sqdireccion,
                                       pe.id_canal
                         FROM TX_PEDIDOS_INSERT pi,
                              pedidos           pe,
                              documentos        do
                        WHERE pe.idpedido = pi.idpedido
                          AND do.iddoctrx = pi.iddoctrx
                          AND pe.icestadosistema = 1
                          and do.cdsucursal = v_RegS.Cdsucursal) --- solo los marcados para transferir
       loop
        -- Transfiere todos los del grupo
          TransferirGrupoPedidos(v_RegPed.Identidadreal,
                                 v_RegPed.fpedido,
                                 v_RegPed.Cdtipodireccion,
                                 v_RegPed.Sqdireccion,
                                 v_RegS.Servidor,
                                 v_RegS.Cdsucursal_Armado, -- 06/07/16 RCigana: se agrega sucursal de armado
                                 v_RegS.Servidor_armado, -- 06/07/16 RCigana: se agrega servidor de armado
                                 v_ok,
                                 v_error);
        IF v_ok = 0 THEN
          pkg_control.GrabarMensaje(sys_guid(),
                                    null,
                                    sysdate,
                                    'Error al transferir grupo pedidos a ' ||
                                    upper(v_RegS.Servidor),
                                    ' cuit= ' || v_RegPed.cdcuit,
                                    0);
        END IF;

      end loop;

      NULL;

      -- Agrupo los pedidos que dieron error en tx suc origen
      for v_RegPed2 in (SELECT distinct pi.cdcuit,
                                        do.identidadreal,
                                        trunc(pe.dtaplicacion) fpedido,
                                        pe.cdtipodireccion,
                                        pe.sqdireccion
                          FROM TX_PEDIDOS_INSERT pi,
                               pedidos           pe,
                               documentos        do
                         WHERE pe.idpedido = pi.idpedido
                           AND do.iddoctrx = pi.iddoctrx
                           AND nvl(pi.icerrtfsucori, 0) = 1
                           and do.cdsucursal = v_RegS.Cdsucursal) -- Solo los que dieron error en tx suc origen
       loop
        -- Re-transfiero los pedidos que dieron error en tx suc origen, si el servidor est� activo
        if HayEnlace(v_RegS.Cdsucursal, v_RegS.Servidor) = 1 then
          ReTransfGrupoPedidos(v_RegPed2.Identidadreal,
                               v_RegPed2.fpedido,
                               v_RegPed2.Cdtipodireccion,
                               v_RegPed2.Sqdireccion,
                               v_RegS.Servidor,
                               v_ok,
                               v_error);
        end if;

        IF v_ok = 0 THEN
          pkg_control.GrabarMensaje(sys_guid(),
                                    null,
                                    sysdate,
                                    'Error al re-transferir grupo pedidos a ' ||
                                    upper(v_RegS.Servidor),
                                    ' cuit= ' || v_RegPed2.cdcuit,
                                    0);
        END IF;
      end loop;

      <<end_loop>> -- ESTO ESTA EN REEMPLAZO DE LA SENTENCIA CONTINUE QUE ESTA DISPONIBLE EN LA VERSION 11g
      NULL;
    end loop;

    -- *** Libero el lockeo ***
    v_lockResult := dbms_lock.release(v_lockHandle);
    if v_lockResult <> 0 then
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_Modulo ||
                                       '  Error al liberar el lock: ' ||
                                       v_lockResult);
    end if;

    PKG_PROCESOAUTOMATICO_CENTRAL.GrabarControlProceso('PROCESO AUTOMATICO CENTRAL',
                                                       'Transferir Pedidos',
                                                       1,
                                                       NULL);

  exception
    when others then
      -- *** Libero el lockeo ***
      v_lockResult := dbms_lock.release(v_lockHandle);
      if v_lockResult <> 0 then
        n_pkg_vitalpos_log_general.write(2,
                                         'Modulo: ' || v_Modulo ||
                                         '  Error al liberar el lock: ' ||
                                         v_lockResult);
      end if;
      --Registro el error
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       '  Error: ' || SQLERRM);
      PKG_PROCESOAUTOMATICO_CENTRAL.GrabarControlProceso('PROCESO AUTOMATICO CENTRAL',
                                                         'Transferir Pedidos',
                                                         0,
                                                         SQLERRM);
  end TransferirPedidos;

END PKG_PEDIDO_CENTRAL;
/
