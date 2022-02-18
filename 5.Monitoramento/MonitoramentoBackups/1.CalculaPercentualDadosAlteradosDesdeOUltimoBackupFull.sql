/* ==================================================================
--Data: 05/09/2018 
--Autor :Wesley Neves
--Observação: O sys.dm_db_file_space_usage é o DMV que retorna informações de uso de espaço do banco de dados.
 
-- ==================================================================
*/


SELECT CAST(ROUND(
                     (SUM(dm_db_file_space_usage.modified_extent_page_count) * 100.0)
                     / SUM(dm_db_file_space_usage.allocated_extent_page_count),
                     2
                 ) AS DECIMAL(10, 2)) AS [Diff %]
FROM sys.dm_db_file_space_usage;