select * from (
SELECT distinct
             vpr.skuid,
             vo.dscucarda name,
             case
               --verifica si tiene oferta vigente
               when vpr.dttoof>=trunc(sysdate) then
                   vpr.priceof
               --verifica si tiene PA vigente
               when vpr.dttoPA>=trunc(sysdate) then
                   vpr.pricePA
                else
                  vpr.pricepl
              end pricepl,
             case
               --verifica si tiene oferta vigente
               when vpr.dttoof>=trunc(sysdate) then
                   round(vpr.priceof-(vpr.priceof*(vo.valoracc/100)),2)
               --verifica si tiene PA vigente
               when vpr.dttoPA>=trunc(sysdate) then
                   round(vpr.pricePA-(vpr.pricePA*(vo.valoracc/100)),2)
                else
                  round(vpr.pricepl-(vpr.pricepl*(vo.valoracc/100)),2)
              end priceof,
             vo.enddateutc dttoof,
--             vo.valorcond*vo.uxb cantminima,
             vs.id_canal_vtex,
             vs.cdsucursal_vtex,
             -- 29/03/2022 - ChM - ajusto leyenda
             case
                when (INSTR(vo.dsleyendacorta,'BULTO')<>0 and INSTR(vo.dsleyendacorta,'cada')<> 0) then
                    'desde '||DECODE(Vo.UXB,0,vo.valorcond,vo.valorcond*vo.uxb)||'  UNIDADES'
                when (INSTR(vo.dsleyendacorta,'BULTO')<> 0 and INSTR(vo.dsleyendacorta,'desde')<> 0) then
                    'desde '||DECODE(Vo.UXB,0,vo.valorcond,vo.valorcond*vo.uxb)||'  UNIDADES'
                else
                  vo.dsleyendacorta
             end dsleyendacorta,
             'Progressive' type
          --   vk.skuid||vs.id_canal_vtex
        FROM vtexprice        vpr,
             vtexsellers      vs,
             vtexproduct      vp,
             vtexsku          vk,
             vtexpromotion    vo,
             vtexpromotionsku vos
       WHERE vs.cdsucursal = vpr.cdsucursal
         and vpr.id_canal = vs.id_canal
         and vpr.id_canal = &p_id_canal
         and vs.icactivo = 1 --solo sucursales activas
         and vpr.icprocesado = 1 --lista solo precios procesados
         and vp.refid = vpr.refid
         and vp.id_canal = vpr.id_canal
         and vp.icprocesado = 1 --solo articulos procesados
         --solo promociones aun vigentes
         and vo.enddateutc>=trunc(sysdate)
         --solo sucursales que no se genero el CSV
         --and vs.iccsv = 0
         and vp.refid = vk.refid
         and vp.id_canal = vk.id_canal
         and vo.id_promo_pos = vos.id_promo_pos
         and vo.id_canal = vpr.id_canal
          --ChM 15112021
         and vo.cdsucursal = vs.cdsucursal
         and vo.icprocesado = 1 --solo promociones procesadas
         and vos.id_promo_hija = vo.id_promo_hija
         and vos.id_canal = vo.id_canal
         and vos.skuid = vk.skuid
         and vos.refid = vk.refid
         and vo.isactive = 1
        --and vp.refid='0153173 '
       UNION
      SELECT distinct
             vpr.skuid,
             'Oferta' name,
             vpr.pricepl,
             vpr.priceof,
             vpr.dttoof,
           --  vk.unitmultiplier cantminima,
             vs.id_canal_vtex,
             vs.cdsucursal_vtex,
             ' ' dsleyendacorta,
             'nominal' type
         --    vk.skuid||vs.id_canal_vtex
        FROM vtexprice    vpr,
             vtexsellers  vs,
             vtexproduct  vp,
             vtexsku      vk
       WHERE vs.cdsucursal = vpr.cdsucursal
         and vpr.id_canal = vs.id_canal
         and vpr.id_canal = &p_id_canal
         and vs.icactivo = 1 --solo sucursales activas
         and vpr.icprocesado = 1 --lista solo precios procesados
         and vp.refid = vpr.refid
         and vp.id_canal = vpr.id_canal
         and vp.icprocesado = 1 --solo articulos procesados
         --solo precios de oferta
         and vpr.priceof is not null
         --solo ofertas aun vigentes
         and vpr.dttoof>=trunc(sysdate)
         --solo sucursales que no se genero el CSV
         --and vs.iccsv = 0
         and vp.refid = vk.refid
         and vp.id_canal = vk.id_canal
         --excluyo articulos en promociones del primer select
         and vk.skuid||vs.id_canal_vtex not in (SELECT distinct
                                                       vos.skuid||vs.id_canal_vtex
                                                  FROM vtexprice        vpr,
                                                       vtexsellers      vs,
                                                       vtexproduct      vp,
                                                       vtexsku          vk,
                                                       vtexpromotion    vo,
                                                       vtexpromotionsku vos
                                                 WHERE vs.cdsucursal = vpr.cdsucursal
                                                   and vpr.id_canal = vs.id_canal
                                                   and vpr.id_canal = &p_id_canal
                                                   and vs.icactivo = 1 --solo sucursales activas
                                                   and vpr.icprocesado = 1 --lista solo precios procesados
                                                   and vp.refid = vpr.refid
                                                   and vp.id_canal = vpr.id_canal
                                                   and vp.icprocesado = 1 --solo articulos procesados
                                                   --solo promociones aun vigentes
                                                   and vo.enddateutc>=trunc(sysdate)
                                                   --solo sucursales que no se genero el CSV
                                                   --and vs.iccsv = 0
                                                   and vp.refid = vk.refid
                                                   and vp.id_canal = vk.id_canal
                                                   and vo.id_promo_pos = vos.id_promo_pos
                                                   and vo.id_canal = vpr.id_canal
                                                   and vos.id_promo_hija = vo.id_promo_hija
                                                   and vos.id_canal = vo.id_canal
                                                    --ChM 15112021
                                                   and vo.cdsucursal = vs.cdsucursal
                                                   and vo.icprocesado = 1 --solo promociones procesadas
                                                   and vos.skuid = vk.skuid
                                                   and vos.refid = vk.refid
                                                    and vo.isactive = 1
                                                  --and vp.refid='0153173 '
                                                )
          --and vp.refid='0153173 '                                       
        UNION
          SELECT distinct
                 vpr.skuid,
                 'Oportunidad' name,
                 vpr.pricepl,
                 vpr.pricepa,
                 vpr.dttopa,
               --  vk.unitmultiplier cantminima,
                 vs.id_canal_vtex,
                 vs.cdsucursal_vtex,
                 ' ' dsleyendacorta,
                 'opportunity' type
             --    vk.skuid||vs.id_canal_vtex
            FROM vtexprice    vpr,
                 vtexsellers  vs,
                 vtexproduct  vp,
                 vtexsku      vk
           WHERE vs.cdsucursal = vpr.cdsucursal
             and vpr.id_canal = vs.id_canal
             and vpr.id_canal = &p_id_canal
             and vs.icactivo = 1 --solo sucursales activas
             and vpr.icprocesado = 1 --lista solo precios procesados
             and vp.refid = vpr.refid
             and vp.id_canal = vpr.id_canal
             and vp.icprocesado = 1 --solo articulos procesados
             --solo precios de acercamiento
             and vpr.pricepa is not null
             --solo PA aun vigentes
             and vpr.dttoPA>=trunc(sysdate)
             --solo sucursales que no se genero el CSV
             --and vs.iccsv = 0
             and vp.refid = vk.refid
             and vp.id_canal = vk.id_canal
             --excluyo articulos en promociones del primer select Y OFERTAS DEL SEGUNDO
             and vk.skuid||vs.id_canal_vtex not in (SELECT distinct
                                                           vos.skuid||vs.id_canal_vtex
                                                      FROM vtexprice        vpr,
                                                           vtexsellers      vs,
                                                           vtexproduct      vp,
                                                           vtexsku          vk,
                                                           vtexpromotion    vo,
                                                           vtexpromotionsku vos
                                                     WHERE vs.cdsucursal = vpr.cdsucursal
                                                       and vpr.id_canal = vs.id_canal
                                                       and vpr.id_canal = &p_id_canal
                                                       and vs.icactivo = 1 --solo sucursales activas
                                                       and vpr.icprocesado = 1 --lista solo precios procesados
                                                       and vp.refid = vpr.refid
                                                       and vp.id_canal = vpr.id_canal
                                                       and vp.icprocesado = 1 --solo articulos procesados
                                                       --solo promociones aun vigentes
                                                       and vo.enddateutc>=trunc(sysdate)
                                                       --solo sucursales que no se genero el CSV
                                                       --and vs.iccsv = 0
                                                       and vp.refid = vk.refid
                                                       and vp.id_canal = vk.id_canal
                                                       and vo.id_promo_pos = vos.id_promo_pos
                                                       and vo.id_canal = vpr.id_canal
                                                       and vos.id_promo_hija = vo.id_promo_hija
                                                       and vos.id_canal = vo.id_canal
                                                        --ChM 15112021
                                                       and vo.cdsucursal = vs.cdsucursal
                                                       and vo.icprocesado = 1 --solo promociones procesadas
                                                       and vos.skuid = vk.skuid
                                                       and vos.refid = vk.refid
                                                       and vo.isactive = 1
                                                       --and vp.refid='0153173 '
                                                   UNION
                                                  SELECT distinct
                                                         vk.skuid||vs.id_canal_vtex
                                                    FROM vtexprice    vpr,
                                                         vtexsellers  vs,
                                                         vtexproduct  vp,
                                                         vtexsku      vk
                                                   WHERE vs.cdsucursal = vpr.cdsucursal
                                                     and vpr.id_canal = vs.id_canal
                                                     and vpr.id_canal = &p_id_canal
                                                     and vs.icactivo = 1 --solo sucursales activas
                                                     and vpr.icprocesado = 1 --lista solo precios procesados
                                                     and vp.refid = vpr.refid
                                                     and vp.id_canal = vpr.id_canal
                                                     and vp.icprocesado = 1 --solo articulos procesados
                                                     --solo precios de oferta
                                                     and vpr.priceof is not null
                                                     --solo ofertas aun vigentes
                                                     and vpr.dttoof>=trunc(sysdate)
                                                     --solo sucursales que no se genero el CSV
                                                     --and vs.iccsv = 0
                                                     and vp.refid = vk.refid
                                                     and vp.id_canal = vk.id_canal
                                                     --and vp.refid='0153173 '
                                                  )
              --and vp.refid='0153173 '
      ORDER BY 1
      )A, 
      vtexsku s
      where A.type ='opportunity'
     and s.skuid=a.skuid
      ;
