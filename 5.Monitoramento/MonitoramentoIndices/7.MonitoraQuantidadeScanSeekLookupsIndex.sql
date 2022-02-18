
SELECT OBJECT_NAME(S.object_id) AS table_name,
I.name AS index_name,
S.user_seeks, S.user_scans, s.user_lookups
FROM sys.dm_db_index_usage_stats AS S
INNER JOIN sys.indexes AS i
ON S.object_id = I.object_id
AND S.index_id = I.index_id
AND S.database_id = DB_ID()
ORDER BY S.user_lookups DESC
--WHERE S.object_id = OBJECT_ID(N'Contabilidade.Lancamentos', N'U');