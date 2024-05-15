PL/SQL Developer Test script 3.0
15
declare
  -- Non-scalar parameters require additional processing 
  p_cdarticulos pkg_slv_tareas.arr_cdarticulo;
begin
  -- Call the procedure
  p_cdarticulos(1):='0153078 ';
  p_cdarticulos(2):='0126464 ';
  pkg_slv_tareas.setasignaarticulosarmador(p_cdarticulos => p_cdarticulos,
                                           p_idconsolidado => :p_idconsolidado,
                                           p_tipotarea => :p_tipotarea,
                                           p_idpersona => :p_idpersona,
                                           p_idarmador => :p_idarmador,
                                           p_ok => :p_ok,
                                           p_error => :p_error);
end;
6
p_idconsolidado
1
2
4
p_tipotarea
1
1
4
p_idpersona
1
A24AA1E78DD6AC37E03000C8EF003B71        
5
p_idarmador
1
{FD95DC1D-F3CD-4216-B87D-6BEBEE72D4E5}  
5
p_ok
1
1
4
p_error
0
5
0
