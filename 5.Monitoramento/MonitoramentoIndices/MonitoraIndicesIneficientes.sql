/* ==================================================================
--Data: 17/10/2018 
--Autor :Wesley Neves
--Observação: Identifique índices ineficientes
Nossa consulta final sys.dm_db_index_usage_stats é filtrada pelo banco de dados atual e
 inclui apenas índices não clusterizados. Ele pode ajudá-lo a decidir se o custo de
  manutenção de um determinado índice supera o benefício que você está recebendo de tê-lo no lugar
 

 OBS:
 Certifique-se de que a instância do SQL Server esteja em execução por tempo suficiente 
 para garantir que a carga de trabalho típica completa seja representada nas estatísticas 
 relatadas. Novamente, não se esqueça de cargas de trabalho de relatórios periódicas
  que podem não aparecer na carga de trabalho do dia-a-dia. Embora os índices que 
  facilitam essas cargas de trabalho sejam usados ??com pouca freqüência, sua presença será crítica.
-- ==================================================================
*/

DROP TABLE IF EXISTS #candidates;

DROP TABLE IF EXISTS #indexusage;
CREATE TABLE #indexusage (
                         [object_id]    INT,
                         [index_id]     INT,
                         [user_seeks]   BIGINT,
                         [user_scans]   BIGINT,
                         [user_lookups] BIGINT,
                         [user_updates] BIGINT
                         );

INSERT INTO #indexusage
SELECT s.object_id,
       s.index_id,
       s.user_seeks,
       s.user_scans,
       s.user_lookups,
       s.user_updates
FROM sys.dm_db_index_usage_stats AS s
WHERE s.database_id = DB_ID();


-- Potentially inefficent non-clustered indexes (writes > reads)
WITH Dados AS (
SELECT SCHEMA_NAME(T.schema_id) AS SCHEMANAME,
       T.name AS [Table Name],
       ddius.object_id,
       i.name AS [Index Name],
       i.index_id,
       ddius.user_updates AS [Total Writes],
       ddius.user_seeks + ddius.user_scans + ddius.user_lookups AS [Total Reads],
       (ddius.user_updates - (ddius.user_seeks + ddius.user_scans + ddius.user_lookups)) * -1 AS [Difference],
	   SumWhite =(SUM(I2.user_updates) OVER (PARTITION BY I.object_id)) * 1.0,
	   SumReads =SUM(I2.user_scans + I2.user_seeks + I2.user_lookups) OVER (PARTITION BY I.object_id)
	   
FROM sys.dm_db_index_usage_stats AS ddius WITH (NOLOCK)
JOIN #indexusage AS I2 ON ddius.object_id = I2.object_id
     INNER JOIN
     sys.indexes AS i WITH (NOLOCK) ON ddius.object_id = i.object_id
                                       AND i.index_id = ddius.index_id
     JOIN
     sys.tables AS T ON ddius.object_id = T.object_id
WHERE OBJECTPROPERTY(ddius.object_id, 'IsUserTable') = 1
      --AND ddius.database_id = DB_ID()
      AND ddius.user_updates > (ddius.user_seeks + ddius.user_scans + ddius.user_lookups)
      AND i.index_id > 1
      AND SCHEMA_NAME(T.schema_id) NOT IN ( 'HangFire' )
	  
),
Custo AS (
SELECT R.SCHEMANAME,
       R.[Table Name],
       R.object_id,
       R.[Index Name],
       R.index_id,
       R.[Total Writes],
       R.[Total Reads],
       R.Difference,
	   [write:read ratio] = CONVERT(
                                            DECIMAL(18, 2),
                                           [Total Writes]
                                            / IIF(R.[Total Reads] = 0 ,1, R.[Total Reads])
                                        )
	   FROM Dados R
	   WHERE R.[Total Reads] = 0
)
SELECT * FROM  Custo R
WHERE R.[write:read ratio]  > 1 --Bad Index
ORDER BY
    R.[Difference] DESC,
    R.[Total Writes] DESC,
    R.[Total Reads] ASC;
	