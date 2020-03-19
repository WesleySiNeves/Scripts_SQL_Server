
WITH    Dados
          AS ( SELECT   [Favorecido] = P2.NomeRazaoSocial ,
                        Quantidade = COUNT(*) ,
                        Mes = MONTH(P.DataPagamento) ,
                        P.NumeroProcesso ,
                        Valor = SUM(P.Valor)
               FROM     Despesa.Pagamentos AS P
                        JOIN Despesa.SaidasFinanceiras AS SF ON SF.IdSaidaFinanceira = P.IdSaidaFinanceira
                        JOIN Cadastro.Pessoas AS P2 ON P2.IdPessoa = SF.IdPessoa
               WHERE    YEAR(P.DataPagamento) = 2016
               GROUP BY MONTH(P.DataPagamento) ,
                        P2.NomeRazaoSocial ,
                        P.NumeroProcesso
             ),
        PivotDados
          AS ( SELECT   PV.Favorecido ,
                        PV.Quantidade ,
                        PV.NumeroProcesso ,
                        PV.[1] ,
                        PV.[2] ,
                        PV.[3] ,
                        PV.[4] ,
                        PV.[5] ,
                        PV.[6] ,
                        PV.[7] ,
                        PV.[8] ,
                        PV.[9] ,
                        PV.[10] ,
                        PV.[11] ,
                        PV.[12]
               FROM     Dados R PIVOT ( SUM(Valor) FOR Mes IN ( [1], [2], [3],
                                                              [4], [5], [6],
                                                              [7], [8], [9],
                                                              [10], [11], [12] ) ) PV
             )
    SELECT  *
    FROM    PivotDados PV UNPIVOT( Valor FOR Mes IN ( [1], [2], [3], [4], [5],
                                                      [6], [7], [8], [9], [10],
                                                      [11], [12] ) ) UP;
--ORDER BY Favorecido ,Mes,P.NumeroProcesso

