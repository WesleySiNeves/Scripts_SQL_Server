

EXEC HealthCheck.uspTruncateTableWithForenKeys @TableName = 'Log.LogsJson,Expurgo.LogsJson', -- varchar(256)
                                               @Truncate = 1 -- bit

EXEC HealthCheck.uspTruncateTableWithForenKeys @TableName = 'Sistema.ArquivosAnexos', -- varchar(256)
                                               @Truncate = 1 -- bit

CREATE OR ALTER PROCEDURE HealthCheck.uspTruncateTableWithForenKeys
(
    @TableName VARCHAR(256),
    @Truncate  BIT = 0
)
AS
    BEGIN

        --DECLARE	@TableName VARCHAR(256) ='Log.LogsJson,Expurgo.LogsJson',
        --@Truncate  BIT = 0
        IF(OBJECT_ID('TEMPDB..#TabelasAResetar') IS NOT NULL)
            DROP TABLE #TabelasAResetar;

        CREATE TABLE #TabelasAResetar
        (
            TableName VARCHAR(256),
        );

        INSERT INTO #TabelasAResetar(
                                        TableName
                                    )
        SELECT FSV.Conteudo FROM Sistema.fnSplitValues(@TableName, ',') AS FSV;

        IF(OBJECT_ID('TEMPDB..#BancosNaoDeletarArquivos') IS NOT NULL)
            DROP TABLE #BancosNaoDeletarArquivos;

        --INSERT INTO #TabelasAResetar(TableName)VALUES('Sistema.ArquivosAnexos');
        IF(OBJECT_ID('TEMPDB..#DeletaForenKeys') IS NOT NULL)
            DROP TABLE #DeletaForenKeys;

        CREATE TABLE #DeletaForenKeys
        (
            [SchemaReferenciando]            NVARCHAR(128),
            [TabelaReferenciando]            NVARCHAR(128),
            [ColumsReferentes]               NVARCHAR(128),
            [name]                           NVARCHAR(128),
            [delete_referential_action_desc] NVARCHAR(60),
            [update_referential_action_desc] NVARCHAR(60),
            [SchemaReferenciado]             NVARCHAR(128),
            ReferencedObjectId               BIGINT,
            [TabelaReferenciado]             NVARCHAR(128),
            [ScriptCreate]                   NVARCHAR(1487),
            [ScriptDrop]                     NVARCHAR(674)
        );

        INSERT INTO #DeletaForenKeys
        SELECT S.name AS SchemaReferenciando,
               OBJECT_NAME(referenciando.object_id) AS TabelaReferenciando,
               C.name AS ColumsReferentes,
               FK.name,
               FK.delete_referential_action_desc,
               FK.update_referential_action_desc,
               SshemaReferenced.name AS SchemaReferenciado,
               Referenced.object_id,
               Referenced.name AS TabelaReferenciado,
               ScriptCreate = CONCAT('ALTER TABLE ', QUOTENAME(S.name), '.', OBJECT_NAME(referenciando.object_id), ' WITH NOCHECK ADD CONSTRAINT ', QUOTENAME(FK.name), ' FOREIGN KEY (', QUOTENAME(C.name), ') REFERENCES', QUOTENAME(SshemaReferenced.name), '.', QUOTENAME(Referenced.name)),
               ScriptDrop = CONCAT('ALTER TABLE ', QUOTENAME(S.name), '.', OBJECT_NAME(referenciando.object_id), ' DROP CONSTRAINT ', QUOTENAME(FK.name))
          FROM sys.foreign_keys AS FK
               JOIN sys.foreign_key_columns AS FKC ON FK.parent_object_id = FKC.parent_object_id
                                                      AND FK.referenced_object_id = FKC.referenced_object_id
               JOIN sys.tables AS referenciando ON FK.parent_object_id = referenciando.object_id
               JOIN sys.schemas AS S ON referenciando.schema_id = S.schema_id
               JOIN sys.columns AS C ON referenciando.object_id = C.object_id
                                        AND C.column_id = FKC.parent_column_id
               JOIN sys.tables AS Referenced ON FK.referenced_object_id = Referenced.object_id
               JOIN sys.schemas AS SshemaReferenced ON Referenced.schema_id = SshemaReferenced.schema_id
         WHERE
            Referenced.object_id IN(
                                       SELECT OBJECT_ID(TAR.TableName)FROM #TabelasAResetar AS TAR
                                   );

        IF(CHARINDEX('prd', @@SERVERNAME, 0) = 0)
            BEGIN

                /* declare variables */
                DECLARE @ScriptDelecao NVARCHAR(2000);

                DECLARE cursor_DeletaFK CURSOR FAST_FORWARD READ_ONLY FOR
                SELECT DFK.ScriptDrop
                  FROM #DeletaForenKeys AS DFK
                 ORDER BY
                    DFK.TabelaReferenciando;

                OPEN cursor_DeletaFK;

                FETCH NEXT FROM cursor_DeletaFK
                 INTO @ScriptDelecao;

                WHILE @@FETCH_STATUS = 0
                    BEGIN
                        EXEC sys.sp_executesql @ScriptDelecao;

                        FETCH NEXT FROM cursor_DeletaFK
                         INTO @ScriptDelecao;
                    END;

                CLOSE cursor_DeletaFK;
                DEALLOCATE cursor_DeletaFK;

                IF(@Truncate = 1)
                    BEGIN

                        /* declare variables */
                        DECLARE @Tabela VARCHAR(256);

                        DECLARE cursor_TruncateTable CURSOR FAST_FORWARD READ_ONLY FOR
                        SELECT * FROM #TabelasAResetar AS TAR;

                        OPEN cursor_TruncateTable;

                        FETCH NEXT FROM cursor_TruncateTable
                         INTO @Tabela;

                        WHILE @@FETCH_STATUS = 0
                            BEGIN
                                DECLARE @Truncatetable NVARCHAR(200) = CONCAT('TRUNCATE TABLE ', @Tabela);

                                EXEC sys.sp_executesql @Truncatetable;

                                FETCH NEXT FROM cursor_TruncateTable
                                 INTO @Tabela;
                            END;

                        CLOSE cursor_TruncateTable;
                        DEALLOCATE cursor_TruncateTable;
                    END;

                /* declare variables */
                DECLARE @ScriptCriacao NVARCHAR(2000);

                DECLARE cursor_CriaFK CURSOR FAST_FORWARD READ_ONLY FOR
                SELECT DFK.ScriptCreate FROM #DeletaForenKeys AS DFK;

                OPEN cursor_CriaFK;

                FETCH NEXT FROM cursor_CriaFK
                 INTO @ScriptCriacao;

                WHILE @@FETCH_STATUS = 0
                    BEGIN
                        EXEC sys.sp_executesql @ScriptCriacao;

                        FETCH NEXT FROM cursor_CriaFK
                         INTO @ScriptCriacao;
                    END;

                CLOSE cursor_CriaFK;
                DEALLOCATE cursor_CriaFK;

                SELECT * FROM #DeletaForenKeys AS DFK;
            END;
    END;