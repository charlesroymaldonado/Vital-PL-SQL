--promociones con error de carga
--si estan en estado 2 pasar a estado 0 para intentar subida a vtex   
-- si hay muchos en estado 0 avisar a help para revisar el estado del servicio web o indicar al desarrollador VTEX
select vp.*
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
         and vp.uxb>=0
         and vp.icrevisadopos is null
         --   valida o incluir solo promos con SKUs
         and vp.id_promo_pos||vp.id_promo_hija||vp.id_canal  in ( select distinct vps.id_promo_pos||vps.id_promo_hija||vps.id_canal from Vtexpromotionsku vps)
        -- group by vs.cdsucursal
        ;
         
-- stock con error
--si estan en estado 2 pasar a estado 0 para intentar subida a vtex   
-- si hay muchos en estado 0 avisar a help para revisar el estado del servicio web o indicar al desarrollador VTEX
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
--si estan en estado 2 pasar a estado 0 para intentar subida a vtex   
-- si hay muchos en estado 0 avisar a help para revisar el estado del servicio web o indicar al desarrollador VTEX
select vpr.cdsucursal,count(*),vpr.id_canal
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
          group by vpr.cdsucursal,vpr.id_canal;
--control de ofertas por sucursal
select vs.cdsucursal,count(*)
      --into p_result
      from vtexsellers vs
     where /*vs.cdsucursal = p_cdsucursal
       and*/ vs.iccsv = 0
       and vs.icactivo = 1
  group by vs.cdsucursal;       
  --controla productos
  --si estan en estado 2 pasar a estado 0 para intentar subida a vtex   
 -- si hay muchos en estado 0 avisar a help para revisar el estado del servicio web o notrificar al desarrollador VTEX
  select *
   --   into p_result
      from vtexproduct vp
     where case
             when &p_tipoerror=0 and vp.icprocesado = 0 then 1--lista solo por procesar
             when &p_tipoerror=1 and vp.icprocesado > 1 then 1--solo con error de carga en VTEX
               else
                 0
           end = 1
           and vp.icrevisadopos is null
      order by vp.isactive     
           --for update
         ;  
--colecciones vacias
--si cant esta en cero avisar a desarrolladro VTEX para subir colecciones
select vc.collectionid,vc.name,vc.id_canal,
           (select count(*)
              from vtexcollectionsku vcs
             where vcs.collectionid=vc.collectionid) cant
     from vtexcollection vc ;
--colecciones con error
--si cant esta en cero avisar a desarrolladro VTEX para subir colecciones
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
--si estan en estado 2 pasar a estado 0 para intentar subida a vtex   
-- si hay muchos en estado 0 avisar a help para revisar el estado del servicio web
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
--si existen en cant cero avisar al desarrollador integracion VTEX
select vc.id_cuenta,
               (select count(*)
                  from vtexaddress  va
                 where va.id_cuenta=vc.id_cuenta
                   and va.clientsid_vtex=vc.clientsid_vtex) cant
          from vtexclients vc
         --si tiene una marca distinta de null no muesta m�s el error en el control
         where vc.icrevisadopos is null;   

--clientes en error   
--si estan en estado 2 pasar a estado 0 para intentar subida a vtex   
-- si hay muchos en estado 0 avisar a help para revisar el estado del servicio web
select *
      from vtexclients vc,
           vtexsellers s
     where case
             --agrego no validar clientes sin direcciones
             when &p_tipoerror=0 and vc.icprocesado = 0 and (select count(*)
                  from vtexaddress  va
                 where va.id_cuenta=vc.id_cuenta
                   and va.clientsid_vtex=vc.clientsid_vtex
                   --solo direcciones activas
                   and va.icactive = 1) > 0 then 1--lista solo por procesar
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
 ---clientes sin direcciones         
 select * from (
select vc.*,
               (select count(*)
                  from vtexaddress  va
                 where va.id_cuenta=vc.id_cuenta
                   and va.clientsid_vtex=vc.clientsid_vtex
                   --solo direcciones activas
                   and va.icactive = 1) cant
          from vtexclients vc
         --si tiene una marca distinta de null no muestra m�s el error en el control
         where vc.icrevisadopos is null
          --solo clientes con cuenta asociada a vtex
           and vc.id_cuenta <>'1'
           ) A
           where A.cant=0  ;            
--ordenes con error
--actualizar las de estdo 2 a cero epserar si bajan ok 
--si continua el estado 2 revisar en la vtexclients si el correo en error tiene el agente asignado
--sino tiene agente notificar por correo a Denise o Pablo gullimonti en ventas para corregir el cliente
--luego que se asigna el cliente se vuelve a estado 0 para bajar pedido
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
     --for update
       ;
       
--enviar por correo a Victo Benavidez para crear y luego darlo de alta en vtexbrand                             
select *
          from (select
              distinct t.vlmarca
                  from TBLARTICULONOMBREECOMMERCE t
                 where upper(trim(t.vlmarca)) not in (select b.name from vtexbrand b ));   
                 
--promociones que no suben por multiple UxB o mas 100 skus
 select 
         distinct p.cdpromo,
                  p.name,
                  p.id_canal,
                  decode(p.uxb,-1,'Multiple UxB',-2,'M�s de 100 Skus') error
             from vtexpromotion p 
            where &v_fecha between p.begindateutc and p.enddateutc
              and p.uxb in (-1,-2)       
         union
          select 
        distinct p.cdpromo cd_promo,
                 p.nombre,
                 c.id_canal,
                 'Promoci�n tipo 1' error
            from tblpromo                 p,                   
                 tblpromo_canal           c                  
           where p.id_promo = c.id_promo
             and p.id_promo_tipo=1                              
             and c.id_canal in ('VE','CO')
             and &v_fecha between p.vigencia_desde and p.vigencia_hasta
        order by id_canal
           ;    
           
           select * from vtexorders o 
             where o.icrevisadopos is not null--o.icprocesado=2
             and o.dtprocesado>=trunc(sysdate-18) 
            -- for update
            ;

--control de PA vigentes
select * from tblprecio p where p.id_canal in ('VE','CO') and p.id_precio_tipo in 
('PA') and p.dtvigenciadesde>=&v_fecha
;
--select * from VTEXORDERS t where t.pedidoid_vtex in ('1210330225042-01', '1210920863816-01','1211002221893-01');
--select * from Vtexclients c where c.email in ('2075657439@qq.com', '975709676@qq.com','chenmei939@gmail.com');
--agrega tapa 9999 por monitor de colecciones
/*insert into tblarticulo_tapa
  select sys_guid(),
         t.cdarticulo,
         t.descripcion,
         t.vigenciadesde,
         t.vigenciahasta,
         t.recargo,
         t.habilitado,
         '9999',
         t.cdcanal
    from tblarticulo_tapa t
   where trunc(sysdate) between t.vigenciadesde and t.vigenciahasta
     and t.cdcanal = 'DISTRIBU'
     and t.cdsucursal = '0020' */
select * from persatclientes p where p.icprocesado>1 and p.observacion='No se pudo obtener el grupo del cliente'--p.dtprocesado>=trunc(sysdate)--
--for update
;
select distinct p.legajo_vendedor||' '||r.dsnombre||' '||r.dsapellido vendedor from persatclientes p, personas r
 where p.icprocesado>1 and p.observacion='No se pudo obtener el grupo del cliente'
 and r.cdlegajo=p.legajo_vendedor;