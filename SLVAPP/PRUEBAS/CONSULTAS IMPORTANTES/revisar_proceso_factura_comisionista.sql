--tareas del pedido 
 select td.* 
   from tblslvtarea ta,
        tblslvtareadet td        
 where ta.idtarea=td.idtarea
   and ta.idconsolidadocomi=&p_idpedido;
--tareas del pedido
  select td.* 
   from tblslvtarea ta,
        tblslvtareadet td
 where ta.idtarea=td.idtarea   
   and ta.idconsolidadocomi=&p_idpedido; 
-- detalle del consolidado pedido
select ccd.* 
   from tblslvconsolidadocomi cc,
        tblslvconsolidadocomidet ccd
   where cc.idconsolidadocomi=ccd.idconsolidadocomi
     and cc.idconsolidadocomi= &p_idpedido
     order by ccd.cdarticulo   ; 
     
 -- detalle del consolidado pedido
select cpd.* 
   from tblslvconsolidadopedido cp,
        tblslvconsolidadopedidodet cpd
   where cp.idconsolidadopedido=cpd.idconsolidadopedido
     and cp.idconsolidadocomi= &p_idpedido
  order by cpd.cdarticulo   ;     
-- detalle pedidoconformado
select pc.idpedido,
               pc.sqdetallepedido,
               pc.cdunidadmedida,
               pc.cdarticulo,
               pc.qtunidadpedido,
               pc.qtunidadmedidabase,
               pc.qtpiezas,
               pc.ampreciounitario,
               pc.amlinea,
               pc.vluxb,
               pc.dsobservacion,
               pc.icrespromo,
               pc.cdpromo,
               des.vldescripcion,
               pc.dtinsert,
               pc.dtupdate
          from tblslvpedidoconformado       pc,
               tblslvconsolidadopedido      cp,
               tblslvconsolidadopedidorel   cprel,
               pedidos                      pe,
               descripcionesarticulos       des
         where pe.idpedido = cprel.idpedido
           and cprel.idconsolidadopedido = cp.idconsolidadopedido
           and pc.idpedido = pe.idpedido
           and pc.cdarticulo = des.cdarticulo
           and cp.idconsolidadocomi =  &p_idpedido
           order by pc.cdarticulo   ;
     
                 select * 
                    from tblslvpordistrib pdis
                    where pdis.idconsolidado=&p_idpedido
                    and pdis.cdtipo=&c_TareaConsolidadoComi
                    order by pdis.cdarticulo   ;
                    
                    
                    
select r.*,rd.* from tblslvremito r,
              tblslvremitodet rd,
              tblslvtarea ta
where r.idtarea = ta.idtarea
  and ta.idconsolidadocomi = &p_idpedido
  and r.idremito = rd.idremito
  order by rd.cdarticulo   ;                    
      
                   select 
      distinct do.cdcomprobante,
               do.cdpuntoventa,
               do.sqcomprobante,
               dmm.*
          from tblslvconsolidadopedido     cp,
               tblslvconsolidadopedidorel  cprel,
               pedidos                     pe,
               detallepedidos              dp,
               movmateriales               mm,
               detallemovmateriales        dmm,
               documentos                  do
         where cp.idconsolidadopedido = cprel.idconsolidadopedido
           and cprel.idpedido = pe.idpedido
           and pe.idpedido = mm.idpedido
           and pe.idpedido = dp.idpedido
           and mm.idmovmateriales = do.idmovmateriales
           and mm.idmovmateriales = dmm.idmovmateriales          
           and cp.idconsolidadocomi = &p_idpedido
           order by dmm.cdarticulo   ;
