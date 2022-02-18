
/* ==================================================================
--Data: 19/10/2018 
--Autor :Wesley Neves
--Observa��o: identificar �ndices que est�o sendo mantidos, mas n�o usados
 identifica �ndices em cluster  e n�o clusterizados que est�o consumindo recursos, 
 em termos de grava��es e manuten��o, mas nunca est�o sendo selecionados para uso 
 pelo otimizador, portanto, nunca foram lidos, pelo menos desde a �ltima vez em que
  o cache foi limpo dados de uso. Ele usa uma conven��o de nomenclatura 
  totalmente qualificada e � identificada 

-- ==================================================================
*/


WITH Dados AS  (
SELECT  OBJECT_NAME(ddius.[object_id], ddius.database_id) AS [object_name] ,
        ddius.index_id ,
        ddius.user_seeks ,
        ddius.user_scans ,
        ddius.user_lookups ,
        ddius.user_seeks + ddius.user_scans + ddius.user_lookups 
                                                     AS user_reads ,
        ddius.user_updates AS user_writes ,
        ddius.last_user_scan ,
        ddius.last_user_update
FROM    sys.dm_db_index_usage_stats ddius
WHERE   ddius.database_id > 4 -- filter out system tables
        AND OBJECTPROPERTY(ddius.OBJECT_ID, 'IsUserTable') = 1
        AND ddius.index_id > 0
)
SELECT * FROM  Dados R
WHERE user_reads = 0

