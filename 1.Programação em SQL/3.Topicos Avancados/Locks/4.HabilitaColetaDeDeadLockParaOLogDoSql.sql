DBCC TRACEON(1204,1222,-1)



-- ==================================================================
--Observação: Demo DeadLock
-- ==================================================================
ALTER DATABASE Certificacao70762  SET  READ_COMMITTED_SNAPSHOT  OFF

USE Certificacao70762;


SET TRANSACTION ISOLATION LEVEL READ COMMITTED
 

/*Query para uma sessão*/
BEGIN TRAN  t1
UPDATE Examples.LockingA SET LockingA.ColumnText ='Update row 1'
WHERE LockingA.RowId = 1



UPDATE Examples.LockingB SET LockingB.ColumnText ='Update row 2' 
WHERE LockingB.RowId =2



/*Em outra sessão rode a query abaixo*/

BEGIN TRAN  t2
SET TRANSACTION ISOLATION LEVEL READ COMMITTED


UPDATE Examples.LockingB SET LockingB.ColumnText ='Update row 2' 
WHERE LockingB.RowId =2


UPDATE Examples.LockingA SET LockingA.ColumnText ='Update row 1'
WHERE LockingA.RowId = 1

--COMMIT
--ROLLBACK

SELECT  * FROM sys.sysprocesses AS S
WHERE S.open_tran = 1


SELECT * FROM Examples.LockingA AS LA