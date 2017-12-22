USE master

GO
IF ( db_id('ESTBay_Central') is not NULL )
DROP DATABASE ESTBay_Central

GO
CREATE DATABASE ESTBay_Central

GO
USE ESTBay_Central

GO

CREATE TABLE [FATURACAO_PT] (
IDFatura int IDENTITY(1,1),
NomeComprador nVarChar(255) NOT NULL,
NomeVendedor nVarChar(255) NOT NULL,
NomeProduto nVarChar(255) NOT NULL,
Valor Decimal(7,2) NOT NULL,
DataDeVenda Date NOT NULL
PRIMARY KEY(IDFatura))
GO

CREATE TABLE [FATURACAO_AO] (
IDFatura int IDENTITY(1,1),
NomeComprador nVarChar(255) NOT NULL,
NomeVendedor nVarChar(255) NOT NULL,
NomeProduto nVarChar(255) NOT NULL,
Valor Decimal(7,2) NOT NULL,
DataDeVenda Date NOT NULL
PRIMARY KEY(IDFatura))
GO

CREATE TABLE [FATURACAO_VA] (
IDFatura int IDENTITY(1,1),
NomeComprador nVarChar(255) NOT NULL,
NomeVendedor nVarChar(255) NOT NULL,
NomeProduto nVarChar(255) NOT NULL,
Valor Decimal(7,2) NOT NULL,
DataDeVenda Date NOT NULL
PRIMARY KEY(IDFatura))
GO

CREATE VIEW v_mostrar_faturacao AS
SELECT * FROM [FATURACAO_PT]
UNION ALL
SELECT * FROM [FATURACAO_AO]
UNION ALL
SELECT * FROM [FATURACAO_VA]
GO

INSERT INTO [FATURACAO_PT]
VALUES('John', 'Berner', 'COCAINA', 17.5, GETDATE());
INSERT INTO [FATURACAO_AO]
VALUES('Teresa', 'Lalanginha', 'Beer', 250, GETDATE());
INSERT INTO [FATURACAO_VA]
VALUES('BB-8', 'R2-D2', 'OIL', 1, GETDATE());

SELECT *
FROM v_mostrar_faturacao