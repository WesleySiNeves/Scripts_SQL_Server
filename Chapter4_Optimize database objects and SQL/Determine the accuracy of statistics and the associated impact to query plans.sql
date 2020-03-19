/*########################
# OBS: Optimize statistics and indexes
*/

/*########################
# OBS: Determinar a precisão das estatísticas e o impacto associado aos planos de consulta
e desempenho
*/

USE Lancamentos;

SELECT T.name,
       SchemaName = SCHEMA_NAME(T.schema_id),
       T.lock_escalation_desc,
       C.name,
       C.column_id
FROM sys.tables AS T
    JOIN sys.columns AS C
        ON C.object_id = T.object_id
WHERE T.name = 'Lancamentos';

SELECT '[Densidade quando mais chegar a 1 mais indicado para indice]';


SELECT  CONCAT('Coluna ','Credito') AS Coluna,
        CAST(COUNT(DISTINCT L.Credito) AS DECIMAL(18,2))  / CAST(COUNT(L.Credito) AS DECIMAL(18,2))  Densidade
FROM contabilidade.movimentos AS L


/*########################
# OBS: Review data distribution and cardinality
*/

