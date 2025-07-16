SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
--exec HealthCheck.GetMetricasSistema 

--rgprd-sqlsrv-prd01.database.windows.net
--cro-sp.implanta.net.br
--implanta

--EXEC HealthCheck.GetMetricasSistema @RecuperarInformacoesArquivosAnexos = 1, -- bit
--                                    @RecuperarDataUltimoCadastroSistema = 1, -- bit
--                                    @RecuperarTodasMetricas = 1,             -- bit
--                                    @RetornarFormatoPivot = 0                -- bit

---- GO

CREATE OR ALTER PROCEDURE HealthCheck.GetMetricasSistema
    (
        @RecuperarInformacoesArquivosAnexos BIT = 1,
        @RecuperarDataUltimoCadastroSistema BIT = 1,
        @RecuperarTodasMetricas             BIT = 1,
        @RetornarFormatoPivot               BIT = 0
    )
AS
    BEGIN
        --DECLARE @RecuperarInformacoesArquivosAnexos BIT = 1;
        --DECLARE @RecuperarDataUltimoCadastroSistema BIT = 1;
        --DECLARE @RecuperarTodasMetricas BIT = 1;
        --DECLARE @RetornarFormatoPivot BIT = 0;
        --DECLARE @Sistema UNIQUEIDENTIFIER = '00000000-0000-0000-0000-000000000099';


        DROP TABLE IF EXISTS #Metricas;

        CREATE TABLE #Metricas
            (
                Id               INT              NOT NULL IDENTITY(1, 1),
                CodSistema       UNIQUEIDENTIFIER NOT NULL,
                Ordem            TINYINT          NOT NULL,
                NomeMetrica      VARCHAR(50),
                TipoRetorno      VARCHAR(20),
                TabelaConsultada VARCHAR(128),
                Valor            VARCHAR(MAX),
                DataAtualizacao  DATETIME2(2),
                PRIMARY KEY (CodSistema, NomeMetrica)
            );

        DROP TABLE IF EXISTS #MetricasArquivosAnexos;

        CREATE TABLE #MetricasArquivosAnexos
            (
                CodSistema                 UNIQUEIDENTIFIER,
                [Entidade]                 VARCHAR(250),
                NomeSchema                 VARCHAR(200),
                [QuantidadeArquivosAnexos] INT,
                [Total em GB]              DECIMAL(18, 2)
            );

        DROP TABLE IF EXISTS #InformacoesLogs;

        CREATE TABLE #InformacoesLogs
            (
                CodSistema                   UNIQUEIDENTIFIER NOT NULL,
                [Entidade]                   VARCHAR(128),
                [NomeSchema]                 VARCHAR(128),
                [DataUltimoRegistroInserido] DATETIME2(2),
                TotalInseridoAno             INT
            );



        IF (@RecuperarDataUltimoCadastroSistema = 1)
            BEGIN
                INSERT INTO #InformacoesLogs
                            SELECT
                                    se.CodSistema,
                                    Entidade,
                                    SUBSTRING(Entidade, 0, CHARINDEX('.', Entidade, 0)) AS NomeSchema,
                                    MAX(Data)                                           AS DataUltimoRegistroInserido,
                                    COUNT(1)                                            AS TotalInseridoAno
                            FROM
                                    Log.LogsJson                  lj
                                JOIN
                                    Sistema.SistemasEspelhamentos se
                                        ON se.IdSistemaEspelhamento = lj.IdSistemaEspelhamento
                            WHERE
                                    Acao = 'I'
                            GROUP BY
                                    se.CodSistema,
                                    Entidade,
                                    SUBSTRING(Entidade, 0, CHARINDEX('.', Entidade, 0))
                            ORDER BY
                                    Entidade;
            END;



        DROP TABLE IF EXISTS #AcessosSistemas;

        CREATE TABLE #AcessosSistemas
            (
                [CodSistema] UNIQUEIDENTIFIER,
                [Ano]        INT,
                [Mes]        INT,
                [Total]      INT
            );

        DROP TABLE IF EXISTS #MetricasBase;

        CREATE TABLE #MetricasBase
            (
                CodSistema       UNIQUEIDENTIFIER NOT NULL PRIMARY KEY,
                Ordem            TINYINT          NOT NULL
                    DEFAULT (1),
                DataUltimoAcesso DATETIME2(2)     NULL,
                QtdAcessos       INT              NOT NULL,
                QtdAcessosNoAno  INT              NOT NULL,
                PossueLicenca    BIT
            );
        INSERT INTO #MetricasBase
            (
                [CodSistema],
                [DataUltimoAcesso],
                [QtdAcessos],
                [QtdAcessosNoAno],
                PossueLicenca
            )
                    SELECT
                            s.CodSistema,
                            Acesso.DataUltimoAcesso,
                            ISNULL(Acesso.QtdAcessos, 0)      AS QtdAcessos,
                            ISNULL(Acesso.QtdAcessosNoAno, 0) AS QtdAcessosNoAno,
                            ISNULL(
                                (
                                    SELECT TOP 1
                                           IIF(Valor IS NOT NULL AND LEN(Valor) > 0, 1, 0)
                                    FROM
                                           Sistema.Configuracoes
                                    WHERE
                                           Modulo = 'Global'
                                           AND Configuracao LIKE 'Licenca%'
                                           AND REPLACE(
                                                          REPLACE(
                                                                     REPLACE(
                                                                                REPLACE(REPLACE(Nome, '.NET', ''), ' ', ''),
                                                                                '&', ''
                                                                            ), 'ção', 'cao'
                                                                 ), 'NET', ''
                                                      ) LIKE '%' + REPLACE(REPLACE(Configuracao, 'Licenca', ''), 'NET', '')
                                                             + '%'
                                ), 0
                                  )                           AS PossueLicenca
                    FROM
                            Sistema.Sistemas s
                        LEFT JOIN
                            (
                                SELECT
                                        AcessoGeral.IdSistema,
                                        AcessoGeral.DataUltimoAcesso,
                                        ISNULL(AcessoGeral.QtdAcessos, 0)             QtdAcessos,
                                        ISNULL(AcessoPorExercicio.QtdAcessosNoAno, 0) QtdAcessosNoAno
                                FROM
                                        (
                                            SELECT
                                                stotal.IdSistema,
                                                MAX(stotal.DataUltimoRequest) AS DataUltimoAcesso,
                                                COUNT(1)                      AS QtdAcessos
                                            FROM
                                                Acesso.Sessoes stotal
                                            GROUP BY
                                                stotal.IdSistema
                                        ) AS AcessoGeral
                                    LEFT JOIN
                                        (
                                            SELECT
                                                sinterno.IdSistema,
                                                COUNT(1) QtdAcessosNoAno
                                            FROM
                                                Acesso.Sessoes sinterno
                                            WHERE
                                                YEAR(sinterno.DataInicio) = YEAR(GETDATE())
                                            GROUP BY
                                                sinterno.IdSistema
                                        ) AcessoPorExercicio
                                            ON AcessoPorExercicio.IdSistema = AcessoGeral.IdSistema
                            )                Acesso
                                ON Acesso.IdSistema = s.CodSistema
                    --               WHERE 
                    --(s.CodSistema  = @Sistema OR @Sistema IS NULL)
                    ORDER BY
                            s.CodSistema;




        DECLARE @UtilizaCentroCustoPagamento BIT = CAST(
                                                       (
                                                           SELECT
                                                               c.Valor
                                                           FROM
                                                               Sistema.Configuracoes c
                                                           WHERE
                                                               c.Configuracao = 'UtilizaCentroCustoPagamento'
                                                               AND Ano = YEAR(GETDATE())
                                                       ) AS BIT);



        DECLARE @OrcamentoPorCentroCusto BIT = CAST(
                                                   (
                                                       SELECT TOP 1
                                                              Valor
                                                       FROM
                                                              Sistema.Configuracoes c
                                                       WHERE
                                                              c.Configuracao = 'OrcamentoPorCentroCusto'
                                                              AND Ano = YEAR(GETDATE())
                                                   ) AS BIT);




        ----Modulos que são caracterizados como sistema
        INSERT INTO #MetricasBase
            (
                CodSistema,
                PossueLicenca,
                DataUltimoAcesso,
                QtdAcessos,
                QtdAcessosNoAno
            )
                    SELECT
                        '00000000-0000-0000-0000-000000000099' AS CodSistema,
                        IIF(
                               (
                                   SELECT TOP 1
                                          1
                                   FROM
                                          Sistema.Configuracoes AS C
                                   WHERE
                                          C.Configuracao = 'LicencaCentroCustos'
                                          AND LEN(TRIM(C.Valor)) > 1
                               ) = 1,
                               1,
                               0)                              AS PossueLicenca,
                        CASE
                            WHEN @OrcamentoPorCentroCusto = 1
                                 OR @UtilizaCentroCustoPagamento = 1
                                THEN
                                (
                                    SELECT
                                        MAX(ep.DataUltimoAcesso)
                                    FROM
                                        #MetricasBase ep
                                    WHERE
                                        ep.CodSistema = '00000000-0000-0000-0000-000000000001'
                                )
                            ELSE
                                NULL
                        END                                    AS DataUltimoAcesso,
                        CASE
                            WHEN @OrcamentoPorCentroCusto = 1
                                 OR @UtilizaCentroCustoPagamento = 1
                                THEN
                                (
                                    SELECT
                                        QtdAcessos
                                    FROM
                                        #MetricasBase
                                    WHERE
                                        CodSistema = '00000000-0000-0000-0000-000000000001'
                                )
                            ELSE
                                0
                        END                                    AS QtdAcessos,
                        CASE
                            WHEN @OrcamentoPorCentroCusto = 1
                                 OR @UtilizaCentroCustoPagamento = 1
                                THEN
                                (
                                    SELECT
                                        QtdAcessosNoAno
                                    FROM
                                        #MetricasBase
                                    WHERE
                                        CodSistema = '00000000-0000-0000-0000-000000000001'
                                )
                            ELSE
                                0
                        END                                    AS QtdAcessosNoAno;


        /*Sistemas que são ativados por configuração e não por licenciamento*/

        DROP TABLE IF EXISTS #SistemasAtivadosPorFlag;
        CREATE TABLE #SistemasAtivadosPorFlag
            (
                [CodSistema]       UNIQUEIDENTIFIER,
                [DataUltimoAcesso] DATETIME2(2),
                [QtdAcessos]       INT,
                [QtdAcessosNoAno]  INT,
                [PossueLicenca]    INT
            );


        WITH InfoSOnline
        AS (   SELECT
                   '00000000-0000-0000-0000-000000000018' AS CodSistema, --Servicos Online
                   MAX(DataAcesso)                        AS DataUltimoAcesso,
                   COUNT(1)                               AS QtdAcessos,
                   (
                       SELECT
                           COUNT(1) AS QtdAcessosNoAno
                       FROM
                           Online.Acessos
                       WHERE
                           YEAR(DataAcesso) = YEAR(GETDATE())
                   )                                      AS QtdAcessosNoAno,
                   (
                       SELECT
                           ISNULL(IIF(Valor = 'true', 1, 0), 0)
                       FROM
                           Sistema.Configuracoes
                       WHERE
                           Configuracao = 'AcessoServicoOnlineSiscaf'
                   )                                      AS PossueLicenca
               FROM
                   Online.Acessos)
        INSERT INTO #SistemasAtivadosPorFlag
                    SELECT
                        *
                    FROM
                        InfoSOnline;


        UPDATE
                target
        SET
                target.DataUltimoAcesso = Info.DataUltimoAcesso,
                target.QtdAcessos = Info.QtdAcessos,
                target.QtdAcessosNoAno = Info.QtdAcessosNoAno,
                target.PossueLicenca = Info.PossueLicenca
        FROM
                #MetricasBase            AS target
            JOIN
                #SistemasAtivadosPorFlag Info
                    ON Info.CodSistema = target.CodSistema;



        DROP TABLE IF EXISTS #MetricasScripts;

        CREATE TABLE #MetricasScripts
            (
                CodSistema       UNIQUEIDENTIFIER NOT NULL,
                Ordem            TINYINT          NOT NULL
                    DEFAULT (2),
                NomeMetrica      VARCHAR(200),
                TipoRetorno      VARCHAR(30),
                TabelaConsultada VARCHAR(200),
                Script           VARCHAR(MAX)
            );


        INSERT INTO #MetricasScripts
            (
                CodSistema,
                NomeMetrica,
                TipoRetorno,
                TabelaConsultada,
                Script
            )
        VALUES
            --- 'Centro de Custos.NET
            (
                '00000000-0000-0000-0000-000000000099', 'DataUltimoRegistro', -- Nome - varchar(200)
                'DATETIME',                                                   -- TipoRetorno - varchar(30)
                '',                                                           -- TabelaConsultada
                'SELECT CASE  
		WHEN (CAST((SELECT TOP 1 Valor FROM Sistema.Configuracoes c
                         WHERE c.Configuracao = ''OrcamentoPorCentroCusto''
                               AND Ano = YEAR(GETDATE()) ) AS BIT)) = 0
			THEN NULL 
       WHEN  (CAST((SELECT TOP 1 Valor FROM Sistema.Configuracoes c
                         WHERE c.Configuracao = ''OrcamentoPorCentroCusto''
                               AND Ano = YEAR(GETDATE()) ) AS BIT)) = 1 
	   AND (CAST( ( SELECT TOP 1 Valor FROM Sistema.Configuracoes c
                     WHERE c.Configuracao = ''UtilizaCentroCustoPagamento''
                           AND Ano = YEAR(GETDATE()) ) AS BIT) = 1)
                
			THEN
           (
               SELECT MAX(p.DataCadastro)
               FROM Despesa.PagamentosCentroCustos pcc
                   JOIN Despesa.Pagamentos p
                       ON p.IdPagamento = pcc.IdPagamento
           )
		ELSE  
		(
               SELECT MAX(c.DataCadastro)
               FROM Despesa.EmpenhosCentroCustos ecc
                   JOIN Despesa.Empenhos c
                       ON c.IdEmpenho = ecc.IdEmpenho
           )
       END'
            ),
            (
                '00000000-0000-0000-0000-000000000099', 'QtdTotalRegistro', -- Nome - varchar(200)
                'INT',                                                      -- TipoRetorno - varchar(30)
                'Despesa.CentroCustos',
                'SELECT COUNT(1) FROM   Despesa.CentroCustos WHERE IdCentroCusto <> ''00000000-0000-0000-0000-000000000001'''
            ),
            (
                '00000000-0000-0000-0000-000000000099', 'QtdRegistroAno', -- Nome - varchar(200)
                'INT',                                                    -- TipoRetorno - varchar(30)
                '',
                'SELECT CASE  
		WHEN (CAST((SELECT TOP 1 Valor FROM Sistema.Configuracoes c
                         WHERE c.Configuracao = ''OrcamentoPorCentroCusto''
                               AND Ano = YEAR(GETDATE()) ) AS BIT)) = 0
			THEN 0 
       WHEN  (CAST((SELECT TOP 1 Valor FROM Sistema.Configuracoes c
                         WHERE c.Configuracao = ''OrcamentoPorCentroCusto''
                               AND Ano = YEAR(GETDATE()) ) AS BIT)) = 1 
	   AND (CAST( ( SELECT TOP 1 Valor FROM Sistema.Configuracoes c
                     WHERE c.Configuracao = ''UtilizaCentroCustoPagamento''
                           AND Ano = YEAR(GETDATE()) ) AS BIT) = 1)
                
			THEN
           (
               SELECT COUNT(1)
               FROM Despesa.PagamentosCentroCustos pcc
                   JOIN Despesa.Pagamentos p
                       ON p.IdPagamento = pcc.IdPagamento
					   WHERE YEAR(p.DataCadastro) = YEAR(p.DataCadastro)
           )
		ELSE  
		(
               SELECT COUNT(1)
               FROM Despesa.EmpenhosCentroCustos ecc
                   JOIN Despesa.Empenhos e
                       ON e.IdEmpenho = ecc.IdEmpenho
					   WHERE YEAR(e.DataCadastro) = YEAR(e.DataCadastro)
           )
       END'
            ),

            --SISCONT.NET
            (
                '00000000-0000-0000-0000-000000000001', 'UtilizaGestaoDevedores78', -- Nome - varchar(200)
                'BIT',                                                              -- TipoRetorno - varchar(30),
                'Contabilidade.Movimentos',
                'ISNULL(cast((  SELECT TOP 1 1 FROM Contabilidade.Lancamentos p
JOIN Contabilidade.Movimentos  m ON m.IdLancamento = p.IdLancamento
JOIN Contabilidade.PlanoContas pc ON pc.IdPlanoConta = m.IdPlanoConta
WHERE pc.Codigo LIKE ''[78].%'') AS bit ),0)'                                       -- Script - varchar(max)
            ),
            (
                '00000000-0000-0000-0000-000000000001', 'QtdLancamentosGestaoDevedores78', -- Nome - varchar(200)
                'BIT',                                                                     -- TipoRetorno - varchar(30),
                'Contabilidade.Movimentos',
                'ISNULL(cast((  SELECT TOP 1 1 FROM Contabilidade.Lancamentos p
JOIN Contabilidade.Movimentos  m ON m.IdLancamento = p.IdLancamento
JOIN Contabilidade.PlanoContas pc ON pc.IdPlanoConta = m.IdPlanoConta
WHERE pc.Codigo LIKE ''[78].%'' AND YEAR(p.Data) = YEAR(GETDATE())) AS bit ),0)'           -- Script - varchar(max)
            ),
            (
                '00000000-0000-0000-0000-000000000001', 'UtilizaCentroCustoPagamento',                                                                                         -- Nome - varchar(200)
                'BIT',                                                                                                                                                         -- TipoRetorno - varchar(30),
                'sistema.configuracoes',
                'ISNULL(cast( (  SELECT top 1 Valor from sistema.configuracoes c WHERE c.Configuracao =''UtilizaCentroCustoPagamento'' AND Ano = YEAR(GETDATE())) as BIT ),0)' -- Script - varchar(max)
            ),
            (
                '00000000-0000-0000-0000-000000000001', 'OrcamentoPorCentroCusto',                                                                                         -- Nome - varchar(200)
                'BIT',                                                                                                                                                     -- TipoRetorno - varchar(30)
                'sistema.configuracoes',
                'ISNULL(cast( (  SELECT top 1 Valor from sistema.configuracoes c WHERE c.Configuracao =''OrcamentoPorCentroCusto'' AND Ano = YEAR(GETDATE())) as BIT ),0)' -- Script - varchar(max)
            ),
            (
                '00000000-0000-0000-0000-000000000001', 'DataUltimoRegistro',                          -- Nome - varchar(200)
                'DATETIME',                                                                            -- TipoRetorno - varchar(30)
                'Contabilidade.Lancamentos', 'SELECT MAX(DataCadastro) FROM Contabilidade.Lancamentos' -- Script - varchar(max)
            ),
            (
                '00000000-0000-0000-0000-000000000001', 'QtdTotalRegistro',                   -- Nome - varchar(200)
                'INT',                                                                        -- TipoRetorno - varchar(30)
                'Contabilidade.Lancamentos', 'SELECT Count(1) FROM Contabilidade.Lancamentos' -- Script - varchar(max)
            ),
            (
                '00000000-0000-0000-0000-000000000001', 'QtdRegistroAno',                                     -- Nome - varchar(200)
                'INT',                                                                                        -- TipoRetorno - varchar(30)
                'Contabilidade.Lancamentos',
                'SELECT Count(1) FROM Contabilidade.Lancamentos where  YEAR(DataCadastro) = YEAR(GETDATE()) ' -- Script - varchar(max)
            ),
            (
                '00000000-0000-0000-0000-000000000001', 'QtdPagamentos', -- Nome - varchar(200)
                'INT',                                                   -- TipoRetorno - varchar(30)
                'despesa.pagamentos', 'SELECT COUNT(1) FROM Despesa.Pagamentos'
            ),
            (
                '00000000-0000-0000-0000-000000000001', 'QtdPagamentosNoAno', -- Nome - varchar(200)
                'INT',                                                        -- TipoRetorno - varchar(30)
                'despesa.pagamentos',
                'SELECT COUNT(1) FROM Despesa.Pagamentos s WHERE YEAR(s.DataPagamento) = YEAR(GETDATE())'
            ),
            (
                '00000000-0000-0000-0000-000000000001', 'UtilizaConciliacaoBancaria', -- Nome - varchar(200)
                'BIT',                                                                -- TipoRetorno - varchar(30)
                'despesa.conciliacoesbancarias',
                'ISNULL(cast( (  SELECT top 1 1 FROM Despesa.ConciliacoesBancarias ) AS BIT),0) '
            ),
            (
                '00000000-0000-0000-0000-000000000001', 'QtdConciliacaoBancariaAno', -- Nome - varchar(200)
                'INT',                                                               -- TipoRetorno - varchar(30)
                'despesa.conciliacoesbancarias',
                'SELECT COUNT(1) FROM Despesa.ConciliacoesBancarias WHERE YEAR(DataConciliacao) =YEAR(GETDATE())'
            ),
            --- 'PCS.NET
            (
                '00000000-0000-0000-0000-000000000003', 'DataUltimoRegistro', -- Nome - varchar(200)
                'DATETIME',                                                   -- TipoRetorno - varchar(30)
                'PCS.Despesas', 'SELECT MAX(DataDespesa) FROM   PCS.Despesas'
            ),
            (
                '00000000-0000-0000-0000-000000000003', 'QtdTotalRegistro', -- Nome - varchar(200)
                'INT',                                                      -- TipoRetorno - varchar(30)
                'PCS.Despesas', 'SELECT COUNT(1) FROM   PCS.Despesas'
            ),
            (
                '00000000-0000-0000-0000-000000000003', 'QtdRegistroAno', -- Nome - varchar(200)
                'INT',                                                    -- TipoRetorno - varchar(30)
                'PCS.Despesas', 'SELECT COUNT(1) FROM   PCS.Despesas  WHERE  YEAR(DataDespesa)  = YEAR(GETDATE())'
            ),

            --- 'Sispat.NET
            (
                '00000000-0000-0000-0000-000000000004', 'DataUltimoRegistro', -- Nome - varchar(200)
                'DATETIME',                                                   -- TipoRetorno - varchar(30)
                'Patrimonio.BensMoveis', 'SELECT MAX(DataCadastro) FROM   Patrimonio.BensMoveis'
            ),
            (
                '00000000-0000-0000-0000-000000000004', 'QtdTotalRegistro', -- Nome - varchar(200)
                'INT',                                                      -- TipoRetorno - varchar(30)
                'Patrimonio.BensMoveis', 'SELECT COUNT(1) FROM   Patrimonio.BensMoveis'
            ),
            (
                '00000000-0000-0000-0000-000000000004', 'QtdRegistroAno', -- Nome - varchar(200)
                'INT',                                                    -- TipoRetorno - varchar(30)
                'Patrimonio.BensMoveis',
                'SELECT COUNT(1) FROM   Patrimonio.BensMoveis WHERE  YEAR(DataCadastro)  = YEAR(GETDATE())'
            ),
            --- 'Agenda Financeira.NET
            (
                '00000000-0000-0000-0000-000000000005', 'DataUltimoRegistro', -- Nome - varchar(200)
                'DATETIME',                                                   -- TipoRetorno - varchar(30)
                'Agenda.LancamentosFinanceiros',
                ' SELECT MAX(LancamentosFinanceiros.DataModificacao) FROM   Agenda.LancamentosFinanceiros'
            ),
            (
                '00000000-0000-0000-0000-000000000005', 'QtdTotalRegistro', -- Nome - varchar(200)
                'INT',                                                      -- TipoRetorno - varchar(30)
                'Agenda.LancamentosFinanceiros', 'SELECT COUNT(1) FROM   Agenda.LancamentosFinanceiros'
            ),
            (
                '00000000-0000-0000-0000-000000000005', 'QtdRegistroAno', -- Nome - varchar(200)
                'INT',                                                    -- TipoRetorno - varchar(30)
                'Agenda.LancamentosFinanceiros',
                'SELECT COUNT(1) FROM   Agenda.LancamentosFinanceiros WHERE  YEAR(DataModificacao)  = YEAR(GETDATE())'
            ),
            ---Sialm.NET
            (
                '00000000-0000-0000-0000-000000000006', 'DataUltimoRegistro', -- Nome - varchar(200)
                'DATETIME',                                                   -- TipoRetorno - varchar(30)
                'Almoxarifado.Movimentacoes', 'SELECT MAX(DataCriacao) FROM   Almoxarifado.Movimentacoes'
            ),
            (
                '00000000-0000-0000-0000-000000000006', 'QtdTotalRegistro', -- Nome - varchar(200)
                'INT',                                                      -- TipoRetorno - varchar(30)
                'Almoxarifado.Movimentacoes', 'SELECT COUNT(1) FROM   Almoxarifado.Movimentacoes'
            ),
            (
                '00000000-0000-0000-0000-000000000006', 'QtdRegistroAno', -- Nome - varchar(200)
                'INT',                                                    -- TipoRetorno - varchar(30)
                'Almoxarifado.Movimentacoes',
                'SELECT COUNT(1) FROM   Almoxarifado.Movimentacoes WHERE  YEAR(DataCriacao)  = YEAR(GETDATE())'
            ),


            ---ComprasContratos.NET (Revisar) -LEO
            (
                '00000000-0000-0000-0000-000000000007', 'DataUltimoRegistro', -- Nome - varchar(200)
                'DATETIME',                                                   -- TipoRetorno - varchar(30)
                'Contrato.Contratos', 'SELECT MAX( DataPublicacao) FROM   Contrato.Contratos'
            ),
            (
                '00000000-0000-0000-0000-000000000007', 'QtdTotalRegistro', -- Nome - varchar(200)
                'INT',                                                      -- TipoRetorno - varchar(30)
                'Contrato.Contratos', 'SELECT COUNT(1) FROM   Contrato.Contratos'
            ),
            (
                '00000000-0000-0000-0000-000000000007', 'QtdRegistroAno', -- Nome - varchar(200)
                'INT',                                                    -- TipoRetorno - varchar(30)
                'Contrato.Contratos',
                'SELECT COUNT(1) FROM   Contrato.Contratos  WHERE  YEAR(DataPublicacao)  = YEAR(GETDATE())'
            ),


            ---Sispad.NET
            (
                '00000000-0000-0000-0000-000000000008', 'DataUltimoRegistro', -- Nome - varchar(200)
                'DATETIME',                                                   -- TipoRetorno - varchar(30)
                'Viagem.SolicitacoesPessoas', 'SELECT MAX(DataIda) FROM   Viagem.SolicitacoesPessoas'
            ),
            (
                '00000000-0000-0000-0000-000000000008', 'QtdTotalRegistro', -- Nome - varchar(200)
                'INT',                                                      -- TipoRetorno - varchar(30)
                'Viagem.SolicitacoesPessoas', 'SELECT COUNT(IdSolicitacaoPessoa) FROM   Viagem.SolicitacoesPessoas'
            ),
            (
                '00000000-0000-0000-0000-000000000008', 'QtdRegistroAno', -- Nome - varchar(200)
                'INT',                                                    -- TipoRetorno - varchar(30)
                'Viagem.SolicitacoesPessoas',
                'SELECT COUNT(1) FROM   Viagem.SolicitacoesPessoas WHERE YEAR(DataIda) = YEAR(GETDATE())'
            ),

            --Licitacao.NET
            (
                '00000000-0000-0000-0000-000000000009', 'DataUltimoRegistro', -- Nome - varchar(200)
                'DATETIME',                                                   -- TipoRetorno - varchar(30)
                'Licitacao.Licitacoes', 'SELECT MAX(Data) FROM   Licitacao.Licitacoes'
            ),
            (
                '00000000-0000-0000-0000-000000000009', 'QtdTotalRegistro', -- Nome - varchar(200)
                'INT',                                                      -- TipoRetorno - varchar(30)
                'Licitacao.Licitacoes', 'SELECT COUNT(1) FROM   Licitacao.Licitacoes'
            ),
            (
                '00000000-0000-0000-0000-000000000009', 'QtdRegistroAno', -- Nome - varchar(200)
                'INT',                                                    -- TipoRetorno - varchar(30)
                'Licitacao.Licitacoes',
                'SELECT COUNT(1) FROM   Licitacao.Licitacoes WHERE  YEAR(Data)  = YEAR(GETDATE())'
            ),
            --GestaoTCU   
            (
                '00000000-0000-0000-0000-000000000010', 'DataUltimoRegistro', -- Nome - varchar(200)
                'DATETIME',                                                   -- TipoRetorno - varchar(30)
                'TCU.RelatoriosTCU', 'SELECT MAX(DataGeracao) FROM   TCU.RelatoriosTCU'
            ),
            (
                '00000000-0000-0000-0000-000000000010', 'QtdTotalRegistro', -- Nome - varchar(200)
                'INT',                                                      -- TipoRetorno - varchar(30)
                'TCU.RelatoriosTCU', 'SELECT COUNT(1) FROM   TCU.RelatoriosTCU'
            ),
            (
                '00000000-0000-0000-0000-000000000010', 'QtdRegistroAno', -- Nome - varchar(200)
                'INT',                                                    -- TipoRetorno - varchar(30)
                'TCU.RelatoriosTCU',
                'SELECT COUNT(1) FROM   TCU.RelatoriosTCU WHERE  YEAR(DataGeracao)  = YEAR(GETDATE())'
            ),

            --Auditoria.NET (Revisar) -LEO
            (
                '00000000-0000-0000-0000-000000000015', 'DataUltimoRegistro', -- Nome - varchar(200)
                'DATETIME',                                                   -- TipoRetorno - varchar(30)
                'Auditoria.PrestacoesContas', 'SELECT MAX(DataCadastro) FROM   Auditoria.PrestacoesContas'
            ),
            (
                '00000000-0000-0000-0000-000000000015', 'QtdTotalRegistro', -- Nome - varchar(200)
                'INT',                                                      -- TipoRetorno - varchar(30)
                'Auditoria.PrestacoesContas', 'SELECT COUNT(1) FROM   Auditoria.PrestacoesContas'
            ),
            (
                '00000000-0000-0000-0000-000000000015', 'QtdRegistroAno', -- Nome - varchar(200)
                'INT',                                                    -- TipoRetorno - varchar(30)
                'Auditoria.PrestacoesContas',
                'SELECT COUNT(1) FROM Auditoria.PrestacoesContas WHERE  YEAR(DataCadastro)  = YEAR(GETDATE())'
            ),


            --Portal Transparencia.NET (Revisar)-LEO
            (
                '00000000-0000-0000-0000-000000000016', 'DataUltimoRegistro', -- Nome - varchar(200)
                'DATETIME',                                                   -- TipoRetorno - varchar(30)
                'Transparencia.RelatoriosConteudos', 'SELECT MAX(DataUpload) FROM   Transparencia.RelatoriosConteudos'
            ),
            (
                '00000000-0000-0000-0000-000000000016', 'QtdTotalRegistro', -- Nome - varchar(200)
                'INT',                                                      -- TipoRetorno - varchar(30)
                'Transparencia.RelatoriosConteudos', 'SELECT COUNT(1) FROM   Transparencia.RelatoriosConteudos'
            ),
            (
                '00000000-0000-0000-0000-000000000016', 'QtdRegistroAno', -- Nome - varchar(200)
                'INT',                                                    -- TipoRetorno - varchar(30)
                'Transparencia.RelatoriosConteudos',
                'SELECT COUNT(1) FROM   Transparencia.RelatoriosConteudos WHERE  YEAR(DataUpload)  = YEAR(GETDATE())'
            ),
            --Visão Nacional.NET
            (
                '00000000-0000-0000-0000-000000000017', 'DataUltimoRegistro', -- Nome - varchar(200)
                'DATETIME',                                                   -- TipoRetorno - varchar(30)
                'Nacional.RegistrosNacionais', 'SELECT MAX(DataSincronizacao) FROM   Nacional.RegistrosNacionais'
            ),
            (
                '00000000-0000-0000-0000-000000000017', 'QtdTotalRegistro', -- Nome - varchar(200)
                'INT',                                                      -- TipoRetorno - varchar(30)
                'Nacional.RegistrosNacionais', 'SELECT COUNT(1) FROM   Nacional.RegistrosNacionais'
            ),
            (
                '00000000-0000-0000-0000-000000000017', 'QtdRegistroAno', -- Nome - varchar(200)
                'INT',                                                    -- TipoRetorno - varchar(30)
                'Nacional.RegistrosNacionais',
                'SELECT COUNT(1) FROM   Nacional.RegistrosNacionais WHERE  YEAR(DataSincronizacao)  = YEAR(GETDATE())'
            ),

            -- Programas & Projetos.NET(Revisar)-LEO
            (
                '00000000-0000-0000-0000-000000000019', 'DataUltimoRegistro', -- Nome - varchar(200)
                'DATETIME',                                                   -- TipoRetorno - varchar(30)
                'projeto.projetos', 'SELECT MAX(DataCriacao) FROM  Projeto.Projetos'
            ),
            (
                '00000000-0000-0000-0000-000000000019', 'QtdTotalRegistro', -- Nome - varchar(200)
                'INT',                                                      -- TipoRetorno - varchar(30)
                'projeto.projetos', 'SELECT COUNT(1) FROM Projeto.Projetos'
            ),
            (
                '00000000-0000-0000-0000-000000000019', 'QtdRegistroAno', -- Nome - varchar(200)
                'INT',                                                    -- TipoRetorno - varchar(30)
                'projeto.projetos', 'SELECT Count(1) FROM  Projeto.Projetos WHERE YEAR(DataCriacao) = YEAR(GETDATE())'
            ),

            ---Danilo
            --SISCAF
            (
                '00000000-0000-0000-0000-000000000011', 'DataUltimoRegistro', -- Nome - varchar(200)
                'DATETIME',                                                   -- TipoRetorno - varchar(30)
                'Registro.Registros', 'SELECT MAX(R.DataCriacao) FROM   Registro.Registros AS R'
            ),
            (
                '00000000-0000-0000-0000-000000000011', 'QtdTotalRegistro', -- Nome - varchar(200)
                'INT',                                                      -- TipoRetorno - varchar(30)
                'Registro.Registros', 'SELECT COUNT(1) FROM Registro.Registros AS R'
            ),
            (
                '00000000-0000-0000-0000-000000000011', 'QtdRegistroAno', -- Nome - varchar(200)
                'INT',                                                    -- TipoRetorno - varchar(30)
                'Registro.Registros',
                'SELECT Count(1) FROM  Registro.Registros  WHERE YEAR(DataCriacao) = YEAR(GETDATE())'
            ),
            --Sisdoc.NET
            (
                '00000000-0000-0000-0000-000000000014', 'DataUltimoRegistro', -- Nome - varchar(200)
                'DATETIME',                                                   -- TipoRetorno - varchar(30)
                'Documento.Documentos', 'SELECT MAX(R.DataCriacao) FROM   Documento.Documentos AS R'
            ),
            (
                '00000000-0000-0000-0000-000000000014', 'QtdTotalRegistro', -- Nome - varchar(200)
                'INT',                                                      -- TipoRetorno - varchar(30)
                'Documento.Documentos', 'SELECT COUNT(1) FROM Documento.Documentos AS R'
            ),
            (
                '00000000-0000-0000-0000-000000000014', 'QtdRegistroAno', -- Nome - varchar(200)
                'INT',                                                    -- TipoRetorno - varchar(30)
                'Documento.Documentos',
                'SELECT Count(1) FROM  Documento.Documentos  WHERE YEAR(DataCriacao) = YEAR(GETDATE())'
            ),
            --Processos.NET
            (
                '00000000-0000-0000-0000-000000000023', 'DataUltimoRegistro', -- Nome - varchar(200)
                'DATETIME',                                                   -- TipoRetorno - varchar(30)
                'Processo.Processos', 'SELECT MAX(R.DataCriacao) FROM   Processo.Processos AS R'
            ),
            (
                '00000000-0000-0000-0000-000000000023', 'QtdTotalRegistro', -- Nome - varchar(200)
                'INT',                                                      -- TipoRetorno - varchar(30)
                'Processo.Processos', 'SELECT COUNT(1) FROM Processo.Processos AS R'
            ),
            (
                '00000000-0000-0000-0000-000000000023', 'QtdRegistroAno', -- Nome - varchar(200)
                'INT',                                                    -- TipoRetorno - varchar(30)
                'Processo.Processos',
                'SELECT Count(1) FROM Processo.Processos  WHERE YEAR(DataCriacao) = YEAR(GETDATE())'
            ),
            --Fiscalização.NET
            (
                '00000000-0000-0000-0000-000000000024', 'DataUltimoRegistro', -- Nome - varchar(200)
                'DATETIME',                                                   -- TipoRetorno - varchar(30)
                'Fiscalizacao.Visitas', 'SELECT MAX(R.DataCriacao) FROM   Fiscalizacao.Visitas AS R'
            ),
            (
                '00000000-0000-0000-0000-000000000024', 'QtdTotalRegistro', -- Nome - varchar(200)
                'INT',                                                      -- TipoRetorno - varchar(30)
                'Fiscalizacao.Visitas', 'SELECT COUNT(1) FROM Fiscalizacao.Visitas AS R'
            ),
            (
                '00000000-0000-0000-0000-000000000024', 'QtdRegistroAno', -- Nome - varchar(200)
                'INT',                                                    -- TipoRetorno - varchar(30)
                'Fiscalizacao.Visitas',
                'SELECT Count(1) FROM Fiscalizacao.Visitas  WHERE YEAR(DataCriacao) = YEAR(GETDATE())'
            );


        /*Ordem = 1 (Metricas importantes*/
        /*Ordem = 2 (Metricas detalhes de cada sistema*/
        UPDATE
            #MetricasScripts
        SET
            Ordem = 1
        FROM
            #MetricasScripts
        WHERE
            NomeMetrica IN (
                               'DataUltimoRegistro', 'QtdTotalRegistro', 'QtdRegistroAno'
                           );


        IF (@RecuperarTodasMetricas = 0)
            BEGIN
                DELETE FROM
                       #MetricasScripts
                WHERE
                    Ordem = 2;
            END;



        /*trecho para remover sistemas aindas
        CodSistema	Nome
        00000000-0000-0000-0000-000000000002	Logon
        00000000-0000-0000-0000-000000000003	PCS
        00000000-0000-0000-0000-000000000012	Siplen
        00000000-0000-0000-0000-000000000013	Cursos
        */
        DELETE FROM
               #MetricasScripts
        WHERE
            CodSistema IN (
                              '{00000000-0000-0000-0000-000000000002}', '{00000000-0000-0000-0000-000000000003}',
                              '{00000000-0000-0000-0000-000000000012}', '{00000000-0000-0000-0000-000000000013}'
                          );





        DECLARE @dataAtualizacao DATETIME = GETDATE();
        DECLARE
            @CodSistema       UNIQUEIDENTIFIER,
            @Ordem            TINYINT,
            @Nome             VARCHAR(100),
            @TipoRetorno      VARCHAR(100),
            @TabelaConsultada VARCHAR(200),
            @Script           VARCHAR(MAX);

        DECLARE cursor_InsertsMetricas CURSOR FAST_FORWARD READ_ONLY FOR
            SELECT
                CodSistema,
                Ordem,
                NomeMetrica,
                TipoRetorno,
                TabelaConsultada,
                Script
            FROM
                #MetricasScripts;


        OPEN cursor_InsertsMetricas;

        FETCH NEXT FROM cursor_InsertsMetricas
        INTO
            @CodSistema,
            @Ordem,
            @Nome,
            @TipoRetorno,
            @TabelaConsultada,
            @Script;

        WHILE @@FETCH_STATUS = 0
            BEGIN

                DECLARE @result NVARCHAR(MAX);


                DECLARE @_sql NVARCHAR(MAX) = N'SELECT @result = (' + @Script + N')';


                EXEC sp_executesql
                    @stmt = @_sql,
                    @params = N'@result VARCHAR(MAX) OUTPUT',
                    @result = @result OUTPUT;

                INSERT INTO #Metricas
                    (
                        CodSistema,
                        Ordem,
                        NomeMetrica,
                        TipoRetorno,
                        TabelaConsultada,
                        Valor,
                        DataAtualizacao
                    )
                VALUES
                    (
                        @CodSistema, @Ordem, @Nome, -- Nome - varchar(200)
                        @TipoRetorno,               -- TipoRetorno - varchar(30)
                        @TabelaConsultada,          -- TabelaConsultada - varchar(200)
                        @result,                    -- Valor - varchar(max)
                        @dataAtualizacao
                    );


                FETCH NEXT FROM cursor_InsertsMetricas
                INTO
                    @CodSistema,
                    @Ordem,
                    @Nome,
                    @TipoRetorno,
                    @TabelaConsultada,
                    @Script;

            END;

        CLOSE cursor_InsertsMetricas;
        DEALLOCATE cursor_InsertsMetricas;




        INSERT INTO #Metricas
            (
                CodSistema,
                Ordem,
                NomeMetrica,
                TipoRetorno,
                TabelaConsultada,
                Valor,
                DataAtualizacao
            )
                    SELECT
                        CodSistema,
                        Ordem,
                        'DataUltimoAcesso' AS Nome,
                        'DATETIME'         AS TipoRetorno,
                        'acesso.sessoes'   AS TabelaConsultada,
                        DataUltimoAcesso   AS Valor,
                        @dataAtualizacao   AS DataAtualizacao
                    FROM
                        #MetricasBase;


        INSERT INTO #Metricas
                    SELECT
                        CodSistema,
                        Ordem,
                        'QtdAcessos'     AS Nome,
                        'INT'            AS TipoRetorno,
                        'acesso.sessoes' AS TabelaConsultada,
                        QtdAcessos       AS Valor,
                        @dataAtualizacao AS DataAtualizacao
                    FROM
                        #MetricasBase;

        INSERT INTO #Metricas
                    SELECT
                        CodSistema,
                        Ordem,
                        'QtdAcessosNoAno' AS Nome,
                        'INT'             AS TipoRetorno,
                        'acesso.sessoes'  AS TabelaConsultada,
                        QtdAcessosNoAno   AS Valor,
                        @dataAtualizacao  AS DataAtualizacao
                    FROM
                        #MetricasBase;

        INSERT INTO #Metricas
                    SELECT
                        CodSistema,
                        ss.Ordem,
                        'PossueLicenca'         AS Nome,
                        'BIT'                   AS TipoRetorno,
                        'sistema.configuracoes' AS TabelaConsultada,
                        PossueLicenca           AS Valor,
                        @dataAtualizacao        AS DataAtualizacao
                    FROM
                        #MetricasBase ss;



        DROP TABLE IF EXISTS #TabelasPrincipaisSistema;

        CREATE TABLE #TabelasPrincipaisSistema
            (
                [CodSistema]       UNIQUEIDENTIFIER,
                Sistema            VARCHAR(100),
                [Tabela Principal] VARCHAR(200),
                NomeSchema         VARCHAR(200)
            );
        WITH DadosTabelaPrincipal
        AS (   SELECT
                   CodSistema,
                   [Tabela Principal] =
                       (
                           SELECT
                               TabelaConsultada
                           FROM
                               #Metricas
                           WHERE
                               CodSistema = ss.CodSistema
                               AND NomeMetrica = 'QtdTotalRegistro'
                       )
               FROM
                   #Metricas ss
               GROUP BY
                   ss.CodSistema)
        INSERT INTO #TabelasPrincipaisSistema
            (
                CodSistema,
                [Tabela Principal],
                NomeSchema
            )
                    SELECT
                        R.CodSistema,
                        R.[Tabela Principal],
                        NomeEschema = SUBSTRING(R.[Tabela Principal], 0, CHARINDEX('.', R.[Tabela Principal], 0))
                    FROM
                        DadosTabelaPrincipal R
                    WHERE
                        R.[Tabela Principal] IS NOT NULL;



        IF (@RecuperarInformacoesArquivosAnexos = 1)
            BEGIN

                ;WITH MetricasArquivosAnexos
                 AS (   SELECT
                            Entidade,
                            COUNT(1)                          AS QuantidadeArquivosAnexos,
                            (SUM(Tamanho) / 1073741824) * 1.0 AS [Total em GB]
                        FROM
                            Sistema.ArquivosAnexos
                        GROUP BY
                            Entidade),
                      GetSchema
                 AS (   SELECT
                            m.Entidade,
                            NomeEschema = SUBSTRING(m.Entidade, 0, CHARINDEX('.', m.Entidade, 0)),
                            m.QuantidadeArquivosAnexos,
                            m.[Total em GB]
                        FROM
                            MetricasArquivosAnexos m)
                INSERT INTO #MetricasArquivosAnexos
                    (
                        CodSistema,
                        Entidade,
                        NomeSchema,
                        QuantidadeArquivosAnexos,
                        [Total em GB]
                    )
                            SELECT
                                NULL,
                                Entidade,
                                NomeEschema,
                                QuantidadeArquivosAnexos,
                                [Total em GB]
                            FROM
                                GetSchema;


                UPDATE
                        target
                SET
                        target.CodSistema = regra.CodSistema
                FROM
                        #MetricasArquivosAnexos AS target
                    JOIN
                        (
                            SELECT DISTINCT
                                   st.CodSistema,
                                   st.Sistema,
                                   st.NomeSchema
                            FROM
                                   #TabelasPrincipaisSistema st
                            WHERE
                                   st.CodSistema <> '00000000-0000-0000-0000-000000000099' --Centro de custos
                        )                       AS regra
                            ON regra.NomeSchema = target.NomeSchema;




                UPDATE
                    target
                SET
                    target.CodSistema = '00000000-0000-0000-0000-000000000007' -- 'ComprasContratos.NET'
                FROM
                    #MetricasArquivosAnexos AS target
                WHERE
                    target.NomeSchema IN (
                                             'Compra', 'Contrato'
                                         )
                    AND target.CodSistema IS NULL;


                UPDATE
                    target
                SET
                    target.CodSistema = '00000000-0000-0000-0000-000000000010' -- 'GestaoTCU.NET'
                FROM
                    #MetricasArquivosAnexos AS target
                WHERE
                    target.NomeSchema LIKE 'TCU%'
                    AND target.CodSistema IS NULL;



                UPDATE
                    target
                SET
                    target.CodSistema = '00000000-0000-0000-0000-000000000016' --'Portal Transparencia.NET'
                FROM
                    #MetricasArquivosAnexos AS target
                WHERE
                    target.NomeSchema LIKE '%Transparencia%'
                    AND target.CodSistema IS NULL;



                UPDATE
                    target
                SET
                    target.CodSistema = '00000000-0000-0000-0000-000000000001' --'Siscont.NET'
                FROM
                    #MetricasArquivosAnexos AS target
                WHERE
                    target.NomeSchema IN (
                                             'REINF', 'Despesa', 'Receita', 'Contabilidade', 'Orcamento'
                                         )
                    AND target.CodSistema IS NULL;





                UPDATE
                    target
                SET
                    target.CodSistema = '00000000-0000-0000-0000-000000000011' --Siscaf
                FROM
                    #MetricasArquivosAnexos AS target
                WHERE
                    target.NomeSchema IN (
                                             'AtivosBB', 'Financeiro', 'Plenaria', 'Requerimento', 'Serasa', 'Siscaf',
                                             'Online', 'Recadastramento', 'Registro'
                                         )
                    AND target.CodSistema IS NULL;

                UPDATE
                    target
                SET
                    target.CodSistema = '00000000-0000-0000-0000-000000000014' --Sisdoc
                FROM
                    #MetricasArquivosAnexos AS target
                WHERE
                    target.NomeSchema IN (
                                             'Formulario'
                                         )
                    AND target.CodSistema IS NULL;


                UPDATE
                    target
                SET
                    target.CodSistema = '00000000-0000-0000-0000-000000000000'
                FROM
                    #MetricasArquivosAnexos AS target
                WHERE
                    target.NomeSchema IN (
                                             'Sistema', 'Cadastro', ''
                                         )
                    AND target.CodSistema IS NULL;



                INSERT INTO #Metricas
                            SELECT DISTINCT
                                   CodSistema,
                                   1,
                                   'TotalGB',
                                   'DECIMAL',
                                   'Todas as Tabelas',
                                   0,
                                   GETDATE()
                            FROM
                                   #Metricas
                            UNION
                            SELECT DISTINCT
                                   CodSistema,
                                   1,
                                   'QuantidadeArquivosAnexos',
                                   'INT',
                                   'Todas as Tabelas',
                                   0,
                                   GETDATE()
                            FROM
                                   #Metricas;



                UPDATE
                        target
                SET
                        target.Valor = info.Valor
                FROM
                        #Metricas target
                    JOIN
                        (
                            SELECT
                                    base.CodSistema,
                                    info.NomeMetrica,
                                    info.Valor
                            FROM
                                    (
                                        SELECT DISTINCT
                                               CodSistema
                                        FROM
                                               #Metricas
                                    ) base
                                JOIN
                                    (
                                        SELECT
                                            CodSistema,
                                            TipoMetrica        AS NomeMetrica,
                                            CAST(Valor AS INT) AS Valor -- Garantir que seja string
                                        FROM
                                            (
                                                SELECT
                                                    CodSistema,
                                                    SUM(CAST(QuantidadeArquivosAnexos AS INT)) AS QuantidadeArquivosAnexos,
                                                    SUM(CAST([Total em GB] AS INT))            AS [TotalGB]
                                                FROM
                                                    #MetricasArquivosAnexos
                                                GROUP BY
                                                    CodSistema
                                            ) AS SourceTable
                                            UNPIVOT
                                                (
                                                    Valor
                                                    FOR TipoMetrica IN (
                                                                           QuantidadeArquivosAnexos, [TotalGB]
                                                                       )
                                                ) AS UnpivotTable
                                    ) info
                                        ON info.CodSistema = base.CodSistema
                        )         AS info
                            ON info.CodSistema = target.CodSistema
                               AND target.NomeMetrica = info.NomeMetrica COLLATE Latin1_General_CI_AI;


            END;






        DROP TABLE IF EXISTS #Retorno;


        CREATE TABLE #Retorno
            (
                [Cliente]          VARCHAR(100),
                [CodSistema]       TINYINT,
                [Ordem]            TINYINT,
                [NomeMetrica]      VARCHAR(100),
                [TipoRetorno]      VARCHAR(100),
                [TabelaConsultada] VARCHAR(128),
                [Valor]            VARCHAR(MAX)
            );

        DELETE FROM
               #Metricas
        FROM
            #Metricas
        WHERE
            CodSistema IN (
                              '{00000000-0000-0000-0000-000000000002}', '{00000000-0000-0000-0000-000000000003}',
                              '{00000000-0000-0000-0000-000000000012}', '{00000000-0000-0000-0000-000000000013}'
                          );


        INSERT INTO #Retorno
                    SELECT
                            Cliente                                                                       = UPPER(CAST(SUBSTRING(DB_NAME(), 0, CHARINDEX('.', DB_NAME())) AS VARCHAR(20))),
                            ISNULL(s.IdSistemaEspelhamento, RIGHT(CAST(m.CodSistema AS VARCHAR(100)), 3)) AS CodSistema,
                            Ordem,
                            NomeMetrica,
                            TipoRetorno,
                            TabelaConsultada,
                            Valor
                    FROM
                            #Metricas                     m
                        LEFT JOIN
                            Sistema.SistemasEspelhamentos s
                                ON s.CodSistema = m.CodSistema
                    WHERE
                            NOT (
                                    m.CodSistema = '00000000-0000-0000-0000-000000000000'
                                    AND m.NomeMetrica IN (
                                                             'DataUltimoAcesso', 'QtdAcessos', 'QtdAcessosNoAno',
                                                             'PossueLicenca'
                                                         )
                                )
                    ORDER BY
                            s.IdSistemaEspelhamento,
                            m.Id;




        IF (@RetornarFormatoPivot = 1)
            BEGIN
                DECLARE
                    @columns NVARCHAR(MAX),
                    @sql     NVARCHAR(MAX);

                -- Obter as colunas dinamicamente
                SELECT
                    @columns
                    = STUFF(
                    (
                        SELECT DISTINCT
                               ',' + QUOTENAME(NomeMetrica)
                        FROM
                               #Retorno
                        WHERE
                               CodSistema IN (
                                                 '00000000-0000-0000-0000-000000000001',
                                                 '00000000-0000-0000-0000-000000000003',
                                                 '00000000-0000-0000-0000-000000000004',
                                                 '00000000-0000-0000-0000-000000000005',
                                                 '00000000-0000-0000-0000-000000000006',
                                                 '00000000-0000-0000-0000-000000000007',
                                                 '00000000-0000-0000-0000-000000000008',
                                                 '00000000-0000-0000-0000-000000000009',
                                                 '00000000-0000-0000-0000-000000000010',
                                                 '00000000-0000-0000-0000-000000000011',
                                                 '00000000-0000-0000-0000-000000000014',
                                                 '00000000-0000-0000-0000-000000000015',
                                                 '00000000-0000-0000-0000-000000000016',
                                                 '00000000-0000-0000-0000-000000000017',
                                                 '00000000-0000-0000-0000-000000000019',
                                                 '00000000-0000-0000-0000-000000000021',
                                                 '00000000-0000-0000-0000-000000000023',
                                                 '00000000-0000-0000-0000-000000000024',
                                                 '00000000-0000-0000-0000-000000000099'
                                             )
                        -- AND CodSistema = '00000000-0000-0000-0000-000000000004'
                        FOR XML PATH(''), TYPE
                    ).value('.', 'NVARCHAR(MAX)'), 1, 1, ''
                           );

                -- Construir a consulta dinâmica
                SET @sql
                    = N'

SELECT Cliente,
       CodigoSistema,
       NomeSistema,
       [Tabela Principal] AS Tabela,' + @columns
                      + N'

FROM (
    SELECT Cliente,
           CodSistema AS CodigoSistema,
           NomeSistema,
           [Tabela Principal],
           NomeMetrica,
		   --Valor
           CASE 
               WHEN NomeMetrica NOT LIKE ''Data%'' AND Valor IS NULL THEN ''0''
               ELSE Valor
           END AS Valor
    FROM #Retorno R
    WHERE R.CodSistema IN (''00000000-0000-0000-0000-000000000001'', 
                           ''00000000-0000-0000-0000-000000000003'',
                           ''00000000-0000-0000-0000-000000000004'', 
                           ''00000000-0000-0000-0000-000000000005'',
                           ''00000000-0000-0000-0000-000000000006'', 
                           ''00000000-0000-0000-0000-000000000007'',
                           ''00000000-0000-0000-0000-000000000008'',
                           ''00000000-0000-0000-0000-000000000009'',
                           ''00000000-0000-0000-0000-000000000010'',
                           ''00000000-0000-0000-0000-000000000011'',
                           ''00000000-0000-0000-0000-000000000014'',
                           ''00000000-0000-0000-0000-000000000015'',
                           ''00000000-0000-0000-0000-000000000016'',
                           ''00000000-0000-0000-0000-000000000017'',
                           ''00000000-0000-0000-0000-000000000019'',
                           ''00000000-0000-0000-0000-000000000021'',
                           ''00000000-0000-0000-0000-000000000023'',
                           ''00000000-0000-0000-0000-000000000024'',
                           ''00000000-0000-0000-0000-000000000099'')
         -- AND R.CodSistema = ''00000000-0000-0000-0000-000000000007''
) AS SourceTable
PIVOT (
    MAX(Valor) FOR NomeMetrica IN (' + @columns + N')
) AS PivotTable';



                EXEC sp_executesql
                    @sql;

            END;
        ELSE
            BEGIN

                SELECT
                        R.Cliente,
                        R.CodSistema,
                        --se.Nome,
                        R.Ordem,
                        R.NomeMetrica,
                        R.TipoRetorno,
                        R.TabelaConsultada,
                        ISNULL(R.Valor,'') AS Valor
                FROM
                        #Retorno                      R
                    LEFT JOIN
                        Sistema.SistemasEspelhamentos se
                            ON se.IdSistemaEspelhamento = R.CodSistema;
            --WHERE se.Nome  LIKE '%Sispad%'
            --WHERE R.CodSistema  IN( 1,99)

            END;
    END;
GO

