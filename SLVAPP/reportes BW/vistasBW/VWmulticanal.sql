CREATE OR REPLACE VIEW VIEW_DW_SLVMULTICANAL AS
select cm.idconsolidadom pedido,                
                 'MC' id_canal,
                 cm.dtinsert dtinicio,
                 cm.dtupdate dtfin,
                 cm.cdsucursal,
                 cmd.cdarticulo,
                 nvl((SELECT to_number(trim(ua.vlcontador),'999999999999.99')
                  FROM UnidadesArticulo ua
                 WHERE ua.CDArticulo = cmd.cdarticulo
                   AND ua.CDUnidad = 'BTO'
                   AND ROWNUM = 1),1) UxB,
                 cmd.qtunidadmedidabase qtsolictada,
                 nvl(cmd.qtunidadmedidabasepicking,0) qtpicking
            from tblslvconsolidadom           cm,
                 tblslvconsolidadomdet        cmd                          
           where cm.idconsolidadom = cmd.idconsolidadom          
           --  and cm.idconsolidadom = &ped
order by PEDIDO
;
