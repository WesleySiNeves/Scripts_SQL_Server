

--SELECT * FROM HealthCheck.ufnGetTopQuerys(30,'TimeElepsed')
CREATE OR ALTER FUNCTION HealthCheck.ufnGetTopQuerys(@TopCount SMALLINT, @order VARCHAR(10) ='TimeElepsed')
RETURNS TABLE AS 
 RETURN 

--DECLARE @TopCount SMALLINT,@order VARCHAR(30) ='TimeElepsed';

WITH AggregatedDurationLastHour
  AS (SELECT q.query_id,
             SUM(rs.count_executions * rs.avg_duration) AS total_duration,
             SUM(rs.count_executions * rs.avg_cpu_time) AS total_cpu_time,
             SUM(rs.count_executions * rs.avg_logical_io_reads) AS total_logical_io_reads,
             SUM(rs.count_executions * rs.avg_logical_io_writes) AS total_logical_io_writes,
             SUM(rs.count_executions * rs.avg_log_bytes_used) AS total_log_bytes_used,
             SUM(rs.count_executions * rs.avg_tempdb_space_used) AS total_tempdb_space_used,
             SUM(rs.count_executions * rs.avg_query_max_used_memory) AS total_used_memory,
             COUNT(DISTINCT p.plan_id) AS number_of_plans
        FROM sys.query_store_query_text AS qt
        JOIN sys.query_store_query AS q
          ON qt.query_text_id              = q.query_text_id
        JOIN sys.query_store_plan AS p
          ON q.query_id                    = p.query_id
        JOIN sys.query_store_runtime_stats AS rs
          ON rs.plan_id                    = p.plan_id
        JOIN sys.query_store_runtime_stats_interval AS rsi
          ON rsi.runtime_stats_interval_id = rs.runtime_stats_interval_id
       WHERE rsi.start_time   >= CAST(GETDATE() AS DATE)      
         AND rs.execution_type_desc = 'Regular'
         AND qt.query_sql_text NOT LIKE '%sys.%'
		 AND qt.query_sql_text NOT LIKE '%[[sys]].%'
		 AND qt.query_sql_text NOT LIKE '%[[HangFire]]%'
		 
       GROUP BY q.query_id),
     OrderedDuration
  AS (SELECT AggregatedDurationLastHour.query_id,
             AggregatedDurationLastHour.total_duration,
             AggregatedDurationLastHour.total_cpu_time,
             AggregatedDurationLastHour.total_logical_io_reads,
             AggregatedDurationLastHour.total_logical_io_writes,
             AggregatedDurationLastHour.total_log_bytes_used,
             AggregatedDurationLastHour.total_tempdb_space_used,
             AggregatedDurationLastHour.total_used_memory,
             AggregatedDurationLastHour.number_of_plans,
             ROW_NUMBER() OVER (ORDER BY AggregatedDurationLastHour.total_duration DESC,
                                         AggregatedDurationLastHour.query_id) AS RN
        FROM AggregatedDurationLastHour),
		Result AS (
		SELECT qt.query_text_id,
		od.query_id,
       qt.query_sql_text,
       OBJECT_NAME(q.object_id) AS containing_object,
       (od.total_duration) / 1000000 AS [Time Elepsed em Seg],
       (od.total_cpu_time) / 1000000 AS [Cpu Time em Seg],
       CAST(((od.total_logical_io_reads * 8) / 1024.0) AS DECIMAL(18, 4)) AS [logical_io_reads MB],
       CAST(((od.total_logical_io_writes * 8) / 1024.0) AS DECIMAL(18, 4)) AS [logical_io_writes MB],
       CAST(((od.total_log_bytes_used * 8) / 12014.0) AS DECIMAL(18, 4)) AS [log used MB],
       CAST(((od.total_tempdb_space_used * 8) / 12014.0) AS DECIMAL(18, 4)) AS [tempdb_space_used MB],
       CAST(((od.total_used_memory * 8) / 12014.0) AS DECIMAL(18, 4)) AS [total_used_memory MB],
       od.number_of_plans,
       --  CONVERT(XML, p.query_plan) AS query_plan_xml,
       p.is_forced_plan
  FROM OrderedDuration od
  JOIN sys.query_store_query AS q
    ON q.query_id      = od.query_id
  JOIN sys.query_store_query_text qt
    ON q.query_text_id = qt.query_text_id
  JOIN sys.query_store_plan p
    ON q.query_id      = p.query_id
		)
		SELECT R.query_text_id,
               R.query_id,
               R.query_sql_text,
               R.containing_object,
               R.[Time Elepsed em Seg],
               R.[Cpu Time em Seg],
               R.[logical_io_reads MB],
               R.[logical_io_writes MB],
               R.[log used MB],
               R.[tempdb_space_used MB],
               R.[total_used_memory MB],
               R.number_of_plans,
               R.is_forced_plan FROM Result R
 ORDER BY 
 CASE WHEN @order ='TimeElepsed' THEN R.[Time Elepsed em Seg] END DESC,
 CASE WHEN @order ='CpuTime' THEN R.[Cpu Time em Seg] END DESC,
 CASE WHEN @order ='LogicalIoReads' THEN R.[logical_io_reads MB]   END  DESC,
 CASE WHEN @order ='LogicalIoWrites' THEN R.[logical_io_writes MB]   END  DESC,
 CASE WHEN @order ='LogUsed' THEN R.[log used MB]   END  DESC,
 CASE WHEN @order ='UsedMemory' THEN R.[total_used_memory MB]   END  DESC OFFSET 0 ROW FETCH NEXT 30 ROW ONLY
  
 
  