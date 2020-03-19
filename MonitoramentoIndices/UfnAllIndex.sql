


WITH ResultSet AS (
SELECT ObjectName = CAST(CONCAT(S.name, '.', T.name) AS VARCHAR(150)),
		SI.rowcnt AS TotalRows,
       I.object_id,
       IndexName = I.name,
       I.index_id,
       I.type_desc,
       I.fill_factor,
       I.is_unique,
       I.is_primary_key,
       I.is_unique_constraint,
       I.allow_row_locks,
       I.allow_page_locks,
       I.has_filter,
       I.filter_definition
FROM sys.indexes I
	JOIN  sys.sysindexes AS SI ON  SI.id = I.object_id AND SI.groupid =1
     JOIN
     sys.tables AS T ON I.object_id = T.object_id
     JOIN
     sys.schemas AS S ON T.schema_id = S.schema_id
)
SELECT * FROM  ResultSet R
WHERE R.ObjectName = 'Patrimonio.Bensmoveis'
 AND R.type_desc NOT IN ( 'HEAP' )
 ORDER BY R.ObjectName
 
