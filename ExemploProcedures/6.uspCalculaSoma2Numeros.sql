USE ExerciciosLogica
go

-- =============================================
-- Author:		<Wesley.si.neves@gmail.com>
-- Description:	<PROCEDURE para calcular a soma de 2 numeros>
-- Para testar : exec Calculos.uspSoma2Numeros 2,2
-- =============================================
ALTER PROCEDURE Calculos.uspSoma2Numeros(@Numero1 DECIMAL(18,2),@Numero2 DECIMAL(18,2))
AS SET NOCOUNT OFF
BEGIN
		--declaração de variaveis
		DECLARE @Result DECIMAL(18,2)
		
		--Validação dos paramentros de entrada
		--Valida o numero 1
		SET @Numero1 = ISNULL(@Numero1,0)
		
		--Valida o numero 2
		SET @Numero2 =ISNULL(@Numero2,0)
		
		--Efetua a soma
		SET @Result = @Numero1 + @Numero2
		
		--retorna o valor com o calculo
		SELECT @Result
		
		
END