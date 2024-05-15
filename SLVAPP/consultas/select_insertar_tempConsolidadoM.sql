select  ped.idpedido,ped.transid,ped.id_canal
  from pedidos                ped
where ped.transid='MALEGREAOFFMDM'
      and ped.idcomisionista is null



select '{D2F7D889-60EE-46A4-96E6-6AF3D21358A2}' ident,
       '{D2F7D889-60EE-46A4-96E6-6AF3D21358A2}' comi,
       ped.id_canal,
       20 bto,
       ped.transid
  from pedidos                ped
       , documentos           do
where ped.iddoctrx = do.iddoctrx
      and ped.iddoctrx=do.iddoctrx
      AND do.dtdocumento >='20/10/2015' --g_FechaComisionista
      and ped.idcomisionista='{D2F7D889-60EE-46A4-96E6-6AF3D21358A2}  '
      and ped.idcomisionista is not null

--comisionista ejemplo
insert into tbltmpslvConsolidadoM m 
select '{D2F7D889-60EE-46A4-96E6-6AF3D21358A2}' ident,
       '{D2F7D889-60EE-46A4-96E6-6AF3D21358A2}' comi,
       ped.id_canal,
       20 bto,
       ped.transid
  from pedidos                ped
       , documentos           do
where ped.iddoctrx = do.iddoctrx
      and ped.iddoctrx=do.iddoctrx
      AND do.dtdocumento >='20/10/2015' --g_FechaComisionista
      and ped.idcomisionista='{D2F7D889-60EE-46A4-96E6-6AF3D21358A2}  '
      and ped.idcomisionista is not null
      
      
      select * from tbltmpslvConsolidadoM;
      delete tbltmpslvConsolidadoM;
--reparto ejemplo     
 select sys_guid(),'{D2F7D889-60EE-46A4-96E6-6AF3D21358A2}',NULL comi,P.canal, 2 bot, P.transid
      from (select distinct ped.id_canal canal, ped.transid transid
            from pedidos ped
            where  ped.transid ='MALEGREAOFFMDM') P;    
            
                 
