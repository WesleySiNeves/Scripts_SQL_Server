SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
CREATE PROCEDURE HealthCheck.uspExecutaShrink
    @ExecuteShrink BIT = 0,     -- Parâmetro para controlar execução (0 = apenas análise, 1 = executar)
    @ReportOnly BIT = 1,        -- Por padrão, apenas relatório
    @ForceExecution BIT = 0     -- Forçar execução (usar com cuidado)
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Verificar se é Azure SQL Database
    DECLARE @IsAzureSQL BIT = CASE 
        WHEN SERVERPROPERTY('EngineEdition') = 5 THEN 1 
        ELSE 0 
    END;
    
    -- Variáveis para controle
    DECLARE @ShouldShrink BIT = 0;
    DECLARE @LogFileName VARCHAR(100);
    DECLARE @ErrorMessage NVARCHAR(4000);
    DECLARE @WarningMessage NVARCHAR(4000) = '';
    
    -- Log de início da análise
    PRINT '=== ANÁLISE DE SHRINK - ' + CONVERT(VARCHAR, GETDATE(), 120) + ' ===';
    PRINT 'Banco: ' + DB_NAME();
    PRINT 'Ambiente: ' + CASE WHEN @IsAzureSQL = 1 THEN 'Azure SQL Database' ELSE 'SQL Server On-Premises' END;
    PRINT '';
    
    -- 1. ANÁLISE DETALHADA DO LOG
    PRINT '1. ANÁLISE DO ARQUIVO DE LOG:';
    SELECT 
        'LOG ANALYSIS' AS [Categoria],
        ddls.database_id AS [Database_ID],
        ddls.total_vlf_count AS [Total_VLF],
        ddls.active_vlf_count AS [Active_VLF],
        ddls.total_log_size_mb AS [Total_Log_MB],
        ddls.active_log_size_mb AS [Active_Log_MB],
        ddls.log_truncation_holdup_reason AS [Truncation_Holdup],
        -- Cálculo de eficiência
        CAST((ddls.active_log_size_mb * 100.0 / ddls.total_log_size_mb) AS DECIMAL(5,2)) AS [Log_Usage_Percent],
        CAST(((ddls.total_log_size_mb - ddls.active_log_size_mb)) AS DECIMAL(10,2)) AS [Free_Space_MB],
        -- Recomendação baseada nas regras
        CASE 
            WHEN ddls.log_truncation_holdup_reason <> 'NOTHING'
            THEN 'CRÍTICO: Resolver bloqueio primeiro - ' + ddls.log_truncation_holdup_reason
            WHEN (ddls.total_log_size_mb - ddls.active_log_size_mb) * 100.0 / ddls.total_log_size_mb < 70
            THEN 'OK: Espaço livre insuficiente para shrink (<70%)'
            WHEN ddls.total_vlf_count <= (ddls.active_vlf_count * 3)
            THEN 'OK: VLF count adequado'
            WHEN (ddls.total_log_size_mb - ddls.active_log_size_mb) < 100
            THEN 'OK: Espaço livre muito pequeno (<100MB)'
            ELSE 'SHRINK RECOMENDADO: Todas as condições atendidas'
        END AS [Recomendacao]
    FROM sys.dm_db_log_stats(DB_ID()) AS ddls;
    
    -- 2. VERIFICAR TRANSAÇÕES ATIVAS (CRÍTICO)
    PRINT '';
    PRINT '2. VERIFICAÇÃO DE TRANSAÇÕES ATIVAS:';
    
    IF EXISTS (
        SELECT 1 
        FROM sys.dm_tran_active_transactions t
        INNER JOIN sys.dm_tran_session_transactions st ON t.transaction_id = st.transaction_id
        WHERE DATEDIFF(MINUTE, transaction_begin_time, GETDATE()) > 5
    )
    BEGIN
        SELECT 
            'TRANSAÇÕES LONGAS DETECTADAS' AS [Alerta],
            session_id AS [Session_ID],
            transaction_begin_time AS [Inicio_Transacao],
            DATEDIFF(MINUTE, transaction_begin_time, GETDATE()) AS [Duracao_Minutos],
            CASE transaction_state
                WHEN 0 THEN 'Initializing'
                WHEN 1 THEN 'Initialized but not started'
                WHEN 2 THEN 'Active'
                WHEN 3 THEN 'Ended (read-only)'
                WHEN 4 THEN 'Commit initiated'
                WHEN 5 THEN 'Prepared, waiting resolution'
                WHEN 6 THEN 'Committed'
                WHEN 7 THEN 'Rolling back'
                WHEN 8 THEN 'Rolled back'
            END AS [Estado_Transacao]
        FROM sys.dm_tran_active_transactions t
        INNER JOIN sys.dm_tran_session_transactions st ON t.transaction_id = st.transaction_id
        WHERE DATEDIFF(MINUTE, transaction_begin_time, GETDATE()) > 5;
        
        SET @WarningMessage = @WarningMessage + 'ATENÇÃO: Transações longas detectadas. ';
    END
    ELSE
    BEGIN
        PRINT 'OK: Nenhuma transação longa detectada.';
    END;
    
    -- 3. ANÁLISE ESPECÍFICA PARA AZURE SQL
    IF @IsAzureSQL = 1
    BEGIN
        PRINT '';
        PRINT '3. MÉTRICAS AZURE SQL (última hora):';
        
        SELECT TOP 5
            'AZURE METRICS' AS [Categoria],
            end_time AS [Horario],
            avg_cpu_percent AS [CPU_Percent],
            avg_data_io_percent AS [Data_IO_Percent],
            avg_log_write_percent AS [Log_Write_Percent],
            avg_memory_usage_percent AS [Memory_Percent],
            CASE 
                WHEN avg_cpu_percent > 50 OR avg_data_io_percent > 60 OR avg_log_write_percent > 40
                THEN 'ALTO USO - Evitar shrink'
                ELSE 'OK para shrink'
            END AS [Status_Recursos]
        FROM sys.dm_db_resource_stats
        WHERE end_time >= DATEADD(HOUR, -1, GETDATE())
        ORDER BY end_time DESC;
        
        -- Verificar se recursos estão adequados para shrink
        IF EXISTS (
            SELECT 1 FROM sys.dm_db_resource_stats
            WHERE end_time >= DATEADD(MINUTE, -15, GETDATE())
            AND (avg_cpu_percent > 50 OR avg_data_io_percent > 60 OR avg_log_write_percent > 40)
        )
        BEGIN
            SET @WarningMessage = @WarningMessage + 'ATENÇÃO: Alto uso de recursos detectado. ';
        END;
    END;
    
    -- 4. APLICAR REGRAS DE DECISÃO
    PRINT '';
    PRINT '4. APLICANDO REGRAS DE DECISÃO:';
    
    SELECT @ShouldShrink = CASE 
        WHEN (
            -- Regra 1: Espaço livre > 70%
            (ddls.total_log_size_mb - ddls.active_log_size_mb) * 100.0 / ddls.total_log_size_mb > 70
            -- Regra 2: VLF excessivos (> 3x)
            AND ddls.total_vlf_count > (ddls.active_vlf_count * 3)
            -- Regra 3: Sem bloqueios de truncamento
            AND ddls.log_truncation_holdup_reason = 'NOTHING'
            -- Regra 4: Tamanho mínimo significativo (> 100MB livre)
            AND (ddls.total_log_size_mb - ddls.active_log_size_mb) > 100
        ) THEN 1
        ELSE 0
    END,
    @LogFileName = (
        SELECT TOP 1 name
        FROM sys.database_files
        WHERE type_desc = 'LOG'
    )
    FROM sys.dm_db_log_stats(DB_ID()) AS ddls;
    
    -- Verificar transações longas (regra adicional)
    IF EXISTS (
        SELECT 1 
        FROM sys.dm_tran_active_transactions t
        INNER JOIN sys.dm_tran_session_transactions st ON t.transaction_id = st.transaction_id
        WHERE DATEDIFF(MINUTE, transaction_begin_time, GETDATE()) > 5
    )
    BEGIN
        SET @ShouldShrink = 0;
        SET @WarningMessage = @WarningMessage + 'BLOQUEIO: Transações longas ativas. ';
    END;
    
    -- Para Azure SQL, verificar recursos adicionais
    IF @IsAzureSQL = 1 AND @ShouldShrink = 1
    BEGIN
        IF EXISTS (
            SELECT 1 FROM sys.dm_db_resource_stats
            WHERE end_time >= DATEADD(MINUTE, -15, GETDATE())
            AND (avg_cpu_percent > 50 OR avg_data_io_percent > 60 OR avg_log_write_percent > 40)
        )
        BEGIN
            SET @ShouldShrink = 0;
            SET @WarningMessage = @WarningMessage + 'BLOQUEIO: Alto uso de recursos. ';
        END;
    END;
    
    -- 5. RELATÓRIO DE DECISÃO
    PRINT '';
    PRINT '5. DECISÃO FINAL:';
    PRINT 'Arquivo de log: ' + ISNULL(@LogFileName, 'N/A');
    PRINT 'Shrink recomendado: ' + CASE WHEN @ShouldShrink = 1 THEN 'SIM' ELSE 'NÃO' END;
    
    IF LEN(@WarningMessage) > 0
    BEGIN
        PRINT 'Avisos: ' + @WarningMessage;
    END;
    
    -- 6. EXECUÇÃO (apenas se todas as condições forem atendidas)
    IF @ExecuteShrink = 1 AND @ReportOnly = 0
    BEGIN
        IF @ShouldShrink = 1 OR @ForceExecution = 1
        BEGIN
            PRINT '';
            PRINT '6. EXECUTANDO SHRINK:';
            PRINT 'Iniciando shrink do arquivo: ' + @LogFileName;
            PRINT 'Horário de início: ' + CONVERT(VARCHAR, GETDATE(), 120);
            
            BEGIN TRY
                DBCC SHRINKFILE(@LogFileName, 0, TRUNCATEONLY);
                PRINT 'SHRINK CONCLUÍDO COM SUCESSO!';
                PRINT 'Horário de conclusão: ' + CONVERT(VARCHAR, GETDATE(), 120);
                
                -- Análise pós-shrink
                PRINT '';
                PRINT 'ANÁLISE PÓS-SHRINK:';
                SELECT 
                    'PÓS-SHRINK' AS [Status],
                    ddls.total_log_size_mb AS [Novo_Tamanho_MB],
                    ddls.active_log_size_mb AS [Espaco_Usado_MB],
                    CAST((ddls.active_log_size_mb * 100.0 / ddls.total_log_size_mb) AS DECIMAL(5,2)) AS [Percentual_Uso]
                FROM sys.dm_db_log_stats(DB_ID()) AS ddls;
                
            END TRY
            BEGIN CATCH
                SET @ErrorMessage = 'ERRO durante shrink: ' + ERROR_MESSAGE();
                PRINT @ErrorMessage;
                THROW;
            END CATCH;
        END
        ELSE
        BEGIN
            PRINT '';
            PRINT '6. SHRINK NÃO EXECUTADO:';
            PRINT 'Motivo: Condições de segurança não atendidas.';
            PRINT 'Use @ForceExecution = 1 apenas se tiver certeza.';
        END;
    END
    ELSE
    BEGIN
        PRINT '';
        PRINT '6. MODO SOMENTE ANÁLISE:';
        PRINT 'Para executar o shrink, use: @ExecuteShrink = 1, @ReportOnly = 0';
    END;
    
    PRINT '';
    PRINT '=== FIM DA ANÁLISE ===';
    
END;
GO