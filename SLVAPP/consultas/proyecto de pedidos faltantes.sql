select * from tblslvpedfaltante;
select * from tblslvpedfaltantedet;

select * from tblslvpedfaltanterel;

select * from tblslvconsolidadopedido;

select * from tblslvpedidoconformado;

select cp.idconsolidadopedido 
  from tblslvconsolidadopedido cp,
       tblslvconsolidadopedidodet cpd,
       tblslvconsolidadopedidorel prel,
       pedidos pe
 where cp.idconsolidadopedido = prel.idconsolidadopedido
   and pe.idpedido = prel.idpedido
   --valida que el pedido no este facturado
   and pe.idpedido not in
       (  select 
        distinct pcf.idpedido
            from tblslvpedidoconformado pcf) 
   --valdia que el consolidado pedido no sea parte de un pedfaltante        
   and cp.idconsolidadopedido not in
       (  select 
        distinct prel2.idconsolidadopedido
            from tblslvconsolidadopedidorel prel2)
   --valida que el pedido tenga faltantes en su detalle y no este null así aseguro que pikió
   and cp.idconsolidadopedido = cpd.idconsolidadopedido
   and cpd.qtunidadesmedidabase-nvl(cpd.qtunidadmedidabasepicking,0) <> 0
   and cpd.qtunidadmedidabasepicking is not null
