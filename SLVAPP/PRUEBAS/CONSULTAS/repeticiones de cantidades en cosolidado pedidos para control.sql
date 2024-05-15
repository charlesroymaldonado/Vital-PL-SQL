      select cpd.cdarticulo,              
             count(cpd.cdarticulo) aparece,      
             nvl((select count (cpd2.qtunidadmedidabasepicking) 
                from tblslvconsolidadopedidodet cpd2,
                     tblslvconsolidadopedido cp2
               where cpd2.cdarticulo = &cpd
                 and cp2.idconsolidadopedido = cpd2.idconsolidadopedido
                 and nvl(cpd2.qtunidadmedidabasepicking,0)<>0
                 and cp2.idconsolidadocomi = &v_idcontrol
               group by cpd2.qtunidadmedidabasepicking
               /*having count (cpd2.qtunidadmedidabasepicking) >2*/),0)  repeticiones                        
         from tblslvconsolidadopedidodet cpd,
              tblslvconsolidadopedido    cp
        where cpd.idconsolidadopedido = cp.idconsolidadopedido
          and cp.idconsolidadocomi = &v_idcontrol
     group by cpd.cdarticulo;
     
     select cpd.* 
      from tblslvconsolidadopedido    cp,
           tblslvconsolidadopedidodet cpd
     where cp.idconsolidadocomi=&v_idcontrol
       and cp.idconsolidadopedido=cpd.idconsolidadopedido
     order by cpd.cdarticulo