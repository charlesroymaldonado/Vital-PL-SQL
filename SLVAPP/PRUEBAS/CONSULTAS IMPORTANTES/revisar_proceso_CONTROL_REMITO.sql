Select * from tblslvremito r where r.idremito=&p_idremtio;
/*Select * from tblslvremitodet;*/
Select rd.*,
       PKG_SLV_ARTICULO.GetCodigoDeBarra(rd.cdarticulo,decode(rd.qtpiezaspicking,0,'UN','KG')) 
 from tblslvremitodet rd where rd.idremito=&p_idremtio;

Select RD.CDARTICULO, SUM(RD.QTUNIDADMEDIDABASEPICKING), SUM(RD.QTPIEZASPICKING)
 from tblslvremitodet rd where rd.idremito=&p_idremtio
 GROUP BY  RD.CDARTICULO;

select * from tblslvcontrolremito cr where cr.idremito = &p_idremtio;

select crd.* 
  from tblslvcontrolremito cr,
       tblslvcontrolremitodet crd
 where cr.idremito = &p_idremtio 
   and cr.idcontrolremito = crd.idcontrolremito ;

   select * from tblslvconteo co
   where co.idcontrolremito =&p_idcontrol ;
   
select cod.* 
  from tblslvconteo co,
       tblslvconteodet cod
   where co.idcontrolremito =&p_idcontrol    
     and co.idconteo=cod.idconteo
     order by cod.idconteo, cod.cdarticulo;
--select * from tblslvcontrolremitodet crd where crd.idcontrolremito=&p_idcontrol    for update
--select * from tblslvconteodet cod  where cod.idconteo=91 for update
