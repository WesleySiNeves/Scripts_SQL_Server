USE WideWorldImporters;

GO


CREATE VIEW Sales.vSalesByYear
WITH SCHEMABINDING
AS
SELECT YEAR(InvoiceDate) AS InvoiceYear,
       COUNT_BIG(*) AS InvoiceCount
FROM Sales.Invoices
GROUP BY YEAR(InvoiceDate);
GO
CREATE UNIQUE CLUSTERED INDEX idx_vSalesByYear
ON Sales.vSalesByYear (InvoiceYear);
GO

SELECT * FROM Sales.vSalesByYear AS VSBY