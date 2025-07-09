
DROP TABLE IF EXISTS #DadosMetricas;

CREATE TABLE #DadosMetricas
(
    [Cliente] VARCHAR(20),
    [CodSistema] UNIQUEIDENTIFIER,
    [Ordem] TINYINT,
    [NomeMetrica] VARCHAR(50),
    [TipoRetorno] VARCHAR(20),
    [TabelaConsultada] VARCHAR(128),
    [Valor] VARCHAR(MAX),
    [DataAtualizacao] DATETIME2(2)
);

INSERT INTO #DadosMetricas
(
    [Cliente],
    [CodSistema],
    [Ordem],
    [NomeMetrica],
    [TipoRetorno],
    [TabelaConsultada],
    [Valor],
    [DataAtualizacao]
)
VALUES
('cro-sp', '{00000000-0000-0000-0000-000000000000}', 1, 'DataUltimoAcesso', 'DATETIME', 'acesso.sessoes', NULL,
 N'2025-07-08T17:52:40.34'),
('cro-sp', '{00000000-0000-0000-0000-000000000000}', 1, 'QtdAcessos', 'INT', 'acesso.sessoes', '0',
 N'2025-07-08T17:52:40.34'),
('cro-sp', '{00000000-0000-0000-0000-000000000000}', 1, 'QtdAcessosNoAno', 'INT', 'acesso.sessoes', '0',
 N'2025-07-08T17:52:40.34'),
('cro-sp', '{00000000-0000-0000-0000-000000000000}', 1, 'PossueLicenca', 'BIT', 'sistema.configuracoes', '0',
 N'2025-07-08T17:52:40.34'),
('cro-sp', '{00000000-0000-0000-0000-000000000000}', 1, 'QuantidadeArquivosAnexos', 'INT', 'Todas as Tabelas',
 '318313', N'2025-07-08T17:52:48.07'),
('cro-sp', '{00000000-0000-0000-0000-000000000000}', 1, 'TotalGB', 'DECIMAL', 'Todas as Tabelas', '127',
 N'2025-07-08T17:52:48.07'),
('cro-sp', '{00000000-0000-0000-0000-000000000001}', 1, 'DataUltimoRegistro', 'DATETIME', 'Contabilidade.Lancamentos',
 '2025-07-08 14:52:17.80', N'2025-07-08T17:52:40.34'),
('cro-sp', '{00000000-0000-0000-0000-000000000001}', 1, 'QtdTotalRegistro', 'INT', 'Contabilidade.Lancamentos',
 '492236', N'2025-07-08T17:52:40.34'),
('cro-sp', '{00000000-0000-0000-0000-000000000001}', 1, 'QtdRegistroAno', 'INT', 'Contabilidade.Lancamentos', '60706',
 N'2025-07-08T17:52:40.34'),
('cro-sp', '{00000000-0000-0000-0000-000000000001}', 1, 'DataUltimoAcesso', 'DATETIME', 'acesso.sessoes',
 '2025-07-08 14:52:09.33', N'2025-07-08T17:52:40.34'),
('cro-sp', '{00000000-0000-0000-0000-000000000001}', 1, 'QtdAcessos', 'INT', 'acesso.sessoes', '25367',
 N'2025-07-08T17:52:40.34'),
('cro-sp', '{00000000-0000-0000-0000-000000000001}', 1, 'QtdAcessosNoAno', 'INT', 'acesso.sessoes', '2203',
 N'2025-07-08T17:52:40.34'),
('cro-sp', '{00000000-0000-0000-0000-000000000001}', 1, 'PossueLicenca', 'BIT', 'sistema.configuracoes', '1',
 N'2025-07-08T17:52:40.34'),
('cro-sp', '{00000000-0000-0000-0000-000000000001}', 1, 'QuantidadeArquivosAnexos', 'INT', 'Todas as Tabelas', '185',
 N'2025-07-08T17:52:48.07'),
('cro-sp', '{00000000-0000-0000-0000-000000000001}', 1, 'TotalGB', 'DECIMAL', 'Todas as Tabelas', '0',
 N'2025-07-08T17:52:48.07'),
('cro-sp', '{00000000-0000-0000-0000-000000000002}', 1, 'DataUltimoAcesso', 'DATETIME', 'acesso.sessoes',
 '2025-07-08 14:52:31.69', N'2025-07-08T17:52:40.34'),
('cro-sp', '{00000000-0000-0000-0000-000000000002}', 1, 'QtdAcessos', 'INT', 'acesso.sessoes', '267978',
 N'2025-07-08T17:52:40.34'),
('cro-sp', '{00000000-0000-0000-0000-000000000002}', 1, 'QtdAcessosNoAno', 'INT', 'acesso.sessoes', '41983',
 N'2025-07-08T17:52:40.34'),
('cro-sp', '{00000000-0000-0000-0000-000000000002}', 1, 'PossueLicenca', 'BIT', 'sistema.configuracoes', '0',
 N'2025-07-08T17:52:40.34'),
('cro-sp', '{00000000-0000-0000-0000-000000000002}', 1, 'QuantidadeArquivosAnexos', 'INT', 'Todas as Tabelas', '0',
 N'2025-07-08T17:52:48.07'),
('cro-sp', '{00000000-0000-0000-0000-000000000002}', 1, 'TotalGB', 'DECIMAL', 'Todas as Tabelas', '0',
 N'2025-07-08T17:52:48.07');

SELECT * FROM #DadosMetricas


CREATE TABLE Staging.MetricasClientes
(
    [Cliente] VARCHAR(20) NOT NULL,
    [CodSistema] UNIQUEIDENTIFIER NOT NULL,
    [Ordem] TINYINT NOT NULL,
    [NomeMetrica] VARCHAR(50) NOT NULL,
    [TipoRetorno] VARCHAR(20) NOT NULL,
    [TabelaConsultada] VARCHAR(128) NULL,
    [Valor] VARCHAR(MAX) NULL,
    [DataCarga] DATETIME2(2) NOT NULL,
	DataProcessamento DATETIME2(2) NULL
)WITH(DATA_COMPRESSION =PAGE);


CREATE TABLE DM_MetricasProdutos.DimTipoRetornoMetrica
(
  SkTipoRetornoMetrica TINYINT NOT NULL PRIMARY KEY,
  Nome VARCHAR(50) NOT NULL,
  DataCarga  DATETIME2(2) NOT NULL

) WITH (DATA_COMPRESSION =PAGE)

CREATE TABLE DM_MetricasProdutos.DimMetricasProdutos
(
  SkMetricaProduto INT NOT NULL PRIMARY KEY,
  SkTipoRetornoMetrica  TINYINT NOT NULL,
  Nome VARCHAR(50) NOT NULL,
  TabelaConsultada VARCHAR(130) NOT NULL,
  [Ativo] BIT NOT NULL DEFAULT(1),
  [DataCriacao] DATETIME2(2) NOT NULL DEFAULT(GETDATE()),
  [DataAtualizacao] DATETIME2(2) NOT NULL DEFAULT(GETDATE()),

) WITH (DATA_COMPRESSION =PAGE)






