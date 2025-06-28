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

-- Limpeza das tabelas existentes


DROP TABLE IF EXISTS [DM_MetricasClientes].[FatoMetricas];
DROP TABLE IF EXISTS [DM_MetricasClientes].[DimMetricas];
DROP TABLE IF EXISTS [Staging].[StagingMetricas];


DROP TABLE IF EXISTS [Shared].[DimSistemas];
DROP TABLE IF EXISTS [Shared].[DimCategorias];
DROP TABLE IF EXISTS [Shared].[DimClientes];
DROP TABLE IF EXISTS [Shared].[DimConselhosFederais];

DROP TABLE IF EXISTS [Shared].[DimTempo];



DROP TABLE IF EXISTS [DM_MetricasClientes].[LogExecucaoMetricas];



--DM_MetricasClientes
-- =============================================
-- TABELAS DIMENSÃO
-- =============================================

-- DIMENSÃO CONSELHOS FEDERAIS
CREATE TABLE [Shared].[DimConselhosFederais]
(
    [SkConselhoFederal] SMALLINT NOT NULL IDENTITY(0, 1),
    [IdConselhoFederal] [UNIQUEIDENTIFIER] NOT NULL,
    [NomeRazaoSocial] [VARCHAR](250) COLLATE SQL_Latin1_General_CP1_CI_AI NOT NULL,
    [Sigla] [VARCHAR](50) COLLATE SQL_Latin1_General_CP1_CI_AI NOT NULL,
    [Ativo] BIT DEFAULT 1,
	Categoria VARCHAR(30) ,
    [DataCarga] DATETIME2(2) DEFAULT GETDATE(),
    [DataAtualizacao] DATETIME2(2) DEFAULT GETDATE(),
    CONSTRAINT [PK_DimConselhosFederais] PRIMARY KEY CLUSTERED ([SkConselhoFederal])
) ON [PRIMARY]
WITH (DATA_COMPRESSION = PAGE);

CREATE UNIQUE NONCLUSTERED INDEX IX_DimConselhosFederais_Id ON 
[Shared].[DimConselhosFederais](IdConselhoFederal) 
INCLUDE([SkConselhoFederal], [Sigla])
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
    [Ativo] BIT DEFAULT 1,
    [DataCarga] DATETIME2(2) DEFAULT GETDATE(),
    [DataAtualizacao] DATETIME2(2) DEFAULT GETDATE(),
    CONSTRAINT [PK_DimClientes] PRIMARY KEY CLUSTERED ([SkCliente]),
    CONSTRAINT [FK_DimClientes_ConselhoFederal] FOREIGN KEY ([SkConselhoFederal]) 
        REFERENCES [Shared].[DimConselhosFederais]([SkConselhoFederal])
)
WITH (DATA_COMPRESSION = PAGE);

CREATE UNIQUE NONCLUSTERED INDEX IX_DimClientes_Sigla ON 
[Shared].[DimClientes](Sigla) 
INCLUDE(SkCliente, IdCliente, Nome)
WITH (DATA_COMPRESSION = PAGE, FILLFACTOR = 95);

CREATE NONCLUSTERED INDEX IX_DimClientes_ConselhoFederal ON 
[Shared].[DimClientes](SkConselhoFederal)
WITH (DATA_COMPRESSION = PAGE);

-- DIMENSÃO SISTEMAS
CREATE TABLE [Shared].[DimSistemas]
(
    [SkSistema] TINYINT NOT NULL IDENTITY(0, 1),
    [IdSistema] INT NOT NULL,
    [Descricao] VARCHAR(250) NOT NULL,
    [Area] VARCHAR(50),
    [Ativo] BIT DEFAULT 1,
    [DataCarga] DATETIME2(2) DEFAULT GETDATE(),
    [DataAtualizacao] DATETIME2(2) DEFAULT GETDATE(),
    CONSTRAINT [PK_DimSistemas] PRIMARY KEY CLUSTERED ([SkSistema])
)
WITH (DATA_COMPRESSION = PAGE);

CREATE UNIQUE NONCLUSTERED INDEX IX_DimSistemas_Id ON 
[Shared].[DimSistemas](IdSistema) 
INCLUDE([SkSistema], [Descricao])
WITH (DATA_COMPRESSION = PAGE, FILLFACTOR = 95);

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
    CONSTRAINT [PK_DimTempo] PRIMARY KEY CLUSTERED ([DataKey])
) 
WITH (DATA_COMPRESSION = PAGE);

CREATE UNIQUE NONCLUSTERED INDEX IX_DimTempo_Data ON 
[Shared].[DimTempo](Data) 
INCLUDE(DataKey, Ano, Mes)
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

