DECLARE @ROLLBACK BIT = 1;

SET XACT_ABORT ON;

BEGIN TRANSACTION SCHEDULE;

BEGIN TRY
    /*Region Logical Querys*/
    IF(OBJECT_ID('TEMPDB..#Dados') IS NOT NULL)
        DROP TABLE #Dados;

    CREATE TABLE #Dados
    (
        [object_id]             INT,
        [Schema]                VARCHAR(128),
        [Tabela]                VARCHAR(128),
        [ColumName]             VARCHAR(128),
        [is_rowguidcol]         BIT,
        [default_object_id]     INT,
        [DefaultName]           VARCHAR(200),
        [definition]            VARCHAR(200),
        ScriptDeletarRowguidcol VARCHAR(2000),
        ScriptDeletarDefault    VARCHAR(2000),
    );

    INSERT INTO #Dados
    SELECT t.object_id,
           s.name [Schema],
           t.name [Tabela],
           c.name,
           c.is_rowguidcol,
           c.default_object_id,
           Def.name,
           Def.definition,
           CONCAT('ALTER TABLE ', '[', s.name, ']', '.', '[', t.name, ']', ' ALTER COLUMN  ', '[', c.name, '] ', 'DROP ROWGUIDCOL ;'),
           IIF(Def.object_id IS NULL, '', CONCAT('ALTER TABLE ', s.name, '.', t.name, ' DROP CONSTRAINT  ', '[', Def.name, ']'))
      FROM sys.schemas s
           JOIN sys.tables t ON t.schema_id = s.schema_id
           JOIN sys.columns c ON c.object_id = t.object_id
           LEFT JOIN sys.default_constraints Def ON Def.object_id = c.default_object_id
     WHERE
        c.is_rowguidcol = 1
        AND s.name IN ('Contabilidade', 'Despesa', 'Orcamento', 'Receita')
     ORDER BY
        s.name,
        t.name;

    /* declare variables */
    DECLARE @object_id               BIGINT,
            @Schema                  VARCHAR(250),
            @Tabela                  VARCHAR(250),
            @ColumName               VARCHAR(250),
            @is_rowguidcol           BIT,
            @default_object_id       BIGINT,
            @DefaultName             VARCHAR(250),
            @definition              VARCHAR(250),
            @ScriptDeletarRowguidcol NVARCHAR(2000),
            @ScriptDeletarDefault    NVARCHAR(2000);

    DECLARE cursorCorrige_is_rowguidcol CURSOR FAST_FORWARD READ_ONLY FOR
    SELECT * FROM #Dados AS D ORDER BY D.[Schema], D.Tabela;

    OPEN cursorCorrige_is_rowguidcol;

    FETCH NEXT FROM cursorCorrige_is_rowguidcol
     INTO @object_id,
          @Schema,
          @Tabela,
          @ColumName,
          @is_rowguidcol,
          @default_object_id,
          @DefaultName,
          @definition,
          @ScriptDeletarRowguidcol,
          @ScriptDeletarDefault;

    WHILE @@FETCH_STATUS = 0
        BEGIN
            PRINT @ScriptDeletarRowguidcol;
            PRINT @ScriptDeletarDefault;

            EXECUTE sp_executesql @ScriptDeletarRowguidcol;

            IF(LEN(LTRIM((RTRIM(@ScriptDeletarDefault)))) > 0)
                BEGIN
                    EXECUTE sp_executesql @ScriptDeletarDefault;
                END;

            --SELECT @retorno;

            --EXECUTE sp_executesql @ScriptDropDefault;
            FETCH NEXT FROM cursorCorrige_is_rowguidcol
             INTO @object_id,
                  @Schema,
                  @Tabela,
                  @ColumName,
                  @is_rowguidcol,
                  @default_object_id,
                  @DefaultName,
                  @definition,
                  @ScriptDeletarRowguidcol,
                  @ScriptDeletarDefault;
        END;

    CLOSE cursorCorrige_is_rowguidcol;
    DEALLOCATE cursorCorrige_is_rowguidcol;

    /*End region */
    IF @ROLLBACK = 0
        BEGIN
            COMMIT TRANSACTION SCHEDULE;
        END;
    ELSE
        BEGIN
            ROLLBACK TRANSACTION SCHEDULE;
        END;
END TRY
BEGIN CATCH
    ROLLBACK TRANSACTION SCHEDULE;

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