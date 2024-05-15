select * from Vtexsku;
insert into vtexsku
select BB.* from(
select distinct
       a.cdarticulo skuid,
       a.cdarticulo refid,
       a.vldescripcion skuname,
       1 isactive,
       a.dtcreacion creationdate,
       1 unmitmultiplier,
       'UN' measurementunit,
       null dtupdate,
       0 icprocesado,
       null observacion,       
       sysdate dtinsert,
       null dtprocesado       
  from articulos a) BB,
       vtexproduct  vp
 where BB.refid = vp.refid
  -- and vp.refid in (SELECT p.refid FROM VTEXPRODUCT P WHERE P.DEPARTMENTID=9 AND P.CATEGORYID=96  AND P.SUBCATEGORYID=100)
  