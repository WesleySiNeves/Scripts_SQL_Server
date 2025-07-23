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


DROP TABLE IF EXISTS [DM_MetricasClientes].[FatoMetricasClientes];
DROP TABLE IF EXISTS [DM_MetricasClientes].[DimTabelasConsultadas]
DROP TABLE IF EXISTS [DM_MetricasClientes].[DimMetricas];



IF(NOT EXISTS(SELECT * FROM  sys.tables WHERE name ='MetricasClientes'))
BEGIN
	CREATE TABLE [Staging].[MetricasClientes]
    (
        [Cliente]           [VARCHAR](50)  COLLATE SQL_Latin1_General_CP1_CI_AI NOT NULL,
        [CodSistema]        SMALLINT      NOT NULL,
        [Ordem]             [TINYINT]      NOT NULL,
        [NomeMetrica]       [VARCHAR](50)  COLLATE SQL_Latin1_General_CP1_CI_AI NOT NULL,
        [TipoRetorno]       [VARCHAR](50)  COLLATE SQL_Latin1_General_CP1_CI_AI NOT NULL,
        [TabelaConsultada]  [VARCHAR](128) COLLATE SQL_Latin1_General_CP1_CI_AI NULL,
        [Valor]             [VARCHAR](MAX) COLLATE SQL_Latin1_General_CP1_CI_AI NOT NULL DEFAULT (''),
        [DataCarga]         [DATETIME2](2) NOT NULL
            DEFAULT (GETDATE()),
        [DataProcessamento] [DATETIME2](2)  NULL ,
    --CONSTRAINT PK_MetricasClientes PRIMARY KEY(Cliente,CodSistema,Ordem,NomeMetrica,Valor)

    ) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
WITH (DATA_COMPRESSION = PAGE);


END





-- =============================================
-- DIMENSÕES TEMPORAIS - MÉTRICAS CLIENTES
-- Implementação SCD Tipo 2 para versionamento
-- =============================================

-- Dimensão Métrica (Temporal)
CREATE TABLE [DM_MetricasClientes].[DimMetricas]
    (
        [SkMetrica]        SMALLINT          IDENTITY(1, 1) NOT NULL,
        [NomeMetrica]      VARCHAR(50)  NOT NULL, -- Chave natural
        [TipoRetorno]      VARCHAR(20),
        [Categoria]        VARCHAR(50),
        [Descricao]        VARCHAR(255),
        [Ativo]            BIT DEFAULT 1,

                                                  -- Campos de versionamento temporal (SCD Tipo 2)
        [DataInicioVersao] DATETIME2(2) NOT NULL
            DEFAULT GETDATE(),
        [DataFimVersao]    DATETIME2(2) NULL,
        [VersaoAtual]      BIT          NOT NULL DEFAULT 1,

                                                  -- Auditoria
        [DataCarga]        DATETIME2(2)
            DEFAULT GETDATE(),
        [DataAtualizacao]  DATETIME2(2) NULL ,
        CONSTRAINT [PK_DimMetricas]
            PRIMARY KEY CLUSTERED ([SkMetrica])
    ) ON [PRIMARY]
WITH (DATA_COMPRESSION = PAGE);

-- Dimensão Tipo Retorno (Simples - sem versionamento)
CREATE TABLE [DM_MetricasClientes].[DimTabelasConsultadas]
    (
        [SkTabelasConsultada]   SMALLINT     IDENTITY(1, 1) NOT NULL,
        [Nome]     VARCHAR(128) NOT NULL,
        [Ativo]           BIT DEFAULT 1,
        [DataCarga]       DATETIME2(2) DEFAULT GETDATE(), 
	    [DataAtualizacao] DATETIME2(2) DEFAULT GETDATE(),
        CONSTRAINT [PK_DimTipoRetorno]
            PRIMARY KEY CLUSTERED ([SkTabelasConsultada])
    ) ON [PRIMARY]
WITH (DATA_COMPRESSION = PAGE);


-- =============================================
-- TABELA FATO - MÉTRICAS TEMPORAIS
-- Snapshot temporal das métricas por período
-- =============================================


CREATE TABLE [DM_MetricasClientes].[FatoMetricasClientes]
    (
		[SkTempo]                 [DATE]           NOT NULL,
        [SkCliente]               [SMALLINT]       NOT NULL,
        [SkProduto]               [SMALLINT]       NOT NULL,
        [SkMetrica]               [SMALLINT]       NOT NULL,
        [SkDimTabelasConsultadas] [SMALLINT]       NOT NULL,
        [Ordem]                   [TINYINT]        NOT NULL,
        [ValorTexto]              [VARCHAR](MAX)   COLLATE SQL_Latin1_General_CP1_CI_AI NULL,
        [ValorNumerico]           [DECIMAL](10, 2) NULL,
        [ValorData]               [DATETIME2](2)   NULL,
        [ValorBooleano]           [BIT]            NULL,
        [VersaoCliente]           [TINYINT]        NOT NULL,
        [VersaoSistema]           [TINYINT]        NOT NULL,
        [VersaoMetrica]           [TINYINT]        NOT NULL,
        [DataProcessamento]       [DATETIME2](2)   NOT NULL,
        [DataCarga]               [DATETIME2](2)   NULL CONSTRAINT [DF_FatoMetricasClienteDataCarga] DEFAULT (GETDATE()),
        [DataAtualizacao]         [DATETIME2](2)   NULL CONSTRAINT [DF_FatoMetricasClienteDataAtualizacao]  DEFAULT (GETDATE()),
        [CodContrato]             [VARCHAR](20)    COLLATE SQL_Latin1_General_CP1_CI_AI NULL
    ) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
WITH (DATA_COMPRESSION = PAGE);
GO
ALTER TABLE [DM_MetricasClientes].[FatoMetricasClientes]
ADD
    CONSTRAINT [PK_FatoMetricasClientes]
    PRIMARY KEY CLUSTERED ([SkCliente], [SkProduto], [SkMetrica], [SkDimTabelasConsultadas],SkTempo)
    WITH (DATA_COMPRESSION = PAGE) ON [PRIMARY];
GO
ALTER TABLE [DM_MetricasClientes].[FatoMetricasClientes]
ADD
    CONSTRAINT [FK_FatoMetricas_Cliente]
    FOREIGN KEY ([SkCliente])
    REFERENCES [Shared].[DimClientes] ([SkCliente]);
GO
ALTER TABLE [DM_MetricasClientes].[FatoMetricasClientes]
ADD
    CONSTRAINT [FK_FatoMetricas_DimTabelasConsultadas]
    FOREIGN KEY ([SkDimTabelasConsultadas])
    REFERENCES [DM_MetricasClientes].[DimTabelasConsultadas] ([SkTabelasConsultada]);
GO
ALTER TABLE [DM_MetricasClientes].[FatoMetricasClientes]
ADD
    CONSTRAINT [FK_FatoMetricas_Metrica]
    FOREIGN KEY ([SkMetrica])
    REFERENCES [DM_MetricasClientes].[DimMetricas] ([SkMetrica]);
GO
ALTER TABLE [DM_MetricasClientes].[FatoMetricasClientes]
ADD
    CONSTRAINT [FK_FatoMetricas_Sistema]
    FOREIGN KEY ([SkProduto])
    REFERENCES [Shared].[DimProdutos] ([SkProduto]);
GO
ALTER TABLE [DM_MetricasClientes].[FatoMetricasClientes]
ADD
    CONSTRAINT [FK_FatoMetricas_Tempo]
    FOREIGN KEY ([SkTempo])
    REFERENCES [Shared].[DimTempo] ([Data]);
GO
