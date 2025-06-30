/*
==============================================================================
Exemplo de Teste - Verificação de Horário e Parâmetro @Force
Arquivo: Exemplo_Teste_Horario.sql
Descrição: Script de exemplo para testar a funcionalidade de verificação de horário
           e o novo parâmetro @Force na procedure HealthCheck.uspAutoCreateIndex
==============================================================================
*/

-- Exemplo 1: Execução em modo de análise (sem criar índices)
-- Este exemplo sempre funcionará independente do horário
EXEC HealthCheck.uspAutoCreateIndex 
    @Efetivar = 0,                    -- Não efetiva as alterações
    @VisualizarMissing = 1,           -- Mostra os missing indexes
    @VisualizarCreate = 1,            -- Mostra os índices a serem criados
    @VisualizarAlteracoes = 1,        -- Mostra as alterações propostas
    @ModoDebug = 1,                   -- Ativa logs detalhados
    @SomenteAnalise = 1;              -- Apenas análise

GO

-- Exemplo 2: Execução com criação de índices (respeitando horário)
-- Este exemplo só criará índices entre 20:00 e 05:00
EXEC HealthCheck.uspAutoCreateIndex 
    @Efetivar = 1,                    -- Efetiva as alterações
    @MaxIndicesProcessar = 5,         -- Limita a 5 índices por execução
    @TamanhoLote = 3,                 -- Processa em lotes de 3
    @ModoDebug = 1,                   -- Ativa logs detalhados
    @defaultTunningPerform = 500;     -- Threshold de performance

GO

-- =============================================
-- 3. TESTE COM PARÂMETRO @Force = 1
-- =============================================
-- Este exemplo usa o parâmetro @Force = 1 para permitir execução
-- em qualquer horário, ignorando a restrição de 20:00-05:00

PRINT '=== TESTE 3: Execução com @Force = 1 (Simulação) ===';
EXEC [HealthCheck].[uspAutoCreateIndex] 
    @Efetivar = 0,              -- Apenas simulação
    @VisualizarCreate = 1,      -- Mostra scripts de criação
    @ModoDebug = 1,             -- Logs detalhados
    @Force = 1;                 -- Força execução em qualquer horário
GO

-- =============================================
-- 4. TESTE COM @Force = 1 E EXECUÇÃO REAL
-- =============================================
-- CUIDADO: Este exemplo executa realmente a criação de índices
-- usando @Force = 1 para ignorar restrições de horário

PRINT '=== TESTE 4: Execução REAL com @Force = 1 ===';
-- DESCOMENTE APENAS SE QUISER EXECUTAR REALMENTE:
/*
EXEC [HealthCheck].[uspAutoCreateIndex] 
    @Efetivar = 1,              -- EXECUÇÃO REAL!
    @VisualizarCreate = 1,      -- Mostra scripts de criação
    @ModoDebug = 1,             -- Logs detalhados
    @Force = 1;                 -- Força execução em qualquer horário
*/
GO

-- Exemplo 4: Verificação do horário atual
SELECT 
    GETDATE() AS DataHoraAtual,
    CAST(GETDATE() AS TIME) AS HorarioAtual,
    CASE 
        WHEN CAST(GETDATE() AS TIME) >= '20:00:00' OR CAST(GETDATE() AS TIME) <= '05:00:00'
        THEN 'PERMITIDO - Criação de índices autorizada'
        ELSE 'BLOQUEADO - Fora do horário permitido (20:00-05:00)'
    END AS StatusCriacaoIndices;

GO

/*
==============================================================================
NOTAS IMPORTANTES:

1. HORÁRIO PERMITIDO: 20:00 às 05:00
   - A criação de índices só ocorre neste período
   - Fora deste horário, apenas análise é realizada
   - NOVO: Use @Force = 1 para ignorar restrições de horário

2. PARÂMETROS IMPORTANTES:
   - @Efetivar = 1: Necessário para criar índices
   - @ModoDebug = 1: Mostra logs detalhados incluindo verificação de horário
   - @SomenteAnalise = 1: Força apenas análise, ignorando @Efetivar
   - @Force = 1: Permite execução em qualquer horário (use com cuidado!)

3. PARÂMETRO @Force:
   - Quando @Force = 1, ignora completamente a verificação de horário
   - Use apenas em situações emergenciais ou manutenções programadas
   - Sempre combine com @Efetivar = 0 primeiro para testar
   - Logs mostrarão "(FORÇADO)" quando @Force = 1

4. LOGS DE HORÁRIO:
   - Com @ModoDebug = 1, você verá: "Horário atual: HH:mm:ss - Criação permitida: SIM/NÃO"
   - Se fora do horário: "AVISO: Criação de índices não executada..."

5. RECOMENDAÇÕES:
   - Execute em modo análise primeiro (@Efetivar = 0)
   - Use @MaxIndicesProcessar para limitar o impacto
   - Use @Force = 1 apenas quando necessário
   - Monitore os logs durante a execução
   - Agende a execução para o período noturno (20:00-05:00) quando possível
==============================================================================
*/