CREATE OR REPLACE PACKAGE PKG_CLIENTE_CENTRAL IS

   /**************************************************************************************************
   * Antigua librería que da servicios de clientes del PKG_CLIENTE que usa la Caja Unificada
   * En el futuro el PKG_CLIENTE va a pasar a fuera de uso y solo se va utilizar este
   *************************************************************************************************/
   c_SITIVA_CF CONSTANT SITUACIONESIVA.CDSITUACIONIVA%TYPE := '48';

   FUNCTION GetIdEntidad(p_cdcuit ENTIDADES.CDCUIT%TYPE) RETURN ENTIDADES.IDENTIDAD%TYPE;

   PROCEDURE GetDireccion(p_idEntidad IN ENTIDADES.IDENTIDAD%TYPE,
                          o_cdtipdir  OUT DIRECCIONESENTIDADES.CDTIPODIRECCION%TYPE,
                          o_sqdir     OUT DIRECCIONESENTIDADES.SQDIRECCION%TYPE);

   PROCEDURE GetDataEntidad(p_idEntidad IN ENTIDADES.IDENTIDAD%TYPE,
                            o_cdsitiva  OUT SITUACIONESIVA.CDSITUACIONIVA%TYPE,
                            o_cdtipdir  OUT DIRECCIONESENTIDADES.CDTIPODIRECCION%TYPE,
                            o_sqdir     OUT DIRECCIONESENTIDADES.SQDIRECCION%TYPE);

   FUNCTION GetCuitCF(p_ref VARCHAR2, p_chr1 VARCHAR2, p_chr2 VARCHAR2) RETURN ENTIDADES.CDCUIT%TYPE;

   FUNCTION GetLegajo(p_ref VARCHAR2) RETURN VARCHAR2;

   FUNCTION GetHabilitBebidaAlcoholica(p_idEntidad IN entidades.identidad%TYPE) RETURN INTEGER;

   FUNCTION EsConsumidorFinal(p_ident ENTIDADES.IDENTIDAD%TYPE) RETURN INTEGER;

  Function EsCliente(p_ident ENTIDADES.IDENTIDAD%Type) Return Integer ;

   FUNCTION GetEntidadAlter(p_idEntidad    ENTIDADES.IDENTIDAD%TYPE,
                            p_dsReferencia PEDIDOS.DSREFERENCIA%TYPE) RETURN ENTIDADES.CDCUIT%TYPE;

   FUNCTION DireccionOK(p_idEntidad ENTIDADES.IDENTIDAD%TYPE) RETURN NUMBER;

   --   Procedure GetEntidadRef(p_ref     In tblcu_cabecera.dsreferencia%Type,
   --                           p_entidad Out entidades.identidad%Type);

   PROCEDURE GetClienteExclud(p_idEntidad IN ENTIDADES.IDENTIDAD%TYPE, p_excluido OUT NUMBER);

   /**************************************************************************************************
   * Fin de Antigua librería que da servicios de clientes del PKG_CLIENTE que usa la Caja Unificada
   *************************************************************************************************/
   /**************************************************************************************************
   * Nueva Librería que da servicios de clientes
   *************************************************************************************************/
   /*Juan Bodnar
   26/03/2014
   Inicio de Grupo de servicios agregado para ser utilizado por el nuevo sisteama de Creditos
   */
   TYPE cursor_type IS REF CURSOR;
   Procedure ActualizarContacto(p_SqContactoEntidad In contactosentidades.sqcontactoentidad%Type,
                               p_Identidad         In entidades.identidad%Type,
                               p_CdFormadeContacto In contactosentidades.cdformadecontacto%Type,
                               p_IdPersonaModif    In entidades.idpersonamodif%Type,
                               p_DsFormadeContacto In contactosentidades.dscontactoentidad%Type,
                               p_ok                Out Integer,
                               p_error             Out Varchar2,
                               p_modificado        Out Integer);

   PROCEDURE ActualizarDatosCliente(p_IdEntidad         IN entidades.identidad%TYPE,
                                    --p_cdforma           IN entidades.cdforma%TYPE,
                                    p_cdtraba           IN entidades.cdtraba%TYPE,
                                    p_vldiasdeuda       IN entidades.vldiasdeuda%TYPE,
                                    p_vlrecargo         IN entidades.vlrecargo%TYPE,
                                    p_cdestadooperativo IN entidades.cdestadooperativo%TYPE,
												            p_IdPersonaModif IN entidades.idpersonamodif%TYPE,
                                    p_observaciones     IN observacionesentidades.dsobservacion%TYPE,
                                    p_ok                OUT INTEGER,
                                    p_error             OUT VARCHAR2);

   PROCEDURE ValidaSintaxisCuit(p_CdCuit           IN entidades.cdcuit%TYPE,
                                p_CdCuitFormateado OUT entidades.cdcuit%TYPE,
                                p_ok               OUT INTEGER,
                                p_error            OUT VARCHAR2);

   FUNCTION ExisteEntidad(p_cdcuit ENTIDADES.CDCUIT%TYPE, p_Identidad entidades.identidad%TYPE)
      RETURN INTEGER;

   PROCEDURE GetEstadoCliente(p_CdCuit IN entidades.cdcuit%TYPE,
                              p_ok     OUT INTEGER,
                              p_error  OUT VARCHAR2);
   PROCEDURE GetOperacionCliente(cur_out OUT cursor_type);

   PROCEDURE GetDatosCliente(p_Identidad IN entidades.identidad%TYPE, cur_out OUT cursor_type);

   PROCEDURE GetDatosImpositivos(p_Identidad IN entidades.identidad%TYPE,
                                 cur_out OUT cursor_type);

   PROCEDURE GetReduccionIB(p_identidad  IN entidades.identidad%TYPE,
                            p_cur_out    OUT cursor_type);

   PROCEDURE GetExcencionesImpositivas(p_identidad IN entidades.identidad%TYPE,
                                       p_cur_out   OUT cursor_type);

   PROCEDURE GrabarRolesCliente(p_IdEntidad rolesentidades.identidad%TYPE,
                                p_CdRol     roles.cdrol%TYPE,
                                p_IdPersona rolesentidades.idpersonaresponsable%TYPE,
                                p_ok        OUT INTEGER,
                                p_error     OUT VARCHAR2);

   PROCEDURE BorrarRolesCliente(p_IdEntidad rolesentidades.identidad%TYPE,
                                p_CdRol     roles.cdrol%TYPE,
                                p_ok        OUT INTEGER,
                                p_error     OUT VARCHAR2);

   --Gets Generales para Alta de Clientes
   PROCEDURE GetSucursales(cur_out OUT cursor_type);

   PROCEDURE GetFidelizacionCliente(cur_out OUT cursor_type, pCodBar IN TjClientesCf.VlCodBar%TYPE);

   PROCEDURE GetCanales(cur_out OUT cursor_type);

   PROCEDURE GetRubros(cur_out OUT cursor_type);

   PROCEDURE GetTipoDirec(cur_out OUT cursor_type);

   PROCEDURE GetPaises(cur_out OUT cursor_type);

   PROCEDURE GetProvincias(p_Pais IN paises.cdpais%TYPE, cur_out OUT cursor_type);

   PROCEDURE GetSituacionIva(cur_out OUT cursor_type);

   PROCEDURE GetLocalidades(p_Localidad IN localidades.dslocalidad%TYPE,
                            p_Provincia IN provincias.cdprovincia%TYPE,
                            p_Pais      IN paises.cdpais%TYPE,
                            cur_out     OUT cursor_type);

   PROCEDURE GetCdPostal(p_CdLocalidad IN localidades.cdlocalidad%TYPE,
                         p_CdProvincia IN provincias.cdprovincia%TYPE,
                         cur_out       OUT cursor_type);

   PROCEDURE GetContactosCliente(p_Identidad IN entidades.identidad%TYPE, cur_out OUT cursor_type);

   PROCEDURE GetDomiciliosCliente(p_Identidad IN entidades.identidad%TYPE, /*p_DomicilioCuenta in integer,*/
                                  cur_out     OUT cursor_type);

   PROCEDURE GetRebaTMK(cur_out OUT cursor_type, pIdEntidad IN Entidades.IDENTIDAD%TYPE);

   PROCEDURE GetDatosComerciales(cur_out OUT cursor_type, pIdEntidad IN ENTIDADES.IDENTIDAD%TYPE);

   PROCEDURE GetFormasContacto(cur_out OUT cursor_type);

   PROCEDURE GetEstadosOperativos(cur_out OUT cursor_type);

   FUNCTION HabilitacionOK(p_IdEntidad entidades.identidad%TYPE,
                           p_Cliente   OUT VARCHAR2,
                           p_Cd13178   entidades.cd13178%TYPE) RETURN NUMBER;

   PROCEDURE GetClientesPorCuit(cur_out OUT cursor_type,
                                p_Cuit  IN entidades.cdcuit%TYPE,
                                p_Rol   IN rolesentidades.cdrol%TYPE);

   PROCEDURE GetEmpleadoPorLegajo(cur_out OUT cursor_type, pCdLegajo IN Personas.CdLegajo%TYPE);

   PROCEDURE GetClientesPorRazonSocial(p_RazonSocial IN entidades.dsrazonsocial%TYPE,
                                       p_Rol         IN rolesentidades.cdrol%TYPE,
													cur_out       OUT cursor_type);

   PROCEDURE GetClienteCuenta(cur_out OUT cursor_type, p_IdCuenta IN tblcuenta.idcuenta%TYPE);

   PROCEDURE GetRolesCliente(p_Identidad IN entidades.identidad%TYPE, cur_out OUT cursor_type);

   PROCEDURE GetRoles(cur_out OUT cursor_type);

   PROCEDURE ExcluidoFidelizadoRecargo(cur_out    OUT cursor_type,
                                       pIdEntidad IN Entidades.IdEntidad%TYPE);

   FUNCTION GetDescLocalidad(p_cdlocalidad localidades.cdlocalidad%TYPE) RETURN VARCHAR2;

   FUNCTION GetDescProvincia(p_cdprovincia provincias.cdprovincia%TYPE) RETURN VARCHAR2;

	PROCEDURE GetFormaCliente(p_iDentidad IN entidades.identidad%TYPE,
		                       p_cur_out OUT cursor_type);

   PROCEDURE GetClientesPorDireccion(p_pais direccionesentidades.cdpais%type,
                                     p_provincia direccionesentidades.cdprovincia%type,
                                     p_localidad direccionesentidades.cdlocalidad%type,
                                     p_strcalle direccionesentidades.dscalle%type,
                                     p_altura   integer,
													           cur_out       OUT cursor_type);

  Procedure GetClienteMercadoPago(p_Identidad   In entidades.identidad%Type,
                                  p_InicioDesde IN DATE,
                                  p_InicioHasta IN DATE,
                                  p_icenviado   In integer default 0,
                                  cur_out       Out cursor_type);

  Procedure SetEvioMercadoPago( p_Identidad              IN entidades.identidad%Type,
                                                  p_idPersonaEnvio       IN personas.idpersona%TYPE,
                                                  p_ok                     OUT INTEGER,
                                                  p_error               OUT VARCHAR2 );

END PKG_CLIENTE_CENTRAL;
/
CREATE OR REPLACE PACKAGE BODY PKG_CLIENTE_CENTRAL IS

   --Declaracion de constantes
   c_DirComercial CONSTANT direccionesentidades.cdtipodireccion%TYPE := '2';
   c_DirParticular CONSTANT direccionesentidades.cdtipodireccion%TYPE := '4';
   c_IdCodigoOperacion CONSTANT OperacionesComprobantes.CdComprobante%TYPE := '30';
   c_IdEntidadOperativa CONSTANT Entidades.CdEstadoOperativo%TYPE := 'A';
   c_responsableinscripto CONSTANT SITUACIONESIVA.CDSITUACIONIVA%TYPE := '1';
   c_IdPersonaActiva CONSTANT Personas.IcActivo%TYPE := 1;
   c_dtOperativa DATE := N_PKG_VITALPOS_CORE.GetDT();
   
/**************************************************************************************************
  * %v 29/03/2017 - IAquilano
  * Funcion que quita caracteres no imprimibles de una cadena de texto
  * Solo para 11g
  * %V 20/07/2021 ChM - se trae procedimiento desde PKG_CLIENTE sucursal para la
                        habilitación de TiendaOnline desde ACWEB
  ***************************************************************************************************/
  FUNCTION LimpiarContacto(p_contacto IN contactosentidades.dscontactoentidad%type)
    RETURN VARCHAR2 IS

    v_contacto contactosentidades.dscontactoentidad%type := p_contacto;
    --- Si estoy en 11g descomento el select
    -- Si estoy en 9i comento el select pero queda asignado para devolver lo mismo que entró, así no hay que tocar en otras partes del pkg

  BEGIN

    select regexp_replace(p_contacto, '[^[:print:]]', '') --saco caracteres no imprimibles
    into v_contacto
    from dual;

    return v_contacto; --devuelvo string sin caracteres no imprimibles

  EXCEPTION
    WHEN OTHERS THEN
      RETURN 0;

  END LimpiarContacto;

  /****************************************************************************************
  * 11/04/2014
  * JBodnar
  * Actualiza el contacto de un cliente
  * %v 05/08/2016 RCigana, se deshabilita modificación de cdformadecontacto y se
  *               incluye cdformadecontacto en where de update
  * %v 31/03/2017 IAquilano - Agrego comparacion de datos para ver si modifica o no
  * %v 29/03/2017 IAquilano - Agrego chequeo de caracteres no imprimibles
  * %V 20/07/2021 ChM - se trae procedimiento desde PKG_CLIENTE sucursal para la
                        habilitación de TiendaOnline desde ACWEB
  *****************************************************************************************/
  Procedure ActualizarContacto(p_SqContactoEntidad In contactosentidades.sqcontactoentidad%Type,
                               p_Identidad         In entidades.identidad%Type,
                               p_CdFormadeContacto In contactosentidades.cdformadecontacto%Type,
                               p_IdPersonaModif    In entidades.idpersonamodif%Type,
                               p_DsFormadeContacto In contactosentidades.dscontactoentidad%Type,
                               p_ok                Out Integer,
                               p_error             Out Varchar2,
                               p_modificado        Out Integer) As
    v_Modulo            Varchar2(100) := 'PKG_CLIENTE_CENTRAL.ActualizarContacto';
    v_valorcontacto     contactosentidades.dscontactoentidad%TYPE;
    v_dsformadecontacto contactosentidades.dscontactoentidad%TYPE;

  Begin
    v_dsformadecontacto := LimpiarContacto(p_DsFormadeContacto);

    Select ce.dscontactoentidad --Inicia la comparacion si esta o no modificando
      into v_valorcontacto
      from contactosentidades ce
     where ce.identidad = p_identidad
       and ce.cdformadecontacto = p_CdFormadeContacto
       and ce.sqcontactoentidad = p_SqContactoEntidad;

    --If trim(v_valorcontacto) <> trim(p_DsFormadeContacto) Then
    If trim(v_valorcontacto) <> trim(v_DsFormadeContacto) Then
      -- 11g
      p_modificado := 1; -- Si el valor nuevo es diferente del que estaba, asigna 1, sino 0
    else
      p_modificado := 0; -- Asigno al parametro de salida si modifico o no
    end if;

    --Actualiza el contacto de un cliente
    Update contactosentidades
       Set idpersona         = p_IdPersonaModif,
           dscontactoentidad = v_DsFormadeContacto
     Where identidad = p_Identidad
       And cdformadecontacto = p_CdFormadeContacto
       And sqcontactoentidad = p_SqContactoEntidad;

    --Alta OK
    Commit;
    p_ok    := 1;
    p_error := '';
  Exception
    When Others Then
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_Modulo ||
                                       '  Error: ' || Sqlerrm);
      p_ok    := 0;
      p_error := '  Error: ' || Sqlerrm;
      Raise;
  End ActualizarContacto;
  /****************************************************************************************
  * Procedimiento para actualizar los datos del cliente en la tabla entidad
	* %v 26/06/2014 MatiasG: v1.0
  * %v 22/09/2015 - APW - Audito cambios de forma
  * %v 19/02/2016 - LucianoF - Guarda observacion
  * %v 11/05/2018 - IAquilano - Cambio auditoria de Forma por auditoria de recargo.
  *****************************************************************************************/
   PROCEDURE ActualizarDatosCliente(p_IdEntidad         IN entidades.identidad%TYPE,
                                    --p_cdforma           IN entidades.cdforma%TYPE,
                                    p_cdtraba           IN entidades.cdtraba%TYPE,
                                    p_vldiasdeuda       IN entidades.vldiasdeuda%TYPE,
                                    p_vlrecargo         IN entidades.vlrecargo%TYPE,
                                    p_cdestadooperativo IN entidades.cdestadooperativo%TYPE,
												            p_IdPersonaModif IN entidades.idpersonamodif%TYPE,
                                    p_observaciones     IN observacionesentidades.dsobservacion%TYPE,
                                    p_ok                OUT INTEGER,
                                    p_error             OUT VARCHAR2) AS

      v_Modulo VARCHAR2(100) := 'PKG_CLIENTE_CENTRAL.ActualizarDatosCliente';
      v_vlrecargo_ant            entidades.vlrecargo%type;
      v_existe INTEGER;
   BEGIN
      -- Audita solo si cambio recargo
      select nvl(e.vlrecargo,0)
      into v_vlrecargo_ant
      from entidades e
      where e.identidad = p_IdEntidad;

      if v_vlrecargo_ant <> nvl(p_vlrecargo, '0') then
        insert into tblauditoria (idauditoria,cdsucursal,idpersona,vlpuesto,idtabla,nmtabla, dtaccion, nmproceso)
        values (sys_guid(), 'AC', p_IdPersonaModif, null, p_IdEntidad, 'ENTIDADES', sysdate(), v_Modulo||' cambia recargo de '||v_vlrecargo_ant||'  a  '|| nvl(p_vlrecargo,0));
      end if;

      --Actualizo los datos en la tabla entidades y guardo la persona y la fecha de modificacion
      UPDATE entidades ee
         SET --ee.cdforma           = p_cdforma,
             ee.cdtraba           = p_cdtraba,
             ee.vldiasdeuda       = p_vldiasdeuda,
             ee.vlrecargo         = p_vlrecargo,
             ee.cdestadooperativo = p_cdestadooperativo,
             ee.idpersonamodif    = p_IdPersonaModif,
             ee.dtmodif           = c_dtOperativa
       WHERE identidad = p_Identidad;
      --Confirmo y retorno Ok

      --Busco si tiene obs, inserta o actualiza
       select count(*) into v_existe
       from observacionesentidades
       where identidad = p_IdEntidad;

       if v_existe > 0 then
         UPDATE observacionesentidades oe
            SET oe.dsobservacion = p_observaciones,
                oe.dtregistro    = sysdate,
                oe.idpersona     = p_IdPersonaModif
          WHERE oe.identidad     = p_IdEntidad;
       else
         INSERT INTO observacionesentidades (identidad,dsobservacion,dtregistro,idpersona)
                VALUES (p_idEntidad,p_observaciones,sysdate,p_IdPersonaModif);
       end if;

      COMMIT;
      p_ok    := 1;
      p_error := '';

   EXCEPTION
      WHEN OTHERS THEN
         n_pkg_vitalpos_log_general.write(2, 'Modulo: ' || v_Modulo || '  Error: ' || SQLERRM);
         p_ok    := 0;
         p_error := '  Error: ' || SQLERRM;
         RAISE;
   END ActualizarDatosCliente;
   /****************************************************************************************
   * 27/09/2013 - MarianoL
   * GetIdentidad()
   * Obtiene el id de la entidad en base al cuit, retorna Nulo si no lo encuentra
   * El caso se puede dar si el cuit referenciado en un pedido no ha sido dado de alta como entidad.
   *****************************************************************************************/
   FUNCTION GetIdEntidad(p_cdcuit ENTIDADES.CDCUIT%TYPE) RETURN ENTIDADES.IDENTIDAD%TYPE IS
      v_idEnti ENTIDADES.IDENTIDAD%TYPE;
   BEGIN
      SELECT identidad
        INTO v_idEnti
        FROM entidades e
       WHERE e.cdcuit = p_cdcuit;
      RETURN v_idEnti;
   EXCEPTION
      WHEN OTHERS THEN
         RETURN NULL;
   END GetIdEntidad;

   /****************************************************************************************
   * 27/09/2013 - MarianoL
   * GetDireccion
   * Obtiene datos de direccion de la entidad, si no encuentra una direccion comercial opta por una particular.
   *****************************************************************************************/
   PROCEDURE GetDireccion(p_idEntidad IN ENTIDADES.IDENTIDAD%TYPE,
                          o_cdtipdir  OUT DIRECCIONESENTIDADES.CDTIPODIRECCION%TYPE,
                          o_sqdir     OUT DIRECCIONESENTIDADES.SQDIRECCION%TYPE) IS
      v_Modulo VARCHAR2(100) := 'PKG_CLIENTE_CENTRAL.GetDireccion';
   BEGIN
      BEGIN
         SELECT CDTIPODIRECCION, SQDIRECCION
           INTO o_cdtipdir, o_sqdir
           FROM direccionesentidades de
          WHERE de.identidad = p_idEntidad
            AND de.cdtipodireccion = c_dircomercial --Dirección Comercial
            AND de.sqdireccion =
                (SELECT MAX(ddee.sqdireccion)
                   FROM direccionesentidades ddee
                  WHERE ddee.identidad = de.identidad
                    AND ddee.cdtipodireccion = de.cdtipodireccion);
      EXCEPTION
         WHEN OTHERS THEN
            o_cdtipdir := NULL;
      END;
      IF TRIM(o_cdtipdir) IS NULL THEN
         SELECT CDTIPODIRECCION, SQDIRECCION
           INTO o_cdtipdir, o_sqdir
           FROM direccionesentidades de
          WHERE de.identidad = p_idEntidad
            AND de.cdtipodireccion = c_dirparticular --Dirección Particular
            AND de.sqdireccion =
                (SELECT MAX(ddee.sqdireccion)
                   FROM direccionesentidades ddee
                  WHERE ddee.identidad = de.identidad
                    AND ddee.cdtipodireccion = de.cdtipodireccion);
      END IF;
      RETURN;
   EXCEPTION
      WHEN OTHERS THEN
         n_pkg_vitalpos_log_general.write(2, 'Modulo: ' || v_Modulo || '  Error: ' || SQLERRM);
         o_cdtipdir := NULL;
         o_sqdir    := 0;
   END GetDireccion;

   /****************************************************************************************
   * 13/03/2014 - MarianoL
   * DireccionOK()
   * Verifica si la dirección del clientes está OK para facturar
   * Devuelve 1=OK ó 0=Error
   *****************************************************************************************/
   FUNCTION DireccionOK(p_idEntidad ENTIDADES.IDENTIDAD%TYPE) RETURN NUMBER IS
      v_Modulo      VARCHAR2(100) := 'PKG_CLIENTE_CENTRAL.DireccionOK';
      v_cdtipdir    direccionesentidades.cdtipodireccion%TYPE;
      v_sqdir       direccionesentidades.sqdireccion%TYPE;
      v_cdcodpostal direccionesentidades.cdcodigopostal%TYPE;
   BEGIN
      GetDireccion(p_idEntidad, v_cdtipdir, v_sqdir);
      IF v_cdtipdir IS NOT NULL AND v_sqdir IS NOT NULL THEN
         SELECT de.cdcodigopostal
           INTO v_cdcodpostal
           FROM direccionesentidades de
          WHERE de.identidad = p_idEntidad
            AND de.cdtipodireccion = v_cdtipdir
            AND de.sqdireccion = v_sqdir;
      END IF;
      IF v_cdtipdir IS NOT NULL AND v_sqdir IS NOT NULL AND v_cdcodpostal IS NOT NULL THEN
         RETURN 1;
      ELSE
         RETURN 0;
      END IF;
   EXCEPTION
      WHEN OTHERS THEN
         n_pkg_vitalpos_log_general.write(2, 'Modulo: ' || v_Modulo || '  Error: ' || SQLERRM);
         RAISE;
   END DireccionOK;

   /****************************************************************************************
   * 27/09/2013 - MarianoL
   * GetDATAiDENTIDAD
   * Obtiene los datos básicos del cliente
   *****************************************************************************************/
   PROCEDURE GetDataEntidad(p_idEntidad IN ENTIDADES.IDENTIDAD%TYPE,
                            o_cdsitiva  OUT SITUACIONESIVA.CDSITUACIONIVA%TYPE,
                            o_cdtipdir  OUT DIRECCIONESENTIDADES.CDTIPODIRECCION%TYPE,
                            o_sqdir     OUT DIRECCIONESENTIDADES.SQDIRECCION%TYPE) IS
      v_Modulo          VARCHAR2(100) := 'PKG_CLIENTE.GetDataEntidad';
      v_NumeraImpFiscal VARCHAR2(5) := nvl(GetVlParametro('MdlFiscal', 'General'), 0);
   BEGIN
      SELECT nvl(cdsituacioniva, c_responsableinscripto)
        INTO o_cdsitiva
        FROM INFOIMPUESTOSENTIDADES
       WHERE identidad = p_idEntidad;
      IF v_NumeraImpFiscal = '1' AND TRIM(p_idEntidad) = GetVlparametro('CdConsFinal', 'General') THEN
         o_cdsitiva := c_SITIVA_CF;
      END IF;
      GetDireccion(p_idEntidad, o_cdtipdir, o_sqdir);
      RETURN;
   EXCEPTION
      WHEN OTHERS THEN
         n_pkg_vitalpos_log_general.write(2, 'Modulo: ' || v_Modulo || '  Error: ' || SQLERRM);
         RAISE;
   END GetDataEntidad;

   /****************************************************************************************
   * 27/09/2013 - MarianoL
   * Getcuicf
   * Obtiene el cuit de la referencia de un CF fidelizado
   *****************************************************************************************/
   FUNCTION GetCuitCF(p_ref VARCHAR2, p_chr1 VARCHAR2, p_chr2 VARCHAR2) RETURN ENTIDADES.CDCUIT%TYPE IS
      XCUIT    ENTIDADES.CDCUIT%TYPE;
      pos1     INTEGER;
      pos2     INTEGER;
      v_Modulo VARCHAR2(100) := 'PKG_CLIENTE_CENTRAL.GetCuitCF';
   BEGIN
      pos1  := instr(p_ref, TRIM(p_chr1));
      pos2  := instr(p_ref, TRIM(p_chr2));
      XCUIT := NULL;
      IF pos1 > 0 AND pos2 > 0 AND pos1 < pos2 THEN
         XCUIT := substr(p_ref, pos1 + 1, pos2 - pos1 - 1);
      END IF;
      RETURN XCUIT;
   EXCEPTION
      WHEN OTHERS THEN
         n_pkg_vitalpos_log_general.write(2, 'Modulo: ' || v_Modulo || '  Error: ' || SQLERRM);
         RAISE;
   END GetCuitCF;

   /****************************************************************************************
   * 27/09/2013 - MarianoL
   * GetLegajo
   * Dada un DSREFERENCIA obtiene el legajo del empleado
   *****************************************************************************************/
   FUNCTION GetLegajo(p_ref VARCHAR2) RETURN VARCHAR2 IS
      v_Legajo personas.cdlegajo%TYPE;
      v_Existe INTEGER;
      v_pos1   INTEGER;
      v_pos2   INTEGER;
      v_Modulo VARCHAR2(100) := 'PKG_CLIENTE_CENTRAL.GetLegajo';
   BEGIN
      v_pos1 := instr(p_ref, TRIM('['));
      v_pos2 := instr(p_ref, TRIM(']'));
      IF v_pos1 > 0 AND v_pos2 > 0 AND v_pos1 < v_pos2 THEN
         v_Legajo := substr(p_ref, v_pos1 + 1, v_pos2 - v_pos1 - 1);
      END IF;
      SELECT COUNT(*)
        INTO v_Existe
        FROM personas p
       WHERE TRIM(p.cdlegajo) = TRIM(v_Legajo);
      IF v_Existe = 0 THEN
         v_Legajo := NULL;
      END IF;
      RETURN v_Legajo;
   EXCEPTION
      WHEN OTHERS THEN
         n_pkg_vitalpos_log_general.write(2, 'Modulo: ' || v_Modulo || '  Error: ' || SQLERRM);
         RAISE;
   END GetLegajo;

   /****************************************************************************************
   * 27/09/2013 - MarianoL
   * EsconsumidorFinal
   * Determina si la entidad es consumidor final
   /****************************************************************************************/
   FUNCTION EsConsumidorFinal(p_ident ENTIDADES.IDENTIDAD%TYPE) RETURN INTEGER IS
      v_Result INTEGER;
   BEGIN
      BEGIN
         --Si la situacion iva es consumidor final retorna 1
         SELECT 1
           INTO v_Result
           FROM infoimpuestosentidades i
          WHERE i.identidad = p_ident
            AND  i.cdsituacioniva = '48      ';
      EXCEPTION
         WHEN no_data_found THEN
            IF TRIM(p_ident) = TRIM(Getvlparametro('IdCfReparto', 'General')) OR
               TRIM(p_ident) = TRIM(GetVlparametro('CdConsFinal', 'General')) THEN
               v_Result := 1;
            ELSE
               v_Result := 0;
            END IF;
      END;
      RETURN v_Result;
   EXCEPTION
      WHEN OTHERS THEN
         RETURN 0;
   END EsConsumidorFinal;

  /****************************************************************************************
  * Recibe una entidad y evalua si es un cliente diferencte a CF
  * %v 19/02/2015 - JBodnar
  /****************************************************************************************/
  Function EsCliente(p_ident ENTIDADES.IDENTIDAD%Type) Return Integer Is
     v_Result  Integer;
  Begin
     --Si no es el CF generico retorna 1
     If Trim(p_ident) <> Trim(Getvlparametro('IdCfReparto', 'General')) And
        Trim(p_ident) <> Trim(GetVlparametro('CdConsFinal', 'General')) Then
        v_Result := 1;
     Else
        v_Result := 0;
     End If;
     Return v_Result;
  Exception
     When Others Then
        Return 0;
  End EsCliente;

   /****************************************************************************************
   * 27/09/2013 - MarianoL
   * GetEntidadAlter
   * Devuelve la entidad alternativa del pedido.
   * Si el pedido es con cuenta devuelve el idEntidad del pedido, si es CF busca el IdEntidad
   * que corresponde al CUIT que está en dsreferencia.
   *****************************************************************************************/
   FUNCTION GetEntidadAlter(p_idEntidad    ENTIDADES.IDENTIDAD%TYPE,
                            p_dsReferencia PEDIDOS.DSREFERENCIA%TYPE) RETURN ENTIDADES.CDCUIT%TYPE IS
      v_idEntidadAlter ENTIDADES.IDENTIDAD%TYPE := NULL;
      v_cdCuit         ENTIDADES.CDCUIT%TYPE;
      v_Modulo         VARCHAR2(100) := 'PKG_CLIENTE_CENTRAL.GetEntidadAlter';
   BEGIN
      --Busco el Cuit del cliente
      IF EsConsumidorFinal(p_identidad) = 1 THEN
         --Es CF, busco el cuit en la referencia entre paréntesis
         v_cdCuit := GetCuitCF(p_dsreferencia, '(', ')');
         IF v_cdCuit IS NULL THEN
            -- Si no lo encuentro lo busco en la referencia entre corchetes
            v_cdCuit := GetCuitCF(p_dsreferencia, '[', ']');
         END IF;
         --Busco la entidad alternativa (es distinta cuando el Cuit está en la referencia)
         v_idEntidadAlter := GetIdEntidad(v_cdCuit);
      ELSE
         --No es CF
         v_idEntidadAlter := p_identidad;
      END IF;
      RETURN v_idEntidadAlter;
   EXCEPTION
      WHEN OTHERS THEN
         n_pkg_vitalpos_log_general.write(2, 'Modulo: ' || v_Modulo || '  Error: ' || SQLERRM);
         RAISE;
   END GetEntidadAlter;

   /**************************************************************************************************
   * 19/12/2013
   * MarianoL
   * function GetHabilitBebidaAlcoholica
   * Dado un idEntidad devuelve 1 si está habilitada para vender bebidas alcoholicas, sino devuelve 0
   ***************************************************************************************************/
   FUNCTION GetHabilitBebidaAlcoholica(p_idEntidad IN entidades.identidad%TYPE) RETURN INTEGER IS
      v_modulo      VARCHAR2(100) := 'PKG_CLIENTE_CENTRAL.GetHabilitBebidaAlcoholica';
      v_Result      INTEGER := 0;
      v_TipoDir     DireccionesEntidades.CdTipoDireccion%TYPE := SUBSTR(N_PKG_VITALPOS_CORE.Getvlparametro('CdDirComercial',
                                                                                                           'Creditos'),
                                                                        1,
                                                                        8);
      v_cd13178     Entidades.Cd13178%TYPE;
      v_dt13178     Entidades.dt13178%TYPE;
      v_cdProvincia DireccionesEntidades.CdProvincia%TYPE;
      v_cdLocalidad DireccionesEntidades.CdLocalidad%TYPE;
   BEGIN
      SELECT d.cdprovincia, d.cdlocalidad, e.cd13178, e.dt13178
        INTO v_cdProvincia, v_cdLocalidad, v_cd13178, v_dt13178
        FROM DireccionesEntidades d, Entidades e
       WHERE d.identidad = e.identidad
         AND d.cdtipodireccion = v_TipoDir
         AND e.identidad = p_idEntidad
         AND d.sqdireccion = (SELECT MAX(sqdireccion)
                                FROM DireccionesEntidades d2
                               WHERE d2.identidad = p_idEntidad
                                 AND d2.cdtipodireccion = v_TipoDir);
      IF (v_cdProvincia <> 1 AND v_cdProvincia <> 14) OR
         (v_cdProvincia = 14 AND v_cdLocalidad <> 12331) OR
         (v_cd13178 IS NOT NULL AND v_dt13178 >= trunc(N_PKG_VITALPOS_CORE.GetDT())) THEN
         v_Result := 1;
      END IF;
      RETURN v_Result;
   EXCEPTION
      WHEN OTHERS THEN
         n_pkg_vitalpos_log_general.write(2, 'Modulo: ' || v_modulo || '  Error: ' || SQLERRM);
         RETURN v_Result;
   END GetHabilitBebidaAlcoholica;

   /****************************************************************************************
   * 26/03/2014 Paola Toledo
   * GetClienteExclud
   * Devuelve si un cliente debe ser excluido o no del recargo de IVA por CF
   * (1=excluido 0=no excluido)
   *****************************************************************************************/
   PROCEDURE GetClienteExclud(p_idEntidad IN ENTIDADES.IDENTIDAD%TYPE, p_excluido OUT NUMBER) IS
      v_Modulo VARCHAR2(100) := 'PKG_CLIENTE_CENTRAL.GetClienteExclud';
   BEGIN
      SELECT COUNT(1)
        INTO p_excluido
        FROM CLTESFIDELEXCLUD exc
       WHERE exc.identidad = p_idEntidad;
      RETURN;
   EXCEPTION
      WHEN OTHERS THEN
         n_pkg_vitalpos_log_general.write(2, 'Modulo: ' || v_Modulo || '  Error: ' || SQLERRM);
         RAISE;
   END GetClienteExclud;
   /****************************************************************************************
   * 27/03/2014 JBodnar
   * ValidaSintaxisCuit
   * Valido el formato del cuit antes de darlo de alta o actualizar los datos del cliente
   *****************************************************************************************/
   PROCEDURE ValidaSintaxisCuit(p_CdCuit           IN entidades.cdcuit%TYPE,
                                p_CdCuitFormateado OUT entidades.cdcuit%TYPE,
                                p_ok               OUT INTEGER,
                                p_error            OUT VARCHAR2) IS
      v_Modulo  VARCHAR2(100) := 'PKG_CLIENTE_CENTRAL.ValidaSintaxisCuit';
      v_cuit    entidades.cdcuit%TYPE;
      v_numeros INTEGER;
   BEGIN
      --Seteo el inicio en OK y si hay algun error lo cambio en el proceso
      p_ok    := 1;
      p_error := '';
      --Valido si no tiene guiones el cuit y se lo agrego
      IF instr(p_CdCuit, '-') = 0 THEN
         v_cuit             := substr(p_CdCuit, 0, 2) || '-' || substr(p_CdCuit, 3, 8) || '-' ||
                               substr(p_CdCuit, 11, 1);
         p_CdCuitFormateado := v_cuit;
      ELSE
         p_CdCuitFormateado := p_CdCuit;
      END IF;
      --Guardo la cantidad de numeros del cuit
      v_numeros := length(TRIM(REPLACE(v_cuit, '-', '')));
      --El cuit debe tener 11 numeros
      IF v_numeros <> 11 THEN
         p_ok               := 0;
         p_error            := 'Formato de cuit incorrecto.';
         p_CdCuitFormateado := p_CdCuit;
         RETURN;
      END IF;
   EXCEPTION
      WHEN OTHERS THEN
         n_pkg_vitalpos_log_general.write(2, 'Modulo: ' || v_Modulo || '  Error: ' || SQLERRM);
         p_ok               := 0;
         p_error            := '  Error: ' || SQLERRM;
         p_CdCuitFormateado := p_CdCuit;
         RAISE;
   END ValidaSintaxisCuit;

   /****************************************************************************************
   * 11/04/2014 - Juan Bodnar
   * ExisteEntidad
   * Valido si ya existe el cuit asigando a una entidad
   *****************************************************************************************/
   FUNCTION ExisteEntidad(p_cdcuit ENTIDADES.CDCUIT%TYPE, p_Identidad entidades.identidad%TYPE)
      RETURN INTEGER IS
      v_Existe INTEGER;
      v_Modulo VARCHAR2(100) := 'PKG_CLIENTE_CENTRAL.ExisteEntidad';
   BEGIN
      BEGIN
         SELECT 1
           INTO v_Existe
           FROM entidades e
          WHERE e.cdcuit = p_cdcuit
            AND e.identidad <> p_Identidad;
      EXCEPTION
         WHEN no_data_found THEN
            v_Existe := 0;
      END;
      RETURN v_Existe;
   EXCEPTION
      WHEN OTHERS THEN
         n_pkg_vitalpos_log_general.write(2, 'Modulo: ' || v_Modulo || '  Error: ' || SQLERRM);
   END ExisteEntidad;

   /****************************************************************************************
   * 03/04/2014 JBodnar
   * GetEstadoCliente
   * Verifica si el estado del cliente es A(Activo) esta dado de baja en el estado B
   *****************************************************************************************/
   PROCEDURE GetEstadoCliente(p_CdCuit IN entidades.cdcuit%TYPE,
                              p_ok     OUT INTEGER,
                              p_error  OUT VARCHAR2) IS
      v_Modulo VARCHAR2(100) := 'PKG_CLIENTE_CENTRAL.GetEstadoCliente';
      v_estado entidades.cdestadooperativo%TYPE;
   BEGIN
      --Consulto el estado operativo del cliente
      SELECT e.cdestadooperativo
        INTO v_estado
        FROM entidades e
       WHERE e.cdcuit = p_CdCuit;
      --Si esta dado de baja devuelvo codigo de error 0
      IF TRIM(v_estado) = 'B' THEN
         p_ok    := 0;
         p_error := 'El cliente esta dado de baja en el sistema.';
      ELSE
         p_ok    := 1;
         p_error := '';
      END IF;
   EXCEPTION
      WHEN OTHERS THEN
         n_pkg_vitalpos_log_general.write(2, 'Modulo: ' || v_Modulo || '  Error: ' || SQLERRM);
         p_ok    := 0;
         p_error := '  Error: ' || SQLERRM;
         RAISE;
   END GetEstadoCliente;

   /****************************************************************************************
   * 16/06/2014 JBodnar
   * GetOperacionCliente
   * Dado un cliente retorna los tipos de operacion para poder asignarle
   *****************************************************************************************/
   PROCEDURE GetOperacionCliente(cur_out OUT cursor_type) IS
      v_Modulo VARCHAR2(100) := 'PKG_CLIENTE_CENTRAL.GetOperacionCliente';
   BEGIN
      --Consulto el estado operativo del cliente
      OPEN cur_out FOR
         SELECT TRIM(fi.cdforma) AS cdforma, fi.dsforma
           FROM tblformaingreso fi
          WHERE fi.iccliente = 1;

   EXCEPTION
      WHEN OTHERS THEN
         n_pkg_vitalpos_log_general.write(2, 'Modulo: ' || v_Modulo || '  Error: ' || SQLERRM);
         RAISE;
   END GetOperacionCliente;

   /****************************************************************************************
   * 03/04/2014 JBodnar
   * GetDatosCliente
   * Recibe un cliente y retorna los datos en un cursor
   * %v 14/03/2019 - Elimino join con CONVENIOS porque se borra la tabla (y nunca hacía join!)
   *****************************************************************************************/
   PROCEDURE GetDatosCliente(p_Identidad IN entidades.identidad%TYPE, cur_out OUT cursor_type) AS
      v_Modulo VARCHAR2(100) := 'PKG_CLIENTE_CENTRAL.GetDatosCliente';
   BEGIN
      --Cursor de datos generales del cliente
      OPEN cur_out FOR
         SELECT TRIM(e.identidad) AS Identidad,
                TRIM(e.cdmainsucursal) AS CdSucursalPrincipal,
                s.dssucursal AS DsSucursalPrincipal,
                e.dsrazonsocial AS RazonSocial,
                e.dsnombrefantasia AS NombreFantasia,
                TRIM(e.cdcuit) AS Cuit,
                si.dssituacioniva AS SituacionIVA,
                TRIM(i.cdingresosbrutos) AS NumeroIngresosBrutos,
                r.dsrubrocomercial AS Rubro,
                i.icconvenio AS Convenio,
                TRIM(e.cd13178) AS NumeroHabilitacion,
                e.dt13178 AS FechaVencimiento,
                e.dtmodif AS FechaModificacion,
                p.dsapellido || ' ' || p.dsnombre AS PersonaModificacion,
                eo.cdestadooperativo,
                eo.dsestadooperativo,
                e.cdforma,
                fi.dsforma,
					      null cov_desc -- dejo la columna para que no de error la aplicación
           FROM entidades              e,
                infoimpuestosentidades i,
                situacionesiva         si,
                rubroscomerciales      r,
                personas               p,
                estadosoperativos      eo,
                sucursales             s,
                tblformaingreso        fi
          WHERE e.identidad = i.identidad
            AND fi.cdforma(+) = e.cdforma
            AND e.idpersonamodif = p.idpersona(+)
            AND r.cdrubrocomercial = e.cdrubroprincipal
            AND i.cdsituacioniva = si.cdsituacioniva
            AND eo.cdestadooperativo = e.cdestadooperativo
            AND s.cdsucursal = e.cdmainsucursal
            AND e.identidad = p_Identidad;
   EXCEPTION
      WHEN OTHERS THEN
         n_pkg_vitalpos_log_general.write(2, 'Modulo: ' || v_Modulo || '  Error: ' || SQLERRM);
         RAISE;
   END GetDatosCliente;

   /**************************************************************************************
   * Recibe un cliente y retorna los datos generales y los impositivos en un cursor
   * %v 30/03/2016 JBodnar
   *****************************************************************************************/
   PROCEDURE GetDatosImpositivos(p_Identidad IN entidades.identidad%TYPE,
                                 cur_out OUT cursor_type) AS
      v_Modulo VARCHAR2(100) := 'PKG_CLIENTE_CENTRAL.GetDatosImpositivos';
   BEGIN
      --Cursor de datos generales del cliente
      OPEN cur_out FOR
       SELECT TRIM(e.identidad) AS Identidad,
                    TRIM(e.cdmainsucursal) AS CdSucursalPrincipal,
                    s.dssucursal AS DsSucursalPrincipal,
                    e.dsrazonsocial AS RazonSocial,
                    e.dsnombrefantasia AS NombreFantasia,
                    TRIM(e.cdcuit) AS Cuit,
                    TRIM(i.cdingresosbrutos) AS NumeroIngresosBrutos,
                    ib.dssituacionib AS SituacionIB,
                    decode(i.icmunicipal,null,'No Aplica',0,'No Aplica',1, 'Inscripto', 2, 'No Inscripto', 3,'Extento') as SituacionMuni,
                    si.dssituacioniva AS SituacionIVA
               FROM entidades              e,
                    infoimpuestosentidades i,
                    situacionesiva         si,
                    tblimpsituacionib      ib,
                    personas               p,
                    sucursales             s
              WHERE e.identidad = i.identidad
                AND e.idpersonamodif = p.idpersona(+)
                AND i.cdsituacioniva = si.cdsituacioniva
                AND ib.cdsituacionib = i.icconvenio
                AND s.cdsucursal = e.cdmainsucursal
            AND e.identidad = p_Identidad;
   EXCEPTION
      WHEN OTHERS THEN
         n_pkg_vitalpos_log_general.write(2, 'Modulo: ' || v_Modulo || '  Error: ' || SQLERRM);
         RAISE;
   END GetDatosImpositivos;

   /****************************************************************************************
   * 24/04/2014 JBodnar
   * GrabarRolesCliente
   * Asocia un rol a una entidad insertando en la tabla rolesentidades
   *****************************************************************************************/
   PROCEDURE GrabarRolesCliente(p_IdEntidad rolesentidades.identidad%TYPE,
                                p_CdRol     roles.cdrol%TYPE,
                                p_IdPersona rolesentidades.idpersonaresponsable%TYPE,
                                p_ok        OUT INTEGER,
                                p_error     OUT VARCHAR2) AS
      v_Modulo VARCHAR2(100) := 'PKG_CLIENTE_CENTRAL.GrabarRolesCliente';
   BEGIN
      BEGIN
         --Insert de asociacion roles y entidades
         INSERT INTO rolesentidades
            (cdrol, identidad, idpersonaresponsable, dtmodificacion)
         VALUES
            (p_CdRol, p_IdEntidad, p_IdPersona, c_dtOperativa);
      EXCEPTION
         WHEN dup_val_on_index THEN
            p_ok    := 0;
            p_error := 'Error de clave duplicada. El rol ya esta asociado al cliente.';
            RETURN;
      END;
      --Insert OK
      COMMIT;
      p_ok    := 1;
      p_error := '';
   EXCEPTION
      WHEN OTHERS THEN
         n_pkg_vitalpos_log_general.write(2, 'Modulo: ' || v_Modulo || '  Error: ' || SQLERRM);
         p_ok    := 0;
         p_error := '  Error: ' || SQLERRM;
         RAISE;
   END GrabarRolesCliente;

   /****************************************************************************************
   * 24/04/2014 JBodnar
   * BorrarRolesCliente
   * Baja un rol a una entidad borrando en la tabla rolesentidades
   *****************************************************************************************/
   PROCEDURE BorrarRolesCliente(p_IdEntidad rolesentidades.identidad%TYPE,
                                p_CdRol     roles.cdrol%TYPE,
                                p_ok        OUT INTEGER,
                                p_error     OUT VARCHAR2) AS
      v_Modulo VARCHAR2(100) := 'PKG_CLIENTE_CENTRAL.BorrarRolesCliente';
   BEGIN
      --Borra un rol a una entidad
      DELETE FROM rolesentidades r
       WHERE r.identidad = p_IdEntidad
         AND r.cdrol = p_CdRol;
      --Insert OK
      COMMIT;
      p_ok    := 1;
      p_error := '';
   EXCEPTION
      WHEN OTHERS THEN
         n_pkg_vitalpos_log_general.write(2, 'Modulo: ' || v_Modulo || '  Error: ' || SQLERRM);
         p_ok    := 0;
         p_error := '  Error: ' || SQLERRM;
         RAISE;
   END BorrarRolesCliente;

   /****************************************************************************************
   * 04/04/2014 JBodnar
   * GetSucursales
   * Retorna un cursor con la descripcion de las sucursales disponibles
   *****************************************************************************************/
   PROCEDURE GetSucursales(cur_out OUT cursor_type) AS
      v_Modulo VARCHAR2(100) := 'PKG_CLIENTE_CENTRAL.GetSucursales';
   BEGIN
      --Cargo y retorno el cursor con la descripcion de las sucursales disponibles
      OPEN cur_out FOR
         SELECT s.cdsucursal , s.dssucursal, r.cdregion, r.dsregion
           FROM sucursales s , tblregion r
          WHERE s.cdregion=r.cdregion and s.servidor IS NOT NULL
          order by  s.dssucursal;
   EXCEPTION
      WHEN OTHERS THEN
         n_pkg_vitalpos_log_general.write(2, 'Modulo: ' || v_Modulo || '  Error: ' || SQLERRM);
         RAISE;
   END GetSucursales;

   /****************************************************************************************
   * 12/05/2014 JBodnar
   * GetFidelizacionCliente
   * Retorna los datos del cliente fidelizado dado un codigo de barra
   *****************************************************************************************/
   PROCEDURE GetFidelizacionCliente(cur_out OUT cursor_type, pCodBar IN TjClientesCf.VlCodBar%TYPE) AS
      v_Modulo VARCHAR2(100) := 'PKG_CLIENTE_CENTRAL.GetFidelizacionCliente';
   BEGIN
      OPEN cur_out FOR
         SELECT Ent.IdEntidad, Ent.CdCuit, Ent.DsRazonSocial
           FROM TjClientesCf Tj, entidades Ent
          WHERE Tj.VlCodBar = pCodBar
            AND Tj.IdEntidad = Ent.IdEntidad
            AND Ent.CdEstadoOperativo = c_IdEntidadOperativa;
   EXCEPTION
      WHEN OTHERS THEN
         n_pkg_vitalpos_log_general.write(2, 'Modulo: ' || v_Modulo || '  Error: ' || SQLERRM);
         RAISE;
   END GetFidelizacionCliente;

   /****************************************************************************************
   * 04/04/2014 JBodnar
   * GetCanales
   * Retorna un cursor con la descripcion de los canales
   *****************************************************************************************/
   PROCEDURE GetCanales(cur_out OUT cursor_type) AS
      v_Modulo VARCHAR2(100) := 'PKG_CLIENTE_CENTRAL.GetCanales';
   BEGIN
      --Cargo y retorno el cursor con la descripcion de los canales activos
      OPEN cur_out FOR
         SELECT TRIM(id_canal) AS id_canal, nombre
           FROM tblcanal
          WHERE activo = 1;
   EXCEPTION
      WHEN OTHERS THEN
         n_pkg_vitalpos_log_general.write(2, 'Modulo: ' || v_Modulo || '  Error: ' || SQLERRM);
         RAISE;
   END GetCanales;

   /****************************************************************************************
   * 04/04/2014 JBodnar
   * GetRubros
   * Retorna un cursor con la descripcion de los rubros comerciales
   *****************************************************************************************/
   PROCEDURE GetRubros(cur_out OUT cursor_type) AS
      v_Modulo VARCHAR2(100) := 'PKG_CLIENTE_CENTRAL.GetRubros';
   BEGIN
      --Cargo y retorno el cursor con la descripcion de los rubros comerciales
      OPEN cur_out FOR
         SELECT TRIM(cdrubrocomercial) AS cdrubrocomercial, dsrubrocomercial
           FROM rubroscomerciales;
   EXCEPTION
      WHEN OTHERS THEN
         n_pkg_vitalpos_log_general.write(2, 'Modulo: ' || v_Modulo || '  Error: ' || SQLERRM);
         RAISE;
   END GetRubros;

   /****************************************************************************************
   * 04/04/2014 JBodnar
   * GetTipoDirec
   * Retorna un cursor con la descripcion de los tipos de direcciones
   *****************************************************************************************/
   PROCEDURE GetTipoDirec(cur_out OUT cursor_type) AS
      v_Modulo VARCHAR2(100) := 'PKG_CLIENTE_CENTRAL.GetTipoDirec';
   BEGIN
      --Cargo y retorno el cursor con la descripcion de los tipos de direcciones
      OPEN cur_out FOR
         SELECT TRIM(cdtipodireccion) AS cdtipodireccion, dstipodireccion
           FROM tipodirecciones;
   EXCEPTION
      WHEN OTHERS THEN
         n_pkg_vitalpos_log_general.write(2, 'Modulo: ' || v_Modulo || '  Error: ' || SQLERRM);
         RAISE;
   END GetTipoDirec;

   /****************************************************************************************
   * 04/04/2014 JBodnar
   * GetTipoDirec
   * Retorna un cursor con la descripcion de los paises cargados
   *****************************************************************************************/
   PROCEDURE GetPaises(cur_out OUT cursor_type) AS
      v_Modulo VARCHAR2(100) := 'PKG_CLIENTE_CENTRAL.GetPaises';
   BEGIN
      --Cargo y retorno el cursor con la descripcion de los los paises cargados
      OPEN cur_out FOR
         SELECT TRIM(cdpais) AS cdpais, dspais
           FROM paises;
   EXCEPTION
      WHEN OTHERS THEN
         n_pkg_vitalpos_log_general.write(2, 'Modulo: ' || v_Modulo || '  Error: ' || SQLERRM);
         RAISE;
   END GetPaises;

   /****************************************************************************************
   * 04/04/2014 JBodnar
   * GetProvincias
   * Retorna un cursor con la descripcion de las provincias cargadas
   *****************************************************************************************/
   PROCEDURE GetProvincias(p_Pais IN paises.cdpais%TYPE, cur_out OUT cursor_type) AS
      v_Modulo VARCHAR2(100) := 'PKG_CLIENTE_CENTRAL.GetProvincias';
   BEGIN
      --Cargo y retorno el cursor con la descripcion de las provincias cargadas
      OPEN cur_out FOR
         SELECT TRIM(cdprovincia) AS cdprovincia, dsprovincia
           FROM provincias
          WHERE cdpais = p_Pais;
   EXCEPTION
      WHEN OTHERS THEN
         n_pkg_vitalpos_log_general.write(2, 'Modulo: ' || v_Modulo || '  Error: ' || SQLERRM);
         RAISE;
   END GetProvincias;

   /****************************************************************************************
   * 04/04/2014 JBodnar
   * GetSituacionIva
   * Retorna un cursor con la descripcion de las situaciones impositivas
   *****************************************************************************************/
   PROCEDURE GetSituacionIva(cur_out OUT cursor_type) AS
      v_Modulo VARCHAR2(100) := 'PKG_CLIENTE_CENTRAL.GetSituacionIva';
   BEGIN
      --Cargo y retorno el cursor con la descripcion de las situaciones impositivas
      OPEN cur_out FOR
         SELECT TRIM(cdsituacioniva) AS cdsituacioniva, dssituacioniva
           FROM situacionesiva
          WHERE icmuestra = 1;
   EXCEPTION
      WHEN OTHERS THEN
         n_pkg_vitalpos_log_general.write(2, 'Modulo: ' || v_Modulo || '  Error: ' || SQLERRM);
         RAISE;
   END GetSituacionIva;

   /****************************************************************************************
   * 04/04/2014 JBodnar
   * GetLocalidades
   * Retorna un cursor con la descripcion de las localidades recibiendo un string
   *****************************************************************************************/
   PROCEDURE GetLocalidades(p_Localidad IN localidades.dslocalidad%TYPE,
                            p_Provincia IN provincias.cdprovincia%TYPE,
                            p_Pais      IN paises.cdpais%TYPE,
                            cur_out     OUT cursor_type) AS
      v_Modulo VARCHAR2(100) := 'PKG_CLIENTE_CENTRAL.GetLocalidades';
      v_sql    VARCHAR2(200);
   BEGIN
      --Armo consulta dinamica con un like del parametro recibido
      v_sql := 'select trim(cdlocalidad) as cdlocalidad, dslocalidad from localidades where cdprovincia=' ||
               p_Provincia || ' and cdpais=';
      v_sql := v_sql || p_Pais || ' and dslocalidad like ' || chr(39) || '%' ||
               TRIM(upper(p_Localidad)) || '%' || chr(39);
      --Cargo y retorno el cursor con la descripcion de las localidades recibiendo un string
      OPEN cur_out FOR v_sql;
   EXCEPTION
      WHEN OTHERS THEN
         n_pkg_vitalpos_log_general.write(2, 'Modulo: ' || v_Modulo || '  Error: ' || SQLERRM);
         RAISE;
   END GetLocalidades;

   /****************************************************************************************
   * 04/04/2014 JBodnar
   * GetCdPostal
   * Retorna un cursor con el codigo postal dada una localidad y una provincia
   *****************************************************************************************/
   PROCEDURE GetCdPostal(p_CdLocalidad IN localidades.cdlocalidad%TYPE,
                         p_CdProvincia IN provincias.cdprovincia%TYPE,
                         cur_out       OUT cursor_type) AS
      v_Modulo VARCHAR2(100) := 'PKG_CLIENTE_CENTRAL.GetCdPostal';
   BEGIN
      --Retorna el codigo postal dada una localidad y una provincia
      OPEN cur_out FOR
         SELECT TRIM(cdcodigopostal) cdcodigopostal
           FROM codigospostales
          WHERE cdlocalidad = p_CdLocalidad
            AND cdprovincia = p_CdProvincia;
   EXCEPTION
      WHEN OTHERS THEN
         n_pkg_vitalpos_log_general.write(2, 'Modulo: ' || v_Modulo || '  Error: ' || SQLERRM);
         RAISE;
   END GetCdPostal;

   /****************************************************************************************
   * 07/04/2014 JBodnar
   * GetContactosCliente
   * Retorna un cursor los contactos de un cliente(telefonos, emails, etc)
   *****************************************************************************************/
   PROCEDURE GetContactosCliente(p_Identidad IN entidades.identidad%TYPE, cur_out OUT cursor_type) AS
      v_Modulo VARCHAR2(100) := 'PKG_CLIENTE_CENTRAL.GetContactosCliente';
   BEGIN
      --Cursor con dato de los contactos del cliente
      OPEN cur_out FOR
         SELECT TRIM(ce.cdformadecontacto) AS cdformadecontacto,
                ce.dscontactoentidad,
                fc.dsformadecontacto,
                ce.sqcontactoentidad
           FROM contactosentidades ce, formasdecontacto fc, entidades e
          WHERE ce.identidad = e.identidad
            AND ce.cdformadecontacto = fc.cdformadecontacto
            AND e.identidad = p_Identidad;
   EXCEPTION
      WHEN OTHERS THEN
         n_pkg_vitalpos_log_general.write(2, 'Modulo: ' || v_Modulo || '  Error: ' || SQLERRM);
         RAISE;
   END GetContactosCliente;

   /****************************************************************************************
   * 07/04/2014 JBodnar
   * GetDomiciliosCliente
   * Retorna un Cursor de datos de direcciones
   *****************************************************************************************/
   PROCEDURE GetDomiciliosCliente(p_Identidad IN entidades.identidad%TYPE, cur_out OUT cursor_type) AS
      v_Modulo VARCHAR2(100) := 'PKG_CLIENTE_CENTRAL.GetDomiciliosCliente';
   BEGIN
      --Cursor de datos de direcciones
      OPEN cur_out FOR
         SELECT TRIM(td.cdtipodireccion) AS CdTipoDireccion,
                td.dstipodireccion AS DsTipoDireccion,
                d.dscalle AS Calle,
                d.dsnumero AS Numero,
                d.dspisonumero AS Piso,
                TRIM(p.cdpais) AS CdPais,
                p.dspais AS DsPais,
                TRIM(l.cdlocalidad) AS CdLocalidad,
                l.dslocalidad AS DsLocalidad,
                TRIM(prov.cdprovincia) AS CdProvincia,
                TRIM(prov.dsprovincia) AS DsProvincia,
                TRIM(d.cdcodigopostal) AS CodigoPostal,
                d.icactiva AS Activa,
                d.sqdireccion AS Sqdireccion,
                i.icresol177 AS Resol177
           FROM entidades              e,
                direccionesentidades   d,
                paises                 p,
                localidades            l,
                provincias             prov,
                tipodirecciones        td,
                infoimpuestosentidades i
          WHERE e.identidad = d.identidad
            AND d.cdtipodireccion = td.cdtipodireccion
            AND d.cdpais = p.cdpais
            AND d.cdprovincia = prov.cdprovincia
            AND d.cdlocalidad = l.cdlocalidad
            AND e.identidad = i.identidad
            AND d.sqdireccion = (SELECT MAX(sqdireccion)
                                   FROM direccionesentidades
                                  WHERE identidad = e.identidad
                                    AND cdtipodireccion = c_DirComercial) --Maximo sq de las comerciales
            AND e.identidad = p_Identidad
         UNION
         --Todas las direcciones que no sean comerciales
         SELECT TRIM(td.cdtipodireccion) AS CdTipoDireccion,
                td.dstipodireccion AS DsTipoDireccion,
                d.dscalle AS Calle,
                d.dsnumero AS Numero,
                d.dspisonumero AS Piso,
                TRIM(p.cdpais) AS CdPais,
                p.dspais AS DsPais,
                TRIM(l.cdlocalidad) AS CdLocalidad,
                l.dslocalidad AS DsLocalidad,
                TRIM(prov.cdprovincia) AS CdProvincia,
                TRIM(prov.dsprovincia) AS DsProvincia,
                TRIM(d.cdcodigopostal) AS CodigoPostal,
                d.icactiva AS Activa,
                d.sqdireccion AS Sqdireccion,
                i.icresol177 AS Resol177
           FROM entidades              e,
                direccionesentidades   d,
                paises                 p,
                localidades            l,
                provincias             prov,
                tipodirecciones        td,
                infoimpuestosentidades i
          WHERE e.identidad = d.identidad
            AND d.cdtipodireccion = td.cdtipodireccion
            AND d.cdpais = p.cdpais
            AND d.cdprovincia = prov.cdprovincia
            AND d.cdlocalidad = l.cdlocalidad
            AND e.identidad = i.identidad
            AND d.cdtipodireccion <> c_DirComercial
            AND e.identidad = p_Identidad;
   EXCEPTION
      WHEN OTHERS THEN
         n_pkg_vitalpos_log_general.write(2, 'Modulo: ' || v_Modulo || '  Error: ' || SQLERRM);
         RAISE;
   END GetDomiciliosCliente;

   /***************************************************************************************************
   *  Dado un cliente retorna si tiene cargadas reducciones de alícuotas de IIBB
   *  %v 08/03/2016 JBodnar - v1.0
   **************************************************************************************************/
   PROCEDURE GetReduccionIB(p_identidad  IN entidades.identidad%TYPE,
                            p_cur_out    OUT cursor_type) IS
      v_modulo VARCHAR2(100) := 'PKG_CLIENTE_CENTRAL.GetReduccionIB';
   BEGIN

      --Retorna el cursor con la ultima tasa cargada
      open p_cur_out for
      select r.vltasa, r.dtinsert, p.dsnombre||' '||p.dsapellido as responsable
      from tblimpreduccion r, personas p
      where r.idpersona = p.idpersona
      and r.identidad= p_identidad
      and r.dtinsert = (select max(r2.dtinsert)
                        from tblimpreduccion r2
                        where r2.identidad = r.identidad);

   EXCEPTION
      WHEN OTHERS THEN
         n_pkg_vitalpos_log_general.write(2, 'Modulo: ' || v_modulo || '  Error: ' || SQLERRM);
         RAISE;
   END GetReduccionIB;

   /***************************************************************************************************
   *  OBtiene las excenciones impositivas
   *  %v 17/10/2014 MatiasG - v1.0
   **************************************************************************************************/
   PROCEDURE GetExcencionesImpositivas(p_identidad IN entidades.identidad%TYPE,
                                       p_cur_out   OUT cursor_type) IS
      v_modulo VARCHAR2(100) := 'PKG_CLIENTE_CENTRAL.GetExcencionesImpositivas';
   BEGIN
      OPEN p_cur_out FOR
         SELECT ee.dsrazonsocial,
                ex.icactivo,
                ex.identidad,
                ex.cdimpuesto,
                i.dsimpuesto,
                ex.dtdesde,
                ex.dthasta,
                ex.dtcarga,
                decode(p.dsnombre||' ' ||p.dsapellido,' ',ex.idpersona,p.dsnombre||' ' ||p.dsapellido) usuario
           FROM tblimpexencion ex, entidades ee, tblimpuesto i, personas p
          WHERE ex.identidad = ee.identidad
            AND ex.cdimpuesto = i.cdimpuesto
            and p.idpersona (+)  = ex.idpersona
            AND ex.identidad = NVL(p_identidad, ex.identidad)
            ORDER BY ex.dtcarga desc;

   EXCEPTION
      WHEN OTHERS THEN
         n_pkg_vitalpos_log_general.write(2, 'Modulo: ' || v_modulo || '  Error: ' || SQLERRM);
         RAISE;
   END GetExcencionesImpositivas;

   /****************************************************************************************
   * 12/05/2014 JBodnar
   * GetRebaTMK
   * Se evalua si un cliente tiene el certificado de REBA y si esta o no habilitado
   *****************************************************************************************/
   PROCEDURE GetRebaTMK(cur_out OUT cursor_type, pIdEntidad IN Entidades.IDENTIDAD%TYPE) AS
      v_Modulo    VARCHAR2(100) := 'PKG_CLIENTE_CENTRAL.GetRebaTMK';
      strTipodir  DireccionesEntidades.CdTipoDireccion%TYPE;
      rv          INTEGER;
      cd13178     Entidades.Cd13178%TYPE;
      dt13178     Entidades.Dt13178%TYPE;
      dtfac       Documentos.DtDocumento%TYPE;
      cdprovincia DireccionesEntidades.CdProvincia%TYPE;
      cdlocalidad DireccionesEntidades.CdLocalidad%TYPE;
   BEGIN
      -- En principio digo que no esta habilitado
      rv         := 0;
      strTipoDir := SUBSTR(N_PKG_VITALPOS_CORE.Getvlparametro('CdDirComercial', 'Creditos'), 1, 8);
      dtfac      := N_PKG_VITALPOS_CORE.Getdt();
      SELECT d.cdprovincia, cdlocalidad, cd13178, dt13178
        INTO cdprovincia, cdlocalidad, cd13178, dt13178
        FROM DireccionesEntidades d, Entidades e
       WHERE d.identidad = e.identidad
         AND d.cdtipodireccion = strtipodir
         AND e.identidad = pIdEntidad
         AND d.sqdireccion = (SELECT MAX(sqdireccion)
                                FROM DireccionesEntidades d2
                               WHERE d2.identidad = pIdEntidad
                                 AND d2.cdtipodireccion = strTipoDir);
      IF (cdprovincia <> 1 AND cdprovincia <> 14) OR (cdprovincia = 14 AND cdlocalidad <> 12331) THEN
         -- Sin Certificado
         rv := 2;
      ELSE
         IF (cd13178 IS NOT NULL) THEN
            IF (dt13178 >= dtfac) THEN
               -- Habilitado
               rv := 1;
            ELSE
               -- Vencido
               rv := 3;
            END IF;
         END IF;
      END IF;
      OPEN cur_out FOR
         SELECT rv REBA, dt13178 FECHAREBA
           FROM DUAL;
   EXCEPTION
      WHEN OTHERS THEN
         n_pkg_vitalpos_log_general.write(2, 'Modulo: ' || v_Modulo || '  Error: ' || SQLERRM);
         RAISE;
   END GetRebaTMK;

   /****************************************************************************************
   * 12/05/2014 JBodnar
   * GetDatosComerciales
   * Dado un cliente evalua Condicion de Venta, Rubro Comercial, Situacion impositiva,
   * reargos, etc, y retorna un cursor
   *****************************************************************************************/
   PROCEDURE GetDatosComerciales(cur_out OUT cursor_type, pIdEntidad IN ENTIDADES.IDENTIDAD%TYPE) IS
      v_Modulo          VARCHAR2(100) := 'PKG_CLIENTE_CENTRAL.GetDatosComerciales';
      lCDRubroComercial RUBROSCOMERCIALES.CDRubroComercial%TYPE;
      lDSRubroComercial RUBROSCOMERCIALES.DSRubroComercial%TYPE;
      lCDSituacionIva   SITUACIONESIVA.CDSituacionIva%TYPE;
      lDSSituacionIva   SITUACIONESIVA.DSSituacionIva%TYPE;
      lAplicaRecargo    NUMBER;
      lDiscrimina       NUMBER;
      lPoseePosnet      NUMBER;
      vCdLugar          OperacionesComprobantes.CdLugar%TYPE;
   BEGIN
      -- OBTENGO RUBROCOMERCIAL DEL CLIENTE
      BEGIN
         SELECT r.CDRubroComercial, UPPER(r.DSRubroComercial) DSRubroComercial
           INTO lCDRubroComercial, lDSRubroComercial
           FROM Entidades e, RUBROSCOMERCIALES r
          WHERE e.IDEntidad = pIdEntidad
            AND e.CDRubroPrincipal = r.CDRubroComercial;
      EXCEPTION
         WHEN OTHERS THEN
            lCDRubroComercial := ' ';
            lDSRubroComercial := ' ';
      END;
      -- OBTENGO SITUACIONIVA DEL CLIENTE
      BEGIN
         SELECT s.CDSituacionIva, UPPER(s.DSSituacionIva) DSSituacionIva
           INTO lCDSituacionIva, lDSSituacionIva
           FROM INFOIMPUESTOSEntidades i, SITUACIONESIVA s
          WHERE IDEntidad = pIdEntidad
            AND i.CDSituacionIva = s.CDSituacionIva;
      EXCEPTION
         WHEN OTHERS THEN
            lCDSituacionIva := ' ';
            lDSSituacionIva := ' ';
      END;
      -- OBTENGO SI EL CLIENTE APLICA RECARGO
      BEGIN
         SELECT COUNT(*)
           INTO lAplicaRecargo
           FROM EXENTIRECESP
          WHERE Identidad = pIdEntidad;
         IF lAplicaRecargo >= 1 THEN
            lAplicaRecargo := 0;
         ELSE
            lAplicaRecargo := 1;
         END IF;
      EXCEPTION
         WHEN OTHERS THEN
            lAplicaRecargo := 0;
      END;
      -- OBTENGO SI EL CLIENTE DISCRIMINA
      BEGIN
         vCdLugar := N_PKG_VITALPOS_CORE.GetVlParametro('CdLugar', 'General');
         SELECT IcDiscrimina
           INTO lDiscrimina
           FROM OperacionesComprobantes
          WHERE CdOperacion = c_IdCodigoOperacion
            AND CdSituacionIVA = lCDSituacionIva
            AND CdLugar = vCdLugar;
      EXCEPTION
         WHEN OTHERS THEN
            lDiscrimina := 0;
      END;
      -- OBTENGO SI EL CLIENTE POSEE POSNET
      BEGIN
         SELECT COUNT(*)
           INTO lPoseePosnet
           FROM DOCUMENTOS D
          WHERE D.IDENTIDAD = pIdEntidad
            AND D.CDCOMPROBANTE LIKE 'PB%';
         IF lPoseePosnet >= 1 THEN
            lPoseePosnet := 1;
         ELSE
            lPoseePosnet := 0;
         END IF;
      EXCEPTION
         WHEN OTHERS THEN
            lPoseePosnet := 0;
      END;
      OPEN cur_out FOR
         SELECT pIdEntidad        IDENTIDAD,
                lCDRubroComercial CDRubroComercial,
                lDSRubroComercial DSRubroComercial,
                lCDSituacionIva   CDSituacionIva,
                lDSSituacionIva   DSSituacionIva,
                lAplicaRecargo    AplicaRecargo,
                lDiscrimina       Discrimina,
                lPoseePosnet      PoseePosnet
           FROM DUAL;
   EXCEPTION
      WHEN OTHERS THEN
         n_pkg_vitalpos_log_general.write(2, 'Modulo: ' || v_Modulo || '  Error: ' || SQLERRM);
         RAISE;
   END GetDatosComerciales;

   /****************************************************************************************
   * 08/04/2014 JBodnar
   * GetFormasContacto
   * Retorna un cursor las diferenctes formas de contacto
   *****************************************************************************************/
   PROCEDURE GetFormasContacto(cur_out OUT cursor_type) AS
      v_Modulo VARCHAR2(100) := 'PKG_CLIENTE_CENTRAL.GetFormasContacto';
   BEGIN
      --Retorna un cursor las diferenctes formas de contacto
      OPEN cur_out FOR
         SELECT TRIM(cdformadecontacto) cdformadecontacto, dsformadecontacto
           FROM formasdecontacto;
   EXCEPTION
      WHEN OTHERS THEN
         n_pkg_vitalpos_log_general.write(2, 'Modulo: ' || v_Modulo || '  Error: ' || SQLERRM);
         RAISE;
   END GetFormasContacto;

   /****************************************************************************************
   * 11/04/2014 JBodnar
   * GetEstadosOperativos
   * Retorna un cursor con los estados operativos del sistema
   *****************************************************************************************/
   PROCEDURE GetEstadosOperativos(cur_out OUT cursor_type) IS
      v_Modulo VARCHAR2(100) := 'PKG_CLIENTE_CENTRAL.GetEstadosOperativos';
   BEGIN
      --Retorna un cursor con los estados operativos del sistema
      OPEN cur_out FOR
         SELECT e.cdestadooperativo, e.nmtarea, e.dsestadooperativo
           FROM estadosoperativos e;
   EXCEPTION
      WHEN OTHERS THEN
         n_pkg_vitalpos_log_general.write(2, 'Modulo: ' || v_Modulo || '  Error: ' || SQLERRM);
         RAISE;
   END GetEstadosOperativos;

   /****************************************************************************************
   * 11/04/2014 JBodnar
   * HabilitacionOK()
   * Verifica si el numero de habilitacion esta asignada a otro cliente
   *****************************************************************************************/
   FUNCTION HabilitacionOK(p_IdEntidad entidades.identidad%TYPE,
                           p_Cliente   OUT VARCHAR2,
                           p_Cd13178   entidades.cd13178%TYPE) RETURN NUMBER IS
      v_Modulo  VARCHAR2(100) := 'PKG_CLIENTE_CENTRAL.HabilitacionOK';
      v_Cliente VARCHAR2(100) := '';
      v_Ok      INTEGER;
   BEGIN
      --Verifico si ya existe el codigo de habilitacion para otro cliente
      BEGIN
         SELECT cdcuit || '-' || dsrazonsocial, 1
           INTO p_Cliente, v_Ok
           FROM entidades
          WHERE identidad <> p_IdEntidad
            AND cd13178 = p_Cd13178;
      EXCEPTION
         WHEN no_data_found THEN
            v_Ok      := 0;
            p_Cliente := v_Cliente;
      END;
      RETURN v_Ok;
   EXCEPTION
      WHEN OTHERS THEN
         n_pkg_vitalpos_log_general.write(2, 'Modulo: ' || v_Modulo || '  Error: ' || SQLERRM);
         RAISE;
   END HabilitacionOK;

   /****************************************************************************************
   * 09/04/2014 JBodnar
   * GetClientesPorCuit
   * Retorna un cursor con los datos de las entidades segun un cuit
   *****************************************************************************************/
   PROCEDURE GetClientesPorCuit(cur_out OUT cursor_type,
                                p_Cuit  IN entidades.cdcuit%TYPE,
                                p_Rol   IN rolesentidades.cdrol%TYPE) IS
      v_Modulo VARCHAR2(100) := 'PKG_CLIENTE_CENTRAL.GetClientesPorCuit';
   BEGIN
      --Armo el cursor y lo retorno
      OPEN cur_out FOR
         SELECT DISTINCT e.identidad,
                         e.cdcuit,
                         e.dsrazonsocial,
                         e.dsnombrefantasia,
                         tj.IdEntidad AS EsFidelizado
           FROM entidades e, rolesentidades re, TjClientesCf tj
          WHERE re.identidad = e.identidad
            AND tj.identidad(+) = e.identidad
            AND e.cdcuit like trim(p_Cuit) || '%'
            AND re.cdrol = to_number(nvl(p_Rol, 2));
   EXCEPTION
      WHEN OTHERS THEN
         n_pkg_vitalpos_log_general.write(2, 'Modulo: ' || v_Modulo || '  Error: ' || SQLERRM);
         RAISE;
   END GetClientesPorCuit;

   /****************************************************************************************
   * 19/05/2014 JBodnar
   * GetEmpleadoPorLegajo
   * Retorna los datos de un empleado de vital dado un legajo recibido
   *****************************************************************************************/
   PROCEDURE GetEmpleadoPorLegajo(cur_out OUT cursor_type, pCdLegajo IN Personas.CdLegajo%TYPE) AS
      v_Modulo VARCHAR2(100) := 'PKG_CLIENTE_CENTRAL.GetEmpleadoPorLegajo';
   BEGIN
      OPEN cur_out FOR
         SELECT Per.DsNombre, Per.DsApellido, Per.CdLegajo
           FROM Personas Per
          WHERE CdLegajo = pCdLegajo
            AND IcActivo = c_IdPersonaActiva
            AND NOT EXISTS (SELECT 1
                   FROM IdsEXcludCFVital Idex
                  WHERE Idex.IdPersona = Per.IdPersona);
   EXCEPTION
      WHEN OTHERS THEN
         n_pkg_vitalpos_log_general.write(2, 'Modulo: ' || v_Modulo || '  Error: ' || SQLERRM);
         RAISE;
   END GetEmpleadoPorLegajo;

   /****************************************************************************************
   * 09/04/2014 JBodnar
   * GetClientesPorRazonSocial
   * Retorna un cursor con los datos de las entidades segun una razon social
   *****************************************************************************************/
   PROCEDURE GetClientesPorRazonSocial(p_RazonSocial IN entidades.dsrazonsocial%TYPE,
                                       p_Rol         IN rolesentidades.cdrol%TYPE,
													cur_out       OUT cursor_type) IS
      v_Modulo VARCHAR2(100) := 'PKG_CLIENTE_CENTRAL.GetClientesPorRazonSocial';
   BEGIN
      OPEN cur_out FOR
         SELECT DISTINCT ee.identidad,
                         ee.cdcuit,
                         ee.dsrazonsocial,
                         ee.dsnombrefantasia,
                         tj.IdEntidad AS EsFidelizado
           FROM entidades ee, rolesentidades re, TjClientesCf tj
          WHERE ee.identidad = re.identidad
            AND tj.identidad(+) = ee.identidad
            AND upper(ee.dsrazonsocial) LIKE upper('%' || TRIM( p_RazonSocial) || '%')
            AND re.cdrol = to_number(nvl(p_Rol, 2));

   EXCEPTION
      WHEN OTHERS THEN
         n_pkg_vitalpos_log_general.write(2, 'Modulo: ' || v_Modulo || '  Error: ' || SQLERRM);
         RAISE;
   END GetClientesPorRazonSocial;

   /****************************************************************************************
   * GetClientesPorDireccion
   * Retorna un cursor con los datos de las entidades por provincia/localidad/calle
   *****************************************************************************************/
   PROCEDURE GetClientesPorDireccion(p_pais direccionesentidades.cdpais%type,
                                     p_provincia direccionesentidades.cdprovincia%type,
                                     p_localidad direccionesentidades.cdlocalidad%type,
                                     p_strcalle direccionesentidades.dscalle%type,
                                     p_altura   integer,
													           cur_out       OUT cursor_type) IS

      v_Modulo VARCHAR2(100) := 'PKG_CLIENTE_CENTRAL.GetClientesPorDireccion';

   BEGIN
      OPEN cur_out FOR
         SELECT DISTINCT ee.identidad,
                         ee.cdcuit,
                         ee.dsrazonsocial,
                         de.dscalle,
                         de.dsnumero
           FROM entidades ee, direccionesentidades de
          WHERE ee.identidad = de.identidad
            AND de.cdpais = p_pais
            and de.cdprovincia = p_provincia
            and de.cdlocalidad = p_localidad
            AND upper(de.dscalle) like upper('%' || TRIM( p_strcalle) || '%')
            and upper(de.dsnumero) like upper(trim(to_char(nvl(p_altura, 1)/100)) || '%')
            ;

   EXCEPTION
      WHEN OTHERS THEN
         n_pkg_vitalpos_log_general.write(2, 'Modulo: ' || v_Modulo || '  Error: ' || SQLERRM);
         RAISE;
   END GetClientesPorDireccion;

   /****************************************************************************************
   * 12/05/2014 JBodnar
   * GetClienteCuenta
   * Retorna un cursor con los datos de las entidades dada una cuenta
   *****************************************************************************************/
   PROCEDURE GetClienteCuenta(cur_out OUT cursor_type, p_IdCuenta IN tblcuenta.idcuenta%TYPE) AS
      v_Modulo VARCHAR2(100) := 'PKG_CLIENTE_CENTRAL.GetClienteCuenta';
   BEGIN
      OPEN cur_out FOR
         SELECT DISTINCT e.identidad,
                         e.cdcuit,
                         e.dsrazonsocial,
                         e.dsnombrefantasia,
                         e.CdMainCanal,
                         Tj.IdEntidad       AS EsFidelizado,
                         cli.IdEntidad      ExcludLimitArts
           FROM entidades e, rolesentidades r, TjClientesCf Tj, Facart_Clientes cli
          WHERE e.identidad = r.identidad
            AND e.identidad = (SELECT identidad
                                 FROM tblcuenta
                                WHERE idcuenta = p_IdCuenta
                                  AND rownum = 1)
            AND e.IdEntidad = Tj.IdEntidad(+)
            AND e.IdEntidad = cli.IdEntidad(+);
   EXCEPTION
      WHEN OTHERS THEN
         n_pkg_vitalpos_log_general.write(2, 'Modulo: ' || v_Modulo || '  Error: ' || SQLERRM);
         RAISE;
   END GetClienteCuenta;

   /****************************************************************************************
   * 24/04/2014 JBodnar
   * GetRolesCliente
   * Retorna los roles que tiene asociado un cliente
   *****************************************************************************************/
   PROCEDURE GetRolesCliente(p_Identidad IN entidades.identidad%TYPE, cur_out OUT cursor_type) AS
      v_Modulo VARCHAR2(100) := 'PKG_CLIENTE_CENTRAL.GetRolesCliente';
   BEGIN
      --Cursor de datos de los roles del cliente
      OPEN cur_out FOR
         SELECT re.cdrol, r.dsrol
           FROM rolesentidades re, roles r
          WHERE re.cdrol = r.cdrol
            AND re.identidad = p_Identidad
				AND r.icactivo = 1;
   EXCEPTION
      WHEN OTHERS THEN
         n_pkg_vitalpos_log_general.write(2, 'Modulo: ' || v_Modulo || '  Error: ' || SQLERRM);
         RAISE;
   END GetRolesCliente;

   /****************************************************************************************
   * 10/06/2014 JBodnar
   * GetRoles
   * Retorna los roles
   *****************************************************************************************/
   PROCEDURE GetRoles(cur_out OUT cursor_type) AS
      v_Modulo VARCHAR2(100) := 'PKG_CLIENTE_CENTRAL.GetRoles';
   BEGIN
      --Cursor de datos de los roles
      OPEN cur_out FOR
         SELECT r.cdrol, r.dsrol
           FROM roles r
          WHERE r.icactivo = 1;
   EXCEPTION
      WHEN OTHERS THEN
         n_pkg_vitalpos_log_general.write(2, 'Modulo: ' || v_Modulo || '  Error: ' || SQLERRM);
         RAISE;
   END GetRoles;

   /****************************************************************************************
   * 12/05/2014 JBodnar
   * ExcluidoFidelizadoRecargo
   * Retorna los roles que tiene asociado un cliente
   *****************************************************************************************/
   PROCEDURE ExcluidoFidelizadoRecargo(cur_out    OUT cursor_type,
                                       pIdEntidad IN Entidades.IdEntidad%TYPE) AS
      v_Modulo                   VARCHAR2(100) := 'PKG_CLIENTE_CENTRAL.ExcluidoFidelizadoRecargo';
      vTieneTJFidelizacion       INTEGER;
      vExcluidoFidelizadoRecargo INTEGER;
      vCuantos                   INTEGER;
   BEGIN
      vExcluidoFidelizadoRecargo := 0;
      SELECT COUNT(*)
        INTO vTieneTJFidelizacion
        FROM tjclientescf tj, entidades e
       WHERE tj.identidad = pIdEntidad
         AND tj.identidad = e.identidad
         AND cdestadooperativo = c_IdEntidadOperativa;
      IF (vTieneTJFidelizacion = 1) THEN
         SELECT COUNT(*)
           INTO vCuantos
           FROM CltesFidelExclud
          WHERE identidad = pIdEntidad;
         IF (vCuantos >= 1) THEN
            vExcluidoFidelizadoRecargo := 1;
         END IF;
      END IF;
      OPEN cur_out FOR
         SELECT vExcluidoFidelizadoRecargo Exclud
           FROM DUAL;
   EXCEPTION
      WHEN OTHERS THEN
         n_pkg_vitalpos_log_general.write(2, 'Modulo: ' || v_Modulo || '  Error: ' || SQLERRM);
         RAISE;
   END ExcluidoFidelizadoRecargo;

   /****************************************************************************************
   * Retorna la descripcion de asociada a un codigo de localidad
   * %v 12/05/2014 MatiasG: V1.0
   *****************************************************************************************/
   FUNCTION GetDescLocalidad(p_cdlocalidad localidades.cdlocalidad%TYPE) RETURN VARCHAR2 AS
      v_Modulo      VARCHAR2(100) := 'PKG_CLIENTE_CENTRAL.GetDescLocalidad';
      v_dsLocalidad localidades.dslocalidad%TYPE;
   BEGIN

      SELECT dslocalidad
        INTO v_dsLocalidad
        FROM localidades
       WHERE cdlocalidad = p_cdlocalidad
         AND Rownum = 1;

      RETURN v_dsLocalidad;

   EXCEPTION
      WHEN OTHERS THEN
         n_pkg_vitalpos_log_general.write(2, 'Modulo: ' || v_Modulo || '  Error: ' || SQLERRM);
         RAISE;
   END GetDescLocalidad;

   /****************************************************************************************
   * Retorna la descripcion de asociada a un codigo de provincia
   * %v 12/05/2014 MatiasG: V1.0
   *****************************************************************************************/

   FUNCTION GetDescProvincia(p_cdprovincia provincias.cdprovincia%TYPE) RETURN VARCHAR2 AS
      v_Modulo      VARCHAR2(100) := 'PKG_CLIENTE_CENTRAL.GetDescProvincia';
      v_dsprovincia provincias.dsprovincia%TYPE;

   BEGIN

      SELECT dsprovincia
        INTO v_dsprovincia
        FROM provincias
       WHERE cdprovincia = p_cdprovincia
         AND Rownum = 1;


      RETURN v_dsprovincia;

   EXCEPTION
      WHEN OTHERS THEN
         n_pkg_vitalpos_log_general.write(2, 'Modulo: ' || v_Modulo || '  Error: ' || SQLERRM);
         RAISE;

   END GetDescProvincia;

   /****************************************************************************************
   * Retorna la forma del cliente
   * %v 12/05/2014 MatiasG: V1.0
   *****************************************************************************************/
	PROCEDURE GetFormaCliente(p_iDentidad IN entidades.identidad%TYPE,
		                       p_cur_out OUT cursor_type) AS
		v_Modulo      VARCHAR2(100) := 'PKG_CLIENTE_CENTRAL.GetFormaCliente';

	BEGIN
		OPEN p_cur_out FOR
			SELECT ee.cdforma, fi.dsforma
			  FROM entidades ee, tblformaingreso fi
			 WHERE ee.identidad = p_iDentidad
				AND ee.cdforma = fi.cdforma;

	EXCEPTION
		WHEN OTHERS THEN
			n_pkg_vitalpos_log_general.write(2, 'Modulo: ' || v_Modulo || '  Error: ' || SQLERRM);
			RAISE;
	END GetFormaCliente;

  /****************************************************************************************
  * %v 01/03/2019 JBodnar - Retorna los datos del cliente dados de alta en mercado pago
  *****************************************************************************************/
  Procedure GetClienteMercadoPago(p_Identidad   In entidades.identidad%Type,
                                  p_InicioDesde IN DATE,
                                  p_InicioHasta IN DATE,
                                  p_icenviado   In integer default 0,
                                  cur_out       Out cursor_type) As
    v_Modulo Varchar2(100) := 'PKG_CLIENTE_CENTRAL.GetClienteMercadoPago';
  Begin
    Open cur_out For
      SELECT e.identidad,
             s.dssucursal,
             e.dsrazonsocial,
             e.dsnombrefantasia,
             e.cdcuit,
             r.dsrubrocomercial,
             pkg_reporte_central.GetCanal(e.identidad, s.cdsucursal) as canal,
             TRIM(prov.dsprovincia) || ' - ' || l.dslocalidad || ' (' ||
             TRIM(d.cdcodigopostal) || ') - ' || d.dscalle || ' ' ||
             d.dsnumero as direccion,
             m.icppoint,
             pi.dsnombre || ' ' || pi.dsapellido as iniciado,
             m.dtinicio,
             pe.dsnombre || ' ' || pe.dsapellido as enviado,
             m.dtenvio
        FROM entidades             e,
             direccionesentidades  d,
             paises                p,
             localidades           l,
             provincias            prov,
             sucursales            s,
             tblentidadmercadopago m,
             rubroscomerciales     r,
             personas              pi,
             personas              pe
       WHERE e.identidad = d.identidad
         and m.cdsucursal = s.cdsucursal
         and m.identidad = e.identidad
         AND d.cdpais = p.cdpais
         and decode(nvl(m.idpersonaenvio,'0'),'0','0','1')=nvl(p_icenviado,decode(nvl(m.idpersonaenvio,'0'),'0','0','1'))
         and pi.idpersona = m.idpersonainicio
         AND m.dtinicio BETWEEN trunc(p_InicioDesde) AND trunc(p_InicioHasta + 1)
         and pe.idpersona(+) = m.idpersonaenvio
         and r.cdrubrocomercial = e.cdrubroprincipal
         AND d.cdprovincia = prov.cdprovincia
         AND d.cdlocalidad = l.cdlocalidad
         AND e.identidad = nvl(p_Identidad,e.identidad)
         AND d.sqdireccion =
             (SELECT MAX(sqdireccion)
                FROM direccionesentidades
               WHERE identidad = e.identidad
                 AND cdtipodireccion = '2       '); --Maximo sq de las comerciales

  Exception
    When Others Then
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_Modulo || '  Error: ' ||
                                       Sqlerrm);
      Raise;
  End GetClienteMercadoPago;

  /**************************************************************************************************
  * Indica que el pedido de alta de un cliente para operar con MercadoPago fue enviado
  * %v 12/03/2019 - FP
  ***************************************************************************************************/
  Procedure SetEvioMercadoPago( p_Identidad              IN entidades.identidad%Type,
                                                  p_idPersonaEnvio       IN personas.idpersona%TYPE,
                                                  p_ok                     OUT INTEGER,
                                                  p_error               OUT VARCHAR2 ) Is
  v_Modulo Varchar2(100) := 'PKG_CLIENTE_CENTRAL.SetEvioMercadoPago';
  Begin
    Update tblentidadmercadopago
        Set idpersonaenvio = p_idPersonaEnvio,
            dtenvio = sysdate
        Where identidad = p_Identidad;

    p_ok := 1;
    Commit;

  Exception
    When Others Then
      n_pkg_vitalpos_log_general.write(2,'Modulo: ' || v_Modulo || ' Error: ' || SQLERRM);
      p_ok    := 0;
      p_error := 'Modulo: ' || v_Modulo || ' Error: ' || Sqlerrm;
      Raise;
  End SetEvioMercadoPago;

END PKG_CLIENTE_CENTRAL;
/
