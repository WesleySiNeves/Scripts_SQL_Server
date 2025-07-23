-- =============================================
-- Procedure: uspLoadDimMetricas
-- Descrição: Carga da dimensão DimMetricas com SCD Tipo 2
-- Autor: Sistema BI
-- Data: 2024
-- Versão: 2.0 - Implementação completa SCD Tipo 2
-- =============================================

--SELECT * FROM DM_MetricasClientes.DimMetricas

CREATE OR ALTER PROCEDURE [DM_MetricasClientes].[uspLoadDimMetricas]
AS
    BEGIN
        SET NOCOUNT ON;

        DECLARE @DataProcessamento DATETIME2(2) = GETDATE();
        DECLARE @RegistrosInseridos INT = 0;
        DECLARE @RegistrosAtualizados INT = 0;

        BEGIN TRY
            BEGIN TRANSACTION;

            -- =============================================
            -- ETAPA 1: IDENTIFICAR MÉTRICAS NOVAS
            -- Inserir métricas que não existem na dimensão
            -- =============================================

            INSERT INTO [DM_MetricasClientes].[DimMetricas]
                (
                    [NomeMetrica],
                    [TipoRetorno],
                    [Categoria],
                    [Descricao],
                    [Ativo],
                    [DataInicioVersao],
                    [DataFimVersao],
                    [VersaoAtual],
                    [DataCarga],
                    [DataAtualizacao]
                )
                        SELECT DISTINCT
                               s.[NomeMetrica],
                               s.[TipoRetorno],
                                                                      -- Categorização automática baseada no nome da métrica
                               CASE
                                   WHEN s.[NomeMetrica] LIKE '%Performance%'
                                        OR s.[NomeMetrica] LIKE '%Tempo%'
                                       THEN
                                       'Performance'
                                   WHEN s.[NomeMetrica] LIKE '%Erro%'
                                        OR s.[NomeMetrica] LIKE '%Falha%'
                                       THEN
                                       'Qualidade'
                                   WHEN s.[NomeMetrica] LIKE '%Usuario%'
                                        OR s.[NomeMetrica] LIKE '%Login%'
                                       THEN
                                       'Acesso'
                                   WHEN s.[NomeMetrica] LIKE '%Backup%'
                                        OR s.[NomeMetrica] LIKE '%Manutencao%'
                                       THEN
                                       'Infraestrutura'
                                   WHEN s.[NomeMetrica] LIKE '%Relatorio%'
                                        OR s.[NomeMetrica] LIKE '%Dashboard%'
                                       THEN
                                       'Relatórios'
                                   ELSE
                                       'Geral'
                               END                AS [Categoria],
                                                                      -- Descrição automática baseada no tipo de retorno
                               CASE
                                   WHEN s.[TipoRetorno] = 'BIT'
                                       THEN
                                       'Métrica booleana: ' + s.[NomeMetrica]
                                   WHEN s.[TipoRetorno] IN (
                                                               'INT', 'DECIMAL', 'NUMERIC'
                                                           )
                                       THEN
                                       'Métrica numérica: ' + s.[NomeMetrica]
                                   WHEN s.[TipoRetorno] = 'DATETIME'
                                       THEN
                                       'Métrica temporal: ' + s.[NomeMetrica]
                                   ELSE
                                       'Métrica textual: ' + s.[NomeMetrica]
                               END                AS [Descricao],
                               1                  AS [Ativo],         -- Nova métrica sempre ativa
                               @DataProcessamento AS [DataInicioVersao],
                               NULL               AS [DataFimVersao], -- Versão atual
                               1                  AS [VersaoAtual],   -- Versão atual
                               @DataProcessamento AS [DataCarga],
                               @DataProcessamento AS [DataAtualizacao]
                        FROM
                               [Staging].[MetricasClientes] s
                        WHERE
                               NOT EXISTS
                            (
                                SELECT
                                    1
                                FROM
                                    [DM_MetricasClientes].[DimMetricas] d
                                WHERE
                                    d.[NomeMetrica] = s.[NomeMetrica]
                            );

            SET @RegistrosInseridos = @@ROWCOUNT;

            -- =============================================
            -- ETAPA 2: IDENTIFICAR MÉTRICAS MODIFICADAS
            -- Fechar versões antigas e criar novas versões
            -- =============================================

            -- 2.1: Fechar versões antigas (definir DataFimVersao e VersaoAtual = 0)
            UPDATE
                    d
            SET
                    [DataFimVersao] = @DataProcessamento,
                    [VersaoAtual] = 0,
                    [DataAtualizacao] = @DataProcessamento
            FROM
                    [DM_MetricasClientes].[DimMetricas] d
                INNER JOIN
                    [Staging].[MetricasClientes]        s
                        ON d.[NomeMetrica] = s.[NomeMetrica]
            WHERE
                    d.[VersaoAtual] = 1
                    AND (
                -- Verificar se houve mudança no tipo de retorno
                d.[TipoRetorno] != s.[TipoRetorno]
                        -- Adicionar outras verificações de mudança se necessário
                        -- OR d.[OutroCampo] != s.[OutroCampo]
                        );

            -- 2.2: Inserir novas versões para métricas modificadas
            INSERT INTO [DM_MetricasClientes].[DimMetricas]
                (
                    [NomeMetrica],
                    [TipoRetorno],
                    [Categoria],
                    [Descricao],
                    [Ativo],
                    [DataInicioVersao],
                    [DataFimVersao],
                    [VersaoAtual],
                    [DataCarga],
                    [DataAtualizacao]
                )
                        SELECT  DISTINCT
                                s.[NomeMetrica],
                                s.[TipoRetorno],
                                -- Manter categorização automática
                                CASE
                                    WHEN s.[NomeMetrica] LIKE '%Performance%'
                                         OR s.[NomeMetrica] LIKE '%Tempo%'
                                        THEN
                                        'Performance'
                                    WHEN s.[NomeMetrica] LIKE '%Erro%'
                                         OR s.[NomeMetrica] LIKE '%Falha%'
                                        THEN
                                        'Qualidade'
                                    WHEN s.[NomeMetrica] LIKE '%Usuario%'
                                         OR s.[NomeMetrica] LIKE '%Login%'
                                        THEN
                                        'Acesso'
                                    WHEN s.[NomeMetrica] LIKE '%Backup%'
                                         OR s.[NomeMetrica] LIKE '%Manutencao%'
                                        THEN
                                        'Infraestrutura'
                                    WHEN s.[NomeMetrica] LIKE '%Relatorio%'
                                         OR s.[NomeMetrica] LIKE '%Dashboard%'
                                        THEN
                                        'Relatórios'
                                    ELSE
                                        'Geral'
                                END                                                                           AS [Categoria],
                                'Métrica atualizada: ' + s.[NomeMetrica] + ' (Tipo: ' + s.[TipoRetorno] + ')' AS [Descricao],
                                1                                                                             AS [Ativo],
                                @DataProcessamento                                                            AS [DataInicioVersao],
                                NULL                                                                          AS [DataFimVersao],
                                1                                                                             AS [VersaoAtual],
                                @DataProcessamento                                                            AS [DataCarga],
                                @DataProcessamento                                                            AS [DataAtualizacao]
                        FROM
                                [Staging].[MetricasClientes]        s
                            INNER JOIN
                                [DM_MetricasClientes].[DimMetricas] d
                                    ON s.[NomeMetrica] = d.[NomeMetrica]
                        WHERE
                                d.[DataFimVersao] = @DataProcessamento -- Apenas métricas que foram fechadas nesta execução
                                AND d.[VersaoAtual] = 0;

            SET @RegistrosAtualizados = @@ROWCOUNT;

            -- =============================================
            -- ETAPA 3: DESATIVAR MÉTRICAS NÃO UTILIZADAS
            -- Marcar como inativas métricas que não aparecem mais no staging
            -- =============================================

            UPDATE
                [DM_MetricasClientes].[DimMetricas]
            SET
                [Ativo] = 0,
                [DataAtualizacao] = @DataProcessamento
            WHERE
                [VersaoAtual] = 1
                AND [Ativo] = 1
                AND NOT EXISTS
                (
                    SELECT
                        1
                    FROM
                        [Staging].[MetricasClientes] s
                    WHERE
                        s.[NomeMetrica] = [DM_MetricasClientes].[DimMetricas].[NomeMetrica]
                );

            COMMIT TRANSACTION;

            -- =============================================
            -- LOG DE EXECUÇÃO
            -- =============================================

            PRINT '=== CARGA DimMetricas CONCLUÍDA ===';
            PRINT 'Data/Hora: ' + CONVERT(VARCHAR(20), @DataProcessamento, 120);
            PRINT 'Métricas Inseridas (Novas): ' + CAST(@RegistrosInseridos AS VARCHAR(10));
            PRINT 'Métricas Atualizadas (SCD): ' + CAST(@RegistrosAtualizados AS VARCHAR(10));
            PRINT '======================================';

        END TRY
        BEGIN CATCH
            -- Rollback em caso de erro
            IF @@TRANCOUNT > 0
                ROLLBACK TRANSACTION;

            -- Log do erro
            DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
            DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
            DECLARE @ErrorState INT = ERROR_STATE();

            PRINT '=== ERRO NA CARGA DimMetricas ===';
            PRINT 'Erro: ' + @ErrorMessage;
            PRINT 'Severidade: ' + CAST(@ErrorSeverity AS VARCHAR(10));
            PRINT 'Estado: ' + CAST(@ErrorState AS VARCHAR(10));
            PRINT '==================================';

            -- Re-throw do erro
            RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
        END CATCH;
    END;
GO

-- =============================================
-- COMENTÁRIOS E DOCUMENTAÇÃO
-- =============================================
/*
ESTRATÉGIA SCD TIPO 2 IMPLEMENTADA:

1. INSERÇÃO DE NOVAS MÉTRICAS:
   - Métricas que não existem na dimensão são inseridas como versão atual
   - Categorização automática baseada no nome da métrica
   - Descrição automática baseada no tipo de retorno

2. ATUALIZAÇÃO DE MÉTRICAS EXISTENTES:
   - Detecta mudanças no TipoRetorno (principal campo de controle)
   - Fecha a versão antiga (DataFimVersao + VersaoAtual = 0)
   - Cria nova versão com os dados atualizados

3. DESATIVAÇÃO DE MÉTRICAS:
   - Métricas que não aparecem mais no staging são marcadas como inativas
   - Mantém histórico completo para auditoria

4. CAMPOS DE CONTROLE SCD:
   - DataInicioVersao: Início da validade da versão
   - DataFimVersao: Fim da validade (NULL = versão atual)
   - VersaoAtual: Flag para identificar versão ativa (1 = atual, 0 = histórica)

5. AUDITORIA:
   - DataCarga: Data de criação do registro
   - DataAtualizacao: Data da última modificação
   - Log detalhado de execução

6. TRATAMENTO DE ERROS:
   - Transação com rollback automático
   - Log detalhado de erros
   - Re-throw para notificação

USO RECOMENDADO:
- Executar após a carga do staging
- Monitorar logs para identificar mudanças
- Validar integridade com queries de controle
*/