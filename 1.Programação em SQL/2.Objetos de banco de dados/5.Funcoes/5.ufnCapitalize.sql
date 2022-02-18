

USE AuditoriaDatabase

GO

/* ==================================================================
--Data: 05/09/2018 
--Autor :Wesley Neves
--Exemplo: 
DECLARE @NomeConta VARCHAR(100) ='Obrigações contratuais';
SELECT Helper.ufnCapitalize(@NomeConta)
-- ==================================================================
*/

CREATE OR ALTER FUNCTION Helper.ufnCapitalize(@Conteudo AS NVARCHAR(100))
RETURNS NVARCHAR(100)
AS
BEGIN

    DECLARE @ret_str AS VARCHAR(100),
            @pos AS     INT,
            @len AS     INT

    SELECT @ret_str = N' ' + LOWER(@Conteudo),
           @pos = 1,
           @len = LEN(@Conteudo) + 1

    WHILE @pos > 0 AND @pos < @len
    BEGIN
        SET @ret_str = STUFF(@ret_str, @pos + 1, 1, UPPER(SUBSTRING(@ret_str, @pos + 1, 1)))
        SET @pos = CHARINDEX(N' ', @ret_str, @pos + 1)
    END

    RETURN RIGHT(@ret_str, @len - 1)

END




