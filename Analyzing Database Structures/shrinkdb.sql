-- Check database free space
use shrinktest
exec sp_spaceused 

-- Check index fragmentation
select * from sys.dm_db_index_physical_stats (DB_ID('shrinktest'), NULL, NULL, NULL, NULL) 
where avg_fragmentation_in_percent > 0 order by avg_fragmentation_in_percent desc

-- Shrink database data file
DBCC SHRINKFILE('shrinktest_Data',100)

-- Check database free space
use shrinktest
exec sp_spaceused 

-- Check index fragmentation
select * from sys.dm_db_index_physical_stats (DB_ID('shrinktest'), NULL, NULL, NULL, NULL) 
where avg_fragmentation_in_percent > 0 order by avg_fragmentation_in_percent desc