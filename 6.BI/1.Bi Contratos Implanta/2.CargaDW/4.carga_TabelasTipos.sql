


IF(NOT EXISTS(SELECT * FROM DM_ContratosProdutos.DimTipoSituacaoContratos
				WHERE Nome ='Não informado'))
BEGIN
		
		INSERT INTO DM_ContratosProdutos.DimTipoSituacaoContratos
		    (
		        Nome,
		        Ativo,
		        DataCarga,
		        DataAtualizacao
		    )
		VALUES
		    (
		        'Não informado',      -- Nome - varchar(100)
		        DEFAULT, -- Ativo - bit
		        DEFAULT, -- DataCarga - datetime2(2)
		        DEFAULT  -- DataAtualizacao - datetime2(2)
		    )
END

IF(NOT EXISTS(SELECT * FROM DM_ContratosProdutos.DimTiposSituacaoFinanceira
				WHERE Nome ='Não informado'))
BEGIN
INSERT INTO DM_ContratosProdutos.DimTiposSituacaoFinanceira
    (
        Nome,
        Ativo,
        DataCarga,
        DataAtualizacao
    )
VALUES
    (
        'Não informado',      -- Nome - varchar(100)
        DEFAULT, -- Ativo - bit
        DEFAULT, -- DataCarga - datetime2(2)
        DEFAULT  -- DataAtualizacao - datetime2(2)
    )
END
IF(NOT EXISTS(SELECT * FROM DM_ContratosProdutos.DimTipoContratos
				WHERE Nome ='Não informado'))
BEGIN
INSERT INTO  DM_ContratosProdutos.DimTipoContratos
    (
        Nome,
        Ativo,
        DataCarga,
        DataAtualizacao
    )
VALUES
    (
        'Não informado',      -- Nome - varchar(100)
        DEFAULT, -- Ativo - bit
        DEFAULT, -- DataCarga - datetime2(2)
        DEFAULT  -- DataAtualizacao - datetime2(2)
    )
END


