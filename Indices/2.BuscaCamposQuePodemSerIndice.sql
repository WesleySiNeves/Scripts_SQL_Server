SELECT  CONCAT(OBJECT_SCHEMA_NAME(object_id), '.', OBJECT_NAME(object_id)) AS TableName ,
        name AS ColumnName ,
        COLUMNPROPERTYEX(object_id, name, 'IsIndexable') AS Indexable
FROM    sys.columns
WHERE   OBJECT_NAME(object_id) = 'Empenhos';