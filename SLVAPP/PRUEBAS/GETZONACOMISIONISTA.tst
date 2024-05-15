PL/SQL Developer Test script 3.0
9
declare
  -- Non-scalar parameters require additional processing 
  p_idcomisionista pkg_slv_consolidam.arr_identidadcomi;
begin
  -- Call the procedure
  p_IdComisionista(1):=NULL;
  pkg_slv_consolidam.getzonacomisionistas(p_idcomisionista => p_idcomisionista,
                                          p_cursor => :p_cursor);
end;
1
p_cursor
1
<Cursor>
116
2
v_idcomi
