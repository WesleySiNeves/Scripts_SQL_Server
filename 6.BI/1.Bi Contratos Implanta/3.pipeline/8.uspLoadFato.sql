

-- =============================================
-- Stored Procedure: uspLoadFatoContratosProdutos
-- Descrição: Carrega a tabela fato usando MERGE para inserir/atualizar dados
-- Autor: Sistema BI
-- Data: Criação automática
-- =============================================

CREATE OR ALTER PROCEDURE [DM_ContratosProdutos].[uspLoadFatoContratosProdutos]
AS
BEGIN
    SET NOCOUNT ON;

    -- Declaração de variáveis para controle
    DECLARE @RegistrosInseridos INT = 0;
    DECLARE @RegistrosAtualizados INT = 0;
    DECLARE @RegistrosProcessados INT = 0;
    DECLARE @InicioProcessamento DATETIME = GETDATE();

    BEGIN TRY
        PRINT 'Iniciando carga da tabela fato FatoContratosProdutos...';
        PRINT 'Timestamp: ' + CONVERT(VARCHAR(20), @InicioProcessamento, 120);
        PRINT '';
		

        DROP TABLE IF EXISTS #DadosStaging;

       CREATE TABLE #DadosStaging
    (
        [Estado]                      CHAR(2),
        [SkCategoria]                 SMALLINT,
        [SkProduto]                   TINYINT,
        [SkTipoContrato]              TINYINT,
        [SkTipoSituacaoContrato]      TINYINT,
        [SkPagador]                   SMALLINT,
        [SkCliente]                   SMALLINT,
        [SkDataVigenciaInicial]        DATE,
        [SkDataVigenciaFinal]          DATE,
        [SkTiposSituacaoFinanceira]   TINYINT,
        [CodContrato]                 VARCHAR(10),
        [Periodicidade]               VARCHAR(60),
		
        [PrecoUnitario]               DECIMAL(10, 2),
        [Quantidade]                  FLOAT(8),
        [ValorTotal]                  DECIMAL(10, 2),
		[ValorDesconto]               DECIMAL(10, 2),
        [DataBase]                    DATE,
		[QtdDiasVigencia]            INT,
        [QtdDiasFaltantes]            INT,
        [Vencido]                     VARCHAR(3),
        [ContratoPagoPorOutroCliente] VARCHAR(3),
        [QuantidadeLicencasGigam]     INT,
        [DataAtualizacao]             DATETIME
    );
	
        INSERT INTO #DadosStaging
            (
                Estado,
                SkCategoria,
                SkProduto,
                SkTipoContrato,
                SkTipoSituacaoContrato,
                SkPagador,
                SkCliente,
                SkDataVigenciaInicial,
                SkDataVigenciaFinal,
                SkTiposSituacaoFinanceira,
                CodContrato,
                Periodicidade,
                PrecoUnitario,
                Quantidade,
                ValorTotal,
                ValorDesconto,
                [DataBase],
                QtdDiasVigencia,
                QtdDiasFaltantes,
                Vencido,
                ContratoPagoPorOutroCliente,
                QuantidadeLicencasGigam,
                DataAtualizacao
            )
        SELECT geo.Estado,
               categoria.SkCategoria,
               prod.SkProduto,
               tipo.SkTipoContrato,
               situacao.SkTipoSituacaoContrato,
               pagador.SkCliente AS SkPagador,
               cliente.SkCliente AS SkCliente,
               tempoInicial.Data AS DataVigenciaInical,
               tempoFinal.Data AS DataVigenciaFinal,
               situacaofinanceira.SkTiposSituacaoFinanceira,
               source.CodContrato,
			   source.Periodicidade,
			   source.PrecoUnitario,
			   source.Quantidade,
			   source.ValorTotal,
			   source.ValorDesconto,
			   source.[DataBase],
               DiasVingencia = DATEDIFF(DAY, source.DataVigenciaInicial, source.DataVigenciaFinal),
               QtdDiasFaltantes = DATEDIFF(DAY, GETDATE(), source.DataVigenciaFinal),
               Vencido = IIF(DATEDIFF(DAY, GETDATE(), source.DataVigenciaFinal) < 0, 'SIM', 'NÂO'),
               ContratoPagoPorOutroCliente = IIF(pagador.SkCliente <> cliente.SkCliente, 'SIM', 'NÃO'),
               source.QtdLicencas AS QuantidadeLicencasGigam,
               GETDATE() AS DataAtualizacao
        FROM Staging.ClientesProdutosCIGAM source
            LEFT JOIN Shared.DimTempo tempoInicial
                ON tempoInicial.Data = source.DataVigenciaInicial
            LEFT JOIN Shared.DimTempo tempoFinal
                ON tempoFinal.Data = source.DataVigenciaFinal
            LEFT JOIN Shared.DimCategorias categoria
                ON source.Categoria = categoria.Nome
            LEFT JOIN Shared.DimGeografia geo
                ON geo.Estado = source.UF
            LEFT JOIN Shared.DimProdutos prod
                ON prod.DescricaoCigam = source.Descricao
                AND prod.VersaoAtual = 1
            LEFT JOIN Shared.DimClientes pagador
                ON pagador.SiglaCliente = source.Pagador COLLATE Latin1_General_CI_AI
                AND pagador.VersaoAtual = 1
            LEFT JOIN Shared.DimClientes cliente
                ON cliente.SiglaCliente = source.SiglaCliente COLLATE Latin1_General_CI_AI
                AND cliente.VersaoAtual = 1
            LEFT JOIN DM_ContratosProdutos.DimTipoContratos tipo
                ON tipo.Nome = source.Tipo
            LEFT JOIN DM_ContratosProdutos.DimTipoSituacaoContratos situacao
                ON situacao.Nome = source.Situacao
            LEFT JOIN DM_ContratosProdutos.DimTiposSituacaoFinanceira situacaofinanceira
                ON situacaofinanceira.Nome = source.SituacaoFinanceira
        WHERE
            -- Filtra apenas registros com chaves válidas (não nulas)
            cliente.SkCliente IS NOT NULL
            AND prod.SkProduto IS NOT NULL
            AND tipo.SkTipoContrato IS NOT NULL
            AND situacao.SkTipoSituacaoContrato IS NOT NULL
            AND situacaofinanceira.SkTiposSituacaoFinanceira IS NOT NULL;

        -- Conta registros preparados
        SET @RegistrosProcessados = @@ROWCOUNT;
        PRINT 'Registros preparados para processamento: ' + CAST(@RegistrosProcessados AS VARCHAR(10));

        -- Executa MERGE para inserir/atualizar dados na tabela fato
        PRINT 'Executando MERGE na tabela fato...';




        MERGE DM_ContratosProdutos.FatoContratosProdutos AS Target
        USING #DadosStaging AS Source
        ON Target.[SkUF] = Source.Estado
           AND Target.SkCliente = Source.SkCliente
           AND Target.SkProduto = Source.SkProduto
           AND Target.CodContrato = Source.CodContrato
           AND Target.SkTipoContrato = Source.SkTipoContrato
           AND Target.DataVigenciaInicial = Source.SKDataVigenciaInicial
           AND Target.DataVigenciaInicial = Source.SKDataVigenciaInicial
		   
        -- Quando não existe na tabela fato, insere novo registro
        WHEN NOT MATCHED BY TARGET THEN
            INSERT
            (
                SkUF,
                CodContrato,
                SkCategoria,
                SkProduto,
                SkTipoContrato,
                SkTipoSituacaoContrato,
                SkClientePagador,
                SkCliente,
                DataVigenciaInicial,
                DataVigenciaFinal,
                SkTiposSituacaoFinanceira,
				Data_base,
				Periodicidade,
				PrecoUnitario,
				Quantidade,
				ValorDesconto,
				ValorTotal,
				QtdLicencasCIGAM,
                DataCarga,
                DataUltimaAtualizacao
            )
            VALUES
            (Source.Estado,
			Source.CodContrato,
			Source.SkCategoria, Source.SkProduto, Source.SkTipoContrato, Source.SkTipoSituacaoContrato,
             Source.SkPagador, Source.SkCliente, Source.SkDataVigenciaInicial, Source.SkDataVigenciaFinal,
             Source.SkTiposSituacaoFinanceira,Source.[DataBase],Source.Periodicidade,Source.PrecoUnitario,
			 Source.Quantidade,Source.ValorDesconto,Source.ValorTotal,Source.QuantidadeLicencasGigam, GETDATE(), GETDATE())
		
        -- Quando existe na tabela fato, atualiza se houve mudança
        WHEN MATCHED AND (
                             Target.SkTipoSituacaoContrato <> Source.SkTipoSituacaoContrato
                             OR Target.SkTiposSituacaoFinanceira <> Source.SkTiposSituacaoFinanceira
                             OR Target.QtdLicencasCIGAM <> Source.QuantidadeLicencasGigam
                             OR Target.ValorTotal <> Source.ValorTotal
                         ) THEN
            UPDATE SET SkTipoSituacaoContrato = Source.SkTipoSituacaoContrato,
                       SkTiposSituacaoFinanceira = Source.SkTiposSituacaoFinanceira,
                       QtdLicencasCIGAM = Source.QuantidadeLicencasGigam,
                       ValorTotal = Source.ValorTotal,
                       DataUltimaAtualizacao = GETDATE();

        -- Captura estatísticas do MERGE
        SET @RegistrosInseridos = @@ROWCOUNT;

        UPDATE DM_ContratosProdutos.FatoContratosProdutos
        SET DataUltimaAtualizacao = GETDATE();
		
        -- Calcula registros atualizados (aproximação)
        SELECT @RegistrosAtualizados = COUNT(*)
        FROM DM_ContratosProdutos.FatoContratosProdutos f
            INNER JOIN #DadosStaging s
                ON f.SkCliente = s.SkCliente
                   AND f.SkProduto = s.SkProduto
                   AND f.DataVigenciaInicial = s.SkDataVigenciaInicial
                   AND f.DataVigenciaFinal = s.SkDataVigenciaFinal
        WHERE f.DataUltimaAtualizacao >= @InicioProcessamento;

        SET @RegistrosAtualizados = @RegistrosAtualizados - @RegistrosInseridos;


        -- Estatísticas finais
        DECLARE @TempoProcessamento VARCHAR(20) = CONVERT(VARCHAR(20), GETDATE() - @InicioProcessamento, 108);

        PRINT '';
        PRINT '=================================================';
        PRINT 'CARGA DA FATO CONCLUÍDA COM SUCESSO!';
        PRINT '=================================================';
        PRINT 'Registros processados: ' + CAST(@RegistrosProcessados AS VARCHAR(10));
        PRINT 'Registros inseridos: ' + CAST(@RegistrosInseridos AS VARCHAR(10));
        PRINT 'Registros atualizados: ' + CAST(@RegistrosAtualizados AS VARCHAR(10));
        PRINT 'Tempo de processamento: ' + @TempoProcessamento;
        PRINT 'Método: MERGE (Insert/Update)';

        -- Verifica a integridade dos dados carregados
        SELECT 'Verificação Final' AS Tipo,
               COUNT(*) AS TotalRegistrosFato,
               COUNT(DISTINCT SkCliente) AS TotalClientes,
               COUNT(DISTINCT SkProduto) AS TotalProdutos,
               MIN(DataCarga) AS PrimeiraCarga,
               MAX(DataUltimaAtualizacao) AS UltimaAtualizacao
        FROM DM_ContratosProdutos.FatoContratosProdutos;

    END TRY
    BEGIN CATCH
        -- Tratamento de erro
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();

        PRINT 'ERRO durante a carga da tabela fato:';
        PRINT 'Mensagem: ' + @ErrorMessage;
        PRINT 'Registros processados antes do erro: ' + CAST(@RegistrosProcessados AS VARCHAR(10));

        -- Limpa tabela temporária em caso de erro
        IF OBJECT_ID('tempdb..#DadosStaging') IS NOT NULL
            DROP TABLE #DadosStaging;

        -- Re-lança o erro
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH;
END;
--GO

---- =============================================
---- Script para executar a stored procedure
---- =============================================

---- Executa a carga da tabela fato
--EXEC DM_ContratosProdutos.uspLoadFatoContratosProdutos;
               

	 