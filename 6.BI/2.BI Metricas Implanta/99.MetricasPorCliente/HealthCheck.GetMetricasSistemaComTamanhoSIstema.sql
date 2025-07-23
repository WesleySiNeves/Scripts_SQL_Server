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
        --DECLARE @RecuperarTamanhoPorSIstema BIT = 1;
        DECLARE @Sistema UNIQUEIDENTIFIER = NULL;
        DECLARE @Metricas VARCHAR(MAX) = NULL;



        --SELECT
        --    @Metricas
        --    = 'QuantidadeArquivosAnexos,
        --	TotalArmazenamentoArquivosAnexosMB,
        --	TotalArmazenadoSistemaMB,
        --	QtdRegistrosSistema,
        --	PossueLicenca';

        --SELECT
        --    @Metricas ='QuantidadeArquivosAnexos,TotalArmazenamentoArquivosAnexosMB';

        DROP TABLE IF EXISTS #DadosTabelas;
        DROP TABLE IF EXISTS #MetricasParamentros;
        DROP TABLE IF EXISTS #Retorno;
        DROP TABLE IF EXISTS #Sistemas;
        DROP TABLE IF EXISTS #Metricas;
        DROP TABLE IF EXISTS #MetricasArquivosAnexos;
        DROP TABLE IF EXISTS #InformacoesLogs;
        DROP TABLE IF EXISTS #AcessosSistemas;
        DROP TABLE IF EXISTS #MetricasBase;
        DROP TABLE IF EXISTS #MetricasScripts;
        DROP TABLE IF EXISTS #SistemasAtivadosPorFlag;
        DROP TABLE IF EXISTS #TabelasPrincipaisSistema;
        DROP TABLE IF EXISTS #SchemasSistemas;

        CREATE TABLE #InformacoesLogs
            (
                CodSistema                   UNIQUEIDENTIFIER NOT NULL,
                [Entidade]                   VARCHAR(128),
                [NomeSchema]                 VARCHAR(128),
                [DataUltimoRegistroInserido] DATETIME2(2),
                TotalInseridoAno             INT
            );

        CREATE TABLE #MetricasParamentros
            (
                NomeMetrica VARCHAR(50)
            );

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

        CREATE TABLE #MetricasArquivosAnexos
            (
                CodSistema                         UNIQUEIDENTIFIER,
                [Entidade]                         VARCHAR(250),
                NomeSchema                         VARCHAR(200),
                [QuantidadeArquivosAnexos]         INT,
                TotalArmazenamentoArquivosAnexosMB DECIMAL(18, 2)
            );

        CREATE TABLE #DadosTabelas
            (
                [Schema]         NVARCHAR(128),
                [Tabela]         NVARCHAR(128),
                CodSistema       UNIQUEIDENTIFIER NULL,
                Area             VARCHAR(50)      NULL,
                [Linhas]         BIGINT,
                [Tamanho_MB]     DECIMAL(38, 2),
                [Tamanho_GB]     DECIMAL(38, 2),
                [Usado_MB]       DECIMAL(38, 2),
                [Usado_GB]       DECIMAL(38, 2),
                [Livre_MB]       DECIMAL(38, 2),
                [Total Geral GB] DECIMAL(38, 6)
            );

        CREATE TABLE #AcessosSistemas
            (
                [CodSistema] UNIQUEIDENTIFIER,
                [Ano]        INT,
                [Mes]        INT,
                [Total]      INT
            );

        CREATE TABLE #SchemasSistemas
            (
                [Schema]     VARCHAR(128) PRIMARY KEY,
                [CodSistema] UNIQUEIDENTIFIER,
                [Descricao]  VARCHAR(100)
            );



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

        CREATE TABLE #SistemasAtivadosPorFlag
            (
                [CodSistema]       UNIQUEIDENTIFIER,
                [DataUltimoAcesso] DATETIME2(2),
                [QtdAcessos]       INT,
                [QtdAcessosNoAno]  INT,
                [PossueLicenca]    INT
            );

        CREATE TABLE #TabelasPrincipaisSistema
            (
                [CodSistema]       UNIQUEIDENTIFIER,
                Sistema            VARCHAR(100),
                [Tabela Principal] VARCHAR(200),
                NomeSchema         VARCHAR(200)
            );

        IF (LEN(@Metricas) > 0)
            BEGIN
                INSERT INTO #MetricasParamentros
                            SELECT
                                LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(value, CHAR(13), ''), CHAR(10), ''), CHAR(9), '')))
                            FROM
                                STRING_SPLIT(@Metricas, ',');
            END;




            ;WITH DadosTamanhoCadaTabela
            AS (   SELECT
                           s.name                                                                                     AS [Schema],
                           t.name                                                                                     AS [Tabela],
                           p.rows                                                                                     AS [Linhas],
                           CAST(ROUND(((SUM(a.total_pages) * 8) / 1024.00), 2) AS NUMERIC(36, 2))                     AS [Tamanho_MB],
                           CAST(ROUND(((SUM(a.total_pages) * 8) / 1024.00 / 1024.00), 2) AS NUMERIC(36, 2))           AS [Tamanho_GB],
                           CAST(ROUND(((SUM(a.used_pages) * 8) / 1024.00), 2) AS NUMERIC(36, 2))                      AS [Usado_MB],
                           CAST(ROUND(((SUM(a.used_pages) * 8) / 1024.00 / 1024.00), 2) AS NUMERIC(36, 2))            AS [Usado_GB],
                           CAST(ROUND(((SUM(a.total_pages) - SUM(a.used_pages)) * 8) / 1024.00, 2) AS NUMERIC(36, 2)) AS [Livre_MB]
                   FROM
                           sys.tables           t
                       INNER JOIN
                           sys.indexes          i
                               ON t.object_id = i.object_id
                       INNER JOIN
                           sys.partitions       p
                               ON i.object_id = p.object_id
                                  AND i.index_id = p.index_id
                       INNER JOIN
                           sys.allocation_units a
                               ON p.partition_id = a.container_id
                       LEFT OUTER JOIN
                           sys.schemas          s
                               ON t.schema_id = s.schema_id
                   WHERE
                           t.name NOT LIKE 'dt%'
                           AND t.is_ms_shipped = 0
                           AND i.object_id > 255
                   GROUP BY
                           t.name,
                           s.name,
                           p.rows),
                  Agregate
            AS (   SELECT
                       R.[Schema],
                       R.Tabela,
                       SUM(R.Linhas)     AS Linhas,
                       SUM(R.Tamanho_MB) AS Tamanho_MB,
                       SUM(R.Tamanho_GB) AS Tamanho_GB,
                       SUM(R.Usado_MB)   AS Usado_MB,
                       SUM(R.Usado_GB)   AS Usado_GB,
                       SUM(R.Livre_MB)   AS Livre_MB
                   FROM
                       DadosTamanhoCadaTabela R
                   GROUP BY
                       R.[Schema],
                       R.Tabela)
        INSERT INTO #DadosTabelas
            (
                [Schema],
                Tabela,
                CodSistema,
                Area,
                Linhas,
                Tamanho_MB,
                Tamanho_GB,
                Usado_MB,
                Usado_GB,
                Livre_MB,
                [Total Geral GB]
            )
                    SELECT
                        R.[Schema],
                        R.Tabela,
                        NULL,
                        NULL,
                        R.Linhas,
                        R.Tamanho_MB,
                        [Total Geral GB] = SUM(R.Tamanho_MB) OVER () / 1024.0,
                        R.Tamanho_GB,
                        R.Usado_MB,
                        R.Usado_GB,
                        R.Livre_MB
                    FROM
                        Agregate R
                    WHERE
                        R.[Schema] NOT LIKE '%Hangfire%'
                        AND R.Linhas > 0
                    ORDER BY
                        [Tamanho_MB] DESC;



        /*Essa regra aqui pode ser adicionado na tabela de sistemas quando ela for refatorada*/

        CREATE TABLE #Sistemas
            (
                [IdSistemaEspelhamento] TINYINT,
                [CodSistema]            UNIQUEIDENTIFIER,
                [NomeSistema]           VARCHAR(200),
                Area                    VARCHAR(50)     NULL,
                Schemas                 VARCHAR(MAX)
            );

        INSERT INTO #Sistemas
            (
                IdSistemaEspelhamento,
                CodSistema,
                NomeSistema
            )
                    SELECT
                        IdSistemaEspelhamento,
                        CodSistema,
                        ISNULL(Descricao, Nome) AS NomeSistema
                    FROM
                        Sistema.SistemasEspelhamentos;

        INSERT INTO #Sistemas
            (
                IdSistemaEspelhamento,
                CodSistema,
                NomeSistema
            )
        VALUES
            (
                99,                                     -- IdSistemaEspelhamento - tinyint
                '00000000-0000-0000-0000-000000000099', -- CodSistema - uniqueidentifier
                'CentroCustos.NET'                      -- NomeSistema - varchar(200)
            );


        UPDATE
            s
        SET
            s.Area = 'Área Fim'
        FROM
            #Sistemas s
        WHERE
            CodSistema IN (
                              '00000000-0000-0000-0000-000000000011', '00000000-0000-0000-0000-000000000013',
                              '00000000-0000-0000-0000-000000000012', '00000000-0000-0000-0000-000000000014',
                              '00000000-0000-0000-0000-000000000017', '00000000-0000-0000-0000-000000000018',
                              '00000000-0000-0000-0000-000000000021', '00000000-0000-0000-0000-000000000023',
                              '00000000-0000-0000-0000-000000000024'
                          );

        UPDATE
            s
        SET
            s.Area = 'Área Meio'
        FROM
            #Sistemas s
        WHERE
            CodSistema IN (
                              '00000000-0000-0000-0000-000000000006', '00000000-0000-0000-0000-000000000007',
                              '00000000-0000-0000-0000-000000000008', '00000000-0000-0000-0000-000000000009',
                              '00000000-0000-0000-0000-000000000004'
                          );

        UPDATE
            s
        SET
            s.Area = 'Área Financeira / Fiscal'
        FROM
            #Sistemas s
        WHERE
            CodSistema IN (
                              '{00000000-0000-0000-0000-000000000001}', '{00000000-0000-0000-0000-000000000002}',
                              '{00000000-0000-0000-0000-000000000003}', '{00000000-0000-0000-0000-000000000005}',
                              '{00000000-0000-0000-0000-000000000010}', '{00000000-0000-0000-0000-000000000015}',
                              '{00000000-0000-0000-0000-000000000016}', '{00000000-0000-0000-0000-000000000019}',
                              '{00000000-0000-0000-0000-000000000020}', '{00000000-0000-0000-0000-000000000022}',
                              '00000000-0000-0000-0000-000000000000', '00000000-0000-0000-0000-000000000099'
                          );

        UPDATE
            s
        SET
            s.Area = 'Todas'
        FROM
            #Sistemas s
        WHERE
            Area IS NULL;

        --SELECT * FROM #Sistemas



        -- Global , e um  pre-requisitos de todos os sistemas
        UPDATE
            s
        SET
            s.Schemas = 'Sistema,Cadastro,Corporativo,Expurgo,HealthCheck,Log,DNE,AssinaturaDigital'
        FROM
            #Sistemas s
        WHERE
            CodSistema = '00000000-0000-0000-0000-000000000000';



        UPDATE
            s
        SET
            s.Schemas = 'REINF,Despesa,Receita,Contabilidade,Orcamento,PCASP'
        FROM
            #Sistemas s
        WHERE
            CodSistema = '00000000-0000-0000-0000-000000000001';



        -- vou usar o Centro de custos aqui , mas o tratamento nos updates será  like nome da tabela e não por schema
        UPDATE
            s
        SET
            s.Schemas = 'CentroCusto'
        FROM
            #Sistemas s
        WHERE
            CodSistema = '00000000-0000-0000-0000-000000000099';




        --Logon
        UPDATE
            s
        SET
            s.Schemas = 'Acesso'
        FROM
            #Sistemas s
        WHERE
            CodSistema = '00000000-0000-0000-0000-000000000002';


        UPDATE
            s
        SET
            s.Schemas = 'PCS'
        FROM
            #Sistemas s
        WHERE
            CodSistema = '00000000-0000-0000-0000-000000000003'; --PCS


        UPDATE
            s
        SET
            s.Schemas = 'Patrimonio'
        FROM
            #Sistemas s
        WHERE
            CodSistema = '00000000-0000-0000-0000-000000000004'; --Patrimonio


        UPDATE
            s
        SET
            s.Schemas = 'Agenda'
        FROM
            #Sistemas s
        WHERE
            CodSistema = '00000000-0000-0000-0000-000000000005'; --Agenda


        UPDATE
            s
        SET
            s.Schemas = 'Almoxarifado'
        FROM
            #Sistemas s
        WHERE
            CodSistema = '00000000-0000-0000-0000-000000000006';


        UPDATE
            s
        SET
            s.Schemas = 'Compra,Contrato,PNCP'
        FROM
            #Sistemas s
        WHERE
            CodSistema = '00000000-0000-0000-0000-000000000007';



        UPDATE
            s
        SET
            s.Schemas = 'Viagem'
        FROM
            #Sistemas s
        WHERE
            CodSistema = '00000000-0000-0000-0000-000000000008';


        UPDATE
            s
        SET
            s.Schemas = 'Licitacao'
        FROM
            #Sistemas s
        WHERE
            CodSistema = '00000000-0000-0000-0000-000000000009';


        UPDATE
            s
        SET
            s.Schemas = 'TCU,TCU2015'
        FROM
            #Sistemas s
        WHERE
            CodSistema = '00000000-0000-0000-0000-000000000010';


        UPDATE
            s
        SET
            s.Schemas = 'AtivosBB,Financeiro,Plenaria,Requerimento,Serasa,Siscaf,IEPTB,SPC,Cadin,Recadastramento,Registro,DividaAtiva,Cielo,OAB,Sopague,SelfPay,Zoop'
        FROM
            #Sistemas s
        WHERE
            CodSistema = '00000000-0000-0000-0000-000000000011'; --Siscaf



        UPDATE
            s
        SET
            s.Schemas = 'Curso'
        FROM
            #Sistemas s
        WHERE
            CodSistema = '00000000-0000-0000-0000-000000000013'; --Cursos


        UPDATE
            s
        SET
            s.Schemas = 'Formulario,Tramitacao,Documento'
        FROM
            #Sistemas s
        WHERE
            CodSistema = '00000000-0000-0000-0000-000000000014'; --Sisdoc

        UPDATE
            s
        SET
            s.Schemas = 'Auditoria'
        FROM
            #Sistemas s
        WHERE
            CodSistema = '00000000-0000-0000-0000-000000000015'; --Auditoria



        UPDATE
            s
        SET
            s.Schemas = 'Transparencia,eSIC,PortalTransparencia'
        FROM
            #Sistemas s
        WHERE
            CodSistema = '00000000-0000-0000-0000-000000000016'; -- POrtal da transparencia


        UPDATE
            s
        SET
            s.Schemas = 'Nacional'
        FROM
            #Sistemas s
        WHERE
            CodSistema = '00000000-0000-0000-0000-000000000017'; --Visão Nacional  


        UPDATE
            s
        SET
            s.Schemas = 'Online,OnBoardingDigital'
        FROM
            #Sistemas s
        WHERE
            CodSistema = '00000000-0000-0000-0000-000000000018'; --Serviços Online



        UPDATE
            s
        SET
            s.Schemas = 'Planejamento,Programa,Projeto'
        FROM
            #Sistemas s
        WHERE
            CodSistema = '00000000-0000-0000-0000-000000000019'; -- Programas e Projetos



        UPDATE
            s
        SET
            s.Schemas = 'CRM,Ocorrencia,FAQ,CrmImplanta'
        FROM
            #Sistemas s
        WHERE
            CodSistema = '00000000-0000-0000-0000-000000000021'; -- CRM.NET

        UPDATE
            s
        SET
            s.Schemas = 'AssinaturaDigital'
        FROM
            #Sistemas s
        WHERE
            CodSistema = '00000000-0000-0000-0000-000000000022'; -- Assinatura Digital

        UPDATE
            s
        SET
            s.Schemas = 'Processo'
        FROM
            #Sistemas s
        WHERE
            CodSistema = '00000000-0000-0000-0000-000000000023'; -- Processos

        UPDATE
            s
        SET
            s.Schemas = 'Fiscalizacao'
        FROM
            #Sistemas s
        WHERE
            CodSistema = '00000000-0000-0000-0000-000000000024'; -- Processos


        /*
       
       SELECT DISTINCT [Schema],Tabela FROM #DadosTabelas 
       WHERE [Schema] NOT IN('Sistema','Cadastro','Corporativo','Expurgo','HealthCheck','Log','DNE','AssinaturaDigital')-- Global
       AND [Schema] NOT IN('REINF','Despesa','Receita','Contabilidade','Orcamento','PCASP','') --- Siscont
       AND [Schema] NOT IN('Acesso') --- Logon
       AND [Schema] NOT IN('PCS') --- Logon
       AND [Schema] NOT IN('Patrimonio') --- Patrimonio
       AND [Schema] NOT IN('Agenda') --- Agenda
       AND [Schema] NOT IN('Almoxarifado') --- Almoxarifado
       AND [Schema] NOT IN('Compra','Contrato','PNCP') --- Compras
       AND [Schema] NOT IN('Viagem') --- Viagem
       AND [Schema] NOT IN('Licitacao') --- Licitacao
       AND [Schema] NOT IN('TCU','TCU2015') --- TCU
       AND [Schema] NOT IN('AtivosBB','Financeiro','Plenaria','Requerimento','Serasa','Siscaf','IEPTB','SPC','Cadin','Recadastramento','Registro','DividaAtiva','Cielo','OAB','Sopague',
       'SelfPay','Zoop') --- SISCAF
       AND [Schema] NOT IN('Curso') --- Curso
       AND [Schema] NOT IN('Formulario','Tramitacao','Documento') --- Sisdoc
       AND [Schema] NOT IN('Auditoria') --- Auditoria
       AND [Schema] NOT IN('Transparencia','eSIC','PortalTransparencia') --- Auditoria
       AND [Schema] NOT IN('Nacional') --- Nacional
       AND [Schema] NOT IN('Online','OnBoardingDigital') --- Serviços Online
       AND [Schema] NOT IN('Planejamento','Programa','Projeto') --- Programas e Projetos
       AND [Schema] NOT IN('CRM','Ocorrencia','FAQ','CrmImplanta') --- Serviços Online
       AND [Schema] NOT IN('AssinaturaDigital') ---Assinaturas
       AND [Schema] NOT IN('Processo') ---Processos
       AND [Schema] NOT IN('Fiscalizacao') ---Fiscalização
        
        */







        /*Metricas bases (DataUltimoAcesso,QtdAcessos,QtdAcessosNoAno,PossueLicenca)
         A metrica PossueLicenca vai ser alterada para ser lida na tabela de Sistemas
        */
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
                                                                                REPLACE(
                                                                                           REPLACE(s.NomeSistema, '.NET', ''),
                                                                                           ' ', ''
                                                                                       ), '&', ''
                                                                            ), 'ção', 'cao'
                                                                 ), 'NET', ''
                                                      ) LIKE '%' + REPLACE(REPLACE(Configuracao, 'Licenca', ''), 'NET', '')
                                                             + '%'
                                ), 0
                                  )                           AS PossueLicenca
                    FROM
                            #Sistemas s
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
                            )         Acesso
                                ON Acesso.IdSistema = s.CodSistema
                    --               WHERE 
                    --(s.CodSistema  = @Sistema OR @Sistema IS NULL)
                    ORDER BY
                            s.CodSistema;



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


        /* Tratativa do centro de custos*/

        DECLARE @UtilizaCentroCustoPagamento BIT = ISNULL(CAST(
                                                              (
                                                                  SELECT
                                                                      c.Valor
                                                                  FROM
                                                                      Sistema.Configuracoes c
                                                                  WHERE
                                                                      c.Configuracao = 'UtilizaCentroCustoPagamento'
                                                                      AND Ano = YEAR(GETDATE())
                                                              ) AS BIT), 0
                                                         );

        DECLARE @OrcamentoPorCentroCusto BIT = ISNULL(CAST(
                                                          (
                                                              SELECT TOP 1
                                                                     Valor
                                                              FROM
                                                                     Sistema.Configuracoes c
                                                              WHERE
                                                                     c.Configuracao = 'OrcamentoPorCentroCusto'
                                                                     AND Ano = YEAR(GETDATE())
                                                          ) AS BIT), 0
                                                     );

        ----Modulos que são caracterizados como sistema
        UPDATE
            target
        SET
            target.PossueLicenca = IIF(
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
                                          0),
            target.DataUltimoAcesso = (CASE
                                           WHEN @OrcamentoPorCentroCusto = 1
                                                OR @UtilizaCentroCustoPagamento = 1
                                               THEN
                                               (
                                                   SELECT
                                                       MAX(ep.DataUltimoAcesso)
                                                   FROM
                                                       #MetricasBase ep
                                                   WHERE
                                                       ep.CodSistema = '00000000-0000-0000-0000-000000000001' --trasfere as informações do Siscont para o Centro de Custos
                                               )
                                           ELSE
                                               NULL
                                       END
                                      ),
            target.QtdAcessos = (CASE
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
                                 END
                                ),
            target.QtdAcessosNoAno = (CASE
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
                                      END
                                     )
        FROM
            #MetricasBase AS target
        WHERE
            target.CodSistema = '00000000-0000-0000-0000-000000000099';




        /*Tratativa da ativação de Sistemas  por flag e não por licenciamento*/

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


        /*Serviços Online*/
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

        /*Metricas por sistemas ( coração da procedure) 
        Cada sistema pode ter N metricas
        */
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
				WHERE pc.Codigo LIKE ''[78].%'') AS bit ),0)'                       -- Script - varchar(max)
            ),
            (
                '00000000-0000-0000-0000-000000000001', 'QtdLancamentosGestaoDevedores78', -- Nome - varchar(200)
                'BIT',                                                                     -- TipoRetorno - varchar(30),
                'Contabilidade.Movimentos',
                'ISNULL(cast((  SELECT TOP 1 1 FROM Contabilidade.Lancamentos p
				JOIN Contabilidade.Movimentos  m ON m.IdLancamento = p.IdLancamento
				JOIN Contabilidade.PlanoContas pc ON pc.IdPlanoConta = m.IdPlanoConta
				WHERE pc.Codigo LIKE ''[78].%'' AND YEAR(p.Data) = YEAR(GETDATE())) AS bit ),0)' -- Script - varchar(max)
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
        /*Ordem = 2 (Metricas detalhes de cada sistema a a ideia é que as metricas tipo 2 podem ficar me detalhes na pagina do sistema*/
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



        /*remover alguns sistemas ainda não solicitados(Rever no futuro)
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
                              '{00000000-0000-0000-0000-000000000003}', '{00000000-0000-0000-0000-000000000012}',
                              '{00000000-0000-0000-0000-000000000013}'
                          );



        /*Se for passado os paramentros  me metricas especificas , aqui remove todas as demais  */
        IF (EXISTS
            (
                SELECT
                    *
                FROM
                    #MetricasParamentros
            )
           )
            BEGIN
                DELETE FROM
                       #MetricasScripts
                WHERE
                    NomeMetrica NOT IN
                        (
                            SELECT
                                NomeMetrica
                            FROM
                                #MetricasParamentros
                        );
            END;


        UPDATE
            target
        SET
            target.CodSistema =
                (
                    SELECT TOP 1
                           CodSistema
                    FROM
                           #Sistemas
                    WHERE
                           Schemas LIKE CONCAT('%', target.[Schema], '%') --Recupera o Codigo do Sistema
                )
        FROM
            #DadosTabelas AS target;

        /*Trata o Centro de custos*/


        UPDATE
            target
        SET
            target.CodSistema = '00000000-0000-0000-0000-000000000099'
        FROM
            #DadosTabelas AS target
        WHERE
            Tabela LIKE '%CentroCusto%';


        /*Quando não identificamos o schema associado ou foi criado um schema novo e ainda não configurou no de-para*/
        UPDATE
            target
        SET
            target.CodSistema = '00000000-0000-0000-0000-000000000000' --Global
        FROM
            #DadosTabelas AS target
        WHERE
            CodSistema IS NULL;





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


        /*Primeiras metricas*/
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
                        'DataUltimoAcesso'                    AS Nome,
                        'DATETIME'                            AS TipoRetorno,
                        'acesso.sessoes'                      AS TabelaConsultada,
                        CAST(DataUltimoAcesso AS VARCHAR(30)) AS Valor,
                        GETDATE()                             AS DataAtualizacao
                    FROM
                        #MetricasBase
                    UNION ALL
                    SELECT
                        CodSistema,
                        Ordem,
                        'QtdAcessos'                    AS Nome,
                        'INT'                           AS TipoRetorno,
                        'acesso.sessoes'                AS TabelaConsultada,
                        CAST(QtdAcessos AS VARCHAR(30)) AS Valor,
                        GETDATE()                       AS DataAtualizacao
                    FROM
                        #MetricasBase
                    UNION ALL
                    SELECT
                        CodSistema,
                        Ordem,
                        'QtdAcessosNoAno'                    AS Nome,
                        'INT'                                AS TipoRetorno,
                        'acesso.sessoes'                     AS TabelaConsultada,
                        CAST(QtdAcessosNoAno AS VARCHAR(30)) AS Valor,
                        GETDATE()                            AS DataAtualizacao
                    FROM
                        #MetricasBase
                    UNION ALL
                    SELECT
                        CodSistema,
                        ss.Ordem,
                        'PossueLicenca'                    AS Nome,
                        'BIT'                              AS TipoRetorno,
                        'sistema.configuracoes'            AS TabelaConsultada,
                        CAST(PossueLicenca AS VARCHAR(10)) AS Valor,
                        GETDATE()                          AS DataAtualizacao
                    FROM
                        #MetricasBase ss


        /*Tabela Principal de Cada sistema (Rever posteriormente para identificar se essa informação ainda é relevante)*/
        ;

        WITH DadosTabelaPrincipal
        AS (   SELECT
                   CodSistema,
                   [Tabela Principal] =
                       (
                           SELECT
                               TabelaConsultada
                           FROM
                               #Metricas m
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






        --IF (@RecuperarInformacoesArquivosAnexos = 1 OR @RecuperarTamanhoPorSIstema =1)
        --    BEGIN

        ;
        WITH MetricasArquivosAnexos
        AS (   SELECT
                   Entidade,
                   COUNT(1)                       AS QuantidadeArquivosAnexos,
                   (SUM(Tamanho) / 1048576) * 1.0 AS TotalArmazenamentoArquivosAnexosMB
               FROM
                   Sistema.ArquivosAnexos
               GROUP BY
                   Entidade),
             GetSchema
        AS (   SELECT
                   m.Entidade,
                   NomeEschema = SUBSTRING(m.Entidade, 0, CHARINDEX('.', m.Entidade, 0)),
                   m.QuantidadeArquivosAnexos,
                   m.TotalArmazenamentoArquivosAnexosMB
               FROM
                   MetricasArquivosAnexos m)
        INSERT INTO #MetricasArquivosAnexos
            (
                CodSistema,
                Entidade,
                NomeSchema,
                QuantidadeArquivosAnexos,
                TotalArmazenamentoArquivosAnexosMB
            )
                    SELECT
                        NULL,
                        Entidade,
                        NomeEschema,
                        QuantidadeArquivosAnexos,
                        TotalArmazenamentoArquivosAnexosMB
                    FROM
                        GetSchema;





        UPDATE
            target
        SET
            target.CodSistema = X.CodSistema
        FROM
            #MetricasArquivosAnexos target
            OUTER APPLY
            (
                SELECT
                    *
                FROM
                    #Sistemas si
                WHERE
                    si.Schemas LIKE CONCAT('%', target.NomeSchema, '%')
            )                       X
        WHERE
            LEN(target.NomeSchema) > 0;




        --Schemas Não Mapeados
        UPDATE
            target
        SET
            target.CodSistema = '00000000-0000-0000-0000-000000000000'
        FROM
            #MetricasArquivosAnexos AS target
        WHERE
            target.CodSistema IS NULL;

        --Schemas Não Mapeados
        UPDATE
            target
        SET
            target.CodSistema = '00000000-0000-0000-0000-000000000000'
        FROM
            #DadosTabelas AS target
        WHERE
            target.CodSistema IS NULL;



        INSERT INTO #Metricas
                    SELECT DISTINCT
                           CodSistema,
                           1,
                           'TotalArmazenamentoArquivosAnexosMB',
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
                                            SUM(CAST(QuantidadeArquivosAnexos AS INT))           AS QuantidadeArquivosAnexos,
                                            SUM(CAST(TotalArmazenamentoArquivosAnexosMB AS INT)) AS TotalArmazenamentoArquivosAnexosMB
                                        FROM
                                            #MetricasArquivosAnexos
                                        GROUP BY
                                            CodSistema
                                    ) AS SourceTable
                                    UNPIVOT
                                        (
                                            Valor
                                            FOR TipoMetrica IN (
                                                                   QuantidadeArquivosAnexos,
                                                                   TotalArmazenamentoArquivosAnexosMB
                                                               )
                                        ) AS UnpivotTable
                            ) info
                                ON info.CodSistema = base.CodSistema
                )         AS info
                    ON info.CodSistema = target.CodSistema
                       AND target.NomeMetrica = info.NomeMetrica COLLATE Latin1_General_CI_AI;


        --END;





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
                              '{00000000-0000-0000-0000-000000000003}', '{00000000-0000-0000-0000-000000000012}',
                              '{00000000-0000-0000-0000-000000000013}'
                          );




        WITH AgregadosDadosSistemas
        AS (   SELECT
                   CodSistema,
                   CAST(COUNT(DISTINCT Tabela) AS VARCHAR(20)) AS [QtdTabelasComDados],
                   CAST(SUM(Linhas) AS VARCHAR(20))            AS [QtdRegistrosSistema],
                   CAST(SUM(Tamanho_MB) AS VARCHAR(20))        AS [TotalArmazenadoSistemaMB]
               FROM
                   #DadosTabelas
               GROUP BY
                   CodSistema)
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
                        UnpivotTable.CodSistema,
                        1                  AS Ordem,
                        UnpivotTable.NomeMetrica,
                        'DECIMAL'          AS TipoRetorno,
                        'Todas as Tabelas' AS TabelaConsultada,
                        UnpivotTable.Valor,
                        GETDATE()          AS DataAtualizacao
                    FROM
                        AgregadosDadosSistemas R
                        UNPIVOT
                            (
                                Valor
                                FOR NomeMetrica IN (
                                                       [QtdTabelasComDados], [QtdRegistrosSistema],
                                                       [TotalArmazenadoSistemaMB]
                                                   )
                            ) AS UnpivotTable;

        IF (EXISTS
            (
                SELECT
                    *
                FROM
                    #MetricasParamentros
            )
           )
            BEGIN
                DELETE FROM
                       #Metricas
                WHERE
                    NomeMetrica NOT IN
                        (
                            SELECT
                                NomeMetrica
                            FROM
                                #MetricasParamentros
                        );
            END;



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
                            #Metricas m
                        LEFT JOIN
                            #Sistemas s
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
                                                 '1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '14', '15',
                                                 '16', '17', '19', '21', '23', '24', '99'
                                             )
                        -- AND CodSistema = '00000000-0000-0000-0000-000000000004'
                        FOR XML PATH(''), TYPE
                    ).value('.', 'NVARCHAR(MAX)'), 1, 1, ''
                           );

                -- Criar colunas com tratamento de NULL
                DECLARE @columnsWithIsnull NVARCHAR(MAX) = N'';

                SELECT
                    @columnsWithIsnull
                    = STUFF(
                    (
                        SELECT DISTINCT
                               ',' + 'ISNULL(' + QUOTENAME(NomeMetrica) + ', ''0'') AS ' + QUOTENAME(NomeMetrica)
                        FROM
                               #Retorno
                        WHERE
                               CodSistema IN (
                                                 '1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '14', '15',
                                                 '16', '17', '19', '21', '23', '24', '99'
                                             )
                        FOR XML PATH(''), TYPE
                    ).value('.', 'NVARCHAR(MAX)'), 1, 1, ''
                           );

                -- Construir a consulta dinâmica
                SET @sql
                    = N'
SELECT Cliente,
       CodigoSistema,
       Area,
       NomeSistema,
       [Tabela Principal] AS Tabela,' + @columnsWithIsnull
                      + N'
FROM (
    SELECT R.Cliente,
           R.CodSistema AS CodigoSistema,
           se.NomeSistema,
           se.Area,
           R.TabelaConsultada as [Tabela Principal],
           R.NomeMetrica,
           -- Valor com tratamento melhorado
           CASE 
               WHEN NomeMetrica NOT LIKE ''Data%'' AND Valor IS NULL THEN ''0''
               WHEN NomeMetrica LIKE ''Data%'' AND Valor IS NULL THEN ''N/A''
               ELSE ISNULL(Valor, ''0'')
           END AS Valor
    FROM #Retorno R
    LEFT JOIN #Sistemas se ON se.IdSistemaEspelhamento = R.CodSistema
    WHERE R.CodSistema IN (''0'',''1'',''2'', ''3'', ''4'', ''5'', ''6'', ''7'', ''8'', ''9'', ''10'', 
                           ''11'', ''14'', ''15'', ''16'', ''17'', ''19'', ''21'', ''23'', ''24'', ''99'')
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
                        ISNULL(R.Valor, '') AS Valor
                FROM
                        #Retorno  R
                    LEFT JOIN
                        #Sistemas se
                            ON se.IdSistemaEspelhamento = R.CodSistema
                ORDER BY
                        R.CodSistema,
                        R.Ordem,
                        R.NomeMetrica;


            END;
    END;
GO


