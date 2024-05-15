 select distinct
                'DON' as key1,
                TRIM(vc.cuit) as key2,
                '' as key3,
                '' as key4,
                '' as key5,
                VA.DSCALLE || ' ' || VA.DSNUMCALLE as seldesc,
                VA.SQDIRECCION as selcode,
                TRIM(VA.CDTIPODIRECCION) as Value1,
                VA.SQDIRECCION as Value2,
                pkg_credito_central.GetPoderCompraByDirec(a.identidad,
                                                          va.cdtipodireccion,
                                                          va.sqdireccion,
                                                          s.cdsucursal_armado) as Value3,
                '' as Value4,
                '' as Value5,
                '' as Value6,
                '' as Value7,
                '' as Value8,
                '' as Value9,
                '' as Value10,
                8 as ValueType1,
                8 as ValueType2,
                4 as ValueType3,
                -1 as ValueType4,
                -1 as ValueType5,
                -1 as ValueType6,
                -1 as ValueType7,
                -1 as ValueType8,
                -1 as ValueType9,
                -1 as ValueType10,
                'Y' as SyncedAccess,
                TRIM(f.DSNOMBRE || ' ' || f.DSAPELLIDO) as version
            from vtexaddress  va,
                 vtexclients  vc,
                 vtexsellers  vs,
                 entidades    a,
                 TBLDIRECCIONCUENTA DC,
                 personas f,
                 clientesviajantesvendedores Y,
                 (SELECT DISTINCT idpersona FROM rolespersonas WHERE cdrol = 11) U,
                 tblsucursalarmado S
           where va.id_cuenta = vc.id_cuenta
             and dc.idcuenta=vc.id_cuenta
             and va.clientsid_vtex = vc.clientsid_vtex             
             and vc.cdsucursal = vs.cdsucursal
             and vc.id_canal = vs.id_canal 
             and vc.id_canal = 'VE'         
             --solo direcciones que ya tienen clientsid_vtex
             and va.clientsid_vtex <> '1'
             --solo direccioens activas
             and va.icactive = 1
             AND a.identidad = dc.identidad      
             AND a.IDENTIDAD = Y.IDENTIDAD
             AND Y.idviajante = f.idpersona 
             and f.icactivo = 1
             AND Y.idviajante = U.idpersona
             AND Y.dthasta = (SELECT MAX(dthasta)
                                FROM clientesviajantesvendedores T
                             )
             AND Y.CDSUCURSAL = S.CDSUCURSAL  
        GROUP BY a.IDENTIDAD,
                 vc.CUIT,
                 va.dscalle,
                 va.dsnumcalle,
                 va.SQDIRECCION,
                 a.CDMAINSUCURSAL,
                 f.DSNOMBRE,
                 f.DSAPELLIDO,
                 va.CDTIPODIRECCION,
                 va.SQDIRECCION,
                 S.CDSUCURSAL,
                 pkg_credito_central.GetPoderCompraByDirec(a.identidad,
                                                           va.cdtipodireccion,
                                                           va.sqdireccion,
                                                            s.cdsucursal_armado)                                     
UNION 
SELECT DISTINCT 'DON' as key1,
                TRIM(a.CDCUIT) as key2,
                '' as key3,
                '' as key4,
                '' as key5,
                b.DSCALLE || ' ' || b.DSNUMERO as seldesc,
                b.SQDIRECCION as selcode,
                TRIM(CDTIPODIRECCION) as Value1,
                SQDIRECCION as Value2,
                pkg_credito_central.GetPoderCompraByDirec(a.identidad,
                                                          b.cdtipodireccion,
                                                          b.sqdireccion,
                                                          s.cdsucursal_armado) as Value3,
                '' as Value4,
                '' as Value5,
                '' as Value6,
                '' as Value7,
                '' as Value8,
                '' as Value9,
                '' as Value10,
                8 as ValueType1,
                8 as ValueType2,
                4 as ValueType3,
                -1 as ValueType4,
                -1 as ValueType5,
                -1 as ValueType6,
                -1 as ValueType7,
                -1 as ValueType8,
                -1 as ValueType9,
                -1 as ValueType10,
                'Y' as SyncedAccess,
                TRIM(f.DSNOMBRE || ' ' || f.DSAPELLIDO) as version
  FROM ENTIDADES a,
       DIRECCIONESENTIDADES b,
       personas f,
       clientesviajantesvendedores Y,
       (SELECT DISTINCT idpersona FROM rolespersonas WHERE cdrol = 11) U,
       tblsucursalarmado S
 WHERE b.IDENTIDAD = a.IDENTIDAD
   AND a.CDESTADOOPERATIVO = 'A'
   AND b.icactiva = 1
   AND a.IDENTIDAD = Y.IDENTIDAD
   AND Y.idviajante = f.idpersona 
   and f.icactivo = 1
   AND Y.idviajante = U.idpersona
   AND Y.dthasta = (SELECT MAX(dthasta)
                      FROM clientesviajantesvendedores T
                    )
   AND Y.CDSUCURSAL = S.CDSUCURSAL
 GROUP BY b.IDENTIDAD,
          a.CDCUIT,
          b.DSCALLE,
          b.DSNUMERO,
          b.SQDIRECCION,
          a.CDMAINSUCURSAL,
          f.DSNOMBRE,
          f.DSAPELLIDO,
          CDTIPODIRECCION,
          SQDIRECCION,
          S.CDSUCURSAL,
          pkg_credito_central.GetPoderCompraByDirec(a.identidad,
                                                    b.cdtipodireccion,
                                                    b.sqdireccion,
                                                    s.cdsucursal_armado)
