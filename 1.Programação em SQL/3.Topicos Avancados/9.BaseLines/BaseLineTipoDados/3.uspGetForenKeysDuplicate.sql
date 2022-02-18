

CREATE OR ALTER PROCEDURE HealthCheck.uspGetForenKeysDuplicate
AS
BEGIN

    ;WITH ForeignKeys1
       AS (SELECT fk.object_id,
                  SCHEMA_NAME(fk.schema_id) AS SchemaName,
                  OBJECT_NAME(fk.parent_object_id) AS table_name,
                  fk.name AS foreign_key_name,
                  fk.create_date,
                  (   SELECT CAST(fkc.parent_object_id AS VARCHAR(50)) + SPACE(1)
                             + CAST(fkc.parent_column_id AS VARCHAR(50)) + SPACE(1)
                             + CAST(fkc.referenced_object_id AS VARCHAR(50)) + SPACE(1)
                             + CAST(fkc.referenced_column_id AS VARCHAR(50)) AS [data()]
                        FROM sys.foreign_key_columns fkc
                       WHERE fk.object_id = fkc.constraint_object_id
                       ORDER BY constraint_column_id
                      FOR XML PATH('')) foreign_key
             FROM sys.foreign_keys fk),
          ForeignKeys2
       AS (SELECT ForeignKeys1.object_id,
                  ForeignKeys1.SchemaName,
                  ForeignKeys1.table_name,
                  ForeignKeys1.foreign_key_name,
                  ForeignKeys1.foreign_key,
                  ROW_NUMBER() OVER (PARTITION BY ForeignKeys1.foreign_key
                                         ORDER BY ForeignKeys1.create_date) AS ForeignKeyRank
             FROM ForeignKeys1)
    SELECT x.object_id,
           x.SchemaName,
           x.table_name AS [Table Name],
           x.foreign_key_name AS [Foreign Key],
           y.foreign_key_name AS [Foreign Key Duplicate]
      FROM ForeignKeys2 x
     INNER JOIN ForeignKeys2 y
        ON x.foreign_key    = y.foreign_key
       AND x.ForeignKeyRank <> y.ForeignKeyRank;

END;
