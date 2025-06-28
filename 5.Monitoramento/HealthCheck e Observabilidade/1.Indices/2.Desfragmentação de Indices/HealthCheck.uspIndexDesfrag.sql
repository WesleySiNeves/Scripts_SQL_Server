/****** Object:  StoredProcedure [HealthCheck].[uspIndexDesfrag_Optimized]    Script Date: 2024 ******/
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/* ==================================================================
-- Data: 2024 - Versão Otimizada para Azure SQL Database
-- Autor: Wesley Neves
-- Versão: 2.1 - Compatível com Azure SQL Database
-- Observação: Versão otimizada com priorização inteligente e verificações de recursos
--             COMPATÍVEL COM AZURE SQL DATABASE
--
-- Mudanças para Azure SQL Database:
-- ✅ Substituído sys.dm_os_ring_buffers por sys.dm_db_resource_stats
-- ✅ Substituído sys.dm_os_sys_memory por sys.dm_db_resource_stats
-- ✅ Substituído sys.dm_os_sys_info por valores fixos otimizados
-- ✅ Mantido RAISERROR e WAITFOR (suportados no Azure SQL)
-- ✅ Mantido sys.sp_executesql (suportado no Azure SQL)
--
-- Baseado em: 
https://sqlperformance.com/2015/04/sql-indexes/mitigating-index-fragmentation
https://ola.hallengren.com/sql-server-index-and-statistics-maintenance.html
https://www.red-gate.com/simple-talk/sql/database-administration/defragmenting-indexes-in-sql-server-2005-and-2008/
https://www.sqlskills.com/blogs/paul/indexes-from-every-angle-how-can-you-tell-if-an-index-is-being-used/
https://blog.sqlserveronline.com/2017/11/18/sql-server-activity-monitor-and-page-splits-per-second-tempdb/
https://techcommunity.microsoft.com/t5/Premier-Field-Engineering/Three-Usage-Scenarios-for-sys-dm-db-index-operational-stats/ba-p/370298
-- ==================================================================
*/

-- Execução: 
-- exec HealthCheck.uspIndexDesfrag_Optimized 1,15,2000,0  -- Simulação
-- exec HealthCheck.uspIndexDesfrag_Optimized @Efetivar = 1 -- Execução real

CREATE OR ALTER PROCEDURE [HealthCheck].[uspIndexDesfrag]
(
    @MostrarIndices BIT = 1,
    @MinFrag SMALLINT = 15,        -- Mais conservador
    @MinPageCount SMALLINT = 2000, -- Focar em índices maiores
    @Efetivar BIT = 0,
    @MaxCpuUsage TINYINT = 80,     -- Limite de CPU para execução
    @MaxDurationMinutes INT = 240, -- Limite de tempo total (4 horas)
    @PriorityFilter TINYINT = 4    -- 1=Crítico, 2=Alto, 3=Médio, 4=Todos
)
AS
BEGIN
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
    SET NOCOUNT ON;

    -- Declaração de variáveis de controle
    DECLARE @SqlServerVersion VARCHAR(100) =
            (
                SELECT @@VERSION
            );
    DECLARE @TipoVersao VARCHAR(100) = CASE
                                           WHEN CHARINDEX('Azure', @SqlServerVersion) > 0 THEN
                                               'Azure'
                                           WHEN CHARINDEX('Enterprise', @SqlServerVersion) > 0 THEN
                                               'Enterprise'
                                           ELSE
                                               'Standard'
                                       END;

    -- Variáveis para verificação de recursos do sistema
    DECLARE @CpuUsage INT = 0;
    DECLARE @MemoryPressure BIT = 0;
    DECLARE @TempDbSpaceGB DECIMAL(10, 2);
    DECLARE @StartTime DATETIME2 = GETDATE();
    DECLARE @TotalEstimatedDuration INT = 0;

    -- Configuração de exclusões (mais flexível)
    DECLARE @SchemasExcecao TABLE
    (
        SchemaName VARCHAR(128)
    );
    DECLARE @TableExcecao TABLE
    (
        TableName VARCHAR(128)
    );

    INSERT INTO @SchemasExcecao
    (
        SchemaName
    )
    VALUES
    ('Expurgo'),
    ('sys'),
    ('INFORMATION_SCHEMA');
    INSERT INTO @TableExcecao
    (
        TableName
    )
    VALUES
    ('LogsDetalhes'),
    ('sysdiagrams');

    -- Configurações dinâmicas de fill factor baseadas em análise
    DECLARE @MinFillFactorCritical TINYINT = 25; -- Para casos extremos
    DECLARE @MinFillFactorHigh TINYINT = 20; -- Para alta fragmentação
    DECLARE @MinFillFactorMedium TINYINT = 15; -- Para fragmentação média
    DECLARE @MinFillFactorLow TINYINT = 10; -- Para fragmentação baixa
    DECLARE @DefaultFillFactor TINYINT = 90; -- Padrão conservador

    -- ========================================
    -- VERIFICAÇÃO DE RECURSOS DO SISTEMA
    -- ========================================

    -- Verificar uso de CPU atual (Azure SQL Database compatível)
    -- No Azure SQL Database, usamos sys.dm_db_resource_stats para monitoramento
    SELECT @CpuUsage = ISNULL(
        (
            SELECT TOP 1 avg_cpu_percent 
            FROM sys.dm_db_resource_stats 
            ORDER BY end_time DESC
        ), 0
    );

    -- Se não houver dados recentes, assumir uso baixo para permitir manutenção
    IF @CpuUsage = 0
        SET @CpuUsage = 10;

    -- Verificar pressão de memória (Azure SQL Database compatível)
    -- No Azure SQL Database, verificamos através de sys.dm_db_resource_stats
    SELECT @MemoryPressure = CASE
        WHEN EXISTS (
            SELECT 1 
            FROM sys.dm_db_resource_stats 
            WHERE end_time >= DATEADD(MINUTE, -5, GETUTCDATE())
            AND avg_memory_usage_percent > 90
        ) THEN 1
        ELSE 0
    END;

  

    -- Validações de segurança antes de prosseguir
    IF @CpuUsage > @MaxCpuUsage
    BEGIN
        RAISERROR('ERRO: CPU usage muito alto (%d%%). Limite: %d%%. Abortando manutenção.', 16, 1, @CpuUsage, @MaxCpuUsage);
        RETURN;
    END;

    IF @MemoryPressure = 1
    BEGIN
        RAISERROR('ERRO: Pressão de memória detectada. Abortando manutenção.', 16, 1);
        RETURN;
    END;


    -- ========================================
    -- CRIAÇÃO DAS TABELAS TEMPORÁRIAS
    -- ========================================

    DROP TABLE IF EXISTS #Fragmentacao;
    DROP TABLE IF EXISTS #IndicesDesfragmentar;
    DROP TABLE IF EXISTS #IndexUsageStats;

    -- Tabela para dados de fragmentação (otimizada)
    CREATE TABLE #Fragmentacao
    (
        RowId INT NOT NULL IDENTITY(1, 1) PRIMARY KEY,
        ObjectId INT NOT NULL,
        IndexId INT NOT NULL,
        [index_type_desc] NVARCHAR(60),
        AvgFragmentationInPercent FLOAT(8),
        [fragment_count] BIGINT,
        [avg_fragment_size_in_pages] FLOAT(8),
        PageCount BIGINT,
        INDEX IX_ObjectIndex (ObjectId, IndexId)
    );

    -- Tabela para estatísticas de uso de índices
    CREATE TABLE #IndexUsageStats
    (
        ObjectId INT NOT NULL,
        IndexId INT NOT NULL,
        UserSeeks BIGINT,
        UserScans BIGINT,
        UserLookups BIGINT,
        UserUpdates BIGINT,
        LastUserSeek DATETIME,
        LastUserScan DATETIME,
        LastUserLookup DATETIME,
        LastUserUpdate DATETIME,
        PRIMARY KEY (
                        ObjectId,
                        IndexId
                    )
    );

    -- Tabela principal otimizada com campos adicionais
    CREATE TABLE #IndicesDesfragmentar
    (
        RowId SMALLINT NOT NULL IDENTITY(1, 1) PRIMARY KEY,
        [SchemaName] VARCHAR(128) NOT NULL,
        [TableName] VARCHAR(128) NOT NULL,
        IndexName VARCHAR(128) NOT NULL,
        FillFact TINYINT,
        NewFillFact TINYINT NULL,
        PageSpltForIndex BIGINT,
        AvgFragmentationInPercent FLOAT,
        PageCount BIGINT,
        -- Novos campos para priorização inteligente
        Priority TINYINT,
        EstimatedBenefit DECIMAL(12, 2),
        EstimatedDurationMinutes INT,
        EstimatedTempDbSpaceGB DECIMAL(10, 2),
        MaintenanceWindow VARCHAR(20),
        OptimalMaxDop TINYINT,
        UsageScore DECIMAL(10, 2),
        LastUsed DATETIME,
        Script NVARCHAR(1000),
        INDEX IX_Priority (Priority, EstimatedBenefit DESC)
    );

    -- ========================================
    -- COLETA DE DADOS DE FRAGMENTAÇÃO OTIMIZADA
    -- ========================================

    RAISERROR('🔍 Coletando dados de fragmentação...', 0, 1) WITH NOWAIT;

    -- Inserir dados de fragmentação com filtros otimizados
    INSERT INTO #Fragmentacao
    (
        ObjectId,
        IndexId,
        [index_type_desc],
        AvgFragmentationInPercent,
        [fragment_count],
        [avg_fragment_size_in_pages],
        PageCount
    )
    SELECT A.object_id,
           A.index_id,
           A.index_type_desc,
           A.avg_fragmentation_in_percent,
           A.fragment_count,
           A.avg_fragment_size_in_pages,
           A.page_count
    FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, 'SAMPLED') AS A -- SAMPLED para melhor performance
        INNER JOIN sys.indexes ix
            ON ix.object_id = A.object_id
               AND ix.index_id = A.index_id
        INNER JOIN sys.tables t
            ON t.object_id = A.object_id
        INNER JOIN sys.schemas s
            ON s.schema_id = t.schema_id
    WHERE A.alloc_unit_type_desc = 'IN_ROW_DATA' -- Apenas dados in-row
          AND ix.type IN ( 1, 2 ) -- Clustered e Non-clustered apenas
          AND ix.is_disabled = 0 -- Excluir índices desabilitados
          AND ix.is_hypothetical = 0 -- Excluir índices hipotéticos
          AND A.page_count > @MinPageCount
          AND A.avg_fragmentation_in_percent >= @MinFrag
          AND s.name NOT IN
              (
                  SELECT SE.SchemaName COLLATE DATABASE_DEFAULT FROM @SchemasExcecao AS SE
              )
          AND t.name NOT IN
              (
                  SELECT TE.TableName COLLATE DATABASE_DEFAULT FROM @TableExcecao AS TE
              )
          AND t.is_ms_shipped = 0 -- Excluir tabelas do sistema
          AND OBJECTPROPERTY(A.object_id, 'IsSystemTable') = 0
    
    UNION ALL
    
    -- Adicionar índices ColumnStore para análise
    SELECT 
        i.object_id,
        i.index_id,
        CASE i.type 
            WHEN 5 THEN 'CLUSTERED COLUMNSTORE'
            WHEN 6 THEN 'NONCLUSTERED COLUMNSTORE'
        END AS index_type_desc,
        ISNULL(
            (SELECT AVG(CAST(deleted_rows AS FLOAT) / NULLIF(total_rows, 0) * 100)
             FROM sys.dm_db_column_store_row_group_physical_stats 
             WHERE object_id = i.object_id AND index_id = i.index_id), 0
        ) AS avg_fragmentation_in_percent,
        0 AS fragment_count, -- N/A para ColumnStore
        0 AS avg_fragment_size_in_pages, -- N/A para ColumnStore
        ISNULL(
            (SELECT SUM(total_rows) / 128 -- Estimativa de páginas baseada em rows
             FROM sys.dm_db_column_store_row_group_physical_stats 
             WHERE object_id = i.object_id AND index_id = i.index_id), 0
        ) AS page_count
    FROM sys.indexes i
        INNER JOIN sys.tables t ON i.object_id = t.object_id
        INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
    WHERE i.type IN (5, 6) -- ColumnStore indexes (5=Clustered, 6=NonClustered)
          AND i.is_disabled = 0
          AND i.is_hypothetical = 0
          AND s.name NOT IN
              (
                  SELECT SE.SchemaName COLLATE DATABASE_DEFAULT FROM @SchemasExcecao AS SE
              )
          AND t.name NOT IN
              (
                  SELECT TE.TableName COLLATE DATABASE_DEFAULT FROM @TableExcecao AS TE
              )
          AND t.is_ms_shipped = 0
          AND OBJECTPROPERTY(i.object_id, 'IsSystemTable') = 0
          AND (
              -- Critérios específicos para ColumnStore
              EXISTS (
                  SELECT 1 
                  FROM sys.dm_db_column_store_row_group_physical_stats rg
                  WHERE rg.object_id = i.object_id 
                    AND rg.index_id = i.index_id
                    AND (rg.deleted_rows > 0 OR rg.state <> 3) -- Tem linhas deletadas ou não está comprimido
              )
              OR 
              -- Fragmentação baseada em linhas deletadas > 10%
              ISNULL(
                  (SELECT AVG(CAST(deleted_rows AS FLOAT) / NULLIF(total_rows, 0) * 100)
                   FROM sys.dm_db_column_store_row_group_physical_stats 
                   WHERE object_id = i.object_id AND index_id = i.index_id), 0
              ) >= 10
          );

    -- Coletar estatísticas de uso dos índices
    INSERT INTO #IndexUsageStats
    SELECT st.object_id,
           st.index_id,
           st.user_seeks,
           st.user_scans,
           st.user_lookups,
           st.user_updates,
           st.last_user_seek,
           st.last_user_scan,
           st.last_user_lookup,
           st.last_user_update
    FROM sys.dm_db_index_usage_stats st
    WHERE database_id = DB_ID()
          AND EXISTS
    (
        SELECT *
        FROM #Fragmentacao f
        WHERE f.ObjectId = st.object_id
              AND st.index_id = f.IndexId
    );

    DECLARE @FragmentedIndexes INT =
            (
                SELECT COUNT(*)FROM #Fragmentacao
            );
    RAISERROR('INFO: Encontrados %d índices fragmentados para análise.', 0, 1, @FragmentedIndexes) WITH NOWAIT;

    -- ========================================
    -- PROCESSAMENTO PRINCIPAL
    -- ========================================

    IF EXISTS (SELECT 1 FROM #Fragmentacao)
    BEGIN
        RAISERROR('INFO: Processando dados e calculando prioridades...', 0, 1) WITH NOWAIT;

        -- Inserir índices para desfragmentação com dados enriquecidos
        INSERT INTO #IndicesDesfragmentar
        (
            [SchemaName],
            [TableName],
            [IndexName],
            [FillFact],
            [NewFillFact],
            [PageSpltForIndex],
            [AvgFragmentationInPercent],
            [PageCount],
            [UsageScore],
            [LastUsed]
        )
        SELECT CAST(S.name AS VARCHAR(128)) AS SchemaName,
               CAST(T.name AS VARCHAR(128)) AS TableName,
               CAST(I.name AS VARCHAR(128)) AS IndexName,
               CAST(ISNULL(I.fill_factor, 0) AS TINYINT) fill_factor,
               NULL AS NewFillFact,
               ISNULL(IOS.leaf_allocation_count, 0) AS PageSplitForIndex,
               F.AvgFragmentationInPercent,
               CAST(F.PageCount AS BIGINT),
               -- Calcular score de uso baseado em atividade
               ISNULL(
                         (ISNULL(US.UserSeeks, 0) + ISNULL(US.UserScans, 0) + ISNULL(US.UserLookups, 0)) * 1.0
                         / NULLIF(ISNULL(US.UserUpdates, 0), 0),
                         0
                     ) AS UsageScore,
               -- Última vez que foi usado
               COALESCE(US.LastUserSeek, US.LastUserScan, US.LastUserLookup, '1900-01-01') AS LastUsed
        FROM sys.dm_db_index_operational_stats(DB_ID(), NULL, NULL, NULL) IOS
            INNER JOIN #Fragmentacao AS F
                ON IOS.object_id = F.ObjectId
                   AND IOS.index_id = F.IndexId
            INNER JOIN sys.indexes I
                ON IOS.index_id = I.index_id
                   AND IOS.object_id = I.object_id
            INNER JOIN sys.tables AS T
                ON I.object_id = T.object_id
            INNER JOIN sys.schemas AS S
                ON T.schema_id = S.schema_id
            LEFT JOIN #IndexUsageStats US
                ON US.ObjectId = F.ObjectId
                   AND US.IndexId = F.IndexId
        OPTION (MAXDOP 0);

        -- ========================================
        -- NORMALIZAÇÃO E CÁLCULO DE FILL FACTOR
        -- ========================================

        -- Normalizar fill factor (0 = 100%)
        UPDATE IX
        SET IX.FillFact = CASE
                              WHEN IX.FillFact = 0 THEN
                                  100
                              WHEN IX.FillFact
                                   BETWEEN 1 AND 99 THEN
                                  IX.FillFact
                              ELSE
                                  @DefaultFillFactor
                          END
        FROM #IndicesDesfragmentar IX;

        -- ========================================
        -- CÁLCULO INTELIGENTE DE PRIORIDADES
        -- ========================================

        -- Calcular prioridade baseada em múltiplos fatores
        UPDATE FRAG
        SET
            -- Prioridade baseada em fragmentação, tamanho e page splits
            FRAG.Priority = CASE
                                WHEN FRAG.AvgFragmentationInPercent >= 80
                                     AND FRAG.PageCount > 50000 THEN
                                    1 -- CRÍTICO
                                WHEN FRAG.AvgFragmentationInPercent >= 70
                                     AND FRAG.PageSpltForIndex > 10000 THEN
                                    1 -- CRÍTICO
                                WHEN FRAG.AvgFragmentationInPercent >= 60
                                     AND FRAG.PageCount > 20000 THEN
                                    2 -- ALTO
                                WHEN FRAG.AvgFragmentationInPercent >= 50
                                     AND FRAG.PageSpltForIndex > 5000 THEN
                                    2 -- ALTO
                                WHEN FRAG.AvgFragmentationInPercent >= 40
                                     OR FRAG.PageSpltForIndex > 2000 THEN
                                    3 -- MÉDIO
                                ELSE
                                    4 -- BAIXO
                            END,

            -- Benefício estimado (fórmula ponderada)
            FRAG.EstimatedBenefit = ((FRAG.AvgFragmentationInPercent * 0.4) + -- 40% peso para fragmentação
            (FRAG.PageCount * 0.0001 * 0.3) + -- 30% peso para tamanho
            (FRAG.PageSpltForIndex * 0.001 * 0.2) + -- 20% peso para page splits
            (FRAG.UsageScore * 0.1) -- 10% peso para uso
                                    ),

            -- Estimativa de duração baseada no tipo de operação e tamanho
            FRAG.EstimatedDurationMinutes = CASE
                                                WHEN FRAG.AvgFragmentationInPercent > 30 THEN
                                                    CAST((FRAG.PageCount * 0.0008) + 2 AS INT) -- REBUILD (mais lento)
                                                ELSE
                                                    CAST((FRAG.PageCount * 0.0003) + 1 AS INT) -- REORGANIZE (mais rápido)
                                            END,

            -- Estimativa de espaço no TempDB (apenas para REBUILD)
            FRAG.EstimatedTempDbSpaceGB = CASE
                                              WHEN FRAG.AvgFragmentationInPercent > 30 THEN
            (FRAG.PageCount * 8.0 / 1024 / 1024) * 1.3 -- REBUILD com margem de segurança
                                              ELSE
                                                  0    -- REORGANIZE não usa TempDB significativamente
                                          END,

            -- Janela de manutenção recomendada
            FRAG.MaintenanceWindow = CASE
                                         WHEN FRAG.AvgFragmentationInPercent >= 80
                                              AND FRAG.PageCount > 50000 THEN
                                             'IMEDIATO'
                                         WHEN FRAG.AvgFragmentationInPercent >= 60 THEN
                                             'SEMANAL'
                                         WHEN FRAG.AvgFragmentationInPercent >= 40 THEN
                                             'MENSAL'
                                         ELSE
                                             'TRIMESTRAL'
                                     END
        FROM #IndicesDesfragmentar FRAG;

        -- ========================================
        -- CÁLCULO DINÂMICO DE FILL FACTOR
        -- ========================================

        -- Calcular novo fill factor baseado em análise inteligente
        UPDATE FRAG
        SET FRAG.NewFillFact = CASE
                                   -- Para índices com page splits extremos
                                   WHEN FRAG.PageSpltForIndex > 20000 THEN
                                       GREATEST(FRAG.FillFact - @MinFillFactorCritical, 70)
                                   -- Para fragmentação crítica
                                   WHEN FRAG.AvgFragmentationInPercent >= 90 THEN
                                       GREATEST(FRAG.FillFact - @MinFillFactorHigh, 75)
                                   -- Para fragmentação alta com índices grandes
                                   WHEN FRAG.AvgFragmentationInPercent >= 70
                                        AND FRAG.PageCount > 10000 THEN
                                       GREATEST(FRAG.FillFact - @MinFillFactorHigh, 75)
                                   -- Para fragmentação média-alta
                                   WHEN FRAG.AvgFragmentationInPercent >= 50 THEN
                                       GREATEST(FRAG.FillFact - @MinFillFactorMedium, 80)
                                   -- Para fragmentação média
                                   WHEN FRAG.AvgFragmentationInPercent >= @MinFrag THEN
                                       GREATEST(FRAG.FillFact - @MinFillFactorLow, 85)
                                   -- Padrão conservador
                                   ELSE
                                       @DefaultFillFactor
                               END,

            -- Calcular MAXDOP otimizado baseado no tamanho do índice (Azure SQL Database compatível)
            -- No Azure SQL Database, usamos valores fixos baseados no tier de serviço
            FRAG.OptimalMaxDop = CASE
                                     WHEN FRAG.PageCount > 100000 THEN 8  -- Índices muito grandes
                                     WHEN FRAG.PageCount > 50000 THEN 6   -- Índices grandes
                                     WHEN FRAG.PageCount > 20000 THEN 4   -- Índices médios
                                     WHEN FRAG.PageCount > 5000 THEN 2    -- Índices pequenos
                                     ELSE 1                                -- Índices muito pequenos
                                 END
        FROM #IndicesDesfragmentar FRAG
        WHERE FRAG.NewFillFact IS NULL;

        -- Calcular duração total estimada
        SELECT @TotalEstimatedDuration = SUM(EstimatedDurationMinutes)
        FROM #IndicesDesfragmentar
        WHERE Priority <= @PriorityFilter;

        -- Verificar se a duração estimada excede o limite
        IF @TotalEstimatedDuration > @MaxDurationMinutes
        BEGIN
            RAISERROR(
                         'AVISO: Duração estimada (%d min) excede limite (%d min). Considere filtrar por prioridade.',
                         10,
                         1,
                         @TotalEstimatedDuration,
                         @MaxDurationMinutes
                     );
        END;

        -- ========================================
        -- GERAÇÃO DE SCRIPTS OTIMIZADOS
        -- ========================================

        -- Gerar scripts de manutenção com configurações otimizadas
        UPDATE FRAG
        SET FRAG.Script = CASE
                              -- Scripts específicos para índices ColumnStore
                              WHEN F.index_type_desc LIKE '%COLUMNSTORE%' THEN
                                  CONCAT(
                                            'ALTER INDEX ',
                                            QUOTENAME(FRAG.IndexName),
                                            ' ON ',
                                            QUOTENAME(FRAG.SchemaName),
                                            '.',
                                            QUOTENAME(FRAG.TableName),
                                            ' REBUILD WITH (MAXDOP = ',
                                            FRAG.OptimalMaxDop,
                                            ');'
                                        )
                              -- REBUILD para fragmentação alta (>30%) ou índices críticos
                              WHEN FRAG.AvgFragmentationInPercent > 30
                                   OR FRAG.Priority <= 2 THEN
                                  CONCAT(
                                            'ALTER INDEX ',
                                            QUOTENAME(FRAG.IndexName),
                                            ' ON ',
                                            QUOTENAME(FRAG.SchemaName),
                                            '.',
                                            QUOTENAME(FRAG.TableName),
                                            ' REBUILD'
                                        )
                              -- REORGANIZE para fragmentação média (15-30%)
                              ELSE
                                  CONCAT(
                                            'ALTER INDEX ',
                                            QUOTENAME(FRAG.IndexName),
                                            ' ON ',
                                            QUOTENAME(FRAG.SchemaName),
                                            '.',
                                            QUOTENAME(FRAG.TableName),
                                            ' REORGANIZE'
                                        )
                          END
        FROM #IndicesDesfragmentar FRAG
        INNER JOIN #Fragmentacao F ON F.ObjectId = (
            SELECT object_id FROM sys.objects 
            WHERE SCHEMA_NAME(schema_id) = FRAG.SchemaName 
            AND name = FRAG.TableName
        ) AND F.IndexId = (
            SELECT index_id FROM sys.indexes 
            WHERE object_id = (
                SELECT object_id FROM sys.objects 
                WHERE SCHEMA_NAME(schema_id) = FRAG.SchemaName 
                AND name = FRAG.TableName
            ) AND name = FRAG.IndexName
        );

        -- Adicionar opções WITH para operações REBUILD (exceto ColumnStore que já têm configurações específicas)
        UPDATE FRAG
        SET FRAG.Script = CONCAT(
                                    FRAG.Script,
                                    ' WITH (',
                                    -- Configurações baseadas na versão do SQL Server
                                    CASE
                                        WHEN @TipoVersao IN ( 'Azure', 'Enterprise' ) THEN
                                            'ONLINE=ON, DATA_COMPRESSION=PAGE, '
                                        ELSE
                                            ''
                                    END,
                                    'MAXDOP=',
                                    CAST(FRAG.OptimalMaxDop AS VARCHAR(2)),
                                    ', ',
                                    'SORT_IN_TEMPDB=ON, ',
                                    'FILLFACTOR=',
                                    CAST(FRAG.NewFillFact AS VARCHAR(3)),
                                    ')'
                                )
        FROM #IndicesDesfragmentar FRAG
        INNER JOIN #Fragmentacao F ON F.ObjectId = (
            SELECT object_id FROM sys.objects 
            WHERE SCHEMA_NAME(schema_id) = FRAG.SchemaName 
            AND name = FRAG.TableName
        ) AND F.IndexId = (
            SELECT index_id FROM sys.indexes 
            WHERE object_id = (
                SELECT object_id FROM sys.objects 
                WHERE SCHEMA_NAME(schema_id) = FRAG.SchemaName 
                AND name = FRAG.TableName
            ) AND name = FRAG.IndexName
        )
        WHERE FRAG.AvgFragmentationInPercent > 30 -- Apenas para REBUILD
        AND F.index_type_desc NOT LIKE '%COLUMNSTORE%';

        -- ========================================
        -- EXECUÇÃO COM CONTROLE INTELIGENTE
        -- ========================================

        DECLARE @Script NVARCHAR(1000);
        DECLARE @CurrentIndex VARCHAR(300);
        DECLARE @OperationStartTime DATETIME2;
        DECLARE @Mensagem NVARCHAR(1000);
        DECLARE @ProcessedCount INT = 0;
        DECLARE @TotalCount INT;
        DECLARE @ProgressPct DECIMAL(5, 2);
        DECLARE @RetryCount INT;
        DECLARE @MaxRetries INT = 3;
        DECLARE @CurrentPriority TINYINT;
        DECLARE @CurrentDuration INT;

        -- Contar total de índices a processar
        SELECT @TotalCount = COUNT(*)
        FROM #IndicesDesfragmentar
        WHERE Priority <= @PriorityFilter;

        RAISERROR(
                     'INFO: Total de %d índices selecionados para manutenção (Prioridade <= %d).',
                     0,
                     1,
                     @TotalCount,
                     @PriorityFilter
                 ) WITH NOWAIT;

        -- Executar manutenção se solicitado
        IF EXISTS
        (
            SELECT 1
            FROM #IndicesDesfragmentar
            WHERE Priority <= @PriorityFilter
        )
           AND @Efetivar = 1
        BEGIN
            RAISERROR('🚀 Iniciando execução da manutenção...', 0, 1) WITH NOWAIT;

            DECLARE cursor_Fragmentacao CURSOR FAST_FORWARD READ_ONLY FOR
            SELECT FI.Script,
                   CONCAT(FI.SchemaName, '.', FI.TableName, '.', FI.IndexName),
                   FI.Priority,
                   FI.EstimatedDurationMinutes
            FROM #IndicesDesfragmentar AS FI
            WHERE FI.Priority <= @PriorityFilter
            ORDER BY FI.Priority ASC,
                     FI.EstimatedBenefit DESC,
                     FI.PageCount DESC;

            OPEN cursor_Fragmentacao;
            FETCH NEXT FROM cursor_Fragmentacao
            INTO @Script,
                 @CurrentIndex,
                 @CurrentPriority,
                 @CurrentDuration;

            WHILE @@FETCH_STATUS = 0
                  AND DATEDIFF(MINUTE, @StartTime, GETDATE()) < @MaxDurationMinutes
            BEGIN
                SET @ProcessedCount = @ProcessedCount + 1;
                SET @ProgressPct = (@ProcessedCount * 100.0) / @TotalCount;
                SET @OperationStartTime = GETDATE();
                SET @RetryCount = 0;

                -- Verificar recursos antes de cada operação crítica
                IF @CurrentPriority <= 2 -- Apenas para prioridades críticas e altas
                BEGIN
                    -- Verificar CPU durante execução (Azure SQL Database compatível)
                    SELECT @CpuUsage = ISNULL(
                        (
                            SELECT TOP 1 avg_cpu_percent 
                            FROM sys.dm_db_resource_stats 
                            ORDER BY end_time DESC
                        ), 10  -- Valor padrão baixo se não houver dados
                    );

                    IF @CpuUsage > (@MaxCpuUsage + 10) -- Margem adicional durante execução
                    BEGIN
                        RAISERROR('AVISO: CPU alto (%d%%) durante execução. Pausando por 30 segundos...', 0, 1, @CpuUsage) WITH NOWAIT;
                        WAITFOR DELAY '00:00:30';
                    END;
                END;

                -- Implementar retry logic
                WHILE @RetryCount < @MaxRetries
                BEGIN
                    BEGIN TRY
                        EXEC sys.sp_executesql @Script;
                        BREAK; -- Sucesso, sair do loop de retry
                    END TRY
                    BEGIN CATCH
                        SET @RetryCount = @RetryCount + 1;

                        IF @RetryCount >= @MaxRetries
                        BEGIN
                            SET @Mensagem
                                = CONCAT(
                                            'ERRO: Falha após ',
                                            @MaxRetries,
                                            ' tentativas - ',
                                            @CurrentIndex,
                                            ': ',
                                            ERROR_MESSAGE()
                                        );
                            RAISERROR(@Mensagem, 0, 1) WITH NOWAIT;
                        END;
                        ELSE
                        BEGIN
                            RAISERROR(
                                         'AVISO: Tentativa %d/%d falhou para %s. Aguardando 30s...',
                                         0,
                                         1,
                                         @RetryCount,
                                         @MaxRetries,
                                         @CurrentIndex
                                     ) WITH NOWAIT;
                            WAITFOR DELAY '00:00:30';
                        END;
                    END CATCH;
                END;

                -- Exibir progresso detalhado
                IF (@MostrarIndices = 1 AND @RetryCount < @MaxRetries)
                BEGIN
                    DECLARE @ActualDuration INT = DATEDIFF(MILLISECOND, @OperationStartTime, GETDATE());
                    DECLARE @PriorityText VARCHAR(10) = CASE @CurrentPriority
                                                            WHEN 1 THEN
                                                                'CRÍTICO'
                                                            WHEN 2 THEN
                                                                'ALTO'
                                                            WHEN 3 THEN
                                                                'MÉDIO'
                                                            ELSE
                                                                'BAIXO'
                                                        END;

                    SET @Mensagem
                        = CONCAT(
                                    'SUCESSO [',
                                    FORMAT(@ProgressPct, 'N1'),
                                    '%] ',
                                    '(',
                                    @ProcessedCount,
                                    '/',
                                    @TotalCount,
                                    ') ',
                                    @PriorityText,
                                    ' - ',
                                    @CurrentIndex,
                                    ' - ',
                                    @ActualDuration,
                                    'ms ',
                                    '(Est: ',
                                    @CurrentDuration,
                                    'min)'
                                );

                    RAISERROR(@Mensagem, 0, 1) WITH NOWAIT;
                END;

                FETCH NEXT FROM cursor_Fragmentacao
                INTO @Script,
                     @CurrentIndex,
                     @CurrentPriority,
                     @CurrentDuration;
            END;

            CLOSE cursor_Fragmentacao;
            DEALLOCATE cursor_Fragmentacao;

            DECLARE @TotalDuration INT = DATEDIFF(MINUTE, @StartTime, GETDATE());
            RAISERROR(
                         'CONCLUIDO: Manutenção finalizada! Processados: %d/%d índices em %d minutos.',
                         0,
                         1,
                         @ProcessedCount,
                         @TotalCount,
                         @TotalDuration
                     ) WITH NOWAIT;
        END;
        ELSE IF @Efetivar = 0
        BEGIN
            RAISERROR('INFO: Modo simulação ativo. Use @Efetivar = 1 para executar.', 0, 1) WITH NOWAIT;
        END;
    END;
    ELSE
    BEGIN
        RAISERROR('INFO: Nenhum índice encontrado que atenda aos critérios de fragmentação.', 0, 1) WITH NOWAIT;
    END;

    -- ========================================
    -- RELATÓRIO FINAL DETALHADO
    -- ========================================

    IF (@MostrarIndices = 1)
    BEGIN
        -- Relatório resumido por prioridade
        SELECT Priority,
               CASE Priority
                   WHEN 1 THEN
                       'CRÍTICO'
                   WHEN 2 THEN
                       'ALTO'
                   WHEN 3 THEN
                       'MÉDIO'
                   ELSE
                       'BAIXO'
               END AS PriorityDesc,
               COUNT(*) AS QtdIndices,
               AVG(AvgFragmentationInPercent) AS FragmentacaoMedia,
               SUM(PageCount) AS TotalPaginas,
               SUM(EstimatedDurationMinutes) AS DuracaoEstimadaMin,
               SUM(EstimatedTempDbSpaceGB) AS EspacoTempDbGB
        FROM #IndicesDesfragmentar
        GROUP BY Priority
        ORDER BY Priority;

        -- Relatório detalhado dos índices
        SELECT Priority,
               CASE Priority
                   WHEN 1 THEN
                       'CRÍTICO'
                   WHEN 2 THEN
                       'ALTO'
                   WHEN 3 THEN
                       'MÉDIO'
                   ELSE
                       'BAIXO'
               END AS PriorityDesc,
               SchemaName,
               TableName,
               IndexName,
               CAST(AvgFragmentationInPercent AS DECIMAL(5, 2)) AS FragmentacaoAtual,
               PageCount,
               PageSpltForIndex,
               FillFact AS FillFactorAtual,
               NewFillFact AS NovoFillFactor,
               CAST(EstimatedBenefit AS DECIMAL(10, 2)) AS BeneficioEstimado,
               EstimatedDurationMinutes AS DuracaoEstMin,
               CAST(EstimatedTempDbSpaceGB AS DECIMAL(8, 2)) AS EspacoTempDbGB,
               MaintenanceWindow AS JanelaSugerida,
               OptimalMaxDop AS MaxDopOtimo,
               CAST(UsageScore AS DECIMAL(8, 2)) AS ScoreUso,
               LastUsed AS UltimoUso,
               Script
        FROM #IndicesDesfragmentar
        ORDER BY Priority ASC,
                 EstimatedBenefit DESC,
                 PageCount DESC;
    END;

    -- Limpeza
    DROP TABLE IF EXISTS #Fragmentacao;
    DROP TABLE IF EXISTS #IndicesDesfragmentar;
    DROP TABLE IF EXISTS #IndexUsageStats;

END;
GO

-- ========================================
-- EXEMPLOS DE USO
-- ========================================

/*
-- Simulação completa (recomendado primeiro)
EXEC HealthCheck.uspIndexDesfrag_Optimized 
    @MostrarIndices = 1,
    @MinFrag = 15,
    @MinPageCount = 2000,
    @Efetivar = 0;

-- Execução apenas de prioridade crítica
EXEC HealthCheck.uspIndexDesfrag_Optimized 
    @Efetivar = 1,
    @PriorityFilter = 1,
    @MaxDurationMinutes = 60;

-- Execução completa em janela de manutenção
EXEC HealthCheck.uspIndexDesfrag_Optimized 
    @Efetivar = 1,
    @MaxDurationMinutes = 240,
    @MaxCpuUsage = 70;

-- Modo conservador para produção
EXEC HealthCheck.uspIndexDesfrag_Optimized 
    @MinFrag = 20,
    @MinPageCount = 5000,
    @PriorityFilter = 2,
    @MaxCpuUsage = 60,
    @Efetivar = 1;
*/