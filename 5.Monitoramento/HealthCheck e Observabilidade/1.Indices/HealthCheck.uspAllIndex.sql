    -- =============================================
    -- Procedure: HealthCheck.uspAllIndex (OTIMIZADA)
    -- Descrição: Análise completa de índices com performance melhorada
    -- Autor: Wesley David Santos (Otimizada)
    -- =============================================

    CREATE OR ALTER PROCEDURE HealthCheck.uspAllIndex
    (
        @typeIndex VARCHAR(40) = NULL,          -- Tipo do índice (CLUSTERED/NONCLUSTERED)
        @SomenteUsado BIT = NULL,                -- Filtrar apenas índices usados
        @TableIsEmpty BIT = NULL,                -- Considerar tabelas vazias
        @ObjectName VARCHAR(128) = NULL,         -- Nome específico da tabela
        @BadIndex BIT = NULL,                    -- Filtrar índices ruins
        @percentualAproveitamento SMALLINT = 10, -- Percentual mínimo de aproveitamento
        @TableObjectIds TableIntegerIds READONLY -- IDs específicos de tabelas
    )
    AS
    BEGIN
        SET NOCOUNT ON;
        SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
        

		 --DECLARE @typeIndex VARCHAR(40) = NULL,          -- Tipo do índice (CLUSTERED/NONCLUSTERED)
   --     @SomenteUsado BIT = NULL,                -- Filtrar apenas índices usados
   --     @TableIsEmpty BIT = NULL,                -- Considerar tabelas vazias
   --     @ObjectName VARCHAR(128) = NULL,         -- Nome específico da tabela
   --     @BadIndex BIT = NULL,                    -- Filtrar índices ruins
   --     @percentualAproveitamento SMALLINT = 10; -- Percentual mínimo de aproveitamento
   --     --@TableObjectIds TableIntegerIds READONLY -- IDs específicos de tabelas


        -- Validação e configuração de parâmetros
        SET @percentualAproveitamento = ISNULL(NULLIF(@percentualAproveitamento, 0), 10);
        
        DECLARE @IndexType TINYINT = CASE 
            WHEN @typeIndex = 'NONCLUSTERED' THEN 2
            WHEN @typeIndex = 'CLUSTERED' THEN 1 
            ELSE NULL 
        END;
        

				DROP TABLE IF EXISTS #DadosBase;
				CREATE TABLE #DadosBase
				(
					[object_id] INT,
					[SchemaName] NVARCHAR(128),
					[TableName] NVARCHAR(128),
					[RowsInTable] BIGINT,
					[TypeIndex] TINYINT,
					[index_id] INT,
					[IndexName] NVARCHAR(128),
					[IndexsizeKB] BIGINT,
					[IndexsizeMB] DECIMAL(18, 2),
					[IsUnique] BIT,
					[IgnoreDupKey] BIT,
					[IsPrimaryKey] BIT,
					[IsUniqueConstraint] BIT,
					[FillFact] TINYINT,
					[AllowRowLocks] BIT,
					[AllowPageLocks] BIT,
					[HasFilter] BIT
					PRIMARY KEY(object_id,index_id)
				);

		INSERT INTO #DadosBase
		 SELECT 
                i.object_id,
                SCHEMA_NAME(t.schema_id) AS SchemaName,
                t.name AS TableName,
                si.rowcnt AS RowsInTable,
                i.type AS TypeIndex,
                i.index_id,
                i.name AS IndexName,
                -- Tamanho do índice
                SUM(a.used_pages) * 8 AS IndexsizeKB,
                CAST(SUM(a.used_pages) * 8.0 / 1024 AS DECIMAL(18,2)) AS IndexsizeMB,
                
                ---- Estatísticas de uso
                --CASE WHEN ius.object_id IS NULL THEN 0 ELSE 1 END AS Usado,
                --ISNULL(ius.user_seeks, 0) AS UserSeeks,
                --ISNULL(ius.user_scans, 0) AS UserScans,
                --ISNULL(ius.user_lookups, 0) AS UserLookups,
                --ISNULL(ius.user_updates, 0) AS UserUpdates,
                
                ---- Cálculos de performance
                --ISNULL(ius.user_seeks + ius.user_scans + ius.user_lookups, 0) AS Reads,
                --ISNULL(ius.user_updates, 0) AS Write,
                
                ---- Page splits (incorporado diretamente)
                --ISNULL(ios.leaf_allocation_count, 0) AS CountPageSplitPage,
                
                -- Propriedades do índice
                i.is_unique AS IsUnique,
                i.ignore_dup_key AS IgnoreDupKey,
                i.is_primary_key AS IsPrimaryKey,
                i.is_unique_constraint AS IsUniqueConstraint,
                i.fill_factor AS FillFact,
                i.allow_row_locks AS AllowRowLocks,
                i.allow_page_locks AS AllowPageLocks,
                i.has_filter AS HasFilter
                
            FROM sys.indexes i
            INNER JOIN sys.tables t ON i.object_id = t.object_id
            INNER JOIN sys.sysindexes si ON si.id = i.object_id AND si.indid = i.index_id
			 INNER JOIN sys.partitions p ON i.object_id = p.object_id AND i.index_id = p.index_id
            INNER JOIN sys.allocation_units a ON a.container_id = p.partition_id
			 -- Filtros básicos
            WHERE (@IndexType IS NULL OR i.type = @IndexType)
            AND (@ObjectName IS NULL OR CONCAT(SCHEMA_NAME(t.schema_id), '.', t.name) LIKE '%' + @ObjectName + '%')
            AND (NOT EXISTS(SELECT 1 FROM @TableObjectIds) OR i.object_id IN (SELECT Id FROM @TableObjectIds))
           
			GROUP BY SCHEMA_NAME(t.schema_id),
                     i.object_id,
                     t.name,
                     si.rowcnt,
                     i.type,
                     i.index_id,
                     i.name,
                     i.is_unique,
                     i.ignore_dup_key,
                     i.is_primary_key,
                     i.is_unique_constraint,
                     i.fill_factor,
                     i.allow_row_locks,
                     i.allow_page_locks,
                     i.has_filter

       ; WITH IndexData AS (
            -- Dados básicos dos índices com métricas de uso
            SELECT 
                i.object_id,
                i.SchemaName,
                i.TableName,
                i.RowsInTable,
                i.TypeIndex,
                i.index_id,
                i.IndexName,
                -- Tamanho do índice
                 i.IndexsizeKB,
                 i.IndexsizeMB,
                
                 --Estatísticas de uso
                CASE WHEN ius.object_id IS NULL THEN 0 ELSE 1 END AS Usado,
                ISNULL(ius.user_seeks, 0) AS UserSeeks,
                ISNULL(ius.user_scans, 0) AS UserScans,
                ISNULL(ius.user_lookups, 0) AS UserLookups,
                ISNULL(ius.user_updates, 0) AS UserUpdates,
                
                ---- Cálculos de performance
                ISNULL(ius.user_seeks + ius.user_scans + ius.user_lookups, 0) AS Reads,
                ISNULL(ius.user_updates, 0) AS Write,
                
                ---- Page splits (incorporado diretamente)
                ISNULL(ios.leaf_allocation_count, 0) AS CountPageSplitPage,
                
                -- Propriedades do índice
                i.IsUnique AS IsUnique,
                i.IgnoreDupKey AS IgnoreDupKey,
                i.IsPrimaryKey AS IsPrimaryKey,
                i.IsUniqueConstraint AS IsUniqueConstraint,
                i.FillFact AS FillFact,
                i.AllowRowLocks AS AllowRowLocks,
                i.AllowPageLocks AS AllowPageLocks,
                i.HasFilter AS HasFilter
                
            FROM #DadosBase i
            LEFT JOIN sys.dm_db_index_usage_stats ius ON i.object_id = ius.object_id 
                AND i.index_id = ius.index_id 
                AND ius.database_id = DB_ID()
            LEFT JOIN (
                SELECT object_id, index_id, SUM(leaf_allocation_count) AS leaf_allocation_count
                FROM sys.dm_db_index_operational_stats(DB_ID(), NULL, NULL, NULL)
                GROUP BY object_id, index_id
            ) ios ON i.object_id = ios.object_id AND i.index_id = ios.index_id
        ),
        
        IndexWithMetrics AS (
            -- Cálculo de métricas avançadas
            SELECT *,
                -- Total de acessos por tabela para cálculo de aproveitamento
                SUM(Reads) OVER (PARTITION BY object_id) AS TotalAcessoTabela,
                
                -- Tamanho total por tipo de índice
                SUM(IndexsizeMB) OVER (PARTITION BY object_id, TypeIndex) AS IndexSizePorTipoMB
                
            FROM IndexData
        ),
        
        -- CTEs separadas para otimizar performance das colunas
        IndexKeyColumns AS (
            -- Colunas chave dos índices
            SELECT 
                ic.object_id,
                ic.index_id,
                STRING_AGG(c.name, ', ') WITHIN GROUP (ORDER BY ic.key_ordinal) AS Chave
            FROM sys.index_columns ic
            INNER JOIN sys.columns c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
            WHERE ic.is_included_column = 0
            GROUP BY ic.object_id, ic.index_id
        ),
        
        IndexIncludedColumns AS (
            -- Colunas incluídas dos índices
            SELECT 
                ic.object_id,
                ic.index_id,
                STRING_AGG(c.name, ', ') WITHIN GROUP (ORDER BY c.column_id) AS ColunasIncluidas
            FROM sys.index_columns ic
            INNER JOIN sys.columns c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
            WHERE ic.is_included_column = 1
            GROUP BY ic.object_id, ic.index_id
        )
        
        -- ═══════════════════════════════════════════════════════════════
        -- 📊 RESULTADO FINAL COM TODOS OS CÁLCULOS
        -- ═══════════════════════════════════════════════════════════════
        
        SELECT 
            idx.object_id AS ObjectId,
            QUOTENAME(idx.SchemaName) + '.' + QUOTENAME(idx.TableName) AS ObjectName,
            idx.RowsInTable,
            idx.IndexName,
            idx.Usado,
            idx.UserSeeks,
            idx.UserScans,
            idx.UserLookups,
            idx.UserUpdates,
            idx.Reads,
            idx.Write,
            idx.CountPageSplitPage,
            
            -- Percentual de aproveitamento
            CAST(
                CASE WHEN idx.TotalAcessoTabela = 0 THEN 0
                    ELSE (idx.Reads * 100.0 / idx.TotalAcessoTabela)
                END AS DECIMAL(18,2)
            ) AS PercAproveitamento,
            
            -- Percentual de custo médio (writes vs reads)
            CAST(
                CASE WHEN idx.Reads = 0 THEN 0
                    ELSE (idx.Write * 1.0 / idx.Reads)
                END AS DECIMAL(18,2)
            ) AS PercCustoMedio,
            
            -- Identificação de índice ruim (simplificada)
            CASE WHEN idx.index_id > 1 
                    AND idx.Reads > 0 
                    AND (idx.Write * 1.0 / idx.Reads) > 1
                    AND (idx.Reads * 100.0 / NULLIF(idx.TotalAcessoTabela, 0)) < @percentualAproveitamento
                THEN 1 
                ELSE 0 
            END AS IsBadIndex,
            
            idx.index_id AS IndexId,
            idx.IndexsizeKB,
            idx.IndexsizeMB,
            idx.IndexSizePorTipoMB,
            
            -- Colunas do índice
            ISNULL(ikc.Chave, '') AS Chave,
            ISNULL(iic.ColunasIncluidas, '') AS ColunasIncluidas,
            
            -- Propriedades do índice
            idx.IsUnique,
            idx.IgnoreDupKey,
            idx.IsPrimaryKey,
            idx.IsUniqueConstraint,
            idx.FillFact,
            idx.AllowRowLocks,
            idx.AllowPageLocks,
            idx.HasFilter,
            idx.TypeIndex
            
        FROM IndexWithMetrics idx
        LEFT JOIN IndexKeyColumns ikc ON idx.object_id = ikc.object_id AND idx.index_id = ikc.index_id
        LEFT JOIN IndexIncludedColumns iic ON idx.object_id = iic.object_id AND idx.index_id = iic.index_id
        
        -- ═══════════════════════════════════════════════════════════════
        -- 🎯 FILTROS FINAIS SIMPLIFICADOS
        -- ═══════════════════════════════════════════════════════════════
        WHERE 
            -- Filtro de índices usados
            (@SomenteUsado IS NULL OR 
            (@SomenteUsado = 1 AND idx.Usado = 1) OR 
            (@SomenteUsado = 0 AND idx.Usado = 0))
            
            -- Filtro de tabelas vazias
            AND (@TableIsEmpty IS NULL OR 
                (@TableIsEmpty = 1 AND idx.RowsInTable = 0) OR 
                (@TableIsEmpty = 0 AND idx.RowsInTable > 0))
            
            -- Filtro de índices ruins (simplificado)
            AND (@BadIndex IS NULL OR 
                (@BadIndex = 1 AND 
                idx.index_id > 1 AND 
                idx.Reads > 0 AND 
                (idx.Write * 1.0 / idx.Reads) > 1 AND 
                (idx.Reads * 100.0 / NULLIF(idx.TotalAcessoTabela, 0)) < @percentualAproveitamento) OR 
                (@BadIndex = 0 AND NOT (
                idx.index_id > 1 AND 
                idx.Reads > 0 AND 
                (idx.Write * 1.0 / idx.Reads) > 1 AND 
                (idx.Reads * 100.0 / NULLIF(idx.TotalAcessoTabela, 0)) < @percentualAproveitamento)))
        
        ORDER BY 
            idx.SchemaName, 
            idx.TableName, 
            idx.index_id;
            
    END;
    GO