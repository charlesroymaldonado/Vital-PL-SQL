CREATE OR REPLACE PACKAGE PKG_TRANSFERIR_PEDIDOS Is

procedure Trae_pedidos;
procedure Trae_Prepedidos;

End;
/
CREATE OR REPLACE PACKAGE BODY PKG_TRANSFERIR_PEDIDOS Is

/* MPASSIOTTI - 15/05/2017 - Migracion CC - Trae los pedidos a procesar desde la base CC */
/* MPASSIOTTI - 01/06/2017 - Migracion CC - Se actualiza icestadosistema = 0 para los pedidos padre particionados  en AC. Quedaban en -1 */


procedure Trae_pedidos is

   v_modulo          varchar2(100) := 'PKG_TRANSFERIR_PEDIDOS.Trae_pedidos';
  -- v_idPedido        detallepedidos.idpedido%type;
 --  v_sqDetallePedido detallepedidos.sqdetallepedido%type;

--   TYPE T_PEDIDOS IS TABLE OF PEDIDOS%ROWTYPE INDEX BY BINARY_INTEGER;
--   V_PEDIDOS T_PEDIDOS;

 v_ok      integer;
 v_error   varchar2(300);

   Cursor c_pedidos is
    select p.IDPEDIDO IDPEDIDO,p.IDDOCTRX IDDOCTRX, nvl(pa.limite,0) limite
       From pedidos@CC.VITAL.COM.AR p
       left join tx_pedidos_particionar@CC.VITAL.COM.AR pa on (p.idpedido = pa.idpedido)
      where p.icestadosistema = -1;

begin
  --Traigo los pedidos de CC y cargo las tablas locales.
    FOR i in c_pedidos
    LOOP

      BEGIN
          --Insert documentos
          INSERT INTO DOCUMENTOS
          SELECT * FROM DOCUMENTOS@CC.VITAL.COM.AR WHERE IDDOCTRX = i.IDDOCTRX;
          --Insert pedidos
          INSERT INTO PEDIDOS
          SELECT * FROM PEDIDOS@CC.VITAL.COM.AR WHERE IDPEDIDO = i.IDPEDIDO;
          --Insert detallepedidos
          INSERT INTO DETALLEPEDIDOS
          SELECT * FROM DETALLEPEDIDOS@CC.VITAL.COM.AR WHERE IDPEDIDO = i.IDPEDIDO;
          --Insert observacionespedido
          INSERT INTO OBSERVACIONESPEDIDO
          SELECT * FROM OBSERVACIONESPEDIDO@CC.VITAL.COM.AR WHERE IDPEDIDO = i.IDPEDIDO;
          --Insert tx_pedidos_insert
          INSERT INTO TX_PEDIDOS_INSERT
          SELECT * FROM TX_PEDIDOS_INSERT@CC.VITAL.COM.AR WHERE IDPEDIDO = i.IDPEDIDO;
          --Insert tx_pedidos_particionar
          INSERT INTO TX_PEDIDOS_PARTICIONAR
          SELECT * FROM TX_PEDIDOS_PARTICIONAR@CC.VITAL.COM.AR WHERE IDPEDIDO = i.IDPEDIDO;
      EXCEPTION
        WHEN OTHERS THEN
          n_pkg_vitalpos_log_general.write(2, 'Modulo: '||v_modulo||'  Error al traer info de CC: ' || SQLERRM);
          ROLLBACK;
      END;

      --Particiono el pedido en caso de ser necesario
      If i.limite != 0 then
            BEGIN
              pkg_dividir_pedido.dividir(i.IDPEDIDO, i.LIMITE,v_ok, v_error);

			  --MPASSIOTTI - 01/06/2017 - Migracion CC - Si se particiona, se pasa el pedido padre a 0. Dividirpedido lo elimina de tx_pedidos_insert
              update pedidos set icestadosistema = 0  where idpedido = i.IDPEDIDO;

              delete TX_PEDIDOS_PARTICIONAR WHERE IDPEDIDO = i.IDPEDIDO;
              delete TX_PEDIDOS_PARTICIONAR@CC.VITAL.COM.AR WHERE IDPEDIDO = i.IDPEDIDO;
            EXCEPTION
            WHEN OTHERS THEN
              n_pkg_vitalpos_log_general.write(2, 'Modulo: '||v_modulo||'  Error al dividir pedido: ' || SQLERRM);
              ROLLBACK;
            END;
      END IF;

      --actualizo remoto para que no vuelva a traer los registros
      update pedidos@CC.VITAL.COM.AR set icestadosistema = 0 where IDPEDIDO = i.IDPEDIDO;
      delete TX_PEDIDOS_INSERT@CC.VITAL.COM.AR where IDPEDIDO = i.IDPEDIDO;


    END LOOP;

--una vez que tengo todas las tablas locales cargadas y actualizadas en base CC, modifico valor local para enviar a tiendas.
    BEGIN
       update pedidos
          set icestadosistema = 0
        where idpedido in (select idpedido from TX_PEDIDOS_INSERT)
          and icestadosistema = -1;
    EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2, 'Modulo: '||v_modulo||'  Error al actualizar pedidos de -1: ' || SQLERRM);
      ROLLBACK;
    END;

    commit;

exception when others then
   n_pkg_vitalpos_log_general.write(2, 'Modulo: ' || v_modulo || '  Error: ' || Sqlerrm);
   ROLLBACK;
   raise;
end Trae_pedidos;


procedure Trae_Prepedidos is

 v_modulo          varchar2(100) := 'PKG_TRANSFERIR_PEDIDOS.Trae_Prepedidos';
-- v_ok      integer;
 --v_error   varchar2(300);

   Cursor c_prepedidos is
    select p.*
       From tblcc_prepedido@CC.VITAL.COM.AR p
       where p.idpersonaautoriza   is null
       and p.vltipodocumento = 'pendiente'
       and not exists (select 1 from tblcc_prepedido ppac where ppac.idprepedido = p.idprepedido);

begin
  --Traigo los pedidos de CC y cargo las tablas locales.
    FOR i in c_prepedidos
    LOOP

      BEGIN
          --Insert documentos
          INSERT INTO tblcc_prepedido
          SELECT * FROM tblcc_prepedido@CC.VITAL.COM.AR WHERE idprepedido = i.idprepedido;
          --Insert detallepedidos
          INSERT INTO tblcc_prepedidodetalle
          SELECT * FROM tblcc_prepedidodetalle@CC.VITAL.COM.AR WHERE idprepedido = i.idprepedido;
      EXCEPTION
        WHEN OTHERS THEN
          n_pkg_vitalpos_log_general.write(2, 'Modulo: '||v_modulo||'  Error al traer info de CC: ' || SQLERRM);
          ROLLBACK;
      END;

      BEGIN
       update tblcc_prepedido@CC.VITAL.COM.AR
          set VLTIPODOCUMENTO = 'enviadoAC'
       WHERE idprepedido = i.idprepedido;
      EXCEPTION
      WHEN OTHERS THEN
        n_pkg_vitalpos_log_general.write(2, 'Modulo: '||v_modulo||'  Error al actualizar pedidos de -1: ' || SQLERRM);
       ROLLBACK;
      END;

    END LOOP;

    commit;

exception when others then
   n_pkg_vitalpos_log_general.write(2, 'Modulo: ' || v_modulo || '  Error: ' || Sqlerrm);
   ROLLBACK;
   raise;
end Trae_Prepedidos;
/*********************************************************************************************************************
* %v 21/10/2020 ChM - Traer pedidos de E-commerce 
                      permite extraer pedidos desde ecommerce BWV (PENDIENTE DESARROLLO REUNION CON IVAN Y VTEX) a AC
**********************************************************************************************************************/

procedure Trae_pedidos_ecommerce is

   v_modulo          varchar2(100) := 'PKG_TRANSFERIR_PEDIDOS.Trae_pedidos_ecommerce';
 --  v_idPedido        detallepedidos.idpedido%type;
 --  v_sqDetallePedido detallepedidos.sqdetallepedido%type;

  -- TYPE T_PEDIDOS IS TABLE OF PEDIDOS%ROWTYPE INDEX BY BINARY_INTEGER;
  -- V_PEDIDOS T_PEDIDOS;

 v_ok      integer;
 v_error   varchar2(300);

   Cursor c_pedidos is
    select p.IDPEDIDO IDPEDIDO,p.IDDOCTRX IDDOCTRX, nvl(pa.limite,0) limite
       From pedidos@CC.VITAL.COM.AR p
       left join tx_pedidos_particionar@CC.VITAL.COM.AR pa on (p.idpedido = pa.idpedido)
      where p.icestadosistema = -1;

begin
  --Traigo los pedidos de CC y cargo las tablas locales.
    FOR i in c_pedidos
    LOOP

      BEGIN
          --Insert documentos
          INSERT INTO DOCUMENTOS
          SELECT * FROM DOCUMENTOS@CC.VITAL.COM.AR WHERE IDDOCTRX = i.IDDOCTRX;
          --Insert pedidos
          INSERT INTO PEDIDOS
          SELECT * FROM PEDIDOS@CC.VITAL.COM.AR WHERE IDPEDIDO = i.IDPEDIDO;
          --Insert detallepedidos
          INSERT INTO DETALLEPEDIDOS
          SELECT * FROM DETALLEPEDIDOS@CC.VITAL.COM.AR WHERE IDPEDIDO = i.IDPEDIDO;
          --Insert observacionespedido
          INSERT INTO OBSERVACIONESPEDIDO
          SELECT * FROM OBSERVACIONESPEDIDO@CC.VITAL.COM.AR WHERE IDPEDIDO = i.IDPEDIDO;
          --Insert tx_pedidos_insert
          INSERT INTO TX_PEDIDOS_INSERT
          SELECT * FROM TX_PEDIDOS_INSERT@CC.VITAL.COM.AR WHERE IDPEDIDO = i.IDPEDIDO;
          --Insert tx_pedidos_particionar
          INSERT INTO TX_PEDIDOS_PARTICIONAR
          SELECT * FROM TX_PEDIDOS_PARTICIONAR@CC.VITAL.COM.AR WHERE IDPEDIDO = i.IDPEDIDO;
      EXCEPTION
        WHEN OTHERS THEN
          n_pkg_vitalpos_log_general.write(2, 'Modulo: '||v_modulo||'  Error al traer info de CC: ' || SQLERRM);
          ROLLBACK;
      END;

      --Particiono el pedido en caso de ser necesario
      If i.limite != 0 then
            BEGIN
              pkg_dividir_pedido.dividir(i.IDPEDIDO, i.LIMITE,v_ok, v_error);

			  --MPASSIOTTI - 01/06/2017 - Migracion CC - Si se particiona, se pasa el pedido padre a 0. Dividirpedido lo elimina de tx_pedidos_insert
              update pedidos set icestadosistema = 0  where idpedido = i.IDPEDIDO;

              delete TX_PEDIDOS_PARTICIONAR WHERE IDPEDIDO = i.IDPEDIDO;
              delete TX_PEDIDOS_PARTICIONAR@CC.VITAL.COM.AR WHERE IDPEDIDO = i.IDPEDIDO;
            EXCEPTION
            WHEN OTHERS THEN
              n_pkg_vitalpos_log_general.write(2, 'Modulo: '||v_modulo||'  Error al dividir pedido: ' || SQLERRM);
              ROLLBACK;
            END;
      END IF;

      --actualizo remoto para que no vuelva a traer los registros
      update pedidos@CC.VITAL.COM.AR set icestadosistema = 0 where IDPEDIDO = i.IDPEDIDO;
      delete TX_PEDIDOS_INSERT@CC.VITAL.COM.AR where IDPEDIDO = i.IDPEDIDO;


    END LOOP;

--una vez que tengo todas las tablas locales cargadas y actualizadas en base CC, modifico valor local para enviar a tiendas.
    BEGIN
       update pedidos
          set icestadosistema = 0
        where idpedido in (select idpedido from TX_PEDIDOS_INSERT)
          and icestadosistema = -1;
    EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2, 'Modulo: '||v_modulo||'  Error al actualizar pedidos de -1: ' || SQLERRM);
      ROLLBACK;
    END;

    commit;

exception when others then
   n_pkg_vitalpos_log_general.write(2, 'Modulo: ' || v_modulo || '  Error: ' || Sqlerrm);
   ROLLBACK;
   raise;
end Trae_pedidos_ecommerce;

END;
/