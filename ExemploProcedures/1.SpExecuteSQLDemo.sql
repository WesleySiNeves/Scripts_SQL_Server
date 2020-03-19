USE TSQL2012;

DECLARE @SQLString AS NVARCHAR(4000),
        @address AS NVARCHAR(60);
SET @SQLString
    = N'
SELECT custid, companyname, contactname, contacttitle, address
FROM [Sales].[Customers]
WHERE address = @address';
SET @address = N'5678 rue de l''Abbaye';
EXEC sys.sp_executesql @statement = @SQLString,
                       @params = N'@address NVARCHAR(60)',
                       @address = @address;