

-- Version 3 With parameter testing

/*

O error_number é um número inteiro que representa a exceção. O error_number deve ser maior que 50,000 e menor que ou igual a 2,147,483,647.
*/
IF OBJECT_ID('Production.InsertProducts', 'P') IS NOT NULL
    DROP PROCEDURE Production.InsertProducts;
GO
CREATE PROCEDURE Production.InsertProducts @productname AS NVARCHAR(40) ,
    @supplierid AS INT ,
    @categoryid AS INT ,
    @unitprice AS MONEY = 0 ,
    @discontinued AS BIT = 0
AS
    BEGIN
        DECLARE @ClientMessage NVARCHAR(100);
        BEGIN TRY
-- Test parameters
            IF NOT EXISTS ( SELECT 1
                                FROM Production.Suppliers
                                WHERE supplierid = @supplierid )
                BEGIN
                    SET @ClientMessage = 'Supplier id '
                        + CAST(@supplierid AS VARCHAR) + ' is invalid';
                    THROW 50000, @ClientMessage, 0;
                END;
            IF NOT EXISTS ( SELECT 1
                                FROM Production.Categories
                                WHERE categoryid = @categoryid )
                BEGIN
                    SET @ClientMessage = 'Category id '
                        + CAST(@categoryid AS VARCHAR) + ' is invalid';
                    THROW 50000, @ClientMessage, 0;
                END;
            IF NOT ( @unitprice >= 0 )
                BEGIN
                    SET @ClientMessage = 'Unitprice '
                        + CAST(@unitprice AS VARCHAR)
                        + ' is invalid. Must be >= 0.';
                    THROW 50000, @ClientMessage, 0;
                END;
-- Perform the insert
            INSERT Production.Products
                    ( productname ,
                      supplierid ,
                      categoryid ,
                      unitprice ,
                      discontinued
                    )
                VALUES
                    ( @productname ,
                      @supplierid ,
                      @categoryid ,
                      @unitprice ,
                      @discontinued
                    );
        END TRY
        BEGIN CATCH
            THROW;
        END CATCH;
    END;
GO




------####################---


SELECT * FROM Production.Products AS P
WHERE P.productname ='Teste'

EXEC Production.InsertProducts @productname = N'Teste2', -- nvarchar(40)
    @supplierid = 1, -- int
    @categoryid = 1, -- int
    @unitprice = -10, -- money
    @discontinued = 0 -- bit