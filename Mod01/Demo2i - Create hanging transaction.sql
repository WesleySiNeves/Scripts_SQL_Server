
-- Module 1 - Demo 2 - File 1
USE TSQL;
GO

SELECT @@SPID as update_session_id;

BEGIN TRAN

	UPDATE Sales.Customers
	SET companyname = N'Customer Demo Update'
	WHERE custid = 10;

--ROLLBACK
