--DROP TABLE dbo.Lancamentos
--DROP TABLE dbo.Bancos

IF (OBJECT_ID('Bancos', 'U') IS NULL)
BEGIN
    CREATE TABLE [dbo].[Bancos]
    (
        [idBanco] INT NOT NULL IDENTITY(1, 1),
        [NomeBanco] [VARCHAR](30) COLLATE Latin1_General_CI_AI NULL
    );
END;

ALTER TABLE dbo.Bancos ADD CONSTRAINT PKbancos PRIMARY KEY(idBanco)

INSERT INTO dbo.Bancos
(
    [NomeBanco]
)
VALUES ('Banco A'),
('Banco B');



SELECT  OBJECT_NAME(PAR.object_id)  AS TableName,   
       PAR.index_id,   
       PAR.rows,   
       PAR.data_compression_desc , 
       p.type_desc, 
       p.filegroup_id, 
       p.total_pages, 
       p.used_pages, 
       p.data_pages, 
       p.first_page, 
       p.root_page, 
       p.first_iam_page  
FROM sys.partitions PAR   
JOIN sys.system_internals_allocation_units p ON PAR.partition_id =p.container_id 
WHERE PAR.object_id = OBJECT_ID('Bancos');   


CREATE TABLE [dbo].[Lancamentos] 
    ( 
      [idLancamento] [UNIQUEIDENTIFIER] NOT NULL 
                                        ROWGUIDCOL 
                                        DEFAULT ( NEWSEQUENTIALID() ) , 
      [idBanco] INT NOT NULL , 
      [Historico] [VARCHAR](100) 
        COLLATE Latin1_General_CI_AI 
        NOT NULL 
        DEFAULT ( 'Histórico padrão para lançamentos bancários.' ) , 
      [NumeroLancamento] [INT] NOT NULL , 
      [Data] [DATETIME] NOT NULL , 
      [Valor] [DECIMAL](18, 2) NULL , 
      [Credito] [BIT] NOT NULL,   
    
    );   
  

GO  






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
    WHERE CTE.NumeroLancamento < 1000000
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




SELECT  OBJECT_NAME(PAR.object_id)  AS TableName,  
       PAR.index_id,  
       PAR.rows,  
       PAR.data_compression_desc ,
       p.type_desc,
       p.filegroup_id,
       p.total_pages,
       p.used_pages,
       p.data_pages,
       p.first_page,
       p.root_page,
       p.first_iam_page 
FROM sys.partitions PAR  
JOIN sys.system_internals_allocation_units p ON PAR.partition_id =p.container_id
WHERE PAR.object_id = OBJECT_ID('Lancamentos');  


SELECT * FROM dbo.Bancos

SET STATISTICS IO  ON 	
SELECT * FROM dbo.Lancamentos
WHERE NumeroLancamento =55555
SET STATISTICS IO  OFF

SELECT   
       B.idBanco,  
       B.NomeBanco,  
       L.Data ,  
       L.Valor ,  
       L.Historico ,  
       L.NumeroLancamento ,  
       L.Credito FROM dbo.Lancamentos AS L  
       JOIN dbo.Bancos B ON B.idBanco = L.idBanco 
	   WHERE L.idBanco =1



CREATE NONCLUSTERED INDEX IxdDemoScanLancamentos ON dbo.Lancamentos(NumeroLancamento) INCLUDE(idBanco,idLancamento,Data,Valor,Credito)



SET STATISTICS IO ON 
SELECT L.idLancamento,
       L.idBanco,
       L.Historico,
       L.NumeroLancamento,
       L.Data,
       L.Valor,
       L.Credito FROM dbo.Lancamentos L
WHERE NumeroLancamento BETWEEN 1 AND 100 -- Scan count 5, logical reads 12346
SET STATISTICS IO OFF



--ALTER TABLE [dbo].[Lancamentos] ADD CONSTRAINT [PKLancamentos] PRIMARY KEY CLUSTERED ([idLancamento]) ON [PRIMARY];  


