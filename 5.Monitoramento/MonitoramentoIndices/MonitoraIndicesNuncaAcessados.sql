/* ==================================================================
--Data: 17/10/2018 
--Autor :Wesley Neves
--Observação: Identifique índices que nunca foram acessados
 
 A Listagem 2 usa sys.indexes e sys.objects para localizar tabelas e índices
  no banco de dados atual que  não aparecem em sys.dm_db_index_usage_stats.
   Isso significa que esses índices não tiveram leituras ou gravações 
   desde que o SQL Server foi iniciado pela última vez ou
    porque o banco de dados atual foi fechado ou desanexado, o que for menor.
-- ==================================================================
*/

-- List unused indexes
SELECT OBJECT_NAME(i.object_id) AS [Table Name],
       i.object_id,
       i.name,
       i.type_desc,
	   o.create_date AS DataCriacao,
	   DiasNoBanco = DATEDIFF(DAY,o.create_date,GETDATE()),
       TotalLinhas = S.rowcnt
FROM sys.indexes AS i
     INNER JOIN
     sys.objects AS o ON i.object_id = o.object_id
     JOIN
     sys.sysindexes AS S ON S.id = i.object_id
                            AND S.name = i.name
WHERE i.index_id NOT IN (
                        SELECT ddius.index_id
                        FROM sys.dm_db_index_usage_stats AS ddius
                        WHERE ddius.object_id = i.object_id
                              AND i.index_id = ddius.index_id
                              AND ddius.database_id = DB_ID()
                        )
      AND o.type = 'U'
      AND i.type_desc <> 'CLUSTERED'
      AND S.rowcnt > 0
ORDER BY
    OBJECT_NAME(i.object_id) ASC;

