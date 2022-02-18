SELECT CONCAT(OBJECT_SCHEMA_NAME(columns.object_id), '.', OBJECT_NAME(columns.object_id)) AS TableName,
       columns.name AS ColumnName,
       COLUMNPROPERTYEX(columns.object_id, columns.name, 'IsIndexable') AS Indexable
  FROM sys.columns
 WHERE columns.is_computed = 1;