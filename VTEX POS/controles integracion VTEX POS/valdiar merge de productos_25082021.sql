with  vp as ( select * from vtexproduct p /*where p.dtupdate>=trunc(sysdate)*/),
      tvp as (
select distinct to_number(ar.cdarticulo) productID,
             nvl(trim(ae.vldescripcion),da.vldescripcion) name,
             vc.departmentid,
             vc.categoryid,
             vc.subcategoryid,
             NVL(vb.brandid,99999) brandid, --MARCA GENERICA
             nvl(trim(ae.vldescripcion),da.vldescripcion)||'-'||to_number(ar.cdarticulo) linkid,
             ar.cdarticulo refid,
             --estado 07 articulo activo pero no visible al cliente
             DECODE(trim(ar.cdestadoplu),'07',0,1) isvisible,
             nvl(trim(ae.vldescripcion),da.vldescripcion) description,
             ar.dtinsertplu releasedate,
             1 isactive,
             1 icnuevo,
             sysdate dtinsert,
             null dtupdate,
             decode(n_pkg_vitalpos_materiales.GetUxB(ar.cdarticulo),0,1,n_pkg_vitalpos_materiales.GetUxB(ar.cdarticulo)) UXB,
             null observacion,
             0 icprocesado, --indica se debe procesar a VTEX
             null dtprocesado,
             trim(ac.VARIEDADNAME) VARIEDAD,
             &pc_id_canal id_canal
       from articulos                    ar,
            descripcionesarticulos       da,
            tblarticulonombreecommerce   ae,
            tblctgryarticulocategorizado a,
            VTEXARTICULOSCATEGORIZADOS   ac,
            tblctgrydepartamento         d,
            tblctgryuniverso             u,
            tblctgrycategoria            c,
            tblctgrysubcategoria         sc,
            vtexbrand                    vb,
            vtexcatalog                  vc
      where ar.cdarticulo = da.cdarticulo
        and ar.cdestadoplu in('00','07')  --OJO 00 activo para la venta 07 no visible 03 articulo desactivado permanentemente
        and not exists
      (select 1
               from articulosnocomerciales t
              where t.cdarticulo = a.cdarticulo)
        and not exists
      (select 1
               from articulos_excluidos h     --agrego tabla articulos excluidos
              where h.cdarticulo = ar.cdarticulo
                -- excluidos por canal
                and h.id_canal = &pc_id_canal   )
        and substr(ar.cdarticulo, 1, 1) <> 'A'
        and a.cdarticulo = ae.cdarticulo (+)
        and a.cddepartamento = d.cddepartamento(+)
        and a.cduniverso = u.cduniverso(+)
        and a.cdcategoria = c.cdcategoria(+)
        and a.cdsubcategoria = sc.cdsubcategoria(+)
        and a.cdarticulo = ar.cdarticulo
        and NVL(ar.cddrugstore,'XX') not in ('EX', 'DE', 'CP')
        and upper(trim(ae.vlmarca))= vb.name(+)
        and a.cdarticulo = ac.cdarticulo
        and vc.departmentid = ac.departmentid
        and vc.categoryid = ac.categoryid
        and vc.subcategoryid =ac.subcategoryid)
        
        select * from vp,tvp
        where -- solo se actualizan si hubo algun cambio
               (vp.refid = tvp.refid
           and vp.id_canal = tvp.id_canal)
           and (
             vp.name <> tvp.name
           or vp.departmentid <> tvp.departmentid
           or vp.categoryid <> tvp.categoryid
           or vp.subcategoryid <> tvp.subcategoryid
           or nvl(vp.variedad,0) <> nvl(tvp.variedad,0)
           or vp.brandid <> tvp.brandid
           or vp.linkid <> tvp.linkid
           or vp.isvisible <> tvp.isvisible
           or vp.description <> tvp.description
           or vp.releasedate <> tvp.releasedate
           or vp.isactive <> tvp.isactive
           or nvl(vp.uxb,0) <> nvl(tvp.uxb,0)
           );
