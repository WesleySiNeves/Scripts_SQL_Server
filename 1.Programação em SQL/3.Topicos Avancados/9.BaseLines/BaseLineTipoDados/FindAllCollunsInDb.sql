
IF ( OBJECT_ID('TEMPDB..#AllCollunns') IS NOT NULL )
    DROP TABLE #AllCollunns;	

CREATE TABLE #AllCollunns(
    [object_id] INT,
    [SCHEMAName] NVARCHAR(128),
    [TableName] NVARCHAR(128),
    [Coluna] NVARCHAR(128),
    [Tipo] NVARCHAR(128),
    [user_type_id] INT,
    [max_length] SMALLINT
);


WITH Dados AS (
SELECT 
T.object_id,
S.name AS SCHEMAName,
T.name AS TableName,
C.name AS Coluna,
T2.name AS Tipo,
T2.user_type_id,
C.max_length
FROM sys.tables AS T
    JOIN sys.schemas AS S
        ON T.schema_id = S.schema_id
		JOIN sys.columns AS C  ON T.object_id = C.object_id
		JOIN sys.types AS T2 ON c.user_type_id = T2.user_type_id
)
INSERT INTO #AllCollunns
SELECT * FROM Dados






SELECT  R.Tipo,COUNT(*) AS Quantidade FROM #AllCollunns R
GROUP BY R.Tipo
ORDER BY Quantidade DESC