SELECT
	S.name, T.name,
       I.name,
	   Script = CONCAT('ALTER INDEX ', QUOTENAME(I.name),' ON ',QUOTENAME(S.name),'.',QUOTENAME(T.name),' REBUILD')
  FROM sys.tables AS T
  JOIN sys.indexes AS I ON T.object_id = I.object_id
  JOIN sys.schemas AS S ON T.schema_id = S.schema_id
  WHERE I.type > 0