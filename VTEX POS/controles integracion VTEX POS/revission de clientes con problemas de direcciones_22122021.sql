select distinct e.cdcuit,e.dsrazonsocial,decode(p.icorigen,0, 'venta movil','VTEX') origen, p.dtaplicacion, a.dscalle,a.dsnumcalle 
from pedidos p, documentos d, entidades e, vtexaddress a, vtexclients c
where p.iddoctrx=d.iddoctrx
  and d.identidadreal=e.identidad
  and e.cdcuit in ('20-94026002-8')
  and p.icestadosistema<>0
  and p.dtaplicacion>=trunc(sysdate-45)
  and a.id_cuenta=c.id_cuenta
  and a.clientsid_vtex=c.clientsid_vtex
  and c.cuit=e.cdcuit
  and a.cdtipodireccion=p.cdtipodireccion
  and a.sqdireccion=p.sqdireccion
  order by 4,5
  ;
  select * from vtexaddress a, vtexclients c where c.id_cuenta=a.id_cuenta and c.cuit='20-94026002-8';
  select * from direccionesentidades de,entidades e where de.identidad=e.identidad and e.cdcuit='20-95749479-0';
  
 select * from tbldireccioncuenta de,entidades e where de.identidad=e.identidad and e.cdcuit='20-95749479-0';
    select * from vtexaddress a where a.id_cuenta='6503F705C1E846B8E053100000D839ED' --for update
    ;
        select * from vtexclients a where a.id_cuenta='6503F705C1E846B8E053100000D839ED' --for update
        ;
