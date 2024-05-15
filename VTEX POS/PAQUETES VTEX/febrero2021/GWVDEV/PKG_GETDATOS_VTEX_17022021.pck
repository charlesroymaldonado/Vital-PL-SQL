create or replace package PKG_GETDATOS_VTEX is
  -- Author  : CMALDONADO
  -- Created : 12/11/2020 8:14:18 a. m.
  -- Purpose : para manejar los datos de integración con plataforma VTEX
  
   TYPE CURSOR_TYPE IS REF CURSOR;
   
   TYPE arr_refid IS TABLE OF VARCHAR(4000) INDEX BY PLS_INTEGER;
   
   --temporal
PROCEDURE GetBrands(Cur_Out Out Cursor_Type);
PROCEDURE GetCat(Cur_Out Out Cursor_Type);
   
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
                           
  PROCEDURE GetPromotion ( p_cdsucursal In sucursales.cdsucursal%type,                         
                           Cur_Out      Out Cursor_Type);                                          
                           
  PROCEDURE SetPromotion (p_refId IN arr_refId,
                          p_Ok    OUT number,
                          p_error OUT varchar2); 
                          
  PROCEDURE SetPedidosVtex (p_pedidoid_vtex  IN  vtexorders.pedidoid_vtex%type,
                            p_Ok    OUT number,
                            p_error OUT varchar2);
                            
                                                     
  PROCEDURE GetClients (Cur_Out      Out Cursor_Type);
  
  PROCEDURE SetClients (p_refId IN arr_refId,
                        p_Ok    OUT number,
                        p_error OUT varchar2);
                        
  PROCEDURE GetAdress (Cur_Out      Out Cursor_Type);
   
  PROCEDURE SetAdress  (p_refId IN arr_refId,
                        p_Ok    OUT number,
                        p_error OUT varchar2);                        
                           
end PKG_GETDATOS_VTEX;
/
create or replace package body PKG_GETDATOS_VTEX is
  /***********************************************************************************************
  * Temporal code, Hilmer
  ************************************************************************************************/

  PROCEDURE GetBrands(Cur_Out Out Cursor_Type) IS 

    v_modulo varchar2(100) := 'PKG_GetDatos_VTEX.GetBrands';

  BEGIN

    OPEN cur_out FOR
     select * from vtexbrand;
  EXCEPTION
    WHEN OTHERS THEN
      pkg_log_general.write(1,
                            'Modulo: ' || v_Modulo || '  Error: ' ||
                            SQLERRM);
      return;
  END GetBrands;
    /***********************************************************************************************
  * Temporal code, Hilmer
  ************************************************************************************************/

  PROCEDURE GetCat(Cur_Out Out Cursor_Type) IS 

    v_modulo varchar2(100) := 'PKG_GetDatos_VTEX.GetCat';

  BEGIN

    OPEN cur_out FOR
     select * from VTexCatalog;
  EXCEPTION
    WHEN OTHERS THEN
      pkg_log_general.write(1,
                            'Modulo: ' || v_Modulo || '  Error: ' ||
                            SQLERRM);
      return;
  END GetCat;

  /***********************************************************************************************
  * %v 13/11/2020 - ChM - Obtiene cursor con todos los productos no procesados en VTEX de los atículos 
  *                       nuevos o modificados en AC 
  ************************************************************************************************/

  PROCEDURE GetProduct(Cur_Out Out Cursor_Type) IS 

    v_modulo varchar2(100) := 'PKG_GetDatos_VTEX.GetProduct';

  BEGIN

    OPEN cur_out FOR
      SELECT vp.productid id,
             vp.name,
             vp.departmentid,
             vp.subcategoryid categoryid,
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
             vp.uxb,
             vc.variedadname
        FROM vtexproduct vp,
             vtexcatalog vc
       WHERE vp.departmentid = vc.departmentid
         AND vp.categoryid = vc.categoryid
         AND vp.subcategoryid = vc.subcategoryid
         AND nvl(vp.variedadid,0) = nvl(vc.variedadid,0)   
         AND vp.icprocesado = 0; --lista solo productos por procesar
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

    v_modulo        varchar2(100) := 'PKG_GetDatos_VTEX.GetSku';
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

    v_modulo               varchar2(100) := 'PKG_GetDatos_VTEX.SetProduct';
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

    v_modulo               varchar2(100) := 'PKG_GetDatos_VTEX.SetSKU';
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

    v_modulo        varchar2(100) := 'PKG_GetDatos_VTEX.GetSucursales';

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

    v_modulo        varchar2(100) := 'PKG_GetDatos_VTEX.GetStock';

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

    v_modulo               varchar2(100) := 'PKG_GetDatos_VTEX.SetStock';
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
          v_sku_refid:=trim(substr(p_refId(i),1,8));          
          v_icprocesado:=to_number(substr(p_refId(i),9,1));
          v_cdsucursal:=rpad((trim(substr(p_refId(i),10,4))),8,' ');         
          v_observacion:= substr(p_refId(i),14,3999);
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

    v_modulo        varchar2(100) := 'PKG_GetDatos_VTEX.GetPrice';
   
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
         and vs.icactivo = 1 --solo sucursales activas          
         and vpr.icprocesado = 0 --lista solo precios por procesar
         order by vpr.skuid; 
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

    v_modulo               varchar2(100) := 'PKG_GetDatos_VTEX.SetPrice';
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
          v_cdsucursal:=rpad((trim(substr(p_refId(i),10,4))),8,' ');
          v_id_canal:=upper(trim(substr(p_refId(i),14,2)));
          v_observacion:= substr(p_refId(i),16,3999);
         --actualiza a procesado el articulo del arreglo 
         begin
             update vtexprice vp
                set vp.icprocesado = v_icprocesado,
                    vp.dtprocesado = sysdate,                   
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

    v_modulo        varchar2(100) := 'PKG_GetDatos_VTEX.GetCollection';

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

    v_modulo               varchar2(100) := 'PKG_GetDatos_VTEX.SetCollection';    
    
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

    v_modulo        varchar2(100) := 'PKG_GetDatos_VTEX.GetCollectionSKU';

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

    v_modulo               varchar2(100) := 'PKG_GetDatos_VTEX.SetCollectionSKU';
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
          v_observacion:= substr(p_refId(i),14,3999);
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
  
  /***********************************************************************************************
  * %v 30/12/2020 - ChM - Obtiene cursor con todas las promociones no procesadas en VTEX 
  ************************************************************************************************/

  PROCEDURE GetPromotion ( p_cdsucursal In sucursales.cdsucursal%type,                         
                           Cur_Out      Out Cursor_Type) IS 

    v_modulo        varchar2(100) := 'PKG_GetDatos_VTEX.GetPromotion';
   
  BEGIN

    OPEN cur_out FOR
           SELECT DISTINCT
             vp.id_promo_pos,
             vp.name,
             vp.begindateutc,
             vp.enddateutc,
             DECODE(vp.isactive,1,1,0) isactive,--desaticvar si es diferente de 1
             DECODE(vp.type,1,100,vp.valoracc) percentualDiscountValue,
             --multiplica x UxB para convertir bultos en unidades VTEX
             DECODE(vp.type,1,null,'[{' ||vp.valorcond*vp.uxb||', ' ||vp.valoracc||'}]') percentualDiscountValueList,
             --concatena las politicas comerciales separadas por coma
             --1 canal main
             (select distinct LISTAGG(vs2.id_canal_vtex, ', ') WITHIN GROUP (ORDER BY vs2.id_canal_vtex) 
               from vtexpromotion vp2,
                    vtexsellers   vs2 
              where vp2.id_promo_pos=vp.id_promo_pos
                and vp2.cdsucursal=vp.cdsucursal
                and vp2.cdsucursal=vs2.cdsucursal
                and vp2.id_canal=vs2.id_canal) idsSalesChannel,                
                vp.valorcond*vp.uxb minimumQuantityBuyTogether,
                --Para tipo 7 = null Para tipo 1= los que van gratis LA RESTA ENTRE VALOR COND-VALOR ACC
                --multiplica x UxB para convertir bultos en unidades VTEX
                DECODE(vp.type,1,vp.valorcond-vp.valoracc,null)*vp.uxb quantityToAffectBuyTogether,
                --TRUE si monoproducto
                DECODE(vp.multiproducto,0,1)enableBuyTogetherPerSku,
             --concatena los SKUS separados por coma
             ( select distinct LISTAGG(vps.skuid, ', ') WITHIN GROUP (ORDER BY vps.skuid) 
                      from Vtexpromotionsku vps
                     where vps.id_promo_pos=vp.id_promo_pos) listSku1BuyTogether, 
                --Tipo 7 = "progressive" Tipo 1 = "forThePriceOf"
                DECODE(vp.type,1,'forThePriceOf',7,'progressive') type,
                vp.dscucarda cucarda,
                vp.dsleyendacorta descripcion,
                trim(vp.id_promo_vtex) id_promo_vtex,
                vp.cdpromo
        FROM vtexpromotion vp,
             vtexsellers vs 
       WHERE vs.cdsucursal = vp.cdsucursal
         and vs.icactivo = 1 --solo sucursales activas        
         and vp.cdsucursal = p_cdsucursal           
         and vp.icprocesado = 0 --lista solo promociones por procesar         
         --   valida o incluir solo promos con SKUs
         and vp.id_promo_pos  in ( select distinct id_promo_pos from Vtexpromotionsku vps)
         -- verifica no incluir promos con multiproducto de diferentes UxB
         and vp.uxb<>-1
            ;
  EXCEPTION
    WHEN OTHERS THEN
      pkg_log_general.write(1,
                            'Modulo: ' || v_Modulo || '  Error: ' ||
                            SQLERRM);
      return;
  END GetPromotion;
  
  
  /***********************************************************************************************
  * %v 30/12/2020 - ChM - Actualiza a procesado el listado de promociones que recibe del arr_refid
  ************************************************************************************************/

  PROCEDURE SetPromotion (p_refId IN arr_refId,
                          p_Ok    OUT number,
                          p_error OUT varchar2) IS 

    v_modulo               varchar2(100) := 'PKG_GetDatos_VTEX.SetPromotion';
    v_idpromo_pos          vtexpromotion.id_promo_pos%type;
    v_idpromo_vtex         vtexpromotion.id_promo_vtex%type;
    v_icprocesado          vtexpromotion.icprocesado%type;
    v_cdsucursal           vtexpromotion.cdsucursal%type;
   -- v_id_canal             vtexpromotion.id_canal%type;
    v_observacion          vtexpromotion.observacion%type;
    
  BEGIN
    
     IF (p_refId(1) IS NOT NULL and LENGTH(TRIM(p_refId(1)))>1) THEN
       FOR i IN 1 .. p_refId.Count LOOP
          --separa del arreglo del 1-32 char del idpromo_pos          
          --separa del arreglo del 33-73 char del idpromo_vtex 
          --el caracter 74 el estado puede ser : 1 procesado sin error, 2 procesado con error
          -- el carater 76 al 80 cdsucursal
          -- el carater 81 al 82 id_canal
          -- observacion 83 hasta 3900
          v_idpromo_pos:=trim(substr(p_refId(i),1,32));          
          v_idpromo_vtex:=trim(substr(p_refId(i),33,40));
          v_icprocesado:=to_number(substr(p_refId(i),73,1));
          v_cdsucursal:=rpad((trim(substr(p_refId(i),74,4))),8,' ');
        --  v_id_canal:=upper(trim(substr(p_refId(i),81,2)));
          v_observacion:= substr(p_refId(i),78,3900);
         --actualiza a procesado el articulo del arreglo 
         begin
             update vtexpromotion vp
                set vp.id_promo_vtex = v_idpromo_vtex,
                    vp.icprocesado = v_icprocesado,                   
                    vp.dtprocesado = sysdate,
                    vp.observacion = v_observacion
              where vp.id_promo_pos = v_idpromo_pos
                and vp.cdsucursal = v_cdsucursal
               -- and vp.id_canal = v_id_canal        
                     ;
                    
             exception
               when others then
                   pkg_log_general.write(1,
                                       'Modulo: ' || v_modulo ||
                                       ' Detalle Error: promotion ID ' || v_idpromo_pos ||
                                       ' icprocesado ' || v_icprocesado);
           
         end; 
       END LOOP; 
     ELSE     
      p_Ok:=0;
      p_error:='Error Arreglo Vacio no es posible Actualizar Promociones';
   	  ROLLBACK;
      RETURN;  
     END IF;
  COMMIT;   
  p_Ok:=1;       
  EXCEPTION
    WHEN OTHERS THEN      
           pkg_log_general.write(1,
                               'Modulo: ' || v_modulo ||
                               ' Detalle Error: promotion ID ' || v_idpromo_pos ||
                               ' icprocesado ' || v_icprocesado);
      p_Ok:=0;
      p_error:='Error no es posible Actualizar Promociones';
   	  ROLLBACK;
      RETURN;  
  END SetPromotion; 
 
 /*******************************************************************************************************
  * %v 15/01/2021 - ChM - inserta el pedido de VTEX que llega a VITAL para entrar en la cola y ser 
  *                       procesado por AC.
  ********************************************************************************************************/

  PROCEDURE SetPedidosVtex (p_pedidoid_vtex  IN  vtexorders.pedidoid_vtex%type,
                            p_Ok    OUT number,
                            p_error OUT varchar2) IS 

    v_modulo                varchar2(100) := 'PKG_GetDatos_VTEX.SetPedidosVtex';
    v_pedidoid_vtex         vtexorders.pedidoid_vtex%type:=null;

  BEGIN
    --verifica si el id pedido vtex ya existe en la tabla
    begin
        select distinct 
               vo.pedidoid_vtex 
          into v_pedidoid_vtex
          from vtexorders vo
         where vo.pedidoid_vtex = p_pedidoid_vtex;  
        if v_pedidoid_vtex is not null then
            p_Ok:=0;
            p_error:='Error el pedido VTEX ya existe';           
            RETURN;   
        end if;          
    exception 
      when others then
      v_pedidoid_vtex:=null;
    end;     
  
     insert into vtexorders 
                 (pedidoid_vtex,
                 idpedido_pos,
                 icprocesado,
                 dtprocesado,
                 observacion)
          values (p_pedidoid_vtex,
                 null,
                 0, --estado 0 pendiente por pasar a AC
                 sysdate,
                 null);
  commit;  
   p_Ok:=1;
  EXCEPTION
    WHEN OTHERS THEN
      pkg_log_general.write(1,
                            'Modulo: ' || v_Modulo || '  Error: ' ||
                            SQLERRM||'detalle del error ID pedido VTEX: '||p_pedidoid_vtex);
      p_Ok:=0;
      p_error:='Error al insertar pedido de VTEX ' || SQLERRM;
   	  ROLLBACK;
      RETURN;                              
  END SetPedidosVtex;
  
 /***********************************************************************************************
  * %v 08/02/2021 - ChM - Obtiene cursor con todos los clientes nuevos o modificados en AC 
  *                        no procesados en VTEX                         
  ************************************************************************************************/

  PROCEDURE GetClients (Cur_Out      Out Cursor_Type) IS 

    v_modulo        varchar2(100) := 'PKG_GetDatos_VTEX.GetClients';
   
  BEGIN

    OPEN cur_out FOR
      select distinct
             vc.clientsid_vtex,
             vc.agent,
             vc.icactive approved,  
             vs.id_canal_vtex canal,   
             vc.cuit corporateDocument,          
             vc.razonsocial corporateName, 
             vc.idagent,
             1 isCorporate,
             vc.icalcohol reba,             
             vs.cdpostal,
             vs.cdsucursal_vtex sucursal,             
             vc.email,
             vc.id_cuenta customerClass
        from vtexclients vc, 
             vtexsellers vs
             --,
          --   vtexadress  va
       where vc.cdsucursal = vs.cdsucursal
         and vc.id_canal = vs.id_canal
        -- and va.id_cuenta = vc.id_cuenta--solo clientes con dirección
         and vc.icprocesado = 0 --solo pendientes por procesar      
         and length(vc.idagent)>10 --solo clientes con agentes validos
         ;
  EXCEPTION
    WHEN OTHERS THEN
      pkg_log_general.write(1,
                            'Modulo: ' || v_Modulo || '  Error: ' ||
                            SQLERRM);
      return;
  END GetClients;
  
  /***********************************************************************************************
  * %v 08/02/2021 - ChM - Actualiza a procesado el listado de clients que recibe del arr_refid
  ************************************************************************************************/

  PROCEDURE SetClients (p_refId IN arr_refId,
                        p_Ok    OUT number,
                        p_error OUT varchar2) IS 

    v_modulo               varchar2(100) := 'PKG_GetDatos_VTEX.SetClients';
    v_id_cuenta            vtexclients.id_cuenta%type;
    v_clientsid_vtex       vtexclients.clientsid_vtex%type;
    v_icprocesado          vtexclients.icprocesado%type;
    v_observacion          vtexclients.observacion%type;
    
  BEGIN
    
     IF (p_refId(1) IS NOT NULL and LENGTH(TRIM(p_refId(1)))>1) THEN
       FOR i IN 1 .. p_refId.Count LOOP
          --separa del arreglo del 1 + 40 char del idcuenta
          --separa del arreglo del 41 + 40 char del clientsid_vtex
          --el caracter 81 + 1  el estado puede ser : 1 procesado sin error, 2 procesado con error
          --separa del arreglo 82 + 3900 observacion  
          v_id_cuenta:=to_number(substr(p_refId(i),1,40));          
          v_clientsid_vtex:=to_number(substr(p_refId(i),41,40)); 
          v_icprocesado:=to_number(substr(p_refId(i),81,1));
          v_observacion:= substr(p_refId(i),82,3900);
         --actualiza a procesado el cliente del arreglo 
         begin
             update vtexclients vc
                set vc.clientsid_vtex = v_clientsid_vtex,
                    vc.icprocesado = v_icprocesado,
                    vc.dtprocesado = sysdate,                   
                    vc.observacion = v_observacion
              where vc.id_cuenta = v_id_cuenta
              --solo actulizo clientes de registro inicial
                and vc.clientsid_vtex='1';
              --actualizo las direcciones asociadas al cliente para la consistencia de la BD
                update vtexadress va 
                   set va.clientsid_vtex = v_clientsid_vtex
                 where va.id_cuenta = v_id_cuenta 
                   --solo actulizo direcciones de clientes de registro inicial
                   and va.clientsid_vtex='1'
                   ;      
             exception
               when others then
                   pkg_log_general.write(1,
                                       'Modulo: ' || v_modulo ||
                                       ' Detalle Error: id Cuenta ' || v_id_cuenta ||
                                       ' icprocesado ' || v_icprocesado);
           
         end; 
       END LOOP; 
     ELSE     
      p_Ok:=0;
      p_error:='Error Arreglo Vacio no es posible Actualizar Clientes';
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
      p_error:='Error no es posible Actualizar Clientes';
   	  ROLLBACK;
      RETURN;  
  END SetClients; 
  /***********************************************************************************************
  * %v 09/02/2021 - ChM - Obtiene cursor con todas las direcciones de clientes nuevas o modificadas en AC 
  *                        no procesados en VTEX                         
  ************************************************************************************************/

  PROCEDURE GetAdress (Cur_Out      Out Cursor_Type) IS 

    v_modulo        varchar2(100) := 'PKG_GetDatos_VTEX.GetAdress';
   
  BEGIN

    OPEN cur_out FOR          
          select distinct
                 va.id_cuenta,
                 va.clientsid_vtex,
                 va.iddireccion_vtex, 
                 va.cdtipodireccion,
                 va.sqdireccion,
                 va.cdpostal,
                 vs.cdpostal cdpostalsellers,
                 va.dscalle,
                 va.dsnumcalle,
                 va.dslocalidad,
                 va.dsprovincia,
                 va.icactive
            from vtexadress  va,
                 vtexclients vc,
                 vtexsellers vs 
           where va.id_cuenta = vc.id_cuenta
             and va.clientsid_vtex = vc.clientsid_vtex
             and vc.cdsucursal = vs.cdsucursal
             --  solo pendientes por procesar
             and va.icprocesado = 0
             --solo direcciones que ya tienen clientsid_vtex
            -- and va.clientsid_vtex <> '1'
         ;
  EXCEPTION
    WHEN OTHERS THEN
      pkg_log_general.write(1,
                            'Modulo: ' || v_Modulo || '  Error: ' ||
                            SQLERRM);
      return;
  END GetAdress;
  
  /***********************************************************************************************
  * %v 09/02/2021 - ChM - Actualiza a procesado el listado de direcciones que recibe del arr_refid
  ************************************************************************************************/

  PROCEDURE SetAdress  (p_refId IN arr_refId,
                        p_Ok    OUT number,
                        p_error OUT varchar2) IS 

    v_modulo               varchar2(100) := 'PKG_GetDatos_VTEX.SetAdress';
    v_id_cuenta            vtexadress.id_cuenta%type;
    v_clientsid_vtex       vtexadress.clientsid_vtex%type;
    v_iddireccion_vtex     vtexadress.iddireccion_vtex%type;
    v_cdtipodireccion      vtexadress.cdtipodireccion%type;
    v_sqdireccion          vtexadress.sqdireccion%type;
    v_icprocesado          vtexadress.icprocesado%type;
    v_observacion          vtexadress.observacion%type;
    
    
  BEGIN
    
     IF (p_refId(1) IS NOT NULL and LENGTH(TRIM(p_refId(1)))>1) THEN
       FOR i IN 1 .. p_refId.Count LOOP
          --separa del arreglo del 1 + 40 char del idcuenta
          --separa del arreglo del 41 + 40 char del clientsid_vtex
          --separa del arreglo del 81 + 40 char del iddireccion_vtex
          --separa del arreglo del 121 + 8 char del cdtipodireccion
          --separa del arreglo del 129 + 2 char del sqdireccion          
          --el caracter 131 + 1  el estado puede ser : 1 procesado sin error, 2 procesado con error
          --separa del arreglo 132 + 3850 observacion  
          v_id_cuenta:=to_number(substr(p_refId(i),1,40));          
          v_clientsid_vtex:=to_number(substr(p_refId(i),41,40));           
          v_iddireccion_vtex:=to_number(substr(p_refId(i),81,40));
          v_cdtipodireccion:=trim(substr(p_refId(i),121,8));
          v_sqdireccion:= to_number(substr(p_refId(i),129,2));         
          v_icprocesado:=to_number(substr(p_refId(i),131,1));
          v_observacion:= substr(p_refId(i),132,3850);
         --actualiza a procesado la dirección del arreglo 
         begin
                --actualizo las direcciones asociadas al cliente 
                update vtexadress va 
                   set va.iddireccion_vtex = v_iddireccion_vtex,
                       va.icprocesado = v_icprocesado,
                       va.dtprocesado = sysdate,
                       va.observacion = v_observacion 
                 where va.id_cuenta = v_id_cuenta
                   and va.clientsid_vtex = v_clientsid_vtex
                   and va.cdtipodireccion = v_cdtipodireccion
                   and va.sqdireccion = v_sqdireccion;      
             exception
               when others then
                   pkg_log_general.write(1,
                                       'Modulo: ' || v_modulo ||
                                       ' Detalle Error: id Cuenta ' || v_id_cuenta ||
                                       ' icprocesado ' || v_icprocesado);
           
         end; 
       END LOOP; 
     ELSE     
      p_Ok:=0;
      p_error:='Error Arreglo Vacio no es posible Actualizar Direcciones';
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
      p_error:='Error no es posible Actualizar Direcciones';
   	  ROLLBACK;
      RETURN;  
  END SetAdress; 

end PKG_GETDATOS_VTEX;
/
