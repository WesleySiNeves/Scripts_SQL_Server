-- =============================================
-- Procedure: uspAnaliseAtividadeBanco
-- Descrição: Analisa atividade do banco atual (Azure SQL Database)
-- Deve ser executada em cada banco individualmente
-- =============================================
CREATE OR ALTER PROCEDURE dbo.uspAnaliseAtividadeBanco
    @DiasAnalise INT = 30,              -- Período de análise em dias
    @LimiteConexoes INT = 5,            -- Limite mínimo de conexões
    @LimiteCPUPercent DECIMAL(5,2) = 1.0, -- Limite mínimo de CPU (%)
    @LimiteIOPercent DECIMAL(5,2) = 1.0   -- Limite mínimo de IO (%)
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @DataInicio DATETIME2 = DATEADD(DAY, -@DiasAnalise, GETUTCDATE());
    DECLARE @DataFim DATETIME2 = GETUTCDATE();
    DECLARE @NomeBanco NVARCHAR(128) = DB_NAME();
    
    PRINT '=============================================';
    PRINT 'ANÁLISE DE ATIVIDADE DO BANCO: ' + @NomeBanco;
    PRINT 'Período: ' + CONVERT(VARCHAR, @DataInicio, 120) + ' até ' + CONVERT(VARCHAR, @DataFim, 120);
    PRINT '=============================================';
    
    -- 1. Informações Gerais do Banco
    SELECT 
        'Informações Gerais' AS [Categoria],
        @NomeBanco AS [Nome_Banco],
        DATABASEPROPERTYEX(@NomeBanco, 'Status') AS [Status],
        DATABASEPROPERTYEX(@NomeBanco, 'Collation') AS [Collation],
        DATABASEPROPERTYEX(@NomeBanco, 'Edition') AS [Edicao],
        DATABASEPROPERTYEX(@NomeBanco, 'ServiceObjective') AS [Service_Objective],
        GETUTCDATE() AS [Data_Analise];
    
    -- 2. Análise de Conexões (últimos dias)
    WITH ConexoesRecentes AS (
        SELECT 
            COUNT(*) AS Total_Conexoes,
            COUNT(DISTINCT login_name) AS Usuarios_Distintos,
            MIN(login_time) AS Primeira_Conexao,
            MAX(login_time) AS Ultima_Conexao
        FROM sys.dm_exec_sessions 
        WHERE login_time >= @DataInicio
            AND database_id = DB_ID()
    )
    SELECT 
        'Análise de Conexões' AS [Categoria],
        cr.Total_Conexoes,
        cr.Usuarios_Distintos,
        cr.Primeira_Conexao,
        cr.Ultima_Conexao,
        CASE 
            WHEN cr.Total_Conexoes < @LimiteConexoes THEN 'BAIXA ATIVIDADE'
            ELSE 'ATIVIDADE NORMAL'
        END AS [Status_Conexoes]
    FROM ConexoesRecentes cr;
    
    -- 3. Análise de Queries Executadas
    WITH QueriesRecentes AS (
        SELECT 
            COUNT(*) AS Total_Execucoes,
            COUNT(DISTINCT sql_handle) AS Queries_Distintas,
            SUM(total_worker_time) AS CPU_Total_Microseg,
            SUM(total_logical_reads) AS IO_Reads_Total,
            SUM(total_logical_writes) AS IO_Writes_Total,
            AVG(total_worker_time) AS CPU_Medio_Microseg,
            MAX(last_execution_time) AS Ultima_Execucao
        FROM sys.dm_exec_query_stats qs
        WHERE last_execution_time >= @DataInicio
    )
    SELECT 
        'Análise de Queries' AS [Categoria],
        qr.Total_Execucoes,
        qr.Queries_Distintas,
        qr.CPU_Total_Microseg,
        qr.CPU_Medio_Microseg,
        qr.IO_Reads_Total,
        qr.IO_Writes_Total,
        qr.Ultima_Execucao,
        CASE 
            WHEN qr.Total_Execucoes = 0 THEN 'SEM ATIVIDADE'
            WHEN qr.Total_Execucoes < 100 THEN 'BAIXA ATIVIDADE'
            ELSE 'ATIVIDADE NORMAL'
        END AS [Status_Queries]
    FROM QueriesRecentes qr;
    
    -- 4. Análise de Tamanho e Crescimento
    SELECT 
        'Análise de Tamanho' AS [Categoria],
        SUM(CASE WHEN type = 0 THEN size END) * 8 / 1024 AS [Dados_MB],
        SUM(CASE WHEN type = 1 THEN size END) * 8 / 1024 AS [Log_MB],
        SUM(size) * 8 / 1024 AS [Total_MB],
        COUNT(*) AS [Arquivos_Total]
    FROM sys.database_files;
    
    -- 5. Top 10 Tabelas por Tamanho
    SELECT TOP 10
        'Top Tabelas' AS [Categoria],
        s.name AS [Schema],
        t.name AS [Tabela],
        p.rows AS [Linhas],
        CAST(ROUND(((SUM(a.total_pages) * 8) / 1024.00), 2) AS NUMERIC(36, 2)) AS [Tamanho_MB]
    FROM sys.tables t
    INNER JOIN sys.indexes i ON t.OBJECT_ID = i.object_id
    INNER JOIN sys.partitions p ON i.object_id = p.OBJECT_ID AND i.index_id = p.index_id
    INNER JOIN sys.allocation_units a ON p.partition_id = a.container_id
    LEFT OUTER JOIN sys.schemas s ON t.schema_id = s.schema_id
    WHERE t.is_ms_shipped = 0
    GROUP BY t.Name, s.Name, p.Rows
    ORDER BY [Tamanho_MB] DESC;
    
    -- 6. Sessões Ativas Atuais
    SELECT 
        'Sessões Ativas' AS [Categoria],
        session_id,
        login_name,
        program_name,
        host_name,
        login_time,
        last_request_start_time,
        status
    FROM sys.dm_exec_sessions
    WHERE database_id = DB_ID()
        AND session_id > 50  -- Excluir sessões do sistema
        AND status IN ('running', 'sleeping')
    ORDER BY last_request_start_time DESC;
    
    -- 7. Recomendação Final
    DECLARE @TotalConexoes INT;
    DECLARE @TotalQueries INT;
    
    SELECT @TotalConexoes = COUNT(*) 
    FROM sys.dm_exec_sessions 
    WHERE login_time >= @DataInicio AND database_id = DB_ID();
    
    SELECT @TotalQueries = COUNT(*) 
    FROM sys.dm_exec_query_stats 
    WHERE last_execution_time >= @DataInicio;
    
    SELECT 
        'Recomendação' AS [Categoria],
        @NomeBanco AS [Banco],
        @TotalConexoes AS [Conexoes_Periodo],
        @TotalQueries AS [Queries_Periodo],
        CASE 
            WHEN @TotalConexoes < @LimiteConexoes AND @TotalQueries < 100 THEN 
                'CANDIDATO A REMOÇÃO - Baixa atividade detectada'
            WHEN @TotalConexoes < @LimiteConexoes THEN 
                'ATENÇÃO - Poucas conexões, verificar queries'
            WHEN @TotalQueries < 100 THEN 
                'ATENÇÃO - Poucas queries, verificar conexões'
            ELSE 
                'BANCO ATIVO - Manter'
        END AS [Recomendacao],
        @DiasAnalise AS [Dias_Analisados];
        
    PRINT 'Análise concluída para o banco: ' + @NomeBanco;
END;
GO