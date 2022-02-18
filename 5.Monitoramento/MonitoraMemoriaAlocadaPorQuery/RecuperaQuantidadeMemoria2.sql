SELECT dm_os_performance_counters.counter_name,
       dm_os_performance_counters.cntr_value,
       CAST((dm_os_performance_counters.cntr_value / 1024.0) / 1024.0 AS NUMERIC(8, 2)) AS Gb
  FROM sys.dm_os_performance_counters
 WHERE dm_os_performance_counters.counter_name LIKE '%Target server_memory%'
    OR dm_os_performance_counters.counter_name LIKE '%Total server_memory%';


	-- Memória consumida em tempo real por cada banco de dados --
SELECT  CASE database_id
          WHEN 32767 THEN 'ResourceDb'
          ELSE DB_NAME(database_id)
        END AS database_name ,
        COUNT(*) AS cached_pages_count ,
        COUNT(*) * .0078125 AS cached_megabytes /* Each page is 8kb, which is .0078125 of an MB */
FROM    sys.dm_os_buffer_descriptors
GROUP BY DB_NAME(database_id) ,
        database_id
ORDER BY cached_pages_count DESC ;