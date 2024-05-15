PL/SQL Developer Test script 3.0
27
declare
  -- Non-scalar parameters require additional processing 
  p_transid pkg_slv_consolidam.arr_transid;
  p_idcomisionista pkg_slv_consolidam.arr_identidadcomi;
begin
  
  /*p_idcomisionista(1):='{6E2F8690-2CA8-49E3-BAE1-173A1631C2E4}  ';  
  p_idcomisionista(2):='{9F6C6307-FFC5-4E00-AD6E-84147FFD6D43}  ';
  p_idcomisionista(3):='{A993F1E4-DAF2-46EA-AD6C-A457F49B600E}  ';
  p_transid(1):='4817848F17768A86E05001AC3C056B07        ';
  p_transid(2):='48193E6D425AA44EE05001AC3C057012        ';
  p_transid(3):='39E46C7435F511CDE05001AC3C055458        ';
  p_transid(4):='487E382FCD1CBC99E05001AC3C053538_HIJO';  */
  /* p_idcomisionista(1):= NULL;
   p_transid(1):= NULL;*/
  p_transid(1):='88F120AC1BCA2182E0533E0501AC8E41       ';
  p_transid(2):='76C98F7BCDD62FBCE05001AC3902450C        ';
  p_idcomisionista(1):='';
  -- Call the procedure
  pkg_slv_consolidam.getprevisualizarpedidos(p_qtbtoconsolidar => :p_qtbtoconsolidar,
                                             p_transid => p_transid,
                                             p_idcomisionista => p_idcomisionista,
                                             p_idpersona => :p_idpersona,
                                             p_ok => :p_ok,
                                             p_error => :p_error,
                                             p_cursor => :p_cursor);
end;
5
p_qtbtoconsolidar
1
1
4
p_idpersona
1
﻿A24AA1E78DD6AC37E03000C8EF003B71
5
p_ok
0
4
p_error
0
5
p_cursor
1
<Cursor>
116
0
