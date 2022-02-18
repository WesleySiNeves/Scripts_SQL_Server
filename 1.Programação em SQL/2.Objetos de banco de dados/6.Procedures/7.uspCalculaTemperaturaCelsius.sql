USE ExerciciosLogica
GO

-- =============================================
-- Author:		<Wesley.si.neves@gmail.com>
-- Description:	Fa�a um algoritmo que leia uma temperatura em Fahrenheit e a apresente
--convertida em graus Celsius. A f�rmula de convers�o � C = (F � 32) * ( 5 / 9), na
--qual F � a temperatura em Fahrenheit e C � a temperatura em Celcius.
-- Para testar : exec Calculos.uspCalculaTemperaturaCelsius 200
ALTER PROCEDURE Calculos.uspCalculaTemperaturaCelsius(@TempFahrenheit NUMERIC(18,2))
AS SET NOCOUNT OFF
BEGIN
	--declara��o de variaveis
	DECLARE @Result NUMERIC(18,2)
	
	--Valida os dados de entrada
	SET @TempFahrenheit = ISNULL(@TempFahrenheit,0)
	
	--Efetua o calculo C = (F � 32) * ( 5 / 9),
	SET @Result = 	@TempFahrenheit - (32 * 5) / 9
	
	
	--retorna o resultado
SELECT @Result
END