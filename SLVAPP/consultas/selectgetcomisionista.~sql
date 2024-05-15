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
         AND trim(pe.idcomisionista) in (select trim(p.idcomisionista) from pedidos p where p.idcomisionista in ('{9048F662-D4DE-45D9-9F3B-E8226550EC5D}  ','{0D9AD177-B7B6-4976-98AD-21BC486BB006}'))
       GROUP BY pe.idcomisionista,
                e.CDCUIT,
               trunc(SYSDATE),
                pe.id_canal,
                e.dsrazonsocial
