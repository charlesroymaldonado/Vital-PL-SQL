select distinct d.fecha_ultima_modificacion, d.mensaje from tbllog_general d
where to_char(d.fecha_ultima_modificacion,'dd/mm/yyyy')>='14/01/2021'
-- and d.mensaje like '%PKG_SLV_TAREAS%'

 order by 1 desc;
select * from tbllog_general d
where to_char(d.fecha_ultima_modificacion,'dd/mm/yyyy')>='15/09/2020'
 -- and d.usuario like '%SLVAPP%'
order by d.fecha_ultima_modificacion desc;
 
