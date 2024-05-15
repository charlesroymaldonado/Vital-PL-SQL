select * from (
select vct.departmentname,
       vct.categoryname,
       vct.subcategoryname,
      -- vp.productid,
       vp.refid,
       vp.name,
       vp.uxb,
       vs.unitmultiplier,
       (select uv.uv from vtexunidadventa uv where uv.cdarticulo=vs.refid) uv
  from vtexproduct                       vp,
       vtexsku                           vs,
       posapp.vtexarticuloscategorizados ac,
       vtexcatalog vct
 where vct.categoryid = ac.categoryid
   and vct.departmentid = ac.departmentid
   and vct.subcategoryid = ac.subcategoryid
   and ac.cdarticulo = vp.refid
   and vp.refid = vs.refid
order by vct.departmentname, vct.categoryname, vct.subcategoryname, vp.name
)A where-- A.unitmultiplier <>nvl(A.uv,0)
         	 A.refid not in (select uv.cdarticulo from vtexunidadventa uv)
           and A.UXB<>A.UnitMULTIPLIER
