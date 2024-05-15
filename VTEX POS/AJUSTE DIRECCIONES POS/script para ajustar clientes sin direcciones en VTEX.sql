--generar el listado de identidades de clientes sin direcciones
select * from (
select cu.identidad,
       vc.cdsucursal suc,
       vc.cuit,       
       vc.razonsocial,
       cu.nombrecuenta,
       vc.email,
       decode(vc.icprocesado, 1, 'OK', 0, 'Pendiente', 'NO VTEX') procesado,
       case
         when vc.idagent = 'RCOyVE' then
          'Cliente con Comisionista y Vendedor'
         when vc.idagent = 'DCOyVE' then
          'Cliente con más de un Vendedor/Comisionista'
         when vc.idagent = 'RCOyTE' then
          'Cliente con Comisionista y Telemarketer'
         when vc.idagent = 'DTE' then
          'Cliente con más de un Telemarketer'
         when vc.idagent = 'DCO' then
          'Cliente con más de un Comisionista'
         when vc.idagent = 'DVE' then
          'Cliente con Agente duplicado en Vendedor'
         when vc.idagent = 'RVEyTE' then
          'Cliente con Vendedor y Telemarketer'
         when vc.idagent = 'NOAGT' then
          'Cliente sin Agente Asignado'
         else
          COALESCE((select distinct e.cdcuit || ' ' || e.dsrazonsocial
                     from clientescomisionistas cc, entidades e
                    where cc.idcomisionista = vc.idagent
                      and cc.identidad = e.identidad),
                   (select distinct p.dsnombre || ' ' || p.dsapellido
                      from clientesviajantesvendedores cv,
                           entidades                   e,
                           personas                    p
                     where cv.idviajante = vc.idagent
                       and cv.identidad = e.identidad
                       and cv.cdsucursal = vc.cdsucursal
                       and cv.identidad = cu.identidad
                       and cv.idviajante = p.idpersona),
                   (select distinct p.dsnombre || ' ' || p.dsapellido
                      from clientestelemarketing ct, entidades e, personas p
                     where ct.idpersona = vc.idagent
                       and ct.identidad = e.identidad
                       and ct.identidad = cu.identidad
                       and ct.cdsucursal = vc.cdsucursal
                       and ct.idpersona = p.idpersona))
       end agente,
       PKG_CLD_DATOS.GetCanal(cu.identidad, vc.cdsucursal) id_canal,
      -- decode(vc.icalcohol, 1, 'SI', 'NO') REBA,
       decode((select count(*)
                from vtexaddress va
              --solo direcciones activas
               where va.icactive = 1
                 and va.id_cuenta = vc.id_cuenta
                 and va.clientsid_vtex = vc.clientsid_vtex),
              0,
              'No Dirección',
              'OK') direcciones
  from vtexclients vc, tblcuenta cu
 where vc.id_cuenta = cu.idcuenta
      --solo clientes activos
   and vc.icactive = 1
)A 
where A.direcciones <>'OK'
;
--pasar el listado a excel para ir revisando identidad por identidad
--revisar de cada identidad las direcciones asociadas 
select * from direccionesentidades de where de.identidad=&identidad
;
--revisar que tenga asociada la dirección activa a la cuenta de la sucursal que tiene el cliente en VTEX
select * from tbldireccioncuenta dc where dc.identidad=&identidad
;
--actualizar en la sucursal la direccion activa y por replica sube a AC con eso la direccion sube OK a VTEX
--select * from tbldireccioncuenta@av dc where dc.identidad=&identidad
--FOR UPDATE
;
--revisar que suba ok las direcciones a vtex
select c.cdsucursal, a.*,c.cdsucursal,e.* from vtexaddress a,vtexclients c, entidades e
where a.id_cuenta=c.id_cuenta  
and c.cuit = e.cdcuit 
and e.identidad =&identidad 
and a.id_cuenta<>'1'
;

--finalmente a medida que sube ok desaparece la identidad del cliente de la consulta inicial
