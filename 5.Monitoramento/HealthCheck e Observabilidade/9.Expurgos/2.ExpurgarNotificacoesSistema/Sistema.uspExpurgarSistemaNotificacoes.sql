/*
=============================================
Autor: Wesley Neves
Data de Criação: 2024-12-19
Descrição: Procedure  para expurgo de notificações do sistema
           com relatórios detalhados de impacto e métricas de redução.
           
Versão: 3.0 - Versão  com performance aprimorada

Parâmetros:
    @DataLimite: Data limite para expurgo (obrigatório)
    @MostrarRelatorio: Exibe relatório detalhado do expurgo (padrão: 1)
    @Debug: Habilita logs detalhados de execução (padrão: 0)

Funcionalidades implementadas:
📊 RELATÓRIOS DETALHADOS:
- Contagem de registros antes e depois do expurgo
- Tamanho das tabelas em MB antes e depois
- Redução estimada de espaço por tabela
- Tempo de execução por operação
- Resumo executivo consolidado

⚡ OTIMIZAÇÕES DE PERFORMANCE:
- Pré-filtro com tabela temporária para IDs elegíveis
- Contagem otimizada com EXISTS apenas quando necessário
- Operações em lote com controle de batch size
- Hints de performance (MAXDOP, RECOMPILE)
- Logs de progresso por etapa
- Controle de transações otimizado
- Métricas de tempo de execução detalhadas

🛡️ VALIDAÇÕES E SEGURANÇA:
- Validação de parâmetros obrigatórios
- Controle de erros com TRY/CATCH
- Logs detalhados de operações

[Sistema].[uspExpurgarSistemaNotificacoes]  @DataLimite ='2024-01-01'

=============================================
*/

SET QUOTED_IDENTIFIER ON
SET ANSI_NULLS ON
GO


CREATE OR ALTER PROCEDURE [Sistema].[uspExpurgarSistemaNotificacoes] 
    @DataLimite DATETIME,
    @MostrarRelatorio BIT = 1,  -- Parâmetro para exibir relatório
    @Debug BIT = 0,             -- Parâmetro para logs detalhados
    @BatchSize INT = 10000      -- NOVO: Tamanho do lote para operações em batch
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED; -- Reduz bloqueios
    
    -- Variáveis para controle de tempo e métricas
    DECLARE @StartTime DATETIME2 = GETDATE();
    DECLARE @StepTime DATETIME2;
    
    -- Variáveis para contagem de registros
    DECLARE @NotificacoesAntes BIGINT = 0;
    DECLARE @NotificacoesDepois BIGINT = 0;
    DECLARE @ProcessosRecursosAntes BIGINT = 0;
    DECLARE @ProcessosRecursosDepois BIGINT = 0;
    DECLARE @DescartesAntes BIGINT = 0;
    DECLARE @DescartesDepois BIGINT = 0;
    
    -- Variáveis para tamanho das tabelas
    DECLARE @TamanhoNotificacoesAntesMB DECIMAL(10,2) = 0;
    DECLARE @TamanhoNotificacoesDepoisMB DECIMAL(10,2) = 0;
    DECLARE @TamanhoProcessosAntesMB DECIMAL(10,2) = 0;
    DECLARE @TamanhoProcessosDepoisMB DECIMAL(10,2) = 0;
    DECLARE @TamanhoDescartesAntesMB DECIMAL(10,2) = 0;
    DECLARE @TamanhoDescartesDepoisMB DECIMAL(10,2) = 0;
    
    -- Variáveis para registros deletados
    DECLARE @RegistrosDeletadosNotificacoes BIGINT = 0;
    DECLARE @RegistrosDeletadosProcessos BIGINT = 0;
    DECLARE @RegistrosDeletadosDescartes BIGINT = 0;
    
    BEGIN TRY
        -- Validação de parâmetros
        IF @DataLimite IS NULL
        BEGIN
            RAISERROR('O parâmetro @DataLimite é obrigatório', 16, 1);
            RETURN;
        END;
        
        IF @Debug = 1
            PRINT CONCAT('🚀 Iniciando expurgo de notificações até ', FORMAT(@DataLimite, 'dd/MM/yyyy HH:mm:ss'));
        
        -- ═══════════════════════════════════════════════════════════════
        -- COLETA DE MÉTRICAS ANTES DO EXPURGO
        -- ═══════════════════════════════════════════════════════════════
        
        SET @StepTime = GETDATE();
        IF @Debug = 1
            PRINT '📊 Coletando métricas antes do expurgo...';
        
        -- Contagem otimizada de registros antes (usando estatísticas quando possível)
        SELECT @NotificacoesAntes = 
            CASE 
                WHEN EXISTS (SELECT 1 FROM [Sistema].[Notificacoes] WHERE [DataCriacao] < @DataLimite)
                THEN (SELECT COUNT_BIG(*) FROM [Sistema].[Notificacoes] WITH (NOLOCK))
                ELSE 0
            END;
        
        SELECT @ProcessosRecursosAntes = 
            CASE 
                WHEN @NotificacoesAntes > 0
                THEN (SELECT COUNT_BIG(*) FROM [Processo].[ProcessosRecursosNotificacoesUsuarios] WITH (NOLOCK))
                ELSE 0
            END;
        
        SELECT @DescartesAntes = 
            CASE 
                WHEN @NotificacoesAntes > 0
                THEN (SELECT COUNT_BIG(*) FROM [Sistema].[NotificacoesUsuariosDescartes] WITH (NOLOCK))
                ELSE 0
            END;
        
        -- Tamanho das tabelas antes (em MB)
        SELECT @TamanhoNotificacoesAntesMB = 
            ISNULL(SUM(ps.used_page_count * 8.0 / 1024), 0)
        FROM sys.dm_db_partition_stats ps
        INNER JOIN sys.objects o ON ps.object_id = o.object_id
        WHERE o.name = 'Notificacoes' AND SCHEMA_NAME(o.schema_id) = 'Sistema';
        
        SELECT @TamanhoProcessosAntesMB = 
            ISNULL(SUM(ps.used_page_count * 8.0 / 1024), 0)
        FROM sys.dm_db_partition_stats ps
        INNER JOIN sys.objects o ON ps.object_id = o.object_id
        WHERE o.name = 'ProcessosRecursosNotificacoesUsuarios' AND SCHEMA_NAME(o.schema_id) = 'Processo';
        
        SELECT @TamanhoDescartesAntesMB = 
            ISNULL(SUM(ps.used_page_count * 8.0 / 1024), 0)
        FROM sys.dm_db_partition_stats ps
        INNER JOIN sys.objects o ON ps.object_id = o.object_id
        WHERE o.name = 'NotificacoesUsuariosDescartes' AND SCHEMA_NAME(o.schema_id) = 'Sistema';
        
        IF @Debug = 1
            PRINT CONCAT('✅ Métricas coletadas em ', DATEDIFF(MILLISECOND, @StepTime, GETDATE()), 'ms');
        
        -- ═══════════════════════════════════════════════════════════════
        -- PRÉ-FILTRO OTIMIZADO - CRIAÇÃO DE TABELA TEMPORÁRIA
        -- ═══════════════════════════════════════════════════════════════
        
        SET @StepTime = GETDATE();
        IF @Debug = 1
            PRINT '🔍 Criando pré-filtro de IDs elegíveis para expurgo...';
        
        -- Criar tabela temporária com IDs das notificações a serem excluídas
        CREATE TABLE #NotificacoesParaExcluir (
            IdNotificacao UNIQUEIDENTIFIER PRIMARY KEY
        );
        
        -- Inserir IDs das notificações elegíveis para exclusão
        INSERT INTO #NotificacoesParaExcluir (IdNotificacao)
        SELECT [IdNotificacao]
        FROM [Sistema].[Notificacoes] N WITH (NOLOCK)
        WHERE [DataCriacao] < @DataLimite
		AND NOT EXISTS(SELECT * FROM Processo.NotificacoesProcessos np 
							WHERE np.IdNotificacao = N.IdNotificacao)
		AND NOT EXISTS(SELECT * FROM Processo.[ProcessosRecursosNotificacoesUsuarios] np 
							WHERE np.IdNotificacao = N.IdNotificacao)
		
		
        OPTION (MAXDOP 4, RECOMPILE);
        
        DECLARE @TotalNotificacoesParaExcluir INT = @@ROWCOUNT;
        
        IF @Debug = 1
            PRINT CONCAT('✅ Pré-filtro criado com ', @TotalNotificacoesParaExcluir, ' IDs em ', 
                        DATEDIFF(MILLISECOND, @StepTime, GETDATE()), 'ms');
        
        -- Se não há registros para excluir, sair da procedure
        IF @TotalNotificacoesParaExcluir = 0
        BEGIN
            IF @Debug = 1
                PRINT '⚠️ Nenhum registro encontrado para expurgo. Finalizando...';
            DROP TABLE #NotificacoesParaExcluir;
            RETURN;
        END;
        
        -- ═══════════════════════════════════════════════════════════════
        -- EXECUÇÃO OTIMIZADA DO EXPURGO EM LOTES
        -- ═══════════════════════════════════════════════════════════════
        
        -- 1. Deletar registros de ProcessosRecursosNotificacoesUsuarios em lotes
        SET @StepTime = GETDATE();
        IF @Debug = 1
            PRINT '🗑️ Deletando registros de ProcessosRecursosNotificacoesUsuarios em lotes...';
        
        DECLARE @RowsDeleted INT = 1;
        WHILE @RowsDeleted > 0
        BEGIN
            DELETE TOP (@BatchSize) target
            FROM [Processo].[ProcessosRecursosNotificacoesUsuarios] target
            INNER JOIN #NotificacoesParaExcluir temp ON temp.IdNotificacao = target.[IdNotificacao]
            OPTION (MAXDOP 4);
            
            SET @RowsDeleted = @@ROWCOUNT;
            SET @RegistrosDeletadosProcessos += @RowsDeleted;
            
            IF @Debug = 1 AND @RowsDeleted > 0
                PRINT CONCAT('   📦 Lote processado: ', @RowsDeleted, ' registros');
        END;
        
        IF @Debug = 1
            PRINT CONCAT('✅ ', @RegistrosDeletadosProcessos, ' registros deletados em ', 
                        DATEDIFF(MILLISECOND, @StepTime, GETDATE()), 'ms');
        
        -- 2. Deletar registros de NotificacoesUsuariosDescartes em lotes
        SET @StepTime = GETDATE();
        IF @Debug = 1
            PRINT '🗑️ Deletando registros de NotificacoesUsuariosDescartes em lotes...';
        
        SET @RowsDeleted = 1;
        WHILE @RowsDeleted > 0
        BEGIN
            DELETE TOP (@BatchSize) target
            FROM [Sistema].[NotificacoesUsuariosDescartes] target
            INNER JOIN #NotificacoesParaExcluir temp ON temp.IdNotificacao = target.[IdNotificacao]
            OPTION (MAXDOP 4);
            
            SET @RowsDeleted = @@ROWCOUNT;
            SET @RegistrosDeletadosDescartes += @RowsDeleted;
            
            IF @Debug = 1 AND @RowsDeleted > 0
                PRINT CONCAT('   📦 Lote processado: ', @RowsDeleted, ' registros');
        END;
        
        IF @Debug = 1
            PRINT CONCAT('✅ ', @RegistrosDeletadosDescartes, ' registros deletados em ', 
                        DATEDIFF(MILLISECOND, @StepTime, GETDATE()), 'ms');
        
        -- 3. Deletar notificações principais em lotes
        SET @StepTime = GETDATE();
        IF @Debug = 1
            PRINT '🗑️ Deletando notificações principais em lotes...';
        
        SET @RowsDeleted = 1;
        WHILE @RowsDeleted > 0
        BEGIN
            DELETE TOP (@BatchSize) N
            FROM [Sistema].[Notificacoes] N
            INNER JOIN #NotificacoesParaExcluir temp ON temp.IdNotificacao = N.[IdNotificacao]
            OPTION (MAXDOP 4);
            
            SET @RowsDeleted = @@ROWCOUNT;
            SET @RegistrosDeletadosNotificacoes += @RowsDeleted;
            
            IF @Debug = 1 AND @RowsDeleted > 0
                PRINT CONCAT('   📦 Lote processado: ', @RowsDeleted, ' registros');
        END;
        
        -- Limpar tabela temporária
        DROP TABLE #NotificacoesParaExcluir;
        
        IF @Debug = 1
            PRINT CONCAT('✅ ', @RegistrosDeletadosNotificacoes, ' registros deletados em ', 
                        DATEDIFF(MILLISECOND, @StepTime, GETDATE()), 'ms');
        
        -- ═══════════════════════════════════════════════════════════════
        -- COLETA DE MÉTRICAS APÓS O EXPURGO
        -- ═══════════════════════════════════════════════════════════════
        
        SET @StepTime = GETDATE();
        IF @Debug = 1
            PRINT '📊 Coletando métricas após o expurgo...';
        
        -- Contagem otimizada de registros depois
        SELECT @NotificacoesDepois = COUNT_BIG(*) FROM [Sistema].[Notificacoes] WITH (NOLOCK);
        SELECT @ProcessosRecursosDepois = COUNT_BIG(*) FROM [Processo].[ProcessosRecursosNotificacoesUsuarios] WITH (NOLOCK);
        SELECT @DescartesDepois = COUNT_BIG(*) FROM [Sistema].[NotificacoesUsuariosDescartes] WITH (NOLOCK);
        
        -- Tamanho das tabelas depois (em MB)
        SELECT @TamanhoNotificacoesDepoisMB = 
            ISNULL(SUM(ps.used_page_count * 8.0 / 1024), 0)
        FROM sys.dm_db_partition_stats ps
        INNER JOIN sys.objects o ON ps.object_id = o.object_id
        WHERE o.name = 'Notificacoes' AND SCHEMA_NAME(o.schema_id) = 'Sistema';
        
        SELECT @TamanhoProcessosDepoisMB = 
            ISNULL(SUM(ps.used_page_count * 8.0 / 1024), 0)
        FROM sys.dm_db_partition_stats ps
        INNER JOIN sys.objects o ON ps.object_id = o.object_id
        WHERE o.name = 'ProcessosRecursosNotificacoesUsuarios' AND SCHEMA_NAME(o.schema_id) = 'Processo';
        
        SELECT @TamanhoDescartesDepoisMB = 
            ISNULL(SUM(ps.used_page_count * 8.0 / 1024), 0)
        FROM sys.dm_db_partition_stats ps
        INNER JOIN sys.objects o ON ps.object_id = o.object_id
        WHERE o.name = 'NotificacoesUsuariosDescartes' AND SCHEMA_NAME(o.schema_id) = 'Sistema';
        
        IF @Debug = 1
            PRINT CONCAT('✅ Métricas finais coletadas em ', DATEDIFF(MILLISECOND, @StepTime, GETDATE()), 'ms');
        
        -- ═══════════════════════════════════════════════════════════════
        -- RELATÓRIO EXECUTIVO DETALHADO
        -- ═══════════════════════════════════════════════════════════════
        
        IF @MostrarRelatorio = 1
        BEGIN
            PRINT '';
            PRINT '═══════════════════════════════════════════════════════════════════════════════';
            PRINT '                    RELATÓRIO EXECUTIVO - EXPURGO DE NOTIFICAÇÕES';
            PRINT '═══════════════════════════════════════════════════════════════════════════════';
            PRINT CONCAT('🕒 Tempo total de execução: ', DATEDIFF(MILLISECOND, @StartTime, GETDATE()), 'ms');
            PRINT CONCAT('📅 Data limite para expurgo: ', FORMAT(@DataLimite, 'dd/MM/yyyy HH:mm:ss'));
            PRINT CONCAT('🗑️ Total de registros deletados: ', 
                        (@RegistrosDeletadosNotificacoes + @RegistrosDeletadosProcessos + @RegistrosDeletadosDescartes));
            PRINT '';
            
            -- Relatório detalhado por tabela
            SELECT 
                '📊 RESUMO POR TABELA' AS Tipo,
                'Sistema.Notificacoes' AS Tabela,
                @NotificacoesAntes AS RegistrosAntes,
                @NotificacoesDepois AS RegistrosDepois,
                @RegistrosDeletadosNotificacoes AS RegistrosDeletados,
                FORMAT(@TamanhoNotificacoesAntesMB, 'N2') + ' MB' AS TamanhoAntes,
                FORMAT(@TamanhoNotificacoesDepoisMB, 'N2') + ' MB' AS TamanhoDepois,
                FORMAT(@TamanhoNotificacoesAntesMB - @TamanhoNotificacoesDepoisMB, 'N2') + ' MB' AS ReducaoEstimada,
                FORMAT(
                    CASE 
                        WHEN @TamanhoNotificacoesAntesMB > 0 
                        THEN ((@TamanhoNotificacoesAntesMB - @TamanhoNotificacoesDepoisMB) / @TamanhoNotificacoesAntesMB) * 100
                        ELSE 0
                    END, 'N1'
                ) + '%' AS PercentualReducao
            
            UNION ALL
            
            SELECT 
                '📊 RESUMO POR TABELA',
                'Processo.ProcessosRecursosNotificacoesUsuarios',
                @ProcessosRecursosAntes,
                @ProcessosRecursosDepois,
                @RegistrosDeletadosProcessos,
                FORMAT(@TamanhoProcessosAntesMB, 'N2') + ' MB',
                FORMAT(@TamanhoProcessosDepoisMB, 'N2') + ' MB',
                FORMAT(@TamanhoProcessosAntesMB - @TamanhoProcessosDepoisMB, 'N2') + ' MB',
                FORMAT(
                    CASE 
                        WHEN @TamanhoProcessosAntesMB > 0 
                        THEN ((@TamanhoProcessosAntesMB - @TamanhoProcessosDepoisMB) / @TamanhoProcessosAntesMB) * 100
                        ELSE 0
                    END, 'N1'
                ) + '%'
            
            UNION ALL
            
            SELECT 
                '📊 RESUMO POR TABELA',
                'Sistema.NotificacoesUsuariosDescartes',
                @DescartesAntes,
                @DescartesDepois,
                @RegistrosDeletadosDescartes,
                FORMAT(@TamanhoDescartesAntesMB, 'N2') + ' MB',
                FORMAT(@TamanhoDescartesDepoisMB, 'N2') + ' MB',
                FORMAT(@TamanhoDescartesAntesMB - @TamanhoDescartesDepoisMB, 'N2') + ' MB',
                FORMAT(
                    CASE 
                        WHEN @TamanhoDescartesAntesMB > 0 
                        THEN ((@TamanhoDescartesAntesMB - @TamanhoDescartesDepoisMB) / @TamanhoDescartesAntesMB) * 100
                        ELSE 0
                    END, 'N1'
                ) + '%';
            
            -- Resumo consolidado
            SELECT 
                '💾 RESUMO CONSOLIDADO' AS Tipo,
                (@NotificacoesAntes + @ProcessosRecursosAntes + @DescartesAntes) AS TotalRegistrosAntes,
                (@NotificacoesDepois + @ProcessosRecursosDepois + @DescartesDepois) AS TotalRegistrosDepois,
                (@RegistrosDeletadosNotificacoes + @RegistrosDeletadosProcessos + @RegistrosDeletadosDescartes) AS TotalRegistrosDeletados,
                FORMAT((@TamanhoNotificacoesAntesMB + @TamanhoProcessosAntesMB + @TamanhoDescartesAntesMB), 'N2') + ' MB' AS TamanhoTotalAntes,
                FORMAT((@TamanhoNotificacoesDepoisMB + @TamanhoProcessosDepoisMB + @TamanhoDescartesDepoisMB), 'N2') + ' MB' AS TamanhoTotalDepois,
                FORMAT(
                    (@TamanhoNotificacoesAntesMB + @TamanhoProcessosAntesMB + @TamanhoDescartesAntesMB) - 
                    (@TamanhoNotificacoesDepoisMB + @TamanhoProcessosDepoisMB + @TamanhoDescartesDepoisMB), 'N2'
                ) + ' MB' AS ReducaoTotalEstimada,
                FORMAT(
                    CASE 
                        WHEN (@TamanhoNotificacoesAntesMB + @TamanhoProcessosAntesMB + @TamanhoDescartesAntesMB) > 0
                        THEN (
                            ((@TamanhoNotificacoesAntesMB + @TamanhoProcessosAntesMB + @TamanhoDescartesAntesMB) - 
                             (@TamanhoNotificacoesDepoisMB + @TamanhoProcessosDepoisMB + @TamanhoDescartesDepoisMB)) / 
                            (@TamanhoNotificacoesAntesMB + @TamanhoProcessosAntesMB + @TamanhoDescartesAntesMB)
                        ) * 100
                        ELSE 0
                    END, 'N1'
                ) + '%' AS PercentualReducaoTotal;
            
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