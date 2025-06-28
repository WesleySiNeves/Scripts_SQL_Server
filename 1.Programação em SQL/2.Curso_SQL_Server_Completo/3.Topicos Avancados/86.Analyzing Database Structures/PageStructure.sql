--Create table and insert test data
use AdventureWorks;
GO

IF object_id('viewPage') is not null drop table viewPage; 
GO

CREATE TABLE viewPage
(
	ID int identity(1,1) not null,
	rowData varchar(8000)
)

DECLARE @i int = 1;
WHILE @i <=3 
BEGIN
INSERT INTO	viewPage (rowData) VALUES (REPLICATE(cast(@i as char(1)), 2000))
SET @i = @i + 1
END
GO


-- Find page information
SELECT DB_NAME(dm_db_database_page_allocations.database_id) AS DatabaseName,
       OBJECT_NAME(dm_db_database_page_allocations.object_id) TableName,
       dm_db_database_page_allocations.allocation_unit_type,
       dm_db_database_page_allocations.allocation_unit_type_desc,
       dm_db_database_page_allocations.allocated_page_file_id,
       dm_db_database_page_allocations.allocated_page_page_id
FROM sys.dm_db_database_page_allocations(DB_ID('AdventureWorks'), OBJECT_ID('viewPage'), NULL, NULL, 'DETAILED')
WHERE dm_db_database_page_allocations.page_type = 1;
GO

SELECT  sys.fn_PhysLocFormatter(%%PhysLoc%%),L.* FROM
dbo.viewPage AS  l 


-- Enable trace flag
DBCC TRACEON(3604);
GO


-- View page allocation
dbcc page('AdventureWorks',1,37280,3);
GO


-- Update data
update viewPage set viewPage.rowData = replicate('1',5000) where viewPage.ID = 1;
GO


-- Find page information
select db_name(dm_db_database_page_allocations.database_id), OBJECT_NAME(dm_db_database_page_allocations.object_id), dm_db_database_page_allocations.allocation_unit_type, dm_db_database_page_allocations.allocation_unit_type_desc, dm_db_database_page_allocations.allocated_page_file_id, dm_db_database_page_allocations.allocated_page_page_id 
from sys.dm_db_database_page_allocations(db_id('AdventureWorks'),object_id('viewPage'),NULL,NULL,'DETAILED')
where dm_db_database_page_allocations.page_type = 1;
GO


-- View updated page allocation
DBCC PAGE('AdventureWorks', 1, XXX, 3);
GO