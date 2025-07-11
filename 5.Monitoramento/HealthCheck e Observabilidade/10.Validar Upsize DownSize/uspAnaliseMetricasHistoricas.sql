-- =============================================
-- Procedure: uspAnaliseMetricasUpsizeAzureSQL
-- Descrição: Analisa métricas para decisão de Upsize no Azure SQL Database
-- Foco: Análise de CPU, Data IO e Log IO para otimização de vCores
-- Autor: Sistema de Monitoramento
-- Data: 2024
-- =============================================
CREATE OR ALTER PROCEDURE dbo.uspAnaliseMetricasUpsizeAzureSQL
    @DataInicio DATETIME2 = NULL,         -- Data início da análise (padrão: 30 dias atrás)
    @DataFim DATETIME2 = NULL,            -- Data fim da análise (padrão: agora)
    @HoraInicioPico INT = 8,              -- Hora início do pico (padrão: 8h)
    @HoraFimPico INT = 18,                -- Hora fim do pico (padrão: 18h)
    @OffsetHorario INT = -3,              -- Offset de horário UTC (padrão: -3 para Brasil)
    @LimiteCPUUpsize DECIMAL(5,2) = 70.0, -- Limite CPU para considerar upsize (%)
    @LimiteIOUpsize DECIMAL(5,2) = 70.0   -- Limite IO para considerar upsize (%)
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Definir datas padrão se não informadas
    SET @DataInicio = ISNULL(@DataInicio, DATEADD(DAY, -30, GETUTCDATE()));
    SET @DataFim = ISNULL(@DataFim, GETUTCDATE());
    
    DECLARE @NomeBanco NVARCHAR(128) = DB_NAME();
    DECLARE @DiasAnalise INT = DATEDIFF(DAY, @DataInicio, @DataFim);
    
    PRINT '=============================================';
    PRINT 'ANÁLISE PARA DECISÃO DE UPSIZE - AZURE SQL';
    PRINT 'Banco: ' + @NomeBanco;
    PRINT 'Período: ' + CONVERT(VARCHAR, @DataInicio, 120) + ' até ' + CONVERT(VARCHAR, @DataFim, 120);
    PRINT 'Horário de Pico: ' + CAST(@HoraInicioPico AS VARCHAR) + 'h às ' + CAST(@HoraFimPico AS VARCHAR) + 'h';
    PRINT 'Dias Analisados: ' + CAST(@DiasAnalise AS VARCHAR);
    PRINT '=============================================';
    
    -- 1. Resumo Geral das Métricas (Todo o Período)
    SELECT 
        'RESUMO GERAL - TODO PERÍODO' AS [Categoria],
        @NomeBanco AS [Nome_Banco],
        COUNT(*) AS [Total_Registros],
        MIN(end_time) AS [Primeira_Metrica],
        MAX(end_time) AS [Ultima_Metrica],
        ROUND(AVG(avg_cpu_percent), 2) AS [CPU_Media_Geral],
        ROUND(MAX(avg_cpu_percent), 2) AS [CPU_Maxima_Geral],
        ROUND(AVG(avg_data_io_percent), 2) AS [DataIO_Media_Geral],
        ROUND(MAX(avg_data_io_percent), 2) AS [DataIO_Maxima_Geral],
        ROUND(AVG(avg_log_write_percent), 2) AS [LogIO_Media_Geral],
        ROUND(MAX(avg_log_write_percent), 2) AS [LogIO_Maxima_Geral],
        CASE 
            WHEN AVG(avg_cpu_percent) > @LimiteCPUUpsize OR 
                 AVG(avg_data_io_percent) > @LimiteIOUpsize OR 
                 AVG(avg_log_write_percent) > @LimiteIOUpsize 
            THEN 'CONSIDERAR UPSIZE'
            ELSE 'RECURSOS ADEQUADOS'
        END AS [Recomendacao_Geral]
    FROM sys.dm_db_resource_stats
    WHERE end_time >= @DataInicio AND end_time <= @DataFim;
    
    -- 2. Análise do Horário de Pico (8h às 18h)
    SELECT 
        'HORÁRIO DE PICO (' + CAST(@HoraInicioPico AS VARCHAR) + 'h-' + CAST(@HoraFimPico AS VARCHAR) + 'h)' AS [Categoria],
        COUNT(*) AS [Total_Registros_Pico],
        ROUND(AVG(avg_cpu_percent), 2) AS [CPU_Media_Pico],
        ROUND(MAX(avg_cpu_percent), 2) AS [CPU_Maxima_Pico],
        ROUND(AVG(avg_data_io_percent), 2) AS [DataIO_Media_Pico],
        ROUND(MAX(avg_data_io_percent), 2) AS [DataIO_Maxima_Pico],
        ROUND(AVG(avg_log_write_percent), 2) AS [LogIO_Media_Pico],
        ROUND(MAX(avg_log_write_percent), 2) AS [LogIO_Maxima_Pico],
        CASE 
            WHEN AVG(avg_cpu_percent) > @LimiteCPUUpsize THEN 'CPU: UPSIZE NECESSÁRIO'
            WHEN AVG(avg_data_io_percent) > @LimiteIOUpsize THEN 'DATA IO: UPSIZE NECESSÁRIO'
            WHEN AVG(avg_log_write_percent) > @LimiteIOUpsize THEN 'LOG IO: UPSIZE NECESSÁRIO'
            WHEN AVG(avg_cpu_percent) > (@LimiteCPUUpsize * 0.8) THEN 'CPU: MONITORAR CRESCIMENTO'
            ELSE 'RECURSOS ADEQUADOS NO PICO'
        END AS [Recomendacao_Pico]
    FROM sys.dm_db_resource_stats
    WHERE end_time >= @DataInicio AND end_time <= @DataFim
              AND DATEPART(HOUR, DATEADD(HOUR, @OffsetHorario, end_time)) BETWEEN @HoraInicioPico AND @HoraFimPico;
    
    -- 3. Análise Fora do Horário de Pico
    SELECT 
        'FORA DO PICO (Demais Horários)' AS [Categoria],
        COUNT(*) AS [Total_Registros_ForaPico],
        ROUND(AVG(avg_cpu_percent), 2) AS [CPU_Media_ForaPico],
        ROUND(MAX(avg_cpu_percent), 2) AS [CPU_Maxima_ForaPico],
        ROUND(AVG(avg_data_io_percent), 2) AS [DataIO_Media_ForaPico],
        ROUND(MAX(avg_data_io_percent), 2) AS [DataIO_Maxima_ForaPico],
        ROUND(AVG(avg_log_write_percent), 2) AS [LogIO_Media_ForaPico],
        ROUND(MAX(avg_log_write_percent), 2) AS [LogIO_Maxima_ForaPico]
    FROM sys.dm_db_resource_stats
    WHERE end_time >= @DataInicio AND end_time <= @DataFim
        AND (DATEPART(HOUR, end_time) < @HoraInicioPico 
             OR DATEPART(HOUR, end_time) >= @HoraFimPico);
    
    -- 4. Métricas Agregadas por Dia
    SELECT 
        'MÉTRICAS DIÁRIAS' AS [Categoria],
        CAST(end_time AS DATE) AS [Data],
        COUNT(*) AS [Registros_Dia],
        ROUND(AVG(avg_cpu_percent), 2) AS [CPU_Media_Dia],
        ROUND(MAX(avg_cpu_percent), 2) AS [CPU_Maxima_Dia],
        ROUND(AVG(avg_data_io_percent), 2) AS [DataIO_Media_Dia],
        ROUND(MAX(avg_data_io_percent), 2) AS [DataIO_Maxima_Dia],
        ROUND(AVG(avg_log_write_percent), 2) AS [LogIO_Media_Dia],
        ROUND(MAX(avg_log_write_percent), 2) AS [LogIO_Maxima_Dia],
        CASE 
            WHEN AVG(avg_cpu_percent) > @LimiteCPUUpsize OR 
                 AVG(avg_data_io_percent) > @LimiteIOUpsize OR 
                 AVG(avg_log_write_percent) > @LimiteIOUpsize 
            THEN 'DIA COM ALTA DEMANDA'
            WHEN AVG(avg_cpu_percent) > (@LimiteCPUUpsize * 0.8) OR 
                 AVG(avg_data_io_percent) > (@LimiteIOUpsize * 0.8) 
            THEN 'DIA COM DEMANDA MODERADA'
            ELSE 'DIA COM BAIXA DEMANDA'
        END AS [Status_Dia]
    FROM sys.dm_db_resource_stats
    WHERE end_time >= @DataInicio AND end_time <= @DataFim
    GROUP BY CAST(end_time AS DATE)
    ORDER BY [Data] DESC;
    
    -- 5. Padrão de Uso por Hora (Identificação de Picos)
    SELECT 
        'PADRÃO HORÁRIO DE USO' AS [Categoria],
        DATEPART(HOUR, end_time) AS [Hora],
        COUNT(*) AS [Registros],
        ROUND(AVG(avg_cpu_percent), 2) AS [CPU_Media_Hora],
        ROUND(MAX(avg_cpu_percent), 2) AS [CPU_Maxima_Hora],
        ROUND(AVG(avg_data_io_percent), 2) AS [DataIO_Media_Hora],
        ROUND(MAX(avg_data_io_percent), 2) AS [DataIO_Maxima_Hora],
        ROUND(AVG(avg_log_write_percent), 2) AS [LogIO_Media_Hora],
        ROUND(MAX(avg_log_write_percent), 2) AS [LogIO_Maxima_Hora],
        CASE 
            WHEN DATEPART(HOUR, end_time) >= @HoraInicioPico AND DATEPART(HOUR, end_time) < @HoraFimPico 
            THEN 'HORÁRIO DE PICO'
            ELSE 'FORA DO PICO'
        END AS [Periodo],
        CASE 
            WHEN AVG(avg_cpu_percent) > @LimiteCPUUpsize THEN 'CRÍTICO - CPU'
            WHEN AVG(avg_data_io_percent) > @LimiteIOUpsize THEN 'CRÍTICO - DATA IO'
            WHEN AVG(avg_log_write_percent) > @LimiteIOUpsize THEN 'CRÍTICO - LOG IO'
            WHEN AVG(avg_cpu_percent) > (@LimiteCPUUpsize * 0.8) THEN 'ATENÇÃO - CPU'
            ELSE 'NORMAL'
        END AS [Status_Hora]
    FROM sys.dm_db_resource_stats
    WHERE end_time >= @DataInicio AND end_time <= @DataFim
    GROUP BY DATEPART(HOUR, end_time)
    ORDER BY [Hora];
    
    -- 6. Top 15 Picos de Atividade (Momentos Críticos)
    SELECT TOP 15
        'TOP PICOS DE ATIVIDADE' AS [Categoria],
        end_time AS [Data_Hora],
        DATEPART(HOUR, end_time) AS [Hora],
        ROUND(avg_cpu_percent, 2) AS [CPU_Percent],
        ROUND(avg_data_io_percent, 2) AS [DataIO_Percent],
        ROUND(avg_log_write_percent, 2) AS [LogIO_Percent],
        ROUND((avg_cpu_percent + avg_data_io_percent + avg_log_write_percent), 2) AS [Total_Atividade],
        CASE 
            WHEN DATEPART(HOUR, end_time) >= @HoraInicioPico AND DATEPART(HOUR, end_time) < @HoraFimPico 
            THEN 'PICO NO HORÁRIO ESPERADO'
            ELSE 'PICO FORA DO HORÁRIO'
        END AS [Tipo_Pico],
        CASE 
            WHEN avg_cpu_percent > @LimiteCPUUpsize THEN 'CPU CRÍTICA'
            WHEN avg_data_io_percent > @LimiteIOUpsize THEN 'DATA IO CRÍTICO'
            WHEN avg_log_write_percent > @LimiteIOUpsize THEN 'LOG IO CRÍTICO'
            ELSE 'MÚLTIPLAS MÉTRICAS ALTAS'
        END AS [Motivo_Pico]
    FROM sys.dm_db_resource_stats
    WHERE end_time >= @DataInicio AND end_time <= @DataFim
    ORDER BY (avg_cpu_percent + avg_data_io_percent + avg_log_write_percent) DESC;
    
    -- 7. Análise de Tendência para Upsize (Últimos 7 dias vs Período Total)
    WITH UltimosSete AS (
        SELECT 
            AVG(avg_cpu_percent) AS CPU_Media_7d,
            MAX(avg_cpu_percent) AS CPU_Max_7d,
            AVG(avg_data_io_percent) AS DataIO_Media_7d,
            MAX(avg_data_io_percent) AS DataIO_Max_7d,
            AVG(avg_log_write_percent) AS LogIO_Media_7d,
            MAX(avg_log_write_percent) AS LogIO_Max_7d
        FROM sys.dm_db_resource_stats
        WHERE end_time >= DATEADD(DAY, -7, GETUTCDATE())
            AND end_time <= @DataFim
    ),
    PeriodoTotal AS (
        SELECT 
            AVG(avg_cpu_percent) AS CPU_Media_Total,
            MAX(avg_cpu_percent) AS CPU_Max_Total,
            AVG(avg_data_io_percent) AS DataIO_Media_Total,
            MAX(avg_data_io_percent) AS DataIO_Max_Total,
            AVG(avg_log_write_percent) AS LogIO_Media_Total,
            MAX(avg_log_write_percent) AS LogIO_Max_Total
        FROM sys.dm_db_resource_stats
        WHERE end_time >= @DataInicio AND end_time <= @DataFim
    )
    SELECT 
        'ANÁLISE DE TENDÊNCIA PARA UPSIZE' AS [Categoria],
        ROUND(us.CPU_Media_7d, 2) AS [CPU_Media_Ultimos_7d],
        ROUND(us.CPU_Max_7d, 2) AS [CPU_Max_Ultimos_7d],
        ROUND(pt.CPU_Media_Total, 2) AS [CPU_Media_Periodo_Total],
        ROUND(pt.CPU_Max_Total, 2) AS [CPU_Max_Periodo_Total],
        ROUND(us.DataIO_Media_7d, 2) AS [DataIO_Media_Ultimos_7d],
        ROUND(us.DataIO_Max_7d, 2) AS [DataIO_Max_Ultimos_7d],
        ROUND(pt.DataIO_Media_Total, 2) AS [DataIO_Media_Periodo_Total],
        ROUND(pt.DataIO_Max_Total, 2) AS [DataIO_Max_Periodo_Total],
        CASE 
            WHEN us.CPU_Media_7d > pt.CPU_Media_Total * 1.2 THEN 'CRESCIMENTO ACELERADO - CPU'
            WHEN us.DataIO_Media_7d > pt.DataIO_Media_Total * 1.2 THEN 'CRESCIMENTO ACELERADO - DATA IO'
            WHEN us.CPU_Media_7d > @LimiteCPUUpsize * 0.9 THEN 'PRÓXIMO DO LIMITE - CPU'
            WHEN us.DataIO_Media_7d > @LimiteIOUpsize * 0.9 THEN 'PRÓXIMO DO LIMITE - DATA IO'
            WHEN us.CPU_Media_7d < pt.CPU_Media_Total * 0.8 THEN 'TENDÊNCIA DE QUEDA'
            ELSE 'ESTÁVEL'
        END AS [Tendencia_Geral]
    FROM UltimosSete us, PeriodoTotal pt;
    
    -- 8. Recomendação Final para Upsize
    WITH ResumoFinal AS (
        SELECT 
            AVG(avg_cpu_percent) AS CPU_Media,
            MAX(avg_cpu_percent) AS CPU_Max,
            AVG(avg_data_io_percent) AS DataIO_Media,
            MAX(avg_data_io_percent) AS DataIO_Max,
            AVG(avg_log_write_percent) AS LogIO_Media,
            MAX(avg_log_write_percent) AS LogIO_Max,
            COUNT(*) AS Total_Registros
        FROM sys.dm_db_resource_stats
        WHERE end_time >= @DataInicio AND end_time <= @DataFim
    ),
    ResumoHorarioPico AS (
         SELECT 
             AVG(avg_cpu_percent) AS CPU_Media_Pico,
             MAX(avg_cpu_percent) AS CPU_Max_Pico,
             AVG(avg_data_io_percent) AS DataIO_Media_Pico,
             MAX(avg_data_io_percent) AS DataIO_Max_Pico,
             COUNT(*) AS Registros_Pico
         FROM sys.dm_db_resource_stats
         WHERE end_time >= @DataInicio AND end_time <= @DataFim
             AND DATEPART(HOUR, end_time) >= @HoraInicioPico 
             AND DATEPART(HOUR, end_time) < @HoraFimPico
     )
    SELECT 
        'RECOMENDAÇÃO FINAL PARA UPSIZE' AS [Categoria],
        ROUND(rf.CPU_Media, 2) AS [CPU_Media_Geral],
        ROUND(rf.CPU_Max, 2) AS [CPU_Max_Geral],
        ROUND(rhp.CPU_Media_Pico, 2) AS [CPU_Media_Horario_Pico],
        ROUND(rhp.CPU_Max_Pico, 2) AS [CPU_Max_Horario_Pico],
        ROUND(rf.DataIO_Media, 2) AS [DataIO_Media_Geral],
        ROUND(rf.DataIO_Max, 2) AS [DataIO_Max_Geral],
        ROUND(rhp.DataIO_Media_Pico, 2) AS [DataIO_Media_Horario_Pico],
        ROUND(rhp.DataIO_Max_Pico, 2) AS [DataIO_Max_Horario_Pico],
        rf.Total_Registros AS [Total_Amostras],
        rhp.Registros_Pico AS [Amostras_Horario_Pico],
        CASE 
            WHEN rhp.CPU_Max_Pico >= @LimiteCPUUpsize OR rhp.DataIO_Max_Pico >= @LimiteIOUpsize 
                 THEN 'UPSIZE RECOMENDADO - LIMITES ATINGIDOS NO HORÁRIO DE PICO'
            WHEN rhp.CPU_Media_Pico >= (@LimiteCPUUpsize * 0.85) OR rhp.DataIO_Media_Pico >= (@LimiteIOUpsize * 0.85) 
                 THEN 'UPSIZE RECOMENDADO - PRÓXIMO DOS LIMITES NO HORÁRIO DE PICO'
            WHEN rf.CPU_Max >= @LimiteCPUUpsize OR rf.DataIO_Max >= @LimiteIOUpsize 
                 THEN 'UPSIZE RECOMENDADO - LIMITES ATINGIDOS FORA DO HORÁRIO DE PICO'
            WHEN rhp.CPU_Media_Pico >= (@LimiteCPUUpsize * 0.70) AND rf.CPU_Media >= (@LimiteCPUUpsize * 0.50) 
                 THEN 'MONITORAR - CRESCIMENTO CONSISTENTE DE CPU'
            WHEN rhp.DataIO_Media_Pico >= (@LimiteIOUpsize * 0.70) AND rf.DataIO_Media >= (@LimiteIOUpsize * 0.50) 
                 THEN 'MONITORAR - CRESCIMENTO CONSISTENTE DE DATA IO'
            WHEN rhp.CPU_Media_Pico < (@LimiteCPUUpsize * 0.30) AND rhp.DataIO_Media_Pico < (@LimiteIOUpsize * 0.30) 
                 THEN 'RECURSOS SUBUTILIZADOS - CONSIDERAR DOWNSIZE'
            ELSE 'CONFIGURAÇÃO ATUAL ADEQUADA'
        END AS [Recomendacao_Upsize],
        CASE 
            WHEN rhp.CPU_Max_Pico >= @LimiteCPUUpsize THEN 'CPU atingiu limite no horário de pico'
            WHEN rhp.DataIO_Max_Pico >= @LimiteIOUpsize THEN 'Data IO atingiu limite no horário de pico'
            WHEN rf.CPU_Max >= @LimiteCPUUpsize THEN 'CPU atingiu limite fora do horário de pico'
            WHEN rf.DataIO_Max >= @LimiteIOUpsize THEN 'Data IO atingiu limite fora do horário de pico'
            WHEN rhp.CPU_Media_Pico >= (@LimiteCPUUpsize * 0.85) THEN 'CPU média próxima do limite no horário de pico'
            WHEN rhp.DataIO_Media_Pico >= (@LimiteIOUpsize * 0.85) THEN 'Data IO média próxima do limite no horário de pico'
            ELSE 'Recursos dentro dos parâmetros normais'
        END AS [Justificativa]
    FROM ResumoFinal rf, ResumoHorarioPico rhp;
        
    PRINT 'Análise de métricas históricas concluída para: ' + @NomeBanco;
END;
GO

/*
=============================================================================
EXEMPLO DE USO - ANÁLISE PARA UPSIZE AZURE SQL:
=============================================================================

-- Exemplo 1: Análise dos últimos 30 dias com parâmetros padrão
-- Horário de pico: 8h às 18h
-- Limites para upsize: 70% CPU e 70% IO
EXEC uspAnaliseMetricasUpsizeAzureSQL;

-- Exemplo 2: Análise dos últimos 7 dias para ambiente crítico
-- Horário de pico: 7h às 19h
-- Limites mais conservadores para upsize: 60% CPU e 60% IO
EXEC uspAnaliseMetricasUpsizeAzureSQL 
    @DataInicio = NULL,  -- Será calculado automaticamente (7 dias atrás)
    @DataFim = NULL,     -- Será calculado automaticamente (agora)
    @HoraInicioPico = 7,
    @HoraFimPico = 19,
    @LimiteCPUUpsize = 60.0,
    @LimiteIOUpsize = 60.0;

-- Exemplo 3: Análise de período específico para planejamento
-- Período: últimos 14 dias
-- Horário de pico: 6h às 20h
-- Limites mais agressivos para upsize: 80% CPU e 75% IO
EXEC uspAnaliseMetricasUpsizeAzureSQL 
    @DataInicio = '2024-01-01 00:00:00',
    @DataFim = '2024-01-15 23:59:59',
    @HoraInicioPico = 6,
    @HoraFimPico = 20,
    @LimiteCPUUpsize = 80.0,
    @LimiteIOUpsize = 75.0;

-- Exemplo 4: Análise para ambiente 24x7 (sem horário de pico definido)
-- Considera todo o período como crítico
EXEC uspAnaliseMetricasUpsizeAzureSQL 
    @HoraInicioPico = 0,
    @HoraFimPico = 24,
    @LimiteCPUUpsize = 65.0,
    @LimiteIOUpsize = 65.0;

=============================================================================
*/