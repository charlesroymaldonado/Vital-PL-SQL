                                 
--borrar el conteo detalle
delete tblslvconteodet cond 
 where cond.idconteo in ( select co.idconteo
                            from tblslvconteo co
                           where co.idcontrolremito in  (select cr.idcontrolremito
                                                           from tblslvcontrolremito cr
                                                          where cr.idremito = &p_idremito));                          
                                    
--borrar el conteo 
delete tblslvconteo co 
 where co.idcontrolremito in (select cr.idcontrolremito
                                from tblslvcontrolremito cr
                               where cr.idremito  = &p_idremito);                          
                          
--borrar el control remito detalle
delete tblslvcontrolremitodet crd
 where crd.idcontrolremito in (select cr.idcontrolremito
                                 from tblslvcontrolremito cr
                                where cr.idremito = &p_idremito);                                            
--borrar el control remito
delete tblslvcontrolremito cr
 where cr.idremito = &p_idremito;  
