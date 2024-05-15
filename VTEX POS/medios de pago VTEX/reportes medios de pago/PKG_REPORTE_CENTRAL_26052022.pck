CREATE OR REPLACE PACKAGE PKG_REPORTE_CENTRAL IS

  TYPE cursor_type IS REF CURSOR;

/*+++++++++++++++++++++++++++++creo la temporal para el reporte++++++++
/*ChM cajas sucursales 08/04/2020*/
 TYPE cajasucu IS RECORD   (
    cdsucursal     sucursales.cdsucursal%type,
    dssucursal     sucursales.dssucursal%type,
    fecha        date,
    monto          number
    );

TYPE cajassucursales IS TABLE OF cajasucu INDEX BY BINARY_INTEGER;
Type cajassucursalesPipe Is Table Of cajasucu;
Arreglo_Cajas cajassucursales;
Function Pipecajas Return cajassucursalesPipe Pipelined;

PROCEDURE GetCajaSucursalesGeneralM(p_sucursales      IN Varchar2,
                                    p_fechadesde      IN DATE,
                                    p_fechahasta      IN DATE,
                                    p_cur_out         OUT cursor_type);

/*++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/

  /******************** creo tabla temporal ********************/
  Type reg_chequecomi Is Record(
                            sucursal          VARCHAR2(100),
  ingresorechazado  VARCHAR2(40),
  nroguia           INTEGER,
  cuitcomi          CHAR(15),
  razonsocialcomi   VARCHAR2(100),
  cuit              CHAR(15),
  razonsocial       VARCHAR2(100),
  numerocheque      NUMBER,
  banco             VARCHAR2(100),
  sucbanco          VARCHAR2(100),
  cuentabanco       VARCHAR2(20),
  fechaacreditacion DATE,
  fechaingresosuc   DATE,
  fecharechazo      DATE,
  motivorechazo     VARCHAR2(50),
  tipo              VARCHAR2(10),
  cuit_tercero      VARCHAR2(20),
  importe           NUMBER,
  emision           DATE,
  montodeuda        NUMBER
);

   Type tab_Listachequecomi Is Table Of reg_chequecomi Index By Binary_Integer;

   Type tab_ListachequecomiPipe Is Table Of reg_chequecomi;

     Function Pipechequecomi Return tab_ListachequecomiPipe
      Pipelined;

      Procedure GetNewChequeRechazadoDetalle(p_cdsucursal In tblcuenta.cdsucursal%Type,
                                       p_identidad  In entidades.identidad%Type,
                                       p_fechaDesde In Date,
                                       p_fechaHasta In Date,
                                       p_Debe       IN integer, --si tiene deuda:1--si no tiene deuda:0--todos:null
                                       p_cur_out    Out cursor_type);
/****************************************************************************/
  TYPE reg_efectivo IS RECORD(
  dtmovimiento     tblmovcuenta.dtmovimiento%TYPE,
  dsnombre         personas.dsnombre%TYPE,
  dsapellido       personas.dsapellido%TYPE,
  dsoperacioncaja  tbloperacioncaja.dsoperacioncaja%TYPE,
  ammovimiento     tblmovcaja.ammovimiento%TYPE,
  saldo            tblmovcaja.ammovimiento%TYPE,
  dssucursal       sucursales.dssucursal%TYPE);

  TYPE tab_efectivo IS TABLE OF reg_efectivo;

  TYPE MovimientosCaja IS RECORD(
  dtMovimiento      tblmovcaja.dtmovimiento%TYPE,
  cajero            VARCHAR2(200),
  cdcuit            entidades.cdcuit%TYPE,
  dsrazonsocial     entidades.dsrazonsocial%TYPE,
  nombrecuenta      tblcuenta.nombrecuenta%TYPE,
  descripcion       VARCHAR2(200),
  amdocumento       documentos.amdocumento%TYPE,
  amingreso         tblingreso.amingreso%TYPE,
  estado            VARCHAR2(200),
  cdsucursal        sucursales.cdsucursal%TYPE,
  idtransaccion     tbltransaccion.idtransaccion%TYPE,
  orden             INTEGER);

  TYPE t_MovimientosCaja IS TABLE OF MovimientosCaja;

/***********************************************************************************************/
/*ChM reporte tiempos de cajeros 18/12/2019*/
 TYPE TIEMPO IS RECORD   (
    R_idpersonas             personas.idpersona%type,
    R_DsPersona              personas.dsnombre%type,
    R_MINUTOS                NUMBER);

TYPE TIEMPOS IS TABLE OF TIEMPO INDEX BY BINARY_INTEGER;
Type TIEMPOSPipe Is Table Of TIEMPO;
CAJA_TIEMPOS TIEMPOS;
Function PipeTIEMPOS Return TIEMPOSPipe Pipelined;

/**********************************************************************************************/
  FUNCTION GetClienteComisionista(p_identidad IN tblcuenta.identidad%TYPE)
  RETURN entidades.dsrazonsocial%TYPE;

  FUNCTION GetResponsableDeuda(p_idDocTrx IN documentos.iddoctrx%TYPE)
  RETURN VARCHAR2;

  FUNCTION SetSucursalesSeleccionadas(p_listaSucursales IN VARCHAR2) RETURN VARCHAR2;

  PROCEDURE CleanSucursalesSeleccionadas(p_idReporte  IN VARCHAR2);

  FUNCTION SeleccionarCuenta(p_idCuentaPrincipal IN tblcuenta.idcuenta%TYPE,
                          p_cdTipoCuenta      IN tblcuenta.cdtipocuenta%TYPE)
  RETURN tblcuenta.idcuenta%TYPE;

  FUNCTION EsCFAnonimo(p_ident ENTIDADES.IDENTIDAD%TYPE) RETURN INTEGER;

  FUNCTION GetPersona(p_idPersona IN personas.idpersona%TYPE) RETURN VARCHAR2;

  FUNCTION GetRazonSocial(p_identidad in entidades.identidad%type) RETURN entidades.dsrazonsocial%type;

  PROCEDURE GetPersonas(p_NombreApellido IN VARCHAR2,
                     p_cdrol          IN rolespersonas.cdrol%TYPE,
                     p_cur_out        OUT cursor_type);

  FUNCTION GetSaldo(p_cdConfIngreso IN tblconfingreso.cdconfingreso%TYPE,
                 p_cdSucursal    IN sucursales.cdsucursal%TYPE) RETURN NUMBER;

  FUNCTION GetDescEstadoIngreso(p_cdestado IN tblingreso.cdestado%TYPE)
  RETURN tblestadoingreso.dsestado%TYPE;

  FUNCTION GetDescIngreso(p_cdConfIngreso IN tblconfingreso.cdconfingreso%TYPE,
                     p_cdSucursal    IN sucursales.cdsucursal%TYPE) RETURN VARCHAR2;

  FUNCTION GetDescDocumento(p_idDocTrx IN documentos.iddoctrx%TYPE) RETURN VARCHAR2;

  FUNCTION GetOtorgado(p_idCuenta IN tblcuenta.idcuenta%TYPE) RETURN tblcuenta.amotorgado%TYPE;

  PROCEDURE GetPersonasCajeros(p_cur_out OUT cursor_type);

  FUNCTION GetPeriodoAging(p_diasDeuda IN NUMBER) RETURN NUMBER;

  PROCEDURE GetMonitoreoCajasTesoreras(p_cur_out OUT cursor_type);

  PROCEDURE GetEstadosComprobantes(p_cdcomprobante IN estadocomprobantes.cdcomprobante%TYPE,
                                p_cur_out       OUT cursor_type);

  PROCEDURE GetIngresosPorDocumento(p_idDocTrx IN documentos.iddoctrx%TYPE,
                                 p_cur_out  OUT cursor_type);

  PROCEDURE GetDocumentosPorIngreso(p_idingreso IN tblingreso.idingreso%TYPE,
                     p_cur_out   OUT cursor_type);

  PROCEDURE GetAcreditaciones(p_cdCuit       IN entidades.cdcuit%TYPE,
                           p_idcuenta     IN tblcuenta.idcuenta%TYPE,
                           p_fechaDesde   IN DATE,
                           p_fechaHasta   IN DATE,
                           p_cur_out      OUT cursor_type);

  PROCEDURE GetFacturacionPorCanal(p_idcuenta IN documentos.idcuenta%TYPE,
                               p_id_canal IN movmateriales.id_canal%TYPE,
                               p_cur_out  OUT cursor_type);

  PROCEDURE GetClientesPorAltaGeneral(p_cdregion   IN tblregion.cdregion%TYPE,
                                   p_sucursales IN VARCHAR2,
                                   p_identidad  IN entidades.identidad%TYPE,
                                   p_FechaDesde IN DATE,
                                   p_FechaHasta IN DATE,
                                   p_cur_out    OUT cursor_type);

  PROCEDURE GetClientesPorAltaDetalle(p_cdsucursal IN tblcuenta.cdsucursal%TYPE,
                                   p_identidad  IN entidades.identidad%TYPE,
                       p_FechaDesde IN DATE,
                                   p_FechaHasta IN DATE,
                                   p_cur_out    OUT cursor_type) ;

  PROCEDURE GetCreditosOtorgadosGeneral(p_cdregion     IN tblregion.cdregion%TYPE,
                                     p_sucursales   IN VARCHAR2,
                                     p_identidad    IN entidades.identidad%TYPE,
                                     p_idcuenta     IN tblcuenta.idcuenta%TYPE,
                                     p_creditoDesde IN tblcuenta.amotorgado%TYPE,
                                     p_creditoHasta IN tblcuenta.amotorgado%TYPE,
                                     p_cur_out      OUT cursor_type);

  function GetSaldoFactura(p_idDocTrx        in documentos.iddoctrx%type,
                       p_dtHasta         in date default null,
                       p_icForzarCalculo in number default 0) return number;

  PROCEDURE GetCreditosOtorgadosDetalle(p_cdsucursal   IN tblcuenta.cdsucursal%TYPE,
                                     p_identidad    IN entidades.identidad%TYPE,
                                     p_idcuenta     IN tblcuenta.idcuenta%TYPE,
                                     p_creditoDesde IN tblcuenta.amotorgado%TYPE,
                                     p_creditoHasta IN tblcuenta.amotorgado%TYPE,
                                     p_cur_out      OUT cursor_type);

  PROCEDURE GetFacturacionGeneral(p_cdregion   IN tblregion.cdregion%TYPE,
                               p_sucursales IN VARCHAR2,
                               p_identidad  IN entidades.identidad%TYPE,
                               p_idcuenta   IN tblcuenta.idcuenta%TYPE,
                               p_filtro     IN INTEGER,
                               p_fechaDesde IN DATE,
                               p_fechaHasta IN DATE,
                               p_cur_out    OUT cursor_type);

  PROCEDURE GetFacturacionDetalle(p_cdsucursal IN tblcuenta.cdsucursal%TYPE,
                               p_identidad  IN entidades.identidad%TYPE,
                    p_idcuenta   IN tblcuenta.idcuenta%TYPE,
                               p_fechaDesde IN DATE,
                               p_fechaHasta IN DATE,
                               p_filtro     IN INTEGER,
                               p_cur_out    OUT cursor_type);

  PROCEDURE GetIngresosGeneral(p_cdregion     IN tblregion.cdregion%TYPE,
                          p_sucursales   IN VARCHAR2,
                          p_fechaDesde IN DATE,
                  p_fechaHasta IN DATE,
                  p_cdmedio    IN tblconfingreso.cdmedio%TYPE,
                  p_cdtipo     IN tblconfingreso.cdtipo%TYPE,
                  p_identidad  IN tblcuenta.identidad%TYPE,
                  p_idcuenta   IN tblcuenta.idcuenta%TYPE,
                  p_cur_out    OUT cursor_type);

  PROCEDURE GetIngresosDetalle(p_cdsucursal IN tblcuenta.cdsucursal%TYPE,
                            p_identidad  IN entidades.identidad%TYPE,
                  p_idcuenta   IN tblcuenta.idcuenta%TYPE,
                            p_fechaDesde IN DATE,
                            p_fechaHasta IN DATE,
                            p_cdmedio    IN tblconfingreso.cdmedio%TYPE,
                            p_cdtipo     IN tblconfingreso.cdtipo%TYPE,
                            p_cur_out    OUT cursor_type);

  Procedure GetFormaDePago(p_sucursales In Varchar2,
                         p_fechaDesde In Date,
                         p_fechaHasta In Date ,
                         p_cur_out Out cursor_type);

  function GetDeudaCheque(p_idIngresoCheque in tblingreso.idingreso%type)
   return number;

  Procedure GetChequesDetalle(p_cdsucursal      IN tblcuenta.cdsucursal%Type,
                             p_identidad       IN entidades.identidad%Type,
                             p_idcuenta        IN tblcuenta.idcuenta%Type,
                             p_fechaDesde      IN Date,
                             p_fechaHasta      IN Date,
                             p_cdestado        IN Integer,
                             p_cdmotivorechazo IN tblmotivorechazo.cdmotivorechazo%type,
                             p_cur_out         OUT cursor_type) ;

  Procedure GetChequesDetalleCO(p_sucursales       IN  tblcuenta.cdsucursal%Type            ,
                               p_idcomisionista   IN  entidades.identidad%Type             ,
                               p_fechaDesde       IN  Date                                 ,
                               p_fechaHasta       IN  Date                                 ,
                               p_cdestado         IN  Integer                              ,
                               p_cdmotivorechazo  IN  tblmotivorechazo.cdmotivorechazo%type,
                               p_cur_out          OUT cursor_type                          );


  Procedure GetChequeRechazadoDetalle(p_cdsucursal      IN tblcuenta.cdsucursal%Type,
                                    p_identidad       IN entidades.identidad%Type,
                                    p_idcuenta        IN tblcuenta.idcuenta%Type,
                                    p_fechaDesde      IN Date,
                                    p_fechaHasta      IN Date,
                                    p_Debe            IN integer,
                                    p_cur_out         OUT cursor_type);

  PROCEDURE GetCuentaCorrienteDetalle(p_identidad  IN entidades.identidad%TYPE,
                                   p_idcuenta   IN tblcuenta.idcuenta%TYPE,
                                   p_fechaDesde IN DATE,
                                   p_fechaHasta IN DATE,
                                   p_cur_out    OUT cursor_type);

  PROCEDURE GetCuentaCorrienteDetalleDrill( p_idcuenta    IN  tblmovcuenta.idcuenta%TYPE     ,
                                        p_sqmovcuenta IN  tblmovcuenta.sqmovcuenta%TYPE  ,
                                        p_cur_out     OUT              cursor_type       );

  FUNCTION GetFacturacionAnterior(p_idCuenta IN tblcuenta.idcuenta%TYPE, p_aniomes IN NUMBER)
  RETURN documentos.amdocumento%TYPE;

  PROCEDURE GetDeudoresPorVentaGeneral(p_sucursales  IN VARCHAR2,
                                    p_identidad   IN entidades.identidad%TYPE,
                                    p_idcuenta    IN tblcuenta.idcuenta%TYPE,
                                    p_cur_out     OUT cursor_type);

  PROCEDURE GetDeudoresPorVentaDetalle(p_cdsucursal  IN  sucursales.cdsucursal%TYPE,
                       p_identidad   IN  entidades.identidad%TYPE,
                       p_idcuenta    IN  tblcuenta.idcuenta%TYPE,
                       p_cur_out    OUT cursor_type);

  PROCEDURE GetDeudoresMorososGeneral(p_sucursales  IN VARCHAR2,
                                   p_identidad   IN entidades.identidad%TYPE,
                                   p_idcuenta    IN tblcuenta.idcuenta%TYPE,
                                   p_cur_out     OUT cursor_type);

  PROCEDURE GetDeudoresMorososDetalle(p_cdsucursal  IN sucursales.cdsucursal%TYPE,
                                   p_identidad   IN entidades.identidad%TYPE,
                                   p_idcuenta    IN tblcuenta.idcuenta%TYPE,
                                   p_cur_out     OUT cursor_type);

  PROCEDURE GetRankingDeudoresGeneral(p_cdregion     IN tblregion.cdregion%TYPE,
                      p_sucursales   IN VARCHAR2,
                      p_cur_out      OUT cursor_type);


  PROCEDURE GetRankingDeudoresPorSucursal(p_cdregion   IN tblregion.cdregion%TYPE,
                         p_sucursales IN VARCHAR2,
                         p_cur_out    OUT cursor_type);

  PROCEDURE GetAgingDeudaGeneral(p_cdregion   IN tblregion.cdregion%TYPE,
                              p_sucursales IN VARCHAR2,
                              p_identidad  IN entidades.identidad%TYPE,
                              p_idcuenta   IN tblcuenta.idcuenta%TYPE,
                              p_cur_out    OUT cursor_type);

  PROCEDURE GetAgingDeudaDetalle(p_cdsucursal IN sucursales.cdsucursal%TYPE,
                              p_identidad  IN entidades.identidad%TYPE,
                              p_idcuenta   IN tblcuenta.idcuenta%TYPE,
                              p_cur_out    OUT cursor_type);

  PROCEDURE GetAcreditacionPosnetGeneral(p_cdregion     IN  tblregion.cdregion%TYPE,
                                      p_sucursales   IN VARCHAR2,
                                      p_identidad    IN entidades.identidad%TYPE,
                                      p_idcuenta     IN tblcuenta.idcuenta%TYPE,
                                      p_fechaDesde   IN DATE,
                                      p_fechaHasta   IN DATE,
                                      p_cdforma      IN tblformaingreso.cdforma%TYPE,
                                      p_cur_out      OUT cursor_type);

  PROCEDURE GetAcreditacionPosnetDetalle(p_cdsucursal   IN  sucursales.cdsucursal%TYPE,
                                      p_identidad    IN  entidades.identidad%TYPE,
                                      p_idcuenta     IN  tblcuenta.idcuenta%TYPE,
                                      p_fechaDesde   IN  DATE,
                                      p_fechaHasta   IN  DATE,
                                      p_cdforma      IN tblformaingreso.cdforma%TYPE,
                                      p_cur_out      OUT cursor_type);

  PROCEDURE GetDiferenciaDeCajasGeneral(p_sucursales IN VARCHAR2,
                                     p_idpersona  IN tbltesoro.idpersona%TYPE,
                                     p_fechaDesde IN DATE,
                                     p_fechaHasta IN DATE,
                                     p_cur_out    OUT cursor_type);

  PROCEDURE GetDiferenciaDeCajasDetalle(p_cdsucursal   IN  sucursales.cdsucursal%TYPE,
                         p_idpersona    IN tbltesoro.idpersona%TYPE,
                                    p_fechaDesde   IN  DATE,
                         p_fechaHasta   IN  DATE,
                           p_cur_out      OUT cursor_type);

  PROCEDURE GetFacturasPendientesGeneral(p_sucursales IN VARCHAR2,
                                      p_identidad  IN entidades.identidad%TYPE,
                                      p_idcuenta   IN tblcuenta.idcuenta%TYPE,
                                      p_cur_men7   OUT cursor_type,
                                      p_cur_may7   OUT cursor_type);

  PROCEDURE GetFacturasPendientesDetalle(p_cdsucursal IN sucursales.cdsucursal%TYPE,
                                       p_cur_men7    OUT cursor_type,
                         p_cur_may7    OUT cursor_type);

  PROCEDURE GetFacturasPendientesPopup(p_idCanal    IN movmateriales.id_canal%TYPE,
                                    p_cdSucursal IN sucursales.cdsucursal%TYPE,
                                    p_cur_out    OUT cursor_type);

  PROCEDURE GetAgingPopup(p_idcuenta   IN tblcuenta.idcuenta%TYPE,
                       p_periodo    IN varchar2,
                       p_cur_out    OUT cursor_type);

  FUNCTION GetMovimientosEfectivo(p_cdsucursal    IN sucursales.cdsucursal%TYPE,
                               p_idpersona     IN tbltesoro.idpersona%TYPE,
                               p_fechaDesde    IN DATE,
                               p_fechaHasta    IN DATE)
  RETURN tab_efectivo PIPELINED;

  PROCEDURE GetMovimientosEfectivoDetalle(p_cdsucursal    IN sucursales.cdsucursal%TYPE,
                                     p_idpersona     IN tbltesoro.idpersona%TYPE,
                                       p_fechaDesde    IN DATE,
                                       p_fechaHasta    IN DATE,
                                       p_cur_out       OUT cursor_type);

  PROCEDURE GetGuiasPorFleteroGeneral(p_sucursales IN VARCHAR2,
                                   p_identidad  IN entidades.identidad%TYPE,
                                   p_fechaDesde IN DATE,
                                   p_fechaHasta IN DATE,
                      p_estado     IN documentos.cdestadocomprobante%TYPE,
                                   p_cur_out    OUT cursor_type);

  PROCEDURE GetGuiasPorFleteroDetalle(p_cdsucursal IN sucursales.cdsucursal%TYPE,
                                   p_identidad  IN entidades.identidad%TYPE,
                                   p_fechaDesde IN DATE,
                                   p_fechaHasta IN DATE,
                      p_estado     IN documentos.cdestadocomprobante%TYPE,
                                   p_cur_out    OUT cursor_type);

  PROCEDURE GetDiferenciaDeAliviosGeneral(p_cdRegion   IN tblregion.cdregion%TYPE,
                                       p_sucursales IN VARCHAR2,
                                       p_idPersona  IN tblmovcaja.idpersonaresponsable%TYPE,
                                       p_fechaDesde IN DATE,
                                       p_fechaHasta IN DATE,
                                       p_cur_out    OUT cursor_type);

  PROCEDURE GetDiferenciaDeAliviosDetalle(p_cdsucursal    IN sucursales.cdsucursal%TYPE,
                                     p_idpersona     IN tbltesoro.idpersona%TYPE,
                                       p_fechaDesde    IN DATE,
                                       p_fechaHasta    IN DATE,
                         p_cur_out       OUT cursor_type);

  PROCEDURE GetEgresosTesoreroGeneral( p_cdRegion   IN tblregion.cdregion%TYPE,
                                    p_sucursales IN VARCHAR2,
                       p_idPersona  IN tbltesoro.idpersona%TYPE,
                                    p_fechaDesde IN DATE,
                                    p_fechaHasta IN DATE,
                       p_cur_out OUT cursor_type);

  PROCEDURE GetEgresosTesoreroDetalle(p_cdsucursal    IN sucursales.cdsucursal%TYPE,
                         p_idPersona  IN tbltesoro.idpersona%TYPE,
                                   p_fechaDesde    IN DATE,
                                   p_fechaHasta    IN DATE,
                      p_cur_out OUT cursor_type);

  PROCEDURE GetRankingTelemarketers(p_idTelemarketer IN pedidos.idpersonaresponsable%TYPE,
                               p_sucursales     IN VARCHAR2,
                                 p_fechaDesde     IN DATE,
                                 p_fechaHasta     IN DATE,
                                 p_cur_out        OUT cursor_type);

  PROCEDURE GetEstadisticaVendedores(p_idVendedor IN pedidos.idvendedor%TYPE,
                                  p_sucursales IN VARCHAR2,
                                  p_fechaDesde IN DATE,
                                  p_fechaHasta IN DATE,
                                  p_cur_out    OUT cursor_type);

  PROCEDURE GetAuditoriaBlanqueo(p_sucursales    IN VARCHAR2,
                            p_fechaDesde    IN  DATE,
                            p_fechaHasta    IN  DATE,
                            p_idEntidad     IN  entidades.identidad%type,
                            p_cur_out       OUT cursor_type);

  PROCEDURE GetPedidosGeneral(p_sucursales IN VARCHAR2,
                  p_idEntidad  IN entidades.identidad%TYPE,
                  p_idCuenta   IN tblcuenta.idcuenta%TYPE,
                  p_estado     IN NUMBER,
                  p_fechaDesde IN DATE,
                  p_fechaHasta IN DATE,
                  p_canal      IN VARCHAR2,
                  cur_out      OUT cursor_type);

  PROCEDURE GetInformeJefeVentasGeneral(p_sucursales IN VARCHAR2,
                                     p_identidad  IN entidades.identidad%TYPE,
                                     p_idPersona  IN personas.idpersona%TYPE,
                                     p_idCuenta   IN tblcuenta.idcuenta%TYPE,
                                     p_fechaDesde IN DATE,
                                     p_fechaHasta IN DATE,
                                     p_canal      IN pedidos.id_canal%TYPE,
                                     cur_out      OUT cursor_type);

   Procedure getpedidostlkveco (p_fechadesde IN documentos.dtdocumento%type,
                                p_fechahasta IN documentos.dtdocumento%type,
                                p_cur_out      OUT cursor_type);

  PROCEDURE GetInformeJefeVentasDetalle(p_sucursal   IN sucursales.cdsucursal%TYPE,
                                     p_identidad  IN entidades.identidad%TYPE,
                                     p_idPersona  IN personas.idpersona%TYPE,
                                     p_idCuenta   IN tblcuenta.idcuenta%TYPE,
                                     p_fechaDesde IN DATE,
                                     p_fechaHasta IN DATE,
                                     p_canal      IN pedidos.id_canal%TYPE,
                                     cur_out      OUT cursor_type);

  PROCEDURE GetEgresosTesoro(p_sucursales IN VARCHAR2,
                          p_cdMedio    IN tblconfingreso.cdmedio%TYPE,
                          p_fechaDesde IN DATE,
                p_fechaHasta IN DATE,
                          p_cur_out    OUT cursor_type);


  PROCEDURE GetMovimientosEfectivoGeneral(p_cdregion   IN tblregion.cdregion%TYPE,
                         p_sucursales IN VARCHAR2,
                         p_idPersona  IN tblmovcaja.idpersonaresponsable%TYPE,
                         p_fechaDesde IN DATE,
                         p_fechaHasta IN DATE,
                         p_cur_out    OUT cursor_type);

  PROCEDURE GetDatosFacturista (p_cdsucursal in sucursales.cdsucursal%type,
                            p_cursor_out out cursor_type);

  PROCEDURE GetExcencionesImpositivas(p_idCuenta  IN tblcuenta.idcuenta%TYPE,
                                   p_cur_out   OUT cursor_type);

  PROCEDURE GetMovimientosDeCajaGeneral(p_idpersona  IN tbltesoro.idpersona%TYPE,
                        p_cdMedio    IN tblconfingreso.cdmedio%TYPE,
                        p_fechaDesde IN DATE,
                        p_fechaHasta IN DATE,
                                     p_idCuenta   IN tblcuenta.idcuenta%TYPE,
                        p_sucursales IN VARCHAR2,
                        p_cur_out    OUT cursor_type);

  PROCEDURE GetListadoDeFacturasGeneral(p_idCajero   IN     documentos.idpersona%TYPE,
                        p_identidad  IN     documentos.identidad%TYPE,
                        p_idCuenta   IN     documentos.idcuenta%TYPE,
                        p_CF         IN     INTEGER,
                        p_fechaDesde IN DATE,
                        p_fechaHasta IN DATE,
                        p_sucursales IN VARCHAR2,
                        p_cur_out    OUT cursor_type);

  FUNCTION GetImporteNoAplicado(p_idIngreso in tblingreso.idingreso%type) return number;

  PROCEDURE GetChequesTodos(p_cdsucursal      In tblcuenta.cdsucursal%Type,
                         p_identidad    IN entidades.identidad%TYPE,
                         p_idcuenta        In tblcuenta.idcuenta%Type,
                         p_fechaDesde   IN DATE,
                         p_fechaHasta   IN DATE,
                         p_cdmotivorechazo In tblmotivorechazo.cdmotivorechazo%type,
                         p_cur_out      OUT cursor_type);

  PROCEDURE GetChequesAcreditados(p_cdsucursal      In tblcuenta.cdsucursal%Type,
                               p_identidad    IN entidades.identidad%TYPE,
                               p_idcuenta        In tblcuenta.idcuenta%Type,
                               p_fechaDesde   IN DATE,
                               p_fechaHasta   IN DATE,
                               p_cur_out      OUT cursor_type);

  PROCEDURE GetChequesNoAcreditados(p_cdsucursal      In tblcuenta.cdsucursal%Type,
                                 p_identidad    IN entidades.identidad%TYPE,
                                 p_idcuenta        In tblcuenta.idcuenta%Type,
                                 p_fechaDesde   IN DATE,
                                 p_fechaHasta   IN DATE,
                                 p_cur_out      OUT cursor_type);

  PROCEDURE GetChequesRechazadosResumido(p_cdsucursal      In tblcuenta.cdsucursal%Type,
                                      p_identidad    IN entidades.identidad%TYPE,
                                      p_idcuenta        In tblcuenta.idcuenta%Type,
                                      p_fechaDesde   IN DATE,
                                      p_fechaHasta   IN DATE,
                                      p_cdmotivorechazo In tblmotivorechazo.cdmotivorechazo%type,
                                      p_cur_out      OUT cursor_type);

  PROCEDURE GetPosnetBancoDisponible(p_identidad  IN entidades.identidad%TYPE,
                                  p_idcuenta   IN tblcuenta.idcuenta%TYPE,
                                  p_fechaDesde IN DATE,
                                  p_fechaHasta IN DATE,
                                  p_cdtipo     IN tblconfingreso.cdtipo%TYPE,
                                  p_cur_out    OUT cursor_type);

  PROCEDURE GetGrupos(p_cdSector   IN Sectores.CDSECTOR%TYPE,
                    p_cur_out    OUT cursor_type);

  PROCEDURE GetSectores (p_cur_out    OUT cursor_type);

  PROCEDURE GetListaPrecios(p_cdSucursal IN tblprecio.cdsucursal%TYPE,
                         p_idCanal    IN tblprecio.id_canal%TYPE,
                         p_cdSector   IN sectores.cdsector%TYPE,
                         p_cdGrupo    IN gruposarticulo.cdgrupoarticulos%TYPE,
                         p_cur_out    OUT cursor_type,
                         p_preciolista IN integer default 0,
                         p_qtstock in integer default 0);

  PROCEDURE GetVentaSucursalGeneral (p_sucursales IN VARCHAR2,
                                 p_fechadesde in   date,
                                 p_fechahasta in   date,
                                 p_cur_out    OUT cursor_type);

  FUNCTION GetDescMotivoDoc(p_idmotivodoc tbldocumento_control.idmotivodoc%type)
  RETURN varchar2;

  PROCEDURE GetDevolucionEfectivo (p_sucursales   IN VARCHAR2,
                               p_fechadesde in   date,
                               p_fechahasta in   date,
                               p_cur_out    OUT cursor_type);

  PROCEDURE GetReporteRendicionesPorGuia (p_idguiadetransporte IN  guiasdetransporte.idguiadetransporte%TYPE ,
                                      p_cur_out            OUT                   cursor_type             ,
                                      p_ok                 OUT                   INTEGER                 ,
                                      p_error              OUT                   VARCHAR2                );

  PROCEDURE GetPorcentajeMediosRendGuiaCO  ( p_idcomisionista IN  documentos.identidad%TYPE ,
                                         p_fechadesde     IN  DATE                      ,
                                         p_fechahasta     IN  DATE                      ,
                                         p_sucursales     IN  VARCHAR2                  ,
                                         p_cur_out        OUT cursor_type               ,
                                         p_ok             OUT INTEGER                   ,
                                         p_error          OUT VARCHAR2                  );

  PROCEDURE GetMontosMediosRendidoGuiaCO ( p_idcomisionista IN  documentos.identidad%TYPE ,
                                       p_fechadesde     IN  DATE                      ,
                                       p_fechahasta     IN  DATE                      ,
                                       p_sucursales     IN  VARCHAR2                  ,
                                       p_cur_out        OUT cursor_type               ,
                                       p_ok             OUT INTEGER                   ,
                                       p_error          OUT VARCHAR2                  );

  PROCEDURE GetClientesActivosComisionista ( p_idcomisionista IN  documentos.identidad%TYPE            ,
                                         p_diasactivo     IN  INTEGER                   DEFAULT 30 ,
                                         p_cur_out        OUT cursor_type                          ,
                                         p_ok             OUT INTEGER                              ,
                                         p_error          OUT VARCHAR2                             );

  PROCEDURE GetSaldoClientesComisionista   (p_idcomisionista  IN  documentos.identidad%TYPE  ,
                                        p_cur_out         OUT cursor_type                ,
                                        p_ok              OUT INTEGER                    ,
                                        p_error           OUT VARCHAR2                   );

  PROCEDURE GetCuentaTransportista (p_sucursales IN VARCHAR2,
                                p_fechadesde in   date,
                                p_fechahasta in   date,
                                p_cur_out    OUT cursor_type);

  PROCEDURE GetFactPendienteDeAnular (p_sucursales IN  VARCHAR2,
                                  p_fechahasta in  date,
                                  p_fechadesde in  date,
                                  p_identidad  IN entidades.identidad%TYPE,
                                  cur_out      OUT cursor_type);

  PROCEDURE GetCuentaDeudoresGeneral (p_sucursales IN  VARCHAR2,
                                  p_fechahasta in  date,
                                  p_identidad  IN entidades.identidad%TYPE,
                                  p_cdestado   in  tbldocumentodeuda.cdestado%type,
                                  cur_out      OUT cursor_type);

  PROCEDURE GetCuentaDeudoresDetalle (p_cdsucursal  IN  sucursales.cdsucursal%TYPE,
                                  p_fechahasta in  date,
                                  p_identidad  IN entidades.identidad%TYPE,
                                  p_cdestado   in  tbldocumentodeuda.cdestado%type,
                                  cur_out      OUT cursor_type);

  PROCEDURE GetCuentaAnticipoPosnet (p_sucursales IN  VARCHAR2,
                                 p_fechahasta in  date,
                                 p_cur_out    OUT cursor_type);

  PROCEDURE GetCuentaIngresoPosnet (p_sucursales IN  VARCHAR2,
                                p_fechadesde in  date,
                                p_fechahasta in  date,
                                p_cur_out    OUT cursor_type);

  PROCEDURE GetDetalleConteoCompleto( p_fechadesde in  date,
                            p_fechahasta in  date,
                            p_cdgrupocontrol in tblcontrolstock.cdgrupocontrol%TYPE,
                            p_cdarticulo     in tblcontrolstock.cdarticulo%TYPE,
                            p_sucursales IN  VARCHAR2,
                            p_cur_out    OUT cursor_type);

  PROCEDURE GetDeudaEgresos (p_sucursales IN  VARCHAR2,
                         p_fechadesde in  date,
                         p_fechahasta in  date,
                         p_cur_out    OUT cursor_type);


  PROCEDURE GetCuentaAnticipoCliente (p_sucursales IN  VARCHAR2,
                                  p_fechahasta in  date,
                                  p_cur_out    OUT cursor_type);
                                  
  PROCEDURE GetCuentaAnticipoCliAbierto (p_cdsucursal IN  VARCHAR2,
                                         p_fecha IN DATE,
                                         p_cur_out    OUT cursor_type);
                                         

  PROCEDURE GetSaldosPorGuiaComisionista( p_sucursales     IN            VARCHAR2       ,
                                      p_fechadesde     IN            DATE           ,
                                      p_fechahasta     IN            DATE           ,
                                      p_idcomisionista IN  entidades.identidad%TYPE ,
                                      p_cur_out        OUT           cursor_type    ,
                                      p_ok             OUT           INTEGER        ,
                                      p_error          OUT           VARCHAR2       );

  PROCEDURE GetPedidosTiempo (p_sucursales IN  VARCHAR2,
                          p_fechadesde in  date,
                          p_fechahasta in  date,
                          p_cur_out    OUT cursor_type) ;

  FUNCTION GetCuentaComi(p_idcomisionista IN entidades.identidad%TYPE) RETURN tblcuenta.idcuenta%TYPE;

  FUNCTION GetDeudaComisionistaEnGuias( p_idcomisionista IN documentos.identidad%TYPE ) RETURN NUMBER;

  FUNCTION GetDiasVisita (p_identidad in entidades.identidad%type,
                    p_idvendedor in personas.idpersona%type) return varchar2;

  PROCEDURE GetVentaDetalleCliente(p_sucursal   IN sucursales.cdsucursal%TYPE,
                             p_idPersona  IN personas.idpersona%TYPE,
                             p_fechaDesde IN DATE,
                             p_fechaHasta IN DATE,
                             cur_out      OUT cursor_type);

  PROCEDURE GetEstadoGuiaTransporte ( p_idguiadetransporte IN  guiasdetransporte.idguiadetransporte%TYPE ,
                                  p_montoticket        OUT                   NUMBER                  ,
                                  p_montointerdeposito OUT                   NUMBER                  ,
                                  p_montoefectivopesos OUT                   NUMBER                  ,
                                  p_montoefectivodolar OUT                   NUMBER                  ,
                                  p_cur_out            OUT                   cursor_type             );

  PROCEDURE GetEstadosPagare(p_cur_out OUT cursor_type);

  PROCEDURE GetPagares(      p_sucursales          IN VARCHAR2,
                          p_idcuenta            IN tblcuenta.idcuenta%TYPE,
                           p_identidad           IN entidades.identidad%TYPE,
                           p_dtIngreso           IN tblingreso.dtingreso%TYPE,
                           p_dtIngresoHasta      IN tblingreso.dtingreso%TYPE,
                           p_cdestadocomprobante IN documentos.cdestadocomprobante%TYPE,
                           p_cur_out             OUT cursor_type);

  PROCEDURE GetEfectivoDolar(p_cdsucursal IN tblcuenta.cdsucursal%TYPE,
                            p_identidad  IN entidades.identidad%TYPE,
                            p_idcuenta   IN tblcuenta.idcuenta%TYPE,
                            p_fechaDesde IN DATE,
                            p_fechaHasta IN DATE,
                            p_cur_out    OUT cursor_type);

  PROCEDURE GetControlStockConteo(p_sucursales IN  VARCHAR2,
                                p_fechadesde in  date,
                                p_fechahasta in  date,
                                p_cdgrupocontrol in tblcontrolstock.cdgrupocontrol%TYPE,
                                p_cdarticulo     in tblcontrolstock.cdarticulo%TYPE,
                                p_cur_out    OUT cursor_type);

    PROCEDURE GetDetalleConteo( p_fechadesde in  date,
                            p_fechahasta in  date,
                            p_cdgrupocontrol in tblcontrolstock.cdgrupocontrol%TYPE,
                            p_cdarticulo     in tblcontrolstock.cdarticulo%TYPE,
                            p_sucursal       in tblcontrolstock.cdsucursal%TYPE,
                            p_cur_out    OUT cursor_type);

  PROCEDURE GetVolumenCompraGeneral (p_sucursales IN VARCHAR2,
                          p_minimo in   integer,
                          p_cur_out    OUT cursor_type);

  PROCEDURE GetVolumenCompraDetalle (p_idcuenta IN tblfacturacionhistorica.idcuenta%TYPE,
                                 p_minimo in   integer,
                                 p_cur_out    OUT cursor_type);

  PROCEDURE GetFacturasPendientesListado(p_cdSucursal IN sucursales.cdsucursal%TYPE,
                                      p_fecha in documentos.dtdocumento%TYPE,
                                    p_cur_out    OUT cursor_type);

  PROCEDURE GetCobroComisionistas(p_sucursales          IN VARCHAR2,
                               p_comisionista        IN entidades.identidad%type,
                               p_dtdesde           IN date,
                               p_dthasta     IN date,
                               p_cur_out             OUT cursor_type);

  PROCEDURE GetUbicacionMateriales (p_cdsector IN  sectores.cdsector%TYPE,
                                p_cdgrupo IN gruposarticulo.cdgrupoarticulos%TYPE,
                                p_control IN tblcontrolstock.cdgrupocontrol%TYPE,
                                p_sucursal IN VARCHAR2,
                                p_cur_out    OUT cursor_type);

  Procedure GetCuponesRechazadosDetalle(p_cdsucursal      In tblcuenta.cdsucursal%Type,
                                   p_identidad       In entidades.identidad%Type,
                                   p_idcuenta        In tblcuenta.idcuenta%Type,
                                   p_fechaDesde      In Date,
                                   p_fechaHasta      In Date,
                                   p_lote            IN tblcierrelote.vlcierrelote%TYPE,
                                   p_cur_out         Out cursor_type);

  PROCEDURE GetCamionesPorDia( p_sucursales IN VARCHAR2,
                            p_fechaDesde IN DATE,
                            p_fechaHasta IN DATE,
                            p_cur_out    OUT cursor_type);

  PROCEDURE GetPedidosSelectivos(p_sucursales          IN VARCHAR2,
                         p_dtdesde             IN date,
                         p_dthasta             IN date,
                         p_cur_out             OUT cursor_type);

  PROCEDURE GetDescuentoPersonal(p_sucursales IN VARCHAR2,
                       p_fechadesde in date,
                       p_fechahasta in date,
                       p_idpersona  in personas.idpersona%type,
                       p_cur_out    OUT cursor_type);

  PROCEDURE GetCarteraVendedores (p_sucursales IN  VARCHAR2,
                           p_cur_out    OUT cursor_type);

  PROCEDURE GetCarteraVendedoresDetalle (p_idpersona IN  clientesviajantesvendedores.idviajante%TYPE,
                                  p_cdsucursal IN clientesviajantesvendedores.cdsucursal%TYPE,
                           p_cur_out    OUT cursor_type);

  FUNCTION GetCdEstadoFC  ( p_iddoctrx  IN documentos.iddoctrx%type,
                  p_cdestado  IN documentos.cdestadocomprobante%type,
                  p_amnetodocumento in documentos.amnetodocumento%type )
                  RETURN documentos.cdestadocomprobante%type;

  FUNCTION GetDesEstadoFC ( p_iddoctrx        IN documentos.iddoctrx%type,
                  p_cdcomprobante   IN documentos.cdcomprobante%type,
                  p_cdestado        IN documentos.cdestadocomprobante%type,
                  p_amnetodocumento IN documentos.amnetodocumento%type)
  RETURN estadocomprobantes.dsestado%type;

  FUNCTION GetApellidoNombrePersona(p_idpersona IN tbltesoro.idpersona%TYPE) RETURN VARCHAR2;

  PROCEDURE GetReporteControlNC (p_fechaDesde    IN  DATE,
                       p_fechaHasta    IN  DATE,
                       p_autoriz       IN  VARCHAR2,
                       p_idpersona     IN  tbltesoro.idpersona%TYPE,
                       p_cuit          IN  entidades.cdcuit%type,
                       p_cf            IN  NUMBER,
                       p_canal         IN  VARCHAR2,
                       p_sucursales    IN  VARCHAR2,
                       p_cur_out       OUT cursor_type);

  PROCEDURE GetComentariosNC   (p_idDocTrx      IN  documentos.iddoctrx%type,
                       p_cur_out       OUT cursor_type);

  Procedure GetCuponesTJRechazadosDetalle(p_cdsucursal      In tblcuenta.cdsucursal%Type,
                             p_identidad       In entidades.identidad%Type,
                             p_idcuenta        In tblcuenta.idcuenta%Type,
                             p_fechaDesde      In Date,
                             p_fechaHasta      In Date,
                             p_lote            IN tbltarjeta.nrolote%TYPE,
                             p_cupon           IN tbltarjeta.dsnrocupon%TYPE,
                             p_cur_out         Out cursor_type);

  PROCEDURE GetAuditoriaEnvioAtencion(p_sucursales    IN VARCHAR2,
               p_fechaDesde    IN  DATE,
               p_fechaHasta    IN  DATE,
               p_cur_out       OUT cursor_type);

  PROCEDURE GetContracargosDetalle(p_cdsucursal IN tblcuenta.cdsucursal%TYPE,
                  p_identidad  IN entidades.identidad%TYPE,
                  p_idcuenta   IN tblcuenta.idcuenta%TYPE,
                  p_fechaDesde IN DATE,
                  p_fechaHasta IN DATE,
                  p_cur_out    OUT cursor_type);

  PROCEDURE GetContracargosGeneral(p_cdregion   IN tblregion.cdregion%TYPE,
                  p_sucursales IN VARCHAR2,
                  p_fechaDesde IN DATE,
                  p_fechaHasta IN DATE,
                  p_identidad  IN tblcuenta.identidad%TYPE,
                  p_idcuenta   IN tblcuenta.idcuenta%TYPE,
                  p_cur_out    OUT cursor_type);

  PROCEDURE GetTraspasoTransportita(p_IdTransportista IN tbltraspasotrans.idtransportista%type,
                       p_fechaDesde      IN  DATE,
                       p_fechaHasta      IN  DATE,
                       p_cur_out         OUT cursor_type);

  PROCEDURE GetRentabilidadCl(p_fechaDesde IN  DATE,
                              p_fechaHasta IN  DATE,
                              p_cur_out    out cursor_type);

  PROCEDURE GetComerciosClientesCL(p_cur_out out cursor_type);


  PROCEDURE GetDetallePedido(cur_out          OUT CURSOR_TYPE,
                             p_idpedido        IN pedidos.idpedido%type);

  PROCEDURE GetTarjetas(p_sucursales IN VARCHAR2,
                      p_FechaDesde IN DATE,
                      p_FechaHasta IN DATE,
                      p_cur_out    OUT cursor_type,
                      p_tipo IN NUMBER,
                      p_tipoing IN tblconfingreso.cdtipo%TYPE,
                      p_medio in tblconfingreso.cdmedio%TYPE,
                       p_importe in tblingreso.amingreso%TYPE) ;

 FUNCTION GetCanal(p_ident		     IN ENTIDADES.IDENTIDAD%TYPE,
				           p_cdSucursal    IN sucursales.cdsucursal%TYPE) RETURN VARCHAR2;

 PROCEDURE GetUltimoSaldoDetalle(p_sucursales  IN VARCHAR2,
                                 p_identidad   IN entidades.identidad%TYPE,
                                 p_idcuenta    IN tblcuenta.idcuenta%TYPE,
                                 p_tiposaldo   IN Integer,
                                 p_cur_out     OUT cursor_type);

Procedure GetGestionEstablecimiento(p_sucursales In Varchar2,
                         p_fechaDesde In Date,
                         p_fechaHasta In Date,
                         p_identidad in entidades.identidad%TYPE,
                        -- p_estado    in tblgsterminal.cdestado%TYPE,
                         p_cur_out    Out cursor_type);

PROCEDURE GetDetGsEstablecimiento(p_idgsestablecimiento IN tblcuenta.idcuenta%TYPE,
                       cur_out               OUT cursor_type);

PROCEDURE GetTerminalGsEstabl(p_idgsestablecimiento IN tblcuenta.idcuenta%TYPE,
                        cur_out               OUT cursor_type);

PROCEDURE GetDeudaGuia(p_fechaDesde  IN  DATE,
                        p_fechaHasta  IN  DATE,
                        p_cur_out     OUT cursor_type);


PROCEDURE GetTarjetasParaConciliacionCP(p_cdSucursal IN sucursales.cdsucursal%TYPE,
                                        p_fechaDesde IN DATE,
                                        p_fechaHasta IN DATE,
                                         p_sologiftcard   IN INTEGER,
                                        p_cur_out    OUT cursor_type);

PROCEDURE GetCajaSucursalDetallado(p_fecha      IN DATE,
                                   p_cdsucursal IN sucursales.cdsucursal%type,
                                   p_cur_out    OUT cursor_type);

PROCEDURE GetCajaSucursalGeneral(p_fechadesde IN DATE,
                                 p_fechahasta IN DATE,
                                 p_cdsucursal IN sucursales.cdsucursal%type,
                                 p_cur_out    OUT cursor_type);


  PROCEDURE GetDeudaTransportista (p_sucursales IN VARCHAR2,
                                    p_fechadesde in   date,
                                    p_fechahasta in   date,
                                    p_cur_out    OUT cursor_type);

 FUNCTION EsBajaPB(p_idcuenta tblcuenta.idcuenta%TYPE) RETURN varchar2;

 FUNCTION EsBajaPBN(p_idcuenta tblcuenta.idcuenta%TYPE) RETURN varchar2;

 PROCEDURE GetArchivoConciliacionCP (p_fecha   IN  DATE,
                                  p_cur_out OUT cursor_type);

  Procedure GetReporteDeudoresCreditos(p_fecha   IN Date,
                               p_cur_out OUT cursor_type);

Procedure GetPagosIngresosRechazados(p_idingreso IN tblcobranza.idingreso_pago%type,
                                      p_cur_out   OUT cursor_type);

Procedure GetChequesEnCarteraCred(p_cdsucursal In tblcuenta.cdsucursal%Type,
                                  p_identidad  In entidades.identidad%Type,
                                  p_fecha      IN date,
                                  p_cur_out    OUT cursor_type) ;

FUNCTION VendedorPorGuia(p_idguiadetransporte guiasdetransporte.idguiadetransporte%TYPE)
  RETURN varchar2;

PROCEDURE GetLiberacionCuenta(p_sucursales IN VARCHAR2,
                              p_fechadesde in date,
                              p_fechahasta in date,
                              p_cur_out    OUT cursor_type);

PROCEDURE GetClientesconCredito(p_identidad  IN entidades.identidad%type,
                                p_cdsucursal IN sucursales.cdsucursal%type,
                                p_cur_out    OUT cursor_type);

PROCEDURE AuditoriaCreditos(p_idpersona  IN personas.idpersona%type,
                            p_identidad  IN entidades.identidad%type,
                            p_fechadesde IN date,
                            p_fechahasta IN date,
                            p_cur_out    OUT cursor_type);

PROCEDURE GetEgresosConDeuda (p_sucursales IN  VARCHAR2,
                                     p_identidad IN entidades.identidad%type,
                                     p_cur_out    OUT cursor_type);

  PROCEDURE GetVentaACredito(p_identidad  IN entidades.identidad%type,
                        p_fechahasta IN date,
                        p_cdsucursal   IN sucursales.cdsucursal%type,
                        p_cur_out    OUT cursor_type);

  PROCEDURE GetFacFlete (p_sucursales IN VARCHAR2,
                       p_identidad  IN entidades.identidad%TYPE,
                       p_fechadesde in date,
                       p_fechahasta in date,
                       p_cur_out    OUT cursor_type);

  PROCEDURE GetAuditoriaCL(p_sucursales IN sucursales.cdsucursal%type,
                         p_idpersona  IN personas.idpersona%type,
                         p_identidad  IN entidades.identidad%type,
                         p_fechadesde DATE,
                         p_fechahasta DATE,
                         p_cur_out    OUT cursor_type) ;

  PROCEDURE GetAuditoriaReimpresion(p_sucursales IN VARCHAR2,
                                    p_fechaDesde IN DATE,
                                    p_fechaHasta IN DATE,
                                    p_cur_out    OUT cursor_type);

  PROCEDURE GetPanelSLV(p_cdsucursal       IN  sucursales.cdsucursal%TYPE,
                       p_IdConsolidado    IN  tblslv_consolidado.idconsolidado%TYPE,
                       p_fechaConsolidado IN  DATE,
                       p_canal            IN  VARCHAR2,
                       p_estados          IN  tblslv_consolidado.idestado%type,
                       p_cur_out          OUT cursor_type);

  PROCEDURE GetMercadoPago(p_sucursales IN VARCHAR2,
                           p_FechaDesde IN DATE,
                           p_FechaHasta IN DATE,
                           p_cdtipo     IN tblconfingreso.cdtipo%TYPE,
                           p_idexterno     IN tblelectronico.idexterno%TYPE,
                           p_cur_out    OUT cursor_type);

  PROCEDURE GetMercadoPagoDet (p_idingreso  IN tblelectronico.idingreso%TYPE,
                               p_cur_out    OUT cursor_type);

  PROCEDURE GetMontoTopeCargaComi(p_sucursales IN VARCHAR2,
                                  p_cur_out    OUT cursor_type);

  PROCEDURE GetEstablecTerm(   p_sucursales   IN            VARCHAR2,
                               p_cdforma      IN tblformaingreso.cdforma%TYPE,
                               p_cur_out      OUT           cursor_type);


PROCEDURE GetIngresosCanalGeneral(p_cdregion   IN tblregion.cdregion%TYPE,
                                p_sucursales IN VARCHAR2,
                                p_fechaDesde IN DATE,
                                p_fechaHasta IN DATE,
                                p_identidad  IN tblcuenta.identidad%TYPE,
                                p_idcuenta   IN tblcuenta.idcuenta%TYPE,
                                p_cur_out    OUT cursor_type);

PROCEDURE GetIngresosCanaldetalle(p_sucursales IN VARCHAR2,
                                p_identidad  IN entidades.identidad%TYPE,
                                p_idcuenta   IN tblcuenta.idcuenta%TYPE,
                                p_fechaDesde IN DATE,
                                p_fechaHasta IN DATE,
                                p_cur_out    OUT cursor_type) ;

PROCEDURE GetCajeroTiempoAlivio(     p_Fdesde IN DATE,
                                     p_Fhasta IN DATE,
                                     p_cdsucursal IN SUCURSALES.CDSUCURSAL%TYPE,
                                     p_cur_out    OUT cursor_type);

PROCEDURE GetEstadoCargaComi(p_idcomisionista entidades.identidad%type,
                             p_dtguia         out varchar2,
                             p_sqguia         out integer,
                             p_amguia         out number,
                             p_cur_out        OUT cursor_type);
                             
  PROCEDURE GetUsuariosPersonas (p_icestado   IN INTEGER,
                                 p_idpersona  in personas.idpersona%type,
                                 p_cur_out    OUT cursor_type);

PROCEDURE GetCierreLoteSalon( p_dtFechaDesde     IN tblcierrelotesalon.dtlote%TYPE,
                              p_dtFechaHasta     IN tblcierrelotesalon.dtlote%type,
                              p_cdsucursal IN tblcierrelotesalon.cdsucursal%type,
                              p_cur_out    OUT cursor_type);
                              
PROCEDURE GetComerciosConfigurados( p_cur_out    OUT cursor_type);

PROCEDURE GetVentaArticulosElectroCuotas(p_fechaDesde IN DATE,
                                         p_fechaHasta IN DATE,
                                         p_cur_out OUT cursor_type);
                                         
PROCEDURE GetVentaArticulosElectroDet(p_fechaDesde IN DATE,
                                         p_fechaHasta IN DATE,
                                         p_cur_out OUT cursor_type);
                                         
PROCEDURE GetBusquedaFacturas(p_fechadesde        in   date,
                              p_fechahasta        in   date,
                              p_dni               in   VARCHAR2,
                              p_entidad           in entidades.identidad%type,
                              p_cur_out           OUT cursor_type); 
                              
PROCEDURE GetBusquedaFacturasDetalle(p_idmovmateriales  IN detallemovmateriales.idmovmateriales%type,
                                     p_cur_out          OUT cursor_type);
                              
FUNCTION IDVTEX (p_idpedido      pedidos.idpedido%type) return varchar2;

FUNCTION ObtenerDNIReferencia(p_DsReferencia   in DOCUMENTOS.Dsreferencia%type,
                                 p_identidad    in documentos.identidad%type,
                                 p_canal        in movmateriales.id_canal%type)  RETURN varchar2;
        
   
  PROCEDURE GetEstatusPrecargaNC(p_sucursales IN VARCHAR2,
                                 p_estado     IN tblprecarganc.cdestado%type,
                                 p_fechadesde IN DATE,
                                 p_fechahasta IN DATE,
                                 p_canal      IN movmateriales.id_canal%type,
                                 p_cur_out    OUT cursor_type);
                           
END PKG_REPORTE_CENTRAL;
/
CREATE OR REPLACE PACKAGE BODY PKG_REPORTE_CENTRAL IS

 g_Listachequecomi tab_Listachequecomi;

   /**************************************************************************************************
   * 07/02/2014 - MatiasG
   * package PKG_REPORTE_CENTRAL
   * version: 1.0
   * Este PKG contiene los servicios para la generacion de reportes en CASA CENTRAL
   **************************************************************************************************/

   /**************************************************************************************************
   * Inserta en la tabla temporal la lista de sucursales recibida como parametro desde la interfaz y
  * devuelve un SYS_GUID a ser utilizado como ID para multiusuario multiconsulta
  *
  *******        ATENCION: Cuidado al tocar esto porque se rompen todos los reportes       **********
  *
   * %v 15/07/2014 - MatiasG: v1.0
   ***************************************************************************************************/
   FUNCTION SetSucursalesSeleccionadas(p_listaSucursales IN VARCHAR2) RETURN VARCHAR2
  IS
      v_modulo                VARCHAR2(100)  := 'PKG_REPORTE_CENTRAL.SetSucursalesSeleccionadas';
    v_idReporte             VARCHAR2(40)   := '';
    v_query                 VARCHAR2(2000) := '';
   BEGIN
      -- Genero un ID de reporte para soporte multi usuario
      v_idReporte := sys_guid();

    --  Inserto las sucursales enviadas por parametro en la tabla temporal
    v_query := 'INSERT INTO tbltmp_sucursales_reporte(idreporte, cdsucursal)
                  SELECT '''||v_idReporte||''', su.cdsucursal FROM sucursales su';

      IF p_listaSucursales IS NOT NULL THEN
       v_query := v_query ||' WHERE su.cdsucursal IN ('||p_listaSucursales||')';
    END IF;

      EXECUTE IMMEDIATE v_query;
    COMMIT;

    RETURN v_idReporte;
   EXCEPTION
      WHEN OTHERS THEN
         n_pkg_vitalpos_log_general.write(2, 'Modulo: ' || v_modulo || '  Error: ' || SQLERRM);
         RAISE;
   END SetSucursalesSeleccionadas;

   /**************************************************************************************************
   * Realiza la limpieza de la tabla temporal
  *
  *******        ATENCION: Cuidado al tocar esto porque se rompen todos los reportes       **********
  *
   * %v 15/07/2014 - MatiasG: v1.0
   ***************************************************************************************************/
  PROCEDURE CleanSucursalesSeleccionadas(p_idReporte  IN VARCHAR2)
    IS
      v_modulo VARCHAR2(100) := 'PKG_REPORTE_CENTRAL.GetMonitoreoCajas';
  BEGIN
      DELETE tbltmp_sucursales_reporte sr
       WHERE sr.idreporte = p_idReporte;
      COMMIT;
   EXCEPTION
      WHEN OTHERS THEN
         n_pkg_vitalpos_log_general.write(2, 'Modulo: ' || v_modulo || ' Error: ' || SQLERRM);
         RAISE;
  END;

   /****************************************************************************************
   * 27/09/2013
   * MarianoL
   * Determina si la entidad es consumidor final
   /****************************************************************************************/
   FUNCTION EsCFAnonimo(p_ident ENTIDADES.IDENTIDAD%TYPE) RETURN INTEGER IS
      v_Result INTEGER;
   BEGIN
      IF TRIM(p_ident) = TRIM(Getvlparametro('IdCfReparto', 'General')) OR
         TRIM(p_ident) = TRIM(GetVlparametro('CdConsFinal', 'General')) OR
         TRIM(p_ident) = TRIM(getvlparametro('CdCFNoResidente', 'General')) THEN
         v_Result := 1;
      ELSE
         v_Result := 0;
      END IF;
      RETURN v_Result;

   EXCEPTION
      WHEN OTHERS THEN
         RETURN 0;
   END EsCFAnonimo;

  /***************************************************************************************************************************
  * Dado un identidad retorna la razonsocial
  * %V 15/07/2015 - JBodnar v1.0
  ****************************************************************************************************************************/
   FUNCTION GetRazonSocial(p_identidad in entidades.identidad%type) RETURN entidades.dsrazonsocial%type IS
      v_Result entidades.dsrazonsocial%type;

   BEGIN

      SELECT dd.dsrazonsocial
        INTO v_Result
        FROM entidades dd
       WHERE dd.identidad=p_identidad;

      RETURN v_Result;

   EXCEPTION
      WHEN OTHERS THEN
         RETURN null;
   END GetRazonSocial;

   /*****************************************************************************************************************
   * Retorna el idCuenta de la cuenta principal o de cualquiera de sus cuentas hijas segun el parametro cdTipoCuenta
   * %v 24/02/2015 - MatiasG: v1.0
   ******************************************************************************************************************/
   FUNCTION SeleccionarCuenta(p_idCuentaPrincipal IN tblcuenta.idcuenta%TYPE,
                              p_cdTipoCuenta      IN tblcuenta.cdtipocuenta%TYPE)
      RETURN tblcuenta.idcuenta%TYPE IS
      v_Modulo   VARCHAR2(100) := 'PKG_REPORTE_CENTRAL.SeleccionarCuenta';
      v_idCuenta tblcuenta.idcuenta%TYPE;
   BEGIN
      IF p_cdTipoCuenta = '1' THEN
         RETURN p_idCuentaPrincipal;
      ELSE
         SELECT cu.idcuenta
           INTO v_idCuenta
           FROM tblcuenta cu
          WHERE cu.idpadre = p_idCuentaPrincipal
            AND cu.cdtipocuenta = p_cdTipoCuenta;

         RETURN v_idCuenta;
      END IF;
   EXCEPTION
      WHEN OTHERS THEN
         n_pkg_vitalpos_log_general.write(2, 'Modulo: ' || v_Modulo || ' Error: ' || SQLERRM);
         RAISE;
   END SeleccionarCuenta;

   /*****************************************************************************************************************
   * function GetResponsableDeuda
   * Dado un idDocTrx decuelve un string con la descripción del responsable de la deuda (usado para reporte de deudor)
   * %v 23/09/2015 - MarianoL
   ******************************************************************************************************************/
   FUNCTION GetResponsableDeuda(p_idDocTrx IN documentos.iddoctrx%TYPE)
   RETURN VARCHAR2
   IS
      v_Return          varchar2(1000);
      v_idComisionista  movmateriales.idcomisionista%type;
      v_idEntidadReal   entidades.identidad%type;

   BEGIN

      --Buscar el comisionista
      select mm.idcomisionista, d.identidadreal
      into v_idComisionista, v_idEntidadReal
      from movmateriales mm,
           documentos d
      where d.iddoctrx = p_idDocTrx
        and mm.idmovmateriales = d.idmovmateriales;

      --Verificar si es una factura de un cliente de comisionista
      if v_idComisionista is not null then
         --Buscar los datos del comisionista
         select '(' || trim(e.cdcuit) || ') ' || trim(e.dsrazonsocial) || ' (CO)'
         into v_Return
         from entidades e
         where e.identidad = v_idComisionista;

      else
         --Buscar los datos de la entidad real
         select '(' || trim(e.cdcuit) || ') ' || trim(e.dsrazonsocial)
         into v_Return
         from entidades e
         where e.identidad = v_idEntidadReal;

      end if;

      return v_Return;

   EXCEPTION WHEN OTHERS THEN
      return null;
   END GetResponsableDeuda;

   /*****************************************************************************************************************
   * Retorna un listado de personas por rol(opcional) y
   * %v 29/08/2014 - MatiasG: v1.0
   ******************************************************************************************************************/
   FUNCTION GetPersona(p_idPersona IN personas.idpersona%TYPE) RETURN VARCHAR2 IS
      v_Modulo    VARCHAR2(100) := 'PKG_REPORTE_CENTRAL.GetPersona';
      v_dspersona VARCHAR2(1000);
   BEGIN
         SELECT pp.dsapellido || ' ' || pp.dsnombre
           INTO v_dspersona
           FROM personas pp
          WHERE pp.idpersona = p_idPersona;
      RETURN v_dspersona;
   EXCEPTION
      WHEN no_data_found THEN
         RETURN 'Persona No Encontrada';
      WHEN OTHERS THEN
         n_pkg_vitalpos_log_general.write(2, 'Modulo: ' || v_Modulo || ' Error: ' || SQLERRM);
         RAISE;
   END GetPersona;
   /*****************************************************************************************************************
   * Retorna un listado de personas por rol(opcional) y
   * %v 29/08/2014 - MatiasG: v1.0
   ******************************************************************************************************************/
   PROCEDURE GetPersonas(p_NombreApellido IN VARCHAR2,
                         p_cdrol          IN rolespersonas.cdrol%TYPE,
                         p_cur_out        OUT cursor_type) IS
      v_Modulo VARCHAR2(100) := 'PKG_REPORTE_CENTRAL.GetPersonas';
   BEGIN
      OPEN p_cur_out FOR
         SELECT pp.idpersona, UPPER(pp.dsapellido || ' ' || pp.dsnombre) dspersona, rp.cdrol
           FROM personas pp, rolespersonas rp
          WHERE pp.idpersona = rp.idpersona
            AND lower(pp.dsapellido || ' ' || pp.dsnombre)  LIKE '%' || lower(p_NombreApellido) || '%'
            AND TRIM(rp.cdrol) = NVL(p_cdrol, TRIM(rp.cdrol))
          ORDER BY 2;

   EXCEPTION
      WHEN OTHERS THEN
         n_pkg_vitalpos_log_general.write(2, 'Modulo: ' || v_Modulo || ' Error: ' || SQLERRM);
         RAISE;
   END GetPersonas;


  /***************************************************************************************************************************
  * Dado un medio de pago devuelve el saldo del medio de pago en el tesoro
  * No importa la acción del p_cdConfIngreso el saldo será siempre el mismo
  * %V 07/08/2014 - MarianoL v1.0
  ****************************************************************************************************************************/
   FUNCTION GetSaldo(p_cdConfIngreso IN tblconfingreso.cdconfingreso%TYPE,
                     p_cdSucursal    IN sucursales.cdsucursal%TYPE) RETURN NUMBER IS
      v_Result NUMBER := 0;

   BEGIN

      SELECT nvl(SUM(t.amsaldo), 0)
        INTO v_Result
        FROM tbltesoro t
       WHERE t.cdsucursal = p_cdSucursal
       and t.sqtesoro = (SELECT MAX(t.sqtesoro)
                             FROM tblconfingreso c1, tblconfingreso c2, tbltesoro t
                            WHERE c1.cdconfingreso = p_cdConfIngreso
                              AND c1.icestado = 1
                              AND t.cdsucursal = p_cdSucursal
                              AND c2.cdmedio = c1.cdmedio
                              AND c2.cdtipo = c1.cdtipo
                              AND c2.cdforma = c1.cdforma
                              AND c2.cdsucursal = c1.cdsucursal
                              AND c2.icestado = 1
                              AND t.cdconfingreso = c2.cdconfingreso);
      RETURN v_Result;

   EXCEPTION
      WHEN OTHERS THEN
         RETURN 0;
   END GetSaldo;

   /**************************************************************************************************
   * Dado un IdIngreso devuelve la descripcion del estado del mismo
   * %v 07/10/2014 MatiasG: v1.0
   ***************************************************************************************************/
   FUNCTION GetDescEstadoIngreso(p_cdestado IN tblingreso.cdestado%TYPE)
      RETURN tblestadoingreso.dsestado%TYPE
  IS
      v_Modulo VARCHAR2(100) := 'PKG_INGRESO.GetDescEstadoIngreso';
      v_Result tblestadoingreso.dsestado%TYPE;
   BEGIN
      SELECT ei.dsestado
        INTO v_Result
        FROM tblestadoingreso ei
       WHERE ei.cdestado = p_cdestado;

      RETURN(v_Result);

   EXCEPTION
      WHEN OTHERS THEN
         n_pkg_vitalpos_log_general.write(2, 'Modulo: ' || v_Modulo || '  Error: ' || SQLERRM);
         RAISE;
   END GetDescEstadoIngreso;

   /**************************************************************************************************
   * 19/05/2014
   * MarianoL
   * Devuelve la descripción de un ConfIngreso
   ***************************************************************************************************/
  FUNCTION GetDescIngreso(p_cdConfIngreso IN tblconfingreso.cdconfingreso%TYPE,
                         p_cdSucursal    IN sucursales.cdsucursal%TYPE) RETURN VARCHAR2 IS
    v_Result VARCHAR2(100);
  BEGIN
    SELECT decode(a.cdaccion, 1, NULL, TRIM(a.dsaccion) || ' ') || TRIM(m.dsmedio) || ' ' ||
         TRIM(t.dstipo) || decode(f.cdforma, 1, null, ' ' || TRIM(f.dsforma))
      INTO v_Result
      FROM tblconfingreso   ci,
         tblaccioningreso a,
         tblmedioingreso  m,
         tbltipoingreso   t,
         tblformaingreso  f
     WHERE ci.cdmedio = m.cdmedio
      AND ci.cdaccion = a.cdaccion
      AND ci.cdtipo = t.cdtipo
      AND ci.cdforma = f.cdforma
      AND ci.cdsucursal = p_cdSucursal
      AND ci.cdconfingreso = p_cdConfIngreso;
    RETURN(v_Result);
  EXCEPTION WHEN OTHERS THEN
      RETURN(NULL);
  END GetDescIngreso;

   /**************************************************************************************************
   * Devuelve la descripción de un documento
   * %v 19/05/2014 - MarianoL
   ***************************************************************************************************/
   FUNCTION GetDescDocumento(p_idDocTrx IN documentos.iddoctrx%TYPE) RETURN VARCHAR2 IS
      v_Result VARCHAR2(100);
   BEGIN
      SELECT substr(d.cdcomprobante, 1, 2) || ' ' || substr(d.cdcomprobante, 4, 1) || ' ' ||
             TRIM(d.cdpuntoventa) || '-' || d.sqcomprobante
        INTO v_Result
        FROM documentos d
       WHERE d.iddoctrx = p_idDocTrx;
      RETURN(v_Result);
   EXCEPTION
      WHEN OTHERS THEN
         RETURN(NULL);
   END GetDescDocumento;

   /**************************************************************************************************
   * Devuelve El credito otorgado
   * %v 19/05/2014 - MarianoL
   ***************************************************************************************************/
   FUNCTION GetOtorgado(p_idCuenta IN tblcuenta.idcuenta%TYPE) RETURN tblcuenta.amotorgado%TYPE IS
      v_Result tblcuenta.amotorgado%TYPE;
   BEGIN
      SELECT cu.amotorgado
        INTO v_Result
        FROM tblcuenta cu
      WHERE cu.idcuenta = p_idCuenta;
      RETURN(v_Result);
   EXCEPTION
      WHEN OTHERS THEN
         RETURN(NULL);
   END GetOtorgado;

   /**************************************************************************************************
   * Devuelve una lista de personas con rol de cajero
   * %v 28/08/2014 MatiasG : v1.0
   * %v 29/09/2014 JBodnar : v1.1 - Filtros de cuenta y persona activa
   ***************************************************************************************************/
  PROCEDURE GetPersonasCajeros(p_cur_out OUT cursor_type)
  IS
    v_modulo VARCHAR2(100) := 'PKG_REPORTE_CENTRAL.GetPersonasCajeros';
  BEGIN
    OPEN p_cur_out FOR
      SELECT pe.idpersona, pe.dsapellido || ' ' || pe.dsnombre dspersona
        FROM personas pe, permisos pp, cuentasusuarios cu
       WHERE pe.idpersona = pp.idpersona
        AND pp.nmgrupotarea = 'Cajero'
        and cu.idpersona=pe.idpersona
        and cu.icestadousuario=1 --Cuenta activa
        and pe.icactivo=1--Persona activa
        ORDER BY pe.dsapellido ASC;

  EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2, 'Modulo: ' || v_modulo || '  Error: ' || SQLERRM);
      RAISE;
  END GetPersonasCajeros;

  /*****************************************************************************************************
   * Retorna el periodo de aging segun los dias de deuda, buscando eliminar el decode del query principal
   * %v 30/06/2014 - MatiasG: v1.0
   ******************************************************************************************************/
  FUNCTION GetPeriodoAging(p_diasDeuda IN NUMBER) RETURN NUMBER
   IS
  BEGIN
    IF p_diasDeuda BETWEEN 0 AND 7 THEN
      RETURN 7;
    ELSIF p_diasDeuda BETWEEN 8 AND 14 THEN
      RETURN 14;
    ELSIF p_diasDeuda BETWEEN 15 AND 30 THEN
      RETURN 30;
    ELSIF p_diasDeuda BETWEEN 31 AND 45 THEN
      RETURN 45;
    ELSIF p_diasDeuda BETWEEN 46 AND 60 THEN
      RETURN 60;
    ELSIF p_diasDeuda BETWEEN 61 AND 100 THEN
      RETURN 100;
    ELSIF p_diasDeuda > 100 THEN
      RETURN 101;
    END IF;

    RETURN 0;
  END GetPeriodoAging;

   /*****************************************************************************************************************
   * Retorna los posibles estados para un coprobante ingresado en el parametro
   * %v 19/05/2014 - MatiasG: v1.0
   ******************************************************************************************************************/
   PROCEDURE GetEstadosComprobantes(p_cdcomprobante IN estadocomprobantes.cdcomprobante%TYPE,
                                    p_cur_out       OUT cursor_type) IS
      v_modulo VARCHAR2(100) := 'PKG_REPORTE_CENTRAL.GetEstadosComprobantes';
   BEGIN
      OPEN p_cur_out FOR
         SELECT ee.cdestado, ee.dsestado
           FROM estadocomprobantes ee
          WHERE ee.cdcomprobante = p_cdcomprobante
       ORDER BY 1;
   EXCEPTION
      WHEN OTHERS THEN
         n_pkg_vitalpos_log_general.write(2, 'Modulo: ' || v_modulo || '  Error: ' || SQLERRM);
         RAISE;
   END GetEstadosComprobantes;

   /*****************************************************************************************************************
   * Retorna el saldo actual de las cajas tesoreras
   * %v 19/05/2014 - MatiasG: v1.0
   ******************************************************************************************************************/
  PROCEDURE GetMonitoreoCajasTesoreras(p_cur_out OUT cursor_type) IS
    v_modulo VARCHAR2(100) := 'PKG_REPORTE_CENTRAL.GetMonitoreoCajasTesoreras';
  BEGIN


    OPEN p_cur_out FOR
      SELECT su.dssucursal,
           DECODE(a.cdmedio,
                1,
                pkg_ingreso_central.GetDescMedio(a.cdconfingreso, a.cdsucursal) ||
                DECODE(a.cdtipo, 18, ' Dolares', '20', ' Pesos'),
                pkg_ingreso_central.GetDescMedio(a.cdconfingreso, a.cdsucursal)) medio,
           SUM(PKG_REPORTE_CENTRAL.GetSaldo(a.cdconfingreso, a.cdsucursal)) importe
        FROM (SELECT DISTINCT te.cdsucursal, te.cdconfingreso, ci.cdmedio, ci.cdtipo
             FROM tbltesoro te, tblconfingreso ci
            WHERE te.cdconfingreso = ci.cdconfingreso
              AND te.cdsucursal = ci.cdsucursal
              AND ci.cdaccion = '1') a,
           sucursales su
       WHERE a.cdsucursal = su.cdsucursal
       GROUP BY su.dssucursal,
             DECODE(a.cdmedio,
                  1,
                  pkg_ingreso_central.GetDescMedio(a.cdconfingreso, a.cdsucursal) ||
                  DECODE(a.cdtipo, 18, ' Dolares', '20', ' Pesos'),
                  pkg_ingreso_central.GetDescMedio(a.cdconfingreso, a.cdsucursal));
  EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2, 'Modulo: ' || v_modulo || '  Error: ' || SQLERRM);
      RAISE;
  END GetMonitoreoCajasTesoreras;

   /*****************************************************************************************************************
   * Retorna un reporte del detalle de ingresos por factura
   * %v 30/06/2014 - MatiasG: v1.0
   ******************************************************************************************************************/
   PROCEDURE GetIngresosPorDocumento(p_idDocTrx IN documentos.iddoctrx%TYPE,
                                     p_cur_out  OUT cursor_type) IS
      v_modulo VARCHAR2(100) := 'PKG_REPORTE_CENTRAL.GetIngresosPorDocumento';
   BEGIN
      OPEN p_cur_out FOR
      SELECT pkg_ingreso_central.GetDescIngreso(ii.cdconfingreso, ii.cdsucursal) mediodepago,
      round(tc.amimputado,2) importe
      FROM tblcobranza tc, tblingreso ii
      WHERE tc.idingreso = ii.idingreso
      AND tc.iddoctrx = p_idDocTrx
      union
      SELECT PKG_REPORTE_CENTRAL.GetDescDocumento(tc.iddoctrx_pago) mediodepago,
      round(tc.amimputado,2) importe
      FROM tblcobranza tc
      WHERE tc.iddoctrx = p_idDocTrx
      and tc.iddoctrx_pago is not null;

   EXCEPTION
      WHEN OTHERS THEN
         n_pkg_vitalpos_log_general.write(2, 'Modulo: ' || v_modulo || '  Error: ' || SQLERRM);
         RAISE;
   END GetIngresosPorDocumento;

   /*****************************************************************************************************************
   * Retorna un reporte del detalle de facturas por ingreso
   * %v 30/06/2014 - MatiasG: v1.0
   ******************************************************************************************************************/
   PROCEDURE GetDocumentosPorIngreso(p_idingreso IN tblingreso.idingreso%TYPE,
                                     p_cur_out   OUT cursor_type)
  IS
      v_modulo VARCHAR2(100) := 'PKG_REPORTE_CENTRAL.GetDocumentosPorIngreso';
      v_cdconfingreso   tblconfingreso.cdconfingreso%type;
   BEGIN
      --Busca el la configuracion
      select ii.cdconfingreso into v_cdconfingreso
      from tblingreso ii
      where ii.idingreso=p_idingreso;

      OPEN p_cur_out FOR
         SELECT trunc(tc.dtimputado) fecha,
                PKG_REPORTE_CENTRAL.GetDescDocumento(do.iddoctrx) descripcion,
                (tc.amimputado * -1) importe
           FROM tblingreso ii, tblcobranza tc, documentos do
          WHERE ii.idingreso = tc.idingreso
            AND tc.iddoctrx = do.iddoctrx
            and ii.cdconfingreso =v_cdconfingreso
            AND do.iddoctrx in  (
         SELECT tc.iddoctrx
           FROM tblcobranza tc
        where tc.idingreso = p_idingreso)  ;

   EXCEPTION
      WHEN OTHERS THEN
         n_pkg_vitalpos_log_general.write(2, 'Modulo: ' || v_modulo || '  Error: ' || SQLERRM);
         RAISE;
   END GetDocumentosPorIngreso;

   /*****************************************************************************************************************
   * Retorna un reporte del detalle de acreditaciones
   * %v 30/06/2014 - MatiasG: v1.0
   * %v 05/01/2016 - LucianoF: v1.1 - Agrego clienteEspecial para traer tarjetas CE y Tercero
   ******************************************************************************************************************/
   PROCEDURE GetAcreditaciones(p_cdCuit       IN entidades.cdcuit%TYPE,
                               p_idcuenta     IN tblcuenta.idcuenta%TYPE,
                               p_fechaDesde   IN DATE,
                               p_fechaHasta   IN DATE,
                               p_cur_out      OUT cursor_type) IS
      v_modulo VARCHAR2(100) := 'PKG_REPORTE_CENTRAL.GetAcreditaciones';
   BEGIN

      OPEN p_cur_out FOR
              SELECT TRUNC(ii.dtingreso) fecha,
                pkg_ingreso_central.GetDescIngreso(ii.cdconfingreso,ii.cdsucursal) tipo,
                cl.vlestablecimiento establecimiento,
                ii.amingreso importe
                FROM tblingreso                ii,
                     sucursales                su,
                     tblcuenta                 cu,
                     entidades                 ee,
                     tblconfingreso            tci,
                     tblcierrelote cl
               WHERE ii.cdsucursal = su.cdsucursal
                 AND su.cdsucursal = cu.cdsucursal
                 AND ii.idcuenta = cu.idcuenta
                 AND cu.identidad = ee.identidad
                 and cl.idingreso (+)= ii.idingreso
                 and ee.cdcuit = nvl (p_cdCuit, ee.cdcuit)
                 AND ii.idcuenta = NVL(p_idcuenta, ii.idcuenta)
                 AND ii.dtingreso BETWEEN trunc(p_fechaDesde) AND trunc(p_fechaHasta+1)
                 AND tci.cdconfingreso = ii.cdconfingreso
                 AND tci.cdsucursal = ii.cdsucursal
                 AND tci.cdforma in (2,3,4,5); --PB y CL --LF: Agrego CE y Tercero

   EXCEPTION
      WHEN OTHERS THEN
         n_pkg_vitalpos_log_general.write(2, 'Modulo: ' || v_modulo || '  Error: ' || SQLERRM);
         RAISE;
   END GetAcreditaciones;

   /************************************************************************************************
   * Retorna la facturacion agrupada por canal de venta, mes y año.
   * Si es nulo el parametro del año, se toma 2 años para atras
   * %v 31/03/2015 - JBodnar: v1.0
   *************************************************************************************************/
    Procedure GetFacturacionPorCanal(p_idcuenta In documentos.idcuenta%Type,
                                     p_id_canal In movmateriales.id_canal%Type,
                                     p_cur_out  Out cursor_type) Is
       v_Modulo     Varchar2(100) := 'PKG_REPORTE_CENTRAL.GetFacturacionPorCanal';
       v_idCuenta2  tblcuenta.idcuenta%type;
    Begin

       pkg_cuenta_central.GetCuentaHija(p_idcuenta,'2',v_idCuenta2);

       Open p_cur_out For
          Select to_number(to_char(fh.aniomes,'yyyy')) anio,
                 to_number(to_char(fh.aniomes,'mm')) mes,
                 sum(fh.qtdocumentos) cant,
                 sum(fh.amfacturacion) monto,
                 cu.cdtipocuenta
            From tblfacturacionhistorica fh,
                 tblcuenta cu,
                 entidades ee
           Where cu.idcuenta = fh.idcuenta
             And ee.identidad = cu.identidad
             And fh.id_canal = nvl(p_id_canal, fh.id_canal)
             And cu.idcuenta in (p_idcuenta,v_idCuenta2)
             Group by aniomes,cu.cdtipocuenta;


    Exception
       When Others Then
          n_pkg_vitalpos_log_general.write(2, 'Modulo: ' || v_Modulo ||
                                            ' Error: ' || Sqlerrm);
          Raise;
    End GetFacturacionPorCanal;

   /****************************************************************************************
   * Retorna las altas de clientes agrupadas
   * %v 12/05/2014 - MatiasG: v1.0
   *****************************************************************************************/
   PROCEDURE GetClientesPorAltaGeneral(p_cdregion   IN tblregion.cdregion%TYPE,
                                       p_sucursales IN VARCHAR2,
                                       p_identidad  IN entidades.identidad%TYPE,
                                       p_FechaDesde IN DATE,
                                       p_FechaHasta IN DATE,
                                       p_cur_out    OUT cursor_type)
  IS
      v_Modulo VARCHAR2(100) := 'PKG_REPORTE_CENTRAL.GetClientesPorAltaGeneral';
     v_idReporte             VARCHAR2(40) := '';
   BEGIN
      v_idReporte := SetSucursalesSeleccionadas(p_sucursales);

    OPEN p_cur_out FOR
         SELECT re.cdregion,
                re.dsregion region,
                su.cdsucursal,
                su.dssucursal sucursal,
                COUNT(*) altas
           FROM entidades ee, sucursales su, tblregion re, tbltmp_sucursales_reporte rs
          WHERE ee.cdmainsucursal = su.cdsucursal
            AND su.cdregion = re.cdregion
            AND su.cdsucursal = rs.cdsucursal
        AND rs.idreporte = v_idReporte
        AND re.cdregion = NVL(p_cdregion,re.cdregion)
        AND ee.identidad = NVL(p_identidad,ee.identidad)
            AND ee.dtalta BETWEEN trunc(p_fechaDesde) AND trunc(p_fechaHasta+1)
          GROUP BY re.cdregion, re.dsregion, su.cdsucursal, su.dssucursal;

    CleanSucursalesSeleccionadas(v_idReporte);
   EXCEPTION
      WHEN OTHERS THEN
         n_pkg_vitalpos_log_general.write(2, 'Modulo: ' || v_Modulo || ' Error: ' || SQLERRM);
         RAISE;
   END GetClientesPorAltaGeneral;

   /****************************************************************************************
   * Retorna el detalle de las altas de clientes
   * %v 12/05/2014 - MatiasG: v1.0
   * %v 21/02/2017 - IAquilano - Agrego consulta de canal optativo
   * %v 26/06/2017 - APW - Cambio join de direccion
   *****************************************************************************************/
   PROCEDURE GetClientesPorAltaDetalle(p_cdsucursal IN tblcuenta.cdsucursal%TYPE,
                                       p_identidad  IN entidades.identidad%TYPE,
                                       p_FechaDesde IN DATE,
                                       p_FechaHasta IN DATE,
                                       p_cur_out    OUT cursor_type)
  IS
      v_Modulo VARCHAR2(100) := 'PKG_REPORTE_CENTRAL.GetClientesPorAltaDetalle';
   BEGIN
      OPEN p_cur_out FOR
          SELECT re.dsregion      region,
                su.dssucursal    sucursal,
                ee.dsrazonsocial cliente,
                ee.cdcuit,
                ee.dtalta        fecha,
                de.dscalle || ' ' || de.dsnumero || ' ' || de.dspisonumero as calle,
                de.cdcodigopostal,
                lo.dslocalidad,
                po.dsprovincia,
                pa.dspais,
                rc.dsrubrocomercial,
                (select ce.dscontactoentidad
                from contactosentidades ce
                where ce.identidad = ee.identidad
                and ce.cdformadecontacto = 1
                and ce.sqcontactoentidad = (select max(ce1.sqcontactoentidad) from contactosentidades ce1
                                           where ce1.identidad = ee.identidad
                                           and ce1.cdformadecontacto = 1)) as telefono,
                (select ce.dscontactoentidad
                from contactosentidades ce
                where ce.identidad = ee.identidad
                and ce.cdformadecontacto = 3
                and ce.sqcontactoentidad = (select max(ce1.sqcontactoentidad) from contactosentidades ce1
                                           where ce1.identidad = ee.identidad
                                           and ce1.cdformadecontacto = 3)) as celular,
                (select ce.dscontactoentidad
                from contactosentidades ce
                where ce.identidad = ee.identidad
                and ce.cdformadecontacto = 2
                and ce.sqcontactoentidad = (select max(ce1.sqcontactoentidad) from contactosentidades ce1
                                           where ce1.identidad = ee.identidad
                                           and ce1.cdformadecontacto = 2)) as Correo,
                 GetCanal(ee.identidad, ee.cdmainsucursal) as Opcion_De_Venta
           FROM entidades ee, sucursales su, tblregion re, direccionesentidades de, localidades lo, provincias po, paises pa, rubroscomerciales rc
          WHERE ee.identidad = ee.identidad
            AND ee.cdmainsucursal = su.cdsucursal
            AND su.cdregion = re.cdregion
            AND su.cdsucursal = NVL(p_cdsucursal,su.cdsucursal)
            AND ee.identidad = NVL(p_identidad,ee.identidad)
            AND ee.dtalta BETWEEN trunc(p_fechaDesde) AND trunc(p_fechaHasta+1)
            AND ee.identidad = de.identidad
            AND de.cdtipodireccion = 2
            AND de.sqdireccion = (select max(de1.sqdireccion)
                                         from direccionesentidades de1
                                         where de1.identidad = ee.identidad
                                         and de1.cdtipodireccion = 2)
            and de.cdpais = lo.cdpais
            and de.cdprovincia = lo.cdprovincia
            AND de.cdlocalidad = lo.cdlocalidad
            AND de.cdpais = po.cdpais
            AND de.cdprovincia = po.cdprovincia
            AND de.cdpais = pa.cdpais
            AND rc.cdrubrocomercial = ee.cdrubroprincipal
           ORDER BY ee.dtalta DESC;
   EXCEPTION
      WHEN OTHERS THEN
         n_pkg_vitalpos_log_general.write(2, 'Modulo: ' || v_Modulo || ' Error: ' || SQLERRM);
         RAISE;
   END GetClientesPorAltaDetalle;

   /*****************************************************************************************************************
   * Retorna un reporte de creditos otorgados por cliente y por cuenta agrupado por region y sucursal
   * %v 30/06/2014 - MatiasG: v1.0
   * %v 16/01/2015 - MartinM: v1.1 Agrego una condición en el query EsConsumidorFinal, ya que estaba en el detalle y no el General
   ******************************************************************************************************************/
   PROCEDURE GetCreditosOtorgadosGeneral(p_cdregion     IN tblregion.cdregion%TYPE,
                                         p_sucursales   IN VARCHAR2,
                                         p_identidad    IN entidades.identidad%TYPE,
                                         p_idcuenta     IN tblcuenta.idcuenta%TYPE,
                                         p_creditoDesde IN tblcuenta.amotorgado%TYPE,
                                         p_creditoHasta IN tblcuenta.amotorgado%TYPE,
                                         p_cur_out      OUT cursor_type)
  IS
      v_modulo VARCHAR2(100) := 'PKG_REPORTE_CENTRAL.GetCreditosOtorgadosGeneral';
     v_idReporte             VARCHAR2(40) := '';
   BEGIN
     v_idReporte := SetSucursalesSeleccionadas(p_sucursales);

    OPEN p_cur_out FOR
         SELECT re.cdregion,
                re.dsregion region,
                cu.cdsucursal,
                su.dssucursal sucursal,
                trunc(SUM(pkg_credito_central.GetDisponible(cu.idcuenta)),2) disponible,
                trunc(SUM(cu.amotorgado),2) otorgado,
                trunc(SUM(pkg_credito_central.GetUtilizado(cu.idcuenta)),2) utilizado,
                trunc(SUM(cu.amampliacion),2) amampliacion,
                trunc(SUM(cu.amampliacionextra),2) amampliacionextra
           FROM tblcuenta cu,
                sucursales su,
                tblregion re,
                tbltmp_sucursales_reporte rs
          WHERE cu.cdsucursal = su.cdsucursal
            AND cu.amotorgado > 0
            AND su.cdregion = re.cdregion
            AND su.cdsucursal = rs.cdsucursal
            AND rs.idreporte = v_idReporte
           AND cu.cdtipocuenta = '1'
            AND re.cdregion = NVL(p_cdregion,re.cdregion)
            AND cu.identidad = NVL(p_identidad,cu.identidad)
            AND cu.idcuenta = NVL(p_idcuenta,cu.idcuenta)
            AND cu.amotorgado BETWEEN NVL(p_creditoDesde,cu.amotorgado)
                                  AND NVL(p_creditoHasta,cu.amotorgado)
       GROUP BY re.cdregion,
                re.dsregion,
                cu.cdsucursal,
                su.dssucursal;

    CleanSucursalesSeleccionadas(v_idReporte);
   EXCEPTION
      WHEN OTHERS THEN
         n_pkg_vitalpos_log_general.write(2, 'Modulo: ' || v_modulo || '  Error: ' || SQLERRM);
         RAISE;
   END GetCreditosOtorgadosGeneral;

   /*****************************************************************************************************************
   * Retorna un reporte del detalle de creditos otorgados por cliente y por cuenta
   * %v 30/06/2014 - MatiasG: v1.0
   ******************************************************************************************************************/
   PROCEDURE GetCreditosOtorgadosDetalle(p_cdsucursal IN tblcuenta.cdsucursal%TYPE,
                                         p_identidad  IN entidades.identidad%TYPE,
                              p_idcuenta   IN tblcuenta.idcuenta%TYPE,
                                         p_creditoDesde IN tblcuenta.amotorgado%TYPE,
                                         p_creditoHasta IN tblcuenta.amotorgado%TYPE,
                                         p_cur_out      OUT cursor_type)
  IS
      v_modulo VARCHAR2(100) := 'PKG_REPORTE_CENTRAL.GetCreditosOtorgadosDetalle';
   BEGIN
      OPEN p_cur_out FOR
         SELECT re.dsregion region,
             su.dssucursal sucursal,
           ee.dsrazonsocial cliente,
                cu.nombrecuenta cuenta,
           ee.cdcuit,
                trunc(SUM(pkg_credito_central.GetDisponible(cu.idcuenta)),2) disponible,
                trunc(SUM(cu.amotorgado),2) otorgado,
                trunc(SUM(pkg_credito_central.GetUtilizado(cu.idcuenta)),2) utilizado,
            trunc(SUM(cu.amampliacion),2) amampliacion,
           trunc(SUM(cu.amampliacionextra),2) amampliacionextra
           FROM tblcuenta cu, sucursales su, entidades ee, tblregion re
          WHERE cu.cdsucursal = su.cdsucursal
            AND cu.amotorgado > 0
         AND su.cdregion = re.cdregion
        AND cu.identidad = ee.identidad
        AND cu.cdtipocuenta = '1'
          AND su.cdsucursal = NVL(p_cdsucursal,su.cdsucursal)
            AND ee.identidad = NVL(p_identidad,ee.identidad)
            AND cu.idcuenta = NVL(p_idcuenta,cu.idcuenta)
            AND cu.amotorgado BETWEEN NVL(p_creditoDesde,cu.amotorgado) AND NVL(p_creditoHasta,cu.amotorgado)
          GROUP BY re.dsregion, su.dssucursal, ee.dsrazonsocial, cu.nombrecuenta, ee.cdcuit
          ORDER BY cliente;

   EXCEPTION
      WHEN OTHERS THEN
         n_pkg_vitalpos_log_general.write(2, 'Modulo: ' || v_modulo || '  Error: ' || SQLERRM);
         RAISE;
   END GetCreditosOtorgadosDetalle;

  /**************************************************************************************************
  * Devuelve la deuda de un documento.
  * Siempre devuelve un valor positivo, la aclaración vale cuando el documento en NC
  * En caso que p_dtHasta <> null devuelve la deuda hasta p_dtHasta.  Si es null devuelve la deuda actual.
  * %v 19/05/2014 - MarianoL
  ***************************************************************************************************/
  function GetSaldoFactura(p_idDocTrx        in documentos.iddoctrx%type,
                           p_dtHasta         in date default null,
                           p_icForzarCalculo in number default 0) return number
    IS
       v_amDocumento         number := 0;
       v_amPagado            number := 0;
       v_amNcUsada           number := 0;
       v_cdEstadoComprobante documentos.cdestadocomprobante%type;
       v_cdComprobante       documentos.cdcomprobante%type;
       v_dtOperativa         date := N_PKG_VITALPOS_CORE.GetDT();
       v_dtHasta             date;
       v_Result              number;
       v_DocEmitido          documentos.cdestadocomprobante%type := '1       ';
       v_DocImpreso          documentos.cdestadocomprobante%type := '2       ';
       v_DocCanceladoTotal   documentos.cdestadocomprobante%type := '5       ';

    BEGIN

       --Si se pasó el parámetro tomo esta fecha como hasta, sino tomo la fecha operativa
       if p_dtHasta is not null then
          v_dtHasta := p_dtHasta;
       else
          v_dtHasta := v_dtOperativa;
       end if;

       --Buscar datos del documento
       select abs(d.amdocumento), d.cdcomprobante, d.cdestadocomprobante
       into   v_amDocumento, v_cdComprobante, v_cdEstadoComprobante
       from   documentos d
       where  d.iddoctrx = p_idDocTrx
       and   (d.cdcomprobante like 'FC%' or d.cdcomprobante like 'NC%' or d.cdcomprobante like 'ND%')
       and   d.dtdocumento <= trunc(v_dtHasta+1);

       --Calcular cuanto fue pagado
       if v_cdEstadoComprobante in (v_DocEmitido, v_DocImpreso) and trunc(v_dtOperativa) = trunc(v_dtHasta)
          and p_icForzarCalculo = 0 then
          v_amPagado := 0;

       elsif v_cdEstadoComprobante = v_DocCanceladoTotal and trunc(v_dtOperativa) = trunc(v_dtHasta)
          and p_icForzarCalculo = 0 then
          v_amPagado := v_amDocumento;

       else
          select nvl(sum(c.amimputado),0)
          into v_amPagado
          from tblcobranza c
          where c.iddoctrx = p_idDocTrx
            and c.dtimputado <= trunc(v_dtHasta+1);

          if v_cdComprobante like 'NC%' then  --En caso que el documento sea NC
             --Calcular cuanto se usó para pagar otros documentos o egresos
             select nvl(sum(abs(c.amimputado)),0)
             into v_amNcUsada
             from tblcobranza c
             where c.iddoctrx_pago = p_idDocTrx
               and c.dtimputado <= trunc(v_dtHasta+1);
          end if;

       end if;

       v_Result := v_amDocumento-v_amPagado-v_amNcUsada;

       if v_Result < 0 then
          v_Result := 0;    --Siempre devuelve positivo
       end if;

       return(v_Result);

    exception when others then
       return(0);
    end GetSaldoFactura;

   /*****************************************************************************************************************
   * Retorna un reporte de facturacion agrupado por region y sucursal
  * Los parametros de fecha son obligatorios
   * %v 30/06/2014 - MatiasG: v1.0
   * %v 21/04/2015 - MartinM: v1.1 - Se modifica las clausulas que contenian los parametros
   *                                 cuenta, entidad, persona y region para mejorar la performance del query
   ******************************************************************************************************************/
   PROCEDURE GetFacturacionGeneral(p_cdregion   IN tblregion.cdregion%TYPE,
                                   p_sucursales IN VARCHAR2,
                                   p_identidad  IN entidades.identidad%TYPE,
                                   p_idcuenta   IN tblcuenta.idcuenta%TYPE,
                                   p_filtro     IN INTEGER,
                                   p_fechaDesde IN DATE,
                                   p_fechaHasta IN DATE,
                                   p_cur_out    OUT cursor_type)
  IS
      v_modulo VARCHAR2(100) := 'PKG_REPORTE_CENTRAL.GetFacturacionGeneral';
     v_idReporte             VARCHAR2(40) := '';
   BEGIN
      v_idReporte := SetSucursalesSeleccionadas(p_sucursales);

      IF p_filtro = 0 THEN
         --todo
         OPEN p_cur_out FOR
        SELECT cdregion, region, cdsucursal, sucursal, SUM(importe) importe, SUM(saldo) saldo
         FROM (SELECT re.cdregion,
                  re.dsregion region,
                  su.cdsucursal,
                  su.dssucursal sucursal,
                  do.idcuenta,
                  trunc(do.dtdocumento) fecha,
                  substr(do.cdcomprobante, 0, 2) Descripcion,
                    trunc(do.amdocumento,2) importe,
                  GetSaldoFactura(do.iddoctrx) saldo
              FROM documentos do,sucursales su, tblregion re, tbltmp_sucursales_reporte rs
              WHERE do.cdsucursal = su.cdsucursal
               AND su.cdregion = re.cdregion
               AND su.cdsucursal = rs.cdsucursal
               AND rs.idreporte = v_idReporte
               AND (do.cdcomprobante LIKE ('FC%') OR do.cdcomprobante LIKE ('ND%') OR do.cdcomprobante LIKE ('NC%'))
               AND (do.identidadreal = p_identidad or p_identidad is null)
               AND (do.idcuenta = p_idcuenta or p_idcuenta is null)
               AND do.dtdocumento BETWEEN trunc(p_fechaDesde) AND trunc(p_fechaHasta + 1)
               AND (re.cdregion = p_cdregion or p_cdregion is null))
        GROUP BY cdregion, region, cdsucursal, sucursal;

      ELSIF p_filtro = 1 THEN
         --pago
         OPEN p_cur_out FOR
            SELECT cdregion, region, cdsucursal, sucursal, SUM(importe) importe, SUM(saldo) saldo
         FROM (SELECT re.cdregion,
                  re.dsregion region,
                  su.cdsucursal,
                  su.dssucursal sucursal,
                  do.idcuenta,
                  trunc(do.dtdocumento) fecha,
                  substr(do.cdcomprobante, 0, 2) Descripcion,
                    trunc(do.amdocumento,2) importe,
                  GetSaldoFactura(do.iddoctrx) saldo
              FROM documentos do, sucursales su, tblregion re, tbltmp_sucursales_reporte rs
              WHERE do.cdsucursal = su.cdsucursal
               AND su.cdregion = re.cdregion
               AND su.cdsucursal = rs.cdsucursal
               AND rs.idreporte = v_idReporte
               AND (do.cdcomprobante LIKE ('FC%') OR do.cdcomprobante LIKE ('NC%') OR do.cdcomprobante LIKE ('ND%'))
               AND (do.identidadreal = p_identidad or p_identidad is null)
               AND (do.idcuenta = p_idcuenta or p_idcuenta is null)
               AND do.dtdocumento BETWEEN trunc(p_fechaDesde) AND trunc(p_fechaHasta + 1)
               AND (re.cdregion = p_cdregion or p_cdregion is null)
               AND do.cdestadocomprobante = 5)
        GROUP BY cdregion, region, cdsucursal, sucursal;

      ELSIF p_filtro = 2 THEN
         --impago
         OPEN p_cur_out FOR
            SELECT cdregion, region, cdsucursal, sucursal, SUM(importe) importe, SUM(saldo) saldo
         FROM (SELECT re.cdregion,
                  re.dsregion region,
                  su.cdsucursal,
                  su.dssucursal sucursal,
                  do.idcuenta,
                  trunc(do.dtdocumento) fecha,
                  substr(do.cdcomprobante, 0, 2) Descripcion,
                    trunc(do.amdocumento,2) importe,
                  GetSaldoFactura(do.iddoctrx) saldo
              FROM documentos do, sucursales su, tblregion re, tbltmp_sucursales_reporte rs
              WHERE do.cdsucursal = su.cdsucursal
               AND su.cdregion = re.cdregion
               AND su.cdsucursal = rs.cdsucursal
               AND rs.idreporte = v_idReporte
               AND (do.cdcomprobante LIKE ('FC%') OR do.cdcomprobante LIKE ('NC%') OR do.cdcomprobante LIKE ('ND%'))
               AND (do.identidadreal = p_identidad or p_identidad is null)
               AND (do.idcuenta = p_idcuenta or p_idcuenta is null)
               AND do.dtdocumento BETWEEN trunc(p_fechaDesde) AND trunc(p_fechaHasta + 1)
               AND (re.cdregion = p_cdregion or p_cdregion is null)
               AND do.cdestadocomprobante NOT IN ('3','5'))
        GROUP BY cdregion, region, cdsucursal, sucursal;
      END IF;

    CleanSucursalesSeleccionadas(v_idReporte);
   EXCEPTION
      WHEN OTHERS THEN
         n_pkg_vitalpos_log_general.write(2, 'Modulo: ' || v_modulo || '  Error: ' || SQLERRM);
         RAISE;
   END GetFacturacionGeneral;

   /*****************************************************************************************************************
   * Retorna un reporte del detalle de facturacion
   * filtro (todos=0, pagos=1, impagos=2)
   * %v 30/06/2014 - MatiasG: v1.0
   * %v 21/04/2015 - MartinM: v1.1 - Se modifica las clausulas que contenian los parametros
   *                                 cuenta, entidad, persona y region para mejorar la performance del query
   * %v 26/11/2015 - LucianoF: v1.1 - Se agrega la fecha de escaneo de la factura
   ******************************************************************************************************************/
   PROCEDURE GetFacturacionDetalle(p_cdsucursal IN tblcuenta.cdsucursal%TYPE,
                                   p_identidad  IN entidades.identidad%TYPE,
                                   p_idcuenta   IN tblcuenta.idcuenta%TYPE,
                                   p_fechaDesde IN DATE,
                                   p_fechaHasta IN DATE,
                                   p_filtro     IN INTEGER,
                                   p_cur_out    OUT cursor_type)
   IS

      v_modulo VARCHAR2(100) := 'PKG_REPORTE_CENTRAL.GetFacturacionDetalle';

   BEGIN

      IF p_filtro = 0 THEN

         --todo
         OPEN p_cur_out FOR
          WITH salida as
           (
            select ds.iddoctrx, ds.dtsalida , p.dsapellido ||', '|| p.dsnombre persona
            from tbldocumento_salida ds, personas p
            where ds.idpersona = p.idpersona
            and ds.cdmensajesalida = 1
            )
        SELECT re.dsregion                  region,
               su.dssucursal                sucursal,
               ee.dsrazonsocial             cliente,
               ee.cdcuit                    cdcuit,
               cu.idcuenta                  idcuenta,
               cu.nombrecuenta              cuenta,
               do.dtdocumento               fecha,
               substr(do.cdcomprobante, 1, 2) || ' ' ||
               substr(do.cdcomprobante, 4, 1) || ' ' ||
               Trim(do.cdpuntoventa) || '-' || do.sqcomprobante Descripcion,
               do.iddoctrx                  iddoctrx,
               trunc(do.amdocumento,2)      importe,
               GetSaldoFactura(do.iddoctrx) saldo,
               ec.dsestado                  estado,
               p.dsapellido || ', ' || p.dsnombre cajero,
               mm.cdcaja,
               s.dtsalida                  fecha_salida,
               s.persona                   persona,
               mm.id_canal                  canal
          FROM documentos         do,
               tblcuenta          cu,
               sucursales         su,
               entidades          ee,
               tblregion          re,
               estadocomprobantes ec,
               movmateriales       mm,
               salida              s,
               personas            p
         WHERE do.identidadreal = cu.identidad
           AND do.idcuenta      = cu.idcuenta
           AND cu.identidad     = ee.identidad
           AND ec.cdcomprobante = do.cdcomprobante
           And ec.cdestado      = do.cdestadocomprobante
           AND su.cdregion      = re.cdregion
           AND do.cdsucursal    = su.cdsucursal
           AND mm.idpersonaresponsable = p.idpersona
           AND do.iddoctrx      = s.iddoctrx(+)
           AND do.idmovmateriales = mm.idmovmateriales
           AND (do.cdcomprobante LIKE ('FC%') OR do.cdcomprobante LIKE ('ND%') OR do.cdcomprobante LIKE ('NC%'))
           AND (su.cdsucursal   = p_cdsucursal or p_cdsucursal is null)
           AND (ee.identidad    = p_identidad  or p_identidad  is null)
           AND (cu.idcuenta     = p_idcuenta   or p_idcuenta   is null)
           AND do.dtdocumento BETWEEN trunc( p_fechaDesde ) AND trunc( p_fechaHasta + 1 )
      ORDER BY cliente;

      ELSIF p_filtro = 1 THEN

         --pago
         OPEN p_cur_out FOR
         WITH salida as
           (
            select ds.iddoctrx, ds.dtsalida , p.dsapellido ||', '|| p.dsnombre persona
            from tbldocumento_salida ds, personas p
            where ds.idpersona = p.idpersona
            and ds.cdmensajesalida = 1
            )
        SELECT re.dsregion                  region,
               su.dssucursal                sucursal,
               ee.dsrazonsocial             cliente,
               ee.cdcuit                    cdcuit,
               cu.idcuenta                  idcuenta,
               cu.nombrecuenta              cuenta,
               do.dtdocumento               fecha,
               substr(do.cdcomprobante, 1, 2) || ' ' ||
               substr(do.cdcomprobante, 4, 1) || ' ' ||
               Trim(do.cdpuntoventa) || '-' ||do.sqcomprobante Descripcion,
               do.iddoctrx                  iddoctrx,
               trunc(do.amdocumento,2)      importe,
               GetSaldoFactura(do.iddoctrx) saldo,
               ec.dsestado                  estado,
               p.dsapellido || ', ' || p.dsnombre cajero,
               mm.cdcaja,
               s.dtsalida                  fecha_salida,
               s.persona                   persona,
               mm.id_canal                  canal
          FROM documentos         do,
               tblcuenta          cu,
               sucursales         su,
               entidades          ee,
               tblregion          re,
               estadocomprobantes ec,
               salida              s,
               movmateriales       mm,
               personas            p
         WHERE do.identidadreal       = cu.identidad
           AND do.idcuenta            = cu.idcuenta
           AND cu.identidad           = ee.identidad
           AND ec.cdcomprobante       = do.cdcomprobante
           And ec.cdestado            = do.cdestadocomprobante
           AND su.cdregion            = re.cdregion
           AND do.cdsucursal          = su.cdsucursal
           AND mm.idpersonaresponsable = p.idpersona
           AND do.iddoctrx      = s.iddoctrx(+)
           AND do.idmovmateriales = mm.idmovmateriales
           AND (su.cdsucursal         = p_cdsucursal or p_cdsucursal is null)
           AND (ee.identidad          = p_identidad  or p_identidad  is null)
           AND (cu.idcuenta           = p_idcuenta   or p_idcuenta   is null)
           AND  do.dtdocumento BETWEEN trunc( p_fechaDesde ) AND trunc( p_fechaHasta + 1 )
           AND (do.cdcomprobante LIKE ('FC%') OR do.cdcomprobante LIKE ('ND%')  OR do.cdcomprobante LIKE ('NC%'))
           AND do.cdestadocomprobante = 5
      ORDER BY cliente;

      ELSIF p_filtro = 2 THEN

         --impago
         OPEN p_cur_out FOR
         WITH salida as
           (
            select ds.iddoctrx, ds.dtsalida , p.dsapellido ||', '|| p.dsnombre persona
            from tbldocumento_salida ds, personas p
            where ds.idpersona = p.idpersona
            and ds.cdmensajesalida = 1
            )
        SELECT re.dsregion                  region,
               su.dssucursal                sucursal,
               ee.dsrazonsocial             cliente,
               ee.cdcuit                    cdcuit,
               cu.idcuenta                  idcuenta,
               cu.nombrecuenta              cuenta,
               do.dtdocumento               fecha,
               substr(do.cdcomprobante, 1, 2) || ' ' ||
               substr(do.cdcomprobante, 4, 1) || ' ' ||
               Trim(do.cdpuntoventa) || '-' ||do.sqcomprobante Descripcion,
               do.iddoctrx                  iddoctrx,
               trunc(do.amdocumento,2)      importe,
               GetSaldoFactura(do.iddoctrx) saldo,
               ec.dsestado                  estado,
               p.dsapellido || ', ' || p.dsnombre cajero,
               mm.cdcaja,
               s.dtsalida                  fecha_salida,
               s.persona                   persona,
               mm.id_canal                  canal
          FROM documentos         do,
               tblcuenta          cu,
               sucursales         su,
               entidades          ee,
               tblregion          re,
               estadocomprobantes ec,
               salida              s,
               movmateriales       mm,
               personas            p
         WHERE do.identidadreal        = cu.identidad
           AND do.idcuenta             = cu.idcuenta
           AND cu.identidad            = ee.identidad
           AND ec.cdcomprobante        = do.cdcomprobante
           And ec.cdestado             = do.cdestadocomprobante
           AND su.cdregion             = re.cdregion
           AND do.cdsucursal           = su.cdsucursal
           AND mm.idpersonaresponsable = p.idpersona
           AND do.iddoctrx      = s.iddoctrx(+)
           AND do.idmovmateriales = mm.idmovmateriales
           AND (do.cdcomprobante LIKE ('FC%') OR do.cdcomprobante LIKE ('ND%')  OR do.cdcomprobante LIKE ('NC%'))
           AND (su.cdsucursal          = p_cdsucursal or p_cdsucursal is null)
           AND (ee.identidad           = p_identidad  or p_identidad  is null)
           AND (cu.idcuenta            = p_idcuenta   or p_idcuenta   is null)
           AND do.dtdocumento BETWEEN trunc(p_fechaDesde) AND trunc(p_fechaHasta+1)
           AND do.cdestadocomprobante != 5
      ORDER BY cliente;

      END IF;
   EXCEPTION
      WHEN OTHERS THEN
         n_pkg_vitalpos_log_general.write(2, 'Modulo: ' || v_modulo || '  Error: ' || SQLERRM);
         RAISE;

   END GetFacturacionDetalle;

   /*****************************************************************************************************************
   * Retorna un reporte de ingresos agrupado por region y sucursal
   * %v 30/06/2014 - MatiasG: v1.0
   * %v 02/07/2019 - APW - cambio forma de busqueda sin parámetros por performance
   ******************************************************************************************************************/
   PROCEDURE GetIngresosGeneral(p_cdregion   IN tblregion.cdregion%TYPE,
                                p_sucursales IN VARCHAR2,
                                p_fechaDesde IN DATE,
                                p_fechaHasta IN DATE,
                                p_cdmedio    IN tblconfingreso.cdmedio%TYPE,
                                p_cdtipo     IN tblconfingreso.cdtipo%TYPE,
                      p_identidad  IN tblcuenta.identidad%TYPE,
                      p_idcuenta   IN tblcuenta.idcuenta%TYPE,
                                p_cur_out    OUT cursor_type) IS
      v_modulo    VARCHAR2(100) := 'PKG_REPORTE_CENTRAL.GetIngresosGeneral';
      v_idReporte VARCHAR2(40) := '';
   BEGIN
      v_idReporte := SetSucursalesSeleccionadas(p_sucursales);

      OPEN p_cur_out FOR
        SELECT re.cdregion,
               re.dsregion,
               su.cdsucursal,
               su.dssucursal,
               trunc(SUM(ii.amingreso), 2) importe
          FROM tblingreso                ii,
               tblconfingreso            ci,
               sucursales                su,
               tblregion                 re,
               tblcuenta                 cu,
               tbltmp_sucursales_reporte rs
         WHERE ii.cdconfingreso = ci.cdconfingreso
           AND ii.cdsucursal = su.cdsucursal
           AND su.cdregion = re.cdregion
           AND ii.cdsucursal = ci.cdsucursal
           AND ci.cdforma = decode(p_cdmedio, '999', '5', ci.cdforma) --CL
           AND ii.idcuenta = cu.idcuenta
           AND su.cdsucursal = rs.cdsucursal
           AND rs.idreporte = v_idReporte
           AND ci.cdaccion not in ('2', '3', '6', '7') --Ajuste ingreso y Ajuste egreso, Accion rechazo AC/Sucursal
           AND (p_identidad is null or cu.identidad = p_identidad)
           AND (p_idcuenta is null or cu.idcuenta = p_idcuenta)
           AND (p_cdregion is null or re.cdregion = p_cdregion)
           AND ii.dtingreso BETWEEN trunc(p_fechaDesde) AND trunc(p_fechaHasta + 1)
           AND ci.cdmedio =  NVL(decode(p_cdmedio, '999', ci.cdmedio, p_cdmedio), ci.cdmedio)
           AND ci.cdtipo = NVL(p_cdtipo, ci.cdtipo)
         GROUP BY re.cdregion, re.dsregion, su.cdsucursal, su.dssucursal;

      CleanSucursalesSeleccionadas(v_idReporte);
   EXCEPTION
      WHEN OTHERS THEN
         n_pkg_vitalpos_log_general.write(2, 'Modulo: ' || v_modulo || '  Error: ' || SQLERRM);
         RAISE;
   END GetIngresosGeneral;

 /*****************************************************************************************************************
   * Retorna un reporte de ingresos agrupado por region y sucursal
   * %v 30/06/2014 - MatiasG: v1.0
   * %v 02/07/2019 - APW - cambio forma de busqueda sin parámetros por performance
   ******************************************************************************************************************/
   PROCEDURE GetContracargosGeneral(p_cdregion   IN tblregion.cdregion%TYPE,
                                p_sucursales IN VARCHAR2,
                                p_fechaDesde IN DATE,
                                p_fechaHasta IN DATE,
                                p_identidad  IN tblcuenta.identidad%TYPE,
                                p_idcuenta   IN tblcuenta.idcuenta%TYPE,
                                p_cur_out    OUT cursor_type) IS
      v_modulo    VARCHAR2(100) := 'PKG_REPORTE_CENTRAL.GetContracargosGeneral';
      v_idReporte VARCHAR2(40) := '';
   BEGIN
      v_idReporte := SetSucursalesSeleccionadas(p_sucursales);

      OPEN p_cur_out FOR
         SELECT         re.cdregion,
                re.dsregion,
                su.cdsucursal,
                su.dssucursal,
                trunc(SUM(ii.amingreso), 2) importe
           FROM tblingreso                ii,
                tblconfingreso            ci,
                sucursales                su,
                tblregion                 re,
                tblcuenta                 cu,
                tblclcontracargo          cc,
                tbltmp_sucursales_reporte rs
          WHERE ii.cdconfingreso = ci.cdconfingreso
            AND ii.cdsucursal = su.cdsucursal
            AND su.cdregion = re.cdregion
            AND ii.cdsucursal = ci.cdsucursal
            AND ii.idcuenta = cu.idcuenta
            AND ii.idingreso = cc.idingreso
            AND su.cdsucursal = rs.cdsucursal
            AND rs.idreporte = v_idReporte
            AND (p_identidad is null or cu.identidad =p_identidad)
            AND (p_idcuenta is null or cu.idcuenta =p_idcuenta)
            AND (p_cdregion is null or re.cdregion = p_cdregion)
            AND ii.dtingreso BETWEEN trunc(p_fechaDesde) AND trunc(p_fechaHasta + 1)
         GROUP BY re.cdregion, re.dsregion, su.cdsucursal, su.dssucursal;

      CleanSucursalesSeleccionadas(v_idReporte);
   EXCEPTION
      WHEN OTHERS THEN
         n_pkg_vitalpos_log_general.write(2, 'Modulo: ' || v_modulo || '  Error: ' || SQLERRM);
         RAISE;
   END GetContracargosGeneral;


    /*****************************************************************************************************************
   * Retorna un reporte de ingresos agrupados por camiones de transportistas
   * %v 04/02/2016 - LucianoF: v1.0
   * %v 18/03/2016 - APW - Agrego filtro por estado de guia
   * %v 26/05/2017 - IAquilano - Agrego dtasignada para que traiga el horario de salida del camion.
   * %v 09/05/2019 - LM. se agrega la condicion de que no devuelva guias sin fecha de asignacion.
   ******************************************************************************************************************/
   PROCEDURE GetCamionesPorDia( p_sucursales IN VARCHAR2,
                                p_fechaDesde IN DATE,
                                p_fechaHasta IN DATE,
                                p_cur_out    OUT cursor_type) IS
      v_modulo    VARCHAR2(100) := 'PKG_REPORTE_CENTRAL.GetCamionesPorDia';
      v_idReporte VARCHAR2(40) := '';
   BEGIN
      v_idReporte := SetSucursalesSeleccionadas(p_sucursales);

      OPEN p_cur_out FOR
           select s.dssucursal, trunc(docg.dtdocumento) fecha, e.cdcuit, e.dsrazonsocial,
                   upper(replace(replace (nvl(gt.vehiculo,'xxx'),' ',''),'-','')) vehiculo, sum(docg.amdocumento) monto, gt.dtasignada Hora_Salida, count(distinct(gt.identidad)) as cantpedidos
           from guiasdetransporte gt,
                documentos docg,
                entidades e,
                sucursales s,
                tbltmp_sucursales_reporte rs
           where gt.iddoctrx = docg.iddoctrx
           and docg.dtdocumento between trunc(p_fechaDesde) and trunc(p_fechaHasta + 1)
           and gt.idtransportista = e.identidad
           and docg.cdsucursal = s.cdsucursal
           and docg.cdcomprobante = 'GUIA'
           and gt.icestado in ('4','5','7')
           and gt.dtasignada is not null
           and s.cdsucursal = rs.cdsucursal
           and rs.idreporte = v_idReporte
           group by s.dssucursal, trunc(docg.dtdocumento), e.cdcuit, e.dsrazonsocial, upper(replace(replace (nvl(gt.vehiculo,'xxx'),' ',''),'-','')),gt.dtasignada
           order by s.dssucursal, trunc(docg.dtdocumento), e.cdcuit, e.dsrazonsocial, upper(replace(replace (nvl(gt.vehiculo,'xxx'),' ',''),'-','')),gt.dtasignada;

      CleanSucursalesSeleccionadas(v_idReporte);
   EXCEPTION
      WHEN OTHERS THEN
         n_pkg_vitalpos_log_general.write(2, 'Modulo: ' || v_modulo || '  Error: ' || SQLERRM);
         RAISE;
   END GetCamionesPorDia;


   /*****************************************************************************************************************
   * Retorna un reporte del detalle de Ingresos
   * %v 30/06/2014 - MatiasG: v1.0
   * %v 08/05/2015 - MartinM: v1.1 - cambio el group by para que agrupe los ingresos
   * %v 17/02/2016 - LucianoF: v1.2 - divido en una union para poder incluir si las tarjetas son manuales o automaticas
   * %v 02/07/2019 - APW - cambio forma de busqueda sin parámetros por performance
   ******************************************************************************************************************/
   PROCEDURE GetIngresosDetalle(p_cdsucursal IN tblcuenta.cdsucursal%TYPE,
                                p_identidad  IN entidades.identidad%TYPE,
                                p_idcuenta   IN tblcuenta.idcuenta%TYPE,
                                p_fechaDesde IN DATE,
                                p_fechaHasta IN DATE,
                                p_cdmedio    IN tblconfingreso.cdmedio%TYPE,
                                p_cdtipo     IN tblconfingreso.cdtipo%TYPE,
                                p_cur_out    OUT cursor_type)
  IS
      v_modulo VARCHAR2(100) := 'PKG_REPORTE_CENTRAL.GetIngresosDetalle';
   BEGIN
      OPEN p_cur_out FOR
         SELECT re.dsregion,
                su.dssucursal,
                ee.dsrazonsocial,
                cu.nombrecuenta cuenta,
                ee.cdcuit,
                max(ii.idingreso) idingreso,-- MM - Para que sumarice por iguales descripciones y lo saco del group by
                ii.dtingreso,
                pkg_ingreso_central.GetDescIngreso(ci.cdconfingreso,ii.cdsucursal) dsingreso,
                trunc(SUM(ii.amingreso),2) importe,
                pe.dsapellido||' '||pe.dsnombre cajero
           FROM tblingreso ii, tblcuenta cu, tblconfingreso ci, sucursales su, tblregion re, entidades ee, tblmovcaja mc, personas pe
          WHERE ii.idcuenta      = cu.idcuenta
            AND ii.cdconfingreso = ci.cdconfingreso
            AND ii.cdsucursal    = ci.cdsucursal
            AND ii.cdsucursal    = su.cdsucursal
            AND su.cdregion      = re.cdregion
            AND cu.identidad     = ee.identidad
            AND (p_identidad is null or ee.identidad = p_identidad)
            AND (p_idcuenta is null or cu.idcuenta = p_idcuenta)
            AND (p_cdsucursal is null or su.cdsucursal = p_cdsucursal)
            AND ci.cdforma=decode(p_cdmedio,'999','5',ci.cdforma)--CL
            AND ii.dtingreso BETWEEN trunc(p_fechaDesde) AND trunc(p_fechaHasta + 1)
            AND ci.cdmedio       = NVL(decode(p_cdmedio,'999',ci.cdmedio,p_cdmedio), ci.cdmedio)
            AND ci.cdtipo        = NVL(p_cdtipo, ci.cdtipo)
            AND ii.idmovcaja     = mc.idmovcaja
            AND mc.idpersonaresponsable  = pe.idpersona
            AND not exists (select 1        --No rechazado en sucursal
                              from tblingreso i2,
                                   tblconfingreso ci2
                             where i2.idingresorechazado = ii.idingreso
                               and ci2.cdconfingreso     = i2.cdconfingreso
                               and ci2.cdaccion          = '2')
            AND ci.cdaccion not in ('2','3','6','7') --Ajuste ingreso y Ajuste egreso, Accion rechazo AC/Sucursal
            AND ci.cdmedio not in ('3','7') --Quito las tarjetas porque se unen en el otro query
       GROUP BY re.dsregion,su.dssucursal,ee.dsrazonsocial,cu.nombrecuenta,ee.cdcuit,
                ii.dtingreso,  pkg_ingreso_central.GetDescIngreso(ci.cdconfingreso,ii.cdsucursal),
                pe.dsapellido||' '||pe.dsnombre
       UNION
         SELECT re.dsregion,
                su.dssucursal,
                ee.dsrazonsocial,
                cu.nombrecuenta cuenta,
                ee.cdcuit,
                max(ii.idingreso) idingreso,-- MM - Para que sumarice por iguales descripciones y lo saco del group by
                ii.dtingreso,
                case when ta.modoingreso is null then
                pkg_ingreso_central.GetDescIngreso(ci.cdconfingreso,ii.cdsucursal) || ' (M)'
                else
                pkg_ingreso_central.GetDescIngreso(ci.cdconfingreso,ii.cdsucursal)|| ' (A)'
                end dsingreso,
                trunc(SUM(ii.amingreso),2) importe,
                pe.dsapellido||' '||pe.dsnombre cajero
           FROM tblingreso ii, tblcuenta cu, tblconfingreso ci, sucursales su, tblregion re, entidades ee, tblmovcaja mc, personas pe,
                tbltarjeta ta
          WHERE ii.idcuenta      = cu.idcuenta
            AND ii.cdconfingreso = ci.cdconfingreso
            AND ii.cdsucursal    = ci.cdsucursal
            AND ii.cdsucursal    = su.cdsucursal
            AND su.cdregion      = re.cdregion
            AND cu.identidad     = ee.identidad
            AND ta.idingreso     = ii.idingreso
            AND (p_identidad is null or ee.identidad = p_identidad)
            AND (p_idcuenta is null or cu.idcuenta = p_idcuenta)
            AND (p_cdsucursal is null or su.cdsucursal = p_cdsucursal)
            AND ci.cdforma=decode(p_cdmedio,'999','5',ci.cdforma)--CL
            AND ii.dtingreso BETWEEN trunc(p_fechaDesde) AND trunc(p_fechaHasta + 1)
            AND ci.cdmedio       = NVL(decode(p_cdmedio,'999',ci.cdmedio,p_cdmedio), ci.cdmedio)
            AND ci.cdtipo        = NVL(p_cdtipo, ci.cdtipo)
            AND ii.idmovcaja     = mc.idmovcaja
            AND mc.idpersonaresponsable  = pe.idpersona
            AND not exists (select 1        --No rechazado en sucursal
                              from tblingreso i2,
                                   tblconfingreso ci2
                             where i2.idingresorechazado = ii.idingreso
                               and ci2.cdconfingreso     = i2.cdconfingreso
                               and ci2.cdaccion          = '2')
            AND ci.cdaccion not in ('2','3','6','7') --Ajuste ingreso y Ajuste egreso, Accion rechazo AC/Sucursal
       GROUP BY re.dsregion,su.dssucursal,ee.dsrazonsocial,cu.nombrecuenta,ee.cdcuit,
                ii.dtingreso,
                case when ta.modoingreso is null then
                pkg_ingreso_central.GetDescIngreso(ci.cdconfingreso,ii.cdsucursal) || ' (M)'
                else
                pkg_ingreso_central.GetDescIngreso(ci.cdconfingreso,ii.cdsucursal)|| ' (A)'
                end,
                pe.dsapellido||' '||pe.dsnombre;
   EXCEPTION
      WHEN OTHERS THEN
         n_pkg_vitalpos_log_general.write(2, 'Modulo: ' || v_modulo || '  Error: ' || SQLERRM);
         RAISE;
   END GetIngresosDetalle;




   /*****************************************************************************************************************
   * Retorna un reporte del detalle de Contracargos
   * %v 12/07/2016 - LucianoF: v1.0
   * %v 02/07/2019 - APW - cambio forma de busqueda sin parámetros por performance
   ******************************************************************************************************************/
   PROCEDURE GetContracargosDetalle(p_cdsucursal IN tblcuenta.cdsucursal%TYPE,
                                p_identidad  IN entidades.identidad%TYPE,
                                p_idcuenta   IN tblcuenta.idcuenta%TYPE,
                                p_fechaDesde IN DATE,
                                p_fechaHasta IN DATE,
                                p_cur_out    OUT cursor_type)
  IS
      v_modulo VARCHAR2(100) := 'PKG_REPORTE_CENTRAL.GetContracargosDetalle';
   BEGIN
      OPEN p_cur_out FOR
        SELECT         re.dsregion,
                su.dssucursal,
                ee.dsrazonsocial,
                cu.nombrecuenta cuenta,
                ee.cdcuit,
                ii.idingreso,
                ii.dtingreso,
                pkg_ingreso_central.GetDescIngreso(ci.cdconfingreso,ii.cdsucursal) dsingreso,
                ii.amingreso importe
           FROM tblclcontracargo cc, tblingreso ii, tblcuenta cu, tblconfingreso ci, sucursales su, tblregion re, entidades ee
          WHERE ii.idcuenta      = cu.idcuenta
            AND ii.cdconfingreso = ci.cdconfingreso
            AND ii.cdsucursal    = ci.cdsucursal
            AND ii.cdsucursal    = su.cdsucursal
            AND su.cdregion      = re.cdregion
            AND cu.identidad     = ee.identidad
            and ii.idingreso     = cc.idingreso
            AND (p_cdsucursal is null or su.cdsucursal = p_cdsucursal)
            AND (p_identidad is null or cu.identidad = p_identidad)
            AND (p_idcuenta is null or cu.idcuenta = p_idcuenta)
            AND ii.dtingreso BETWEEN trunc(p_fechaDesde) AND trunc(p_fechaHasta + 1);
   EXCEPTION
      WHEN OTHERS THEN
         n_pkg_vitalpos_log_general.write(2, 'Modulo: ' || v_modulo || '  Error: ' || SQLERRM);
         RAISE;
   END GetContracargosDetalle;

    /*****************************************************************************************************************
    * Retorna un cursor mostrando como pagan los cliente por sucursal entre un rando de fechas
    * %v 16/03/2015 - JBodnar: v1.0
    ******************************************************************************************************************/
    Procedure GetFormaDePago(p_sucursales In Varchar2,
                             p_fechaDesde In Date,
                             p_fechaHasta In Date ,
                             p_cur_out Out cursor_type) Is
       v_modulo    Varchar2(100) := 'PKG_REPORTE_CENTRAL.GetFormaDePago';
       v_idReporte Varchar2(40) := '';
    Begin
       v_idReporte := SetSucursalesSeleccionadas(p_sucursales);

       Open p_cur_out For
         Select
            case fi.cdforma
              when '1' then mi.dsmedio
              else  mi.dsmedio||' '||fi.dsforma
            end dsmedio,
            case fi.cdforma
              when '1' then ti.dstipo
              else  ti.dstipo||' '||fi.dsforma
            end dstipo,
            su.dssucursal,
            su.cdsucursal,
            case fi.cdforma
              when '2' then '97'
              when '3' then '98'
              when '4' then '96'
              when '5' then '99'
              else  ci.cdmedio
            end cdmedio,
            Sum(ii.amingreso) amingreso
            From
            tblmedioingreso mi,
            tblconfingreso ci,
            tbltipoingreso ti,
            tblingreso ii,
            tblformaingreso fi,
            tbltmp_sucursales_reporte rs,
            sucursales su
           Where ci.cdconfingreso = ii.cdconfingreso
             And ii.cdsucursal = su.cdsucursal
             And ci.cdmedio = mi.cdmedio
             And ci.cdtipo = ti.cdtipo
             And ii.cdsucursal = ci.cdsucursal
             And su.cdsucursal = rs.cdsucursal
             And fi.cdforma = ci.cdforma
             And rs.idreporte = v_idReporte
             And ii.dtingreso Between trunc(p_fechaDesde) And trunc(p_fechaHasta + 1)
             And ci.cdaccion = '1' --Ingreso
             --And ci.cdforma  <> '4' --No es PB
             And not exists (select 1 from tblingreso ir where ir.idingresorechazado=ii.idingreso)--No Rechazado
             And mi.cdmedio not in ('8') --Transferencia
           Group By case fi.cdforma
                     when '1' then mi.dsmedio
                     else  mi.dsmedio||' '||fi.dsforma
                    end ,
                    case fi.cdforma
                     when '1' then ti.dstipo
                     else  ti.dstipo||' '||fi.dsforma
                    end ,
                    su.dssucursal,
                    su.cdsucursal,
                    case fi.cdforma
                      when '2' then '97'
                      when '3' then '98'
                      when '4' then '96'
                      when '5' then '99'
                      else  ci.cdmedio
                    end  ;

       CleanSucursalesSeleccionadas(v_idReporte);
    Exception
       When Others Then
          n_pkg_vitalpos_log_general.write(2, 'Modulo: ' || v_modulo ||
                                            '  Error: ' || Sqlerrm);
          Raise;
    End GetFormaDePago;

  /**************************************************************************************************
    * Devuelve la deuda (importe aún impago) de un cheque rechazado.
    * Si no encuentra el cheque o dtAcreditación <> null (porque ya está cancelado) se producirá un
    * exception y la función devuelve 0.
    * %v 21/02/2015 - MarianoL
    * %v 16/11/2017 - IAquilano - Comento el estado del cheque
    ***************************************************************************************************/
    function GetDeudaCheque(p_idIngresoCheque in tblingreso.idingreso%type)
       return number
    is
       v_amCheque      number := 0;
       v_amCobrado     number := 0;
    begin

       --Buscar el importe del cheque rechazado y que esté pendiente de cobro
       select abs(i.amingreso)
         into v_amCheque
         from tblingreso i,
              tblcheque c
        where i.idingreso = p_idIngresoCheque
          --and i.cdestado = '4'          --Rechazado
          and c.idingreso = i.idingreso
          and c.dtacreditacion is null; --Pendiente de cobro

       --Buscar cuánto se cobró del cheque
       select nvl(sum(co.amimputado),0)
         into v_amCobrado
         from tblcobranza co
        where co.idingreso_pago = p_idIngresoCheque;

       return v_amCheque - v_amCobrado;

    exception when others then
       return(0);
    end GetDeudaCheque;

   /*****************************************************************************************************************
   * Retorna un reporte del detalle de cheques
   * %v 25/09/2014 - JBodnar: v1.0
   ******************************************************************************************************************/
   Procedure GetChequesDetalle(p_cdsucursal      In tblcuenta.cdsucursal%Type,
                               p_identidad       In entidades.identidad%Type,
                               p_idcuenta        In tblcuenta.idcuenta%Type,
                               p_fechaDesde      In Date,
                               p_fechaHasta      In Date,
                               p_cdestado        In Integer,
                               p_cdmotivorechazo In tblmotivorechazo.cdmotivorechazo%type,
                               p_cur_out         Out cursor_type)

  IS
      v_modulo VARCHAR2(100) := 'PKG_REPORTE_CENTRAL.GetChequesDetalle';
   BEGIN

   if p_cdestado=0 then
      --Todos los estados sin filtro
       GetChequesTodos(p_cdsucursal,p_identidad,p_idcuenta,  p_fechaDesde, p_fechaHasta, p_cdmotivorechazo, p_cur_out);

   elsif  p_cdestado=1 then
      --Acreditado
      GetChequesAcreditados(p_cdsucursal,p_identidad,p_idcuenta, p_fechaDesde, p_fechaHasta, p_cur_out);

   elsif  p_cdestado=2 then
      --No Acreditado
      GetChequesNoAcreditados(p_cdsucursal,p_identidad,p_idcuenta, p_fechaDesde, p_fechaHasta, p_cur_out);

   else
      --Rechazado p_cdestado=3
      GetChequesRechazadosResumido(p_cdsucursal,p_identidad,p_idcuenta, p_fechaDesde, p_fechaHasta, p_cdmotivorechazo, p_cur_out);

   end if;

   return;

   EXCEPTION
      WHEN OTHERS THEN
         n_pkg_vitalpos_log_general.write(2, 'Modulo: ' || v_modulo || '  Error: ' || SQLERRM);
         RAISE;
   END GetChequesDetalle;


   /*****************************************************************************************************************
   * Retorna un reporte del detalle de cheques con parametros pensado para comisionistas
   * %v 28/08/2015 - MartinM: v1.0
   * %v 26/12/2017 - LM: se permite que busque todos los comisionistas y se devuelve en el cursor los datos del comi
   ******************************************************************************************************************/
   Procedure GetChequesDetalleCO (p_sucursales         IN  tblcuenta.cdsucursal%TYPE                 ,
                                  p_idcomisionista     IN  entidades.identidad%TYPE                  ,
                                  p_fechaDesde         IN  DATE                                      ,
                                  p_fechaHasta         IN  DATE                                      ,
                                  p_cdestado           IN  INTEGER                                   ,
                                  p_cdmotivorechazo    IN  tblmotivorechazo.cdmotivorechazo%TYPE     ,
                                  p_cur_out            OUT cursor_type                               ) IS

      v_modulo    VARCHAR2(100) := 'PKG_REPORTE_CENTRAL.GetChequesDetalleCO';
      v_idReporte VARCHAR2(40)  := '';

   BEGIN

         v_idReporte := SetSucursalesSeleccionadas(p_sucursales);

   OPEN  p_cur_out
     FOR SELECT *
           FROM (  SELECT distinct d.sqcomprobante                         sqcomprobante      ,
                          ii.dtingreso                                     dtingreso          ,
                          eeco.cdcuit                                      cuitComi           ,
                          eeco.dsrazonsocial                               razonSocialComi    ,
                          ee.cdcuit                                        cdcuit             ,
                          ee.dsrazonsocial                                 dsrazonsocial      ,
                          cu.nombrecuenta                                  nombrecuenta       ,
                          ii.amingreso                                     amingreso          ,
                          bb.dsbanco                                       dsbanco            ,
                          sb.dssucursal                                    dssucursalbanco    ,
                          ch.dtemision                                     dtemision          ,
                          CASE WHEN ch.dtacreditacion is not null                             --Acreditado
                                AND not exists (select 1 from tblingreso ir where ir.idingresorechazado = ii.idingreso)
                               THEN ch.dtacreditacion
                               WHEN ch.dtacreditacion is null                                 --No Acreditado
                                AND not exists (select 1 from tblingreso ir where ir.idingresorechazado = ii.idingreso)
                               THEN (ch.dtcobro + (sb.qthorasclearing / 24))                  --Rechazado
                               WHEN     exists (select 1 from tblingreso ir where ir.idingresorechazado = ii.idingreso)
                               THEN nvl(ch.dtacreditacion,(ch.dtcobro + (sb.qthorasclearing / 24)))
                          END                                              deposito           ,
                          ch.vlnumero                                      vlnumero           ,
                          DECODE(ac.icchequepropio,1,'Propio',0,'Tercero') tipo               ,
                          mr.dsmotivorechazo                               dsmotivorechazo    ,
                          su.dssucursal                                    dssucursal         ,
                          CASE WHEN ch.dtacreditacion is not null                             --Acreditado
                                AND not exists (select 1 from tblingreso ir where ir.idingresorechazado = ii.idingreso)
                               THEN 'Acreditado'
                               WHEN ch.dtacreditacion is null                                 --No Acreditado
                                AND not exists (select 1 from tblingreso ir where ir.idingresorechazado = ii.idingreso)
                               THEN 'No Acreditado'                                           --Rechazado
                               WHEN exists (select 1 from tblingreso ir where ir.idingresorechazado = ii.idingreso)
                               THEN 'Rechazado'
                          END                                              dsestado           ,
                          ac.vlcuentanumero                                vlcuentanumero
                     FROM tblingreso            ii,
--                          tblmovcaja            mc,
--                          personas              pe,
                          tblcuenta             cu,
                          tblcuenta             cuco, --para sacar al comisionista
                          entidades             ee,
                          entidades             eeco, --para sacar al comisionista
                          tblcheque             ch,
                          tblautorizacioncheque ac,
                          tblbanco              bb,
                          tblsucursalesbanco    sb,
                          sucursales            su,
                          tblconfingreso        ci,
                          tblingresoestado_ac   ie, --Para los rechazados
                          tblmotivorechazo      mr, --Para los rechazados
                          guiasdetransporte     gt, --Para las guias de transporte
                          tblrendicionguia      rg,
                          documentos            d ,
                          tbltmp_sucursales_reporte rs
                    WHERE  gt.identidad            =  nvl(p_idcomisionista, gt.identidad)
                      AND  gt.idguiadetransporte   = rg.idguiadetransporte
                      AND  gt.iddoctrx             =  d.iddoctrx
                       and  ac.idcuenta             = cuco.idcuenta
                      and  cuco.identidad          = gt.identidad --que la identidad de la guia sea la misma identidad que configura las chequeras
                      and  gt.idtransportista      is null --en las guias de comisionista no se inserta el transportista
                      and  cuco.identidad          = eeco.identidad
                      AND  rg.idingreso            = ii.idingreso
                      AND  ii.idingreso            = ch.idingreso
                      AND  ii.idcuenta             = cu.idcuenta
--                      AND  ii.idmovcaja            = mc.idmovcaja
                      AND  ii.cdsucursal           = su.cdsucursal
                      AND  ii.cdsucursal           = ci.cdsucursal
                      AND  ii.cdconfingreso        = ci.cdconfingreso
                      AND  ci.cdaccion             =    '1'
                      AND  cu.cdtipocuenta         =    '1'
                      AND  cu.identidad            = ee.identidad
--                      AND  cu.idcuenta             = ac.idcuenta
                      AND  ac.cdbanco              = bb.cdbanco
                      AND  sb.cdbanco              = bb.cdbanco
                    --  AND  ii.cdestado            in ('0','4')
                      AND rs.cdsucursal            = ii.cdsucursal
                      AND rs.idreporte             = v_idReporte
                     -- AND (ii.cdsucursal           =    p_cdsucursal OR p_cdsucursal IS NULL ) lo dejo comentado para una sucursal
                      AND  sb.cdsucursal           = ac.cdsucursal
--                      AND  mc.idpersonaresponsable = pe.idpersona
                      AND  ch.idautorizacion       = ac.idautorizacion  (+)
                      AND  ii.dtingreso      BETWEEN    TRUNC(nvl(p_fechaDesde ,sysdate)     )
                                                 AND    TRUNC(nvl(p_fechaHasta ,sysdate) + 1 )
                      AND  ii.idingreso            = ie.idingreso       (+)
                      AND  ie.cdmotivorechazo      = mr.cdmotivorechazo (+)
                      AND (mr.cdmotivorechazo      =    p_cdmotivorechazo OR p_cdmotivorechazo IS NULL)
                 ) q
             WHERE (q.dsestado = 'Acreditado'    and p_cdestado = 1)
                OR (q.dsestado = 'No Acreditado' and p_cdestado = 2)
                OR (q.dsestado = 'Rechazado'     and p_cdestado = 3)
                OR (p_cdestado = 0);

      CleanSucursalesSeleccionadas(v_idReporte);

   EXCEPTION WHEN OTHERS THEN
         n_pkg_vitalpos_log_general.write(2, 'Modulo: ' || v_modulo || '  Error: ' || SQLERRM);
         RAISE;
   End GetChequesDetalleCO;

  /*****************************************************************************************************************
   * Retorna un reporte del detalle de Cupones de tarjeta Rechazados
   * %v 29/01/2016 - LucianoF: v1.0
   ******************************************************************************************************************/
   Procedure GetCuponesTJRechazadosDetalle(p_cdsucursal      In tblcuenta.cdsucursal%Type,
                                       p_identidad       In entidades.identidad%Type,
                                       p_idcuenta        In tblcuenta.idcuenta%Type,
                                       p_fechaDesde      In Date,
                                       p_fechaHasta      In Date,
                                       p_lote            IN tbltarjeta.nrolote%TYPE,
                                       p_cupon           IN tbltarjeta.dsnrocupon%TYPE,
                                       p_cur_out         Out cursor_type)
  IS
      v_modulo VARCHAR2(100) := 'PKG_REPORTE_CENTRAL.GetCuponesRechazadosDetalle';
      v_idReporte             VARCHAR2(40) := '';
   BEGIN
          v_idReporte := PKG_REPORTE_CENTRAL.SetSucursalesSeleccionadas(p_cdsucursal);
  OPEN p_cur_out FOR
         SELECT ii.idingreso,
                su.dssucursal ,
                ii.dtingreso,
                ee.cdcuit,
                ee.dsrazonsocial,
                cu.nombrecuenta,
                tj.cdcomercio establecimiento,
                tj.vlterminal terminal,
                tj.dsnrocupon cupon,
                tj.nrolote lote,
                pkg_ingreso_central.GetDescIngreso(ii.cdconfingreso,su.cdsucursal) as medio,
                abs(ii.amingreso) amingreso,
                decode(ii.idingresorechazado,null,'',mr.dsmotivorechazo) dsmotivorechazo
           FROM tblingreso            ii,
                tblcuenta             cu,
                entidades             ee,
                tblconfingreso        ci,
                tbltarjeta            tj,
                tblingresoestado_ac   ie,
                tblmotivorechazo      mr,
                tblregion             re,
                sucursales            su,
                tbltmp_sucursales_reporte sr
          WHERE
                ii.cdconfingreso = ci.cdconfingreso
            AND ii.cdsucursal = ci.cdsucursal
            AND ii.idcuenta = cu.idcuenta
            AND ii.idingreso = tj.idingreso
            AND cu.cdtipocuenta = '1'
            AND cu.identidad = ee.identidad
            and ci.cdaccion='3' --Rechazo de AC
            and re.cdregion= su.cdregion
            and su.cdsucursal=cu.cdsucursal
            AND mr.cdmotivorechazo=ie.cdmotivorechazo
            and ii.idingresorechazado=ie.idingreso
            and ii.idcuenta=nvl(p_idcuenta, ii.idcuenta)
            and cu.identidad = NVL(p_identidad,cu.identidad)
            and tj.dsnrocupon = NVL(p_cupon, tj.dsnrocupon)
            and tj.nrolote = NVL(p_lote, tj.nrolote)
            and ii.dtingreso BETWEEN TRUNC(nvl(p_fechaDesde,sysdate)) AND TRUNC(nvl(p_fechaHasta,sysdate) + 1)
            and sr.cdsucursal = su.cdsucursal
            and sr.idreporte = v_idReporte
            ORDER BY ii.dtingreso desc;

      PKG_REPORTE_CENTRAL.CleanSucursalesSeleccionadas(v_idReporte);
 EXCEPTION
      WHEN OTHERS THEN
         n_pkg_vitalpos_log_general.write(2, 'Modulo: ' || v_modulo || '  Error: ' || SQLERRM);
         RAISE;
   END GetCuponesTJRechazadosDetalle;

  /*****************************************************************************************************************
   * Retorna un reporte del detalle de Cupones Rechazados
   * %v 29/01/2016 - LucianoF: v1.0
   ******************************************************************************************************************/
   Procedure GetCuponesRechazadosDetalle(p_cdsucursal      In tblcuenta.cdsucursal%Type,
                                       p_identidad       In entidades.identidad%Type,
                                       p_idcuenta        In tblcuenta.idcuenta%Type,
                                       p_fechaDesde      In Date,
                                       p_fechaHasta      In Date,
                                       p_lote            IN tblcierrelote.vlcierrelote%TYPE,
                                       p_cur_out         Out cursor_type)
  IS
      v_modulo VARCHAR2(100) := 'PKG_REPORTE_CENTRAL.GetCuponesRechazadosDetalle';
      v_idReporte             VARCHAR2(40) := '';
   BEGIN
          v_idReporte := PKG_REPORTE_CENTRAL.SetSucursalesSeleccionadas(p_cdsucursal);
  OPEN p_cur_out FOR
         SELECT ii.idingreso,
                su.dssucursal ,
                ii.dtingreso,
                ee.cdcuit,
                ee.dsrazonsocial,
                cu.nombrecuenta,
                cl.vlestablecimiento establecimiento,
                cl.vlterminal terminal,
                '' cupon,
                cl.vlcierrelote lote,
                pkg_ingreso_central.GetDescIngreso(ii.cdconfingreso,su.cdsucursal) as medio,
                abs(ii.amingreso) amingreso,
                decode(ii.idingresorechazado,null,'',mr.dsmotivorechazo) dsmotivorechazo
           FROM tblingreso            ii,
                tblcuenta             cu,
                entidades             ee,
                tblconfingreso        ci,
                tblcierrelote         cl,
                tblingresoestado_ac   ie,
                tblmotivorechazo      mr,
                tblregion             re,
                sucursales            su,
                tbltmp_sucursales_reporte sr
          WHERE
                ii.cdconfingreso = ci.cdconfingreso
            AND ii.cdsucursal = ci.cdsucursal
            AND ii.idcuenta = cu.idcuenta
            AND ii.idingreso = cl.idingreso
            AND cu.cdtipocuenta = '1'
            AND cu.identidad = ee.identidad
            and ci.cdaccion='3' --Rechazo de AC
            and re.cdregion= su.cdregion
            and su.cdsucursal=cu.cdsucursal
            AND mr.cdmotivorechazo=ie.cdmotivorechazo
            and ii.idingresorechazado=ie.idingreso
            and ii.idcuenta=nvl(p_idcuenta, ii.idcuenta)
            and cu.identidad = NVL(p_identidad,cu.identidad)
            and cl.vlcierrelote = NVL(p_lote, cl.vlcierrelote)
            and ii.dtingreso BETWEEN TRUNC(nvl(p_fechaDesde,sysdate)) AND TRUNC(nvl(p_fechaHasta,sysdate) + 1)
            and sr.cdsucursal = su.cdsucursal
            and sr.idreporte = v_idReporte
            ORDER BY ii.dtingreso desc;

      PKG_REPORTE_CENTRAL.CleanSucursalesSeleccionadas(v_idReporte);
 EXCEPTION
      WHEN OTHERS THEN
         n_pkg_vitalpos_log_general.write(2, 'Modulo: ' || v_modulo || '  Error: ' || SQLERRM);
         RAISE;
   END GetCuponesRechazadosDetalle;


   /*****************************************************************************************************************
   * Retorna un reporte del detalle de cheques rechazados
   * %v 25/09/2014 - JBodnar: v1.0
   * %v 08/01/2016 - LucianoF: v1.1 - Busco por fecha de rechazo de cheques
   * %v 16/11/2017 - IAquilan: v1.2 - Cambio el idingresorechazado por idingreso en la funcion de GetDeudaCheque
   ******************************************************************************************************************/
   Procedure GetChequeRechazadoDetalle(p_cdsucursal      In tblcuenta.cdsucursal%Type,
                                       p_identidad       In entidades.identidad%Type,
                                       p_idcuenta        In tblcuenta.idcuenta%Type,
                                       p_fechaDesde      In Date,
                                       p_fechaHasta      In Date,
                                       p_Debe            IN integer,
                                       p_cur_out         Out cursor_type)
  IS
      v_modulo VARCHAR2(100) := 'PKG_REPORTE_CENTRAL.GetChequeRechazadoDetalle';
   BEGIN

  --Si tiene deuda
  if p_Debe=1 then
      OPEN p_cur_out FOR
           SELECT re.dsregion region,
               su.dssucursal ,
               sb.dssucursal dssucursalbanco,
                ii.dtingreso,
                ee.cdcuit,
                ee.dsrazonsocial,
                cu.nombrecuenta,
                bb.dsbanco,
                ac.vlcuentanumero,
                ch.dtemision,
                ch.dtcobro,
                ch.dtacreditacion,
                ch.vlnumero,
                DECODE(ac.icchequepropio,1,'Propio',0,'Tercero') tipo,
                abs(ii.amingreso) amingreso,
                decode(ii.idingresorechazado,null,'',mr.dsmotivorechazo) dsmotivorechazo,
                nvl(PKG_REPORTE_CENTRAL.GetDeudaCheque(ii.idingreso),0) saldodeuda--Cambio idingresorechazado por idingreso IAquilano
           FROM tblingreso            ii,
                tblcuenta             cu,
                entidades             ee,
                tblconfingreso        ci,
                tblcheque             ch,
                tblautorizacioncheque ac,
                tblbanco              bb,
                tblingresoestado_ac   ie,
                tblmotivorechazo      mr,
                tblregion             re,
                sucursales            su,
                tblsucursalesbanco    sb
          WHERE
          ii.cdconfingreso = ci.cdconfingreso
            AND ii.cdsucursal = ci.cdsucursal
            AND ii.idcuenta = cu.idcuenta
            AND ii.idingreso = ch.idingreso
            AND cu.cdtipocuenta = '1'
            AND cu.identidad = ee.identidad
            and ac.idautorizacion=ch.idautorizacion
            and ci.cdaccion='3' --Rechazo de AC
            and re.cdregion= su.cdregion
            and su.cdsucursal=cu.cdsucursal
            AND mr.cdmotivorechazo=ie.cdmotivorechazo
            and ii.idingresorechazado=ie.idingreso
            AND ac.cdbanco = bb.cdbanco
            and ac.cdsucursal=sb.cdsucursal
            and bb.cdbanco=sb.cdbanco
            AND PKG_REPORTE_CENTRAL.GetDeudaCheque(ii.idingresorechazado)> 0
            and ii.cdsucursal=nvl(p_cdsucursal,su.cdsucursal)
            and ii.idcuenta=nvl(p_idcuenta, ii.idcuenta)
            and cu.identidad = NVL(p_identidad,cu.identidad)
            and ii.dtingreso BETWEEN TRUNC(nvl(p_fechaDesde,sysdate)) AND TRUNC(nvl(p_fechaHasta,sysdate) + 1)
            ORDER BY ee.dsrazonsocial;

    --No tiene deuda
    elsif p_Debe=0 then
       OPEN p_cur_out FOR
           SELECT re.dsregion region,
               su.dssucursal ,
               sb.dssucursal dssucursalbanco,
                ii.dtingreso,
                ee.cdcuit,
                ee.dsrazonsocial,
                cu.nombrecuenta,
                bb.dsbanco,
                ac.vlcuentanumero,
                ch.dtemision,
                ch.dtcobro,
                ch.dtacreditacion,
                ch.vlnumero,
                DECODE(ac.icchequepropio,1,'Propio',0,'Tercero') tipo,
                abs(ii.amingreso) amingreso,
                decode(ii.idingresorechazado,null,'',mr.dsmotivorechazo) dsmotivorechazo,
                nvl(PKG_REPORTE_CENTRAL.GetDeudaCheque(ii.idingreso),0) saldodeuda--Cambio idingresorechazado por idingreso IAquilano
           FROM tblingreso            ii,
                tblcuenta             cu,
                entidades             ee,
                tblconfingreso        ci,
                tblcheque             ch,
                tblautorizacioncheque ac,
                tblbanco              bb,
                tblingresoestado_ac   ie,
                tblmotivorechazo      mr,
                tblregion             re,
                sucursales            su,
                tblsucursalesbanco    sb
          WHERE
          ii.cdconfingreso = ci.cdconfingreso
            AND ii.cdsucursal = ci.cdsucursal
            AND ii.idcuenta = cu.idcuenta
            AND ii.idingreso = ch.idingreso
            AND cu.cdtipocuenta = '1'
            AND cu.identidad = ee.identidad
            and ac.idautorizacion=ch.idautorizacion
            and ci.cdaccion='3' --Rechazo de AC
            and re.cdregion= su.cdregion
            and su.cdsucursal=cu.cdsucursal
            AND mr.cdmotivorechazo=ie.cdmotivorechazo
            and ii.idingresorechazado=ie.idingreso
            AND ac.cdbanco = bb.cdbanco
            and ac.cdsucursal=sb.cdsucursal
            and bb.cdbanco=sb.cdbanco
            AND PKG_REPORTE_CENTRAL.GetDeudaCheque(ii.idingresorechazado)= 0
            and ii.cdsucursal=nvl(p_cdsucursal,su.cdsucursal)
            and ii.idcuenta=nvl(p_idcuenta, ii.idcuenta)
            and cu.identidad = NVL(p_identidad,cu.identidad)
            and ii.dtingreso BETWEEN TRUNC(nvl(p_fechaDesde,sysdate)) AND TRUNC(nvl(p_fechaHasta,sysdate) + 1)
            ORDER BY ee.dsrazonsocial;

    else   --Si es null o vacio trae todos
       OPEN p_cur_out FOR
       SELECT re.dsregion region,
               su.dssucursal ,
               sb.dssucursal dssucursalbanco,
                ii.dtingreso,
                ee.cdcuit,
                ee.dsrazonsocial,
                cu.nombrecuenta,
                bb.dsbanco,
                ac.vlcuentanumero,
                ch.dtemision,
                ch.dtcobro,
                ch.dtacreditacion,
                ch.vlnumero,
                DECODE(ac.icchequepropio,1,'Propio',0,'Tercero') tipo,
                abs(ii.amingreso) amingreso,
                decode(ii.idingresorechazado,null,'',mr.dsmotivorechazo) dsmotivorechazo,
                nvl(PKG_REPORTE_CENTRAL.GetDeudaCheque(ii.idingreso),0) saldodeuda--Cambio idingresorechazado por idingreso IAquilano
           FROM tblingreso            ii,
                tblcuenta             cu,
                entidades             ee,
                tblconfingreso        ci,
                tblcheque             ch,
                tblautorizacioncheque ac,
                tblbanco              bb,
                tblingresoestado_ac   ie,
                tblmotivorechazo      mr,
                tblregion             re,
                sucursales            su,
                tblsucursalesbanco    sb
          WHERE
          ii.cdconfingreso = ci.cdconfingreso
            AND ii.cdsucursal = ci.cdsucursal
            AND ii.idcuenta = cu.idcuenta
            AND ii.idingreso = ch.idingreso
            AND cu.cdtipocuenta = '1'
            AND cu.identidad = ee.identidad
            and ac.idautorizacion=ch.idautorizacion
            and ci.cdaccion='3' --Rechazo de AC
            and re.cdregion= su.cdregion
            and su.cdsucursal=cu.cdsucursal
            AND mr.cdmotivorechazo=ie.cdmotivorechazo
            and ii.idingresorechazado=ie.idingreso
            AND ac.cdbanco = bb.cdbanco
            and ac.cdsucursal=sb.cdsucursal
            and bb.cdbanco=sb.cdbanco
            and ii.cdsucursal=nvl(p_cdsucursal,su.cdsucursal)
            and ii.idcuenta=nvl(p_idcuenta, ii.idcuenta)
            and cu.identidad = NVL(p_identidad,cu.identidad)
            and ii.dtingreso BETWEEN TRUNC(nvl(p_fechaDesde,sysdate)) AND TRUNC(nvl(p_fechaHasta,sysdate) + 1)
            ORDER BY ee.dsrazonsocial;
    end if;

   EXCEPTION
      WHEN OTHERS THEN
         n_pkg_vitalpos_log_general.write(2, 'Modulo: ' || v_modulo || '  Error: ' || SQLERRM);
         RAISE;
   END GetChequeRechazadoDetalle;

   /*****************************************************************************************************************
   * Dado el IDINGRESORECHAZADO, retorna todos los pagos que se realizaron.
   * %v 26/02/2018 - IAquilano
   ******************************************************************************************************************/
 Procedure GetPagosIngresosRechazados(p_idingreso IN tblcobranza.idingreso_pago%type,
                                      p_cur_out   OUT cursor_type) IS

   v_modulo VARCHAR2(100) := 'PKG_REPORTE_CENTRAL.GetPagosIngresosRechazados';

 BEGIN

   open p_cur_out for

    select tc.idingreso_pago idingreso, tc.dtimputado fecha, sum(tc.amimputado) monto
       from tblcobranza tc
      where tc.idingreso_pago = p_idingreso
      group by tc.idingreso_pago, tc.dtimputado;

 EXCEPTION
   WHEN OTHERS THEN
     n_pkg_vitalpos_log_general.write(2,
                                      'Modulo: ' || v_Modulo || ' Error: ' ||
                                      SQLERRM);
     RAISE;
 END GetPagosIngresosRechazados;


/*****************************************************************************************************************
* Retorna un reporte nuevo del detalle de cheques rechazados incluyendo comisionistas
* %v 21/02/2018 - IAquilano
******************************************************************************************************************/
Procedure GetNewChequeRechazadoDetalle(p_cdsucursal In tblcuenta.cdsucursal%Type,
                                       p_identidad  In entidades.identidad%Type,
                                       p_fechaDesde In Date,
                                       p_fechaHasta In Date,
                                       p_Debe       IN integer, --si tiene deuda:1--si no tiene deuda:0--todos:null
                                       p_cur_out    Out cursor_type) IS

  v_modulo VARCHAR2(100) := 'PKG_REPORTE_CENTRAL.GetNewChequeRechazadoDetalle';
  c Integer := 0;
BEGIN

  g_Listachequecomi.delete;

  --cargo tabla temporal con todos los cheques comis
  If p_debe = 1 then
  For r_chequecomi in
    (SELECT distinct s.dssucursal sucursal,
                     tiii.idingreso ingresorechazado,
                     d.sqcomprobante NroGuia,
                     eco.cdcuit CuitComi,
                     eco.dsrazonsocial RazonSocialComi,
                     e.cdcuit Cuit,
                     e.dsrazonsocial RazonSocial,
                     ch.vlnumero NumeroCheque,
                     bb.dsbanco Banco,
                     sb.dssucursal SucBanco,
                     ac.vlcuentanumero CuentaBanco,
                     trunc(ch.dtcobro) FechaAcreditacion,
                     trunc(ii.dtingreso) FechaIngresoSuc,
                     tiii.dtingreso fechaRechazo,
                     mr.dsmotivorechazo MotivoRechazo,
                     DECODE(ac.icchequepropio, 1, 'Propio', 0, 'Tercero') tipo,
                     nvl(ac.refertercero, '-') cuit_tercero,
                     tiii.amingreso Importe,
                     trunc(ch.dtemision) emision,
                     pkg_ingreso_central.GetImporteNoAplicado(tiii.idingreso) montodeuda
       FROM tblingreso            ii,
            tblingreso            tiii,
            tblcheque             ch,
            tblautorizacioncheque ac,
            tblbanco              bb,
            tblsucursalesbanco    sb,
            tblmotivorechazo      mr,
            tblingresoestado_ac   ie,
            tblrendicionguia      trg,
            guiasdetransporte     gt,
            tblcuenta             tc,
            entidades             e,
            entidades             eco, --para sacar comisionista
            documentos            d,
            sucursales            s
      WHERE gt.idguiadetransporte = trg.idguiadetransporte
        AND trg.idingreso = ii.idingreso
        AND ac.icactivo = 1
        AND ii.idingreso = ch.idingreso
        AND ac.cdbanco = bb.cdbanco
        AND ac.cdbanco = sb.cdbanco
        and ac.cdsucursal = sb.cdsucursal
        AND ch.idautorizacion = ac.idautorizacion(+)
        AND ii.idingreso = ie.idingreso(+)
        AND ie.cdmotivorechazo = mr.cdmotivorechazo(+) -- los cheques rechazados
        AND ii.idcuenta = tc.idcuenta
        AND tc.identidad = e.identidad
        and gt.identidad = eco.identidad
        and gt.iddoctrx = d.iddoctrx
        and ii.cdsucursal = s.cdsucursal
        and gt.IDTRANSPORTISTA is null
        and tiii.idingresorechazado = ii.idingreso
        and tiii.dtingreso < p_fechahasta + 1 --Parametros fechas
        and s.cdsucursal = (nvl(p_cdsucursal, s.cdsucursal)) --Paramtro sucursal
       and e.identidad = (nvl(p_identidad, e.identidad)))
        loop

          g_Listachequecomi(c).sucursal := r_chequecomi.sucursal;
          g_Listachequecomi(c).ingresorechazado := r_chequecomi.ingresorechazado;
          g_Listachequecomi(c).nroguia := r_chequecomi.NroGuia;
          g_Listachequecomi(c).cuitcomi := r_chequecomi.CuitComi;
          g_Listachequecomi(c).razonsocialcomi := r_chequecomi.RazonSocialComi;
          g_Listachequecomi(c).cuit := r_chequecomi.Cuit;
          g_Listachequecomi(c).razonsocial := r_chequecomi.RazonSocial;
          g_Listachequecomi(c).numerocheque := r_chequecomi.NumeroCheque;
          g_Listachequecomi(c).banco := r_chequecomi.Banco;
          g_Listachequecomi(c).sucbanco := r_chequecomi.SucBanco;
          g_Listachequecomi(c).cuentabanco := r_chequecomi.CuentaBanco;
          g_Listachequecomi(c).fechaacreditacion := r_chequecomi.FechaAcreditacion;
          g_Listachequecomi(c).fechaingresosuc := r_chequecomi.FechaIngresoSuc;
          g_Listachequecomi(c).fecharechazo := r_chequecomi.fechaRechazo;
          g_Listachequecomi(c).motivorechazo := r_chequecomi.MotivoRechazo;
          g_Listachequecomi(c).tipo := r_chequecomi.tipo;
          g_Listachequecomi(c).cuit_tercero := r_chequecomi.cuit_tercero;
          g_Listachequecomi(c).importe := r_chequecomi.Importe;
          g_Listachequecomi(c).emision := r_chequecomi.emision;
          g_Listachequecomi(c).montodeuda := r_chequecomi.montodeuda;

       c:= c + 1;
end loop; --parametro identidad)

    else
  For r_chequecomi in
    (SELECT distinct s.dssucursal sucursal,
                     tiii.idingreso ingresorechazado,
                     d.sqcomprobante NroGuia,
                     eco.cdcuit CuitComi,
                     eco.dsrazonsocial RazonSocialComi,
                     e.cdcuit Cuit,
                     e.dsrazonsocial RazonSocial,
                     ch.vlnumero NumeroCheque,
                     bb.dsbanco Banco,
                     sb.dssucursal SucBanco,
                     ac.vlcuentanumero CuentaBanco,
                     trunc(ch.dtcobro) FechaAcreditacion,
                     trunc(ii.dtingreso) FechaIngresoSuc,
                     tiii.dtingreso fechaRechazo,
                     mr.dsmotivorechazo MotivoRechazo,
                     DECODE(ac.icchequepropio, 1, 'Propio', 0, 'Tercero') tipo,
                     nvl(ac.refertercero, '-') cuit_tercero,
                     tiii.amingreso Importe,
                     trunc(ch.dtemision) emision,
                     pkg_ingreso_central.GetImporteNoAplicado(tiii.idingreso) montodeuda
       FROM tblingreso            ii,
            tblingreso            tiii,
            tblcheque             ch,
            tblautorizacioncheque ac,
            tblbanco              bb,
            tblsucursalesbanco    sb,
            tblmotivorechazo      mr,
            tblingresoestado_ac   ie,
            tblrendicionguia      trg,
            guiasdetransporte     gt,
            tblcuenta             tc,
            entidades             e,
            entidades             eco, --para sacar comisionista
            documentos            d,
            sucursales            s
      WHERE gt.idguiadetransporte = trg.idguiadetransporte
        AND trg.idingreso = ii.idingreso
        AND ac.icactivo = 1
        AND ii.idingreso = ch.idingreso
        AND ac.cdbanco = bb.cdbanco
        AND ac.cdbanco = sb.cdbanco
        and ac.cdsucursal = sb.cdsucursal
        AND ch.idautorizacion = ac.idautorizacion(+)
        AND ii.idingreso = ie.idingreso(+)
        AND ie.cdmotivorechazo = mr.cdmotivorechazo(+) -- los cheques rechazados
        AND ii.idcuenta = tc.idcuenta
        AND tc.identidad = e.identidad
        and gt.identidad = eco.identidad
        and gt.iddoctrx = d.iddoctrx
        and ii.cdsucursal = s.cdsucursal
        and gt.IDTRANSPORTISTA is null
        and tiii.idingresorechazado = ii.idingreso
        and tiii.dtingreso between p_fechadesde and p_fechahasta + 1 --Parametros fechas
        and s.cdsucursal = (nvl(p_cdsucursal, s.cdsucursal)) --Paramtro sucursal
        and e.identidad = (nvl(p_identidad, e.identidad))) --parametro identidad)
        loop

          g_Listachequecomi(c).sucursal := r_chequecomi.sucursal;
          g_Listachequecomi(c).ingresorechazado := r_chequecomi.ingresorechazado;
          g_Listachequecomi(c).nroguia := r_chequecomi.NroGuia;
          g_Listachequecomi(c).cuitcomi := r_chequecomi.CuitComi;
          g_Listachequecomi(c).razonsocialcomi := r_chequecomi.RazonSocialComi;
          g_Listachequecomi(c).cuit := r_chequecomi.Cuit;
          g_Listachequecomi(c).razonsocial := r_chequecomi.RazonSocial;
          g_Listachequecomi(c).numerocheque := r_chequecomi.NumeroCheque;
          g_Listachequecomi(c).banco := r_chequecomi.Banco;
          g_Listachequecomi(c).sucbanco := r_chequecomi.SucBanco;
          g_Listachequecomi(c).cuentabanco := r_chequecomi.CuentaBanco;
          g_Listachequecomi(c).fechaacreditacion := r_chequecomi.FechaAcreditacion;
          g_Listachequecomi(c).fechaingresosuc := r_chequecomi.FechaIngresoSuc;
          g_Listachequecomi(c).fecharechazo := r_chequecomi.fechaRechazo;
          g_Listachequecomi(c).motivorechazo := r_chequecomi.MotivoRechazo;
          g_Listachequecomi(c).tipo := r_chequecomi.tipo;
          g_Listachequecomi(c).cuit_tercero := r_chequecomi.cuit_tercero;
          g_Listachequecomi(c).importe := r_chequecomi.Importe;
          g_Listachequecomi(c).emision := r_chequecomi.emision;
          g_Listachequecomi(c).montodeuda := r_chequecomi.montodeuda;

       c:= c + 1;
end loop;

     End if;

  --Si tiene deuda
  if p_Debe = 1 then
    OPEN p_cur_out FOR

      Select *
        from table(Pipechequecomi) tche
       where tche.montodeuda > 0

      UNION

     SELECT su.dssucursal sucursal,
             ii.idingreso ingresorechazado,
             0 as NroGuia,
             '-' as CuitComi,
             '-' as RazonSocialComi,
             ee.cdcuit Cuit,
             ee.dsrazonsocial RazonSocial,
             ch.vlnumero NumeroCheque,
             bb.dsbanco Banco,
             sb.dssucursal SucBanco,
             ac.vlcuentanumero CuentaBanco,
             trunc(ch.dtcobro) FechaAcreditacion,
             trunc(tiii.dtingreso) fechaIngresoSuc,
             trunc(ii.dtingreso) FechaRechazo,
             mr.dsmotivorechazo MotivoRechazo,
             DECODE(ac.icchequepropio, 1, 'Propio', 0, 'Tercero') tipo,
             nvl(ac.refertercero, '-') Cuit_tercero,
             (ii.amingreso) Importe,
             trunc(ch.dtemision) Emision,
             pkg_ingreso_central.GetImporteNoAplicado(ii.idingreso ) montodeuda
        FROM tblingreso            ii,
             tblingreso            tiii,
             tblcuenta             cu,
             entidades             ee,
             tblconfingreso        ci,
             tblcheque             ch,
             tblautorizacioncheque ac,
             tblbanco              bb,
             tblingresoestado_ac   ie,
             tblmotivorechazo      mr,
             tblregion             re,
             sucursales            su,
             rolesentidades        re,
             tblsucursalesbanco    sb
       WHERE ii.cdconfingreso = ci.cdconfingreso
         AND ii.cdsucursal = ci.cdsucursal
         AND ii.idcuenta = cu.idcuenta
         AND ii.idingreso = ch.idingreso
         AND cu.cdtipocuenta = '1'
         AND cu.identidad = ee.identidad
         and ee.identidad = re.identidad
         and re.cdrol <> 1
         and ac.idautorizacion = ch.idautorizacion
         and ci.cdaccion = '3' --Rechazo de AC
         and re.cdregion = su.cdregion
         and su.cdsucursal = cu.cdsucursal
         AND mr.cdmotivorechazo = ie.cdmotivorechazo
         and ii.idingresorechazado = ie.idingreso
         AND ac.cdbanco = bb.cdbanco
         and ac.cdsucursal = sb.cdsucursal
         and bb.cdbanco = sb.cdbanco
         and pkg_ingreso_central.GetImporteNoAplicado(ii.idingreso) >0
         and ii.idingresorechazado = tiii.idingreso
         and ii.idingreso not in (select tcho.ingresorechazado from table(Pipechequecomi) tcho)
         and ii.cdsucursal = nvl(p_cdsucursal, su.cdsucursal)
         and cu.identidad = NVL(p_identidad, cu.identidad)
         and ii.dtingreso  <= p_fechahasta; --parametro fecha hasta

    --No tiene deuda
  elsif p_Debe = 0 then
    OPEN p_cur_out FOR

      select *
        from table(Pipechequecomi) tche
       where tche.montodeuda = 0

      UNION

      SELECT su.dssucursal sucursal,
             ii.idingreso ingresorechazado,
             0 as NroGuia,
             '-' as CuitComi,
             '-' as RazonSocialComi,
             ee.cdcuit Cuit,
             ee.dsrazonsocial RazonSocial,
             ch.vlnumero NumeroCheque,
             bb.dsbanco Banco,
             sb.dssucursal SucBanco,
             ac.vlcuentanumero CuentaBanco,
             trunc(ch.dtcobro) FechaAcreditacion,
             trunc(tiii.dtingreso) fechaIngresoSuc,
             trunc(ii.dtingreso) FechaRechazo,
             mr.dsmotivorechazo MotivoRechazo,
             DECODE(ac.icchequepropio, 1, 'Propio', 0, 'Tercero') tipo,
             nvl(ac.refertercero, '-') Cuit_tercero,
             (ii.amingreso) Importe,
             trunc(ch.dtemision) Emision,
             pkg_ingreso_central.GetImporteNoAplicado(ii.idingreso) montodeuda
        FROM tblingreso            ii,
             tblingreso            tiii,
             tblcuenta             cu,
             entidades             ee,
             tblconfingreso        ci,
             tblcheque             ch,
             tblautorizacioncheque ac,
             tblbanco              bb,
             tblingresoestado_ac   ie,
             tblmotivorechazo      mr,
             tblregion             re,
             sucursales            su,
             rolesentidades        re,
             tblsucursalesbanco    sb
       WHERE ii.cdconfingreso = ci.cdconfingreso
         AND ii.cdsucursal = ci.cdsucursal
         AND ii.idcuenta = cu.idcuenta
         AND ii.idingreso = ch.idingreso
         AND cu.cdtipocuenta = '1'
         AND cu.identidad = ee.identidad
         and ee.identidad = re.identidad
         and re.cdrol <> 1
         and ac.idautorizacion = ch.idautorizacion
         and ci.cdaccion = '3' --Rechazo de AC
         and re.cdregion = su.cdregion
         and su.cdsucursal = cu.cdsucursal
         AND mr.cdmotivorechazo = ie.cdmotivorechazo
         and ii.idingresorechazado = ie.idingreso
         AND ac.cdbanco = bb.cdbanco
         and ac.cdsucursal = sb.cdsucursal
         and bb.cdbanco = sb.cdbanco
         and pkg_ingreso_central.GetImporteNoAplicado(ii.idingreso) = 0
         and ii.idingresorechazado = tiii.idingreso
         and ii.idingreso not in (select tcho.ingresorechazado from table(Pipechequecomi) tcho)
         and ii.cdsucursal = nvl(p_cdsucursal, su.cdsucursal)
         and cu.identidad = NVL(p_identidad, cu.identidad)
         and ii.dtingreso  BETWEEN p_fechadesde AND p_fechahasta + 1; --parametro fecha hasta

  else
    --Si es null o vacio trae todos
    OPEN p_cur_out FOR

      select *
        from table(Pipechequecomi)

      UNION

      SELECT su.dssucursal sucursal,
             ii.idingreso ingresorechazado,
             0 as NroGuia,
             '-' as CuitComi,
             '-' as RazonSocialComi,
             ee.cdcuit Cuit,
             ee.dsrazonsocial RazonSocial,
             ch.vlnumero NumeroCheque,
             bb.dsbanco Banco,
             sb.dssucursal SucBanco,
             ac.vlcuentanumero CuentaBanco,
             trunc(ch.dtcobro) FechaAcreditacion,
             (tiii.dtingreso) fechaIngresoSuc,
             trunc(ii.dtingreso) FechaRechazo,
             mr.dsmotivorechazo MotivoRechazo,
             DECODE(ac.icchequepropio, 1, 'Propio', 0, 'Tercero') tipo,
             nvl(ac.refertercero, '-') Cuit_tercero,
             (ii.amingreso) Importe,
             trunc(ch.dtemision) Emision,
             pkg_ingreso_central.GetImporteNoAplicado(ii.idingreso ) montodeuda
        FROM tblingreso            ii,
             tblingreso            tiii,
             tblcuenta             cu,
             entidades             ee,
             tblconfingreso        ci,
             tblcheque             ch,
             tblautorizacioncheque ac,
             tblbanco              bb,
             tblingresoestado_ac   ie,
             tblmotivorechazo      mr,
             tblregion             re,
             sucursales            su,
             rolesentidades        re,
             tblsucursalesbanco    sb
       WHERE ii.cdconfingreso = ci.cdconfingreso
         AND ii.cdsucursal = ci.cdsucursal
         AND ii.idcuenta = cu.idcuenta
         AND ii.idingreso = ch.idingreso
         AND cu.cdtipocuenta = '1'
         AND cu.identidad = ee.identidad
         and ee.identidad = re.identidad
         and re.cdrol <> 1
         and ac.idautorizacion = ch.idautorizacion
         and ci.cdaccion = '3' --Rechazo de AC
         and re.cdregion = su.cdregion
         and su.cdsucursal = cu.cdsucursal
         AND mr.cdmotivorechazo = ie.cdmotivorechazo
         and ii.idingresorechazado = ie.idingreso
         AND ac.cdbanco = bb.cdbanco
         and ac.cdsucursal = sb.cdsucursal
         and bb.cdbanco = sb.cdbanco
         and ii.idingresorechazado = tiii.idingreso
         and ii.idingreso not in (select tcho.ingresorechazado from table(Pipechequecomi) tcho)
         and ii.cdsucursal = nvl(p_cdsucursal, su.cdsucursal)
         and cu.identidad = NVL(p_identidad, cu.identidad)
         and ii.dtingreso BETWEEN p_fechadesde AND p_fechahasta + 1;

  end if;

EXCEPTION
  WHEN OTHERS THEN
    n_pkg_vitalpos_log_general.write(2,
                                     'Modulo: ' || v_modulo || '  Error: ' ||
                                     SQLERRM);
    RAISE;
END GetNewChequeRechazadoDetalle;

/**************************************************************************************************
   * 27/04/2013
   * MarianoL
   * function Pipechequecomi
   * Pipea la lista que recibe como parámetro
   ***************************************************************************************************/
   Function Pipechequecomi Return tab_ListachequecomiPipe
      Pipelined Is
      i Binary_Integer := 0;
   Begin
      i := g_Listachequecomi.FIRST;
      While i Is Not Null Loop
         Pipe Row(g_Listachequecomi(i));
         i := g_Listachequecomi.NEXT(i);
      End Loop;
      Return;
   Exception
      When Others Then
         Null;
   End Pipechequecomi;


 /*****************************************************************************************************************
 * Reporte que trae todos los cheques que hay en cartera.
 * %v 27/02/2018 - IAquilano
 * %v 06/03/2018 - IAquilano - Agrego que sean de estado distinto al rechazado.
 ******************************************************************************************************************/
 Procedure GetChequesEnCarteraCred(p_cdsucursal In tblcuenta.cdsucursal%Type,
                                  p_identidad  In entidades.identidad%Type,
                                  p_fecha      IN date,
                                  p_cur_out    OUT cursor_type) IS

   v_modulo VARCHAR2(100) := 'PKG_REPORTE_CENTRAL.GetChequesEnCarteraCred';

 BEGIN

   open p_cur_out for
     select distinct s.dssucursal SUCURSAL,
                     nvl(d.sqcomprobante, 0) NROGUIA,
                     nvl(eco.dsrazonsocial, '-') RAZONSOCIALCOMI,
                     e.cdcuit CUIT,
                     e.dsrazonsocial RAZONSOCIAL,
                     cu.nombrecuenta,
                     ch.vlnumero NUMEROCHEQUE,
                     bb.dsbanco BANCO,
                     tsuc.dssucursal SUCBANCO ,
                     ac.vlcuentanumero Cuenta_banco,
                     ch.dtcobro FECHAACREDITACION,
                     ti.dtingreso FECHAINGRESOSUC,
                     DECODE(ac.icchequepropio, 1, 'Propio', 0, 'Tercero') TIPO,
                     nvl(ac.refertercero, '-') CUIT_TERCERO,
                     ti.amingreso IMPORTE
       from tblcheque             ch,
            tblingreso            ti,
            tblcuenta             cu,
            entidades             e,
            tblrendicionguia      trg,
             ( select * from guiasdetransporte where idtransportista is null
            ) gt, --filtro para que solo sean guias de comisionista
            entidades             eco,
            sucursales            s,
            documentos            d,
            tblautorizacioncheque ac,
            tblbanco              bb,
            tblsucursalesbanco    tsuc
      where dtcobro >= p_fecha
        and ch.idingreso = ti.idingreso
        and ti.idcuenta = cu.idcuenta
        and cu.identidad = e.identidad
        and ti.idingreso = trg.idingreso(+)
        and trg.idguiadetransporte = gt.idguiadetransporte(+)
        and gt.identidad = eco.identidad(+)
        and ti.cdsucursal = s.cdsucursal
        and gt.iddoctrx = d.iddoctrx(+)
        and ch.idautorizacion(+) = ac.idautorizacion
        AND ac.cdbanco = bb.cdbanco
        AND ac.cdbanco = tsuc.cdbanco
        and ac.cdsucursal = tsuc.cdsucursal
        and s.cdsucursal = (nvl(p_cdsucursal, s.cdsucursal))
        and e.identidad = (nvl(p_identidad, e.identidad))
        and ti.cdestado <> '4'
        and ti.amingreso>0 --para que no devuelva el rechazo del cheque
        order by ch.dtcobro desc ;

 EXCEPTION
   WHEN OTHERS THEN
     n_pkg_vitalpos_log_general.write(2,
                                      'Modulo: ' || v_Modulo || ' Error: ' ||
                                      SQLERRM);
     RAISE;
 END GetChequesEnCarteraCred;


   /*****************************************************************************************************************
   * Retorna un reporte del detalle de cuentas corrientes
   * %v 30/06/2014 - MatiasG: v1.0
   * %v 06/05/2014 - MartinM: v1.1 - Se rediseña para que la info sea consistente con los cambios realizados
   *                                 en los querys de la autoconsulta
   * %v 17/06/2015 - MartinM: v1.2 - Se rediseña para que la info se muestre agrupada
   * %v 21/09/2015 - MartinM: v1.3 - Se rediseña la consulta
   ******************************************************************************************************************/
  PROCEDURE GetCuentaCorrienteDetalle( p_identidad  IN  entidades.identidad%TYPE ,
                                       p_idcuenta   IN  tblcuenta.idcuenta%TYPE  ,
                                       p_fechaDesde IN            DATE           ,
                                       p_fechaHasta IN            DATE           ,
                                       p_cur_out    OUT           cursor_type    ) IS

    v_modulo                          VARCHAR2(100)    := 'PKG_REPORTE_CENTRAL.GetCuentaCorrienteDetalle' ;
    v_sqmovcuentatmp     tblmovcuenta.sqmovcuenta%TYPE                                                    ;
    v_sqmovcuentahasta   tblmovcuenta.sqmovcuenta%TYPE                                                    ;
    v_saldo_al           tblmovcuenta.sqmovcuenta%TYPE                                                    ;
    v_fechadesde                      DATE                                                                ;
    v_fechahasta                      DATE                                                                ;
    v_fechamigracion                  DATE                                                                ;

  BEGIN

      --averiguo la fecha de la migración
      BEGIN
        select trunc(mi.dtfechamigracion)
          into v_fechamigracion
          from tblmigracion mi
         where mi.cdsucursal= pkg_cuenta_central.GetSucursalCuenta(p_idcuenta);
      EXCEPTION WHEN OTHERS THEN
        v_fechamigracion := p_fechaDesde;
      END;

      --si la fecha de la migración es mayor a la fecha desde del parametro tomo la fecha de la migración
      IF  p_fechaDesde < v_fechamigracion then
            v_fechadesde := v_fechamigracion + 1;
      ELSE
            v_fechadesde := p_fechaDesde;
      END IF;

      --si la fecha de la migración es mayor a la fecha hasta del parametro tomo la fecha de la migración
      IF  p_fechaHasta < v_fechamigracion then
            v_fechahasta := trunc(v_fechamigracion) + 2;
      ELSE
            v_fechahasta := trunc(p_fechaHasta) + 1;
      END IF;

      --averiguo el sqmovcuenta de la fecha desde
      BEGIN
         SELECT max(tmc.sqmovcuenta)
           INTO v_sqmovcuentatmp
           FROM tblmovcuenta tmc
          WHERE tmc.idcuenta = p_IdCuenta
            AND tmc.dtmovimiento < trunc(v_fechadesde);

         IF v_sqmovcuentatmp IS NULL THEN
           v_sqmovcuentatmp := 0;
         END IF;
       EXCEPTION WHEN OTHERS THEN
               v_sqmovcuentatmp   := 0;
      END;

      v_saldo_al := v_sqmovcuentatmp;

    SELECT nvl(max(tmc.sqmovcuenta),0)
      INTO v_sqmovcuentahasta
      FROM tblmovcuenta tmc
     WHERE tmc.idcuenta = p_IdCuenta
       AND tmc.dtmovimiento between trunc(v_fechadesde) and trunc(v_fechahasta);

     -- Envío la info para la autoconsulta
        open p_cur_out for
      select tr.dsregion                                     region      ,
              s.dssucursal                                   sucursal    ,
              e.dsrazonsocial                                cliente     ,
              e.cdcuit                                       cdcuit      ,
             tc.nombrecuenta                                 cuenta      ,
             q3.idcuenta                                     idcuenta    ,
             q3.dtmovimiento                                 fecha       ,
             case when q3.iddoctrx    is not null
                   and q3.tienedetalle = 1
                  then q3.descripciongenerica
                  else q3.dsmovimiento
              end                                            descripcion ,
             q3.sqmovcuenta                                  sqmovcuenta ,
             q3.amsaldo                      -
              lag (q3.amsaldo              )
             over (order by q3.sqmovcuenta )                 importe     ,
             q3.amsaldo                                      saldo       ,
             q3.tienedetalle                                 tienedetalle
        from (select idcuenta           ,
                     dtmovimiento       ,
                     iddoctrx           ,
                     dsmovimiento       ,
                     descripciongenerica,
                     sqmovcuenta        ,
                     amsaldo            ,
                     case when descripciongenerica = lag(descripciongenerica) over (order by sqmovcuenta desc)
                          then 'No'
                          else 'Si'
                     end muestraregistro,
                     case when descripciongenerica = lead(descripciongenerica) over (order by sqmovcuenta desc)
                          then 1
                          else 0
                     end tienedetalle
               from ( SELECT tmc.idcuenta                                                 idcuenta           ,
                             tmc.dtmovimiento                                             dtmovimiento       ,
                             tmc.iddoctrx                                                 iddoctrx           ,
                             DECODE(nvl(tmc.iddoctrx,'ingreso'),
                                    'ingreso',   tmc.dsmovimiento,
                                    pkg_documento_central.GetDescDocumento(tmc.iddoctrx)) dsmovimiento       ,
                             tmc.sqmovcuenta                                              sqmovcuenta        ,
                             tmc.amsaldo                                                  amsaldo            ,
                             DECODE(nvl(tmc.iddoctrx,'ingreso'),
                                    'ingreso',   tmc.dsmovimiento,
                                    d2.descripciongenerica )                              descripciongenerica
                        FROM tblmovcuenta tmc,
                             (select iddoctrx,
                                     case when cdcomprobante like 'FC%'
                                          then 'Facturas'
                                          when cdcomprobante like 'ND%'
                                          then 'Notas de Débito'
                                          when cdcomprobante like 'NC%'
                                          then 'Notas de Crédito'
                                      end descripciongenerica
                                from documentos   d1) d2
                       WHERE tmc.iddoctrx    =  d2.iddoctrx (+)
                         and tmc.idcuenta    =    p_IdCuenta
                         and tmc.sqmovcuenta >    v_saldo_al
                         and tmc.sqmovcuenta <=   v_sqmovcuentahasta
                    order by sqmovcuenta desc ) q
              union all
              select nvl(q2.idcuenta,p_IdCuenta)                        idcuenta           ,
                     v_fechadesde                                       dtmovimiento       ,
                     NULL                                               iddoctrx           ,
                     'Saldo al '|| to_char(v_fechadesde,'dd/mm/yyyy')   dsmovimiento       ,
                     NULL                                               descripciongenerica,
                     nvl(q2.sqmovcuenta,0)                              sqmovcuenta        ,
                     nvl(q2.amsaldo    ,0)                              amsaldo            ,
                     'Si'                                               muestraregistro    ,
                     0                                                  tienedetalle
                from dual d,
                     (select 'X' dummy, tmc.*
                        from tblmovcuenta tmc
                       where tmc.idcuenta    = p_IdCuenta
                         and tmc.sqmovcuenta = v_saldo_al ) q2
               where d.Dummy = q2.dummy (+)  ) q3,
             sucursales                       s  ,
             entidades                        e  ,
             tblregion                        tr ,
             tblcuenta                        tc
       WHERE tc.idcuenta        =  q3.idcuenta
         AND tc.identidad       =   e.identidad
         AND tc.cdsucursal      =   s.cdsucursal
         AND  s.cdregion        =  tr.cdregion
         AND  e.identidad       =     p_identidad
         AND q3.muestraregistro =     'Si'
       order by q3.sqmovcuenta desc;

  EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2, 'Modulo: ' || v_modulo || '  Error: ' || SQLERRM);
      RAISE;
  END GetCuentaCorrienteDetalle;


   /*****************************************************************************************************************
   * Retorna un reporte del detalle de cuentas corrientes
   * %v 30/06/2014 - MatiasG: v1.0
   * %v 06/05/2014 - MartinM: v1.1 - Se rediseña para que la info sea consistente con los cambios realizados
   *                                 en los querys de la autoconsulta
   * %v 17/06/2015 - MartinM: v1.2 - Se rediseña para que la info se muestre agrupada
   ******************************************************************************************************************/
  PROCEDURE GetCuentaCorrienteDetalleDrill( p_idcuenta    IN  tblmovcuenta.idcuenta%TYPE     ,
                                            p_sqmovcuenta IN  tblmovcuenta.sqmovcuenta%TYPE  ,
                                            p_cur_out     OUT              cursor_type       ) IS

   v_modulo VARCHAR2(100) := 'PKG_REPORTE_CENTRAL.GetCuentaCorrienteDetalleDrill' ;

  BEGIN

     -- Envío la info para la autoconsulta
        open p_cur_out
         for select tr.dsregion                                    region     ,
                    s.dssucursal                                   sucursal   ,
                    e.dsrazonsocial                                cliente    ,
                    e.cdcuit                                       cdcuit     ,
                   tc.nombrecuenta                                 cuenta     ,
                  tmc.idcuenta                                     idcuenta   ,
                  tmc.dtmovimiento                                 fecha      ,
                  tmc.dsmovimiento                                 descripcion,
                  tmc.sqmovcuenta                                  sqmovcuenta,
                  coalesce(ti.amingreso, d.amdocumento * -1)       importe    ,
                    tmc.amsaldo                                    saldo
               from tblmovcuenta tmc,
                    documentos   d  ,
                    tblingreso   ti ,
                    sucursales   s  ,
                    entidades    e  ,
                    tblregion    tr ,
                    tblcuenta    tc
              where tmc.iddoctrx     = d.iddoctrx (+)
                and tmc.idingreso    = ti.idingreso (+)
                and tmc.idcuenta     = p_idcuenta
                and tmc.sqmovcuenta <= p_sqmovcuenta
                and tmc.sqmovcuenta  > nvl((select max(sqmovcuenta) sqmovcuenta
                                              from ( select q0.sqmovcuenta,
                                                            case when q0.dsmovimiento = lead(q0.dsmovimiento) over (order by sqmovcuenta)
                                                                 then 'No'
                                                                 else 'Si'
                                                            end MuestraRegistro
                                                       from ( select sqmovcuenta,
                                                                     nvl(descripciongenerica,dsmovimiento) dsmovimiento
                                                                from tblmovcuenta tmc1,
                                                                     (select iddoctrx,
                                                                             case when cdcomprobante like 'FC%'
                                                                                  then 'Facturas'
                                                                                  when cdcomprobante like 'ND%'
                                                                                  then 'Notas de Débito'
                                                                                  when cdcomprobante like 'NC%'
                                                                                  then 'Notas de Crédito'
                                                                              end descripciongenerica
                                                                        from documentos ) d2
                                                                where tmc1.iddoctrx = d2.iddoctrx (+)
                                                                  and tmc1.idcuenta = p_idcuenta
                                                                  and tmc1.sqmovcuenta <= p_sqmovcuenta
                                                                order by sqmovcuenta desc) q0 ) q
                                           where q.MuestraRegistro = 'Si'
                                             and q.sqmovcuenta < p_sqmovcuenta),p_sqmovcuenta - 1)
                and tc.idcuenta      = tmc.idcuenta
                and tc.identidad     =   e.identidad
                and tc.cdsucursal    =   s.cdsucursal
                and  s.cdregion      =  tr.cdregion
                and  e.identidad     =  tc.identidad
           order by tmc.sqmovcuenta desc;

  EXCEPTION WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2, 'Modulo: ' || v_modulo || '  Error: ' || SQLERRM);
      RAISE;
  END GetCuentaCorrienteDetalleDrill;


   /*****************************************************************************************************************
   * Dado una cuenta retorna la facturacion de X meses para atras, siendo X el parametro p_mes
   * %v 18/03/2015 - JBodnar: v1.0
   ******************************************************************************************************************/
   FUNCTION GetFacturacionAnterior(p_idCuenta IN tblcuenta.idcuenta%TYPE, p_aniomes IN NUMBER)
      RETURN documentos.amdocumento%TYPE IS
      v_modulo      VARCHAR2(100) := 'PKG_REPORTE_CENTRAL.GetFacturacionAnterior';
      v_facturacion documentos.amdocumento%TYPE;
   BEGIN

      select sum(fh.amfacturacion)
      into v_facturacion
      from tblfacturacionhistorica fh
      where TO_NUMBER(to_char(fh.aniomes,'yyyymm')) = p_aniomes
      and fh.idcuenta=p_idCuenta;

      RETURN v_facturacion;
   EXCEPTION
      WHEN OTHERS THEN
         n_pkg_vitalpos_log_general.write(2, 'Modulo: ' || v_Modulo || ' Error: ' || SQLERRM);
         RAISE;
   END GetFacturacionAnterior;

   /*****************************************************************************************************************
   * Retorna un reporte de deudores por ventas agrupado por region y sucursal
   * %v 30/06/2014 - MatiasG: v1.0
   * %v 23/04/2015 - MartinM: v1.1 - Se ha quitado del join la tabla tbldocumentodeuda para que no de producto cartesiano
   * %v 23/06/2016 - LucianoF: v1.2 - Agrego cuenta CF, quito Comisionista
   ******************************************************************************************************************/
   PROCEDURE GetDeudoresPorVentaGeneral(p_sucursales  IN VARCHAR2,
                                        p_identidad   IN entidades.identidad%TYPE,
                                        p_idcuenta    IN tblcuenta.idcuenta%TYPE,
                                        p_cur_out     OUT cursor_type)
  IS
    v_Modulo                VARCHAR2(100) := 'PKG_REPORTE_CENTRAL.GetDeudoresPorVentaGeneral';
    v_AnioMesActual         number        := TO_NUMBER(to_char(sysdate,'YYYYMM'));
    v_idReporte             VARCHAR2(40)  := '';
  BEGIN

    v_idReporte := SetSucursalesSeleccionadas(p_sucursales);

    OPEN p_cur_out FOR
  SELECT cdregion,
         region,
         cdsucursal,
         sucursal,
         SUM(uno)        uno,
         SUM(dos)        dos,
         SUM(tres)       tres,
         SUM(saldoventa) saldomoroso,
         SUM(amotorgado) otorgado
    FROM ( SELECT re.cdregion,
                  re.dsregion region,
                  su.cdsucursal,
                  su.dssucursal sucursal,
                  ee.dsrazonsocial cliente,
                  ee.cdcuit,
                  cu.idcuenta,
                  cu.nombrecuenta cuenta,
                  NVL(PKG_REPORTE_CENTRAL.GetFacturacionAnterior(do.idcuenta,v_AnioMesActual-2),0) uno,
                  NVL(PKG_REPORTE_CENTRAL.GetFacturacionAnterior(do.idcuenta,v_AnioMesActual-1),0) dos,
                  NVL(PKG_REPORTE_CENTRAL.GetFacturacionAnterior(do.idcuenta,v_AnioMesActual),0) tres,
                  NVL(sum(GetSaldoFactura(do.iddoctrx)),0) saldoventa,
                  cu.amotorgado
             FROM documentos do,
                  entidades ee,
                  tblcuenta cu,
                  sucursales su,
                  tblregion re,
                  tbltmp_sucursales_reporte rs,
                  movmateriales mm
            WHERE do.identidadreal  = ee.identidad
              AND do.idcuenta       = cu.idcuenta
              AND su.cdregion       = re.cdregion
              AND rs.idreporte      = v_idReporte
              --AND cu.cdtipocuenta   = '1'
              AND su.cdsucursal = rs.cdsucursal
              AND do.cdsucursal     = su.cdsucursal
              AND do.idmovmateriales      = mm.idmovmateriales
              AND mm.id_canal in ('SA','VE','TE')
              AND (do.cdcomprobante LIKE ('FC%') OR do.cdcomprobante LIKE ('ND%'))
              AND ( do.identidadreal = p_identidad OR p_identidad IS NULL )
              AND ( cu.idcuenta = p_idcuenta OR p_idcuenta IS NULL )
              AND EXISTS ( SELECT *
                             FROM tbldocumentodeuda dd
                            WHERE dd.iddoctrx = do.iddoctrx
                              AND dd.cdestado = 1 --Venta
                              AND dd.dtestadofin IS NULL )
         GROUP BY re.cdregion,
                  re.dsregion ,
                  su.cdsucursal,
                  su.dssucursal ,
                  ee.dsrazonsocial ,
                  ee.cdcuit,
                  cu.idcuenta,
                  cu.nombrecuenta ,
                  NVL(PKG_REPORTE_CENTRAL.GetFacturacionAnterior(do.idcuenta,v_AnioMesActual-2),0) ,
                  NVL(PKG_REPORTE_CENTRAL.GetFacturacionAnterior(do.idcuenta,v_AnioMesActual-1),0) ,
                  NVL(PKG_REPORTE_CENTRAL.GetFacturacionAnterior(do.idcuenta,v_AnioMesActual),0),
                  cu.amotorgado
           HAVING NVL(sum(GetSaldoFactura(do.iddoctrx)),0) > 0)
 GROUP BY cdregion,
          region ,
          cdsucursal,
          sucursal;

     CleanSucursalesSeleccionadas(v_idReporte);

  EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2, 'Modulo: ' || v_Modulo || ' Error: ' || SQLERRM);
      RAISE;
  END GetDeudoresPorVentaGeneral;

   /*****************************************************************************************************************
   * Retorna un reporte del detalle de deudores por ventas
   * %v 30/06/2014 - MatiasG: v1.0
   * %v 23/04/2015 - MartinM: v1.1 - Se ha quitado del join la tabla tbldocumentodeuda para que no de producto cartesiano
   * %v 23/06/2016 - LucianoF: v1.2 - Agrego cuenta CF, quito Comisionista
   ******************************************************************************************************************/
  PROCEDURE GetDeudoresPorVentaDetalle(p_cdsucursal  IN  sucursales.cdsucursal%TYPE,
                           p_identidad   IN  entidades.identidad%TYPE,
                           p_idcuenta    IN  tblcuenta.idcuenta%TYPE,
                           p_cur_out    OUT cursor_type)
  IS
    v_Modulo VARCHAR2(100) := 'PKG_REPORTE_CENTRAL.GetDeudoresPorVentaDetalle';
    v_AnioMesActual  number:=TO_NUMBER(to_char(sysdate,'YYYYMM'));
  BEGIN
    OPEN p_cur_out FOR
       SELECT re.cdregion,
               re.dsregion region,
              su.cdsucursal,
              su.dssucursal sucursal,
              ee.dsrazonsocial cliente,
              ee.cdcuit,
              cu.idcuenta,
              cu.nombrecuenta cuenta,
              NVL(PKG_REPORTE_CENTRAL.GetFacturacionAnterior(do.idcuenta,v_AnioMesActual-2),0) uno,
              NVL(PKG_REPORTE_CENTRAL.GetFacturacionAnterior(do.idcuenta,v_AnioMesActual-1),0) dos,
              NVL(PKG_REPORTE_CENTRAL.GetFacturacionAnterior(do.idcuenta,v_AnioMesActual),0) tres,
              NVL(sum(GetSaldoFactura(do.iddoctrx)),0) saldoventa,
              cu.amotorgado otorgado
         FROM documentos do,
              entidades ee,
              tblcuenta cu,
              sucursales su,
              tblregion re,
              movmateriales mm
        WHERE EXISTS ( SELECT *
                         FROM tbldocumentodeuda dd
                        WHERE dd.iddoctrx    = do.iddoctrx
                          AND dd.cdestado    = 1 --Venta
                           AND dd.dtestadofin IS NULL )
          AND do.identidadreal        = ee.identidad
          --AND cu.cdtipocuenta         = '1'
          AND do.idcuenta             = cu.idcuenta
          AND su.cdregion             = re.cdregion
          AND do.cdsucursal           = su.cdsucursal
          AND do.idmovmateriales      = mm.idmovmateriales
          AND mm.id_canal in ('SA','VE','TE')
          AND (do.cdcomprobante LIKE ('FC%') OR do.cdcomprobante LIKE ('ND%'))
          AND (do.cdsucursal          = p_cdsucursal or p_cdsucursal is null)
          AND (do.identidadreal       = p_identidad  or p_identidad  is null)
          AND (cu.idcuenta            = p_idcuenta   or p_idcuenta   is null)
     GROUP BY re.cdregion,
              re.dsregion ,
              su.cdsucursal,
              su.dssucursal ,
              ee.dsrazonsocial ,
              ee.cdcuit,
              cu.idcuenta,
              cu.nombrecuenta ,
              NVL(PKG_REPORTE_CENTRAL.GetFacturacionAnterior(do.idcuenta,v_AnioMesActual-2),0) ,
              NVL(PKG_REPORTE_CENTRAL.GetFacturacionAnterior(do.idcuenta,v_AnioMesActual-1),0) ,
              NVL(PKG_REPORTE_CENTRAL.GetFacturacionAnterior(do.idcuenta,v_AnioMesActual),0),
              cu.amotorgado
       HAVING NVL(sum(GetSaldoFactura(do.iddoctrx)),0) > 0
     ORDER BY cliente;

  EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2, 'Modulo: ' || v_Modulo || ' Error: ' || SQLERRM);
      RAISE;
  END GetDeudoresPorVentaDetalle;

   /*****************************************************************************************************************
   * Retorna un reporte de deudores morosos agrupado por region y sucursal
   * %v 30/06/2014 - MatiasG: v1.0
    * %v 23/06/2016 - LucianoF: v1.1 - Agrego cuenta CF, quito Comisionista
   ******************************************************************************************************************/
   PROCEDURE GetDeudoresMorososGeneral(p_sucursales  IN VARCHAR2,
                                       p_identidad   IN entidades.identidad%TYPE,
                                       p_idcuenta    IN tblcuenta.idcuenta%TYPE,
                                       p_cur_out     OUT cursor_type)
  IS
    v_Modulo     VARCHAR2(100) := 'PKG_REPORTE_CENTRAL.GetDeudoresMorososGeneral';
    v_AnioMesActual  number:=TO_NUMBER(to_char(sysdate,'YYYYMM'));
    v_idReporte             VARCHAR2(40) := '';
  BEGIN
   v_idReporte := SetSucursalesSeleccionadas(p_sucursales);

    OPEN p_cur_out FOR
         SELECT cdregion, region , cdsucursal, sucursal ,SUM(uno) uno, SUM(dos) dos , SUM(tres) tres ,SUM(saldomoroso) saldomoroso, SUM(amotorgado) otorgado
        FROM (  SELECT re.cdregion,
                re.dsregion region,
                su.cdsucursal,
                su.dssucursal sucursal,
                ee.dsrazonsocial cliente,
                ee.cdcuit,
                cu.idcuenta,
                cu.nombrecuenta cuenta,
                NVL(PKG_REPORTE_CENTRAL.GetFacturacionAnterior(do.idcuenta,v_AnioMesActual-2),0) uno,
                NVL(PKG_REPORTE_CENTRAL.GetFacturacionAnterior(do.idcuenta,v_AnioMesActual-1),0) dos,
                NVL(PKG_REPORTE_CENTRAL.GetFacturacionAnterior(do.idcuenta,v_AnioMesActual),0) tres,
                NVL(sum(GetSaldoFactura(do.iddoctrx)),0)  saldomoroso,
                cu.amotorgado
             FROM documentos do, tbldocumentodeuda dd, entidades ee, tblcuenta cu, tbltmp_sucursales_reporte rs,
             sucursales su, tblregion re, movmateriales mm
            WHERE do.iddoctrx = dd.iddoctrx
              AND dd.cdestado = 2 --Moroso
              AND dd.dtestadofin IS NULL
              AND do.identidadreal = ee.identidad
              AND do.idcuenta = cu.idcuenta
              AND rs.idreporte = v_idReporte
              AND su.cdregion = re.cdregion
              AND su.cdsucursal = rs.cdsucursal
              --AND cu.cdtipocuenta = '1'
              AND do.cdsucursal = su.cdsucursal
              AND do.idmovmateriales      = mm.idmovmateriales
              AND mm.id_canal in ('SA','VE','TE')
              AND (do.cdcomprobante LIKE ('FC%') OR do.cdcomprobante LIKE ('ND%'))
              AND (do.identidadreal       = p_identidad  or p_identidad  is null)
              AND (cu.idcuenta            = p_idcuenta   or p_idcuenta   is null)
            GROUP BY re.cdregion,
                re.dsregion ,
                su.cdsucursal,
                su.dssucursal ,
                ee.dsrazonsocial ,
                ee.cdcuit,
                cu.idcuenta,
                cu.nombrecuenta ,
                NVL(PKG_REPORTE_CENTRAL.GetFacturacionAnterior(do.idcuenta,v_AnioMesActual-2),0) ,
                NVL(PKG_REPORTE_CENTRAL.GetFacturacionAnterior(do.idcuenta,v_AnioMesActual-1),0) ,
                NVL(PKG_REPORTE_CENTRAL.GetFacturacionAnterior(do.idcuenta,v_AnioMesActual),0),
                cu.amotorgado
                HAVING NVL(sum(GetSaldoFactura(do.iddoctrx)),0) > 0)
       GROUP BY cdregion, region , cdsucursal, sucursal;

       CleanSucursalesSeleccionadas(v_idReporte);

 EXCEPTION
    WHEN OTHERS THEN
       n_pkg_vitalpos_log_general.write(2, 'Modulo: ' || v_Modulo || ' Error: ' || SQLERRM);
       RAISE;
 END GetDeudoresMorososGeneral;

   /*****************************************************************************************************************
   * Retorna un reporte del detalle de deudores morosos
   * %v 30/06/2014 - MatiasG: v1.0
   * %v 23/06/2016 - LucianoF: v1.1 - Agrego cuenta CF, quito Comisionista
   ******************************************************************************************************************/
   PROCEDURE GetDeudoresMorososDetalle(p_cdsucursal  IN sucursales.cdsucursal%TYPE,
                           p_identidad   IN entidades.identidad%TYPE,
                           p_idcuenta    IN tblcuenta.idcuenta%TYPE,
                           p_cur_out     OUT cursor_type)
  IS
        v_Modulo         VARCHAR2(100) := 'PKG_REPORTE_CENTRAL.GetDeudoresMorososDetalle';
        v_AnioMesActual  number:=TO_NUMBER(to_char(sysdate,'YYYYMM'))   ;
   BEGIN
     OPEN p_cur_out FOR
       SELECT re.cdregion,
            re.dsregion region,
            su.cdsucursal,
            su.dssucursal sucursal,
            ee.dsrazonsocial cliente,
            ee.cdcuit,
            cu.idcuenta,
            cu.nombrecuenta cuenta,
            NVL(PKG_REPORTE_CENTRAL.GetFacturacionAnterior(do.idcuenta,v_AnioMesActual-2),0) uno,
            NVL(PKG_REPORTE_CENTRAL.GetFacturacionAnterior(do.idcuenta,v_AnioMesActual-1),0) dos,
            NVL(PKG_REPORTE_CENTRAL.GetFacturacionAnterior(do.idcuenta,v_AnioMesActual),0) tres,
            NVL(sum(GetSaldoFactura(do.iddoctrx)),0) saldomoroso,
            cu.amotorgado otorgado
         FROM documentos do, tbldocumentodeuda dd, entidades ee, tblcuenta cu, sucursales su, tblregion re,
              movmateriales mm
        WHERE do.iddoctrx = dd.iddoctrx
          AND dd.cdestado = 2 --Moroso
          AND dd.dtestadofin IS NULL
          AND do.identidadreal = ee.identidad
          AND do.idcuenta = cu.idcuenta
          --AND cu.cdtipocuenta = '1'
          AND su.cdregion = re.cdregion
          AND do.cdsucursal = su.cdsucursal
          AND do.idmovmateriales      = mm.idmovmateriales
          AND mm.id_canal in ('SA','VE','TE')
          AND (do.cdcomprobante LIKE ('FC%') OR do.cdcomprobante LIKE ('ND%'))
          AND (do.cdsucursal          = p_cdsucursal or p_cdsucursal is null)
          AND (do.identidadreal       = p_identidad  or p_identidad  is null)
          AND (cu.idcuenta            = p_idcuenta   or p_idcuenta   is null)
        GROUP BY re.cdregion,
            re.dsregion ,
            su.cdsucursal,
            su.dssucursal ,
            ee.dsrazonsocial ,
            ee.cdcuit,
            cu.idcuenta,
            cu.nombrecuenta ,
            NVL(PKG_REPORTE_CENTRAL.GetFacturacionAnterior(do.idcuenta,v_AnioMesActual-2),0) ,
            NVL(PKG_REPORTE_CENTRAL.GetFacturacionAnterior(do.idcuenta,v_AnioMesActual-1),0) ,
            NVL(PKG_REPORTE_CENTRAL.GetFacturacionAnterior(do.idcuenta,v_AnioMesActual),0),
            cu.amotorgado
            HAVING NVL(sum(GetSaldoFactura(do.iddoctrx)),0) > 0
            ORDER BY cliente;

   EXCEPTION
      WHEN OTHERS THEN
         n_pkg_vitalpos_log_general.write(2, 'Modulo: ' || v_Modulo || ' Error: ' || SQLERRM);
         RAISE;
   END GetDeudoresMorososDetalle;

   /*****************************************************************************************************************
   * Retorna un reporte del ranking de deudores agrupado por region y sucursal
   * %v 30/06/2014 - MatiasG: v1.0
   ******************************************************************************************************************/
  PROCEDURE GetRankingDeudoresGeneral(p_cdregion     IN tblregion.cdregion%TYPE,
                          p_sucursales   IN VARCHAR2,
                          p_cur_out      OUT cursor_type)
  IS
    v_Modulo     VARCHAR2(100) := 'PKG_REPORTE_CENTRAL.GetRankingDeudoresGeneral';
    v_idReporte             VARCHAR2(40) := '';
  BEGIN
    v_idReporte := SetSucursalesSeleccionadas(p_sucursales);

    OPEN p_cur_out FOR
      SELECT re.cdregion,
           re.dsregion region,
           su.cdsucursal,
           su.dssucursal sucursal,
           ee.dsrazonsocial cliente,
           ee.cdcuit,
           cu.nombrecuenta cuenta,
           DECODE(dd.cdestado, 1, 'Deudor Por Venta', 2, 'Deudor Moroso', 3, 'Gestión Judicial') nivelgestion,
           MAX(trunc(SYSDATE - do.dtdocumento)) dias,
           trunc(SUM(getSaldoFactura(do.iddoctrx)),2) saldo
        FROM documentos                do,
           tbldocumentodeuda         dd,
           tblcuenta                 cu,
           entidades                 ee,
           sucursales                su,
           tblregion                 re,
           tbltmp_sucursales_reporte rs
       WHERE do.iddoctrx = dd.iddoctrx
        AND do.idcuenta = cu.idcuenta
        AND do.identidadreal = ee.identidad
        AND do.cdsucursal = su.cdsucursal
        AND su.cdregion = re.cdregion
        AND cu.cdtipocuenta = '1'
        AND dd.dtestadofin IS NULL
        AND su.cdsucursal = rs.cdsucursal
        AND rs.idreporte = v_idReporte
        AND re.cdregion = NVL(p_cdregion, re.cdregion)
       GROUP BY re.cdregion,
             re.dsregion,
             su.cdsucursal,
             su.dssucursal,
             ee.dsrazonsocial,
             ee.cdcuit,
             cu.nombrecuenta,
             DECODE(dd.cdestado, 1, 'Deudor Por Venta', 2, 'Deudor Moroso', 3, 'Gestión Judicial')
           HAVING trunc(SUM(getSaldoFactura(do.iddoctrx)),2) > 0
       ORDER BY saldo DESC;

    CleanSucursalesSeleccionadas(v_idReporte);
  EXCEPTION
   WHEN OTHERS THEN
     n_pkg_vitalpos_log_general.write(2, 'Modulo: ' || v_Modulo || ' Error: ' || SQLERRM);
     RAISE;
  END GetRankingDeudoresGeneral;

  /*****************************************************************************************************************
   * Retorna un reporte de facturas pendientes agrupado por region y sucursal
   * %v 30/06/2014 - MatiasG: v1.0
   ******************************************************************************************************************/
    PROCEDURE GetRankingDeudoresPorSucursal(p_cdregion   IN tblregion.cdregion%TYPE,
                                            p_sucursales IN VARCHAR2,
                                            p_cur_out    OUT cursor_type) IS
      v_Modulo VARCHAR2(100) := 'PKG_REPORTE_CENTRAL.GetRankingDeudoresPorSucursal';
      v_idReporte VARCHAR2(40) := '';
    BEGIN
       v_idReporte := SetSucursalesSeleccionadas(p_sucursales);

       OPEN p_cur_out FOR
        select  cdregion, region, cdsucursal, sucursal, sum(deuda) deuda, sum(morosos) morosos from
        (SELECT re.cdregion,
        re.dsregion region,
        su.cdsucursal,
        su.dssucursal sucursal,
        CASE dd.cdestado
        WHEN 1 THEN NVL(sum(PKG_REPORTE_CENTRAL.GetSaldoFactura(do.iddoctrx)),0)
        END deuda,
        CASE dd.cdestado
        WHEN 2 THEN NVL(sum(PKG_REPORTE_CENTRAL.GetSaldoFactura(do.iddoctrx)),0)
        END morosos
        FROM documentos do, tbldocumentodeuda dd, entidades ee, tblcuenta cu, tbltmp_sucursales_reporte rs,
        sucursales su, tblregion re
        WHERE do.iddoctrx = dd.iddoctrx
        AND dd.cdestado = 1 --Ventas
        AND dd.dtestadofin IS NULL
        AND do.identidadreal = ee.identidad
        AND do.idcuenta = cu.idcuenta
        AND rs.idreporte = v_idReporte
        AND rs.cdsucursal= su.cdsucursal
        AND re.cdregion = NVL(p_cdregion,re.cdregion)
        AND su.cdregion = re.cdregion
        AND cu.cdtipocuenta = '1'
        AND do.cdsucursal = su.cdsucursal
        AND (do.cdcomprobante LIKE ('FC%') OR do.cdcomprobante LIKE ('ND%'))
        GROUP BY re.cdregion,
        re.dsregion ,
        su.cdsucursal,
        su.dssucursal,
        dd.cdestado
        HAVING NVL(sum(PKG_REPORTE_CENTRAL.GetSaldoFactura(do.iddoctrx)),0) > 0
        union
        SELECT re.cdregion,
        re.dsregion region,
        su.cdsucursal,
        su.dssucursal sucursal,
        CASE dd.cdestado
        WHEN 1 THEN NVL(sum(PKG_REPORTE_CENTRAL.GetSaldoFactura(do.iddoctrx)),0)
        END deuda,
        CASE dd.cdestado
        WHEN 2 THEN NVL(sum(PKG_REPORTE_CENTRAL.GetSaldoFactura(do.iddoctrx)),0)
        END morosos
        FROM documentos do, tbldocumentodeuda dd, entidades ee, tblcuenta cu, tbltmp_sucursales_reporte rs,
        sucursales su, tblregion re
        WHERE do.iddoctrx = dd.iddoctrx
        AND dd.cdestado = 2 --Moroso
        AND dd.dtestadofin IS NULL
        AND do.identidadreal = ee.identidad
        AND do.idcuenta = cu.idcuenta
        AND rs.idreporte = v_idReporte
        AND rs.cdsucursal= su.cdsucursal
        AND re.cdregion = NVL(p_cdregion,re.cdregion)
        AND su.cdregion = re.cdregion
        AND cu.cdtipocuenta = '1'
        AND do.cdsucursal = su.cdsucursal
        AND (do.cdcomprobante LIKE ('FC%') OR do.cdcomprobante LIKE ('ND%'))
        GROUP BY re.cdregion,
        re.dsregion ,
        su.cdsucursal,
        su.dssucursal,
        dd.cdestado
        HAVING NVL(sum(PKG_REPORTE_CENTRAL.GetSaldoFactura(do.iddoctrx)),0) > 0  )
        group by  cdregion, region, cdsucursal, sucursal;

          CleanSucursalesSeleccionadas(v_idReporte);
    EXCEPTION
       WHEN OTHERS THEN
          n_pkg_vitalpos_log_general.write(2, 'Modulo: ' || v_Modulo || ' Error: ' || SQLERRM);
          RAISE;
    END GetRankingDeudoresPorSucursal;

   /*****************************************************************************************************************
   * Dado un cliente retorna el nombre del comisionista
   * %v 01/09/2016 - JBodnar: v1.0
   ******************************************************************************************************************/
   FUNCTION GetClienteComisionista(p_identidad IN tblcuenta.identidad%TYPE)
      RETURN entidades.dsrazonsocial%TYPE IS
      v_dsnombre    entidades.dsrazonsocial%TYPE;
   BEGIN

      select ec.dsrazonsocial
      into v_dsnombre
      from clientescomisionistas cc, entidades ec
      where cc.identidad = p_identidad
      and ec.identidad = cc.idcomisionista
      and rownum = 1;

      RETURN ' ('||v_dsnombre||')';
   EXCEPTION
      WHEN OTHERS THEN
         null;
         RAISE;
   END GetClienteComisionista;

     /*****************************************************************************************************************
   * Retorna un reporte de aging de deuda agrupado por region y sucursal
   * %v 30/06/2014 - MatiasG: v1.0
   * %v 23/06/2016 - LucianoF: v1.1 - Agrego cuentas de CF y quito canal CO
   * %v 21/12/2016 - JBodnar: Apunta a la nueva tblagingdeuda para mejorar la performance
   * %v 13/11/2017 - APW: quito los datos de comisionistas
   ******************************************************************************************************************/
    PROCEDURE GetAgingDeudaGeneral(p_cdregion   IN tblregion.cdregion%TYPE,
                                   p_sucursales IN VARCHAR2,
                                   p_identidad  IN entidades.identidad%TYPE,
                                   p_idcuenta   IN tblcuenta.idcuenta%TYPE,
                                   p_cur_out    OUT cursor_type) IS
       v_Modulo    VARCHAR2(100) := 'PKG_REPORTE_CENTRAL.GetAgingDeudaGeneral';
       v_idReporte VARCHAR2(40) := '';
    BEGIN
     v_idReporte := SetSucursalesSeleccionadas(p_sucursales);

       OPEN p_cur_out FOR
      select * from (
        SELECT a.cdregion,
               a.dsregion region,
               a.cdsucursal,
               a.dssucursal sucursal,
               a.aging ,
               sum(a.saldo)  saldo
            FROM tblagingdeuda a, tbltmp_sucursales_reporte rs
            where a.cdregion = nvl(p_cdregion, a.cdregion)
            and rs.cdsucursal = a.cdsucursal
            and rs.idreporte = v_idReporte
            and a.identidad = nvl(p_identidad, a.identidad)
            and a.idcuenta = nvl(p_idcuenta,a.idcuenta )
            and a.identidad not in (select re.identidad from rolesentidades re where re.cdrol = '1')
            group by  a.cdregion, a.dsregion , a.cdsucursal, a.dssucursal, a.aging);

     CleanSucursalesSeleccionadas(v_idReporte);
   EXCEPTION
       WHEN OTHERS THEN
          n_pkg_vitalpos_log_general.write(2, 'Modulo: ' || v_Modulo || ' Error: ' || SQLERRM);
          RAISE;
    END GetAgingDeudaGeneral;

   /*****************************************************************************************************************
   * Retorna un reporte del detalle de aging de deuda
   * %v 30/06/2014 - MatiasG: v1.0
   * %v 23/06/2016 - LucianoF: v1.1 - Agrego cuentas de CF y quito canal CO
   * %v 31/08/2016 - JBodnar: Se agrega el nombre del comisionista en los clientes que correspondan
   * %v 21/12/2016 - JBodnar: Apunta a la nueva tblagingdeuda para mejorar la performance
   * %v 13/11/2017 - APW: quito los datos de comisionistas
   ******************************************************************************************************************/
   PROCEDURE GetAgingDeudaDetalle(p_cdsucursal IN sucursales.cdsucursal%TYPE,
                         p_identidad  IN entidades.identidad%TYPE,
                        p_idcuenta   IN tblcuenta.idcuenta%TYPE,
                        p_cur_out    OUT cursor_type)
   IS
     v_Modulo VARCHAR2(100) := 'PKG_REPORTE_CENTRAL.GetAgingDeudaDetalle';
   BEGIN
     OPEN p_cur_out FOR

      select * from (
        SELECT a.dsregion region,
               a.dssucursal sucursal,
               a.dsrazonsocial cliente,
               a.cdcuit,
               a.idcuenta,
               a.nombrecuenta cuenta,
               a.aging ,
               sum(a.saldo)  saldo
            FROM tblagingdeuda a
            where a.cdsucursal = nvl(p_cdsucursal, a.cdsucursal)
            and a.identidad = nvl(p_identidad, a.identidad)
            and a.idcuenta = nvl(p_idcuenta,a.idcuenta )
            and a.identidad not in (select re.identidad from rolesentidades re where re.cdrol = '1')
            group by a.dsregion , a.dssucursal, a.dsrazonsocial, a.cdcuit,a.idcuenta, a.nombrecuenta, a.aging)
            order by cliente;

   EXCEPTION
     WHEN OTHERS THEN
       n_pkg_vitalpos_log_general.write(2, 'Modulo: ' || v_Modulo || ' Error: ' || SQLERRM);
       RAISE;
   END GetAgingDeudaDetalle;

   /*****************************************************************************************************************
   * Retorna un reporte de acreditacion posner agrupado por region y sucursal
   * %v 30/06/2014 - MatiasG: v1.0
   * %v 15/01/2015 - MartinM: v1.1 Filtro en la tabla tblingresos todos los registros de cdforma 4 (PostNet)
   * %v 05/01/2016 - LucianoF: v1.2 Agrego CE y Tercero para CL y PB
   * %v 16/06/2017 - IAquilano: Agrego CE
   * %v 10/08/2017 - APW: aplico el comentario de buscar solo compra de cuentas con establecimiento a todas las consultas
   * %v 12/04/2018 - JBodanr: Se agrega el filtro en los ingresos para que no tome los rechazados cdestado <> '4' --No rechazado
   ******************************************************************************************************************/
  PROCEDURE GetAcreditacionPosnetGeneral(p_cdregion   IN tblregion.cdregion%TYPE,
                                         p_sucursales IN VARCHAR2,
                                         p_identidad  IN entidades.identidad%TYPE,
                                         p_idcuenta   IN tblcuenta.idcuenta%TYPE,
                                         p_fechaDesde IN DATE,
                                         p_fechaHasta IN DATE,
                                         p_cdforma    IN tblformaingreso.cdforma%TYPE,
                                         p_cur_out    OUT cursor_type) IS
    v_Modulo    VARCHAR2(100) := 'PKG_REPORTE_CENTRAL.GetAcreditacionPosnetGeneral';
    v_idReporte VARCHAR2(40) := '';

  BEGIN
    v_idReporte := SetSucursalesSeleccionadas(p_sucursales);
    --PB o CL o CE
    if p_cdforma is not null then
      If p_cdforma = '2' then
        OPEN p_cur_out FOR

        SELECT cdregion,
               region,
               cdsucursal,
               sucursal,
               trunc(SUM(amdocumentoCuit), 2) compraCuit,
               trunc(SUM(amdocumentoCF), 2) compraCF,
               trunc(SUM(amingreso), 2) acreditacion
          FROM (SELECT distinct re.cdregion,
                       re.dsregion    region,
                       su.cdsucursal,
                       su.dssucursal  sucursal,
                       do.amdocumento amdocumentoCuit,
                       0              amdocumentoCF,
                       0              amingreso, do.iddoctrx
                  FROM documentos                do,
                       sucursales                su,
                       tblregion                 re,
                       tbltmp_sucursales_reporte rs,
                       entidades                 ee,
                       tblcuenta                 cu,
                       tblclientespecial         ce,--Agrego 3 tablas desde aca
                       tblestablecimientomaycar  em,
                       tbltipoingreso            ti
                 WHERE do.cdsucursal = su.cdsucursal
                   AND su.cdsucursal = rs.cdsucursal
                   AND rs.idreporte = v_idReporte
                   and do.cdsucursal = su.cdsucursal
                   AND do.identidadreal = ee.identidad
                   AND do.idcuenta = cu.idcuenta
                   AND cu.cdtipocuenta = '1'
                   AND ce.idestablecimientomaycar = em.idestablecimientomaycar--desde aca
                   AND ti.cdtipo = em.cdtipo
                   AND ce.idcuenta = cu.idcuenta
                   and em.cdforma = p_cdforma-- Hago los joins correspondientes
                   and em.cdsucursal = cu.cdsucursal-- HAsta aca
                   AND do.identidadreal = NVL(p_identidad, do.identidadreal)
                   AND re.cdregion = NVL(p_cdregion, re.cdregion)
                   AND do.idcuenta = NVL(p_idcuenta, do.idcuenta)
                   AND do.dtdocumento BETWEEN trunc(p_fechaDesde) AND trunc(p_fechaHasta + 1)
                   AND (do.cdcomprobante LIKE ('FC%') OR
                       do.cdcomprobante LIKE ('NC%') OR
                       do.cdcomprobante LIKE ('ND%'))
                   AND su.cdregion = re.cdregion
         /*             --busco solo datos de cuentas que tengan establecimientos
                   AND (select count(*)
                          from tblestablecimiento es
                         where es.idcuenta = cu.idcuenta) > 0*/
                UNION ALL
                SELECT distinct re.cdregion,
                       re.dsregion    region,
                       su.cdsucursal,
                       su.dssucursal  sucursal,
                       0              amdocumentoCuit,
                       do.amdocumento amdocumentoCF,
                       0              amingreso, do.iddoctrx
                  FROM documentos                do,
                       sucursales                su,
                       tblregion                 re,
                       tbltmp_sucursales_reporte rs,
                       entidades                 ee,
                       tblcuenta                 cu,
                       tblcuenta                 cu1,
                       tblclientespecial         ce,-- Rerpito lo de arriba
                       tblestablecimientomaycar  em,
                       tbltipoingreso            ti
                 WHERE do.cdsucursal = su.cdsucursal
                   AND rs.idreporte = v_idReporte
                   AND su.cdsucursal = rs.cdsucursal
                   and do.cdsucursal = su.cdsucursal
                   AND do.identidadreal = ee.identidad
                   AND do.idcuenta = cu.idcuenta
                   AND cu.cdtipocuenta = '2'
                   AND ce.idestablecimientomaycar = em.idestablecimientomaycar-- desde aca
                   AND ti.cdtipo = em.cdtipo
                   AND ce.idcuenta = cu.idcuenta
                   and em.cdforma = p_cdforma
                   and em.cdsucursal = cu.cdsucursal-- hasta aca
                   AND do.identidadreal = NVL(p_identidad, do.identidadreal)
                   AND re.cdregion = NVL(p_cdregion, re.cdregion)
                   AND do.idcuenta = NVL(p_idcuenta, do.idcuenta)
                   AND do.dtdocumento BETWEEN trunc(p_fechaDesde) AND trunc(p_fechaHasta + 1)
                   AND (do.cdcomprobante LIKE ('FC%') OR
                       do.cdcomprobante LIKE ('NC%') OR
                       do.cdcomprobante LIKE ('ND%'))
                   AND su.cdregion = re.cdregion
                   AND cu.idpadre = cu1.idcuenta
                 /*     --busco solo datos de cuentas que tengan establecimientos
                   AND (select count(*)
                          from tblestablecimiento es
                         where es.idcuenta = cu1.idcuenta) > 0*/
                UNION ALL
                SELECT distinct re.cdregion,
                       re.dsregion   region,
                       su.cdsucursal,
                       su.dssucursal sucursal,
                       0             amdocumentoCuit,
                       0             amdocumentoCF,
                       ii.amingreso  amingreso, ii.idingreso
                  FROM tblingreso                ii,
                       sucursales                su,
                       tblregion                 re,
                       tbltmp_sucursales_reporte rs,
                       tblcuenta                 cu,
                       entidades                 ee,
                       tblconfingreso            tci,
                       tblclientespecial         ce,
                       tblestablecimientomaycar  em,
                       tbltipoingreso            ti
                 WHERE ii.cdsucursal = su.cdsucursal
                   AND su.cdsucursal = rs.cdsucursal
                   AND ii.idcuenta = cu.idcuenta
                   AND cu.identidad = ee.identidad
                   AND rs.idreporte = v_idReporte
                   and ii.cdestado <> '4' --No rechazado
                   and ii.cdsucursal = su.cdsucursal
                   AND su.cdregion = re.cdregion
                   AND ce.idestablecimientomaycar =
                       em.idestablecimientomaycar
                   AND ti.cdtipo = em.cdtipo
                    and tci.cdtipo=ti.cdtipo
                   AND ce.idcuenta = cu.idcuenta
                   and em.cdforma = p_cdforma
                   AND cu.identidad = NVL(p_identidad, cu.identidad)
                   AND ii.idcuenta = NVL(p_idcuenta, ii.idcuenta)
                   AND ii.dtingreso BETWEEN trunc(p_fechaDesde) AND trunc(p_fechaHasta + 1)
                   AND tci.cdconfingreso = ii.cdconfingreso
                   AND tci.cdsucursal = ii.cdsucursal
                   AND tci.cdaccion = 1
                   and em.cdsucursal = cu.cdsucursal --solo ingresos)
               AND (
               (tci.cdforma in (2) and ee.cdforma = 5)) --Agrego CE
        AND re.cdregion = NVL(p_cdregion, re.cdregion))
         GROUP BY cdregion, region, cdsucursal, sucursal;
     else
      OPEN p_cur_out FOR
        SELECT cdregion,
               region,
               cdsucursal,
               sucursal,
               trunc(SUM(amdocumentoCuit), 2) compraCuit,
               trunc(SUM(amdocumentoCF), 2) compraCF,
               trunc(SUM(amingreso), 2) acreditacion
          FROM (SELECT re.cdregion,
                       re.dsregion    region,
                       su.cdsucursal,
                       su.dssucursal  sucursal,
                       do.amdocumento amdocumentoCuit,
                       0              amdocumentoCF,
                       0              amingreso
                  FROM documentos                do,
                       sucursales                su,
                       tblregion                 re,
                       tbltmp_sucursales_reporte rs,
                       entidades                 ee,
                       tblcuenta                 cu
                 WHERE do.cdsucursal = su.cdsucursal
                   AND su.cdsucursal = rs.cdsucursal
                   AND rs.idreporte = v_idReporte
                   AND do.identidadreal = ee.identidad
                   AND do.idcuenta = cu.idcuenta
                   AND cu.cdtipocuenta = '1'
                  AND ee.cdforma = p_cdforma
                   AND do.identidadreal = NVL(p_identidad, do.identidadreal)
                   AND re.cdregion = NVL(p_cdregion, re.cdregion)
                   AND do.idcuenta = NVL(p_idcuenta, do.idcuenta)
                   AND do.dtdocumento BETWEEN trunc(p_fechaDesde) AND
                       trunc(p_fechaHasta + 1)
                   AND (do.cdcomprobante LIKE ('FC%') OR
                       do.cdcomprobante LIKE ('NC%') OR
                       do.cdcomprobante LIKE ('ND%'))
                   AND su.cdregion = re.cdregion
                  /*  --busco solo datos de cuentas que tengan establecimientos -- APW 10/8/2017
                   AND (select count(*) from tblestablecimiento es where es.idcuenta = cu.idcuenta) > 0*/
                UNION ALL
                SELECT re.cdregion,
                       re.dsregion    region,
                       su.cdsucursal,
                       su.dssucursal  sucursal,
                       0              amdocumentoCuit,
                       do.amdocumento amdocumentoCF,
                       0              amingreso
                  FROM documentos                do,
                       sucursales                su,
                       tblregion                 re,
                       tbltmp_sucursales_reporte rs,
                       entidades                 ee,
                       tblcuenta                 cu,
                       tblcuenta                 cu1
                 WHERE do.cdsucursal = su.cdsucursal
                   AND rs.idreporte = v_idReporte
                   AND su.cdsucursal = rs.cdsucursal
                   AND do.identidadreal = ee.identidad
                   AND do.idcuenta = cu.idcuenta
                   AND cu.cdtipocuenta = '2'
                    AND ee.cdforma = p_cdforma

                   AND do.identidadreal = NVL(p_identidad, do.identidadreal)
                   AND re.cdregion = NVL(p_cdregion, re.cdregion)
                   AND do.idcuenta = NVL(p_idcuenta, do.idcuenta)
                   AND do.dtdocumento BETWEEN trunc(p_fechaDesde) AND
                       trunc(p_fechaHasta + 1)
                   AND (do.cdcomprobante LIKE ('FC%') OR
                       do.cdcomprobante LIKE ('NC%') OR
                       do.cdcomprobante LIKE ('ND%'))
                   AND su.cdregion = re.cdregion
                   AND cu.idpadre = cu1.idcuenta
                  /* --busco solo datos de cuentas que tengan establecimientos -- APW 10/8/2017
                   AND (select count(*) from tblestablecimiento es where es.idcuenta = cu1.idcuenta) > 0*/
                UNION ALL
                SELECT re.cdregion,
                       re.dsregion   region,
                       su.cdsucursal,
                       su.dssucursal sucursal,
                       0             amdocumentoCuit,
                       0             amdocumentoCF,
                       ii.amingreso  amingreso
                  FROM tblingreso                ii,
                       sucursales                su,
                       tblregion                 re,
                       tbltmp_sucursales_reporte rs,
                       tblcuenta                 cu,
                       entidades                 ee,
                       tblconfingreso            tci
                 WHERE ii.cdsucursal = su.cdsucursal
                   AND su.cdsucursal = rs.cdsucursal
                   AND ii.idcuenta = cu.idcuenta
                   AND cu.identidad = ee.identidad
                   AND rs.idreporte = v_idReporte
                   AND su.cdregion = re.cdregion
                   and ii.cdestado <> '4' --No rechazado
                    AND ee.cdforma = p_cdforma
                   AND cu.identidad = NVL(p_identidad, cu.identidad)
                   AND ii.idcuenta = NVL(p_idcuenta, ii.idcuenta)
                   AND ii.dtingreso BETWEEN trunc(p_fechaDesde) AND
                       trunc(p_fechaHasta + 1)
                   AND tci.cdconfingreso = ii.cdconfingreso
                   AND tci.cdsucursal = ii.cdsucursal
                   AND tci.cdaccion = 1 --solo ingresos
                   AND (/*(tci.cdforma in (3, 4) and p_cdforma = 4) or*/
                       (tci.cdforma in (/*2,*/ 3, 5) and p_cdforma = 5)) --Agrego CE y Tercero. LM. 23.06.2017. Se quita la forma '2', que es CE
                   AND re.cdregion = NVL(p_cdregion, re.cdregion))
         GROUP BY cdregion, region, cdsucursal, sucursal;
       End If;
    ELSE
      --Todos
      OPEN p_cur_out FOR
        SELECT cdregion,
               region,
               cdsucursal,
               sucursal,
               trunc(SUM(amdocumentoCuit), 2) compraCuit,
               trunc(SUM(amdocumentoCF), 2) compraCF,
               trunc(SUM(amingreso), 2) acreditacion
          FROM (SELECT re.cdregion,
                       re.dsregion    region,
                       su.cdsucursal,
                       su.dssucursal  sucursal,
                       do.amdocumento amdocumentoCuit,
                       0              amdocumentoCF,
                       0              amingreso
                  FROM documentos                do,
                       sucursales                su,
                       tblregion                 re,
                       tbltmp_sucursales_reporte rs,
                       entidades                 ee,
                       tblcuenta                 cu
                 WHERE do.cdsucursal = su.cdsucursal
                   AND su.cdsucursal = rs.cdsucursal
                   AND rs.idreporte = v_idReporte
                   AND do.identidadreal = ee.identidad
                   AND do.idcuenta = cu.idcuenta
                   AND cu.cdtipocuenta = '1'
                   AND ee.cdforma in (4, 5) --PB y CL
                   AND do.identidadreal = NVL(p_identidad, do.identidadreal)
                   AND re.cdregion = NVL(p_cdregion, re.cdregion)
                   AND do.idcuenta = NVL(p_idcuenta, do.idcuenta)
                   AND do.dtdocumento BETWEEN trunc(p_fechaDesde) AND
                       trunc(p_fechaHasta + 1)
                   AND (do.cdcomprobante LIKE ('FC%') OR
                       do.cdcomprobante LIKE ('NC%') OR
                       do.cdcomprobante LIKE ('ND%'))
                   AND su.cdregion = re.cdregion
                   /* --busco solo datos de cuentas que tengan establecimientos -- APW 10/8/2017
                   AND (select count(*) from tblestablecimiento es where es.idcuenta = cu.idcuenta) > 0*/
                UNION ALL
                SELECT re.cdregion,
                       re.dsregion    region,
                       su.cdsucursal,
                       su.dssucursal  sucursal,
                       0              amdocumentoCuit,
                       do.amdocumento amdocumentoCF,
                       0              amingreso
                  FROM documentos                do,
                       sucursales                su,
                       tblregion                 re,
                       tbltmp_sucursales_reporte rs,
                       entidades                 ee,
                       tblcuenta                 cu,
                       tblcuenta                 cu1
                 WHERE do.cdsucursal = su.cdsucursal
                   AND rs.idreporte = v_idReporte
                   AND su.cdsucursal = rs.cdsucursal
                   AND do.identidadreal = ee.identidad
                   AND do.idcuenta = cu.idcuenta
                   AND cu.cdtipocuenta = '2'
                   AND ee.cdforma in (4, 5) --PB y CL
                   AND do.identidadreal = NVL(p_identidad, do.identidadreal)
                   AND re.cdregion = NVL(p_cdregion, re.cdregion)
                   AND do.idcuenta = NVL(p_idcuenta, do.idcuenta)
                   AND do.dtdocumento BETWEEN trunc(p_fechaDesde) AND
                       trunc(p_fechaHasta + 1)
                   AND (do.cdcomprobante LIKE ('FC%') OR
                       do.cdcomprobante LIKE ('NC%') OR
                       do.cdcomprobante LIKE ('ND%'))
                   AND su.cdregion = re.cdregion
                   AND cu.idpadre = cu1.idcuenta
                  /*  --busco solo datos de cuentas que tengan establecimientos -- APW 10/8/2017
                   AND (select count(*) from tblestablecimiento es where es.idcuenta = cu1.idcuenta) > 0*/
                UNION ALL
                SELECT re.cdregion,
                       re.dsregion   region,
                       su.cdsucursal,
                       su.dssucursal sucursal,
                       0             amdocumentoCuit,
                       0             amdocumentoCF,
                       ii.amingreso  amingreso
                  FROM tblingreso                ii,
                       sucursales                su,
                       tblregion                 re,
                       tbltmp_sucursales_reporte rs,
                       tblcuenta                 cu,
                       entidades                 ee,
                       tblconfingreso            tci
                 WHERE ii.cdsucursal = su.cdsucursal
                   AND su.cdsucursal = rs.cdsucursal
                   AND ii.idcuenta = cu.idcuenta
                   AND cu.identidad = ee.identidad
                   AND rs.idreporte = v_idReporte
                   and ii.cdestado <> '4' --No rechazado
                   AND ee.cdforma in (4, 5) --PB y CL
                   AND su.cdregion = re.cdregion
                   AND cu.identidad = NVL(p_identidad, cu.identidad)
                   AND ii.idcuenta = NVL(p_idcuenta, ii.idcuenta)
                   AND ii.dtingreso BETWEEN trunc(p_fechaDesde) AND
                       trunc(p_fechaHasta + 1)
                   AND tci.cdconfingreso = ii.cdconfingreso
                   AND tci.cdsucursal = ii.cdsucursal
                   AND tci.cdforma in (2, 3, 4, 5) --PB y CL --LF: Agrego CE y Tercero
                   AND tci.cdaccion = 1 -- solo ingresos
                   AND re.cdregion = NVL(p_cdregion, re.cdregion))
         GROUP BY cdregion, region, cdsucursal, sucursal;
    end if;

    CleanSucursalesSeleccionadas(v_idReporte);
  EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_Modulo || ' Error: ' ||
                                       SQLERRM);
      RAISE;
  END GetAcreditacionPosnetGeneral;

      /*****************************************************************************************************************
   * Retorna un reporte del detalle de acreditacion posnet
   * %v 30/06/2014 - MatiasG: v1.0
   * %v 15/01/2015 - MartinM: v1.1 Filtro en la tabla tblingresos todos los registros de cdforma 4 (PostNet)
   * %v 05/01/2016 - LucianoF: v1.2 Agrego CE y Tercero para CL y PB
   * %v 09/09/2016 - LucianoF: v1.3 Unifico registros de cuenta 1 y 2
   * %v 10/08/2017 - APW: aplico el comentario de buscar solo compra de cuentas con establecimiento a todas las consultas
   * %v 09/11/2017 - JB: se agrega una funcion que mira si el cliente tiene baja la terminal posnet
   * %v 12/04/2018 - JBodanr: Se agrega el filtro en los ingresos para que no tome los rechazados cdestado <> '4' --No rechazado
   * %v 20/07/2018 - LM: se agregan los clientes especiales cuando el cliente no tiene compra ni acreditacion.
   * %v 18/02/2020 - APW: Se corrige dsforma en rama "todos"
   ******************************************************************************************************************/
    PROCEDURE GetAcreditacionPosnetDetalle(p_cdsucursal IN sucursales.cdsucursal%TYPE,
                                           p_identidad  IN entidades.identidad%TYPE,
                                           p_idcuenta   IN tblcuenta.idcuenta%TYPE,
                                           p_fechaDesde IN DATE,
                                           p_fechaHasta IN DATE,
                                           p_cdforma    IN tblformaingreso.cdforma%TYPE,
                                           p_cur_out    OUT cursor_type) IS
      v_Modulo VARCHAR2(100) := 'PKG_REPORTE_CENTRAL.GetAcreditacionPosnetDetalle';
    BEGIN

      --PB o CL
      if p_cdforma is not null then
        If p_cdforma = '2' then
        OPEN p_cur_out FOR
        SELECT region,
                 sucursal,
                 cliente,
                 cdcuit,
                 cuenta,
                 idcuenta,
                 trunc(SUM(amdocumentoCuit), 2) compraCuit,
                 trunc(SUM(amdocumentoCF), 2) compraCF,
                 trunc(SUM(amingreso), 2) acreditacion,
                 decode(cdforma, 4, 'P.B.', 5, 'C.L.',2,'CE') dsforma,
                 baja,
                 Opcion_De_Venta
          --Opcion_De_Venta
            FROM ( --- compra cuenta 1
                  SELECT distinct re.dsregion region,
                          su.dssucursal sucursal,
                          ee.dsrazonsocial cliente,
                          ee.cdcuit,
                          cu.nombrecuenta cuenta,
                          cu.idcuenta,
                          do.amdocumento amdocumentoCuit,
                          0 amdocumentoCF,
                          0 amingreso,
                          em.cdforma,
                          EsBajaPBN(cu.idcuenta) baja,
                          GetCanal(ee.identidad, ee.cdmainsucursal) as Opcion_De_Venta,  do.iddoctrx
                    FROM documentos do,
                          sucursales su,
                          tblregion  re,
                          tblcuenta  cu,
                          entidades  ee,
                          tblclientespecial         ce,--Agrego 3 tablas
                          tblestablecimientomaycar  em,
                          tbltipoingreso            ti
                   WHERE do.cdsucursal = su.cdsucursal
                     AND su.cdregion = re.cdregion
                     AND do.idcuenta = cu.idcuenta
                     AND do.identidadreal = ee.identidad
                     AND cu.cdtipocuenta = '1'
                     AND ce.idestablecimientomaycar = em.idestablecimientomaycar--Modifico desde aca
                     AND em.cdtipo = ti.cdtipo-- Hago los joins
                     AND em.cdforma = p_cdforma
                     and ce.idcuenta=cu.idcuenta
                     AND em.cdsucursal = su.cdsucursal-- Hasta aca
                     AND (do.cdcomprobante LIKE ('FC%') OR
                         do.cdcomprobante LIKE ('NC%') OR
                         do.cdcomprobante LIKE ('ND%'))
                     AND do.cdsucursal = NVL(p_cdsucursal, do.cdsucursal)
                     AND do.identidadreal =
                         NVL(p_identidad, do.identidadreal)
                     AND cu.idcuenta = NVL(p_idcuenta, cu.idcuenta)
                     AND do.dtdocumento BETWEEN trunc(p_fechaDesde) AND
                         trunc(p_fechaHasta + 1)
                    /*        --busco solo datos de cuentas que tengan establecimientos
                     AND (select count(*) from tblestablecimiento es where es.idcuenta = cu.idcuenta) > 0*/
                  UNION ALL
                  --- compra cuenta 2
                  SELECT distinct re.dsregion region,
                         su.dssucursal sucursal,
                         ee.dsrazonsocial cliente,
                         ee.cdcuit,
                         cu1.nombrecuenta cuenta,
                         cu1.idcuenta,
                         0 amdocumentoCuit,
                         do.amdocumento amdocumentoCF,
                         0 amingreso,
                         em.cdforma,
                         EsBajaPBN(cu.idcuenta) baja,
                         GetCanal(ee.identidad, ee.cdmainsucursal) as Opcion_De_Venta, do.iddoctrx
                    FROM documentos do,
                         sucursales su,
                         tblregion  re,
                         tblcuenta  cu,
                         entidades  ee,
                         tblcuenta  cu1,
                          tblclientespecial         ce,--Agrego 3 tablas
                          tblestablecimientomaycar  em,
                          tbltipoingreso            ti
                   WHERE do.cdsucursal = su.cdsucursal
                     AND su.cdregion = re.cdregion
                     AND do.idcuenta = cu.idcuenta
                     AND do.identidadreal = ee.identidad
                     AND cu.cdtipocuenta = '2'
                     AND ce.idestablecimientomaycar = em.idestablecimientomaycar--Modifico desde aca
                     AND em.cdtipo = ti.cdtipo-- Hago los joins
                     AND em.cdforma = p_cdforma
                     and ce.idcuenta=cu.idcuenta
                     AND em.cdsucursal = su.cdsucursal-- Hasta aca
                     AND (do.cdcomprobante LIKE ('FC%') OR
                         do.cdcomprobante LIKE ('NC%') OR
                         do.cdcomprobante LIKE ('ND%'))
                     AND do.cdsucursal = NVL(p_cdsucursal, do.cdsucursal)
                     AND do.identidadreal =
                         NVL(p_identidad, do.identidadreal)
                     AND do.dtdocumento BETWEEN trunc(p_fechaDesde) AND
                         trunc(p_fechaHasta + 1)
                     AND cu.idpadre = cu1.idcuenta
                  /*    --busco solo datos de cuentas que tengan establecimientos
                     AND (select count(*) from tblestablecimiento es where es.idcuenta = cu1.idcuenta) > 0*/
                  --- acreditación
                  UNION ALL
                  SELECT distinct re.dsregion region,
                         su.dssucursal sucursal,
                         ee.dsrazonsocial cliente,
                         ee.cdcuit,
                         cu.nombrecuenta cuenta,
                         cu.idcuenta,
                         0 amdocumentoCuit,
                         0 amdocumentoCF,
                         ii.amingreso amingreso,
                         em.cdforma,
                         EsBajaPBN(cu.idcuenta) baja,
                         GetCanal(ee.identidad, ee.cdmainsucursal) as Opcion_De_Venta, ii.idingreso
                    FROM tblingreso     ii,
                         sucursales     su,
                         tblregion      re,
                         tblcuenta      cu,
                         entidades      ee,
                         tblconfingreso tci,
                          tblclientespecial         ce,--Agrego 3 tablas
                          tblestablecimientomaycar  em,
                          tbltipoingreso            ti
                   WHERE ii.cdsucursal = su.cdsucursal
                     AND ii.idcuenta = cu.idcuenta
                     AND cu.identidad = ee.identidad
                     AND su.cdregion = re.cdregion
                     AND ce.idestablecimientomaycar = em.idestablecimientomaycar--Modifico desde aca
                     AND em.cdtipo = ti.cdtipo-- Hago los joins
                      and tci.cdtipo=ti.cdtipo
                     AND em.cdforma = p_cdforma
                     and ce.idcuenta=cu.idcuenta
                     AND em.cdsucursal = su.cdsucursal-- Hasta aca
                     AND su.cdsucursal = NVL(p_cdsucursal, su.cdsucursal)
                     AND ee.identidad = NVL(p_identidad, ee.identidad)
                     AND cu.idcuenta = NVL(p_idcuenta, cu.idcuenta)
                     AND ii.dtingreso BETWEEN trunc(p_fechaDesde) AND
                         trunc(p_fechaHasta + 1)
                     AND tci.cdconfingreso = ii.cdconfingreso
                     AND tci.cdsucursal = ii.cdsucursal
                     and ii.cdestado <> '4' --No rechazado
                     AND (/*(tci.cdforma in (3, 4) and p_cdforma = 4) or*/
                         (tci.cdforma in (2/*, 3, 5*/) and ee.cdforma = 5)) --Agrego CE y Tercero. LM. 23.06.2017. solo se filtra por CE
                     and tci.cdaccion = 1 -- solo ingresos, no egresos
                     /*AND ee.cdforma = p_cdforma*/
                  union all
                  --- no tiene compra ni acreditación
                  SELECT distinct re.dsregion region,
                         su.dssucursal sucursal,
                         ee.dsrazonsocial cliente,
                         ee.cdcuit,
                         cu.nombrecuenta cuenta,
                         cu.idcuenta,
                         0 amdocumentoCuit,
                         0 amdocumentoCF,
                         0 amingreso,
                         em.cdforma,
                         EsBajaPBN(cu.idcuenta) baja,
                         GetCanal(ee.identidad, ee.cdmainsucursal) as Opcion_De_Venta, ''
                    FROM sucursales         su,
                         tblregion          re,
                         tblcuenta          cu,
                         entidades          ee,
                         tblestablecimiento es,
                          tblclientespecial         ce,--Agrego 3 tablas
                          tblestablecimientomaycar  em,
                          tbltipoingreso            ti
                   WHERE cu.cdsucursal = su.cdsucursal
                     AND cu.identidad = ee.identidad
                     AND su.cdsucursal = NVL(p_cdsucursal, su.cdsucursal)
                     AND ee.identidad = NVL(p_identidad, ee.identidad)
                     AND cu.idcuenta = NVL(p_idcuenta, cu.idcuenta)
                     AND su.cdregion = re.cdregion
                     and cu.idcuenta = es.idcuenta
                     AND ce.idestablecimientomaycar = em.idestablecimientomaycar--Modifico desde aca
                     AND em.cdtipo = ti.cdtipo-- Hago los joins
                     AND em.cdforma = p_cdforma
                     and ce.idcuenta=cu.idcuenta
                     AND em.cdsucursal = su.cdsucursal-- Hasta aca --agrego la forma mas alla que tenga o no establecimientos
                     AND not exists
                   (select 1
                            from tblfacturacionhistorica fa
                           where fa.idcuenta = cu.idcuenta
                             and fa.aniomes BETWEEN trunc(p_fechaDesde) AND
                                 last_day(trunc(p_fechaHasta)))
                     and not exists
                   (select 1
                            from tblingreso ii, tblconfingreso tci
                           where cu.idcuenta = ii.idcuenta
                             and ii.cdestado <> '4' --No rechazado
                             and ii.cdconfingreso = tci.cdconfingreso
                             and cu.cdsucursal = tci.cdsucursal
                             AND (/*(tci.cdforma in (3, 4) and p_cdforma = 4) or*/
                                 (tci.cdforma in (2/*, 3, 5*/) and ee.cdforma = 5)) --Agrego CE
                             and ii.dtingreso BETWEEN trunc(p_fechaDesde) AND
                                 trunc(p_fechaHasta + 1)
                             and tci.cdaccion = 1))
           GROUP BY region,
                    sucursal,
                    cliente,
                    cdcuit,
                    cuenta,
                    idcuenta,
                    decode(cdforma, 4, 'P.B.', 5, 'C.L.', 2,'CE'),
                    baja,
                    Opcion_De_Venta
           ORDER BY cliente;
        Else
        OPEN p_cur_out FOR
          SELECT region,
                 sucursal,
                 cliente,
                 cdcuit,
                 cuenta,
                 idcuenta,
                 trunc(SUM(amdocumentoCuit), 2) compraCuit,
                 trunc(SUM(amdocumentoCF), 2) compraCF,
                 trunc(SUM(amingreso), 2) acreditacion,
                 decode(cdforma, 4, 'P.B.', 5, 'C.L.',2,'CE') dsforma,
                 baja,
                 Opcion_De_Venta
          --Opcion_De_Venta
            FROM ( --- compra cuenta 1
                  SELECT re.dsregion region,
                          su.dssucursal sucursal,
                          ee.dsrazonsocial cliente,
                          ee.cdcuit,
                          cu.nombrecuenta cuenta,
                          cu.idcuenta,
                          do.amdocumento amdocumentoCuit,
                          0 amdocumentoCF,
                          0 amingreso,
                          ee.cdforma,
                          EsBajaPBN(cu.idcuenta) baja,
                          GetCanal(ee.identidad, ee.cdmainsucursal) as Opcion_De_Venta
                    FROM documentos do,
                          sucursales su,
                          tblregion  re,
                          tblcuenta  cu,
                          entidades  ee
                   WHERE do.cdsucursal = su.cdsucursal
                     AND su.cdregion = re.cdregion
                     AND do.idcuenta = cu.idcuenta
                     AND do.identidadreal = ee.identidad
                     AND cu.cdtipocuenta = '1'
                     AND ee.cdforma = p_cdforma
                     AND (do.cdcomprobante LIKE ('FC%') OR
                         do.cdcomprobante LIKE ('NC%') OR
                         do.cdcomprobante LIKE ('ND%'))
                     AND do.cdsucursal = NVL(p_cdsucursal, do.cdsucursal)
                     AND do.identidadreal =
                         NVL(p_identidad, do.identidadreal)
                     AND cu.idcuenta = NVL(p_idcuenta, cu.idcuenta)
                     AND do.dtdocumento BETWEEN trunc(p_fechaDesde) AND
                         trunc(p_fechaHasta + 1)
                    /*        --busco solo datos de cuentas que tengan establecimientos -- APW 10/08/2017
                     AND (select count(*) from tblestablecimiento es where es.idcuenta = cu.idcuenta) > 0*/
                  UNION ALL
                  --- compra cuenta 2
                  SELECT re.dsregion region,
                         su.dssucursal sucursal,
                         ee.dsrazonsocial cliente,
                         ee.cdcuit,
                         cu1.nombrecuenta cuenta,
                         cu1.idcuenta,
                         0 amdocumentoCuit,
                         do.amdocumento amdocumentoCF,
                         0 amingreso,
                         ee.cdforma,
                         EsBajaPBN(cu.idcuenta) baja,
                         GetCanal(ee.identidad, ee.cdmainsucursal) as Opcion_De_Venta
                    FROM documentos do,
                         sucursales su,
                         tblregion  re,
                         tblcuenta  cu,
                         entidades  ee,
                         tblcuenta  cu1
                   WHERE do.cdsucursal = su.cdsucursal
                     AND su.cdregion = re.cdregion
                     AND do.idcuenta = cu.idcuenta
                     AND do.identidadreal = ee.identidad
                     AND cu.cdtipocuenta = '2'
                     AND ee.cdforma = p_cdforma
                     AND (do.cdcomprobante LIKE ('FC%') OR
                         do.cdcomprobante LIKE ('NC%') OR
                         do.cdcomprobante LIKE ('ND%'))
                     AND do.cdsucursal = NVL(p_cdsucursal, do.cdsucursal)
                     AND do.identidadreal =
                         NVL(p_identidad, do.identidadreal)
                     AND do.dtdocumento BETWEEN trunc(p_fechaDesde) AND
                         trunc(p_fechaHasta + 1)
                     AND cu.idpadre = cu1.idcuenta
                     /* --busco solo datos de cuentas que tengan establecimientos  -- APW 10/08/2017
                     AND (select count(*) from tblestablecimiento es where es.idcuenta = cu1.idcuenta) > 0*/
                  --- acreditación
                  UNION ALL
                  SELECT re.dsregion region,
                         su.dssucursal sucursal,
                         ee.dsrazonsocial cliente,
                         ee.cdcuit,
                         cu.nombrecuenta cuenta,
                         cu.idcuenta,
                         0 amdocumentoCuit,
                         0 amdocumentoCF,
                         ii.amingreso amingreso,
                         ee.cdforma,
                         EsBajaPBN(cu.idcuenta) baja,
                         GetCanal(ee.identidad, ee.cdmainsucursal) as Opcion_De_Venta
                    FROM tblingreso     ii,
                         sucursales     su,
                         tblregion      re,
                         tblcuenta      cu,
                         entidades      ee,
                         tblconfingreso tci
                   WHERE ii.cdsucursal = su.cdsucursal
                     AND ii.idcuenta = cu.idcuenta
                     AND cu.identidad = ee.identidad
                     AND su.cdregion = re.cdregion
                     AND ee.cdforma = p_cdforma
                     and ii.cdestado <> '4' --No rechazado
                     AND su.cdsucursal = NVL(p_cdsucursal, su.cdsucursal)
                     AND ee.identidad = NVL(p_identidad, ee.identidad)
                     AND cu.idcuenta = NVL(p_idcuenta, cu.idcuenta)
                     AND ii.dtingreso BETWEEN trunc(p_fechaDesde) AND
                         trunc(p_fechaHasta + 1)
                     AND tci.cdconfingreso = ii.cdconfingreso
                     AND tci.cdsucursal = ii.cdsucursal
                     AND ((tci.cdforma in (3, 4) and p_cdforma = 4) or
                         (tci.cdforma in (/*2,*/ 3, 5) and p_cdforma = 5)) --Agrego CE y Tercero. LM. 23.06.2017. que no devuelva CE
                     and tci.cdaccion = 1 -- solo ingresos, no egresos
                     AND ee.cdforma = p_cdforma
                  union all
                  --- no tiene compra ni acreditación tblestablecimiento
                  SELECT re.dsregion region,
                         su.dssucursal sucursal,
                         ee.dsrazonsocial cliente,
                         ee.cdcuit,
                         cu.nombrecuenta cuenta,
                         cu.idcuenta,
                         0 amdocumentoCuit,
                         0 amdocumentoCF,
                         0 amingreso,
                         ee.cdforma,
                         EsBajaPBN(cu.idcuenta) baja,
                         GetCanal(ee.identidad, ee.cdmainsucursal) as Opcion_De_Venta
                    FROM sucursales         su,
                         tblregion          re,
                         tblcuenta          cu,
                         entidades          ee,
                         tblestablecimiento es
                   WHERE cu.cdsucursal = su.cdsucursal
                     AND cu.identidad = ee.identidad
                     AND su.cdsucursal = NVL(p_cdsucursal, su.cdsucursal)
                     AND ee.identidad = NVL(p_identidad, ee.identidad)
                     AND cu.idcuenta = NVL(p_idcuenta, cu.idcuenta)
                     AND su.cdregion = re.cdregion
                     and cu.idcuenta = es.idcuenta
                     AND ee.cdforma = p_cdforma --agrego la forma mas alla que tenga o no establecimientos
                     AND not exists
                   (select 1
                            from tblfacturacionhistorica fa
                           where fa.idcuenta = cu.idcuenta
                             and fa.aniomes BETWEEN trunc(p_fechaDesde) AND
                                 last_day(trunc(p_fechaHasta)))
                     and not exists
                   (select 1
                            from tblingreso ii, tblconfingreso tci
                           where cu.idcuenta = ii.idcuenta
                             and ii.cdestado <> '4' --No rechazado
                             and ii.cdconfingreso = tci.cdconfingreso
                             and cu.cdsucursal = tci.cdsucursal
                             AND ((tci.cdforma in (3, 4) and p_cdforma = 4) or
                                 (tci.cdforma in (/*2,*/ 3, 5) and p_cdforma = 5)) --Agrego CE y Tercero. LM. 23.06.2017. que no devuelva CE
                             and ii.dtingreso BETWEEN trunc(p_fechaDesde) AND
                                 trunc(p_fechaHasta + 1)
                             and tci.cdaccion = 1)
                             )
           GROUP BY region,
                    sucursal,
                    cliente,
                    cdcuit,
                    cuenta,
                    idcuenta,
                    decode(cdforma, 4, 'P.B.', 5, 'C.L.',2,'CE'),
                    baja,
                    Opcion_De_Venta
           ORDER BY cliente;
      End If;
      else
        --Todos

        OPEN p_cur_out FOR
          SELECT region,
                 sucursal,
                 cliente,
                 cdcuit,
                 cuenta,
                 idcuenta,
                 trunc(SUM(amdocumentoCuit), 2) compraCuit,
                 trunc(SUM(amdocumentoCF), 2) compraCF,
                 trunc(SUM(amingreso), 2) acreditacion,
                 decode(cdforma, 4, 'P.B.', 5, 'C.L.') dsforma,
                 baja,
                 Opcion_De_Venta
          --Opcion_De_Venta
            FROM ( --compra con cuenta 1
                  SELECT re.dsregion region,
                          su.dssucursal sucursal,
                          ee.dsrazonsocial cliente,
                          ee.cdcuit,
                          cu.nombrecuenta cuenta,
                          cu.idcuenta,
                          do.amdocumento amdocumentoCuit,
                          0 amdocumentoCF,
                          0 amingreso,
                          ee.cdforma,
                          EsBajaPBN(cu.idcuenta) baja,
                          GetCanal(ee.identidad, ee.cdmainsucursal) as Opcion_De_Venta
                    FROM documentos do,
                          sucursales su,
                          tblregion  re,
                          tblcuenta  cu,
                          entidades  ee
                   WHERE do.cdsucursal = su.cdsucursal
                     AND su.cdregion = re.cdregion
                     AND do.idcuenta = cu.idcuenta
                     AND do.identidadreal = ee.identidad
                     AND cu.cdtipocuenta = '1'
                     AND ee.cdforma in (4, 5) --PB y CL
                     AND (do.cdcomprobante LIKE ('FC%') OR
                         do.cdcomprobante LIKE ('NC%') OR
                         do.cdcomprobante LIKE ('ND%'))
                     AND do.cdsucursal = NVL(p_cdsucursal, do.cdsucursal)
                     AND do.identidadreal =
                         NVL(p_identidad, do.identidadreal)
                     AND cu.idcuenta = NVL(p_idcuenta, cu.idcuenta)
                     AND do.dtdocumento BETWEEN trunc(p_fechaDesde) AND
                         trunc(p_fechaHasta + 1)
                 /*        --busco solo datos de cuentas que tengan establecimientos -- APW 10/08/2017
                     AND (select count(*) from tblestablecimiento es where es.idcuenta = cu.idcuenta) > 0*/
                  UNION ALL
                  --compra cuenta 2
                  SELECT re.dsregion region,
                         su.dssucursal sucursal,
                         ee.dsrazonsocial cliente,
                         ee.cdcuit,
                         cu1.nombrecuenta cuenta,
                         cu1.idcuenta,
                         0 amdocumentoCuit,
                         do.amdocumento amdocumentoCF,
                         0 amingreso,
                         ee.cdforma,
                         EsBajaPBN(cu.idcuenta) baja,
                         GetCanal(ee.identidad, ee.cdmainsucursal) as Opcion_De_Venta
                    FROM documentos do,
                         sucursales su,
                         tblregion  re,
                         tblcuenta  cu,
                         entidades  ee,
                         tblcuenta  cu1
                   WHERE do.cdsucursal = su.cdsucursal
                     AND su.cdregion = re.cdregion
                     AND do.idcuenta = cu.idcuenta
                     AND do.identidadreal = ee.identidad
                     AND cu.cdtipocuenta = '2'
                     AND ee.cdforma in (4, 5) --PB y CL
                     AND (do.cdcomprobante LIKE ('FC%') OR
                         do.cdcomprobante LIKE ('NC%') OR
                         do.cdcomprobante LIKE ('ND%'))
                     AND do.cdsucursal = NVL(p_cdsucursal, do.cdsucursal)
                     AND do.identidadreal =
                         NVL(p_identidad, do.identidadreal)
                     AND do.dtdocumento BETWEEN trunc(p_fechaDesde) AND
                         trunc(p_fechaHasta + 1)
                     AND cu.idpadre = cu1.idcuenta --Busco los datos pero muestro los datos de la cuenta padre
                     /*  --busco solo datos de cuentas que tengan establecimintos -- APW 10/08/2017
                     AND (select count(*) from tblestablecimiento es where es.idcuenta = cu1.idcuenta) > 0*/
                  UNION ALL
                  --acreditaciones
                  SELECT re.dsregion region,
                         su.dssucursal sucursal,
                         ee.dsrazonsocial cliente,
                         ee.cdcuit,
                         cu.nombrecuenta cuenta,
                         cu.idcuenta,
                         0 amdocumentoCuit,
                         0 amdocumentoCF,
                         ii.amingreso amingreso,
                         ee.cdforma,
                         EsBajaPBN(cu.idcuenta) baja,
                         GetCanal(ee.identidad, ee.cdmainsucursal) as Opcion_De_Venta
                    FROM tblingreso     ii,
                         sucursales     su,
                         tblregion      re,
                         tblcuenta      cu,
                         entidades      ee,
                         tblconfingreso tci
                   WHERE ii.cdsucursal = su.cdsucursal
                     AND ii.idcuenta = cu.idcuenta
                     AND cu.identidad = ee.identidad
                     and ii.cdestado <> '4' --No rechazado
                     AND su.cdsucursal = NVL(p_cdsucursal, su.cdsucursal)
                     AND ee.identidad = NVL(p_identidad, ee.identidad)
                     AND cu.idcuenta = NVL(p_idcuenta, cu.idcuenta)
                     AND ii.dtingreso BETWEEN trunc(p_fechaDesde) AND
                         trunc(p_fechaHasta + 1)
                     AND tci.cdconfingreso = ii.cdconfingreso
                     AND tci.cdsucursal = ii.cdsucursal
                     AND tci.cdforma in (2, 3, 4, 5) --PB y CL --LF:Agrego CE y Tercero
                     AND su.cdregion = re.cdregion
                     and tci.cdaccion = 1 -- solo ingresos, no egresos
                     AND ee.cdforma in (4, 5) --PB y CL - Busco que tenga forma aunque tengas acreditciones
                  union all
                  --- no tiene compra ni acreditación clientes de tblestablecimiento
                  SELECT re.dsregion region,
                         su.dssucursal sucursal,
                         ee.dsrazonsocial cliente,
                         ee.cdcuit,
                         cu.nombrecuenta cuenta,
                         cu.idcuenta,
                         0 amdocumentoCuit,
                         0 amdocumentoCF,
                         0 amingreso,
                         ee.cdforma,
                         EsBajaPBN(cu.idcuenta) baja,
                         GetCanal(ee.identidad, ee.cdmainsucursal) as Opcion_De_Venta
                    FROM sucursales         su,
                         tblregion          re,
                         tblcuenta          cu,
                         entidades          ee,
                         tblestablecimiento es
                   WHERE cu.cdsucursal = su.cdsucursal
                     AND cu.identidad = ee.identidad
                     AND su.cdsucursal = NVL(p_cdsucursal, su.cdsucursal)
                     AND ee.identidad = NVL(p_identidad, ee.identidad)
                     AND cu.idcuenta = NVL(p_idcuenta, cu.idcuenta)
                     AND su.cdregion = re.cdregion
                     and cu.idcuenta = es.idcuenta
                     AND ee.cdforma in (4, 5) --PB y CL
                     AND not exists
                   (select 1
                            from tblfacturacionhistorica fa
                           where fa.idcuenta = cu.idcuenta
                             and fa.aniomes BETWEEN trunc(p_fechaDesde) AND
                                 last_day(trunc(p_fechaHasta)))
                     and not exists
                   (select 1
                            from tblingreso ii, tblconfingreso tci
                           where cu.idcuenta = ii.idcuenta
                             and ii.cdestado <> '4' --No rechazado
                             and ii.cdconfingreso = tci.cdconfingreso
                             and cu.cdsucursal = tci.cdsucursal
                             AND tci.cdforma in (2, 3, 4, 5) -- todos
                             and ii.dtingreso BETWEEN trunc(p_fechaDesde) AND
                                 trunc(p_fechaHasta + 1)
                             and tci.cdaccion = 1)
                     union all
                  --- no tiene compra ni acreditación, clientes de tblclientespecial
                  SELECT re.dsregion region,
                         su.dssucursal sucursal,
                         ee.dsrazonsocial cliente,
                         ee.cdcuit,
                         cu.nombrecuenta cuenta,
                         cu.idcuenta,
                         0 amdocumentoCuit,
                         0 amdocumentoCF,
                         0 amingreso,
                         ee.cdforma,
                         EsBajaPBN(cu.idcuenta) baja,
                         GetCanal(ee.identidad, ee.cdmainsucursal) as Opcion_De_Venta
                    FROM sucursales         su,
                         tblregion          re,
                         tblcuenta          cu,
                         entidades          ee,
                         tblclientespecial  es
                   WHERE cu.cdsucursal = su.cdsucursal
                     AND cu.identidad = ee.identidad
                     AND su.cdsucursal = NVL(p_cdsucursal, su.cdsucursal)
                     AND ee.identidad = NVL(p_identidad, ee.identidad)
                     AND cu.idcuenta = NVL(p_idcuenta, cu.idcuenta)
                     AND su.cdregion = re.cdregion
                     and cu.idcuenta = es.idcuenta
                     AND ee.cdforma in (4, 5) --PB y CL
                     AND not exists
                   (select 1
                            from tblfacturacionhistorica fa
                           where fa.idcuenta = cu.idcuenta
                             and fa.aniomes BETWEEN trunc(p_fechaDesde) AND
                                 last_day(trunc(p_fechaHasta)))
                     and not exists
                   (select 1
                            from tblingreso ii, tblconfingreso tci
                           where cu.idcuenta = ii.idcuenta
                             and ii.cdestado <> '4' --No rechazado
                             and ii.cdconfingreso = tci.cdconfingreso
                             and cu.cdsucursal = tci.cdsucursal
                             AND tci.cdforma in (2, 3, 4, 5) -- todos
                             and ii.dtingreso BETWEEN trunc(p_fechaDesde) AND
                                 trunc(p_fechaHasta + 1)
                             and tci.cdaccion = 1)
                             )
           GROUP BY region,
                    sucursal,
                    cliente,
                    cdcuit,
                    cuenta,
                    idcuenta,
                    decode(cdforma, 4, 'P.B.', 5, 'C.L.'),
                    baja,
                    Opcion_De_Venta
           ORDER BY cliente;
      end if;

    EXCEPTION
      WHEN OTHERS THEN
        n_pkg_vitalpos_log_general.write(2,
                                         'Modulo: ' || v_Modulo ||
                                         ' Error: ' || SQLERRM);
        RAISE;
    END GetAcreditacionPosnetDetalle;

  /*****************************************************************************************************************
   * Retorna un reporte de diferencias de caja agrupado por region y sucursal
   * %v 30/06/2014 - MatiasG: v1.0
   ******************************************************************************************************************/
   PROCEDURE GetDiferenciaDeCajasGeneral(p_sucursales IN VARCHAR2,
                                         p_idpersona  IN tbltesoro.idpersona%TYPE,
                                         p_fechaDesde IN DATE,
                                         p_fechaHasta IN DATE,
                                         p_cur_out    OUT cursor_type) IS
      v_Modulo    VARCHAR2(100) := 'PKG_REPORTE_CENTRAL.GetDiferenciaDeCajasGeneral';
      v_idReporte VARCHAR2(40) := '';
   BEGIN
      v_idReporte := SetSucursalesSeleccionadas(p_sucursales);

      OPEN p_cur_out FOR
         SELECT re.cdregion,
             re.dsregion,
           su.cdsucursal,
                su.dssucursal,
                trunc(SUM(DECODE(SIGN(dc.amdiferenciacaja), -1, 0, 1, dc.amdiferenciacaja, dc.amdiferenciacaja)),2) sobrante,
                trunc(SUM(DECODE(SIGN(dc.amdiferenciacaja), 1, 0, -1, dc.amdiferenciacaja, dc.amdiferenciacaja)),2) faltante
           FROM tbldiferenciacaja dc, sucursales su, tblregion re, personas pe, tbltmp_sucursales_reporte rs
          WHERE dc.idpersonaresponsable = pe.idpersona
            AND dc.cdsucursal = su.cdsucursal
            AND su.cdregion = re.cdregion
        AND rs.idreporte = v_idReporte
        AND rs.cdsucursal = su.cdsucursal
        AND dc.idpersonaresponsable = NVL(p_idpersona,dc.idpersonaresponsable)
            AND dc.dtcierrecaja BETWEEN trunc(p_fechaDesde) AND trunc(p_fechaHasta + 1)
          GROUP BY re.cdregion,re.dsregion,su.cdsucursal, su.dssucursal;

      CleanSucursalesSeleccionadas(v_idReporte);
   EXCEPTION
      WHEN OTHERS THEN
         n_pkg_vitalpos_log_general.write(2, 'Modulo: ' || v_Modulo || ' Error: ' || SQLERRM);
         RAISE;
   END GetDiferenciaDeCajasGeneral;

   /*****************************************************************************************************************
   * Retorna un reporte del detalle de diferencias de caja
   * %v 30/06/2014 - MatiasG: v1.0
   ******************************************************************************************************************/
   PROCEDURE GetDiferenciaDeCajasDetalle(p_cdsucursal IN sucursales.cdsucursal%TYPE,
                                         p_idpersona  IN tbltesoro.idpersona%TYPE,
                                         p_fechaDesde IN DATE,
                                         p_fechaHasta IN DATE,
                                         p_cur_out    OUT cursor_type) IS
      v_Modulo VARCHAR2(100) := 'PKG_REPORTE_CENTRAL.GetDiferenciaDeCajasDetalle';
   BEGIN

      OPEN p_cur_out FOR
         SELECT re.dsregion,
                su.dssucursal,
                pe.dsnombre || ' ' || pe.dsapellido AS responsable,
                dc.dtcierrecaja,
                dc.amdiferenciacaja,
                dc.dsingreso
           FROM tbldiferenciacaja dc, sucursales su, tblregion re, personas pe
          WHERE dc.idpersonaresponsable = pe.idpersona
            AND dc.cdsucursal = su.cdsucursal
            AND su.cdregion = re.cdregion
            AND dc.cdsucursal = NVL(p_cdsucursal, dc.cdsucursal)
            AND dc.idpersonaresponsable = NVL(p_idpersona, dc.idpersonaresponsable)
            AND dc.dtcierrecaja BETWEEN trunc(p_fechaDesde) AND trunc(p_fechaHasta + 1);

   EXCEPTION
      WHEN OTHERS THEN
         n_pkg_vitalpos_log_general.write(2, 'Modulo: ' || v_Modulo || ' Error: ' || SQLERRM);
         RAISE;
   END GetDiferenciaDeCajasDetalle;


  /*****************************************************************************************************************
   * Retorna un reporte de facturas pendientes agrupado por region y sucursal
   * %v 30/06/2014 - MatiasG: v1.0
   ******************************************************************************************************************/
   PROCEDURE GetFacturasPendientesGeneral(p_sucursales IN VARCHAR2,
                                          p_identidad  IN entidades.identidad%TYPE,
                                          p_idcuenta   IN tblcuenta.idcuenta%TYPE,
                                          p_cur_men7   OUT cursor_type,
                                          p_cur_may7   OUT cursor_type) IS
      v_Modulo    VARCHAR2(100) := 'PKG_REPORTE_CENTRAL.GetFacturasPendientesGeneral';
      v_idReporte VARCHAR2(40) := '';
   BEGIN
      v_idReporte := SetSucursalesSeleccionadas(p_sucursales);

           OPEN p_cur_may7 FOR
         SELECT re.cdregion,
                re.dsregion,
                su.cdsucursal,
                su.dssucursal,
                COUNT(1) cantidad,
                trunc(SUM(do.amdocumento),2) importe
           FROM documentos do,
                movmateriales mm,
                sucursales su,
                tblregion re,
                tbltmp_sucursales_reporte rs
          WHERE do.idmovmateriales = mm.idmovmateriales
            AND do.cdsucursal = su.cdsucursal
            AND su.cdregion = re.cdregion
            AND (do.cdcomprobante LIKE ('FC%') OR
                 do.cdcomprobante LIKE ('NC%') OR
                 do.cdcomprobante LIKE ('ND%'))
            AND mm.id_canal IS NOT NULL
            AND do.dtdocumento BETWEEN TRUNC(SYSDATE - 30)
                                   AND TRUNC(SYSDATE -7)
            AND rs.idreporte = v_idReporte
            AND rs.cdsucursal = su.cdsucursal
            AND do.identidad = NVL(p_identidad,do.identidad)
            AND do.idcuenta = NVL(p_idcuenta,do.idcuenta)
            AND NOT EXISTS (SELECT 1
                              FROM tblmovcuenta mc
                             WHERE mc.iddoctrx = do.iddoctrx)
       GROUP BY re.cdregion,
                re.dsregion,
                su.cdsucursal,
                su.dssucursal;

           OPEN p_cur_men7 FOR
         SELECT re.cdregion,
                re.dsregion,
                su.cdsucursal,
                su.dssucursal,
                COUNT(1) cantidad,
                trunc(SUM(do.amdocumento),2) importe
           FROM documentos do,
                movmateriales mm,
                sucursales su,
                tblregion re,
                tbltmp_sucursales_reporte rs
          WHERE do.idmovmateriales = mm.idmovmateriales
            AND do.cdsucursal = su.cdsucursal
            AND su.cdregion = re.cdregion
            AND (do.cdcomprobante LIKE ('FC%') OR
                 do.cdcomprobante LIKE ('NC%') OR
                 do.cdcomprobante LIKE ('ND%'))
            AND do.dtdocumento BETWEEN TRUNC(SYSDATE - 7)
                                   AND TRUNC(SYSDATE + 1)
            AND mm.id_canal IS NOT NULL
            AND rs.idreporte = v_idReporte
            AND rs.cdsucursal = su.cdsucursal
            AND do.identidad = NVL(p_identidad,do.identidad)
            AND do.idcuenta = NVL(p_idcuenta,do.idcuenta)
        AND NOT EXISTS (SELECT 1
                          FROM tblmovcuenta mc
                         WHERE mc.iddoctrx = do.iddoctrx)
       GROUP BY re.cdregion,
                re.dsregion,
                su.cdsucursal,
                su.dssucursal;

      CleanSucursalesSeleccionadas(v_idReporte);
   EXCEPTION
      WHEN OTHERS THEN
         n_pkg_vitalpos_log_general.write(2, 'Modulo: ' || v_Modulo || ' Error: ' || SQLERRM);
         RAISE;
   END GetFacturasPendientesGeneral;

   /*****************************************************************************************************************
   * Retorna un reporte del detalle de facturas pendientes
   * %v 30/06/2014 - MatiasG: v1.0
   * %v 16/01/2015 - MartinM: v1.1 Cambio el rango de fecha porque hay un período que no se considera (SYSDATE - 7 y SYSDATE - 8)
                                   Dejo el between porque no hay posibilidad que se genere una venta sino tendría que usar los operadores < <= > y >=
   ******************************************************************************************************************/
    PROCEDURE GetFacturasPendientesDetalle(p_cdsucursal IN sucursales.cdsucursal%TYPE,
                                           p_cur_men7   OUT cursor_type,
                                           p_cur_may7   OUT cursor_type) IS
       v_Modulo VARCHAR2(100) := 'PKG_REPORTE_CENTRAL.GetFacturasPendientesDetalle';
    BEGIN
       OPEN p_cur_may7 FOR
          SELECT mm.id_canal cdcanal,
                 ca.nombre dscanal,
                 re.cdregion,
                 re.dsregion,
                 su.dssucursal,
                 su.cdsucursal,
                 COUNT(1) cantidad,
                 trunc(SUM(do.amdocumento),2) importe
            FROM documentos do,
                 movmateriales mm,
                 sucursales su,
                 tblregion re,
                 tblcanal ca
           WHERE do.idmovmateriales = mm.idmovmateriales
             AND do.cdsucursal = su.cdsucursal
             AND su.cdregion = re.cdregion
             AND mm.id_canal = ca.id_canal
             AND (do.cdcomprobante LIKE ('FC%') OR
                  do.cdcomprobante LIKE ('NC%') OR
                  do.cdcomprobante LIKE ('ND%'))
             AND mm.id_canal IS NOT NULL
             AND do.dtdocumento BETWEEN TRUNC(SYSDATE - 30) AND trunc(SYSDATE - 7) --MM 16/01/2015 Cambio el sysdate - 8 por SYSDATE - 7
             AND do.cdsucursal = NVL(p_cdsucursal, do.cdsucursal)
         AND NOT EXISTS (SELECT 1
                            FROM tblmovcuenta mc
                          WHERE mc.iddoctrx = do.iddoctrx)
           GROUP BY mm.id_canal,ca.nombre,re.cdregion,re.dsregion,su.dssucursal, su.cdsucursal;

       OPEN p_cur_men7 FOR
          SELECT mm.id_canal cdcanal,
                 ca.nombre dscanal,
                 re.cdregion,
                 re.dsregion,
                 su.dssucursal,
                 su.cdsucursal,
                 COUNT(1) cantidad,
                 trunc(SUM(do.amdocumento),2) importe
            FROM documentos do,
                 movmateriales mm,
                 sucursales su,
                 tblregion re,
                 tblcanal ca
           WHERE do.idmovmateriales = mm.idmovmateriales
             AND do.cdsucursal = su.cdsucursal
             AND su.cdregion = re.cdregion
             AND mm.id_canal = ca.id_canal
             AND (do.cdcomprobante LIKE ('FC%') OR
                  do.cdcomprobante LIKE ('NC%') OR
                  do.cdcomprobante LIKE ('ND%'))
             AND do.dtdocumento BETWEEN TRUNC(SYSDATE - 7)
                                    AND TRUNC(SYSDATE + 1)
             AND mm.id_canal IS NOT NULL
             AND do.cdsucursal = NVL(p_cdsucursal, do.cdsucursal)
         AND NOT EXISTS (SELECT 1
                           FROM tblmovcuenta mc
                          WHERE mc.iddoctrx = do.iddoctrx)
        GROUP BY mm.id_canal,
                 ca.nombre,
                 re.cdregion,
                 re.dsregion,
                 su.dssucursal,
                 su.cdsucursal;

    EXCEPTION
       WHEN OTHERS THEN
          n_pkg_vitalpos_log_general.write(2, 'Modulo: ' || v_Modulo || ' Error: ' || SQLERRM);
          RAISE;
    END GetFacturasPendientesDetalle;

   /*****************************************************************************************************************
   * Retorna un reporte del detalle de facturas pendientes una a una
   * %v 06/08/2014 - MatiasG: v1.0
   ******************************************************************************************************************/
   PROCEDURE GetFacturasPendientesPopup(p_idCanal    IN movmateriales.id_canal%TYPE,
                                        p_cdSucursal IN sucursales.cdsucursal%TYPE,
                                        p_cur_out    OUT cursor_type) IS
      v_Modulo VARCHAR2(100) := 'PKG_REPORTE_CENTRAL.GetFacturasPendientesPopup';
   BEGIN
      OPEN p_cur_out FOR
         SELECT ee.cdcuit,
                ee.dsrazonsocial,
                cu.nombrecuenta,
                do.dtdocumento,
                do.amdocumento,
                GetDescDocumento(do.iddoctrx) dsdocumento
           FROM documentos do,
                entidades ee,
                tblcuenta cu,
                movmateriales mm
          WHERE do.identidadreal = ee.identidad
            AND do.idcuenta = cu.idcuenta
            AND do.idmovmateriales = mm.idmovmateriales
            AND (do.cdcomprobante LIKE ('FC%') OR
                 do.cdcomprobante LIKE ('NC%') OR
                 do.cdcomprobante LIKE ('ND%'))
            AND do.dtdocumento BETWEEN trunc(SYSDATE - 30)
                                   AND trunc(SYSDATE + 1)
            AND do.cdsucursal = p_cdsucursal
            AND mm.id_canal = p_idCanal
            AND NOT EXISTS (SELECT 1
                               FROM tblmovcuenta mc
                             WHERE mc.iddoctrx = do.iddoctrx)
       ORDER BY do.dtdocumento;

   EXCEPTION
      WHEN OTHERS THEN
         n_pkg_vitalpos_log_general.write(2, 'Modulo: ' || v_Modulo || ' Error: ' || SQLERRM);
         RAISE;
   END GetFacturasPendientesPopup;

   /*****************************************************************************************************************
   * Retorna un reporte del detalle de facturas pendientes una a una
   * %v 25/01/2016 - LucianoF: v1.0
   * %v 26/01/2017 - APW: La fecha del parámetro compara también con la fecha de transaccionada (para que sean PENDIENTES AL...)
   ******************************************************************************************************************/
   PROCEDURE GetFacturasPendientesListado(p_cdSucursal IN sucursales.cdsucursal%TYPE,
                                          p_fecha in documentos.dtdocumento%TYPE,
                                        p_cur_out    OUT cursor_type) IS
      v_Modulo VARCHAR2(100) := 'PKG_REPORTE_CENTRAL.GetFacturasPendientesListado';
      v_idReporte VARCHAR2(100) := '';
   BEGIN
      v_idReporte := SetSucursalesSeleccionadas(p_cdSucursal);

      OPEN p_cur_out FOR
          SELECT    s.dssucursal,
            mm.id_canal,
              ee.cdcuit,
                ee.dsrazonsocial,
                cu.nombrecuenta,
                do.dtdocumento,
                do.amdocumento,
                pkg_core_documento.GetDescDocumento(do.iddoctrx) dsdocumento
           FROM documentos do,
                entidades ee,
                tblcuenta cu,
                movmateriales mm,
                sucursales s,
                tbltmp_sucursales_reporte rs
          WHERE do.identidadreal = ee.identidad
            AND do.idcuenta = cu.idcuenta
            AND do.idmovmateriales = mm.idmovmateriales
            AND do.cdsucursal = s.cdsucursal
            AND rs.cdsucursal = s.cdsucursal
            AND rs.idreporte = v_idReporte
            AND (do.cdcomprobante LIKE ('FC%') OR
                 do.cdcomprobante LIKE ('NC%') OR
                 do.cdcomprobante LIKE ('ND%'))
            AND do.dtdocumento BETWEEN trunc(SYSDATE - 60)
                                   AND trunc(p_fecha)
            --AND do.cdsucursal IN (p_cdSucursal)
            AND NOT EXISTS (SELECT 1
                               FROM tblmovcuenta mc
                             WHERE mc.iddoctrx = do.iddoctrx
                               AND mc.dtmovimiento < p_fecha)
       ORDER BY s.dssucursal, mm.id_canal ,do.dtdocumento;
       CleanSucursalesSeleccionadas(v_idReporte);
   EXCEPTION
      WHEN OTHERS THEN
         n_pkg_vitalpos_log_general.write(2, 'Modulo: ' || v_Modulo || ' Error: ' || SQLERRM);
         RAISE;
   END GetFacturasPendientesListado;

   /*****************************************************************************************************************
   * Retorna un cursor con el detalle de facturas con deuda y de egresos sin aplicar
   * %v 31/03/2015 - Jbodnar: v1.0
   * %v 23/04/2015 - MartinM: v1.1 -- Agrego el filtro p_periodo en el query para filtrado
   * %v 23/04/2015 - MartinM: v1.2 -- Se saco la tabla tbldocumentodeuda fuera del join para que no de producto cartesiano
   * %v 23/06/2016 - LucianoF: v1.3 - Agrego cuentas de CF y quito canal CO
   ******************************************************************************************************************/
   PROCEDURE GetAgingPopup(p_idcuenta   IN tblcuenta.idcuenta%TYPE,
                           p_periodo    IN varchar2,
                           p_cur_out    OUT cursor_type) IS

      v_Modulo VARCHAR2(100) := 'PKG_REPORTE_CENTRAL.GetAgingPopup';

   BEGIN

      OPEN p_cur_out FOR
    SELECT *
      FROM ( SELECT distinct do.dtdocumento,
                    PKG_REPORTE_CENTRAL.GetDescDocumento(do.iddoctrx) dsaging,
                    do.amdocumento importe,
                    trunc( SUM( getSaldoFactura( do.iddoctrx ) ), 2 ) saldo
               FROM entidades ee,
                    sucursales su,
                    documentos do,
                    tblcuenta cu,
                    tblregion re,
                    tbldocumentodeuda dd,
                    movmateriales mm
              WHERE do.cdsucursal   = su.cdsucursal
                AND su.cdregion     = re.cdregion
                AND do.idcuenta     = cu.idcuenta
                AND ee.identidad    = cu.identidad
                --AND cu.cdtipocuenta = '1'
                AND do.idmovmateriales = mm.idmovmateriales
                AND mm.id_canal in ('SA','VE','TE')
                AND dd.iddoctrx = do.iddoctrx
                and dd.cdestado not in (3,5) --Judicial e Incobrable
                AND dd.dtestadofin is null
                AND ( do.cdcomprobante LIKE ( 'FC%' ) OR
                      do.cdcomprobante LIKE ( 'NC%' ) OR
                      do.cdcomprobante LIKE ( 'ND%' ) )
                AND do.cdsucursal   = pkg_cuenta_central.GetSucursalCuenta( p_idcuenta )
                AND ( do.idcuenta   = p_idcuenta or p_idcuenta is null )
                AND do.cdestadocomprobante IN ( '1','2','4' )
                AND ( ( p_periodo = '0-7'    and dd.dtestadoinicio >= trunc(sysdate) - 7) or
                      ( p_periodo = '8-14'   and dd.dtestadoinicio >= trunc(sysdate) - 14  and dd.dtestadoinicio < trunc(sysdate) - 7  ) or
                      ( p_periodo = '15-30'  and dd.dtestadoinicio >= trunc(sysdate) - 30  and dd.dtestadoinicio < trunc(sysdate) - 14 ) or
                      ( p_periodo = '31-45'  and dd.dtestadoinicio >= trunc(sysdate) - 45  and dd.dtestadoinicio < trunc(sysdate) - 30 ) or
                      ( p_periodo = '46-60'  and dd.dtestadoinicio >= trunc(sysdate) - 60  and dd.dtestadoinicio < trunc(sysdate) - 45 ) or
                      ( p_periodo = '61-100' and dd.dtestadoinicio >= trunc(sysdate) - 100 and dd.dtestadoinicio < trunc(sysdate) - 60 ) or
                      ( trim(p_periodo) = '101'   and dd.dtestadoinicio <  trunc(sysdate) - 100 )
                    )
           GROUP BY do.dtdocumento,
                    do.amdocumento,
                    do.iddoctrx
             HAVING trunc( SUM( getSaldoFactura( do.iddoctrx ) ), 2 ) > 0
          UNION --Ingresos de tipo Egresos
             SELECT distinct ii.dtingreso,
                    pkg_ingreso_central.GetDescIngreso( ii.cdconfingreso, ii.cdsucursal ) dsaging,
                    ii.amingreso importe,
                    trunc( SUM( pkg_ingreso_central.GetImporteNoAplicado ( ii.idingreso ) ), 2 )  saldo
               FROM entidades ee,
                    sucursales su,
                    tblingreso ii,
                    tblcuenta cu,
                    tblregion re,
                    tblconfingreso ci
              WHERE ii.cdsucursal    = su.cdsucursal
                AND ii.cdsucursal    = ci.cdsucursal
                AND ii.cdsucursal    = pkg_cuenta_central.GetSucursalCuenta( p_idcuenta )
                AND ( ii.idcuenta    = p_idcuenta or p_idcuenta is null )
                AND ii.cdestado     in ( '1', '2' ) --No aplicado, Parcialmente Aplicado
                AND ii.idcuenta      = cu.idcuenta
                AND su.cdregion      = re.cdregion
                AND ee.identidad     = cu.identidad
                AND ci.cdconfingreso = ii.cdconfingreso
                AND ci.cdaccion      = 4 --Engreso
                --AND cu.cdtipocuenta  = '1'
                AND ( ( p_periodo = '0-7'    and ii.dtingreso >= trunc(sysdate) - 7) or
                      ( p_periodo = '8-14'   and ii.dtingreso >= trunc(sysdate) - 14  and ii.dtingreso < trunc(sysdate) - 7  ) or
                      ( p_periodo = '15-30'  and ii.dtingreso >= trunc(sysdate) - 30  and ii.dtingreso < trunc(sysdate) - 14 ) or
                      ( p_periodo = '31-45'  and ii.dtingreso >= trunc(sysdate) - 45  and ii.dtingreso < trunc(sysdate) - 30 ) or
                      ( p_periodo = '46-60'  and ii.dtingreso >= trunc(sysdate) - 60  and ii.dtingreso < trunc(sysdate) - 45 ) or
                      ( p_periodo = '61-100' and ii.dtingreso >= trunc(sysdate) - 100 and ii.dtingreso < trunc(sysdate) - 60 ) or
                      ( p_periodo = '101+'   and ii.dtingreso  < trunc(sysdate) - 100 )
                    )
           GROUP BY ii.dtingreso,
                    ii.amingreso,
                    ii.cdconfingreso,
                    ii.cdsucursal
             HAVING trunc( SUM( pkg_ingreso_central.GetImporteNoAplicado( ii.idingreso ) ), 2 ) > 0 );

   EXCEPTION
      WHEN OTHERS THEN
         n_pkg_vitalpos_log_general.write(2, 'Modulo: ' || v_Modulo || ' Error: ' || SQLERRM);
         RAISE;
   END GetAgingPopup;

   /*****************************************************************************************************************
   * Reporte de movimientos en efectivo agrupados por region y sucursal
   * %v 06/08/2014 - MatiasG: v1.0
   * %v 12/01/2015 - MartinM: v1.1 cambio el total del movimiento de la caja por solamente el ingreso en efectivo
   * %v 12/01/2015 - MartinM: v1.1 cambio el total del movimiento de la caja por solamente el alivio en efectivo
   ******************************************************************************************************************/
  PROCEDURE GetMovimientosEfectivoGeneral(p_cdregion   IN tblregion.cdregion%TYPE,
                             p_sucursales IN VARCHAR2,
                             p_idPersona  IN tblmovcaja.idpersonaresponsable%TYPE,
                             p_fechaDesde IN DATE,
                             p_fechaHasta IN DATE,
                             p_cur_out    OUT cursor_type) IS
    v_Modulo    VARCHAR2(100) := 'PKG_REPORTE_CENTRAL.GetMovimientosEfectivoGeneral';
    v_idReporte VARCHAR2(40) := '';
  BEGIN
    v_idReporte := SetSucursalesSeleccionadas(p_sucursales);
    OPEN p_cur_out FOR
    SELECT cdsucursal,
           dssucursal,
           cdregion,
           dsregion,
           SUM(ingreso) ingreso,
           SUM(egreso) egreso
       FROM (SELECT su.cdsucursal,
                   su.dssucursal,
                   re.cdregion,
                   re.dsregion,
                   TRUNC(SUM(ii.amingreso), 2) ingreso,
                   0 egreso
              FROM tblingreso                ii,
                   tblmovcaja                mc,
                   sucursales                su,
                   tblregion                 re,
                   tbltmp_sucursales_reporte rs
             WHERE ii.idmovcaja = mc.idmovcaja
               AND ii.cdsucursal = su.cdsucursal
               AND su.cdregion = re.cdregion
               AND rs.idreporte = v_idReporte
               AND rs.cdsucursal = su.cdsucursal
               AND re.cdregion = NVL(p_cdregion, re.cdregion)
               AND mc.idpersonaresponsable = NVL(p_idpersona, mc.idpersonaresponsable)
               AND mc.dtmovimiento BETWEEN trunc(p_fechaDesde) AND trunc(p_fechaHasta + 1)
               AND mc.cdoperacioncaja = 2 -- movimientos
               AND ii.cdconfingreso IN (SELECT ci.cdconfingreso
                                          FROM tblconfingreso ci
                                         WHERE ci.cdmedio = 1
                                           AND ci.cdtipo IN (20, 18))
   GROUP BY su.cdsucursal,
            su.dssucursal,
            re.cdregion,
            re.dsregion
        UNION
        SELECT su.cdsucursal,
               su.dssucursal,
               re.cdregion,
               re.dsregion,
               0 ingreso,
               TRUNC(SUM(ad.amaliviado)* -1, 2) egreso
          FROM tblaliviodetalle          ad,
                tblmovcaja                mc,
               sucursales                su,
               tblregion                 re,
               tbltmp_sucursales_reporte rs
         WHERE ad.idmovcaja = mc.idmovcaja
           AND ad.cdsucursal = su.cdsucursal
           AND su.cdregion = re.cdregion
           AND rs.idreporte = v_idReporte
           AND rs.cdsucursal = su.cdsucursal
           AND re.cdregion = NVL(p_cdregion, re.cdregion)
           AND mc.idpersonaresponsable = NVL(p_idpersona, mc.idpersonaresponsable)
           AND mc.dtmovimiento BETWEEN trunc(p_fechaDesde) AND trunc(p_fechaHasta + 1)
           AND mc.cdoperacioncaja = 3 --alivios
           AND ad.cdconfingreso IN (SELECT ci.cdconfingreso
                                       FROM tblconfingreso ci
                                      WHERE ci.cdmedio = 1
                                        AND ci.cdtipo IN (20, 18))
      GROUP BY su.cdsucursal,
               su.dssucursal,
               re.cdregion,
               re.dsregion)
      GROUP BY cdsucursal,
               dssucursal,
               cdregion,
               dsregion;

    CleanSucursalesSeleccionadas(v_idReporte);
  EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2, 'Modulo: ' || v_Modulo || ' Error: ' || SQLERRM);
      RAISE;
  END GetMovimientosEfectivoGeneral;

   /*****************************************************************************************************************
   * Reporte de movimientos en efectivo detalle
   * %v 06/08/2014 - MatiasG: v1.0
   * %v 13/01/2015 - MartinM: v1.1 Cambio mc.ammovimiento por ii.amingreso para mostrar solo los montos en efectivo
   * %v 14/01/2015 - MartinM: v1.1 Cambio mc.ammovimiento por ad.amaliviado para mostrar solo los montos en efectivo
   * %v 23/11/2015 - APW: v1.2 - Agrego ALL al union para que no elimine duplicados
   ******************************************************************************************************************/
  FUNCTION GetMovimientosEfectivo(p_cdsucursal    IN sucursales.cdsucursal%TYPE,
                                   p_idpersona     IN tbltesoro.idpersona%TYPE,
                                   p_fechaDesde    IN DATE,
                                   p_fechaHasta    IN DATE)
    RETURN tab_efectivo PIPELINED IS

    v_Modulo          VARCHAR2(100) := 'PKG_REPORTE_CENTRAL.GetMovimientosEfectivo';
    v_saldo_anterior  NUMBER := 0;
    r_efectivo        reg_efectivo;


    CURSOR cur_efectivo IS
       SELECT mc.dtmovimiento,
              pe.dsapellido,
              pe.dsnombre,
              oc.dsoperacioncaja,
              mc.ammovimiento,
              su.dssucursal
         FROM tblmovcaja mc,
              personas pe,
              tbloperacioncaja oc,
              sucursales su
        WHERE mc.idpersonaresponsable = pe.idpersona
          AND mc.cdoperacioncaja = oc.cdoperacioncaja
          AND mc.cdsucursal = su.cdsucursal
          AND mc.cdoperacioncaja NOT IN (2, 3) --Solo aperturas y cierres
          AND mc.idpersonaresponsable = NVL(p_idpersona, mc.idpersonaresponsable)
          AND mc.cdsucursal = NVL (p_cdsucursal,mc.cdsucursal)
          AND mc.dtmovimiento BETWEEN trunc(p_fechaDesde) AND trunc(p_fechaHasta + 1)
      UNION ALL
      SELECT mc.dtmovimiento,
             pe.dsapellido,
             pe.dsnombre,
             DECODE(SIGN(ii.amingreso),-1,'Egreso',1,'Ingreso'),
             ii.amingreso,
             su.dssucursal
        FROM tblingreso       ii,
             tblmovcaja       mc,
             personas         pe,
             tbloperacioncaja oc,
          sucursales       su
       WHERE ii.idmovcaja= mc.idmovcaja
            AND mc.idpersonaresponsable = pe.idpersona
            AND mc.cdoperacioncaja = oc.cdoperacioncaja
         AND mc.cdsucursal = su.cdsucursal
        AND mc.cdoperacioncaja = 2 -- movimientos
        AND mc.cdsucursal = NVL (p_cdsucursal,mc.cdsucursal)
        AND mc.idpersonaresponsable = NVL(p_idpersona, mc.idpersonaresponsable)
        AND mc.dtmovimiento BETWEEN trunc(p_fechaDesde) AND trunc(p_fechaHasta + 1)
        AND ii.cdconfingreso IN (SELECT ci.cdconfingreso
                              FROM tblconfingreso ci
                              WHERE ci.cdmedio = 1
                            AND ci.cdtipo IN (20, 18))
      UNION ALL
         SELECT mc.dtmovimiento,
                pe.dsapellido,
                pe.dsnombre,
                'Alivio',
                (ad.amaliviado *-1) ammovimiento,
                su.dssucursal
         FROM tblaliviodetalle ad,
                tblmovcaja       mc,
                personas         pe,
                tbloperacioncaja oc,
             sucursales       su
       WHERE ad.idmovcaja= mc.idmovcaja
            AND mc.idpersonaresponsable = pe.idpersona
            AND mc.cdoperacioncaja = oc.cdoperacioncaja
        AND mc.cdsucursal = su.cdsucursal
        AND mc.cdoperacioncaja = 3 -- alivios
        AND mc.cdsucursal = NVL (p_cdsucursal,mc.cdsucursal)
        AND mc.idpersonaresponsable = NVL(p_idpersona, mc.idpersonaresponsable)
        AND mc.dtmovimiento BETWEEN trunc(p_fechaDesde) AND trunc(p_fechaHasta + 1)
        AND ad.cdconfingreso IN (SELECT ci.cdconfingreso
                                 FROM tblconfingreso ci
                              WHERE ci.cdmedio = 1
                                AND ci.cdtipo IN (20, 18))
      ORDER BY 2,1;
     BEGIN

      FOR r IN cur_efectivo
      LOOP

         IF r.dsoperacioncaja IN ('Apertura','Cierre') THEN
            v_saldo_anterior := r.ammovimiento;
           r_efectivo.saldo := r.ammovimiento;
         ELSE
           r_efectivo.saldo := r.ammovimiento + v_saldo_anterior;
           v_saldo_anterior := r_efectivo.saldo;
         END IF;

          r_efectivo.dsoperacioncaja := r.dsoperacioncaja;
         r_efectivo.ammovimiento := r.ammovimiento;
           r_efectivo.dtmovimiento := r.dtmovimiento;
         r_efectivo.dsnombre := r.dsnombre;
         r_efectivo.dsapellido := r.dsapellido;
         r_efectivo.dssucursal := r.dssucursal;

         PIPE ROW(r_efectivo);
      END LOOP;

        RETURN;

      EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2, 'Modulo: ' || v_Modulo || ' Error: ' || SQLERRM);
      RAISE;
  END GetMovimientosEfectivo;

   /*****************************************************************************************************************
   * Reporte de movimientos en efectivo detalle
   * %v 06/08/2014 - MatiasG: v1.0
   ******************************************************************************************************************/
  PROCEDURE GetMovimientosEfectivoDetalle(p_cdsucursal    IN sucursales.cdsucursal%TYPE,
                                         p_idpersona     IN tbltesoro.idpersona%TYPE,
                                           p_fechaDesde    IN DATE,
                                           p_fechaHasta    IN DATE,
                                           p_cur_out       OUT cursor_type) IS
    v_Modulo VARCHAR2(100) := 'PKG_REPORTE_CENTRAL.GetMovimientosEfectivoDetalle';
  BEGIN
    OPEN p_cur_out FOR
      SELECT dtmovimiento, dsnombre, dsapellido, DECODE(dsoperacioncaja,'2',to_char(ammovimiento),dsoperacioncaja) dsoperacioncaja, dssucursal,ammovimiento, saldo
           FROM TABLE(GetMovimientosEfectivo(p_cdsucursal,p_idpersona,p_fechaDesde,p_fechaHasta));
  EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2, 'Modulo: ' || v_Modulo || ' Error: ' || SQLERRM);
      RAISE;
  END GetMovimientosEfectivoDetalle;

   /*****************************************************************************************************************
   * Retorna un reporte la lista de guias rendidas por fletero
   * %v 06/08/2014 - MatiasG: v1.0
   ******************************************************************************************************************/
   PROCEDURE GetGuiasPorFleteroGeneral(p_sucursales IN VARCHAR2,
                                       p_identidad  IN entidades.identidad%TYPE,
                                       p_fechaDesde IN DATE,
                                       p_fechaHasta IN DATE,
                                       p_estado     IN documentos.cdestadocomprobante%TYPE,
                                       p_cur_out    OUT cursor_type) IS
      v_Modulo VARCHAR2(100) := 'PKG_REPORTE_CENTRAL.GetGuiasPorFleteroGeneral';
      v_idReporte VARCHAR2(40) := '';
   BEGIN
      v_idReporte := SetSucursalesSeleccionadas(p_sucursales);

      OPEN p_cur_out FOR
         SELECT re.cdregion, re.dsregion, su.cdsucursal, su.dssucursal, COUNT(*) cantidad
           FROM documentos                do,
                guiasdetransporte         gt,
                estadocomprobantes        ec,
                sucursales                su,
                tblregion                 re,
           tbltmp_sucursales_reporte rs
          WHERE do.iddoctrx = gt.iddoctrx
            and do.cdcomprobante = 'GUIA'
            AND do.cdestadocomprobante = ec.cdestado
            AND do.cdcomprobante = ec.cdcomprobante
            AND do.cdsucursal = su.cdsucursal
            AND su.cdregion = re.cdregion
            AND rs.idreporte = v_idReporte
        AND rs.cdsucursal = su.cdsucursal
            AND gt.icestado = NVL(p_estado, gt.icestado)
        AND gt.idtransportista = NVL(p_identidad, gt.idtransportista)
        AND do.dtdocumento BETWEEN TRUNC(p_fechaDesde) AND TRUNC(p_fechaHasta + 1)
          GROUP BY re.cdregion, re.dsregion, su.cdsucursal, su.dssucursal;

      CleanSucursalesSeleccionadas(v_idReporte);
   EXCEPTION
      WHEN OTHERS THEN
         n_pkg_vitalpos_log_general.write(2, 'Modulo: ' || v_Modulo || ' Error: ' || SQLERRM);
         RAISE;
   END GetGuiasPorFleteroGeneral;

   /*****************************************************************************************************************
   * Retorna un reporte la lista de guias rendidas por fletero detallada
   * %v 06/08/2014 - MatiasG: v1.0
   * %v 24/02/2016 - APW: Agrego motivo de anulación (si existe)
   * %v 13/09/2016 - APW: agrego que tome el primero por error de réplicas
   * %v 27/10/2017 - IAquilano: Agrego columnas de Patente, Chofer, direccion y Dias de vencido
   * %v 28/02/201 - JB: Se creo la funcion VendedorPorGuia para retornar en nombre y apellido del vendedor
   * %v 11/04/2018 - IAquilano: Quito de motivos la aplicacion y que busque directamente por cdmotivo.
   ******************************************************************************************************************/
 PROCEDURE GetGuiasPorFleteroDetalle(p_cdsucursal IN sucursales.cdsucursal%TYPE,
                                     p_identidad  IN entidades.identidad%TYPE,
                                     p_fechaDesde IN DATE,
                                     p_fechaHasta IN DATE,
                                     p_estado     IN documentos.cdestadocomprobante%TYPE,
                                     p_cur_out    OUT cursor_type) IS
   v_Modulo VARCHAR2(100) := 'PKG_REPORTE_CENTRAL.GetGuiasPorFleteroDetalle';
 BEGIN
   OPEN p_cur_out FOR
     SELECT do.sqcomprobante,
            do.amdocumento,
            gt.icestado,
            ec.dsestado,
            su.dssucursal,
            do.dtdocumento,
            ee.cdcuit,
            ee.dsrazonsocial,
            de.dscalle || ', ' || de.dsnumero direccion, --agrego direccion
            tra.dsrazonsocial transportista,
            nvl(UPPER(gt.vehiculo),'-') Patente, --agrego patente
            nvl(gt.chofertxt, '-') chofertxt, --agrego chofer
            (select m.dsmotivo
               from motivos m, auditoria a
              where m.cdmotivo = a.cdmotivo--quito aplicacion y dejo cdmotivo
                and a.iddoctrx = do.iddoctrx
                and rownum = 1) dsmotivo,
            (case
              when ec.dsestado = 'Asignada' then
               trunc(sysdate) - trunc(gt.dtasignada)
              else
               -1
            end) dias_sin_rendir, --dias vencida
            VendedorPorGuia(gt.idguiadetransporte) vendedor
       FROM documentos           do,
            guiasdetransporte    gt,
            estadocomprobantes   ec,
            sucursales           su,
            entidades            ee,
            entidades            tra,
            direccionesentidades de --agrego tabla direccionesentidades
      WHERE do.iddoctrx = gt.iddoctrx
        and do.cdcomprobante = 'GUIA'
        AND do.identidad = ee.identidad
        and tra.identidad = gt.idtransportista
        AND do.cdcomprobante = ec.cdcomprobante
        and gt.icestado = ec.cdestado
        AND do.cdsucursal = su.cdsucursal
        AND gt.icestado = NVL(p_estado, gt.icestado)
        AND gt.idtransportista = NVL(p_identidad, gt.idtransportista)
        AND do.cdsucursal = NVL(p_cdsucursal, do.cdsucursal)
        and de.identidad = ee.identidad --agrego join con tabla entidades
        and de.cdtipodireccion = gt.cdtipodireccion --agrego join con tabla guia
        and de.sqdireccion = gt.sqdireccion
        AND do.dtdocumento BETWEEN TRUNC(p_fechaDesde) AND
            TRUNC(p_fechaHasta + 1)
            order by dias_sin_rendir desc;
 EXCEPTION
   WHEN OTHERS THEN
     n_pkg_vitalpos_log_general.write(2,
                                      'Modulo: ' || v_Modulo || ' Error: ' ||
                                      SQLERRM);
     RAISE;
 END GetGuiasPorFleteroDetalle;

   /*****************************************************************************************************************
   * Retorna un reporte de diferencia de alivios de caja
   * %v 06/08/2014 - MatiasG: v1.0
   * %v 14/01/2015 - MartinM: v1.1 -- Agrego outer join a la tabla tbltesoro porque no muestra diferencia de alivios
                                      en casos donde el monto confirmado (amconfirmado) es 0 (estado rechazado).
   * %v 02/11/2016 - LucianoF: v1.2 -- Muestro todos los alivios en vez de diferencia
   ******************************************************************************************************************/
   PROCEDURE GetDiferenciaDeAliviosGeneral(p_cdRegion   IN tblregion.cdregion%TYPE,
                                           p_sucursales IN VARCHAR2,
                                           p_idPersona  IN tblmovcaja.idpersonaresponsable%TYPE,
                                           p_fechaDesde IN DATE,
                                           p_fechaHasta IN DATE,
                                           p_cur_out    OUT cursor_type) IS
      v_Modulo    VARCHAR2(100) := 'PKG_REPORTE_CENTRAL.GetDiferenciaDeAliviosGeneral';
      v_idReporte VARCHAR2(40) := '';
   BEGIN
      v_idReporte := SetSucursalesSeleccionadas(p_sucursales);

      OPEN p_cur_out FOR
       SELECT cdregion, dsregion, cdsucursal, dssucursal, SUM(aliviado) aliviado, SUM(confirmado) confirmado
         FROM (SELECT re.cdregion,
                      re.dsregion,
                      su.cdsucursal,
                      su.dssucursal,
                      ad.amaliviadooriginal aliviado,
                      ABS(nvl(te.amconfirmado,0)) confirmado --MM 14/01/2015
                 FROM tbltesoro                 te,
                      tblaliviodetalle          ad,
                      sucursales                su,
                      tblregion                 re,
                      tblmovcaja                mc,
                      tbltmp_sucursales_reporte rs
                WHERE te.idaliviodetalle (+) = ad.idaliviodetalle
                  AND te.cdsucursal (+) =  ad.cdsucursal
                  AND ad.cdestado in (2,3)
                  AND ad.idmovcaja = mc.idmovcaja
                  AND su.cdsucursal = ad.cdsucursal
                  AND su.cdregion = re.cdregion
                  AND mc.cdoperacioncaja = 3
                  AND rs.idreporte = v_idReporte
                  AND rs.cdsucursal = su.cdsucursal
                  AND mc.idpersonaresponsable = NVL(p_idpersona, mc.idpersonaresponsable)
                  AND re.cdregion = NVL(p_cdRegion, re.cdregion)
                  AND mc.dtmovimiento BETWEEN TRUNC(p_fechaDesde) AND TRUNC(p_fechaHasta + 1)
                  and ad.cdestado = '2' --Alivio confirmado
                  --AND (ad.amaliviadooriginal - ABS(nvl(te.amconfirmado,0))) <> 0
                  )
        GROUP BY cdregion, dsregion, cdsucursal, dssucursal;

      CleanSucursalesSeleccionadas(v_idReporte);
   EXCEPTION
      WHEN OTHERS THEN
         n_pkg_vitalpos_log_general.write(2, 'Modulo: ' || v_Modulo || ' Error: ' || SQLERRM);
         RAISE;
   END GetDiferenciaDeAliviosGeneral;

   /*****************************************************************************************************************
   * Retorna un reporte de diferencia de alivios de caja detallado
   * %v 06/08/2014 - MatiasG: v1.0
   * %v 14/01/2015 - MartinM: v1.1 -- Agrego outer join a la tabla tbltesoro porque no muestra diferencia de alivios
                                      en casos donde el monto confirmado (amconfirmado) es 0 (estado rechazado).
   * %v 02/11/2016 - LucianoF: v1.2 -- Muestro todos los alivios en vez de diferencia
   * %v 19/10/2021 - LM: se agrega la observacion de que el alivio de tarjeta vino sin cupon
   * %v 05/01/2022 - IA: Se agrega columna DTCARGAALIVIO para metricas
   ******************************************************************************************************************/
  PROCEDURE GetDiferenciaDeAliviosDetalle(p_cdsucursal    IN sucursales.cdsucursal%TYPE,
                                         p_idpersona     IN tbltesoro.idpersona%TYPE,
                                           p_fechaDesde    IN DATE,
                                           p_fechaHasta    IN DATE,
                                          p_cur_out       OUT cursor_type) IS
    v_Modulo VARCHAR2(100) := 'PKG_REPORTE_CENTRAL.GetDiferenciaDeAliviosDetalle';
  BEGIN
    OPEN p_cur_out FOR
SELECT su.cdsucursal,
                su.dssucursal,
                pe.dsapellido || ', ' || pe.dsnombre responsable,
                pkg_ingreso_central.GetDescIngreso(ad.cdconfingreso, ad.cdsucursal) dsingreso,
                ad.amaliviadooriginal aliviado,
                ABS(nvl(te.amconfirmado,0)) confirmado,
                (ad.amaliviadooriginal - ABS(nvl(te.amconfirmado,0))) diferencia,
                ad.idsobre,
                nvl(ta.dtinicioalivio,ad.dtestado) dtcargaalivio,
                nvl(te.dtoperacion, ad.dtestado) dtconfirmado,
                mc.dtmovimiento dtaliviado,
                ee.cdcuit,
                ee.dsrazonsocial,
                cu.nombrecuenta,
                (decode(nvl(ad.icsincupon,0),0,'-','Sin Cupon') ) observacion
           FROM tbltesoro        te,
                tblaliviodetalle ad,
                sucursales       su,
                tblregion        re,
                tblmovcaja       mc,
                personas         pe,
                tblingreso       ii,
                tblcuenta        cu,
                entidades        ee,
                tblalivio        ta
          WHERE te.idaliviodetalle (+) = ad.idaliviodetalle
            AND te.cdsucursal (+) = ad.cdsucursal
            AND ad.idmovcaja = mc.idmovcaja
            AND ad.cdestado in (2,3)
            AND su.cdsucursal = ad.cdsucursal
            AND su.cdregion = re.cdregion
            AND mc.idpersonaresponsable = pe.idpersona
            AND mc.cdoperacioncaja = 3
            AND ad.cdsucursal = NVL(p_cdsucursal, ad.cdsucursal)
            and nvl(te.dtoperacion, ad.dtestado)=(select nvl(max(te.dtoperacion),ad.dtestado)
                                                  from tbltesoro te
                                                  where te.idaliviodetalle=ad.idaliviodetalle)
            AND mc.idpersonaresponsable = NVL(p_idpersona, mc.idpersonaresponsable)
            AND mc.dtmovimiento BETWEEN TRUNC(p_fechaDesde) AND TRUNC(p_fechaHasta + 1)
            and ad.cdestado = '2' --Alivio confirmado
            --AND (ad.amaliviadooriginal - ABS(nvl(te.amconfirmado,0))) <> 0
            AND ii.idingreso(+)=ad.idingreso
            AND ii.idcuenta=cu.idcuenta(+)
            AND ee.identidad(+)=cu.identidad
            and ad.idalivio = ta.idalivio(+)--con outer asi trae todos los anteriores
          ORDER BY nvl(te.dtoperacion, ad.dtestado);

  EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2, 'Modulo: ' || v_Modulo || ' Error: ' || SQLERRM);
      RAISE;
  END GetDiferenciaDeAliviosDetalle;

   /*****************************************************************************************************************
   * Retorna un reporte de egresos de tesoreria
   * %v 06/08/2014 - MatiasG: v1.0
   ******************************************************************************************************************/
   PROCEDURE GetEgresosTesoreroGeneral(p_cdRegion   IN tblregion.cdregion%TYPE,
                                        p_sucursales IN VARCHAR2,
                           p_idPersona  IN tbltesoro.idpersona%TYPE,
                                        p_fechaDesde IN DATE,
                                        p_fechaHasta IN DATE,
                           p_cur_out OUT cursor_type) IS
    v_Modulo    VARCHAR2(100) := 'PKG_REPORTE_CENTRAL.GetEgresosTesoreroGeneral';
    v_idReporte VARCHAR2(40) := '';
  BEGIN
    v_idReporte := SetSucursalesSeleccionadas(p_sucursales);

    OPEN p_cur_out FOR
      SELECT cdsucursal, dssucursal, cdregion, dsregion, SUM(dolares) dolares, sum(pesos) pesos
      FROM (SELECT su.cdsucursal, su.dssucursal, re.cdregion, re.dsregion, SUM(te.amconfirmado) * -1 dolares, 0 pesos
            FROM tbltesoro te, sucursales su, tblregion re, tblconfingreso ci, tbltmp_sucursales_reporte rs
           WHERE te.cdsucursal = su.cdsucursal
            AND su.cdregion = re.cdregion
            AND te.idtransportadoracaudales IS NOT NULL
            AND te.cddestinocaudal IS NOT NULL
            AND te.cdconfingreso = ci.cdconfingreso
            AND te.cdsucursal = ci.cdsucursal
            AND ci.cdconfingreso = '9047'
            AND ci.cdaccion = 4
            AND rs.idreporte = v_idReporte
                  AND rs.cdsucursal = su.cdsucursal
            AND re.cdregion = NVL(p_cdRegion, re.cdregion)
            AND te.idpersona = NVL(p_idpersona, te.idpersona)
            AND te.dtoperacion BETWEEN TRUNC(p_fechaDesde) AND TRUNC(p_fechaHasta + 1)
           GROUP BY su.cdsucursal, su.dssucursal, re.cdregion, re.dsregion
           UNION ALL
          SELECT su.cdsucursal, su.dssucursal, re.cdregion, re.dsregion, 0 dolares, SUM(te.amconfirmado) * -1 pesos
            FROM tbltesoro te, sucursales su, tblregion re, tblconfingreso ci, tbltmp_sucursales_reporte rs
           WHERE te.cdsucursal = su.cdsucursal
            AND su.cdregion = re.cdregion
            AND te.idtransportadoracaudales IS NOT NULL
            AND te.cddestinocaudal IS NOT NULL
            AND te.cdconfingreso = ci.cdconfingreso
            AND te.cdsucursal = ci.cdsucursal
            AND ci.cdconfingreso != '9047'
            AND ci.cdaccion = 4
            AND rs.idreporte = v_idReporte
                  AND rs.cdsucursal = su.cdsucursal
            AND re.cdregion = NVL(p_cdRegion, re.cdregion)
            AND te.idpersona = NVL(p_idpersona, te.idpersona)
            AND te.dtoperacion BETWEEN TRUNC(p_fechaDesde) AND TRUNC(p_fechaHasta + 1)
           GROUP BY su.cdsucursal, su.dssucursal, re.cdregion, re.dsregion)
       GROUP BY cdsucursal, dssucursal, cdregion, dsregion;

    CleanSucursalesSeleccionadas(v_idReporte);
  EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2, 'Modulo: ' || v_Modulo || ' Error: ' || SQLERRM);
      RAISE;
  END GetEgresosTesoreroGeneral;

   /*****************************************************************************************************************
   * Retorna un reporte de egresos de tesoreria detallado
   * %v 06/08/2014 - MatiasG: v1.0
   ******************************************************************************************************************/
  PROCEDURE GetEgresosTesoreroDetalle(p_cdsucursal    IN  sucursales.cdsucursal%TYPE,
                                       p_idPersona     IN tbltesoro.idpersona%TYPE,
                                      p_fechaDesde    IN  DATE,
                                      p_fechaHasta    IN  DATE,
                          p_cur_out       OUT cursor_type) IS
    v_Modulo VARCHAR2(100) := 'PKG_REPORTE_CENTRAL.GetEgresosTesoreroDetalle';
  BEGIN
    OPEN p_cur_out FOR
      SELECT su.cdsucursal,
           su.dssucursal,
           te.dtoperacion,
           pkg_ingreso_central.GetDescIngreso(te.cdconfingreso, su.cdsucursal) dsingreso,
           sum(te.amconfirmado *-1) amconfirmado,
           tc.dstransportadora,
           dc.dsdestinocaudal
        FROM tbltesoro             te,
           sucursales            su,
           tblregion             re,
           tbltransportecaudales tc,
           tbldestinocaudal      dc,
           tblconfingreso        ci
       WHERE te.cdsucursal = su.cdsucursal
        AND su.cdregion = re.cdregion
        AND te.cddestinocaudal = dc.cddestinocaudal
        AND tc.idtransportadoracaudales = te.idtransportadoracaudales
        AND te.idtransportadoracaudales IS NOT NULL
        AND te.cddestinocaudal IS NOT NULL
        AND te.cdconfingreso = ci.cdconfingreso
        AND te.cdsucursal = ci.cdsucursal
        AND ci.cdaccion = 4
        AND te.idpersona = NVL(p_idPersona, te.idpersona)
        AND su.cdsucursal = NVL(p_cdsucursal, su.cdsucursal)
        AND te.dtoperacion BETWEEN TRUNC(p_fechaDesde) AND TRUNC(p_fechaHasta + 1)
        group by su.cdsucursal,
        su.dssucursal,
        te.dtoperacion,
        pkg_ingreso_central.GetDescIngreso(te.cdconfingreso, su.cdsucursal) ,
        tc.dstransportadora,
        dc.dsdestinocaudal;

  EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2, 'Modulo: ' || v_Modulo || ' Error: ' || SQLERRM);
      RAISE;
  END GetEgresosTesoreroDetalle;

  /*****************************************************************************************************************
  * Retorna un reporte general de ranking de telemarketers
  * %v 10/09/2014 - MatiasG: v1.0
  * %v 31/03/2016 - APW: Elimino la búsqueda de documentos pedido sin identidadreal
  ******************************************************************************************************************/
  Procedure GetRankingTelemarketers(p_idTelemarketer In pedidos.idpersonaresponsable%Type,
                                    p_sucursales     In Varchar2,
                                    p_fechaDesde     In Date,
                                    p_fechaHasta     In Date,
                                    p_cur_out        Out cursor_type) Is
     v_Modulo    Varchar2(100) := 'PKG_REPORTE_CENTRAL.GetRankingTelemarketers';
     v_idReporte Varchar2(40) := '';
  Begin
     v_idReporte := SetSucursalesSeleccionadas(p_sucursales);
     Open p_cur_out For
     WITH doc_cliente as
           (/*select d.iddoctrx, d.idcuenta, d.cdsucursal, d.amdocumento, e.identidad, e.cdcuit, e.dsrazonsocial
            from documentos d, entidades e
            where d.identidad = e.identidad
            and   d.identidad <> 'IdCfReparto'
            and   d.identidadreal is null
            and   d.cdcomprobante = 'PEDI'
            and   d.dtdocumento BETWEEN TRUNC(p_fechaDesde) AND TRUNC(p_fechaHasta + 1)
           union*/
            select d.iddoctrx, d.idcuenta, d.cdsucursal, d.amdocumento, e.identidad, e.cdcuit, e.dsrazonsocial
            from documentos d, entidades e
            where d.identidadreal = e.identidad
            and   d.identidadreal is not null
            and   d.cdcomprobante = 'PEDI'
            and   d.dtdocumento BETWEEN TRUNC(p_fechaDesde) AND TRUNC(p_fechaHasta + 1)
           /*union
            select d.iddoctrx, d.idcuenta, d.cdsucursal, d.amdocumento, e.identidad, e.cdcuit, e.dsrazonsocial
            from documentos d, entidades e
            where e.cdcuit = trim(replace(replace(d.dsreferencia, '[', ''), ']', ''))||'  '
            and   d.identidad = 'IdCfReparto'
            and   d.identidadreal is null
            and   d.cdcomprobante = 'PEDI'
            and   d.dtdocumento BETWEEN TRUNC(p_fechaDesde) AND TRUNC(p_fechaHasta + 1)*/
            )
        Select su.cdsucursal,
               su.dssucursal,
               do.identidad,
               do.dsrazonsocial,
               do.cdcuit,
               pe.idpersona,
               pe.dsapellido || ' ' || pe.dsnombre dspersona,
               TRUNC(pd.dtaplicacion) dtdocumento,
               ec.dsestado,
               Sum(do.amdocumento) amdocumento
          From pedidos                   pd,
               doc_cliente               do,
               sucursales                su,
               personas                  pe,
               estadocomprobantes        ec,
               tbltmp_sucursales_reporte rs
         Where do.iddoctrx = pd.iddoctrx
           And su.cdsucursal = do.cdsucursal
           And rs.idreporte = v_idReporte
           And pd.id_canal = 'TE'
           And rs.cdsucursal = su.cdsucursal
           And pe.idpersona = pd.idpersonaresponsable
           And pd.icestadosistema = ec.cdestado
           and ec.cdcomprobante = 'PEDI'
           And pd.idpersonaresponsable = NVL(p_idTelemarketer, pd.idpersonaresponsable)
           And pd.dtaplicacion Between TRUNC(p_fechaDesde) And TRUNC(p_fechaHasta + 1)
         Group By su.cdsucursal,
                  su.dssucursal,
                  do.identidad,
                  do.dsrazonsocial,
                  do.cdcuit,
                  pe.idpersona,
                  pe.dsapellido || ' ' || pe.dsnombre,
                  TRUNC(pd.dtaplicacion),
                  ec.dsestado
         Order by pe.dsapellido || ' ' || pe.dsnombre,
                  su.dssucursal,
                  ec.dsestado,
                  do.cdcuit;
     CleanSucursalesSeleccionadas(v_idReporte);
  Exception
     When Others Then
        n_pkg_vitalpos_log_general.write(2, 'Modulo: ' || v_Modulo ||
                                          ' Error: ' || Sqlerrm);
        Raise;
  End GetRankingTelemarketers;

   /*****************************************************************************************************************
   * Retorna un reporte general de estadística de vendedores
   * %v 29/08/2014 - MatiasG: v1.0
   ******************************************************************************************************************/
   PROCEDURE GetEstadisticaVendedores(p_idVendedor IN pedidos.idvendedor%TYPE,
                                      p_sucursales IN VARCHAR2,
                                      p_fechaDesde IN DATE,
                                      p_fechaHasta IN DATE,
                                      p_cur_out    OUT cursor_type) IS
      v_Modulo    VARCHAR2(100) := 'PKG_REPORTE_CENTRAL.GetEstadisticaVendedores';
      v_idReporte VARCHAR2(40) := '';
   BEGIN
      v_idReporte := SetSucursalesSeleccionadas(p_sucursales);

      OPEN p_cur_out FOR
         SELECT su.cdsucursal,
             su.dssucursal,
             ee.identidad,
                ee.dsrazonsocial,
                ee.cdcuit,
                pe.idpersona,
                pe.dsapellido || ' ' || pe.dsnombre dspersona,
                TRUNC(pp.dtaplicacion) dtdocumento,
                SUM(do.amdocumento) amdocumento
           FROM documentos                do,
                pedidos                   pp,
                entidades                 ee,
                personas                  pe,
                sucursales                su,
                tbltmp_sucursales_reporte rs
          WHERE do.iddoctrx = pp.iddoctrx
            AND do.cdsucursal = su.cdsucursal
            AND do.identidadreal = ee.identidad
            AND pp.idpersonaresponsable = pe.idpersona
            AND rs.idreporte = v_idReporte
            AND rs.cdsucursal = su.cdsucursal
            AND pp.id_canal = 'VE'
        AND pp.idvendedor IS NOT NULL
            AND pp.idvendedor = NVL(p_idVendedor, pp.idvendedor)
            AND pp.dtaplicacion BETWEEN TRUNC(p_fechaDesde) AND TRUNC(p_fechaHasta + 1)
          GROUP BY su.cdsucursal,
                su.dssucursal,
             ee.identidad,
                   ee.dsrazonsocial,
                   ee.cdcuit,
                   pe.idpersona,
                   pe.dsapellido || ' ' || pe.dsnombre,
                   TRUNC(pp.dtaplicacion);

      CleanSucursalesSeleccionadas(v_idReporte);
   EXCEPTION
      WHEN OTHERS THEN
         n_pkg_vitalpos_log_general.write(2, 'Modulo: ' || v_Modulo || ' Error: ' || SQLERRM);
         RAISE;
   END GetEstadisticaVendedores;  

   /*****************************************************************************************************************
   * Retorna un reporte de pedidos confirmados, pendientes y cancelados
   * %v 06/08/2014 - MatiasG: v1.0
   * %v 31/03/2016 - APW: Elimino la búsqueda de documentos pedido sin identidadreal
   * %v 25/04/2016 - APW: Muestro solo el máximo estado del grupo
   * %v 26/05/2016 - APW: Quito filtro de canal y lo muestro, además agrego el responsable (vendedor o comisionista)
   * %v 22/06/2016 - LucianoF: Agrego filtro de canal
   * %v 01/09/2017 - IAquilano: Agrego columna Transportista
   * %v 05/07/2018 - APW: mejoro la performance agregando fecha del log en la búsqueda
   * %v 25/10/2021 - APW: busqueda de cliente por identidadreal
   * %v 26/05/2022 - ChM ajusto retira en sucursal en direccion POSG-916
   * %v 26/05/2022 - ChM incorporo medio de pago del pedido POSG - 913
   ******************************************************************************************************************/
   PROCEDURE GetPedidosGeneral(p_sucursales IN VARCHAR2,
                               p_idEntidad  IN entidades.identidad%TYPE,
                               p_idCuenta   IN tblcuenta.idcuenta%TYPE,
                               p_estado     IN NUMBER,
                               p_fechaDesde IN DATE,
                               p_fechaHasta IN DATE,
                               p_canal      IN VARCHAR2,
                               cur_out      OUT cursor_type) IS
      v_Modulo    VARCHAR2(100) := 'PKG_REPORTE_CENTRAL.GetPedidosGeneral';
      v_idReporte VARCHAR2(40) := '';
   BEGIN
      v_idReporte := PKG_REPORTE_CENTRAL.SetSucursalesSeleccionadas(p_sucursales);

      OPEN cur_out FOR
      SELECT re.cdregion,
               re.dsregion,
               su.cdregion,
               su.dssucursal,
               e.cdcuit,
               e.dsrazonsocial,
               do.identidad,
               do.idcuenta,
               trunc(pe.dtaplicacion) Fecha,
               de.cdtipodireccion,
               de.sqdireccion,
               decode(nvl(pe.icretirasucursal,0),1,'Retira en Tienda',
                      de.dscalle || ' ' || de.dsnumero || ' (' || TRIM(de.cdcodigopostal) || ') ' || lo.dslocalidad
                     ) Direccion,
               pe.id_canal id_canal,
               pkg_pedido_central.GetNombreResponsable (pe.id_canal, pe.idpersonaresponsable, pe.idvendedor, pe.idcomisionista) responsableventa,
               ec.dsestado,
               trunc(lep.dtmodif) fecha_cambio_estado,
             SUM(pe.ammonto) Monto,
             case when pe.id_canal = 'CO' then--Agrego columna trasportista
                 null
                 else tr.dsrazonsocial
               end transportista,
               case
                when pe.icorigen=4 then 'EC'
                when pe.icorigen=5 then 'VD'
                when pe.icorigen=0 then 'VM'
                when pe.icorigen is null then 'CC'
                else
                '-'
                end as vitaldigital,            
             nvl(mp.dsmediopago,' ') mediodepago             
          FROM
             pedidos                   pe,
             documentos                do,
             direccionesentidades      de,
             localidades               lo,
             estadocomprobantes        ec,
             tbllogestadopedidos       lep,
             tblregion                 re,
             sucursales                su,
             entidades                 e,
             tbltmp_sucursales_reporte rs,
             (select distinct p.idpedido, e.dsrazonsocial
              from pedidos p, movmateriales mm, documentos doc, tbldetalleguia tg, guiasdetransporte gt, entidades e
              where p.idpedido = mm.idpedido
              and mm.idmovmateriales = doc.idmovmateriales
              and doc.iddoctrx = tg.iddoctrx
              and tg.idguiadetransporte = gt.idguiadetransporte
              and gt.idtransportista = e.identidad
              and p.dtaplicacion BETWEEN TRUNC(p_fechaDesde) AND TRUNC(p_fechaHasta + 1)) tr,
              --ChM incorporo medio de pago del pedido 26/05/2022
              ( select mp.idpedido,vm.dsmediopago
                  from pedidomediodepago mp, vtexmediodepago vm
                 where vm.idmediopago = mp.idmediopago
                   and vm.id_canal = mp.id_canal) mp              
         WHERE pe.iddoctrx = do.iddoctrx
         and   do.identidadreal = e.identidad
         and   pe.idpedido = tr.idpedido (+)     
         and   pe.idpedido = mp.idpedido (+)        
         and   do.cdcomprobante = 'PEDI'
         and   do.dtdocumento BETWEEN TRUNC(p_fechaDesde) AND TRUNC(p_fechaHasta + 1)
          AND pe.icestadosistema = ec.cdestado
          AND ec.cdcomprobante = 'PEDI'
          AND do.identidadreal = de.identidad
          AND de.cdtipodireccion = pe.cdtipodireccion
          AND de.sqdireccion = pe.sqdireccion
          and lo.cdpais = de.cdpais
          and lo.cdprovincia = de.cdprovincia
          AND lo.cdlocalidad = de.cdlocalidad
          AND do.cdsucursal = su.cdsucursal
          AND rs.idreporte = v_idReporte
          AND rs.cdsucursal= su.cdsucursal
          AND su.cdregion = re.cdregion
          AND (p_idEntidad is null OR p_identidad = do.identidadreal)
          AND (p_idCuenta is null OR p_idCuenta = do.idcuenta)
          AND (p_estado is null OR p_estado = pe.icestadosistema)
          and  pe.dtaplicacion BETWEEN TRUNC(p_fechaDesde) AND TRUNC(p_fechaHasta + 1)
          and  pe.icestadosistema = (select max(pe2.icestadosistema)
                                     from pedidos pe2/*, documentos do2
                                     where pe2.iddoctrx = do2.iddoctrx
                                     and trunc(pe2.dtaplicacion) = trunc(pe.dtaplicacion)
                                     and do2.identidadreal = do.identidadreal
                                     and dtaplicacion BETWEEN TRUNC(p_fechaDesde) AND TRUNC(p_fechaHasta + 1)*/
                                     where pe2.transid = pe.transid
                                     )  -- descarto prefacturas que no se procesaron
          and  pe.idpedido = lep.idpedido
          and  lep.dtmodif > TRUNC(p_fechaDesde)
          and  pe.id_canal in ( select * from (SELECT SUBSTR(txt, INSTR (txt, ',', 1, level ) + 1,
                                                   INSTR (txt, ',', 1, level + 1) - INSTR (txt, ',', 1, level) -1) AS u
                                FROM (SELECT replace(','|| replace(p_canal,' ','') || ',','''','') AS txt
                                      FROM dual )
                                CONNECT BY level <= LENGTH(txt)-LENGTH(REPLACE(txt,',',''))-1
                                ))
          and  pe.icestadosistema = lep.icestadosistema
          and  lep.dtmodif = (select max(lep2.dtmodif)
                              from tbllogestadopedidos lep2
                              where lep2.idpedido = lep.idpedido
                              and lep2.icestadosistema = lep.icestadosistema)  -- ultimo cambio de estado del pedido
         GROUP BY re.cdregion,
               re.dsregion,
               su.cdregion,
               su.dssucursal,
               e.cdcuit,
               e.dsrazonsocial,
               do.identidad,
               do.idcuenta,
               pe.icorigen,
               trunc(pe.dtaplicacion) ,
               de.cdtipodireccion,
               de.sqdireccion,
               pe.icretirasucursal,
               de.dscalle || ' ' || de.dsnumero || ' (' || TRIM(de.cdcodigopostal) || ') ' || lo.dslocalidad,
               pe.id_canal,
               pkg_pedido_central.GetNombreResponsable (pe.id_canal, pe.idpersonaresponsable, pe.idvendedor, pe.idcomisionista),
               ec.dsestado,
               trunc(lep.dtmodif),
                case when pe.id_canal = 'CO' then
                 null
                 else tr.dsrazonsocial
               end,     
               mp.dsmediopago              
         ORDER BY 2, 4, 13, 15, 16, 6;

      PKG_REPORTE_CENTRAL.CleanSucursalesSeleccionadas(v_idReporte);
   EXCEPTION
      WHEN OTHERS THEN
         n_pkg_vitalpos_log_general.write(2, 'Modulo: ' || v_Modulo || ' Error: ' || SQLERRM);
         RAISE;
   END GetPedidosGeneral;

   /*****************************************************************************************************************
   * Retorna un reporte de pedidos confirmados, pendientes y cancelados
   * %v 06/08/2014 - MatiasG: v1.0
   * %v 21/04/2015 - MartinM: v1.1 - Se modifica las clausulas que contenian los parametros
   *                                 cuenta entidad y persona para mejorar su performance
   * %v 20/07/2016 - RLC: Agrego parámetro Canal
   * %v 07/05/2020 - LM: se corrige para que devuelva datos si no tiene persona en documento pedido
   * %v 25/10/2021 - APW: cambio busqueda de cliente por entidad real
   ******************************************************************************************************************/
   PROCEDURE GetInformeJefeVentasGeneral(p_sucursales IN VARCHAR2,
                                         p_identidad  IN entidades.identidad%TYPE,
                                         p_idPersona  IN personas.idpersona%TYPE,
                                         p_idCuenta   IN tblcuenta.idcuenta%TYPE,
                                         p_fechaDesde IN DATE,
                                         p_fechaHasta IN DATE,
                                         p_canal      IN pedidos.id_canal%TYPE,
                                         cur_out      OUT cursor_type) IS

      v_Modulo    VARCHAR2(100) := 'PKG_REPORTE_CENTRAL.GetInformeJefeVentasGeneral';
      v_idReporte VARCHAR2(40)  := '';

   BEGIN

      v_idReporte := PKG_REPORTE_CENTRAL.SetSucursalesSeleccionadas(p_sucursales);

      OPEN cur_out FOR
        SELECT su.cdsucursal,
                    su.dssucursal,
                    re.cdregion,
                    re.dsregion,
                    SUM(pe.ammonto) importePedido,
                    SUM(df.amdocumento) importeFactura
           FROM documentos                dp,
                movmateriales             mm,
                pedidos                   pe,
                documentos                df,
                tbltmp_sucursales_reporte rs,
                sucursales                su,
                tblregion                 re
          WHERE dp.iddoctrx        = pe.iddoctrx
            AND dp.cdcomprobante   = 'PEDI'
            /*AND pe.id_canal in ('VE','TE')*/
            AND  pe.id_canal in ( select * from (SELECT SUBSTR(txt, INSTR (txt, ',', 1, level ) + 1,
                                                     INSTR (txt, ',', 1, level + 1) - INSTR (txt, ',', 1, level) -1) AS u
                                  FROM (SELECT replace(','|| replace(p_canal,' ','') || ',','''','') AS txt
                                        FROM dual )
                                  CONNECT BY level <= LENGTH(txt)-LENGTH(REPLACE(txt,',',''))-1
                                  ))
            AND pe.idpedido        = mm.idpedido (+)
            AND mm.idmovmateriales = df.idmovmateriales (+)
            AND su.cdregion        = re.cdregion
            AND dp.cdsucursal      = su.cdsucursal
            AND rs.idreporte       = v_idReporte
            AND rs.cdsucursal      = su.cdsucursal
            AND (p_idCuenta is null OR p_idCuenta = dp.idcuenta)
            AND dp.identidadreal = nvl(p_identidad, dp.identidadreal )
            AND nvl(dp.idpersona,'X') = nvl(p_idPersona,nvl(dp.idpersona,'X') )
            AND dp.dtdocumento BETWEEN TRUNC(p_fechaDesde)
                                   AND TRUNC(p_fechaHasta + 1)
           GROUP BY su.cdsucursal,
                    su.dssucursal,
                    re.cdregion,
                    re.dsregion;

      PKG_REPORTE_CENTRAL.CleanSucursalesSeleccionadas(v_idReporte);

   EXCEPTION
      WHEN OTHERS THEN
         n_pkg_vitalpos_log_general.write(2, 'Modulo: ' || v_Modulo || ' Error: ' || SQLERRM);
         RAISE;
   END GetInformeJefeVentasGeneral;


   /*****************************************************************************************************************
   * Retorna un reporte de pedidos hechos por TLK a nombre de Vendedor o Comisionista
   * %v 24/02/2017 - IAquilano
   ******************************************************************************************************************/
   Procedure getpedidostlkveco (p_fechadesde IN documentos.dtdocumento%type,
                                p_fechahasta IN documentos.dtdocumento%type,
                                p_cur_out      OUT cursor_type) is

   v_Modulo    VARCHAR2(100) := 'PKG_REPORTE_CENTRAL.getpedidostlkveco';

   BEGIN
     OPEN p_cur_out FOR
          WITH doc_cliente AS
           (
            select d.iddoctrx, d.idcuenta, d.cdsucursal,  e.identidad, e.cdcuit, e.dsrazonsocial
            from documentos d, entidades e
            where d.identidadreal = e.identidad
            and   d.identidadreal is not null
            and   d.cdcomprobante = 'PEDI'
            and   d.dtdocumento BETWEEN TRUNC(p_fechaDesde) AND TRUNC(p_fechaHasta + 1)
            )
        SELECT * FROM (SELECT
                            su.dssucursal sucursal,
                            do.cdcuit,
                            do.dsrazonsocial cliente,
                            e.dsrazonsocial A_Nombre_De,
                            trunc(pe.dtaplicacion) Fecha,
                            p.dsapellido||' '||p.dsnombre ingresado_por,
                            ec.dsestado estado,
                            SUM(nvl(pe.ammonto,0)) Monto,
                            pe.id_canal Canal
                       FROM
                            pedidos                   pe,
                            doc_cliente               do,
                            direccionesentidades      de,
                            localidades               lo,
                            estadocomprobantes        ec,
                            sucursales                su,
                            personas                  p,
                            entidades                 e
                       WHERE pe.iddoctrx = do.iddoctrx
                       AND pe.icestadosistema = ec.cdestado
                       AND ec.cdcomprobante = 'PEDI'
                       AND do.identidad = de.identidad
                       AND de.cdtipodireccion = pe.cdtipodireccion
                       AND de.sqdireccion = pe.sqdireccion
                       AND lo.cdpais = de.cdpais
                       AND lo.cdprovincia = de.cdprovincia
                       AND lo.cdlocalidad = de.cdlocalidad
                       AND do.cdsucursal = su.cdsucursal
                       AND pe.idcomisionista = e.identidad
                       AND pe.idpersonaresponsable = p.idpersona
                       AND pe.dtaplicacion BETWEEN TRUNC(p_fechaDesde) AND TRUNC(p_fechaHasta + 1)
                       AND pe.id_canal in ('CO') -- Canal COMISIONISTA
                       AND pe.idpersonaresponsable is not null -- entró por Contact Center
                    GROUP BY
                           su.dssucursal,
                           do.cdcuit,
                           do.dsrazonsocial,
                           e.dsrazonsocial,
                           trunc(pe.dtaplicacion),
                           p.dsapellido||' '||p.dsnombre,
                           ec.dsestado,
                           pe.id_canal
                    ORDER BY su.dssucursal, ec.dsestado, trunc(pe.dtaplicacion), do.cdcuit)
     UNION ALL
        SELECT * FROM (SELECT
                           su.dssucursal sucursal,
                           do.cdcuit,
                           do.dsrazonsocial cliente,
                           p.dsapellido||' '||p.dsnombre " A_Nombre_De",
                           trunc(pe.dtaplicacion) Fecha,
                           pp.dsapellido||' '||pp.dsnombre "INGRESADO POR",
                           ec.dsestado estado,
                           SUM(nvl(pe.ammonto,0)) Monto,
                           pe.id_canal Canal
                      FROM
                           pedidos                   pe,
                           doc_cliente               do,
                           direccionesentidades      de,
                           localidades               lo,
                           estadocomprobantes        ec,
                           sucursales                su,
                           personas                  p,
                           personas                  pp
                      WHERE pe.iddoctrx = do.iddoctrx
                        AND pe.icestadosistema = ec.cdestado
                        AND ec.cdcomprobante = 'PEDI'
                        AND do.identidad = de.identidad
                        AND de.cdtipodireccion = pe.cdtipodireccion
                        AND de.sqdireccion = pe.sqdireccion
                        AND lo.cdpais = de.cdpais
                        AND lo.cdprovincia = de.cdprovincia
                        AND lo.cdlocalidad = de.cdlocalidad
                        AND do.cdsucursal = su.cdsucursal
                        AND pe.idvendedor = p.idpersona
                        AND pe.idpersonaresponsable = pp.idpersona
                        AND pe.dtaplicacion BETWEEN TRUNC(p_fechaDesde) AND TRUNC(p_fechaHasta + 1)
                        AND pe.id_canal in ('VE') -- Canal VENDEDOR
                        AND pe.idpersonaresponsable <> pe.idvendedor -- entró por Contact Center
                      GROUP BY
                            su.dssucursal,
                            do.cdcuit,
                            do.dsrazonsocial,
                            pp.idpersona,
                            trunc(pe.dtaplicacion),
                            p.dsapellido||' '||p.dsnombre,
                            pp.dsapellido||' '||pp.dsnombre,
                            ec.dsestado,
                            pe.id_canal
                      ORDER BY su.dssucursal, ec.dsestado, trunc(pe.dtaplicacion), do.cdcuit);

     EXCEPTION
      WHEN OTHERS THEN
         n_pkg_vitalpos_log_general.write(2, 'Modulo: ' || v_Modulo || ' Error: ' || SQLERRM);
         RAISE;

  END getpedidostlkveco;
   /*****************************************************************************************************************
   * %v 23/09/2021 ChM - Retorna el id pedido VTEX de los pedidos EC
   ******************************************************************************************************************/
   FUNCTION IDVTEX (p_idpedido      pedidos.idpedido%type) return varchar2 IS
     v_idpedido_vtex vtexorders.pedidoid_vtex%type:=' ';
     v_transid      pedidos.transid%type;
   BEGIN
     select p.transid
       into v_transid 
       from Pedidos p
      where p.idpedido=p_idpedido
        --solo pedidos de origen VTEX
        and p.icorigen=4; 
     -- sino es hijo el transid es el id_VTEX
     if instr(v_transid,'_HIJO') = 0 then   
        v_idpedido_vtex:= v_transid;
     else
        select o.pedidoid_vtex 
          into v_idpedido_vtex
          from vtexorders o   
         where o.idpedido_pos like '%'||SUBSTR(v_transid,1,(instr(v_transid,'_HIJO')-1))||'%';     
     end if;   
     RETURN '-'||v_idpedido_vtex;
     EXCEPTION 
       WHEN OTHERS THEN
         RETURN ' ';
     END;  
   
   /*****************************************************************************************************************
   * Retorna un reporte de pedidos confirmados, pendientes y cancelados
   * %v 06/08/2014 - MatiasG: v1.0
   * %v 21/04/2015 - MartinM: v1.1 - Se modifica las clausulas que contenian los parametros
   *                                 cuenta entidad y persona para mejorar su performance
   * %v 31/03/2016 - APW: Elimino la búsqueda de documentos pedido sin identidadreal
   * %v 18/07/2016 - RLC: Agrego parámetro Canal y columna Telemarketer
   * %v 02/08/2016 - APW: Cambio join de documentos y clientes, no uso más el with
   * %v 07/05/2020 - LM: se corrige para que devuelva datos si no tiene persona en documento pedido
   * %v 13/05/2020 - APW: se agegra marca de origen 
   * %v 21/04/2021 - APW: mejoro marca de origen 
   * %v 25/10/2021 - APW: cambio busqueda de cliente por entidad real
   * %v 26/05/2022 - ChM incorporo medio de pago del pedido POSG - 913
   ******************************************************************************************************************/
   PROCEDURE GetInformeJefeVentasDetalle(p_sucursal   IN sucursales.cdsucursal%TYPE,
                                         p_identidad  IN entidades.identidad%TYPE,
                                         p_idPersona  IN personas.idpersona%TYPE,
                                         p_idCuenta   IN tblcuenta.idcuenta%TYPE,
                                         p_fechaDesde IN DATE,
                                         p_fechaHasta IN DATE,
                                         p_canal      IN pedidos.id_canal%TYPE,
                                         cur_out      OUT cursor_type) IS
      v_Modulo    VARCHAR2(100) := 'PKG_REPORTE_CENTRAL.GetInformeJefeVentasDetalle';
   BEGIN
      OPEN cur_out FOR
         SELECT su.cdsucursal,
                su.dssucursal,
                re.cdregion,
                re.dsregion,
                e.cdcuit,
                e.dsrazonsocial,
                ec.dsestado estado,
                pkg_pedido_central.GetNombreResponsable (pe.id_canal, pe.idpersonaresponsable, pe.idvendedor, pe.idcomisionista) responsableventa,
                Decode(dp.idpersona,Null,Null,Pkg_reporte_central.GetPersona(dp.idpersona)) Telemarketer,
                pe.id_canal canal,
                trunc(pe.dtaplicacion) dtpedido,
                dp.amdocumento        importePedido,
                trunc(df.dtdocumento) dtfactura,
                df.cdcomprobante      tipoFactura,
                df.cdpuntoventa       puntoVenta,
                GetDescDocumento(df.iddoctrx)      comprobanteFactura,
                df.amdocumento        importeFactura,
                pe.idpedido,
                mm.idmovmateriales,
                 case
                  when pe.icorigen=4 then 'EC'
                  when pe.icorigen=5 then 'VD'
                  when pe.icorigen=0 then 'VM'
                  when pe.icorigen is null then 'CC'
                else
                  null
                end as vitaldigital,
                nvl(mp.dsmediopago,' ') mediodepago     
           FROM documentos                dp,
                movmateriales             mm,
                pedidos                   pe,
                documentos                df,
                sucursales                su,
                tblregion                 re,
                estadocomprobantes        ec,
                entidades                 e,
                --ChM incorporo medio de pago del pedido 26/05/2022
                ( select mp.idpedido,vm.dsmediopago
                    from pedidomediodepago mp, vtexmediodepago vm
                   where vm.idmediopago = mp.idmediopago
                     and vm.id_canal = mp.id_canal) mp  
          WHERE dp.iddoctrx                = pe.iddoctrx
            and dp.identidadreal = e.identidad
            and dp.cdcomprobante = 'PEDI'            
            and pe.idpedido = mp.idpedido (+)    
            and dp.dtdocumento BETWEEN TRUNC(p_fechaDesde) AND TRUNC(p_fechaHasta + 1)
            and pe.id_canal in ( select * from (SELECT SUBSTR(txt, INSTR (txt, ',', 1, level ) + 1,
                                                   INSTR (txt, ',', 1, level + 1) - INSTR (txt, ',', 1, level) -1) AS u
                                FROM (SELECT replace(','|| replace(p_canal,' ','') || ',','''','') AS txt
                                      FROM dual )
                                CONNECT BY level <= LENGTH(txt)-LENGTH(REPLACE(txt,',',''))-1
                                ))
            AND pe.idpedido                = mm.idpedido        (+)
            AND mm.idmovmateriales         = df.idmovmateriales (+)
            AND dp.cdsucursal              = su.cdsucursal
            AND ec.cdcomprobante           = 'PEDI'
            AND ec.cdestado                = pe.icestadosistema
            AND su.cdregion                = re.cdregion
            AND su.cdsucursal              = p_sucursal
            AND (p_idCuenta is null OR p_idCuenta = dp.idcuenta)
            AND dp.identidadreal = nvl(p_identidad, dp.identidadreal )
            --AND nvl(dp.idpersona,'X') = nvl(p_idPersona,nvl(dp.idpersona,'X') )
            AND nvl(pe.idpersonaresponsable,'X') = nvl(p_idPersona,nvl(pe.idpersonaresponsable,'X'))
            AND pe.dtaplicacion BETWEEN TRUNC( p_fechaDesde )AND TRUNC( p_fechaHasta + 1 )
       ORDER BY pe.dtaplicacion;
   EXCEPTION
      WHEN OTHERS THEN
         n_pkg_vitalpos_log_general.write(2, 'Modulo: ' || v_Modulo || ' Error: ' || SQLERRM);
         RAISE;
   END GetInformeJefeVentasDetalle;

   /*****************************************************************************************************************
   * Retorna un reporte de egresos del tesoro
   * %v 27/08/2014 - MatiasG: v1.0
   ******************************************************************************************************************/
   PROCEDURE GetEgresosTesoro(p_sucursales IN VARCHAR2,
                              p_cdMedio    IN tblconfingreso.cdmedio%TYPE,
                              p_fechaDesde IN DATE,
                              p_fechaHasta IN DATE,
                              p_cur_out    OUT cursor_type) IS
      v_Modulo    VARCHAR2(100) := 'PKG_REPORTE_CENTRAL.GetEgresosTesoro';
      v_idReporte VARCHAR2(40) := '';
   BEGIN
      v_idReporte := PKG_REPORTE_CENTRAL.SetSucursalesSeleccionadas(p_sucursales);
      OPEN p_cur_out FOR
         SELECT su.dssucursal,
             te.dtoperacion,
                pkg_ingreso_central.GetDescIngreso(te.cdconfingreso, su.cdsucursal) dsingreso,
                tc.dstransportadora,
                DECODE(dc.cddestinocaudal, '000', 'Maycar', '001', 'Fondo Fijo', 'Banco') dsbanco,
                SUM(te.amconfirmado)*-1 confirmado
           FROM tbltesoro                 te,
                tbltransportecaudales     tc,
                tbldestinocaudal          dc,
                tblconfingreso            ci,
                tbltmp_sucursales_reporte rs,
                sucursales                su
          WHERE te.cddestinocaudal = dc.cddestinocaudal
            AND tc.idtransportadoracaudales = te.idtransportadoracaudales
            AND te.idtransportadoracaudales IS NOT NULL
            AND te.cddestinocaudal IS NOT NULL
            AND te.cdconfingreso = ci.cdconfingreso
            AND te.cdsucursal = ci.cdsucursal
            AND te.cdsucursal = su.cdsucursal
            AND rs.cdsucursal = su.cdsucursal
            AND rs.idreporte = v_idReporte
        AND te.dtoperacion BETWEEN trunc(p_fechaDesde) AND trunc(p_fechaHasta + 1)
        AND ci.cdaccion = '4' --egreso
            AND ci.cdmedio = NVL(p_cdMedio, ci.cdmedio)
          GROUP BY su.dssucursal,
                te.dtoperacion,
                   pkg_ingreso_central.GetDescIngreso(te.cdconfingreso, su.cdsucursal),
                   tc.dstransportadora,
                   DECODE(dc.cddestinocaudal, '000', 'Maycar', '001', 'Fondo Fijo', 'Banco');

      PKG_REPORTE_CENTRAL.CleanSucursalesSeleccionadas(v_idReporte);
   EXCEPTION
      WHEN OTHERS THEN
         n_pkg_vitalpos_log_general.write(2, 'Modulo: ' || v_Modulo || ' Error: ' || SQLERRM);
         RAISE;
   END GetEgresosTesoro;

 /*****************************************************************************************************************
 * Retorna los datos de la persona para el control de puertas, utilizado para los reportes
 * %v 29/12/2014 - JBodnar: v1.0
 ******************************************************************************************************************/
  procedure GetDatosFacturista (p_cdsucursal in sucursales.cdsucursal%type,
                                p_cursor_out out cursor_type) as

   v_modulo           varchar2(100) := 'PKG_REPORTE_CENTRAL.GetDatosFacturista';

  BEGIN
    open p_cursor_out for
    select  p.idpersona,
            p.dsapellido ||','|| p.dsnombre Nombre,
            nvl(p.cdlegajo,'0000') Legajo
    from  personas p, rolespersonas rp ,CuentasUsuarios cu
    where p.idpersona = rp.idpersona
    and   p.idpersona = cu.idpersona
    and   cu.icestadousuario = 1
    and   cu.cdsucursal = p_cdsucursal
    and   p.IcActivo = 1
    and   rp.cdrol = 12
    order by p.dsapellido;

  EXCEPTION WHEN OTHERS THEN
     n_pkg_vitalpos_log_general.write(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM);
     raise;
  END GetDatosFacturista;

   /***************************************************************************************************
   *  OBtiene las excenciones impositivas
   *  %v 17/10/2014 MatiasG - v1.0
   **************************************************************************************************/
   PROCEDURE GetExcencionesImpositivas(p_idCuenta  IN tblcuenta.idcuenta%TYPE,
                                       p_cur_out   OUT cursor_type) IS
      v_modulo     VARCHAR2(100) := 'PKG_ADMINISTRACION.GetExcencionesImpositivas';
    v_cdSucursal   sucursales.cdsucursal%TYPE;
    v_DBLink       sucursales.servidor%TYPE;
    v_identidad    entidades.identidad%TYPE;
    v_nombrecuenta tblcuenta.idcuenta%TYPE;
    v_query        VARCHAR2(2000);
   BEGIN

      SELECT cu.cdsucursal, cu.identidad, cu.nombrecuenta
      INTO v_cdSucursal, v_identidad, v_nombrecuenta
       FROM tblcuenta cu
     WHERE cu.idcuenta = p_idCuenta;

    SELECT su.servidor
        INTO v_DBLink
        FROM sucursales su
       WHERE TRIM(su.cdsucursal) = TRIM(v_cdsucursal)
         AND su.servidor IS NOT NULL;

      v_query := 'SELECT ex.amminimo, ee.dsrazonsocial, ex.vltasa, ex.icestado, ap.dsaplicacion, ex.cdtasa, ap.dtvigencia, ex.dtvigenciahasta, ap.icconvenio, ''' ||v_nombrecuenta||''' nombrecuenta '||
                   'FROM excencionesimpuestos@'|| v_DBLink ||' ex, entidades@'|| v_DBLink ||' ee, aplicacionimpuestos@'|| v_DBLink ||' ap '||
                  'WHERE ex.identidad = ee.identidad '||
                    'AND ex.cdimpuesto = ap.cdimpuesto '||
                    'AND ex.cdtasa = ap.cdtasa '||
                    'AND ex.sqtasa = ap.sqtasa '||
                    'AND ex.dtvigencia = ap.dtvigencia '||
                    'AND ex.identidad = '''|| v_identidad ||'''';

      OPEN p_cur_out FOR v_query;

   EXCEPTION
      WHEN OTHERS THEN
         n_pkg_vitalpos_log_general.write(2, 'Modulo: ' || v_modulo || '  Error: ' || SQLERRM);
         RAISE;
   END GetExcencionesImpositivas;

   /*****************************************************************************************************************
   * Retorna un reporte con el detalle los movimientos de una caja
   * %v 06/08/2014 - MatiasG: v1.0
   * %v 19/06/2015 - MartinM: v1.1 - Rediseño del Query
   ******************************************************************************************************************/
  PROCEDURE GetMovimientosDeCajaGeneral(p_idpersona  IN tbltesoro.idpersona%TYPE,
                            p_cdMedio    IN tblconfingreso.cdmedio%TYPE,
                            p_fechaDesde IN DATE,
                            p_fechaHasta IN DATE,
                            p_idCuenta   IN tblcuenta.idcuenta%TYPE,
                            p_sucursales IN VARCHAR2,
                            p_cur_out    OUT cursor_type) IS
      v_Modulo VARCHAR2(100) := 'PKG_REPORTE.GetMovimientosDeCajaGeneral';
      v_idReporte VARCHAR2(40) := '';
   BEGIN
      v_idReporte := SetSucursalesSeleccionadas(p_sucursales);

    OPEN p_cur_out FOR
select *
  from (select distinct
               tmc.dtmovimiento                  dtmovimiento , --Apertura y Cierre
               p.dsapellido || ' '|| p.dsnombre  cajero       ,
               null                              cdcuit       ,
               null                              dsrazonsocial,
               null                              nombrecuenta ,
               decode(tmc.cdoperacioncaja,
                      1, 'Apertura',
                      4, 'Cierre')               descripcion  ,
               null                              amdocumento  ,
               tmc.ammovimiento                  amingreso    ,
               null                              estado       ,
               s.cdsucursal                      cdsucursal   ,
               s.dssucursal                      dssucrusal   ,
               tmc.idmovcaja                     idtransaccion,
               cast(tmc.cdoperacioncaja as number)      orden
          from tblmovcaja                tmc,
               personas                  p  ,
               tbltmp_sucursales_reporte tsr,
               sucursales                s
         where  tmc.cdoperacioncaja     in (1,4)
           and  tmc.idpersonaresponsable = p.idpersona  (+)
           and (tmc.idpersonaresponsable = p_idpersona or p_idpersona is null)
           and  tmc.cdsucursal           = s.cdsucursal (+)
           and  tsr.cdsucursal           = tmc.cdsucursal
           and  tsr.idreporte            = v_idReporte
           and  tmc.dtmovimiento   BETWEEN trunc(p_fechaDesde)
                                       AND trunc(p_fechaHasta + 1)
        union all --Muestro las diferencias de cierre de caja
           select distinct
                  tmc.dtmovimiento                                  dtmovimiento  ,
                    p.dsapellido || ' '|| p.dsnombre                cajero        ,
                  null                                              cdcuit        ,
                  null                                              dsrazonsocial ,
                  null                                              nombrecuenta  ,
                  'Diferencia ' || tdc.dsingreso                    descripcion   ,
                  tdc.amdiferenciacaja                              amdocumento   ,
                  null                                              amingreso     ,
                  null                                              estado        ,
                    s.cdsucursal                                    cdsucursal    ,
                    s.dssucursal                                    dssucursal    ,
                  tmc.idmovcaja                                     idtransaccion ,
                  5                                                 orden
             from tblmovcaja                tmc,
                  personas                  p  ,
                  tbltmp_sucursales_reporte tsr,
                  sucursales                s  ,
                  tbldiferenciacaja         tdc
            where tmc.idmovcaja             = tdc.idmovcaja
              and tmc.cdoperacioncaja       = 4 --cierre
              and tmc.idpersonaresponsable  = p.idpersona  (+)
              and (tmc.idpersonaresponsable = p_idpersona or p_idpersona is null)
              and  tmc.cdsucursal           = s.cdsucursal (+)
              and  tsr.cdsucursal           = tmc.cdsucursal
              and  tsr.idreporte            = v_idReporte
              and  tmc.dtmovimiento   BETWEEN trunc(p_fechaDesde)
                                          AND trunc(p_fechaHasta + 1)
        union all
           select tt.dttransaccion                                                                       dtmovimiento  ,--Egresos e Ingresos
                  p.dsapellido || ' '|| p.dsnombre                                                       cajero        ,
                  e.cdcuit                                                                               cdcuit        ,
                  e.dsrazonsocial                                                                        dsrazonsocial ,
                  tc.nombrecuenta                                                                        nombrecuenta  ,
                  coalesce(PKG_REPORTE_CENTRAL.GetDescDocumento(trx.iddoctrx),
                            pkg_ingreso_central.GetDescIngreso(trx.cdconfingreso,trx.cdsucursal))        descripcion   ,
                  trx.amdocumento                                                                        amdocumento   ,
                  trx.amingreso                                                                          amingreso     ,
                  null                                                                                   estado        ,
                  s.cdsucursal                                                                           cdsucursal    ,
                  s.dssucursal                                                                           dssucrusal    ,
                  tt.idtransaccion                                                                       idtransaccion ,
                  case when trx.iddoctrx is not null then 2
                    else 3
                  end orden
             from tbltransaccion                     tt      ,
                  (select d.iddoctrx        iddoctrx     ,
                          null              idingreso    ,
                          d.amdocumento     amdocumento  ,
                          null              amingreso    ,
                          d.idtransaccion   idtransaccion,
                          d.idcuenta        idcuenta     ,
                          d.cdsucursal      cdsucursal   ,
                          null              cdconfingreso
                    from documentos d
                   where d.cdcomprobante <> 'PGCO'
                    union all
                   select d.iddoctrx        iddoctrx     ,
                          null              idingreso    ,
                          null              amdocumento  ,
                          d.amdocumento     amingreso    ,
                          d.idtransaccion   idtransaccion,
                          d.idcuenta        idcuenta     ,
                          d.cdsucursal      cdsucursal   ,
                          null              cdconfingreso
                    from documentos d
                   where d.cdcomprobante = 'PGCO'
                    union all
                    select null             iddoctrx     ,
                           ti.idingreso     idingreso    ,
                           null             amdocumento  ,
                           ti.amingreso     amingreso    ,
                           ti.idtransaccion idtransaccion,
                           ti.idcuenta      idcuenta     ,
                           ti.cdsucursal    cdsucursal   ,
                           ti.cdconfingreso cdconfingreso
                      from tblingreso ti) trx,
                  tblcuenta                          tc      ,
                  entidades                          e       ,
                  personas                           p       ,
                  sucursales                         s
            where tt.idtransaccion         =     trx.idtransaccion
              and tt.idpersonaresponsable  =     p.idpersona     (+)
              and (tt.idpersonaresponsable =  p_idpersona or p_idpersona is null)
              and  tt.dttransaccion  BETWEEN trunc(p_fechaDesde)
                                         AND trunc(p_fechaHasta + 1)
              and  trx.idcuenta             =      tc.idcuenta      (+)
              and  tc.identidad             =       e.identidad     (+)
              and  tt.cdsucursal            =       s.cdsucursal    (+)
        union all
           select tt.dttransaccion                                                                       dtmovimiento  ,--Egresos e Ingresos
                  min(p.dsapellido || ' '|| p.dsnombre)                                                  cajero        ,
                  min(e.cdcuit)                                                                          cdcuit        ,
                  min(e.dsrazonsocial)                                                                   dsrazonsocial ,
                  min(tc.nombrecuenta)                                                                   nombrecuenta  ,
                  case when sum(nvl(trx.amingreso,0))   > sum(nvl(trx.amdocumento,0)) then
                            'Crédito a cuenta'
                  else      'Débito de saldo'  end                                                       descripcion   ,
                  case when sum(nvl(trx.amingreso,0))   > sum(nvl(trx.amdocumento,0)) then
                            sum(nvl(trx.amingreso,0))   - sum(nvl(trx.amdocumento,0)) end                amdocumento   ,
                  case when sum(nvl(trx.amdocumento,0)) > sum(nvl(trx.amingreso,0)) then
                            sum(nvl(trx.amdocumento,0)) - sum(nvl(trx.amingreso,0)) end                  amingreso     ,
                  null                                                                                   estado        ,
                  min(s.cdsucursal)                                                                      cdsucursal    ,
                  min(s.dssucursal)                                                                      dssucrusal    ,
                  min(tt.idtransaccion)                                                                  idtransaccion ,
                  10                                                                                     orden
             from tbltransaccion                     tt      ,
                  (select d.iddoctrx        iddoctrx     ,
                          null              idingreso    ,
                          d.amdocumento     amdocumento  ,
                          null              amingreso    ,
                          d.idtransaccion   idtransaccion,
                          d.idcuenta        idcuenta     ,
                          d.cdsucursal      cdsucursal   ,
                          null              cdconfingreso
                    from documentos d
                   where d.cdcomprobante <> 'PGCO'
                    union all
                   select d.iddoctrx        iddoctrx     ,
                          null              idingreso    ,
                          null              amdocumento  ,
                          d.amdocumento     amingreso    ,
                          d.idtransaccion   idtransaccion,
                          d.idcuenta        idcuenta     ,
                          d.cdsucursal      cdsucursal   ,
                          null              cdconfingreso
                    from documentos d
                   where d.cdcomprobante = 'PGCO'
                    union all
                    select null             iddoctrx     ,
                           ti.idingreso     idingreso    ,
                           null             amdocumento  ,
                           ti.amingreso     amingreso    ,
                           ti.idtransaccion idtransaccion,
                           ti.idcuenta      idcuenta     ,
                           ti.cdsucursal    cdsucursal   ,
                           ti.cdconfingreso cdconfingreso
                      from tblingreso ti) trx,
                  tblcuenta                          tc      ,
                  entidades                          e       ,
                  personas                           p       ,
                  tbltmp_sucursales_reporte          tsr     ,
                  sucursales                         s
            where tt.idtransaccion         =     trx.idtransaccion
              and tt.idpersonaresponsable  =     p.idpersona     (+)
              and (tt.idpersonaresponsable =  p_idpersona or p_idpersona is null)
              and  tt.dttransaccion  BETWEEN trunc(p_fechaDesde)
                                         AND trunc(p_fechaHasta + 1)
              and  trx.idcuenta            =      tc.idcuenta      (+)
              and  tc.identidad            =       e.identidad     (+)
              and  tt.cdsucursal           =       s.cdsucursal    (+)
              and  tsr.cdsucursal          =      tt.cdsucursal
              and  tsr.idreporte           =         v_idReporte
          group by tt.dttransaccion
          having sum(nvl(trx.amingreso,0)) - sum(nvl(trx.amdocumento,0)) <> 0 )
          order by dtmovimiento, orden;

      CleanSucursalesSeleccionadas(v_idReporte);
  EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2, 'Modulo: ' || v_Modulo || ' Error: ' || SQLERRM);
      RAISE;
  END GetMovimientosDeCajaGeneral;

   /*****************************************************************************************************************
   * Retorna un reporte con el listado de factura que no fueron cotroladas (piqueadas) en la puerta
   * %v 06/08/2014 - MatiasG: v1.0
   * %v 08/09/2015 - APW - Filtra solo las de canal SA y solo NC y FC
   * %v 19/10/2015 - APW - Agrego join con estadocomprobantes en lugar de decode
   * %v 11/02/2016 - APW - No muestra las FC de flete
   ******************************************************************************************************************/
  PROCEDURE GetListadoDeFacturasGeneral(p_idCajero   IN     documentos.idpersona%TYPE,
                            p_identidad  IN     documentos.identidad%TYPE,
                            p_idCuenta   IN     documentos.idcuenta%TYPE,
                            p_CF         IN     INTEGER,
                            p_fechaDesde IN DATE,
                            p_fechaHasta IN DATE,
                            p_sucursales IN VARCHAR2,
                            p_cur_out    OUT cursor_type) IS
    v_Modulo VARCHAR2(100) := 'PKG_REPORTE.GetListadoDeFacturasGeneral';
      v_idReporte VARCHAR2(40) := '';
   BEGIN
      v_idReporte := SetSucursalesSeleccionadas(p_sucursales);

    IF p_CF = 0 THEN
      --Facturas de cliente
      OPEN p_cur_out FOR
        SELECT do.dtdocumento,
             GetDescDocumento(do.iddoctrx) descDocumento,
             do.amdocumento,
             ec.dsestado estado,
             --DECODE(do.cdestadocomprobante,1,'Creada',2,'Impresa',3,'Anulado',4,'Cancelada Parcialmente',5,'Cancelada') estado,
             GetPersona(do.idpersona) persona,
             mm.cdcaja,
             ee.cdcuit,
             ee.dsrazonsocial,
             su.dssucursal
          FROM documentos do, movmateriales mm, tblcuenta cu, entidades ee, sucursales su,tbltmp_sucursales_reporte rs, estadocomprobantes ec
         WHERE do.idmovmateriales = mm.idmovmateriales
          AND do.idcuenta = cu.idcuenta
          AND cu.cdtipocuenta IN ('1','2') --Cliente y Fidelizado
          AND do.identidadreal = ee.identidad
          AND do.cdsucursal = su.cdsucursal
          AND rs.idreporte = v_idReporte
          AND rs.cdsucursal= su.cdsucursal
          AND do.idpersona = NVL(p_idCajero, do.idpersona)
          AND do.idcuenta = NVL(p_idCuenta, cu.idcuenta)
          AND do.identidadreal = NVL(p_identidad, do.identidadreal)
          AND do.dtdocumento BETWEEN TRUNC(p_fechaDesde) AND TRUNC(p_fechaHasta + 1)
          AND (do.cdcomprobante like 'FC%' or do.cdcomprobante like 'NC%')
          and do.cdcomprobante = ec.cdcomprobante
          and do.cdestadocomprobante = ec.cdestado
          AND exists (SELECT 1 FROM tblmovcuenta mc where mc.iddoctrx=do.iddoctrx and mc.idcuenta=do.idcuenta) --Transaccionadas
          AND not exists (SELECT 1 FROM tbldocumento_salida ds where ds.iddoctrx=do.iddoctrx) --No escaneadas
          and not exists (select 1 from tbldetalleguia dg where dg.iddoctrx = do.iddoctrx and dg.icflete = 1) -- NO es de flete
          and mm.id_canal = 'SA'; -- solo las de salón
      ELSIF p_CF = 1 THEN
      --Facturas de Consumidor Final
      OPEN p_cur_out FOR
        SELECT do.dtdocumento,
             GetDescDocumento(do.iddoctrx) descDocumento,
             do.amdocumento,
             ec.dsestado estado,
             --DECODE(do.cdestadocomprobante,1,'Creada',2,'Impresa',3,'Anulado',4,'Cancelada Parcialmente',5,'Cancelada') estado,
             GetPersona(do.idpersona) persona,
             mm.cdcaja,
             ee.cdcuit,
             ee.dsrazonsocial,
             su.dssucursal
          FROM documentos do, movmateriales mm, tblcuenta cu, entidades ee, sucursales su, tbltmp_sucursales_reporte rs, estadocomprobantes ec
         WHERE do.idmovmateriales = mm.idmovmateriales
          AND do.idcuenta = cu.idcuenta
          AND do.identidadreal = ee.identidad
          AND EsCFAnonimo(do.identidad) = 1
          AND do.cdsucursal = su.cdsucursal
          AND rs.idreporte = v_idReporte
          AND rs.cdsucursal = su.cdsucursal
          AND do.idpersona = NVL(p_idCajero, do.idpersona)
          AND do.idcuenta = NVL(p_idCuenta, cu.idcuenta)
          AND do.identidadreal = NVL(p_identidad, do.identidadreal)
          AND do.dtdocumento BETWEEN TRUNC(p_fechaDesde) AND TRUNC(p_fechaHasta + 1)
          AND (do.cdcomprobante like 'FC%' or do.cdcomprobante like 'NC%')
          and do.cdcomprobante = ec.cdcomprobante
          and do.cdestadocomprobante = ec.cdestado
          AND exists (SELECT 1 FROM tblmovcuenta mc where mc.iddoctrx=do.iddoctrx and mc.idcuenta=do.idcuenta) --Transaccionadas
          AND not exists (SELECT 1 FROM tbldocumento_salida ds where ds.iddoctrx=do.iddoctrx) --No escaneadas
          and not exists (select 1 from tbldetalleguia dg where dg.iddoctrx = do.iddoctrx and dg.icflete = 1) -- NO es de flete
          and mm.id_canal = 'SA'; -- solo las de salón
    END IF;
      CleanSucursalesSeleccionadas(v_idReporte);
  EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2, 'Modulo: ' || v_Modulo || ' Error: ' || SQLERRM);
      RAISE;
  END GetListadoDeFacturasGeneral;
  /**************************************************************************************************
  * Devuelve el importe no aplicado de un ingreso.
  * Siempre devuelve un valor positivo, la aclaración vale cuando es un EGRESO
  * En caso de un ingreso de acción "ingreso" debe interpretarse como el importe disponible que puede
  * pagar facturas.
  * En caso de un ingreso de acción "egreso", "rechazo" o "reversión" debe  interpretarse como el importe
  * que aún se debe ser descontado de otros ingresos.
  * %v 19/05/2014 - MarianoL
  ***************************************************************************************************/
  function GetImporteNoAplicado(p_idIngreso in tblingreso.idingreso%type) return number
  IS
     v_amIngreso       number := 0;
     v_amAplicado      number := 0;
     v_cdEstadoIngreso tblingreso.cdestado%type;
     v_cdAccion        tblaccioningreso.cdaccion%type;

  BEGIN
     --Buscar los datos del ingreso
     select i.amingreso, i.cdestado, ci.cdaccion
     into   v_amIngreso, v_cdEstadoIngreso, v_cdAccion
     from   tblingreso i,
            tblconfingreso ci
     where  i.idingreso = p_idIngreso
       and  ci.cdconfingreso = i.cdconfingreso;

     --Calcular cuánto fue aplicado
     if v_cdEstadoIngreso = '1' then --No aplicado
        v_amAplicado := 0;
     elsif v_cdEstadoIngreso = '3' then --Totalmente aplicado
        v_amAplicado := v_amIngreso;
     else
        if v_cdAccion = '1' then --Ingreso
           select nvl(sum(c.amimputado),0)
           into   v_amAplicado
           from   tblcobranza c
           where  c.idingreso = p_idIngreso;
        else
           select nvl(sum(c.amimputado),0)
           into   v_amAplicado
           from   tblcobranza c
           where  c.idingreso_pago = p_idIngreso;
        end if;

     end if;

     return abs(v_amIngreso-v_amAplicado);

  exception when others then
     return(0);
  end GetImporteNoAplicado;

   /*****************************************************************************************************************
   * Retorna un reporte de todos los cheques
   * %v 17/05/2015 - MarianoL: v1.0
   * %v 22/10/2015 - APW: v1.1 - Corrección de orden de columnas en no acreditados
   ******************************************************************************************************************/
   PROCEDURE GetChequesTodos(p_cdsucursal      In tblcuenta.cdsucursal%Type,
                             p_identidad    IN entidades.identidad%TYPE,
                             p_idcuenta        In tblcuenta.idcuenta%Type,
                             p_fechaDesde   IN DATE,
                             p_fechaHasta   IN DATE,
                             p_cdmotivorechazo In tblmotivorechazo.cdmotivorechazo%type,
                             p_cur_out      OUT cursor_type) IS

      v_modulo VARCHAR2(100) := 'PKG_REPORTE.GetChequesTodos';

   BEGIN

      OPEN p_cur_out FOR
         select *
         from (
         --Acreditados
         SELECT ii.dtingreso,ee.CDCUIT, ee.DSRAZONSOCIAL, cu.NOMBRECUENTA, ii.AMINGRESO,
                bb.DSBANCO,sb.dssucursal DSSUCURSALBANCO, ch.DTEMISION, ch.dtacreditacion DEPOSITO, ch.VLNUMERO,
                DECODE(ac.icchequepropio,1,'Propio',0,'Tercero') TIPO, '' DSMOTIVORECHAZO,
                su.dssucursal, 'Acreditado' DSESTADO, ac.vlcuentanumero, '' DSOBSERVACION
           FROM tblingreso ii, tblmovcaja mc, personas pe, tblcuenta cu, entidades ee, tblcheque ch,
                tblautorizacioncheque ac, tblbanco bb, tblsucursalesbanco sb, sucursales su, tblconfingreso ci
          WHERE ii.idmovcaja = mc.idmovcaja
            AND su.cdsucursal=ii.cdsucursal
            AND ii.idcuenta = cu.idcuenta
            AND ii.idingreso = ch.idingreso
            and ci.cdsucursal = ii.cdsucursal
            and ci.cdconfingreso = ii.cdconfingreso
            and ci.cdaccion = '1'
            AND cu.cdtipocuenta = '1'
            AND cu.identidad = ee.identidad
            -- no sirve para comisionista -- AND cu.idcuenta = ac.idcuenta
            AND ac.cdbanco = bb.cdbanco
            and sb.cdbanco = bb.cdbanco
            and ii.cdsucursal=nvl(p_cdsucursal,ii.cdsucursal)
            And cu.idcuenta = nvl(p_idcuenta,cu.idcuenta)
            and sb.cdsucursal = ac.cdsucursal
            AND mc.idpersonaresponsable = pe.idpersona
            AND ch.dtacreditacion is not null
            and not exists (select 1 from tblingreso ir where ir.idingresorechazado=ii.idingreso)--No Rechazado
            AND ch.idautorizacion = ac.idautorizacion
            AND cu.identidad = NVL(p_identidad,cu.identidad)
            AND ii.dtingreso BETWEEN TRUNC(nvl(p_fechaDesde,sysdate)) AND TRUNC(nvl(p_fechaHasta,sysdate) + 1)          union
          --No Acreditados
         SELECT ii.dtingreso,ee.CDCUIT, ee.DSRAZONSOCIAL, cu.NOMBRECUENTA, ii.AMINGRESO,
                bb.DSBANCO,sb.dssucursal DSSUCURSALBANCO,ch.DTEMISION, (ch.dtcobro + (sb.qthorasclearing / 24))  DEPOSITO, ch.vlnumero,
                DECODE(ac.icchequepropio,1,'Propio',0,'Tercero') tipo,  '' dsmotivorechazo,
                su.dssucursal, 'No Acreditado' DSESTADO, ac.vlcuentanumero, '' DSOBSERVACION
           FROM tblingreso ii, tblmovcaja mc, personas pe, tblcuenta cu, entidades ee, tblcheque ch,
                tblautorizacioncheque ac, tblbanco bb, tblsucursalesbanco sb, sucursales su, tblconfingreso ci
          WHERE ii.idmovcaja = mc.idmovcaja
            AND su.cdsucursal=ii.cdsucursal
            AND ii.idcuenta = cu.idcuenta
            AND ii.idingreso = ch.idingreso
            and ci.cdsucursal = ii.cdsucursal
            and ci.cdconfingreso = ii.cdconfingreso
            and ci.cdaccion = '1'
            AND cu.cdtipocuenta = '1'
            AND cu.identidad = ee.identidad
            -- no sirve para comisionista -- AND cu.idcuenta = ac.idcuenta
            AND ac.cdbanco = bb.cdbanco
            and sb.cdbanco = bb.cdbanco
            and ii.cdsucursal=nvl(p_cdsucursal,ii.cdsucursal)
            And cu.idcuenta = nvl(p_idcuenta,cu.idcuenta)
            and sb.cdsucursal = ac.cdsucursal
            AND mc.idpersonaresponsable = pe.idpersona
            AND ch.dtacreditacion is null
            and not exists (select 1 from tblingreso ir where ir.idingresorechazado=ii.idingreso) --No Rechazado
            AND ch.idautorizacion = ac.idautorizacion
            AND cu.identidad = NVL(p_identidad,cu.identidad)
            AND ii.dtingreso BETWEEN TRUNC(nvl(p_fechaDesde,sysdate)) AND TRUNC(nvl(p_fechaHasta,sysdate) + 1)
          union
          --Rechazados
         SELECT ii.dtingreso,ee.CDCUIT, ee.DSRAZONSOCIAL, cu.NOMBRECUENTA, ii.AMINGRESO,
                bb.DSBANCO,sb.dssucursal DSSUCURSALBANCO,ch.DTEMISION,nvl(ch.dtacreditacion,(ch.dtcobro + (sb.qthorasclearing / 24))) DEPOSITO, ch.vlnumero,
                DECODE(ac.icchequepropio,1,'Propio',0,'Tercero') tipo, mr.dsmotivorechazo ,
                su.dssucursal, 'Rechazado' DSESTADO, ac.vlcuentanumero, ie.dsobservacion
           FROM tblingreso ii, tblmovcaja mc, personas pe, tblcuenta cu, entidades ee, tblcheque ch,
                tblautorizacioncheque ac, tblbanco bb, tblingresoestado_ac ie,
                tblmotivorechazo mr, tblingreso ri, tblsucursalesbanco sb, sucursales su, tblconfingreso ci
          WHERE ii.idmovcaja = mc.idmovcaja
            AND su.cdsucursal=ii.cdsucursal
            AND ii.idcuenta = cu.idcuenta
            AND ii.idingreso = ch.idingreso
            and ci.cdsucursal = ii.cdsucursal
            and ci.cdconfingreso = ii.cdconfingreso
            and ci.cdaccion = '1'
            AND cu.cdtipocuenta = '1'
            AND cu.identidad = ee.identidad
           -- no sirve para comisionista --  AND cu.idcuenta = ac.idcuenta
            AND ac.cdbanco = bb.cdbanco
            and sb.cdbanco = bb.cdbanco
            And mr.cdmotivorechazo =nvl (p_cdmotivorechazo,mr.cdmotivorechazo)
            and ii.cdsucursal=nvl(p_cdsucursal,ii.cdsucursal)
            And cu.idcuenta = nvl(p_idcuenta,cu.idcuenta)
            and sb.cdsucursal = ac.cdsucursal
            AND mc.idpersonaresponsable = pe.idpersona
            AND ii.idingreso=ie.idingreso --Solo cheques rechazados desde AC
            AND mr.cdmotivorechazo(+)=ie.cdmotivorechazo --Incluye todos los que no tienen motivo de rechazo
            AND ri.idingresorechazado=ii.idingreso
            AND exists (select 1 from tblingreso ir where ir.idingresorechazado=ii.idingreso)  --Rechazado
            AND ch.idautorizacion = ac.idautorizacion
            AND cu.identidad = NVL(p_identidad,cu.identidad)
            AND ii.dtingreso BETWEEN TRUNC(nvl(p_fechaDesde,sysdate)) AND TRUNC(nvl(p_fechaHasta,sysdate) + 1)
           /* UNION
            --JBodnar - 31/08/2015
            --Trae los cheques viejos que se ingresaron manualmente sin mover la cuenta y sin alivio
            SELECT ii.dtingreso,ee.CDCUIT, ee.DSRAZONSOCIAL, cu.NOMBRECUENTA, ii.AMINGRESO,
                  bb.DSBANCO,sb.dssucursal DSSUCURSALBANCO,ch.DTEMISION,nvl(ch.dtacreditacion,(ch.dtcobro + (sb.qthorasclearing / 24))) DEPOSITO, ch.vlnumero,
                  DECODE(ac.icchequepropio,1,'Propio',0,'Tercero') tipo, mr.dsmotivorechazo,
                  su.dssucursal, 'Rechazado' DSESTADO, ac.vlcuentanumero, ie.dsobservacion
             FROM tblingreso ii, tblcuenta cu, entidades ee, tblcheque ch,
                  tblautorizacioncheque ac, tblbanco bb, tblingresoestado_ac ie,
                  tblmotivorechazo mr, tblingreso ri, tblsucursalesbanco sb, sucursales su, tblconfingreso ci
             WHERE  su.cdsucursal=ii.cdsucursal
              AND ii.idcuenta = cu.idcuenta
              AND ii.idingreso = ch.idingreso
              and ci.cdsucursal = ii.cdsucursal
              and ci.cdconfingreso = ii.cdconfingreso
              and ci.cdaccion = '1'
              AND cu.cdtipocuenta = '1'
              AND cu.identidad = ee.identidad
              AND cu.idcuenta = ac.idcuenta
              AND ac.cdbanco = bb.cdbanco
              and sb.cdbanco = bb.cdbanco
              And mr.cdmotivorechazo =nvl (p_cdmotivorechazo,mr.cdmotivorechazo)
              and ii.cdsucursal=nvl(p_cdsucursal,ii.cdsucursal)
              And cu.idcuenta = nvl(p_idcuenta,cu.idcuenta)
              and sb.cdsucursal = ac.cdsucursal
              AND ii.idingreso=ie.idingreso --Solo cheques rechazados desde AC
              AND mr.cdmotivorechazo(+)=ie.cdmotivorechazo --Incluye todos los que no tienen motivo de rechazo
              AND ri.idingresorechazado=ii.idingreso
              AND exists (select 1 from tblingreso ir where ir.idingresorechazado=ii.idingreso)  --Rechazado
              AND ch.idautorizacion = ac.idautorizacion
              AND cu.identidad = NVL(p_identidad,cu.identidad)
              AND ii.dtingreso BETWEEN TRUNC(nvl(p_fechaDesde,sysdate)) AND TRUNC(nvl(p_fechaHasta,sysdate) + 1)         */ )
          order by dssucursal, dtingreso;

      return;

   EXCEPTION WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2, 'Modulo: ' || v_modulo || '  Error: ' || SQLERRM);
      RAISE;
   END GetChequesTodos;


   /*****************************************************************************************************************
   * Retorna un reporte de cheques acreditados (pasó el crearing)
   * %v 17/05/2015 - MarianoL: v1.0
   ******************************************************************************************************************/
   PROCEDURE GetChequesAcreditados(p_cdsucursal      In tblcuenta.cdsucursal%Type,
                                   p_identidad       IN entidades.identidad%TYPE,
                                   p_idcuenta        In tblcuenta.idcuenta%Type,
                                   p_fechaDesde      IN DATE,
                                   p_fechaHasta      IN DATE,
                                   p_cur_out         OUT cursor_type) IS

      v_modulo VARCHAR2(100) := 'PKG_REPORTE.GetChequesAcreditados';

   BEGIN

      OPEN p_cur_out FOR
         SELECT  ii.dtingreso,ee.CDCUIT, ee.DSRAZONSOCIAL, cu.NOMBRECUENTA, ii.AMINGRESO,
                bb.DSBANCO,sb.dssucursal DSSUCURSALBANCO, ch.DTEMISION, ch.dtacreditacion DEPOSITO, ch.VLNUMERO,
                DECODE(ac.icchequepropio,1,'Propio',0,'Tercero') TIPO, '' DSMOTIVORECHAZO,
                su.dssucursal, 'Acreditado' DSESTADO, ac.vlcuentanumero,'' DSOBSERVACION
           FROM tblingreso ii, tblmovcaja mc, personas pe, tblcuenta cu, entidades ee, tblcheque ch,
                tblautorizacioncheque ac, tblbanco bb, tblsucursalesbanco sb, sucursales su, tblconfingreso ci
          WHERE ii.idmovcaja = mc.idmovcaja
            AND su.cdsucursal=ii.cdsucursal
            AND ii.idcuenta = cu.idcuenta
            AND ii.idingreso = ch.idingreso
            and ci.cdsucursal = ii.cdsucursal
            and ci.cdconfingreso = ii.cdconfingreso
            and ci.cdaccion = '1'
            AND cu.cdtipocuenta = '1'
            AND cu.identidad = ee.identidad
            -- no sirve para comisionista -- AND cu.idcuenta = ac.idcuenta
            AND ac.cdbanco = bb.cdbanco
            and sb.cdbanco = bb.cdbanco
            and ii.cdsucursal=nvl(p_cdsucursal,ii.cdsucursal)
            And cu.idcuenta = nvl(p_idcuenta,cu.idcuenta)
            and sb.cdsucursal = ac.cdsucursal
            AND mc.idpersonaresponsable = pe.idpersona
            AND ch.dtacreditacion is not null
            and not exists (select 1 from tblingreso ir where ir.idingresorechazado=ii.idingreso)--No Rechazado
            AND ch.idautorizacion = ac.idautorizacion
            AND cu.identidad = NVL(p_identidad,cu.identidad)
            AND ii.dtingreso BETWEEN TRUNC(nvl(p_fechaDesde,sysdate)) AND TRUNC(nvl(p_fechaHasta,sysdate) + 1)
          order by dssucursal, dtingreso;

      return;

   EXCEPTION WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2, 'Modulo: ' || v_modulo || '  Error: ' || SQLERRM);
      RAISE;
   END GetChequesAcreditados;

   /*****************************************************************************************************************
   * Retorna un reporte de Cheques NO acreditados (No pasó el crearing)
   * %v 17/05/2015 - MarianoL: v1.0
   ******************************************************************************************************************/
   PROCEDURE GetChequesNoAcreditados(p_cdsucursal      In tblcuenta.cdsucursal%Type,
                                     p_identidad    IN entidades.identidad%TYPE,
                                     p_idcuenta        In tblcuenta.idcuenta%Type,
                                     p_fechaDesde   IN DATE,
                                     p_fechaHasta   IN DATE,
                                     p_cur_out      OUT cursor_type) IS

      v_modulo VARCHAR2(100) := 'PKG_REPORTE.GetChequesNoAcreditados';
   BEGIN

      OPEN p_cur_out FOR
         SELECT ii.dtingreso,ee.CDCUIT, ee.DSRAZONSOCIAL, cu.NOMBRECUENTA, ii.AMINGRESO,
                bb.DSBANCO,sb.dssucursal DSSUCURSALBANCO,ch.DTEMISION, (ch.dtcobro + (sb.qthorasclearing / 24))  DEPOSITO, ch.vlnumero,
                DECODE(ac.icchequepropio,1,'Propio',0,'Tercero') tipo,  '' dsmotivorechazo,
                su.dssucursal, 'No Acreditado' DSESTADO, ac.vlcuentanumero,'' DSOBSERVACION
           FROM tblingreso ii, tblmovcaja mc, personas pe, tblcuenta cu, entidades ee, tblcheque ch,
                tblautorizacioncheque ac, tblbanco bb, tblsucursalesbanco sb, sucursales su, tblconfingreso ci
          WHERE ii.idmovcaja = mc.idmovcaja
            AND su.cdsucursal=ii.cdsucursal
            AND ii.idcuenta = cu.idcuenta
            AND ii.idingreso = ch.idingreso
            and ci.cdsucursal = ii.cdsucursal
            and ci.cdconfingreso = ii.cdconfingreso
            and ci.cdaccion = '1'
            AND cu.cdtipocuenta = '1'
            AND cu.identidad = ee.identidad
            -- no sirve para comisionista -- AND cu.idcuenta = ac.idcuenta
            AND ac.cdbanco = bb.cdbanco
            and sb.cdbanco = bb.cdbanco
            and ii.cdsucursal=nvl(p_cdsucursal,ii.cdsucursal)
            And cu.idcuenta = nvl(p_idcuenta,cu.idcuenta)
            and sb.cdsucursal = ac.cdsucursal
            AND mc.idpersonaresponsable = pe.idpersona
            AND ch.dtacreditacion is null
            and not exists (select 1 from tblingreso ir where ir.idingresorechazado=ii.idingreso) --No Rechazado
            AND ch.idautorizacion = ac.idautorizacion
            AND cu.identidad = NVL(p_identidad,cu.identidad)
            AND ii.dtingreso BETWEEN TRUNC(nvl(p_fechaDesde,sysdate)) AND TRUNC(nvl(p_fechaHasta,sysdate) + 1)
          order by dssucursal, dtingreso;

      return;

   EXCEPTION
      WHEN OTHERS THEN
         n_pkg_vitalpos_log_general.write(2, 'Modulo: ' || v_modulo || '  Error: ' || SQLERRM);
         RAISE;
   END GetChequesNoAcreditados;

   /*****************************************************************************************************************
   * Retorna un reporte Cheques Rechazados con información resumida
   * %v 17/05/2015 - MarianoL: v1.0
   * %v 30/05/2016 - APW: corrijo error de sucursal banco
   ******************************************************************************************************************/
   PROCEDURE GetChequesRechazadosResumido(p_cdsucursal      In tblcuenta.cdsucursal%Type,
                                          p_identidad    IN entidades.identidad%TYPE,
                                          p_idcuenta        In tblcuenta.idcuenta%Type,
                                          p_fechaDesde   IN DATE,
                                          p_fechaHasta   IN DATE,
                                          p_cdmotivorechazo In tblmotivorechazo.cdmotivorechazo%type,
                                          p_cur_out      OUT cursor_type) IS
      v_modulo VARCHAR2(100) := 'PKG_REPORTE.GetChequesRechazadosResumido';
   BEGIN

      OPEN p_cur_out FOR
         SELECT ii.dtingreso,ee.CDCUIT, ee.DSRAZONSOCIAL, cu.NOMBRECUENTA, ii.AMINGRESO,
                bb.DSBANCO,sb.dssucursal DSSUCURSALBANCO,ch.DTEMISION,nvl(ch.dtacreditacion,(ch.dtcobro + (sb.qthorasclearing / 24))) DEPOSITO, ch.vlnumero,
                DECODE(ac.icchequepropio,1,'Propio',0,'Tercero') tipo,
                mr.dsmotivorechazo, su.dssucursal, 'Rechazado' DSESTADO, ac.vlcuentanumero, ie.dsobservacion
           FROM tblingreso ii, tblmovcaja mc, personas pe, tblcuenta cu, entidades ee, tblcheque ch,
                tblautorizacioncheque ac, tblbanco bb, tblingresoestado_ac ie,
                tblmotivorechazo mr, tblingreso ri, tblsucursalesbanco sb, sucursales su, tblconfingreso ci
          WHERE ii.idmovcaja = mc.idmovcaja
            AND su.cdsucursal=ii.cdsucursal
            AND ii.idcuenta = cu.idcuenta
            AND ii.idingreso = ch.idingreso
            and ci.cdsucursal = ii.cdsucursal
            and ci.cdconfingreso = ii.cdconfingreso
            and ci.cdaccion = '1'
            AND cu.cdtipocuenta = '1'
            AND cu.identidad = ee.identidad
            -- no sirve para comisionista -- AND cu.idcuenta = ac.idcuenta
            AND ac.cdbanco = bb.cdbanco
            and sb.cdbanco = bb.cdbanco
            And mr.cdmotivorechazo =nvl (p_cdmotivorechazo,mr.cdmotivorechazo)
            and ii.cdsucursal=nvl(p_cdsucursal,ii.cdsucursal)
            And cu.idcuenta = nvl(p_idcuenta,cu.idcuenta)
            and sb.cdsucursal = ac.cdsucursal
            AND mc.idpersonaresponsable = pe.idpersona
            AND ii.idingreso=ie.idingreso --Solo cheques rechazados desde AC
            AND mr.cdmotivorechazo(+)=ie.cdmotivorechazo --Incluye todos los que no tienen motivo de rechazo
            AND ri.idingresorechazado=ii.idingreso
            AND exists (select 1 from tblingreso ir where ir.idingresorechazado=ii.idingreso)  --Rechazado
            AND ch.idautorizacion = ac.idautorizacion
            AND cu.identidad = NVL(p_identidad,cu.identidad)
            AND ri.dtingreso BETWEEN TRUNC(nvl(p_fechaDesde,sysdate)) AND TRUNC(nvl(p_fechaHasta,sysdate) + 1)
            /*UNION
            --JBodnar - 31/08/2015
            --Trae los cheques viejos que se ingresaron manualmente sin mover la cuenta y sin alivio
            SELECT ii.dtingreso,ee.CDCUIT, ee.DSRAZONSOCIAL, cu.NOMBRECUENTA, ii.AMINGRESO,
                  bb.DSBANCO,sb.dssucursal DSSUCURSALBANCO,ch.DTEMISION,nvl(ch.dtacreditacion,(ch.dtcobro + (sb.qthorasclearing / 24))) DEPOSITO, ch.vlnumero,
                  DECODE(ac.icchequepropio,1,'Propio',0,'Tercero') tipo,
                  mr.dsmotivorechazo, su.dssucursal, 'Rechazado' DSESTADO, ac.vlcuentanumero, ie.dsobservacion
             FROM tblingreso ii, tblcuenta cu, entidades ee, tblcheque ch,
                  tblautorizacioncheque ac, tblbanco bb, tblingresoestado_ac ie,
                  tblmotivorechazo mr, tblingreso ri, tblsucursalesbanco sb, sucursales su, tblconfingreso ci
             WHERE  su.cdsucursal=ii.cdsucursal
              AND ii.idcuenta = cu.idcuenta
              AND ii.idingreso = ch.idingreso
              and ci.cdsucursal = ii.cdsucursal
              and ci.cdconfingreso = ii.cdconfingreso
              and ci.cdaccion = '1'
              AND cu.cdtipocuenta = '1'
              AND cu.identidad = ee.identidad
              -- no sirve para comisionista -- AND cu.idcuenta = ac.idcuenta
              AND ac.cdbanco = bb.cdbanco
              and sb.cdbanco = bb.cdbanco
              And mr.cdmotivorechazo =nvl (p_cdmotivorechazo,mr.cdmotivorechazo)
              and ii.cdsucursal=nvl(p_cdsucursal,ii.cdsucursal)
              And cu.idcuenta = nvl(p_idcuenta,cu.idcuenta)
              and sb.cdsucursal = ac.cdsucursal
              AND ii.idingreso=ie.idingreso --Solo cheques rechazados desde AC
              AND mr.cdmotivorechazo(+)=ie.cdmotivorechazo --Incluye todos los que no tienen motivo de rechazo
              AND ri.idingresorechazado=ii.idingreso
              AND exists (select 1 from tblingreso ir where ir.idingresorechazado=ii.idingreso)  --Rechazado
              AND ch.idautorizacion = ac.idautorizacion
              AND cu.identidad = NVL(p_identidad,cu.identidad)
              AND ii.dtingreso BETWEEN TRUNC(nvl(p_fechaDesde,sysdate)) AND TRUNC(nvl(p_fechaHasta,sysdate) + 1)*/
              UNION
              --JBodnar 02/10/2015
              --Muestra cheque rechazados de comisionistas
              SELECT dtingreso,CDCUIT, DSRAZONSOCIAL, NOMBRECUENTA, AMINGRESO,
                DSBANCO, DSSUCURSALBANCO,DTEMISION,DEPOSITO, vlnumero,
                tipo, dsmotivorechazo, dssucursal, DSESTADO, vlcuentanumero, dsobservacion
               FROM (  SELECT distinct d.sqcomprobante                         sqcomprobante      ,
                          ii.dtingreso                                     dtingreso          ,
                          ee.cdcuit                                        cdcuit             ,
                          ee.dsrazonsocial                                 dsrazonsocial      ,
                          cu.nombrecuenta                                  nombrecuenta       ,
                          ii.amingreso                                     amingreso          ,
                          bb.dsbanco                                       dsbanco            ,
                          sb.dssucursal                                    dssucursalbanco    ,
                          ch.dtemision                                     dtemision          ,
                          CASE WHEN ch.dtacreditacion is not null                             --Acreditado
                                AND not exists (select 1 from tblingreso ir where ir.idingresorechazado = ii.idingreso)
                               THEN ch.dtacreditacion
                               WHEN ch.dtacreditacion is null                                 --No Acreditado
                                AND not exists (select 1 from tblingreso ir where ir.idingresorechazado = ii.idingreso)
                               THEN (ch.dtcobro + (sb.qthorasclearing / 24))                  --Rechazado
                               WHEN     exists (select 1 from tblingreso ir where ir.idingresorechazado = ii.idingreso)
                               THEN nvl(ch.dtacreditacion,(ch.dtcobro + (sb.qthorasclearing / 24)))
                          END                                              deposito           ,
                          ch.vlnumero                                      vlnumero           ,
                          DECODE(ac.icchequepropio,1,'Propio',0,'Tercero') tipo               ,
                          mr.dsmotivorechazo                               dsmotivorechazo    ,
                          su.dssucursal                                    dssucursal         ,
                          CASE WHEN ch.dtacreditacion is not null                             --Acreditado
                                AND not exists (select 1 from tblingreso ir where ir.idingresorechazado = ii.idingreso)
                               THEN 'Acreditado'
                               WHEN ch.dtacreditacion is null                                 --No Acreditado
                                AND not exists (select 1 from tblingreso ir where ir.idingresorechazado = ii.idingreso)
                               THEN 'No Acreditado'                                           --Rechazado
                               WHEN exists (select 1 from tblingreso ir where ir.idingresorechazado = ii.idingreso)
                               THEN 'Rechazado'
                          END                                              dsestado           ,
                          ac.vlcuentanumero                                vlcuentanumero, ie.dsobservacion
                     FROM tblingreso            ii,
                          tblcuenta             cu,
                          entidades             ee,
                          tblcheque             ch,
                          tblautorizacioncheque ac,
                          tblbanco              bb,
                          tblsucursalesbanco    sb,
                          sucursales            su,
                          tblconfingreso        ci,
                          tblingresoestado_ac   ie, --Para los rechazados
                          tblmotivorechazo      mr, --Para los rechazados
                          guiasdetransporte     gt, --Para las guias de transporte
                          tblrendicionguia      rg,
                          documentos            d
                    WHERE  cu.identidad = NVL(p_identidad,cu.identidad)
                      AND gt.idguiadetransporte   = rg.idguiadetransporte
                      AND  gt.iddoctrx             =  d.iddoctrx
                      AND  rg.idingreso            = ii.idingreso
                      AND  ii.idingreso            = ch.idingreso
                      AND  ii.idcuenta             = cu.idcuenta
                      AND  ii.cdsucursal           = su.cdsucursal
                      AND  ii.cdsucursal           = ci.cdsucursal
                      AND  ii.cdconfingreso        = ci.cdconfingreso
                      AND  ci.cdaccion             =    '1'
                      AND  cu.cdtipocuenta         =    '1'
                      AND  cu.identidad            = ee.identidad
                      AND  ac.cdbanco              = bb.cdbanco
                      AND  sb.cdbanco              = bb.cdbanco
                      And cu.idcuenta = nvl(p_idcuenta,cu.idcuenta)
                      and ii.cdsucursal=nvl(p_cdsucursal,ii.cdsucursal)
                      AND  sb.cdsucursal           = ac.cdsucursal
                      AND  ch.idautorizacion       = ac.idautorizacion  (+)
                       AND ii.dtingreso BETWEEN TRUNC(nvl(p_fechaDesde,sysdate)) AND TRUNC(nvl(p_fechaHasta,sysdate) + 1)
                      AND  ii.idingreso            = ie.idingreso       (+)
                      AND  ie.cdmotivorechazo      = mr.cdmotivorechazo (+)
                      AND  mr.cdmotivorechazo =nvl (p_cdmotivorechazo,mr.cdmotivorechazo))
              order by dssucursal, dtingreso;


      return;

   EXCEPTION WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2, 'Modulo: ' || v_modulo || '  Error: ' || SQLERRM);
      RAISE;
   END GetChequesRechazadosResumido;

   /*****************************************************************************************************************
   * Retorna un listado de las partidas de Posnet Banco que componen el monto disponible de cada cliente.
   * %v 26/05/2015 - JBodnar: v1.0
   ******************************************************************************************************************/
   PROCEDURE GetPosnetBancoDisponible(p_identidad  IN entidades.identidad%TYPE,
                                      p_idcuenta   IN tblcuenta.idcuenta%TYPE,
                                      p_fechaDesde IN DATE,
                                      p_fechaHasta IN DATE,
                                      p_cdtipo     IN tblconfingreso.cdtipo%TYPE,
                                      p_cur_out    OUT cursor_type)
  IS
      v_modulo VARCHAR2(100) := 'PKG_REPORTE_CENTRAL.GetPosnetBancoDisponible';
   BEGIN
      OPEN p_cur_out FOR
         SELECT ii.cdsucursal,
                ee.dsrazonsocial,
                cu.nombrecuenta cuenta,
                ee.cdcuit,
                idingreso,
                ii.dtingreso,
                pkg_ingreso_central.GetDescIngreso(ci.cdconfingreso,ii.cdsucursal) dsingreso,
                pkg_ingreso_central.GetImporteNoAplicado(ii.idingreso) importe
           FROM tblingreso ii, tblcuenta cu, tblconfingreso ci,entidades ee
          WHERE ii.idcuenta      = cu.idcuenta
            AND ii.cdconfingreso = ci.cdconfingreso
            AND ii.cdsucursal    = ci.cdsucursal
            AND cu.identidad     = ee.identidad
            AND ee.identidad     = NVL(p_identidad,ee.identidad)
            AND cu.idcuenta      = NVL(p_idcuenta,cu.idcuenta)
            AND ii.dtingreso BETWEEN trunc(p_fechaDesde) AND trunc(p_fechaHasta + 1)
            AND ci.cdmedio       = '3' --Tarjeta Credito
            AND ci.cdforma       ='4' --Posnet Banco
            and pkg_ingreso_central.GetImporteNoAplicado(ii.idingreso) > 0 --Disponible para aplicar de PB
            AND ci.cdtipo        = NVL(p_cdtipo, ci.cdtipo)
            AND not exists (select 1        --No rechazado en sucursal
                              from tblingreso i2,
                                   tblconfingreso ci2
                             where i2.idingresorechazado = ii.idingreso
                               and ci2.cdconfingreso     = i2.cdconfingreso
                               and ci2.cdaccion          = '2')
            AND ci.cdaccion not in ('6','7') --Ajuste ingreso y Ajuste egreso
       ORDER BY ee.dsrazonsocial;
   EXCEPTION
      WHEN OTHERS THEN
         n_pkg_vitalpos_log_general.write(2, 'Modulo: ' || v_modulo || '  Error: ' || SQLERRM);
         RAISE;
   END GetPosnetBancoDisponible;

   /*****************************************************************************************************************
   * Dato un sector un listado grupos
   * %v 14/07/2015 - JBodnar: v1.0
   ******************************************************************************************************************/
    PROCEDURE GetGrupos(p_cdSector   IN Sectores.CDSECTOR%TYPE,
                        p_cur_out    OUT cursor_type) IS
    BEGIN
            OPEN p_cur_out FOR
                SELECT DISTINCT g.CDGrupoArticulos,
                                g.DSGRUPOARTICULOS
                  FROM GruposArticulo g,
                       Articulos      a
                 WHERE a.CDGrupoArticulos = g.CDGrupoArticulos
                   AND trim(a.CDSector) = trim(nvl(p_cdSector, a.CDSector))
                 ORDER BY DSGrupoArticulos;

    END GetGrupos;

   /*****************************************************************************************************************
   * Retorna un listado sectores
   * %v 14/07/2015 - JBodnar: v1.0
   ******************************************************************************************************************/
    PROCEDURE GetSectores (p_cur_out    OUT cursor_type) IS
    BEGIN
        OPEN p_cur_out FOR
            SELECT CDSector,
                   DSSector
              FROM Sectores
             ORDER BY DSSector;
    END GetSectores;

   /*****************************************************************************************************************
   * Retorna un listado de precios de articulos filtrados
   * %v 14/07/2015 - JBodnar: v1.0
   * %v 24/09/2015 - APW: v1.1 - Agrego parámetro para que sean PRECIOS DE LISTA
   * %v 09/12/2015 - APW: v1.2 - Agrego parámetro para que muestre solo los que el stock supera una cantidad
   ******************************************************************************************************************/
   PROCEDURE GetListaPrecios(p_cdSucursal IN tblprecio.cdsucursal%TYPE,
                             p_idCanal    IN tblprecio.id_canal%TYPE,
                             p_cdSector   IN sectores.cdsector%TYPE,
                             p_cdGrupo    IN gruposarticulo.cdgrupoarticulos%TYPE,
                             p_cur_out    OUT cursor_type,
                             p_preciolista IN integer default 0,
                             p_qtstock in integer default 0)
  IS
      v_modulo VARCHAR2(100) := 'PKG_REPORTE_CENTRAL.GetListaPrecios';
   BEGIN

      if nvl(p_preciolista, 0) = 0 then
        OPEN p_cur_out FOR
        SELECT DISTINCT lp.cdarticulo,
               lp.descripcion,
               lp.cantidadunidad uxb,
               lp.preciosuperiorafactor precio,
               lp.factor,
               lp.precioinferiorafactor,
               lp.grupodescripcion,
               lp.grupo,
               se.dssector,
               se.cdsector,
               lp.icoferta
        FROM tbllista_precio_central lp, sectores se, vista_stock_pedidos st
        WHERE lp.cdsucursal = trim(p_cdSucursal)
        and lp.id_canal = trim(p_idCanal)
        and lp.sector = nvl(p_cdSector, lp.sector)
        and lp.grupo = nvl(p_cdGrupo, lp.grupo)
        and se.cdsector = lp.sector
        and lp.unidadmedida = lp.unidadventaminima
        and trim(lp.cdsucursal) = trim(st.cdsucursal)
        and lp.cdarticulo = st.cdarticulo
        and st.qtstock >= p_qtstock;
      else
        OPEN p_cur_out FOR
        SELECT DISTINCT lp.cdarticulo,
                 da.vldescripcion descripcion,
                 n_pkg_vitalpos_materiales.GetUxB(lp.cdarticulo) uxb,
                 lp.amprecio precio,
                 null factor,
                 null precioinferiorafactor,
                 ga.dsgrupoarticulos grupodescripcion,
                 ga.cdgrupoarticulos grupo,
                 se.dssector,
                 se.cdsector,
                 0 icoferta
       FROM tblprecio lp, articulos a, descripcionesarticulos da, sectores se, gruposarticulo ga, vista_stock_pedidos st
        WHERE lp.cdsucursal = p_cdSucursal
        and lp.id_canal = p_idCanal
        and lp.cdarticulo = a.cdarticulo
        and a.cdarticulo = da.cdarticulo
        and a.cdsector = nvl(p_cdSector, a.cdsector)
        and a.cdgrupoarticulos = nvl(p_cdGrupo, a.cdgrupoarticulos)
        and a.cdsector = se.cdsector
        and a.cdgrupoarticulos = ga.cdgrupoarticulos
        and trunc(sysdate) between lp.dtvigenciadesde and lp.dtvigenciahasta
        and lp.id_precio_tipo = 'PL'
        and trim(lp.cdsucursal) = trim(st.cdsucursal)
        and lp.cdarticulo = st.cdarticulo
        and st.qtstock >= p_qtstock;
      end if;

   EXCEPTION
      WHEN OTHERS THEN
         n_pkg_vitalpos_log_general.write(2, 'Modulo: ' || v_modulo || '  Error: ' || SQLERRM);
         RAISE;
   END GetListaPrecios;


  /**************************************************************************************************
  * Retorna el volumen de compra de los clientes con porcentaje de diferencia entre periodos
  * %v 18/12/2015 - LucianoF: v1.0
  ***************************************************************************************************/
  PROCEDURE GetVolumenCompraGeneral (p_sucursales IN VARCHAR2,
                              p_minimo in   integer,
                              p_cur_out    OUT cursor_type) IS

    v_modulo varchar2(100) := 'PKG_REPORTE_CENTRAL.GetVolumenCompra';
    v_idReporte VARCHAR2(40) := '';

  Begin
      v_idReporte := SetSucursalesSeleccionadas(p_sucursales);

      open p_cur_out for
      select dssucursal,identidad, cdcuit,dsrazonsocial,nombrecuenta, idcuenta,
       SUM(actual) actual, SUM(anterior) anterior, round((100 - ( (SUM(actual) * 100) / sum(anterior) )),2) as disminucion
       from
        (select s.dssucursal,e.identidad,e.cdcuit, e.dsrazonsocial, c.nombrecuenta, fh.idcuenta, fh.aniomes, fh.amfacturacion actual, 0 anterior
          from tblfacturacionhistorica fh,
               tblcuenta c,
               entidades e,
               sucursales s,
               tbltmp_sucursales_reporte rs
          where fh.idcuenta = c.idcuenta
                and c.identidad = e.identidad
                and c.cdsucursal = s.cdsucursal
                and rs.idreporte = v_idReporte
                and rs.cdsucursal = s.cdsucursal
                and fh.aniomes > TRUNC(sysdate, 'MM')
        union
          select s.dssucursal, e.identidad, e.cdcuit, e.dsrazonsocial, c.nombrecuenta, fh.idcuenta, fh.aniomes, 0 actual, fh.amfacturacion anterior
          from tblfacturacionhistorica fh,
               tblcuenta c,
               entidades e,
               sucursales s,
                tbltmp_sucursales_reporte rs
          where fh.idcuenta = c.idcuenta
                and c.identidad = e.identidad
                and c.cdsucursal = s.cdsucursal
                and rs.idreporte = v_idReporte
                and rs.cdsucursal = s.cdsucursal
                and  fh.aniomes between trunc(add_months(sysdate, -1),'MM') and  TRUNC(sysdate, 'MM')
        )
        group by dssucursal,identidad,cdcuit,dsrazonsocial,nombrecuenta,idcuenta
        having SUM(anterior) <> 0
        and (100 - ( (SUM(actual) * 100) / sum(anterior) )) <= p_minimo and (100 - ( (SUM(actual) * 100) / sum(anterior) )) > 0
        order by disminucion desc;

      CleanSucursalesSeleccionadas(v_idReporte);

  EXCEPTION WHEN OTHERS THEN
     n_pkg_vitalpos_log_general.write(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM);
     raise;
  End GetVolumenCompraGeneral;


/**************************************************************************************************
  * Retorna el volumen de compra de los clientes con porcentaje de diferencia entre periodos
  * %v 18/12/2015 - LucianoF: v1.0
  ***************************************************************************************************/
  PROCEDURE GetVolumenCompraDetalle (p_idcuenta IN tblfacturacionhistorica.idcuenta%TYPE,
                                     p_minimo in   integer,
                                     p_cur_out    OUT cursor_type) IS

    v_modulo varchar2(100) := 'PKG_REPORTE_CENTRAL.GetVolumenCompra';


  Begin


      open p_cur_out for
      select dssucursal,cdcuit,dsrazonsocial,nombrecuenta, idcuenta,nombrecanal, id_canal,
       SUM(actual) actual, SUM(anterior) anterior, round((100 - ( (SUM(actual) * 100) / sum(anterior) )),2) as disminucion
       from
        (select s.dssucursal,e.cdcuit, e.dsrazonsocial, c.nombrecuenta, fh.idcuenta, fh.aniomes, cc.nombre nombrecanal,
                fh.id_canal, fh.amfacturacion actual, 0 anterior
          from tblfacturacionhistorica fh,
               tblcuenta c,
               entidades e,
               sucursales s,
               tblcanal cc
          where fh.idcuenta = c.idcuenta
                and c.identidad = e.identidad
                and c.cdsucursal = s.cdsucursal
                and cc.id_canal = fh.id_canal
                and fh.aniomes > TRUNC(sysdate, 'MM')
                and fh.idcuenta = p_idcuenta
        union
          select s.dssucursal, e.cdcuit, e.dsrazonsocial, c.nombrecuenta, fh.idcuenta, fh.aniomes,cc.nombre nombrecanal,
                 fh.id_canal, 0 actual, fh.amfacturacion anterior
          from tblfacturacionhistorica fh,
               tblcuenta c,
               entidades e,
               sucursales s,
               tblcanal cc
          where fh.idcuenta = c.idcuenta
                and c.identidad = e.identidad
                and c.cdsucursal = s.cdsucursal
                and cc.id_canal = fh.id_canal
                and fh.aniomes between trunc(add_months(sysdate, -1),'MM') and  TRUNC(sysdate, 'MM')
                and fh.idcuenta = p_idcuenta
        )
        group by dssucursal,cdcuit,dsrazonsocial,nombrecuenta,idcuenta,nombrecanal, id_canal
        having SUM(anterior) <> 0
        and (100 - ( (SUM(actual) * 100) / sum(anterior) )) <= p_minimo and (100 - ( (SUM(actual) * 100) / sum(anterior) )) > 0
        order by disminucion desc;



  EXCEPTION WHEN OTHERS THEN
     n_pkg_vitalpos_log_general.write(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM);
     raise;
  End GetVolumenCompraDetalle;

  /**************************************************************************************************
  * Retorna el monto de las ventas de la sucursal entre fechas
  * %v 27/07/2015 - JBodnar: v1.0
  * %v 14/12/2021 - LM - Se agregan totales de unidades
  ***************************************************************************************************/
  PROCEDURE GetVentaSucursalGeneral (p_sucursales IN VARCHAR2,
                                     p_fechadesde in   date,
                                     p_fechahasta in   date,
                                     p_cur_out    OUT cursor_type) IS

    v_modulo varchar2(100) := 'PKG_REPORTE_CENTRAL.GetVentaSucursalGeneral';
    v_idReporte VARCHAR2(40) := '';

  Begin
      v_idReporte := SetSucursalesSeleccionadas(p_sucursales);

      open p_cur_out for
      with monto as
        (
        select cdregion, dsregion,cdsucursal,dssucursal,sum(CO) as CO,  sum(VE) as VE, sum(SA) as SA, sum(TE) as TE
              from
              (select
              re.cdregion,re.dsregion,su.cdsucursal,su.dssucursal,nvl(round(sum(d.amnetodocumento)/1000,2),0) AS CO,0 as VE, 0 as SA, 0 as TE     
              from documentos d,
                   sucursales su,
                   tblregion re,
                   movmateriales mm,
                   tbltmp_sucursales_reporte rs
              where  d.dtdocumento between trunc(p_fechadesde) and trunc(p_fechahasta) + 1
              AND d.cdsucursal = su.cdsucursal
              AND su.cdregion = re.cdregion
              AND rs.idreporte = v_idReporte
              AND rs.cdsucursal = su.cdsucursal
              AND mm.idmovmateriales = d.idmovmateriales
              AND mm.id_canal='CO'
              and substr(d.cdcomprobante,1,2) in ('FC','NC','ND')
              and d.cdcomprobante not in ('NCTA','NCTB','NDTA','NDTB')
              group by re.cdregion, re.dsregion, su.cdsucursal, su.dssucursal, mm.id_canal
              union
              select re.cdregion,re.dsregion, su.cdsucursal,su.dssucursal,0 AS CO,0 as VE,nvl(round(sum(d.amnetodocumento)/1000,2),0) as SA,0 as TE            
              from documentos d,
                   sucursales su,
                   tblregion re,
                   movmateriales mm,
                   tbltmp_sucursales_reporte rs
              where  d.dtdocumento between trunc(p_fechadesde) and trunc(p_fechahasta) + 1
              AND d.cdsucursal = su.cdsucursal
              AND su.cdregion = re.cdregion
              AND rs.idreporte = v_idReporte
              AND rs.cdsucursal = su.cdsucursal
              AND mm.idmovmateriales = d.idmovmateriales
              AND mm.id_canal='SA'
              and substr(d.cdcomprobante,1,2) in ('FC','NC','ND')
              and d.cdcomprobante not in ('NCTA','NCTB','NDTA','NDTB')
              group by re.cdregion, re.dsregion, su.cdsucursal, su.dssucursal, mm.id_canal
              union
              select re.cdregion,re.dsregion,su.cdsucursal,su.dssucursal,0 AS CO,0 as VE,0 as SA,nvl(round(sum(d.amnetodocumento)/1000,2),0) as TE         
              from documentos d,
                   sucursales su,
                   tblregion re,
                   movmateriales mm,
                   tbltmp_sucursales_reporte rs
              where  d.dtdocumento between trunc(p_fechadesde) and trunc(p_fechahasta) + 1
              AND d.cdsucursal = su.cdsucursal
              AND su.cdregion = re.cdregion
              AND rs.idreporte = v_idReporte
              AND rs.cdsucursal = su.cdsucursal
              AND mm.idmovmateriales = d.idmovmateriales
              AND mm.id_canal='TE'
              and substr(d.cdcomprobante,1,2) in ('FC','NC','ND')
              and d.cdcomprobante not in ('NCTA','NCTB','NDTA','NDTB')
              group by re.cdregion, re.dsregion, su.cdsucursal, su.dssucursal, mm.id_canal
              union
              select re.cdregion,re.dsregion,su.cdsucursal,su.dssucursal,0 AS CO,nvl(round(sum(d.amnetodocumento)/1000,2),0) as VE,0 as SA, 0 as TE          
              from documentos d,
                   sucursales su,
                   tblregion re,
                   movmateriales mm,
                   tbltmp_sucursales_reporte rs
              where  d.dtdocumento between trunc(p_fechadesde) and trunc(p_fechahasta) + 1
              AND d.cdsucursal = su.cdsucursal
              AND su.cdregion = re.cdregion
              AND rs.idreporte = v_idReporte
              AND rs.cdsucursal = su.cdsucursal
              AND mm.idmovmateriales = d.idmovmateriales
              AND mm.id_canal='VE'
              and substr(d.cdcomprobante,1,2) in ('FC','NC','ND')
              and d.cdcomprobante not in ('NCTA','NCTB','NDTA','NDTB')
              group by re.cdregion, re.dsregion, su.cdsucursal, su.dssucursal, mm.id_canal
                )
              GROUP BY cdregion, dsregion,  cdsucursal,dssucursal
        ),
        unidades as
        (
        select cdregion, dsregion,cdsucursal,dssucursal,sum(CO) as CO,  sum(VE) as VE, sum(SA) as SA, sum(TE) as TE
              from
              (select
              re.cdregion,re.dsregion,su.cdsucursal,su.dssucursal,nvl(round(sum(
              case when d.cdcomprobante like 'FC%' then dmm.qtunidadmedidabase
                   when d.cdcomprobante like 'NC%' then dmm.qtunidadmedidabase*-1
              end
              ),0),0) AS CO,0 as VE, 0 as SA, 0 as TE
              from documentos d,
                   sucursales su,
                   tblregion re,
                   movmateriales mm,
                   detallemovmateriales dmm,
                   tbltmp_sucursales_reporte rs
              where  d.dtdocumento between trunc(p_fechadesde) and trunc(p_fechahasta) + 1
              AND d.cdsucursal = su.cdsucursal
              AND su.cdregion = re.cdregion
              AND rs.idreporte = v_idReporte
              AND rs.cdsucursal = su.cdsucursal
              AND mm.idmovmateriales = d.idmovmateriales
              and mm.idmovmateriales = dmm.idmovmateriales
              AND mm.id_canal='CO'
              and substr(d.cdcomprobante,1,2) in ('FC','NC')
              and d.cdcomprobante not in ('NCTA','NCTB','NDTA','NDTB')
              and nvl(dmm.icresppromo, 0) = 0
              and nvl(dmm.dsobservacion, 'NULL')  not in ('(*)     ','DEL     ')
              group by re.cdregion, re.dsregion, su.cdsucursal, su.dssucursal, mm.id_canal
              union
              select re.cdregion,re.dsregion, su.cdsucursal,su.dssucursal,0 AS CO,0 as VE,nvl(round(sum(
              case when d.cdcomprobante like 'FC%' then dmm.qtunidadmedidabase
                   when d.cdcomprobante like 'NC%' then dmm.qtunidadmedidabase*-1
              end
              ),0),0) as SA,0 as TE
              from documentos d,
                   sucursales su,
                   tblregion re,
                   movmateriales mm,
                   detallemovmateriales dmm,
                   tbltmp_sucursales_reporte rs
              where  d.dtdocumento between trunc(p_fechadesde) and trunc(p_fechahasta) + 1
              AND d.cdsucursal = su.cdsucursal
              AND su.cdregion = re.cdregion
              AND rs.idreporte = v_idReporte
              AND rs.cdsucursal = su.cdsucursal
              AND mm.idmovmateriales = d.idmovmateriales
              and mm.idmovmateriales = dmm.idmovmateriales
              AND mm.id_canal='SA'
              and substr(d.cdcomprobante,1,2) in ('FC','NC')
              and d.cdcomprobante not in ('NCTA','NCTB','NDTA','NDTB')
              and nvl(dmm.icresppromo, 0) = 0
              and nvl(dmm.dsobservacion, 'NULL')  not in ('(*)     ','DEL     ')
              group by re.cdregion, re.dsregion, su.cdsucursal, su.dssucursal, mm.id_canal
              union
              select re.cdregion,re.dsregion,su.cdsucursal,su.dssucursal,0 AS CO,0 as VE,0 as SA,nvl(round(sum(
              case when d.cdcomprobante like 'FC%' then dmm.qtunidadmedidabase
                   when d.cdcomprobante like 'NC%' then dmm.qtunidadmedidabase*-1
              end
              ),0),0) as TE
              from documentos d,
                   sucursales su,
                   tblregion re,
                   movmateriales mm,
                   detallemovmateriales dmm,
                   tbltmp_sucursales_reporte rs
              where  d.dtdocumento between trunc(p_fechadesde) and trunc(p_fechahasta) + 1
              AND d.cdsucursal = su.cdsucursal
              AND su.cdregion = re.cdregion
              AND rs.idreporte = v_idReporte
              AND rs.cdsucursal = su.cdsucursal
              AND mm.idmovmateriales = d.idmovmateriales
              and mm.idmovmateriales = dmm.idmovmateriales
              AND mm.id_canal='TE'
              and substr(d.cdcomprobante,1,2) in ('FC','NC')
              and d.cdcomprobante not in ('NCTA','NCTB','NDTA','NDTB')
              and nvl(dmm.icresppromo, 0) = 0
              and nvl(dmm.dsobservacion, 'NULL')  not in ('(*)     ','DEL     ')
              group by re.cdregion, re.dsregion, su.cdsucursal, su.dssucursal, mm.id_canal
              union
              select re.cdregion,re.dsregion,su.cdsucursal,su.dssucursal,0 AS CO,nvl(round(sum(
               case when d.cdcomprobante like 'FC%' then dmm.qtunidadmedidabase
                   when d.cdcomprobante like 'NC%' then dmm.qtunidadmedidabase*-1
              end
              ),0),0) as VE,0 as SA, 0 as TE
              from documentos d,
                   sucursales su,
                   tblregion re,
                   movmateriales mm,
                   detallemovmateriales dmm,
                   tbltmp_sucursales_reporte rs
              where  d.dtdocumento between trunc(p_fechadesde) and trunc(p_fechahasta) + 1
              AND d.cdsucursal = su.cdsucursal
              AND su.cdregion = re.cdregion
              AND rs.idreporte = v_idReporte
              AND rs.cdsucursal = su.cdsucursal
              AND mm.idmovmateriales = d.idmovmateriales
              and mm.idmovmateriales = dmm.idmovmateriales
              AND mm.id_canal='VE'
              and substr(d.cdcomprobante,1,2) in ('FC','NC')
              and d.cdcomprobante not in ('NCTA','NCTB','NDTA','NDTB')
              and nvl(dmm.icresppromo, 0) = 0
              and nvl(dmm.dsobservacion, 'NULL')  not in ('(*)     ','DEL     ')
              group by re.cdregion, re.dsregion, su.cdsucursal, su.dssucursal, mm.id_canal 
               )
              GROUP BY cdregion, dsregion,  cdsucursal,dssucursal
        )
            select m.cdregion,
                   m.dsregion, 
                   m.cdsucursal,
                   m.dssucursal,
                   m.co,
                   m.ve,
                   m.sa,
                   m.te,
                   u.co as co_un,
                   u.ve as ve_un,
                   u.sa as sa_un,
                   u.te as te_un
             from monto m ,unidades u   
            where m.cdregion=u.cdregion
              and m.dsregion=u.dsregion
              and m.cdsucursal=u.cdsucursal      
         order by 1;
      CleanSucursalesSeleccionadas(v_idReporte);

  EXCEPTION WHEN OTHERS THEN
     n_pkg_vitalpos_log_general.write(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM);
     raise;
  End GetVentaSucursalGeneral;

  /*****************************************************************************************************************
  * Función que devuelve la descripción del motivo de un documento
  * %v 19/08/2015   - APW: v1.0
  ******************************************************************************************************************/
  FUNCTION GetDescMotivoDoc(p_idmotivodoc tbldocumento_control.idmotivodoc%type) RETURN varchar2 IS

    v_descmotivo varchar2(100);

  BEGIN

    select sd.vldescripcion || ' - ' || ti.vldescripcion
      into v_descmotivo
      from tbltipomotivodoc           ti,
           posapp.tblsubtipomotivodoc sd,
           tblmotivodocumento         dd
     where ti.cdtipomotivodoc = sd.cdtipomotivodoc
       and sd.idsubtipomotivodoc = dd.idsubtipomotivodoc
       and dd.idmotivodoc = p_idmotivodoc;

     RETURN v_descmotivo;

  EXCEPTION
    WHEN OTHERS THEN
      return ' ';
  END GetDescMotivoDoc;

  /**************************************************************************************************
  * Retorna el detalle de devoluciones de efectivo por sucursal
  * %v 20/08/2015 - JBodnar: v1.0
  * %v 03/08/2018 - JBodnar: v1.0: se modifica para que muestre el monto imputado y solo de las notas de credito
  * %v 31/08/2018 - JBodnar: v1.0: se modifica para que muestre el monto de la nota de credito y el imputado y union con tarjetas
  ***************************************************************************************************/
  PROCEDURE GetDevolucionEfectivo (p_sucursales   IN VARCHAR2,
                                   p_fechadesde in   date,
                                   p_fechahasta in   date,
                                   p_cur_out    OUT cursor_type) IS

    v_modulo varchar2(100) := 'PKG_REPORTE_CENTRAL.GetDevolucionEfectivo';
     v_idReporte             VARCHAR2(40) := '';
  BEGIN
    v_idReporte := PKG_REPORTE_CENTRAL.SetSucursalesSeleccionadas(p_sucursales);

      open p_cur_out for
      --Devolucion de Efectivo
      select pkg_ingreso_central.GetDescIngreso(i.cdconfingreso, i.cdsucursal) descripcion,
             su.dssucursal sucursal,
             i.dtingreso FECHA,
             mc.cdcaja,
             pe.dsnombre || ' ' || pe.dsapellido CAJERO,
             pef.dsnombre || ' ' || pef.dsapellido FACTURISTA,
             ee.dsrazonsocial CLIENTE,
             pkg_documento_central.GetDescDocumento(c.iddoctrx_pago) nc,
             dd.amdocumento,
             c.amimputado,
             pkg_reporte_central.GetDescMotivoDoc(dc.idmotivodoc) MOTIVO_NC
        from tblingreso           i,
             tblcobranza          c,
             sucursales           su,
             tblmovcaja           mc,
             personas             pe,
             entidades            ee,
             documentos           dd,
             personas             pef,
             tbldocumento_control dc,
             tbltmp_sucursales_reporte rs
       where i.cdconfingreso = '9035' --Egreso de Efectivo
         and i.idtransaccion = c.idtransaccion
         and su.cdsucursal = i.cdsucursal
         AND I.IDINGRESO = C.IDINGRESO_PAGO
         and i.idmovcaja = mc.idmovcaja
         and c.iddoctrx_pago is not null
         and c.idingreso_pago is not null
         and dc.iddoctrxgen = c.iddoctrx_pago
         and mc.idpersonaresponsable = pe.idpersona
         and pef.idpersona = dd.idpersona
         and dd.iddoctrx = c.iddoctrx_pago
         and ee.identidad = dd.identidadreal
         and rs.idreporte = v_idReporte
         and su.cdsucursal = rs.cdsucursal
         and i.dtingreso between trunc(p_fechadesde) and trunc(p_fechahasta) + 1
         UNION ALL
         --Devolucion de Tarjetas
        select pkg_ingreso_central.GetDescIngreso(i.cdconfingreso, i.cdsucursal) descripcion,
               su.dssucursal sucursal,
               i.dtingreso FECHA,
               mc.cdcaja,
               pe.dsnombre || ' ' || pe.dsapellido CAJERO,
               pef.dsnombre || ' ' || pef.dsapellido FACTURISTA,
               ee.dsrazonsocial CLIENTE,
               pkg_documento_central.GetDescDocumento(c.iddoctrx_pago) nc,
               dd.amdocumento,
               c.amimputado,
               pkg_reporte_central.GetDescMotivoDoc(dc.idmotivodoc) MOTIVO_NC
          from tblingreso           i,
               tblcobranza          c,
               sucursales           su,
               tblmovcaja           mc,
               personas             pe,
               entidades            ee,
               documentos           dd,
               personas             pef,
               tbldocumento_control dc,
               tblconfingreso ci,
               tbltmp_sucursales_reporte rs
         where  i.idtransaccion = c.idtransaccion
           and ci.cdconfingreso = i.cdconfingreso
           and ci.cdsucursal = i.cdsucursal
           AND I.IDINGRESO = C.IDINGRESO_PAGO
           and ci.cdaccion = 4 --Egresto
           and ci.cdmedio  in (7 , 3 ) --Debito y Credito
           and su.cdsucursal = i.cdsucursal
           and i.idmovcaja = mc.idmovcaja
           and c.iddoctrx_pago is not null
           and c.idingreso_pago is not null
           and dc.iddoctrxgen = c.iddoctrx_pago
           and mc.idpersonaresponsable = pe.idpersona
           and pef.idpersona = dd.idpersona
           and dd.iddoctrx = c.iddoctrx_pago
           and ee.identidad = dd.identidadreal
           and rs.idreporte = v_idReporte
           and su.cdsucursal = rs.cdsucursal
           and i.dtingreso between trunc(p_fechadesde) and trunc(p_fechahasta) + 1;


      PKG_REPORTE_CENTRAL.CleanSucursalesSeleccionadas(v_idReporte);

  EXCEPTION WHEN OTHERS THEN
     n_pkg_vitalpos_log_general.write(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM);
     raise;
  End GetDevolucionEfectivo;

  /**************************************************************************************************
  * Genera Reporte de las rendiciones hechas en una Guía
  * %v 12/08/2015 - MartinM: v1.0
  ***************************************************************************************************/

  PROCEDURE GetReporteRendicionesPorGuia (p_idguiadetransporte IN  guiasdetransporte.idguiadetransporte%TYPE ,
                                          p_cur_out            OUT                   cursor_type             ,
                                          p_ok                 OUT                   INTEGER                 ,
                                          p_error              OUT                   VARCHAR2                ) IS

     v_Modulo VARCHAR2(100) := 'PKG_REPORTE_CENTRAL.GetReporteRendicionesPorGuia' ;

  BEGIN

     p_ok := 0;

      OPEN p_cur_out FOR
    select  ti.dtingreso  FechaIngreso,
            ti.amingreso  MontoIngreso,
           tmi.dsmedio    MedioIngreso,
           tfi.dsforma    FormaIngreso,
           tti.dstipo     TipoIngreso
      from tblrendicionguia trg,
           tblingreso       ti ,
           tblconfingreso   tci,
           tblmedioingreso  tmi,
           tblformaingreso  tfi,
           tbltipoingreso   tti
     where trg.idguiadetransporte = p_idguiadetransporte
       and  ti.idingreso          = trg.idingreso
       and  ti.cdconfingreso      = tci.cdconfingreso
       and tci.cdmedio            = tmi.cdmedio
       and tci.cdforma            = tfi.cdforma
       and tci.cdtipo             = tti.cdtipo;

     p_ok := 1;

  EXCEPTION WHEN OTHERS THEN
     p_ok    := 0;
     p_error := SQLERRM;
     n_pkg_vitalpos_log_general.write(2, 'Modulo: ' || v_Modulo || ' Error: ' || SQLERRM);
  END GetReporteRendicionesPorGuia;

  /**************************************************************************************************
  * Reporte de los diferentes porcentajes de los diferentes ingresos asociados a una guía de transporte
  * %v 12/08/2015 - MartinM: v1.0
  * %V APW - agrego filtro para que solo sirva para comisionistas
  * %V LM  - 17.12.2018 - se agrega la columna de pago electronico
  ***************************************************************************************************/
  PROCEDURE GetPorcentajeMediosRendGuiaCO ( p_idcomisionista IN  documentos.identidad%TYPE  ,
                                            p_fechadesde     IN  DATE                       ,
                                            p_fechahasta     IN  DATE                       ,
                                            p_sucursales     IN  VARCHAR2                   ,
                                            p_cur_out        OUT cursor_type                ,
                                            p_ok             OUT INTEGER                    ,
                                            p_error          OUT VARCHAR2                   ) IS

     v_Modulo    VARCHAR2(100) := 'PKG_REPORTE_CENTRAL.GetPorcentajeMediosRendGuiaCO' ;
     v_idReporte VARCHAR2(40)  := ''                                                  ;

  BEGIN

     v_idReporte := SetSucursalesSeleccionadas(p_sucursales);

     p_ok := 0;

      OPEN p_cur_out FOR
      WITH q
        AS ( SELECT /*+ inline */ trg.idguiadetransporte IdGuiaDeTransporte ,
                     ti.amingreso                        MontoIngreso       ,
                    CASE WHEN tci.cdmedio in ('3','7')
                          AND tci.cdforma = '5'
                         THEN 'Cierre de Lote'
                         WHEN tci.cdmedio = '6'
                         THEN 'Interdepósito'
                         WHEN tci.cdmedio = '5'
                         THEN 'Cheque'
                         WHEN tci.cdmedio = '4'
                         THEN 'Ticket'
                         WHEN tci.cdmedio = '19'
                         THEN 'Retención'
                         WHEN tci.cdmedio = '1'
                          AND tci.cdtipo  = '20'
                         THEN 'Efectivo Pesos'
                         WHEN tci.cdmedio = '1'
                          AND tci.cdtipo  = '18'
                         THEN 'Efectivo Dolar'
                         WHEN tci.cdmedio = '20'
                         THEN 'Electronico'
                    END MedioPago
               FROM tblrendicionguia          trg,
                    tblingreso                ti ,
                    tblconfingreso            tci,
                    guiasdetransporte         gt ,
                    documentos                d  ,
                    tbltmp_sucursales_reporte rs,
                    entidades e,
                    rolesentidades re
              WHERE  ti.idingreso          = trg.idingreso
                AND  ti.cdconfingreso      = tci.cdconfingreso
                AND  ti.cdsucursal         = tci.cdsucursal
                AND  gt.idguiadetransporte = trg.idguiadetransporte
                AND  gt.iddoctrx           =   d.iddoctrx
                AND  rs.cdsucursal         =  ti.cdsucursal
                AND  rs.idreporte          =     v_idReporte
                AND  gt.identidad=d.identidad
                AND  gt.identidad=e.identidad
                and  e.identidad=re.identidad
                and  re.cdrol=1
                AND (gt.identidad          =     p_idcomisionista or p_idcomisionista IS NULL)
                AND ( d.dtdocumento       >=     p_fechadesde     or p_fechadesde     IS NULL)
                AND ( d.dtdocumento       <=     p_fechahasta     or p_fechahasta     IS NULL) )
           SELECT q4.idguiadetransporte                                    idguiadetransporte          ,
                   d.sqcomprobante                                         sqcomprobante               ,
                   d.dtdocumento                                           dtdocumento                 ,
                   e.dsrazonsocial                                         dsrazonsocial               ,
                   s.dssucursal                                            dssucursal                  ,
                  nvl(max(decode(q4.MedioPago,'Cierre de Lote',Porcentaje,'')),' ') CierreDeLote       ,
                  nvl(max(decode(q4.MedioPago,'Interdepósito',Porcentaje,'')),' ')  Interdeposito      ,
                  nvl(max(decode(q4.MedioPago,'Cheque',Porcentaje,'')),' ')         Cheque             ,
                  nvl(max(decode(q4.MedioPago,'Ticket',Porcentaje,'')),' ')         Ticket             ,
                  nvl(max(decode(q4.MedioPago,'Retención',Porcentaje,'')),' ')      Retencion          ,
                  nvl(max(decode(q4.MedioPago,'Efectivo Pesos',Porcentaje,'')),' ') EfectivoPesos      ,
                  nvl(max(decode(q4.MedioPago,'Efectivo Dolar',Porcentaje,'')),' ') EfectivoDolar      ,
                  nvl(max(decode(q4.MedioPago,'Electronico',Porcentaje,'')),' ')    Electronico        ,
                  '$ ' || trim(to_char(round(q4.TotalGuia,2),'99999999990D99','NLS_NUMERIC_CHARACTERS = '',.'''))   TotalGuia
             FROM (SELECT q3.idguiadetransporte,
                          q3.MedioPago ,
                          q3.TotalMedio,
                          q3.TotalGuia ,
                          to_char(round((q3.TotalMedio / q3.TotalGuia) * 100,2),'990D99','NLS_NUMERIC_CHARACTERS = '',.''')  || ' %' Porcentaje
                     FROM ( SELECT q2.idguiadetransporte,
                                   q2.MedioPago,
                                   q2.TotalMedio,
                                   Sum(nvl(q2.TotalMedio,0)) OVER (PARTITION BY q2.idguiadetransporte) TotalGuia
                             FROM (SELECT q.idguiadetransporte          ,
                                          q.MedioPago                   ,
                                          Sum(nvl(MontoIngreso,0)) TotalMedio
                                     FROM q
                                 GROUP BY idguiadetransporte     ,
                                          MedioPago              ) q2 ) q3 )                   q4 ,
                                                                             guiasdetransporte gt ,
                                                                             documentos        d  ,
                                                                             entidades         e  ,
                                                                             sucursales        s
            WHERE q4.idguiadetransporte = gt.idguiadetransporte
              AND gt.iddoctrx           =  d.iddoctrx
              AND  d.identidad          =  e.identidad
              AND  d.cdsucursal         =  s.cdsucursal
         GROUP BY q4.idguiadetransporte ,
                   d.sqcomprobante      ,
                   d.dtdocumento        ,
                   e.dsrazonsocial      ,
                   s.dssucursal         ,
                  '$ ' || trim(to_char(round(q4.TotalGuia,2),'99999999990D99','NLS_NUMERIC_CHARACTERS = '',.'''))
          ORDER BY d.sqcomprobante DESC ;

     CleanSucursalesSeleccionadas(v_idReporte);

     p_ok := 1;

  EXCEPTION WHEN OTHERS THEN
     p_ok    := 0;
     p_error := SQLERRM;
     n_pkg_vitalpos_log_general.write(2, 'Modulo: ' || v_Modulo || ' Error: ' || SQLERRM);
  END GetPorcentajeMediosRendGuiaCO;

  /**************************************************************************************************
  * Reporte de los diferentes montos de los diferentes ingresos asociados a una guía de transporte
  * %v 12/08/2015 - MartinM: v1.0
  ***************************************************************************************************/
  PROCEDURE GetMontosMediosRendidoGuiaCO ( p_idcomisionista IN  documentos.identidad%TYPE ,
                                           p_fechadesde     IN  DATE                      ,
                                           p_fechahasta     IN  DATE                      ,
                                           p_sucursales     IN  VARCHAR2                  ,
                                           p_cur_out        OUT cursor_type               ,
                                           p_ok             OUT INTEGER                   ,
                                           p_error          OUT VARCHAR2                  ) IS

     v_Modulo VARCHAR2(100)   := 'PKG_REPORTE_CENTRAL.GetMontosMediosRendidoGuiaCO' ;
     v_idReporte VARCHAR2(40) := '';

  BEGIN

     p_ok := 0;
     v_idReporte := SetSucursalesSeleccionadas(p_sucursales);

      OPEN p_cur_out FOR
      WITH q
        AS ( SELECT /*+ inline */ trg.idguiadetransporte IdGuiaDeTransporte ,
                     ti.amingreso                        MontoIngreso       ,
                    CASE WHEN tci.cdmedio in ('3','7')
                          AND tci.cdforma = '5'
                         THEN 'Cierre de Lote'
                         WHEN tci.cdmedio = '6'
                         THEN 'Interdepósito'
                         WHEN tci.cdmedio = '5'
                         THEN 'Cheque'
                         WHEN tci.cdmedio = '4'
                         THEN 'Ticket'
                         WHEN tci.cdmedio = '19'
                         THEN 'Retención'
                         WHEN tci.cdmedio = '1'
                          AND tci.cdtipo  = '20'
                         THEN 'Efectivo Pesos'
                         WHEN tci.cdmedio = '1'
                          AND tci.cdtipo  = '18'
                         THEN 'Efectivo Dolar'
                    END MedioPago
               FROM tblrendicionguia          trg,
                    tblingreso                ti ,
                    tblconfingreso            tci,
                    guiasdetransporte         gt ,
                    documentos                d  ,
                    tbltmp_sucursales_reporte rs
              WHERE  ti.idingreso          = trg.idingreso
                AND  ti.cdconfingreso      = tci.cdconfingreso
                AND  ti.cdsucursal         = tci.cdsucursal
                AND  gt.idguiadetransporte = trg.idguiadetransporte
                AND  gt.iddoctrx           =   d.iddoctrx
                AND  rs.cdsucursal         =  ti.cdsucursal
                AND  rs.idreporte          =     v_idReporte
                AND (gt.identidad          =     p_idcomisionista or p_idcomisionista IS NULL)
                AND ( d.dtdocumento       >=     p_fechadesde     or p_fechadesde     IS NULL)
                AND ( d.dtdocumento       <=     p_fechahasta     or p_fechahasta     IS NULL) )
           SELECT q4.idguiadetransporte                                                                        idguiadetransporte ,
                   d.sqcomprobante                                                                             sqcomprobante      ,
                   d.dtdocumento                                                                               dtdocumento        ,
                   e.dsrazonsocial                                                                             dsrazonsocial      ,
                  max(decode(q4.MedioPago,'Cierre de Lote',TotalMedio,'')) CierreDeLote       ,
                  max(decode(q4.MedioPago,'Interdepósito' ,TotalMedio,'')) Interdeposito      ,
                  max(decode(q4.MedioPago,'Cheque'        ,TotalMedio,'')) Cheque             ,
                  max(decode(q4.MedioPago,'Ticket'        ,TotalMedio,'')) Ticket             ,
                  max(decode(q4.MedioPago,'Retención'     ,TotalMedio,'')) Retencion          ,
                  max(decode(q4.MedioPago,'Efectivo Pesos',TotalMedio,'')) EfectivoPesos      ,
                  max(decode(q4.MedioPago,'Efectivo Dolar',TotalMedio,'')) EfectivoDolar      ,
                  q4.TotalGuia
             FROM (SELECT q3.idguiadetransporte,
                          q3.MedioPago ,
                          q3.TotalMedio,
                          q3.TotalGuia
                     FROM ( SELECT q2.idguiadetransporte,
                                   q2.MedioPago,
                                   q2.TotalMedio,
                                   Sum(q2.TotalMedio) OVER (PARTITION BY q2.idguiadetransporte) TotalGuia
                             FROM (SELECT q.idguiadetransporte          ,
                                          q.MedioPago                   ,
                                          Sum(MontoIngreso) TotalMedio
                                     FROM q
                                 GROUP BY idguiadetransporte     ,
                                          MedioPago              ) q2 ) q3 )                   q4 ,
                                                                             guiasdetransporte gt ,
                                                                             documentos        d  ,
                                                                             entidades         e
            WHERE q4.idguiadetransporte = gt.idguiadetransporte
              AND gt.iddoctrx           =  d.iddoctrx
              AND  d.identidad          =  e.identidad
         GROUP BY q4.idguiadetransporte ,
                   d.sqcomprobante      ,
                   d.dtdocumento        ,
                   e.dsrazonsocial      ,
                  q4.TotalGuia
         ORDER BY  d.sqcomprobante DESC ;

     p_ok := 1;

     CleanSucursalesSeleccionadas(v_idReporte);

  EXCEPTION WHEN OTHERS THEN
     p_ok    := 0;
     p_error := SQLERRM;
     n_pkg_vitalpos_log_general.write(2, 'Modulo: ' || v_Modulo || ' Error: ' || SQLERRM);
  END GetMontosMediosRendidoGuiaCO;

  /**************************************************************************************************
  * Genera los datos de los clientes activos de un comisionista tomando como parametro la cantidad de dias
  * que los mismos deberían tener alguna facturación asociados a este para ser considerado como tal
  * %v 12/08/2015 - MartinM: v1.0
  ***************************************************************************************************/
  PROCEDURE GetClientesActivosComisionista ( p_idcomisionista IN  documentos.identidad%TYPE            ,
                                             p_diasactivo     IN  INTEGER                   DEFAULT 30 ,
                                             p_cur_out        OUT cursor_type                          ,
                                             p_ok             OUT INTEGER                              ,
                                             p_error          OUT VARCHAR2                             ) IS

     v_Modulo VARCHAR2(100) := 'PKG_REPORTE_CENTRAL.GetClientesActivosComisionista' ;

  BEGIN

     p_ok := 0;

      OPEN p_cur_out FOR
    SELECT e2.dsrazonsocial nombrecomisionista,
           e.dsrazonsocial  nombreclientecomisionista,
           e.cdcuit         cuitclientecomisionista
      FROM clientescomisionistas cc,
           entidades             e ,
           entidades             e2
     WHERE cc.identidad      =  e.identidad
       AND cc.idcomisionista = e2.identidad
       AND EXISTS (SELECT 1
                     FROM documentos    d ,
                          movmateriales mm
                    WHERE  d.idmovmateriales         = mm.idmovmateriales
                      AND mm.idcomisionista          = cc.idcomisionista
                      AND ((SYSDATE - d.dtdocumento) <    p_diasactivo )
                      AND  d.identidad               = cc.identidad)
       AND cc.idcomisionista = p_idcomisionista;

     p_ok := 1;

  EXCEPTION WHEN OTHERS THEN
     p_ok    := 0;
     p_error := SQLERRM;
     n_pkg_vitalpos_log_general.write(2, 'Modulo: ' || v_Modulo || ' Error: ' || SQLERRM);
  END GetClientesActivosComisionista;

  /**************************************************************************************************
  * Muestra el saldo de los Clientes del Comisionista
  * %v 12/08/2015 - MartinM: v1.0
  * %v 28/03/2019 - LM: se modifica la consulta, se busca los clientes que hayan participado en una guia de comisionista
  ***************************************************************************************************/
  PROCEDURE GetSaldoClientesComisionista ( p_idcomisionista IN  documentos.identidad%TYPE            ,
                                           p_cur_out        OUT cursor_type                          ,
                                           p_ok             OUT INTEGER                              ,
                                           p_error          OUT VARCHAR2                             ) IS

     v_Modulo VARCHAR2(100) := 'PKG_REPORTE_CENTRAL.GetSaldoClientesComisionista' ;

  BEGIN

     p_ok := 0;

    OPEN p_cur_out FOR
    select * from (
        select clie.comi, clie.cdcuit, clie.dsrazonsocial, s.dssucursal, sum(pkg_cuenta_central.GetSaldo(c.idcuenta))  saldo
        from (
              select  distinct e.dsrazonsocial comi, d.identidadreal, eclie.cdcuit ,eclie.dsrazonsocial
               from guiasdetransporte gt,
                 tbldetalleguia dgt,
                 documentos d,
                 entidades e,
                 entidades eclie
              where gt.identidad=e.identidad
                  and e.identidad=p_idcomisionista
                  and gt.idguiadetransporte=dgt.idguiadetransporte
                  and dgt.iddoctrx=d.iddoctrx
                  and d.identidadreal=eclie.identidad
        ) clie, tblcuenta c , sucursales s
        where clie.identidadreal=c.identidad
        and c.cdsucursal=s.cdsucursal
        group by clie.comi,clie.cdcuit, clie.dsrazonsocial, s.dssucursal)
    where saldo>0;

     p_ok := 1;

  EXCEPTION WHEN OTHERS THEN
     p_ok    := 0;
     p_error := SQLERRM;
     n_pkg_vitalpos_log_general.write(2, 'Modulo: ' || v_Modulo || ' Error: ' || SQLERRM);
  END GetSaldoClientesComisionista;

  /**************************************************************************************************
  * Retorna la Deuda de transportistas por fecha y sucursal
  * %v 25/08/2015 - JBodnar: v1.0
  ***************************************************************************************************/
  PROCEDURE GetCuentaTransportista (p_sucursales IN VARCHAR2,
                                    p_fechadesde in   date,
                                    p_fechahasta in   date,
                                    p_cur_out    OUT cursor_type) IS

    v_modulo varchar2(100) := 'PKG_REPORTE_CENTRAL.GetCuentaTransportista';
     v_idReporte             VARCHAR2(40) := '';
  BEGIN
    v_idReporte := PKG_REPORTE_CENTRAL.SetSucursalesSeleccionadas(p_sucursales);

      open p_cur_out for
      select
      su.dssucursal Sucursal,
      dt.dtdeuda Fecha,
      tr.dsrazonsocial Empresa,
      gt.chofertxt Fletero,
      ee.dsrazonsocial Cliente,
      dt.amdiferencia Importe,
      d.sqcomprobante Guia
      from tbldeudatrans dt, entidades tr, sucursales su, tbltmp_sucursales_reporte rs,
      guiasdetransporte gt, documentos d, entidades ee
      where dt.idtransportista=tr.identidad
      and gt.identidad=ee.identidad
      and dt.dtdeuda BETWEEN trunc(p_fechadesde) AND trunc(p_fechahasta + 1)
      and rs.cdsucursal = dt.cdsucursal
      and rs.idreporte = v_idReporte
      and su.cdsucursal=dt.cdsucursal
      and gt.iddoctrx = d.iddoctrx
      and gt.idguiadetransporte=dt.idguiadetransporte;

      PKG_REPORTE_CENTRAL.CleanSucursalesSeleccionadas(v_idReporte);

  EXCEPTION WHEN OTHERS THEN
     n_pkg_vitalpos_log_general.write(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM);
     raise;
  End GetCuentaTransportista;

  /**************************************************************************************************
  * Retorna la Deuda de transportistas por fecha y sucursal
  * %v 27/10/2017 - JBodnar: v1.0
  * %v 19/12/2018 - IAquilano: se corrige cursor porque no tomaba en cuenta cuando tenia mas de una deuda en guia
  ***************************************************************************************************/
  PROCEDURE GetDeudaTransportista (p_sucursales IN VARCHAR2,
                                    p_fechadesde in   date,
                                    p_fechahasta in   date,
                                    p_cur_out    OUT cursor_type) IS

    v_modulo varchar2(100) := 'PKG_REPORTE_CENTRAL.GetDeudaTransportista';
     v_idReporte             VARCHAR2(40) := '';
  BEGIN
    v_idReporte := PKG_REPORTE_CENTRAL.SetSucursalesSeleccionadas(p_sucursales);

      open p_cur_out for
       select t.dsestado, t.Sucursal,
               min(t.Fecha) fecha,
               t.Empresa,
               t.cdcuit,
               t.Fletero,
               t.patente,
               t.Cliente,
               t.Guia,
               t.montoguia,
               (t.deudainicial) deudainicial,
               (t.pagos) pagos,
               (t.deudaactual) deudaactual ,
               max(t.diasvencida) diasvencida
      from (
      select r.dsestado, r.Sucursal,
             r.Fecha,
             r.Empresa,
             r.cdcuit,
             r.Fletero,
             r.patente,
             r.Cliente,
             r.Guia,
             r.montoguia,
             r.deudainicial,
             nvl(r.pagos,0) pagos,
             (r.deudainicial + nvl(r.pagos,0)) deudaactual,
             r.diasvencida
        from (
select distinct ec.dsestado, su.dssucursal Sucursal,
                     trunc(dt.dtdeuda) Fecha,
                     tr.dsrazonsocial Empresa,
                     ee.cdcuit,
                     gt.chofertxt Fletero,
                     gt.vehiculo patente,
                     ee.dsrazonsocial Cliente,
                     d.sqcomprobante Guia,
                     d.amdocumento montoguia,
                     /*( dt.amdiferencia)*/
                      (select sum(dt3.amdiferencia)
                        from tbldeudatrans dt3
                       where dt3.idguiadetransporte = dt.idguiadetransporte
                         and dt3.amdiferencia > 0) deudainicial,
                     (select sum(dt3.amdiferencia)
                        from tbldeudatrans dt3
                       where dt3.idguiadetransporte = dt.idguiadetransporte
                         and dt3.amdiferencia < 0) pagos,
                     round((trunc(sysdate) - trunc((dt.dtdeuda)))) diasvencida
                from tbldeudatrans     dt,
                     entidades         tr,
                     sucursales        su,
                     tbltmp_sucursales_reporte rs,
                     guiasdetransporte  gt,
                     documentos        d,
                     entidades         ee,
                     estadocomprobantes ec
               where dt.idtransportista = tr.identidad
                 and gt.identidad = ee.identidad
                 and ec.cdcomprobante = d.cdcomprobante
                 and ec.cdestado = gt.icestado
                 and dt.dtdeuda BETWEEN trunc(p_fechadesde) AND trunc(p_fechahasta + 1)
                    and rs.cdsucursal = dt.cdsucursal
                    and rs.idreporte = v_idReporte
                    and gt.icestado in ( 5, 7)  --Rendida/liquidada
                 and su.cdsucursal = dt.cdsucursal
               /*  and dt.dtdeuda =
                     (select min(dtdeuda)
                        from tbldeudatrans dt2 --Inicio de deuda
                       where dt2.idguiadetransporte = dt.idguiadetransporte)*/
                 and gt.iddoctrx = d.iddoctrx
                 and gt.idguiadetransporte = dt.idguiadetransporte
                ) r
      where (r.deudainicial + nvl(r.pagos,0)) > 0
    ) t
       group by
        t.dsestado,
             t.Sucursal,
             t.Empresa,
             t.cdcuit,
             t.Fletero,
             t.patente,
             t.Cliente,
             t.Guia,
             t.montoguia,
             t.deudainicial,
             t.pagos,
             t.deudaactual;

      PKG_REPORTE_CENTRAL.CleanSucursalesSeleccionadas(v_idReporte);

  EXCEPTION WHEN OTHERS THEN
     n_pkg_vitalpos_log_general.write(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM);
     raise;
  End GetDeudaTransportista;

  /**************************************************************************************************
  * Retorna la apertura de cuenta de deudores agrupada
  * %v 25/08/2015 - JBodnar: v1.0
  ***************************************************************************************************/
  PROCEDURE GetCuentaDeudoresGeneral (p_sucursales IN  VARCHAR2,
                                      p_fechahasta in  date,
                                      p_identidad  IN entidades.identidad%TYPE,
                                      p_cdestado   in  tbldocumentodeuda.cdestado%type,
                                      cur_out      OUT cursor_type) IS

    v_modulo varchar2(100) := 'PKG_REPORTE_CENTRAL.GetCuentaDeudoresGeneral';
     v_idReporte             VARCHAR2(40) := '';
  BEGIN
    v_idReporte := PKG_REPORTE_CENTRAL.SetSucursalesSeleccionadas(p_sucursales);

      open cur_out for
        select re.cdregion,
               re.dsregion region,
               s.cdsucursal,
               s.dssucursal sucursal,
               sum(pkg_documento_central.GetDeudaDocumento(d.iddoctrx, trunc( p_fechahasta))) deuda
        from tbldocumentodeuda dd,
             documentos d,
             entidades e,
             sucursales s,
             tbltmp_sucursales_reporte rs,
             tblregion                 re
        where (trunc(p_fechahasta + 1 ) between dd.dtestadoinicio and dd.dtestadofin
               or
              (dd.dtestadoinicio <= trunc( p_fechahasta + 1 ) and dd.dtestadofin is null) )
          and dd.cdestado = nvl(p_cdestado,dd.cdestado)
          and d.iddoctrx = dd.iddoctrx
          and s.cdsucursal = dd.cdsucursal
          and d.identidadreal = nvl(p_identidad,d.identidadreal)
          and e.identidad = d.identidadreal
          and rs.idreporte = v_idReporte
          and s.cdsucursal = rs.cdsucursal
          and re.cdregion  = s.cdregion
          and pkg_documento_central.GetDeudaDocumento(d.iddoctrx, trunc( p_fechahasta) ) <> 0
          group by re.cdregion,
                   re.dsregion ,
                   s.cdsucursal,
                   s.dssucursal ;

      PKG_REPORTE_CENTRAL.CleanSucursalesSeleccionadas(v_idReporte);

  EXCEPTION WHEN OTHERS THEN
     n_pkg_vitalpos_log_general.write(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM);
     raise;
  End GetCuentaDeudoresGeneral;

  /**************************************************************************************************
  * Retorna las facturas de guias pendientes de anular
  * %v 01/09/2016 - JBodnar: v1.0
  ***************************************************************************************************/
  PROCEDURE GetFactPendienteDeAnular (p_sucursales IN  VARCHAR2,
                                      p_fechahasta in  date,
                                      p_fechadesde in  date,
                                      p_identidad  IN entidades.identidad%TYPE,
                                      cur_out      OUT cursor_type) IS

    v_modulo varchar2(100) := 'PKG_REPORTE_CENTRAL.GetFactPendienteDeAnular';
     v_idReporte             VARCHAR2(40) := '';
  BEGIN
    v_idReporte := PKG_REPORTE_CENTRAL.SetSucursalesSeleccionadas(p_sucursales);

      open cur_out for
        Select distinct gui.iddoctrx IDGUIA, gui.sqcomprobante GUIA,
        decode(gt.icestado,1,'Creada',2,'Borrada',4,'Asignada','6','Anulada',gt.icestado) ESTADO,
        gui.dtdocumento FECHA_GUI,
        pkg_documento_central.GetDescDocumento (fg.iddoctrx) DOCUMENTO,
        ee.dsrazonsocial CLIENTE,
        ee.cdcuit CUIT,
        ec.dsestado ESTADO_FACTURA,
        fg.amdocumento IMPORTE,
        su.dssucursal,
        fg.dtdocumento FECHA_FACTURA
        From documentos gui, entidades ee, documentos fg, tbldetalleguia dt,
        guiasdetransporte gt, estadocomprobantes ec, tbltmp_sucursales_reporte rs, sucursales su
        Where (fg.cdcomprobante Like 'FC%' Or fg.cdcomprobante Like 'ND%')
        And fg.cdestadocomprobante In (1, 2, 4) -- Emitido, Impreso, Cancelado Parcialmente
        And fg.identidad = ee.identidad
        and fg.dtdocumento  between p_fechadesde and p_fechahasta
        and fg.identidadreal = nvl(p_identidad,fg.identidadreal)
        and  dt.idguiadetransporte =  gt.idguiadetransporte
        and  fg.iddoctrx=dt.iddoctrx
        and gui.iddoctrx = gt.iddoctrx
        and ee.identidad = fg.identidadreal
        and rs.idreporte = v_idReporte
        and rs.cdsucursal = su.cdsucursal
        and fg.cdsucursal = rs.cdsucursal
        AND ec.cdestado = fg.cdestadocomprobante
        and ec.cdcomprobante = fg.cdcomprobante
        and dt.icflete = 0
        And gt.icestado In  (2,6) --Borrada, Anulada
        And Exists (Select 1 -- Facturas en una guia trasacionadas
                    From tblmovcuenta mc Where mc.iddoctrx = fg.iddoctrx)
        and not Exists (Select 1
                     From tbldetalleguia dt, guiasdetransporte gt
                     Where dt.idguiadetransporte =  gt.idguiadetransporte
                      and fg.iddoctrx=dt.iddoctrx
                     And gt.icestado In  (1, 4))--Creada , Asignada
        ORDER BY  su.dssucursal, gui.sqcomprobante ;

      PKG_REPORTE_CENTRAL.CleanSucursalesSeleccionadas(v_idReporte);

  EXCEPTION WHEN OTHERS THEN
     n_pkg_vitalpos_log_general.write(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM);
     raise;
  End GetFactPendienteDeAnular;

  /**************************************************************************************************
  * Retorna la apertura de cuenta de deudores detallada
  * %v 25/08/2015 - JBodnar: v1.0
  ***************************************************************************************************/
  PROCEDURE GetCuentaDeudoresDetalle (p_cdsucursal  IN  sucursales.cdsucursal%TYPE,
                                      p_fechahasta in  date,
                                      p_identidad  IN entidades.identidad%TYPE,
                                      p_cdestado   in  tbldocumentodeuda.cdestado%type,
                                      cur_out      OUT cursor_type) IS

    v_modulo varchar2(100) := 'PKG_REPORTE_CENTRAL.GetCuentaDeudoresDetalle';
  BEGIN


    open cur_out for
        select distinct s.dssucursal,
               e.cdcuit cuit,
               e.dsrazonsocial || decode(d.identidad, d.identidadreal, null, ' (CF)') nombre,
               pkg_reporte_central.GetResponsableDeuda(d.iddoctrx) responsable_deuda,
               trunc(d.dtdocumento) fecha_documento,
               pkg_documento_central.GetDescDocumento(d.iddoctrx) documento,
               d.amdocumento importe_documento,
               pkg_documento_central.GetDeudaDocumento(d.iddoctrx, trunc( p_fechahasta)) importe_deuda,
               dd.dtestadoinicio, dd.dtestadofin
        from tbldocumentodeuda dd,
             documentos d,
             entidades e,
             sucursales s,
             tbltmp_sucursales_reporte rs
        where (trunc(p_fechahasta + 1 ) between dd.dtestadoinicio and dd.dtestadofin
               or
              (dd.dtestadoinicio <= trunc( p_fechahasta + 1 ) and dd.dtestadofin is null) )
          and dd.cdestado = p_cdestado
          and d.iddoctrx = dd.iddoctrx
          and e.identidad = d.identidadreal
          and s.cdsucursal = dd.cdsucursal
          and dd.cdsucursal = p_cdsucursal
          and e.identidad = nvl(p_identidad,e.identidad)
          and s.cdsucursal = rs.cdsucursal
          and pkg_documento_central.GetDeudaDocumento(d.iddoctrx, trunc( p_fechahasta) ) <> 0;

  EXCEPTION WHEN OTHERS THEN
     n_pkg_vitalpos_log_general.write(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM);
     raise;
  End GetCuentaDeudoresDetalle;

  /**************************************************************************************************
  * Retorna la apertura de Anticipo Posnet Banco
  * %v 25/08/2015 - JBodnar: v1.0
  * %v 23/09/2015 - LucianoF: v1.1 - Importe en negativo
  * %v 15/12/2016 - JBodnar: v1.1 - Buscar de la tblanticipoposnet
  ***************************************************************************************************/
  PROCEDURE GetCuentaAnticipoPosnet (p_sucursales IN  VARCHAR2,
                                     p_fechahasta in  date,
                                     p_cur_out    OUT cursor_type) IS

    v_modulo varchar2(100) := 'PKG_REPORTE_CENTRAL.GetCuentaAnticipoPosnet';
     v_idReporte             VARCHAR2(40) := '';
  BEGIN
    v_idReporte := PKG_REPORTE_CENTRAL.SetSucursalesSeleccionadas(p_sucursales);

    open p_cur_out for
    select dssucursal,cdcuit, dsrazonsocial, vlestablecimiento as establecimiento ,dstipo as cdtipo, dtoperacion as fechapago, saldo
    from tblanticipoposnet a
    where trunc(a.dtproceso) = trunc(p_fechahasta)
    and a.dssucursal in (select s.dssucursal
                         from sucursales s, tbltmp_sucursales_reporte sr
                         where s.cdsucursal=sr.cdsucursal
                         and sr.idreporte=v_idReporte);

      PKG_REPORTE_CENTRAL.CleanSucursalesSeleccionadas(v_idReporte);

  EXCEPTION WHEN OTHERS THEN
     n_pkg_vitalpos_log_general.write(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM);
     raise;
  End GetCuentaAnticipoPosnet;


  /**************************************************************************************************
  * Retorna el total de clientes por vendedor
  * %v 08/04/2016 - LucianoF: v1.0
  * %v 11/03/2022 - APW - Agrego TLKs
  ***************************************************************************************************/
  PROCEDURE GetCarteraVendedores (p_sucursales IN  VARCHAR2,
                                  p_cur_out    OUT cursor_type) IS

    v_modulo varchar2(100) := 'PKG_REPORTE_CENTRAL.GetCarteraVendedores';
     v_idReporte             VARCHAR2(40) := '';
  BEGIN
    v_idReporte := PKG_REPORTE_CENTRAL.SetSucursalesSeleccionadas(p_sucursales);

      open p_cur_out for
      with vt as -- vendedores y telemarketers
       (select cvv.cdsucursal, cvv.idviajante idpersona, cvv.identidad
          from clientesviajantesvendedores cvv
         where cvv.dthasta =
               (select max(dthasta) from clientesviajantesvendedores)
        union
        select ct.cdsucursal, ct.idpersona, ct.identidad
          from clientestelemarketing ct
         where ct.icactivo = 1)
      SELECT v.idpersona,
             su.cdsucursal,
             su.dssucursal,
             v.cdlegajo,
             v.dsapellido || ', ' || v.dsnombre vendedor,
             count(*) cantidad
        from vt                        cv,
             entidades                 e,
             personas                  v,
             sucursales                su,
             tbltmp_sucursales_reporte sr
       where cv.identidad = e.identidad
         and cv.cdsucursal = su.cdsucursal
         and cv.idpersona = v.idpersona
         and v.icactivo = 1 -- solo los vendedores activos
         and sr.cdsucursal = su.cdsucursal
         and sr.idreporte = v_idReporte
       group by v.idpersona,
                su.cdsucursal,
                su.dssucursal,
                v.cdlegajo,
                v.dsapellido || ', ' || v.dsnombre
       order by count(*) desc;
      PKG_REPORTE_CENTRAL.CleanSucursalesSeleccionadas(v_idReporte);

  EXCEPTION WHEN OTHERS THEN
     n_pkg_vitalpos_log_general.write(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM);
     raise;
  End GetCarteraVendedores;

  /**************************************************************************************************
  * Retorna el detalle de clientes por vendedor
  * %v 08/04/2016 - LucianoF: v1.0
  * %v 14/12/2021 - LM - Se agregan emails de aplicaciones configuradas
  * %v 11/03/2022 - APW - Quito VitalDigital y agego TLKs
  ***************************************************************************************************/
  PROCEDURE GetCarteraVendedoresDetalle (p_idpersona IN  clientesviajantesvendedores.idviajante%TYPE,
                                         p_cdsucursal IN clientesviajantesvendedores.cdsucursal%TYPE,
                                         p_cur_out    OUT cursor_type) IS
    v_modulo varchar2(100) := 'PKG_REPORTE_CENTRAL.GetCarteraVendedoresDetalle';
  BEGIN

      open p_cur_out for
      with vt as -- vendedores y telemarketers
       (select cvv.cdsucursal, cvv.idviajante idpersona, cvv.identidad
          from clientesviajantesvendedores cvv
         where cvv.dthasta =
               (select max(dthasta) from clientesviajantesvendedores)
           and cvv.cdsucursal = p_cdsucursal
           and cvv.idviajante = p_idpersona
        union
        select ct.cdsucursal, ct.idpersona, ct.identidad
          from clientestelemarketing ct
         where ct.icactivo = 1
           and ct.cdsucursal = p_cdsucursal
           and ct.idpersona = p_idpersona),
      TiendaOnline as
       (select cu.identidad, ep.vlaplicacion, ep.mail, cu.nombrecuenta
          from tblentidadaplicacion ep, tblcuenta cu
         where ep.vlaplicacion in ('TiendaOnline')
           and ep.icactivo = 1
           and ep.idcuenta = cu.idcuenta
           and cu.cdsucursal = p_cdsucursal)
      SELECT e.cdcuit,
             e.dsrazonsocial,
             v.cdlegajo,
             v.dsapellido || ', ' || v.dsnombre vendedor,
             s.dssucursal,
             nvl(tio.nombrecuenta, '---') Cuenta_TO,
             nvl(tio.vlaplicacion, '---') aplicacion_TO,
             nvl(tio.mail, '---') Mail_TO,
             nvl(null, '---') Cuenta_VD,
             nvl(null, '---') aplicacion_VD,
             nvl(null, '---') Mail_VD
        from vt cv, entidades e, personas v, sucursales s, TiendaOnline tio
       where cv.identidad = e.identidad
         and cv.idpersona = p_idpersona
         and cv.idpersona = v.idpersona
         and s.cdsucursal = cv.cdsucursal
         and e.identidad = tio.identidad(+)
         and trim(cv.cdsucursal) = trim(p_cdsucursal)
       order by e.cdcuit;
    
  EXCEPTION WHEN OTHERS THEN
     n_pkg_vitalpos_log_general.write(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM);
     raise;
  End GetCarteraVendedoresDetalle;





  /**************************************************************************************************
  * Retorna el detalle de clientes por vendedor
  * %v 08/04/2016 - LucianoF: v1.0
  * %v 26/04/2016 - APW: filtro bajas
  ***************************************************************************************************/
  PROCEDURE GetUbicacionMateriales (p_cdsector IN  sectores.cdsector%TYPE,
                                    p_cdgrupo IN gruposarticulo.cdgrupoarticulos%TYPE,
                                    p_control IN tblcontrolstock.cdgrupocontrol%TYPE,
                                    p_sucursal IN VARCHAR2,
                                    p_cur_out    OUT cursor_type) IS
    v_modulo varchar2(100) := 'PKG_REPORTE_CENTRAL.GetUbicacionMateriales';
    v_dtOperativa         date := N_PKG_VITALPOS_CORE.GetDT();
  BEGIN


      IF p_control IS NULL then
                   open p_cur_out for
           SELECT  (select dssucursal from sucursales where trim(cdsucursal) = trim(p_sucursal)) sucursal,
                   '' control,
                    a.cdarticulo,
                    da.vldescripcion,
                    NVL(pkg_precio.GetPrecio(v_dtOperativa, a.cdarticulo, 'SA', p_sucursal), 0) precioUnitario,
                    se.dssector,
                    ga.dsgrupoarticulos,
                    (select ua.cdubicacion from  ubicacionarticulos ua,  sectores se
                      where  ua.cdarticulo = da.cdarticulo
                             AND ua.cdalmacen = se.cdsector
                             AND ua.cdsucursal=p_sucursal) ubicacion
           FROM descripcionesarticulos da,
                sectores se,
                gruposarticulo ga,
                articulos a
          WHERE
            a.cdarticulo = da.cdarticulo
            AND a.cdgrupoarticulos = ga.cdgrupoarticulos
            AND a.cdsector = se.cdsector
            AND trim(se.cdsector) = NVL(p_cdsector, trim(se.cdsector))
            AND trim(ga.cdgrupoarticulos) = NVL(p_cdgrupo, trim(ga.cdgrupoarticulos))
            and a.cdestadoplu = '00';
    ELSE
            open p_cur_out for
           SELECT   (select dssucursal from sucursales where trim(cdsucursal) = trim(p_sucursal)) sucursal,
                    cs.cdgrupocontrol control,
                    a.cdarticulo,
                    da.vldescripcion,
                    NVL(pkg_precio.GetPrecio(v_dtOperativa, a.cdarticulo, 'SA', p_sucursal), 0) precioUnitario,
                    se.dssector,
                    ga.dsgrupoarticulos,
                    (select ua.cdubicacion from  ubicacionarticulos ua,  sectores se
                      where  ua.cdarticulo = da.cdarticulo
                             AND ua.cdalmacen = se.cdsector
                             AND ua.cdsucursal=p_sucursal) ubicacion
           FROM tblcontrolstock cs,
                descripcionesarticulos da,
                sectores se,
                gruposarticulo ga,
                articulos a
          WHERE
             cs.cdarticulo = da.cdarticulo
            AND a.cdarticulo = da.cdarticulo
            AND a.cdgrupoarticulos = ga.cdgrupoarticulos
            AND a.cdsector = se.cdsector
            AND trim(se.cdsector) = NVL(p_cdsector, trim(se.cdsector))
            AND trim(ga.cdgrupoarticulos) = NVL(p_cdgrupo, trim(ga.cdgrupoarticulos))
            AND cs.cdgrupocontrol = NVL(p_control, cs.cdgrupocontrol)
            AND cs.cdsucursal = p_sucursal
            and a.cdestadoplu = '00';

    END IF;
  EXCEPTION WHEN OTHERS THEN
     n_pkg_vitalpos_log_general.write(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM);
     raise;
  End GetUbicacionMateriales;







  /**************************************************************************************************
  * Retorna la apertura de ingreso Posnet Banco
  * %v 25/08/2015 - JBodnar: v1.0
  ***************************************************************************************************/
  PROCEDURE GetCuentaIngresoPosnet (p_sucursales IN  VARCHAR2,
                                    p_fechadesde in  date,
                                    p_fechahasta in  date,
                                    p_cur_out    OUT cursor_type) IS

    v_modulo varchar2(100) := 'PKG_REPORTE_CENTRAL.GetCuentaIngresoPosnet';
     v_idReporte             VARCHAR2(40) := '';
  BEGIN
    v_idReporte := PKG_REPORTE_CENTRAL.SetSucursalesSeleccionadas(p_sucursales);

      open p_cur_out for
      select dssucursal, cdcuit, dsrazonsocial, establecimiento, dtingreso, cdtipo, fechapago, amingreso
      from (select s.dssucursal, e.cdcuit, e.dsrazonsocial, tr.vlestablecimiento establecimiento,
                   trunc(i.dtingreso) dtingreso,
                   pkg_ingreso_central.GetDescTipo(i.cdconfingreso, i.cdsucursal) cdtipo, tr.dtoperacion fechapago,
                   i.amingreso amingreso
            from tblingreso i,
                 tblcuenta c,
                 entidades e,
                 tblconfingreso ci,
                 tblaccioningreso a,
                 tblmovcuenta mc,
                 sucursales s,
                 tblposnetbanco pb,
                 tblposnet_transmitido tr,
                 tbltmp_sucursales_reporte sr
            where mc.dtmovimiento between trunc( p_fechadesde) and trunc( p_fechahasta + 1 )
             and i.idingreso = mc.idingreso
              and pb.idingreso = i.idingreso
              and tr.idtransmitido = pb.idtransmitido
              and tr.idarchivo <> 'Migracion'
              and c.idcuenta = i.idcuenta
              and e.identidad = c.identidad
              and ci.cdconfingreso = i.cdconfingreso
              and ci.cdforma = '4' --PB
              and ci.cdsucursal = i.cdsucursal
              and a.cdaccion = ci.cdaccion
              and s.cdsucursal = c.cdsucursal
              and s.cdsucursal = sr.cdsucursal
              and sr.idreporte = v_idReporte
      )
      order by dssucursal, cdtipo, cdcuit, dtingreso;

      PKG_REPORTE_CENTRAL.CleanSucursalesSeleccionadas(v_idReporte);

  EXCEPTION WHEN OTHERS THEN
     n_pkg_vitalpos_log_general.write(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM);
     raise;
  End GetCuentaIngresoPosnet;

  /**************************************************************************************************
  * Reporte de egresos que no son PB y que no estan aplicados totalmente
  * %v 22/09/2015 - JBodnar: v1.0
  ***************************************************************************************************/
  PROCEDURE GetDeudaEgresos (p_sucursales IN  VARCHAR2,
                             p_fechadesde in  date,
                             p_fechahasta in  date,
                             p_cur_out    OUT cursor_type) IS

    v_modulo varchar2(100) := 'PKG_REPORTE_CENTRAL.GetDeudaEgresos';
     v_idReporte             VARCHAR2(40) := '';
  BEGIN
    v_idReporte := PKG_REPORTE_CENTRAL.SetSucursalesSeleccionadas(p_sucursales);

     open p_cur_out for
     select dssucursal,cdcuit, dsrazonsocial, descripcion, dtingreso, saldo
     from (select s.dssucursal, ee.cdcuit, ee.dsrazonsocial,
                   pkg_ingreso_central.GetDescTipo(ii.cdconfingreso,ii.cdsucursal) descripcion, ii.dtingreso,
                   sum(ai.vlmultiplicador*pkg_ingreso_central.GetImporteNoAplicado(ii.idingreso,trunc( p_fechahasta))) saldo
     From tblingreso ii,
     tblconfingreso ci,
     tblaccioningreso ai,
     tblcuenta cu,
     entidades ee,
     sucursales s,
     tbltmp_sucursales_reporte sr
     where ii.dtingreso between trunc( p_fechadesde + 1 ) and trunc( p_fechahasta + 1 )
     and ii.cdconfingreso= ci.cdconfingreso
     and ci.cdaccion = ai.cdaccion
     and ai.vlmultiplicador = -1 --Multiplicador de egresos
     and ii.cdestado in (1, 2) --No aplicado / Parcialmente aplicado
     and ci.cdforma <> '4' --No es contracargo de Pb
     and ii.idcuenta = cu.idcuenta
     and cu.identidad = ee.identidad
     and s.cdsucursal = ii.cdsucursal
     and s.cdsucursal = sr.cdsucursal
     and sr.idreporte = v_idReporte
     And Exists (Select 1 --Transaccionada
                  From tblmovcuenta mc Where mc.idingreso = ii.idingreso)
      )
      where saldo <> 0
      order by dssucursal, cdcuit;

      PKG_REPORTE_CENTRAL.CleanSucursalesSeleccionadas(v_idReporte);

  EXCEPTION WHEN OTHERS THEN
     n_pkg_vitalpos_log_general.write(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM);
     raise;
 End GetDeudaEgresos;


   /**************************************************************************************************
  * Reporte de egresos con deuda
  * %v 21/03/2018 - IAquilano
  ***************************************************************************************************/
  PROCEDURE GetEgresosConDeuda (p_sucursales IN  VARCHAR2,
                                     p_identidad IN entidades.identidad%type,
                                     p_cur_out    OUT cursor_type) IS

    v_modulo varchar2(100) := 'PKG_REPORTE_CENTRAL.GetEgresosConDeuda';
     v_idReporte             VARCHAR2(40) := '';
  BEGIN
    v_idReporte := PKG_REPORTE_CENTRAL.SetSucursalesSeleccionadas(p_sucursales);

     open p_cur_out for
     select dssucursal,nvl(cdcuit,'-')cdcuit, dsrazonsocial, nombrecuenta,vlcomercio, desc_egreso, dtingreso, deuda
     from (select s.dssucursal, ee.cdcuit, ee.dsrazonsocial, cu.nombrecuenta, nvl(cc.vlcomercio,'-') vlcomercio,
                   pkg_ingreso_central.GetDescIngreso(ii.cdconfingreso,ii.cdsucursal) desc_egreso, ii.dtingreso,
                    ai.vlmultiplicador*pkg_ingreso_central.GetImporteNoAplicado(ii.idingreso,trunc(sysdate))  deuda
     From tblingreso ii,
     tblconfingreso ci,
     tblaccioningreso ai,
     tblcuenta cu,
     entidades ee,
     sucursales s,
     tblclcontracargo cc,
     tbltmp_sucursales_reporte sr
     where /*ii.dtingreso < sysdate +1
     and*/ ii.cdconfingreso= ci.cdconfingreso
     and ii.cdsucursal=ci.cdsucursal
     and ci.cdmedio <> '5'--cheque
     and ci.cdaccion = ai.cdaccion
     and ai.vlmultiplicador = -1 --Multiplicador de egresos
     and ii.cdestado in (1, 2) --No aplicado / Parcialmente aplicado
     and ii.idcuenta = cu.idcuenta
     and cu.identidad = ee.identidad
     and ee.identidad = nvl(p_identidad, ee.identidad)
     and ii.idingreso = cc.idingreso (+)
     and s.cdsucursal = ii.cdsucursal
     and s.cdsucursal = sr.cdsucursal
     and sr.idreporte = v_idReporte
  /*   And Exists (Select 1 --Transaccionada
                  From tblmovcuenta mc Where mc.idingreso = ii.idingreso)*/
    -- group by s.dssucursal, ee.cdcuit, ee.dsrazonsocial, cu.nombrecuenta, pkg_ingreso_central.GetDescTipo(ii.cdconfingreso,ii.cdsucursal), ii.dtingreso
      )
      where deuda <> 0
      order by dssucursal, cdcuit, dtingreso;

      PKG_REPORTE_CENTRAL.CleanSucursalesSeleccionadas(v_idReporte);

  EXCEPTION WHEN OTHERS THEN
     n_pkg_vitalpos_log_general.write(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM);
     raise;
  End GetEgresosConDeuda;

  /**************************************************************************************************
  * Retorna la apertura de anticipo cliente
  * %v 25/08/2015 - JBodnar: v1.0
  * %v 22/09/2015 - MartinM: v1.1 - Le agregamos la fecha del ingreso
  * %v 23/09/2015 - LucianoF: v1.2 - Importe en negativo
  * %v 15/07/2015 - JBodnar: v1.3 - Consulta la tblanticipocliente que se carga por un proceso batch
  ***************************************************************************************************/
  PROCEDURE GetCuentaAnticipoClientebkp (p_sucursales IN  VARCHAR2,
                                p_fechahasta in  date,
                                p_cur_out    OUT cursor_type) IS

    v_modulo varchar2(100) := 'PKG_REPORTE_CENTRAL.GetCuentaAnticipoCliente';
     v_idReporte             VARCHAR2(40) := '';
  BEGIN
    v_idReporte := PKG_REPORTE_CENTRAL.SetSucursalesSeleccionadas(p_sucursales);

    open p_cur_out for
    select dssucursal, cdcuit, dsrazonsocial, dtingreso, saldo
    from tblanticipocliente a
    where trunc(a.dtanticipo) = trunc(p_fechahasta)
    and a.dssucursal in (select s.dssucursal
                         from sucursales s, tbltmp_sucursales_reporte sr
                         where s.cdsucursal=sr.cdsucursal
                         and sr.idreporte=v_idReporte);

 PKG_REPORTE_CENTRAL.CleanSucursalesSeleccionadas(v_idReporte);

  EXCEPTION WHEN OTHERS THEN
     n_pkg_vitalpos_log_general.write(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM);
     raise;
  End GetCuentaAnticipoClientebkp;

  /*****************************************************************************************

  * IAquilano - 28/03/2019 - Retorna la nueva apertura de Anticipo Cliente

 ******************************************************************************************/

  PROCEDURE GetCuentaAnticipoCliente (p_sucursales IN  VARCHAR2,
                                      p_fechahasta in  date,
                                      p_cur_out    OUT cursor_type) IS


  v_modulo        varchar2(100) := 'PKG_REPORTE_CENTRAL.GetCuentaAnticipoCliente';
  v_idReporte     VARCHAR2(40) := '';

begin

    v_idReporte := PKG_REPORTE_CENTRAL.SetSucursalesSeleccionadas(p_sucursales);

OPEN p_cur_out FOR
--- este se corre en la sucursal para abrir el asiento que se mando a SAP
select s.dssucursal,
       case
         when dsrazonsocial = 'Consumidor Final' then
          'x'
         else
          cdcuit
       end as cdcuit,
       dsrazonsocial,
       P_fechahasta as dtingreso,
       sum(monto)*(-1) as saldo--muestro saldo con signo invertido
  from (select *
          from (select e.cdcuit,
                       e.dsrazonsocial,
                       i.cdsucursal,
                       pkg_ingreso_central.GetDescIngreso(ci.cdconfingreso, i.cdsucursal) tipo,
                       nvl(a.vlmultiplicador * pkg_ingreso_central.GetImporteNoAplicado(i.idingreso, to_date(trunc(mc.dtmovimiento))), 0) monto,
                       'ingresos del día no aplicados' motivo
                --into v_amIngresosNoAplicados
                  from tblingreso       i,
                       tblconfingreso   ci,
                       tblaccioningreso a,
                       tblmovcuenta     mc,
                       tblcuenta        c,
                       entidades        e
                 where mc.dtmovimiento between to_date('01/' || to_char(P_fechahasta, 'mm/yyyy'), 'dd/mm/yyyy') and to_date(P_fechahasta + 1)
                   and i.idingreso = mc.idingreso
                   and i.cdsucursal in (select s.cdsucursal
                                          from sucursales s, tbltmp_sucursales_reporte sr
                                         where s.cdsucursal=sr.cdsucursal
                                           and sr.idreporte=v_idReporte)
                   and i.cdsucursal = ci.cdsucursal
                      --04/09/2015-MarianoL: No hay que considerar los rechazados hoy
                   and not exists
                 (select 1
                          from tblingreso i2, tblconfingreso ci2
                         where i2.idingresorechazado = i.idingreso
                           and trunc(i2.dtingreso) = trunc(mc.dtmovimiento)
                           and i2.cdsucursal in (select s.cdsucursal
                                                   from sucursales s, tbltmp_sucursales_reporte sr
                                                  where s.cdsucursal=sr.cdsucursal
                                                    and sr.idreporte=v_idReporte)
                           and ci2.cdconfingreso = i2.cdconfingreso
                           and ci2.cdsucursal = i2.cdsucursal) --No rechazado el mismo día
                      --04/09/2015-MarianoL: No hay que considerar los rechazados hoy
                   and ci.cdconfingreso = i.cdconfingreso
                   and ci.cdmedio <> '9' --Prestamo Comisionista
                   and not (ci.cdforma = '4' /*PB*/ or (ci.cdmedio = '5' and ci.cdaccion in ('3', '2') /*Cheq.Rechazado*/ ))
                   and a.cdaccion = ci.cdaccion
                   and mc.idcuenta = c.idcuenta
                   and c.identidad = e.identidad)
         where monto <> 0
        union all
        select *
          from (select e.cdcuit,
                       e.dsrazonsocial,
                       i.cdsucursal,
                       pkg_ingreso_central.GetDescIngreso(ci.cdconfingreso, i.cdsucursal) tipo,
                       nvl(c.amimputado * -1, 0) monto,
                       'ingresos de días anteriores que hoy se usaron para pagar algo'
                --into v_amAnterioresQuePagaron
                  from tblcobranza    c,
                       tblingreso     i,
                       tblconfingreso ci,
                       tblmovcuenta   mc,
                       tblcuenta      c,
                       entidades      e
                 where c.dtimputado between to_date('01/' || to_char(P_fechahasta, 'mm/yyyy'), 'dd/mm/yyyy') and to_date(P_fechahasta + 1) --Fecha de aplicación
                   and i.idingreso = c.idingreso
                   and mc.idingreso = i.idingreso
                   and i.cdsucursal   in (select s.cdsucursal
                                            from sucursales s, tbltmp_sucursales_reporte sr
                                           where s.cdsucursal=sr.cdsucursal
                                             and sr.idreporte=v_idReporte)
                   and i.cdsucursal = ci.cdsucursal
                   and mc.dtmovimiento < trunc(c.dtimputado) --Fecha del ingreso a la cuenta
                   and ci.cdconfingreso = i.cdconfingreso
                   and ci.cdmedio <> '9' --Prestamo Comisionista
                   and not (ci.cdforma = '4' /*PB*/ or (ci.cdmedio = '5' and ci.cdaccion in ('3', '2') /*Cheq.Rechazado*/ ))
                   and mc.idcuenta = c.idcuenta
                   and c.identidad = e.identidad)
         where monto <> 0
        union all
        select *
          from (select e.cdcuit,
                       e.dsrazonsocial,
                       i.cdsucursal,
                       pkg_ingreso_central.GetDescIngreso(ci.cdconfingreso, i.cdsucursal) tipo,
                       nvl(c.amimputado, 0) monto,
                       'ingresos de días anteriores que hoy fueron pagados por otro ingreso'
                -- into v_amAnterioresPagos
                  from tblcobranza    c,
                       tblingreso     i,
                       tblconfingreso ci,
                       tblmovcuenta   mc,
                       tblcuenta      c,
                       entidades      e
                 where c.dtimputado between to_date('01/' || to_char(P_fechahasta, 'mm/yyyy'), 'dd/mm/yyyy') and to_date(P_fechahasta + 1) --Fecha de aplicación
                   and i.idingreso = c.idingreso_pago
                   and mc.idingreso = i.idingreso
                   and i.cdsucursal in (select s.cdsucursal
                                          from sucursales s, tbltmp_sucursales_reporte sr
                                         where s.cdsucursal=sr.cdsucursal
                                           and sr.idreporte=v_idReporte)
                   and i.cdsucursal = ci.cdsucursal
                   and mc.dtmovimiento < trunc(c.dtimputado) --Fecha del ingreso a la cuenta
                   and ci.cdconfingreso = i.cdconfingreso
                   and ci.cdmedio <> '9' --Prestamo Comisionista
                   and not (ci.cdforma = '4' /*PB*/ or (ci.cdmedio = '5' and ci.cdaccion in ('3', '2', '6') /*Cheq.Rechazado*/ ))
                   and mc.idcuenta = c.idcuenta
                   and c.identidad = e.identidad)
         where monto <> 0
        union all
        select *
          from (select e.cdcuit,
                       e.dsrazonsocial,
                       d.cdsucursal,
                       pkg_core_documento.GetDescDocumento(d.iddoctrx) tipo,
                       nvl(pkg_core_documento.GetDeudaDocumento(d.iddoctrx, to_date(trunc(dtdocumento)), 1), 0) monto,
                       'NC que al final del día tienen saldo'
                --into v_amNC
                  from documentos d, tblcuenta c, entidades e
                 where d.dtdocumento between to_date('01/' || to_char(P_fechahasta, 'mm/yyyy'), 'dd/mm/yyyy') and to_date(P_fechahasta + 1) --Fecha de la NC
                   and substr(d.cdcomprobante, 1, 2) = 'NC'
                   and d.cdsucursal   in (select s.cdsucursal
                                            from sucursales s, tbltmp_sucursales_reporte sr
                                           where s.cdsucursal=sr.cdsucursal
                                             and sr.idreporte=v_idReporte)
                   and not exists
                 (select 1
                          from tblorigendocumento od, tblorigen o
                         where od.iddoctrx = d.iddoctrx
                           and o.cdorigen = od.cdorigen
                           and o.cdgrupoorigen = '2') --NC ajuste de CL
                   and d.idcuenta = c.idcuenta
                   and c.identidad = e.identidad)
         where monto <> 0
        union all
        select *
          from (select e.cdcuit,
                       e.dsrazonsocial,
                       d.cdsucursal,
                       pkg_core_documento.GetDescDocumento(d.iddoctrx) tipo,
                       nvl(c.amimputado * -1, 0) monto,
                       'NC de días anteriores que hoy se usaron para pagar algo'
                --into v_amNC
                  from tblcobranza c, documentos d, tblcuenta c, entidades e
                 where c.dtimputado between to_date('01/' || to_char(P_fechahasta, 'mm/yyyy'), 'dd/mm/yyyy') and to_date(P_fechahasta + 1) --Fecha de aplicación
                   and d.iddoctrx = c.iddoctrx_pago
                   and d.cdsucursal in (select s.cdsucursal
                                          from sucursales s, tbltmp_sucursales_reporte sr
                                         where s.cdsucursal=sr.cdsucursal
                                           and sr.idreporte=v_idReporte)
                   and d.dtdocumento < trunc(c.dtimputado)
                   and d.idcuenta = c.idcuenta
                   and c.identidad = e.identidad)
         where monto <> 0) rep,
       sucursales s
 where rep.cdsucursal = s.cdsucursal
 group by  cdcuit, dsrazonsocial, dssucursal
 order by 1;


Exception
  when others then
    n_pkg_vitalpos_log_general.write(2, 'Modulo: ' || v_modulo || '  Error: ' || Sqlerrm);

end GetCuentaAnticipoCliente;



/*****************************************************************************************

  * Jorge Rojas - 21/01/2022 - Retorna la nueva apertura de anticipo cliente abierto

 ******************************************************************************************/

  PROCEDURE GetCuentaAnticipoCliAbierto (p_cdsucursal IN  VARCHAR2,
                                      p_fecha in date,
                                      p_cur_out    OUT cursor_type) IS

  v_modulo        varchar2(100) := 'PKG_REPORTE_CENTRAL.GetCuentaAnticipoCliAbierto';
  p_fechaAux varchar2(12) := to_char(P_fecha, 'dd/mm/yyyy');
  
BEGIN
OPEN p_cur_out FOR

select * from (
				select e.cdcuit, e.dsrazonsocial, pkg_ingreso_central.GetDescIngreso(ci.cdconfingreso, ci.cdsucursal) tipo, nvl(a.vlmultiplicador*pkg_ingreso_central.GetImporteNoAplicado(i.idingreso, to_date(p_fechaAux||'23:59:59','dd/mm/yyyy  hh24:mi:ss')),0) monto, 'ingresos del día no aplicados' motivo
					  --into v_amIngresosNoAplicados
					  from tblingreso i,
						   tblconfingreso ci,
						   tblaccioningreso a,
						   tblmovcuenta mc,
						   tblcuenta c,
						   entidades e
					  where mc.dtmovimiento between to_date(p_fechaAux,'dd/mm/yyyy') and to_date(p_fechaAux ||'23:59:59','dd/mm/yyyy  hh24:mi:ss')
						and i.idingreso = mc.idingreso
						and i.cdsucursal = p_cdsucursal
						and ci.cdsucursal = i.cdsucursal
				--04/09/2015-MarianoL: No hay que considerar los rechazados hoy
						and not exists (select 1
										from tblingreso i2,
											 tblconfingreso ci2
										where i2.idingresorechazado = i.idingreso
										  and trunc(i2.dtingreso) = trunc(mc.dtmovimiento)
										  and ci2.cdconfingreso = i2.cdconfingreso
										  and ci2.cdsucursal = i2.cdsucursal)  --No rechazado el mismo día
				--04/09/2015-MarianoL: No hay que considerar los rechazados hoy
						and ci.cdconfingreso = i.cdconfingreso
						and ci.cdmedio <> '9' --Prestamo Comisionista
						and not(ci.cdforma = '4' /*PB*/ or (ci.cdmedio = '5' and ci.cdaccion in ('3','2') /*Cheq.Rechazado*/) )
						and a.cdaccion = ci.cdaccion
						and mc.idcuenta = c.idcuenta
						and c.identidad = e.identidad
              )
where monto <> 0
union all
select * from (
				select e.cdcuit, e.dsrazonsocial, pkg_ingreso_central.GetDescIngreso(ci.cdconfingreso, ci.cdsucursal) tipo, nvl(c.amimputado*-1,0) monto, 'ingresos de días anteriores que hoy se usaron para pagar algo'
					  --into v_amAnterioresQuePagaron
					  from tblcobranza c,
						   tblingreso i,
						   tblconfingreso ci,
						   tblmovcuenta mc,
						   tblcuenta c,
						   entidades e
					  where c.dtimputado between to_date(p_fechaAux,'dd/mm/yyyy') and to_date(p_fechaAux ||'23:59:59','dd/mm/yyyy  hh24:mi:ss')  --Fecha de aplicación
						and i.idingreso = c.idingreso
						and mc.idingreso = i.idingreso
						and i.cdsucursal = p_cdsucursal
						and i.cdsucursal = ci.cdsucursal
						and mc.dtmovimiento < to_date(p_fechaAux,'dd/mm/yyyy')                   --Fecha del ingreso a la cuenta
						and ci.cdconfingreso = i.cdconfingreso
						and ci.cdmedio <> '9' --Prestamo Comisionista
						and not(ci.cdforma = '4' /*PB*/ or (ci.cdmedio = '5' and ci.cdaccion in ('3','2') /*Cheq.Rechazado*/))
						and mc.idcuenta = c.idcuenta
						and c.identidad = e.identidad
              )
where monto <> 0
union all
select * from (
				select e.cdcuit,e.dsrazonsocial,pkg_ingreso_central.GetDescIngreso(ci.cdconfingreso, ci.cdsucursal) tipo, nvl(c.amimputado,0) monto, 'ingresos de días anteriores que hoy fueron pagados por otro ingreso'
					 -- into v_amAnterioresPagos
					  from tblcobranza c,
						   tblingreso i,
						   tblconfingreso ci,
						   tblmovcuenta mc,
						   tblcuenta c,
						   entidades e
					  where c.dtimputado between to_date(p_fechaAux,'dd/mm/yyyy') and to_date(p_fechaAux ||'23:59:59','dd/mm/yyyy  hh24:mi:ss')  --Fecha de aplicación
						and i.idingreso = c.idingreso_pago
						and mc.idingreso = i.idingreso
						and i.cdsucursal = p_cdsucursal
						and ci.cdsucursal = i.cdsucursal
						and mc.dtmovimiento < to_date(p_fechaAux,'dd/mm/yyyy')                   --Fecha del ingreso a la cuenta
						and ci.cdconfingreso = i.cdconfingreso
						and ci.cdmedio <> '9' --Prestamo Comisionista
						and not(ci.cdforma = '4' /*PB*/ or (ci.cdmedio = '5' and ci.cdaccion in ('3','2','6') /*Cheq.Rechazado*/))
						and mc.idcuenta = c.idcuenta
						and c.identidad = e.identidad
              )
where monto <> 0
union all
select * from (
				select e.cdcuit, e.dsrazonsocial,pkg_core_documento.GetDescDocumento(d.iddoctrx) tipo, nvl(pkg_core_documento.GetDeudaDocumento(d.iddoctrx, to_date(p_fechaAux ||'23:59:59','dd/mm/yyyy  hh24:mi:ss'), 1),0) monto, 'NC que al final del día tienen saldo'
					  --into v_amNC
					  from documentos d,
						   tblcuenta c,
						   entidades e
					  where d.dtdocumento between to_date(p_fechaAux,'dd/mm/yyyy') and to_date(p_fechaAux ||'23:59:59','dd/mm/yyyy  hh24:mi:ss')  --Fecha de la NC
						and substr(d.cdcomprobante,1,2) = 'NC'
						and d.cdsucursal = p_cdsucursal
						and not exists (select 1
										from tblorigendocumento od,
											 tblorigen o
										where od.iddoctrx = d.iddoctrx
										  and o.cdorigen = od.cdorigen
										  and o.cdgrupoorigen = '2') --NC ajuste de CL
						and d.idcuenta = c.idcuenta
						and c.identidad = e.identidad
               ) 
where monto <> 0
union all
select * from (
						select e.cdcuit, e.dsrazonsocial,pkg_core_documento.GetDescDocumento(d.iddoctrx) tipo, nvl(c.amimputado*-1,0) monto, 'NC de días anteriores que hoy se usaron para pagar algo'
							  --into v_amNC
							  from tblcobranza c,
								   documentos d,
								   tblcuenta c,
								   entidades e
							  where c.dtimputado between to_date(p_fechaAux,'dd/mm/yyyy') and to_date(p_fechaAux ||'23:59:59','dd/mm/yyyy hh24:mi:ss')  --Fecha de aplicación
								and d.iddoctrx = c.iddoctrx_pago
								and d.cdsucursal = p_cdsucursal
								and d.dtdocumento < to_date(p_fechaAux,'dd/mm/yyyy')
								and d.idcuenta = c.idcuenta
								and c.identidad = e.identidad
               ) 
where monto <> 0;

Exception
  when others then
    n_pkg_vitalpos_log_general.write(2, 'Modulo: ' || v_modulo || '  Error: ' || Sqlerrm);

end GetCuentaAnticipoCliAbierto;


  /**************************************************************************************************
  * Retorna el detalle de descuentos al personal registrados
  * %v 31/08/2015 - APW
  * %v 22/10/2015 - APW: v1.1 - Agrego facturista y control
  * %v 11/6/2021 - APW - reformulo toda la consulta
  * %v 13/12/2021 - LM: se agregan las columnas de montoConDesc, montoSinDesc,legajo,mes
  ***************************************************************************************************/
  PROCEDURE GetDescuentoPersonal(p_sucursales IN VARCHAR2,
                                 p_fechadesde in date,
                                 p_fechahasta in date,
                                 p_idpersona  in personas.idpersona%type,
                                 p_cur_out    OUT cursor_type) IS

    v_modulo    varchar2(100) := 'PKG_REPORTE_CENTRAL.GetDescuentoPersonal';
    v_idReporte VARCHAR2(40) := '';
  BEGIN
    v_idReporte := PKG_REPORTE_CENTRAL.SetSucursalesSeleccionadas(p_sucursales);

    open p_cur_out for
        -- nuevo reporte descuento empleado
        with salidaok as (
        select s.iddoctrx, p.dsapellido, p.dsnombre
        from personas p, tbldocumento_salida s
        where p.idpersona = s.idpersona
       -- and s.dtsalida > to_date(p_fechadesde,'dd/mm/yyyy')
        and s.dtsalida > trunc(p_fechadesde)
        and s.cdmensajesalida = 1) 
        select distinct su.dssucursal, to_char(emp.cdlegajo) cdlegajo,
                              upper(emp.dsapellido||', '||emp.dsnombre) empleado,
                              d.dtdocumento Fecha_Factura,
                              to_char(d.dtdocumento, 'Mon', 'nls_date_language=spanish') mes,
                              pkg_reporte_central.GetDescDocumento(d.iddoctrx) FC_NC,
                              round(d.amdocumento+ac.amdescuentoconiva, 2) Monto_s_desc,
                              round(ac.amdescuentoconiva, 2) Monto_Desc,
                              f.dsapellido || ', ' || f.dsnombre facturista,
                              s.dsapellido || ', ' || s.dsnombre control
                from tbldescuentoempleado      ac,
                     documentos                d,
                     personas                  emp,
                     personas                  f,
                     salidaok                  s,
                     tbltmp_sucursales_reporte rs,
                     sucursales                su
               where emp.idpersona = ac.idpersona
                 and ac.iddoctrx = d.iddoctrx
                -- and ac.dtdocumento between to_date(p_fechadesde,'dd/mm/yyyy') and to_date(p_fechahasta,'dd/mm/yyyy')+1
                -- and d.dtdocumento between to_date(p_fechadesde,'dd/mm/yyyy') and to_date(p_fechahasta,'dd/mm/yyyy')+1
                and ac.dtdocumento between trunc(p_fechadesde) and trunc(p_fechahasta +1)
                and d.dtdocumento between trunc(p_fechadesde) and trunc(p_fechahasta +1)
                 and (d.cdcomprobante like 'FC%' or d.cdcomprobante like 'NC%')
                 and d.iddoctrx = s.iddoctrx (+)
                 and d.idpersona = f.idpersona
                 and d.cdsucursal=su.cdsucursal
                 and d.cdsucursal = rs.cdsucursal
                 and rs.idreporte = v_idReporte
                 and ac.idpersona = nvl(p_idpersona,ac.idpersona)
               order by 3 desc;
       /*select distinct su.dssucursal,
                      emp.dsapellido||', '||emp.dsnombre empleado,
                      d.dtdocumento,
                      GetDescDocumento(d.iddoctrx) factura,
                      d.amdocumento,
                      f.dsapellido || ', ' || f.dsnombre facturista,
                      c.dsapellido || ', ' || c.dsnombre control
        from tbldescuentoempleado               ac,
             documentos                d,
             personas                  emp,
             personas                  f,
             personas                  c,
             tbldocumento_salida       s,
             tbltmp_sucursales_reporte rs,
             sucursales                su
       where emp.idpersona = p_idpersona
         and emp.idpersona = ac.idpersona
         and ac.iddoctrx = d.iddoctrx
         and ac.dtdocumento between p_fechadesde and p_fechahasta+1
         and d.dtdocumento between p_fechadesde and p_fechahasta+1
         and d.cdcomprobante like 'FC%'
         and d.iddoctrx = s.iddoctrx
         and s.idpersona = c.idpersona
         and d.idpersona = f.idpersona
         and d.cdsucursal = su.cdsucursal
         and d.cdsucursal = rs.cdsucursal
         and rs.idreporte = v_idReporte
       order by 3 desc;*/

    PKG_REPORTE_CENTRAL.CleanSucursalesSeleccionadas(v_idReporte);

  EXCEPTION WHEN OTHERS THEN
     n_pkg_vitalpos_log_general.write(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM);
     raise;
  End GetDescuentoPersonal;

  /**************************************************************************************************
  * Reporte de Saldos por Guia
  * %v 01/09/2015 - MartinM
  ***************************************************************************************************/
  PROCEDURE GetSaldosPorGuiaComisionista( p_sucursales     IN            VARCHAR2       ,
                                          p_fechadesde     IN            DATE           ,
                                          p_fechahasta     IN            DATE           ,
                                          p_idcomisionista IN  entidades.identidad%TYPE ,
                                          p_cur_out        OUT           cursor_type    ,
                                          p_ok             OUT           INTEGER        ,
                                          p_error          OUT           VARCHAR2       ) IS

     v_modulo varchar2(100)   := 'PKG_REPORTE_CENTRAL.GetSaldosPorGuiaComisionista';
     v_idReporte VARCHAR2(40) := '';

  BEGIN

  p_ok        := 0                                       ;
  v_idReporte := SetSucursalesSeleccionadas(p_sucursales);

  OPEN p_cur_out
   FOR SELECT d.sqcomprobante                                         sqcomprobante ,
              d.dtdocumento                                           dtdocumento   ,
              (select sum(ti.amingreso)
                 from tblingreso       ti ,
                      tblrendicionguia trg
                where trg.idingreso          = ti.idingreso
                  and trg.idguiadetransporte = gt.idguiadetransporte) TotalIngresos ,
              (select sum(d.amdocumento)
                 from documentos     d  ,
                      tbldetalleguia tdg
                where d.iddoctrx = tdg.iddoctrx
                  and tdg.idguiadetransporte = gt.idguiadetransporte
                  and d.cdcomprobante     like    'FC%'             ) TotalFacturado,
              (select sum(pkg_documento_central.GetDeudaDocumento(d.iddoctrx))
                 from documentos     d  ,
                      tbldetalleguia tdg
                where d.iddoctrx = tdg.iddoctrx
                  and tdg.idguiadetransporte = gt.idguiadetransporte) TotalDeuda    ,
              (select sum(d.amdocumento)
                 from documentos           d  ,
                      tbldetalleguia       tdg,
                      tbldocumento_control tdc,
                      documentos           dnc
                where   d.iddoctrx              = tdg.iddoctrx
                  and tdg.idguiadetransporte    =  gt.idguiadetransporte
                  and   d.cdcomprobante      like     'FC%'
                  and tdg.iddoctrx              = tdc.iddoctrx
                  and tdc.iddoctrxgen           = dnc.iddoctrx
                  and dnc.cdcomprobante      like     'NC%')          TotalNC       ,
               s.dssucursal                                           dssucursal
         FROM documentos                d  ,
              guiasdetransporte         gt ,
              tbltmp_sucursales_reporte rs ,
              sucursales                s
        WHERE  d.identidad        =   p_idcomisionista
          AND  d.cdcomprobante    =   'GUIA'
          AND gt.iddoctrx         = d.iddoctrx
          AND  d.cdsucursal       = s.cdsucursal
          AND d.dtdocumento BETWEEN   trunc(p_fechadesde)
                                AND   trunc(p_fechahasta) + 1
          AND rs.cdsucursal       = d.cdsucursal
          AND rs.idreporte        =   v_idReporte;

  CleanSucursalesSeleccionadas(v_idReporte);

  p_ok        := 1;

  EXCEPTION WHEN OTHERS THEN
     p_error := SQLERRM;
     n_pkg_vitalpos_log_general.write(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM);
  END GetSaldosPorGuiaComisionista;

  /**************************************************************************************************
  * Retorna tiempos varios de los pedidos
  * %v 25/08/2015 - JBodnar: v1.0
  * %v 25/02/2016 - APW: agrego a los tiempos de liberación, los otros que tenemos en AC
  * %v 04/04/2016 - APW: agrego fecha de entrega (por cambio de estado a 4)
  * %v 07/04/2016 - APW: agrego canal
  * %v 16/06/2017 - IAquilano: Agrego cantidad de guias y fecha consolidado
  * %v 26/05/2022 - ChM incorporo medio de pago del pedido POSG - 913
  ***************************************************************************************************/
  PROCEDURE GetPedidosTiempo (p_sucursales IN  VARCHAR2,
                              p_fechadesde in  date,
                              p_fechahasta in  date,
                              p_cur_out    OUT cursor_type) IS

    v_modulo varchar2(100) := 'PKG_REPORTE_CENTRAL.GetPedidosTiempo';
    v_idReporte             VARCHAR2(40) := '';

  BEGIN
    v_idReporte := PKG_REPORTE_CENTRAL.SetSucursalesSeleccionadas(p_sucursales);

      open p_cur_out for
           select su.dssucursal,
                   e.cdcuit,
                   e.dsrazonsocial,
                   de.dscalle || ' ' || de.dsnumero || ' ' || lo.dslocalidad Direccion,
                   (pedi.fechaventa),
                   (pedi.fechallegada),
                   (pedi.fechaliberacion),
                   per.dsapellido || ' ' || per.dsnombre LiberadoPor,
                   max(pedi.fechafactura) fechafactura,
                   sum(pedi.importe) importe,
                   (pedi.fechaentrega),
                   pedi.canal,
                   pedi.cantidad_de_guia,
                   (pedi.fecha_consolidado), --agrego dato de fecha_consolidado
                   nvl(pedi.mediodepago,' ') mediodepago
              from (select do.cdsucursal,
                           do.identidadreal,
                           do.dtdocumento fechaventa,
                           pe.cdtipodireccion,
                           pe.sqdireccion,
                           pe.id_canal canal,
                           max(lg.dtlog) FechaLlegada,
                           max(ap.dtviajasuc) fechaliberacion,
                           nvl(ap.idpersona, 'x') liberadopor,
                           max(do.dtdocumento) fechafactura,
                           sum(pe.ammonto) importe,
                           max(guia.dtasignada) fechaentrega,
                           (select count(*)
                              from documentos fc, guiasdetransporte gt, tbldetalleguia dg
                             where fc.iddoctrx = dg.iddoctrx
                               and mm.idmovmateriales = fc.idmovmateriales
                               and dg.idguiadetransporte = gt.idguiadetransporte
                               and fc.dtdocumento > trunc( p_fechadesde )
                            ) cantidad_de_guia,
                           max(distinct(cons.dtmodif)) fecha_consolidado,
                           mp.dsmediopago mediodepago
                      from pedidos pe,
                           logtimestamp lg,
                           movmateriales mm,
                           documentos do,
                           tblauditoriapedido ap,
                           (select fc.idmovmateriales,
                                   gt.dtasignada,
                                   gt.idguiadetransporte
                              from documentos fc, guiasdetransporte gt, tbldetalleguia dg
                             where fc.iddoctrx = dg.iddoctrx
                               and dg.idguiadetransporte = gt.idguiadetransporte
                               and fc.dtdocumento > trunc( p_fechadesde )
                               and gt.icestado not in (1, 2, 6) -- solo guias válidas ya entregadas
                            ) guia,
                           tbltmp_sucursales_reporte sr,
                           (select tp.idpedido, tp.dtmodif
                              from tbllogestadopedidos tp --agrego tabla tbllogestadopedido
                             where tp.icestadosistema = 3
                               and tp.dtmodif > trunc( p_fechadesde )) cons,
                            --ChM incorporo medio de pago del pedido 26/05/2022
                            ( select mp.idpedido,vm.dsmediopago
                                from pedidomediodepago mp, vtexmediodepago vm
                               where vm.idmediopago = mp.idmediopago
                                 and vm.id_canal = mp.id_canal) mp      
                     where pe.iddoctrx = do.iddoctrx
                       and pe.iddoctrx = lg.id
                       and lg.cdestado = '-5   ' -- insertado en AC
                       and pe.idpedido = ap.idpedido(+)
                       and pe.idpedido = mm.idpedido(+)
                       and pe.idpedido = cons.idpedido(+)
                        --ChM incorporo medio de pago del pedido 26/05/2022
                       and   pe.idpedido = mp.idpedido (+)      
                       and mm.idmovmateriales = guia.idmovmateriales(+)
                       and do.cdcomprobante = 'PEDI'
                       and pe.dtaplicacion between trunc( p_fechadesde ) and trunc( p_fechahasta + 1 )
                       and do.dtdocumento between trunc( p_fechadesde ) and trunc( p_fechahasta + 1 )
                       and do.cdsucursal = sr.cdsucursal
                       and sr.idreporte = v_idReporte
                     group by do.cdsucursal,
                              do.identidadreal,
                              do.dtdocumento,
                              pe.cdtipodireccion,
                              pe.sqdireccion,
                              pe.id_canal,
                              mm.idmovmateriales,
                              mp.dsmediopago,
                              nvl(ap.idpersona, 'x')) pedi,
                   entidades e,
                   personas per,
                   direccionesentidades de,
                   localidades lo,
                   sucursales su
             WHERE pedi.identidadreal = e.identidad
               and pedi.liberadopor = per.idpersona(+) -- puede no haber
               and e.identidad = de.identidad
               and pedi.sqdireccion = de.sqdireccion
               and pedi.cdtipodireccion = de.cdtipodireccion
               and de.cdlocalidad = lo.cdlocalidad
               and de.cdpais = lo.cdpais
               and de.cdprovincia = lo.cdprovincia
               and pedi.cdsucursal = su.cdsucursal
             group by su.dssucursal,
                      e.cdcuit,
                      e.dsrazonsocial,
                      de.dscalle,
                      de.dsnumero,
                      lo.dslocalidad,
                      per.dsapellido,
                      per.dsnombre,
                      pedi.fechaventa,
                      pedi.fechallegada,
                      pedi.fechaliberacion,
                      pedi.fechaentrega,
                      pedi.fecha_consolidado,
                      pedi.canal,
                      pedi.cantidad_de_guia,
                      pedi.mediodepago
             order by su.dssucursal, pedi.fechaventa;

      PKG_REPORTE_CENTRAL.CleanSucursalesSeleccionadas(v_idReporte);

  EXCEPTION WHEN OTHERS THEN
     n_pkg_vitalpos_log_general.write(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM);
     raise;
  End GetPedidosTiempo;

  /*****************************************************************************************************************
  * Cuenta del comisionista -- DEBE TENER SOLO 1 POR SUCURSAL!!!!
  * %v 29/01/2015 - APW v1.0
  ******************************************************************************************************************/
  FUNCTION GetCuentaComi(p_idcomisionista IN entidades.identidad%TYPE) RETURN tblcuenta.idcuenta%TYPE IS

     v_Modulo  VARCHAR2(100)           := 'PKG_COMISIONISTA.GetDTCargaAnterior';
     v_cuenta  tblcuenta.idcuenta%TYPE                                         ;

  BEGIN

    SELECT idcuenta
      INTO v_cuenta
      FROM tblcuenta c
     WHERE c.identidad    = p_idcomisionista
       AND c.cdtipocuenta = '1' -- que devuelva solo cuentas Padre . LM
       AND rownum         =  1; -- no debería tener más de una cuenta!

    RETURN v_cuenta;

    EXCEPTION WHEN OTHERS THEN
     n_pkg_vitalpos_log_general.write(2, 'Modulo: ' || v_Modulo || ' Error: ' || SQLERRM);
     RAISE;
  END GetCuentaComi;

  /*****************************************************************************************************************
  * Estado del Comisionista - Interdepósitos por confirmar o rechazados luego de la última carga
  * %v 29/01/2015 - APW v1.0
  * %v 21/07/2015 - MartinM v1.1: Se cambia el parametro de la cuenta/guia y se lo cambia por el idcomisionista
  ******************************************************************************************************************/
  FUNCTION GetDeudaComisionistaEnGuias( p_idcomisionista IN documentos.identidad%TYPE ) RETURN NUMBER IS

     v_Modulo             VARCHAR2(100) := 'PKG_COMISIONISTA.GetDeudaComisionistaEnGuias';
     v_saldocomisionista  NUMBER                                                         ;
     v_deuda              NUMBER                                                         ;

  BEGIN

     -- Tomo el saldo del comisionista
       SELECT CASE WHEN sum(pkg_cuenta_central.GetSaldo(tc.idcuenta)) <= 0
                   THEN abs(sum(pkg_cuenta_central.GetSaldo(tc.idcuenta)))
                   ELSE 0
                   END Total_Cliente
         INTO v_saldocomisionista
         FROM tblcuenta tc
        WHERE tc.identidad = p_idcomisionista;

     -- Deuda de documentos
     SELECT nvl(sum(pkg_documento_central.GetDeudaDocumento(d.iddoctrx)),0)
       INTO v_deuda
       FROM documentos     d  ,
            tbldetalleguia tdg
      WHERE d.identidad =     p_idcomisionista
        AND d.iddoctrx  = tdg.iddoctrx;

     RETURN v_saldocomisionista - v_deuda;

  EXCEPTION WHEN OTHERS THEN
     n_pkg_vitalpos_log_general.write(2, 'Modulo: ' || v_Modulo || '  Error: ' || SQLERRM);
     RAISE;
  END GetDeudaComisionistaEnGuias;

/*****************************************************************************************************************
* Función que obtiene en 1 string los días de visita del cliente al vendedor
* %v 11/10/2015 - AWP: v1.1
******************************************************************************************************************/
FUNCTION GetDiasVisita (p_identidad in entidades.identidad%type,
                        p_idvendedor in personas.idpersona%type) return varchar2 is
    v_modulo varchar2(100) := 'PKG_REPORTE.GetDiasVisita';
    v_diasconcat varchar2(50) := null;
    v_pos integer;
    v_dias varchar2(50) := ' ';

BEGIN
    for v_dia in (select rv.dsdiasemana
                  from tblruteovendedor rv
                  where rv.identidad = p_identidad
                  and   rv.idvendedor = p_idvendedor)
    loop
      v_diasconcat := v_diasconcat||substr(v_dia.dsdiasemana,1,3)||'/';
    end loop;
    v_pos := length(v_diasconcat)-1;
    v_dias := substr(v_diasconcat, 1, v_pos);

    return v_dias;

  EXCEPTION WHEN OTHERS THEN
     n_pkg_vitalpos_log_general.write(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM);
     return ' ';

END GetDiasVisita;

/*****************************************************************************************************************
* Venta por sucursal, vendedor y cliente - para armar grilla
* %v 25/09/2015 - APW: v1.0
* %v 19/10/2015 - APW: v1.1 - Agrego tabla de dias de visita
* %v 31/03/2016 - APW: Elimino la búsqueda de documentos pedido sin identidadreal
******************************************************************************************************************/
PROCEDURE GetVentaDetalleCliente(p_sucursal   IN sucursales.cdsucursal%TYPE,
                                 p_idPersona  IN personas.idpersona%TYPE,
                                 p_fechaDesde IN DATE,
                                 p_fechaHasta IN DATE,
                                 cur_out      OUT cursor_type) IS
  v_Modulo VARCHAR2(100) := 'PKG_REPORTE_CENTRAL.GetVentaDetalleCliente';
BEGIN
  OPEN cur_out FOR
        WITH doc_cliente as
           (/*select d.iddoctrx, d.idcuenta, d.cdsucursal, e.identidad, e.cdcuit, e.dsrazonsocial, d.idpersona
            from documentos d, entidades e
            where d.identidad = e.identidad
            and   d.identidad <> 'IdCfReparto'
            and   d.identidadreal is null
            and   d.cdcomprobante = 'PEDI'
            and   d.dtdocumento BETWEEN TRUNC(p_fechaDesde) AND TRUNC(p_fechaHasta + 1)
           union*/
            select d.iddoctrx, d.idcuenta, d.cdsucursal,  e.identidad, e.cdcuit, e.dsrazonsocial, d.idpersona
            from documentos d, entidades e
            where d.identidadreal = e.identidad
            and   d.identidadreal is not null
            and   d.cdcomprobante = 'PEDI'
            and   d.dtdocumento BETWEEN TRUNC(p_fechaDesde) AND TRUNC(p_fechaHasta + 1)
          /* union
            select d.iddoctrx, d.idcuenta, d.cdsucursal,  e.identidad, e.cdcuit, e.dsrazonsocial, d.idpersona
            from documentos d, entidades e
            where e.cdcuit = trim(replace(replace(d.dsreferencia, '[', ''), ']', ''))||'  '
            and   d.identidad = 'IdCfReparto'
            and   d.identidadreal is null
            and   d.cdcomprobante = 'PEDI'
            and   d.dtdocumento BETWEEN TRUNC(p_fechaDesde) AND TRUNC(p_fechaHasta + 1)*/
            ),
    detpedi as  -- suma de articulos de tapa para un pedido
     (select pe.idpedido, sum(dped.amlinea) amtapa
        from detallepedidos dped, pedidos pe
       where dped.idpedido = pe.idpedido
         and exists (select 1
                     from tblarticulo_tapa tp
                     where dped.cdarticulo = tp.cdarticulo
                     and trunc(pe.dtaplicacion) between  tp.vigenciadesde and tp.vigenciahasta)
         and pe.dtaplicacion BETWEEN TRUNC(p_fechaDesde) AND TRUNC(p_fechaHasta + 1)
       group by pe.idpedido)
    SELECT su.cdsucursal,
           su.dssucursal,
           docp.cdcuit,
           docp.dsrazonsocial,
           GetDiasVisita(docp.identidad, docp.idpersona) diavisita,
           p.dsapellido || ', ' || p.dsnombre vendedor,
           trunc(pe.dtaplicacion) dtpedido,
           sum(pe.ammonto) totalpedido,
           nvl(sum(dptapa.amtapa), 0) total_tapa
      FROM doc_cliente docp,
           pedidos pe,
           detpedi     dptapa,
           sucursales  su,
           personas    p
     WHERE docp.iddoctrx = pe.iddoctrx
       and pe.idvendedor = p.idpersona
       AND docp.cdsucursal = su.cdsucursal
       and pe.idpedido = dptapa.idpedido(+)
       AND pe.id_canal in ('VE')
       AND trim(su.cdsucursal) = trim(p_sucursal)
       and pe.dtaplicacion between TRUNC(p_fechaDesde) AND TRUNC(p_fechaHasta + 1)
       and (p_idpersona is null or trim(pe.idvendedor) = trim(p_idpersona))
     group by su.cdsucursal,
              su.dssucursal,
              docp.cdcuit,
              docp.dsrazonsocial,
              GetDiasVisita(docp.identidad, docp.idpersona),
              p.dsapellido || ', ' || p.dsnombre,
              trunc(pe.dtaplicacion)
    union -- los clientes a los que no se les vendió y están en el ruteo del vendedor
    SELECT su.cdsucursal,
           su.dssucursal,
           e.cdcuit,
           e.dsrazonsocial,
           GetDiasVisita(cv.identidad, cv.idviajante) diavisita,
           v.dsapellido || ', ' || v.dsnombre vendedor,
           null dtpedido,
           0 totalpedido,
           0 totaltapa
      from clientesviajantesvendedores cv,
           entidades                   e,
           personas                    v,
           sucursales                  su
     where cv.identidad = e.identidad
     and   cv.cdsucursal = su.cdsucursal
     and   cv.idviajante = v.idpersona
     and   v.icactivo = 1 -- solo los vendedores activos
     and   (cv.dthasta = trunc(last_day(p_fechaDesde)) -- solo las relaciones vigentes
            or cv.dthasta = (select max(dthasta) from clientesviajantesvendedores))
     and   trim(su.cdsucursal) = trim(p_sucursal)
     and (p_idpersona is null or trim(v.idpersona) = trim(p_idpersona))
     and not exists (select 1
                     from doc_cliente docp
                     where docp.identidad = cv.identidad
                     and   docp.idpersona = cv.idviajante
                     and   docp.cdsucursal = cv.cdsucursal
                     )
     order by cdsucursal, vendedor, dtpedido, cdcuit;

EXCEPTION
  WHEN OTHERS THEN
    n_pkg_vitalpos_log_general.write(2,'Modulo: ' || v_Modulo || ' Error: ' ||SQLERRM);
    RAISE;
END GetVentaDetalleCliente;
/*****************************************************************************************************************
* Devuelve 1 si la cuenta de un comisionista y 0 si lo contrario
* %v 09/09/2015 - MartinM v1.0
******************************************************************************************************************/
PROCEDURE GetEstadoGuiaTransporte ( p_idguiadetransporte IN  guiasdetransporte.idguiadetransporte%TYPE ,
                                    p_montoticket        OUT                   NUMBER                  ,
                                    p_montointerdeposito OUT                   NUMBER                  ,
                                    p_montoefectivopesos OUT                   NUMBER                  ,
                                    p_montoefectivodolar OUT                   NUMBER                  ,
                                    p_cur_out            OUT                   cursor_type             )
       IS

   v_Modulo         VARCHAR2(100) := 'PKG_COMISIONISTA.GetEstadoGuiaTransporte';

BEGIN

     --Averiguo el monto de tickets rendidos en la guia para el comisionista
     begin
         select sum(nvl(ti.amingreso,0))
           into p_montoticket
           from tblingreso       ti ,
                tblrendicionguia trg,
                tblconfingreso   tci
          where ti.idingreso           = trg.idingreso
            and trg.idguiadetransporte =     p_idguiadetransporte
            and tci.cdconfingreso      =  ti.cdconfingreso
            and tci.cdmedio = '4';

       if  p_montoticket is null then
          p_montoticket := 0;
        end if;

     exception when others then
       p_montoticket := 0;
     end;

     --Averiguo el monto de interdepósitos rendidos en la guia para el comisionista
     begin
         select sum(nvl(ti.amingreso,0))
           into p_montointerdeposito
           from tblingreso       ti ,
                tblrendicionguia trg,
                tblconfingreso   tci
          where ti.idingreso           = trg.idingreso
            and trg.idguiadetransporte =     p_idguiadetransporte
            and tci.cdconfingreso      =  ti.cdconfingreso
            and tci.cdmedio = '6';

       if  p_montointerdeposito is null then
          p_montointerdeposito := 0;
        end if;

     exception when others then
       p_montointerdeposito := 0;
     end;

     --Averiguo el monto de efectivo pesos en la guia para el comisionista
     begin
         select sum(nvl(ti.amingreso,0))
           into p_montoefectivopesos
           from tblingreso       ti ,
                tblrendicionguia trg,
                tblconfingreso   tci
          where ti.idingreso           = trg.idingreso
            and trg.idguiadetransporte =     p_idguiadetransporte
            and tci.cdconfingreso      =  ti.cdconfingreso
            and tci.cdmedio = '1'
            and tci.cdtipo  = '20';

       if  p_montoefectivopesos is null then
          p_montoefectivopesos := 0;
        end if;

     exception when others then
       p_montoefectivopesos := 0;
     end;

     --Averiguo el monto de efectivo dolar en la guia para el comisionista
     begin
         select sum(nvl(ti.amingreso,0))
           into p_montoefectivodolar
           from tblingreso       ti ,
                tblrendicionguia trg,
                tblconfingreso   tci
          where ti.idingreso           = trg.idingreso
            and trg.idguiadetransporte =     p_idguiadetransporte
            and tci.cdconfingreso      =  ti.cdconfingreso
            and tci.cdmedio = '1'
            and tci.cdtipo  = '18';

       if  p_montoefectivodolar is null then
          p_montoefectivodolar := 0;
       end if;

     exception when others then
       p_montoefectivodolar := 0;
     end;

     --Query del Estado de la Guia
     OPEN p_cur_out
          FOR Select dsrazonsocial                               dsrazonsocial    ,
             escf                                                escf             ,
             amdocumento                                         amdocumento      ,
             amnotadecredito                                     amnotadecredito  ,
             nvl(amdocumento    ,0) + nvl(amnotadecredito,0)     amdeudatotalizada,
             nvl(PagosCierreLote,0)                              PagosCierreDeLote,
             nvl(PagosCheque    ,0)                              PagosCheque      ,
             nvl(PagosRetencion ,0)                              PagosRetencion   ,
             nvl(Transf         ,0)                              EfectivoTransf   ,
             nvl(Pagos          ,0) + nvl(Transf,0)              TotalPago        ,
            -- amdeudatotalizada                                   amdeudatotalizada,
             ( CASE WHEN nvl(Pagos ,0) +
                         nvl(Transf,0) -
                         amdocumento   -
                         amnotadecredito > 0
                    THEN nvl(Pagos ,0) +
                         nvl(Transf,0) -
                         amdocumento   -
                         amnotadecredito
                    ELSE 0 END           )                       SaldoFavorCliente
        from ( SELECT TRIM(e.dsrazonsocial) || ' (' ||
                      TRIM(e.cdcuit)        || ')'                                                                  dsrazonsocial     ,
                           q.escf                                                                                   escf              ,
                       sum(q.amdeudatotalizada)                                                                     amdeudatotalizada ,
                       sum(q.amnotadecredito)                                                                       amnotadecredito   ,
                       sum(q.amdocumento)                                                                           amdocumento       ,
                      (select sum( nvl( ti.amingreso, 0) )
                         from tblrendicionguia  trg,
                              tblingreso        ti
                        where trg.idguiadetransporte =     p_idguiadetransporte
                          and trg.idingreso          =  ti.idingreso
                          and  ti.idcuenta           =   q.idcuenta )                                               Pagos             ,
                      (select sum( nvl( ti.amingreso, 0) )
                         from tblrendicionguia  trg,
                              tblingreso        ti ,
                              tblconfingreso    tci
                        where trg.idguiadetransporte =     p_idguiadetransporte
                          and trg.idingreso          =  ti.idingreso
                          and  ti.cdconfingreso      = tci.cdconfingreso
                          and  ti.idcuenta           =   q.idcuenta
                          and tci.cdmedio in ('3','7')
                          and tci.cdforma = '5' )                                                                   PagosCierreLote   ,
                      (select sum( nvl( ti.amingreso, 0) )
                         from tblrendicionguia  trg,
                              tblingreso        ti ,
                              tblconfingreso    tci
                        where trg.idguiadetransporte =     p_idguiadetransporte
                          and trg.idingreso          =  ti.idingreso
                          and  ti.cdconfingreso      = tci.cdconfingreso
                          and  ti.idcuenta           =   q.idcuenta
                          and tci.cdmedio            =     '5' )                                                    PagosCheque       ,
                      (select sum( nvl( ti.amingreso, 0) )
                         from tblrendicionguia  trg,
                              tblingreso        ti ,
                              tblconfingreso    tci
                        where trg.idguiadetransporte =     p_idguiadetransporte
                          and trg.idingreso          =  ti.idingreso
                          and  ti.cdconfingreso      = tci.cdconfingreso
                          and  ti.idcuenta           =   q.idcuenta
                          and tci.cdmedio            =     '19' )                                                   PagosRetencion    ,
                      (select sum(nvl( tiTrans.amingreso,0))
                         from tblingreso   tiTrans,
                              tblguiacomistransferencia tgct
                        where tiTrans.idcuenta           = q.idcuenta
                          and tiTrans.cdconfingreso      =   '830'
                          and tiTrans.Idtransaccion      = tgct.idtransaccion
                          and    tgct.idguiadetransporte = p_idguiadetransporte)                                    Transf
                 FROM (SELECT d.iddoctrx                                         iddoctrx          ,
                              d.idcuenta                                         idcuenta          ,
                                DECODE(d.identidadreal,d.identidad,0,1)          escf              ,
                                pkg_documento_central.GetDeudaDocumento(d.iddoctrx) amdeudatotalizada ,
                                0                                                amnotadecredito   ,
                              d.amdocumento                                      amdocumento
                        FROM documentos        d  ,
                             tbldetalleguia    tdg
                       WHERE tdg.idguiadetransporte   =    p_idguiadetransporte
                         AND tdg.iddoctrx             =  d.iddoctrx
                         AND   d.cdcomprobante     like    'FC%'
                         AND EXISTS (SELECT 1
                                       FROM tblmovcuenta tmc
                                      WHERE tmc.iddoctrx = d.iddoctrx)
                       UNION
                      SELECT dd.iddoctrx                                         iddoctrx         ,
                             dd.idcuenta                                         idcuenta         ,
                             DECODE(dd.identidadreal,dd.identidad,0,1)           escf             ,
                             0                                                   amdeudatotalizada,
                             dd.amdocumento                                      amnotadecredito  ,
                             0                                                   amdocumento
                        FROM documentos           d  ,
                             tbldetalleguia       tdg,
                             tbldocumento_control tdc,
                             documentos           dd
                       WHERE tdg.idguiadetransporte   =     p_idguiadetransporte
                         AND tdg.iddoctrx             =   d.iddoctrx
                         AND   d.iddoctrx             = tdc.iddoctrx
                         AND  dd.iddoctrx             = tdc.iddoctrxgen
                         AND  dd.cdcomprobante     like     'NC%'                                 ) q ,
                      tblcuenta                                                                     tc,
                      entidades                                                                     e
                WHERE tc.idcuenta  = q.idcuenta
                  AND tc.identidad = e.identidad
                GROUP
                   BY      e.identidad                 ,
                      TRIM(e.dsrazonsocial) || ' (' ||
                      TRIM(e.cdcuit)        || ')'     ,
                           q.idcuenta                  ,
                           q.escf                     ) ;

EXCEPTION WHEN OTHERS THEN
   n_pkg_vitalpos_log_general.write(2, 'Modulo: ' || v_Modulo || ' Error: ' || SQLERRM);
   RAISE;
END GetEstadoGuiaTransporte;


  PROCEDURE GetEstadosPagare(p_cur_out OUT cursor_type) IS
    v_Modulo VARCHAR2(100) := 'PKG_REPORTE.getEstadosPagare';
  BEGIN
    OPEN p_cur_out FOR
      SELECT ec.cdestado, ec.dsestado
        FROM estadocomprobantes ec
       WHERE ec.cdcomprobante LIKE 'PGCO%';
  EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2, 'Modulo: ' || v_Modulo || ' Error: ' || SQLERRM);
      RAISE;
  END getEstadosPagare;



     /*****************************************************************************************************************
   * Retorna un reporte con el detalle los pagares
   * %v 06/08/2014 - MatiasG: v1.0
   * %v 01/02/2018 - LM: se agrega un nvl en el cuit, ya que existen pagares a consumidor final
   ******************************************************************************************************************/
   PROCEDURE GetPagares(      p_sucursales          IN VARCHAR2,
                              p_idcuenta            IN tblcuenta.idcuenta%TYPE,
                               p_identidad           IN entidades.identidad%TYPE,
                               p_dtIngreso           IN tblingreso.dtingreso%TYPE,
                               p_dtIngresoHasta      IN tblingreso.dtingreso%TYPE,
                               p_cdestadocomprobante IN documentos.cdestadocomprobante%TYPE,
                               p_cur_out             OUT cursor_type) IS
      v_Modulo VARCHAR2(100) := 'PKG_REPORTE.GetPagares';
      v_idReporte             VARCHAR2(40) := '';
   BEGIN
      v_idReporte := SetSucursalesSeleccionadas(p_sucursales);
      OPEN p_cur_out FOR
         SELECT su.dssucursal,
                do.dtdocumento,
                pe.dsapellido,
                pe.dsnombre,
                nvl(ee.cdcuit,'--') cdcuit,
                ee.dsrazonsocial,
                cu.nombrecuenta,
           do.sqcomprobante nroPagare,
                trunc(do.amdocumento, 2) amdocumento,
                ec.dsestado,
                pkg_documento_central.GetDescDocumento(do.iddoctrx) descripcion
           FROM documentos         do,
                entidades          ee,
                tblcuenta          cu,
                estadocomprobantes ec,
                personas           pe,
                tbltmp_sucursales_reporte rs,
                sucursales                su
          WHERE exists (select 1 from tblpagaredetalle pd where do.iddoctrx = pd.iddoctrxpagare)
            AND do.identidad = ee.identidad
            AND do.idcuenta = cu.idcuenta
            AND do.idpersona = pe.idpersona
            AND do.cdestadocomprobante = ec.cdestado
            AND do.cdcomprobante like 'PG%'
            AND cu.cdtipocuenta = '1'
            AND do.cdcomprobante = ec.cdcomprobante
            AND (p_idcuenta is null or cu.idcuenta = p_idcuenta)
            AND (p_identidad is null or do.identidad = p_identidad)
            AND (p_cdestadocomprobante is null or trim(do.cdestadocomprobante) = trim(p_cdestadocomprobante))
            AND do.dtdocumento BETWEEN TRUNC(p_dtIngreso) AND TRUNC(p_dtIngresoHasta + 1)
            AND do.cdsucursal = su.cdsucursal
            AND su.cdsucursal = rs.cdsucursal
            and rs.idreporte = v_idReporte;

          PKG_REPORTE_CENTRAL.CleanSucursalesSeleccionadas(v_idReporte);
   EXCEPTION
      WHEN OTHERS THEN
         n_pkg_vitalpos_log_general.write(2, 'Modulo: ' || v_Modulo || ' Error: ' || SQLERRM);
         RAISE;
   END GetPagares;

   /*****************************************************************************************************************
   * Retorna un reporte efectivo dolares por sucursal
   * %v 15/10/2014 - JBodnar: v1.0
   ******************************************************************************************************************/
   PROCEDURE GetEfectivoDolar(p_cdsucursal IN tblcuenta.cdsucursal%TYPE,
                                p_identidad  IN entidades.identidad%TYPE,
                                p_idcuenta   IN tblcuenta.idcuenta%TYPE,
                                p_fechaDesde IN DATE,
                                p_fechaHasta IN DATE,
                                p_cur_out    OUT cursor_type)
  IS
      v_modulo VARCHAR2(100) := 'PKG_REPORTE_CENTRAL.GetEfectivoDolar';
   BEGIN
      OPEN p_cur_out FOR
         SELECT re.dsregion,
                su.dssucursal,
                ee.dsrazonsocial,
                cu.nombrecuenta cuenta,
                ee.cdcuit,
                max(ii.idingreso) idingreso,
                ii.dtingreso,
                pkg_ingreso_central.GetDescIngreso(ci.cdconfingreso,ii.cdsucursal) dsingreso,
                trunc(SUM(ii.amingreso),2) importe,
                pe.dsapellido||' '||pe.dsnombre cajero
           FROM tblingreso ii, tblcuenta cu, tblconfingreso ci, sucursales su, tblregion re, entidades ee, tblmovcaja mc, personas pe
          WHERE ii.idcuenta      = cu.idcuenta
            AND ii.cdconfingreso = ci.cdconfingreso
            AND ii.cdsucursal    = ci.cdsucursal
            AND ii.cdsucursal    = su.cdsucursal
            AND su.cdregion      = re.cdregion
            AND cu.identidad     = ee.identidad
            AND su.cdsucursal    = NVL(p_cdsucursal,su.cdsucursal)
            AND ee.identidad     = NVL(p_identidad,ee.identidad)
            AND cu.idcuenta      = NVL(p_idcuenta,cu.idcuenta)
            AND ci.cdmedio       = '1' --Efectivo
            AND ci.cdtipo        = '18' --Dolares
            AND ii.dtingreso BETWEEN trunc(p_fechaDesde) AND trunc(p_fechaHasta + 1)
            AND ii.idmovcaja     = mc.idmovcaja
            AND mc.idpersonaresponsable  = pe.idpersona
            AND not exists (select 1        --No rechazado en sucursal
                              from tblingreso i2,
                                   tblconfingreso ci2
                             where i2.idingresorechazado = ii.idingreso
                               and ci2.cdconfingreso     = i2.cdconfingreso
                               and ci2.cdaccion          = '2')
            AND ci.cdaccion not in ('2','3','6','7') --Ajuste ingreso y Ajuste egreso, Accion rechazo AC/Sucursal
       GROUP BY re.dsregion,su.dssucursal,ee.dsrazonsocial,cu.nombrecuenta,ee.cdcuit,
                ii.dtingreso,  pkg_ingreso_central.GetDescIngreso(ci.cdconfingreso,ii.cdsucursal),
                pe.dsapellido||' '||pe.dsnombre
       ORDER BY ee.dsrazonsocial;
   EXCEPTION
      WHEN OTHERS THEN
         n_pkg_vitalpos_log_general.write(2, 'Modulo: ' || v_modulo || '  Error: ' || SQLERRM);
         RAISE;
   END GetEfectivoDolar;

  /*****************************************************************************************************************
   * Retorna el conteo de stock
   * %v 28/10/2015 - LucianoF: v1.0
   * %v 17/05/2016 - LucianoF: v1.1 - Agregado de la tabla historico
   ******************************************************************************************************************/
    PROCEDURE GetControlStockConteo(p_sucursales IN  VARCHAR2,
                                    p_fechadesde in  date,
                                    p_fechahasta in  date,
                                    p_cdgrupocontrol in tblcontrolstock.cdgrupocontrol%TYPE,
                                    p_cdarticulo     in tblcontrolstock.cdarticulo%TYPE,
                                    p_cur_out    OUT cursor_type) IS

    v_modulo varchar2(100) := 'PKG_REPORTE_CENTRAL.GetControlStockConteo';
     v_idReporte             VARCHAR2(40) := '';
  BEGIN
    v_idReporte := PKG_REPORTE_CENTRAL.SetSucursalesSeleccionadas(p_sucursales);

      open p_cur_out for
      select
       su.cdsucursal,
       cs.idcontrolstockhist,
       cs.idcontrolstock,
       su.dssucursal,
       cs.dtcontrol,
       cs.dtproceso,
       cs.cdarticulo,
       da.vldescripcion,
       cs.vlcantventa,
       cs.vlcantaereo,
       cs.vlcantdeposito,
       cs.vlcantstock,
       cs.cdgrupocontrol,
       case when cs.cdestadocontrol = 0 then 'Sin contabilizar'
            when cs.cdestadocontrol = 1 then 'Contabilizado'
            when cs.cdestadocontrol = 2 then 'A contar'
            when cs.cdestadocontrol = 3 then 'Cerrado'
            when cs.cdestadocontrol = 4 then 'A recontar'
         end as estado
       from tblcontrolstockhistorico cs
       inner join descripcionesarticulos da on da.cdarticulo = cs.cdarticulo
       inner join sucursales su on su.cdsucursal = cs.cdsucursal
       inner join  tbltmp_sucursales_reporte sr on sr.cdsucursal = su.cdsucursal
       where cs.dtcontrol between trunc( p_fechadesde) and trunc( p_fechahasta + 1 )
       and sr.idreporte = v_idReporte
       and trim(cs.cdgrupocontrol) = NVL(p_cdgrupocontrol, trim(cs.cdgrupocontrol))
       and trim(cs.cdarticulo) = NVL(p_cdarticulo, trim(cs.cdarticulo))
      order by su.dssucursal, cs.cdgrupocontrol, cs.cdarticulo, cs.dtproceso;

      PKG_REPORTE_CENTRAL.CleanSucursalesSeleccionadas(v_idReporte);

  EXCEPTION WHEN OTHERS THEN
     n_pkg_vitalpos_log_general.write(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM);
     raise;
  End GetControlStockConteo;

/*****************************************************************************************************************
   * Retorna el detalle de cada conteo
   * %v 17/05/2016 - LucianoF: v1.0
   ******************************************************************************************************************/
    PROCEDURE GetDetalleConteo( p_fechadesde in  date,
                                p_fechahasta in  date,
                                p_cdgrupocontrol in tblcontrolstock.cdgrupocontrol%TYPE,
                                p_cdarticulo     in tblcontrolstock.cdarticulo%TYPE,
                                p_sucursal       in tblcontrolstock.cdsucursal%TYPE,
                                p_cur_out    OUT cursor_type) IS

    v_modulo varchar2(100) := 'PKG_REPORTE_CENTRAL.GetDetalleConteo';

  BEGIN


      open p_cur_out for
     select *
       from tblcontrolstockdetalle cs
       where
       cs.dtcontrol between p_fechadesde and p_fechahasta
       and trim(cs.cdgrupocontrol) = NVL(p_cdgrupocontrol, trim(cs.cdgrupocontrol))
       and trim(cs.cdarticulo) = NVL(p_cdarticulo, trim(cs.cdarticulo))
       and cs.cdsucursal = NVL(p_sucursal, cs.cdsucursal)
      order by cs.dtcontrol;

  EXCEPTION WHEN OTHERS THEN
     n_pkg_vitalpos_log_general.write(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM);
     raise;
  End GetDetalleConteo;

  /*****************************************************************************************************************
   * Retorna el detalle de cada conteo completo
   * %v 17/05/2016 - LucianoF: v1.0
   ******************************************************************************************************************/
    PROCEDURE GetDetalleConteoCompleto( p_fechadesde in  date,
                                p_fechahasta in  date,
                                p_cdgrupocontrol in tblcontrolstock.cdgrupocontrol%TYPE,
                                p_cdarticulo     in tblcontrolstock.cdarticulo%TYPE,
                                p_sucursales IN  VARCHAR2,
                                p_cur_out    OUT cursor_type) IS

    v_modulo varchar2(100) := 'PKG_REPORTE_CENTRAL.GetDetalleConteoCompleto';

     v_idReporte             VARCHAR2(40) := '';
  BEGIN
    v_idReporte := PKG_REPORTE_CENTRAL.SetSucursalesSeleccionadas(p_sucursales);


      open p_cur_out for
     select cs.*, a.vldescripcion, s.dssucursal, p.dsapellido||', '||p.dsnombre persona
       from tblcontrolstockdetalle cs,
            descripcionesarticulos a,
            tbltmp_sucursales_reporte rs,
            sucursales s,
            personas p
       where
       cs.cdarticulo = a.cdarticulo
       and s.cdsucursal = cs.cdsucursal
       and s.cdsucursal = rs.cdsucursal
       and rs.idreporte = v_idReporte
       and cs.dtcontrol between p_fechadesde and p_fechahasta + 1
       and trim(cs.cdgrupocontrol) = NVL(p_cdgrupocontrol, trim(cs.cdgrupocontrol))
       and trim(cs.cdarticulo) = NVL(p_cdarticulo, trim(cs.cdarticulo))
       and cs.idpersona = p.idpersona
      order by cs.dtcontrol;

  EXCEPTION WHEN OTHERS THEN
     n_pkg_vitalpos_log_general.write(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM);
     raise;
  End GetDetalleConteoCompleto;


   /*****************************************************************************************************************
   * Retorna un reporte con el cobro a los comisionistas
   * %v 29/01/2016 - APW
   ******************************************************************************************************************/
   PROCEDURE GetCobroComisionistas(p_sucursales          IN VARCHAR2,
                                   p_comisionista        IN entidades.identidad%type,
                                   p_dtdesde             IN date,
                                   p_dthasta             IN date,
                                   p_cur_out             OUT cursor_type) IS
      v_Modulo VARCHAR2(100) := 'PKG_REPORTE.GetCobroComisionistas';
      v_idReporte             VARCHAR2(40) := '';
   BEGIN
      v_idReporte := SetSucursalesSeleccionadas(p_sucursales);

      OPEN p_cur_out FOR
         SELECT su.dssucursal,
                ee.cdcuit,
                ee.dsrazonsocial,
                cc.dtorden,
                cc.dsmotivo dsmotivo_cobrar,
                cc.amcobrar,
                decode(cc.cdestado, '1', 'A Procesar', 'Procesado') estadoorden,
                pkg_documento_central.GetDescDocumento(do.iddoctrx) dsmov,
                do.dtdocumento dtmov,
                do.amdocumento ammov,
                (select decode(trim(ec.cdestado), '2', 'No Pagado', '4', 'Pagado Parcial', '5', 'Pagado', ec.dsestado)
                 from estadocomprobantes ec
                 where ec.cdestado = do.cdestadocomprobante
                 and   ec.cdcomprobante = do.cdcomprobante) dsestado
           FROM tblcomisionistacobrar cc,
                documentos do,
                entidades          ee,
                tbltmp_sucursales_reporte rs,
                sucursales                su
          WHERE cc.idcomisionista = ee.identidad
            and cc.iddoctrx = do.iddoctrx (+)
            AND (p_comisionista is null or cc.idcomisionista = p_comisionista)
            AND cc.dtorden BETWEEN TRUNC(p_dtdesde) AND TRUNC(p_dthasta + 1)
            AND cc.cdsucursal = su.cdsucursal
            AND su.cdsucursal = rs.cdsucursal
            and rs.idreporte = v_idReporte
           union
           SELECT su.dssucursal,
                ee.cdcuit,
                ee.dsrazonsocial,
                cc.dtorden,
                cc.dsmotivo dsmotivo_cobrar,
                cc.amcobrar,
                decode(cc.cdestado, '1', 'A Procesar', 'Procesado') estadoorden,
                pkg_ingreso_central.GetDescIngreso(ii.cdconfingreso, ii.cdsucursal) dsmov,
                ii.dtingreso dtmov,
                ii.amingreso ammov,
                 (select decode(ei.cdestado, '1', 'No Pagado', '2', 'Pagado Parcial', '3', 'Pagado', ei.dsestado)
                 from tblestadoingreso ei
                 where ei.cdestado = ii.cdestado) dsestado
           FROM tblcomisionistacobrar cc,
                tblingreso ii,
                entidades          ee,
                tbltmp_sucursales_reporte rs,
                sucursales                su
          WHERE cc.idcomisionista = ee.identidad
            AND cc.idingreso = ii.idingreso (+)
            AND (p_comisionista is null or cc.idcomisionista = p_comisionista)
            AND cc.dtorden BETWEEN TRUNC(p_dtdesde) AND TRUNC(p_dthasta + 1)
            AND ii.cdsucursal = su.cdsucursal
            AND cc.cdsucursal = rs.cdsucursal
            and rs.idreporte = v_idReporte
           ;

          PKG_REPORTE_CENTRAL.CleanSucursalesSeleccionadas(v_idReporte);
   EXCEPTION
      WHEN OTHERS THEN
         n_pkg_vitalpos_log_general.write(2, 'Modulo: ' || v_Modulo || ' Error: ' || SQLERRM);
         RAISE;
   END GetCobroComisionistas;

   /*****************************************************************************************************************
   * Retorna un reporte con los pedidos de selectivos generados
   * %v 11/02/16 - APW
   ******************************************************************************************************************/
   PROCEDURE GetPedidosSelectivos(p_sucursales          IN VARCHAR2,
                                   p_dtdesde             IN date,
                                   p_dthasta             IN date,
                                   p_cur_out             OUT cursor_type) IS

      v_Modulo VARCHAR2(100) := 'PKG_REPORTE.GetPedidosSelectivos';
      v_idReporte             VARCHAR2(40) := '';

   BEGIN
      v_idReporte := SetSucursalesSeleccionadas(p_sucursales);

      OPEN p_cur_out FOR
         SELECT su.dssucursal,
                trunc(do.dtdocumento) fecha,
                count(*) cantidad,
                sum(do.amdocumento) importe
           FROM documentos do,
                tbltmp_sucursales_reporte rs,
                sucursales                su
          WHERE do.cdcomprobante = 'RTOESPEC'
            AND do.dtdocumento BETWEEN TRUNC(p_dtdesde) AND TRUNC(p_dthasta + 1)
            AND do.cdsucursal = su.cdsucursal
            AND su.cdsucursal = rs.cdsucursal
            and rs.idreporte = v_idReporte
         group by su.dssucursal, trunc(do.dtdocumento);

          PKG_REPORTE_CENTRAL.CleanSucursalesSeleccionadas(v_idReporte);
   EXCEPTION
      WHEN OTHERS THEN
         n_pkg_vitalpos_log_general.write(2, 'Modulo: ' || v_Modulo || ' Error: ' || SQLERRM);
         RAISE;
   END GetPedidosSelectivos;


     /**************************************************************************************************
   GetDesEstadoFC: Devuelve la descripcion del estado de la FC - Si se anuló y luego se canceló
                   en caja retorna ANULADA
  * %v 07/07/2015 - MartinM: v1.0 Se paso la función desde el package PKG_REPORTE_control
  ***************************************************************************************************/
  FUNCTION GetDesEstadoFC ( p_iddoctrx        IN documentos.iddoctrx%type,
                            p_cdcomprobante   IN documentos.cdcomprobante%type,
                            p_cdestado        IN documentos.cdestadocomprobante%type,
                            p_amnetodocumento IN documentos.amnetodocumento%type)
    RETURN estadocomprobantes.dsestado%type is

  v_modulo   varchar2(100)                    := 'PKG_REPORTE.GetDesEstadoFC';
  v_dsestado estadocomprobantes.dsestado%type;
  v_tieneNC  number;

  BEGIN

    if p_cdestado = '5' then
      -- si tiene NC por el mismo monto, la considero Anulada
      select count(*)
        into v_tieneNC
        from tbldocumento_control dc,
             documentos           nc
       where     dc.iddoctrx             = p_iddoctrx
         and     dc.iddoctrxgen          = nc.iddoctrx
         and     nc.cdcomprobante     like 'NC%'
         and abs(nc.amnetodocumento)     = abs(p_amnetodocumento);

      if v_tieneNC > 0 then
        v_dsestado := 'Anulada';
        return v_dsestado;
      end if;
    end if;

    -- si no está cancelada, o no está anulada busco la descripción del estado en la tabla
    select es.dsestado
      into v_dsestado
      from estadocomprobantes es
     where es.cdestado      = p_cdestado
       and es.cdcomprobante = p_cdcomprobante;

    return v_dsestado;

  EXCEPTION WHEN OTHERS THEN
     n_pkg_vitalpos_log_general.write(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM);
     raise;
  End GetDesEstadoFC;


        /**************************************************************************************************
   GetCdEstadoFC: Devuelve el codigo del estado de la FC - Si se anuló y luego se canceló en caja
                  retorna ANULADA
  * %v 07/07/2015 - MartinM: v1.0 Se paso la función desde el package PKG_REPORTE_control
  ***************************************************************************************************/
  FUNCTION GetCdEstadoFC  ( p_iddoctrx  IN documentos.iddoctrx%type,
                            p_cdestado  IN documentos.cdestadocomprobante%type,
                            p_amnetodocumento in documentos.amnetodocumento%type )
    RETURN documentos.cdestadocomprobante%type is

  v_modulo    varchar2(100)                        := 'PKG_REPORTE.GetCdEstadoFC';
  v_cdestado  documentos.cdestadocomprobante%type;
  v_tieneNC   number;

  BEGIN

     if p_cdestado = '5' then
      -- si tiene NC por el mismo monto, la considero Anulada
      select count(*)
        into v_tieneNC
        from tbldocumento_control dc,
             documentos           nc
       where     dc.iddoctrx         = p_iddoctrx
         and     dc.iddoctrxgen      = nc.iddoctrx
         and     nc.cdcomprobante like 'NC%'
         and abs(nc.amnetodocumento) = abs(p_amnetodocumento);

      if v_tieneNC > 0 then
        v_cdestado := '3';
        return v_cdestado;
      end if;
    end if;

    -- si no está cancelada, o no está anulada devuelvo lo que tenía
    v_cdestado := p_cdestado;
    return v_cdestado;

  EXCEPTION WHEN OTHERS THEN
     n_pkg_vitalpos_log_general.write(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM);
     raise;
  End GetCdEstadoFC;


     /*****************************************************************************************************************
   * Función que devuelve Apellido y Nombre de la Persona dado un id determinado
   * %v 06/07/2015 - MartinM: v1.0
   ******************************************************************************************************************/
  FUNCTION GetApellidoNombrePersona(p_idpersona IN tbltesoro.idpersona%TYPE) RETURN VARCHAR2 IS

    v_ApellidoYNombre VARCHAR2(300);

  BEGIN

   select trim(p.dsapellido) || '  ' || trim(p.dsnombre)
     into v_ApellidoYNombre
     from personas p
    where p.idpersona = p_idpersona;

   return nvl(trim(v_ApellidoYNombre),'');

  EXCEPTION WHEN OTHERS THEN
      return null;
  END GetApellidoNombrePersona;


    /*****************************************************************************************************************
  * Reporte de Notas de Crédito
  * %v 06/07/2015 - MartinM: v1.0
  * %v 19/08/2015 - APW - Cambios por filas repetidas
  ******************************************************************************************************************/
  PROCEDURE GetReporteControlNC (p_fechaDesde    IN  DATE,
                                 p_fechaHasta    IN  DATE,
                                 p_autoriz       IN  VARCHAR2,
                                 p_idpersona     IN  tbltesoro.idpersona%TYPE,
                                 p_cuit          IN  entidades.cdcuit%type,
                                 p_cf            IN  NUMBER,
                                 p_canal         IN  VARCHAR2,
                                 p_sucursales    IN  VARCHAR2,
                                 p_cur_out       OUT cursor_type) IS

    v_Modulo VARCHAR2(100) := 'PKG_REPORTE_CENTRAL.GetReporteControlNC';
    v_idReporte             VARCHAR2(40) := '';
  BEGIN
    v_idReporte := SetSucursalesSeleccionadas(p_sucursales);
    OPEN p_cur_out for
     WITH taudit as
     (select distinct a.idmovmateriales, a.idpersonaautoriza, m.dsmotivo
           from auditoria a, motivos m
           where a.cdmotivo = m.cdmotivo
           and a.nmtarea in ('NotaCreditoAuto', 'NotaCredito', 'AutorizacionNC')
           and a.dtauditoria between TRUNC(p_fechaDesde) AND TRUNC(p_fechaHasta) + 1)
     SELECT     su.dssucursal,
                d.iddoctrx,
                d.dtdocumento fecha_documento,
                d.cdcomprobante tipo_documento,
                pkg_core_documento.GetDescDocumento(d.iddoctrx) dscomprobante,
                d.sqcomprobante sq_documento,
                d.cdpuntoventa cdvta_documento,
                d.amdocumento monto_documento,
                GetApellidoNombrePersona(d.idpersona) persona_operador,
                GetApellidoNombrePersona(au.idpersonaautoriza) persona_autoriza,
                au.dsmotivo motivo_autoriza,
                e.dsrazonsocial RazonSocial_Cliente,
                e.cdcuit Cuit_cliente,
                pkg_core_documento.GetDescDocumento(dfac.iddoctrx) dscomprobantefactura,
                dfac.cdcomprobante Cd_factura,
                dfac.sqcomprobante sq_factura,
                dfac.cdpuntoventa cdvta_factura,
                dfac.dtdocumento fecha_factura,
                nvl(mmfac.id_canal,
                    trim(pkg_canal.GetCanalVenta(mmfac.idmovmateriales))) canal_venta,
                case
                  when mmfac.idcomisionista is not null then
                   PKG_REPORTE_CENTRAL.GetApellidoNombrePersona(mmfac.idcomisionista)
                  when mmfac.idcomisionista is null then
                   PKG_REPORTE_CENTRAL.GetApellidoNombrePersona(nvl(pe.idvendedor,
                                                            pe.idpersonaresponsable))
                end vendedor_comisionista,
                PKG_REPORTE_CENTRAL.GetApellidoNombrePersona(dfac.idpersona) operador_facturista,
                trim(GetDescMotivoDoc (tdc.idmotivodoc)) MotivoNota,
                dfac.amdocumento Monto_factura,
                PKG_REPORTE_CENTRAL.GetDesEstadoFC(dfac.iddoctrx,
                                                   dfac.cdcomprobante,
                                                   dfac.cdestadocomprobante,
                                                   dfac.amnetodocumento) EstadoComprobante,
                PKG_REPORTE_CENTRAL.GetCdEstadoFC(dfac.iddoctrx,
                                                  dfac.cdestadocomprobante,
                                                  dfac.amnetodocumento) IdEstado,
                d.identidad
           FROM documentos           d    ,
                documentos           dfac ,
                personas             p    ,
                entidades            e    ,
                movmateriales        mmfac,
                pedidos              pe   ,
                tbldocumento_control tdc,
                taudit               au,
                tbltmp_sucursales_reporte rs,
                sucursales                su
          WHERE     d.cdcomprobante   LIKE       'NC%'
            AND     d.identidad          =     e.identidad
            AND     d.iddoctrx           =   tdc.iddoctrxgen
            AND   tdc.iddoctrx           =  dfac.iddoctrx
            AND  dfac.idmovmateriales    = mmfac.idmovmateriales
            and  mmfac.idmovmateriales   = au.idmovmateriales (+)
            AND mmfac.idpedido           =    pe.idpedido           (+)
            AND     d.idpersona          =     p.idpersona
            AND    d.cdsucursal          = su.cdsucursal
            AND    su.cdsucursal         = rs.cdsucursal
            AND    rs.idreporte          = v_idReporte
            AND     d.dtdocumento  BETWEEN TRUNC(p_fechaDesde)
                                       AND TRUNC(p_fechaHasta) + 1
            AND   (au.idpersonaautoriza  = p_autoriz                                                 or p_autoriz   is null)
            AND   ( d.idpersona          = p_idpersona                                               or p_idpersona is null)
            AND   ( e.cdcuit             = p_cuit                                                    or p_cuit      is null)
            AND   (nvl(mmfac.id_canal, trim(pkg_canal.GetCanalVenta(mmfac.idmovmateriales)))
                    in ( SELECT TRIM(SUBSTR(txt,  --esto es una técnica para transformar un string separado por comas a tabla
                                INSTR (txt, ',', 1, level ) + 1,
                                INSTR (txt, ',', 1, level + 1) - INSTR (txt, ',', 1, level) -1)) AS u
                           FROM (SELECT replace(','||p_canal||',','''','') AS txt FROM dual )
                     CONNECT BY level <= LENGTH(txt)-LENGTH(REPLACE(txt,',',''))-1) /*fin técnica*/  or p_canal     is null)
            AND   ( p_cf = 1 AND trim(e.identidad) in ( trim(Getvlparametro('IdCfReparto','General')),
                                                  trim(GetVlparametro('CdConsFinal','General')),
                                                  trim(getvlparametro('CdCFNoResidente', 'General') ))    or p_cf        is null or p_cf = 0 )
        ORDER BY fecha_documento DESC;
        PKG_REPORTE_CENTRAL.CleanSucursalesSeleccionadas(v_idReporte);
  EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2, 'Modulo: ' || v_Modulo || ' Error: ' || SQLERRM);
      RAISE;
  END GetReporteControlNC;


   PROCEDURE GetComentariosNC   (p_idDocTrx      IN  documentos.iddoctrx%type,
                                 p_cur_out       OUT cursor_type) IS
    v_Modulo VARCHAR2(100) := 'PKG_REPORTE.GetComentariosNC';
  BEGIN

    OPEN p_cur_out for
         select c.dtcomentario,
                p.dsapellido || ', ' || p.dsnombre as persona,
                c.comentario
         from   tblcontrolpuertacomentario c,
                personas p,
                tbldocumento_control dc
         where  c.idpersona = p.idpersona
                and c.iddoctrx = dc.iddoctrx
                and dc.iddoctrxgen = p_idDocTrx
         order by c.vlorden;

    EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2, 'Modulo: ' || v_Modulo || ' Error: ' || SQLERRM);
      RAISE;
  END GetComentariosNC;


 PROCEDURE GetAuditoriaBlanqueo(p_sucursales    IN VARCHAR2,
                                p_fechaDesde    IN  DATE,
                                p_fechaHasta    IN  DATE,
                                p_idEntidad     IN  entidades.identidad%type,
                                p_cur_out       OUT cursor_type) IS

    v_Modulo VARCHAR2(100) := 'PKG_REPORTE.GetAuditoriaBlanqueo';
     v_idReporte             VARCHAR2(40) := '';
  BEGIN
    v_idReporte := SetSucursalesSeleccionadas(p_sucursales);

    OPEN p_cur_out for
          select  s.cdsucursal,
                  s.dssucursal,
                  p.dsapellido || ', ' || p.dsnombre persona,
                  e.cdcuit,
                  e.dsrazonsocial,
                  c.nombrecuenta,
                  a.dtaccion
          from tblauditoria a,
               tblcuenta    c,
               entidades    e,
               personas     p,
               sucursales   s,
               tbltmp_sucursales_reporte t
          where a.idpersona = p.idpersona
                and a.idtabla   = c.idcuenta
                and c.identidad = e.identidad
                and a.cdsucursal= s.cdsucursal
                and a.nmproceso = 'PKG_SEGURIDAD.BlanquearPassword'
                and nmtabla = 'TBLCUENTA'
                and t.cdsucursal = s.cdsucursal
                and t.idreporte = v_idReporte
                and a.dtaccion between TRUNC(p_fechaDesde) AND TRUNC(p_fechaHasta) + 1
                and (e.identidad = p_idEntidad or p_idEntidad is null)
                order by a.dtaccion;

          PKG_REPORTE_CENTRAL.CleanSucursalesSeleccionadas(v_idReporte);
    EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2, 'Modulo: ' || v_Modulo || ' Error: ' || SQLERRM);
      RAISE;
  END GetAuditoriaBlanqueo;

  /*****************************************************************************************************************
  * Reporte de Auditoria de paso para atras
  * %v 06/07/2016 - LucianoF: v1.0
  ******************************************************************************************************************/
  PROCEDURE GetAuditoriaEnvioAtencion(p_sucursales    IN VARCHAR2,
                             p_fechaDesde    IN  DATE,
                             p_fechaHasta    IN  DATE,
                             p_cur_out       OUT cursor_type) IS

    v_Modulo VARCHAR2(100) := 'PKG_REPORTE.GetAuditoriaPaso';
     v_idReporte             VARCHAR2(40) := '';
  BEGIN
    v_idReporte := SetSucursalesSeleccionadas(p_sucursales);

    OPEN p_cur_out for
            select s.dssucursal,
                   a.dtauditoria,
                   a.cdcaja,
                   p.dsapellido || ', ' || p.dsnombre as persona,
                   m.dsmotivo
              from auditoria a, personas p, sucursales s, motivos m, tbltmp_sucursales_reporte t
             where a.idpersonaautoriza = p.idpersona
               and a.cdsucursal = s.cdsucursal
               and a.cdmotivo = m.cdmotivo
               and s.cdsucursal = t.cdsucursal
               and t.idreporte = v_idReporte
               and a.dtauditoria between TRUNC(p_fechaDesde) AND TRUNC(p_fechaHasta) + 1
               and a.nmtarea = 'AutEnvioAtencionCliente'
             order by a.dtauditoria;

          PKG_REPORTE_CENTRAL.CleanSucursalesSeleccionadas(v_idReporte);
    EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2, 'Modulo: ' || v_Modulo || ' Error: ' || SQLERRM);
      RAISE;
  END GetAuditoriaEnvioAtencion;

   /*****************************************************************************************************************
   * Retorna un listado de los traspasos de efectivo entre sucursales de los transportistas
   * %v 04/10/2016 - JBodnar: v1.0
   ******************************************************************************************************************/
   PROCEDURE GetTraspasoTransportita(p_IdTransportista IN tbltraspasotrans.idtransportista%type,
                                     p_fechaDesde      IN  DATE,
                                     p_fechaHasta      IN  DATE,
                                     p_cur_out         OUT cursor_type) IS
      v_Modulo VARCHAR2(100) := 'PKG_REPORTE_CENTRAL.GetTraspasoTransportita';
   BEGIN
      OPEN p_cur_out FOR
        select t.dsrazonsocial transportista, t.cdcuit,tr.dttraspaso, i.amingreso amtraspaso,
               so.dssucursal Origen, sd.dssucursal Destino , tr.vlrecibo
        from tbltraspasotrans tr, entidades t, tblingreso i, sucursales so, sucursales sd
        where tr.idtransportista = t.identidad
        and i.idingreso=tr.idingreso
        and so.cdsucursal= i.cdsucursal
        and sd.cdsucursal=tr.cdsucursaldestino
        and tr.amtraspaso > 0
        and tr.idtransportista = nvl(p_IdTransportista,tr.idtransportista)
        and tr.dttraspaso between TRUNC(p_fechaDesde) AND TRUNC(p_fechaHasta) + 1
        order by tr.dttraspaso desc;

   EXCEPTION
      WHEN OTHERS THEN
         n_pkg_vitalpos_log_general.write(2, 'Modulo: ' || v_Modulo || ' Error: ' || SQLERRM);
         RAISE;
   END GetTraspasoTransportita;

/**************************************************************************************************
* Reporte de rentabilidad de los clientes liquidados como CL
* %v 18/11/2016 - JBodnar
***************************************************************************************************/
PROCEDURE GetRentabilidadCl(p_fechaDesde IN  DATE,
                            p_fechaHasta IN  DATE,
                            p_cur_out    out cursor_type)
IS
   v_modulo varchar2(100) := 'PKG_REPORTE_CENTRAL.GetRentabilidadCl';
BEGIN

   open p_cur_out for
 Select out.fecha,
            out.comercio,
            out.tarjeta,
            out.cuit,
            out.razon_social,
            out.provincia,
            SUM(out.neto) Neto,
            SUM(out.bruto) Bruto,
            SUM(round(bruto * (1 - (nvl(vlrecargo,12)/100)),2)) pagado,
            SUM(round(neto - (bruto * (1 - (nvl(vlrecargo,12)/100))),2)) ganado,
            SUM(round((neto - (bruto * (1 - (nvl(vlrecargo,12)/100))))/(bruto * (1 - (nvl(vlrecargo,12)/100)))* 100,2)) ganancia, out.riesgo,
             pkg_conciliacion_cl.TraeCuotasSiNo(to_date(p_fechaDesde,'dd/mm/yyyy')-2 ,to_date(p_fechaHasta,'dd/mm/yyyy'),comercio) Cuotas,
             nvl(vlrecargo,12) recargo
  from (select qry.fecha,
             qry.comercio,
             qry.tarjeta,
             qry.cuit,
             qry.razon_social,
             qry.provincia,
             qry.neto,
             qry.bruto, --
             qry.vlrecargo ,
           round(qry.bruto * (1 - (nvl(qry.vlrecargo,12)/100)),2) pagado2,
           round(qry.neto - (qry.bruto * (1 - (nvl(qry.vlrecargo,12)/100))),2) ganado2,
           round((qry.neto - (qry.bruto * (1 - (nvl(qry.vlrecargo,12)/100))))/(qry.bruto * (1 - (nvl(qry.vlrecargo,12)/100)))* 100,2) ganancia2, qry.riesgo,
           pkg_conciliacion_cl.TraeCuotasSiNo(to_date(p_fechaDesde,'dd/mm/yyyy')-2 ,to_date(p_fechaHasta,'dd/mm/yyyy'),qry.comercio) Cuotas,
           nvl(qry.vlrecargo,12) recargo
    from
     (select   to_char(liq.dtvencimiento,'mm/yyyy') fecha,
               liq.vlcomercio comercio,
               liq.cdtipo tarjeta,
               dat.CUIT,
               dat.Razon_Social,
               dat.provincia,
               dat.riesgo,
               sum(liq.amimporteneto) Neto,
               sum(liq.amimportebruto) Bruto,
               dat.vlrecargo
      from     tblclliquidacion liq,
         (select distinct         lid.vlcomercio comercio,
                                  lid.idliquidacion,
                                  ent.cdcuit CUIT,
                                  ent.dsrazonsocial Razon_Social,
                                  pro.dsprovincia provincia,
                                  decode(rfi.tasa,null,null,'SI') riesgo,
                                  ent.vlrecargo
          from   tblclliquidaciondetalle lid,tblclcuponliquidaciondet cld,tblcierrelote
                 cie,tblingreso ing,tblcuenta cta,entidades ent,direccionesentidades den,
                 provincias pro,agip_enti_r1251 rfi
          where  lid.idliquidaciondetalle=cld.idliquidaciondetalle
            and  cld.idingreso=cie.idingreso
            and  cie.idingreso=ing.idingreso
            and  cta.idcuenta=ing.idcuenta
            and  cta.identidad=ent.identidad
            and  ent.identidad=den.identidad
            and  den.cdtipodireccion='2'
            and  den.sqdireccion=(select max(de2.sqdireccion) from direccionesentidades de2 where de2.identidad=den.identidad and de2.cdtipodireccion='2')
            and  den.icactiva=1
            and  den.cdpais=pro.cdpais
            and  den.cdprovincia=pro.cdprovincia
            and  rpad(replace(ent.cdcuit,'-'),20,' ')=rfi.cdcuit(+)
            and  exists (select 1 from tblclliquidacion li1
                          where li1.vlcomercio=lid.vlcomercio
                            and li1.idliquidacion=lid.idliquidacion
                            and li1.dtvencimiento >= to_date(p_fechaDesde,'dd/mm/yyyy')
                            and li1.dtvencimiento <  to_date(p_fechaHasta,'dd/mm/yyyy'))) dat
      where liq.vlcomercio=dat.comercio
      and   liq.idliquidacion=dat.idliquidacion
      group by to_char(liq.dtvencimiento,'mm/yyyy'),liq.vlcomercio,
               liq.cdtipo,dat.CUIT,dat.Razon_Social,dat.provincia,dat.riesgo,
               dat.vlrecargo
     union all
      select   to_char(liq.dtvencimiento,'mm/yyyy') mesanio,
               liq.vlcomercio comercio,
               liq.cdtipo tarjeta,
               dat.CUIT,
               dat.Razon_Social,
               dat.provincia,
               dat.riesgo,
               sum(liq.amimporteneto) Neto,
               sum(liq.amimportebruto) Bruto,
               dat.vlrecargo
      from     tblclbkliquidacion liq,
         (select distinct         lid.vlcomercio comercio,
                                  lid.idliquidacion,
                                  ent.cdcuit CUIT,
                                  ent.dsrazonsocial Razon_Social,
                                  pro.dsprovincia provincia,
                                  decode(rfi.tasa,null,null,'SI') riesgo,
                                  ent.vlrecargo
          from   tblclbkliquidaciondetalle lid,tblclbkcuponliqdet cld,tblcierrelote
                 cie,tblingreso ing,tblcuenta cta,entidades ent,direccionesentidades den,
                 provincias pro,agip_enti_r1251 rfi
          where  lid.idliquidaciondetalle=cld.idliquidaciondetalle
            and  cld.idingreso=cie.idingreso
            and  cie.idingreso=ing.idingreso
            and  cta.idcuenta=ing.idcuenta
            and  cta.identidad=ent.identidad
            and  ent.identidad=den.identidad
            and  den.cdtipodireccion='2'
            and  den.sqdireccion=(select max(de2.sqdireccion) from direccionesentidades de2 where de2.identidad=den.identidad and de2.cdtipodireccion='2')
            and  den.icactiva=1
            and  den.cdpais=pro.cdpais
            and  den.cdprovincia=pro.cdprovincia
            and  rpad(replace(ent.cdcuit,'-'),20,' ')=rfi.cdcuit(+)
            and  exists (select 1 from tblclbkliquidacion li1
                          where li1.vlcomercio=lid.vlcomercio
                            and li1.idliquidacion=lid.idliquidacion
                            and li1.dtvencimiento >= to_date(p_fechaDesde,'dd/mm/yyyy')
                            and li1.dtvencimiento <  to_date(p_fechaHasta,'dd/mm/yyyy'))) dat
      where liq.vlcomercio=dat.comercio
      and   liq.idliquidacion=dat.idliquidacion
      group by to_char(liq.dtvencimiento,'mm/yyyy'),liq.vlcomercio,
               liq.cdtipo,dat.CUIT,dat.Razon_Social,dat.provincia,dat.riesgo, dat.vlrecargo
               )  qry) out
      Group by out.fecha,
            out.comercio,
            out.tarjeta,
            out.cuit,
            out.razon_social,
            out.provincia,
            out.riesgo,
             nvl(vlrecargo,12);
   return;

EXCEPTION WHEN OTHERS THEN
   n_pkg_vitalpos_log_general.write(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM);
   raise;
End GetRentabilidadCl;

/**************************************************************************************************
* Reporte clientes / comercios que operan como Cierre de Lote
* %v 18/11/2016 - JBodnar
***************************************************************************************************/
PROCEDURE GetComerciosClientesCL(p_cur_out out cursor_type)
IS
   v_modulo varchar2(100) := 'PKG_REPORTE_CENTRAL.GetClientesCL';
BEGIN

   open p_cur_out for
    select distinct e.cdcuit, e.dsrazonsocial, s.dssucursal, es.vlestablecimiento, 'CL' Operacion
    from entidades e, tblcuenta c, tblestablecimiento es, sucursales s
    where e.cdforma = '5'
    and c.identidad = e.identidad
    and es.idcuenta = c.idcuenta
    and c.cdtipocuenta ='1'
    --and c.iccontracargo = 1
    and s.cdsucursal = c.cdsucursal
    order by e.dsrazonsocial asc;
   return;

EXCEPTION WHEN OTHERS THEN
   n_pkg_vitalpos_log_general.write(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM);
   raise;
End GetComerciosClientesCL;


 /*****************************************************************************************************************
   * Retorna un reporte de detalle de pedido
   * %v 01/12/2016 - LM: v1.0
   ******************************************************************************************************************/
  PROCEDURE GetDetallePedido(cur_out          OUT CURSOR_TYPE,
                             p_idpedido        IN pedidos.idpedido%type) IS
    BEGIN
      OPEN cur_out FOR
           select suc.dssucursal cdsucursal,e.cdcuit, e.dsrazonsocial,to_char(do.dtdocumento, 'dd/MM/yyyy') fecha,dp.cdarticulo ||' - '|| dp.dsarticulo cdarticulo,
        case when nvl(dp.qtpiezas,0)>0 then
          dp.qtpiezas
          else
             dp.qtunidadpedido
          end qtunidadpedido ,
          case when nvl(dp.qtpiezas,0)>0 then
            'PZA'
            else
               dp.cdunidadmedida end cdunidadmedida
          FROM pedidos pe, documentos do, entidades e, detallepedidos dp, sucursales suc
         WHERE pe.iddoctrx = do.iddoctrx
           and do.identidadreal = e.identidad
           and do.cdcomprobante = 'PEDI'
           AND pe.idpedido = p_idpedido
           and pe.idpedido=dp.idpedido
           and dp.icresppromo=0
           and do.cdsucursal=suc.cdsucursal;

    END GetDetallePedido;


/*****************************************************************************************************************
* Retorna un reporte de Tarjetas
* %v 17/01/2017 - IAquilano: v1.0
******************************************************************************************************************/

PROCEDURE GetTarjetas(p_sucursales IN VARCHAR2,
                      p_FechaDesde IN DATE,
                      p_FechaHasta IN DATE,
                      p_cur_out    OUT cursor_type,
                      p_tipo IN NUMBER,
                      p_tipoing IN tblconfingreso.cdtipo%TYPE,
                      p_medio in tblconfingreso.cdmedio%TYPE,
                      p_importe in tblingreso.amingreso%TYPE) IS
  v_modulo VARCHAR2(100) := 'PKG_REPORTE_CENTRAL.GetTarjetas';
  v_idReporte VARCHAR2(40) := '';
BEGIN
  v_idReporte := SetSucursalesSeleccionadas(p_sucursales);
  if p_tipo = 0 then
  OPEN p_cur_out FOR
    select ti.cdsucursal,
           su.dssucursal,
           tj.dsnrocupon,
           tj.nrolote,
           tj.vlterminal,
           ti.amingreso,
           ee.dsrazonsocial,
           ee.cdcuit,
           mc.cdcaja,
           ti.dtingreso,
           pe.dsapellido || ', ' || pe.dsnombre as cajero,
           pkg_ingreso_central.GetDescIngreso(ti.cdconfingreso,
                                              ti.cdsucursal) as descripcion

      from tbltarjeta tj,
           tblingreso ti,
           tblcuenta  tc,
           entidades  ee,
           tblmovcaja mc,
           personas   pe,
           sucursales su,
           tbltmp_sucursales_reporte rs,
           tblconfingreso ci
     where tj.idingreso = ti.idingreso
       and ti.idcuenta = tc.idcuenta
       and tc.identidad = ee.identidad
       and ti.idmovcaja = mc.idmovcaja
       and ti.cdsucursal = su.cdsucursal
       and mc.idpersonaresponsable = pe.idpersona
       and rs.cdsucursal = ti.cdsucursal
       and rs.idreporte = v_idReporte
       and ti.cdconfingreso = ci.cdconfingreso
       and trim(ci.cdtipo) = NVL(p_tipoing,trim(ci.cdtipo))
       and trim(ci.cdmedio) = NVL(p_medio,trim(ci.cdmedio))
       and ti.cdsucursal = ci.cdsucursal
       and ti.amingreso = NVL(p_importe,ti.amingreso)
       AND ti.dtingreso BETWEEN trunc(p_fechaDesde) AND
           trunc(p_fechaHasta + 1);
   else

     OPEN p_cur_out FOR
    select ti.cdsucursal,
           su.dssucursal,
           tcl.vlcierrelote,
           tcl.vlterminal,
           tcl.vlestablecimiento,
           tcl.dtcierrelote,
           ee.dsrazonsocial,
           ee.cdcuit,
           mc.cdcaja,
           ti.amingreso,
           ti.dtingreso,
           pe.dsapellido || ', ' || pe.dsnombre as cajero,
           pkg_ingreso_central.GetDescIngreso(ti.cdconfingreso,
                                              ti.cdsucursal) as descripcion
      from tblcierrelote tcl,
           tblingreso ti,
           tblcuenta  tc,
           entidades  ee,
           tblmovcaja mc,
           personas   pe,
           sucursales su,
           tbltmp_sucursales_reporte rs,
           tblconfingreso ci
     where tcl.idingreso = ti.idingreso
       and ti.idcuenta = tc.idcuenta
       and tc.identidad = ee.identidad
       and ti.idmovcaja = mc.idmovcaja
       and ti.cdsucursal = su.cdsucursal
       and mc.idpersonaresponsable = pe.idpersona
       and rs.cdsucursal = ti.cdsucursal
       and rs.idreporte = v_idReporte
       and ti.cdconfingreso = ci.cdconfingreso
       and trim(ci.cdtipo) = NVL(p_tipoing,trim(ci.cdtipo))
       and trim(ci.cdmedio) = NVL(p_medio,trim(ci.cdmedio))
        and ti.amingreso = NVL(p_importe,ti.amingreso)
       and ti.cdsucursal = ci.cdsucursal
       AND ti.dtingreso BETWEEN trunc(p_fechaDesde) AND
           trunc(p_fechaHasta + 1);
    end if;

EXCEPTION
  WHEN OTHERS THEN
    n_pkg_vitalpos_log_general.write(2,
                                     'Modulo: ' || v_modulo || '  Error: ' ||
                                     SQLERRM);
    RAISE;
END GetTarjetas;

/****************************************************************************************
* Retorna canal optativo de venta que tiene configurado el cliente.
* %v 21/02/2017 - IAquilano: v1.0
/****************************************************************************************/

FUNCTION GetCanal(p_ident		      IN ENTIDADES.IDENTIDAD%TYPE,
				          p_cdSucursal    IN sucursales.cdsucursal%TYPE  ) RETURN VARCHAR2 IS
      v_canal VARCHAR2(8);
	    v_contv INTEGER;
	    v_contc INTEGER;

   BEGIN

   v_contv := 0;
   v_contc := 0;

   select count(idviajante)
   into v_contv
   from clientesviajantesvendedores clv
   where clv.identidad = p_ident
   and clv.cdsucursal = p_cdSucursal
   and  clv.dthasta = (SELECT MAX(dthasta) FROM clientesviajantesvendedores T );

   select count(idcomisionista)
   into v_contc
   from clientescomisionistas clc
   where clc.identidad = p_ident;

   if v_contv > 0 and v_contc > 0 then
      v_canal := 'VE - CO';
	    else if v_contv > 0 and v_contc = 0 then
		       v_canal := 'VE';
		       else if v_contv = 0 and v_contc > 0 then
		            V_canal := 'CO';
			          else
			          v_canal := ' ';
			          end if;
		     end if;
	end if;

      RETURN v_canal;

   EXCEPTION
      WHEN OTHERS THEN
         RETURN null;
   END GetCanal;

 /*****************************************************************************************************************
 * Retorna el detalle de los saldos de los clientes positivos
 * %v 23/02/2017 - JBodnar: v1.0
 ******************************************************************************************************************/
 PROCEDURE GetUltimoSaldoDetalle(p_sucursales  IN VARCHAR2,
                                 p_identidad   IN entidades.identidad%TYPE,
                                 p_idcuenta    IN tblcuenta.idcuenta%TYPE,
                                 p_tiposaldo   IN Integer,
                                 p_cur_out     OUT cursor_type)
IS
      v_Modulo         VARCHAR2(100) := 'PKG_REPORTE_CENTRAL.GetUltimoSaldoDetalle';
      v_idReporte      VARCHAR2(40) := '';
 BEGIN

    v_idReporte := SetSucursalesSeleccionadas(p_sucursales);
 Case when p_tiposaldo = 1 then
    OPEN p_cur_out FOR
    select
        su.dssucursal,
        e.dsrazonsocial,
        e.cdcuit,
        c.nombrecuenta,
        s.amsaldo,
        s.dtultmov,
        pkg_reporte_central.GetCanal(e.identidad, c.cdsucursal) canal
    from tblsaldo s,
         tblcuenta c,
         entidades e,
         sucursales su,
         tbltmp_sucursales_reporte rs
    where s.amsaldo > 0
    and s.idcuenta = c.idcuenta
    and c.identidad = e.identidad
    and su.cdsucursal = c.cdsucursal
    and e.identidad = nvl(p_identidad, e.identidad)
    and c.idcuenta  = nvl(p_idcuenta , c.idcuenta)
    and rs.cdsucursal = c.cdsucursal
    and rs.idreporte = v_idReporte
    order by s.amsaldo desc;
    when p_tiposaldo = 2 then
      OPEN p_cur_out FOR
    select
        su.dssucursal,
        e.dsrazonsocial,
        e.cdcuit,
        c.nombrecuenta,
        s.amsaldo,
        s.dtultmov,
        pkg_reporte_central.GetCanal(e.identidad, c.cdsucursal) canal
    from tblsaldo s,
         tblcuenta c,
         entidades e,
         sucursales su,
         tbltmp_sucursales_reporte rs
    where s.amsaldo < 0
    and s.idcuenta = c.idcuenta
    and c.identidad = e.identidad
    and su.cdsucursal = c.cdsucursal
    and e.identidad = nvl(p_identidad, e.identidad)
    and c.idcuenta  = nvl(p_idcuenta , c.idcuenta)
    and rs.cdsucursal = c.cdsucursal
    and rs.idreporte = v_idReporte
    order by s.amsaldo desc;

    end case;

    CleanSucursalesSeleccionadas(v_idReporte);

 EXCEPTION
    WHEN OTHERS THEN
       n_pkg_vitalpos_log_general.write(2, 'Modulo: ' || v_Modulo || ' Error: ' || SQLERRM);
       RAISE;
 END GetUltimoSaldoDetalle;

      /*****************************************************************************************************************
   * Retorna un cursor con las gestiones de los establecimientos
   * %v 16/05/2017 - LM: v1.0
   * %v 12/12/2017 - LM: v2.0 . se modifica el filtro, que busque las fechas de las modificaciones y no por fecha de recepcion
   * %v 22/05/2018 - LM: v3.0 . se quita el filtro de estado de la terminal y se lista solo las gestiones establecimientos, ya que ahora es multiterminal.
   * %v 01/06/2018 - LM: v4.0 . se corrige para que muestre las gestiones que no tengan direcciones seleccionadas
   * %v 06/06/2018 - LM: v5.0 . se controla las fechas si tienen NULL
   ******************************************************************************************************************/
   Procedure GetGestionEstablecimiento(p_sucursales In Varchar2,
                         p_fechaDesde In Date,
                         p_fechaHasta In Date,
                         p_identidad in entidades.identidad%TYPE,
                         --p_estado    in tblgsterminal.cdestado%TYPE,
                         p_cur_out    Out cursor_type) Is
     v_modulo    Varchar2(100) := 'PKG_REPORTE_CENTRAL.GetGestionEstablecimiento';
     v_idReporte Varchar2(40) := '';
   Begin
     v_idReporte := SetSucursalesSeleccionadas(p_sucursales);

     Open p_cur_out For
     select rep.idgsestablecimiento, rep.idcuenta, rep.dssucursal, rep.cdcuit, rep.dsrazonsocial, rep.telefono, rep.dssituacioniva, rep.dtrecepcion,
rep.dsforma, rep.mntipoterminal, rep.dtenviodoc, rep.dsobservacion, rep.estado, de.dscalle || ' #' || de.dsnumero direccion, loc.dslocalidad || ' ('||prov.dsprovincia||')' Localidad, nvl(de.cdcodigopostal,'.')cdcodigopostal
from
(
 select ge.idgsestablecimiento, c.idcuenta, suc.dssucursal, e.cdcuit, e.dsrazonsocial,ge.sqdireccion, ge.cdtipodireccion, e.identidad,
      nvl(
      (select ce.dscontactoentidad from contactosentidades ce
      where   e.identidad=ce.identidad
      and ce.cdformadecontacto(+)='3       '
      and  rownum=1),'.'
      ) telefono,  sii.dssituacioniva,
      decode(nvl(ge.dtrecepcion,'01/01/1900'),'01/01/1900','.', to_char(ge.dtrecepcion,'dd/mm/yyyy'))dtrecepcion,
      fi.dsforma,
      nvl(tt.mntipoterminal,'.')mntipoterminal,
      decode(nvl(ge.dtenviodoc,'01/01/1900'),'01/01/1900','.', to_char(ge.dtrecepcion,'dd/mm/yyyy')) dtenviodoc,
      nvl(ge.dsobservacion,'.') dsobservacion,
       case
                when nvl(ge.icbaja,0)=0 then
                 'Activa'
                else
                 'Baja'
              end as estado
      from entidades e, tblgsestablecimiento ge, tblcuenta c, sucursales suc, tblformaingreso fi, tbltipoterminal tt,
         tbltmp_sucursales_reporte rs,   infoimpuestosentidades iie , situacionesiva sii
      where e.identidad=c.identidad
      and c.idcuenta=ge.idcuenta
      and c.cdsucursal=suc.cdsucursal
      and ge.cdforma=fi.cdforma
      and ge.idtipoterminal=tt.idtipoterminal (+)
      and e.identidad = NVL(p_identidad,e.identidad)
      and suc.cdsucursal = rs.cdsucursal
      and rs.idreporte = v_idReporte
      and e.identidad=iie.identidad
      and iie.cdsituacioniva=sii.cdsituacioniva
      and ge.dtinsertupdate between trunc(p_fechaDesde) AND  trunc(p_fechaHasta + 1))rep,  direccionesentidades de, localidades loc, provincias prov
      where  de.sqdireccion (+)=rep.sqdireccion
      and de.cdtipodireccion (+) =rep.cdtipodireccion
      and de.cdlocalidad=loc.cdlocalidad (+)
      and de.cdprovincia=loc.cdprovincia (+)
      and loc.cdprovincia=prov.cdprovincia (+)
      and rep.identidad=de.identidad (+);
     /* select c.idcuenta, suc.dssucursal, e.cdcuit, e.dsrazonsocial, de.dscalle || ' #' || de.dsnumero direccion, loc.dslocalidad || ' ('||prov.dsprovincia||')' Localidad, de.cdcodigopostal,
      nvl(
      (select ce.dscontactoentidad from contactosentidades ce
      where   e.identidad=ce.identidad
      and ce.cdformadecontacto(+)='3       '
      and  rownum=1),'.'
      ) telefono,  sii.dssituacioniva,
      ge.dtrecepcion, fi.dsforma,
      tt.mntipoterminal,
      decode(nvl(ge.dtenviodoc,'01/01/1900'),'01/01/1900','.', to_char(ge.dtrecepcion,'dd/mm/yyyy')) dtenviodoc,
      nvl(term.dsempresa,'.') dsempresa, decode(nvl(term.dtpedido,'01/01/1900'),'01/01/1900','.', to_char(term.dtpedido,'dd/mm/yyyy')) dtpedido, nvl(term.vlterminal,'.')vlterminal,
      decode(nvl(term.dtinstalacion,'01/01/1900'),'01/01/1900','.', to_char(term.dtinstalacion,'dd/mm/yyyy')) dtinstalacion,
         case
                when term.cdestado = 1 then
                 'Instalada'
                when term.cdestado = 2 then
                 'Bloqueada'
                when term.cdestado = 3 then
                 'Rechazada'
                when term.cdestado = 4 then
                 'Baja'
                when term.cdestado = 5 then
                 'Pendiente'
                else
                 '.'
              end as estado,
              decode(nvl(term.dtbaja,'01/01/1900'),'01/01/1900','.', to_char(term.dtbaja,'dd/mm/yyyy')) dtBaja, nvl(ge.dsobservacion,'.') dsobservacion
      from entidades e, tblgsestablecimiento ge, tblcuenta c, sucursales suc, tblformaingreso fi, tbltipoterminal tt,
         tbltmp_sucursales_reporte rs, tblgsterminal term, direccionesentidades de, localidades loc, provincias prov, infoimpuestosentidades iie , situacionesiva sii
      where e.identidad=c.identidad
      and c.idcuenta=ge.idcuenta
      and c.cdsucursal=suc.cdsucursal
      and ge.cdforma=fi.cdforma
      and ge.idtipoterminal=tt.idtipoterminal
      and ge.idgsestablecimiento=term.idgsestablecimiento
      and e.identidad = NVL(p_identidad,e.identidad)
      and nvl(term.cdestado,'X') = NVL(p_estado,nvl(term.cdestado,'X'))
      and suc.cdsucursal = rs.cdsucursal
      and rs.idreporte = v_idReporte
      and e.identidad=de.identidad
      and de.sqdireccion=ge.sqdireccion
      and de.cdtipodireccion=ge.cdtipodireccion
      and de.cdlocalidad=loc.cdlocalidad
      and de.cdprovincia=loc.cdprovincia
      and loc.cdprovincia=prov.cdprovincia
      and e.identidad=iie.identidad
      and iie.cdsituacioniva=sii.cdsituacioniva
      and ge.dtinsertupdate between trunc(p_fechaDesde) AND       trunc(p_fechaHasta + 1); */

     CleanSucursalesSeleccionadas(v_idReporte);
   Exception
     When Others Then
       n_pkg_vitalpos_log_general.write(2,
                                        'Modulo: ' || v_modulo ||
                                        '  Error: ' || Sqlerrm);
       Raise;
   End GetGestionEstablecimiento;
 /*****************************************************************************************************************
 * Retorna el detalle de los establecimientos por Gestion establecimiento
 * %v 22/05/2018 - LM: v1.0
 ******************************************************************************************************************/

  PROCEDURE GetDetGsEstablecimiento(p_idgsestablecimiento IN tblcuenta.idcuenta%TYPE,
                       cur_out               OUT cursor_type) AS
    v_Modulo VARCHAR2(100) := 'PKG_REPORTE_CENTRAL.GetDetGsEstablecimiento';
  BEGIN
    --Retorno cursor con todos los datos del Detalle
    OPEN cur_out FOR
      SELECT td.idgsdetalle,
             td.idgsestablecimiento,
             td.vlestablecimiento,
             ti.dstipo,
             td.dtrecibido,
             td.idestablecimiento,
             td.cdtipo
        FROM tblgsestablecimientodet td , tbltipoingreso ti
       WHERE td.idgsestablecimiento = p_idgsestablecimiento
             and td.cdtipo=ti.cdtipo
             and td.dsestado = 1;
  EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_Modulo ||
                                       '  Error: ' || SQLERRM);
      RAISE;
  END GetDetGsEstablecimiento;


  /****************************************************************************************
  * Dada un idGestion retorna los datos de la Tabla Terminal
  * %v 22/05/2018 - LM: v1.0
  *****************************************************************************************/
  PROCEDURE GetTerminalGsEstabl(p_idgsestablecimiento IN tblcuenta.idcuenta%TYPE,
                        cur_out               OUT cursor_type) AS
    v_Modulo VARCHAR2(100) := 'PKG_REPORTE_CENTRAL.GetTerminalGsEstabl';
  BEGIN

    --Retorno cursor con todos los datos del Detalle
    OPEN cur_out FOR
      SELECT td.idterminal,
             td.idgsestablecimiento,
             nvl(td.dsempresa,'.')dsempresa,
             td.dtpedido,
             nvl(td.vlterminal,'.')vlterminal,
             nvl(to_char(td.dtinstalacion,'dd/mm/yyyy'),'.') dtinstalacion,
             td.cdestado,
             te.dsestado,
             nvl(to_char(td.dtbaja,'dd/mm/yyyy'),'.') dtbaja,
             td.dtinsert,
             td.dtupdate
        FROM tblgsterminal td, tblestadoterminal te
       WHERE td.idgsestablecimiento = p_idgsestablecimiento
         and td.cdestado = te.cdestado
         order by td.dtpedido;
  EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_Modulo ||
                                       '  Error: ' || SQLERRM);
      RAISE;
  END GetTerminalGsEstabl;


 /*****************************************************************************************************************
 * Retorna las guias con deuda
 * %v 17/07/2017 - JBodnar: v1.0
 ******************************************************************************************************************/
 PROCEDURE GetDeudaGuia(p_fechaDesde  IN  DATE,
                        p_fechaHasta  IN  DATE,
                        p_cur_out     OUT cursor_type)
IS
      v_Modulo         VARCHAR2(100) := 'PKG_REPORTE_CENTRAL.GetDeudaGuia';
 BEGIN

    OPEN p_cur_out FOR
    select d.nroguia, d.dsestado, d.cliente, d.transportista, d.dtguia, d.amguia, d.amdeuda, s.dssucursal
    from tbldeudaguia d, sucursales s
    where d.dtguia between trunc(p_fechaDesde) AND trunc(p_fechaHasta + 1)
    and d.cdsucursal = s.cdsucursal;

 EXCEPTION
    WHEN OTHERS THEN
       n_pkg_vitalpos_log_general.write(2, 'Modulo: ' || v_Modulo || ' Error: ' || SQLERRM);
       RAISE;
 END GetDeudaGuia;

 /*****************************************************************************************************************
 * Retorna datos de tarjetas para conciliacion comercio propio - Para todas las sucursales
 * %v 13/09/2017 - APW
 * %v 22/11/2017 - APW - agrego al filtro que solo sean ingresos para que no aparezcan los rechazos
 * %v 15/12/2017 - LM - se corrige un JOIN
 * %v 22/12/2017 - IAquilano - Se agrega condicion para consultar solo giftcard
 * %v 02/05/2018 - APW - Se cambia el control de Manual revisando modoingreso en lugar de emisortarjeta
 ******************************************************************************************************************/
PROCEDURE GetTarjetasParaConciliacionCP(p_cdSucursal   IN sucursales.cdsucursal%TYPE,
                                        p_fechaDesde   IN DATE,
                                        p_fechaHasta   IN DATE,
                                        p_sologiftcard IN INTEGER,
                                        p_cur_out      OUT cursor_type) IS
  v_Modulo VARCHAR2(100) := 'PKG_REPORTE_CENTRAL.GetTarjetasParaConciliacionCP';
BEGIN

  If p_sologiftcard = 0 then

    OPEN p_cur_out FOR
    -- cupones ventas en comercio propio
      SELECT TO_CHAR(II.DTINGRESO, 'DD/MM/YYYY') FECHA,
             TO_CHAR(ii.dtingreso, 'HH24:MI:SS') HORA,
             PKG_INGRESO_CENTRAL.GETDESCINGRESO(II.CDCONFINGRESO,
                                                II.CDSUCURSAL) INGRESO,
             PKG_INGRESO_CENTRAL.GETDESCTIPO(II.CDCONFINGRESO,
                                             II.CDSUCURSAL) TIPO,
             PKG_INGRESO_CENTRAL.GETDESCMEDIO(II.CDCONFINGRESO,
                                              II.CDSUCURSAL) MEDIO,
             TA.NROTARJETA NROTJA,
             TA.PLANCUOTAS CUOTAS,
             II.AMINGRESO MONTO,
             II.CDSUCURSAL SUCURSAL,
             TA.VLTERMINAL TERMINAL,
             TA.NROLOTE LOTE,
             TA.DSNROCUPON CUPON,
             TA.EMISORTARJETA EMISOR,
             'S' || DECODE(TA.emisortarjeta, NULL, 'M', 'A') ORIGEN,
             TA.CDCOMERCIO COMERCIO
        FROM TBLTARJETA TA, TBLINGRESO II, tblconfingreso ci
       WHERE TA.IDINGRESO = II.IDINGRESO
         AND II.CDESTADO NOT IN ('4', '5')
         and ii.cdconfingreso = ci.cdconfingreso
         and ci.cdaccion = '1' -- solo ingreso
         AND II.CDSUCURSAL = NVL(p_cdSucursal, II.CDSUCURSAL)
         AND II.DTINGRESO BETWEEN P_FECHADESDE AND P_FECHAHASTA + 1
      UNION
      -- cierre de lote de comercio propio
      SELECT DISTINCT TO_CHAR(II.DTINGRESO, 'DD/MM/YYYY') FECHA,
                      TO_CHAR(II.DTINGRESO, 'HH24:MI:SS') HORA,
                      PKG_INGRESO_CENTRAL.GETDESCINGRESO(II.CDCONFINGRESO,
                                                         II.CDSUCURSAL) INGRESO,
                      PKG_INGRESO_CENTRAL.GETDESCTIPO(II.CDCONFINGRESO,
                                                      II.CDSUCURSAL) TIPO,
                      PKG_INGRESO_CENTRAL.GETDESCMEDIO(II.CDCONFINGRESO,
                                                       II.CDSUCURSAL) MEDIO,
                      '' NROTJA,
                      '' CUOTAS,
                      II.AMINGRESO MONTO,
                      II.CDSUCURSAL SUCURSAL,
                      C.VLTERMINAL TERMINAL,
                      TO_CHAR(C.VLCIERRELOTE) LOTE,
                      '' CUPON,
                      CI.DSTERMINALPOSNET EMISOR,
                      'CL' ORIGEN,
                      C.VLESTABLECIMIENTO AS COMERCIO--'' COMERCIO
        FROM TBLCIERRELOTE            C,
             TBLCLIENTESPECIAL        CE,
             TBLESTABLECIMIENTOMAYCAR EM,
             TBLINGRESO               II,
             TBLCONFINGRESO           CI,
             TBLFORMAINGRESO          FI
       WHERE C.VLESTABLECIMIENTO = EM.VLESTABLECIMIENTOMAYCAR
         AND EM.IDESTABLECIMIENTOMAYCAR = CE.IDESTABLECIMIENTOMAYCAR
         AND CE.IDCUENTA = II.IDCUENTA
         AND C.IDINGRESO = II.IDINGRESO
         AND CI.CDCONFINGRESO = II.CDCONFINGRESO
         AND CI.CDSUCURSAL = II.CDSUCURSAL
         AND EM.CDFORMA = CI.CDFORMA
         AND EM.Cdtipo = ci.cdtipo
         AND FI.CDFORMA = EM.CDFORMA
         AND II.CDESTADO NOT IN ('4', '5')
         and ci.cdaccion = '1' -- solo ingreso
         AND II.CDSUCURSAL = NVL(p_cdSucursal, II.CDSUCURSAL)
         AND II.DTINGRESO BETWEEN P_FECHADESDE AND P_FECHAHASTA + 1;
  Else
    OPEN p_cur_out FOR
    -- cupones Giftcard
      SELECT TO_CHAR(II.DTINGRESO, 'DD/MM/YYYY') FECHA,
             TO_CHAR(ii.dtingreso, 'HH24:MI:SS') HORA,
             PKG_INGRESO_CENTRAL.GETDESCINGRESO(II.CDCONFINGRESO,
                                                II.CDSUCURSAL) INGRESO,
             PKG_INGRESO_CENTRAL.GETDESCTIPO(II.CDCONFINGRESO,
                                             II.CDSUCURSAL) TIPO,
             PKG_INGRESO_CENTRAL.GETDESCMEDIO(II.CDCONFINGRESO,
                                              II.CDSUCURSAL) MEDIO,
             '*'||TA.NROTARJETA NROTJA,
             TA.PLANCUOTAS CUOTAS,
             II.AMINGRESO MONTO,
             II.CDSUCURSAL SUCURSAL,
             TA.VLTERMINAL TERMINAL,
             TA.NROLOTE LOTE,
             TA.DSNROCUPON CUPON,
             TA.EMISORTARJETA EMISOR,
             'S' || DECODE(TA.emisortarjeta, NULL, 'M', 'A') ORIGEN,
             TA.CDCOMERCIO COMERCIO
        FROM TBLTARJETA TA, TBLINGRESO II, tblconfingreso ci
       WHERE TA.IDINGRESO = II.IDINGRESO
            --AND II.CDESTADO NOT IN ('4','5')
         and ii.cdconfingreso = ci.cdconfingreso
         and ci.cdaccion = '1' -- solo ingreso
         AND II.CDSUCURSAL = NVL(p_cdSucursal, II.CDSUCURSAL)
         AND CI.CDSUCURSAL = II.CDSUCURSAL
         and ci.cdconfingreso = '811' --traigo solo las gift card
         AND II.DTINGRESO BETWEEN P_FECHADESDE AND P_FECHAHASTA + 1;
  End if;

EXCEPTION
  WHEN OTHERS THEN
    n_pkg_vitalpos_log_general.write(2,
                                     'Modulo: ' || v_Modulo || ' Error: ' ||
                                     SQLERRM);
    RAISE;
END GetTarjetasParaConciliacionCP;
/**************************************************************************************************
 * 08/04/2020 - ChM
 * function PipeCajas
 * convierte en tabla la lista que recibe como parámetro
 ***************************************************************************************************/
 Function PipeCajas Return cajassucursalesPipe
   Pipelined Is
   i Binary_Integer := 0;
 Begin
   i := Arreglo_Cajas.FIRST;
   While i Is Not Null Loop
     Pipe Row(Arreglo_Cajas(i));
     i := Arreglo_Cajas.NEXT(i);
   End Loop;
   Return;
 Exception
   When Others Then
     Null;
 End PipeCajas;
/*****************************************************************************************************************
 * Retorna cursor con resumen de las diferencias de todas cajas de todas las sucursales para una fecha.
 * %v 13/04/2020 - ChM: v1.0
 ******************************************************************************************************************/
PROCEDURE GetCajaSucursalesGeneralM(p_sucursales      IN Varchar2,
                                    p_fechadesde      IN DATE,
                                    p_fechahasta      IN DATE,
                                    p_cur_out         OUT cursor_type) IS

  v_Modulo      VARCHAR2(100) := 'PKG_REPORTE_CENTRAL.GetCajaSucursalesGeneralM';
  v_cur_out     cursor_type;
  v_dtfecha    date;
  v_monto       number;
  v_i           number;
  v_idReporte   Varchar2(40) := '';
  BEGIN

  v_idReporte := SetSucursalesSeleccionadas(p_sucursales);
  v_i:=0;
  --itera en cada sucursal vigente para la fecha establecida
FOR SUCU IN
 (SELECT su.cdsucursal,su.dssucursal
    FROM sucursales su,
         tbliniciofe ini,
         tbltmp_sucursales_reporte rs
   WHERE su.servidor IS NOT NULL
     and su.cdsucursal not in ('9991', '9998    ', '9999    ')
     and ini.cdsucursal=su.cdsucursal
     and ini.dtinicio<= p_fechadesde
     and rs.idreporte = v_idReporte
     and rs.cdsucursal = su.cdsucursal
   ORDER BY 1)
LOOP
  --recupera los saldos de cada sucursal
   GetCajaSucursalgeneral(p_fechadesde,p_fechahasta,SUCU.CDSUCURSAL,v_cur_out);
   --recorro el cursor por sucursal
   loop
     fetch v_cur_out
      into v_dtfecha,
           v_monto;
     exit when v_cur_out%notfound;
     Arreglo_Cajas(V_i).cdsucursal:= SUCU.CDSUCURSAL;
     Arreglo_Cajas(V_i).dssucursal:= SUCU.DSSUCURSAL;
     Arreglo_Cajas(V_i).fecha := v_dtfecha;
     Arreglo_Cajas(V_i).monto := v_monto;
     V_i := V_i + 1;
    end loop;
    close v_cur_out;
END LOOP;
--valido si genero resultados y cargo el cursor DE SALIDA con todos los resultados
IF(V_i <> 0) THEN
   OPEN p_cur_out FOR
         SELECT cj.cdsucursal,cj.dssucursal,cj.fecha ,cj.monto FROM TABLE(PipeCajas) cj
         ORDER BY 1;
END IF;
  EXCEPTION
  WHEN OTHERS THEN
    n_pkg_vitalpos_log_general.write(2,
                                     'Modulo: ' || v_Modulo || ' Error: ' ||
                                     SQLERRM);
    RAISE;
END GetCajaSucursalesGeneralM;
/*****************************************************************************************************************
 * Retorna cursor con el detalle de las cajas de la sucursal detallado por cajeros para una fecha.
 * %v 02/10/2017 - IAquilano: v1.0
 ******************************************************************************************************************/
PROCEDURE GetCajaSucursalDetallado(p_fecha      IN DATE,
                                   p_cdsucursal IN sucursales.cdsucursal%type,
                                   p_cur_out    OUT cursor_type) IS
  v_Modulo VARCHAR2(100) := 'PKG_REPORTE_CENTRAL.GetCajaSucursalDetallado';
BEGIN

  OPEN p_cur_out FOR
    select a.dsapellido,
           a.inicial,
           a.cierre,
           - (a.inicial - a.cierre) diferencia,
           '1' as c
      from (select p.dsapellido,
                   nvl((SELECT sum(nvl(mc1.ammovimiento,0)) ammovimiento
                      FROM tblmovcaja mc1
                     WHERE mc1.idpersonaresponsable = p.idpersona
                       AND mc1.cdoperacioncaja = '1' --Apertura de Caja
                       AND mc1.dtmovimiento = dtApertura
                       and mc1.cdsucursal = p_cdsucursal),0) Inicial,

                   nvl((SELECT sum(nvl(mc1.ammovimiento,0)) ammovimiento
                      FROM tblmovcaja mc1
                     WHERE mc1.idpersonaresponsable = p.idpersona
                       AND mc1.cdoperacioncaja = '4' --Cierre de Caja
                       AND mc1.dtmovimiento = dtCierre
                       and mc1.cdsucursal = p_cdsucursal),0) Cierre

              from (select pp.idpersona,
                           pp.dsapellido,
                           min(mc3.dtmovimiento) dtApertura,
                           max(mc3.dtmovimiento) dtCierre
                      from personas pp, tblmovcaja mc3
                     where mc3.dtmovimiento between p_fecha and --fecha desde
                           p_fecha + 1 -- fecha hasta
                       and mc3.cdoperacioncaja in ('1', '4') --Apertura o Cierre de caja
                       and pp.idpersona = mc3.idpersonaresponsable
                       and mc3.cdsucursal = p_cdsucursal --sucursal
                     group by pp.idpersona, pp.dsapellido) p) a
    UNION
    select 'TESORO' as apellido, inicial.saldo, cierre.saldo, -(cierre.saldo - inicial.saldo) diferencia, '2' as C
              from (select trunc(t.dtoperacion) fecha,
                           nvl(sum(t.amsaldo), 0) saldo
                      from tbltesoro t
                     where t.sqtesoro =
                           (select max(t.sqtesoro)
                              from tblconfingreso c1,
                                   tblconfingreso c2,
                                   tbltesoro      t
                             where c1.cdconfingreso = '035' --MarianoL 13/11/15: comentado  in ('035', '9035')
                               and c1.icestado = 1
                               and c1.cdsucursal = p_cdsucursal--sucursal
                               and c2.cdmedio = c1.cdmedio
                               and c2.cdtipo = c1.cdtipo
                               and c2.cdforma = c1.cdforma
                               and c2.cdsucursal = c1.cdsucursal
                               and c2.icestado = 1
                               and t.cdconfingreso = c2.cdconfingreso
                               and t.dtoperacion < trunc(p_fecha)+1 --fechahasta
                               and t.cdsucursal = c1.cdsucursal)
                       and t.cdsucursal = p_cdsucursal --sucursal
                     group by trunc(t.dtoperacion)) Inicial,

                   (select trunc(t.dtoperacion) fecha,
                           nvl(sum(t.amsaldo), 0) saldo
                      from tbltesoro t
                     where t.sqtesoro =
                           (select max(t.sqtesoro)
                              from tblconfingreso c1,
                                   tblconfingreso c2,
                                   tbltesoro      t
                             where c1.cdconfingreso = '035' --MarianoL 13/11/15: comentado  in ('035', '9035')
                               and c1.icestado = 1
                               and c1.cdsucursal = p_cdsucursal --sucursal
                               and c2.cdmedio = c1.cdmedio
                               and c2.cdtipo = c1.cdtipo
                               and c2.cdforma = c1.cdforma
                               and c2.cdsucursal = c1.cdsucursal
                               and c2.icestado = 1
                               and t.cdconfingreso = c2.cdconfingreso
                               and t.dtoperacion < trunc(p_fecha) --fechadesde
                               and t.cdsucursal = c1.cdsucursal)
                       and t.cdsucursal = p_cdsucursal --sucursal
                     group by trunc(t.dtoperacion)) cierre
     order by c, dsapellido;

EXCEPTION
  WHEN OTHERS THEN
    n_pkg_vitalpos_log_general.write(2,
                                     'Modulo: ' || v_Modulo || ' Error: ' ||
                                     SQLERRM);
    RAISE;
END GetCajaSucursalDetallado;

/*****************************************************************************************************************
 * Retorna cursor con el detalle de las cajas de la sucursal general para un rango de fechas para una unica sucursal
 * %v 06/10/2017 - IAquilano: v1.0
 ******************************************************************************************************************/
PROCEDURE GetCajaSucursalGeneral(p_fechadesde IN DATE,
                                 p_fechahasta IN DATE,
                                 p_cdsucursal IN sucursales.cdsucursal%type,
                                 p_cur_out    OUT cursor_type) IS
  v_Modulo VARCHAR2(100) := 'PKG_REPORTE_CENTRAL.GetCajaSucursalGeneral';
BEGIN

  OPEN p_cur_out FOR

    select total.fecha, nvl(sum(total.diferencia), 0) monto
      from (select inicial.fecha,
                   - (inicial.total_inicial - cierre.total_cierre) diferencia
              from (select trunc(mc.dtmovimiento) fecha,
                           sum(mc.ammovimiento) total_inicial
                      from tblmovcaja mc
                     where mc.cdoperacioncaja = 1
                       and mc.dtmovimiento between trunc(p_fechadesde) and --fecha desde
                           trunc(p_fechahasta) --fecha hasta
                       and mc.cdsucursal = p_cdsucursal --sucursal
                     group by trunc(mc.dtmovimiento)) inicial, -- calculo el inicial
                   (select trunc(mc.dtmovimiento) fecha,
                           sum(mc.ammovimiento) total_cierre
                      from tblmovcaja mc
                     where mc.cdoperacioncaja = 4
                       and mc.dtmovimiento between trunc(p_fechadesde) and --fecha desde
                           trunc(p_fechahasta) --fecha hasta
                       and mc.cdsucursal = p_cdsucursal --Sucursal
                     group by trunc(mc.dtmovimiento)) cierre -- calculo el cierre
             where inicial.fecha = cierre.fecha

            union all

            select inicial.fecha,- (cierre.saldo - inicial.saldo) diferencia
              from (select trunc(t.dtoperacion) fecha,
                           nvl(sum(t.amsaldo), 0) saldo
                      from tbltesoro t
                     where t.sqtesoro =
                           (select max(t.sqtesoro)
                              from tblconfingreso c1,
                                   tblconfingreso c2,
                                   tbltesoro      t
                             where c1.cdconfingreso = '035' --MarianoL 13/11/15: comentado  in ('035', '9035')
                               and c1.icestado = 1
                               and c1.cdsucursal = p_cdsucursal --sucursal
                               and c2.cdmedio = c1.cdmedio
                               and c2.cdtipo = c1.cdtipo
                               and c2.cdforma = c1.cdforma
                               and c2.cdsucursal = c1.cdsucursal
                               and c2.icestado = 1
                               and t.cdconfingreso = c2.cdconfingreso
                               and t.dtoperacion < trunc(p_fechahasta) --fechahasta
                               and t.cdsucursal = c1.cdsucursal)
                       and t.cdsucursal = p_cdsucursal --sucursal
                     group by trunc(t.dtoperacion)) Inicial,

                   (select trunc(t.dtoperacion) fecha,
                           nvl(sum(t.amsaldo), 0) saldo
                      from tbltesoro t
                     where t.sqtesoro =
                           (select max(t.sqtesoro)
                              from tblconfingreso c1,
                                   tblconfingreso c2,
                                   tbltesoro      t
                             where c1.cdconfingreso = '035' --MarianoL 13/11/15: comentado  in ('035', '9035')
                               and c1.icestado = 1
                               and c1.cdsucursal = p_cdsucursal --sucursal
                               and c2.cdmedio = c1.cdmedio
                               and c2.cdtipo = c1.cdtipo
                               and c2.cdforma = c1.cdforma
                               and c2.cdsucursal = c1.cdsucursal
                               and c2.icestado = 1
                               and t.cdconfingreso = c2.cdconfingreso
                               and t.dtoperacion < trunc(p_fechadesde) --fechadesde
                               and t.cdsucursal = c1.cdsucursal)
                       and t.cdsucursal = p_cdsucursal --sucursal
                     group by trunc(t.dtoperacion)) cierre) total
     group by total.fecha;

EXCEPTION
  WHEN OTHERS THEN
    n_pkg_vitalpos_log_general.write(2,
                                     'Modulo: ' || v_Modulo || ' Error: ' ||
                                     SQLERRM);
    RAISE;
END GetCajaSucursalGeneral;

/****************************************************************************************
* Retorna si el cliente tiene terminales posnet de baja
* 09/11/2017
* %v 05/02/2018 - APW - Corrijo error en busqueda de terminales en null
* %v 02/03/2018 - Iaquilano - Se corrije si es PB que devuelva activa sin hacer mas averiguaciones
* %v 05/03/2018 - LM- se verifica primero que el estado de la configuracion en gestion establecimientos.
/****************************************************************************************/
FUNCTION EsBajaPB(p_idcuenta tblcuenta.idcuenta%TYPE) RETURN varchar2 IS
   v_count    INTEGER;
   v_baja     INTEGER;
   v_estados  INTEGER;
   v_terminal INTEGER;
   v_terminalEsp INTEGER;
   v_tipocuenta tblcuenta.cdtipocuenta%type;
   v_idcuentapadre tblcuenta.idcuenta%type;
   v_idcuenta   tblcuenta.idcuenta%type;
BEGIN
   --Busca el tipo cuenta
   select c.cdtipocuenta, c.idpadre
   into v_tipocuenta, v_idcuentapadre
   from tblcuenta c
   where c.idcuenta = p_idcuenta;

   --Asigna la cuenta padre en todos los casos
   If v_tipocuenta='2' then
     v_idcuenta:= v_idcuentapadre;
   else
     v_idcuenta:= p_idcuenta;
   end if;

 --Mira si tiene estados
   --Bloqueada 2 /Rechazada 3 /Baja 4
   select count(*)
     into v_estados
     from tblgsterminal        t,
          tblgsestablecimiento e
    where  t.idgsestablecimiento = e.idgsestablecimiento
      and t.cdestado in ('2','3','4')
      and e.idcuenta =v_idcuenta;

   --Mira si tiene baja
   select nvl(count(distinct t.vlterminal), 0)
     into v_baja
     from tblgsterminal        t,
          tblgsestablecimiento e,
          tblcuenta            c,
          tblestablecimiento   es,
          entidades            en
    where t.dtbaja is not null
      and t.idgsestablecimiento = e.idgsestablecimiento
      and e.idcuenta = c.idcuenta
      and c.idcuenta = es.idcuenta
      and c.idcuenta =v_idcuenta
      and c.identidad = en.identidad;

   --Sin esta en estado bloqueado o con fecha baja
   If v_baja <> 0 or v_estados <> 0 then
     Return 'Baja';
   end if;

   --Comercios configurados
   select count(*)
   into v_count
   from tblestablecimiento e
   where e.idcuenta = v_idcuenta;

   --Si esta vacio mira especiales
   if  v_count = 0 then
     --Especiales
     select count(*)
     into v_count
     from tblclientespecial ce, tblestablecimientomaycar em
     where ce.idestablecimientomaycar=em.idestablecimientomaycar
     and ce.idcuenta = v_idcuenta;
   end if;

   --Sin tiene ninguno sale
   If v_count = 0 then
     Return 'No Configurado';
   end if;

   -- si es PB no necesita validar terminal
   if pkg_establecimientocuenta.GetFormaOperacion(p_idcuenta)='4' then
     RETURN 'Activa';
   end if;

   --Mira si tiene terminal
   select count(*)
   into v_terminal
   from tblestablecimiento e
   where e.idcuenta = v_idcuenta
   --and pkg_establecimientocuenta.GetFormaOperacion(p_idcuenta)='5' --CL
   and (e.vlterminal is not null and  e.vlterminal <>'0');

   --Especiales
   select count(*)
   into v_terminalEsp
   from tblclientespecial ce, tblestablecimientomaycar em
   where ce.idestablecimientomaycar=em.idestablecimientomaycar
   and ce.idcuenta = v_idcuenta
   --and pkg_establecimientocuenta.GetFormaOperacion(p_idcuenta)='5' --CL
   and (ce.vlterminal is not null and ce.vlterminal <> '0');

   --Sin tiene ninguno sale
   If v_terminal = 0 and v_terminalEsp=0 then
     Return 'Sin Terminal';
   end if;

   RETURN 'Activa';

EXCEPTION
   WHEN OTHERS THEN
     RETURN 0;
END EsBajaPB;

/****************************************************************************************
* Retorna si el cliente tiene terminales posnet de baja
* %v 28/03/2018. LM. se crea una nueva funcion con nueva logica para mostrar la baja de terminales
/****************************************************************************************/
FUNCTION EsBajaPBN(p_idcuenta tblcuenta.idcuenta%TYPE) RETURN varchar2 IS
   v_count    INTEGER;

   v_estados  INTEGER;
   v_terminal INTEGER;
   v_terminalEsp INTEGER;
   v_tipocuenta tblcuenta.cdtipocuenta%type;
   v_idcuentapadre tblcuenta.idcuenta%type;
   v_idcuenta   tblcuenta.idcuenta%type;
   v_estadoTemp varchar2(100);
BEGIN
   --Busca el tipo cuenta
   select c.cdtipocuenta, c.idpadre
   into v_tipocuenta, v_idcuentapadre
   from tblcuenta c
   where c.idcuenta = p_idcuenta;

   --Asigna la cuenta padre en todos los casos
   If v_tipocuenta='2' then
     v_idcuenta:= v_idcuentapadre;
   else
     v_idcuenta:= p_idcuenta;
   end if;

--***1. Primero verifica que tenga comercios configurados
   --Comercios configurados
   select count(*)
   into v_count
   from tblestablecimiento e
   where e.idcuenta = v_idcuenta;

   --Si esta vacio mira especiales
   if  v_count = 0 then
     --Especiales
     select count(*)
     into v_count
     from tblclientespecial ce, tblestablecimientomaycar em
     where ce.idestablecimientomaycar=em.idestablecimientomaycar
     and ce.idcuenta = v_idcuenta;
   end if;

   --Sin tiene ninguno sale
   If v_count = 0 then
     Return 'No Configurado';
   end if;

--***2. Verifica si es PB
   if pkg_establecimientocuenta.GetFormaOperacion(p_idcuenta)='4' then
       v_estadoTemp:='Activo';
       --Mira si tiene terminal
       select count(*)
       into v_terminal
       from tblestablecimiento e
       where e.idcuenta = v_idcuenta
       and (e.vlterminal is not null and  e.vlterminal <>'0');

       --Especiales
       select count(*)
       into v_terminalEsp
       from tblclientespecial ce, tblestablecimientomaycar em
       where ce.idestablecimientomaycar=em.idestablecimientomaycar
       and ce.idcuenta = v_idcuenta
       and (ce.vlterminal is not null and ce.vlterminal <> '0');

       --Si no tiene terminales cargadas, define que esta activo (Por ser PB)
       If v_terminal = 0 and v_terminalEsp=0 then
         Return 'Activo';
       end if;
       --si tiene terminales cargadas (no salio por el return)recorre las terminales cargadas, si no estan dadas de baja en gestion establecimiento
       v_estadoTemp:='Baja';
       for r_terminales in (  select e.idestablecimiento, e.idcuenta, e.vlterminal
                              from tblestablecimiento e
                              where e.idcuenta = v_idcuenta
                              and e.vlterminal is not null and  e.vlterminal <>'0'
                            )
       loop
         --Mira si tiene estados Baja o tiene fecha baja distinta de null
          select count(*)
           into v_estados
           from tblgsterminal        t,
                tblgsestablecimiento e
          where  t.idgsestablecimiento = e.idgsestablecimiento
            and (t.cdestado in ('4') or t.dtbaja is not null)
            and t.vlterminal=r_terminales.vlterminal
            and e.idcuenta =v_idcuenta;
           if v_estados>0 then
                 v_estadoTemp:='Baja';
           else
             return 'Activo';
           end if;
       end loop;
       --si tiene terminales especiales cargadas (no salio por el return)recorre las terminales cargadas, si no estan dadas de baja en gestion establecimiento
       for r_terminales in (  --Especiales
                               select ce.idestablecimientomaycar, ce.vlterminal,ce.idcuenta
                               from tblclientespecial ce, tblestablecimientomaycar em
                               where ce.idestablecimientomaycar=em.idestablecimientomaycar
                               and ce.idcuenta = v_idcuenta
                               and (ce.vlterminal is not null and ce.vlterminal <> '0')
                            )
       loop
         --Mira si tiene estados Baja o tiene fecha baja distinta de null
          select count(*)
           into v_estados
           from tblgsterminal        t,
                tblgsestablecimiento e
          where  t.idgsestablecimiento = e.idgsestablecimiento
            and (t.cdestado in ('4') or t.dtbaja is not null)
            and t.vlterminal=r_terminales.vlterminal
            and e.idcuenta =v_idcuenta;
           if v_estados>0 then
               v_estadoTemp:='Baja';
           else
             return 'Activo';
           end if;
       end loop;
     RETURN v_estadoTemp;

   else --es CL
        --Mira si tiene terminal
     select count(*)
     into v_terminal
     from tblestablecimiento e
     where e.idcuenta = v_idcuenta
     and (e.vlterminal is not null and  e.vlterminal <>'0');

     --Especiales
     select count(*)
     into v_terminalEsp
     from tblclientespecial ce, tblestablecimientomaycar em
     where ce.idestablecimientomaycar=em.idestablecimientomaycar
     and ce.idcuenta = v_idcuenta
     and (ce.vlterminal is not null and ce.vlterminal <> '0');

     --Sin tiene ninguno sale
     If v_terminal = 0 and v_terminalEsp=0 then
       Return 'Sin Terminal';
     end if;

      --si tiene terminales cargadas (no salio por el return)recorre las terminales cargadas, si no estan dadas de baja en gestion establecimiento
       v_estadoTemp:='Baja';
       for r_terminales in (  select e.idestablecimiento, e.idcuenta, e.vlterminal
                              from tblestablecimiento e
                              where e.idcuenta = v_idcuenta
                              and e.vlterminal is not null and  e.vlterminal <>'0'
                            )
       loop
         --Mira si tiene estados Baja o tiene fecha baja distinta de null
          select count(*)
           into v_estados
           from tblgsterminal        t,
                tblgsestablecimiento e
          where  t.idgsestablecimiento = e.idgsestablecimiento
            and (t.cdestado in ('4') or t.dtbaja is not null)
            and t.vlterminal=r_terminales.vlterminal
            and e.idcuenta =v_idcuenta;
           if v_estados>0 then
                 v_estadoTemp:='Baja';
           else
             return 'Activo';
           end if;
       end loop;
       --si tiene terminales especiales cargadas (no salio por el return)recorre las terminales cargadas, si no estan dadas de baja en gestion establecimiento
       for r_terminales in (  --Especiales
                               select ce.idestablecimientomaycar, ce.vlterminal,ce.idcuenta
                               from tblclientespecial ce, tblestablecimientomaycar em
                               where ce.idestablecimientomaycar=em.idestablecimientomaycar
                               and ce.idcuenta = v_idcuenta
                               and (ce.vlterminal is not null and ce.vlterminal <> '0')
                            )
       loop
         --Mira si tiene estados Baja o tiene fecha baja distinta de null
          select count(*)
           into v_estados
           from tblgsterminal        t,
                tblgsestablecimiento e
          where  t.idgsestablecimiento = e.idgsestablecimiento
            and (t.cdestado in ('4') or t.dtbaja is not null)
            and t.vlterminal=r_terminales.vlterminal
            and e.idcuenta =v_idcuenta;
           if v_estados>0 then
               v_estadoTemp:='Baja';
           else
             return 'Activo';
           end if;
       end loop;
     RETURN v_estadoTemp;

   end if;
EXCEPTION
   WHEN OTHERS THEN
     RETURN 0;
END EsBajaPBN;


  /*****************************************************************************************************************
 * Retorna datos de tarjetas para conciliacion comercio propio en formato texto plano separado por ;
 * %v 24/11/2017 - JB
 * %v 15/12/2017 - LM. se corrige la duplicidad por las sucursales
  * %v 15/12/2017 - LM - se corrige un JOIN de AND EM.Cdtipo=ci.cdtipo
 ******************************************************************************************************************/
 PROCEDURE GetArchivoConciliacionCP (p_fecha   IN  DATE,
                                  p_cur_out OUT cursor_type)
IS
      v_Modulo         VARCHAR2(100) := 'PKG_REPORTE_CENTRAL.GetArchivoConciliacionCP';
 BEGIN
    OPEN p_cur_out FOR
      select sub.linea
      from
      --titulo del campo
      (SELECT 'FECHA' || ';' || 'HORA' || ';' || 'INGRESO' || ';' || 'TIPO' || ';' ||
             'MEDIO' || ';' || 'NROTJA' || ';' || 'CUOTAS' || ';' || 'MONTO' || ';' ||
             'SUCURSAL' || ';' || 'TERMINAL' || ';' || 'LOTE' || ';' || 'CUPON' || ';' ||
             'EMISOR' || ';' || 'ORIGEN' as linea, -1 orden
        from dual
      union
      SELECT TO_CHAR(II.DTINGRESO, 'DD/MM/YYYY') || ';' ||
             TO_CHAR(ii.dtingreso, 'HH24:MI:SS') || ';' ||
             PKG_INGRESO_CENTRAL.GETDESCINGRESO(II.CDCONFINGRESO, II.CDSUCURSAL) || ';' ||
             PKG_INGRESO_CENTRAL.GETDESCTIPO(II.CDCONFINGRESO, II.CDSUCURSAL) || ';' ||
             PKG_INGRESO_CENTRAL.GETDESCMEDIO(II.CDCONFINGRESO, II.CDSUCURSAL) || ';' ||
             TA.NROTARJETA || ';' || TA.PLANCUOTAS || ';' || II.AMINGRESO || ';' ||
             II.CDSUCURSAL || ';' || TA.VLTERMINAL || ';' || TA.NROLOTE || ';' ||
             TA.DSNROCUPON || ';' || TA.EMISORTARJETA || ';' ||
             DECODE(TA.EMISORTARJETA, NULL, 'M', 'A') as linea, rownum orden
        FROM TBLTARJETA TA, TBLINGRESO II, tblconfingreso ci
       WHERE TA.IDINGRESO = II.IDINGRESO
         AND II.CDESTADO NOT IN ('4', '5')
         and ii.cdconfingreso = ci.cdconfingreso
         and ci.cdaccion = '1' -- solo ingreso
         AND CI.CDSUCURSAL = II.CDSUCURSAL
         AND II.DTINGRESO > p_fecha - 1
      UNION
      --Comercio Propio
      SELECT DISTINCT TO_CHAR(II.DTINGRESO, 'DD/MM/YYYY') || ';' ||
                      TO_CHAR(II.DTINGRESO, 'HH24:MI:SS') || ';' ||
                      PKG_INGRESO_CENTRAL.GETDESCINGRESO(II.CDCONFINGRESO,
                                                         II.CDSUCURSAL) || ';' ||
                      PKG_INGRESO_CENTRAL.GETDESCTIPO(II.CDCONFINGRESO,
                                                      II.CDSUCURSAL) || ';' ||
                      PKG_INGRESO_CENTRAL.GETDESCMEDIO(II.CDCONFINGRESO,
                                                       II.CDSUCURSAL) || ';' || '' || ';' || '' || ';' ||
                      II.AMINGRESO || ';' || II.CDSUCURSAL || ';' || C.VLTERMINAL || ';' ||
                      TO_CHAR(C.VLCIERRELOTE) || ';' || '' || ';' ||
                      CI.DSTERMINALPOSNET || ';' || 'CL' as linea, rownum orden
        FROM TBLCIERRELOTE            C,
             TBLCLIENTESPECIAL        CE,
             TBLESTABLECIMIENTOMAYCAR EM,
             TBLINGRESO               II,
             TBLCONFINGRESO           CI,
             TBLFORMAINGRESO          FI
       WHERE C.VLESTABLECIMIENTO = EM.VLESTABLECIMIENTOMAYCAR
         AND EM.IDESTABLECIMIENTOMAYCAR = CE.IDESTABLECIMIENTOMAYCAR
         AND CE.IDCUENTA = II.IDCUENTA
         AND C.IDINGRESO = II.IDINGRESO
         AND CI.CDCONFINGRESO = II.CDCONFINGRESO
         AND CI.CDSUCURSAL = II.CDSUCURSAL
         AND EM.CDFORMA = CI.CDFORMA
         AND FI.CDFORMA = EM.CDFORMA
         AND EM.Cdtipo=ci.cdtipo
         AND II.CDESTADO NOT IN ('4', '5')
         and ci.cdaccion = '1' -- solo ingreso
         AND II.DTINGRESO > p_fecha - 1) sub
         order by orden asc;

 EXCEPTION
    WHEN OTHERS THEN
       n_pkg_vitalpos_log_general.write(2, 'Modulo: ' || v_Modulo || ' Error: ' || SQLERRM);
       RAISE;
 END GetArchivoConciliacionCP;

 /*****************************************************************************************************************
 * Nuevo reporte Deudores agrupado por canal, sucursal y cliente.
 * %v 06/02/2018 - IAquilano
 * %v 05/03/2018 - IAquilano - Agrego condiciones en el filtro.
 * %v 07/03/2018 - LM - cambio el filtro de fechas, se quita el filtro del estado del documento, se incluyen los documentos en gestion
 ******************************************************************************************************************/
Procedure GetReporteDeudoresCreditos(p_fecha   IN Date,
                                     p_cur_out OUT cursor_type) IS
  v_Modulo VARCHAR2(100) := 'PKG_REPORTE_CENTRAL.GetReporteDeudoresCreditos';

Begin
  open p_cur_out for
    select tdc.id_canal,
           tdc.dssucursal,
           nvl(tdc.cdcuit, '.') cdcuit,
           tdc.dsrazonsocial,
           tdc.nombrecuenta,
           nvl(tdc.venta, 0) venta,
           nvl(tdc.moroso, 0) moroso,
           nvl(tdc.gestion, 0) gestion,
           Dias_Deuda,
           fecha_inicio_deuda
      from (select mm.id_canal,
                   s.dssucursal,
                   e.cdcuit,
                   e.dsrazonsocial,
                   tc.nombrecuenta,
                   sum(case
                         when td.cdestado = 1 then
                          (Select (nvl(pkg_documento_central.GetDeudaDocumento(d.iddoctrx,
                                                                                  p_fecha),
                                          0)) --parametro de fecha
                             from documentos d
                            where d.iddoctrx = td.iddoctrx
                            group by d.iddoctrx)
                       end) as venta,

                   sum(case
                         when td.cdestado = 2 then
                          (Select (nvl(pkg_documento_central.GetDeudaDocumento(d.iddoctrx,
                                                                                  p_fecha),
                                          0)) --parametro de fecha
                             from documentos d
                            where d.iddoctrx = td.iddoctrx
                            group by d.iddoctrx)
                       end) as moroso,

                   sum(case
                         when td.cdestado = 3 then
                          (Select (nvl(pkg_documento_central.GetDeudaDocumento(d.iddoctrx,
                                                                                  p_fecha),
                                          0)) --parametro de fecha
                             from documentos d
                            where d.iddoctrx = td.iddoctrx
                            group by d.iddoctrx)
                       end) as gestion,
                   trunc(to_date(p_fecha, 'DD/MM/YYYY')) -
                   trunc(to_date(min(tdd.dtestadoinicio),
                                 'DD/MM/YYYY')) as Dias_Deuda,
                   min(trunc(tdd.dtestadoinicio)) fecha_inicio_deuda

              from    (select ddd.iddoctrx, max(ddd.dtestadoinicio)dtestadoinicio, max(ddd.cdestado)cdestado, ddd.cdsucursal  from tbldocumentodeuda ddd
                   where
                   p_fecha between --poner parametro fecha simple
                   trunc(ddd.dtestadoinicio) and
                   nvl(trunc(ddd.dtestadofin), p_fecha)
                   group by ddd.iddoctrx, ddd.cdsucursal
                   )td,
                   documentos d,
                   entidades e,
                   tblcuenta tc,
                   sucursales s,
                   movmateriales mm,
                   (select ddd.iddoctrx,
                           min(ddd.dtestadoinicio) dtestadoinicio,
                           ddd.cdsucursal
                      from tbldocumentodeuda ddd
                     group by ddd.iddoctrx, ddd.cdsucursal) tdd
             where /*p_fecha between --poner parametro fecha simple
                   trunc(td.dtestadoinicio) and
                   nvl(trunc(td.dtestadofin), p_fecha) --poner parametro fecha simple
               and*/ td.iddoctrx = d.iddoctrx
               and d.identidadreal = e.identidad
               and d.idcuenta = tc.idcuenta
               and d.cdsucursal = s.cdsucursal
               and d.idmovmateriales = mm.idmovmateriales
               and td.iddoctrx = tdd.iddoctrx
               and mm.id_canal <> 'CO'
               AND mm.id_canal in ('SA', 'VE', 'TE')
               and td.cdestado not in (/*3,*/ 5) --Judicial e Incobrable
               AND (d.cdcomprobante LIKE ('FC%') OR
                   d.cdcomprobante LIKE ('NC%') OR
                   d.cdcomprobante LIKE ('ND%'))
              -- AND d.cdestadocomprobante IN ('1', '2', '4')
               and e.identidad not in (select re.identidad from rolesentidades re where re.cdrol = '1')
            --    and e.cdcuit='20-95243439-0  '
            --and e.cdcuit = '20-05316353-0'--posible parametro de cuit o identidad
             group by mm.id_canal,
                      s.dssucursal,
                      e.cdcuit,
                      e.dsrazonsocial,
                      tc.nombrecuenta) tdc
     where nvl(tdc.venta, 0) > 0
        or nvl(tdc.moroso, 0) > 0
        or nvl(tdc.gestion, 0) > 0
     order by id_canal, dssucursal, cdcuit;

EXCEPTION
  WHEN OTHERS THEN
    n_pkg_vitalpos_log_general.write(2,
                                     'Modulo: ' || v_Modulo || ' Error: ' ||
                                     SQLERRM);
    RAISE;

End GetReporteDeudoresCreditos;

/****************************************************************************************
* Dada una guia retorna el nombre y apellido del vendedor que tomo los pedidos
* %v 28/02/2018 - JB
/****************************************************************************************/
FUNCTION VendedorPorGuia(p_idguiadetransporte guiasdetransporte.idguiadetransporte%TYPE)
  RETURN varchar2 IS

  v_vendedor varchar2(150);
BEGIN

  select pe.dsnombre || ' ' || pe.dsapellido vendedor
    into v_vendedor
    from guiasdetransporte gt,
         tbldetalleguia    dtg,
         documentos        f,
         movmateriales     m,
         pedidos           p,
         personas          pe
   where gt.idguiadetransporte = p_idguiadetransporte
     and gt.idguiadetransporte = dtg.idguiadetransporte
     and dtg.iddoctrx = f.iddoctrx
     and f.idmovmateriales = m.idmovmateriales
     and m.idpedido = p.idpedido
     and p.idpersonaresponsable = pe.idpersona
     and rownum = 1;

   return v_vendedor;

EXCEPTION
  WHEN OTHERS THEN
    RETURN null;
END VendedorPorGuia;

/**************************************************************************************************
* Retorna las cuentas liberadas y el origen de la liberacion
* %v 07/03/2018 - JB
* %v 12/06/2018 - IAquilano: Agrego filtro para que no vea las liberaciones automaticas
***************************************************************************************************/
PROCEDURE GetLiberacionCuenta(p_sucursales IN VARCHAR2,
                              p_fechadesde in date,
                              p_fechahasta in date,
                              p_cur_out    OUT cursor_type) IS

  v_modulo    varchar2(100) := 'PKG_REPORTE_CENTRAL.GetLiberacionCuenta';
  v_idReporte VARCHAR2(40) := '';
BEGIN
  v_idReporte := PKG_REPORTE_CENTRAL.SetSucursalesSeleccionadas(p_sucursales);

  open p_cur_out for
   select distinct e.dsrazonsocial,
          e.cdcuit,
          c.nombrecuenta,
          s.dssucursal,
          lc.dtestado,
          decode(lc.iccaja, 1, 'Caja', 0, 'Autogestion') Origen
     from tblcuenta                 c,
          entidades                 e,
          tblliberacioncuenta       lc,
          sucursales                s,
          tbltmp_sucursales_reporte rs
    where c.identidad = e.identidad
      and lc.idcuenta = c.idcuenta
      and rs.cdsucursal = s.cdsucursal
      AND rs.idreporte = v_idReporte
      AND c.cdsucursal = rs.cdsucursal
      and lc.iccaja <> 2
      and to_char(c.dtalta,'ddmmyyyy hh24:mi') <> to_char(lc.dtbloqueo,'ddmmyyyy hh24:mi') --No muestra el primer registro de alta de cuenta
      and lc.dtestado between trunc(p_fechaDesde) AND trunc(p_fechaHasta + 1);

  PKG_REPORTE_CENTRAL.CleanSucursalesSeleccionadas(v_idReporte);

EXCEPTION
  WHEN OTHERS THEN
    n_pkg_vitalpos_log_general.write(2,
                                     'Modulo: ' || v_modulo || '  Error: ' ||
                                     SQLERRM);
    raise;
End GetLiberacionCuenta;

/**************************************************************************************************
* Retorna Cursor con todos los clientes con creditos (monto inicial y actual)
* %v 09/03/2018 - IAquilano
***************************************************************************************************/
PROCEDURE GetClientesconCredito(p_identidad  IN entidades.identidad%type,
                                p_cdsucursal IN sucursales.cdsucursal%type,
                                p_cur_out    OUT cursor_type) IS

  v_modulo varchar2(100) := 'PKG_REPORTE_CENTRAL.GetClientesconCredito';

BEGIN

  open p_cur_out for
    select t.dssucursal,
           t.cdcuit,
           t.dsrazonsocial,
           t.nombrecuenta,
           t.fecha_ini,
           t.Otorgado_Ini,
           t.Ultima_modif,
           t.Ultimo_otorgado
      from (select s.dssucursal,
                   e.cdcuit,
                   e.dsrazonsocial,
                   c.nombrecuenta,
                   fechamin.fecha Fecha_Ini,--fecha del monto inicial
                   (select distinct amotorgado
                      from tbllogcuenta tl
                     where tl.dtlog = fechamin.fecha
                       and tl.idcuenta = fechamin.idcuenta
                       and tl.idpersona is null) Otorgado_Ini,--monto inicial
                   fechamax.fecha Ultima_Modif,--fecha del monto actual
                   (select distinct amotorgado
                      from tbllogcuenta tl
                     where tl.dtlog = fechamax.fecha
                       and tl.idcuenta = fechamax.idcuenta
                       and tl.amotorgado is not null
                       and tl.idpersona is not null) Ultimo_otorgado--monto actual
              from (select tl.idcuenta, min(tl.dtlog) fecha
                      from tbllogcuenta tl
                     where tl.idpersona is null
                     group by tl.idcuenta) fechamin,--tabla con las fechas iniciales
                   (select tl.idcuenta, max(tl.dtlog) fecha
                      from tbllogcuenta tl
                     where tl.idpersona is not null
                       and tl.amotorgado is not null
                     group by tl.idcuenta) fechamax,--tabla con las ultimas fechas con monto
                   tblcuenta c,
                   entidades e,
                   sucursales s
             where fechamin.idcuenta = c.idcuenta
               and fechamax.idcuenta = c.idcuenta
               and c.identidad = e.identidad
               and c.cdsucursal = s.cdsucursal
               and e.identidad = NVL(p_identidad, c.identidad)--identidad
               and s.cdsucursal = NVL(p_cdSucursal, c.cdsucursal)) t--sucursal
     where t.otorgado_ini <> 0
        or t.ultimo_otorgado <> 0;

EXCEPTION
  WHEN OTHERS THEN
    n_pkg_vitalpos_log_general.write(2,
                                     'Modulo: ' || v_modulo || '  Error: ' ||
                                     SQLERRM);

End GetClientesconCredito;

/**************************************************************************************************
* Retorna Cursor con auditoria de cambios crediticios
* %v 16/03/2018 - IAquilano
***************************************************************************************************/
PROCEDURE AuditoriaCreditos(p_idpersona  IN personas.idpersona%type,
                            p_identidad  IN entidades.identidad%type,
                            p_fechadesde IN date,
                            p_fechahasta IN date,
                            p_cur_out    OUT cursor_type) IS

  v_modulo varchar2(100) := 'PKG_REPORTE_CENTRAL.AuditoriaCreditos';

BEGIN

  open p_cur_out for

    select tabla.persona Persona,
           tabla.dssucursal Sucursal,
           tabla.cdcuit Cuit,
           tabla.dsrazonsocial Razon_Social,
           tabla.nombrecuenta Cuenta,
           nvl(TO_CHAR(tabla.amotorgado), '-') Otorgado,
           nvl(TO_CHAR(tabla.amampliacion), '-') Sobregiro,
           nvl(TO_CHAR(tabla.amampliacionextra), '-') Sobregiro_Extra,
           tabla.dtlog Fecha
      from (select distinct p.dsapellido || ',' || p.dsnombre Persona,
                            s.dssucursal,
                            e.cdcuit,
                            e.dsrazonsocial,
                            c.nombrecuenta,
                            tlc.amotorgado,
                            tlc.amampliacion,
                            tlc.amampliacionextra,
                            tlc.dtlog
              from personas     p,
                   tblcuenta    c,
                   entidades    e,
                   tbllogcuenta tlc,
                   sucursales   s
             where tlc.idpersona = NVL(p_idpersona, p.idpersona) --p_idpersona
               and tlc.idpersona = p.idpersona
               and tlc.idcuenta = c.idcuenta
               and c.identidad = e.identidad
               and e.identidad = NVL(p_identidad, c.identidad) --p_identidad
               and c.cdsucursal = s.cdsucursal
               and tlc.dtlog between nvl(p_fechadesde, tlc.dtlog) and nvl(p_fechahasta, tlc.dtlog) + 1 --p_fechadesde y hasta
             order by e.dsrazonsocial, tlc.dtlog desc) tabla
     where tabla.amotorgado is not null
        or tabla.amampliacion is not null
        or tabla.amampliacionextra is not null
     order by sucursal asc, fecha desc, razon_social, cuenta, persona asc;

EXCEPTION
  WHEN OTHERS THEN
    n_pkg_vitalpos_log_general.write(2,
                                     'Modulo: ' || v_modulo || '  Error: ' ||
                                     SQLERRM);
End AuditoriaCreditos;

/**************************************************************************************************
* Retorna Cursor con auditoria de cambios crediticios
* %v 16/03/2018 - IAquilano
***************************************************************************************************/
PROCEDURE GetVentaACredito(p_identidad  IN entidades.identidad%type,
                           p_fechahasta IN date,
                           p_cdsucursal IN sucursales.cdsucursal%type,
                           p_cur_out    OUT cursor_type) IS

  v_modulo varchar2(100) := 'PKG_REPORTE_CENTRAL.GetVentaACredito';

BEGIN

  open p_cur_out for
  select * from tblventaacredito vc
  where trunc(vc.ultimodiames)=trunc(p_fechahasta)
  and vc.identidad=nvl(p_identidad,vc.identidad)
  and vc.cdsucursal=nvl(p_cdsucursal,vc.cdsucursal)
  order by vc.motivo, vc.sucursal, vc.fechadoc;


EXCEPTION
  WHEN OTHERS THEN
    n_pkg_vitalpos_log_general.write(2,
                                     'Modulo: ' || v_modulo || '  Error: ' ||
                                     SQLERRM);
End GetVentaACredito;

/**************************************************************************************************
* Retorna las facturas de flete
* %v 31/05/2018 - JB
***************************************************************************************************/
PROCEDURE GetFacFlete (p_sucursales IN VARCHAR2,
                       p_identidad  IN entidades.identidad%TYPE,
                       p_fechadesde in date,
                       p_fechahasta in date,
                       p_cur_out    OUT cursor_type) IS

  v_modulo    varchar2(100) := 'PKG_REPORTE_CENTRAL.GetFacFlete';
  v_idReporte VARCHAR2(40) := '';
BEGIN
  v_idReporte := PKG_REPORTE_CENTRAL.SetSucursalesSeleccionadas(p_sucursales);

  open p_cur_out for
  select s.dssucursal,
         e.dsrazonsocial cliente,
         l.dslocalidad||' - '||de.dscalle||' '||de.dsnumero as direccion,
         e.cdcuit,
         t.dsrazonsocial transportista,
         dg.sqcomprobante nroguia,
         dg.amdocumento monto_guia,
         d.amnetodocumento neto_flete,
         d.dtdocumento fecha
    from tbldetalleguia            f,
         documentos                d,
         documentos                dg,
         entidades                 e,
         entidades                 t,
         sucursales                s,
         tbltmp_sucursales_reporte rs,
         guiasdetransporte         gt,
         direccionesentidades      de,
         localidades               l
   where icflete = 1
     and f.iddoctrx = d.iddoctrx
     and d.identidadreal = e.identidad
     and rs.cdsucursal = s.cdsucursal
     and rs.idreporte = v_idReporte
     and d.cdsucursal = rs.cdsucursal
     and gt.idguiadetransporte=f.idguiadetransporte
     and gt.idtransportista = t.identidad
     and e.identidad = nvl(p_identidad,e.identidad)
     and gt.iddoctrx=dg.iddoctrx
     and gt.cdtipodireccion = de.cdtipodireccion
     and gt.sqdireccion =de.sqdireccion
     and de.identidad = e.identidad
     and l.cdlocalidad=de.cdlocalidad
     and d.cdestadocomprobante not in ('3       ', '6      ', '1      ') --Anuldas o no impresas
     and d.dtdocumento between trunc(p_fechaDesde) AND
         trunc(p_fechaHasta + 1);

  PKG_REPORTE_CENTRAL.CleanSucursalesSeleccionadas(v_idReporte);

EXCEPTION
  WHEN OTHERS THEN
    n_pkg_vitalpos_log_general.write(2,
                                     'Modulo: ' || v_modulo || '  Error: ' ||
                                     SQLERRM);
    raise;
End GetFacFlete;

/**************************************************************************************************
* Retorna Cursor con Auditoria de cambios en el recargo CL
* %v 08/06/2018 - IAquilano
***************************************************************************************************/
PROCEDURE GetAuditoriaCL(p_sucursales IN sucursales.cdsucursal%type,
                         p_idpersona  IN personas.idpersona%type,
                         p_identidad  IN entidades.identidad%type,
                         p_fechadesde DATE,
                         p_fechahasta DATE,
                         p_cur_out    OUT cursor_type) IS

  v_modulo varchar2(100) := 'PKG_REPORTE_CENTRAL.GetAuditoriaCL';
  v_idReporte VARCHAR2(40) := '';
BEGIN
  v_idReporte := PKG_REPORTE_CENTRAL.SetSucursalesSeleccionadas(p_sucursales);

  open p_cur_out for
    select suc.dssucursal as Sucursal,
           ta.dtaccion as Fecha,
           p.dsnombre || ', ' || p.dsapellido as Responsable,
           e.dsrazonsocial as Cliente,
           e.cdcuit as Cuit,
           trim(substr(nmproceso, 62, 3)) as Recargo_anterior,
           trim(substr(nmproceso, 69, 3)) as Recargo_Nuevo
      from tblauditoria ta, personas p, entidades e, sucursales suc, tbltmp_sucursales_reporte rs
     where ta.nmproceso like 'PKG_CLIENTE_CENTRAL.ActualizarDatosCliente cambia recargo%'
       and ta.idpersona = p.idpersona
       and ta.idtabla = e.identidad
       and e.cdmainsucursal = suc.cdsucursal
       and ta.idpersona = nvl(p_idpersona, ta.idpersona)
       and e.identidad = nvl(p_identidad, e.identidad)
       and rs.cdsucursal = suc.cdsucursal
       and rs.idreporte = v_idReporte
       and ta.dtaccion between p_fechadesde and p_fechahasta order by ta.dtaccion desc;

     PKG_REPORTE_CENTRAL.CleanSucursalesSeleccionadas(v_idReporte);

EXCEPTION
  WHEN OTHERS THEN
    n_pkg_vitalpos_log_general.write(2,
                                     'Modulo: ' || v_modulo || '  Error: ' ||
                                     SQLERRM);
    raise;
End GetAuditoriaCL;

  /*****************************************************************************************************************
  * Reporte de Auditoria de reimpresiones
  * %v 03/09/2018 - IAquilano
  * %v 06/01/2020 - APW - Agrego fecha de la factura e indicardor de remito o factura
  ******************************************************************************************************************/
  PROCEDURE GetAuditoriaReimpresion(p_sucursales IN VARCHAR2,
                                    p_fechaDesde IN DATE,
                                    p_fechaHasta IN DATE,
                                    p_cur_out    OUT cursor_type) IS

    v_Modulo    VARCHAR2(100) := 'PKG_REPORTE.GetAuditoriaReimpresion';
    v_idReporte VARCHAR2(40) := '';
  BEGIN
    v_idReporte := SetSucursalesSeleccionadas(p_sucursales);

    OPEN p_cur_out for
      select pkg_core_documento.GetDescDocumento(d.iddoctrx) as factura,
             d.amdocumento as monto,
             a.dtauditoria,
             p.dsapellido || ', ' || p.dsnombre persona,
             s.dssucursal,
             trunc(d.dtdocumento) ffactura,
             case
               when d.dtdocumento > i.dtinicio then 'F' -- si fue electrónica se reimprimió factura
               else 'R' -- si es antes de esa fecha, fue remito
             end fac_o_rem
        from auditoria                 a,
             documentos                d,
             personas                  p,
             sucursales                s,
             tbltmp_sucursales_reporte t,
             tbliniciofe               i
       where a.cdmotivo = '120'
         and a.nmtarea = 'menuReeimpresiones'
         and a.iddoctrx = d.iddoctrx
         and a.idpersonaautoriza = p.idpersona
         and a.cdsucursal = s.cdsucursal
         and s.cdsucursal = i.cdsucursal
         and s.cdsucursal = t.cdsucursal
         and t.idreporte = v_idReporte
         and a.dtauditoria between TRUNC(p_fechaDesde) AND
             TRUNC(p_fechaHasta) + 1
       order by a.dtauditoria;

    PKG_REPORTE_CENTRAL.CleanSucursalesSeleccionadas(v_idReporte);
  EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_Modulo || ' Error: ' ||
                                       SQLERRM);
      RAISE;
  END GetAuditoriaReimpresion;

 /*****************************************************************************************************************
 * %v 17/09/2018 - JBodnar: Panel de Control del SLV
 * %v 05/02/2019 - APW: agrego sucursal en el join
 * %v 19/02/2019 - LM: se agregan los pedidos sin consolidar y se agrega el canal
 * %v 27/02/2019 - LM: se agrega el filtro de canal y estados. estado
    	IDESTADO	 DESCRIPCION
      1	         En Curso
      2	         Cerrado
      3	         A Facturar
      4	         Pendiente
      5	         Facturado
      0          Todos
      15         Sin consolidar

 ******************************************************************************************************************/
 PROCEDURE GetPanelSLV(p_cdsucursal       IN  sucursales.cdsucursal%TYPE,
                       p_IdConsolidado    IN  tblslv_consolidado.idconsolidado%TYPE,
                       p_fechaConsolidado IN  DATE,
                       p_canal            IN  VARCHAR2,
                       p_estados          IN  tblslv_consolidado.idestado%type,
                       p_cur_out          OUT cursor_type) IS

   v_modulo VARCHAR2(100) := 'PKG_REPORTE_CENTRAL.GetPanelSLV';

 BEGIN

   OPEN p_cur_out FOR
     SELECT TO_CHAR(cp.idconsolidado_pedido) PedidoNumero,
            cp.idconsolidado ConsolidadoNumero,
            trunc(cp.fecha_pedido) FechaPedido,
            trunc(cp.fecha_entrega) FechaEntrega,
            to_char(trunc(cons.fecha_consolidado), 'dd/mm/yyyy')FechaConsolidado,
            suc.dssucursal Sucursal /* Formato Cliente */,
            '(' || TRIM(ent.cdcuit) || ') ' ||
            NVL(ent.dsrazonsocial, ent.dsnombrefantasia) Cliente,
            est.descripcion Estado , cp.id_canal Canal
       FROM tblslv_consolidado_pedido cp,
            tblslv_consolidado        cons,
            entidades                 ent,
            sucursales                suc,
            tblslv_estado             est
      WHERE cons.idconsolidado = cp.idconsolidado
        and cons.cdsucursal = cp.cdsucursal
        AND suc.cdsucursal = cons.cdsucursal
        AND ent.identidad = cp.identidad
        AND TRIM(cons.cdsucursal) = p_cdsucursal
        AND est.idestado = cp.idestado
        AND (cp.idestado =p_estados or p_estados=0)
        AND   (trim(cp.id_canal)
                    in ( SELECT TRIM(SUBSTR(txt,  --esto es una técnica para transformar un string separado por comas a tabla
                                INSTR (txt, ',', 1, level ) + 1,
                                INSTR (txt, ',', 1, level + 1) - INSTR (txt, ',', 1, level) -1)) AS u
                           FROM (SELECT replace(','||p_canal||',','''','') AS txt FROM dual )
                     CONNECT BY level <= LENGTH(txt)-LENGTH(REPLACE(txt,',',''))-1) /*fin técnica*/  or p_canal is null)
        AND cons.idconsolidado = nvl(p_IdConsolidado, cons.idconsolidado)
        AND trunc(cons.fecha_consolidado) =
            trunc(nvl(p_fechaConsolidado, cons.fecha_consolidado))
    --  order by PedidoNumero
     UNION  --pedidos sin consolidar
      select --distinct decode(p.id_canal,'TE',to_char(d.sqcomprobante),p.transid) PedidoNumero,
      case
                when p.id_canal = 'TE' then
                 to_char(d.sqcomprobante)
                when p.id_canal = 'CO' and p.idpersonaresponsable is not null then
                 to_char(d.sqcomprobante)
                else
                 p.transid
              end as PedidoNumero,
       0 consolidadoNumero,
       p.dtaplicacion fechaPedido,
       p.dtentrega FechaEntrega,
       '---' FechaConsolidado,
       s.dssucursal Sucursal,
       '(' || TRIM(e.cdcuit) || ') ' ||
            NVL(e.dsrazonsocial, e.dsnombrefantasia) Cliente,
       'Sin consolidar' Estado, p.id_canal Canal
      FROM pedidos p,
       documentos d,
       entidades e,
       sucursales s
      WHERE p.dtaplicacion>sysdate-Getvlparametro('ICDiaNoFacturacion','General')
      and p.iddoctrx=d.iddoctrx
      and d.identidadreal=e.identidad
      and d.cdsucursal=s.cdsucursal
      AND TRIM(d.cdsucursal) = p_cdsucursal
      AND (p_estados=15 or p_estados=0)
      AND   (p.id_canal
                    in ( SELECT TRIM(SUBSTR(txt,  --esto es una técnica para transformar un string separado por comas a tabla
                                INSTR (txt, ',', 1, level ) + 1,
                                INSTR (txt, ',', 1, level + 1) - INSTR (txt, ',', 1, level) -1)) AS u
                           FROM (SELECT replace(','||p_canal||',','''','') AS txt FROM dual )
                     CONNECT BY level <= LENGTH(txt)-LENGTH(REPLACE(txt,',',''))-1) /*fin técnica*/  or p_canal is null)
      and p.icestadosistema=2 ;

 EXCEPTION WHEN OTHERS THEN n_pkg_vitalpos_log_general.write(2,
                                                             'Modulo: ' ||
                                                             v_modulo ||
                                                             '  Error: ' ||
                                                             SQLERRM);
 RAISE    ;

 END GetPanelSLV;

  /*****************************************************************************************************************
  * Retorna un reporte de Mercado Pago
  * %v 09/11/2018 - Jbodnar: v1.0
  * %v 16/11/2018 - LM: se modifica la consulta para que no devuelva con joins la cantidad de facturas afectadas con el ingreso
  * %v 21/05/2019 - APW: agrego estado para distinguir los que no contabilizan
  ******************************************************************************************************************/
  PROCEDURE GetMercadoPago(p_sucursales IN VARCHAR2,
                           p_FechaDesde IN DATE,
                           p_FechaHasta IN DATE,
                           p_cdtipo     IN tblconfingreso.cdtipo%TYPE,
                           p_idexterno  IN tblelectronico.idexterno%TYPE,
                           p_cur_out    OUT cursor_type) IS
    v_modulo    VARCHAR2(100) := 'PKG_REPORTE_CENTRAL.GetMercadoPago';
    v_idReporte VARCHAR2(40) := '';
  BEGIN
    v_idReporte := SetSucursalesSeleccionadas(p_sucursales);

    OPEN p_cur_out FOR
      select el.idingreso,
             pkg_ingreso_central.GetDescIngreso(i.cdconfingreso, i.cdsucursal) medio,
             su.dssucursal,
             i.dtingreso,
             el.idexterno Nroperacion,
             i.amingreso AmPago,
             trim(e.cdcuit) cdcuit,
             e.dsrazonsocial,
             nvl(el.cdtipopago,'-') cdtipopago,
              (
             select count(d.iddoctrx) from documentos d, tblcobranza c
             where d.iddoctrx=c.iddoctrx
             and c.idingreso=el.idingreso
             and d.cdestadocomprobante not in ('6       ', '3       ') --Anuladas
             and c.amimputado > 0
             )nroFactura,
             nvl(el.dtpago,i.dtingreso) dtpago,
             mc.cdcaja,
             case when ei.cdestado in ('0','4') then ei.dsestado -- Muestra rechazados o pendientes del offline
                  else 'Aprobado'
             end estado
        from tblingreso                i,
             tblconfingreso            ci,
             tblcuenta                 c,
             entidades                 e,
             tbltipoingreso            ti,
             tblelectronico            el,
             sucursales                su,
             tblmovcaja                mc,
             tblestadoingreso          ei,
             tbltmp_sucursales_reporte rs
       where i.dtingreso BETWEEN trunc(p_fechaDesde) AND trunc(p_fechaHasta + 1)
         and ci.cdconfingreso = i.cdconfingreso
         and i.idcuenta = c.idcuenta
         and c.identidad = e.identidad
         and ti.cdtipo = ci.cdtipo
         and el.idingreso = i.idingreso
         and ti.cdtipo = nvl(p_cdtipo,ti.cdtipo)
         and su.cdsucursal = c.cdsucursal
         and c.cdsucursal = ci.cdsucursal
         and i.idmovcaja=mc.idmovcaja
         and i.cdsucursal=mc.cdsucursal
         and i.cdestado = ei.cdestado
         and ci.cdmedio = '20' --Electronico
         and el.idexterno = nvl(p_idexterno, el.idexterno)
         and su.cdsucursal = rs.cdsucursal
         and rs.idreporte = v_idReporte;

    PKG_REPORTE_CENTRAL.CleanSucursalesSeleccionadas(v_idReporte);

  EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo || '  Error: ' ||
                                       SQLERRM);
      RAISE;
  END GetMercadoPago;

  /*****************************************************************************************************************
  * Retorna las facturas pagadas con MP
  * %v 09/11/2018 - Jbodnar: v1.0
  ******************************************************************************************************************/
  PROCEDURE GetMercadoPagoDet (p_idingreso  IN tblelectronico.idingreso%TYPE,
                               p_cur_out    OUT cursor_type) IS
    v_modulo    VARCHAR2(100) := 'PKG_REPORTE_CENTRAL.GetMercadoPagoDet';
  BEGIN

    OPEN p_cur_out FOR
      select pkg_documento_central.GetDescDocumento(d.iddoctrx) factura, c.nombrecuenta, d.amdocumento
        from tblcobranza               co,
             documentos                d,
             tblcuenta                 c
       where co.iddoctrx = d.iddoctrx
       and d.idcuenta = c.idcuenta
       and co.idingreso = p_idingreso;

  EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo || '  Error: ' ||
                                       SQLERRM);
      RAISE;
  END GetMercadoPagoDet;


 /*****************************************************************************************************************
  * Retorna un reporte de Monto Tope de Carga Comi
  * %v 14/03/2019 - LM: v1.0
  ******************************************************************************************************************/
  PROCEDURE GetMontoTopeCargaComi(p_sucursales IN VARCHAR2,
                                  p_cur_out    OUT cursor_type) IS
    v_modulo    VARCHAR2(100) := 'PKG_REPORTE_CENTRAL.GetMontoTopeCargaComi';
    v_idReporte VARCHAR2(40) := '';
  BEGIN
    v_idReporte := SetSucursalesSeleccionadas(p_sucursales);

    OPEN p_cur_out FOR
      select d.*, case when d.tope_carga<d.PromedioCarga then 'Tope Superado' else 'Carga Bajo el Tope' end Alerta
        from (
        select e.cdcuit, e.dsrazonsocial,
          ti.amgarantiadolar Garantia_dolar,
          ti.dthastagarantia Vencimiento_garantia,
          ti.amtopecarga Tope_Carga,
          suc.dssucursal sucursal,
          decode(ti.iclunes,0,'-','Si') iclunes,
          decode(ti.icmartes,0,'-','Si') icmartes,
          decode(ti.icmiercoles,0,'-','Si')icmiercoles,
          decode(ti.icjueves,0,'-','Si') icjueves,
          decode(ti.icviernes,0,'-','Si') icviernes,
          decode(ti.icsabado,0,'-','Si') icsabado,
          decode(ti.vlfrecuencia,'S','Semanal','Quincenal') vlfrecuencia ,
          (
            select nvl(round(avg(d.amdocumento),2), 0)
            from guiasdetransporte gt, documentos d
            where gt.identidad = ti.idcomisionista
            and gt.iddoctrx = d.iddoctrx
            and d.cdcomprobante = 'GUIA'
            and d.dtdocumento between sysdate - 30 and sysdate
          ) PromedioCarga
        from TBLINFOCOMISIONISTA ti, entidades e, sucursales suc,tbltmp_sucursales_reporte rs
        where ti.idcomisionista=e.identidad
        and ti.cdsucursal=suc.cdsucursal
        and ti.cdsucursal=rs.cdsucursal
        and rs.idreporte = v_idReporte) d
        order by d.sucursal  ;

    PKG_REPORTE_CENTRAL.CleanSucursalesSeleccionadas(v_idReporte);

  EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo || '  Error: ' ||
                                       SQLERRM);
      RAISE;
  END GetMontoTopeCargaComi;



 /*****************************************************************************************************************
  * Retorna un reporte de los establecimientos y terminales cargadas
  * %v 29/03/2019 - LM: v1.0
  ******************************************************************************************************************/
  PROCEDURE GetEstablecTerm(   p_sucursales   IN            VARCHAR2,
                               p_cdforma      IN tblformaingreso.cdforma%TYPE,
                               p_cur_out      OUT           cursor_type) IS
    v_modulo    VARCHAR2(100) := 'PKG_REPORTE_CENTRAL.GetEstablecTerm';
    v_idReporte VARCHAR2(40) := '';
  BEGIN
    v_idReporte := SetSucursalesSeleccionadas(p_sucursales);
    if p_cdforma is not null then
        If p_cdforma = '2' then
            OPEN p_cur_out FOR
             select distinct e.cdcuit, e.dsrazonsocial, s.dssucursal, c.nombrecuenta , es.VLESTABLECIMIENTOMAYCAR establecimiento,
                    nvl (ce.vlterminal,0) vlterminal, ti.dstipo,decode(e.cdforma, 4, 'P.B.', 5, 'C.L.',2,'CE') dsforma, nvl(e.vlrecargo,0)vlrecargo
                from tblestablecimientomaycar es, tblclientespecial ce, tblcuenta c, entidades e,
                     tbltipoingreso ti, tblformaingreso f, sucursales s, tbltmp_sucursales_reporte rs
                where e.identidad=c.identidad
                  and c.idcuenta=ce.idcuenta
                  and ti.cdtipo=es.cdtipo
                  and es.cdsucursal=c.cdsucursal
                  and f.cdforma=e.cdforma
                  and es.idestablecimientomaycar=ce.idestablecimientomaycar
                  and c.cdsucursal=s.cdsucursal
                  and s.cdsucursal=rs.cdsucursal
                  and rs.idreporte=v_idReporte
                  order by s.dssucursal, e.dsrazonsocial;
         else
           OPEN p_cur_out FOR
             select distinct e.cdcuit, e.dsrazonsocial, s.dssucursal, c.nombrecuenta , es.vlestablecimiento  establecimiento,
                    nvl(es.vlterminal,0) vlterminal, ti.dstipo,f.dsforma, nvl(e.vlrecargo,0)vlrecargo
                from tblestablecimiento es, tblcuenta c, entidades e, tbltipoingreso ti,
                     tblformaingreso f, sucursales s, tbltmp_sucursales_reporte rs
                where e.identidad=c.identidad
                  and c.idcuenta=es.idcuenta
                  and ti.cdtipo=es.cdtipo
                  and f.cdforma=e.cdforma
                  and c.cdsucursal=s.cdsucursal
                  and s.cdsucursal=rs.cdsucursal
                  and rs.idreporte=v_idReporte
                  and e.cdforma=p_cdforma
                  order by s.dssucursal, e.dsrazonsocial;
         end if;
      else
        OPEN p_cur_out FOR
          select * from (
            select distinct e.cdcuit, e.dsrazonsocial, s.dssucursal, c.nombrecuenta , es.vlestablecimiento  establecimiento,
                   nvl(es.vlterminal,0) vlterminal, ti.dstipo,f.dsforma, nvl(e.vlrecargo,0)vlrecargo
                from tblestablecimiento es, tblcuenta c, entidades e, tbltipoingreso ti,
                     tblformaingreso f, sucursales s, tbltmp_sucursales_reporte rs
                where e.identidad=c.identidad
                  and c.idcuenta=es.idcuenta
                  and ti.cdtipo=es.cdtipo
                  and f.cdforma=e.cdforma
                  and c.cdsucursal=s.cdsucursal
                  and s.cdsucursal=rs.cdsucursal
                  and rs.idreporte=v_idReporte
             union
             select distinct e.cdcuit, e.dsrazonsocial, s.dssucursal, c.nombrecuenta , es.VLESTABLECIMIENTOMAYCAR  establecimiento,
                    nvl(ce.vlterminal,0) vlterminal,ti.dstipo,decode(e.cdforma, 4, 'P.B.', 5, 'C.L.',2,'CE') dsforma, nvl(e.vlrecargo,0)vlrecargo
                from tblestablecimientomaycar es, tblclientespecial ce, tblcuenta c,
                     entidades e, tbltipoingreso ti, tblformaingreso f, sucursales s, tbltmp_sucursales_reporte rs
                where e.identidad=c.identidad
                  and c.idcuenta=ce.idcuenta
                  and ti.cdtipo=es.cdtipo
                  and f.cdforma=e.cdforma
                  and es.cdsucursal=c.cdsucursal
                  and es.idestablecimientomaycar=ce.idestablecimientomaycar
                  and c.cdsucursal=s.cdsucursal
                  and s.cdsucursal=rs.cdsucursal
                  and rs.idreporte=v_idReporte )
                  order by dssucursal, dsrazonsocial;
      end if;

    PKG_REPORTE_CENTRAL.CleanSucursalesSeleccionadas(v_idReporte);

  EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo || '  Error: ' ||
                                       SQLERRM);
      RAISE;
  END GetEstablecTerm;

   /*****************************************************************************************************************
   * Retorna un reporte de ingresos agrupado por region y sucursal
   * %v 23/05/2019 - IAquilano: v1.0
   ******************************************************************************************************************/
   PROCEDURE GetIngresosCanalGeneral(p_cdregion   IN tblregion.cdregion%TYPE,
                                     p_sucursales IN VARCHAR2,
                                     p_fechaDesde IN DATE,
                                     p_fechaHasta IN DATE,
                                     p_identidad  IN tblcuenta.identidad%TYPE,
                                     p_idcuenta   IN tblcuenta.idcuenta%TYPE,
                                     p_cur_out    OUT cursor_type) IS
     v_modulo    VARCHAR2(100) := 'PKG_REPORTE_CENTRAL.GetIngresosCanalGeneral';
     v_idReporte VARCHAR2(40) := '';
   BEGIN
     v_idReporte := SetSucursalesSeleccionadas(p_sucursales);

     OPEN p_cur_out FOR
       select re.cdregion,
                re.dsregion,
                su.cdsucursal,
                su.dssucursal,
              sum(c.amimputado) monto
         from tblcobranza               c,
              tblingreso                i,
              documentos                d,
              movmateriales             mm,
              entidades                 e,
              tbltmp_sucursales_reporte rs,
              sucursales                su,
              tblregion                 re
        where c.idingreso = i.idingreso
          and d.iddoctrx = c.iddoctrx
          and d.idcuenta = i.idcuenta
          and d.idmovmateriales = mm.idmovmateriales
          and i.dtingreso between trunc(p_fechaDesde) AND trunc(p_fechaHasta + 1)
          and d.identidadreal = e.identidad
          and (p_identidad is null or e.identidad = p_identidad)
          and (p_idcuenta is null or d.idcuenta = p_idcuenta)
          AND (p_cdregion is null or re.cdregion = p_cdregion)
          and i.cdsucursal = su.cdsucursal
          AND su.cdregion = re.cdregion
          AND su.cdsucursal = rs.cdsucursal
          AND rs.idreporte = v_idReporte
        group by re.cdregion,
                re.dsregion,
                su.cdsucursal,
                su.dssucursal;

     CleanSucursalesSeleccionadas(v_idReporte);
   EXCEPTION
     WHEN OTHERS THEN
       n_pkg_vitalpos_log_general.write(2,
                                        'Modulo: ' || v_modulo || '  Error: ' ||
                                        SQLERRM);
       RAISE;
   END GetIngresosCanalGeneral;



   /*****************************************************************************************************************
   * Retorna un reporte de ingresos agrupado por region y sucursal
   * %v 23/05/2019 - IAquilano: v1.0
   ******************************************************************************************************************/
   PROCEDURE GetIngresosCanaldetalle(p_sucursales IN VARCHAR2,
                                p_identidad  IN entidades.identidad%TYPE,
                                p_idcuenta   IN tblcuenta.idcuenta%TYPE,
                                p_fechaDesde IN DATE,
                                p_fechaHasta IN DATE,
                                p_cur_out    OUT cursor_type) IS
     v_modulo    VARCHAR2(100) := 'PKG_REPORTE_CENTRAL.GetIngresosCanalGeneral';
   v_idReporte VARCHAR2(40) := '';
   BEGIN
          v_idReporte := SetSucursalesSeleccionadas(p_sucursales);

     OPEN p_cur_out FOR
       select re.dsregion,
              su.dssucursal,
              e.cdcuit,
              e.dsrazonsocial,
              mm.id_canal,
              pkg_ingreso_central.GetDescIngreso(i.cdconfingreso,i.cdsucursal) medio,
              sum(c.amimputado) monto,
              trunc(i.dtingreso) fecha
         from tblcobranza               c,
              tblingreso                i,
              documentos                d,
              tbltmp_sucursales_reporte rs,
              movmateriales             mm,
              entidades                 e,
              sucursales                su,
              tblregion                 re
        where c.idingreso = i.idingreso
          and d.iddoctrx = c.iddoctrx
          and d.idcuenta = i.idcuenta
          and d.idmovmateriales = mm.idmovmateriales
          and i.dtingreso between trunc(p_fechaDesde) AND trunc(p_fechaHasta + 1)
          and d.identidadreal = e.identidad
          and i.cdsucursal = su.cdsucursal
          AND su.cdregion = re.cdregion
          and (p_identidad is null or e.identidad = p_identidad)
          and (p_idcuenta is null or d.idcuenta = p_idcuenta)
          AND su.cdsucursal = rs.cdsucursal
          AND rs.idreporte = v_idReporte
        group by re.dsregion,
                 su.dssucursal,
                 e.cdcuit,
                 e.dsrazonsocial,
                 mm.id_canal,
                 pkg_ingreso_central.GetDescIngreso(i.cdconfingreso,
                                                    i.cdsucursal),
                 trunc(i.dtingreso);

   EXCEPTION
     WHEN OTHERS THEN
       n_pkg_vitalpos_log_general.write(2,
                                        'Modulo: ' || v_modulo || '  Error: ' ||
                                        SQLERRM);
       RAISE;
   END GetIngresosCanaldetalle;

   /**************************************************************************************************
   * 18/12/2019
   * ChM
   * function PipePedidos
   * convierte en tabla la lista que recibe como parámetro
   ***************************************************************************************************/
   Function PipeTIEMPOS Return  TIEMPOSPipe
      Pipelined Is
      i Binary_Integer := 0;
   Begin
      i := CAJA_TIEMPOS.FIRST;
      While i Is Not Null Loop
         Pipe Row(CAJA_TIEMPOS(i));
         i := CAJA_TIEMPOS.NEXT(i);
      End Loop;
      Return;
   Exception
      When Others Then
         Null;
   End PipeTIEMPOS;
   /*************************************************************************************************************************
   * Retorna el DBLink correspondiente a la sucursal
   * %v 27/12/2019 - ChM copia de la función que esta disponible en PKG_HELPDESK
   **************************************************************************************************************************/
   FUNCTION GetDBLink(p_cdsucursal IN sucursales.cdsucursal%TYPE)
     RETURN VARCHAR2 IS
       v_Modulo   VARCHAR2(100) := 'PKG_REPORTE_CENTRAL.GetDBLink';
       v_servidor sucursales.servidor%TYPE;
      BEGIN
        SELECT su.servidor
        INTO v_servidor
        FROM sucursales su
        WHERE TRIM(su.cdsucursal) = TRIM(p_cdsucursal)
              AND (su.servidor IS NOT NULL OR
              cdsucursal in ('9991', '9998    ', '9999    ')); --Incluye AC, Telemarketing, Todas;

        RETURN v_servidor;
        EXCEPTION
        WHEN OTHERS THEN
            n_pkg_vitalpos_log_general.write(2,
                                     'Modulo: ' || v_Modulo || '  Error: ' ||
                                     SQLERRM);
    RAISE;
    END GetDBLink;
   /*****************************************************************************************************************
   * Retorna fecha promedio de meta efectivo con respecto al alivio de cajas de ingreso por cajero
   * %v 17/12/2019 - ChM: v1.0
   ******************************************************************************************************************/
   PROCEDURE GetCajeroTiempoAlivio(  p_Fdesde IN DATE,
                                     p_Fhasta IN DATE,
                                     p_cdsucursal IN SUCURSALES.CDSUCURSAL%TYPE,
                                     p_cur_out    OUT cursor_type) IS
   V_idpersonas             personas.idpersona%type;
   V_fechaEfectivo          tblmovcaja.dtmovimiento%type;
   V_fechaAlivio            tblmovcaja.dtmovimiento%type;
   V_minimo                 number;
   V_CMinimo                number;
   V_Band                   number;
   V_CAlivios               number;
   V_AcuTiemposAlivio       number;
   V_DsPersona              personas.dsnombre%type;
   V_modulo                 VARCHAR2(100) := 'PKG_REPORTE_CENTRAL.GetCajeroTiempoAlivio';
   V_i                      number;
   V_dtmovimiento           tblmovcaja.dtmovimiento%type;
   V_cdoperacioncaja        tblmovcaja.cdoperacioncaja%type;
   V_ammovimiento           tblmovcaja.ammovimiento%type;

   v_DBLink                 sucursales.servidor%TYPE;
   sql_stmt                 VARCHAR2(1500);
   DOCU                     cursor_type;


   CURSOR CAJEROS IS
   SELECT DISTINCT pe.idpersona,pe.dsapellido || ' ' || pe.dsnombre dspersona
        FROM personas pe, permisos pp, cuentasusuarios cu, tblmovcaja mc
       WHERE pe.idpersona = pp.idpersona
        AND pp.nmgrupotarea = 'Cajero'
        and cu.idpersona=pe.idpersona
        and cu.icestadousuario=1                       --Cuenta activa
        and pe.icactivo=1                              --Persona activa
        and pe.idpersona=mc.idpersonaresponsable
        AND mc.dtmovimiento>=p_Fdesde AND mc.dtmovimiento<(nvl(p_Fhasta,p_Fdesde) + 1)
        and mc.cdoperacioncaja=1                       --Apertura caja
        and mc.cdsucursal=p_cdsucursal;
   BEGIN
      v_DBLink := GetDBLink(p_cdsucursal);
        SELECT nvl(getvlparametro('VLSemaforo', 'CajaUnificada'),12000)
        INTO V_minimo FROM dual;                        --obtengo el valor minimo de Alivio de Caja POR DEFECTO 12000 AL 17/12/2019
        OPEN CAJEROS;
        V_i:=0;
        CAJA_TIEMPOS.DELETE;
        LOOP
         FETCH CAJEROS INTO V_idpersonas,V_DsPersona;
          EXIT WHEN CAJEROS%NOTFOUND;
          V_band:=0;
          V_fechaEfectivo:=NULL;
          V_AcuTiemposAlivio:=0;
          V_CAlivios:=0;
          V_CMinimo:=0;
          sql_stmt := 'select mc.dtmovimiento,mc.cdoperacioncaja,mc.ammovimiento
              from tblmovcaja@'||v_DBLink|| ' mc
              where mc.idpersonaresponsable ='''||V_idpersonas||'''
              AND mc.dtmovimiento>='''||p_Fdesde||
              ''' AND mc.dtmovimiento<'''||(nvl(p_Fhasta,p_Fdesde) + 1)||'''
              and mc.cdoperacioncaja=3                  --Alivio
              union
              SELECT  mc.dtmovimiento,mc.cdoperacioncaja,mc.ammovimiento
              FROM tblmovcaja@'||v_DBLink|| ' mc, tblconfingreso@'||v_DBLink||'
               ci, tblingreso@'||v_DBLink|| ' ii
              WHERE mc.idmovcaja = ii.idmovcaja
              AND ii.cdconfingreso = ci.cdconfingreso
              AND ii.cdsucursal = ci.cdsucursal
              AND mc.idpersonaresponsable ='''||V_idpersonas||'''
              AND mc.dtmovimiento>='''||p_Fdesde||
              ''' AND mc.dtmovimiento<'''||(nvl(p_Fhasta,p_Fdesde) + 1)||'''
              AND mc.cdoperacioncaja=2                  --movimiento caja
              AND ci.icsemaforo = 1                     --operación en efectivo
              order by 1';
          OPEN DOCU FOR sql_stmt;
          LOOP
               FETCH DOCU INTO V_dtmovimiento,V_cdoperacioncaja,V_ammovimiento;
                EXIT WHEN DOCU%NOTFOUND;
            IF(V_cdoperacioncaja=2)THEN
               V_CMinimo:=V_CMinimo+V_ammovimiento;
               IF(V_CMinimo>=V_minimo and V_band=0)THEN
                  V_fechaEfectivo:=V_dtmovimiento;
                  V_band:=1;
               END IF;
             ELSE
               IF(V_cdoperacioncaja='3') THEN
                  V_CMinimo:=0;
                  V_band:=0;
                  V_fechaAlivio:=V_dtmovimiento;
                  IF(V_fechaEfectivo IS NOT NULL)THEN
                     V_CAlivios:=V_CAlivios+1;
                     V_AcuTiemposAlivio:=V_AcuTiemposAlivio+(TRUNC(MOD((V_fechaAlivio - V_fechaEfectivo) * (60 * 24), 60))); --diferencia en minutos
                  END IF;
               END IF;
             END IF;
          END LOOP;
          CLOSE DOCU;
         CAJA_TIEMPOS(V_i).R_idpersonas:=V_idpersonas;
         CAJA_TIEMPOS(V_i).R_DsPersona:=V_DsPersona;
         IF(V_CAlivios>0)THEN
         CAJA_TIEMPOS(V_i).R_MINUTOS:=V_AcuTiemposAlivio/V_CAlivios; --promedio de tiempo en minutos por cajero
         ELSE
           CAJA_TIEMPOS(V_i).R_MINUTOS:=0;
         END IF;
         V_i:=V_i+1;
        END LOOP;
         CLOSE CAJEROS;

          OPEN p_cur_out FOR
          SELECT * FROM TABLE(PipeTIEMPOS)
          ORDER BY R_MINUTOS;

     EXCEPTION
     WHEN OTHERS THEN
       n_pkg_vitalpos_log_general.write(2,
                                        'Modulo: ' || v_modulo || '  Error: ' ||
                                        SQLERRM);
       RAISE;


   END GetCajeroTiempoAlivio;

/**************************************************************************************************
* Retorna el estado de los pedidos ingresados de un comisionista luego de la última carga
* %v 03/12/2019 - APW
***************************************************************************************************/
PROCEDURE GetEstadoCargaComi(p_idcomisionista entidades.identidad%type,
                             p_dtguia         out varchar2,
                             p_sqguia         out integer,
                             p_amguia         out number,
                             p_cur_out        OUT cursor_type) IS

  v_modulo    varchar2(100) := 'PKG_REPORTE_CENTRAL.GetEstadoCargaComi';
  v_dtguia     date;

BEGIN

  -- datos de la última guía del comisionista
  begin
  select do.dtdocumento, do.sqcomprobante, do.amdocumento
    into v_dtguia, p_sqguia, p_amguia
    from guiasdetransporte gt, documentos do
   where gt.iddoctrx = do.iddoctrx
     and do.dtdocumento =
         (select max(do1.dtdocumento)
            from documentos do1
           where do1.identidad = do.identidad
             and do1.cdcomprobante = 'GUIA')
     and gt.identidad = p_idcomisionista;
  exception when others then
    null; -- evito el error y va a devolver los datos vacíos
  end;

  p_dtguia := to_char(v_dtguia, 'dd/mm/yyyy'); -- .net la necesita formateada
  -- agrupo pedidos tomados después de la útlima guía, para ver avance de la carga actual
  open p_cur_out for
    select ec.dsestado, count(distinct p.transid) qtpedi, sum(p.ammonto) ampedi
      from pedidos p, estadocomprobantes ec
     where p.icestadosistema = ec.cdestado
       and ec.cdcomprobante = 'PEDI'
       and p.icestadosistema in (2, 3, 4, 6, 16, 18)
       and p.idcomisionista = p_idcomisionista
       and p.id_canal = 'CO'
       and p.dtaplicacion > v_dtguia
     group by ec.dsestado;

EXCEPTION
  WHEN OTHERS THEN
    n_pkg_vitalpos_log_general.write(2,
                                     'Modulo: ' || v_modulo || '  Error: ' ||
                                     SQLERRM);
    raise;
End GetEstadoCargaComi;

  /**************************************************************************************************
  * Retorna usuarios y personas registradas en POS
  * %v 10/12/2021 - LM
  * %v 21/12/2021 - APW - Corrijo detalles
  ***************************************************************************************************/
  
  PROCEDURE GetUsuariosPersonas (p_icestado   IN INTEGER,
                                 p_idpersona  in personas.idpersona%type,
                                 p_cur_out    OUT cursor_type) IS

    v_modulo    varchar2(100) := 'PKG_REPORTE_CENTRAL.GetUsuariosPersonas';
    v_idReporte VARCHAR2(40) := '';
  BEGIN
    open p_cur_out for
        select p.cdlegajo Legajo,
               p.dsapellido Apellido,
               p.dsnombre Nombre,
               p.dscuil CUIL,
               decode(p.icactivo, 1, 'Activo', 'Baja') estado_persona,
               nvl(c.dsloginname, '---Sin Usuario---') Usuario,
               decode(c.icestadousuario, 1, 'Activo', 0, 'Baja', '') estado_usuario,
               decode(c.dsloginname, null, null, trunc(c.dtvencimientopassword)) vencimiento_password,
               nvl(suc.dssucursal, '---') Sucursal
          from personas p, cuentasusuarios c, sucursales suc
         where p.idpersona = c.idpersona(+)
           and p.icactivo = p_icestado
           and p.idpersona = nvl(p_idpersona, p.idpersona)
           and c.cdsucursal = suc.cdsucursal(+)
         order by cdlegajo;
             

  EXCEPTION WHEN OTHERS THEN
     n_pkg_vitalpos_log_general.write(2, 'Modulo: '||v_modulo||'  Error: ' || SQLERRM);
     raise;
  End GetUsuariosPersonas;


  /*****************************************************************************************************************
   * Dada una fecha y sucursal retorna los datos de cierre de lote salon
   * %v 19/08/2021 - LM: v1.0
   * %v 02/05/2022 - IA: Modifico el reporte, hay casos que realizan movimientos posteriores al cierre de lote.
   ******************************************************************************************************************/
   PROCEDURE GetCierreLoteSalon( p_dtFechaDesde     IN tblcierrelotesalon.dtlote%TYPE,
                                 p_dtFechaHasta     IN tblcierrelotesalon.dtlote%type,
                                 p_cdsucursal       IN tblcierrelotesalon.cdsucursal%type,
                                 p_cur_out          OUT cursor_type) IS
      v_modulo VARCHAR2(100) := 'PKG_REPORTE_CENTRAL.GetCierreLoteSalon';
   BEGIN
      OPEN p_cur_out FOR
/*      Select suc.dssucursal,trunc(cl.dtlote) Fecha, cl.vlterminal, cl.vllote, cl.amingreso,
       pkg_ingreso_central.GetDescIngreso(cl.cdconfingreso,p_cdsucursal) dsingreso, cl.amdiferencia
      from tblcierrelotesalon cl, sucursales suc
      where cl.dtlote between trunc(p_dtFechaDesde) and trunc(p_dtFechaHasta)+1
      and cl.cdsucursal=suc.cdsucursal
      and cl.cdsucursal=p_cdsucursal;*/

        with ingresos as
         (select tt.nrolote,
                 tt.vlterminal,
                 ti.cdconfingreso,
                 trunc(ti.dtingreso) dtingreso,
                 sum(ti.amingreso) as tot
            from tblingreso ti, tbltarjeta tt
           where ti.dtingreso between trunc(p_dtFechaDesde) and
                 trunc(p_dtFechaHasta) + 1
             and ti.idingreso = tt.idingreso
             and ti.cdsucursal = p_cdsucursal
           group by tt.nrolote, tt.vlterminal, ti.cdconfingreso, trunc(ti.dtingreso))
        Select suc.dssucursal,
               trunc(cl.dtlote) Fecha,
               cl.vlterminal,
               cl.vllote,
               cl.amingreso,
               pkg_ingreso_central.GetDescIngreso(cl.cdconfingreso, p_cdsucursal) dsingreso,
               case
                 when i.tot < 0 then
                  (cl.amingreso + i.tot)
                 else
                  (cl.amingreso - i.tot)
               end as amdiferencia
          from tblcierrelotesalon cl, sucursales suc, ingresos i
         where cl.dtlote between trunc(p_dtFechaDesde) and
               trunc(p_dtFechaHasta) + 1
           and cl.cdsucursal = suc.cdsucursal
           and cl.cdsucursal = p_cdsucursal
           and cl.vllote = i.nrolote
           and cl.vlterminal = i.vlterminal
           and cl.cdconfingreso = i.cdconfingreso
           and trunc(cl.dtlote) = i.dtingreso;

   EXCEPTION
      WHEN OTHERS THEN
         n_pkg_vitalpos_log_general.write(2, 'Modulo: ' || v_modulo || '  Error: ' || SQLERRM);
         RAISE;
   END GetCierreLoteSalon;

   /*****************************************************************************************************************
   * Rertorna comercios  configgurados
   * %v 14/12/2021 - LM
   ******************************************************************************************************************/
    PROCEDURE GetComerciosConfigurados(p_cur_out OUT cursor_type) IS
      v_modulo VARCHAR2(100) := 'PKG_REPORTE_CENTRAL.GetComerciosConfigurados';
    BEGIN
      OPEN p_cur_out FOR
        select e.cdcuit cuit,
               e.dsrazonsocial Razon_Social,
               cu.cdsucursal sucursal,
               cu.nombrecuenta cuenta,
               decode(nvl(cu.iccontracargo, 0), 1, 'SI', 'NO') Marca_contracargo,
               es.vlestablecimiento comercio,
               es.vlterminal terminal,
               ti.dstipo tarjeta,
               fi.dsforma forma
          from entidades          e,
               tblestablecimiento es,
               tblcuenta          cu,
               tbltipoingreso     ti,
               tblformaingreso    fi
         where e.identidad = cu.identidad
           and cu.idcuenta = es.idcuenta
           and es.cdtipo = ti.cdtipo
           and e.cdforma = fi.cdforma
        union
        select e.cdcuit,
               e.dsrazonsocial,
               cu.cdsucursal,
               cu.nombrecuenta,
               decode(nvl(cu.iccontracargo, 0), 1, 'SI', 'NO'),
               esm.vlestablecimientomaycar,
               ce.vlterminal,
               ti.dstipo,
               fi.dsforma
          from entidades                e,
               tblestablecimientomaycar esm,
               tblcuenta                cu,
               tbltipoingreso           ti,
               tblformaingreso          fi,
               tblclientespecial        ce
         where e.identidad = cu.identidad
           and cu.idcuenta = ce.idcuenta
           and ce.idestablecimientomaycar = esm.idestablecimientomaycar
           and esm.cdtipo = ti.cdtipo
           and esm.cdforma = fi.cdforma;
        
    EXCEPTION
      WHEN OTHERS THEN
        n_pkg_vitalpos_log_general.write(2,
                                         'Modulo: ' || v_modulo ||
                                         '  Error: ' || SQLERRM);
        raise;
    end GetComerciosConfigurados;
    
   /*****************************************************************************************************************
   * Rertorna venta de articulos electronicos (CABECERA)
   *  08/02/2022 - LA
   ******************************************************************************************************************/     
    PROCEDURE GetVentaArticulosElectroCuotas(p_fechadesde IN DATE,
                                             p_fechahasta IN DATE,
                                             p_cur_out OUT cursor_type) IS
        v_modulo VARCHAR2(100) := 'PKG_REPORTE_CENTRAL.GetVentaArticulosElectroCuotas';
        BEGIN
          OPEN p_cur_out FOR
--CABECERA     
       with nf as
            (select c.cdarticulo
            from tblctgryarticulocategorizado c,
            tblctgrysectorc s,
            tblctgrydepartamento d
            where c.cdsectorc = s.cdserctorc
            and c.cddepartamento = d.cddepartamento
            and s.dssectorc = 'NON FOOD'
            and d.dsdepartamento = 'ELECTRO')
            select distinct do.iddoctrx, suc.dssucursal sucursal,
            ii.dtingreso fecha_ingreso,
            do.dtdocumento fecha_factura,
            pkg_ingreso_central.getdescingreso(ii.cdconfingreso, ii.cdsucursal ) Medio,
            sum  (ii.amingreso)  Total_ingreso,
            sum  (co.amimputado) Pago_factura, 
            case
            when ta.plancuotas in (1, 3) then
            ta.plancuotas
            when ta.plancuotas = '7' then
            'Ahora 12'
            when ta.plancuotas = '8' then
            'Ahora 18'
            when ta.plancuotas = '16' then
            'Ahora 6'
            when ta.plancuotas = '11' then
            'Plan Z'
            when ta.plancuotas = '4' then
            'Plan Z 4'
            when ta.plancuotas = '13' then
            'Ahora 3'
            when ta.plancuotas = '201' then
            'GiftCard'
            else
            'Efectivo'
            end cuotas,
            pkg_core_documento.getdescdocumento(do.iddoctrx) FC,
            e.dsrazonsocial, 
            do.amnetodocumento Total_sin_imp_con_iva,
            do.amdocumento Total_factura
            from tbltarjeta ta,
            tblingreso ii,
            tblcuenta c,
            entidades e,
            tblcobranza co,
            documentos do, sucursales suc
            where ta.idingreso (+)= ii.idingreso
            and ii.idcuenta = c.idcuenta
            and c.identidad = e.identidad
            and ii.idingreso = co.idingreso
            and co.iddoctrx = do.iddoctrx 
            and do.cdsucursal=suc.cdsucursal
            and ((ii.cdestado not in ('4', '5') and ii.cdconfingreso<>'810') 
                or (ii.cdestado  in ('4', '5') and ii.cdconfingreso='811'))--no ingresos rechazados o revertidos-- NO GIFTCARD
            and do.cdestadocomprobante not in ('3','6') --documentos anulados antes o despues de cancelarse
            and do.dtdocumento between trunc(p_fechadesde) and trunc(p_fechahasta) 
          and do.idmovmateriales in
          (
          select dmm.idmovmateriales from detallemovmateriales dmm, nf
          where dmm.idmovmateriales=do.idmovmateriales
            and nvl(dmm.icresppromo, '0') = 0
            and trim(nvl(dmm.dsobservacion, 'x')) not in ('(*)', 'DEL')
            and dmm.cdarticulo = nf.cdarticulo
          )
            group by do.iddoctrx, ii.cdsucursal, suc.dssucursal,
            ii.dtingreso,
            do.dtdocumento,
             ii.cdconfingreso , 
            ta.plancuotas , 
            e.dsrazonsocial, do.amnetodocumento, do.amdocumento
             order by do.dtdocumento, do.iddoctrx;
          EXCEPTION
          WHEN OTHERS THEN
             n_pkg_vitalpos_log_general.write(2, 'Modulo: ' || v_modulo || '  Error: ' || SQLERRM);
             RAISE;
    END GetVentaArticulosElectroCuotas;
    
     /*****************************************************************************************************************
   * Rertorna venta de articulos electronicos (Detalle)
   *  08/02/2022 - LA
   ******************************************************************************************************************/     
    PROCEDURE GetVentaArticulosElectroDet(p_fechadesde IN DATE,
                                             p_fechahasta IN DATE,
                                             p_cur_out OUT cursor_type) IS
        v_modulo VARCHAR2(100) := 'PKG_REPORTE_CENTRAL.GetVentaArticulosElectroCuotas';
        BEGIN
          OPEN p_cur_out FOR
--DETALLE
            with nf as
            (select c.cdarticulo
            from tblctgryarticulocategorizado c,
            tblctgrysectorc s,
            tblctgrydepartamento d
            where c.cdsectorc = s.cdserctorc
            and c.cddepartamento = d.cddepartamento
            and s.dssectorc = 'NON FOOD'
            and d.dsdepartamento = 'ELECTRO')
            select distinct do.iddoctrx, suc.dssucursal sucursal,
            pkg_core_documento.getdescdocumento(do.iddoctrx) FC,
            do.dtdocumento fecha_factura,
            e.dsrazonsocial,
            dmm.cdarticulo,
            dmm.dsarticulo,
            sum(dmm.qtunidadmedidabase) Cantidad,
            dmm.ampreciounitario,
            do.amnetodocumento Total_sin_imp_con_iva,
            do.amdocumento Total_factura
            from tblcuenta c,
            entidades e,
            documentos do,
            detallemovmateriales dmm,
            nf,
            sucursales suc
            where  c.identidad = e.identidad 
            and do.idcuenta=c.idcuenta
            and do.idmovmateriales = dmm.idmovmateriales
            and nvl(dmm.icresppromo, '0') = 0
            and trim(nvl(dmm.dsobservacion, 'x')) not in ('(*)', 'DEL')
            and do.amdocumento>0
            and do.cdestadocomprobante not in ('3','6') --documentos anulados antes o despues de cancelarse
           and do.dtdocumento between trunc(p_fechadesde) and trunc(p_fechahasta)
            and dmm.cdarticulo = nf.cdarticulo
            and do.cdsucursal=suc.cdsucursal
            group by do.iddoctrx, do.cdsucursal, suc.dssucursal,
            do.dtdocumento,
            e.dsrazonsocial,
            dmm.cdarticulo,
            dmm.dsarticulo,
            dmm.ampreciounitario,do.amnetodocumento, do.amdocumento 
            order by do.dtdocumento, do.iddoctrx;
          EXCEPTION
          WHEN OTHERS THEN
             n_pkg_vitalpos_log_general.write(2, 'Modulo: ' || v_modulo || '  Error: ' || SQLERRM);
             RAISE;
    END GetVentaArticulosElectroDet;

/****************************************************************************************
* Busqueda de facturas de clientes
* %v 14/03/2022 - KMaldonado
*****************************************************************************************/

PROCEDURE GetBusquedaFacturas(p_fechadesde        in   date  ,
                              p_fechahasta        in   date  ,
                              p_dni               in   VARCHAR2        ,                       
                              p_entidad           in   entidades.identidad%type,
                              p_cur_out           OUT cursor_type) IS
  v_Modulo VARCHAR2(100) := 'PKG_REPORTE_CENTRAL.GetBusquedaFacturas';
 
BEGIN
  OPEN p_cur_out FOR
     SELECT DISTINCT d.idmovmateriales,
                     e.cdcuit,
                     e.dsrazonsocial razonsocial,
                     sii.dssituacionivadgi,
                     PKG_REPORTE_CENTRAL.ObtenerDNIReferencia(d.dsreferencia,
                                                     d.identidad,
                                                     mm.id_canal) dni,
                     trunc(d.dtdocumento) fecha,
                     pkg_core_documento.GetDescDocumento(d.iddoctrx) factura,
                     d.amdocumento total,
                     mm.id_canal
       FROM documentos           d,
            movmateriales        mm,
            entidades            e,
            situacionesivadgi    sii,
            detallemovmateriales dmm
      WHERE (e.cdcuit LIKE '%' || p_dni || '%' OR d.dsreferencia LIKE '%' || p_dni || '%')
        AND d.idmovmateriales = mm.idmovmateriales
        AND d.dtdocumento BETWEEN TRUNC(p_fechadesde) AND TRUNC(p_fechahasta)+1
        AND e.identidad = d.identidadreal
        AND e.identidad = NVL(p_entidad, e.identidad)
        AND mm.cdsituacioniva = sii.cdsituacionivapos
        AND mm.idmovmateriales = dmm.idmovmateriales
      ORDER BY trunc(d.dtdocumento);

EXCEPTION
WHEN OTHERS THEN
  n_pkg_vitalpos_log_general.write(2, 'Modulo: ' || v_Modulo || ' Error: ' || SQLERRM);
  RAISE;
END GetBusquedaFacturas;

/****************************************************************************************
* Detalle de Busqueda de facturas de clientes
* %v 21/03/2022 - Karen Maldonado
*****************************************************************************************/
PROCEDURE GetBusquedaFacturasDetalle(p_idmovmateriales  IN detallemovmateriales.idmovmateriales%type,
                                     p_cur_out          OUT cursor_type) IS
  v_Modulo VARCHAR2(100) := 'PKG_REPORTE_CENTRAL.GetBusquedaFacturasDetalle';
BEGIN

  OPEN p_cur_out FOR
   SELECT dmm.cdarticulo,
          dmm.dsarticulo,
          dmm.amlinea,
          dmm.ampreciounitario,
          dmm.qtunidadmedidabase
     FROM detallemovmateriales dmm
    WHERE dmm.idmovmateriales = p_idmovmateriales
      AND dmm.icresppromo = 0;

EXCEPTION
WHEN OTHERS THEN
  n_pkg_vitalpos_log_general.write(2, 'Modulo: ' || v_Modulo || ' Error: ' || SQLERRM);
  RAISE;
END GetBusquedaFacturasDetalle;

/****************************************************************************************
* Obtener DNI Referencia en caso de CF
* Obtiene el DNI de la referencia de un documento
* %v 29/03/2022 - LM. 
*****************************************************************************************/
FUNCTION ObtenerDNIReferencia(p_DsReferencia   in DOCUMENTOS.Dsreferencia%type,
                                 p_identidad    in documentos.identidad%type,
                                 p_canal        in movmateriales.id_canal%type)
 RETURN varchar2 IS

   v_Modulo               varchar2(100) := 'PKG_REPORTE_CENTRAL.ObtenerDNIReferencia';
   v_refPars              documentos.dsreferencia%Type;
   v_pos1                 Integer;
   v_pos2                 Integer;
   v_pos3                 Integer;
   v_pos4                 Integer;
   v_posMedio             Integer;
   v_dni                  varchar2(10);
begin
   if p_DsReferencia is not null then
       --verifico si es CF SALON y si el CUIT es null
    if trim(p_identidad) in( trim(getvlparametro('CdConsFinal', 'General')),trim(getvlparametro('CdCFNoResidente', 'General'))) and p_canal = 'SA' then
        v_pos1  := instr(trim(p_DsReferencia), Trim('{'));
        v_pos2  := instr(trim(p_DsReferencia), Trim('}'));
        v_refPars := Null;
        If v_pos1 > 0 And v_pos2 > 0 And v_pos1 < v_pos2 Then
           v_refPars := substr(trim(p_DsReferencia), v_pos1 + 1, v_pos2 - v_pos1 - 1);
        End If;
        if v_refPars is not null then
          v_posMedio  := instr(trim(v_refPars), Trim('|'));
          v_dni:=substr(trim(v_refPars), 0, v_posMedio - 1);
        end if;
    elsif trim(p_identidad) = trim(getvlparametro('IdCfReparto', 'General')) and p_canal <> 'SA' then
       --parseo referencia dentro de {} para obtener la direccion y dni
        v_pos1  := instr(trim(p_DsReferencia), Trim('{'));
        v_pos2  := instr(trim(p_DsReferencia), Trim('|'));
        v_pos3  := instr(trim(p_DsReferencia), Trim('|'),v_pos2 + 1);
        v_pos4  := instr(trim(p_DsReferencia), Trim('}'));

        v_dni:= substr(p_DsReferencia, v_pos2 + 1 , v_pos3 - v_pos2 - 1 );
    end if;
   else
     v_dni:='-';
   end if;

 return v_dni;

exception when others then
   n_pkg_vitalpos_log_general.write(2, 'Modulo: '||v_Modulo||'  Error: ' || SQLERRM);
   raise;
end ObtenerDNIReferencia;

  /*****************************************************************************************************************
  * Rertorna venta de articulos electronicos (Detalle)
  *  08/02/2022 - LA
  ******************************************************************************************************************/
  PROCEDURE GetEstatusPrecargaNC(p_sucursales IN VARCHAR2,
                                 p_estado     IN tblprecarganc.cdestado%type,
                                 p_fechadesde IN DATE,
                                 p_fechahasta IN DATE,
                                 p_canal      IN movmateriales.id_canal%type,
                                 p_cur_out    OUT cursor_type) IS

    v_modulo    VARCHAR2(100) := 'PKG_REPORTE_CENTRAL.GetEstatusPrecargaNC';
    v_idReporte VARCHAR2(40) := '';

  BEGIN

    v_idReporte := SetSucursalesSeleccionadas(p_sucursales);

    OPEN p_cur_out FOR
      with NCPRECARGADAS as (
select tpc.idprecarganc, d.dtdocumento, p.dsapellido||', '||p.dsnombre as responsable, ec.dsestado, pkg_documento_central.GetDescDocumento(tdc.iddoctrxgen) as Nro_Comprobante
from tbldocumento_control tdc,
     documentos d,
     personas p,
     estadocomprobantes ec,
     tblprecarganc tpc
where tpc.dtinsert between TRUNC(p_fechaDesde) AND TRUNC(p_fechaHasta + 1) --filtro fechas
AND tdc.iddoctrxgen = d.iddoctrx
and tdc.idpersonaresponsable =  p.idpersona
and d.cdestadocomprobante = ec.cdestado
and d.cdcomprobante = ec.cdcomprobante
and tdc.idprecarganc is not null--Para forzar a usar el indice
and tdc.idprecarganc = tpc.idprecarganc
)
select pc.idprecarganc,
       pc.dtinsert fecha_precarga,
       p.dsnombre || ' ' || p.dsapellido Persona_responsable,
       pc.nroprecarga Nro_precarga,
       tc.dsestado estado_precarga,
       mm.id_canal canal,
       suc.dssucursal sucursal,
       nvl((select to_char(tnc.dtupdate,'DD/MM/YYYY hh24:mi:ss')
          from tbllogprecargancestado tnc
         where tnc.cdestado = (select min(tncc.cdestado)
                                 from tbllogprecargancestado tncc
                                where tncc.idprecarganc = tnc.idprecarganc
                                  and tncc.cdestado > 0)
           and tnc.idprecarganc = pc.idprecarganc),'-') fecha_revision,
       nvl((select p.dsnombre || ', ' || p.dsapellido
          from tbllogprecargancestado tnc, personas p
         where tnc.cdestado = (select min(tncc.cdestado)
                                 from tbllogprecargancestado tncc
                                where tncc.idprecarganc = tnc.idprecarganc
                                  and tncc.cdestado > 0)
           and tnc.idprecarganc = pc.idprecarganc
           and tnc.idpersona = p.idpersona),'-') as responsablederevision,
       nvl((select tr.dsestado
          from tbllogprecargancestado tnc, tblestadoprecarga tr
         where tnc.cdestado = (select min(tncc.cdestado)
                                 from tbllogprecargancestado tncc
                                where tncc.idprecarganc = tnc.idprecarganc
                                  and tncc.cdestado > 0)
           and tnc.idprecarganc = pc.idprecarganc
           and tnc.cdestado = tr.cdestado),'-') as resolucion,
       nvl(tpc.dsmotivorechazo,'-') as justificacion,
       '-' as evidencia,
       nvl(to_char(ncp.dtdocumento,'DD/MM/YYYY hh24:mi:ss'),'-') as dtnotacredito,
       nvl(ncp.responsable,'-') as ResponsableNC,
       nvl(ncp.dsestado,'-') as dsestadoNC,
       nvl(ncp.nro_comprobante,'-') as Nro_comprobante_NC
  from tblprecarganc             pc,
       documentos                d,
       movmateriales             mm,
       personas                  p,
       sucursales                suc,
       tblpcmotivosrechazos      tpc,
       ncprecargadas             NCP,
       tblestadoprecarga         tc,
       tbltmp_sucursales_reporte rs
 where pc.iddoctrx = d.iddoctrx
   and d.idmovmateriales = mm.idmovmateriales
   and tc.cdestado = pc.cdestado
   and pc.idpersonacarga = p.idpersona
   and pc.cdsucursal = suc.cdsucursal
   and pc.cdmotivorechazo = tpc.cdmotivorechazo(+)
   and pc.idprecarganc = ncp.idprecarganc(+)
   and suc.cdsucursal = rs.cdsucursal
   and rs.idreporte = v_idReporte --filtro sucursales
   and pc.dtinsert BETWEEN TRUNC(p_fechaDesde) AND TRUNC(p_fechaHasta + 1) --filtro fechas
   and (p_estado = -1 OR pc.cdestado = p_estado) --filtro de estado
   and mm.id_canal in
       (select *
          from (SELECT SUBSTR(txt,
                              INSTR(txt, ',', 1, level) + 1,
                              INSTR(txt, ',', 1, level + 1) -
                              INSTR(txt, ',', 1, level) - 1) AS u
                  FROM (SELECT replace(',' || replace(p_canal, ' ', '') || ',',
                                       '''',
                                       '') AS txt
                          FROM dual)
                CONNECT BY level <=
                           LENGTH(txt) - LENGTH(REPLACE(txt, ',', '')) - 1));

  EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_modulo || '  Error: ' ||
                                       SQLERRM);
      RAISE;
      
  END GetEstatusPrecargaNC;


END PKG_REPORTE_CENTRAL;
/
