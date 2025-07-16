

-- =============================================
-- MODELAGEM DATA WAREHOUSE - MÉTRICAS CONSOLIDADAS
-- Otimizada para Azure SQL Database (DTU)
-- =============================================



-- Criar schemas se não existirem
IF NOT EXISTS
    (
        SELECT
            *
        FROM
            sys.schemas
        WHERE
            name = 'Shared'
    )
    EXEC ('CREATE SCHEMA Shared');


IF NOT EXISTS
    (
        SELECT
            *
        FROM
            sys.schemas
        WHERE
            name = 'Staging'
    )
    EXEC ('CREATE SCHEMA Staging');

IF NOT EXISTS
    (
        SELECT
            *
        FROM
            sys.schemas
        WHERE
            name = 'DM_ContratosProdutos'
    )
    EXEC ('CREATE SCHEMA DM_ContratosProdutos');


-- Limpeza das tabelas existentes

DROP TABLE IF EXISTS [DM_ContratosProdutos].[FatoContratosProdutos];
DROP TABLE IF EXISTS [Shared].[DimSistemas];
DROP TABLE IF EXISTS [Shared].[DimCategorias];
DROP TABLE IF EXISTS [Shared].[DimClientes];
DROP TABLE IF EXISTS [Shared].DimProdutos;
DROP TABLE IF EXISTS [Shared].DimGeografia;
DROP TABLE IF EXISTS [Shared].[DimConselhosFederais];
DROP TABLE IF EXISTS [Shared].[DimTempo];
DROP TABLE IF EXISTS DM_MetricasProdutos.DimTipoRetornoMetrica;
DROP TABLE IF EXISTS DM_MetricasProdutos.DimMetricasProdutos;
DROP TABLE IF EXISTS Staging.MetricasClientes;
DROP TABLE IF EXISTS [DM_ContratosProdutos].[DimTipoContratos];
DROP TABLE IF EXISTS [DM_ContratosProdutos].[DimTipoSituacaoContratos];
DROP TABLE IF EXISTS [DM_ContratosProdutos].[DimTiposSituacaoFinanceira];
DROP TABLE IF EXISTS DM_MetricasProdutos.DimTipoRetornoMetrica;
DROP TABLE IF EXISTS Staging.ClientesProdutosCIGAM;


--DM_MetricasClientes
-- =============================================
-- TABELAS DIMENSÃO
-- =============================================

CREATE TABLE [Shared].[DimCategorias]
    (
        SkCategoria       SMALLINT     NOT NULL,
        Nome              VARCHAR(100) NOT NULL,
        [Ativo]           BIT
            DEFAULT 1,
        [DataCarga]       DATETIME2(2)
            DEFAULT GETDATE(),
        [DataAtualizacao] DATETIME2(2)
            DEFAULT GETDATE(),
        CONSTRAINT [PK_DimDimCategoria]
            PRIMARY KEY CLUSTERED (SkCategoria)
    ) ON [PRIMARY]
WITH (DATA_COMPRESSION = PAGE);



-- DIMENSÃO PRODUTOS (TEMPORAL - SCD TIPO 2)
CREATE TABLE [Shared].[DimProdutos]
    (
        [SkProduto]         INT              NOT NULL IDENTITY(1, 1),  -- Alterado de TINYINT para INT
        [IdProduto]         UNIQUEIDENTIFIER NOT NULL,                  -- Chave natural
        [DescricaoCigam]    VARCHAR(250)     NOT NULL,
        [DescricaoImplanta] VARCHAR(250)     NOT NULL,
        [Area]              VARCHAR(50),
        [Ativo]             BIT
            DEFAULT 1,
        
        -- Campos de versionamento temporal (SCD Tipo 2)
        [DataInicioVersao]  DATETIME2(2)     NOT NULL DEFAULT GETDATE(),
        [DataFimVersao]     DATETIME2(2)     NULL,           -- NULL = versão atual
        [VersaoAtual]       BIT              NOT NULL DEFAULT 1,      -- 1 = versão atual, 0 = histórica
        
        -- Auditoria
        [DataCarga]         DATETIME2(2)
            DEFAULT GETDATE(),
        [DataAtualizacao]   DATETIME2(2)
            DEFAULT GETDATE(),
        CONSTRAINT [PK_DimProdutos]  -- Corrigido nome da constraint
            PRIMARY KEY CLUSTERED ([SkProduto])
    )
WITH (DATA_COMPRESSION = PAGE);

-- Índice para busca por chave natural e versão atual
CREATE NONCLUSTERED INDEX [IX_DimProdutos_IdProduto_VersaoAtual] 
    ON [Shared].[DimProdutos] ([IdProduto], [VersaoAtual])
    INCLUDE ([SkProduto], [DataInicioVersao], [DataFimVersao])
    WITH (DATA_COMPRESSION = PAGE, FILLFACTOR = 95);

CREATE UNIQUE NONCLUSTERED INDEX IX_DimProdutos_IdProduto_VersaoAtual_Unique
    ON [Shared].[DimProdutos] ([IdProduto], [VersaoAtual])
    INCLUDE ([SkProduto], [DescricaoImplanta], [DescricaoCigam])
    WHERE [VersaoAtual] = 1
    WITH (DATA_COMPRESSION = PAGE, FILLFACTOR = 95);

-- Índice para consultas históricas
CREATE NONCLUSTERED INDEX IX_DimProdutos_Historico
    ON [Shared].[DimProdutos] (DataInicioVersao, DataFimVersao)
    INCLUDE (SkProduto, IdProduto, DescricaoImplanta, DescricaoCigam)
    WITH (DATA_COMPRESSION = PAGE, FILLFACTOR = 95);

-- Índice para busca por descrição (versão atual)
CREATE NONCLUSTERED INDEX IX_DimProdutos_Descricao_VersaoAtual
    ON [Shared].[DimProdutos] ([DescricaoCigam], [VersaoAtual])
    INCLUDE ([SkProduto], [IdProduto])
    WITH (DATA_COMPRESSION = PAGE, FILLFACTOR = 95);




-- DIMENSÃO CONSELHOS FEDERAIS
CREATE TABLE [Shared].[DimConselhosFederais]
    (
        [SkConselhoFederal] SMALLINT           NOT NULL IDENTITY(0, 1),
        [IdConselhoFederal] [UNIQUEIDENTIFIER] NOT NULL,
        [NomeRazaoSocial]   [VARCHAR](250)     COLLATE SQL_Latin1_General_CP1_CI_AI NOT NULL,
        [Sigla]             [VARCHAR](50)      COLLATE SQL_Latin1_General_CP1_CI_AI NOT NULL,
        SkCategoria         SMALLINT           NOT NULL
            DEFAULT (0),
        [Ativo]             BIT
            DEFAULT 1,
        [DataCarga]         DATETIME2(2)
            DEFAULT GETDATE(),
        [DataAtualizacao]   DATETIME2(2)
            DEFAULT GETDATE(),
        CONSTRAINT [PK_DimConselhosFederais]
            PRIMARY KEY CLUSTERED ([SkConselhoFederal])
    ) ON [PRIMARY]
WITH (DATA_COMPRESSION = PAGE);

CREATE UNIQUE NONCLUSTERED INDEX IX_DimConselhosFederais_Id
    ON [Shared].[DimConselhosFederais] (IdConselhoFederal)
    INCLUDE ([SkConselhoFederal], [Sigla])
    WITH (DATA_COMPRESSION = PAGE, FILLFACTOR = 95);

-- DIMENSÃO CLIENTES (TEMPORAL - SCD TIPO 2)
CREATE TABLE [Shared].[DimClientes]
    (
        [SkCliente]         INT              NOT NULL IDENTITY(1, 1),
        [IdCliente]         UNIQUEIDENTIFIER NOT NULL,        -- Chave natural
        [SkConselhoFederal] SMALLINT         NOT NULL,
        [Nome]              VARCHAR(100)     NOT NULL,
        [Sigla]             VARCHAR(50)      NOT NULL,
        [Estado]            CHAR(2),
        [TipoCliente]       VARCHAR(20),
        [Ativo]             BIT
            DEFAULT 1,
        
        -- Campos de versionamento temporal (SCD Tipo 2)
        [DataInicioVersao]  DATETIME2(2)     NOT NULL DEFAULT GETDATE(),
        [DataFimVersao]     DATETIME2(2)     NULL,           -- NULL = versão atual
        [VersaoAtual]       BIT              NOT NULL DEFAULT 1,      -- 1 = versão atual, 0 = histórica
        
        -- Auditoria
        [DataCarga]         DATETIME2(2)
            DEFAULT GETDATE(),
        [DataAtualizacao]   DATETIME2(2)
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
    ON [Shared].[DimClientes] ([IdCliente], [VersaoAtual])
    INCLUDE ([SkCliente], [DataInicioVersao], [DataFimVersao])
    WITH (DATA_COMPRESSION = PAGE, FILLFACTOR = 95);

CREATE UNIQUE NONCLUSTERED INDEX IX_DimClientes_Sigla_VersaoAtual
    ON [Shared].[DimClientes] (Sigla, VersaoAtual)
    INCLUDE (SkCliente, IdCliente, Nome)
    WITH (DATA_COMPRESSION = PAGE, FILLFACTOR = 95);

CREATE NONCLUSTERED INDEX IX_DimClientes_ConselhoFederal
    ON [Shared].[DimClientes] (SkConselhoFederal)
    WITH (DATA_COMPRESSION = PAGE);

-- Índice para consultas históricas
CREATE NONCLUSTERED INDEX IX_DimClientes_Historico
    ON [Shared].[DimClientes] (DataInicioVersao, DataFimVersao)
    INCLUDE (SkCliente, IdCliente, Nome, Sigla)
    WITH (DATA_COMPRESSION = PAGE, FILLFACTOR = 95);


CREATE TABLE [DM_ContratosProdutos].[DimTipoContratos]
    (
        SkTipoContrato    TINYINT      NOT NULL IDENTITY(0, 1),
        Nome              VARCHAR(100) NOT NULL,
        [Ativo]           BIT
            DEFAULT 1,
        [DataCarga]       DATETIME2(2)
            DEFAULT GETDATE(),
        [DataAtualizacao] DATETIME2(2)
            DEFAULT GETDATE(),
        CONSTRAINT [PK_TipoContratos]
            PRIMARY KEY CLUSTERED (SkTipoContrato)
    ) ON [PRIMARY]
WITH (DATA_COMPRESSION = PAGE);

CREATE TABLE [DM_ContratosProdutos].[DimTipoSituacaoContratos]
    (
        SkTipoSituacaoContrato TINYINT      NOT NULL IDENTITY(0, 1),
        Nome                   VARCHAR(100) NOT NULL,
        [Ativo]                BIT
            DEFAULT 1,
        [DataCarga]            DATETIME2(2)
            DEFAULT GETDATE(),
        [DataAtualizacao]      DATETIME2(2)
            DEFAULT GETDATE(),
        CONSTRAINT [PK_TipoSituacaoContratos]
            PRIMARY KEY CLUSTERED (SkTipoSituacaoContrato)
    ) ON [PRIMARY]
WITH (DATA_COMPRESSION = PAGE);

CREATE TABLE [DM_ContratosProdutos].[DimTiposSituacaoFinanceira]
    (
        SkTiposSituacaoFinanceira TINYINT      NOT NULL IDENTITY(0, 1),
        Nome                      VARCHAR(100) NOT NULL,
        [Ativo]                   BIT
            DEFAULT 1,
        [DataCarga]               DATETIME2(2)
            DEFAULT GETDATE(),
        [DataAtualizacao]         DATETIME2(2)
            DEFAULT GETDATE(),
        CONSTRAINT [PK_TipoTiposSituacaoFinanceira]
            PRIMARY KEY CLUSTERED (SkTiposSituacaoFinanceira)
    ) ON [PRIMARY]
WITH (DATA_COMPRESSION = PAGE);

-- DIMENSÃO TEMPO
CREATE TABLE [Shared].[DimTempo]
    (
        [Data]          DATE        NOT NULL,
        [Ano]           INT         NOT NULL,
        [Mes]           INT         NOT NULL,
        [Trimestre]     INT         NOT NULL,
        [Semestre]      INT         NOT NULL,
        [NomeMes]       VARCHAR(20) NOT NULL,
        [DiaSemana]     INT         NOT NULL,
        [NomeDiaSemana] VARCHAR(20) NOT NULL,
        CONSTRAINT [PK_DimTempo]
            PRIMARY KEY CLUSTERED ([Data])
    )
WITH (DATA_COMPRESSION = PAGE)
   


-- =============================================
-- SCHEMA STAGING
-- =============================================

IF (NOT EXISTS
    (
        SELECT
            *
        FROM
            sys.tables
        WHERE
            name = 'ClientesProdutosCIGAM'
    )
   )
    BEGIN
	
        CREATE TABLE [Staging].[ClientesProdutosCIGAM]
            (
                [IdClienteProduto]    [UNIQUEIDENTIFIER] NOT NULL PRIMARY KEY,
                [UF]                  [VARCHAR](2)       COLLATE SQL_Latin1_General_CP1_CI_AI NULL,
                [CodContrato]         VARCHAR(10)        NOT NULL,
                [Categoria]           [VARCHAR](20)      COLLATE SQL_Latin1_General_CP1_CI_AI NULL,
                [Descricao]           [VARCHAR](60)      COLLATE SQL_Latin1_General_CP1_CI_AI NULL,
                [Tipo]                [VARCHAR](60)      COLLATE SQL_Latin1_General_CP1_CI_AI NULL,
                [Situacao]            [VARCHAR](9)       COLLATE SQL_Latin1_General_CP1_CI_AI NULL,
                [Pagador]             [VARCHAR](30)      COLLATE SQL_Latin1_General_CP1_CI_AI NULL,
                [SiglaCliente]        [VARCHAR](30)      COLLATE SQL_Latin1_General_CP1_CI_AI NULL,
                [DataVigenciaInicial] [DATE]             NULL,
                [DataVigenciaFinal]   [DATE]             NULL,
                [DataBase]            [DATE]             NULL,
                [Periodicidade]       VARCHAR(60)        NULL,
                PrecoUnitario         DECIMAL(10, 2)     NOT NULL,
                Quantidade            FLOAT            NOT NULL,
                ValorDesconto         DECIMAL(10, 2)     NOT NULL,
                ValorTotal            DECIMAL(10, 2)     NOT NULL,
                [SituacaoFinanceira]  [VARCHAR](30)      COLLATE SQL_Latin1_General_CP1_CI_AI NULL,
                [QtdLicencas]         [INT]              NULL,
                [DataAtualizacao]     [DATETIME2](2)     NULL
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
        [SkUF]                      CHAR(2)        NOT NULL,
		[CodContrato]               VARCHAR(10)    NOT NULL,
        [SkCategoria]               TINYINT        NOT NULL,
        [SkProduto]                 INT            NOT NULL,
        [SkTipoContrato]            TINYINT        NOT NULL,
        [SkTipoSituacaoContrato]    TINYINT        NOT NULL,
        [SkClientePagador]          INT            NOT NULL,
        [SkCliente]                 INT            NOT NULL,
        [DataVigenciaInicial]		DATE           NOT NULL,
        [DataVigenciaFinal]			DATE           NOT NULL,
        [SkTiposSituacaoFinanceira] TINYINT        NOT NULL,
        [Data_base]					DATE		   NOT NULL,
                                                         -- Métricas/Fatos
		[Periodicidade]       VARCHAR(60)           NOT NULL,
		PrecoUnitario DECIMAL(10,2)				    NOT NULL,
		Quantidade SMALLINT							NOT NULL,
		ValorDesconto DECIMAL(10,2)					NOT NULL,
		[ValorTotal]             DECIMAL(10, 2)		NOT NULL, -- Valor monetário do contrato
        [QtdLicencasCIGAM]			SMALLINT		 NOT NULL DEFAULT 0,
		QuantidadeDiasVigenciaFinal AS  DATEDIFF(DAY,GETDATE(),DataVigenciaFinal),
		[QtdDiasVigencia]   AS    DATEDIFF(DAY,DataVigenciaInicial,DataVigenciaFinal),
		Vencido  AS  IIF(DATEDIFF(DAY,DataVigenciaFinal,GETDATE()) > 0,'SIM','NÂO'),
		[DataCarga]                 DATETIME2(2)   NOT NULL,
        [DataUltimaAtualizacao]     DATETIME2(2)   NOT NULL DEFAULT GETDATE(),

                                                         -- Chave Primária Composta
        CONSTRAINT [PK_FatoContratosProdutos]
            PRIMARY KEY CLUSTERED ([SkUF], [SkCliente], [SkProduto], [DataVigenciaInicial], [DataVigenciaFinal]),

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
    ON [DM_ContratosProdutos].[FatoContratosProdutos] ([SkCliente], [SkProduto])
    INCLUDE ([QtdLicencasCIGAM], [ValorTotal])
    WITH (DATA_COMPRESSION = PAGE, FILLFACTOR = 95);

-- Índice para consultas por período de vigência
CREATE NONCLUSTERED INDEX IX_FatoContratosProdutos_PeriodoVigencia
    ON [DM_ContratosProdutos].[FatoContratosProdutos] ([DataVigenciaInicial], [DataVigenciaFinal])
    INCLUDE ([SkCliente], [SkProduto], [QtdLicencasCIGAM])
    WITH (DATA_COMPRESSION = PAGE, FILLFACTOR = 95);

-- Índice para consultas por situação do contrato
CREATE NONCLUSTERED INDEX IX_FatoContratosProdutos_SituacaoContrato
    ON [DM_ContratosProdutos].[FatoContratosProdutos] ([SkTipoSituacaoContrato], [SkTiposSituacaoFinanceira])
    INCLUDE ([SkCliente], [QtdLicencasCIGAM], [ValorTotal])
    WITH (DATA_COMPRESSION = PAGE, FILLFACTOR = 95);



