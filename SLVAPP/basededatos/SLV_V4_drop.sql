-- Created by Vertabelo (http://vertabelo.com)
-- Last modification date: 2020-07-23 13:22:40.951

-- foreign keys
ALTER TABLE tblslvConsolidadoComiDet
    DROP CONSTRAINT FK_Articulo_ConsolidadoComiDet;

ALTER TABLE tblslvPedidoConformado
    DROP CONSTRAINT FK_Articulo_PedidoConformado;

ALTER TABLE tblslvConsolidadoMDet
    DROP CONSTRAINT FK_Articulos_ConsolidadoMDet;

ALTER TABLE tblslvConsolidadoPedidoDet
    DROP CONSTRAINT FK_Articulos_ConsolidadoPedDet;

ALTER TABLE tblslvPedFaltanteDet
    DROP CONSTRAINT FK_Articulos_PedFaltanteDet;

ALTER TABLE tblslvRemitoDet
    DROP CONSTRAINT FK_Articulos_RemitoDet;

ALTER TABLE tblslvTareaDet
    DROP CONSTRAINT FK_Articulos_TareaDet;

ALTER TABLE tblslvConsolidadoPedidoDet
    DROP CONSTRAINT FK_ConsolPed_ConsolidadoPedDet;

ALTER TABLE tblslvConsolidadoComiDet
    DROP CONSTRAINT FK_ConsoliComi_ConsoliComiDet;

ALTER TABLE tblslvConsolidadoPedido
    DROP CONSTRAINT FK_ConsoliComi_ConsoliPedido;

ALTER TABLE tblslvConsolidadoComi
    DROP CONSTRAINT FK_ConsoliM_ConsolidadoComi;

ALTER TABLE tblslvConsolidadoMDet
    DROP CONSTRAINT FK_ConsoliM_ConsolidadoMDet;

ALTER TABLE tblslvConsolidadoPedidoRel
    DROP CONSTRAINT FK_ConsoliPed_ConsoliPedRel;

ALTER TABLE tblslvPedFaltanteRel
    DROP CONSTRAINT FK_ConsoliPed_PedFaltanteRel;

ALTER TABLE tblslvTarea
    DROP CONSTRAINT FK_ConsolidadoComi_Tarea;

ALTER TABLE tblslvConsolidadoPedido
    DROP CONSTRAINT FK_ConsolidadoM_ConsoliPedido;

ALTER TABLE tblslvTarea
    DROP CONSTRAINT FK_ConsolidadoM_Tarea;

ALTER TABLE tblslvTarea
    DROP CONSTRAINT FK_ConsolidadoPedido_Tarea;

ALTER TABLE tblslvConteoDet
    DROP CONSTRAINT FK_ConteoDet_Articulos;

ALTER TABLE tblslvConteoDet
    DROP CONSTRAINT FK_ConteoDet_Conteo;

ALTER TABLE tblslvConteo
    DROP CONSTRAINT FK_Conteo_ControlRemito;

ALTER TABLE tblslvControlRemitoDet
    DROP CONSTRAINT FK_ControlRemitoDet_Articulos;

ALTER TABLE tblslvControlRemito
    DROP CONSTRAINT FK_ControlRemito_Estado;

ALTER TABLE tblslvControlRemito
    DROP CONSTRAINT FK_ControlRemito_Personas;

ALTER TABLE tblslvControlRemito
    DROP CONSTRAINT FK_ControlRemito_Remito;

ALTER TABLE tblslvControlRemitoDet
    DROP CONSTRAINT FK_CtrlRemitoDet_ControlRemito;

ALTER TABLE tblslvRemito
    DROP CONSTRAINT FK_DistribuPedFaltante_Remito;

ALTER TABLE tblslvConsolidadoPedido
    DROP CONSTRAINT FK_Entidades_ConsolidadoPedido;

ALTER TABLE tblslvConsolidadoComi
    DROP CONSTRAINT FK_Estado_ConsolidadoComi;

ALTER TABLE tblslvConsolidadoM
    DROP CONSTRAINT FK_Estado_ConsolidadoM;

ALTER TABLE tblslvConsolidadoPedido
    DROP CONSTRAINT FK_Estado_ConsolidadoPedido;

ALTER TABLE tblslvPedFaltante
    DROP CONSTRAINT FK_Estado_PedFaltante;

ALTER TABLE tblslvRemito
    DROP CONSTRAINT FK_Estado_Remito;

ALTER TABLE tblslvTarea
    DROP CONSTRAINT FK_Estado_Tarea;

ALTER TABLE tblslvConsolidadoComiDet
    DROP CONSTRAINT FK_GrupSector_ConsolidComiDet;

ALTER TABLE tblslvTareaDet
    DROP CONSTRAINT FK_GrupSector_TareaDet;

ALTER TABLE tblslvConsolidadoPedidoDet
    DROP CONSTRAINT FK_GrupoSector_ConsolidPedDet;

ALTER TABLE tblslvConsolidadoMDet
    DROP CONSTRAINT FK_GrupoSector_ConsolidadoMDet;

ALTER TABLE tblslvPedFaltanteDet
    DROP CONSTRAINT FK_GrupoSector_PedFaltanteDet;

ALTER TABLE tblslvpordistrib
    DROP CONSTRAINT FK_PORCDIST_ARTICULOS;

ALTER TABLE tblslvpordistrib
    DROP CONSTRAINT FK_PORCDIST_CONSOLIDADOPEDIDO;

ALTER TABLE tblslvpordistrib
    DROP CONSTRAINT FK_PORCDIST_PEDIDOS;

ALTER TABLE tblslvpordistrib
    DROP CONSTRAINT FK_PORCDIST_TIPOTAREA;

ALTER TABLE tblslvPedFaltanteDet
    DROP CONSTRAINT FK_PedFaltante_PedFaltanteDet;

ALTER TABLE tblslvPedFaltanteRel
    DROP CONSTRAINT FK_PedFaltante_PedFaltanteRel;

ALTER TABLE tblslvTarea
    DROP CONSTRAINT FK_PedFaltante_Tarea;

ALTER TABLE tblslvConsolidadoPedidoRel
    DROP CONSTRAINT FK_Pedidos_ConsolidadoPedRel;

ALTER TABLE tblslvConsolidadoComi
    DROP CONSTRAINT FK_Personas_ConsolidadoComi;

ALTER TABLE tblslvConsolidadoM
    DROP CONSTRAINT FK_Personas_ConsolidadoM;

ALTER TABLE tblslvConsolidadoPedido
    DROP CONSTRAINT FK_Personas_ConsolidadoPedido;

ALTER TABLE tblslvPedFaltante
    DROP CONSTRAINT FK_Personas_PedFaltante;

ALTER TABLE tblslvPedFaltanteRel
    DROP CONSTRAINT FK_Personas_PedFaltanteRel;

ALTER TABLE tblslvTarea
    DROP CONSTRAINT FK_Personas_Tarea;

ALTER TABLE tblslvTarea
    DROP CONSTRAINT FK_Personas_Tarea_Armador;

ALTER TABLE tblslvRemitoDet
    DROP CONSTRAINT FK_Remito_RemitoDet;

ALTER TABLE tblslvRemito
    DROP CONSTRAINT FK_Tarea_Remito;

ALTER TABLE tblslvTareaDet
    DROP CONSTRAINT FK_Tarea_TareaDet;

ALTER TABLE tblslvTarea
    DROP CONSTRAINT FK_TipoTarea_Tarea;

ALTER TABLE tblslv_grupo_sector
    DROP CONSTRAINT tblslv_grupo_sector_sectores;

-- tables
DROP TABLE Articulos;

DROP TABLE ENTIDADES;

DROP TABLE PEDIDOS;

DROP TABLE Personas;

DROP TABLE sectores;

DROP TABLE tblslvConsolidadoComi;

DROP TABLE tblslvConsolidadoComiDet;

DROP TABLE tblslvConsolidadoM;

DROP TABLE tblslvConsolidadoMDet;

DROP TABLE tblslvConsolidadoPedido;

DROP TABLE tblslvConsolidadoPedidoDet;

DROP TABLE tblslvConsolidadoPedidoRel;

DROP TABLE tblslvConteo;

DROP TABLE tblslvConteoDet;

DROP TABLE tblslvControlRemito;

DROP TABLE tblslvControlRemitoDet;

DROP TABLE tblslvEstado;

DROP TABLE tblslvPedFaltante;

DROP TABLE tblslvPedFaltanteDet;

DROP TABLE tblslvPedFaltanteRel;

DROP TABLE tblslvPedidoConformado;

DROP TABLE tblslvRemito;

DROP TABLE tblslvRemitoDet;

DROP TABLE tblslvTarea;

DROP TABLE tblslvTareaDet;

DROP TABLE tblslvTipoTarea;

DROP TABLE tblslv_grupo_sector;

DROP TABLE tblslvpordistrib;

DROP TABLE tbltmpslvConsolidadoM;

-- sequences
DROP SEQUENCE SEQ_ConsolidadoComi;

DROP SEQUENCE SEQ_ConsolidadoComiDet;

DROP SEQUENCE SEQ_ConsolidadoM;

DROP SEQUENCE SEQ_ConsolidadoMDet;

DROP SEQUENCE SEQ_ConsolidadoPedido;

DROP SEQUENCE SEQ_ConsolidadoPedidoDet;

DROP SEQUENCE SEQ_ConsolidadoPedidoRel;

DROP SEQUENCE SEQ_ControlRemito;

DROP SEQUENCE SEQ_ControlRemitoDet;

DROP SEQUENCE SEQ_DistribucionPedFaltante;

DROP SEQUENCE SEQ_PedFaltante;

DROP SEQUENCE SEQ_PedFaltanteDet;

DROP SEQUENCE SEQ_PedFaltanteRel;

DROP SEQUENCE SEQ_Remito;

DROP SEQUENCE SEQ_RemitoDet;

DROP SEQUENCE SEQ_Tarea;

DROP SEQUENCE SEQ_TareaDet;

-- End of file.

