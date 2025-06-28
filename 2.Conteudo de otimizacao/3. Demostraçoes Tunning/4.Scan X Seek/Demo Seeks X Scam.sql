

--ALTER TABLE dbo.Lancamentos ADD PK INT NOT NULL PRIMARY KEY IDENTITY(1,1)

----logical reads 1358
--SET STATISTICS IO ON 
--SELECT * FROM  dbo.Lancamentos AS L

--SET STATISTICS IO OFF


SELECT L.* FROM dbo.Lancamentos AS L
WHERE l.PK <=1

SELECT L.* FROM dbo.Lancamentos AS L
WHERE l.PK <=10

SELECT L.* FROM dbo.Lancamentos AS L
WHERE l.PK <=100

SELECT L.* FROM dbo.Lancamentos AS L
WHERE l.PK <=200

SELECT L.* FROM dbo.Lancamentos AS L
WHERE l.PK <=300

SELECT L.* FROM dbo.Lancamentos AS L
WHERE l.PK <=500

SET STATISTICS IO ON 
SELECT L.* FROM dbo.Lancamentos AS L
--JOIN dbo.Lancamentos AS L2 ON L.PK = L2.PK
WHERE l.PK <=100000

SET STATISTICS IO OFF

SELECT OBJECT_NAME(DDIUS.object_id), * FROM sys.dm_db_index_usage_stats AS DDIUS
JOIN sys.tables AS T ON DDIUS.object_id = T.object_id
ORDER BY DDIUS.user_seeks DESC



--Merge Joins
SELECT L.* FROM dbo.Lancamentos AS L
JOIN dbo.Lancamentos AS L2 ON L.PK = L2.PK
go
--HASH Joins
SELECT L.* FROM dbo.Lancamentos AS L
INNER HASH JOIN dbo.Lancamentos AS L2 ON L.PK = L2.PK