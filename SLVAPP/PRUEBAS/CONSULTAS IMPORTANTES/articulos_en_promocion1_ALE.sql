/*<TOAD_FILE_CHUNK>*/
SELECT distinct
                            lpad(R.CDPROMO, 8, '0') as CDPROMO,
                            R.ID_PROMO_TIPO TIPO,
                            R.NOMBRE,
                            CP.VALOR                as CANT_COND,
                            vp1.nombre              as UN_MED,
                            CA.CDARTICULO ART_COND,
                            d.vldescripcion, cp2.valor,
                            ca.destacado
                            
  FROM TBLPROMO                     R,
       TBLPROMO_CONDICION           C,
       TBLPROMO_CONDICION_PARAMETRO CP,
       TBLPROMO_CONDICION_PARAMETRO CP2,
       TBLPROMO_CONDICION_PARAMETRO CP3,
       TBLPROMO_TIPO_CONDICION      TC,
       TBLPROMO_TIPO_ACCION         TA,
       TBLPROMO_CONDICION_ARTICULO  CA,
       TBLPROMO_SUCURSAL            SUC,
       TBLPROMO_CANAL               CANAL,
       TBLPROMO_VALOR_PERMITIDO     VP1,
       DESCRIPCIONESARTICULOS D
   WHERE 1=1
   --and R.ID_PROMO_ESTADO = 1 -- Promo Activa
   AND C.ID_PROMO = R.ID_PROMO
   AND TC.ID_PROMO_TIPO_CONDICION = C.ID_PROMO_TIPO_CONDICION
   AND SUC.ID_PROMO = C.ID_PROMO
   AND CANAL.ID_PROMO = C.ID_PROMO
   AND CA.ID_PROMO_CONDICION = C.ID_PROMO_CONDICION
   AND CP.ID_PROMO_CONDICION = C.ID_PROMO_CONDICION
   AND CP.ID_PROMO_PARAMETRO = 6 --Parametro Cantidad
   AND CP2.ID_PROMO_CONDICION = C.ID_PROMO_CONDICION
   AND CP2.ID_PROMO_PARAMETRO = 10 --Parametro Fidelizacion
   AND CP2.VALOR IN ('8', '9') --Fidelizado o Todos
   AND CP3.ID_PROMO_CONDICION = C.ID_PROMO_CONDICION
   AND CP3.ID_PROMO_PARAMETRO = 7 --Parametro Tipo Unidad
   AND VP1.ID_PROMO_VALOR_PERMITIDO = CP3.VALOR
   AND CA.CDARTICULO = D.CDARTICULO
   AND R.ID_PROMO_TIPO<>2
   --and trunc(sysdate) between r.VIGENCIA_DESDE AND r.VIGENCIA_HASTA
  -- AND trim(SUC.CDSUCURSAL) in ('0012') --Sucursal
   --AND trim(CANAL.ID_CANAL) = 'TE' --Canal  
  And r.cdpromo in( 125671)
  --and r.nombre like '%SUAVE%'
/*<TOAD_FILE_CHUNK>*/
   
   SELECT distinct
                            lpad(R.CDPROMO, 8, '0') as CDPROMO,
                            R.ID_PROMO_TIPO TIPO,
                            R.NOMBRE,
                            R.descripcion_cartel,
                            CA.CDARTICULO ART_COND,
                            CP.VALOR                as CANT_COND,
                            vp1.nombre              as UN_MED_COND,
                            AA.CDARTICULO ART_REGALO,
                            AP.valor CANT_REGALO,
                            VP2.nombre as UN_MED_REGALO,
                            cp2.valor
  FROM TBLPROMO                     R,
       TBLPROMO_CONDICION           C,
       TBLPROMO_CONDICION_PARAMETRO CP,
       TBLPROMO_CONDICION_PARAMETRO CP2,
       TBLPROMO_CONDICION_PARAMETRO CP3,
       TBLPROMO_TIPO_CONDICION      TC,
       TBLPROMO_CONDICION_ARTICULO  CA,
       TBLPROMO_SUCURSAL            SUC,
       TBLPROMO_CANAL               CANAL,
       TBLPROMO_VALOR_PERMITIDO     VP1,
       TBLPROMO_VALOR_PERMITIDO     VP2,
       TBLPROMO_ACCION              A,
       TBLPROMO_ACCION_ARTICULO AA,
       TBLPROMO_ACCION_PARAMETRO AP,
       TBLPROMO_ACCION_PARAMETRO AP2,
       DESCRIPCIONESARTICULOS DC,
       DESCRIPCIONESARTICULOS DA
   WHERE 1=1
   --AND R.ID_PROMO_ESTADO = 1 -- Promo Activa
   AND C.ID_PROMO = R.ID_PROMO
   AND TC.ID_PROMO_TIPO_CONDICION = C.ID_PROMO_TIPO_CONDICION
   AND SUC.ID_PROMO = C.ID_PROMO
   AND CANAL.ID_PROMO = C.ID_PROMO
   AND CA.ID_PROMO_CONDICION = C.ID_PROMO_CONDICION
   AND CP.ID_PROMO_CONDICION = C.ID_PROMO_CONDICION
   AND CP.ID_PROMO_PARAMETRO = 6 --Parametro Cantidad
   AND CP2.ID_PROMO_CONDICION = C.ID_PROMO_CONDICION
   AND CP2.ID_PROMO_PARAMETRO = 10 --Parametro Fidelizacion
   AND CP2.VALOR IN ('8', '9') --Fidelizado o Todos
   AND CP3.ID_PROMO_CONDICION = C.ID_PROMO_CONDICION
   AND CP3.ID_PROMO_PARAMETRO = 7 --Parametro Tipo Unidad
   AND VP1.ID_PROMO_VALOR_PERMITIDO = CP3.VALOR
   AND CA.CDARTICULO = DC.CDARTICULO
   AND R.ID_PROMO = A.ID_PROMO
   AND A.ID_PROMO_ACCION = AA.ID_PROMO_ACCION
   AND AA.CDARTICULO = DA.CDARTICULO
   AND AA.ID_PROMO_ACCION = AP.id_promo_accion
   AND AP.ID_PROMO_PARAMETRO = 6 --Parametro Cantidad
   AND AP2.ID_PROMO_ACCION = A.ID_PROMO_ACCION
   AND AP2.ID_PROMO_PARAMETRO = 7 --Parametro Tipo Unidad
   AND VP2.ID_PROMO_VALOR_PERMITIDO = AP2.VALOR
   AND R.ID_PROMO_TIPO=2
   AND trim(SUC.CDSUCURSAL) in ('0010') --Suursal
   AND trim(CANAL.ID_CANAL) = 'SA' --Canal
   --AND trunc(sysdate) between r.VIGENCIA_DESDE AND r.VIGENCIA_HASTA
   And r.cdpromo in( '125652''

   
   
