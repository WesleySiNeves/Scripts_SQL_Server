

-- ==================================================================
--Observa��o: Columnstore indexes - defragmentation
-- ==================================================================

-- Use ALTER INDEX REORGANIZE

/*
para desfragmentar um �ndice de armazenamento de colunas on-line
*/

/*
Depois de executar cargas de qualquer tipo, voc� pode ter v�rios pequenos grupos de filas no deltastore.
 Voc� pode usar ALTER INDEX REORGANIZEpara for�ar todos os grupos de filas na barra de colunas e, em seguida, para combinar os grupos de filas em menos grupos de filas com mais linhas. A opera��o de reorganiza��o
 tamb�m remover� as linhas que foram exclu�das da loja de colunas.
*/

/*
Use o exemplo em sys.dm_db_column_store_row_group_physical_stats (Transact-SQL)
 para calcular a fragmenta��o.
 Isso ajuda voc� a determinar se vale a pena executar uma opera��o REORGANIZE.
*/


-- ==================================================================
--Observa��o: Inicio da Demo
-- ==================================================================



USE master;
GO

IF EXISTS (   SELECT databases.name
                FROM sys.databases
               WHERE databases.name = N'[columnstore]')
    DROP DATABASE [columnstore];
GO

CREATE DATABASE [columnstore];
GO

USE [columnstore];


IF EXISTS (   SELECT tables.name
                FROM sys.tables
               WHERE tables.name      = N'staging'
                 AND tables.object_id = OBJECT_ID(N'staging'))
    DROP TABLE dbo.staging;
GO


CREATE TABLE [staging] (
    AccountKey INT NOT NULL,
    AccountDescription NVARCHAR(50),
    AccountType NVARCHAR(50),
    AccountCodeAlternateKey INT);
GO

-- Load data  
DECLARE @loop INT;
DECLARE @AccountDescription VARCHAR(50);
DECLARE @AccountKey INT;
DECLARE @AccountType VARCHAR(50);
DECLARE @AccountCode INT;

SELECT @loop = 0;
BEGIN TRAN;
WHILE (@loop < 300000)
BEGIN
    SELECT @AccountKey = CAST(RAND() * 10000000 AS INT);
    SELECT @AccountDescription = 'accountdesc ' + CONVERT(VARCHAR(20), @AccountKey);
    SELECT @AccountType = 'AccountType ' + CONVERT(VARCHAR(20), @AccountKey);
    SELECT @AccountCode = CAST(RAND() * 10000000 AS INT);

    INSERT INTO staging
    VALUES (@AccountKey, @AccountDescription, @AccountType, @AccountCode);

    SELECT @loop = @loop + 1;
END;
COMMIT;


-- ==================================================================
--Observa��o: Parte 2
/*
Crie uma tabela armazenada como um �ndice de armazenamento de colunas.
 */
-- ==================================================================

IF EXISTS (   SELECT tables.name
                FROM sys.tables
               WHERE tables.name      = N'cci_target'
                 AND tables.object_id = OBJECT_ID(N'cci_target'))
    DROP TABLE dbo.cci_target;
GO

-- Create a table with a clustered columnstore index  
-- and the same columns as the rowstore staging table.  
CREATE TABLE cci_target (
    AccountKey INT NOT NULL,
    AccountDescription NVARCHAR(50),
    AccountType NVARCHAR(50),
    AccountCodeAlternateKey INT,
    INDEX idx_cci_target CLUSTERED COLUMNSTORE);
GO

/*
Bulk insira as linhas da tabela de teste na tabela de armazenamento de colunas. INSERT INTO ... SELECTexecuta uma inser��o em massa.
 O que TABLOCKpermite INSERT executar com paralelismo.
*/


--TRUNCATE TABLE cci_target
INSERT INTO cci_target WITH (TABLOCK)
SELECT TOP (300000) *
  FROM staging  AS S;
GO



-- ==================================================================
--Observa��o: Visualize os grupos de filas usando a exibi��o de gerenciamento din�mico 
--sys.dm_db_column_store_row_group_physical_stats (DMV).
-- ==================================================================

SELECT *   
FROM sys.dm_db_column_store_row_group_physical_stats   
WHERE object_id  = object_id('cci_target')  
ORDER BY row_group_id;  



/*
Use ALTER INDEX REORGANIZEcom a COMPRESS_ALL_ROW_GROUPS op��o para for�ar todos os grupos
 de filas a serem compactados na barra de colunas.
*/


-- This command will force all CLOSED and OPEN rowgroups into the columnstore.  
ALTER INDEX idx_cci_target ON cci_target   
REORGANIZE WITH (COMPRESS_ALL_ROW_GROUPS = ON);  


SELECT *   
FROM sys.dm_db_column_store_row_group_physical_stats   
WHERE object_id  = object_id('cci_target')  
ORDER BY row_group_id;  


/*
Para o desempenho da consulta, � muito melhor combinar pequenos grupos 
de filas em conjunto. ALTER INDEX REORGANIZEir� combinar COMPRESSED grupos de 
filas em conjunto. Agora que os grupos de fila delta s�o compactados na loja de colunas, execute ALTER INDEX REORGANIZE novamente para combinar os pequenos grupos de filas COMPRIMIDOS
. Desta vez, voc� n�o precisa da COMPRESS_ALL_ROW_GROUPSop��o.
*/


-- Run this again and you will see that smaller rowgroups   
-- combined into one compressed rowgroup with 300,000 rows  
ALTER INDEX idx_cci_target ON cci_target REORGANIZE;  

SELECT *   
FROM sys.dm_db_column_store_row_group_physical_stats   
WHERE object_id  = object_id('cci_target')  
ORDER BY row_group_id; 


/*
Use ALTER INDEX REBUILD para desfragmentar o �ndice columnstore offline
Reconstruir um �ndice de armazenamento de colunas remove a fragmenta��o e move todas
 as linhas para a loja de colunas. Use CREATE COLUMNSTORE INDEX (Transact-SQL)
  ou ALTER INDEX (Transact-SQL) para executar uma reconstru��o completa de um �ndice 
  de armazenamento de colunas em cluster existente. Al�m disso, voc� pode usar ALTER INDEX ... REBUILD para reconstruir uma parti��o espec�fica.
*/

/*
Processo de reconstru��o
Para reconstruir um �ndice de armazenamento de colunas, o SQL Server:

Adquira um bloqueio exclusivo na mesa ou parti��o enquanto ocorre a reconstru��o.
 Os dados est�o "offline" e n�o est�o dispon�veis durante a reconstru��o, 
 mesmo quando se usa NOLOCK, RCSI ou SI.

Re-comprime todos os dados na barra de colunas. Existem duas c�pias do �ndice columnstore 
enquanto a reconstru��o est� ocorrendo. Quando a reconstru��o estiver conclu�da, 
o SQL Server exclui o �ndice original de armazenamento de colunas.
*/