 UPDATE pedidos ped
       SET ped.icestadosistema=2 
     WHERE ped.transid in (select m.transid 
                             from tbltmpslvconsolidadom M 
                            where m.idpersona = 'A24AA1E78DD6AC37E03000C8EF003B71        ');    

DELETE TBLSLVCONSOLIDADOPEDIDOREL;
DELETE TBLSLVCONSOLIDADOPEDIDODET;
DELETE TBLSLVCONSOLIDADOPEDIDO;
DELETE TBLSLVCONSOLIDADOCOMIDET;
DELETE TBLSLVCONSOLIDADOCOMI;
DELETE TBLSLVCONSOLIDADOMDET;
DELETE TBLSLVCONSOLIDADOM;


select * from  pedidos ped
where ped.transid in (select m.transid 
                             from tbltmpslvconsolidadom M 
                            where m.idpersona = 'A24AA1E78DD6AC37E03000C8EF003B71        ');    
