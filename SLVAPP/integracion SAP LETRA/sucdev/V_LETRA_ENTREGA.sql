CREATE OR REPLACE VIEW V_LETRA_ENTREGA AS
SELECT TRIM (cdsucursal) || PedidoNumero idpedido,
            material,
            SUM (cantidad) cantidad,
            ROUND (SUM (precio), 2) precio
       FROM (SELECT cp.idconsolidado_pedido PedidoNumero,
                    dm.cdarticulo material,
                    fc.cdsucursal,
                    dm.qtunidadmedidabase cantidad,
                    dm.amlinea precio
               FROM tblslv_consolidado_pedido cp,
                    tblslv_consolidado_pedido_rel re,
                    documentos fc,
                    movmateriales mm,
                    detallemovmateriales dm,
                    pedidos pe
              WHERE     cp.idconsolidado_pedido = re.idconsolidado_pedido
                    AND fc.idmovmateriales = mm.idmovmateriales
                    AND dm.idmovmateriales = mm.idmovmateriales
                    AND fc.cdcomprobante LIKE 'FC%'
                    AND pe.icestadosistema IN (4, 5, 6)
                    AND dm.cdarticulo NOT IN
                           (SELECT cdarticulo FROM articulosnocomerciales)
                    AND mm.idpedido = re.idpedido_pos
                    AND pe.idpedido = re.idpedido_pos
                    AND fc.dtdocumento > TRUNC (SYSDATE) - 15)
   GROUP BY cdsucursal, PedidoNumero, material
   UNION ALL
   --Pedidos de SA Modificados
   (  SELECT TRIM (Centro) || PedidoNumero idpedido,
             material,
             SUM (cantidad) cantidad,
             ROUND (SUM (precio), 2) precio
        FROM (                                                      --Facturas
              SELECT     fc.sqcomprobante
                      || SUBSTR (fc.cdcomprobante, 4, 1)
                      || SUBSTR (fc.cdpuntoventa, 1, 4)
                         PedidoNumero,
                      mm.id_canal,
                      fc.cdsucursal centro,
                      DECODE (
                         TRIM (a.cdSector),
                         '11', 'CA' || SUBSTR (TRIM (fc.cdsucursal), 3, 2),
                         '12', 'CA' || SUBSTR (TRIM (fc.cdsucursal), 3, 2),
                         SUBSTR (TRIM (fc.cdsucursal), 3, 2) || '01    ')
                         almacen,
                      e.dsrazonsocial cliente,
                      p.dsprovincia provincia,
                      l.dslocalidad localidad,
                      de.cdcodigopostal codpostal,
                      de.dscalle calle,
                      de.dsnumero numero,
                      dmm.cdarticulo material,
                      dmm.qtunidadmedidabase cantidad,
                      (CASE
                          WHEN (   TRIM (dmm.cdunidamedida) = 'BTO'
                                OR TRIM (dmm.cdunidamedida) = 'CA'
                                OR TRIM (dmm.cdunidamedida) = 'UN')
                          THEN
                             'UN'
                          WHEN (TRIM (dmm.cdunidamedida) = 'PZA'
                                OR TRIM (dmm.cdunidamedida) = 'KG')
                          THEN
                             'KG'
                       END)
                         cdunidadmedida,
                      dmm.amlinea precio,
                      (SYSDATE + 1) dtentrega,
                      '' AS dsobservacion
                 FROM movmateriales mm,
                      detallemovmateriales dmm,
                      documentos fc,
                      entidades e,
                      direccionesentidades de,
                      provincias p,
                      localidades l,
                      articulos a
                WHERE     mm.idmovmateriales = dmm.idmovmateriales
                      AND fc.idmovmateriales = mm.idmovmateriales
                      AND fc.identidadreal = e.identidad
                      AND mm.id_canal = 'SA'                           --Salon
                      AND de.identidad = e.identidad
                      AND mm.cdtipodireccion = de.cdtipodireccion
                      AND mm.sqdireccion = de.sqdireccion
                      AND a.cdarticulo = dmm.cdarticulo
                      AND dmm.cdarticulo NOT IN
                             ( SELECT cdarticulo FROM articulosnocomerciales)
                      AND de.icactiva = 1
                      AND mm.idpedido IS NOT NULL
                      AND NVL (dmm.dsobservacion, 'x') NOT IN
                             ('(*)     ', 'DEL     ')
                      AND p.cdprovincia = de.cdprovincia
                      AND p.cdpais = de.cdpais
                      AND l.cdlocalidad = de.cdlocalidad
                      AND p.cdprovincia = l.cdprovincia
                      AND fc.dtdocumento > TRUNC (SYSDATE) - 15
              UNION ALL
              --Notas de credito relacionadas
              SELECT    fc.sqcomprobante
                     || SUBSTR (fc.cdcomprobante, 4, 1)
                     || SUBSTR (fc.cdpuntoventa, 1, 4)
                        PedidoNumero,
                     mm.id_canal,
                     fc.cdsucursal centro,
                     DECODE (TRIM (a.cdSector),
                             '11', 'CA' || SUBSTR (TRIM (fc.cdsucursal), 3, 2),
                             '12', 'CA' || SUBSTR (TRIM (fc.cdsucursal), 3, 2),
                             SUBSTR (TRIM (fc.cdsucursal), 3, 2) || '01    ')
                        almacen,
                     e.dsrazonsocial cliente,
                     p.dsprovincia provincia,
                     l.dslocalidad localidad,
                     de.cdcodigopostal codpostal,
                     de.dscalle calle,
                     de.dsnumero numero,
                     dmm.cdarticulo material,
                     (dmm.qtunidadmedidabase * -1) cantidad,
                     (CASE
                         WHEN (   TRIM (dmm.cdunidamedida) = 'BTO'
                               OR TRIM (dmm.cdunidamedida) = 'CA'
                               OR TRIM (dmm.cdunidamedida) = 'UN')
                         THEN
                            'UN'
                         WHEN (TRIM (dmm.cdunidamedida) = 'PZA'
                               OR TRIM (dmm.cdunidamedida) = 'KG')
                         THEN
                            'KG'
                      END)
                        cdunidadmedida,
                     (dmm.amlinea * -1) precio,
                     (SYSDATE + 1) dtentrega,
                     '' AS dsobservacion
                FROM movmateriales mm,
                     detallemovmateriales dmm,
                     documentos nc,
                     entidades e,
                     direccionesentidades de,
                     provincias p,
                     localidades l,
                     articulos a,
                     tbldocumento_control dco,
                     documentos fc
               WHERE     mm.idmovmateriales = dmm.idmovmateriales
                     AND nc.idmovmateriales = mm.idmovmateriales
                     AND nc.identidadreal = e.identidad
                     AND mm.id_canal = 'SA'                            --Salon
                     AND de.identidad = e.identidad
                     AND mm.cdtipodireccion = de.cdtipodireccion
                     AND mm.sqdireccion = de.sqdireccion
                     AND a.cdarticulo = dmm.cdarticulo
                     AND dmm.cdarticulo NOT IN
                            (SELECT cdarticulo FROM articulosnocomerciales)
                     AND de.icactiva = 1
                     AND dco.iddoctrxgen = nc.iddoctrx
                     AND fc.iddoctrx = dco.iddoctrx
                     AND NVL (dmm.dsobservacion, 'x') NOT IN
                            ('(*)     ', 'DEL     ')
                     AND p.cdprovincia = de.cdprovincia
                     AND p.cdpais = de.cdpais
                     AND l.cdlocalidad = de.cdlocalidad
                     AND p.cdprovincia = l.cdprovincia
                     AND nc.dtdocumento > TRUNC (SYSDATE) - 4)
    GROUP BY TRIM (Centro) || PedidoNumero, material)
;
