with 
confor as(
select pc.dtinsert,pc.idpedido,pc.cdarticulo,sum(pc.qtunidadmedidabase) sc
  from tblslvpedidoconformado pc       
   group by pc.dtinsert,pc.idpedido,pc.cdarticulo
   ),
pedi as
 (select dp.idpedido,dp.cdarticulo,sum(dp.qtunidadmedidabase) sp
  from detallepedidos dp
 where dp.icresppromo=0
   group by dp.idpedido,dp.cdarticulo
  )   
select co.*,p.*,pe.id_canal from confor co ,pedi p, pedidos pe  
   where p.idpedido=co.idpedido
     and p.idpedido=pe.idpedido
     and p.cdarticulo=co.cdarticulo
     and co.sc> p.sp
     and co.dtinsert>='20/01/2021'
   order by co.dtinsert;
   
/*   select * from detallepedidos dp 
    where dp.idpedido in ( select p.idpedido from pedidos p where p.transid='CLOTOAULPGGD')
      and dp.cdarticulo='0100694 '
      ;
      select * from pedidos p where p.transid='CLOTOAULPGGD';
      */
      
/*      select * from detallepedidos dp 
    where dp.idpedido in ( select p.idpedido from pedidos p where p.transid='CLOTOAULPGGD')
      and dp.cdarticulo='0100694 '
      ;*/
      select * from tblslvpedidoconformado pc where pc.dtinsert>=trunc(sysdate);
      
  
       select * from detallepedidos dp 
    where dp.idpedido='BCBC489C5A10820AE053100310ACE9FE        '
      and dp.cdarticulo='0162638 '
      ;
      
      select * from tblslvconsolidadopedidorel cpr
      where cpr.idpedido='BCBC489C5A10820AE053100310ACE9FE        '
      ;
      
      select * from tblslvconsolidadopedido cp where cp.idconsolidadopedido=9028