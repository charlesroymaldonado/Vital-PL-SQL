CREATE OR REPLACE PACKAGE PKG_TRANSFERIR_PEDIDOS Is

type cursor_type Is Ref Cursor;

TYPE arr_refid IS TABLE OF VARCHAR(100) INDEX BY PLS_INTEGER;

procedure Trae_pedidos;
procedure Trae_Prepedidos;
PROCEDURE GetPedidosVtex ( p_id_canal In vtexorders.id_canal%type,
                           Cur_Out Out Cursor_Type);

FUNCTION GETMULTIPLICADOR (P_CDARTICULO ARTICULOS.CDARTICULO%TYPE,
                             p_id_canal   vtexsku.id_canal%type)  RETURN INTEGER;

PROCEDURE InsertarPedidoPOS (p_pedidoid_vtex       IN  vtexorders.pedidoid_vtex%type,
                             p_id_canal            IN  vtexorders.id_canal%type,
                             p_cabecera            IN OUT  varchar2,                             
                             p_detalle             IN  arr_refId,
                             p_ok                  OUT integer,
                             p_politicaIVA         IN integer default 0);

PROCEDURE Setvtexorders (p_pedidoid_vtex    IN     vtexorders.pedidoid_vtex%type,
                         p_id_canal         IN     vtexorders.id_canal%type,
                         p_idpedido_pos     IN     vtexorders.idpedido_pos%type,
                         p_icprocesado      IN     vtexorders.icprocesado%type,
                         p_observacion      IN     vtexorders.observacion%type);

FUNCTION DividirPedidos(p_idpedido    IN pedidos.idpedido%type) return integer;

PROCEDURE ConvertirPedidoCF (p_idpedido    IN pedidos.idpedido%type,
                             p_ok          OUT INTEGER,
                             p_error       OUT VARCHAR2);
                             
FUNCTION GetmarcaOferART ( p_cdarticulo   articulos.cdarticulo%type,      
                           p_fecha        tblprecio.dtvigenciadesde%type,
                           p_cdsucursal   vtexprice.cdsucursal%type,
                           p_id_canal     vtexprice.id_canal%type )return varchar2;     

PROCEDURE JobPedidosVtex;                                                   

FUNCTION GETPrecioSinIVA (p_cdarticulo articulos.cdarticulo%type,
                            p_cdsucursal sucursales.cdsucursal%type,
                            p_precio     tblprecio.amprecio%type) RETURN NUMBER;
End;
/
CREATE OR REPLACE PACKAGE BODY PKG_TRANSFERIR_PEDIDOS Is

/* MPASSIOTTI - 15/05/2017 - Migracion CC - Trae los pedidos a procesar desde la base CC */
/* MPASSIOTTI - 01/06/2017 - Migracion CC - Se actualiza icestadosistema = 0 para los pedidos padre particionados  en AC. Quedaban en -1 */


procedure Trae_pedidos is

   v_modulo          varchar2(100) := 'PKG_TRANSFERIR_PEDIDOS.Trae_pedidos';
  -- v_idPedido        detallepedidos.idpedido%type;
 --  v_sqDetallePedido detallepedidos.sqdetallepedido%type;

--   TYPE T_PEDIDOS IS TABLE OF PEDIDOS%ROWTYPE INDEX BY BINARY_INTEGER;
--   V_PEDIDOS T_PEDIDOS;

 v_ok      integer;
 v_error   varchar2(300);

   Cursor c_pedidos is
    select p.IDPEDIDO IDPEDIDO,p.IDDOCTRX IDDOCTRX, nvl(pa.limite,0) limite
       From pedidos@CC.VITAL.COM.AR p
       left join tx_pedidos_particionar@CC.VITAL.COM.AR pa on (p.idpedido = pa.idpedido)
      where p.icestadosistema = -1;

begin
  --Traigo los pedidos de CC y cargo las tablas locales.
    FOR i in c_pedidos
    LOOP

      BEGIN
          --Insert documentos
          INSERT INTO DOCUMENTOS
          SELECT * FROM DOCUMENTOS@CC.VITAL.COM.AR WHERE IDDOCTRX = i.IDDOCTRX;
          --Insert pedidos
          INSERT INTO PEDIDOS
          SELECT * FROM PEDIDOS@CC.VITAL.COM.AR WHERE IDPEDIDO = i.IDPEDIDO;
          --Insert detallepedidos
          INSERT INTO DETALLEPEDIDOS
          SELECT * FROM DETALLEPEDIDOS@CC.VITAL.COM.AR WHERE IDPEDIDO = i.IDPEDIDO;
          --Insert observacionespedido
          INSERT INTO OBSERVACIONESPEDIDO
          SELECT * FROM OBSERVACIONESPEDIDO@CC.VITAL.COM.AR WHERE IDPEDIDO = i.IDPEDIDO;
          --Insert tx_pedidos_insert
          INSERT INTO TX_PEDIDOS_INSERT
          SELECT * FROM TX_PEDIDOS_INSERT@CC.VITAL.COM.AR WHERE IDPEDIDO = i.IDPEDIDO;
          --Insert tx_pedidos_particionar
          INSERT INTO TX_PEDIDOS_PARTICIONAR
          SELECT * FROM TX_PEDIDOS_PARTICIONAR@CC.VITAL.COM.AR WHERE IDPEDIDO = i.IDPEDIDO;
      EXCEPTION
        WHEN OTHERS THEN
          n_pkg_vitalpos_log_general.write(2, 'Modulo: '||v_modulo||'  Error al traer info de CC: ' || SQLERRM);
          ROLLBACK;
      END;

      --Particiono el pedido en caso de ser necesario
      If i.limite != 0 then
            BEGIN
              pkg_dividir_pedido.dividir(i.IDPEDIDO, i.LIMITE,v_ok, v_error);

			  --MPASSIOTTI - 01/06/2017 - Migracion CC - Si se particiona, se pasa el pedido padre a 0. Dividirpedido lo elimina de tx_pedidos_insert
              update pedidos set icestadosistema = 0  where idpedido = i.IDPEDIDO;

              delete TX_PEDIDOS_PARTICIONAR WHERE IDPEDIDO = i.IDPEDIDO;
              delete TX_PEDIDOS_PARTICIONAR@CC.VITAL.COM.AR WHERE IDPEDIDO = i.IDPEDIDO;
            EXCEPTION
            WHEN OTHERS THEN
              n_pkg_vitalpos_log_general.write(2, 'Modulo: '||v_modulo||'  Error al dividir pedido: ' || SQLERRM);
              ROLLBACK;
            END;
      END IF;

      --actualizo remoto para que no vuelva a traer los registros
      update pedidos@CC.VITAL.COM.AR set icestadosistema = 0 where IDPEDIDO = i.IDPEDIDO;
      delete TX_PEDIDOS_INSERT@CC.VITAL.COM.AR where IDPEDIDO = i.IDPEDIDO;


    END LOOP;

--una vez que tengo todas las tablas locales cargadas y actualizadas en base CC, modifico valor local para enviar a tiendas.
    BEGIN
       update pedidos
          set icestadosistema = 0
        where idpedido in (select idpedido from TX_PEDIDOS_INSERT)
          and icestadosistema = -1;
    EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2, 'Modulo: '||v_modulo||'  Error al actualizar pedidos de -1: ' || SQLERRM);
      ROLLBACK;
    END;

    commit;

exception when others then
   n_pkg_vitalpos_log_general.write(2, 'Modulo: ' || v_modulo || '  Error: ' || Sqlerrm);
   ROLLBACK;
   raise;
end Trae_pedidos;


procedure Trae_Prepedidos is

 v_modulo          varchar2(100) := 'PKG_TRANSFERIR_PEDIDOS.Trae_Prepedidos';
-- v_ok      integer;
 --v_error   varchar2(300);

   Cursor c_prepedidos is
    select p.*
       From tblcc_prepedido@CC.VITAL.COM.AR p
       where p.idpersonaautoriza   is null
       and p.vltipodocumento = 'pendiente'
       and not exists (select 1 from tblcc_prepedido ppac where ppac.idprepedido = p.idprepedido);

begin
  --Traigo los pedidos de CC y cargo las tablas locales.
    FOR i in c_prepedidos
    LOOP

      BEGIN
          --Insert documentos
          INSERT INTO tblcc_prepedido
          SELECT * FROM tblcc_prepedido@CC.VITAL.COM.AR WHERE idprepedido = i.idprepedido;
          --Insert detallepedidos
          INSERT INTO tblcc_prepedidodetalle
          SELECT * FROM tblcc_prepedidodetalle@CC.VITAL.COM.AR WHERE idprepedido = i.idprepedido;
      EXCEPTION
        WHEN OTHERS THEN
          n_pkg_vitalpos_log_general.write(2, 'Modulo: '||v_modulo||'  Error al traer info de CC: ' || SQLERRM);
          ROLLBACK;
      END;

      BEGIN
       update tblcc_prepedido@CC.VITAL.COM.AR
          set VLTIPODOCUMENTO = 'enviadoAC'
       WHERE idprepedido = i.idprepedido;
      EXCEPTION
      WHEN OTHERS THEN
        n_pkg_vitalpos_log_general.write(2, 'Modulo: '||v_modulo||'  Error al actualizar pedidos de -1: ' || SQLERRM);
       ROLLBACK;
      END;

    END LOOP;

    commit;

exception when others then
   n_pkg_vitalpos_log_general.write(2, 'Modulo: ' || v_modulo || '  Error: ' || Sqlerrm);
   ROLLBACK;
   raise;
end Trae_Prepedidos;

/**************************************************************************************************
* Devuelve los pedidos que están pendientes por traer de VTEX para AC
* %v 15/01/2021 - ChM
* %v 29/07/2021 - ChM - Agrego id_canal para ajuste ambientes VTEX
***************************************************************************************************/
PROCEDURE GetPedidosVtex ( p_id_canal In vtexorders.id_canal%type,
                           Cur_Out Out Cursor_Type) IS

  v_modulo        varchar2(100) := 'PKG_TRANSFERIR_PEDIDOS.GetPedidosVtex';

BEGIN
  OPEN Cur_Out FOR
   select p.pedidoid_vtex
     from vtexorders p
    where p.icprocesado=0 --solo pedidos por procesar
     --devulve de 1 en 1 los pedidos
      and p.id_canal=p_id_canal     
      and rownum = 1;

EXCEPTION
  when others then
      n_pkg_vitalpos_log_general.write(2,
                            'Modulo: ' || v_Modulo || '  Error: ' ||
                            SQLERRM);
      return;
END GetPedidosVtex;

/**************************************************************************************************
* cambia el estado de la tabla vtexorders según parametro de entrada del procedimiento
* 1 procesado OK 2 Procesado con error
* %v 22/01/2021 - ChM
***************************************************************************************************/
PROCEDURE Setvtexorders (p_pedidoid_vtex     IN     vtexorders.pedidoid_vtex%type,
                         p_id_canal          IN     vtexorders.id_canal%type,
                         p_idpedido_pos      IN     vtexorders.idpedido_pos%type,
                         p_icprocesado       IN     vtexorders.icprocesado%type,
                         p_observacion       IN     vtexorders.observacion%type) is

  v_Modulo varchar2(100) := 'PKG_TRANSFERIR_PEDIDOS.SETvtexorders';
  PRAGMA AUTONOMOUS_TRANSACTION;

BEGIN

  update vtexorders vp
     set vp.icprocesado = p_icprocesado,
         vp.idpedido_pos = p_idpedido_pos,
         vp.dtprocesado = sysdate,
         vp.observacion = p_observacion
   where vp.pedidoid_vtex = p_pedidoid_vtex
     and vp.id_canal = p_id_canal;
  commit;
EXCEPTION
  WHEN OTHERS THEN
    n_pkg_vitalpos_log_general.write(1,
                          'Modulo: ' || v_Modulo || '  Error: ' || SQLERRM);
    commit;
END Setvtexorders;

/**************************************************************************************************
* FunciÃ³n que retorna 1 si posee el cliente es Zona Franca y 0 si no
* %v 09/02/2017 - IAquilano
* %v 29/03/2021 - ChM extraida del PKG_CC para ser usada en VTEX
***************************************************************************************************/
FUNCTION fnvalidazonafranca( p_cdtipodireccion  IN direccionesentidades.cdtipodireccion%TYPE ,
                             p_sqdireccion      IN direccionesentidades.sqdireccion%TYPE,
                             p_identidad        IN entidades.identidad%type) RETURN NUMBER
IS

  v_modulo                       Varchar2(100) := 'PKG_TRANSFERIR_PEDIDOS.fnvalidazonafranca';
  v_eszfranca                     integer;

BEGIN
 BEGIN
    select decode(de.cdprovincia,'23      ',1,0) --23 es Tierra del Fuego
    into v_eszfranca
    from direccionesentidades de
    where de.cdtipodireccion= p_cdtipodireccion
    and de.sqdireccion= p_sqdireccion
    and de.identidad= p_identidad
    and de.icactiva=1 ;--Activa

  EXCEPTION WHEN no_data_found THEN
    v_eszfranca := 0;

end;
  return v_eszfranca;

EXCEPTION WHEN OTHERS THEN
   n_pkg_vitalpos_log_general.write(2, 'Modulo: ' || v_modulo || '  Error: ' || Sqlerrm);
   return -1;
END fnvalidazonafranca;

/**************************************************************************************************
* %v 25/06/2020  ChM - versión inicial GET_UNIDADMEDIDABASE
* %v 30/03/2021  ChM - procedimiento tomado del PKG_SLV_ARTICULO sin modificación
***************************************************************************************************/
    function get_unidadmedidabase(p_cdarticulo articulos.cdarticulo%type) return char is
      v_cdUnidad   char(8);
       v_modulo    varchar2(100) := 'PKG_TRANSFERIR_PEDIDOS.GET_UNIDADMEDIDABASE';
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
       return '-1';
    end get_unidadmedidabase;

 /**************************************************************************************************
* %v 19/05/2021 - ChM - devuelve el mlutiplicador del artículo desde la VTEXStock
***************************************************************************************************/
  FUNCTION GETMULTIPLICADOR (P_CDARTICULO ARTICULOS.CDARTICULO%TYPE,
                             p_id_canal   vtexsku.id_canal%type)  RETURN INTEGER IS
    V_MULTIPLICADOR INTEGER:=1;
    BEGIN
    select distinct vs.unitmultiplier
      into V_MULTIPLICADOR
      from vtexsku vs
      where vs.refid = P_CDARTICULO
        and vs.id_canal = p_id_canal;
       RETURN nvl(V_MULTIPLICADOR,1);
  EXCEPTION
  WHEN OTHERS THEN
    RETURN 1;
END  GETMULTIPLICADOR;

/**************************************************************************************************
* devuelve el precio sin IVA del articulo que recibe
* %v 04/05/2021 - ChM
***************************************************************************************************/
  FUNCTION GETPrecioSinIVA (p_cdarticulo articulos.cdarticulo%type,
                            p_cdsucursal sucursales.cdsucursal%type,
                            p_precio     tblprecio.amprecio%type) RETURN NUMBER IS

   v_ImpInt             number;
   v_PorcIva            number;
   v_precioSinIva       number:=p_precio;
   v_signo              number:=1;

  BEGIN
    if p_precio<0 then
      v_signo:=-1;
    else
      v_signo:=1;
    end if;

--Buscar el IVA del artículo
   v_PorcIva := PKG_PRECIO.GetIvaArticulo(p_cdarticulo);

   --busca impuesto interno del articulo
   v_ImpInt  := pkg_impuesto_central.GetImpuestoInterno(p_cdsucursal, p_cdarticulo);

   --calcular precio SIN iva
   v_precioSinIva := (abs(p_precio)-v_ImpInt)/(1+(v_PorcIva/100));

   --suma impuesto interno
   v_precioSinIva := v_precioSinIva + v_ImpInt;

   --redondeo amprecio a dos decimales
   v_precioSinIva := round(v_precioSinIva,2);

 RETURN  v_precioSinIva*v_signo;

 END GETPrecioSinIVA;
 
  /**************************************************************************************************
* %v 11/05/2022 - ChM - inserta el medio de pago del pedido padre y los hijos creados
***************************************************************************************************/
FUNCTION SETMEDIODEPAGO(p_idpedido      pedidos.idpedido%type,
                        p_idmediopago vtexmediodepago.idmediopago%type,
                        p_id_canal      vtexmediodepago.id_canal%type)  RETURN INTEGER IS

BEGIN
  --inserto el pedido padre
  insert into pedidomediodepago
    (idpedido, idmediopago, id_canal)
  values
    (p_idpedido, p_idmediopago, p_id_canal);
    
  --inserto los pedidos hijos
  insert into pedidomediodepago    
    select p.idpedido, p_idmediopago, p_id_canal
      from pedidos p
     where p.transid like '%' || trim(p_idpedido) || '%'
       and p.id_canal = p_id_canal; 
  commit;     
  RETURN 1;
EXCEPTION
  WHEN OTHERS THEN
    RETURN 0;
    
END SETMEDIODEPAGO;
  
/**************************************************************************************************
* Inserta los pedidos de VTEX para AC
* %v 22/01/2021 - ChM
* %v 29/03/2021 - ChM agrego control de zona franca
*                     Agrego idpersonaresponsable del pedido
*                     Ajusto formato de promo lpad('123456',8,'0')
* %v 30/03/2021 - ChM  Agrego logica para manejo de pesables
* %v 17/05/2021 - ChM  si el pedido no tiene idcuenta  busco por mail. Agrego mail en la cabecera
* %v 18/05/2021 - ChM ajusto dividir pedido saco tx_pedidos_particionar
* %v 19/05/2021 - ChM agrego multiplicador del artículo
* %v 01/07/2021 - ChM Agregro P_OK para avisar al servicio si el pedido inserto OK
                       así: P_OK = 0 insertado correctamente
                            P_OK = 1  No pudo insertar
* %v 14/07/2021 - ChM Ajusto para que el id_pedido_POS sea igual al id_pedidoVtex
* %v 15/07/2021 - ChM Ajusto para buscar promo por cdpromo
* %v 26/10/2021 - ChM en coordinación con corebiz se elimina la busqueda del cliente por id_cuenta  solo mail  
* %v 21/11/2021 - ChM calculo e inserto los detalles de las promociones por solicitud de reportes auditoria
* %v 04/11/2021 - ChM agrego marca de oferta en observación del detalle pedido
* %v 10/03/2022 - ChM si el pedido no tiene  mail. Agrego buscar por id cuenta
* %v 11/05/2022 - ChM ajusto medio de pago
* %v 01/06/2022 - ChM mejoro la suma del detalle pedido 
* %v 04/08/2022 - ChM si es canal VE busco detalle si TE o VE el agente para canal del pedido
* %v 18/08/2022 - ChM mejoro el monto del documento
* %v 31/08/2022 - ChM ajusto sales chanel para adecuar precios sin iva FALTA VERIFICAR LOS PRECIOS VIGENTES SIN IVA CON TBLPRECIO O VTEXPRICE
***************************************************************************************************/
PROCEDURE InsertarPedidoPOS (p_pedidoid_vtex       IN  vtexorders.pedidoid_vtex%type,
                             p_id_canal            IN  vtexorders.id_canal%type,
                             p_cabecera            IN OUT  varchar2,                             
                             p_detalle             IN  arr_refId,
                             p_ok                  OUT integer,
                             p_politicaIVA         IN integer default 0) IS

  v_modulo                   varchar2(100) := 'PKG_TRANSFERIR_PEDIDOS.InsertarPedidoPOS';
  v_iddoctrx                 documentos.iddoctrx%type;
  v_cdsucursal               vtexsellers.cdsucursal%type:=null;
  v_id_canal                 vtexsellers.id_canal%type:=null;
  v_id_canal_pedido          vtexsellers.id_canal%type:='CO';
  v_identidad                entidades.identidad%type;
  v_identidadReal            entidades.identidad%type;
  v_cdcuit                   entidades.cdcuit%type;
  v_idvendedor               personas.idpersona%type;
  v_idcomisionista           entidades.identidad%type;
  v_icorigen                 pedidos.icorigen%type:=4;--0-Normal 1-Especificos 2-viejos sin identificar  3-Salon 4-Ecommerce
  v_idcuenta                 tblcuenta.idcuenta%type;
  v_cdsituacioniva           pedidos.cdsituacioniva%type;
  v_qtmateriales             integer:=0;
  v_fechapedido              pedidos.dtaplicacion%type;
  v_ammonto                  pedidos.ammonto%type:=0;
  v_idpedido                 pedidos.idpedido%type;
  v_icretiraensucu           pedidos.icretirasucursal%type:=0;
  v_cdtipodireccion          tbldireccioncuenta.cdtipodireccion%type:=null;
  v_sqdireccion              tbldireccioncuenta.sqdireccion%type:=null;
  v_icestadosistema          pedidos.icestadosistema%type:=0; --listo para Validar en PKG_PEDIDO_CENTRAL
  v_dsreferencia             pedidos.dsreferencia%type:=null; --OOOOJJJJOOOOO dsreferencia de CF se va null porque PKG_PEDIDO_CENTRAL validar le asignará DNI de CF
  v_dtentrega                pedidos.dtentrega%type;
  v_zonafranca               integer;
  v_idpersonaresponsable     pedidos.idpersonaresponsable%type:=null;
  v_pedidoid_vtex_canal      vtexorders.pedidoid_vtex%type:=p_pedidoid_vtex||p_id_canal;
    
  --items
  v_cdarticulo               vtexproduct.refid%type;
  v_price                    vtexprice.pricepl%type;
  v_quantity                 vtexstock.qtstock%type;  
  v_idpromo_vtex             vtexpromotion.id_promo_vtex%type;
  v_cdpromo                  vtexpromotion.cdpromo%type;
  v_qtpiezas                 detallepedidos.qtpiezas%type:=0;
  v_vluxb                    detallepedidos.vluxb%type;
  v_vlcantidad               detallepedidos.qtunidadpedido%type;
  v_cdunidadmedida           detallepedidos.cdunidadmedida%type;
  v_undpesable               detallepedidos.cdunidadmedida%type;
  v_dsarticulo               detallepedidos.dsarticulo%type;
  v_icresppromo              detallepedidos.icresppromo%type;
  v_ampreciounitario         detallepedidos.ampreciounitario%type;
  v_amlinea                  detallepedidos.amlinea%type;
  v_observacion              observacionespedido.dsobservacion%type;
  v_limitedividepedido       number:= n_pkg_vitalpos_core.GETVLPARAMETRO('MAX_PEDIDO_CF','General');
  v_dsobservacion            detallepedidos.dsobservacion%type;
  v_idmediopago              vtexmediodepago.idmediopago%type;

   -- promociones
   Type reg_type Is Record( TipoResultado                                Varchar2(1)     ,
                           cdArticulo              detallemovmateriales.cdarticulo%TYPE ,
                           dsArticulo                                   Varchar2(1000)  , -- Descripcion de la promoción
                           qtUnidades              detallemovmateriales.qtunidadmov%TYPE, -- Cantidad de unidades compradas (si es un pesable es la cantidad de piezas)
                           cdUnidaMedida                                Varchar2(2)     ,
                           cdPromo                 detallemovmateriales.cdpromo%TYPE    ,
                           PorcentajeIva  impuestosdetallemovmateriales.vltasa%TYPE     ,
                           amImporteTotal          detallemovmateriales.amlinea%TYPE    );
                           
   v_reg                      reg_type;                        
   v_Resultado                cursor_type;
   v_sqdetalle                detallepedidos.sqdetallepedido%type:=1;   
   v_amlineasiniva            detallepedidos.ampreciounitario%type;
   v_totalPEDI                pedidos.ammonto%type:=0;

BEGIN
  --REGRESO PARA PODER INSERTAR VARIAS VECES 08092021
  v_pedidoid_vtex_canal:=SYS_GUID();
   p_ok:=1;
   n_pkg_vitalpos_log_general.write(1,'comienza insertar pos: '||v_pedidoid_vtex_canal);

  /*o	Texto del 1 + 40  el idCuenta  (cliente)

    o	Texto 41 + 1 marca de Consumidor Final. 1 CF 0 Cliente

    o	Texto del 42 + 40 idaddress

    o	Texto del 82 + 10 cddireccion sqdireccion

    o	Texto del 92 + 30 fecha de creacion del pedido dd/mm/yyyyhh:mm:ss

    o	Texto del 122 + 128 email
    
    •	Texto del 250 + 5  medio de pago    
    
    •	Texto del 255 + 100  observaciones del pedido 

  */ 
          --ChM si el pedido no tiene idcuenta  busco por mail
           begin
               select vc.cdsucursal,
                      vc.id_canal,
                      cu.identidad,
                      cu.identidad,
                      vc.cuit,
                      decode (vc.id_canal,'VE',vc.idagent,null) idvendedor,
                      decode (vc.id_canal,'CO',vc.idagent,null) idcomi,
                      vc.id_cuenta
                 into v_cdsucursal,
                      v_id_canal,
                      v_identidad,
                      v_identidadReal,
                      v_cdcuit,
                      v_idvendedor,
                      v_idcomisionista,
                      v_idcuenta
                from vtexclients vc,
                     tblcuenta   cu
                where vc.email=trim(substr(p_cabecera,122,128))
                  and vc.id_cuenta = cu.idcuenta;
             exception
               when others then
                  begin
                     select vc.cdsucursal,
                            vc.id_canal,
                            cu.identidad,
                            cu.identidad,
                            vc.cuit,
                            decode (vc.id_canal,'VE',vc.idagent,null) idvendedor,
                            decode (vc.id_canal,'CO',vc.idagent,null) idcomi,
                            vc.id_cuenta
                       into v_cdsucursal,
                            v_id_canal,
                            v_identidad,
                            v_identidadReal,
                            v_cdcuit,
                            v_idvendedor,
                            v_idcomisionista,
                            v_idcuenta
                      from vtexclients vc,
                           tblcuenta   cu
                      where vc.id_cuenta=trim(substr(p_cabecera,1,40))
                        and vc.id_cuenta = cu.idcuenta;
                   exception
                     when others then
                     	 Setvtexorders (p_pedidoid_vtex,p_id_canal,null,2,'No es posible recuperar datos de cabecera: '||p_cabecera);
                       RETURN;
                 end;
            end;
            
   --obtengo v_cdtipodireccion, v_sqdireccion si viene pickup retira en sucursal
   if trim(substr(p_cabecera,82,10))='pickup' then
     v_icretiraensucu := 1;
     --busca la dirección comercial del cliente
     begin
        select de.cdtipodireccion,
               max(de.sqdireccion)sqdireccion
          into v_cdtipodireccion,
               v_sqdireccion
          from direccionesentidades de
         where de.identidad = v_identidadReal
           --ubico la dirección comercial del cliente activa
           and de.cdtipodireccion = 2
           and de.icactiva = 1
      group by
               de.cdtipodireccion;
     exception
       when others then
         --se pasa cero para que el validar pedidos lo resuelva por datos incompletos
         v_cdtipodireccion:='00';
         v_sqdireccion:=0;
     end;

   else
       v_cdtipodireccion:=nvl(trim(substr(p_cabecera,82,8)),'00');
       v_sqdireccion:=nvl(to_number(trim(substr(p_cabecera,90,2))),0);
       v_icretiraensucu := 0;
  end if;


     --verifico si es canal NO error no se puede recuperar el pedido
    if v_id_canal = 'NO' then
      Setvtexorders (p_pedidoid_vtex,p_id_canal,null,2,'cliente sin CANAL asociado. No es posible recuperar datos de cabecera: '||p_cabecera);
      RETURN;
    end if;
    --asigno v_idpersonaresponsable si es canal CO null en otro caso id del vendedor o telemarketing
    if v_id_canal = 'CO' then
       v_idpersonaresponsable:=null;
    else
      v_idpersonaresponsable:=v_idvendedor;
    end if;

    --Averiguo la Situacion de IVA 1 si es CF o cliente registrado
    if trim(substr(p_cabecera,41,1)) = 1 then
      v_cdsituacioniva := '2';
      --si es CF identidad IdCfReparto
      v_identidad:='IdCfReparto';
    else
      v_cdsituacioniva := '1';
    end if;
     --Averiguo la cantidad de articulos distintos que tiene el pedido
    v_qtmateriales:=p_detalle.Count;
    if v_qtmateriales = 0 then
       Setvtexorders (p_pedidoid_vtex,p_id_canal,null,2,'Pedido sin articulos: '||trim(substr(p_cabecera,1,40)));
               RETURN;
    end if;
    v_qtmateriales:=0;    
    
    --Averiguo el monto total del pedido
    IF (p_detalle(1) IS NOT NULL and LENGTH(TRIM(p_detalle(1)))>1) THEN
       FOR i IN 1 .. p_detalle.Count LOOP
          v_cdarticulo:=trim(substr(p_detalle(i),1,8));
          v_price:=to_number(trim(substr(p_detalle(i),9,20)))/100;
          v_quantity:=to_number(trim(substr(p_detalle(i),29,6))); --la cantidad en VTEX viene solo en unidades UN
          v_icresppromo:=to_number(substr(p_detalle(i),75,1));
          --agrego multiplicador del artículo
          v_quantity:=v_quantity*GETMULTIPLICADOR(v_cdarticulo,v_id_canal);
          --si la politica es 1 precio se saca el IVA
          if p_politicaIVA=1 then
            -- obtengo el precio unitario sin iva
            v_ampreciounitario:= getpreciosiniva(v_cdarticulo,v_cdsucursal,v_price);
          else
            v_ampreciounitario:=v_price;  
          end if;
          --valor de la linea
          v_ammonto:=v_ammonto+(v_quantity*v_ampreciounitario);
          --solo líneas de artículos
          if v_icresppromo=0 then
            v_qtmateriales:=v_qtmateriales+1;
          end if;
       END LOOP;
    ELSE
     Setvtexorders (p_pedidoid_vtex,p_id_canal,null,2,'No existen artículos en el pedido: '||v_pedidoid_vtex_canal);
     rollback;
     RETURN;
   END IF;
   --extrae la fecha del pedido
   v_fechapedido:= to_date(trim(substr(p_cabecera,92,30)),'dd/mm/yyyy hh24:mi:ss');
   --dos dias despues de la fecha del pedido
   v_dtentrega:=v_fechapedido+2;
    --observaciones del pedido
   v_observacion:= trim(substr(p_cabecera,255,100));

    --si es CF y ammomto superior al limite se marca para dividir pedido
    if v_cdsituacioniva = 2 and v_ammonto > v_limitedividepedido then
         v_icestadosistema:=-1; --pedido preparado para dividir
    end if;

  --busca la marca de zona franca
   v_zonafranca:=fnvalidazonafranca( v_cdtipodireccion, v_sqdireccion,v_identidad);
   if v_zonafranca=-1 then
      Setvtexorders (p_pedidoid_vtex,p_id_canal,null,2,'Error al ubicar Zona Franca'||v_identidad);
     rollback;
     RETURN;
   end if;

 --inserto datos en documentos con tipo de comprobante PEDI
  INSERT INTO documentos
      (iddoctrx           , idmovmateriales       , idmovtrx                         , cdsucursal     , identidad        , cdcomprobante ,
       cdestadocomprobante, idpersona             , sqcomprobante                    , sqsistema      , dtdocumento      , amdocumento   ,
       icorigen           , amnetodocumento       , qtreimpresiones                  , amrecargo      , cdtipocomprobante, dsreferencia  ,
       icspool            , iccajaunificada       , cdpuntoventa                     , idcuenta       , identidadreal    , idtransaccion )
  VALUES
      (sys_guid()         , NULL                  , NULL                             , v_cdsucursal   , v_identidad      , 'PEDI'        ,
       '1'                , NULL                  , OBTENERCONTADORNUMCOMPROB('PEDI'), CONTADORSISTEMA, v_fechapedido    , v_ammonto     ,
       v_icorigen         , v_ammonto             , 0                                , 0              , NULL             , v_dsreferencia,
       NULL               , NULL                  , NULL                             , v_idcuenta     , v_identidadReal  , NULL          )
  RETURNING iddoctrx INTO v_iddoctrx;

  IF  SQL%ROWCOUNT = 0  THEN      --valida insert
      Setvtexorders (p_pedidoid_vtex,p_id_canal,null,2,'Error al insertar documento del pedido VTEX '||v_identidad);
     rollback;
     RETURN;
    END IF;
   -- 04/08/2022 si es canal VE busco detalle si TE o VE para pedido
        if v_id_canal ='VE' then
         begin
               select 'VE'
                 into V_id_canal_pedido
                 from carteraclientes c,
                      personas        p,
                      rolespersonas   rp       
                where p.idpersona=rp.idpersona    
                   --solo empleados vendedores
                  and rp.cdrol = 11   
                   --solo personas activas
                  and p.icactivo = 1
                  --solo relaciones activas
                  and c.icactivo = 1
                  and c.idpersona = p.idpersona
                  and c.identidad = v_identidad
                  and c.idpersona = v_idvendedor
                  and rownum = 1;               
           EXCEPTION
                 WHEN OTHERS THEN
                   begin
                     select 'TE'
                       into V_id_canal_pedido
                       from carteraclientes c,
                            personas        p,
                            rolespersonas   rp       
                      where p.idpersona=rp.idpersona    
                         --solo empleados TELEMARKETER
                        and rp.cdrol = 6   
                         --solo personas activas
                        and p.icactivo = 1
                        --solo relaciones activas
                        and c.icactivo = 1
                        and c.idpersona = p.idpersona
                        and c.identidad = v_identidad
                        and c.idpersona = v_idvendedor
                        and rownum = 1;   
                   EXCEPTION
                      WHEN OTHERS THEN                                          
                         V_id_canal_pedido:='VE';
                  end;   
         end;
       end if;
       
  --Inserto el registro cabecera en la tabla pedidos (uso el mismo transid de la transaccion de VTEX)
  insert into pedidos
  (idpedido          , identidad       , idpersonaresponsable  , dspersona  , iddoctrx        , qtmateriales  , dsreferencia     ,
   cdcondicionventa  , cdsituacioniva  , icestadosistema       , cdlugar    , dtaplicacion    , dtentrega     , cdtipodireccion  ,
   idvendedor        , sqdireccion     , ammonto               , icorigen   , idcomisionista  , id_canal      , transid          ,
   icretirasucursal  , iczonafranca  )
  values
  (v_pedidoid_vtex_canal   , v_identidad     , v_idpersonaresponsable , null        , v_iddoctrx      , v_qtmateriales ,v_dsreferencia      ,
   null              , v_cdsituacioniva, v_icestadosistema      , 3           , v_fechapedido   , v_dtentrega    , v_cdtipodireccion ,
   v_idvendedor      , v_sqdireccion   , v_ammonto              , v_icorigen  , v_idcomisionista, v_id_canal_pedido , p_pedidoid_vtex   ,
   v_icretiraensucu  , v_zonafranca  )
   RETURNING idpedido  INTO v_idpedido;

   IF  SQL%ROWCOUNT = 0  THEN      --valida insert
      Setvtexorders (p_pedidoid_vtex,p_id_canal,null,2,'Error al insertar idpedido POs del pedido VTEX'||v_pedidoid_vtex_canal);
     rollback;
     RETURN;
    END IF;

   --isertar los items del pedido si el arreglo trae datos
    IF (p_detalle(1) IS NOT NULL and LENGTH(TRIM(p_detalle(1)))>1) THEN
       FOR i IN 1 .. p_detalle.Count LOOP

          --o  Texto del 1 + 8 refId
          --o  Texto del 9 + 20 price  (2 últimos dígitos decimal)
          --o  Texto del 29 + 6 quantity
          --o  Texto del 35 + 40  identifier (promo id VTEX) si no existe no se envía.
          --o  Texto del 75 + 1 marca de promo (1) si la línea es promo (0) si la línea es producto
        --  p_detalle(1):='0158777 4669                100                                           0';
          v_cdarticulo:=trim(substr(p_detalle(i),1,8));
          v_price:=to_number(trim(substr(p_detalle(i),9,20)))/100;
          v_quantity:=to_number(trim(substr(p_detalle(i),29,6))); --la cantidad en VTEX viene solo en unidades UN o kg
          --ChM 15/07/2021 ahora llega el cdpromo no el idpromo_VTEX
          v_idpromo_vtex:=rpad(trim(substr(p_detalle(i),35,40)),40,' ');
          v_icresppromo:=to_number(substr(p_detalle(i),75,1));
          v_qtpiezas:=0;
          --agrego multiplicador del artículo
          v_quantity:=v_quantity*GETMULTIPLICADOR(v_cdarticulo,v_id_canal);
          -- busco el  UxB del articulo
          v_vluxb:=nvl(n_pkg_vitalpos_materiales.GetUxB(v_cdarticulo),0);

           -- obtengo el precio unitario sin iva
          --si la politica es 1 precio se saca el IVA
          if p_politicaIVA=1 then 
             v_ampreciounitario:= getpreciosiniva(v_cdarticulo,v_cdsucursal,v_price);
          else
             v_ampreciounitario:=v_price;
          end if;   
          --valor de la linea
          v_amlinea:= v_quantity*v_ampreciounitario;

          --si es la linea de promo v_vluxb es 1
           if v_icresppromo = 1 then
                v_vluxb:=1;
                v_dsobservacion:='PR';
            end if;

          --si la división es exacta y vluxb > 1 se pasa BTO sino UN, además excluyo lineas de promo siempre en UN
          if v_vluxb > 1 and mod(v_quantity,v_vluxb) = 0 and v_icresppromo <> 1 then
            v_vlcantidad:=v_quantity/v_vluxb;
            v_cdunidadmedida:='BTO';
          else
            v_vlcantidad:=v_quantity;
            v_cdunidadmedida:='UN';
          end if;

          --verifica si es un articulo pesable
          v_undpesable:=trim(get_unidadmedidabase(v_cdarticulo));
          if trim(v_undpesable)='-1' then
               Setvtexorders (p_pedidoid_vtex,p_id_canal,null,2,'Error al intentar recuperar unidad de medida del articulo: '||v_cdarticulo);
               rollback;
               RETURN;
          else
               if v_undpesable in ('KG','PZA') then
                v_qtpiezas:=to_number(trim(substr(p_detalle(i),29,6))); --la cantidad en VTEX viene solo en unidades UN o kg
                 v_cdunidadmedida:='KG';
               end if;
          end if;

          --busco el cdpromo
          begin
            --verifica si existe cdpromo
            if LENGTH(TRIM(v_idpromo_vtex))>1 then
              --OJO PARA PRUEBA NO BUSCO PROMO   QUITAR!!!!!!!!!
              -- v_cdpromo:=1234567;
                select
              distinct lpad(trim(vp.cdpromo),8,'0')
                  into v_cdpromo
                  from vtexpromotion vp
                 where vp.cdpromo = to_number(TRIM(v_idpromo_vtex))
                   and vp.id_canal = v_id_canal;
            else
              v_cdpromo:=null;
            end if;
            exception
              when others then
               Setvtexorders (p_pedidoid_vtex,p_id_canal,null,2,'Error al intentar recuperar promoción artículo: '||v_cdarticulo||'cdpromo '||v_idpromo_vtex);
               rollback;
               RETURN;
          end;
          --busco la descripción del producto
          begin
             if LENGTH(TRIM(v_cdarticulo))>1 then
               select substr(vp.name,1,50)
                 into v_dsarticulo
                 from vtexproduct vp
                where vp.refid = v_cdarticulo
                  and vp.id_canal = v_id_canal;
              else
                v_dsarticulo:=null;
             end if;
            exception
              when others then
                Setvtexorders (p_pedidoid_vtex,p_id_canal,null,2,'Error al intentar recuperar descripción del artículo: '||v_cdarticulo);
               rollback;
               RETURN;
          end;
          --agrego marca de oferta
          v_dsobservacion:= GetmarcaOferART (v_cdarticulo,v_fechapedido,v_cdsucursal,v_id_canal);
          insert into detallepedidos
          (idpedido           , sqdetallepedido , cdunidadmedida   , cdarticulo      , qtunidadpedido, qtunidadmedidabase  , qtpiezas     ,
           ampreciounitario   , amlinea         , vluxb            , dsobservacion   , icresppromo   , cdpromo             , dsarticulo   )
          values
          (v_idpedido         , i               , v_cdunidadmedida , v_cdarticulo    , v_vlcantidad  , v_quantity          , v_qtpiezas   ,
           v_ampreciounitario , v_amlinea       , v_vluxb          , v_dsobservacion , v_icresppromo , v_cdpromo           , v_dsarticulo);

           IF  SQL%ROWCOUNT = 0  THEN      --valida insert
             Setvtexorders (p_pedidoid_vtex,p_id_canal,null,2,'Error al insertar detalle del pedido VTEX'||v_pedidoid_vtex_canal||'cdarticulo: '||v_cdarticulo);
             rollback;
             RETURN;
            END IF;

       END LOOP;

     ELSE
     Setvtexorders (p_pedidoid_vtex,p_id_canal,null,2,'No existen artículos en el pedido: '||v_idpedido);
     rollback;
     RETURN;
     END IF;


  -- Inserto un registro en tx_pedidos_insert para que el pedido sea considerado en la cola de pedidos del SLV
  insert into tx_pedidos_insert
  (iddoctrx  , idpedido          , cdsucursal  , cdcuit  )
  values
  (v_iddoctrx, v_idpedido        , v_cdsucursal, v_cdcuit);

  IF  SQL%ROWCOUNT = 0  THEN      --valida insert
   	 Setvtexorders (p_pedidoid_vtex,p_id_canal,null,2,'Error al insertar tx_pedidos_insert del pedido VTEX'||v_pedidoid_vtex_canal);
     rollback;
     RETURN;
    END IF;
    --valido si es observacion de COMI debe ser numerica
    if v_id_canal='CO' then
      if REGEXP_INSTR(trim(substr(v_observacion,instr(v_observacion,'-')+1,100)),'[[:alpha:]]')<>0 then
             pkg_control.GrabarMensaje(sys_guid(),
                                                null,
                                                sysdate,
                                                'Pedido de Comisionista sin ZONA',
                                                'id_pedido_VTEX= ' || p_pedidoid_vtex,
                                                0);
            v_observacion:='99999999';                                                                                   
        else
          v_observacion:=trim(substr(v_observacion,instr(v_observacion,'-')+2,100));
      end if;
    end if;  
  -- Inserto las observaciones
  if length(v_observacion)>=1 then
    insert into observacionespedido
               (idpedido, dsobservacion)
    values
               (v_idpedido, v_observacion);

     IF  SQL%ROWCOUNT = 0  THEN      --valida insert
   	 Setvtexorders (p_pedidoid_vtex,p_id_canal,null,2,'Error al insertar observaciones del pedido VTEX'||v_pedidoid_vtex_canal);
     rollback;
     RETURN;
    END IF;
  end if;
  
    -- calculo e inserto los detalles de las promociones
    pkg_promo.MotorPromociones_PEDI(v_idpedido,v_Resultado);
    
       --max  sqdetallepedido
        select max(td.sqdetallepedido)+1
          into v_sqdetalle
          from detallepedidos td
         where td.idpedido = v_idpedido;
         
    --Recorrer las promociones y hacer insert o update
  Loop
     Fetch v_Resultado
      Into v_reg;
     Exit When v_Resultado%Notfound;
     
     If v_reg.TipoResultado = 'C' Then
        --Condición
        Update detallepedidos dp
           Set dp.cdpromo    = to_char(to_number(v_reg.cdPromo))
         Where dp.cdarticulo = v_reg.cdArticulo
           And dp.idpedido = v_idpedido
           And dp.icresppromo = 0;
     End If;
     
     If v_reg.TipoResultado = 'A' Then

        v_dsarticulo    := substr('Promo ' || v_reg.dsarticulo, 1, 50);        
        v_amlineasiniva := round(v_reg.amImporteTotal, 3);
              
        --Accion
        insert into detallepedidos
          (idpedido           , sqdetallepedido , cdunidadmedida   , cdarticulo      , qtunidadpedido, qtunidadmedidabase  , qtpiezas     ,
           ampreciounitario   , amlinea         , vluxb            , dsobservacion   , icresppromo   , cdpromo             , dsarticulo   )
          values
          (v_idpedido         , v_sqdetalle, v_reg.cdUnidaMedida , v_reg.cdArticulo, v_reg.qtUnidades , v_reg.qtUnidades, 0,
           (v_amlineasiniva/v_reg.qtUnidades) , v_amlineasiniva      , 1         , 'PR' , 1 , to_char(to_number(v_reg.cdPromo)), v_dsarticulo);

           IF  SQL%ROWCOUNT = 0  THEN      --valida insert
             Setvtexorders (p_pedidoid_vtex,p_id_canal,null,2,'Error al insertar PROMO en detalle del pedido VTEX'||v_pedidoid_vtex_canal||'cdarticulo: '||v_reg.cdArticulo);
             rollback;
             RETURN;
            END IF;                    
     End If;
     v_sqdetalle:=v_sqdetalle+1;    
  End Loop;
  
    --mejoro la suma del detalle pedido ChM 01/06/2022
  select sum(nvl(dp.amlinea,0))
    into v_totalPEDI 
    from DETALLEPEDIDOS dp
   where dp.idpedido = v_idpedido;
   --ACTUALIZAR EL MONTO TOTAL DEL PEDIDO con descarga de promo
   update pedidos p 
      set p.ammonto=v_totalPEDI
    where p.idpedido=v_idpedido;
     -- %v 18/08/2022 - ChM mejoro el monto del documento
   update documentos d
      set d.amdocumento=v_totalPEDI,
          d.amnetodocumento=v_totalPEDI
    where d.iddoctrx=v_iddoctrx; 
        
  Setvtexorders (p_pedidoid_vtex,p_id_canal,v_idpedido,1,'Insertado en POS Correctamente!');
  p_ok:=0;
  COMMIT;  
  
    --si es CF y ammomto superior al limite llamo al dividir pedido
    if v_cdsituacioniva = 2 and v_ammonto > v_limitedividepedido then
      IF DividirPedidos(v_idpedido) = 0 then
          Setvtexorders (p_pedidoid_vtex,p_id_canal,v_idpedido,3,'Error al dividir pedido. Insertado en POS Correctamente!!');
      End If;
    end if;
    
    --tomo el medio de pago de la cabecera
    v_idmediopago:=nvl(to_number(trim(substr(p_cabecera,250,5))),0);
    If v_idmediopago=0 then
       Setvtexorders (p_pedidoid_vtex,p_id_canal,v_idpedido,3,'Error pedido sin medio de pago. Insertado en POS Correctamente!!');
    End If;
    
    --inserto el medio de pago
    --04/08/2022 envio el canal real del pedido
    If SETMEDIODEPAGO(v_idpedido,v_idmediopago,v_id_canal_pedido)=0 Then
       Setvtexorders (p_pedidoid_vtex,p_id_canal,v_idpedido,3,'Error al insertar medio de pago. Insertado en POS Correctamente!!');
    End If;  
    
  EXCEPTION
    WHEN OTHERS THEN
      Setvtexorders (p_pedidoid_vtex,p_id_canal,null,2, 'Modulo: ' || v_Modulo || '  Error: ' ||SQLERRM);
   	  ROLLBACK;
      RETURN;
END InsertarPedidoPOS;
/**************************************************************************************************
* %v 18/05/2021 - ChM convierte un pedido de cliente  a CF
***************************************************************************************************/
PROCEDURE ConvertirPedidoCF (p_idpedido    IN pedidos.idpedido%type,
                             p_ok          OUT INTEGER,
                             p_error       OUT VARCHAR2) is

  v_Modulo               varchar2(100) := 'PKG_TRANSFERIR_PEDIDOS.ConvertirPedidoCF';
  v_limitedividepedido   number:= n_pkg_vitalpos_core.GETVLPARAMETRO('MAX_PEDIDO_CF','General');
 -- v_idpedido             pedidos.idpedido%type:='%'||trim(p_idpedido)||'%';
  v_pedido               pedidos%rowtype;
  v_icestadosistema      pedidos.icestadosistema%type:=0;

BEGIN
  --busca el pedido que recibe como parametro
  begin
    select p.*
      into v_pedido
      from pedidos p
     where p.idpedido= p_idpedido;

     --verifica si ya es consumidor final error
     if trim(v_pedido.identidad) =trim('IdCfReparto') then
       p_ok    := 0;
       p_error := '  Error: Pedido ya es de Consumidor Final';
       return;
     else
       --si se pasa del limite dividir pedido
       if v_pedido.ammonto > v_limitedividepedido then
         v_icestadosistema:=-1;
       end if;

       update pedidos p
          set p.identidad = trim('IdCfReparto'),
              p.icestadosistema = v_icestadosistema
        where p.idpedido = p_idpedido;
       update documentos d
          set d.identidad = trim('IdCfReparto')
        where d.iddoctrx = v_pedido.iddoctrx;
     end if;

  exception
    when others then
       p_ok    := 0;
       p_error := '  Error: Pedido inexistente';
       return;
  end;
       --si se pasa del limite dividir pedido
       if  v_icestadosistema =-1 then
        If DividirPedidos(p_idpedido) = 0 Then
             n_pkg_vitalpos_log_general.write(1,
                          'Modulo: ' || v_Modulo || '  Error: no es posible dividir pedido' || SQLERRM);
             p_ok    := 0;
             p_error := '  Error: no es posible dividir pedido.'|| SQLERRM;
             rollback;
             return;
        End If;
       end if;
   p_ok    := 1;
   p_error := '';
  commit;
EXCEPTION
  WHEN OTHERS THEN
    n_pkg_vitalpos_log_general.write(1,
                          'Modulo: ' || v_Modulo || '  Error: ' || SQLERRM);

    p_ok    := 0;
    p_error := '  Error: '|| SQLERRM;
    rollback;
    return;
END ConvertirPedidoCF;
/***************************************************************************************************
* %v 02/02/2021 - ChM
* %v 18/05/2021 - ChM ajusto dividir pedido saco tx_pedidos_particionar
***************************************************************************************************/
FUNCTION DividirPedidos(p_idpedido    IN pedidos.idpedido%type) return integer is

  v_Modulo               varchar2(100) := 'PKG_TRANSFERIR_PEDIDOS.DividirPedidos';

  v_ok                   integer;
  v_error                varchar2(300);
  v_limitedividepedido   number:= n_pkg_vitalpos_core.GETVLPARAMETRO('MAX_PEDIDO_CF','General');
  v_idpedido             pedidos.idpedido%type:='%'||trim(p_idpedido)||'%';

BEGIN
     pkg_dividir_pedido.dividir(p_idpedido, v_limitedividepedido,v_ok, v_error);

      if v_ok <> 1 then
            n_pkg_vitalpos_log_general.write(2, 'Modulo: '||v_modulo||'  Error al dividir pedido: ' || SQLERRM);
            ROLLBACK;
            return 0;
      end if;
    -- Si se particiona, se pasa el pedido padre a 0.
    --Dividirpedido lo elimina de tx_pedidos_insert así no se transfiere a las sucursales
    --y lo marca como PEDREF
    update pedidos set icestadosistema = 0  where idpedido = p_idpedido;
    --una vez que tengo todas los pedidos divididos, modifico valor para enviar a tiendas (el PKG_DIVIDIR inserta a todos los hijos en TX_PEDIDOS_INSERT).
    BEGIN
       update pedidos p
          set p.icestadosistema = 0
        where p.idpedido in (select idpedido from TX_PEDIDOS_INSERT)
          and p.icestadosistema = -1
          and p.transid like v_idpedido;
    EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2, 'Modulo: '||v_modulo||'  Error al actualizar pedidos de -1: ' || SQLERRM);
      ROLLBACK;
      return 0;
    END;
  commit;
  return 1;
EXCEPTION
  WHEN OTHERS THEN
    n_pkg_vitalpos_log_general.write(1,
                          'Modulo: ' || v_Modulo || '  Error: ' || SQLERRM);
    rollback;
    return 0;
END DividirPedidos;
/**************************************************************************************************
* Devuelve si el articulo tiene oferta vigente para la fecha del parametro
* %v 04/11/2021 - ChM
* %v 11/04/2022 - ChM agrego buscar primero en vtexpricespecial
***************************************************************************************************/
FUNCTION GetmarcaOferART ( p_cdarticulo   articulos.cdarticulo%type,      
                           p_fecha        tblprecio.dtvigenciadesde%type,
                           p_cdsucursal   vtexprice.cdsucursal%type,
                           p_id_canal     vtexprice.id_canal%type ) return varchar2 IS
                           
  v_marca         integer:=0;
  
BEGIN
         --busca en vtexpricespecial si la oferta del pedido esta vigente para devolver marca
        select count(*)
          into v_marca 
          from vtexpricespecial vp
         where vp.refid = p_cdarticulo
           and vp.cdsucursal = p_cdsucursal
           and vp.id_canal = p_id_canal           
           and p_fecha between vp.dtfromof and vp.dttoof;
        if v_marca = 0 then    
           --busca en vtexprice si la oferta del pedido esta vigente para devolver marca
            select count(*)
              into v_marca 
              from vtexprice vp
             where vp.refid = p_cdarticulo
               and vp.cdsucursal = p_cdsucursal
               and vp.id_canal = p_id_canal
               and vp.priceof is not null
               and p_fecha between vp.dtfromof and vp.dttoof;   
        end if;        
       if v_marca = 0 then
          --busca en tblprecio la oferta vigente para la marca
            select count(*)
              into v_marca 
              from tblprecio p
             where p.cdarticulo = p_cdarticulo
               and p.cdsucursal = p_cdsucursal
               and p.id_canal = p_id_canal
               and p.id_precio_tipo = 'OF'
               and p_fecha between p.dtvigenciadesde and p.dtvigenciahasta;        
       end if;
       if v_marca = 0 then        
         return null;
       else 
         return 'OF';
       end if;
       
EXCEPTION
    WHEN OTHERS THEN 
      return null;
END GetmarcaOferART;

/**************************************************************************************************
* pasa a cero los pedidos de estado 2 para reprocesar en job
* %v 16/11/2021 - ChM
* %v 14/04/2022 - ChM agrego 9999 para mejorar el monitor de control
* %v 16/04/2022. ChM elimino el ajsute dañe un pedidos 1224691091691-01
***************************************************************************************************/
PROCEDURE JobPedidosVtex  IS
BEGIN
  update vtexorders o 
     set o.icprocesado=0
   where o.icprocesado=2
     and o.icrevisadopos is null-- or o.icrevisadopos=9999
     ;
  COMMIT;   
EXCEPTION
  when others then
      return;
END JobPedidosVtex;

END;
/
