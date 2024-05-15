select * from slvapp.tblslvconsolidadopedidorel cpr, detallepedidos dp 
where cpr.idconsolidadopedido=9028
and cpr.idpedido=dp.idpedido 
and dp.cdarticulo in
(
'0162638 '
)
;
select d.iddoctrx,dmm.*, cpr.idpedido from slvapp.tblslvconsolidadopedidorel cpr, movmateriales mm, detallemovmateriales dmm, documentos d
where cpr.idconsolidadopedido in (9028)
and cpr.idpedido=mm.idpedido
and mm.idmovmateriales=dmm.idmovmateriales
and mm.idmovmateriales=d.idmovmateriales
and dmm.cdarticulo='0162638 '
;

select pc.* 
  from tblslvpedidoconformado pc,
       tblslvconsolidadopedidorel cpr
 where pc.idpedido=cpr.idpedido
   and cpr.idconsolidadopedido in (9028)
   and pc.cdarticulo='0162638  ';
       
