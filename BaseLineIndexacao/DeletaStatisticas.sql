
IF ( OBJECT_ID('TEMPDB..#DadosDeletar') IS NOT NULL )
    DROP TABLE #DadosDeletar;	


CREATE TABLE #DadosDeletar
(
    [SchemaName] NVARCHAR(128),
    [TableName]  NVARCHAR(128),
    [Script]     NVARCHAR(402),
    [StatsName]  NVARCHAR(128)
);


INSERT INTO #DadosDeletar(
                             SchemaName,
                             TableName,
                             Script,
                             StatsName
                         )

SELECT S2.name SchemaName,
       T.name AS TableName,
       Script = CONCAT('DROP STATISTICS ', S2.name, '.', T.name, '.', S.name),
       S.name AS StatsName
  FROM sys.stats AS S
       JOIN sys.tables AS T ON S.object_id = T.object_id
       JOIN sys.schemas AS S2 ON T.schema_id = S2.schema_id
 WHERE
    S.name LIKE 'Stats_%'
 --   AND T.name IN ('Usuarios');




 /* declare variables */
 DECLARE @Script VARCHAR(MAX)
 
 DECLARE cursor_executaScript CURSOR FAST_FORWARD READ_ONLY FOR SELECT  DD.Script FROM #DadosDeletar AS DD
 
 OPEN cursor_executaScript
 
 FETCH NEXT FROM cursor_executaScript INTO @Script
 
 WHILE @@FETCH_STATUS = 0
 BEGIN
     

	 EXEC (@Script)

 
     FETCH NEXT FROM cursor_executaScript INTO @Script
 END
 
 CLOSE cursor_executaScript
 DEALLOCATE cursor_executaScript


 SELECT * FROM #DadosDeletar AS DD