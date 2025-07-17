
CREATE OR ALTER VIEW Contrato.VwGetUnidadesModalidadesContratos
AS 
SELECT '00000000-0000-0000-0000-000000000000' AS IdModalidadeContrato,
'Não informada' AS NomeUnidade
UNION
SELECT DISTINCT mo.IdModalidadeContrato,
       mo.Nome AS NomeModalidadeContrato
FROM Contrato.Contratos c
      JOIN  Contrato.ModalidadeContrato mo ON mo.IdModalidadeContrato = c.IdModalidadeContrato
        

