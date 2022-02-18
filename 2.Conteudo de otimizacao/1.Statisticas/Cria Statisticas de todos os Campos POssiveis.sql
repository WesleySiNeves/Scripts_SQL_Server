BEGIN TRY
    /*Region Logical Querys*/

    DECLARE @MostrarStatistica BIT = 1;
    DECLARE @Efetivar BIT = 1;

    DROP TABLE IF EXISTS #CreateStats;


    CREATE TABLE #CreateStats (
                              [object_id]    INT,
                              [SchemaName]   NVARCHAR(128),
                              [TableName]    NVARCHAR(128),
                              [Rows]         BIGINT,
                              [column_id]    INT,
                              [Collun]       NVARCHAR(128),
                              [Type]         NVARCHAR(128),
                              [user_type_id] INT,
                              [max_length]   SMALLINT,
                              [precision]    TINYINT,
                              [is_nullable]  BIT,
                              [is_computed]  BIT,
                              [Script]       VARCHAR(825)
                              );


    WITH AllCollunsNotStatis
      AS (SELECT T.object_id,
                 SchemaName = S.name,
                 TableName = T.name,
                 SI.rowcnt AS Rows,
                 C.column_id,
                 Collun = C.name,
                 [Type] = T2.name,
                 C.user_type_id,
                 C.max_length,
                 C.precision,
                 C.is_nullable,
                 C.is_computed
          FROM sys.tables AS T
               JOIN
               sys.sysindexes AS SI ON SI.id = T.object_id
                                       AND SI.indid = 1
               JOIN
               sys.schemas AS S ON T.schema_id = S.schema_id
               JOIN
               sys.columns AS C ON T.object_id = C.object_id
               JOIN
               sys.types AS T2 ON T2.user_type_id = C.user_type_id
          WHERE NOT EXISTS (
                           SELECT S.object_id,
                                  S.name,
                                  SC.column_id
                           FROM sys.stats AS S
                                JOIN
                                sys.stats_columns AS SC ON S.object_id = SC.object_id
                                                           AND S.stats_id = SC.stats_id
                           WHERE S.object_id = T.object_id
                                 AND SC.column_id = C.column_id
                           )
                AND C.is_replicated = 0
                AND C.is_filestream = 0
                AND C.is_xml_document = 0
                AND C.encryption_type IS NULL
                AND C.is_masked = 0
                AND C.is_hidden = 0
                AND C.graph_type IS NULL
                AND T2.is_table_type = 0
                AND SI.rowcnt > 100
                AND C.column_id > 1
                AND T2.name NOT IN ( 'varbinary', 'nvarchar','XML' )
                AND NOT (
                        T2.name = 'varchar'
                        AND C.max_length = -1
                        )
                AND NOT (
                        T2.name = 'varchar'
                        AND C.max_length > 100
                        )
                AND COLUMNPROPERTY(T.object_id, C.name, 'IsDeterministic')IS NULL
         )
    INSERT INTO #CreateStats
    SELECT AX.object_id,
           AX.SchemaName,
           AX.TableName,
           AX.Rows,
           AX.column_id,
           AX.Collun,
           AX.Type,
           AX.user_type_id,
           AX.max_length,
           AX.precision,
           AX.is_nullable,
           AX.is_computed,
           Script = CONCAT(
                              'CREATE ',
                              SPACE(1),
                              'STATISTICS',
                              SPACE(1),
                              'Stats',
                              AX.SchemaName,
                              AX.TableName,
                              AX.Collun,
                              SPACE(1),
                              'ON',
                              SPACE(1),
                              '[',
                              AX.SchemaName,
                              ']',
                              '.',
                              '[',
                              AX.TableName,
                              '](',
                              AX.Collun,
                              ') WITH ',
                              IIF(AX.Rows <= 1000, 'FULLSCAN', 'SAMPLE 50 PERCENT')
                          )
    FROM AllCollunsNotStatis AX;


    IF (
       EXISTS (
              SELECT 1
              FROM #CreateStats
              )
       AND @Efetivar = 1
       )
    BEGIN

        /* declare variables */
        DECLARE @object_id INT;
        DECLARE @SchemaName VARCHAR(128);
        DECLARE @TableName VARCHAR(128);
        DECLARE @Collun VARCHAR(128);
        DECLARE @Script NVARCHAR(1000);


        DECLARE @StartTime DATETIME = GETDATE();

        DECLARE @Mensagem VARCHAR(1000);

        DECLARE cursor_CreatStats CURSOR FAST_FORWARD READ_ONLY FOR
            SELECT CS.object_id,
                   CS.SchemaName,
                   CS.TableName,
                   CS.Collun,
                   CS.Script
            FROM #CreateStats AS CS;

        OPEN cursor_CreatStats;

        FETCH NEXT FROM cursor_CreatStats
        INTO @object_id,
             @SchemaName,
             @TableName,
             @Collun,
             @Script;

        WHILE @@FETCH_STATUS = 0
        BEGIN


            SET @StartTime = GETDATE();


            EXEC sys.sp_executesql @Script;


            SET @Mensagem
                = CONCAT('Comando :', @Script, ' Executado em :', DATEDIFF(MILLISECOND, @StartTime, GETDATE()), ' MS');

            RAISERROR(@Mensagem, 0, 1) WITH NOWAIT;


            FETCH NEXT FROM cursor_CreatStats
            INTO @object_id,
                 @SchemaName,
                 @TableName,
                 @Collun,
                 @Script;
        END;

        CLOSE cursor_CreatStats;
        DEALLOCATE cursor_CreatStats;

    END;

    IF (@MostrarStatistica = 1)
    BEGIN

        SELECT *
        FROM #CreateStats AS CS;
    END;

END TRY
BEGIN CATCH


    DECLARE @ErrorNumber INT = ERROR_NUMBER();
    DECLARE @ErrorLine INT = ERROR_LINE();
    DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
    DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
    DECLARE @ErrorState INT = ERROR_STATE();

    PRINT 'Actual error number: ' + CAST(@ErrorNumber AS VARCHAR(MAX));
    PRINT 'Actual line number: ' + CAST(@ErrorLine AS VARCHAR(MAX));
    PRINT '@ErrorMessage: ' + CAST(@ErrorMessage AS VARCHAR(MAX));
    PRINT '@ErrorSeverity: ' + CAST(@ErrorLine AS VARCHAR(MAX));
    PRINT '@ErrorState: ' + CAST(@ErrorLine AS VARCHAR(MAX));
    RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);


    PRINT 'Error detected, all changes reversed.';
END CATCH;