-- =============================================
-- Índices Otimizados para Histórico - Fato Métricas Clientes
-- Descrição: Índices específicos para consultas temporais e análise de histórico
-- Autor: Sistema
-- Data: 2024
-- =============================================

USE [DW_MetricasClientes];
GO

PRINT '=== CRIAÇÃO DE ÍNDICES PARA HISTÓRICO DE MÉTRICAS ===';
PRINT 'Iniciando criação dos índices otimizados...';
GO

-- =============================================
-- ÍNDICE 1: BUSCA DE ÚLTIMO VALOR POR MÉTRICA
-- Otimiza consultas para valores atuais
-- =============================================

PRINT '1. Criando índice para busca de último valor...';
GO

CREATE NONCLUSTERED INDEX [IX_FatoMetricas_UltimoValor]
ON [DM_MetricasClientes].[FatoMetricasClientes] 
(
    [SkCliente] ASC,
    [SkProduto] ASC,
    [SkMetrica] ASC,
    [SkDimTabelasConsultadas] ASC,
    [SkTempo] DESC  -- DESC para buscar o mais recente primeiro
)
INCLUDE 
(
    [ValorTexto],
    [ValorNumerico],
    [ValorData],
    [ValorBooleano],
    [DataProcessamento],
    [DataCarga]
)
WITH 
(
    PAD_INDEX = OFF,
    STATISTICS_NORECOMPUTE = OFF,
    SORT_IN_TEMPDB = OFF,
    DROP_EXISTING = OFF,
    ONLINE = OFF,
    ALLOW_ROW_LOCKS = ON,
    ALLOW_PAGE_LOCKS = ON,
    DATA_COMPRESSION = PAGE  -- Compressão para economizar espaço
);
GO

-- =============================================
-- ÍNDICE 2: ANÁLISES TEMPORAIS POR MÉTRICA
-- Otimiza consultas de tendência e evolução
-- =============================================

PRINT '2. Criando índice para análises temporais...';
GO

CREATE NONCLUSTERED INDEX [IX_FatoMetricas_Temporal]
ON [DM_MetricasClientes].[FatoMetricasClientes] 
(
    [SkTempo] ASC,
    [SkMetrica] ASC
)
INCLUDE 
(
    [SkCliente],
    [ValorNumerico],
    [ValorTexto],
    [NomeMetrica],
    [DataProcessamento]
)
WITH 
(
    PAD_INDEX = OFF,
    STATISTICS_NORECOMPUTE = OFF,
    SORT_IN_TEMPDB = OFF,
    DROP_EXISTING = OFF,
    ONLINE = OFF,
    ALLOW_ROW_LOCKS = ON,
    ALLOW_PAGE_LOCKS = ON,
    DATA_COMPRESSION = PAGE
);
GO

-- =============================================
-- ÍNDICE 3: CONSULTAS POR CLIENTE E PERÍODO
-- Otimiza dashboards e relatórios por cliente
-- =============================================

PRINT '3. Criando índice para consultas por cliente...';
GO

CREATE NONCLUSTERED INDEX [IX_FatoMetricas_ClientePeriodo]
ON [DM_MetricasClientes].[FatoMetricasClientes] 
(
    [SkCliente] ASC,
    [SkTempo] ASC
)
INCLUDE 
(
    [SkMetrica],
    [SkProduto],
    [NomeMetrica],
    [ValorTexto],
    [ValorNumerico],
    [ValorData],
    [ValorBooleano],
    [Ordem]
)
WITH 
(
    PAD_INDEX = OFF,
    STATISTICS_NORECOMPUTE = OFF,
    SORT_IN_TEMPDB = OFF,
    DROP_EXISTING = OFF,
    ONLINE = OFF,
    ALLOW_ROW_LOCKS = ON,
    ALLOW_PAGE_LOCKS = ON,
    DATA_COMPRESSION = PAGE
);
GO

-- =============================================
-- ÍNDICE 4: CONSULTAS POR MÉTRICA ESPECÍFICA
-- Otimiza análise de uma métrica específica
-- =============================================

PRINT '4. Criando índice para consultas por métrica específica...';
GO

CREATE NONCLUSTERED INDEX [IX_FatoMetricas_MetricaEspecifica]
ON [DM_MetricasClientes].[FatoMetricasClientes] 
(
    [SkMetrica] ASC,
    [SkCliente] ASC,
    [SkTempo] ASC
)
INCLUDE 
(
    [ValorNumerico],
    [ValorTexto],
    [ValorData],
    [ValorBooleano],
    [NomeMetrica],
    [DataProcessamento],
    [VersaoCliente],
    [VersaoMetrica]
)
WITH 
(
    PAD_INDEX = OFF,
    STATISTICS_NORECOMPUTE = OFF,
    SORT_IN_TEMPDB = OFF,
    DROP_EXISTING = OFF,
    ONLINE = OFF,
    ALLOW_ROW_LOCKS = ON,
    ALLOW_PAGE_LOCKS = ON,
    DATA_COMPRESSION = PAGE
);
GO

-- =============================================
-- ÍNDICE 5: DETECÇÃO DE ALTERAÇÕES (PARA ETL)
-- Otimiza a procedure de carga
-- =============================================

PRINT '5. Criando índice para detecção de alterações...';
GO

CREATE NONCLUSTERED INDEX [IX_FatoMetricas_DeteccaoAlteracoes]
ON [DM_MetricasClientes].[FatoMetricasClientes] 
(
    [SkCliente] ASC,
    [SkProduto] ASC,
    [SkMetrica] ASC,
    [SkDimTabelasConsultadas] ASC,
    [SkTempo] DESC
)
INCLUDE 
(
    [ValorTexto],
    [ValorNumerico],
    [ValorData],
    [ValorBooleano]
)
WITH 
(
    PAD_INDEX = OFF,
    STATISTICS_NORECOMPUTE = OFF,
    SORT_IN_TEMPDB = OFF,
    DROP_EXISTING = OFF,
    ONLINE = OFF,
    ALLOW_ROW_LOCKS = ON,
    ALLOW_PAGE_LOCKS = ON,
    DATA_COMPRESSION = PAGE,
    FILLFACTOR = 90  -- Deixa espaço para crescimento
);
GO

-- =============================================
-- ÍNDICE 6: CONSULTAS DE AGREGAÇÃO TEMPORAL
-- Otimiza relatórios com GROUP BY temporal
-- =============================================

PRINT '6. Criando índice para agregações temporais...';
GO

CREATE NONCLUSTERED INDEX [IX_FatoMetricas_AgregacaoTemporal]
ON [DM_MetricasClientes].[FatoMetricasClientes] 
(
    [SkTempo] ASC,
    [SkMetrica] ASC,
    [SkCliente] ASC
)
INCLUDE 
(
    [ValorNumerico],
    [NomeMetrica],
    [DataProcessamento]
)
WITH 
(
    PAD_INDEX = OFF,
    STATISTICS_NORECOMPUTE = OFF,
    SORT_IN_TEMPDB = OFF,
    DROP_EXISTING = OFF,
    ONLINE = OFF,
    ALLOW_ROW_LOCKS = ON,
    ALLOW_PAGE_LOCKS = ON,
    DATA_COMPRESSION = PAGE
);
GO

-- =============================================
-- ÍNDICE 7: CONSULTAS POR CÓDIGO CLIENTE
-- Otimiza buscas por código de cliente (campo de negócio)
-- =============================================

PRINT '7. Criando índice para consultas por código cliente...';
GO

CREATE NONCLUSTERED INDEX [IX_FatoMetricas_CodigoCliente]
ON [DM_MetricasClientes].[FatoMetricasClientes] 
(
    [CodigoCliente] ASC,
    [NomeMetrica] ASC,
    [SkTempo] DESC
)
INCLUDE 
(
    [SkCliente],
    [SkMetrica],
    [ValorTexto],
    [ValorNumerico],
    [ValorData],
    [ValorBooleano],
    [Ordem]
)
WITH 
(
    PAD_INDEX = OFF,
    STATISTICS_NORECOMPUTE = OFF,
    SORT_IN_TEMPDB = OFF,
    DROP_EXISTING = OFF,
    ONLINE = OFF,
    ALLOW_ROW_LOCKS = ON,
    ALLOW_PAGE_LOCKS = ON,
    DATA_COMPRESSION = PAGE
);
GO

-- =============================================
-- ÍNDICE 8: CONSULTAS DE AUDITORIA
-- Otimiza consultas por data de processamento
-- =============================================

PRINT '8. Criando índice para auditoria...';
GO

CREATE NONCLUSTERED INDEX [IX_FatoMetricas_Auditoria]
ON [DM_MetricasClientes].[FatoMetricasClientes] 
(
    [DataProcessamento] ASC,
    [DataCarga] ASC
)
INCLUDE 
(
    [SkCliente],
    [SkMetrica],
    [NomeMetrica],
    [CodigoCliente],
    [ValorNumerico],
    [SkTempo]
)
WITH 
(
    PAD_INDEX = OFF,
    STATISTICS_NORECOMPUTE = OFF,
    SORT_IN_TEMPDB = OFF,
    DROP_EXISTING = OFF,
    ONLINE = OFF,
    ALLOW_ROW_LOCKS = ON,
    ALLOW_PAGE_LOCKS = ON,
    DATA_COMPRESSION = PAGE
);
GO

-- =============================================
-- ESTATÍSTICAS CUSTOMIZADAS
-- Para otimizar ainda mais as consultas
-- =============================================

PRINT '9. Criando estatísticas customizadas...';
GO

-- Estatística para combinação de filtros comuns
CREATE STATISTICS [ST_FatoMetricas_ClienteMetricaTempo]
ON [DM_MetricasClientes].[FatoMetricasClientes] 
([SkCliente], [SkMetrica], [SkTempo]);
GO

-- Estatística para valores numéricos por métrica
CREATE STATISTICS [ST_FatoMetricas_ValorNumericoMetrica]
ON [DM_MetricasClientes].[FatoMetricasClientes] 
([ValorNumerico], [SkMetrica]);
GO

-- =============================================
-- VERIFICAÇÃO DE FRAGMENTAÇÃO
-- Script para monitorar a saúde dos índices
-- =============================================

PRINT '10. Criando view para monitoramento de fragmentação...';
GO

CREATE OR ALTER VIEW [DM_MetricasClientes].[VwMonitoramentoIndices]
AS
SELECT 
    OBJECT_NAME(ips.object_id) AS NomeTabela,
    i.name AS NomeIndice,
    i.type_desc AS TipoIndice,
    ips.index_type_desc AS DescricaoTipoIndice,
    ips.avg_fragmentation_in_percent AS PercentualFragmentacao,
    ips.page_count AS TotalPaginas,
    ips.avg_page_space_used_in_percent AS PercentualEspacoUsado,
    ips.record_count AS TotalRegistros,
    CASE 
        WHEN ips.avg_fragmentation_in_percent > 30 THEN 'REBUILD RECOMENDADO'
        WHEN ips.avg_fragmentation_in_percent > 10 THEN 'REORGANIZE RECOMENDADO'
        ELSE 'OK'
    END AS RecomendacaoManutencao,
    GETDATE() AS DataVerificacao
FROM sys.dm_db_index_physical_stats(DB_ID(), OBJECT_ID('DM_MetricasClientes.FatoMetricasClientes'), NULL, NULL, 'DETAILED') ips
INNER JOIN sys.indexes i ON ips.object_id = i.object_id AND ips.index_id = i.index_id
WHERE ips.page_count > 10  -- Apenas índices com mais de 10 páginas
  AND i.name IS NOT NULL;  -- Excluir heap
GO

-- =============================================
-- SCRIPT DE MANUTENÇÃO DOS ÍNDICES
-- =============================================

PRINT '11. Criando procedure de manutenção...';
GO

CREATE OR ALTER PROCEDURE [DM_MetricasClientes].[uspManutencaoIndicesFato]
@PercentualFragmentacaoReorganize FLOAT = 10.0,
@PercentualFragmentacaoRebuild FLOAT = 30.0,
@ExecutarManutencao BIT = 0  -- 0 = Apenas relatório, 1 = Executar manutenção
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @SQL NVARCHAR(MAX);
    DECLARE @NomeIndice NVARCHAR(128);
    DECLARE @Fragmentacao FLOAT;
    DECLARE @Acao VARCHAR(20);
    
    PRINT CONCAT('=== MANUTENÇÃO DE ÍNDICES - FATO MÉTRICAS CLIENTES ===');
    PRINT CONCAT('Data/Hora: ', FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss'));
    PRINT CONCAT('Modo: ', CASE WHEN @ExecutarManutencao = 1 THEN 'EXECUÇÃO' ELSE 'RELATÓRIO' END);
    PRINT '';
    
    -- Cursor para percorrer índices fragmentados
    DECLARE cursor_indices CURSOR FOR
    SELECT 
        i.name,
        ips.avg_fragmentation_in_percent,
        CASE 
            WHEN ips.avg_fragmentation_in_percent > @PercentualFragmentacaoRebuild THEN 'REBUILD'
            WHEN ips.avg_fragmentation_in_percent > @PercentualFragmentacaoReorganize THEN 'REORGANIZE'
            ELSE 'OK'
        END
    FROM sys.dm_db_index_physical_stats(DB_ID(), OBJECT_ID('DM_MetricasClientes.FatoMetricasClientes'), NULL, NULL, 'DETAILED') ips
    INNER JOIN sys.indexes i ON ips.object_id = i.object_id AND ips.index_id = i.index_id
    WHERE ips.page_count > 10
      AND i.name IS NOT NULL
      AND ips.avg_fragmentation_in_percent > @PercentualFragmentacaoReorganize;
    
    OPEN cursor_indices;
    FETCH NEXT FROM cursor_indices INTO @NomeIndice, @Fragmentacao, @Acao;
    
    WHILE @@FETCH_STATUS = 0
    BEGIN
        PRINT CONCAT('Índice: ', @NomeIndice, ' - Fragmentação: ', FORMAT(@Fragmentacao, 'N2'), '% - Ação: ', @Acao);
        
        IF @ExecutarManutencao = 1
        BEGIN
            IF @Acao = 'REBUILD'
            BEGIN
                SET @SQL = CONCAT('ALTER INDEX [', @NomeIndice, '] ON [DM_MetricasClientes].[FatoMetricasClientes] REBUILD WITH (DATA_COMPRESSION = PAGE);');
                EXEC sp_executesql @SQL;
                PRINT '  -> REBUILD executado com sucesso';
            END
            ELSE IF @Acao = 'REORGANIZE'
            BEGIN
                SET @SQL = CONCAT('ALTER INDEX [', @NomeIndice, '] ON [DM_MetricasClientes].[FatoMetricasClientes] REORGANIZE;');
                EXEC sp_executesql @SQL;
                PRINT '  -> REORGANIZE executado com sucesso';
            END
        END
        ELSE
        BEGIN
            PRINT '  -> Ação recomendada (não executada)';
        END
        
        FETCH NEXT FROM cursor_indices INTO @NomeIndice, @Fragmentacao, @Acao;
    END
    
    CLOSE cursor_indices;
    DEALLOCATE cursor_indices;
    
    -- Atualizar estatísticas se executou manutenção
    IF @ExecutarManutencao = 1
    BEGIN
        PRINT '';
        PRINT 'Atualizando estatísticas...';
        UPDATE STATISTICS [DM_MetricasClientes].[FatoMetricasClientes];
        PRINT 'Estatísticas atualizadas com sucesso!';
    END
    
    PRINT '';
    PRINT 'Manutenção concluída!';
END;
GO

-- =============================================
-- PERMISSÕES
-- =============================================

GRANT SELECT ON [DM_MetricasClientes].[VwMonitoramentoIndices] TO [db_datareader];
GRANT EXECUTE ON [DM_MetricasClientes].[uspManutencaoIndicesFato] TO [db_executor];
GO

-- =============================================
-- RELATÓRIO FINAL
-- =============================================

PRINT '';
PRINT '=== ÍNDICES CRIADOS COM SUCESSO ===';
PRINT 'Total de índices criados: 8';
PRINT 'Estatísticas customizadas: 2';
PRINT 'Views de monitoramento: 1';
PRINT 'Procedures de manutenção: 1';
PRINT '';
PRINT 'Índices disponíveis:';
PRINT '1. IX_FatoMetricas_UltimoValor - Busca de valores atuais';
PRINT '2. IX_FatoMetricas_Temporal - Análises temporais';
PRINT '3. IX_FatoMetricas_ClientePeriodo - Consultas por cliente';
PRINT '4. IX_FatoMetricas_MetricaEspecifica - Análise por métrica';
PRINT '5. IX_FatoMetricas_DeteccaoAlteracoes - Otimização ETL';
PRINT '6. IX_FatoMetricas_AgregacaoTemporal - Relatórios agregados';
PRINT '7. IX_FatoMetricas_CodigoCliente - Busca por código';
PRINT '8. IX_FatoMetricas_Auditoria - Consultas de auditoria';
PRINT '';
PRINT 'Ferramentas de monitoramento:';
PRINT '- VwMonitoramentoIndices: View para verificar fragmentação';
PRINT '- uspManutencaoIndicesFato: Procedure para manutenção automática';
PRINT '';
PRINT 'Recomendações:';
PRINT '- Execute a manutenção semanalmente: EXEC uspManutencaoIndicesFato @ExecutarManutencao = 1';
PRINT '- Monitore a fragmentação: SELECT * FROM VwMonitoramentoIndices';
PRINT '- Considere particionamento se a tabela crescer muito (>100M registros)';
GO