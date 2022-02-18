

USE AuditoriaDatabase

GO

CREATE OR ALTER FUNCTION Helper.FormataCasasDecimais(@texto VARCHAR(20))
RETURNS VARCHAR(20)
BEGIN
  

 
DECLARE @VALOR  DECIMAL(15,2), @X  INT, @retorno VARCHAR(20)

SET @VALOR  = CAST(@texto AS DECIMAL(15,0));

SET @X = CASE   WHEN LEN(@VALOR) BETWEEN 1 AND 6 THEN 3
                WHEN LEN(@VALOR) BETWEEN 7 AND 9 THEN 2
                WHEN LEN(@VALOR) BETWEEN 10 AND 12 THEN 1 
                WHEN LEN(@VALOR) BETWEEN 13 AND 15 THEN 0 END

SET @retorno =  REPLACE(LEFT(convert(varchar,cast(@VALOR as money),1),(LEN(@VALOR)-@X)),',','.')  + ',' + RIGHT(@VALOR,2)


-- exemplo SELECT Helper.FormataCasasDecimais('40400')  =Saida : 40.400,00
RETURN @retorno
END

GO

