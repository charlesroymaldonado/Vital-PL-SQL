select pe.idpedido,
                    dpe.cdarticulo,
                    pdi.qtunidadmedidabase,
                    pdi.qtpiezas,
                    dpe.ampreciounitario,
                    dpe.dsobservacion,
                    dpe.icresppromo,
                    dpe.cdpromo,
                    dpe.icresppromo,
                    sysdate dtinsert,
                    null dtupdate
               from pedidos                      pe,
                    detallepedidos               dpe,
                    tblslvconsolidadopedidorel   cprel,
                    tblslvconsolidadopedido      cp,
                    tblslvconsolidadopedidodet   cpd,
                    tblslvpordistrib             pdi
              where pe.idpedido = dpe.idpedido
                and pe.idpedido = cprel.idpedido
                and cprel.idconsolidadopedido = cp.idconsolidadopedido
                and cp.idconsolidadopedido = cpd.idconsolidadopedido
                and cpd.cdarticulo = dpe.cdarticulo
                and pdi.idpedido = pe.idpedido
                and pdi.idconsolidado = cp.idconsolidadopedido
                and pdi.cdarticulo = cpd.cdarticulo
                --  valida solo articulos en promo
                and pdi.artpromo = 1
                --  valida el tipo de tarea consolidado Pedido en la tabla distribuci�n
                and pdi.cdtipo = &c_TareaConsolidadoPedido
                --  excluyo pesables
                and nvl(cpd.qtpiezas,0)=0               
                --  excluyo linea de promo
                and dpe.icresppromo = 0
                --excluyo comisionistas
                and cp.idconsolidadocomi is null
                and cp.idconsolidadopedido = &p_idconsolidado
           -- ordenados por el que menos compr� en cantidad y art�culos solo as� funciona esta l�gica
           order by pdi.qtunidadmedidabase,
                    dpe.cdarticulo;
                    select * 
                    from tblslvpordistrib pdis
                    where pdis.idconsolidado=&p_idconsolidado
                    and pdis.cdtipo=&c_TareaConsolidadoPedido;
                    
                    select * 
                    from tblslvconsolidadopedidodet pd 
                    where pd.idconsolidadopedido=&p_idconsolidado ;
                    select * 
                    from tblslvconsolidadopedido cp
                    where cp.idconsolidadopedido=&p_idconsolidado
                    for update ;
                    
                    select * from tblslvconsolidadomdet md
                    where md.idconsolidadom=27;
                    
