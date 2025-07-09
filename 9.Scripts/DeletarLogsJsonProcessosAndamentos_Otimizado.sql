-- =============================================
-- Script: Deletar Logs JSON Processos Andamentos - Versão Otimizada
-- Descrição: Remove logs duplicados com controle de progresso usando WHILE
-- Data: 2025-01-30
-- =============================================

BEGIN TRY
    -- Configurações otimizadas para Azure SQL Database
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
    SET LOCK_TIMEOUT 1800000; -- 30 minutos
    SET DEADLOCK_PRIORITY LOW;
    SET NOCOUNT ON;

DECLARE @BathSize INT = 1000;

-- Limpa tabelas temporárias se existirem
DROP TABLE IF EXISTS #DadosBase;
DROP TABLE IF EXISTS #ControleExecucao;

-- Cria tabela base com dados a serem processados (com RowId para controle)
CREATE TABLE #DadosBase
(
    RowId INT IDENTITY(1,1) PRIMARY KEY,  -- Chave primária para controle de loop
    [IdEntidade] UNIQUEIDENTIFIER,
    Data DATE,
    [MaxData] DATETIME2(2),
    [Quantidade] INT
);

-- Cria tabela de controle de execução
CREATE TABLE #ControleExecucao
(
    TotalRegistros INT,
    RegistrosProcessados INT,
    RegistrosDeletados INT,
    InicioExecucao DATETIME2,
    UltimaAtualizacao DATETIME2
);

-- Popula dados base
DECLARE @DataHoraInicio VARCHAR(30) = CONVERT(VARCHAR, GETDATE(), 120);
RAISERROR('=== INICIANDO ANÁLISE DE LOGS DUPLICADOS ===', 0, 1) WITH NOWAIT;
DECLARE @MsgInicio VARCHAR(100) = 'Data/Hora Início: ' + @DataHoraInicio;
RAISERROR(@MsgInicio, 0, 1) WITH NOWAIT;

-- Inserção otimizada com TOP para respeitar @BathSize
INSERT INTO #DadosBase (IdEntidade, Data, MaxData, Quantidade)
SELECT TOP (@BathSize)
       IdEntidade,
       Data = CAST(Data AS DATE),
       MAX(Data) AS MaxData,
       COUNT(1) AS Quantidade
FROM Log.LogsJson
WHERE Entidade = 'Processo.ProcessosAndamentos'
      AND Acao = 'U'
      AND YEAR(Data) = 2025
      AND LEN(Conteudo) > 1048576  -- 1MB em 
GROUP BY CAST(Data AS DATE),
         IdEntidade
HAVING COUNT(1) > 10
ORDER BY CAST(Data AS DATE) DESC;

-- Inicializa controle de execução
DECLARE @TotalRegistros INT = (SELECT COUNT(*) FROM #DadosBase);
DECLARE @TotalLogsParaDeletar INT;

-- Calcula total de logs que serão deletados (já considerando @BathSize)
SELECT @TotalLogsParaDeletar = SUM(Quantidade - 1)
FROM #DadosBase;

INSERT INTO #ControleExecucao
VALUES (@TotalRegistros, 0, 0, GETDATE(), GETDATE());

-- Exibe estatísticas iniciais
DECLARE @MsgGrupos VARCHAR(100) = 'Total de grupos para processar (limitado por @BathSize): ' + CAST(@TotalRegistros AS VARCHAR(20));
RAISERROR(@MsgGrupos, 0, 1) WITH NOWAIT;
DECLARE @MsgLogs VARCHAR(100) = 'Total estimado de logs para deletar: ' + CAST(@TotalLogsParaDeletar AS VARCHAR(20));
RAISERROR(@MsgLogs, 0, 1) WITH NOWAIT;
DECLARE @MsgBathSize VARCHAR(100) = 'Tamanho do lote (@BathSize): ' + CAST(@BathSize AS VARCHAR(20));
RAISERROR(@MsgBathSize, 0, 1) WITH NOWAIT;
RAISERROR('================================================', 0, 1) WITH NOWAIT;

/* Declaração de variáveis para WHILE loop */
DECLARE @CurrentRowId INT = 1;
DECLARE @MaxRowId INT;
DECLARE @IdEntidade UNIQUEIDENTIFIER,
        @Data DATE,
        @MaxData DATETIME2(2),
        @Quantidade INT,
        @RegistrosProcessados INT = 0,
        @RegistrosDeletados INT = 0,
        @PercentualConcluido DECIMAL(5,2),
        @LogsDeletadosNaIteracao INT,
        @MensagemProgresso VARCHAR(500);

-- Obter o máximo RowId para controle do loop
SELECT @MaxRowId = MAX(RowId) FROM #DadosBase;

-- WHILE loop otimizado (substitui o cursor)
WHILE @CurrentRowId <= @MaxRowId
BEGIN
    -- Buscar dados do registro atual
    SELECT 
        @IdEntidade = IdEntidade,
        @Data = Data,
        @MaxData = MaxData,
        @Quantidade = Quantidade
    FROM #DadosBase 
    WHERE RowId = @CurrentRowId;

    -- Verificar se encontrou registro (pode haver gaps nos IDs)
    IF @@ROWCOUNT > 0
    BEGIN
        -- Incrementa contador de registros processados
        SET @RegistrosProcessados = @RegistrosProcessados + 1;
        
        -- Calcula quantos logs serão deletados nesta iteração
        SET @LogsDeletadosNaIteracao = @Quantidade - 1;
        
        -- Executa deleção dos logs duplicados (mantém apenas o mais recente)
        -- VERSÃO OTIMIZADA - Substitua as linhas 122-134
        
        -- Abordagem 1: CTE com DELETE direto (mais eficiente)
        WITH LogsParaDeletar AS (
            SELECT IdLog,
                   ROW_NUMBER() OVER (
                       PARTITION BY CAST(Data AS DATE), IdEntidade 
                       ORDER BY Data DESC
                   ) AS RN
            FROM Log.LogsJson
            WHERE CAST(Data AS DATE) = @Data
                  AND IdEntidade = @IdEntidade
                  AND Entidade = 'Processo.ProcessosAndamentos'
                  AND Acao = 'U'
                  AND LEN(Conteudo) > 1048576  -- 1MB em bytes (mais rápido que divisão)
        )
        DELETE l
        FROM LogsParaDeletar l
        WHERE l.RN > 1;
        
        -- Atualiza contador de registros deletados
        SET @RegistrosDeletados = @RegistrosDeletados + @@ROWCOUNT;
        
        -- Calcula percentual de conclusão
        SET @PercentualConcluido = (CAST(@RegistrosProcessados AS DECIMAL(10,2)) / @TotalRegistros) * 100;
        
        -- Exibe progresso para CADA execução de DELETE
        SET @MensagemProgresso = CONCAT(
            'DELETE #', @RegistrosProcessados, ' | ',
            'Progresso: ', CAST(ROUND(@PercentualConcluido, 1) AS VARCHAR(6)), '% (',
            @RegistrosProcessados, '/', @TotalRegistros, ') | ',
            'Deletados nesta iteração: ', @@ROWCOUNT, ' | ',
            'Total deletados: ', @RegistrosDeletados, ' | ',
            'Hora: ', CONVERT(VARCHAR, GETDATE(), 108)
        );
        
        RAISERROR(@MensagemProgresso, 0, 1) WITH NOWAIT;
        
        -- Pequeno delay para reduzir pressão no banco
        IF @@ROWCOUNT > 0
            WAITFOR DELAY '00:00:01';
        
        -- Atualiza controle de execução
        UPDATE #ControleExecucao
        SET RegistrosProcessados = @RegistrosProcessados,
            RegistrosDeletados = @RegistrosDeletados,
            UltimaAtualizacao = GETDATE();
    END;

    -- Incrementa para próximo registro
    SET @CurrentRowId = @CurrentRowId + 1;
END;

-- Exibe relatório final
DECLARE @DataHoraFim VARCHAR(30) = CONVERT(VARCHAR, GETDATE(), 120);
RAISERROR('================================================', 0, 1) WITH NOWAIT;
RAISERROR('=== EXECUÇÃO CONCLUÍDA ===', 0, 1) WITH NOWAIT;
DECLARE @MsgFim VARCHAR(100) = 'Data/Hora Fim: ' + @DataHoraFim;
RAISERROR(@MsgFim, 0, 1) WITH NOWAIT;
DECLARE @MsgProcessados VARCHAR(100) = 'Total de grupos processados: ' + CAST(@RegistrosProcessados AS VARCHAR(20));
RAISERROR(@MsgProcessados, 0, 1) WITH NOWAIT;
DECLARE @MsgDeletados VARCHAR(100) = 'Total de logs deletados: ' + CAST(@RegistrosDeletados AS VARCHAR(20));
RAISERROR(@MsgDeletados, 0, 1) WITH NOWAIT;
RAISERROR('Percentual concluído: 100%', 0, 1) WITH NOWAIT;

-- Calcula tempo de execução
DECLARE @TempoExecucao INT;
SELECT @TempoExecucao = DATEDIFF(SECOND, InicioExecucao, GETDATE())
FROM #ControleExecucao;

DECLARE @MsgTempo VARCHAR(200) = 'Tempo total de execução: ' + CAST(@TempoExecucao AS VARCHAR(10)) + ' segundos (' + FORMAT(@TempoExecucao / 60.0, 'N1') + ' minutos)';
RAISERROR(@MsgTempo, 0, 1) WITH NOWAIT;
DECLARE @MsgTempoMedio VARCHAR(200) = 'Tempo médio por grupo: ' + FORMAT(CASE WHEN @RegistrosProcessados > 0 THEN (@TempoExecucao * 1.0 / @RegistrosProcessados) ELSE 0 END, 'N2') + ' segundos';
RAISERROR(@MsgTempoMedio, 0, 1) WITH NOWAIT;
RAISERROR('================================================', 0, 1) WITH NOWAIT;

    -- Limpa tabelas temporárias
    DROP TABLE IF EXISTS #DadosBase;
    DROP TABLE IF EXISTS #ControleExecucao;

END TRY
BEGIN CATCH
    DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
    DECLARE @ErrorNumber INT = ERROR_NUMBER();
    DECLARE @ErrorLine INT = ERROR_LINE();

    PRINT '❌ === ERRO DETECTADO ===';
    PRINT 'Número: ' + CAST(@ErrorNumber AS VARCHAR(10));
    PRINT 'Linha: ' + CAST(@ErrorLine AS VARCHAR(10));
    PRINT 'Mensagem: ' + @ErrorMessage;
    PRINT '========================';

    -- Limpa tabelas temporárias em caso de erro
    DROP TABLE IF EXISTS #DadosBase;
    DROP TABLE IF EXISTS #ControleExecucao;

    THROW;
END CATCH;





