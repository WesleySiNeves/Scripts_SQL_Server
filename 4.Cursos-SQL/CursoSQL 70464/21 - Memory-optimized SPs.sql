-- Use the MemDemo database

USE MemDemo

-- Create a native stored proc
CREATE PROCEDURE dbo.InsertData
	WITH NATIVE_COMPILATION, SCHEMABINDING, EXECUTE AS OWNER
AS
BEGIN ATOMIC WITH (TRANSACTION ISOLATION LEVEL = SNAPSHOT, LANGUAGE = 'us_english')
	DECLARE @Memid int = 1
	WHILE @Memid <= 500000
	BEGIN
		INSERT INTO dbo.MemoryTable VALUES (@Memid, GETDATE())
		SET @Memid += 1
	END
END;
GO

-- Use the native stored proc. 
/* Note how long it has taken for the stored procedure to execute. 
This should be significantly lower than the time that it takes to 
insert data into the memory-optimized table by using a Transact-SQL INSERT statement.
*/

EXEC dbo.InsertData;