
/* ==================================================================
--Data: 08/11/2018 
--Autor :Wesley Neves
--Observação: https://www.red-gate.com/simple-talk/sql/t-sql-programming/checking-the-plan-cache-warnings-for-a-sql-server-database/
 
-- ==================================================================
*/

;WITH XMLNAMESPACES (DEFAULT N'http://schemas.microsoft.com/sqlserver/2004/07/showplan')
SELECT cp.query_hash,
       cp.query_plan_hash,
       ConvertIssue = operators.value('@ConvertIssue', 'nvarchar(250)'),
       Expression = operators.value('@Expression', 'nvarchar(250)'),
	   DEST.text,
       qp.query_plan
  FROM sys.dm_exec_query_stats cp
  CROSS APPLY sys.dm_exec_sql_text(cp.sql_handle) AS DEST
 CROSS APPLY sys.dm_exec_query_plan(cp.plan_handle) qp
 CROSS APPLY query_plan.nodes('//Warnings/PlanAffectingConvert') rel(operators)
 WHERE DEST.text NOT LIKE '%sys%'
   
 

 