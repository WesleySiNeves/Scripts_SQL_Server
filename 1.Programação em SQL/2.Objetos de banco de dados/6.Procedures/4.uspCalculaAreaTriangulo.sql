
USE ExerciciosLogica

go


-- =============================================
-- Author:		<Wesley.si.neves@gmail.com>
-- Description:	<PROCEDURE para calcular a area da circuferencia>
-- Para testar : EXEC Calculos.uspCalculaAreaTriangulo 2,2
-- =============================================

ALTER  PROCEDURE Calculos.uspCalculaAreaTriangulo(@Base DECIMAL(18,2), @Altura  DECIMAL(18,2))
AS 
SET NOCOUNT OFF
BEGIN
	--Declaracao variaveis
	DECLARE @Area DECIMAL(18,2)
	
	
	--Validação dos parametros recebidos
	--Valida o valor da @Base
	SET @Base = ISNULL(@Base,0);
	
	--Valida o valor da @Altura
	SET @Altura = ISNULL(@Altura,0);
	
	
	--Começo da rotima para calcular a area do triangulo
	SET @Area = (@Base * @Altura) /2
				
				
	-- Retorna o valor do calculo se for nulo retorna 0		
    SELECT ISNULL(@Area,CAST(0 AS NUMERIC(18,2)))				
				
					
END
		
