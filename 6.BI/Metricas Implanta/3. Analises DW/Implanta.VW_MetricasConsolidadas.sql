
-- View consolidada para análises
CREATE VIEW [Implanta].[VW_MetricasConsolidadas]
AS
SELECT 
    c.Nome AS ClienteNome,
    c.Sigla AS ClienteSigla,
    c.UF,
    c.Categoria AS ClienteCategoria,
    cf.Sigla AS ConselhoSigla,
    cf.NomeRazaoSocial AS ConselhoNome,
    s.Descricao AS SistemaDescricao,
    s.Area AS SistemaArea,
    m.NomeMetrica,
    m.TipoRetorno,
    m.Categoria AS MetricaCategoria,
    t.Data,
    t.Ano,
    t.Mes,
    t.NomeMes,
    t.Trimestre,
    f.Valor,
    f.ValorTexto,
    f.ValorData,
    f.DataProcessamento
FROM [Implanta].[FatoMetricas] f
    INNER JOIN [Implanta].[DimClientes] c ON f.SkCliente = c.SkCliente
    INNER JOIN [Implanta].[DimConselhosFederais] cf ON c.SkConselhoFederal = cf.SkConselhoFederal
    INNER JOIN [Implanta].[DimSistemas] s ON f.SkSistema = s.SkSistema
    INNER JOIN [Implanta].[DimMetricas] m ON f.SkMetrica = m.SkMetrica
    INNER JOIN [Implanta].[DimTempo] t ON f.DataKey = t.DataKey
WHERE c.Ativo = 1 AND s.Ativo = 1 AND m.Ativo = 1;

GO