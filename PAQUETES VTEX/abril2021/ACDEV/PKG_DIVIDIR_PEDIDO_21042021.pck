CREATE OR REPLACE PACKAGE PKG_DIVIDIR_PEDIDO Is

procedure Dividir(p_idPedido in  pedidos.idpedido%type,
                  p_amLimite in  number,
                  p_ok       out integer,
                  p_error    out varchar2);

End;
/
CREATE OR REPLACE PACKAGE BODY PKG_DIVIDIR_PEDIDO Is
/**************************************************************************************************
* Dado un amLinea y un amLímite, busca entre los nuevos pedidos si en alguno entra la línea.
* En caso que no entre en ningún pedido, genera uno nuevo.
* Devuelve el idPedido en dónde entra la línea.
*
* %v 04/01/2016 - MarianoL
* %v 12/07/2016 - APW - Recupero observacionespedido y lo grabo para todas las cabeceras
***************************************************************************************************/
function BuscarPedido(p_RegPedidoPadre in  pedidos%rowtype,
                      p_amLinea        in number,
                      p_amLimite       in number)
return pedidos.idpedido%type
is

   v_modulo            varchar2(100) := 'PKG_DIVIDIR_PEDIDO.BuscarPedido';
   v_cdCompPEDI        documentos.cdcomprobante%type := 'PEDI    ';
   v_RegDocumentoPadre documentos%rowtype;
   v_RegDocumentoHijo  documentos%rowtype;
   v_RegPedidoHijo     pedidos%rowtype;
   v_cdCuit            entidades.cdcuit%type;
   v_idPedidoPadre     pedidos.idpedido%type;
   v_dsobservacion     observacionespedido.dsobservacion%type;

begin

   --Buscar el documento PEDREF
   select *
   into v_RegDocumentoPadre
   from documentos d
   where d.iddoctrx = p_RegPedidoPadre.Iddoctrx
     and d.cdcomprobante = 'PEDREF  ';

   -- Buscar si tiene observaciones
   begin
     select op.dsobservacion
     into v_dsobservacion
     from observacionespedido op
     where op.idpedido = p_RegPedidoPadre.idpedido;
   exception when no_data_found then
     v_dsobservacion := null;
   end;

   --Recorrer los PEDI asociados al PEDREF
   for v_RegPedido in (select dp.idpedido, sum(dp.amlinea) amlinea
                       from documentos d,
                            pedidos p,
                            detallepedidos dp
                       where d.idmovtrx = v_RegDocumentoPadre.Iddoctrx
                         and d.cdcomprobante = v_cdCompPEDI
                         and p.iddoctrx = d.iddoctrx
                         and dp.idpedido = p.idpedido
                       group by dp.idpedido)
   loop
      if (v_RegPedido.Amlinea + p_amLinea) <= p_amLimite then
         --La línea entra en este pedido
         return(v_RegPedido.Idpedido);
      end if;
   end loop;

   --Si llegó hasta acá es porque la línea no entra en ninguno de los PEDI ya existentes.  Crear uno nuevo

   --Grabar el nuevo documento
   v_RegDocumentoHijo                 := v_RegDocumentoPadre;
   v_RegDocumentoHijo.Iddoctrx        := sys_guid();
   v_RegDocumentoHijo.Idmovtrx        := v_RegDocumentoPadre.Iddoctrx;
   v_RegDocumentoHijo.Cdcomprobante   := v_cdCompPEDI;
   v_RegDocumentoHijo.Sqcomprobante   := obtenercontadornumcomprob('PEDI');
   v_RegDocumentoHijo.Sqsistema       := contadorsistema();
   v_RegDocumentoHijo.Amdocumento     := 0;
   v_RegDocumentoHijo.Amnetodocumento := 0;
   insert into documentos d values v_RegDocumentoHijo;

   --Averiguo el id del pedido padre para asociarlo al transid
   begin
     select idpedido
       into v_idPedidoPadre
       from pedidos
      where iddoctrx = v_RegDocumentoPadre.Iddoctrx;
   exception when others then
     v_idPedidoPadre := NULL;
   end;

   --Grabar el nuevo pedido
   v_RegPedidoHijo := p_RegPedidoPadre;
   v_RegPedidoHijo.Idpedido     := sys_guid();
   v_RegPedidoHijo.Iddoctrx     := v_RegDocumentoHijo.Iddoctrx;
   v_RegPedidoHijo.Qtmateriales := 0;
   v_RegPedidoHijo.Ammonto      := 0;
   v_RegPedidoHijo.transid      := trim(v_idPedidoPadre) || '_HIJO';
   insert into pedidos p values v_RegPedidoHijo;

   -- Si tenía observación, la hereda
   if v_dsobservacion is not null then
      insert into observacionespedido values (v_RegPedidoHijo.Idpedido, v_dsobservacion);
   end if;

   --Buscar el cuit de la entidad real
   begin
      select e.cdcuit
      into v_cdCuit
      from entidades e
      where e.identidad = v_RegDocumentoPadre.Identidadreal;
   exception when others then
      null;
   end;

   --Grabar tx_Pedidos_Insert
   insert into tx_pedidos_insert
   (iddoctrx, idpedido, cdsucursal, cdcuit)
   values
   (v_RegDocumentoHijo.Iddoctrx, v_RegPedidoHijo.Idpedido, v_RegDocumentoHijo.Cdsucursal, v_cdCuit);

   return(v_RegPedidoHijo.Idpedido);

exception when others then
   n_pkg_vitalpos_log_general.write(2, 'Modulo: ' || v_modulo || '  Error: ' || Sqlerrm);
   raise;
end BuscarPedido;

/**************************************************************************************************
* Dada una línea del pedido, la graba a uno de los nuevo pedidos
*
* %v 04/01/2016 - MarianoL
***************************************************************************************************/
procedure GrabarLinea(p_RegPedidoPadre in  pedidos%rowtype,
                      p_RegDetalle     in  detallepedidos%rowtype,
                      p_amLimite       in  number,
                      p_idPedido       in  pedidos.idpedido%type default null)
is

   v_modulo          varchar2(100) := 'PKG_DIVIDIR_PEDIDO.GrabarLinea';
   v_idPedido        detallepedidos.idpedido%type;
   v_sqDetallePedido detallepedidos.sqdetallepedido%type;

begin

   --En caso que no se pase el p_idPedido, Buscar en que pedido hay espacio para este importe
   if p_idPedido is null then
      v_idPedido := BuscarPedido(p_RegPedidoPadre, p_RegDetalle.Amlinea, p_amLimite);
   else
      v_idPedido := p_idPedido;
   end if;

   --Buscar la máxima línea
   select nvl(max(dp.sqdetallepedido),0) + 1
   into v_sqDetallePedido
   from detallepedidos dp
   where dp.idpedido = v_idPedido;

   --Insertar la línea en el pedido
   insert into detallepedidos dp
   (idpedido                       , sqdetallepedido         , cdunidadmedida               , cdarticulo             , qtunidadpedido             ,
   qtunidadmedidabase              , qtpiezas                , ampreciounitario             , amlinea                , vluxb                      ,
   dsobservacion                   , icresppromo             , cdpromo                      , dsarticulo             )
   values
   (v_idPedido                     , v_sqDetallePedido       , p_RegDetalle.Cdunidadmedida  , p_RegDetalle.Cdarticulo, p_RegDetalle.Qtunidadpedido,
    p_RegDetalle.Qtunidadmedidabase, p_RegDetalle.Qtpiezas   , p_RegDetalle.Ampreciounitario, p_RegDetalle.Amlinea   , p_RegDetalle.Vluxb         ,
    p_RegDetalle.Dsobservacion     , p_RegDetalle.Icresppromo, p_RegDetalle.Cdpromo         , p_RegDetalle.Dsarticulo);

   return;

exception when others then
   n_pkg_vitalpos_log_general.write(2, 'Modulo: ' || v_modulo || '  Error: ' || Sqlerrm);
   raise;
end GrabarLinea;

/**************************************************************************************************
* Dada una línea del pedido origen que es parte de una promoción, copia toda la promoción entera en
* uno de los nuevos pedidos
*
* %v 04/01/2016 - MarianoL
***************************************************************************************************/
procedure PromoEntera(p_RegPedidoPadre in  pedidos%rowtype,
                      p_RegDetalle     in  detallepedidos%rowtype,
                      p_amLimite       in  number)
is

   v_modulo       varchar2(100) := 'PKG_DIVIDIR_PEDIDO.PromoEntera';
   v_amTotalPromo number;
   v_idPedido     pedidos.idpedido%type;

begin

   --Calcular el total de la promoción
   select sum(dp.amlinea)
   into v_amTotalPromo
   from detallepedidos dp
   where dp.idpedido = p_RegDetalle.Idpedido
     and dp.cdpromo = p_RegDetalle.Cdpromo;

   --Buscar en que pedido hay espacio para este importe
   v_idPedido := BuscarPedido(p_RegPedidoPadre, v_amTotalPromo, p_amLimite);

   --Para cada línea del pedido que pertenece a la promoción
   for v_regDetallePromo in (select *
                             from detallepedidos dp
                             where dp.idpedido = p_RegDetalle.Idpedido
                               and dp.cdpromo = p_RegDetalle.Cdpromo)
   loop
      GrabarLinea(p_RegPedidoPadre, v_regDetallePromo, p_amLimite, v_idPedido);
   end loop;

   return;

exception when others then
   n_pkg_vitalpos_log_general.write(2, 'Modulo: ' || v_modulo || '  Error: ' || Sqlerrm);
   raise;
end PromoEntera;

/**************************************************************************************************
* Dada una línea del pedido origen que supera el máximo permitido en un pedido, la parte en
* líneas más chicas y luego las copia en los nuevos pedidos
*
* %v 04/01/2016 - MarianoL
***************************************************************************************************/
procedure PartirLinea(p_RegPedidoPadre in  pedidos%rowtype,
                      p_RegDetalle     in  detallepedidos%rowtype,
                      p_amLimite       in  number)
is

   v_modulo              varchar2(100) := 'PKG_DIVIDIR_PEDIDO.PartirLinea';
   v_vlUxB               detallepedidos.vluxb%type;
   v_amLineaMinimo       number;
   v_qtUnidadPedidoTotal detallepedidos.qtunidadpedido%type := 0;
   v_RegNuevoDetalle     detallepedidos%rowtype;

begin

   --Calcular el UxB
   if trim(p_RegDetalle.Cdunidadmedida) = 'UN' then
      v_vlUxB := 1;
   elsif trim(p_RegDetalle.Cdunidadmedida) = 'BTO' then
      v_vlUxB := p_RegDetalle.Vluxb;
   else
      --Si la unidad de medida no es UN ni BTO. Grabar la línea sin dividir
      GrabarLinea(p_RegPedidoPadre, p_RegDetalle, p_amLimite);
      return;
   end if;

   --Calcular la máxima cantidad que puede contener una línea para no superar el amLimite
   v_amLineaMinimo := v_vlUxB * p_RegDetalle.ampreciounitario;

   --Verificar si aunque se divida la línea igual supera el límite.
   if v_amLineaMinimo > p_amLimite then
      --Grabar la línea sin dividir
      GrabarLinea(p_RegPedidoPadre, p_RegDetalle, p_amLimite);
      return;
   end if;

   --Iniciar la división de la línea
   v_RegNuevoDetalle                := p_RegDetalle;
   v_RegNuevoDetalle.Qtunidadpedido := trunc(p_amLimite / v_amLineaMinimo);

   loop
      v_qtUnidadPedidoTotal := v_qtUnidadPedidoTotal + v_RegNuevoDetalle.Qtunidadpedido;

      --Controlar que el total dividido no supere la línea original
      if v_qtUnidadPedidoTotal > p_RegDetalle.qtunidadpedido then
          v_RegNuevoDetalle.Qtunidadpedido  := p_RegDetalle.qtunidadpedido - (v_qtUnidadPedidoTotal - v_RegNuevoDetalle.Qtunidadpedido);
      end if;

      v_RegNuevoDetalle.qtunidadmedidabase := v_RegNuevoDetalle.Qtunidadpedido * v_vluxb;
      v_RegNuevoDetalle.amlinea            := round(v_RegNuevoDetalle.ampreciounitario * v_RegNuevoDetalle.qtunidadmedidabase, 3);

      GrabarLinea(p_RegPedidoPadre, v_RegNuevoDetalle, p_amLimite);

      if v_qtunidadpedidototal >= p_RegDetalle.qtunidadpedido THEN
          exit;
      end if;
   end loop;

   return;

exception when others then
   n_pkg_vitalpos_log_general.write(2, 'Modulo: ' || v_modulo || '  Error: ' || Sqlerrm);
   raise;
end PartirLinea;


/**************************************************************************************************
* Calcula los totales de los PEDI y los graba en las tablas documentos y pedidos
*
* %v 04/01/2016 - MarianoL
***************************************************************************************************/
procedure CalcularTotales(p_RegPedidoPadre in  pedidos%rowtype)
is

   v_modulo       varchar2(100) := 'PKG_DIVIDIR_PEDIDO.CalcularTotales';

begin

   --Recorrer los PEDI asociados al PEDREF
   for v_RegPedido in (select dp.idpedido, d.iddoctrx, count(dp.sqdetallepedido) qtmateriales, sum(dp.amlinea) ammonto
                       from documentos d,
                            pedidos p,
                            detallepedidos dp
                       where d.idmovtrx = p_RegPedidoPadre.Iddoctrx
                         and d.cdcomprobante = 'PEDI'
                         and p.iddoctrx = d.iddoctrx
                         and dp.idpedido = p.idpedido
                       group by dp.idpedido, d.iddoctrx)
   loop
      --documentos
      update documentos d
      set d.amdocumento     = v_RegPedido.Ammonto,
          d.amnetodocumento = v_RegPedido.Ammonto
      where d.iddoctrx = v_RegPedido.Iddoctrx;

      --pedidos
      update pedidos p
      set p.ammonto      = v_RegPedido.Ammonto,
          p.qtmateriales = v_RegPedido.Qtmateriales
      where p.idpedido = v_RegPedido.Idpedido;

   end loop;

   return;

exception when others then
   n_pkg_vitalpos_log_general.write(2, 'Modulo: ' || v_modulo || '  Error: ' || Sqlerrm);
   raise;
end CalcularTotales;

/**************************************************************************************************
* Dado un pedido lo divide en nuevos PEDI y renombra el original como PEDREF
* REGLAS: - Una promomoción nunca se divide
*         - Si una línea supera el límite la divide en n líneas pero nunca cambia la unidad de medida
*
* %v 04/01/2016 - MarianoL
* %v 08/04/2021 - ChM ajusto para dividir promociones para pedidos de icorigen VTEX
* %v 21/04/2021 - ChM ajusto para dividir promociones para pedidos de canal TE estos traen de icorigen null
***************************************************************************************************/
procedure Dividir(p_idPedido in  pedidos.idpedido%type,
                  p_amLimite in  number,
                  p_ok       out integer,
                  p_error    out varchar2)
is

   v_modulo       varchar2(100) := 'PKG_DIVIDIR_PEDIDO.StatusIndicadores';
   v_RegPedido    pedidos%rowtype;
   v_RegDetalle   detallepedidos%rowtype;
   i              BINARY_INTEGER := 0;
   v_icExiste     integer;

   TYPE reg_Promo IS RECORD(cdPromo detallepedidos.cdpromo%type);
   TYPE tab_Promo IS TABLE OF reg_Promo INDEX BY BINARY_INTEGER;
   v_ListaPromo   tab_Promo;

begin
   p_ok := 0;
   v_ListaPromo.DELETE;

   --Buscar el pedido
   begin
      select *
      into v_RegPedido
      from pedidos p
      where p.idpedido = p_idPedido;
   exception when others then
      p_error := 'No se pudo dividir el pedido porque no existe.';
      return;
   end;

   --Renombrar el comprobante del pedido original de PEDI a PEDREF y eliminarlo de tx_pedidos_insert
   update documentos d
   set d.cdcomprobante = 'PEDREF  '
   where d.iddoctrx = v_RegPedido.Iddoctrx
     and d.cdcomprobante = 'PEDI    ';

   delete tx_pedidos_insert tx where tx.iddoctrx = v_RegPedido.Iddoctrx;

   --Recorrer el detalle del pedido
   for v_regDetalle in (select *
                        from detallepedidos d
                        where d.idpedido = p_idPedido
                         --verifica si es de origen VTEX excluye las lineas de promo
                         and case
                              --verifica si es de origen VTEX o TE excluye las lineas de promo
                              when nvl(v_RegPedido.icorigen,-1) in (4,-1) and d.icresppromo=0 then 1
                              when nvl(v_RegPedido.icorigen,-1) in (4,-1) and d.icresppromo=1 then 0                              
                              when nvl(v_RegPedido.icorigen,-1) not in (4,-1) then 1
                             end = 1     
                              )
   loop
     
      -- ChM los pedidos de VTEX  o TE no respetan promociones enteras                    
      if v_RegDetalle.Cdpromo is not null and nvl(v_RegPedido.icorigen,-1) not in (4,-1) then --Es parte de una PROMOCION

         --Buscar si la promo ya fue procesada
         v_icExiste := 0;
         i := v_ListaPromo.FIRST;
         while i is not null loop
            if v_ListaPromo(i).cdPromo = v_RegDetalle.Cdpromo then
               v_icExiste := 1;
            end if;
            i := v_ListaPromo.NEXT(i);
         end loop;

         --Si no fue procesada, procesarla ahora y marcarla
         if v_icExiste = 0 then
            PromoEntera(v_RegPedido, v_RegDetalle, p_amLimite);
            --Marcar la promo como procesada
            i := v_ListaPromo.COUNT + 1;
            v_ListaPromo(i).cdPromo := v_RegDetalle.Cdpromo;
         end if;

      else  --Línea NO PROMOCION

         if v_RegDetalle.Amlinea > p_amLimite then
            --La línea del pedido supera el límite, hay que partirla
            PartirLinea(v_RegPedido, v_RegDetalle, p_amLimite);
         else
            --Copiar la línea sin partirla
            GrabarLinea(v_RegPedido, v_RegDetalle, p_amLimite);
         end if;

      end if;
   end loop;

   --Calcular los totales y grabarlos en pedidos y en documentos
   CalcularTotales(v_RegPedido);

   p_ok := 1;
   return;

exception when others then
   n_pkg_vitalpos_log_general.write(2, 'Modulo: ' || v_modulo || '  Error: ' || Sqlerrm);
   raise;
end Dividir;

End;
/
