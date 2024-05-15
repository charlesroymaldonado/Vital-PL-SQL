

select * from clientescomisionistas cc, entidades e, tblcuenta c, tbldireccioncuenta dc
where cc.identidad=e.identidad
and e.identidad=c.identidad
and c.cdsucursal='0010'
and c.idcuenta=dc.idcuenta
and cc.idcomisionista=
'{DE27CCF8-746E-4405-9777-207326187CC9}  '
