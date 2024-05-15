CREATE OR REPLACE PACKAGE Ibw
--------------------------------------------------------------------------------------------------
-- Fecha        Programador         Descripci¢n
--------------------------------------------------------------------------------------------------
-- 07/08/2004   Fernanda MOron      Se modific¢ la funci¢n EjecutarProceso y ObtenerDatosCamposDM
--                                  para adaptar al tratamiento de las promociones de voucher marketec
--                                  La NC se trata normalmente salvo que se agrega en el campo cdpromo
--                                  un valor especial para identificar dicha promoci¢n.
--------------------------------------------------------------------------------------------------
-- 05/04/2005   Hernan Azpilcueta   Modifico la forma en que detecta si es NC de voucher ya que es posible
--                                  que existan mas de un motivo para la NC y el sistema toma uno de ellos
--                                  que puede ser justo el que no es 110. Para solucionar esto se agregar 
--                                  una consulta que detecte si alguno de los motivos es 110.
-- 12/10/2012	ACV		    Se modifico para que determine si un precio es de tapa y esta vigente, solo para precios de  pedidos de vendedor y facturas conexas
-- 05/02/2013	ACV		    Se modifico para que incluya si participo de una regla  y su id, o no
-----------------------------------------------------------------------------------------------------------
IS
  FUNCTION EspedidoVendedor(p_idped PEDIDOS.IDPEDIDO%type) return integer;

  Function GetFechaPedido(p_idped PEDIDOS.IDPEDIDO%type ) return DATE;

  Function EsPrecioDeTapa(p_cdart  ARTICULOS.CDARTICULO%type, p_fch DATE, p_cdcanal tblcanal.id_canal%type) return  integer;

  Function GetCuitReferenciado(p_idmov in MOVMATERIALES.IDMOVMATERIALES%TYPE, o_cdcuit out ENTIDADES.CDCUIT%TYPE) return  integer;

  FUNCTION EsCbteFiscal(p_cbte  in COMPROBANTES.CDCOMPROBANTE%TYPE) return INTEGER;

  FUNCTION ClteDeZonaFranca( piIDentidad IN ENTIDADES.IDENTIDAD%TYPE) return INTEGER;

  FUNCTION GetCuitRef( pidsrefer in DOCUMENTOS.dsreferencia%TYPE, pocdcuit out ENTIDADES.CDCUiT%TYPE) return  integer ;

  PROCEDURE GrabarLog(iXMLSuceso IN VARCHAR2,
  					  iCDSucursal IN LOGINTERFACES.CDSUCURSAL%TYPE);


  PROCEDURE EjecutarProceso (iFechaProceso IN DATE,oEstado OUT INTEGER);


  TYPE recDetPedFalt IS RECORD ( SQDETALLEPEDIDO     DETALLEPEDIDOS.SQDETALLEPEDIDO%TYPE,
							   	 CDUNIDADMEDIDA      DETALLEPEDIDOS.CDUNIDADMEDIDA%TYPE,
							   	 CDARTICULO          DETALLEPEDIDOS.CDARTICULO%TYPE,
							   	 QTUNIDADPEDIDO	   	 DETALLEPEDIDOS.QTUNIDADPEDIDO%TYPE,
							   	 QTUNIDADMEDIDABASE  DETALLEPEDIDOS.QTUNIDADMEDIDABASE%TYPE,
							   	 QTPIEZAS			 DETALLEPEDIDOS.QTPIEZAS%TYPE,
							   	 AMPRECIOUNITARIO	 DETALLEPEDIDOS.AMPRECIOUNITARIO%TYPE,
							   	 AMLINEA			 DETALLEPEDIDOS.AMLINEA%TYPE,
							   	 VLUXB			   	 DETALLEPEDIDOS.VLUXB%TYPE,
							   	 DSOBSERVACION	   	 DETALLEPEDIDOS.DSOBSERVACION%TYPE,
							   	 ICRESPPROMO		 DETALLEPEDIDOS.ICRESPPROMO%TYPE,
							   	 CDPROMO			 DETALLEPEDIDOS.CDPROMO%TYPE);

PROCEDURE GetReglaDetMovmat(p_idmovmat in DETALLEMOVMATERIALES.IDMOVMATERIALES%type, p_sq in DETALLEMOVMATERIALES.sqdetallemovmateriales%type,
  					p_art DETALLEMOVMATERIALES.CDARTICULO%type,
  					o_idregla OUT TBLREGLA_DETMOVMAT.id_regla%type, o_aplico OUT TBLREGLA_DETMOVMAT.aplica%type, o_porc OUT number, o_factor OUT number);

END;
/
CREATE OR REPLACE PACKAGE BODY Ibw

IS
/*--- Trae la linea de la regla  idregla, si aplico, factor y porcentaje 
%v 13/10/2021 - APW - agrego búsqueda en TBLFACTOR 
*/

PROCEDURE GetReglaDetMovmat(p_idmovmat in DETALLEMOVMATERIALES.IDMOVMATERIALES%type,
                            p_sq       in DETALLEMOVMATERIALES.sqdetallemovmateriales%type,
                            p_art      DETALLEMOVMATERIALES.CDARTICULO%type,
                            o_idregla  OUT TBLREGLA_DETMOVMAT.id_regla%type,
                            o_aplico   OUT TBLREGLA_DETMOVMAT.aplica%type,
                            o_porc     OUT number,
                            o_factor   OUT number) is

BEGIN
  /*--- ac.OBTENGO LOS ID DE REGLA  QUE APLICO  ---*/
  o_idregla := null;
  o_aplico  := 0;
  o_porc    := 0;
  o_factor  := 0;

  select id_regla, aplica
    into o_idregla, o_aplico
    from TBLREGLA_DETMOVMAT
   where id_movmateriales = p_idmovmat
     and sqdetallemovmateriales = p_sq;
  
  select f.factor, f.porcentaje
    into o_factor, o_porc
    from tblfactor f
   where f.id_regla = o_idregla;

EXCEPTION
  WHEN others then
    RETURN;

END GetReglaDetMovmat;


   /*08/10/2018 JBodnar: Se hace un substr sobre la referencia*/
  Function GetCuitReferenciado(p_idmov in MOVMATERIALES.IDMOVMATERIALES%TYPE, o_cdcuit out  ENTIDADES.CDCUIT%TYPE) return integer
  IS
  cuantos  integer;
  cuite ENTIDADES.CDCUIT%TYPE;
--  idped  MOVMATERIALES.IDPEDIDO%TYPE;
  BEGIN
  	select count(*)  into cuantos
  		from movmateriales mm, documentos d,  pedidos p
  		where mm.idmovmateriales = p_idmov and
  			mm.idmovmateriales = d.idmovmateriales and
  				trim(d.identidad) = 'IdCfReparto' and
  					mm.idpedido is not null and
  						mm.idpedido = p.idpedido;


  	if cuantos >=1  then
	  	select  substr(d.dsreferencia,2,13)
      --replace(replace(trim(d.dsreferencia),'[',''),']','')
      into cuite
	  	 from  movmateriales mm, pedidos p , documentos d
	  	 	where
	  	 		mm.idmovmateriales = p_idmov and
	  	 		mm.idpedido = p.idpedido and
	  	 		p.iddoctrx = d.iddoctrx;
	else
		cuite := '';
	end if;

	o_cdcuit := cuite;

	return cuantos;

  END GetCuitReferenciado;

  FUNCTION EsCbteFiscal(p_cbte  in COMPROBANTES.CDCOMPROBANTE%TYPE) return INTEGER
  IS
  cuantos integer;
  BEGIN
  	select count(*) into cuantos  from comprobantes cb, impfiscomprobantes ifc
  		where cb.cdcomprobante = p_cbte and
  			cb.cdcomprobante = ifc.cdcomprobante;

  	if cuantos >= 1 then
  		return 1;
  	else
  		return 0;
  	end if;

  END EsCbteFiscal;







  FUNCTION ClteDeZonaFranca( piIDentidad IN ENTIDADES.IDENTIDAD%TYPE) return INTEGER
  IS
  cuantos integer;
  BEGIN

  	select count(*) into cuantos from direccionesentidades
  		where identidad  = piIDentidad and cdpais = '1';
  	if cuantos >= 1 then
  		return 1;
  	else
  		return 0;
  	end if;

  END ClteDeZonaFranca;


  FUNCTION GetCuitRef( pidsrefer in DOCUMENTOS.dsreferencia%TYPE, pocdcuit out ENTIDADES.CDCUiT%TYPE) return  integer
  is
  posi integer;
  posf integer;
  --ok integer;
  cdcuit entidades.cdcuit%type;

  BEGIN
	---posi := instr(pidsrefer,'-('); APW 22/5/14 - No se escribe más el -
  posi := instr(pidsrefer,'(');
	posf := instr(pidsrefer,')');

	cdcuit := NULL;
	if posi >=1 and posf >= 1 then
		--cdcuit := substr(pidsrefer,posi+2,posf-posi-2);
    cdcuit := substr(pidsrefer,posi+1,posf-posi-1);
	end if;
	pocdcuit := cdcuit;
	return 1;
 End GetCuitRef;

  FUNCTION ObtenerVendedorEntidad(piIdEntidad  IN ENTIDADES.IDENTIDAD%TYPE,
  		   		  poIdVendedor OUT ENTIDADESPERSONA.IDPERSONA%TYPE,
                      		  pimovmat    in  DOCUMENTOS.IDMOVMATERIALES%TYPE,
				  poXMLSalida  OUT VARCHAR2,
				  poIDTelemarketer OUT PEDIDOS.IDPERSONARESPONSABLE%TYPE) RETURN INTEGER
  IS
  tmpiddoctrx       DOCUMENTOS.IDDOCTRX%TYPE;
  tmppedido         PEDIDOS.IDPEDIDO%TYPE;
  tmpIdVendedor     ATRIBUTOSENTIDADES.VLATRIBUTO%TYPE;
  tmpIdTelemarketer PEDIDOS.IDPERSONARESPONSABLE%TYPE;
  --tmpRolVendedor    ENTIDADESPERSONA.CDROLPERSONA%TYPE;

  BEGIN

    select idpedido,iddoctrx
    into tmppedido,tmpiddoctrx
    from movmateriales
    where idmovmateriales=pimovmat;

    loop
    	exit when tmpiddoctrx is null;

	select idpedido,iddoctrx
	into tmppedido,tmpiddoctrx
	from movmateriales m
	where exists(select idmovmateriales from documentos d
                 where d.idmovmateriales=m.idmovmateriales and
                 d.iddoctrx=tmpiddoctrx);

    end loop;

    /*--- ACV 27/10/2006 ---*/
    /*--- modificacion para BW, rentabilidad de ventas ---*/
    /*--- trae el vendedor o legajo del telemarketer que lo cargo ---*/
    select idvendedor, IDPERSONARESPONSABLE
    into tmpIdVendedor, tmpIdTelemarketer
    from pedidos
    where idpedido=tmppedido;

	  poIdVendedor:=tmpIdVendedor;
	  poIDTelemarketer:=tmpIdTelemarketer;

	  RETURN(0);

  EXCEPTION
	  	   WHEN NO_DATA_FOUND THEN
	   		 poIdVendedor:='';
	                 poIDTelemarketer:='';

			 RETURN(0);

		   WHEN OTHERS THEN
		   	 poXMLSalida:=  '<NUMERO>' || trim(SQLCODE) || '</NUMERO>';
			 poXMLSalida:= poXMLSalida || '<DESCRIPCION>' || trim(SQLERRM) || '</DESCRIPCION>';

  			 RETURN(-1);

  END ObtenerVendedorEntidad;



  PROCEDURE EsPedido(piCDCOMPROBANTE IN DOCUMENTOS.CDCOMPROBANTE%TYPE,
  		   			 poESPEDIDO		OUT BOOLEAN)
  IS

  /*DETERMINA SI ES UN PEDIDO U OTRO MOVIMIENTO*/

  BEGIN

  	   IF UPPER(TRIM(piCDCOMPROBANTE)) IN ('PEDG','PEDI') THEN
	   	  poESPEDIDO:=TRUE;
	   ELSE
	   	  poESPEDIDO:=FALSE;
	   END IF;

  END EsPedido;


FUNCTION ObtenerAtributoEntidad (piIDENTIDAD  IN DOCUMENTOS.IDENTIDAD%TYPE,
  		   					     piCDSUCURSAL IN DOCUMENTOS.CDSUCURSAL%TYPE:=NULL,
							     piCDATRIBUTO IN ATRIBUTOSENTIDADES.CDATRIBUTO%TYPE,
								 poVLATRIBUTO OUT ATRIBUTOSENTIDADES.VLATRIBUTO%TYPE,
  								 poXMLSalida  OUT VARCHAR2) RETURN INTEGER

  IS

  /*FUNCION GENERICA PARA OBTENER REGISTROS DE LA TABLA AtributosEntidades*/

   BEGIN

  	   IF TRIM(piCDATRIBUTO)='NROVIEJO' THEN
		   SELECT ai.VLATRIBUTO
		   INTO	  poVLATRIBUTO
		   FROM   ATRIBUTOSENTIDADES ai
		   WHERE  ai.IDENTIDAD = piIDENTIDAD AND
		   		  ai.SQATRIBUTO = piCDSUCURSAL AND
		   		  ai.CDATRIBUTO = piCDATRIBUTO;
	   ELSE
	   	   SELECT ai.VLATRIBUTO
		   INTO	  poVLATRIBUTO
		   FROM   ATRIBUTOSENTIDADES ai
		   WHERE  ai.IDENTIDAD = piIDENTIDAD AND
		   		    ai.CDATRIBUTO = piCDATRIBUTO and --- apw 11/3/2015 -- para que no de error de mas de 1 fila
              ai.sqatributo = (select max (ai2.sqatributo) from atributosentidades ai2
                               where ai2.identidad = ai.identidad
                               and   ai2.cdatributo = ai.cdatributo);

	   END IF;

  	   RETURN (0);

  EXCEPTION
  		WHEN NO_DATA_FOUND THEN

			 RETURN(-1);

		WHEN OTHERS THEN
			 poXMLSalida:=  '<NUMERO>' || trim(SQLCODE) || '</NUMERO>';
			 poXMLSalida:= poXMLSalida || '<DESCRIPCION>' || trim(SQLERRM) || '</DESCRIPCION>';

			 RETURN(-2);
  END ObtenerAtributoEntidad;

  FUNCTION ObtenerCuitEntidad(piIDEntidad IN DOCUMENTOS.IDENTIDAD%TYPE,
	  		   				  poCDCUIT	  OUT ENTIDADES.CDCUIT%TYPE,
							  poXMLSalida OUT VARCHAR2) RETURN INTEGER

  IS
  	  /*DADA UNA ENTIDAD, OBTIENE SU NRO DE CUIT*/
  BEGIN

  	   SELECT ENTIDADES.CDCUIT
	   INTO	  poCDCUIT
	   FROM   ENTIDADES
	   WHERE  ENTIDADES.IDENTIDAD=piIDEntidad;


  	   RETURN(0);


  EXCEPTION

   		WHEN NO_DATA_FOUND THEN

			 poXMLSalida:='<DESCRIPCION>NO SE HALLO LA ENTIDAD: ' || piIDEntidad || ' EN LA TABLA ENTIDADES.</DESCRIPCION>';
			 RETURN(-1);

		WHEN OTHERS THEN
			 poXMLSalida:=  '<NUMERO>' || trim(SQLCODE) || '</NUMERO>';
			 poXMLSalida:= poXMLSalida || '<DESCRIPCION>' || trim(SQLERRM) || '</DESCRIPCION>';

			 RETURN(-2);

  END ObtenerCuitEntidad;


  FUNCTION ObtenerTipoPrecio(piCDLUGAR IN MOVMATERIALES.CDLUGAR%TYPE,
  		   					 piDSOBSERVACION IN DETALLEMOVMATERIALES.DSOBSERVACION%TYPE,
							 poTipoPrecio	 OUT INTERFAZBW.CDTIPOPRECIO%TYPE,
							 poXMLSalida	 OUT VARCHAR2) RETURN INTEGER
  IS

  /*OBTIENE EL TIPO DE PRECIO*/

  tmpDSLUGAR	LUGARESVENTA.DSLUGAR%TYPE;

  BEGIN



	   IF piDSOBSERVACION IS NULL OR piDSOBSERVACION IN ('OF','PD','OFESP') THEN -- agrego OFESP  - APW 16/2/2017

		   --Determina si es gastronomia
		   BEGIN

			   SELECT LUGARESVENTA.DSLUGAR
			   INTO	  tmpDSLUGAR
			   FROM   LUGARESVENTA
			   WHERE  LUGARESVENTA.CDLUGAR=piCDLUGAR;
		   EXCEPTION
		   	   WHEN NO_DATA_FOUND THEN
			   		tmpDSLUGAR:=NULL;
		   	   WHEN OTHERS THEN
			   		poXMLSalida:='<NUMERO>' || trim(SQLCODE) || '</NUMERO>';
					poXMLSalida:= poXMLSalida || '<DESCRIPCION>' || trim(SQLERRM) || '</DESCRIPCION>';
					RETURN(-1);
		   END;

		   IF UPPER(tmpDSLUGAR)='S'||CHR(38)||'P FOOD' THEN
		   	  --Canal de gastronomia
			  IF piDSOBSERVACION IS NULL THEN
			  	 poTipoPrecio:='PG';
			  ELSIF piDSOBSERVACION = 'OF' THEN
			  	 poTipoPrecio:='POG';
			  ELSIF piDSOBSERVACION = 'PD' THEN
  			  	 poTipoPrecio:='PDG';
			  END IF;

		   ELSE
		   	  --No es canal de gastronomia
			  IF piDSOBSERVACION IS NULL THEN
			  	 poTipoPrecio:='PL';
			  ELSIF piDSOBSERVACION IN ('OF','OFESP') THEN -- agrego OFESP  - APW 16/2/2017
			  	 poTipoPrecio:='PO';
			  ELSIF piDSOBSERVACION = 'PD' THEN
  			  	 poTipoPrecio:='PD';
			  END IF;
		   END IF;

  	   ELSE
	   		  IF piDSOBSERVACION = 'PR' THEN
			 	--Promocion => Precio Lista
  			 	poTipoPrecio:='PL';
			  ELSIF piDSOBSERVACION = 'PE' THEN
			  	 poTipoPrecio:='PPT';
			  --ELSIF piDSOBSERVACION = 'SOF' THEN
			  ELSIF piDSOBSERVACION = 'SO' THEN
			  	 poTipoPrecio:='PSO';
			  ELSIF piDSOBSERVACION = 'JV' THEN
			  	 poTipoPrecio:='JV';
			  ELSE
			     --No se corresponde con ninguno
--				 poXMLSalida:='<DESCRIPCION>DSOBSERVACION=' || trim(piDSOBSERVACION) || ' debe ser NULL, PR, PE o SOF si no es gastronomia</DESCRIPCION>';
--				 RETURN (-2);
			  	 poTipoPrecio:=NULL;
			  END IF;

		END IF;

		RETURN(0);

  EXCEPTION
  		   WHEN OTHERS THEN
		   	 poXMLSalida:='<NUMERO>' || trim(SQLCODE) || '</NUMERO>';
		 	 poXMLSalida:=poXMLSalida || '<DESCRIPCION>' || trim(SQLERRM) || '</DESCRIPCION>';
  		 	 RETURN(-3);

  END ObtenerTipoPrecio;

  FUNCTION ObtenerTipoCpteVta (piCDCOMPROBANTE IN COMPROBANTES.CDCOMPROBANTE%TYPE,
  		   					   piCDSITUACIONIVA IN MOVMATERIALES.CDSITUACIONIVA%TYPE,
							   poCDGRUPOBW 	   OUT INTERFAZBW.CDCOMPROBANTE%TYPE,
							   poXMLSalida	   OUT VARCHAR2) RETURN INTEGER

  IS

  /*OBTIENE EL TIPO DE COMPROBANTE DE VENTA*/

  --tmpSitIvaMov MOVMATERIALES.CDSITUACIONIVA%TYPE;

  BEGIN

	   SELECT AGRUPACIONCOMPROBANTESBW.CDGRUPOBW
	   INTO	  poCDGRUPOBW
	   FROM	  AGRUPACIONCOMPROBANTESBW
	   WHERE  AGRUPACIONCOMPROBANTESBW.CDCOMPROBANTE=piCDCOMPROBANTE;

	   RETURN(0);


  EXCEPTION
 		WHEN NO_DATA_FOUND THEN
		 	 poXMLSalida:='<DESCRIPCION>NO SE HALLO EL COMPROBANTE: ' || trim(piCDCOMPROBANTE) || ' EN LA TABLA AGRUPACIONCOMPROBANTESBW</DESCRIPCION>';
		 	 RETURN(-1);
		WHEN OTHERS THEN
		 	 poXMLSalida:='<NUMERO>' || trim(SQLCODE) || '</NUMERO>';
		 	 poXMLSalida:=poXMLSalida || '<DESCRIPCION>' || trim(SQLERRM) || '</DESCRIPCION>';
  		 	 RETURN(-2);
  END ObtenerTipoCpteVta ;




  PROCEDURE ObtenerCanal(/*piTipoPrecio IN INTERFAZBW.CDTIPOPRECIO%TYPE,*/
  						piCdLugar	 IN  MOVMATERIALES.CDLUGAR%TYPE,
  		   				poCanal		 OUT INTERFAZBW.CDCANALDISTRIBUCION%TYPE)

  IS

  BEGIN

  	   /*IF piTipoPrecio IN ('PG','PGD','POG') THEN
	   	  poCanal:='GA';
	   ELSIF piTipoPrecio ='PE' THEN
	   	  poCanal:='EX';
	   ELSIF piTipoPrecio ='PPT' THEN
	   	  poCanal:='PT';
	   ELSE
	   	  poCanal:='VS';
	   END IF;*/

	   IF trim(piCdLugar)='1' THEN
	   	  poCanal:='PT';
	   ELSIF trim(piCdLugar)='4' THEN
       	  poCanal:='GA';
	   ELSE
		  poCanal:='VS';
	   END IF;


	   /*
	   if trim(piCdLugar)='1' then
	   	  poCanal:='CM';
	   elsif trim(piCdLugar)='2' then
	   	  poCanal:='VS';
	   elsif trim(piCdLugar)='3' then
     	  poCanal:='TE';
	   elsif trim(piCdLugar)='4' then
       	  poCanal:='SP';
	   elsif trim(piCdLugar)='5' then
       	  poCanal:='CJ';
	   else
		  poCanal:='VS';
	   end if;
	   */
  END ObtenerCanal;





  FUNCTION ObtenerCtoVtaOp(piIDPersonaResponsable IN MOVMATERIALES.IDPERSONARESPONSABLE%TYPE,
						   poLEGAJO				  OUT PERSONAS.CDLEGAJO%TYPE,
						   poXMLSalida	OUT VARCHAR2) RETURN INTEGER
  IS
  /*OBTIENE EL LEGAJO DEL OPERADOR*/

  BEGIN

  		SELECT PERSONAS.CDLEGAJO
		INTO   poLEGAJO
		FROM   PERSONAS
		WHERE  PERSONAS.IDPERSONA=piIDPersonaResponsable;

		RETURN(0);

  EXCEPTION
  		WHEN NO_DATA_FOUND THEN
			 poXMLSalida:='<DESCRIPCION>NO SE HALLO EL LEGAJO DEL OPERADOR: ' || trim(piIDPersonaResponsable);
			 poXMLSalida:= poXMLSalida || ' EN LA TABLA PERSONAS</DESCRIPCION>';

			 RETURN(-1);

		WHEN OTHERS THEN
			 poXMLSalida:=  '<NUMERO>' || trim(SQLCODE) || '</NUMERO>';
			 poXMLSalida:= poXMLSalida || '<DESCRIPCION>' || trim(SQLERRM) || '</DESCRIPCION>';

  			 RETURN(-2);

  END ObtenerCtoVtaOp;


 FUNCTION ObtenerPtoVtaVenta(--piCDLugar IN MOVMATERIALES.CDLUGAR%TYPE,
                 piIdMovMat  in MOVMATERIALES.IDMOVMATERIALES%TYPE,
 		  					 piIdPedido	 IN MOVMATERIALES.IDPEDIDO%TYPE,
							 piIdComisionista IN MOVMATERIALES.IDCOMISIONISTA%TYPE,
							 piIdEntidad	  IN MOVMATERIALES.IDENTIDAD%TYPE,
							 piCDCondicionVenta IN MOVMATERIALES.CDCondicionVenta%TYPE,
 		  					 poPuntoVenta OUT VARCHAR2,
							 poXMLSalida  OUT VARCHAR2) RETURN INTEGER IS

		tmpIdVendedor 		ATRIBUTOSENTIDADES.VLATRIBUTO%TYPE;
		tmpTelemarketer		PEDIDOS.IDPERSONARESPONSABLE%TYPE;
 BEGIN

	  IF ObtenerVendedorEntidad(piIdEntidad,tmpIdVendedor,piidmovmat,poXMLSalida, tmpTelemarketer) !=0 THEN
	  	 --Error al buscar el vendedor de la entidad
		 poXmlSalida:='<FUNCION>ObtenerVendedorEntidad</FUNCION>' || trim(poXMLSalida);
		 RETURN (-1);
	  END IF;


	  IF piIdPedido IS NOT NULL THEN
	  	 --La factura tiene asociado un pedido
		 poPuntoVenta:='TE';
	  ELSIF trim(tmpIdVendedor)!='' THEN
	  	 --El Cliente tiene vendedor Habitual
			 poPuntoVenta:='VD';
	  ELSIF (piIdComisionista IS NOT NULL) AND TO_NUMBER(piCDCondicionVenta)!=5 THEN
	     --La factura tiene comisionista y la cond. de vta es distinta de 5
	  	 poPuntoVenta:='CM';
	  ELSE
	  	  --Si no cumple ninguna condicion, es Vta Salon
		 poPuntoVenta:='VS';
	  END IF;



	  RETURN (0);

  EXCEPTION
	  WHEN OTHERS THEN
			 poXMLSalida:=  '<NUMERO>' || trim(SQLCODE) || '</NUMERO>';
			 poXMLSalida:= poXMLSalida || '<DESCRIPCION>' || trim(SQLERRM) || '</DESCRIPCION>';

  			 RETURN(-2);

  END ObtenerPtoVtaVenta;


  FUNCTION ObtenerLegRespVta(piIDENTIDAD  IN  DOCUMENTOS.IDENTIDAD%TYPE,
		   	     poLegRespVta OUT PERSONAS.CDLEGAJO%TYPE,
               		     piIdMovMat   IN DOCUMENTOS.IDMOVMATERIALES%TYPE,
			     poXMLSalida  OUT VARCHAR2) RETURN INTEGER
  IS

  /*OBTIENE EL LEGAJO DEL VENDEDOR DEL CLIENTE*/

  tmpIDVendedor	 	 PEDIDOS.IDVENDEDOR%TYPE;
  tmpIDTelemarketer	 PEDIDOS.IDPERSONARESPONSABLE%TYPE;

  BEGIN



	  ---------------------------------
	  --Obtiene el vendedor del cliente
	  ---------------------------------
	  IF ObtenerVendedorEntidad(piIdEntidad,tmpIdVendedor,piIdMovMat,poXMLSalida,tmpIDTelemarketer) !=0 THEN
	   	  --Error al intentar obtener el vendedor asociado a la entidad
		  poXMLSalida:='<FUNCION>ObtenerAtributoEntidad</FUNCION>' || poXMLSalida;
		  RETURN(-1);
	   END IF;

	   --Obtiene el legajo del vendedor
	   IF tmpIDVendedor is not null THEN
		   BEGIN
		   		SELECT PERSONAS.CDLEGAJO
				INTO   poLegRespVta
				FROM   PERSONAS
				WHERE  PERSONAS.IDPERSONA=tmpIDVendedor;


		   EXCEPTION
		   		WHEN NO_DATA_FOUND THEN
			 		 --No hallo al vendedor en  PERSONAS
					 poLegRespVta:='999999';

		   END;
	   ELSE

	   	 -- si  no tiene vendedor
	   	 if tmpIDTelemarketer is not null  then

	   		BEGIN
		   		SELECT PERSONAS.CDLEGAJO
				INTO   poLegRespVta
				FROM   PERSONAS
				WHERE  PERSONAS.IDPERSONA=tmpIDTelemarketer;


		   	EXCEPTION
		   		WHEN NO_DATA_FOUND THEN
			 		 --No hallo al vendedor en  PERSONAS
					 poLegRespVta:='999999';

		   	END;
		  else
	   		--No tiene Vendedor ni telemarketer, caso muy dudoso
		  	poLegRespVta:='999999';

	   	  end if;

       	    END IF;

       RETURN(0);



  EXCEPTION
  		   WHEN OTHERS THEN
   			   poXMLSalida:='<NUMERO>' || trim(SQLCODE) || '</NUMERO>';
			   poXMLSalida:=poXMLSalida || '<DESCRIPCION>' || trim(SQLERRM) || '</DESCRIPCION>';

  			   RETURN(-2);


  END ObtenerLegRespVta  ;


  FUNCTION ObtenerRubroCanal(piIDENTIDAD        IN DOCUMENTOS.IDENTIDAD%TYPE,
  		   					 poCDRUBROPRINCIPAL OUT ENTIDADES.CDRUBROPRINCIPAL%TYPE,
							 poCDMAINCANAL		OUT ENTIDADES.CDMAINCANAL%TYPE,
							 poXMLSalida  	    OUT VARCHAR2) RETURN INTEGER

  IS

  /*OBTIENE EL RUBRO Y EL CANAL PRINCIPAL DE UNA ENTIDAD*/

  BEGIN

  	   SELECT ENTIDADES.CDRUBROPRINCIPAL,
	   		  ENTIDADES.CDMAINCANAL
	   INTO	  poCDRUBROPRINCIPAL,
	   		  poCDMainCanal
	   FROM   ENTIDADES
	   WHERE  ENTIDADES.IDENTIDAD=piIDENTIDAD;

	   RETURN(0);


  EXCEPTION
  		   WHEN OTHERS THEN

				poXMLSalida:='<NUMERO>' || trim(SQLCODE) || '</NUMERO>';
				poXMLSalida:=poXMLSalida || '<DESCRIPCION>' || trim(SQLERRM) || '</DESCRIPCION>';

				RETURN(-1);

  END ObtenerRubroCanal;

  /* ******************************************************************
  %v 18/4/13 - APW - Cambio para nuevas tablas de promociones
  %v 23/08/2017 - APW - Cambio para adecuar a los descuentos de frescos
  * *******************************************************************/
  FUNCTION ObtenerFechaPromo(piCDPROMO   IN DETALLEMOVMATERIALES.CDPROMO%TYPE,
                             poDTDESDE   OUT TBLPROMO.VIGENCIA_DESDE%TYPE,
                             poDTHASTA   OUT TBLPROMO.VIGENCIA_HASTA%TYPE,
                             poXMLSalida OUT VARCHAR2) RETURN INTEGER IS

    /*OBTIENE LA FECHA DESDE Y HASTA DE UNA PROMOCION*/
    n_promo integer;
    v_qt integer;

  BEGIN
    IF piCDPROMO IS NOT NULL THEN
      n_promo := tonumber(piCDPROMO); --- APW - Cambio por función de vital que no da error si es alfabético
      if n_promo > 0 then
        -- es una promo verdadera
        SELECT TBLPROMO.VIGENCIA_DESDE, TBLPROMO.VIGENCIA_HASTA
          INTO poDTDESDE, poDTHASTA
          FROM TBLPROMO
         WHERE TBLPROMO.CDPROMO = n_promo;
      else
        -- averiguo si es descuento de frescos
        select count(*)
          into v_qt
          from tbldescuentoarticuloxvencer xv
         where xv.cdbarradescuento = piCDPROMO;
        if v_qt > 0 then
          select xv.dtdesde, xv.dthasta
            into poDTDESDE, poDTHASTA
            from tbldescuentoarticuloxvencer xv
           where xv.cdbarradescuento = piCDPROMO;
        end if;
      end if;
    end if;

    RETURN(0);
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      poDTDESDE := NULL;
      poDTHASTA := NULL;
      RETURN(0);
    WHEN OTHERS THEN
      poXMLSalida := '<NUMERO>' || 'promo' || piCDPROMO || '-' ||trim(SQLCODE) || '</NUMERO>';
      poXMLSalida := poXMLSalida || '<DESCRIPCION>' || trim(SQLERRM) ||'</DESCRIPCION>';
      RETURN(-1);
  END ObtenerFechaPromo;


  FUNCTION ObtenerMotivoNC(piIDMOVMATERIALES IN  DOCUMENTOS.IDMOVMATERIALES%TYPE,
  		   				   poCDMOTIVO		 OUT AUDITORIA.CDMOTIVO%TYPE,
						   poXMLSalida		 OUT VARCHAR2) RETURN INTEGER

  IS

  /*OBTIENE EL MOTIVO DE UNA NOTA DE CREDITO*/

  BEGIN

  	   SELECT AUDITORIA.CDMOTIVO
	   INTO	  poCDMOTIVO
	   FROM   AUDITORIA
	   WHERE  AUDITORIA.SQREIMPRESION IS NULL AND
	   		  AUDITORIA.SQDETALLEMOVMATERIALES IS NULL AND
	   		  AUDITORIA.IDMOVMATERIALES =  piIDMOVMATERIALES;

	   RETURN(0);

  EXCEPTION
  	   WHEN TOO_MANY_ROWS THEN
	   		BEGIN

				 SELECT AUDITORIA.CDMOTIVO
	   			 INTO	  poCDMOTIVO
	   			 FROM   AUDITORIA
	   			 WHERE  AUDITORIA.CDMOTIVO IS NOT NULL AND
				 		AUDITORIA.SQREIMPRESION IS NULL AND
	   		  	 		AUDITORIA.SQDETALLEMOVMATERIALES IS NULL AND
	   		  			AUDITORIA.IDMOVMATERIALES =  piIDMOVMATERIALES AND
						ROWNUM<2;

						RETURN(0);

			EXCEPTION
				WHEN OTHERS THEN
					  	poXMLSalida:='<NUMERO>'      || trim(SQLCODE) || '</NUMERO>';
						poXMLSalida:=poXMLSalida || '<DESCRIPCION>' || trim(SQLERRM) || '</DESCRIPCION>';

  						RETURN(-3);
			END;

	   WHEN NO_DATA_FOUND THEN
			/* dff 20/10/2004 se comento para que pasen todas las nc
	   	 	poXMLSalida:='<DESCRIPCION>NO SE HALLO EL MOTIVO DE LA NOTA DE CREDITO: ' || trim(piIDMOVMATERIALES) || ' EN LA TABLA AUDITORIA</DESCRIPCION>';

	   		RETURN(-1);*/
			RETURN(0);
	   WHEN OTHERS THEN

			poXMLSalida:='<NUMERO>'      || trim(SQLCODE) || '</NUMERO>';
			poXMLSalida:=poXMLSalida || '<DESCRIPCION>' || trim(SQLERRM) || '</DESCRIPCION>';

  			RETURN(-2);

  END ObtenerMotivoNC;


  FUNCTION TipoDespacho(piEsPedido	 	  IN BOOLEAN,
  		   				piIDCOMISIONISTA  IN MOVMATERIALES.IDCOMISIONISTA%TYPE,
						piIDDOCTRX 		  IN DOCUMENTOS.IDDOCTRX%TYPE,
  						poTipoDespacho	  OUT VARCHAR2,
						poXMLSalida	  	  OUT VARCHAR2) RETURN INTEGER
  IS

  /*OBTIENE EL TIPO DE DESPACHO*/

  tmpTieneGuia INTEGER;

  BEGIN
  	   IF piEsPedido=TRUE THEN
	   	  --Default para los pedidos
		  poTipoDespacho:='RS';
	   ELSE
	   	  --Es una venta
	   	  IF piIDCOMISIONISTA IS NOT NULL THEN
		  	 --Tiene comisionista
		  	 poTipoDespacho:='ERI';
		  ELSE
		  	 --No tiene comisionista

			 BEGIN
				 --determina si tiene una guia asociada
				 SELECT COUNT(*)
				 INTO   tmpTieneGuia
				 FROM   DETALLEGUIADETRANSPORTE
				 WHERE  DETALLEGUIADETRANSPORTE.IDDOCTRX = piIDDOCTRX;

			 EXCEPTION
			 	  WHEN OTHERS THEN

						poXMLSalida:='<NUMERO>'  || trim(SQLCODE) || '</NUMERO>';
						poXMLSalida:=poXMLSalida || '<DESCRIPCION>' || trim(SQLERRM) || '</DESCRIPCION>';

	  					RETURN (-1);
			 END;

			 IF tmpTieneGuia>0 THEN
			 	--Tiene una guia de transporte asociada
				poTipoDespacho:='ERM';
			 ELSE
			 	--No tiene una guia de transporte asociada
	   		 	poTipoDespacho:='RS';
			 END IF;
		  END IF;
	   END IF;

	   RETURN (0);

  END TipoDespacho;


  FUNCTION ObtenerCantVendidas(piVLUXB 	        IN DETALLEMOVMATERIALES.VLUXB%TYPE,
  		   					   piCDUNIDADMEDIDA IN DETALLEMOVMATERIALES.CDUNIDAMEDIDA%TYPE,
			 				   piQTUNIDAD 	 	IN DETALLEMOVMATERIALES.QTUNIDAdmOV%TYPE,
							   poCantVendidas	OUT INTERFAZBW.QTBULTOS%TYPE,
							   poXMLSalida 	 	OUT VARCHAR2) RETURN INTEGER

  IS

  /*CALCULA LA CANTIDAD DE BULTOS VENDIDOS*/

  BEGIN

  	/*
	IF piCDUNIDADMEDIDA IN ('KG','PZA') THEN
	   -- Pieza (PZA) o  Kilogramo (KG)
	   poCantVendidas:=0;

	   RETURN(0);

	ELSIF piCDUNIDADMEDIDA IN ('UN','BTO') THEN
	   --Bulto (BTO) o Unidad (UN)
	   IF piVLUXB IS NOT NULL THEN
	   	   IF piVLUXB !=0 THEN
		   	  poCantVendidas:=NVL(piQTUNIDAD/piVLUXB,0);

		      RETURN(0);
		   ELSE

		   	  poXMLSalida:='<MENSAJE>LA UNIDAD X BULTO ES CERO</MENSAJE>';
		   	  RETURN(-1);
		   END IF;
	   ELSE
		  poXMLSalida:='<MENSAJE>LA UNIDAD X BULTO ES NULL</MENSAJE>';
	   	  RETURN (-1);
	   END IF;
	ELSE
		--Unidad de medida no contemplada
		poXMLSalida:='<MENSAJE>LA UNIDAD DE MEDIDA: ' || trim(piCDUNIDADMEDIDA) || ' NO ESTA CONTEMPLADA</MENSAJE>';

		RETURN(-2);
	END IF;
*/

    --IF trim(piCDUNIDADMEDIDA) IN ('UN','PZA','KG') THEN
	IF trim(piCDUNIDADMEDIDA) = 'UN' THEN
	   poCantVendidas:=0;

	   RETURN(0);

	ELSIF trim(piCDUNIDADMEDIDA) IN ('PZA','KG') THEN
	   --Bulto (BTO) o Pieza (PZA)
	   poCantVendidas:=NVL(piQTUNIDAD,0);

	   RETURN(0);

	ELSIF Trim(piCDUNIDADMEDIDA) IN ('BTO') THEN
	   --Unidad (UN) o Kilogramo (KG)
	   IF piVLUXB IS NOT NULL THEN
	   	   IF piVLUXB !=0 THEN
			  /*poCantVendidas:=NVL(piQTUNIDAD*piVLUXB,0);*/
		   	  poCantVendidas:=NVL(piQTUNIDAD,0);
		      RETURN(0);
		   ELSE

		   	  poXMLSalida:='<MENSAJE>LA UNIDAD X BULTO ES CERO</MENSAJE>';
		   	  RETURN(-1);
		   END IF;
	   ELSE
		  poXMLSalida:='<MENSAJE>LA UNIDAD X BULTO ES NULL</MENSAJE>';
	   	  RETURN (-1);
	   END IF;
	ELSE
		--Unidad de medida no contemplada
		poXMLSalida:='<MENSAJE>LA UNIDAD DE MEDIDA: ' || trim(piCDUNIDADMEDIDA) || ' NO ESTA CONTEMPLADA</MENSAJE>';

		RETURN(-2);
	END IF;

  EXCEPTION
  		   WHEN OTHERS THEN
		   		poXMLSalida:='<NUMERO>' || trim(SQLCODE) || '</NUMERO>';
				poXMLSalida:='<DESCRIPCION>' || trim(SQLERRM) || '</DESCRIPCION>';
				RETURN(-3);
  END ObtenerCantVendidas;



  FUNCTION InsertarInterfazBW(piRegBw IN INTERFAZBW%ROWTYPE,poXMLSalida OUT VARCHAR2) RETURN INTEGER
  IS

  /*INSERTA UN REGISTRO EN LA TABLA InsertarInterfazBW*/

  BEGIN

  	   INSERT INTO INTERFAZBW(INTERFAZBW.IDINTERFAZ,
	   		  	   			  INTERFAZBW.CDCANALDISTRIBUCION,
	   		  	   			  INTERFAZBW.NRCLIENTE,
							  INTERFAZBW.NRLEGAJO,
							  INTERFAZBW.CDLEGAJOREGISTRO,
							  INTERFAZBW.CDPTOVENTA,
							  INTERFAZBW.CDARTICULO,
							  INTERFAZBW.CDNIVELACTIVIDAD,
							  INTERFAZBW.CDORGVTA,
							  INTERFAZBW.CDLEGAJOVENDEDOR,
							  INTERFAZBW.CDRUBROCLIENTE,
							  INTERFAZBW.CDSUCURSAL,
							  INTERFAZBW.CDPROMO,
							  INTERFAZBW.DTINICIOPROMO,
							  INTERFAZBW.DTFINPROMO,
							  INTERFAZBW.CDMOTIVONC,
							  INTERFAZBW.CDCONDVTA,
							  INTERFAZBW.CDCOMPROBANTE,
							  INTERFAZBW.NRCOMISIONISTA,
							  INTERFAZBW.SQCOMPROBANTE,
							  INTERFAZBW.SQLINEA,
							  INTERFAZBW.DTDOCUMENTO,
							  INTERFAZBW.CDSTATUSPEDIDO,
							  INTERFAZBW.CDCANALCLIENTE,
							  INTERFAZBW.CDTIPODESPACHO,
							  INTERFAZBW.CDTIPOPRECIO,
							  INTERFAZBW.CDTIPOPROMO,
							  INTERFAZBW.AMLINEA,
							  INTERFAZBW.ICPRIMERALINEA,
							  INTERFAZBW.QTBULTOS,
							  INTERFAZBW.QTMOVPROMO,
							  INTERFAZBW.QTMOV,
							  INTERFAZBW.QTMOVPEDIDO,
							  INTERFAZBW.AMLINEAPEDIDO,
							  INTERFAZBW.DTCOMPROBANTE,
							  INTERFAZBW.CMP,
							  INTERFAZBW.CDUNIDADMOV,
							  INTERFAZBW.CDTIPOLINEA,
							  INTERFAZBW.DSFECHACOMPROBANTE,
							  INTERFAZBW.DTPROCESO,
							  INTERFAZBW.CDCUIT,
							  interfazbw.ID_REGLA,
							  interfazbw.APLICA,
							  interfazbw.FACTOR,
							  interfazbw.PORCENTAJE,
                interfazbw.id_canal,
                interfazbw.ampreciounitario,
                interfazbw.dsobservacion,
                interfazbw.iddoctrx   )
					VALUES   (SYS_GUID(),
							  piRegBw.CDCANALDISTRIBUCION,
	   		  	   			  piRegBw.NRCLIENTE,
							  piRegBw.NRLEGAJO,
							  piRegBw.CDLEGAJOREGISTRO,
							  piRegBw.CDPTOVENTA,
							  piRegBw.CDARTICULO,
							  piRegBw.CDNIVELACTIVIDAD,
							  piRegBw.CDORGVTA,
							  piRegBw.CDLEGAJOVENDEDOR,
							  piRegBw.CDRUBROCLIENTE,
							  piRegBw.CDSUCURSAL,
							  piRegBw.CDPROMO,
							  piRegBw.DTINICIOPROMO,
							  piRegBw.DTFINPROMO,
							  piRegBw.CDMOTIVONC,
							  piRegBw.CDCONDVTA,
							  piRegBw.CDCOMPROBANTE,
							  piRegBw.NRCOMISIONISTA,
							  piRegBw.SQCOMPROBANTE,
							  piRegBw.SQLINEA,
							  piRegBw.DTDOCUMENTO,
							  piRegBw.CDSTATUSPEDIDO,
							  piRegBw.CDCANALCLIENTE,
							  piRegBw.CDTIPODESPACHO,
							  piRegBw.CDTIPOPRECIO,
							  piRegBw.CDTIPOPROMO,
							  piRegBw.AMLINEA,
							  piRegBw.ICPRIMERALINEA,
							  piRegBw.QTBULTOS,
							  piRegBw.QTMOVPROMO,
							  piRegBw.QTMOV,
							  piRegBw.QTMOVPEDIDO,
							  piRegBw.AMLINEAPEDIDO,
							  piRegBw.DTCOMPROBANTE,
							  piRegBw.CMP,
							  piRegBw.CDUNIDADMOV,
							  piRegBw.CDTIPOLINEA,
							  piRegBw.DSFECHACOMPROBANTE,
							  piRegBw.DTPROCESO,
							  piRegBw.CDCUIT,
							  piRegBw.id_regla,
							  piRegBw.Aplica,
							  piRegBw.factor,
							  piRegBw.porcentaje,
                piRegBw.Id_Canal,
                piRegBw.Ampreciounitario,
                piRegBw.Dsobservacion,
                piRegBw.Iddoctrx);

		RETURN (0);

  EXCEPTION
  		WHEN OTHERS THEN
 			 poXMLSalida:= '<NUMERO>' || trim(SQLCODE) || '</NUMERO>';
 			 poXMLSalida:= poXMLSalida || '<DESCRIPCION>' || trim(SQLERRM) || '</DESCRIPCION>';

			 RETURN (-1);
  END InsertarInterfazBW;


  FUNCTION ObtenerDatosMovimiento(piIDMOVMATERIALES  IN DOCUMENTOS.IDMOVMATERIALES%TYPE,
  		   						  poRegMovMateriales OUT MOVMATERIALES%ROWTYPE,
								  poXMLMensaje 		 OUT VARCHAR2) RETURN INTEGER

  IS

  /*DEVUELVE TODOS LOS CAMPOS DE UN MOVIMIENTO*/

  BEGIN
  		   SELECT *
		   INTO   poRegMovMateriales
		   FROM   MOVMATERIALES
		   WHERE  MOVMATERIALES.IDMOVMATERIALES=piIDMOVMATERIALES;

  		   RETURN (0);

  EXCEPTION
  		   WHEN NO_DATA_FOUND THEN
		   		--No existe el pedido
				poXMLMensaje:='<DESCRIPCION>NO EXISTE EL MOVIMIENTO DE Materiales: ' || trim(piIDMOVMATERIALES) || '</DESCRIPCION>';
				RETURN(-1);
		   WHEN OTHERS THEN
				poXMLMensaje:= '<NUMERO>' || trim(SQLCODE) || '</NUMERO>';
				poXMLMensaje:= poXMLMensaje || '<DESCRIPCION>' || trim(SQLCODE) || '</DESCRIPCION>';
  				RETURN (-2);

  END ObtenerDatosMovimiento;

 PROCEDURE GrabarLog(iXMLSuceso IN VARCHAR2,iCDSucursal IN LOGINTERFACES.CDSUCURSAL%TYPE) IS

 /*INSERTA EN LA TABLA LOGINTERFACES*/
 PRAGMA AUTONOMOUS_TRANSACTION;
 BEGIN

 		INSERT INTO LOGINTERFACES (DTPROCESO,
			 					 IDPROCESO,
								 CDINTERFAZ,
								 DSSUCESO,
								 CDSUCURSAL)
			 			 VALUES (SYSDATE,
						 		 sys_guid(),
								 'IBW',
								 iXMLSuceso,
								 iCDSucursal);
                commit;

 exception
  when others then
      null;
 END GrabarLog;


  FUNCTION ObtenerDatosCamposDOC(piRegDocumentos IN DOCUMENTOS%ROWTYPE,
								poRegInterfazBW IN OUT INTERFAZBW%ROWTYPE,
								poXMLMensaje	OUT VARCHAR2) RETURN INTEGER

  IS

	  /**************************************************
	  CALCULA LOS VALORES QUE DEPENDEN SOLO DEL DOCUMENTO
	  ***************************************************/

	  tmpSalida INTEGER;
	  tmpXMLMensaje VARCHAR2(4000);


  BEGIN

      --Inicio - MarianoL 15/07/2013: modificación para migracion de BO a BW
		  poRegInterfazBW.Iddoctrx := piRegDocumentos.Iddoctrx;
      --Fin - MarianoL 15/07/2013: modificación para migracion de BO a BW

  	   --NRCLIENTE (ZCLIENTE)
	   tmpSalida:=ObtenerAtributoEntidad (piRegDocumentos.IDENTIDAD, piRegDocumentos.CDSUCURSAL,
							     		  'NROVIEJO', poRegInterfazBW.NRCLIENTE , tmpXMLMensaje);

	   IF tmpSalida=-1 THEN
	   	  --No hallo el atributo
		  /*poXMLMensaje:='<DESCRIPCION>NO SE HALLO EL NUMERO DEL CLIENTE: ' || trim(piRegDocumentos.IDENTIDAD);
		  poXMLMensaje:= poXMLMensaje || ' DE LA SUCURSAL: ' || trim(piRegDocumentos.CDSUCURSAL) || ' EN LA TABLA ATRIBUTOSENTIDADES</DESCRIPCION>';
		  RETURN (-1);*/
		  poRegInterfazBW.NRCLIENTE:='999999';
	   ELSIF tmpSalida=-2 THEN
	   	  poXMLMensaje:='<FUNCION>OBTENERATRIBUTOENTIDAD</FUNCION>' || tmpXMLMensaje;
		  RETURN (-1);
	   END IF;


	   --CDORGVTA (ZORG_VTA1)
	   poRegInterfazBW.CDORGVTA:='VTO';


	   --CDLEGAJOVENDEDOR (ZRES_VTA)
	   tmpSalida:=ObtenerLegRespVta(piRegDocumentos.IDENTIDAD,
							        poRegInterfazBW.CDLEGAJOVENDEDOR,
                      piregdocumentos.idmovmateriales,
							 		tmpXMLMensaje);

	   IF tmpSalida!=0 THEN
	   	  --Error indeterminado
		  poXMLMensaje:='<FUNCION>ObtenerLegRespVta</FUNCION>' || tmpXMLMensaje;
	   	  RETURN(-1);
	   END IF;


	   --CDRUBROCLIENTE , CDCANALCLIENTE (ZRUB_COM , ZTIP_CLIE)
	   tmpSalida:=ObtenerRubroCanal(piRegDocumentos.IDENTIDAD,
  		   					 		poRegInterfazBW.CDRUBROCLIENTE,
							 		poRegInterfazBW.CDCANALCLIENTE,
							 		tmpXMLMensaje);

	   	IF tmpSalida!=0 THEN
		   poXMLMensaje:='<FUNCION>ObtenerRubroCanal</FUNCION>' || tmpXMLMensaje ;
	   	   RETURN (-1);
		END IF;


		--CDSUCURSAL (ZSUCURS1)
		poRegInterfazBW.CDSUCURSAL:=piRegDocumentos.CDSUCURSAL;


		--CDMOTIVONC (ZMOT_ACOM)
		IF piRegDocumentos.AMDOCUMENTO < 0 THEN
		   --Nota de credito

		   tmpSalida:=ObtenerMotivoNC(piRegDocumentos.IDMOVMATERIALES,
  		   				   			  poRegInterfazBW.CDMOTIVONC,
						   			  tmpXMLMensaje);

		   IF tmpSalida!=0 THEN
		   	   --Error en la funcion
			   poXMLMensaje:='<FUNCION>ObtenerMotivoNC</FUNCION>' || tmpXMLMensaje;
	   	       RETURN (-1);
		   END IF;
		ELSE
			--No es una nota de credito
			poRegInterfazBW.CDMOTIVONC:=0;
		END IF;


		--SQCOMPROBANTE (ZNRO_PED)
		poRegInterfazBW.SQCOMPROBANTE:=piRegDocumentos.SQCOMPROBANTE;

		--DTDOCUMENTO (ZSTA_FECH)
		poRegInterfazBW.DTDOCUMENTO := piRegDocumentos.DTDOCUMENTO;


		--DTCOMPROBANTE (0CALDAY)
		poRegInterfazBW.DTCOMPROBANTE:= piRegDocumentos.DTDOCUMENTO;


		--CMP (ZCOMPR)
		poRegInterfazBW.CMP:='CPT';

		--DSFECHACOMPROBANTE (0CALMONTH)
		poRegInterfazBW.DSFECHACOMPROBANTE:=TO_CHAR(piRegDocumentos.DTDOCUMENTO,'MMYYYY');

		--CDCUIT
		tmpSalida:=ObtenerCuitEntidad(piRegDocumentos.IDEntidad, poRegInterfazBW.CDCUIT,tmpXMLMensaje);

		IF tmpSalida!=0 THEN
		   --Error en la funcion
		   poXMLMensaje:='<FUNCION>ObtenerCuitEntidad</FUNCION>' || tmpXMLMensaje ;
	   	   RETURN (-1);
		END IF;

		--- ACV 03/04/2010 cambios por definicion de A.Gonzalez---
		if piRegDocumentos.Cdcomprobante = 'FCEE' or piregDocumentos.Cdcomprobante = 'NCEE' then
			--- por default ---
			poRegInterfazBW.Cdorgvta := 'VEX';

			--- verifico si es de zona franca ---
			if ClteDeZonaFranca(piRegDocumentos.IDentidad) = 1 then
				poRegInterfazBW.cdorgvta := 'VZF';
			end if;
		end if;


		if trim(piRegDocumentos.IDentidad) = trim(GetVlParametro('CdConsFinal','General')) or
			trim(piRegDocumentos.IDentidad) = 'IdCfReparto' then

			if trim(piRegDocumentos.IDentidad) <> 'IdCfReparto' then
        --- APW 22/5/14 - no se graba mas el -
				--if instr(piRegDocumentos.dsreferencia,'-(') >= 1   then
        if instr(piRegDocumentos.dsreferencia,'(') >= 1   then
					tmpSalida := GetCuitRef(piRegDocumentos.dsreferencia, poRegInterfazBW.CDCUIT);
				end if;
			else
				tmpSalida := GetCuitReferenciado(piRegDocumentos.IDMOVMATERIALES, poRegInterfazBW.CDCUIT);
			end if;

			if  substr(piRegDocumentos.CdComprobante,1,2) = 'FC' then
				poRegInterfazBW.CDcomprobante := 'FF';
			end if;
			if  substr(piRegDocumentos.CdComprobante,1,2) = 'NC' then
				poRegInterfazBW.CDcomprobante := 'NF';
			end if;
		end if;



		RETURN(0);

  EXCEPTION
  		   WHEN OTHERS THEN
		   		poXMLMensaje:='<NUMERO>' || trim(SQLCODE) || '</NUMERO>';
				poXMLMensaje:= poXMLMensaje || '<DESCRIPCION>' || trim(SQLERRM) || '</DESCRIPCION>';

				RETURN(-2);

  END ObtenerDatosCamposDOC;


  FUNCTION ObtenerDatosCamposMOV(piRegDocumentos IN DOCUMENTOS%ROWTYPE,
  		   						 piRegMovMateriales IN MOVMATERIALES%ROWTYPE,
								 poRegInterfazBW IN OUT INTERFAZBW%ROWTYPE,
								 poXMLMensaje	OUT VARCHAR2) RETURN INTEGER

  IS

	  /**********************************************
	  CALCULA LOS VALORES QUE DEPENDEN DEL MOVIMIENTO
	  ***********************************************/

	  tmpSalida INTEGER;
	  tmpXMLMensaje VARCHAR2(4000);


  BEGIN


	   --NRLEGAJO (ZCTO_VTA1)
	   IF piRegMovMateriales.IDCOMISIONISTA IS NOT NULL THEN
	   	  tmpSalida:=ObtenerAtributoEntidad (piRegMovMateriales.IDCOMISIONISTA ,
		  									 piRegDocumentos.CDSUCURSAL,
							     		  	 'LEGAJO',
											 poRegInterfazBW.NRLEGAJO ,
											 tmpXMLMensaje);

		   IF tmpSalida=-1 THEN
		   	  --No hallo el atributo
			  poRegInterfazBW.NRLEGAJO:='999999';
		   ELSIF tmpSalida=-2 THEN
		   	  poXMLMensaje:='<FUNCION>OBTENERATRIBUTOENTIDAD</FUNCION>' || tmpXMLMensaje;
			  RETURN (-1);
		   END IF;
       ELSE
	   	   poRegInterfazBW.NRLEGAJO:='999999';
	   END IF;



	   --CDLEGAJOREGISTRO (ZCTO_VTA2)
	   tmpSalida:=ObtenerCtoVtaOp(piRegMovMateriales.IDPersonaResponsable,
						   		  poRegInterfazBW.CDLEGAJOREGISTRO,
						   		  tmpXMLMensaje);
	   IF tmpSalida!=0 THEN
	   	  --Error
		  poXMLMensaje:='<FUNCION>OBTENERCTOVTAOP</FUNCION>' || tmpXMLMensaje;
		  RETURN (-1);
	   END IF;


	   --CDPTOVENTA (ZPTO_VTA1)
	   /*tmpSalida:=ObtenerPtoVtaVenta(piRegMovMateriales.CDLUGAR,
 		  					         poRegInterfazBW.CDPTOVENTA,
							 		 tmpXMLMensaje);*/
		/*tmpSalida:=ObtenerPtoVtaVenta(piRegMovMateriales.CDLUGAR,
									  piRegMovMateriales.CDCONDICIONVENTA,
 		  					         poRegInterfazBW.CDPTOVENTA,
							 		 tmpXMLMensaje);*/

		IF trim(piRegDocumentos.CDCOMPROBANTE) IN ('FCEE','NCEE') THEN
		   --Factura o nota de cr¿dito de exportaci¢n
		   poRegInterfazBW.CDPTOVENTA:='EX';

		ELSE
		   tmpSalida:=ObtenerPtoVtaVenta(
                       piregmovmateriales.idmovmateriales,
                       piRegMovMateriales.IDPEDIDO,
									  	 piRegMovMateriales.IDCOMISIONISTA,
									  	 piRegMovMateriales.IDENTIDAD,
                       piRegMovMateriales.CDCONDICIONVENTA,
 		  					         	 poRegInterfazBW.CDPTOVENTA,
							 		 	 tmpXMLMensaje);

	       IF tmpSalida!=0 THEN
	   	   	  --Error
		  	  poXMLMensaje:='<FUNCION>ObtenerPtoVtaVenta</FUNCION>' || tmpXMLMensaje;
	  	  	  RETURN (-1);
	       END IF;
	   END IF;



	   --CDNIVELACTIVIDAD (ZNIV_CTE1)
	   poRegInterfazBW.CDNIVELACTIVIDAD:=NULL;


	   --CDCONDVTA (ZTIP_CVTU)
	   poRegInterfazBW.CDCONDVTA := NVL(piRegMovMateriales.CDCONDICIONVENTA,0);


	   --CDCOMPROBANTE (ZTIP_CVTA)
	   tmpSalida:=ObtenerTipoCpteVta (piRegDocumentos.CDCOMPROBANTE,
  		   				   			  piRegMovMateriales.CDSITUACIONIVA,
									  poReginterfazbw.CDCOMPROBANTE,
						   			  tmpXMLMensaje);

	   IF tmpSalida!=0 THEN
	  	  --error
		  poXMLMensaje:='<FUNCION>ObtenerTipoCpteVta</FUNCION>' || tmpXMLMensaje;
	  	  RETURN (-1);
	   END IF;


	   --NRCOMISIONISTA (ZCOMISION)
	   IF piRegMovMateriales.IDCOMISIONISTA IS NULL THEN
	   	  poRegInterfazBW.NRCOMISIONISTA:=NULL;

	   ELSE
		   /*tmpSalida:= ObtenerAtributoEntidad (piRegMovMateriales.IDCOMISIONISTA, piRegDocumentos.CDSUCURSAL,
								     		   'NUMERO', poRegInterfazBW.NRCOMISIONISTA, tmpXMLMensaje);*/

			tmpSalida:= ObtenerAtributoEntidad (piRegMovMateriales.IDCOMISIONISTA, piRegDocumentos.CDSUCURSAL,
								     		   'NROVIEJO', poRegInterfazBW.NRCOMISIONISTA, tmpXMLMensaje);

		   IF tmpSalida=-1 THEN
		   	  /*poXMLMensaje:='<FUNCION>ObtenerAtributoEntidad</FUNCION>';
		   	  poXMLMensaje:= poXMLMensaje || '<DESCRIPCION>NO SE HALLO EL NRO DEL COMISIONISTA: ' || trim(piRegMovMateriales.IDCOMISIONISTA) || ' DE LA SUCURSAL: ' || trim(piRegDocumentos.CDSUCURSAL);
			  poXMLMensaje:= poXMLMensaje || ' EN LA TABLA ATRIBUTOSENTIDADES</DESCRIPCION>';
			  RETURN (-1);*/
			  poRegInterfazBW.NRCOMISIONISTA:=NULL;

		   ELSIF tmpSalida=-2 THEN
		      poXMLMensaje:='<FUNCION>ObtenerAtributoEntidad</FUNCION>' || tmpXMLMensaje;
			  RETURN (-1);
		   END IF;
	   END IF;


	   --CDTIPODESPACHO (ZTIP_DESP)
	   tmpSalida:=TipoDespacho(FALSE, piRegMovMateriales.IDCOMISIONISTA, piRegDocumentos.IDDOCTRX,
  							   poRegInterfazBW.CDTIPODESPACHO, tmpXMLMensaje);

	   IF tmpSalida!=0 THEN
	   	  --Error
		  poXMLMensaje:='<FUNCION>TipoDespacho</FUNCION>' || tmpXMLMensaje;
		  RETURN (-1);
	   END IF;

      --Inicio MarianoL 29/05/2013 -- Agragar información del canal de venta
      -- APW 29/4/15 - el GetCanalVentaBW distingue entre TE y EC (e-commerce)
		poRegInterfazBW.Id_Canal := posapp.pkg_canal.GetCanalVentaBW(piRegMovMateriales.Idmovmateriales);
      --Fin MarianoL 29/05/2013 -- Agragar información del canal de venta

	   RETURN (0);

  EXCEPTION
  		   WHEN OTHERS THEN
		   		poXMLMensaje:='<NUMERO>' || trim(SQLCODE) || '</NUMERO>';
				poXMLMensaje:= poXMLMensaje || '<DESCRIPCION>' || trim(SQLERRM) || '</DESCRIPCION>';

				RETURN(-2);

  END ObtenerDatosCamposMOV;


  /********************************************************************************************
   Fecha        Programador   Descripci¢n
   -------------------------------------------------------------------------------------------
   09/08/2004   F.Mor¢n       Se agregan dos par metros de entrada:
                                piPVMCdPromo: C¢digo de promociones marketec
                                piPVMMotivoNC: C¢digo de motivo
                              Para las notas de cr¿dito por promociones marketec, se carga el
                              campo CDPROMO con el valor pasado en piPVMCdPromo
  ********************************************************************************************/
  FUNCTION ObtenerDatosCamposDM( piRegDocumentos IN DOCUMENTOS%ROWTYPE,
  		   						 piRegMovMateriales IN MOVMATERIALES%ROWTYPE,
								 piRegDMovMateriales DETALLEMOVMATERIALES%ROWTYPE,
                                 piPVMCdPromo IN INTERFAZBW.CDPROMO%TYPE,
                                 piPVMMotivoNC IN INTERFAZBW.CDMOTIVONC%TYPE,
								 poRegInterfazBW IN OUT INTERFAZBW%ROWTYPE,
								 poXMLMensaje	OUT VARCHAR2) RETURN INTEGER

  IS


	  /*******************************************************
	  CALCULA LOS VALORES QUE DEPENDEN DE DETALLEMOVMATERIALES
	  ********************************************************/

	  tmpSalida INTEGER;
	  tmpXMLMensaje VARCHAR2(4000);
	  msgerr integer;
	  fchpedido DATE;
	  o_idregla TBLREGLA_DETMOVMAT.id_regla%type;
	  o_aplico TBLREGLA_DETMOVMAT.aplica%type;
	  o_porc number;
	  o_factor number;


        -- 05/04/2005   Hernan Azpilcueta
        -------------------------------------------------------------
        FUNCTION EsNcVoucher(piidmovmateriales IN MOVMATERIALES.IDMOVMATERIALES%TYPE, piPVMMotivoNC IN MOTIVOS.CDMOTIVO%TYPE) RETURN BOOLEAN IS
            nCant INTEGER;
        BEGIN
             SELECT COUNT(*) INTO nCant
               FROM AUDITORIA
              WHERE idmovmateriales = piidmovmateriales
                AND cdmotivo = piPVMMotivoNC;
            RETURN (nCant > 0);
        END EsNcVoucher;
        -------------------------------------------------------------

  BEGIN

	   --CDTIPOPRECIO (ZTIP_PREC)
	   tmpSalida:=ObtenerTipoPrecio(piRegMovMateriales.CDLUGAR,
  		   					 		piRegDMovMateriales.DSOBSERVACION,
							 		poRegInterfazBW.CDTIPOPRECIO,
							 		tmpXMLMensaje);

       /*--- ACV 12/10/2012  modificacion de precios de tapa  ---*/
       if piRegMovmateriales.idpedido is not null then
          /*19/01/2015 MarianoL: la marca de tapa aplica a todos los pedidos no solo a vendedores*/
          --if EspedidoVendedor(piRegMovmateriales.idpedido) = 1 then
          fchpedido := GetFechaPedido(piRegMovmateriales.idpedido);
         --ChM 13/09/2022 agrego canal para DISTRIVE y DISTRICO 
         if piRegMovmateriales.Id_Canal='CO' then
              if  EsPrecioDeTapa(piRegDMovMateriales.CDARTICULO, fchpedido, 'DISTRICO') = 1  then
                   poRegInterfazBW.CDTIPOPRECIO := 'TP';
               end if;  
           else
               if  EsPrecioDeTapa(piRegDMovMateriales.CDARTICULO, fchpedido, 'DISTRIVE') = 1  then
                   poRegInterfazBW.CDTIPOPRECIO := 'TP';
               end if;  
         end if;  
       	 
          --end if;
       end if;
       /*---  fin de modificacion de precio de tapa ---*/

       IF tmpSalida!=0 THEN
	   	  --Error
		  poXMLMensaje:='<FUNCION>ObtenerTipoPrecio</FUNCION>' || tmpXMLMensaje;
		  RETURN(-1);
	   END IF;

	   --CDCANALDISTRIBUCION (ZCAN_DIS1)

	   IF TRIM(piRegDocumentos.CDCOMPROBANTE) IN ('FCEE','NCEE') THEN
	   	  --FACTURAS Y NOTAS DE CREDITO DE EXPEDICION
	   	  poRegInterfazBW.CDCANALDISTRIBUCION:='EX';
	   ELSE
	   	  --ObtenerCanal(poRegInterfazBW.CDTIPOPRECIO,poRegInterfazBW.CDCANALDISTRIBUCION);
		  ObtenerCanal(piRegMovMateriales.CDLUGAR,poRegInterfazBW.CDCANALDISTRIBUCION);
	   END IF;

	   --CDARTICULO (ZMATERIAL)
	   poRegInterfazBW.CDARTICULO :=piRegDMovMateriales.CDARTICULO;

       -- FEM - 09/08/2004
       -- Al cargar el campo CDPROMO, se tienen en cuenta las promociones marketec
	   --CDPROMO (ZNRO_PROM)
	   --poRegInterfazBW.CDPROMO := piRegDMovMateriales.CDPROMO;
       IF SUBSTR(piRegDocumentos.cdcomprobante, 1, 2) = 'NC' THEN
           -- Es una nota de cr¿dito

           -- 05/04/2005    Hernan Azpilcueta   Porque puede tener mas de un motivo.
           -------------------------------------------------------
           /*
           IF poRegInterfazBW.CDMotivoNC = piPVMMotivoNC THEN
               -- Es una nota de cr¿dito de promociones marketec
               poRegInterfazBW.CDPROMO := piPVMCdPromo;
           ELSE
               poRegInterfazBW.CDPROMO := piRegDMovMateriales.CDPROMO;
           END IF;
           */
           IF EsNcVoucher(piRegMovMateriales.idmovmateriales, piPVMMotivoNC) THEN
               poRegInterfazBW.CDPROMO := piPVMCdPromo;
           ELSE
               poRegInterfazBW.CDPROMO := piRegDMovMateriales.CDPROMO;
           END IF;
           -------------------------------------------------------
       ELSE
           -- No es una nota de cr¿dito
           poRegInterfazBW.CDPROMO := piRegDMovMateriales.CDPROMO;
       END IF;


	   --DTINICIOPROMO, DTFINPROMO (ZVALIDEZ, ZVALIDEZH)
	   tmpSalida:=ObtenerFechaPromo (piRegDMovMateriales.CDPROMO,
			 			  			 poReginterfazbw.DTINICIOPROMO,
						  			 poReginterfazbw.DTFINPROMO,
						  			 tmpXMLMensaje);

		msgerr := 1;

	   IF tmpSalida!=0 THEN
	   	  --error
		  poXMLMensaje:='<FUNCION>ObtenerFechaPromo</FUNCION>' || tmpXMLMensaje;
		  RETURN(-1);
	   END IF;


   		msgerr := 2;

	   --SQLINEA (ZNRO_POS)
	   poRegInterfazBW.SQLINEA := piRegDMovMateriales.SQDETALLEMOVMATERIALES;

	   --CDSTATUSPEDIDO (ZSTA_PED)
	   poReginterfazbw.CDSTATUSPEDIDO:=NULL;

	   --CDTIPOPROMO (ZTIP_PROM)
--	   IF NVL(piRegDMovMateriales.CDPROMO,0) !=0 OR TRIM(NVL(piRegDMovMateriales.DSOBSERVACION,''))='PR' THEN
	   IF piRegDMovMateriales.CDPROMO IS NOT NULL OR TRIM(NVL(piRegDMovMateriales.DSOBSERVACION,''))='PR' THEN
	   	  poRegInterfazBW.CDTIPOPROMO:= piRegDMovMateriales.ICRESPPROMO;
	   ELSE
	   	  poRegInterfazBW.CDTIPOPROMO:= NULL;
	   END IF;

	   --AM (ZIMP_TOTF)
	   IF TRIM(piRegDocumentos.cdcomprobante) IN ('NCSA','NCSB','NCCA','NCCB','NCFA','NCFB','NCEE') THEN
	   	  --ES UNA NOTA DE CREDITO
	   	  IF piRegDMovMateriales.ICRESPPROMO=1 OR TRIM(NVL(piRegDMovMateriales.DSOBSERVACION,''))='PR' OR TRIM(NVL(piRegDMovMateriales.DSOBSERVACION,''))='DEL' THEN
		  	 --ES EL REGALO DE UNA PROMOCION => SE GRABA EN POSITIVO
			 IF piRegDMovMateriales.AMLINEA <0 THEN
		  	 	 poReginterfazbw.AMLINEA := piRegDMovMateriales.AMLINEA * (-1);
			 ELSE
			 	 poReginterfazbw.AMLINEA := piRegDMovMateriales.AMLINEA;
			 END IF;
       --Inicio - MarianoL 15/07/2013: modificación para migracion de BO a BW
			 IF piRegDMovMateriales.Ampreciounitario <0 THEN
		  	 	 poReginterfazbw.Ampreciounitario := piRegDMovMateriales.Ampreciounitario * (-1);
			 ELSE
			 	 poReginterfazbw.Ampreciounitario := piRegDMovMateriales.Ampreciounitario;
			 END IF;
       --Fin - MarianoL 15/07/2013: modificación para migracion de BO a BW
		  ELSE
		  	  --NO ES EL REGALO DE UNA PROMOCION => SE GRABA EN NEGATIVO
			  IF piRegDMovMateriales.AMLINEA <0 THEN
		   	  	 poReginterfazbw.AMLINEA := piRegDMovMateriales.AMLINEA;
			  ELSE
		  	 	 poReginterfazbw.AMLINEA := piRegDMovMateriales.AMLINEA * (-1);
			  END IF;
       --Inicio - MarianoL 15/07/2013: modificación para migracion de BO a BW
			  IF piRegDMovMateriales.Ampreciounitario <0 THEN
		   	  	 poReginterfazbw.Ampreciounitario := piRegDMovMateriales.Ampreciounitario;
			  ELSE
		  	 	 poReginterfazbw.Ampreciounitario := piRegDMovMateriales.Ampreciounitario * (-1);
			  END IF;
       --Fin - MarianoL 15/07/2013: modificación para migracion de BO a BW
		  END IF;
	   ELSE
		  --NO ES UNA NOTA DE CREDITO
		  poReginterfazbw.AMLINEA := piRegDMovMateriales.AMLINEA;
      --Inicio - MarianoL 15/07/2013: modificación para migracion de BO a BW
		  poReginterfazbw.Ampreciounitario := piRegDMovMateriales.Ampreciounitario;
      --Fin - MarianoL 15/07/2013: modificación para migracion de BO a BW
	   END IF;

    --Inicio - MarianoL 15/07/2013: modificación para migracion de BO a BW
	  poReginterfazbw.Dsobservacion := piRegDMovMateriales.Dsobservacion;
    --Fin - MarianoL 15/07/2013: modificación para migracion de BO a BW

	   --ICPRIMERALINEA  (ZCAN_COMP)
	  IF  piRegDMovMateriales.SQDETALLEMOVMATERIALES=1 THEN
   	  	  poRegInterfazBW.ICPRIMERALINEA:=1;
	  ELSE
	  	  poRegInterfazBW.ICPRIMERALINEA:=NULL;
	  END IF;

	  --QTBULTOS (ZUNI_VTAB)
	  tmpSalida:= ObtenerCantVendidas(piRegDMovMateriales.VLUXB, piRegDMovMateriales.CDUNIDAMEDIDA,
	 				   	  			  piRegDMovMateriales.QTUNIDADMOV, poRegInterfazBW.QTBULTOS, tmpXMLMensaje);

	 msgerr := 3;


	  IF tmpSalida!=0 THEN
	  	 poXMLMensaje:='<FUNCION>ObtenerCantVendidas</FUNCION>' || tmpXMLMensaje;
		 RETURN(-1);
	  END IF;

   	  --CDTIPOLINEA (ZPROM)
	  IF piRegDMovMateriales.ICRESPPROMO=1 OR TRIM(NVL(piRegDMovMateriales.DSOBSERVACION,''))='PR' THEN
	  	  poRegInterfazBW.CDTIPOLINEA:='PRO';
	  ELSE
	  	  poRegInterfazBW.CDTIPOLINEA:=NULL;
	  END IF;

	  IF  ((piRegDMovMateriales.CDPROMO IS NOT NULL) OR TRIM(NVL(piRegDMovMateriales.DSOBSERVACION,''))='PR') AND
	  	  poRegInterfazBW.CDTIPOLINEA IS NOT NULL  THEN
	      --QTMOVPROMO (ZCAN_PROM)
	  	  --poRegInterfazBW.QTMOVPROMO:=piRegDMovMateriales.QTUNIDADMOV; (MODIFICADO 17/06)


		  IF SUBSTR(TRIM(NVL(piRegDocumentos.CDCOMPROBANTE,'')),1,2) ='FC' AND piRegDMovMateriales.ICRESPPROMO=1 THEN
		  	  IF piRegDMovMateriales.QTUNIDADMEDIDABASE<0 THEN
			  	 poRegInterfazBW.QTMOVPROMO:=piRegDMovMateriales.QTUNIDADMEDIDABASE;
		      ELSE
			  	 poRegInterfazBW.QTMOVPROMO:=(-1) * piRegDMovMateriales.QTUNIDADMEDIDABASE;
		      END IF;
		  ELSE
		  	  poRegInterfazBW.QTMOVPROMO:=piRegDMovMateriales.QTUNIDADMEDIDABASE;
		  END IF;

	  	  --QTMOV (ZUNI_VTAK)
   	  	  poRegInterfazBW.QTMOV:=NULL;


	  ELSE
	      --QTMOVPROMO (ZCAN_PROM)
	  	  poRegInterfazBW.QTMOVPROMO:=NULL;

	  	  --QTMOV (ZUNI_VTAK)
--		  poRegInterfazBW.QTMOV:=piRegDMovMateriales.QTUNIDADMOV; (MODIFICADO 17/06)
--		  poRegInterfazBW.QTMOV:=piRegDMovMateriales.QTUNIDADMEDIDABASE (Modificado 18/06/2002)
 		  IF TRIM(piRegDocumentos.cdcomprobante) IN ('NCSA','NCSB','NCCA','NCCB','NCFA','NCFB','NCEE') THEN
		     --Es una nota de credito

	  	   	  IF piRegDMovMateriales.ICRESPPROMO=1 OR TRIM(NVL(piRegDMovMateriales.DSOBSERVACION,''))='PR' OR TRIM(NVL(piRegDMovMateriales.DSOBSERVACION,''))='DEL' THEN
			  	 --ES EL REGALO DE UNA PROMOCION => SE GRABA EN POSITIVO
			  	 IF piRegDMovMateriales.QTUNIDADMEDIDABASE < 0 THEN
				 	poRegInterfazBW.QTMOV:=piRegDMovMateriales.QTUNIDADMEDIDABASE * (-1);
				 ELSE
				 	poRegInterfazBW.QTMOV:=piRegDMovMateriales.QTUNIDADMEDIDABASE;
				 END IF;
			  ELSE
			  	 --NO ES EL REGALO DE UNA PROMOCION => SE GRABA EN NEGATIVO
				  IF piRegDMovMateriales.QTUNIDADMEDIDABASE < 0 THEN
			     	 poRegInterfazBW.QTMOV:=piRegDMovMateriales.QTUNIDADMEDIDABASE;
				  ELSE
				  	  poRegInterfazBW.QTMOV:=piRegDMovMateriales.QTUNIDADMEDIDABASE * (-1);
			  	  END IF;
			  END IF;
		  ELSE
		  	  --No es una Nota de Credito
		  	  poRegInterfazBW.QTMOV:=piRegDMovMateriales.QTUNIDADMEDIDABASE;
		  END IF;
	  END IF;


	  		msgerr := 4;


	  --QTMOVPEDIDO (ZCAN_PED)
	  poRegInterfazBW.QTMOVPEDIDO:=	0;

	  --AMLINEAPEDIDO (ZIMP_TOTP)
	  poRegInterfazBW.AMLINEAPEDIDO:= 0;

	  --CDUNIDADMEDIDA (ZBTO)
	  IF piRegDMovMateriales.CDUNIDAMEDIDA IN ('BTO','KG') THEN
	  	 poRegInterfazBW.CDUNIDADMOV:='BTO';
	  ELSE
	  	 poRegInterfazBW.CDUNIDADMOV:=NULL;
	  END IF;

		msgerr := 5;


	 /*--- ACV 05/02/2013 obtengo los valores de la regla relacionada si hubiere ---*/
	GetReglaDetMovmat(piRegDMovMateriales.idmovmateriales, piRegDMovMateriales.sqdetallemovmateriales, piRegDMovMateriales.cdarticulo, o_idregla , o_aplico, o_porc , o_factor );
	poRegInterfazBW.id_regla := o_idregla;
	poRegInterfazBW.aplica := o_aplico;
	poRegInterfazBW.factor := o_factor;
	poRegInterfazBW.porcentaje := o_porc;


/*	GrabarLog ('valores obtenidos de:' || piRegDMovMateriales.idmovmateriales || '-' || piRegDMovMateriales.sqdetallemovmateriales || '-' || piRegDMovMateriales.cdarticulo || '- valores de regla id/aplico/porc/factor' || o_idregla || ' / ' || o_aplico || ' / ' || o_factor,'9999');*/

    RETURN (0);

  EXCEPTION
  		   WHEN OTHERS THEN
		   		poXMLMensaje:='<NUMERO>' || trim(SQLCODE) || '[' || msgerr || ']' || '</NUMERO>';
				poXMLMensaje:= poXMLMensaje || '<DESCRIPCION>' || trim(SQLERRM) || '</DESCRIPCION>';

				RETURN(-2);
  END ObtenerDatosCamposDM;


  /*ELIMINA DE LA TABLA INTERFAZBW LOS REGISTROS EXISTENTES PARA LA FECHA DE PROCESO*/
  FUNCTION DepurarInterfazBw(piFechaProceso IN INTERFAZBW.DTDOCUMENTO%TYPE,
  		   					 poXmlMensaje   OUT VARCHAR2) RETURN INTEGER

  IS

  BEGIN
  	   DELETE FROM INTERFAZBW
	   WHERE  TRUNC(INTERFAZBW.DTDOCUMENTO)=TRUNC(piFechaProceso);

  	   RETURN(0);

  EXCEPTION
  	WHEN OTHERS THEN
	   	   		poXMLMensaje:='<NUMERO>' || trim(SQLCODE) || '</NUMERO>';
				poXMLMensaje:= poXMLMensaje || '<DESCRIPCION>' || trim(SQLERRM) || '</DESCRIPCION>';

				RETURN(-1);

  END;


  /********************************************************************************************
  Modificaciones:
  Fecha       Programador     Descripci¢n
  ---------------------------------------------------------------------------------------------
  09/08/2004  F.Mor¢n         Para notas de cr¿dito generadas por promociones marketec
                              (es decir aquellas cuyo motivo corresponde al configurado en el
                              parametro PVMMotivoNC), se graba en el campo INTERFAZBW.CDPROMO,
                              el valor configurado en el par metro de sistema PVMCdPromo
  ********************************************************************************************/
  PROCEDURE EjecutarProceso (iFechaProceso IN DATE,
  							 oEstado 	   OUT INTEGER)



  IS

  /****************************************
  PROCEDIMIENTO DE EJECUCION DE LA INTERFAZ
  * v% 16/08/2019 - Excluyo articulos A900128 y 127 por iva.
  *****************************************/

  	CURSOR curDocumentos IS SELECT DOCUMENTOS.*
		   		 		 	FROM   FILTROESTADOSCOMPROBANTES,
								   DOCUMENTOS
					        WHERE  FILTROESTADOSCOMPROBANTES.CDESTADO = DOCUMENTOS.CDESTADOCOMPROBANTE AND
						   		   FILTROESTADOSCOMPROBANTES.CDOPERACION = 35 AND
						   		   FILTROESTADOSCOMPROBANTES.CDCOMPROBANTE = DOCUMENTOS.CDCOMPROBANTE AND
						   		   DOCUMENTOS.DTDOCUMENTO between TRUNC(iFechaProceso) and TRUNC(iFechaProceso)+1; -- APW 8/10/2018

	CURSOR curDetalleMovMateriales (piIDMOVMATERIALES IN DETALLEMOVMATERIALES.IDMOVMATERIALES%TYPE) IS
		   SELECT *
		   FROM  DETALLEMOVMATERIALES
		   WHERE DETALLEMOVMATERIALES.IDMOVMATERIALES = piIDMOVMATERIALES
       AND CDARTICULO NOT IN ('A900128','A900127');


/*	CURSOR curDetallePedidos(piIDPEDIDO IN PEDIDOS.IDPEDIDO%TYPE) IS
		   SELECT *
		   FROM  DETALLEPEDIDOS
		   WHERE DETALLEPEDIDOS.IDPEDIDO=piIDPEDIDO;*/

/*	CURSOR curFaltantePedidos(piIDPEDIDO IN PEDIDOS.IDPEDIDO%TYPE) IS
		   SELECT *
		   FROM FALTANTEPEDIDOS
		   WHERE FALTANTEPEDIDOS.IDPEDIDO = piIDPEDIDO;*/


    regDocumentos     curDocumentos%ROWTYPE;

	--RegPedido	  	  PEDIDOS%ROWTYPE;
	--regDPedido		  curDetallePedidos%ROWTYPE;
	--regFPedido		  curFaltantePedidos%ROWTYPE;

	--Para el detalle del pedido y el faltante.
	--regDetallePedido recDetPedFalt;

  	regMovMateriales  MOVMATERIALES%ROWTYPE;
	regDMovMateriales curDetalleMovMateriales%ROWTYPE;


	regInterfazBW     INTERFAZBW%ROWTYPE;

    tmpXMLMensaje	  VARCHAR2(4000);
	tmpSalida		  INTEGER;
	tmpEsPedido 	  BOOLEAN;

    -- FEM - 09/08/2004
    strPVMCdPromo     INTERFAZBW.CDPROMO%TYPE;        -- C¢digo de promoci¢n para promociones marketec
    strPVMMotivoNC    INTERFAZBW.CDMOTIVONC%TYPE;     -- Motivo de notas de cr¿dito por promociones marketec
    tmpSalida2 integer;

  BEGIN

  		tmpSalida:=0;
		oEstado:=0;


        /* 11/03/2014 -- APW -- Agrego grabacion de regla factoreo para ventas por canal que no se esta grabando con la factura */
        pkg_grabarestadisticafactor.grabarreglafactor(iFechaProceso);

        -- FEM - 09/08/2004
        -- Se obtiene el c¢digo de motivo correspondiente a NC por promociones Marketec
        BEGIN
            SELECT vlparametro
              INTO strPVMMotivoNC
              FROM PARAMETROSSISTEMA
             WHERE nmparametrosistema='PVMMotivoNC'
               AND dcdescriptorqualificador='Marketec';
        EXCEPTION
            WHEN OTHERS THEN
                RAISE_APPLICATION_ERROR (-20001,'Error al recuperar el motivo de Notas de cr¿dito por promociones marketec');
        END ;
        -- Se obtiene el c¢digo de promoci¢n para promociones Marketec
        BEGIN
            SELECT vlparametro
              INTO strPVMCdPromo
              FROM PARAMETROSSISTEMA
             WHERE nmparametrosistema='PVMCdPromo'
               AND dcdescriptorqualificador='Marketec';
        EXCEPTION
            WHEN OTHERS THEN
                RAISE_APPLICATION_ERROR (-20002,'Error al recuperar el c¢dgio de promociones marketec');
        END ;


		--Borra, si existen, los registros previamente grabados para la fecha de proceso actual
		tmpSalida:=DepurarInterfazBw(iFechaProceso,tmpXmlMensaje);

		IF tmpSalida !=0 THEN
		   tmpXMLMensaje:='<ERROR><FUNCION>DepurarInterfazBw</FUNCION>' || tmpXMLMensaje;
 		   tmpXMLMensaje := tmpXMLMensaje || '<FECHAPROCESO>' || TRUNC(iFechaProceso) ||  '</FECHAPROCESO></ERROR>' ;
		   ROLLBACK;
		   GrabarLog (tmpXMLMensaje, regDocumentos.CDSUCURSAL);
		   COMMIT;
		   oEstado:=-1;
		   RETURN;
		END IF;

		regInterfazBW.DTPROCESO:=SYSDATE;

		--Recorre alegremente los documentos
		FOR regDocumentos IN curDocumentos LOOP

         --Calcula los valores que dependen del documento
		 tmpSalida:=ObtenerDatosCamposDOC(regDocumentos,
											regInterfazBW,
											tmpXMLMensaje);

		 IF tmpSalida!=0 THEN
		   	  --Error
			    tmpXMLMensaje:='<ERROR><FUNCION>ObtenerDatosCamposDOC</FUNCION>' || tmpXMLMensaje;
 			    tmpXMLMensaje := tmpXMLMensaje || '<IDDOCTRX>' || trim(regDocumentos.IDDOCTRX) ||  '</IDDOCTRX></ERROR>' ;
				GrabarLog (tmpXMLMensaje, regDocumentos.CDSUCURSAL);
		  ELSE

      /* MarianoL - 15/07/2013 : Elimino todo lo referente a pedidos porque no se usa... */
			EsPedido(regDocumentos.CDCOMPROBANTE, tmpEsPedido);
			IF tmpEsPedido = false THEN
		   --Obtiene los datos del comprobante
		   tmpSalida:=ObtenerDatosMovimiento(regDocumentos.IDMOVMATERIALES,
  		   						  			 RegMovMateriales,
								  			 tmpXMLMensaje);

		   IF tmpSalida!=0 THEN
			  --Ocurrio un error
			  tmpXMLMensaje:='<ERROR><FUNCION>ObtenerDatosMovimiento</FUNCION>' || tmpXMLMensaje ;
			  tmpXMLMensaje := tmpXMLMensaje || '<IDDOCTRX>' || trim(regDocumentos.IDDOCTRX) ||  '</IDDOCTRX>' ;
			  tmpXMLMensaje := tmpXMLMensaje || '<IDMOVMATERIALES>' || trim(regDocumentos.IDMOVMATERIALES) ||  '</IDMOVMATERIALES></ERROR>';

			  GrabarLog (tmpXMLMensaje,regDocumentos.CDSUCURSAL);
	           ELSE

			  --Calcula los valores que dependen del movimiento de materiales
			 tmpSalida:=ObtenerDatosCamposMOV(regDocumentos,
  		   						 			  RegMovMateriales,
								 			  regInterfazBW,
								 			  tmpXMLMensaje);

			--- ACV 03/04/2010 cambios por definicion de A.Gonzalez---
	  		if RegDocumentos.Cdcomprobante = 'FCEE' or regDocumentos.Cdcomprobante = 'NCEE' then
				--- por default ---
				RegInterfazBW.Cdorgvta := 'VEX';

				--- verifico si es de zona franca ---
				if ClteDeZonaFranca(RegDocumentos.IDentidad) = 1 then
					RegInterfazBW.Cdorgvta := 'VZF';
				end if;
	 		end if;


			if trim(RegDocumentos.IDentidad) = trim(GetVlParametro('CdConsFinal','General')) or
					trim(RegDocumentos.IDentidad) = 'IdCfReparto' then

				if trim(RegDocumentos.IDentidad) <> 'IdCfReparto' then
					if instr(RegDocumentos.dsreferencia,'-(') >= 1   then
						tmpSalida2 := GetCuitRef(RegDocumentos.dsreferencia, RegInterfazBW.CDCUIT);
					end if;
				else
					tmpSalida2 := GetCuitReferenciado(RegDocumentos.IDMOVMATERIALES, RegInterfazBW.CDCUIT);
				end if;


				if  substr(RegDocumentos.CdComprobante,1,2) = 'FC' then
					RegInterfazBW.CDcomprobante := 'FF';
				end if;
				if  substr(RegDocumentos.CdComprobante,1,2) = 'NC' then
					RegInterfazBW.CDcomprobante := 'NF';
				end if;

			end if;


			 IF tmpSalida!=0 THEN
			 	--Error
				tmpXMLMensaje:='<ERROR><FUNCION>ObtenerDatosCamposMOV</FUNCION>' || tmpXMLMensaje ;
			  	tmpXMLMensaje := tmpXMLMensaje || '<IDDOCTRX>' || trim(regDocumentos.IDDOCTRX) ||  '</IDDOCTRX>' ;
			  	tmpXMLMensaje := tmpXMLMensaje || '<IDMOVMATERIALES>' || trim(regDocumentos.IDMOVMATERIALES) ||  '</IDMOVMATERIALES></ERROR>';

				GrabarLog (tmpXMLMensaje,regDocumentos.CDSUCURSAL);
			 ELSE
				--Abre el cursor del detalle del movimiento
				FOR regDMovMateriales IN curDetalleMovMateriales (regDocumentos.IDMOVMATERIALES)  LOOP

					--Calcula los valores que dependen del detalle del movimiento
					tmpSalida:=ObtenerDatosCamposDM(regDocumentos,
  		   						 					RegMovMateriales,
								 					regDMovMateriales,
                                                    strPVMCdPromo,      -- FEM - 09/08/2004 - Par metro agregado
                                                    strPVMMotivoNC,     -- FEM - 09/08/2004 - Par metro agregado
								 					RegInterfazBW,
								 					tmpXMLMensaje);

					IF tmpSalida!=0 THEN
					   --Error al obtener los datos necesarios para insertar el registro
					   tmpXMLMensaje:='<ERROR><FUNCION>ObtenerDatosCamposDM</FUNCION>' ||  tmpXMLMensaje ;
					   tmpXMLMensaje := tmpXMLMensaje || '<IDDOCTRX>' || trim(regDocumentos.IDDOCTRX) ||  '</IDDOCTRX>' ;
					   tmpXMLMensaje := tmpXMLMensaje || '<IDMOVMATERIALES>' || trim(regDocumentos.IDMOVMATERIALES) ||  '</IDMOVMATERIALES>';
					   tmpXMLMensaje := tmpXMLMensaje || '<SQDETALLEMOVMATERIALES>' || trim(regDMovMateriales.SQDETALLEMOVMATERIALES) ||  '</SQDETALLEMOVMATERIALES></ERROR>';
					   GrabarLog (tmpXMLMensaje,regDocumentos.CDSUCURSAL);
					ELSE
					   --Obtuvo los datos necesarios para el pedido
					   tmpSalida:=InsertarInterfazBW(regInterfazBW,tmpXMLMensaje);

					   IF tmpSalida!=0 THEN
							   --Error al intentar grabar el registro
							   tmpXMLMensaje:='<ERROR><FUNCION>InsertarInterfazBW</FUNCION>' ||  tmpXMLMensaje;
							   tmpXMLMensaje := tmpXMLMensaje || '<IDDOCTRX>' || trim(regDocumentos.IDDOCTRX) ||  '</IDDOCTRX>' ;
					   		   tmpXMLMensaje := tmpXMLMensaje || '<IDMOVMATERIALES>' || trim(regDocumentos.IDMOVMATERIALES) ||  '</IDMOVMATERIALES>';
					   		   tmpXMLMensaje := tmpXMLMensaje || '<SQDETALLEMOVMATERIALES>' || trim(regDMovMateriales.SQDETALLEMOVMATERIALES) ||  '</SQDETALLEMOVMATERIALES></ERROR>';
							   GrabarLog (tmpXMLMensaje,regDocumentos.CDSUCURSAL);
					   END IF;


					END IF;

					COMMIT;

				END LOOP;

			 END IF;

			END IF;
		 END IF;
        END IF;

		COMMIT;

		END LOOP;

		COMMIT;

  EXCEPTION
  		   WHEN OTHERS THEN
		   		oEstado:=-1;

				tmpXMLMensaje:='<ERROR><FUNCION>EjecutarProceso</FUNCION>';
				tmpXMLMensaje:= tmpXMLMensaje || '<NUMERO>' || trim(SQLCODE) || '</NUMERO>';
				tmpXMLMensaje:= tmpXMLMensaje || '<DESCRIPCION>' || trim(SQLERRM) || '</DESCRIPCION></ERROR>';

			    GrabarLog (tmpXMLMensaje,regDocumentos.CDSUCURSAL);

				COMMIT;


  END EjecutarProceso;


  Function EsPrecioDeTapa(p_cdart  ARTICULOS.CDARTICULO%type, p_fch DATE, p_cdcanal tblcanal.id_canal%type) return  integer is
	cuantos integer;
	BEGIN
		select count(*) into cuantos from TBLARTICULO_TAPA where
			cdarticulo = p_cdart and p_fch between vigenciadesde and vigenciahasta +1
				and habilitado in('1','T')
				and ( trim(cdsucursal) = '9999' or trim(cdsucursal) = trim(GetVlParametro('CDSucursal' ,'General'))  )
				and cdcanal = p_cdcanal;

		if cuantos > 0 then
			return 1;
		else
			return 0;
		end if;
	EXCEPTION
	  	   WHEN NO_DATA_FOUND THEN
			 RETURN 0;

		   WHEN OTHERS THEN
			return 0;

  End  EsPrecioDeTapa;

  Function GetFechaPedido(p_idped PEDIDOS.IDPEDIDO%type ) return DATE is
  	fch DATE;
  	BEGIN
  		select dtdocumento into fch from DOCUMENTOS d, PEDIDOS p
  			where p.idpedido = p_idped and p.iddoctrx = d.iddoctrx;

  		return fch;

  	EXCEPTION
	  	   WHEN NO_DATA_FOUND THEN
			 RETURN null;

		   WHEN OTHERS THEN
			return null;
  End GetFechaPedido;

  FUNCTION EspedidoVendedor(p_idped PEDIDOS.IDPEDIDO%type) return integer  is
  	id_vendedor PEDIDOS.IDVENDEDOR%type;

	BEGIN
	  	select idvendedor into id_vendedor from pedidos where idpedido = p_idped;

  		if id_vendedor is null then
  		   return 0;
	  	else
  			return 1;
	  	end if;

  EXCEPTION
	  	   WHEN NO_DATA_FOUND THEN
			 RETURN 0;

		   WHEN OTHERS THEN
			return 0;
  END EspedidoVendedor;
END;
/
