DROP TABLE IF EXISTS dbo.Lancamentos
DROP TABLE IF EXISTS dbo.ContaBancaria


IF(NOT EXISTS(SELECT * FROM sys.schemas AS S
WHERE S.name ='Automation'))
BEGIN
		EXEC ('CREATE SCHEMA Automation;');
END

IF(NOT EXISTS(SELECT * FROM sys.schemas AS S
WHERE S.name ='HealthCheck'))
BEGIN
		EXEC ('CREATE SCHEMA HealthCheck;');
END



IF (OBJECT_ID('ContaBancaria', 'U') IS NULL)
BEGIN

    CREATE TABLE dbo.ContaBancaria
    (
        idContaBancaria UNIQUEIDENTIFIER NOT NULL
            CONSTRAINT DEF_ContaBancariaidContaBancaria
                DEFAULT (NEWSEQUENTIALID()),
        NomeConta VARCHAR(30) NOT NULL,
        CONSTRAINT PK_ContaBancariaIdContaBancaria
            PRIMARY KEY (idContaBancaria)
    );


    INSERT dbo.ContaBancaria
    (
        NomeConta
    )
    VALUES
    ('CEF'),
    ('BB');

END;

IF (OBJECT_ID('Lancamentos', 'U') IS NULL)
BEGIN

    CREATE TABLE dbo.Lancamentos
    (
        idLancamento UNIQUEIDENTIFIER NOT NULL ROWGUIDCOL
            CONSTRAINT DEF_LancamentosIdLancamento
                DEFAULT (NEWSEQUENTIALID()),
        idContaBancaria UNIQUEIDENTIFIER NOT NULL,
        Historico VARCHAR(100) NOT NULL
            CONSTRAINT DEF_LancamentosHistorico
                DEFAULT ('Historico padrão para lançamentos bancários.'),
        NumeroLancamento INT NOT NULL,
        Data DATETIME2(2) NOT NULL,
        Valor DECIMAL(18, 2) NOT NULL,
        Credito BIT NOT NULL,
        CONSTRAINT PK_Lancamentos
            PRIMARY KEY (idLancamento)
    );

    ALTER TABLE dbo.Lancamentos
    ADD CONSTRAINT FK_Lancamentos_Contem_ContaBancaria
        FOREIGN KEY (idContaBancaria)
        REFERENCES dbo.ContaBancaria (idContaBancaria);
END;







-- ==================================================================
--Observa��o:faz insert dos dados com valoes aleatorios
-- ==================================================================


DECLARE @dataInicio DATETIME = '2011-01-01';
DECLARE @IsCredito BIT = 1;
DECLARE @IdContaBancariaCEF UNIQUEIDENTIFIER =
        (
            SELECT TOP 1
                   CB.idContaBancaria
            FROM dbo.ContaBancaria AS CB
            WHERE CB.NomeConta = 'CEF'
        );
DECLARE @IdContaBancariaBB UNIQUEIDENTIFIER =
        (
            SELECT TOP 1
                   CB.idContaBancaria
            FROM dbo.ContaBancaria AS CB
            WHERE CB.NomeConta = 'BB'
        );


WITH CTE
AS (SELECT 1 AS NumeroLancamento
    UNION ALL
    SELECT CTE.NumeroLancamento + 1
    FROM CTE
    WHERE CTE.NumeroLancamento < 3000000),
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
                       @IdContaBancariaCEF
                   ELSE
                       @IdContaBancariaBB
               END AS IdConta,
               CAST(DATEADD(
                               DAY,
                               ABS(CHECKSUM(NEWID()) % IIF((CTE.NumeroLancamento <= 800000), 2555, 730)),
                               IIF((CTE.NumeroLancamento <= 800000), '2011-01-01', '2022-01-01')
                           ) AS DATE) AS Data,
               CAST(ABS(CAST((CAST(CHECKSUM(NEWID()) AS DECIMAL(18, 2)) / 1000000) AS DECIMAL(18, 2))) AS DECIMAL(18, 2)) AS Valor,
               IIF((CTE.NumeroLancamento <= 600000), 0, 1) AS Credito
    ) AS TA )
INSERT INTO dbo.Lancamentos WITH (TABLOCK)
(
    idContaBancaria,
    NumeroLancamento,
    Data,
    Valor,
    Credito
)
SELECT Q.IdConta,
       Q.NumeroLancamento,
       Q.Data,
       Q.Valor,
       Q.Credito
FROM Query Q
OPTION (MAXRECURSION 0);




-- ==================================================================
-- Vamos analisar a quantidade de dados que temos por ano
-- ==================================================================

SELECT Ano = YEAR(L.Data),
       QuantidadeLancamento = FORMAT(COUNT(*), 'N', 'pt-Br')
FROM dbo.Lancamentos AS L
GROUP BY YEAR(L.Data)
ORDER BY YEAR(L.Data);