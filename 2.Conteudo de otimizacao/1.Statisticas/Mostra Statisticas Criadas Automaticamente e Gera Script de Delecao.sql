
SELECT
		[Schema] =S.name,
		[Tabela] =T.name,
		stats.object_id,
       stats.name,
       stats.auto_created,
	   [Scripts] = CONCAT('DROP STATISTICS ',QUOTENAME(S.name),'.',QUOTENAME(T.name),'.',QUOTENAME(stats.name),';')
  FROM sys.stats
  JOIN sys.tables AS T ON stats.object_id = T.object_id
  JOIN sys.schemas AS S ON T.schema_id = S.schema_id
 WHERE stats.auto_created = 1
   AND stats.object_id IN ( SELECT objects.object_id FROM sys.objects WHERE objects.type = 'U' )
   ORDER BY Tabela
   

   


