

--Executando uma SP dentro do Select
CREATE PROCEDURE VerHora
AS   
BEGIN
	 SELECT GETDATE() AS d	
END

SELECT * FROM OPENROWSET('SQLOLEDB','(local)';'sa';'implanta','exec SisEagle.dbo.VerHOra')