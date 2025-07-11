CREATE OR ALTER PROCEDURE [dbo].[uspAnaliseMetricasUpsizeDownsize]
    @DataInicio DATETIME2,
    @DataFim DATETIME2,
    @HoraInicioAnalise TIME = '08:00:00', -- Hora de início do período de maior uso
    @HoraFimAnalise TIME = '18:00:00'     -- Hora de fim do período de maior uso
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Validação dos parâmetros
    IF @DataInicio >= @DataFim
    BEGIN
        RAISERROR('Data de início deve ser menor que data de fim', 16, 1);
        RETURN;
    END
    
    -- Declaração de variáveis para informações do servidor
    DECLARE @VCoresAtuais INT;
    DECLARE @TierAtual NVARCHAR(50);
    DECLARE @MaxMemoryMB INT;
    DECLARE @DTULimit INT;
    DECLARE @DatabaseName NVARCHAR(128);
    
    -- Obter informações atuais do servidor (CORRIGIDO)
    SELECT 
        @VCoresAtuais = dso.cpu_limit,
        @TierAtual = dso.slo_name,          -- CORRIGIDO: usar slo_name ao invés de service_objective
        @MaxMemoryMB = dso.max_db_memory,
        @DTULimit = dso.dtu_limit,
        @DatabaseName = dso.database_name
    FROM sys.dm_user_db_resource_governance dso;
    
    -- Exibir informações atuais do servidor
    PRINT '=== INFORMAÇÕES ATUAIS DO SERVIDOR ===';
    PRINT 'Database: ' + ISNULL(@DatabaseName, 'N/A');
    PRINT 'Service Level Objective (SLO): ' + ISNULL(@TierAtual, 'N/A');
    PRINT 'vCores Atuais: ' + ISNULL(CAST(@VCoresAtuais AS VARCHAR(10)), 'N/A');
    PRINT 'DTU Limit: ' + ISNULL(CAST(@DTULimit AS VARCHAR(10)), 'N/A');
    PRINT 'Memória Máxima (MB): ' + ISNULL(CAST(@MaxMemoryMB AS VARCHAR(20)), 'N/A');
    PRINT '';
    
    -- Análise geral do período completo
    SELECT 
        'PERÍODO COMPLETO' AS Periodo,
        COUNT(*) AS TotalRegistros,
        AVG(avg_cpu_percent) AS CPU_Media_Percent,
        MAX(avg_cpu_percent) AS CPU_Maximo_Percent,
        AVG(avg_data_io_percent) AS DataIO_Media_Percent,
        MAX(avg_data_io_percent) AS DataIO_Maximo_Percent,
        AVG(avg_log_write_percent) AS LogIO_Media_Percent,
        MAX(avg_log_write_percent) AS LogIO_Maximo_Percent,
        AVG(avg_memory_usage_percent) AS Memoria_Media_Percent,
        MAX(avg_memory_usage_percent) AS Memoria_Maximo_Percent,
        AVG(avg_instance_cpu_percent) AS CPU_Instancia_Media_Percent,
        MAX(avg_instance_cpu_percent) AS CPU_Instancia_Maximo_Percent
    FROM sys.dm_db_resource_stats
    WHERE end_time BETWEEN @DataInicio AND @DataFim;
    
    -- Análise do horário de pico (8h às 18h)
    SELECT 
        'HORÁRIO DE PICO (8h-18h)' AS Periodo,
        COUNT(*) AS TotalRegistros,
        AVG(avg_cpu_percent) AS CPU_Media_Percent,
        MAX(avg_cpu_percent) AS CPU_Maximo_Percent,
        AVG(avg_data_io_percent) AS DataIO_Media_Percent,
        MAX(avg_data_io_percent) AS DataIO_Maximo_Percent,
        AVG(avg_log_write_percent) AS LogIO_Media_Percent,
        MAX(avg_log_write_percent) AS LogIO_Maximo_Percent,
        AVG(avg_memory_usage_percent) AS Memoria_Media_Percent,
        MAX(avg_memory_usage_percent) AS Memoria_Maximo_Percent,
        AVG(avg_instance_cpu_percent) AS CPU_Instancia_Media_Percent,
        MAX(avg_instance_cpu_percent) AS CPU_Instancia_Maximo_Percent
    FROM sys.dm_db_resource_stats
    WHERE end_time BETWEEN @DataInicio AND @DataFim
      AND CAST(end_time AS TIME) BETWEEN @HoraInicioAnalise AND @HoraFimAnalise;
    
    -- Análise por dia da semana no horário de pico
    SELECT 
        CASE DATEPART(WEEKDAY, end_time)
            WHEN 1 THEN 'Domingo'
            WHEN 2 THEN 'Segunda-feira'
            WHEN 3 THEN 'Terça-feira'
            WHEN 4 THEN 'Quarta-feira'
            WHEN 5 THEN 'Quinta-feira'
            WHEN 6 THEN 'Sexta-feira'
            WHEN 7 THEN 'Sábado'
        END AS DiaSemana,
        COUNT(*) AS TotalRegistros,
        AVG(avg_cpu_percent) AS CPU_Media_Percent,
        MAX(avg_cpu_percent) AS CPU_Maximo_Percent,
        AVG(avg_data_io_percent) AS DataIO_Media_Percent,
        MAX(avg_data_io_percent) AS DataIO_Maximo_Percent,
        AVG(avg_log_write_percent) AS LogIO_Media_Percent,
        MAX(avg_log_write_percent) AS LogIO_Maximo_Percent
    FROM sys.dm_db_resource_stats
    WHERE end_time BETWEEN @DataInicio AND @DataFim
      AND CAST(end_time AS TIME) BETWEEN @HoraInicioAnalise AND @HoraFimAnalise
    GROUP BY DATEPART(WEEKDAY, end_time)
    ORDER BY DATEPART(WEEKDAY, end_time);
    
    -- Análise por hora do dia
    SELECT 
        DATEPART(HOUR, end_time) AS Hora,
        COUNT(*) AS TotalRegistros,
        AVG(avg_cpu_percent) AS CPU_Media_Percent,
        MAX(avg_cpu_percent) AS CPU_Maximo_Percent,
        AVG(avg_data_io_percent) AS DataIO_Media_Percent,
        MAX(avg_data_io_percent) AS DataIO_Maximo_Percent,
        AVG(avg_log_write_percent) AS LogIO_Media_Percent,
        MAX(avg_log_write_percent) AS LogIO_Maximo_Percent
    FROM sys.dm_db_resource_stats
    WHERE end_time BETWEEN @DataInicio AND @DataFim
    GROUP BY DATEPART(HOUR, end_time)
    ORDER BY DATEPART(HOUR, end_time);
    
    -- Identificar picos de utilização (acima de 80%)
    SELECT 
        'PICOS DE UTILIZAÇÃO (>80%)' AS Analise,
        end_time,
        avg_cpu_percent,
        avg_data_io_percent,
        avg_log_write_percent,
        avg_memory_usage_percent
    FROM sys.dm_db_resource_stats
    WHERE end_time BETWEEN @DataInicio AND @DataFim
      AND (avg_cpu_percent > 80 OR avg_data_io_percent > 80 OR avg_log_write_percent > 80)
    ORDER BY end_time DESC;
    
    -- Recomendações baseadas nas métricas
    DECLARE @CPUMediaPico DECIMAL(5,2);
    DECLARE @CPUMaximoPico DECIMAL(5,2);
    DECLARE @DataIOMediaPico DECIMAL(5,2);
    DECLARE @LogIOMediaPico DECIMAL(5,2);
    
    SELECT 
        @CPUMediaPico = AVG(avg_cpu_percent),
        @CPUMaximoPico = MAX(avg_cpu_percent),
        @DataIOMediaPico = AVG(avg_data_io_percent),
        @LogIOMediaPico = AVG(avg_log_write_percent)
    FROM sys.dm_db_resource_stats
    WHERE end_time BETWEEN @DataInicio AND @DataFim
      AND CAST(end_time AS TIME) BETWEEN @HoraInicioAnalise AND @HoraFimAnalise;
    
    -- Gerar recomendações
    PRINT '=== RECOMENDAÇÕES ===';
    
    IF @CPUMediaPico > 80
        PRINT '🔴 UPSIZE RECOMENDADO: CPU média no horário de pico está acima de 80% (' + CAST(@CPUMediaPico AS VARCHAR(10)) + '%)';
    ELSE IF @CPUMediaPico > 60
        PRINT '🟡 MONITORAR: CPU média no horário de pico está entre 60-80% (' + CAST(@CPUMediaPico AS VARCHAR(10)) + '%)';
    ELSE IF @CPUMediaPico < 30
        PRINT '🟢 DOWNSIZE POSSÍVEL: CPU média no horário de pico está abaixo de 30% (' + CAST(@CPUMediaPico AS VARCHAR(10)) + '%)';
    ELSE
        PRINT '✅ CONFIGURAÇÃO ADEQUADA: CPU média no horário de pico está em nível aceitável (' + CAST(@CPUMediaPico AS VARCHAR(10)) + '%)';
    
    IF @DataIOMediaPico > 80
        PRINT '🔴 ATENÇÃO: Data IO média no horário de pico está acima de 80% (' + CAST(@DataIOMediaPico AS VARCHAR(10)) + '%)';
    ELSE IF @DataIOMediaPico < 30
        PRINT '🟢 Data IO está em nível baixo (' + CAST(@DataIOMediaPico AS VARCHAR(10)) + '%)';
    
    IF @LogIOMediaPico > 80
        PRINT '🔴 ATENÇÃO: Log IO média no horário de pico está acima de 80% (' + CAST(@LogIOMediaPico AS VARCHAR(10)) + '%)';
    ELSE IF @LogIOMediaPico < 30
        PRINT '🟢 Log IO está em nível baixo (' + CAST(@LogIOMediaPico AS VARCHAR(10)) + '%)';
    
    PRINT '';
    PRINT '=== PRÓXIMOS PASSOS ===';
    PRINT '1. Analise os horários de pico identificados';
    PRINT '2. Verifique se há consultas específicas causando os picos';
    PRINT '3. Considere otimizações antes de fazer upsize';
    PRINT '4. Para downsize, monitore por pelo menos 2 semanas';
    
END;
GO