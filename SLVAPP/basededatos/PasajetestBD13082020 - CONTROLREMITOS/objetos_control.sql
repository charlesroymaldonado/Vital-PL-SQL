-- Table: tblslvConteo
CREATE TABLE tblslvConteo (
    idConteo integer  NOT NULL,
    idControlRemito integer  NOT NULL,
    qtveces integer  DEFAULT 1 NOT NULL,
    dtinicio date  NOT NULL,
    dtfin date  NULL,
    cdsucursal char(8)  NOT NULL,
    CONSTRAINT PK_ConteoControl PRIMARY KEY (idConteo)
) ;

-- Table: tblslvConteoDet
CREATE TABLE tblslvConteoDet (
    idConteoDet integer  NOT NULL,
    idConteo integer  NOT NULL,
    cdArticulo char(8)  NOT NULL,
    qtUnidadMedidaBasePicking number(10,2)  NOT NULL,
    qtPiezasPicking number(10,2)  NOT NULL,
    dtinsert date  NOT NULL,
    dtupdate date  NOT NULL,
    cdsucursal char(8)  NOT NULL,
    CONSTRAINT PK_ConteoDet PRIMARY KEY (idConteoDet)
) ;

-- Table: tblslvControlRemito
CREATE TABLE tblslvControlRemito (
    idControlRemito integer  NOT NULL,
    idRemito integer  NOT NULL,
    cdEstado integer  NOT NULL,
    idPersonaControl char(40)  NOT NULL,
    qtcontrol integer  DEFAULT 1 NOT NULL,
    dtinsert date  NOT NULL,
    dtupdate date  NULL,
    CONSTRAINT PK_ControlRemito PRIMARY KEY (idControlRemito)
) ;

-- Table: tblslvControlRemitoDet
CREATE TABLE tblslvControlRemitoDet (
    idControlRemitoDet integer  NOT NULL,
    idControlRemito integer  NOT NULL,
    cdArticulo char(8)  NOT NULL,
    qtDiferenciaUnidadMBase number(10,2)  DEFAULT 0 NOT NULL,
    qtDiferenciaPiezas number(10,2)  DEFAULT 0 NOT NULL,
    qtUnidadMedidaBasePicking number(10,2)  NULL,
    qtPiezasPicking number(10,2)  NULL,
    dtinsert date  NOT NULL,
    dtupdate date  NULL,
    CONSTRAINT PK_ControlRemitoDet PRIMARY KEY (idControlRemitoDet)
) ;

--foreign keys
-- Reference: ControlRemitoDet_Articulos (table: tblslvControlRemitoDet)
ALTER TABLE tblslvControlRemitoDet ADD CONSTRAINT FK_ControlRemitoDet_Articulos
    FOREIGN KEY (cdArticulo)
    REFERENCES Articulos (cdArticulo);
	

-- Reference: ControlRemito_Estado (table: tblslvControlRemito)
ALTER TABLE tblslvControlRemito ADD CONSTRAINT FK_ControlRemito_Estado
    FOREIGN KEY (cdEstado)
    REFERENCES tblslvEstado (cdEstado);
	
	-- Reference: FK_ControlRemito_Personas (table: tblslvControlRemito)
ALTER TABLE tblslvControlRemito ADD CONSTRAINT FK_ControlRemito_Personas
    FOREIGN KEY (idPersonaControl)
    REFERENCES Personas (idPersona);

-- Reference: FK_ControlRemito_Remito (table: tblslvControlRemito)
ALTER TABLE tblslvControlRemito ADD CONSTRAINT FK_ControlRemito_Remito
    FOREIGN KEY (idRemito)
    REFERENCES tblslvRemito (idRemito);

-- Reference: FK_CtrlRemitoDet_ControlRemito (table: tblslvControlRemitoDet)
ALTER TABLE tblslvControlRemitoDet ADD CONSTRAINT FK_CtrlRemitoDet_ControlRemito
    FOREIGN KEY (idControlRemito)
    REFERENCES tblslvControlRemito (idControlRemito);
	
	
-- foreign keys
-- Reference: FK_ConteoDet_Conteo (table: tblslvConteoDet)
ALTER TABLE tblslvConteoDet ADD CONSTRAINT FK_ConteoDet_Conteo
    FOREIGN KEY (idConteo)
    REFERENCES tblslvConteo (idConteo);	
	
	-- Sequence: SEQ_ControlRemito
CREATE SEQUENCE SEQ_ControlRemito
      INCREMENT BY 1
      MINVALUE 1
      MAXVALUE 999999999999999999999999999
      START WITH 1
      NOCACHE
      NOCYCLE;

-- Sequence: SEQ_ControlRemitoDet
CREATE SEQUENCE SEQ_ControlRemitoDet
      INCREMENT BY 1
      MINVALUE 1
      MAXVALUE 999999999999999999999999999
      START WITH 1
      NOCACHE
      NOCYCLE;

	-- Sequence: SEQ_Conteo
CREATE SEQUENCE SEQ_Conteo
      INCREMENT BY 1
      MINVALUE 1
      MAXVALUE 999999999999999999999999999
      START WITH 1
      NOCACHE
      NOCYCLE;

-- Sequence: SEQ_ConteoDet
CREATE SEQUENCE SEQ_ConteoDet
      INCREMENT BY 1
      MINVALUE 1
      MAXVALUE 999999999999999999999999999
      START WITH 1
      NOCACHE
      NOCYCLE;	  
