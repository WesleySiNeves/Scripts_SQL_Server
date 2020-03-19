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



/*########################
# OBS: Cria segunda tabela
*/
INSERT Examples.SimpleTable
(
    ID,
    Value
)
VALUES
(2, 100);
ALTER TABLE Examples.SimpleTable
ADD CONSTRAINT [PK_SimpleTable_Ident]
    PRIMARY KEY CLUSTERED (Ident);
CREATE NONCLUSTERED INDEX ix_SimpleTable_ID ON Examples.SimpleTable (ID);
GO


/*########################
# OBS: Cria uma procedure
*/
CREATE PROCEDURE Examples.GetValues @PARAMETER1 INT
AS
SELECT ID,
       Value
FROM Examples.SimpleTable
WHERE ID = @PARAMETER1;
GO


/*########################
# OBS: Habilita o query Store
*/
ALTER DATABASE ExamBook762Ch4_QueryStore
SET QUERY_STORE = ON
    (
        INTERVAL_LENGTH_MINUTES = 1
    );


/*########################
# OBS: executa a procedure
*/

	EXEC Examples.GetValues 1;
GO 20


/*########################
# OBS: Abra o Query Store e de uma olhada nas informações
*/


/*########################
# OBS: Agora rode a query abaixo
*/
EXEC Examples.GetValues 2;
GO


/*########################
# OBS: Agora vamos limpar o Buffer e executar novamente
*/
DBCC FREEPROCCACHE();
GO

EXEC Examples.GetValues 2;
GO


EXEC Examples.GetValues 1;
GO