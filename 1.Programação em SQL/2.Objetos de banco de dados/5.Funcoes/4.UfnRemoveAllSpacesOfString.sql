CREATE OR ALTER FUNCTION Helper.RemoveAllSpaces (@InputStr VARCHAR(8000))
RETURNS VARCHAR(8000)
AS
BEGIN
    DECLARE @ResultStr VARCHAR(8000);
    SET @ResultStr = @InputStr;
    WHILE CHARINDEX('  ', @ResultStr) > 0
    SET @ResultStr = REPLACE(@InputStr, '  ', '');

    RETURN @ResultStr;

--Exemplo SELECT Helper.RemoveAllSpaces('Wesley     Neves')  saida : 'Wesley Neves'
END;