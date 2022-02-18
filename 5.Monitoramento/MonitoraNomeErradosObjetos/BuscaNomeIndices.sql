
SELECT  S.name, T.name AS Tabela , I.name,I.object_id FROM  sys.indexes AS I
JOIN sys.tables AS T ON I.object_id = T.object_id
JOIN sys.schemas AS S ON T.schema_id = S.schema_id
WHERE I.object_id > 100
AND I.name LIKE '%missing%'