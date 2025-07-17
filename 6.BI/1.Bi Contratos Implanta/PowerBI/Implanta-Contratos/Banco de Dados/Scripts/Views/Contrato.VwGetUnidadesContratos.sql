
CREATE OR ALTER VIEW Contrato.VwGetUnidadesContratos
AS 
SELECT '00000000-0000-0000-0000-000000000000' AS IdUnidade,
'Não informada' AS NomeUnidade
UNION
SELECT DISTINCT uni.IdUnidade,
       uni.Nome AS NomeUnidade
FROM Contrato.Contratos c
      JOIN  Cadastro.Unidades uni ON uni.IdUnidade = c.IdUnidade
        

