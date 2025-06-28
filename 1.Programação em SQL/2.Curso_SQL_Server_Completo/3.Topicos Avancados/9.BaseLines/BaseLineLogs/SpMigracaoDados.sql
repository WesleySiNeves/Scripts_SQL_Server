SET QUOTED_IDENTIFIER ON;

SET ANSI_NULLS ON;
GO

/* ==================================================================
--Data: 15/01/2019 
--Autor :Wesley Neves
--Observação: Faz a migração dos dados
			 
-- ==================================================================
*/

--EXEC Log.uspMigrarConteudoLogsForLogsJSON @DeletarRegistrosMigrados = 1, -- bit
--                                          @QuantidadeRegistrosMigrar = 10000    -- int

/* ==================================================================
--Data: 03/05/2019 
--Autor :Wesley Neves
--Observação: https://blog.pythian.com/disable-lock-escalation-in-sql-server/
 
-- ==================================================================
*/
--EXEC Log.uspMigrarConteudoLogsForLogsJSON @DeletarRegistrosMigrados = 1, -- bit
--                                          @QuantidadeRegistrosMigrar = 1   -- int

CREATE OR ALTER PROCEDURE Log.uspMigrarConteudoLogsForLogsJSON
(
    @DeletarRegistrosMigrados  BIT = 0,
    @QuantidadeRegistrosMigrar INT = 102400
)

AS
    BEGIN
        DECLARE @LogsResult AS TABLE
        (
            NomeTabela                   VARCHAR(150),
            QuantidadeRegistrosDeletados INT
        );

        SET XACT_ABORT ON;

        --   DECLARE @DeletarRegistrosMigrados BIT = 0;

        --DECLARE @QuantidadeRegistrosMigrar INT = 10000;
        IF(EXISTS (
                      SELECT I.name,
                             IC.*,
                             C.name
                        FROM sys.indexes AS I
                             JOIN sys.index_columns AS IC ON I.object_id = IC.object_id
                                                             AND I.index_id = IC.index_id
                             JOIN sys.columns AS C ON I.object_id = C.object_id
                                                      AND IC.column_id = C.column_id
                       WHERE
                          I.object_id = OBJECT_ID('Log.LogsDetalhes')
                          AND IC.index_id > 1
                          AND IC.key_ordinal = 1
                          AND C.name = 'IdLog'
                  )
          )
            BEGIN
                IF(NOT EXISTS (
                                  SELECT I.name,
                                         IC.*,
                                         C.name
                                    FROM sys.indexes AS I
                                         JOIN sys.index_columns AS IC ON I.object_id = IC.object_id
                                                                         AND I.index_id = IC.index_id
                                         JOIN sys.columns AS C ON I.object_id = C.object_id
                                                                  AND IC.column_id = C.column_id
                                   WHERE
                                      I.object_id = OBJECT_ID('Log.LogsDetalhes')
                                      AND IC.key_ordinal = 0
                                      AND C.name IN ('Campo', 'ValorAtual')
                              )
                  )
                    BEGIN
                        DECLARE @NomeIndex VARCHAR(150) = (
                                                              SELECT I.name
                                                                FROM sys.indexes AS I
                                                                     JOIN sys.index_columns AS IC ON I.object_id = IC.object_id
                                                                                                     AND I.index_id = IC.index_id
                                                                     JOIN sys.columns AS C ON I.object_id = C.object_id
                                                                                              AND IC.column_id = C.column_id
                                                               WHERE
                                                                  I.object_id = OBJECT_ID('Log.LogsDetalhes')
                                                                  AND IC.index_id > 1
                                                                  AND IC.key_ordinal = 1
                                                                  AND C.name = 'IdLog'
                                                          );
                        DECLARE @script VARCHAR(500) = CONCAT('CREATE NONCLUSTERED INDEX ', @NomeIndex, ' ON Log.LogsDetalhes([IdLog]) INCLUDE(Campo, ValorAtual) WITH(DROP_EXISTING = ON);');

                        EXEC(@script);
                    END;
            END;
        ELSE
            BEGIN
                CREATE NONCLUSTERED INDEX [IDX_AuditoriaLogsDetalhes]
                ON Log.LogsDetalhes([IdLog])
                INCLUDE(Campo, ValorAtual);
            END;

        IF(EXISTS (
                      SELECT I.name,
                             IC.*,
                             C.name
                        FROM sys.indexes AS I
                             JOIN sys.index_columns AS IC ON I.object_id = IC.object_id
                                                             AND I.index_id = IC.index_id
                             JOIN sys.columns AS C ON I.object_id = C.object_id
                                                      AND IC.column_id = C.column_id
                       WHERE
                          I.object_id = OBJECT_ID('Expurgo.LogsDetalhes')
                          AND IC.index_id > 1
                          AND IC.key_ordinal = 1
                          AND C.name = 'IdLog'
                  )
          )
            BEGIN
                IF(NOT EXISTS (
                                  SELECT I.name,
                                         IC.*,
                                         C.name
                                    FROM sys.indexes AS I
                                         JOIN sys.index_columns AS IC ON I.object_id = IC.object_id
                                                                         AND I.index_id = IC.index_id
                                         JOIN sys.columns AS C ON I.object_id = C.object_id
                                                                  AND IC.column_id = C.column_id
                                   WHERE
                                      I.object_id = OBJECT_ID('Expurgo.LogsDetalhes')
                                      AND IC.key_ordinal = 0
                                      AND C.name IN ('Campo', 'ValorAtual')
                              )
                  )
                    BEGIN
                        DECLARE @NomeIndeExpurgo VARCHAR(150) = (
                                                                    SELECT I.name
                                                                      FROM sys.indexes AS I
                                                                           JOIN sys.index_columns AS IC ON I.object_id = IC.object_id
                                                                                                           AND I.index_id = IC.index_id
                                                                           JOIN sys.columns AS C ON I.object_id = C.object_id
                                                                                                    AND IC.column_id = C.column_id
                                                                     WHERE
                                                                        I.object_id = OBJECT_ID('Expurgo.LogsDetalhes')
                                                                        AND IC.index_id > 1
                                                                        AND IC.key_ordinal = 1
                                                                        AND C.name = 'IdLog'
                                                                );
                        DECLARE @scriptExpurgo VARCHAR(500) = CONCAT('CREATE NONCLUSTERED INDEX ', @NomeIndeExpurgo, ' ON Expurgo.LogsDetalhes([IdLog]) INCLUDE(Campo, ValorAtual) WITH(DROP_EXISTING = ON);');

                        EXEC(@scriptExpurgo);
                    END;
            END;
        ELSE
            BEGIN
                CREATE NONCLUSTERED INDEX [IX_ExpurgoLogsDetalhesIdLog]
                ON Expurgo.LogsDetalhes([IdLog])
                INCLUDE(Campo);
            END;

        IF(OBJECT_ID('TEMPDB..#DadosTempLogs') IS NOT NULL)
            DROP TABLE #DadosTempLogs;

        CREATE TABLE #DadosTempLogs
        (
            [IdLog] UNIQUEIDENTIFIER PRIMARY KEY
        );

        IF(OBJECT_ID('TEMPDB..#DadosTempExpurgo') IS NOT NULL)
            DROP TABLE #DadosTempExpurgo;

        CREATE TABLE #DadosTempExpurgo
        (
            [IdLog] UNIQUEIDENTIFIER PRIMARY KEY
        );

        IF(OBJECT_ID('TEMPDB..#DadosTempLogsDetalhes') IS NOT NULL)
            DROP TABLE #DadosTempLogsDetalhes;

        CREATE TABLE #DadosTempLogsDetalhes
        (
            [IdLog]      UNIQUEIDENTIFIER,
            [Campo]      VARCHAR(100),
            [ValorAtual] VARCHAR(MAX)
        );

        CREATE NONCLUSTERED INDEX IxTempDadosTempLogsDetalhes
        ON #DadosTempLogsDetalhes(IdLog)
        INCLUDE(Campo, ValorAtual);

        IF(OBJECT_ID('TEMPDB..#DadosTempExpurgoDetalhes') IS NOT NULL)
            DROP TABLE #DadosTempExpurgoDetalhes;

        CREATE TABLE #DadosTempExpurgoDetalhes
        (
            [IdLog]      UNIQUEIDENTIFIER,
            [Campo]      VARCHAR(100),
            [ValorAtual] VARCHAR(MAX)
        );

        CREATE NONCLUSTERED INDEX IxTempDadosTempExpurgoDetalhes
        ON #DadosTempExpurgoDetalhes(IdLog)
        INCLUDE(Campo, ValorAtual);

        --/*Region Logical Querys*/
        BEGIN TRY
            DECLARE @ConfigExecutouMigracaoLogsJSON BIT = (
                                                              SELECT ISNULL(TRY_CAST(C.Valor AS BIT), 0)
                                                                FROM Sistema.Configuracoes AS C
                                                               WHERE
                                                                  C.Configuracao = 'ExecutouMigracaoLogsJSON'
                                                          );

            IF(@ConfigExecutouMigracaoLogsJSON = 1)
                BEGIN
                    DECLARE @QuantidadeRegistros INT = (
                                                           SELECT COUNT(*)FROM Log.Logs AS L WITH(NOLOCK)
                                                       ) + (
                                                               SELECT COUNT(*)FROM Expurgo.Logs AS L WITH(NOLOCK)
                                                           );

                    IF(@QuantidadeRegistros > 0)
                        BEGIN
                            SET @ConfigExecutouMigracaoLogsJSON = 0;
                        END;

                    IF(@ConfigExecutouMigracaoLogsJSON = 1)
                        BEGIN
                            SELECT 'A Configuração @ConfigExecutouMigracaoLogsJSON está verdadeira ou seja, cliente migrado ';

                            RETURN;
                        END;
                END;

            ALTER TABLE Log.LogsJson SET(LOCK_ESCALATION = DISABLE);

            ALTER TABLE Expurgo.LogsJson SET(LOCK_ESCALATION = DISABLE);

            ALTER TABLE Log.Logs SET(LOCK_ESCALATION = DISABLE);

            ALTER TABLE Log.LogsDetalhes SET(LOCK_ESCALATION = DISABLE);

            ALTER TABLE Expurgo.Logs SET(LOCK_ESCALATION = DISABLE);

            ALTER TABLE Expurgo.LogsDetalhes SET(LOCK_ESCALATION = DISABLE);

            BEGIN TRANSACTION MigraLogs;

            DECLARE @AzureVersionDB BIT = IIF((SELECT CHARINDEX('Azure', @@VERSION)) > 0, 1, 0);

            TRUNCATE TABLE #DadosTempLogs;


			
            WITH DadosLogs
                AS
                (
                    SELECT L.IdLog
                      FROM Log.Logs AS L
                           LEFT JOIN Log.LogsJson AS LMigrado ON L.IdLog = LMigrado.IdLogAntigo
                     WHERE
                        LMigrado.IdLogAntigo IS NULL
                     ORDER BY
                        L.Data OFFSET 0 ROWS FETCH NEXT @QuantidadeRegistrosMigrar ROWS ONLY
                )
            INSERT INTO #DadosTempLogs SELECT R.IdLog FROM DadosLogs R;

            TRUNCATE TABLE #DadosTempExpurgo;

            WITH DadosExpurgo
                AS
                (
                    SELECT L.IdLog
                      FROM Expurgo.Logs AS L
                           LEFT JOIN Expurgo.LogsJson AS LMigrado ON L.IdLog = LMigrado.IdLogAntigo
                     WHERE
                        LMigrado.IdLogAntigo IS NULL
                     ORDER BY
                        L.Data OFFSET 0 ROWS FETCH NEXT @QuantidadeRegistrosMigrar ROWS ONLY
                )
            INSERT INTO #DadosTempExpurgo SELECT * FROM DadosExpurgo R;

            INSERT INTO #DadosTempLogsDetalhes(
                                                  IdLog,
                                                  Campo,
                                                  ValorAtual
                                              )
            SELECT LD.IdLog,
                   LD.Campo,
                   LD.ValorAtual
              FROM Log.LogsDetalhes AS LD
                   JOIN #DadosTempLogs AS DTL ON LD.IdLog = DTL.IdLog;

            INSERT INTO #DadosTempExpurgoDetalhes(
                                                     IdLog,
                                                     Campo,
                                                     ValorAtual
                                                 )
            SELECT LD.IdLog,
                   LD.Campo,
                   LD.ValorAtual
              FROM Expurgo.LogsDetalhes AS LD
                   JOIN #DadosTempExpurgo AS DTE ON LD.IdLog = DTE.IdLog;

            WITH DadosAMigrarTabelaLogs
                AS
                (
                    SELECT L.IdLog,
                           L.IdPessoa,
                           L.IdEntidade,
                           L.Entidade,
                           L.Acao,
                           L.Data,
                           L.CodSistema,
                           L.IPAdress,
                           JS.*
                      FROM Log.Logs AS L
                           INNER JOIN #DadosTempLogs Temp ON L.IdLog = Temp.IdLog
                           OUTER APPLY(
                                          SELECT M2.Campo,
                                                 M2.ValorAtual
                                            FROM #DadosTempLogsDetalhes AS M2
                                           WHERE
                                              M2.IdLog = L.IdLog
                                              AND LEN(LTRIM(RTRIM(M2.ValorAtual))) > 0
                                          FOR JSON PATH
                                      )JS(Conteudo)
                ),
                 ReplaceJson
                AS
                (
                    SELECT R.IdLog,
                           R.IdPessoa,
                           R.IdEntidade,
                           R.Entidade,
                           R.Acao,
                           R.Data,
                           R.CodSistema,
                           R.IPAdress,
                           R.Conteudo,
                           ReplaceJson1 = REPLACE(REPLACE(R.Conteudo, '"Campo":', ''), '"ValorAtual":', '')
                      FROM DadosAMigrarTabelaLogs R
                ),
                 ReplaceJson2
                AS
                (
                    SELECT R.*,
                           ReplaceJson2 = CONCAT('{', REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(R.ReplaceJson1, ',"', ':"'), '{', ''), '}', ''), '[', ''), ']', ''), '}')
                      FROM ReplaceJson R
                ),
                 DataSource
                AS
                (
                    SELECT R.IdPessoa,
                           R.IdEntidade,
                           R.Entidade,
                           R.IdLog,
                           Acao = CASE WHEN(R.Acao = 'Added') THEN 'I'
                                  WHEN R.Acao = 'Modified' THEN 'U'
                                  WHEN R.Acao = 'Deleted' THEN 'D' END,
                           R.Data,
                           SEL.IdSistemaEspelhamento,
                           R.IPAdress,
                           Conteudo = IIF(R.Acao = 'Deleted', '', R.ReplaceJson2)
                      FROM ReplaceJson2 R
                           JOIN Sistema.SistemasEspelhamentos AS SEL ON R.CodSistema = SEL.CodSistema
                )
            INSERT INTO Log.LogsJson(
                                        IdPessoa,
                                        IdEntidade,
                                        Entidade,
                                        IdLogAntigo,
                                        Acao,
                                        Data,
                                        IdSistemaEspelhamento,
                                        IPAdress,
                                        Conteudo
                                    ) 
									
            SELECT source.IdPessoa,
                   source.IdEntidade,
                   source.Entidade,
                   source.IdLog,
                   source.Acao,
                   source.Data,
                   source.IdSistemaEspelhamento,
                   source.IPAdress,
                   source.Conteudo  
              FROM DataSource source WITH(NOLOCK);

            WITH DadosAMigrarTabelaExpurgoLogs
                AS
                (
                    SELECT L.IdLog,
                           L.IdPessoa,
                           L.IdEntidade,
                           L.Entidade,
                           L.Acao,
                           L.Data,
                           L.CodSistema,
                           L.IPAdress,
                           JS.*
                      FROM Expurgo.Logs AS L
                           JOIN #DadosTempExpurgo AS DTE ON L.IdLog = DTE.IdLog
                           OUTER APPLY(
                                          SELECT M2.Campo,
                                                 M2.ValorAtual
                                            FROM #DadosTempExpurgoDetalhes AS M2
                                           WHERE
                                              M2.IdLog = L.IdLog
                                              AND LEN(LTRIM(RTRIM(M2.ValorAtual))) > 0
                                          FOR JSON PATH
                                      )JS(Conteudo)
                ),
                 ReplaceJson
                AS
                (
                    SELECT R.IdLog,
                           R.IdPessoa,
                           R.IdEntidade,
                           R.Entidade,
                           R.Acao,
                           R.Data,
                           R.CodSistema,
                           R.IPAdress,
                           ReplaceJson1 = REPLACE(REPLACE(R.Conteudo, '"Campo":', ''), '"ValorAtual":', '')
                      FROM DadosAMigrarTabelaExpurgoLogs R
                ),
                 ReplaceJson2
                AS
                (
                    SELECT R.*,
                           ReplaceJson2 = CONCAT('{', REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(R.ReplaceJson1, ',"', ':"'), '{', ''), '}', ''), '[', ''), ']', ''), '}')
                      FROM ReplaceJson R
                ),
                 DataSource
                AS
                (
                    SELECT R.IdPessoa,
                           R.IdEntidade,
                           R.Entidade,
                           R.IdLog,
                           Acao = CASE WHEN(R.Acao = 'Added') THEN 'I'
                                  WHEN R.Acao = 'Modified' THEN 'U'
                                  WHEN R.Acao = 'Deleted' THEN 'D' END,
                           R.Data,
                           SEL.IdSistemaEspelhamento,
                           R.IPAdress,
                           Conteudo = IIF(R.Acao = 'Deleted', '', R.ReplaceJson2)
                      FROM ReplaceJson2 R
                           JOIN Sistema.SistemasEspelhamentos AS SEL ON R.CodSistema = SEL.CodSistema
                )
            INSERT INTO Expurgo.LogsJson(
                                            IdPessoa,
                                            IdEntidade,
                                            Entidade,
                                            IdLogAntigo,
                                            Acao,
                                            Data,
                                            IdSistemaEspelhamento,
                                            IPAdress,
                                            Conteudo
                                        )
            SELECT source.IdPessoa,
                   source.IdEntidade,
                   source.Entidade,
                   source.IdLog,
                   source.Acao,
                   source.Data,
                   source.IdSistemaEspelhamento,
                   source.IPAdress,
                   source.Conteudo
              FROM DataSource source WITH(NOLOCK);

            DECLARE @QuantidadeRegistrosNaoMigradosLogs INT = (
                                                                  SELECT COUNT(L.IdLog)
                                                                    FROM Log.Logs AS L WITH(NOLOCK)
                                                                         LEFT JOIN Log.LogsJson  AS LMigrado WITH(NOLOCK) ON L.IdLog = LMigrado.IdLogAntigo
                                                                   WHERE
                                                                      LMigrado.IdLogAntigo IS NULL
                                                              );
			DECLARE @QuantidadeRegistrosNaoMigradosExpurgo INT = (
																	 SELECT COUNT(L.IdLog)
																	   FROM Expurgo.Logs AS L WITH(NOLOCK)
																			LEFT JOIN Expurgo.LogsJson AS LMigrado WITH(NOLOCK)ON L.IdLog = LMigrado.IdLogAntigo
																	  WHERE
																		 LMigrado.IdLogAntigo IS NULL
																 );


            --SELECT  @QuantidadeRegistrosNaoMigradosLogs AS 'QuantidadeRegistrosNaoMigradosLogs', @QuantidadeRegistrosNaoMigradosExpurgo AS 'QuantidadeRegistrosNaoMigradosExpurgo';

            IF(
                  @QuantidadeRegistrosNaoMigradosExpurgo = 0
                  AND @DeletarRegistrosMigrados = 1
              )
                BEGIN
                    TRUNCATE TABLE Expurgo.LogsDetalhes;

                    IF(EXISTS (
                                  SELECT *
                                    FROM sys.foreign_keys
                                   WHERE
                                      foreign_keys.name = 'FK_LogsDetalhesIdLog_LogsIdLog'
                                      AND foreign_keys.parent_object_id = OBJECT_ID('Expurgo.LogsDetalhes')
                              )
                      )
                        BEGIN
                            ALTER TABLE Expurgo.LogsDetalhes
                            DROP CONSTRAINT FK_LogsDetalhesIdLog_LogsIdLog;
                        END;

                    TRUNCATE TABLE Expurgo.Logs;
                END;

            IF(
                  @QuantidadeRegistrosNaoMigradosLogs = 0
                  AND @DeletarRegistrosMigrados = 1
              )
                BEGIN
                    TRUNCATE TABLE Log.LogsDetalhes;

                    IF(EXISTS (
                                  SELECT *
                                    FROM sys.foreign_keys
                                   WHERE
                                      foreign_keys.name = 'FK_LogsDetalhesIdLog_LogsIdLog'
                                      AND foreign_keys.parent_object_id = OBJECT_ID('Log.LogsDetalhes')
                              )
                      )
                        BEGIN
                            ALTER TABLE Log.LogsDetalhes
                            DROP CONSTRAINT FK_LogsDetalhesIdLog_LogsIdLog;
                        END;

                    TRUNCATE TABLE Log.Logs;
                END;

            PRINT @QuantidadeRegistrosNaoMigradosLogs;
            PRINT @QuantidadeRegistrosNaoMigradosExpurgo;

            IF(
                  @QuantidadeRegistrosNaoMigradosLogs = 0
                  AND @QuantidadeRegistrosNaoMigradosExpurgo = 0
              )
                BEGIN
                    UPDATE C
                       SET C.Valor = 'True'
                      FROM Sistema.Configuracoes AS C
                     WHERE
                        C.Configuracao = 'ExecutouMigracaoLogsJSON';

                    DECLARE @DataFinalizacaoMigracao DATE = GETDATE();

                    UPDATE Sistema.Configuracoes
                       SET Configuracoes.Valor = CAST(@DataFinalizacaoMigracao AS VARCHAR(20))
                     WHERE
                        Configuracoes.Configuracao = 'DataMigracaoLogsJSON';

                    UPDATE Sistema.Configuracoes
                       SET Configuracoes.Valor = DATEADD(DAY, 7, @DataFinalizacaoMigracao)
                     WHERE
                        Configuracoes.Configuracao = 'DataExecucaoExpurgo';

                    IF(NOT EXISTS (
                                      SELECT *
                                        FROM sys.foreign_keys AS FK
                                       WHERE
                                          FK.name = 'FK_LogsDetalhesIdLog_LogsIdLog'
                                          AND FK.parent_object_id = OBJECT_ID('Expurgo.LogsDetalhes')
                                  )
                      )
                        BEGIN
                            ALTER TABLE Expurgo.LogsDetalhes WITH NOCHECK
                            ADD CONSTRAINT [FK_LogsDetalhesIdLog_LogsIdLog] FOREIGN KEY([IdLog])REFERENCES Expurgo.Logs([IdLog]);
                        END;

                    IF(NOT EXISTS (
                                      SELECT *
                                        FROM sys.foreign_keys AS FK
                                       WHERE
                                          FK.name = 'FK_LogsDetalhesIdLog_LogsIdLog'
                                          AND FK.parent_object_id = OBJECT_ID('Log.LogsDetalhes')
                                  )
                      )
                        BEGIN
                            ALTER TABLE Log.LogsDetalhes WITH NOCHECK
                            ADD CONSTRAINT [FK_LogsDetalhesIdLog_LogsIdLog] FOREIGN KEY([IdLog])REFERENCES Log.Logs([IdLog]);
                        END;
                END;

            COMMIT TRAN MigraLogs;

            ALTER TABLE Log.LogsJson SET(LOCK_ESCALATION = AUTO);

            ALTER TABLE Expurgo.LogsJson SET(LOCK_ESCALATION = AUTO);

            ALTER TABLE Log.Logs SET(LOCK_ESCALATION = AUTO);

            ALTER TABLE Log.LogsDetalhes SET(LOCK_ESCALATION = AUTO);

            ALTER TABLE Expurgo.Logs SET(LOCK_ESCALATION = AUTO);

            ALTER TABLE Expurgo.LogsDetalhes SET(LOCK_ESCALATION = AUTO);
        END TRY
        BEGIN CATCH
            IF(@@TRANCOUNT > 0)
                BEGIN
                    ROLLBACK TRANSACTION;
                END;

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
    END;
GO