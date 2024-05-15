        select * from tblslvdistribucionpedfaltante f,
                      tblslvpedfaltanterel rel
           where f.idpedfaltanterel=rel.idpedfaltanterel;
        select dfa.cdarticulo,
               cp.idconsolidadopedido,               
               sum(dfa.qtunidadmedidabase) base,
               sum(dfa.qtpiezas) piezas   
          from tblslvconsolidadopedido            cp,
               tblslvdistribucionpedfaltante      dfa,
               tblslvpedfaltanterel               frel
         where cp.idconsolidadopedido = frel.idconsolidadopedido
           and dfa.idpedfaltanterel = frel.idpedfaltanterel                   
           and frel.idpedfaltante = &p_IdPedFaltante
      group by dfa.cdarticulo,
               cp.idconsolidadopedido;

       select * from tblslvconsolidadopedidodet d
               where d.idconsolidadopedido=9;
               
        select * from  tblslvdistribucionpedfaltante      dfa
        where   dfa.cdarticulo='0105095 ';
        
        select * from tblslvpedfaltantedet df
        where df.cdarticulo='0105095 ';  
               
