

/* ==================================================================
--Data: 30/04/2019 
--Autor :Wesley Neves
--Observação: 
O Repositório de Consultas coleta planos para Instruções DML, como SELECT, INSERT, UPDATE, DELETE, MERGE e BULK INSERT
 

Cenários comuns para o uso do recurso Repositório de Consultas são:
Localizar e corrigir rapidamente uma regressão de desempenho do plano, forçando o plano de consulta anterior.
 Corrigir consultas com regressão recente no desempenho devido a alterações no plano de execução.
Determinar o número de vezes que uma consulta foi executada em determinada janela de tempo, auxiliando um DBA na solução de problemas de recurso de desempenho.
Identificar as principais consultas n (por tempo de execução, consumo de memória, etc.) nas últimas x horas.
Fazer auditoria de histórico dos planos de consulta para determinada consulta.
Analisar os padrões de uso dos recursos (CPU, E/S e memória) para determinado banco de dados.
Identifique as principais n consultas que estão esperando em recursos.
Entenda a natureza de espera de um plano ou de uma consulta específica.
-- ==================================================================
*/


/* ==================================================================
--Data: 30/04/2019 
--Autor :Wesley Neves
--Observação: 
O Repositório de Consultas contém três repositórios:
um repositório de plano para persistir as informações do plano de execução.
um repositório de estatísticas de tempo de execução para manter as informações de estatísticas de execução.
um repositório de estatísticas de espera para manter as informações de estatísticas de espera.
 
-- ==================================================================
*/

SELECT TOP 10 * FROM sys.query_store_plan AS QSP



/* ==================================================================
--Data: 30/04/2019 
--Autor :Wesley Neves
--Observação: A consulta a seguir retorna informações sobre consultas e planos no repositório de consultas.
 
-- ==================================================================
*/

SELECT TOP 100 Txt.query_text_id, Txt.query_sql_text, Pl.plan_id, Qry.*  
FROM sys.query_store_plan AS Pl  
INNER JOIN sys.query_store_query AS Qry  
    ON Pl.query_id = Qry.query_id  
INNER JOIN sys.query_store_query_text AS Txt  
    ON Qry.query_text_id = Txt.query_text_id  
	ORDER BY Pl.query_id


/* ==================================================================
--Data: 30/04/2019 
--Autor :Wesley Neves
--Observação: Retorna a quantidae de planos de execução por query
 
-- ==================================================================
*/
SELECT (QSP.query_id) AS Query,
       COUNT(*) AS QuantidadePlanoExecucao
  FROM sys.query_store_plan AS QSP
 GROUP BY(QSP.query_id)
 ORDER BY QuantidadePlanoExecucao DESC
