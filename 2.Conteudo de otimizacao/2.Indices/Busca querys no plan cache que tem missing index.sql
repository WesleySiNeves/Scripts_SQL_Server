
;WITH XMLNAMESPACES(DEFAULT N'http://schemas.microsoft.com/sqlserver/2004/07/showplan')       
SELECT dec.usecounts, dec.refcounts, dec.objtype
      ,dec.cacheobjtype, des.dbid, des.text      
      ,deq.query_plan 
FROM sys.dm_exec_cached_plans AS dec 
     CROSS APPLY sys.dm_exec_sql_text(dec.plan_handle) AS des 
     CROSS APPLY sys.dm_exec_query_plan(dec.plan_handle) AS deq 
WHERE deq.query_plan.exist(N'/ShowPlanXML/BatchSequence/Batch/Statements/StmtSimple/QueryPlan/MissingIndexes/MissingIndexGroup') <> 0 
ORDER BY dec.usecounts DESC 