PL/SQL Developer Test script 3.0
12
begin
  -- Call the procedure
  pkg_slv_tareas.setregistrarpicking(p_idpersona => :p_idpersona,
                                     p_idremito => :p_idremito,
                                     p_nrocarreta => :p_nrocarreta,
                                     p_cdbarras => :p_cdbarras,
                                     p_cantidad => :p_cantidad,
                                     p_cdarticulo => :p_cdarticulo,
                                     p_idtarea => :p_idtarea,
                                     p_ok => :p_ok,
                                     p_error => :p_error);
end;
9
p_idpersona
1
{FD95DC1D-F3CD-4216-B87D-6BEBEE72D4E5}
5
p_idremito
1
0
4
p_nrocarreta
1
0
5
p_cdbarras
1
7790077000487
5
p_cantidad
1
20
4
p_cdarticulo
1
0126464 
5
p_idtarea
1
4
4
p_ok
1
1
4
p_error
0
5
8
 v_cdunidad
v_cantidad
p_icgeneraremito 
 p_idRemito
v_icgeneraremito
 v_res
v_cant
tarea.idconsolidadom
