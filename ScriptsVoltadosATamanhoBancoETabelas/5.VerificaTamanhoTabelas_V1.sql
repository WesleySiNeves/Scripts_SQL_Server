WITH Dados
  AS (SELECT  
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
          t.name,
          s.name,
          p.rows
     ),
     Projecao
  AS (
     SELECT R.[Nome Tabela],
            R.[Nome Schema],
            R.[Quantidade Registros],
            R.TotalSpaceKB,
            [TotalAlocadoMB] = CONCAT(CAST(CAST((R.TotalSpaceKB / 1024) AS DECIMAL(18, 2)) AS VARCHAR(100)), ' MB'),
            R.UsedSpaceKB,
            [TotalUsadoMB] = CONCAT((R.UsedSpaceKB / 1024), ' MB'),
            R.UnusedSpaceKB,
            [TotaReservadoMB] = CONCAT((R.UnusedSpaceKB / 1024), ' MB')
     FROM Dados R
     )
SELECT P.[Nome Schema],
       P.[Nome Tabela],
       P.[Quantidade Registros],
       P.TotalSpaceKB,
       P.[TotalAlocadoMB],
       P.UsedSpaceKB,
       P.[TotalUsadoMB],
       P.UnusedSpaceKB,
       P.[TotaReservadoMB]
FROM Projecao P
WHERE P.TotalSpaceKB > 0
ORDER BY
    P.TotalSpaceKB DESC;



