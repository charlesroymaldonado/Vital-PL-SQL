SELECT  NULL TRANSID,
             e.identidad IDCOMISIONISTA,
             pe.id_canal CANAL,
             trunc(do.dtdocumento) DTENTREGA,
             e.CDCUIT CUIT,
             e.dsrazonsocial RAZONSOCIAL,
             '-' DIRECCION,
             round(SUM(pe.ammonto), 2) MONTO
        FROM pedidos              pe,
             documentos           do,
             entidades            e
       WHERE pe.iddoctrx = do.iddoctrx
         and do.identidadreal = e.identidad
         and do.cdcomprobante = 'PEDI'
         AND pe.icestadosistema = 2
         and pe.id_canal = 'CO'
         and nvl(pe.iczonafranca, 0) = 0
         AND do.dtdocumento >='20/10/2015'
         and pe.idcnpedido is null
         and do.cdsucursal = '0020'
         AND trim(E.IDENTIDAD) in ('{BD1DFCCB-E388-44AA-BCBD-88680AF53CEC}','{A366D31F-A9B2-4BB4-9D68-6D7DA81D651E}')
       GROUP BY e.identidad,
                e.CDCUIT,
               trunc(do.dtdocumento),
                pe.id_canal,
                e.dsrazonsocial
       ORDER BY trunc(do.dtdocumento)
