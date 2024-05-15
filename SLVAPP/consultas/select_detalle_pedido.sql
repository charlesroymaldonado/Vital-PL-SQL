--reparto      
      select art.cdarticulo COD, 
                   des.vldescripcion DESC_ART,
                   SUM(detped.qtunidadmedidabase) CANT,
                   posapp.n_pkg_vitalpos_materiales.GetUxB(art.cdarticulo) UXB
             from pedidos                ped,
                  documentos             docped,
                  detallepedidos         detped,
                  articulos              art,
                  descripcionesarticulos des                 
             where ped.iddoctrx = docped.iddoctrx
                   and ped.idpedido = detped.idpedido
                   and art.cdarticulo = detped.cdarticulo
                   and ped.transid in ('RTESIO0APJJ8CB')
                   and art.cdarticulo = des.cdarticulo
                   --AND ped.icestadosistema =2
                 --  AND ped.id_canal <> 'CO'
                   AND nvl(ped.iczonafranca, 0) = 0
                   AND ped.idcnpedido is null        
                   AND docped.cdsucursal = '0020'
             group by 
                      art.cdarticulo,
                      des.vldescripcion

--comisionista
            select art.cdarticulo COD, 
                   des.vldescripcion DESC_ART,
                   SUM(detped.qtunidadmedidabase) CANT,
                   posapp.n_pkg_vitalpos_materiales.GetUxB(art.cdarticulo) UXB
             from pedidos                ped,
                  documentos             docped,
                  detallepedidos         detped,
                  articulos              art,
                  descripcionesarticulos des
             where ped.iddoctrx = docped.iddoctrx                 
                   and ped.idpedido = detped.idpedido
                   and art.cdarticulo = detped.cdarticulo
                   and ped.idcomisionista in ('{C6570172-0961-44EC-994D-35233243169F}  ')
                   and art.cdarticulo = des.cdarticulo
                   AND ped.icestadosistema =2
                   AND ped.id_canal = 'CO'
                   AND nvl(ped.iczonafranca, 0) = 0
                   AND ped.idcnpedido is null        
                   AND docped.cdsucursal = '0020'
                   AND docped.dtdocumento >= '20/10/2015'
             group by  art.cdarticulo,
                       des.vldescripcion                      
                      
  -- DATOS GENERALES REPARTO                    
            select distinct 
                   su.dssucursal,
                   e.cdcuit,
                   e.dsrazonsocial,
                   ped.id_canal,
                   ped.Ammonto
             from pedidos                ped,
                  documentos             docped,
                  entidades              e,
                  sucursales               su
             where ped.iddoctrx = docped.iddoctrx
                   and docped.cdsucursal = su.cdsucursal
                   and docped.identidadreal = e.identidad 
                   and ped.transid in ('RTESIO0APJJ8CB')
                 --AND ped.icestadosistema =2
                  -- AND ped.id_canal <> 'CO'
                   AND nvl(ped.iczonafranca, 0) = 0
                   AND ped.idcnpedido is null        
                   AND docped.cdsucursal = '0020'
                    
 -- DATOS GENERALES COMISIONISTA                     
select distinct 
             su.dssucursal,            
             e.cdcuit CUIT,
             e.dsrazonsocial RAZONSOCIAL,
             ped.id_canal CANAL,
             sum(ped.Ammonto) ammonto
      
       from  pedidos                ped,
             documentos             docped,
             entidades              e,
             sucursales             su
      where  ped.iddoctrx = docped.iddoctrx
             and docped.cdsucursal = su.cdsucursal 
             AND ped.idcomisionista = e.identidad
             and ped.idcomisionista = '{C6570172-0961-44EC-994D-35233243169F}'
             AND ped.icestadosistema =2
             AND ped.id_canal = 'CO'
             AND nvl(ped.iczonafranca, 0) = 0
             AND ped.idcnpedido is null        
             AND docped.cdsucursal = '0020'
             AND docped.dtdocumento >= '20/10/2015'
        group by su.dssucursal,
                 ped.id_canal,
                 e.cdcuit,
                 e.dsrazonsocial 
                                             