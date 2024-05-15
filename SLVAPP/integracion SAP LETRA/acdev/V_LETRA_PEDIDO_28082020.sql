CREATE OR REPLACE VIEW V_LETRA_PEDIDO AS
SELECT TRIM (Centro) || PedidoNumero idpedido,
            id_canal Canal,
            Centro,
            origen,
            DECODE (vendedor, ' ', telema, vendedor) vendedor,
            almacen,
            cliente,
            cdcuit,
            provincia,
            localidad,
            codpostal,
            calle,
            numero,
            material,
            SUM (cantidad) cantidad,
            cdunidadmedida,
            ROUND (SUM (precio), 2) precio,
            TRUNC (dtaplicacion) dtpedido,
            TRUNC (dtentrega) dtentrega,
            dsobservacion
       FROM (SELECT cp.idconsolidado_pedido PedidoNumero,
                    pe.id_canal,
                    sa.cdsucursal_armado centro,
                    d.cdsucursal origen,
                    ve.dsnombre || ' ' || ve.dsapellido AS vendedor,
                    te.dsnombre || ' ' || te.dsapellido AS telema,
                    DECODE (
                       TRIM (a.cdSector),
                       '11', 'CA' || SUBSTR (TRIM (sa.cdsucursal_armado), 3, 2),
                       '12', 'CA' || SUBSTR (TRIM (sa.cdsucursal_armado), 3, 2),
                       SUBSTR (TRIM (sa.cdsucursal_armado), 3, 2) || '01    ')
                       almacen,
                    e.dsrazonsocial cliente,
                    TRIM (REPLACE (e.cdcuit, '-', '')) cdcuit,
                    p.dsprovincia provincia,
                    l.dslocalidad localidad,
                    de.cdcodigopostal codpostal,
                    de.dscalle calle,
                    de.dsnumero numero,
                    dp.cdarticulo material,
                    dp.qtunidadmedidabase cantidad,
                    (CASE
                        WHEN (   TRIM (dp.cdunidadmedida) = 'BTO'
                              OR TRIM (dp.Cdunidadmedida) = 'CA'
                              OR TRIM (dp.Cdunidadmedida) = 'UN')
                        THEN
                           'UN'
                        WHEN (TRIM (dp.Cdunidadmedida) = 'PZA'
                              OR TRIM (dp.Cdunidadmedida) = 'KG')
                        THEN
                           'KG'
                     END)
                       cdunidadmedida,
                    dp.amlinea precio,
                    pe.dtaplicacion,
                    pe.dtentrega,
                    op.dsobservacion
               FROM tblslv_consolidado_pedido cp,
                    pedidos pe,
                    detallepedidos dp,
                    tblslv_consolidado_pedido_rel re,
                    documentos d,
                    entidades e,
                    direccionesentidades de,
                    provincias p,
                    localidades l,
                    tblsucursalarmado sa,
                    observacionespedido op,
                    articulos a,
                    tblslv_consolidado con,
                    personas ve,
                    personas te
              WHERE     cp.idconsolidado_pedido = re.idconsolidado_pedido
                    AND cp.cdsucursal = re.cdsucursal
                    AND re.idpedido_pos = pe.idpedido
                    AND d.iddoctrx = pe.iddoctrx
                    AND dp.idpedido = pe.idpedido
                    AND ve.idpersona(+) = pe.idvendedor
                    AND te.idpersona(+) = pe.idpersonaresponsable
                    AND e.identidad = d.identidadreal
                    AND de.identidad = d.identidadreal
                    AND pe.id_canal <> 'CO'               --No es comisionista
                    AND (pe.iczonafranca = 0 OR pe.iczonafranca IS NULL) --No es exportacion
                    AND pe.icestadosistema = 3                    --A facturar
                    AND de.cdtipodireccion = cp.cdtipodireccion
                    AND de.sqdireccion = cp.sqdireccion
                    AND de.cdprovincia = p.cdprovincia
                    AND con.idconsolidado = cp.idconsolidado
                    AND con.cdsucursal = cp.cdsucursal
                    AND con.fecha_consolidado > TRUNC (SYSDATE) - 1
                    AND de.cdlocalidad = l.cdlocalidad
                    AND d.cdsucursal = sa.cdsucursal
                    AND a.cdarticulo = dp.cdarticulo
                    AND op.idpedido(+) = pe.idpedido
                    AND p.cdprovincia = l.cdprovincia
                    --AND sa.cdsucursal_armado IN('0016    ')
                    AND dp.icresppromo <> 1                  --saco las promos
                                           /*and de.icactiva = 1*/
            )
   GROUP BY PedidoNumero,
            id_canal,
            centro,
            origen,
            vendedor,
            telema,
            almacen,
            cliente,
            cdcuit,
            provincia,
            localidad,
            codpostal,
            calle,
            numero,
            material,
            cdunidadmedida,
            TRUNC (dtaplicacion),
            TRUNC (dtentrega),
            dsobservacion
    --union all para los pedidos manejados cno el nuevo slvapp
    UNION ALL
    SELECT TRIM (Centro) || PedidoNumero idpedido,
            id_canal Canal,
            Centro,
            origen,
            DECODE (vendedor, ' ', telema, vendedor) vendedor,
            almacen,
            cliente,
            cdcuit,
            provincia,
            localidad,
            codpostal,
            calle,
            numero,
            material,
            SUM (cantidad) cantidad,
            cdunidadmedida,
            ROUND (SUM (precio), 2) precio,
            TRUNC (dtaplicacion) dtpedido,
            TRUNC (dtentrega) dtentrega,
            dsobservacion
       FROM (SELECT cp.idconsolidadopedido PedidoNumero,
                    pe.id_canal,
                    sa.cdsucursal_armado centro,
                    d.cdsucursal origen,
                    ve.dsnombre || ' ' || ve.dsapellido AS vendedor,
                    te.dsnombre || ' ' || te.dsapellido AS telema,
                    DECODE (
                       TRIM (a.cdSector),
                       '11', 'CA' || SUBSTR (TRIM (sa.cdsucursal_armado), 3, 2),
                       '12', 'CA' || SUBSTR (TRIM (sa.cdsucursal_armado), 3, 2),
                       SUBSTR (TRIM (sa.cdsucursal_armado), 3, 2) || '01    ')
                       almacen,
                    e.dsrazonsocial cliente,
                    TRIM (REPLACE (e.cdcuit, '-', '')) cdcuit,
                    p.dsprovincia provincia,
                    l.dslocalidad localidad,
                    de.cdcodigopostal codpostal,
                    de.dscalle calle,
                    de.dsnumero numero,
                    dp.cdarticulo material,
                    dp.qtunidadmedidabase cantidad,
                    (CASE
                        WHEN (   TRIM (dp.cdunidadmedida) = 'BTO'
                              OR TRIM (dp.Cdunidadmedida) = 'CA'
                              OR TRIM (dp.Cdunidadmedida) = 'UN')
                        THEN
                           'UN'
                        WHEN (TRIM (dp.Cdunidadmedida) = 'PZA'
                              OR TRIM (dp.Cdunidadmedida) = 'KG')
                        THEN
                           'KG'
                     END)
                       cdunidadmedida,
                    dp.amlinea precio,
                    pe.dtaplicacion,
                    pe.dtentrega,
                    op.dsobservacion
               FROM tblslvconsolidadopedido cp,
                    pedidos pe,
                    detallepedidos dp,
                    tblslvconsolidadopedidorel re,
                    documentos d,
                    entidades e,
                    direccionesentidades de,
                    provincias p,
                    localidades l,
                    tblsucursalarmado sa,
                    observacionespedido op,
                    articulos a,
                    tblslvconsolidadoM con,
                    personas ve,
                    personas te
              WHERE     cp.idconsolidadopedido = re.idconsolidadopedido
                    AND cp.cdsucursal = re.cdsucursal
                    AND re.idpedido = pe.idpedido
                    AND d.iddoctrx = pe.iddoctrx
                    AND dp.idpedido = pe.idpedido
                    AND ve.idpersona(+) = pe.idvendedor
                    AND te.idpersona(+) = pe.idpersonaresponsable
                    AND e.identidad = d.identidadreal
                    AND de.identidad = d.identidadreal
                    AND pe.id_canal <> 'CO'               --No es comisionista
                    AND (pe.iczonafranca = 0 OR pe.iczonafranca IS NULL) --No es exportacion
                    AND pe.icestadosistema = 3                    --A facturar
                    AND de.identidad = cp.identidad
                    AND de.cdprovincia = p.cdprovincia
                    AND con.idconsolidadom = cp.idconsolidadom
                    AND con.cdsucursal = cp.cdsucursal
                    AND con.dtinsert > TRUNC (SYSDATE) - 1
                    AND de.cdlocalidad = l.cdlocalidad
                   AND d.cdsucursal = sa.cdsucursal
                    AND a.cdarticulo = dp.cdarticulo
                    AND op.idpedido(+) = pe.idpedido
                    AND p.cdprovincia = l.cdprovincia
                    --AND sa.cdsucursal_armado IN('0016    ')
                    AND dp.icresppromo <> 1                  --saco las promos
                                           /*and de.icactiva = 1*/
            )
   GROUP BY PedidoNumero,
            id_canal,
            centro,
            origen,
            vendedor,
            telema,
            almacen,
            cliente,
            cdcuit,
            provincia,
            localidad,
            codpostal,
            calle,
            numero,
            material,
            cdunidadmedida,
            TRUNC (dtaplicacion),
            TRUNC (dtentrega),
            dsobservacion        
;
