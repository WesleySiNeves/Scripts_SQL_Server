
/* declare variables */
DECLARE @Script VARCHAR(1000);

DECLARE cursor_RebuildAllIndex CURSOR FAST_FORWARD READ_ONLY FOR
SELECT 
       Script = CONCAT('ALTER INDEX ALL ON [', S.name, '].[', T.name, '] REBUILD WITH(DATA_COMPRESSION =PAGE,FILLFACTOR =100,ONLINE =ON)')
  FROM sys.schemas AS S
       JOIN sys.tables AS T ON T.schema_id = S.schema_id
 WHERE
    NOT EXISTS (
                   SELECT *
                     FROM sys.indexes AS I
                    WHERE
                       I.object_id = T.object_id
                       AND I.type = 5
               )
			   AND S.name <> 'dbo'
 ORDER BY
    S.name,
    T.name;

OPEN cursor_RebuildAllIndex;

FETCH NEXT FROM cursor_RebuildAllIndex
 INTO @Script;

WHILE @@FETCH_STATUS = 0
    BEGIN
	PRINT(@Script)
	 EXEC(@Script)

	 
        FETCH NEXT FROM cursor_RebuildAllIndex
         INTO @Script;
    END;

CLOSE cursor_RebuildAllIndex;
DEALLOCATE cursor_RebuildAllIndex;
