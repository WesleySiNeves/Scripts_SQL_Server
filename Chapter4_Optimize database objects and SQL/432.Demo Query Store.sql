USE master;

DROP DATABASE IF EXISTS ExamBook762Ch4_QueryStore;

CREATE DATABASE ExamBook762Ch4_QueryStore;
GO
USE ExamBook762Ch4_QueryStore;

GO
CREATE SCHEMA Examples;
GO


CREATE TABLE Examples.SimpleTable
(
    Ident INT IDENTITY,
    ID INT,
    Value INT
);

	WITH IDs
	AS (SELECT TOP (9999)
			ROW_NUMBER() OVER (ORDER BY (SELECT 1)) AS n
		FROM master.sys.all_columns ac1
			CROSS JOIN master.sys.all_columns ac2
	   )
	INSERT INTO Examples.SimpleTable
	(
		ID,
		Value
	)
	SELECT 1,
		   n
	FROM IDs;
	GO


INSERT Examples.SimpleTable (ID, Value)
VALUES (2, 100);

ALTER TABLE Examples.SimpleTable
ADD CONSTRAINT [PK_SimpleTable_Ident]
    PRIMARY KEY CLUSTERED (Ident);
CREATE NONCLUSTERED INDEX ix_SimpleTable_ID ON Examples.SimpleTable (ID);
GO

CREATE PROCEDURE Examples.GetValues @PARAMETER1 INT
AS
SELECT ID,
       Value
FROM Examples.SimpleTable
WHERE ID = @PARAMETER1;
GO
	

ALTER DATABASE ExamBook762Ch4_QueryStore SET QUERY_STORE=ON
    (
        INTERVAL_LENGTH_MINUTES = 1
    );

EXEC Examples.GetValues 1;
GO 20

/*########################
# OBS:Agora veja o query store e analise 
apos isso rode a query abaixo
*/



EXEC Examples.GetValues 2;

DBCC DROPCLEANBUFFERS 

EXEC Examples.GetValues 2;

EXEC Examples.GetValues 1;
SELECT p.plan_id,
       p.query_id,
       q.object_id,
       force_failure_count,
       last_force_failure_reason_desc
FROM sys.query_store_plan AS p
    INNER JOIN sys.query_store_query AS q
        ON p.query_id = q.query_id
WHERE is_forced_plan = 1;