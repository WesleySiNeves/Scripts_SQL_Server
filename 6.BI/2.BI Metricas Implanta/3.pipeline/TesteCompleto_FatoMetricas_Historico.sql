-- =============================================
-- Teste Completo - Estratégia de Histórico Fato Métricas
-- Descrição: Testes abrangentes para validar a implementação do histórico
-- Autor: Sistema
-- Data: 2024
-- =============================================

USE [DW_MetricasClientes];
GO

PRINT '=========================================';
PRINT 'TESTE COMPLETO - HISTÓRICO FATO MÉTRICAS';
PRINT '=========================================';
PRINT CONCAT('Início dos testes: ', FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss'));
PRINT '';

-- =============================================
-- PREPARAÇÃO DO AMBIENTE DE TESTE
-- =============================================

PRINT '1. PREPARANDO AMBIENTE DE TESTE...';
GO

-- Limpar dados de teste anteriores
DELETE FROM DM_MetricasClientes.FatoMetricasClientes 
WHERE CodigoCliente IN ('TESTE-01', 'TESTE-02', 'TESTE-03');

DELETE FROM Staging.MetricasClientes 
WHERE Cliente IN ('TESTE-01', 'TESTE-02', 'TESTE-03');

PRINT 'Ambiente limpo para testes.';
GO

-- =============================================
-- CENÁRIO 1: INSERÇÃO DE NOVOS REGISTROS
-- =============================================

PRINT '';
PRINT '2. CENÁRIO 1: INSERÇÃO DE NOVOS REGISTROS';
PRINT '============================================';
GO

-- Inserir dados iniciais na staging
INSERT INTO Staging.MetricasClientes 
(Cliente, CodSistema, Ordem, NomeMetrica, TipoRetorno, TabelaConsultada, Valor, DataCarga, DataProcessamento)
VALUES
-- Cliente TESTE-01 - Métricas iniciais
('TESTE-01', 1, 1, 'QtdRegistrosSistema', 'DECIMAL', 'Registros', '100', '2024-01-01 08:00:00', NULL),
('TESTE-01', 1, 2, 'DataUltimoAcesso', 'DATETIME', 'Acessos', '2024-01-01 07:30:00', '2024-01-01 08:00:00', NULL),
('TESTE-01', 1, 3, 'StatusSistema', 'TEXT', 'Status', 'ATIVO', '2024-01-01 08:00:00', NULL),
('TESTE-01', 1, 4, 'SistemaAtivo', 'BIT', 'Configuracao', '1', '2024-01-01 08:00:00', NULL),

-- Cliente TESTE-02 - Métricas iniciais
('TESTE-02', 1, 1, 'QtdRegistrosSistema', 'DECIMAL', 'Registros', '250', '2024-01-01 08:00:00', NULL),
('TESTE-02', 1, 2, 'DataUltimoAcesso', 'DATETIME', 'Acessos', '2024-01-01 07:45:00', '2024-01-01 08:00:00', NULL),
('TESTE-02', 1, 3, 'StatusSistema', 'TEXT', 'Status', 'ATIVO', '2024-01-01 08:00:00', NULL);

PRINT 'Dados iniciais inseridos na staging.';
GO

-- Executar primeira carga
PRINT 'Executando primeira carga...';
EXEC DM_MetricasClientes.uspLoadFatoMetricasClientes @DataProcessamento = '2024-01-01 08:00:00';
GO

-- Verificar resultados da primeira carga
PRINT 'Verificando resultados da primeira carga:';
SELECT 
    'PRIMEIRA_CARGA' AS Cenario,
    CodigoCliente,
    NomeMetrica,
    CASE 
        WHEN ValorTexto IS NOT NULL THEN ValorTexto
        WHEN ValorNumerico IS NOT NULL THEN CAST(ValorNumerico AS VARCHAR(50))
        WHEN ValorData IS NOT NULL THEN FORMAT(ValorData, 'yyyy-MM-dd HH:mm:ss')
        WHEN ValorBooleano IS NOT NULL THEN CASE WHEN ValorBooleano = 1 THEN 'Sim' ELSE 'Não' END
        ELSE 'NULL'
    END AS Valor,
    SkTempo,
    DataProcessamento
FROM DM_MetricasClientes.FatoMetricasClientes
WHERE CodigoCliente IN ('TESTE-01', 'TESTE-02')
ORDER BY CodigoCliente, NomeMetrica;
GO

-- =============================================
-- CENÁRIO 2: ALTERAÇÃO DE VALORES (SEM MUDANÇA)
-- =============================================

PRINT '';
PRINT '3. CENÁRIO 2: REPROCESSAMENTO SEM ALTERAÇÕES';
PRINT '==============================================';
GO

-- Reprocessar os mesmos dados (não deve inserir nada)
PRINT 'Reprocessando os mesmos dados...';
EXEC DM_MetricasClientes.uspLoadFatoMetricasClientes @DataProcessamento = '2024-01-01 09:00:00';
GO

-- Verificar que não houve inserções
PRINT 'Verificando que não houve inserções desnecessárias:';
SELECT 
    'REPROCESSAMENTO' AS Cenario,
    CodigoCliente,
    COUNT(*) AS TotalSnapshots,
    MAX(DataProcessamento) AS UltimoProcessamento
FROM DM_MetricasClientes.FatoMetricasClientes
WHERE CodigoCliente IN ('TESTE-01', 'TESTE-02')
GROUP BY CodigoCliente
ORDER BY CodigoCliente;
GO

-- =============================================
-- CENÁRIO 3: ALTERAÇÕES REAIS DE VALORES
-- =============================================

PRINT '';
PRINT '4. CENÁRIO 3: ALTERAÇÕES REAIS DE VALORES';
PRINT '==========================================';
GO

-- Limpar staging e inserir dados alterados
DELETE FROM Staging.MetricasClientes WHERE Cliente IN ('TESTE-01', 'TESTE-02');

INSERT INTO Staging.MetricasClientes 
(Cliente, CodSistema, Ordem, NomeMetrica, TipoRetorno, TabelaConsultada, Valor, DataCarga, DataProcessamento)
VALUES
-- TESTE-01 - Algumas métricas alteradas
('TESTE-01', 1, 1, 'QtdRegistrosSistema', 'DECIMAL', 'Registros', '150', '2024-01-02 08:00:00', NULL), -- Alterado: 100 -> 150
('TESTE-01', 1, 2, 'DataUltimoAcesso', 'DATETIME', 'Acessos', '2024-01-02 07:30:00', '2024-01-02 08:00:00', NULL), -- Alterado
('TESTE-01', 1, 3, 'StatusSistema', 'TEXT', 'Status', 'ATIVO', '2024-01-02 08:00:00', NULL), -- Sem alteração
('TESTE-01', 1, 4, 'SistemaAtivo', 'BIT', 'Configuracao', '0', '2024-01-02 08:00:00', NULL), -- Alterado: 1 -> 0
('TESTE-01', 1, 5, 'NovaMetrica', 'DECIMAL', 'Registros', '75', '2024-01-02 08:00:00', NULL), -- Nova métrica

-- TESTE-02 - Apenas uma métrica alterada
('TESTE-02', 1, 1, 'QtdRegistrosSistema', 'DECIMAL', 'Registros', '300', '2024-01-02 08:00:00', NULL), -- Alterado: 250 -> 300
('TESTE-02', 1, 2, 'DataUltimoAcesso', 'DATETIME', 'Acessos', '2024-01-01 07:45:00', '2024-01-02 08:00:00', NULL), -- Sem alteração
('TESTE-02', 1, 3, 'StatusSistema', 'TEXT', 'Status', 'ATIVO', '2024-01-02 08:00:00', NULL); -- Sem alteração

PRINT 'Dados alterados inseridos na staging.';
GO

-- Executar carga com alterações
PRINT 'Executando carga com alterações...';
EXEC DM_MetricasClientes.uspLoadFatoMetricasClientes @DataProcessamento = '2024-01-02 08:00:00';
GO

-- Verificar histórico de alterações
PRINT 'Verificando histórico de alterações:';
SELECT 
    'HISTORICO_ALTERACOES' AS Cenario,
    CodigoCliente,
    NomeMetrica,
    CASE 
        WHEN ValorTexto IS NOT NULL THEN ValorTexto
        WHEN ValorNumerico IS NOT NULL THEN CAST(ValorNumerico AS VARCHAR(50))
        WHEN ValorData IS NOT NULL THEN FORMAT(ValorData, 'yyyy-MM-dd HH:mm:ss')
        WHEN ValorBooleano IS NOT NULL THEN CASE WHEN ValorBooleano = 1 THEN 'Sim' ELSE 'Não' END
        ELSE 'NULL'
    END AS Valor,
    SkTempo,
    DataProcessamento,
    ROW_NUMBER() OVER (PARTITION BY CodigoCliente, NomeMetrica ORDER BY SkTempo) AS VersaoSequencial
FROM DM_MetricasClientes.FatoMetricasClientes
WHERE CodigoCliente IN ('TESTE-01', 'TESTE-02')
ORDER BY CodigoCliente, NomeMetrica, SkTempo;
GO

-- =============================================
-- CENÁRIO 4: MÚLTIPLAS ALTERAÇÕES SEQUENCIAIS
-- =============================================

PRINT '';
PRINT '5. CENÁRIO 4: MÚLTIPLAS ALTERAÇÕES SEQUENCIAIS';
PRINT '==============================================';
GO

-- Simular várias alterações ao longo do tempo
DECLARE @DataTeste DATE = '2024-01-03';
DECLARE @Contador INT = 1;

WHILE @Contador <= 5
BEGIN
    -- Limpar staging
    DELETE FROM Staging.MetricasClientes WHERE Cliente = 'TESTE-01';
    
    -- Inserir dados com valores incrementais
    INSERT INTO Staging.MetricasClientes 
    (Cliente, CodSistema, Ordem, NomeMetrica, TipoRetorno, TabelaConsultada, Valor, DataCarga, DataProcessamento)
    VALUES
    ('TESTE-01', 1, 1, 'QtdRegistrosSistema', 'DECIMAL', 'Registros', 
     CAST(150 + (@Contador * 10) AS VARCHAR(10)), -- 160, 170, 180, 190, 200
     DATEADD(DAY, @Contador - 1, @DataTeste), NULL);
    
    -- Executar carga
    EXEC DM_MetricasClientes.uspLoadFatoMetricasClientes 
         @DataProcessamento = DATEADD(DAY, @Contador - 1, CAST(@DataTeste AS DATETIME2));
    
    SET @Contador = @Contador + 1;
END

PRINT 'Múltiplas alterações sequenciais executadas.';
GO

-- Verificar evolução temporal
PRINT 'Verificando evolução temporal:';
SELECT 
    'EVOLUCAO_TEMPORAL' AS Cenario,
    CodigoCliente,
    NomeMetrica,
    ValorNumerico,
    SkTempo,
    LAG(ValorNumerico) OVER (ORDER BY SkTempo) AS ValorAnterior,
    ValorNumerico - LAG(ValorNumerico) OVER (ORDER BY SkTempo) AS Variacao,
    ROW_NUMBER() OVER (ORDER BY SkTempo) AS Sequencia
FROM DM_MetricasClientes.FatoMetricasClientes
WHERE CodigoCliente = 'TESTE-01' 
  AND NomeMetrica = 'QtdRegistrosSistema'
ORDER BY SkTempo;
GO

-- =============================================
-- CENÁRIO 5: TESTE DAS VIEWS
-- =============================================

PRINT '';
PRINT '6. CENÁRIO 5: TESTE DAS VIEWS';
PRINT '==============================';
GO

-- Teste da view de valores atuais
PRINT 'Testando VwMetricasAtuais:';
SELECT 
    'VIEW_ATUAIS' AS Cenario,
    SiglaCliente,
    NomeMetrica,
    ValorFormatado,
    DataUltimaAlteracao
FROM DM_MetricasClientes.VwMetricasAtuais
WHERE SiglaCliente IN ('TESTE-01', 'TESTE-02')
ORDER BY SiglaCliente, NomeMetrica;
GO

-- Teste da view de histórico
PRINT 'Testando VwMetricasHistorico (últimas 10 alterações):';
SELECT TOP 10
    'VIEW_HISTORICO' AS Cenario,
    SiglaCliente,
    NomeMetrica,
    CASE 
        WHEN ValorTexto IS NOT NULL THEN ValorTexto
        WHEN ValorNumerico IS NOT NULL THEN CAST(ValorNumerico AS VARCHAR(50))
        WHEN ValorData IS NOT NULL THEN FORMAT(ValorData, 'yyyy-MM-dd HH:mm:ss')
        WHEN ValorBooleano IS NOT NULL THEN CASE WHEN ValorBooleano = 1 THEN 'Sim' ELSE 'Não' END
        ELSE 'NULL'
    END AS ValorAtual,
    CASE 
        WHEN ValorTextoAnterior IS NOT NULL THEN ValorTextoAnterior
        WHEN ValorNumericoAnterior IS NOT NULL THEN CAST(ValorNumericoAnterior AS VARCHAR(50))
        WHEN ValorDataAnterior IS NOT NULL THEN FORMAT(ValorDataAnterior, 'yyyy-MM-dd HH:mm:ss')
        WHEN ValorBooleanoAnterior IS NOT NULL THEN CASE WHEN ValorBooleanoAnterior = 1 THEN 'Sim' ELSE 'Não' END
        ELSE 'NULL'
    END AS ValorAnterior,
    TipoMovimento,
    VariacaoNumerica,
    SkTempo
FROM DM_MetricasClientes.VwMetricasHistorico
WHERE SiglaCliente IN ('TESTE-01', 'TESTE-02')
ORDER BY SkTempo DESC;
GO

-- Teste da view de resumo de atividade
PRINT 'Testando VwResumoAtividadeMetricas:';
SELECT 
    'VIEW_RESUMO' AS Cenario,
    NomeMetrica,
    TotalSnapshots,
    TotalClientes,
    PrimeiroSnapshot,
    UltimoSnapshot,
    MediaSnapshotsPorDia,
    MediaValorNumerico,
    MinValorNumerico,
    MaxValorNumerico
FROM DM_MetricasClientes.VwResumoAtividadeMetricas
WHERE TotalClientes > 0
ORDER BY TotalSnapshots DESC;
GO

-- =============================================
-- CENÁRIO 6: TESTE DE PERFORMANCE
-- =============================================

PRINT '';
PRINT '7. CENÁRIO 6: TESTE DE PERFORMANCE';
PRINT '==================================';
GO

-- Inserir volume maior de dados para teste
PRINT 'Inserindo dados para teste de performance...';

DECLARE @ClienteTeste VARCHAR(10);
DECLARE @ContadorCliente INT = 1;
DECLARE @ContadorMetrica INT;
DECLARE @DataPerformance DATETIME2 = '2024-01-10 08:00:00';

-- Criar 10 clientes de teste com 5 métricas cada
WHILE @ContadorCliente <= 10
BEGIN
    SET @ClienteTeste = CONCAT('PERF-', FORMAT(@ContadorCliente, '00'));
    SET @ContadorMetrica = 1;
    
    WHILE @ContadorMetrica <= 5
    BEGIN
        INSERT INTO Staging.MetricasClientes 
        (Cliente, CodSistema, Ordem, NomeMetrica, TipoRetorno, TabelaConsultada, Valor, DataCarga, DataProcessamento)
        VALUES
        (@ClienteTeste, 1, @ContadorMetrica, 
         CONCAT('Metrica', @ContadorMetrica), 'DECIMAL', 'TestTable', 
         CAST(RAND() * 1000 AS VARCHAR(10)), @DataPerformance, NULL);
        
        SET @ContadorMetrica = @ContadorMetrica + 1;
    END
    
    SET @ContadorCliente = @ContadorCliente + 1;
END

PRINT 'Dados de performance inseridos na staging.';
GO

-- Medir tempo de execução
DECLARE @InicioPerformance DATETIME2 = GETDATE();

EXEC DM_MetricasClientes.uspLoadFatoMetricasClientes @DataProcessamento = '2024-01-10 08:00:00';

DECLARE @FimPerformance DATETIME2 = GETDATE();
DECLARE @TempoExecucao INT = DATEDIFF(MILLISECOND, @InicioPerformance, @FimPerformance);

PRINT CONCAT('Tempo de execução para 50 registros: ', @TempoExecucao, ' ms');
GO

-- =============================================
-- CENÁRIO 7: VALIDAÇÕES DE INTEGRIDADE
-- =============================================

PRINT '';
PRINT '8. CENÁRIO 7: VALIDAÇÕES DE INTEGRIDADE';
PRINT '========================================';
GO

-- Verificar se não há duplicatas para a mesma data
PRINT 'Verificando duplicatas por data:';
SELECT 
    'VALIDACAO_DUPLICATAS' AS Cenario,
    CodigoCliente,
    NomeMetrica,
    SkTempo,
    COUNT(*) AS Ocorrencias
FROM DM_MetricasClientes.FatoMetricasClientes
WHERE CodigoCliente LIKE 'TESTE%' OR CodigoCliente LIKE 'PERF%'
GROUP BY CodigoCliente, NomeMetrica, SkTempo
HAVING COUNT(*) > 1;
GO

-- Verificar consistência de tipos de dados
PRINT 'Verificando consistência de tipos:';
SELECT 
    'VALIDACAO_TIPOS' AS Cenario,
    met.TipoRetorno,
    COUNT(CASE WHEN f.ValorTexto IS NOT NULL THEN 1 END) AS TemTexto,
    COUNT(CASE WHEN f.ValorNumerico IS NOT NULL THEN 1 END) AS TemNumerico,
    COUNT(CASE WHEN f.ValorData IS NOT NULL THEN 1 END) AS TemData,
    COUNT(CASE WHEN f.ValorBooleano IS NOT NULL THEN 1 END) AS TemBooleano,
    COUNT(*) AS Total
FROM DM_MetricasClientes.FatoMetricasClientes f
INNER JOIN DM_MetricasClientes.DimMetricas met ON met.SkMetrica = f.SkMetrica
WHERE f.CodigoCliente LIKE 'TESTE%'
GROUP BY met.TipoRetorno;
GO

-- Verificar se todas as chaves estrangeiras são válidas
PRINT 'Verificando integridade referencial:';
SELECT 
    'VALIDACAO_FK' AS Cenario,
    'Clientes sem FK válida' AS Tipo,
    COUNT(*) AS Quantidade
FROM DM_MetricasClientes.FatoMetricasClientes f
LEFT JOIN Shared.DimClientes cli ON cli.SkCliente = f.SkCliente
WHERE f.CodigoCliente LIKE 'TESTE%' AND cli.SkCliente IS NULL

UNION ALL

SELECT 
    'VALIDACAO_FK' AS Cenario,
    'Métricas sem FK válida' AS Tipo,
    COUNT(*) AS Quantidade
FROM DM_MetricasClientes.FatoMetricasClientes f
LEFT JOIN DM_MetricasClientes.DimMetricas met ON met.SkMetrica = f.SkMetrica
WHERE f.CodigoCliente LIKE 'TESTE%' AND met.SkMetrica IS NULL;
GO

-- =============================================
-- LIMPEZA DOS DADOS DE TESTE
-- =============================================

PRINT '';
PRINT '9. LIMPEZA DOS DADOS DE TESTE';
PRINT '==============================';
GO

-- Remover dados de teste
DELETE FROM DM_MetricasClientes.FatoMetricasClientes 
WHERE CodigoCliente LIKE 'TESTE%' OR CodigoCliente LIKE 'PERF%';

DELETE FROM Staging.MetricasClientes 
WHERE Cliente LIKE 'TESTE%' OR Cliente LIKE 'PERF%';

PRINT 'Dados de teste removidos.';
GO

-- =============================================
-- RELATÓRIO FINAL DOS TESTES
-- =============================================

PRINT '';
PRINT '=========================================';
PRINT 'RELATÓRIO FINAL DOS TESTES';
PRINT '=========================================';
PRINT 'Todos os cenários de teste foram executados:';
PRINT '';
PRINT '✓ Cenário 1: Inserção de novos registros';
PRINT '✓ Cenário 2: Reprocessamento sem alterações';
PRINT '✓ Cenário 3: Alterações reais de valores';
PRINT '✓ Cenário 4: Múltiplas alterações sequenciais';
PRINT '✓ Cenário 5: Teste das views';
PRINT '✓ Cenário 6: Teste de performance';
PRINT '✓ Cenário 7: Validações de integridade';
PRINT '';
PRINT 'Funcionalidades testadas:';
PRINT '• Detecção automática de alterações';
PRINT '• Inserção apenas de valores modificados';
PRINT '• Histórico completo de mudanças';
PRINT '• Conversão automática de tipos';
PRINT '• Views de consulta otimizadas';
PRINT '• Integridade referencial';
PRINT '• Performance com volumes maiores';
PRINT '';
PRINT CONCAT('Fim dos testes: ', FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss'));
PRINT '=========================================';
GO