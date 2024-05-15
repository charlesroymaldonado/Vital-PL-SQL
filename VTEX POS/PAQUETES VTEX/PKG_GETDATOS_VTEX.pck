create or replace package PKG_GETDATOS_VTEX is

  -- Author  : CMALDONADO
  -- Created : 12/11/2020 8:14:18 a. m.
  -- Purpose : para manejar los datos de integración con plataforma VTEX
  
   TYPE CURSOR_TYPE IS REF CURSOR;
   
   PROCEDURE GetArticulos(p_fecha IN date, Cur_Out Out Cursor_Type);

end PKG_GETDATOS_VTEX;
/
create or replace package body PKG_GETDATOS_VTEX is

  /*******************************************************************************************
  * Obtiene cursor con todos los artÃ­culos nuevos o modificados desde una fecha
  * %v 17/05/2017 - IAquilano
  *******************************************************************************************/

  PROCEDURE GetArticulos(p_fecha IN date, Cur_Out Out Cursor_Type) IS

    v_modulo varchar2(100) := 'PKG_GetDatos.GetArticulos';

  BEGIN

    OPEN cur_out FOR
      SELECT a.cdarticulo,
             a.vldescripcion,
             a.dssectorc,
             a.dsdepartamento,
             a.dsuniverso,
             a.dscategoria,
             a.dssubcategoria,
             a.dssegmento,
             a.dssubsegmento,
             a.vluxb,
             a.icalcohol,
             a.vlpesopromedio,
             a.dtcreacion,
             a.dtactualizacion,
             case
               when a.vluxb = 1 or
                    (a.icun = 1 and
                    (select 1
                        from tbl_aux_art_unidad b
                       where b.dsuniverso = a.dsuniverso
                         and b.dscategoria = a.dscategoria
                         and a.dssubcategoria = b.dssubcategoria) = 0) or
                    (a.vluxb > 1 and (select 1
                        from tbl_aux_art_unidad b
                       where b.dsuniverso = a.dsuniverso
                         and b.dscategoria = a.dscategoria
                         and a.dssubcategoria = b.dssubcategoria) = 1 and a.icun = 1) then
                '1'
               else
                '0'
             end as icun, --'0' as icun,--a.icun, --harcodeamos 0 para que solo se venda por bto
             a.icpza,
             case
               when a.vluxb > 1 then
                 '1'
                 else
                '0'
             end as icbto,
             a.iciva0,
             a.icun as icuncf,
             a.icbto as icbtocf,
             a.icpza as icpzacf,
             case
               when exists (select 1 from articulospropios aa where aa.cdarticulo = a.cdarticulo) then
                 '1'
                 else
                 '0'
               end as icmarcapropia
        FROM articulos a
       WHERE a.dtcreacion >= nvl(p_fecha, a.dtcreacion)
          or a.dtactualizacion >= nvl(p_fecha, a.dtactualizacion)
       order by 3, 4, 5, 6, 7, 8, 9;

  EXCEPTION
    WHEN OTHERS THEN
      pkg_log_general.write(1,
                            'Modulo: ' || v_Modulo || '  Error: ' ||
                            SQLERRM);
      raise;
  END GetArticulos;

end PKG_GETDATOS_VTEX;
/
