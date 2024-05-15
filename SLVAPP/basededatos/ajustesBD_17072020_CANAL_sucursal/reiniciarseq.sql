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
-- sequences
-- Sequence: SEQ_ConsolidadoComi
CREATE SEQUENCE SEQ_ConsolidadoComi
      INCREMENT BY 1
      MINVALUE 1
      MAXVALUE 999999999999999999999999999
      START WITH 1
      NOCACHE
      NOCYCLE;

-- Sequence: SEQ_ConsolidadoComiDet
CREATE SEQUENCE SEQ_ConsolidadoComiDet
      INCREMENT BY 1
      MINVALUE 1
      MAXVALUE 999999999999999999999999999
      START WITH 1
      NOCACHE
      NOCYCLE;

-- Sequence: SEQ_ConsolidadoM
CREATE SEQUENCE SEQ_ConsolidadoM
      INCREMENT BY 1
      MINVALUE 1
      MAXVALUE 999999999999999999999999999
      START WITH 1
      NOCACHE
      NOCYCLE;

-- Sequence: SEQ_ConsolidadoMDet
CREATE SEQUENCE SEQ_ConsolidadoMDet
      INCREMENT BY 1
      MINVALUE 1
      MAXVALUE 999999999999999999999999999
      START WITH 1
      NOCACHE
      NOCYCLE;

-- Sequence: SEQ_ConsolidadoPedido
CREATE SEQUENCE SEQ_ConsolidadoPedido
      INCREMENT BY 1
      MINVALUE 1
      MAXVALUE 999999999999999999999999999
      START WITH 1
      NOCACHE
      NOCYCLE;

-- Sequence: SEQ_ConsolidadoPedidoDet
CREATE SEQUENCE SEQ_ConsolidadoPedidoDet
      INCREMENT BY 1
      MINVALUE 1
      MAXVALUE 999999999999999999999999999
      START WITH 1
      NOCACHE
      NOCYCLE;

-- Sequence: SEQ_ConsolidadoPedidoRel
CREATE SEQUENCE SEQ_ConsolidadoPedidoRel
      INCREMENT BY 1
      MINVALUE 1
      MAXVALUE 999999999999999999999999999
      START WITH 1
      NOCACHE
      NOCYCLE;

-- Sequence: SEQ_DistribucionPedFaltante
CREATE SEQUENCE SEQ_DistribucionPedFaltante
      INCREMENT BY 1
      MINVALUE 1
      MAXVALUE 999999999999999999999999999
      START WITH 1
      NOCACHE
      NOCYCLE;

-- Sequence: SEQ_PedFaltante
CREATE SEQUENCE SEQ_PedFaltante
      INCREMENT BY 1
      MINVALUE 1
      MAXVALUE 999999999999999999999999999
      START WITH 1
      NOCACHE
      NOCYCLE;

-- Sequence: SEQ_PedFaltanteDet
CREATE SEQUENCE SEQ_PedFaltanteDet
      INCREMENT BY 1
      MINVALUE 1
      MAXVALUE 999999999999999999999999999
      START WITH 1
      NOCACHE
      NOCYCLE;

-- Sequence: SEQ_PedFaltanteRel
CREATE SEQUENCE SEQ_PedFaltanteRel
      INCREMENT BY 1
      MINVALUE 1
      MAXVALUE 999999999999999999999999999
      START WITH 1
      NOCACHE
      NOCYCLE;

-- Sequence: SEQ_Remito
CREATE SEQUENCE SEQ_Remito
      INCREMENT BY 1
      MINVALUE 1
      MAXVALUE 999999999999999999999999999
      START WITH 1
      NOCACHE
      NOCYCLE;

-- Sequence: SEQ_Tarea
CREATE SEQUENCE SEQ_Tarea
      INCREMENT BY 1
      MINVALUE 1
      MAXVALUE 999999999999999999999999999
      START WITH 1
      NOCACHE
      NOCYCLE;

-- Sequence: SEQ_TareaDet
CREATE SEQUENCE SEQ_TareaDet
      INCREMENT BY 1
      MINVALUE 1
      MAXVALUE 999999999999999999999999999
      START WITH 1
      NOCACHE
      NOCYCLE;