
CREATE OR ALTER PROCEDURE [HealthCheck].[uspUpdateStats]
(
    @ExecutarAtualizacao BIT = 0,        -- Se 1, executa as atualizações; se 0, apenas mostra o que seria feito
    @ModificationThreshold FLOAT = 0.10, -- Limite de modificações (10% por padrão)
    @DaysSinceLastUpdate INT = 30,       -- Dias desde última atualização
    @MostrarProgresso BIT = 1,           -- Mostrar progresso em percentual
    @ForcarExecucao BIT = 0,             -- Se 1, força execução mesmo em horário comercial
    @MaxParallelism TINYINT = 1,         -- Grau máximo de paralelismo para UPDATE STATISTICS
    @SamplePercent TINYINT = NULL,       -- Percentual de amostragem (NULL = padrão do SQL Server)
    @TimeoutSegundos INT = 300,          -- Timeout em segundos para cada comando
    @LogDetalhado BIT = 1,               -- Se 1, exibe logs detalhados de execução
    @Force BIT = 0                       -- Se 1, permite execução em qualquer horário
)
AS
BEGIN
    SET NOCOUNT ON;

    -- Validação de parâmetros
    IF @ModificationThreshold <= 0
       OR @ModificationThreshold > 1
    BEGIN
        RAISERROR('O parâmetro @ModificationThreshold deve estar entre 0.01 e 1.0', 16, 1);
        RETURN;
    END;

    IF @DaysSinceLastUpdate < 0
    BEGIN
        RAISERROR('O parâmetro @DaysSinceLastUpdate deve ser maior ou igual a 0', 16, 1);
        RETURN;
    END;

    IF @MaxParallelism < 1
       OR @MaxParallelism > 64
    BEGIN
        RAISERROR('O parâmetro @MaxParallelism deve estar entre 1 e 64', 16, 1);
        RETURN;
    END;

    IF @SamplePercent IS NOT NULL
       AND
       (
           @SamplePercent < 1
           OR @SamplePercent > 100
       )
    BEGIN
        RAISERROR('O parâmetro @SamplePercent deve estar entre 1 e 100 ou ser NULL', 16, 1);
        RETURN;
    END;

    /*
    === PROCEDURE OTIMIZADA DE ATUALIZAÇÃO DE ESTATÍSTICAS ===
    
    FUNCIONALIDADES:
    ✓ Identifica estatísticas desatualizadas com base em modificações e idade
    ✓ Sistema de priorização inteligente baseado em múltiplos fatores
    ✓ Validação de horário comercial (8h-18h) com opção de forçar execução
    ✓ Controle de paralelismo e amostragem personalizável
    ✓ Timeout configurável para evitar bloqueios longos
    ✓ Logs detalhados opcionais para troubleshooting
    ✓ Interrupção automática se horário comercial for atingido durante execução
    ✓ Relatórios com métricas de performance e taxa de sucesso
    ✓ Execução controlada (simulação ou execução real)
    
    MELHORIAS IMPLEMENTADAS:
    • Validação robusta de parâmetros de entrada
    • Score de prioridade baseado em percentual de modificação (70%) e idade (30%)
    • Classificação de prioridade (CRÍTICA/ALTA/MÉDIA/BAIXA)
    • Controle de MAXDOP e percentual de amostragem
    • Timeout por comando para evitar travamentos
    • Monitoramento de duração de execução por estatística
    • Relatório final com percentuais e tempo médio
    
    AUTOR: Wesley Silva
    VERSÃO: 5.0 - Enhanced with Business Hours Control & Advanced Features
    DATA: 2024
    */

    -- Verificação de horário para atualização de estatísticas (apenas entre 20:00 e 05:00)
    DECLARE @HoraAtual TIME = CAST(GETDATE() AS TIME);
    DECLARE @HorarioPermitido BIT = 0;
    
    -- Verifica se está no horário permitido (20:00 às 05:00) ou se @Force = 1
    IF (@HoraAtual >= '20:00:00' OR @HoraAtual <= '05:00:00') OR @Force = 1
        SET @HorarioPermitido = 1;
    
    -- Log do horário atual
    DECLARE @LogHorario NVARCHAR(200) = CONCAT('Horário atual: ', FORMAT(@HoraAtual, 'HH:mm:ss'), 
                                              ' - Atualização de estatísticas permitida: ', 
                                              CASE WHEN @HorarioPermitido = 1 THEN 'SIM' ELSE 'NÃO' END,
                                              CASE WHEN @Force = 1 THEN ' (FORÇADO)' ELSE '' END);
    PRINT @LogHorario;

    IF @ExecutarAtualizacao = 1
       AND @HorarioPermitido = 0
       AND @ForcarExecucao = 0
    BEGIN
        PRINT 'AVISO: Atualização de estatísticas só é permitida entre 20:00 e 05:00.';
        PRINT 'Para forçar a execução, utilize @ForcarExecucao = 1';
        PRINT CONCAT('Horário atual: ', FORMAT(GETDATE(), 'HH:mm:ss'));
        RETURN;
    END;

    IF @HorarioPermitido = 0
       AND @ForcarExecucao = 1
    BEGIN
        PRINT 'ATENÇÃO: Execução forçada fora do horário permitido (20:00-05:00)!';
        PRINT 'Monitorar impacto na performance do sistema.';
    END;

    -- Variáveis de controle
    DECLARE @StartTime DATETIME = GETDATE();
    DECLARE @EndTime DATETIME;
    DECLARE @TotalElapsedTime INT;
    DECLARE @sql NVARCHAR(MAX);
    DECLARE @ProcessedCount INT = 0;
    DECLARE @TotalCount INT = 0;
    DECLARE @ProgressPercent FLOAT = 0;
    DECLARE @CurrentTableName NVARCHAR(256);
    DECLARE @CurrentStatName NVARCHAR(256);

    PRINT '=========================================';
    PRINT 'ANÁLISE DE ESTATÍSTICAS DESATUALIZADAS';
    PRINT '=========================================';
    PRINT CONCAT('Horário de início: ', FORMAT(GETDATE(), 'dd/MM/yyyy HH:mm:ss'));
    PRINT CONCAT('Threshold de modificações: ', @ModificationThreshold * 100, '%');
    PRINT CONCAT('Dias desde última atualização: ', @DaysSinceLastUpdate);
    PRINT CONCAT(   'Modo de execução: ',
                    CASE
                        WHEN @ExecutarAtualizacao = 1 THEN
                            'EXECUÇÃO REAL'
                        ELSE
                            'SIMULAÇÃO'
                    END
                );
    PRINT CONCAT('Paralelismo máximo: ', @MaxParallelism);
    PRINT CONCAT(   'Amostragem: ',
                    CASE
                        WHEN @SamplePercent IS NULL THEN
                            'PADRÃO SQL SERVER'
                        ELSE
                            CONCAT(@SamplePercent, '%')
                    END
                );
    PRINT CONCAT('Timeout por comando: ', @TimeoutSegundos, ' segundos');
    PRINT CONCAT(   'Horário permitido: ',
                    CASE
                        WHEN @HorarioPermitido = 1 THEN
                            'SIM (20h-05h)'
                        ELSE
                            'NÃO (fora do período 20h-05h)'
                    END
                );
    IF @HorarioPermitido = 0
       AND @ExecutarAtualizacao = 1
    BEGIN
        PRINT CONCAT(   'Forçar execução: ',
                        CASE
                            WHEN @ForcarExecucao = 1 THEN
                                'SIM'
                            ELSE
                                'NÃO'
                        END
                    );
    END;
    PRINT '=========================================';
    PRINT '';

    DROP TABLE IF EXISTS #StatsToUpdate;

    -- Tabela temporária para estatísticas desatualizadas
    CREATE TABLE #StatsToUpdate
    (
        [SchemaName] VARCHAR(100),
        [TableName] VARCHAR(100),
        [StatsName] VARCHAR(100),
        [modification_counter] BIGINT,
        [rows] BIGINT,
        [last_updated] DATETIME,
        [modification_percent] FLOAT, -- Precisão aumentada para evitar overflow
        [priority_score] FLOAT,       -- Score de prioridade baseado em múltiplos fatores
        [days_since_update] INT,
        [update_script] NVARCHAR(MAX),
        [ProcessingOrder] INT IDENTITY(1, 1),
    );

    -- Identificar estatísticas desatualizadas
    INSERT INTO #StatsToUpdate
    (
        SchemaName,
        TableName,
        StatsName,
        modification_counter,
        rows,
        last_updated,
        modification_percent,
        days_since_update,
        update_script
    )
    SELECT s.name AS SchemaName,
           t.name AS TableName,
           st.name AS StatsName,
           sp.modification_counter,
           sp.rows,
           sp.last_updated,
           CASE
               WHEN sp.rows > 0
                    AND sp.modification_counter > 0 THEN
                   CAST((CAST(sp.modification_counter AS FLOAT) * 100.0 / CAST(sp.rows AS FLOAT)) AS FLOAT)
               ELSE
                   0
           END AS modification_percent,
           DATEDIFF(DAY, sp.last_updated, GETDATE()) AS days_since_update,
           CASE
               WHEN @SamplePercent IS NOT NULL THEN
                   CONCAT(
                             'UPDATE STATISTICS [',
                             s.name,
                             '].[',
                             t.name,
                             '] ([',
                             st.name,
                             ']) WITH SAMPLE ',
                             @SamplePercent,
                             ' PERCENT, MAXDOP = ',
                             @MaxParallelism,
                             ';'
                         )
               ELSE
                   CONCAT(
                             'UPDATE STATISTICS [',
                             s.name,
                             '].[',
                             t.name,
                             '] ([',
                             st.name,
                             ']) WITH SAMPLE, MAXDOP = ',
                             @MaxParallelism,
                             ';'
                         )
           END AS update_script
    FROM sys.tables t
        INNER JOIN sys.schemas s
            ON t.schema_id = s.schema_id
        INNER JOIN sys.stats st
            ON t.object_id = st.object_id
        CROSS APPLY sys.dm_db_stats_properties(st.object_id, st.stats_id) sp
    WHERE s.name NOT IN ( 'Log', 'Expurgo', 'HangFire', 'Sistema', 'sys' )
          AND s.name NOT LIKE '%HangFire%'
          AND st.auto_created = 1 -- Apenas estatísticas criadas automaticamente
          AND
          (
              -- Estatísticas com muitas modificações
              (
                  sp.rows > 0
                  AND sp.modification_counter > (sp.rows * @ModificationThreshold)
              )
              OR
              -- Estatísticas muito desatualizadas
              DATEDIFF(DAY, sp.last_updated, GETDATE()) > @DaysSinceLastUpdate
          )
    ORDER BY
        -- Priorizar por percentual de modificação e idade da estatística
        CASE
            WHEN sp.rows > 0
                 AND sp.modification_counter > 0 THEN
        (CAST(sp.modification_counter AS FLOAT) * 100.0 / CAST(sp.rows AS FLOAT))
            ELSE
                0
        END DESC,
        DATEDIFF(DAY, sp.last_updated, GETDATE()) DESC;

    -- Obter total de estatísticas encontradas
    SELECT @TotalCount = COUNT(*)
    FROM #StatsToUpdate;



    PRINT CONCAT('Encontradas ', @TotalCount, ' estatísticas desatualizadas.');
    PRINT '';

    -- Calcular score de prioridade baseado em múltiplos fatores
    UPDATE #StatsToUpdate
    SET priority_score = (modification_percent * 0.7) + -- 70% peso para modificações
        (CASE
             WHEN days_since_update > 30 THEN
        (days_since_update / 10.0)
             ELSE
                 0
         END * 0.3
        ); -- 30% peso para idade

    -- Atualizar scripts com configurações otimizadas
    IF @SamplePercent IS NULL
    BEGIN
        UPDATE #StatsToUpdate
        SET update_script = 'UPDATE STATISTICS [' + SchemaName + '].[' + TableName + '] ([' + StatsName
                            + ']) WITH SAMPLE, MAXDOP = ' + CAST(@MaxParallelism AS VARCHAR(2)) + ';';
    END;
    ELSE
    BEGIN
        UPDATE #StatsToUpdate
        SET update_script = 'UPDATE STATISTICS [' + SchemaName + '].[' + TableName + '] ([' + StatsName
                            + ']) WITH SAMPLE ' + CAST(@SamplePercent AS VARCHAR(3)) + ' PERCENT, MAXDOP = '
                            + CAST(@MaxParallelism AS VARCHAR(2)) + ';';
    END;

    -- Execução das atualizações com processamento otimizado
    IF (@ExecutarAtualizacao = 1 AND @TotalCount > 0)
    BEGIN
        DECLARE @CurrentSchemaName sysname;
        DECLARE @ProcessingOrder INT;
        DECLARE @SuccessCount INT = 0;
        DECLARE @ErrorCount INT = 0;

        PRINT '=========================================';
        PRINT 'INICIANDO EXECUÇÃO DAS ATUALIZAÇÕES';
        PRINT '=========================================';
        IF @HorarioPermitido = 0
           AND @ForcarExecucao = 1
        BEGIN
            PRINT '⚠️  ATENÇÃO: EXECUÇÃO FORA DO HORÁRIO PERMITIDO (20:00-05:00)!';
            PRINT '   Monitorar impacto na performance do sistema';
            PRINT '';
        END;

        DECLARE cursor_stats CURSOR LOCAL FAST_FORWARD FOR
        SELECT SchemaName,
               TableName,
               StatsName,
               update_script,
               ProcessingOrder,
               priority_score
        FROM #StatsToUpdate
        ORDER BY priority_score DESC,
                 ProcessingOrder; -- Ordenar por prioridade calculada

        OPEN cursor_stats;

        DECLARE @CurrentPriorityScore FLOAT;

        FETCH NEXT FROM cursor_stats
        INTO @CurrentSchemaName,
             @CurrentTableName,
             @CurrentStatName,
             @sql,
             @ProcessingOrder,
             @CurrentPriorityScore;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            -- Validação de horário a cada iteração (caso a execução seja longa)
            SET @HoraAtual = CAST(GETDATE() AS TIME);
            SET @HorarioPermitido = 0;
            
            -- Verifica se está no horário permitido (20:00 às 05:00)
            IF (@HoraAtual >= '20:00:00' OR @HoraAtual <= '05:00:00' OR @Force = 1 
				OR DATEPART(WEEKDAY, GETDATE()) IN (1, 7)  -- 1 = Domingo, 7 = Sábado
			)
                SET @HorarioPermitido = 1;

				

            IF @HorarioPermitido = 0
               AND @ForcarExecucao = 0
            BEGIN
                PRINT CONCAT(
                                'INTERROMPIDO: Fora do horário permitido (',
                                FORMAT(GETDATE(), 'HH:mm:ss'),
                                '). Processados: ',
                                @ProcessedCount,
                                '/',
                                @TotalCount
                            );
                BREAK;
            END;

            SET @ProcessedCount = @ProcessedCount + 1;

            -- Cálculo de progresso percentual
            IF (@MostrarProgresso = 1)
            BEGIN
                SET @ProgressPercent = CAST((@ProcessedCount * 100.0) / @TotalCount AS float);
                IF @LogDetalhado = 1
                BEGIN
                    PRINT CONCAT(
                                    'Progresso: ',
                                    @ProgressPercent,
                                    '% (',
                                    @ProcessedCount,
                                    '/',
                                    @TotalCount,
                                    ') - Prioridade: ',
                                    @CurrentPriorityScore,
                                    ' - Atualizando: [',
                                    @CurrentSchemaName,
                                    '].[',
                                    @CurrentTableName,
                                    '].[',
                                    @CurrentStatName,
                                    ']'
                                );
                END;
                ELSE
                BEGIN
                    PRINT CONCAT(
                                    'Progresso: ',
                                    @ProgressPercent,
                                    '% (',
                                    @ProcessedCount,
                                    '/',
                                    @TotalCount,
                                    ') - [',
                                    @CurrentSchemaName,
                                    '].[',
                                    @CurrentTableName,
                                    '].[',
                                    @CurrentStatName,
                                    ']'
                                );
                END;
            END;

            -- Execução da atualização com timeout
            DECLARE @StartExecTime DATETIME = GETDATE();
            DECLARE @ExecDuration INT;

            BEGIN TRY
                -- Configurar timeout para o comando
                DECLARE @TimeoutCommand NVARCHAR(MAX)
                    = CONCAT('SET LOCK_TIMEOUT ', @TimeoutSegundos * 1000, '; ', @sql);
                EXEC sp_executesql @TimeoutCommand;

                SET @ExecDuration = DATEDIFF(MILLISECOND, @StartExecTime, GETDATE());
                SET @SuccessCount = @SuccessCount + 1;

                IF @LogDetalhado = 1
                BEGIN
                    PRINT CONCAT(
                                    'SUCESSO: [',
                                    @CurrentSchemaName,
                                    '].[',
                                    @CurrentTableName,
                                    '].[',
                                    @CurrentStatName,
                                    '] - Duração: ',
                                    @ExecDuration,
                                    'ms'
                                );
                END;
            END TRY
            BEGIN CATCH
                SET @ErrorCount = @ErrorCount + 1;
                SET @ExecDuration = DATEDIFF(MILLISECOND, @StartExecTime, GETDATE());
                PRINT CONCAT(
                                'ERRO ao atualizar [',
                                @CurrentSchemaName,
                                '].[',
                                @CurrentTableName,
                                '].[',
                                @CurrentStatName,
                                '] (',
                                @ExecDuration,
                                'ms): ',
                                ERROR_MESSAGE()
                            );
            END CATCH;

            FETCH NEXT FROM cursor_stats
            INTO @CurrentSchemaName,
                 @CurrentTableName,
                 @CurrentStatName,
                 @sql,
                 @ProcessingOrder,
                 @CurrentPriorityScore;
        END;

        CLOSE cursor_stats;
        DEALLOCATE cursor_stats;

        -- Relatório final
        SET @EndTime = GETDATE();
        SET @TotalElapsedTime = DATEDIFF(SECOND, @StartTime, @EndTime);

        PRINT '';
        PRINT '=========================================';
        PRINT 'RELATÓRIO FINAL';
        PRINT '=========================================';
        PRINT CONCAT('Estatísticas encontradas: ', @TotalCount);
        PRINT CONCAT('Estatísticas processadas: ', @ProcessedCount);
        PRINT CONCAT('Sucessos: ',
                     @SuccessCount,
                     ' (',
                     FORMAT(   CASE
                                   WHEN @ProcessedCount > 0 THEN
                               (@SuccessCount * 100.0 / @ProcessedCount)
                                   ELSE
                                       0
                               END,
                               'N1'
                           ),
                     '%)'
                    );
        PRINT CONCAT('Erros: ',
                     @ErrorCount,
                     ' (',
                     FORMAT(   CASE
                                   WHEN @ProcessedCount > 0 THEN
                               (@ErrorCount * 100.0 / @ProcessedCount)
                                   ELSE
                                       0
                               END,
                               'N1'
                           ),
                     '%)'
                    );
        PRINT CONCAT(
                        'Tempo total: ',
                        @TotalElapsedTime,
                        ' segundos (',
                        FORMAT(@TotalElapsedTime / 60.0, 'N1'),
                        ' minutos)'
                    );
        PRINT CONCAT('Tempo médio por estatística: ',
                     FORMAT(   CASE
                                   WHEN @ProcessedCount > 0 THEN
                               (@TotalElapsedTime * 1.0 / @ProcessedCount)
                                   ELSE
                                       0
                               END,
                               'N2'
                           ),
                     ' segundos'
                    );

        IF @HorarioPermitido = 0
           AND @ForcarExecucao = 1
        BEGIN
            PRINT 'ATENÇÃO: Execução realizada fora do horário permitido (20:00-05:00)!';
        END;
        PRINT '=========================================';
    END;

   

    SELECT SchemaName + '.' + TableName AS Tabela,
           StatsName AS Estatistica,
           FORMAT(rows, 'N0') AS TotalLinhas,
           FORMAT(modification_counter, 'N0') AS LinhasModificadas,
           FORMAT(modification_percent, 'N2') AS PercentualModificacao,
           days_since_update AS DiasDesdeUltimaAtualizacao,
           FORMAT(priority_score, 'N2') AS ScorePrioridade,
           CASE
               WHEN priority_score >= 50 THEN
                   'CRÍTICA'
               WHEN priority_score >= 20 THEN
                   'ALTA'
               WHEN priority_score >= 10 THEN
                   'MÉDIA'
               ELSE
                   'BAIXA'
           END AS Prioridade,
           update_script AS ComandoSQL
    FROM #StatsToUpdate
    ORDER BY priority_score DESC,
             ProcessingOrder;

    PRINT CONCAT('Total de estatísticas que seriam atualizadas: ', @TotalCount);

	

    
END;
GO
GO