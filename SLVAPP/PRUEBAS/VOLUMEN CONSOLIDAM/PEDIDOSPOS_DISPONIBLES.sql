SELECT pe.transid TRANSID, --devuelve todos los pedidos de reparto
               NULL IDCOMISIONISTA,
               pe.id_canal CANAL,
               trunc(pe.dtentrega) DTENTREGA,
               e.CDCUIT CUIT,
               e.dsrazonsocial RAZONSOCIAL,
               de.dscalle || ' ' || de.dsnumero || ' (' ||
               trim(de.cdcodigopostal) || ') ' || lo.dslocalidad || ' - ' ||
               pro.dsprovincia DIRECCION,
               round(SUM(pe.ammonto), &c_qtDecimales) MONTO,
               '-' COMISIONISTA,
               '-' ORDEN,
               0 FALTANTECOMI
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
           AND do.cdcomprobante = 'PEDI'
           AND pe.dtaplicacion >= (select SYSDATE -To_Number(getVlParametro('DiasPedidos', 'General')) from dual)
           AND pe.dtentrega <= &p_dthasta
           AND pe.icestadosistema = &c_pedi_liberado
           AND pe.id_canal <> 'CO'
           AND pe.id_canal <> 'SA'
           AND nvl(pe.iczonafranca, 0) = 0
           AND pe.idcnpedido is null -- null para caja navideña
        --   AND do.cdsucursal = g_cdSucursal
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
        UNION ALL
            SELECT pe.transid TRANSID, --devuelve todos los pedidos de reparto
                 pe.idcomisionista IDCOMISIONISTA,
                 pe.id_canal CANAL,
                 trunc(pe.dtentrega) DTENTREGA,
                 e.CDCUIT CUIT,
                 e.dsrazonsocial RAZONSOCIAL,
                 de.dscalle || ' ' || de.dsnumero || ' (' ||
                 trim(de.cdcodigopostal) || ') ' || lo.dslocalidad || ' - ' ||
                 pro.dsprovincia DIRECCION,
                 round(SUM(pe.ammonto), 2) MONTO,
                 trim(ecomi.dsrazonsocial) || ' (' || trim(ecomi.cdcuit) || ')'  COMISIONISTA,
                 nvl(o.dsobservacion,'-') orden,
                 case
                 when PE.TRANSID like '%-PGF%' then 1 else 0 end FALTANTECOMI
            FROM pedidos              pe,
                 documentos           do,
                 direccionesentidades de,
                 localidades          lo,
                 provincias           pro,
                 sucursales           su,
                 entidades            e,
                 entidades            eComi,
                 observacionespedido  o
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
             AND do.cdcomprobante = 'PEDI'
             AND do.dtdocumento >= (select SYSDATE -To_Number(getVlParametro('DiasPedidos', 'General')) from dual)
             AND pe.icestadosistema = &c_pedi_liberado
             AND pe.id_canal = 'CO'
             AND pe.id_canal <> 'SA'
             AND pe.idcomisionista=ecomi.identidad
             and pe.idpedido=o.idpedido             
             AND nvl(pe.iczonafranca, 0) = 0
             AND pe.idcnpedido is null -- null para caja navideña
         --    AND do.cdsucursal = g_cdSucursal
           GROUP BY pe.transid,
                    pe.idcomisionista,
                    ecomi.dsrazonsocial,
                    ecomi.cdcuit,
                    e.CDCUIT,
                    pe.dtentrega,
                    pe.id_canal,
                    e.dsrazonsocial,
                    de.dscalle,
                    de.dsnumero,
                    de.cdcodigopostal,
                    lo.dslocalidad,
                    pro.dsprovincia,
                    o.dsobservacion
           ORDER BY 4 DESC;
           
 /*DELETE DETPEDIDOCONFORMADO DC
 WHERE DC.IDPEDIDO IN(  
 SELECT PRE.IDPEDIDO 
   FROM TBLSLVCONSOLIDADOPEDIDOREL   PRE,
        TBLSLVCONSOLIDADOPEDIDO CP
  WHERE CP.IDCONSOLIDADOPEDIDO = PRE.IDCONSOLIDADOPEDIDO
    AND CP.IDCONSOLIDADOM = 139);
    
 DELETE TBLSLVPEDIDOCONFORMADO PC
 WHERE PC.IDPEDIDO IN(  
 SELECT PRE.IDPEDIDO 
   FROM TBLSLVCONSOLIDADOPEDIDOREL   PRE,
        TBLSLVCONSOLIDADOPEDIDO CP
  WHERE CP.IDCONSOLIDADOPEDIDO = PRE.IDCONSOLIDADOPEDIDO
    AND CP.IDCONSOLIDADOM = 139);   
    
DELETE DETPEDIDOCONFORMADO DC
 WHERE DC.IDPEDIDO IN(  
 select P.IDPEDIDO from pedidos p 
 where p.icestadosistema = 2
   and p.dtaplicacion>=(select SYSDATE -To_Number(getVlParametro('DiasPedidos', 'General')) from dual));
    
 DELETE TBLSLVPEDIDOCONFORMADO PC
 WHERE PC.IDPEDIDO IN(  
 select P.IDPEDIDO from pedidos p 
 where p.icestadosistema = 2
   and p.dtaplicacion>=(select SYSDATE -To_Number(getVlParametro('DiasPedidos', 'General')) from dual)); */
   
 
