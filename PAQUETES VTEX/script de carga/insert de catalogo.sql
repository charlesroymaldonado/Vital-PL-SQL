   select * from vtexcatalog c order by c.departmentid;
   select * from vtexarticuloscategorizados;
   select * from vtexbrand; 
   select distinct trim(upper(ec.vlmarca)) from tblarticulonombreecommerce ec;

    insert into vtexcatalog
    select distinct
           replace(sap.departmentid,'B',2), 
           sap.departmentname,          
           replace(sap.categoryid,'C',3),          
           sap.categoryname,
           replace(sap.subcategoryid,'D',4),         
           sap.subcategoryname                
      from vtexcatSAP sap
  group by sap.departmentid,
           sap.departmentname, 
           sap.categoryid,
           sap.categoryname,
           sap.subcategoryid,
           sap.subcategoryname;
         
   
    insert into vtexarticuloscategorizados
    select '0'||trim(to_char(sap.cdarticulo)),
           replace(sap.departmentid,'B',2),           
           replace(sap.categoryid,'C',3),          
           replace(sap.subcategoryid,'D',4),         
           replace(sap.variedadid,'E',5),
           sap.variedadname                   
      from vtexcatSAP sap
 
