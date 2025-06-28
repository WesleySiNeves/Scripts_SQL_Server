/* ==================================================================
--Data: 24/09/2018 
--Autor :Wesley Neves
--Observa��o: Compressao de dados
https://docs.microsoft.com/pt-br/sql/relational-databases/data-compression/enable-compression-on-a-table-or-index?view=sql-server-2017
https://docs.microsoft.com/pt-br/sql/relational-databases/data-compression/data-compression?view=sql-server-2017
 
-- ==================================================================
*/


SELECT * FROM Log.LogsDetalhes AS LD 

DBCC SHOWCONTIG('Log.LogsDetalhes')WITH TABLERESULTS;

SELECT 'Tamanho Estimado da tabela', CONCAT(406.632,' MB')

EXEC sys.sp_estimate_data_compression_savings @schema_name = 'Log',    -- sysname
                                              @object_name = 'LogsDetalhes',    -- sysname
                                              @index_id = 1,          -- int
                                              @partition_number = '1',  -- int
                                              @data_compression = N'PAGE' -- nvarchar(60)


EXEC sys.sp_estimate_data_compression_savings @schema_name = 'Log',    -- sysname
                                              @object_name = 'LogsDetalhes',    -- sysname
                                              @index_id = 1,          -- int
                                              @partition_number = '1',  -- int
                                              @data_compression = N'ROW' -- nvarchar(60)


USE master



CREATE DATABASE DemoDataDataBaseCompression

USE DemoDataDataBaseCompression

/* ==================================================================
--Data: 24/09/2018 
--Autor :Wesley Neves
--Observa��o: Vamos Criar uma tabela com esse exemplo
 
 CREATE TABLE [Movimentos]
(
[IdMovimento] [uniqueidentifier] NOT NULL ROWGUIDCOL CONSTRAINT [DEF_ContabilidadeMovimentosIdMovimento] DEFAULT (newsequentialid()),
[IdLancamento] [uniqueidentifier] NOT NULL,
[IdPlanoConta] [uniqueidentifier] NOT NULL,
[Credito] [bit] NOT NULL CONSTRAINT [DEF_ContabilidadeMovimentosCredito] DEFAULT ((0)),
[NumeroProcesso] [varchar] (20) COLLATE Latin1_General_CI_AI NULL,
[NumeroDocumento] [int] NULL,
[Valor] [numeric] (18, 2) NOT NULL CONSTRAINT [DEF_ContabilidadeMovimentosValor] DEFAULT ((0)),
[Historico] [varchar] (max) COLLATE Latin1_General_CI_AI NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY] WITH(DATA_COMPRESSION =PAGE)
GO
-- ==================================================================
*/



INSERT INTO dbo.Movimentos (
                           IdMovimento,
                           IdLancamento,
                           IdPlanoConta,
                           Credito,
                           NumeroProcesso,
                           NumeroDocumento,
                           Valor,
                           Historico
                           )
SELECT M.* FROM Implanta.Contabilidade.Movimentos AS M
JOIN Implanta.Contabilidade.Lancamentos AS L ON M.IdLancamento = L.IdLancamento
WHERE L.Exercicio = 2018


USE Implanta
ALTER TABLE Log.Logs REBUILD PARTITION = ALL  
WITH (DATA_COMPRESSION = ROW);   
GO  



/* ==================================================================
--Data: 24/09/2018 
--Autor :Wesley Neves
--Observa��o:  Esse exemplo aqui faz a compacta��o de dados de um indice
 
-- ==================================================================
*/


USE AdventureWorks2012;
GO  
SELECT name, index_id  
FROM sys.indexes  
WHERE OBJECT_NAME (object_id) = N'TransactionHistory';  

EXEC sp_estimate_data_compression_savings   
    @schema_name = 'Production',   
    @object_name = 'TransactionHistory',  
    @index_id = 2,   
    @partition_number = NULL,   
    @data_compression = 'PAGE' ;   

ALTER INDEX IX_TransactionHistory_ProductID
    ON Production.TransactionHistory
    REBUILD PARTITION = ALL
    WITH (DATA_COMPRESSION = PAGE);
GO

/* ==================================================================
--Data: 25/09/2018 
--Autor :Wesley Neves
--Observa��o: Criando uma tabela com comprens�o de pagina
 
-- ==================================================================
*/

CREATE TABLE [Log].[Logs]
(
[IdLog] [uniqueidentifier] NOT NULL ROWGUIDCOL,
[IdPessoa] [uniqueidentifier] NOT NULL,
[IdEntidade] [uniqueidentifier] NOT NULL,
[Entidade] [varchar] (100) COLLATE Latin1_General_CI_AI NOT NULL,
[Acao] [varchar] (10) COLLATE Latin1_General_CI_AI NOT NULL,
[Data] [datetime] NOT NULL,
[CodSistema] [uniqueidentifier] NOT NULL,
[IPAdress] [varchar] (30) COLLATE Latin1_General_CI_AI NULL
) ON [PRIMARY] WITH(DATA_COMPRESSION =PAGE)


/* ==================================================================
--Data: 25/09/2018 
--Autor :Wesley Neves
--Observa��o: Criando uma tabela com comprens�o de de Row
 
-- ==================================================================
*/

CREATE TABLE [Log].[Logs]
(
[IdLog] [uniqueidentifier] NOT NULL ROWGUIDCOL,
[IdPessoa] [uniqueidentifier] NOT NULL,
[IdEntidade] [uniqueidentifier] NOT NULL,
[Entidade] [varchar] (100) COLLATE Latin1_General_CI_AI NOT NULL,
[Acao] [varchar] (10) COLLATE Latin1_General_CI_AI NOT NULL,
[Data] [datetime] NOT NULL,
[CodSistema] [uniqueidentifier] NOT NULL,
[IPAdress] [varchar] (30) COLLATE Latin1_General_CI_AI NULL
) ON [PRIMARY] WITH(DATA_COMPRESSION =ROW)