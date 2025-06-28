/*########################
# OBS: Use dynamic management objects to review current index usage and identify
missing indexes
*/

/*########################
# OBS: O SQL Server usa �ndices para acelerar o acesso a dados.
 No Cap�tulo 1, cobrimos muitos dos considera��es que afetam o
 projeto de tabelas. Com o tempo, voc� pode descobrir que alguns �ndices
n�o s�o t�o �teis quanto o esperado devido a altera��es na distribui��o dos 
dados ou na consulta Padr�es Al�m disso, a exist�ncia de um �ndice que o SQL 
Server nunca usa adiciona sobrecarga para gravar opera��es.
*/

/*########################
# OBS: revis�o para DMOs que traz informa��o de indices
*/

/*########################
# OBS: Query de indices usados
*/

USE Lancamentos;

DECLARE @NomeBanco VARCHAR(128) = 'Lancamentos';

SELECT Banco = DB_NAME(database_id),
       Tabela = OBJECT_NAME(object_id, database_id),
       index_id,
       user_seeks,
       user_scans,
       user_lookups,
       user_updates,
       last_user_seek,
       last_user_scan,
       last_user_lookup,
       last_user_update
FROM sys.dm_db_index_usage_stats
WHERE database_id = DB_ID(@NomeBanco)
ORDER BY user_scans;




SELECT DDIPS.database_id,
       DDIPS.object_id,
       DDIPS.index_id,
       DDIPS.partition_number,
       DDIPS.index_type_desc,
       DDIPS.alloc_unit_type_desc,
       DDIPS.avg_fragmentation_in_percent,
       DDIPS.fragment_count,
       DDIPS.avg_fragment_size_in_pages,
       DDIPS.page_count,
       DDIPS.hobt_id
FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, NULL) AS DDIPS;



SELECT OBJECT_NAME(ixu.object_id, DB_ID('WideWorldImporters')) AS [object_name],
       ix.[name] AS index_name,
       ixu.user_seeks + ixu.user_scans + ixu.user_lookups AS user_reads,
       ixu.user_updates AS user_writes
FROM sys.dm_db_index_usage_stats ixu
    INNER JOIN WideWorldImporters.sys.indexes ix
        ON ixu.[object_id] = ix.[object_id]
           AND ixu.index_id = ix.index_id
WHERE ixu.database_id = DB_ID('WideWorldImporters')
ORDER BY user_reads DESC;




/*########################
# OBS: Quando o otimizador de consulta compila uma instru��o T-SQL, ele tamb�m rastreia at� 500 �ndices que
poderia ter sido usado se eles tivessem existido. Os seguintes DMVs ajudam voc� a rever estes
�ndices ausentes
*/


/*########################
# OBS: sys.dm_db_missing_index_details Use this DMV to identify the columns used for
equality and inequality predicates.
*/

SELECT * FROM sys.dm_db_missing_index_details AS DDMID


/*########################
# OBS: sys.dm_db_missing_index_groups Use este DMV como um intermedi�rio entre
sys.dm_db_index_details e sys.dm_db_missing_group_stats

*/
SELECT * FROM sys.dm_db_missing_index_groups AS DDMIG


/*########################
# OBS: sys.dm_db_missing_index_group_stats Use este DMV para recuperar m�tricas em um
grupo de �ndices ausentes
*/
SELECT * FROM sys.dm_db_missing_index_group_stats 


/*########################
# OBS: Review missing indexes
*/


SELECT (user_seeks + user_scans) * avg_total_user_cost * (avg_user_impact * 0.01) AS IndexImprovement,
       id.statement,
       id.equality_columns,
       id.inequality_columns,
       id.included_columns
FROM sys.dm_db_missing_index_group_stats AS igs
    INNER JOIN sys.dm_db_missing_index_groups AS ig
        ON igs.group_handle = ig.index_group_handle
    INNER JOIN sys.dm_db_missing_index_details AS id
        ON ig.index_handle = id.index_handle
ORDER BY IndexImprovement DESC;




