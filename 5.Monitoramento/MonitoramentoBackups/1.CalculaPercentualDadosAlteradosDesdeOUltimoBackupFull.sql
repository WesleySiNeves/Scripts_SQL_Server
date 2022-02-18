/* ==================================================================
--Data: 05/09/2018 
--Autor :Wesley Neves
--Observa��o: O sys.dm_db_file_space_usage � o DMV que retorna informa��es de uso de espa�o do banco de dados.
 
-- ==================================================================
*/


SELECT CAST(ROUND(
                     (SUM(dm_db_file_space_usage.modified_extent_page_count) * 100.0)
                     / SUM(dm_db_file_space_usage.allocated_extent_page_count),
                     2
                 ) AS DECIMAL(10, 2)) AS [Diff %]
FROM sys.dm_db_file_space_usage;