SELECT pe.transid TRANSID,
             NULL IDCOMISIONISTA,
             pe.id_canal CANAL,
             trunc(pe.dtentrega) DTENTREGA,
             e.CDCUIT CUIT,
             e.dsrazonsocial RAZONSOCIAL,
             -- Formato Direccion
             de.dscalle || ' ' || de.dsnumero || ' (' ||
             trim(de.cdcodigopostal) || ') ' || lo.dslocalidad || ' - ' ||
             pro.dsprovincia DIRECCION,
             round(SUM(pe.ammonto), 2) MONTO
        FROM pedidos              pe,
             documentos           do,
             direccionesentidades de,
             localidades          lo,
             provincias           pro,
             sucursales           su,
             entidades            e
       WHERE pe.iddoctrx = do.iddoctrx
         and do.identidadreal = e.identidad
         AND do.identidadreal = de.identidad
         AND pe.cdtipodireccion = de.cdtipodireccion
         AND pe.sqdireccion = de.sqdireccion
         and de.cdpais = pro.cdpais
         and de.cdprovincia = pro.cdprovincia
         and de.cdpais = lo.cdpais
         and de.cdprovincia = lo.cdprovincia
         AND de.cdlocalidad = lo.cdlocalidad
         AND do.cdsucursal = su.cdsucursal
         and do.cdcomprobante = 'PEDI'
         AND do.dtdocumento>='20/12/2015'
         AND do.dtdocumento<'14/10/2019'
         AND pe.icestadosistema = 2
         and pe.id_canal <> 'CO'
         and nvl(pe.iczonafranca, 0) = 0
         and pe.idcnpedido is null
         and do.cdsucursal = '0020'
       GROUP BY pe.transid,
                e.CDCUIT,
                pe.dtentrega,
                pe.id_canal,
                e.dsrazonsocial,
                de.dscalle,
                de.dsnumero,
                de.cdcodigopostal,
                lo.dslocalidad,
                pro.dsprovincia
UNION  ALL       
SELECT  NULL TRANSID,
             pe.idcomisionista IDCOMISIONISTA,
             pe.id_canal CANAL,
             trunc(SYSDATE) DTENTREGA,
             e.CDCUIT CUIT,
             e.dsrazonsocial RAZONSOCIAL,
             '-' DIRECCION,
             round(SUM(pe.ammonto), 2) MONTO
        FROM pedidos              pe,
             documentos           do,
             entidades            e
       WHERE pe.iddoctrx = do.iddoctrx
         and pe.idcomisionista = e.identidad
         and do.cdcomprobante = 'PEDI'
         AND pe.icestadosistema = 2
         and pe.id_canal = 'CO'
         and nvl(pe.iczonafranca, 0) = 0
         AND do.dtdocumento >='20/10/2015'
         and pe.idcnpedido is null
         and do.cdsucursal = '0020'
         AND pe.idcomisionista in ('{0D9AD177-B7B6-4976-98AD-21BC486BB006}   ','{A366D31F-A9B2-4BB4-9D68-6D7DA81D651E}')
       GROUP BY pe.idcomisionista,
                e.CDCUIT,
               trunc(SYSDATE),
                pe.id_canal,
                e.dsrazonsocial
ORDER BY 4  DESC             