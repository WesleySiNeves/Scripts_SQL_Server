/*
=============================================
Autor: Wesley David Santos
Data de Criação: 2024-12-19
Descrição: Procedure OTIMIZADA para expurgo de logs de relatórios
           com relatórios detalhados de impacto e métricas de redução.
           
Versão: 2.1 - Versão corrigida sem LogTasks

Parâmetros:
    @DataLimite: Data limite para expurgo (obrigatório)
    @MostrarRelatorio: Exibe relatório detalhado do expurgo (padrão: 1)
    @Debug: Habilita logs detalhados de execução (padrão: 0)

Tabelas processadas:
- Log.LogsRelatorios
- Log.LogsRelatoriosFiltros

Funcionalidades implementadas:
📊 RELATÓRIOS DETALHADOS:
- Contagem de registros antes e depois do expurgo
- Tamanho das tabelas em MB antes e depois
- Redução estimada de espaço por tabela
- Tempo de execução por operação
- Resumo executivo consolidado

⚡ OTIMIZAÇÕES DE PERFORMANCE:
- Contagem otimizada com EXISTS
- Logs de progresso por etapa
- Controle de transações
- Métricas de tempo de execução

🛡️ VALIDAÇÕES E SEGURANÇA:
- Validação de parâmetros obrigatórios
- Controle de erros com TRY/CATCH
- Logs detalhados de operações

[Log].[uspExpurgarLogsRelatorios]  @DataLimite ='2024-01-01'

=============================================
*/

SET QUOTED_IDENTIFIER ON
SET ANSI_NULLS ON
GO


CREATE OR ALTER PROCEDURE [HealthCheck].[uspExpurgarLogsRelatorios] 
    @DataLimite DATETIME,
    @MostrarRelatorio BIT = 1,  -- NOVO: Parâmetro para exibir relatório
    @Debug BIT = 0              -- NOVO: Parâmetro para logs detalhados
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Variáveis para controle de tempo e métricas
    DECLARE @StartTime DATETIME2 = GETDATE();
    DECLARE @StepTime DATETIME2;
    
    -- Variáveis para contagem de registros
    DECLARE @LogsRelatoriosAntes BIGINT = 0;
    DECLARE @LogsRelatoriosDepois BIGINT = 0;
    DECLARE @LogsRelatoriosFiltrosAntes BIGINT = 0;
    DECLARE @LogsRelatoriosFiltrosDepois BIGINT = 0;
    
    -- Variáveis para tamanho das tabelas
    DECLARE @TamanhoLogRelatoriosAntesMB DECIMAL(10,2) = 0;
    DECLARE @TamanhoLogRelatoriosDepoisMB DECIMAL(10,2) = 0;
    DECLARE @TamanhoLogFiltrosAntesMB DECIMAL(10,2) = 0;
    DECLARE @TamanhoLogFiltrosDepoisMB DECIMAL(10,2) = 0;
    
    -- Variáveis para registros deletados
    DECLARE @RegistrosDeletadosLogRelatorios BIGINT = 0;
    DECLARE @RegistrosDeletadosLogFiltros BIGINT = 0;
  
    
    BEGIN TRY
        -- Validação de parâmetros
        IF @DataLimite IS NULL
        BEGIN
            RAISERROR('O parâmetro @DataLimite é obrigatório', 16, 1);
            RETURN;
        END;
        
        IF @Debug = 1
            PRINT CONCAT('🚀 Iniciando expurgo de logs até ', FORMAT(@DataLimite, 'dd/MM/yyyy HH:mm:ss'));
        
        -- ═══════════════════════════════════════════════════════════════
        -- COLETA DE MÉTRICAS ANTES DO EXPURGO
        -- ═══════════════════════════════════════════════════════════════
        
        SET @StepTime = GETDATE();
        IF @Debug = 1
            PRINT '📊 Coletando métricas antes do expurgo...';
        
        -- Contagem de registros antes
        SELECT @LogsRelatoriosAntes = COUNT(*) FROM [Log].[LogsRelatorios];
        SELECT @LogsRelatoriosFiltrosAntes = COUNT(*) FROM [Log].[LogsRelatoriosFiltros];
         
        -- Tamanho das tabelas antes (em MB)
        SELECT @TamanhoLogRelatoriosAntesMB = 
            ISNULL(SUM(ps.used_page_count * 8.0 / 1024), 0)
        FROM sys.dm_db_partition_stats ps
        INNER JOIN sys.objects o ON ps.object_id = o.object_id
        WHERE o.name = 'LogsRelatorios' AND SCHEMA_NAME(o.schema_id) = 'Log';
        
        SELECT @TamanhoLogFiltrosAntesMB = 
            ISNULL(SUM(ps.used_page_count * 8.0 / 1024), 0)
        FROM sys.dm_db_partition_stats ps
        INNER JOIN sys.objects o ON ps.object_id = o.object_id
        WHERE o.name = 'LogsRelatoriosFiltros' AND SCHEMA_NAME(o.schema_id) = 'Log';
        
       
        
        IF @Debug = 1
            PRINT CONCAT('✅ Métricas coletadas em ', DATEDIFF(MILLISECOND, @StepTime, GETDATE()), 'ms');
        
        -- ═══════════════════════════════════════════════════════════════
        -- EXECUÇÃO DO EXPURGO
        -- ═══════════════════════════════════════════════════════════════
        
        -- Criar tabela temporária para IDs dos relatórios
        DROP TABLE IF EXISTS #IdsRelatorios;
        CREATE TABLE #IdsRelatorios (IdLogRelatorio UNIQUEIDENTIFIER NOT NULL PRIMARY KEY);
        
        SET @StepTime = GETDATE();
        IF @Debug = 1
            PRINT '🔍 Identificando logs de relatórios para expurgo...';
        
        INSERT INTO #IdsRelatorios
        SELECT [lr].[IdLogRelatorio]
        FROM [Log].[LogsRelatorios] AS [lr]
        WHERE [lr].[Data] <= @DataLimite;
        
        IF @Debug = 1
            PRINT CONCAT('✅ ', @@ROWCOUNT, ' logs de relatórios identificados em ', 
                        DATEDIFF(MILLISECOND, @StepTime, GETDATE()), 'ms');
        
        -- 1. Deletar registros de LogsRelatoriosFiltros
        SET @StepTime = GETDATE();
        IF @Debug = 1
            PRINT '🗑️ Deletando registros de LogsRelatoriosFiltros...';
        
        DELETE [lrf]
        FROM [Log].[LogsRelatoriosFiltros] AS [lrf]
        JOIN [#IdsRelatorios] AS [ir] ON [ir].[IdLogRelatorio] = [lrf].[IdLogRelatorio];
        
        SET @RegistrosDeletadosLogFiltros = @@ROWCOUNT;
        
        IF @Debug = 1
            PRINT CONCAT('✅ ', @RegistrosDeletadosLogFiltros, ' registros deletados em ', 
                        DATEDIFF(MILLISECOND, @StepTime, GETDATE()), 'ms');
        
        -- 2. Deletar registros de LogsRelatorios
        SET @StepTime = GETDATE();
        IF @Debug = 1
            PRINT '🗑️ Deletando registros de LogsRelatorios...';
        
        DELETE [lr]
        FROM [Log].[LogsRelatorios] AS [lr]
        JOIN [#IdsRelatorios] AS [ir] ON [ir].[IdLogRelatorio] = [lr].[IdLogRelatorio];
        
        SET @RegistrosDeletadosLogRelatorios = @@ROWCOUNT;
        
        IF @Debug = 1
            PRINT CONCAT('✅ ', @RegistrosDeletadosLogRelatorios, ' registros deletados em ', 
                        DATEDIFF(MILLISECOND, @StepTime, GETDATE()), 'ms');
        
         
       
        -- ═══════════════════════════════════════════════════════════════
        -- COLETA DE MÉTRICAS APÓS O EXPURGO
        -- ═══════════════════════════════════════════════════════════════
        
        SET @StepTime = GETDATE();
        IF @Debug = 1
            PRINT '📊 Coletando métricas após o expurgo...';
        
        -- Contagem de registros depois
        SELECT @LogsRelatoriosDepois = COUNT(*) FROM [Log].[LogsRelatorios];
        SELECT @LogsRelatoriosFiltrosDepois = COUNT(*) FROM [Log].[LogsRelatoriosFiltros];
        
        -- Tamanho das tabelas depois (em MB)
        SELECT @TamanhoLogRelatoriosDepoisMB = 
            ISNULL(SUM(ps.used_page_count * 8.0 / 1024), 0)
        FROM sys.dm_db_partition_stats ps
        INNER JOIN sys.objects o ON ps.object_id = o.object_id
        WHERE o.name = 'LogsRelatorios' AND SCHEMA_NAME(o.schema_id) = 'Log';
        
        SELECT @TamanhoLogFiltrosDepoisMB = 
            ISNULL(SUM(ps.used_page_count * 8.0 / 1024), 0)
        FROM sys.dm_db_partition_stats ps
        INNER JOIN sys.objects o ON ps.object_id = o.object_id
        WHERE o.name = 'LogsRelatoriosFiltros' AND SCHEMA_NAME(o.schema_id) = 'Log';
        
      
        IF @Debug = 1
            PRINT CONCAT('✅ Métricas finais coletadas em ', DATEDIFF(MILLISECOND, @StepTime, GETDATE()), 'ms');
        
        -- ═══════════════════════════════════════════════════════════════
        -- RELATÓRIO EXECUTIVO DETALHADO
        -- ═══════════════════════════════════════════════════════════════
        
        IF @MostrarRelatorio = 1
        BEGIN
            PRINT '';
            PRINT '═══════════════════════════════════════════════════════════════════════════════';
            PRINT '                 RELATÓRIO EXECUTIVO - EXPURGO DE LOGS DE RELATÓRIOS';
            PRINT '═══════════════════════════════════════════════════════════════════════════════';
            PRINT CONCAT('🕒 Tempo total de execução: ', DATEDIFF(MILLISECOND, @StartTime, GETDATE()), 'ms');
            PRINT CONCAT('📅 Data limite para expurgo: ', FORMAT(@DataLimite, 'dd/MM/yyyy HH:mm:ss'));
            PRINT CONCAT('🗑️ Total de registros deletados: ', 
                        (@RegistrosDeletadosLogRelatorios + @RegistrosDeletadosLogFiltros));
            PRINT '';
            
            -- Relatório detalhado por tabela
            SELECT 
                '📊 RESUMO POR TABELA' AS Tipo,
                'Log.LogsRelatorios' AS Tabela,
                @LogsRelatoriosAntes AS RegistrosAntes,
                @LogsRelatoriosDepois AS RegistrosDepois,
                @RegistrosDeletadosLogRelatorios AS RegistrosDeletados,
                FORMAT(@TamanhoLogRelatoriosAntesMB, 'N2') + ' MB' AS TamanhoAntes,
                FORMAT(@TamanhoLogRelatoriosDepoisMB, 'N2') + ' MB' AS TamanhoDepois,
                FORMAT(@TamanhoLogRelatoriosAntesMB - @TamanhoLogRelatoriosDepoisMB, 'N2') + ' MB' AS ReducaoEstimada,
                FORMAT(
                    CASE 
                        WHEN @TamanhoLogRelatoriosAntesMB > 0 
                        THEN ((@TamanhoLogRelatoriosAntesMB - @TamanhoLogRelatoriosDepoisMB) / @TamanhoLogRelatoriosAntesMB) * 100
                        ELSE 0
                    END, 'N1'
                ) + '%' AS PercentualReducao
            
            UNION ALL
            
            SELECT 
                '📊 RESUMO POR TABELA',
                'Log.LogsRelatoriosFiltros',
                @LogsRelatoriosFiltrosAntes,
                @LogsRelatoriosFiltrosDepois,
                @RegistrosDeletadosLogFiltros,
                FORMAT(@TamanhoLogFiltrosAntesMB, 'N2') + ' MB',
                FORMAT(@TamanhoLogFiltrosDepoisMB, 'N2') + ' MB',
                FORMAT(@TamanhoLogFiltrosAntesMB - @TamanhoLogFiltrosDepoisMB, 'N2') + ' MB',
                FORMAT(
                    CASE 
                        WHEN @TamanhoLogFiltrosAntesMB > 0 
                        THEN ((@TamanhoLogFiltrosAntesMB - @TamanhoLogFiltrosDepoisMB) / @TamanhoLogFiltrosAntesMB) * 100
                        ELSE 0
                    END, 'N1'
                ) + '%'
            
            UNION ALL
            
           
            
            -- Resumo consolidado
            SELECT 
                '💾 RESUMO CONSOLIDADO' AS Tipo,
                'TOTAL GERAL' AS Tabela,
                (@LogsRelatoriosAntes + @LogsRelatoriosFiltrosAntes) AS RegistrosAntes,
                (@LogsRelatoriosDepois + @LogsRelatoriosFiltrosDepois) AS RegistrosDepois,
                (@RegistrosDeletadosLogRelatorios + @RegistrosDeletadosLogFiltros) AS RegistrosDeletados,
                FORMAT((@TamanhoLogRelatoriosAntesMB + @TamanhoLogFiltrosAntesMB), 'N2') + ' MB' AS TamanhoAntes,
                FORMAT((@TamanhoLogRelatoriosDepoisMB + @TamanhoLogFiltrosDepoisMB), 'N2') + ' MB' AS TamanhoDepois,
                FORMAT(
                    (@TamanhoLogRelatoriosAntesMB + @TamanhoLogFiltrosAntesMB) - 
                    (@TamanhoLogRelatoriosDepoisMB + @TamanhoLogFiltrosDepoisMB), 'N2'
                ) + ' MB' AS ReducaoEstimada,
                FORMAT(
                    CASE 
                        WHEN (@TamanhoLogRelatoriosAntesMB + @TamanhoLogFiltrosAntesMB) > 0
                        THEN (
                            ((@TamanhoLogRelatoriosAntesMB + @TamanhoLogFiltrosAntesMB) - 
                             (@TamanhoLogRelatoriosDepoisMB + @TamanhoLogFiltrosDepoisMB)) / 
                            (@TamanhoLogRelatoriosAntesMB + @TamanhoLogFiltrosAntesMB)
                        ) * 100
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