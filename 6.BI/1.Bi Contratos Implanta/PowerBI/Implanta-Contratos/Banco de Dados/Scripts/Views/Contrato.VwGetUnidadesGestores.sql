
CREATE OR ALTER VIEW Contrato.VwGetUnidadesGestores
AS 

SELECT DISTINCT ISNULL(c.IdUnidadeGestor,'00000000-0000-0000-0000-000000000000') AS IdUnidadeGestor,
       ISNULL(u.Nome,'Não informada') AS UnidadeGestor
FROM Contrato.Contratos c
     JOIN Cadastro.Pessoas pegestor ON pegestor.IdPessoa = c.IdGestor
    LEFT JOIN  Cadastro.Unidades u ON u.IdUnidade = c.IdUnidadeGestor
	