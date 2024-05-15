select * from vtexbrand b where b.name in ('ARCOR','FLECKY','SUIZA','LABRATTO','LE SANSY','MACROBIOTICA');
select count(*), b.name from vtexbrand b group by b.name having  count(*)>1 ;
--delete vtexbrand b where b.brandid in ('2000087','2001230','2000484','2000694','2000707','2000758' );
