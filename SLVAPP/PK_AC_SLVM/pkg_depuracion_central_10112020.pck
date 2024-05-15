CREATE OR REPLACE PACKAGE pkg_depuracion_central is

PROCEDURE DepurarPromociones (p_fecha  varchar2,
                              p_error  out varchar2);
                              
PROCEDURE DepurarSLVM (p_numDias  in integer,
                       p_error    out varchar2);                              

end pkg_depuracion_central;
/
CREATE OR REPLACE PACKAGE BODY pkg_depuracion_central is
/****************************************************************************************
* 01/09/14
* PToledo
* Depuraciones de datos en AC
*****************************************************************************************/


/****************************************************************************************
* 01/09/14
* PToledo
* Tablas de promociones
*****************************************************************************************/
PROCEDURE DepurarPromociones (p_fecha  varchar2,
                              p_error  out varchar2) IS

  v_Modulo          varchar2(100)  := 'PKG_DEPURACION_CENTRAL.DepurarPromociones';
  v_tablas          varchar2(100)  := 'PROMOCIONES';
  v_fecha           date:=trunc(sysdate );
  v_maxfecha        date:=trunc(sysdate );


  cursor promo is
  select tb.id_promo, tb.cdpromo, tb.vigencia_desde
  from   tblpromo tb
  where  vigencia_desde <=to_date(p_fecha,'dd/mm/yyyy')
  and    tb.id_promo <>'VP000001' -- que no sea descuento al personal
  and    trunc(sysdate) not between vigencia_desde and vigencia_hasta -- que no este vigente!!
  and    not exists (--- ni está redimiendo cupones
                     select 1 from tblpromo p, tblpromo_accion a, tblpromo_accion_parametro aph, tblpromo_accion_parametro apd
                     where p.id_promo = tb.id_promo
                     and   p.id_promo = a.id_promo
                     and   a.id_promo_accion = aph.id_promo_accion
                     and   aph.id_promo_parametro = 16
                     and   a.id_promo_accion = apd.id_promo_accion
                     and   apd.id_promo_parametro = 15
                     and   trunc(sysdate) between to_date(apd.valor,'dd/mm/yyyy') and to_date(apd.valor,'dd/mm/yyyy'))
  order by tb.vigencia_desde;

BEGIN
  
  insert into tbldepuracion  (dtdepurar, DSPASO, DTCOMMIT, DSGRUPOTABLAS)
  values (to_date(p_fecha, 'dd/mm/yyyy') , 'INICIO PROCESO', sysdate, v_tablas) ;

  FOR prom IN promo LOOP

  v_maxfecha:= prom.vigencia_desde;

  --TBLPROMO_CONDICION_PARAMETRO
  delete
   from tblpromo_condicion_parametro tap
   where tap.id_promo_condicion in (select ta.id_promo_condicion
                                    from tblpromo_condicion ta
                                    where ta.id_promo =prom.id_promo);
   --TBLPROMO_CONDICION_ARTICULO
   delete
   from tblpromo_condicion_articulo taa
   where taa.id_promo_condicion in ( select ta.id_promo_condicion
                                     from tblpromo_condicion ta
                                     where ta.id_promo =prom.id_promo);

   --TBLPROMO_CONDICION_ENTIDAD
   delete from tblpromo_condicion_entidad cee
   where  cee.id_promo_condicion in( select ta.id_promo_condicion
                                     from tblpromo_condicion ta
                                     where ta.id_promo =prom.id_promo);

   --TBLPROMO_CONDICION
   delete
   from tblpromo_condicion ta
   where ta.id_promo =prom.id_promo;

   --TBLPROMO_ACCION_PARAMETRO
   delete
   from tblpromo_accion_parametro tap
   where tap.id_promo_accion in (select ta.id_promo_accion
                                  from tblpromo_accion ta
                                  where ta.id_promo =prom.id_promo);
   --TBLPROMO_ACCION_ARTICULO
   delete
   from tblpromo_accion_articulo taa
   where taa.id_promo_accion in ( select ta.id_promo_accion
                                  from tblpromo_accion ta
                                  where ta.id_promo =prom.id_promo);
   --TBLPROMO_ACCION
   delete
   from tblpromo_accion ta
   where ta.id_promo =prom.id_promo;

   --TBLPROMO_CANAL
   delete
   from tblpromo_canal ca
   where ca.id_promo=prom.id_promo;

   --TBLPROMO_SUCURSAL
   delete
   from tblpromo_sucursal su
   where su.id_promo=prom.id_promo;

   --TBLPROMO
   delete
   from  tblpromo t where t.id_promo=prom.id_promo;

   if v_fecha <> prom.vigencia_desde then ---hago commit por cambio de fecha_desde y registro el avance
      v_fecha := prom.vigencia_desde ;

   insert into tbldepuracion  (dtdepurar, DSPASO, DTCOMMIT, DSGRUPOTABLAS)
      values (to_date(p_fecha, 'dd/mm/yyyy') , 'COMMIT hasta: '||to_char(v_fecha, 'dd/mm/yyyy'), sysdate, v_tablas) ;
      commit;
   end if;


  END LOOP;

  insert into tbldepuracion (dtdepurar, DSPASO, DTCOMMIT, DSGRUPOTABLAS)
  values (to_date(p_fecha, 'dd/mm/yyyy'), 'ULTIMO COMMIT hasta: '||to_char(v_fecha, 'dd/mm/yyyy'), sysdate, v_tablas) ;

  delete tbldepuracion d where d.dtcommit < v_maxfecha - 30; -- borro los registros de log anteriores a 1 mes
  COMMIT;
  p_error:='OK';

  EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2, 'Modulo: '||v_Modulo||'  Error: ' || SQLERRM||' En fecha: ' ||v_maxfecha);
      p_error:='ERROR: '||sqlerrm;
      ROLLBACK;
END DepurarPromociones;

/****************************************************************************************
* 10/11/2020 - ChM limpiar tablas de SLVM del sysdate menos el valor del parametro en días
*****************************************************************************************/
PROCEDURE DepurarSLVM (p_numDias  in integer,
                       p_error    out varchar2) IS

  v_Modulo          varchar2(100)  := 'PKG_DEPURACION_CENTRAL.DepurarSLVM';
 BEGIN

Delete tblslvcontrolremitodet crd where crd.idcontrolremito in 
                                        (select cr.idcontrolremito 
                                           from tblslvcontrolremito cr 
                                          where cr.dtinicio<=trunc(sysdate-p_numDias));

Delete tblslvcontrolremito cr where cr.idremito in                             
                                        (select r.idremito
                                           from tblslvremito r 
                                          where r.dtremito<=trunc(sysdate-p_numDias));

Delete tblslvremito re where re.dtremito<=trunc(sysdate-p_numDias);

Delete tblslvtareadet td where td.idtarea in 
                                   (select ta.idtarea
                                      from tblslvtarea ta 
                                     where ta.dtinsert<=trunc(sysdate-p_numDias));
                                     
Delete tblslvtarea ta where ta.dtinsert<=trunc(sysdate-p_numDias);

Delete tblslvpedfaltanterel frel where frel.dtinsert<=trunc(sysdate-p_numDias);

Delete tblslvconsolidadopedidorel prel where prel.idconsolidadopedido in 
                                             (select cp.idconsolidadopedido 
                                                from tblslvconsolidadopedido cp 
                                                where cp.dtinsert<=trunc(sysdate-p_numDias));
                                                
Delete tblslvconsolidadopedido cp where cp.dtinsert<=trunc(sysdate-p_numDias);

Delete tblslvconsolidadomdet cmd where cmd.idconsolidadom in 
                                      (select cm.idconsolidadom 
                                         from tblslvconsolidadom cm 
                                        where cm.dtinsert<=trunc(sysdate-p_numDias));
                                        
Delete tblslvconsolidadom cm where cm.dtinsert<=trunc(sysdate-p_numDias);

p_error:='OK';
commit; 

  EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2, 'Modulo: '||v_Modulo||'  Error: ' || SQLERRM||' En fecha menor a: ' ||trunc(sysdate-p_numDias));
      p_error:='ERROR: '||sqlerrm;
      ROLLBACK;
END DepurarSLVM;


end pkg_depuracion_central;
/
