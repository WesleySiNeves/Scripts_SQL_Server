ALTER PROCEDURE HealthCheck.uspAutoHealthCheck
(
    @Efetivar                                BIT      = 1,
    @Visualizar                              BIT      = 0,
    @DiaExecucao                             DATETIME = NULL,
    @TableRowsInUpdateStats                  INT      = 1000,
    @NumberLinesToDetermineFullScan          INT      = 1000,
    @NumberOfDaysAnalyzedsForDuplicateIndexs TINYINT  = 7,
    @PercOfSafetyForDuplicateIndexs          TINYINT  = 10,
    @NumberOfDaysForInefficientIndex         TINYINT  = 60,
    @PercAccessForInefficientIndex           TINYINT  = 8,
    @PercMinFragmentation                    TINYINT  = 10,
    @QuantityPagesOfAnalyzedFragmentation    SMALLINT = 1000,
    @DefaultTunningPerform                   SMALLINT = 200
)
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Variáveis para controle de erro
    DECLARE @ErrorMessage NVARCHAR(4000);
    DECLARE @ErrorSeverity INT;
    DECLARE @ErrorState INT;
    DECLARE @ErrorProcedure NVARCHAR(128);
    DECLARE @ErrorLine INT;
    
   BEGIN TRY
        --DECLARE @Efetivar BIT = 1,
        --        @Visualizar BIT = 1,
        --        @DiaExecucao DATETIME = GETDATE(),
        --        @TableRowsInUpdateStats INT = 1000,
        --        @NumberLinesToDetermineFullScan INT = 10000,
        --        @NumberOfDaysAnalyzedsForDuplicateIndexs TINYINT = 7,
        --        @PercOfSafetyForDuplicateIndexs TINYINT = 10,
        --        @NumberOfDaysForInefficientIndex TINYINT = 7,
        --        @PercAccessForInefficientIndex TINYINT = 9,
        --        @PercMinFragmentation TINYINT = 10,
        --        @QuantityPagesOfAnalyzedFragmentation SMALLINT = 1000,
        --        @DefaultTunningPerform SMALLINT = 500;




        SET @DiaExecucao = ISNULL(@DiaExecucao, GETDATE());



    DROP TABLE IF EXISTS #TableLogs;


    CREATE TABLE #TableLogs
    (
        NomeProcedure VARCHAR(200),
        DataInicio DATETIME,
        DataTermino DATETIME,
        Mensagem AS
            CONCAT(NomeProcedure, SPACE(2), 'Tempo Decorrido:', DATEDIFF(MILLISECOND, DataInicio, DataTermino), ' MS')
    );

    DECLARE @ConfiguracaoHabilitarAutoHealthCheck BIT =
            (
                SELECT CAST(C.Valor AS BIT)
                FROM Sistema.Configuracoes AS C
                WHERE C.Configuracao = 'HabilitarAutoHealthCheck'
            );



    /* ==================================================================
    Data: 11/16/2020 
    Autor :Wesley Neves
    Observação: Altera o Nivel de Isolamento do banco de dados para READ_COMMITTED_SNAPSHOT
    
    ==================================================================
    */
    IF (EXISTS
    (
        SELECT s.name,
               CASE s.is_read_committed_snapshot_on
                   WHEN 1 THEN
                       'ENABLED'
                   WHEN 0 THEN
                       'DISABLED'
               END AS 'READ_COMMITTED_SNAPSHOT'
        FROM sys.databases s
        WHERE s.name = DB_NAME()
              AND s.is_read_committed_snapshot_on = 0
    )
       )
    BEGIN
        DECLARE @Script NVARCHAR(1000) = N'';

        SET @Script
            = CONCAT('ALTER DATABASE [', DB_NAME(), '] SET READ_COMMITTED_SNAPSHOT ON WITH ROLLBACK IMMEDIATE ');

        EXEC (@Script);
    END;

    IF (@ConfiguracaoHabilitarAutoHealthCheck IS NULL)
    BEGIN
        INSERT INTO Sistema.Configuracoes
        (
            CodConfiguracao,
            CodSistema,
            Modulo,
            Configuracao,
            Valor,
            Ano
        )
        VALUES
        (   NEWID(),                                -- CodConfiguracao - uniqueidentifier
            '00000000-0000-0000-0000-000000000000', -- CodSistema - uniqueidentifier
            'Global',                               -- Modulo - varchar(100)
            'HabilitarAutoHealthCheck',             -- Configuracao - varchar(100)
            'True',                                 -- Valor - varchar(max)
            0                                       -- Ano - int
            );

        SET @ConfiguracaoHabilitarAutoHealthCheck = CAST(1 AS BIT);
    END;

    DECLARE @DayOfWeek TINYINT =
            (
                SELECT DATEPART(WEEKDAY, GETDATE())
            );


    DROP TABLE IF EXISTS #RotinasHabilitadas;

    CREATE TABLE #RotinasHabilitadas
    (
        id INT NOT NULL PRIMARY KEY IDENTITY(1, 1),
        Rotina VARCHAR(100),
        Ativo BIT,
        PeriodicidadeEmDias SMALLINT,
        ElepsedDays INT
    );



    DECLARE @StartTime DATETIME;

    INSERT INTO [#RotinasHabilitadas]
    (
        [Rotina],
        Ativo,
        PeriodicidadeEmDias,
        [ElepsedDays]
    )
    SELECT [A].[Nome] AS [Rotina],
           CAST(A.Ativo AS BIT) Ativo,
           [A].[Periodicidade],
           DATEDIFF(DAY, ISNULL(A.[DataUltimaExecucao], A.[DataInicio]), GETDATE()) AS [ElepsedDays]
    FROM HealthCheck.AcoesPeriodicidadeDias AS A
    WHERE CAST(A.Ativo AS BIT) = 1
          AND DATEDIFF(DAY, ISNULL(A.[DataUltimaExecucao], A.[DataInicio]), GETDATE()) >= [A].[Periodicidade];





    /* ==================================================================
    --Data: 9/2/2020 
    --Autor :Wesley Neves
    --Observação: guarda o tamanho do banco de dados
    
    -- ==================================================================
    */


    --GetSizeDB ✅ (monitoramento inicial)
    IF (EXISTS (SELECT * FROM sys.procedures AS P WHERE P.name = 'GetSizeDB'))
    BEGIN

        SET @StartTime = GETDATE();

        EXEC HealthCheck.GetSizeDB;

        INSERT INTO [#TableLogs]
        VALUES
        (   'HealthCheck.GetSizeDB', -- NomeProcedure - varchar(200)
            @StartTime,              -- DataInicio - datetime
            GETDATE()                -- DataTermino - datetime
            );
    END;



    /*ExpurgarLogs/ExpurgarLogsAcesso/ExpurgarSistemaNotificacoes/ExpurgarLogsRelatoriosTasks 📈 (libera espaço) */
    IF EXISTS
    (
        SELECT *
        FROM [#RotinasHabilitadas] AS [rh]
        WHERE [rh].[Rotina] = 'ExpurgarLogs'
    )
    BEGIN
        IF (EXISTS
        (
            SELECT *
            FROM sys.procedures AS P
            WHERE P.name = 'uspExpurgoLogsJson'
        )
           )
        BEGIN
            SET @StartTime = GETDATE();

            EXEC Log.uspExpurgoLogsJson;

            INSERT INTO [#TableLogs]
            VALUES
            (   'Log.uspExpurgoLogsJson', -- NomeProcedure - varchar(200)
                @StartTime,               -- DataInicio - datetime
                GETDATE()                 -- DataTermino - datetime
                );

            UPDATE HealthCheck.AcoesPeriodicidadeDias
            SET DataUltimaExecucao = GETDATE()
            WHERE Nome = 'ExpurgarLogs';
        END;
    END;

    IF EXISTS
    (
        SELECT *
        FROM [#RotinasHabilitadas] AS [rh]
        WHERE [rh].[Rotina] = 'ExpurgarLogsAcesso'
    )
    BEGIN

        IF (EXISTS
        (
            SELECT *
            FROM sys.procedures AS P
            WHERE P.name = 'uspExpurgaLogAcessos'
        )
           )
        BEGIN


            DECLARE @PeriodicidadeExpurgarLogsAcessos INT =
                    (
                        SELECT PeriodicidadeEmDias
                        FROM #RotinasHabilitadas
                        WHERE Rotina = 'ExpurgarLogsAcesso'
                    );

            DECLARE @dataExecucao DATE = DATEADD(DAY, (@PeriodicidadeExpurgarLogsAcessos * -1), GETDATE());

            SELECT @dataExecucao;



            EXEC [Log].[uspExpurgaLogAcessos] @Data = @dataExecucao; -- datetime

            INSERT INTO [#TableLogs]
            VALUES
            (   'Log.uspExpurgaLogAcessos', -- NomeProcedure - varchar(200)
                @StartTime,                 -- DataInicio - datetime
                GETDATE()                   -- DataTermino - datetime
                );

            UPDATE HealthCheck.AcoesPeriodicidadeDias
            SET DataUltimaExecucao = GETDATE()
            WHERE Nome = 'ExpurgarLogsAcesso';
        END;
    END;

    /*Expurgo de notificações*/
    IF EXISTS
    (
        SELECT *
        FROM [#RotinasHabilitadas] AS [rh]
        WHERE [rh].[Rotina] = 'ExpurgarSistemaNotificacoes'
    )
    BEGIN

        IF (EXISTS
        (
            SELECT *
            FROM sys.procedures AS P
            WHERE P.name = 'uspExpurgarSistemaNotificacoes'
        )
           )
        BEGIN



            DECLARE @PeriodicidadeExpurgarNotificacoes INT =
                    (
                        SELECT Periodicidade
                        FROM HealthCheck.AcoesPeriodicidadeDias
                        WHERE Nome = 'ExpurgarSistemaNotificacoes'
                    );


            DECLARE @data DATE = DATEADD(DAY, (@PeriodicidadeExpurgarNotificacoes * -1), GETDATE());

            EXEC [Sistema].[uspExpurgarSistemaNotificacoes] @DataLimite = @data,@MostrarRelatorio = @Visualizar; -- datetime

            INSERT INTO [#TableLogs]
            VALUES
            (   'Sistema.uspExpurgarSistemaNotificacoes', -- NomeProcedure - varchar(200)
                @StartTime,                               -- DataInicio - datetime
                GETDATE()                                 -- DataTermino - datetime
                );

            UPDATE HealthCheck.AcoesPeriodicidadeDias
            SET DataUltimaExecucao = GETDATE()
            WHERE Nome = 'uspExpurgarSistemaNotificacoes';
        END;
    END;

    /*Expurgo de logs relatórios e logs task*/
    IF EXISTS
    (
        SELECT *
        FROM [#RotinasHabilitadas] AS [rh]
        WHERE [rh].[Rotina] = 'ExpurgarLogsRelatorios'
    )
    BEGIN

        IF (EXISTS
        (
            SELECT *
            FROM sys.procedures AS P
            WHERE P.name = 'uspExpurgarLogsRelatorios'
        )
           )
        BEGIN



            DECLARE @PeriodicidadeExpurgarLogsRelatorios INT =
                    (
                        SELECT Periodicidade
                        FROM HealthCheck.AcoesPeriodicidadeDias
                        WHERE Nome = 'ExpurgarLogsRelatorios'
                    );


            DECLARE @dataLogsRelatorios DATE = DATEADD(DAY, (@PeriodicidadeExpurgarLogsRelatorios * -1), GETDATE());

            EXEC [HealthCheck].uspExpurgarLogsRelatorios @DataLimite = @dataLogsRelatorios,@MostrarRelatorio = @visualizar;

            INSERT INTO [#TableLogs]
            VALUES
            (   'Log.uspExpurgarLogsRelatorios', -- NomeProcedure - varchar(200)
                @StartTime,                               -- DataInicio - datetime
                GETDATE()                                 -- DataTermino - datetime
                );

            UPDATE HealthCheck.AcoesPeriodicidadeDias
            SET DataUltimaExecucao = GETDATE()
            WHERE Nome = 'ExpurgarLogsRelatorios';
        END;
    END;

    /*Expurgo de logs  task*/
    IF EXISTS
    (
        SELECT *
        FROM [#RotinasHabilitadas] AS [rh]
        WHERE [rh].[Rotina] = 'ExpurgarLogsTasks'
    )
    BEGIN

        IF (EXISTS
        (
            SELECT *
            FROM sys.procedures AS P
            WHERE P.name = 'uspExpurgarLogsTasks'
        )
           )
        BEGIN



            DECLARE @PeriodicidadeExpurgarsLogsTasks INT =
                    (
                        SELECT Periodicidade
                        FROM HealthCheck.AcoesPeriodicidadeDias
                        WHERE Nome = 'ExpurgarLogsTasks'
                    );



            DECLARE @dataLogsRelatoriosLogsTasks DATE
                = DATEADD(DAY, (@PeriodicidadeExpurgarsLogsTasks * -1), GETDATE());

            EXEC [HealthCheck].[uspExpurgarLogsTasks] @DataLimite = @dataLogsRelatoriosLogsTasks,@MostrarRelatorio =@Visualizar;

            INSERT INTO [#TableLogs]
            VALUES
            (   'Log.uspExpurgarLogsTasks', -- NomeProcedure - varchar(200)
                @StartTime,                 -- DataInicio - datetime
                GETDATE()                   -- DataTermino - datetime
                );

            UPDATE HealthCheck.AcoesPeriodicidadeDias
            SET DataUltimaExecucao = GETDATE()
            WHERE Nome = 'ExpurgarLogsTasks';
        END;
    END;

    /*Deleta os indices duplicados*/
    IF EXISTS
    (
        SELECT *
        FROM [#RotinasHabilitadas] AS [rh]
        WHERE [rh].[Rotina] = 'DeletarIndicesDuplicados'
    )
    BEGIN
        IF (EXISTS
        (
            SELECT *
            FROM sys.procedures AS P
            WHERE P.name = 'uspDeleteDuplicateIndex'
        )
           )
        BEGIN
            SET @StartTime = GETDATE();

            EXEC HealthCheck.uspDeleteDuplicateIndex @Efetivar = 1, -- bit
                                         @MostrarIndicesDuplicados = @Visualizar, -- bit
                                         @MostrarIndicesMarcadosParaDeletar = @Visualizar, -- bit
                                         @QuantidadeDiasAnalizados = 1, -- tinyint
                                         @TaxaDeSeguranca = 10, -- tinyint
                                         @Debug = 0, -- bit
                                         @MostrarResumoExecutivo = @Visualizar


            INSERT INTO [#TableLogs]
            VALUES
            (   'HealthCheck.uspDeleteDuplicateIndex', -- NomeProcedure - varchar(200)
                @StartTime,                            -- DataInicio - datetime
                GETDATE()                              -- DataTermino - datetime
                );

            UPDATE HealthCheck.AcoesPeriodicidadeDias
            SET DataUltimaExecucao = GETDATE()
            WHERE Nome = 'DeletarIndicesDuplicados';
        END;
    END;

    /*Atualizar Statisticas base para otimizações*/
    IF EXISTS
    (
        SELECT *
        FROM [#RotinasHabilitadas] AS [rh]
        WHERE [rh].[Rotina] = 'AtualizarStatisticas'
    )
    BEGIN


        IF (EXISTS
        (
            SELECT *
            FROM sys.procedures AS P
            WHERE P.name = 'uspUpdateStats'
        )
           )
        BEGIN
            SET @StartTime = GETDATE();
            /*Atualiza Statisticas Necessárias (diario)*/
            EXEC HealthCheck.uspUpdateStats @ExecutarAtualizacao = 1,@MostrarProgresso =@Visualizar; -- bit

            INSERT INTO [#TableLogs]
            VALUES
            (   'HealthCheck.uspUpdateStats', -- NomeProcedure - varchar(200)
                @StartTime,                   -- DataInicio - datetime
                GETDATE()                     -- DataTermino - datetime
                );

            UPDATE HealthCheck.AcoesPeriodicidadeDias
            SET DataUltimaExecucao = GETDATE()
            WHERE Nome = 'AtualizarStatisticas';
        END;
    END;

    /*CriarStatisticasColunas ✅ (Após atualizar estatísticas)*/
    IF EXISTS
    (
        SELECT *
        FROM [#RotinasHabilitadas] AS [rh]
        WHERE [rh].[Rotina] = 'CriarStatisticasColunas'
    )
    BEGIN
        IF (EXISTS
        (
            SELECT *
            FROM sys.procedures AS P
            WHERE P.name = 'uspAutoCreateStats'
        )
           )
        BEGIN
            SET @StartTime = GETDATE();

            /*Cria os Statisticas Colunares de tabelas que foram acessados pelos indices*/
            EXEC HealthCheck.uspAutoCreateStats @Efetivar = 1;


            INSERT INTO [#TableLogs]
            VALUES
            (   'HealthCheck.uspAutoCreateStats', -- NomeProcedure - varchar(200)
                @StartTime,                       -- DataInicio - datetime
                GETDATE()                         -- DataTermino - datetime
                );

            UPDATE HealthCheck.AcoesPeriodicidadeDias
            SET DataUltimaExecucao = GETDATE( )
            WHERE Nome = 'CriarStatisticasColunas';
        END;
    END;

    /*CriarIndicesAutomaticamente ✅ (Após estatísticas atualizadas)*/
    IF EXISTS
    (
        SELECT *
        FROM [#RotinasHabilitadas] AS [rh]
        WHERE [rh].[Rotina] = 'CriarIndicesAutomaticamente'
    )
    BEGIN
        IF (EXISTS
        (
            SELECT *
            FROM sys.procedures AS P
            WHERE P.name = 'uspAutoCreateIndex'
        )
           )
        BEGIN
            SET @StartTime = GETDATE();

            /*Cria Automaticamente Missing Index (diario)*/
            EXEC HealthCheck.uspAutoCreateIndex @Efetivar = 1;


            INSERT INTO [#TableLogs]
            VALUES
            (   'HealthCheck.uspAutoCreateIndex', -- NomeProcedure - varchar(200)
                @StartTime,                       -- DataInicio - datetime
                GETDATE()                         -- DataTermino - datetime
                );

            UPDATE HealthCheck.AcoesPeriodicidadeDias
            SET DataUltimaExecucao = GETDATE()
            WHERE Nome = 'CriarIndicesAutomaticamente';
        END;
    END;


    --DesfragmentacaoIndices ✅ (Após criação de índices)
    IF EXISTS
    (
        SELECT *
        FROM [#RotinasHabilitadas] AS [rh]
        WHERE [rh].[Rotina] = 'DesfragmentacaoIndices'
    )
    BEGIN
        IF (EXISTS
        (
            SELECT *
            FROM sys.procedures AS P
            WHERE P.name = 'uspIndexDesfrag'
        )
           )
        BEGIN
            SET @StartTime = GETDATE();

            /* Desfragmento dos indices */
            exec [HealthCheck].[uspIndexDesfrag] @Efetivar = 1 ,@MostrarIndices  = @Visualizar

            INSERT INTO [#TableLogs]
            VALUES
            (   'HealthCheck.uspIndexDesfrag', -- NomeProcedure - varchar(200)
                @StartTime,                    -- DataInicio - datetime
                GETDATE()                      -- DataTermino - datetime
                );

            UPDATE HealthCheck.AcoesPeriodicidadeDias
            SET DataUltimaExecucao = GETDATE()
            WHERE Nome = 'DesfragmentacaoIndices';
        END;
    END;


    /*ShrinkDatabase*/
    IF EXISTS
    (
        SELECT *
        FROM [#RotinasHabilitadas] AS [rh]
        WHERE [rh].[Rotina] = 'ShrinkDatabase'
    )
    BEGIN

        IF (EXISTS
        (
            SELECT *
            FROM sys.procedures AS P
            WHERE P.name = 'uspExecutaShrink'
        )
           )
        BEGIN
            SET @StartTime = GETDATE();

            EXEC HealthCheck.uspExecutaShrink @ExecuteShrink = 1;

            INSERT INTO [#TableLogs]
            VALUES
            (   'HealthCheck.uspExecutaShrink', -- NomeProcedure - varchar(200)
                @StartTime,                     -- DataInicio - datetime
                GETDATE()                       -- DataTermino - datetime
                );

            UPDATE HealthCheck.AcoesPeriodicidadeDias
            SET DataUltimaExecucao = GETDATE()
            WHERE Nome = 'ShrinkDatabase';
        END;
    END;

        SELECT *
        FROM [#TableLogs];
        
    END TRY
    BEGIN CATCH
        -- Captura informações do erro
        SELECT @ErrorMessage = ERROR_MESSAGE(),
               @ErrorSeverity = ERROR_SEVERITY(),
               @ErrorState = ERROR_STATE(),
               @ErrorProcedure = ISNULL(ERROR_PROCEDURE(), 'HealthCheck.uspAutoHealthCheck'),
               @ErrorLine = ERROR_LINE();
        
        -- Log do erro para auditoria
        DECLARE @ErrorLog NVARCHAR(MAX) = 
            N'ERRO na execução do HealthCheck: ' + 
            N'Procedure: ' + @ErrorProcedure + 
            N', Linha: ' + CAST(@ErrorLine AS NVARCHAR(10)) + 
            N', Mensagem: ' + @ErrorMessage + 
            N', Severidade: ' + CAST(@ErrorSeverity AS NVARCHAR(10)) + 
            N', Estado: ' + CAST(@ErrorState AS NVARCHAR(10)) + 
            N', Data/Hora: ' + CONVERT(NVARCHAR(30), GETDATE(), 121);
        
        ---- Tenta inserir o erro na tabela de logs se ela existir
        --IF OBJECT_ID('HealthCheck.LogsExecucao') IS NOT NULL
        --BEGIN
        --    INSERT INTO HealthCheck.LogsExecucao (Procedure, DataExecucao, Status, Mensagem)
        --    VALUES ('HealthCheck.uspAutoHealthCheck', GETDATE(), 'ERRO', @ErrorLog);
        --END;
        
        -- Retorna informações do erro para o PowerShell capturar
        SELECT 
            'ERRO' AS Status,
            @ErrorProcedure AS 'Rotina',
            @ErrorLine AS Linha,
            @ErrorMessage AS Mensagem,
            @ErrorSeverity AS Severidade,
            @ErrorState AS Estado,
            GETDATE() AS DataHoraErro;
        
        -- Re-lança o erro para que o PowerShell possa capturar
        RAISERROR(@ErrorLog, @ErrorSeverity, @ErrorState);
        
    END CATCH;
END;
GO
