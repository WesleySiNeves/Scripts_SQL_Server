
USE AdventureWorks2016;
/*########################
# OBS: Query Store components

O armazenamento de consultas captura informações sobre planos de consulta e estatísticas de execução de tempo de execução
até que a alocação máxima de espaço seja atingida. Você pode revisar esses dados nas seguintes
DMVs:
*/


/*########################
# OBS: 1)sys.query_store_plan
Informações do plano de consulta, como Showplan XML, o número
de compilações, a data e hora da primeira e última compilações, a última
data e hora de execução, e a duração média e mais recente da compilação,
entre outros detalhes. O plano de consulta disponível neste DMV é apenas o plano estimado
*/
SELECT * FROM sys.query_store_plan AS QSP


/*########################
# OBS: 2) sys.query_store_query
Estatísticas de execução de tempo de execução agregada para uma consulta,
incluindo estatísticas de ligação, memória, otimização e compilação de CPU. este
informações são armazenadas no nível de instrução e não no nível de lote que é
diferente do comportamento de sys.dm_exec_query_stats.
*/
SELECT * FROM  sys.query_store_query AS QSQ



/*########################
# OBS: 3) sys.query_store_query_text
 The text of the executed query.
*/

SELECT * FROM  sys.query_store_query_text AS QSQT


/*########################
# OBS: 4) sys.query_store_runtime_stats

Estatísticas de execução em tempo de execução para uma consulta, como
primeira e última data e hora de execução, o número de execuções, estatísticas (média,
último, mínimo, máximo e desvio padrão) para duração da consulta, tempo de CPU,
IO lógico lê e grava, IO físico lê e escreve, tempo de CLR, DOP, máximo
memória usada e contagens de linhas
*/

SELECT * FROM  sys.query_store_runtime_stats AS QSRS


/*########################
# OBS: 5) sys.query_store_runtime_stats_interval 
Os horários de início e término definindo
intervalos durante os quais o SQL Server coleta estatísticas de execução de tempo de execução para a consulta
loja

*/


/*########################
# OBS: exemplo 
5 principais consultas com as maiores leituras lógicas médias

*/


USE WideWorldImporters;
GO
SELECT TOP 5 
qt.query_sql_text,
CAST(query_plan AS XML) AS QueryPlan,
rs.avg_logical_io_reads
FROM sys.query_store_plan qp
INNER JOIN sys.query_store_query q
ON qp.query_id = q.query_id
INNER JOIN sys.query_store_query_text qt
ON q.query_text_id = qt.query_text_id
INNER JOIN sys.query_store_runtime_stats rs
ON qp.plan_id = rs.plan_id
ORDER BY rs.avg_logical_io_reads DESC;

/*########################
# OBS: Você pode usar os seguintes procedimentos armazenados do sistema para gerenciar o armazenamento de consulta:

1)sp_query_store_flush_db 
Limpe a parte do armazenamento de consulta atualmente na memória para
disco. Este procedimento armazenado não leva argumentos
*/

/*########################
# OBS: 2)sp_query_store_force_plan
 Força o SQL Server a usar um plano de consulta especificado para um
consulta especificada. Você fornece identificadores para a consulta e planeja como argumentos para isso
procedimento armazenado.
*/


/*########################
# OBS:3) sp_query_store_remove_plan 
Remove a specified query plan from the query store.

*/

/*########################
# OBS: sp_query_store_remove_query 
Remove uma consulta especificada do armazenamento de consulta, em
além dos planos de consulta e estatísticas de execução de tempo de execução relacionadas a ele
*/

/*########################
# OBS: sp_query_store_reset_exec_stats
 Redefinir as estatísticas de execução de tempo de execução para um plano especificado.
*/