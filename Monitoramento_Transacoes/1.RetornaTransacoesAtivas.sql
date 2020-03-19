


SET TRAN ISOLATION LEVEL READ UNCOMMITTED;

WITH ResultSet
  AS (
     SELECT [Database] = COALESCE(DB_NAME(DTDT.database_id), DB_NAME()),
            [Usuario] = DES.login_name,
            [Maquina Conectada] = DES.host_name,
            [Sessão] = DES.session_id,
            [transaction_id] = DTDT.transaction_id,
            [Nivel Isolamento] = CASE
                                     WHEN DES.transaction_isolation_level = 0 THEN
                                         'Não Especificado'
                                     WHEN DES.transaction_isolation_level = 1 THEN
                                         'READ UNCOMMITTED'
                                     WHEN DES.transaction_isolation_level = 2 THEN
                                         'READ COMMITTED'
                                     WHEN DES.transaction_isolation_level = 3 THEN
                                         'REPEATABLE READ'
                                     WHEN DES.transaction_isolation_level = 4 THEN
                                         'SERIALIZABLE'
                                     WHEN DES.transaction_isolation_level = 5 THEN
                                         'SNAPSHOT'
                                 END,
            [Tempo da transação aberta] = CONVERT(
                                                     TIME,
                                                     DATEADD(
                                                                ms,
                                                                DATEDIFF(
                                                                            MILLISECOND,
                                                                            DTDT.database_transaction_begin_time,
                                                                            CURRENT_TIMESTAMP
                                                                        ),
                                                                0
                                                            )
                                                 ),
            [lock_timeout config session] = DES.lock_timeout,
            [time  last query] = CONVERT(
                                            TIME,
                                            DATEADD(
                                                       ms,
                                                       DATEDIFF(
                                                                   MILLISECOND,
                                                                   DES.last_request_start_time,
                                                                   DES.last_request_end_time
                                                               ),
                                                       0
                                                   )
                                        ),
            s_est.text AS [Last T-SQL Text],
            [Tamanho Pacote] = DEC.net_packet_size,
            [Transaction_type] = CASE
                                     WHEN DTDT.database_transaction_type = 1 THEN
                                         'Transação de leitura/gravação'
                                     WHEN DTDT.database_transaction_type = 2 THEN
                                         'Transação somente leitura'
                                     WHEN DTDT.database_transaction_type = 3 THEN
                                         'Transação de sistema'
                                 END,
            [Transaction_state] = CASE
                                      WHEN DTDT.database_transaction_state = 1 THEN
                                          'A transação não foi inicializada'
                                      WHEN DTDT.database_transaction_state = 3 THEN
                                          'A transação foi inicializada mas não gerou registros de log'
                                      WHEN DTDT.database_transaction_state = 4 THEN
                                          'A transação gerou registros de log.'
                                      WHEN DTDT.database_transaction_state = 5 THEN
                                          'A transação foi preparada'
                                      WHEN DTDT.database_transaction_state = 10 THEN
                                          'A transação efetuou COMMIT'
                                      WHEN DTDT.database_transaction_state = 11 THEN
                                          'A transação efetuou ROLLBACK'
                                      WHEN DTDT.database_transaction_state = 12 THEN
                                          'A transação está sendo confirmada. (O registro de log está sendo gerado, mas não foi materializado ou persistente.)'
                                  END,
            [bytes_used] = DTDT.database_transaction_log_bytes_used,
            [bytes_reserved] = DTDT.database_transaction_log_bytes_reserved,
            [Quantidade de Transacoes] = s_tst.open_transaction_count,
            s_eqp.query_plan AS [Last Plan]
     FROM sys.dm_tran_database_transactions AS DTDT
          LEFT JOIN
          sys.dm_tran_session_transactions [s_tst] ON s_tst.transaction_id = DTDT.transaction_id
          LEFT JOIN
          sys.dm_exec_sessions AS DES ON DES.session_id = s_tst.session_id
          LEFT JOIN
          sys.dm_exec_connections AS DEC ON DES.session_id = DEC.session_id
          LEFT OUTER JOIN
          sys.dm_exec_requests [s_er] ON s_er.session_id = s_tst.session_id
          OUTER APPLY sys.dm_exec_sql_text(DEC.most_recent_sql_handle) AS [s_est]
          OUTER APPLY sys.dm_exec_query_plan(s_er.plan_handle) AS [s_eqp]
     WHERE DES.database_id > 6
     )
SELECT 
R.[Maquina Conectada],
R.[Database],
       R.Usuario,
	   R.transaction_id,
       R.Sessão,
       R.[Nivel Isolamento],
       R.[Tempo da transação aberta],
       R.[lock_timeout config session],
       R.[time  last query],
       R.[Last T-SQL Text],
       R.[Tamanho Pacote],
       R.Transaction_type,
       R.Transaction_state,
       R.bytes_used,
       R.bytes_reserved,
       R.[Quantidade de Transacoes],
       R.[Last Plan]
FROM ResultSet R
ORDER BY
    R.[Database],
    R.transaction_id;


	
	


	
