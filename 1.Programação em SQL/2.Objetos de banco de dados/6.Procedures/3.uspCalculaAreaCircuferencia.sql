

-- =============================================
-- Author:		<Wesley.si.neves@gmail.com>
-- Description:	<Faça um algoritmo para calcular a área de uma circunferência, considerando a
--  fórmula ÁREA = ? * RAIO2. Utilize as variáveis AREA e RAIO, a constante ? (pi =
-- 3,14159) e os operadores aritméticos de multiplicação.
-- Para testar : EXEC Calculos.UspCalculaAreaCircuferencia 2
-- =============================================
CREATE PROCEDURE Calculos.uspCalculaAreaCircuferencia(@Raio DECIMAL(18,2))
AS  
SET NOCOUNT OFF
BEGIN
	--Declaracao variaveis
	DECLARE @Area DECIMAL(18,2) 
	DECLARE @PI DECIMAL(18,2) 
	
	-- Atribuindo Valor a Variavel
    SET @PI =3.14
    SET @Area = 0
	
	-- Valida  o parametro de entrada
	IF(@Raio IS NULL)
	BEGIN
	  SET @Raio =0
	END
	-- Comeca a rotina de Calculo
	ELSE
	BEGIN
		SET @Area = (@PI *(@Raio * @Raio))
	    
	 -- Retorna o valor do calculo se for nulo retorna 0
		SELECT ISNULL(@Area,CAST(0 AS NUMERIC(18,2)))
	END
END