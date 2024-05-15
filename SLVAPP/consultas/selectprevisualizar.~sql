       SELECT  gs2.cdgrupo || ' - ' || gs2.dsgruposector || ' (' || SEC.DSSECTOR || ')'  Sector,
               A.cod || '- ' || A.desc_art articulo,
               trunc((A.cant / A.uxb), 0) || ' BTO/ ' || mod(A.cant, A.uxb) || --divide las cantidades por bulto y unidad 
               ' UN' cantidad,
               trunc((A.stock / A.uxb), 0) || ' BTO/ ' || mod(A.stock, A.uxb) ||
               ' UN' stock,
               A.uxb,
               A.ubicacion
          FROM (select gs.cdsector sector,
                       art.cdarticulo COD,
                       des.vldescripcion DESC_ART,
                       SUM(detped.qtunidadmedidabase) CANT,
                       PKG_SLV_Articulos.GetStockArticulos(art.cdarticulo) STOCK,
                       posapp.n_pkg_vitalpos_materiales.GetUxB(art.cdarticulo) UXB,
                       PKG_SLV_Articulos.GetUbicacionArticulos(ART.cdarticulo) UBICACION
                  from pedidos                ped,
                       documentos             docped,
                       detallepedidos         detped,
                       articulos              art,
                       descripcionesarticulos des,
                       tblslv_grupo_sector    gs
                 where ped.iddoctrx = docped.iddoctrx
                   and ped.idpedido = detped.idpedido
                   and art.cdarticulo = detped.cdarticulo
                   and ped.icestadosistema = 2
                   and docped.cdsucursal='0020'
                    AND gs.cdsucursal='0020'
                  /* and ped.transid in
                       (select mm.transid
                          from tbltmpslvConsolidadoM MM
                         where MM.idpersona = p_idPersona)*/
                   and art.cdarticulo = des.cdarticulo
                   and trim(gs.cdsector) = trim(decode(trim(art.cdidentificador),'01','26',art.cdsector))
                   and gs.cdsucursal = '0020'
              group by gs.cdsector, art.cdarticulo, des.vldescripcion
               ORDER BY 1,3) A, sectores sec, tblslv_grupo_sector gs2 
         WHERE trunc((cant / uxb), 0) >= 4       --mayor a bultos a consolidar
           AND A.sector = sec.cdsector
           AND sec.cdsector=gs2.cdsector
           AND gs2.cdsucursal='0020'
