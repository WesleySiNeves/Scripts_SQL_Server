-- Demonstration 10 - Maintaining Indexes


USE tempdb;
GO
-- Check the level of fragmentation again via sys.dm_db_index_physical_stats

SELECT * FROM sys.dm_db_index_physical_stats(DB_ID(),NULL,NULL,NULL,'DETAILED')
WHERE dm_db_index_physical_stats.avg_fragmentation_in_percent > 0
ORDER BY avg_fragmentation_in_percent DESC
GO

-- Note the avg_fragmentation_in_percent and avg_page_space_used_in_percent

-- Now we'll go ahead and remove the fragmentation

ALTER INDEX ALL ON dbo.PhoneLog REBUILD;
GO

-- Step 11: Check the level of fragmentation via sys.dm_db_index_physical_stats

SELECT * FROM sys.dm_db_index_physical_stats(DB_ID(),OBJECT_ID('dbo.PhoneLog'),NULL,NULL,'DETAILED');
GO

-- Step 12: Note the avg_fragmentation_in_percent and avg_page_space_used_in_percent

-- Step 13: Drop the table

DROP TABLE dbo.PhoneLog;
GO

