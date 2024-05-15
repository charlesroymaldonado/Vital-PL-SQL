
ALTER TABLE TBLSLVREMITODET ADD idpedidollavero char(40);

ALTER TABLE tblslvRemitoDet DROP CONSTRAINT UK_Remito_Articulo;

-- Reference: FK_Remito_RemitoDet (table: tblslvRemitoDet)
ALTER TABLE tblslvRemitoDet ADD CONSTRAINT FK_RemitoDet_Remito
    FOREIGN KEY (idRemito)
    REFERENCES tblslvRemito (idRemito);
