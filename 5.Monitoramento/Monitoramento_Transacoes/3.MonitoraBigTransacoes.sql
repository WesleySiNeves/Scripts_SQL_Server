SET NOCOUNT ON;
GO
DECLARE @datetime DATETIME;
SELECT @datetime = GETDATE();
SELECT @datetime logtime,
       dm_exec_sql_text.text,
       tr.database_id,
       tr.transaction_id,
       tr.database_transaction_log_bytes_used,
       tr.database_transaction_log_bytes_reserved,
       tr.database_transaction_log_record_count,
       tr.database_transaction_state,
       tr.database_transaction_status,
       tr.database_transaction_log_bytes_used_system,
       tr.database_transaction_log_bytes_reserved_system
FROM sys.dm_tran_database_transactions tr
     INNER JOIN
     sys.dm_exec_requests r ON tr.transaction_id = r.transaction_id
     CROSS APPLY sys.dm_exec_sql_text(r.sql_handle)
WHERE tr.database_transaction_log_bytes_used > 100 * 1024 * 1024; -- 100 MB