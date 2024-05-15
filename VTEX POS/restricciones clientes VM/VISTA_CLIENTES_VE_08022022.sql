CREATE OR REPLACE VIEW VISTA_CLIENTES_VE AS
-- clientes con más de 4 pedidos en vtex en los últimos 45 días -- 283
with tienen_vtex as (
select identidadreal
  from documentos do, pedidos p
 where do.iddoctrx = p.iddoctrx
   and do.cdcomprobante = 'PEDI'
   and do.dtdocumento > trunc(sysdate - 45)
   and nvl(p.icorigen, 0) = 4
   and p.id_canal = 'VE'
 group by do.identidadreal
having count(distinct p.transid) > 4
),
-- clientes con algún pedido en vmovil en los últimos 45 días -- 848
tienen_vmovil as ( 
select distinct do.identidadreal
  from documentos do, pedidos p
 where do.iddoctrx = p.iddoctrx
   and do.cdcomprobante = 'PEDI'
   and do.dtdocumento > trunc(sysdate - 45)
   and nvl(p.icorigen, 0) <> 4
   and p.id_canal = 'VE'
),
elegidos as (
-- todos los clientes de vendedor (1589)
select distinct identidad
  from clientesviajantesvendedores
 where dthasta = (SELECT MAX(dthasta) FROM clientesviajantesvendedores T) 
   and identidad not in (select * from tienen_vtex) -- que no tienen vtex
union all
select distinct identidad
  from clientesviajantesvendedores
 where dthasta = (SELECT MAX(dthasta) FROM clientesviajantesvendedores T) 
   and identidad in (select * from tienen_vtex) -- que tienen vtex
   and identidad in (select * from tienen_vmovil) -- y tienen vmovil
)
SELECT DISTINCT 'CTE' as key1,
                '' as key2,
                '' as key3,
                '' as key4,
                '' as key5,
                TRIM(a.DSRAZONSOCIAL) || ' (' || TRIM(S.DSSUCURSAL) || ')' as seldesc,
                TRIM(a.CDCUIT) as selcode,
                TRIM(b.CDPROVINCIA) as Value1,
                TRIM(b.CDLOCALIDAD) as Value2,
                TRIM(c.CDSITUACIONIVA) as Value3,
                CASE
                  WHEN A.DT13178 IS NULL THEN
                   'SIN HABILITACION'
                  WHEN A.DT13178 < TRUNC(SYSDATE) THEN
                   'VENCIDO'
                  ELSE
                   'VIG'
                END as Value4,
                TRIM(TO_CHAR(c.ICCONVENIO)) as Value5,
                TO_CHAR(f.nudocumento) as Value6,
                TRIM(Y.CDSUCURSAL) as Value7,
                TRIM(a.CDCUIT) || '-' || TRIM(Y.CDSUCURSAL) as Value8,
                CASE
                  WHEN A.DT13178 IS NULL OR A.DT13178 < TRUNC(SYSDATE) THEN
                   'VC'
                  ELSE
                   'OK'
                END as Value9,
                '' as Value10,
                8 as ValueType1,
                8 as ValueType2,
                8 as ValueType3,
                8 as ValueType4,
                8 as ValueType5,
                8 as ValueType6,
                8 as ValueType7,
                8 as ValueType8,
                8 as ValueType9,
                8 as ValueType10,
                'Y' as SyncedAccess,
                TRIM(f.DSNOMBRE || ' ' || f.DSAPELLIDO) as version
  FROM elegidos e, entidades a,
       DIRECCIONESENTIDADES b,
       INFOIMPUESTOSENTIDADES c,
       SITUACIONESIVA d,
       clientesviajantesvendedores Y,
       (SELECT DISTINCT idpersona FROM rolespersonas WHERE cdrol = 11) U,
       personas f,
       sucursales S
 WHERE a.identidad = e.identidad
   and b.IDENTIDAD = A.IDENTIDAD
   AND c.IDENTIDAD = a.IDENTIDAD
   AND TRIM(c.CDSITUACIONIVA) = TRIM(d.CDSITUACIONIVA)
   AND a.CDESTADOOPERATIVO = 'A'
   AND a.IDENTIDAD = Y.IDENTIDAD
   and Y.idviajante = f.idpersona
   AND Y.idviajante = U.idpersona
   AND Y.dthasta = (SELECT MAX(dthasta)
                      FROM clientesviajantesvendedores T
                     )
   AND Y.CDSUCURSAL = S.CDSUCURSAL
   AND b.CDTIPODIRECCION = '2'
   AND SQDIRECCION = (SELECT MAX(SQDIRECCION)
                        FROM DIRECCIONESENTIDADES
                       WHERE IDENTIDAD = a.IDENTIDAD
                         AND CDTIPODIRECCION = '2'
                         and icactiva = 1)
 GROUP BY a.DSRAZONSOCIAL,
          a.IDENTIDAD,
          a.CDCUIT,
          b.CDLOCALIDAD,
          b.CDPROVINCIA,
          Y.CDSUCURSAL,
          TRIM(c.CDSITUACIONIVA),
          d.DSSITUACIONIVA,
          c.ICCONVENIO,
          f.DSNOMBRE,
          f.DSAPELLIDO,
          f.nudocumento,
          S.DSSUCURSAL,
          A.DT13178
;
