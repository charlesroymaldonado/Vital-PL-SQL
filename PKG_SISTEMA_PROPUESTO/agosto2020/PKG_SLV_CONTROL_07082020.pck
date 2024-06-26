CREATE OR REPLACE PACKAGE PKG_SLV_CONTROL is
  /**********************************************************************************************************
  * Author  : CHARLES MALDONADO
  * Created : 01/07/2020 03:45:03 p.m.
  * %v Paquete para gesti�n y control de REMITOS SLV
  **********************************************************************************************************/
  -- Tipos de datos

  TYPE CURSOR_TYPE IS REF CURSOR;
  
  
  -- para uso publico del paquete
  
  PROCEDURE GetControl(p_idremito           IN  tblslvremito.idremito%type,
                       p_idpersona          IN  personas.idpersona%type, 
                       p_qtcontrol           OUT tblslvcontrolremito.qtcontrol%type,                     
                       p_Ok                 OUT number,
                       p_error              OUT varchar2);
                       
  PROCEDURE SetControl(p_idremito           IN  tblslvremito.idremito%type,                        
                       p_cdBarras           IN  barras.cdeancode%type,                       
                       p_qtunidad           IN  tblslvremitodet.qtunidadmedidabasepicking%type,
                       p_recontar           OUT integer,
                       p_Cursor             OUT CURSOR_TYPE,
                       p_Ok                 OUT number,
                       p_error              OUT varchar2);  
                       
   PROCEDURE GetReConteo(p_idremito           IN  tblslvremito.idremito%type, 
                         p_idConteo           OUT tblslvconteo.idconteo%type,  
                         p_Cursor             OUT CURSOR_TYPE,                                                          
                         p_Ok                 OUT number,
                         p_error              OUT varchar2);

   PROCEDURE SetReConteoDet(p_idremito           IN  tblslvremito.idremito%type, 
                            p_idConteo           IN  tblslvconteo.idconteo%type, 
                            p_cdBarras           IN  barras.cdeancode%type,
                            p_cdArticulo         IN  articulos.cdarticulo%type,                                      
                            p_qtunidad           IN  tblslvremitodet.qtunidadmedidabasepicking%type,
                            p_Cursor             OUT CURSOR_TYPE,                                                        
                            p_Ok                 OUT number,
                            p_error              OUT varchar2);  
                            
   PROCEDURE SetVerificaConteo(p_idConteo           IN  tblslvconteo.idconteo%type, 
                               p_idNuevoConteo      OUT tblslvconteo.idconteo%type,
                               p_ajustar            OUT integer,                                                
                               p_Ok                 OUT number,
                               p_error              OUT varchar2);                             
                            
  PROCEDURE GetErroresControl(p_idremito           IN  tblslvremito.idremito%type,
                              p_cursor             OUT CURSOR_TYPE,                  
                              p_Ok                 OUT number,
                              p_error              OUT varchar2);  
                              
  PROCEDURE SetErroresControl(p_idremito           IN  tblslvremito.idremito%type,                        
                              p_cdBarras           IN  barras.cdeancode%type, 
                              p_cdArticulo         IN  articulos.cdarticulo%type,                      
                              p_qtunidad           IN  tblslvremitodet.qtunidadmedidabasepicking%type,
                              p_Faltante_sobrante  IN  varchar, 
                              p_Cursor             OUT CURSOR_TYPE,
                              p_Ok                 OUT number,
                              p_error              OUT varchar2);                                                                                                                          
                                
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
                                                             
                                
  PROCEDURE DetalleRemito(p_idremito        IN  tblslvremito.idremito%type,
                          p_TipoTarea       IN  Tblslvtipotarea.cdtipo%type,
                          p_DsSucursal      OUT sucursales.dssucursal%type,                  
                          p_CursorCab       OUT CURSOR_TYPE,                                            
                          p_Cursor          OUT CURSOR_TYPE);                             
                              
  --PARA USO INTERNO DEL PAQUETE
  FUNCTION ContarArticulos(p_Idcontrol        tblslvcontrolremito.idcontrolremito%type,
                           p_cdarticulo       articulos.cdarticulo%type,
                           p_marcapesable     integer) 
                           RETURN integer;                               
  
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
  C_ControladoConError               CONSTANT tblslvestado.cdestado%type := 45; 
  c_TareaConsolidadoPedido           CONSTANT tblslvtipotarea.cdtipo%type := 25;
  c_TareaConsolidadoComi             CONSTANT tblslvtipotarea.cdtipo%type := 50;
  
  PROCEDURE ControlarRemito(p_idremito           IN  tblslvremito.idremito%type,
                            p_Ok                 OUT number,
                            p_error              OUT varchar2,
                            p_cursor             OUT CURSOR_TYPE); 
  
  /****************************************************************************************************
  * %v 27/07/2020 - ChM  Versi�n inicial InsertConteo
  * %v 27/07/2020 - ChM  inserta la tabla conteo
  *****************************************************************************************************/
   FUNCTION InsertConteo(p_IdControlRemito      tblslvcontrolremito.idcontrolremito%type,
                         p_qtveces              tblslvconteo.qtveces%type)
                         RETURN integer IS
                         
    v_modulo           varchar2(100) := 'PKG_SLV_CONTROL.InsertConteo';
                                                                   
   BEGIN
    insert into tblslvconteo
                (idconteo,
                 idcontrolremito,
                 qtveces,
                 dtinicio,
                 dtfin,
                 cdsucursal)
         values (seq_conteo.nextval,         
                 p_IdControlRemito,
                 p_qtveces,
                 sysdate,
                 null,
                 g_cdSucursal);
         
   IF SQL%ROWCOUNT = 0 THEN
              n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       ' Error: ' || SQLERRM);     
              ROLLBACK;
              RETURN 0;
            END IF; 
   return seq_conteo.currval;             
  exception                  
    when others then
          n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       ' Error: ' || SQLERRM);
              ROLLBACK;
              RETURN 0; 
  END InsertConteo;
   /****************************************************************************************************
  * %v 27/07/2020 - ChM  Versi�n inicial FinalizaConteo
  * %v 27/07/2020 - ChM  Actualiza la fecha fin de conteo controlado
  *****************************************************************************************************/
   FUNCTION FinalizaConteo(p_Idconteo      tblslvconteo.idconteo%type)
                         RETURN integer IS
                         
    v_modulo           varchar2(100) := 'PKG_SLV_CONTROL.FinalizaConteo';
                                                                   
   BEGIN
    update tblslvconteo co
       set co.dtfin=sysdate
     where co.idconteo=p_Idconteo;         
   IF SQL%ROWCOUNT = 0 THEN
              n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       ' Error: ' || SQLERRM);       
              ROLLBACK;
              RETURN 0;
            END IF; 
   return 1;             
  exception                  
    when others then
          n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       ' Error: ' || SQLERRM);      
    ROLLBACK;
    RETURN 0; 
  END FinalizaConteo;
  
  /****************************************************************************************************
  * %v 29/07/2020 - ChM  Versi�n inicial FinalizaConteoDet
  * %v 29/07/2020 - ChM  Actualiza el estado a finalizado de un cdarticulo de conteo
  *****************************************************************************************************/
   FUNCTION FinalizaConteoDet(p_Idconteo      tblslvconteo.idconteo%type,
                              p_cdArticulo    articulos.cdarticulo%type)
                         RETURN integer IS
                         
    v_modulo           varchar2(100) := 'PKG_SLV_CONTROL.FinalizaConteoDet';
                                                                   
   BEGIN
        update tblslvconteodet cd
           set cd.icfinalizado = 1,
               cd.qtunidadmedidabasepicking= nvl(cd.qtunidadmedidabasepicking,0),
               cd.qtpiezaspicking = nvl(cd.qtpiezaspicking,0),
               cd.dtupdate = sysdate
         where cd.idconteo = p_idConteo  
           and cd.cdarticulo = p_cdArticulo;
        IF SQL%ROWCOUNT = 0 THEN
            n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       ' Error: ' || SQLERRM);
           ROLLBACK;
           RETURN 0;
        END IF;    
   return 1;             
  exception                  
    when others then
          n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       ' Error: ' || SQLERRM);  
    ROLLBACK;
    RETURN 0; 
  END FinalizaConteoDet;
  
  /****************************************************************************************************
  * %v 27/07/2020 - ChM  Versi�n inicial InsertConteoDet
  * %v 27/07/2020 - ChM  inserta la tabla conteoDet
  *****************************************************************************************************/
   FUNCTION InsertConteoDet(p_IdConteo             tblslvconteodet.idconteo%type,
                            p_cdarticulo           tblslvconteodet.cdarticulo%type,
                            p_qtbase               tblslvconteodet.qtunidadmedidabasepicking%type,
                            p_qtpiezas             tblslvconteodet.qtpiezaspicking%type)
                         RETURN integer IS
                         
    v_modulo           varchar2(100) := 'PKG_SLV_CONTROL.InsertConteoDet';
                                                                   
   BEGIN
    insert into tblslvconteoDet
                (idconteodet,
                 idconteo,
                 cdarticulo,
                 Qtunidadmedidabasepicking,
                 Qtpiezaspicking,
                 Dtinsert,
                 Dtupdate,
                 Cdsucursal)
         values (seq_conteodet.nextval,       
                 p_IdConteo,
                 p_cdarticulo,
                 p_qtbase,
                 p_qtpiezas,
                 sysdate,
                 null,
                 g_cdSucursal);
         
   IF SQL%ROWCOUNT = 0 THEN
              n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       ' Error: ' || SQLERRM);
              ROLLBACK;
              RETURN 0;
            END IF; 
   return seq_conteodet.currval;             
  exception                  
    when others then
          n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       ' Error: ' || SQLERRM);  
              ROLLBACK;
              RETURN 0; 
  END InsertConteoDet;
  
  /****************************************************************************************************
  * %v 27/07/2020 - ChM  Versi�n inicial UpdateConteoDet
  * %v 27/07/2020 - ChM  inserta la tabla conteoDet
  *****************************************************************************************************/
   FUNCTION UpdateConteoDet(p_IdConteo             tblslvconteodet.idconteo%type,
                            p_cdarticulo           tblslvconteodet.cdarticulo%type,
                            p_qtbase               tblslvconteodet.qtunidadmedidabasepicking%type,
                            p_qtpiezas             tblslvconteodet.qtpiezaspicking%type)
                         RETURN integer IS
                         
    v_modulo           varchar2(100) := 'PKG_SLV_CONTROL.InsertConteoDet';
                                                                   
   BEGIN
    update tblslvconteoDet cod
       set cod.qtunidadmedidabasepicking=nvl(cod.qtunidadmedidabasepicking,0)+p_qtbase,
           cod.qtpiezaspicking=nvl(cod.qtpiezaspicking,0)+p_qtpiezas,
           cod.dtupdate=sysdate
     where cod.idconteo = p_IdConteo
       and cod.cdarticulo =p_cdarticulo;
         
   IF SQL%ROWCOUNT = 0 THEN
              n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       ' Error: ' || SQLERRM);
              ROLLBACK;
              RETURN 0;
            END IF; 
   return 1;             
  exception                  
    when others then
          n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       ' Error: ' || SQLERRM);   
              ROLLBACK;
              RETURN 0; 
  END UpdateConteoDet;
  
  /****************************************************************************************************
  * %v 03/07/2020 - ChM  Versi�n inicial GetControl
  * %v 03/07/2020 - ChM  recibe un idremito para iniciar su control                      
  *****************************************************************************************************/
  
  PROCEDURE GetControl(p_idremito           IN  tblslvremito.idremito%type,
                       p_idpersona          IN  personas.idpersona%type, 
                       p_qtcontrol          OUT tblslvcontrolremito.qtcontrol%type,                     
                       p_Ok                 OUT number,
                       p_error              OUT varchar2) IS
                       
    v_modulo           varchar2(100) := 'PKG_SLV_CONTROL.GetControl';
    v_estado           tblslvremito.cdestado%type:=null;
    v_error            varchar2(250);  
    v_idremito         tblslvremito.idremito%type:=0;   
    v_idControl        tblslvcontrolremito.idcontrolremito%type;
    v_idconteo         tblslvconteo.idconteo%type;
    
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
    --los remito de distribuci�n se controlan
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
                   cr.cdestado,
                   cr.qtcontrol                   
              into v_idControl,
                   v_estado,
                   p_qtcontrol                   
              from tblslvcontrolremito cr
             where cr.idremito = p_idremito; 
           exception        
             -- si no existe lo crea    
           when no_data_found then
             p_qtcontrol:=1; 
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
                     p_qtcontrol,
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
            --creo el conteo inicial
            v_idconteo:=InsertConteo(v_idControl,1); 
            if v_idconteo = 0 then
              p_Ok    := 0;
              p_error:='Error. Comuniquese con Sistemas!';
              ROLLBACK;
              RETURN;
             end if;             
         end;
     --verifica si esta Controlado
    if v_estado in (C_Controlado, C_ControladoConError) then
       p_Ok    := 0;
       p_error := 'Remito '||to_char(p_idremito)||' ya Controlado.';
       RETURN;
    end if;      
    p_Ok    := 1;
    p_error := '';
    commit;   
    EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       ' Error: ' || SQLERRM);
      p_Ok    := 0;
      p_error:='Error Control Remito. Comuniquese con Sistemas!';
      ROLLBACK;
      RETURN;
  END GetControl;
  
  /****************************************************************************************************
  * %v 01/07/2020 - ChM  Versi�n inicial SetControl
  * %v 01/07/2020 - ChM  recibe un idremito para inserta en control y conteo los art�culos
                         segun codigo de barras y cantidad
  *****************************************************************************************************/
  PROCEDURE SetControl(p_idremito           IN  tblslvremito.idremito%type,                        
                       p_cdBarras           IN  barras.cdeancode%type,                       
                       p_qtunidad           IN  tblslvremitodet.qtunidadmedidabasepicking%type,
                       p_recontar           OUT integer,
                       p_Cursor             OUT CURSOR_TYPE,
                       p_Ok                 OUT number,
                       p_error              OUT varchar2  
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
    v_idConteo         tblslvconteo.idconteo%type;
    v_qtveces          tblslvconteo.qtveces%type;
    v_idconteoDet      tblslvconteodet.idconteodet%type;
    v_cdunidadVentamin articulos.cdunidadventaminima%type;
 
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
              p_Ok    := 0;
              p_error := 'Control para el remito '||to_char(p_idremito)||' no existe.';
              return;
       end;
       
       --valida si existe el conteo inicial 
       begin        
            select co.idconteo,
                   co.qtveces
              into v_idConteo,
                   v_qtveces
              from tblslvconteo co
             where co.idcontrolremito = v_idControl
               and co.qtveces = 1;
       exception                  
          when no_data_found then
              p_Ok    := 0;
              p_error := 'Conteo para el remito '||to_char(p_idremito)||' no existe.';
              return;
       end;
       
      --verifica si esta Controlado
      if v_estado in (C_Controlado, C_ControladoConError) then
         p_Ok    := 0;
         p_error := 'Remito '||to_char(p_idremito)||' ya Controlado.';
         RETURN;
      end if;  
      
      p_recontar:=0;
      --si desea finalizar (F) primera llamada a SetControlarRemito 
      if p_cdBarras ='F' then        
          PKG_SLV_CONTROL.ControlarRemito(p_idremito,p_Ok,p_error,p_cursor); 
          if p_ok = -1 then
            p_recontar:=1;
            p_ok:=1;
            p_error:= '';
          end if;  
          return;        
      end if;
            
      --busca el cdarticulo del p_cdBarras
      pkg_slv_articulo.GetcdArticuloxBarras(p_cdBarras,v_cdArticulo,v_cdunidad,v_cantidad);      
      if v_cdarticulo = '-' then
          p_Ok    := 0;
          p_error := 'Codigo de barras no valido';
          return;
      end if;
              
     --valida unidad de venta minima indivisibles
        v_cdunidadVentamin:=pkg_slv_articulo.GetUnidadVentaMinimaArt(v_cdArticulo);     
     if trim(v_cdunidadVentamin) <> trim(v_cdunidad) and trim(v_cdunidadVentamin)<>'-' then
        p_Ok:=0;
        p_error:='La unidad m�nima de venta es '||v_cdunidadVentamin||' Ingreso '||v_cdunidad;
        rollback;
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
     
    --valido si no es el primer control del remito 
    if  v_qtcontrol <> 1 then
        p_Ok    := 0;
        p_error:='Procedimiento solo para primer control.'; 
      return;   
     end if;  
     
      --verifica si existe el detalle de control remito
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
                 p_Ok    := 0;
                 p_error:='Error al actualizar Art�culo';
                 ROLLBACK;
                 RETURN;
             END IF;
       --Actualiza en conteo detalle
       v_idconteoDet:=UpdateConteoDet(v_idConteo,v_cdarticulo,v_qtbase,v_qtpiezas);   
           if v_idconteoDet = 0 then
              p_Ok    := 0;
              p_error:='Error. Comuniquese con Sistemas!';             
              RETURN;
             end if;                 
                                
       exception        
       -- si no existe el detalle de control remito lo crea    
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
                     p_Ok    := 0;
                     p_error:='Error al insertar Art�culo';
                     ROLLBACK;
                     RETURN;
                 END IF; 
           --inserto en conteo detalle
           v_idconteoDet:=InsertConteoDet(v_idConteo,v_cdarticulo,v_qtbase,v_qtpiezas);   
           if v_idconteoDet = 0 then
              p_Ok    := 0;
              p_error:='Error. Comuniquese con Sistemas!';             
              RETURN;
             end if;             
      end; 
     open p_Cursor for           
           select A.cdarticulo,
                  A.cdarticulo||' - '||des.vldescripcion Articulo,
                  A.Cantidad
             from (select crd.cdarticulo,
                          PKG_SLV_Articulo.SetFormatoArticuloscod(crd.cdarticulo,
                          --valida pesables
                          decode(sum(nvl(crd.qtpiezaspicking,0)),0,
                          sum(nvl(crd.qtunidadmedidabasepicking,0)),
                          sum(nvl(crd.qtpiezaspicking,0)))) Cantidad                     
                     from tblslvcontrolremitodet            crd                          
                    where crd.idcontrolremito = v_idControl             
                      --solo muestro las piqueadas por primera vez
                      and (crd.qtdiferenciaunidadmbase = 0 or crd.qtdiferenciapiezas = 0)
                     -- filtra por el articulo piquiado
                      and crd.cdarticulo = v_cdarticulo
                 group by crd.cdarticulo
                   )A,
                    descripcionesarticulos des
              where A.cdarticulo = des.cdarticulo;
  p_Ok    := 1;
  p_error:=null; 
  commit;
  EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       ' Error: ' || SQLERRM);
      p_Ok    := 0;
      p_error:='Error Control Remito. Comuniquese con Sistemas!';
      ROLLBACK;
      RETURN;      
  END SetControl;
   /****************************************************************************************************
  * %v 27/07/2020 - ChM  Versi�n inicial GetReConteo
  * %v 27/07/2020 - ChM  recibe un idremito para recontar diferencias
  *****************************************************************************************************/
   PROCEDURE GetReConteo(p_idremito           IN  tblslvremito.idremito%type, 
                         p_idConteo           OUT tblslvconteo.idconteo%type,  
                         p_Cursor             OUT CURSOR_TYPE,                                                          
                         p_Ok                 OUT number,
                         p_error              OUT varchar2)
                           IS
                           
    v_modulo           varchar2(100) := 'PKG_SLV_CONTROL.GetReConteo';
    v_estado           tblslvremito.cdestado%type:=null;
    v_idControl        tblslvcontrolremito.idcontrolremito%type;
    v_qtcontrol        tblslvcontrolremito.qtcontrol%type;         
    v_idConteo         tblslvconteo.idconteo%type;
    v_qtveces          tblslvconteo.qtveces%type;                 
                           
   BEGIN
     --valida si existe el p_idremito en tblslvcontrolremito 
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
              p_Ok    := 0;
              p_error := 'Control para el remito '||to_char(p_idremito)||' no existe.';
              return;
       end;
       
       --valida si existe el conteo inicial 
       begin        
            select co.idconteo,
                   co.qtveces
              into v_idConteo,
                   v_qtveces
              from tblslvconteo co
             where co.idcontrolremito = v_idControl
               and co.qtveces = 1;
       exception                  
          when no_data_found then
              p_Ok    := 0;
              p_error := 'Conteo para el remito '||to_char(p_idremito)||' no existe.';
              return;
       end;
       
      --verifica si esta Controlado
      if v_estado in (C_Controlado, C_ControladoConError) then
         p_Ok    := 0;
         p_error := 'Remito '||to_char(p_idremito)||' ya Controlado.';
         RETURN;
      end if;  
       
      --inserto el nuevo conteo cabecera maxima +1 si es el primer conteo
      select max(co.qtveces)
        into v_qtveces
        from tblslvconteo co
       where co.idconteo = v_idConteo;
       if v_qtveces = 1 then
          p_idConteo := InsertConteo(v_idControl,v_qtveces+1); 
          if p_idConteo = 0 then
              p_Ok    := 0;
              p_error := 'Error. Comuniquese con sistemas.';
              ROLLBACK;        
              RETURN;
          end if;    
          --inserto los articulos con diferencia en el nuevo idconteo   
          for nuevoConteo in
            (select crd.cdarticulo                                              
               from tblslvcontrolremitodet            crd                          
              where crd.idcontrolremito = v_idControl             
                 --solo los art�culos con diferencias
                and (crd.qtdiferenciaunidadmbase <> 0 or crd.qtdiferenciapiezas <> 0))
           loop
             if InsertConteoDet(p_IdConteo,nuevoConteo.cdArticulo,null,null) = 0 then
                  p_Ok    := 0;
                  p_error := 'Error. Comuniquese con sistemas.';
                  ROLLBACK;        
                  RETURN;
              end if;    
           end loop;         
       else
         --sino recupero el idconteo en curso v_qtveces max
          select co.idconteo
            into p_idConteo
            from tblslvconteo co
           where co.idconteo = v_idConteo
             and co.qtveces = v_qtveces;
         end if;   
      if p_idConteo = 0 then              
         p_Ok    := 0;
         p_error := 'Error. Comuniquese con sistemas.';
         ROLLBACK;        
         RETURN;
       end if;             
       
    --carga el cursor con el primer articulo a recontar   
   open p_Cursor for 
           select cod.cdarticulo,
                  cod.cdarticulo||' - '||des.vldescripcion Articulo
             from tblslvconteodet        cod,
                  descripcionesarticulos des
            where cod.cdarticulo = des.cdarticulo
              and cod.idconteo = p_idConteo
             --and cod.cdarticulo = p_cdarticulo
              --valida articulos no finalizados
              and cod.icfinalizado = 0
           --  and rownum=1
           ;                    
   p_Ok    := 1;
   p_error := null;          
   COMMIT;    
   exception                  
    when others then
          n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       ' Error: ' || SQLERRM);
          p_Ok    := 0;
          p_error := 'Error. Comuniquese con sistemas.';           
          ROLLBACK;
          RETURN;       
   END GetReConteo;        
  
  /****************************************************************************************************
  * %v 27/07/2020 - ChM  Versi�n inicial SetReConteoDet
  * %v 27/07/2020 - ChM  recibe un idremito y idConteo y el primer art�culo a recontar
  *****************************************************************************************************/
   PROCEDURE SetReConteoDet(p_idremito           IN  tblslvremito.idremito%type, 
                            p_idConteo           IN  tblslvconteo.idconteo%type, 
                            p_cdBarras           IN  barras.cdeancode%type,
                            p_cdArticulo         IN  articulos.cdarticulo%type,                                      
                            p_qtunidad           IN  tblslvremitodet.qtunidadmedidabasepicking%type,
                            p_Cursor             OUT CURSOR_TYPE,                                                        
                            p_Ok                 OUT number,
                            p_error              OUT varchar2)
                           IS
                           
    v_modulo           varchar2(100) := 'PKG_SLV_CONTROL.SetReConteoDet';    
   -- v_error            varchar2(250); 
   
    v_estado           tblslvremito.cdestado%type:=null;
    v_diferencias      integer:=0;
    v_idControl        tblslvcontrolremito.idcontrolremito%type;
    v_qtcontrol        tblslvcontrolremito.qtcontrol%type;     
    v_qtbase           tblslvcontrolremitodet.qtunidadmedidabasepicking%type;
    v_qtpiezas         tblslvcontrolremitodet.qtpiezaspicking%type;
    v_cdunidad         barras.cdunidad%type;
    v_cantidad         tblslvtareadet.qtunidadmedidabase%type;
    V_UxB              number;
   -- v_cdarticulo       articulos.cdarticulo%type;    
    v_idConteo         tblslvconteo.idconteo%type;
    v_qtveces          tblslvconteo.qtveces%type;                 
    v_cdunidadVentamin articulos.cdunidadventaminima%type;
                           
   BEGIN
     --valida si existe el p_idremito en tblslvcontrolremito 
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
              p_Ok    := 0;
              p_error := 'Control para el remito '||to_char(p_idremito)||' no existe.';
              return;
       end;
       
       --valida si existe el conteo 
       begin        
            select co.idconteo,
                   co.qtveces
              into v_idConteo,
                   v_qtveces
              from tblslvconteo co
             where co.idcontrolremito = p_idConteo;                
       exception                  
          when no_data_found then
              p_Ok    := 0;
              p_error := 'Conteo para el remito '||to_char(p_idremito)||' no existe.';
              return;
       end;
       
      --verifica si esta Controlado
      if v_estado in (C_Controlado,C_ControladoConError) then
         p_Ok    := 0;
         p_error := 'Remito '||to_char(p_idremito)||' ya Controlado.';
         RETURN;
      end if;   
      
      --carga el cursor con el articulo a recontar   
      open p_Cursor for 
           select cod.cdarticulo,
                  cod.cdarticulo||' - '||des.vldescripcion Articulo
             from tblslvconteodet        cod,
                  descripcionesarticulos des
            where cod.cdarticulo = des.cdarticulo
              and cod.idconteo = p_idConteo             
              --valida articulos no finalizados
              and cod.icfinalizado = 0;
      
        --valida si el articulo ya esta finalizado
       begin 
         v_diferencias:=0;     
       select count(cod.cdarticulo) 
         into v_diferencias                    
         from tblslvconteodet  cod                     
        where cod.idconteo = p_idConteo                     
          --ultimo articulo ingresado
          and cod.cdarticulo = p_cdarticulo
          --marca de finalizado
          and cod.icfinalizado = 1;
       if v_diferencias <> 0 then 
           p_Ok    := 0;
           p_error := 'Art�culo Finalizado';
           ROLLBACK;        
           RETURN;  
        end if;    
       exception         
         when others then
          null; 
       end;  
      
       --si desea finalizar el renglon p_qtunidad = 0
      if p_qtunidad = 0 then
          if FinalizaConteoDet(p_idConteo,p_cdArticulo)=0 then
              p_Ok:=0;
              p_error:='Error. Comuniquese con sistemas.';
              rollback;
              return;
           else
             p_Ok    := 1;
             p_error := null;           
             commit;        
          end if; 
                 
      end if;
           
    --valida si p_qtunidad es mayor a cero y existe p_cdbarras
    if p_qtunidad>0 and p_cdBarras is not null then    
          --devuelve la unidad de medida del articulo segun codigo de barra         
          pkg_slv_articulo.GetValidaArticuloBarras(p_cdArticulo,p_cdBarras,v_cdunidad,v_cantidad); 
          
          if trim(v_cdunidad) = '-' then
              p_Ok:=0;
              p_error:='El Codigo de barra no corresponde al art�culo!';
              rollback;
              return;
          end if;     
      
         --valida unidad de venta minima indivisibles
         v_cdunidadVentamin:=pkg_slv_articulo.GetUnidadVentaMinimaArt(p_cdArticulo);     
         if trim(v_cdunidadVentamin) <> trim(v_cdunidad) and trim(v_cdunidadVentamin)<>'-' then
            p_Ok:=0;
            p_error:='La unidad m�nima de venta es '||v_cdunidadVentamin||' Ingreso '||v_cdunidad;
            rollback;
            return;
         end if;   
          
         v_qtbase:=p_qtunidad;
         v_qtpiezas:=0;
          --si es distinto de unidad o pesable se busca y multiplica por el UXB
         if v_cdunidad not in ('UN','KG','PZA') then
           V_UxB:=posapp.n_pkg_vitalpos_materiales.GetUxB(p_cdArticulo,v_cdunidad);
           v_qtbase:=p_qtunidad*V_UxB;
           v_qtpiezas:=0;
         end if;   
         --si es igual a KG o PZA pesable
         if v_cdunidad in ('KG','PZA') then
           v_qtpiezas:=p_qtunidad; 
           v_qtbase:=0;
         end if;           
     else
          v_qtpiezas:=0; 
          v_qtbase:=0;   
    end if;          
       --valida si el articulo es del grupo del remito con diferencias 
       begin 
       v_diferencias:=0;          
       select count(cod.cdarticulo) 
         into v_diferencias                    
         from tblslvconteodet  cod                     
        where cod.idconteo = p_idConteo                     
          --ultimo articulo ingresado
          and cod.cdarticulo = p_cdarticulo;
       if v_diferencias = 0 then 
           p_Ok    := 0;
           p_error := 'Art�culo sin diferencias';
           ROLLBACK;        
           RETURN;  
        end if;    
       exception
         when no_data_found then
           p_Ok    := 0;
           p_error := 'Art�culo no valido';
           ROLLBACK;        
           RETURN;   
         when others then
           p_Ok    := 0;
           p_error := 'Art�culo sin diferencias';
           ROLLBACK;        
           RETURN;   
       end;    
      -- si el articulo es del grupo con diferencias
      if v_diferencias <> 0 then
        -- intento actualizar en conteoDet la cantidad solicitada
         if UpdateConteoDet(v_IdConteo,p_cdArticulo,v_qtbase,v_qtpiezas) = 0 then
                p_Ok    := 0;
                p_error := 'Error. Comuniquese con sistemas.';
                ROLLBACK;        
                RETURN;                   
          end if;             
      end if;  
         
   p_Ok    := 1;
   p_error := null;           
   commit;                           
   exception                  
    when others then
           n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       ' Error: ' || SQLERRM);
          p_Ok    := 0;
          p_error := 'Error. Comuniquese con sistemas.';            
          ROLLBACK;
          RETURN;       
   END SetReConteoDet;  
   
   /****************************************************************************************************
  * %v 28/07/2020 - ChM  Versi�n inicial GetErroresControl
  * %v 28/07/2020 - ChM  recibe un idremito para iniciar su ajuste de errores                     
  *****************************************************************************************************/
  PROCEDURE GetErroresControl(p_idremito           IN  tblslvremito.idremito%type,
                              p_cursor             OUT CURSOR_TYPE,                  
                              p_Ok                 OUT number,
                              p_error              OUT varchar2) IS
                       
    v_modulo           varchar2(100) := 'PKG_SLV_CONTROL.GetErroresControl';
    v_estado           tblslvremito.cdestado%type:=null;   
    v_idremito         tblslvremito.idremito%type:=0;   
    v_idControl        tblslvcontrolremito.idcontrolremito%type;
    v_valida           integer:=0;
    
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
    --los remito de distribuci�n se controlan
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
           when no_data_found then
            p_Ok    := 0;
            p_error := 'Remito '||to_char(p_idremito)||' No Controlado.';
            RETURN;
         end;
         
     --verifica si esta Controlado
    if v_estado in (C_Controlado) then
       p_Ok    := 0;
       p_error := 'Remito '||to_char(p_idremito)||' ya Controlado sin errores.';
       RETURN;
    end if;   
   --verifica si esta iniciado Control
    if v_estado in (C_IniciaControl) then
       p_Ok    := 0;
       p_error := 'Remito '||to_char(p_idremito)||' en proceso de Control.';
       RETURN;
    end if;  
    
    --verifica si no existen diferencias
    begin
     select count(crd.cdarticulo)
       into v_valida                              
       from tblslvcontrolremitodet            crd                          
      where crd.idcontrolremito = v_idControl             
         --solo cuenta los art�culos con diferencias
        and (crd.qtdiferenciaunidadmbase <> 0 or crd.qtdiferenciapiezas <> 0)
         --solo articulos no ajustados
        and crd.qtajusteunidadmbase is null;
     if v_valida = 0 then
         p_Ok    := 0;
         p_error := 'Remito '||to_char(p_idremito)||' sin diferencias.';
         RETURN;  
     end if;   
    exception
      when no_data_found then
         p_Ok    := 0;
         p_error := 'Remito '||to_char(p_idremito)||' sin diferencias.';
         RETURN;    
    end;
    --cursor con el listado de diferencias 
   open p_Cursor for 
           select A.cdarticulo,
                  A.cdarticulo||' - '||des.vldescripcion||'  |  '||  
                  --formato de Cantidad
                  PKG_SLV_Articulo.SetFormatoArticuloscod(A.cdarticulo,A.Cantidad) ||
                  --valida sobrante o faltante
                  case 
                    when A.Cantidad > 0 then ' (S)'
                    when A.Cantidad < 0 then ' (F)'
                   end Articulo,
                   case 
                    when A.Cantidad > 0 then 'S'
                    when A.Cantidad < 0 then 'F'
                   end Articulo
             from (select crd.cdarticulo,                          
                          --valida pesables
                          decode(sum(crd.qtdiferenciapiezas),0,
                          (sum(crd.qtdiferenciaunidadmbase)),
                           sum(crd.qtdiferenciapiezas)) Cantidad                                                
                     from tblslvcontrolremitodet            crd                          
                    where crd.idcontrolremito = v_idControl             
                       --solo muestra los art�culos con diferencias
                      and (crd.qtdiferenciaunidadmbase <> 0 or crd.qtdiferenciapiezas <> 0)
                      --solo articulos no ajustados
                      and crd.icfinalizado = 0
                 group by crd.cdarticulo
                 order by Cantidad desc  
                   )A,
                    descripcionesarticulos des
              where A.cdarticulo = des.cdarticulo;
           
    p_Ok    := 1;
    p_error := '';    
    EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       ' Error: ' || SQLERRM);
      p_Ok    := 0;
      p_error:='Error. Comuniquese con Sistemas!';
  END GetErroresControl;
  
  /****************************************************************************************************
  * %v 28/07/2020 - ChM  Versi�n inicial SetErroresControl
  * %v 28/07/2020 - ChM  recibe un idremito y cdarticulo para ajustar cantidades
  *****************************************************************************************************/
  PROCEDURE SetErroresControl(p_idremito           IN  tblslvremito.idremito%type,                        
                              p_cdBarras           IN  barras.cdeancode%type, 
                              p_cdArticulo         IN  articulos.cdarticulo%type,                      
                              p_qtunidad           IN  tblslvremitodet.qtunidadmedidabasepicking%type,
                              p_Faltante_sobrante  IN  varchar, 
                              p_Cursor             OUT CURSOR_TYPE,
                              p_Ok                 OUT number,
                              p_error              OUT varchar2  
                              ) IS

    v_modulo           varchar2(100) := 'PKG_SLV_CONTROL.SetErroresControl';
    v_error            varchar2(250); 
    v_estado           tblslvremito.cdestado%type:=null; 
    v_idControl        tblslvcontrolremito.idcontrolremito%type;
    v_qtcontrol        tblslvcontrolremito.qtcontrol%type;     
    v_idConteo         tblslvconteo.idconteo%type;
    v_qtveces          tblslvconteo.qtveces%type;
    v_valida           integer:=0;   
    v_qtbase           tblslvcontrolremitodet.qtunidadmedidabasepicking%type;
    v_qtpiezas         tblslvcontrolremitodet.qtpiezaspicking%type;
    v_cdunidad         barras.cdunidad%type;
    v_cantidad         tblslvtareadet.qtunidadmedidabase%type;
    V_UxB              number;
    v_cdunidadVentamin articulos.cdunidadventaminima%type;
    
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
              p_Ok    := 0;
              p_error := 'Control para el remito '||to_char(p_idremito)||' no existe.';
              return;
       end;
       
       --valida si existe el conteo inicial 
       begin        
            select co.idconteo,
                   co.qtveces
              into v_idConteo,
                   v_qtveces
              from tblslvconteo co
             where co.idcontrolremito = v_idControl
               and co.qtveces = 1;
       exception                  
          when no_data_found then
              p_Ok    := 0;
              p_error := 'Conteo para el remito '||to_char(p_idremito)||' no existe.';
              return;
       end;
       
      --verifica si esta Controlado
      if v_estado in (C_Controlado) then
         p_Ok    := 0;
         p_error := 'Remito '||to_char(p_idremito)||' ya Controlado.';
         RETURN;
      end if;  
      
      --verifica si esta en proceso
      if v_estado in (C_IniciaControl) then
         p_Ok    := 0;
         p_error := 'Remito '||to_char(p_idremito)||' en proceso de control.';
         RETURN;
      end if; 
      
     --cursor con el listado de diferencias 
   open p_Cursor for 
           select A.cdarticulo,
                  A.cdarticulo||' - '||des.vldescripcion||'  |  '|| 
                  --formato de Cantidad
                  PKG_SLV_Articulo.SetFormatoArticuloscod(A.cdarticulo,A.Cantidad) ||
                  --valida sobrante o faltante
                  case 
                    when A.Cantidad > 0 then ' (S)'
                    when A.Cantidad < 0 then ' (F)'
                   end Articulo,
                   case 
                    when A.Cantidad > 0 then 'S'
                    when A.Cantidad < 0 then 'F'
                   end Articulo                  
             from (select crd.cdarticulo,                          
                          --valida pesables
                          decode(sum(crd.qtdiferenciapiezas),0,
                          (sum(crd.qtdiferenciaunidadmbase)),
                           sum(crd.qtdiferenciapiezas)) Cantidad                                            
                     from tblslvcontrolremitodet            crd                          
                    where crd.idcontrolremito = v_idControl             
                       --solo muestra los art�culos con diferencias
                      and (crd.qtdiferenciaunidadmbase <> 0 or crd.qtdiferenciapiezas <> 0)
                      --solo articulos no ajustados
                      and crd.icfinalizado = 0
                 group by crd.cdarticulo
                 order by Cantidad desc  
                   )A,
                    descripcionesarticulos des
              where A.cdarticulo = des.cdarticulo
              --muestra solo un articulo
                and rownum=1;
                  
        --verifica si no existen diferencias en el remito
    begin
     select count(crd.cdarticulo)
       into v_valida                              
       from tblslvcontrolremitodet            crd                          
      where crd.idcontrolremito = v_idControl             
         --solo cuenta los art�culos con diferencias
        and (crd.qtdiferenciaunidadmbase <> 0 or crd.qtdiferenciapiezas <> 0);       
     if v_valida = 0 then
         p_Ok    := 0;
         p_error := 'Remito '||to_char(p_idremito)||' sin diferencias.';
         RETURN;  
     end if;   
    exception
      when no_data_found then
         p_Ok    := 0;
         p_error := 'Remito '||to_char(p_idremito)||' sin diferencias.';
         RETURN;    
    end;
     
   --valida si el articulo ya esta finalizado
       begin 
         v_cantidad:=0;     
       select count(crd.cdarticulo) 
         into v_cantidad                
         from tblslvcontrolremitodet crd                     
        where crd.idcontrolremito = v_idControl                    
          --ultimo articulo ingresado
          and crd.cdarticulo = p_cdarticulo
          --marca de finalizado
          and crd.icfinalizado = 1;
       if v_cantidad <> 0 then 
           p_Ok    := 0;
           p_error := 'Art�culo Finalizado';
           ROLLBACK;        
           RETURN;  
        end if;    
       exception         
         when others then
          null; 
       end;  
      
       --si desea finalizar el renglon p_qtunidad=0
      if p_qtunidad=0 then
         v_error:='Falla UPDATE tblslvcontrolremitodet a FINALIZADO';
         update tblslvcontrolremitodet crd   
            set crd.icfinalizado = 1,
                crd.qtajusteunidadmbase = nvl(crd.qtajusteunidadmbase,0),
                crd.qtajustepiezas = nvl(crd.qtajustepiezas,0), 
                crd.dtupdate = sysdate
          where crd.idcontrolremito = v_idControl
            and crd.cdarticulo = p_cdArticulo; 
         IF SQL%ROWCOUNT = 0 THEN
             n_pkg_vitalpos_log_general.write(2,
                                              'Modulo: ' || v_modulo ||
                                              '  Detalle Error: ' || v_error);
             p_Ok    := 0;
             p_error:='Error. Comuniquese con Sistemas';
             ROLLBACK;
             RETURN;
         END IF; 
          p_Ok    := 1;
          p_error := '';       
          commit;             
      end if;
  
    --verifica si no existen diferencias en el Articulo
    begin
     select count(crd.cdarticulo)
       into v_valida                              
       from tblslvcontrolremitodet            crd                          
      where crd.idcontrolremito = v_idControl             
         --solo cuenta los art�culos con diferencias
        and (crd.qtdiferenciaunidadmbase <> 0 or crd.qtdiferenciapiezas <> 0)
        --solo articulos no ajustados
        and crd.icfinalizado = 0
        and crd.cdarticulo = p_cdArticulo;
     if v_valida = 0 then
        -- Actualiza a finalizado automatico sino hay diferencias
         update tblslvcontrolremitodet crd   
            set crd.icfinalizado = 1,
                crd.qtajusteunidadmbase = nvl(crd.qtajusteunidadmbase,0),
                crd.qtajustepiezas = nvl(crd.qtajustepiezas,0), 
                crd.dtupdate = sysdate
          where crd.idcontrolremito = v_idControl
            and crd.cdarticulo = p_cdArticulo; 
         IF SQL%ROWCOUNT = 0 THEN
             n_pkg_vitalpos_log_general.write(2,
                                              'Modulo: ' || v_modulo ||
                                              '  Detalle Error: ' || v_error);
             p_Ok    := 0;
             p_error:='Error. Comuniquese con Sistemas';
             ROLLBACK;
             RETURN;
         END IF;      
         p_Ok    := 0;
         p_error := 'Art�culo sin diferencias.';
         RETURN;  
     end if;   
    exception
      when no_data_found then
         p_Ok    := 0;
         p_error := 'Art�culo sin diferencias.';
         RETURN;    
    end;
    
    --valida si p_qtunidad es mayor a cero y existe p_cdbarras
    if p_qtunidad>0 and p_cdBarras is not null then    
        --devuelve la unidad de medida del articulo segun codigo de barra         
        pkg_slv_articulo.GetValidaArticuloBarras(p_cdArticulo,p_cdBarras,v_cdunidad,v_cantidad); 
          
          if trim(v_cdunidad) = '-' then
              p_Ok:=0;
              p_error:='El Codigo de barra no corresponde al art�culo!';
              rollback;
              return;
          end if;
 
         --valida unidad de venta minima indivisibles
         v_cdunidadVentamin:=pkg_slv_articulo.GetUnidadVentaMinimaArt(p_cdArticulo);     
         if trim(v_cdunidadVentamin) <> trim(v_cdunidad) and trim(v_cdunidadVentamin)<>'-' then
            p_Ok:=0;
            p_error:='La unidad m�nima de venta es '||v_cdunidadVentamin||' Ingreso '||v_cdunidad;
            rollback;
            return;
         end if;   
          
         v_qtbase:=p_qtunidad;
         v_qtpiezas:=0;
          --si es distinto de unidad o pesable se busca y multiplica por el UXB
         if v_cdunidad not in ('UN','KG','PZA') then
           V_UxB:=posapp.n_pkg_vitalpos_materiales.GetUxB(p_cdArticulo,v_cdunidad);
           v_qtbase:=p_qtunidad*V_UxB;
           v_qtpiezas:=0;
         end if;   
         --si es igual a KG o PZA pesable
         if v_cdunidad in ('KG','PZA') then
           v_qtpiezas:=p_qtunidad; 
           v_qtbase:=0;
         end if;    
      else
          v_qtpiezas:=0; 
          v_qtbase:=0;   
    end if;       
    --Actualiza la cantidad ingresada faltante o sobrante    
    if p_Faltante_sobrante = 'S' then
        v_qtbase:=-abs(v_qtbase);
        v_qtpiezas:=-abs(v_qtpiezas); 
      end if;      
    if p_Faltante_sobrante = 'F' then
        v_qtbase:=abs(v_qtbase);
        v_qtpiezas:=abs(v_qtpiezas); 
      end if;  
       
     v_error:='Falla UPDATE tblslvcontrolremitodet';
    update tblslvcontrolremitodet crd               
       set crd.qtdiferenciaunidadmbase = nvl(crd.qtdiferenciaunidadmbase,0) + v_qtbase,
           crd.qtdiferenciapiezas = nvl(crd.qtdiferenciapiezas,0) + v_qtpiezas,
           crd.qtajusteunidadmbase = nvl(crd.qtajusteunidadmbase,0) + v_qtbase,
           crd.qtajustepiezas = nvl(crd.qtajustepiezas,0) + v_qtpiezas,
           crd.dtupdate=sysdate
     where crd.idcontrolremito = v_idControl
       and crd.cdarticulo = p_cdarticulo;
      IF SQL%ROWCOUNT = 0 THEN
             n_pkg_vitalpos_log_general.write(2,
                                              'Modulo: ' || v_modulo ||
                                              '  Detalle Error: ' || v_error);
             p_Ok    := 0;
             p_error:='Error. Comuniquese con Sistemas';
             ROLLBACK;
             RETURN;
         END IF;  
           
     --si desea finalizar (F) verifica si aun quedan articulos sin ajustar
    if p_cdBarras ='F' then
      begin
        v_cantidad:=0;
        select count(cr.cdarticulo)
         into v_cantidad
         from tblslvcontrolremitodet cr
        where cr.idcontrolremito = v_idControl          
          --valida articulos no finalizados
          and cr.icfinalizado = 0;
        if v_cantidad <> 0 then
             p_Ok    := 0;
             p_error:='No es posible finalizar. Tiene art�culos sin ajustar.';
             ROLLBACK;
             RETURN;        
        end if;     
       exception
           when no_data_found then
              null;
      end;
      p_Ok    := 1;
      p_error := '';       
      commit; 
      return;   
    end if;    
                          
    --actualizo dtfin de tblslvcontrolremito POR CADA AJUSTE
    v_error:='Falla UPDATE tblslvcontrolremito'; 
    update tblslvcontrolremito cr              
       set cr.dtfin= sysdate
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
    p_Ok    := 1;
    p_error := '';       
    commit; 
  EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       ' Error: ' || SQLERRM);
      p_Ok    := 0;
      p_error:='Error. Comuniquese con Sistemas!';
  END SetErroresControl;  
  
  /****************************************************************************************************
  * %v 27/07/2020 - ChM  Versi�n inicial  SetVerificaConteo
  * %v 27/07/2020 - ChM  recibe p_idConteo y verifica el conteo de los articulos con error
  *****************************************************************************************************/
   PROCEDURE SetVerificaConteo(p_idConteo           IN  tblslvconteo.idconteo%type, 
                               p_idNuevoConteo      OUT tblslvconteo.idconteo%type, 
                               p_ajustar            OUT integer,                                                                  
                               p_Ok                 OUT number,
                               p_error              OUT varchar2)
                            IS
                          
    v_modulo           varchar2(100) := 'PKG_SLV_CONTROL.SetVerificaConteo';
    v_cantidad         integer:=0;     
    v_estado           tblslvremito.cdestado%type:=null;
    v_idControl        tblslvcontrolremito.idcontrolremito%type;
    v_qtcontrol        tblslvcontrolremito.qtcontrol%type; 
    v_idremito         tblslvremito.idremito%type;
    v_cursor           CURSOR_TYPE;    
    v_qtveces          tblslvconteo.qtveces%type:=10;                   
  BEGIN    
      p_ajustar:=0;
     --verifica si existen articulos sin cargar en el conteo p_idConteo 
     begin
         select count(cod.cdarticulo) 
           into v_cantidad        
           from tblslvconteodet        cod
          where cod.idconteo = p_idConteo
            and (cod.qtunidadmedidabasepicking is null or cod.qtpiezaspicking is null);   
          if v_cantidad = 0 then      
             p_Ok    := 0;
             p_error := 'Existen art�culos sin contar. Continue el Conteo!';
             RETURN;
          end if;
      exception
        when no_data_found then
          null;    
     end; 
     
    --valida si existe el idremito en tblslvcontrolremito 
     begin        
          select co.idcontrolremito,
                 cr.cdestado,
                 cr.qtcontrol,
                 cr.idremito                
            into v_idControl,
                 v_estado,
                 v_qtcontrol,
                 v_idremito                   
            from tblslvconteo co,
                 tblslvcontrolremito cr
           where cr.idcontrolremito = co.idcontrolremito
             and co.idconteo = p_idConteo; 
     exception                  
        when no_data_found then
            p_Ok    := 0;
            p_error := 'Control para el Remito '||to_char(v_idremito)||' no existe.';
            return;
     end;
              
    --Actualizo en tblslvcontrolremitodet las cantidades del nuevo conteo
   for conteodet in 
       (select c.idcontrolremito,
               c.qtveces,
               cd.cdarticulo,
               cd.qtunidadmedidabasepicking,
               cd.qtpiezaspicking
          from tblslvconteo   c,
               tblslvconteodet cd               
         where c.idconteo = p_IdConteo
           and c.idconteo = cd.idconteo)
    loop
      update tblslvcontrolremitodet crd
         set crd.qtunidadmedidabasepicking = conteodet.qtunidadmedidabasepicking,
             crd.qtpiezaspicking = conteodet.qtpiezaspicking,
             crd.dtupdate = sysdate
       where crd.cdarticulo = conteodet.cdarticulo
         and crd.idcontrolremito = conteodet.idcontrolremito;      
        IF SQL%ROWCOUNT = 0 THEN
          p_Ok    := 0;
          p_error := 'Error. Comuniquese con sistemas.';
          n_pkg_vitalpos_log_general.write(2,
                                         'Modulo: ' || v_modulo ||
                                         ' Error: ' || SQLERRM);        
          ROLLBACK;
          RETURN;
        END IF;
         --asigno a la variable qtveces
          v_qtveces:=conteodet.qtveces;     
      end loop;    
     
     --validar si el conteo elimino las diferencias del control de remito finalizar ok
     begin
       v_cantidad:=0;
       select count(*)
         into v_cantidad 
         from tblslvcontrolremitodet crd
        where crd.idcontrolremito = v_idcontrol
          --cuenta las que tienen diferencia            
          and crd.qtdiferenciaunidadmbase+crd.qtunidadmedidabasepicking <> 0
          and crd.qtdiferenciapiezas+crd.qtpiezaspicking <> 0;       
       exception 
         when no_data_found then
          v_cantidad:=0;
       end;
     --si verifica OK segundo llamado a SetcontrolarRemito 
      if v_cantidad = 0 then         
         PKG_SLV_CONTROL.ControlarRemito(v_idremito,p_Ok,p_error,v_cursor); 
         if p_ok = 0 then
           rollback;
           return;
         end if;  
         p_Ok    := 1;
         p_error := null;
         commit;
         return;  
      end if;
           
      --compara los conteos anteriores    
       for valida in
              (select cd.cdarticulo, 
                      count(cd.cdarticulo) aparece,
                      PKG_SLV_CONTROL.ContarArticulos(v_idControl,cd.cdarticulo,
                      --indica pesables
                      decode(sum(cd.qtpiezaspicking),0,0,1)) frecuencia                                   
                 from tblslvconteodet cd,
                      tblslvconteo    co
                where co.idconteo = cd.idconteo
                  and co.idcontrolremito = v_idcontrol
             group by cd.cdarticulo)
        loop
             --verifica si aparece el articulo mas de 1 vez y no se repite
             --crea el nuevo conteo para recontar
             if valida.aparece > 1 and valida.frecuencia = 0 then                 
                 if p_idNuevoConteo is null then
                    --creo el conteo 
                    p_idNuevoConteo:=InsertConteo(v_idControl,v_qtveces+1); 
                    if p_idNuevoConteo = 0 then
                      p_Ok    := 0;
                      p_error:='Error. Comuniquese con sistemas!';
                      ROLLBACK;
                      RETURN;
                     end if; 
                  --inserto el articulo con error de conteo detalle null para volver a contar                
                   if InsertConteoDet(p_idNuevoConteo,valida.cdarticulo,null,null) = 0 then
                      p_Ok    := 0;
                      p_error:='Error. Comuniquese con Sistemas!';
                      ROLLBACK;             
                      RETURN;
                     end if;             
                 end if;  
             end if;
        end loop;  
    --si el parametro se mantiene NULL no hay errores en el conteo
    if p_idNuevoConteo is null then      
        --si hay diferencias pero existen dos conteos iguales se llama controlarremito 
         -- ejecuta y devuelve el estado C_ControladoConError y aplica el commit en SetControlarRemito 
         --segundo llamado a controlarremito fin del control         
         PKG_SLV_CONTROL.ControlarRemito(v_idremito,p_Ok,p_error,v_cursor); 
        if p_ok = -2 then
            --  p_ajustar = 1 implica llamar al procedimiento de ajuste de remito GetErroresControl
            p_ajustar:=1;
            p_ok:=1;
            p_error:= '';
          end if;  
    else
       p_Ok    := 0;
       p_error:='Falla de Control.';  
    end if;            
    p_Ok    := 1;
    p_error := null;
    commit;
   exception                  
    when others then
          n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       ' Error: ' || SQLERRM);
          p_Ok    := 0;
          p_error := 'Error. Comuniquese con sistemas.';
   END  SetVerificaConteo;    
   /****************************************************************************************************
  * %v 03/07/2020 - ChM  Versi�n inicial SetControlarRemito
  * %v 03/07/2020 - ChM  recibe un p_idremito  para validar contra el remito
  *****************************************************************************************************/
  PROCEDURE ControlarRemito(p_idremito           IN  tblslvremito.idremito%type,
                            p_Ok                 OUT number,
                            p_error              OUT varchar2,
                            p_cursor             OUT CURSOR_TYPE) IS

    v_modulo           varchar2(100) := 'PKG_SLV_CONTROL.ControlarRemito';
    v_estado           tblslvremito.cdestado%type:=null;
    v_error            varchar2(250); 
    v_idControl        tblslvcontrolremito.idcontrolremito%type;  
    v_qtcontrol        tblslvcontrolremito.qtcontrol%type:=0;
    v_band             integer:=0;   
    v_idConteo         tblslvconteo.idconteo%type;
    v_qtveces          tblslvconteo.qtveces%type;
    
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
    
    --valida si existe el conteo inicial 
       begin        
            select co.idconteo,
                   co.qtveces
              into v_idConteo,
                   v_qtveces
              from tblslvconteo co
             where co.idcontrolremito = v_idControl
               and co.qtveces = 1;
       exception                  
          when no_data_found then
              p_Ok    := 0;
              p_error := 'Conteo para el remito '||to_char(p_idremito)||' no existe.';
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
        p_Ok    := 0;
        p_error := ' Remito '||to_char(p_idremito)||' No tiene art�culos picking para controlar.';
        ROLLBACK;
        RETURN;           
    end;   
       
    --verifica si esta Controlado
    if v_estado in (C_Controlado, C_ControladoConError) then
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
    --listado de articulos del remito que no est�n en el control
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
     --finaliza conteo
     if FinalizaConteo(v_idConteo) <> 1 then
        p_Ok    := 0;
        p_error:='Error. Comuniquese con Sistemas';
        ROLLBACK;
        RETURN;
      end if;         
       --si remito controlado termina procedimiento          
       p_Ok:=1;
       p_error:='';
       commit;  
       RETURN;        
     end if;

  --valido si es el primer control del remito y llega a esta condici�n hay diferencias
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
             
   --INDICA PASO PARA LLAMAR GETRECONTEO  
   p_Ok:=-1;
   p_error := '';
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
                       --solo muestra los art�culos con diferencias
                      and (crd.qtdiferenciaunidadmbase <> 0 or crd.qtdiferenciapiezas <> 0)
                 group by crd.cdarticulo
                   )A,
                    descripcionesarticulos des
              where A.cdarticulo = des.cdarticulo;       
   RETURN;             
  end if; 
  --valido si es el segundo control del remito y llega a esta condici�n hay diferencias
  if  v_qtcontrol = 2 then
     --actualiza a CONTROLADO CON ERROR la tblslvcontrolremito
       v_error:='Falla UPDATE tblslvcontrolremito';
       update tblslvcontrolremito cr
          set cr.cdestado = C_ControladoConError,
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
            
   --INDICA PASO PARA LLAMAR GETERRORESCONTROL 
   p_Ok:=-2;
   p_error := '';
   --finaliza conteo
   if FinalizaConteo(v_idConteo) <> 1 then
      p_Ok    := 0;
      p_error:='Error. Comuniquese con Sistemas';
      ROLLBACK;
      RETURN;
    end if;  
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
                       --solo muestra los art�culos con diferencias
                      and (crd.qtdiferenciaunidadmbase <> 0 or crd.qtdiferenciapiezas <> 0)
                 group by crd.cdarticulo
                   )A,
                    descripcionesarticulos des
              where A.cdarticulo = des.cdarticulo;     
   commit;            
  end if; 
  EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       ' Error: ' || SQLERRM);
      p_Ok    := 0;
      p_error:='Error Control Remito. Comuniquese con Sistemas!';
  END ControlarRemito;                   
   /****************************************************************************************************
  * %v 14/07/2020 - ChM  Versi�n inicial ContarArticulos
  * %v 14/07/2020 - ChM  devuelve 1 si dos conteos de un articulo son iguales 
                         revisando en todos los conteos de un idcontrol
  *****************************************************************************************************/
  FUNCTION ContarArticulos(p_Idcontrol        tblslvcontrolremito.idcontrolremito%type,
                           p_cdarticulo       articulos.cdarticulo%type,
                           p_marcapesable     integer) 
                           RETURN integer IS     
  BEGIN
    --verifica si es pesable
    if p_marcapesable = 1 then 
        for conteo in               
               (select count (nvl(cd.qtpiezaspicking,0)) cant 
                  from tblslvconteodet          cd,
                       tblslvconteo             co,
                       tblslvcontrolremito      cr          
                 where cd.idconteo = co.idconteo
                   and co.idcontrolremito = cr.idcontrolremito
                   and cd.cdarticulo = p_cdarticulo
                   and cr.idcontrolremito = p_idcontrol
                   and nvl(cd.qtpiezaspicking,0)<>0
                 group by cd.qtpiezaspicking)
         loop
           --verifica si algun conteo es mayor a 2
           if conteo.cant >=2 then
              RETURN 1;
           end if;   
         end loop;  
     else
       for conteo in               
               (select count (nvl(cd.qtunidadmedidabasepicking,0)) cant 
                  from tblslvconteodet          cd,
                       tblslvconteo             co,
                       tblslvcontrolremito      cr          
                 where cd.idconteo = co.idconteo
                   and co.idcontrolremito = cr.idcontrolremito
                   and cd.cdarticulo = p_cdarticulo
                   and cr.idcontrolremito = p_idcontrol
                   and nvl(cd.qtunidadmedidabasepicking,0)<>0
                 group by cd.qtunidadmedidabasepicking)
         loop
           --verifica si algun conteo es mayor a 2
           if conteo.cant >=2 then
              RETURN 1;
           end if;   
         end loop;   
      end if;             
     RETURN 0;  
    EXCEPTION
      WHEN OTHERS THEN
        RETURN 0;
    END ContarArticulos;                          
  
  /****************************************************************************************************
  * %v 14/07/2020 - ChM  Versi�n inicial ContarRemitos
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
  * %v 14/07/2020 - ChM  Versi�n inicial GetPanelControl
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
  * %v 14/07/2020 - ChM  Versi�n inicial EstadoPedidoControl
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
          if v_estado in (C_Controlado, C_ControladoConError) then
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
          if v_estado in (C_Controlado, C_ControladoConError) then
             v_cControl:=v_cControl+1;
          end if;   
        exception
          when no_data_found then
                --cuento los remitos no encontrados
               v_cError:= v_cError + 1;               
        end; 
        end loop; 
      end if;  
     --verifica si todos los remitos est�n controlados
     if v_cRemito = v_cControl and v_cRemito<>0 then          
       return 'Controlado';
    end if; 
    --verifica si todos los remitos no est�n en tblslvcontrolremito
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
  * %v 14/07/2020 - ChM  Versi�n inicial GetDetalleControl
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
                 A.cdtipo tipotarea,
                 A.estado,
                 A.Armador,
                 --nombre del controlador
                 nvl2(A.idpersonacontrol,
                      (select nvl(upper(p.dsnombre) || ' ' || upper(p.dsapellido),'-') nom
                         from personas p
                       where p.idpersona = A.idpersonacontrol
                         and rownum=1) ,'-') personacontrol,
                 PKG_SLV_CONTROL.ErroresControl(A.idremito) errores,
                 PKG_SLV_REMITOS.FormatoUbicacionRemito(A.idubicacionremito) ubicacion                           
            from (select r.idremito,
                         r.nrocarreta,
                         ta.cdtipo,
                         --etiqueta el estado
                         nvl2(cr.cdestado,decode(cr.cdestado,C_Controlado,'Controlado',
                         C_ControladoConError,'Controlado con error','En Curso'),'No Controlado') estado,
                         upper(pe.dsnombre) || ' ' || upper(pe.dsapellido) Armador,
                         cr.idpersonacontrol,
                         r.idubicacionremito                                                                        
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
                         c_TareaConsolidadoPedido cdtipo,
                         --etiqueta el estado
                         nvl2(cr.cdestado,decode(cr.cdestado,C_Controlado,'Controlado',
                         C_ControladoConError,'Controlado con error','En Curso'),'No Controlado') estado,
                         'DISTRIBUCI�N DE FALTANTE'  Armador,
                         cr.idpersonacontrol,
                         r.idubicacionremito                           
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
                 A.cdtipo tipotarea,
                 A.estado,
                 A.Armador,
                 --nombre del controlador
                 nvl2(A.idpersonacontrol,
                      (select nvl(upper(p.dsnombre) || ' ' || upper(p.dsapellido),'-') nom
                         from personas p
                       where p.idpersona = A.idpersonacontrol
                         and rownum=1) ,'-') personacontrol,
                 PKG_SLV_CONTROL.ErroresControl(A.idremito) errores,
                 PKG_SLV_REMITOS.FormatoUbicacionRemito(A.idubicacionremito) ubicacion           
            from (select r.idremito,
                         r.nrocarreta,
                         ta.cdtipo,
                         --etiqueta el estado
                         nvl2(cr.cdestado,decode(cr.cdestado,C_Controlado,'Controlado',
                         C_ControladoConError,'Controlado con error','En Curso'),'No Controlado') estado,
                         upper(pe.dsnombre) || ' ' || upper(pe.dsapellido) Armador,
                         cr.idpersonacontrol,
                         r.idubicacionremito                                                                         
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
  * %v 14/07/2020 - ChM  Versi�n inicial ErroresControl
  * %v 14/07/2020 - ChM  verifica si el remito se control� con errores
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
  * %v 15/07/2020 - ChM  Versi�n inicial GetArticulosControl
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
                     --solo muestra los art�culos con diferencias
                     and (crd.qtdiferenciaunidadmbase <> 0 or crd.qtdiferenciapiezas <> 0)            
                     and ta.idconsolidadopedido = p_idpedido
               union all       
                  select crd.cdarticulo,
                         crd.qtdiferenciaunidadmbase,
                         crd.qtdiferenciapiezas, 
                         r.idremito,                                               
                         'DISTRIBUCI�N DE FALTANTE' Armador,
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
                     --solo muestra los art�culos con diferencias
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
                     --solo muestra los art�culos con diferencias
                     and (crd.qtdiferenciaunidadmbase <> 0 or crd.qtdiferenciapiezas <> 0)            
                     and ta.idconsolidadocomi = p_idcomi) A,
                descripcionesarticulos        des   
          where A.cdarticulo = des.cdarticulo
          order by accion;
    end if;
     
  END GetArticulosControl; 
  
  /****************************************************************************************************
  * %v 15/07/2020 - ChM  Versi�n inicial GetFacturas
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
       select LISTAGG(factura, '�')
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
       select LISTAGG(factura, '�')
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
 
  /****************************************************************************************************
  * %v 04/08/2020 - ChM  Versi�n inicial DetalleRemito
  * %v 04/08/2020 - ChM  datos detallados del remito
  *****************************************************************************************************/
  PROCEDURE DetalleRemito(p_idremito        IN  tblslvremito.idremito%type,
                          p_TipoTarea       IN  Tblslvtipotarea.cdtipo%type,
                          p_DsSucursal      OUT sucursales.dssucursal%type,                  
                          p_CursorCab       OUT CURSOR_TYPE,                                            
                          p_Cursor          OUT CURSOR_TYPE) IS
                               
  v_modulo                           varchar2(100) := 'PKG_SLV_CONTROL.DetalleRemito';
 
  BEGIN
    PKG_SLV_REMITOS.GetRemito(p_idRemito,p_TipoTarea,p_DsSucursal,p_CursorCab);
    OPEN p_Cursor FOR                
                select A.cdarticulo || '- ' || des.vldescripcion Articulo,
                       --codigo de barras 
                       decode(A.qtpiezas,0,
                       PKG_SLV_ARTICULO.GetCodigoDeBarra(A.cdarticulo,'UN'),
                       PKG_SLV_ARTICULO.GetCodigoDeBarra(A.cdarticulo,'KG')) barras, 
                       PKG_SLV_Articulo.SetFormatoArticulosCod(A.cdarticulo,
                        --formato en piezas si es pesable  
                       decode(A.qtpiezas,0,A.qtbase,A.qtpiezas)) Cantidad   
                  from (select rd.cdarticulo,
                               sum(rd.qtpiezaspicking) qtpiezas,
                               sum(rd.qtunidadmedidabasepicking) qtbase 
                          from tblslvremito           re,
                               tblslvremitodet        rd
                         where re.idremito = rd.idremito
                           and re.idremito = p_idremito
                      group by rd.cdarticulo)A,
                       descripcionesarticulos des 
                 where A.cdarticulo = des.cdarticulo;         
   EXCEPTION
   WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       '  Error: ' || SQLERRM);
  END DetalleRemito; 
  
end PKG_SLV_CONTROL;
/
