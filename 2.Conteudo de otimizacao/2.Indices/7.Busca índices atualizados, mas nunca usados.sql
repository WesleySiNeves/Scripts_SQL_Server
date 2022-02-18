
/* ==================================================================
--Data: 19/10/2018 
--Autor :Wesley Neves
--Observação: identificar índices que estão sendo mantidos, mas não usados
 identifica índices em cluster  e não clusterizados que estão consumindo recursos, 
 em termos de gravações e manutenção, mas nunca estão sendo selecionados para uso 
 pelo otimizador, portanto, nunca foram lidos, pelo menos desde a última vez em que
  o cache foi limpo dados de uso. Ele usa uma convenção de nomenclatura 
  totalmente qualificada e é identificada 

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

