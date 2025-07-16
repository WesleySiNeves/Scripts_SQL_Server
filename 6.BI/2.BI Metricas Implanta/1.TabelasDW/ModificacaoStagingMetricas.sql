-- Adicionar campos de versionamento temporal (SCD Tipo 2) à tabela staging
ALTER TABLE [Staging].[MetricasClientes] ADD
    [VersaoAtual]       [BIT]          NOT NULL DEFAULT(1),           -- Indica se é a versão atual
    [DataInicioVersao]  [DATETIME2](2) NOT NULL DEFAULT(GETDATE()),   -- Quando a versão começou
    [DataFimVersao]     [DATETIME2](2) NULL,                          -- Quando a versão terminou (NULL = atual)
    [HashValor]         [VARBINARY](32) NULL;                         -- Hash do valor para comparação rápida
GO

-- Criar índice para performance nas consultas de versionamento
CREATE NONCLUSTERED INDEX [IX_MetricasClientes_Versao] 
ON [Staging].[MetricasClientes] ([Cliente], [CodSistema], [Ordem], [NomeMetrica], [VersaoAtual])
INCLUDE ([Valor], [DataInicioVersao], [DataFimVersao]);
GO

-- Criar índice para busca por hash (performance)
CREATE NONCLUSTERED INDEX [IX_MetricasClientes_Hash] 
ON [Staging].[MetricasClientes] ([Cliente], [CodSistema], [Ordem], [NomeMetrica], [HashValor])
WHERE [VersaoAtual] = 1;
GO