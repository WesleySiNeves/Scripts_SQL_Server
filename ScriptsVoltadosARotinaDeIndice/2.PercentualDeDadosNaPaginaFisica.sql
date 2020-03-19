DECLARE @BancoDados NVARCHAR(100) = 'Implanta';
DECLARE @Tabela NVARCHAR(100) = NULL; --'Log.Logs';

SET TRAN ISOLATION LEVEL READ UNCOMMITTED 

/*

CREATE FUNCTION dbo.index_name (@object_id int, @index_id int) 
RETURNS sysname 
AS 
BEGIN 
  RETURN(SELECT name FROM sys.indexes WHERE object_id = @object_id and index_id = @index_id) 
END; 
GO
*/

--DROP FUNCTION  dbo.index_name;


SELECT Phisical.index_type_desc,
       [Tabela] = OBJECT_NAME(Phisical.object_id),
       -- [Nome Indice] = dbo.index_name(Phisical.object_id,Phisical.index_id),
       [Total paginas do Indice] = FORMAT(Phisical.page_count, 'N', 'Pt-Br'),
       [Total de Linhas] = FORMAT(Phisical.record_count, 'N', 'Pt-Br'),
       [Porcentagem de dados na Pagina] = FORMAT(Phisical.avg_page_space_used_in_percent, 'N', 'Pt-Br'),
       Phisical.avg_fragmentation_in_percent [Porcentagem de Fragmentação da Pagina],
       Phisical.fragment_count [Total Paginas com Fragmentadas]
  FROM sys.dm_db_index_physical_stats(
           IIF(@BancoDados IS NULL, NULL, DB_ID(@BancoDados)),
           IIF(@Tabela IS NULL, NULL, OBJECT_ID(@Tabela)),
           NULL,
           NULL,
           'DETAILED') AS Phisical
 ORDER BY Phisical.index_type_desc,
          [Total paginas do Indice] DESC;


--  ALTER INDEX [PK_LogLogs] ON [Log].[Logs] REBUILD WITH(ONLINE =ON)

--ALTER INDEX IX_Logs_DATA ON [Log].[Logs] REBUILD WITH(ONLINE =ON)


