CREATE OR ALTER PROCEDURE dbo.uspAnaliseMetricasElasticPool
    @ElasticPoolName NVARCHAR(128),
    @DataInicio DATETIME2,
    @DataFim DATETIME2,
    @HoraInicioAnalise TIME = '08:00:00',
    @HoraFimAnalise TIME = '18:00:00'
AS
BEGIN
    SET NOCOUNT ON;

    -- Validação dos parâmetros
    IF @DataInicio >= @DataFim
    BEGIN
        RAISERROR('Data de início deve ser menor que data de fim', 16, 1);
        RETURN;
    END

    -- Exibir informações do pool
    PRINT '=== INFORMAÇÕES DO ELASTIC POOL ===';
    SELECT 
        ep.name AS ElasticPoolName,
        ep.edition,
        ep.dtu,
        ep.database_dtu_max,
        ep.database_dtu_min,
        ep.storage_mb
    FROM sys.elastic_pools ep
    WHERE ep.name = @ElasticPoolName;

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
        AVG(avg_storage_percent) AS Storage_Media_Percent,
        MAX(avg_storage_percent) AS Storage_Maximo_Percent
    FROM sys.elastic_pool_resource_stats
    WHERE elastic_pool_name = @ElasticPoolName
      AND end_time BETWEEN @DataInicio AND @DataFim;

    -- Análise do horário de pico
    SELECT 
        'HORÁRIO DE PICO' AS Periodo,
        COUNT(*) AS TotalRegistros,
        AVG(avg_cpu_percent) AS CPU_Media_Percent,
        MAX(avg_cpu_percent) AS CPU_Maximo_Percent,
        AVG(avg_data_io_percent) AS DataIO_Media_Percent,
        MAX(avg_data_io_percent) AS DataIO_Maximo_Percent,
        AVG(avg_log_write_percent) AS LogIO_Media_Percent,
        MAX(avg_log_write_percent) AS LogIO_Maximo_Percent,
        AVG(avg_storage_percent) AS Storage_Media_Percent,
        MAX(avg_storage_percent) AS Storage_Maximo_Percent
    FROM sys.elastic_pool_resource_stats
    WHERE elastic_pool_name = @ElasticPoolName
      AND end_time BETWEEN @DataInicio AND @DataFim
      AND CAST(end_time AS TIME) BETWEEN @HoraInicioAnalise AND @HoraFimAnalise;

    -- Identificar picos de utilização (>80%)
    SELECT 
        end_time,
        avg_cpu_percent,
        avg_data_io_percent,
        avg_log_write_percent,
        avg_storage_percent
    FROM sys.elastic_pool_resource_stats
    WHERE elastic_pool_name = @ElasticPoolName
      AND end_time BETWEEN @DataInicio AND @DataFim
      AND (
            avg_cpu_percent > 80 OR
            avg_data_io_percent > 80 OR
            avg_log_write_percent > 80 OR
            avg_storage_percent > 80
          )
    ORDER BY end_time DESC;

    -- Recomendações
    DECLARE @CPUMediaPico DECIMAL(5,2), @CPUMaximoPico DECIMAL(5,2),
            @DataIOMediaPico DECIMAL(5,2), @LogIOMediaPico DECIMAL(5,2);

    SELECT 
        @CPUMediaPico = AVG(avg_cpu_percent),
        @CPUMaximoPico = MAX(avg_cpu_percent),
        @DataIOMediaPico = AVG(avg_data_io_percent),
        @LogIOMediaPico = AVG(avg_log_write_percent)
    FROM sys.elastic_pool_resource_stats
    WHERE elastic_pool_name = @ElasticPoolName
      AND end_time BETWEEN @DataInicio AND @DataFim
      AND CAST(end_time AS TIME) BETWEEN @HoraInicioAnalise AND @HoraFimAnalise;

    PRINT '=== RECOMENDAÇÕES ===';
    IF @CPUMediaPico > 80
        PRINT '🔴 UPSIZE RECOMENDADO: CPU média no horário de pico acima de 80% (' + CAST(@CPUMediaPico AS VARCHAR(10)) + '%)';
    ELSE IF @CPUMediaPico > 60
        PRINT '🟡 MONITORAR: CPU média no horário de pico entre 60-80% (' + CAST(@CPUMediaPico AS VARCHAR(10)) + '%)';
    ELSE IF @CPUMediaPico < 30
        PRINT '🟢 DOWNSIZE POSSÍVEL: CPU média no horário de pico abaixo de 30% (' + CAST(@CPUMediaPico AS VARCHAR(10)) + '%)';
    ELSE
        PRINT '✅ CONFIGURAÇÃO ADEQUADA: CPU média no horário de pico em nível aceitável (' + CAST(@CPUMediaPico AS VARCHAR(10)) + '%)';

    -- Repita lógica para Data IO e Log IO se desejar

    PRINT '=== PRÓXIMOS PASSOS ===';
    PRINT '1. Analise horários de pico e bancos mais ativos no pool';
    PRINT '2. Verifique consultas ou bancos que consomem mais recursos';
    PRINT '3. Considere otimizações antes de aumentar recursos';
    PRINT '4. Para downsize, monitore por pelo menos 2 semanas';

END
GO