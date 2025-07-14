SET QUOTED_IDENTIFIER ON
SET ANSI_NULLS ON
GO

/*
=============================================
Autor: Wesley Neves
Data de Criação: 2024-12-19
Descrição: Procedure para análise detalhada de tamanho de objetos do banco de dados
           Retorna informações sobre tabelas (tamanho, registros, média bytes/linha)
           e índices NonClustered com seus respectivos tamanhos
           
Versão: 1.0

Parâmetros:
    @TableName: Filtro opcional por nome da tabela (NULL = todas as tabelas)
    @IncludeSystemTables: Incluir tabelas do sistema (0 = não, 1 = sim)
    @MinSizeMB: Tamanho mínimo em MB para filtrar resultados (padrão = 0)
    @ShowIndexDetails: Mostrar detalhes dos índices NonClustered (0 = não, 1 = sim)
    @OrderBy: Ordenação dos resultados ('SIZE', 'ROWS', 'NAME') - padrão = 'SIZE'

Exemplo de uso:
    EXEC HealthCheck.uspSizeObjects 
        @TableName = NULL,
        @IncludeSystemTables = 0,
        @MinSizeMB = 1,
        @ShowIndexDetails = 1,
        @OrderBy = 'SIZE'
=============================================
*/

CREATE OR ALTER PROCEDURE HealthCheck.uspSizeObjects (
    @TableName VARCHAR(128) = NULL,
    @IncludeSystemTables BIT = 0,
    @MinSizeMB DECIMAL(10,2) = 0,
    @ShowIndexDetails BIT = 1,
    @OrderBy VARCHAR(10) = 'SIZE'
)
AS
BEGIN
    SET NOCOUNT ON;
    SET TRAN ISOLATION LEVEL READ UNCOMMITTED;
    
    -- Variáveis para controle
    DECLARE @StartTime DATETIME2 = GETDATE();
    DECLARE @TotalTables INT = 0;
    DECLARE @TotalIndexes INT = 0;
    DECLARE @TotalSizeGB DECIMAL(18,2) = 0;
    DECLARE @DatabaseId INT = DB_ID();
    
    -- Validação de parâmetros
    IF @OrderBy NOT IN ('SIZE', 'ROWS', 'NAME')
        SET @OrderBy = 'SIZE';
    
    PRINT '═══════════════════════════════════════════════════════════════════════════════';
    PRINT '🔍 ANÁLISE DE TAMANHO DE OBJETOS DO BANCO DE DADOS';
    PRINT CONCAT('📅 Data/Hora: ', FORMAT(@StartTime, 'dd/MM/yyyy HH:mm:ss'));
    PRINT CONCAT('🗄️  Banco: ', DB_NAME());
    IF @TableName IS NOT NULL
        PRINT CONCAT('📋 Tabela específica: ', @TableName);
    PRINT CONCAT('📏 Tamanho mínimo: ', @MinSizeMB, ' MB');
    PRINT '═══════════════════════════════════════════════════════════════════════════════';
    
    -- ========================================
    -- OTIMIZAÇÃO: Tabelas temporárias no tempDB com índices para melhor performance
    -- ========================================
    
    -- Tabela base para objetos (criada no tempDB com índices)
    CREATE TABLE #BaseObjects (
        object_id INT NOT NULL,
        schema_id INT NOT NULL,
        SchemaName VARCHAR(128) NOT NULL,
        TableName VARCHAR(128) NOT NULL,
        IsSystemTable BIT NOT NULL,
        PRIMARY KEY CLUSTERED (object_id)
    );
    
    -- Tabela base para allocation units (otimizada para JOINs)
    CREATE TABLE #AllocationData (
        object_id INT NOT NULL,
        index_id INT NOT NULL,
        partition_id BIGINT NOT NULL,
        total_pages BIGINT NOT NULL,
        used_pages BIGINT NOT NULL,
        data_pages BIGINT NOT NULL,
        rows BIGINT NOT NULL,
        INDEX IX_ObjectIndex (object_id, index_id)
    );
    
    -- Tabela para informações de fragmentação (cache para evitar múltiplas chamadas)
    CREATE TABLE #FragmentationData (
        object_id INT NOT NULL,
        index_id INT NOT NULL,
        avg_fragmentation_in_percent DECIMAL(5,2),
        page_count BIGINT,
        PRIMARY KEY CLUSTERED (object_id, index_id)
    );
    
    -- Tabela final para tabelas
    CREATE TABLE #TableSizes (
        SchemaName VARCHAR(128),
        TableName VARCHAR(128),
        CountRow BIGINT,
        ReservedKB BIGINT,
        DataKB BIGINT,
        IndexKB BIGINT,
        UnusedKB BIGINT,
        TotalSizeMB DECIMAL(18,2),
        DataSizeMB DECIMAL(18,2),
        IndexSizeMB DECIMAL(18,2),
        AvgBytesPerRow DECIMAL(18,2),
        IsSystemTable BIT,
        INDEX IX_Size (TotalSizeMB DESC),
        INDEX IX_Rows (CountRow DESC)
    );
    
    -- Tabela final para índices
    CREATE TABLE #IndexSizes (
        SchemaName VARCHAR(128),
        TableName VARCHAR(128),
        IndexName VARCHAR(128),
        IndexType VARCHAR(50),
        SizeKB BIGINT,
        SizeMB DECIMAL(18,2),
        CountRow BIGINT,
        IsUnique BIT,
        IsPrimaryKey BIT,
        Fill_Factor TINYINT,
        IsDisabled BIT,
        FragmentationPercent DECIMAL(5,2),
        PageCount BIGINT,
        WastedSpaceMB DECIMAL(18,2),
        PotentialSavingsMB DECIMAL(18,2),
        INDEX IX_Fragmentation (FragmentationPercent DESC),
        INDEX IX_Size (SizeMB DESC)
    );
    
    PRINT '⏳ Coletando metadados base dos objetos...';
    
    -- OTIMIZAÇÃO: Primeiro, coletar apenas os objetos que atendem aos critérios
    INSERT INTO #BaseObjects (object_id, schema_id, SchemaName, TableName, IsSystemTable)
    SELECT 
        t.object_id,
        t.schema_id,
        s.name AS SchemaName,
        t.name AS TableName,
        CASE 
            WHEN s.name IN ('sys', 'INFORMATION_SCHEMA') OR t.is_ms_shipped = 1 THEN 1
            ELSE 0
        END AS IsSystemTable
    FROM sys.tables t
    INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
    WHERE 
        (@TableName IS NULL OR t.name LIKE '%' + @TableName + '%')
        AND (@IncludeSystemTables = 1 OR 
             (s.name NOT IN ('sys', 'INFORMATION_SCHEMA') AND t.is_ms_shipped = 0));
    
    PRINT '⏳ Coletando dados de alocação otimizados...';
    
    -- OTIMIZAÇÃO: Coletar dados de alocação apenas para objetos filtrados
    INSERT INTO #AllocationData (object_id, index_id, partition_id, total_pages, used_pages, data_pages, rows)
    SELECT 
        i.object_id,
        i.index_id,
        p.partition_id,
        SUM(a.total_pages) AS total_pages,
        SUM(a.used_pages) AS used_pages,
        SUM(a.data_pages) AS data_pages,
        p.rows
    FROM #BaseObjects bo
    INNER JOIN sys.indexes i ON bo.object_id = i.object_id
    INNER JOIN sys.partitions p ON i.object_id = p.object_id AND i.index_id = p.index_id
    INNER JOIN sys.allocation_units a ON p.partition_id = a.container_id
    GROUP BY i.object_id, i.index_id, p.partition_id, p.rows;
    
    PRINT '⏳ Processando informações de tamanho das tabelas...';
    
    -- OTIMIZAÇÃO: Usar dados pré-processados para calcular tamanhos das tabelas
    INSERT INTO #TableSizes (
        SchemaName, TableName, CountRow, ReservedKB, DataKB, 
        IndexKB, UnusedKB, TotalSizeMB, DataSizeMB, IndexSizeMB, 
        AvgBytesPerRow, IsSystemTable
    )
    SELECT 
        bo.SchemaName,
        bo.TableName,
        ad.rows AS CountRow,
        ad.total_pages * 8 AS ReservedKB,
        ad.used_pages * 8 AS DataKB,
        (ad.total_pages - ad.used_pages) * 8 AS IndexKB,
        (ad.total_pages - ad.data_pages) * 8 AS UnusedKB,
        ROUND(ad.total_pages * 8.0 / 1024, 2) AS TotalSizeMB,
        ROUND(ad.data_pages * 8.0 / 1024, 2) AS DataSizeMB,
        ROUND((ad.used_pages - ad.data_pages) * 8.0 / 1024, 2) AS IndexSizeMB,
        -- Cálculo otimizado da média de bytes por linha
        CASE 
            WHEN ad.rows > 0 THEN ROUND((ad.data_pages * 8192.0) / ad.rows, 2)
            ELSE 0
        END AS AvgBytesPerRow,
        bo.IsSystemTable
    FROM #BaseObjects bo
    INNER JOIN (
        SELECT 
            object_id,
            SUM(total_pages) AS total_pages,
            SUM(used_pages) AS used_pages,
            SUM(data_pages) AS data_pages,
            MAX(rows) AS rows  -- MAX porque todas as partições de uma tabela têm o mesmo valor
        FROM #AllocationData
        WHERE index_id <= 1  -- Apenas clustered index ou heap
        GROUP BY object_id
    ) ad ON bo.object_id = ad.object_id
    
    -- OTIMIZAÇÃO: Coletar informações dos índices NonClustered e ColumnStore
    IF @ShowIndexDetails = 1
    BEGIN
        PRINT '⏳ Coletando dados de fragmentação (otimizado)...';
        
        -- OTIMIZAÇÃO: Coletar fragmentação apenas para índices relevantes (com agregação para evitar duplicatas)
        INSERT INTO #FragmentationData (object_id, index_id, avg_fragmentation_in_percent, page_count)
        SELECT 
            ips.object_id,
            ips.index_id,
            AVG(ips.avg_fragmentation_in_percent) as avg_fragmentation_in_percent,
            SUM(ips.page_count) as page_count
        FROM sys.dm_db_index_physical_stats(@DatabaseId, NULL, NULL, NULL, 'LIMITED') ips
        INNER JOIN #BaseObjects bo ON ips.object_id = bo.object_id
        INNER JOIN sys.indexes i ON ips.object_id = i.object_id AND ips.index_id = i.index_id
        WHERE i.type IN (2, 5, 6)  -- Apenas índices que nos interessam
            AND i.name IS NOT NULL
            AND ips.alloc_unit_type_desc = 'IN_ROW_DATA'  -- Apenas dados em linha
        GROUP BY ips.object_id, ips.index_id;  -- Agregar para evitar duplicatas
        
        PRINT '⏳ Processando informações dos índices NonClustered e ColumnStore...';
        
        -- OTIMIZAÇÃO: Usar dados pré-processados para índices
        INSERT INTO #IndexSizes (
            SchemaName, TableName, IndexName, IndexType, SizeKB, SizeMB,
            CountRow, IsUnique, IsPrimaryKey, Fill_Factor, IsDisabled,
            FragmentationPercent, PageCount, WastedSpaceMB, PotentialSavingsMB
        )
        SELECT 
            bo.SchemaName,
            bo.TableName,
            i.name AS IndexName,
            CASE i.type
                WHEN 0 THEN 'HEAP'
                WHEN 1 THEN 'CLUSTERED'
                WHEN 2 THEN 'NONCLUSTERED'
                WHEN 3 THEN 'XML'
                WHEN 4 THEN 'SPATIAL'
                WHEN 5 THEN 'CLUSTERED COLUMNSTORE'
                WHEN 6 THEN 'NONCLUSTERED COLUMNSTORE'
                WHEN 7 THEN 'NONCLUSTERED HASH'
                ELSE 'UNKNOWN'
            END AS IndexType,
            ad.total_pages * 8 AS SizeKB,
            ROUND(ad.total_pages * 8.0 / 1024, 2) AS SizeMB,
            ad.rows AS CountRow,
            i.is_unique AS IsUnique,
            i.is_primary_key AS IsPrimaryKey,
            i.fill_factor AS Fill_Factor,
            i.is_disabled AS IsDisabled,
            -- Informações de fragmentação otimizadas
            ISNULL(fd.avg_fragmentation_in_percent, 0) AS FragmentationPercent,
            ISNULL(fd.page_count, 0) AS PageCount,
            -- Cálculo otimizado do espaço desperdiçado
            CASE 
                WHEN fd.avg_fragmentation_in_percent > 30 THEN 
                    ROUND((ad.total_pages * 8.0 / 1024) * (fd.avg_fragmentation_in_percent / 100), 2)
                ELSE 0
            END AS WastedSpaceMB,
            -- Potencial de economia otimizado
            CASE 
                WHEN fd.avg_fragmentation_in_percent > 30 THEN 
                    ROUND((ad.total_pages * 8.0 / 1024) * ((fd.avg_fragmentation_in_percent - 5) / 100), 2)
                WHEN fd.avg_fragmentation_in_percent > 10 THEN 
                    ROUND((ad.total_pages * 8.0 / 1024) * ((fd.avg_fragmentation_in_percent - 5) / 100) * 0.5, 2)
                ELSE 0
            END AS PotentialSavingsMB
        FROM #BaseObjects bo
        INNER JOIN sys.indexes i ON bo.object_id = i.object_id
        INNER JOIN (
            SELECT 
                object_id,
                index_id,
                SUM(total_pages) AS total_pages,
                MAX(rows) AS rows
            FROM #AllocationData
            GROUP BY object_id, index_id
        ) ad ON i.object_id = ad.object_id AND i.index_id = ad.index_id
        LEFT JOIN #FragmentationData fd ON i.object_id = fd.object_id AND i.index_id = fd.index_id
        WHERE 
            i.type IN (2, 5, 6)  -- NonClustered, Clustered ColumnStore e NonClustered ColumnStore
            AND i.name IS NOT NULL
            AND ROUND(ad.total_pages * 8.0 / 1024, 2) >= (@MinSizeMB / 10); -- Filtro mais flexível para índices
    END;
    
    -- Calcular totais para resumo
    SELECT 
        @TotalTables = COUNT(*),
        @TotalSizeGB = ROUND(SUM(TotalSizeMB) / 1024, 2)
    FROM #TableSizes;
    
    SELECT @TotalIndexes = COUNT(*) FROM #IndexSizes;
    
    PRINT '';
    PRINT '📊 RESUMO EXECUTIVO:';
    PRINT CONCAT('  • Total de tabelas analisadas: ', @TotalTables);
    PRINT CONCAT('  • Total de índices NonClustered/ColumnStore: ', @TotalIndexes);
    PRINT CONCAT('  • Tamanho total das tabelas: ', @TotalSizeGB, ' GB');
    PRINT '';
    
    -- ========================================
    -- PRIMEIRO RESULTADO: TAMANHO DO BANCO DE DADOS
    -- ========================================
    PRINT '💾 TAMANHO TOTAL DO BANCO DE DADOS:';
    
    SELECT 
        '💾 BANCO DE DADOS' AS Tipo,
        DB_NAME() AS [Nome do Banco],
        -- Tamanho dos arquivos de dados
        FORMAT(SUM(CASE WHEN type = 0 THEN size END) * 8.0 / 1024, 'N2') + ' MB' AS [Tamanho Dados],
        -- Tamanho dos arquivos de log
        FORMAT(SUM(CASE WHEN type = 1 THEN size END) * 8.0 / 1024, 'N2') + ' MB' AS [Tamanho Log],
        -- Tamanho total do banco
        FORMAT(SUM(size) * 8.0 / 1024, 'N2') + ' MB' AS [Tamanho Total],
        -- Tamanho total em GB
        FORMAT(SUM(size) * 8.0 / 1024 / 1024, 'N2') + ' GB' AS [Tamanho Total GB],
        -- Espaço usado nos arquivos de dados
        FORMAT(SUM(CASE WHEN type = 0 THEN FILEPROPERTY(name, 'SpaceUsed') END) * 8.0 / 1024, 'N2') + ' MB' AS [Espaço Usado Dados],
        -- Espaço livre nos arquivos de dados
        FORMAT(SUM(CASE WHEN type = 0 THEN (size - FILEPROPERTY(name, 'SpaceUsed')) END) * 8.0 / 1024, 'N2') + ' MB' AS [Espaço Livre Dados],
        -- Percentual de uso
        FORMAT(
            (SUM(CASE WHEN type = 0 THEN FILEPROPERTY(name, 'SpaceUsed') END) * 100.0) / 
            NULLIF(SUM(CASE WHEN type = 0 THEN size END), 0), 
            'N1'
        ) + '%' AS [% Uso Dados],
        -- Quantidade de arquivos
        COUNT(*) AS [Qtd Arquivos],
        -- Quantidade de arquivos de dados
        SUM(CASE WHEN type = 0 THEN 1 ELSE 0 END) AS [Arquivos Dados],
        -- Quantidade de arquivos de log
        SUM(CASE WHEN type = 1 THEN 1 ELSE 0 END) AS [Arquivos Log]
    FROM sys.database_files;
    
    PRINT '';
    
    -- Relatório principal: Informações das tabelas
    PRINT '📋 RELATÓRIO DE TAMANHO DAS TABELAS:';
    
    SELECT 
        '📊 TABELAS' AS Tipo,
        SchemaName AS [Schema],
        TableName AS [Tabela],
        FORMAT(CountRow, 'N0') AS [Qtd Registros],
        FORMAT(TotalSizeMB, 'N2') + ' MB' AS [Tamanho Total],
        FORMAT(DataSizeMB, 'N2') + ' MB' AS [Tamanho Dados],
        FORMAT(IndexSizeMB, 'N2') + ' MB' AS [Tamanho Índices],
        FORMAT(AvgBytesPerRow, 'N2') + ' bytes' AS [Média Bytes/Linha],
        CASE 
            WHEN CountRow > 0 THEN FORMAT((TotalSizeMB * 1024 * 1024) / CountRow, 'N2') + ' bytes'
            ELSE 'N/A'
        END AS [Bytes por Registro],
        CASE 
            WHEN TotalSizeMB > 1024 THEN '🔴 Grande'
            WHEN TotalSizeMB > 100 THEN '🟡 Média'
            ELSE '🟢 Pequena'
        END AS [Classificação]
    FROM #TableSizes
    ORDER BY 
        CASE @OrderBy
            WHEN 'SIZE' THEN TotalSizeMB
            WHEN 'ROWS' THEN CAST(CountRow AS DECIMAL(18,2))
            WHEN 'NAME' THEN 0
        END DESC,
        CASE @OrderBy
            WHEN 'NAME' THEN TableName
            ELSE ''
        END ASC;
    
    -- Relatório de índices NonClustered (se solicitado)
    IF @ShowIndexDetails = 1 AND @TotalIndexes > 0
    BEGIN
        PRINT '';
        PRINT '🗂️  RELATÓRIO DE ÍNDICES NONCLUSTERED E COLUMNSTORE:';
        
        SELECT 
            '🗂️ ÍNDICES NC/CS' AS Tipo,
            SchemaName AS [Schema],
            TableName AS [Tabela],
            IndexName AS [Nome do Índice],
            IndexType AS [Tipo],
            FORMAT(SizeMB, 'N2') + ' MB' AS [Tamanho],
            FORMAT(CountRow, 'N0') AS [Registros],
            FORMAT(FragmentationPercent, 'N1') + '%' AS [Fragmentação],
            FORMAT(PageCount, 'N0') AS [Páginas],
            FORMAT(WastedSpaceMB, 'N2') + ' MB' AS [Espaço Desperdiçado],
            FORMAT(PotentialSavingsMB, 'N2') + ' MB' AS [Economia Potencial],
            CASE WHEN IsUnique = 1 THEN 'SIM' ELSE 'NÃO' END AS [Único],
            CASE 
                WHEN Fill_Factor = 0 THEN '100%'
                ELSE CAST(Fill_Factor AS VARCHAR(3)) + '%'
            END AS [Fill Factor],
            CASE WHEN IsDisabled = 1 THEN '❌ Desabilitado' ELSE '✅ Ativo' END AS [Status],
            CASE 
                WHEN FragmentationPercent > 30 THEN '🔴 Crítica'
                WHEN FragmentationPercent > 10 THEN '🟡 Moderada'
                WHEN FragmentationPercent > 5 THEN '🟢 Baixa'
                ELSE '✅ Ótima'
            END AS [Status Fragmentação],
            CASE 
                WHEN SizeMB > 100 THEN '🔴 Grande'
                WHEN SizeMB > 10 THEN '🟡 Médio'
                ELSE '🟢 Pequeno'
            END AS [Classificação Tamanho]
        FROM #IndexSizes
        ORDER BY FragmentationPercent DESC, SizeMB DESC, TableName, IndexName;
        
        -- Top 10 maiores índices NonClustered e ColumnStore
        PRINT '';
        PRINT '🏆 TOP 10 MAIORES ÍNDICES NONCLUSTERED E COLUMNSTORE:';
        
        SELECT TOP 10
            '🏆 TOP ÍNDICES' AS Tipo,
            CONCAT(SchemaName, '.', TableName) AS [Tabela],
            IndexName AS [Índice],
            FORMAT(SizeMB, 'N2') + ' MB' AS [Tamanho],
            FORMAT(FragmentationPercent, 'N1') + '%' AS [Fragmentação],
            FORMAT(PotentialSavingsMB, 'N2') + ' MB' AS [Economia Potencial],
            FORMAT((SizeMB / @TotalSizeGB) * 100, 'N2') + '%' AS [% do Total]
        FROM #IndexSizes
        WHERE @TotalSizeGB > 0
        ORDER BY SizeMB DESC;
        
        -- Relatório de índices com maior fragmentação
        PRINT '';
        PRINT '⚠️  TOP 10 ÍNDICES MAIS FRAGMENTADOS:';
        
        SELECT TOP 10
            '⚠️ FRAGMENTADOS' AS Tipo,
            CONCAT(SchemaName, '.', TableName) AS [Tabela],
            IndexName AS [Índice],
            FORMAT(FragmentationPercent, 'N1') + '%' AS [Fragmentação],
            FORMAT(SizeMB, 'N2') + ' MB' AS [Tamanho],
            FORMAT(PotentialSavingsMB, 'N2') + ' MB' AS [Economia Potencial],
            CASE 
                WHEN FragmentationPercent > 30 THEN 'REBUILD URGENTE'
                WHEN FragmentationPercent > 10 THEN 'REORGANIZE'
                ELSE 'OK'
            END AS [Recomendação]
        FROM #IndexSizes
        WHERE FragmentationPercent > 5
        ORDER BY FragmentationPercent DESC;
        
        -- Resumo de economia potencial
        DECLARE @TotalWastedMB DECIMAL(18,2);
        DECLARE @TotalPotentialSavingsMB DECIMAL(18,2);
        
        SELECT 
            @TotalWastedMB = SUM(WastedSpaceMB),
            @TotalPotentialSavingsMB = SUM(PotentialSavingsMB)
        FROM #IndexSizes;
        
        PRINT '';
        PRINT '💰 RESUMO DE ECONOMIA POTENCIAL:';
        PRINT CONCAT('  • Total de espaço desperdiçado: ', FORMAT(@TotalWastedMB, 'N2'), ' MB');
        PRINT CONCAT('  • Economia potencial com rebuild: ', FORMAT(@TotalPotentialSavingsMB, 'N2'), ' MB');
        PRINT CONCAT('  • Percentual de economia: ', FORMAT((@TotalPotentialSavingsMB / @TotalSizeGB) * 100, 'N2'), '%');
    END;
    
    -- Análise de densidade de dados
    PRINT '';
    PRINT '📈 ANÁLISE DE DENSIDADE DE DADOS:';
    
    SELECT 
        '📈 DENSIDADE' AS Tipo,
        SchemaName AS [Schema],
        TableName AS [Tabela],
        FORMAT(CountRow, 'N0') AS [Registros],
        FORMAT(AvgBytesPerRow, 'N0') + ' bytes' AS [Bytes/Linha],
        CASE 
            WHEN AvgBytesPerRow > 8000 THEN '🔴 Muito Densa'
            WHEN AvgBytesPerRow > 2000 THEN '🟡 Densa'
            WHEN AvgBytesPerRow > 500 THEN '🟢 Normal'
            ELSE '🔵 Esparsa'
        END AS [Classificação Densidade],
        CASE 
            WHEN CountRow > 10000000 THEN '🔴 Muito Grande'
            WHEN CountRow > 1000000 THEN '🟡 Grande'
            WHEN CountRow > 100000 THEN '🟢 Média'
            ELSE '🔵 Pequena'
        END AS [Classificação Volume]
    FROM #TableSizes
    WHERE CountRow > 0
    ORDER BY AvgBytesPerRow DESC;
    
    -- Resumo por schema
    PRINT '';
    PRINT '📁 RESUMO POR SCHEMA:';
    
    SELECT 
        '📁 SCHEMAS' AS Tipo,
        SchemaName AS [Schema],
        COUNT(*) AS [Qtd Tabelas],
        FORMAT(SUM(CountRow), 'N0') AS [Total Registros],
        FORMAT(SUM(TotalSizeMB), 'N2') + ' MB' AS [Tamanho Total],
        FORMAT(AVG(AvgBytesPerRow), 'N2') + ' bytes' AS [Média Bytes/Linha],
        FORMAT((SUM(TotalSizeMB) / @TotalSizeGB) * 100, 'N1') + '%' AS [% do Banco]
    FROM #TableSizes
    WHERE @TotalSizeGB > 0
    GROUP BY SchemaName
    ORDER BY SUM(TotalSizeMB) DESC;
    
    -- Log final
    DECLARE @EndTime DATETIME2 = GETDATE();
    DECLARE @ExecutionTimeMs INT = DATEDIFF(MILLISECOND, @StartTime, @EndTime);
    
    PRINT '';
    PRINT '═══════════════════════════════════════════════════════════════════════════════';
    PRINT CONCAT('✅ Análise concluída em ', @ExecutionTimeMs, 'ms');
    PRINT CONCAT('📊 Resumo: ', @TotalTables, ' tabelas, ', @TotalIndexes, ' índices NC/CS, ', @TotalSizeGB, ' GB total');
    PRINT '═══════════════════════════════════════════════════════════════════════════════';
    
    -- OTIMIZAÇÃO: Limpeza de todas as tabelas temporárias
    DROP TABLE #BaseObjects;
    DROP TABLE #AllocationData;
    DROP TABLE #FragmentationData;
    DROP TABLE #TableSizes;
    DROP TABLE #IndexSizes;
END;
GO

-- Exemplo de uso da procedure
/*
-- Análise completa de todas as tabelas
EXEC HealthCheck.uspSizeObjects;

-- Análise de uma tabela específica
EXEC HealthCheck.uspSizeObjects @TableName = 'MinhaTabela';

-- Análise apenas de tabelas grandes (> 10MB)
EXEC HealthCheck.uspSizeObjects @MinSizeMB = 10;

-- Análise sem detalhes de índices para melhor performance
EXEC HealthCheck.uspSizeObjects @ShowIndexDetails = 0;

-- Análise ordenada por quantidade de registros
EXEC HealthCheck.uspSizeObjects @OrderBy = 'ROWS';
*/