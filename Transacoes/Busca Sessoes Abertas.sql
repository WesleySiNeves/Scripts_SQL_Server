
BEGIN TRAN  t1

SELECT 1;

SELECT   DB_NAME(er.database_id),
		tat.transaction_id,
       tat.name,
       tat.transaction_begin_time,
       tat.transaction_type,
	   er.session_id,
       tat.transaction_state,
       tat.transaction_status,
       er.request_id,
       er.status,
       er.command,
       --er.sql_handle,
       --er.statement_start_offset,
       er.statement_end_offset,
       --er.plan_handle,
      
       er.user_id,
       er.blocking_session_id,
       er.wait_type,
       er.wait_time,
       er.last_wait_type,
       er.wait_resource,
       er.open_transaction_count,
       er.open_resultset_count,
       er.percent_complete,
       er.estimated_completion_time,
       er.cpu_time,
       er.total_elapsed_time,
       er.scheduler_id,
       er.reads,
       er.writes,
       er.logical_reads,
       er.text_size,
       er.language,
       er.date_format,
       er.date_first,
       er.quoted_identifier,
       er.arithabort,
       er.ansi_null_dflt_on,
       er.ansi_defaults,
       er.ansi_warnings,
       er.ansi_padding,
       er.ansi_nulls,
       er.concat_null_yields_null,
       er.transaction_isolation_level,
       er.lock_timeout,
       er.deadlock_priority,
       er.row_count,
       er.prev_error,
       er.nest_level,
       er.granted_query_memory,
       er.executing_managed_code,
       er.group_id,
       er.statement_sql_handle,
        [Query Completa] =text ,
	   Bat.text
    FROM sys.dm_tran_active_transactions tat 
        INNER JOIN sys.dm_exec_requests er ON tat.transaction_id = er.transaction_id
        CROSS APPLY sys.dm_exec_sql_text(er.sql_handle) Bat


COMMIT		