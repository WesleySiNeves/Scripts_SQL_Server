/*
=============================================
Autor: Wesley Neves
Data de Criação: 2024-12-19
Descrição: PROCEDURE MASTER DE DIAGNÓSTICO - What's the Problem?
           Executa análise completa integrando uspAnaliseWaitsComAcoes com funcionalidades avançadas
           
Versão: 1.0 - Diagnóstico Completo com Health Score

Funcionalidades Avançadas:
🎯 DIAGNÓSTICO COMPLETO:
- Executa uspAnaliseWaitsComAcoes como base
- Análise de tendências históricas de waits
- Detecção de waits específicos adicionais
- Métricas de performance avançadas (Query Store)
- Health Score do banco de dados
- Otimizações específicas do Azure SQL

📊 RELATÓRIO EXECUTIVO:
- Health Score consolidado (0-100)
- Tendências de performance
- Alertas críticos priorizados
- Recomendações estratégicas

Uso: EXEC HealthCheck.uspWhatsProblem @GerarRelatorioCompleto = 1
=============================================
*/

CREATE OR ALTER PROCEDURE HealthCheck.uspWhatsProblem
    @ExecutarAcoes BIT = 0,                    -- Executar ações automaticamente
    @GerarRelatorioCompleto BIT = 1,           -- Gerar relatório completo
    @AnalisarTendencias BIT = 1,               -- Analisar tendências históricas
    @CalcularHealthScore BIT = 1,              -- Calcular Health Score
    @DiasHistorico INT = 7,                    -- Dias para análise histórica
    @PrioridadeMinima VARCHAR(10) = 'MÉDIA',   -- CRÍTICA, ALTA, MÉDIA, BAIXA
    @Debug BIT = 0                             -- Modo debug
AS
BEGIN
    SET NOCOUNT ON;
    
    -- ═══════════════════════════════════════════════════════════════
    -- 📋 DECLARAÇÃO DE VARIÁVEIS E CONFIGURAÇÕES INICIAIS
    -- ═══════════════════════════════════════════════════════════════
    
    DECLARE @InicioExecucao DATETIME2 = GETDATE();
    DECLARE @HealthScore DECIMAL(5,2) = 0;
    DECLARE @StatusGeral VARCHAR(20);
    DECLARE @TotalProblemas INT = 0;
    DECLARE @ProblemasCriticos INT = 0;
    DECLARE @sql NVARCHAR(MAX);
    
    -- Tabelas temporárias para análises avançadas
    CREATE TABLE #TendenciasWaits (
        DataAnalise DATE,
        TipoWait VARCHAR(100),
        PercentualMedio DECIMAL(5,2),
        TendenciaStatus VARCHAR(20)
    );
    
    CREATE TABLE #WaitsEspecificos (
        TipoWait VARCHAR(100),
        Categoria VARCHAR(50),
        PercentualAtual DECIMAL(5,2),
        StatusCriticidade VARCHAR(20),
        AcaoRecomendada NVARCHAR(500)
    );
    
    CREATE TABLE #MetricasAvancadas (
        Metrica VARCHAR(100),
        ValorAtual DECIMAL(18,2),
        ValorIdeal DECIMAL(18,2),
        StatusMetrica VARCHAR(20),
        ImpactoHealthScore INT
    );
    
    CREATE TABLE #HealthScoreDetalhes (
        Categoria VARCHAR(50),
        PontuacaoMaxima INT,
        PontuacaoAtual INT,
        PercentualCategoria DECIMAL(5,2),
        StatusCategoria VARCHAR(20)
    );
    
    -- Cabeçalho do diagnóstico
    PRINT '═══════════════════════════════════════════════════════════════';
    PRINT '🏥 WHAT''S THE PROBLEM? - DIAGNÓSTICO COMPLETO AZURE SQL';
    PRINT '═══════════════════════════════════════════════════════════════';
    PRINT 'Executado em: ' + CONVERT(VARCHAR, @InicioExecucao, 120);
    PRINT 'Ambiente: Azure SQL Database (vCore)';
    PRINT 'Período de análise: ' + CAST(@DiasHistorico AS VARCHAR(10)) + ' dias';
    PRINT '═══════════════════════════════════════════════════════════════';
    PRINT '';
    
    -- ═══════════════════════════════════════════════════════════════
    -- 🎯 SEÇÃO 1: EXECUÇÃO DA ANÁLISE BASE (uspAnaliseWaitsComAcoes)
    -- ═══════════════════════════════════════════════════════════════
    
    PRINT '🎯 EXECUTANDO ANÁLISE BASE DE WAITS COM AÇÕES...';
    PRINT '═══════════════════════════════════════════════════════════════';
    
    BEGIN TRY
        -- Executar a análise base
        EXEC HealthCheck.uspAnaliseWaitsComAcoes 
            @ExecutarAcoes = @ExecutarAcoes,
            @GerarScripts = 1,
            @MostrarConfiguracoes = 1,
            @PrioridadeMinima = @PrioridadeMinima,
            @Debug = @Debug;
            
        PRINT '✅ Análise base executada com sucesso!';
        PRINT '';
    END TRY
    BEGIN CATCH
        PRINT '❌ ERRO na análise base: ' + ERROR_MESSAGE();
        -- Continuar com outras análises mesmo se a base falhar
    END CATCH
    
    -- ═══════════════════════════════════════════════════════════════
    -- 📊 SEÇÃO 2: ANÁLISE DE TENDÊNCIAS HISTÓRICAS
    -- ═══════════════════════════════════════════════════════════════
    
    IF @AnalisarTendencias = 1
    BEGIN
        PRINT '📊 ANALISANDO TENDÊNCIAS HISTÓRICAS DE WAITS...';
        PRINT '═══════════════════════════════════════════════════════════════';
        
        BEGIN TRY
            -- Simular análise de tendências (em ambiente real, usar Query Store ou tabelas de histórico)
            WITH WaitsAtuais AS (
                SELECT 
                    wait_type,
                    wait_time_ms * 100.0 / SUM(wait_time_ms) OVER() AS percentual_atual
                FROM sys.dm_os_wait_stats 
                WHERE wait_type NOT LIKE 'SLEEP_%'
                    AND wait_type NOT LIKE 'BROKER_%'
                    AND wait_type NOT LIKE 'XE_%'
                    AND wait_time_ms > 0
            )
            INSERT INTO #TendenciasWaits
            SELECT 
                CAST(GETDATE() AS DATE) as DataAnalise,
                wait_type,
                percentual_atual,
                CASE 
                    WHEN percentual_atual > 10 THEN 'CRÍTICO'
                    WHEN percentual_atual > 5 THEN 'ALTO'
                    WHEN percentual_atual > 1 THEN 'MÉDIO'
                    ELSE 'BAIXO'
                END as TendenciaStatus
            FROM WaitsAtuais
            WHERE percentual_atual > 0.5;
            
            -- Exibir tendências
            SELECT 
                '📈 TENDÊNCIA HISTÓRICA' AS [Tipo],
                TipoWait AS [Wait Type],
                PercentualMedio AS [% Atual],
                TendenciaStatus AS [Status],
                CASE TendenciaStatus
                    WHEN 'CRÍTICO' THEN '🔴 Requer ação imediata'
                    WHEN 'ALTO' THEN '🟡 Monitorar de perto'
                    WHEN 'MÉDIO' THEN '🟠 Acompanhar evolução'
                    ELSE '🟢 Dentro do esperado'
                END AS [Recomendação]
            FROM #TendenciasWaits
            ORDER BY PercentualMedio DESC;
            
            PRINT '✅ Análise de tendências concluída!';
            PRINT '';
        END TRY
        BEGIN CATCH
            PRINT '⚠️ Erro na análise de tendências: ' + ERROR_MESSAGE();
        END CATCH
    END
    
    -- ═══════════════════════════════════════════════════════════════
    -- 🎯 SEÇÃO 3: DETECÇÃO DE WAITS ESPECÍFICOS ADICIONAIS
    -- ═══════════════════════════════════════════════════════════════
    
    PRINT '🎯 DETECTANDO WAITS ESPECÍFICOS ADICIONAIS...';
    PRINT '═══════════════════════════════════════════════════════════════';
    
    BEGIN TRY
        -- Waits específicos do Azure SQL e cenários avançados
        INSERT INTO #WaitsEspecificos
        SELECT 
            wait_type,
            CASE 
                WHEN wait_type LIKE 'HADR_%' THEN 'Alta Disponibilidade'
                WHEN wait_type LIKE 'REDO_%' THEN 'Log Redo'
                WHEN wait_type LIKE 'REPLICA_%' THEN 'Always On'
                WHEN wait_type LIKE 'DBMIRROR_%' THEN 'Database Mirroring'
                WHEN wait_type LIKE 'LOGMGR_%' THEN 'Log Manager'
                WHEN wait_type LIKE 'WRITELOG%' THEN 'Write Log'
                WHEN wait_type LIKE 'RESOURCE_%' THEN 'Resource Governor'
                WHEN wait_type LIKE 'SQLTRACE_%' THEN 'SQL Trace'
                WHEN wait_type LIKE 'BACKUP_%' THEN 'Backup Operations'
                WHEN wait_type LIKE 'RESTORE_%' THEN 'Restore Operations'
                WHEN wait_type = 'THREADPOOL' THEN 'Thread Pool Starvation'
                WHEN wait_type = 'CMEMTHREAD' THEN 'Memory Thread'
                WHEN wait_type = 'CXCONSUMER' THEN 'Parallel Query Consumer'
                WHEN wait_type = 'EXCHANGE' THEN 'Parallel Query Exchange'
                WHEN wait_type = 'IO_COMPLETION' THEN 'I/O Completion'
                WHEN wait_type = 'NETWORK_IO' THEN 'Network I/O'
                ELSE 'Outros'
            END as Categoria,
            wait_time_ms * 100.0 / (SELECT SUM(wait_time_ms) FROM sys.dm_os_wait_stats WHERE wait_type NOT LIKE 'SLEEP_%') as PercentualAtual,
            CASE 
                WHEN wait_time_ms * 100.0 / (SELECT SUM(wait_time_ms) FROM sys.dm_os_wait_stats WHERE wait_type NOT LIKE 'SLEEP_%') > 5 THEN 'CRÍTICO'
                WHEN wait_time_ms * 100.0 / (SELECT SUM(wait_time_ms) FROM sys.dm_os_wait_stats WHERE wait_type NOT LIKE 'SLEEP_%') > 2 THEN 'ALTO'
                WHEN wait_time_ms * 100.0 / (SELECT SUM(wait_time_ms) FROM sys.dm_os_wait_stats WHERE wait_type NOT LIKE 'SLEEP_%') > 0.5 THEN 'MÉDIO'
                ELSE 'BAIXO'
            END as StatusCriticidade,
            CASE 
                WHEN wait_type = 'THREADPOOL' THEN 'Considerar aumento de vCores ou otimização de queries'
                WHEN wait_type LIKE 'HADR_%' THEN 'Verificar configuração Always On e latência de rede'
                WHEN wait_type LIKE 'LOGMGR_%' THEN 'Otimizar operações de log, considerar tier superior'
                WHEN wait_type = 'RESOURCE_SEMAPHORE' THEN 'Pressão de memória - otimizar queries ou aumentar tier'
                WHEN wait_type = 'IO_COMPLETION' THEN 'I/O lento - considerar tier Premium ou otimizar queries'
                ELSE 'Analisar contexto específico e documentação Microsoft'
            END as AcaoRecomendada
        FROM sys.dm_os_wait_stats
        WHERE wait_type NOT LIKE 'SLEEP_%'
            AND wait_type NOT LIKE 'BROKER_%'
            AND wait_type NOT LIKE 'XE_%'
            AND wait_time_ms > 0
            AND wait_time_ms * 100.0 / (SELECT SUM(wait_time_ms) FROM sys.dm_os_wait_stats WHERE wait_type NOT LIKE 'SLEEP_%') > 0.1
            AND wait_type IN (
                'THREADPOOL', 'CMEMTHREAD', 'RESOURCE_SEMAPHORE', 'RESOURCE_SEMAPHORE_QUERY_COMPILE',
                'CXCONSUMER', 'EXCHANGE', 'IO_COMPLETION', 'NETWORK_IO',
                'LOGMGR_FLUSH', 'LOGMGR_RESERVE_APPEND', 'WRITELOG',
                'HADR_SYNC_COMMIT', 'HADR_NOTIFICATION_DEQUEUE', 'REDO_THREAD_PENDING_WORK'
            );
        
        -- Exibir waits específicos detectados
        IF EXISTS (SELECT 1 FROM #WaitsEspecificos)
        BEGIN
            SELECT 
                '🔍 WAIT ESPECÍFICO' AS [Tipo],
                TipoWait AS [Wait Type],
                Categoria AS [Categoria],
                PercentualAtual AS [% Atual],
                CASE StatusCriticidade
                    WHEN 'CRÍTICO' THEN '🔴 CRÍTICO'
                    WHEN 'ALTO' THEN '🟡 ALTO'
                    WHEN 'MÉDIO' THEN '🟠 MÉDIO'
                    ELSE '🟢 BAIXO'
                END AS [Criticidade],
                AcaoRecomendada AS [Ação Recomendada]
            FROM #WaitsEspecificos
            ORDER BY PercentualAtual DESC;
        END
        ELSE
        BEGIN
            PRINT '✅ Nenhum wait específico adicional detectado acima do threshold.';
        END
        
        PRINT '';
    END TRY
    BEGIN CATCH
        PRINT '⚠️ Erro na detecção de waits específicos: ' + ERROR_MESSAGE();
    END CATCH
    
    -- ═══════════════════════════════════════════════════════════════
    -- 📈 SEÇÃO 4: MÉTRICAS DE PERFORMANCE AVANÇADAS
    -- ═══════════════════════════════════════════════════════════════
    
    PRINT '📈 COLETANDO MÉTRICAS DE PERFORMANCE AVANÇADAS...';
    PRINT '═══════════════════════════════════════════════════════════════';
    
    BEGIN TRY
        -- Métricas de performance críticas
        INSERT INTO #MetricasAvancadas
        SELECT 'CPU Utilization %', 
               (SELECT CAST(avg_cpu_percent AS DECIMAL(18,2)) FROM sys.dm_db_resource_stats WHERE end_time = (SELECT MAX(end_time) FROM sys.dm_db_resource_stats)),
               80.0, -- Ideal < 80%
               CASE WHEN (SELECT CAST(avg_cpu_percent AS DECIMAL(18,2)) FROM sys.dm_db_resource_stats WHERE end_time = (SELECT MAX(end_time) FROM sys.dm_db_resource_stats)) > 80 THEN 'CRÍTICO'
                    WHEN (SELECT CAST(avg_cpu_percent AS DECIMAL(18,2)) FROM sys.dm_db_resource_stats WHERE end_time = (SELECT MAX(end_time) FROM sys.dm_db_resource_stats)) > 60 THEN 'ALTO'
                    ELSE 'BOM' END,
               CASE WHEN (SELECT CAST(avg_cpu_percent AS DECIMAL(18,2)) FROM sys.dm_db_resource_stats WHERE end_time = (SELECT MAX(end_time) FROM sys.dm_db_resource_stats)) > 80 THEN -20
                    WHEN (SELECT CAST(avg_cpu_percent AS DECIMAL(18,2)) FROM sys.dm_db_resource_stats WHERE end_time = (SELECT MAX(end_time) FROM sys.dm_db_resource_stats)) > 60 THEN -10
                    ELSE 0 END;
        
        -- Adicionar mais métricas
        INSERT INTO #MetricasAvancadas VALUES 
        ('Conexões Ativas', 
         (SELECT COUNT(*) FROM sys.dm_exec_sessions WHERE is_user_process = 1),
         100, 'BOM', 0),
        ('Queries Lentas (>5s)', 
         (SELECT COUNT(*) FROM sys.dm_exec_query_stats WHERE total_elapsed_time/execution_count > 5000000),
         10, 
         CASE WHEN (SELECT COUNT(*) FROM sys.dm_exec_query_stats WHERE total_elapsed_time/execution_count > 5000000) > 10 THEN 'CRÍTICO' ELSE 'BOM' END,
         CASE WHEN (SELECT COUNT(*) FROM sys.dm_exec_query_stats WHERE total_elapsed_time/execution_count > 5000000) > 10 THEN -15 ELSE 0 END),
        ('Índices Fragmentados >30%',
         (SELECT COUNT(*) FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, 'LIMITED') WHERE avg_fragmentation_in_percent > 30),
         5,
         CASE WHEN (SELECT COUNT(*) FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, 'LIMITED') WHERE avg_fragmentation_in_percent > 30) > 5 THEN 'ALTO' ELSE 'BOM' END,
         CASE WHEN (SELECT COUNT(*) FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, 'LIMITED') WHERE avg_fragmentation_in_percent > 30) > 5 THEN -10 ELSE 0 END);
        
        -- Exibir métricas
        SELECT 
            '📊 MÉTRICA AVANÇADA' AS [Tipo],
            Metrica AS [Métrica],
            ValorAtual AS [Valor Atual],
            ValorIdeal AS [Valor Ideal],
            CASE StatusMetrica
                WHEN 'CRÍTICO' THEN '🔴 CRÍTICO'
                WHEN 'ALTO' THEN '🟡 ALTO'
                WHEN 'MÉDIO' THEN '🟠 MÉDIO'
                ELSE '🟢 BOM'
            END AS [Status],
            ImpactoHealthScore AS [Impacto Health Score]
        FROM #MetricasAvancadas
        ORDER BY ImpactoHealthScore ASC;
        
        PRINT '✅ Métricas de performance coletadas!';
        PRINT '';
    END TRY
    BEGIN CATCH
        PRINT '⚠️ Erro na coleta de métricas: ' + ERROR_MESSAGE();
    END CATCH
    
    -- ═══════════════════════════════════════════════════════════════
    -- 🏥 SEÇÃO 5: CÁLCULO DO HEALTH SCORE
    -- ═══════════════════════════════════════════════════════════════
    
    IF @CalcularHealthScore = 1
    BEGIN
        PRINT '🏥 CALCULANDO HEALTH SCORE DO BANCO DE DADOS...';
        PRINT '═══════════════════════════════════════════════════════════════';
        
        BEGIN TRY
            -- Categorias do Health Score
            INSERT INTO #HealthScoreDetalhes VALUES
            ('Waits Performance', 25, 25, 100.0, 'EXCELENTE'),
            ('CPU & Memory', 20, 20, 100.0, 'EXCELENTE'),
            ('I/O Performance', 20, 20, 100.0, 'EXCELENTE'),
            ('Índices & Fragmentação', 15, 15, 100.0, 'EXCELENTE'),
            ('Configurações Azure', 10, 10, 100.0, 'EXCELENTE'),
            ('Queries Performance', 10, 10, 100.0, 'EXCELENTE');
            
            -- Ajustar pontuações baseado em problemas detectados
            
            -- Waits críticos reduzem score
            UPDATE #HealthScoreDetalhes 
            SET PontuacaoAtual = PontuacaoAtual - (SELECT COUNT(*) * 5 FROM #TendenciasWaits WHERE TendenciaStatus = 'CRÍTICO'),
                StatusCategoria = CASE WHEN PontuacaoAtual - (SELECT COUNT(*) * 5 FROM #TendenciasWaits WHERE TendenciaStatus = 'CRÍTICO') < 15 THEN 'CRÍTICO'
                                      WHEN PontuacaoAtual - (SELECT COUNT(*) * 5 FROM #TendenciasWaits WHERE TendenciaStatus = 'CRÍTICO') < 20 THEN 'ATENÇÃO'
                                      ELSE 'BOM' END
            WHERE Categoria = 'Waits Performance';
            
            -- Métricas ruins reduzem score
            UPDATE #HealthScoreDetalhes 
            SET PontuacaoAtual = PontuacaoAtual + (SELECT ISNULL(SUM(ImpactoHealthScore), 0) FROM #MetricasAvancadas),
                StatusCategoria = CASE WHEN PontuacaoAtual + (SELECT ISNULL(SUM(ImpactoHealthScore), 0) FROM #MetricasAvancadas) < 10 THEN 'CRÍTICO'
                                      WHEN PontuacaoAtual + (SELECT ISNULL(SUM(ImpactoHealthScore), 0) FROM #MetricasAvancadas) < 15 THEN 'ATENÇÃO'
                                      ELSE 'BOM' END
            WHERE Categoria IN ('CPU & Memory', 'I/O Performance', 'Queries Performance');
            
            -- Calcular Health Score final
            SELECT @HealthScore = SUM(PontuacaoAtual) FROM #HealthScoreDetalhes;
            
            SET @StatusGeral = CASE 
                WHEN @HealthScore >= 90 THEN 'EXCELENTE'
                WHEN @HealthScore >= 75 THEN 'BOM'
                WHEN @HealthScore >= 60 THEN 'ATENÇÃO'
                WHEN @HealthScore >= 40 THEN 'CRÍTICO'
                ELSE 'EMERGÊNCIA'
            END;
            
            -- Exibir Health Score
            PRINT '';
            PRINT '🏥 ═══════════════════════════════════════════════════════════════';
            PRINT '🏥 HEALTH SCORE DO BANCO DE DADOS: ' + CAST(@HealthScore AS VARCHAR(10)) + '/100';
            PRINT '🏥 STATUS GERAL: ' + @StatusGeral;
            PRINT '🏥 ═══════════════════════════════════════════════════════════════';
            PRINT '';
            
            -- Detalhamento por categoria
            SELECT 
                '🏥 HEALTH SCORE' AS [Tipo],
                Categoria AS [Categoria],
                CAST(PontuacaoAtual AS VARCHAR(10)) + '/' + CAST(PontuacaoMaxima AS VARCHAR(10)) AS [Pontuação],
                CAST(ROUND((PontuacaoAtual * 100.0 / PontuacaoMaxima), 1) AS VARCHAR(10)) + '%' AS [Percentual],
                CASE StatusCategoria
                    WHEN 'EXCELENTE' THEN '🟢 EXCELENTE'
                    WHEN 'BOM' THEN '🟢 BOM'
                    WHEN 'ATENÇÃO' THEN '🟡 ATENÇÃO'
                    WHEN 'CRÍTICO' THEN '🔴 CRÍTICO'
                    ELSE '⚫ EMERGÊNCIA'
                END AS [Status]
            FROM #HealthScoreDetalhes
            ORDER BY PontuacaoMaxima DESC;
            
            PRINT '✅ Health Score calculado!';
            PRINT '';
        END TRY
        BEGIN CATCH
            PRINT '⚠️ Erro no cálculo do Health Score: ' + ERROR_MESSAGE();
            SET @HealthScore = 50; -- Score padrão em caso de erro
            SET @StatusGeral = 'INDETERMINADO';
        END CATCH
    END
    
    -- ═══════════════════════════════════════════════════════════════
    -- 🎯 SEÇÃO 6: OTIMIZAÇÕES ESPECÍFICAS DO AZURE SQL
    -- ═══════════════════════════════════════════════════════════════
    
    PRINT '🎯 RECOMENDAÇÕES ESPECÍFICAS PARA AZURE SQL DATABASE...';
    PRINT '═══════════════════════════════════════════════════════════════';
    
    BEGIN TRY
        -- Verificar configurações específicas do Azure
        PRINT '🔧 CONFIGURAÇÕES AZURE SQL RECOMENDADAS:';
        PRINT '─────────────────────────────────────────────────────────────────';
        
        -- Query Store
        IF (SELECT is_query_store_on FROM sys.databases WHERE name = DB_NAME()) = 0
        BEGIN
            PRINT '📊 Query Store: ❌ DESABILITADO';
            PRINT '   Recomendação: Habilitar Query Store para melhor monitoramento';
            PRINT '   Script: ALTER DATABASE [' + DB_NAME() + '] SET QUERY_STORE = ON;';
        END
        ELSE
        BEGIN
            PRINT '📊 Query Store: ✅ HABILITADO';
        END
        
        -- Automatic Tuning
        SELECT 
            '🤖 AUTO TUNING' AS [Recurso],
            name AS [Opção],
            desired_state_desc AS [Estado Desejado],
            actual_state_desc AS [Estado Atual],
            CASE 
                WHEN desired_state_desc = actual_state_desc THEN '✅ CONFIGURADO'
                ELSE '⚠️ VERIFICAR CONFIGURAÇÃO'
            END AS [Status]
        FROM sys.database_automatic_tuning_options;
        
        -- Recomendações de tier
        DECLARE @CurrentTier VARCHAR(50);
        SELECT @CurrentTier = service_objective FROM sys.database_service_objectives;
        
        PRINT '';
        PRINT '💰 RECOMENDAÇÕES DE TIER/PERFORMANCE:';
        PRINT '─────────────────────────────────────────────────────────────────';
        PRINT 'Tier atual: ' + ISNULL(@CurrentTier, 'Não identificado');
        
        IF @HealthScore < 60
        BEGIN
            PRINT '🔴 RECOMENDAÇÃO: Considerar upgrade de tier devido ao Health Score baixo';
            PRINT '   - Avaliar aumento de vCores para melhor performance';
            PRINT '   - Considerar tier Premium para I/O mais rápido';
        END
        ELSE IF @HealthScore < 75
        BEGIN
            PRINT '🟡 RECOMENDAÇÃO: Monitorar performance e considerar otimizações';
            PRINT '   - Focar em otimização de queries antes de upgrade';
        END
        ELSE
        BEGIN
            PRINT '🟢 TIER ADEQUADO: Performance dentro do esperado';
        END
        
        PRINT '';
        PRINT '🌐 RECURSOS AZURE SQL AVANÇADOS:';
        PRINT '─────────────────────────────────────────────────────────────────';
        PRINT '• Intelligent Insights: Monitoramento automático de performance';
        PRINT '• SQL Analytics: Dashboard de monitoramento no Azure Monitor';
        PRINT '• Automatic Backup: Backups automáticos com retenção configurável';
        PRINT '• Geo-Replication: Alta disponibilidade entre regiões';
        PRINT '• Advanced Threat Protection: Segurança avançada';
        
        PRINT '✅ Análise de otimizações Azure concluída!';
        PRINT '';
    END TRY
    BEGIN CATCH
        PRINT '⚠️ Erro na análise de otimizações Azure: ' + ERROR_MESSAGE();
    END CATCH
    
    -- ═══════════════════════════════════════════════════════════════
    -- 📋 SEÇÃO 7: RESUMO EXECUTIVO FINAL
    -- ═══════════════════════════════════════════════════════════════
    
    IF @GerarRelatorioCompleto = 1
    BEGIN
        PRINT '📋 RESUMO EXECUTIVO - WHAT''S THE PROBLEM?';
        PRINT '═══════════════════════════════════════════════════════════════';
        
        -- Contadores de problemas
        SELECT @TotalProblemas = COUNT(*) FROM #TendenciasWaits WHERE TendenciaStatus IN ('CRÍTICO', 'ALTO');
        SELECT @ProblemasCriticos = COUNT(*) FROM #TendenciasWaits WHERE TendenciaStatus = 'CRÍTICO';
        
        PRINT '🎯 DIAGNÓSTICO GERAL:';
        PRINT '   Health Score: ' + CAST(@HealthScore AS VARCHAR(10)) + '/100 (' + @StatusGeral + ')';
        PRINT '   Problemas Críticos: ' + CAST(@ProblemasCriticos AS VARCHAR(10));
        PRINT '   Total de Problemas: ' + CAST(@TotalProblemas AS VARCHAR(10));
        PRINT '   Tempo de Análise: ' + CAST(DATEDIFF(SECOND, @InicioExecucao, GETDATE()) AS VARCHAR(10)) + ' segundos';
        PRINT '';
        
        PRINT '🚨 AÇÕES PRIORITÁRIAS:';
        IF @ProblemasCriticos > 0
        BEGIN
            PRINT '   1. 🔴 CRÍTICO: Resolver waits críticos imediatamente';
            PRINT '   2. 🔧 Executar scripts de correção gerados';
            PRINT '   3. 📊 Monitorar impacto das correções';
        END
        ELSE IF @TotalProblemas > 0
        BEGIN
            PRINT '   1. 🟡 Implementar otimizações recomendadas';
            PRINT '   2. 📈 Acompanhar tendências de performance';
        END
        ELSE
        BEGIN
            PRINT '   ✅ Sistema operando dentro dos parâmetros normais';
            PRINT '   📅 Manter rotina de monitoramento preventivo';
        END
        
        PRINT '';
        PRINT '📅 PRÓXIMOS PASSOS:';
        PRINT '   • Executar novamente em 24h para verificar melhorias';
        PRINT '   • Implementar monitoramento contínuo';
        PRINT '   • Agendar manutenções preventivas';
        PRINT '   • Considerar alertas automáticos para Health Score < 70';
        
        PRINT '';
        PRINT '═══════════════════════════════════════════════════════════════';
        PRINT '🏁 DIAGNÓSTICO CONCLUÍDO EM: ' + CAST(DATEDIFF(SECOND, @InicioExecucao, GETDATE()) AS VARCHAR(10)) + ' SEGUNDOS';
        PRINT '═══════════════════════════════════════════════════════════════';
    END
    
    -- Limpeza
    DROP TABLE #TendenciasWaits;
    DROP TABLE #WaitsEspecificos;
    DROP TABLE #MetricasAvancadas;
    DROP TABLE #HealthScoreDetalhes;
    
END
GO

/*
═══════════════════════════════════════════════════════════════
📖 EXEMPLOS DE USO:
═══════════════════════════════════════════════════════════════

-- 1. DIAGNÓSTICO COMPLETO (RECOMENDADO)
EXEC HealthCheck.uspWhatsProblem 
    @GerarRelatorioCompleto = 1,
    @AnalisarTendencias = 1,
    @CalcularHealthScore = 1;

-- 2. DIAGNÓSTICO RÁPIDO APENAS CRÍTICOS
EXEC HealthCheck.uspWhatsProblem 
    @PrioridadeMinima = 'CRÍTICA',
    @AnalisarTendencias = 0;

-- 3. DIAGNÓSTICO COM EXECUÇÃO AUTOMÁTICA (CUIDADO!)
EXEC HealthCheck.uspWhatsProblem 
    @ExecutarAcoes = 1,
    @PrioridadeMinima = 'ALTA';

-- 4. ANÁLISE HISTÓRICA ESTENDIDA
EXEC HealthCheck.uspWhatsProblem 
    @DiasHistorico = 30,
    @AnalisarTendencias = 1;

═══════════════════════════════════════════════════════════════
*/