--ALTER PROCEDURE HealthCheck.uspAutoHealthCheck
--(
--    @Efetivar                                BIT      = 1,
--    @Visualizar                              BIT      = 0,
--    @DiaExecucao                             DATETIME = NULL,
--    @TableRowsInUpdateStats                  INT      = 1000,
--    @NumberLinesToDetermineFullScan          INT      = 1000,
--    @NumberOfDaysAnalyzedsForDuplicateIndexs TINYINT  = 7,
--    @PercOfSafetyForDuplicateIndexs          TINYINT  = 10,
--    @NumberOfDaysForInefficientIndex         TINYINT  = 60,
--    @PercAccessForInefficientIndex           TINYINT  = 8,
--    @PercMinFragmentation                    TINYINT  = 10,
--    @QuantityPagesOfAnalyzedFragmentation    SMALLINT = 1000,
--    @DefaultTunningPerform                   SMALLINT = 200
--)
--AS
--    BEGIN

DECLARE @Efetivar BIT = 1,
        @Visualizar BIT = 1,
        @DiaExecucao DATETIME = GETDATE(),
        @TableRowsInUpdateStats INT = 1000,
        @NumberLinesToDetermineFullScan INT = 10000,
        @NumberOfDaysAnalyzedsForDuplicateIndexs TINYINT = 7,
        @PercOfSafetyForDuplicateIndexs TINYINT = 10,
        @NumberOfDaysForInefficientIndex TINYINT = 7,
        @PercAccessForInefficientIndex TINYINT = 9,
        @PercMinFragmentation TINYINT = 10,
        @QuantityPagesOfAnalyzedFragmentation SMALLINT = 1000,
        @DefaultTunningPerform SMALLINT = 500;


EXEC HealthCheck.GetSizeDB;


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

    SET @Script = CONCAT('ALTER DATABASE [', DB_NAME(), '] SET READ_COMMITTED_SNAPSHOT ON WITH ROLLBACK IMMEDIATE ');

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


/*Atualizar Statisticas*/
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
        EXEC HealthCheck.uspUpdateStats @MostarStatisticas = @Visualizar, -- bit
                                        @ExecutarAtualizacao = @Efetivar, -- bit
                                        @TableRowsInUpdateStats = 1000,
                                        @NumberLinesToDetermineFullScan = @NumberLinesToDetermineFullScan;

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
        EXEC HealthCheck.uspAutoCreateIndex @Efetivar = @Efetivar,            -- bit
                                            @VisualizarMissing = @Visualizar, -- bit
                                            @defaultTunningPerform = @DefaultTunningPerform;

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
        EXEC HealthCheck.uspAutoCreateStats @MostrarStatistica = @Visualizar, -- bit
                                            @Efetivar = @Efetivar,            -- bit
                                            @NumberLinesToDetermineFullScan = 10000;

        INSERT INTO [#TableLogs]
        VALUES
        (   'HealthCheck.uspAutoCreateStats', -- NomeProcedure - varchar(200)
            @StartTime,                       -- DataInicio - datetime
            GETDATE()                         -- DataTermino - datetime
            );

        UPDATE HealthCheck.AcoesPeriodicidadeDias
        SET DataUltimaExecucao = GETDATE()
        WHERE Nome = 'CriarStatisticasColunas';
    END;
END;

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

        EXEC HealthCheck.uspDeleteDuplicateIndex @Efetivar = @Efetivar,                            -- bit
                                                 @MostrarIndicesDuplicados = @Visualizar,
                                                 @MostrarIndicesMarcadosParaDeletar = @Visualizar, -- bit
                                                 @QuantidadeDiasAnalizados = @NumberOfDaysAnalyzedsForDuplicateIndexs,
                                                 @TaxaDeSeguranca = 10;                            -- Não deletar indices com acesso superior a 10 % mesmo duplicado(é necessário uma analise individual)

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
        EXEC HealthCheck.uspIndexDesfrag @MostrarIndices = @Visualizar,                         -- bit
                                         @MinFrag = @PercMinFragmentation,                      -- smallint
                                         @MinPageCount = @QuantityPagesOfAnalyzedFragmentation, -- smallint
                                         @Efetivar = @Efetivar;                                 -- bit

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
                    SELECT TOP 1
                           [c].[Valor]
                    FROM [Sistema].[Configuracoes] AS [c]
                    WHERE [c].[Configuracao] = 'QtdDiasExpurgoLogsAcessos'
                );

        DECLARE @dataExecucao DATE = DATEADD(DAY, (@PeriodicidadeExpurgarLogsAcessos * -1), @DiaExecucao);

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

        EXEC [Sistema].[uspExpurgarSistemaNotificacoes] @DataLimite = @data; -- datetime

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
    WHERE [rh].[Rotina] = 'ExpurgarLogsRelatoriosTasks'
)
BEGIN

    IF (EXISTS
    (
        SELECT *
        FROM sys.procedures AS P
        WHERE P.name = 'uspExpurgarLogsRelatoriosLogsTasks'
    )
       )
    BEGIN

        DECLARE @PeriodicidadeExpurgarLogsRelatoriosLogsTasks INT = 180;


        DECLARE @dataLogsRelatoriosLogsTasks DATE
            = DATEADD(DAY, (@PeriodicidadeExpurgarLogsRelatoriosLogsTasks * -1), GETDATE());

        EXEC [Log].uspExpurgarLogsRelatoriosLogsTasks @DataLimite = @dataLogsRelatoriosLogsTasks; -- datetime

        INSERT INTO [#TableLogs]
        VALUES
        (   'Log.uspExpurgarLogsRelatoriosLogsTasks', -- NomeProcedure - varchar(200)
            @StartTime,                               -- DataInicio - datetime
            GETDATE()                                 -- DataTermino - datetime
            );

        UPDATE HealthCheck.AcoesPeriodicidadeDias
        SET DataUltimaExecucao = GETDATE()
        WHERE Nome = 'uspExpurgarLogsRelatoriosLogsTasks';
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

        EXEC HealthCheck.uspExecutaShrink;

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
--END;
GO
