CREATE OR REPLACE PACKAGE PKG_CONTROL IS
/**************************************************************************************************
* PACKAGE PKG_CONTROL
* Este PKG controla que los datos generados por el POS sean correctos.  Si encuentra errores los
* escribe en la tblcontrolmensaje
* %v 16/09/2015 - MarianoL
***************************************************************************************************/

PROCEDURE Controlar;

procedure GrabarMensaje (p_idcontrolmensaje In tblcontrolmensaje.idcontrolmensaje%type,
                         p_cdsucursal       In tblcontrolmensaje.cdsucursal%type,
                         p_dtmensaje        In tblcontrolmensaje.dtmensaje%type,
                         p_dstitulo         In tblcontrolmensaje.dstitulo%type,
                         p_dsmensaje        In tblcontrolmensaje.dsmensaje%type,
                         p_icleido          In tblcontrolmensaje.icleido%type);
                         
PROCEDURE ControlarVTEXpromoPOS ( p_result   OUT integer,
                             	    p_mensaje  OUT varchar2);
PROCEDURE ControlarVTEXpromo ( p_cdsucursal IN sucursales.cdsucursal%type,
                               p_tipoerror  IN integer default 1, 
                               p_result     OUT integer 
                                 );                                                           

PROCEDURE ControlarVTEXproduct ( p_tipoerror  IN integer default 1,
                                 p_result     OUT integer);
                                 
PROCEDURE ControlarVTEXstock ( p_cdsucursal IN sucursales.cdsucursal%type,
                               p_tipoerror  IN integer default 1, 
                               p_result     OUT integer); 
                                       
PROCEDURE ControlarVTEXPrice ( p_cdsucursal IN sucursales.cdsucursal%type,
                               p_tipoerror  IN integer default 1, 
                               p_result     OUT integer);
                               
PROCEDURE ControlarVTEXOffer ( p_cdsucursal IN sucursales.cdsucursal%type,
                               p_tipoerror  IN integer default 1,
                               p_result     OUT integer); 
                                     
PROCEDURE ControlarVTEXCollection ( p_tipoerror  IN integer default 1, 
                                    p_result     OUT integer);  
                                    
PROCEDURE ControlarVTEXAdress  ( p_tipoerror  IN integer default 1,
                                 p_result     OUT integer);
                                 
PROCEDURE ControlarVTEXOrders ( p_tipoerror  IN integer default 1,
                                p_result     OUT integer);                                   
                                 
PROCEDURE ControlarVTEXClients ( p_tipoerror  IN integer default 1, 
                                 p_result     OUT integer);    
                                 
                                 
 PROCEDURE ControlarPreciosExtranet(p_result    OUT integer);
 
   Procedure Control_Replicas_CAR(p_cdsucursal IN sucursales.cdsucursal%TYPE,
                                 p_fecha      IN date,
                                 P_Result     OUT varchar2);
                                                                                                                                                                            
END;
/
CREATE OR REPLACE PACKAGE BODY PKG_CONTROL IS

g_dtDesde            date;
g_dtHasta            date;

/***************************************************************************************************
* procedure GrabarMensaje
* Graba el mensaje en caso que no exista
*
* %v 30/09/2015 - JBodnar
* %v 01/02/2017 - IAquilano - Se agrega variable para poder recibir parametro nulo y generar el sys_guide
***************************************************************************************************/
procedure GrabarMensaje (p_idcontrolmensaje In tblcontrolmensaje.idcontrolmensaje%type,
                         p_cdsucursal       In tblcontrolmensaje.cdsucursal%type,
                         p_dtmensaje        In tblcontrolmensaje.dtmensaje%type,
                         p_dstitulo         In tblcontrolmensaje.dstitulo%type,
                         p_dsmensaje        In tblcontrolmensaje.dsmensaje%type,
                         p_icleido          In tblcontrolmensaje.icleido%type)
IS
   v_idcontrolmensaje    tblcontrolmensaje.idcontrolmensaje%type;
   v_modulo               varchar2(100) := 'PKG_CONTROL.GrabarMensaje';
   v_Existe               integer;
   PRAGMA AUTONOMOUS_TRANSACTION;

BEGIN
      v_idcontrolmensaje := p_idcontrolmensaje;
      
      If v_idcontrolmensaje is null then
       v_idcontrolmensaje := (sys_guid());
      end if;
          
      select count(*)
      into v_Existe
      from tblcontrolmensaje co
      where nvl(co.cdsucursal,'x') = nvl(p_cdsucursal,'x')
        and trunc(co.dtmensaje) = trunc(p_dtmensaje)
        and trim(co.dstitulo) = trim(p_dstitulo)
        and trim(co.dsmensaje) = trim(p_dsmensaje);
        
      --Si es demora de job lo muestra siempre aunque se repita
      If p_dstitulo='Job Demorado ' then
        
         select count(*)
         into v_Existe
         from tblcontrolmensaje co
         where nvl(co.cdsucursal,'x') = nvl(p_cdsucursal,'x')
         and trunc(co.dtmensaje) = trunc(p_dtmensaje)
         and trim(co.dstitulo) = trim(p_dstitulo)
         and trim(co.dsmensaje) = trim(p_dsmensaje)
         and co.icleido = p_icleido;
         
         --Si no  existe lo graba
         if  v_Existe=0 then     
           insert into tblcontrolmensaje
           (idcontrolmensaje, cdsucursal, dtmensaje, dstitulo, dsmensaje, icleido)
           values
           (v_idcontrolmensaje, p_cdsucursal, p_dtmensaje, p_dstitulo, p_dsmensaje, p_icleido);
         end if; 
         
         commit;
         return;       
      end if;  

      If v_Existe = 0 then
         --Si el mensaje no existe lo grabo pero con icLeido = -1
         if p_idcontrolmensaje is null then
             insert into tblcontrolmensaje
              (idcontrolmensaje, cdsucursal, dtmensaje, dstitulo, dsmensaje, icleido)
            values
             (v_idcontrolmensaje, p_cdsucursal, p_dtmensaje, p_dstitulo, p_dsmensaje, p_icleido);
         else
             insert into tblcontrolmensaje
             (idcontrolmensaje, cdsucursal, dtmensaje, dstitulo, dsmensaje, icleido)
             values
             (v_idcontrolmensaje, p_cdsucursal, p_dtmensaje, p_dstitulo, p_dsmensaje, -1);
          end if;
      Elsif v_Existe = 1 then
         --Si el mensaje existe y tiene icLeido = -1 lo updateo con icLeido = 0
         update tblcontrolmensaje co
         set icLeido = p_icleido
         where icLeido = -1
          and nvl(co.cdsucursal,'x') = nvl(p_cdsucursal,'x')
          and trunc(co.dtmensaje) = trunc(p_dtmensaje)
          and trim(co.dstitulo) = trim(p_dstitulo)
          and trim(co.dsmensaje) = trim(p_dsmensaje);
      end if;

      commit;
      Return;

EXCEPTION WHEN OTHERS THEN
   n_pkg_vitalpos_log_general.write(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM);
   RETURN;
end GrabarMensaje;

/***************************************************************************************************
* function GetConsumidorFinal
* Dado una sucursal devuelve el idEntidad del CF desconocido
*
* %v 16/09/2015 - MarianoL
***************************************************************************************************/
function GetConsumidorFinal(p_servidor in sucursales.servidor%type)
return entidades.identidad%type
is
   v_Result               entidades.identidad%type;

begin

   EXECUTE IMMEDIATE 'select GetVlparametro@' || p_servidor || '  (''CdConsFinal'', ''General'') as CF from dual ' INTO v_Result;

   return v_Result;

exception when others then
   return null;
end GetConsumidorFinal;


/***************************************************************************************************
* procedure ControlarFacturas
* Controla que las FC y ND hayan sido imputadas correctamente en la tblcobranza y que estén en estado correcto
*
* %v 16/09/2015 - MarianoL
***************************************************************************************************/
procedure ControlarFacturas
IS
   v_modulo               varchar2(100) := 'PKG_CONTROL.ControlarFacturas';
   v_amUsado              number;
   v_dsMensaje            varchar2(4000);
   v_Existe               integer;

BEGIN

   -- Buscar las FCs y NDs generadas en el día o las que hoy fueron usadas para cobranzas
   for v_RegTmp in (select iddoctrx, cdestadocomprobante, amdocumento
                    from( select d.iddoctrx, d.cdestadocomprobante, d.amdocumento
                          from documentos d
                          where d.dtdocumento between g_dtDesde and g_dtHasta
                            and substr(d.cdcomprobante,1,2) in ('FC','ND')
                          union
                          select d.iddoctrx, d.cdestadocomprobante, d.amdocumento
                          from tblcobranza c,
                               documentos d
                          where c.dtimputado between g_dtDesde and g_dtHasta
                            and d.iddoctrx = c.iddoctrx
                            and d.dtdocumento between g_dtDesde and g_dtHasta
                            and substr(d.cdcomprobante,1,2) in ('FC','ND'))
                     group by iddoctrx, cdestadocomprobante, amdocumento)
   loop

      --Verificar cuánto se usó del documento
      select sum(c.amimputado)
      into v_amUsado
      from tblcobranza c
      where c.iddoctrx = v_RegTmp.Iddoctrx;

      v_dsMensaje := 'idDocTrx:' || v_RegTmp.Iddoctrx || ' amDocumento:' || v_RegTmp.Amdocumento || ' Usado:' || v_amUsado || ' Estado:' || v_RegTmp.Cdestadocomprobante;

      if v_amUsado > v_RegTmp.Amdocumento then

         GrabarMensaje(sys_guid(), null, sysdate, 'Documento usado por importe mayor al amDocumento', v_dsMensaje, 0);

      elsif v_amUsado < v_RegTmp.Amdocumento and  v_RegTmp.Cdestadocomprobante in ('5','6') and  abs(v_amUsado - v_RegTmp.Amdocumento) > (0.01) then

         GrabarMensaje(sys_guid(), null, sysdate, 'Documento usado parcialmente con estado inconsistente', v_dsMensaje, 0);

      elsif v_amUsado = v_RegTmp.Amdocumento and v_RegTmp.Cdestadocomprobante not in ('3','5','6') then

         GrabarMensaje(sys_guid(), null, sysdate, 'Documento usado totalmente con estado inconsistente', v_dsMensaje, 0);

      end if;

      --En caso que el documento esté con deuda y transaccionado verificar si está como deudor
      if v_amUsado < v_RegTmp.Amdocumento and abs(v_amUsado - v_RegTmp.Amdocumento) > (0.01) then
         select count(*)
         into v_Existe
         from tblmovcuenta mc
         where mc.iddoctrx = v_RegTmp.Iddoctrx;

         if v_Existe <> 0 then
            --Buscar si está en deudor
            select count(*)
            into v_Existe
            from tbldocumentodeuda dd
            where dd.iddoctrx = v_RegTmp.Iddoctrx
              and dd.dtestadofin is null;
            if v_Existe <> 1 and v_RegTmp.Cdestadocomprobante <> '3' then
               GrabarMensaje(sys_guid(), null, sysdate, 'Documento condeuda no está como Moroso o está más de una vez', v_dsMensaje, 0);
            end if;
         end if;

      end if;



   end loop;

   return;

EXCEPTION WHEN OTHERS THEN
   rollback;
   n_pkg_vitalpos_log_general.write(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM);
   RETURN;
end ControlarFacturas;

/***************************************************************************************************
* procedure ControlarNC
* Controla que las NC hayan sido imputadas correctamente en la tblcobranza y que estén en estado correcto
*
* %v 16/09/2015 - MarianoL
***************************************************************************************************/
procedure ControlarNC
IS
   v_modulo               varchar2(100) := 'PKG_CONTROL.ControlarNC';
   v_amUsado              number;
   v_dsMensaje            varchar2(4000);
   v_amFactura            number;

BEGIN

   -- Buscar las NCs generadas en el día o las que hoy fueron usadas para cobranzas
   for v_RegTmp in (select iddoctrx, cdestadocomprobante, amdocumento
                    from( select d.iddoctrx, d.cdestadocomprobante, (d.amdocumento*-1) amdocumento
                          from documentos d
                          where d.dtdocumento between g_dtDesde and g_dtHasta
                            and d.cdcomprobante like 'NC%'
                          union
                          select d.iddoctrx, d.cdestadocomprobante, (d.amdocumento*-1) amdocumento
                          from tblcobranza c,
                               documentos d
                          where c.dtimputado between g_dtDesde and g_dtHasta
                            and d.iddoctrx = c.iddoctrx_pago
                            and d.dtdocumento between g_dtDesde and g_dtHasta
                            and d.cdcomprobante like 'NC%')
                     group by iddoctrx, cdestadocomprobante, amdocumento)
   loop

      --Verificar cuánto se usó de la NC
      select sum(c.amimputado)
      into v_amUsado
      from tblcobranza c
      where c.iddoctrx_pago = v_RegTmp.Iddoctrx;

      v_dsMensaje := 'idDocTrx:' || v_RegTmp.Iddoctrx || ' amDocumento:' || v_RegTmp.Amdocumento || ' Usado:' || v_amUsado || ' Estado:' || v_RegTmp.Cdestadocomprobante;

      if v_amUsado > v_RegTmp.Amdocumento then

         GrabarMensaje(sys_guid(), null, sysdate, 'NC usada por importe mayor al amDocumento', v_dsMensaje, 0);

      elsif v_amUsado < v_RegTmp.Amdocumento and  v_RegTmp.Cdestadocomprobante in ('3','5','6') then

         GrabarMensaje(sys_guid(), null, sysdate, 'NC usada parcialmente con estado inconsistente', v_dsMensaje, 0);

/*      elsif v_amUsado = v_RegTmp.Amdocumento and v_RegTmp.Cdestadocomprobante not in ('3','5','6') then

         GrabarMensaje(sys_guid(), null, sysdate, 'NC usada totalmente con estado inconsistente', v_dsMensaje, 0);*/

      end if;

      --Verificar si la NC anuló la factura
      begin
         select fc.amdocumento
         into v_amFactura
         from documentos nc,
              movmateriales mm,
              documentos fc
         where nc.iddoctrx = v_RegTmp.Iddoctrx
           and mm.idmovmateriales = nc.idmovmateriales
           and fc.iddoctrx = mm.idmovmateriales
           and trim(fc.cdestadocomprobante) in ('3','6');

         if v_amFactura <> v_RegTmp.Amdocumento or v_amUsado <> v_RegTmp.Amdocumento or v_amFactura <> v_amUsado then

            GrabarMensaje(sys_guid(), null, sysdate, 'NC anula una FC por importe diferente', v_dsMensaje, 0);
         end if;
      exception when others then
         null;
      end;

   end loop;

   return;

EXCEPTION WHEN OTHERS THEN
   rollback;
   n_pkg_vitalpos_log_general.write(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM);
   RETURN;
end ControlarNC;

/***************************************************************************************************
* procedure ControlarIngresos
* Controla que los ingresos hayan sido imputados correctamente en la tblcobranza y que estén en estado correcto
*
* %v 16/09/2015 - MarianoL
***************************************************************************************************/
procedure ControlarIngresos
IS
   v_modulo               varchar2(100) := 'PKG_CONTROL.ControlarIngresos';
   v_amUsado              number;
   v_dsMensaje            varchar2(4000);

BEGIN

   -- Buscar los ingresos del día o los que hoy fueron usados para cobranzas
   for v_RegTmp in (select i.idingreso, i.amingreso, i.cdestado
                    from (select mc.idingreso
                          from tblmovcuenta mc
                          where mc.dtmovimiento between g_dtDesde and g_dtHasta
                            and mc.idingreso is not null
                          union
                          select c.idingreso
                          from tblcobranza c
                          where c.dtimputado between g_dtDesde and g_dtHasta
                            and c.idingreso is not null
                          ) t,
                          tblingreso i,
                          tblconfingreso ci,
                          tblaccioningreso a
                    where i.idingreso = t.idingreso
                      and ci.cdconfingreso = i.cdconfingreso
                      and ci.cdsucursal = i.cdsucursal
                      and a.cdaccion = ci.cdaccion
                      and a.vlmultiplicador = 1 --Solo ingresos
                    group by i.idingreso, i.amingreso, i.cdestado)
   loop

      --Verificar cuánto se usó del ingreso
      select sum(c.amimputado)
      into v_amUsado
      from tblcobranza c
      where c.idingreso = v_RegTmp.Idingreso;

      v_dsMensaje := 'idIngreso:' || v_RegTmp.Idingreso || ' amIngreso:' || v_RegTmp.Amingreso || ' Usado:' || v_amUsado || ' Estado:' || v_RegTmp.Cdestado;

      if v_amUsado <> 0 and v_amUsado > v_RegTmp.Amingreso then

         GrabarMensaje(sys_guid(), null, sysdate, 'Ingreso usado por importe mayor al amIngreso', v_dsMensaje, 0);

      elsif v_amUsado <> 0 and v_amUsado < v_RegTmp.Amingreso and  v_RegTmp.Cdestado not in ('1','2') then

         GrabarMensaje(sys_guid(), null, sysdate, 'Ingreso usado parcialmente con estado inconsistente', v_dsMensaje, 0);

      elsif v_amUsado <> 0 and v_amUsado = v_RegTmp.Amingreso and v_RegTmp.Cdestado not in ('3','4','5') then

         GrabarMensaje(sys_guid(), null, sysdate, 'Ingreso usado totalmente con estado inconsistente', v_dsMensaje, 0);

      elsif v_amUsado = 0 and  v_RegTmp.Cdestado not in ('0','1','2') then

         GrabarMensaje(sys_guid(), null, sysdate, 'Ingreso no usado con estado inconsistente', v_dsMensaje, 0);

      end if;

   end loop;

   return;

EXCEPTION WHEN OTHERS THEN
   rollback;
   n_pkg_vitalpos_log_general.write(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM);
   RETURN;
end ControlarIngresos;

/***************************************************************************************************
* procedure ControlarEgresos
* Controla que los egresos que hayan sido imputados correctamente en la tblcobranza y que estén en estado correcto
*
* %v 16/09/2015 - MarianoL
***************************************************************************************************/
procedure ControlarEgresos
IS
   v_modulo               varchar2(100) := 'PKG_CONTROL.ControlarEgresos';
   v_amUsado              number;
   v_dsMensaje            varchar2(4000);

BEGIN

   -- Buscar los egresos del día o los que hoy fueron usados para cobranzas
   for v_RegTmp in (select i.idingreso, abs(i.amingreso) amingreso, i.cdestado
                    from (select mc.idingreso
                          from tblmovcuenta mc
                          where mc.dtmovimiento between g_dtDesde and g_dtHasta
                            and mc.idingreso is not null
                          union
                          select c.idingreso
                          from tblcobranza c
                          where c.dtimputado between g_dtDesde and g_dtHasta
                            and c.idingreso_pago is not null
                          ) t,
                          tblingreso i,
                          tblconfingreso ci,
                          tblaccioningreso a
                    where i.idingreso = t.idingreso
                      and ci.cdconfingreso = i.cdconfingreso
                      and ci.cdsucursal = i.cdsucursal
                      and a.cdaccion = ci.cdaccion
                      and a.vlmultiplicador = -1 --Solo egresos
                    group by i.idingreso, abs(i.amingreso), i.cdestado)
   loop

      --Verificar cuánto se usó del egreso
      select sum(c.amimputado)
      into v_amUsado
      from tblcobranza c
      where c.idingreso = v_RegTmp.Idingreso;

      v_dsMensaje := 'idIngreso:' || v_RegTmp.Idingreso || ' amIngreso:' || v_RegTmp.Amingreso || ' Usado:' || v_amUsado || ' Estado:' || v_RegTmp.Cdestado;

      if v_amUsado <> 0 and v_amUsado > v_RegTmp.Amingreso then

         GrabarMensaje(sys_guid(), null, sysdate, 'Egreso usado por importe mayor al amIngreso', v_dsMensaje, 0);

      elsif v_amUsado <> 0 and v_amUsado < v_RegTmp.Amingreso and  v_RegTmp.Cdestado not in ('1','2') then

         GrabarMensaje(sys_guid(), null, sysdate, 'Egreso usado parcialmente con estado inconsistente', v_dsMensaje, 0);

      elsif v_amUsado <> 0 and v_amUsado = v_RegTmp.Amingreso and v_RegTmp.Cdestado not in ('3','4','5') then

         GrabarMensaje(sys_guid(), null, sysdate, 'Egreso usado totalmente con estado inconsistente', v_dsMensaje, 0);

      elsif v_amUsado = 0 and  v_RegTmp.Cdestado not in ('0','1') then

         GrabarMensaje(sys_guid(), null, sysdate, 'Egreso no usado con estado inconsistente', v_dsMensaje, 0);

      end if;

   end loop;

   return;

EXCEPTION WHEN OTHERS THEN
   rollback;
   n_pkg_vitalpos_log_general.write(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM);
   RETURN;
end ControlarEgresos;

/***************************************************************************************************
* procedure ControlarCobranzas
* Controla que en las conbranzas del día se cuemplan las siguientes reglas:
* idDocTrx:       debe ser una FC o ND
* idDocTrx_pago:  debe ser una NC
* idIngreso:      debe ser un ingreso con vlMultiplicador = 1
* idIngreso_pago: debe ser un ingreso con vlMultiplicador = -1
*
* Además controla que en una cobranza haya siempre un positivo y un negativo
* %v 16/09/2015 - MarianoL
***************************************************************************************************/
procedure ControlarCobranzas
IS
   v_modulo               varchar2(100) := 'PKG_CONTROL.ControlarCobranzas';
   v_dsMensaje            varchar2(4000);
   v_Existe               integer;

BEGIN

   -- Buscar las cobranzas del día
   for v_RegTmp in (select c.*
                    from tblcobranza c
                    where c.dtimputado between g_dtDesde and g_dtHasta
                      and c.amimputado <> 0)
   loop

      v_dsMensaje := 'idCobranza:' || v_RegTmp.Idcobranza;

/*      if v_RegTmp.Iddoctrx is not null then
         select count(*)
         into v_existe
         from documentos d
         where d.iddoctrx = v_RegTmp.Iddoctrx
           and substr(d.cdcomprobante,1,2) in ('FC','ND');
         if v_Existe = 0 then
            insert into tblcontrolmensaje
            (idcontrolmensaje, cdsucursal, dtmensaje, dstitulo, dsmensaje, icleido)
            values
            (sys_guid(), null, sysdate, 'Tabla tblcobranza con idDocTrx que no es FC o ND', v_dsMensaje, 0);
         end if;
      end if;

      if v_RegTmp.Iddoctrx_pago is not null then
         select count(*)
         into v_existe
         from documentos d
         where d.iddoctrx = v_RegTmp.Iddoctrx_pago
           and substr(d.cdcomprobante,1,2) in ('NC');
         if v_Existe = 0 then
            insert into tblcontrolmensaje
            (idcontrolmensaje, cdsucursal, dtmensaje, dstitulo, dsmensaje, icleido)
            values
            (sys_guid(), null, sysdate, 'Tabla tblcobranza con idDocTrx_pago que no es NC', v_dsMensaje, 0);
         end if;
      end if;
*/
      if v_RegTmp.Idingreso is not null then
         select count(*)
         into v_Existe
         from tblingreso i,
              tblconfingreso ci,
              tblaccioningreso a
         where i.idingreso = v_RegTmp.Idingreso
           and ci.cdconfingreso = i.cdconfingreso
           and ci.cdsucursal = i.cdsucursal
           and a.cdaccion = ci.cdaccion;
           --and a.vlmultiplicador = 1;
         if v_Existe = 0 then
            insert into tblcontrolmensaje
            (idcontrolmensaje, cdsucursal, dtmensaje, dstitulo, dsmensaje, icleido)
            values
            (sys_guid(), null, sysdate, 'Tabla tblcobranza con idIngreso que no es INGRESO', v_dsMensaje, 0);
         end if;
      end if;

      if v_RegTmp.Idingreso_Pago is not null then
         select count(*)
         into v_Existe
         from tblingreso i,
              tblconfingreso ci,
              tblaccioningreso a
         where i.idingreso = v_RegTmp.Idingreso_pago
           and ci.cdconfingreso = i.cdconfingreso
           and ci.cdsucursal = i.cdsucursal
           and a.cdaccion = ci.cdaccion;
           --and a.vlmultiplicador = -1;
         if v_Existe = 0 then
            insert into tblcontrolmensaje
            (idcontrolmensaje, cdsucursal, dtmensaje, dstitulo, dsmensaje, icleido)
            values
            (sys_guid(), null, sysdate, 'Tabla tblcobranza con idIngreso_pago que no es EGRESO', v_dsMensaje, 0);
         end if;
      end if;

      if v_RegTmp.Idingreso is not null and v_RegTmp.Iddoctrx_Pago is not null then

         GrabarMensaje(sys_guid(), null, sysdate, 'Tabla tblcobranza con idIngreso y idDocTrx_Pago', v_dsMensaje, 0);
--      elsif v_RegTmp.Iddoctrx is not null and v_RegTmp.Idingreso_Pago is not null then
--         insert into tblcontrolmensaje
--         (idcontrolmensaje, cdsucursal, dtmensaje, dstitulo, dsmensaje, icleido)
--         values
--         (sys_guid(), null, sysdate, 'Tabla tblcobranza con idDocTrx y idIngreso_Pago', v_dsMensaje, 0);
      end if;

/*      if v_RegTmp.Amimputado = 0 then

         GrabarMensaje(sys_guid(), null, sysdate, 'Registro de cobranza con importe en 0', v_dsMensaje, 0);
      end if;*/

   end loop;

   return;

EXCEPTION WHEN OTHERS THEN
   rollback;
   n_pkg_vitalpos_log_general.write(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM);
   RETURN;
end ControlarCobranzas;

/***************************************************************************************************
* procedure ControlarDeudores
* Controla que la información de deudores en la tbldocumentodeuda sea consistente
*
* %v 16/09/2015 - MarianoL
***************************************************************************************************/
procedure ControlarDeudores
IS
   v_modulo               varchar2(100) := 'PKG_CONTROL.ControlarDeudores';
   v_dsMensaje            varchar2(4000);
   v_cdEstadoComprobante  documentos.cdestadocomprobante%type;
   v_amDeuda              number;
   v_Existe               integer;

BEGIN

   -- Buscar los deudores del día
   for v_RegTmp in (select dd.*
                    from tbldocumentodeuda dd
                    where dd.dtestadoinicio between g_dtDesde and g_dtHasta
                       or dd.dtestadofin between g_dtDesde and g_dtHasta)
   loop
      select d.cdestadocomprobante, pkg_documento_central.GetDeudaDocumento(d.iddoctrx, sysdate, 1)
      into v_cdEstadoComprobante, v_amDeuda
      from documentos d
      where d.iddoctrx = v_RegTmp.iddoctrx;

      v_dsMensaje := 'idDocumentoDeuda:' || v_RegTmp.iddocumentodeuda || ' idDocTrx:' || v_RegTmp.iddoctrx || ' EstadoDeuda:'|| v_RegTmp.cdestado || ' dtInicio:' || to_char(v_RegTmp.dtestadoinicio,'dd/mm/yyyy') || ' EstadoComprobante: ' || v_cdEstadoComprobante || ' amDeuda' || v_amDeuda;

      --Si no tiene fecha de fin
      if v_RegTmp.dtestadofin is null then
         if v_cdEstadoComprobante not in ('1','2','4') or v_amDeuda <= 0 then

            GrabarMensaje(sys_guid(), null, sysdate, 'Existe un documento como deudor con estado o deuda inconsistente ', v_dsMensaje, 0);
         end if;
      else
         --Si tiene fecha fin el documento no debe tener deuda o debe haber otro registro sin fechafin
         if v_cdEstadoComprobante in ('1','2','4') or v_amDeuda > 0 then

            select count(*)
            into v_Existe
            from tbldocumentodeuda dd
            where dd.iddoctrx = v_RegTmp.Iddoctrx
              and dd.dtestadoinicio >= v_RegTmp.dtestadofin
              and dd.dtestadofin is null;

            if v_Existe <> 1 then

               GrabarMensaje(sys_guid(), null, sysdate, 'Existe un documento con deuda pero no figura como deudor', v_dsMensaje, 0);
            end if;
         end if;
      end if;

   end loop;

   return;

EXCEPTION WHEN OTHERS THEN
   rollback;
   n_pkg_vitalpos_log_general.write(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM);
   RETURN;
end ControlarDeudores;

/***************************************************************************************************
* procedure ControlarCF
* Controla que la información del CF desconocido sea consistente
*
* %v 16/09/2015 - MarianoL
***************************************************************************************************/
procedure ControlarCF
IS
   v_modulo               varchar2(100) := 'PKG_CONTROL.ControlarCF';
   v_dsMensaje            varchar2(4000);
   v_idEntidad            entidades.identidad%type;
   v_idCuenta             tblcuenta.idcuenta%type;
   v_amSaldo              number;

BEGIN

   -- Buscar las sucursales migradas
   for v_RegTmp in (select s.servidor, s.cdsucursal
                    from tblmigracion m,
                         sucursales s
                    where s.cdsucursal = m.cdsucursal)
   loop
      if pkg_replica_suc.GetActiva(v_RegTmp.cdSucursal) = 1 then

         v_idEntidad := GetConsumidorFinal(v_RegTmp.servidor);

         --Buscar la cuenta del CF
         select c.idcuenta
         into v_idCuenta
         from tblcuenta c
         where c.identidad = v_idEntidad
           and c.cdsucursal = v_RegTmp.Cdsucursal
           and c.cdtipocuenta = '1';

         v_amSaldo := pkg_cuenta_central.GetSaldo(v_idCuenta);

         v_dsMensaje := 'Sucursal:' || v_RegTmp.Servidor || ' idCuenta:' || v_idCuenta || ' Saldo:'|| v_amSaldo ;

         if v_amSaldo <> 0 then

            GrabarMensaje(sys_guid(), null, sysdate, 'CF de sucursal ' || upper(v_RegTmp.Servidor) || ' con saldo', v_dsMensaje, 0);
         end if;

      end if;
   end loop;

   return;

EXCEPTION WHEN OTHERS THEN
   rollback;
   n_pkg_vitalpos_log_general.write(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM);
   RETURN;
end ControlarCF;

/***************************************************************************************************
* procedure ControlarPagares
* Controla que los pagarés en estado 1 tengan facturas con deuda
*
* %v 16/09/2015 - MarianoL
***************************************************************************************************/
procedure ControlarPagares
IS
   v_modulo               varchar2(100) := 'PKG_CONTROL.ControlarPagares';
   v_dsMensaje            varchar2(4000);
   v_cdEstadoPagare       documentos.cdestadocomprobante%type;
   v_icDeuda              integer;

BEGIN

   --Buscar los pagares que algún documento participó en cobranzas hoy
   for v_RegTmp in (select unique pd.iddoctrxpagare
                    from tblcobranza c,
                         tblpagaredetalle pd
                    where c.dtimputado between g_dtDesde and g_dtHasta
                      and pd.iddoctrxdocumento = c.iddoctrx)
   loop

      --Buscar el estado del pagaré
      select d.cdestadocomprobante
      into v_cdEstadoPagare
      from documentos d
      where d.iddoctrx = v_RegTmp.Iddoctrxpagare;

      v_icDeuda := 0;

      --Buscar los documentos que componen el pagaré
      for v_RegDocu in (select pd.iddoctrxdocumento
                        from tblpagaredetalle pd
                        where pd.iddoctrxpagare = v_RegTmp.Iddoctrxpagare)
      loop

         --Verificar si el documento tiene deuda
         if pkg_documento_central.GetDeudaDocumento(v_RegDocu.Iddoctrxdocumento) <> 0 then
            v_icDeuda := 1;  --Documento tiene deuda
         end if;

         exit when v_icDeuda = 1;
      end loop;

      v_dsMensaje := 'Pagaré:' || v_RegTmp.Iddoctrxpagare;

      if v_icDeuda = 0 and v_cdEstadoPagare = '1' then

         GrabarMensaje(sys_guid(), null, sysdate, 'Pagaré en estado 1 con documentos sin deuda.', v_dsMensaje, 0);
      elsif v_icDeuda = 1 and v_cdEstadoPagare = '5' then

         GrabarMensaje(sys_guid(), null, sysdate, 'Pagaré en estado 5 con documentos con deuda.', v_dsMensaje, 0);
      end if;

   end loop;

   return;

EXCEPTION WHEN OTHERS THEN
   rollback;
   n_pkg_vitalpos_log_general.write(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM);
   RETURN;
end ControlarPagares;

/***************************************************************************************************
* procedure ControlarMontoPedidos
* Controla que los pedidos que llegan AC no tengan monto cero
*
* %v 10/10/2015 - JBodnar
***************************************************************************************************/
procedure ControlarMontoPedidos
IS
   v_modulo               varchar2(100) := 'PKG_CONTROL.ControlarMontoPedidos';
BEGIN
   --Buscar los pedidos que tienen monto cero
   for v_RegTmp in (select pe.idpedido
                    from pedidos pe
                    where pe.dtaplicacion between g_dtDesde and g_dtHasta
                    and pe.ammonto = 0 )
   loop
         GrabarMensaje(sys_guid(), null, sysdate, 'Pedido con monto en 0', 'IdPedido: '||v_RegTmp.Idpedido, 0);
   end loop;
   return;

EXCEPTION WHEN OTHERS THEN
   rollback;
   n_pkg_vitalpos_log_general.write(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM);
   RETURN;
end ControlarMontoPedidos;


/***************************************************************************************************
* procedure ControlarSqcomprobante
* Controla que los documentos no permanezcan con sqcomprobante en 0
*
* %v 28/12/2016 - APW 
***************************************************************************************************/
procedure ControlarSqcomprobante
IS
   v_modulo               varchar2(100) := 'PKG_CONTROL.ControlarSqcomprobante';
BEGIN
   --Buscar los pedidos que tienen monto cero
   for v_RegTmp in (select do.iddoctrx, do.cdsucursal
                    from documentos do
                    where do.dtdocumento between g_dtDesde and g_dtHasta
                    and (do.cdcomprobante like 'FC%' or do.cdcomprobante like 'NC%' or do.cdcomprobante like 'ND%')
                    and do.sqcomprobante = 0
                    and do.cdestadocomprobante not in ('1       ') )
   loop
         GrabarMensaje(sys_guid(), v_RegTmp.cdsucursal, sysdate, 'Documento sqcomprobante 0', 'Iddoctrx: '||v_RegTmp.iddoctrx, 0);
   end loop;
   return;

EXCEPTION WHEN OTHERS THEN
   rollback;
   n_pkg_vitalpos_log_general.write(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM);
   RETURN;
end ControlarSqcomprobante;

/***************************************************************************************************
* procedure ControlarAliviosDuplicados
* Controla si un ingreso se alivio mas de una vez
*
* %v 16/10/2015 - JBodnar
***************************************************************************************************/
procedure ControlarAliviosDuplicados
IS
   v_modulo               varchar2(100) := 'PKG_CONTROL.ControlarAliviosDuplicados';
BEGIN
   --Buscar los ingresos aliviados y confirmados mas de una vez
   for v_RegTmp in (select ii.idingreso, ii.cdsucursal
                    from tblingreso ii,
                    (select al.idingreso, count(*)
                    from tblaliviodetalle al where
                    al.cdestado='2'--Alivio confirmado
                    and al.idingreso is not null
                    having count(*) > 1 --Se alivio mas de una
                    group by al.idingreso) ali
                    where ali.idingreso=ii.idingreso
                    and ii.dtingreso between g_dtDesde and g_dtHasta)
   loop
        GrabarMensaje(sys_guid(), v_RegTmp.Cdsucursal, sysdate, 'Ingreso con alivio duplicado', 'IdIngreso: '||v_RegTmp.idingreso, 0);
   end loop;
   return;

EXCEPTION WHEN OTHERS THEN
   rollback;
   n_pkg_vitalpos_log_general.write(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM);
   RETURN;
end ControlarAliviosDuplicados;


/***************************************************************************************************
* procedure ControlarCierreLote
* Controla si un ingreso se alivio mas de una vez
*
* %v 24/05/2016 - JBodnar
***************************************************************************************************/
procedure ControlarCierreLote
IS
   v_modulo               varchar2(100) := 'PKG_CONTROL.ControlarCierreLote';
BEGIN
   --Buscar los ingresos del tipo CL, Tercero, CE que no se grabaron en la tblcierrelote
   for v_RegTmp in (select ii.idingreso, ii.cdsucursal
                    from tblingreso ii, tblconfingreso ci
                    where ii.cdconfingreso=ci.cdconfingreso
                    and ci.cdforma in ('2','3','5') --CL, Tercero, CE
                    and ci.cdaccion=1 --Ingreso
                    and ii.cdsucursal=ci.cdsucursal
                    and ci.cdmedio not in ('11','13') --Contracargos / Recargo Cl
                    and ii.dtingreso between g_dtDesde and g_dtHasta
                    and not exists (select 1 from tblcierrelote cl
                                    where cl.idingreso=ii.idingreso))
   loop
        GrabarMensaje(sys_guid(), v_RegTmp.Cdsucursal, sysdate, 'Ingreso no grabado en TblcierreLote', 'IdIngreso: '||v_RegTmp.idingreso, 0);
   end loop;
   return;

EXCEPTION WHEN OTHERS THEN
   rollback;
   n_pkg_vitalpos_log_general.write(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM);
   RETURN;
end ControlarCierreLote;

/***************************************************************************************************
* procedure ControlarJobsColgados
* Controla si un proceso de los que se ejecutan por job está corriendo hace más de 30 minutos
* %v 01/02/2016 - APW
***************************************************************************************************/
procedure ControlarJobsDemorados
IS
   v_modulo               varchar2(100) := 'PKG_CONTROL.ControlarJobsColgados';
BEGIN
   -- supongo que ningún proceso de los que corre por job puede estar activo más de media hora
   for v_RegTmp in (select j.job, j.what, j.this_date
                    from user_jobs j
                    where j.THIS_DATE is not null -- está corriendo ahora
                    and   round((sysdate - j.THIS_DATE)*1440, 0) > 60 -- inició hace más de 60 minutos
                    and   j.JOB not in (1818) --Excluye los job que tardan mucho tiempo en procesar
                    and   j.what not like '%PKG_CONCILIACION_CL%'
                    and   j.what not like '%CompletaNroComprobante%')
   loop
        GrabarMensaje(sys_guid(), 'AC', sysdate, 'Job Demorado ', 'job: '||v_RegTmp.job||' '||v_RegTmp.what||
                                                 ' desde: '||to_char(v_RegTmp.This_Date,'dd/mm/yyyy hh24:mi'), 0);
   end loop;
   return;

EXCEPTION WHEN OTHERS THEN
   rollback;
   n_pkg_vitalpos_log_general.write(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM);
   RETURN;
end ControlarJobsDemorados;

/***************************************************************************************************
* procedure ControlarNotasDebito
* Controla si esta pendiente de generar una ND ganancia por el proceso de conciliacion
*
* %v 18/08/2016 - JBodnar
***************************************************************************************************/
procedure ControlarNotasDebito
IS
   v_modulo               varchar2(100) := 'PKG_CONTROL.ControlarNotasDebito';
BEGIN
   --Buscar los ingresos del tipo CL, Tercero, CE que no se grabaron en la tblcierrelote
   for v_RegTmp in (--Controlar que documentos faltan generar
                    select tnc.amnotadecredito, s.cdsucursal, s.dssucursal, tnc.cdcuit
                    from tblclnotadecredito tnc,
                    sucursales s
                    where tnc.iddoctrx is null
                    and tnc.cdsucursal = s.cdsucursal
                    and tnc.idejecucionconciliacion='ND-Ganancia')
   loop
        GrabarMensaje(sys_guid(), v_RegTmp.Cdsucursal, sysdate, 'ND-Ganancia no generada',' Cuit: '||v_RegTmp.Cdcuit||' Monto: '||v_RegTmp.Amnotadecredito, 0);
   end loop;
   return;

EXCEPTION WHEN OTHERS THEN
   rollback;
   n_pkg_vitalpos_log_general.write(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM);
   RETURN;
end ControlarNotasDebito;

/***************************************************************************************************
* procedure ControlarFormatoCuit
* Controla si un cliente de dio de alta con cuit con formato incorrecto
*
* %v 31/08/2016 - JBodnar
***************************************************************************************************/
procedure ControlarFormatoCuit
IS
   v_modulo               varchar2(100) := 'PKG_CONTROL.ControlarFormatoCuit';
BEGIN
   for v_RegTmp in (select cdcuit, cdmainsucursal
                    from entidades where cdcuit not like '__-________-_ %'
                    and dtalta > trunc(sysdate)- 90)
   loop
        GrabarMensaje(sys_guid(), v_RegTmp.cdmainsucursal, sysdate, 'Cuit con Formato Incorrecto',' Cuit: '||v_RegTmp.cdcuit, 0);
   end loop;
   return;

EXCEPTION WHEN OTHERS THEN
   rollback;
   n_pkg_vitalpos_log_general.write(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM);
   RETURN;
end ControlarFormatoCuit;

/***************************************************************************************************
* procedure ControlarImpuestos
* Controla que las FC / ND tengan impuestos positivos y las NC tengan impuestos negativos
*
* %v 08/09/2016 - JBodnar
* %v 12/09/2016 - APW - mejora consulta
***************************************************************************************************/
procedure ControlarImpuestos
IS
   v_modulo               varchar2(100) := 'PKG_CONTROL.ControlarImpuestos';
BEGIN
   --Buscar impuestos de FC o ND
   for v_RegFcNd in (--Controlar signos de facturas o debitos
                    select distinct id.idmovmateriales, d.cdsucursal
                    from documentos d, tblimpdocumento id
                    where d.idmovmateriales = id.idmovmateriales
                    and d.dtdocumento between g_dtDesde and g_dtHasta
                    and (d.cdcomprobante like 'FC%' or d.cdcomprobante like 'FC%')
                    and id.amimpuesto < 0 )
   loop
        GrabarMensaje(sys_guid(), v_RegFcNd.Cdsucursal, sysdate, 'FC - ND con impuesto negativo',' IdMovmateriales: '||v_RegFcNd.idmovmateriales, 0);
   end loop;
   
   --Buscar impuestos de NC
   for v_RegNc in (--Controlar signos de creditos
                    select distinct id.idmovmateriales, d.cdsucursal
                    from documentos d, tblimpdocumento id
                    where d.idmovmateriales = id.idmovmateriales
                    and d.dtdocumento between g_dtDesde and g_dtHasta
                    and d.cdcomprobante like 'NC%' 
                    and id.amimpuesto > 0 )
   loop
        GrabarMensaje(sys_guid(), v_RegNc.Cdsucursal, sysdate, 'NC con impuesto positivo',' IdMovmateriales: '||v_RegNc.idmovmateriales, 0);
   end loop;
      
   return;

EXCEPTION WHEN OTHERS THEN
   rollback;
   n_pkg_vitalpos_log_general.write(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM);
   RETURN;
end ControlarImpuestos;

/***************************************************************************************************
* procedure ControlarPedidoRaro
* Controla pedidos que está trabados por créditos pero que por algún error de datos no se ven en la pantalla para liberarlos
* %v 02/06/2017 - APW 
***************************************************************************************************/
procedure ControlarPedidoRaro
IS
   v_modulo               varchar2(100) := 'PKG_CONTROL.ControlarPedidoRaro';
BEGIN
   -- Busca pedidos en cualquier estado que indique problema de créditos
   for v_RegP in (
                SELECT distinct pi1.cdcuit, pi1.cdsucursal
                from pedidos pe1, tx_pedidos_insert pi1
                where pe1.iddoctrx = pi1.iddoctrx
                and pe1.icestadosistema in (11,12,13,14)
                and not exists ( -- los que se ven en la pantalla para destrabar
                select 1 
                   FROM pedidos                   pe,
                        documentos                do,
                        tx_pedidos_insert         pi,
                        direccionesentidades      de,
                        localidades               lo,
                        entidades                 en,
                        estadocomprobantes        ec,
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
                    AND en.cdestadooperativo ='A' --Activo
                    and su.cdsucursal = pi.cdsucursal
                    AND pe.icestadosistema in (11,12,13,14) 
                    and pe.idpedido = pe1.idpedido)
                    )
   loop
        GrabarMensaje(sys_guid(), v_RegP.Cdsucursal, sysdate, 'Pedido RARO',' cuit: '||v_RegP.cdcuit, 0);
   end loop;
      
   return;

EXCEPTION WHEN OTHERS THEN
   rollback;
   n_pkg_vitalpos_log_general.write(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM);
   RETURN;
end ControlarPedidoRaro;

/***************************************************************************************************
* procedure ControlarChoqueDescuentoPromo
* Controla superposiciones en la definición de articulos de una promo y de un descuento de frescos
* %v 23/08/2017 - APW
***************************************************************************************************/
procedure ControlarChoqueDescuentoPromo
IS
   v_modulo               varchar2(100) := 'PKG_CONTROL.ControlarChoqueDescuentoPromo';
BEGIN
   -- Controla que el artículo con descuento no tenga acción (descuento) de promo
   for v_RegP in (
      select p.cdpromo, xv.cdbarradescuento, s.cdsucursal
      from tblpromo p, tblpromo_sucursal s, tblpromo_accion c, tblpromo_accion_articulo ca,
      tbldescuentoarticuloxvencer xv
      where p.id_promo = s.id_promo
      and s.cdsucursal = xv.cdsucursal
      and p.id_promo = c.id_promo
      and c.id_promo_accion = ca.id_promo_accion
      and ca.cdarticulo =  xv.cdarticulo
      and xv.icactivo = 1
      and p.id_promo_estado = 1 
      and trunc(sysdate) between p.vigencia_desde and p.vigencia_hasta
      and ((xv.dtdesde between p.vigencia_desde and p.vigencia_hasta
           or xv.dthasta between p.vigencia_desde and p.vigencia_hasta)
           or
           (p.vigencia_desde between xv.dtdesde and xv.dthasta
           or p.vigencia_hasta between xv.dtdesde and xv.dthasta
           )
           )
      and p.cdpromo not in (106839, 107667) -- voucher de bienvenida
      and p.id_promo_tipo <> 14
   )
   loop
        GrabarMensaje(sys_guid(), v_RegP.Cdsucursal, sysdate, 'Descuento con PROMO',' cdpromo: '||v_RegP.cdpromo||' descuento: '||v_RegP.Cdbarradescuento, 0);
   end loop;
      
   return;

EXCEPTION WHEN OTHERS THEN
   rollback;
   n_pkg_vitalpos_log_general.write(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM);
   RETURN;
end ControlarChoqueDescuentoPromo;

/***************************************************************************************************
* procedure ControlarIvaCero
* Controla si no se cobra el iva en algun articulo producto de error en la impresora fiscal
* Si esto ocurre hay que seguir los siguientes pasos:
--Se modifica la TBLIMPDOCUMENTO (amimpuesto que esta en 0)
--Se reprocesa Interfaz Cobranza (pkg_sap.generarinterfaz) para ese dia
--Se vuelve a tirar la query de interfaz y no tiene que dar nada en la cuenta puente 
--Se envia correo a contabilidad
--Se reprocesa subdiario para esa sucursal para ese dia.
* %v 05/07/2017 - JB 
***************************************************************************************************/
procedure ControlarIvaCero
IS
   v_modulo               varchar2(100) := 'PKG_CONTROL.ControlarIvaCero';
BEGIN
   -- Busca pedidos en cualquier estado que indique problema de créditos
   for v_RegIva in (
                    select distinct d.cdsucursal, d.idmovmateriales, round(((ti.vltasa/100) * ti.ambaseimponible),2) dif
                    from documentos d, tblimpdocumento ti
                    where d.dtdocumento between g_dtDesde and g_dtHasta
                    and (d.cdcomprobante like 'NC%' or d.cdcomprobante like 'ND%' or d.cdcomprobante like 'FC%' )
                    and d.idmovmateriales = ti.idmovmateriales
                    and ti.cdimpuesto = 'IVA_VTA'
                    and ti.vltasa = '10,5'
                    and ti.amimpuesto = 0
                    and ti.ambaseimponible <> 0
                    )
   loop
        GrabarMensaje(sys_guid(), v_RegIva.Cdsucursal, sysdate, 'IVA 10.5 en cero',' idmovmateriales: '||v_RegIva.idmovmateriales||' - '||'Diferencia: '||v_RegIva.Dif, 0);
   end loop;
      
   return;

EXCEPTION WHEN OTHERS THEN
   rollback;
   n_pkg_vitalpos_log_general.write(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM);
   RETURN;
end ControlarIvaCero;

/***************************************************************************************************
* procedure ControlarFormatoCuit
* Controla si un cliente de dio de alta con cuit con formato incorrecto
*
* %v 31/08/2016 - JBodnar
***************************************************************************************************/
procedure ControlarFaltaCAEA
IS
   v_modulo               varchar2(100) := 'PKG_CONTROL.ControlarFaltaCAEA';
   v_caea                 tblcodigocaea.vlcodigocaea%type;
   v_ultimo               date;
   
BEGIN
   begin
   select cc.vlcodigocaea
   into v_caea
   from tblcodigocaea cc
   where trunc(sysdate)+4 between cc.dtvigenciadesde and cc.dtvigenciahasta;
   exception when others then
           select max(cc.dtvigenciahasta)
           into v_ultimo
           from tblcodigocaea cc;
           GrabarMensaje(sys_guid(), 'AC', sysdate, 'SIN CAEA PROXIMA QUINCENA','Vence: '||to_char(v_ultimo, 'dd/mm/yyyy'), 0);
   end;
   return;

EXCEPTION WHEN OTHERS THEN
   rollback;
   n_pkg_vitalpos_log_general.write(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM);
   RETURN;
end ControlarFaltaCAEA;

/***************************************************************************************************
* procedure ControlarNC
* Ejecutar los controles para hoy
*
* %v 16/09/2015 - MarianoL
* %v 07/10/2015 - JBodnar: Nuevo control que muesta pedidos con monto cero
* %v 08/09/2016 - JBodnar: Nuevos controles ControlarFormatoCuit / ControlarImpuestos
***************************************************************************************************/
procedure Controlar
IS
   v_modulo               varchar2(100) := 'PKG_CONTROL.Controlar';

   v_vlRetardo            integer := 30;  --En minutos. Controla desde el inicio del día hasta sysdate-v_vlRetardo

BEGIN

   g_dtDesde := trunc(sysdate);    --inicio del día
   g_dtHasta := sysdate - v_vlRetardo/1440; --sysdate - x minutos

   ControlarFacturas;
   ControlarNC;
   ControlarIngresos;
   ControlarEgresos;
   ControlarCobranzas;
   ControlarDeudores;
   ControlarCF;
   ControlarPagares;
   ControlarMontoPedidos;
   ControlarCierreLote;
   ControlarAliviosDuplicados;
   ControlarJobsDemorados;
   --ControlarNotasDebito;
   ControlarFormatoCuit;
   ControlarImpuestos;
   ControlarSqcomprobante;
   ControlarPedidoRaro;
   ControlarChoqueDescuentoPromo;
   ControlarFaltaCAEA;

   commit;

   PKG_PROCESOAUTOMATICO_CENTRAL.GrabarControlProceso('CONTROL','Controles', 1, NULL);  --Ojo que hace commit adentro!!!

   return;

EXCEPTION WHEN OTHERS THEN
   rollback;
   n_pkg_vitalpos_log_general.write(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM);
   PKG_PROCESOAUTOMATICO_CENTRAL.GrabarControlProceso('CONTROL','Controles', 0, '  Error: ' || SQLERRM);  --Ojo que hace commit adentro!!!
   RETURN;
end Controlar;

/************************************************************************************************************
  * Informar a ventas sobre las promociones con UxB -1 y -2 en UxB por ser promociones que no suben a VTEX, 
  * multiple UxB o exceso de SKUs más de 100.  solo para control matutino 
  * %v 14/04/2021 ChM: v1.0
  ************************************************************************************************************/
PROCEDURE ControlarVTEXpromoPOS ( p_result   OUT integer,
                             	    p_mensaje  OUT varchar2)
IS
   v_modulo               varchar2(100) := 'PKG_CONTROL.ControlarVTEXpromoPOS';
   v_fecha                date := trunc(sysdate);
   v_mensaje              varchar2(4000);
BEGIN
    select LISTAGG(A.cdpromo, ', ') WITHIN GROUP (ORDER BY A.cdpromo) promos 
      into v_mensaje
      from (select distinct 
                   vp.cdpromo                   
              from vtexpromotion vp 
                   --solo promos con error multiple UxB
             where vp.uxb=-1
                   --solo promos vigentes
               and v_fecha between vp.begindateutc and vp.enddateutc
               --si tiene una marca distinta de null no muesta más el error en el control
               and vp.icrevisadopos is null
           ) A ;   
     
    p_mensaje:='Multiple UxB: '||v_mensaje;  
    select LISTAGG(A.cdpromo, ', ') WITHIN GROUP (ORDER BY A.cdpromo) promos 
      into v_mensaje
      from (select distinct 
                   vp.cdpromo                   
              from vtexpromotion vp 
                   --solo promos con error Más de 100 SKU
             where vp.uxb=-2
                   --solo promos vigentes
               and v_fecha between vp.begindateutc and vp.enddateutc
                   --si tiene una marca distinta de null no muesta más el error en el control
               and vp.icrevisadopos is null
           ) A;    
   p_mensaje:=p_mensaje||'Más de 100 SKU: '||v_mensaje;
   p_result:=1;
EXCEPTION 
  WHEN OTHERS THEN
     p_mensaje:=null;
     p_result:=null;
   n_pkg_vitalpos_log_general.write(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM);
END ControlarVTEXpromoPOS;

 /************************************************************************************************************
  * Informar sobre las promociones no cargadas o en error en VTEX por sucursal que recibe 
  * %v 14/04/2021 ChM: v1.0
  * %v 12/05/2020 ChM ajusto tipo de error general desde 0 en adelante
  ************************************************************************************************************/
PROCEDURE ControlarVTEXpromo ( p_cdsucursal IN sucursales.cdsucursal%type,
                               p_tipoerror  IN integer default 1, --1 indica filtrar con error en API, 0 no subidas
                               p_result     OUT integer)
IS
   v_modulo               varchar2(100) := 'PKG_CONTROL.ControlarVTEXpromo';
   v_fecha                date := trunc(sysdate);   
    v_cdsucursal          sucursales.cdsucursal%type;
   
BEGIN
  --verifica si la sucursal esta activa en vtex
  begin
    select distinct
           vs.cdsucursal 
      into v_cdsucursal     
      from vtexsellers vs 
     where vs.icactivo = 1
       --diferente de sucursal central de VTEX
       and vs.cdsucursal <> '9999    '
       and vs.cdsucursal = p_cdsucursal;
 exception
   when no_data_found then
     --valor negativo indica no es sucursal activa en VTEX no control
     p_result:=-1;
     return;       
 end;
    p_result:=0;
      select count(*) 
        into p_result               
        from vtexpromotion vp, 
             vtexsellers   vs     
           --solo promos vigentes         
       where v_fecha between vp.begindateutc and vp.enddateutc        
         and vs.icactivo = 1 --solo sucursales activas
         and vp.cdsucursal = vs.cdsucursal
         and vp.cdsucursal = p_cdsucursal
         and (vp.icprocesado = 0 or vp.icprocesado>1)
         /*and case 
               when p_tipoerror=0 and vp.icprocesado = 0 then 1--lista solo promociones por procesar
               when p_tipoerror=1 and vp.icprocesado > 1 then 1--solo promos con error de carga en VTEX
                 else
                   0
             end = 1 */     
         --   valida incluir solo promos con SKUs
         and vp.id_promo_pos  in ( select distinct id_promo_pos from Vtexpromotionsku vps)
          -- verifica no incluir promos con multiproducto de diferentes UxB o con más de 100 SKUS
         and vp.uxb>=0;
         
EXCEPTION 
  WHEN OTHERS THEN   
     p_result:=null;
   n_pkg_vitalpos_log_general.write(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM);
END ControlarVTEXpromo;

 /************************************************************************************************************
  * Informar sobre los stock no cargados o en error en VTEX por sucursal que recibe 
  * %v 15/04/2021 ChM: v1.0
  * %v 12/05/2020 ChM ajusto tipo de error general desde 0 en adelante
  ************************************************************************************************************/
PROCEDURE ControlarVTEXstock ( p_cdsucursal IN sucursales.cdsucursal%type,
                               p_tipoerror  IN integer default 1, --1 indica filtrar con error en API, 0 no subidas
                               p_result     OUT integer)
IS
   v_modulo              varchar2(100) := 'PKG_CONTROL.ControlarVTEXstock';   
   v_cdsucursal          sucursales.cdsucursal%type;
   
BEGIN
  --verifica si la sucursal esta activa en vtex
  begin
    select distinct
           vs.cdsucursal 
      into v_cdsucursal     
      from vtexsellers vs 
     where vs.icactivo = 1
       --diferente de sucursal central de VTEX
       and vs.cdsucursal <> '9999    '
       and vs.cdsucursal = p_cdsucursal;
 exception
   when no_data_found then
     --valor negativo indica no es sucursal activa en VTEX no control
     p_result:=-1;
     return;       
 end;
     p_result:=0;
     select count(*)
       into p_result
       from vtexstock   vst,
            vtexproduct vp
      where vst.cdsucursal = p_cdsucursal
        and vst.cdarticulo = vp.refid
        --solo productos procesados y activos en VTEX
        and vp.icprocesado = 1         
        and vp.dtprocesado is not null
        and vp.isactive = 1  
        and (vst.icprocesado = 0 or vst.icprocesado>1)         
        /*and case 
               when p_tipoerror=0 and vst.icprocesado = 0 then 1--lista solo  por procesar
               when p_tipoerror=1 and vst.icprocesado > 1 then 1--solo con error de carga en VTEX
                 else
                   0
            end = 1*/;
         
EXCEPTION 
  WHEN OTHERS THEN   
     p_result:=null;
   n_pkg_vitalpos_log_general.write(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM);
END ControlarVTEXstock;

 /************************************************************************************************************
  * Informar sobre los precios no cargados o en error en VTEX por sucursal que recibe 
  * %v 15/04/2021 ChM: v1.0
  * %v 12/05/2020 ChM ajusto tipo de error general desde 0 en adelante  
  ************************************************************************************************************/
PROCEDURE ControlarVTEXPrice ( p_cdsucursal IN sucursales.cdsucursal%type,
                               p_tipoerror  IN integer default 1, --1 indica filtrar con error en API, 0 no subidas
                               p_result     OUT integer)
IS
   v_modulo              varchar2(100) := 'PKG_CONTROL.ControlarVTEXPrice';   
   v_cdsucursal          sucursales.cdsucursal%type;
   
BEGIN
  --verifica si la sucursal esta activa en vtex
  begin
    select distinct
           vs.cdsucursal 
      into v_cdsucursal     
      from vtexsellers vs 
     where vs.icactivo = 1
       --diferente de sucursal central de VTEX
       and vs.cdsucursal <> '9999    '
       and vs.cdsucursal = p_cdsucursal;
 exception
   when no_data_found then
     --valor negativo indica no es sucursal activa en VTEX no control
     p_result:=-1;
     return;       
 end;
    p_result:=0;
    select count(*)
      into p_result         
      FROM vtexprice   vpr,            
           vtexproduct  vp
     WHERE vpr.cdsucursal = p_cdsucursal       
       and vp.refid = vpr.refid        
       --solo productos procesados 
       and vp.icprocesado = 1  
        and (vpr.icprocesado = 0 or vpr.icprocesado>1)     
       /*and case 
             when p_tipoerror=0 and vpr.icprocesado = 0 then 1--lista solo por procesar
             when p_tipoerror=1 and vpr.icprocesado > 1 then 1--solo con error de carga en VTEX
               else
                 0
           end = 1*/;         
EXCEPTION 
  WHEN OTHERS THEN   
     p_result:=null;
   n_pkg_vitalpos_log_general.write(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM);
END ControlarVTEXPrice;
 /************************************************************************************************************
  * Informar sobre las ofertas que suben por csv no cargados o en error en VTEX por sucursal que recibe 
  * %v 15/04/2021 ChM: v1.0
  * %v 12/05/2020 ChM ajusto tipo de error general desde 0 en adelante  
  ************************************************************************************************************/
PROCEDURE ControlarVTEXOffer ( p_cdsucursal IN sucursales.cdsucursal%type,
                               p_tipoerror  IN integer default 1, 
                               p_result     OUT integer)
IS
   v_modulo              varchar2(100) := 'PKG_CONTROL.ControlarVTEXOffer';   
   v_cdsucursal          sucursales.cdsucursal%type;
   
BEGIN
  p_result:=p_tipoerror;
  --verifica si la sucursal esta activa en vtex
  begin
    select distinct
           vs.cdsucursal 
      into v_cdsucursal     
      from vtexsellers vs 
     where vs.icactivo = 1
       --diferente de sucursal central de VTEX
       and vs.cdsucursal <> '9999    '
       and vs.cdsucursal = p_cdsucursal;
 exception
   when no_data_found then
     --valor negativo indica no es sucursal activa en VTEX no control
     p_result:=-1;
     return;       
 end;
    p_result:=0;
    select count(*)
      into p_result     
      from vtexsellers vs 
     where vs.cdsucursal = p_cdsucursal
       and vs.iccsv = 0;         
EXCEPTION 
  WHEN OTHERS THEN   
     p_result:=null;
   n_pkg_vitalpos_log_general.write(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM);
END ControlarVTEXOffer;

 /************************************************************************************************************
  * Informar sobre los productos no cargados o en error en VTEX 
  * %v 15/04/2021 ChM: v1.0
  ************************************************************************************************************/
PROCEDURE ControlarVTEXproduct ( p_tipoerror  IN integer default 1, -- 1 indica filtrar con error en API, 0 no subidos
                                 p_result     OUT integer)
IS
   v_modulo               varchar2(100) := 'PKG_CONTROL.ControlarVTEXproduct';
     
BEGIN
    p_result:=0;
    select count(*)
      into p_result 
      from vtexproduct vp
     where case 
             when p_tipoerror=0 and vp.icprocesado = 0 then 1--lista solo por procesar
             when p_tipoerror=1 and vp.icprocesado > 1 then 1--solo con error de carga en VTEX
               else
                 0
           end = 1; 
EXCEPTION 
  WHEN OTHERS THEN   
     p_result:=null;
   n_pkg_vitalpos_log_general.write(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM);
END ControlarVTEXproduct;


 /************************************************************************************************************
  * Informar sobre las marcas en error en VTEX con respecto al listado de POS
  * %v 01/07/2021 ChM: v1.0
  ************************************************************************************************************/
PROCEDURE ControlarVTEXBrand ( p_tipoerror  IN integer default 1, -- 1 indica filtrar con error en API, 0 no subidos
                                p_result     OUT integer)
IS
   v_modulo               varchar2(100) := 'PKG_CONTROL.ControlarVTEXOrders';
     
BEGIN  
    p_result:=0;
   select count(*)
          into p_result
          from (select 
              distinct t.vlmarca 
                  from TBLARTICULONOMBREECOMMERCE t 
                 where upper(trim(t.vlmarca)) not in (select b.name from vtexbrand b )); 
EXCEPTION 
  WHEN OTHERS THEN   
     p_result:=null;
   n_pkg_vitalpos_log_general.write(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM);
END ControlarVTEXBrand;

 /************************************************************************************************************
  * Informar sobre las colecciones no cargadas o en error en VTEX 
  * %v 15/04/2021 ChM: v1.0
  * %v 26/08/2021 ChM - verifico si las colecciones subieron hoy 
  ************************************************************************************************************/
PROCEDURE ControlarVTEXCollection ( p_tipoerror  IN integer default 1, -- 1 indica filtrar con error en API, 0 no subidos
                                    p_result     OUT integer)
IS
   v_modulo               varchar2(100) := 'PKG_CONTROL.ControlarVTEXCollection';
     
BEGIN
    p_result:=0;
    -- verifico si las colecciones subieron hoy      
       select count(*)
         into p_result 
         from vtexcollectionsku vc
        where trunc(vc.dtprocesado)<>trunc(sysdate);
       if p_result <> 0 then
         return;
        end if;     
  --Alerta de colecciones vacías en VTEX  
    for coll in( 
    select vc.collectionid,
           (select count(*)      
              from vtexcollectionsku vcs 
             where vcs.collectionid=vc.collectionid) cant
     from vtexcollection vc )  
    loop
      if coll.cant=0 then
         p_result:=-1; --valor negativo indica existen colecciones vacias
         return;
      end if;
      end loop;   
    
    p_result:=0;
    select count(*)
      into p_result 
      from vtexcollectionsku vc
     where case 
             when p_tipoerror=0 and vc.icprocesado = 0 then 1--lista solo por procesar
             when p_tipoerror=1 and vc.icprocesado > 1 then 1--solo con error de carga en VTEX
               else
                 0
           end = 1; 
    
EXCEPTION 
  WHEN OTHERS THEN   
     p_result:=null;
   n_pkg_vitalpos_log_general.write(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM);
END ControlarVTEXCollection;

 /************************************************************************************************************
  * Informar sobre las direcciones no cargadas o en error en VTEX 
  * %v 15/04/2021 ChM: v1.0
  ************************************************************************************************************/
PROCEDURE ControlarVTEXAdress  ( p_tipoerror  IN integer default 1, -- 1 indica filtrar con error en API, 0 no subidos
                                 p_result     OUT integer)
IS
   v_modulo               varchar2(100) := 'PKG_CONTROL.ControlarVTEXAdress';
     
BEGIN 
    p_result:=0;
    select count(*)
      into p_result 
      from vtexaddress  va
     where 
       --solo direcciones que ya tienen clientsid_vtex
           va.clientsid_vtex <> '1'      
       and case 
             when p_tipoerror=0 and va.icprocesado = 0 then 1--lista solo por procesar
             when p_tipoerror=1 and va.icprocesado > 1 then 1--solo con error de carga en VTEX
               else
                 0
           end = 1
        --si tiene una marca distinta de null no muesta más el error en el control
        and va.icrevisadopos is null
        --no envio direcciones anuladas nunca creadas en VTEX
             and case
                 	when va.icactive = 0 and va.iddireccion_vtex is null then 0
                    else 1
                 end = 1; 
EXCEPTION 
  WHEN OTHERS THEN   
     p_result:=null;
   n_pkg_vitalpos_log_general.write(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM);
END ControlarVTEXAdress;

 /************************************************************************************************************
  * Informar sobre los pedidos no cargados o en error en VTEX 
  * %v 16/04/2021 ChM: v1.0
  ************************************************************************************************************/
PROCEDURE ControlarVTEXOrders ( p_tipoerror  IN integer default 1, -- 1 indica filtrar con error en API, 0 no subidos
                                p_result     OUT integer)
IS
   v_modulo               varchar2(100) := 'PKG_CONTROL.ControlarVTEXOrders';
     
BEGIN  
    p_result:=0;
   select count(*)
          into p_result
          from vtexorders vo        
    where case 
             when p_tipoerror=0 and vo.icprocesado = 0 then 1--lista solo por procesar
             when p_tipoerror=1 and vo.icprocesado > 1 then 1--solo con error de carga en VTEX
               else
                 0
          end = 1
       --si tiene una marca distinta de null no muesta más el error en el control
       and vo.icrevisadopos is null; 
EXCEPTION 
  WHEN OTHERS THEN   
     p_result:=null;
   n_pkg_vitalpos_log_general.write(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM);
END ControlarVTEXOrders;
  /************************************************************************************************************
  * Informar sobre los clientes no cargados o en error en VTEX por sucursal que recibe 
  * %v 15/04/2021 ChM: v1.0
  ************************************************************************************************************/
PROCEDURE ControlarVTEXClients ( p_tipoerror  IN integer default 1, -- 1 indica filtrar con error en API, 0 no subidos
                                 p_result     OUT integer)
IS
   v_modulo              varchar2(100) := 'PKG_CONTROL.ControlarVTEXClients';      
BEGIN
  --Alerta de clientes sin direcciones VTEX
    for clients in
      ( 
        select vc.id_cuenta, 
               (select count(*)
                  from vtexaddress  va
                 where va.id_cuenta=vc.id_cuenta
                   and va.clientsid_vtex=vc.clientsid_vtex
                   --solo direcciones activas
                   and va.icactive = 1) cant
          from vtexclients vc
         --si tiene una marca distinta de null no muestra más el error en el control
         where vc.icrevisadopos is null
          --solo clientes con cuenta asociada a vtex
           and vc.id_cuenta <>'1'
        )  
    loop
      if clients.cant=0 then
         p_result:=-1; --valor negativo indica existen clientes sin direcciones
         return;
      end if;
      end loop;   
  p_result:=0;
    select count(*)
      into p_result 
      from vtexclients vc
     where case 
             when p_tipoerror=0 and vc.icprocesado = 0 then 1--lista solo por procesar
             when p_tipoerror=1 and vc.icprocesado > 1 then 1--solo con error de carga en VTEX
               else
                 0
           end = 1
        --si tiene una marca distinta de null no muesta más el error en el control
        and vC.icrevisadopos is null;          
EXCEPTION 
  WHEN OTHERS THEN   
     p_result:=null;
   n_pkg_vitalpos_log_general.write(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM);
END ControlarVTEXClients;


  /************************************************************************************************************
  * Informar diferencias de precios entre AC y la tabla que alimenta VentaMóvil
  * %v 14/5/2021 - APW (sobre consulta de IAquilano!)
  ************************************************************************************************************/
  PROCEDURE ControlarPreciosExtranet(p_result    OUT integer) IS

    v_modulo varchar2(100) := 'PKG_CONTROL.ControlarPreciosExtranet';
    
  BEGIN
    p_result := 0; -- ok
    select count(*)
      into p_result -- si encuentra algo es error
      from (select distinct s.cdarticulo,
                            s.cdsucursal,
                            s.amprecioinfafactor,
                            s.ampreciosupafactor,
                            s.amprecioinfafactorciva,
                            s.ampreciosupafactorciva,
                            s.amprecioresultante,
                            s.amprecioresultanteciva,
                            tp.precioinferiorafactor,
                            tp.preciosuperiorafactor,
                            tp.precioinferiorafactorciva,
                            tp.preciosuperiorafactorciva,
                            tp.amprecioresultantesiva precioresultantesininva,
                            tp.amprecioresultanteciva precioresultanteconiva,
                            (s.amprecioinfafactor - tp.precioinferiorafactor) dif1,
                            (s.ampreciosupafactor - tp.preciosuperiorafactor) dif2,
                            (s.amprecioinfafactorciva -
                            tp.precioinferiorafactorciva) dif3,
                            (s.ampreciosupafactorciva -
                            tp.preciosuperiorafactorciva) dif4
              from preciosgw_s s, tbllista_precio_central tp
             where trim(tp.cdarticulo) = trim(s.cdarticulo)
               and trim(tp.cdsucursal) = trim(s.cdsucursal)
               and tp.id_canal = 'VE'
             order by 1, 2) t
     where t.dif1 <> 0
        or t.dif2 <> 0
        or t.dif3 <> 0
        or t.dif4 <> 0;
 
  EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,'Modulo: ' || v_modulo || '  Error: ' ||SQLERRM);
  END ControlarPreciosExtranet;

  /************************************************************************************************************
  * Informa al momento del control, si pasaron todas las replicas correspondientes a todas las tablas que 
  * utiliza CAR para procesar la contabilidad.
  * %v 24/08/2021 - IAquilano
  ************************************************************************************************************/

  Procedure Control_Replicas_CAR(p_cdsucursal IN sucursales.cdsucursal%TYPE,
                                 p_fecha      IN date,
                                 P_Result     OUT varchar2) is
                                 
    v_modulo   varchar2(100) := 'PKG_CONTROL.Control_Replicas_CAR';
    v_query    VARCHAR2(5000);
    v_sucursal sucursales.servidor%type;

  Begin
    
 select s.servidor
 into v_sucursal
 from sucursales s
 where s.cdsucursal = p_cdsucursal;

    v_query := ('select decode(nvl(sum(cant), ''0''), 0, ''OK'', ''NO OK'')
  from (select count(*) as cant
          from detallemovmateriales@'|| v_sucursal ||' dd,
               documentos@'|| v_sucursal ||' d
         where d.idmovmateriales = dd.idmovmateriales
           and d.dtdocumento BETWEEN  to_date(''' || p_fecha || ''',''dd/mm/yyyy'') ' || 'AND to_date(''' || p_fecha || ''',''dd/mm/yyyy'') + 1 ' || '
           and not exists
         (select 1
                  from detallemovmateriales dd1
                 where dd1.idmovmateriales = dd.idmovmateriales)
        union all
        select count(*) as cant
          from movmateriales@'|| v_sucursal ||' dd, documentos@'|| v_sucursal ||' d
         where d.idmovmateriales = dd.idmovmateriales
           and d.dtdocumento BETWEEN  to_date(''' || p_fecha || ''',''dd/mm/yyyy'') ' || 'AND to_date(''' || p_fecha || ''',''dd/mm/yyyy'') + 1 ' || '
           and not exists
         (select 1
                  from movmateriales mm1
                 where mm1.idmovmateriales = dd.idmovmateriales)
        union all
        select count(*) as cant
          from documentos@'|| v_sucursal ||' d
         where d.dtdocumento BETWEEN  to_date(''' || p_fecha || ''',''dd/mm/yyyy'') ' || 'AND to_date(''' || p_fecha || ''',''dd/mm/yyyy'') + 1 ' || '
           and not exists
         (select 1 from documentos dd1 where dd1.iddoctrx = d.iddoctrx)
        union all
        select count(*) as cant
          from tblimpdocumentodetalle@'|| v_sucursal ||' ti
         where idmovmateriales in
               (select idmovmateriales
                  from documentos@'|| v_sucursal ||'
                 where dtdocumento between  to_date(''' || p_fecha || ''',''dd/mm/yyyy'') ' || 'AND to_date(''' || p_fecha || ''',''dd/mm/yyyy'') + 1 ' || ')
           and not exists
         (select 1
                  from tblimpdocumentodetalle ti1
                 where ti1.idimpdocumentodetalle = ti.idimpdocumentodetalle)
        union all
        select count(*) as cant
          from tblimpdocumento@'|| v_sucursal ||' tip
         where idmovmateriales in
               (select idmovmateriales
                  from documentos@'|| v_sucursal ||'
                 where dtdocumento BETWEEN  to_date(''' || p_fecha || ''',''dd/mm/yyyy'') ' || 'AND to_date(''' || p_fecha || ''',''dd/mm/yyyy'') + 1 ' || ')
           and not exists
         (select 1
                  from tblimpdocumento tip1
                 where tip1.idimpdocumento = tip.idimpdocumento)
        union all
        select count(*) as cant
          from tblcierrelotesalon@'|| v_sucursal ||' ts
         where ts.dtlote BETWEEN  to_date(''' || p_fecha || ''',''dd/mm/yyyy'') ' || 'AND to_date(''' || p_fecha || ''',''dd/mm/yyyy'') + 1 ' || '
           and not exists
         (select 1
                  from tblcierrelotesalon tss
                 where tss.idcierrelotesalon = ts.idcierrelotesalon)
        union all
        select count(*) as cant
          from tbltesoro@'|| v_sucursal ||' tt
         where dtoperacion BETWEEN  to_date(''' || p_fecha || ''',''dd/mm/yyyy'') ' || 'AND to_date(''' || p_fecha || ''',''dd/mm/yyyy'') + 1 ' || '
           and not exists
         (select 1 from tbltesoro tt1 where tt1.idtesoro = tt.idtesoro)
        union all
        select count(*) as cant
          from tblaliviodetalle@'|| v_sucursal ||' ta
         where dtestado BETWEEN  to_date(''' || p_fecha || ''',''dd/mm/yyyy'') ' || 'AND to_date(''' || p_fecha || ''',''dd/mm/yyyy'') + 1 ' || '
           and not exists
         (select 1
                  from tblaliviodetalle taa
                 where taa.idaliviodetalle = ta.idaliviodetalle)
        union all
        select count(*) as cant
          from tblmovcaja@'|| v_sucursal ||' tm
         where dtmovimiento BETWEEN  to_date(''' || p_fecha || ''',''dd/mm/yyyy'') ' || 'AND to_date(''' || p_fecha || ''',''dd/mm/yyyy'') + 1 ' || '
           and not exists (select 1
                  from tblmovcaja tmm
                 where tmm.idmovcaja = tm.idmovcaja)
        union all
        select count(*) as cant
          from tblingreso@'|| v_sucursal ||' ti
         where dtingreso BETWEEN  to_date(''' || p_fecha || ''',''dd/mm/yyyy'') ' || 'AND to_date(''' || p_fecha || ''',''dd/mm/yyyy'') + 1 ' || '
           and not exists (select 1
                  from tblingreso tii
                 where tii.idingreso = ti.idingreso)
        union all
        select count(*) as cant
          from tbltransaccion@'|| v_sucursal ||' tc
         where tc.dttransaccion between  to_date(''' || p_fecha || ''',''dd/mm/yyyy'') ' || 'AND to_date(''' || p_fecha || ''',''dd/mm/yyyy'') + 1 ' || '
           and not exists
         (select 1
                  from tbltransaccion tcc
                 where tcc.idtransaccion = tc.idtransaccion)
        union all
        select count(*) as cant
          from tblclsube@'|| v_sucursal ||' ts
         where dtlote BETWEEN  to_date(''' || p_fecha || ''',''dd/mm/yyyy'') ' || 'AND to_date(''' || p_fecha || ''',''dd/mm/yyyy'') + 1 ' || '
           and not exists
         (select 1 from tblclsube tss where tss.idclsube = ts.idclsube)
        union all
        select count(*) as cant
          from tblcierrelote@'|| v_sucursal ||' tcs
         where dtcierrelote BETWEEN  to_date(''' || p_fecha || ''',''dd/mm/yyyy'') ' || 'AND to_date(''' || p_fecha || ''',''dd/mm/yyyy'') + 1 ' || '
           and not exists
         (select 1
                  from tblcierrelote tcs1
                 where tcs1.idingreso = tcs.idingreso))');

    EXECUTE IMMEDIATE v_query
      into p_result;

  Exception
    when others then
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo || '  Error: ' ||
                                       SQLERRM);
    
  end Control_Replicas_CAR;


END;
/
