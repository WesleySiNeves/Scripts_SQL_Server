
/* ==================================================================
--Data: 03/09/2018 
--Autor :Wesley Neves
--Observação: https://docs.microsoft.com/pt-br/sql/relational-databases/system-dynamic-management-views/sys-dm-db-index-physical-stats-transact-sql?view=sql-server-2017
 
 para cada tabela retorna os indices e quanto de bytes estão alocados 
-- ==================================================================
*/
SELECT o.name,  
    ips.partition_number,  
    ips.index_type_desc,  
    ips.record_count, ips.avg_record_size_in_bytes,  
    ips.min_record_size_in_bytes,  
    ips.max_record_size_in_bytes,  
    ips.page_count, ips.compressed_page_count  
FROM sys.dm_db_index_physical_stats ( DB_ID(), NULL, NULL, NULL, 'DETAILED') ips  
JOIN sys.objects o on o.object_id = ips.object_id  
ORDER BY record_count DESC;  