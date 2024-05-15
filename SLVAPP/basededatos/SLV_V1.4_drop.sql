-- Created by Vertabelo (http://vertabelo.com)
-- Last modification date: 2020-01-24 17:53:37.967

-- foreign keys

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

ALTER TABLE tblslvRemito
    DROP CONSTRAINT FK_ConsolidadoComi_Remito;

ALTER TABLE tblslvTarea
    DROP CONSTRAINT FK_ConsolidadoComi_Tarea;

ALTER TABLE tblslvConsolidadoPedido
    DROP CONSTRAINT FK_ConsolidadoM_ConsoliPedido;

ALTER TABLE tblslvTarea
    DROP CONSTRAINT FK_ConsolidadoM_Tarea;

ALTER TABLE tblslvRemito
    DROP CONSTRAINT FK_ConsolidadoPedido_Remito;

ALTER TABLE tblslvTarea
    DROP CONSTRAINT FK_ConsolidadoPedido_Tarea;

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

ALTER TABLE tblslvDistribucionPedFaltante
    DROP CONSTRAINT FK_PedFaltaRel_DistribPedFalta;

ALTER TABLE tblslvPedFaltanteDet
    DROP CONSTRAINT FK_PedFaltante_PedFaltanteDet;

ALTER TABLE tblslvPedFaltanteRel
    DROP CONSTRAINT FK_PedFaltante_PedFaltanteRel;

ALTER TABLE tblslvTarea
    DROP CONSTRAINT FK_PedFaltante_Tarea;

ALTER TABLE tblslvTareaDet
    DROP CONSTRAINT FK_Remito_TareaDet;

ALTER TABLE tblslvTareaDet
    DROP CONSTRAINT FK_Tarea_TareaDet;

ALTER TABLE tblslvTarea
    DROP CONSTRAINT FK_TipoTarea_Tarea;

-- tables


DROP TABLE tblslvConsolidadoComi;

DROP TABLE tblslvConsolidadoComiDet;

DROP TABLE tblslvConsolidadoM;

DROP TABLE tblslvConsolidadoMDet;

DROP TABLE tblslvConsolidadoPedido;

DROP TABLE tblslvConsolidadoPedidoDet;

DROP TABLE tblslvConsolidadoPedidoRel;

DROP TABLE tblslvDistribucionPedFaltante;

DROP TABLE tblslvEstado;

DROP TABLE tblslvPedFaltante;

DROP TABLE tblslvPedFaltanteDet;

DROP TABLE tblslvPedFaltanteRel;

DROP TABLE tblslvPedidoConformado;

DROP TABLE tblslvRemito;

DROP TABLE tblslvTarea;

DROP TABLE tblslvTareaDet;

DROP TABLE tblslvTipoTarea;

DROP TABLE tbltmpslvConsolidadoM;

-- sequences
DROP SEQUENCE SEQ_ConsolidadoComi;

DROP SEQUENCE SEQ_ConsolidadoComiDet;

DROP SEQUENCE SEQ_ConsolidadoM;

DROP SEQUENCE SEQ_ConsolidadoMDet;

DROP SEQUENCE SEQ_ConsolidadoPedido;

DROP SEQUENCE SEQ_ConsolidadoPedidoDet;

DROP SEQUENCE SEQ_ConsolidadoPedidoRel;

DROP SEQUENCE SEQ_DistribucionPedFaltante;

DROP SEQUENCE SEQ_PedFaltante;

DROP SEQUENCE SEQ_PedFaltanteDet;

DROP SEQUENCE SEQ_PedFaltanteRel;

DROP SEQUENCE SEQ_Remito;

DROP SEQUENCE SEQ_Tarea;

DROP SEQUENCE SEQ_TareaDet;

-- End of file.

