-- =============================================
-- Autor:  Wesley
-- Data: Criação automática - Versão otimizada com CTE
-- =============================================
CREATE VIEW Shared.VwGetFatoContratos
AS
SELECT  vw.SkUF,
        vw.SkCategoria,
        vw.SkProduto,
        vw.SkTipoContrato,
        vw.SkTipoSituacaoContrato,
        vw.SkClientePagador,
        vw.SkCliente,
        vw.SkDataVigenciaInicial,
        vw.SkDataVigenciaFinal,
        vw.SkTiposSituacaoFinanceira,
        vw.CodContrato,
        vw.QtdLicencas,
        vw.ValorContrato,
        vw.DiasVigencia,
        vw.DataCarga,
        vw.DataUltimaAtualizacao,
		PagoPorOutroCliente = IIF(vw.SkCliente <> vw.SkClientePagador,'SIM','NÃO'),
		-- CAST(CAST(SkDataVigenciaInicial AS VARCHAR(8)) AS DATE) AS DataVigenciaInicial,
		--CAST(CAST(SkDataVigenciaFinal AS VARCHAR(8)) AS DATE) AS DataVigenciaFinal,
		Status = IIF(DATEDIFF(DAY, CAST(CAST(vw.SkDataVigenciaFinal AS VARCHAR(8)) AS DATE),GETDATE()) < 0, 'Vencido','Não Vencido')
		FROM DM_ContratosProdutos.FatoContratosProdutos  vw