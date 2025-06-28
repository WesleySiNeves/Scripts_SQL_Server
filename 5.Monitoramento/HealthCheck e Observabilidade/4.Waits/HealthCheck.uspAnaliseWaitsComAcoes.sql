/*
=============================================
Autor: Wesley David Santos
Data de Criação: 2024-12-19
Descrição: PROCEDURE ESPECIALISTA EM TUNING - Análise de Waits com Ações Automáticas
           Executa análise completa e gera plano de ação específico para Azure SQL Database
           
Versão: 1.0 - Integração com Procedures de Otimização

Funcionalidades:
🎯 ANÁLISE AUTOMATIZADA:
- Executa uspAnaliseWaitsCompleta
- Interpreta resultados e gera ações específicas
- Integra com procedures existentes de otimização
- Adaptado para Azure SQL Database (vCore)

📊 PLANO DE AÇÃO INTELIGENTE:
- Ações priorizadas por impacto
- Scripts de correção automática
- Configurações específicas para Azure
- Integração com rotinas de manutenção

Uso: EXEC HealthCheck.uspAnaliseWaitsComAcoes @ExecutarAcoes = 0, @GerarScripts = 1
=============================================
*/

CREATE OR ALTER PROCEDURE HealthCheck.uspAnaliseWaitsComAcoes
    @ExecutarAcoes BIT = 0,                 -- Executar ações automaticamente (cuidado!)
    @GerarScripts BIT = 1,                  -- Gerar scripts de correção
    @MostrarConfiguracoes BIT = 1,          -- Mostrar configurações atuais
    @PrioridadeMinima VARCHAR(10) = 'MÉDIA', -- CRÍTICA, ALTA, MÉDIA, BAIXA
    @Debug BIT = 0                          -- Modo debug
AS
BEGIN
    SET NOCOUNT ON;
    
    -- ═══════════════════════════════════════════════════════════════
    -- 📋 DECLARAÇÃO DE VARIÁVEIS E CONFIGURAÇÕES INICIAIS
    -- ═══════════════════════════════════════════════════════════════
    
    DECLARE @InicioExecucao DATETIME2 = GETDATE();
    DECLARE @sql NVARCHAR(MAX);
    DECLARE @ConfigAtual NVARCHAR(500);
    DECLARE @ValorAtual INT;
    DECLARE @NovoValor INT;
    
    -- Tabela para capturar resultados da análise de waits
    CREATE TABLE #ResultadosWaits (
        TipoWait VARCHAR(100),
        PercentualTotal DECIMAL(5,2),
        TempoMedio DECIMAL(10,2),
        Categoria VARCHAR(50),
        Severidade VARCHAR(20),
        Recomendacao NVARCHAR(500)
    );
    
    -- Tabela principal de ações
    CREATE TABLE #AcoesRecomendadas (
        ID INT IDENTITY(1,1),
        Prioridade VARCHAR(10),
        Categoria VARCHAR(50),
        ProblemaIdentificado NVARCHAR(200),
        ConfiguracaoAtual NVARCHAR(200),
        ValorRecomendado NVARCHAR(100),
        AcaoEspecifica NVARCHAR(500),
        ScriptCorrecao NVARCHAR(MAX),
        ProcedureIntegracao VARCHAR(100),
        ImpactoEstimado VARCHAR(50),
        TempoEstimado VARCHAR(50),
        ObservacoesAzure NVARCHAR(300)
    );
    
    -- Cabeçalho do relatório
    PRINT '═══════════════════════════════════════════════════════════════';
    PRINT '🎯 ANÁLISE DE WAITS COM PLANO DE AÇÃO - AZURE SQL DATABASE';
    PRINT '═══════════════════════════════════════════════════════════════';
    PRINT 'Executado em: ' + CONVERT(VARCHAR, @InicioExecucao, 120);
    PRINT 'Ambiente: Azure SQL Database (vCore)';
    PRINT '═══════════════════════════════════════════════════════════════';
    PRINT '';
    
    -- ═══════════════════════════════════════════════════════════════
    -- 🔍 SEÇÃO 1: EXECUÇÃO DA ANÁLISE DE WAITS COMPLETA
    -- ═══════════════════════════════════════════════════════════════
    
    PRINT '🔍 EXECUTANDO ANÁLISE COMPLETA DE WAITS...';
    PRINT '═══════════════════════════════════════════════════════════════';
    
    BEGIN TRY
        -- Executar a análise completa de waits
        EXEC HealthCheck.uspAnaliseWaitsCompleta 
            @TipoAnalise = 'COMPLETA',
            @MostrarRecomendacoes = 1,
            @TopQueries = 20,
            @AlertasApenas = 0,
            @Debug = @Debug;
            
        PRINT '✅ Análise de waits executada com sucesso!';
        PRINT '';
    END TRY
    BEGIN CATCH
        PRINT '❌ ERRO na execução da análise de waits: ' + ERROR_MESSAGE();
        RETURN;
    END CATCH
    
    -- ═══════════════════════════════════════════════════════════════
    -- 📊 SEÇÃO 2: ANÁLISE DE CONFIGURAÇÕES ATUAIS DO AZURE SQL
    -- ═══════════════════════════════════════════════════════════════
    
    IF @MostrarConfiguracoes = 1
    BEGIN
        PRINT '📊 CONFIGURAÇÕES ATUAIS DO AZURE SQL DATABASE...';
        PRINT '═══════════════════════════════════════════════════════════════';
        
        -- Configurações específicas do Azure SQL Database
        SELECT 
            '⚙️ CONFIGURAÇÃO AZURE' AS [Tipo],
            name AS [Configuração],
            value AS [Valor Atual],
            value_in_use AS [Valor em Uso],
            description AS [Descrição],
            CASE name
                WHEN 'max degree of parallelism' THEN 
                    CASE 
                        WHEN value_in_use = 0 THEN '🟡 AUTO (pode causar problemas)'
                        WHEN value_in_use > 8 THEN '🔴 MUITO ALTO (reduzir)'
                        WHEN value_in_use BETWEEN 4 AND 8 THEN '🟢 ADEQUADO'
                        ELSE '🟠 BAIXO (pode ser otimizado)'
                    END
                WHEN 'cost threshold for parallelism' THEN
                    CASE 
                        WHEN value_in_use = 5 THEN '🔴 PADRÃO (muito baixo)'
                        WHEN value_in_use < 25 THEN '🟡 BAIXO (aumentar)'
                        WHEN value_in_use BETWEEN 25 AND 50 THEN '🟢 ADEQUADO'
                        ELSE '🟠 ALTO (revisar)'
                    END
                ELSE '📋 Revisar conforme necessário'
            END AS [Status/Recomendação]
        FROM sys.configurations 
        WHERE name IN (
            'max degree of parallelism',
            'cost threshold for parallelism',
            'optimize for ad hoc workloads'
        )
        ORDER BY name;
        
        PRINT '';
    END
    
    -- ═══════════════════════════════════════════════════════════════
    -- 🎯 SEÇÃO 3: GERAÇÃO DE AÇÕES BASEADAS EM WAITS CRÍTICOS
    -- ═══════════════════════════════════════════════════════════════
    
    PRINT '🎯 GERANDO PLANO DE AÇÃO BASEADO EM WAITS...';
    PRINT '═══════════════════════════════════════════════════════════════';
    
    -- 1. AÇÃO PARA SOS_WORK_DISPATCHER (CRÍTICO)
    IF EXISTS (
        SELECT 1 FROM sys.dm_os_wait_stats 
        WHERE wait_type = 'SOS_WORK_DISPATCHER' 
        AND (wait_time_ms * 100.0 / (SELECT SUM(wait_time_ms) FROM sys.dm_os_wait_stats WHERE wait_type NOT LIKE 'SLEEP_%')) > 10
    )
    BEGIN
        SELECT @ValorAtual = CONVERT(INT, value_in_use) FROM sys.configurations WHERE name = 'max degree of parallelism';
        SET @NovoValor = CASE 
            WHEN @ValorAtual = 0 THEN 4  -- Se AUTO, definir 4
            WHEN @ValorAtual > 4 THEN @ValorAtual / 2  -- Reduzir pela metade
            ELSE 2  -- Mínimo 2
        END;
        
        INSERT INTO #AcoesRecomendadas VALUES (
            'CRÍTICA',
            'Scheduler/Paralelismo',
            'SOS_WORK_DISPATCHER alto (>10%) - Scheduler sobrecarregado',
            'MAXDOP atual: ' + CAST(@ValorAtual AS VARCHAR(10)),
            CAST(@NovoValor AS VARCHAR(10)),
            'Reduzir MAXDOP para diminuir contenção do scheduler',
            'ALTER DATABASE SCOPED CONFIGURATION SET MAXDOP = ' + CAST(@NovoValor AS VARCHAR(10)) + ';',
            NULL,
            'ALTO - Redução imediata de contenção',
            '< 1 minuto',
            'Azure SQL: Use ALTER DATABASE SCOPED CONFIGURATION em vez de sp_configure'
        );
    END
    
    -- 2. AÇÃO PARA PAGEIOLATCH (I/O LENTO)
    IF EXISTS (
        SELECT 1 FROM sys.dm_os_wait_stats 
        WHERE wait_type LIKE 'PAGEIOLATCH_%' 
        AND wait_time_ms / NULLIF(waiting_tasks_count, 0) > 20
    )
    BEGIN
        INSERT INTO #AcoesRecomendadas VALUES (
            'ALTA',
            'I/O Performance',
            'PAGEIOLATCH alto - I/O de disco lento (>20ms médio)',
            'Latência I/O atual: >20ms',
            'Otimizar índices e queries',
            'Executar análise de índices ausentes e fragmentação',
            '-- Executar procedures de otimização\nEXEC HealthCheck.uspMissingIndex;\nEXEC HealthCheck.uspAutoCreateIndex @ExecutarCriacao = 1;',
            'HealthCheck.uspMissingIndex, HealthCheck.uspAutoCreateIndex',
            'ALTO - Melhoria significativa de I/O',
            '5-15 minutos',
            'Azure SQL: Considerar tier de performance superior se I/O continuar lento'
        );
    END
    
    -- 3. AÇÃO PARA PARALELISMO EXCESSIVO
    IF EXISTS (
        SELECT 1 FROM sys.dm_os_wait_stats 
        WHERE wait_type IN ('CXPACKET', 'CXCONSUMER', 'CXSYNC_PORT') 
        AND (wait_time_ms * 100.0 / (SELECT SUM(wait_time_ms) FROM sys.dm_os_wait_stats WHERE wait_type NOT LIKE 'SLEEP_%')) > 2
    )
    BEGIN
        SELECT @ValorAtual = CONVERT(INT, value_in_use) FROM sys.configurations WHERE name = 'cost threshold for parallelism';
        SET @NovoValor = CASE 
            WHEN @ValorAtual <= 5 THEN 25
            WHEN @ValorAtual < 25 THEN 50
            ELSE @ValorAtual
        END;
        
        INSERT INTO #AcoesRecomendadas VALUES (
            'ALTA',
            'Paralelismo',
            'Waits de paralelismo excessivos (CXPACKET/CXCONSUMER >2%)',
            'Cost Threshold atual: ' + CAST(@ValorAtual AS VARCHAR(10)),
            CAST(@NovoValor AS VARCHAR(10)),
            'Aumentar Cost Threshold for Parallelism para reduzir paralelismo desnecessário',
            '-- ═══════════════════════════════════════════════════════════════\n' +
            '-- 🎯 SCRIPTS POR AMBIENTE - COST THRESHOLD FOR PARALLELISM\n' +
            '-- ═══════════════════════════════════════════════════════════════\n\n' +
            '-- 🏢 ON-PREMISE (SQL Server 2019+):\n' +
            'EXEC sp_configure ''show advanced options'', 1;\n' +
            'RECONFIGURE;\n' +
            'EXEC sp_configure ''cost threshold for parallelism'', ' + CAST(@NovoValor AS VARCHAR(10)) + ';\n' +
            'RECONFIGURE;\n' +
            'EXEC sp_configure ''show advanced options'', 0;\n' +
            'RECONFIGURE;\n\n' +
            '-- ☁️ AZURE SQL DATABASE:\n' +
            '-- Nota: Cost Threshold é gerenciado automaticamente pelo Azure\n' +
            '-- Foque em otimização de queries e configurações de escopo:\n' +
            'ALTER DATABASE SCOPED CONFIGURATION SET MAXDOP = 0; -- Usar padrão\n' +
            'ALTER DATABASE SCOPED CONFIGURATION SET LEGACY_CARDINALITY_ESTIMATION = OFF;\n' +
            'ALTER DATABASE SCOPED CONFIGURATION SET PARAMETER_SNIFFING = ON;\n\n' +
            '-- 🌐 AWS RDS SQL SERVER:\n' +
            '-- Use o Parameter Group para configurar:\n' +
            '-- 1. No AWS Console, vá para RDS > Parameter Groups\n' +
            '-- 2. Edite o parameter group associado à instância\n' +
            '-- 3. Modifique: cost threshold for parallelism = ' + CAST(@NovoValor AS VARCHAR(10)) + '\n' +
            '-- 4. Reinicie a instância RDS para aplicar\n' +
            '-- Alternativa via SQL (se permitido):\n' +
            'EXEC sp_configure ''cost threshold for parallelism'', ' + CAST(@NovoValor AS VARCHAR(10)) + ';\n' +
            'RECONFIGURE;',
            NULL,
            'MÉDIO - Redução de contenção',
            '< 1 minuto',
            'Scripts específicos por ambiente: On-premise (sp_configure), Azure (DATABASE SCOPED), AWS (Parameter Group)'
        );
    END
    
    -- 4. AÇÃO PARA PRESSÃO DE CPU
    IF EXISTS (
        SELECT 1 FROM sys.dm_os_wait_stats 
        WHERE wait_type = 'SOS_SCHEDULER_YIELD' 
        AND (wait_time_ms * 100.0 / (SELECT SUM(wait_time_ms) FROM sys.dm_os_wait_stats WHERE wait_type NOT LIKE 'SLEEP_%')) > 1
    )
    BEGIN
        INSERT INTO #AcoesRecomendadas VALUES (
            'ALTA',
            'CPU Performance',
            'SOS_SCHEDULER_YIELD alto - Pressão de CPU detectada',
            'CPU com alta utilização',
            'Otimizar queries e índices',
            'Executar otimização completa de índices e estatísticas',
            '-- Otimização completa\nEXEC HealthCheck.uspDeleteDuplicateIndex @ExecutarDelecao = 1;\nEXEC HealthCheck.uspAutoCreateStats @ExecutarCriacao = 1;\nEXEC HealthCheck.uspUpdateStats @ExecutarAtualizacao = 1;',
            'HealthCheck.uspDeleteDuplicateIndex, HealthCheck.uspAutoCreateStats, HealthCheck.uspUpdateStats',
            'ALTO - Redução significativa de CPU',
            '10-30 minutos',
            'Azure SQL: Considerar scale-up se CPU continuar alta após otimizações'
        );
    END
    
    -- 5. AÇÃO PARA REDE/CLIENTE LENTO
    IF EXISTS (
        SELECT 1 FROM sys.dm_os_wait_stats 
        WHERE wait_type = 'ASYNC_NETWORK_IO' 
        AND (wait_time_ms * 100.0 / (SELECT SUM(wait_time_ms) FROM sys.dm_os_wait_stats WHERE wait_type NOT LIKE 'SLEEP_%')) > 1
    )
    BEGIN
        INSERT INTO #AcoesRecomendadas VALUES (
            'MÉDIA',
            'Rede/Cliente',
            'ASYNC_NETWORK_IO alto - Cliente lento ou resultados grandes',
            'Aplicação processando resultados lentamente',
            'Otimizar queries e paginação',
            'Revisar queries que retornam muitos dados, implementar paginação',
            '-- Identificar queries com muitos resultados\nSELECT TOP 10 \n    qs.execution_count,\n    qs.total_rows / qs.execution_count as avg_rows,\n    SUBSTRING(st.text, 1, 200) as query_text\nFROM sys.dm_exec_query_stats qs\nCROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) st\nORDER BY qs.total_rows DESC;',
            NULL,
            'MÉDIO - Melhoria de experiência do usuário',
            '2-5 minutos para análise',
            'Azure SQL: Verificar localização geográfica e latência de rede'
        );
    END
    
    -- 6. AÇÃO PREVENTIVA - MANUTENÇÃO GERAL
    INSERT INTO #AcoesRecomendadas VALUES (
        'BAIXA',
        'Manutenção Preventiva',
        'Manutenção regular de índices e estatísticas',
        'Manutenção baseada em cronograma',
        'Executar rotinas de manutenção',
        'Manter índices e estatísticas atualizados regularmente',
        '-- Manutenção completa (executar em horário de baixo uso)\nEXEC HealthCheck.uspUpdateStats @ExecutarAtualizacao = 1, @PriorityMode = 1;\nEXEC HealthCheck.uspMissingIndex @MostrarRecomendacoes = 1;',
        'HealthCheck.uspUpdateStats, HealthCheck.uspMissingIndex',
        'BAIXO - Prevenção de problemas',
        '15-45 minutos',
        'Azure SQL: Agendar durante janela de manutenção ou baixo uso'
    );
    
    -- ═══════════════════════════════════════════════════════════════
    -- 📋 SEÇÃO 4: EXIBIÇÃO DO PLANO DE AÇÃO
    -- ═══════════════════════════════════════════════════════════════
    
    PRINT '📋 PLANO DE AÇÃO GERADO:';
    PRINT '═══════════════════════════════════════════════════════════════';
    
    -- Filtrar por prioridade mínima
    DECLARE @FiltroP INT = CASE @PrioridadeMinima
        WHEN 'CRÍTICA' THEN 1
        WHEN 'ALTA' THEN 2  
        WHEN 'MÉDIA' THEN 3
        WHEN 'BAIXA' THEN 4
        ELSE 3
    END;
    
    -- Exibir ações recomendadas
    SELECT 
        '🎯 AÇÃO RECOMENDADA' AS [Tipo],
        ROW_NUMBER() OVER (ORDER BY 
            CASE Prioridade 
                WHEN 'CRÍTICA' THEN 1 
                WHEN 'ALTA' THEN 2 
                WHEN 'MÉDIA' THEN 3 
                WHEN 'BAIXA' THEN 4 
            END, ID) AS [#],
        CASE Prioridade
            WHEN 'CRÍTICA' THEN '🔴 CRÍTICA'
            WHEN 'ALTA' THEN '🟡 ALTA'
            WHEN 'MÉDIA' THEN '🟠 MÉDIA'
            WHEN 'BAIXA' THEN '🟢 BAIXA'
        END AS [Prioridade],
        Categoria AS [Categoria],
        ProblemaIdentificado AS [Problema Identificado],
        ConfiguracaoAtual AS [Configuração Atual],
        ValorRecomendado AS [Valor Recomendado],
        AcaoEspecifica AS [Ação Específica],
        ProcedureIntegracao AS [Procedure Relacionada],
        ImpactoEstimado AS [Impacto Estimado],
        TempoEstimado AS [Tempo Estimado],
        ObservacoesAzure AS [Observações Azure SQL]
    FROM #AcoesRecomendadas
    WHERE CASE Prioridade 
        WHEN 'CRÍTICA' THEN 1 
        WHEN 'ALTA' THEN 2 
        WHEN 'MÉDIA' THEN 3 
        WHEN 'BAIXA' THEN 4 
    END <= @FiltroP
    ORDER BY 
        CASE Prioridade 
            WHEN 'CRÍTICA' THEN 1 
            WHEN 'ALTA' THEN 2 
            WHEN 'MÉDIA' THEN 3 
            WHEN 'BAIXA' THEN 4 
        END, ID;
    
    -- ═══════════════════════════════════════════════════════════════
    -- 🔧 SEÇÃO 5: SCRIPTS DE CORREÇÃO
    -- ═══════════════════════════════════════════════════════════════
    
    IF @GerarScripts = 1
    BEGIN
        PRINT '';
        PRINT '🔧 SCRIPTS DE CORREÇÃO GERADOS:';
        PRINT '═══════════════════════════════════════════════════════════════';
        
        DECLARE @ScriptAtual NVARCHAR(MAX);
        DECLARE @PrioridadeAtual VARCHAR(10);
        DECLARE @CategoriaAtual VARCHAR(50);
        DECLARE @ContadorScript INT = 1;
        
        DECLARE cursor_scripts CURSOR FOR
        SELECT Prioridade, Categoria, ScriptCorrecao
        FROM #AcoesRecomendadas
        WHERE ScriptCorrecao IS NOT NULL
            AND CASE Prioridade 
                WHEN 'CRÍTICA' THEN 1 
                WHEN 'ALTA' THEN 2 
                WHEN 'MÉDIA' THEN 3 
                WHEN 'BAIXA' THEN 4 
            END <= @FiltroP
        ORDER BY 
            CASE Prioridade 
                WHEN 'CRÍTICA' THEN 1 
                WHEN 'ALTA' THEN 2 
                WHEN 'MÉDIA' THEN 3 
                WHEN 'BAIXA' THEN 4 
            END, ID;
        
        OPEN cursor_scripts;
        FETCH NEXT FROM cursor_scripts INTO @PrioridadeAtual, @CategoriaAtual, @ScriptAtual;
        
        WHILE @@FETCH_STATUS = 0
        BEGIN
            PRINT '';
            PRINT '-- ═══════════════════════════════════════════════════════════════';
            PRINT '-- SCRIPT #' + CAST(@ContadorScript AS VARCHAR(10)) + ' - PRIORIDADE: ' + @PrioridadeAtual + ' - CATEGORIA: ' + @CategoriaAtual;
            PRINT '-- ═══════════════════════════════════════════════════════════════';
            PRINT @ScriptAtual;
            PRINT '';
            
            SET @ContadorScript = @ContadorScript + 1;
            FETCH NEXT FROM cursor_scripts INTO @PrioridadeAtual, @CategoriaAtual, @ScriptAtual;
        END;
        
        CLOSE cursor_scripts;
        DEALLOCATE cursor_scripts;
    END
    
    -- ═══════════════════════════════════════════════════════════════
    -- ⚡ SEÇÃO 6: EXECUÇÃO AUTOMÁTICA (SE SOLICITADA)
    -- ═══════════════════════════════════════════════════════════════
    
    IF @ExecutarAcoes = 1
    BEGIN
        PRINT '';
        PRINT '⚡ EXECUTANDO AÇÕES AUTOMÁTICAS...';
        PRINT '⚠️  ATENÇÃO: Executando correções automáticas!';
        PRINT '═══════════════════════════════════════════════════════════════';
        
        DECLARE @ProcedureExec VARCHAR(100);
        DECLARE @ScriptExec NVARCHAR(MAX);
        
        DECLARE cursor_execucao CURSOR FOR
        SELECT ProcedureIntegracao, ScriptCorrecao
        FROM #AcoesRecomendadas
        WHERE Prioridade IN ('CRÍTICA', 'ALTA')
            AND (ProcedureIntegracao IS NOT NULL OR ScriptCorrecao IS NOT NULL);
        
        OPEN cursor_execucao;
        FETCH NEXT FROM cursor_execucao INTO @ProcedureExec, @ScriptExec;
        
        WHILE @@FETCH_STATUS = 0
        BEGIN
            BEGIN TRY
                IF @ProcedureExec IS NOT NULL
                BEGIN
                    PRINT '🔄 Executando: ' + @ProcedureExec;
                    -- Executar procedures específicas
                    IF @ProcedureExec LIKE '%uspMissingIndex%'
                        EXEC HealthCheck.uspMissingIndex @MostrarRecomendacoes = 1;
                    ELSE IF @ProcedureExec LIKE '%uspAutoCreateIndex%'
                        EXEC HealthCheck.uspAutoCreateIndex @ExecutarCriacao = 1;
                    ELSE IF @ProcedureExec LIKE '%uspUpdateStats%'
                        EXEC HealthCheck.uspUpdateStats @ExecutarAtualizacao = 1, @PriorityMode = 1;
                    
                    PRINT '✅ Sucesso: ' + @ProcedureExec;
                END
                
                IF @ScriptExec IS NOT NULL AND @ScriptExec NOT LIKE '%EXEC HealthCheck%'
                BEGIN
                    PRINT '🔄 Executando script de configuração...';
                    EXEC sp_executesql @ScriptExec;
                    PRINT '✅ Script executado com sucesso';
                END
                
            END TRY
            BEGIN CATCH
                PRINT '❌ ERRO na execução: ' + ERROR_MESSAGE();
            END CATCH
            
            FETCH NEXT FROM cursor_execucao INTO @ProcedureExec, @ScriptExec;
        END;
        
        CLOSE cursor_execucao;
        DEALLOCATE cursor_execucao;
    END
    
    -- ═══════════════════════════════════════════════════════════════
    -- 📊 SEÇÃO 7: RESUMO EXECUTIVO
    -- ═══════════════════════════════════════════════════════════════
    
    PRINT '';
    PRINT '📊 RESUMO EXECUTIVO:';
    PRINT '═══════════════════════════════════════════════════════════════';
    
    SELECT 
        'RESUMO POR PRIORIDADE' AS [Categoria],
        Prioridade,
        COUNT(*) AS [Quantidade de Ações],
        STRING_AGG(Categoria, ', ') AS [Categorias Envolvidas]
    FROM #AcoesRecomendadas
    GROUP BY Prioridade
    ORDER BY 
        CASE Prioridade 
            WHEN 'CRÍTICA' THEN 1 
            WHEN 'ALTA' THEN 2 
            WHEN 'MÉDIA' THEN 3 
            WHEN 'BAIXA' THEN 4 
        END;
    
    DECLARE @TotalAcoes INT;
    SELECT @TotalAcoes = COUNT(*) FROM #AcoesRecomendadas;
    
    PRINT '';
    PRINT 'Total de ações identificadas: ' + CAST(@TotalAcoes AS VARCHAR(10));
    PRINT 'Tempo total de execução: ' + CAST(DATEDIFF(SECOND, @InicioExecucao, GETDATE()) AS VARCHAR(10)) + ' segundos';
    PRINT '';
    PRINT '🎯 RECOMENDAÇÃO FINAL:';
    PRINT '1. Execute primeiro as ações CRÍTICAS e ALTAS';
    PRINT '2. Monitore o impacto antes de prosseguir';
    PRINT '3. Agende ações de MANUTENÇÃO para horários de baixo uso';
    PRINT '4. Considere scale-up no Azure se problemas persistirem';
    PRINT '';
    PRINT '═══════════════════════════════════════════════════════════════';
    
    -- Limpeza
    DROP TABLE #ResultadosWaits;
    DROP TABLE #AcoesRecomendadas;
END;
GO

-- ═══════════════════════════════════════════════════════════════
-- 📝 EXEMPLOS DE USO
-- ═══════════════════════════════════════════════════════════════

/*
-- EXEMPLO 1: Análise completa com geração de scripts (RECOMENDADO)
EXEC HealthCheck.uspAnaliseWaitsComAcoes 
    @ExecutarAcoes = 0,           -- Não executar automaticamente
    @GerarScripts = 1,            -- Gerar scripts para revisão
    @MostrarConfiguracoes = 1,    -- Mostrar configurações atuais
    @PrioridadeMinima = 'MÉDIA';  -- Mostrar ações médias e acima

-- EXEMPLO 2: Execução automática de ações críticas (CUIDADO!)
EXEC HealthCheck.uspAnaliseWaitsComAcoes 
    @ExecutarAcoes = 1,           -- EXECUTAR automaticamente
    @GerarScripts = 1,
    @PrioridadeMinima = 'CRÍTICA'; -- Apenas ações críticas

-- EXEMPLO 3: Análise rápida apenas de alertas críticos
EXEC HealthCheck.uspAnaliseWaitsComAcoes 
    @ExecutarAcoes = 0,
    @GerarScripts = 0,
    @MostrarConfiguracoes = 0,
    @PrioridadeMinima = 'CRÍTICA';
*/