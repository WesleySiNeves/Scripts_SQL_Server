
USE AuditoriaDatabase

GO


CREATE FUNCTION [Helper].[ufnAllMes]()
RETURNS  @tableRetorno table
(
   Mes int not null,
   MesExtenso varchar(max) 
)
as
BEGIN
------DECLARE @retorno  as  table (Mes int, MesExtenso varchar(max))
INSERT INTO @tableRetorno ([@retorno].Mes, [@retorno].MesExtenso)
	VALUES (1, 'Janeiro'),
	(2, 'Fevereiro'),
	(3, 'Março'),
	(4, 'Abril'),
	(5, 'Maio'),
	(6, 'Junho'),
	(7, 'Julho'),
	(8, 'Agosto'),
	(9, 'Setembro'),
	(10, 'Outubro'),
	(11, 'Novembro'),
	(12, 'Dezembro')

RETURN
END;


 