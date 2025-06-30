
CREATE OR ALTER PROCEDURE HealthCheck.uspExpurgarLogs
( 
    @ProcessarApenasUmaFase BIT = 1, -- 0 = Todas as fases, 1 = Apenas uma fase
    @FaseProcessar TINYINT = 1, -- -- 1=Deletar Antigos, 2=Migrar, 3=Expurgar
    @LimiteMaximoPorFase INT = 5000000
)
AS
BEGIN

     -- Configurações otimizadas para Azure SQL Database
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
    SET LOCK_TIMEOUT 1800000; -- 30 minutos
    SET DEADLOCK_PRIORITY LOW;

    -- CONFIGURAÇÃO DE EXECUÇÃO POR FASES
    --DECLARE @ProcessarApenasUmaFase BIT = 0; -- 0 = Todas as fases, 1 = Apenas uma fase
    --DECLARE @FaseProcessar TINYINT = 1; -- 1=Deletar Antigos, 2=Migrar, 3=Expurgar

    ---- LIMITE MÁXIMO POR FASE - NOVO CONTROLE
    --DECLARE @LimiteMaximoPorFase INT = 5000000; -- 5 milhão por execução

    -- Configurações otimizadas
    DECLARE @QuantidadeMesesDeletarLogs INT = 12;
    DECLARE @QuantidadeMesesExpurgarLogs INT = (@QuantidadeMesesDeletarLogs * 2);
    DECLARE @BatchSize INT = 25000; -- Tamanho do lote

    DECLARE @PrimeiroDiaMes DATE = DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1);
    DECLARE @DataTheSholdMigrateLogs DATE = DATEADD(MONTH, - (@QuantidadeMesesDeletarLogs), @PrimeiroDiaMes);
    DECLARE @DataTheSholdDeleteExpurgo DATE = DATEADD(MONTH, - (@QuantidadeMesesExpurgarLogs), @PrimeiroDiaMes);

    -- Verificar configurações do sistema
    DECLARE @QtdMesExpurgoLogsAuditoria TINYINT =
            (
                SELECT TOP 1
                       C.Valor
                FROM Sistema.Configuracoes AS C
                WHERE C.Configuracao = 'QtdMesExpurgoLogsAuditoria'
            );

    IF (@QtdMesExpurgoLogsAuditoria <= @QuantidadeMesesDeletarLogs)
    BEGIN
        UPDATE C
        SET C.Valor = @QuantidadeMesesDeletarLogs
        FROM Sistema.Configuracoes AS C
        WHERE C.Configuracao = 'QtdMesExpurgoLogsAuditoria';
    END;
    ELSE
    BEGIN
        SET @QuantidadeMesesDeletarLogs = @QtdMesExpurgoLogsAuditoria;
        SET @DataTheSholdMigrateLogs = DATEADD(MONTH, - (@QuantidadeMesesDeletarLogs), @PrimeiroDiaMes);
    END;

    -- Análise inicial para determinar qual fase executar
    RAISERROR('=== ANÁLISE INICIAL ===', 0, 1) WITH NOWAIT;
    DECLARE @MsgDataMigracao VARCHAR(100)
        = 'Data limite migração: ' + CONVERT(VARCHAR(10), @DataTheSholdMigrateLogs, 120);
    RAISERROR(@MsgDataMigracao, 0, 1) WITH NOWAIT;
    DECLARE @MsgDataExclusao VARCHAR(100)
        = 'Data limite exclusão: ' + CONVERT(VARCHAR(10), @DataTheSholdDeleteExpurgo, 120);
    RAISERROR(@MsgDataExclusao, 0, 1) WITH NOWAIT;

    DECLARE @quantidadeLogsDeletarExpurgo INT =
            (
                SELECT COUNT(1)
                FROM Expurgo.LogsJson
                WHERE Data <= @DataTheSholdDeleteExpurgo
            );

    DECLARE @quantidadeLogsDeletarLogs INT =
            (
                SELECT COUNT(1)
                FROM Log.LogsJson
                WHERE Data <= @DataTheSholdDeleteExpurgo
            );

    DECLARE @quantidadeLogsMigrarLogs INT =
            (
                SELECT COUNT(1)
                FROM Log.LogsJson
                WHERE Data <= @DataTheSholdMigrateLogs
                      AND Data > @DataTheSholdDeleteExpurgo
            );



    DECLARE @MsgMigrar VARCHAR(100) = 'Logs para migrar: ' + CAST(@quantidadeLogsMigrarLogs AS VARCHAR(20));
    RAISERROR(@MsgMigrar, 0, 1) WITH NOWAIT;
    DECLARE @MsgDeletar VARCHAR(100) = 'Logs antigos para deletar: ' + CAST(@quantidadeLogsDeletarLogs AS VARCHAR(20));
    RAISERROR(@MsgDeletar, 0, 1) WITH NOWAIT;
    DECLARE @MsgExpurgo VARCHAR(100)
        = 'Logs expurgo para deletar: ' + CAST(@quantidadeLogsDeletarExpurgo AS VARCHAR(20));
    RAISERROR(@MsgExpurgo, 0, 1) WITH NOWAIT;


    DECLARE @DataUltimaExecucaoExpurgo DATE = ISNULL(
                                              (
                                                  SELECT TRY_CAST(Valor AS DATE)
                                                  FROM Sistema.Configuracoes
                                                  WHERE Configuracao = 'DataExecucaoExpurgo'
                                              ),
                                              GETDATE()
                                                    );



    IF (
            @quantidadeLogsDeletarLogs = 0
           AND @quantidadeLogsMigrarLogs = 0
           AND @quantidadeLogsDeletarExpurgo = 0
       )
    BEGIN

        SELECT 'Nenhum processamento necessário.';
        RETURN;
    END
	ELSE
	BEGIN

	DECLARE @Mensagemtexto VARCHAR(500)  ='';

	 IF @quantidadeLogsDeletarLogs > 0
	 BEGIN
		SELECT @Mensagemtexto =  '🗑️ FASE 1 - Quantidade: ' + CAST(@quantidadeLogsDeletarLogs AS VARCHAR(10)) + '';	
	 END
	   IF @quantidadeLogsMigrarLogs > 0
	 BEGIN
		SELECT @Mensagemtexto =  '🗑️ FASE 2 - Quantidade: ' + CAST(@quantidadeLogsMigrarLogs AS VARCHAR(10)) + '';	
	 END
	  IF @quantidadeLogsDeletarExpurgo > 0
	 BEGIN
		SELECT @Mensagemtexto =  '🗑️ FASE 3 - Quantidade: ' + CAST(@quantidadeLogsDeletarExpurgo AS VARCHAR(10)) + '';	
	 END

       RAISERROR(@Mensagemtexto, 0, 1) WITH NOWAIT;
		

	END
    -- Determinar fase automaticamente se não especificado
    IF @ProcessarApenasUmaFase = 0
    BEGIN
        -- Prioridade: 1º Deletar muito antigos, 2º Migrar, 3º Expurgar
        IF @quantidadeLogsDeletarLogs > 0
            SET @FaseProcessar = 1;
        ELSE IF @quantidadeLogsMigrarLogs > 0
            SET @FaseProcessar = 2;
        ELSE IF @quantidadeLogsDeletarExpurgo > 0
            SET @FaseProcessar = 3;
        ELSE
        BEGIN
            SELECT 'Nenhum processamento necessário. Todas as tabelas estão em dia!';
            RETURN;
        END;
    END;



    -- Tabelas de controle
    DROP TABLE IF EXISTS #ProcessamentoResumo;
    CREATE TABLE #ProcessamentoResumo
    (
        Fase VARCHAR(50),
        QuantidadeTotal INT,
        QuantidadeProcessada INT,
        LimiteAtingido BIT
            DEFAULT 0,
        TempoExecucao VARCHAR(20),
        Status VARCHAR(20)
    );

    -- ===================================================
    -- TABELAS TEMPORÁRIAS PARA CONTROLE DE PROCESSAMENTO
    -- ===================================================

    -- Tabela para controlar logs já migrados (máximo 5 milhão para performance)
    DROP TABLE IF EXISTS #LogsMigrados;
    CREATE TABLE #LogsMigrados
    (
        IdLog INT NOT NULL PRIMARY KEY
    );

    -- Tabela para controlar logs já deletados (máximo 1 milhão para performance)
    DROP TABLE IF EXISTS #LogsDeletados;
    CREATE TABLE #LogsDeletados
    (
        IdLog INT NOT NULL PRIMARY KEY
    );

		BEGIN TRY
        DECLARE @RowsAffected INT = 1;
        DECLARE @TotalProcessadoFase INT = 0;
        DECLARE @TempoInicio DATETIME2 = GETDATE();
        DECLARE @ContadorLotes INT = 0;

        RAISERROR('=== INICIANDO PROCESSO DE EXPURGO LIMITADO ===', 0, 1) WITH NOWAIT;
        DECLARE @MsgLimite VARCHAR(100) = 'Limite máximo por execução: ' + CAST(@LimiteMaximoPorFase AS VARCHAR(20));
        RAISERROR(@MsgLimite, 0, 1) WITH NOWAIT;
        DECLARE @MsgFase VARCHAR(50) = 'Fase selecionada: ' + CAST(@FaseProcessar AS VARCHAR(1));
        RAISERROR(@MsgFase, 0, 1) WITH NOWAIT;
        RAISERROR('================================================', 0, 1) WITH NOWAIT;

        -- ===============================================
        -- FASE 1: Deletar logs muito antigos (LIMITADO)
        -- ===============================================
        IF @ProcessarApenasUmaFase = 0
           OR @FaseProcessar = 1
        BEGIN
            RAISERROR('🗑️ === FASE 1: DELETANDO LOGS ANTIGOS (LIMITADO) ===', 0, 1) WITH NOWAIT;

            SET @RowsAffected = 1;
            SET @TotalProcessadoFase = 0;
            SET @ContadorLotes = 0;

            -- Tabela temporária para IDs a deletar da tabela principal
            DROP TABLE IF EXISTS #LogsParaDeletar;
            CREATE TABLE #LogsParaDeletar
            (
                IdLog INT NOT NULL PRIMARY KEY
            );

            ---- Buscar IDs para deletar (limitado)
            INSERT INTO #LogsParaDeletar
            (
                IdLog
            )
			SELECT DISTINCT TOP (@LimiteMaximoPorFase)
                   IdLog
            FROM Log.LogsJson
            WHERE Data < @DataTheSholdDeleteExpurgo
		

            DECLARE @TotalParaDeletar INT = @@ROWCOUNT;
            DECLARE @MsgSelecao VARCHAR(100)
                = 'Registros selecionados para deleção: ' + CAST(@TotalParaDeletar AS VARCHAR(10));
            RAISERROR(@MsgSelecao, 0, 1) WITH NOWAIT;

            -- Deletar da tabela principal com limite usando a nova lógica
            WHILE @RowsAffected > 0 AND EXISTS (SELECT 1 FROM #LogsParaDeletar)
            BEGIN
                -- Limpar tabela de controle para reutilizar
                TRUNCATE TABLE #LogsDeletados;

                -- Inserir IDs do lote atual na tabela de controle
                INSERT INTO #LogsDeletados
                (
                    IdLog
                )
                SELECT TOP (@BatchSize)
                       IdLog
                FROM #LogsParaDeletar
                ORDER BY IdLog;

                -- Deletar usando JOIN com a tabela de controle
                DELETE lj
                FROM Log.LogsJson lj
                    INNER JOIN #LogsDeletados ld
                        ON lj.IdLog = ld.IdLog;

                SET @RowsAffected = @@ROWCOUNT;
                SET @TotalProcessadoFase = @TotalProcessadoFase + @RowsAffected;
                SET @ContadorLotes = @ContadorLotes + 1;

                -- Calcular porcentagem de progresso da Fase 1
                DECLARE @PorcentagemFase1 DECIMAL(5, 2)
                    = CASE
                          WHEN @TotalParaDeletar > 0 THEN
                              CAST(@TotalProcessadoFase AS DECIMAL(10, 2)) / CAST(@TotalParaDeletar AS DECIMAL(10, 2))
                              * 100.0
                          ELSE
                              0
                      END;

                DECLARE @TempoDecorrido INT = DATEDIFF(SECOND, @TempoInicio, GETDATE());
                DECLARE @VelocidadeRegistros DECIMAL(10, 2)
                    = CASE
                          WHEN @TempoDecorrido > 0 THEN
                              CAST(@TotalProcessadoFase AS DECIMAL(10, 2)) / CAST(@TempoDecorrido AS DECIMAL(10, 2))
                          ELSE
                              0
                      END;

                -- Criar barra de progresso visual
                DECLARE @BarraProgresso VARCHAR(50) = '';
                DECLARE @ProgressoCompleto INT = CAST(@PorcentagemFase1 / 2 AS INT); -- Dividir por 2 para caber em 50 caracteres
                DECLARE @i INT = 1;
                WHILE @i <= 50
                BEGIN
                    IF @i <= @ProgressoCompleto
                        SET @BarraProgresso = @BarraProgresso + '█';
                    ELSE
                        SET @BarraProgresso = @BarraProgresso + '░';
                    SET @i = @i + 1;
                END;

                -- LINHA CORRIGIDA (escapando o %):
                DECLARE @MensagemProgresso VARCHAR(500)
                    = '🗑️ FASE 1 - Deletando Logs: ' + CAST(@RowsAffected AS VARCHAR(10)) + ' | Total: '
                      + CAST(@TotalProcessadoFase AS VARCHAR(10)) + ' | Restante: '
                      + CAST(@TotalParaDeletar - @TotalProcessadoFase AS VARCHAR(10)) + ' | Progresso: '
                      + CAST(@PorcentagemFase1 AS VARCHAR(6)) + '%%' + ' | Velocidade: '
                      + CAST(@VelocidadeRegistros AS VARCHAR(10)) + ' reg/s' + ' | Lote: '
                      + CAST(@ContadorLotes AS VARCHAR(10)) + ' | Tempo: ' + CAST(@TempoDecorrido AS VARCHAR(10)) + 's';
                RAISERROR(@MensagemProgresso, 0, 1) WITH NOWAIT;

                DECLARE @MensagemBarra VARCHAR(100)
                    = '[' + @BarraProgresso + '] ' + CAST(@PorcentagemFase1 AS VARCHAR(6)) + '%%';
                RAISERROR(@MensagemBarra, 0, 1) WITH NOWAIT;

                IF @RowsAffected > 0
                BEGIN
                    -- Remover os processados da tabela temporária
                    DELETE a
                    FROM #LogsParaDeletar a
                        JOIN #LogsDeletados b
                            ON b.IdLog = a.IdLog;

                    WAITFOR DELAY '00:00:03';
                END;

                -- Parar se atingiu o limite
                IF @TotalProcessadoFase >= @LimiteMaximoPorFase
                BEGIN
                    RAISERROR('⚠️ LIMITE DE 1M ATINGIDO - Parando Fase 1', 0, 1) WITH NOWAIT;
                    BREAK;
                END;
            END;

            -- Se ainda há espaço no limite, processar tabela de expurgo
            IF @TotalProcessadoFase < @LimiteMaximoPorFase
            BEGIN
                RAISERROR('🗑️ Processando também tabela Expurgo...', 0, 1) WITH NOWAIT;

                DECLARE @LimiteRestanteExpurgo INT = @LimiteMaximoPorFase - @TotalProcessadoFase;

                -- Tabela temporária para IDs a deletar da tabela de expurgo
                DROP TABLE IF EXISTS #ExpurgoParaDeletar;
                CREATE TABLE #ExpurgoParaDeletar
                (
                    IdLog INT NOT NULL PRIMARY KEY
                );

                -- Buscar IDs para deletar do expurgo (limitado ao restante)
                INSERT INTO #ExpurgoParaDeletar
                (
                    IdLog
                )
                SELECT TOP (@LimiteRestanteExpurgo)
                       IdLog
                FROM Expurgo.LogsJson
                WHERE Data < @DataTheSholdDeleteExpurgo
                ORDER BY IdLog;

                DECLARE @TotalExpurgoParaDeletar INT = @@ROWCOUNT;
                DECLARE @MsgExpurgoSel VARCHAR(100)
                    = 'Registros do expurgo selecionados: ' + CAST(@TotalExpurgoParaDeletar AS VARCHAR(10));
                RAISERROR(@MsgExpurgoSel, 0, 1) WITH NOWAIT;

                SET @RowsAffected = 1;
                WHILE @RowsAffected > 0 AND EXISTS (SELECT 1 FROM #ExpurgoParaDeletar)
                BEGIN
                    -- Limpar tabela de controle para reutilizar
                    TRUNCATE TABLE #LogsDeletados;

                    -- Inserir IDs do lote atual na tabela de controle
                    INSERT INTO #LogsDeletados
                    (
                        IdLog
                    )
                    SELECT TOP (@BatchSize)
                           IdLog
                    FROM #ExpurgoParaDeletar
                    ORDER BY IdLog;

                    -- Deletar usando JOIN com a tabela de controle
                    DELETE ej
                    FROM Expurgo.LogsJson ej
                        INNER JOIN #LogsDeletados ld
                            ON ej.IdLog = ld.IdLog;

                    SET @RowsAffected = @@ROWCOUNT;
                    SET @TotalProcessadoFase = @TotalProcessadoFase + @RowsAffected;
                    SET @ContadorLotes = @ContadorLotes + 1;

                    -- Calcular porcentagem de progresso do Expurgo na Fase 1
                    DECLARE @PorcentagemExpurgo DECIMAL(5, 2)
                        = CASE
                              WHEN @TotalExpurgoParaDeletar > 0 THEN
                                  CAST((@TotalProcessadoFase
                                        - (@TotalParaDeletar - (@TotalParaDeletar - @TotalProcessadoFase))
                                       ) AS DECIMAL(10, 2))
                                  / CAST(@TotalExpurgoParaDeletar AS DECIMAL(10, 2)) * 100.0
                              ELSE
                                  0
                          END;

                    DECLARE @TempoDecorridoExpurgo INT = DATEDIFF(SECOND, @TempoInicio, GETDATE());
                    DECLARE @VelocidadeExpurgo DECIMAL(10, 2)
                        = CASE
                              WHEN @TempoDecorridoExpurgo > 0 THEN
                                  CAST(@TotalProcessadoFase AS DECIMAL(10, 2))
                                  / CAST(@TempoDecorridoExpurgo AS DECIMAL(10, 2))
                              ELSE
                                  0
                          END;

                    DECLARE @MensagemExpurgo VARCHAR(500)
                        = '🗑️ FASE 1 - Deletando Expurgo: ' + CAST(@RowsAffected AS VARCHAR(10)) + ' | Total Geral: '
                          + CAST(@TotalProcessadoFase AS VARCHAR(10)) + ' | Restante: '
                          + CAST(@LimiteMaximoPorFase - @TotalProcessadoFase AS VARCHAR(10)) + ' | Progresso Expurgo: '
                          + CAST(@PorcentagemExpurgo AS VARCHAR(6)) + '%%' + ' | Velocidade: '
                          + CAST(@VelocidadeExpurgo AS VARCHAR(10)) + ' reg/s' + ' | Tempo: '
                          + CAST(@TempoDecorridoExpurgo AS VARCHAR(10)) + 's';
                    RAISERROR(@MensagemExpurgo, 0, 1) WITH NOWAIT;

                    IF @RowsAffected > 0
                    BEGIN
                        -- Remover os processados da tabela temporária
                        DELETE a
                        FROM #ExpurgoParaDeletar a
                            JOIN #LogsDeletados b
                                ON b.IdLog = a.IdLog;

                        WAITFOR DELAY '00:00:03';
                    END;

                    IF @TotalProcessadoFase >= @LimiteMaximoPorFase
                    BEGIN
                        PRINT '⚠️ LIMITE DE 1M ATINGIDO - Parando processamento';
                        BREAK;
                    END;
                END;
            END;

            -- Registrar resultado da Fase 1
            INSERT INTO #ProcessamentoResumo
            (
                Fase,
                QuantidadeTotal,
                QuantidadeProcessada,
                LimiteAtingido,
                Status
            )
            VALUES
            (   'FASE1_DELETE', @quantidadeLogsDeletarLogs, @TotalProcessadoFase,
                CASE
                    WHEN @TotalProcessadoFase >= @LimiteMaximoPorFase THEN
                        1
                    ELSE
                        0
                END, 'CONCLUIDO');

            -- Calcular progresso geral da Fase 1
            DECLARE @ProgressoGeralFase1 DECIMAL(5, 2)
                = CASE
                      WHEN (@TotalParaDeletar + ISNULL(@TotalExpurgoParaDeletar, 0)) > 0 THEN
                          CAST(@TotalProcessadoFase AS DECIMAL(10, 2))
                          / CAST((@TotalParaDeletar + ISNULL(@TotalExpurgoParaDeletar, 0)) AS DECIMAL(10, 2)) * 100.0
                      ELSE
                          100.0
                  END;

            PRINT '✅ FASE 1 FINALIZADA - Processados: ' + CAST(@TotalProcessadoFase AS VARCHAR(10))
                  + ' | Progresso Geral: ' + CAST(@ProgressoGeralFase1 AS VARCHAR(6)) + '%%';

            IF @TotalProcessadoFase >= @LimiteMaximoPorFase
                PRINT '⚠️ Execute novamente para continuar o processamento';
        END;

        -- ===============================================
        -- FASE 2: Migrar logs para expurgo (LIMITADO)
        -- ===============================================
        IF (
               @ProcessarApenasUmaFase = 0
               OR @FaseProcessar = 2
           )
           AND @TotalProcessadoFase < @LimiteMaximoPorFase
        BEGIN
            RAISERROR('📦 === FASE 2: MIGRANDO LOGS PARA EXPURGO (LIMITADO) ===', 0, 1) WITH NOWAIT;

            -- ===================================================
            -- CARREGAR TABELA DE CONTROLE DE LOGS JÁ MIGRADOS
            -- ===================================================

            RAISERROR('⏳ Carregando logs já migrados para controle...', 0, 1) WITH NOWAIT;


            DECLARE @LogsMigradosCarregados INT = @@ROWCOUNT;
            DECLARE @MsgCarregados VARCHAR(100)
                = '✅ Logs migrados carregados: ' + CAST(@LogsMigradosCarregados AS VARCHAR(10));
            RAISERROR(@MsgCarregados, 0, 1) WITH NOWAIT;

            -- Tabela temporária para IDs a migrar
            DROP TABLE IF EXISTS #LogsParaMigrar;
            CREATE TABLE #LogsParaMigrar
            (
                IdLog INT NOT NULL PRIMARY KEY,
                Data DATE NOT NULL
            );

            -- Buscar IDs para migrar usando LEFT JOIN (muito mais eficiente que NOT IN)
            INSERT INTO #LogsParaMigrar
            (
                IdLog,
                Data
            )
            SELECT TOP (@LimiteMaximoPorFase)
                   lj.IdLog,
                   lj.Data
            FROM Log.LogsJson lj
                LEFT JOIN #LogsMigrados lm
                    ON lj.IdLog = lm.IdLog -- Usar LEFT JOIN ao invés de NOT IN
            WHERE lj.Data <= @DataTheSholdMigrateLogs
                  AND lj.Data > @DataTheSholdDeleteExpurgo
                  AND lm.IdLog IS NULL -- Registros que NÃO estão na tabela de migrados
            ORDER BY lj.Data,
                     lj.IdLog;

            DECLARE @TotalParaMigrar INT = @@ROWCOUNT;
            DECLARE @MsgMigracao VARCHAR(100)
                = 'Registros selecionados para migração: ' + CAST(@TotalParaMigrar AS VARCHAR(10));
            RAISERROR(@MsgMigracao, 0, 1) WITH NOWAIT;

            IF @TotalParaMigrar > 0
            BEGIN
                SET @RowsAffected = 1;
                DECLARE @TotalMigrados INT = 0;
                DECLARE @ContadorMigracao INT = 0;

                WHILE @RowsAffected > 0 AND EXISTS (SELECT 1 FROM #LogsParaMigrar)
                BEGIN
                    -- Limpar tabela de controle para reutilizar
                    TRUNCATE TABLE #LogsMigrados;

                    -- Inserir IDs do lote atual na tabela de controle
                    INSERT INTO #LogsMigrados
                    (
                        IdLog
                    )
                    SELECT TOP (@BatchSize)
                           IdLog
                    FROM #LogsParaMigrar
                    ORDER BY IdLog;

                    -- Migrar lote usando WHERE IN
                    INSERT INTO Expurgo.LogsJson
                    (
                        IdLog,
                        NomeUsuario,
                        IdEntidade,
                        Entidade,
                        IdLogAntigo,
                        Acao,
                        Data,
                        IdSistemaEspelhamento,
                        IPAdress,
                        Conteudo
                    )
                    SELECT lj.IdLog,
                           lj.NomeUsuario,
                           lj.IdEntidade,
                           lj.Entidade,
                           lj.IdLogAntigo,
                           lj.Acao,
                           lj.Data,
                           lj.IdSistemaEspelhamento,
                           lj.IPAdress,
                           lj.Conteudo
                    FROM Log.LogsJson lj
                    WHERE lj.IdLog IN
                          (
                              SELECT IdLog FROM #LogsMigrados
                          );

                    SET @RowsAffected = @@ROWCOUNT;

                    IF @RowsAffected > 0
                    BEGIN
                        -- Deletar os migrados da tabela original usando JOIN
                        DELETE lj
                        FROM Log.LogsJson lj
                            INNER JOIN #LogsMigrados lpm
                                ON lj.IdLog = lpm.IdLog;

                        -- Remover da tabela temporária usando JOIN
                        DELETE a
                        FROM #LogsParaMigrar a
                            JOIN #LogsMigrados b
                                ON b.IdLog = a.IdLog;

                        SET @TotalMigrados = @TotalMigrados + @RowsAffected;
                        SET @ContadorMigracao = @ContadorMigracao + 1;

                        -- Calcular porcentagem de progresso da Fase 2
                        DECLARE @PorcentagemFase2 DECIMAL(5, 2)
                            = CASE
                                  WHEN @TotalParaMigrar > 0 THEN
                                      CAST(@TotalMigrados AS DECIMAL(10, 2)) / CAST(@TotalParaMigrar AS DECIMAL(10, 2))
                                      * 100.0
                                  ELSE
                                      0
                              END;

                        DECLARE @TempoDecorridoFase2 INT = DATEDIFF(SECOND, @TempoInicio, GETDATE());
                        DECLARE @VelocidadeFase2 DECIMAL(10, 2)
                            = CASE
                                  WHEN @TempoDecorridoFase2 > 0 THEN
                                      CAST(@TotalMigrados AS DECIMAL(10, 2))
                                      / CAST(@TempoDecorridoFase2 AS DECIMAL(10, 2))
                                  ELSE
                                      0
                              END;

                        -- Criar barra de progresso visual para Fase 2
                        DECLARE @BarraProgressoFase2 VARCHAR(50) = '';
                        DECLARE @ProgressoCompletoFase2 INT = CAST(@PorcentagemFase2 / 2 AS INT);
                        DECLARE @j INT = 1;
                        WHILE @j <= 50
                        BEGIN
                            IF @j <= @ProgressoCompletoFase2
                                SET @BarraProgressoFase2 = @BarraProgressoFase2 + '█';
                            ELSE
                                SET @BarraProgressoFase2 = @BarraProgressoFase2 + '░';
                            SET @j = @j + 1;
                        END;

                        DECLARE @MensagemFase2 VARCHAR(500)
                            = '📦 FASE 2 - Migrados: ' + CAST(@RowsAffected AS VARCHAR(10)) + ' | Total: '
                              + CAST(@TotalMigrados AS VARCHAR(10)) + ' | Restante: '
                              + CAST(@TotalParaMigrar - @TotalMigrados AS VARCHAR(10)) + ' | Progresso: '
                              + CAST(@PorcentagemFase2 AS VARCHAR(6)) + '%%' + ' | Velocidade: '
                              + CAST(@VelocidadeFase2 AS VARCHAR(10)) + ' reg/s' + ' | Lote: '
                              + CAST(@ContadorMigracao AS VARCHAR(10)) + ' | Tempo: '
                              + CAST(@TempoDecorridoFase2 AS VARCHAR(10)) + 's';
                        RAISERROR(@MensagemFase2, 0, 1) WITH NOWAIT;

                        DECLARE @MensagemBarraFase2 VARCHAR(100)
                            = '[' + @BarraProgressoFase2 + '] ' + CAST(@PorcentagemFase2 AS VARCHAR(6)) + '%%';
                        RAISERROR(@MensagemBarraFase2, 0, 1) WITH NOWAIT;

                        WAITFOR DELAY '00:00:03';
                    END;
                END;

                SET @TotalProcessadoFase = @TotalProcessadoFase + @TotalMigrados;

                -- Registrar resultado da Fase 2
                INSERT INTO #ProcessamentoResumo
                (
                    Fase,
                    QuantidadeTotal,
                    QuantidadeProcessada,
                    LimiteAtingido,
                    Status
                )
                VALUES
                (   'FASE2_MIGRAR', @quantidadeLogsMigrarLogs, @TotalMigrados,
                    CASE
                        WHEN @TotalMigrados >= @LimiteMaximoPorFase THEN
                            1
                        ELSE
                            0
                    END, 'CONCLUIDO');

                -- Calcular progresso geral da Fase 2
                DECLARE @ProgressoGeralFase2 DECIMAL(5, 2)
                    = CASE
                          WHEN @TotalParaMigrar > 0 THEN
                              CAST(@TotalMigrados AS DECIMAL(10, 2)) / CAST(@TotalParaMigrar AS DECIMAL(10, 2)) * 100.0
                          ELSE
                              100.0
                      END;

                PRINT '✅ FASE 2 FINALIZADA - Migrados: ' + CAST(@TotalMigrados AS VARCHAR(10)) + ' | Progresso Geral: '
                      + CAST(@ProgressoGeralFase2 AS VARCHAR(6)) + '%%';
            END;
            ELSE
            BEGIN
                PRINT '✅ FASE 2: Nenhum registro para migrar';
            END;
        END;

        -- ===============================================
        -- FASE 3: Expurgar logs antigos (LIMITADO)
        -- ===============================================
        IF (
               @ProcessarApenasUmaFase = 0
               OR @FaseProcessar = 3
           )
           AND @TotalProcessadoFase < @LimiteMaximoPorFase
        BEGIN
            RAISERROR('🧹 === FASE 3: EXPURGANDO LOGS ANTIGOS (LIMITADO) ===', 0, 1) WITH NOWAIT;

            DECLARE @LimiteRestanteFase3 INT = @LimiteMaximoPorFase - @TotalProcessadoFase;
            DECLARE @MsgLimiteFase3 VARCHAR(100)
                = 'Limite disponível para expurgo: ' + CAST(@LimiteRestanteFase3 AS VARCHAR(10));
            RAISERROR(@MsgLimiteFase3, 0, 1) WITH NOWAIT;

            SET @RowsAffected = 1;
            DECLARE @TotalExpurgados INT = 0;
            DECLARE @ContadorExpurgo INT = 0;

            -- Tabela temporária para IDs a expurgar
            DROP TABLE IF EXISTS #LogsParaExpurgar;
            CREATE TABLE #LogsParaExpurgar
            (
                IdLog INT NOT NULL PRIMARY KEY
            );

            -- Buscar IDs para expurgar (limitado)
            INSERT INTO #LogsParaExpurgar
            (
                IdLog
            )
            SELECT TOP (@LimiteRestanteFase3)
                   IdLog
            FROM Expurgo.LogsJson
            WHERE Data < @DataTheSholdDeleteExpurgo
            ORDER BY IdLog;

            DECLARE @TotalParaExpurgar INT = @@ROWCOUNT;
            DECLARE @MsgExpurgoSelecionados VARCHAR(100)
                = 'Registros selecionados para expurgo: ' + CAST(@TotalParaExpurgar AS VARCHAR(10));
            RAISERROR(@MsgExpurgoSelecionados, 0, 1) WITH NOWAIT;

            WHILE @RowsAffected > 0 AND EXISTS (SELECT 1 FROM #LogsParaExpurgar)
            BEGIN
                -- Limpar tabela de controle para reutilizar
                TRUNCATE TABLE #LogsDeletados;

                -- Inserir IDs do lote atual na tabela de controle
                INSERT INTO #LogsDeletados
                (
                    IdLog
                )
                SELECT TOP (@BatchSize)
                       IdLog
                FROM #LogsParaExpurgar
                ORDER BY IdLog;

                -- Expurgar usando JOIN com a tabela de controle
                DELETE ej
                FROM Expurgo.LogsJson ej
                    INNER JOIN #LogsDeletados ld
                        ON ej.IdLog = ld.IdLog;

                SET @RowsAffected = @@ROWCOUNT;
                SET @TotalExpurgados = @TotalExpurgados + @RowsAffected;
                SET @ContadorExpurgo = @ContadorExpurgo + 1;

                -- Calcular porcentagem de progresso da Fase 3
                DECLARE @PorcentagemFase3 DECIMAL(5, 2)
                    = CASE
                          WHEN @TotalParaExpurgar > 0 THEN
                              CAST(@TotalExpurgados AS DECIMAL(10, 2)) / CAST(@TotalParaExpurgar AS DECIMAL(10, 2))
                              * 100.0
                          ELSE
                              0
                      END;

                DECLARE @TempoDecorridoFase3 INT = DATEDIFF(SECOND, @TempoInicio, GETDATE());
                DECLARE @VelocidadeFase3 DECIMAL(10, 2)
                    = CASE
                          WHEN @TempoDecorridoFase3 > 0 THEN
                              CAST(@TotalExpurgados AS DECIMAL(10, 2)) / CAST(@TempoDecorridoFase3 AS DECIMAL(10, 2))
                          ELSE
                              0
                      END;

                -- Criar barra de progresso visual para Fase 3
                DECLARE @BarraProgressoFase3 VARCHAR(50) = '';
                DECLARE @ProgressoCompletoFase3 INT = CAST(@PorcentagemFase3 / 2 AS INT);
                DECLARE @k INT = 1;
                WHILE @k <= 50
                BEGIN
                    IF @k <= @ProgressoCompletoFase3
                        SET @BarraProgressoFase3 = @BarraProgressoFase3 + '█';
                    ELSE
                        SET @BarraProgressoFase3 = @BarraProgressoFase3 + '░';
                    SET @k = @k + 1;
                END;

                DECLARE @MensagemFase3 VARCHAR(500)
                    = '🧹 FASE 3 - Expurgados: ' + CAST(@RowsAffected AS VARCHAR(10)) + ' | Total: '
                      + CAST(@TotalExpurgados AS VARCHAR(10)) + ' | Restante: '
                      + CAST(@TotalParaExpurgar - @TotalExpurgados AS VARCHAR(10)) + ' | Progresso: '
                      + CAST(@PorcentagemFase3 AS VARCHAR(6)) + '%' + ' | Velocidade: '
                      + CAST(@VelocidadeFase3 AS VARCHAR(10)) + ' reg/s' + ' | Lote: '
                      + CAST(@ContadorExpurgo AS VARCHAR(10)) + ' | Tempo: '
                      + CAST(@TempoDecorridoFase3 AS VARCHAR(10)) + 's';
                RAISERROR(@MensagemFase3, 0, 1) WITH NOWAIT;

                DECLARE @MensagemBarraFase3 VARCHAR(100)
                    = '[' + @BarraProgressoFase3 + '] ' + CAST(@PorcentagemFase3 AS VARCHAR(6)) + '%';
                RAISERROR(@MensagemBarraFase3, 0, 1) WITH NOWAIT;

                IF @RowsAffected > 0
                BEGIN
                    -- Remover os processados da tabela temporária
                    DELETE a
                    FROM #LogsParaExpurgar a
                        JOIN #LogsDeletados b
                            ON b.IdLog = a.IdLog;

                    WAITFOR DELAY '00:00:03';
                END;

                IF @TotalExpurgados >= @LimiteRestanteFase3
                BEGIN
                    RAISERROR('⚠️ LIMITE ATINGIDO - Parando Fase 3', 0, 1) WITH NOWAIT;
                    BREAK;
                END;
            END;

            SET @TotalProcessadoFase = @TotalProcessadoFase + @TotalExpurgados;

            -- Registrar resultado da Fase 3
            INSERT INTO #ProcessamentoResumo
            (
                Fase,
                QuantidadeTotal,
                QuantidadeProcessada,
                LimiteAtingido,
                Status
            )
            VALUES
            (   'FASE3_EXPURGAR', @quantidadeLogsDeletarExpurgo, @TotalExpurgados,
                CASE
                    WHEN @TotalExpurgados >= @LimiteRestanteFase3 THEN
                        1
                    ELSE
                        0
                END, 'CONCLUIDO');

            -- Calcular progresso geral da Fase 3
            DECLARE @ProgressoGeralFase3 DECIMAL(5, 2)
                = CASE
                      WHEN @TotalParaExpurgar > 0 THEN
                          CAST(@TotalExpurgados AS DECIMAL(10, 2)) / CAST(@TotalParaExpurgar AS DECIMAL(10, 2)) * 100.0
                      ELSE
                          100.0
                  END;

            PRINT '✅ FASE 3 FINALIZADA - Expurgados: ' + CAST(@TotalExpurgados AS VARCHAR(10)) + ' | Progresso Geral: '
                  + CAST(@ProgressoGeralFase3 AS VARCHAR(6)) + '%';
        END;


        -- Atualizar configurações apenas se tudo foi processado
        IF NOT EXISTS (SELECT * FROM #ProcessamentoResumo WHERE LimiteAtingido = 1)
        BEGIN
            DECLARE @NovoDia DATE = DATEADD(MONTH, 1, GETDATE());

            UPDATE Sistema.Configuracoes
            SET Valor = @NovoDia
            WHERE Configuracao = 'DataExecucaoExpurgo';




            UPDATE HealthCheck.AcoesPeriodicidadeDias
            SET DataUltimaExecucao = GETDATE()
            WHERE Nome = 'ExpurgarLogs';

            PRINT '✅ Configurações do sistema atualizadas';
        END;
        ELSE
        BEGIN
            PRINT '⚠️ Configurações NÃO atualizadas - há mais dados para processar';
        END;

        -- Relatório final
        DECLARE @TempoFim DATETIME2 = GETDATE();
        DECLARE @TempoExecucao VARCHAR(20) = CAST(DATEDIFF(SECOND, @TempoInicio, @TempoFim) AS VARCHAR(10)) + 's';

        UPDATE #ProcessamentoResumo
        SET TempoExecucao = @TempoExecucao;

        PRINT '=== RESUMO DA EXECUÇÃO ===';
        PRINT 'Tempo total: ' + @TempoExecucao;
        PRINT 'Total processado: ' + CAST(@TotalProcessadoFase AS VARCHAR(10));
        PRINT 'Limite por execução: ' + CAST(@LimiteMaximoPorFase AS VARCHAR(10));

        -- Verificar se há mais trabalho
        DECLARE @MaisTrabalho BIT = 0;
        IF EXISTS (SELECT 1 FROM #ProcessamentoResumo WHERE LimiteAtingido = 1)
            SET @MaisTrabalho = 1;

        IF @MaisTrabalho = 1
        BEGIN
            PRINT '⚠️ HÁ MAIS DADOS PARA PROCESSAR';
            PRINT '▶️ Execute o script novamente para continuar';
        END;
        ELSE
        BEGIN
            PRINT '✅ PROCESSAMENTO COMPLETO';
            PRINT '✅ Todas as operações foram finalizadas';
        END;

        PRINT '=============================';

        -- Exibir resumo detalhado
        SELECT Fase,
               QuantidadeTotal AS 'Total Identificado',
               QuantidadeProcessada AS 'Processado Agora',
               CASE
                   WHEN LimiteAtingido = 1 THEN
                       'SIM'
                   ELSE
                       'NÃO'
               END AS 'Limite Atingido',
               Status,
               TempoExecucao
        FROM #ProcessamentoResumo
        ORDER BY CASE Fase
                     WHEN 'FASE1_DELETE' THEN
                         1
                     WHEN 'FASE2_MIGRAR' THEN
                         2
                     WHEN 'FASE3_EXPURGAR' THEN
                         3
                 END;

    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorNumber INT = ERROR_NUMBER();
        DECLARE @ErrorLine INT = ERROR_LINE();

        PRINT '❌ === ERRO DETECTADO ===';
        PRINT 'Número: ' + CAST(@ErrorNumber AS VARCHAR(10));
        PRINT 'Linha: ' + CAST(@ErrorLine AS VARCHAR(10));
        PRINT 'Mensagem: ' + @ErrorMessage;
        PRINT '========================';

        -- Mostrar o que foi processado até o erro
        SELECT *
        FROM #ProcessamentoResumo;

        THROW;
    END CATCH;


END;