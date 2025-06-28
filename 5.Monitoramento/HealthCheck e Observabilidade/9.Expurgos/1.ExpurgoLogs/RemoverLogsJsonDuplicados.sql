-- =============================================
-- Procedure: uspRemoverLogsDuplicadosEnterprise
-- Descrição: Remove logs duplicados das tabelas Log.LogsJson e Expurgo.LogsJson
-- Critério: Mantém apenas 1 registro por IdEntidade + Acao (exceto Acao = 'U')
-- Autor: Sistema HealthCheck
-- Data: 2024
-- =============================================

CREATE OR ALTER PROCEDURE [HealthCheck].[uspRemoverLogsDuplicadosEnterprise]
    @EfetivarRemocao BIT = 0,                    -- 0 = Apenas simular, 1 = Efetivar remoção
    @ProcessarLogPrincipal BIT = 1,              -- 1 = Processar Log.LogsJson
    @ProcessarExpurgo BIT = 1,                   -- 1 = Processar Expurgo.LogsJson
    @BatchSize INT = 5000,                       -- Tamanho do lote para performance
    @Debug BIT = 0                               -- 1 = Modo debug com informações detalhadas
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    
    -- Configurações otimizadas para performance
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
    SET LOCK_TIMEOUT 1800000; -- 30 minutos
    SET DEADLOCK_PRIORITY LOW;
    
    DECLARE @TempoInicio DATETIME2 = GETDATE();
    DECLARE @MensagemInicial NVARCHAR(500);
    DECLARE @TotalDuplicadosLog INT = 0;
    DECLARE @TotalDuplicadosExpurgo INT = 0;
    DECLARE @TotalRemovidosLog INT = 0;
    DECLARE @TotalRemovidosExpurgo INT = 0;
    
    -- Cabeçalho do processo
    SET @MensagemInicial = CASE 
        WHEN @EfetivarRemocao = 1 THEN '🗑️ REMOÇÃO DE LOGS DUPLICADOS - MODO EFETIVAÇÃO'
        ELSE '🔍 REMOÇÃO DE LOGS DUPLICADOS - MODO SIMULAÇÃO'
    END;
    
    PRINT '============================================================';
    PRINT @MensagemInicial;
    PRINT '============================================================';
    PRINT 'Critério: Manter apenas 1 registro por IdEntidade + Acao (exceto Acao = ''U'')';
    PRINT 'Tabelas: ' + 
           CASE WHEN @ProcessarLogPrincipal = 1 THEN 'Log.LogsJson ' ELSE '' END +
           CASE WHEN @ProcessarExpurgo = 1 THEN 'Expurgo.LogsJson' ELSE '' END;
    PRINT 'Tamanho do lote: ' + CAST(@BatchSize AS VARCHAR(10));
    PRINT '============================================================';
    
    BEGIN TRY
        
        -- ===================================================
        -- ANÁLISE INICIAL - IDENTIFICAR DUPLICADOS
        -- ===================================================
        
        IF @ProcessarLogPrincipal = 1
        BEGIN
            PRINT '';
            PRINT '📊 ANALISANDO TABELA: Log.LogsJson';
            PRINT '-----------------------------------';
            
            -- Contar duplicados na tabela Log.LogsJson
            SELECT @TotalDuplicadosLog = SUM(Duplicados)
            FROM (
                SELECT COUNT(1) - 1 AS Duplicados
                FROM Log.LogsJson 
                WHERE Acao <> 'U'
                GROUP BY IdEntidade, Acao
                HAVING COUNT(1) > 1
            ) AS Contagem;
            
            SET @TotalDuplicadosLog = ISNULL(@TotalDuplicadosLog, 0);
            PRINT 'Registros duplicados encontrados: ' + CAST(@TotalDuplicadosLog AS VARCHAR(10));
            
            IF @Debug = 1 AND @TotalDuplicadosLog > 0
            BEGIN
                PRINT '📋 Detalhamento dos duplicados (Top 10):';
                SELECT TOP 10
                    IdEntidade,
                    Acao,
                    COUNT(1) AS QtdDuplicados,
                    COUNT(1) - 1 AS QtdParaRemover
                FROM Log.LogsJson 
                WHERE Acao <> 'U'
                GROUP BY IdEntidade, Acao
                HAVING COUNT(1) > 1
                ORDER BY COUNT(1) DESC;
            END;
        END;
        
        IF @ProcessarExpurgo = 1
        BEGIN
            PRINT '';
            PRINT '📊 ANALISANDO TABELA: Expurgo.LogsJson';
            PRINT '--------------------------------------';
            
            -- Contar duplicados na tabela Expurgo.LogsJson
            SELECT @TotalDuplicadosExpurgo = SUM(Duplicados)
            FROM (
                SELECT COUNT(1) - 1 AS Duplicados
                FROM Expurgo.LogsJson 
                WHERE Acao <> 'U'
                GROUP BY IdEntidade, Acao
                HAVING COUNT(1) > 1
            ) AS Contagem;
            
            SET @TotalDuplicadosExpurgo = ISNULL(@TotalDuplicadosExpurgo, 0);
            PRINT 'Registros duplicados encontrados: ' + CAST(@TotalDuplicadosExpurgo AS VARCHAR(10));
            
            IF @Debug = 1 AND @TotalDuplicadosExpurgo > 0
            BEGIN
                PRINT '📋 Detalhamento dos duplicados (Top 10):';
                SELECT TOP 10
                    IdEntidade,
                    Acao,
                    COUNT(1) AS QtdDuplicados,
                    COUNT(1) - 1 AS QtdParaRemover
                FROM Expurgo.LogsJson 
                WHERE Acao <> 'U'
                GROUP BY IdEntidade, Acao
                HAVING COUNT(1) > 1
                ORDER BY COUNT(1) DESC;
            END;
        END;
        
        -- Verificar se há duplicados para processar
        IF @TotalDuplicadosLog = 0 AND @TotalDuplicadosExpurgo = 0
        BEGIN
            PRINT '';
            PRINT '✅ NENHUM REGISTRO DUPLICADO ENCONTRADO!';
            PRINT 'Processo finalizado sem necessidade de remoção.';
            RETURN;
        END;
        
        -- ===================================================
        -- PROCESSAMENTO DA TABELA LOG.LOGSJSON
        -- ===================================================
        
        IF @ProcessarLogPrincipal = 1 AND @TotalDuplicadosLog > 0
        BEGIN
            PRINT '';
            PRINT '🔄 PROCESSANDO: Log.LogsJson';
            PRINT '==============================';
            
            -- Criar tabela temporária para IDs a serem removidos
            DROP TABLE IF EXISTS #LogsDuplicadosLog;
            CREATE TABLE #LogsDuplicadosLog (
                IdLog INT NOT NULL PRIMARY KEY
            );
            
            -- Identificar registros duplicados para remoção (mantém o mais recente)
            INSERT INTO #LogsDuplicadosLog (IdLog)
            SELECT l.IdLog
            FROM (
                SELECT 
                    IdLog,
                    IdEntidade,
                    Acao,
                    Data,
                    ROW_NUMBER() OVER (
                        PARTITION BY IdEntidade, Acao 
                        ORDER BY Data DESC, IdLog DESC
                    ) AS RowNum
                FROM Log.LogsJson
                WHERE Acao <> 'U'
            ) l
            WHERE l.RowNum > 1;
            
            DECLARE @QtdParaRemoverLog INT = @@ROWCOUNT;
            PRINT 'Registros selecionados para remoção: ' + CAST(@QtdParaRemoverLog AS VARCHAR(10));
            
            IF @EfetivarRemocao = 1
            BEGIN
                PRINT '🗑️ Iniciando remoção em lotes...';
                
                DECLARE @RowsAffectedLog INT = 1;
                DECLARE @ContadorLotesLog INT = 0;
                
                -- Processar em lotes
                WHILE @RowsAffectedLog > 0 AND EXISTS (SELECT 1 FROM #LogsDuplicadosLog)
                BEGIN
                    DELETE TOP (@BatchSize) l
                    FROM Log.LogsJson l
                        INNER JOIN #LogsDuplicadosLog d ON l.IdLog = d.IdLog;
                    
                    SET @RowsAffectedLog = @@ROWCOUNT;
                    SET @TotalRemovidosLog = @TotalRemovidosLog + @RowsAffectedLog;
                    SET @ContadorLotesLog = @ContadorLotesLog + 1;
                    
                    IF @RowsAffectedLog > 0
                    BEGIN
                        PRINT 'Lote ' + CAST(@ContadorLotesLog AS VARCHAR(5)) + 
                              ': Removidos ' + CAST(@RowsAffectedLog AS VARCHAR(10)) + 
                              ' | Total: ' + CAST(@TotalRemovidosLog AS VARCHAR(10));
                        
                        -- Remover os processados da tabela de controle
                        DELETE TOP (@BatchSize) FROM #LogsDuplicadosLog;
                        
                        -- Pausa entre lotes
                        WAITFOR DELAY '00:00:01';
                    END;
                END;
                
                PRINT '✅ Log.LogsJson processada: ' + CAST(@TotalRemovidosLog AS VARCHAR(10)) + ' registros removidos';
            END
            ELSE
            BEGIN
                PRINT '🔍 SIMULAÇÃO: ' + CAST(@QtdParaRemoverLog AS VARCHAR(10)) + ' registros seriam removidos';
            END;
        END;
        
        -- ===================================================
        -- PROCESSAMENTO DA TABELA EXPURGO.LOGSJSON
        -- ===================================================
        
        IF @ProcessarExpurgo = 1 AND @TotalDuplicadosExpurgo > 0
        BEGIN
            PRINT '';
            PRINT '🔄 PROCESSANDO: Expurgo.LogsJson';
            PRINT '=================================';
            
            -- Criar tabela temporária para IDs a serem removidos
            DROP TABLE IF EXISTS #LogsDuplicadosExpurgo;
            CREATE TABLE #LogsDuplicadosExpurgo (
                IdLog INT NOT NULL PRIMARY KEY
            );
            
            -- Identificar registros duplicados para remoção (mantém o mais recente)
            INSERT INTO #LogsDuplicadosExpurgo (IdLog)
            SELECT e.IdLog
            FROM (
                SELECT 
                    IdLog,
                    IdEntidade,
                    Acao,
                    Data,
                    ROW_NUMBER() OVER (
                        PARTITION BY IdEntidade, Acao 
                        ORDER BY Data DESC, IdLog DESC
                    ) AS RowNum
                FROM Expurgo.LogsJson
                WHERE Acao <> 'U'
            ) e
            WHERE e.RowNum > 1;
            
            DECLARE @QtdParaRemoverExpurgo INT = @@ROWCOUNT;
            PRINT 'Registros selecionados para remoção: ' + CAST(@QtdParaRemoverExpurgo AS VARCHAR(10));
            
            IF @EfetivarRemocao = 1
            BEGIN
                PRINT '🗑️ Iniciando remoção em lotes...';
                
                DECLARE @RowsAffectedExpurgo INT = 1;
                DECLARE @ContadorLotesExpurgo INT = 0;
                
                -- Processar em lotes
                WHILE @RowsAffectedExpurgo > 0 AND EXISTS (SELECT 1 FROM #LogsDuplicadosExpurgo)
                BEGIN
                    DELETE TOP (@BatchSize) e
                    FROM Expurgo.LogsJson e
                        INNER JOIN #LogsDuplicadosExpurgo d ON e.IdLog = d.IdLog;
                    
                    SET @RowsAffectedExpurgo = @@ROWCOUNT;
                    SET @TotalRemovidosExpurgo = @TotalRemovidosExpurgo + @RowsAffectedExpurgo;
                    SET @ContadorLotesExpurgo = @ContadorLotesExpurgo + 1;
                    
                    IF @RowsAffectedExpurgo > 0
                    BEGIN
                        PRINT 'Lote ' + CAST(@ContadorLotesExpurgo AS VARCHAR(5)) + 
                              ': Removidos ' + CAST(@RowsAffectedExpurgo AS VARCHAR(10)) + 
                              ' | Total: ' + CAST(@TotalRemovidosExpurgo AS VARCHAR(10));
                        
                        -- Remover os processados da tabela de controle
                        DELETE TOP (@BatchSize) FROM #LogsDuplicadosExpurgo;
                        
                        -- Pausa entre lotes
                        WAITFOR DELAY '00:00:01';
                    END;
                END;
                
                PRINT '✅ Expurgo.LogsJson processada: ' + CAST(@TotalRemovidosExpurgo AS VARCHAR(10)) + ' registros removidos';
            END
            ELSE
            BEGIN
                PRINT '🔍 SIMULAÇÃO: ' + CAST(@QtdParaRemoverExpurgo AS VARCHAR(10)) + ' registros seriam removidos';
            END;
        END;
        
        -- ===================================================
        -- RELATÓRIO FINAL
        -- ===================================================
        
        DECLARE @TempoExecucao VARCHAR(20) = 
            CAST(DATEDIFF(SECOND, @TempoInicio, GETDATE()) AS VARCHAR(10)) + 's';
        
        PRINT '';
        PRINT '============================================================';
        PRINT '📊 RELATÓRIO FINAL - REMOÇÃO DE LOGS DUPLICADOS';
        PRINT '============================================================';
        
        -- Relatório detalhado por tabela
        SELECT 
            'Log.LogsJson' AS Tabela,
            @TotalDuplicadosLog AS DuplicadosEncontrados,
            CASE WHEN @EfetivarRemocao = 1 THEN @TotalRemovidosLog ELSE 0 END AS RegistrosRemovidos,
            CASE WHEN @ProcessarLogPrincipal = 1 THEN 'Processada' ELSE 'Ignorada' END AS Status
        WHERE @ProcessarLogPrincipal = 1
        
        UNION ALL
        
        SELECT 
            'Expurgo.LogsJson' AS Tabela,
            @TotalDuplicadosExpurgo AS DuplicadosEncontrados,
            CASE WHEN @EfetivarRemocao = 1 THEN @TotalRemovidosExpurgo ELSE 0 END AS RegistrosRemovidos,
            CASE WHEN @ProcessarExpurgo = 1 THEN 'Processada' ELSE 'Ignorada' END AS Status
        WHERE @ProcessarExpurgo = 1;
        
        -- Resumo consolidado
        SELECT 
            (@TotalDuplicadosLog + @TotalDuplicadosExpurgo) AS TotalDuplicadosEncontrados,
            CASE WHEN @EfetivarRemocao = 1 THEN (@TotalRemovidosLog + @TotalRemovidosExpurgo) ELSE 0 END AS TotalRegistrosRemovidos,
            @TempoExecucao AS TempoExecucao,
            CASE WHEN @EfetivarRemocao = 1 THEN 'EFETIVADO' ELSE 'SIMULAÇÃO' END AS ModoExecucao;
        
        PRINT 'Tempo de execução: ' + @TempoExecucao;
        PRINT 'Modo: ' + CASE WHEN @EfetivarRemocao = 1 THEN 'EFETIVAÇÃO' ELSE 'SIMULAÇÃO' END;
        
        IF @EfetivarRemocao = 1
        BEGIN
            PRINT '🎉 PROCESSO CONCLUÍDO COM SUCESSO!';
            PRINT 'Total de registros removidos: ' + CAST((@TotalRemovidosLog + @TotalRemovidosExpurgo) AS VARCHAR(10));
        END
        ELSE
        BEGIN
            PRINT '🔍 SIMULAÇÃO CONCLUÍDA!';
            PRINT 'Para efetivar, execute: EXEC uspRemoverLogsDuplicadosEnterprise @EfetivarRemocao = 1';
        END;
        
    END TRY
    BEGIN CATCH
        PRINT '';
        PRINT '❌ ERRO DURANTE A EXECUÇÃO:';
        PRINT 'Erro: ' + ERROR_MESSAGE();
        PRINT 'Linha: ' + CAST(ERROR_LINE() AS VARCHAR(10));
        PRINT 'Procedure: ' + ISNULL(ERROR_PROCEDURE(), 'uspRemoverLogsDuplicadosEnterprise');
        
        PRINT '';
        PRINT '📊 RESUMO ATÉ O ERRO:';
        PRINT 'Log.LogsJson - Removidos: ' + CAST(@TotalRemovidosLog AS VARCHAR(10));
        PRINT 'Expurgo.LogsJson - Removidos: ' + CAST(@TotalRemovidosExpurgo AS VARCHAR(10));
        
        -- Re-lançar o erro para tratamento externo se necessário
        THROW;
    END CATCH;
    
    -- Limpeza das tabelas temporárias
    DROP TABLE IF EXISTS #LogsDuplicadosLog;
    DROP TABLE IF EXISTS #LogsDuplicadosExpurgo;
    
    PRINT '============================================================';
    PRINT '✅ PROCEDURE FINALIZADA';
    PRINT '============================================================';
END;
GO

-- =============================================
-- EXEMPLOS DE USO DA PROCEDURE
-- =============================================

/*
-- 1. SIMULAÇÃO (apenas visualizar o que seria removido)
EXEC uspRemoverLogsDuplicadosEnterprise 
    @EfetivarRemocao = 0,
    @ProcessarLogPrincipal = 1,
    @ProcessarExpurgo = 1,
    @Debug = 1;

-- 2. EFETIVAÇÃO (remover duplicados realmente)
EXEC uspRemoverLogsDuplicadosEnterprise 
    @EfetivarRemocao = 1,
    @ProcessarLogPrincipal = 1,
    @ProcessarExpurgo = 1,
    @BatchSize = 5000;

-- 3. PROCESSAR APENAS UMA TABELA
EXEC uspRemoverLogsDuplicadosEnterprise 
    @EfetivarRemocao = 1,
    @ProcessarLogPrincipal = 1,
    @ProcessarExpurgo = 0;

-- 4. MODO DEBUG PARA ANÁLISE DETALHADA
EXEC uspRemoverLogsDuplicadosEnterprise 
    @EfetivarRemocao = 0,
    @Debug = 1;
*/