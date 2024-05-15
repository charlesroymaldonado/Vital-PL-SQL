
        select *
          from tblslvnuevadistribucion nd
         where nd.idpedfaltante = &p_IdPedFaltante;
         
         select *
          from tblslvdistribucionpedfaltante dpf
         where dpf.iddistribucionpedfaltante in  
         (select nd.iddistribucionpedfaltante
          from tblslvnuevadistribucion nd
         where nd.idpedfaltante = &p_IdPedFaltante)
        --actualiza error de redistribucion
        /* update tblslvdistribucionpedfaltante dpf
         set dpf.qtunidadmedidabase = (select nb.qtunidadmedidabase 
                                        from tblslvnuevadistribucion nb
                                       where dpf.iddistribucionpedfaltante = nb.iddistribucionpedfaltante
                                         and nb.cdarticulo = dpf.cdarticulo
                                         and nb.idpedfaltante = &p_IdPedFaltante)
         where exists (select nb.qtunidadmedidabase 
                                        from tblslvnuevadistribucion nb
                                       where dpf.iddistribucionpedfaltante = nb.iddistribucionpedfaltante
                                         and nb.cdarticulo = dpf.cdarticulo
                                         and nb.idpedfaltante = &p_IdPedFaltante)*/
