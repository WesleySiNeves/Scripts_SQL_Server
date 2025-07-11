-- Exemplo de uso da procedure de análise de métricas para upsize/downsize
-- Substitua as datas conforme necessário

-- Análise dos últimos 7 dias
EXEC [dbo].[uspAnaliseMetricasUpsizeDownsize]
    @DataInicio = '2024-01-15 00:00:00',
    @DataFim = '2024-01-22 23:59:59',
    @HoraInicioAnalise = '08:00:00',
    @HoraFimAnalise = '18:00:00';

-- Análise dos últimos 30 dias
EXEC [dbo].[uspAnaliseMetricasUpsizeDownsize]
    @DataInicio = '2023-12-23 00:00:00',
    @DataFim = '2024-01-22 23:59:59',
    @HoraInicioAnalise = '08:00:00',
    @HoraFimAnalise = '18:00:00';

-- Análise com horário personalizado (ex: 7h às 19h)
EXEC [dbo].[uspAnaliseMetricasUpsizeDownsize]
    @DataInicio = '2024-01-15 00:00:00',
    @DataFim = '2024-01-22 23:59:59',
    @HoraInicioAnalise = '07:00:00',
    @HoraFimAnalise = '19:00:00';