-- =============================================
-- Procedure: uspLoadFatoMetricasClientes
-- Descrição: Carga da tabela fato usando MERGE
--            Insere apenas se valor mudou ou não existe
-- Autor: Sistema
-- Data: 2024
-- =============================================

CREATE OR ALTER PROCEDURE [DM_MetricasClientes].[uspLoadFatoMetricasClientes]
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRAN 

        -- Criar tabela temporária para dados base
        DROP TABLE IF EXISTS #DadosBase;
        
        CREATE TABLE #DadosBase
        (
            [SiglaCliente]        VARCHAR(100),
            [CodSistema]          SMALLINT,
            [Ordem]               TINYINT,
            [NomeMetrica]         VARCHAR(50),
            [TabelaConsultada]    VARCHAR(128),
            [Valor]               VARCHAR(MAX),
            [SkCliente]           SMALLINT,
            [SkProduto]           SMALLINT,
            [SkMetrica]           SMALLINT,
            [TipoRetorno]         VARCHAR(20),
            [SkTabelasConsultada] SMALLINT
        );

        -- Carregar dados base com joins das dimensões
        WITH MetricasClientes AS (
            SELECT
                SiglaCliente = REPLACE(Cliente, '-', '/'),
                CodSistema,
                Ordem,
                NomeMetrica,
                TabelaConsultada,
                Valor
            FROM Staging.MetricasClientes metrica
        )
        INSERT INTO #DadosBase
        SELECT
            metrica.SiglaCliente,
            metrica.CodSistema,
            metrica.Ordem,
            metrica.NomeMetrica,
            metrica.TabelaConsultada,
            metrica.Valor,
            cliente.SkCliente,
            produto.SkProduto,
            d_metrica.SkMetrica,
            d_metrica.TipoRetorno,
            tabela.SkTabelasConsultada
        FROM
            MetricasClientes metrica
            JOIN Shared.DimClientes cliente ON cliente.SiglaImplanta = metrica.SiglaCliente
            LEFT JOIN Shared.DimProdutos produto ON produto.SkProduto = metrica.CodSistema
            LEFT JOIN DM_MetricasClientes.DimMetricas d_metrica ON d_metrica.NomeMetrica = metrica.NomeMetrica
            LEFT JOIN DM_MetricasClientes.DimTabelasConsultadas tabela ON tabela.Nome = metrica.TabelaConsultada
        WHERE 
            produto.SkProduto IS NOT NULL 
            AND d_metrica.SkMetrica IS NOT NULL 
            AND tabela.SkTabelasConsultada IS NOT NULL;

        -- Preparar dados para MERGE com conversão de tipos
        DROP TABLE IF EXISTS #DadosParaMerge;
        
        CREATE TABLE #DadosParaMerge
        (
            [SkTempo]                 DATE,
            [SkCliente]               SMALLINT,
            [SkProduto]               SMALLINT,
            [SkMetrica]               SMALLINT,
            [SkDimTabelasConsultadas] SMALLINT,
            [Ordem]                   TINYINT,
            [ValorTexto]              VARCHAR(MAX),
            [ValorNumerico]           DECIMAL(10,2),
            [ValorData]               DATETIME2(2),
            [ValorBooleano]           BIT,
            [VersaoCliente]           TINYINT,
            [VersaoSistema]           TINYINT,
            [VersaoMetrica]           TINYINT,
            [DataProcessamento]       DATETIME2(2),
            [DataCarga]               DATETIME2(2),
            [DataAtualizacao]         DATETIME2(2),
            [CodContrato]             VARCHAR(20)
        );

        -- Inserir dados convertidos para MERGE
        INSERT INTO #DadosParaMerge
        SELECT
            CAST(GETDATE() AS DATE) AS SkTempo,
            db.SkCliente,
            db.SkProduto,
            db.SkMetrica,
            db.SkTabelasConsultada,
            db.Ordem,
            -- Conversão de valores baseada no tipo
            CASE 
                WHEN db.TipoRetorno IN ('VARCHAR', 'NVARCHAR', 'CHAR', 'NCHAR', 'TEXT') 
                THEN db.Valor
                ELSE NULL
            END AS ValorTexto,
            CASE 
                WHEN db.TipoRetorno IN ('DECIMAL', 'NUMERIC', 'FLOAT', 'REAL', 'INT', 'BIGINT', 'SMALLINT', 'TINYINT', 'MONEY', 'SMALLMONEY')
                     AND ISNUMERIC(db.Valor) = 1 
                THEN TRY_CAST(db.Valor AS DECIMAL(10,2))
                ELSE NULL
            END AS ValorNumerico,
            CASE 
                WHEN db.TipoRetorno IN ('DATETIME', 'DATETIME2', 'SMALLDATETIME', 'DATE', 'TIME')
                     AND ISDATE(db.Valor) = 1 
                THEN TRY_CAST(db.Valor AS DATETIME2(2))
                ELSE NULL
            END AS ValorData,
            CASE 
                WHEN db.TipoRetorno = 'BIT'
                THEN CASE 
                    WHEN UPPER(db.Valor) IN ('TRUE', '1', 'SIM', 'S', 'YES', 'Y') THEN 1
                    WHEN UPPER(db.Valor) IN ('FALSE', '0', 'NAO', 'N', 'NO') THEN 0
                    ELSE NULL
                END
                ELSE NULL
            END AS ValorBooleano,
            ISNULL(dc.VersaoAtual, 1) AS VersaoCliente,
            ISNULL(dp.VersaoAtual, 1) AS VersaoSistema,
            ISNULL(dm.VersaoAtual, 1) AS VersaoMetrica,
            GETDATE() AS DataProcessamento,
            GETDATE() AS DataCarga,
            GETDATE() AS DataAtualizacao,
            db.SiglaCliente AS CodContrato -- Assumindo que SiglaCliente é o código do contrato
        FROM
            #DadosBase db
            LEFT JOIN DM_MetricasClientes.DimMetricas dm ON dm.SkMetrica = db.SkMetrica
            LEFT JOIN Shared.DimClientes dc ON dc.SkCliente = db.SkCliente
            LEFT JOIN Shared.DimProdutos dp ON dp.SkProduto = db.SkProduto;

        -- Variáveis para controle
        DECLARE @RegistrosInseridos INT = 0;
        DECLARE @RegistrosAtualizados INT = 0;
        DECLARE @TotalProcessados INT = (SELECT COUNT(*) FROM #DadosParaMerge);

        -- MERGE: Inserir apenas se valor mudou ou não existe
        MERGE DM_MetricasClientes.FatoMetricasClientes AS target
        USING #DadosParaMerge AS source
        ON (
            target.SkCliente = source.SkCliente 
            AND target.SkProduto = source.SkProduto 
            AND target.SkMetrica = source.SkMetrica 
            AND target.SkDimTabelasConsultadas = source.SkDimTabelasConsultadas
            AND target.Ordem = source.Ordem
        )
        -- WHEN MATCHED: Atualizar apenas se algum valor mudou
        WHEN MATCHED AND (
            -- Verificar se algum valor realmente mudou
            ISNULL(target.ValorTexto, '') <> ISNULL(source.ValorTexto, '')
            OR ISNULL(target.ValorNumerico, 0) <> ISNULL(source.ValorNumerico, 0)
            OR ISNULL(target.ValorData, '1900-01-01') <> ISNULL(source.ValorData, '1900-01-01')
            OR ISNULL(target.ValorBooleano, 0) <> ISNULL(source.ValorBooleano, 0)
        ) THEN
            UPDATE SET
                SkTempo = source.SkTempo,
                ValorTexto = source.ValorTexto,
                ValorNumerico = source.ValorNumerico,
                ValorData = source.ValorData,
                ValorBooleano = source.ValorBooleano,
                VersaoCliente = source.VersaoCliente,
                VersaoSistema = source.VersaoSistema,
                VersaoMetrica = source.VersaoMetrica,
                DataProcessamento = source.DataProcessamento,
                DataAtualizacao = source.DataAtualizacao
        -- WHEN NOT MATCHED: Inserir novos registros
        WHEN NOT MATCHED BY TARGET THEN
            INSERT (
                SkTempo, SkCliente, SkProduto, SkMetrica, SkDimTabelasConsultadas, Ordem,
                ValorTexto, ValorNumerico, ValorData, ValorBooleano,
                VersaoCliente, VersaoSistema, VersaoMetrica,
                DataProcessamento, DataCarga, DataAtualizacao, CodContrato
            )
            VALUES (
                source.SkTempo, source.SkCliente, source.SkProduto, source.SkMetrica, 
                source.SkDimTabelasConsultadas, source.Ordem,
                source.ValorTexto, source.ValorNumerico, source.ValorData, source.ValorBooleano,
                source.VersaoCliente, source.VersaoSistema, source.VersaoMetrica,
                source.DataProcessamento, source.DataCarga, source.DataAtualizacao, source.CodContrato
            );

        -- Capturar estatísticas do MERGE
        SET @RegistrosInseridos = @@ROWCOUNT;
        
        -- Log detalhado do processamento
        PRINT '=========================================';
        PRINT 'MERGE CONCLUÍDO - FATO MÉTRICAS CLIENTES';
        PRINT '=========================================';
        PRINT 'Estatísticas do Processamento:';
        PRINT '• Total de registros processados: ' + CAST(@TotalProcessados AS VARCHAR(10));
        PRINT '• Registros inseridos/atualizados: ' + CAST(@RegistrosInseridos AS VARCHAR(10));
        PRINT '• Registros sem alteração: ' + CAST(@TotalProcessados - @RegistrosInseridos AS VARCHAR(10));
        PRINT 'Data/Hora: ' + CONVERT(VARCHAR(20), GETDATE(), 120);
        PRINT '=========================================';

        -- Limpeza das tabelas temporárias
        DROP TABLE IF EXISTS #DadosBase;
        DROP TABLE IF EXISTS #DadosParaMerge;

        COMMIT TRAN;
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRAN;
        
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        PRINT '❌ ERRO na procedure uspLoadFatoMetricasClientes:';
        PRINT 'Mensagem: ' + @ErrorMessage;
        
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END