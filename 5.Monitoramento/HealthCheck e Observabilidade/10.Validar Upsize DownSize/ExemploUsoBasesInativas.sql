-- Exemplos de uso da procedure para identificar bases inativas
-- Execute no banco MASTER do Azure SQL Elastic Pool

-- Análise padrão (últimos 30 dias)
EXEC [dbo].[uspIdentificarBasesInativas];

-- Análise dos últimos 7 dias (mais restritiva)
EXEC [dbo].[uspIdentificarBasesInativas]
    @DiasAnalise = 7,
    @LimiteConexoes = 2,
    @LimiteCPUPercent = 0.5,
    @LimiteIOPercent = 0.5,
    @ExibirDetalhes = 1;

-- Análise dos últimos 60 dias (mais abrangente)
EXEC [dbo].[uspIdentificarBasesInativas]
    @DiasAnalise = 60,
    @LimiteConexoes = 10,
    @LimiteCPUPercent = 2.0,
    @LimiteIOPercent = 2.0,
    @ExibirDetalhes = 1;

-- Análise apenas para identificar bancos sem nenhuma métrica
EXEC [dbo].[uspIdentificarBasesInativas]
    @DiasAnalise = 30,
    @LimiteConexoes = 0,
    @LimiteCPUPercent = 0,
    @LimiteIOPercent = 0,
    @ExibirDetalhes = 0;