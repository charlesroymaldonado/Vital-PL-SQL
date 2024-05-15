create or replace package PKG_GETDATOS_VTEX is

  -- Author  : CMALDONADO
  -- Created : 12/11/2020 8:14:18 a. m.
  -- Purpose : para manejar los datos de integración con plataforma VTEX
  
   TYPE CURSOR_TYPE IS REF CURSOR;
   
   PROCEDURE Getproduct(p_fecha IN date, Cur_Out Out Cursor_Type);
   PROCEDURE GetSku(p_fecha IN date, Cur_Out Out Cursor_Type);

end PKG_GETDATOS_VTEX;
/
create or replace package body PKG_GETDATOS_VTEX is

  /***********************************************************************************************
  * %v 13/11/2020 - ChM - Obtiene cursor con todos los productos no procesados en VTEX de los atículos 
  *                       nuevos o modificados en AC desde una fecha
  ************************************************************************************************/

  PROCEDURE Getproduct(p_fecha IN date, Cur_Out Out Cursor_Type) IS 

    v_modulo varchar2(100) := 'PKG_GetDatos.GetArticulos';

  BEGIN

    OPEN cur_out FOR
      SELECT vp.productid id,
             vp.name,
             vp.departmentid,
             vp.categoryid,
             vp.brandid,
             vp.linkid, -- OJO falta concatenar el parametro del vinculo donde se alojan todos los productos
             vp.refid,
             vp.isvisible,
             vp.name Description, 
             --en blanco para modificar con valor para insertar            
             decode(vp.icnuevo,1,vp.name,'') Descriptionshort, --explicar al front que si va sin valor no lo actualice
             vp.releasedate,  
             --en blanco para modificar con valor para insertar            
             decode(vp.icnuevo,1,vp.refid,'') KeyWords, --falta concatenar los cdbarras pricipales del articulo                      
             decode(vp.icnuevo,1,vp.name,'') Title,
             vp.isactive,
             decode(vp.icnuevo,1,vp.name,'') MetaTagDescription,
             decode(vp.icnuevo,1,1,'') ShowWithoutStock, --por defecto 1 para insert sin valor para update
             1 Score
        FROM vtexproduct vp
       WHERE (vp.dtinsert >= nvl(p_fecha, vp.dtinsert)
              or vp.dtupdate >= nvl(p_fecha, vp.dtupdate))
          and vp.icprocesado = 0; --lista solo productos por procesar
  EXCEPTION
    WHEN OTHERS THEN
      pkg_log_general.write(1,
                            'Modulo: ' || v_Modulo || '  Error: ' ||
                            SQLERRM);
      raise;
  END Getproduct;
  
  /***********************************************************************************************
  * %v 13/11/2020 - ChM - Obtiene cursor con todos los SKU no procesados en VTEX de los atículos 
  *                       nuevos o modificados en AC desde una fecha
  ************************************************************************************************/

  PROCEDURE GetSku(p_fecha IN date, Cur_Out Out Cursor_Type) IS 

    v_modulo varchar2(100) := 'PKG_GetDatos.GetArticulos';

  BEGIN

    OPEN cur_out FOR
      SELECT vs.skuid id,             
             vp.productid,
             vs.isactive,             
             vp.name,
             vs.refid,
             vs.measurementunit,             
             vs.unitmultiplier                  
        FROM vtexproduct vp,
             vtexsku     vs
       WHERE vp.refid = vs.refid         
         and (vs.creationdate >= nvl(p_fecha, vs.creationdate)
              or vs.dtupdate >= nvl(p_fecha, vs.dtupdate))
         and vs.icprocesado = 0; --lista solo SKU por procesar
  EXCEPTION
    WHEN OTHERS THEN
      pkg_log_general.write(1,
                            'Modulo: ' || v_Modulo || '  Error: ' ||
                            SQLERRM);
      raise;
  END GetSku;

end PKG_GETDATOS_VTEX;
/
