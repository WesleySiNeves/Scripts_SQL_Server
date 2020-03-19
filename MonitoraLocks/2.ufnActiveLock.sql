

CREATE FUNCTION Active_locks ()
RETURNS TABLE RETURN
SELECT TOP 10000000 CASE dtl.request_session_id WHEN-2 THEN 'orphaned distributed transaction'
                    WHEN-3 THEN 'deferred recovery transaction' ELSE dtl.request_session_id END AS spid,
       DB_NAME(dtl.resource_database_id) AS databasename,
       so.name AS lockedobjectname,
       dtl.resource_type AS lockedresource,
       dtl.request_mode AS locktype,
       es.login_name AS loginname,
       es.host_name AS hostname,
       CASE tst.is_user_transaction WHEN 0 THEN 'system transaction'
       WHEN 1 THEN 'user transaction' END AS user_or_system_transaction,
       at.name AS transactionname,
       dtl.request_status
  FROM sys.dm_tran_locks dtl
       JOIN sys.partitions sp ON sp.hobt_id = dtl.resource_associated_entity_id
       JOIN sys.objects so ON so.object_id = sp.object_id
       JOIN sys.dm_exec_sessions es ON es.session_id = dtl.request_session_id
       JOIN sys.dm_tran_session_transactions tst ON es.session_id = tst.session_id
       JOIN sys.dm_tran_active_transactions at ON tst.transaction_id = at.transaction_id
       JOIN sys.dm_exec_connections ec ON ec.session_id = es.session_id
       CROSS APPLY sys.dm_exec_sql_text(ec.most_recent_sql_handle) AS st
 WHERE
    dtl.resource_database_id = DB_ID()
 ORDER BY
    dtl.request_session_id;



