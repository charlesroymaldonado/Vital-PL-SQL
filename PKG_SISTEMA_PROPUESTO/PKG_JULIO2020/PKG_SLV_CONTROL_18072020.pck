CREATE OR REPLACE PACKAGE PKG_SLV_CONTROL is
  /**********************************************************************************************************
  * Author  : CHARLES MALDONADO
  * Created : 01/07/2020 03:45:03 p.m.
  * %v Paquete para gestión y control de REMITOS SLV
  **********************************************************************************************************/
  -- Tipos de datos

  TYPE CURSOR_TYPE IS REF CURSOR;
  
  
  -- para uso publico del paquete
  
  PROCEDURE GetControl(p_idremito           IN  tblslvremito.idremito%type,
                       p_idpersona          IN  personas.idpersona%type,                     
                       p_Ok                 OUT number,
                       p_error              OUT varchar2);
                       
  PROCEDURE SetControl(p_idremito           IN  tblslvremito.idremito%type,                        
                       p_cdBarras           IN  barras.cdeancode%type,                       
                       p_qtunidad           IN  tblslvremitodet.qtunidadmedidabasepicking%type);  
                       
  PROCEDURE SetControlarRemito(p_idremito           IN  tblslvremito.idremito%type,
                               p_Ok                 OUT number,
                               p_error              OUT varchar2,
                               p_cursor             OUT CURSOR_TYPE);  
                                
  PROCEDURE GetPanelControl  (p_DtDesde        IN DATE,
                              p_DtHasta        IN DATE,
                              p_idcomi         IN tblslvconsolidadopedido.idconsolidadocomi%type default 0,
                              p_idpedido       IN tblslvconsolidadopedido.idconsolidadopedido%type default 0,
                              p_Cursor         OUT CURSOR_TYPE);
                              
  PROCEDURE GetDetalleControl(p_idcomi         IN  tblslvconsolidadopedido.idconsolidadocomi%type,
                              p_idpedido       IN  tblslvconsolidadopedido.idconsolidadopedido%type,
                              p_Cabezera       OUT Varchar,
                              p_Cursor         OUT CURSOR_TYPE); 
                              
  PROCEDURE GetArticulosControl(p_idcomi         IN  tblslvconsolidadopedido.idconsolidadocomi%type,
                                p_idpedido       IN  tblslvconsolidadopedido.idconsolidadopedido%type,
                                p_CursorCab      OUT CURSOR_TYPE,
                                p_Cursor         OUT CURSOR_TYPE);                                 
                              
  --PARA USO INTERNO DEL PAQUETE
  
   FUNCTION ContarRemitos(p_IdConsolidado        tblslvconsolidadopedido.idconsolidadocomi%type,
                         p_TipoTarea           tblslvtipotarea.cdtipo%type) 
                               RETURN integer;
                               
   FUNCTION EstadoPedidoControl (p_IdConsolidado       IN tblslvconsolidadopedido.idconsolidadocomi%type,
                                p_TipoTarea           IN tblslvtipotarea.cdtipo%type) 
                               RETURN VARCHAR2;
                               
   FUNCTION ErroresControl  (p_idremito           IN  tblslvremito.idremito%type)
                              RETURN VARCHAR2;
                                                                                                                                                                                                                                                                                                             
   FUNCTION GetFacturas  (p_IdConsolidado        tblslvconsolidadopedido.idconsolidadocomi%type,
                         p_TipoTarea            tblslvtipotarea.cdtipo%type,
                         p_cdarticulo           articulos.cdarticulo%type)
                         RETURN VARCHAR2;                         
end PKG_SLV_CONTROL;
/
CREATE OR REPLACE PACKAGE BODY PKG_SLV_CONTROL is
/***************************************************************************************************
*  %v 01/07/2020  ChM - Parametros globales del PKG
****************************************************************************************************/

  g_cdSucursal      sucursales.cdsucursal%type := trim(getvlparametro('CDSucursal','General'));

  --costante de tblslvestado
 -- C_EnCursoRemito                    CONSTANT tblslvestado.cdestado%type := 36;
  C_FinalizadoRemito                 CONSTANT tblslvestado.cdestado%type := 37;
  C_IniciaControl                    CONSTANT tblslvestado.cdestado%type := 43;
  C_Controlado                       CONSTANT tblslvestado.cdestado%type := 44; 
  c_TareaConsolidadoPedido           CONSTANT tblslvtipotarea.cdtipo%type := 25;
  c_TareaConsolidadoComi             CONSTANT tblslvtipotarea.cdtipo%type := 50;
  
  /****************************************************************************************************
  * %v 03/07/2020 - ChM  Versión inicial GetControl
  * %v 03/07/2020 - ChM  recibe un idremito para iniciar su control                      
  *****************************************************************************************************/
  PROCEDURE GetControl(p_idremito           IN  tblslvremito.idremito%type,
                       p_idpersona          IN  personas.idpersona%type,                      
                       p_Ok                 OUT number,
                       p_error              OUT varchar2) IS
                       
    v_modulo           varchar2(100) := 'PKG_SLV_CONTROL.GetControl';
    v_estado           tblslvremito.cdestado%type:=null;
    v_error            varchar2(250);  
    v_idremito         tblslvremito.idremito%type:=0;   
    v_idControl        tblslvcontrolremito.idcontrolremito%type;
    
   BEGIN
     --valida si el remito existe 
    begin
      select re.cdestado
        into v_estado
        from tblslvremito re
       where re.idremito = p_idremito;
     exception
       when no_data_found then
          p_Ok    := 0;
          p_error := 'Remito '||to_char(p_idremito)||' no existe.';
       return;  
      end;
    --verifica si esta finalizado
    if v_estado <> C_FinalizadoRemito then
       p_Ok    := 0;
       p_error := 'Remito '||to_char(p_idremito)||' No Finalizado.';
       RETURN;
    end if; 
    
   --verifica si el remito se controla
   begin
    select r.idremito 
      into v_idremito     
      from tblslvremito     r,
           tblslvtarea      t,
           tblslvtipotarea  tt
     where r.idtarea = t.idtarea
       and t.cdtipo = tt.cdtipo
       -- indica que remito se controla
       and tt.iccontrolaremito = 1     
       and r.idremito = p_idremito
    union
    --los remito de distribución se controlan
    select r.idremito 
      from tblslvremito          r,
           tblslvpedfaltanterel  pfrel
     where r.idpedfaltanterel = pfrel.idpedfaltanterel
       and r.idremito = p_idremito;   
     exception
       when no_data_found then
          p_Ok    := 0;
          p_error := 'Remito '||to_char(p_idremito)||' no se controla.';
       return;  
      end;   
    
     --valida si existe el remito en tblslvcontrolremito obtiene el idcontrol
       begin        
            select cr.idcontrolremito,
                   cr.cdestado                   
              into v_idControl,
                   v_estado                   
              from tblslvcontrolremito cr
             where cr.idremito = p_idremito; 
           exception        
             -- si no existe lo crea    
           when no_data_found then
            v_error:='Falla Insert tblslvcontrolremito';
            v_idControl:=seq_controlremito.nextval;
            insert into tblslvcontrolremito
                   (idcontrolremito,
                    idremito,
                    cdestado,
                    idpersonacontrol,
                    qtcontrol,
                    dtinicio,
                    dtfin,
                    cdsucursal)
             values (v_idControl,
                     p_idremito,
                     C_IniciaControl,
                     p_idpersona,
                     1,
                     sysdate,
                     null,
                     g_cdSucursal);
            IF SQL%ROWCOUNT = 0 THEN
              n_pkg_vitalpos_log_general.write(2,
                                              'Modulo: ' || v_modulo ||
                                              '  Detalle Error: ' || v_error);
              p_Ok    := 0;
              p_error:='Error. Comuniquese con Sistemas!';
              ROLLBACK;
              RETURN;
            END IF; 
            p_Ok    := 1;
            p_error := '';
            commit;
            return;   
         end;
     --verifica si esta Controlado
    if v_estado = C_Controlado then
       p_Ok    := 0;
       p_error := 'Remito '||to_char(p_idremito)||' ya Controlado.';
       RETURN;
    end if;      
    p_Ok    := 1;
    p_error := '';
    return;       
    EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       ' Error: ' || SQLERRM);
      p_Ok    := 0;
      p_error:='Error Control Remito. Comuniquese con Sistemas!';
  END GetControl;
  
  /****************************************************************************************************
  * %v 01/07/2020 - ChM  Versión inicial SetControl
  * %v 01/07/2020 - ChM  recibe un idcontrol para inserta los artículos
  *****************************************************************************************************/
  PROCEDURE SetControl(p_idremito           IN  tblslvremito.idremito%type,                        
                       p_cdBarras           IN  barras.cdeancode%type,                       
                       p_qtunidad           IN  tblslvremitodet.qtunidadmedidabasepicking%type  
                       ) IS

    v_modulo           varchar2(100) := 'PKG_SLV_CONTROL.SetControl';
    v_estado           tblslvremito.cdestado%type:=null;
    v_error            varchar2(250); 
    v_idcontroldet     tblslvcontrolremitodet.idcontrolremitodet%type;
    v_idControl        tblslvcontrolremito.idcontrolremito%type;
    v_qtcontrol        tblslvcontrolremito.qtcontrol%type;     
    v_qtbase           tblslvcontrolremitodet.qtunidadmedidabasepicking%type;
    v_qtpiezas         tblslvcontrolremitodet.qtpiezaspicking%type;
    v_cdarticulo       articulos.cdarticulo%type;
    v_cdunidad         barras.cdunidad%type;
    v_cantidad         tblslvtareadet.qtunidadmedidabase%type;
    V_UxB              number;
  --  v_Cursor           CURSOR_TYPE;
 --   p_Ok               number;
 --   p_error            varchar2(100);
  BEGIN
    
      --valida si existe el p_idControl en tblslvcontrolremito 
       begin        
            select cr.idcontrolremito,
                   cr.cdestado,
                   cr.qtcontrol                   
              into v_idControl,
                   v_estado,
                   v_qtcontrol                   
              from tblslvcontrolremito cr
             where cr.idremito = p_idremito; 
       exception                  
          when no_data_found then
      --        p_Ok    := 0;
      --        p_error := 'Control para el remito '||to_char(p_idremito)||' no existe.';
              return;
       end;
       
      --verifica si esta Controlado
      if v_estado = C_Controlado then
       --  p_Ok    := 0;
     --    p_error := 'Remito '||to_char(p_idremito)||' ya Controlado.';
         RETURN;
      end if;  
      
      --busca el cdarticulo del p_cdBarras
      pkg_slv_articulo.GetcdArticuloxBarras(p_cdBarras,v_cdArticulo,v_cdunidad,v_cantidad);
      --si no lo encuentra no continua el proceso (no error al usuario)
      if v_cdarticulo = '-' then
       --   p_Ok    := 1;
      --    p_error := 'Codigo de Barras no encontrado '||p_cdBarras;
          return;
      end if;
      
     v_qtbase:=p_qtunidad;
     v_qtpiezas:=0;
      --si es distinto de unidad o pesable se busca y multiplica por el UXB
     if v_cdunidad not in ('UN','KG','PZA') then
       V_UxB:=posapp.n_pkg_vitalpos_materiales.GetUxB(v_cdArticulo,v_cdunidad);
       v_qtbase:=p_qtunidad*V_UxB;
       v_qtpiezas:=0;
     end if;   
     --si es igual a KG o PZA pesable
     if v_cdunidad in ('KG','PZA') then
       v_qtpiezas:=p_qtunidad; 
       v_qtbase:=0;
     end if;  
  --valido si es el primer control del remito y llega a esta condición hay diferencias
  if  v_qtcontrol = 1 then
      --verifica si existe el detalle 
       begin           
            select crd.idcontrolremitodet      
              into v_idControldet            
              from tblslvcontrolremitodet crd
             where crd.idcontrolremito = v_idControl
               and crd.cdarticulo = v_cdarticulo; 
             -- si existe actualiza la cantidad picking
             v_error:='Falla update tblslvcontrolremitodet';
             update tblslvcontrolremitodet crd
                set crd.qtunidadmedidabasepicking = nvl(crd.qtunidadmedidabasepicking,0)+v_qtbase,
                    crd.qtpiezaspicking = nvl(crd.qtpiezaspicking,0)+v_qtpiezas,
                    crd.dtupdate = sysdate
              where crd.idcontrolremitodet = v_idcontroldet
                and crd.idcontrolremito = v_idControl
                and crd.cdarticulo = v_cdarticulo; 
             IF SQL%ROWCOUNT = 0 THEN
                 n_pkg_vitalpos_log_general.write(2,
                                                  'Modulo: ' || v_modulo ||
                                                  '  Detalle Error: ' || v_error);
        --         p_Ok    := 0;
        --         p_error:='Error al actualizar Artículo';
                 ROLLBACK;
                 RETURN;
             END IF;                   
       exception        
       -- si no existe lo crea    
       when no_data_found then       
                -- inserto en tblslvcontrolremitodet      
                v_error:='Falla Insert tblslvcontrolremitodet';
                insert into tblslvcontrolremitodet
                           (idcontrolremitodet,
                            idcontrolremito,
                            cdarticulo,
                            qtdiferenciaunidadmbase,
                            qtdiferenciapiezas,
                            qtunidadmedidabasepicking,
                            qtpiezaspicking,
                            dtinsert,
                            dtupdate,
                            cdsucursal)
                     values (seq_controlremitodet.nextval,
                             v_idControl,
                             v_cdarticulo,
                             0,
                             0,
                             v_qtbase,
                             v_qtpiezas,
                             sysdate,
                             null,
                             g_cdSucursal);
                  IF SQL%ROWCOUNT = 0 THEN
                     n_pkg_vitalpos_log_general.write(2,
                                                      'Modulo: ' || v_modulo ||
                                                      '  Detalle Error: ' || v_error);
                 --    p_Ok    := 0;
                --     p_error:='Error al insertar Artículo';
                     ROLLBACK;
                     RETURN;
                 END IF;  
      end; 
      end if;
   /*--valida si el qtcontrol es 1 devuelve lo piqueado sin diferencias
   if v_qtcontrol = 1 then
     open v_Cursor for           
           select A.cdarticulo,
                  A.cdarticulo||' - '||des.vldescripcion Articulo,
                  A.Cantidad
             from (select crd.cdarticulo,
                          PKG_SLV_Articulo.SetFormatoArticuloscod(crd.cdarticulo,
                          --valida pesables
                          decode(nvl(sum(crd.qtpiezaspicking),0),0,
                          (nvl(sum(crd.qtunidadmedidabasepicking),0)),
                          nvl(sum(crd.qtpiezaspicking),0))) Cantidad                     
                     from tblslvcontrolremitodet            crd                          
                    where crd.idcontrolremito = v_idControl             
                      --solo muestro las piqueadas por primera vez
                      and (crd.qtdiferenciaunidadmbase = 0 or crd.qtdiferenciapiezas = 0)
                      -- que tenga cantidad ingresada
                      and (nvl(crd.qtunidadmedidabasepicking,0)<>0 or nvl(crd.qtpiezaspicking,0)<>0)
                 group by crd.cdarticulo
                   )A,
                    descripcionesarticulos des
              where A.cdarticulo = des.cdarticulo;
        
     end if;
     --valida si el qtcontrol es diferente de 1 devuelve lo piqueado con diferencias
   if v_qtcontrol <> 1 then
     open v_Cursor for 
           select A.cdarticulo,
                  A.cdarticulo||' - '||des.vldescripcion Articulo,
                  A.Cantidad
             from (select crd.cdarticulo,
                          PKG_SLV_Articulo.SetFormatoArticuloscod(crd.cdarticulo,
                          --valida pesables
                          decode(nvl(sum(crd.qtpiezaspicking),0),0,
                          (nvl(sum(crd.qtunidadmedidabasepicking),0)),
                          nvl(sum(crd.qtpiezaspicking),0))) Cantidad                     
                     from tblslvcontrolremitodet            crd                          
                    where crd.idcontrolremito = v_idControl             
                       --solo muestra los artículos con diferencias
                      and (crd.qtdiferenciaunidadmbase <> 0 or crd.qtdiferenciapiezas <> 0)
                 group by crd.cdarticulo
                   )A,
                    descripcionesarticulos des
              where A.cdarticulo = des.cdarticulo;            
     end if;*/
  --  p_Ok:=1;
  --  p_error:='';
  --valido si es el SEGUNDO control del remito actualizo solo artículos con diferencias
  if  v_qtcontrol = 2 then
      --verifica si existe el detalle y tiene diferencias 
       begin           
            select crd.idcontrolremitodet      
              into v_idControldet            
              from tblslvcontrolremitodet crd
             where crd.idcontrolremito = v_idControl
               --solo artículos con diferencias
               and (crd.qtdiferenciaunidadmbase <> 0 or crd.qtdiferenciapiezas <> 0)
               and crd.cdarticulo = v_cdarticulo; 
             -- si existe actualiza la cantidad picking
             v_error:='Falla update tblslvcontrolremitodet';
             update tblslvcontrolremitodet crd
                set crd.qtunidadmedidabasepicking = nvl(crd.qtunidadmedidabasepicking,0)+v_qtbase,
                    crd.qtpiezaspicking = nvl(crd.qtpiezaspicking,0)+v_qtpiezas,
                    crd.dtupdate = sysdate
              where crd.idcontrolremitodet = v_idcontroldet
                and crd.idcontrolremito = v_idControl
                and crd.cdarticulo = v_cdarticulo; 
             IF SQL%ROWCOUNT = 0 THEN
                 n_pkg_vitalpos_log_general.write(2,
                                                  'Modulo: ' || v_modulo ||
                                                  '  Detalle Error: ' || v_error);
        --         p_Ok    := 0;
        --         p_error:='Error al actualizar Artículo';
                 ROLLBACK;
                 RETURN;
             END IF;                   
       exception        
       -- si no existe y es segunda vuelta error
       when no_data_found then       
         --  p_Ok    := 0;
          -- p_error:='artículo no existente segundo control'; 
          rollback;
          return;  
      end; 
      end if;
  commit;
  EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       ' Error: ' || SQLERRM);
    --  p_Ok    := 0;
   --   p_error:='Error Control Remito. Comuniquese con Sistemas!';
  END SetControl;
  
   /****************************************************************************************************
  * %v 03/07/2020 - ChM  Versión inicial SetControlarRemito
  * %v 03/07/2020 - ChM  recibe un idcontrol para validar contra el remito
  *****************************************************************************************************/
  PROCEDURE SetControlarRemito(p_idremito           IN  tblslvremito.idremito%type,
                               p_Ok                 OUT number,
                               p_error              OUT varchar2,
                               p_cursor             OUT CURSOR_TYPE) IS

    v_modulo           varchar2(100) := 'PKG_SLV_CONTROL.SetControl';
    v_estado           tblslvremito.cdestado%type:=null;
    v_error            varchar2(250); 
    v_idControl        tblslvcontrolremito.idcontrolremito%type;  
    v_qtcontrol        tblslvcontrolremito.qtcontrol%type:=0;
    v_band             integer:=0;   
    
  BEGIN
     --valida si existe el p_idControl en tblslvcontrolremito 
     begin        
          select cr.cdestado,
                 cr.idcontrolremito,
                 cr.qtcontrol                
            into v_estado,
                 v_idControl,
                 v_qtcontrol               
            from tblslvcontrolremito cr
           where cr.idremito = p_idremito; 
     exception               
        when no_data_found then
           p_Ok    := 0;
           p_error := 'Remito '||to_char(p_idremito)||' No existe en control.';
          return; 
     end;
    
     --valida si existe el p_idControl en tblslvcontrolremitodet y se piqueo algo
     begin        
          select crd.idcontrolremitodet              
            into v_band              
            from tblslvcontrolremitodet crd
           where crd.idcontrolremito = v_idControl
             -- verifica que se piqueo algo 
             and (nvl(crd.qtunidadmedidabasepicking,0)<>0 or nvl(crd.qtpiezaspicking,0)<>0)
             and rownum=1; 
      exception
      when no_data_found then
        n_pkg_vitalpos_log_general.write(2,
                                        'Modulo: ' || v_modulo ||
                                        '  Control de Remito Sin detalle Piqueado ');
        p_Ok    := 0;
        p_error := ' Remito '||to_char(p_idremito)||' No tiene artículos picking para controlar.';
        ROLLBACK;
        RETURN;           
    end;   
       
    --verifica si esta Controlado
    if v_estado = C_Controlado then
       p_Ok    := 0;
       p_error := 'Remito '||to_char(p_idremito)||' ya Controlado.';
       RETURN;
    end if;  
   --busca las diferencias del control con el remito y las actualiza en el tblslvcontrolremitodet
      v_band:=0;
      for control in
          (select cr.idremito,
                  crd.idcontrolremitodet,         
                  crd.cdarticulo,
                  crd.qtunidadmedidabasepicking,
                  crd.qtpiezaspicking
             from tblslvcontrolremito       cr,
                  tblslvcontrolremitodet    crd
            where cr.idcontrolremito = crd.idcontrolremito         
              and cr.idcontrolremito = v_idControl)   
       loop
          for remito in
             (select rd.cdarticulo,
                     sum(rd.qtunidadmedidabasepicking) qtbase,
                     sum(rd.qtpiezaspicking) qtpiezas               
                from tblslvremitodet rd
               where rd.idremito = control.idremito
                 and rd.cdarticulo = control.cdarticulo
            group by rd.cdarticulo)
         loop
            --Actualiza las diferencias
            v_band:=1;
            --limpio qtbase si es pesable
            if remito.qtpiezas <>0 then
               remito.qtbase:=0; 
            end if;  
             v_error:='Falla UPDATE tblslvcontrolremitodet';
            update tblslvcontrolremitodet crd               
               set crd.qtdiferenciaunidadmbase = nvl(crd.qtunidadmedidabasepicking,0)-remito.qtbase,
                   crd.qtdiferenciapiezas = nvl(crd.qtpiezaspicking,0) - remito.qtpiezas,
                   crd.dtupdate=sysdate
             where crd.idcontrolremito = v_idControl
               and crd.cdarticulo = control.cdarticulo
               and crd.idcontrolremitodet = control.idcontrolremitodet;
              IF SQL%ROWCOUNT = 0 THEN
                     n_pkg_vitalpos_log_general.write(2,
                                                      'Modulo: ' || v_modulo ||
                                                      '  Detalle Error: ' || v_error);
                     p_Ok    := 0;
                     p_error:='Error. Comuniquese con Sistemas';
                     ROLLBACK;
                     RETURN;
                 END IF;       
         end loop; 
         -- si no existe en remito v_band en cero es sobrante se actualiza todo como diferencia positiva    
         if v_band = 0 then              
             v_error:='Falla UPDATE tblslvcontrolremitodet';
            update tblslvcontrolremitodet crd               
               set crd.qtdiferenciaunidadmbase = nvl(crd.qtunidadmedidabasepicking,0),
                   crd.qtdiferenciapiezas = nvl(crd.qtpiezaspicking,0),
                   crd.dtupdate=sysdate
             where crd.idcontrolremito = v_idControl
               and crd.cdarticulo = control.cdarticulo
               and crd.idcontrolremitodet = control.idcontrolremitodet;
              IF SQL%ROWCOUNT = 0 THEN
                     n_pkg_vitalpos_log_general.write(2,
                                                      'Modulo: ' || v_modulo ||
                                                      '  Detalle Error: ' || v_error);
                     p_Ok    := 0;
                     p_error:='Error. Comuniquese con Sistemas';
                     ROLLBACK;
                     RETURN;
                 END IF;       
           else
             --pone la bandera a cero para revisar en remito el siguiente articulo a controlar
             v_band:=0;
           end if;         
    end loop; 
    --listado de articulos del remito que no están en el control
      for remito in
             (select rd.cdarticulo,
                     sum(rd.qtunidadmedidabasepicking) qtbase,
                     sum(rd.qtpiezaspicking) qtpiezas               
                from tblslvremitodet rd
               where rd.idremito = p_idremito
                  -- devuelve solo los cdarticulos de remito que no estan en tblslvcontrolremitodet
                 and rd.cdarticulo not in (select crd.cdarticulo
                                             from tblslvcontrolremitodet crd
                                            where crd.idcontrolremito = v_idControl) 
            group by rd.cdarticulo)
       loop
         --limpio qtbase si es pesable
        if remito.qtpiezas <>0 then
           remito.qtbase:=0; 
        end if;  
        --si estan en remito y no controlado lo inserto en tblslvcontrolremitodet  
        --con diferencias negativas y valor de picking null   
        v_error:='Falla Insert tblslvcontrolremitodet';
        insert into tblslvcontrolremitodet
                   (idcontrolremitodet,
                    idcontrolremito,
                    cdarticulo,
                    qtdiferenciaunidadmbase,
                    qtdiferenciapiezas,
                    qtunidadmedidabasepicking,
                    qtpiezaspicking,
                    dtinsert,
                    dtupdate,
                    cdsucursal)
             values (seq_controlremitodet.nextval,
                     v_idControl,
                     remito.cdarticulo,
                     -remito.qtbase,
                     -remito.qtpiezas,
                     null,
                     null,
                     sysdate,
                     null,
                     g_cdSucursal);
          IF SQL%ROWCOUNT = 0 THEN
             n_pkg_vitalpos_log_general.write(2,
                                              'Modulo: ' || v_modulo ||
                                              '  Detalle Error: ' || v_error);
             p_Ok    := 0;
             p_error:='Error. Comuniquese con Sistemas';
             ROLLBACK;
             RETURN;
         END IF; 
       end loop;
     
    --cuento los que tengan diferencias  
    v_band:=-1;
    select count (*)
      into v_band
      from tblslvcontrolremitodet    crd
     where crd.idcontrolremito = v_idControl
       and (crd.qtdiferenciaunidadmbase <> 0 or crd.qtdiferenciapiezas <> 0);
     -- si no hay diferencias paso tblslvcontrolremito estado controlado  
     if v_band = 0  then
        v_error:='Falla UPDATE tblslvcontrolremito';
       update tblslvcontrolremito cr
          set cr.cdestado = C_Controlado,
              cr.dtfin = sysdate
        where cr.idcontrolremito=v_idControl;
              IF SQL%ROWCOUNT = 0 THEN
                 n_pkg_vitalpos_log_general.write(2,
                                                  'Modulo: ' || v_modulo ||
                                                  '  Detalle Error: ' || v_error);
                 p_Ok    := 0;
                 p_error:='Error. Comuniquese con Sistemas';
                 ROLLBACK;
                 RETURN;
             END IF;
       --si remito controlado termina procedimiento          
       p_Ok:=1;
       p_error:='';
       commit;  
       RETURN;        
     end if;

  --valido si es el primer control del remito y llega a esta condición hay diferencias
  if  v_qtcontrol = 1 then
       --actualiza a 2 tblslvcontrolremito, para iniciar el segundo piking
       v_error:='Falla UPDATE tblslvcontrolremito';
       update tblslvcontrolremito cr
          set cr.qtcontrol = 2
        where cr.idcontrolremito = v_idControl;
              IF SQL%ROWCOUNT = 0 THEN
                 n_pkg_vitalpos_log_general.write(2,
                                                  'Modulo: ' || v_modulo ||
                                                  '  Detalle Error: ' || v_error);
                 p_Ok    := 0;
                 p_error:='Error. Comuniquese con Sistemas';
                 ROLLBACK;
                 RETURN;
             END IF;
            --actualiza a null en tblslvcontrolremitodet los picking con diferencias para volver a piquear  
            v_error:='Falla UPDATE tblslvcontrolremitodet';        
            update tblslvcontrolremitodet crd               
               set crd.qtunidadmedidabasepicking = null,
                   crd.qtpiezaspicking = null,
                   crd.dtupdate = sysdate
             where crd.idcontrolremito = v_idControl
               and (crd.qtdiferenciaunidadmbase<>0 or crd.qtdiferenciapiezas <>0);
              IF SQL%ROWCOUNT = 0 THEN
                 n_pkg_vitalpos_log_general.write(2,
                                                  'Modulo: ' || v_modulo ||
                                                  '  Detalle Error: ' || v_error);
                 p_Ok    := 0;
                 p_error:='Error. Comuniquese con Sistemas';
                 ROLLBACK;
                 RETURN;
             END IF;          
   p_Ok:=0;
   p_error := 'Remito '||to_char(p_idremito)||' con diferencias, por favor volver a controlar.';
   commit;
   --cursor con el listado de diferencias 
   open p_Cursor for 
           select A.cdarticulo,
                  A.cdarticulo||' - '||des.vldescripcion Articulo,
                  A.Cantidad
             from (select crd.cdarticulo,
                          PKG_SLV_Articulo.SetFormatoArticuloscod(crd.cdarticulo,
                          --valida pesables
                          decode(nvl(sum(crd.qtpiezaspicking),0),0,
                          (nvl(sum(crd.qtunidadmedidabasepicking),0)),
                          nvl(sum(crd.qtpiezaspicking),0))) Cantidad                     
                     from tblslvcontrolremitodet            crd                          
                    where crd.idcontrolremito = v_idControl             
                       --solo muestra los artículos con diferencias
                      and (crd.qtdiferenciaunidadmbase <> 0 or crd.qtdiferenciapiezas <> 0)
                 group by crd.cdarticulo
                   )A,
                    descripcionesarticulos des
              where A.cdarticulo = des.cdarticulo;       
   RETURN;             
  end if; 
  --valido si es el segundo control del remito y llega a esta condición hay diferencias
  if  v_qtcontrol = 2 then
     --actualiza a CONTROLADO la tblslvcontrolremito
       v_error:='Falla UPDATE tblslvcontrolremito';
       update tblslvcontrolremito cr
          set cr.cdestado = C_Controlado,
              cr.dtfin = sysdate
        where cr.idcontrolremito=v_idControl;
              IF SQL%ROWCOUNT = 0 THEN
                 n_pkg_vitalpos_log_general.write(2,
                                                  'Modulo: ' || v_modulo ||
                                                  '  Detalle Error: ' || v_error);
                 p_Ok    := 0;
                 p_error:='Error. Comuniquese con Sistemas';
                 ROLLBACK;
                 RETURN;
             END IF;
   p_Ok:=0;
   p_error := 'Remito '||to_char(p_idremito)||' Controlado con diferencias por favor ver Reporte.';
   commit;  
   RETURN;             
  end if; 
  EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       ' Error: ' || SQLERRM);
      p_Ok    := 0;
      p_error:='Error Control Remito. Comuniquese con Sistemas!';
  END SetControlarRemito;
  
  /****************************************************************************************************
  * %v 14/07/2020 - ChM  Versión inicial ContarRemitos
  * %v 14/07/2020 - ChM  Obtener la cantidad de remitos de un pedido
  *****************************************************************************************************/
  FUNCTION ContarRemitos(p_IdConsolidado        tblslvconsolidadopedido.idconsolidadocomi%type,
                         p_TipoTarea            tblslvtipotarea.cdtipo%type) 
                               RETURN integer IS     
  V_cant                       integer:=0;                                   
  BEGIN
    if  p_TipoTarea = c_TareaConsolidadoPedido then
        select count (*)
          into v_cant
           from (select re.idremito                
                  from tblslvremito               re,
                       tblslvtarea                ta
                 where re.idtarea = ta.idtarea      
                   and ta.idconsolidadopedido = p_IdConsolidado
             union all 
               select re.idremito                
                 from tblslvremito              re,
                      tblslvpedfaltanterel      pfrel,
                      tblslvconsolidadopedido   cp2
                where re.idpedfaltanterel = pfrel.idpedfaltanterel
                  and cp2.idconsolidadopedido = pfrel.idconsolidadopedido
                  and cp2.idconsolidadopedido = p_IdConsolidado);
    end if;
    if p_TipoTarea = c_TareaConsolidadoComi then
      select count (*)  
        into v_cant            
        from tblslvremito               re,
             tblslvtarea                ta
       where re.idtarea = ta.idtarea      
         and ta.idconsolidadocomi = p_IdConsolidado; 
     end if;              
    RETURN V_cant;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN 0;  
  END ContarRemitos;
 /****************************************************************************************************
  * %v 14/07/2020 - ChM  Versión inicial GetPanelControl
  * %v 14/07/2020 - ChM  Obtener Consolidados control por fecha
  *****************************************************************************************************/
  PROCEDURE GetPanelControl  (p_DtDesde        IN  DATE,
                              p_DtHasta        IN  DATE,
                              p_idcomi         IN  tblslvconsolidadopedido.idconsolidadocomi%type default 0,
                              p_idpedido       IN  tblslvconsolidadopedido.idconsolidadopedido%type default 0,
                              p_Cursor         OUT CURSOR_TYPE) IS
  v_dtHasta                   date;
  v_dtDesde                   date;                                                   
  BEGIN
    v_dtDesde := trunc(p_DtDesde);    
    v_dtHasta := to_date(to_char(p_DtHasta, 'dd/mm/yyyy') || ' 23:59:59','dd/mm/yyyy hh24:mi:ss');   
    
    OPEN p_Cursor FOR
         select A.fechapedido,
                A.Idconsopedido,
                A.Idconsocomi,
                A.cliente,
                A.comisionista,
                A.Estado,
                A.cantremito  
           from (select cp.dtinsert fechapedido,
                        cp.idconsolidadopedido Idconsopedido,
                        0 Idconsocomi,                  
                        TRIM(NVL (e.dsrazonsocial, e.dsnombrefantasia))||' ('||TRIM(e.cdcuit)||')' cliente, 
                        '-' comisionista,
                        PKG_SLV_CONTROL.EstadoPedidoControl(cp.idconsolidadopedido,c_TareaConsolidadoPedido) Estado,
                        ContarRemitos(cp.idconsolidadopedido,c_TareaConsolidadoPedido) cantremito                
                   from entidades                    e,                
                        tblslvconsolidadopedido      cp         
                  where cp.identidad = e.identidad
                    and cp.idconsolidadocomi is  null
                    and ((p_IdPedido = 0 and p_idcomi = 0) or cp.idconsolidadopedido = p_idpedido)                    
                    and cp.dtinsert between v_dtDesde and v_dtHasta
              union all
                 select cc.dtinsert fechapedido,
                        0 Idconsopedido,
                        cc.idconsolidadocomi Idconsocomi,   
                        '-' cliente,               
                        NVL (e.dsrazonsocial, e.dsnombrefantasia) comisionista,
                        PKG_SLV_CONTROL.EstadoPedidoControl(cc.idconsolidadocomi,c_TareaConsolidadoComi) Estado,
                        ContarRemitos(cc.idconsolidadocomi,c_TareaConsolidadoComi) cantremito                   
                   from entidades                    e,                
                        tblslvconsolidadocomi        cc         
                  where cc.idcomisionista = e.identidad              
                    and ((p_IdComi = 0  and p_idpedido = 0) or cc.idconsolidadocomi = p_idComi)
                    and cc.dtinsert between v_dtDesde and v_dtHasta) A
       --   where A.estado <> 'Sin Remito'          
       order by A.fechapedido desc;
  END GetPanelControl;
  /****************************************************************************************************
  * %v 14/07/2020 - ChM  Versión inicial EstadoPedidoControl
  * %v 14/07/2020 - ChM  Obtener el estado por pedido segun el numero de remitos controlados
  *****************************************************************************************************/
  FUNCTION EstadoPedidoControl (p_IdConsolidado        tblslvconsolidadopedido.idconsolidadocomi%type,
                                p_TipoTarea            tblslvtipotarea.cdtipo%type) 
                               RETURN VARCHAR2 IS                
                                          
  v_estado                     tblslvcontrolremito.cdestado%type; 
  v_cRemito                    integer:=0;  
  v_cError                     integer:=0;
  v_cControl                   integer:=0;
                          
  BEGIN
     if  p_TipoTarea = c_TareaConsolidadoPedido then
       --recorro todos los remitos del idpedido
       for pedido in
                 (select r.idremito
                    from tblslvtarea          ta,
                         tblslvremito         r
                   where ta.idtarea = r.idtarea               
                     and ta.idconsolidadopedido = p_idconsolidado
               union all    
                  select r.idremito 
                    from tblslvremito              r,
                         tblslvpedfaltanterel      pfrel,
                         tblslvconsolidadopedido   cp
                   where r.idpedfaltanterel = pfrel.idpedfaltanterel
                     and cp.idconsolidadopedido =  pfrel.idconsolidadopedido
                     and cp.idconsolidadopedido = p_idconsolidado)
      loop
        --cuento los remitos
        v_cRemito:=v_cRemito+1;
        begin
          select cr.cdestado
            into v_estado 
            from tblslvcontrolremito  cr
           where cr.idremito = pedido.idremito;
           --cuento los remitos controlados 
          if v_estado = C_Controlado then
             v_cControl:=v_cControl+1;
          end if;   
        exception
          when no_data_found then
               --cuento los remitos no encontrados
               v_cError:= v_cError + 1;               
        end; 
        end loop; 
     end if;
     
     if p_TipoTarea = c_TareaConsolidadoComi then
        --recorro todos los remitos del idcomisionista
        for comi in
                 (select r.idremito
                    from tblslvtarea          ta,
                         tblslvremito         r
                   where ta.idtarea = r.idtarea               
                     and ta.idconsolidadocomi = p_idconsolidado)
      loop
        --cuento los remitos
        v_cRemito:=v_cRemito+1;
        begin
          select cr.cdestado
            into v_estado 
            from tblslvcontrolremito  cr
           where cr.idremito = comi.idremito;
           --cuento los remitos controlados
          if v_estado = C_Controlado then
             v_cControl:=v_cControl+1;
          end if;   
        exception
          when no_data_found then
                --cuento los remitos no encontrados
               v_cError:= v_cError + 1;               
        end; 
        end loop; 
      end if;  
     --verifica si todos los remitos están controlados
     if v_cRemito = v_cControl and v_cRemito<>0 then          
       return 'Controlado';
    end if; 
    --verifica si todos los remitos no están en tblslvcontrolremito
    if v_cRemito = v_cError and v_cRemito<>0 then          
       return 'No Controlado';
    end if; 
    --si tiene remitos sin controlar
    if v_cRemito <>0 then          
       return 'Control Parcial';
    else
      return 'Sin Remito';   
    end if; 
  END EstadoPedidoControl;
  
 /****************************************************************************************************
  * %v 14/07/2020 - ChM  Versión inicial GetDetalleControl
  * %v 14/07/2020 - ChM  Obtener los remitos de un consolidado
  ****************************************************************************************************/
  PROCEDURE GetDetalleControl(p_idcomi         IN  tblslvconsolidadopedido.idconsolidadocomi%type,
                              p_idpedido       IN  tblslvconsolidadopedido.idconsolidadopedido%type,
                              p_Cabezera       OUT Varchar,
                              p_Cursor         OUT CURSOR_TYPE) IS
                              
  BEGIN
     
    if  p_idpedido <> 0 then
      p_Cabezera:= 'Pedido de Reparto '||to_char(p_idpedido);
       --recorro todos los remitos del idpedido
       OPEN p_Cursor FOR
          select A.idremito,
                 A.nrocarreta,
                 A.estado,
                 A.Armador,
                 --nombre del controlador
                 nvl2(A.idpersonacontrol,
                      (select nvl(upper(p.dsnombre) || ' ' || upper(p.dsapellido),'-') nom
                         from personas p
                       where p.idpersona = A.idpersonacontrol
                         and rownum=1) ,'-') personacontrol,
                 PKG_SLV_CONTROL.ErroresControl(A.idremito) errores                           
            from (select r.idremito,
                         r.nrocarreta,
                         --etiqueta el estado
                         nvl2(cr.cdestado,decode(cr.cdestado,C_Controlado,'Controlado','En Curso'),'No Controlado') estado,
                         upper(pe.dsnombre) || ' ' || upper(pe.dsapellido) Armador,
                         cr.idpersonacontrol                                                                         
                    from tblslvtarea          ta,
                         personas             pe,
                         tblslvremito         r
               left join tblslvcontrolremito  cr on
                         (r.idremito = cr.idremito)
                   where ta.idtarea = r.idtarea  
                     and ta.idpersonaarmador = pe.idpersona             
                     and ta.idconsolidadopedido = p_idpedido
               union all    
                  select r.idremito,
                         r.nrocarreta,
                         --etiqueta el estado
                         nvl2(cr.cdestado,decode(cr.cdestado,C_Controlado,'Controlado','En Curso'),'No Controlado') estado,
                         'DISTRIBUCIÓN DE FALTANTE'  Armador,
                         cr.idpersonacontrol                           
                    from tblslvremito         r
               left join tblslvcontrolremito  cr on
                         (r.idremito = cr.idremito),
                         tblslvpedfaltanterel      pfrel,                        
                         tblslvconsolidadopedido   cp
                   where r.idpedfaltanterel = pfrel.idpedfaltanterel
                     and cp.idconsolidadopedido =  pfrel.idconsolidadopedido
                     and cp.idconsolidadopedido = p_idpedido) A;
    end if;
    if  p_idcomi  <> 0 then
      p_Cabezera:= 'Pedido de Comisionista '||to_char(p_idcomi);
       --recorro todos los remitos del idpedido
       OPEN p_Cursor FOR
          select A.idremito,
                 A.nrocarreta,
                 A.estado,
                 A.Armador,
                 --nombre del controlador
                 nvl2(A.idpersonacontrol,
                      (select nvl(upper(p.dsnombre) || ' ' || upper(p.dsapellido),'-') nom
                         from personas p
                       where p.idpersona = A.idpersonacontrol
                         and rownum=1) ,'-') personacontrol,
                 PKG_SLV_CONTROL.ErroresControl(A.idremito) errores       
            from (select r.idremito,
                         r.nrocarreta,
                         --etiqueta el estado
                         nvl2(cr.cdestado,decode(cr.cdestado,C_Controlado,'Controlado','En Curso'),'No Controlado') estado,
                         upper(pe.dsnombre) || ' ' || upper(pe.dsapellido) Armador,
                         cr.idpersonacontrol                                                                         
                    from tblslvtarea          ta,
                         personas             pe,
                         tblslvremito         r
               left join tblslvcontrolremito  cr on
                         (r.idremito = cr.idremito)
                   where ta.idtarea = r.idtarea  
                     and ta.idpersonaarmador = pe.idpersona             
                     and ta.idconsolidadocomi = p_idcomi) A;
    end if;
     
  END GetDetalleControl; 
 /****************************************************************************************************
  * %v 14/07/2020 - ChM  Versión inicial ErroresControl
  * %v 14/07/2020 - ChM  verifica si el remito se controló con errores
  *****************************************************************************************************/
  FUNCTION ErroresControl  (p_idremito           IN  tblslvremito.idremito%type)
                           RETURN VARCHAR2 IS
                           
    v_idControl        tblslvcontrolremito.idcontrolremito%type;    
    v_band             integer:=-1;                                                   
  BEGIN
    --valida si existe el p_idControl en tblslvcontrolremito 
       begin        
            select cr.idcontrolremito                                     
              into v_idControl                                   
              from tblslvcontrolremito cr
             where cr.idremito = p_idremito; 
            --cuento los que tengan diferencias              
            select count (*)
              into v_band
              from tblslvcontrolremitodet    crd
             where crd.idcontrolremito = v_idControl
               and (crd.qtdiferenciaunidadmbase <> 0 or crd.qtdiferenciapiezas <> 0); 
            if v_band = 0 then
              return 'NO';
            else
              return 'SI'; 
            end if;     
       exception                  
          when no_data_found then
               return '-';
       end;
       
  END ErroresControl;
  
  /****************************************************************************************************
  * %v 15/07/2020 - ChM  Versión inicial GetArticulosControl
  * %v 15/07/2020 - ChM  Obtener los articulos que componen un control de remito
  ****************************************************************************************************/
  PROCEDURE GetArticulosControl(p_idcomi         IN  tblslvconsolidadopedido.idconsolidadocomi%type,
                                p_idpedido       IN  tblslvconsolidadopedido.idconsolidadopedido%type,
                                p_CursorCab      OUT CURSOR_TYPE,
                                p_Cursor         OUT CURSOR_TYPE) IS                           
  BEGIN     
    if  p_idpedido <> 0 then
      --cabezera del reporte
      OPEN p_CursorCAB FOR   
                    select cp.idconsolidadopedido idconsolidado,
                           cp.dtinsert,                           
                           TRIM(NVL (e.dsrazonsocial, e.dsnombrefantasia))||' ('||TRIM(e.cdcuit)||')' cliente
                      from tblslvconsolidadopedido cp,
                           entidades               e
                     where cp.identidad = e.identidad
                       and cp.idconsolidadopedido = p_idpedido;   
       --recorro todos los remitos del idpedido
       OPEN p_Cursor FOR
          select A.cdarticulo||' - '||des.vldescripcion Articulo,
                 PKG_SLV_Articulo.SetFormatoArticuloscod(A.cdarticulo,
                 --valida pesables
                 decode(nvl(A.qtdiferenciapiezas,0),0,
                 (nvl(A.qtdiferenciaunidadmbase,0)),
                 nvl(A.qtdiferenciapiezas,0))) Cantidad,
                 A.idremito,
                 A.Armador,
                 A.personacontrol,
                 case
                 when A.qtdiferenciapiezas > 0 then 'Sobrante'
                 when A.qtdiferenciapiezas < 0 then 'Faltante'  
                 when A.qtdiferenciaunidadmbase > 0 then 'Sobrante'    
                 when A.qtdiferenciaunidadmbase < 0 then 'Faltante'      
                 end observacion,
                 case
                 when A.qtdiferenciapiezas > 0 then 'Sacar de Carreta'
                 when A.qtdiferenciapiezas < 0 then 'Realizar NC'  
                 when A.qtdiferenciaunidadmbase > 0 then 'Sacar de Carreta'    
                 when A.qtdiferenciaunidadmbase < 0 then 'Realizar NC'      
                 end Accion,
                 case
                 when A.qtdiferenciapiezas > 0 then '-'
                 when A.qtdiferenciapiezas < 0 then 
                   GetFacturas(p_idpedido,c_TareaConsolidadoPedido,A.cdarticulo)  
                 when A.qtdiferenciaunidadmbase > 0 then '-'    
                 when A.qtdiferenciaunidadmbase < 0 then 
                   GetFacturas(p_idpedido,c_TareaConsolidadoPedido,A.cdarticulo)      
                 end  Facturas
            from (select crd.cdarticulo,
                         crd.qtdiferenciaunidadmbase,
                         crd.qtdiferenciapiezas, 
                         r.idremito,                                               
                         upper(pe.dsnombre) || ' ' || upper(pe.dsapellido) Armador,
                         upper(pe2.dsnombre) || ' ' || upper(pe2.dsapellido) personacontrol                                                                                                  
                    from tblslvtarea              ta,
                         personas                 pe,
                         personas                 pe2,
                         tblslvremito             r,                        
                         tblslvcontrolremito      cr,
                         tblslvcontrolremitodet   crd                         
                   where ta.idtarea = r.idtarea
                     and r.idremito = cr.idremito  
                     and cr.idcontrolremito = crd.idcontrolremito
                     and ta.idpersonaarmador = pe.idpersona
                     and cr.idpersonacontrol = pe2.idpersona                    
                     --solo muestra los artículos con diferencias
                     and (crd.qtdiferenciaunidadmbase <> 0 or crd.qtdiferenciapiezas <> 0)            
                     and ta.idconsolidadopedido = p_idpedido
               union all       
                  select crd.cdarticulo,
                         crd.qtdiferenciaunidadmbase,
                         crd.qtdiferenciapiezas, 
                         r.idremito,                                               
                         'DISTRIBUCIÓN DE FALTANTE' Armador,
                         upper(pe.dsnombre) || ' ' || upper(pe.dsapellido) personacontrol                                                                                                  
                    from personas                 pe,
                         tblslvremito             r,                        
                         tblslvcontrolremito      cr,
                         tblslvpedfaltanterel     pfrel,                        
                         tblslvconsolidadopedido  cp,
                         tblslvcontrolremitodet   crd                         
                   where r.idpedfaltanterel = pfrel.idpedfaltanterel
                     and pfrel.idconsolidadopedido = cp.idconsolidadopedido
                     and r.idremito = cr.idremito  
                     and cr.idcontrolremito = crd.idcontrolremito                    
                     and cr.idpersonacontrol = pe.idpersona                    
                     --solo muestra los artículos con diferencias
                     and (crd.qtdiferenciaunidadmbase <> 0 or crd.qtdiferenciapiezas <> 0)            
                     and cp.idconsolidadopedido = p_idpedido) A,
                descripcionesarticulos        des   
          where A.cdarticulo = des.cdarticulo
          order by accion;
    end if;
    
    if  p_idcomi  <> 0 then
      --cabezera del reporte
       OPEN p_CursorCAB FOR   
          select cc.idconsolidadocomi idconsolidado,
                 cc.dtinsert,
                 TRIM(NVL (e.dsrazonsocial, e.dsnombrefantasia))||' ('||TRIM(e.cdcuit)||')' cliente
            from tblslvconsolidadocomi cc,
                 entidades               e
           where cc.idcomisionista = e.identidad
             and cc.idconsolidadocomi = p_idComi;
       --recorro todos los remitos del idcomi
       OPEN p_Cursor FOR
          select A.cdarticulo||' - '||des.vldescripcion Articulo,
                 PKG_SLV_Articulo.SetFormatoArticuloscod(A.cdarticulo,
                 --valida pesables
                 decode(nvl(A.qtdiferenciapiezas,0),0,
                 (nvl(A.qtdiferenciaunidadmbase,0)),
                 nvl(A.qtdiferenciapiezas,0))) Cantidad,
                 A.idremito,
                 A.Armador,
                 A.personacontrol,
                 case
                 when A.qtdiferenciapiezas > 0 then 'Sobrante'
                 when A.qtdiferenciapiezas < 0 then 'Faltante'  
                 when A.qtdiferenciaunidadmbase > 0 then 'Sobrante'    
                 when A.qtdiferenciaunidadmbase < 0 then 'Faltante'      
                 end observacion,
                 case
                 when A.qtdiferenciapiezas > 0 then 'Sacar de Carreta'
                 when A.qtdiferenciapiezas < 0 then 'Realizar NC'  
                 when A.qtdiferenciaunidadmbase > 0 then 'Sacar de Carreta'    
                 when A.qtdiferenciaunidadmbase < 0 then 'Realizar NC'      
                 end Accion,                 
                 case
                 when A.qtdiferenciapiezas > 0 then '-'
                 when A.qtdiferenciapiezas < 0 then 
                   GetFacturas(p_idcomi,c_TareaConsolidadoComi,A.cdarticulo)  
                 when A.qtdiferenciaunidadmbase > 0 then '-'    
                 when A.qtdiferenciaunidadmbase < 0 then 
                   GetFacturas(p_idcomi,c_TareaConsolidadoComi,A.cdarticulo)      
                 end  Facturas
            from (select crd.cdarticulo,
                         crd.qtdiferenciaunidadmbase,
                         crd.qtdiferenciapiezas, 
                         r.idremito,                                               
                         upper(pe.dsnombre) || ' ' || upper(pe.dsapellido) Armador,
                         upper(pe2.dsnombre) || ' ' || upper(pe2.dsapellido) personacontrol                                                                                                  
                    from tblslvtarea              ta,
                         personas                 pe,
                         personas                 pe2,
                         tblslvremito             r,                        
                         tblslvcontrolremito      cr,
                         tblslvcontrolremitodet   crd                         
                   where ta.idtarea = r.idtarea
                     and r.idremito = cr.idremito  
                     and cr.idcontrolremito = crd.idcontrolremito
                     and ta.idpersonaarmador = pe.idpersona
                     and cr.idpersonacontrol = pe2.idpersona                    
                     --solo muestra los artículos con diferencias
                     and (crd.qtdiferenciaunidadmbase <> 0 or crd.qtdiferenciapiezas <> 0)            
                     and ta.idconsolidadocomi = p_idcomi) A,
                descripcionesarticulos        des   
          where A.cdarticulo = des.cdarticulo
          order by accion;
    end if;
     
  END GetArticulosControl; 
  
  /****************************************************************************************************
  * %v 15/07/2020 - ChM  Versión inicial GetFacturas
  * %v 15/07/2020 - ChM  devuelve los comprobantes que incluyen un articulo de un idpedido
  *****************************************************************************************************/
  FUNCTION GetFacturas  (p_IdConsolidado        tblslvconsolidadopedido.idconsolidadocomi%type,
                         p_TipoTarea            tblslvtipotarea.cdtipo%type,
                         p_cdarticulo           articulos.cdarticulo%type)
                         RETURN VARCHAR2 IS
  v_facturas             varchar2(2000);                                                                   
  BEGIN
     if  p_TipoTarea = c_TareaConsolidadoPedido then
       --recorro todos los remitos del idpedido
       select LISTAGG(factura, '$ ')
                   WITHIN GROUP (ORDER BY factura) 
         into v_facturas          
         from (select 
      distinct do.cdcomprobante,
               do.cdpuntoventa,
               do.sqcomprobante,
               trim(do.cdcomprobante)||' '||trim(do.cdpuntoventa)||' '||to_char(do.sqcomprobante) factura
          from tblslvconsolidadopedido     cp,
               tblslvconsolidadopedidorel  cprel,
               pedidos                     pe,
               detallepedidos              dp,
               movmateriales               mm,
               documentos                  do
         where cp.idconsolidadopedido = cprel.idconsolidadopedido
           and cprel.idpedido = pe.idpedido
           and pe.idpedido = mm.idpedido
           and pe.idpedido = dp.idpedido
           and mm.idmovmateriales = do.idmovmateriales
           and dp.cdarticulo = p_cdarticulo
           and cp.idconsolidadopedido = p_idconsolidado
      ) A;
      end if; 
     if  p_TipoTarea = c_TareaConsolidadoComi then
       --recorro todos los remitos del idpedido
       select LISTAGG(factura, '$ ')
                   WITHIN GROUP (ORDER BY factura) 
         into v_facturas          
         from (select 
      distinct do.cdcomprobante,
               do.cdpuntoventa,
               do.sqcomprobante,
               trim(do.cdcomprobante)||' '||trim(do.cdpuntoventa)||' '||to_char(do.sqcomprobante) factura
          from tblslvconsolidadopedido     cp,
               tblslvconsolidadopedidorel  cprel,
               pedidos                     pe,
               detallepedidos              dp,
               movmateriales               mm,
               documentos                  do
         where cp.idconsolidadopedido = cprel.idconsolidadopedido
           and cprel.idpedido = pe.idpedido
           and pe.idpedido = mm.idpedido
           and pe.idpedido = dp.idpedido
           and mm.idmovmateriales = do.idmovmateriales
           and dp.cdarticulo = p_cdarticulo
           and cp.idconsolidadocomi = p_idconsolidado
      ) A;
      end if;
     if v_facturas is null then
        return 'Por Facturar';  
     else    
       return v_facturas;
     end if;  
  exception                  
    when others then
         return 'Por Facturar';     
  END GetFacturas;
  
  
end PKG_SLV_CONTROL;
/
