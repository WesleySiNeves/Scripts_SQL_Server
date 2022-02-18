SELECT A.session_id,
       B.host_name,
       B.login_name,
       (A.user_objects_alloc_page_count + A.internal_objects_alloc_page_count) * 1.0 / 128 AS TotalalocadoMB,
       D.text
FROM sys.dm_db_session_space_usage A
     JOIN
     sys.dm_exec_sessions B ON A.session_id = B.session_id
     JOIN
     sys.dm_exec_connections C ON C.session_id = B.session_id
     CROSS APPLY sys.dm_exec_sql_text(C.most_recent_sql_handle) AS D
WHERE A.session_id > 50
--and (A.user_objects_alloc_page_count + A.internal_objects_alloc_page_count)*1.0/128 > 100 --— Ocupam mais de 100 MB
ORDER BY
    TotalalocadoMB DESC;
