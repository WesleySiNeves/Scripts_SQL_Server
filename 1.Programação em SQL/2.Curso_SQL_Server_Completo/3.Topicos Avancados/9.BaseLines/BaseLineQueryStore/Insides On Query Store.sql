

/* ==================================================================
--Data: 30/04/2019 
--Autor :Wesley Neves
--Observa��o: 
O Reposit�rio de Consultas coleta planos para Instru��es DML, como SELECT, INSERT, UPDATE, DELETE, MERGE e BULK INSERT
 

Cen�rios comuns para o uso do recurso Reposit�rio de Consultas s�o:
Localizar e corrigir rapidamente uma regress�o de desempenho do plano, for�ando o plano de consulta anterior.
 Corrigir consultas com regress�o recente no desempenho devido a altera��es no plano de execu��o.
Determinar o n�mero de vezes que uma consulta foi executada em determinada janela de tempo, auxiliando um DBA na solu��o de problemas de recurso de desempenho.
Identificar as principais consultas n (por tempo de execu��o, consumo de mem�ria, etc.) nas �ltimas x horas.
Fazer auditoria de hist�rico dos planos de consulta para determinada consulta.
Analisar os padr�es de uso dos recursos (CPU, E/S e mem�ria) para determinado banco de dados.
Identifique as principais n consultas que est�o esperando em recursos.
Entenda a natureza de espera de um plano ou de uma consulta espec�fica.
-- ==================================================================
*/


/* ==================================================================
--Data: 30/04/2019 
--Autor :Wesley Neves
--Observa��o: 
O Reposit�rio de Consultas cont�m tr�s reposit�rios:
um reposit�rio de plano para persistir as informa��es do plano de execu��o.
um reposit�rio de estat�sticas de tempo de execu��o para manter as informa��es de estat�sticas de execu��o.
um reposit�rio de estat�sticas de espera para manter as informa��es de estat�sticas de espera.
 
-- ==================================================================
*/

SELECT TOP 10 * FROM sys.query_store_plan AS QSP



/* ==================================================================
--Data: 30/04/2019 
--Autor :Wesley Neves
--Observa��o: A consulta a seguir retorna informa��es sobre consultas e planos no reposit�rio de consultas.
 
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
--Observa��o: Retorna a quantidae de planos de execu��o por query
 
-- ==================================================================
*/
SELECT (QSP.query_id) AS Query,
       COUNT(*) AS QuantidadePlanoExecucao
  FROM sys.query_store_plan AS QSP
 GROUP BY(QSP.query_id)
 ORDER BY QuantidadePlanoExecucao DESC
