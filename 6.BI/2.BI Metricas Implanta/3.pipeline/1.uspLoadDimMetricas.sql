-- =============================================
-- Procedure: uspLoadDimMetricas
-- Descrição: Carga da dimensão DimMetricas com SCD Tipo 2
-- Autor: Sistema
-- Data: 2024
-- =============================================

CREATE OR ALTER PROCEDURE [DM_MetricasClientes].[uspLoadDimMetricas]
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @DataProcessamento DATETIME2(2) = GETDATE();
    DECLARE @RowsAffected INT = 0;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Etapa 1: Carregar dados únicos do staging
        WITH StagingData AS (
            SELECT DISTINCT
                NomeMetrica,
                TipoRetorno,
                TabelaConsultada,
                CASE 
                    WHEN TipoRetorno = 'INT' THEN 'Numérica'
                    WHEN TipoRetorno = 'VARCHAR' THEN 'Texto'
                    WHEN TipoRetorno = 'DATETIME' THEN 'Data/Hora'
                    WHEN TipoRetorno = 'BIT' THEN 'Booleana'
                    ELSE 'Outros'
                END AS Categoria,
                CONCAT('Métrica: ', NomeMetrica, ' - Tipo: ', TipoRetorno) AS Descricao
            FROM [Staging].[MetricasClientes]
            WHERE NomeMetrica IS NOT NULL
              AND LTRIM(RTRIM(NomeMetrica)) <> ''
        ),
        
        -- Etapa 2: Identificar registros que mudaram
        ChangedRecords AS (
            SELECT 
                s.NomeMetrica,
                s.TipoRetorno,
                s.TabelaConsultada,
                s.Categoria,
                s.Descricao,
                d.SkMetrica
            FROM StagingData s
            LEFT JOIN [DM_MetricasClientes].[DimMetricas] d 
                ON s.NomeMetrica = d.NomeMetrica 
                AND d.VersaoAtual = 1
            WHERE d.SkMetrica IS NULL  -- Novos registros
               OR (  -- Registros modificados
                    d.TipoRetorno <> s.TipoRetorno
                 OR ISNULL(d.TabelaConsultada, '') <> ISNULL(s.TabelaConsultada, '')
                 OR ISNULL(d.Categoria, '') <> ISNULL(s.Categoria, '')
                 OR ISNULL(d.Descricao, '') <> ISNULL(s.Descricao, '')
               )
        )
        
        -- Etapa 3: Fechar versões antigas (SCD Tipo 2)
        UPDATE [DM_MetricasClientes].[DimMetricas]
        SET 
            DataFimVersao = @DataProcessamento,
            VersaoAtual = 0,
            DataAtualizacao = @DataProcessamento
        WHERE NomeMetrica IN (
            SELECT NomeMetrica 
            FROM ChangedRecords 
            WHERE SkMetrica IS NOT NULL
        )
        AND VersaoAtual = 1;
        
        SET @RowsAffected = @@ROWCOUNT;
        
        -- Etapa 4: Inserir novas versões
        INSERT INTO [DM_MetricasClientes].[DimMetricas] (
            NomeMetrica,
            TipoRetorno,
            TabelaConsultada,
            Categoria,
            Descricao,
            Ativo,
            DataInicioVersao,
            DataFimVersao,
            VersaoAtual,
            DataCarga,
            DataAtualizacao
        )
        SELECT 
            NomeMetrica,
            TipoRetorno,
            TabelaConsultada,
            Categoria,
            Descricao,
            1 as Ativo,
            @DataProcessamento as DataInicioVersao,
            NULL as DataFimVersao,
            1 as VersaoAtual,
            @DataProcessamento as DataCarga,
            @DataProcessamento as DataAtualizacao
        FROM ChangedRecords;
        
        SET @RowsAffected = @RowsAffected + @@ROWCOUNT;
        
        -- Etapa 5: Atualizar DataAtualizacao para registros inalterados
        UPDATE [DM_MetricasClientes].[DimMetricas]
        SET DataAtualizacao = @DataProcessamento
        WHERE NomeMetrica IN (
            SELECT DISTINCT NomeMetrica 
            FROM [Staging].[MetricasClientes]
            WHERE NomeMetrica IS NOT NULL
        )
        AND VersaoAtual = 1
        AND NomeMetrica NOT IN (
            SELECT NomeMetrica 
            FROM ChangedRecords
        );
        
        COMMIT TRANSACTION;
        
        PRINT CONCAT('uspLoadDimMetricas executada com sucesso. Registros afetados: ', @RowsAffected);
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
            
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        PRINT CONCAT('Erro na uspLoadDimMetricas: ', @ErrorMessage);
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END;
GO

-- Conceder permissões
GRANT EXECUTE ON [DM_MetricasClientes].[uspLoadDimMetricas] TO [db_executor];
GO