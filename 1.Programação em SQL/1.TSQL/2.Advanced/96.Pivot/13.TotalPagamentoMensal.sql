
DECLARE @Exercicio INT = 2016;


WITH    Dados
          AS ( SELECT   [Pessoa] = P2.NomeRazaoSocial ,
                        [Mes] = MONTH(P.DataPagamento) ,
                        P.Valor
               FROM     Despesa.Pagamentos AS P
                        JOIN Despesa.SaidasFinanceiras AS SF
                        ON SF.IdSaidaFinanceira = P.IdSaidaFinanceira
                        JOIN Cadastro.Pessoas AS P2
                        ON P2.IdPessoa = SF.IdPessoa
               WHERE    YEAR(P.DataPagamento) = @Exercicio),
        DadosPivot
          AS ( SELECT   P.Pessoa ,
                        [Exercicio] = 2016 ,
                        ISNULL(P.[1], 0) AS [Janeiro] ,
                        ISNULL(P.[2], 0) AS [Fereveiro] ,
                        ISNULL(P.[3], 0) AS [Março] ,
                        ISNULL(P.[4], 0) AS [Abril] ,
                        ISNULL(P.[5], 0) AS [Maio] ,
                        ISNULL(P.[6], 0) AS [Junho] ,
                        ISNULL(P.[7], 0) AS [Julho] ,
                        ISNULL(P.[8], 0) AS [Agosto] ,
                        ISNULL(P.[9], 0) AS [Setembro] ,
                        ISNULL(P.[10], 0) AS [Outubro] ,
                        ISNULL(P.[11], 0) AS [Novembro] ,
                        ISNULL(P.[12], 0) AS [Dezembro]
               FROM     Dados PIVOT( SUM(Valor) FOR Mes IN ( [1], [2], [3],
                                                             [4], [5], [6],
                                                             [7], [8], [9],
                                                             [10], [11], [12] ) ) P)
     SELECT P.Pessoa ,
            P.Exercicio ,
			[Total] =(SUM(P.[Janeiro] + P.[Fereveiro] +P.[Março]  + P.[Abril] + P.[Maio] + P.[Junho] + P.[Julho] + P.[Agosto] +P.[Setembro] +P.[Outubro] + P.[Novembro] +P.[Dezembro]) OVER(PARTITION BY P.Pessoa)),
            P.Janeiro ,
            P.Fereveiro ,
            P.Março ,
            P.Abril ,
            P.Maio ,
            P.Junho ,
            P.Julho ,
            P.Agosto ,
            P.Setembro ,
            P.Outubro ,
            P.Novembro ,
            P.Dezembro
     FROM   DadosPivot P;
	