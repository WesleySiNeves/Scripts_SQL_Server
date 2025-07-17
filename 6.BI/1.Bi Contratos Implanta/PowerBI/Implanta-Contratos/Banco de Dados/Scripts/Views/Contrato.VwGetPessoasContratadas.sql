
CREATE OR ALTER VIEW Contrato.VwGetPessoasContratadas
AS 
SELECT '00000000-0000-0000-0000-000000000000' AS IdPessoa,
'Não informada' AS Fornecedor
UNION
SELECT DISTINCT pe.IdPessoa,
       pe.NomeRazaoSocial AS Fornecedor
FROM Contrato.Contratos c
    JOIN Cadastro.Pessoas pe
        ON pe.IdPessoa = c.IdPessoaContratado

