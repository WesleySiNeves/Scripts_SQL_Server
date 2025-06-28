
USE AdventureWorks2016;
/*########################
# OBS: Query Store components

O armazenamento de consultas captura informa��es sobre planos de consulta e estat�sticas de execu��o de tempo de execu��o
at� que a aloca��o m�xima de espa�o seja atingida. Voc� pode revisar esses dados nas seguintes
DMVs:
*/


/*########################
# OBS: 1)sys.query_store_plan
Informa��es do plano de consulta, como Showplan XML, o n�mero
de compila��es, a data e hora da primeira e �ltima compila��es, a �ltima
data e hora de execu��o, e a dura��o m�dia e mais recente da compila��o,
entre outros detalhes. O plano de consulta dispon�vel neste DMV � apenas o plano estimado
*/
SELECT * FROM sys.query_store_plan AS QSP


/*########################
# OBS: 2) sys.query_store_query
Estat�sticas de execu��o de tempo de execu��o agregada para uma consulta,
incluindo estat�sticas de liga��o, mem�ria, otimiza��o e compila��o de CPU. este
informa��es s�o armazenadas no n�vel de instru��o e n�o no n�vel de lote que �
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

Estat�sticas de execu��o em tempo de execu��o para uma consulta, como
primeira e �ltima data e hora de execu��o, o n�mero de execu��es, estat�sticas (m�dia,
�ltimo, m�nimo, m�ximo e desvio padr�o) para dura��o da consulta, tempo de CPU,
IO l�gico l� e grava, IO f�sico l� e escreve, tempo de CLR, DOP, m�ximo
mem�ria usada e contagens de linhas
*/

SELECT * FROM  sys.query_store_runtime_stats AS QSRS


/*########################
# OBS: 5) sys.query_store_runtime_stats_interval 
Os hor�rios de in�cio e t�rmino definindo
intervalos durante os quais o SQL Server coleta estat�sticas de execu��o de tempo de execu��o para a consulta
loja

*/


/*########################
# OBS: exemplo 
5 principais consultas com as maiores leituras l�gicas m�dias

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
# OBS: Voc� pode usar os seguintes procedimentos armazenados do sistema para gerenciar o armazenamento de consulta:

1)sp_query_store_flush_db 
Limpe a parte do armazenamento de consulta atualmente na mem�ria para
disco. Este procedimento armazenado n�o leva argumentos
*/

/*########################
# OBS: 2)sp_query_store_force_plan
 For�a o SQL Server a usar um plano de consulta especificado para um
consulta especificada. Voc� fornece identificadores para a consulta e planeja como argumentos para isso
procedimento armazenado.
*/


/*########################
# OBS:3) sp_query_store_remove_plan 
Remove a specified query plan from the query store.

*/

/*########################
# OBS: sp_query_store_remove_query 
Remove uma consulta especificada do armazenamento de consulta, em
al�m dos planos de consulta e estat�sticas de execu��o de tempo de execu��o relacionadas a ele
*/

/*########################
# OBS: sp_query_store_reset_exec_stats
 Redefinir as estat�sticas de execu��o de tempo de execu��o para um plano especificado.
*/