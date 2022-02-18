--Skill 3.1: Implement transactions

----Identify DML statement results based on transaction behavior

------Listing 3-1 Create a test environment for exploring transaction behavior
CREATE DATABASE ExamBook762Ch3;
GO
USE ExamBook762Ch3;
GO
CREATE SCHEMA Examples;

GO

CREATE TABLE Examples.TestParent
(
    ParentId  int NOT NULL
        CONSTRAINT PKTestParent PRIMARY KEY,
    ParentName  varchar(100) NULL
);

CREATE TABLE Examples.TestChild
(
    ChildId  int NOT NULL
        CONSTRAINT PKTestChild PRIMARY KEY,
    ParentId int NOT NULL,  
    ChildName  varchar(100) NULL
);
ALTER TABLE Examples.TestChild
ADD CONSTRAINT FKTestChild_Ref_TestParent
    FOREIGN KEY (ParentId)
    REFERENCES Examples.TestParent (ParentId);
INSERT INTO Examples.TestParent (ParentId,
                                 ParentName)
VALUES (1, 'Dean'),
(2, 'Michael'),
(3, 'Robert');
INSERT INTO Examples.TestChild (ChildId,
                                ParentId,
                                ChildName)
VALUES (1, 1, 'Daniel'),
(2, 1, 'Alex'),
(3, 2, 'Matthew'),
(4, 3, 'Jason');

------Executing a single statement as a transaction
UPDATE Examples.TestParent
SET ParentName = 'Bob'
WHERE ParentName = 'Robert';

------Confirming a committed transaction
SELECT ParentId, ParentName 
FROM Examples.TestParent;

------Testing transaction atomicity
BEGIN TRANSACTION;
    UPDATE Examples.TestParent
    SET ParentName = 'Mike'
    WHERE ParentName = 'Michael';
    UPDATE Examples.TestChild
    SET ChildName = 'Matt'
    WHERE ChildName = 'Matthew';
COMMIT TRANSACTION;

------Confirming atomicity of a transaction
SELECT TestParent.ParentId, ParentName, ChildId, ChildName
FROM Examples.TestParent 
    FULL OUTER JOIN Examples.TestChild ON TestParent.ParentId = TestChild.ParentId;

------Testing atomicity with foreign key constraint violation
BEGIN TRANSACTION;
    INSERT INTO Examples.TestParent(ParentId, ParentName)
    VALUES (4, 'Linda');
    DELETE Examples.TestParent
    WHERE ParentName = 'Bob';
COMMIT TRANSACTION;


SELECT * FROM Examples.TestParent AS TP


/*Aqui garantimos a Atomicidade do banco*/
------Guaranteeing atomicity with XACT_ABORT ON
SET XACT_ABORT ON;
BEGIN TRANSACTION;
    INSERT INTO Examples.TestParent(ParentId, ParentName)
    VALUES (5, 'Isabelle');
    DELETE Examples.TestParent
    WHERE ParentName = 'Bob';
COMMIT TRANSACTION;


SELECT * FROM Examples.TestParent AS TP

------Testing atomicity with syntax error
SET XACT_ABORT OFF;
BEGIN TRANSACTION;
    INSERT INTO Examples.TestParent(ParentId, ParentName)
    VALUES (5, 'Isabelle');
    DELETE Examples.TestParent
    WHERE ParentName = 'Bob';
COMMIT TRANSACTION;

SELECT * FROM Examples.TestParent AS TP

------Rolling back a transaction in a CATCH block
BEGIN TRY
    BEGIN TRANSACTION;
        INSERT INTO Examples.TestParent(ParentId, ParentName)
        VALUES (5, 'Isabelle');
        DELETE Examples.TestParent
        WHERE ParentName = 'Bob';
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
END CATCH

------Isolation testing - Session 1
BEGIN TRANSACTION;
    INSERT INTO Examples.TestParent(ParentId, ParentName)
    VALUES (5, 'Isabelle');

------Isolation testing - Session 2
SELECT ParentId, ParentName 
FROM Examples.TestParent;

------Isolation testing - Session 1
COMMIT TRANSACTION;



----Recognize differences between and identify usage of explicit and implicit transactions

------Enable implicit transaction mode
SET IMPLICIT_TRANSACTIONS ON;

------Test status of implicit transaction
INSERT INTO Examples.TestParent(ParentId, ParentName)
VALUES (6, 'Lukas');
SELECT @@TRANCOUNT;

------End an implicit transaction and check results
COMMIT TRANSACTION;
SELECT @@TRANCOUNT;
SELECT ParentId, ParentName 
FROM Examples.TestParent;

------Disable implicit transaction mode
SET IMPLICIT_TRANSACTIONS OFF;

------Test an explicit transaction with error handling
BEGIN TRANSACTION;
    INSERT INTO Examples.TestParent(ParentId, ParentName)
    VALUES (7, 'Mary');
    DELETE Examples.TestParent
    WHERE ParentName = 'Bob';
IF @@ERROR != 0
    BEGIN
        ROLLBACK TRANSACTION;
    RETURN
END
COMMIT TRANSACTION;

GO



------Listing 3-2 Create and execute a stored procedure to test an explicit transaction 
CREATE PROCEDURE Examples.DeleteParent @ParentId INT
AS
BEGIN TRANSACTION;
DELETE Examples.TestParent
 WHERE TestParent.ParentId = @ParentId;
IF @@ERROR != 0
BEGIN
    ROLLBACK TRANSACTION;
    RETURN;
END
COMMIT TRANSACTION;
GO
BEGIN TRANSACTION;
INSERT INTO Examples.TestParent (ParentId,
                                 ParentName)
VALUES (7, 'Mary');
EXEC Examples.DeleteParent @ParentId = 3;
IF @@ERROR != 0
BEGIN
    ROLLBACK TRANSACTION;
    RETURN
END
COMMIT TRANSACTION;
GO

------Listing 3-3 Create a stored procedure that avoids a nested transaction       
CREATE PROCEDURE Examples.DeleteParentNoNest 
    @ParentId INT
AS
    DECLARE @CurrentTranCount INT;
    SELECT @CurrentTranCount = @@TRANCOUNT;
    IF (@CurrentTranCount = 0)
        BEGIN TRANSACTION DeleteTran;
    ELSE
        SAVE TRANSACTION DeleteTran; 
    DELETE Examples.TestParent
    WHERE ParentId = @ParentId;
    IF @@ERROR != 0
        BEGIN
            ROLLBACK TRANSACTION DeleteTran;
            RETURN;
        END
    IF (@CurrentTranCount = 0)
        COMMIT TRANSACTION;
GO
BEGIN TRANSACTION;
    INSERT INTO Examples.TestParent(ParentId, ParentName)
    VALUES (7, 'Mary');
    EXEC Examples.DeleteParentNoNest @ParentId=3;
IF @@ERROR != 0
    BEGIN
        ROLLBACK TRANSACTION;
    RETURN
END
COMMIT TRANSACTION;
GO

------Listing 3-4 Create a transaction with multiple savepoints       
BEGIN TRANSACTION;
    INSERT INTO Examples.TestParent(ParentId, ParentName)
    VALUES (8, 'Ed');
    SAVE TRANSACTION StartTran;
    
    SELECT 'StartTran' AS Status, ParentId, ParentName 
    FROM Examples.TestParent;

    DELETE Examples.TestParent
        WHERE ParentId = 7;
    SAVE TRANSACTION DeleteTran;

    SELECT 'Delete 1' AS Status, ParentId, ParentName 
    FROM Examples.TestParent;
    DELETE Examples.TestParent
        WHERE ParentId = 6;
    SELECT 'Delete 2' AS Status, ParentId, ParentName 
    FROM Examples.TestParent;

    ROLLBACK TRANSACTION DeleteTran;
    SELECT 'RollbackDelete2' AS Status, ParentId, ParentName 
    FROM Examples.TestParent;

    ROLLBACK TRANSACTION StartTran;
    SELECT @@TRANCOUNT AS 'TranCount';
    SELECT 'RollbackStart' AS Status, ParentId, ParentName 
    FROM Examples.TestParent;
COMMIT TRANSACTION;
GO

--Skill 3.2: Manage isolation levels

----Define results of concurrent queries based on isolation level

------Listing 3-5 Create a test environment for testing isolation levels
CREATE TABLE Examples.IsolationLevels
(
    RowId  int NOT NULL
        CONSTRAINT PKRowId PRIMARY KEY,
    ColumnText  varchar(100) NOT NULL
);
INSERT INTO Examples.IsolationLevels(RowId, ColumnText)
VALUES (1, 'Row 1'), (2, 'Row 2'), (3, 'Row 3'), (4, 'Row 4');

SELECT * FROM Examples.IsolationLevels AS IL

------Test READ COMITTED isolation level - Session 1
BEGIN TRANSACTION;
    UPDATE Examples.IsolationLevels
        SET IsolationLevels.ColumnText = 'Row 1 Updated'
        WHERE IsolationLevels.RowId = 1;

------Test READ COMITTED isolation level - Session 2
SELECT IsolationLevels.RowId, IsolationLevels.ColumnText
FROM Examples.IsolationLevels;

------Test READ COMITTED isolation level - Session 1
ROLLBACK TRANSACTION;

------Test READ UNCOMITTED isolation level - Session 1
BEGIN TRANSACTION;
    UPDATE Examples.IsolationLevels
        SET IsolationLevels.ColumnText = 'Row 1 Updated'
        WHERE IsolationLevels.RowId = 1;

------Test READ UNCOMITTED isolation level - Session 2
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
SELECT IsolationLevels.RowId, IsolationLevels.ColumnText
FROM Examples.IsolationLevels;

------Test READ UNCOMITTED isolation level - Session 1
ROLLBACK TRANSACTION;

------Test READ UNCOMITTED isolation level - Session 2
SELECT IsolationLevels.RowId, IsolationLevels.ColumnText
FROM Examples.IsolationLevels;

------Test READ UNCOMITTED using NOLOCK table hint
SELECT IsolationLevels.RowId, IsolationLevels.ColumnText
FROM Examples.IsolationLevels
WITH (NOLOCK);

------Test REPEATABLE READ isolation level - Session 1
SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;
BEGIN TRANSACTION;
    SELECT IsolationLevels.RowId, IsolationLevels.ColumnText
    FROM Examples.IsolationLevels;
    WAITFOR DELAY '00:00:10';
    SELECT IsolationLevels.RowId, IsolationLevels.ColumnText
    FROM Examples.IsolationLevels;
ROLLBACK TRANSACTION;

------Test REPEATABLE READ isolation level - Session 2
UPDATE Examples.IsolationLevels
    SET IsolationLevels.ColumnText = 'Row 1 Updated'
    WHERE IsolationLevels.RowId = 1;

------Create a phantom read - Session 1
/*Veja que existe  que não existe impedimento de inserção*/
SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;
BEGIN TRANSACTION;
    SELECT IsolationLevels.RowId, IsolationLevels.ColumnText
    FROM Examples.IsolationLevels;
    WAITFOR DELAY '00:00:10';
    SELECT IsolationLevels.RowId, IsolationLevels.ColumnText
    FROM Examples.IsolationLevels;
ROLLBACK TRANSACTION;

------Create a phantom read - Session 2
INSERT INTO Examples.IsolationLevels(RowId, ColumnText)
VALUES (5, 'Row 5');

------Test the SERIALIZABLE isolation level - Session 1
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
BEGIN TRANSACTION;
    SELECT IsolationLevels.RowId, IsolationLevels.ColumnText
    FROM Examples.IsolationLevels;
    WAITFOR DELAY '00:00:10';
    SELECT IsolationLevels.RowId, IsolationLevels.ColumnText
    FROM Examples.IsolationLevels;
ROLLBACK TRANSACTION;

------Test the SERIALIZABLE isolation level - Session 2
INSERT INTO Examples.IsolationLevels(RowId, ColumnText)
VALUES (6, 'Row 6');

------Enable SNAPSHOT isolation in the database
ALTER DATABASE ExamBook762Ch3 SET ALLOW_SNAPSHOT_ISOLATION ON;

------Test the SNAPSHOT isolation level  - Session 1
SET TRANSACTION ISOLATION LEVEL SNAPSHOT;
BEGIN TRANSACTION;
    SELECT IsolationLevels.RowId, IsolationLevels.ColumnText
    FROM Examples.IsolationLevels;
    WAITFOR DELAY '00:00:10';
    SELECT IsolationLevels.RowId, IsolationLevels.ColumnText
    FROM Examples.IsolationLevels;
ROLLBACK TRANSACTION;

------Test the SNAPSHOT isolation level  - Session 2
INSERT INTO Examples.IsolationLevels(RowId, ColumnText)
VALUES (7, 'Row 7');

------Listing 3-6 Create a separate for testing isolation levels
CREATE DATABASE ExamBook762Ch3_IsolationTest;
GO
USE ExamBook762Ch3_IsolationTest;
GO 
CREATE SCHEMA Examples;
GO

USE ExamBook762Ch3_IsolationTest

CREATE TABLE Examples.IsolationLevelsTest
(RowId INT NOT NULL
    CONSTRAINT PKRowId PRIMARY KEY,
    ColumnText  varchar(100) NOT NULL
);
INSERT INTO Examples.IsolationLevelsTest(RowId, ColumnText)
VALUES (1, 'Row 1'), (2, 'Row 2'), (3, 'Row 3'), (4, 'Row 4');

------Test the SNAPSHOT isolation level across databases
SET TRANSACTION ISOLATION LEVEL SNAPSHOT;
BEGIN TRANSACTION;
    SELECT t1.RowId, t2.ColumnText
    FROM Examples.IsolationLevels AS t1
    INNER JOIN ExamBook762Ch3_IsolationTest.Examples.IsolationLevelsTest AS t2
    ON t1.RowId = t2.RowId;
END TRANSACTION;

------Test the SNAPSHOT isolation level across databases with READCOMMITTED hint
SET TRANSACTION ISOLATION LEVEL SNAPSHOT;
BEGIN TRANSACTION;
    SELECT t1.RowId, t2.ColumnText
    FROM Examples.IsolationLevels AS t1
    INNER JOIN ExamBook762Ch3_IsolationTest.Examples.IsolationLevelsTest AS t2
    WITH (READCOMMITTED)
    ON t1.RowId = t2.RowId;
END TRANSACTION;

------Add an index to a table for testing SNAPSHOT isolation 
CREATE INDEX Ix_RowId ON Examples.IsolationLevels (RowId);

------Test the SNAPSHOT isolation level for index modification - Session 1
SET TRANSACTION ISOLATION LEVEL SNAPSHOT;
BEGIN TRANSACTION;
    SELECT IsolationLevels.RowId, IsolationLevels.ColumnText
    FROM Examples.IsolationLevels;
    WAITFOR DELAY '00:00:15';
    SELECT IsolationLevels.RowId, IsolationLevels.ColumnText
    FROM Examples.IsolationLevels;
ROLLBACK TRANSACTION;

------Test the SNAPSHOT isolation level for index modification - Session 2
ALTER INDEX Ix_RowId
    ON Examples.IsolationLevels REBUILD;

------Disable SNAPSHOT isolation for a database
ALTER DATABASE ExamBook762Ch3
SET ALLOW_SNAPSHOT_ISOLATION OFF;

------Enable READ_COMMITTED_SNAPSHOT isolation for a database
ALTER DATABASE ExamBook762Ch3
SET READ_COMMITTED_SNAPSHOT ON;

------Test READ_COMMITTED_SNAPSHOT isolation level - Session 1
BEGIN TRANSACTION;
    SELECT IsolationLevels.RowId, IsolationLevels.ColumnText
    FROM Examples.IsolationLevels;
    WAITFOR DELAY '00:00:15';
    SELECT IsolationLevels.RowId, IsolationLevels.ColumnText
    FROM Examples.IsolationLevels;
ROLLBACK TRANSACTION;

------Test READ_COMMITTED_SNAPSHOT isolation level - Session 2
INSERT INTO Examples.IsolationLevels(RowId, ColumnText)
VALUES (8, 'Row 8');

------Disable READ_COMMITTED_SNAPSHOT isolation for a database
ALTER DATABASE Examples
SET READ_COMMITTED_SNAPSHOT OFF;


--Skill 3.3: Optimize concurrency and locking behavior 

----Troubleshoot locking issues

------Listing 3-7 Create a test environment for testing locking behavior
CREATE TABLE Examples.LockingA
(
    RowId  int NOT NULL
        CONSTRAINT PKLockingARowId PRIMARY KEY,
    ColumnText  varchar(100) NOT NULL
);
INSERT INTO Examples.LockingA(RowId, ColumnText)
VALUES (1, 'Row 1'), (2, 'Row 2'), (3, 'Row 3'), (4, 'Row 4');
CREATE TABLE Examples.LockingB
(
    RowId  int NOT NULL
        CONSTRAINT PKLockingBRowId PRIMARY KEY,
    ColumnText  varchar(100) NOT NULL
);
INSERT INTO Examples.LockingB(RowId, ColumnText)
VALUES (1, 'Row 1'), (2, 'Row 2'), (3, 'Row 3'), (4, 'Row 4');

------Test lock management - Session 1
BEGIN TRANSACTION;  
    SELECT LockingA.RowId, LockingA.ColumnText
    FROM Examples.LockingA
    WITH (HOLDLOCK, ROWLOCK);  

------Test lock management - Session 2
BEGIN TRANSACTION;
    UPDATE Examples.LockingA 
        SET LockingA.ColumnText = 'Row 2 Updated'
        WHERE LockingA.RowId = 2;  

------Use sys.dm_tran_locks to view existing locks
SELECT
    dm_tran_locks.request_session_id as s_id, 
	dm_tran_locks.resource_type, 
	dm_tran_locks.resource_associated_entity_id,
    dm_tran_locks.request_status, 
	dm_tran_locks.request_mode
FROM sys.dm_tran_locks
WHERE dm_tran_locks.resource_database_id = db_id('ExamBook762Ch3');

------Use sys.partitions to find the locked table
------UPDATE the hobt_id to match a resource_associated_entity_id from previous query
SELECT 
    object_name(partitions.object_id) as Resource,
    partitions.object_id,
    partitions.hobt_id
FROM sys.partitions
WHERE partitions.hobt_id=72057594041729024;

------Listing 3-8 Use system DMS sys.dm_tran_locks and sys.dm_os_waiting_tasks 
------to display blocked sessions
SELECT
    t1.resource_type AS res_typ, 
    t1.resource_database_id AS res_dbid,
    t1.resource_associated_entity_id AS res_entid, 
    t1.request_mode AS mode,
    t1.request_session_id AS s_id, 
    t2.blocking_session_id AS blocking_s_id
FROM sys.dm_tran_locks as t1 
INNER JOIN sys.dm_os_waiting_tasks as t2
    ON t1.lock_owner_address = t2.resource_address;  

------Release locks - Session 1
ROLLBACK TRANSACTION;

------Check locks in sys.dm_os_wait_stats
SELECT
    dm_os_wait_stats.wait_type as wait,
    dm_os_wait_stats.waiting_tasks_count as wt_cnt,
    dm_os_wait_stats.wait_time_ms as wt_ms,
    dm_os_wait_stats.max_wait_time_ms as max_wt_ms,
    dm_os_wait_stats.signal_wait_time_ms as signal_ms
FROM sys.dm_os_wait_stats
WHERE dm_os_wait_stats.wait_type LIKE 'LCK%'
ORDER BY dm_os_wait_stats.wait_time_ms DESC;

-----Check lock escalation behavior
SELECT
    dm_os_wait_stats.wait_type as wait,
    dm_os_wait_stats.wait_time_ms as wt_ms,
    CONVERT(decimal(9,2), 100.0 * dm_os_wait_stats.wait_time_ms /
	    SUM(dm_os_wait_stats.wait_time_ms) OVER ()) as wait_pct
FROM sys.dm_os_wait_stats
WHERE dm_os_wait_stats.wait_type LIKE 'LCK%'
ORDER BY dm_os_wait_stats.wait_time_ms DESC;

------Create a deadlock - Session 1
BEGIN TRANSACTION;
    UPDATE Examples.LockingA
        SET LockingA.ColumnText = 'Row 1 Updated'
        WHERE LockingA.RowId = 1;
    WAITFOR DELAY '00:00:05';
    UPDATE Examples.LockingB
    SET LockingB.ColumnText = 'Row 1 Updated Again'
    WHERE LockingB.RowId = 1; 

------Create a deadlock - Session 2
BEGIN TRANSACTION;
    UPDATE Examples.LockingB
        SET LockingB.ColumnText = 'Row 1 Updated'
        WHERE LockingB.RowId = 1;
    WAITFOR DELAY '00:00:05';
    UPDATE Examples.LockingA
    SET LockingA.ColumnText = 'Row 1 Updated Again'
    WHERE LockingA.RowId = 1; 

------Capture and analyze deadlock graphs in SQL Server Profiler - Session 1	
BEGIN TRANSACTION;
    UPDATE Examples.LockingA
        SET LockingA.ColumnText = 'Row 2 Updated'
        WHERE LockingA.RowId = 2;
    WAITFOR DELAY '00:00:05';
    UPDATE Examples.LockingB
    SET LockingB.ColumnText = 'Row 2 Updated Again'
    WHERE LockingB.RowId = 2; 

------Capture and analyze deadlock graphs in SQL Server Profiler - Session 2
BEGIN TRANSACTION;
    UPDATE Examples.LockingB
        SET LockingB.ColumnText = 'Row 2 Updated'
        WHERE LockingB.RowId = 2;
    WAITFOR DELAY '00:00:05';
    UPDATE Examples.LockingA
    SET LockingA.ColumnText = 'Row 2 Updated Again'
    WHERE LockingA.RowId = 2; 


----Identify ways to remediate deadlocks

------Listing 3-9 Add retry logic to avoid deadlock
DECLARE @Tries tinyint
SET @Tries = 1
WHILE @Tries <= 3
BEGIN
    BEGIN TRANSACTION
    BEGIN TRY
        UPDATE Examples.LockingB
            SET LockingB.ColumnText = 'Row 3 Updated'
            WHERE LockingB.RowId = 3;
        WAITFOR DELAY '00:00:05';
        UPDATE Examples.LockingA
        SET LockingA.ColumnText = 'Row 3 Updated Again'
            WHERE LockingA.RowId = 3;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        SELECT ERROR_NUMBER() AS ErrorNumber;
        ROLLBACK TRANSACTION;
        SET @Tries = @Tries + 1;
        CONTINUE;
    END CATCH
END



--Skill 3.4: Implement memory-optimized tables and native stored procedures

----Optimize performance of in-memory tables

------Listing 3-10 Enable in-memory OLTP in a new database
CREATE DATABASE ExamBook762Ch3_IMOLTP
ON PRIMARY (
    NAME = ExamBook762Ch3_IMOLTP_data, 
    FILENAME = 'c:\data\ExamBook762Ch3_IMOLTP.mdf', size=500MB
), 
FILEGROUP ExamBook762Ch3_IMOLTP_FG CONTAINS MEMORY_OPTIMIZED_DATA ( 
    NAME = ExamBook762Ch3_IMOLTP_FG_Container, 
    FILENAME = 'c:\data\ExamBook762Ch3_IMOLTP_FG_Container'
) 
LOG ON (
    NAME = ExamBook762Ch3_IMOLTP_log, 
    FILENAME = 'C:\data\ExamBook762Ch3_IMOLTP_log.ldf', size=500MB
); 
GO

------Listing 3-11 Create a new schema and add tables to the memory-optimized database
USE ExamBook762Ch3_IMOLTP;
GO 
CREATE SCHEMA Examples;
GO
CREATE TABLE Examples.Order_Disk (
    OrderId INT NOT NULL PRIMARY KEY NONCLUSTERED,
    OrderDate DATETIME NOT NULL,
    CustomerCode NVARCHAR(5) NOT NULL
);
GO  
CREATE TABLE Examples.Order_IM (
    OrderID INT NOT NULL PRIMARY KEY NONCLUSTERED,
    OrderDate DATETIME NOT NULL,
    CustomerCode NVARCHAR(5) NOT NULL
)
WITH (MEMORY_OPTIMIZED = ON);
GO  

------Listing 3-12 Create stored procedures to test execution performance
USE ExamBook762Ch3_IMOLTP;
GO
-- Create natively compiled stored procedure
CREATE PROCEDURE Examples.OrderInsert_NC 
    @OrderID INT, 
    @CustomerCode NVARCHAR(10) 
WITH NATIVE_COMPILATION, SCHEMABINDING  
AS   
BEGIN ATOMIC 
WITH (TRANSACTION ISOLATION LEVEL = SNAPSHOT, LANGUAGE = N'English')  
    DECLARE @OrderDate DATETIME = getdate();  
    INSERT INTO Examples.Order_IM (OrderId, OrderDate, CustomerCode) 
    VALUES (@OrderID, @OrderDate, @CustomerCode);  
END;  
GO
-- Create interpreted stored procedure
CREATE PROCEDURE Examples.OrderInsert_Interpreted 
    @OrderID INT, 
    @CustomerCode NVARCHAR(10),
    @TargetTable NVARCHAR(20)
AS   
    DECLARE @OrderDate DATETIME = getdate();  
    DECLARE @SQLQuery NVARCHAR(MAX);
    SET @SQLQuery = 'INSERT INTO ' + 
        @TargetTable + 
        ' (OrderId, OrderDate, CustomerCode) VALUES (' +
	CAST(@OrderID AS NVARCHAR(6)) +
        ',''' +  CONVERT(NVARCHAR(20), @OrderDate, 101)+ 
        ''',''' +  @CustomerCode + 
        ''')';  
    EXEC (@SQLQuery);
GO

------Listing 3-13 Execute each stored procedure to compare performance
SET STATISTICS TIME OFF;  
SET NOCOUNT ON;     

DECLARE @starttime DATETIME = sysdatetime();  
DECLARE @timems INT;  
DECLARE @i INT = 1;  
DECLARE @rowcount INT = 100000;  
DECLARE @CustomerCode NVARCHAR(10);

-- Disk-based table and interpreted stored procedure  
BEGIN TRAN;  
    WHILE @i <= @rowcount
    BEGIN;
        SET @CustomerCode = 'cust' + CAST(@i as NVARCHAR(6));
        EXEC Examples.OrderInsert_Interpreted @i, @CustomerCode, 'Examples.Order_Disk';
        SET @i += 1;  
    END;
COMMIT;

SET @timems = datediff(ms, @starttime, sysdatetime());  
SELECT 'Disk-based table and interpreted stored procedure: ' AS [Description],
    CAST(@timems AS NVARCHAR(10)) + ' ms' AS Duration;  
-- Memory-based table and interpreted stored procedure
SET @i = 1;  
SET @starttime = sysdatetime();

BEGIN TRAN;
    WHILE @i <= @rowcount
    BEGIN;
        SET @CustomerCode = 'cust' + CAST(@i AS NVARCHAR(6));
        EXEC Examples.OrderInsert_Interpreted @i, @CustomerCode, 'Examples.Order_IM';
        SET @i += 1;
    END;  
COMMIT; 
SET @timems = datediff(ms, @starttime, sysdatetime());  
SELECT 'Memory-optimized table and interpreted stored procedure: ' AS [Description],       
    CAST(@timems AS NVARCHAR(10)) + ' ms' AS Duration;  

-- Reset memory-optimized table
DELETE FROM Examples.Order_IM;  
SET @i = 1;
SET @starttime = sysdatetime();  

BEGIN TRAN;
    WHILE @i <= @rowcount  
    BEGIN; 
        SET @CustomerCode = 'cust' + CAST(@i AS NVARCHAR(6));
        EXEC Examples.OrderInsert_NC @i, @CustomerCode;  
        SET @i += 1;  
    END;  
COMMIT; 

SET @timems = datediff(ms, @starttime, sysdatetime());
SELECT 'Memory-optimized table and natively compiled stored procedure:' 
    AS [Description],
    CAST(@timems AS NVARCHAR(10)) + ' ms' AS Duration;
GO

----Indexing

------ Create memory-optimized table with hash index
CREATE TABLE Examples.Order_IM_Hash (
    OrderID INT NOT NULL PRIMARY KEY 
        NONCLUSTERED HASH WITH (BUCKET_COUNT = 1000000),
    OrderDate DATETIME NOT NULL, 
    CustomerCode NVARCHAR(5) NOT NULL
        INDEX ix_CustomerCode HASH WITH (BUCKET_COUNT = 1000000)
)
WITH (MEMORY_OPTIMIZED = ON);

------ Create memory-optimized table with columnstore index
CREATE TABLE Examples.Order_IM_CCI (
    OrderID INT NOT NULL PRIMARY KEY NONCLUSTERED,
    OrderDate DATETIME NOT NULL, 
    CustomerCode NVARCHAR(5) NOT NULL,
    INDEX ix_CustomerCode_cci CLUSTERED COLUMNSTORE)
WITH (MEMORY_OPTIMIZED = ON);

------ Create memory-optimized table with nonclustered B-tree index
CREATE TABLE Examples.Order_IM_NC (
    OrderID INT NOT NULL PRIMARY KEY NONCLUSTERED,
    OrderDate DATETIME NOT NULL, 
    CustomerCode NVARCHAR(5) NOT NULL INDEX ix_CustomerCode NONCLUSTERED
)
WITH (MEMORY_OPTIMIZED = ON);



------Listing 3-14 Use the ALTER TABLE statement to add, modify, or drop an index
-- Add a column and an index
USE ExamBook762Ch3_IMOLTP;
GO
ALTER TABLE Examples.Order_IM
    ADD Quantity INT NULL, 
	INDEX ix_OrderDate(OrderDate); 
-- Alter an index by changing the bucket count 
ALTER TABLE Examples.Order_IM_Hash
    ALTER INDEX ix_UserId 
        REBUILD WITH ( BUCKET_COUNT = 2000000); 
-- Drop an index 
ALTER TABLE Examples.Order_IM
DROP INDEX ix_OrderDate;

------Create durable memory-optimized table
CREATE TABLE Examples.Order_IM_Durable (
    OrderID INT NOT NULL PRIMARY KEY NONCLUSTERED,
    OrderDate DATETIME NOT NULL,
    CustomerCode NVARCHAR(5) NOT NULL
)
WITH (MEMORY_OPTIMIZED = ON, DURABILITY=SCHEMA_AND_DATA);
GO  

------Create non-durable memory-optimized table
CREATE TABLE Examples.Order_IM_Nondurable (
    OrderID INT NOT NULL PRIMARY KEY NONCLUSTERED,
    OrderDate DATETIME NOT NULL,
    CustomerCode NVARCHAR(5) NOT NULL
)
WITH (MEMORY_OPTIMIZED = ON, DURABILITY=SCHEMA_ONLY);
GO  

------Listing 3-15 Configure delayed durability
--Set at database level only, all transactions commit as delayed durable
A--Set at database level only, all transactions commit as delayed durable
ALTER DATABASE ExamBook762Ch3_IMOLTP
    SET DELAYED_DURABILITY = FORCED;
--Override database delayed durability at commit for durable transaction
BEGIN TRANSACTION;
    INSERT INTO Examples.Order_IM_Hash
    (OrderId, OrderDate, CustomerCode) 
    VALUES (1, getdate(), 'cust1');  
COMMIT TRANSACTION WITH (DELAYED_DURABILITY = OFF);

--Set at transaction level only
ALTER DATABASE ExamBook762Ch3_IMOLTP
    SET DELAYED_DURABILITY = ALLOWED;
BEGIN TRANSACTION;
    INSERT INTO Examples.Order_IM_Hash
    (OrderId, OrderDate, CustomerCode) 
    VALUES (1, getdate(), 'cust1');  
COMMIT TRANSACTION WITH (DELAYED_DURABILITY = ON);
GO
--Set within a natively compiled stored procedure
CREATE PROCEDURE Examples.OrderInsert_NC_DD 
    @OrderID INT, 
    @CustomerCode NVARCHAR(10) 
WITH NATIVE_COMPILATION, SCHEMABINDING  
AS   
BEGIN ATOMIC 
WITH (DELAYED_DURABILITY = ON,
        TRANSACTION ISOLATION LEVEL = SNAPSHOT, LANGUAGE = N'English')  
    DECLARE @OrderDate DATETIME = getdate();  
    INSERT INTO Examples.Order_IM (OrderId, OrderDate, CustomerCode) 
    VALUES (@OrderID, @OrderDate, @CustomerCode);  
END;  
GO
--Disable delayed durability completely for all transactions
--    and natively compiled stored procedures
ALTER DATABASE ExamBook762Ch3_IMOLTP
    SET DELAYED_DURABILITY = DISABLED;



----Enable collection of execution statistics for natively compiled stored procedures

------Listing 3-16 Enable and disable statistics collection at the procedure level
--Enable statistics collection at the procedure level
EXEC sys.sp_xtp_control_proc_exec_stats @new_collection_value = 1; 

--Check the current status of procedure-level statistics collection
DECLARE @c BIT;  
EXEC sys.sp_xtp_control_proc_exec_stats @old_collection_value=@c output  
SELECT @c AS 'Current collection status';  

--Disable statistics collection at the procedure level
EXEC sys.sp_xtp_control_proc_exec_stats @new_collection_value = 0;  


------Listing 3-17 Enable and disable statistics collection at the query level
--Enable statistics collection at the query level
EXEC sys.sp_xtp_control_query_exec_stats @new_collection_value = 1;

--Check the current status of query-level statistics collection
DECLARE @c BIT;
EXEC sys.sp_xtp_control_query_exec_stats @old_collection_value=@c output;  
SELECT @c AS 'Current collection status';

--Disable statistics collection at the query level
EXEC sys.sp_xtp_control_query_exec_stats @new_collection_value = 0;  

--Enable statistics collection at the query level for a specific 
--natively compiled stored procedure
DECLARE @ncspid int;
DECLARE @dbid int;
SET @ncspid = OBJECT_ID(N'Examples.OrderInsert_NC');
SET @dbid = DB_ID(N'ExamBook762Ch3_IMOLTP')
EXEC sys.sp_xtp_control_query_exec_stats @new_collection_value = 1,
    @database_id = @dbid, @xtp_object_id = @ncspid;  

--Check the current status of query-level statistics collection for a specific
--natively compiled stored procedure
DECLARE @c bit;
DECLARE @ncspid int;
DECLARE @dbid int;
SET @ncspid = OBJECT_ID(N'Examples.OrderInsert_NC');
SET @dbid = DB_ID(N'ExamBook762Ch3_IMOLTP')
EXEC sys.sp_xtp_control_query_exec_stats @database_id = @dbid,
    @xtp_object_id = @ncspid, @old_collection_value=@c output;
SELECT @c AS 'Current collection status';  
 

--Disable statistics collection at the query level for a specific
--natively compiled stored procedure
DECLARE @ncspid int;
DECLARE @dbid int;
EXEC sys.sp_xtp_control_query_exec_stats @new_collection_value = 0,
    @database_id = @dbid, @xtp_object_id = @ncspid;  



------Listing 3-18 Get procedure-level statistics 
SELECT  
    OBJECT_NAME(PS.object_id) AS obj_name,
    PS.cached_time as cached_tm,
    PS.last_execution_time as last_exec_tm,
    PS.execution_count as ex_cnt,
    PS.total_worker_time as wrkr_tm,
    PS.total_elapsed_time as elpsd_tm
FROM sys.dm_exec_procedure_stats PS
INNER JOIN sys.all_sql_modules SM 
    ON SM.object_id = PS.object_id;

------Listing 3-19 Get query-level statistics 
SELECT
    st.objectid as obj_id,
    OBJECT_NAME(st.objectid) AS obj_name,
    SUBSTRING(st.text, 
        (QS.statement_start_offset / 2 ) + 1,
        ((QS.statement_end_offset - QS.statement_start_offset) / 2) + 1) 
            AS 'Query',
    QS.last_execution_time,
    QS.execution_count,
    QS.total_worker_time,
    QS.total_elapsed_time
FROM sys.dm_exec_query_stats QS
CROSS APPLY sys.dm_exec_sql_text(QS.sql_handle) st
INNER JOIN sys.all_sql_modules SM 
    ON SM.object_id = st.objectid
WHERE SM.uses_native_compilation = 1























