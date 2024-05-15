       select 'N/A' remito_carreta,
              to_date('01/01/9999','dd/mm/yyyy') dtinicioremito,
              to_date('01/01/9999','dd/mm/yyyy') dtfinremito, 
              tt.dstarea tipoAsignacion,
              ta.idtarea,
              cm.idconsolidadom pedido,
              p.dsnombre || p.dsapellido armador,
              'MC' id_canal,
              cm.cdsucursal ||'- '||su.dssucursal sucursal,
              ta.dtinicio,
              ta.dtfin,
              decode(sum(nvl(td.qtpiezaspicking,0)),0,                    
              sum(td.qtunidadmedidabasepicking),
              sum(td.qtpiezaspicking)) Unidades              
         from tblslvtarea             ta,
              tblslvtareadet          td,            
              tblslvTipoTarea         tt,
              Personas                p,
              tblslvconsolidadom      cm,
              sucursales              su
        where ta.idtarea = td.idtarea
          and ta.cdtipo = tt.cdtipo 
          and ta.idpersonaarmador = p.idpersona
          and ta.idconsolidadom = cm.idconsolidadom
          and cm.cdsucursal = su.cdsucursal  
          -- solo tareas iniciadas
          and ta.dtinicio is not null 
     group by tt.dstarea,
              ta.idtarea,
              cm.idconsolidadom,
              p.dsnombre,
              p.dsapellido,
              cm.cdsucursal,
              su.dssucursal,              
              ta.dtinicio,
              ta.dtfin 
              --tipoasignacion pedidos
              union all
       select re.idremito||' - '||re.nrocarreta remito_carreta,
              re.dtremito dtinicioremito,
              re.dtupdate dtfinremito, 
              tt.dstarea tipoAsignacion,
              ta.idtarea,
              cp.idconsolidadopedido pedido,
              p.dsnombre || p.dsapellido armador,
              cp.id_canal,
              cp.cdsucursal ||'- '||su.dssucursal sucursal,
              ta.dtinicio,
              ta.dtfin,
              decode(sum(nvl(td.qtpiezaspicking,0)),0,                    
              sum(td.qtunidadmedidabasepicking),
              sum(td.qtpiezaspicking)) Unidades              
         from tblslvtarea             ta,
              tblslvtareadet          td,
              tblslvRemito            re,             
              tblslvTipoTarea         tt,
              Personas                p,
              tblslvConsolidadoPedido cp,
              sucursales              su
        where ta.idtarea = td.idtarea
          and ta.cdtipo = tt.cdtipo               
          and ta.idtarea = re.idtarea 
          and ta.idpersonaarmador = p.idpersona
          and ta.idconsolidadopedido = cp.idconsolidadopedido
          and cp.cdsucursal = su.cdsucursal  
          -- solo tareas iniciadas
          and ta.dtinicio is not null 
     group by re.idremito,
              re.nrocarreta,
              re.dtremito,
              re.dtupdate,
              tt.dstarea,
              ta.idtarea,
              cp.idconsolidadopedido,
              p.dsnombre,
              p.dsapellido,
              cp.id_canal,
              cp.cdsucursal,
              su.dssucursal,              
              ta.dtinicio,
              ta.dtfin 
              --tipoasignacion comisionista
              union all
       select re.idremito||' - '||re.nrocarreta carreta,
              re.dtremito dtinicioremito,
              re.dtupdate dtfinremito, 
              tt.dstarea tipoAsignacion,
              ta.idtarea,
              cc.idconsolidadocomi pedido,
              p.dsnombre || p.dsapellido armador,
              cp.id_canal,
              cp.cdsucursal ||'- '||su.dssucursal sucursal,
              ta.dtinicio,
              ta.dtfin,                    
              decode(sum(nvl(td.qtpiezaspicking,0)),0,                        
              sum(td.qtunidadmedidabasepicking),
              sum(td.qtpiezaspicking)) Unidades               
         from tblslvtarea             ta,
              tblslvtareadet          td,
              tblslvRemito            re,             
              tblslvTipoTarea         tt,
              Personas                p,
              tblslvConsolidadoPedido cp,
              tblslvconsolidadocomi   cc,
              sucursales              su
        where ta.idtarea = td.idtarea
          and ta.cdtipo = tt.cdtipo               
          and ta.idtarea = re.idtarea 
          and ta.idpersonaarmador = p.idpersona
          and ta.idconsolidadocomi = cc.idconsolidadocomi
          and cp.idconsolidadocomi = cc.idconsolidadocomi
          and cp.cdsucursal = su.cdsucursal  
          -- solo tareas iniciadas
          and ta.dtinicio is not null 
     group by re.idremito,
              re.nrocarreta,
              re.dtremito,
              re.dtupdate,
              tt.dstarea,
              ta.idtarea,
              cc.idconsolidadocomi,
              p.dsnombre,
              p.dsapellido,
              cp.id_canal,
              cp.cdsucursal,
              su.dssucursal,              
              ta.dtinicio,
              ta.dtfin 
            --tipo asignacion faltante de pedido
            union all
       select re.idremito||' - '||re.nrocarreta remito_carreta,
              re.dtremito dtinicioremito,
              re.dtupdate dtfinremito, 
              tt.dstarea tipoAsignacion,
              ta.idtarea,
              pf.idpedfaltante pedido,
              p.dsnombre || p.dsapellido armador,
              'FMC',
              ta.cdsucursal ||'- '||su.dssucursal sucursal,
              ta.dtinicio,
              ta.dtfin,
              decode(sum(nvl(td.qtpiezaspicking,0)),0,                    
              sum(td.qtunidadmedidabasepicking),
              sum(td.qtpiezaspicking)) Unidades              
         from tblslvtarea             ta,
              tblslvtareadet          td,
              tblslvRemito            re,             
              tblslvTipoTarea         tt,
              Personas                p,             
              tblslvpedfaltante       pf,
              sucursales              su
        where ta.idtarea = td.idtarea
          and ta.cdtipo = tt.cdtipo               
          and ta.idtarea = re.idtarea 
          and ta.idpersonaarmador = p.idpersona
          and ta.idpedfaltante = pf.idpedfaltante
          and ta.cdsucursal = su.cdsucursal  
          -- solo tareas iniciadas
          and ta.dtinicio is not null 
     group by re.idremito,
              re.nrocarreta,
              re.dtremito,
              re.dtupdate,
              tt.dstarea,
              ta.idtarea,
              pf.idpedfaltante,
              p.dsnombre,
              p.dsapellido,              
              ta.cdsucursal,
              su.dssucursal,              
              ta.dtinicio,
              ta.dtfin 