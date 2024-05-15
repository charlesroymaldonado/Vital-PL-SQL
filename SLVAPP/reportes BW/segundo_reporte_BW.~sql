       select cp.idconsolidadopedido pedido,
              cp.dtinsert dtinicio,
              cp.dtupdate dtfin,
              p.dsnombre || p.dsapellido armador,
              cp.id_canal,
              cp.cdsucursal ||'- '||su.dssucursal sucursal,
              decode(sum(nvl(cpd.qtpiezas,0)),0,                    
              sum(cpd.qtunidadesmedidabase),
              sum(cpd.qtpiezas)) qtUnidades_solicitadas,    
              decode(sum(nvl(cpd.qtpiezas,0)),0,                    
              sum(nvl(cpd.qtunidadmedidabasepicking,0)),
              sum(nvl(cpd.qtpiezaspicking,0))) qtUnidades_picking                
         from tblslvtarea                         ta,                     
              tblslvTipoTarea                     tt,
              Personas                            p,
              tblslvConsolidadoPedido             cp,
              tblslvconsolidadopedidodet          cpd,
              sucursales                          su
        where ta.cdtipo = tt.cdtipo  
          and ta.idpersonaarmador = p.idpersona
          and cp.idconsolidadopedido = cpd.idconsolidadopedido
          and ta.idconsolidadopedido = cp.idconsolidadopedido
          and cp.cdsucursal = su.cdsucursal         
     group by tt.dstarea,
              ta.idtarea,
              cp.idconsolidadopedido,
              cp.dtinsert,
              cp.dtupdate,
              p.dsnombre,
              p.dsapellido,
              cp.id_canal,
              cp.cdsucursal,
              su.dssucursal  
              --consolidado comisionistas  
              union all
       select cp.idconsolidadopedido pedido,
              cp.dtinsert dtinicio,
              cp.dtupdate dtfin,
              p.dsnombre || p.dsapellido armador,
              cp.id_canal,
              cp.cdsucursal ||'- '||su.dssucursal sucursal,
               decode(sum(nvl(cpd.qtpiezas,0)),0,                    
              sum(cpd.qtunidadesmedidabase),
              sum(cpd.qtpiezas)) qtUnidades_solicitadas,    
              decode(sum(nvl(cpd.qtpiezas,0)),0,                    
              sum(nvl(cpd.qtunidadmedidabasepicking,0)),
              sum(nvl(cpd.qtpiezaspicking,0))) qtUnidades_picking              
         from tblslvtarea                         ta,                     
              tblslvTipoTarea                     tt,
              Personas                            p,
              tblslvConsolidadoPedido             cp,
              Tblslvconsolidadocomi               cc,
              tblslvconsolidadopedidodet          cpd,
              sucursales                          su
        where ta.cdtipo = tt.cdtipo  
          and ta.idpersonaarmador = p.idpersona
          and cp.idconsolidadopedido = cpd.idconsolidadopedido
          and cp.idconsolidadocomi = cc.idconsolidadocomi
          and ta.idconsolidadocomi = cc.idconsolidadocomi
          and cp.cdsucursal = su.cdsucursal         
     group by tt.dstarea,
              ta.idtarea,
              cp.dtinsert,
              cp.dtupdate,
              cp.idconsolidadopedido,
              p.dsnombre,
              p.dsapellido,
              cp.id_canal,
              cp.cdsucursal,
              su.dssucursal                            
              
            
