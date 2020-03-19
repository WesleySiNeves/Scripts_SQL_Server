--Enable Memory-Optimized Tables in a Database	

/*
**	On the Filegroups page, in the MEMORY OPTIMIZED DATA section, click Add Filegroup.
**	In the Name box, type MemFG. Note that the filegroups in this section are used to contain FILESTREAM files because memory-optimized tables are persisted as streams.
**	On the General page, click Add to add a database file. Then add a new file that has the following properties:
****	Logical Name: MemData
****	File Type: FILESTREAM Data
****	Filegroup: MemFG
**	 In the Script drop-down list, click Script Action to New Query Window.
**	Click Cancel to view the script file that has been generated.
**	Review the script, noting the syntax that has been used to create a filegroup for memory-optimized data. You can use similar syntax to add a filegroup to an existing database.
**	Click Execute to create the database
*/

-- Create a memory-optimized table
USE MemDemo
GO
CREATE TABLE dbo.MemoryTable
(id INTEGER NOT NULL PRIMARY KEY NONCLUSTERED HASH WITH (BUCKET_COUNT = 1000000),
 date_value DATETIME NULL)
WITH (MEMORY_OPTIMIZED = ON, DURABILITY = SCHEMA_AND_DATA);

-- Query Memory-Optimized Tables
-- Create a disk-based table
CREATE TABLE dbo.DiskTable
(id INTEGER NOT NULL PRIMARY KEY NONCLUSTERED,
 date_value DATETIME NULL);


-- Insert 500,000 rows into DiskTable. This code uses a transaction to insert rows into the disk-based table.
-- When code execution is complete, look at the lower right of the query editor status bar and note how long it has taken

BEGIN TRAN
	DECLARE @Diskid int = 1
	WHILE @Diskid <= 500000
	BEGIN
		INSERT INTO dbo.DiskTable VALUES (@Diskid, GETDATE())
		SET @Diskid += 1
	END
COMMIT;

-- Verify DiskTable contents. Confirm that the table now contains 500,000 rows
SELECT COUNT(*) FROM dbo.DiskTable;

-- Insert 500,000 rows into MemoryTable. This code uses a transaction to insert rows into the memory-optimized table.
/* When code execution is complete, look at the lower right of the query editor status bar
   and note how long it has taken. It should be significantly lower than the time that it 
   takes to insert data into the disk-based table.
*/

BEGIN TRAN
	DECLARE @Memid int = 1
	WHILE @Memid <= 500000
	BEGIN
		INSERT INTO dbo.MemoryTable VALUES (@Memid, GETDATE())
		SET @Memid += 1
	END
COMMIT;

-- Verify MemoryTable contents. Confirm that the table now contains 500,000 rows
SELECT COUNT(*) FROM dbo.MemoryTable;

-- Delete rows from DiskTable. Note how long it has taken for this code to execute.
DELETE FROM DiskTable;

-- Delete rows from MemoryTable. 
/* Note how long it has taken for this code to execute. 
It should be significantly lower than the time that it takes to 
delete rows from the disk-based table.
*/

DELETE FROM MemoryTable;

GO

-- View memory-optimized table stats
SELECT o.Name, m.*
FROM
sys.dm_db_xtp_table_memory_stats m
JOIN sys.sysobjects o
ON m.object_id = o.id
