select * from vtexproduct p where p.refid in ('0100027','0100086');
select * from articulos a where a.cdarticulo in ('0100027','0100086');

--select * from vtexproduct p where p.dtprocesado>=trunc(sysdate);

select * from vtexproduct p where p.icprocesado not in (0,1) ;

--select * from vtexsku p where p.dtprocesado>=trunc(sysdate);

select * from vtexsku p where p.icprocesado not in (0,1) and p.skuid not in (

select v.skuid from vtexsku v where v.icprocesado not in (0,1) and v.observacion like '%NotFound%')
and p.skuid not in (
select vs.skuid from vtexsku vs where vs.icprocesado not in (0,1) and vs.observacion like '%4 MB%');
