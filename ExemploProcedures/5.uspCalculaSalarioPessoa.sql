	USE ExerciciosLogica

GO  
-- =============================================
-- Author:		<Wesley.si.neves@gmail.com>
-- Description:	Fa�a um algoritmo que:
--a) Obtenha o valor para a vari�vel HT (horas trabalhadas no m�s);
--b) Obtenha o valor para a vari�vel VH (valor hora trabalhada):
--c) Obtenha o valor para a vari�vel PD (percentual de desconto);
--d) Calcule o sal�rio bruto => SB = HT * VH;
--e) Calcule o total de desconto => TD = (PD/100)*SB;
--f) Calcule o sal�rio l�quido => SL = SB � TD;
--g) Apresente os valores de: Horas trabalhadas, Sal�rio Bruto, Desconto, Sal�rio Liquido.
-- Para testar : exec Calculos.uspCalculaSalario 200 ,10, 2
-- =============================================
ALTER PROCEDURE Calculos.uspCalculaSalario(@HorasTrabalhadas DECIMAL(18,2),@ValorHora DECIMAL(18,2), @PercDesconto DECIMAL(18,2))
AS SET NOCOUNT OFF
BEGIN
	--Declara��o de variaveis
	DECLARE @ValorTotalDescontado DECIMAL(18,2)
	DECLARE @SalarioBruto DECIMAL(18,2)
	DECLARE @SalarioLiquido DECIMAL(18,2)
	
	--Valida��o dos parametros de entrada
	--Valida o valor da hora trabalhada
	SET @HorasTrabalhadas = ISNULL(@HorasTrabalhadas,0)
	
	--Valida o valor da hora
	SET @ValorHora = ISNULL(@ValorHora,0)
	
	--Valida o percentual de desconto
	SET @PercDesconto = ISNULL(@PercDesconto,0)
	
	
	--Calcula o salario Bruto
	SET @SalarioBruto = @HorasTrabalhadas * @ValorHora
	
	--Calcula o valor descontado
	SET @ValorTotalDescontado = (@PercDesconto/100) * @SalarioBruto
	
	--Calcula o valor  do salario Liquido
	SET @SalarioLiquido = @SalarioBruto - @ValorTotalDescontado
	
	--Retorna o valor
	SELECT @SalarioLiquido
		
END