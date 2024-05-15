CREATE OR REPLACE PACKAGE PKG_CLIENTE Is

  /**************************************************************************************************
  * Antigua librería que da servicios de clientes del PKG_CLIENTE que usa la Caja Unificada
  * En el futuro el PKG_CLIENTE va a pasar a fuera de uso y solo se va utilizar este
  *************************************************************************************************/
  c_SITIVA_CF Constant SITUACIONESIVA.CDSITUACIONIVA%Type := '48';

  Function GetIdEntidad(p_cdcuit ENTIDADES.CDCUIT%Type)
    Return ENTIDADES.IDENTIDAD%Type;

  Procedure GetDireccion(p_idEntidad In ENTIDADES.IDENTIDAD%Type,
                         o_cdtipdir  Out DIRECCIONESENTIDADES.CDTIPODIRECCION%Type,
                         o_sqdir     Out DIRECCIONESENTIDADES.SQDIRECCION%Type);

  Procedure GetDataEntidad(p_idEntidad In ENTIDADES.IDENTIDAD%Type,
                           o_cdsitiva  Out SITUACIONESIVA.CDSITUACIONIVA%Type,
                           o_cdtipdir  Out DIRECCIONESENTIDADES.CDTIPODIRECCION%Type,
                           o_sqdir     Out DIRECCIONESENTIDADES.SQDIRECCION%Type);

  Function GetCuitCF(p_ref Varchar2, p_chr1 Varchar2, p_chr2 Varchar2)
    Return ENTIDADES.CDCUIT%Type;

  Function GetLegajo(p_ref Varchar2) Return Varchar2;

  Function GetHabilitBebidaAlcoholica(p_idEntidad In tblcu_cabecera.identidad%Type)
    Return Integer;

  Function EsConsumidorFinal(p_ident ENTIDADES.IDENTIDAD%Type) Return Integer;

  Function EsCliente(p_ident ENTIDADES.IDENTIDAD%Type) Return Integer;

  Function GetEntidadAlter(p_idEntidad    ENTIDADES.IDENTIDAD%Type,
                           p_dsReferencia PEDIDOS.DSREFERENCIA%Type)
    Return ENTIDADES.Identidad%Type;

  Function DireccionOK(p_idEntidad ENTIDADES.IDENTIDAD%Type) Return Number;

  Procedure GetEntidadRef(p_ref     In tblcu_cabecera.dsreferencia%Type,
                          p_entidad Out tblcu_cabecera.identidad%Type);

  Procedure GetClienteExclud(p_idEntidad In ENTIDADES.IDENTIDAD%Type,
                             p_excluido  Out Number);

  /**************************************************************************************************
  * Fin de Antigua librería que da servicios de clientes del PKG_CLIENTE que usa la Caja Unificada
  *************************************************************************************************/
  Type cursor_type Is Ref Cursor;

  Procedure AltaDeCliente(p_CdSucursal     In entidades.cdmainsucursal%Type,
                          p_RubroPrincipal In entidades.cdrubroprincipal%Type,
                          p_RazonSocial    In entidades.dsrazonsocial%Type,
                          p_NombreFantasia In entidades.dsnombrefantasia%Type,
                          p_CdCuit         In entidades.cdcuit%Type,
                          p_IdPersonaAlta  In entidades.idpersonaalta%Type,
                          p_Dt13178        In entidades.dt13178%Type,
                          p_Cd13178        In entidades.cd13178%Type,
                          p_CdSituacionIva In infoimpuestosentidades.cdsituacioniva%Type,
                          p_Convenio       In infoimpuestosentidades.icconvenio%Type,
                          p_IcMunicipal    In infoimpuestosentidades.icmunicipal%Type,
                          p_IngresosBrutos In infoimpuestosentidades.cdingresosbrutos%Type,
                          p_NombreCuenta   In tblcuenta.nombrecuenta%type,
                          --p_Password in tblusuarioentidad.password%TYPE,
                          --Parametros de retorno
                          p_Identidad Out entidades.identidad%Type,
                          p_IdCuenta  Out tblcuenta.idcuenta%Type,
                          p_ok        Out Integer,
                          p_error     Out Varchar2);

  Procedure GrabarDomicilio(p_Identidad     In entidades.identidad%Type,
                            p_IdPersonaAlta In entidades.idpersonaalta%Type,
                            p_CdTipoDirec   In tipodirecciones.cdtipodireccion%Type,
                            p_CdPais        In paises.cdpais%Type,
                            p_CdProvincia   In provincias.cdprovincia%Type,
                            p_CdLocalidad   In localidades.cdlocalidad%Type,
                            p_CdPostal      In codigospostales.cdcodigopostal%Type,
                            p_Calle         In direccionesentidades.dscalle%Type,
                            p_Numero        In direccionesentidades.dsnumero%Type,
                            p_Piso          In direccionesentidades.dspisonumero%Type,
                            p_icActiva      In direccionesentidades.icactiva%type,
                            p_IdCuenta      In tblcuenta.idcuenta%Type,
                            p_ok            Out Integer,
                            p_error         Out Varchar2);

  Procedure ActualizarDomicilio(p_SqDireccion    In direccionesentidades.sqdireccion%Type,
                                p_CdTipoDirec    In direccionesentidades.cdtipodireccion%type,
                                p_Identidad      In direccionesentidades.identidad%Type,
                                p_IdPersonaModif In entidades.idpersonamodif%Type,
                                p_icActiva       In direccionesentidades.icactiva%type,
                                p_ok             Out Integer,
                                p_error          Out Varchar2);

  Procedure BorrarDomicilio(p_Identidad      In entidades.identidad%Type,
                            p_SqDireccion    In direccionesentidades.sqdireccion%Type,
                            p_TipoDireccion  In direccionesentidades.cdtipodireccion%Type,
                            p_IdPersonaModif In entidades.idpersonamodif%Type,
                            p_ok             Out Integer,
                            p_error          Out Varchar2);

  Procedure GrabarContacto(p_Identidad         In entidades.identidad%Type,
                           p_CdFormadeContacto In contactosentidades.cdformadecontacto%Type,
                           p_IdPersona         In contactosentidades.idpersona%Type,
                           p_DsFormadeContacto In contactosentidades.dscontactoentidad%Type,
                           p_ok                Out Integer,
                           p_error             Out Varchar2);

  Procedure BorrarContacto(p_Identidad         In entidades.identidad%Type,
                           p_CdContacto        In contactosentidades.cdformadecontacto%Type,
                           p_SqContactoEntidad In contactosentidades.sqcontactoentidad%Type,
                           p_IdPersonaModif    In entidades.idpersonamodif%Type,
                           p_ok                Out Integer,
                           p_error             Out Varchar2);

  Procedure ActualizarContacto(p_SqContactoEntidad In contactosentidades.sqcontactoentidad%Type,
                               p_Identidad         In entidades.identidad%Type,
                               p_CdFormadeContacto In contactosentidades.cdformadecontacto%Type,
                               p_IdPersonaModif    In entidades.idpersonamodif%Type,
                               p_DsFormadeContacto In contactosentidades.dscontactoentidad%Type,
                               p_ok                Out Integer,
                               p_error             Out Varchar2,
                               p_modificado        Out Integer);

  Procedure ActualizarCliente(p_IdEntidad       In entidades.identidad%Type,
                              p_CdSucursal      In entidades.cdmainsucursal%Type,
                              p_RubroPrincipal  In entidades.cdrubroprincipal%Type,
                              p_RazonSocial     In entidades.dsrazonsocial%Type,
                              p_NombreFantasia  In entidades.dsnombrefantasia%Type,
                              p_EstadoOperativo In entidades.cdestadooperativo%Type,
                              p_CdCuit          In entidades.cdcuit%Type,
                              p_IdPersonaModif  In entidades.idpersonamodif%Type,
                              p_Dt13178         In entidades.dt13178%Type,
                              p_Cd13178         In entidades.cd13178%Type,
                              p_CdSituacionIva  In infoimpuestosentidades.cdsituacioniva%Type,
                              p_Convenio        In infoimpuestosentidades.icconvenio%Type,
                              p_IcMunicipal     In infoimpuestosentidades.icmunicipal%Type,
                              p_IngresosBrutos  In infoimpuestosentidades.cdingresosbrutos%Type,
                              p_ok              Out Integer,
                              p_error           Out Varchar2);

  Procedure ActualizaInfoImpuestos(p_Identidad      In entidades.identidad%Type,
                                   p_CdSituacionIva In infoimpuestosentidades.cdsituacioniva%Type,
                                   p_Convenio       In infoimpuestosentidades.icconvenio%Type,
                                   p_IcMunicipal    In infoimpuestosentidades.icmunicipal%Type,
                                   p_IngresosBrutos In infoimpuestosentidades.cdingresosbrutos%Type,
                                   p_ok             Out Integer,
                                   p_error          Out Varchar2);

  Procedure ValidaSintaxisCuit(p_CdCuit           In entidades.cdcuit%Type,
                               p_CdCuitFormateado Out entidades.cdcuit%Type,
                               p_ok               Out Integer,
                               p_error            Out Varchar2);
  FUNCTION ValidarSintaxisCuit(p_CdCuit In entidades.cdcuit%Type)
    RETURN entidades.cdcuit%Type;

  Function ExisteEntidad(p_cdcuit    ENTIDADES.CDCUIT%Type,
                         p_Identidad entidades.identidad%Type) Return Integer;

  Procedure GetEstadoCliente(p_idEntidad In entidades.identidad%Type,
                             p_ok        Out Integer,
                             p_error     Out Varchar2);

  Procedure GetDatosCliente(p_Identidad In entidades.identidad%Type,
                            cur_out     Out cursor_type);

  Procedure GrabarRolesCliente(p_IdEntidad rolesentidades.identidad%Type,
                               p_CdRol     roles.cdrol%Type,
                               p_IdPersona rolesentidades.idpersonaresponsable%Type,
                               p_ok        Out Integer,
                               p_error     Out Varchar2);

  Procedure BorrarRolesCliente(p_IdEntidad rolesentidades.identidad%Type,
                               p_CdRol     roles.cdrol%Type,
                               p_ok        Out Integer,
                               p_error     Out Varchar2);

  --Gets Generales para Alta de Clientes
  Procedure GetSucursales(cur_out Out cursor_type);

  Procedure GetFidelizacionCliente(cur_out Out cursor_type,
                                   pCodBar In TjClientesCf.VlCodBar%Type);

  Procedure GetCanales(cur_out Out cursor_type);

  Procedure GetRubros(cur_out Out cursor_type);

  Procedure GetTipoDirec(cur_out Out cursor_type);

  Procedure GetPaises(cur_out Out cursor_type);

  Procedure GetProvincias(p_Pais  In paises.cdpais%Type,
                          cur_out Out cursor_type);

  Procedure GetSituacionIva(cur_out Out cursor_type);

  Procedure GetSituacionIB(cur_out Out cursor_type);

  Procedure GetSituacionMunicipal(cur_out Out cursor_type);

  Procedure GetLocalidades(p_Localidad In localidades.dslocalidad%Type,
                           p_Provincia In provincias.cdprovincia%Type,
                           p_Pais      In paises.cdpais%Type,
                           cur_out     Out cursor_type);

  Procedure GetCdPostal(p_CdLocalidad In localidades.cdlocalidad%Type,
                        p_CdProvincia In provincias.cdprovincia%Type,
                        cur_out       Out cursor_type);

  Procedure GetContactosCliente(p_Identidad In entidades.identidad%Type,
                                cur_out     Out cursor_type);

  Procedure GetControlaEfectivo(p_idEntidad In ENTIDADES.IDENTIDAD%Type,
                                p_Maximo    Out Limite_Condvta.Maximo%type);

  Procedure GetDomiciliosCliente(p_Identidad In entidades.identidad%Type, /*p_DomicilioCuenta in integer,*/
                                 cur_out     Out cursor_type);

  Procedure GetRebaTMK(cur_out    Out cursor_type,
                       pIdEntidad In Entidades.IDENTIDAD%Type);

  Procedure GetDatosComerciales(cur_out    Out cursor_type,
                                pIdEntidad In ENTIDADES.IDENTIDAD%Type);

  Procedure GetFormasContacto(cur_out Out cursor_type);

  Procedure GetEstadosOperativos(cur_out Out cursor_type);

  Function HabilitacionOK(p_IdEntidad entidades.identidad%Type,
                          p_Cliente   Out Varchar2,
                          p_Cd13178   entidades.cd13178%Type) Return Number;

  Procedure GetClientesPorCuit(cur_out Out cursor_type,
                               p_Cuit  In entidades.cdcuit%Type,
                               p_Rol   In rolesentidades.cdrol%Type);

  PROCEDURE GetClienteBajaPorCuit(p_Cuit   IN entidades.cdcuit%TYPE,
                                  p_Activo OUT Integer);

  Procedure GetEmpleadoPorLegajo(cur_out   Out cursor_type,
                                 pCdLegajo In Personas.CdLegajo%Type);

  Procedure GetEmpleadoPorDNI(cur_out       Out cursor_type,
                              p_nudocumento In Personas.Nudocumento%Type);

  Procedure GetClientesPorRazonSocial(cur_out       Out cursor_type,
                                      p_RazonSocial In entidades.dsrazonsocial%Type,
                                      p_Rol         In rolesentidades.cdrol%Type);

  PROCEDURE GetClienteBajaRazon(p_RazonSocial In entidades.dsrazonsocial%Type,
                                p_Activo      OUT Integer);

  Procedure GetClienteCuenta(cur_out    Out cursor_type,
                             p_IdCuenta In tblcuenta.idcuenta%Type);

  Procedure GetRolesCliente(p_Identidad In entidades.identidad%Type,
                            cur_out     Out cursor_type);

  Procedure ExcluidoFidelizadoRecargo(cur_out    Out cursor_type,
                                      pIdEntidad In Entidades.IdEntidad%Type);

  function GetCuitPorCuenta(p_idCuenta tblcuenta.idcuenta%Type)
    return entidades.cdcuit%type;

  Function GetDescLocalidad(p_cdlocalidad localidades.cdlocalidad%Type)
    Return Varchar2;

  Function GetDescProvincia(p_cdprovincia provincias.cdprovincia%Type)
    Return Varchar2;

  FUNCTION GetReferencia(p_dsReferencia IN documentos.dsreferencia%TYPE)
    RETURN VARCHAR2;

  PROCEDURE ObtenerCantidadTjFidelizacion(cur_out    OUT cursor_type,
                                          pIdEntidad TJCLIENTESCF.IDENTIDAD%TYPE);

  PROCEDURE ObtenerDatosTjFidelCliente(cur_out    OUT cursor_type,
                                       pIdEntidad TJCLIENTESCF.IDENTIDAD%TYPE);

  PROCEDURE ActualizarCantReimpresionesTJ(pCodBar     TJCLIENTESCF.VLCODBAR%TYPE,
                                          pIdEntidad  TJCLIENTESCF.IDENTIDAD%TYPE,
                                          pCdSucursal TJCLIENTESCF.CDSUCURSAL%TYPE,
                                          pIdPersona  TJCLIENTESCF.IDPERSONA%TYPE);

  PROCEDURE InsertarReimpresionTJ(pCodBar     TJCLIENTESCF.VLCODBAR%TYPE,
                                  pIdEntidad  TJCLIENTESCF.IDENTIDAD%TYPE,
                                  pCdSucursal TJCLIENTESCF.CDSUCURSAL%TYPE,
                                  pIdPersona  TJCLIENTESCF.IDPERSONA%TYPE);

  PROCEDURE ObtenerEstadoOperativo(cur_out    OUT cursor_type,
                                   pIdEntidad ENTIDADES.IDENTIDAD%TYPE);

  Procedure ValidaCPCaba(p_provincia    In provincias.cdprovincia%type,
                         p_localidad    In localidades.cdlocalidad%type,
                         p_codigopostal In Codigospostales.Cdcodigopostal%type,
                         p_ok           Out Integer,
                         p_error        Out Varchar2);
  PROCEDURE ValidarCodigoCupon(p_Codigo IN tblentidad_cupon.vlcodigo%TYPE,
                               p_Existe OUT Integer);
  PROCEDURE InsertarCodigoCupon(p_IdEntidad IN tblentidad_cupon.identidad%TYPE,
                                p_Codigo    IN tblentidad_cupon.vlcodigo%TYPE,
                                p_update    IN tblentidad_cupon.icupdate%TYPE);

  PROCEDURE ValidarCodigoPresentado(p_Codigo    IN tblentidad_cupon.vlcodigo%TYPE,
                                    p_IdEntidad IN tblentidad_cupon.identidad%TYPE,
                                    p_ok        OUT integer,
                                    p_error     OUT varchar2);

  FUNCTION VerificarCuponCargado(p_identidad IN entidades.identidad%TYPE)
    RETURN VARCHAR2;

  PROCEDURE VerificarSiTieneCupon(P_Identidad  IN entidades.identidad%TYPE,
                                  P_TieneCupon OUT Integer);

  Procedure GrabarClienteCf(p_Identidad  In tbldatoscliente.identidad%Type,
                            p_Nombre     In tbldatoscliente.nombre%Type,
                            p_Dni        In tbldatoscliente.dni%Type,
                            p_Domicilio  In tbldatoscliente.domicilio%Type,
                            p_Iddatoscli Out tbldatoscliente.iddatoscli%Type,
                            p_ok         Out Integer,
                            p_error      Out Varchar2);

  Procedure GetClienteCfAdmin(p_Identidad In tbldatoscliente.identidad%Type,
                              p_Nombre    In tbldatoscliente.nombre%Type default null,
                              p_Dni       In tbldatoscliente.dni%Type default null,
                              cur_out     Out cursor_type);

  Procedure GetClienteCf(p_Identidad In tbldatoscliente.identidad%Type,
                         p_Nombre    In tbldatoscliente.nombre%Type default null,
                         p_Dni       In tbldatoscliente.dni%Type default null,
                         p_Existe    Out integer ,
                         cur_out     Out cursor_type);

  Procedure GetPorDni(p_Dni   In tbldatoscliente.dni%Type,
                      cur_out Out cursor_type);

  PROCEDURE AcumularSaldoDni(p_iddatoscli IN tbldatoscliente.iddatoscli%TYPE,
                             p_iddoctrx   documentos.iddoctrx%type);                                                  

  PROCEDURE TieneSaldoDni(p_iddatoscli IN tbldatoscliente.iddatoscli%TYPE,
                          p_tiene      OUT integer);

  function TieneSaldoDni(p_iddatoscli IN tbldatoscliente.iddatoscli%TYPE)
    return integer;

  function TieneSaldoCliente(p_identidad IN documentos.identidad%TYPE)
    return integer;

  Procedure BorrarClienteCf(p_Iddatoscli In tbldatoscliente.iddatoscli%Type,
                            p_ok         Out Integer,
                            p_error      Out Varchar2);

  Procedure ActualizarClienteCf(p_Iddatoscli In tbldatoscliente.iddatoscli%Type,
                                p_Identidad  In tbldatoscliente.identidad%Type,
                                p_Nombre     In tbldatoscliente.nombre%Type,
                                p_Dni        In tbldatoscliente.dni%Type,
                                p_Domicilio  In tbldatoscliente.domicilio%Type,
                                p_ok         Out Integer,
                                p_error      Out Varchar2);

  function EsExcluido(p_Identidad IN entidades.identidad%TYPE) return char;

  Procedure GetDatosExcluidos(p_Nombre    Out TBLDATOS_PERSONALES.NOMBRE%Type,
                              p_Dni       Out TBLDATOS_PERSONALES.NRODOC%Type,
                              p_Domicilio Out TBLDATOS_PERSONALES.DOMICILIO%Type);

  function ValidaCuit(p_cuit number) return number;

  PROCEDURE GrabarEntidadMP(p_Identidad         IN entidades.identidad%TYPE,
                            p_icppoint          IN integer,
                            p_IdPersona         IN contactosentidades.idpersona%TYPE,
                            p_ok                OUT INTEGER,
                            p_error             OUT VARCHAR2);

  PROCEDURE UpdateEntidadMP(p_Identidad IN entidades.identidad%TYPE,
                            p_icppoint  IN integer,
                            p_IdPersona         IN contactosentidades.idpersona%TYPE,
                            p_ok        OUT INTEGER,
                            p_error     OUT VARCHAR2);

  PROCEDURE GetIcPoint(p_Identidad IN entidades.identidad%TYPE,
                            p_icppoint  Out integer);
                            
   function ValidarCuitPadron(p_Dni In tbldatoscliente.dni%Type,
                              p_identidad in entidades.identidad%type)
    return integer;                            

End PKG_CLIENTE;
/
CREATE OR REPLACE PACKAGE BODY PKG_CLIENTE Is

  /**************************************************************************************************
  Juan Bodnar
  26/03/2014
  Nueva Librería que da servicios de clientes para ser utilizado por el nuevo sisteama de Creditos
  El ABM de clientes y la informacion relacionada como direcciones, contactos, caracteristicas impositivas
  esta manejado en este packages
  *************************************************************************************************/

  --Declaracion de constantes
  c_DirComercial         Constant direccionesentidades.cdtipodireccion%Type := '2';
  c_DirParticular        Constant direccionesentidades.cdtipodireccion%Type := '4';
  c_IdCodigoOperacion    Constant OperacionesComprobantes.CdComprobante%Type := '30';
  c_IdEntidadOperativa   Constant Entidades.CdEstadoOperativo%Type := 'A';
  c_responsableinscripto Constant SITUACIONESIVA.CDSITUACIONIVA%Type := '1';
  c_IdPersonaActiva      Constant Personas.IcActivo%Type := 1;
  c_Sucursal sucursales.cdsucursal%Type := getvlparametro('CDSucursal',
                                                          'General');
   c_MaxAcum   number := getvlparametro('MaxMontoDni', 'General');

  /****************************************************************************************
  * 27/09/2013
  * MarianoL
  * Obtiene el id de la entidad en base al cuit, retorna Nulo si no lo encuentra
  * El caso se puede dar si el cuit referenciado en un pedido no ha sido dado de alta como entidad.
  *****************************************************************************************/
  Function GetIdEntidad(p_cdcuit ENTIDADES.CDCUIT%Type)
    Return ENTIDADES.IDENTIDAD%Type Is
    v_idEnti ENTIDADES.IDENTIDAD%Type;
  Begin
    Select identidad
      Into v_idEnti
      From entidades e
     Where e.cdcuit = p_cdcuit;
    Return v_idEnti;
  Exception
    When Others Then
      Return Null;
  End GetIdEntidad;
  
  /****************************************************************************************
  * 27/07/2020
  * IAquilano
  * Funcion que retorna si el dni existe en el padron AFIP
  * %v 10/07/2020 - APW - Agrego validacion por el cuit del cliente
  *****************************************************************************************/
  function ValidarCuitPadron(p_Dni       In tbldatoscliente.dni%Type,
                             p_identidad in entidades.identidad%type)
    return integer is
  
    v_Result entidades.cdcuit%type;
    v_cont   integer;
    v_cdcuitpropio varchar2(11);
  
  begin
    -- si ingresan el DNI del cliente lo dejamos
    select  trim(replace(e.cdcuit,'-',null))
    into v_cdcuitpropio
    from entidades e
    where e.identidad = p_identidad;
      
    select count(*)
      into v_cont
      from afip_padron_iva_monot ap
     where substr(ap.cdcuit, 3, 8) = p_dni
       and ap.cdcuit like '2%' -- solo personas
       and ap.cdcuit <> v_cdcuitpropio; 
  
    If v_cont > 0 then
      v_Result := 1;
    else
      v_Result := 0;
    end if;
  
    return(v_Result);
  
  end ValidarCuitPadron;

  /****************************************************************************************
  * 30/12/2014
  * MarianoL
  * Dada una cuenta devuelve el CUIT del cliente.  Si no lo encuentra devuelve null.
  * %v 29/01/2016 - APW - Cambio búsqueda en tbldireccioncuenta por tblcuenta - no todas las cuentas tienen direcciones
  *****************************************************************************************/
  function GetCuitPorCuenta(p_idCuenta tblcuenta.idcuenta%Type)
    return entidades.cdcuit%type is
    v_Result entidades.cdcuit%type;

  begin
    select e.cdcuit
      into v_Result
      from entidades e, tblcuenta d
     where e.identidad = d.identidad
       and d.idcuenta = p_idCuenta
       and rownum = 1;

    return(v_Result);

  exception
    when others then
      return null;
  end GetCuitPorCuenta;

  /****************************************************************************************
  * 27/09/2013
  * MarianoL
  * Obtiene datos de direccion de la entidad, si no encuentra una direccion comercial opta por una particular.
  *****************************************************************************************/
  Procedure GetDireccion(p_idEntidad In ENTIDADES.IDENTIDAD%Type,
                         o_cdtipdir  Out DIRECCIONESENTIDADES.CDTIPODIRECCION%Type,
                         o_sqdir     Out DIRECCIONESENTIDADES.SQDIRECCION%Type) Is
    v_Modulo Varchar2(100) := 'PKG_CLIENTE.GetDireccion';
  Begin
    Begin
      Select CDTIPODIRECCION, SQDIRECCION
        Into o_cdtipdir, o_sqdir
        From direccionesentidades de
       Where de.identidad = p_idEntidad
         And de.cdtipodireccion = c_dircomercial --Dirección Comercial
         And de.sqdireccion =
             (Select Max(ddee.sqdireccion)
                From direccionesentidades ddee
               Where ddee.identidad = de.identidad
                 And ddee.cdtipodireccion = de.cdtipodireccion
                 And ddee.icactiva = 1);
    Exception
      When Others Then
        o_cdtipdir := Null;
    End;
    If Trim(o_cdtipdir) Is Null Then
      Select CDTIPODIRECCION, SQDIRECCION
        Into o_cdtipdir, o_sqdir
        From direccionesentidades de
       Where de.identidad = p_idEntidad
         And de.cdtipodireccion = c_dirparticular --Dirección Particular
         And de.sqdireccion =
             (Select Max(ddee.sqdireccion)
                From direccionesentidades ddee
               Where ddee.identidad = de.identidad
                 And ddee.cdtipodireccion = de.cdtipodireccion
                 And ddee.icactiva = 1);
    End If;
    Return;
  Exception
    When Others Then
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_Modulo ||
                                       '  Error: ' || Sqlerrm);
      o_cdtipdir := Null;
      o_sqdir    := 0;
  End GetDireccion;

  /****************************************************************************************
  * Retorna cual es el maximo de efectivo que puede pagar un cliente mirando la provincia de la direccion comercial activa
  * Tiene prioridad la provincia a al que pertenece la sucursal
  * %v 04/09/2014 - JBodnar
  *****************************************************************************************/
  Procedure GetControlaEfectivo(p_idEntidad In ENTIDADES.IDENTIDAD%Type,
                                p_Maximo    Out Limite_Condvta.Maximo%Type) Is
    v_Modulo         Varchar2(100) := 'PKG_CLIENTE.GetControlaEfectivo';
    v_MaximoSucursal Number;
    v_MaximoCliente  Number;
  Begin
    --Busco el maximo segun la provincia de la sucursal
    Begin
      Select maximo
        Into v_MaximoSucursal
        From limite_condvta lc
       Where lc.cdprovincia =
             (Select su.cdprovincia
                From sucursales su
               Where su.cdsucursal = c_Sucursal);
    Exception
      When Others Then
        v_MaximoSucursal := 0;
    End;

    --Busco el maximo segun la provincia del cliente
    Begin
      Select maximo
        Into v_MaximoCliente
        From limite_condvta lc
       Where lc.cdprovincia In
             (Select cdprovincia
                From direccionesentidades de
               Where identidad = p_idEntidad
                 And CDTIPODIRECCION = 2 --Direcion comercial Activa
                 And SQDIRECCION = (Select Max(dee.sqdireccion)
                                      From direccionesentidades dee
                                     Where dee.identidad = de.identidad
                                       And dee.cdtipodireccion = 2
                                       And dee.icactiva = 1)); --Direcion comercial Activa
    Exception
      When Others Then
        v_MaximoCliente := 0;
    End;

    --Si la sucursal tiene maximo retorno el valor
    If v_MaximoSucursal > 0 Then
      p_Maximo := v_MaximoSucursal;
    Else
      --Si la sucursal no tiene maximo miro el del cliente
      If v_MaximoCliente > 0 Then
        p_Maximo := v_MaximoCliente;
      Else
        p_Maximo := 0;
      End If;
    End If;
  Exception
    When Others Then
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_Modulo ||
                                       '  Error: ' || Sqlerrm);
  End GetControlaEfectivo;

  /****************************************************************************************
  * 13/03/2014
  * MarianoL
  * Verifica si la dirección del clientes está OK para facturar
  * Devuelve 1=OK ó 0=Error
  *****************************************************************************************/
  Function DireccionOK(p_idEntidad ENTIDADES.IDENTIDAD%Type) Return Number Is
    v_Modulo      Varchar2(100) := 'PKG_CLIENTE.DireccionOK';
    v_cdtipdir    direccionesentidades.cdtipodireccion%Type;
    v_sqdir       direccionesentidades.sqdireccion%Type;
    v_cdcodpostal direccionesentidades.cdcodigopostal%Type;
  Begin
    GetDireccion(p_idEntidad, v_cdtipdir, v_sqdir);
    If v_cdtipdir Is Not Null And v_sqdir Is Not Null Then
      Select de.cdcodigopostal
        Into v_cdcodpostal
        From direccionesentidades de
       Where de.identidad = p_idEntidad
         And de.cdtipodireccion = v_cdtipdir
         And de.sqdireccion = v_sqdir;
    End If;
    If v_cdtipdir Is Not Null And v_sqdir Is Not Null And
       v_cdcodpostal Is Not Null Then
      Return 1;
    Else
      Return 0;
    End If;
  Exception
    When Others Then
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_Modulo ||
                                       '  Error: ' || Sqlerrm);
      Raise;
  End DireccionOK;

  /****************************************************************************************
  * 27/09/2013
  * MarianoL
  * Obtiene los datos básicos del cliente
  *****************************************************************************************/
  Procedure GetDataEntidad(p_idEntidad In ENTIDADES.IDENTIDAD%Type,
                           o_cdsitiva  Out SITUACIONESIVA.CDSITUACIONIVA%Type,
                           o_cdtipdir  Out DIRECCIONESENTIDADES.CDTIPODIRECCION%Type,
                           o_sqdir     Out DIRECCIONESENTIDADES.SQDIRECCION%Type) Is
    v_Modulo          Varchar2(100) := 'PKG_CLIENTE.GetDataEntidad';
    v_NumeraImpFiscal Varchar2(5) := nvl(GetVlParametro('MdlFiscal',
                                                        'General'),
                                         0);
  Begin
    Select nvl(cdsituacioniva, c_responsableinscripto)
      Into o_cdsitiva
      From INFOIMPUESTOSENTIDADES
     Where identidad = p_idEntidad;
    If v_NumeraImpFiscal = '1' And
       Trim(p_idEntidad) = GetVlparametro('CdConsFinal', 'General') Then
      o_cdsitiva := c_SITIVA_CF;
    End If;
    GetDireccion(p_idEntidad, o_cdtipdir, o_sqdir);
    Return;
  Exception
    When Others Then
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_Modulo ||
                                       '  Error: ' || Sqlerrm);
      Raise;
  End GetDataEntidad;

  /****************************************************************************************
  * 27/09/2013
  * MarianoL
  * Obtiene el cuit de la referencia de un CF fidelizado
  *****************************************************************************************/
  Function GetCuitCF(p_ref Varchar2, p_chr1 Varchar2, p_chr2 Varchar2)
    Return ENTIDADES.CDCUIT%Type Is
    XCUIT    ENTIDADES.CDCUIT%Type;
    pos1     Integer;
    pos2     Integer;
    v_Modulo Varchar2(100) := 'PKG_CLIENTE.GetCuitCF';
  Begin
    pos1  := instr(p_ref, Trim(p_chr1));
    pos2  := instr(p_ref, Trim(p_chr2));
    XCUIT := Null;
    If pos1 > 0 And pos2 > 0 And pos1 < pos2 Then
      XCUIT := substr(p_ref, pos1 + 1, pos2 - pos1 - 1);
    End If;
    Return XCUIT;
  Exception
    When Others Then
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_Modulo ||
                                       '  Error: ' || Sqlerrm);
      Raise;
  End GetCuitCF;

  /****************************************************************************************
  * 27/09/2013
  * MarianoL
  * Dada un DSREFERENCIA obtiene el legajo del empleado
  *****************************************************************************************/
  Function GetLegajo(p_ref Varchar2) Return Varchar2 Is
    v_Legajo personas.cdlegajo%Type;
    v_Existe Integer;
    v_pos1   Integer;
    v_pos2   Integer;
    v_Modulo Varchar2(100) := 'PKG_CLIENTE.GetLegajo';
  Begin
    v_pos1 := instr(p_ref, Trim('['));
    v_pos2 := instr(p_ref, Trim(']'));
    If v_pos1 > 0 And v_pos2 > 0 And v_pos1 < v_pos2 Then
      v_Legajo := substr(p_ref, v_pos1 + 1, v_pos2 - v_pos1 - 1);
    End If;
    Select Count(*)
      Into v_Existe
      From personas p
     Where Trim(p.cdlegajo) = Trim(v_Legajo);
    If v_Existe = 0 Then
      v_Legajo := Null;
    End If;
    Return v_Legajo;
  Exception
    When Others Then
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_Modulo ||
                                       '  Error: ' || Sqlerrm);
      Raise;
  End GetLegajo;

  /****************************************************************************************
  * 27/09/2013
  * MarianoL
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
         AND i.cdsituacioniva = '48      ';
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
    v_Result Integer;
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
  * 27/09/2013
  * MarianoL
  * Devuelve la entidad alternativa del pedido.
  * Si el pedido es con cuenta devuelve el idEntidad del pedido, si es CF busca el IdEntidad
  * que corresponde al CUIT que está en dsreferencia.
  *****************************************************************************************/
  Function GetEntidadAlter(p_idEntidad    ENTIDADES.IDENTIDAD%Type,
                           p_dsReferencia PEDIDOS.DSREFERENCIA%Type)
    Return ENTIDADES.Identidad%Type Is
    v_idEntidadAlter ENTIDADES.IDENTIDAD%Type := Null;
    v_cdCuit         ENTIDADES.CDCUIT%Type;
    v_Modulo         Varchar2(100) := 'PKG_CLIENTE.GetEntidadAlter';
  Begin
    --Busco el Cuit del cliente
    If EsConsumidorFinal(p_identidad) = 1 Then
      --Es CF, busco el cuit en la referencia entre paréntesis
      v_cdCuit := GetCuitCF(p_dsreferencia, '(', ')');
      If v_cdCuit Is Null Then
        -- Si no lo encuentro lo busco en la referencia entre corchetes
        v_cdCuit := GetCuitCF(p_dsreferencia, '[', ']');
      End If;
      --Busco la entidad alternativa (es distinta cuando el Cuit está en la referencia)
      v_idEntidadAlter := GetIdEntidad(v_cdCuit);
    Else
      --No es CF
      v_idEntidadAlter := p_identidad;
    End If;
    Return v_idEntidadAlter;
  Exception
    When Others Then
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_Modulo ||
                                       '  Error: ' || Sqlerrm);
      Raise;
  End GetEntidadAlter;

  /**************************************************************************************************
  * 19/12/2013
  * MarianoL
  * Dado un idEntidad devuelve 1 si está habilitada para vender bebidas alcoholicas, sino devuelve 0
  * %v 25/04/2016 APW - Agrego control para clientes que son consumidor final (andaba solo para anónimos)
  ***************************************************************************************************/
  Function GetHabilitBebidaAlcoholica(p_idEntidad In tblcu_cabecera.identidad%Type)
    Return Integer Is
    v_modulo      Varchar2(100) := 'PKG_CLIENTE.GetHabilitBebidaAlcoholica';
    v_Result      Integer := 0;
    v_TipoDir     DireccionesEntidades.CdTipoDireccion%Type := SUBSTR(N_PKG_VITALPOS_CORE.Getvlparametro('CdDirComercial',
                                                                                                         'Creditos'),
                                                                      1,
                                                                      8);
    v_cd13178     Entidades.Cd13178%Type;
    v_dt13178     Entidades.dt13178%Type;
    v_cdProvincia DireccionesEntidades.CdProvincia%Type;
    v_cdLocalidad DireccionesEntidades.CdLocalidad%Type;
  Begin

    if EsConsumidorFinal(p_identidad) = 1 then
      return 1;
    end if;

    Select d.cdprovincia, d.cdlocalidad, e.cd13178, e.dt13178
      Into v_cdProvincia, v_cdLocalidad, v_cd13178, v_dt13178
      From DireccionesEntidades d, Entidades e
     Where d.identidad = e.identidad
       And d.cdtipodireccion = v_TipoDir
       And e.identidad = p_idEntidad
       And d.icactiva = 1
       And d.sqdireccion =
           (Select Max(sqdireccion)
              From DireccionesEntidades d2
             Where d2.identidad = p_idEntidad
               And d2.cdtipodireccion = v_TipoDir);
    If (v_cdProvincia <> 1 And v_cdProvincia <> 14) Or
       (v_cdProvincia = 14 And v_cdLocalidad <> 12331) Or
       (v_cd13178 Is Not Null And
       trunc(v_dt13178) >= trunc(N_PKG_VITALPOS_CORE.GetDT())) Then
      v_Result := 1;
    End If;
    Return v_Result;
  Exception
    When Others Then
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       '  Error: ' || Sqlerrm);
      Raise;
  End GetHabilitBebidaAlcoholica;

  /****************************************************************************************
  * 26/03/2014
  * Paola Toledo
  * Devuelve una entidad a partir de un string de referencia (documento.dsreferencia)
  * %v 10/10/2018 - APW: sale sin hacer nada si la referencia es null
  *****************************************************************************************/
  Procedure GetEntidadRef(p_ref     In tblcu_cabecera.dsreferencia%Type,
                          p_entidad Out tblcu_cabecera.identidad%Type) Is
    v_Modulo Varchar2(100) := 'PKG_CLIENTE.GetEntidadRef';
    v_cuit   entidades.cdcuit%Type;
  Begin
    p_entidad := Null;
    if p_ref is null then
      return;
    end if;

    If instr(p_ref, '(') = 0 Then
      return;
    end if;

    Select substr(p_ref, instr(p_ref, '(') + 1, 13) Into v_cuit From dual;
    Select e.identidad
      Into p_entidad
      From entidades e
     Where e.cdcuit = v_cuit;

    Return;
  Exception
    When Others Then
      n_pkg_vitalpos_log_general.write(2,'Modulo: ' || v_Modulo ||'  Error: ' || Sqlerrm);
      Raise;
  End GetEntidadRef;

  /****************************************************************************************
  * 26/03/2014
  * Paola Toledo
  * Devuelve si un cliente debe ser excluido o no del recargo de IVA por CF
  * (1=excluido 0=no excluido)
  *****************************************************************************************/
  Procedure GetClienteExclud(p_idEntidad In ENTIDADES.IDENTIDAD%Type,
                             p_excluido  Out Number) Is
    v_Modulo Varchar2(100) := 'PKG_CLIENTE.GetClienteExclud';
  Begin
    Select Count(1)
      Into p_excluido
      From CLTESFIDELEXCLUD exc
     Where exc.identidad = p_idEntidad;
    Return;
  Exception
    When Others Then
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_Modulo ||
                                       '  Error: ' || Sqlerrm);
      Raise;
  End GetClienteExclud;

  /****************************************************************************************
  * 26/03/2014
  * JBodnar
  * Proceso de alta de un cliente donde se validan los datos cargados y ademas se crea la Cuenta
  * y el usuario del cliente para que pueda operar con Cuenta y con Usuario/Pin
  * 17/08/2018 - Jbodnar: Validacion de cuit
  * 29/08/2018: JB se comenta la validacion del cuit
  *****************************************************************************************/
  Procedure AltaDeCliente(p_CdSucursal     In entidades.cdmainsucursal%Type,
                          p_RubroPrincipal In entidades.cdrubroprincipal%Type,
                          p_RazonSocial    In entidades.dsrazonsocial%Type,
                          p_NombreFantasia In entidades.dsnombrefantasia%Type,
                          p_CdCuit         In entidades.cdcuit%Type,
                          p_IdPersonaAlta  In entidades.idpersonaalta%Type,
                          p_Dt13178        In entidades.dt13178%Type,
                          p_Cd13178        In entidades.cd13178%Type,
                          p_CdSituacionIva In infoimpuestosentidades.cdsituacioniva%Type,
                          p_Convenio       In infoimpuestosentidades.icconvenio%Type,
                          p_IcMunicipal    In infoimpuestosentidades.icmunicipal%Type,
                          p_IngresosBrutos In infoimpuestosentidades.cdingresosbrutos%Type,
                          p_NombreCuenta   In tblcuenta.nombrecuenta%type,
                          --Parametros de retorno
                          p_Identidad Out entidades.identidad%Type,
                          p_IdCuenta  Out tblcuenta.idcuenta%Type,
                          p_ok        Out Integer,
                          p_error     Out Varchar2) Is
    v_Modulo      Varchar2(100) := 'PKG_CLIENTE.AltaDeCliente';
    v_dtOperativa Date := N_PKG_VITALPOS_CORE.GetDT();
    v_IdEntidad   entidades.identidad%Type;
    --v_cuitout     entidades.cdcuit%Type;
    v_Cliente  Varchar2(100); --Cliente de bebida alcoholica duplicado
    v_Rol      rolesentidades.cdrol%Type := N_PKG_VITALPOS_CORE.GetVlParametro('CdRolCliente',
                                                                               'General'); --Busco el rol de los parametros del sistema
    v_IdCuenta tblcuenta.idcuenta%Type;
  Begin
    --Asigno un ID al nuevo cliente
    v_IdEntidad := SYS_GUID();

    /*    --Valida el cuit
    v_cuitout:= Validacuit(replace(p_CdCuit,'-',''));
    --Si es diferencite el retorno pincha
    if trim(v_cuitout) <> (replace(p_CdCuit,'-','')) then
      p_ok    := 0;
      p_error := 'El cuit '||p_CdCuit||' no se pudo validar correctamente.';
      Return;
    end if;*/

    --Consulto si ya existe el cuit asociado a un cliente
    If ExisteEntidad(p_CdCuit, v_IdEntidad) = 1 Then
      p_ok    := 0;
      p_error := 'El cuit ya existe asignado a un cliente.';
      Return;
    End If;
    --Validacion de codigo de bebidas alcoholicas
    If HabilitacionOK(v_IdEntidad, v_Cliente, p_Cd13178) = 1 Then
      p_ok    := 0;
      p_error := 'La habilitacion de bebidas esta asiganda a otro cliente: ' ||
                 v_Cliente;
      Return;
    End If;
    --Si pasan todas las validaciones inserto en la tabla de clientes
    Insert Into entidades
      (identidad,
       cdmainsucursal,
       cdrubroprincipal,
       dsrazonsocial,
       dsnombrefantasia,
       cdcuit,
       cdestadooperativo,
       idpersonaalta,
       dtalta,
       idpersonamodif,
       dtmodif,
       dt13178,
       cd13178,
       cdforma,
       cdtraba,
       vlrecargo,
       vldiasdeuda)
    Values
      (v_IdEntidad,
       p_CdSucursal,
       p_RubroPrincipal,
       UPPER(p_RazonSocial),
       UPPER(p_NombreFantasia),
       p_CdCuit,
       'A',
       p_IdPersonaAlta,
       v_dtOperativa,
       '',
       '',
       p_Dt13178,
       p_Cd13178,
       Null,
       1,
       Null,
       Null);
    --Doy de alta la Cuenta
    PKG_CUENTA.GrabarCuenta(v_IdEntidad,
                            p_CdCuit,
                            c_Sucursal,
                            'Cuenta Inicial',
                            v_IdCuenta,
                            p_ok,
                            p_error);

    If p_ok = 0 Then
      Return; --Error al crear la cuenta
    End If;
    --Inserto la situacion impositiva del cliente
    Insert Into infoimpuestosentidades
      (identidad,
       cdsituacioniva,
       icconvenio,
       cdingresosbrutos,
       icresol177,
       icmunicipal,
       cdsituacionib)
    Values
      (v_IdEntidad,
       p_CdSituacionIva,
       p_Convenio,
       p_IngresosBrutos,
       0,
       p_IcMunicipal,
       p_Convenio);

    --Graba la tabla de autitoria
    insert into tblauditoria
      (idauditoria,
       cdsucursal,
       idpersona,
       vlpuesto,
       idtabla,
       nmtabla,
       dtaccion,
       nmproceso)
    values
      (sys_guid(),
       c_Sucursal,
       p_IdPersonaAlta,
       NULL,
       v_IdEntidad,
       'INFOIMPUESTOSENTIDADES',
       sysdate,
       v_Modulo);

    --Asigno el rol general de cliente de los parametros del sistema
    Insert Into RolesEntidades
      (CDROL, IDENTIDAD)
    Values
      (v_Rol, v_IdEntidad);

    --Final OK de transaccion de alta
    --Confirmo el grabado de Entidades y Direccionesentidades
    Commit;
    p_ok    := 1;
    p_error := '';
    --Retorno el Identidad del nuevo cliente y la cuenta por defecto
    p_Identidad := v_IdEntidad;
    p_IdCuenta  := v_IdCuenta;
  Exception
    When Others Then
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_Modulo ||
                                       '  Error: ' || Sqlerrm);
      p_ok    := 0;
      p_error := '  Error: ' || Sqlerrm;
      Rollback; --Vuelvo atras la operacion de alta
      Raise;
  End AltaDeCliente;

  /**************************************************************************************************
  * %v 29/03/2017 - IAquilano
  * Funcion que quita caracteres no imprimibles de una cadena de texto
  * Solo para 11g
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
  * Graba todos los datos de una direccion para un cliente
  * %v 11/04/2014 - JBodnar
  * %v 03/02/2017 - IAquilano - Chequea que exista el parametro de cdpostal para esa pcia.
  *****************************************************************************************/
  Procedure GrabarDomicilio(p_Identidad     In entidades.identidad%Type,
                            p_IdPersonaAlta In entidades.idpersonaalta%Type,
                            p_CdTipoDirec   In tipodirecciones.cdtipodireccion%Type,
                            p_CdPais        In paises.cdpais%Type,
                            p_CdProvincia   In provincias.cdprovincia%Type,
                            p_CdLocalidad   In localidades.cdlocalidad%Type,
                            p_CdPostal      In codigospostales.cdcodigopostal%Type,
                            p_Calle         In direccionesentidades.dscalle%Type,
                            p_Numero        In direccionesentidades.dsnumero%Type,
                            p_Piso          In direccionesentidades.dspisonumero%Type,
                            p_icActiva      In direccionesentidades.icactiva%type,
                            p_IdCuenta      In tblcuenta.idcuenta%Type,
                            p_ok            Out Integer,
                            p_error         Out Varchar2) Is
    v_Modulo      Varchar2(100) := 'PKG_CLIENTE.GrabarDomicilio';
    v_SqDireccion direccionesentidades.sqdireccion%Type;
    v_cant        number;
  Begin
    --Busco la ultima secuencia de la direccion
    Begin
      Select Max(d.sqdireccion) + 1
        Into v_SqDireccion
        From direccionesentidades d
       Where d.identidad = p_Identidad;
    Exception
      When no_data_found Then
        v_SqDireccion := 1; --Si no existe le asingo la primer direccion
    End;
    --No puede ser null el sq
    if v_SqDireccion is null then
      v_SqDireccion := 1; --Si no existe le asingo la primer direccion
    end if;

    select count(*)
      into v_cant
      from codigospostales
     where cdprovincia = p_cdprovincia
       and cdcodigopostal = p_cdpostal;

    if v_cant = 0 then
      p_error := 'El codigo postal no es valido para la provincia seleccionada';
      p_ok    := 0;
      return;
    End if;

    --Grabo en la tabla de direcciones
    Insert Into direccionesentidades
      (identidad,
       cdtipodireccion,
       sqdireccion,
       idpersona,
       cdpais,
       cdprovincia,
       cdlocalidad,
       cdcodigopostal,
       dscalle,
       dsnumero,
       dspisonumero,
       icactiva)
    Values
      (p_Identidad,
       p_CdTipoDirec,
       v_SqDireccion,
       p_IdPersonaAlta,
       p_CdPais,
       p_CdProvincia,
       p_CdLocalidad,
       p_CdPostal,
       p_Calle,
       p_Numero,
       p_Piso,
       p_icActiva);

    --Desactiva los domicilios comerciales anteriores
    --Solo tiene que tener un domicilio comercial activo
    if p_CdTipoDirec = c_DirComercial then
      update direccionesentidades
         set icactiva = 0
       where identidad = p_Identidad
         and cdtipodireccion = c_DirComercial
         and sqdireccion <> v_SqDireccion; --Actualiza todos en inactivos menos el actual que esta cargando
    end if;

    --Si no es direccion comercial guardo en la tabla de configuracion de cuenta/direcciones
    --Si es comercial y es la primera la inserto y la referencia en el caso de los pedidos
    if p_CdTipoDirec <> c_DirComercial or
       (v_SqDireccion = 1 and p_CdTipoDirec = c_DirComercial) then
      --Grabo en la tabla de direcciones de cuentas
      Insert Into tbldireccioncuenta
        (iddireccioncuenta,
         idcuenta,
         identidad,
         cdtipodireccion,
         sqdireccion,
         cdsucursal)
      Values
        (sys_guid(),
         p_IdCuenta,
         p_Identidad,
         p_CdTipoDirec,
         v_SqDireccion,
         c_Sucursal);
    end if;

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
  End GrabarDomicilio;

  /****************************************************************************************
  * Valida codigo postal para localidad de CABA
  * %v 06/02/2017 - IAquilano
  *****************************************************************************************/

  Procedure ValidaCPCaba(p_provincia    In provincias.cdprovincia%type,
                         p_localidad    In localidades.cdlocalidad%type,
                         p_codigopostal In Codigospostales.Cdcodigopostal%type,
                         p_ok           Out Integer,
                         p_error        Out Varchar2) IS
    v_Modulo Varchar2(100) := 'PKG_CLIENTE.ValidaCPCaba';
    v_cant   Number;

  Begin
    p_ok    := 1;
    p_error := '';

    select count(*)
      into v_cant
      from codigospostales
     where cdprovincia = p_provincia
       and cdlocalidad = p_localidad
       and cdcodigopostal = p_codigopostal;

    if v_cant = 0 then
      p_error := 'El codigo postal no es valido para la provincia seleccionada';
      p_ok    := 0;
      return;
    End if;

  Exception
    When Others Then
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_Modulo ||
                                       '  Error: ' || Sqlerrm);
      p_ok    := 0;
      p_error := '  Error: ' || Sqlerrm;
      Raise;

  End ValidaCPCaba;

  /****************************************************************************************
  * Actualiza el domicilio de un cliente
  * %v 11/04/2014 - JBodnar
  *****************************************************************************************/
  Procedure ActualizarDomicilio(p_SqDireccion    In direccionesentidades.sqdireccion%Type,
                                p_CdTipoDirec    In direccionesentidades.cdtipodireccion%type,
                                p_Identidad      In direccionesentidades.identidad%Type,
                                p_IdPersonaModif In entidades.idpersonamodif%Type,
                                p_icActiva       In direccionesentidades.icactiva%type,
                                p_ok             Out Integer,
                                p_error          Out Varchar2) As
    v_Modulo      Varchar2(100) := 'PKG_CLIENTE.ActualizarDomicilio';
    v_dtOperativa Date := N_PKG_VITALPOS_CORE.GetDT();
  Begin
    --Actualizo la direccion del cliente
    Update direccionesentidades
       Set icactiva = p_icActiva
     Where identidad = p_Identidad
       And cdtipodireccion = p_CdTipoDirec
       And sqdireccion = p_SqDireccion;
    --Actualizo los datos de la modificacion en la tabla entidades
    Update entidades e
       Set e.idpersonamodif = p_IdPersonaModif, e.dtmodif = v_dtOperativa
     Where e.identidad = p_Identidad;
    --Update OK
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
  End ActualizarDomicilio;

  /****************************************************************************************
  * 11/04/2014
  * JBodnar
  * Borro los datos del domicilio de un cliente
  *****************************************************************************************/
  Procedure BorrarDomicilio(p_Identidad      In entidades.identidad%Type,
                            p_SqDireccion    In direccionesentidades.sqdireccion%Type,
                            p_TipoDireccion  In direccionesentidades.cdtipodireccion%Type,
                            p_IdPersonaModif In entidades.idpersonamodif%Type,
                            p_ok             Out Integer,
                            p_error          Out Varchar2) As
    v_Modulo      Varchar2(100) := 'PKG_CLIENTE.BorrarDomicilio';
    v_Borrar      Integer;
    v_dtOperativa Date := N_PKG_VITALPOS_CORE.GetDT();
  Begin
    --Valido si existen facturas asociadas al domicilio que se quiere borrar
    Begin
      Select 0
        Into v_Borrar
        From movmateriales
       Where identidad = p_Identidad
         And cdtipodireccion = p_TipoDireccion
         And sqdireccion = p_SqDireccion
         And rownum = 1;
    Exception
      When no_data_found Then
        v_Borrar := 1; --Si no existe pongo un 1 y permito el borrado
    End;
    --Si tiene facturas asociandas al domicilio no puedo borrar
    If v_Borrar = 0 Then
      p_ok    := 0;
      p_error := 'No se puede borrar porque hay facturas asociadas al domicilio.';
      Return;
    Else
      --Borro la direccion del cliente
      Delete From direccionesentidades d
       Where d.identidad = p_Identidad
         And d.sqdireccion = p_SqDireccion
         And d.cdtipodireccion = p_TipoDireccion;
      --Actualizo la persona que lo modifico en la tabla entidades
      Update entidades e
         Set e.idpersonamodif = p_IdPersonaModif, e.dtmodif = v_dtOperativa
       Where e.identidad = p_Identidad;
    End If;
    --Borrado OK
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
  End BorrarDomicilio;

  /****************************************************************************************
  * 08/04/2014
  * JBodnar
  * Inserta en la base los contactos del cliente(telefonos, emails, etc)
  * %v 29/03/2017 IAquilano - Agrego control de caracteres no Imprimibles
  *****************************************************************************************/
  PROCEDURE GrabarContacto(p_Identidad         IN entidades.identidad%TYPE,
                           p_CdFormadeContacto IN contactosentidades.cdformadecontacto%TYPE,
                           p_IdPersona         IN contactosentidades.idpersona%TYPE,
                           p_DsFormadeContacto IN contactosentidades.dscontactoentidad%TYPE,
                           p_ok                OUT INTEGER,
                           p_error             OUT VARCHAR2) AS
    v_Modulo     VARCHAR2(100) := 'PKG_CLIENTE.GrabarContacto';
    v_SqContacto contactosentidades.sqcontactoentidad%TYPE;
    v_contacto   contactosentidades.dscontactoentidad%TYPE;
  BEGIN
    --Busco la ultima direccion. Si no tiene asigno 1 a la secuencia
    BEGIN
      SELECT nvl(MAX(c.sqcontactoentidad), 0) + 1
        INTO v_SqContacto
        FROM contactosentidades c
       WHERE c.identidad = p_Identidad;
    EXCEPTION
      WHEN no_data_found THEN
        v_SqContacto := 1;
    END;
    --Inserta en la base los contactos del cliente(telefonos, emails, etc)
    v_contacto := LimpiarContacto(p_DsFormadeContacto); --limpio el campo de caracteres no imprimibles
    INSERT INTO contactosentidades
      (identidad,
       cdformadecontacto,
       sqcontactoentidad,
       idpersona,
       dscontactoentidad)
    VALUES
      (p_Identidad,
       p_CdFormadeContacto,
       nvl(v_SqContacto, 1),
       p_IdPersona,
       v_contacto);

    --Alta OK
    COMMIT;
    p_ok    := 1;
    p_error := '';
  EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_Modulo ||
                                       '  Error: ' || SQLERRM);
      p_ok    := 0;
      p_error := '  Error: ' || SQLERRM;
      RAISE;
  END GrabarContacto;

  /****************************************************************************************
  * 11/04/2014
  * JBodnar
  * Borra el contacto de un cliente
  *****************************************************************************************/
  Procedure BorrarContacto(p_Identidad         In entidades.identidad%Type,
                           p_CdContacto        In contactosentidades.cdformadecontacto%Type,
                           p_SqContactoEntidad In contactosentidades.sqcontactoentidad%Type,
                           p_IdPersonaModif    In entidades.idpersonamodif%Type,
                           p_ok                Out Integer,
                           p_error             Out Varchar2) As
    v_Modulo      Varchar2(100) := 'PKG_CLIENTE.BorrarContacto';
    v_dtOperativa Date := N_PKG_VITALPOS_CORE.GetDT();
  Begin
    --Borra el contacto de un cliente
    Delete From contactosentidades c
     Where c.identidad = p_Identidad
       And c.sqcontactoentidad = p_SqContactoEntidad
       And c.cdformadecontacto = p_CdContacto;
    --Actualizo la persona que lo modifico en la tabla entidades
    Update entidades e
       Set e.idpersonamodif = p_IdPersonaModif, e.dtmodif = v_dtOperativa
     Where e.identidad = p_Identidad;
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
  End BorrarContacto;

  /****************************************************************************************
  * 11/04/2014
  * JBodnar
  * Actualiza el contacto de un cliente
  * %v 05/08/2016 RCigana, se deshabilita modificación de cdformadecontacto y se
  *               incluye cdformadecontacto en where de update
  * %v 31/03/2017 IAquilano - Agrego comparacion de datos para ver si modifica o no
  * %v 29/03/2017 IAquilano - Agrego chequeo de caracteres no imprimibles
  *****************************************************************************************/
  Procedure ActualizarContacto(p_SqContactoEntidad In contactosentidades.sqcontactoentidad%Type,
                               p_Identidad         In entidades.identidad%Type,
                               p_CdFormadeContacto In contactosentidades.cdformadecontacto%Type,
                               p_IdPersonaModif    In entidades.idpersonamodif%Type,
                               p_DsFormadeContacto In contactosentidades.dscontactoentidad%Type,
                               p_ok                Out Integer,
                               p_error             Out Varchar2,
                               p_modificado        Out Integer) As
    v_Modulo            Varchar2(100) := 'PKG_CLIENTE.ActualizarContacto';
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
  * 11/04/2014
  * JBodnar
  * Recibe los datos del cliente y lo actualiza en la tabla Entidades
  * 29/08/2018: JB se comenta la validacion del cuit
  *****************************************************************************************/
  Procedure ActualizarCliente(p_IdEntidad       In entidades.identidad%Type,
                              p_CdSucursal      In entidades.cdmainsucursal%Type,
                              p_RubroPrincipal  In entidades.cdrubroprincipal%Type,
                              p_RazonSocial     In entidades.dsrazonsocial%Type,
                              p_NombreFantasia  In entidades.dsnombrefantasia%Type,
                              p_EstadoOperativo In entidades.cdestadooperativo%Type,
                              p_CdCuit          In entidades.cdcuit%Type,
                              p_IdPersonaModif  In entidades.idpersonamodif%Type,
                              p_Dt13178         In entidades.dt13178%Type,
                              p_Cd13178         In entidades.cd13178%Type,
                              p_CdSituacionIva  In infoimpuestosentidades.cdsituacioniva%Type,
                              p_Convenio        In infoimpuestosentidades.icconvenio%Type,
                              p_IcMunicipal     In infoimpuestosentidades.icmunicipal%Type,
                              p_IngresosBrutos  In infoimpuestosentidades.cdingresosbrutos%Type,
                              p_ok              Out Integer,
                              p_error           Out Varchar2) As
    v_Modulo  Varchar2(100) := 'PKG_CLIENTE.UpdateDeCliente';
    v_Cliente Varchar2(100); --Cliente de bebida alcoholica duplicado
    --v_cuitout     entidades.cdcuit%Type;
    v_dtOperativa Date := N_PKG_VITALPOS_CORE.GetDT();
  Begin

    /*    --Valida el cuit
        v_cuitout:= Validacuit(replace(p_CdCuit,'-',''));
        --Si es diferencite el retorno pincha
        if trim(v_cuitout) <> (replace(p_CdCuit,'-','')) then
          p_ok    := 0;
          p_error := 'El cuit '||p_CdCuit||' no se pudo validar correctamente.';
          Return;
        end if;
    */
    --Consulto si ya existe el cuit asociado a un cliente
    If ExisteEntidad(p_CdCuit, p_Identidad) = 1 Then
      p_ok    := 0;
      p_error := 'El cuit ya existe asignado a un cliente.';
      Return;
    End If;
    --Validacion de codigo de bebidas alcoholicas
    If HabilitacionOK(p_Identidad, v_Cliente, p_Cd13178) = 1 Then
      p_ok    := 0;
      p_error := 'La habilitacion de bebidas esta asiganda a otro cliente: ' ||
                 v_Cliente;
      Return;
    End If;
    --Actualizo los datos recibidos en la tabla Entidades
    Update entidades
       Set cdmainsucursal    = p_CdSucursal,
           cdrubroprincipal  = p_RubroPrincipal,
           dsrazonsocial     = p_RazonSocial,
           dsnombrefantasia  = p_NombreFantasia,
           cdestadooperativo = decode(p_EstadoOperativo,
                                      Null,
                                      cdestadooperativo,
                                      p_EstadoOperativo),
           idpersonamodif    = p_IdPersonaModif,
           dtmodif           = v_dtOperativa,
           dt13178           = p_dt13178,
           cd13178           = p_cd13178
     Where identidad = p_Identidad;
    --Actualizo informacion impositiva
    ActualizaInfoImpuestos(p_Identidad,
                           p_CdSituacionIva,
                           p_Convenio,
                           p_IcMunicipal,
                           p_IngresosBrutos,
                           p_ok,
                           p_error);

    --Graba la tabla de autitoria
    insert into tblauditoria
      (idauditoria,
       cdsucursal,
       idpersona,
       vlpuesto,
       idtabla,
       nmtabla,
       dtaccion,
       nmproceso)
    values
      (sys_guid(),
       c_Sucursal,
       p_IdPersonaModif,
       NULL,
       p_IdEntidad,
       'INFOIMPUESTOSENTIDADES',
       sysdate,
       v_Modulo);

    If p_ok = 0 Then
      Return; --Error al actualizar informacion impositiva
    End If;
    --Confirmo y retorno Ok
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
  End ActualizarCliente;

  /****************************************************************************************
  * Actualizo los datos impositivos para un cliente
  * v% 02/05/2016 - JBodnar: actualiza el nuevo campo cdsituacionib
  * %v 04/12/2019 - APW: grego provincia de Rio Negro para convenio 4
  * %v 19/12/2019 - ChM:
  *****************************************************************************************/
  Procedure ActualizaInfoImpuestos(p_Identidad      In entidades.identidad%Type,
                                   p_CdSituacionIva In infoimpuestosentidades.cdsituacioniva%Type,
                                   p_Convenio       In infoimpuestosentidades.icconvenio%Type,
                                   p_IcMunicipal    In infoimpuestosentidades.icmunicipal%Type,
                                   p_IngresosBrutos In infoimpuestosentidades.cdingresosbrutos%Type,
                                   p_ok             Out Integer,
                                   p_error          Out Varchar2) Is
    v_Modulo    Varchar2(100) := 'PKG_CLIENTE.ActualizaInfoImpuestos';
    v_Provincia direccionesentidades.cdprovincia%type;
  Begin
    --Buscar la localidad comercial activa
    select di.cdprovincia
      into v_Provincia
      from direccionesentidades di
     where di.identidad = p_Identidad
       and di.cdtipodireccion = c_DirComercial
       and di.icactiva = 1;

    --Si es Simplificado pero no es de CABA o Rio Negro sale por error
    If p_Convenio = 4 and v_Provincia not in ('2','16') Then
      p_ok    := 0;
      p_error := 'No se puede grabar la situacion Simplificado porque no corresponde a la provincia del cliente. Comuniquese con el Dto. de Impuestos.';
      Return;
    End If;
    --Si es padrón general pero no es de CABA sale por error
     If p_Convenio = 6 and v_Provincia not in ('2') Then
      p_ok    := 0;
      p_error := 'No se puede grabar la situacion Padrón General CABA porque no corresponde a la provincia del cliente. Comuniquese con el Dto. de Impuestos.';
      Return;
    End If;
    --Actualizo los datos impositivos para un cliente
    Update infoimpuestosentidades
       Set cdsituacioniva   = p_CdSituacionIva,
           cdsituacionib    = to_char(p_Convenio),
           cdingresosbrutos = p_IngresosBrutos,
           icconvenio       = decode(p_Convenio,
                                     1,
                                     1,
                                     2,
                                     2,
                                     3,
                                     3,
                                     icconvenio),
           icmunicipal      = p_IcMunicipal,
           icresol177       = decode(p_Convenio, 4, 1, 0) --Si la situacionib es 4 es simplificado
     Where identidad = p_Identidad;
    --Retorno Ok
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
  End ActualizaInfoImpuestos;

  /****************************************************************************************
  * 27/03/2014
  * JBodnar
  * Valido el formato del cuit antes de darlo de alta o actualizar los datos del cliente
  *****************************************************************************************/
  Procedure ValidaSintaxisCuit(p_CdCuit           In entidades.cdcuit%Type,
                               p_CdCuitFormateado Out entidades.cdcuit%Type,
                               p_ok               Out Integer,
                               p_error            Out Varchar2) Is
    v_Modulo  Varchar2(100) := 'PKG_CLIENTE.ValidaSintaxisCuit';
    v_cuit    entidades.cdcuit%Type;
    v_numeros Integer;
  Begin
    --Seteo el inicio en OK y si hay algun error lo cambio en el proceso
    p_ok    := 1;
    p_error := '';
    --Valido si no tiene guiones el cuit y se lo agrego
    If instr(p_CdCuit, '-') = 0 Then
      v_cuit             := substr(p_CdCuit, 0, 2) || '-' ||
                            substr(p_CdCuit, 3, 8) || '-' ||
                            substr(p_CdCuit, 11, 1);
      p_CdCuitFormateado := v_cuit;
    Else
      p_CdCuitFormateado := p_CdCuit;
    End If;
    --Guardo la cantidad de numeros del cuit
    v_numeros := length(Trim(Replace(v_cuit, '-', '')));
    --El cuit debe tener 11 numeros
    If v_numeros <> 11 Then
      p_ok               := 0;
      p_error            := 'Formato de cuit incorrecto.';
      p_CdCuitFormateado := p_CdCuit;
      Return;
    End If;
  Exception
    When Others Then
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_Modulo ||
                                       '  Error: ' || Sqlerrm);
      p_ok               := 0;
      p_error            := '  Error: ' || Sqlerrm;
      p_CdCuitFormateado := p_CdCuit;
      Raise;
  End ValidaSintaxisCuit;
  /****************************************************************************************
  * %v 01/08/2017 - APW - Funcion para llamar en queries -- llama al procedure anterior
  *****************************************************************************************/
  FUNCTION ValidarSintaxisCuit(p_CdCuit In entidades.cdcuit%Type)
    RETURN entidades.cdcuit%Type IS
    v_Modulo Varchar2(100) := 'PKG_CLIENTE.ValidaSintaxisCuit';
    v_error  varchar2(200);
    v_ok     integer;
    v_cuitok entidades.cdcuit%type;
  BEGIN
    ValidaSintaxisCuit(p_cdcuit, v_cuitok, v_ok, v_error);
    if v_ok <> 1 then
      return null;
    end if;
    return v_cuitok;
  EXCEPTION
    When Others Then
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_Modulo ||
                                       '  Error: ' || Sqlerrm);
      return null;
  END ValidarSintaxisCuit;

  /****************************************************************************************
  * 11/04/2014
  * JBodnar
  * Valido si ya existe el cuit asigando a una entidad
  *****************************************************************************************/
  Function ExisteEntidad(p_cdcuit    ENTIDADES.CDCUIT%Type,
                         p_Identidad entidades.identidad%Type) Return Integer Is
    v_Existe Integer;
    v_Modulo Varchar2(100) := 'PKG_CLIENTE.ExisteEntidad';
  Begin
    Begin
      Select 1
        Into v_Existe
        From entidades e
       Where trim(e.cdcuit) = trim(p_cdcuit)
         And e.identidad <> p_Identidad;
    Exception
      When no_data_found Then
        v_Existe := 0;
    End;
    Return v_Existe;
  Exception
    When Others Then
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_Modulo ||
                                       '  Error: ' || Sqlerrm);
  End ExisteEntidad;

  /****************************************************************************************
  * 03/04/2014
  * JBodnar
  * Verifica si el estado del cliente es A(Activo) esta dado de baja en el estado B
  *****************************************************************************************/
  Procedure GetEstadoCliente(p_idEntidad In entidades.identidad%Type,
                             p_ok        Out Integer,
                             p_error     Out Varchar2) Is
    v_Modulo Varchar2(100) := 'PKG_CLIENTE.GetEstadoCliente';
    v_estado entidades.cdestadooperativo%Type;
  Begin
    --Consulto el estado operativo del cliente
    Select e.cdestadooperativo
      Into v_estado
      From entidades e
     Where e.identidad = p_idEntidad;
    --Si esta dado de baja devuelvo codigo de error 0
    If Trim(v_estado) = 'B' Then
      p_ok    := 0;
      p_error := 'El cliente esta dado de baja en el sistema.';
    Else
      p_ok    := 1;
      p_error := '';
    End If;
  Exception
    When Others Then
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_Modulo ||
                                       '  Error: ' || Sqlerrm);
      p_ok    := 0;
      p_error := '  Error: ' || Sqlerrm;
      Raise;
  End GetEstadoCliente;

  /****************************************************************************************
  * 03/04/2014
  * JBodnar
  * Recibe un cliente y retorna los datos en un cursor
  * 28/08/2018 - JBodnar: Nueva marca si el cliente es excluido
  *****************************************************************************************/
  Procedure GetDatosCliente(p_Identidad In entidades.identidad%Type,
                            cur_out     Out cursor_type) As
    v_Modulo Varchar2(100) := 'PKG_CLIENTE.GetDatosCliente';
  Begin
    --Cursor de datos generales del cliente
    Open cur_out For
      Select Trim(e.identidad) As Identidad,
             Trim(e.cdmainsucursal) As SucursalPrincipal,
             e.dsrazonsocial As RazonSocial,
             e.dsnombrefantasia As NombreFantasia,
             Trim(e.cdcuit) As Cuit,
             Trim(si.cdsituacioniva) As SituacionIVA, --Situacion IVA
             Trim(i.cdingresosbrutos) As NumeroIngresosBrutos,
             Trim(r.cdrubrocomercial) As Rubro,
             to_number(i.cdsituacionib) As Convenio, --Situacion IB
             i.icmunicipal As Municipal, --Situacion Municipal
             Trim(e.cd13178) As NumeroHabilitacion,
             e.dt13178 As FechaVencimiento,
             e.dtmodif As FechaModificacion,
             p.dsapellido || ' ' || p.dsnombre As PersonaModificacion,
             eo.dsestadooperativo,
             EsExcluido(p_Identidad) excluido
        From entidades              e,
             infoimpuestosentidades i,
             situacionesiva         si,
             rubroscomerciales      r,
             personas               p,
             estadosoperativos      eo
       Where e.identidad = i.identidad
         And e.idpersonamodif = p.idpersona(+)
         And r.cdrubrocomercial = e.cdrubroprincipal
         And i.cdsituacioniva = si.cdsituacioniva
         And eo.cdestadooperativo = e.cdestadooperativo
         And e.identidad = p_Identidad;
  Exception
    When Others Then
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_Modulo ||
                                       '  Error: ' || Sqlerrm);
      Raise;
  End GetDatosCliente;

  /****************************************************************************************
  * 24/04/2014
  * JBodnar
  * Asocia un rol a una entidad insertando en la tabla rolesentidades
  *****************************************************************************************/
  Procedure GrabarRolesCliente(p_IdEntidad rolesentidades.identidad%Type,
                               p_CdRol     roles.cdrol%Type,
                               p_IdPersona rolesentidades.idpersonaresponsable%Type,
                               p_ok        Out Integer,
                               p_error     Out Varchar2) As
    v_Modulo      Varchar2(100) := 'PKG_CLIENTE.GrabarRolesCliente';
    v_dtOperativa Date := N_PKG_VITALPOS_CORE.GetDT();
  Begin

    Begin
      --Insert de asociacion roles y entidades
      Insert Into rolesentidades
        (cdrol, identidad, idpersonaresponsable, dtmodificacion)
      Values
        (p_CdRol, p_IdEntidad, p_IdPersona, v_dtOperativa);
    Exception
      When dup_val_on_index Then
        p_ok    := 0;
        p_error := 'Error de clave duplicada. El rol ya esta asociado al cliente.';
        Return;
    End;
    --Insert OK
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
  End GrabarRolesCliente;

  /****************************************************************************************
  * 24/04/2014
  * JBodnar
  * Baja un rol a una entidad borrando en la tabla rolesentidades
  *****************************************************************************************/
  Procedure BorrarRolesCliente(p_IdEntidad rolesentidades.identidad%Type,
                               p_CdRol     roles.cdrol%Type,
                               p_ok        Out Integer,
                               p_error     Out Varchar2) As
    v_Modulo Varchar2(100) := 'PKG_CLIENTE.BorrarRolesCliente';
  Begin
    --Control del rol=Cliente
    if p_CdRol = '2       ' then
      p_ok    := 0;
      p_error := 'No se puede eliminar el rol tipo cliente.';
      Return;
    end if;

    --Borra un rol a una entidad
    Delete From rolesentidades r
     Where r.identidad = p_IdEntidad
       And r.cdrol = p_CdRol;
    --Insert OK
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
  End BorrarRolesCliente;

  /****************************************************************************************
  * 04/04/2014
  * JBodnar
  * Retorna un cursor con la descripcion de las sucursales disponibles
  *****************************************************************************************/
  Procedure GetSucursales(cur_out Out cursor_type) As
    v_Modulo Varchar2(100) := 'PKG_CLIENTE.GetSucursales';
  Begin
    --Cargo y retorno el cursor con la descripcion de las sucursales disponibles
    Open cur_out For
      Select cdsucursal As cdsucursal, dssucursal
        From sucursales
       Where servidor Is Not Null;
  Exception
    When Others Then
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_Modulo ||
                                       '  Error: ' || Sqlerrm);
      Raise;
  End GetSucursales;

  /****************************************************************************************
  * 12/05/2014
  * JBodnar
  * Retorna los datos del cliente fidelizado dado un codigo de barra
  *****************************************************************************************/
  Procedure GetFidelizacionCliente(cur_out Out cursor_type,
                                   pCodBar In TjClientesCf.VlCodBar%Type) As
    v_Modulo Varchar2(100) := 'PKG_CLIENTE.GetFidelizacionCliente';
  Begin
    --n_pkg_vitalpos_log_general.write(2,'Modulo: ' || v_Modulo ||'  codigo: ' || pCodBar);
    Open cur_out For
      Select Ent.IdEntidad, Ent.CdCuit, Ent.DsRazonSocial
        From TjClientesCf Tj, entidades Ent
       Where Tj.VlCodBar = pCodBar
         And Tj.IdEntidad = Ent.IdEntidad
         And Ent.CdEstadoOperativo = c_IdEntidadOperativa;
  Exception
    When Others Then
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_Modulo ||
                                       '  Error: ' || Sqlerrm);
      Raise;
  End GetFidelizacionCliente;

  /****************************************************************************************
  * 04/04/2014
  * JBodnar
  * Retorna un cursor con la descripcion de los canales
  *****************************************************************************************/
  Procedure GetCanales(cur_out Out cursor_type) As
    v_Modulo Varchar2(100) := 'PKG_CLIENTE.GetCanales';
  Begin
    --Cargo y retorno el cursor con la descripcion de los canales activos
    Open cur_out For
      Select id_canal, nombre From tblcanal Where activo = 1;
  Exception
    When Others Then
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_Modulo ||
                                       '  Error: ' || Sqlerrm);
      Raise;
  End GetCanales;

  /****************************************************************************************
  * 04/04/2014
  * JBodnar
  * Retorna un cursor con la descripcion de los rubros comerciales
  *****************************************************************************************/
  Procedure GetRubros(cur_out Out cursor_type) As
    v_Modulo Varchar2(100) := 'PKG_CLIENTE.GetRubros';
  Begin
    --Cargo y retorno el cursor con la descripcion de los rubros comerciales
    Open cur_out For
      Select Trim(cdrubrocomercial) As cdrubrocomercial, dsrubrocomercial
        From rubroscomerciales;
  Exception
    When Others Then
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_Modulo ||
                                       '  Error: ' || Sqlerrm);
      Raise;
  End GetRubros;

  /****************************************************************************************
  * 04/04/2014
  * JBodnar
  * Retorna un cursor con la descripcion de los tipos de direcciones
  *****************************************************************************************/
  Procedure GetTipoDirec(cur_out Out cursor_type) As
    v_Modulo Varchar2(100) := 'PKG_CLIENTE.GetTipoDirec';
  Begin
    --Cargo y retorno el cursor con la descripcion de los tipos de direcciones
    Open cur_out For
      Select Trim(cdtipodireccion) As cdtipodireccion, dstipodireccion
        From tipodirecciones;
  Exception
    When Others Then
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_Modulo ||
                                       '  Error: ' || Sqlerrm);
      Raise;
  End GetTipoDirec;

  /****************************************************************************************
  * 04/04/2014
  * JBodnar
  * Retorna un cursor con la descripcion de los paises cargados
  *****************************************************************************************/
  Procedure GetPaises(cur_out Out cursor_type) As
    v_Modulo Varchar2(100) := 'PKG_CLIENTE.GetPaises';
  Begin
    --Cargo y retorno el cursor con la descripcion de los los paises cargados
    Open cur_out For
      Select Trim(cdpais) As cdpais, dspais From paises;
  Exception
    When Others Then
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_Modulo ||
                                       '  Error: ' || Sqlerrm);
      Raise;
  End GetPaises;

  /****************************************************************************************
  * 04/04/2014
  * JBodnar
  * Retorna un cursor con la descripcion de las provincias cargadas
  *****************************************************************************************/
  Procedure GetProvincias(p_Pais  In paises.cdpais%Type,
                          cur_out Out cursor_type) As
    v_Modulo Varchar2(100) := 'PKG_CLIENTE.GetProvincias';
  Begin
    --Cargo y retorno el cursor con la descripcion de las provincias cargadas
    Open cur_out For
      Select Trim(cdprovincia) As cdprovincia, dsprovincia
        From provincias
       Where cdpais = p_Pais;
  Exception
    When Others Then
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_Modulo ||
                                       '  Error: ' || Sqlerrm);
      Raise;
  End GetProvincias;

  /****************************************************************************************
  * 04/04/2014
  * JBodnar
  * Retorna un cursor con la descripcion de las situaciones impositivas
  *****************************************************************************************/
  Procedure GetSituacionIva(cur_out Out cursor_type) As
    v_Modulo Varchar2(100) := 'PKG_CLIENTE.GetSituacionIva';
  Begin
    --Cargo y retorno el cursor con la descripcion de las situaciones impositivas
    Open cur_out For
      Select Trim(cdsituacioniva) As cdsituacioniva, dssituacioniva
        From situacionesiva
       Where icmuestra = 1;
  Exception
    When Others Then
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_Modulo ||
                                       '  Error: ' || Sqlerrm);
      Raise;
  End GetSituacionIva;

  /****************************************************************************************
  * Retorna un cursor con la descripcion de las situaciones ingresos brutos
  * %v 21/03/2016 - JBodnar
  *****************************************************************************************/
  Procedure GetSituacionIB(cur_out Out cursor_type) As
    v_Modulo Varchar2(100) := 'PKG_CLIENTE.GetSituacionIB';
  Begin
    --Cargo y retorno el cursor con la descripcion de las situaciones impositivas
    Open cur_out For
      Select Trim(ib.cdsituacionib) As cdsituacionib, ib.dssituacionib
        From tblimpsituacionib ib;
  Exception
    When Others Then
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_Modulo ||
                                       '  Error: ' || Sqlerrm);
      Raise;
  End GetSituacionIB;

  /****************************************************************************************
  * Retorna un cursor con la descripcion de las categorias del impuesto municipal
  * %v 21/03/2016 - JBodnar
  *****************************************************************************************/
  Procedure GetSituacionMunicipal(cur_out Out cursor_type) As
    v_Modulo Varchar2(100) := 'PKG_CLIENTE.GetSituacionMunicipal';
  Begin
    --Cargo y retorno el cursor con la descripcion de las situaciones impositivas
    Open cur_out For
      select decode(t.icinscriptomunicipal,
                    1,
                    'No Inscripto',
                    2,
                    'Inscripto') dsmunicipal,
             t.icinscriptomunicipal icmunicipal
        from tblimpuesto i, tblimptasa t
       where i.cdimptipo = 'ImpMun'
         and t.cdimpuesto = i.cdimpuesto
      union
      select 'Exento' dsmunicipal, 3 icmunicipal
        from dual;
  Exception
    When Others Then
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_Modulo ||
                                       '  Error: ' || Sqlerrm);
      Raise;
  End GetSituacionMunicipal;

  /****************************************************************************************
  * 04/04/2014
  * JBodnar
  * Retorna un cursor con la descripcion de las localidades recibiendo un string
  *****************************************************************************************/
  Procedure GetLocalidades(p_Localidad In localidades.dslocalidad%Type,
                           p_Provincia In provincias.cdprovincia%Type,
                           p_Pais      In paises.cdpais%Type,
                           cur_out     Out cursor_type) As
    v_Modulo Varchar2(100) := 'PKG_CLIENTE.GetLocalidades';
    v_sql    Varchar2(200);
  Begin
    --Armo consulta dinamica con un like del parametro recibido
    v_sql := 'select trim(cdlocalidad) as cdlocalidad, dslocalidad from localidades where cdprovincia=' ||
             p_Provincia || ' and cdpais=';
    v_sql := v_sql || p_Pais || ' and dslocalidad like ' || chr(39) || '%' ||
             Trim(upper(p_Localidad)) || '%' || chr(39);
    --Cargo y retorno el cursor con la descripcion de las localidades recibiendo un string
    Open cur_out For v_sql;
  Exception
    When Others Then
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_Modulo ||
                                       '  Error: ' || Sqlerrm);
      Raise;
  End GetLocalidades;

  /****************************************************************************************
  * 04/04/2014
  * JBodnar
  * Retorna un cursor con el codigo postal dada una localidad y una provincia
  *****************************************************************************************/
  Procedure GetCdPostal(p_CdLocalidad In localidades.cdlocalidad%Type,
                        p_CdProvincia In provincias.cdprovincia%Type,
                        cur_out       Out cursor_type) As
    v_Modulo Varchar2(100) := 'PKG_CLIENTE.GetCdPostal';
  Begin
    --Retorna el codigo postal dada una localidad y una provincia
    Open cur_out For
      Select Trim(cdcodigopostal) cdcodigopostal
        From codigospostales
       Where cdlocalidad = p_CdLocalidad
         And cdprovincia = p_CdProvincia;
  Exception
    When Others Then
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_Modulo ||
                                       '  Error: ' || Sqlerrm);
      Raise;
  End GetCdPostal;

  /****************************************************************************************
  * 07/04/2014
  * JBodnar
  * Retorna un cursor los contactos de un cliente(telefonos, emails, etc)
  *****************************************************************************************/
  Procedure GetContactosCliente(p_Identidad In entidades.identidad%Type,
                                cur_out     Out cursor_type) As
    v_Modulo Varchar2(100) := 'PKG_CLIENTE.GetContactosCliente';
  Begin
    --Cursor con dato de los contactos del cliente
    Open cur_out For
      Select Trim(ce.cdformadecontacto) As cdformadecontacto,
             ce.dscontactoentidad,
             fc.dsformadecontacto,
             ce.sqcontactoentidad
        From contactosentidades ce, formasdecontacto fc, entidades e
       Where ce.identidad = e.identidad
         And ce.cdformadecontacto = fc.cdformadecontacto
         And e.identidad = p_Identidad;
  Exception
    When Others Then
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_Modulo ||
                                       '  Error: ' || Sqlerrm);
      Raise;
  End GetContactosCliente;

  /****************************************************************************************
  * 07/04/2014
  * JBodnar
  * Retorna un Cursor de datos de direcciones
  *****************************************************************************************/
  Procedure GetDomiciliosCliente(p_Identidad In entidades.identidad%Type, /*p_DomicilioCuenta in integer,*/
                                 cur_out     Out cursor_type) As
    v_Modulo Varchar2(100) := 'PKG_CLIENTE.GetDomiciliosCliente';
  Begin
    --Cursor de datos de direcciones
    Open cur_out For
    --Ultima direccion comercial
      Select Trim(td.cdtipodireccion) As CdTipoDireccion,
             td.dstipodireccion As DsTipoDireccion,
             d.dscalle As Calle,
             d.dsnumero As Numero,
             d.dspisonumero As Piso,
             Trim(p.cdpais) As CdPais,
             p.dspais As DsPais,
             Trim(l.cdlocalidad) As CdLocalidad,
             l.dslocalidad As DsLocalidad,
             Trim(prov.cdprovincia) As CdProvincia,
             Trim(prov.dsprovincia) As DsProvincia,
             Trim(d.cdcodigopostal) As CodigoPostal,
             d.icactiva As Activa,
             d.sqdireccion As Sqdireccion,
             i.icresol177 As Resol177
        From entidades              e,
             direccionesentidades   d,
             paises                 p,
             localidades            l,
             provincias             prov,
             tipodirecciones        td,
             infoimpuestosentidades i,
             codigospostales        cod
       Where e.identidad = d.identidad
         And d.cdtipodireccion = td.cdtipodireccion
         And d.cdpais = p.cdpais
         And d.cdprovincia = prov.cdprovincia
         And d.cdlocalidad = l.cdlocalidad
         And d.cdcodigopostal = cod.cdcodigopostal
         And prov.cdpais = p.cdpais
         And l.cdpais = p.cdpais
         And l.cdprovincia = prov.cdprovincia
         And cod.cdpais = p.cdpais
         And cod.cdprovincia = prov.cdprovincia
         And cod.cdlocalidad = l.cdlocalidad
         And e.identidad = i.identidad
         and d.sqdireccion =
             (select max(sqdireccion)
                from direccionesentidades
               where identidad = e.identidad
                 And cdtipodireccion = c_DirComercial) --Maximo sq de las comerciales
         And e.identidad = p_Identidad
      union
      --Todas las direcciones que no sean comerciales
      Select Trim(td.cdtipodireccion) As CdTipoDireccion,
             td.dstipodireccion As DsTipoDireccion,
             d.dscalle As Calle,
             d.dsnumero As Numero,
             d.dspisonumero As Piso,
             Trim(p.cdpais) As CdPais,
             p.dspais As DsPais,
             Trim(l.cdlocalidad) As CdLocalidad,
             l.dslocalidad As DsLocalidad,
             Trim(prov.cdprovincia) As CdProvincia,
             Trim(prov.dsprovincia) As DsProvincia,
             Trim(d.cdcodigopostal) As CodigoPostal,
             d.icactiva As Activa,
             d.sqdireccion As Sqdireccion,
             i.icresol177 As Resol177
        From entidades              e,
             direccionesentidades   d,
             paises                 p,
             localidades            l,
             provincias             prov,
             tipodirecciones        td,
             infoimpuestosentidades i,
             codigospostales        cod
       Where e.identidad = d.identidad
         And d.cdtipodireccion = td.cdtipodireccion
         And d.cdpais = p.cdpais
         And d.cdprovincia = prov.cdprovincia
         And d.cdlocalidad = l.cdlocalidad
         And d.cdcodigopostal = cod.cdcodigopostal
         And prov.cdpais = p.cdpais
         And l.cdpais = p.cdpais
         And l.cdprovincia = prov.cdprovincia
         And cod.cdpais = p.cdpais
         And cod.cdprovincia = prov.cdprovincia
         And cod.cdlocalidad = l.cdlocalidad
         And e.identidad = i.identidad
         And d.cdtipodireccion <> c_DirComercial
         And e.identidad = p_Identidad;
  Exception
    When Others Then
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_Modulo ||
                                       '  Error: ' || Sqlerrm);
      Raise;
  End GetDomiciliosCliente;

  /****************************************************************************************
  * 12/05/2014
  * JBodnar
  * Se evalua si un cliente tiene el certificado de REBA y si esta o no habilitado
  *****************************************************************************************/
  Procedure GetRebaTMK(cur_out    Out cursor_type,
                       pIdEntidad In Entidades.IDENTIDAD%Type) As
    v_Modulo    Varchar2(100) := 'PKG_CLIENTE.GetRebaTMK';
    strTipodir  DireccionesEntidades.CdTipoDireccion%Type;
    rv          Integer;
    cd13178     Entidades.Cd13178%Type;
    dt13178     Entidades.Dt13178%Type;
    dtfac       Documentos.DtDocumento%Type;
    cdprovincia DireccionesEntidades.CdProvincia%Type;
    cdlocalidad DireccionesEntidades.CdLocalidad%Type;
  Begin
    -- En principio digo que no esta habilitado
    rv         := 0;
    strTipoDir := SUBSTR(N_PKG_VITALPOS_CORE.Getvlparametro('CdDirComercial',
                                                            'Creditos'),
                         1,
                         8);
    dtfac      := trunc(N_PKG_VITALPOS_CORE.Getdt());
    Select d.cdprovincia, cdlocalidad, cd13178, dt13178
      Into cdprovincia, cdlocalidad, cd13178, dt13178
      From DireccionesEntidades d, Entidades e
     Where d.identidad = e.identidad
       And d.cdtipodireccion = strtipodir
       And e.identidad = pIdEntidad
       And d.sqdireccion =
           (Select Max(sqdireccion)
              From DireccionesEntidades d2
             Where d2.identidad = pIdEntidad
               And d2.cdtipodireccion = strTipoDir);
    If (cdprovincia <> 1 And cdprovincia <> 14) Or
       (cdprovincia = 14 And cdlocalidad <> 12331) Then
      -- Sin Certificado
      rv := 2;
    Else
      If (cd13178 Is Not Null) Then
        If (trunc(dt13178) >= dtfac) Then
          -- Habilitado
          rv := 1;
        Else
          -- Vencido
          rv := 3;
        End If;
      End If;
    End If;
    Open cur_out For
      Select rv REBA, dt13178 FECHAREBA From DUAL;
  Exception
    When Others Then
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_Modulo ||
                                       '  Error: ' || Sqlerrm);
      Raise;
  End GetRebaTMK;

  /****************************************************************************************
  * 12/05/2014
  * JBodnar
  * Dado un cliente evalua Condicion de Venta, Rubro Comercial, Situacion impositiva,
  * reargos, etc, y retorna un cursor
  *****************************************************************************************/
  Procedure GetDatosComerciales(cur_out    Out cursor_type,
                                pIdEntidad In ENTIDADES.IDENTIDAD%Type) Is
    v_Modulo          Varchar2(100) := 'PKG_CLIENTE.GetDatosComerciales';
    lCDRubroComercial RUBROSCOMERCIALES.CDRubroComercial%Type;
    lDSRubroComercial RUBROSCOMERCIALES.DSRubroComercial%Type;
    lCDSituacionIva   SITUACIONESIVA.CDSituacionIva%Type;
    lDSSituacionIva   SITUACIONESIVA.DSSituacionIva%Type;
    lAplicaRecargo    Number;
    lDiscrimina       Number;
    lPoseePosnet      Number;
    vCdLugar          OperacionesComprobantes.CdLugar%Type;
  Begin
    -- OBTENGO RUBROCOMERCIAL DEL CLIENTE
    Begin
      Select r.CDRubroComercial, UPPER(r.DSRubroComercial) DSRubroComercial
        Into lCDRubroComercial, lDSRubroComercial
        From Entidades e, RUBROSCOMERCIALES r
       Where e.IDEntidad = pIdEntidad
         And e.CDRubroPrincipal = r.CDRubroComercial;
    Exception
      When Others Then
        lCDRubroComercial := ' ';
        lDSRubroComercial := ' ';
    End;
    -- OBTENGO SITUACIONIVA DEL CLIENTE
    Begin
      Select s.CDSituacionIva, UPPER(s.DSSituacionIva) DSSituacionIva
        Into lCDSituacionIva, lDSSituacionIva
        From INFOIMPUESTOSEntidades i, SITUACIONESIVA s
       Where IDEntidad = pIdEntidad
         And i.CDSituacionIva = s.CDSituacionIva;
    Exception
      When Others Then
        lCDSituacionIva := ' ';
        lDSSituacionIva := ' ';
    End;
    -- OBTENGO SI EL CLIENTE APLICA RECARGO
    Begin
      Select Count(*)
        Into lAplicaRecargo
        From EXENTIRECESP
       Where Identidad = pIdEntidad;
      If lAplicaRecargo >= 1 Then
        lAplicaRecargo := 0;
      Else
        lAplicaRecargo := 1;
      End If;
    Exception
      When Others Then
        lAplicaRecargo := 0;
    End;
    -- OBTENGO SI EL CLIENTE DISCRIMINA
    Begin
      vCdLugar := N_PKG_VITALPOS_CORE.GetVlParametro('CdLugar', 'General');
      Select IcDiscrimina
        Into lDiscrimina
        From OperacionesComprobantes
       Where CdOperacion = c_IdCodigoOperacion
         And CdSituacionIVA = lCDSituacionIva
         And CdLugar = vCdLugar;
    Exception
      When Others Then
        lDiscrimina := 0;
    End;
    -- OBTENGO SI EL CLIENTE POSEE POSNET
    Begin
      Select Count(*)
        Into lPoseePosnet
        From DOCUMENTOS D
       Where D.IDENTIDAD = pIdEntidad
         And D.CDCOMPROBANTE Like 'PB%';
      If lPoseePosnet >= 1 Then
        lPoseePosnet := 1;
      Else
        lPoseePosnet := 0;
      End If;
    Exception
      When Others Then
        lPoseePosnet := 0;
    End;
    Open cur_out For
      Select pIdEntidad        IDENTIDAD,
             lCDRubroComercial CDRubroComercial,
             lDSRubroComercial DSRubroComercial,
             lCDSituacionIva   CDSituacionIva,
             lDSSituacionIva   DSSituacionIva,
             lAplicaRecargo    AplicaRecargo,
             lDiscrimina       Discrimina,
             lPoseePosnet      PoseePosnet
        From DUAL;
  Exception
    When Others Then
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_Modulo ||
                                       '  Error: ' || Sqlerrm);
      Raise;
  End GetDatosComerciales;

  /****************************************************************************************
  * 08/04/2014
  * JBodnar
  * Retorna un cursor las diferenctes formas de contacto
  *****************************************************************************************/
  Procedure GetFormasContacto(cur_out Out cursor_type) As
    v_Modulo Varchar2(100) := 'PKG_CLIENTE.GetFormasContacto';
  Begin
    --Retorna un cursor las diferenctes formas de contacto
    Open cur_out For
      Select Trim(cdformadecontacto) cdformadecontacto, dsformadecontacto
        From formasdecontacto;
  Exception
    When Others Then
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_Modulo ||
                                       '  Error: ' || Sqlerrm);
      Raise;
  End GetFormasContacto;

  /****************************************************************************************
  * 11/04/2014
  * JBodnar
  * Retorna un cursor con los estados operativos del sistema
  *****************************************************************************************/
  Procedure GetEstadosOperativos(cur_out Out cursor_type) Is
    v_Modulo Varchar2(100) := 'PKG_CLIENTE.GetEstadosOperativos';
  Begin
    --Retorna un cursor con los estados operativos del sistema
    Open cur_out For
      Select Trim(e.cdestadooperativo) cdestadooperativo,
             e.nmtarea,
             e.dsestadooperativo
        From estadosoperativos e;
  Exception
    When Others Then
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_Modulo ||
                                       '  Error: ' || Sqlerrm);
      Raise;
  End GetEstadosOperativos;

  /****************************************************************************************
  * 11/04/2014
  * JBodnar
  * Verifica si el numero de habilitacion esta asignada a otro cliente
  *****************************************************************************************/
  Function HabilitacionOK(p_IdEntidad entidades.identidad%Type,
                          p_Cliente   Out Varchar2,
                          p_Cd13178   entidades.cd13178%Type) Return Number Is
    v_Modulo  Varchar2(100) := 'PKG_CLIENTE.HabilitacionOK';
    v_Cliente Varchar2(100) := '';
    v_Ok      Integer;
  Begin
    --Verifico si ya existe el codigo de habilitacion para otro cliente
    Begin
      Select cdcuit || '-' || dsrazonsocial, 1
        Into p_Cliente, v_Ok
        From entidades
       Where identidad <> p_IdEntidad
         And cd13178 = p_Cd13178;
    Exception
      When no_data_found Then
        v_Ok      := 0;
        p_Cliente := v_Cliente;
    End;
    Return v_Ok;
  Exception
    When Others Then
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_Modulo ||
                                       '  Error: ' || Sqlerrm);
      Raise;
  End HabilitacionOK;

  /****************************************************************************************
   * Retorna un cursor con los datos de las entidades segun un cuit
  * 17/12/2014 MatiasG - v1.0
  * 28/08/2018 - JBodnar: Nueva marca si el cliente es excluido
   *****************************************************************************************/
  PROCEDURE GetClientesPorCuit(cur_out OUT cursor_type,
                               p_Cuit  IN entidades.cdcuit%TYPE,
                               p_Rol   IN rolesentidades.cdrol%TYPE) IS
    v_Modulo VARCHAR2(100) := 'PKG_CLIENTE.GetClientesPorCuit';
  BEGIN
    OPEN cur_out FOR
      SELECT DISTINCT e.identidad,
                      e.cdcuit,
                      e.dsrazonsocial,
                      e.dsnombrefantasia,
                      tj.IdEntidad AS EsFidelizado,
                      EsExcluido(e.identidad) as Excluido
        FROM entidades e, rolesentidades re, TjClientesCf tj
       WHERE re.identidad = e.identidad
         AND tj.identidad(+) = e.identidad
         AND trim(e.cdestadooperativo) = 'A' --Solo los clientes activos
         AND (re.cdrol = p_Rol OR p_Rol IS NULL)
         AND REPLACE(e.cdcuit, '-') LIKE REPLACE(p_Cuit, '-') || '%';
  EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_Modulo ||
                                       '  Error: ' || SQLERRM);
      RAISE;
  END GetClientesPorCuit;

  /****************************************************************************************
  * Si el cliente esta activo=1 si esta de baja=0
  * 20/11/2015 JBodnar - v1.0
   *****************************************************************************************/
  PROCEDURE GetClienteBajaPorCuit(p_Cuit   IN entidades.cdcuit%TYPE,
                                  p_Activo OUT Integer) Is
    v_return Integer;
  BEGIN
    SELECT count(*)
      into v_return
      FROM entidades e
     WHERE REPLACE(e.cdcuit, '-') LIKE REPLACE(p_Cuit, '-') || '%';

    IF v_return = 1 THEN
      SELECT count(*)
        into v_return
        FROM entidades e
       WHERE REPLACE(e.cdcuit, '-') LIKE REPLACE(p_Cuit, '-') || '%'
         AND e.cdestadooperativo = 'B'; --Solo los clientes activos

      IF v_return = 1 THEN
        p_Activo := 0; --Baja
      else
        p_Activo := 1; --Activo
      end if;
    ELSE
      p_Activo := 1; --Activo
    END IF;

  EXCEPTION
    WHEN OTHERS THEN
      null;
      RAISE;
  END GetClienteBajaPorCuit;

  /****************************************************************************************
  * Valida el codigo para generar el cupon
  * 17/02/2017 LucianoF - v1.0
  * %v 24/05/2018 - APW - Anulamos la validación porque la aplicación genera un loop buscando códigos válidos
  *****************************************************************************************/
  PROCEDURE ValidarCodigoCupon(p_Codigo IN tblentidad_cupon.vlcodigo%TYPE,
                               p_Existe OUT Integer) Is
  BEGIN
    p_Existe := 0;
  EXCEPTION
    WHEN OTHERS THEN
      null;
      RAISE;
  END ValidarCodigoCupon;

  /****************************************************************************************
  * Inserta un nuevo codigo para cupon en el alta de cliente
  * 17/02/2017 LucianoF - v1.0
   *****************************************************************************************/
  PROCEDURE InsertarCodigoCupon(p_IdEntidad IN tblentidad_cupon.identidad%TYPE,
                                p_Codigo    IN tblentidad_cupon.vlcodigo%TYPE,
                                p_update    IN tblentidad_cupon.icupdate%TYPE) Is
    v_dtOperativa Date := N_PKG_VITALPOS_CORE.GetDT();
  BEGIN
    INSERT INTO tblentidad_cupon
      (identidad,
       vlcodigo,
       cdcupon,
       icvalido,
       dtcreacion,
       dtvalido,
       icupdate)
    VALUES
      (p_IdEntidad, p_Codigo, null, 0, v_dtOperativa, null, p_update);
    commit;

  EXCEPTION
    WHEN OTHERS THEN
      null;
      RAISE;
  END InsertarCodigoCupon;

  /****************************************************************************************
  * Inserta un nuevo codigo para cupon en el alta de cliente
  * 17/02/2017 LucianoF - v1.0
  * 13/07/2018 - APW - ahora los codigos se pueden repetir, se agrega el cliente en la validación
  *****************************************************************************************/
  PROCEDURE ValidarCodigoPresentado(p_Codigo    IN tblentidad_cupon.vlcodigo%TYPE,
                                    p_IdEntidad IN tblentidad_cupon.identidad%TYPE,
                                    p_ok        OUT integer,
                                    p_error     OUT varchar2) Is
    v_dtOperativa Date := N_PKG_VITALPOS_CORE.GetDT();
    v_reg         tblentidad_cupon%ROWTYPE;
    v_cdcupon     tblentidad_cupon.cdcupon%TYPE;
  BEGIN
    p_ok    := 1;
    p_error := '';

    begin
      select *
        into v_reg
        from tblentidad_cupon ec
       where ec.vlcodigo = p_Codigo
         and ec.identidad = p_IdEntidad;
    exception
      when no_data_found then
        p_ok    := 0;
        p_error := 'No existe el codigo ingresado para el cliente.';
        return;
    end;

    --validaciones
    if v_reg.icvalido = 1 then
      p_ok    := 0;
      p_error := 'El código ingresado ya fue validado.';
      return;
    end if;

    /* if trim(v_reg.identidad) <> trim(p_IdEntidad) then
       p_ok :=0;
       p_error:='El código ingresado no corresponde al cliente buscado.';
       return;
    end if;*/

    --llamo para insertar el cupon
    PKGPROMO_CUPON.InsertarCuponAltaCliente(p_identidad,
                                            p_ok,
                                            p_error,
                                            v_cdcupon,
                                            v_reg.icupdate);

    if p_ok = 0 then
      return;
    end if;

    Update tblentidad_cupon ec
       set ec.icvalido = 1,
           ec.dtvalido = v_dtOperativa,
           ec.cdcupon  = v_cdcupon
     where ec.vlcodigo = p_Codigo;
    commit;
  EXCEPTION
    WHEN OTHERS THEN
      null;
      RAISE;
  END ValidarCodigoPresentado;

  /****************************************************************************************
  * 19/05/2014
  * JBodnar
  * Retorna los datos de un empleado de vital dado un legajo recibido
  *****************************************************************************************/
  Procedure GetEmpleadoPorLegajo(cur_out   Out cursor_type,
                                 pCdLegajo In Personas.CdLegajo%Type) As
    v_Modulo Varchar2(100) := 'PKG_CLIENTE.GetEmpleadoPorLegajo';
  Begin
    Open cur_out For
      Select Per.DsNombre, Per.DsApellido, Per.CdLegajo
        From Personas Per
       Where CdLegajo = pCdLegajo
         And IcActivo = c_IdPersonaActiva
         And Not Exists (Select 1
                From IdsEXcludCFVital Idex
               Where Idex.IdPersona = Per.IdPersona);
  Exception
    When Others Then
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_Modulo ||
                                       '  Error: ' || Sqlerrm);
      Raise;
  End GetEmpleadoPorLegajo;

  /****************************************************************************************
  * %v 07/08/2017 - APW - Retorna los datos de un empleado de vital ingresando el dni
  *****************************************************************************************/
  Procedure GetEmpleadoPorDNI(cur_out       Out cursor_type,
                              p_nudocumento In Personas.Nudocumento%Type) As
    v_Modulo Varchar2(100) := 'PKG_CLIENTE.GetEmpleadoPorDNI';
  Begin
    Open cur_out For
      Select Per.DsNombre, Per.DsApellido, Per.CdLegajo
        From Personas Per
       Where per.nudocumento = p_nudocumento
         And IcActivo = c_IdPersonaActiva
         And Not Exists (Select 1
                From IdsEXcludCFVital Idex
               Where Idex.IdPersona = Per.IdPersona);
  Exception
    When Others Then
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_Modulo ||
                                       '  Error: ' || Sqlerrm);
      Raise;
  End GetEmpleadoPorDNI;

  /****************************************************************************************
  * 09/04/2014
  * JBodnar
  * Retorna un cursor con los datos de las entidades segun una razon social
  * 28/08/2018 - JBodnar: Nueva marca si el cliente es excluido
  *****************************************************************************************/
  Procedure GetClientesPorRazonSocial(cur_out       Out cursor_type,
                                      p_RazonSocial In entidades.dsrazonsocial%Type,
                                      p_Rol         In rolesentidades.cdrol%Type) Is
    v_Modulo     Varchar2(100) := 'PKG_CLIENTE.GetClientesPorRazonSocial';
    vModificador Varchar2(1) := '';
    vRazonSocial Varchar2(100) := p_RazonSocial;
    vSql         Varchar2(1000) := '';

  Begin
    If SUBSTR(p_RazonSocial, 0, 1) <> '/' Then
      vModificador := '%';
    Else
      vRazonSocial := SUBSTR(vRazonSocial, 2, LENGTH(vRazonSocial) - 1);
    End If;

    --Busqueda de nombres con apostrofo
    vRazonSocial := replace(vRazonSocial, '''', '''''');

    vSql := 'SELECT DISTINCT ' || '   e.identidad, ' || '   e.cdcuit, ' ||
            '   e.dsrazonsocial, ' || '   e.dsnombrefantasia, ' ||
            '   tj.IdEntidad As EsFidelizado, ' ||
            '   pkg_cliente.EsExcluido(e.identidad) as Excluido ' ||
            ' FROM entidades      e, ' || '     rolesentidades r,' ||
            ' TjClientesCf tj';
    vSql := vSql ||
            ' WHERE e.identidad = r.identidad and trim(e.cdestadooperativo)=''A'' and tj.identidad(+)=e.identidad ' ||
            ' AND UPPER(e.dsrazonsocial) LIKE ''' || vModificador ||
            UPPER(vRazonSocial) || '%''';
    --Si es no es null
    IF p_Rol IS NOT NULL THEN
      vSql := vSql || ' AND r.cdrol = ''' || p_Rol || '''';
    END IF;
    --Carga el cursor
    Open cur_out For vSql;
  Exception
    When Others Then
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_Modulo ||
                                       '  Error: ' || Sqlerrm);
      Raise;
  End GetClientesPorRazonSocial;

  /****************************************************************************************
  * Si el cliente esta activo=1 si esta de baja=0
  * 20/11/2015 JBodnar - v1.0
   *****************************************************************************************/
  PROCEDURE GetClienteBajaRazon(p_RazonSocial In entidades.dsrazonsocial%Type,
                                p_Activo      OUT Integer) Is
    v_return Integer;
  BEGIN

    --Valida si existe el cliente
    SELECT count(*)
      INTO v_return
      FROM entidades e
     WHERE e.dsrazonsocial like '%' || UPPER(trim(p_RazonSocial)) || '%';

    IF v_return = 1 THEN
      SELECT count(*)
        INTO v_return
        FROM entidades e
       WHERE e.dsrazonsocial like '%' || UPPER(trim(p_RazonSocial)) || '%'
         AND e.cdestadooperativo = 'B'; --Solo los clientes activos

      IF v_return = 1 THEN
        p_Activo := 0; --Baja
      else
        p_Activo := 1; --Activo
      end if;
    ELSE
      p_Activo := 1; --Activo
    END IF;

  EXCEPTION
    WHEN OTHERS THEN
      null;
      RAISE;
  END GetClienteBajaRazon;

  /****************************************************************************************
  * 12/05/2014
  * JBodnar
  * Retorna un cursor con los datos de las entidades dada una cuenta
  *****************************************************************************************/
  Procedure GetClienteCuenta(cur_out    Out cursor_type,
                             p_IdCuenta In tblcuenta.idcuenta%Type) As
    v_Modulo Varchar2(100) := 'PKG_CLIENTE.GetClienteCuenta';
  Begin
    Open cur_out For
      Select Distinct e.identidad,
                      e.cdcuit,
                      e.dsrazonsocial,
                      e.dsnombrefantasia,
                      e.CdMainCanal,
                      Tj.IdEntidad       As EsFidelizado,
                      cli.IdEntidad      ExcludLimitArts
        From entidades       e,
             rolesentidades  r,
             TjClientesCf    Tj,
             Facart_Clientes cli
       Where e.identidad = r.identidad
         And e.identidad = (Select identidad
                              From tblcuenta
                             Where idcuenta = p_IdCuenta
                               And rownum = 1)
         And e.IdEntidad = Tj.IdEntidad(+)
         And e.IdEntidad = cli.IdEntidad(+);
  Exception
    When Others Then
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_Modulo ||
                                       '  Error: ' || Sqlerrm);
      Raise;
  End GetClienteCuenta;

  /****************************************************************************************
  * 24/04/2014
  * JBodnar
  * Retorna los roles que tiene asociado un cliente
  *****************************************************************************************/
  Procedure GetRolesCliente(p_Identidad In entidades.identidad%Type,
                            cur_out     Out cursor_type) As
    v_Modulo Varchar2(100) := 'PKG_CLIENTE.GetRolesCliente';
  Begin
    --Cursor de datos de los roles del cliente
    Open cur_out For
      Select re.cdrol, r.dsrol
        From rolesentidades re, roles r
       Where re.cdrol = r.cdrol
         and r.ictiporol = 1
         And re.identidad = p_Identidad
         AND r.icactivo = 1;
  Exception
    When Others Then
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_Modulo ||
                                       '  Error: ' || Sqlerrm);
      Raise;
  End GetRolesCliente;

  /****************************************************************************************
  * 12/05/2014
  * JBodnar
  * Retorna los roles que tiene asociado un cliente
  *****************************************************************************************/
  Procedure ExcluidoFidelizadoRecargo(cur_out    Out cursor_type,
                                      pIdEntidad In Entidades.IdEntidad%Type) As
    v_Modulo                   Varchar2(100) := 'PKG_CLIENTE.ExcluidoFidelizadoRecargo';
    vTieneTJFidelizacion       Integer;
    vExcluidoFidelizadoRecargo Integer;
    vCuantos                   Integer;
  Begin
    vExcluidoFidelizadoRecargo := 0;
    Select Count(*)
      Into vTieneTJFidelizacion
      From tjclientescf tj, entidades e
     Where tj.identidad = pIdEntidad
       And tj.identidad = e.identidad
       And cdestadooperativo = c_IdEntidadOperativa;
    If (vTieneTJFidelizacion = 1) Then
      Select Count(*)
        Into vCuantos
        From CltesFidelExclud
       Where identidad = pIdEntidad;
      If (vCuantos >= 1) Then
        vExcluidoFidelizadoRecargo := 1;
      End If;
    End If;
    Open cur_out For
      Select vExcluidoFidelizadoRecargo Exclud From DUAL;
  Exception
    When Others Then
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_Modulo ||
                                       '  Error: ' || Sqlerrm);
      Raise;
  End ExcluidoFidelizadoRecargo;

  /****************************************************************************************
  * Retorna la descripcion de asociada a un codigo de localidad
  * %v 12/05/2014 MatiasG: V1.0
  *****************************************************************************************/
  Function GetDescLocalidad(p_cdlocalidad localidades.cdlocalidad%Type)
    Return Varchar2 IS
    v_Modulo      Varchar2(100) := 'PKG_CLIENTE.GetDescLocalidad';
    v_dsLocalidad localidades.dslocalidad%Type;
  Begin

    Select dslocalidad
      Into v_dsLocalidad
      From localidades
     Where cdlocalidad = p_cdlocalidad
       And Rownum = 1;

    Return v_dsLocalidad;

  Exception
    When Others Then
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_Modulo ||
                                       '  Error: ' || Sqlerrm);
      Raise;
  End GetDescLocalidad;

  /****************************************************************************************
  * Retorna la descripcion de asociada a un codigo de provincia
  * %v 12/05/2014 MatiasG: V1.0
  *****************************************************************************************/
  Function GetDescProvincia(p_cdprovincia provincias.cdprovincia%Type)
    Return Varchar2 IS
    v_Modulo      Varchar2(100) := 'PKG_CLIENTE.GetDescProvincia';
    v_dsprovincia provincias.dsprovincia%Type;
  Begin
    Select dsprovincia
      Into v_dsprovincia
      From provincias
     Where cdprovincia = p_cdprovincia
       And Rownum = 1;
    Return v_dsprovincia;
  Exception
    When Others Then
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_Modulo ||
                                       '  Error: ' || Sqlerrm);
      Raise;

  End GetDescProvincia;

  /***************************************************************************************************
  *  Borra excenciones impositivas
  *  %v 17/10/2014 MatiasG - v1.0
  **************************************************************************************************/
  FUNCTION GetReferencia(p_dsReferencia IN documentos.dsreferencia%TYPE)
    RETURN VARCHAR2 IS
    v_modulo VARCHAR2(100) := 'PKG_ADMINISTRACION.GetReferencia';
  BEGIN
    IF p_dsReferencia IS NOT NULL THEN
      IF INSTR(REPLACE(REPLACE(p_dsReferencia, '[', '{'), '(', '{'), '{') = 0 THEN
        RETURN '(' || p_dsReferencia || ')';
      ELSE
        RETURN '(' || SUBSTR(p_dsReferencia,
                             0,
                             INSTR(REPLACE(REPLACE(p_dsReferencia, '[', '{'),
                                           '(',
                                           '{'),
                                   '{') - 1) || ')';
      END IF;
    ELSE
      RETURN NULL;
    END IF;

  EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       '  Error: ' || SQLERRM);
      RAISE;
  END GetReferencia;

  /***************************************************************************************************
  *  Migracion desde N_PKG_VITALPOS_CLIENTES
  *  %v 17/10/2014 MatiasG - v1.0
  **************************************************************************************************/
  PROCEDURE ObtenerCantidadTjFidelizacion(cur_out    OUT cursor_type,
                                          pIdEntidad TJCLIENTESCF.IDENTIDAD%TYPE) IS
  BEGIN
    OPEN cur_out FOR
      SELECT COUNT(*) cantidad
        FROM TJCLIENTESCF
       WHERE identidad = pIdEntidad;

  EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(1,
                                       'N_PKG_VITALPOS_CLIENTES.ObtenerCantidadTjFidelizacion Error: ' ||
                                       SQLERRM);

  END ObtenerCantidadTjFidelizacion;

  /***************************************************************************************************
  *  Migracion desde N_PKG_VITALPOS_CLIENTES
  *  %v 17/10/2014 MatiasG - v1.0
  **************************************************************************************************/
  PROCEDURE ObtenerDatosTjFidelCliente(cur_out    OUT cursor_type,
                                       pIdEntidad TJCLIENTESCF.IDENTIDAD%TYPE) IS
  BEGIN
    OPEN cur_out FOR
      SELECT to_char(fchalta, 'dd/mm/yyyy hh24:mi:ss') FechaAlta,
             p.dsapellido ApeAlta,
             p.dsnombre NombAlta,
             s.dssucursal SucAlta,
             to_char(fchultimareimp, 'dd/mm/yyyy hh24:mi:ss') FechaUltReimp,
             pi.dsapellido ApeReimp,
             pi.dsnombre NombReimp,
             si.dssucursal SucReimp,
             cntimpresiones,
             TRIM(VLCODBAR) CODBAR
        FROM TJCLIENTESCF t,
             personas     p,
             sucursales   s,
             personas     pi,
             sucursales   si
       WHERE t.identidad = pIdEntidad
         AND t.idpersonaresponsable = p.idpersona
         AND t.cdsucursal = s.cdsucursal
         AND t.idpersona = pi.idpersona(+)
         AND t.cdsucursalreimp = si.cdsucursal(+);
  EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(1,
                                       'N_PKG_VITALPOS_CLIENTES.ObtenerDatosTjFidelCliente Error: ' ||
                                       SQLERRM);

  END ObtenerDatosTjFidelCliente;

  /***************************************************************************************************
  *  Migracion desde N_PKG_VITALPOS_CLIENTES
  *  %v 17/10/2014 MatiasG - v1.0
  **************************************************************************************************/
  PROCEDURE ActualizarCantReimpresionesTJ(pCodBar     TJCLIENTESCF.VLCODBAR%TYPE,
                                          pIdEntidad  TJCLIENTESCF.IDENTIDAD%TYPE,
                                          pCdSucursal TJCLIENTESCF.CDSUCURSAL%TYPE,
                                          pIdPersona  TJCLIENTESCF.IDPERSONA%TYPE) IS
  BEGIN
    UPDATE TJCLIENTESCF
       SET CNTIMPRESIONES  = CNTIMPRESIONES + 1,
           VLCODBAR        = REPLACE(pCodBar, '-', '') ||
                             to_char(CNTIMPRESIONES + 1),
           FCHULTIMAREIMP  = SYSDATE,
           IDPERSONA       = pIdPersona,
           cdsucursalreimp = pCdSucursal
     WHERE identidad = pIdEntidad;

  EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(1,
                                       'N_PKG_VITALPOS_CLIENTES.ActualizarCantReimpresionesTJ Error: ' ||
                                       SQLERRM);

  END ActualizarCantReimpresionesTJ;

  /***************************************************************************************************
  *  Migracion desde N_PKG_VITALPOS_CLIENTES
  *  %v 17/10/2014 MatiasG - v1.0
  **************************************************************************************************/
  PROCEDURE InsertarReimpresionTJ(pCodBar     TJCLIENTESCF.VLCODBAR%TYPE,
                                  pIdEntidad  TJCLIENTESCF.IDENTIDAD%TYPE,
                                  pCdSucursal TJCLIENTESCF.CDSUCURSAL%TYPE,
                                  pIdPersona  TJCLIENTESCF.IDPERSONA%TYPE) IS
  BEGIN
    /* APW - 4/4/13 - Agrego 0 para la columna SALDOPUNTOS */
    INSERT INTO TJCLIENTESCF
      (identidad,
       vlcodbar,
       fchalta,
       cdsucursal,
       idpersonaresponsable,
       cntimpresiones)
      SELECT pIdEntidad,
             REPLACE(pCodBar, '-', ''),
             SYSDATE,
             pCdSucursal,
             pIdPersona,
             0
        FROM dual;

  EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(1,
                                       'N_PKG_VITALPOS_CLIENTES.InsertarReimpresionTJ Error: ' ||
                                       SQLERRM);

  END InsertarReimpresionTJ;

  /***************************************************************************************************
  *  Migracion desde N_PKG_VITALPOS_CLIENTES
  *  %v 17/10/2014 MatiasG - v1.0
  **************************************************************************************************/
  PROCEDURE ObtenerEstadoOperativo(cur_out    OUT cursor_type,
                                   pIdEntidad ENTIDADES.IDENTIDAD%TYPE) IS
  BEGIN
    OPEN cur_out FOR
      SELECT cdestadooperativo FROM ENTIDADES WHERE identidad = pIdEntidad;

  EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(1,
                                       'N_PKG_VITALPOS_CLIENTES.ObtenerEstadoOperativo Error: ' ||
                                       SQLERRM);

  END ObtenerEstadoOperativo;

  /**************************************************************************************************
  * %v 31/03/2017 - IAquilano
  * Funcion que retorna 0 si no tiene cupon cargado y 1 si ya tiene cupon cargado
  ***************************************************************************************************/

  FUNCTION VerificarCuponCargado(p_identidad IN entidades.identidad%TYPE)
    RETURN VARCHAR2 IS

    v_modulo    VARCHAR2(100) := 'PKG_CLIENTE.VerificarCuponCargado';
    v_resultado number;
    v_cupon     number;

  BEGIN
    v_resultado := 0;

    select count(*)
      into v_cupon
      from tblentidad_cupon tc
     where tc.identidad = p_identidad;

    If v_cupon >= getvlparametro('MaxCupon', 'General') Then
      v_resultado := 1;
    End If;

    return v_resultado; -- 0 si no tiene cupon 1 si tiene cupon

  EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       '  Error: ' || SQLERRM);
      RAISE;

  END VerificarCuponCargado;

  /**************************************************************************************************
  * %v 31/03/2017 - IAquilano
  * Procedure que llama a la funcion VerificarCuponCargado
  ***************************************************************************************************/

  PROCEDURE VerificarSiTieneCupon(P_Identidad  IN entidades.identidad%TYPE,
                                  P_TieneCupon OUT Integer) IS

  Begin
    P_TieneCupon := VerificarCuponCargado(P_Identidad);

  End VerificarSiTieneCupon;

  /**************************************************************************************************
  * function retorna si un cliente esta o no excluido
  * %v 16/08/2018 - JBodnar
  * %v 28/08/2018 - JBodnar  : Cambia el tipo a char
  ***************************************************************************************************/
  function EsExcluido(p_Identidad IN entidades.identidad%TYPE) return char as

    v_modulo   VARCHAR2(100) := 'PKG_CLIENTE.EsExcluido';
    v_excluido char(1);

  BEGIN

    select count(*)
      into v_excluido
      from tblentidadexcluida e
     where e.identidad = p_identidad;

    return v_excluido;

  EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       '  Error: ' || SQLERRM);
      RAISE;

  End EsExcluido;


  /****************************************************************************************
  * %v 27/08/2018 JBodnar - Graba los datos del cliente por requerimiento fiscal
  * %v 16/11/2018 JBodnar - Retorna el iddatoscli
  * %v 27/07/2020 IA: Agrego contron de verificacion de dni en padron AFIP
  * %v 02/02/2021 ChM agrego cdsucursal para viajar en replica AC
  *****************************************************************************************/
  Procedure GrabarClienteCf(p_Identidad  In tbldatoscliente.identidad%Type,
                            p_Nombre     In tbldatoscliente.nombre%Type,
                            p_Dni        In tbldatoscliente.dni%Type,
                            p_Domicilio  In tbldatoscliente.domicilio%Type,
                            p_Iddatoscli Out tbldatoscliente.iddatoscli%Type,
                            p_ok         Out Integer,
                            p_error      Out Varchar2) As
    v_Modulo Varchar2(100) := 'PKG_CLIENTE.GrabarClienteCf';
    v_existe integer;
    v_existepadron integer;
    v_Iddatoscli tbldatoscliente.iddatoscli%Type;
 Begin

    --Si existe el dni no lo graba
    select count(*) into v_existe
    from tbldatoscliente where dni = p_Dni
    and icactivo=1;
   
   --agrego control de padron
   v_existepadron := ValidarCuitPadron(p_dni, p_Identidad);
   
    if v_existepadron = 1 then
      p_Iddatoscli:= null;
      p_ok    := 0;
      p_error := 'El DNI: ' || p_Dni || ' Existe en el padron AFIP';
      Return;
    end if;

    if v_existe = 1 then
/*      select iddatoscli into v_Iddatoscli
      from tbldatoscliente where dni = p_Dni
      and icactivo=1;
      p_Iddatoscli:= v_Iddatoscli;*/
      p_Iddatoscli:= null;
      p_ok    := 0;
      p_error := 'El DNI: ' || p_Dni || ' ya esta cargado';
      Return;
    end if;

    v_Iddatoscli:= sys_guid();

    --Si no existe lo inserto
    insert into tbldatoscliente
      (iddatoscli, identidad, nombre, dni, domicilio, icactivo,cdsucursal)
    values
      (v_Iddatoscli, p_Identidad, upper(p_Nombre), p_Dni, upper(p_Domicilio), 1,c_Sucursal);

    --Alta OK
    Commit;
    p_Iddatoscli:= v_Iddatoscli;
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
  End GrabarClienteCf;


  /****************************************************************************************
  * %v 27/08/2018 JBodnar - Actualiza los datos del cliente por requerimiento fiscal
  * %v 27/07/2020 IA: Agrego control de padron AFIP
  *****************************************************************************************/
  Procedure ActualizarClienteCf(p_Iddatoscli In tbldatoscliente.iddatoscli%Type,
                                p_Identidad  In tbldatoscliente.identidad%Type,
                                p_Nombre     In tbldatoscliente.nombre%Type,
                                p_Dni        In tbldatoscliente.dni%Type,
                                p_Domicilio  In tbldatoscliente.domicilio%Type,
                                p_ok         Out Integer,
                                p_error      Out Varchar2) As
    v_Modulo Varchar2(100) := 'PKG_CLIENTE.ActualizarClienteCf';
    v_existe integer;
    v_existepadron integer;
  Begin

    select count(*)
    into v_existe
    from tbldatoscliente
    where iddatoscli = p_Iddatoscli
    and icactivo = 0;
    
   --agrego control de padron
   v_existepadron := ValidarCuitPadron(p_dni, p_identidad);

  IF v_existepadron = 1 then
    p_ok := 0;
    p_error := 'El dni '||p_dni||' Existe en el padron AFIP';
    return;
  end if;
  
    if v_existe > 0 then
      p_ok    := 0;
      p_error := 'El cliente no esta activo.';
      Return;
    end if;

    update tbldatoscliente c
       set c.identidad = p_Identidad,
           c.nombre    = upper(p_Nombre),
           c.dni       = p_Dni,
           c.domicilio = upper(p_Domicilio)
     where c.iddatoscli = p_Iddatoscli
     and c.icactivo = 1;

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
  End ActualizarClienteCf;

  /****************************************************************************************
  * %v 27/08/2018 JBodnar - Borra los datos del cliente por requerimiento fiscal
  * %v 21/11/2018 JBodnar - Se cambia el borrado por una una baja lógica de update en el icactivo
  *****************************************************************************************/
  Procedure BorrarClienteCf(p_Iddatoscli In tbldatoscliente.iddatoscli%Type,
                            p_ok         Out Integer,
                            p_error      Out Varchar2) As
    v_Modulo Varchar2(100) := 'PKG_CLIENTE.BorrarClienteCf';
  Begin

    update tbldatoscliente c
    set c.icactivo = 0 --Baja lógica
    where c.iddatoscli = p_Iddatoscli;

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
  End BorrarClienteCf;

  /****************************************************************************************
  * %v 27/08/2018 JBodnar - Retorna los datos del cliente por requerimiento fiscal
  * %v 29/08/2018 JBodnar - Nueva logica y condiciones de retorno de datos
  * %v 29/08/2018 JBodnar - Se agrega el order by por nombre
  *****************************************************************************************/
  Procedure GetClienteCfAdmin(p_Identidad In tbldatoscliente.identidad%Type,
                              p_Nombre    In tbldatoscliente.nombre%Type default null,
                              p_Dni       In tbldatoscliente.dni%Type default null,
                              cur_out     Out cursor_type) As
    v_Modulo Varchar2(100) := 'PKG_CLIENTE.GetClienteCfAdmin';
    vSql     Varchar2(1000);
  Begin

    --Cliente comerciante
    If p_Nombre is null and p_Dni is null then
      Open cur_out for
        select d.iddatoscli, d.nombre, d.dni, d.domicilio
          from tbldatoscliente d
         where d.identidad = p_Identidad
         and d.icactivo = 1
         order by d.nombre;
      Return;
    end if;
    --Consumidor Final por DNI
    If p_Dni is not null then
      Open cur_out for
        select d.iddatoscli, d.nombre, d.dni, d.domicilio
          from tbldatoscliente d
         where d.identidad = p_Identidad
         and d.icactivo = 1
           and d.dni = p_Dni;
      Return;
    end if;
    --Consumidor Final por Nombre
    If p_Nombre is not null then
      vSql := ' Select d.iddatoscli, d.nombre, d.dni, d.domicilio from tbldatoscliente d ' ||
              ' Where d.identidad = ''' || p_Identidad ||
              ''' AND upper(d.nombre) like ' || chr(39) || '%' ||
              Trim(upper(p_Nombre)) || '%' || chr(39) ||
              'and d.icactivo = 1 order by d.nombre';
      Open cur_out for vSql;
      Return;
    end if;

  Exception
    When Others Then
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_Modulo ||
                                       '  Error: ' || Sqlerrm);
      Raise;
  End GetClienteCfAdmin;

  /****************************************************************************************
  * %v 27/08/2018 JBodnar - Retorna los datos del cliente por requerimiento fiscal
  * %v 29/08/2018 JBodnar - Nueva logica y condiciones de retorno de datos
  * %v 29/08/2018 JBodnar - Se agrega el order by por nombre
  * %v 16/11/2018 JBodnar - Se agrega el  p_Saldo
  * %v 21/11/2018 JBodnar - Filtra por el icactivo
  *****************************************************************************************/
  Procedure GetClienteCf(p_Identidad In tbldatoscliente.identidad%Type,
                         p_Nombre    In tbldatoscliente.nombre%Type default null,
                         p_Dni       In tbldatoscliente.dni%Type default null,
                         p_Existe    Out integer ,
                         cur_out     Out cursor_type) As
    v_Modulo Varchar2(100) := 'PKG_CLIENTE.GetClienteCf';
    vSql     Varchar2(1000);
    v_count  integer;
  Begin
    --Defecto
    p_Existe:=1;

    --Cliente comerciante
    If p_Nombre is null and p_Dni is null then
      Open cur_out for
        select d.iddatoscli, d.nombre, d.dni, d.domicilio
          from tbldatoscliente d
         where d.identidad = p_Identidad
         and d.icactivo = 1
         and TieneSaldoDni(d.iddatoscli) = 1
         order by d.nombre;

      --Conteo si existe
      select count(*) into v_count
        from tbldatoscliente d
       where d.identidad = p_Identidad
       and d.icactivo = 1
       order by d.nombre;

      if v_count > 0 then
        p_Existe:=1;
      else
        p_Existe:=0;
      end if;

      Return;

    end if;
    --Consumidor Final por DNI
    If p_Dni is not null then
      Open cur_out for
        select d.iddatoscli, d.nombre, d.dni, d.domicilio
          from tbldatoscliente d
         where d.identidad = p_Identidad
           and d.icactivo = 1
           and d.dni = p_Dni;

      p_Existe:=1;
      Return;
    end if;
    --Consumidor Final por Nombre
    If p_Nombre is not null then
      vSql := ' Select d.iddatoscli, d.nombre, d.dni, d.domicilio from tbldatoscliente d ' ||
              ' Where d.identidad = ''' || p_Identidad ||
              ''' AND upper(d.nombre) like ' || chr(39) || '%' ||
              Trim(upper(p_Nombre)) || '%' || chr(39) ||
              'and d.icactivo = 1 order by d.nombre';
      Open cur_out for vSql;

      p_Existe:=1;
      Return;
    end if;

  Exception
    When Others Then
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_Modulo ||
                                       '  Error: ' || Sqlerrm);
      Raise;
  End GetClienteCf;

  /****************************************************************************************
  * %v 22/11/2018 JBodnar - Retorna cursor dado un Dni de entrada
  *****************************************************************************************/
  Procedure GetPorDni(p_Dni   In tbldatoscliente.dni%Type,
                      cur_out Out cursor_type) As
    v_Modulo Varchar2(100) := 'PKG_CLIENTE.GetPorDni';
  Begin

    Open cur_out for
      select d.iddatoscli,
             d.nombre,
             d.dni,
             d.domicilio,
             e.cdcuit,
             e.dsrazonsocial
        from tbldatoscliente d, entidades e
       where d.dni = p_Dni
         and d.identidad = e.identidad
         and d.icactivo = 1;

  Exception
    When Others Then
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_Modulo ||
                                       '  Error: ' || Sqlerrm);
      Raise;
  End GetPorDni;

  /**************************************************************************************************
  * PROCEDURE acumula para verificar el saldo mensual
  * %v 20/02/2019 -- no se excluye a consumidor final anónimo
  * %v 31/10/2019 - IAquilano: Excluyo non food de la suma.
  ***************************************************************************************************/
  PROCEDURE AcumularSaldoDni(p_iddatoscli IN tbldatoscliente.iddatoscli%TYPE,
                             p_iddoctrx   documentos.iddoctrx%type) as

    v_modulo      VARCHAR2(100) := 'PKG_CLIENTE.AcumularSaldoDni';
    v_amdocumento documentos.amdocumento%type;
    v_dtdocumento documentos.dtdocumento%type;
    v_cdcomprobante documentos.cdcomprobante%type;

  BEGIN

  --Sumo las lineas de los articulos que no sean "NON FOOD"
      select nvl(sum(da.amlinea),0), d.dtdocumento, d.cdcomprobante
        into v_amdocumento, v_dtdocumento, v_cdcomprobante
        from documentos                   d,
             tblctgryarticulocategorizado c,
             tblctgrysectorc              s,
             detallemovmateriales         da
       where d.iddoctrx = p_idDocTrx
         and c.cdsectorc = s.cdserctorc
         and s.dssectorc <> 'NON FOOD'
         and da.cdarticulo = da.cdarticulo
         and d.idmovmateriales = da.idmovmateriales
         and da.cdarticulo = c.cdarticulo
       group by dtdocumento, d.cdcomprobante;

  If v_amdocumento > 0 then
    If substr(v_cdcomprobante,1,2) = 'NC' then

    insert into tblacumdni
      (idacumdni, iddoctrx, iddatoscli, dtdocumento, amdocumento, cdsucursal)
    values
      (sys_guid(), p_idDocTrx, p_iddatoscli, v_dtdocumento, (v_amdocumento * -1), c_Sucursal);
      else
        insert into tblacumdni
      (idacumdni, iddoctrx, iddatoscli, dtdocumento, amdocumento, cdsucursal)
    values
      (sys_guid(), p_idDocTrx, p_iddatoscli, v_dtdocumento, v_amdocumento , c_Sucursal);

    end if;

  end if;
  EXCEPTION
   when no_data_found then
    return;
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       '  Error: ' || SQLERRM);
      RAISE;
  End AcumularSaldoDni;
  
  /**************************************************************************************************
  * function retorna si un dni asociado a un cliente tiene saldo mensual
  * %v 21/11/2018 - JBodnar
  * %v 02/01/2018 - JBodnar: Mira el mes actual
  * %v 20/02/2019 - APW: cambia lógica para que no reusen DNI en el mismo cliente
  *                      y elimino exclusión de CF anónimo 
  ***************************************************************************************************/
  function TieneSaldoDni(p_iddatoscli IN tbldatoscliente.iddatoscli%TYPE)
    return integer as

    v_modulo    VARCHAR2(100) := 'PKG_CLIENTE.TieneSaldoDni';
    v_tiene     integer;
    v_acumulado_id number;
    v_acumulado_dni number;
    r_datoscli  tbldatoscliente%rowtype;
    v_dtdesde  date;
    
  BEGIN

  --Cargo el rango del mes en que estoy parado
  select add_months(last_day(trunc(n_pkg_vitalpos_core.GetDt())), -1)+1
  into  v_dtdesde
  from dual;

    v_tiene := 1;
    begin
      select *
        into r_datoscli
        from tbldatoscliente dc
       where dc.iddatoscli = p_iddatoscli;
    exception
      when no_data_found then
        return v_tiene;
    end;
    -- si es excluido no lo controla
    if EsExcluido(r_datoscli.identidad) = '1' then
      return v_tiene;
    end if;

    -- acumulo por id
    select nvl(sum(a.amdocumento), 0)
      into v_acumulado_id
      from tblacumdni a
     where a.iddatoscli = r_datoscli.iddatoscli
       and a.dtdocumento > v_dtdesde; --Mira el mes actual
    -- si se pasa ya no miro nada más
    if v_acumulado_id >= c_MaxAcum then
      v_tiene := 0;
      return v_tiene;
    end if;

    -- si no se pasó, sigo revisando para mismo dni, mismo cliente
    -- para evitar que "reseteen" volviendo a cargar el mismo dni para un cliente
    select nvl(sum(a.amdocumento), 0)
      into v_acumulado_dni
      from tblacumdni a, tbldatoscliente dc
     where a.iddatoscli = dc.iddatoscli
       and dc.iddatoscli <> r_datoscli.iddatoscli
       and dc.dni = r_datoscli.dni
       and dc.identidad = r_datoscli.identidad
       and a.dtdocumento > v_dtdesde;--Mira el mes actual

    if v_acumulado_dni+v_acumulado_id >= c_MaxAcum then
      v_tiene := 0;
    end if;
    
  return v_tiene;
  
  EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       '  Error: ' || SQLERRM);
      RAISE;

  End TieneSaldoDni;

  /**************************************************************************************************
  * PROCEDURE retorna si un dni asociado a un cliente tiene saldo mensual
  * %v 21/11/2018 - JBodnar
  ***************************************************************************************************/
  PROCEDURE TieneSaldoDni(p_iddatoscli IN tbldatoscliente.iddatoscli%TYPE,
                          p_tiene      OUT integer) as

    v_modulo VARCHAR2(100) := 'PKG_CLIENTE.TieneSaldoDni';

  BEGIN

    p_tiene := TieneSaldoDni(p_iddatoscli);

  EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       '  Error: ' || SQLERRM);
      RAISE;

  End TieneSaldoDni;

  /**************************************************************************************************
  * function retorna si un cliente tiene saldo mensual
  * %v 20/02/2019 - APW: para clientes CF que no usan el tbldatoscliente
  * %v 01/04/2019 - APW: elimino que solo controle facturas
  * %v 05/11/2019 - IAquilano: acumulo por detalle excluyendo NON FOOD
  ***************************************************************************************************/
  function TieneSaldoCliente(p_identidad IN documentos.identidad%TYPE)
    return integer as

    v_modulo    VARCHAR2(100) := 'PKG_CLIENTE.TieneSaldoCliente';
    v_tiene     integer;
    v_acumulado number;
    v_dtdesde date;

  BEGIN
    v_tiene := 1;

  --Cargo el rango del mes en que estoy parado
  select add_months(last_day(trunc(n_pkg_vitalpos_core.GetDt())), -1)+1
  into v_dtdesde
  from dual;

    select nvl(sum(case
                     when substr(d.cdcomprobante, 1, 2) = 'NC' then
                      da.amlinea * -1
                     else
                      da.amlinea
                   end),
               0)
      into v_acumulado
      from documentos                   d,
             tblctgryarticulocategorizado c,
             tblctgrysectorc              s,
             detallemovmateriales         da
     where d.identidad = p_identidad
     and d.idmovmateriales = da.idmovmateriales
     and da.cdarticulo = c.cdarticulo
     and c.cdsectorc = s.cdserctorc
     and s.dssectorc <> 'NON FOOD'
     and dtdocumento > v_dtdesde; --Mira el mes actual

    -- si se pasa ya no miro nada más
    if v_acumulado >= c_MaxAcum then
      v_tiene := 0;
    end if;

    return v_tiene;

  EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       '  Error: ' || SQLERRM);
      RAISE;

  End TieneSaldoCliente;

  /**************************************************************************************************
  * Procedure retorna si un cliente esta o no excluido
  * %v 16/08/2018 - JBodnar
  ***************************************************************************************************/
  Procedure GetDatosExcluidos(p_Nombre    Out TBLDATOS_PERSONALES.NOMBRE%Type,
                              p_Dni       Out TBLDATOS_PERSONALES.NRODOC%Type,
                              p_Domicilio Out TBLDATOS_PERSONALES.DOMICILIO%Type) as

    v_modulo VARCHAR2(100) := 'PKG_CLIENTE.GetDatosExcluidos';
    v_maxID  number;
    v_random number;

  BEGIN

    SELECT max(id_datos_personales) INTO v_maxID FROM TBLDATOS_PERSONALES;

    SELECT trunc(dbms_random.value(1, v_maxID)) INTO v_random FROM DUAL;

    SELECT p.nombre, p.nrodoc, p.domicilio
      into p_Nombre, p_Dni, p_Domicilio
      FROM TBLDATOS_PERSONALES p
     WHERE ID_DATOS_PERSONALES = v_random;

  EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       '  Error: ' || SQLERRM);
      RAISE;
  END GetDatosExcluidos;

  /**************************************************************************************************
  * Dado un cuit valida si es o no valido retornando el correcto
  * %v 17/08/2018 - JBodnar
  ***************************************************************************************************/
  function ValidaCuit(p_cuit number) return number AS

    v_modulo VARCHAR2(100) := 'PKG_CLIENTE.ValidaCuit';
    v_dv     number;
    v_cuit   number;
  begin

    select mod(substr(p_cuit, 1, 1) * 5 + substr(p_cuit, 2, 1) * 4 +
               substr(p_cuit, 3, 1) * 3 + substr(p_cuit, 4, 1) * 2 +
               substr(p_cuit, 5, 1) * 7 + substr(p_cuit, 6, 1) * 6 +
               substr(p_cuit, 7, 1) * 5 + substr(p_cuit, 8, 1) * 4 +
               substr(p_cuit, 9, 1) * 3 + substr(p_cuit, 10, 1) * 2,
               11)
      into v_dv
      from dual;

    case
      when (11 - v_dv) between 1 and 9 then
        v_cuit := p_cuit;
      when v_dv = 1 then
        CASE
          WHEN substr(p_cuit, 1, 2) = 27 then
            v_cuit := 23 || substr(p_cuit, 3, 8) || 4;
          WHEN substr(p_cuit, 1, 2) = 20 then
            v_cuit := 23 || substr(p_cuit, 3, 8) || 9;
          WHEN substr(p_cuit, 1, 2) = 24 then
            v_cuit := 23 || substr(p_cuit, 3, 8) || 3;
          WHEN substr(p_cuit, 1, 2) = 30 then
            v_cuit := 33 || substr(p_cuit, 3, 8) || 9;
          WHEN substr(p_cuit, 1, 2) = 34 then
            v_cuit := 33 || substr(p_cuit, 3, 8) || 3;
        END CASE;
      else
        v_cuit := p_cuit || 0;
    end case;

    return v_cuit;

  EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo ||
                                       '  Error: ' || SQLERRM);
      RAISE;
  END ValidaCuit;

  /****************************************************************************************
  * %v 27/02/2019 JB - Graba los datos del cliente para cargar en la nube de Mercado Libre
  *****************************************************************************************/
  PROCEDURE GrabarEntidadMP(p_Identidad         IN entidades.identidad%TYPE,
                            p_icppoint          IN integer,
                            p_IdPersona         IN contactosentidades.idpersona%TYPE,
                            p_ok                OUT INTEGER,
                            p_error             OUT VARCHAR2) AS
    v_Modulo   VARCHAR2(100) := 'PKG_CLIENTE.GrabarEntidadMP';
    v_existe   integer;
  BEGIN

    SELECT count(*)
      INTO v_existe
      FROM TBLENTIDADMERCADOPAGO c
     WHERE c.identidad = p_Identidad;

    if v_existe > 0 then
      p_ok    := 2;
      p_error := 'El cliente ya esta asociado a mercado pago.';
      return;
    end if;

    INSERT INTO TBLENTIDADMERCADOPAGO
      (identidadmp,
       identidad,
       cdsucursal,
       icppoint,
       idpersonainicio,
       dtinicio,
       idpersonaenvio,
       dtenvio)
    VALUES
      (sys_guid(),
       p_Identidad,
       c_Sucursal,
       p_icppoint,
       p_IdPersona,
       sysdate,
       null,
       null);

    --Alta OK
    COMMIT;
    p_ok    := 1;
    p_error := '';

  EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_Modulo ||
                                       '  Error: ' || SQLERRM);
      p_ok    := 0;
      p_error := '  Error: ' || SQLERRM;
      RAISE;
  END GrabarEntidadMP;

  /****************************************************************************************
  * %v 27/02/2019 JB - Actualiza los datos del cliente para cargar en la nube de Mercado Libre
  *****************************************************************************************/
  PROCEDURE UpdateEntidadMP(p_Identidad IN entidades.identidad%TYPE,
                            p_icppoint  IN integer,
                            p_IdPersona IN contactosentidades.idpersona%TYPE,
                            p_ok        OUT INTEGER,
                            p_error     OUT VARCHAR2) AS
    v_Modulo VARCHAR2(100) := 'PKG_CLIENTE.UpdateEntidadMP';

  BEGIN

    update TBLENTIDADMERCADOPAGO
       set icppoint        = p_icppoint,
           idpersonainicio = p_IdPersona,
           dtinicio        = sysdate
     where identidad = p_Identidad;

    --Alta OK
    COMMIT;
    p_ok    := 1;
    p_error := '';

  EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_Modulo ||
                                       '  Error: ' || SQLERRM);
      p_ok    := 0;
      p_error := '  Error: ' || SQLERRM;
      RAISE;
  END UpdateEntidadMP;

  /****************************************************************************************
  * %v 27/02/2019 JB - Retorna el icpoint del cliente
  *****************************************************************************************/
  PROCEDURE GetIcPoint(p_Identidad IN entidades.identidad%TYPE,
                            p_icppoint  Out integer) AS
    v_Modulo VARCHAR2(100) := 'PKG_CLIENTE.GetIcPoint';

  BEGIN

    begin
    select m.icppoint
    into p_icppoint
    from  TBLENTIDADMERCADOPAGO m
     where identidad = p_Identidad;

   exception when others then
     p_icppoint:=0;
   end;


  EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_Modulo ||
                                       '  Error: ' || SQLERRM);

  END GetIcPoint;

End PKG_CLIENTE;
/
