SET QUOTED_IDENTIFIER ON
SET ANSI_NULLS ON
GO

CREATE OR ALTER PROCEDURE [HealthCheck].[uspUpdateStats]
(
    @ExecutarAtualizacao BIT = 0, -- Se 1, executa as atualizações; se 0, apenas mostra o que seria feito
    @ModificationThreshold FLOAT = 0.10, -- Limite de modificações (10% por padrão)
    @DaysSinceLastUpdate INT = 30, -- Dias desde última atualização
    @MostrarProgresso BIT = 1 -- Mostrar progresso em percentual
)
AS
BEGIN
    SET NOCOUNT ON;

    /*
    === PROCEDURE SIMPLIFICADA DE ATUALIZAÇÃO DE ESTATÍSTICAS ===
    
    FUNCIONALIDADES:
    ✓ Identifica estatísticas desatualizadas
    ✓ Atualiza estatísticas com base no threshold de modificações
    ✓ Mostra progresso em percentual
    ✓ Execução controlada (simulação ou execução real)
    
    AUTOR: Wesley Silva
    VERSÃO: 4.0 - Simplified
    DATA: 2024
    */

    -- Variáveis de controle
    DECLARE @StartTime DATETIME = GETDATE();
    DECLARE @EndTime DATETIME;
    DECLARE @TotalElapsedTime INT;
    DECLARE @sql NVARCHAR(MAX);
    DECLARE @ProcessedCount INT = 0;
    DECLARE @TotalCount INT = 0;
    DECLARE @ProgressPercent DECIMAL(5,2) = 0;
    DECLARE @CurrentTableName NVARCHAR(256);
    DECLARE @CurrentStatName NVARCHAR(256);
    
    PRINT 'Iniciando análise de estatísticas desatualizadas...';
    PRINT CONCAT('Threshold de modificações: ', @ModificationThreshold * 100, '%');
    PRINT CONCAT('Dias desde última atualização: ', @DaysSinceLastUpdate);
    PRINT '';

    -- Tabela temporária para estatísticas desatualizadas
    CREATE TABLE #StatsToUpdate
    (
        [SchemaName] SYSNAME,
        [TableName] SYSNAME,
        [StatsName] SYSNAME,
        [modification_counter] BIGINT,
        [rows] BIGINT,
        [last_updated] DATETIME,
        [modification_percent] DECIMAL(10,4), -- Aumentado para evitar overflow
        [days_since_update] INT,
        [update_script] NVARCHAR(MAX),
        [ProcessingOrder] INT IDENTITY(1,1)
    );

    -- Identificar estatísticas desatualizadas
    INSERT INTO #StatsToUpdate 
    (
        SchemaName, 
        TableName, 
        StatsName, 
        modification_counter, 
        rows, 
        last_updated, 
        modification_percent, 
        days_since_update,
        update_script
    )
    SELECT 
        s.name AS SchemaName,
        t.name AS TableName,
        st.name AS StatsName,
        sp.modification_counter,
        sp.rows,
        sp.last_updated,
        CASE 
            WHEN sp.rows > 0 AND sp.modification_counter > 0 
            THEN CAST((CAST(sp.modification_counter AS FLOAT) * 100.0 / CAST(sp.rows AS FLOAT)) AS DECIMAL(10,4))
            ELSE 0
        END AS modification_percent,
        DATEDIFF(DAY, sp.last_updated, GETDATE()) AS days_since_update,
        CONCAT('UPDATE STATISTICS [', s.name, '].[', t.name, '] ([', st.name, ']) WITH SAMPLE;') AS update_script
    FROM sys.tables t
    INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
    INNER JOIN sys.stats st ON t.object_id = st.object_id
    CROSS APPLY sys.dm_db_stats_properties(st.object_id, st.stats_id) sp
    WHERE s.name NOT IN ('Log', 'Expurgo', 'HangFire', 'Sistema', 'sys')
      AND st.auto_created = 1  -- Apenas estatísticas criadas automaticamente
      AND (
          -- Estatísticas com muitas modificações
          (sp.rows > 0 AND sp.modification_counter > (sp.rows * @ModificationThreshold))
          OR 
          -- Estatísticas muito desatualizadas
          DATEDIFF(DAY, sp.last_updated, GETDATE()) > @DaysSinceLastUpdate
      )
    ORDER BY 
        CASE 
            WHEN sp.rows > 0 AND sp.modification_counter > 0 
            THEN (CAST(sp.modification_counter AS FLOAT) * 100.0 / CAST(sp.rows AS FLOAT))
            ELSE 0
        END DESC;

    -- Obter total de estatísticas encontradas
    SELECT @TotalCount = COUNT(*) FROM #StatsToUpdate;
    
    PRINT CONCAT('Encontradas ', @TotalCount, ' estatísticas desatualizadas.');
    PRINT '';

    -- Gerar scripts simples de UPDATE STATISTICS
    UPDATE #StatsToUpdate
    SET update_script = 'UPDATE STATISTICS [' + SchemaName + '].[' + TableName + '] ([' + StatsName + ']);';

    -- Execução das atualizações com processamento otimizado
    IF (@ExecutarAtualizacao = 1 AND @TotalCount > 0)
    BEGIN
        DECLARE @CurrentSchemaName SYSNAME;
        DECLARE @ProcessingOrder INT;
        DECLARE @SuccessCount INT = 0;
        DECLARE @ErrorCount INT = 0;
        
        PRINT 'Iniciando execução das atualizações...';
        
        DECLARE cursor_stats CURSOR LOCAL FAST_FORWARD FOR
        SELECT 
            SchemaName,
            TableName,
            StatsName,
            update_script,
            ProcessingOrder
        FROM #StatsToUpdate
        ORDER BY ProcessingOrder;
        
        OPEN cursor_stats;
        
        FETCH NEXT FROM cursor_stats INTO 
             @CurrentSchemaName, @CurrentTableName, @CurrentStatName, @sql, @ProcessingOrder;
         
         WHILE @@FETCH_STATUS = 0
         BEGIN
             SET @ProcessedCount = @ProcessedCount + 1;
             
             -- Cálculo de progresso percentual
             IF (@MostrarProgresso = 1)
             BEGIN
                 SET @ProgressPercent = CAST((@ProcessedCount * 100.0) / @TotalCount AS DECIMAL(5,2));
                 PRINT CONCAT('Progresso: ', @ProgressPercent, '% (', @ProcessedCount, '/', @TotalCount, ') - Atualizando: [', @CurrentSchemaName, '].[', @CurrentTableName, '].[', @CurrentStatName, ']');
             END;
             
             -- Execução da atualização
             BEGIN TRY
                 EXEC sp_executesql @sql;
                 SET @SuccessCount = @SuccessCount + 1;
             END TRY
             BEGIN CATCH
                 SET @ErrorCount = @ErrorCount + 1;
                 PRINT CONCAT('ERRO ao atualizar [', @CurrentSchemaName, '].[', @CurrentTableName, '].[', @CurrentStatName, ']: ', ERROR_MESSAGE());
             END CATCH;
             
             FETCH NEXT FROM cursor_stats INTO 
                 @CurrentSchemaName, @CurrentTableName, @CurrentStatName, @sql, @ProcessingOrder;
        END;
        
        CLOSE cursor_stats;
        DEALLOCATE cursor_stats;
        
        -- Relatório final
        SET @EndTime = GETDATE();
        SET @TotalElapsedTime = DATEDIFF(SECOND, @StartTime, @EndTime);
        
        PRINT '';
        PRINT '=========================================';
        PRINT 'RELATÓRIO FINAL';
        PRINT '=========================================';
        PRINT CONCAT('Estatísticas encontradas: ', @TotalCount);
        PRINT CONCAT('Estatísticas processadas: ', @ProcessedCount);
        PRINT CONCAT('Sucessos: ', @SuccessCount);
        PRINT CONCAT('Erros: ', @ErrorCount);
        PRINT CONCAT('Tempo total: ', @TotalElapsedTime, ' segundos');
        PRINT '=========================================';
    END
    ELSE
    BEGIN
        -- Apenas simulação
        PRINT '';
        PRINT '=========================================';
        PRINT 'SIMULAÇÃO - SCRIPTS QUE SERIAM EXECUTADOS';
        PRINT '=========================================';
        
        SELECT 
            SchemaName + '.' + TableName AS Tabela,
            StatsName AS Estatistica,
            FORMAT(rows, 'N0') AS TotalLinhas,
            FORMAT(modification_counter, 'N0') AS LinhasModificadas,
            FORMAT(CASE WHEN rows > 0 AND modification_counter > 0 
                        THEN CAST(modification_counter AS FLOAT) / CAST(rows AS FLOAT) * 100 
                        ELSE 0 END, 'N2') AS PercentualModificacao,
            DATEDIFF(DAY, last_updated, GETDATE()) AS DiasDesdeUltimaAtualizacao,
            update_script AS ComandoSQL
        FROM #StatsToUpdate
        ORDER BY ProcessingOrder;
        
        PRINT CONCAT('Total de estatísticas que seriam atualizadas: ', @TotalCount);
    END;
    
    -- Limpeza
    IF OBJECT_ID('tempdb..#StatsToUpdate') IS NOT NULL DROP TABLE #StatsToUpdate;
END;
GO