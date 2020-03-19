IF(OBJECT_ID('TEMPDB..#SchemasName') IS NOT NULL)
    DROP TABLE #SchemasName;

CREATE TABLE #SchemasName
(
    Name VARCHAR(200),
);

IF(OBJECT_ID('TEMPDB..#Scripts') IS NOT NULL)
    DROP TABLE #Scripts;

CREATE TABLE #Scripts
(
    Script VARCHAR(MAX)
);

INSERT INTO #SchemasName(Name)VALUES('Compra');

WITH DefaultsContrainsts
    AS
    (
        SELECT S.name AS SchemaName,
               T.name AS TableName,
               DC.name AS DefaultName,
               DC.object_id,
               DC.principal_id,
               DC.schema_id,
               DC.parent_object_id,
               DC.type,
               DC.type_desc,
               DC.parent_column_id,
               DC.definition,
               Script = CONCAT(' IF ( EXISTS(SELECT * FROM sys.default_constraints AS DC WHERE DC.name = ', CHAR(39), DC.name, CHAR(39), ' )) BEGIN     ALTER TABLE ', S.name, '.', T.name, ' DROP CONSTRAINT ', DC.name, ' 	 END')
          FROM sys.default_constraints AS DC
               JOIN sys.tables AS T ON DC.parent_object_id = T.object_id
               JOIN sys.schemas AS S ON DC.schema_id = S.schema_id
         WHERE
            DC.parent_column_id = 1
            AND EXISTS (
                           SELECT I.object_id,
                                  I.index_id,
                                  IC.*
                             FROM sys.indexes AS I
                                  JOIN sys.index_columns IC ON I.object_id = IC.object_id
                                                               AND I.index_id = IC.index_id
                            WHERE
                               I.is_primary_key = 1
                               AND I.object_id = DC.parent_object_id
                               AND IC.column_id = 1
                       )
            AND S.name IN(
                             SELECT SN.Name COLLATE DATABASE_DEFAULT FROM #SchemasName AS SN
                         )
    )
INSERT INTO #Scripts(
                        Script
                    )
SELECT DISTINCT DefaultsContrainsts.Script FROM DefaultsContrainsts;

DECLARE @Query VARCHAR(MAX);

DECLARE cursor_DeletaConstraints CURSOR FAST_FORWARD READ_ONLY FOR
SELECT * FROM #Scripts AS S;

OPEN cursor_DeletaConstraints;

FETCH NEXT FROM cursor_DeletaConstraints
 INTO @Query;

WHILE @@FETCH_STATUS = 0
    BEGIN
        SELECT (@Query);

        --EXEC (@Query);
        FETCH NEXT FROM cursor_DeletaConstraints
         INTO @Query;
    END;

CLOSE cursor_DeletaConstraints;
DEALLOCATE cursor_DeletaConstraints;