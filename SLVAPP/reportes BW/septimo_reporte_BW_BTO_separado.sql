               
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
 
select   A.idconsolidadom,
        -- A.ID_CANAL,
      --   A.DTINICIO,
      --   A.DTFIN,
         A.SUCURSAL,         
         ROUND(SUM(A.qtUnidades_solicitadas_pedido/A.UxB)) BTO_SOL_PEDIDO,
         ROUND(SUM(A.qtUnidades_picking_pedido/A.UxB)) BTO_PIK_PEDIDO
    from (select 
                 cp.idconsolidadom,
                -- cp.id_canal,
               --  cp.dtinsert dtinicio,
             --    cp.dtupdate dtfin,
                 cp.cdsucursal ||'- '||su.dssucursal sucursal,
                 cpd.cdarticulo,
                 nvl((SELECT to_number(trim(ua.vlcontador),'999999999999.99')
                  FROM UnidadesArticulo ua
                 WHERE ua.CDArticulo = cpd.cdarticulo
                   AND ua.CDUnidad = 'BTO'
                   AND ROWNUM = 1),1) UxB,                    
                 cpd.qtunidadesmedidabase qtUnidades_solicitadas_pedido,    
                 nvl(cpd.qtunidadmedidabasepicking,0) qtUnidades_picking_pedido                
            from tblslvconsolidadopedido      cp,
                 tblslvconsolidadopedidodet   cpd,
                 sucursales                   su
           where cp.idconsolidadom = &ped             
             and cp.idconsolidadopedido = cpd.idconsolidadopedido
             and cp.cdsucursal = su.cdsucursal
             and cpd.qtpiezas = 0 )A
group by A.idconsolidadom,          
       --  A.ID_CANAL,
        -- A.DTINICIO,
       --  A.DTFIN,
         A.SUCURSAL    
order by A.idconsolidadom       ;  
   
select * from tblslvconsolidadopedido cp where cp.idconsolidadom = &ped;
