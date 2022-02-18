SELECT DTDT.database_id,
       DTDT.transaction_id,
       '--',
       tran_session.*,
       request.*
FROM sys.dm_tran_database_transactions AS DTDT
     JOIN
     sys.dm_tran_active_transactions AS tran_active ON tran_active.transaction_id = DTDT.transaction_id
     JOIN
     sys.dm_tran_session_transactions AS tran_session ON tran_session.transaction_id = tran_active.transaction_id
     JOIN
     sys.dm_exec_requests AS request ON request.database_id = DTDT.database_id
                                        AND request.session_id = tran_session.session_id;
