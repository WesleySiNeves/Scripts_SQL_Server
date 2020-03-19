USE WideWorldImporters;
GO
CREATE NONCLUSTERED INDEX IX_Purchasing_Suppliers_ExamBook762Ch4
ON Purchasing.Suppliers
(
    SupplierCategoryID,
    SupplierID
)
INCLUDE (SupplierName);


/*########################
# OBS: Mostra as Statisticas
*/

DBCC SHOW_STATISTICS ('Purchasing.Suppliers', IX_Purchasing_Suppliers_ExamBook762Ch4) 


GO

/*########################
# OBS: WITH DENSITY_VECTOR;
*/

