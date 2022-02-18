--ALTER DATABASE IsoTest SET READ_COMMITTED_SNAPSHOT ON;


USE IsoTest;
GO

CREATE TABLE dbo.marbles
(
    id    INT PRIMARY KEY,
    color CHAR(5)
);
GO

INSERT dbo.marbles VALUES(1, 'Black');

INSERT dbo.marbles VALUES(2, 'White');

--UPDATE dbo.marbles SET color ='Black' WHERE id =1
GO

/* ==================================================================
--Data: 11/5/2020 
--Autor :Wesley Neves
--Observação: Em uma sessão
 
-- ==================================================================
*/
USE IsoTest;
SET TRAN ISOLATION LEVEL READ COMMITTED


DECLARE @id INT;

BEGIN TRAN;

SELECT @id = MIN(id)FROM dbo.marbles WHERE color = 'Black';

UPDATE dbo.marbles SET color = 'White' WHERE id = @id;

--COMMIT TRAN;
SELECT * FROM dbo.marbles AS M

/* ==================================================================
--Data: 11/5/2020 
--Autor :Wesley Neves
--Observação: Em outra sessão
 
-- ==================================================================
*/
USE IsoTest;
GO

DECLARE @id INT;

BEGIN TRAN;

SELECT @id = MIN(id)FROM dbo.marbles WHERE color = 'Black';

UPDATE dbo.marbles SET color = 'Red' WHERE id = @id;

COMMIT TRAN;
GO