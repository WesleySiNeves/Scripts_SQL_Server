-- =============================================
-- Exemplo de Teste - Verificação de Horário e Parâmetro @Force
-- Procedure: HealthCheck.uspUpdateStats
-- =============================================
-- Este arquivo demonstra como testar a funcionalidade de verificação de horário
-- e o novo parâmetro @Force na procedure de atualização de estatísticas.
--
-- HORÁRIO PERMITIDO: 20:00 às 05:00
-- PARÂMETRO @Force: Se = 1, permite execução em qualquer horário
-- =============================================

-- 1. TESTE EM MODO DE ANÁLISE (sempre permitido)
-- Este modo apenas analisa as estatísticas sem executar a atualização
EXEC [HealthCheck].[uspUpdateStats] 
    @ExecutarAtualizacao = 0,  -- Modo análise
    @ModificationThreshold = 0.10,
    @DaysSinceLastUpdate = 30,
    @MostrarProgresso = 1,
    @LogDetalhado = 1;

-- 2. TESTE COM ATUALIZAÇÃO (respeitando horário)
-- Este modo executa a atualização apenas se estiver no horário permitido
EXEC [HealthCheck].[uspUpdateStats] 
    @ExecutarAtualizacao = 1,  -- Modo execução
    @ModificationThreshold = 0.15,
    @DaysSinceLastUpdate = 7,
    @MostrarProgresso = 1,
    @MaxParallelism = 2,
    @SamplePercent = 20,
    @TimeoutSegundos = 300,
    @LogDetalhado = 1;

-- 3. TESTE COM PARÂMETRO @Force = 1 (SIMULAÇÃO)
-- Este exemplo usa o parâmetro @Force = 1 para permitir execução
-- em qualquer horário, ignorando a restrição de 20:00-05:00
EXEC [HealthCheck].[uspUpdateStats] 
    @ExecutarAtualizacao = 0,  -- Apenas simulação
    @ModificationThreshold = 0.20,
    @DaysSinceLastUpdate = 15,
    @Force = 1,                -- Força execução em qualquer horário
    @MostrarProgresso = 1,
    @LogDetalhado = 1;

-- 4. TESTE COM @Force = 1 E EXECUÇÃO REAL
-- CUIDADO: Este exemplo executa realmente a atualização de estatísticas
-- usando @Force = 1 para ignorar restrições de horário
-- DESCOMENTE APENAS SE QUISER EXECUTAR REALMENTE:
/*
EXEC [HealthCheck].[uspUpdateStats] 
    @ExecutarAtualizacao = 1,  -- EXECUÇÃO REAL!
    @ModificationThreshold = 0.20,
    @DaysSinceLastUpdate = 15,
    @Force = 1,                -- Força execução em qualquer horário
    @MostrarProgresso = 1,
    @LogDetalhado = 1;
*/

-- 4. VERIFICAÇÃO DO HORÁRIO ATUAL
-- Para verificar se está no horário permitido
DECLARE @HorarioAtual TIME = CAST(GETDATE() AS TIME);
DECLARE @HorarioPermitido BIT = 0;

IF (@HorarioAtual >= '20:00:00' OR @HorarioAtual <= '05:00:00')
    SET @HorarioPermitido = 1;

SELECT 
    GETDATE() AS DataHoraAtual,
    @HorarioAtual AS HorarioAtual,
    CASE WHEN @HorarioPermitido = 1 
         THEN 'SIM - Atualização de estatísticas permitida' 
         ELSE 'NÃO - Fora do horário permitido (20:00-05:00)' 
    END AS StatusPermissao;

-- =============================================
-- NOTAS IMPORTANTES:
-- =============================================
-- 1. HORÁRIO PERMITIDO: 20:00 às 05:00
--    - A atualização só ocorre neste período
--    - Fora deste horário, apenas análise é permitida
--    - NOVO: Use @Force = 1 para ignorar restrições de horário
--
-- 2. PARÂMETROS PRINCIPAIS:
--    - @ExecutarAtualizacao = 0: Apenas análise (sempre permitido)
--    - @ExecutarAtualizacao = 1: Execução real (apenas no horário permitido)
--    - @ModificationThreshold: Limite de modificações (0.10 = 10%)
--    - @DaysSinceLastUpdate: Dias desde última atualização
--    - @ForcarExecucao = 1: Força execução mesmo fora do horário (OBSOLETO)
--    - @Force = 1: Permite execução em qualquer horário (NOVO!)
--    - @MaxParallelism: Grau máximo de paralelismo
--    - @SamplePercent: Percentual de amostragem (NULL = padrão)
--    - @TimeoutSegundos: Timeout por comando
--
-- 3. PARÂMETRO @Force:
--    - Quando @Force = 1, ignora completamente a verificação de horário
--    - Use apenas em situações emergenciais ou manutenções programadas
--    - Sempre combine com @ExecutarAtualizacao = 0 primeiro para testar
--    - Logs mostrarão "(FORÇADO)" quando @Force = 1
--    - Substitui o antigo @ForcarExecucao com funcionalidade aprimorada
--
-- 4. LOGS:
--    - A procedure exibe o horário atual e status de permissão
--    - Mensagens informativas sobre o motivo da não execução
--    - Progresso detalhado durante a execução
--
-- 5. RECOMENDAÇÕES:
--    - Execute em modo análise primeiro (@ExecutarAtualizacao = 0)
--    - Use @Force = 1 apenas quando necessário
--    - Monitore o progresso e performance durante execução
--    - Agende para período noturno (20:00-05:00) quando possível
--    - Ajuste @ModificationThreshold conforme necessidade
--    - Use @SamplePercent para controlar tempo de execução
--
-- 6. COMPORTAMENTO:
--    - No horário permitido: Executa normalmente
--    - Com @Force = 1: Ignora verificação de horário
--    - Fora do horário: Exibe mensagem informativa e não executa
--    - Modo análise: Sempre executa independente do horário
--    - Forçar execução: Permite execução fora do horário com aviso
--
-- 5. PRIORIZAÇÃO:
--    - Score baseado em percentual de modificação (70%) e idade (30%)
--    - Classificação: CRÍTICA, ALTA, MÉDIA, BAIXA
--    - Execução ordenada por prioridade
-- =============================================