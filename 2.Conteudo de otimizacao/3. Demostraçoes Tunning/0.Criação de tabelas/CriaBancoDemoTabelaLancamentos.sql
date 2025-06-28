

IF(NOT EXISTS( SELECT * FROM  sys.databases AS D
WHERE D.name ='Demostracao'))
BEGIN
		
		CREATE DATABASE Demostracao;
		
		WAITFOR DELAY  '00:02';
END


GO

USE Demostracao 

GO

IF (NOT EXISTS
(
    SELECT 1
    FROM sys.sequences AS s
    WHERE s.name = 'SeqForNewCliente'
)
   )
BEGIN
    CREATE SEQUENCE SeqForNewCliente MINVALUE 1 INCREMENT BY 1 CACHE 100;
END;


IF (OBJECT_ID('Lancamentos', 'U') IS NOT NULL)
BEGIN

    DROP TABLE dbo.Lancamentos;
END;





GO


IF (OBJECT_ID('Clientes', 'U') IS NOT NULL)
BEGIN

    DROP TABLE Clientes;
END;

CREATE TABLE Clientes
(
    IdCliente INT NOT NULL
        DEFAULT (NEXT VALUE FOR dbo.SeqForNewCliente),
    Nome VARCHAR(50),
    CONSTRAINT PKCliente
        PRIMARY KEY (IdCliente) ON [PRIMARY],
);





IF (OBJECT_ID('Bancos', 'U') IS NOT NULL)
BEGIN

    DROP TABLE dbo.Bancos;
END;

CREATE TABLE [dbo].[Bancos]
(
    [idBanco] INT NOT NULL IDENTITY(1, 1) PRIMARY KEY ,
    [NomeBanco] [VARCHAR](30) COLLATE Latin1_General_CI_AI NULL
);


CREATE TABLE [dbo].[Lancamentos]
(
    [idLancamento] [UNIQUEIDENTIFIER] NOT NULL ROWGUIDCOL
        DEFAULT (NEWSEQUENTIALID()),
	[IdCliente] INT NOT NULL FOREIGN KEY REFERENCES dbo.Clientes(IdCliente),
    [idBanco] INT NOT NULL REFERENCES dbo.Bancos(idBanco),
    [Historico] [VARCHAR](100) COLLATE Latin1_General_CI_AI NOT NULL
        DEFAULT ('Histórico padrão para lançamentos bancários.'),
    [NumeroLancamento] [INT] NOT NULL,
    [Data] [DATETIME] NOT NULL,
    [Valor] [DECIMAL](18, 2) NULL,
    [Credito] [BIT] NOT NULL,
);

/*Adiciona um campo PK  */

INSERT INTO dbo.Bancos
(
    [NomeBanco]
)
VALUES ('Banco A'), ('Banco B');


ALTER SEQUENCE SeqForNewCliente RESTART WITH 1
INSERT INTO dbo.Clientes
(
    Nome
)
VALUES ('Wesley Neves'),('Jóse Diz'),('Pedro Galvão'),('gapimex'),('Rafael Almeida');




-- ==================================================================
-- Author:Wesley Neves
--Observação: cria tabela com 1 milhão de registros
-- ==================================================================
DECLARE @MinCliente INT  = (SELECT  ISNULL(MIN(c.IdCliente),1) FROM dbo.Clientes AS c);
DECLARE @MaxCliente INT  = (SELECT  ISNULL(MAX(c.IdCliente),1) FROM dbo.Clientes AS c);
DECLARE @Random INT;
SELECT @Random = ROUND(((@MaxCliente - @MinCliente -1) * RAND() + @MinCliente), 0)


DECLARE @dataInicio DATETIME = '2011-01-01';

DECLARE @IsCredito BIT = 1;

DECLARE @IdBanco1 INT = (
                            SELECT TOP 1
                                CB.idBanco
                            FROM dbo.Bancos AS CB
                            WHERE CB.NomeBanco = 'Banco A'
                        );

DECLARE @IdBanco2 INT = (
                            SELECT TOP 1
                                CB.idBanco
                            FROM dbo.Bancos AS CB
                            WHERE CB.NomeBanco = 'Banco B'
                        );


WITH CTE
AS (SELECT 1 AS NumeroLancamento
    UNION ALL
    SELECT CTE.NumeroLancamento + 1
    FROM CTE
    WHERE CTE.NumeroLancamento < 100000
   ),
     Query
AS (SELECT CTE.NumeroLancamento,
           TA.IdConta,
           TA.Data,
           TA.Valor,
           TA.Credito
    FROM CTE
        CROSS APPLY
    (
        SELECT CASE
                   WHEN (CTE.NumeroLancamento % 2 = 0) THEN
                       @IdBanco1
                   ELSE
                       @IdBanco2
               END AS IdConta,
               CAST(DATEADD(
                               DAY,
                               ABS(CHECKSUM(NEWID()) % IIF((CTE.NumeroLancamento <= 800000), 2555, 730)),
                               IIF((CTE.NumeroLancamento <= 800000), '2011-01-01', '2016-01-01')
                           ) AS DATE) AS Data,
               CAST(ABS(CAST((CAST(CHECKSUM(NEWID()) AS DECIMAL(18, 2)) / 1000000) AS DECIMAL(18, 2))) AS DECIMAL(18, 2)) AS Valor,
               IIF((CTE.NumeroLancamento <= 600000), 0, 1) AS Credito
    ) AS TA
   )
INSERT INTO dbo.Lancamentos WITH (TABLOCK)
(
    idBanco,
	IdCliente,
    NumeroLancamento,
    Data,
    Valor,
    Credito
)
SELECT Q.IdConta,
	   	( 1.0 + floor(5 * RAND(convert(varbinary, newid())))) AS IdCliente,
       Q.NumeroLancamento,
       Q.Data,
       Q.Valor,
       Q.Credito
FROM Query Q
OPTION (MAXRECURSION 0);


