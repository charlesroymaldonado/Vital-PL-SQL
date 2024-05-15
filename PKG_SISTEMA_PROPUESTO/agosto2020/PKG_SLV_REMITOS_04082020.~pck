CREATE OR REPLACE PACKAGE PKG_SLV_REMITOS is
  /**********************************************************************************************************
  * Author  : CHARLES ROY MALDONADO DUARTE
  * Created : 13/02/2020 01:45:03 P.m.
  * %v Paquete para gestión y asignación de REMITOS SLV
  **********************************************************************************************************/
  -- Tipos de datos

  TYPE CURSOR_TYPE IS REF CURSOR;
  
  FUNCTION SetInsertarRemitoFaltante(p_idpedfaltanterel tblslvremito.idpedfaltanterel%type)
                                     RETURN INTEGER;
  PROCEDURE GetCarreta(p_IdPersona      IN   personas.idpersona%type,
                       p_IdTarea        IN   tblslvtarea.idtarea%type,
                       p_idRemito       OUT  tblslvremito.idremito%type,
                       p_NroCarreta     OUT  tblslvremito.nrocarreta%type);
                                
  PROCEDURE GetRemito(p_idRemito        IN  tblslvremito.idremito%type,
                      p_TipoTarea       IN  Tblslvtipotarea.cdtipo%type,
                      p_DsSucursal      OUT sucursales.dssucursal%type, 
                      p_Cursor          OUT CURSOR_TYPE);  
                      
  FUNCTION SetInsertarRemito(p_IdTarea               tblslvtarea.idtarea%type,
                             p_NroCarreta            tblslvremito.nrocarreta%type)
                             RETURN INTEGER;  
                             
  FUNCTION SetDetalleRemito(p_idRemito         tblslvremito.idremito%type,
                            p_idTarea          tblslvremito.idtarea%type,
                            p_cdArticulo       tblslvtareadet.cdarticulo%type,
                            p_cantidad         tblslvtareadet.qtunidadmedidabasepicking%type,
                            p_cdunidad         barras.cdunidad%type,
                            p_IdPedidoBolsin   pedidos.idpedido%type default null,
                            p_cantidad_pes     tblslvtareadet.qtunidadmedidabasepicking%type)
                            return integer; 
                            
  FUNCTION SetFinalizarRemito(p_idremito      tblslvremito.idremito%type)
                           RETURN INTEGER;  
                           
  PROCEDURE PanelRemito(p_DtDesde        IN DATE,
                        p_DtHasta        IN DATE,
                        p_idremito       IN tblslvremito.idremito%type default null,
                        p_NroCarreta     IN tblslvremito.nrocarreta%type default null,                        
                        p_Cursor         OUT CURSOR_TYPE);                                                                                                                                                                             

end PKG_SLV_REMITOS;
/
CREATE OR REPLACE PACKAGE BODY PKG_SLV_REMITOS is
/***************************************************************************************************
*  %v 13/02/2020  ChM - Parametros globales del PKG
****************************************************************************************************/
--c_qtDecimales                                  CONSTANT number := 2; -- cantidad de decimales para redondeo
   g_cdSucursal                      sucursales.cdsucursal%type := trim(getvlparametro('CDSucursal','General'));

  c_TareaConsolidadoPedido           CONSTANT tblslvtipotarea.cdtipo%type := 25;
  c_TareaConsolidaPedidoFaltante     CONSTANT tblslvtipotarea.cdtipo%type := 40;
  c_TareaFaltanteConsolFaltante      CONSTANT tblslvtipotarea.cdtipo%type := 44;
  c_TareaConsolidadoComi             CONSTANT tblslvtipotarea.cdtipo%type := 50;
  c_TareaConsolidadoComiFaltante     CONSTANT tblslvtipotarea.cdtipo%type := 60;
  --costante de tblslvestado
  C_EnCursoRemito                    CONSTANT tblslvestado.cdestado%type := 36;
  C_FinalizadoRemito                 CONSTANT tblslvestado.cdestado%type := 37;

 
  /****************************************************************************************************
  * %v 03/06/2020 - ChM  Versión inicial SetInsertarRemitoFaltante
  * %v 03/06/2020 - ChM  inserta remito de la distribución de faltante
  *****************************************************************************************************/
  FUNCTION SetInsertarRemitoFaltante(p_idpedfaltanterel tblslvremito.idpedfaltanterel%type)
    RETURN INTEGER IS
  
    v_modulo   varchar2(100) := 'PKG_SLV_REMITOS.SetInsertarRemitoFaltante';
    v_idremito tblslvremito.idremito%type;
    v_pedido   tblslvconsolidadopedido.idconsolidadopedido%type :=null;
  BEGIN
    --busca el idconsolidadopedido según idpedfantlaterel
    select fr.idconsolidadopedido
      into v_pedido
      from tblslvpedfaltanterel fr
     where fr.idpedfaltanterel = p_idpedfaltanterel
       and rownum=1;
    --inserto la cabecera del remito
    insert into tblslvremito
      (idremito,
       idtarea,
       idpedfaltanterel,
       nrocarreta,
       cdestado,
       dtremito,
       dtupdate,
       cdsucursal)
    values
      (seq_remito.nextval, --idremito
       null, --idtarea
       p_idpedfaltanterel, --idpedfaltanterel
       'DISTB-' || v_pedido, --NroCarreta
       C_FinalizadoRemito, --Cdestado
       sysdate, --dtremito
       null,
       g_cdSucursal); --dtupdate
    IF SQL%ROWCOUNT = 0 THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       ' imposible insertar remito del idpedfaltanterel: ' ||
                                       p_idpedfaltanterel);
      return 0; -- devuelve 0 si no inserta
    END IF;
    --inserto el detalle del remito
    select seq_remito.currval into v_idremito from dual;
    insert into tblslvremitodet
      (idremitodet,
       idremito,
       cdarticulo,
       qtunidadmedidabasepicking,
       qtpiezaspicking,
       dtinsert,
       dtupdate,
       cdsucursal)
      select seq_remitodet.nextval,
             v_idremito,
             df.cdarticulo,
             df.qtunidadmedidabase,
             df.qtpiezas,
             sysdate,
             null,
             g_cdSucursal
        from Tblslvdistribucionpedfaltante df
       where df.idpedfaltanterel = p_idpedfaltanterel
        --validacion necesario por ajuste en nueva distribucion de BTO
        --para no insertar en remito valores en 0
         and df.qtunidadmedidabase>0;
    IF SQL%ROWCOUNT = 0 THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       ' imposible insertar detalle del remito del idpedfaltanterel: ' ||
                                       p_idpedfaltanterel);
      return 0; -- devuelve 0 si no inserta
    END IF;
  
    return 1; -- devuelve 1 todo correcto!
  EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo || ' Error: ' ||
                                       SQLERRM);
      return 0;
  END SetInsertarRemitoFaltante;

 /****************************************************************************************************
  * %v 17/02/2020 - ChM  Versión inicial GetCarreta
  * %v 17/02/2020 - ChM  verifica si el pedido tiene carreta en curso para picking
  *****************************************************************************************************/

  PROCEDURE GetCarreta(p_IdPersona      IN   personas.idpersona%type,
                       p_IdTarea        IN   tblslvtarea.idtarea%type,
                       p_idRemito       OUT  tblslvremito.idremito%type,
                       p_NroCarreta     OUT  tblslvremito.nrocarreta%type) IS
  BEGIN
      p_idRemito:=0;
      p_NroCarreta:='_';
      select re.idremito,
             re.nrocarreta
        into p_idRemito,
             p_NroCarreta
        from tblslvremito re,
             tblslvtarea  ta
       where re.cdestado = C_EnCursoRemito --remito en curso
         and ta.idpersonaarmador = p_IdPersona --id armador
         and re.idtarea = ta.idtarea
         and re.idtarea = p_IdTarea
         and rownum = 1;
  EXCEPTION
  WHEN NO_DATA_FOUND THEN
    p_idRemito := 0;
    p_NroCarreta := '_';
  WHEN OTHERS THEN
    p_idRemito := 0;
    p_NroCarreta := '_';
  END GetCarreta;
  /****************************************************************************************************
  * %v 05/06/2020 - ChM  Versión inicial GetRemitoP
  * %v 05/06/2020 - ChM  muestra los remitos de consolidado pedido
  *****************************************************************************************************/
  PROCEDURE GetRemitoP(p_idRemito        IN  tblslvremito.idremito%type,
                       p_rel             IN  integer,                                                                      
                       p_Cursor          OUT CURSOR_TYPE) IS
                      
  v_modulo varchar2(100) := 'PKG_SLV_REMITOS.GetRemitoP';
  BEGIN
    --cursor para remito de pedidos
    if p_rel = 0 then      
    OPEN p_Cursor FOR
           select re.idremito,
                  re.dtremito,
                  ta.idtarea,
                  cp.idconsolidadom,
                  ta.idconsolidadopedido idconsolidado,
                  cp.dtinsert fechaconsolidado,       
                  pe.dtaplicacion fechapedido, 
                  TRIM(NVL (e.dsrazonsocial, e.dsnombrefantasia))||' ('||TRIM(e.cdcuit)||')' cliente,                             
                  de.dscalle||' '||
                  de.dsnumero||' CP ('||
                  trim(de.cdcodigopostal)||') '|| 
                  l.dslocalidad|| ' - '|| 
                  p.dsprovincia domicilio,
                  pers.dsnombre||' '||pers.dsapellido Armador,
                  re.nrocarreta rolls
             from tblslvremito                        re,
                  tblslvtarea                         ta,
                  personas                            pers,
                  pedidos                             pe,
                  entidades                           e,
                  tblslvconsolidadopedido             cp,
                  tblslvconsolidadopedidorel          pre,
                  direccionesentidades                de, 
                  localidades                         l,
                  provincias                          p
            where re.idtarea = ta.idtarea
              and ta.idpersonaarmador = pers.idpersona
              and cp.identidad=de.identidad
              and pe.sqdireccion=de.sqdireccion
              and pe.cdtipodireccion=de.cdtipodireccion
              and de.cdlocalidad=l.cdlocalidad
              and de.cdprovincia=p.cdprovincia 
              and cp.identidad = e.identidad   
              and cp.idconsolidadopedido = pre.idconsolidadopedido
              and pre.idpedido = pe.idpedido
              and cp.idconsolidadopedido = ta.idconsolidadopedido                       
              and re.idremito = p_idRemito; 
         else --remito de distribución faltante
           OPEN p_Cursor FOR
           select re.idremito,
                  re.dtremito,
                  0 idtarea,
                  cp.idconsolidadom,
                  cp.idconsolidadopedido idconsolidado,
                  cp.dtinsert fechaconsolidado,             
                  pe.dtaplicacion fechapedido, 
                  TRIM(NVL (e.dsrazonsocial, e.dsnombrefantasia))||' ('||TRIM(e.cdcuit)||')' cliente,                             
                  de.dscalle||' '||
                  de.dsnumero||' CP ('||
                  trim(de.cdcodigopostal)||') '|| 
                  l.dslocalidad|| ' - '|| 
                  p.dsprovincia domicilio,
                  'DISTRIBUCIÓN DE FALTANTE' Armador,
                  re.nrocarreta rolls                                          
             from tblslvpedfaltanterel       frel, 
                  tblslvconsolidadopedidorel pre,
                  tblslvconsolidadopedido    cp,
                  tblslvremito               re,
                  pedidos                    pe,
                  entidades                  e,   
                  direccionesentidades       de, 
                  localidades                l,
                  provincias                 p        
            where re.idpedfaltanterel = frel.idpedfaltanterel
              and frel.idconsolidadopedido = cp.idconsolidadopedido
              and cp.identidad = de.identidad
              and pe.sqdireccion = de.sqdireccion
              and pe.cdtipodireccion = de.cdtipodireccion
              and de.cdlocalidad = l.cdlocalidad
              and de.cdprovincia = p.cdprovincia 
              and cp.identidad = e.identidad
              and cp.idconsolidadopedido = pre.idconsolidadopedido   
              and pre.idpedido = pe.idpedido      
              and re.idremito = p_idRemito;        
           end if;                          
   EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       '  Error: ' || SQLERRM);
  END GetRemitoP;
 
 /****************************************************************************************************
  * %v 11/06/2020 - ChM  Versión inicial GetRemitoF
  * %v 11/06/2020 - ChM  muestra los remitos de faltante de pedidos
  *****************************************************************************************************/
  PROCEDURE GetRemitoF(p_idRemito        IN  tblslvremito.idremito%type,                                                                                                    
                       p_Cursor          OUT CURSOR_TYPE) IS
                      
  v_modulo varchar2(100) := 'PKG_SLV_REMITOS.GetRemitoF';
  BEGIN
    --cursor para remito de faltante de pedidos
     OPEN p_Cursor FOR
             select re.idremito,
                    re.dtremito,
                    ta.idtarea,
                    0 idconsolidadom,
                    pf.idpedfaltante idconsolidado,
                    pf.dtinsert fechaconsolidado,                   
                    sysdate fechapedido,
                    LISTAGG(cp.idconsolidadopedido||' - '||trim(NVL (e.dsrazonsocial, e.dsnombrefantasia)||' ('||TRIM(e.cdcuit)||')'), '§')
                    WITHIN GROUP (ORDER BY cp.idconsolidadopedido||' - '||Trim(NVL (e.dsrazonsocial, e.dsnombrefantasia))||' ('||TRIM(e.cdcuit)||')') cliente,                             
                    '-' domicilio,
                    pers.dsnombre||' '||pers.dsapellido Armador,
                    re.nrocarreta rolls
               from tblslvremito                        re,
                    tblslvtarea                         ta,
                    personas                            pers,
                    entidades                           e,               
                    tblslvconsolidadopedido             cp,
                    tblslvpedfaltanterel                pfrel,
                    tblslvpedfaltante                   pf
              where re.idtarea = ta.idtarea
                and ta.idpersonaarmador = pers.idpersona              
                and re.idremito = p_idRemito
                and ta.idpedfaltante = pf.idpedfaltante
                and pf.idpedfaltante = pfrel.idpedfaltante
                and pfrel.idconsolidadopedido = cp.idconsolidadopedido
                and cp.identidad = e.identidad                
           group by re.idremito,
                    re.dtremito,
                    ta.idtarea,
                    pf.idpedfaltante,
                    pf.dtinsert,
                    pers.dsnombre,
                    pers.dsapellido,
                    re.nrocarreta;
     
   EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       '  Error: ' || SQLERRM);
  END GetRemitoF;
 
 /****************************************************************************************************
  * %v 11/06/2020 - ChM  Versión inicial GetRemitoC
  * %v 11/06/2020 - ChM  muestra los remitos de tarea de comisionista
  *****************************************************************************************************/
  PROCEDURE GetRemitoC(p_idRemito        IN  tblslvremito.idremito%type,                                                                   
                       p_Cursor          OUT CURSOR_TYPE) IS
                      
  v_modulo varchar2(100) := 'PKG_SLV_REMITOS.GetRemitoC';
  BEGIN
    --cursor para remito de comisionistas
    OPEN p_Cursor FOR
             select re.idremito,
                    re.dtremito,
                    ta.idtarea,
                    cc.idconsolidadom idconsolidadom,
                    cc.idconsolidadocomi idconsolidado,
                    cc.dtinsert fechaconsolidado, 
                    sysdate fechapedido,
                    TRIM(NVL (e.dsrazonsocial, e.dsnombrefantasia))||' ('||TRIM(e.cdcuit)||')' cliente,
                    '-' domicilio,
                    pers.dsnombre||' '||pers.dsapellido Armador,
                    re.nrocarreta rolls
               from tblslvremito                        re,
                    tblslvtarea                         ta,
                    personas                            pers,
                    entidades                           e,         
                    tblslvconsolidadocomi               cc
              where re.idtarea = ta.idtarea
                and ta.idpersonaarmador = pers.idpersona      
                and ta.idconsolidadocomi = cc.idconsolidadocomi
                and cc.idcomisionista = e.identidad                
                and re.idremito = p_idRemito;
   EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       '  Error: ' || SQLERRM);
  END GetRemitoC;
 
  /****************************************************************************************************
  * %v 18/05/2020 - ChM  Versión inicial GetRemito
  * %v 18/05/2020 - ChM  detalle de remito para imprimir etiquetas
  * %v 05/06/2020 - ChM  ajusto para mostrar los remitos de distribución
  * %v 11/06/2020 - LM   ajusto para diferenciar remitos distrib faltantes vs de faltantes
  *****************************************************************************************************/
  PROCEDURE GetRemito(p_idRemito        IN  tblslvremito.idremito%type,
                      p_TipoTarea       IN  Tblslvtipotarea.cdtipo%type,
                      p_DsSucursal      OUT sucursales.dssucursal%type, 
                      p_Cursor          OUT CURSOR_TYPE) IS
                      
  v_modulo varchar2(100) := 'PKG_SLV_REMITOS.GetRemito';
  v_rel    tblslvremito.idpedfaltanterel%type:=0;
  BEGIN
    --descripcion de la sucursal
    begin
    select su.dssucursal
      into p_DsSucursal
      from sucursales su
     where su.cdsucursal = g_cdSucursal
       and rownum=1;
     exception
       when others then
         p_DsSucursal:='_';  
    end; 
    begin
        --verifico si es remito de distribución de faltantes
        select nvl(r.idpedfaltanterel,0)
          into v_rel
          from tblslvremito r
         where r.idremito=p_idRemito;
        exception
          when no_data_found then
            v_rel:=0;
    end;
    --cursor para remito de pedidos
    if p_TipoTarea = c_TareaConsolidadoPedido  then       
      GetRemitoP(p_idRemito,v_rel,p_Cursor);    
     end if; 
    --cursor para remito de faltante de pedidos 
    if p_TipoTarea in (c_TareaConsolidaPedidoFaltante ,c_TareaFaltanteConsolFaltante)then  
       GetRemitoF(p_idRemito,p_Cursor);    
    end if;      
    --cursor para remito de consolidado comisionista
    if p_TipoTarea in (c_TareaConsolidadoComi,c_TareaConsolidadoComiFaltante) then   
      GetRemitoC(p_idRemito,p_Cursor);    
    end if;   
   EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       '  Error: ' || SQLERRM);
  END GetRemito;
 
  /****************************************************************************************************
  * %v 20/02/2020 - ChM  Versión inicial SetInsertarRemito
  * %v 20/02/2020 - ChM  inserta remito
  *****************************************************************************************************/
  FUNCTION SetInsertarRemito(p_IdTarea               tblslvtarea.idtarea%type,
                             p_NroCarreta            tblslvremito.nrocarreta%type)
                             RETURN INTEGER IS

    v_modulo      varchar2(100) := 'PKG_SLV_REMITOS.SetInsertarRemito';
    v_idremito    tblslvremito.idremito%type;
  BEGIN
   insert into tblslvremito
               (idremito,
               idtarea,
               idpedfaltanterel,
               nrocarreta,
               cdestado,
               dtremito,
               dtupdate,
               cdsucursal)
        values (seq_remito.nextval,    --idremito
                p_IdTarea,              --idtarea
                null,                   --idpedfaltanterel
                p_NroCarreta,          --NroCarreta
                C_EnCursoRemito,      --Cdestado 36 remito en curso
                sysdate,               --dtremito
                null,                 --dtupdate
                g_cdSucursal);
   IF SQL%ROWCOUNT = 0  THEN
     n_pkg_vitalpos_log_general.write(2,
                  'Modulo: ' || v_modulo ||
                  ' imposible insertar remito para la carreta: '||p_NroCarreta);
     return 0; -- devuelve 0 si no inserta
   END IF;
   --devuelve el idremito insertado
   select seq_remito.currval
     into v_idremito
     from dual;
     return v_idremito;
  EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       ' Error: ' || SQLERRM);
      return 0;
  END SetInsertarRemito;

  /****************************************************************************************************
  * %v 26/02/2020 - ChM  Versión inicial SetDetalleRemito
  * %v 26/02/2020 - ChM  actualiza en detalle remito la cantidad ingresada en piking
  * %v 26/05/2020 - ChM  agrego la logica para validar pesables
  * %v 27/05/2020 - ChM  ajuste para solo insertar en el remito por caso de pesables
  * %v 02/07/2020 - LM:  Registro el idpedidoBolsin en la linea del remito
  *****************************************************************************************************/

  FUNCTION SetDetalleRemito(p_idRemito         tblslvremito.idremito%type,
                            p_idTarea          tblslvremito.idtarea%type,
                            p_cdArticulo       tblslvtareadet.cdarticulo%type,
                            p_cantidad         tblslvtareadet.qtunidadmedidabasepicking%type,
                            p_cdunidad         barras.cdunidad%type,
                            p_IdPedidoBolsin   pedidos.idpedido%type default null,
                            p_cantidad_pes     tblslvtareadet.qtunidadmedidabasepicking%type)
                            return integer IS

   v_modulo                        varchar2(100) := 'PKG_SLV_REMITOS.SetDetalleRemito';
   v_res                           integer :=0; 
   v_cant                          tblslvremitodet.qtpiezaspicking%type:=null;
   v_pza                           tblslvremitodet.qtpiezaspicking%type:=null;

  BEGIN
   --verifica si existe remito en curso
   select count(*)
     into v_res
     from tblslvremito re
    where re.cdestado = C_EnCursoRemito  --Cdestado 36 remito en curso
      and re.idremito = p_idRemito
      and re.idtarea = p_idtarea;

      if v_res>0 then     
           --valido si es pesable, multiplico la cantidad por peso del articulo, agrego las piezas   
           if p_cdunidad in ('KG','PZA') then
            v_cant:=p_cantidad*p_cantidad_pes;  
            v_pza:=p_cantidad;
            --valido si es pesable cantidad no puede ser distinto de 1
            if (p_cantidad<>1)then
              return -1;
            end if;
           else
            v_cant:=p_cantidad;  
            v_pza:=0;
           end if;
           insert into tblslvremitodet
                       (idremitodet,
                       idremito,
                       cdarticulo,
                       qtunidadmedidabasepicking,
                       qtpiezaspicking,
                       dtinsert,
                       dtupdate,
                       idpedidollavero,
                       cdsucursal )
                values (seq_remitodet.nextval,
                        p_idRemito,
                        p_cdArticulo,
                        v_cant,
                        v_pza, --qtpiezaspicking
                        sysdate,
                        null,
                        p_IdPedidoBolsin,
                        g_cdSucursal);
            IF SQL%ROWCOUNT = 0  THEN
                n_pkg_vitalpos_log_general.write(2,
                                 'Modulo: ' || v_modulo ||
                                 ' imposible insertar detalle del remito : '||p_idRemito);
                                  return 0; -- devuelve 0 si no inserta
             END IF;
     else
        return 0; -- devuelve 0 si no inserta ni actualiza
      end if;  --if v_res>0

    return 1;
   EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       ' Error: ' || SQLERRM);
      return 0;

  END SetDetalleRemito;

   /****************************************************************************************************
  * %v 20/02/2020 - ChM  Versión inicial SetFinalizarRemito
  * %v 20/02/2020 - ChM  cambia el estado del remito a finalizado
  *****************************************************************************************************/
  FUNCTION SetFinalizarRemito(p_idremito      tblslvremito.idremito%type)
                           RETURN INTEGER IS

    v_modulo      varchar2(100) := 'PKG_SLV_REMITOS.SetFinalizarRemito';
    BEGIN
        update tblslvremito r
           set r.cdestado=C_FinalizadoRemito, --remito finalizado
               r.dtupdate = sysdate
         where r.idremito = p_idremito;
  if SQL%ROWCOUNT = 0  then
     n_pkg_vitalpos_log_general.write(2,
                  'Modulo: ' || v_modulo ||
                  ' imposible actualizar remito numero: '||p_idremito);
     return 0; -- devuelve 0 si no actualiza
  end if;
     return 1; -- devuelve 1 si actualiza
  EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       ' Error: ' || SQLERRM);
      return 0;
  END SetFinalizarRemito;
  
  /****************************************************************************************************
  * %v 20/02/2020 - ChM  Versión inicial PanelRemito
  * %v 20/02/2020 - ChM  inserta remito
  *****************************************************************************************************/
  PROCEDURE PanelRemito(p_DtDesde        IN DATE,
                        p_DtHasta        IN DATE,
                        p_idremito       IN tblslvremito.idremito%type default null,
                        p_NroCarreta     IN tblslvremito.nrocarreta%type default null,                        
                        p_Cursor         OUT CURSOR_TYPE)
                        IS
  v_dtHasta date;
  v_dtDesde date;                             
                            
  BEGIN
    v_dtDesde := trunc(p_DtDesde);
    v_dtHasta := to_date(to_char(p_DtHasta, 'dd/mm/yyyy') || ' 23:59:59',
                         'dd/mm/yyyy hh24:mi:ss');

    OPEN p_Cursor FOR
              --consulta los remitos de consolidados pedidos  
             select re.dtremito,
                    0 Idconsolidadocomi, 
                    cp.idconsolidadopedido Idconsolidadopedido,
                    0 IdcosolidadoFaltante,
                    TRIM(NVL (e.dsrazonsocial, e.dsnombrefantasia))||' ('||TRIM(e.cdcuit)||')' cliente,                         
                    '-' comisionista,
                    pers.dsnombre||' '||pers.dsapellido Armador,
                    es.dsestado,
                    re.idremito,
                    re.nrocarreta,
                    ta.cdtipo tipotarea
               from tblslvremito                        re,
                    tblslvestado                        es,
                    tblslvtarea                         ta, 
                    personas                            pers,  
                    tblslvconsolidadopedido             cp
                    left join (entidades e)
                           on (cp.identidad = e.identidad)                    
              where re.cdestado = es.cdestado                
                and re.idtarea = ta.idtarea
                and ta.idpersonaarmador = pers.idpersona  
                and ta.idconsolidadopedido = cp.idconsolidadopedido 
                and (p_idremito is null or re.idremito = p_idremito)
                and (p_NroCarreta is null or re.nrocarreta = p_NroCarreta)
                and re.dtremito between v_dtDesde and v_dtHasta 
             union all
             --consulta los remitos de distribución
             select re.dtremito,
                    0 Idconsolidadocomi, 
                    cp.idconsolidadopedido Idconsolidadopedido,
                    0 IdcosolidadoFaltante,
                    TRIM(NVL (e.dsrazonsocial, e.dsnombrefantasia))||' ('||TRIM(e.cdcuit)||')' cliente,                              
                    '-' comisionista,
                    'Distribución de Faltante' Armador,
                    es.dsestado,
                    re.idremito,
                    re.nrocarreta,
                    c_TareaConsolidadoPedido tipotarea
               from tblslvremito                        re,
                    tblslvestado                        es,          
                    tblslvpedfaltanterel                frel,   
                    tblslvconsolidadopedido             cp                
                    left join (entidades e)
                           on (cp.identidad = e.identidad)                    
              where re.cdestado = es.cdestado
                and re.idpedfaltanterel = frel.idpedfaltanterel
                and frel.idconsolidadopedido = cp.idconsolidadopedido  
                and (p_idremito is null or re.idremito = p_idremito)
                and (p_NroCarreta is null or re.nrocarreta = p_NroCarreta)                                 
                and re.dtremito between v_dtDesde and v_dtHasta 
             union all
             --consulta los remitos de consolidados comisionistas
             select re.dtremito,
                    cc.idconsolidadocomi Idconsolidadocomi, 
                    0 Idconsolidadopedido,
                    0 IdcosolidadoFaltante,
                    '-' cliente,                           
                    nvl(e.dsrazonsocial,e.dsnombrefantasia) comisionista,
                    pers.dsnombre||' '||pers.dsapellido Armador,
                    es.dsestado,
                    re.idremito,
                    re.nrocarreta,
                    ta.cdtipo tipotarea
               from tblslvremito                        re,
                    tblslvestado                        es,
                    tblslvtarea                         ta, 
                    personas                            pers,  
                    tblslvconsolidadocomi               cc
                    left join (entidades e)
                           on (cc.idcomisionista = e.identidad)           
              where re.cdestado = es.cdestado              
                and re.idtarea = ta.idtarea
                and ta.idpersonaarmador = pers.idpersona  
                and ta.idconsolidadocomi = cc.idconsolidadocomi 
                and (p_idremito is null or re.idremito = p_idremito)
                and (p_NroCarreta is null or re.nrocarreta = p_NroCarreta)                                  
                and re.dtremito between v_dtDesde and v_dtHasta
             union all
             --consulta los remitos de consolidados Faltante
             select re.dtremito,
                    0 Idconsolidadocomi, 
                    0 Idconsolidadopedido,
                    pf.idpedfaltante IdcosolidadoFaltante,
                    '-' cliente,                           
                    '-' comisionista,
                    pers.dsnombre||' '||pers.dsapellido Armador,
                    es.dsestado,
                    re.idremito,
                    re.nrocarreta,
                    ta.cdtipo tipotarea
               from tblslvremito                        re,
                    tblslvestado                        es,
                    tblslvtarea                         ta, 
                    personas                            pers,  
                    tblslvpedfaltante                   pf                                      
              where re.cdestado = es.cdestado                
                and re.idtarea = ta.idtarea
                and ta.idpersonaarmador = pers.idpersona  
                and ta.idpedfaltante = pf.idpedfaltante
                and (p_idremito is null or re.idremito = p_idremito)
                and (p_NroCarreta is null or re.nrocarreta = p_NroCarreta)
                and re.dtremito between v_dtDesde and v_dtHasta
           order by dtremito desc,
                    tipotarea asc;        
     
  END PanelRemito;


end PKG_SLV_REMITOS;
/
