DECLARE @SchemaName sysname = 'Receita';
DECLARE @TableName sysname  = 'Recebimentos';
DECLARE @ColumnName sysname = 'DataModificacao';


SELECT
    @SchemaName + '.' + @TableName                                      AS [USED_OBJECT],
    @ColumnName                                                         AS [COLUMN],
    referencing.referencing_schema_name + '.' + referencing_entity_name AS USAGE_OBJECT,
    CASE so.type
        WHEN 'C' THEN 'CHECK constraint'
        WHEN 'D' THEN 'Default'
        WHEN 'F' THEN 'FOREIGN KEY'
        WHEN 'FN' THEN 'Scalar function' 
        WHEN 'IF' THEN 'In-lined table-function'
        WHEN 'K' THEN 'PRIMARY KEY'
        WHEN 'L' THEN 'Log'
        WHEN 'P' THEN 'Stored procedure'
        WHEN 'R' THEN 'Rule'
        WHEN 'RF' THEN 'Replication filter stored procedure'
        WHEN 'S' THEN 'System table'
        WHEN 'TF' THEN 'Table function'
        WHEN 'TR' THEN 'Trigger'
        WHEN 'U' THEN 'User table' 
        WHEN 'V' THEN 'View' 
        WHEN 'X' THEN 'Extended stored procedure'
    END                                             AS USAGE_OBJECTTYPE,
    so.[type]                                       AS USAGE_OBJECTTYPEID
FROM sys.dm_sql_referencing_entities
    (
        @SchemaName + '.' + @TableName,
        'object'
    ) referencing
    INNER JOIN sys.objects so 
        ON referencing.referencing_id = so.object_id
WHERE
    EXISTS
    (
        SELECT
            *
        FROM
            sys.dm_sql_referenced_entities
            (
                referencing_schema_name + '.' + referencing_entity_name,
                'object'
            ) referenced
        WHERE
            referenced_entity_name = @TableName
            AND 
            (
                referenced.referenced_minor_name LIKE @ColumnName   
                -- referenced_minor_name is sometimes NULL
                -- therefore add below condition (can introduce False Positives)
                OR
                (
                    referenced.referenced_minor_name IS NULL 
                    AND 
                    OBJECT_DEFINITION
                    (
                         OBJECT_ID(referencing_schema_name + '.' + referencing_entity_name)
                    ) LIKE '%' + @ColumnName + '%'
                )
            )
    )
ORDER BY
    USAGE_OBJECTTYPE,
    USAGE_OBJECT