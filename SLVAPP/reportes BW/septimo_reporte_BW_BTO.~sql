               
  select A.PEDIDO,         
         A.ID_CANAL,
         A.DTINICIO,
         A.DTFIN,
         A.SUCURSAL,
         ROUND(SUM(A.qtUnidad_sol_consolidado/A.UxB)) BTO_SOL_CONSOLIDADO,
         ROUND(SUM(A.qtUnidad_picking_consolidado/A.UxB)) BTO_PIK_CONSOLIDADO        
    from (select cm.idconsolidadom pedido,                 
                 'MC' id_canal,
                 cm.dtinsert dtinicio,
                 cm.dtupdate dtfin,
                 cm.cdsucursal ||'- '||su.dssucursal sucursal,
                 cmd.cdarticulo,
                 nvl((SELECT to_number(trim(ua.vlcontador),'999999999999.99')
                  FROM UnidadesArticulo ua
                 WHERE ua.CDArticulo = cmd.cdarticulo
                   AND ua.CDUnidad = 'BTO'
                   AND ROWNUM = 1),1) UxB,
                 cmd.qtunidadmedidabase qtUnidad_sol_consolidado,    
                 nvl(cmd.qtunidadmedidabasepicking,0) qtUnidad_picking_consolidado                      
            from tblslvconsolidadom           cm,
                 tblslvconsolidadomdet        cmd,                
                 sucursales            su
           where cm.idconsolidadom = cmd.idconsolidadom    
             and cm.cdsucursal = su.cdsucursal
           --  and cm.idconsolidadom = &ped
                 )A
group by A.PEDIDO,                
         A.ID_CANAL,
         A.DTINICIO,
         A.DTFIN,
         A.SUCURSAL    
order by A.PEDIDO           ;        
