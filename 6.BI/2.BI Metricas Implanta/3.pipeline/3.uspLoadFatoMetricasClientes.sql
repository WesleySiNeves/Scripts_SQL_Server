-- =============================================
-- Procedure: uspLoadFatoMetricasClientes
-- Descrição: Carga da tabela fato FatoMetricasClientes
-- Autor: Sistema
-- Data: 2024
-- =============================================

CREATE OR ALTER PROCEDURE [DM_MetricasClientes].[uspLoadFatoMetricasClientes]
    @DataSnapshot DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @DataProcessamento DATETIME2(2) = GETDATE();
    DECLARE @DataSnapshotProcessamento DATE = ISNULL(@DataSnapshot, CAST(@DataProcessamento AS DATE));
    DECLARE @RowsAffected INT = 0;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Preparar dados do staging com joins para obter as chaves surrogate
        WITH StagingEnriquecido AS (
            SELECT 
                -- Chaves Surrogate das dimensões
                dc.SkCliente,
                dp.SkProduto as SkSistema,  -- DimProdutos representa os sistemas
                dm.SkMetrica,
                dtr.SkTipoRetorno,
                @DataSnapshotProcessamento as SkTempo,
                
                -- Chaves de negócio
                s.Cliente as CodigoCliente,
                s.CodSistema,
                s.NomeMetrica,
                s.Ordem,
                
                -- Valores tipados
                CASE 
                    WHEN s.TipoRetorno IN ('VARCHAR', 'CHAR', 'TEXT') 
                    THEN s.Valor
                    ELSE NULL
                END as ValorTexto,
                
                CASE 
                    WHEN s.TipoRetorno IN ('INT', 'DECIMAL', 'FLOAT', 'NUMERIC') 
                         AND ISNUMERIC(s.Valor) = 1
                    THEN TRY_CAST(s.Valor AS DECIMAL(18,4))
                    ELSE NULL
                END as ValorNumerico,
                
                CASE 
                    WHEN s.TipoRetorno IN ('DATETIME', 'DATE', 'DATETIME2') 
                         AND ISDATE(s.Valor) = 1
                    THEN TRY_CAST(s.Valor AS DATETIME2(2))
                    ELSE NULL
                END as ValorData,
                
                CASE 
                    WHEN s.TipoRetorno = 'BIT'
                    THEN CASE 
                        WHEN UPPER(s.Valor) IN ('TRUE', '1', 'SIM', 'S', 'YES', 'Y') THEN 1
                        WHEN UPPER(s.Valor) IN ('FALSE', '0', 'NAO', 'NÃO', 'N', 'NO') THEN 0
                        ELSE NULL
                    END
                    ELSE NULL
                END as ValorBooleano,
                
                -- Metadados
                @DataSnapshotProcessamento as DataSnapshot,
                s.DataProcessamento,
                
                -- Versões das dimensões na época (para auditoria)
                dc.SkCliente as VersaoCliente,
                dp.SkProduto as VersaoSistema,
                dm.SkMetrica as VersaoMetrica
                
            FROM [Staging].[MetricasClientes] s
            
            -- Join com DimClientes (versão atual)
            INNER JOIN [Shared].[DimClientes] dc 
                ON s.Cliente = dc.Nome  -- Assumindo que Cliente no staging corresponde ao Nome na dimensão
                AND dc.VersaoAtual = 1
            
            -- Join com DimProdutos (representa sistemas) - versão atual
            INNER JOIN [Shared].[DimProdutos] dp 
                ON s.CodSistema = dp.SkProduto  -- Assumindo que CodSistema corresponde ao SkProduto
                AND dp.VersaoAtual = 1
            
            -- Join com DimMetricas (versão atual)
            INNER JOIN [DM_MetricasClientes].[DimMetricas] dm 
                ON s.NomeMetrica = dm.NomeMetrica
                AND dm.VersaoAtual = 1
            
            -- Join com DimTipoRetorno
            INNER JOIN [DM_MetricasClientes].[DimTipoRetorno] dtr 
                ON s.TipoRetorno = dtr.TipoRetorno
                AND dtr.Ativo = 1
            
            WHERE s.Cliente IS NOT NULL
              AND s.CodSistema IS NOT NULL
              AND s.NomeMetrica IS NOT NULL
              AND s.TipoRetorno IS NOT NULL
        )
        
        -- Usar MERGE para sincronizar a tabela fato
        MERGE [DM_MetricasClientes].[FatoMetricasClientes] AS target
        USING StagingEnriquecido AS source
        ON target.SkCliente = source.SkCliente
           AND target.SkSistema = source.SkSistema
           AND target.SkMetrica = source.SkMetrica
           AND target.DataSnapshot = source.DataSnapshot
        
        -- Atualizar registros existentes
        WHEN MATCHED THEN
            UPDATE SET
                SkTipoRetorno = source.SkTipoRetorno,
                SkTempo = source.SkTempo,
                CodigoCliente = source.CodigoCliente,
                CodSistema = source.CodSistema,
                NomeMetrica = source.NomeMetrica,
                Ordem = source.Ordem,
                ValorTexto = source.ValorTexto,
                ValorNumerico = source.ValorNumerico,
                ValorData = source.ValorData,
                ValorBooleano = source.ValorBooleano,
                DataProcessamento = source.DataProcessamento,
                VersaoCliente = source.VersaoCliente,
                VersaoSistema = source.VersaoSistema,
                VersaoMetrica = source.VersaoMetrica,
                DataAtualizacao = @DataProcessamento
        
        -- Inserir novos registros
        WHEN NOT MATCHED BY TARGET THEN
            INSERT (
                SkCliente,
                SkSistema,
                SkMetrica,
                SkTipoRetorno,
                SkTempo,
                CodigoCliente,
                CodSistema,
                NomeMetrica,
                Ordem,
                ValorTexto,
                ValorNumerico,
                ValorData,
                ValorBooleano,
                DataSnapshot,
                DataProcessamento,
                VersaoCliente,
                VersaoSistema,
                VersaoMetrica,
                DataCarga,
                DataAtualizacao
            )
            VALUES (
                source.SkCliente,
                source.SkSistema,
                source.SkMetrica,
                source.SkTipoRetorno,
                source.SkTempo,
                source.CodigoCliente,
                source.CodSistema,
                source.NomeMetrica,
                source.Ordem,
                source.ValorTexto,
                source.ValorNumerico,
                source.ValorData,
                source.ValorBooleano,
                source.DataSnapshot,
                source.DataProcessamento,
                source.VersaoCliente,
                source.VersaoSistema,
                source.VersaoMetrica,
                @DataProcessamento,
                @DataProcessamento
            );
        
        SET @RowsAffected = @@ROWCOUNT;
        
        COMMIT TRANSACTION;
        
        PRINT CONCAT('uspLoadFatoMetricasClientes executada com sucesso. Registros afetados: ', @RowsAffected, ' para snapshot: ', @DataSnapshotProcessamento);
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
            
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        PRINT CONCAT('Erro na uspLoadFatoMetricasClientes: ', @ErrorMessage);
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END;
GO

-- Conceder permissões
GRANT EXECUTE ON [DM_MetricasClientes].[uspLoadFatoMetricasClientes] TO [db_executor];
GO