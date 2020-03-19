
CREATE OR ALTER PROCEDURE HealthCheck.uspGetTableHeaps
AS BEGIN

DECLARE @SchemaExcecao VARCHAR(3) ='dbo';
		
SELECT 
S2.name AS SchemaName,
 O.name AS TableName,
       S.rowcnt
FROM sys.sysindexes AS S
     JOIN
     sys.objects AS O ON S.id = O.object_id
	 JOIN sys.tables AS T ON O.object_id = T.object_id
	 JOIN sys.schemas AS S2 ON O.schema_id = S2.schema_id
WHERE S.indid = 0
      AND O.type = 'U'
	  AND S2.name <> @SchemaExcecao


   END
