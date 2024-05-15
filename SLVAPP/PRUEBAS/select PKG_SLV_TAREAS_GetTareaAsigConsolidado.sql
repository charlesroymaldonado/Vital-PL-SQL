 select
     distinct  
              COALESCE
              (ta.idpedfaltante,
              ta.idconsolidadom,
              ta.idconsolidadopedido,
              ta.idconsolidadocomi
              )idConsolidado,
              ta.idtarea,
              decode(ta.cdmodoingreso,0,'HandHeld','Manual') modoingreso,
              p.dsnombre||' '||p.dsapellido Armador,
              e.dsestado Estado,
              --solo muestro remito en consolidado pedido los demás cero
              decode(&p_tipoTarea,&c_TareaConsolidadoPedido,nvl(re.idremito,0),0) idremito,
              decode(&p_tipoTarea,&c_TareaConsolidadoPedido,nvl(re.nrocarreta,0),0) roll                               
         from tblslvtarea ta 
    left join (tblslvremito re)
           on (re.idtarea= ta.idtarea),
              personas p,
              tblslvestado e
        where ta.idpersonaarmador = p.idpersona
          and ta.cdestado = e.cdestado
          and case when &p_tipoTarea = &c_TareaConsolidadoMulti        
                    and ta.idconsolidadom = &p_idConsolidado 
                    and ta.cdtipo = &p_tipoTarea then 1
                   when &p_tipoTarea = &c_TareaConsolidaMultiFaltante  
                    and ta.idconsolidadom = &p_idConsolidado 
                    and ta.cdtipo = &p_tipoTarea then 1
                   when &p_tipoTarea = &c_TareaConsolidadoPedido       
                    and ta.idconsolidadopedido = &p_idConsolidado 
                    and ta.cdtipo = &p_tipoTarea then 1 
                   --si es faltante devuelve los 40 y 44 
                   when &p_tipoTarea in (&c_TareaConsolidaPedidoFaltante,&c_TareaFaltanteConsolFaltante) 
                    and ta.idpedfaltante = &p_idConsolidado 
                    and ta.cdtipo in (&c_TareaConsolidaPedidoFaltante,&c_TareaFaltanteConsolFaltante)  then 1                   
                   when &p_tipoTarea = &c_TareaConsolidadoComi         
                    and ta.idconsolidadocomi = &p_idConsolidado 
                    and ta.cdtipo = &p_tipoTarea then 1
                   when &p_tipoTarea = &c_TareaConsolidadoComiFaltante 
                    and ta.idconsolidadocomi = &p_idConsolidado 
                    and ta.cdtipo = &p_tipoTarea then 1       
              end = 1             
