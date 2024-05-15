select * from vtexproduct;
--insert into vtexproduct
SELECT distinct BB.* FROM
(select distinct null productID, 
       a.vldescripcion name,
       NVL((select 
       distinct nvl(vc.departmentid,-1) 
           from vtexcatalog vc
          where vc.departmentname = upper(trim(a.dsdepartamento))
             and rownum = 1),-1) departmentID, 
       NVL((select 
       distinct NVL(vc.categoryid,-1) 
           from vtexcatalog vc
          where vc.categoryname = upper(trim(a.dsuniverso))
             and rownum = 1),-1) categoryID,  
       NVL((select 
          distinct NVL(vc.subcategoryid,-1) 
           from vtexcatalog vc
          where vc.subcategoryname = upper(trim(a.dscategoria))
             and rownum = 1),-1) subcategoryID,             
       NVL((select 
       distinct NVL(vb.brandid,-1) 
           from vtexbrand vb
          where upper(trim(A.VLDESCRIPCION)) LIKE '%'||vb.name||'%'
            and rownum = 1),-1) Brandid,
       a.cdarticulo linkid,
       a.cdarticulo refid,
       1 isvisible,
       a.vldescripcion description,
       a.dtcreacion relesasedate,
       1 isactive,
       1 icnuevo,
       sysdate dtinsert,
       null dtupdate,
       1 factor,
       a.vluxb UXB,
       null observacion,
       0 icprocesado,
       null dtprocesado             
  from articulos a) BB,
       VTEXCATALOG  VC
 WHERE BB.DEPARTMENTID||BB.CATEGORYID||BB.SUBCATEGORYID = VC.DEPARTMENTID||VC.CATEGORYID||VC.SUBCATEGORYID
   and BB.BRANDID<>-1 ;
  select a.cdarticulo,
  NVL((select 
       distinct NVL(vb.brandid,2000001) --natura
           from vtexbrand vb
          where upper(trim(A.VLDESCRIPCION)) LIKE '%'||vb.name||'%'
            and rownum = 1),2000001) Brandid         
  from articulos a
