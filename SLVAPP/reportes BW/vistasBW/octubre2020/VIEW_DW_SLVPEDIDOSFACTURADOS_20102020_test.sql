CREATE OR REPLACE VIEW VIEW_DW_SLVPEDIDOSFACTURADOS AS
SELECT A.PEDIDO,
          A.id_canal,
          A.idpedidoPOS,
          A.idpersona,
          decode(A.id_canal,'CO',
                (select TRIM(NVL (e.dsrazonsocial, e.dsnombrefantasia))||' ('||TRIM(e.cdcuit)||')' razonsocial
                   from tblslvconsolidadocomi cc, entidades e
                  where cc.idconsolidadocomi=A.pedido
                    and cc.idcomisionista=e.identidad),'-') NOMCOMISIONISTA,
          TO_CHAR (A.dtaplicacion, 'yyyymmdd') AS FECHATOMAPEDIDO,
          TO_CHAR (A.dtaplicacion, 'HH24:MI:SS') AS HORATOMAPEDIDO,
          TO_CHAR (A.sincronizacion, 'yyyymmdd') AS FECHASINCRONIZACION,
          TO_CHAR (A.sincronizacion, 'HH24:MI:SS') AS HORASINCRONIZACION,
          TO_CHAR (A.dtinsert, 'yyyymmdd') AS FECHAINICIOARMADO,
          TO_CHAR (A.dtinsert, 'HH24:MI:SS') AS HORAINICIOARMADO,
          TO_CHAR (A.dtupdate, 'yyyymmdd') AS FECHAFINARMADO,
          TO_CHAR (A.dtupdate, 'HH24:MI:SS') AS HORAFINARMADO,
          A.cdsucursal,
          TO_CHAR (A.dtliberacion, 'yyyymmdd') AS FECHALIBERACION,
          TO_CHAR (A.dtliberacion, 'HH24:MI:SS') AS HORALIBERACION,
          TO_CHAR (A.dtbajada_pedido, 'yyyymmdd') AS FECHABAJADA_PEDIDO,
          TO_CHAR (A.dtbajada_pedido, 'HH24:MI:SS') AS HORABAJADA_PEDIDO
     FROM (SELECT NVL2 (cp.idconsolidadocomi,
                        cp.idconsolidadocomi,
                        cp.idconsolidadopedido)
                     pedido,
                  cp.id_canal,
                  pe.dtaplicacion,
                  pe.idpedido idpedidoPOS,
                  cp.idpersona,
                  NVL(null/*(select l.dtlog from logtimestamp l
                    where l.id = pe.iddoctrx
                      and l.cdestado like '-5%')*/, pe.dtaplicacion) sincronizacion,
                  cp.dtinsert,
                  cp.dtupdate,
                  cp.cdsucursal,
                  (SELECT MAX (lp.dtmodif)
                     FROM tbllogestadopedidos lp
                    WHERE lp.icestadosistema = 2
                          AND lp.idpedido = pe.idpedido)
                     dtliberacion,
                  (SELECT cm.dtinsert
                     FROM tblslvconsolidadom cm
                    WHERE cm.idconsolidadom = cp.idconsolidadom
                      AND cm.cdsucursal = cp.cdsucursal)
                     dtbajada_pedido
             FROM tblslvconsolidadopedido cp,
                  tblslvconsolidadopedidorel cprel,
                  pedidos pe
            WHERE cp.idconsolidadopedido = cprel.idconsolidadopedido
                  AND cp.cdsucursal = cprel.cdsucursal
                  AND cprel.idpedido = pe.idpedido) A;