CREATE OR ALTER PROCEDURE HealthCheck.uspAutoHealthCheck
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

--DECLARE @Efetivar                                BIT      = 1,
--        @Visualizar                              BIT      = 1,
--        @DiaExecucao                             DATETIME = GETDATE(),
--        @TableRowsInUpdateStats                  INT      = 1000,
--        @NumberLinesToDetermineFullScan          INT      = 10000,
--        @NumberOfDaysAnalyzedsForDuplicateIndexs TINYINT  = 7,
--        @PercOfSafetyForDuplicateIndexs          TINYINT  = 10,
--        @NumberOfDaysForInefficientIndex         TINYINT  = 7,
--        @PercAccessForInefficientIndex           TINYINT  = 9,
--        @PercMinFragmentation                    TINYINT  = 10,
--        @QuantityPagesOfAnalyzedFragmentation    SMALLINT = 1000,
--        @DefaultTunningPerform                   SMALLINT = 500;
SET @DiaExecucao = ISNULL(@DiaExecucao, GETDATE());

DECLARE @TableLogs TABLE
(
    NomeProcedure VARCHAR(200),
    DataInicio    DATETIME,
    DataTermino   DATETIME,
    Mensagem      AS CONCAT(NomeProcedure, SPACE(2), 'Tempo Decorrido:', DATEDIFF(MILLISECOND, DataInicio, DataTermino), ' MS')
);

DECLARE @ConfiguracaoHabilitarAutoHealthCheck BIT = (
                                                        SELECT CAST(C.Valor AS BIT)
                                                          FROM Sistema.Configuracoes AS C
                                                         WHERE
                                                            C.Configuracao = 'HabilitarAutoHealthCheck'
                                                    );



/* ==================================================================
	Data: 11/16/2020 
	Autor :Wesley Neves
	Observa��o: Altera o Nivel de Isolamento do banco de dados para READ_COMMITTED_SNAPSHOT
	 
	 ==================================================================
	*/
IF(EXISTS (
              SELECT s.name,
                     CASE s.is_read_committed_snapshot_on WHEN 1 THEN 'ENABLED'
                     WHEN 0 THEN 'DISABLED' END AS 'READ_COMMITTED_SNAPSHOT'
                FROM sys.databases s
               WHERE
                  s.name = DB_NAME()
                  AND s.is_read_committed_snapshot_on = 0
          )
  )
    BEGIN
        DECLARE @Script NVARCHAR(1000) = '';

        SET @Script = CONCAT('ALTER DATABASE [', DB_NAME(), '] SET READ_COMMITTED_SNAPSHOT ON WITH ROLLBACK IMMEDIATE ');

        EXEC(@Script);
    END;

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

DECLARE @DayOfWeek TINYINT = (
                                 SELECT DATEPART(WEEKDAY, GETDATE())
                             );
DECLARE @DataUltimaExecucao DATE = (
                                       SELECT TOP 1 ISNULL(A.DataUltimaExecucao, A.DataInicio)
                                         FROM HealthCheck.AcoesPeriodicidadeDias AS A
                                        WHERE
                                           A.Nome = 'AtualizarStatisticas'
                                   );

SET @DataUltimaExecucao = ISNULL(@DataUltimaExecucao, CAST(GETDATE() AS DATE));

IF(@ConfiguracaoHabilitarAutoHealthCheck = 1)
    BEGIN
        DECLARE @StartTime DATETIME;
        DECLARE @AtualizarStatisticas BIT = CAST((
                                                     SELECT TOP 1 1
                                                       FROM HealthCheck.AcoesPeriodicidadeDias AS A
                                                      WHERE
                                                         A.Nome = 'AtualizarStatisticas'
                                                         AND A.Ativo = 1
                                                 ) AS BIT);
        DECLARE @CriarIndicesAutomaticamente BIT = CAST((
                                                            SELECT TOP 1 1
                                                              FROM HealthCheck.AcoesPeriodicidadeDias AS A
                                                             WHERE
                                                                A.Nome = 'CriarIndicesAutomaticamente'
                                                                AND A.Ativo = 1
                                                        ) AS BIT);
        DECLARE @CriarStatisticasColunas BIT = CAST((
                                                        SELECT TOP 1 1
                                                          FROM HealthCheck.AcoesPeriodicidadeDias AS A
                                                         WHERE
                                                            A.Nome = 'CriarStatisticasColunas'
                                                            AND A.Ativo = 1
                                                    ) AS BIT);
        DECLARE @DeletarIndicesDuplicados BIT = CAST((
                                                         SELECT TOP 1 1
                                                           FROM HealthCheck.AcoesPeriodicidadeDias AS A
                                                          WHERE
                                                             A.Nome = 'DeletarIndicesDuplicados'
                                                             AND A.Ativo = 1
                                                     ) AS BIT);
        DECLARE @AnalisarIndicesIneficientes BIT = CAST((
                                                            SELECT TOP 1 1
                                                              FROM HealthCheck.AcoesPeriodicidadeDias AS A
                                                             WHERE
                                                                A.Nome = 'AnalisarIndicesIneficientes'
                                                                AND A.Ativo = 1
                                                        ) AS BIT);
        DECLARE @DesfragmentacaoIndices BIT = CAST((
                                                       SELECT TOP 1 1
                                                         FROM HealthCheck.AcoesPeriodicidadeDias AS A
                                                        WHERE
                                                           A.Nome = 'DesfragmentacaoIndices'
                                                           AND A.Ativo = 1
                                                   ) AS BIT);
        DECLARE @DeletarIndicesNaoUsados BIT = CAST((
                                                        SELECT TOP 1 1
                                                          FROM HealthCheck.AcoesPeriodicidadeDias AS A
                                                         WHERE
                                                            A.Nome = 'DeletarIndicesNaoUsados'
                                                            AND A.Ativo = 1
                                                    ) AS BIT);
        DECLARE @EfetuarShrinkDatabase BIT = CAST((
                                                      SELECT TOP 1 1
                                                        FROM HealthCheck.AcoesPeriodicidadeDias AS A
                                                       WHERE
                                                          A.Nome = 'ShrinkDatabase'
                                                          AND A.Ativo = 1
                                                  ) AS BIT);
        DECLARE @ExpurgarElmah BIT = CAST((
                                              SELECT TOP 1 1
                                                FROM HealthCheck.AcoesPeriodicidadeDias AS A
                                               WHERE
                                                  A.Nome = 'ExpurgarElmah'
                                                  AND A.Ativo = 1
                                          ) AS BIT);
        DECLARE @ExpurgarLogs BIT = CAST((
                                             SELECT TOP 1 1
                                               FROM HealthCheck.AcoesPeriodicidadeDias AS A
                                              WHERE
                                                 A.Nome = 'ExpurgarLogs'
                                                 AND A.Ativo = 1
                                         ) AS BIT);
        DECLARE @DeletarArquivosAnexosOrfaos BIT = CAST((
                                                            SELECT TOP 1 1
                                                              FROM HealthCheck.AcoesPeriodicidadeDias AS A
                                                             WHERE
                                                                A.Nome = 'DeletarArquivosAnexosOrfaos'
                                                                AND A.Ativo = 1
                                                        ) AS BIT);
        DECLARE @DeletarLogsDuplicados BIT = CAST((
                                                      SELECT TOP 1 1
                                                        FROM HealthCheck.AcoesPeriodicidadeDias AS A
                                                       WHERE
                                                          A.Nome = 'DeletarLogsDuplicados'
                                                          AND A.Ativo = 1
                                                  ) AS BIT);
        DECLARE @PeriodicidadeEfetuarShrinkDatabase SMALLINT = (
                                                                   SELECT TOP 1 A.Periodicidade
                                                                     FROM HealthCheck.AcoesPeriodicidadeDias AS A
                                                                    WHERE
                                                                       A.Nome = 'ShrinkDatabase'
                                                                       AND A.Ativo = 1
                                                               );
        DECLARE @PeriodicidadeExpurgarElmah SMALLINT = (
                                                           SELECT TOP 1 A.Periodicidade
                                                             FROM HealthCheck.AcoesPeriodicidadeDias AS A
                                                            WHERE
                                                               A.Nome = 'ExpurgarElmah'
                                                               AND A.Ativo = 1
                                                       );
        DECLARE @PeriodicidadeDeletarIndicesDuplicados SMALLINT = (
                                                                      SELECT TOP 1 A.Periodicidade
                                                                        FROM HealthCheck.AcoesPeriodicidadeDias AS A
                                                                       WHERE
                                                                          A.Nome = 'DeletarIndicesDuplicados'
                                                                          AND A.Ativo = 1
                                                                  );
        DECLARE @PeriodicidadeDesfragmentacaoIndices SMALLINT = (
                                                                    SELECT TOP 1 A.Periodicidade
                                                                      FROM HealthCheck.AcoesPeriodicidadeDias AS A
                                                                     WHERE
                                                                        A.Nome = 'DesfragmentacaoIndices'
                                                                        AND A.Ativo = 1
                                                                );
        DECLARE @PeriodicidadeAnalisarIndicesIneficientes SMALLINT = (
                                                                         SELECT TOP 1 A.Periodicidade
                                                                           FROM HealthCheck.AcoesPeriodicidadeDias AS A
                                                                          WHERE
                                                                             A.Nome = 'AnalisarIndicesIneficientes'
                                                                             AND A.Ativo = 1
                                                                     );
        DECLARE @PeriodicidadeDeletarIndicesNaoUsados SMALLINT = (
                                                                     SELECT TOP 1 A.Periodicidade
                                                                       FROM HealthCheck.AcoesPeriodicidadeDias AS A
                                                                      WHERE
                                                                         A.Nome = 'DeletarIndicesNaoUsados'
                                                                         AND A.Ativo = 1
                                                                 );

        /* ==================================================================
	--Data: 9/2/2020 
	--Autor :Wesley Neves
	--Observa��o: guarda o tamanho do banco de dados
	 
	-- ==================================================================
	*/
        IF(EXISTS (SELECT * FROM sys.procedures AS P WHERE P.name = 'GetSizeDB'))
            BEGIN
                SET @StartTime = GETDATE();

                EXEC HealthCheck.GetSizeDB;

                INSERT INTO @TableLogs
                VALUES(   'HealthCheck.GetSizeDB', -- NomeProcedure - varchar(200)
                          @StartTime,              -- DataInicio - datetime
                          GETDATE()                -- DataTermino - datetime
                      );
            END;

        /* ==================================================================
			  --Data: 9/4/2020 
			  --Autor :Wesley Neves
			  --Observa��o: Efetua ShrinkDatabase o somente a cadas 15 dias no domingo
			   
			  -- ==================================================================
			  */
        IF(@DayOfWeek = 1)
            BEGIN
                IF(
                      @EfetuarShrinkDatabase = 1
                      AND DATEDIFF(DAY, @DataUltimaExecucao, @DiaExecucao) >= @PeriodicidadeEfetuarShrinkDatabase
                  )
                    BEGIN
                        IF(EXISTS (
                                      SELECT * FROM sys.procedures AS P WHERE P.name = 'uspExecutaShrink'
                                  )
                          )
                            BEGIN
                                SET @StartTime = GETDATE();

                                EXEC HealthCheck.uspExecutaShrink;

                                INSERT INTO @TableLogs
                                VALUES(   'HealthCheck.uspExecutaShrink', -- NomeProcedure - varchar(200)
                                          @StartTime,                     -- DataInicio - datetime
                                          GETDATE()                       -- DataTermino - datetime
                                      );

                                UPDATE HealthCheck.AcoesPeriodicidadeDias
                                   SET DataUltimaExecucao = GETDATE()
                                 WHERE
                                    Nome = 'ShrinkDatabase';
                            END;
                    END;
            END;

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
                IF(EXISTS (
                              SELECT * FROM sys.procedures AS P WHERE P.name = 'uspSnapShotIndex'
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
            END;

        /* ==================================================================
	 --Data: 9/3/2020 
	 --Autor :Wesley Neves
	 --Rotinas diarias
	
	 -- Deleta Statisticas duplicadas dos objetos
	 -- Atualizar Statisticas quando necess�rio
	 --Criar Indices autom�ticos
	 --Criar statisticas de colunas

	  
	 -- ==================================================================
	 */
        IF(@AtualizarStatisticas = 1)
            BEGIN
                IF(EXISTS (
                              SELECT *
                                FROM sys.procedures AS P
                               WHERE
                                  P.name = 'uspDeleteOverlappingStats'
                          )
                  )
                    BEGIN
                        SET @StartTime = GETDATE();

                        EXEC HealthCheck.uspDeleteOverlappingStats @MostarStatisticas = @Visualizar, -- bit
                                                                   @Executar = @Efetivar;            -- bit

                        INSERT INTO @TableLogs
                        VALUES(   'HealthCheck.uspDeleteOverlappingStats', -- NomeProcedure - varchar(200)
                                  @StartTime,                              -- DataInicio - datetime
                                  GETDATE()                                -- DataTermino - datetime
                              );
                    END;

                IF(EXISTS (
                              SELECT * FROM sys.procedures AS P WHERE P.name = 'uspUpdateStats'
                          )
                  )
                    BEGIN
                        SET @StartTime = GETDATE();

                        /*Atualiza Statisticas Necess�rias (diario)*/
                        EXEC HealthCheck.uspUpdateStats @MostarStatisticas = @Visualizar, -- bit
                                                        @ExecutarAtualizacao = @Efetivar, -- bit
                                                        @TableRowsInUpdateStats = 1000,
                                                        @NumberLinesToDetermineFullScan = @NumberLinesToDetermineFullScan;

                        INSERT INTO @TableLogs
                        VALUES(   'HealthCheck.uspUpdateStats', -- NomeProcedure - varchar(200)
                                  @StartTime,                   -- DataInicio - datetime
                                  GETDATE()                     -- DataTermino - datetime
                              );

                        UPDATE HealthCheck.AcoesPeriodicidadeDias
                           SET DataUltimaExecucao = GETDATE()
                         WHERE
                            Nome = 'AtualizarStatisticas';
                    END;
            END;

        IF(@CriarIndicesAutomaticamente = 1)
            BEGIN
                IF(EXISTS (
                              SELECT * FROM sys.procedures AS P WHERE P.name = 'uspAutoCreateIndex'
                          )
                  )
                    BEGIN
                        SET @StartTime = GETDATE();

                        /*Cria Automaticamente Missing Index (diario)*/
                        EXEC HealthCheck.uspAutoCreateIndex @Efetivar = @Efetivar,            -- bit
                                                            @VisualizarMissing = @Visualizar, -- bit
                                                            @DefaultTunningPerform = @DefaultTunningPerform;

                        INSERT INTO @TableLogs
                        VALUES(   'HealthCheck.uspAutoCreateIndex', -- NomeProcedure - varchar(200)
                                  @StartTime,                       -- DataInicio - datetime
                                  GETDATE()                         -- DataTermino - datetime
                              );

                        UPDATE HealthCheck.AcoesPeriodicidadeDias
                           SET DataUltimaExecucao = GETDATE()
                         WHERE
                            Nome = 'CriarIndicesAutomaticamente';
                    END;
            END;

        IF(@CriarStatisticasColunas = 1)
            BEGIN
                IF(EXISTS (
                              SELECT * FROM sys.procedures AS P WHERE P.name = 'uspAutoCreateStats'
                          )
                  )
                    BEGIN
                        SET @StartTime = GETDATE();

                        /*Cria os Statisticas Colunares de tabelas que foram acessados pelos indices*/
                        EXEC HealthCheck.uspAutoCreateStats @MostrarStatistica = @Visualizar, -- bit
                                                            @Efetivar = @Efetivar,            -- bit
                                                            @NumberLinesToDetermineFullScan = 10000;

                        INSERT INTO @TableLogs
                        VALUES(   'HealthCheck.uspAutoCreateStats', -- NomeProcedure - varchar(200)
                                  @StartTime,                       -- DataInicio - datetime
                                  GETDATE()                         -- DataTermino - datetime
                              );

                        UPDATE HealthCheck.AcoesPeriodicidadeDias
                           SET DataUltimaExecucao = GETDATE()
                         WHERE
                            Nome = 'CriarStatisticasColunas';
                    END;
            END;

        /* ==================================================================
		--Data: 9/3/2020 
		--Autor :Wesley Neves
		--Observa��o: Rotina pra domingo
		 
		-- ==================================================================
		*/
        IF(@DayOfWeek = 1)
            BEGIN
                IF(
                      @DeletarIndicesDuplicados = 1
                      AND DATEDIFF(DAY, @DataUltimaExecucao, @DiaExecucao) >= @PeriodicidadeDeletarIndicesDuplicados
                  )
                    BEGIN
                        IF(EXISTS (
                                      SELECT * FROM sys.procedures AS P WHERE P.name = 'uspDeleteDuplicateIndex'
                                  )
                          )
                            BEGIN
                                SET @StartTime = GETDATE();

                                EXEC HealthCheck.uspDeleteDuplicateIndex @Efetivar = @Efetivar,                            -- bit
                                                                         @MostrarIndicesDuplicados = @Visualizar,
                                                                         @MostrarIndicesMarcadosParaDeletar = @Visualizar, -- bit
                                                                         @QuantidadeDiasAnalizados = @NumberOfDaysAnalyzedsForDuplicateIndexs,
                                                                         @TaxaDeSeguranca = 10;                            -- N�o deletar indices com acesso superior a 10 % mesmo duplicado(� necess�rio uma analise individual)

                                INSERT INTO @TableLogs
                                VALUES(   'HealthCheck.uspDeleteDuplicateIndex', -- NomeProcedure - varchar(200)
                                          @StartTime,                            -- DataInicio - datetime
                                          GETDATE()                              -- DataTermino - datetime
                                      );

                                UPDATE HealthCheck.AcoesPeriodicidadeDias
                                   SET DataUltimaExecucao = GETDATE()
                                 WHERE
                                    Nome = 'DeletarIndicesDuplicados';
                            END;
                    END;

                --Somente Domingos
                IF(
                      @AnalisarIndicesIneficientes = 1
                      AND DATEDIFF(DAY, @DataUltimaExecucao, @DiaExecucao) >= @PeriodicidadeAnalisarIndicesIneficientes
                  )
                    BEGIN
                        IF(EXISTS (
                                      SELECT * FROM sys.procedures AS P WHERE P.name = 'uspInefficientIndex'
                                  )
                          )
                            BEGIN
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

                                UPDATE HealthCheck.AcoesPeriodicidadeDias
                                   SET DataUltimaExecucao = GETDATE()
                                 WHERE
                                    Nome = 'AnalisarIndicesIneficientes';
                            END;
                    END;

                IF(
                      @DesfragmentacaoIndices = 1
                      AND DATEDIFF(DAY, @DataUltimaExecucao, @DiaExecucao) >= @PeriodicidadeDesfragmentacaoIndices
                  )
                    BEGIN
                        IF(EXISTS (
                                      SELECT * FROM sys.procedures AS P WHERE P.name = 'uspIndexDesfrag'
                                  )
                          )
                            BEGIN
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

                                UPDATE HealthCheck.AcoesPeriodicidadeDias
                                   SET DataUltimaExecucao = GETDATE()
                                 WHERE
                                    Nome = 'DesfragmentacaoIndices';
                            END;
                    END;
            END;

        /* ==================================================================
    --Observa��o:  A cada 30 dias 
	1)  Analise de indices n�o usados
	
    -- ==================================================================
    */
        IF(
              @DeletarIndicesNaoUsados = 1
              AND DATEDIFF(DAY, @DataUltimaExecucao, @DiaExecucao) >= @PeriodicidadeDeletarIndicesNaoUsados
          )
            BEGIN
                IF(EXISTS (
                              SELECT * FROM sys.procedures AS P WHERE P.name = 'uspUnusedIndex'
                          )
                  )
                    BEGIN
                        SET @StartTime = GETDATE();

                        /*Deletar os indices que n�o est�o sendo usados pelo otimizador por mais de X dias*/
                        EXEC HealthCheck.uspUnusedIndex @EfetivarDelecao = @Efetivar,                                       -- bit
                                                        @QuantidadeDiasConfigurado = @PeriodicidadeDeletarIndicesNaoUsados, -- smallint (30 dias)
                                                        @MostrarIndice = @Visualizar;                                       -- bit

                        INSERT INTO @TableLogs
                        VALUES(   'HealthCheck.uspUnusedIndex', -- NomeProcedure - varchar(200)
                                  @StartTime,                   -- DataInicio - datetime
                                  GETDATE()                     -- DataTermino - datetime
                              );

                        UPDATE HealthCheck.AcoesPeriodicidadeDias
                           SET DataUltimaExecucao = GETDATE()
                         WHERE
                            Nome = 'DeletarIndicesNaoUsados';
                    END;
            END;

        EXEC HealthCheck.uspSnapShotClear @diasExpurgo = @PeriodicidadeDeletarIndicesNaoUsados; -- smallint

        IF(@ExpurgarElmah = 1)
            BEGIN
                DECLARE @DataUltimaExecucaoExpurgoElmah DATE = (
                                                                   SELECT TOP 1 ISNULL(APD.DataUltimaExecucao, APD.DataInicio)
                                                                     FROM HealthCheck.AcoesPeriodicidadeDias AS APD
                                                                    WHERE
                                                                       APD.Nome = 'ExpurgarElmah'
                                                                       AND APD.Ativo = 1
                                                               );

                IF(DATEDIFF(DAY, @DataUltimaExecucaoExpurgoElmah, @DiaExecucao) >= @PeriodicidadeExpurgarElmah)
                    BEGIN
                        IF(EXISTS (SELECT * FROM sys.procedures AS P WHERE P.name = 'ExpurgarElmah'))
                            BEGIN
                                SET @StartTime = GETDATE();

                                EXEC HealthCheck.ExpurgarElmah;

                                INSERT INTO @TableLogs
                                VALUES(   'HealthCheck.ExpurgarElmah', -- NomeProcedure - varchar(200)
                                          @StartTime,                  -- DataInicio - datetime
                                          GETDATE()                    -- DataTermino - datetime
                                      );

                                UPDATE HealthCheck.AcoesPeriodicidadeDias
                                   SET DataUltimaExecucao = GETDATE()
                                 WHERE
                                    Nome = 'ExpurgarElmah';
                            END;
                    END;
            END;

        IF(@ExpurgarLogs = 1)
            BEGIN
                IF(EXISTS (
                              SELECT * FROM sys.procedures AS P WHERE P.name = 'uspExpurgoLogsJson'
                          )
                  )
                    BEGIN
                        SET @StartTime = GETDATE();

                        EXEC Log.uspExpurgoLogsJson;

                        INSERT INTO @TableLogs
                        VALUES(   'Log.uspExpurgoLogsJson', -- NomeProcedure - varchar(200)
                                  @StartTime,               -- DataInicio - datetime
                                  GETDATE()                 -- DataTermino - datetime
                              );

                        UPDATE HealthCheck.AcoesPeriodicidadeDias
                           SET DataUltimaExecucao = GETDATE()
                         WHERE
                            Nome = 'ExpurgarLogs';
                    END;
            END;

        IF(@DeletarArquivosAnexosOrfaos = 1)
            BEGIN
                IF(EXISTS (
                              SELECT *
                                FROM sys.procedures AS P
                               WHERE
                                  P.name = 'uspDeletarArquivosAnexosOrfaos'
                          )
                  )
                    BEGIN

						SET @StartTime = GETDATE();

                        EXEC HealthCheck.uspDeletarArquivosAnexosOrfaos @Visualizar = 0, -- bit
                                                                        @Deletar = 1;    -- bit


				

					

						INSERT INTO @TableLogs
						VALUES(   'HealthCheck.uspDeletarArquivosAnexosOrfaos', -- NomeProcedure - varchar(200)
									@StartTime,               -- DataInicio - datetime
									GETDATE()                 -- DataTermino - datetime
								);
                    END;
            END;

        IF(@DeletarLogsDuplicados = 1)
            BEGIN
                IF(EXISTS (
                              SELECT *
                                FROM sys.procedures AS P
                               WHERE
                                  P.name = 'uspDeletarLogsDuplicados'
                          )
                  )
                    BEGIN

							SET @StartTime = GETDATE();

                        EXEC HealthCheck.uspDeletarLogsDuplicados @Visualizar = 0, -- bit
                                                                  @Deletar = 1;    -- bit

						INSERT INTO @TableLogs
						VALUES(   'HealthCheck.uspDeletarArquivosAnexosOrfaos', -- NomeProcedure - varchar(200)
									@StartTime,               -- DataInicio - datetime
									GETDATE()                 -- DataTermino - datetime
								);

                    END;
            END;
    END;
GO