

/* ==================================================================
--Data: 05/09/2018 
--Autor :Wesley Neves
--Observa��o: Lendo o artigo :https://www.sqlshack.com/creating-an-automatic-view-to-an-in-line-table-function-conversion-stored-procedure/
tive a ideia de comparar a filtragem de uma view e a filtragem de uma fun��o
 
 vamos em outra sess�o executar isso com o plano de execu��o ligado

 SELECT * FROM  Contabilidade.VwGetLancamentosEMovimentosDosExercicios AS VGLEMDE
WHERE VGLEMDE.Exercicio = 2018


SELECT * FROM Contabilidade.unfLancamentosEMovimentosDosExercicios(2018) AS ULEMDE


aqui prova que o plano de execu��o tem o mesmo custo
-- ==================================================================
*/

/*Criacao da View*/
SELECT * FROM  Contabilidade.VwGetLancamentosEMovimentosDosExercicios AS VGLEMDE
WHERE VGLEMDE.Exercicio = 2018



/*Criacao da Fun��o*/
GO
CREATE FUNCTION Contabilidade.unfLancamentosEMovimentosDosExercicios (@exercicio INT)
RETURNS TABLE
AS RETURN
    WITH Dados
      AS (SELECT DISTINCT
              L.Exercicio
          FROM Contabilidade.Lancamentos AS L
         )
    SELECT L.Numero AS [NumeroLancamento],
           L.Data [DataLancamento],
           L.TotalDebito [ValorTotalDebito],
           L.TotalCredito [ValorTotalCredito],
           L.Origem,
           L.Exercicio,
           CASE M.Credito
               WHEN 1 THEN
                   'Cr�dito'
               ELSE
                   'D�bito'
           END [TipoMovimento],
           M.Valor [ValorMovimento],
           PC.Codigo [CodigoContaContabil],
           PC.Nome [NomeContaContabil],
           M.Historico [HistoricoMovimento]
    FROM Dados R
         JOIN
         Contabilidade.Lancamentos AS L ON R.Exercicio = L.Exercicio
         JOIN
         Contabilidade.Movimentos AS M ON L.IdLancamento = M.IdLancamento
         CROSS APPLY Contabilidade.ufnPlanoContaSintetica(R.Exercicio) AS PC
    WHERE PC.IdPlanoConta = M.IdPlanoConta
          AND L.Exercicio = @exercicio;

GO
