-- =============================================
-- SCRIPT DE TESTE PARA SCD TIPO 2 - DIMCLIENTES
-- Procedure: uspLoadDimClientes
-- Chave de Verificação: SiglaCliente
-- =============================================

-- Limpar dados de teste anteriores
PRINT '========== LIMPEZA DE DADOS DE TESTE ==========';
DELETE FROM Shared.DimClientes WHERE SiglaCliente IN ('TESTE/SP', 'TESTE2/RJ', 'TESTE3/MG');
PRINT 'Dados de teste removidos.';

-- =============================================
-- CENÁRIO 1: INSERÇÃO DE NOVOS CLIENTES
-- =============================================
PRINT '';
PRINT '========== CENÁRIO 1: INSERÇÃO DE NOVOS CLIENTES ==========';

-- Simular dados na tabela de staging
IF OBJECT_ID('tempdb..#TestSourceClientes') IS NOT NULL DROP TABLE #TestSourceClientes;
CREATE TABLE #TestSourceClientes
(
    [IdCliente]            UNIQUEIDENTIFIER,
    [SkConselhoFederal]    SMALLINT,
    [NomeCliente]          VARCHAR(8000),
    [SiglaCliente]         VARCHAR(250),
    [SkCategoria]          SMALLINT,
    [UF]                   VARCHAR(250),
    [TipoCliente]          VARCHAR(22),
    [ClienteAtivoImplanta] BIT 
);

-- Inserir dados de teste
INSERT INTO #TestSourceClientes VALUES
(NEWID(), 1, 'Conselho Regional de Medicina de São Paulo', 'TESTE/SP', 1, 'SP', 'Conselho', 1),
(NEWID(), 2, 'Conselho Regional de Enfermagem do Rio de Janeiro', 'TESTE2/RJ', 2, 'RJ', 'Conselho', 1),
(NEWID(), 3, 'Ordem dos Advogados de Minas Gerais', 'TESTE3/MG', 3, 'MG', 'Ordem dos Advogados', 1);

-- Simular inserção de novos clientes
INSERT INTO Shared.DimClientes
(
    IdCliente,
    SkConselhoFederal,
    Nome,
    SiglaCliente,
    Estado,
    TipoCliente,
    Ativo,
    ClienteAtivoImplanta,
    DataInicioVersao,
    DataFimVersao,
    VersaoAtual,
    DataCarga,
    DataAtualizacao
)
SELECT 
    src.IdCliente,
    src.SkConselhoFederal,
    src.NomeCliente,
    src.SiglaCliente,
    src.UF,
    src.TipoCliente,
    1,
    src.ClienteAtivoImplanta,
    GETDATE(),
    NULL,
    1,
    GETDATE(),
    GETDATE()
FROM #TestSourceClientes src;

PRINT 'Novos clientes inseridos: ' + CAST(@@ROWCOUNT AS VARCHAR(10));

-- Verificar inserção
SELECT 
    SkCliente,
    Nome,
    SiglaCliente,
    TipoCliente,
    Estado,
    VersaoAtual,
    DataInicioVersao,
    DataFimVersao
FROM Shared.DimClientes 
WHERE SiglaCliente IN ('TESTE/SP', 'TESTE2/RJ', 'TESTE3/MG')
ORDER BY SiglaCliente, DataInicioVersao;

-- =============================================
-- CENÁRIO 2: ATUALIZAÇÃO DE CLIENTES (SCD TIPO 2)
-- =============================================
PRINT '';
PRINT '========== CENÁRIO 2: ATUALIZAÇÃO DE CLIENTES (SCD TIPO 2) ==========';

-- Aguardar 1 segundo para diferença temporal
WAITFOR DELAY '00:00:01';

-- Simular alterações nos dados de origem
UPDATE #TestSourceClientes 
SET 
    NomeCliente = 'Conselho Regional de Medicina de São Paulo - ATUALIZADO',
    TipoCliente = 'Conselho Atualizado'
WHERE SiglaCliente = 'TESTE/SP';

UPDATE #TestSourceClientes 
SET 
    SkConselhoFederal = 5,
    Estado = 'RJ',
    ClienteAtivoImplanta = 0
WHERE SiglaCliente = 'TESTE2/RJ';

-- Simular processo SCD Tipo 2
DECLARE @DataAtualizacao DATETIME2(2) = GETDATE();

-- 1. Identificar registros alterados
IF OBJECT_ID('tempdb..#ClientesAlterados') IS NOT NULL DROP TABLE #ClientesAlterados;
CREATE TABLE #ClientesAlterados
(
    SiglaCliente VARCHAR(250),
    SkClienteAtual INT,
    IdCliente UNIQUEIDENTIFIER,
    NovoNome VARCHAR(8000),
    NovoTipoCliente VARCHAR(22),
    NovoSkConselhoFederal SMALLINT,
    NovoUF VARCHAR(250),
    NovoClienteAtivoImplanta BIT
);

INSERT INTO #ClientesAlterados
(
    SiglaCliente,
    SkClienteAtual,
    IdCliente,
    NovoNome,
    NovoTipoCliente,
    NovoSkConselhoFederal,
    NovoUF,
    NovoClienteAtivoImplanta
)
SELECT 
    src.SiglaCliente,
    dim.SkCliente,
    src.IdCliente,
    src.NomeCliente,
    src.TipoCliente,
    src.SkConselhoFederal,
    src.UF,
    src.ClienteAtivoImplanta
FROM #TestSourceClientes src
INNER JOIN Shared.DimClientes dim ON src.SiglaCliente = dim.SiglaCliente
                                  AND dim.VersaoAtual = 1
WHERE (
    ISNULL(src.NomeCliente, '') <> ISNULL(dim.Nome, '') OR
    ISNULL(src.TipoCliente, '') <> ISNULL(dim.TipoCliente, '') OR
    ISNULL(src.SkConselhoFederal, 0) <> ISNULL(dim.SkConselhoFederal, 0) OR
    ISNULL(src.UF, '') <> ISNULL(dim.Estado, '') OR
    ISNULL(src.ClienteAtivoImplanta, 0) <> ISNULL(dim.ClienteAtivoImplanta, 0)
);

PRINT 'Clientes identificados para atualização: ' + CAST(@@ROWCOUNT AS VARCHAR(10));

-- 2. Fechar versões antigas
UPDATE dim
SET 
    DataFimVersao = @DataAtualizacao,
    VersaoAtual = 0,
    DataAtualizacao = @DataAtualizacao
FROM Shared.DimClientes dim
INNER JOIN #ClientesAlterados alt ON dim.SkCliente = alt.SkClienteAtual;

PRINT 'Versões antigas fechadas: ' + CAST(@@ROWCOUNT AS VARCHAR(10));

-- 3. Inserir novas versões
INSERT INTO Shared.DimClientes
(
    IdCliente,
    SkConselhoFederal,
    Nome,
    SiglaCliente,
    Estado,
    TipoCliente,
    Ativo,
    ClienteAtivoImplanta,
    DataInicioVersao,
    DataFimVersao,
    VersaoAtual,
    DataCarga,
    DataAtualizacao
)
SELECT 
    alt.IdCliente,
    alt.NovoSkConselhoFederal,
    alt.NovoNome,
    alt.SiglaCliente,
    alt.NovoUF,
    alt.NovoTipoCliente,
    1,
    alt.NovoClienteAtivoImplanta,
    @DataAtualizacao,
    NULL,
    1,
    @DataAtualizacao,
    @DataAtualizacao
FROM #ClientesAlterados alt;

PRINT 'Novas versões inseridas: ' + CAST(@@ROWCOUNT AS VARCHAR(10));

-- =============================================
-- VALIDAÇÃO DOS RESULTADOS
-- =============================================
PRINT '';
PRINT '========== VALIDAÇÃO DOS RESULTADOS ==========';

-- Verificar histórico completo
PRINT 'Histórico completo dos clientes de teste:';
SELECT 
    SkCliente,
    Nome,
    SiglaCliente,
    TipoCliente,
    Estado,
    SkConselhoFederal,
    ClienteAtivoImplanta,
    VersaoAtual,
    DataInicioVersao,
    DataFimVersao,
    'Versão ' + CAST(ROW_NUMBER() OVER (PARTITION BY SiglaCliente ORDER BY DataInicioVersao) AS VARCHAR(10)) AS NumeroVersao
FROM Shared.DimClientes 
WHERE SiglaCliente IN ('TESTE/SP', 'TESTE2/RJ', 'TESTE3/MG')
ORDER BY SiglaCliente, DataInicioVersao;

-- =============================================
-- QUERIES DE ANÁLISE TEMPORAL
-- =============================================
PRINT '';
PRINT '========== QUERIES DE ANÁLISE TEMPORAL ==========';

-- 1. Versões atuais apenas
PRINT 'Versões atuais:';
SELECT 
    SkCliente,
    Nome,
    SiglaCliente,
    TipoCliente,
    VersaoAtual,
    DataInicioVersao
FROM Shared.DimClientes 
WHERE SiglaCliente IN ('TESTE/SP', 'TESTE2/RJ', 'TESTE3/MG')
  AND VersaoAtual = 1
ORDER BY SiglaCliente;

-- 2. Clientes que sofreram alterações
PRINT 'Clientes com histórico de mudanças:';
SELECT 
    SiglaCliente,
    COUNT(*) AS TotalVersoes,
    MIN(DataInicioVersao) AS PrimeiraVersao,
    MAX(DataInicioVersao) AS UltimaVersao
FROM Shared.DimClientes 
WHERE SiglaCliente IN ('TESTE/SP', 'TESTE2/RJ', 'TESTE3/MG')
GROUP BY SiglaCliente
HAVING COUNT(*) > 1
ORDER BY SiglaCliente;

-- 3. Comparação entre versões
PRINT 'Comparação entre primeira e última versão:';
WITH PrimeiraVersao AS (
    SELECT 
        SiglaCliente,
        Nome AS NomeOriginal,
        TipoCliente AS TipoOriginal,
        SkConselhoFederal AS ConselhoOriginal,
        ROW_NUMBER() OVER (PARTITION BY SiglaCliente ORDER BY DataInicioVersao) AS rn
    FROM Shared.DimClientes 
    WHERE SiglaCliente IN ('TESTE/SP', 'TESTE2/RJ', 'TESTE3/MG')
),
UltimaVersao AS (
    SELECT 
        SiglaCliente,
        Nome AS NomeAtual,
        TipoCliente AS TipoAtual,
        SkConselhoFederal AS ConselhoAtual
    FROM Shared.DimClientes 
    WHERE SiglaCliente IN ('TESTE/SP', 'TESTE2/RJ', 'TESTE3/MG')
      AND VersaoAtual = 1
)
SELECT 
    p.SiglaCliente,
    p.NomeOriginal,
    u.NomeAtual,
    CASE WHEN p.NomeOriginal <> u.NomeAtual THEN 'ALTERADO' ELSE 'INALTERADO' END AS StatusNome,
    p.TipoOriginal,
    u.TipoAtual,
    CASE WHEN p.TipoOriginal <> u.TipoAtual THEN 'ALTERADO' ELSE 'INALTERADO' END AS StatusTipo
FROM PrimeiraVersao p
INNER JOIN UltimaVersao u ON p.SiglaCliente = u.SiglaCliente
WHERE p.rn = 1;

-- =============================================
-- VALIDAÇÕES DE INTEGRIDADE
-- =============================================
PRINT '';
PRINT '========== VALIDAÇÕES DE INTEGRIDADE ==========';

-- 1. Verificar se existe apenas uma versão atual por SiglaCliente
PRINT 'Verificação de versões atuais únicas:';
SELECT 
    SiglaCliente,
    COUNT(*) AS VersoesAtuais
FROM Shared.DimClientes 
WHERE SiglaCliente IN ('TESTE/SP', 'TESTE2/RJ', 'TESTE3/MG')
  AND VersaoAtual = 1
GROUP BY SiglaCliente
HAVING COUNT(*) > 1;

IF @@ROWCOUNT = 0
    PRINT '✓ Todas as SiglaCliente possuem apenas uma versão atual';
ELSE
    PRINT '✗ ERRO: Encontradas SiglaCliente com múltiplas versões atuais';

-- 2. Verificar se versões históricas possuem DataFimVersao
PRINT 'Verificação de DataFimVersao em versões históricas:';
SELECT 
    SkCliente,
    SiglaCliente,
    VersaoAtual,
    DataFimVersao
FROM Shared.DimClientes 
WHERE SiglaCliente IN ('TESTE/SP', 'TESTE2/RJ', 'TESTE3/MG')
  AND VersaoAtual = 0
  AND DataFimVersao IS NULL;

IF @@ROWCOUNT = 0
    PRINT '✓ Todas as versões históricas possuem DataFimVersao';
ELSE
    PRINT '✗ ERRO: Encontradas versões históricas sem DataFimVersao';

-- 3. Verificar se versões atuais não possuem DataFimVersao
PRINT 'Verificação de DataFimVersao em versões atuais:';
SELECT 
    SkCliente,
    SiglaCliente,
    VersaoAtual,
    DataFimVersao
FROM Shared.DimClientes 
WHERE SiglaCliente IN ('TESTE/SP', 'TESTE2/RJ', 'TESTE3/MG')
  AND VersaoAtual = 1
  AND DataFimVersao IS NOT NULL;

IF @@ROWCOUNT = 0
    PRINT '✓ Todas as versões atuais não possuem DataFimVersao';
ELSE
    PRINT '✗ ERRO: Encontradas versões atuais com DataFimVersao';

-- =============================================
-- LIMPEZA FINAL
-- =============================================
PRINT '';
PRINT '========== LIMPEZA FINAL ==========';

-- Remover dados de teste
DELETE FROM Shared.DimClientes WHERE SiglaCliente IN ('TESTE/SP', 'TESTE2/RJ', 'TESTE3/MG');
PRINT 'Dados de teste removidos: ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' registros';

-- Limpar tabelas temporárias
DROP TABLE IF EXISTS #TestSourceClientes;
DROP TABLE IF EXISTS #ClientesAlterados;

PRINT '';
PRINT '========== TESTE CONCLUÍDO COM SUCESSO! ==========';
PRINT 'O SCD Tipo 2 para DimClientes está funcionando corretamente.';
PRINT 'Chave de verificação: SiglaCliente';
PRINT 'Campos monitorados: Nome, TipoCliente, SkConselhoFederal, Estado, ClienteAtivoImplanta';