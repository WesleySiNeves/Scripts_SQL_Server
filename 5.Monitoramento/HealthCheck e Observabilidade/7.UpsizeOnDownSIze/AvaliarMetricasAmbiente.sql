--CREATE OR ALTER PROCEDURE dbo.uspAnalisarMetricasElasticPool

DECLARE @NomeElasticPool NVARCHAR(128) = N'rgprd-elspool-cro01',
        @DiasAnalise INT = 7,
        @HoraInicio INT = 6,             -- Horário expandido para capturar mais cenários
        @HoraFim INT = 22,
        @ThresholdCPU_Critico DECIMAL(5, 2) = 85.0,
        @ThresholdCPU_Atencao DECIMAL(5, 2) = 70.0,
        @ThresholdCPU_Otimizacao DECIMAL(5, 2) = 30.0,
        @ThresholdIO_Critico DECIMAL(5, 2) = 80.0,
        @ThresholdMemoria_Critico DECIMAL(5, 2) = 85.0,
        @DiasRetencaoHistorico INT = 90; -- Para análise de tendências
                                         --AS
                                         --BEGIN
                                         --    SET NOCOUNT ON;

-- Validações melhoradas
IF @DiasAnalise NOT IN ( 1, 3, 7, 14, 30 )
BEGIN
    RAISERROR('Período de análise deve ser 1, 3, 7, 14 ou 30 dias', 16, 1);
    RETURN;
END;

IF @HoraInicio < 0
   OR @HoraInicio > 23
   OR @HoraFim < 0
   OR @HoraFim > 23
   OR @HoraInicio >= @HoraFim
BEGIN
    RAISERROR('Horários inválidos. HoraInicio deve ser menor que HoraFim (0-23)', 16, 1);
    RETURN;
END;

-- Detectar elastic pools automaticamente se não especificado
IF @NomeElasticPool IS NULL
BEGIN
    SELECT TOP 1
           @NomeElasticPool = elastic_pool_name
    FROM sys.elastic_pool_resource_stats
    WHERE end_time >= DATEADD(DAY, -1, GETUTCDATE())
    ORDER BY end_time DESC;

    IF @NomeElasticPool IS NULL
    BEGIN
        RAISERROR('Nenhum Elastic Pool encontrado com dados recentes', 16, 1);
        RETURN;
    END;

    PRINT 'Pool detectado automaticamente: ' + @NomeElasticPool;
END;

-- Tabela temporária com métricas expandidas
DROP TABLE IF EXISTS #MetricasPool;
CREATE TABLE #MetricasPool
(
    DataColeta DATE,
    HoraColeta INT,
    DiaSemana NVARCHAR(20),
    start_time DATETIME2(7),
    end_time DATETIME2(7),
    elastic_pool_name NVARCHAR(128),
    avg_cpu_percent DECIMAL(5, 2),
    avg_data_io_percent DECIMAL(5, 2),
    avg_log_write_percent DECIMAL(5, 2),
    avg_storage_percent DECIMAL(5, 2),
    max_worker_percent DECIMAL(5, 2),
    max_session_percent DECIMAL(5, 2),
    elastic_pool_dtu_limit INT,
    elastic_pool_storage_limit_mb BIGINT,
    max_xtp_storage_percent DECIMAL(5, 2),
    avg_login_rate_percent DECIMAL(5, 2),
    avg_instance_cpu_percent DECIMAL(5, 2),
    avg_instance_memory_percent DECIMAL(5, 2),
    elastic_pool_cpu_limit DECIMAL(5, 2),
    avg_allocated_storage_percent DECIMAL(5, 2),
                                                                                    -- Métricas calculadas adicionais
    cpu_pressure_score AS (avg_cpu_percent * 0.4 + avg_instance_cpu_percent * 0.6), -- Peso maior para instance CPU
    io_pressure_score AS (avg_data_io_percent * 0.7 + avg_log_write_percent * 0.3),
    resource_pressure_total AS
        ((avg_cpu_percent * 0.3) + (avg_data_io_percent * 0.3) + (avg_instance_memory_percent * 0.2)
         + (max_worker_percent * 0.1) + (avg_log_write_percent * 0.1)
        )
);

-- Inserção com timezone correction e validações
INSERT INTO #MetricasPool
SELECT CAST(metrica.end_time AS DATE) AS DataColeta,
       DATEPART(HOUR, DATEADD(HOUR, -3, metrica.end_time)) AS HoraColeta,
       CASE DATEPART(WEEKDAY, metrica.end_time)
           WHEN 1 THEN
               'Domingo'
           WHEN 2 THEN
               'Segunda'
           WHEN 3 THEN
               'Terça'
           WHEN 4 THEN
               'Quarta'
           WHEN 5 THEN
               'Quinta'
           WHEN 6 THEN
               'Sexta'
           WHEN 7 THEN
               'Sábado'
       END AS DiaSemana,
       metrica.start_time,
       metrica.end_time,
       metrica.elastic_pool_name,
       ISNULL(metrica.avg_cpu_percent, 0),
       ISNULL(metrica.avg_data_io_percent, 0),
       ISNULL(metrica.avg_log_write_percent, 0),
       ISNULL(metrica.avg_storage_percent, 0),
       ISNULL(metrica.max_worker_percent, 0),
       ISNULL(metrica.max_session_percent, 0),
       metrica.elastic_pool_dtu_limit,
       metrica.elastic_pool_storage_limit_mb,
       ISNULL(metrica.max_xtp_storage_percent, 0),
       ISNULL(metrica.avg_login_rate_percent, 0),
       ISNULL(metrica.avg_instance_cpu_percent, 0),
       ISNULL(metrica.avg_instance_memory_percent, 0),
       metrica.elastic_pool_cpu_limit,
       ISNULL(metrica.avg_allocated_storage_percent, 0)
FROM sys.elastic_pool_resource_stats metrica
WHERE metrica.elastic_pool_name = @NomeElasticPool
      AND metrica.end_time >= DATEADD(DAY, -@DiasAnalise, GETUTCDATE())
      AND DATEPART(HOUR, DATEADD(HOUR, -3, metrica.end_time))
      BETWEEN @HoraInicio AND @HoraFim
      AND metrica.avg_cpu_percent IS NOT NULL; -- Filtrar registros com dados válidos

-- Verificar se há dados suficientes
IF @@ROWCOUNT = 0
BEGIN
    RAISERROR('Nenhum dado encontrado para o período especificado', 16, 1);
    RETURN;
END;

-- 1. RESUMO EXECUTIVO
SELECT 'RESUMO EXECUTIVO' AS Analise,
       @NomeElasticPool AS ElasticPool,
       @DiasAnalise AS DiasAnalisados,
       COUNT(*) AS TotalRegistros,
       MIN(DataColeta) AS PrimeiraColeta,
       MAX(DataColeta) AS UltimaColeta,
       ROUND(AVG(avg_cpu_percent), 2) AS CPU_Media_Geral,
       ROUND(MAX(avg_cpu_percent), 2) AS CPU_Maxima_Geral,
       ROUND(AVG(avg_instance_memory_percent), 2) AS Memoria_Media_Geral,
       ROUND(MAX(avg_instance_memory_percent), 2) AS Memoria_Maxima_Geral,
       ROUND(AVG(avg_data_io_percent), 2) AS IO_Media_Geral,
       ROUND(AVG(resource_pressure_total), 2) AS Pressao_Recursos_Media,
       MAX(elastic_pool_dtu_limit) AS DTU_Limit_Atual,
       MAX(elastic_pool_cpu_limit) AS CPU_Limit_Atual
FROM #MetricasPool;

-- 2. ANÁLISE DIÁRIA MELHORADA
SELECT 'ANÁLISE DIÁRIA' AS Analise,
       elastic_pool_name,
       DataColeta,
       DiaSemana,
       COUNT(*) AS Amostras,
       ROUND(AVG(avg_cpu_percent), 2) AS CPU_Media,
       ROUND(MAX(avg_cpu_percent), 2) AS CPU_Maxima,
       ROUND(AVG(avg_instance_memory_percent), 2) AS Memoria_Media,
       ROUND(MAX(avg_instance_memory_percent), 2) AS Memoria_Maxima,
       ROUND(AVG(io_pressure_score), 2) AS Pressao_IO_Media,
       ROUND(AVG(resource_pressure_total), 2) AS Pressao_Total_Media,
       CASE
           WHEN AVG(resource_pressure_total) > 80 THEN
               'CRÍTICO'
           WHEN AVG(resource_pressure_total) > 60 THEN
               'ATENÇÃO'
           WHEN AVG(resource_pressure_total) < 30 THEN
               'SUBUTILIZADO'
           ELSE
               'NORMAL'
       END AS Status_Dia
FROM #MetricasPool
GROUP BY elastic_pool_name,
         DataColeta,
         DiaSemana
ORDER BY DataColeta;

-- 3. ANÁLISE POR HORA E DIA DA SEMANA
SELECT 'ANÁLISE HORÁRIA POR DIA DA SEMANA' AS Analise,
       DiaSemana,
       HoraColeta,
       COUNT(*) AS Ocorrencias,
       ROUND(AVG(avg_cpu_percent), 2) AS CPU_Media,
       ROUND(MAX(avg_cpu_percent), 2) AS CPU_Maxima,
       ROUND(AVG(avg_instance_memory_percent), 2) AS Memoria_Media,
       ROUND(AVG(resource_pressure_total), 2) AS Pressao_Media
FROM #MetricasPool
GROUP BY DiaSemana,
         HoraColeta
ORDER BY CASE DiaSemana
             WHEN 'Segunda' THEN
                 1
             WHEN 'Terça' THEN
                 2
             WHEN 'Quarta' THEN
                 3
             WHEN 'Quinta' THEN
                 4
             WHEN 'Sexta' THEN
                 5
             WHEN 'Sábado' THEN
                 6
             WHEN 'Domingo' THEN
                 7
         END,
         HoraColeta;

-- 4. IDENTIFICAÇÃO DE PICOS CRÍTICOS (melhorada)
SELECT 'PICOS CRÍTICOS DE UTILIZAÇÃO' AS Analise,
       DataColeta,
       DiaSemana,
       HoraColeta,
       ROUND(avg_cpu_percent, 2) AS CPU_Percent,
       ROUND(avg_instance_memory_percent, 2) AS Memoria_Percent,
       ROUND(avg_data_io_percent, 2) AS IO_Percent,
       ROUND(resource_pressure_total, 2) AS Pressao_Total,
       CASE
           WHEN avg_cpu_percent > @ThresholdCPU_Critico THEN
               'CPU_CRÍTICO'
           WHEN avg_instance_memory_percent > @ThresholdMemoria_Critico THEN
               'MEMORIA_CRÍTICA'
           WHEN avg_data_io_percent > @ThresholdIO_Critico THEN
               'IO_CRÍTICO'
           WHEN resource_pressure_total > 85 THEN
               'MÚLTIPLOS_RECURSOS'
           ELSE
               'LIMIAR_ATINGIDO'
       END AS Tipo_Pico
FROM #MetricasPool
WHERE avg_cpu_percent > @ThresholdCPU_Critico
      OR avg_data_io_percent > @ThresholdIO_Critico
      OR avg_instance_memory_percent > @ThresholdMemoria_Critico
      OR resource_pressure_total > 85
ORDER BY resource_pressure_total DESC,
         DataColeta,
         HoraColeta;

-- 5. RECOMENDAÇÕES INTELIGENTES BASEADAS EM MÚLTIPLAS MÉTRICAS

-- CTE para agregados gerais
WITH MetricasConsolidadas AS (
    SELECT
        AVG(avg_cpu_percent) AS Media_CPU,
        AVG(avg_instance_memory_percent) AS Media_Memoria,
        AVG(avg_data_io_percent) AS Media_IO,
        AVG(resource_pressure_total) AS Media_Pressao_Total,
        MAX(avg_cpu_percent) AS Max_CPU,
        MAX(avg_instance_memory_percent) AS Max_Memoria,
        MAX(resource_pressure_total) AS Max_Pressao_Total,
        COUNT(CASE WHEN avg_cpu_percent > @ThresholdCPU_Critico THEN 1 END) AS Picos_CPU_Criticos,
        COUNT(*) AS Total_Amostras
    FROM #MetricasPool
),
P95_CPU_CTE AS (
    SELECT PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY avg_cpu_percent) OVER() AS P95_CPU
    FROM #MetricasPool
),
P95_Pressao_CTE AS (
    SELECT PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY resource_pressure_total) OVER() AS P95_Pressao
    FROM #MetricasPool
)
SELECT
    CASE
        WHEN m.Max_CPU > 95 OR m.Max_Memoria > 95 OR m.Max_Pressao_Total > 90 THEN 'CRÍTICO: Upsize IMEDIATO necessário'
        WHEN p95cpu.P95_CPU > 85 OR p95press.P95_Pressao > 80 OR (m.Picos_CPU_Criticos * 100.0 / m.Total_Amostras) > 10 THEN 'URGENTE: Upsize recomendado em 24-48h'
        WHEN m.Media_CPU > @ThresholdCPU_Atencao OR m.Media_Pressao_Total > 65 THEN 'ATENÇÃO: Monitorar e planejar upsize'
        WHEN m.Media_CPU < @ThresholdCPU_Otimizacao AND m.Max_CPU < 50 AND m.Media_Pressao_Total < 40 THEN 'OTIMIZAÇÃO: Avaliar downsize para reduzir custos'
        ELSE 'NORMAL: Utilização adequada'
    END AS Recomendacao_Principal,
    CONCAT('CPU: Média=', ROUND(m.Media_CPU, 1), '% | Máx=', ROUND(m.Max_CPU, 1), '% | P95=', ROUND(p95cpu.P95_CPU, 1), '%') AS Metricas_CPU,
    CONCAT('Memória: Média=', ROUND(m.Media_Memoria, 1), '% | Máx=', ROUND(m.Max_Memoria, 1), '%') AS Metricas_Memoria,
    CONCAT('IO: Média=', ROUND(m.Media_IO, 1), '% | Storage=', ROUND(s.Media_Storage_Usado, 1), '%') AS Metricas_IO_Storage,
    CONCAT('Pressão Total: Média=', ROUND(m.Media_Pressao_Total, 1), '% | P95=', ROUND(p95press.P95_Pressao, 1), '%') AS Pressao_Recursos,
    CASE
        WHEN s.Max_Storage_Usado > 85 THEN 'AÇÃO: Expandir storage do pool'
        WHEN s.Max_Storage_Usado < 30 THEN 'OTIMIZAÇÃO: Avaliar redução de storage'
        ELSE 'Storage: Adequado'
    END AS Recomendacao_Storage,
    CONCAT(m.Picos_CPU_Criticos, ' picos críticos em ', m.Total_Amostras, ' amostras (', ROUND((m.Picos_CPU_Criticos * 100.0 / m.Total_Amostras), 1), '%)') AS Frequencia_Picos
FROM MetricasConsolidadas m
CROSS JOIN (SELECT AVG(avg_allocated_storage_percent) AS Media_Storage_Usado, MAX(avg_allocated_storage_percent) AS Max_Storage_Usado FROM #MetricasPool) s
CROSS JOIN (SELECT MAX(P95_CPU) AS P95_CPU FROM P95_CPU_CTE) p95cpu
CROSS JOIN (SELECT MAX(P95_Pressao) AS P95_Pressao FROM P95_Pressao_CTE) p95press;

-- 6. HORÁRIOS DE MAIOR PRESSÃO (Top 10)
SELECT TOP 10
       'TOP HORÁRIOS DE PRESSÃO' AS Analise,
       DataColeta,
       DiaSemana,
       HoraColeta,
       ROUND(resource_pressure_total, 2) AS Pressao_Total,
       ROUND(avg_cpu_percent, 2) AS CPU_Percent,
       ROUND(avg_instance_memory_percent, 2) AS Memoria_Percent
FROM #MetricasPool
ORDER BY resource_pressure_total DESC;

-- Limpeza
DROP TABLE IF EXISTS #MetricasPool;

PRINT 'Análise concluída para o pool: ' + @NomeElasticPool;
--END;
--GO