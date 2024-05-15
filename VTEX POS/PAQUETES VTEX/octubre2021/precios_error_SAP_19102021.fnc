create or replace PROCEDURE CORRIGEPRECIOPOSVTEX is
  begin
for P in
(select * from (  
select pre.cdsucursal,
       pre.id_canal,
       pre.cdarticulo,
       pre.amprecio,
       pre.dtvigenciadesde,
       round(pkg_impuesto_central.getImporteConIVA(pre.amPrecio,
                                                   PKG_PRECIO.GetIvaArticulo(pre.cdarticulo),
                                                   pkg_impuesto_central.GetImpuestoInterno(pre.cdsucursal,
                                                                                           pre.cdarticulo),
                                                   pre.cdsucursal),
             2) coniva,
       vpri.pricepl,
       vpri.dtupdate,
       vpri.icprocesado
  from tblprecio pre, vtexsellers vs, vtexprice vpri
where pre.id_canal = vs.id_canal
   and pre.cdsucursal = vs.cdsucursal
   and vs.icactivo = 1
   --and pre.dtvigenciadesde >= '18/09/2021'
   and pre.dtvigenciadesde <= trunc(sysdate) 
   and pre.dtvigenciahasta >= trunc(sysdate) 
   and pre.id_precio_tipo = 'PL'
   and pre.cdsucursal = vpri.cdsucursal
   and pre.id_canal = vpri.id_canal
   and pre.cdsucursal = vpri.cdsucursal
   and pre.cdarticulo = vpri.refid
   --AND pre.cdarticulo='0159852 '
   ) where trunc(coniva) <> trunc(pricepl)   
   )
   loop
   update vtexprice pr
      set pr.pricepl= p.coniva,
          pr.dtupdate= sysdate,
          pr.icprocesado=0,
          pr.dtprocesado = null,
          pr.observacion = null
    where pr.cdsucursal= P.cdsucursal
      and pr.refid = P.cdarticulo
      and pr.id_canal =P.id_canal;
   end loop;
--     dbms_output.put_line('OK!'); 
     commit;
exception
    when others then
         --dbms_output.put_line('Error!'); 
          pkg_control.GrabarMensaje(sys_guid(),
                                    null,
                                    sysdate,
                                    'ERROR Precios diferentes entre SAP VTEX',
                                    'ver job PRECIOSPOSVTEXSAP función CORRIGEPRECIOPOSVTEX',
                                    0);
         rollback ;  
end CORRIGEPRECIOPOSVTEX;
/
