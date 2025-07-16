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
            name = 'DM_MetricasClientes'
    )
    EXEC ('CREATE SCHEMA DM_MetricasClientes');

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

DROP TABLE IF EXISTS [Staging].[MetricasClientes];
DROP TABLE IF EXISTS  [DM_MetricasClientes].[FatoMetricasClientes]
DROP TABLE IF EXISTS [DM_MetricasClientes].[DimTipoRetorno]
DROP TABLE IF EXISTS [DM_MetricasClientes].[DimMetricas]


CREATE TABLE [Staging].[MetricasClientes]
    (
        [Cliente]           [VARCHAR](50)  COLLATE SQL_Latin1_General_CP1_CI_AI NOT NULL,
        [CodSistema]        [TINYINT]      NOT NULL,
        [Ordem]             [TINYINT]      NOT NULL,
        [NomeMetrica]       [VARCHAR](50)  COLLATE SQL_Latin1_General_CP1_CI_AI NOT NULL,
        [TipoRetorno]       [VARCHAR](50)  COLLATE SQL_Latin1_General_CP1_CI_AI NOT NULL,
        [TabelaConsultada]  [VARCHAR](128) COLLATE SQL_Latin1_General_CP1_CI_AI NULL,
        [Valor]             [VARCHAR](MAX) COLLATE SQL_Latin1_General_CP1_CI_AI NOT NULL DEFAULT(''),
        [DataCarga]         [DATETIME2](2) NOT NULL DEFAULT(GETDATE()),
        [DataProcessamento] [DATETIME2](2) NOT NULL DEFAULT (GETDATE()),
		--CONSTRAINT PK_MetricasClientes PRIMARY KEY(Cliente,CodSistema,Ordem,NomeMetrica,Valor)
		 
    ) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
WITH (DATA_COMPRESSION = PAGE);
GO


-- =============================================
-- DIMENSÕES TEMPORAIS - MÉTRICAS CLIENTES
-- Implementação SCD Tipo 2 para versionamento
-- =============================================

-- Dimensão Métrica (Temporal)
CREATE TABLE [DM_MetricasClientes].[DimMetricas]
    (
        [SkMetrica]        INT          IDENTITY(1, 1) NOT NULL,
        [NomeMetrica]      VARCHAR(50)  NOT NULL, -- Chave natural
        [TipoRetorno]      VARCHAR(20),
        [TabelaConsultada] VARCHAR(128),
        [Categoria]        VARCHAR(50),
        [Descricao]        VARCHAR(255),
        [Ativo]            BIT
            DEFAULT 1,

                                                  -- Campos de versionamento temporal (SCD Tipo 2)
        [DataInicioVersao] DATETIME2(2) NOT NULL
            DEFAULT GETDATE(),
        [DataFimVersao]    DATETIME2(2) NULL,
        [VersaoAtual]      BIT          NOT NULL
            DEFAULT 1,

                                                  -- Auditoria
        [DataCarga]        DATETIME2(2)
            DEFAULT GETDATE(),
        [DataAtualizacao]  DATETIME2(2)
            DEFAULT GETDATE(),
        CONSTRAINT [PK_DimMetricas]
            PRIMARY KEY CLUSTERED ([SkMetrica])
    ) ON [PRIMARY]
WITH (DATA_COMPRESSION = PAGE);

-- Dimensão Tipo Retorno (Simples - sem versionamento)
CREATE TABLE [DM_MetricasClientes].[DimTipoRetorno]
    (
        [SkTipoRetorno]   TINYINT     IDENTITY(1, 1) NOT NULL,
        [TipoRetorno]     VARCHAR(20) NOT NULL,
        [Descricao]       VARCHAR(100),
        [Ativo]           BIT
            DEFAULT 1,
        [DataCarga]       DATETIME2(2)
            DEFAULT GETDATE(),
        [DataAtualizacao] DATETIME2(2)
            DEFAULT GETDATE(),
        CONSTRAINT [PK_DimTipoRetorno]
            PRIMARY KEY CLUSTERED ([SkTipoRetorno])
    ) ON [PRIMARY]
WITH (DATA_COMPRESSION = PAGE);


-- =============================================
-- TABELA FATO - MÉTRICAS TEMPORAIS
-- Snapshot temporal das métricas por período
-- =============================================

CREATE TABLE [DM_MetricasClientes].[FatoMetricasClientes]
    (
        -- Chaves Surrogate (Dimensões)
        [SkCliente]         INT           NOT NULL,
        [SkSistema]         INT           NOT NULL,
        [SkMetrica]         INT           NOT NULL,
        [SkTipoRetorno]     TINYINT       NOT NULL,
        [SkTempo]           DATE          NOT NULL, -- Referência para DimTempo compartilhada

                                                    -- Chaves de Negócio (para rastreabilidade)
        [CodigoCliente]     VARCHAR(20)   NOT NULL,
        [CodSistema]        TINYINT       NOT NULL,
        [NomeMetrica]       VARCHAR(50)   NOT NULL,
        [Ordem]             TINYINT       NOT NULL,

                                                    -- Métricas/Fatos
        [ValorTexto]        VARCHAR(MAX),           -- Para métricas de texto
        [ValorNumerico]     DECIMAL(18, 4),         -- Para métricas numéricas
        [ValorData]         DATETIME2(2),           -- Para métricas de data
        [ValorBooleano]     BIT,                    -- Para métricas booleanas

                                                    -- Metadados temporais
        [DataSnapshot]      DATE          NOT NULL, -- Data do snapshot
        [DataProcessamento] DATETIME2(2)  NOT NULL, -- Quando foi processado
        [VersaoCliente]     INT           NOT NULL, -- Versão do cliente na época
        [VersaoSistema]     INT           NOT NULL, -- Versão do sistema na época
        [VersaoMetrica]     INT           NOT NULL, -- Versão da métrica na época

                                                    -- Auditoria
        [DataCarga]         DATETIME2(2)
            DEFAULT GETDATE(),
        [DataAtualizacao]   DATETIME2(2)
            DEFAULT GETDATE(),

                                                    -- Chave Primária Composta (inclui data para particionamento temporal)
        CONSTRAINT [PK_FatoMetricasClientes]
            PRIMARY KEY CLUSTERED ([SkCliente], [SkSistema], [SkMetrica], [DataSnapshot]),

                                                    -- Chaves Estrangeiras
        CONSTRAINT [FK_FatoMetricas_Cliente]
            FOREIGN KEY ([SkCliente])
            REFERENCES [Shared].[DimClientes] ([SkCliente]),
        CONSTRAINT [FK_FatoMetricas_Sistema]
            FOREIGN KEY ([SkSistema])
            REFERENCES [Shared].[DimProdutos] ([SkProduto]),
        CONSTRAINT [FK_FatoMetricas_Metrica]
            FOREIGN KEY ([SkMetrica])
            REFERENCES [DM_MetricasClientes].[DimMetricas] ([SkMetrica]),
        CONSTRAINT [FK_FatoMetricas_TipoRetorno]
            FOREIGN KEY ([SkTipoRetorno])
            REFERENCES [DM_MetricasClientes].[DimTipoRetorno] ([SkTipoRetorno]),
        CONSTRAINT [FK_FatoMetricas_Tempo]
            FOREIGN KEY ([SkTempo])
            REFERENCES [Shared].[DimTempo] ([Data])
    ) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
WITH (DATA_COMPRESSION = PAGE);

-- Índices para performance
CREATE NONCLUSTERED INDEX [IX_FatoMetricas_DataSnapshot]
    ON [DM_MetricasClientes].[FatoMetricasClientes] ([DataSnapshot])
    INCLUDE ([SkCliente], [SkSistema], [SkMetrica]);

CREATE NONCLUSTERED INDEX [IX_FatoMetricas_Cliente_Data]
    ON [DM_MetricasClientes].[FatoMetricasClientes] ([SkCliente], [DataSnapshot]);