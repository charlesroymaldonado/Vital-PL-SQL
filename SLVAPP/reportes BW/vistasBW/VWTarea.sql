create or replace view view_dw_slvtareas as
select ta.idtarea,
              ta.cdtipo cdtipotarea,
              tt.dstarea dstipotarea,
              coalesce(
                ta.idpedfaltante,
                ta.idconsolidadom,
                ta.idconsolidadopedido,
                ta.idconsolidadocomi) pedido,
              ta.idpersonaarmador,
              case
                when ta.idpedfaltante is not null then 'F (TE+VE)'
                when ta.idconsolidadom is not null then 'MC'
                when ta.idconsolidadopedido is not null then
                   (select cp.id_canal
                     from tblslvconsolidadopedido cp
                    where cp.idconsolidadopedido = ta.idconsolidadopedido)
               when ta.idconsolidadocomi is not null then 'CO'
              end id_canal,
              ta.cdsucursal,
              ta.dtinicio,
              ta.dtfin,
              td.cdarticulo,
              pkg_slv_articulo.getuxbarticulo(td.cdarticulo,decode(td.qtpiezas,0,'BTO','KG'))UxB,
              td.qtunidadmedidabase qtsolicitada,
              td.qtunidadmedidabasepicking qtpicking,
              nvl(re.idremito,0) idremito,
              nvl(re.nrocarreta,'-') nrocarreta
         from tblslvtarea             ta,
              tblslvRemito            re,
              tblslvtareadet          td,
              tblslvTipoTarea         tt
         where ta.idtarea = td.idtarea
          and ta.cdtipo = tt.cdtipo
          and ta.idtarea = re.idtarea(+)
          -- solo tareas iniciadas
          and ta.dtinicio is not null
;