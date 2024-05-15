CREATE OR REPLACE PACKAGE PKG_SLV_REVERSOS is
/**********************************************************************************************************
 * Author  : CHARLES MALDONADO
 * Created : 09/09/2020 8:17:03 a.m.
 * %v Paquete para reverso de los distintos procesos SLVM
 **********************************************************************************************************/
 -- Tipos de datos
 TYPE cursor_type IS REF CURSOR;

  --Procedimientos y Funciones
  PROCEDURE ReversaControlRemito (p_idremito        IN  tblslvremito.idremito%type,
                                  p_Ok              OUT number,
                                  p_error           OUT varchar2);
                                  
  PROCEDURE  ReversaTareaNoFinalizada(p_idTarea         IN  Tblslvtarea.Idtarea%type,
                                      p_Ok              OUT number,
                                      p_error           OUT varchar2); 
                                      
  PROCEDURE ReversaDistribFaltante (p_idfaltante      IN  tblslvpedfaltante.idpedfaltante%type,
                                    p_Ok              OUT number,
                                    p_error           OUT varchar2);

  PROCEDURE ReversaPedFaltante (p_idfaltante      IN  tblslvpedfaltante.idpedfaltante%type,
                                p_Ok              OUT number,
                                p_error           OUT varchar2);                                                                                                        
                                                                  
end PKG_SLV_REVERSOS;
/
CREATE OR REPLACE PACKAGE BODY PKG_SLV_REVERSOS is
   
/**************************************************************************************************
* %v 09/09/2020  ChM - reversa el control del remito enviado por parametro
***************************************************************************************************/
  PROCEDURE ReversaControlRemito (p_idremito        IN  tblslvremito.idremito%type,
                                  p_Ok              OUT number,
                                  p_error           OUT varchar2)
                                      IS
                                                
     v_modulo               varchar2(100) := 'PKG_SLV_REVERSOS.ReversaControlRemito. Remito: '||p_idremito;    
        
    BEGIN
        --borrar el conteo detalle
        delete tblslvconteodet cond 
         where cond.idconteo in ( select co.idconteo
                                    from tblslvconteo co
                                   where co.idcontrolremito in  (select cr.idcontrolremito
                                                                   from tblslvcontrolremito cr
                                                                  where cr.idremito = p_idremito));                          
                                            
        --borrar el conteo 
        delete tblslvconteo co 
         where co.idcontrolremito in (select cr.idcontrolremito
                                        from tblslvcontrolremito cr
                                       where cr.idremito  = p_idremito);                          
                                  
        --borrar el control remito detalle
        delete tblslvcontrolremitodet crd
         where crd.idcontrolremito in (select cr.idcontrolremito
                                         from tblslvcontrolremito cr
                                        where cr.idremito = p_idremito);                                            
        --borrar el control remito
        delete tblslvcontrolremito cr
         where cr.idremito = p_idremito;  

        p_Ok:=1;
        p_error:='';
        commit;
        exception
          when others then
            n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       ' Error: ' || SQLERRM);
           ROLLBACK;                                       
           p_Ok:=0;
           p_error:='Error. Comuniquese con sistemas.';
    END ReversaControlRemito;
    
/**************************************************************************************************
* %v 09/09/2020  ChM - reversa la tarea NO FINALIZADA y libera los articulos para nueva asignación                       
***************************************************************************************************/
  PROCEDURE  ReversaTareaNoFinalizada(p_idTarea         IN  Tblslvtarea.Idtarea%type,
                                      p_Ok              OUT number,
                                      p_error           OUT varchar2)
                                      IS
                                                
     v_modulo               varchar2(100) := 'PKG_SLV_REVERSOS.ReversaTareaNoFinalizada. Tarea: '||p_idTarea;    
     v_idtarea              Tblslvtarea.Idtarea%type:=null;   
    BEGIN
        --verifica si la tarea esta finalizada no se puede reversar!!
        --OJO no mover estado para forzar finalizar esto daña el picking del consolidado
        --este procedimiento no actualiza los pick del consolidado solo elimina la tarea
     begin
        select ta.idtarea
          into v_idtarea       
          from tblslvtarea ta
         where ta.idtarea = p_idTarea
           and ta.cdestado in (select e.cdestado 
                                from tblslvestado e 
                               where e.tipo like '%Tarea%' 
                                 and e.dsestado='Finalizado');
       if v_idtarea is not null then 
          p_Ok:=0;
          p_error:='No se puede reversar una tarea finalizada!!'; 
          return; 
       end if;                          
    exception
      when others then
          null; 
    end;
        --borrar el conteo detalle
        delete tblslvconteodet cond 
         where cond.idconteo in ( select co.idconteo
                                    from tblslvconteo co
                                   where co.idcontrolremito in  (select cr.idcontrolremito
                                                                   from tblslvcontrolremito cr
                                                                  where cr.idremito in (select re.idremito
                                                                                          from tblslvremito re 
                                                                                         where re.idtarea = p_idTarea)));                                                                    
        --borrar el conteo 
        delete tblslvconteo co 
         where co.idcontrolremito in (select cr.idcontrolremito
                                        from tblslvcontrolremito cr
                                       where cr.idremito  in (select re.idremito
                                                                from tblslvremito re 
                                                               where re.idtarea = p_idTarea));                   
                                                
        --borrar el control remito detalle
        delete tblslvcontrolremitodet crd
         where crd.idcontrolremito in (select cr.idcontrolremito
                                         from tblslvcontrolremito cr
                                        where cr.idremito in (select re.idremito
                                                                from tblslvremito re 
                                                               where re.idtarea = p_idTarea));                                            
        --borrar el control remito
        delete tblslvcontrolremito cr
         where cr.idremito in (select re.idremito
                                 from tblslvremito re 
                                where re.idtarea = p_idTarea);  

        --borra remito detalle
        delete tblslvremitodet rd
         where rd.idremito in (select re.idremito
                                 from tblslvremito re 
                                where re.idtarea = p_idTarea);
        --borra remito
        delete tblslvremito r
         where r.idtarea = p_idTarea;
               
        --borrar tarea detalle
        delete tblslvtareadet td
         where td.idtarea = p_idTarea;
               
        --borrar tarea 
        delete tblslvtarea t
         where t.idtarea = p_idTarea;                          

        p_Ok:=1;
        p_error:='';
        commit;
        exception
          when others then
            n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       ' Error: ' || SQLERRM);
           ROLLBACK;                                       
           p_Ok:=0;
           p_error:='Error. Comuniquese con sistemas.';
    END ReversaTareaNoFinalizada;    
 
/**************************************************************************************************
* %v 09/09/2020  ChM - Reversa distribución de Faltantes de Consolidado Pedido
                       no elimina tarea ni ped faltante para permitir nueva distribución
***************************************************************************************************/
  PROCEDURE ReversaDistribFaltante (p_idfaltante      IN  tblslvpedfaltante.idpedfaltante%type,
                                    p_Ok              OUT number,
                                    p_error           OUT varchar2)
                                      IS
                                                
     v_modulo               varchar2(100) := 'PKG_SLV_REVERSOS.ReversaDistribFaltante. idFaltante: '||p_idfaltante;    
     v_error                varchar2(200);   
     
    BEGIN
        --actualiza picking consolidado pedido con valores de las tareas 
      for detpedido in
             (select frel.idconsolidadopedido                     
                from tblslvpedfaltanterel               frel
               where frel.idpedfaltante = p_IdFaltante)
      loop
          for dettarea in
             (Select ta.idconsolidadopedido,       
                     td.cdarticulo,
                     td.qtunidadmedidabasepicking,
                     td.qtpiezaspicking
                from tblslvtarea      ta,
                     tblslvtareadet   td
               where ta.idtarea = td.idtarea
                 and ta.idconsolidadopedido =  detpedido.idconsolidadopedido)
          loop           
          v_error:= 'Error en update tblslvconsolidadopedidodet';
          update tblslvconsolidadopedidodet c
             set c.qtunidadmedidabasepicking = dettarea.qtunidadmedidabasepicking,
                 c.qtpiezaspicking = dettarea.qtpiezaspicking
           where c.idconsolidadopedido = detpedido.idconsolidadopedido
             and c.cdarticulo = dettarea.cdarticulo;
          IF SQL%ROWCOUNT = 0 THEN
           n_pkg_vitalpos_log_general.write(2,
                                            'Modulo: ' || v_modulo ||
                                            '  Detalle Error: ' || v_error);
           p_Ok    := 0;
           p_error:='Error. Comuniquese con Sistemas!';
           ROLLBACK;
           RETURN;
           END IF;          
           end loop;
        end loop;
        --borrar detalle remitos
        delete tblslvremitodet rd
         where rd.idremito in (select re.idremito 
                                 from tblslvremito re
                                 where re.idpedfaltanterel in (select pfrel.idpedfaltanterel 
                                                                 from tblslvpedfaltanterel pfrel
                                                                where pfrel.idpedfaltante = p_idfaltante));
        --borrar remitos
        delete tblslvremito re
         where re.idpedfaltanterel in (select pfrel.idpedfaltanterel 
                                         from tblslvpedfaltanterel pfrel
                                        where pfrel.idpedfaltante = p_idfaltante);
                                        
        --borrar tabla tblslvajustedistribucion
        delete tblslvajustedistribucion aj 
         where aj.iddistribucionpedfaltante in (select dpf.iddistribucionpedfaltante 
                                                  from tblslvdistribucionpedfaltante dpf
                                                 where dpf.idpedfaltanterel in (select pfrel.idpedfaltanterel 
                                                                                  from tblslvpedfaltanterel pfrel
                                                                                 where pfrel.idpedfaltante = p_idfaltante));
        --borrar distribucion involucrada
        delete tblslvdistribucionpedfaltante dpf
        where dpf.idpedfaltanterel in (select pfrel.idpedfaltanterel 
                                         from tblslvpedfaltanterel pfrel
                                        where pfrel.idpedfaltante = p_idfaltante); 
        
        -- finalmente actualizo tblslvconsolidadopedido a estado cerrado
        v_error:= 'Error en update tblslvconsolidadopedido';
        update tblslvconsolidadopedido cp
           set cp.cdestado = 12
         where cp.idconsolidadopedido in (select pfrel.idconsolidadopedido 
                                            from tblslvpedfaltanterel pfrel
                                           where pfrel.idpedfaltante = p_idfaltante);
        IF SQL%ROWCOUNT = 0 THEN
           n_pkg_vitalpos_log_general.write(2,
                                            'Modulo: ' || v_modulo ||
                                            '  Detalle Error: ' || v_error);
           p_Ok    := 0;
           p_error:='Error. Comuniquese con Sistemas!';
           ROLLBACK;
           RETURN;
        END IF; 
        -- actualizo tblslvpedfaltante a estado finalizado así es posible volver a distribuir
        v_error:= 'Error en update tblslvpedfaltante';
        update tblslvpedfaltante pf
           set pf.cdestado = 20
           where pf.idpedfaltante= p_idfaltante;
        IF SQL%ROWCOUNT = 0 THEN
           n_pkg_vitalpos_log_general.write(2,
                                            'Modulo: ' || v_modulo ||
                                            '  Detalle Error: ' || v_error);
           p_Ok    := 0;
           p_error:='Error. Comuniquese con Sistemas!';
           ROLLBACK;
           RETURN;
         END IF; 
        p_Ok:=1;
        p_error:='';
        commit;
        exception
          when others then
            n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       ' Error: ' || SQLERRM);
           ROLLBACK;                                       
           p_Ok:=0;
           p_error:='Error. Comuniquese con sistemas.';
    END ReversaDistribFaltante;   
 
/**************************************************************************************************
* %v 09/09/2020  ChM - ReversaPedFaltante PRIMERO ELIMINAR LA TAREA del pedfaltante asi no falla!
* %v 09/09/2020  ChM - Reversa pedidos Faltantes de Consolidado Pedido elimina faltantes y
*                      actualiza estado consodolidados pedidos  para crear nuevo ped faltante     
***************************************************************************************************/
  PROCEDURE ReversaPedFaltante (p_idfaltante      IN  tblslvpedfaltante.idpedfaltante%type,
                                p_Ok              OUT number,
                                p_error           OUT varchar2)
                                      IS
                                                
     v_modulo               varchar2(100) := 'PKG_SLV_REVERSOS.ReversaPedFaltante. idFaltante: '||p_idfaltante;    
        
    BEGIN
        
        p_Ok:=1;
        p_error:='';
        commit;
        exception
          when others then
            n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       ' Error: ' || SQLERRM);
           ROLLBACK;                                       
           p_Ok:=0;
           p_error:='Error. Comuniquese con sistemas.';
    END ReversaPedFaltante;

end PKG_SLV_REVERSOS;
/
