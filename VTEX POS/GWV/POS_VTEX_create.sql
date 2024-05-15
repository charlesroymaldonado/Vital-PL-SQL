-- Created by Vertabelo (http://vertabelo.com)
-- Last modification date: 2020-11-11 17:54:07.317

-- Table: VTEXBRAND
CREATE TABLE VTEXBRAND (
    BrandId integer  NOT NULL,
    Name varchar2(200)  NOT NULL,
    IsActive integer  NOT NULL,
    CONSTRAINT PK_BRAND PRIMARY KEY (BrandId)
) ;

-- Table: VTEXCATALOG
CREATE TABLE VTEXCATALOG (
    DepartmentId integer  NOT NULL,
    DepartmentName varchar2(150)  NOT NULL,
    CategoryId integer  NOT NULL,
    CategoryName varchar2(150)  NOT NULL,
    SubCategoryId integer  NOT NULL,
    SubCategoryName varchar2(150)  NOT NULL,
    CONSTRAINT PK_VTEXCATALOG PRIMARY KEY (DepartmentId,CategoryId,SubCategoryId)
) ;

-- Table: VTEXPRODUCT
CREATE TABLE VTEXPRODUCT (
    ProductId integer  NOT NULL,
    name varchar2(60)  NOT NULL,
    DepartmentId integer  NOT NULL,
    CategoryId integer  NOT NULL,
    SubCategoryId integer  NOT NULL,
    BrandId integer  NOT NULL,
    LinkId varchar2(100)  NOT NULL,
    RefId char(8)  NOT NULL,
    IsVisible integer  DEFAULT 1 NOT NULL,
    Description varchar2(60)  NOT NULL,
    ReleaseDate date  NULL,
    CONSTRAINT UK_VTEXPRODUCT UNIQUE (ProductId, RefId),
    CONSTRAINT PK_VTEXPRODUCT PRIMARY KEY (RefId)
) ;

-- Table: VTEXSKU
CREATE TABLE VTEXSKU (
    SkuId integer  NOT NULL,
    RefId char(8)  NOT NULL,
    SkuName varchar2(60)  NOT NULL,
    IsActive integer  NOT NULL,
    ImageURL varchar2(100)  NOT NULL,
    ReleaseDate date  NOT NULL,
    UnitMultiplier integer  DEFAULT 1 NOT NULL,
    Factor integer  DEFAULT 1 NOT NULL,
    UxB integer  NOT NULL,
    CONSTRAINT PK_VTEXSKU PRIMARY KEY (SkuId,RefId)
) ;

-- foreign keys
-- Reference: FK_VTEXPRODUCT_VTEXBRAND (table: VTEXPRODUCT)
ALTER TABLE VTEXPRODUCT ADD CONSTRAINT FK_VTEXPRODUCT_VTEXBRAND
    FOREIGN KEY (BrandId)
    REFERENCES VTEXBRAND (BrandId);

-- Reference: FK_VTEXPRODUCT_VTEXCATALOG (table: VTEXPRODUCT)
ALTER TABLE VTEXPRODUCT ADD CONSTRAINT FK_VTEXPRODUCT_VTEXCATALOG
    FOREIGN KEY (DepartmentId,CategoryId,SubCategoryId)
    REFERENCES VTEXCATALOG (DepartmentId,CategoryId,SubCategoryId);

-- Reference: VTEXPRODUCT_ARTICULOS (table: VTEXPRODUCT)
ALTER TABLE VTEXPRODUCT ADD CONSTRAINT FK_VTEXPRODUCT_ARTICULOS
    FOREIGN KEY (RefId)
    REFERENCES ARTICULOS (cdarticulo);

-- Reference: VTEXSKU_VTEXPRODUCT (table: VTEXSKU)
ALTER TABLE VTEXSKU ADD CONSTRAINT FK_VTEXSKU_VTEXPRODUCT
    FOREIGN KEY (RefId)
    REFERENCES VTEXPRODUCT (RefId);

-- End of file.

