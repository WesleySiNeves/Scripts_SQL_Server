/* ==================================================================
--Data: 07/06/2018 
--Observação: Use a base do CRM-SP
 
 1) Rode a query com as statisticas normais do banco
 2) mate as statisticas criadas e rode a query abaixo ,
 3)Apos isso crie novamente as statisticas e rode a quey
-- ==================================================================
*/



--DBCC DROPCLEANBUFFERS ;

--DBCC FREEPROCCACHE;
--DBCC FREESESSIONCACHE;

--CHECKPOINT;
--GO





EXEC sys.sp_executesql N'SELECT 
[Project6].[C1] AS [C1], 
[Project6].[IdPagamento] AS [IdPagamento], 
[Project6].[IdLiquidacao] AS [IdLiquidacao], 
[Project6].[IdSaidaFinanceira1] AS [IdSaidaFinanceira], 
[Project6].[Numero] AS [Numero], 
[Project6].[DataPagamento] AS [DataPagamento], 
[Project6].[NumeroProcesso] AS [NumeroProcesso], 
[Project6].[RestoAPagar] AS [RestoAPagar], 
[Project6].[Estorno] AS [Estorno], 
[Project6].[CalculoTributo] AS [CalculoTributo], 
[Project6].[DataNotaFiscal] AS [DataNotaFiscal], 
[Project6].[SaldoEmpenho] AS [SaldoEmpenho], 
[Project6].[SaldoLiquidacao] AS [SaldoLiquidacao], 
[Project6].[DataCadastro] AS [DataCadastro], 
[Project6].[Valor1] AS [Valor], 
[Project6].[ValorLiquido] AS [ValorLiquido], 
[Project6].[ValorEstornado] AS [ValorEstornado], 
[Project6].[ProrrogacaoRestoAPagar] AS [ProrrogacaoRestoAPagar], 
[Project6].[Tipo] AS [Tipo], 
[Project6].[IdMovimentoFinanceiro] AS [IdMovimentoFinanceiro], 
[Project6].[IdPlanoContaOrigem] AS [IdPlanoContaOrigem], 
[Project6].[IdPlanoContaDestino] AS [IdPlanoContaDestino], 
[Project6].[IdTipoMovimento] AS [IdTipoMovimento], 
[Project6].[IdSaidaFinanceira2] AS [IdSaidaFinanceira1], 
[Project6].[Data] AS [Data], 
[Project6].[Valor2] AS [Valor1], 
[Project6].[Historico1] AS [Historico], 
[Project6].[Numero1] AS [Numero1], 
[Project6].[NumeroProcesso1] AS [NumeroProcesso1], 
[Project6].[DataNotaFiscal1] AS [DataNotaFiscal1], 
[Project6].[IdContaBancaria] AS [IdContaBancaria], 
[Project6].[Conta] AS [Conta], 
[Project6].[ContaDV] AS [ContaDV], 
[Project6].[NomeConta] AS [NomeConta], 
[Project6].[Operacao] AS [Operacao], 
[Project6].[IdPlanoConta1] AS [IdPlanoConta], 
[Project6].[ProximoNumeroCheque] AS [ProximoNumeroCheque], 
[Project6].[Padrao] AS [Padrao], 
[Project6].[Agencia] AS [Agencia], 
[Project6].[AgenciaDV] AS [AgenciaDV], 
[Project6].[LimiteTED] AS [LimiteTED], 
[Project6].[IdPessoa1] AS [IdPessoa], 
[Project6].[ConvenioPagamento] AS [ConvenioPagamento], 
[Project6].[CodigoCompromisso] AS [CodigoCompromisso], 
[Project6].[ParametroTransmissao] AS [ParametroTransmissao], 
[Project6].[AmbienteProducaoArquivoCNAB] AS [AmbienteProducaoArquivoCNAB], 
[Project6].[IdBanco] AS [IdBanco], 
[Project6].[DataSaldoInicial] AS [DataSaldoInicial], 
[Project6].[ValorSaldoInicial] AS [ValorSaldoInicial], 
[Project6].[DigitosAnoCheque] AS [DigitosAnoCheque], 
[Project6].[Ativo] AS [Ativo], 
[Project6].[NomeRazaoSocial] AS [NomeRazaoSocial], 
[Project6].[IdPessoa] AS [IdPessoa1], 
[Project6].[IdSaidaFinanceira] AS [IdSaidaFinanceira2], 
[Project6].[IdFormaPagamento] AS [IdFormaPagamento], 
[Project6].[Nome] AS [Nome], 
[Project6].[NumeroFormaPagamento] AS [NumeroFormaPagamento], 
[Project6].[Nome1] AS [Nome1], 
[Project6].[NumeroDocumento] AS [NumeroDocumento], 
[Project6].[Valor] AS [Valor2], 
[Project6].[Historico] AS [Historico1], 
[Project6].[CodigoAutenticacaoBancario] AS [CodigoAutenticacaoBancario], 
[Project6].[IdRecebimento] AS [IdRecebimento], 
[Project6].[IdPlanoConta] AS [IdPlanoConta1], 
[Project6].[IdPlanoContaBanco] AS [IdPlanoContaBanco], 
[Project6].[IdRegiao] AS [IdRegiao], 
[Project6].[Numero2] AS [Numero2], 
[Project6].[Quantidade] AS [Quantidade], 
[Project6].[NumeroDocumento1] AS [NumeroDocumento1], 
[Project6].[DataRecebimento] AS [DataRecebimento], 
[Project6].[Valor3] AS [Valor3], 
[Project6].[Historico2] AS [Historico2], 
[Project6].[NumeroProcesso2] AS [NumeroProcesso2], 
[Project6].[IdPlanoContaContrapartidaPatrimonio] AS [IdPlanoContaContrapartidaPatrimonio], 
[Project6].[RepasseAutomatico] AS [RepasseAutomatico], 
[Project6].[DataModificacao] AS [DataModificacao], 
[Project6].[Devolucao] AS [Devolucao], 
[Project6].[Deducao] AS [Deducao], 
[Project6].[DireitoContratual] AS [DireitoContratual], 
[Project6].[Numero3] AS [Numero3], 
[Project6].[NumeroOficial] AS [NumeroOficial], 
[Project6].[C3] AS [C2], 
[Project6].[C2] AS [C3]
FROM ( SELECT 
	[Project3].[IdSaidaFinanceira] AS [IdSaidaFinanceira], 
	[Project3].[IdFormaPagamento] AS [IdFormaPagamento], 
	[Project3].[IdPessoa] AS [IdPessoa], 
	[Project3].[Valor] AS [Valor], 
	[Project3].[NumeroFormaPagamento] AS [NumeroFormaPagamento], 
	[Project3].[NumeroDocumento] AS [NumeroDocumento], 
	[Project3].[Historico] AS [Historico], 
	[Project3].[CodigoAutenticacaoBancario] AS [CodigoAutenticacaoBancario], 
	[Project3].[IdPagamento] AS [IdPagamento], 
	[Project3].[IdLiquidacao] AS [IdLiquidacao], 
	[Project3].[IdSaidaFinanceira1] AS [IdSaidaFinanceira1], 
	[Project3].[Numero] AS [Numero], 
	[Project3].[DataPagamento] AS [DataPagamento], 
	[Project3].[NumeroProcesso] AS [NumeroProcesso], 
	[Project3].[RestoAPagar] AS [RestoAPagar], 
	[Project3].[Estorno] AS [Estorno], 
	[Project3].[CalculoTributo] AS [CalculoTributo], 
	[Project3].[DataNotaFiscal] AS [DataNotaFiscal], 
	[Project3].[SaldoEmpenho] AS [SaldoEmpenho], 
	[Project3].[SaldoLiquidacao] AS [SaldoLiquidacao], 
	[Project3].[DataCadastro] AS [DataCadastro], 
	[Project3].[Valor1] AS [Valor1], 
	[Project3].[ValorLiquido] AS [ValorLiquido], 
	[Project3].[ValorEstornado] AS [ValorEstornado], 
	[Project3].[ProrrogacaoRestoAPagar] AS [ProrrogacaoRestoAPagar], 
	[Project3].[Tipo] AS [Tipo], 
	[Project3].[IdMovimentoFinanceiro] AS [IdMovimentoFinanceiro], 
	[Project3].[IdPlanoContaOrigem] AS [IdPlanoContaOrigem], 
	[Project3].[IdPlanoContaDestino] AS [IdPlanoContaDestino], 
	[Project3].[IdTipoMovimento] AS [IdTipoMovimento], 
	[Project3].[IdSaidaFinanceira2] AS [IdSaidaFinanceira2], 
	[Project3].[Data] AS [Data], 
	[Project3].[Valor2] AS [Valor2], 
	[Project3].[Historico1] AS [Historico1], 
	[Project3].[Numero1] AS [Numero1], 
	[Project3].[NumeroProcesso1] AS [NumeroProcesso1], 
	[Project3].[DataNotaFiscal1] AS [DataNotaFiscal1], 
	[Project3].[NomeRazaoSocial] AS [NomeRazaoSocial], 
	[Project3].[Nome] AS [Nome], 
	[Project3].[Nome1] AS [Nome1], 
	[Project3].[IdRecebimento] AS [IdRecebimento], 
	[Project3].[IdPlanoConta] AS [IdPlanoConta], 
	[Project3].[IdPlanoContaBanco] AS [IdPlanoContaBanco], 
	[Project3].[IdRegiao] AS [IdRegiao], 
	[Project3].[Numero2] AS [Numero2], 
	[Project3].[Quantidade] AS [Quantidade], 
	[Project3].[NumeroDocumento1] AS [NumeroDocumento1], 
	[Project3].[DataRecebimento] AS [DataRecebimento], 
	[Project3].[Valor3] AS [Valor3], 
	[Project3].[Historico2] AS [Historico2], 
	[Project3].[NumeroProcesso2] AS [NumeroProcesso2], 
	[Project3].[IdPlanoContaContrapartidaPatrimonio] AS [IdPlanoContaContrapartidaPatrimonio], 
	[Project3].[RepasseAutomatico] AS [RepasseAutomatico], 
	[Project3].[DataModificacao] AS [DataModificacao], 
	[Project3].[Devolucao] AS [Devolucao], 
	[Project3].[Deducao] AS [Deducao], 
	[Project3].[DireitoContratual] AS [DireitoContratual], 
	[Project3].[Numero3] AS [Numero3], 
	[Project3].[NumeroOficial] AS [NumeroOficial], 
	1 AS [C1], 
	CASE WHEN ( EXISTS (SELECT 
		1 AS [C1]
		FROM   (SELECT [Extent23].[IdRelacaoCredito] AS [IdRelacaoCredito1], [Extent23].[IdSaidaFinanceira] AS [IdSaidaFinanceira]
			FROM  [Despesa].[RelacoesCreditosSaidas] AS [Extent23]
			INNER JOIN [Despesa].[RelacoesCreditos] AS [Extent24] ON [Extent23].[IdRelacaoCredito] = [Extent24].[IdRelacaoCredito]
			WHERE [Extent24].[Conferencia] <> cast(1 as bit) ) AS [Filter9]
		INNER JOIN [Despesa].[RelacoesCreditos] AS [Extent25] ON [Filter9].[IdRelacaoCredito1] = [Extent25].[IdRelacaoCredito]
		WHERE ([Project3].[IdSaidaFinanceira] = [Filter9].[IdSaidaFinanceira]) AND ([Extent25].[Ativa] = 1)
	)) THEN cast(1 as bit) WHEN ( NOT EXISTS (SELECT 
		1 AS [C1]
		FROM   (SELECT [Extent26].[IdRelacaoCredito] AS [IdRelacaoCredito2], [Extent26].[IdSaidaFinanceira] AS [IdSaidaFinanceira]
			FROM  [Despesa].[RelacoesCreditosSaidas] AS [Extent26]
			INNER JOIN [Despesa].[RelacoesCreditos] AS [Extent27] ON [Extent26].[IdRelacaoCredito] = [Extent27].[IdRelacaoCredito]
			WHERE [Extent27].[Conferencia] <> cast(1 as bit) ) AS [Filter11]
		INNER JOIN [Despesa].[RelacoesCreditos] AS [Extent28] ON [Filter11].[IdRelacaoCredito2] = [Extent28].[IdRelacaoCredito]
		WHERE ([Project3].[IdSaidaFinanceira] = [Filter11].[IdSaidaFinanceira]) AND ([Extent28].[Ativa] = 1)
	)) THEN cast(0 as bit) END AS [C2], 
	[Project3].[IdContaBancaria] AS [IdContaBancaria], 
	[Project3].[Conta] AS [Conta], 
	[Project3].[ContaDV] AS [ContaDV], 
	[Project3].[NomeConta] AS [NomeConta], 
	[Project3].[Operacao] AS [Operacao], 
	[Project3].[IdPlanoConta1] AS [IdPlanoConta1], 
	[Project3].[ProximoNumeroCheque] AS [ProximoNumeroCheque], 
	[Project3].[Padrao] AS [Padrao], 
	[Project3].[Agencia] AS [Agencia], 
	[Project3].[AgenciaDV] AS [AgenciaDV], 
	[Project3].[LimiteTED] AS [LimiteTED], 
	[Project3].[IdPessoa1] AS [IdPessoa1], 
	[Project3].[ConvenioPagamento] AS [ConvenioPagamento], 
	[Project3].[CodigoCompromisso] AS [CodigoCompromisso], 
	[Project3].[ParametroTransmissao] AS [ParametroTransmissao], 
	[Project3].[AmbienteProducaoArquivoCNAB] AS [AmbienteProducaoArquivoCNAB], 
	[Project3].[IdBanco] AS [IdBanco], 
	[Project3].[DataSaldoInicial] AS [DataSaldoInicial], 
	[Project3].[ValorSaldoInicial] AS [ValorSaldoInicial], 
	[Project3].[DigitosAnoCheque] AS [DigitosAnoCheque], 
	[Project3].[Ativo] AS [Ativo], 
	[Project3].[C1] AS [C3]
	FROM ( SELECT 
		[Extent1].[IdSaidaFinanceira] AS [IdSaidaFinanceira], 
		[Extent1].[IdFormaPagamento] AS [IdFormaPagamento], 
		[Extent1].[IdPessoa] AS [IdPessoa], 
		[Extent1].[Valor] AS [Valor], 
		[Extent1].[NumeroFormaPagamento] AS [NumeroFormaPagamento], 
		[Extent1].[NumeroDocumento] AS [NumeroDocumento], 
		[Extent1].[Historico] AS [Historico], 
		[Extent1].[CodigoAutenticacaoBancario] AS [CodigoAutenticacaoBancario], 
		[Limit1].[IdPagamento] AS [IdPagamento], 
		[Limit1].[IdLiquidacao] AS [IdLiquidacao], 
		[Limit1].[IdSaidaFinanceira] AS [IdSaidaFinanceira1], 
		[Limit1].[Numero] AS [Numero], 
		[Limit1].[DataPagamento] AS [DataPagamento], 
		[Limit1].[NumeroProcesso] AS [NumeroProcesso], 
		[Limit1].[RestoAPagar] AS [RestoAPagar], 
		[Limit1].[Estorno] AS [Estorno], 
		[Limit1].[CalculoTributo] AS [CalculoTributo], 
		[Limit1].[DataNotaFiscal] AS [DataNotaFiscal], 
		[Limit1].[SaldoEmpenho] AS [SaldoEmpenho], 
		[Limit1].[SaldoLiquidacao] AS [SaldoLiquidacao], 
		[Limit1].[DataCadastro] AS [DataCadastro], 
		[Limit1].[Valor] AS [Valor1], 
		[Limit1].[ValorLiquido] AS [ValorLiquido], 
		[Limit1].[ValorEstornado] AS [ValorEstornado], 
		[Limit1].[ProrrogacaoRestoAPagar] AS [ProrrogacaoRestoAPagar], 
		[Limit1].[Tipo] AS [Tipo], 
		[Limit2].[IdMovimentoFinanceiro] AS [IdMovimentoFinanceiro], 
		[Limit2].[IdPlanoContaOrigem] AS [IdPlanoContaOrigem], 
		[Limit2].[IdPlanoContaDestino] AS [IdPlanoContaDestino], 
		[Limit2].[IdTipoMovimento] AS [IdTipoMovimento], 
		[Limit2].[IdSaidaFinanceira] AS [IdSaidaFinanceira2], 
		[Limit2].[Data] AS [Data], 
		[Limit2].[Valor] AS [Valor2], 
		[Limit2].[Historico] AS [Historico1], 
		[Limit2].[Numero] AS [Numero1], 
		[Limit2].[NumeroProcesso] AS [NumeroProcesso1], 
		[Limit2].[DataNotaFiscal] AS [DataNotaFiscal1], 
		[Extent5].[NomeRazaoSocial] AS [NomeRazaoSocial], 
		[Extent6].[Nome] AS [Nome], 
		[Extent7].[Nome] AS [Nome1], 
		[Extent9].[IdRecebimento] AS [IdRecebimento], 
		[Extent9].[IdPlanoConta] AS [IdPlanoConta], 
		[Extent9].[IdPlanoContaBanco] AS [IdPlanoContaBanco], 
		[Extent9].[IdRegiao] AS [IdRegiao], 
		[Extent9].[Numero] AS [Numero2], 
		[Extent9].[Quantidade] AS [Quantidade], 
		[Extent9].[NumeroDocumento] AS [NumeroDocumento1], 
		[Extent9].[DataRecebimento] AS [DataRecebimento], 
		[Extent9].[Valor] AS [Valor3], 
		[Extent9].[Historico] AS [Historico2], 
		[Extent9].[NumeroProcesso] AS [NumeroProcesso2], 
		[Extent9].[IdPlanoContaContrapartidaPatrimonio] AS [IdPlanoContaContrapartidaPatrimonio], 
		[Extent9].[RepasseAutomatico] AS [RepasseAutomatico], 
		[Extent9].[DataModificacao] AS [DataModificacao], 
		[Extent9].[Devolucao] AS [Devolucao], 
		[Extent9].[Deducao] AS [Deducao], 
		[Extent9].[DireitoContratual] AS [DireitoContratual], 
		[Extent12].[Numero] AS [Numero3], 
		[Extent16].[NumeroOficial] AS [NumeroOficial], 
		[Extent2].[IdContaBancaria] AS [IdContaBancaria], 
		[Extent2].[Conta] AS [Conta], 
		[Extent2].[ContaDV] AS [ContaDV], 
		[Extent2].[NomeConta] AS [NomeConta], 
		[Extent2].[Operacao] AS [Operacao], 
		[Extent2].[IdPlanoConta] AS [IdPlanoConta1], 
		[Extent2].[ProximoNumeroCheque] AS [ProximoNumeroCheque], 
		[Extent2].[Padrao] AS [Padrao], 
		[Extent2].[Agencia] AS [Agencia], 
		[Extent2].[AgenciaDV] AS [AgenciaDV], 
		[Extent2].[LimiteTED] AS [LimiteTED], 
		[Extent2].[IdPessoa] AS [IdPessoa1], 
		[Extent2].[ConvenioPagamento] AS [ConvenioPagamento], 
		[Extent2].[CodigoCompromisso] AS [CodigoCompromisso], 
		[Extent2].[ParametroTransmissao] AS [ParametroTransmissao], 
		[Extent2].[AmbienteProducaoArquivoCNAB] AS [AmbienteProducaoArquivoCNAB], 
		[Extent2].[IdBanco] AS [IdBanco], 
		[Extent2].[DataSaldoInicial] AS [DataSaldoInicial], 
		[Extent2].[ValorSaldoInicial] AS [ValorSaldoInicial], 
		[Extent2].[DigitosAnoCheque] AS [DigitosAnoCheque], 
		[Extent2].[Ativo] AS [Ativo], 
		(SELECT 
			SUM([Extent22].[Valor]) AS [A1]
			FROM     (SELECT TOP (1) [Project2].[IdRelacaoCredito] AS [IdRelacaoCredito]
				FROM ( SELECT 
					[Filter7].[IdRelacaoCredito3] AS [IdRelacaoCredito], 
					[Filter7].[SeuNumeroCNAB] AS [SeuNumeroCNAB]
					FROM   (SELECT [Extent17].[IdRelacaoCredito] AS [IdRelacaoCredito3], [Extent17].[IdSaidaFinanceira] AS [IdSaidaFinanceira], [Extent17].[SeuNumeroCNAB] AS [SeuNumeroCNAB]
						FROM  [Despesa].[RelacoesCreditosSaidas] AS [Extent17]
						INNER JOIN [Despesa].[RelacoesCreditos] AS [Extent18] ON [Extent17].[IdRelacaoCredito] = [Extent18].[IdRelacaoCredito]
						WHERE [Extent18].[Conferencia] <> cast(1 as bit) ) AS [Filter7]
					INNER JOIN [Despesa].[RelacoesCreditos] AS [Extent19] ON [Filter7].[IdRelacaoCredito3] = [Extent19].[IdRelacaoCredito]
					WHERE ([Extent1].[IdSaidaFinanceira] = [Filter7].[IdSaidaFinanceira]) AND ([Extent19].[Ativa] = 1)
				)  AS [Project2]
				ORDER BY [Project2].[SeuNumeroCNAB] DESC ) AS [Limit6]
			LEFT OUTER JOIN [Despesa].[RelacoesCreditos] AS [Extent20] ON [Limit6].[IdRelacaoCredito] = [Extent20].[IdRelacaoCredito]
			INNER JOIN [Despesa].[RelacoesCreditosSaidas] AS [Extent21] ON [Extent20].[IdRelacaoCredito] = [Extent21].[IdRelacaoCredito]
			INNER JOIN [Despesa].[SaidasFinanceiras] AS [Extent22] ON [Extent21].[IdSaidaFinanceira] = [Extent22].[IdSaidaFinanceira]) AS [C1]
		FROM              [Despesa].[SaidasFinanceiras] AS [Extent1]
		LEFT OUTER JOIN [Despesa].[ContasBancarias] AS [Extent2] ON [Extent1].[IdPlanoConta] = [Extent2].[IdPlanoConta]
		OUTER APPLY  (SELECT TOP (1) [Extent3].[IdPagamento] AS [IdPagamento], [Extent3].[IdLiquidacao] AS [IdLiquidacao], [Extent3].[IdSaidaFinanceira] AS [IdSaidaFinanceira], [Extent3].[Numero] AS [Numero], [Extent3].[DataPagamento] AS [DataPagamento], [Extent3].[NumeroProcesso] AS [NumeroProcesso], [Extent3].[RestoAPagar] AS [RestoAPagar], [Extent3].[Estorno] AS [Estorno], [Extent3].[CalculoTributo] AS [CalculoTributo], [Extent3].[DataNotaFiscal] AS [DataNotaFiscal], [Extent3].[SaldoEmpenho] AS [SaldoEmpenho], [Extent3].[SaldoLiquidacao] AS [SaldoLiquidacao], [Extent3].[DataCadastro] AS [DataCadastro], [Extent3].[Valor] AS [Valor], [Extent3].[ValorLiquido] AS [ValorLiquido], [Extent3].[ValorEstornado] AS [ValorEstornado], [Extent3].[ProrrogacaoRestoAPagar] AS [ProrrogacaoRestoAPagar], [Extent3].[Tipo] AS [Tipo]
			FROM [Despesa].[Pagamentos] AS [Extent3]
			WHERE [Extent1].[IdSaidaFinanceira] = [Extent3].[IdSaidaFinanceira] ) AS [Limit1]
		OUTER APPLY  (SELECT TOP (1) [Extent4].[IdMovimentoFinanceiro] AS [IdMovimentoFinanceiro], [Extent4].[IdPlanoContaOrigem] AS [IdPlanoContaOrigem], [Extent4].[IdPlanoContaDestino] AS [IdPlanoContaDestino], [Extent4].[IdTipoMovimento] AS [IdTipoMovimento], [Extent4].[IdSaidaFinanceira] AS [IdSaidaFinanceira], [Extent4].[Data] AS [Data], [Extent4].[Valor] AS [Valor], [Extent4].[Historico] AS [Historico], [Extent4].[Numero] AS [Numero], [Extent4].[NumeroProcesso] AS [NumeroProcesso], [Extent4].[DataNotaFiscal] AS [DataNotaFiscal]
			FROM [Despesa].[MovimentosFinanceiros] AS [Extent4]
			WHERE [Extent1].[IdSaidaFinanceira] = [Extent4].[IdSaidaFinanceira] ) AS [Limit2]
		LEFT OUTER JOIN [Cadastro].[Pessoas] AS [Extent5] ON [Extent1].[IdPessoa] = [Extent5].[IdPessoa]
		LEFT OUTER JOIN [Despesa].[FormasPagamentos] AS [Extent6] ON [Extent1].[IdFormaPagamento] = [Extent6].[IdFormaPagamento]
		LEFT OUTER JOIN [Despesa].[TiposDocumentos] AS [Extent7] ON [Extent1].[IdTipoDocumento] = [Extent7].[IdTipoDocumento]
		OUTER APPLY  (SELECT TOP (1) [Extent8].[IdRecebimento] AS [IdRecebimento]
			FROM [Receita].[RecebimentosSaidasFinanceiras] AS [Extent8]
			WHERE [Extent1].[IdSaidaFinanceira] = [Extent8].[IdSaidaFinanceira] ) AS [Limit3]
		LEFT OUTER JOIN [Receita].[Recebimentos] AS [Extent9] ON [Limit3].[IdRecebimento] = [Extent9].[IdRecebimento]
		OUTER APPLY  (SELECT TOP (1) [Extent10].[IdLiquidacao] AS [IdLiquidacao]
			FROM [Despesa].[Pagamentos] AS [Extent10]
			WHERE [Extent1].[IdSaidaFinanceira] = [Extent10].[IdSaidaFinanceira] ) AS [Limit4]
		LEFT OUTER JOIN [Despesa].[Liquidacoes] AS [Extent11] ON [Limit4].[IdLiquidacao] = [Extent11].[IdLiquidacao]
		LEFT OUTER JOIN [Despesa].[Empenhos] AS [Extent12] ON [Extent11].[IdEmpenho] = [Extent12].[IdEmpenho]
		OUTER APPLY  (SELECT TOP (1) [Project1].[IdRelacaoCredito] AS [IdRelacaoCredito]
			FROM ( SELECT 
				[Filter5].[IdRelacaoCredito4] AS [IdRelacaoCredito], 
				[Filter5].[SeuNumeroCNAB] AS [SeuNumeroCNAB]
				FROM   (SELECT [Extent13].[IdRelacaoCredito] AS [IdRelacaoCredito4], [Extent13].[IdSaidaFinanceira] AS [IdSaidaFinanceira], [Extent13].[SeuNumeroCNAB] AS [SeuNumeroCNAB]
					FROM  [Despesa].[RelacoesCreditosSaidas] AS [Extent13]
					INNER JOIN [Despesa].[RelacoesCreditos] AS [Extent14] ON [Extent13].[IdRelacaoCredito] = [Extent14].[IdRelacaoCredito]
					WHERE [Extent14].[Conferencia] <> cast(1 as bit) ) AS [Filter5]
				INNER JOIN [Despesa].[RelacoesCreditos] AS [Extent15] ON [Filter5].[IdRelacaoCredito4] = [Extent15].[IdRelacaoCredito]
				WHERE ([Extent1].[IdSaidaFinanceira] = [Filter5].[IdSaidaFinanceira]) AND ([Extent15].[Ativa] = 1)
			)  AS [Project1]
			ORDER BY [Project1].[SeuNumeroCNAB] DESC ) AS [Limit5]
		LEFT OUTER JOIN [Despesa].[RelacoesCreditos] AS [Extent16] ON [Limit5].[IdRelacaoCredito] = [Extent16].[IdRelacaoCredito]
	)  AS [Project3]
)  AS [Project6]
WHERE (([Project6].[IdPagamento] IS NOT NULL) AND ((convert (datetime2, convert(varchar(255), [Project6].[DataPagamento], 102) ,  102)) >= (convert (datetime2, convert(varchar(255), @p__linq__0, 102) ,  102))) AND ((convert (datetime2, convert(varchar(255), [Project6].[DataPagamento], 102) ,  102)) <= (convert (datetime2, convert(varchar(255), @p__linq__1, 102) ,  102)))) OR (([Project6].[IdMovimentoFinanceiro] IS NOT NULL) AND ((convert (datetime2, convert(varchar(255), [Project6].[Data], 102) ,  102)) >= (convert (datetime2, convert(varchar(255), @p__linq__2, 102) ,  102))) AND ((convert (datetime2, convert(varchar(255), [Project6].[Data], 102) ,  102)) <= (convert (datetime2, convert(varchar(255), @p__linq__3, 102) ,  102)))) OR (([Project6].[IdRecebimento] IS NOT NULL) AND ((convert (datetime2, convert(varchar(255), [Project6].[DataRecebimento], 102) ,  102)) >= (convert (datetime2, convert(varchar(255), @p__linq__4, 102) ,  102))) AND ((convert (datetime2, convert(varchar(255), [Project6].[DataRecebimento], 102) ,  102)) <= (convert (datetime2, convert(varchar(255), @p__linq__5, 102) ,  102))))',
N'@p__linq__0 datetime2(7),@p__linq__1 datetime2(7),@p__linq__2 datetime2(7),@p__linq__3 datetime2(7),@p__linq__4 datetime2(7),@p__linq__5 datetime2(7)',
@p__linq__0 = '2018-06-01 03:00:00',
@p__linq__1 = '2018-06-30 03:00:00',
@p__linq__2 = '2018-06-01 03:00:00',
@p__linq__3 = '2018-06-30 03:00:00',
@p__linq__4 = '2018-06-01 03:00:00',
@p__linq__5 = '2018-06-30 03:00:00';