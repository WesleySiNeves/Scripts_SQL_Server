
/*########################
# OBS: Sintaxe
*/


GO

CREATE FUNCTION Examples.ReturnIntValue (@Value INT)
RETURNS INT
AS
BEGIN
    RETURN @Value
END;


GO

CREATE FUNCTION Sales.Customers_ReturnOrderCount
(
    @CustomerID INT,
    @OrderDate DATE = NULL
)
RETURNS INT
WITH RETURNS NULL ON NULL INPUT, --if all parameters NULL, return NULL immediately
SCHEMABINDING --make certain that the tables/columns referenced cannot change
AS
BEGIN
    DECLARE @OutputValue INT;
    SELECT @OutputValue = COUNT(*)
    FROM Sales.Orders
    WHERE CustomerID = @CustomerID
          AND (
                  OrderDate = @OrderDate
                  OR @OrderDate IS NULL
              );
    RETURN @OutputValue;
END;


/*########################
# OBS: Chamada
*/

SELECT Sales.Customers_ReturnOrderCount(905, '2013-01-01');




/*########################
# OBS:Identify differences between deterministic and non-deterministic functions

*/


GO
	
	SELECT
OBJECTPROPERTY(OBJECT_ID('Examples.UpperCaseFirstLetter'),
'IsDeterministic') IsDeterministic


SELECT SM.object_id,
		Eschema =OBJECT_SCHEMA_NAME(SM.object_id),
		Nome =OBJECT_NAME(SM.object_id),
       SM.definition,
       SM.uses_ansi_nulls,
       SM.uses_quoted_identifier,
       SM.is_schema_bound,
       SM.uses_database_collation,
       SM.is_recompiled,
       SM.null_on_null_input,
       SM.execute_as_principal_id,
       SM.uses_native_compilation FROM sys.sql_modules AS SM