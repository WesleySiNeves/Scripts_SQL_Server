

CREATE OR ALTER FUNCTION ScanInCacheFromDatabase 
		(     
		      -- Add the parameters for the function here
		      @DatabaseName varchar(50)
		)
		RETURNS TABLE 
		AS
		RETURN 
		(
		with XMLNAMESPACES
		(default 'http://schemas.microsoft.com/sqlserver/2004/07/showplan')
		select qp.query_plan,qt.text, 
		statement_start_offset, statement_end_offset,
		creation_time, last_execution_time,
		execution_count, total_worker_time,
		last_worker_time, min_worker_time,
		max_worker_time, total_physical_reads,
		last_physical_reads, min_physical_reads,
		max_physical_reads, total_logical_writes,
		last_logical_writes, min_logical_writes,
		max_logical_writes, total_logical_reads,
		last_logical_reads, min_logical_reads,
		max_logical_reads, total_elapsed_time,
		last_elapsed_time, min_elapsed_time,
		max_elapsed_time, total_rows,
		last_rows, min_rows,
		max_rows from sys.dm_exec_query_stats
		CROSS APPLY sys.dm_exec_sql_text(sql_handle) qt
		CROSS APPLY sys.dm_exec_query_plan(plan_handle) qp
		where 
		qp.query_plan.exist('//RelOp[@LogicalOp="Index Scan"
		            or @LogicalOp="Clustered Index Scan"
		            or @LogicalOp="Table Scan"]')=1
		and 
		qp.query_plan.exist('//ColumnReference[fn:lower-case(@Database)=fn:lower-case(sql:variable("@DatabaseName"))]')=1
		)
		GO

		--SELECT TOP 10 * FROM ScanInCacheFromDatabase('Implanta')