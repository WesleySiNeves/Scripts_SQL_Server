
CREATE OR ALTER VIEW Contrato.VwGetPessoasResponsaveis
AS 
SELECT '00000000-0000-0000-0000-000000000000' AS IdPessoa,
'Não informada' AS Responsavel
UNION
SELECT DISTINCT pe.IdPessoa,
       pe.NomeRazaoSocial AS Responsavel
FROM Contrato.Contratos c
    JOIN Cadastro.Pessoas pe
        ON pe.IdPessoa = c.IdResponsavel

