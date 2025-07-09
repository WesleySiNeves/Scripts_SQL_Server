-- =============================================
-- Tabela de Staging para Métricas Voláteis
-- =============================================

USE [HealthCheckDW]
GO

-- Criar schema de staging se não existir
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'Staging')
BEGIN
    EXEC('CREATE SCHEMA [Staging]')
END
GO

-- Tabela de staging para receber dados brutos das métricas
DROP TABLE IF EXISTS [Staging].[MetricasSistemas_Raw]
GO

CREATE TABLE [Staging].[MetricasSistemas_Raw] (
    -- Identificador único do lote de carga
    IdLote UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID(),
    
    -- Dados vindos da procedure (conforme sua imagem)
    Cliente VARCHAR(20) NOT NULL,
    CodSistema VARCHAR(50) NOT NULL,
    Ordem INT NOT NULL,
    NomeMetrica VARCHAR(100) NOT NULL,
    TipoRetorno VARCHAR(20) NOT NULL,
    TabelaConsultada VARCHAR(100) NULL,
    Valor VARCHAR(MAX) NULL,
    
    -- Controle de processamento
    DataHoraCarga DATETIME2 NOT NULL DEFAULT GETDATE(),
    StatusProcessamento VARCHAR(20) NOT NULL DEFAULT 'Pendente', -- Pendente, Processado, Erro
    MensagemErro VARCHAR(MAX) NULL,
    
    -- Metadados da execução
    UsuarioCarga VARCHAR(100) NOT NULL DEFAULT SYSTEM_USER,
    ServidorOrigem VARCHAR(100) NULL,
    VersaoProcedure VARCHAR(20) NULL,
    
    -- Índice clustered por lote e ordem para performance
    CONSTRAINT PK_MetricasSistemas_Raw PRIMARY KEY CLUSTERED (IdLote, Ordem)
)
GO

-- Índices para otimizar consultas
CREATE NONCLUSTERED INDEX IX_MetricasSistemas_Raw_Cliente 
    ON [Staging].[MetricasSistemas_Raw] (Cliente)
GO

CREATE NONCLUSTERED INDEX IX_MetricasSistemas_Raw_Status 
    ON [Staging].[MetricasSistemas_Raw] (StatusProcessamento, DataHoraCarga)
GO

CREATE NONCLUSTERED INDEX IX_MetricasSistemas_Raw_DataCarga 
    ON [Staging].[MetricasSistemas_Raw] (DataHoraCarga)
GO

PRINT '✓ Tabela de staging criada com sucesso!'
GO