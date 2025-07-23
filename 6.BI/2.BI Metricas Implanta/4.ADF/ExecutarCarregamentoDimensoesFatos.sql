-- =============================================
-- Script: ExecutarCarregamentoDimensoesFatos.sql
-- Descrição: Script para execução no Azure Data Factory
--            após o término do ForEach para carregar
--            dimensões e fatos na ordem correta
-- Autor: Sistema
-- Data: 2024
-- =============================================

BEGIN TRY
    -- Log de início do processamento
    PRINT '=========================================';
    PRINT 'INÍCIO DO CARREGAMENTO DE DIMENSÕES E FATOS';
    PRINT 'Data/Hora: ' + CONVERT(VARCHAR(20), GETDATE(), 120);
    PRINT '=========================================';
    
    -- ETAPA 1: Carregamento da Dimensão Clientes (com SCD Tipo 2)
    PRINT '';
    PRINT '1. Executando carregamento da Dimensão Clientes...';
    PRINT 'Início: ' + CONVERT(VARCHAR(20), GETDATE(), 120);
    
    EXEC [DM_MetricasClientes].[uspLoadDimClientes];
    
    PRINT 'Dimensão Clientes carregada com sucesso!';
    PRINT 'Término: ' + CONVERT(VARCHAR(20), GETDATE(), 120);
    
    -- ETAPA 2: Carregamento da Tabela Fato Métricas Clientes
    PRINT '';
    PRINT '2. Executando carregamento da Tabela Fato Métricas...';
    PRINT 'Início: ' + CONVERT(VARCHAR(20), GETDATE(), 120);
    
    EXEC [DM_MetricasClientes].[uspLoadFatoMetricasClientes];
    
    PRINT 'Tabela Fato Métricas carregada com sucesso!';
    PRINT 'Término: ' + CONVERT(VARCHAR(20), GETDATE(), 120);
    
    -- Log de conclusão
    PRINT '';
    PRINT '=========================================';
    PRINT 'CARREGAMENTO CONCLUÍDO COM SUCESSO!';
    PRINT 'Data/Hora Final: ' + CONVERT(VARCHAR(20), GETDATE(), 120);
    PRINT '=========================================';
    
END TRY
BEGIN CATCH
    -- Tratamento de erro
    DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
    DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
    DECLARE @ErrorState INT = ERROR_STATE();
    DECLARE @ErrorProcedure NVARCHAR(128) = ERROR_PROCEDURE();
    DECLARE @ErrorLine INT = ERROR_LINE();
    
    PRINT '';
    PRINT '=========================================';
    PRINT 'ERRO NO CARREGAMENTO DE DIMENSÕES E FATOS';
    PRINT '=========================================';
    PRINT 'Procedure: ' + ISNULL(@ErrorProcedure, 'Script Principal');
    PRINT 'Linha: ' + CAST(@ErrorLine AS VARCHAR(10));
    PRINT 'Mensagem: ' + @ErrorMessage;
    PRINT 'Severidade: ' + CAST(@ErrorSeverity AS VARCHAR(10));
    PRINT 'Estado: ' + CAST(@ErrorState AS VARCHAR(10));
    PRINT 'Data/Hora do Erro: ' + CONVERT(VARCHAR(20), GETDATE(), 120);
    PRINT '=========================================';
    
    -- Re-propagar o erro para o ADF
    RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
END CATCH