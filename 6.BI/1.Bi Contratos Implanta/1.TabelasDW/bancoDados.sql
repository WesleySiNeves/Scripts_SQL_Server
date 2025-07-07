
SELECT sc.name,t.name FROM  sys.tables t
JOIN sys.schemas sc ON sc.schema_id = t.schema_id



-- =============================================
-- MODELAGEM DATA WAREHOUSE - MÉTRICAS CONSOLIDADAS
-- Otimizada para Azure SQL Database (DTU)
-- =============================================

-- Criar schemas se não existirem
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'Shared')
    EXEC ('CREATE SCHEMA Shared');


IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'Staging')
    EXEC ('CREATE SCHEMA Staging');

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'DM_ContratosProdutos')
    EXEC ('CREATE SCHEMA DM_ContratosProdutos');


-- Limpeza das tabelas existentes

DROP TABLE IF EXISTS [DM_ContratosProdutos].[FatoContratosProdutos];
DROP TABLE IF EXISTS [Shared].[DimSistemas];
DROP TABLE IF EXISTS [Shared].[DimCategorias];
DROP TABLE IF EXISTS [Shared].[DimClientes];
DROP TABLE IF EXISTS [Shared].[DimConselhosFederais];
DROP TABLE IF EXISTS [Shared].[DimTempo];

DROP TABLE IF EXISTS [DM_ContratosProdutos].[DimTipoContratos]
DROP TABLE IF EXISTS [DM_ContratosProdutos].[DimTipoSituacaoContratos]
DROP TABLE IF EXISTS [DM_ContratosProdutos].[DimTiposSituacaoFinanceira]


--DM_MetricasClientes
-- =============================================
-- TABELAS DIMENSÃO
-- =============================================

CREATE TABLE [Shared].[DimCategorias]
(
    SkCategoria SMALLINT NOT NULL,
    Nome VARCHAR(100) NOT NULL,
    [Ativo] BIT
        DEFAULT 1,
    [DataCarga] DATETIME2(2)
        DEFAULT GETDATE(),
    [DataAtualizacao] DATETIME2(2)
        DEFAULT GETDATE(),
    CONSTRAINT [PK_DimDimCategoria]
        PRIMARY KEY CLUSTERED (SkCategoria)
) ON [PRIMARY]
WITH (DATA_COMPRESSION = PAGE);



-- DIMENSÃO Produtos
CREATE TABLE [Shared].[DimProdutos]
(
    [SkProduto] TINYINT NOT NULL,
    [IdProduto] UNIQUEIDENTIFIER NOT NULL,
    [Descricao] VARCHAR(250) NOT NULL,
    [Area] VARCHAR(50),
    [Ativo] BIT
        DEFAULT 1,
    [DataCarga] DATETIME2(2)
        DEFAULT GETDATE(),
    [DataAtualizacao] DATETIME2(2)
        DEFAULT GETDATE(),
    CONSTRAINT [PK_DimSistemas]
        PRIMARY KEY CLUSTERED ([SkProduto])
)
WITH (DATA_COMPRESSION = PAGE);

CREATE UNIQUE NONCLUSTERED INDEX IX_DimProdutosSkProduto
ON [Shared].[DimProdutos] ([IdProduto])
INCLUDE (
            [SkProduto],
            [Descricao]
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

-- DIMENSÃO CLIENTES
CREATE TABLE [Shared].[DimClientes]
(
    [SkCliente] SMALLINT NOT NULL IDENTITY(0, 1),
    [IdCliente] UNIQUEIDENTIFIER NOT NULL,
    [SkConselhoFederal] SMALLINT NOT NULL,
    [Nome] VARCHAR(100) NOT NULL,
    [Sigla] VARCHAR(50) NOT NULL,
    [Estado] CHAR(2),
    [TipoCliente] VARCHAR(20), -- Adicionado baseado na imagem 2
    [Ativo] BIT
        DEFAULT 1,
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

CREATE UNIQUE NONCLUSTERED INDEX IX_DimClientes_Sigla
ON [Shared].[DimClientes] (Sigla)
INCLUDE (
            SkCliente,
            IdCliente,
            Nome
        )
WITH (DATA_COMPRESSION = PAGE, FILLFACTOR = 95);

CREATE NONCLUSTERED INDEX IX_DimClientes_ConselhoFederal
ON [Shared].[DimClientes] (SkConselhoFederal)
WITH (DATA_COMPRESSION = PAGE);


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
    [DataKey] INT NOT NULL, -- YYYYMMDD
    [Data] DATE NOT NULL,
    [Ano] INT NOT NULL,
    [Mes] INT NOT NULL,
    [Trimestre] INT NOT NULL,
    [Semestre] INT NOT NULL,
    [NomeMes] VARCHAR(20) NOT NULL,
    [DiaSemana] INT NOT NULL,
    [NomeDiaSemana] VARCHAR(20) NOT NULL,
    CONSTRAINT [PK_DimTempo]
        PRIMARY KEY CLUSTERED ([DataKey])
)
WITH (DATA_COMPRESSION = PAGE);

CREATE UNIQUE NONCLUSTERED INDEX IX_DimTempo_Data
ON [Shared].[DimTempo] (data)
INCLUDE (
            DataKey,
            Ano,
            Mes
        )
WITH (DATA_COMPRESSION = PAGE, FILLFACTOR = 95);


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
        [Categoria] [VARCHAR](20) COLLATE SQL_Latin1_General_CP1_CI_AI NULL,
        [Descricao] [VARCHAR](60) COLLATE SQL_Latin1_General_CP1_CI_AI NULL,
        [Tipo] [VARCHAR](60) COLLATE SQL_Latin1_General_CP1_CI_AI NULL,
        [Situacao] [VARCHAR](9) COLLATE SQL_Latin1_General_CP1_CI_AI NULL,
        [Pagador] [VARCHAR](30) COLLATE SQL_Latin1_General_CP1_CI_AI NULL,
        [SiglaCliente] [VARCHAR](30) COLLATE SQL_Latin1_General_CP1_CI_AI NULL,
        [DataVigenciaInicial] [DATE] NULL,
        [DataVigenciaFinal] [DATE] NULL,
        [SituacaoFinanceira] [VARCHAR](30) COLLATE SQL_Latin1_General_CP1_CI_AI NULL,
        [QtdLicencas] [INT] NULL,
        [DataAtualizacao] [DATETIME2](2) NULL
    ) ON [PRIMARY];

END;


CREATE TABLE Shared.DimGeografia
(
 Estado CHAR(2) PRIMARY KEY,
 Regiao VARCHAR(30)

)
---- =============================================
---- TABELA FATO - CONTRATOS E PRODUTOS
---- =============================================

CREATE TABLE [DM_ContratosProdutos].[FatoContratosProdutos]
(
    -- Chaves Surrogate (Dimensões)
    [SkCliente] SMALLINT NOT NULL,
    [SkProduto] TINYINT NOT NULL,
    [SkTipoContrato] TINYINT NOT NULL,
    [SkTipoSituacaoContrato] TINYINT NOT NULL,
    [SkTiposSituacaoFinanceira] TINYINT NOT NULL,
    [SkDataVigenciaInicial] INT NOT NULL, -- Referência para DimTempo
    [SkDataVigenciaFinal] INT NOT NULL,   -- Referência para DimTempo

    -- Chave Natural (Deduplicação)
    [IdClienteProduto] UNIQUEIDENTIFIER NOT NULL,

    -- Métricas/Fatos
    [QtdLicencas] INT NOT NULL DEFAULT 0,
    [ValorContrato] DECIMAL(15,2) NULL,           -- Valor monetário do contrato
    [DiasVigencia] INT ,                 

    -- Campos de Auditoria
    [DataCarga] DATETIME2(2) DEFAULT GETDATE(),
    [DataUltimaAtualizacao] DATETIME2(2) DEFAULT GETDATE(),

    -- Chave Primária Composta
    CONSTRAINT [PK_FatoContratosProdutos] 
        PRIMARY KEY CLUSTERED ([IdClienteProduto]),

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
        FOREIGN KEY ([SkDataVigenciaInicial]) 
        REFERENCES [Shared].[DimTempo] ([DataKey]),

    CONSTRAINT [FK_FatoContratosProdutos_DataVigenciaFinal] 
        FOREIGN KEY ([SkDataVigenciaFinal]) 
        REFERENCES [Shared].[DimTempo] ([DataKey]),

    CONSTRAINT [FK_FatoContratosProdutos_DataAtualizacao] 
        FOREIGN KEY ([SkDataAtualizacao]) 
        REFERENCES [Shared].[DimTempo] ([DataKey])
)
WITH (DATA_COMPRESSION = PAGE);

-- =============================================
-- ÍNDICES PARA PERFORMANCE
-- =============================================

-- Índice para consultas por cliente e produto
CREATE NONCLUSTERED INDEX IX_FatoContratosProdutos_Cliente_Produto
ON [DM_ContratosProdutos].[FatoContratosProdutos] ([SkCliente], [SkProduto])
INCLUDE ([QtdLicencas], [ValorContrato], [DiasVigencia])
WITH (DATA_COMPRESSION = PAGE, FILLFACTOR = 95);

-- Índice para consultas por período de vigência
CREATE NONCLUSTERED INDEX IX_FatoContratosProdutos_PeriodoVigencia
ON [DM_ContratosProdutos].[FatoContratosProdutos] ([SkDataVigenciaInicial], [SkDataVigenciaFinal])
INCLUDE ([SkCliente], [SkProduto], [QtdLicencas])
WITH (DATA_COMPRESSION = PAGE, FILLFACTOR = 95);

-- Índice para consultas por situação do contrato
CREATE NONCLUSTERED INDEX IX_FatoContratosProdutos_SituacaoContrato
ON [DM_ContratosProdutos].[FatoContratosProdutos] ([SkTipoSituacaoContrato], [SkTiposSituacaoFinanceira])
INCLUDE ([SkCliente], [QtdLicencas], [ValorContrato])
WITH (DATA_COMPRESSION = PAGE, FILLFACTOR = 95);

-- Índice para consultas por data de atualização (útil para ETL incremental)
CREATE NONCLUSTERED INDEX IX_FatoContratosProdutos_DataAtualizacao
ON [DM_ContratosProdutos].[FatoContratosProdutos] ([SkDataAtualizacao])
WITH (DATA_COMPRESSION = PAGE, FILLFACTOR = 95);

