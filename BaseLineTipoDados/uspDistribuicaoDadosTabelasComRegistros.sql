WITH Dados
  AS (SELECT T.name,
             I.name AS IndexName,
             S.rows,
             TabelaPossueRegistro = IIF(S.rows > 0, 1, 0)
        FROM sys.tables AS T
        JOIN sys.indexes AS I
          ON T.object_id = I.object_id
         AND I.type      = 1
        JOIN sys.sysindexes AS S
          ON I.object_id = S.id
         AND S.indid     = 1)
SELECT DISTINCT
       TotalTabelas = COUNT(*) OVER (),
       TotalTabelasComRegistros = SUM(R.TabelaPossueRegistro) OVER (),
	   perct = CAST((SUM(R.TabelaPossueRegistro) OVER () / (COUNT(*) OVER () * 1.0) * 100) AS DECIMAL(18,2))
  FROM Dados R;

