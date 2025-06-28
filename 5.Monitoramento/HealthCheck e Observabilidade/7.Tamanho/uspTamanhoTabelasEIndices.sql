-- =============================================
-- Procedure: uspTamanhoTabelasEIndices
-- Descrição: Retorna informações de tamanho das tabelas e índices
-- Autor: Wesley
-- Data: 2024
-- Compatível com: SQL Server e Azure SQL Database
-- =============================================

CREATE OR ALTER PROCEDURE HealthCheck.uspTamanhoTabelasEIndices
    @MostrarApenasTop20 BIT = 0,           -- Se 1, mostra apenas top 20 tabelas
    @SchemaFiltro NVARCHAR(128) = NULL,    -- Filtro por schema específico
    @TabelaFiltro NVARCHAR(128) = NULL     -- Filtro por tabela específica
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        -- =============================================
        -- RESULTADO 1: INFORMAÇÕES DAS TABELAS
        -- =============================================
        
        PRINT 'Executando consulta de tamanho das tabelas...';
        
        -- Query principal das tabelas com filtros opcionais
        SELECT 
            s.name AS [Schema],
            t.name AS [Tabela],
            p.rows AS [Linhas],
            CAST(ROUND(((SUM(a.total_pages) * 8) / 1024.00), 2) AS NUMERIC(36, 2)) AS [Tamanho_MB],
            CAST(ROUND(((SUM(a.total_pages) * 8) / 1024.00 / 1024.00), 2) AS NUMERIC(36, 2)) AS [Tamanho_GB],
            CAST(ROUND(((SUM(a.used_pages) * 8) / 1024.00), 2) AS NUMERIC(36, 2)) AS [Usado_MB],
            CAST(ROUND(((SUM(a.used_pages) * 8) / 1024.00 / 1024.00), 2) AS NUMERIC(36, 2)) AS [Usado_GB],
            CAST(ROUND(((SUM(a.total_pages) - SUM(a.used_pages)) * 8) / 1024.00, 2) AS NUMERIC(36, 2)) AS [Livre_MB]
        FROM 
            sys.tables t
        INNER JOIN 
            sys.indexes i ON t.OBJECT_ID = i.object_id
        INNER JOIN 
            sys.partitions p ON i.object_id = p.OBJECT_ID AND i.index_id = p.index_id
        INNER JOIN 
            sys.allocation_units a ON p.partition_id = a.container_id
        LEFT OUTER JOIN 
            sys.schemas s ON t.schema_id = s.schema_id
        WHERE 
            t.NAME NOT LIKE 'dt%' 
            AND t.is_ms_shipped = 0
            AND i.OBJECT_ID > 255
            -- Aplicar filtros opcionais
            AND (@SchemaFiltro IS NULL OR s.name = @SchemaFiltro)
            AND (@TabelaFiltro IS NULL OR t.name LIKE '%' + @TabelaFiltro + '%')
        GROUP BY 
            t.Name, s.Name, p.Rows
        ORDER BY 
            CASE WHEN @MostrarApenasTop20 = 1 THEN ROW_NUMBER() OVER (ORDER BY SUM(a.total_pages) DESC) ELSE 1 END,
            [Tamanho_MB] DESC
        OFFSET 0 ROWS
        FETCH NEXT CASE WHEN @MostrarApenasTop20 = 1 THEN 20 ELSE 999999 END ROWS ONLY;
        
        -- =============================================
        -- RESULTADO 2: INFORMAÇÕES DOS ÍNDICES NONCLUSTERED E COLUMNSTORE
        -- =============================================
        
        PRINT 'Executando consulta de tamanho dos índices NonClustered e ColumnStore...';
        
        SELECT 
            s.name AS [Schema],
            t.name AS [Tabela],
            i.name AS [Nome_Indice],
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
            END AS [Tipo_Indice],
            i.is_unique AS [Unico],
            i.is_primary_key AS [Chave_Primaria],
            p.rows AS [Linhas],
            CAST(ROUND(((SUM(a.total_pages) * 8) / 1024.00), 2) AS NUMERIC(36, 2)) AS [Tamanho_MB],
            CAST(ROUND(((SUM(a.total_pages) * 8) / 1024.00 / 1024.00), 2) AS NUMERIC(36, 2)) AS [Tamanho_GB],
            CAST(ROUND(((SUM(a.used_pages) * 8) / 1024.00), 2) AS NUMERIC(36, 2)) AS [Usado_MB],
            CAST(ROUND(((SUM(a.used_pages) * 8) / 1024.00 / 1024.00), 2) AS NUMERIC(36, 2)) AS [Usado_GB],
            CAST(ROUND(((SUM(a.total_pages) - SUM(a.used_pages)) * 8) / 1024.00, 2) AS NUMERIC(36, 2)) AS [Livre_MB],
            -- Informações adicionais para índices ColumnStore
            CASE 
                WHEN i.type IN (5, 6) THEN 
                    CAST(ROUND((SUM(a.total_pages) * 8.0 / 1024.0 / 
                        NULLIF(SUM(CASE WHEN a.type = 1 THEN a.total_pages ELSE 0 END), 0)) * 100, 2) AS NUMERIC(10, 2))
                ELSE NULL
            END AS [Taxa_Compressao_Percent],
            -- Colunas do índice (limitado aos primeiros caracteres)
            STUFF((
                SELECT ', ' + c.name
                FROM sys.index_columns ic
                INNER JOIN sys.columns c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
                WHERE ic.object_id = i.object_id AND ic.index_id = i.index_id
                    AND ic.is_included_column = 0
                ORDER BY ic.key_ordinal
                FOR XML PATH('')
            ), 1, 2, '') AS [Colunas_Chave],
            -- Colunas incluídas
            STUFF((
                SELECT ', ' + c.name
                FROM sys.index_columns ic
                INNER JOIN sys.columns c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
                WHERE ic.object_id = i.object_id AND ic.index_id = i.index_id
                    AND ic.is_included_column = 1
                ORDER BY ic.key_ordinal
                FOR XML PATH('')
            ), 1, 2, '') AS [Colunas_Incluidas]
        FROM 
            sys.tables t
        INNER JOIN 
            sys.indexes i ON t.OBJECT_ID = i.object_id
        INNER JOIN 
            sys.partitions p ON i.object_id = p.OBJECT_ID AND i.index_id = p.index_id
        INNER JOIN 
            sys.allocation_units a ON p.partition_id = a.container_id
        LEFT OUTER JOIN 
            sys.schemas s ON t.schema_id = s.schema_id
        WHERE 
            t.is_ms_shipped = 0
            AND i.OBJECT_ID > 255
            -- Filtrar apenas índices NonClustered (tipo 2) e ColumnStore (tipos 5 e 6)
            AND i.type IN (2, 5, 6)
            -- Aplicar filtros opcionais
            AND (@SchemaFiltro IS NULL OR s.name = @SchemaFiltro)
            AND (@TabelaFiltro IS NULL OR t.name LIKE '%' + @TabelaFiltro + '%')
        GROUP BY 
            s.name, t.name, i.name, i.type, i.is_unique, i.is_primary_key, p.rows, i.object_id, i.index_id
        ORDER BY 
             [Tamanho_MB] DESC, s.name, t.name;
        
        -- =============================================
        -- RESULTADO 3: RESUMO GERAL
        -- =============================================
        
        PRINT 'Executando resumo geral...';
        
        SELECT 
            'RESUMO GERAL' AS [Categoria],
            COUNT(DISTINCT t.object_id) AS [Total_Tabelas],
            COUNT(DISTINCT CASE WHEN i.type = 2 THEN i.index_id END) AS [Total_Indices_NonClustered],
            COUNT(DISTINCT CASE WHEN i.type IN (5, 6) THEN i.index_id END) AS [Total_Indices_ColumnStore],
            CAST(ROUND(((SUM(a.total_pages) * 8) / 1024.00), 2) AS NUMERIC(36, 2)) AS [Tamanho_Total_MB],
            CAST(ROUND(((SUM(a.total_pages) * 8) / 1024.00 / 1024.00), 2) AS NUMERIC(36, 2)) AS [Tamanho_Total_GB]
        FROM 
            sys.tables t
        INNER JOIN 
            sys.indexes i ON t.OBJECT_ID = i.object_id
        INNER JOIN 
            sys.partitions p ON i.object_id = p.OBJECT_ID AND i.index_id = p.index_id
        INNER JOIN 
            sys.allocation_units a ON p.partition_id = a.container_id
        LEFT OUTER JOIN 
            sys.schemas s ON t.schema_id = s.schema_id
        WHERE 
            t.is_ms_shipped = 0
            AND i.OBJECT_ID > 255
            AND (@SchemaFiltro IS NULL OR s.name = @SchemaFiltro)
            AND (@TabelaFiltro IS NULL OR t.name LIKE '%' + @TabelaFiltro + '%');
        
        PRINT 'Procedure executada com sucesso!';
        
    END TRY
    BEGIN CATCH
        -- Tratamento de erros
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        DECLARE @ErrorLine INT = ERROR_LINE();
        
        PRINT 'Erro na execução da procedure:';
        PRINT 'Linha: ' + CAST(@ErrorLine AS VARCHAR(10));
        PRINT 'Mensagem: ' + @ErrorMessage;
        
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH;
END;
GO

-- =============================================
-- EXEMPLOS DE USO
-- =============================================

-- Exemplo 1: Executar com todos os parâmetros padrão
-- EXEC uspTamanhoTabelasEIndices;

-- Exemplo 2: Mostrar apenas top 20 tabelas
-- EXEC uspTamanhoTabelasEIndices @MostrarApenasTop20 = 1;

-- Exemplo 3: Filtrar por schema específico
-- EXEC uspTamanhoTabelasEIndices @SchemaFiltro = 'dbo';

-- Exemplo 4: Filtrar por tabela específica
-- EXEC uspTamanhoTabelasEIndices @TabelaFiltro = 'LogsJson';

-- Exemplo 5: Combinação de filtros
-- EXEC uspTamanhoTabelasEIndices @MostrarApenasTop20 = 1, @SchemaFiltro = 'Log', @TabelaFiltro = 'Logs';

/*
=============================================
RESULTADOS ESPERADOS:

1. PRIMEIRO RESULTADO: Informações das tabelas
   - Schema, Tabela, Linhas, Tamanho_MB, Tamanho_GB, Usado_MB, Usado_GB, Livre_MB

2. SEGUNDO RESULTADO: Informações dos índices NonClustered e ColumnStore
   - Schema, Tabela, Nome_Indice, Tipo_Indice, Unico, Chave_Primaria, Linhas
   - Tamanho_MB, Tamanho_GB, Usado_MB, Usado_GB, Livre_MB
   - Taxa_Compressao_Percent (para ColumnStore), Colunas_Chave, Colunas_Incluidas

3. TERCEIRO RESULTADO: Resumo geral
   - Total_Tabelas, Total_Indices_NonClustered, Total_Indices_ColumnStore
   - Tamanho_Total_MB, Tamanho_Total_GB
=============================================
*/