SELECT COUNT(*) comi
  FROM TBLSLVCONSOLIDADOCOMI CC 
 WHERE CC.IDCONSOLIDADOM=&P_IDCONSO;
 
SELECT COUNT(*) comidet
 FROM TBLSLVCONSOLIDADOCOMIDET CD,
      TBLSLVCONSOLIDADOCOMI CC
WHERE CC.IDCONSOLIDADOCOMI=CD.IDCONSOLIDADOCOMI
  AND CC.IDCONSOLIDADOM=&P_IDCONSO;

select COUNT(*)
  from tblslvconsolidadopedido cp
 where cp.idconsolidadom =&P_IDCONSO;
 
select COUNT(cpd.idconsolidadopedidodet)
  from tblslvconsolidadopedido cp,
       TBLSLVCONSOLIDADOPEDIDODET cpd
 where cpd.idconsolidadopedido = cp.idconsolidadopedido
   and cp.idconsolidadom =&P_IDCONSO; 

  SELECT count (*) 
   FROM TBLSLVCONSOLIDADOPEDIDOREL   PRE,
        TBLSLVCONSOLIDADOPEDIDO CP
  WHERE CP.IDCONSOLIDADOPEDIDO = PRE.IDCONSOLIDADOPEDIDO
    AND cp.idconsolidadom  =&P_IDCONSO; 
   
select COUNT(*)
  from tblslvconsolidadom cm
 where cm.idconsolidadom =&P_IDCONSO;
 
select COUNT(*)
  from tblslvconsolidadomdet cmd
 where cmd.idconsolidadom =&P_IDCONSO;

 
 
 
