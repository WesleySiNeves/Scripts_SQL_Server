SELECT TOP 
	20
	p.last_execution_time,
	 qt.query_sql_text,
		OBJECT_NAME(q.object_id),
       q.query_id,
       qt.query_text_id,
       p.plan_id,
	    rs.avg_duration
  FROM sys.query_store_query_text AS qt
  JOIN sys.query_store_query AS q
    ON qt.query_text_id = q.query_text_id
  JOIN sys.query_store_plan AS p
    ON q.query_id       = p.query_id
  JOIN sys.query_store_runtime_stats AS rs
    ON p.plan_id        = rs.plan_id
	WHERE qt.query_sql_text NOT LIKE '%sys.%'
	 AND qt.query_sql_text NOT LIKE '%sys.%'
		 AND qt.query_sql_text NOT LIKE '%[[HangFire]]%'
 ORDER BY rs.last_execution_time 