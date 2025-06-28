SELECT si.StockItemName,
       c.ColorName,
       s.SupplierName
FROM Warehouse.StockItems si
    INNER JOIN Warehouse.Colors c
        ON c.ColorID = si.ColoriD
    INNER JOIN Purchasing.Suppliers s
        ON s.SupplierID = si.SupplierID;

		GO
        



	--CREATE STATISTICS StatsSupplierID ON Warehouse.StockItems(SupplierID)
--DROP INDEX IX_Purchasing_Suppliers_ExamBook762Ch4_SupplierID ON Purchasing.Suppliers

--DROP INDEX IX_Warehouse_StockItems_ExamBook762Ch4_ColorID ON Warehouse.StockItems
	
--CREATE NONCLUSTERED INDEX
--IX_Purchasing_Suppliers_ExamBook762Ch4_SupplierID
--ON Purchasing.Suppliers
--(
--SupplierID ASC,
--SupplierName
--);
--GO
--CREATE NONCLUSTERED INDEX
--IX_Warehouse_StockItems_ExamBook762Ch4_ColorID
--ON Warehouse.StockItems
--(
--ColorID ASC,
--SupplierID ASC,
--StockItemName ASC
--);