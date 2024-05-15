CREATE OR REPLACE VIEW VIEW_DW_SLVCONTROLREMITO AS
SELECT NVL (ta.idtarea, 0) idtarea,
            NVL (ta.cdtipo, 0) cdtipotarea,
            NVL (
               NVL (ta.idconsolidadopedido, ta.idconsolidadocomi),
               (SELECT DISTINCT cp.idconsolidadopedido
                  FROM tblslvremito r1,
                       tblslvpedfaltanterel pfr,
                       tblslvconsolidadopedido cp
                 WHERE     r1.idpedfaltanterel = pfr.idpedfaltanterel
                       AND r1.idremito = re.idremito
                       AND pfr.idconsolidadopedido = cp.idconsolidadopedido))
               pedido,
            TO_CHAR (cr.dtinicio, 'yyyymmdd') AS FECHAINICIOCONTROL,
            TO_CHAR (cr.dtinicio, 'HH24:MI:SS') AS HORAINICIOCONTROL,
            cr.dtinicio dtinicio,
            TO_CHAR (cr.dtfin, 'yyyymmdd') AS FECHAFINCONTROL,
            TO_CHAR (cr.dtfin, 'HH24:MI:SS') AS HORAFINCONTROL,
            cr.dtfin,
            NVL2 (
               ta.idconsolidadocomi,
               'CO',
               NVL2 (
                  ta.idconsolidadopedido,
                  (SELECT DISTINCT cp.id_canal
                     FROM tblslvconsolidadopedido cp
                    WHERE cp.idconsolidadopedido = ta.idconsolidadopedido),
                  (SELECT DISTINCT cp.id_canal
                     FROM tblslvremito r1,
                          tblslvpedfaltanterel pfr,
                          tblslvconsolidadopedido cp
                    WHERE     r1.idpedfaltanterel = pfr.idpedfaltanterel
                          AND r1.idremito = re.idremito
                          AND pfr.idconsolidadopedido = cp.idconsolidadopedido)))
               Canal,
            re.idremito,
            re.nrocarreta,
            cr.idpersonacontrol,
            NVL (ta.idpersonaarmador, 'Distribución Automática') idArmador,
            re.cdsucursal,
            A.cdarticulo,
            A.UxB VLUxB,
            A.qtbase_UN,
            A.cantidaddif qtajuste_UN,
            CASE
               WHEN A.Cantidaddif > 0 THEN 'S'
               WHEN A.Cantidaddif < 0 THEN 'F'
               ELSE '-'
            END
               TipoAjuste
       FROM (SELECT B.cdarticulo,
                    B.idcontrolremito,
                    --valida pesables
                    NVL (DECODE (B.cantpiezas, 0, B.cantbase, B.cantpiezas), 0)
                       qtbase_UN,
                    DECODE (B.difpiezas, 0, B.difbase, B.difpiezas) cantidaddif,
                    NVL2 (
                       B.cantpiezas,
                       pkg_slv_articulo.
                       getuxbarticulo (B.cdarticulo,
                                       DECODE (B.cantpiezas, 0, 'BTO', 'KG')),
                       1)
                       UxB
               FROM (SELECT crd.cdarticulo,
                            crd.idcontrolremito,
                            (crd.qtdiferenciaunidadmbase
                             - NVL (crd.qtajusteunidadmbase, 0))
                               difbase,
                            crd.qtdiferenciapiezas
                            - NVL (crd.qtajustepiezas, 0)
                               difpiezas,
                            crd.qtunidadmedidabasepicking cantbase,
                            crd.qtpiezaspicking cantpiezas
                       FROM tblslvcontrolremitodet crd --  where crd.idcontrolremito = &v_idControl
                                                      ) B) A,
            tblslvcontrolremito cr,
               tblslvremito re
            LEFT JOIN
               (tblslvtarea ta)
            ON (re.idtarea = ta.idtarea)
      WHERE A.idcontrolremito = cr.idcontrolremito
            AND cr.idremito = re.idremito
   ORDER BY re.idremito
;
