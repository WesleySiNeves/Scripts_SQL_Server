-- =============================================
-- Exemplo de Teste - Verificação de Horário e Parâmetro @Force
-- Procedure: HealthCheck.uspIndexDesfrag
-- =============================================
-- Este arquivo demonstra como testar a funcionalidade de verificação de horário
-- e o novo parâmetro @Force na procedure de desfragmentação de índices.
--
-- HORÁRIO PERMITIDO: 20:00 às 05:00
-- PARÂMETRO @Force: Se = 1, permite execução em qualquer horário
-- =============================================

-- 1. TESTE EM MODO DE ANÁLISE (sempre permitido)
-- Este modo apenas analisa os índices sem executar a desfragmentação
EXEC [HealthCheck].[uspIndexDesfrag] 
    @Efetivar = 0,  -- Modo análise
    @PriorityFilter = 3,
    @MaxDurationMinutes = 60;

-- 2. TESTE COM DESFRAGMENTAÇÃO (respeitando horário)
-- Este modo executa a desfragmentação apenas se estiver no horário permitido
EXEC [HealthCheck].[uspIndexDesfrag] 
    @Efetivar = 1,  -- Modo execução
    @PriorityFilter = 3,
    @MaxDurationMinutes = 30,
    @MaxCpuUsage = 80;

-- =============================================
-- 3. TESTE COM PARÂMETRO @Force = 1
-- =============================================
-- Este exemplo usa o parâmetro @Force = 1 para permitir execução
-- em qualquer horário, ignorando a restrição de 20:00-05:00

PRINT '=== TESTE 3: Execução com @Force = 1 (Simulação) ===';
EXEC [HealthCheck].[uspIndexDesfrag] 
    @Efetivar = 0,              -- Apenas simulação
    @PriorityFilter = 3,
    @MaxDurationMinutes = 30,
    @Force = 1;                 -- Força execução em qualquer horário

-- =============================================
-- 4. TESTE COM @Force = 1 E EXECUÇÃO REAL
-- =============================================
-- CUIDADO: Este exemplo executa realmente a desfragmentação
-- usando @Force = 1 para ignorar restrições de horário

PRINT '=== TESTE 4: Execução REAL com @Force = 1 ===';
-- DESCOMENTE APENAS SE QUISER EXECUTAR REALMENTE:
/*
EXEC [HealthCheck].[uspIndexDesfrag] 
    @Efetivar = 1,              -- EXECUÇÃO REAL!
    @PriorityFilter = 3,
    @MaxDurationMinutes = 30,
    @Force = 1;                 -- Força execução em qualquer horário
*/

-- 3. VERIFICAÇÃO DO HORÁRIO ATUAL
-- Para verificar se está no horário permitido
DECLARE @HorarioAtual TIME = CAST(GETDATE() AS TIME);
DECLARE @HorarioPermitido BIT = 0;

IF (@HorarioAtual >= '20:00:00' OR @HorarioAtual <= '05:00:00')
    SET @HorarioPermitido = 1;

SELECT 
    GETDATE() AS DataHoraAtual,
    @HorarioAtual AS HorarioAtual,
    CASE WHEN @HorarioPermitido = 1 
         THEN 'SIM - Desfragmentação permitida' 
         ELSE 'NÃO - Fora do horário permitido (20:00-05:00)' 
    END AS StatusPermissao;

-- =============================================
-- NOTAS IMPORTANTES:
-- =============================================
-- 1. HORÁRIO PERMITIDO: 20:00 às 05:00
--    - A desfragmentação só ocorre neste período
--    - Fora deste horário, apenas análise é permitida
--    - NOVO: Use @Force = 1 para ignorar restrições de horário
--
-- 2. PARÂMETROS PRINCIPAIS:
--    - @Efetivar = 0: Apenas análise (sempre permitido)
--    - @Efetivar = 1: Execução real (apenas no horário permitido)
--    - @PriorityFilter: Filtro de prioridade (1=Crítico, 2=Alto, 3=Médio, 4=Baixo)
--    - @MaxDurationMinutes: Tempo máximo de execução
--    - @MaxCpuUsage: Limite de CPU para execução
--    - @Force = 1: Permite execução em qualquer horário (use com cuidado!)
--
-- 3. PARÂMETRO @Force:
--    - Quando @Force = 1, ignora completamente a verificação de horário
--    - Use apenas em situações emergenciais ou manutenções programadas
--    - Sempre combine com @Efetivar = 0 primeiro para testar
--    - Logs mostrarão "(FORÇADO)" quando @Force = 1
--
-- 4. LOGS:
--    - A procedure exibe o horário atual e status de permissão
--    - Mensagens informativas sobre o motivo da não execução
--
-- 5. RECOMENDAÇÕES:
--    - Execute em modo análise primeiro (@Efetivar = 0)
--    - Use @Force = 1 apenas quando necessário
--    - Monitore CPU e duração durante execução
--    - Agende para período noturno (20:00-05:00) quando possível
--
-- 4. COMPORTAMENTO:
--    - No horário permitido: Executa normalmente
--    - Fora do horário: Exibe mensagem informativa e não executa
--    - Modo análise: Sempre executa independente do horário
-- =============================================