-- =============================================
-- VALIDAÇÃO E MONITORAMENTO SCD TIPO 2 - DIMCLIENTES
-- Chave de Verificação: SiglaCliente
-- =============================================

-- =============================================
-- 1. VALIDAÇÕES DE INTEGRIDADE
-- =============================================
PRINT '========== VALIDAÇÕES DE INTEGRIDADE SCD TIPO 2 - DIMCLIENTES ==========';
PRINT '';

-- 1.1 Verificar versões atuais únicas por SiglaCliente
PRINT '1. Verificando versões atuais únicas por SiglaCliente...';
SELECT 
    SiglaCliente,
    COUNT(*) AS VersoesAtuais,
    STRING_AGG(CAST(SkCliente AS VARCHAR(10)), ', ') AS SkClientes
FROM Shared.DimClientes 
WHERE VersaoAtual = 1
GROUP BY SiglaCliente
HAVING COUNT(*) > 1
ORDER BY SiglaCliente;

IF @@ROWCOUNT = 0
    PRINT '   ✓ SUCESSO: Todas as SiglaCliente possuem apenas uma versão atual';
ELSE
    PRINT '   ✗ ERRO: Encontradas SiglaCliente com múltiplas versões atuais!';

PRINT '';

-- 1.2 Verificar DataFimVersao em versões históricas
PRINT '2. Verificando DataFimVersao em versões históricas...';
SELECT 
    SkCliente,
    SiglaCliente,
    Nome,
    DataInicioVersao,
    DataFimVersao,
    VersaoAtual
FROM Shared.DimClientes 
WHERE VersaoAtual = 0
  AND DataFimVersao IS NULL
ORDER BY SiglaCliente, DataInicioVersao;

IF @@ROWCOUNT = 0
    PRINT '   ✓ SUCESSO: Todas as versões históricas possuem DataFimVersao';
ELSE
    PRINT '   ✗ ERRO: Encontradas versões históricas sem DataFimVersao!';

PRINT '';

-- 1.3 Verificar DataFimVersao em versões atuais
PRINT '3. Verificando DataFimVersao em versões atuais...';
SELECT 
    SkCliente,
    SiglaCliente,
    Nome,
    DataInicioVersao,
    DataFimVersao,
    VersaoAtual
FROM Shared.DimClientes 
WHERE VersaoAtual = 1
  AND DataFimVersao IS NOT NULL
ORDER BY SiglaCliente;

IF @@ROWCOUNT = 0
    PRINT '   ✓ SUCESSO: Todas as versões atuais não possuem DataFimVersao';
ELSE
    PRINT '   ✗ ERRO: Encontradas versões atuais com DataFimVersao!';

PRINT '';

-- 1.4 Verificar consistência temporal (DataInicioVersao < DataFimVersao)
PRINT '4. Verificando consistência temporal...';
SELECT 
    SkCliente,
    SiglaCliente,
    Nome,
    DataInicioVersao,
    DataFimVersao,
    DATEDIFF(SECOND, DataInicioVersao, DataFimVersao) AS DiferencaSegundos
FROM Shared.DimClientes 
WHERE DataFimVersao IS NOT NULL
  AND DataInicioVersao >= DataFimVersao
ORDER BY SiglaCliente, DataInicioVersao;

IF @@ROWCOUNT = 0
    PRINT '   ✓ SUCESSO: Todas as datas estão consistentes';
ELSE
    PRINT '   ✗ ERRO: Encontradas inconsistências temporais!';

PRINT '';

-- =============================================
-- 2. RELATÓRIOS DE MONITORAMENTO
-- =============================================
PRINT '========== RELATÓRIOS DE MONITORAMENTO ==========';
PRINT '';

-- 2.1 Resumo geral da dimensão
PRINT '1. Resumo Geral da DimClientes:';
SELECT 
    COUNT(*) AS TotalRegistros,
    COUNT(DISTINCT SiglaCliente) AS TotalClientesUnicos,
    SUM(CASE WHEN VersaoAtual = 1 THEN 1 ELSE 0 END) AS VersoesAtuais,
    SUM(CASE WHEN VersaoAtual = 0 THEN 1 ELSE 0 END) AS VersoesHistoricas,
    MIN(DataInicioVersao) AS PrimeiroRegistro,
    MAX(DataInicioVersao) AS UltimoRegistro
FROM Shared.DimClientes;

PRINT '';

-- 2.2 Distribuição por tipo de cliente
PRINT '2. Distribuição por Tipo de Cliente (versões atuais):';
SELECT 
    ISNULL(TipoCliente, 'Não Informado') AS TipoCliente,
    COUNT(*) AS Quantidade,
    CAST(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER() AS DECIMAL(5,2)) AS Percentual
FROM Shared.DimClientes 
WHERE VersaoAtual = 1
GROUP BY TipoCliente
ORDER BY COUNT(*) DESC;

PRINT '';

-- 2.3 Distribuição por estado
PRINT '3. Distribuição por Estado (versões atuais):';
SELECT 
    ISNULL(Estado, 'Não Informado') AS Estado,
    COUNT(*) AS Quantidade,
    CAST(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER() AS DECIMAL(5,2)) AS Percentual
FROM Shared.DimClientes 
WHERE VersaoAtual = 1
GROUP BY Estado
ORDER BY COUNT(*) DESC;

PRINT '';

-- 2.4 Clientes com histórico de mudanças
PRINT '4. Clientes com Histórico de Mudanças:';
SELECT 
    SiglaCliente,
    COUNT(*) AS TotalVersoes,
    MIN(DataInicioVersao) AS PrimeiraVersao,
    MAX(DataInicioVersao) AS UltimaVersao,
    DATEDIFF(DAY, MIN(DataInicioVersao), MAX(DataInicioVersao)) AS DiasHistorico
FROM Shared.DimClientes 
GROUP BY SiglaCliente
HAVING COUNT(*) > 1
ORDER BY COUNT(*) DESC, SiglaCliente;

PRINT '';

-- 2.5 Atividade recente (últimos 30 dias)
PRINT '5. Atividade Recente (últimos 30 dias):';
SELECT 
    CAST(DataCarga AS DATE) AS DataCarga,
    COUNT(*) AS RegistrosInseridos,
    COUNT(DISTINCT SiglaCliente) AS ClientesAfetados
FROM Shared.DimClientes 
WHERE DataCarga >= DATEADD(DAY, -30, GETDATE())
GROUP BY CAST(DataCarga AS DATE)
ORDER BY DataCarga DESC;

PRINT '';

-- =============================================
-- 3. QUERIES DE ANÁLISE TEMPORAL
-- =============================================
PRINT '========== QUERIES DE ANÁLISE TEMPORAL ==========';
PRINT '';

-- 3.1 Buscar histórico de um cliente específico
PRINT '1. Exemplo: Histórico de um Cliente (substitua a SiglaCliente):';
PRINT 'SELECT * FROM Shared.DimClientes WHERE SiglaCliente = ''SUA_SIGLA_AQUI'' ORDER BY DataInicioVersao;';
PRINT '';

-- 3.2 Buscar versão atual de um cliente
PRINT '2. Exemplo: Versão Atual de um Cliente:';
PRINT 'SELECT * FROM Shared.DimClientes WHERE SiglaCliente = ''SUA_SIGLA_AQUI'' AND VersaoAtual = 1;';
PRINT '';

-- 3.3 Buscar cliente em data específica
PRINT '3. Exemplo: Cliente em Data Específica:';
PRINT 'SELECT * FROM Shared.DimClientes';
PRINT 'WHERE SiglaCliente = ''SUA_SIGLA_AQUI''';
PRINT '  AND DataInicioVersao <= ''2024-01-01''';
PRINT '  AND (DataFimVersao IS NULL OR DataFimVersao > ''2024-01-01'');';
PRINT '';

-- 3.4 Comparar mudanças entre versões
PRINT '4. Exemplo: Comparar Mudanças entre Versões:';
PRINT 'WITH HistoricoCliente AS (';
PRINT '    SELECT *, ROW_NUMBER() OVER (ORDER BY DataInicioVersao) AS NumVersao';
PRINT '    FROM Shared.DimClientes';
PRINT '    WHERE SiglaCliente = ''SUA_SIGLA_AQUI''';
PRINT ')';
PRINT 'SELECT';
PRINT '    v1.NumVersao AS VersaoAnterior,';
PRINT '    v2.NumVersao AS VersaoAtual,';
PRINT '    v1.Nome AS NomeAnterior,';
PRINT '    v2.Nome AS NomeAtual,';
PRINT '    v1.TipoCliente AS TipoAnterior,';
PRINT '    v2.TipoCliente AS TipoAtual,';
PRINT '    v2.DataInicioVersao AS DataMudanca';
PRINT 'FROM HistoricoCliente v1';
PRINT 'INNER JOIN HistoricoCliente v2 ON v1.NumVersao = v2.NumVersao - 1;';
PRINT '';

-- =============================================
-- 4. COMANDOS DE MANUTENÇÃO
-- =============================================
PRINT '========== COMANDOS DE MANUTENÇÃO ==========';
PRINT '';

-- 4.1 Reativar cliente desativado (criar nova versão)
PRINT '1. Reativar Cliente Desativado:';
PRINT '/*';
PRINT 'DECLARE @SiglaCliente VARCHAR(250) = ''SUA_SIGLA_AQUI'';';
PRINT 'DECLARE @DataAtivacao DATETIME2(2) = GETDATE();';
PRINT '';
PRINT '-- Fechar versão atual';
PRINT 'UPDATE Shared.DimClientes';
PRINT 'SET DataFimVersao = @DataAtivacao, VersaoAtual = 0, DataAtualizacao = @DataAtivacao';
PRINT 'WHERE SiglaCliente = @SiglaCliente AND VersaoAtual = 1;';
PRINT '';
PRINT '-- Inserir nova versão ativa';
PRINT 'INSERT INTO Shared.DimClientes (...) -- Copiar estrutura da versão anterior';
PRINT 'SELECT ... FROM Shared.DimClientes';
PRINT 'WHERE SiglaCliente = @SiglaCliente AND DataFimVersao = @DataAtivacao;';
PRINT '*/';
PRINT '';

-- 4.2 Limpar histórico antigo (manter apenas N versões)
PRINT '2. Limpar Histórico Antigo (manter apenas últimas 5 versões):';
PRINT '/*';
PRINT 'WITH HistoricoRankeado AS (';
PRINT '    SELECT SkCliente,';
PRINT '           ROW_NUMBER() OVER (PARTITION BY SiglaCliente ORDER BY DataInicioVersao DESC) AS rn';
PRINT '    FROM Shared.DimClientes';
PRINT ')';
PRINT 'DELETE FROM Shared.DimClientes';
PRINT 'WHERE SkCliente IN (';
PRINT '    SELECT SkCliente FROM HistoricoRankeado WHERE rn > 5';
PRINT ');';
PRINT '*/';
PRINT '';

-- =============================================
-- 5. ALERTAS E MONITORAMENTO
-- =============================================
PRINT '========== ALERTAS E MONITORAMENTO ==========';
PRINT '';

-- 5.1 Clientes com muitas mudanças (possível problema de dados)
PRINT '1. Clientes com Muitas Mudanças (>= 5 versões):';
SELECT 
    SiglaCliente,
    COUNT(*) AS TotalVersoes,
    MIN(DataInicioVersao) AS PrimeiraVersao,
    MAX(DataInicioVersao) AS UltimaVersao
FROM Shared.DimClientes 
GROUP BY SiglaCliente
HAVING COUNT(*) >= 5
ORDER BY COUNT(*) DESC;

PRINT '';

-- 5.2 Clientes sem atividade recente
PRINT '2. Clientes sem Atividade Recente (>90 dias):';
SELECT 
    SiglaCliente,
    Nome,
    TipoCliente,
    Estado,
    DataInicioVersao AS UltimaAtividade,
    DATEDIFF(DAY, DataInicioVersao, GETDATE()) AS DiasSemAtividade
FROM Shared.DimClientes 
WHERE VersaoAtual = 1
  AND DataInicioVersao < DATEADD(DAY, -90, GETDATE())
ORDER BY DataInicioVersao;

PRINT '';

-- 5.3 Verificar inconsistências de dados
PRINT '3. Inconsistências de Dados:';
SELECT 
    'Nome em branco' AS TipoInconsistencia,
    COUNT(*) AS Quantidade
FROM Shared.DimClientes 
WHERE VersaoAtual = 1 AND (Nome IS NULL OR LTRIM(RTRIM(Nome)) = '')

UNION ALL

SELECT 
    'SiglaCliente em branco' AS TipoInconsistencia,
    COUNT(*) AS Quantidade
FROM Shared.DimClientes 
WHERE VersaoAtual = 1 AND (SiglaCliente IS NULL OR LTRIM(RTRIM(SiglaCliente)) = '')

UNION ALL

SELECT 
    'TipoCliente em branco' AS TipoInconsistencia,
    COUNT(*) AS Quantidade
FROM Shared.DimClientes 
WHERE VersaoAtual = 1 AND (TipoCliente IS NULL OR LTRIM(RTRIM(TipoCliente)) = '')

UNION ALL

SELECT 
    'Estado inválido' AS TipoInconsistencia,
    COUNT(*) AS Quantidade
FROM Shared.DimClientes 
WHERE VersaoAtual = 1 
  AND Estado IS NOT NULL 
  AND LEN(Estado) <> 2
  AND Estado <> 'BR';

PRINT '';

-- =============================================
-- 6. ESTATÍSTICAS DE PERFORMANCE
-- =============================================
PRINT '========== ESTATÍSTICAS DE PERFORMANCE ==========';
PRINT '';

-- 6.1 Tamanho da tabela
PRINT '1. Informações de Tamanho:';
SELECT 
    OBJECT_NAME(i.object_id) AS NomeTabela,
    i.name AS NomeIndice,
    SUM(s.used_page_count) * 8 AS TamanhoKB,
    SUM(s.used_page_count) * 8 / 1024 AS TamanhoMB,
    SUM(s.row_count) AS NumeroLinhas
FROM sys.dm_db_partition_stats s
INNER JOIN sys.indexes i ON s.object_id = i.object_id AND s.index_id = i.index_id
WHERE i.object_id = OBJECT_ID('Shared.DimClientes')
GROUP BY i.object_id, i.name
ORDER BY SUM(s.used_page_count) DESC;

PRINT '';

-- 6.2 Uso de índices
PRINT '2. Estatísticas de Uso de Índices:';
SELECT 
    i.name AS NomeIndice,
    s.user_seeks AS Buscas,
    s.user_scans AS Varreduras,
    s.user_lookups AS Consultas,
    s.user_updates AS Atualizacoes,
    s.last_user_seek AS UltimaBusca,
    s.last_user_scan AS UltimaVarredura
FROM sys.dm_db_index_usage_stats s
INNER JOIN sys.indexes i ON s.object_id = i.object_id AND s.index_id = i.index_id
WHERE s.object_id = OBJECT_ID('Shared.DimClientes')
ORDER BY s.user_seeks + s.user_scans + s.user_lookups DESC;

PRINT '';
PRINT '========== VALIDAÇÃO CONCLUÍDA ==========';
PRINT 'Execute este script regularmente para monitorar a saúde do SCD Tipo 2 na DimClientes.';
PRINT 'Chave de verificação: SiglaCliente';
PRINT 'Campos monitorados: Nome, TipoCliente, SkConselhoFederal, Estado, ClienteAtivoImplanta';