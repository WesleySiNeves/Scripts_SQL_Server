

-- Query para retornar tamanho de cada tabela com Schema, Nome e Tamanho em MB/GB
-- Compatível com Azure SQL Database
WITH Dados AS (
SELECT 
    s.name AS [Schema],
    t.name AS [Tabela],
    p.rows AS [Linhas],
    CAST(ROUND(((SUM(a.total_pages) * 8) / 1024.00), 2) AS NUMERIC(36, 2)) AS [Tamanho_MB],
    CAST(ROUND(((SUM(a.total_pages) * 8) / 1024.00 / 1024.00), 2) AS NUMERIC(36, 2)) AS [Tamanho_GB],
    CAST(ROUND(((SUM(a.used_pages) * 8) / 1024.00), 2) AS NUMERIC(36, 2)) AS [Usado_MB],
    CAST(ROUND(((SUM(a.used_pages) * 8) / 1024.00 / 1024.00), 2) AS NUMERIC(36, 2)) AS [Usado_GB],
    CAST(ROUND(((SUM(a.total_pages) - SUM(a.used_pages)) * 8) / 1024.00, 2) AS NUMERIC(36, 2)) AS [Livre_MB]
FROM 
    sys.tables t
INNER JOIN 
    sys.indexes i ON t.OBJECT_ID = i.object_id
INNER JOIN 
    sys.partitions p ON i.object_id = p.OBJECT_ID AND i.index_id = p.index_id
INNER JOIN 
    sys.allocation_units a ON p.partition_id = a.container_id
LEFT OUTER JOIN 
    sys.schemas s ON t.schema_id = s.schema_id
WHERE 
    t.NAME NOT LIKE 'dt%' 
    AND t.is_ms_shipped = 0
    AND i.OBJECT_ID > 255 
GROUP BY 
    t.Name, s.Name, p.Rows
), Agregate AS 
(
SELECT R.[Schema],
       R.Tabela,
      SUM(R.Linhas) AS Linhas,
       SUM(R.Tamanho_MB)AS Tamanho_MB,
       SUM(R.Tamanho_GB)AS Tamanho_GB,
       SUM(R.Usado_MB)AS Usado_MB,
       SUM(R.Usado_GB)AS Usado_GB,
       SUM(R.Livre_MB)AS Livre_MB FROM Dados R
	   GROUP BY R.[Schema],
                R.Tabela
)
SELECT R.[Schema],
       R.Tabela,
       R.Linhas,
       R.Tamanho_MB,
	   [Total Geral GB] = SUM(R.Tamanho_MB) OVER() / 1024.0, 

       R.Tamanho_GB,
       R.Usado_MB,
       R.Usado_GB,
       R.Livre_MB
	    FROM Agregate R
		WHERE R.Tabela ='LogsJson'
ORDER BY 
    [Tamanho_MB] DESC;

-- Versão Resumida (Top 20 maiores tabelas)
/*
SELECT TOP 20
    s.name AS [Schema],
    t.name AS [Tabela],
    p.rows AS [Linhas],
    CAST(ROUND(((SUM(a.total_pages) * 8) / 1024.00), 2) AS NUMERIC(36, 2)) AS [Tamanho_MB],
    CAST(ROUND(((SUM(a.total_pages) * 8) / 1024.00 / 1024.00), 2) AS NUMERIC(36, 2)) AS [Tamanho_GB]
FROM 
    sys.tables t
INNER JOIN 
    sys.indexes i ON t.OBJECT_ID = i.object_id
INNER JOIN 
    sys.partitions p ON i.object_id = p.OBJECT_ID AND i.index_id = p.index_id
INNER JOIN 
    sys.allocation_units a ON p.partition_id = a.container_id
LEFT OUTER JOIN 
    sys.schemas s ON t.schema_id = s.schema_id
WHERE 
    t.is_ms_shipped = 0
GROUP BY 
    t.Name, s.Name, p.Rows
ORDER BY 
    [Tamanho_MB] DESC;
*/

-- Versão com Totais por Schema
/*
SELECT 
    s.name AS [Schema],
    COUNT(*) AS [Qtd_Tabelas],
    SUM(p.rows) AS [Total_Linhas],
    CAST(ROUND(((SUM(a.total_pages) * 8) / 1024.00), 2) AS NUMERIC(36, 2)) AS [Total_MB],
    CAST(ROUND(((SUM(a.total_pages) * 8) / 1024.00 / 1024.00), 2) AS NUMERIC(36, 2)) AS [Total_GB]
FROM 
    sys.tables t
INNER JOIN 
    sys.indexes i ON t.OBJECT_ID = i.object_id
INNER JOIN 
    sys.partitions p ON i.object_id = p.OBJECT_ID AND i.index_id = p.index_id
INNER JOIN 
    sys.allocation_units a ON p.partition_id = a.container_id
LEFT OUTER JOIN 
    sys.schemas s ON t.schema_id = s.schema_id
WHERE 
    t.is_ms_shipped = 0
GROUP BY 
    s.name
ORDER BY 
    [Total_MB] DESC;
*/

--
--Schema	Tabela	Linhas	Tamanho_MB	Tamanho_GB	Usado_MB	Usado_GB	Livre_MB
--Log	LogsJson	2231427	604.20	0.59	603.05	0.59	1.16

--Schema	Tabela	Linhas	Tamanho_MB	Tamanho_GB	Usado_MB	Usado_GB	Livre_MB
--Log	LogsJson	2231501	199.70	0.20	199.46	0.19	0.23


