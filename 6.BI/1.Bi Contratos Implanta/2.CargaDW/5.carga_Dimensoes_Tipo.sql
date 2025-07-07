



-- Para que o primeiro registro tenha ID = 0



DELETE FROM [DM_ContratosProdutos].[DimTipoContratos]

DELETE FROM [DM_ContratosProdutos].DimTipoSituacaoContratos

DELETE FROM [DM_ContratosProdutos].DimTiposSituacaoFinanceira

DBCC CHECKIDENT ('[DM_ContratosProdutos].[DimTipoContratos]', RESEED, 0);
DBCC CHECKIDENT ('[DM_ContratosProdutos].[DimTipoSituacaoContratos]', RESEED, 0);
DBCC CHECKIDENT ('[DM_ContratosProdutos].[DimTiposSituacaoFinanceira]', RESEED, 0);


INSERT INTO [DM_ContratosProdutos].[DimTipoContratos]
(
    [Nome]
)

SELECT DISTINCT Tipo FROM Staging.ClientesProdutosCIGAM


INSERT INTO [DM_ContratosProdutos].DimTipoSituacaoContratos
(
    Nome
)
SELECT DISTINCT  Situacao FROM Staging.ClientesProdutosCIGAM


INSERT INTO [DM_ContratosProdutos].DimTiposSituacaoFinanceira
(
    Nome
)

SELECT DISTINCT  SituacaoFinanceira FROM Staging.ClientesProdutosCIGAM



