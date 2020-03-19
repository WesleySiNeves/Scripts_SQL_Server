-- Top 15 CPU consuming queries by query hash
-- note that a query  hash can have many query id if not parameterized or not parameterized properly
-- it grabs a sample query text by min

CREATE OR ALTER FUNCTION HealthCheck.ufnGetTopQuerysConsumeCPU(@TopCount SMALLINT)
RETURNS TABLE AS 
 RETURN 
WITH AggregatedCPU
  AS (SELECT q.query_hash,
             SUM(rs.count_executions * rs.avg_cpu_time / 1000000.0) AS total_cpu_Sec,
             SUM(rs.count_executions * rs.avg_cpu_time / 1000000.0) / SUM(rs.count_executions) AS avg_cpu_Sec,
             MAX(rs.max_cpu_time / 1000000.00) AS max_cpu_Sec,
             MAX(rs.max_logical_io_reads) max_logical_reads,
             COUNT(DISTINCT p.plan_id) AS number_of_distinct_plans,
             COUNT(DISTINCT p.query_id) AS number_of_distinct_query_ids,
             SUM( rs.count_executions) AS Regular_Execution_Count,
             SUM(rs.count_executions) AS total_executions,
             MIN(qt.query_sql_text) AS sampled_query_text
        FROM sys.query_store_query_text AS qt
        JOIN sys.query_store_query AS q
          ON qt.query_text_id              = q.query_text_id
        JOIN sys.query_store_plan AS p
          ON q.query_id                    = p.query_id
        JOIN sys.query_store_runtime_stats AS rs
          ON rs.plan_id                    = p.plan_id
        JOIN sys.query_store_runtime_stats_interval AS rsi
          ON rsi.runtime_stats_interval_id = rs.runtime_stats_interval_id
       WHERE rs.execution_type_desc  = 'Regular'
	   AND qt.query_sql_text NOT LIKE '%sys.%'
         AND rsi.start_time >= DATEADD(HOUR, -2, GETUTCDATE())
       GROUP BY q.query_hash),
     OrderedCPU
  AS (SELECT AggregatedCPU.query_hash,
             AggregatedCPU.total_cpu_Sec,
             AggregatedCPU.avg_cpu_Sec,
             AggregatedCPU.max_cpu_Sec,
             AggregatedCPU.max_logical_reads,
             AggregatedCPU.number_of_distinct_plans,
             AggregatedCPU.number_of_distinct_query_ids,
             AggregatedCPU.total_executions,
             AggregatedCPU.Regular_Execution_Count,
             AggregatedCPU.sampled_query_text,
             ROW_NUMBER() OVER (ORDER BY AggregatedCPU.total_cpu_Sec DESC,
                                         AggregatedCPU.query_hash ASC) AS RN
        FROM AggregatedCPU)
SELECT OD.query_hash,
       OD.total_cpu_Sec,
       OD.avg_cpu_Sec,
       OD.max_cpu_Sec,
       OD.max_logical_reads,
       OD.number_of_distinct_plans,
       OD.number_of_distinct_query_ids,
       OD.total_executions,
       OD.Regular_Execution_Count,
       OD.sampled_query_text,
       OD.RN
  FROM OrderedCPU AS OD
 ORDER BY OD.total_cpu_Sec DESC OFFSET 0 ROWS FETCH FIRST @TopCount ROWS ONLY; 
 


 GO
 
 