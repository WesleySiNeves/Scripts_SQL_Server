DECLARE @Type VARCHAR(30) = NULL; --'NONCLUSTERED';

SELECT DB_NAME() AS Database_Name,
       sc.name AS Schema_Name,
       o.name AS Table_Name,
       o.type_desc,
       i.name AS Index_Name,
       i.type_desc AS Index_Type,
       i.fill_factor
FROM sys.indexes i
     INNER JOIN
     sys.objects o ON i.object_id = o.object_id
     INNER JOIN
     sys.schemas sc ON o.schema_id = sc.schema_id
WHERE i.name IS NOT NULL
      AND i.type_desc = ISNULL(@Type, i.type_desc)
      AND o.type = 'U'
	  AND i.fill_factor > 0
ORDER BY
    i.fill_factor DESC,
    Schema_Name,
    o.name;