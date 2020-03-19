IF(OBJECT_ID('TEMPDB..#Scripts') IS NOT NULL)
    DROP TABLE #Scripts;

CREATE TABLE #Scripts
(
    [name]         NVARCHAR(128),
    [schema_id]    INT,
    [principal_id] INT,
    [script]       NVARCHAR(238)
);

DECLARE @WorkerCount INT = 5;

IF(EXISTS (
              SELECT * FROM sys.syscursors AS S WHERE S.cursor_name = 'cursor_Executa'
          )
  )
    BEGIN
        DEALLOCATE cursor_Executa;
    END;

INSERT INTO #Scripts(
                        name,
                        schema_id,
                        principal_id,
                        script
                    )
SELECT S.name,
       S.schema_id,
       S.principal_id,
       script = CONCAT('UPDATE target SET target.Data = JSON_MODIFY(target.Data,' + CHAR(39) + '$.WorkerCount' + CHAR(39) + ',', CHAR(39), @WorkerCount, CHAR(39), ')', 'FROM ', S.name, '.Server AS target;')
  FROM sys.schemas AS S
 WHERE
    S.name LIKE '%Hangfire%'
    AND S.name NOT IN ('$(HangFireSchema)');

/* declare variables */
DECLARE @scripts VARCHAR(MAX);

DECLARE cursor_Executa CURSOR FAST_FORWARD READ_ONLY FOR
SELECT S.script FROM #Scripts AS S;

OPEN cursor_Executa;

FETCH NEXT FROM cursor_Executa
 INTO @scripts;

WHILE @@FETCH_STATUS = 0
    BEGIN
        SELECT @scripts;

        EXEC(@scripts);

        FETCH NEXT FROM cursor_Executa
         INTO @scripts;
    END;

CLOSE cursor_Executa;
DEALLOCATE cursor_Executa;
