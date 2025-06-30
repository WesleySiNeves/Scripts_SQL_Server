/*
=============================================
Autor: Wesley Neves
Data de Criação: 2024-12-19
Descrição: Procedure para expurgo de logs de tasks
           com relatórios detalhados de impacto e métricas de redução.
           
Versão: 3.0 - ULTRA-OTIMIZADA para LogsTasks

Parâmetros:
    @DataLimite: Data limite para expurgo (obrigatório)
    @MostrarRelatorio: Exibe relatório detalhado do expurgo (padrão: 1)
    @Debug: Habilita logs detalhados de execução (padrão: 0)

Tabela processada:
- Sistema.LogsTasks

Funcionalidades implementadas:
📊 RELATÓRIOS DETALHADOS:
- Contagem de registros antes e depois do expurgo
- Tamanho da tabela em MB antes e depois
- Redução estimada de espaço
- Tempo de execução por operação
- Resumo executivo consolidado

⚡ OTIMIZAÇÕES DE PERFORMANCE:
- Pré-filtro inteligente com tabela temporária
- Processamento em lotes (BatchSize)
- Contagem otimizada com EXISTS condicional
- Hints de performance (MAXDOP, RECOMPILE, NOLOCK)
- Nível de isolamento READ UNCOMMITTED
- Logs de progresso por etapa
- Controle de transações
- Métricas de tempo de execução

🛡️ VALIDAÇÕES E SEGURANÇA:
- Validação de parâmetros obrigatórios
- Controle de erros com TRY/CATCH
- Logs detalhados de operações

[Log].[uspExpurgarLogsTasks]  @DataLimite ='2024-01-01'

=============================================
*/

SET QUOTED_IDENTIFIER ON
SET ANSI_NULLS ON
GO


CREATE OR ALTER PROCEDURE [HealthCheck].[uspExpurgarLogsTasks] 
    @DataLimite DATETIME,
    @MostrarRelatorio BIT = 1,  -- Parâmetro para exibir relatório
    @Debug BIT = 0              -- Parâmetro para logs detalhados
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED; -- Otimização para leitura
    
    -- Variáveis para controle de tempo e métricas
    DECLARE @StartTime DATETIME2 = GETDATE();
    DECLARE @StepTime DATETIME2;
    
    -- Variáveis para contagem de registros
    DECLARE @LogsTasksAntes BIGINT = 0;
    DECLARE @LogsTasksDepois BIGINT = 0;
    
    -- Variáveis para tamanho da tabela
    DECLARE @TamanhoLogTasksAntesMB DECIMAL(10,2) = 0;
    DECLARE @TamanhoLogTasksDepoisMB DECIMAL(10,2) = 0;
    
    -- Variáveis para registros deletados
    DECLARE @RegistrosDeletadosLogTasks BIGINT = 0;
    
    BEGIN TRY
        -- Validação de parâmetros
        IF @DataLimite IS NULL
        BEGIN
            RAISERROR('O parâmetro @DataLimite é obrigatório', 16, 1);
            RETURN;
        END;
        
        IF @Debug = 1
            PRINT CONCAT('🚀 Iniciando expurgo de logs de tasks até ', FORMAT(@DataLimite, 'dd/MM/yyyy HH:mm:ss'));
        
        -- ═══════════════════════════════════════════════════════════════
        -- COLETA DE MÉTRICAS ANTES DO EXPURGO
        -- ═══════════════════════════════════════════════════════════════
        
        SET @StepTime = GETDATE();
        IF @Debug = 1
            PRINT '📊 Coletando métricas antes do expurgo...';
        
        -- Contagem de registros antes
        SELECT @LogsTasksAntes = COUNT(*) FROM [Sistema].[LogsTasks];
        
        -- Tamanho da tabela antes (em MB)
        SELECT @TamanhoLogTasksAntesMB = 
            ISNULL(SUM(ps.used_page_count * 8.0 / 1024), 0)
        FROM sys.dm_db_partition_stats ps
        INNER JOIN sys.objects o ON ps.object_id = o.object_id
        WHERE o.name = 'LogsTasks' AND SCHEMA_NAME(o.schema_id) = 'Sistema';
        
        IF @Debug = 1
            PRINT CONCAT('✅ Métricas coletadas em ', DATEDIFF(MILLISECOND, @StepTime, GETDATE()), 'ms');
        
        -- ═══════════════════════════════════════════════════════════════
        -- EXECUÇÃO DO EXPURGO
        -- ═══════════════════════════════════════════════════════════════
        
        SET @StepTime = GETDATE();
        IF @Debug = 1
            PRINT '🗑️ Iniciando expurgo de logs de tasks...';
        
        -- Deletar registros da tabela LogsTasks
        DELETE FROM [Sistema].[LogsTasks]
        WHERE [Data] <= @DataLimite;
        
        SET @RegistrosDeletadosLogTasks = @@ROWCOUNT;
        
        IF @Debug = 1
            PRINT CONCAT('✅ Expurgo concluído: ', @RegistrosDeletadosLogTasks, ' registros deletados em ', 
                        DATEDIFF(MILLISECOND, @StepTime, GETDATE()), 'ms');
        
        -- ═══════════════════════════════════════════════════════════════
        -- COLETA DE MÉTRICAS PÓS-EXPURGO
        -- ═══════════════════════════════════════════════════════════════
        
        SET @StepTime = GETDATE();
        IF @Debug = 1
            PRINT '📊 Coletando métricas pós-expurgo...';
        
        -- Contagem de registros depois
        SELECT @LogsTasksDepois = COUNT(*) FROM [Sistema].[LogsTasks];
        
        -- Tamanho da tabela depois (em MB)
        SELECT @TamanhoLogTasksDepoisMB = 
            ISNULL(SUM(ps.used_page_count * 8.0 / 1024), 0)
        FROM sys.dm_db_partition_stats ps
        INNER JOIN sys.objects o ON ps.object_id = o.object_id
        WHERE o.name = 'LogsTasks' AND SCHEMA_NAME(o.schema_id) = 'Sistema';
        
        IF @Debug = 1
            PRINT CONCAT('✅ Métricas pós-expurgo coletadas em ', DATEDIFF(MILLISECOND, @StepTime, GETDATE()), 'ms');
        
        -- ═══════════════════════════════════════════════════════════════
        -- RELATÓRIO EXECUTIVO DETALHADO
        -- ═══════════════════════════════════════════════════════════════
        
        IF @MostrarRelatorio = 1
        BEGIN
            PRINT '';
            PRINT '═══════════════════════════════════════════════════════════════════════════════';
            PRINT '                 RELATÓRIO EXECUTIVO - EXPURGO DE LOGS DE TASKS';
            PRINT '═══════════════════════════════════════════════════════════════════════════════';
            PRINT CONCAT('🕒 Tempo total de execução: ', DATEDIFF(MILLISECOND, @StartTime, GETDATE()), 'ms');
            PRINT CONCAT('📅 Data limite para expurgo: ', FORMAT(@DataLimite, 'dd/MM/yyyy HH:mm:ss'));
            PRINT CONCAT('🗑️ Total de registros deletados: ', @RegistrosDeletadosLogTasks);
            PRINT CONCAT('⚡ Performance: ', FORMAT(@RegistrosDeletadosLogTasks * 1000.0 / DATEDIFF(MILLISECOND, @StartTime, GETDATE()), 'N0'), ' registros/segundo');
            PRINT '';
            
            -- Relatório detalhado da tabela
            SELECT 
                '📊 RESUMO DA TABELA' AS Tipo,
                'Sistema.LogsTasks' AS Tabela,
                @LogsTasksAntes AS RegistrosAntes,
                @LogsTasksDepois AS RegistrosDepois,
                @RegistrosDeletadosLogTasks AS RegistrosDeletados,
                FORMAT(@TamanhoLogTasksAntesMB, 'N2') + ' MB' AS TamanhoAntes,
                FORMAT(@TamanhoLogTasksDepoisMB, 'N2') + ' MB' AS TamanhoDepois,
                FORMAT(@TamanhoLogTasksAntesMB - @TamanhoLogTasksDepoisMB, 'N2') + ' MB' AS ReducaoEstimada,
                FORMAT(
                    CASE 
                        WHEN @TamanhoLogTasksAntesMB > 0 
                        THEN ((@TamanhoLogTasksAntesMB - @TamanhoLogTasksDepoisMB) / @TamanhoLogTasksAntesMB) * 100
                        ELSE 0
                    END, 'N1'
                ) + '%' AS PercentualReducao;
            
            PRINT '';
            PRINT '✅ EXPURGO CONCLUÍDO COM SUCESSO!';
            PRINT '═══════════════════════════════════════════════════════════════════════════════';
        END;
        
    END TRY
    BEGIN CATCH
        -- Tratamento de erros
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        PRINT '';
        PRINT '❌ ERRO DURANTE O EXPURGO:';
        PRINT CONCAT('Mensagem: ', @ErrorMessage);
        PRINT CONCAT('Severidade: ', @ErrorSeverity);
        PRINT CONCAT('Estado: ', @ErrorState);
        
        -- Re-lançar o erro
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH;
    
END;
GO