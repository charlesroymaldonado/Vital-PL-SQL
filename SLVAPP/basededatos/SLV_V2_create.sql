-- Created by Vertabelo (http://vertabelo.com)
-- Last modification date: 2020-02-28 12:30:40.115

-- tables
-- Table: Articulos
CREATE TABLE Articulos (
    cdArticulo char(8)  NOT NULL,
    cdSector char(8)  NULL,
    cdUnidadMedidaBase char(8)  NULL,
    CONSTRAINT CDARTICULO_PK PRIMARY KEY (cdArticulo)
) ;

-- Table: ENTIDADES
CREATE TABLE ENTIDADES (
    Identidad char(40)  NOT NULL,
    CONSTRAINT PK_Entidades PRIMARY KEY (Identidad)
) ;

-- Table: PEDIDOS
CREATE TABLE PEDIDOS (
    idPedido char(40)  NOT NULL,
    CONSTRAINT PK_Pedidos PRIMARY KEY (idPedido)
) ;

-- Table: Personas
CREATE TABLE Personas (
    idPersona char(40)  NOT NULL,
    dsNombre varchar2(100)  NULL,
    dsApellido varchar2(100)  NULL,
    CONSTRAINT IDPERSONA PRIMARY KEY (idPersona)
) ;

-- Table: tblslvConsolidadoComi
CREATE TABLE tblslvConsolidadoComi (
    idConsolidadoComi integer  NOT NULL,
    idConsolidadoM integer  NOT NULL,
    Grupo integer  NULL,
    idPersona char(40)  NOT NULL,
    cdEstado integer  NOT NULL,
    dtInsert date  NULL,
    dtUpdate date  NULL,
    CONSTRAINT PK_ConsolidadoComi PRIMARY KEY (idConsolidadoComi)
) ;

-- Table: tblslvConsolidadoComiDet
CREATE TABLE tblslvConsolidadoComiDet (
    idConsolidadoComiDet integer  NOT NULL,
    idConsolidadoComi integer  NOT NULL,
    cdArticulo char(8)  NOT NULL,
    qtUnidadMedidaBase number(10,2)  NOT NULL,
    qtPiezas integer  NOT NULL,
    qtUnidadMedidaBasePicking number(10,2)  NULL,
    qtPiezasPicking integer  NULL,
    idGrupo_Sector integer  NOT NULL,
    CONSTRAINT UK_ConsolidadoComiDet_Articulo UNIQUE (idConsolidadoComi, cdArticulo),
    CONSTRAINT PK_ConsolidadoComiDet PRIMARY KEY (idConsolidadoComiDet)
) ;

-- Table: tblslvConsolidadoM
CREATE TABLE tblslvConsolidadoM (
    idConsolidadoM integer  NOT NULL,
    qtConsolidado integer  NOT NULL,
    idPersona char(40)  NOT NULL,
    cdEstado integer  NOT NULL,
    dtInsert date  NOT NULL,
    dtUpdate date  NULL,
    CONSTRAINT PK_ConsolidadoM PRIMARY KEY (idConsolidadoM)
) ;

-- Table: tblslvConsolidadoMDet
CREATE TABLE tblslvConsolidadoMDet (
    idConsolidadoMDet integer  NOT NULL,
    idConsolidadoM integer  NOT NULL,
    cdArticulo char(8)  NOT NULL,
    qtUnidadMedidaBase number(10,2)  NOT NULL,
    qtPiezas integer  NULL,
    QtUnidadMedidaBasePicking number(10,2)  NULL,
    qtPiezasPicking integer  NULL,
    idGrupo_Sector integer  NOT NULL,
    CONSTRAINT UK_ConsolidadoMDet_Articulo UNIQUE (idConsolidadoM, cdArticulo),
    CONSTRAINT PK_ConsolidadoMDet PRIMARY KEY (idConsolidadoMDet)
) ;

-- Table: tblslvConsolidadoPedido
CREATE TABLE tblslvConsolidadoPedido (
    idConsolidadoPedido integer  NOT NULL,
    identidad char(40)  NOT NULL,
    cdEstado integer  NOT NULL,
    idConsolidadoM integer  NULL,
    idPersona char(40)  NOT NULL,
    idConsolidadoComi integer  NULL,
    dtInsert date  NOT NULL,
    dtUpdate date  NULL,
    CONSTRAINT PK_ConsolidadoPedido PRIMARY KEY (idConsolidadoPedido)
) ;

-- Table: tblslvConsolidadoPedidoDet
CREATE TABLE tblslvConsolidadoPedidoDet (
    idConsolidadoPedidoDet integer  NOT NULL,
    idConsolidadoPedido integer  NOT NULL,
    cdArticulo char(8)  NOT NULL,
    qtUnidadesMedidaBase number(10,2)  NOT NULL,
    qtPiezas integer  NOT NULL,
    qtUnidadMedidaBasePicking number(10,2)  NULL,
    qtPiezasPicking integer  NULL,
    idGrupo_Sector integer  NOT NULL,
    CONSTRAINT UK_ConsolidadoPedDet_Articulo UNIQUE (idConsolidadoPedido, cdArticulo),
    CONSTRAINT PK_ConsolidadoPedidoDet PRIMARY KEY (idConsolidadoPedidoDet)
) ;

-- Table: tblslvConsolidadoPedidoRel
CREATE TABLE tblslvConsolidadoPedidoRel (
    idConsolidadoPedidoRel integer  NOT NULL,
    idPedido char(40)  NOT NULL,
    idConsolidadoPedido integer  NOT NULL,
    CONSTRAINT PK_ConsolidadoPedidoRel PRIMARY KEY (idConsolidadoPedidoRel)
) ;

-- Table: tblslvDistribucionPedFaltante
CREATE TABLE tblslvDistribucionPedFaltante (
    idDistribucionPedFaltante integer  NOT NULL,
    idPedFaltanteRel integer  NOT NULL,
    idRemito integer  NULL,
    cdArticulo char(8)  NOT NULL,
    qtUnidadMedidaBase number(10,2)  NOT NULL,
    qtPiezas integer  NOT NULL,
    CONSTRAINT PK_DistribucionPedFaltante PRIMARY KEY (idDistribucionPedFaltante)
) ;

-- Table: tblslvEstado
CREATE TABLE tblslvEstado (
    cdEstado integer  NOT NULL,
    dsEstado varchar2(40)  NOT NULL,
    tipo varchar2(50)  NOT NULL,
    CONSTRAINT PK_Estado PRIMARY KEY (cdEstado)
) ;

-- Table: tblslvPedFaltante
CREATE TABLE tblslvPedFaltante (
    idPedFaltante integer  NOT NULL,
    idPersona char(40)  NOT NULL,
    cdEstado integer  NOT NULL,
    dtInsert date  NOT NULL,
    dtUpdate date  NULL,
    CONSTRAINT PK_PedFaltante PRIMARY KEY (idPedFaltante)
) ;

-- Table: tblslvPedFaltanteDet
CREATE TABLE tblslvPedFaltanteDet (
    idPedFaltanteDet integer  NOT NULL,
    idPedFaltante integer  NOT NULL,
    cdArticulo char(8)  NOT NULL,
    qtUnidadMedidaBase number(10,2)  NOT NULL,
    qtPiezas integer  NOT NULL,
    qtUnidadMedidaBasePicking number(10,2)  NULL,
    qtPiezasPicking integer  NULL,
    idGrupo_Sector integer  NOT NULL,
    CONSTRAINT UK_PedFaltanteDet_Articulo UNIQUE (idPedFaltante, cdArticulo),
    CONSTRAINT PK_PedFaltanteDet PRIMARY KEY (idPedFaltanteDet)
) ;

-- Table: tblslvPedFaltanteRel
CREATE TABLE tblslvPedFaltanteRel (
    idPedFaltanteRel integer  NOT NULL,
    idPedFaltante integer  NOT NULL,
    idConsolidadoPedido integer  NOT NULL,
    dtDistribucion date  NULL,
    idPersonaDistribucion char(40)  NULL,
    dtInsert date  NOT NULL,
    dtUpdate date  NULL,
    CONSTRAINT PK_PedFaltanteRel PRIMARY KEY (idPedFaltanteRel)
) ;

-- Table: tblslvPedidoConformado
CREATE TABLE tblslvPedidoConformado (
    idPedido char(40)  NOT NULL,
    cdArticulo char(8)  NOT NULL,
    sqDetallePedido integer  NOT NULL,
    cdUnidadMedida char(8)  NOT NULL,
    qtUnidadPedido number  NOT NULL,
    qtUnidadMedidaBase number  NOT NULL,
    qtPiezas integer  NOT NULL,
    amPrecioUnitario number  NOT NULL,
    amLinea number  NULL,
    vlUxb number  NOT NULL,
    dsObservacion varchar2(50)  NULL,
    icresPromo integer  NULL,
    cdPromo char(8)  NULL,
    dtInsert date  NOT NULL,
    dtUpdate date  NULL,
    CONSTRAINT PK_PedidoConformado PRIMARY KEY (idPedido,sqDetallePedido)
) ;

-- Table: tblslvRemito
CREATE TABLE tblslvRemito (
    idRemito integer  NOT NULL,
    idTarea integer  NOT NULL,
    nroCarreta varchar2(15)  NOT NULL,
    cdEstado integer  NOT NULL,
    dtRemito date  NOT NULL,
    dtUpdate date  NULL,
    CONSTRAINT tblslvRemito_pk PRIMARY KEY (idRemito)
) ;

-- Table: tblslvRemitoDet
CREATE TABLE tblslvRemitoDet (
    idRemitoDet integer  NOT NULL,
    idRemito integer  NOT NULL,
    cdArticulo char(8)  NOT NULL,
    qtUnidadMedidaBasePicking number(10,2)  NULL,
    qtPiezasPicking number(10,2)  NULL,
    dtInsert date  NOT NULL,
    dtUpdate date  NOT NULL,
    CONSTRAINT UK_Remito_Articulo UNIQUE (idRemito, cdArticulo),
    CONSTRAINT tblslvRemitoDet_pk PRIMARY KEY (idRemitoDet)
) ;

-- Table: tblslvTarea
CREATE TABLE tblslvTarea (
    idTarea integer  NOT NULL,
    idPedFaltante integer  NULL,
    idConsolidadoM integer  NULL,
    idConsolidadoPedido integer  NULL,
    idConsolidadoComi integer  NULL,
    cdTipo integer  NOT NULL,
    idPersona char(40)  NOT NULL,
    idPersonaArmador char(40)  NOT NULL,
    dtInicio date  NULL,
    dtFin date  NULL,
    Prioridad integer  NOT NULL,
    cdEstado integer  NOT NULL,
    dtInsert date  NOT NULL,
    dtUpdate date  NULL,
    CONSTRAINT PK_Tarea PRIMARY KEY (idTarea)
) ;

-- Table: tblslvTareaDet
CREATE TABLE tblslvTareaDet (
    idTareaDet integer  NOT NULL,
    idTarea integer  NOT NULL,
    cdArticulo char(8)  NOT NULL,
    qtUnidadMedidaBase number(10,2)  NOT NULL,
    qtUnidadMedidaBasePicking number(10,2)  NULL,
    qtPiezas integer  NULL,
    QtPiezasPicking integer  NULL,
    dtInsert date  NULL,
    dtUpdate date  NULL,
    icFinalizado integer  NOT NULL,
    CONSTRAINT UK_TareaDet_Articulo UNIQUE (idTarea, cdArticulo),
    CONSTRAINT PK_TareaDet PRIMARY KEY (idTareaDet)
) ;

-- Table: tblslvTipoTarea
CREATE TABLE tblslvTipoTarea (
    cdTipo integer  NOT NULL,
    dsTarea varchar2(40)  NOT NULL,
    icGeneraRemito integer  DEFAULT 0 NOT NULL,
    CONSTRAINT PK_TipoTarea PRIMARY KEY (cdTipo)
) ;

-- Table: tblslv_grupo_sector
CREATE TABLE tblslv_grupo_sector (
    idGrupo_Sector integer  NOT NULL,
    cdGrupo integer  NOT NULL,
    cdSector char(8)  NOT NULL,
    cdSucursal char(8)  NULL,
    Orden integer  NOT NULL,
    dsGrupoSector varchar2(50)  NOT NULL,
    Activo integer  NULL,
    cdSecGrupoArt integer  NULL,
    CONSTRAINT PK_GrupoSector PRIMARY KEY (idGrupo_Sector)
) ;

-- Table: tbltmpslvConsolidadoM
CREATE TABLE tbltmpslvConsolidadoM (
    idtmpConsolidadoM varchar2(40)  NOT NULL,
    idPersona char(40)  NOT NULL,
    idComisionista char(40)  NULL,
    idCanal varchar2(2)  NOT NULL,
    QtBtoConsolidar number(10,2)  NOT NULL,
    TransID varchar2(50)  NOT NULL,
    Grupo integer  NULL,
    CONSTRAINT PK_TmpConsolidadoM PRIMARY KEY (idtmpConsolidadoM)
) ;

-- foreign keys
-- Reference: FK_Articulo_ConsolidadoComiDet (table: tblslvConsolidadoComiDet)
ALTER TABLE tblslvConsolidadoComiDet ADD CONSTRAINT FK_Articulo_ConsolidadoComiDet
    FOREIGN KEY (cdArticulo)
    REFERENCES Articulos (cdArticulo);

-- Reference: FK_Articulo_DistribPedFaltante (table: tblslvDistribucionPedFaltante)
ALTER TABLE tblslvDistribucionPedFaltante ADD CONSTRAINT FK_Articulo_DistribPedFaltante
    FOREIGN KEY (cdArticulo)
    REFERENCES Articulos (cdArticulo);

-- Reference: FK_Articulo_PedidoConformado (table: tblslvPedidoConformado)
ALTER TABLE tblslvPedidoConformado ADD CONSTRAINT FK_Articulo_PedidoConformado
    FOREIGN KEY (cdArticulo)
    REFERENCES Articulos (cdArticulo);

-- Reference: FK_Articulos_ConsolidadoMDet (table: tblslvConsolidadoMDet)
ALTER TABLE tblslvConsolidadoMDet ADD CONSTRAINT FK_Articulos_ConsolidadoMDet
    FOREIGN KEY (cdArticulo)
    REFERENCES Articulos (cdArticulo);

-- Reference: FK_Articulos_ConsolidadoPedDet (table: tblslvConsolidadoPedidoDet)
ALTER TABLE tblslvConsolidadoPedidoDet ADD CONSTRAINT FK_Articulos_ConsolidadoPedDet
    FOREIGN KEY (cdArticulo)
    REFERENCES Articulos (cdArticulo);

-- Reference: FK_Articulos_PedFaltanteDet (table: tblslvPedFaltanteDet)
ALTER TABLE tblslvPedFaltanteDet ADD CONSTRAINT FK_Articulos_PedFaltanteDet
    FOREIGN KEY (cdArticulo)
    REFERENCES Articulos (cdArticulo);

-- Reference: FK_Articulos_RemitoDet (table: tblslvRemitoDet)
ALTER TABLE tblslvRemitoDet ADD CONSTRAINT FK_Articulos_RemitoDet
    FOREIGN KEY (cdArticulo)
    REFERENCES Articulos (cdArticulo);

-- Reference: FK_Articulos_TareaDet (table: tblslvTareaDet)
ALTER TABLE tblslvTareaDet ADD CONSTRAINT FK_Articulos_TareaDet
    FOREIGN KEY (cdArticulo)
    REFERENCES Articulos (cdArticulo);

-- Reference: FK_ConsolPed_ConsolidadoPedDet (table: tblslvConsolidadoPedidoDet)
ALTER TABLE tblslvConsolidadoPedidoDet ADD CONSTRAINT FK_ConsolPed_ConsolidadoPedDet
    FOREIGN KEY (idConsolidadoPedido)
    REFERENCES tblslvConsolidadoPedido (idConsolidadoPedido);

-- Reference: FK_ConsoliComi_ConsoliComiDet (table: tblslvConsolidadoComiDet)
ALTER TABLE tblslvConsolidadoComiDet ADD CONSTRAINT FK_ConsoliComi_ConsoliComiDet
    FOREIGN KEY (idConsolidadoComi)
    REFERENCES tblslvConsolidadoComi (idConsolidadoComi);

-- Reference: FK_ConsoliComi_ConsoliPedido (table: tblslvConsolidadoPedido)
ALTER TABLE tblslvConsolidadoPedido ADD CONSTRAINT FK_ConsoliComi_ConsoliPedido
    FOREIGN KEY (idConsolidadoComi)
    REFERENCES tblslvConsolidadoComi (idConsolidadoComi);

-- Reference: FK_ConsoliM_ConsolidadoComi (table: tblslvConsolidadoComi)
ALTER TABLE tblslvConsolidadoComi ADD CONSTRAINT FK_ConsoliM_ConsolidadoComi
    FOREIGN KEY (idConsolidadoM)
    REFERENCES tblslvConsolidadoM (idConsolidadoM);

-- Reference: FK_ConsoliM_ConsolidadoMDet (table: tblslvConsolidadoMDet)
ALTER TABLE tblslvConsolidadoMDet ADD CONSTRAINT FK_ConsoliM_ConsolidadoMDet
    FOREIGN KEY (idConsolidadoM)
    REFERENCES tblslvConsolidadoM (idConsolidadoM);

-- Reference: FK_ConsoliPed_ConsoliPedRel (table: tblslvConsolidadoPedidoRel)
ALTER TABLE tblslvConsolidadoPedidoRel ADD CONSTRAINT FK_ConsoliPed_ConsoliPedRel
    FOREIGN KEY (idConsolidadoPedido)
    REFERENCES tblslvConsolidadoPedido (idConsolidadoPedido);

-- Reference: FK_ConsoliPed_PedFaltanteRel (table: tblslvPedFaltanteRel)
ALTER TABLE tblslvPedFaltanteRel ADD CONSTRAINT FK_ConsoliPed_PedFaltanteRel
    FOREIGN KEY (idConsolidadoPedido)
    REFERENCES tblslvConsolidadoPedido (idConsolidadoPedido);

-- Reference: FK_ConsolidadoComi_Tarea (table: tblslvTarea)
ALTER TABLE tblslvTarea ADD CONSTRAINT FK_ConsolidadoComi_Tarea
    FOREIGN KEY (idConsolidadoComi)
    REFERENCES tblslvConsolidadoComi (idConsolidadoComi);

-- Reference: FK_ConsolidadoM_ConsoliPedido (table: tblslvConsolidadoPedido)
ALTER TABLE tblslvConsolidadoPedido ADD CONSTRAINT FK_ConsolidadoM_ConsoliPedido
    FOREIGN KEY (idConsolidadoM)
    REFERENCES tblslvConsolidadoM (idConsolidadoM);

-- Reference: FK_ConsolidadoM_Tarea (table: tblslvTarea)
ALTER TABLE tblslvTarea ADD CONSTRAINT FK_ConsolidadoM_Tarea
    FOREIGN KEY (idConsolidadoM)
    REFERENCES tblslvConsolidadoM (idConsolidadoM);

-- Reference: FK_ConsolidadoPedido_Tarea (table: tblslvTarea)
ALTER TABLE tblslvTarea ADD CONSTRAINT FK_ConsolidadoPedido_Tarea
    FOREIGN KEY (idConsolidadoPedido)
    REFERENCES tblslvConsolidadoPedido (idConsolidadoPedido);

-- Reference: FK_Entidades_ConsolidadoPedido (table: tblslvConsolidadoPedido)
ALTER TABLE tblslvConsolidadoPedido ADD CONSTRAINT FK_Entidades_ConsolidadoPedido
    FOREIGN KEY (identidad)
    REFERENCES ENTIDADES (Identidad);

-- Reference: FK_Estado_ConsolidadoComi (table: tblslvConsolidadoComi)
ALTER TABLE tblslvConsolidadoComi ADD CONSTRAINT FK_Estado_ConsolidadoComi
    FOREIGN KEY (cdEstado)
    REFERENCES tblslvEstado (cdEstado);

-- Reference: FK_Estado_ConsolidadoM (table: tblslvConsolidadoM)
ALTER TABLE tblslvConsolidadoM ADD CONSTRAINT FK_Estado_ConsolidadoM
    FOREIGN KEY (cdEstado)
    REFERENCES tblslvEstado (cdEstado);

-- Reference: FK_Estado_ConsolidadoPedido (table: tblslvConsolidadoPedido)
ALTER TABLE tblslvConsolidadoPedido ADD CONSTRAINT FK_Estado_ConsolidadoPedido
    FOREIGN KEY (cdEstado)
    REFERENCES tblslvEstado (cdEstado);

-- Reference: FK_Estado_PedFaltante (table: tblslvPedFaltante)
ALTER TABLE tblslvPedFaltante ADD CONSTRAINT FK_Estado_PedFaltante
    FOREIGN KEY (cdEstado)
    REFERENCES tblslvEstado (cdEstado);

-- Reference: FK_Estado_Remito (table: tblslvRemito)
ALTER TABLE tblslvRemito ADD CONSTRAINT FK_Estado_Remito
    FOREIGN KEY (cdEstado)
    REFERENCES tblslvEstado (cdEstado);

-- Reference: FK_Estado_Tarea (table: tblslvTarea)
ALTER TABLE tblslvTarea ADD CONSTRAINT FK_Estado_Tarea
    FOREIGN KEY (cdEstado)
    REFERENCES tblslvEstado (cdEstado);

-- Reference: FK_GrupSector_ConsolidComiDet (table: tblslvConsolidadoComiDet)
ALTER TABLE tblslvConsolidadoComiDet ADD CONSTRAINT FK_GrupSector_ConsolidComiDet
    FOREIGN KEY (idGrupo_Sector)
    REFERENCES tblslv_grupo_sector (idGrupo_Sector);

-- Reference: FK_GrupoSector_ConsolidPedDet (table: tblslvConsolidadoPedidoDet)
ALTER TABLE tblslvConsolidadoPedidoDet ADD CONSTRAINT FK_GrupoSector_ConsolidPedDet
    FOREIGN KEY (idGrupo_Sector)
    REFERENCES tblslv_grupo_sector (idGrupo_Sector);

-- Reference: FK_GrupoSector_ConsolidadoMDet (table: tblslvConsolidadoMDet)
ALTER TABLE tblslvConsolidadoMDet ADD CONSTRAINT FK_GrupoSector_ConsolidadoMDet
    FOREIGN KEY (idGrupo_Sector)
    REFERENCES tblslv_grupo_sector (idGrupo_Sector);

-- Reference: FK_GrupoSector_PedFaltanteDet (table: tblslvPedFaltanteDet)
ALTER TABLE tblslvPedFaltanteDet ADD CONSTRAINT FK_GrupoSector_PedFaltanteDet
    FOREIGN KEY (idGrupo_Sector)
    REFERENCES tblslv_grupo_sector (idGrupo_Sector);

-- Reference: FK_PedFaltaRel_DistribPedFalta (table: tblslvDistribucionPedFaltante)
ALTER TABLE tblslvDistribucionPedFaltante ADD CONSTRAINT FK_PedFaltaRel_DistribPedFalta
    FOREIGN KEY (idPedFaltanteRel)
    REFERENCES tblslvPedFaltanteRel (idPedFaltanteRel);

-- Reference: FK_PedFaltante_PedFaltanteDet (table: tblslvPedFaltanteDet)
ALTER TABLE tblslvPedFaltanteDet ADD CONSTRAINT FK_PedFaltante_PedFaltanteDet
    FOREIGN KEY (idPedFaltante)
    REFERENCES tblslvPedFaltante (idPedFaltante);

-- Reference: FK_PedFaltante_PedFaltanteRel (table: tblslvPedFaltanteRel)
ALTER TABLE tblslvPedFaltanteRel ADD CONSTRAINT FK_PedFaltante_PedFaltanteRel
    FOREIGN KEY (idPedFaltante)
    REFERENCES tblslvPedFaltante (idPedFaltante);

-- Reference: FK_PedFaltante_Tarea (table: tblslvTarea)
ALTER TABLE tblslvTarea ADD CONSTRAINT FK_PedFaltante_Tarea
    FOREIGN KEY (idPedFaltante)
    REFERENCES tblslvPedFaltante (idPedFaltante);

-- Reference: FK_Pedidos_ConsolidadoPedRel (table: tblslvConsolidadoPedidoRel)
ALTER TABLE tblslvConsolidadoPedidoRel ADD CONSTRAINT FK_Pedidos_ConsolidadoPedRel
    FOREIGN KEY (idPedido)
    REFERENCES PEDIDOS (idPedido);

-- Reference: FK_Personas_ConsolidadoComi (table: tblslvConsolidadoComi)
ALTER TABLE tblslvConsolidadoComi ADD CONSTRAINT FK_Personas_ConsolidadoComi
    FOREIGN KEY (idPersona)
    REFERENCES Personas (idPersona);

-- Reference: FK_Personas_ConsolidadoM (table: tblslvConsolidadoM)
ALTER TABLE tblslvConsolidadoM ADD CONSTRAINT FK_Personas_ConsolidadoM
    FOREIGN KEY (idPersona)
    REFERENCES Personas (idPersona);

-- Reference: FK_Personas_ConsolidadoPedido (table: tblslvConsolidadoPedido)
ALTER TABLE tblslvConsolidadoPedido ADD CONSTRAINT FK_Personas_ConsolidadoPedido
    FOREIGN KEY (idPersona)
    REFERENCES Personas (idPersona);

-- Reference: FK_Personas_PedFaltante (table: tblslvPedFaltante)
ALTER TABLE tblslvPedFaltante ADD CONSTRAINT FK_Personas_PedFaltante
    FOREIGN KEY (idPersona)
    REFERENCES Personas (idPersona);

-- Reference: FK_Personas_PedFaltanteRel (table: tblslvPedFaltanteRel)
ALTER TABLE tblslvPedFaltanteRel ADD CONSTRAINT FK_Personas_PedFaltanteRel
    FOREIGN KEY (idPersonaDistribucion)
    REFERENCES Personas (idPersona);

-- Reference: FK_Personas_Tarea (table: tblslvTarea)
ALTER TABLE tblslvTarea ADD CONSTRAINT FK_Personas_Tarea
    FOREIGN KEY (idPersona)
    REFERENCES Personas (idPersona);

-- Reference: FK_Personas_Tarea_Armador (table: tblslvTarea)
ALTER TABLE tblslvTarea ADD CONSTRAINT FK_Personas_Tarea_Armador
    FOREIGN KEY (idPersonaArmador)
    REFERENCES Personas (idPersona);

-- Reference: FK_Remito_DistribuPedFaltante (table: tblslvDistribucionPedFaltante)
ALTER TABLE tblslvDistribucionPedFaltante ADD CONSTRAINT FK_Remito_DistribuPedFaltante
    FOREIGN KEY (idRemito)
    REFERENCES tblslvRemito (idRemito);

-- Reference: FK_Remito_RemitoDet (table: tblslvRemitoDet)
ALTER TABLE tblslvRemitoDet ADD CONSTRAINT FK_Remito_RemitoDet
    FOREIGN KEY (idRemito)
    REFERENCES tblslvRemito (idRemito);

-- Reference: FK_Tarea_Remito (table: tblslvRemito)
ALTER TABLE tblslvRemito ADD CONSTRAINT FK_Tarea_Remito
    FOREIGN KEY (idTarea)
    REFERENCES tblslvTarea (idTarea);

-- Reference: FK_Tarea_TareaDet (table: tblslvTareaDet)
ALTER TABLE tblslvTareaDet ADD CONSTRAINT FK_Tarea_TareaDet
    FOREIGN KEY (idTarea)
    REFERENCES tblslvTarea (idTarea);

-- Reference: FK_TipoTarea_Tarea (table: tblslvTarea)
ALTER TABLE tblslvTarea ADD CONSTRAINT FK_TipoTarea_Tarea
    FOREIGN KEY (cdTipo)
    REFERENCES tblslvTipoTarea (cdTipo);

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

-- Sequence: SEQ_RemitoDet
CREATE SEQUENCE SEQ_RemitoDet
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

-- End of file.

