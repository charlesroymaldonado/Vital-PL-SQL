--promociones con error de carga
select *
        from vtexpromotion vp,
             vtexsellers   vs
           --solo promos vigentes
       where &v_fecha between vp.begindateutc and vp.enddateutc
         and vs.icactivo = 1 --solo sucursales activas
         and vs.id_canal = vp.id_canal
         and vp.cdsucursal = vs.cdsucursal
        -- and vp.cdsucursal = p_cdsucursal
         and case
               when &p_tipoerror=0 and vp.icprocesado = 0 then 1--lista solo promociones por procesar
               when &p_tipoerror=1 and vp.icprocesado > 1 then 1--solo promos con error de carga en VTEX
                 else
                   0
             end = 1
         --   valida incluir solo promos con SKUs
         and vp.id_promo_pos  in ( select distinct id_promo_pos from Vtexpromotionsku vps)
          -- verifica no incluir promos con multiproducto de diferentes UxB o con m�s de 100 SKUS
         and vp.uxb>0
         and vp.icrevisadopos is null
        -- group by vs.cdsucursal
        ;
         
-- stock con error
select vst.cdsucursal,count(*)
    --   into p_result
       from vtexstock   vst,
            vtexproduct vp,
            vtexsellers vs
      where /*vst.cdsucursal = &p_cdsucursal
        and*/ vs.cdsucursal=vst.cdsucursal
        and vs.icactivo=1   
        and vp.id_canal = vs.id_canal 
        and vp.id_canal = vst.id_canal         
        and vst.cdarticulo = vp.refid
        --solo productos procesados y activos en VTEX
        and vp.icprocesado = 1
        and vp.dtprocesado is not null
        and vp.isactive = 1
        and (vst.icprocesado = 0 or vst.icprocesado>1)
   group by vst.cdsucursal;
--precios con error
select vpr.cdsucursal,count(*)
     -- into p_result
      FROM vtexprice   vpr,
           vtexproduct  vp,
           vtexsellers vs
     WHERE /*vpr.cdsucursal = p_cdsucursal
       and*/ vp.refid = vpr.refid
        and vs.cdsucursal=vpr.cdsucursal
        and vs.icactivo=1   
        and vp.id_canal = vs.id_canal 
        and vp.id_canal = vpr.id_canal 
       --solo productos procesados
       and vp.icprocesado = 1
        and (vpr.icprocesado = 0 or vpr.icprocesado>1)
          group by vpr.cdsucursal;
--control de ofertas por sucursal
select vs.cdsucursal,count(*)
      --into p_result
      from vtexsellers vs
     where /*vs.cdsucursal = p_cdsucursal
       and*/ vs.iccsv = 0
       and vs.icactivo = 1
  group by vs.cdsucursal;       
  --controla productos
  select *
   --   into p_result
      from vtexproduct vp
     where case
             when &p_tipoerror=0 and vp.icprocesado = 0 then 1--lista solo por procesar
             when &p_tipoerror=1 and vp.icprocesado > 1 then 1--solo con error de carga en VTEX
               else
                 0
           end = 1
         --  for update
         ;  
--colecciones vacias
select vc.collectionid,
           (select count(*)
              from vtexcollectionsku vcs
             where vcs.collectionid=vc.collectionid) cant
     from vtexcollection vc ;
--colecciones con error
select count(*)
     -- into p_result
      from vtexcollectionsku vc
     where case
             when &p_tipoerror=0 and vc.icprocesado = 0 then 1--lista solo por procesar
             when &p_tipoerror=1 and vc.icprocesado > 1 then 1--solo con error de carga en VTEX
               else
                 0
           end = 1;               
--direcciones con error
select *
      from vtexaddress  va
     where
       --solo direcciones que ya tienen clientsid_vtex
           va.clientsid_vtex <> '1'
       and case
             when &p_tipoerror=0 and va.icprocesado = 0 then 1--lista solo por procesar
             when &p_tipoerror=1 and va.icprocesado > 1 then 1--solo con error de carga en VTEX
               else
                 0
           end = 1
        --si tiene una marca distinta de null no muesta m�s el error en el control
        and va.icrevisadopos is null
        --no envio direcciones anuladas nunca creadas en VTEX
             and case
                 	when va.icactive = 0 and va.iddireccion_vtex is null then 0
                    else 1
                 end = 1
--for update                 
                 ;   
                 
--clientes sin direcciones
select vc.id_cuenta,
               (select count(*)
                  from vtexaddress  va
                 where va.id_cuenta=vc.id_cuenta
                   and va.clientsid_vtex=vc.clientsid_vtex) cant
          from vtexclients vc
         --si tiene una marca distinta de null no muesta m�s el error en el control
         where vc.icrevisadopos is null;   

--clientes en error de baja no aplicada
select distinct                 
                 VC.*                 
            from        vtexclients  vc
           where vc.icprocesado = 0
             --solo direcciones que ya tienen clientsid_vtex
             and vc.clientsid_vtex <> '1' 
             and vc.id_cuenta ='1'
             and vc.icactive=0
         ;
--clientes en error      
select *
      from vtexclients vc,
           vtexsellers s
     where case
             when &p_tipoerror=0 and vc.icprocesado = 0 then 1--lista solo por procesar
             when &p_tipoerror=1 and vc.icprocesado > 1 then 1--solo con error de carga en VTEX
               else
                 0
           end = 1
       and s.icactivo = 1    
       and s.cdsucursal = vc.cdsucursal
       and s.id_canal = vc.id_canal
        --si tiene una marca distinta de null no muesta m�s el error en el control
       and vc.icrevisadopos is null  
        -- si es canal NO el error es de usuario
        and vc.id_canal<>'NO'
--for update        
        ;    
        
/*--- clientes activos en vtex y pos que no suben ACTUALIZACION por tener canal NO
--PASAR CORREO A VICTOR PARA AJUSTE INMEDIATO
select c.cuit,c.razonsocial, c.email,c.idagent from vtexclients c where c.icactive=1 and c.icprocesado<>1 and c.clientsid_vtex<>'1';
--clientes activos en vtex y INACTIVOS pos que no suben ACTUALIZACION por tener canal NO
--BORRAR DE MD CON VICTOR Y LUEGO BORRAR DE POS
select * from vtexclients c where c.icactive=0 and c.icprocesado<>1 and c.clientsid_vtex<>'1';    */   
          
--ordenes con error
select *
         -- into p_result
          from vtexorders vo
    where case
             when &p_tipoerror=0 and vo.icprocesado = 0 then 1--lista solo por procesar
             when &p_tipoerror=1 and vo.icprocesado > 1 then 1--solo con error de carga en VTEX
               else
                 0
          end = 1
       --si tiene una marca distinta de null no muesta m�s el error en el control
       and vo.icrevisadopos is null
    -- for update
       ;
                             
select *
          from (select
              distinct t.vlmarca
                  from TBLARTICULONOMBREECOMMERCE t
                 where upper(trim(t.vlmarca)) not in (select b.name from vtexbrand b ));   
                 
--ajsute de pedidos con probleams de promos 
      -- select * from VTEXORDERS t where t.icprocesado=2 and t.dtprocesado>=trunc(sysdate)
--for update  
;
/*select * from vtexpromotion p 
where p.id_promo_pos in (select s.id_promo_pos 
                           from vtexpromotionsku s,vtexpromotion p1 
                          where s.refid='0170782 ' and s.id_promo_pos=p1.id_promo_pos 
                            and trunc(sysdate) between p1.begindateutc and p1.enddateutc) */
--for update                  
        
--select * from VTEXSKU t where t.icprocesado=2