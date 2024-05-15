--tareas del pedido 
 select * 
   from tblslvtarea ta,
        tblslvtareadet td        
 where ta.idtarea=td.idtarea
   and ta.idconsolidadopedido=&p_idpedido;
--remitos del pedido
  select rd.* 
   from tblslvtarea ta,
        tblslvremito re,
        tblslvremitodet rd
 where ta.idtarea=re.idtarea
   and re.idremito = rd.idremito
   and ta.idconsolidadopedido=&p_idpedido; 
-- detalle del consolidado pedido
select cpd.* 
   from tblslvconsolidadopedido cp,
        tblslvconsolidadopedidodet cpd
   where cp.idconsolidadopedido=cpd.idconsolidadopedido
     and cp.idconsolidadopedido= &p_idpedido; 
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
               des.vldescripcion
          from tblslvpedidoconformado       pc,
               tblslvconsolidadopedido      cp,
               tblslvconsolidadopedidorel   cprel,
               pedidos                      pe,
               descripcionesarticulos       des
         where pe.idpedido = cprel.idpedido
           and cprel.idconsolidadopedido = cp.idconsolidadopedido
           and pc.idpedido = pe.idpedido
           and pc.cdarticulo = des.cdarticulo
           and cp.idconsolidadopedido = &p_idpedido;  
 
 select * from DETPEDIDOCONFORMADO dpc
  where dpc.idpedido in (
                        select pc.idpedido                                    
                          from tblslvpedidoconformado       pc,
                               tblslvconsolidadopedido      cp,
                               tblslvconsolidadopedidorel   cprel,
                               pedidos                      pe,
                               descripcionesarticulos       des
                         where pe.idpedido = cprel.idpedido
                           and cprel.idconsolidadopedido = cp.idconsolidadopedido
                           and pc.idpedido = pe.idpedido
                           and pc.cdarticulo = des.cdarticulo
                           and cp.idconsolidadopedido =&p_idpedido ) ;         
           
    select * 
      from tblslvpordistrib pd
     where pd.cdtipo=25
       and pd.idconsolidado = &p_idpedido;  
       select * from tblslvconsolidadopedido cp where cp.idconsolidadopedido=&p_idpedido ;
     
select r.*,rd.* from tblslvremito r,
              tblslvremitodet rd,
              tblslvpedfaltanterel frel
where r.idpedfaltanterel = frel.idpedfaltanterel
  and frel.idconsolidadopedido = &p_idpedido
  and r.idremito = rd.idremito
  union all
  select r.*,rd.* from tblslvremito r,
              tblslvremitodet rd,
              tblslvtarea ta
where r.idtarea = ta.idtarea
  and ta.idconsolidadopedido = &p_idpedido
  and r.idremito = rd.idremito;
  
  
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
           and cp.idconsolidadopedido = &p_idpedido;
