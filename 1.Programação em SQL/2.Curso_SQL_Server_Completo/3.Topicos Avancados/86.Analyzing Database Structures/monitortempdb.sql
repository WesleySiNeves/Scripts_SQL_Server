
-- Amount of space in each tempdb file (Free and Used)
use tempdb
SELECT name, physical_name, SUM(size)*1.0/128 AS [size in MB]
FROM sys.database_files
group by name, physical_name

-- Amount of free space in each tempdb file
SELECT b.name, b.physical_name, SUM(unallocated_extent_page_count) AS [free pages], 
(SUM(unallocated_extent_page_count)*1.0/128) AS [free space in MB]
FROM sys.dm_db_file_space_usage a join sys.database_files b
on a.file_id = b.file_id
GROUP BY b.name, b.physical_name

-- Amount of space used by the version Store
SELECT SUM(version_store_reserved_page_count) AS [version store pages used],
(SUM(version_store_reserved_page_count)*1.0/128) AS [version store space in MB]
FROM sys.dm_db_file_space_usage;

-- Number of pages and the amount of space in MB used by internal objects
SELECT SUM(internal_object_reserved_page_count) AS [internal object pages used],
(SUM(internal_object_reserved_page_count)*1.0/128) AS [internal object space in MB]
FROM sys.dm_db_file_space_usage;

-- Amount of space used by user objects in tempdb
SELECT SUM(user_object_reserved_page_count) AS [user object pages used],
(SUM(user_object_reserved_page_count)*1.0/128) AS [user object space in MB]
FROM sys.dm_db_file_space_usage;
