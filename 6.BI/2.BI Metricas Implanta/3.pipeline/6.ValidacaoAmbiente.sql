-- =============================================
-- Script: ValidacaoAmbiente.sql
-- Descrição: Validação do ambiente e procedures criadas
-- Autor: Sistema
-- Data: 2024
-- =============================================

SET NOCOUNT ON;

PRINT '=============================================';
PRINT 'VALIDAÇÃO DO AMBIENTE - DATA WAREHOUSE MÉTRICAS';
PRINT CONCAT('Data/Hora: ', FORMAT(GETDATE(), 'dd/MM/yyyy HH:mm:ss'));
PRINT '=============================================';
PRINT '';

-- =============================================
-- 1. VALIDAÇÃO DE SCHEMAS
-- =============================================
PRINT '--- 1. VALIDAÇÃO DE SCHEMAS ---';

DECLARE @SchemasTable TABLE (
    SchemaName NVARCHAR(128),
    Existe BIT,
    Tipo NVARCHAR(50)
);

INSERT INTO @SchemasTable (SchemaName, Tipo)
VALUES 
    ('Shared', 'Compartilhado'),
    ('DM_MetricasClientes', 'Específico'),
    ('Staging', 'Staging');

UPDATE @SchemasTable 
SET Existe = CASE WHEN EXISTS (
    SELECT 1 FROM sys.schemas WHERE name = SchemaName
) THEN 1 ELSE 0 END;

SELECT 
    SchemaName as 'Schema',
    Tipo,
    CASE WHEN Existe = 1 THEN '✓ OK' ELSE '✗ AUSENTE' END as Status
FROM @SchemasTable
ORDER BY Tipo, SchemaName;

IF EXISTS (SELECT 1 FROM @SchemasTable WHERE Existe = 0)
    PRINT 'ATENÇÃO: Alguns schemas estão ausentes!';
ELSE
    PRINT 'Todos os schemas necessários estão presentes.';

PRINT '';

-- =============================================
-- 2. VALIDAÇÃO DE TABELAS
-- =============================================
PRINT '--- 2. VALIDAÇÃO DE TABELAS ---';

DECLARE @TabelasTable TABLE (
    SchemaName NVARCHAR(128),
    TableName NVARCHAR(128),
    Existe BIT,
    Tipo NVARCHAR(50)
);

INSERT INTO @TabelasTable (SchemaName, TableName, Tipo)
VALUES 
    -- Tabelas compartilhadas
    ('Shared', 'DimClientes', 'Compartilhada'),
    ('Shared', 'DimProdutos', 'Compartilhada'),
    ('Shared', 'DimTempo', 'Compartilhada'),
    ('Shared', 'DimConselhosFederais', 'Compartilhada'),
    ('Shared', 'DimCategorias', 'Compartilhada'),
    ('Shared', 'DimGeografia', 'Compartilhada'),
    
    -- Tabelas específicas do projeto
    ('DM_MetricasClientes', 'DimMetricas', 'Específica'),
    ('DM_MetricasClientes', 'DimTipoRetorno', 'Específica'),
    ('DM_MetricasClientes', 'FatoMetricasClientes', 'Fato'),
    
    -- Staging
    ('Staging', 'MetricasClientes', 'Staging');

UPDATE @TabelasTable 
SET Existe = CASE WHEN EXISTS (
    SELECT 1 
    FROM sys.tables t 
    INNER JOIN sys.schemas s ON t.schema_id = s.schema_id 
    WHERE s.name = SchemaName AND t.name = TableName
) THEN 1 ELSE 0 END;

SELECT 
    CONCAT(SchemaName, '.', TableName) as 'Tabela',
    Tipo,
    CASE WHEN Existe = 1 THEN '✓ OK' ELSE '✗ AUSENTE' END as Status
FROM @TabelasTable
ORDER BY Tipo, SchemaName, TableName;

-- Contadores por tipo
SELECT 
    Tipo,
    COUNT(*) as Total,
    SUM(CASE WHEN Existe = 1 THEN 1 ELSE 0 END) as Existentes,
    SUM(CASE WHEN Existe = 0 THEN 1 ELSE 0 END) as Ausentes
FROM @TabelasTable
GROUP BY Tipo
ORDER BY Tipo;

PRINT '';

-- =============================================
-- 3. VALIDAÇÃO DE PROCEDURES
-- =============================================
PRINT '--- 3. VALIDAÇÃO DE PROCEDURES ---';

DECLARE @ProceduresTable TABLE (
    SchemaName NVARCHAR(128),
    ProcedureName NVARCHAR(128),
    Existe BIT,
    Descricao NVARCHAR(255)
);

INSERT INTO @ProceduresTable (SchemaName, ProcedureName, Descricao)
VALUES 
    ('DM_MetricasClientes', 'uspLoadDimMetricas', 'Carga da dimensão DimMetricas (SCD Tipo 2)'),
    ('DM_MetricasClientes', 'uspLoadDimTipoRetorno', 'Carga da dimensão DimTipoRetorno'),
    ('DM_MetricasClientes', 'uspLoadFatoMetricasClientes', 'Carga da tabela fato principal'),
    ('DM_MetricasClientes', 'uspOrquestracaoETL', 'Orquestração do processo ETL completo'),
    ('DM_MetricasClientes', 'uspInicializarDimensoes', 'Inicialização com dados padrão');

UPDATE @ProceduresTable 
SET Existe = CASE WHEN EXISTS (
    SELECT 1 
    FROM sys.procedures p 
    INNER JOIN sys.schemas s ON p.schema_id = s.schema_id 
    WHERE s.name = SchemaName AND p.name = ProcedureName
) THEN 1 ELSE 0 END;

SELECT 
    CONCAT(SchemaName, '.', ProcedureName) as 'Procedure',
    Descricao,
    CASE WHEN Existe = 1 THEN '✓ OK' ELSE '✗ AUSENTE' END as Status
FROM @ProceduresTable
ORDER BY ProcedureName;

DECLARE @ProceduresOK INT = (SELECT COUNT(*) FROM @ProceduresTable WHERE Existe = 1);
DECLARE @ProceduresTotal INT = (SELECT COUNT(*) FROM @ProceduresTable);

PRINT CONCAT('Procedures criadas: ', @ProceduresOK, ' de ', @ProceduresTotal);

PRINT '';

-- =============================================
-- 4. VALIDAÇÃO DE DADOS NAS DIMENSÕES COMPARTILHADAS
-- =============================================
PRINT '--- 4. VALIDAÇÃO DE DADOS NAS DIMENSÕES COMPARTILHADAS ---';

IF EXISTS (SELECT 1 FROM @TabelasTable WHERE SchemaName = 'Shared' AND TableName = 'DimClientes' AND Existe = 1)
BEGIN
    DECLARE @QtdClientes INT;
    SELECT @QtdClientes = COUNT(*) FROM [Shared].[DimClientes] WHERE VersaoAtual = 1;
    PRINT CONCAT('DimClientes: ', @QtdClientes, ' registros ativos');
END
ELSE
    PRINT 'DimClientes: Tabela não encontrada';

IF EXISTS (SELECT 1 FROM @TabelasTable WHERE SchemaName = 'Shared' AND TableName = 'DimProdutos' AND Existe = 1)
BEGIN
    DECLARE @QtdProdutos INT;
    SELECT @QtdProdutos = COUNT(*) FROM [Shared].[DimProdutos] WHERE VersaoAtual = 1;
    PRINT CONCAT('DimProdutos: ', @QtdProdutos, ' registros ativos');
END
ELSE
    PRINT 'DimProdutos: Tabela não encontrada';

IF EXISTS (SELECT 1 FROM @TabelasTable WHERE SchemaName = 'Shared' AND TableName = 'DimTempo' AND Existe = 1)
BEGIN
    DECLARE @QtdTempo INT;
    SELECT @QtdTempo = COUNT(*) FROM [Shared].[DimTempo];
    PRINT CONCAT('DimTempo: ', @QtdTempo, ' registros');
END
ELSE
    PRINT 'DimTempo: Tabela não encontrada';

PRINT '';

-- =============================================
-- 5. VALIDAÇÃO DE DADOS NO STAGING
-- =============================================
PRINT '--- 5. VALIDAÇÃO DE DADOS NO STAGING ---';

IF EXISTS (SELECT 1 FROM @TabelasTable WHERE SchemaName = 'Staging' AND TableName = 'MetricasClientes' AND Existe = 1)
BEGIN
    DECLARE @QtdStaging INT, @ClientesUnicos INT, @MetricasUnicas INT;
    
    SELECT 
        @QtdStaging = COUNT(*),
        @ClientesUnicos = COUNT(DISTINCT Cliente),
        @MetricasUnicas = COUNT(DISTINCT NomeMetrica)
    FROM [Staging].[MetricasClientes];
    
    PRINT CONCAT('Staging.MetricasClientes: ', @QtdStaging, ' registros');
    PRINT CONCAT('  - Clientes únicos: ', @ClientesUnicos);
    PRINT CONCAT('  - Métricas únicas: ', @MetricasUnicas);
    
    IF @QtdStaging = 0
        PRINT '  AVISO: Staging está vazio. Execute a carga do staging antes do ETL.';
END
ELSE
    PRINT 'Staging.MetricasClientes: Tabela não encontrada';

PRINT '';

-- =============================================
-- 6. VALIDAÇÃO DE PERMISSÕES
-- =============================================
PRINT '--- 6. VALIDAÇÃO DE PERMISSÕES ---';

IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'db_executor')
    PRINT 'Role db_executor: ✓ Existe'
ELSE
    PRINT 'Role db_executor: ✗ Não encontrada';

-- Verificar permissões das procedures
SELECT 
    CONCAT(s.name, '.', p.name) as 'Procedure',
    CASE WHEN EXISTS (
        SELECT 1 
        FROM sys.database_permissions dp
        INNER JOIN sys.database_principals pr ON dp.grantee_principal_id = pr.principal_id
        WHERE dp.major_id = p.object_id 
          AND pr.name = 'db_executor'
          AND dp.permission_name = 'EXECUTE'
    ) THEN '✓ OK' ELSE '✗ SEM PERMISSÃO' END as 'Permissão db_executor'
FROM sys.procedures p
INNER JOIN sys.schemas s ON p.schema_id = s.schema_id
WHERE s.name = 'DM_MetricasClientes'
ORDER BY p.name;

PRINT '';

-- =============================================
-- 7. RESUMO FINAL
-- =============================================
PRINT '--- 7. RESUMO FINAL ---';

DECLARE @SchemasOK INT = (SELECT COUNT(*) FROM @SchemasTable WHERE Existe = 1);
DECLARE @SchemasTotal INT = (SELECT COUNT(*) FROM @SchemasTable);

DECLARE @TabelasOK INT = (SELECT COUNT(*) FROM @TabelasTable WHERE Existe = 1);
DECLARE @TabelasTotal INT = (SELECT COUNT(*) FROM @TabelasTable);

PRINT CONCAT('Schemas: ', @SchemasOK, '/', @SchemasTotal, ' OK');
PRINT CONCAT('Tabelas: ', @TabelasOK, '/', @TabelasTotal, ' OK');
PRINT CONCAT('Procedures: ', @ProceduresOK, '/', @ProceduresTotal, ' OK');

-- Status geral
IF @SchemasOK = @SchemasTotal AND @TabelasOK = @TabelasTotal AND @ProceduresOK = @ProceduresTotal
BEGIN
    PRINT '';
    PRINT '🎉 AMBIENTE VALIDADO COM SUCESSO!';
    PRINT 'O Data Warehouse de Métricas está pronto para uso.';
    PRINT '';
    PRINT 'Próximos passos:';
    PRINT '1. Execute: EXEC [DM_MetricasClientes].[uspInicializarDimensoes];';
    PRINT '2. Carregue dados no Staging.MetricasClientes';
    PRINT '3. Execute: EXEC [DM_MetricasClientes].[uspOrquestracaoETL];';
END
ELSE
BEGIN
    PRINT '';
    PRINT '⚠️  AMBIENTE INCOMPLETO!';
    PRINT 'Alguns componentes estão ausentes. Verifique os detalhes acima.';
    PRINT '';
    PRINT 'Ações recomendadas:';
    IF @SchemasOK < @SchemasTotal
        PRINT '- Criar schemas ausentes';
    IF @TabelasOK < @TabelasTotal
        PRINT '- Executar script bancoDados.sql';
    IF @ProceduresOK < @ProceduresTotal
        PRINT '- Executar scripts das procedures';
END

PRINT '';
PRINT '=============================================';
PRINT 'FIM DA VALIDAÇÃO';
PRINT '=============================================';

-- =============================================
-- 8. COMANDOS ÚTEIS PARA TESTE
-- =============================================
PRINT '';
PRINT '--- COMANDOS ÚTEIS PARA TESTE ---';
PRINT '';
PRINT '-- Inicializar dimensões:';
PRINT 'EXEC [DM_MetricasClientes].[uspInicializarDimensoes];';
PRINT '';
PRINT '-- Executar ETL completo:';
PRINT 'EXEC [DM_MetricasClientes].[uspOrquestracaoETL];';
PRINT '';
PRINT '-- Verificar resultados:';
PRINT 'SELECT COUNT(*) FROM [DM_MetricasClientes].[DimMetricas] WHERE VersaoAtual = 1;';
PRINT 'SELECT COUNT(*) FROM [DM_MetricasClientes].[DimTipoRetorno] WHERE Ativo = 1;';
PRINT 'SELECT COUNT(*) FROM [DM_MetricasClientes].[FatoMetricasClientes];';
PRINT '';

SET NOCOUNT OFF;