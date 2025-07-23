-- =============================================
-- Procedure: uspExecutarCarregamentoCompleto
-- Descrição: Procedure wrapper para execução completa
--            do carregamento de dimensões e fatos
--            Ideal para chamada no Azure Data Factory
-- Autor: Sistema
-- Data: 2024
-- =============================================

CREATE OR ALTER PROCEDURE [dbo].[uspExecutarCarregamentoCompleto]
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Variáveis de controle
    DECLARE @InicioProcessamento DATETIME2(2) = GETDATE();
    DECLARE @FimProcessamento DATETIME2(2);
    DECLARE @TempoExecucao VARCHAR(20);
    DECLARE @ErrorOcorrido BIT = 0;
    
    BEGIN TRY
        -- Log de início do processamento
        PRINT '=========================================';
        PRINT 'INÍCIO DO CARREGAMENTO COMPLETO BI MÉTRICAS';
        PRINT 'Data/Hora: ' + CONVERT(VARCHAR(20), @InicioProcessamento, 120);
        PRINT '=========================================';
        
        -- ETAPA 1: Carregamento da Dimensão Clientes (com SCD Tipo 2)
        PRINT '';
        PRINT '1. CARREGANDO DIMENSÃO CLIENTES...';
        DECLARE @InicioClientes DATETIME2(2) = GETDATE();
        
        EXEC [DM_MetricasClientes].[uspLoadDimClientes];
        
        DECLARE @FimClientes DATETIME2(2) = GETDATE();
        DECLARE @TempoClientes INT = DATEDIFF(SECOND, @InicioClientes, @FimClientes);
        
        PRINT '✓ Dimensão Clientes carregada com sucesso!';
        PRINT '  Tempo de execução: ' + CAST(@TempoClientes AS VARCHAR(10)) + ' segundos';
        
        -- ETAPA 2: Carregamento da Tabela Fato Métricas Clientes
        PRINT '';
        PRINT '2. CARREGANDO TABELA FATO MÉTRICAS...';
        DECLARE @InicioFato DATETIME2(2) = GETDATE();
        
        EXEC [DM_MetricasClientes].[uspLoadFatoMetricasClientes];
        
        DECLARE @FimFato DATETIME2(2) = GETDATE();
        DECLARE @TempoFato INT = DATEDIFF(SECOND, @InicioFato, @FimFato);
        
        PRINT '✓ Tabela Fato Métricas carregada com sucesso!';
        PRINT '  Tempo de execução: ' + CAST(@TempoFato AS VARCHAR(10)) + ' segundos';
        
        -- Cálculo do tempo total
        SET @FimProcessamento = GETDATE();
        DECLARE @TempoTotal INT = DATEDIFF(SECOND, @InicioProcessamento, @FimProcessamento);
        
        -- Log de conclusão com sucesso
        PRINT '';
        PRINT '=========================================';
        PRINT '✓ CARREGAMENTO CONCLUÍDO COM SUCESSO!';
        PRINT '=========================================';
        PRINT 'Resumo da Execução:';
        PRINT '• Dimensão Clientes: ' + CAST(@TempoClientes AS VARCHAR(10)) + 's';
        PRINT '• Fato Métricas: ' + CAST(@TempoFato AS VARCHAR(10)) + 's';
        PRINT '• Tempo Total: ' + CAST(@TempoTotal AS VARCHAR(10)) + 's';
        PRINT 'Data/Hora Final: ' + CONVERT(VARCHAR(20), @FimProcessamento, 120);
        PRINT '=========================================';
        
    END TRY
    BEGIN CATCH
        SET @ErrorOcorrido = 1;
        SET @FimProcessamento = GETDATE();
        
        -- Captura detalhes do erro
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        DECLARE @ErrorProcedure NVARCHAR(128) = ISNULL(ERROR_PROCEDURE(), 'uspExecutarCarregamentoCompleto');
        DECLARE @ErrorLine INT = ERROR_LINE();
        DECLARE @TempoAteErro INT = DATEDIFF(SECOND, @InicioProcessamento, @FimProcessamento);
        
        -- Log detalhado do erro
        PRINT '';
        PRINT '=========================================';
        PRINT '❌ ERRO NO CARREGAMENTO BI MÉTRICAS';
        PRINT '=========================================';
        PRINT 'Detalhes do Erro:';
        PRINT '• Procedure: ' + @ErrorProcedure;
        PRINT '• Linha: ' + CAST(@ErrorLine AS VARCHAR(10));
        PRINT '• Severidade: ' + CAST(@ErrorSeverity AS VARCHAR(10));
        PRINT '• Estado: ' + CAST(@ErrorState AS VARCHAR(10));
        PRINT '• Tempo até erro: ' + CAST(@TempoAteErro AS VARCHAR(10)) + 's';
        PRINT '• Data/Hora do Erro: ' + CONVERT(VARCHAR(20), @FimProcessamento, 120);
        PRINT '';
        PRINT 'Mensagem do Erro:';
        PRINT @ErrorMessage;
        PRINT '=========================================';
        
        -- Re-propagar o erro para o ADF com contexto
        DECLARE @ErrorCompleto NVARCHAR(4000) = 
            'Erro no carregamento BI Métricas - Procedure: ' + @ErrorProcedure + 
            ' | Linha: ' + CAST(@ErrorLine AS VARCHAR(10)) + 
            ' | Mensagem: ' + @ErrorMessage;
            
        RAISERROR(@ErrorCompleto, @ErrorSeverity, @ErrorState);
    END CATCH
    
    -- Log final de status
    IF @ErrorOcorrido = 0
    BEGIN
        PRINT '';
        PRINT 'STATUS: SUCESSO ✓';
        RETURN 0; -- Sucesso
    END
    ELSE
    BEGIN
        PRINT '';
        PRINT 'STATUS: FALHA ❌';
        RETURN 1; -- Erro
    END
END
GO

-- =============================================
-- Comentários de Uso no Azure Data Factory:
-- =============================================
-- 
-- 1. Configurar Linked Service para o SQL Server
-- 2. Usar atividade "Stored Procedure" 
-- 3. Configurar:
--    - Stored Procedure Name: [dbo].[uspExecutarCarregamentoCompleto]
--    - Timeout: 01:00:00 (1 hora)
--    - Retry: 2 tentativas
--    - Retry Interval: 30 segundos
-- 
-- 4. Dependência: Executar APÓS o ForEach terminar
-- 5. Monitoramento: Verificar logs no ADF e no SQL Server
-- 
-- =============================================