
--ALTER DATABASE Lancamentos ADD FILEGROUP FileMemory CONTAINS MEMORY_OPTIMIZED_DATA


ALTER DATABASE Lancamentos
ADD FILE
    (
        NAME = arquivoFile,
        FILENAME = 'D:\Sql Server\Tabela in memory\arquivoFile'
    )
TO FILEGROUP FileMemory;


CREATE TABLE dbo.LacamentoMemory
(
    [idLancamento] [UNIQUEIDENTIFIER] NOT NULL PRIMARY KEY NONCLUSTERED HASH
                                               WITH (BUCKET_COUNT = 1000000),
    [idContaBancaria] [UNIQUEIDENTIFIER] NOT NULL,
    [Historico] [VARCHAR](100) COLLATE Latin1_General_CI_AS NOT NULL
        CONSTRAINT DefHistorico
            DEFAULT ('Histórico padrão para lançamentos bancários.'),
    [NumeroLancamento] [INT] NOT NULL,
    [Data] [DATETIME] NOT NULL,
    [Valor] [DECIMAL](18, 2) NULL,
    [Credito] [BIT] NOT NULL,
)
WITH (MEMORY_OPTIMIZED = ON, DURABILITY = SCHEMA_AND_DATA);

SET STATISTICS TIME ON;
SELECT *
FROM dbo.LacamentoMemory AS LM
WHERE LM.NumeroLancamento < 10000;
SET STATISTICS TIME OFF;

DBCC DROPCLEANBUFFERS;
SET STATISTICS TIME ON;


SELECT *
FROM dbo.Lancamentos AS L
WHERE L.NumeroLancamento < 10000;
SET STATISTICS TIME OFF;


