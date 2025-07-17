CREATE OR ALTER VIEW Contrato.VwGetGestoresContratos
AS 
SELECT '00000000-0000-0000-0000-000000000000' AS IdGestor,
'Não informada' AS Gestor
UNION
SELECT DISTINCT c.IdGestor,
       pegestor.NomeRazaoSocial AS Gestor
FROM Contrato.Contratos c
     JOIN Cadastro.Pessoas pegestor ON pegestor.IdPessoa = c.IdGestor