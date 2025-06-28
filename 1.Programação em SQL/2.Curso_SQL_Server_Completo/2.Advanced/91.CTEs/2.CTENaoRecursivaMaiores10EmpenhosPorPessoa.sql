
USE Implanta;

				with CTENaoRecursiva as
				(
				
				SELECT   Query.NomeRazaoSocial ,
						Query.RowRank ,
						Query.Valor 
               FROM     ( SELECT 
								NomeRazaoSocial =  p.NomeRazaoSocial,
								RowRank = RANK() over(  PARTITION BY p.NomeRazaoSocial ORDER BY e.Valor)  ,
					            Valor = e.Valor FROM Despesa.Empenhos e
				                JOIN  Cadastro.Pessoas p ON e.IdPessoa = p.IdPessoa
			               
                        ) AS Query
				)

				select CTE.NomeRazaoSocial,CTE.RowRank,CTE.Valor from CTENaoRecursiva CTE
				where  CTE.RowRank < 10