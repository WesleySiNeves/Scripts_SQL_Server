-- =============================================
-- MODELAGEM DATA WAREHOUSE - MÉTRICAS CONSOLIDADAS
-- Otimizada para Azure SQL Database (DTU)
-- =============================================

-- Criar schemas se não existirem
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'Shared')
    EXEC('CREATE SCHEMA Shared');

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'DM_MetricasClientes')
    EXEC('CREATE SCHEMA DM_MetricasClientes');

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'Staging')
    EXEC('CREATE SCHEMA Staging');



-- DIMENSÃO MÉTRICAS (Corrigida)
CREATE TABLE [DM_MetricasClientes].[DimMetricas]
(
    [SkMetrica] SMALLINT NOT NULL IDENTITY(1, 1),
    [NomeMetrica] VARCHAR(100) NOT NULL,
    [TipoRetorno] VARCHAR(20) NOT NULL,
    [TabelaConsultada] VARCHAR(100),
    [Descricao] VARCHAR(255),
    [Categoria] VARCHAR(50), -- Para agrupar métricas similares
    [Ativo] BIT NOT NULL DEFAULT 1,
    [DataCarga] DATETIME2(2) DEFAULT GETDATE(),
    [DataAtualizacao] DATETIME2(2) DEFAULT GETDATE(),
    CONSTRAINT [PK_DimMetricas] PRIMARY KEY CLUSTERED ([SkMetrica])
)
WITH (DATA_COMPRESSION = PAGE);

CREATE UNIQUE NONCLUSTERED INDEX IX_DimMetricas_Nome ON 
[DM_MetricasClientes].[DimMetricas](NomeMetrica) 
INCLUDE([SkMetrica], [TipoRetorno])
WITH (DATA_COMPRESSION = PAGE, FILLFACTOR = 95);

-- =============================================
-- TABELA FATO PRINCIPAL
-- =============================================

CREATE TABLE [DM_MetricasClientes].[FatoMetricas] 
(
    [SkCliente] SMALLINT NOT NULL,
    [DataKey] INT NOT NULL,
    [SkMetrica] SMALLINT NOT NULL,
    [SkSistema] TINYINT NOT NULL,
    [Valor] DECIMAL(18,4) NULL,
    [ValorTexto] VARCHAR(100) NULL,
    [ValorData] DATETIME2(2) NULL, -- Para métricas do tipo DATETIME
    [DataProcessamento] DATETIME2(2) NOT NULL DEFAULT GETDATE(),
    [HashOrigem] CHAR(32) NULL, -- MD5 para controle de duplicatas
    
    -- Chave primária composta otimizada
    CONSTRAINT [PK_FatoMetricas] PRIMARY KEY CLUSTERED ([SkCliente], [DataKey], [SkMetrica], [SkSistema]),
    
    -- Foreign Keys
    CONSTRAINT [FK_FatoMetricas_Cliente] FOREIGN KEY ([SkCliente]) 
        REFERENCES [Shared].[DimClientes]([SkCliente]),
    CONSTRAINT [FK_FatoMetricas_Data] FOREIGN KEY ([DataKey]) 
        REFERENCES [Shared].[DimTempo]([DataKey]),
    CONSTRAINT [FK_FatoMetricas_Metrica] FOREIGN KEY ([SkMetrica]) 
        REFERENCES [DM_MetricasClientes].[DimMetricas]([SkMetrica]),
    CONSTRAINT [FK_FatoMetricas_Sistema] FOREIGN KEY ([SkSistema]) 
        REFERENCES [Shared].[DimSistemas]([SkSistema])
)
WITH (DATA_COMPRESSION = PAGE);

-- Índices otimizados para consultas analíticas
CREATE NONCLUSTERED INDEX IX_FatoMetricas_DataMetrica ON 
[DM_MetricasClientes].[FatoMetricas](DataKey, SkMetrica) 
INCLUDE(SkCliente, Valor, ValorTexto)
WITH (DATA_COMPRESSION = PAGE);

CREATE NONCLUSTERED INDEX IX_FatoMetricas_ClienteData ON 
[DM_MetricasClientes].[FatoMetricas](SkCliente, DataKey) 
INCLUDE(SkMetrica, Valor)
WITH (DATA_COMPRESSION = PAGE);

-- =============================================
-- TABELAS DE CONTROLE E AUDITORIA
-- =============================================

-- LOG DE EXECUÇÃO MELHORADO
CREATE TABLE [DM_MetricasClientes].[LogExecucaoMetricas] 
(
    [LogId] BIGINT IDENTITY(1,1) NOT NULL,
    [SkCliente] SMALLINT NOT NULL,
    [DataExecucao] DATETIME2(2) NOT NULL,
    [DataInicio] DATETIME2(2) NOT NULL,
    [DataFim] DATETIME2(2) NULL,
    [QtdRegistrosProcessados] INT DEFAULT 0,
    [QtdRegistrosInseridos] INT DEFAULT 0,
    [QtdRegistrosAtualizados] INT DEFAULT 0,
    [QtdRegistrosErro] INT DEFAULT 0,
    [TempoExecucaoSegundos] INT NULL,
    [Status] VARCHAR(20) NOT NULL, -- 'Iniciado', 'Sucesso', 'Erro', 'Cancelado'
    [MensagemErro] VARCHAR(MAX) NULL,
    [VersaoPipeline] VARCHAR(20) NULL,
    [DataCarga] DATETIME2(2) DEFAULT GETDATE(),
    CONSTRAINT [PK_LogExecucaoMetricas] PRIMARY KEY CLUSTERED ([LogId]),
    CONSTRAINT [FK_LogExecucao_Cliente] FOREIGN KEY ([SkCliente]) 
        REFERENCES [Shared].[DimClientes]([SkCliente])
)
WITH (DATA_COMPRESSION = PAGE);

CREATE NONCLUSTERED INDEX IX_LogExecucao_ClienteData ON 
[DM_MetricasClientes].[LogExecucaoMetricas](SkCliente, DataExecucao, Status)
WITH (DATA_COMPRESSION = PAGE);

-- =============================================
-- SCHEMA STAGING
-- =============================================


-- TABELA DE STAGING OTIMIZADA
CREATE TABLE [Staging].[StagingMetricas]
(
    [Id] BIGINT IDENTITY(1, 1) NOT NULL,
    [ClienteSigla] VARCHAR(50) NOT NULL,
    [IdSistema] INT NOT NULL,
	Ordem TINYINT NOT NULL, --1 para principal  --2 para metricas detalhes
    [NomeMetrica] VARCHAR(100) NOT NULL,
    [TipoRetorno] VARCHAR(20) NOT NULL,
    [TabelaConsultada] VARCHAR(120) NULL,
    [Valor] VARCHAR(100) NULL,
    [DataRegistro] DATETIME2(2) NOT NULL ,
	[DataCarga] DATETIME2(2) NOT NULL  DEFAULT GETDATE(),
    [DataProcessamento] DATETIME2(2) DEFAULT GETDATE(),
    [ProcessadoFlag] BIT DEFAULT 0,
    [ErroProcessamento] VARCHAR(500) NULL,
    CONSTRAINT [PK_StagingMetricas] PRIMARY KEY CLUSTERED ([Id])
)
WITH (DATA_COMPRESSION = PAGE);

CREATE NONCLUSTERED INDEX IX_StagingMetricas_Processamento ON 
[Staging].[StagingMetricas](ProcessadoFlag, DataProcessamento)
INCLUDE(ClienteSigla, NomeMetrica)
WITH (DATA_COMPRESSION = PAGE);

