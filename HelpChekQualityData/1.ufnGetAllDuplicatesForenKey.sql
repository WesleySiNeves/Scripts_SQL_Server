

CREATE OR ALTER FUNCTION HealthCheck.ufnGetAllDuplicatesForenKey ()
RETURNS TABLE
AS RETURN
WITH FKData
  AS (SELECT fk.parent_object_id,
             fkc.parent_column_id,
             fk.referenced_object_id,
             fkc.referenced_column_id,
             FKCount = COUNT(*)
        FROM sys.foreign_keys fk
       INNER JOIN sys.foreign_key_columns fkc
          ON fkc.constraint_object_id = fk.object_id
       GROUP BY fk.parent_object_id,
                fkc.parent_column_id,
                fk.referenced_object_id,
                fkc.referenced_column_id
      HAVING COUNT(*) > 1),
     DuplicateFK
  AS (SELECT FKName = fk.name,
             ParentSchema = s1.name,
             ParentTable = t1.name,
             ParentColumn = c1.name,
             ReferencedTable = t2.name,
             ReferencedColumn = c2.name
        FROM sys.foreign_keys fk
       INNER JOIN sys.foreign_key_columns fkc
          ON fkc.constraint_object_id = fk.object_id
       INNER JOIN FKData f
          ON fk.parent_object_id      = f.parent_object_id
         AND fk.referenced_object_id  = f.referenced_object_id
         AND fkc.parent_column_id     = f.parent_column_id
         AND fkc.referenced_column_id = f.referenced_column_id
       INNER JOIN sys.tables t1
          ON f.parent_object_id       = t1.object_id
       INNER JOIN sys.columns c1
          ON f.parent_object_id       = c1.object_id
         AND f.parent_column_id       = c1.column_id
       INNER JOIN sys.schemas s1
          ON t1.schema_id             = s1.schema_id
       INNER JOIN sys.tables t2
          ON f.referenced_object_id   = t2.object_id
       INNER JOIN sys.columns c2
          ON f.referenced_object_id   = c2.object_id
         AND f.referenced_column_id   = c2.column_id)
SELECT DuplicateFK.FKName,
       DuplicateFK.ParentSchema,
       DuplicateFK.ParentTable,
       DuplicateFK.ParentColumn,
       DuplicateFK.ReferencedTable,
       DuplicateFK.ReferencedColumn,
       DropStmt = 'ALTER TABLE ' + DuplicateFK.ParentSchema + '.' + DuplicateFK.ParentTable + ' DROP CONSTRAINT '
                  + DuplicateFK.FKName
  FROM DuplicateFK;