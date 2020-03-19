USE ExerciciosLogica
GO

-- =============================================
-- Author:		<Wesley.si.neves@gmail.com>
-- Description:	Fa�a um algoritmo que calcule e apresente o valor do volume de uma lata de
--�leo, utilizando a f�rmula VOLUME = 3,14159 * RAIO2 * ALTURA.>
-- Para testar : EXEC  Calculos.uspCalculaVolumeLata 10 ,10
-- =============================================
ALTER PROCEDURE Calculos.uspCalculaVolumeLata(@Raio DECIMAL(18,2),@Altura DECIMAL(18,2))
AS SET NOCOUNT OFF
BEGIN
	--declara��o de variaveis
	DECLARE @Result NUMERIC(18,2)	
	DECLARE @PI NUMERIC(18,2)
	
	--Inicializa��o de variaveis
	SET @PI = 3.14159
	
	--Valida dados de entrada
	--Valida o valor do raio
	SET @Raio = ISNULL(@Raio,0)
	
	--valida o valor da altura
	SET @Altura = ISNULL(@Altura,0)
		
		
	--Calcula o valor do volume VOLUME = 3,14159 * RAIO2 * ALTURA.
	SET @Result =( @PI *(POWER(@Raio,2) * @Altura))
		
	--Retorna o resultado do calculo	
	SELECT @Result	
END