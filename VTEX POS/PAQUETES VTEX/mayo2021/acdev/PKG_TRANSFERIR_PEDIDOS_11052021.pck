CREATE OR REPLACE PACKAGE PKG_TRANSFERIR_PEDIDOS Is

type cursor_type Is Ref Cursor;

TYPE arr_refid IS TABLE OF VARCHAR(100) INDEX BY PLS_INTEGER;

procedure Trae_pedidos;
procedure Trae_Prepedidos;
PROCEDURE GetPedidosVtex (Cur_Out Out Cursor_Type);

PROCEDURE InsertarPedidoPOS (p_pedidoid_vtex       IN  vtexorders.pedidoid_vtex%type,
                             p_cabecera            IN OUT varchar2,
                             p_detalle             IN  arr_refId);

PROCEDURE Setvtexorders (p_pedidoid_vtex    IN     vtexorders.pedidoid_vtex%type,
                          p_idpedido_pos     IN     vtexorders.idpedido_pos%type, 
                          p_icprocesado      IN     vtexorders.icprocesado%type,
                          p_observacion      IN     vtexorders.observacion%type);                             
                              
FUNCTION DividirPedidos return integer;                              

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
***************************************************************************************************/
PROCEDURE GetPedidosVtex (Cur_Out Out Cursor_Type) IS
  
  v_modulo        varchar2(100) := 'PKG_TRANSFERIR_PEDIDOS.GetPedidosVtex';
  
BEGIN
  OPEN Cur_Out FOR
   select p.pedidoid_vtex
     from vtexorders p
    where p.icprocesado = 0 --solo pedidos por procesar
     --devulve de 1 en 1 los pedidos
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
                          p_idpedido_pos     IN     vtexorders.idpedido_pos%type, 
                          p_icprocesado      IN     vtexorders.icprocesado%type,
                          p_observacion      IN     vtexorders.observacion%type) is
                        
  v_Modulo varchar2(100) := 'PKG_TRANSFERIR_PEDIDOS.SETvtexorders';
  PRAGMA AUTONOMOUS_TRANSACTION;

BEGIN

  update vtexorders vp
     set vp.icprocesado = p_icprocesado,
         vp.idpedido_pos = p_idpedido_pos,
         vp.dtprocesado = sysdate,
         vp.observacion = p_observacion
   where vp.pedidoid_vtex = p_pedidoid_vtex;    
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
* Inserta los pedidos de VTEX para AC
* %v 22/01/2021 - ChM
* %v 29/03/2021 - ChM agrego control de zona franca
*                     Agrego idpersonaresponsable del pedido
*                     Ajusto formato de promo lpad('123456',8,'0')	
*%v 30/03/2021 - ChM  Agrego logica para manejo de pesables
***************************************************************************************************/
PROCEDURE InsertarPedidoPOS (p_pedidoid_vtex       IN  vtexorders.pedidoid_vtex%type,
                             p_cabecera            IN OUT  varchar2,
                             p_detalle             IN  arr_refId) IS
  
  v_modulo                   varchar2(100) := 'PKG_TRANSFERIR_PEDIDOS.InsertarPedidoPOS';
  v_iddoctrx                 documentos.iddoctrx%type;
  v_cdsucursal               vtexsellers.cdsucursal%type:=null;
  v_id_canal                 vtexsellers.id_canal%type:=null;
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
   
  --items
  v_cdarticulo               vtexproduct.refid%type;   
  v_price                    vtexprice.pricepl%type;
  v_quantity                 vtexstock.qtstock%type;
  v_idpromo_vtex             vtexpromotion.id_promo_vtex%type;
  v_qtpiezas                 detallepedidos.qtpiezas%type:=0; 
  v_vluxb                    detallepedidos.vluxb%type;
  v_vlcantidad               detallepedidos.qtunidadpedido%type;            
  v_cdunidadmedida           detallepedidos.cdunidadmedida%type;
  v_undpesable               detallepedidos.cdunidadmedida%type;
  v_cdpromo                  tblpromo.cdpromo%type;
  v_dsarticulo               detallepedidos.dsarticulo%type;
  v_icresppromo              detallepedidos.icresppromo%type;
  v_ampreciounitario         detallepedidos.ampreciounitario%type;
  v_amlinea                  detallepedidos.amlinea%type;                             
  v_observacion              observacionespedido.dsobservacion%type;
  v_limitedividepedido       number:= n_pkg_vitalpos_core.GETVLPARAMETRO('MAX_PEDIDO_CF','General');
  v_dsobservacion            detallepedidos.dsobservacion%type;

  
BEGIN
  
   n_pkg_vitalpos_log_general.write(1,'comienza insertar pos: '||p_pedidoid_vtex);
   
  /*o	Texto del 1 + 40  el idCuenta  (cliente)
    
    o	Texto 41 + 1 marca de Consumidor Final. 1 CF 0 Cliente
    
    o	Texto del 42 + 40 idaddress 
    
    o	Texto del 82 + 10 cddireccion sqdireccion    
    
    o	Texto del 92 + 30 fecha de creacion del pedido dd/mm/yyyyhh:mm:ss
    
    o	Texto del 122 + 100  observaciones del pedido
  */
  
   --obtengo v_cdtipodireccion, v_sqdireccion si viene pickup retira en sucursal
   if trim(substr(p_cabecera,82,10))='pickup' then
     v_icretiraensucu := 1; 
     --busca la dirección comercial del cliente
     begin
        select de.cdtipodireccion,
               max(de.sqdireccion)sqdireccion 
          into v_cdtipodireccion,
               v_sqdireccion                 
          from direccionesentidades de,
               tblcuenta            cu,              
               vtexclients          vc
         where de.identidad = cu.identidad           
           and vc.id_cuenta = cu.idcuenta
           --ubico la dirección comercial del cliente activa
           and de.cdtipodireccion = 2
           and de.icactiva = 1  
           and vc.id_cuenta = trim(substr(p_cabecera,1,40))        
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
         Setvtexorders (p_pedidoid_vtex,null,2,'No es posible recuperar datos de cabecera: '||p_cabecera);         
               RETURN;  
    end;   
     --verifico si es canal NO error no se puede recuperar el pedido
    if v_id_canal = 'NO' then
      Setvtexorders (p_pedidoid_vtex,null,2,'cliente sin CANAL asociado. No es posible recuperar datos de cabecera: '||p_cabecera);
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
       Setvtexorders (p_pedidoid_vtex,null,2,'Pedido sin articulos: '||trim(substr(p_cabecera,1,40)));         
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
            -- obtengo el precio unitario sin iva
          v_ampreciounitario:= getpreciosiniva(v_cdarticulo,v_cdsucursal,v_price);              
          --valor de la linea
          v_ammonto:=v_ammonto+(v_quantity*v_ampreciounitario);
          --solo líneas de artículos
          if v_icresppromo=0 then
            v_qtmateriales:=v_qtmateriales+1;
          end if;  
       END LOOP; 
    ELSE     
     Setvtexorders (p_pedidoid_vtex,null,2,'No existen artículos en el pedido: '||v_idpedido);     
     rollback;  
     RETURN;  
   END IF;
   --extrae la fecha del pedido
   v_fechapedido:= to_date(trim(substr(p_cabecera,92,30)),'dd/mm/yyyy hh24:mi:ss');  
   --dos dias despues de la fecha del pedido
   v_dtentrega:=v_fechapedido+2;     
    --observaciones del pedido
    v_observacion:= trim(substr(p_cabecera,122,100));    
      
    --si es CF y ammomto superior al limite se marca para dividir pedido
    if v_cdsituacioniva = 2 and v_ammonto > v_limitedividepedido then
         v_icestadosistema:=-1; --pedido preparado para dividir        
    end if;
  
  --busca la marca de zona franca
   v_zonafranca:=fnvalidazonafranca( v_cdtipodireccion, v_sqdireccion,v_identidad); 
   if v_zonafranca=-1 then
      Setvtexorders (p_pedidoid_vtex,null,2,'Error al ubicar Zona Franca'||v_identidad);
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
      Setvtexorders (p_pedidoid_vtex,null,2,'Error al insertar documento del pedido VTEX '||v_identidad);
     rollback;  
     RETURN;       
    END IF;

  --Inserto el registro cabecera en la tabla pedidos (uso el mismo transid del de la transaccion de VTEX)
  insert into pedidos
  (idpedido          , identidad       , idpersonaresponsable  , dspersona  , iddoctrx        , qtmateriales  , dsreferencia     ,
   cdcondicionventa  , cdsituacioniva  , icestadosistema       , cdlugar    , dtaplicacion    , dtentrega     , cdtipodireccion  ,
   idvendedor        , sqdireccion     , ammonto               , icorigen   , idcomisionista  , id_canal      , transid          ,
   icretirasucursal  , iczonafranca  )
  values
  (sys_guid()        , v_identidad     , v_idpersonaresponsable , null        , v_iddoctrx      , v_qtmateriales ,v_dsreferencia      ,
   null              , v_cdsituacioniva, v_icestadosistema      , 3           , v_fechapedido   , v_dtentrega    , v_cdtipodireccion ,
   v_idvendedor      , v_sqdireccion   , v_ammonto              , v_icorigen  , v_idcomisionista, v_id_canal     , p_pedidoid_vtex   ,
   v_icretiraensucu  , v_zonafranca  )
   RETURNING idpedido  INTO v_idpedido;
   
   IF  SQL%ROWCOUNT = 0  THEN      --valida insert 
      Setvtexorders (p_pedidoid_vtex,null,2,'Error al insertar idpedido POs del pedido VTEX'||p_pedidoid_vtex);
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
          v_quantity:=to_number(trim(substr(p_detalle(i),29,6))); --la cantidad en VTEX viene solo en unidades UN
          v_idpromo_vtex:=rpad(trim(substr(p_detalle(i),35,40)),40,' ');
          v_icresppromo:=to_number(substr(p_detalle(i),75,1));
          v_qtpiezas:=0;
          
          -- busco el  UxB del articulo 
          v_vluxb:=nvl(n_pkg_vitalpos_materiales.GetUxB(v_cdarticulo),0);
          
           -- obtengo el precio unitario sin iva
          v_ampreciounitario:= getpreciosiniva(v_cdarticulo,v_cdsucursal,v_price);           
                 
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
               Setvtexorders (p_pedidoid_vtex,null,2,'Error al intentar recuperar unidad de medida del articulo: '||v_cdarticulo);                           
               rollback;  
               RETURN; 
          else           
               if v_undpesable in ('KG','PZA') then               
                v_qtpiezas:=v_quantity;  
                 v_cdunidadmedida:='KG';              
               end if;     
          end if;
               
          --busco el cdpromo 
          begin
            --verifica si existe cdpromo_vtex
            if LENGTH(TRIM(v_idpromo_vtex))>1 then
              --OJO PARA PRUEBA NO BUSCO PROMO   QUITAR!!!!!!!!!
              -- v_cdpromo:=1234567;
                select 
              distinct lpad(trim(vp.cdpromo),8,'0')
                  into v_cdpromo
                  from vtexpromotion vp
                 where vp.id_promo_vtex = v_idpromo_vtex
                   and vp.id_canal = v_id_canal;
            else
              v_cdpromo:=null;       
            end if;                   
            exception 
              when others then
               Setvtexorders (p_pedidoid_vtex,null,2,'Error al intentar recuperar promoción artículo: '||v_cdarticulo||'id _promo_vtex '||v_idpromo_vtex);
               rollback;
               RETURN;                       
          end; 
          --busco la descripción del producto 
          begin
             if LENGTH(TRIM(v_cdarticulo))>1 then
               select substr(vp.name,1,50) 
                 into v_dsarticulo
                 from vtexproduct vp 
                where vp.refid = v_cdarticulo;
              else
                v_dsarticulo:=null;   
             end if;
            exception 
              when others then
                Setvtexorders (p_pedidoid_vtex,null,2,'Error al intentar recuperar descripcion del articulo: '||v_cdarticulo);                           
               rollback;  
               RETURN;               
          end;
                     
          insert into detallepedidos
          (idpedido           , sqdetallepedido , cdunidadmedida   , cdarticulo      , qtunidadpedido, qtunidadmedidabase  , qtpiezas     ,
           ampreciounitario   , amlinea         , vluxb            , dsobservacion   , icresppromo   , cdpromo             , dsarticulo   )
          values
          (v_idpedido         , i               , v_cdunidadmedida , v_cdarticulo    , v_vlcantidad  , v_quantity          , v_qtpiezas   ,
           v_ampreciounitario , v_amlinea       , v_vluxb          , v_dsobservacion , v_icresppromo , v_cdpromo           , v_dsarticulo);  
           
           IF  SQL%ROWCOUNT = 0  THEN      --valida insert 
             Setvtexorders (p_pedidoid_vtex,null,2,'Error al insertar detalle del pedido VTEX'||p_pedidoid_vtex||'cdarticulo: '||v_cdarticulo);                          
             rollback;  
             RETURN;   
            END IF;           
                              
       END LOOP;        
          
     ELSE     
     Setvtexorders (p_pedidoid_vtex,null,2,'No existen articulos en el pedido: '||v_idpedido);     
     rollback;  
     RETURN;  
     END IF;
 
 
  -- Inserto un registro en tx_pedidos_insert para que el pedido sea considerado en la cola de pedidos del SLV
  insert into tx_pedidos_insert
  (iddoctrx  , idpedido          , cdsucursal  , cdcuit  )
  values
  (v_iddoctrx, v_idpedido        , v_cdsucursal, v_cdcuit);
  
  IF  SQL%ROWCOUNT = 0  THEN      --valida insert 
   	 Setvtexorders (p_pedidoid_vtex,null,2,'Error al insertar tx_pedidos_insert del pedido VTEX'||p_pedidoid_vtex);
     rollback;  
     RETURN;   
    END IF;

  -- Inserto las observaciones 
  if length(v_observacion)>1 then
    insert into observacionespedido
               (idpedido, dsobservacion)
    values
               (v_idpedido, v_observacion);
               
     IF  SQL%ROWCOUNT = 0  THEN      --valida insert 
   	 Setvtexorders (p_pedidoid_vtex,null,2,'Error al insertar observaciones del pedido VTEX'||p_pedidoid_vtex);                 
     rollback;  
     RETURN;  
    END IF;           
  end if;             
  
  --si es CF y ammomto superior al limite inserto para dividir pedido
    if v_cdsituacioniva = 2 and v_ammonto > v_limitedividepedido then
       INSERT INTO tx_pedidos_particionar
             (idpedido,limite,fecha)
             VALUES
             (v_idpedido,v_limitedividepedido,sysdate);
             
        IF  SQL%ROWCOUNT = 0  THEN      --valida insert 
           Setvtexorders (p_pedidoid_vtex,null,2,'Error al insertar tx_pedidos_particionar del pedido VTEX'||p_pedidoid_vtex);
           rollback;   
           RETURN;  
        END IF;      
    end if;
  Setvtexorders (p_pedidoid_vtex,v_idpedido,1,'Insertado en POS Correctamente!');                       
  COMMIT; 
    
  IF DividirPedidos = 0 then
    Setvtexorders (p_pedidoid_vtex,v_idpedido,3,'Error al dividir pedido. Insertado en POS Correctamente!!');                       
  End If;
    
  EXCEPTION
    WHEN OTHERS THEN
      Setvtexorders (p_pedidoid_vtex,null,2, 'Modulo: ' || v_Modulo || '  Error: ' ||SQLERRM);                  
   	  ROLLBACK;
      RETURN;  
END InsertarPedidoPOS;

/**************************************************************************************************
* divide el pedido POS si esta marcado para dividir por monto y es pedido de CF 
* este proceso lo debe llamar el JOB justo despues de el llamado a InsertarPedidosPos
* %v 02/02/2021 - ChM
***************************************************************************************************/
FUNCTION DividirPedidos return integer is
                        
  v_Modulo               varchar2(100) := 'PKG_TRANSFERIR_PEDIDOS.DividirPedidos';
  v_icorigen             pedidos.icorigen%type:=4;--0-Normal 1-Especificos 2-viejos sin identificar  3-Salon 4-Ecommerce 
  v_ok                   integer;
  v_error                varchar2(300);
  
   Cursor c_pedidos is
    select p.IDPEDIDO IDPEDIDO,p.IDDOCTRX IDDOCTRX, nvl(pa.limite,0) limite
       From pedidos p
       left join tx_pedidos_particionar pa on (p.idpedido = pa.idpedido)
      where p.icestadosistema = -1
        and p.icorigen = v_icorigen; --solo pedidos VTEX
BEGIN
  --recupera los pedidos a dividir de VTEX
    FOR i in c_pedidos
    LOOP
      --Particiono el pedido en caso de ser necesario
      If i.limite != 0 then
            BEGIN
              pkg_dividir_pedido.dividir(i.IDPEDIDO, i.LIMITE,v_ok, v_error);
			       -- Si se particiona, se pasa el pedido padre a 0. Dividirpedido lo elimina de tx_pedidos_insert así no se transfiere a las sucursales
              update pedidos set icestadosistema = 0  where idpedido = i.IDPEDIDO;
              
              --elimino al padre de pedidos a particionar 
              delete TX_PEDIDOS_PARTICIONAR WHERE IDPEDIDO = i.IDPEDIDO;
             
            EXCEPTION
            WHEN OTHERS THEN
              n_pkg_vitalpos_log_general.write(2, 'Modulo: '||v_modulo||'  Error al dividir pedido: ' || SQLERRM);
              ROLLBACK;
            END;
      END IF;
    END LOOP;

--una vez que tengo todas los pedidos divididos, modifico valor para enviar a tiendas (el PKG_DIVIDIR inserta a todos los hijos en TX_PEDIDOS_INSERT).
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

  return 1;
  commit;
EXCEPTION
  WHEN OTHERS THEN
    n_pkg_vitalpos_log_general.write(1,
                          'Modulo: ' || v_Modulo || '  Error: ' || SQLERRM);
    rollback;                      
    return 0;                      
END DividirPedidos;
END;
/
