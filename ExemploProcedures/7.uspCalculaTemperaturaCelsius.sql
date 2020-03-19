USE ExerciciosLogica
GO

-- =============================================
-- Author:		<Wesley.si.neves@gmail.com>
-- Description:	Faça um algoritmo que leia uma temperatura em Fahrenheit e a apresente
--convertida em graus Celsius. A fórmula de conversão é C = (F – 32) * ( 5 / 9), na
--qual F é a temperatura em Fahrenheit e C é a temperatura em Celcius.
-- Para testar : exec Calculos.uspCalculaTemperaturaCelsius 200
ALTER PROCEDURE Calculos.uspCalculaTemperaturaCelsius(@TempFahrenheit NUMERIC(18,2))
AS SET NOCOUNT OFF
BEGIN
	--declaração de variaveis
	DECLARE @Result NUMERIC(18,2)
	
	--Valida os dados de entrada
	SET @TempFahrenheit = ISNULL(@TempFahrenheit,0)
	
	--Efetua o calculo C = (F – 32) * ( 5 / 9),
	SET @Result = 	@TempFahrenheit - (32 * 5) / 9
	
	
	--retorna o resultado
SELECT @Result
END