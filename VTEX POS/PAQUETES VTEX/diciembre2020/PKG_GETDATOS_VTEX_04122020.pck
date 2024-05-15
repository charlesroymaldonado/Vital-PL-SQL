create or replace package PKG_GETDATOS_VTEX is

  -- Author  : CMALDONADO
  -- Created : 12/11/2020 8:14:18 a. m.
  -- Purpose : para manejar los datos de integración con plataforma VTEX
  
   TYPE CURSOR_TYPE IS REF CURSOR;
   
   TYPE arr_refid IS TABLE OF VARCHAR(4000) INDEX BY PLS_INTEGER;
   
   PROCEDURE Getproduct(Cur_Out Out Cursor_Type);
   
   PROCEDURE GetSku(Cur_Out Out Cursor_Type);
   
   PROCEDURE SetProduct (p_refId IN arr_refId,
                        p_Ok    OUT number,
                        p_error OUT varchar2);
                        
   PROCEDURE SetSku(p_refId IN arr_refId,
                   p_Ok    OUT number,
                   p_error OUT varchar2);
                   
   PROCEDURE GetSucursales (p_main     in integer default 0, 
                           p_idcanal  in integer default 0, 
                           Cur_Out    Out Cursor_Type);    
                           
   PROCEDURE GetStock (p_cdSucursal  In sucursales.cdsucursal%type,                       
                      Cur_Out       Out Cursor_Type);                                   

end PKG_GETDATOS_VTEX;
/
create or replace package body PKG_GETDATOS_VTEX is

  /***********************************************************************************************
  * %v 13/11/2020 - ChM - Obtiene cursor con todos los productos no procesados en VTEX de los atículos 
  *                       nuevos o modificados en AC desde una fecha
  ************************************************************************************************/

  PROCEDURE GetProduct(Cur_Out Out Cursor_Type) IS 

    v_modulo varchar2(100) := 'PKG_GetDatos.GetProduct';

  BEGIN

    OPEN cur_out FOR
      SELECT vp.productid id,
             vp.name,
             vp.departmentid,
             vp.categoryid,
             vp.brandid,
             vp.linkid, -- OJO falta concatenar el parametro del vinculo donde se alojan todos los productos
             trim(vp.refid) refid,
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
             1 Score,
             vp.factor,
             vp.uxb
        FROM vtexproduct vp
       WHERE vp.icprocesado = 0; --lista solo productos por procesar
  EXCEPTION
    WHEN OTHERS THEN
      pkg_log_general.write(1,
                            'Modulo: ' || v_Modulo || '  Error: ' ||
                            SQLERRM);
      return;
  END GetProduct;
  
  /***********************************************************************************************
  * %v 13/11/2020 - ChM - Obtiene cursor con todos los SKU no procesados en VTEX de los atículos 
  *                       nuevos o modificados en AC desde una fecha
  ************************************************************************************************/

  PROCEDURE GetSku(Cur_Out Out Cursor_Type) IS 

    v_modulo        varchar2(100) := 'PKG_GetDatos.GetSku';
    v_urlimages     parametrossistema.vlparametro%type:=PKG_API_REST.getvlparametro('VTEX_URLImagenes', 'ConfigVTEX');
  BEGIN

    OPEN cur_out FOR
      SELECT vs.skuid id,             
             vp.productid,
             vs.isactive,             
             vp.name,
             trim(vs.refid) refid,
             1 PackagedHeight,
             1 PackagedLength,
             1 PackagedWidth,
             1 PackagedWeightKg,
             vs.creationdate,
             vs.ean,
             vs.measurementunit,             
             vs.unitmultiplier,
             v_urlimages||to_number(vs.refid)||'.jpg' ImageURL                 
        FROM vtexproduct vp,
             vtexsku     vs
       WHERE vp.refid = vs.refid         
         and vs.icprocesado = 0; --lista solo SKU por procesar
  EXCEPTION
    WHEN OTHERS THEN
      pkg_log_general.write(1,
                            'Modulo: ' || v_Modulo || '  Error: ' ||
                            SQLERRM);
      return;
  END GetSku;
  
  /***********************************************************************************************
  * %v 13/11/2020 - ChM - Actualiza a procesado el listado de productos que recibe del arr_refid
  ************************************************************************************************/

  PROCEDURE SetProduct (p_refId IN arr_refId,
                        p_Ok    OUT number,
                        p_error OUT varchar2) IS 

    v_modulo               varchar2(100) := 'PKG_GetDatos.SetProduct';
    v_refid                vtexproduct.refid%type;
    v_icprocesado          vtexproduct.icprocesado%type;
    v_productID            vtexproduct.productid%type;
    v_observacion          vtexproduct.observacion%type;
    
  BEGIN
    
     IF (p_refId(1) IS NOT NULL and LENGTH(TRIM(p_refId(1)))>1) THEN
       FOR i IN 1 .. p_refId.Count LOOP
          --separa del arreglo del 1-8 char del refid equivalente al cdarticulo
          --el caracter 9 EL estado puede ser : 1 procesado sin error, 2 procesado con error
          --los siguientes del 10 al 30 (20 caracteres) se dejan para la secuencia del productoid de VTEX
          v_refid:=lpad((trim(substr(p_refId(i),1,8))),7,0);
          v_icprocesado:=to_number(substr(p_refId(i),9,1));
          v_productID:=to_number(substr(p_refId(i),10,8));
          v_observacion:= substr(p_refId(i),18,3999);
         --actualiza a procesado el articulo del arreglo 
         begin
             update vtexproduct vp 
                set vp.icprocesado=v_icprocesado,
                    vp.productid = v_productID,
                    vp.observacion = v_observacion,
                    vp.dtprocesado = sysdate                  
              where vp.refid = v_refid;
             exception
               when others then
                   pkg_log_general.write(1,
                                       'Modulo: ' || v_modulo ||
                                       ' Detalle Error: cdarticulo ' || v_refid ||
                                       ' icprocesado ' || v_icprocesado ||
                                       ' ProductoID ' || v_productID);
           
         end; 
       END LOOP; 
     ELSE     
      p_Ok:=0;
      p_error:='Error Arreglo Vacio no es posible Actualizar Productos';
   	  ROLLBACK;
      RETURN;  
     END IF;
  COMMIT;   
  p_Ok:=1;       
  EXCEPTION
    WHEN OTHERS THEN
      pkg_log_general.write(1,
                            'Modulo: ' || v_Modulo || '  Error: ' ||
                            SQLERRM);
      p_Ok:=0;
      p_error:='Error no es posible Actualizar Productos';
   	  ROLLBACK;
      RETURN;  
  END SetProduct;
  
  /***********************************************************************************************
  * %v 13/11/2020 - ChM - Actualiza a procesado el listado de sku que recibe del arr_refid
  ************************************************************************************************/

  PROCEDURE SetSku(p_refId IN arr_refId,
                   p_Ok    OUT number,
                   p_error OUT varchar2) IS 

    v_modulo               varchar2(100) := 'PKG_GetDatos.SetSKU';
    v_SKUid                vtexsku.skuid%type;
    v_icprocesado          vtexproduct.icprocesado%type;
    v_productID            vtexproduct.productid%type;
    v_observacion          vtexsku.observacion%type;
    
  BEGIN
    
     IF (p_refId(1) IS NOT NULL and LENGTH(TRIM(p_refId(1)))>1) THEN
       FOR i IN 1 .. p_refId.Count LOOP
          --separa del arreglo del 1-8 char del skuid equivalente al cdarticulo
          --el caracter 9 EL estado puede ser : 1 procesado sin error, 2 procesado con error
          --los siguientes del 10 al 30 (20 caracteres) se dejan para la secuencia del productoid de VTEX
          v_SKUid:=lpad((trim(substr(p_refId(i),1,8))),7,0);
          v_icprocesado:=to_number(substr(p_refId(i),9,1));         
          v_productID:=to_number(substr(p_refId(i),10,8));
          v_observacion:= substr(p_refId(i),18,3999);
         --actualiza a procesado el SKU del arreglo 
         begin
             update Vtexsku vs
                set vs.icprocesado=v_icprocesado,
                    vs.observacion=v_observacion,
                    vs.dtprocesado = sysdate                    
              where vs.skuid = v_SKUid;
             exception
               when others then
                   pkg_log_general.write(1,
                                       'Modulo: ' || v_modulo ||
                                       ' Detalle Error: cdarticulo ' || v_SKUid ||
                                       ' icprocesado ' || v_icprocesado ||
                                       ' ProductoID ' || v_productID);
           
         end; 
       END LOOP; 
     ELSE     
      p_Ok:=0;
      p_error:='Error Arreglo Vacio no es posible Actualizar SKU';
   	  ROLLBACK;
      RETURN;  
     END IF;
  COMMIT;   
  p_Ok:=1;       
  EXCEPTION
    WHEN OTHERS THEN
      pkg_log_general.write(1,
                            'Modulo: ' || v_Modulo || '  Error: ' ||
                            SQLERRM);
      p_Ok:=0;
      p_error:='Error no es posible Actualizar SKU';
   	  ROLLBACK;
      RETURN;  
  END SetSku;
     
  /*******************************************************************************************************
  * %v 24/11/2020 - ChM - Obtiene cursor con todas las sucursales disponibles                        
  *                       con información necesaria para establecer conexion con VTEX
  *                       si p_main = 1 solo devuelve la conexión al main de vtex sucursal 9999
  *                       si p_idcanal = 1 devuelve solo la conexión al canal vendedor VE de cada sucursal
  ********************************************************************************************************/

  PROCEDURE GetSucursales (p_main     in integer default 0, 
                           p_idcanal  in integer default 0, 
                           Cur_Out    Out Cursor_Type) IS 

    v_modulo        varchar2(100) := 'PKG_GetDatos.GetSucursales';

  BEGIN
    IF p_main = 1 THEN
        OPEN cur_out FOR
          select * from vtexsellers vs where vs.cdsucursal ='9999' and (p_idcanal=0 or vs.id_canal='VE');
    ELSE
        OPEN cur_out FOR
          select * from vtexsellers vs where vs.cdsucursal <>'9999' and (p_idcanal=0 or vs.id_canal='VE');
    END IF;      
  EXCEPTION
    WHEN OTHERS THEN
      pkg_log_general.write(1,
                            'Modulo: ' || v_Modulo || '  Error: ' ||
                            SQLERRM);
      return;
  END GetSucursales;
  
  /*******************************************************************************************************
  * %v 24/11/2020 - ChM - Obtiene cursor con SKUID y STOCK necesarios para subir a VTEX
  ********************************************************************************************************/

  PROCEDURE GetStock (p_cdSucursal  In sucursales.cdsucursal%type,                       
                      Cur_Out       Out Cursor_Type) IS 

    v_modulo        varchar2(100) := 'PKG_GetDatos.GetStock';

  BEGIN
     OPEN cur_out FOR
          select vst.cdarticulo SKU_refid,
                 vst.qtstock
           from vtexstock   vst,
                vtexproduct vp
          where vst.cdsucursal = p_cdsucursal
            and vst.cdarticulo = vp.refid
            --solo productos procesados y activos en VTEX
            and vp.icprocesado = 1
            and vp.productid is not null           
            and vp.dtprocesado is not null
            and vp.isactive = 1;
    
  EXCEPTION
    WHEN OTHERS THEN
      pkg_log_general.write(1,
                            'Modulo: ' || v_Modulo || '  Error: ' ||
                            SQLERRM);
      return;
  END GetStock;

end PKG_GETDATOS_VTEX;
/
