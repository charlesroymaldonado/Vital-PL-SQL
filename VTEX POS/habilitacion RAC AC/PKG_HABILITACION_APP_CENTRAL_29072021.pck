CREATE OR REPLACE PACKAGE PKG_HABILITACION_APP_CENTRAL is

  Type cursor_type Is Ref Cursor;
  
  Procedure GetAgente(p_identidad   IN entidades.identidad%TYPE,
                      p_idcuenta    IN tblcuenta.idcuenta%type,          
                      cur_out       OUT cursor_type);

 Procedure GetHabilitaciones (p_identidad   IN entidades.identidad%TYPE,
                              p_idcuenta    IN tblcuenta.idcuenta%type,              
                              cur_out       OUT cursor_type);

Procedure HabilitacionUsuario(p_identidadaplicacion IN tblentidadaplicacion.identidadaplicacion%TYPE,
                              p_identidad           IN entidades.identidad%type,
                              p_cdsucursal          IN tblcuenta.cdsucursal%type,
                              p_idcuenta            IN tblcuenta.idcuenta%type,
                              p_aplicacion          IN tblentidadaplicacion.vlaplicacion%type,
                              --p_autorizacion IN tblentidadaplicacion.vlautorizacion%type,
                              p_idpersona IN personas.idpersona%type,
                              p_mail      IN tblentidadaplicacion.mail%type,
                              p_icactivo  IN tblentidadaplicacion.icactivo%type,
                              p_ok        OUT Integer,
                              p_error     OUT varchar2);

  Procedure UpdCorreoAplicacion(p_mailviejo           IN tblentidadaplicacion.mail%TYPE,
                               p_mailnuevo           IN tblentidadaplicacion.mail%TYPE,
                               p_SqContactoEntidad In contactosentidades.sqcontactoentidad%Type,
                                p_Identidad         In entidades.identidad%Type,
                                 p_idcuenta            IN tblcuenta.idcuenta%type,
                                p_CdFormadeContacto In contactosentidades.cdformadecontacto%Type,
                                p_IdPersonaModif    In entidades.idpersonamodif%Type,
                               p_ok                  OUT Integer,
                               p_error               OUT varchar2);

  Procedure GetDireccionMail(p_identidad IN entidades.identidad%TYPE,
                             cur_out     OUT cursor_type);

  Procedure GetAplicacionesPermisos(p_vlaplicacion IN TBLENTIDADAPLICACION.VLAPLICACION%type,
                                    cur_out        OUT cursor_type);

  Function FnExisteCorreo(p_correo IN contactosentidades.dscontactoentidad%TYPE,
                                         p_idcuenta IN tblcuenta.idcuenta%type)
    return varchar2;
  
  Procedure GetIdentidadAplicacion(p_Identidad           IN ENTIDADES.identidad%TYPE,
                                   p_IdCuenta            IN TBLCUENTA.IDCUENTA%TYPE,
                                   p_VlAplicacion        IN TBLENTIDADAPLICACION.VLAPLICACION%TYPE,
                                   p_VlAutorizacion      IN TBLENTIDADAPLICACION.VLAUTORIZACION%TYPE,
                                   p_IdentidadAplicacion OUT TBLENTIDADAPLICACION.IDENTIDADAPLICACIOn%TYPE);

  Procedure GetTieneTarjetaFidelizado(p_identidad  IN entidades.identidad%type,
                                      p_aplicacion IN tblaplicacionautorizacion.vlaplicacion%type,
                                      p_ok         OUT INTEGER,
                                      p_error      OUT VARCHAR2);

  Procedure GetAplicaciones(cur_out        OUT cursor_type);

end PKG_HABILITACION_APP_CENTRAL;
/
CREATE OR REPLACE PACKAGE BODY PKG_HABILITACION_APP_CENTRAL is



  
 /****************************************************************************************
  * Retorna un cursor con los agentes que tiene relacionado el cliente
  * %v 22/07/2021 - ChM
  *****************************************************************************************/

  Procedure GetAgente(p_identidad   IN entidades.identidad%TYPE,
                      p_idcuenta    IN tblcuenta.idcuenta%type,          
                      cur_out       OUT cursor_type) IS

    v_Modulo VARCHAR2(100) := 'PKG_HABILITACION_APP.GetAgente';
    
  Begin

    open cur_out for
            with cvv as (
                        select * 
                          from clientesviajantesvendedores cc, personas p
                         where dthasta = (select max(dthasta) from clientesviajantesvendedores)
                        and cc.idviajante = p.idpersona
                         ),
                  tlk as (
                          select * 
                            from clientestelemarketing ct, personas p
                           where ct.idpersona = p.idpersona
                          ),
                  comi as (
                      select ccc.identidad,e.dsrazonsocial
                        from clientescomisionistas ccc,entidades e
                       where ccc.idcomisionista = e.identidad
                          )
                     select distinct 
                            LISTAGG(trim(cvv.dsnombre||' '||cvv.dsapellido), ', ') WITHIN GROUP (ORDER BY cvv.dsnombre) vendedor, 
                            LISTAGG(trim(tlk.dsnombre||' '||tlk.dsapellido), ', ') WITHIN GROUP (ORDER BY tlk.dsnombre) telemarketer, 
                            LISTAGG(trim(comi.dsrazonsocial), ', ') WITHIN GROUP (ORDER BY comi.dsrazonsocial) comisionista, 
                            DECODE(PKG_CLD_DATOS.Getcanal (cu.identidad,cu.cdsucursal),'NO',1,0) ERROR
                       from tlk, cvv,comi, tblcuenta cu
                      where cu.identidad = cvv.identidad (+)
                        and cu.cdsucursal = cvv.cdsucursal (+)
                        and cu.identidad = tlk.identidad (+)
                        and cu.cdsucursal = tlk.cdsucursal (+)
                        and cu.identidad = comi.identidad (+)  
                        and cu.idcuenta = p_idcuenta
                        and cu.identidad = p_identidad
                   group by cu.identidad,cu.cdsucursal;
              
  EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_Modulo ||
                                       '  Error: ' || SQLERRM);
      RAISE;

  End GetAgente;


  /****************************************************************************************
  * Retorna un cursor con todas las autorizaciones asignadas por cuit
  * %v 15/08/2017 - IAquilano - v1.0
  *****************************************************************************************/

  Procedure GetHabilitaciones(p_identidad   IN entidades.identidad%TYPE,
                              p_idcuenta    IN tblcuenta.idcuenta%type,              
                              cur_out       OUT cursor_type) IS

    v_Modulo VARCHAR2(100) := 'PKG_HABILITACION_APP.GetHabilitaciones';
  Begin

    open cur_out for
      select ta.identidadaplicacion,             
             ta.vlaplicacion Aplicacion,
             ta.vlautorizacion Autorizacion,
             TA.IDCUENTA,
             ta.mail,
             p.dsapellido || ', ' ||p.dsnombre Autorizado_por,
             s.cdsucursal,
             s.dssucursal Sucursal,
             ta.dtautorizacion,
             case
               when ta.icactivo = 0 then
                 'Deshabilitado'
               when ta.icactivo = 1 then
                 'Habilitado'
               end as Estado,
             ta.icactivo,
             decode(ta.vlaplicacion,'TiendaOnline',1,0) Actualizar 
        from tblentidadaplicacion         ta, 
             personas                     p, 
             sucursales                   s, 
             tblaplicacionautorizacion    tp,
             tblcuenta                    tc
       where ta.identidad = p_identidad
         and tc.idcuenta = p_idcuenta
         and tc.idcuenta = ta.idcuenta
         and ta.idpersona = p.idpersona
         and ta.cdsucursal = s.cdsucursal
         and ta.vlaplicacion = tp.vlaplicacion;

  EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_Modulo ||
                                       '  Error: ' || SQLERRM);
      RAISE;

  End GetHabilitaciones;

  /****************************************************************************************
  * Retorna cursor con todos los correos cargados para ese cuit
  * de la tabla contactosentidades
  * %v 15/08/2017 - IAquilano - v1.0
  *****************************************************************************************/

  Procedure GetDireccionMail(p_identidad IN entidades.identidad%TYPE,
                             cur_out     OUT cursor_type) is

    v_Modulo VARCHAR2(100) := 'PKG_HABILITACION_APP.GetDireccionMail';

  Begin
    open cur_out for
      Select ce.dscontactoentidad descripcion, sqcontactoentidad codigo
        from contactosentidades ce
       where ce.identidad = p_identidad
         and ce.cdformadecontacto = 2;

  EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_Modulo ||
                                       '  Error: ' || SQLERRM);

  End GetDireccionMail;

  /****************************************************************************************
  * Valida si ya existe ese correo cargado en la tabla tblentidadaplicacion
  * %v 17/08/2017 - IAquilano - v1.0
  * Agrego el IDCUENTA como parámetro de entrada, ya que las aplicaciones de una misma cuenta pueden compartir un mismo correo
  * %v 08/03/2018 - FPeloso - v1.1
  * %v 31/03/2021 - LM - se valida que la entidadAplicacion este habilitada
  *****************************************************************************************/

  Function FnExisteCorreo(p_correo  IN contactosentidades.dscontactoentidad%TYPE,
                                      p_idcuenta IN tblcuenta.idcuenta%type)
    return varchar2 IS

    v_Modulo VARCHAR2(100) := 'PKG_HABILITACION_APP.FnExisteCorreo';
    v_cont   INTEGER;

  Begin

  v_cont := 0;

    select count(*)
      into v_cont
      from tblentidadaplicacion ce
     where trim(ce.mail) = trim(p_correo)
     and ce.idcuenta <> p_idcuenta
     and ce.icactivo=1;

    If nvl(v_cont,0) > 0 then
      return 1;--ya existe
    else
      return 0;--no existe
    End if;

  EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_Modulo ||
                                       '  Error: ' || SQLERRM);
  End FnExisteCorreo;

  /****************************************************************************************
  * Valida si ya existe ese correo cargado en la tabla contactosentidades
  * %v 07/11/2017 - IAquilano - v1.0
  *****************************************************************************************/

  Function FnExisteCorreoEnContactos(p_correo  IN contactosentidades.dscontactoentidad%TYPE)
    return varchar2 IS

    v_Modulo VARCHAR2(100) := 'PKG_HABILITACION_APP.FnExisteCorreoEnContactos';
    v_cont   INTEGER;

  Begin

  v_cont := 0;

    select count(*)
      into v_cont
      from contactosentidades ce
     where trim(ce.dscontactoentidad) = trim(p_correo)
     and ce.cdformadecontacto = 2;

    If nvl(v_cont,0) > 0 then
      return 1;--ya existe
    else
      return 0;--no existe
    End if;

  EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_Modulo ||
                                       '  Error: ' || SQLERRM);
  End FnExisteCorreoEnContactos; 

  /****************************************************************************************
  * Inserta los datos de la entidad en la tabla de habilitacion.
  * %v 15/08/2017 - IAquilano - v1.0
  * %v 16/08/2017 - IAquilano - Agrego update para deshabilitar.
  * %v 17/08/2017 - IAquilano - Agrego validacion de correo
  * %v 08/11/2017 - FPeloso - Agrego ta.mail = p_mail en el Update
  * %v 29/05/2018 - IAquilano: Agrego la persona en el update
  * %v 05/06/2018 - IAquilano: Agrego trim al parametro MAIL asi graba sin espacios al final
  * %v 22/07/2021 - ChM - Agrego parametro de sucursal
  *                       ajsuto validaciones de mail  
  *****************************************************************************************/
Procedure HabilitacionUsuario(p_identidadaplicacion IN tblentidadaplicacion.identidadaplicacion%TYPE,
                              p_identidad           IN entidades.identidad%type,
                              p_cdsucursal          IN tblcuenta.cdsucursal%type,
                              p_idcuenta            IN tblcuenta.idcuenta%type,
                              p_aplicacion          IN tblentidadaplicacion.vlaplicacion%type,
                              --p_autorizacion IN tblentidadaplicacion.vlautorizacion%type,
                              p_idpersona IN personas.idpersona%type,
                              p_mail      IN tblentidadaplicacion.mail%type,
                              p_icactivo  IN tblentidadaplicacion.icactivo%type,
                              p_ok        OUT Integer,
                              p_error     OUT varchar2) IS

  v_Modulo VARCHAR2(100) := 'PKG_HABILITACION_APP.HabilitacionUsuario';
  -- vcont                 integer;
  v_mail                integer;
  v_identidadaplicacion tblentidadaplicacion.identidadaplicacion%type;
  v_existe    integer;
  v_validamailn          integer;

Begin
   p_ok := 0;

  --valido solo trabajar este procedimiento para TiendaOnline
  if p_aplicacion <> 'TiendaOnline' then
     p_error := 'Proceso exclusivo para Habiltar TiendaOnline';
        return;
    end if;
      
 
  n_pkg_vitalpos_log_general.write(2, 'Modulo: ' || v_Modulo || '  P_identidadaplicacion: ' ||  p_identidadaplicacion|| ' P_identidad: '||p_identidad||' P_idcuenta: '||p_idcuenta||' p_aplicacion: '||p_aplicacion||' p_idpersona: '||p_idpersona||' p_mail: '||p_mail||' ICACTIVO: '||p_icactivo);

  select tp.icvalidamail
  into v_validamailn
  from tblaplicacionautorizacion tp
  where tp.vlaplicacion = p_aplicacion;

  If p_identidadaplicacion is null then
    v_identidadaplicacion := sys_guid();
  End If;
 
   v_mail := FnExisteCorreo(trim(lower(p_mail)), p_idcuenta); --check de existencia de correo en tabla tblentidadaplicacion
   If v_mail = 1 then
      p_error := 'El correo ya existe en otra cuenta.';
      return;
    end if;
    
    v_mail := FnExisteCorreoEnContactos(trim(lower(p_mail))); --check de existencia de correo en tabla contactosentidades
   If v_mail = 1 then
      p_error := 'El correo ya existe en otra Entidad.';
      return;
    end if;     
 
  If p_identidadaplicacion is null then 
    --verifico si ya existe y se desea volver a crear p_identidadaplicacio = null     error    
  begin
      select 1
        into v_existe
        from tblentidadaplicacion ta, tblaplicacionautorizacion tt
       where ta.idcuenta = p_idcuenta
         and ta.vlaplicacion = tt.vlaplicacion
         and ta.vlaplicacion = p_aplicacion;
         p_error := 'Existe un correo asociado a TiendaOnline para el cliente';
         return; 
    exception
      when others then
        null;
    end;     
        insert into tblentidadaplicacion
          (identidadaplicacion,
           identidad,
           idcuenta,
           vlaplicacion,
           vlautorizacion,
           idpersona,
           mail,
           cdsucursal,
           dtautorizacion,
           icactivo,
           dtupdate)
        values
          (v_identidadaplicacion,
           p_identidad,
           p_idcuenta,
           p_aplicacion,
           'Todos',
           p_idpersona,
           trim(lower(p_mail)),
           p_cdsucursal,
           sysdate,
           p_icactivo,
           sysdate);    
  else
    update tblentidadaplicacion ta
       set ta.icactivo  = p_icactivo,
           ta.dtupdate  = sysdate,
           ta.mail      = trim(lower(p_mail)),           
           ta.idpersona = p_idpersona
     where ta.identidadaplicacion = p_identidadaplicacion;
  End if;
  -- revisar si la cuenta tiene otra app activa pero excluyente habilitada, entonces la deshabilito automatico  
    update tblentidadaplicacion ta
       set ta.icactivo  = 0,
           ta.dtupdate  = sysdate,          
           ta.idpersona = p_idpersona
     where ta.identidadaplicacion in (select ta.identidadaplicacion 
                                        from tblentidadaplicacion ta, 
                                             tblaplicacionautorizacion tt
                                             --cuenta del parametro
                                       where ta.idcuenta = p_idcuenta
                                         and ta.vlaplicacion = tt.vlaplicacion
                                         -- diferente a la que estoy habilitando
                                         and tt.vlaplicacion <> p_aplicacion
                                         -- verifica si es excluyente 
                                         and nvl(tt.icexcluyente,0) = 1
                                         and ta.icactivo = 1);
  p_ok := 1;
  commit;

EXCEPTION
  WHEN OTHERS THEN
    p_ok    := 0;
    p_error := sqlerrm;
    n_pkg_vitalpos_log_general.write(2,
                                     'Modulo: ' || v_Modulo || '  Error: ' ||
                                     SQLERRM);

End HabilitacionUsuario;
 /****************************************************************************************
  * Inserta los datos de la entidad en la tabla de habilitacion.
  * %v 15/08/2017 - IAquilano - v1.0
  * %v 16/08/2017 - IAquilano - Agrego update para deshabilitar.
  * %v 17/08/2017 - IAquilano - Agrego validacion de correo
  * %v 07/11/2017 - IAquilano - Agrego validaciones de correo y update en contactosentidades
   * %v 08/03/2018 - FPeloso - Agrego el IDCUENTA como parámetro de entrada, ya que las aplicaciones de una misma cuenta pueden compartir un mismo correo
  *****************************************************************************************/
 Procedure UpdCorreoAplicacion(p_mailviejo         IN tblentidadaplicacion.mail%TYPE,
                               p_mailnuevo         IN tblentidadaplicacion.mail%TYPE,
                               p_SqContactoEntidad In contactosentidades.sqcontactoentidad%Type,
                               p_Identidad         In entidades.identidad%Type,
                                p_idcuenta         IN tblcuenta.idcuenta%type,
                               p_CdFormadeContacto In contactosentidades.cdformadecontacto%Type,
                               p_IdPersonaModif    In entidades.idpersonamodif%Type,
                               p_ok                OUT Integer,
                               p_error             OUT varchar2) IS

   v_Modulo     VARCHAR2(100) := 'PKG_HABILITACION_APP.HabilitacionUsuario';
   v_mail       integer;
   v_mail2      integer;
   v_modificado Integer;

 Begin

   v_mail  := FnExisteCorreo(trim(p_mailnuevo), p_idcuenta); --validacion de existencia en tblentidadaplicacion
   v_mail2 := FnExisteCorreoEnContactos(trim(p_mailnuevo)); --validacion de existencia en contactosentidades

   If v_mail = 1 then
     --si existe en tblentidadaplicacion
     p_ok    := 0;
     p_error := 'El correo ya está asignado a otra cuenta de este mismo cliente.';
     return;
   end if;
   If v_mail = 0 then
     --si no existe en tblentidadaplicacion
     If v_mail2 = 1 then
       -- si existe en contactosentidades
       p_ok    := 0;
       p_error := 'El correo ya existe en los contactos del cliente.';
       return;
     Else
       --Si no existe en contactosentidades
       Update tblentidadaplicacion ta
          set ta.mail = p_mailnuevo, ta.dtupdate = sysdate
        where ta.mail = p_mailviejo;

       pkg_cliente_central.ActualizarContacto ( p_SqContactoEntidad,
                                                p_Identidad,
                                                p_CdFormadeContacto,
                                                p_IdPersonaModif,
                                                p_mailnuevo,
                                                p_ok,
                                                p_error,
                                                v_modificado); --agrego el update a contactosentidades

     end if;
   End If;

   commit;

   p_ok := 1;

 EXCEPTION
   WHEN OTHERS THEN
     p_ok    := 0;
     p_error := sqlerrm;
     n_pkg_vitalpos_log_general.write(2,
                                      'Modulo: ' || v_Modulo || '  Error: ' ||
                                      SQLERRM);
 End UpdCorreoAplicacion;
  /****************************************************************************************
  * Retorna cursor con todos los permisos cargados para ese Rol
  * %v 15/08/2017 - IAquilano - v1.0
  + %v 26/02/2018 - FPeloso - Se eliminó @ac de la tabla tblaplicacionautorizacion
  *****************************************************************************************/

  Procedure GetAplicacionesPermisos(p_vlaplicacion IN TBLENTIDADAPLICACION.VLAPLICACION%type,
                                    cur_out        OUT cursor_type) IS

    v_Modulo VARCHAR2(100) := 'PKG_HABILITACION_APP.GetAplicacionesPermisos';

  Begin

    open cur_out for

      SELECT VLAPLICACION, VLAUTORIZACION, ICVALIDAMAIL
        FROM tblaplicacionautorizacion
       where vlaplicacion = p_vlaplicacion
       GROUP BY VLAPLICACION, VLAUTORIZACION;

  EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_Modulo ||
                                       '  Error: ' || SQLERRM);

  End GetAplicacionesPermisos;


 /****************************************************************************************
  * Retorna cursor con todos los permisos cargados para ese Rol
  * %v 15/08/2017 - IAquilano - v1.0
  *%v  26/02/2018 FPeloso - Se agrega codigo y descripcion al retorno del cursor para que coincida con el modelo de .NET
  *****************************************************************************************/

  Procedure GetAplicaciones(cur_out        OUT cursor_type) IS

    v_Modulo VARCHAR2(100) := 'PKG_HABILITACION_APP.GetAplicacionesPermisos';

  Begin

    open cur_out for

      SELECT rownum Codigo, t.VLAPLICACION Descripcion, t.icvalidamail 
        FROM tblaplicacionautorizacion t;

  EXCEPTION
    WHEN OTHERS THEN
      n_pkg_vitalpos_log_general.write(2,
                                       'Modulo: ' || v_Modulo ||
                                       '  Error: ' || SQLERRM);

  End GetAplicaciones;
  /****************************************************************************************
  * Retorna el Id IndentidadAplicacion necesario para actualizar una habilitación,
  * de la tabla TBLENTIDADAPLICACION
  * %v 30/10/2017 - FPeloso- v1.0
  * %V 08/11/2017 - FPeloso- v1.1 Se saco del la consulta: AND MAIL = p_Mail
  * %v 29/05/2018 - IAquilano: Quito parametro IDPERSONA y MAIL.
  *****************************************************************************************/

Procedure GetIdentidadAplicacion(p_Identidad           IN ENTIDADES.identidad%TYPE,
                                 p_IdCuenta            IN TBLCUENTA.IDCUENTA%TYPE,
                                 p_VlAplicacion        IN TBLENTIDADAPLICACION.VLAPLICACION%TYPE,
                                 p_VlAutorizacion      IN TBLENTIDADAPLICACION.VLAUTORIZACION%TYPE,
                                 p_IdentidadAplicacion OUT TBLENTIDADAPLICACION.IDENTIDADAPLICACIOn%TYPE) IS

  v_Modulo VARCHAR2(100) := 'PKG_HABILITACION_APP.GetIdentidadAplicacion';

BEGIN
  SELECT IDENTIDADAPLICACION
    INTO p_IdentidadAplicacion
    FROM TBLENTIDADAPLICACION
   WHERE IDENTIDAD = p_Identidad
     AND IDCUENTA = p_IdCuenta
     AND VLAPLICACION = p_VlAplicacion
     AND UPPER(VLAUTORIZACION) = UPPER(p_VlAutorizacion);

EXCEPTION
  WHEN OTHERS THEN
    n_pkg_vitalpos_log_general.write(2,
                                     'Modulo: ' || v_Modulo || '  Error: ' ||
                                     SQLERRM);
END GetIdentidadAplicacion;

  /****************************************************************************************
  * Valida si la aplicacion requiere de tarjeta vpv y si el cliente tiene tarjeta vpv
  * %v 07/11/2017 - IAquilano
  *****************************************************************************************/

Procedure GetTieneTarjetaFidelizado(p_identidad  IN entidades.identidad%type,
                                    p_aplicacion IN tblaplicacionautorizacion.vlaplicacion%type,
                                    p_ok         OUT INTEGER,
                                    p_error      OUT VARCHAR2) IS

  v_Modulo       VARCHAR2(100) := 'PKG_HABILITACION_APP.GetTieneTarjetaFidelizado';
  v_icaplicacion integer;
  v_cont         integer;

Begin

  select nvl(ta.icrequieretjcf, 0)
    into v_icaplicacion
    from tblaplicacionautorizacion ta
   where trim(ta.vlaplicacion) = trim(p_aplicacion);

  If v_icaplicacion = 1 then
    select count(*)
      into v_cont
      from tjclientescf tc
     where tc.identidad = p_identidad;

    if v_cont > 0 then
      p_ok := 1;
    else
      p_ok    := 0;
      p_error := 'Cliente sin tarjeta vpv';
    End if;
  Else
    p_ok := 1;
  end if;

EXCEPTION
  WHEN NO_DATA_FOUND THEN
      p_ok    := 0;
      p_error := 'No existen datos de VPV para la aplicación ' || p_aplicacion;

  WHEN OTHERS THEN
    p_ok    := 0;
    p_error := sqlerrm;
    n_pkg_vitalpos_log_general.write(2,
                                     'Modulo: ' || v_Modulo || '  Error: ' ||
                                     SQLERRM);

End GetTieneTarjetaFidelizado;



end PKG_HABILITACION_APP_CENTRAL;
/
