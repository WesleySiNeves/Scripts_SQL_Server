
SELECT geo.Estado,
       base.CodContrato,
       cat.Nome,
       prod.DescricaoImplanta,
       tipo.Nome AS Tipo,
       situ.Nome AS Situacao,
       clipagador.Sigla AS SiglaPagador,
       cli.Sigla AS SiglaCliente,
       base.DataVigenciaInicial,
       base.DataVigenciaFinal,
       fina.Nome AS SituacaoFinanceira,
       base.Data_base,
       base.Periodicidade,
       base.PrecoUnitario,
       base.Quantidade,
       base.ValorDesconto,
       base.ValorTotal,
       base.QtdLicencasCIGAM,
       base.QuantidadeDiasVigenciaFinal,
       base.QtdDiasVigencia,
       base.Vencido,
       base.DataCarga,
       base.DataUltimaAtualizacao FROM DM_ContratosProdutos.FatoContratosProdutos base
	   LEFT JOIN Shared.DimGeografia geo ON base.SkUF = geo.Estado
	   LEFT JOIN Shared.DimCategorias cat ON cat.SkCategoria = base.SkCategoria
	   LEFT JOIN Shared.DimProdutos prod ON prod.SkProduto = base.SkProduto AND prod.VersaoAtual = 1
	   LEFT JOIN DM_ContratosProdutos.DimTipoContratos tipo ON tipo.SkTipoContrato = base.SkTipoContrato
	   LEFT JOIN DM_ContratosProdutos.DimTipoSituacaoContratos situ  ON situ.SkTipoSituacaoContrato = base.SkTipoSituacaoContrato
	   LEFT JOIN Shared.DimClientes clipagador ON clipagador.SkCliente = base.SkClientePagador AND clipagador.VersaoAtual = 1
    LEFT JOIN Shared.DimClientes cli ON cli.SkCliente = base.SkCliente AND cli.VersaoAtual = 1
	   LEFT JOIN DM_ContratosProdutos.DimTiposSituacaoFinanceira fina ON fina.SkTiposSituacaoFinanceira = base.SkTiposSituacaoFinanceira
