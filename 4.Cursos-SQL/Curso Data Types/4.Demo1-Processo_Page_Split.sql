
/* https://docs.google.com/presentation/d/1ri_rNqh6oXATN_IprhjCYlJWrS0x5_Pp/edit#slide=id.g123db721edf_0_160

Slide  19
Total dados em uma pagina 8060 bytes  
Logo 8060 /10    cada linha Oculpa 806 bytes
*/
IF (NOT EXISTS (SELECT * FROM sys.tables AS T WHERE T.name ='QuantidadeRegistosPorPagina'))
BEGIN
    CREATE TABLE QuantidadeRegistosPorPagina
    (
        Campo CHAR(806) NOT NULL PRIMARY KEY
    );
END;




SELECT o.name TableName,
       SUM(p.rows) totalRows,
       SUM(a.data_pages) numDataPages
FROM sys.objects o
    JOIN sys.indexes i
        ON o.object_id = i.object_id
    JOIN sys.partitions p
        ON i.object_id = p.object_id
           AND i.index_id = p.index_id
    JOIN sys.allocation_units a
        ON p.partition_id = a.container_id
WHERE o.is_ms_shipped = 0
      AND o.type = 'U'
      AND o.name = 'QuantidadeRegistosPorPagina'
GROUP BY o.name;


	INSERT INTO dbo.QuantidadeRegistosPorPagina
	(
	    Campo
	)
	VALUES
	('1' ),('2'),('3'),('4'),('5'),('6'),('7'),('8'),('9')


SELECT o.name TableName,
       SUM(p.rows) totalRows,
       SUM(a.data_pages) numDataPages
FROM sys.objects o
    JOIN sys.indexes i
        ON o.object_id = i.object_id
    JOIN sys.partitions p
        ON i.object_id = p.object_id
           AND i.index_id = p.index_id
    JOIN sys.allocation_units a
        ON p.partition_id = a.container_id
WHERE o.is_ms_shipped = 0
      --AND o.type = 'U'
      AND o.name = 'QuantidadeRegistosPorPagina'
GROUP BY o.name;


/*Aqui Pcorre page Split */

INSERT INTO dbo.QuantidadeRegistosPorPagina
	(
	    Campo
	)
	VALUES
	('10' )
	
	
SELECT o.name TableName,
       SUM(p.rows) totalRows,
       SUM(a.data_pages) numDataPages
FROM sys.objects o
    JOIN sys.indexes i
        ON o.object_id = i.object_id
    JOIN sys.partitions p
        ON i.object_id = p.object_id
           AND i.index_id = p.index_id
    JOIN sys.allocation_units a
        ON p.partition_id = a.container_id
WHERE o.is_ms_shipped = 0
      --AND o.type = 'U'
      AND o.name = 'QuantidadeRegistosPorPagina'
GROUP BY o.name;


SELECT S.name as 'Schema',
T.name as 'Table',
I.name as 'Index',
DDIPS.avg_fragmentation_in_percent,
DDIPS.page_count
FROM sys.dm_db_index_physical_stats (DB_ID(), NULL, NULL, NULL, NULL) AS DDIPS
INNER JOIN sys.tables T on T.object_id = DDIPS.object_id
INNER JOIN sys.schemas S on T.schema_id = S.schema_id
INNER JOIN sys.indexes I ON I.object_id = DDIPS.object_id
AND DDIPS.index_id = I.index_id
WHERE DDIPS.database_id = DB_ID()
and I.name is not NULL
AND T.name ='QuantidadeRegistosPorPagina'
AND DDIPS.avg_fragmentation_in_percent > 0
ORDER BY DDIPS.avg_fragmentation_in_percent desc



SELECT * FROM dbo.QuantidadeRegistosPorPagina AS QRPP