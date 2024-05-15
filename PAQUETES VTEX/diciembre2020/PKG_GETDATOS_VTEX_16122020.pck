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
                       
  PROCEDURE SetStock (p_refId IN arr_refId,
                      p_Ok    OUT number,
                      p_error OUT varchar2);                      
                      
  PROCEDURE GetPrice ( p_cdsucursal In sucursales.cdsucursal%type,                         
                       Cur_Out      Out Cursor_Type);
                                                                           
  PROCEDURE SetPrice (p_refId IN arr_refId,
                      p_Ok    OUT number,
                      p_error OUT varchar2);
                      
  PROCEDURE GetCollection (Cur_Out       Out Cursor_Type);
  
  PROCEDURE SetCollection (p_collectionID IN vtexcollection.collectionid%type,
                           p_dtfrom       IN vtexcollection.dtfrom%type,
                           p_dtto         IN vtexcollection.dtto%type,
                           p_Ok           OUT number,
                           p_error        OUT varchar2);                      
                      
end PKG_GETDATOS_VTEX;
/
create or replace package body PKG_GETDATOS_VTEX is

  /***********************************************************************************************
  * %v 13/11/2020 - ChM - Obtiene cursor con todos los productos no procesados en VTEX de los atículos 
  *                       nuevos o modificados en AC 
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
  *                       nuevos o modificados en AC 
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
          --los siguientes del 10 al 18 (8 caracteres) se dejan para la secuencia del productoid de VTEX
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
          --los siguientes del 10 al 18 (8 caracteres) se dejan para la secuencia del productoid de VTEX
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
          select * from vtexsellers vs 
            where vs.cdsucursal ='9999' 
              and (p_idcanal=0 or vs.id_canal='VE')
              and vs.icactivo = 1
              ;
    ELSE
        OPEN cur_out FOR
          select * from vtexsellers vs
           where vs.cdsucursal <>'9999' 
             and (p_idcanal=0 or vs.id_canal='VE')              
              and vs.icactivo = 1
             ;
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
            and vp.isactive = 1
            --solo stock por procesar
            and vst.icprocesado = 0;
    
  EXCEPTION
    WHEN OTHERS THEN
      pkg_log_general.write(1,
                            'Modulo: ' || v_Modulo || '  Error: ' ||
                            SQLERRM);
      return;
  END GetStock;
  
  /***********************************************************************************************
  * %v 15/12/2020 - ChM - Actualiza a procesado el listado de stock que recibe del arr_refid
  ************************************************************************************************/

  PROCEDURE SetStock (p_refId IN arr_refId,
                      p_Ok    OUT number,
                      p_error OUT varchar2) IS 

    v_modulo               varchar2(100) := 'PKG_GetDatos.SetStock';
    v_sku_refid            vtexstock.cdarticulo%type;
    v_icprocesado          vtexstock.icprocesado%type;
    v_cdsucursal           vtexstock.cdsucursal%type;
    v_observacion          varchar2(3999);
    
  BEGIN
    
     IF (p_refId(1) IS NOT NULL and LENGTH(TRIM(p_refId(1)))>1) THEN
       FOR i IN 1 .. p_refId.Count LOOP
          --separa del arreglo del 1-8 char del skuid equivalente al cdarticulo
          --el caracter 9 el estado puede ser : 1 procesado sin error, 2 procesado con error
          -- el carater 10 al 14 cd sucursal
          -- el carater 15 al 16 id_canal
          v_sku_refid:=substr(p_refId(i),1,8);          
          v_icprocesado:=to_number(substr(p_refId(i),9,1));
          v_cdsucursal:=rpad((trim(substr(p_refId(i),10,4))),8,0);         
          v_observacion:= substr(p_refId(i),15,3999);
         --actualiza a procesado el articulo del arreglo 
         begin
             update Vtexstock vs
                set vs.icprocesado = v_icprocesado,
                    vs.dtprocesado = sysdate,                    
                    vs.observacion = v_observacion
              where vs.cdarticulo = v_sku_refid
                and vs.cdsucursal = v_cdsucursal;      
               
             exception
               when others then
                   pkg_log_general.write(1,
                                       'Modulo: ' || v_modulo ||
                                       ' Detalle Error: cdarticulo ' || v_sku_refid ||
                                       ' icprocesado ' || v_icprocesado);
           
         end; 
       END LOOP; 
     ELSE     
      p_Ok:=0;
      p_error:='Error arreglo vacio no es posible actualizar Stock';
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
      p_error:='Error no es posible actualizar Stock';
   	  ROLLBACK;
      RETURN;  
  END SetStock;
  
    
  /***********************************************************************************************
  * %v 09/12/2020 - ChM - Obtiene cursor con todos los precios no procesados en VTEX de los atículos 
  *                       nuevos o modificados en AC 
  ************************************************************************************************/

  PROCEDURE GetPrice ( p_cdsucursal In sucursales.cdsucursal%type,                         
                       Cur_Out      Out Cursor_Type) IS 

    v_modulo        varchar2(100) := 'PKG_GetDatos.GetPrice';
   
  BEGIN

    OPEN cur_out FOR
      SELECT vpr.cdsucursal,
             vpr.id_canal,
             vs.id_canal_vtex,
             vpr.skuid,
             vpr.pricepl,
             vpr.priceof,
             vpr.dtfromof,
             vpr.dttoof
        FROM vtexprice   vpr,
             vtexsellers vs 
       WHERE vs.cdsucursal = vpr.cdsucursal
         and vpr.id_canal = vs.id_canal
         and vpr.cdsucursal = p_cdsucursal           
         and vpr.icprocesado = 0
         order by vpr.skuid; --lista solo precios por procesar
  EXCEPTION
    WHEN OTHERS THEN
      pkg_log_general.write(1,
                            'Modulo: ' || v_Modulo || '  Error: ' ||
                            SQLERRM);
      return;
  END GetPrice;
  
  /***********************************************************************************************
  * %v 09/12/2020 - ChM - Actualiza a procesado el listado de precios que recibe del arr_refid
  ************************************************************************************************/

  PROCEDURE SetPrice (p_refId IN arr_refId,
                        p_Ok    OUT number,
                        p_error OUT varchar2) IS 

    v_modulo               varchar2(100) := 'PKG_GetDatos.SetPrice';
    v_skuid                vtexprice.skuid%type;
    v_icprocesado          vtexprice.icprocesado%type;
    v_cdsucursal           vtexprice.cdsucursal%type;
    v_id_canal             vtexprice.id_canal%type;
    v_observacion          varchar2(3999);
    
  BEGIN
    
     IF (p_refId(1) IS NOT NULL and LENGTH(TRIM(p_refId(1)))>1) THEN
       FOR i IN 1 .. p_refId.Count LOOP
          --separa del arreglo del 1-8 char del skuid equivalente al cdarticulo
          --el caracter 9 el estado puede ser : 1 procesado sin error, 2 procesado con error
          -- el carater 10 al 14 cd sucursal
          -- el carater 15 al 16 id_canal
          v_skuid:=to_number(substr(p_refId(i),1,8));          
          v_icprocesado:=to_number(substr(p_refId(i),9,1));
          v_cdsucursal:=rpad((trim(substr(p_refId(i),10,4))),8,0);
          v_id_canal:=upper(trim(substr(p_refId(i),15,2)));
          v_observacion:= substr(p_refId(i),17,3999);
         --actualiza a procesado el articulo del arreglo 
         begin
             update vtexprice vp
                set vp.icprocesado = v_icprocesado,
                    vp.dtprocesado = sysdate,
                    vp.dtupdate    = sysdate,
                    vp.observacion = v_observacion
              where vp.skuid = v_skuid
                and vp.cdsucursal = v_cdsucursal
                and vp.id_canal = v_id_canal;
                    
             exception
               when others then
                   pkg_log_general.write(1,
                                       'Modulo: ' || v_modulo ||
                                       ' Detalle Error: cdarticulo ' || v_skuid ||
                                       ' icprocesado ' || v_icprocesado);
           
         end; 
       END LOOP; 
     ELSE     
      p_Ok:=0;
      p_error:='Error Arreglo Vacio no es posible Actualizar Precios';
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
      p_error:='Error no es posible Actualizar Precios';
   	  ROLLBACK;
      RETURN;  
  END SetPrice;
  /*******************************************************************************************************
  * %v 16/12/2020 - ChM - Obtiene cursor con todas las colecciones necesarias para para solicitar fecha de
  *                       vigencia de las mismas a VTEX
  ********************************************************************************************************/

  PROCEDURE GetCollection (Cur_Out       Out Cursor_Type) IS 

    v_modulo        varchar2(100) := 'PKG_GetDatos.GetCollection';

  BEGIN
     OPEN cur_out FOR
          select * from vtexcollection;
    
  EXCEPTION
    WHEN OTHERS THEN
      pkg_log_general.write(1,
                            'Modulo: ' || v_Modulo || '  Error: ' ||
                            SQLERRM);
      return;
  END GetCollection;
  
  /***********************************************************************************************
  * %v 16/12/2020 - ChM - Actualiza fecha de vigencia de las colecciones de VTEX a POS
                          de esta manera se cargan los SKU solo en Colecciones Vigentes en VTEX
  ************************************************************************************************/

  PROCEDURE SetCollection (p_collectionID IN vtexcollection.collectionid%type,
                           p_dtfrom       IN vtexcollection.dtfrom%type,
                           p_dtto         IN vtexcollection.dtto%type,
                           p_Ok           OUT number,
                           p_error        OUT varchar2) IS 

    v_modulo               varchar2(100) := 'PKG_GetDatos.SetCollection';    
    
  BEGIN
     
     update Vtexcollection vc
        set vc.dtfrom = p_dtfrom,
            vc.dtto = p_dtto
      where vc.collectionid = p_collectionID; 
                 
  COMMIT;   
  p_Ok:=1;       
  EXCEPTION
    WHEN OTHERS THEN
      pkg_log_general.write(1,
                               'Modulo: ' || v_modulo ||
                               ' Detalle Error: collectionID ' || p_collectionID ||'  Error: ' ||SQLERRM);     
      p_Ok:=0;
      p_error:='Error no es posible actualizar collection';
   	  ROLLBACK;
      RETURN;  
  END SetCollection;
   
   /*******************************************************************************************************
  * %v 16/12/2020 - ChM - Obtiene cursor con todas los SKUS y idColletion que se deben agregar a una 
  *                       colección de VTEX
  ********************************************************************************************************/

  PROCEDURE GetCollectionSKU (p_fecha       IN  vtexcollection.dtfrom%type,
                              Cur_Out       Out Cursor_Type) IS 

    v_modulo        varchar2(100) := 'PKG_GetDatos.GetCollectionSKU';

  BEGIN
     OPEN cur_out FOR
          select vs.collectionid,
                 vs.skuid,
                 vs.refid 
            from vtexcollectionSKU vs,
                 vtexcollection    vc
           where vs.collectionid = vc.collectionid
             --solo colecciones vigentes en VTEX
             and p_fecha between vc.dtfrom and vc.dtto;
    
  EXCEPTION
    WHEN OTHERS THEN
      pkg_log_general.write(1,
                            'Modulo: ' || v_Modulo || '  Error: ' ||
                            SQLERRM);
      return;
  END GetCollectionSKU;
  
  /***********************************************************************************************
  * %v 16/12/2020 - ChM - Actualiza a procesado el SKU de la Collection que recibe en arreglo
  ************************************************************************************************/

  PROCEDURE SetCollectionSKU (p_refId IN arr_refId,
                              p_Ok    OUT number,
                              p_error OUT varchar2) IS 

    v_modulo               varchar2(100) := 'PKG_GetDatos.SetCollectionSKU';
    v_collectionID         vtexcollectionsku.collectionid%type;
    v_refid                vtexcollectionsku.refid%type;
    v_icprocesado          vtexcollectionsku.icprocesado%type;    
    v_observacion          varchar2(3999);
    
  BEGIN
    
     IF (p_refId(1) IS NOT NULL and LENGTH(TRIM(p_refId(1)))>1) THEN
       FOR i IN 1 .. p_refId.Count LOOP
          --separa del arreglo del 1-8 char del refid equivalente al cdarticulo
          --el caracter 9 el estado puede ser : 1 procesado sin error, 2 procesado con error
          -- el carater 10 al 14 collectionID
          
          v_refid:=substr(p_refId(i),1,8);          
          v_icprocesado:=to_number(substr(p_refId(i),9,1));
          v_collectionID:=lpad((trim(substr(p_refId(i),10,4))),8,0);         
          v_observacion:= substr(p_refId(i),15,3999);
         --actualiza a procesado el sku
         begin
             update Vtexcollectionsku vs
                set vs.icprocesado = v_icprocesado,
                    vs.dtprocesado = sysdate,                    
                    vs.observacion = v_observacion
              where vs.refid = v_refid
                and vs.collectionid = v_collectionID;
                    
             exception
               when others then
                   pkg_log_general.write(1,
                                       'Modulo: ' || v_modulo ||
                                       ' Detalle Error: cdarticulo ' || v_refid ||
                                       ' icprocesado ' || v_icprocesado);
           
         end; 
       END LOOP; 
     ELSE     
      p_Ok:=0;
      p_error:='Error arreglo vacio no es posible actualizar collectionSKU';
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
      p_error:='Error no es posible actualizar collectionSKU';
   	  ROLLBACK;
      RETURN;  
  END SetCollectionSKU;
   
  

end PKG_GETDATOS_VTEX;
/
