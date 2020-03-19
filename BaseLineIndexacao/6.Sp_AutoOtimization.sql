SET QUOTED_IDENTIFIER ON;

SET ANSI_NULLS ON;
GO

CREATE OR ALTER PROCEDURE HealthCheck.uspAutoHealthCheck
(
    @Efetivar                                BIT      = 1,
    @Visualizar                              BIT      = 0,
    @DiaExecucao                             DATETIME = NULL,
    @TableRowsInUpdateStats                  INT      = 1000,
    @NumberLinesToDetermineFullScan          INT      = 100000,
    @NumberOfDaysAnalyzedsForDuplicateIndexs TINYINT  = 7,
    @PercOfSafetyForDuplicateIndexs          TINYINT  = 10,
    @NumberOfDaysForInefficientIndex         TINYINT  = 60,
    @PercAccessForInefficientIndex           TINYINT  = 8,
    @PercMinFragmentation                    TINYINT  = 10,
    @QuantityPagesOfAnalyzedFragmentation    SMALLINT = 1000,
    @NumberOfDaysForIndexNoUsageIndex        TINYINT  = 60,
    @NumberOfDaysForClear                    TINYINT  = 60,
    @DefaultTunningPerform                   SMALLINT = 200
)
AS

--DECLARE @Efetivar                                BIT      = 0,
--        @Visualizar                              BIT      = 1,
--        @DiaExecucao                             DATETIME = GETDATE(),
--        @TableRowsInUpdateStats                  INT      = 1000,
--        @NumberLinesToDetermineFullScan          INT      = 100000,
--        @NumberOfDaysAnalyzedsForDuplicateIndexs TINYINT  = 7,
--        @PercOfSafetyForDuplicateIndexs          TINYINT  = 10,
--        @NumberOfDaysForInefficientIndex         TINYINT  = 7,
--        @PercAccessForInefficientIndex           TINYINT  = 9,
--        @PercMinFragmentation                    TINYINT  = 10,
--        @QuantityPagesOfAnalyzedFragmentation    SMALLINT = 1000,
--        @NumberOfDaysForIndexNoUsageIndex        TINYINT  = 30,
--        @NumberOfDaysForClear                    TINYINT  = 30,
--        @DefaultTunningPerform                   SMALLINT = 500;
SET @DiaExecucao = ISNULL(@DiaExecucao, GETDATE());

DECLARE @TableLogs TABLE
(
    NomeProcedure VARCHAR(200),
    DataInicio    DATETIME,
    DataTermino   DATETIME,
    Mensagem      AS CONCAT(NomeProcedure, SPACE(2), 'Tempo Decorrido:', DATEDIFF(MILLISECOND, DataInicio, DataTermino), ' MS')
);

-- recuperar da configuracao
DECLARE @DataStartMonitoracao DATE = (
                                         SELECT CAST(C.Valor AS DATE)
                                           FROM Sistema.Configuracoes AS C
                                          WHERE
                                             C.Configuracao = 'DataStartMonitoramentoHealthCheck'
                                     );
DECLARE @ConfiguracaoHabilitarAutoHealthCheck BIT = (
                                                        SELECT CAST(C.Valor AS BIT)
                                                          FROM Sistema.Configuracoes AS C
                                                         WHERE
                                                            C.Configuracao = 'HabilitarAutoHealthCheck'
                                                    );
DECLARE @DayOfWeek TINYINT = (
                                 SELECT DATEPART(WEEKDAY, GETDATE())
                             );

IF(@DataStartMonitoracao IS NULL)
    BEGIN
        INSERT INTO Sistema.Configuracoes(
                                             CodConfiguracao,
                                             CodSistema,
                                             Modulo,
                                             Configuracao,
                                             Valor,
                                             Ano
                                         )
        VALUES(   NEWID(),                                -- CodConfiguracao - uniqueidentifier
                  '00000000-0000-0000-0000-000000000000', -- CodSistema - uniqueidentifier
                  'Global',                               -- Modulo - varchar(100)
                  'DataStartMonitoramentoHealthCheck',    -- Configuracao - varchar(100)
                  CONVERT(VARCHAR, GETDATE(), 20),        -- Valor - varchar(max)
                  0                                       -- Ano - int
              );
    END;

SET @DataStartMonitoracao = ISNULL(@DataStartMonitoracao, GETDATE());

IF(@ConfiguracaoHabilitarAutoHealthCheck IS NULL)
    BEGIN
        INSERT INTO Sistema.Configuracoes(
                                             CodConfiguracao,
                                             CodSistema,
                                             Modulo,
                                             Configuracao,
                                             Valor,
                                             Ano
                                         )
        VALUES(   NEWID(),                                -- CodConfiguracao - uniqueidentifier
                  '00000000-0000-0000-0000-000000000000', -- CodSistema - uniqueidentifier
                  'Global',                               -- Modulo - varchar(100)
                  'HabilitarAutoHealthCheck',             -- Configuracao - varchar(100)
                  'True',                                 -- Valor - varchar(max)
                  0                                       -- Ano - int
              );

        SET @ConfiguracaoHabilitarAutoHealthCheck = CAST(1 AS BIT);
    END;

IF(@ConfiguracaoHabilitarAutoHealthCheck = 1)
    BEGIN
        DECLARE @Modulo1 TINYINT = 7;
        DECLARE @Modulo2 TINYINT = 15;
        DECLARE @Modulo3 TINYINT = 30;
        DECLARE @StartTime DATETIME;

        /* ==================================================================
	--Observação: Diario , 
	 1) Snap shots do uso dos indices
	 2) Atualização das statisticas necessárias
	 3) Auto Create Index
	 
	-- ==================================================================
	*/

        /*Executa Snap shot dos indices  (Diario) exceto nos Fins de Semana e feriados*/
        IF(
              @DayOfWeek NOT IN (7, 1)
              AND (NOT EXISTS (
                                  SELECT *
                                    FROM Corporativo.Feriados AS F
                                   WHERE
                                      F.Mes = MONTH(@DiaExecucao)
                                      AND F.Dia = DAY(@DiaExecucao)
                              )
                  )
          )
            BEGIN
                SET @StartTime = GETDATE();

                EXEC HealthCheck.uspSnapShotIndex @Visualizar = @Visualizar,   -- bit
                                                  @DiaExecucao = @DiaExecucao, -- datetime
                                                  @Efetivar = @Efetivar;

                INSERT INTO @TableLogs
                VALUES(   'HealthCheck.uspSnapShotIndex', -- NomeProcedure - varchar(200)
                          @StartTime,                     -- DataInicio - datetime
                          GETDATE()                       -- DataTermino - datetime
                      );
            END;

        SET @StartTime = GETDATE();

        /*Deleta Statisticas Duplicadas*/
        EXEC HealthCheck.uspDeleteOverlappingStats @MostarStatisticas = @Visualizar, -- bit
                                                   @Executar = @Efetivar;            -- bit

        INSERT INTO @TableLogs
        VALUES(   'HealthCheck.uspDeleteOverlappingStats', -- NomeProcedure - varchar(200)
                  @StartTime,                              -- DataInicio - datetime
                  GETDATE()                                -- DataTermino - datetime
              );

        SET @StartTime = GETDATE();

        /*Atualiza Statisticas Necessárias (diario)*/
        EXEC HealthCheck.uspUpdateStats @MostarStatisticas = @Visualizar, -- bit
                                        @ExecutarAtualizacao = @Efetivar, -- bit
                                        @TableRowsInUpdateStats = @TableRowsInUpdateStats,
                                        @NumberLinesToDetermineFullScan = @NumberLinesToDetermineFullScan;

        INSERT INTO @TableLogs
        VALUES(   'HealthCheck.uspUpdateStats', -- NomeProcedure - varchar(200)
                  @StartTime,                   -- DataInicio - datetime
                  GETDATE()                     -- DataTermino - datetime
              );

        SET @StartTime = GETDATE();

        /*Cria Automaticamente Missing Index (diario)*/
        EXEC HealthCheck.uspAutoCreateIndex @Efetivar = @Efetivar,            -- bit
                                            @VisualizarMissing = @Visualizar, -- bit
                                            @defaultTunningPerform = @DefaultTunningPerform;

        INSERT INTO @TableLogs
        VALUES(   'HealthCheck.uspAutoCreateIndex', -- NomeProcedure - varchar(200)
                  @StartTime,                       -- DataInicio - datetime
                  GETDATE()                         -- DataTermino - datetime
              );

        /* ==================================================================
    --Observação:  A cada 7 dias 
	1)  Analize de indices duplicados
	2)  Analize de indices ineficientes
	3) Criação das statisticas Colunares
     
    -- ==================================================================
    */

        --Somente aos Sabados
        IF(@DayOfWeek = 7)
            BEGIN
                SET @StartTime = GETDATE();

                /*Cria os Statisticas Colunares de tabelas que foram acessados pelos indices*/
                EXEC HealthCheck.uspAutoManegerStats @MostrarStatistica = @Visualizar, -- bit
                                                     @Efetivar = @Efetivar,            -- bit
                                                     @NumberLinesToDetermineFullScan = @NumberLinesToDetermineFullScan;

                INSERT INTO @TableLogs
                VALUES(   'HealthCheck.uspInefficientIndex', -- NomeProcedure - varchar(200)
                          @StartTime,                        -- DataInicio - datetime
                          GETDATE()                          -- DataTermino - datetime
                      );
            END;

        --Somente Domingos
        IF(@DayOfWeek = 1)
            BEGIN
                SET @StartTime = GETDATE();

                EXEC HealthCheck.uspDeleteDuplicateIndex @Efetivar = @Efetivar,                              -- bit
                                                         @MostrarIndicesDuplicados = @Visualizar,
                                                         @MostrarIndicesMarcadosParaDeletar = @Visualizar,   -- bit
                                                         @QuantidadeDiasAnalizados = @NumberOfDaysAnalyzedsForDuplicateIndexs,
                                                         @TaxaDeSeguranca = @PercOfSafetyForDuplicateIndexs; -- Não deletar indices com acesso superior a 10 % mesmo duplicado(é necessário uma analise individual)

                INSERT INTO @TableLogs
                VALUES(   'HealthCheck.uspDeleteDuplicateIndex', -- NomeProcedure - varchar(200)
                          @StartTime,                            -- DataInicio - datetime
                          GETDATE()                              -- DataTermino - datetime
                      );

                SET @StartTime = GETDATE();

                /*Executa de analize  eficiencia de indices*/
                EXEC HealthCheck.uspInefficientIndex @percentualAproveitamento = @PercAccessForInefficientIndex,          --  (Acesso <= 9 %) smallint
                                                     @EfetivarDelecao = @Efetivar,                                        -- bit
                                                     @NumberOfDaysForInefficientIndex = @NumberOfDaysForInefficientIndex, -- smallint  (7 dias)
                                                     @MostrarIndiceIneficiente = @Visualizar;                             -- bit

                INSERT INTO @TableLogs
                VALUES(   'HealthCheck.uspInefficientIndex', -- NomeProcedure - varchar(200)
                          @StartTime,                        -- DataInicio - datetime
                          GETDATE()                          -- DataTermino - datetime
                      );

                SET @StartTime = GETDATE();

                /* Desfragmento dos indices */
                EXEC HealthCheck.uspIndexDesfrag @MostrarIndices = @Visualizar,                         -- bit
                                                 @MinFrag = @PercMinFragmentation,                      -- smallint
                                                 @MinPageCount = @QuantityPagesOfAnalyzedFragmentation, -- smallint
                                                 @Efetivar = @Efetivar;                                 -- bit

                INSERT INTO @TableLogs
                VALUES(   'HealthCheck.uspIndexDesfrag', -- NomeProcedure - varchar(200)
                          @StartTime,                    -- DataInicio - datetime
                          GETDATE()                      -- DataTermino - datetime
                      );
            END;

        /* ==================================================================
    --Observação:  A cada 30 dias 
	1)  Analise de indices não usados
	
    -- ==================================================================
    */
        IF(DATEDIFF(DAY, @DataStartMonitoracao, @DiaExecucao) % @Modulo3 = 0)
            BEGIN
                SET @StartTime = GETDATE();

                /*Deletar os indices que não estão sendo usados pelo otimizador por mais de X dias*/
                EXEC HealthCheck.uspUnusedIndex @EfetivarDelecao = @Efetivar,                                   -- bit
                                                @QuantidadeDiasConfigurado = @NumberOfDaysForIndexNoUsageIndex, -- smallint (30 dias)
                                                @MostrarIndice = @Visualizar;                                   -- bit

                INSERT INTO @TableLogs
                VALUES(   'HealthCheck.uspUnusedIndex', -- NomeProcedure - varchar(200)
                          @StartTime,                   -- DataInicio - datetime
                          GETDATE()                     -- DataTermino - datetime
                      );
            END;

        EXEC HealthCheck.uspSnapShotClear @diasExpurgo = @NumberOfDaysForClear; -- smallint

        SELECT * FROM @TableLogs;
    END;
GO