CREATE FUNCTION [dbo].[SommenteNumeros] (@String_in VARCHAR(MAX))
RETURNS VARCHAR(MAX)
AS
BEGIN
    /*
   *****   Takes a string variable and turns it into a set of 
   *****   numbers separated by spaces.

   *****   Despite the name, it also removes punctuation, not
   *****   just letters.

   *****   Input string must be simple ASCII, not Unicode.
   *****   (No accented letters, etc.)
*/
    DECLARE @sub CHAR(1);

    --Letters
    WHILE PATINDEX('%[a-z]%', @String_in) > 0
    BEGIN
        SET @sub = SUBSTRING(@String_in, PATINDEX('%[a-z]%', @String_in), 1);

        SET @String_in = REPLACE(@String_in, @sub, '');
    END;

    --Punctuation
    WHILE PATINDEX('%[!-)]%', @String_in) > 0
    BEGIN
        SET @sub = SUBSTRING(@String_in, PATINDEX('%[!-/]%', @String_in), 1);

        SET @String_in = REPLACE(@String_in, @sub, '');
    END;

    WHILE PATINDEX('%[+-/]%', @String_in) > 0
    BEGIN
        SET @sub = SUBSTRING(@String_in, PATINDEX('%[!-/]%', @String_in), 1);

        SET @String_in = REPLACE(@String_in, @sub, '');
    END;

    WHILE PATINDEX('%[:-=]%', @String_in) > 0
    BEGIN
        SET @sub = SUBSTRING(@String_in, PATINDEX('%[:-@]%', @String_in), 1);

        SET @String_in = REPLACE(@String_in, @sub, '');
    END;

    WHILE PATINDEX('%[?-@]%', @String_in) > 0
    BEGIN
        SET @sub = SUBSTRING(@String_in, PATINDEX('%[:-@]%', @String_in), 1);

        SET @String_in = REPLACE(@String_in, @sub, '');
    END;

    SET @String_in = REPLACE(@String_in, '[', '');

    WHILE PATINDEX('%[\-`]%', @String_in) > 0
    BEGIN
        SET @sub = SUBSTRING(@String_in, PATINDEX('%[\-`]%', @String_in), 1);

        SET @String_in = REPLACE(@String_in, @sub, '');
    END;

    WHILE PATINDEX('%[{-~]%', @String_in) > 0
    BEGIN
        SET @sub = SUBSTRING(@String_in, PATINDEX('%[{-~]%', @String_in), 1);

        SET @String_in = REPLACE(@String_in, @sub, '');
    END;

    WHILE CHARINDEX('  ', @String_in, 0) > 0
    SET @String_in = REPLACE(@String_in, '  ', ' ');

    RETURN @String_in;
END;