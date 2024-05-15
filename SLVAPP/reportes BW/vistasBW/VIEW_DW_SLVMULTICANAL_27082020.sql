CREATE OR REPLACE VIEW VIEW_DW_SLVMULTICANAL AS
select cm.idconsolidadom pedido,
                 'MC' id_canal,
                 TO_CHAR (cm.dtinsert, 'yyyymmdd') AS FECHAINICIO,
                 TO_CHAR (cm.dtinsert, 'HH24:MI:SS') AS HORAINICIO,
                 cm.dtinsert dtinicio,
                 TO_CHAR (cm.dtupdate, 'yyyymmdd') AS FECHAFIN,
                 TO_CHAR (cm.dtupdate, 'HH24:MI:SS') AS HORAFIN,
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
