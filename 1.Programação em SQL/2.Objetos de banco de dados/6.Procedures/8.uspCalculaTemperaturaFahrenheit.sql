USE [ExerciciosLogica]
GO
/****** Object:  StoredProcedure [dbo].[uspCalculaTemperaturaFahrenheit]    Script Date: 01/21/2013 09:39:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




 -- =============================================
-- Author:		<Wesley.si.neves@gmail.com>
-- Description:	<Procedure para calcular a temperatura em Fahrenheit
-- Para testar : exec [Calculos].[uspCalculaTemperaturaFahrenheit] 10
ALTER PROCEDURE [Calculos].[uspCalculaTemperaturaFahrenheit](@TempCelsius NUMERIC(18,2))
AS  SET NOCOUNT OFF
BEGIN
	--Declaração de variaveis
	DECLARE @Result NUMERIC(18,2)
	
	--Valida Dados de entrada
	SET @TempCelsius = ISNULL(@TempCelsius,0)
	
	--Calcula a temperatura F = (9 * C + 160) / 5,
	SET @Result = (((9 * @TempCelsius) + 160) /5)
		
		
	--Retorna o valor do calculo	
  SELECT @Result
END
