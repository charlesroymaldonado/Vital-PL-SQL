/*create materialized view view_slvTareas
on prebuilt table
refresh force on demand
as*/
       select ta.idtarea,
              ta.cdtipo cdtipotarea,
              tt.dstarea dstipotarea,              
              cm.idconsolidadom pedido,
              ta.idpersonaarmador,       
              'MC' id_canal,
              ta.cdsucursal, 
              ta.dtinicio,
              ta.dtfin,
              td.cdarticulo,
              nvl((SELECT to_number(trim(ua.vlcontador),'999999999999.99')
                     FROM UnidadesArticulo ua
                    WHERE ua.CDArticulo = td.cdarticulo
                      AND ua.CDUnidad = 'BTO'
                      AND ROWNUM = 1),0) UxB,
              td.qtunidadmedidabase qtsolicitada,                                 
              td.qtunidadmedidabasepicking qtpicking,
              0   idremito,
              '-' nrocarreta                                 
         from tblslvtarea             ta,
              tblslvtareadet          td,            
              tblslvTipoTarea         tt,            
              tblslvconsolidadom      cm
        where ta.idtarea = td.idtarea
          and ta.cdtipo = tt.cdtipo        
          and ta.idconsolidadom = cm.idconsolidadom 
          -- solo tareas iniciadas
          and ta.dtinicio is not null      
              --tipoasignacion pedidos
              union all
       select ta.idtarea,
              ta.cdtipo cdtipotarea,
              tt.dstarea dstipotarea,              
              cp.idconsolidadopedido pedido,
              ta.idpersonaarmador,         
              cp.id_canal,
              ta.cdsucursal, 
              ta.dtinicio,
              ta.dtfin,
              td.cdarticulo,
              pkg_slv_articulo.getuxbarticulo(td.cdarticulo,'BTO') UxB,
              td.qtunidadmedidabase qtsolicitada,                                 
              td.qtunidadmedidabasepicking qtpicking,
              re.idremito,
              re.nrocarreta                      
         from tblslvtarea             ta,
              tblslvtareadet          td,
              tblslvRemito            re,             
              tblslvTipoTarea         tt,
              tblslvConsolidadoPedido cp
         where ta.idtarea = td.idtarea
          and ta.cdtipo = tt.cdtipo               
          and ta.idtarea = re.idtarea          
          and ta.idconsolidadopedido = cp.idconsolidadopedido 
          -- solo tareas iniciadas
          and ta.dtinicio is not null 
              --tipoasignacion comisionista
              union all
       select ta.idtarea,
              ta.cdtipo cdtipotarea,
              tt.dstarea dstipotarea,              
              cc.idconsolidadocomi pedido,
              ta.idpersonaarmador,        
              'CO' id_canal,
              ta.cdsucursal, 
              ta.dtinicio,
              ta.dtfin,  
              td.cdarticulo, 
              pkg_slv_articulo.getuxbarticulo(td.cdarticulo,'BTO') UxB, 
              td.qtunidadmedidabase qtsolicitada,                                 
              td.qtunidadmedidabasepicking qtpicking,
              re.idremito,
              re.nrocarreta                 
         from tblslvtarea             ta,
              tblslvtareadet          td,
              tblslvRemito            re,             
              tblslvTipoTarea         tt,        
              tblslvconsolidadocomi   cc     
        where ta.idtarea = td.idtarea
          and ta.cdtipo = tt.cdtipo               
          and ta.idtarea = re.idtarea         
          and ta.idconsolidadocomi = cc.idconsolidadocomi       
          -- solo tareas iniciadas
          and ta.dtinicio is not null 
            --tipo asignacion faltante de pedido
            union all
       select ta.idtarea,
              ta.cdtipo cdtipotarea,
              tt.dstarea dstipotarea,              
              pf.idpedfaltante pedido,
              ta.idpersonaarmador,          
              'F (TE+VE)' id_canal,
              ta.cdsucursal, 
              ta.dtinicio,
              ta.dtfin,
              td.cdarticulo,
              pkg_slv_articulo.getuxbarticulo(td.cdarticulo,'BTO') UxB,
              td.qtunidadmedidabase qtsolicitada,                                 
              td.qtunidadmedidabasepicking qtpicking,
              re.idremito,
              re.nrocarreta                                   
         from tblslvtarea             ta,
              tblslvtareadet          td,
              tblslvRemito            re,             
              tblslvTipoTarea         tt,                  
              tblslvpedfaltante       pf
        where ta.idtarea = td.idtarea
          and ta.cdtipo = tt.cdtipo               
          and ta.idtarea = re.idtarea         
          and ta.idpedfaltante = pf.idpedfaltante     
          -- solo tareas iniciadas
          and ta.dtinicio is not null 
