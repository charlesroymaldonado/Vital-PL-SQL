select * from vtexproduct vp where vp.dtprocesado>=trunc(sysdate) order by vp.dtprocesado;
select * from vtexsku vs where vs.dtprocesado>= trunc(sysdate);
select * from vtexproduct vp where vp.icprocesado=2;
select count(*) from vtexproduct vp where vp.icprocesado<> 0;
select count(*) from vtexsku s where s.dtprocesado>= trunc(sysdate);
select count(*) from vtexproduct vp where vp.icprocesado=0;
select count(*) from Vtexprice p where p.icprocesado=0;
/*update vtexprice vp set vp.icprocesado=0,  --59694 6357 --stock 3341
                        vp.dtprocesado=null,
                        vp.observacion=null
                  where vp.icprocesado in (1,2);  */    

select count(*) from Vtexstock so where so.icprocesado=0 --not in (0,1)
;

/*update vtexproduct vp set vp.icprocesado=9,
                          vp.dtprocesado=null,
                          vp.observacion=null
                           where vp.icprocesado=0;*/
