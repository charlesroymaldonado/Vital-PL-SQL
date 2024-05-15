select s.cdsucursal,s.dslocalidad from vtexsellers s where s.id_canal='VE' and s.icactivo=1;
select * from vtexpricespecial p where p.icestado=0
;
select distinct t.cdsucursal,t.politica_comercial from VTEXSELLERS t where t.icactivo=1 and t.id_canal='VE'
order by 1;

insert into vtexpricespecial es
 select s.cdsucursal,
        p.skuid,
        p.refid,
        p.id_canal,
        p.priceof,
        p.dtfromof,
        p.dttoof,
        p.dtinsert,
        null,
        0   
  from vtexpricespecial p, vtexsellers s 
 where s.icactivo=1 and s.id_canal='VE' and s.cdsucursal<>'9999'  and p.icestado=0
  /* and case
   --si son todas las sucursales quito esto
      --amba
     when p.cdsucursal='0000' and s.cdsucursal in ('0007','0013','0015','0016')  then 1      
   --interior
     when p.cdsucursal='0001' and s.cdsucursal in ('0017','0018','0019','0020','0021','0022','0024')  then 1
   end = 1  */
  order by 1;
  --borro las de carga
  delete vtexpricespecial p where p.cdsucursal in ('0000','1000')

