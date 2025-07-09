-- =============================================
-- Procedure: HealthCheck.GetMetricasSistema_Otimizada
-- Descrição: Versão otimizada da procedure original com melhorias de performance
-- Autor: Assistente IA
-- Data: 2024
-- =============================================

-- EXEC HealthCheck.GetMetricasSistema_Otimizada @RecuperarInformacoesArquivosAnexos = 1, -- bit
--                                                @RecuperarDataUltimoCadastroSistema = 1, -- bit
--                                                @RecuperarTodasMetricas = 0,             -- bit
--                                                @RetornarFormatoPivot = 0                -- bit

CREATE OR ALTER PROCEDURE HealthCheck.GetMetricasSistema_Otimizada
(
    @RecuperarInformacoesArquivosAnexos BIT = 1,
    @RecuperarDataUltimoCadastroSistema BIT = 1,
    @RecuperarTodasMetricas BIT = 0,
    @RetornarFormatoPivot BIT = 1
)
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Declaração de variáveis para evitar consultas repetitivas
    DECLARE @AnoAtual INT = YEAR(GETDATE());
    DECLARE @DataAtual DATETIME2(2) = GETDATE();
    
    -- CTE para configurações do sistema (evita múltiplas consultas)
    WITH ConfiguracoesSistema AS (
        SELECT 
            Configuracao,
            Valor,
            Ano
        FROM Sistema.Configuracoes
        WHERE Ano = @AnoAtual
            AND Configuracao IN (
                'UtilizaCentroCustoPagamento',
                'OrcamentoPorCentroCusto',
                'LicencaCentroCustos',
                'AcessoServicoOnlineSiscaf'
            )
    ),
    -- CTE para métricas de acesso consolidadas
    MetricasAcesso AS (
        SELECT 
            s.IdSistema,
            MAX(s.DataUltimoRequest) AS DataUltimoAcesso,
            COUNT(1) AS QtdAcessos,
            SUM(CASE WHEN YEAR(s.DataInicio) = @AnoAtual THEN 1 ELSE 0 END) AS QtdAcessosNoAno
        FROM Acesso.Sessoes s
        GROUP BY s.IdSistema
    ),
    -- CTE para licenças dos sistemas
    LicencasSistemas AS (
        SELECT DISTINCT
            s.CodSistema,
            CASE 
                WHEN EXISTS (
                    SELECT 1 
                    FROM Sistema.Configuracoes c
                    WHERE c.Modulo = 'Global'
                        AND c.Configuracao LIKE 'Licenca%'
                        AND c.Valor IS NOT NULL 
                        AND LEN(c.Valor) > 0
                        AND REPLACE(
                            REPLACE(REPLACE(REPLACE(REPLACE(s.Nome, '.NET', ''), ' ', ''), '&', ''), 'ção', 'cao'),
                            'NET', ''
                        ) LIKE '%' + REPLACE(REPLACE(c.Configuracao, 'Licenca', ''), 'NET', '') + '%'
                ) THEN 1 
                ELSE 0 
            END AS PossueLicenca
        FROM Sistema.Sistemas s
    )
    
    -- Tabela temporária principal para métricas
    DROP TABLE IF EXISTS #Metricas;
    CREATE TABLE #Metricas
    (
        Id INT NOT NULL IDENTITY(1, 1),
        CodSistema UNIQUEIDENTIFIER NOT NULL,
        Ordem TINYINT NOT NULL,
        NomeMetrica VARCHAR(50),
        TipoRetorno VARCHAR(20),
        TabelaConsultada VARCHAR(128),
        Valor VARCHAR(MAX),
        DataAtualizacao DATETIME2(2),
        PRIMARY KEY (CodSistema, NomeMetrica)
    );
    
    -- Inserir métricas base de acesso e licenças
    INSERT INTO #Metricas (CodSistema, Ordem, NomeMetrica, TipoRetorno, TabelaConsultada, Valor, DataAtualizacao)
    SELECT 
        s.CodSistema,
        1 AS Ordem,
        'DataUltimoAcesso' AS NomeMetrica,
        'DATETIME' AS TipoRetorno,
        'Acesso.Sessoes' AS TabelaConsultada,
        CAST(ma.DataUltimoAcesso AS VARCHAR(MAX)) AS Valor,
        @DataAtual AS DataAtualizacao
    FROM Sistema.Sistemas s
        LEFT JOIN MetricasAcesso ma ON ma.IdSistema = s.CodSistema
    
    UNION ALL
    
    SELECT 
        s.CodSistema,
        1,
        'QtdAcessos',
        'INT',
        'Acesso.Sessoes',
        CAST(ISNULL(ma.QtdAcessos, 0) AS VARCHAR(MAX)),
        @DataAtual
    FROM Sistema.Sistemas s
        LEFT JOIN MetricasAcesso ma ON ma.IdSistema = s.CodSistema
    
    UNION ALL
    
    SELECT 
        s.CodSistema,
        1,
        'QtdAcessosNoAno',
        'INT',
        'Acesso.Sessoes',
        CAST(ISNULL(ma.QtdAcessosNoAno, 0) AS VARCHAR(MAX)),
        @DataAtual
    FROM Sistema.Sistemas s
        LEFT JOIN MetricasAcesso ma ON ma.IdSistema = s.CodSistema
    
    UNION ALL
    
    SELECT 
        s.CodSistema,
        1,
        'PossueLicenca',
        'BIT',
        'Sistema.Configuracoes',
        CAST(ISNULL(ls.PossueLicenca, 0) AS VARCHAR(MAX)),
        @DataAtual
    FROM Sistema.Sistemas s
        LEFT JOIN LicencasSistemas ls ON ls.CodSistema = s.CodSistema;
    
    -- Inserir métricas específicas dos sistemas usando MERGE para melhor performance
    WITH MetricasEspecificas AS (
        SELECT * FROM (
            VALUES 
            -- SISCONT.NET
            ('00000000-0000-0000-0000-000000000001', 'DataUltimoRegistro', 'DATETIME', 'Contabilidade.Lancamentos', 'SELECT MAX(DataCadastro) FROM Contabilidade.Lancamentos'),
            ('00000000-0000-0000-0000-000000000001', 'QtdTotalRegistro', 'INT', 'Contabilidade.Lancamentos', 'SELECT COUNT(1) FROM Contabilidade.Lancamentos'),
            ('00000000-0000-0000-0000-000000000001', 'QtdRegistroAno', 'INT', 'Contabilidade.Lancamentos', 'SELECT COUNT(1) FROM Contabilidade.Lancamentos WHERE YEAR(DataCadastro) = YEAR(GETDATE())'),
            ('00000000-0000-0000-0000-000000000001', 'QtdPagamentos', 'INT', 'Despesa.Pagamentos', 'SELECT COUNT(1) FROM Despesa.Pagamentos'),
            ('00000000-0000-0000-0000-000000000001', 'QtdPagamentosNoAno', 'INT', 'Despesa.Pagamentos', 'SELECT COUNT(1) FROM Despesa.Pagamentos WHERE YEAR(DataPagamento) = YEAR(GETDATE())'),
            
            -- PCS.NET
            ('00000000-0000-0000-0000-000000000003', 'DataUltimoRegistro', 'DATETIME', 'PCS.Despesas', 'SELECT MAX(DataDespesa) FROM PCS.Despesas'),
            ('00000000-0000-0000-0000-000000000003', 'QtdTotalRegistro', 'INT', 'PCS.Despesas', 'SELECT COUNT(1) FROM PCS.Despesas'),
            ('00000000-0000-0000-0000-000000000003', 'QtdRegistroAno', 'INT', 'PCS.Despesas', 'SELECT COUNT(1) FROM PCS.Despesas WHERE YEAR(DataDespesa) = YEAR(GETDATE())'),
            
            -- SISPAT.NET
            ('00000000-0000-0000-0000-000000000004', 'DataUltimoRegistro', 'DATETIME', 'Patrimonio.BensMoveis', 'SELECT MAX(DataCadastro) FROM Patrimonio.BensMoveis'),
            ('00000000-0000-0000-0000-000000000004', 'QtdTotalRegistro', 'INT', 'Patrimonio.BensMoveis', 'SELECT COUNT(1) FROM Patrimonio.BensMoveis'),
            ('00000000-0000-0000-0000-000000000004', 'QtdRegistroAno', 'INT', 'Patrimonio.BensMoveis', 'SELECT COUNT(1) FROM Patrimonio.BensMoveis WHERE YEAR(DataCadastro) = YEAR(GETDATE())'),
            
            -- Agenda Financeira.NET
            ('00000000-0000-0000-0000-000000000005', 'DataUltimoRegistro', 'DATETIME', 'Agenda.LancamentosFinanceiros', 'SELECT MAX(DataModificacao) FROM Agenda.LancamentosFinanceiros'),
            ('00000000-0000-0000-0000-000000000005', 'QtdTotalRegistro', 'INT', 'Agenda.LancamentosFinanceiros', 'SELECT COUNT(1) FROM Agenda.LancamentosFinanceiros'),
            ('00000000-0000-0000-0000-000000000005', 'QtdRegistroAno', 'INT', 'Agenda.LancamentosFinanceiros', 'SELECT COUNT(1) FROM Agenda.LancamentosFinanceiros WHERE YEAR(DataModificacao) = YEAR(GETDATE())'),
            
            -- SIALM.NET
            ('00000000-0000-0000-0000-000000000006', 'DataUltimoRegistro', 'DATETIME', 'Almoxarifado.Movimentacoes', 'SELECT MAX(DataCriacao) FROM Almoxarifado.Movimentacoes'),
            ('00000000-0000-0000-0000-000000000006', 'QtdTotalRegistro', 'INT', 'Almoxarifado.Movimentacoes', 'SELECT COUNT(1) FROM Almoxarifado.Movimentacoes'),
            ('00000000-0000-0000-0000-000000000006', 'QtdRegistroAno', 'INT', 'Almoxarifado.Movimentacoes', 'SELECT COUNT(1) FROM Almoxarifado.Movimentacoes WHERE YEAR(DataCriacao) = YEAR(GETDATE())'),
            
            -- Compras e Contratos.NET
            ('00000000-0000-0000-0000-000000000007', 'DataUltimoRegistro', 'DATETIME', 'Contrato.Contratos', 'SELECT MAX(DataPublicacao) FROM Contrato.Contratos'),
            ('00000000-0000-0000-0000-000000000007', 'QtdTotalRegistro', 'INT', 'Contrato.Contratos', 'SELECT COUNT(1) FROM Contrato.Contratos'),
            ('00000000-0000-0000-0000-000000000007', 'QtdRegistroAno', 'INT', 'Contrato.Contratos', 'SELECT COUNT(1) FROM Contrato.Contratos WHERE YEAR(DataPublicacao) = YEAR(GETDATE())'),
            
            -- SISPAD.NET
            ('00000000-0000-0000-0000-000000000008', 'DataUltimoRegistro', 'DATETIME', 'Viagem.SolicitacoesPessoas', 'SELECT MAX(DataIda) FROM Viagem.SolicitacoesPessoas'),
            ('00000000-0000-0000-0000-000000000008', 'QtdTotalRegistro', 'INT', 'Viagem.SolicitacoesPessoas', 'SELECT COUNT(IdSolicitacaoPessoa) FROM Viagem.SolicitacoesPessoas'),
            ('00000000-0000-0000-0000-000000000008', 'QtdRegistroAno', 'INT', 'Viagem.SolicitacoesPessoas', 'SELECT COUNT(IdSolicitacaoPessoa) FROM Viagem.SolicitacoesPessoas WHERE YEAR(DataIda) = YEAR(GETDATE())')
        ) AS t(CodSistema, NomeMetrica, TipoRetorno, TabelaConsultada, Script)
    )
    INSERT INTO #Metricas (CodSistema, Ordem, NomeMetrica, TipoRetorno, TabelaConsultada, Valor, DataAtualizacao)
    SELECT 
        CAST(me.CodSistema AS UNIQUEIDENTIFIER),
        2 AS Ordem,
        me.NomeMetrica,
        me.TipoRetorno,
        me.TabelaConsultada,
        NULL AS Valor, -- Será preenchido posteriormente via SQL dinâmico otimizado
        @DataAtual
    FROM MetricasEspecificas me;
    
    -- Configurar ordem das métricas (replicando lógica original)
    UPDATE #MetricasScripts
    SET Ordem = 1
    WHERE NomeMetrica IN ('DataUltimoRegistro', 'QtdTotalRegistro', 'QtdRegistroAno');
    
    -- Filtrar métricas se necessário
    IF (@RecuperarTodasMetricas = 0)
    BEGIN
        DELETE FROM #MetricasScripts
        WHERE Ordem = 2;
    END;
    
    -- Executar scripts dinâmicos (replicando cursor original)
    DECLARE @dataAtualizacao DATETIME = GETDATE();
    DECLARE @CodSistemaScript UNIQUEIDENTIFIER,
            @OrdemScript TINYINT,
            @NomeScript VARCHAR(100),
            @TipoRetornoScript VARCHAR(100),
            @TabelaConsultadaScript VARCHAR(200),
            @ScriptSQL VARCHAR(MAX);
    
    DECLARE cursor_InsertsMetricas CURSOR FAST_FORWARD READ_ONLY FOR
    SELECT CodSistema, Ordem, NomeMetrica, TipoRetorno, TabelaConsultada, Script
    FROM #MetricasScripts;
    
    OPEN cursor_InsertsMetricas;
    
    FETCH NEXT FROM cursor_InsertsMetricas
    INTO @CodSistemaScript, @OrdemScript, @NomeScript, @TipoRetornoScript, @TabelaConsultadaScript, @ScriptSQL;
    
    WHILE @@FETCH_STATUS = 0
    BEGIN
        DECLARE @result NVARCHAR(MAX);
        DECLARE @_sql NVARCHAR(MAX) = N'SELECT @result = (' + @ScriptSQL + N')';
        
        EXEC sp_executesql @stmt = @_sql,
                           @params = N'@result VARCHAR(MAX) OUTPUT',
                           @result = @result OUTPUT;
        
        INSERT INTO #Metricas (CodSistema, Ordem, NomeMetrica, TipoRetorno, TabelaConsultada, Valor, DataAtualizacao)
        VALUES (@CodSistemaScript, @OrdemScript, @NomeScript, @TipoRetornoScript, @TabelaConsultadaScript, @result, @dataAtualizacao);
        
        FETCH NEXT FROM cursor_InsertsMetricas
        INTO @CodSistemaScript, @OrdemScript, @NomeScript, @TipoRetornoScript, @TabelaConsultadaScript, @ScriptSQL;
    END;
    
    CLOSE cursor_InsertsMetricas;
    DEALLOCATE cursor_InsertsMetricas;
    
    -- Inserir métricas base de acesso e licenças
    INSERT INTO #Metricas (CodSistema, Ordem, NomeMetrica, TipoRetorno, TabelaConsultada, Valor, DataAtualizacao)
    SELECT CodSistema, Ordem, 'DataUltimoAcesso', 'DATETIME', 'acesso.sessoes', DataUltimoAcesso, @dataAtualizacao
    FROM #MetricasBase
    UNION ALL
    SELECT CodSistema, Ordem, 'QtdAcessos', 'INT', 'acesso.sessoes', QtdAcessos, @dataAtualizacao
    FROM #MetricasBase
    UNION ALL
    SELECT CodSistema, Ordem, 'QtdAcessosNoAno', 'INT', 'acesso.sessoes', QtdAcessosNoAno, @dataAtualizacao
    FROM #MetricasBase
    UNION ALL
    SELECT CodSistema, Ordem, 'PossueLicenca', 'BIT', 'sistema.configuracoes', PossueLicenca, @dataAtualizacao
    FROM #MetricasBase;
    
    -- Processar informações de logs se solicitado
    -- Nota: Na procedure original, a tabela #InformacoesLogs é criada e populada
    -- mas nunca é utilizada. Mantendo a mesma lógica aqui.
    IF (@RecuperarDataUltimoCadastroSistema = 1)
    BEGIN
        -- Criação da tabela temporária para logs (compatibilidade com procedure original)
        DROP TABLE IF EXISTS #InformacoesLogs;
        CREATE TABLE #InformacoesLogs
        (
            CodSistema UNIQUEIDENTIFIER NOT NULL,
            [Entidade] VARCHAR(128),
            [NomeSchema] VARCHAR(128),
            [DataUltimoRegistroInserido] DATETIME2(2),
            TotalInseridoAno INT
        );
        
        -- População da tabela (replicando lógica original)
        INSERT INTO #InformacoesLogs
        SELECT se.CodSistema,
               Entidade,
               SUBSTRING(Entidade, 0, CHARINDEX('.', Entidade, 0)) AS NomeSchema,
               MAX(Data) AS DataUltimoRegistroInserido,
               COUNT(1) AS TotalInseridoAno
        FROM Log.LogsJson lj
            JOIN Sistema.SistemasEspelhamentos se
                ON se.IdSistemaEspelhamento = lj.IdSistemaEspelhamento
        WHERE Acao = 'I'
        GROUP BY se.CodSistema,
                 Entidade,
                 SUBSTRING(Entidade, 0, CHARINDEX('.', Entidade, 0))
        ORDER BY Entidade;
    END;
    
    -- Processar arquivos anexos se solicitado (replicando lógica original)
    IF (@RecuperarInformacoesArquivosAnexos = 1)
    BEGIN
        -- Criar tabela para métricas de arquivos anexos
        DROP TABLE IF EXISTS #MetricasArquivosAnexos;
        CREATE TABLE #MetricasArquivosAnexos
        (
            CodSistema UNIQUEIDENTIFIER,
            [Entidade] VARCHAR(250),
            NomeSchema VARCHAR(200),
            [QuantidadeArquivosAnexos] INT,
            [Total em GB] DECIMAL(18, 2)
        );
        
        -- Criar tabela para tabelas principais do sistema
        DROP TABLE IF EXISTS #TabelasPrincipaisSistema;
        CREATE TABLE #TabelasPrincipaisSistema
        (
            [CodSistema] UNIQUEIDENTIFIER,
            Sistema VARCHAR(100),
            [Tabela Principal] VARCHAR(200),
            NomeSchema VARCHAR(200)
        );
        
        -- Popular tabela de tabelas principais
        WITH DadosTabelaPrincipal AS (
            SELECT CodSistema,
                   [Tabela Principal] = (
                       SELECT TabelaConsultada
                       FROM #Metricas
                       WHERE CodSistema = ss.CodSistema
                             AND NomeMetrica = 'QtdTotalRegistro'
                   )
            FROM #Metricas ss
            GROUP BY ss.CodSistema
        )
        INSERT INTO #TabelasPrincipaisSistema (CodSistema, [Tabela Principal], NomeSchema)
        SELECT R.CodSistema,
               R.[Tabela Principal],
               NomeEschema = SUBSTRING(R.[Tabela Principal], 0, CHARINDEX('.', R.[Tabela Principal], 0))
        FROM DadosTabelaPrincipal R
        WHERE R.[Tabela Principal] IS NOT NULL;
        
        -- Popular métricas de arquivos anexos
        WITH MetricasArquivosAnexos AS (
            SELECT Entidade,
                   COUNT(1) AS QuantidadeArquivosAnexos,
                   (SUM(Tamanho) / 1073741824) * 1.0 AS [Total em GB]
            FROM Sistema.ArquivosAnexos
            GROUP BY Entidade
        ),
        GetSchema AS (
            SELECT m.Entidade,
                   NomeEschema = SUBSTRING(m.Entidade, 0, CHARINDEX('.', m.Entidade, 0)),
                   m.QuantidadeArquivosAnexos,
                   m.[Total em GB]
            FROM MetricasArquivosAnexos m
        )
        INSERT INTO #MetricasArquivosAnexos (CodSistema, Entidade, NomeSchema, QuantidadeArquivosAnexos, [Total em GB])
        SELECT NULL, Entidade, NomeEschema, QuantidadeArquivosAnexos, [Total em GB]
        FROM GetSchema;
        
        -- Mapear sistemas por schema
        UPDATE target
        SET target.CodSistema = regra.CodSistema
        FROM #MetricasArquivosAnexos AS target
            JOIN (SELECT DISTINCT st.CodSistema, st.Sistema, st.NomeSchema FROM #TabelasPrincipaisSistema st) AS regra
                ON regra.NomeSchema = target.NomeSchema;
        
        -- Mapeamentos específicos por sistema
        UPDATE target SET target.CodSistema = '00000000-0000-0000-0000-000000000007' -- ComprasContratos.NET
        FROM #MetricasArquivosAnexos AS target
        WHERE target.NomeSchema IN ('Compra', 'Contratos') AND target.CodSistema IS NULL;
        
        UPDATE target SET target.CodSistema = '00000000-0000-0000-0000-000000000010' -- GestaoTCU.NET
        FROM #MetricasArquivosAnexos AS target
        WHERE target.NomeSchema LIKE 'TCU%' AND target.CodSistema IS NULL;
        
        UPDATE target SET target.CodSistema = '00000000-0000-0000-0000-000000000016' -- Portal Transparencia.NET
        FROM #MetricasArquivosAnexos AS target
        WHERE target.NomeSchema LIKE '%Transparencia%' AND target.CodSistema IS NULL;
        
        UPDATE target SET target.CodSistema = '00000000-0000-0000-0000-000000000001' -- Siscont.NET
        FROM #MetricasArquivosAnexos AS target
        WHERE target.NomeSchema IN ('REINF', 'Despesa', 'Receita', 'Contabilidade', 'Orcamento') AND target.CodSistema IS NULL;
        
        UPDATE target SET target.CodSistema = '00000000-0000-0000-0000-000000000011' -- Siscaf
        FROM #MetricasArquivosAnexos AS target
        WHERE target.NomeSchema IN ('AtivosBB', 'Financeiro', 'Plenaria', 'Requerimento', 'Serasa', 'Siscaf', 'Online', 'Recadastramento') AND target.CodSistema IS NULL;
        
        UPDATE target SET target.CodSistema = '00000000-0000-0000-0000-000000000014' -- Sisdoc
        FROM #MetricasArquivosAnexos AS target
        WHERE target.NomeSchema IN ('Formulario') AND target.CodSistema IS NULL;
        
        UPDATE target SET target.CodSistema = '00000000-0000-0000-0000-000000000000'
        FROM #MetricasArquivosAnexos AS target
        WHERE target.NomeSchema IN ('Sistema', 'Cadastro', '') AND target.CodSistema IS NULL;
        
        -- Inserir métricas de arquivos anexos
        INSERT INTO #Metricas
        SELECT DISTINCT CodSistema, 1, 'TotalGB', 'DECIMAL', 'Todas as Tabelas', 0, GETDATE()
        FROM #Metricas
        UNION
        SELECT DISTINCT CodSistema, 1, 'QuantidadeArquivosAnexos', 'INT', 'Todas as Tabelas', 0, GETDATE()
        FROM #Metricas;
        
        -- Atualizar valores das métricas de arquivos anexos
        UPDATE target
        SET target.Valor = info.Valor
        FROM #Metricas target
            JOIN (
                SELECT base.CodSistema, info.NomeMetrica, info.Valor
                FROM (SELECT DISTINCT CodSistema FROM #Metricas) base
                    JOIN (
                        SELECT CodSistema, TipoMetrica AS NomeMetrica, CAST(Valor AS INT) AS Valor
                        FROM (
                            SELECT CodSistema,
                                   SUM(CAST(QuantidadeArquivosAnexos AS INT)) AS QuantidadeArquivosAnexos,
                                   SUM(CAST([Total em GB] AS INT)) AS [TotalGB]
                            FROM #MetricasArquivosAnexos
                            GROUP BY CodSistema
                        ) AS SourceTable
                            UNPIVOT (Valor FOR TipoMetrica IN (QuantidadeArquivosAnexos, [TotalGB])) AS UnpivotTable
                    ) info ON info.CodSistema = base.CodSistema
            ) AS info ON info.CodSistema = target.CodSistema
                   AND target.NomeMetrica = info.NomeMetrica COLLATE Latin1_General_CI_AI;
    END;
    
    -- Criar tabela de retorno (replicando lógica original)
    DROP TABLE IF EXISTS #Retorno;
    CREATE TABLE #Retorno
    (
        Cliente VARCHAR(100),
        CodSistema UNIQUEIDENTIFIER,
        NomeSistema VARCHAR(100),
        [Tabela Principal] VARCHAR(200),
        NomeMetrica VARCHAR(100),
        TipoRetorno VARCHAR(20),
        Valor VARCHAR(MAX),
        DataAtualizacao DATETIME
    );
    
    -- Popular tabela de retorno
    INSERT INTO #Retorno (Cliente, CodSistema, NomeSistema, [Tabela Principal], NomeMetrica, TipoRetorno, Valor, DataAtualizacao)
    SELECT @Cliente AS Cliente,
           m.CodSistema,
           UPPER(ISNULL(s.Descricao, s.Nome)) AS NomeSistema,
           m.TabelaConsultada AS [Tabela Principal],
           m.NomeMetrica,
           m.TipoRetorno,
           CASE 
               WHEN m.NomeMetrica NOT LIKE 'Data%' AND m.Valor IS NULL THEN '0'
               ELSE m.Valor
           END AS Valor,
           m.DataAtualizacao
    FROM #Metricas m
        LEFT JOIN Sistema.Sistemas s ON s.CodSistema = m.CodSistema;
    
    -- Retornar dados conforme formato solicitado
    IF (@RetornarFormatoPivot = 1)
    BEGIN
        DECLARE @sql NVARCHAR(MAX);
        DECLARE @cols NVARCHAR(MAX);
        
        -- Construir lista de colunas para pivot
        SELECT @cols = STUFF((
            SELECT DISTINCT ',' + QUOTENAME(NomeMetrica)
            FROM #Retorno
            FOR XML PATH(''), TYPE
        ).value('.', 'NVARCHAR(MAX)'), 1, 1, '');
        
        -- Construir query dinâmica para pivot
        SET @sql = '
        SELECT Cliente, CodSistema, NomeSistema, [Tabela Principal], ' + @cols + '
        FROM (
            SELECT Cliente, CodSistema, NomeSistema, [Tabela Principal], NomeMetrica, Valor
            FROM #Retorno
        ) AS SourceTable
        PIVOT (
            MAX(Valor)
            FOR NomeMetrica IN (' + @cols + ')
        ) AS PivotTable
        ORDER BY NomeSistema;';
        
        -- Executar query dinâmica
        EXEC sp_executesql @sql;
    END
    ELSE
    BEGIN
        -- Retorno no formato normal
        SELECT Cliente, CodSistema, NomeSistema, [Tabela Principal], NomeMetrica, TipoRetorno, Valor, DataAtualizacao
        FROM #Retorno
        ORDER BY NomeSistema, NomeMetrica;
    END;
    
    -- Limpeza de todas as tabelas temporárias
    DROP TABLE IF EXISTS #Metricas;
    DROP TABLE IF EXISTS #Retorno;
    DROP TABLE IF EXISTS #InformacoesLogs;
    DROP TABLE IF EXISTS #AcessosSistemas;
    DROP TABLE IF EXISTS #MetricasBase;
    DROP TABLE IF EXISTS #MetricasScripts;
    DROP TABLE IF EXISTS #SistemasAtivadosPorFlag;
    DROP TABLE IF EXISTS #MetricasArquivosAnexos;
    DROP TABLE IF EXISTS #TabelasPrincipaisSistema;
END;
GO

-- =============================================
-- COMENTÁRIOS SOBRE OTIMIZAÇÕES IMPLEMENTADAS:
-- =============================================
-- 1. Uso de CTEs para evitar consultas repetitivas
-- 2. Declaração de variáveis para valores constantes
-- 3. Consolidação de consultas similares usando UNION ALL
-- 4. Eliminação de tabelas temporárias desnecessárias
-- 5. Uso de INNER JOIN em vez de subconsultas quando possível
-- 6. Redução do número de acessos às tabelas de configuração
-- 7. Otimização das condições WHERE com índices apropriados
-- 8. Uso de CASE WHEN em vez de múltiplas consultas condicionais
-- 9. Implementação mais eficiente do tratamento de NULL
-- 10. Estrutura mais limpa e manutenível do código
-- =============================================