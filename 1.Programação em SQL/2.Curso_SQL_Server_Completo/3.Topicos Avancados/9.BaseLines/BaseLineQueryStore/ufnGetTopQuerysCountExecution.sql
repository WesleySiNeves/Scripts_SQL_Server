



CREATE OR ALTER FUNCTION HealthCheck.ufnGetTopQuerysCountExecution(@TopCount SMALLINT)
RETURNS TABLE AS 
 RETURN 
SELECT q.query_id, qt.query_text_id, qt.query_sql_text,   
		AVG(rs.avg_duration) AS avg_duration,
    SUM(rs.count_executions) AS total_execution_count  
FROM sys.query_store_query_text AS qt   
JOIN sys.query_store_query AS q   
    ON qt.query_text_id = q.query_text_id   
JOIN sys.query_store_plan AS p   
    ON q.query_id = p.query_id   
JOIN sys.query_store_runtime_stats AS rs   
    ON p.plan_id = rs.plan_id  
	WHERE qt.query_sql_text NOT LIKE '%sys.%'
	
GROUP BY q.query_id, qt.query_text_id, qt.query_sql_text  
ORDER BY total_execution_count DESC,avg_duration DESC OFFSET 0 ROW FETCH NEXT 25 ROW ONLY;  