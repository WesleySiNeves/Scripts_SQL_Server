IF (OBJECT_ID('TEMPDB..#BytesPorRow') IS NOT NULL)
    DROP TABLE #BytesPorRow;

CREATE TABLE #BytesPorRow (
                          [object_id]  INT,
                          [SchemaName] NVARCHAR(128),
                          [TableName]  NVARCHAR(128),
                          [Rows]       BIGINT,
                          [GB]         DECIMAL(33, 12),
                          [Bytes/Row]  BIGINT
                          );


INSERT INTO #BytesPorRow
SELECT T.object_id,
       S2.name AS SchemaName,
       T.name AS TableName,
       MAX(s.row_count) AS 'Rows',
       SUM(s.reserved_page_count) * 8.0 / (1024 * 1024) AS 'GB',
       (8 * 1024 * SUM(s.reserved_page_count)) / (MAX(s.row_count)) AS 'Bytes/Row'
FROM sys.dm_db_partition_stats s
     JOIN
     sys.tables AS T ON T.object_id = s.object_id
     JOIN
     sys.schemas AS S2 ON S2.schema_id = T.schema_id
GROUP BY
    T.object_id,
    S2.name,
    T.name
HAVING MAX(s.row_count) > 0
ORDER BY
    GB DESC;





WITH Dados
  AS (SELECT t.object_id,
             [Nome Tabela] = t.name,
             [Nome Schema] = s.name,
             [Quantidade Registros] = p.rows,
             SUM(a.total_pages) * 8 AS TotalSpaceKB,
             SUM(a.used_pages) * 8 AS UsedSpaceKB,
             (SUM(a.total_pages) - SUM(a.used_pages)) * 8 AS UnusedSpaceKB
      FROM sys.tables t
           INNER JOIN
           sys.indexes i ON t.object_id = i.object_id
           INNER JOIN
           sys.partitions p ON i.object_id = p.object_id
                               AND i.index_id = p.index_id
           INNER JOIN
           sys.allocation_units a ON p.partition_id = a.container_id
           LEFT OUTER JOIN
           sys.schemas s ON t.schema_id = s.schema_id
      GROUP BY
          t.object_id,
          t.name,
          s.name,
          p.rows
     ),
     Projecao
  AS (SELECT R.object_id,
             R.[Nome Tabela],
             R.[Nome Schema],
             R.[Quantidade Registros],
             R.TotalSpaceKB,
             [TotalAlocadoMB] = CONCAT(CAST(CAST((R.TotalSpaceKB / 1024) AS DECIMAL(18, 2)) AS VARCHAR(100)), ' MB'),
             [TotalMB] = CAST((R.TotalSpaceKB / 1024) AS DECIMAL(18, 2)),
             R.UsedSpaceKB,
             [TotalUsadoMB] = CONCAT((R.UsedSpaceKB / 1024), ' MB'),
             R.UnusedSpaceKB,
             [TotaReservadoMB] = CONCAT((R.UnusedSpaceKB / 1024), ' MB')
      FROM Dados R
     )
SELECT P.object_id,
       P.[Nome Schema],
       P.[Nome Tabela],
	   BPR.[Bytes/Row],
       FORMAT(P.[Quantidade Registros], 'N0', 'Pt-Br') [Quantidade Registros],
       P.TotalSpaceKB,
       P.TotalMB,
       P.TotalAlocadoMB,
       P.UsedSpaceKB,
       P.TotalUsadoMB,
       P.UnusedSpaceKB,
       P.TotaReservadoMB
FROM Projecao P
     LEFT JOIN
     #BytesPorRow AS BPR ON BPR.object_id = P.object_id
WHERE P.TotalSpaceKB > 0
--AND P.[Nome Schema] IN ('Log', 'Expurgo')
-- AND P.[Nome Tabela] IN  ('LogsDetalhes','Logs')

ORDER BY
    P.TotalSpaceKB DESC;
