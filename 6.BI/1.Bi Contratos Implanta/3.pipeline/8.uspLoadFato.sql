

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
        [UF] VARCHAR(2),
        [SkCategoria] SMALLINT,
        [SkProduto] TINYINT,
        [SkTipoContrato] TINYINT,
        [SkTipoSituacaoContrato] TINYINT,
        [SkPagador] SMALLINT,
        [SkCliente] SMALLINT,
        [SkDataVigenciaInicial] INT,
        [SkDataVigenciaFinal] INT,
        [SkTiposSituacaoFinanceira] TINYINT,
        [ValorContrato] INT,
        [DiasVigencia] INT,
        [QtdDiasFaltantes] INT,
        [Vencido] VARCHAR(3),
        ContratoPagoPorOutroCliente VARCHAR(3),
        [QtdLicencas] INT,
        [DataAtualizacao] DATETIME2(2)
    );

    INSERT INTO #Dados
    SELECT geo.Estado,
           --source.Categoria,
           categoria.SkCategoria,
           --source.Descricao,
           prod.SkProduto,
           --source.Tipo,
           tipo.SkTipoContrato,
           --source.Situacao,
           situacao.SkTipoSituacaoContrato,
           --source.Pagador,
           pagador.SkCliente AS SkPagador,
           --source.SiglaCliente,
           cliente.SkCliente AS SkCliente,
           tempoInicial.DataKey,
           tempoFinal.DataKey,
           --source.SituacaoFinanceira,
           situacaofinanceira.SkTiposSituacaoFinanceira,
           ValorContrato = 0,
           DiasVingencia = DATEDIFF(DAY, source.DataVigenciaInicial, source.DataVigenciaFinal),
           QtdDiasFaltantes = DATEDIFF(DAY, GETDATE(), source.DataVigenciaFinal),
           Vencido = IIF(DATEDIFF(DAY, GETDATE(), source.DataVigenciaFinal) < 0, 'SIM', 'NÂO'),
           ContratoPagoPorOutroCliente = IIF(pagador.SkCliente <> cliente.SkCliente, 'SIM', 'NÃO'),
           source.QtdLicencas,
           source.DataAtualizacao
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
        LEFT JOIN Shared.DimClientes pagador
            ON pagador.Sigla = source.Pagador
        LEFT JOIN Shared.DimClientes cliente
            ON cliente.Sigla = source.SiglaCliente
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
    USING #Dados AS Source
    ON Target.SkUF = Source.UF
       AND Target.SkCliente = Source.SkCliente
       AND Target.SkProduto = Source.SkProduto
       AND Target.SkTipoContrato = Source.SkTipoContrato
       AND Target.SkDataVigenciaInicial = Source.SkDataVigenciaInicial
       AND Target.SkDataVigenciaFinal = Source.SkDataVigenciaFinal

    -- Quando não existe na tabela fato, insere novo registro
    WHEN NOT MATCHED BY TARGET THEN
        INSERT
        (
            SkUF,
            SkCliente,
            SkClientePagador,
            SkProduto,
            SkTipoContrato,
            SkTipoSituacaoContrato,
            SkTiposSituacaoFinanceira,
            SkDataVigenciaInicial,
            SkDataVigenciaFinal,
            QtdLicencas,
            ValorContrato,
            DiasVigencia,
            DataCarga,
            DataUltimaAtualizacao
        )
        VALUES
        (Source.UF, Source.SkCliente, Source.SkPagador, Source.SkProduto, Source.SkTipoContrato,
         Source.SkTipoSituacaoContrato, Source.SkTiposSituacaoFinanceira, Source.SkDataVigenciaInicial,
         Source.SkDataVigenciaFinal, Source.QtdLicencas, Source.ValorContrato, Source.[DiasVigencia], GETDATE(),
         GETDATE())

    -- Quando existe na tabela fato, atualiza se houve mudança
    WHEN MATCHED AND (
                         Target.SkTipoSituacaoContrato <> Source.SkTipoSituacaoContrato
                         OR Target.SkTiposSituacaoFinanceira <> Source.SkTiposSituacaoFinanceira
                         OR Target.QtdLicencas <> Source.QtdLicencas
                         OR Target.ValorContrato <> Source.ValorContrato
                         OR Target.DiasVigencia <> Source.[DiasVigencia]
                     ) THEN
        UPDATE SET SkTipoSituacaoContrato = Source.SkTipoSituacaoContrato,
                   SkTiposSituacaoFinanceira = Source.SkTiposSituacaoFinanceira,
                   QtdLicencas = Source.QtdLicencas,
                   ValorContrato = Source.ValorContrato,
                   DiasVigencia = Source.[DiasVigencia],
                   DataUltimaAtualizacao = GETDATE();

    -- Captura estatísticas do MERGE
    SET @RegistrosInseridos = @@ROWCOUNT;

    -- Calcula registros atualizados (aproximação)
    SELECT @RegistrosAtualizados = COUNT(*)
    FROM DM_ContratosProdutos.FatoContratosProdutos f
        INNER JOIN #DadosStaging s
            ON f.SkCliente = s.SkCliente
               AND f.SkProduto = s.SkProduto
               AND f.SkDataVigenciaInicial = s.SkDataVigenciaInicial
               AND f.SkDataVigenciaFinal = s.SkDataVigenciaFinal
    WHERE f.DataUltimaAtualizacao >= @InicioProcessamento;

    SET @RegistrosAtualizados = @RegistrosAtualizados - @RegistrosInseridos;

    -- Limpa tabela temporária
    DROP TABLE #DadosStaging;

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
