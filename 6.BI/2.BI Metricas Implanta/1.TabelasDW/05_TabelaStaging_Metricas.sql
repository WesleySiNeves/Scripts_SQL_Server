
CREATE TABLE [Staging].[MetricasClientes]
    (
        [Cliente]           [VARCHAR](20)  COLLATE SQL_Latin1_General_CP1_CI_AI NOT NULL,
        [CodSistema]        [TINYINT]      NOT NULL,
        [Ordem]             [TINYINT]      NOT NULL,
        [NomeMetrica]       [VARCHAR](50)  COLLATE SQL_Latin1_General_CP1_CI_AI NOT NULL,
        [TipoRetorno]       [VARCHAR](20)  COLLATE SQL_Latin1_General_CP1_CI_AI NOT NULL,
        [TabelaConsultada]  [VARCHAR](128) COLLATE SQL_Latin1_General_CP1_CI_AI NULL,
        [Valor]             [VARCHAR](MAX) COLLATE SQL_Latin1_General_CP1_CI_AI NULL,
        [DataCarga]         [DATETIME2](2) NULL,
        [DataProcessamento] [DATETIME2](2) NULL
    ) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
WITH (DATA_COMPRESSION = PAGE);
GO
