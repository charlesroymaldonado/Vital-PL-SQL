select * from vtexproduct vp where vp.categoryid=3;   -- and vp.refid in ('0154909', '0171914', '0150284', '0172089' ); --vp.dtupdate is not null; where vp.refid like '%128643%'; --for update; --where vp.productid is not null;
select * from vtexsku vs where vs.refid in (select vp.refid from vtexproduct vp where vp.categoryid=3); --for update; vs.dtupdate is not null;
select * from vtexstock vst;-- where vst.cdarticulo in (select vp.refid from vtexproduct vp where vp.productid is not null);

select * from vtexproduct vp where vp.icprocesado=0;

select * from vtexsku vs where vs.icprocesado=0;
--update  vtexproduct vp set vp.productid=to_number(vp.refid);
--select * from articulos_s a where a.cdarticulo='0170367 ';
/*
delete vtexstock vst where vst.cdarticulo not in (select vp.refid from vtexproduct vp where vp.productid is not null);
delete vtexsku vs where vs.refid not in (select vp.refid from vtexproduct vp where vp.productid is not null);
delete vtexproduct vp where vp.productid is null;*/

--update vtexproduct vp set vp.icprocesado=0, vp.icnuevo=1, vp.dtupdate=null, vp.productid=to_number(vp.refid) where vp.categoryid=3; 
--update vtexsku vs set vs.icprocesado=0 where vs.refid in (select vp.refid from vtexproduct vp where vp.categoryid=3); 
--procesar solo una categoria
---update vtexproduct vp set vp.icprocesado=0 where vp.categoryid=6; 
---update vtexsku vs set vs.icprocesado=0 where vs.refid in (select vp.refid from vtexproduct vp where vp.categoryid=6); 

--select n_pkg_vitalpos_materiales_s.GetUxB('0172090 ') UXB from dual;
/*select pkg_merge_datos_vtex.GETFACTOR('0171740 ') from dual;
select * 
  --      into V_FACTOR 
        from tbllista_precio_central_s pc 
       where pc.cdarticulo in (select vp.refid from vtexproduct vp where vp.categoryid=97);*/
--delete vtexsku;
--delete vtexproduct;
