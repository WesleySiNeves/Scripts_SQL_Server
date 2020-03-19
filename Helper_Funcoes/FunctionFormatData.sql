
--CREATE SCHEMA Helper

DROP FUNCTION IF EXISTS Helper.FormatData;
 
 GO
 
CREATE FUNCTION  Helper.FormatData(@data DATE)
RETURNS VARCHAR(10)
WITH RETURNS NULL ON NULL INPUT
BEGIN
    RETURN (CONVERT(VARCHAR, CONVERT(DATE, @data, 103), 103));

END;

GO


DECLARE @Campos TABLE (Valor VARCHAR(20));

INSERT INTO @Campos (Valor)
VALUES ('19780613'),
('19790716'),
('19690123'),
('19710703'),
('19670530'),
('19681219'),
('19540327'),
('19710909'),
('19870424'),
('19601013');




SELECT ValorOriginal = C.Valor,
 [ValorConvertido para Data] =	CONVERT(DATE, C.Valor,103),
 [ValorConvertido para Varchar] = CONVERT(varchar,CONVERT(DATE, C.Valor,103),103),
 [Data Formatada Na Função] = Helper.FormatData(C.Valor)
  FROM @Campos AS C;

GO

 
 

  


--SELECT CONVERT(DATE,@variavel,101)

--Aí no meu código eu ponho em ordem (DD/MM/AAAA) e adiciono as '/',
