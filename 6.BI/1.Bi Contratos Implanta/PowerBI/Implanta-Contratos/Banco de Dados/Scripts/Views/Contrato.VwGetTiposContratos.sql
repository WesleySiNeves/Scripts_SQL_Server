
CREATE OR ALTER VIEW Contrato.VwGetTiposContratos
AS 
SELECT '00000000-0000-0000-0000-000000000000' AS IdTipoContrato,
'Não informada' AS TipoContrato
UNION
SELECT DISTINCT tc.IdTipoContrato,
       tc.Nome AS TipoContrato
FROM Contrato.Contratos c
 LEFT  JOIN Contrato.TiposContratos tc ON  tc.IdTipoContrato = c.IdTipoContrato

