

-- =============================================
-- MODELAGEM DATA WAREHOUSE - MÉTRICAS CONSOLIDADAS
-- Otimizada para Azure SQL Database (DTU)
-- =============================================



-- Criar schemas se não existirem
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'Shared')
    EXEC ('CREATE SCHEMA Shared');


IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'Staging')
    EXEC ('CREATE SCHEMA Staging');

IF NOT EXISTS
(
    SELECT *
    FROM sys.schemas
    WHERE name = 'DM_ContratosProdutos'
)
    EXEC ('CREATE SCHEMA DM_ContratosProdutos');


-- Limpeza das tabelas existentes


---- Gerar comandos para remover Foreign Keys
--SELECT 
--    CONCAT('ALTER TABLE [', s.name, '].[', t.name, '] DROP CONSTRAINT [', fk.name, ']') AS ComandoDropFK
--FROM sys.foreign_keys fk
--INNER JOIN sys.tables t ON fk.parent_object_id = t.object_id
--INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
--WHERE s.name NOT IN ('Implanta', 'Staging', 'dbo')
--ORDER BY s.name, t.name


--SELECT CONCAT('DROP TABLE ', se.name,'.',t.name) FROM  sys.tables t
--JOIN sys.schemas se ON se.schema_id = t.schema_id
--WHERE se.name NOT IN ('Implanta','Staging','dbo')

-- =============================================
-- TABELAS DIMENSÃO
-- =============================================

CREATE TABLE [Shared].[DimCategorias]
(
    SkCategoria SMALLINT NOT NULL,
    Nome VARCHAR(100) NOT NULL,
    [Ativo] BIT CONSTRAINT DEF_SharedDimCategoriasAtivo DEFAULT(1),
    [DataCarga] DATETIME2(2) CONSTRAINT DEF_SharedDimCategoriasDataCarga DEFAULT GETDATE(),
    [DataAtualizacao] DATETIME2(2) CONSTRAINT DEF_SharedDimCategoriasDataAtualizacao DEFAULT GETDATE(),
    CONSTRAINT [PK_DimDimCategoria]
        PRIMARY KEY CLUSTERED (SkCategoria)
) ON [PRIMARY]
WITH (DATA_COMPRESSION = PAGE);



-- DIMENSÃO PRODUTOS (TEMPORAL - SCD TIPO 2)
CREATE TABLE [Shared].[DimProdutos]
(
    [SkProduto] SMALLINT NOT NULL,
    [IdProduto] UNIQUEIDENTIFIER NOT NULL, -- Chave natural
    [DescricaoProdutoCigam] VARCHAR(250) NOT NULL,
	[CodigoProdutoCigam] VARCHAR(250) NOT NULL,
    [DescricaoProdutoImplanta] VARCHAR(250) NOT NULL,
    [Area] VARCHAR(50),
    [Ativo] BIT CONSTRAINT DEF_SharedDimProdutosAtivo DEFAULT 1,

                                           -- Campos de versionamento temporal (SCD Tipo 2)
    [DataInicioVersao] DATETIME2(2) NOT NULL
        DEFAULT GETDATE(),
    [DataFimVersao] DATETIME2(2) NULL,     -- NULL = versão atual
    [VersaoAtual] BIT NOT NULL
        DEFAULT 1,                         -- 1 = versão atual, 0 = histórica

                                           -- Auditoria
    [DataCarga] DATETIME2(2)
        DEFAULT GETDATE(),
    [DataAtualizacao] DATETIME2(2)
        DEFAULT GETDATE(),
    CONSTRAINT [PK_DimProdutos] -- Corrigido nome da constraint
        PRIMARY KEY CLUSTERED ([SkProduto])
)
WITH (DATA_COMPRESSION = PAGE);

-- Índice para busca por chave natural e versão atual
CREATE NONCLUSTERED INDEX [IX_DimProdutos_IdProduto_VersaoAtual]
ON [Shared].[DimProdutos] (
                              [IdProduto],
                              [VersaoAtual]
                          )
INCLUDE (
            [SkProduto],
            [DataInicioVersao],
            [DataFimVersao]
        )
WITH (DATA_COMPRESSION = PAGE, FILLFACTOR = 95);


-- DIMENSÃO CONSELHOS FEDERAIS
CREATE TABLE [Shared].[DimConselhosFederais]
(
    [SkConselhoFederal] SMALLINT NOT NULL IDENTITY(0, 1),
    [IdConselhoFederal] [UNIQUEIDENTIFIER] NOT NULL,
    [NomeRazaoSocial] [VARCHAR](250) COLLATE SQL_Latin1_General_CP1_CI_AI NOT NULL,
    [Sigla] [VARCHAR](50) COLLATE SQL_Latin1_General_CP1_CI_AI NOT NULL,
    SkCategoria SMALLINT NOT NULL
        DEFAULT (0),
    [Ativo] BIT
        DEFAULT 1,
    [DataCarga] DATETIME2(2)
        DEFAULT GETDATE(),
    [DataAtualizacao] DATETIME2(2)
        DEFAULT GETDATE(),
    CONSTRAINT [PK_DimConselhosFederais]
        PRIMARY KEY CLUSTERED ([SkConselhoFederal])
) ON [PRIMARY]
WITH (DATA_COMPRESSION = PAGE);

CREATE UNIQUE NONCLUSTERED INDEX IX_DimConselhosFederais_Id
ON [Shared].[DimConselhosFederais] (IdConselhoFederal)
INCLUDE (
            [SkConselhoFederal],
            [Sigla]
        )
WITH (DATA_COMPRESSION = PAGE, FILLFACTOR = 95);

-- DIMENSÃO CLIENTES (TEMPORAL - SCD TIPO 2)


CREATE TABLE [Shared].[DimClientes]
(
    [SkCliente] SMALLINT NOT NULL IDENTITY(1, 1),
    [IdCliente] UNIQUEIDENTIFIER NOT NULL, -- Chave natural
    [SkConselhoFederal] SMALLINT NOT NULL,
    [Nome] VARCHAR(100) NOT NULL,
    [SiglaCliente] VARCHAR(50) NOT NULL,
    [SiglaImplanta] VARCHAR(50) NOT NULL,
    [Estado] CHAR(2),
    [TipoCliente] VARCHAR(20),
    [Ativo] BIT
        DEFAULT 1,
    ClienteAtivoImplanta BIT NOT NULL
        DEFAULT (1),
    [DataInicioVersao] DATETIME2(2) NOT NULL -- Campos de versionamento temporal (SCD Tipo 2)
        DEFAULT GETDATE(),
    [DataFimVersao] DATETIME2(2) NULL,     -- NULL = versão atual
    [VersaoAtual] BIT NOT NULL
        DEFAULT 1,                         -- 1 = versão atual, 0 = histórica

                                           -- Auditoria
    [DataCarga] DATETIME2(2)
        DEFAULT GETDATE(),
    [DataAtualizacao] DATETIME2(2)
        DEFAULT GETDATE(),
    CONSTRAINT [PK_DimClientes]
        PRIMARY KEY CLUSTERED ([SkCliente]),
    CONSTRAINT [FK_DimClientes_ConselhoFederal]
        FOREIGN KEY ([SkConselhoFederal])
        REFERENCES [Shared].[DimConselhosFederais] ([SkConselhoFederal])
)
WITH (DATA_COMPRESSION = PAGE);

-- Índice para busca por chave natural e versão atual
CREATE NONCLUSTERED INDEX [IX_DimClientes_IdCliente_VersaoAtual]
ON [Shared].[DimClientes] (
                              [IdCliente],
                              [VersaoAtual]
                          )
INCLUDE (
            [SkCliente],
            [DataInicioVersao],
            [DataFimVersao]
        )
WITH (DATA_COMPRESSION = PAGE, FILLFACTOR = 95);

CREATE UNIQUE NONCLUSTERED INDEX IX_DimClientes_Sigla_VersaoAtual
ON [Shared].[DimClientes] (
                              SiglaCliente,
                              VersaoAtual
                          )
INCLUDE (
            SkCliente,
            IdCliente,
            Nome
        )
WITH (DATA_COMPRESSION = PAGE, FILLFACTOR = 95);

CREATE NONCLUSTERED INDEX IX_DimClientes_ConselhoFederal
ON [Shared].[DimClientes] (SkConselhoFederal)
WITH (DATA_COMPRESSION = PAGE);

-- Índice para consultas históricas
CREATE NONCLUSTERED INDEX IX_DimClientes_Historico
ON [Shared].[DimClientes] (
                              DataInicioVersao,
                              DataFimVersao
                          )
INCLUDE (
            SkCliente,
            IdCliente,
            Nome,
            SiglaCliente
        )
WITH (DATA_COMPRESSION = PAGE, FILLFACTOR = 95);


CREATE TABLE [DM_ContratosProdutos].[DimTipoContratos]
(
    SkTipoContrato TINYINT NOT NULL IDENTITY(0, 1),
    Nome VARCHAR(100) NOT NULL,
    [Ativo] BIT
        DEFAULT 1,
    [DataCarga] DATETIME2(2)
        DEFAULT GETDATE(),
    [DataAtualizacao] DATETIME2(2)
        DEFAULT GETDATE(),
    CONSTRAINT [PK_TipoContratos]
        PRIMARY KEY CLUSTERED (SkTipoContrato)
) ON [PRIMARY]
WITH (DATA_COMPRESSION = PAGE);

CREATE TABLE [DM_ContratosProdutos].[DimTipoSituacaoContratos]
(
    SkTipoSituacaoContrato TINYINT NOT NULL IDENTITY(0, 1),
    Nome VARCHAR(100) NOT NULL,
    [Ativo] BIT
        DEFAULT 1,
    [DataCarga] DATETIME2(2)
        DEFAULT GETDATE(),
    [DataAtualizacao] DATETIME2(2)
        DEFAULT GETDATE(),
    CONSTRAINT [PK_TipoSituacaoContratos]
        PRIMARY KEY CLUSTERED (SkTipoSituacaoContrato)
) ON [PRIMARY]
WITH (DATA_COMPRESSION = PAGE);

CREATE TABLE [DM_ContratosProdutos].[DimTiposSituacaoFinanceira]
(
    SkTiposSituacaoFinanceira TINYINT NOT NULL IDENTITY(0, 1),
    Nome VARCHAR(100) NOT NULL,
    [Ativo] BIT
        DEFAULT 1,
    [DataCarga] DATETIME2(2)
        DEFAULT GETDATE(),
    [DataAtualizacao] DATETIME2(2)
        DEFAULT GETDATE(),
    CONSTRAINT [PK_TipoTiposSituacaoFinanceira]
        PRIMARY KEY CLUSTERED (SkTiposSituacaoFinanceira)
) ON [PRIMARY]
WITH (DATA_COMPRESSION = PAGE);

-- DIMENSÃO TEMPO
CREATE TABLE [Shared].[DimTempo]
(
    [Data] DATE NOT NULL,
    [Ano] SMALLINT NOT NULL,
    [Mes] TINYINT NOT NULL,
    [Trimestre] TINYINT NOT NULL,
    [Semestre] TINYINT NOT NULL,
    [NomeMes] VARCHAR(20) NOT NULL,
    [DiaSemana] TINYINT NOT NULL,
    [NomeDiaSemana] VARCHAR(20) NOT NULL,
    CONSTRAINT [PK_DimTempo]
        PRIMARY KEY CLUSTERED ([Data])
)
WITH (DATA_COMPRESSION = PAGE);




-- =============================================
-- SCHEMA STAGING
-- =============================================

IF (NOT EXISTS
(
    SELECT *
    FROM sys.tables
    WHERE name = 'ClientesProdutosCIGAM'
)
   )
BEGIN

    CREATE TABLE [Staging].[ClientesProdutosCIGAM]
    (
        [IdClienteProduto] [UNIQUEIDENTIFIER] NOT NULL PRIMARY KEY,
        [UF] [VARCHAR](2) COLLATE SQL_Latin1_General_CP1_CI_AI NULL,
        [CodContrato] VARCHAR(10) NOT NULL,
        [Categoria] [VARCHAR](20) COLLATE SQL_Latin1_General_CP1_CI_AI NULL,
        [DescricaoProdutoSigam] [VARCHAR](60) COLLATE SQL_Latin1_General_CP1_CI_AI NULL,
		CodigoProdutoSigam VARCHAR(10) COLLATE SQL_Latin1_General_CP1_CI_AI NULL,
        [Tipo] [VARCHAR](60) COLLATE SQL_Latin1_General_CP1_CI_AI NULL,
        [Situacao] [VARCHAR](9) COLLATE SQL_Latin1_General_CP1_CI_AI NULL,
        [Pagador] [VARCHAR](30) COLLATE SQL_Latin1_General_CP1_CI_AI NULL,
        [SiglaCliente] [VARCHAR](30) COLLATE SQL_Latin1_General_CP1_CI_AI NULL,
        [DataVigenciaInicial] [DATE] NULL,
        [DataVigenciaFinal] [DATE] NULL,
        [DataBase] [DATE] NULL,
        [Periodicidade] VARCHAR(60) NULL,
        PrecoUnitario DECIMAL(10, 2) NOT NULL,
        Quantidade FLOAT NOT NULL,
        ValorDesconto DECIMAL(10, 2) NOT NULL,
        ValorTotal DECIMAL(10, 2) NOT NULL,
        [SituacaoFinanceira] [VARCHAR](30) COLLATE SQL_Latin1_General_CP1_CI_AI NULL,
        [QtdLicencas] [INT] NULL,
        [DataAtualizacao] [DATETIME2](2) NULL
    )
    WITH (DATA_COMPRESSION = PAGE);


END;


CREATE TABLE Shared.DimGeografia
(
    Estado CHAR(2) PRIMARY KEY,
    Regiao VARCHAR(30)
);
---- =============================================
---- TABELA FATO - CONTRATOS E PRODUTOS
---- =============================================


--DROP TABLE [DM_ContratosProdutos].[FatoContratosProdutos]
CREATE TABLE [DM_ContratosProdutos].[FatoContratosProdutos]
(
    -- Chaves Surrogate (Dimensões)
    [SkUF] CHAR(2) NOT NULL,
    [CodContrato] VARCHAR(10) NOT NULL,
    [SkCategoria] TINYINT NOT NULL,
    [SkProduto] SMALLINT NOT NULL,
    [SkTipoContrato] TINYINT NOT NULL,
    [SkTipoSituacaoContrato] TINYINT NOT NULL,
    [SkClientePagador] SMALLINT NOT NULL,
    [SkCliente] SMALLINT NOT NULL,
    [DataVigenciaInicial] DATE NOT NULL,
    [DataVigenciaFinal] DATE NOT NULL,
    [SkTiposSituacaoFinanceira] TINYINT NOT NULL,
    [Data_base] DATE NOT NULL,
                                          -- Métricas/Fatos
    [Periodicidade] VARCHAR(60) NOT NULL,
    PrecoUnitario DECIMAL(10, 2) NOT NULL,
    Quantidade SMALLINT NOT NULL,
    ValorDesconto DECIMAL(10, 2) NOT NULL,
    [ValorTotal] DECIMAL(10, 2) NOT NULL, -- Valor monetário do contrato
    [QtdLicencasCIGAM] SMALLINT NOT NULL
        DEFAULT 0,
    QuantidadeDiasVigenciaFinal AS DATEDIFF(DAY, GETDATE(), DataVigenciaFinal),
    [QtdDiasVigencia] AS DATEDIFF(DAY, DataVigenciaInicial, DataVigenciaFinal),
    Vencido AS IIF(DATEDIFF(DAY, DataVigenciaFinal, GETDATE()) > 0, 'SIM', 'NÂO'),
    [DataCarga] DATETIME2(2) NOT NULL,
    [DataUltimaAtualizacao] DATETIME2(2) NOT NULL
        DEFAULT GETDATE(),

                                          -- Chave Primária Composta
    CONSTRAINT [PK_FatoContratosProdutos]
        PRIMARY KEY CLUSTERED (
                                  [SkUF],
                                  [SkCliente],
                                  [SkProduto],
                                  [DataVigenciaInicial],
                                  [DataVigenciaFinal]
                              ),

                                          -- Chaves Estrangeiras
    CONSTRAINT [FK_FatoContratosProdutos_Cliente]
        FOREIGN KEY ([SkCliente])
        REFERENCES [Shared].[DimClientes] ([SkCliente]),
    CONSTRAINT [FK_FatoContratosProdutos_Produto]
        FOREIGN KEY ([SkProduto])
        REFERENCES [Shared].[DimProdutos] ([SkProduto]),
    CONSTRAINT [FK_FatoContratosProdutos_TipoContrato]
        FOREIGN KEY ([SkTipoContrato])
        REFERENCES [DM_ContratosProdutos].[DimTipoContratos] ([SkTipoContrato]),
    CONSTRAINT [FK_FatoContratosProdutos_TipoSituacaoContrato]
        FOREIGN KEY ([SkTipoSituacaoContrato])
        REFERENCES [DM_ContratosProdutos].[DimTipoSituacaoContratos] ([SkTipoSituacaoContrato]),
    CONSTRAINT [FK_FatoContratosProdutos_TipoSituacaoFinanceira]
        FOREIGN KEY ([SkTiposSituacaoFinanceira])
        REFERENCES [DM_ContratosProdutos].[DimTiposSituacaoFinanceira] ([SkTiposSituacaoFinanceira]),
    CONSTRAINT [FK_FatoContratosProdutos_DataVigenciaInicial]
        FOREIGN KEY ([DataVigenciaInicial])
        REFERENCES [Shared].[DimTempo] (Data),
    CONSTRAINT [FK_FatoContratosProdutos_DataVigenciaFinal]
        FOREIGN KEY ([DataVigenciaFinal])
        REFERENCES [Shared].[DimTempo] (Data),
)
WITH (DATA_COMPRESSION = PAGE);



-- =============================================
-- ÍNDICES PARA PERFORMANCE
-- =============================================

-- Índice para consultas por cliente e produto
CREATE NONCLUSTERED INDEX IX_FatoContratosProdutos_Cliente_Produto
ON [DM_ContratosProdutos].[FatoContratosProdutos] (
                                                      [SkCliente],
                                                      [SkProduto]
                                                  )
INCLUDE (
            [QtdLicencasCIGAM],
            [ValorTotal]
        )
WITH (DATA_COMPRESSION = PAGE, FILLFACTOR = 95);

-- Índice para consultas por período de vigência
CREATE NONCLUSTERED INDEX IX_FatoContratosProdutos_PeriodoVigencia
ON [DM_ContratosProdutos].[FatoContratosProdutos] (
                                                      [DataVigenciaInicial],
                                                      [DataVigenciaFinal]
                                                  )
INCLUDE (
            [SkCliente],
            [SkProduto],
            [QtdLicencasCIGAM]
        )
WITH (DATA_COMPRESSION = PAGE, FILLFACTOR = 95);

-- Índice para consultas por situação do contrato
CREATE NONCLUSTERED INDEX IX_FatoContratosProdutos_SituacaoContrato
ON [DM_ContratosProdutos].[FatoContratosProdutos] (
                                                      [SkTipoSituacaoContrato],
                                                      [SkTiposSituacaoFinanceira]
                                                  )
INCLUDE (
            [SkCliente],
            [QtdLicencasCIGAM],
            [ValorTotal]
        )
WITH (DATA_COMPRESSION = PAGE, FILLFACTOR = 95);



-- Verificar se a tabela Implanta.Produtos existe, se não, criar
IF NOT EXISTS
(
    SELECT *
    FROM sys.objects
    WHERE object_id = OBJECT_ID(N'Implanta.Produtos')
          AND type IN ( N'U' )
)
BEGIN
    CREATE TABLE Implanta.Produtos
    (
        [IdProduto] UNIQUEIDENTIFIER NOT NULL PRIMARY KEY,
        [NumeroProduto] SMALLINT NOT NULL,
        [DescricaoProduto] VARCHAR(250) NOT NULL,
        [Ativo] BIT NOT NULL,
        [Area] VARCHAR(20) NOT NULL,
        [DescricaoProdutoSigam] VARCHAR(100),
        [CodigoProdutoSigam] VARCHAR(10),
        [DataCriacao] DATETIME2
            DEFAULT GETDATE(),
        [DataAtualizacao] DATETIME2
            DEFAULT GETDATE()
    );
END;




