WITH Query_MultPlans
  AS (SELECT TOP 100 COUNT(*) AS cnt,
             q.query_id
        FROM sys.query_store_query_text AS qt
        JOIN sys.query_store_query AS q
          ON qt.query_text_id = q.query_text_id
        JOIN sys.query_store_plan AS p
          ON p.query_id       = q.query_id
       GROUP BY q.query_id
      HAVING COUNT(DISTINCT p.plan_id) > 1)
SELECT q.query_id,
       OBJECT_NAME(q.object_id) AS ContainingObject,
       qt.query_sql_text,
       p.plan_id,
       p.query_plan AS plan_xml,
	   p.is_parallel_plan,
       p.last_compile_start_time,
       p.last_execution_time
  FROM Query_MultPlans AS qm
  JOIN sys.query_store_query AS q
    ON qm.query_id      = q.query_id
  JOIN sys.query_store_plan AS p
    ON q.query_id       = p.query_id
  JOIN sys.query_store_query_text qt
    ON qt.query_text_id = q.query_text_id
	WHERE q.query_id ='1256'
 ORDER BY query_id,
          p.plan_id;

SELECT * FROM  sys.query_store_plan AS QSP WHERE QSP.plan_id =271

