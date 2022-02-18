USE TSQL2012;
GO
DECLARE @SQLString AS NVARCHAR(4000) ,
    @outercount AS INT;
SET @SQLString = N'SET @innercount = (SELECT COUNT(*) FROM Production.Products)';
EXEC sp_executesql @statment = @SQLString,
    @params = N'@innercount AS int OUTPUT', @innercount = @outercount OUTPUT;
SELECT  @outercount AS 'RowCount';