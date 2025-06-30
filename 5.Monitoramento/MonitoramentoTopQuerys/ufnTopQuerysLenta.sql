/* ==================================================================
--Data: 08/11/2018 
--Autor: Wesley Neves
--Observação: Função para identificar as queries mais lentas
--Versão: 2.0 - Otimizada
-- ==================================================================
*/

-- Nome mais simples
/* ==================================================================
--Data: 08/11/2018 
--Autor: Wesley Neves
--Observação: Função para identificar as queries mais lentas
--Versão: 2.1 - Corrigida
-- ==================================================================
*/

CREATE OR ALTER FUNCTION HealthCheck.[ufnTopQuerys] 
(
    @Quantidade SMALLINT = 10,
    @MinExecucoes INT = 5
)
RETURNS TABLE
RETURN
WITH Dados AS 
(
    SELECT 
        -- Informações básicas
        [Banco_Dados] = DB_NAME(ST.dbid),
        
        -- Query Text corrigida - problema estava aqui
        [Query_Text] = CASE 
            WHEN QS.statement_start_offset = 0 AND QS.statement_end_offset = -1 
            THEN ST.text
            ELSE SUBSTRING(
                ST.text, 
                (QS.statement_start_offset / 2) + 1,
                ((CASE QS.statement_end_offset
                    WHEN -1 THEN DATALENGTH(ST.text)
                    ELSE QS.statement_end_offset
                END - QS.statement_start_offset) / 2) + 1
            )
        END,
        
        [Objeto] = ISNULL(OBJECT_NAME(QP.objectid, ST.dbid), 'Ad-hoc Query'),
        
        -- Contadores de execução
        QS.execution_count,
        QS.creation_time,
        QS.last_execution_time,
        
        -- Métricas de tempo (já convertidas para segundos)
        [Ultimo_Tempo_Seg] = CAST(QS.last_elapsed_time / 1000000.0 AS DECIMAL(18,6)),
        [Tempo_Medio_Seg] = CASE 
            WHEN QS.execution_count > 0 
            THEN CAST((QS.total_elapsed_time / QS.execution_count) / 1000000.0 AS DECIMAL(18,6))
            ELSE 0
        END,
        [CPU_Medio_Seg] = CASE 
            WHEN QS.execution_count > 0 
            THEN CAST((QS.total_worker_time / QS.execution_count) / 1000000.0 AS DECIMAL(18,6))
            ELSE 0
        END,
        
        -- Métricas de I/O
        QS.last_logical_reads,
        [Leituras_Medias] = CASE 
            WHEN QS.execution_count > 0 
            THEN QS.total_logical_reads / QS.execution_count
            ELSE 0
        END,
        [Escritas_Medias] = CASE 
            WHEN QS.execution_count > 0 
            THEN QS.total_logical_writes / QS.execution_count
            ELSE 0
        END,
        
        -- Métricas de memória
        QS.last_grant_kb,
        QS.last_used_grant_kb,
        QS.last_ideal_grant_kb,
        QS.last_spills,
        
        -- Totais
        QS.total_logical_reads,
        QS.total_logical_writes,
        
        -- Plano de execução
        QP.query_plan
        
    FROM sys.dm_exec_query_stats AS QS
    CROSS APPLY sys.dm_exec_sql_text(QS.sql_handle) AS ST
    CROSS APPLY sys.dm_exec_query_plan(QS.plan_handle) AS QP
    WHERE DB_NAME(ST.dbid) = DB_NAME(DB_ID())
      AND QS.execution_count >= @MinExecucoes
      AND ST.text IS NOT NULL
)
SELECT 
    D.Banco_Dados,
    D.Objeto,
    D.Query_Text,
    [Qtd_Execucoes] = D.execution_count,
    [Data_Criacao] = D.creation_time,
    [Ultima_Execucao] = D.last_execution_time,
    
    -- Métricas de tempo
    D.Ultimo_Tempo_Seg,
    D.Tempo_Medio_Seg,
    D.CPU_Medio_Seg,
    
    -- Métricas de I/O com conversões
    D.last_logical_reads,
    [Ultimas_Leituras_MB] = CAST((D.last_logical_reads * 8.0) / 1024 AS DECIMAL(18,2)),
    D.Leituras_Medias,
    D.Escritas_Medias,
    
    -- Métricas de memória
    [Memoria_Reservada_KB] = D.last_grant_kb,
    [Memoria_Utilizada_KB] = D.last_used_grant_kb,
    [Memoria_Ideal_KB] = D.last_ideal_grant_kb,
    [Spills] = D.last_spills,
    
    -- Totais
    [Total_Leituras] = D.total_logical_reads,
    [Total_Leituras_MB] = CAST((D.total_logical_reads * 8.0) / 1024 AS DECIMAL(18,2)),
    [Total_Escritas] = D.total_logical_writes,
    
    -- Plano de execução
    D.query_plan AS [Plano_Execucao]
    
FROM Dados D
ORDER BY D.Tempo_Medio_Seg DESC
OFFSET 0 ROWS FETCH NEXT @Quantidade ROWS ONLY;
