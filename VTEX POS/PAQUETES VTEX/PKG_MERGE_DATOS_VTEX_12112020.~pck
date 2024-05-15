create or replace package PKG_MERGE_DATOS_VTEX is

  -- Author  : CMALDONADO
  -- Created : 12/11/2020 7:43:10 a. m.
  -- Purpose : para manejar los datos de integración con plataforma VTEX
  
   type cursor_type Is Ref Cursor;

  type t_articulos is table of articulos%rowtype index by binary_integer;
  type t_articulos_pipe is table of articulos%rowtype;

end PKG_MERGE_DATOS_VTEX;
/
create or replace package body PKG_MERGE_DATOS_VTEX is
 g_l_articulos t_articulos;

 
/**************************************************************************************************
* Carga en una tabla global en memoria los datos de todos los artículos activos en AC
* %v 04/05/2017 - APW
* %v 27/02/2018 - APW - Aplico HOGAR a otras categorías
* %v 02/03/2020 - IAquilano: Cambio vista de articulos_frescos por articulos_excluidos
***************************************************************************************************/
PROCEDURE CargarTablaArticulos IS
  v_Modulo varchar2(100) := 'PKG_MERGE_DATOS.CargarTablaArticulos';
  i        binary_integer := 1;

BEGIN

  for r_articulo in (select distinct ar.cdarticulo,
                                     da.vldescripcion,
                                     tse.dssectorc,
                                     case
                                       when tse.dssectorc = 'FOOD' and
                                            d.dsdepartamento in
                                            ('KIOSCO', 'FRESCOS') then
                                        'ALMACEN'
                                       when tse.dssectorc = 'NON FOOD' and
                                            d.dsdepartamento in
                                            ('AUTOMOTOR',
                                             'BAZAR',
                                             'BEBES Y NIÑOS',
                                             'FERRETERIA',
                                             'FIESTAS',
                                             'ILUMINACION Y ELECTRICIDAD',
                                             'JUGUETERIA',
                                             'LIBRERIA',
                                             'MASCOTAS',
                                             'MUEBLES',
                                             'TEXTIL') then
                                        'HOGAR'
                                       else
                                        d.dsdepartamento
                                     end dsdepartamento,
                                     case  
                                       when tse.dssectorc = 'NON FOOD' and
                                            d.dsdepartamento in
                                            ('AUTOMOTOR',
                                             'BAZAR',
                                             'BEBES Y NIÑOS',
                                             'FERRETERIA',
                                             'FIESTAS',
                                             'ILUMINACION Y ELECTRICIDAD',
                                             'JUGUETERIA',
                                             'LIBRERIA',
                                             'MASCOTAS',
                                             'MUEBLES',
                                             'TEXTIL') then
                                        d.dsdepartamento
                                       else
                                        u.dsuniverso
                                        end dsuniverso,
                                     case  
                                       when tse.dssectorc = 'NON FOOD' and
                                            d.dsdepartamento in
                                            ('AUTOMOTOR',
                                             'BAZAR',
                                             'BEBES Y NIÑOS',
                                             'FERRETERIA',
                                             'FIESTAS',
                                             'ILUMINACION Y ELECTRICIDAD',
                                             'JUGUETERIA',
                                             'LIBRERIA',
                                             'MASCOTAS',
                                             'MUEBLES',
                                             'TEXTIL') then
                                        u.dsuniverso
                                       else
                                        c.dscategoria
                                        end dscategoria,
                                     case  
                                       when tse.dssectorc = 'NON FOOD' and
                                            d.dsdepartamento in
                                            ('AUTOMOTOR',
                                             'BAZAR',
                                             'BEBES Y NIÑOS',
                                             'FERRETERIA',
                                             'FIESTAS',
                                             'ILUMINACION Y ELECTRICIDAD',
                                             'JUGUETERIA',
                                             'LIBRERIA',
                                             'MASCOTAS',
                                             'MUEBLES',
                                             'TEXTIL') then
                                        c.dscategoria
                                       else
                                        sc.dssubcategoria
                                        end dssubcategoria,
                                     case  
                                       when tse.dssectorc = 'NON FOOD' and
                                            d.dsdepartamento in
                                            ('AUTOMOTOR',
                                             'BAZAR',
                                             'BEBES Y NIÑOS',
                                             'FERRETERIA',
                                             'FIESTAS',
                                             'ILUMINACION Y ELECTRICIDAD',
                                             'JUGUETERIA',
                                             'LIBRERIA',
                                             'MASCOTAS',
                                             'MUEBLES',
                                             'TEXTIL') then
                                        sc.dssubcategoria
                                       else
                                        s.dssegmento
                                        end dssegmento,
                                      case  
                                       when tse.dssectorc = 'NON FOOD' and
                                            d.dsdepartamento in
                                            ('AUTOMOTOR',
                                             'BAZAR',
                                             'BEBES Y NIÑOS',
                                             'FERRETERIA',
                                             'FIESTAS',
                                             'ILUMINACION Y ELECTRICIDAD',
                                             'JUGUETERIA',
                                             'LIBRERIA',
                                             'MASCOTAS',
                                             'MUEBLES',
                                             'TEXTIL') then
                                        s.dssegmento
                                       else
                                        ss.dssubsegmento
                                        end dssubsegmento,
                                     ar.cdunidadventaminima,
                                     decode(trim(ar.cdunidadventaminima),
                                            'UN',
                                            1,
                                            0) icUN,
                                     CASE
                                       WHEN trim(ar.cdunidadventaminima) IN
                                            ('PZA', 'KG') THEN
                                        1
                                       ELSE
                                        0
                                     END icPZA,
                                     CASE
                                       WHEN trim(ar.cdunidadventaminima) NOT IN
                                            ('PZA', 'KG') THEN
                                        CASE
                                          WHEN n_pkg_vitalpos_materiales_s.GetUxB(ar.cdarticulo,
                                                                                  'BTO') >= 1 THEN
                                           1
                                          ELSE
                                           0
                                        END
                                       ELSE
                                        0
                                     END icBTO,
                                     decode(nvl(tiva.cdarticulo, 0), 0, 0, 1) as iciva0
                       from articulos_s                    ar,
                            descripcionesarticulos_s       da,
                            tblctgryarticulocategorizado_s a,
                            tblctgrydepartamento_s         d,
                            tblctgryuniverso_s             u,
                            tblctgrycategoria_s            c,
                            tblctgrysubcategoria_s         sc,
                            tblctgrysegmento_s             s,
                            tblctgrysubsegmento_s          ss,
                            tblctgrysectorc_S              tse,
                            tblivaarticulo_s               tiva
                      where ar.cdarticulo = da.cdarticulo
                        and ar.cdestadoplu = '00'
                        and tiva.cdarticulo(+) = ar.cdarticulo
                        and not exists
                      (select 1
                               from articulosnocomerciales_s t
                              where t.cdarticulo = a.cdarticulo)
                        and not exists
                      (select 1
                               from articulos_excluidos h
                              where h.cdarticulo = ar.cdarticulo) --agrego tabla articulos excluidos 
                        and substr(ar.cdarticulo, 1, 1) <> 'A'
                        and a.cddepartamento = d.cddepartamento(+)
                        and a.cduniverso = u.cduniverso(+)
                        and a.cdcategoria = c.cdcategoria(+)
                        and a.cdsubcategoria = sc.cdsubcategoria(+)
                        and a.cdsegmento = s.cdsegmento(+)
                        and a.cdsubsegmento = ss.cdsubsegmento(+)
                        and a.cdsectorc = tse.cdserctorc
                        and a.cdarticulo = ar.cdarticulo
                        and ar.cddrugstore not in ('EX', 'DE', 'CP')) loop
    g_l_articulos(i).cdarticulo := r_articulo.cdarticulo;
    g_l_articulos(i).vldescripcion := r_articulo.vldescripcion;
    g_l_articulos(i).dssectorc := r_articulo.dssectorc;
    g_l_articulos(i).dsdepartamento := r_articulo.dsdepartamento;
    g_l_articulos(i).dsuniverso := r_articulo.dsuniverso;
    g_l_articulos(i).dscategoria := r_articulo.dscategoria;
    g_l_articulos(i).dssubcategoria := r_articulo.dssubcategoria;
    g_l_articulos(i).dssegmento := r_articulo.dssegmento;
    g_l_articulos(i).dssubsegmento := r_articulo.dssubsegmento;
    g_l_articulos(i).cdunidadventaminima := r_articulo.cdunidadventaminima;
    g_l_articulos(i).vluxb := n_pkg_vitalpos_materiales_s.getuxb(r_articulo.cdarticulo);
    g_l_articulos(i).icalcohol := pkg_core_materiales.GetRequiereREBA(r_articulo.cdarticulo);
    g_l_articulos(i).vlpesopromedio := pkg_core_materiales.GetPesoPromedio(r_articulo.cdarticulo);
    g_l_articulos(i).cdunidadbase := pkg_core_materiales.GetUnidadBase(r_articulo.cdarticulo);
    g_l_articulos(i).qtunidadbase := pkg_core_materiales.GetQtUnidadBase(r_articulo.cdarticulo);
    g_l_articulos(i).icun := r_articulo.icun;
    g_l_articulos(i).icpza := r_articulo.icpza;
    g_l_articulos(i).icbto := r_articulo.icbto;
    g_l_articulos(i).dtcreacion := sysdate;
    g_l_articulos(i).dtactualizacion := sysdate;
    g_l_articulos(i).iciva0 := r_articulo.iciva0;
    i := i + 1;
  end loop;

EXCEPTION
  WHEN OTHERS THEN
    pkg_log_general.write(1,
                          'Modulo: ' || v_Modulo || '  Error: ' || SQLERRM);
END CargarTablaArticulos;

/**************************************************************************************************
* Devuelve todos los datos de la tabla de artículos en memoria
* %v 04/05/2017 - APW
***************************************************************************************************/
FUNCTION PipeArticulos RETURN t_articulos_pipe
  PIPELINED IS
  i binary_integer := 0;
BEGIN
  i := g_l_articulos.FIRST;
  while i is not null loop
    pipe row(g_l_articulos(i));
    i := g_l_articulos.NEXT(i);
  end loop;
  return;
EXCEPTION
  when others then
    null;
END PipeArticulos;

/**************************************************************************************************
* Carga datos de todas los articulos para la carga inicial
* %v 27/04/2017 - APW
***************************************************************************************************/
PROCEDURE CargarArticulos IS
  v_Modulo varchar2(100) := 'PKG_MERGE_DATOS.CargarArticulos1';

BEGIN

  execute immediate 'truncate table articulos';
  g_l_articulos.delete;
  -- llena la tabla en memoria
  CargarTablaArticulos;
  -- la inserta en la definitiva
  insert into articulos
    select * From Table(PipeArticulos);

  commit;

EXCEPTION
  WHEN OTHERS THEN
    pkg_log_general.write(1,
                          'Modulo: ' || v_Modulo || '  Error: ' || SQLERRM);
END CargarArticulos;

/**************************************************************************************************
* Carga artículos nuevos, actualiza los modificados y pasa a otra tabla los que detecta como baja
* %v 04/05/2017 - APW
***************************************************************************************************/
PROCEDURE RefrescarArticulos IS
  v_Modulo varchar2(100) := 'PKG_MERGE_DATOS.RefrescarArticulos';

BEGIN

  g_l_articulos.delete;
  -- llena la tabla en memoria con los articulos activos de AC
  CargarTablaArticulos;
  -- la inserta en una temporal para despues comparar

      insert into tmp_articulos
      select cdarticulo, vldescripcion, cdunidadventaminima, vluxb, icalcohol, vlpesopromedio, cdunidadbase, qtunidadbase, dtcreacion,
      dtactualizacion, dssectorc, dsdepartamento, dsuniverso, dscategoria, dssubcategoria, dssegmento, dssubsegmento, icun, icpza, icbto, iciva0
      From Table(PipeArticulos);

  -- no hago commit porque elimina los datos cargados -- commit;

  merge into articulos tec
  using tmp_articulos tac
  on (tec.cdarticulo = tac.cdarticulo)
  when not matched then -- altas
    insert
      (cdarticulo,
       vldescripcion,
       dssectorc,
       dsdepartamento,
       dsuniverso,
       dscategoria,
       dssubcategoria,
       dssegmento,
       dssubsegmento,
       cdunidadventaminima,
       vluxb,
       icalcohol,
       vlpesopromedio,
       cdunidadbase,
       qtunidadbase,
       dtcreacion,
       dtactualizacion,
       icun,
       icpza,
       icbto,
       iciva0)
    values
      (tac.cdarticulo,
       tac.vldescripcion,
       tac.dssectorc,
       tac.dsdepartamento,
       tac.dsuniverso,
       tac.dscategoria,
       tac.dssubcategoria,
       tac.dssegmento,
       tac.dssubsegmento,
       tac.cdunidadventaminima,
       tac.vluxb,
       tac.icalcohol,
       tac.vlpesopromedio,
       tac.cdunidadbase,
       tac.qtunidadbase,
       sysdate,
       sysdate,
       tac.icun,
       tac.icpza,
       tac.icbto,
       tac.iciva0)
  when matched then -- modificaciones
     update
       set tec.vldescripcion       = tac.vldescripcion,
           tec.dssectorc           = tac.dssectorc,
           tec.dsdepartamento      = tac.dsdepartamento,
           tec.dsuniverso          = tac.dsuniverso,
           tec.dscategoria         = tac.dscategoria,
           tec.dssubcategoria      = tac.dssubcategoria,
           tec.dssegmento          = tac.dssegmento,
           tec.dssubsegmento       = tac.dssubsegmento,
           tec.cdunidadventaminima = tac.cdunidadventaminima,
           tec.vluxb               = tac.vluxb,
           tec.icalcohol           = tac.icalcohol,
           tec.vlpesopromedio      = tac.vlpesopromedio,
           tec.cdunidadbase        = tac.cdunidadbase,
           tec.qtunidadbase        = tac.qtunidadbase,
           tec.dtcreacion          = tac.dtcreacion,
           tec.icun                = tac.icun,
           tec.icpza               = tac.icpza,
           tec.icbto               = tac.icbto,
           tec.dtactualizacion     = sysdate,
           tec.iciva0              = tac.iciva0
     where -- solo se actualizan si hubo algun cambio
     tec.vldescripcion <> tac.vldescripcion
     or tec.dssectorc <> tac.dssectorc
     or tec.dsdepartamento <> tac.dsdepartamento
     or tec.dsuniverso <> tac.dsuniverso
     or tec.dscategoria <> tac.dscategoria
     or tec.dssubcategoria <> tac.dssubcategoria
     or tec.dssegmento <> tac.dssegmento
     or tec.dssubsegmento <> tac.dssubsegmento
     or tec.cdunidadventaminima <> tac.cdunidadventaminima
     or tec.vluxb <> tac.vluxb
     or tec.icalcohol <> tac.icalcohol
     or tec.vlpesopromedio <> tac.vlpesopromedio
     or tec.cdunidadbase <> tac.cdunidadbase
     or tec.qtunidadbase <> tac.qtunidadbase
     or tec.icun         <> tac.icun
     or tec.icpza        <> tac.icpza
     or tec.icbto        <> tac.icbto
     or nvl(tec.iciva0, 0)       <> nvl(tac.iciva0, 0);

  commit;

EXCEPTION
  WHEN OTHERS THEN
    pkg_log_general.write(1,
                          'Modulo: ' || v_Modulo || '  Error: ' || SQLERRM);
END RefrescarArticulos;



end PKG_MERGE_DATOS_VTEX;
/
