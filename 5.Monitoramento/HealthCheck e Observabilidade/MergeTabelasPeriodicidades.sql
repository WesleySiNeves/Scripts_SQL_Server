

DROP TABLE IF EXISTS #temptable

CREATE TABLE #temptable
(
    [IdAcao] SMALLINT,
    [Nome] VARCHAR(30),
    [Descricao] VARCHAR(150),
    [Periodicidade] SMALLINT,
    [Ativo] BIT,
    [DataInicio] DATE,
    [DataUltimaExecucao] DATE
);

INSERT INTO #temptable
(
    [IdAcao],
    [Nome],
    [Descricao],
    [Periodicidade],
    [Ativo],
    [DataInicio],
    [DataUltimaExecucao]
)
VALUES
(1, 'AtualizarStatisticas', 'Atualização de statisticas diariamente (Periodicidade =1)', 1, 1, N'2020-10-07',
 N'2021-03-20'),
(2, 'CriarIndicesAutomaticamente', 'Criação de indices diariamente (Periodicidade =1)', 1, 1, N'2020-10-07',
 N'2021-03-21'),
(3, 'CriarStatisticasColunas', 'Criação de estatisticas nas colunas  (Periodicidade =1)', 1, 0, N'2020-10-07',
 N'2021-03-21'),
(4, 'DeletarIndicesDuplicados', 'Deleção de indices duplicados  (Periodicidade =15)', 15, 0, N'2020-10-07', NULL),
(5, 'AnalisarIndicesIneficientes', 'Analise de indices ineficientes  (Periodicidade =7)', 7, 0, N'2020-10-07', NULL),
(6, 'DesfragmentacaoIndices', 'Desfragmentação de indices  (Periodicidade =7)', 7, 1, N'2020-10-07', NULL),
(7, 'DeletarIndicesNaoUsados', 'Deleção de indices  não usados (Periodicidade =60)', 60, 0, N'2020-10-07',
 N'2021-02-11'),
(8, 'ShrinkDatabase', 'Efetua o ShrinkDatabase(Periodicidade =2)', 30, 1, N'2020-10-07', NULL),
(9, 'ExpurgarElmah', 'Expurgar Erros do Elmah', 30, 0, N'2020-10-07', N'2021-02-11'),
(10, 'ExpurgarLogs',
 'Expurgar Logs em Json  no banco de dados , a peridiocidade ficará zero pois esse valor e vem da tabela sistema.configuração',
 0, 1, N'2020-10-07', N'2025-06-27'),
(12, 'DeletarArquivosAnexosOrfaos', 'Deletar Arquivos Anexos Orfãos', 30, 0, N'2020-11-23', NULL),
(13, 'ExpurgarLogsAcesso', 'Expurgar os logs de acesso', 360, 1, N'2021-02-18', NULL),
(14, 'DeletarLogsDuplicados', 'Deletar Logs Duplicados', 7, 1, N'2023-02-28', NULL),
(15, 'ExpurgarSistemaNotificacoes', 'Expurgar a tabela Sistema.Notificacoes', 120, 1, N'2023-12-28', NULL),
(16, 'ExpurgarLogsRelatoriosTasks', 'Expurgar os logs de execuções de relatorios e logs tasks', 30, 1, N'2024-01-23',
 NULL);



-- MERGE para sincronizar a tabela temporária com HealthCheck.AcoesPeriodicidadeDias
-- Insere registros que não existem, atualiza os existentes e remove os que não estão na origem
MERGE HealthCheck.AcoesPeriodicidadeDias AS TARGET
USING #temptable AS SOURCE
ON TARGET.IdAcao = SOURCE.IdAcao

-- Quando o registro existe na tabela de destino, atualiza os campos
WHEN MATCHED THEN
    UPDATE SET
        Nome = SOURCE.Nome,
        Descricao = SOURCE.Descricao,
        Periodicidade = SOURCE.Periodicidade,
        Ativo = SOURCE.Ativo,
        DataInicio = SOURCE.DataInicio,
        DataUltimaExecucao = SOURCE.DataUltimaExecucao

-- Quando o registro não existe na tabela de destino, insere
WHEN NOT MATCHED BY TARGET THEN
    INSERT (Nome, Descricao, Periodicidade, Ativo, DataInicio, DataUltimaExecucao)
    VALUES (SOURCE.Nome, SOURCE.Descricao, SOURCE.Periodicidade, 
            SOURCE.Ativo, SOURCE.DataInicio, SOURCE.DataUltimaExecucao)

-- Quando o registro existe na tabela de destino mas não na origem, remove
WHEN NOT MATCHED BY SOURCE THEN
    DELETE;

-- Mostra o resultado da operação
SELECT @@ROWCOUNT AS 'Registros Afetados';

-- Consulta final para verificar o resultado
SELECT * FROM HealthCheck.AcoesPeriodicidadeDias
ORDER BY IdAcao;

