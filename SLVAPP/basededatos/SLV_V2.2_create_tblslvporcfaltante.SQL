

--VOLVER A GENERAR TBLSLVREMITODET

ALTER TABLE DROP CONSTRAINT UK_Remito_Articulo UNIQUE (idRemito, cdArticulo);

-- Reference: FK_Remito_RemitoDet (table: tblslvRemitoDet)
ALTER TABLE tblslvRemitoDet ADD CONSTRAINT FK_Remito_RemitoDet
    FOREIGN KEY (idRemito)
    REFERENCES tblslvRemito (idRemito);
	
-- Table: tblslvPorcenDistribFaltante
CREATE TABLE tblslvPorcenDistribFaltante (
    IDConsolidadoPedido integer  NOT NULL,
    idConsolidadoM integer  NOT NULL,
    cdArticulo char(8)  NOT NULL,
    qtunidadmedidabase number(10,2)  NOT NULL,
    totalconsolidadoM number(10,2)  NOT NULL,
    CONSTRAINT PK_porcendistfaltante PRIMARY KEY (IDConsolidadoPedido,idConsolidadoM,cdArticulo)
) ;

-- foreign keys
-- Reference: FK_PorcDistFaltan_Articulos (table: tblslvPorcenDistribFaltante)
ALTER TABLE tblslvPorcenDistribFaltante ADD CONSTRAINT FK_PorcDistFaltan_Articulos
    FOREIGN KEY (cdArticulo)
    REFERENCES Articulos (cdArticulo);

-- End of file.

ALTER TABLE tblslvPorcenDistribFaltante ADD CONSTRAINT FK_PorcenDistFaltaConsolidadoM
    FOREIGN KEY (idConsolidadoM)
    REFERENCES tblslvConsolidadoM (idConsolidadoM);

-- foreign keys
-- Reference: FK_DistribFaltante_ConsoPed (table: tblslvPorcenDistribFaltante)
ALTER TABLE tblslvPorcenDistribFaltante ADD CONSTRAINT FK_DistribFaltante_ConsoPed
    FOREIGN KEY (IDConsolidadoPedido)
    REFERENCES tblslvConsolidadoPedido (idConsolidadoPedido);
	