USE Implanta;

        WITH    MovimentoCTE ( IdPlanoConta, IdPlanoContaPai, EfetivacaoValor )
                  AS ( SELECT   MC.IdPlanoContaFinanceiroOrigem ,
                                PC.IdPlanoContaFinanceiroPai ,
                                MC.EfetivacaoValor
                       FROM     Agenda.LancamentosFinanceiros AS MC 
                                JOIN Agenda.ufnPlanoContasFinanceiro(2016)  AS PC ON MC.IdPlanoContaFinanceiroOrigem = PC.IdPlanoContaFinanceiro
                       UNION ALL
                       SELECT   PC.IdPlanoContaFinanceiro ,
                                PC.IdPlanoContaFinanceiroPai ,
                                MC.EfetivacaoValor
                       FROM     Agenda.ufnPlanoContasFinanceiro(2016) AS PC
                                JOIN MovimentoCTE AS MC ON MC.IdPlanoContaPai = PC.IdPlanoContaFinanceiro
                     )


            SELECT  PC.IdPlanoContaFinanceiro ,
                    PC.IdPlanoContaFinanceiroPai ,
                    PC.Codigo ,
                    PC.Nome ,
                    X.ValorCredito
            FROM    ( SELECT    MC.IdPlanoConta ,
                                SUM(MC.EfetivacaoValor) AS ValorCredito
                      FROM      MovimentoCTE MC
                      GROUP BY  MC.IdPlanoConta
                    ) X
                    JOIN Agenda.ufnPlanoContasFinanceiro(2016) AS PC ON X.IdPlanoConta = PC.IdPlanoContaFinanceiro
            ORDER BY PC.Codigo;