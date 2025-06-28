

--A partir od Sq1l server 2014

ALTER DATABASE Implanta
ADD FILEGROUP InMemoryFileGroup
CONTAINS MEMORY_OPTIMIZED_DATA;


ALTER DATABASE Implanta
ADD FILE (NAME = 'InMemoryFile',
          FILENAME = 'D:\MSSQL\ImMemory.ndf')
TO FILEGROUP InMemoryFileGroup;




CREATE TABLE [Contabilidade].[MovimentosMemory] 
(
    [IdMovimento] [UNIQUEIDENTIFIER] NOT NULL PRIMARY KEY NONCLUSTERED HASH
                                              WITH (BUCKET_COUNT = 1000000),
    [IdLancamento] [UNIQUEIDENTIFIER] NOT NULL,
    [IdPlanoConta] [UNIQUEIDENTIFIER] NOT NULL,
    [Credito] [BIT] NOT NULL
        CONSTRAINT [DEF_ContabilidadeMovimentosCreditoMemory]
            DEFAULT ((0)),
    [NumeroProcesso] [VARCHAR](20) COLLATE Latin1_General_CI_AI NULL,
    [NumeroDocumento] [INT] NULL,
    [Valor] [NUMERIC](18, 2) NOT NULL
        CONSTRAINT [DEF_ContabilidadeMovimentosValorMemory]
            DEFAULT ((0)),
    [Historico] [VARCHAR](MAX) COLLATE Latin1_General_CI_AI NULL)
WITH (MEMORY_OPTIMIZED = ON, DURABILITY = SCHEMA_AND_DATA
);
GO


--Fazendo o Insert


INSERT INTO Contabilidade.MovimentosMemory (IdMovimento,
                                            IdLancamento,
                                            IdPlanoConta,
                                            Credito,
                                            NumeroProcesso,
                                            NumeroDocumento,
                                            Valor,
                                            Historico)
SELECT * FROM Contabilidade.Movimentos AS M


SET STATISTICS IO  ON 
 
SELECT * FROM Contabilidade.MovimentosMemory AS MM
WHERE MM.IdMovimento ='C74A9EF1-5D8A-44D0-A61D-33402BA38FDD'
SET STATISTICS IO  OFF