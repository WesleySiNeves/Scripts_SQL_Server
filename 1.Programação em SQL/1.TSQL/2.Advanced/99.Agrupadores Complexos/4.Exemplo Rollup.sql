USE Implanta

SELECT 
       P.NomeRazaoSocial,
	   Quantidade = COUNT(E.IdEmpenho) ,
       [Conta] = CONCAT(pc.Codigo,'-',pc.Nome),
       --E.Exercicio ,
       --E.Tipo ,
       --Mes = MONTH(E.Data) ,
     Total = FORMAT(SUM(E.Valor),'C','pt-BR' )
        FROM  Despesa.Empenhos AS E
JOIN Cadastro.Pessoas AS P ON P.IdPessoa = E.IdPessoa
JOIN Contabilidade.PlanoContas AS PC ON PC.IdPlanoConta = E.IdPlanoConta
WHERE E.Exercicio = 2016
--AND P.NomeRazaoSocial ='ADRIANO FALVO'
GROUP BY ROLLUP
(
	P.NomeRazaoSocial,
	CONCAT(pc.Codigo,'-',pc.Nome)

)
ORDER BY P.NomeRazaoSocial,Conta



SELECT 
       P.NomeRazaoSocial,
	   Quantidade = COUNT(E.IdEmpenho) ,
       [Conta] = CONCAT(pc.Codigo,'-',pc.Nome),
	   Mes = MONTH(E.Data) ,
       --E.Exercicio ,
       --E.Tipo ,
     Total = FORMAT(SUM(E.Valor),'C','pt-BR' )
	 
        FROM  Despesa.Empenhos AS E
JOIN Cadastro.Pessoas AS P ON P.IdPessoa = E.IdPessoa
JOIN Contabilidade.PlanoContas AS PC ON PC.IdPlanoConta = E.IdPlanoConta
WHERE E.Exercicio = 2016
AND P.NomeRazaoSocial ='ADRIANO FALVO'
GROUP BY CUBE(P.NomeRazaoSocial,CONCAT(pc.Codigo,'-',pc.Nome),MONTH(E.Data))


SELECT 
       P.NomeRazaoSocial,
	   Quantidade = COUNT(E.IdEmpenho) ,
       [Conta] = CONCAT(pc.Codigo,'-',pc.Nome),
	   Mes = MONTH(E.Data) ,
       --E.Exercicio ,
       --E.Tipo ,
     Total = FORMAT(SUM(E.Valor),'C','pt-BR' )
	 
        FROM  Despesa.Empenhos AS E
JOIN Cadastro.Pessoas AS P ON P.IdPessoa = E.IdPessoa
JOIN Contabilidade.PlanoContas AS PC ON PC.IdPlanoConta = E.IdPlanoConta
WHERE E.Exercicio = 2016
AND P.NomeRazaoSocial ='ADRIANO FALVO'
GROUP BY GROUPING SETS 
(
( P.NomeRazaoSocial ,CONCAT(pc.Codigo,'-',pc.Nome),MONTH(E.Data))
)
