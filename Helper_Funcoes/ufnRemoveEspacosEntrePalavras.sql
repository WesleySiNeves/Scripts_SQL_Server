

CREATE  OR ALTER FUNCTION Helper.ufnRemoveEspacosEntrePalavras (@texto VARCHAR(8000))
RETURNS VARCHAR(8000)
AS
BEGIN
    RETURN REPLACE(REPLACE(REPLACE(REPLACE(@texto, ' ', '<>'), '><', ''), '<>', ' '),' ','');


END;
