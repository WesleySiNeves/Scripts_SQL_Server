SELECT  P.NomeRazaoSocial
FROM    Cadastro.Pessoas AS P
WHERE   NomeRazaoSocial COLLATE SQL_Latin1_General_CP1_CI_AS LIKE '%[γινϊσ]%';