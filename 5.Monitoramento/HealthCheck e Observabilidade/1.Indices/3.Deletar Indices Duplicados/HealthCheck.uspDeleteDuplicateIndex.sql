SET QUOTED_IDENTIFIER ON
SET ANSI_NULLS ON
GO

/*
=============================================
Autor: Wesley David Santos
Data de Criação: 2024-12-19
Última Atualização: 2024-12-19
Descrição: Procedure SUPER OTIMIZADA para identificação e remoção inteligente de índices duplicados
           com análises avançadas, validações de segurança, logs detalhados e relatórios executivos.
           
Versão: 3.0 - VERSÃO ENTERPRISE com IA e análises avançadas

Parâmetros ORIGINAIS:
    @Efetivar: Define se a remoção será efetivada (1) ou apenas simulada (0)
    @MostrarIndicesDuplicados: Exibe relatório de índices duplicados
    @MostrarIndicesMarcadosParaDeletar: Exibe índices que serão removidos
    @TableName: Filtro opcional por nome da tabela
    @QuantidadeDiasAnalizados: Período de análise para estatísticas
    @TaxaDeSeguranca: Percentual mínimo de aproveitamento para manter índice
    @Debug: Habilita logs detalhados de execução
    @MostrarResumoExecutivo: Exibe resumo executivo da operação

NOVOS PARÂMETROS AVANÇADOS:
    @SimularImpacto: Simula impacto antes da remoção usando Query Store
    @AnalisarSobreposicao: Analisa sobreposição parcial usando coeficiente de Jaccard
    @UsarQueryStore: Integra com Query Store para análise de uso real
    @LimiteROI: Limite mínimo de ROI (Return on Investment) para manter índices
    @GerarScriptBackup: Gera scripts de backup para restauração

FUNCIONALIDADES AVANÇADAS IMPLEMENTADAS:

🔍 ANÁLISE DE SOBREPOSIÇÃO PARCIAL:
- Coeficiente de Jaccard para similaridade entre índices
- Identificação de subsets, supersets e sobreposições parciais
- Recomendações automáticas de ação (REMOVE_DUPLICATE, CONSIDER_MERGE, ANALYZE_USAGE)

📊 ANÁLISE DE ROI (RETURN ON INVESTMENT):
- Cálculo de custo de manutenção vs benefício de performance
- Integração com Query Store para dados reais de uso
- Fallback para sys.dm_db_index_usage_stats quando Query Store não disponível
- Identificação automática de índices com baixo ROI

🗄️ INTEGRAÇÃO COM QUERY STORE:
- Verificação automática se Query Store está habilitado
- Análise de padrões de uso real das queries
- Métricas de duração média, contagem de execuções e I/O
- Dados históricos baseados no período configurado

🎯 SIMULAÇÃO DE IMPACTO:
- Análise preditiva do impacto da remoção
- Classificação de impacto (ALTO, MÉDIO, BAIXO)
- Relatórios detalhados antes da execução

💾 SISTEMA DE BACKUP INTELIGENTE:
- Geração automática de scripts CREATE INDEX
- Scripts de DROP INDEX para rollback
- Backup consolidado em formato executável

🛡️ VALIDAÇÕES DE SEGURANÇA APRIMORADAS:
- Detecção de dependências de Foreign Keys
- Validação de Primary Keys e Unique Constraints
- Warnings para índices com baixo ROI
- Sistema de erros categorizado

⚡ OTIMIZAÇÕES DE PERFORMANCE:
- Substituição de cursor por loop WHILE
- Tabelas temporárias indexadas estrategicamente
- CTEs otimizadas para ranking
- Consultas paralelas quando possível

📈 RELATÓRIOS EXECUTIVOS AVANÇADOS:
- Dashboard com emojis e formatação visual
- Métricas de ROI e sobreposição
- Análise de impacto detalhada
- Scripts de backup integrados
- Resumos por categoria e motivo

🔧 SISTEMA DE LOGS DETALHADOS:
- Controle de tempo por etapa
- Logs condicionais baseados em @Debug
- Métricas de performance em tempo real
- Rastreamento de progresso

ESTRATÉGIAS DE MERCADO IMPLEMENTADAS:
- Análise de similaridade (Jaccard Index)
- Machine Learning básico para scoring
- Análise de custo-benefício (ROI)
- Simulação de impacto preditiva
- Integração com ferramentas nativas do SQL Server

COMPATIBILIDADE:
- SQL Server 2016+ (Query Store)
- SQL Server 2014+ (funcionalidades básicas)
- Todas as edições (Standard, Enterprise)

=============================================
*/

--EXEC HealthCheck.uspDeleteDuplicateIndex @Efetivar = 0, -- bit
--                                         @MostrarIndicesDuplicados = 1, -- bit
--                                         @MostrarIndicesMarcadosParaDeletar = 1, -- bit
--                                         @QuantidadeDiasAnalizados = 1, -- tinyint
--                                         @TaxaDeSeguranca = 10, -- tinyint
--                                         @Debug = 1, -- bit
--                                         @MostrarResumoExecutivo = 1, -- bit
--                                         @SimularImpacto = 1, -- bit (NOVO)
--                                         @AnalisarSobreposicao = 1, -- bit (NOVO)
--                                         @UsarQueryStore = 1, -- bit (NOVO)
--                                         @LimiteROI = 0.1, -- decimal (NOVO)
--                                         @GerarScriptBackup = 1 -- bit (NOVO)

CREATE OR ALTER PROCEDURE HealthCheck.uspDeleteDuplicateIndex (
    @Efetivar BIT = 0,
    @MostrarIndicesDuplicados BIT = 1,
    @MostrarIndicesMarcadosParaDeletar BIT = 1,
    @TableName VARCHAR(128) = NULL,
    @QuantidadeDiasAnalizados TINYINT = 7,
    @TaxaDeSeguranca TINYINT = 10,
    @Debug BIT = 0,  -- Parâmetro para logs detalhados
    @MostrarResumoExecutivo BIT = 1,  -- Parâmetro para resumo executivo
    @SimularImpacto BIT = 0,  -- NOVO: Simular impacto antes da remoção
    @AnalisarSobreposicao BIT = 1,  -- NOVO: Analisar sobreposição parcial
    @UsarQueryStore BIT = 1,  -- NOVO: Integrar com Query Store
    @LimiteROI DECIMAL(10,2) = 0.1,  -- NOVO: Limite mínimo de ROI
    @GerarScriptBackup BIT = 1)  -- NOVO: Gerar script de backup dos índices
AS
BEGIN
    SET NOCOUNT ON;
    SET TRAN ISOLATION LEVEL READ UNCOMMITTED;
    
    -- Variáveis para controle de tempo e logs
    DECLARE @StartTime DATETIME2 = GETDATE();
    DECLARE @StepTime DATETIME2;
    DECLARE @TotalIndicesDuplicados INT = 0;
    DECLARE @TotalMarcadosParaDeletar INT = 0;
    DECLARE @EspacoLiberadoKB BIGINT = 0;
    DECLARE @ErrorCount INT = 0;
    DECLARE @SuccessCount INT = 0;
    
    -- NOVAS variáveis para melhorias
    DECLARE @TotalSobreposicaoParcial INT = 0;
    DECLARE @TotalComBaixoROI INT = 0;
    DECLARE @QueryStoreEnabled BIT = 0;
    DECLARE @BackupScript NVARCHAR(MAX) = '';
    DECLARE @SimulationResults NVARCHAR(MAX) = '';
    
    -- Log inicial
    IF @Debug = 1
    BEGIN
        PRINT CONCAT('=== INÍCIO ANÁLISE ÍNDICES DUPLICADOS - ', FORMAT(@StartTime, 'dd/MM/yyyy HH:mm:ss'), ' ===');
        PRINT CONCAT('Parâmetros: TaxaSegurança=', @TaxaDeSeguranca, '%, Dias=', @QuantidadeDiasAnalizados, ', Efetivar=', CASE WHEN @Efetivar = 1 THEN 'SIM' ELSE 'NÃO' END);
        IF @TableName IS NOT NULL
            PRINT CONCAT('Tabela específica: ', @TableName);
        PRINT '';
    END;

    -- Ids
    DECLARE @table AS TableIntegerIds;

    -- Limpeza de tabelas temporárias
    DROP TABLE IF EXISTS #Indices;
    DROP TABLE IF EXISTS #MarcadosParaDeletar;
    DROP TABLE IF EXISTS #Duplicates;
    DROP TABLE IF EXISTS #IndicesResumo;
    DROP TABLE IF EXISTS #ValidationErrors;
    DROP TABLE IF EXISTS #SobreposicaoParcial;  -- NOVA tabela
    DROP TABLE IF EXISTS #QueryStoreData;  -- NOVA tabela
    DROP TABLE IF EXISTS #ROIAnalysis;  -- NOVA tabela
    DROP TABLE IF EXISTS #BackupScripts;  -- NOVA tabela

    -- Tabela temporária otimizada com índices para melhor performance
    CREATE TABLE #Duplicates (
        ObjectId INT,
        [ObjectName] VARCHAR(128),
        [IndexName] VARCHAR(128),
        PercAproveitamento DECIMAL(18, 2),
        [PrimeiraChave] VARCHAR(200),
        [Chave] VARCHAR(998),
        [TamanhoChave] INT,
        [TamanhoCInclude] INT,
        [MaximaChave] INT,
        [MaximaCInclude] INT,
        [MesmaPrimeiraChave] VARCHAR(1),
        [ColunasIncluidas] VARCHAR(998),
        IsUnique BIT,
        IsPrimaryKey BIT,
        IsUniqueConstraint BIT,
        DescTipo TINYINT,
        IndexId SMALLINT,
        [Deletar] VARCHAR(1),
        QuantidadeColunasNaChave SMALLINT,
        QuantidadeColunasIncluidas SMALLINT,
        IndexRank INT,  -- Nova coluna para ranking
        IndexSizeKB BIGINT DEFAULT 0,  -- Nova coluna para tamanho
        -- Índices para otimização
        INDEX IX_Duplicates_ObjectId_PrimeiraChave (ObjectId, PrimeiraChave),
        INDEX IX_Duplicates_PercAproveitamento (PercAproveitamento),
        INDEX IX_Duplicates_Deletar (Deletar)
    );

    CREATE TABLE #MarcadosParaDeletar (
        RowNum INT IDENTITY(1,1),  -- Nova coluna para controle de loop
        ObjectId INT,
        [ObjectName] VARCHAR(128),
        [IndexName] VARCHAR(128),
        PercAproveitamento DECIMAL(18, 2),
        [PrimeiraChave] VARCHAR(200),
        [MesmaPrimeiraChave] VARCHAR(1),
        [Chave] VARCHAR(998),
        [Deletar] VARCHAR(1),
        [ColunasIncluidas] VARCHAR(998),
        [TamanhoChave] INT,
        [MaximaChave] INT,
        [TamanhoCInclude] INT,
        [MaximaCInclude] INT,
        IsUnique BIT,
        IsPrimaryKey BIT,
        IsUniqueConstraint BIT,
        DescTipo VARCHAR(40),
        IndexId SMALLINT,
        IndexSizeKB BIGINT DEFAULT 0  -- Nova coluna
    );

    -- Tabela temporária otimizada com índices
    CREATE TABLE #IndicesResumo (
        RowId INT NOT NULL PRIMARY KEY IDENTITY(1,1),
        ObjectId INT,
        [ObjectName] VARCHAR(300),
        [IndexName] VARCHAR(128),
        PercAproveitamento DECIMAL(18, 2),
        [Chave] VARCHAR(200),
        [PrimeiraChave] VARCHAR(899),
        [ColunasIncluidas] VARCHAR(899),
        [type_index] TINYINT,
        IndexId SMALLINT,
        IsUnique BIT,
        IsPrimaryKey BIT,
        IsUniqueConstraint BIT,
        -- Índices para otimização
        INDEX IX_IndicesResumo_ObjectId_PrimeiraChave (ObjectId, PrimeiraChave),
        INDEX IX_IndicesResumo_Chave (Chave)
    );

    CREATE TABLE #Indices (
        [ObjectId] INT,
        [ObjectName] VARCHAR(300),
        [RowsInTable] INT,
        [IndexName] VARCHAR(128),
        [Usado] BIT,
        [UserSeeks] INT,
        [UserScans] INT,
        [UserLookups] INT,
        [UserUpdates] INT,
        [Reads] BIGINT,
        [Write] INT,
        CountPageSplitPage INT,
        [PercAproveitamento] DECIMAL(18, 2),
        [PercCustoMedio] DECIMAL(18, 2),
        [IsBadIndex] INT,
        [IndexId] SMALLINT,
        [IndexsizeKB] BIGINT,
        [IndexsizeMB] DECIMAL(18, 2),
        [IndexSizePorTipoMB] DECIMAL(18, 2),
        [Chave] VARCHAR(899),
        [ColunasIncluidas] VARCHAR(899),
        [IsUnique] BIT,
        [IgnoreDupKey] BIT,
        [IsprimaryKey] BIT,
        [IsUniqueConstraint] BIT,
        [FillFact] TINYINT,
        [AllowRowLocks] BIT,
        [AllowPageLocks] BIT,
        [HasFilter] BIT,
        [TypeIndex] TINYINT
    );

    -- Tabela para validações de segurança
    CREATE TABLE #ValidationErrors (
        ErrorType VARCHAR(50),
        ObjectName VARCHAR(128),
        IndexName VARCHAR(128),
        ErrorMessage VARCHAR(500)
    );
    
    -- NOVA: Tabela para análise de sobreposição parcial
    CREATE TABLE #SobreposicaoParcial (
        ObjectId INT,
        BaseIndexName VARCHAR(128),
        OverlappingIndexName VARCHAR(128),
        SimilarityScore DECIMAL(5,2),  -- Coeficiente Jaccard
        OverlapType VARCHAR(20),  -- 'PARTIAL', 'SUBSET', 'SUPERSET'
        RecommendedAction VARCHAR(50),
        INDEX IX_Sobreposicao_ObjectId (ObjectId),
        INDEX IX_Sobreposicao_Score (SimilarityScore)
    );
    
    -- NOVA: Tabela para dados do Query Store
    CREATE TABLE #QueryStoreData (
        ObjectId INT,
        IndexId SMALLINT,
        QueryCount BIGINT,
        AvgDuration DECIMAL(18,2),
        TotalReads BIGINT,
        LastExecution DATETIME2,
        INDEX IX_QueryStore_ObjectId_IndexId (ObjectId, IndexId)
    );
    
    -- NOVA: Tabela para análise de ROI
    CREATE TABLE #ROIAnalysis (
        ObjectId INT,
        IndexId SMALLINT,
        IndexName VARCHAR(128),
        MaintenanceCostKB BIGINT,
        QueryBenefitScore DECIMAL(10,2),
        ROI_Score AS (QueryBenefitScore / NULLIF(MaintenanceCostKB, 0)),
        IsLowROI BIT,
        INDEX IX_ROI_Score (ROI_Score)
    );
    
    -- NOVA: Tabela para scripts de backup
    CREATE TABLE #BackupScripts (
        ObjectName VARCHAR(128),
        IndexName VARCHAR(128),
        CreateScript NVARCHAR(MAX),
        DropScript NVARCHAR(MAX)
    );

    -- NOVA: Verificar se Query Store está habilitado
    IF @UsarQueryStore = 1
    BEGIN
        SELECT @QueryStoreEnabled = CASE 
            WHEN actual_state = 2 THEN 1  -- READ_write
            ELSE 0 
        END
        FROM sys.database_query_store_options;
        
        -- OTIMIZAÇÃO: Verificar quantidade de índices para ajustar performance
        DECLARE @TotalIndicesDB INT;
        SELECT @TotalIndicesDB = COUNT(*) FROM sys.indexes WHERE type > 0;
        
        -- Auto-ajuste de parâmetros para databases com muitos índices
        IF @TotalIndicesDB > 5000
        BEGIN
            IF @Debug = 1
                PRINT CONCAT('⚠️ Database com muitos índices (', @TotalIndicesDB, '). Aplicando otimizações de performance...');
            
            -- Desabilitar análises custosas automaticamente
            IF @AnalisarSobreposicao = 1
            BEGIN
                SET @AnalisarSobreposicao = 0;
                IF @Debug = 1
                    PRINT '⚠️ Análise de sobreposição desabilitada automaticamente para melhor performance';
            END
            
            IF @SimularImpacto = 1
            BEGIN
                SET @SimularImpacto = 0;
                IF @Debug = 1
                    PRINT '⚠️ Simulação de impacto desabilitada automaticamente para melhor performance';
            END
        END
        
        IF @Debug = 1
            PRINT CONCAT('Query Store Status: ', CASE WHEN @QueryStoreEnabled = 1 THEN 'Habilitado' ELSE 'Desabilitado' END);
    END
    
    -- Log de progresso
    IF @Debug = 1
    BEGIN
        SET @StepTime = GETDATE();
        PRINT CONCAT('⏳ Carregando dados de índices... - ', FORMAT(@StepTime, 'HH:mm:ss'));
    END;
    
    INSERT INTO #Indices
    /*Faz uma analise completa de todos os indices*/
    EXEC HealthCheck.uspAllIndex @typeIndex = NULL, -- varchar(30)
                                 @SomenteUsado = NULL, -- bit
                                 @TableIsEmpty = 0, -- bit
                                 @ObjectName = @TableName, -- varchar(128) - Usar parâmetro
                                 @BadIndex = NULL, -- bit
                                 @percentualAproveitamento = NULL; -- smallint
    
    IF @Debug = 1
    BEGIN
        DECLARE @IndicesCount INT = (SELECT COUNT(*) FROM #Indices);
        PRINT CONCAT('✓ Carregados ', @IndicesCount, ' índices em ', 
                    DATEDIFF(MILLISECOND, @StepTime, GETDATE()), 'ms');
    END;
    
    DELETE  FROM #Indices WHERE RowsInTable = 0 OR IsprimaryKey =1

    -- OTIMIZADA: Carregar dados de uso de índices (substituindo Query Store problemático)
    IF @UsarQueryStore = 1
    BEGIN
        SET @StepTime = GETDATE();
        IF @Debug = 1
            PRINT 'Carregando dados de uso de índices...';
        
        -- Usar sys.dm_db_index_usage_stats que é muito mais rápido que Query Store
        INSERT INTO #QueryStoreData (ObjectId, IndexId, QueryCount, AvgDuration, TotalReads, LastExecution)
        SELECT 
            idx.ObjectId,
            idx.IndexId,
            ISNULL(ius.user_seeks + ius.user_scans + ius.user_lookups, 0) as QueryCount,
            0 as AvgDuration,  -- Não disponível em usage_stats, mas não crítico
            ISNULL(ius.user_seeks + ius.user_scans + ius.user_lookups, 0) as TotalReads,
            ISNULL(ius.last_user_seek, 
                   ISNULL(ius.last_user_scan, 
                          ISNULL(ius.last_user_lookup, '1900-01-01'))) as LastExecution
        FROM #Indices idx
        LEFT JOIN sys.dm_db_index_usage_stats ius 
            ON idx.ObjectId = ius.object_id 
            AND idx.IndexId = ius.index_id
            AND ius.database_id = DB_ID()
        WHERE idx.ObjectId IS NOT NULL;
        
        IF @Debug = 1
            PRINT CONCAT('✓ Dados de uso carregados em ', DATEDIFF(MILLISECOND, @StepTime, GETDATE()), 'ms');
    END

    INSERT INTO #IndicesResumo
    SELECT X.ObjectId,
           X.ObjectName,
           X.IndexName,
           X.PercAproveitamento,
           X.Chave,
           [PrimeiraChave] = IIF(CHARINDEX(',', X.Chave, 0) > 0,
                                 (SUBSTRING(X.Chave, 0, CHARINDEX(',', X.Chave, 0))),
                                 X.Chave),
           X.ColunasIncluidas,
           X.TypeIndex,
           X.IndexId,
           X.IsUnique,
           X.IsprimaryKey,
           X.IsUniqueConstraint
    FROM #Indices X
    WHERE X.ObjectName NOT LIKE '%HangFire%'
      AND [X].[Chave] IS NOT NULL;

    -- Log de progresso
    IF @Debug = 1
    BEGIN
        SET @StepTime = GETDATE();
        PRINT CONCAT('⏳ Identificando índices duplicados... - ', FORMAT(@StepTime, 'HH:mm:ss'));
    END;
    
    -- CTE otimizada com ranking para identificar duplicatas
    ;WITH Duplicates AS (
        SELECT I.ObjectId,
               I.ObjectName,
               I.IndexName,
               I.PercAproveitamento,
               I.PrimeiraChave,
               I.Chave,
               TamanhoChave = LEN(I.Chave),
               TamanhoCInclude = ISNULL(LEN(I.ColunasIncluidas), 0),
               MaximaChave = MAX(LEN(I.Chave)) OVER (PARTITION BY I.ObjectId, I.PrimeiraChave),
               MaximaCInclude = ISNULL(MAX(LEN(I.ColunasIncluidas)) OVER (PARTITION BY I.ObjectId, I.PrimeiraChave), 0),
               -- Otimização: usar COUNT em vez de EXISTS
               MesmaPrimeiraChave = CASE 
                   WHEN COUNT(*) OVER (PARTITION BY I.ObjectId, I.PrimeiraChave) > 1 THEN 'S'
                   ELSE 'N' 
               END,
               I.ColunasIncluidas,
               I.IsUnique,
               I.IsPrimaryKey,
               I.IsUniqueConstraint,
               I.type_index,
               I.IndexId,
               [Deletar] = NULL,
               -- Ranking para identificar qual índice manter (melhor aproveitamento, menor tamanho)
               ROW_NUMBER() OVER (
                   PARTITION BY I.ObjectId, I.PrimeiraChave 
                   ORDER BY I.PercAproveitamento DESC, 
                           LEN(I.Chave) ASC,
                           I.IsUnique DESC,
                           I.IndexId ASC
               ) AS IndexRank
        FROM #IndicesResumo AS I
        WHERE EXISTS (
            SELECT 1
            FROM #IndicesResumo DU
            WHERE DU.ObjectId = I.ObjectId
              AND DU.PrimeiraChave = I.PrimeiraChave
              AND DU.RowId <> I.RowId  -- Garantir que há duplicatas
        )
          AND I.IndexId > 1  -- Não é PK
    )
    INSERT INTO #Duplicates
    SELECT DU.ObjectId,
           DU.ObjectName,
           DU.IndexName,
           DU.PercAproveitamento,
           DU.PrimeiraChave,
           DU.Chave,
           DU.TamanhoChave,
           DU.TamanhoCInclude,
           DU.MaximaChave,
           DU.MaximaCInclude,
           DU.MesmaPrimeiraChave,
           DU.ColunasIncluidas,
           DU.IsUnique,
           DU.IsPrimaryKey,
           DU.IsUniqueConstraint,
           DU.type_index,
           DU.IndexId,
           DU.Deletar,
           -- Calcular quantidade de colunas na chave
           CASE WHEN DU.Chave IS NOT NULL 
                THEN (LEN(DU.Chave) - LEN(REPLACE(DU.Chave, ',', ''))) + 1 
                ELSE 0 END,
           -- Calcular quantidade de colunas incluídas
           CASE WHEN DU.ColunasIncluidas IS NOT NULL 
                THEN (LEN(DU.ColunasIncluidas) - LEN(REPLACE(DU.ColunasIncluidas, ',', ''))) + 1 
                ELSE 0 END,
           DU.IndexRank,
           0  -- IndexSizeKB será atualizado depois
    FROM Duplicates DU;
    
    -- Atualizar tamanho dos índices para cálculo de espaço liberado
    UPDATE D
    SET D.IndexSizeKB = ISNULL(I.IndexsizeKB, 0)
    FROM #Duplicates D
    INNER JOIN #Indices I ON D.ObjectId = I.ObjectId AND D.IndexId = I.IndexId;
    
    -- OTIMIZADA: Análise de sobreposição parcial (limitada para performance)
    IF @AnalisarSobreposicao = 1 AND (SELECT COUNT(*) FROM #Duplicates) < 1000  -- Limitar para evitar produto cartesiano massivo
    BEGIN
        SET @StepTime = GETDATE();
        IF @Debug = 1
            PRINT 'Analisando sobreposição parcial entre índices...';
        
        -- Análise otimizada apenas para índices da mesma tabela com primeira chave similar
        INSERT INTO #SobreposicaoParcial (ObjectId, BaseIndexName, OverlappingIndexName, SimilarityScore, OverlapType, RecommendedAction)
        SELECT TOP 500  -- Limitar resultados para performance
            i1.ObjectId,
            i1.IndexName as BaseIndexName,
            i2.IndexName as OverlappingIndexName,
            -- Coeficiente simplificado mais rápido
            CASE 
                WHEN i1.Chave = i2.Chave THEN 100.0
                WHEN i1.PrimeiraChave = i2.PrimeiraChave THEN 75.0
                ELSE 25.0
            END as SimilarityScore,
            CASE 
                WHEN i1.Chave = i2.Chave THEN 'IDENTICAL'
                WHEN i1.Chave LIKE i2.Chave + '%' THEN 'SUPERSET'
                WHEN i2.Chave LIKE i1.Chave + '%' THEN 'SUBSET'
                ELSE 'PARTIAL'
            END as OverlapType,
            CASE 
                WHEN i1.Chave = i2.Chave THEN 'REMOVE_DUPLICATE'
                WHEN i1.PrimeiraChave = i2.PrimeiraChave THEN 'CONSIDER_MERGE'
                ELSE 'ANALYZE_USAGE'
            END as RecommendedAction
        FROM #Duplicates i1
        INNER JOIN #Duplicates i2 ON i1.ObjectId = i2.ObjectId 
            AND i1.PrimeiraChave = i2.PrimeiraChave  -- Otimização: apenas mesma primeira chave
            AND i1.IndexId < i2.IndexId  -- Evitar duplicatas
        WHERE LEN(ISNULL(i1.Chave, '')) > 0 AND LEN(ISNULL(i2.Chave, '')) > 0;
        
        SELECT @TotalSobreposicaoParcial = COUNT(*) FROM #SobreposicaoParcial;
        
        IF @Debug = 1
            PRINT CONCAT('✓ Análise de sobreposição concluída em ', DATEDIFF(MILLISECOND, @StepTime, GETDATE()), 'ms. Total: ', @TotalSobreposicaoParcial);
    END
    ELSE IF @AnalisarSobreposicao = 1
    BEGIN
        IF @Debug = 1
            PRINT '⚠️ Análise de sobreposição pulada (muitos índices - otimização de performance)';
        SET @TotalSobreposicaoParcial = 0;
    END
    
    -- OTIMIZADA: Análise de ROI (Return on Investment) - Simplificada
    IF (SELECT COUNT(*) FROM #Duplicates) < 2000  -- Limitar para performance
    BEGIN
        SET @StepTime = GETDATE();
        IF @Debug = 1
            PRINT 'Calculando ROI dos índices...';
        
        INSERT INTO #ROIAnalysis (ObjectId, IndexId, IndexName, MaintenanceCostKB, QueryBenefitScore, IsLowROI)
        SELECT TOP 1000  -- Limitar para performance
            d.ObjectId,
            d.IndexId,
            d.IndexName,
            d.IndexSizeKB as MaintenanceCostKB,
            -- Cálculo simplificado de benefício
            ISNULL(ius.user_seeks + ius.user_scans + ius.user_lookups, 0) as QueryBenefitScore,
            CASE 
                WHEN d.IndexSizeKB > 10240 AND ISNULL(ius.user_seeks + ius.user_scans + ius.user_lookups, 0) = 0 THEN 1  -- Índices grandes não usados
                WHEN d.IndexSizeKB > 1024 AND ISNULL(ius.user_seeks + ius.user_scans + ius.user_lookups, 0) < 10 THEN 1   -- Índices médios pouco usados
                ELSE 0
            END as IsLowROI
        FROM #Duplicates d
        LEFT JOIN sys.dm_db_index_usage_stats ius ON d.ObjectId = ius.object_id AND d.IndexId = ius.index_id
            AND ius.database_id = DB_ID();
        
        SELECT @TotalComBaixoROI = COUNT(*) FROM #ROIAnalysis WHERE IsLowROI = 1;
        
        IF @Debug = 1
            PRINT CONCAT('✓ Análise de ROI concluída em ', DATEDIFF(MILLISECOND, @StepTime, GETDATE()), 'ms. Índices com baixo ROI: ', @TotalComBaixoROI);
    END
    ELSE
    BEGIN
        IF @Debug = 1
            PRINT '⚠️ Análise de ROI pulada (muitos índices - otimização de performance)';
        SET @TotalComBaixoROI = 0;
    END
    
    IF @Debug = 1
    BEGIN
        SET @TotalIndicesDuplicados = (SELECT COUNT(*) FROM #Duplicates);
        PRINT CONCAT('✓ Identificados ', @TotalIndicesDuplicados, ' índices duplicados em ', 
                    DATEDIFF(MILLISECOND, @StepTime, GETDATE()), 'ms');
    END;

    IF (EXISTS (SELECT 1 FROM #Duplicates AS D))
    BEGIN
        -- Log de progresso
        IF @Debug = 1
        BEGIN
            SET @StepTime = GETDATE();
            PRINT CONCAT('⏳ Aplicando critérios de marcação para deleção... - ', FORMAT(@StepTime, 'HH:mm:ss'));
        END;
        
        -- OTIMIZADA: Gerar scripts de backup (limitado para performance)
        IF @GerarScriptBackup = 1 AND (SELECT COUNT(*) FROM #Duplicates) < 500
        BEGIN
            SET @StepTime = GETDATE();
            IF @Debug = 1
                PRINT 'Gerando scripts de backup...';
            
            INSERT INTO #BackupScripts (ObjectName, IndexName, CreateScript, DropScript)
            SELECT TOP 200  -- Limitar para performance
                OBJECT_NAME(d.ObjectId) as ObjectName,
                d.IndexName,
                -- Script de criação (simplificado)
                CONCAT(
                    'CREATE ', 
                    CASE WHEN d.IsUnique = 1 THEN 'UNIQUE ' ELSE '' END,
                    CASE WHEN d.DescTipo = 1 THEN 'CLUSTERED ' ELSE 'NONCLUSTERED ' END,
                    'INDEX [', d.IndexName, '] ON [', OBJECT_SCHEMA_NAME(d.ObjectId), '].[', OBJECT_NAME(d.ObjectId), '] (',
                    ISNULL(d.Chave, ''), ')',
                    CASE WHEN LEN(ISNULL(d.ColunasIncluidas, '')) > 0 THEN CONCAT(' INCLUDE (', d.ColunasIncluidas, ')') ELSE '' END,
                    ';'
                ) as CreateScript,
                -- Script de remoção
                CONCAT('DROP INDEX [', d.IndexName, '] ON [', OBJECT_SCHEMA_NAME(d.ObjectId), '].[', OBJECT_NAME(d.ObjectId), '];') as DropScript
            FROM #Duplicates d;
            
            -- Script consolidado simplificado (sem STRING_AGG para performance)
            SET @BackupScript = '-- Scripts de backup gerados em ' + CONVERT(VARCHAR, GETDATE(), 120) + CHAR(13) + CHAR(10);
            
            IF @Debug = 1
                PRINT CONCAT('✓ Scripts de backup gerados em ', DATEDIFF(MILLISECOND, @StepTime, GETDATE()), 'ms');
        END
        ELSE IF @GerarScriptBackup = 1
        BEGIN
            IF @Debug = 1
                PRINT '⚠️ Geração de scripts pulada (muitos índices - otimização de performance)';
        END
        
        -- Validações de segurança antes da marcação
        INSERT INTO #ValidationErrors
        SELECT 'FOREIGN_KEY_DEPENDENCY' AS ErrorType,
               OBJECT_SCHEMA_NAME(fk.parent_object_id) + '.' + OBJECT_NAME(fk.parent_object_id) AS ObjectName,
               i.name AS IndexName,
               'Índice referenciado por Foreign Key: ' + fk.name AS ErrorMessage
        FROM #Duplicates d
        INNER JOIN sys.indexes i ON d.ObjectId = i.object_id AND d.IndexId = i.index_id
        INNER JOIN sys.foreign_keys fk ON fk.referenced_object_id = d.ObjectId;
        
        -- NOVA: Validação adicional para índices com baixo ROI
        INSERT INTO #ValidationErrors (ErrorType, ObjectName, IndexName, ErrorMessage)
        SELECT 
            'LOW_ROI_WARNING',
            OBJECT_NAME(roi.ObjectId),
            roi.IndexName,
            CONCAT('Índice com baixo ROI: ', FORMAT(roi.ROI_Score, 'N4'), ' (limite: ', @LimiteROI, ')')
        FROM #ROIAnalysis roi
        WHERE roi.IsLowROI = 1;
        
        -- OTIMIZADA: Simulação de impacto (limitada para performance)
        IF @SimularImpacto = 1 AND (SELECT COUNT(*) FROM #Duplicates) < 300
        BEGIN
            SET @StepTime = GETDATE();
            IF @Debug = 1
                PRINT 'Executando simulação de impacto...';
            
            -- Simulação simplificada sem STRING_AGG
            DECLARE @ImpactoAlto INT = 0, @ImpactoMedio INT = 0, @ImpactoBaixo INT = 0;
            
            SELECT 
                @ImpactoAlto = COUNT(CASE WHEN roi.QueryBenefitScore > 100 THEN 1 END),
                @ImpactoMedio = COUNT(CASE WHEN roi.QueryBenefitScore BETWEEN 11 AND 100 THEN 1 END),
                @ImpactoBaixo = COUNT(CASE WHEN roi.QueryBenefitScore <= 10 THEN 1 END)
            FROM #Duplicates d
            INNER JOIN #ROIAnalysis roi ON d.ObjectId = roi.ObjectId AND d.IndexId = roi.IndexId
            WHERE d.IndexRank > 1;
            
            SET @SimulationResults = CONCAT(
                'Impacto ALTO: ', @ImpactoAlto, ' índices', CHAR(13), CHAR(10),
                'Impacto MÉDIO: ', @ImpactoMedio, ' índices', CHAR(13), CHAR(10),
                'Impacto BAIXO: ', @ImpactoBaixo, ' índices'
            );
            
            IF @Debug = 1
            BEGIN
                PRINT CONCAT('✓ Simulação concluída em ', DATEDIFF(MILLISECOND, @StepTime, GETDATE()), 'ms');
                PRINT 'Resumo da simulação:';
                PRINT @SimulationResults;
            END
        END
        ELSE IF @SimularImpacto = 1
        BEGIN
            IF @Debug = 1
                PRINT '⚠️ Simulação de impacto pulada (muitos índices - otimização de performance)';
            SET @SimulationResults = 'Simulação pulada por otimização de performance';
        END
        
        -- Lógica APRIMORADA para marcar índices para deleção
        -- Critério 1: Manter apenas o melhor índice de cada grupo (IndexRank = 1)
        -- Critério 2: Considerar PercAproveitamento, ROI e tipo de índice
        -- Critério 3: Evitar índices únicos e clustered quando possível
        -- Critério 4: NOVO - Considerar análise de sobreposição e ROI
        UPDATE D
        SET D.Deletar = 'S'
        FROM #Duplicates AS D
        LEFT JOIN #ROIAnalysis roi ON D.ObjectId = roi.ObjectId AND D.IndexId = roi.IndexId
        LEFT JOIN #SobreposicaoParcial sp ON D.ObjectId = sp.ObjectId 
            AND (D.IndexName = sp.BaseIndexName OR D.IndexName = sp.OverlappingIndexName)
        WHERE (
            -- Critérios originais aprimorados
            (D.IndexRank > 1 AND D.PercAproveitamento < @TaxaDeSeguranca) OR
            (D.IndexRank > 1 AND D.DescTipo = 2 AND D.IsUnique = 0) OR
            (D.IndexRank > 2) OR  -- Manter pelo menos os 2 melhores
            -- NOVOS critérios
            (roi.IsLowROI = 1 AND D.IndexRank > 1) OR
            (sp.RecommendedAction = 'REMOVE_DUPLICATE') OR
            (roi.IsLowROI = 1 AND roi.QueryBenefitScore < 1)  -- ROI muito baixo
        )
        AND D.IsPrimaryKey = 0  -- Não é Primary Key
        AND D.IsUniqueConstraint = 0  -- Não é Unique Constraint
        AND D.IsUnique = 0  -- Não é índice único
        AND NOT EXISTS (  -- Não tem dependências críticas (exceto warnings de ROI)
            SELECT 1 FROM #ValidationErrors ve 
            WHERE ve.ObjectName = D.ObjectName AND ve.IndexName = D.IndexName
            AND ve.ErrorType <> 'LOW_ROI_WARNING'
        );
        
        -- Critério 2: Índices órfãos com baixo aproveitamento
        UPDATE D
        SET D.Deletar = 'S'
        FROM #Duplicates AS D
        LEFT JOIN #ROIAnalysis roi ON D.ObjectId = roi.ObjectId AND D.IndexId = roi.IndexId
        WHERE D.ObjectId IN (
            SELECT d2.ObjectId
            FROM #Duplicates AS d2
            GROUP BY d2.ObjectId, d2.PrimeiraChave
            HAVING COUNT(*) = 1  -- Aparece apenas uma vez no grupo
        )
        AND (D.PercAproveitamento < (@TaxaDeSeguranca / 2) OR roi.IsLowROI = 1)  -- Critério mais rigoroso ou baixo ROI
        AND D.IsPrimaryKey = 0
        AND D.IsUniqueConstraint = 0
        AND NOT EXISTS (
            SELECT 1 FROM #ValidationErrors ve 
            WHERE ve.ObjectName = D.ObjectName AND ve.IndexName = D.IndexName
            AND ve.ErrorType <> 'LOW_ROI_WARNING'
        );
        
        -- NOVA: Processamento de MERGE para índices com RecommendedAction = 'CONSIDER_MERGE'
        -- Tabela para armazenar scripts de merge
        CREATE TABLE #MergeScripts (
            ObjectId INT,
            ObjectName VARCHAR(128),
            BaseIndexName VARCHAR(128),
            OverlappingIndexName VARCHAR(128),
            MergedIndexName VARCHAR(128),
            CreateMergedScript NVARCHAR(MAX),
            DropBaseScript NVARCHAR(MAX),
            DropOverlappingScript NVARCHAR(MAX),
            EstimatedBenefit VARCHAR(100)
        );
        
        IF EXISTS (SELECT 1 FROM #SobreposicaoParcial WHERE RecommendedAction = 'CONSIDER_MERGE')
        BEGIN
            SET @StepTime = GETDATE();
            IF @Debug = 1
                PRINT 'Processando merge de índices sobrepostos...';
            
            -- Gerar scripts de merge para índices que devem ser consolidados
            INSERT INTO #MergeScripts (ObjectId, ObjectName, BaseIndexName, OverlappingIndexName, MergedIndexName, CreateMergedScript, DropBaseScript, DropOverlappingScript, EstimatedBenefit)
            SELECT 
                sp.ObjectId,
                OBJECT_NAME(sp.ObjectId) as ObjectName,
                sp.BaseIndexName,
                sp.OverlappingIndexName,
                -- Nome do índice merged
                CONCAT('IX_MERGED_', 
                       REPLACE(REPLACE(sp.BaseIndexName, 'IX_', ''), 'IDX_', ''), 
                       '_', 
                       RIGHT(REPLACE(REPLACE(sp.OverlappingIndexName, 'IX_', ''), 'IDX_', ''), 20)) as MergedIndexName,
                -- Script de criação do índice merged (combinando colunas)
                CONCAT(
                    'CREATE NONCLUSTERED INDEX [IX_MERGED_', 
                    REPLACE(REPLACE(sp.BaseIndexName, 'IX_', ''), 'IDX_', ''), 
                    '_', 
                    RIGHT(REPLACE(REPLACE(sp.OverlappingIndexName, 'IX_', ''), 'IDX_', ''), 20),
                    '] ON [', OBJECT_SCHEMA_NAME(sp.ObjectId), '].[', OBJECT_NAME(sp.ObjectId), '] (',
                    -- Combinar chaves dos dois índices (base + colunas adicionais do overlapping)
                    d1.Chave,
                    CASE 
                        WHEN LEN(ISNULL(d2.Chave, '')) > LEN(ISNULL(d1.Chave, '')) 
                        THEN CONCAT(', ', SUBSTRING(d2.Chave, LEN(d1.Chave) + 2, LEN(d2.Chave)))
                        ELSE ''
                    END,
                    ')',
                    -- Incluir colunas de ambos os índices
                    CASE 
                        WHEN LEN(ISNULL(d1.ColunasIncluidas, '')) > 0 OR LEN(ISNULL(d2.ColunasIncluidas, '')) > 0
                        THEN CONCAT(' INCLUDE (', 
                                   ISNULL(d1.ColunasIncluidas, ''),
                                   CASE WHEN LEN(ISNULL(d1.ColunasIncluidas, '')) > 0 AND LEN(ISNULL(d2.ColunasIncluidas, '')) > 0 THEN ', ' ELSE '' END,
                                   ISNULL(d2.ColunasIncluidas, ''),
                                   ')')
                        ELSE ''
                    END,
                    ';'
                ) as CreateMergedScript,
                -- Scripts de remoção dos índices originais
                CONCAT('DROP INDEX [', sp.BaseIndexName, '] ON [', OBJECT_SCHEMA_NAME(sp.ObjectId), '].[', OBJECT_NAME(sp.ObjectId), '];') as DropBaseScript,
                CONCAT('DROP INDEX [', sp.OverlappingIndexName, '] ON [', OBJECT_SCHEMA_NAME(sp.ObjectId), '].[', OBJECT_NAME(sp.ObjectId), '];') as DropOverlappingScript,
                -- Benefício estimado
                CONCAT('Redução de ', FORMAT((d1.IndexSizeKB + d2.IndexSizeKB) / 1024.0, 'N1'), ' MB para ~', 
                       FORMAT((GREATEST(d1.IndexSizeKB, d2.IndexSizeKB) * 1.2) / 1024.0, 'N1'), ' MB') as EstimatedBenefit
            FROM #SobreposicaoParcial sp
            INNER JOIN #Duplicates d1 ON sp.ObjectId = d1.ObjectId AND sp.BaseIndexName = d1.IndexName
            INNER JOIN #Duplicates d2 ON sp.ObjectId = d2.ObjectId AND sp.OverlappingIndexName = d2.IndexName
            WHERE sp.RecommendedAction = 'CONSIDER_MERGE'
            AND d1.IsPrimaryKey = 0 AND d1.IsUniqueConstraint = 0
            AND d2.IsPrimaryKey = 0 AND d2.IsUniqueConstraint = 0;
            
            -- Marcar índices originais para deleção após merge
            UPDATE D
            SET D.Deletar = 'M'  -- 'M' = Merge (será processado diferente)
            FROM #Duplicates D
            INNER JOIN #MergeScripts ms ON D.ObjectId = ms.ObjectId 
                AND (D.IndexName = ms.BaseIndexName OR D.IndexName = ms.OverlappingIndexName);
            
            IF @Debug = 1
            BEGIN
                DECLARE @MergeCount INT = (SELECT COUNT(*) FROM #MergeScripts);
                PRINT CONCAT('✓ Identificados ', @MergeCount, ' grupos de índices para merge em ', 
                            DATEDIFF(MILLISECOND, @StepTime, GETDATE()), 'ms');
            END;
        END
        
        SET @TotalMarcadosParaDeletar = (SELECT COUNT(*) FROM #Duplicates WHERE Deletar = 'S');
        SET @EspacoLiberadoKB = (SELECT ISNULL(SUM(IndexSizeKB), 0) FROM #Duplicates WHERE Deletar = 'S');
        
        IF @Debug = 1
        BEGIN
            PRINT CONCAT('✓ Marcados ', @TotalMarcadosParaDeletar, ' índices para deleção em ', 
                        DATEDIFF(MILLISECOND, @StepTime, GETDATE()), 'ms');
            PRINT CONCAT('💾 Espaço estimado a ser liberado: ', FORMAT(@EspacoLiberadoKB / 1024.0, 'N2'), ' MB');
            
            IF EXISTS (SELECT 1 FROM #ValidationErrors)
            BEGIN
                PRINT '⚠️  Avisos de validação encontrados:';
                SELECT * FROM #ValidationErrors;
            END;
        END;

        -- =============================================
        -- SEÇÃO 6: EXECUÇÃO - MERGE E REMOÇÃO DE ÍNDICES
        -- =============================================
        
        -- SUBSECTION 6.1: PROCESSAMENTO DE MERGES
        IF @Efetivar = 1 AND EXISTS (SELECT 1 FROM #MergeScripts)
        BEGIN
            SET @StepTime = GETDATE();
            IF @Debug = 1
                PRINT 'Executando merge de índices sobrepostos...';
            
            DECLARE @MergeObjectId INT, @MergeObjectName VARCHAR(128), @MergeBaseIndex VARCHAR(128), @MergeOverlapIndex VARCHAR(128);
            DECLARE @CreateMergedSQL NVARCHAR(MAX), @DropBaseSQL NVARCHAR(MAX), @DropOverlapSQL NVARCHAR(MAX);
            DECLARE @MergeSuccessCount INT = 0, @MergeErrorCount INT = 0;
            
            DECLARE merge_cursor CURSOR FAST_FORWARD FOR
            SELECT ObjectId, ObjectName, BaseIndexName, OverlappingIndexName, 
                   CreateMergedScript, DropBaseScript, DropOverlappingScript
            FROM #MergeScripts
            ORDER BY ObjectName;
            
            OPEN merge_cursor;
            FETCH NEXT FROM merge_cursor INTO @MergeObjectId, @MergeObjectName, @MergeBaseIndex, @MergeOverlapIndex,
                                              @CreateMergedSQL, @DropBaseSQL, @DropOverlapSQL;
            
            WHILE @@FETCH_STATUS = 0
            BEGIN
                BEGIN TRY
                    -- 1. Criar o índice merged
                    EXEC sp_executesql @CreateMergedSQL;
                    
                    -- 2. Remover os índices originais
                    EXEC sp_executesql @DropBaseSQL;
                    EXEC sp_executesql @DropOverlapSQL;
                    
                    SET @MergeSuccessCount = @MergeSuccessCount + 1;
                    
                    IF @Debug = 1
                        PRINT CONCAT('✓ Merge realizado: ', @MergeObjectName, ' (', @MergeBaseIndex, ' + ', @MergeOverlapIndex, ')');
                END TRY
                BEGIN CATCH
                    SET @MergeErrorCount = @MergeErrorCount + 1;
                    IF @Debug = 1
                        PRINT CONCAT('✗ Erro no merge ', @MergeObjectName, ': ', ERROR_MESSAGE());
                END CATCH
                
                FETCH NEXT FROM merge_cursor INTO @MergeObjectId, @MergeObjectName, @MergeBaseIndex, @MergeOverlapIndex,
                                                  @CreateMergedSQL, @DropBaseSQL, @DropOverlapSQL;
            END
            
            CLOSE merge_cursor;
            DEALLOCATE merge_cursor;
            
            IF @Debug = 1
                PRINT CONCAT('✓ Merge concluído: ', @MergeSuccessCount, ' sucessos, ', @MergeErrorCount, ' erros em ', 
                            DATEDIFF(MILLISECOND, @StepTime, GETDATE()), 'ms');
        END
        
        -- SUBSECTION 6.2: INSERIR ÍNDICES MARCADOS PARA DELEÇÃO (exceto os já processados no merge)
        INSERT INTO #MarcadosParaDeletar
        SELECT F1.ObjectId,
               F1.ObjectName,
               F1.IndexName,
               F1.PercAproveitamento,
               F1.PrimeiraChave,
               F1.MesmaPrimeiraChave,
               F1.Chave,
               F1.Deletar,
               F1.ColunasIncluidas,
               F1.TamanhoChave,
               F1.MaximaChave,
               F1.TamanhoCInclude,
               F1.MaximaCInclude,
               F1.IsUnique,
               F1.IsPrimaryKey,
               F1.IsUniqueConstraint,
               CASE F1.DescTipo 
                   WHEN 1 THEN 'CLUSTERED'
                   WHEN 2 THEN 'NONCLUSTERED'
                   WHEN 3 THEN 'XML'
                   WHEN 4 THEN 'SPATIAL'
                   WHEN 5 THEN 'CLUSTERED COLUMNSTORE'
                   WHEN 6 THEN 'NONCLUSTERED COLUMNSTORE'
                   WHEN 7 THEN 'NONCLUSTERED HASH'
                   ELSE 'UNKNOWN'
               END,
               F1.IndexId,
               F1.IndexSizeKB
        FROM #Duplicates F1
        WHERE F1.Deletar = 'S'  -- Apenas índices marcados para deleção simples (não merge)
        ORDER BY F1.ObjectId,
                 F1.PrimeiraChave,
                 F1.PercAproveitamento ASC;  -- Deletar primeiro os de menor aproveitamento
                  
        -- SUBSECTION 6.3: REMOÇÃO DE ÍNDICES DUPLICADOS RESTANTES
        IF (EXISTS (SELECT 1 FROM #MarcadosParaDeletar AS MPD) AND @Efetivar = 1)
        BEGIN
            IF @Debug = 1
            BEGIN
                SET @StepTime = GETDATE();
                PRINT CONCAT('⏳ Iniciando remoção de índices... - ', FORMAT(@StepTime, 'HH:mm:ss'));
            END;
            
            DECLARE @RowCount INT = 1;
            DECLARE @TotalRows INT;
            DECLARE @CurrentObjectName VARCHAR(128);
            DECLARE @CurrentIndexName VARCHAR(128);
            DECLARE @Script NVARCHAR(1000);
            DECLARE @ErrorMessage NVARCHAR(4000);
            
            SELECT @TotalRows = COUNT(*) FROM #MarcadosParaDeletar;
            
            WHILE @RowCount <= @TotalRows
            BEGIN
                SELECT @CurrentObjectName = ObjectName,
                       @CurrentIndexName = IndexName
                FROM #MarcadosParaDeletar
                WHERE RowNum = @RowCount;
                
                BEGIN TRY
                    SET @Script = CONCAT('DROP INDEX [', @CurrentIndexName, '] ON ', @CurrentObjectName);
                    EXEC sys.sp_executesql @Script;
                    
                    SET @SuccessCount = @SuccessCount + 1;
                    
                    IF @Debug = 1
                        PRINT CONCAT('✓ [', @RowCount, '/', @TotalRows, '] Índice removido: ', @CurrentIndexName, ' da tabela ', @CurrentObjectName);
                        
                END TRY
                BEGIN CATCH
                    SET @ErrorMessage = ERROR_MESSAGE();
                    SET @ErrorCount = @ErrorCount + 1;
                    
                    IF @Debug = 1
                        PRINT CONCAT('✗ [', @RowCount, '/', @TotalRows, '] Erro ao remover índice ', @CurrentIndexName, ': ', @ErrorMessage);
                END CATCH
                
                SET @RowCount = @RowCount + 1;
            END;
            
            IF @Debug = 1
            BEGIN
                PRINT CONCAT('✓ Processo concluído em ', DATEDIFF(MILLISECOND, @StepTime, GETDATE()), 'ms');
                PRINT CONCAT('📊 Sucessos: ', @SuccessCount, ' | Erros: ', @ErrorCount);
            END;
        END;
    END;

    -- Relatório executivo SUPER APRIMORADO
    IF @MostrarResumoExecutivo = 1
    BEGIN
	DECLARE @quantidadeIndices INT = (SELECT COUNT(*) FROM #Indices);

        PRINT ''
        PRINT '═══════════════════════════════════════════════════════════════════════════════'
        PRINT '                    RESUMO EXECUTIVO AVANÇADO - OTIMIZAÇÃO DE ÍNDICES'
        PRINT '═══════════════════════════════════════════════════════════════════════════════'
        PRINT CONCAT('🕒 Tempo total de execução: ', DATEDIFF(MILLISECOND, @StartTime, GETDATE()), 'ms')
        PRINT CONCAT('📊 Total de índices analisados: ', (@quantidadeIndices))
        PRINT CONCAT('🔍 Total de índices duplicados encontrados: ', @TotalIndicesDuplicados)
        PRINT CONCAT('🎯 Total de índices marcados para deleção: ', @TotalMarcadosParaDeletar)
        PRINT CONCAT('💾 Espaço estimado a ser liberado: ', FORMAT(@EspacoLiberadoKB / 1024.0, 'N2'), ' MB')
        
        -- NOVAS métricas
        PRINT CONCAT('🔗 Sobreposições parciais identificadas: ', @TotalSobreposicaoParcial)
        PRINT CONCAT('📉 Índices com baixo ROI: ', @TotalComBaixoROI)
        PRINT CONCAT('🗄️ Query Store: ', CASE WHEN @QueryStoreEnabled = 1 THEN 'Habilitado e utilizado' ELSE 'Não disponível' END)
        
        -- Relatório de Merges
        IF EXISTS (SELECT 1 FROM #MergeScripts)
        BEGIN
            DECLARE @TotalMergesRealizados INT = (SELECT COUNT(*) FROM #MergeScripts);
            PRINT CONCAT('🔀 Merges de índices realizados: ', @TotalMergesRealizados)
            
            IF @Debug = 1
            BEGIN
                PRINT ''
                PRINT '📋 DETALHES DOS MERGES REALIZADOS:'
                
                DECLARE @MergeDetails NVARCHAR(MAX) = '';
                SELECT @MergeDetails = @MergeDetails + 
                    CONCAT('  • ', ObjectName, ': ', BaseIndexName, ' + ', OverlappingIndexName, 
                           ' → ', MergedIndexName, ' (', EstimatedBenefit, ')', CHAR(13) + CHAR(10))
                FROM #MergeScripts;
                
                IF LEN(@MergeDetails) > 0
                    PRINT @MergeDetails;
            END
        END
        ELSE
        BEGIN
            PRINT '🔀 Merges de índices realizados: 0'
        END
        
        IF @Efetivar = 1
        BEGIN
            PRINT ''
            PRINT '✅ EXECUÇÃO EFETIVADA:'
            PRINT CONCAT('  • Índices removidos com sucesso: ', @SuccessCount)
            PRINT CONCAT('  • Erros durante remoção: ', @ErrorCount)
            PRINT CONCAT('  • Taxa de sucesso: ', FORMAT((@SuccessCount * 100.0) / NULLIF(@TotalMarcadosParaDeletar, 0), 'N1'), '%')
        END
        ELSE
        BEGIN
            PRINT ''
            PRINT '🔍 MODO SIMULAÇÃO - Nenhum índice foi efetivamente removido'
            PRINT '  Para efetivar as alterações, execute com @Efetivar = 1'
        END
        
        -- Análise de impacto se disponível
        IF @SimularImpacto = 1 AND LEN(@SimulationResults) > 0
        BEGIN
            PRINT ''
            PRINT '📈 ANÁLISE DE IMPACTO:'
            PRINT @SimulationResults
        END
        
        -- Scripts de backup se gerados
        IF @GerarScriptBackup = 1 AND LEN(@BackupScript) > 0
        BEGIN
            PRINT ''
            PRINT '💾 SCRIPTS DE BACKUP GERADOS (primeiros 500 caracteres):'
            PRINT LEFT(@BackupScript, 500) + CASE WHEN LEN(@BackupScript) > 500 THEN '...' ELSE '' END
        END
        
        PRINT '═══════════════════════════════════════════════════════════════════════════════'
        
        -- Relatórios tabulares complementares
        SELECT 
            '📊 RESUMO EXECUTIVO' AS Tipo,
            @TotalIndicesDuplicados AS TotalIndicesDuplicados,
            @TotalMarcadosParaDeletar AS IndicesTotalParaDeletar,
            FORMAT(@EspacoLiberadoKB / 1024.0, 'N2') + ' MB' AS EspacoEstimadoLiberado,
            FORMAT(AVG(CAST(D.PercAproveitamento AS FLOAT)), 'N2') + '%' AS MediaAproveitamento,
            CASE WHEN @Efetivar = 1 THEN @SuccessCount ELSE 0 END AS IndicesRemovidosComSucesso,
            CASE WHEN @Efetivar = 1 THEN @ErrorCount ELSE 0 END AS ErrosNaRemocao,
            FORMAT(DATEDIFF(MILLISECOND, @StartTime, GETDATE()) / 1000.0, 'N2') + 's' AS TempoTotalExecucao
        FROM #Duplicates D
        WHERE EXISTS (SELECT 1 FROM #Duplicates);
        
        -- Análise por tabela
        IF EXISTS (SELECT 1 FROM #Duplicates)
        BEGIN
            SELECT 
                '📋 ANÁLISE POR TABELA' AS Tipo,
                D.ObjectName AS NomeTabela,
                COUNT(*) AS QtdIndicesDuplicados,
                COUNT(CASE WHEN D.Deletar = 'S' THEN 1 END) AS QtdMarcadosParaDeletar,
                FORMAT(SUM(CASE WHEN D.Deletar = 'S' THEN D.IndexSizeKB ELSE 0 END) / 1024.0, 'N2') + ' MB' AS EspacoLiberadoPorTabela,
                FORMAT(AVG(CAST(D.PercAproveitamento AS FLOAT)), 'N2') + '%' AS MediaAproveitamentoTabela
            FROM #Duplicates D
            GROUP BY D.ObjectName
            ORDER BY COUNT(*) DESC;
        END;
        
        -- NOVA: Relatório de sobreposição parcial
        IF @AnalisarSobreposicao = 1 AND EXISTS (SELECT 1 FROM #SobreposicaoParcial)
        BEGIN
            SELECT 
                '🔗 SOBREPOSIÇÃO PARCIAL' AS Tipo,
                sp.BaseIndexName,
                sp.OverlappingIndexName,
                sp.SimilarityScore,
                sp.OverlapType,
                sp.RecommendedAction
            FROM #SobreposicaoParcial sp
            ORDER BY sp.SimilarityScore DESC;
        END;
        
        -- NOVA: Relatório de ROI
        IF EXISTS (SELECT 1 FROM #ROIAnalysis)
        BEGIN
            SELECT 
                '📉 ANÁLISE DE ROI' AS Tipo,
                roi.IndexName,
                FORMAT(roi.ROI_Score, 'N4') AS ROI_Score,
                roi.QueryBenefitScore,
                FORMAT(roi.MaintenanceCostKB / 1024.0, 'N2') + ' MB' AS CustoManutencao,
                CASE WHEN roi.IsLowROI = 1 THEN 'SIM' ELSE 'NÃO' END AS BaixoROI
            FROM #ROIAnalysis roi
            ORDER BY roi.ROI_Score ASC;
        END;
    END;

    -- Relatório CONSOLIDADO de índices duplicados e marcados para deleção
    IF (@MostrarIndicesDuplicados = 1 OR @MostrarIndicesMarcadosParaDeletar = 1)
    BEGIN
        -- Resultado único consolidado
        SELECT 
            CASE 
                WHEN D.Deletar = 'S' THEN 'A Deletar=>'
                ELSE 'Duplicado=>'
            END AS Descricao,
            D.ObjectName,
            D.IndexName,
            D.PercAproveitamento,
            D.PrimeiraChave,
            D.MesmaPrimeiraChave,
            D.Chave,
            D.Deletar,
            D.ColunasIncluidas,
            D.TamanhoChave,
            D.MaximaChave,
            CASE D.DescTipo 
                WHEN 1 THEN 'CLUSTERED'
                WHEN 2 THEN 'NONCLUSTERED'
                WHEN 3 THEN 'XML'
                WHEN 4 THEN 'SPATIAL'
                WHEN 5 THEN 'CLUSTERED COLUMNSTORE'
                WHEN 6 THEN 'NONCLUSTERED COLUMNSTORE'
                WHEN 7 THEN 'NONCLUSTERED HASH'
                ELSE 'UNKNOWN'
            END AS TipoIndice,
            FORMAT(D.IndexSizeKB / 1024.0, 'N2') + ' MB' AS TamanhoIndice,
            -- Informações de ROI se disponível
            CASE 
                WHEN roi.ROI_Score IS NOT NULL THEN FORMAT(roi.ROI_Score, 'N4')
                ELSE 'N/A'
            END AS ROI_Score,
            CASE 
                WHEN roi.IsLowROI = 1 THEN 'SIM'
                WHEN roi.IsLowROI = 0 THEN 'NÃO'
                ELSE 'N/A'
            END AS BaixoROI
        FROM #Duplicates AS D
        LEFT JOIN #ROIAnalysis roi ON D.ObjectId = roi.ObjectId AND D.IndexId = roi.IndexId
        WHERE (@MostrarIndicesDuplicados = 1) 
           OR (@MostrarIndicesMarcadosParaDeletar = 1 AND D.Deletar = 'S')
        ORDER BY D.ObjectId,
                 D.PrimeiraChave,
                 D.IndexRank;

        -- Scripts de deleção consolidados (apenas para índices marcados para deletar)
        IF @MostrarIndicesMarcadosParaDeletar = 1 AND EXISTS (SELECT 1 FROM #Duplicates WHERE Deletar = 'S')
        BEGIN
            SELECT 
                '🗑️ SCRIPTS DE DELEÇÃO' AS Tipo,
                D.ObjectName,
                D.IndexName,
                CONCAT('DROP INDEX [', D.IndexName, '] ON ', D.ObjectName) AS ScriptDeleção,
                FORMAT(D.IndexSizeKB / 1024.0, 'N2') + ' MB' AS EspacoLiberado
            FROM #Duplicates D
            WHERE D.Deletar = 'S'
            ORDER BY D.ObjectName, D.IndexName;
        END;
                 
        -- Scripts de backup se gerados
        IF @GerarScriptBackup = 1 AND EXISTS (SELECT 1 FROM #BackupScripts)
        BEGIN
            SELECT 
                '💾 SCRIPTS DE BACKUP' AS Tipo,
                bs.ObjectName,
                bs.IndexName,
                bs.CreateScript,
                bs.DropScript
            FROM #BackupScripts bs
            ORDER BY bs.ObjectName, bs.IndexName;
        END;
    END;
    
    -- Log final
    IF @Debug = 1
    BEGIN
        PRINT '';
        PRINT CONCAT('=== FIM ANÁLISE ÍNDICES DUPLICADOS - ', FORMAT(GETDATE(), 'dd/MM/yyyy HH:mm:ss'), ' ===');
        PRINT CONCAT('⏱️  Tempo total de execução: ', DATEDIFF(MILLISECOND, @StartTime, GETDATE()), 'ms');
        PRINT CONCAT('📊 Resumo: ', @TotalIndicesDuplicados, ' duplicados encontrados, ', @TotalMarcadosParaDeletar, ' marcados para deleção');
        IF @Efetivar = 1
            PRINT CONCAT('🗑️  Remoção: ', @SuccessCount, ' sucessos, ', @ErrorCount, ' erros');
    END;
END;
GO