SELECT DISTINCT cm.transid TRANSID,
        to_number(o.dsobservacion) NROORDEN,
        ecomi.dsrazonsocial COMISIONISTA,
        e.cdcuit CUIT,
        e.dsrazonsocial RAZONSOCIAL,
        de.dscalle || ' ' || de.dsnumero || ' (' ||
        trim(de.cdcodigopostal) || ') ' || lo.dslocalidad || ' - ' ||
        pro.dsprovincia DIRECCION,
        trunc(pe.dtentrega) DTENTREGA,
        cm.idcomisionista
        FROM pedidos               pe,
             entidades             e,
             documentos            do,
             direccionesentidades de,
             localidades          lo,
             provincias           pro,
             observacionespedido o,
             tbltmpslvconsolidadom cm,
             entidades eComi
       WHERE  pe.iddoctrx = do.iddoctrx
          AND pe.transid=cm.transid
          AND pe.idcomisionista=ecomi.identidad
          AND do.identidadreal= e.identidad
          AND do.identidadreal = de.identidad
          AND pe.cdtipodireccion = de.cdtipodireccion
          AND pe.sqdireccion = de.sqdireccion
          AND de.cdpais = pro.cdpais
          AND de.cdprovincia = pro.cdprovincia
          AND de.cdpais = lo.cdpais
          AND de.cdprovincia = lo.cdprovincia
          AND de.cdlocalidad = lo.cdlocalidad
          AND pe.idpedido = o.idpedido
          AND do.cdsucursal ='0020' 
          AND trim(cm.idcomisionista) in ('{C6570172-0961-44EC-994D-35233243169F}') 
         ORDER BY trunc(pe.dtentrega) 
         
 
         
       
