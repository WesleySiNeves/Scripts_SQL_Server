---Identify differences between deterministic and non-deterministic functions
CREATE FUNCTION Helper.UpperCaseFirstLetter (@Value VARCHAR(50))
RETURNS NVARCHAR(50)
WITH SCHEMABINDING
AS
BEGIN
    --start at position 2, as 1 will always be uppercase if it exists
    DECLARE @OutputValue NVARCHAR(50),
            @position INT = 2,
            @previousPosition INT;
    IF LEN(@Value) = 0
        RETURN @OutputValue;
    --remove leading spaces, uppercase the first character
    SET @OutputValue = (LTRIM(CONCAT(UPPER(SUBSTRING(@Value, 1, 1)), LOWER(SUBSTRING(@Value, 2, 99)))));
    --if no space characters, exit
    IF CHARINDEX(' ', @OutputValue, 1) = 0
        RETURN @OutputValue;
    WHILE 1 = 1
    BEGIN
        SET @position = CHARINDEX(' ', @OutputValue, @position) + 1;
        IF @position < @previousPosition
           OR @position = 0
            BREAK;
        SELECT @OutputValue
            = CONCAT(
                        SUBSTRING(@OutputValue, 1, @position - 1),
                        UPPER(SUBSTRING(@OutputValue, @position, 1)),
                        SUBSTRING(@OutputValue, @position + 1, 50)
                    ),
               @previousPosition = @position;
    END;
    RETURN @OutputValue;
END;
GO