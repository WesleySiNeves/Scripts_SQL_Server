
SELECT  QS.session_id ,
        [Inicio da Conexão] = QS.connect_time ,
        QS.net_transport ,
        QS.protocol_type ,
        QS.protocol_version ,
        QS.endpoint_id ,
        QS.encrypt_option ,
        QS.auth_scheme ,
        [Numero Paginas Lidas] = QS.num_reads ,
        [Numero Paginas Escritas] = QS.num_writes ,
        [Tamanho Pacote] = QS.net_packet_size ,
        [IP Address] = QS.client_net_address ,
        QS.client_tcp_port ,
        QS.local_net_address ,
        QS.local_tcp_port ,
        QS.connection_id ,
        QS.parent_connection_id ,
        [SQL Exercutado] = ST.text
FROM    sys.dm_exec_connections QS
        CROSS APPLY sys.dm_exec_sql_text(QS.most_recent_sql_handle) AS ST
WHERE   QS.session_id <> @@SPID;




SELECT * FROM  sys.query_store_plan AS QSP
SELECT * FROM  sys.query_store_query_text AS QSQT
SELECT * FROM  sys.query_store_query_text AS QSQT
SELECT * FROM  ssy
SELECT * FROM  sys.query_store_runtime_stats AS QSRS
SELECT * FROM  sys.query_store_runtime_stats_interval AS QSRSI

SELECT * FROM  sys.query_store_wait_stats AS QSWS
