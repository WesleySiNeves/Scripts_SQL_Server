
USE AuditoriaDatabase
GO

/* ==================================================================
--Data: 05/09/2018 
--Autor :Wesley Neves
--Observação: 
 Exemplo de Uso  SELECT Helper.IsGuid('F51530FA-A551-4B25-90CE-3C55CE4D541D')
-- ==================================================================
*/

CREATE FUNCTION  Helper.IsGuid(@StringToCompare VARCHAR(MAX))
 RETURNS BIT 
 AS
 BEGIN

 
  RETURN( SELECT 1  WHERE @StringToCompare LIKE 
       REPLACE('00000000-0000-0000-0000-000000000000', '0', '[0-9a-fA-F]'))
 END



