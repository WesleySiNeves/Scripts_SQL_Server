USE AdventureWorks2012;   
GO  
-- Reorganize all indexes on the HumanResources.Employee table.  
ALTER INDEX ALL ON HumanResources.Employee  
REORGANIZE ;   
GO  
