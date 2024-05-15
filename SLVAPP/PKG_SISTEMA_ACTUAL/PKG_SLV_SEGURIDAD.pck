CREATE OR REPLACE PACKAGE SLVAPP.PKG_SLV_SEGURIDAD AS
    TYPE CURSOR_TYPE IS REF CURSOR;

PROCEDURE GetUsuario(r_cursor OUT CURSOR_TYPE, P_NOMBREUSUARIO IN TBLSLV_USUARIO.NOMBREUSUARIO%TYPE);

PROCEDURE Login(r_cursor OUT CURSOR_TYPE,
                P_USERNAME IN Varchar2,
                P_PASSWORD IN Varchar2);

PROCEDURE GetPermisosMenu(r_cursor OUT CURSOR_TYPE,
                P_ID_USUARIO IN TBLSLV_USUARIO.ID_USUARIO%TYPE);


--IAquilano
PROCEDURE AltaUsuarioConFuncion(p_nombre   IN tblslv_usuario.nombreusuario%type,
                                p_icactivo IN tblslv_usuario.icactivo%type);

Procedure getfuncionesslv(r_cursor OUT CURSOR_TYPE);

Procedure ValidarUsuarioSLV(p_loginusr IN tblslv_usuario.nombreusuario%type,
                            p_icactivo OUT integer,
                            p_ok       OUT integer,
                            p_error    OUT varchar2);

PROCEDURE EliminarFuncion(p_loginusr  IN tblslv_usuario.nombreusuario%type,
                          p_idfuncion IN tblslv_funcion.id_funcion%type,
                          p_ok        OUT integer,
                          p_error     OUT varchar2);

PROCEDURE GuardarFuncion(p_loginusr  IN tblslv_usuario.nombreusuario%type,
                         p_idfuncion IN tblslv_funcion.id_funcion%type,
                         p_icactivo  IN tblslv_usuario.icactivo%type,
                         p_ok        OUT integer,
                         p_error     OUT varchar2);
                         
 Procedure DesactivarArmador(p_idpersona IN personas.idpersona%type,
                             p_ok        OUT integer,
                             p_error     OUT varchar2);
                             
Procedure ActivarArmador(p_idpersona IN personas.idpersona%type,
                          p_sucursal  IN sucursales.cdsucursal%type,
                          p_ok        OUT integer,
                          p_error     OUT varchar2);                                                      

END PKG_SLV_SEGURIDAD;
/
CREATE OR REPLACE PACKAGE BODY SLVAPP.PKG_SLV_SEGURIDAD AS
/*
    Recibe el nombre de usuario y la clave como parametro
    Chequea que esten correctos y retorna el id de la persona si es correcto
    Si hay un error devuelun mensaje de error y el codigo -1 como valor de retorno
*/
PROCEDURE Login(r_cursor OUT CURSOR_TYPE,
                P_USERNAME IN Varchar2, P_PASSWORD IN Varchar2) IS
        idpers CHAR(40);
        err    VARCHAR2(200);
        ret    NUMBER;
    BEGIN
        ret := POSLOGIN.DOLOGIN(P_USERNAME, P_PASSWORD, idpers, err);
        OPEN r_cursor FOR
            SELECT idpers IDPERSONA,
                   err    DSERROR,
                   ret    RETVAL
            from dual;
        NULL;
    END Login;



/*
    Devuelve los datos de un usuario por su nombre de usuario (POS)
*/
PROCEDURE GetUsuario(r_cursor OUT CURSOR_TYPE,
        P_NOMBREUSUARIO IN TBLSLV_USUARIO.NOMBREUSUARIO%TYPE)
IS
BEGIN
    OPEN r_cursor FOR
    SELECT ID_USUARIO, NOMBREUSUARIO
    FROM TBLSLV_USUARIO
    WHERE TRIM(UPPER(NOMBREUSUARIO)) =TRIM( UPPER(P_NOMBREUSUARIO))--JBODNAR 03/12/2013 SE AGREGA TRIM POR ERROR DE ESPACIO
    and icactivo = 1; --Agrego el ICActivo Iaquilano
END GetUsuario;


/*
    Devuelve los datos de los permisos a nivel de menu de un usuario
*/
PROCEDURE GetPermisosMenu(r_cursor OUT CURSOR_TYPE,
                    P_ID_USUARIO IN TBLSLV_USUARIO.ID_USUARIO%TYPE)
IS
BEGIN
    OPEN r_cursor FOR
    SELECT MNU.ID_MENU, MNU.NOMBRE, MNU.ID_MENU_PADRE, MNU.MNU_NOMBRE
    FROM TBLSLV_MENU MNU
    INNER JOIN TBLSLV_MENUROL MR ON MR.ID_MENU = MNU.ID_MENU
    INNER JOIN TBLSLV_ROL R ON R.ID_ROL = MR.ID_ROL
    INNER JOIN TBLSLV_ROLFUNCION RF ON RF.ID_ROL = R.ID_ROL
    INNER JOIN TBLSLV_FUNCION F ON F.ID_FUNCION = RF.ID_FUNCION
    INNER JOIN TBLSLV_USUARIOFUNCION UF ON UF.ID_FUNCION = F.ID_FUNCION
    INNER JOIN TBLSLV_USUARIO USR ON USR.ID_USUARIO = UF.ID_USUARIO
                                  AND USR.ID_USUARIO = P_ID_USUARIO;
END GetPermisosMenu;

/* --------------------------------------------------------------------------------------------------
%v 9/12/2014 APW Alta básica de usuario
-----------------------------------------------------------------------------------------------------*/
PROCEDURE AltaUsuarioParametrizada(p_nombre IN tblslv_usuario.nombreusuario%type,
                                   p_icactivo IN tblslv_usuario.icactivo%type,
                                   p_idfuncion IN number)
IS

v_idusuario tblslv_usuario.id_usuario%type;
v_iduf tblslv_usuariofuncion.id_uf%type;
msgerror tblslv_log.mensaje%type  ;
v_usuario cuentasusuarios.dsloginname%type;

BEGIN

  BEGIN -- tiene que existir como "usuario pos"
    select c.dsloginname
    into v_usuario
    from cuentasusuarios c
    where c.dsloginname = p_nombre;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        raise_application_error(-20101, 'No existe el usuario en CUENTASUSUARIOS');
        return;
  END;

  BEGIN -- no tiene que existir como "usuario slv"
    select u.id_usuario
    into v_idusuario
    from tblslv_usuario u
    where u.nombreusuario = p_nombre;

    if v_idusuario is not null then
      raise_application_error(-20101, 'Ya existe el usuario '||p_nombre);
      return;
    end if;

    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        null;
  END;

  select max(u.id_usuario)
  into v_idusuario
  from tblslv_usuario u;

  v_idusuario := v_idusuario+1;
  insert into tblslv_usuario values (v_idusuario, p_nombre, p_icactivo);


  select max(uf.id_uf)
  into v_iduf
  from tblslv_usuariofuncion uf;

  v_iduf := v_iduf+1;
  insert into tblslv_usuariofuncion values (v_iduf, v_idusuario, p_idfuncion);

  commit;

  EXCEPTION
  WHEN OTHERS THEN
      msgerror := SQLERRM;
      PKG_slv_common.logwrite('AltaUsuarioParametrizada','Error:' || msgerror);
      RAISE;

END AltaUsuarioParametrizada;

/* --------------------------------------------------------------------------------------------------
%v 9/12/2014 APW Alta Usuario SLV con funcion parametrizada
-----------------------------------------------------------------------------------------------------*/

PROCEDURE AltaUsuarioConFuncion(p_nombre IN tblslv_usuario.nombreusuario%type,
                                p_icactivo IN tblslv_usuario.icactivo%type)
IS

v_idusuario tblslv_usuario.id_usuario%type;
v_iduf tblslv_usuariofuncion.id_uf%type;
msgerror tblslv_log.mensaje%type  ;
v_usuario cuentasusuarios.dsloginname%type;

BEGIN

  BEGIN -- tiene que existir como "usuario pos"
    select c.dsloginname
    into v_usuario
    from cuentasusuarios c
    where c.dsloginname = p_nombre;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        raise_application_error(-20101, 'No existe el usuario en CUENTASUSUARIOS');
        return;
  END;

  BEGIN -- no tiene que existir como "usuario slv"
    select u.id_usuario
    into v_idusuario
    from tblslv_usuario u
    where u.nombreusuario = p_nombre;

    if v_idusuario is not null then
      raise_application_error(-20101, 'Ya existe el usuario '||p_nombre);
      return;
    end if;

    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        null;
  END;

  select max(u.id_usuario)
  into v_idusuario
  from tblslv_usuario u;

  v_idusuario := v_idusuario+1;
  insert into tblslv_usuario values (v_idusuario, p_nombre, p_icactivo);


  select max(uf.id_uf)
  into v_iduf
  from tblslv_usuariofuncion uf;

  v_iduf := v_iduf+1;
  insert into tblslv_usuariofuncion values (v_iduf, v_idusuario, 1);

  commit;

  EXCEPTION
  WHEN OTHERS THEN
      msgerror := SQLERRM;
      PKG_slv_common.logwrite('AltaUsuarioConFuncion','Error:' || msgerror);
      RAISE;

END AltaUsuarioConFuncion;

  /* --------------------------------------------------------------------------------------------------
  %v 31/10/2018 - IAquilano: Cursor con todas las funciones del SLV
  -----------------------------------------------------------------------------------------------------*/
  Procedure getfuncionesslv(r_cursor OUT CURSOR_TYPE) is

  msgerror tblslv_log.mensaje%type  ;

  Begin
    open r_cursor for
      Select * from tblslv_funcion;

  EXCEPTION
    WHEN OTHERS THEN
      PKG_slv_common.logwrite('getfuncionesslv', 'Error:' || msgerror);
      RAISE;
  End getfuncionesslv;
                       



  /* --------------------------------------------------------------------------------------------------
  %v 31/10/2018 - IAquilano: Validar si tiene o no usuario en slv.
  -----------------------------------------------------------------------------------------------------*/
  Procedure ValidarUsuarioSLV(p_loginusr IN tblslv_usuario.nombreusuario%type,
                               p_icactivo OUT integer,
                               p_ok       OUT integer,
                               p_error    OUT varchar2) is

    msgerror tblslv_log.mensaje%type;

  Begin
    Begin
      select 1, tu.icactivo
        into p_ok, p_icactivo
        from tblslv_usuario tu
       where tu.nombreusuario = p_loginusr;
    
    Exception
      when no_data_found then
        p_ok       := 0;
        p_icactivo := 0;
        p_error    := 'Ese usuario no existe en el slv';
    end;

  EXCEPTION
    WHEN OTHERS THEN
      PKG_slv_common.logwrite('getfuncionesslv', 'Error:' || msgerror);
      RAISE;
  End ValidarUsuarioSLV;


--
  /* --------------------------------------------------------------------------------------------------
  %v 05/11/2018 - IAquilano: Alta de usuario/funcion de SLV
  -----------------------------------------------------------------------------------------------------*/
    PROCEDURE GuardarFuncion(p_loginusr  IN tblslv_usuario.nombreusuario%type,
                             p_idfuncion IN tblslv_funcion.id_funcion%type,
                             p_icactivo  IN tblslv_usuario.icactivo%type,
                             p_ok        OUT integer,
                             p_error     OUT varchar2) IS
      msgerror    tblslv_log.mensaje%type;
      v_idusuario number;
      v_maxidusr  number;
      v_cont      integer;
    BEGIN
      p_ok    := 0;
      p_error := '';
      --Cargo id de usuario 
      select tu.id_usuario
        into v_idusuario
        from tblslv_usuario tu
       where tu.nombreusuario = p_loginusr;
    
      update tblslv_usuario tu
         set tu.icactivo = p_icactivo
       where tu.nombreusuario = p_loginusr;
    
      INSERT INTO tblslv_usuariofuncion
        (id_uf, id_usuario, id_funcion)
      VALUES
        (v_idusuario, v_idusuario, p_idfuncion);
      
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        --si no encuentra nada antes, es un alta
        --busco el max id del usuario
        select max(tu.id_usuario) into v_maxidusr from tblslv_usuario tu;
        --Genero el id del nuevo usuario
        v_cont := v_maxidusr + 1;
        --Alta en la tabla usuario
        insert into tblslv_usuario
          (id_usuario, nombreusuario, icactivo)
        values
          (v_cont, p_loginusr, '1');
        --Alta en la tabla funcion
        insert into tblslv_usuariofuncion
          (id_uf, id_usuario, id_funcion)
        values
          (v_cont, v_cont, p_idfuncion);
      
        p_ok    := 1;
        p_error := '' ;
        
      WHEN OTHERS THEN
        p_ok    := 0;
        p_error := sqlerrm;
        PKG_slv_common.logwrite('getfuncionesslv', 'Error:' || msgerror);
        RAISE;
    END GuardarFuncion;
/* --------------------------------------------------------------------------------------------------
  %v 05/11/2018 - IAquilano: Borrado de Funciones
  -----------------------------------------------------------------------------------------------------*/   
  
  PROCEDURE EliminarFuncion(p_loginusr  IN tblslv_usuario.nombreusuario%type,
                            p_idfuncion IN tblslv_funcion.id_funcion%type,
                            p_ok        OUT integer,
                            p_error     OUT varchar2) IS
  
    msgerror    tblslv_log.mensaje%type;
    v_idusuario number;
  BEGIN
  
    --Cargo id de usuario 
    select tu.id_usuario
      into v_idusuario
      from tblslv_usuario tu
     where tu.nombreusuario = p_loginusr;
  
    DELETE tblslv_usuariofuncion tu
     WHERE tu.id_usuario = v_idusuario
       AND tu.id_funcion = p_idfuncion;

  
    p_ok := 1;
    p_error:= '';
  
  EXCEPTION
    WHEN OTHERS THEN
      p_ok    := 0;
      p_error := sqlerrm;
      PKG_slv_common.logwrite('getfuncionesslv', 'Error:' || msgerror);
      RAISE;
  END EliminarFuncion;

/* --------------------------------------------------------------------------------------------------
  %v 16/11/2018 - IAquilano: Inserta o habilita un armador
  -----------------------------------------------------------------------------------------------------*/   
 Procedure ActivarArmador(p_idpersona IN personas.idpersona%type,
                          p_sucursal  IN sucursales.cdsucursal%type,
                          p_ok        OUT integer,
                          p_error     OUT varchar2) is
 
   msgerror   tblslv_log.mensaje%type;
   v_nombre   personas.dsnombre%type;
   v_apellido personas.dsapellido%type;
   v_legajo   personas.cdlegajo%type;
   v_id       tblslv_armadores.idarmador%type;
 
 Begin
 
   begin
     select p.dsnombre, p.dsapellido, p.cdlegajo
       into v_nombre, v_apellido, v_legajo
       from personas p
      where p.idpersona = p_idpersona;
   
   exception
     when no_data_found then
       p_ok    := 0;
       p_error := 'No existe la persona en la sucursal';
   end;
 
   Begin
     select ts.idarmador
       into v_id
       from tblslv_armadores ts
      where ts.legajo = v_legajo;
   
     update tblslv_armadores ta
        set ta.idestado = 1
      where ta.idarmador = v_id;
   
   Exception
     when no_data_found then
     
       select max(ta.idarmador) + 1 into v_id from tblslv_armadores ta;
     
       Insert into tblslv_armadores
         (idarmador, nombre, apellido, legajo, cdsucursal, idestado)
       values
         (v_id, v_nombre, v_apellido, v_legajo, p_sucursal, '1');
         
   End;
   p_ok    := 1;
   p_error := null;
 
 EXCEPTION
   WHEN OTHERS THEN
     p_ok    := 0;
     p_error := sqlerrm;
     PKG_slv_common.logwrite('ActivarArmador', 'Error:' || msgerror);
     
     RAISE;
       
 end ActivarArmador;
 
 /* --------------------------------------------------------------------------------------------------
  %v 16/11/2018 - IAquilano: Desactiva Armador
  -----------------------------------------------------------------------------------------------------*/   
 Procedure DesactivarArmador(p_idpersona IN personas.idpersona%type,
                             p_ok        OUT integer,
                             p_error     OUT varchar2) is
 
   msgerror   tblslv_log.mensaje%type;
   v_nombre   personas.dsnombre%type;
   v_apellido personas.dsapellido%type;
   v_legajo   personas.cdlegajo%type;
   v_id       tblslv_armadores.idarmador%type;
 
 Begin
 
   begin
     select p.dsnombre, p.dsapellido, p.cdlegajo
       into v_nombre, v_apellido, v_legajo
       from personas p
      where p.idpersona = p_idpersona;
   
   exception
     when no_data_found then
       p_ok    := 0;
       p_error := 'No existe la persona en la sucursal';
   end;
 
   Begin
     select ts.idarmador
       into v_id
       from tblslv_armadores ts
      where ts.legajo = v_legajo;
   
     update tblslv_armadores ta
        set ta.idestado = 0
      where ta.idarmador = v_id;
     
     p_ok := 1;
     p_error := null;
   
   Exception
     when no_data_found then
     p_ok := 0;
     p_error := 'No existe ese armador'; 
     
   End;
 
 EXCEPTION
   WHEN OTHERS THEN
     p_ok    := 0;
     p_error := sqlerrm;
     PKG_slv_common.logwrite('DesactivarArmador', 'Error:' || msgerror);
     
     RAISE;       
 
 end DesactivarArmador;




END PKG_SLV_SEGURIDAD;
/
