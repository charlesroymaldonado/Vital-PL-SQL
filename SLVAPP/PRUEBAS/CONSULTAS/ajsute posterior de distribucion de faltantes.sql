--drop table  tblslvpruebadistribucion ;
--create table  tblslvpruebadistribucion as
select A.idpedfaltante,
       A.iddistribucionpedfaltante,
       A.cdarticulo,
       A.qtunidadmedidabase,
       A.necesita,
       A.UxB,
       A.BTO,
       A.UxB*A.BTO UNIDADES,
       0 NUEVA_DISTRIB,        
       A.qtunidadmedidabase-(A.BTO* A.UxB) DIFERENCIA
        from 
           (select pf.idpedfaltante,
                   dtf.iddistribucionpedfaltante,
                   dtf.cdarticulo,
                   dtf.qtunidadmedidabase,
                   cpd.qtunidadesmedidabase-nvl(cpd.qtunidadmedidabasepicking,0) necesita,                   
                   PKG_SLV_ARTICULO.GetUXBArticulo(dtf.cdarticulo,'BTO') UxB, 
                   TRUNC(dtf.qtunidadmedidabase/
                   --manejo el error de division por cero
                   DECODE(PKG_SLV_ARTICULO.GetUXBArticulo(dtf.cdarticulo,'BTO'),0
                   ,-1,PKG_SLV_ARTICULO.GetUXBArticulo(dtf.cdarticulo,'BTO'))) BTO                  
              from tblslvdistribucionpedfaltante dtf,
                   tblslvpedfaltanterel          frel,
                   tblslvpedfaltante             pf,
                   tblslvconsolidadopedido       cp,
                   tblslvconsolidadopedidodet    cpd                  
             where pf.idpedfaltante = frel.idpedfaltante
               and frel.idpedfaltanterel = dtf.idpedfaltanterel
               and cp.idconsolidadopedido = frel.idconsolidadopedido
               and cp.idconsolidadopedido = cpd.idconsolidadopedido
               and dtf.cdarticulo = cpd.cdarticulo             
               --excluyo pesables
               and nvl(dtf.qtpiezas,0)=0
            --   and pf.idpedfaltante = &p_idfaltante
            ) A
              order by  A.idpedfaltante,A.cdarticulo
                      ;
--validar si uxb es cero nada que ajustar para ese articulo, salir al siguente articulo       
--validar si necesita igual a cero la diferencia se acumula para el proximo dentro del mismo articulo
--validar si no tiene diferencia sumada no hacer nada
--validar si nadie lo necesita dejar distribucion igual
--sumar todas las diferencias por articulo y dividirla por uxb si es mayor a cero asignar el trunc hasta no mas diferencia en BTO
--luego al sobrante de diferencias en UN asignar a quien lo necesite
/*select pd.cdarticulo,sum(pd.qtunidadmedidabase),sum(pd.unidades),sum(pd.nueva_distrib) 
  from  tblslvpruebadistribucion PD
 -- where pd.cdarticulo=&art
  group by pd.cdarticulo
  order by pd.cdarticulo; 
select * 
  from  tblslvpruebadistribucion PD
 --where pd.cdarticulo=&art
order by pd.cdarticulo,unidades ; */
select * 
  from  tblslvnuevadistribucion nd
  where nd.idpedfaltante=&p_idfaltante
