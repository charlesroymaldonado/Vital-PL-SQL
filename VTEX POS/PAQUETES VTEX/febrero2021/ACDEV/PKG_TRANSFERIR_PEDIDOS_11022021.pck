CREATE OR REPLACE PACKAGE PKG_TRANSFERIR_PEDIDOS Is

type cursor_type Is Ref Cursor;

TYPE arr_refid IS TABLE OF VARCHAR(100) INDEX BY PLS_INTEGER;

procedure Trae_pedidos;
procedure Trae_Prepedidos;

 PROCEDURE InsertarPedidoPOS (p_pedidoid_vtex       IN  vtexorders.pedidoid_vtex%type,
                              p_cabecera            IN OUT varchar2,
                              p_detalle             IN  arr_refId);

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
PROCEDURE Setvtexorders (p_pedidoid_vtex    IN     vtexorders.pedidoid_vtex%type,
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
* Inserta los pedidos de VTEX para AC
* %v 22/01/2021 - ChM
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
  v_ammonto                  number:=0;
  v_idpedido                 pedidos.idpedido%type;
  v_icretiraensucu           pedidos.icretirasucursal%type:=0;
  v_cdtipodireccion          tbldireccioncuenta.cdtipodireccion%type;
  v_sqdireccion              tbldireccioncuenta.sqdireccion%type;
  v_icestadosistema          pedidos.icestadosistema%type:=0; --listo para Validar en PKG_PEDIDO_CENTRAL
  v_dsreferencia             pedidos.dsreferencia%type:=null; --OOOOJJJJOOOOO dsreferencia de CF se va null porque PKG_PEDIDO_CENTRAL validar le asignará DNI de CF
  v_dtentrega                pedidos.dtentrega%type:=sysdate+2;--2 dias despues de subido a POS
  --items
  v_cdarticulo               vtexproduct.refid%type;   
  v_price                    vtexprice.pricepl%type;
  v_quantity                 vtexstock.qtstock%type;
  v_idpromo_vtex             vtexpromotion.id_promo_vtex%type;
  v_qtpiezas                 detallepedidos.qtpiezas%type:=0; --en vtex por ahora no existen pesables
  v_vluxb                    detallepedidos.vluxb%type;
  v_vlcantidad               detallepedidos.qtunidadpedido%type;            
  v_cdunidadmedida           detallepedidos.cdunidadmedida%type;
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
   
  /*o	Texto del 1 + 3 el affiliateId
    o	Texto el  4 + 1  el salesChannel
    o	Texto del 5 + 40  el idCuenta  (cliente)
    o	Texto del 45 + 60  el email (cliente)Texto del 
    o	Texto 105 + 1 marca de Consumidor Final. 1 CF 0 Cliente
    o	Texto del 106 + 30 value Monto total pedido.
    o	 Texto del 136 + 40 id vendedor o comi.
    o	Texto del 176 + 1 icretiraensucursal 0 no 1 si.
    o	Texto del 177 + 8  cdtipodireccion.
    o	Texto del 185 + 3 sqdireccion.
    o	Texto del 188 + 100 observación.
    FALTA DTENTREGA del pedido OOOOOOOOOOOOOOOJOOOOOOOOOOOOOOOO
  */
  --cabecera para vendedor PRUEBAS
  p_cabecera:='VLH137C1BBB794844E8CE05000CB3C00415C        vendedor@unet.edu.vevendedor@unet.edu.vevendedor@unet.edu.ve02500                          232AA03211C6863FE05000C83C001F36        12       1   pruebavendedor';
 --cabecera para comi
--  p_cabecera:='CLH237C1BBB794844E8CE05000CB3C00415C        comisionista@unet.edu.vecomisionista@unet.edu.vecomisionista05500                          4B7C2D073AA4304EE053100000CEA5C6        12       1   pruebacomi'

  --recupero el cdsucursal y el ID_canal según el affiliateId
   begin
      select vs.cdsucursal, vs.id_canal
        into v_cdsucursal,v_id_canal
        from vtexsellers vs
       where vs.afiliado = trim(substr(p_cabecera,1,3))
       --solo sucursales activas 
         and vs.icactivo = 1;
   exception 
     when others then
         Setvtexorders (p_pedidoid_vtex,null,2,'No existe la sucursal o no esta activa');
           RETURN;  
   end;
   
   --recupero el id cuenta del cliente y la identidad real entidades
   begin
              select cu.idcuenta,cu.identidad
                into v_idcuenta,v_identidadReal
                from tblcuenta cu
               where cu.idcuenta = trim(substr(p_cabecera,5,40));
               --si es cliente registrado identidad igual a identidad real
               v_identidad:=v_identidadReal;
    exception 
         when others then
             Setvtexorders (p_pedidoid_vtex,null,2,'No se encuentra la cuenta del cliente: '||trim(substr(p_cabecera,5,40)));              
             RETURN;  
   end; 
   
   --recupero el CUIT del cliente
   begin
             select e.cdcuit
               into v_cdcuit
               from entidades e
              where e.identidad = v_identidadReal;
    exception 
         when others then
             Setvtexorders (p_pedidoid_vtex,null,2,'No se encuentra CUIT del cliente: '||v_identidadReal);        
               RETURN;          
   end; 
    --Averiguo la Situacion de IVA 1 si es CF o cliente registrado
    if trim(substr(p_cabecera,105,1)) = 1 then
      v_cdsituacioniva := '2';
      --si es CF identidad IdCfReparto
      v_identidad:='IdCfReparto';     
    else
      v_cdsituacioniva := '1';      
    end if;
 
  --Averiguo el monto total del pedido, 
  --divido por 100 por que vtex envia los dos decimales en los ultimos 2 digitos
    v_ammonto:= to_number(trim(substr(p_cabecera,106,30)))/100;      
       
    --recupera el ID Comi o ID vendedor
   begin
            if v_id_canal ='VE' then
              select per.idpersona
                into v_idvendedor
                from personas per 
               where per.idpersona = substr(p_cabecera,136,40);
             end if;  
            if v_id_canal ='CO' then
              select e.identidad
                into v_idcomisionista
                from entidades e
               where e.identidad = substr(p_cabecera,136,40);
             end if;   
    exception 
         when others then
             Setvtexorders (p_pedidoid_vtex,null,2,'No existe ID vendedor o comisionista: '||substr(p_cabecera,136,40)||' canal: '||v_id_canal);        
               RETURN;  
   end;   
    --indica si el pedido se retira en sucursal  
    v_icretiraensucu := trim(substr(p_cabecera,176,1));     
    --indica cdtipodireccion
    v_cdtipodireccion := substr(p_cabecera,177,8); 
    --indica sqdireccion 
    v_sqdireccion:= to_number(trim(substr(p_cabecera,185,3)));  
    
    --observaciones del pedido
    v_observacion:= trim(substr(p_cabecera,188,100));
    
    --Averiguo la cantidad de articulos distintos que tiene el pedido  OOOOJJOOOOOO falta restar las lineas de promo
    v_qtmateriales:=p_detalle.Count;
    if v_qtmateriales = 0 then 
       Setvtexorders (p_pedidoid_vtex,null,2,'Pedido sin articulos: '||trim(substr(p_cabecera,5,45)));         
               RETURN;  
    end if;
    
    --si es CF y ammomto superior al limite se marca para dividir pedido
    if v_cdsituacioniva = 2 and v_ammonto > v_limitedividepedido then
         v_icestadosistema:=-1; --pedido preparado para dividir        
    end if;
    
              
 --inserto datos en documentos con tipo de comprobante PEDI
  INSERT INTO documentos
      (iddoctrx           , idmovmateriales       , idmovtrx                         , cdsucursal     , identidad        , cdcomprobante ,
       cdestadocomprobante, idpersona             , sqcomprobante                    , sqsistema      , dtdocumento      , amdocumento   ,
       icorigen           , amnetodocumento       , qtreimpresiones                  , amrecargo      , cdtipocomprobante, dsreferencia  ,
       icspool            , iccajaunificada       , cdpuntoventa                     , idcuenta       , identidadreal    , idtransaccion )
  VALUES
      (sys_guid()         , NULL                  , NULL                             , v_cdsucursal   , v_identidad      , 'PEDI'        ,
       '1'                , NULL                  , OBTENERCONTADORNUMCOMPROB('PEDI'), CONTADORSISTEMA, SYSDATE          , v_ammonto     ,
       v_icorigen         , v_ammonto             , 0                                , 0              , NULL             , v_dsreferencia,
       NULL               , NULL                  , NULL                             , v_idcuenta     , v_identidadReal  , NULL          )
  RETURNING iddoctrx INTO v_iddoctrx;
  
  IF  SQL%ROWCOUNT = 0  THEN      --valida insert 
      Setvtexorders (p_pedidoid_vtex,null,2,'Error al insertar documento del pedido VTEX'||p_pedidoid_vtex);
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
  (sys_guid()        , v_identidad     , NULL                   , null        , v_iddoctrx      , v_qtmateriales ,v_dsreferencia      ,
   null              , v_cdsituacioniva, v_icestadosistema      , 3           , sysdate         , v_dtentrega    , v_cdtipodireccion ,
   v_idvendedor      , v_sqdireccion   , v_ammonto              , v_icorigen  , v_idcomisionista, v_id_canal     , p_pedidoid_vtex   ,
   v_icretiraensucu  , null  )
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
         
          
          -- busco el  UxB del articulo 
          v_vluxb:=nvl(n_pkg_vitalpos_materiales.GetUxB(v_cdarticulo),0);
          
           -- obtengo el precio unitario sin iva
          v_ampreciounitario:= pkg_cld_datos.getpreciosiniva(v_cdarticulo,v_cdsucursal,v_price);           
                 
          --valor de la linea
          v_amlinea:= v_quantity*v_ampreciounitario;
          
          --si es la linea de promo v_vluxb es 1 
           if v_icresppromo = 1 then
                v_vluxb:=1;            
                v_dsobservacion:='PR';                         
            end if;
            
          --si la división es exacta y vluxb > 1 se pasa BTO sino UN, además excluyo lineas de promo siempre en UN
          if v_vluxb > 1 and mod((v_quantity/v_vluxb),2) = 0 and v_icresppromo <> 1 then
            v_vlcantidad:=v_quantity/v_vluxb;
            v_cdunidadmedida:='BTO';            
          else
            v_vlcantidad:=v_quantity;
            v_cdunidadmedida:='UN';
          end if;      
               
          --busco el cdpromo 
          begin
            --verifica si existe cdpromo_vtex
            if LENGTH(TRIM(v_idpromo_vtex))>1 then
                select 
              distinct vp.cdpromo
                  into v_cdpromo
                  from vtexpromotion vp
                 where vp.id_promo_vtex = v_idpromo_vtex
                   and vp.id_canal = v_id_canal;
            else
              v_cdpromo:=null;       
            end if;                   
            exception 
              when others then
               Setvtexorders (p_pedidoid_vtex,null,2,'Error al intentar recuperar promoción artículo: '||v_cdarticulo);
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
