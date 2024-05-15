-- Table: tblslvConsolidadoM
CREATE TABLE tblslvConsolidadoM (
    idConsolidadoM integer  NOT NULL,
	cdSucursal	char(8)		NOT NULL,
    qtConsolidado integer  NOT NULL,
    idPersona char(40)  NOT NULL,
    cdEstado integer  NOT NULL,
    dtInsert date  NOT NULL,
    dtUpdate date  NULL,
    CONSTRAINT PK_ConsolidadoM PRIMARY KEY (idConsolidadoM,cdSucursal)
) ;


-- Table: tblslvConsolidadoPedido
CREATE TABLE tblslvConsolidadoPedido (
    idConsolidadoPedido integer  NOT NULL,
	cdSucursal	char(8)		NOT NULL,
    identidad char(40)  NOT NULL,
    cdEstado integer  NOT NULL,
    idConsolidadoM integer  NULL,
    idPersona char(40)  NOT NULL,
    idConsolidadoComi integer  NULL,
    dtInsert date  NOT NULL,
    dtUpdate date  NULL,
    CONSTRAINT PK_ConsolidadoPedido PRIMARY KEY (idConsolidadoPedido,cdSucursal)
) ;

CREATE TABLE tblslvConsolidadoPedidoRel (
    idConsolidadoPedidoRel integer  NOT NULL,
	cdSucursal	char(8)		NOT NULL,
    idPedido char(40)  NOT NULL,
    idConsolidadoPedido integer  NOT NULL,
    CONSTRAINT PK_ConsolidadoPedidoRel PRIMARY KEY (idConsolidadoPedidoRel,cdSucursal)
) ;

-- Table: tblslvRemito
CREATE TABLE tblslvRemito (
    idRemito integer  NOT NULL,
	cdSucursal	char(8)		NOT NULL,
    idTarea integer  NULL,
    idPedFaltanteRel integer  NULL,
    nroCarreta varchar2(15)  NOT NULL,
    cdEstado integer  NOT NULL,
    dtRemito date  NOT NULL,
    dtUpdate date  NULL,
    CONSTRAINT PK_tblslvRemito PRIMARY KEY (idRemito,cdsucursal)
) ;

-- Table: tblslvTarea
CREATE TABLE tblslvTarea (
    idTarea integer  NOT NULL,
	cdSucursal	char(8) NOT NULL,
    idPedFaltante integer  NULL,
    idConsolidadoM integer  NULL,
    idConsolidadoPedido integer  NULL,
    idConsolidadoComi integer  NULL,
    cdTipo integer  NOT NULL,
    cdModoIngreso integer  DEFAULT 0 NOT NULL,
    idPersona char(40)  NOT NULL,
    idPersonaArmador char(40)  NOT NULL,
    dtInicio date  NULL,
    dtFin date  NULL,
    Prioridad integer  NOT NULL,
    cdEstado integer  NOT NULL,
    dtInsert date  NOT NULL,
    dtUpdate date  NULL,
    CONSTRAINT PK_Tarea PRIMARY KEY (idTarea,cdSucursal)
) ;


-- Table: tblslvEstado
CREATE TABLE tblslvEstado (
    cdEstado integer  NOT NULL,
    dsEstado varchar2(40)  NOT NULL,
    tipo varchar2(50)  NOT NULL,
    CONSTRAINT PK_Estado PRIMARY KEY (cdEstado)
) ;

-- Reference: FK_Tarea_Remito (table: tblslvRemito)
ALTER TABLE tblslvRemito ADD CONSTRAINT FK_Tarea_Remito
    FOREIGN KEY (idTarea,cdsucursal)
    REFERENCES tblslvTarea (idTarea,cdsucursal);

-- Reference: FK_Estado_Tarea (table: tblslvTarea)
ALTER TABLE tblslvTarea ADD CONSTRAINT FK_Estado_Tarea
    FOREIGN KEY (cdEstado)
    REFERENCES tblslvEstado (cdEstado);

-- Reference: FK_Personas_Tarea (table: tblslvTarea)
ALTER TABLE tblslvTarea ADD CONSTRAINT FK_Personas_Tarea
    FOREIGN KEY (idPersona)
    REFERENCES Personas (idPersona);

-- Reference: FK_Personas_Tarea_Armador (table: tblslvTarea)
ALTER TABLE tblslvTarea ADD CONSTRAINT FK_Personas_Tarea_Armador
    FOREIGN KEY (idPersonaArmador)
    REFERENCES Personas (idPersona);
  
-- Reference: FK_ConsolidadoPedido_Tarea (table: tblslvTarea)
ALTER TABLE tblslvTarea ADD CONSTRAINT FK_ConsolidadoPedido_Tarea
    FOREIGN KEY (idConsolidadoPedido,cdsucursal)
    REFERENCES tblslvConsolidadoPedido (idConsolidadoPedido,cdsucursal);  
  

-- Reference: FK_ConsoliPed_ConsoliPedRel (table: tblslvConsolidadoPedidoRel)
ALTER TABLE tblslvConsolidadoPedidoRel ADD CONSTRAINT FK_ConsoliPed_ConsoliPedRel
    FOREIGN KEY (idConsolidadoPedido,cdSucursal)
    REFERENCES tblslvConsolidadoPedido (idConsolidadoPedido,cdSucursal);

-- Reference: FK_Pedidos_ConsolidadoPedRel (table: tblslvConsolidadoPedidoRel)
ALTER TABLE tblslvConsolidadoPedidoRel ADD CONSTRAINT FK_Pedidos_ConsolidadoPedRel
    FOREIGN KEY (idPedido)
    REFERENCES PEDIDOS (idPedido);	

-- Reference: FK_ConsolidadoM_ConsoliPedido (table: tblslvConsolidadoPedido)
ALTER TABLE tblslvConsolidadoPedido ADD CONSTRAINT FK_ConsolidadoM_ConsoliPedido
    FOREIGN KEY (idConsolidadoM,cdSucursal)
    REFERENCES tblslvConsolidadoM (idConsolidadoM,cdSucursal);
	
-- Reference: FK_Estado_ConsolidadoPedido (table: tblslvConsolidadoPedido)
ALTER TABLE tblslvConsolidadoPedido ADD CONSTRAINT FK_Estado_ConsolidadoPedido
    FOREIGN KEY (cdEstado)
    REFERENCES tblslvEstado (cdEstado);	
	
-- Reference: FK_Entidades_ConsolidadoPedido (table: tblslvConsolidadoPedido)
ALTER TABLE tblslvConsolidadoPedido ADD CONSTRAINT FK_Entidades_ConsolidadoPedido
    FOREIGN KEY (identidad)
    REFERENCES ENTIDADES (Identidad);	

-- Reference: FK_Personas_ConsolidadoPedido (table: tblslvConsolidadoPedido)
ALTER TABLE tblslvConsolidadoPedido ADD CONSTRAINT FK_Personas_ConsolidadoPedido
    FOREIGN KEY (idPersona)
    REFERENCES Personas (idPersona);		

-- Reference: FK_Personas_ConsolidadoM (table: tblslvConsolidadoM)
ALTER TABLE tblslvConsolidadoM ADD CONSTRAINT FK_Personas_ConsolidadoM
    FOREIGN KEY (idPersona)
    REFERENCES Personas (idPersona);


-- Reference: FK_Estado_ConsolidadoM (table: tblslvConsolidadoM)
ALTER TABLE tblslvConsolidadoM ADD CONSTRAINT FK_Estado_ConsolidadoM
    FOREIGN KEY (cdEstado)
    REFERENCES tblslvEstado (cdEstado);
	