SET QUOTED_IDENTIFIER ON
SET ANSI_NULLS ON
GO
CREATE OR ALTER  VIEW Contrato.VwGetInformacoesContratosEmpenhos
AS 
SELECT cemp.IdContratoEmpenho,
       cemp.IdContrato,
       co.Codigo,
       cemp.IdEmpenho,
	  ep.Numero,
	  ep.Data,
      ep.IdPessoa,
	  pe.NomeRazaoSocial AS Favorecido,
      ep.IdPlanoConta,
	  pc.Nome AS ContaEmpenho,
      ep.Processo,
      ep.Tipo,
      ep.RestoAPagar,
      ep.ValorOriginalEmpenho,
      ep.ValorInscritoRestoAPagar,
      ep.ValorAnulado,
      ep.ValorPago,
      ep.ValorLiquidado,
      ep.Valor,
      ep.SaldoALiquidar,
      ep.ObrigacaoContratual
      FROM  Contrato.Contratos co 
JOIN Contrato.ContratosEmpenhos cemp ON cemp.IdContrato = co.IdContrato
JOIN Despesa.Empenhos ep ON ep.IdEmpenho = cemp.IdEmpenho
JOIN Cadastro.Pessoas pe ON ep.IdPessoa = pe.IdPessoa
JOIN Contabilidade.PlanoContas pc ON pc.IdPlanoConta = ep.IdPlanoConta
GO