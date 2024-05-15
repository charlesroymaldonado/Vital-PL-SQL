PL/SQL Developer Test script 3.0
14
declare
  -- Non-scalar parameters require additional processing 
  p_idcomisionista pkg_slv_consolidam.arr_identidadcomi;
begin
  -- Call the procedure
  p_idcomisionista(1):='{5D7DC84F-23DD-4621-9B6E-55A43CA2284B}  ';
  p_idcomisionista(2):='{6E2F8690-2CA8-49E3-BAE1-173A1631C2E4}  ';  
  p_idcomisionista(3):='{9F6C6307-FFC5-4E00-AD6E-84147FFD6D43}  ';
  p_idcomisionista(4):='{A993F1E4-DAF2-46EA-AD6C-A457F49B600E}  ';  
  pkg_slv_consolidam.getpedidossinconsolidar(p_dthasta => :p_dthasta,
                                             p_idcanal => :p_idcanal,
                                             p_idcomisionista => p_idcomisionista,
                                             p_cursor => :p_cursor);
end;
3
p_dthasta
1
10/02/2020
12
p_idcanal
1
CO TE VE
5
p_cursor
1
<Cursor>
116
0
