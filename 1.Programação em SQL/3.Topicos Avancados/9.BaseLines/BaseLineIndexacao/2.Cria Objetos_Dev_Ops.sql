/* ==================================================================
--Data: 9/4/2020 
--Autor :Wesley Neves
--Observação: Cria as tabelas de AcoesPeriodicidadeDias para a execução dos jobs
 
-- ==================================================================
*/

IF(NOT EXISTS (
                  SELECT * FROM sys.tables AS T WHERE T.name = 'AcoesPeriodicidadeDias'
              )
  )
    BEGIN
        CREATE TABLE HealthCheck.AcoesPeriodicidadeDias
        (
            IdAcao             SMALLINT    NOT NULL IDENTITY(1, 1) CONSTRAINT PKHealthCheckAcoesPeriodicidadeDiasIdAcao PRIMARY KEY(IdAcao),
            Nome               VARCHAR(30),
            Descricao          VARCHAR(150),
            Periodicidade      SMALLINT,
            Ativo              BIT         NOT NULL CONSTRAINT DEF_HealthCheckAcoesPeriodicidadeDiasAtivo DEFAULT(1),
            DataInicio         DATE        NOT NULL CONSTRAINT DEF_HealthCheckAcoesPeriodicidadeDiasDataInicio DEFAULT(CAST(GETDATE() AS DATE)),
            DataUltimaExecucao DATE        NULL
        )
        WITH (DATA_COMPRESSION = PAGE);

        --AcoesPeriodicidadeDias
        INSERT INTO HealthCheck.AcoesPeriodicidadeDias(
                                                          Nome,
                                                          Descricao,
                                                          Periodicidade
                                                      )
        VALUES(   'AtualizarStatisticas',                                      -- Nome - varchar(20)
                  'Atualização de statisticas diariamente (Periodicidade =1)', -- Descricao - varchar(100)
                  1                                                            -- Periodicidade - varchar(20)
              );

        INSERT INTO HealthCheck.AcoesPeriodicidadeDias(
                                                          Nome,
                                                          Descricao,
                                                          Periodicidade
                                                      )
        VALUES(   'CriarIndicesAutomaticamente',                       -- Nome - varchar(20)
                  'Criação de indices diariamente (Periodicidade =1)', -- Descricao - varchar(100)
                  1                                                    -- Periodicidade - varchar(20)
              );

        INSERT INTO HealthCheck.AcoesPeriodicidadeDias(
                                                          Nome,
                                                          Descricao,
                                                          Periodicidade
                                                      )
        VALUES(   'CriarStatisticasColunas',                                 -- Nome - varchar(20)
                  'Criação de estatisticas nas colunas  (Periodicidade =1)', -- Descricao - varchar(100)
                  1                                                          -- Periodicidade - varchar(20)
              );

        INSERT INTO HealthCheck.AcoesPeriodicidadeDias(
                                                          Nome,
                                                          Descricao,
                                                          Periodicidade
                                                      )
        VALUES(   'DeletarIndicesDuplicados',                           -- Nome - varchar(20)
                  'Deleção de indices duplicados  (Periodicidade =15)', -- Descricao - varchar(100)
                  15                                                    -- Periodicidade - varchar(20)
              );

        INSERT INTO HealthCheck.AcoesPeriodicidadeDias(
                                                          Nome,
                                                          Descricao,
                                                          Periodicidade
                                                      )
        VALUES(   'AnalisarIndicesIneficientes',                         -- Nome - varchar(20)
                  'Analise de indices ineficientes  (Periodicidade =7)', -- Descricao - varchar(100)
                  7                                                      -- Periodicidade - varchar(20)
              );

        INSERT INTO HealthCheck.AcoesPeriodicidadeDias(
                                                          Nome,
                                                          Descricao,
                                                          Periodicidade
                                                      )
        VALUES(   'DesfragmentacaoIndices',                         -- Nome - varchar(20)
                  'Desfragmentação de indices  (Periodicidade =7)', -- Descricao - varchar(100)
                  7                                                 -- Periodicidade - varchar(20)
              );

        INSERT INTO HealthCheck.AcoesPeriodicidadeDias(
                                                          Nome,
                                                          Descricao,
                                                          Periodicidade
                                                      )
        VALUES(   'DeletarIndicesNaoUsados',                            -- Nome - varchar(20)
                  'Deleção de indices  não usados (Periodicidade =60)', -- Descricao - varchar(100)
                  60                                                    -- Periodicidade - varchar(20)
              );

        INSERT INTO HealthCheck.AcoesPeriodicidadeDias(
                                                          Nome,
                                                          Descricao,
                                                          Periodicidade
                                                      )
        VALUES(   'ShrinkDatabase',                             -- Nome - varchar(20)
                  'Efetua o ShrinkDatabase(Periodicidade =15)', -- Descricao - varchar(100)
                  15                                            -- Periodicidade - varchar(20)
              );

        INSERT INTO HealthCheck.AcoesPeriodicidadeDias(
                                                          Nome,
                                                          Descricao,
                                                          Periodicidade
                                                      )
        VALUES(   'ExpurgarElmah',           -- Nome - varchar(20)
                  'Expurgar Erros do Elmah', -- Descricao - varchar(100)
                  90                         -- Periodicidade - varchar(20)
              );

        INSERT INTO HealthCheck.AcoesPeriodicidadeDias(
                                                          Nome,
                                                          Descricao,
                                                          Periodicidade
                                                      )
        VALUES(   'ExpurgarLogs',                                                                                                                -- Nome - varchar(20)
                  'Expurgar Logs em Json  no banco de dados , a peridiocidade ficará zero pois esse valor e vem da tabela sistema.configuração', -- Descricao - varchar(100)
                  0                                                                                                                              -- Periodicidade - varchar(20)
              );
    END;

IF(NOT EXISTS (SELECT * FROM sys.tables AS T WHERE T.name = 'SizeDBHistory'))
    BEGIN
        CREATE TABLE HealthCheck.SizeDBHistory
        (
            IdSizeDBHistory            INT           NOT NULL IDENTITY(1, 1) CONSTRAINT PKHealthSizeDBHistoryIdSizeDBHistory PRIMARY KEY(IdSizeDBHistory),
            [DataBaseName]             VARCHAR(128),
            Data                       DATE          NOT NULL CONSTRAINT HealthCheckSizeDBHistoryData DEFAULT(CAST(GETDATE() AS DATE)),
            [SizeInGB]                 DECIMAL(18, 2),
            [DatabaseSpaceUsedInGB]    DECIMAL(18, 2),
            [DatabaseSpaceNonUsedInGB] DECIMAL(18, 2)
        )
        WITH (DATA_COMPRESSION = PAGE);
    END;
GO

CREATE OR ALTER PROCEDURE HealthCheck.uspAutoCreateIndex
(
    @Efetivar              BIT      = 0,
    @VisualizarMissing     BIT      = 0,
    @VisualizarCreate      BIT      = 0,
    @VisualizarAlteracoes  BIT      = 0,
    @defaultTunningPerform SMALLINT = 200
)
AS
    BEGIN
        BEGIN TRY
            --DECLARE @Efetivar BIT = 0;
            --DECLARE @VisualizarMissing BIT = 1;
            --DECLARE @VisualizarCreate BIT = 1;
            --DECLARE @VisualizarAlteracoes BIT = 1;
            --DECLARE @defaultTunningPerform SMALLINT = 100;
            SET TRAN ISOLATION LEVEL READ UNCOMMITTED;

            SET NOCOUNT ON;

            DECLARE @SqlServerVersion VARCHAR(100) = (
                                                         SELECT @@VERSION
                                                     );
            DECLARE @TipoVersao VARCHAR(100) = CASE WHEN CHARINDEX('Azure', @SqlServerVersion) > 0 THEN 'Azure'
                                               WHEN CHARINDEX('Enterprise', @SqlServerVersion) > 0 THEN 'Enterprise' ELSE 'Standard' END;
            DECLARE @tableObjectsIds AS TableIntegerIds;
            DECLARE @QuantidadeMaximaIndiceTabela TINYINT = 5; --(1 PK + 4 NonCluster);

            IF(OBJECT_ID('TEMPDB..#MissingIndex') IS NOT NULL)
                DROP TABLE #MissingIndex;

            IF(OBJECT_ID('TEMPDB..#IndexOnDataBase') IS NOT NULL)
                DROP TABLE #IndexOnDataBase;

            IF(OBJECT_ID('TEMPDB..#NovosIndices') IS NOT NULL)
                DROP TABLE #NovosIndices;

            IF(OBJECT_ID('TEMPDB..#InformacaoesOnTable') IS NOT NULL)
                DROP TABLE #InformacaoesOnTable;

            IF(OBJECT_ID('TEMPDB..#Parcial') IS NOT NULL)
                DROP TABLE #Parcial;

            IF(OBJECT_ID('TEMPDB..#Alteracoes') IS NOT NULL)
                DROP TABLE #Alteracoes;

            IF(OBJECT_ID('TEMPDB..#SchemasExcessao') IS NOT NULL)
                DROP TABLE #SchemasExcessao;

            CREATE TABLE #SchemasExcessao
            (
                SchemaName VARCHAR(128) NOT NULL
            );

            INSERT INTO #SchemasExcessao(SchemaName)VALUES('%HangFire%');

            CREATE TABLE #Alteracoes
            (
                RowId                INT NOT NULL PRIMARY KEY IDENTITY(1, 1),
                [ObjectId]           INT,
                [SchemaName]         VARCHAR(140),
                [TableName]          VARCHAR(140),
                [Chave]              VARCHAR(200),
                [PrimeiraChave]      VARCHAR(200),
                [ColunaIncluida]     VARCHAR(1000),
                [CreateIndex]        VARCHAR(8000),
                [MagicBenefitNumber] REAL,
                [Melhor]             DECIMAL(18, 2),
                ScriptDrop           NVARCHAR(400),
                ScriptCreate         NVARCHAR(400),
            );

            CREATE TABLE #InformacaoesOnTable
            (
                ObjectId                 BIGINT,
                [QuantidadeIndiceTabela] TINYINT
            );

            CREATE TABLE #Parcial
            (
                RowId                       INT NOT NULL IDENTITY(1, 1),
                ObjectId                    INT,
                TotalObjetcId               SMALLINT,
                SchemaName                  VARCHAR(140),
                TableName                   VARCHAR(140),
                IndexName                   VARCHAR(200),
                [Chave]                     VARCHAR(200),
                [PrimeiraChave]             VARCHAR(200),
                [ExisteIndiceNaChave]       INT,
                [ChavePertenceAOutroIndice] INT,
                [QuantidadeIndiceTabela]    TINYINT,
                [ColunaIncluida]            VARCHAR(1000),
                AvgEstimatedImpact          REAL,
                MagicBenefitNumber          REAL,
                PotentialReadOp             INT,
                [reads]                     INT,
                PercCusto                   DECIMAL(10, 2),
                [CreateIndex]               VARCHAR(8000)
            );

            IF(OBJECT_ID('TEMPDB..#ResultAllIndex') IS NOT NULL)
                DROP TABLE #ResultAllIndex;

            CREATE TABLE #ResultAllIndex
            (
                [ObjectId]           INT,
                [ObjectName]         VARCHAR(300),
                [RowsInTable]        INT,
                [IndexName]          VARCHAR(128),
                [Usado]              BIT,
                [UserSeeks]          INT,
                [UserScans]          INT,
                [UserLookups]        INT,
                [UserUpdates]        INT,
                [Reads]              BIGINT,
                [Write]              INT,
                [CountPageSplitPage] INT,
                [PercAproveitamento] DECIMAL(18, 2),
                [PercCustoMedio]     DECIMAL(18, 2),
                [IsBadIndex]         INT,
                [IndexId]            SMALLINT,
                [IndexsizeKB]        BIGINT,
                [IndexsizeMB]        DECIMAL(18, 2),
                [IndexSizePorTipoMB] DECIMAL(18, 2),
                [Chave]              VARCHAR(899),
                PrimeiraChave        AS (IIF(CHARINDEX(',', [Chave], 0) > 0, SUBSTRING([Chave], 0, CHARINDEX(',', [Chave], 0)), [Chave])),
                [ColunasIncluidas]   VARCHAR(899),
                [IsUnique]           BIT,
                [IgnoreDupKey]       BIT,
                [IsprimaryKey]       BIT,
                [IsUniqueConstraint] BIT,
                [FillFact]           TINYINT,
                [AllowRowLocks]      BIT,
                [AllowPageLocks]     BIT,
                [HasFilter]          BIT,
                [TypeIndex]          TINYINT
            );

            IF EXISTS (
                          SELECT 1
                            FROM sys.syscursors AS S
                           WHERE
                              S.cursor_name = 'cursor_CreateOrAlterIndex'
                      )
                BEGIN
                    DEALLOCATE cursor_CreateOrAlterIndex;
                END;

            CREATE TABLE #IndexOnDataBase
            (
                [SnapShotDate]         DATETIME2(3),
                ObjectId               INT,
                [RowsInTable]          INT,
                [ObjectName]           VARCHAR(260),
                [index_id]             SMALLINT,
                [IndexName]            VARCHAR(128),
                [Reads]                BIGINT,
                [Write]                INT,
                [%Aproveitamento]      DECIMAL(18, 2),
                [%Custo Medio]         DECIMAL(18, 2),
                [Perc_scan]            DECIMAL(10, 2),
                AvgPercScan            DECIMAL(10, 2),
                [Media IsBad]          INT,
                [Media Reads]          DECIMAL(10, 2),
                [Media Writes]         DECIMAL(10, 2),
                [Media Aproveitamento] DECIMAL(10, 2),
                [Media Custo]          DECIMAL(10, 2),
                [IsBadIndex]           BIT,
                [MaxAnaliseForTable]   SMALLINT,
                [MaxAnaliseForIndex]   INT,
                [QtdAnalize]           INT,
                [Analise]              SMALLINT,
                [is_unique_constraint] BIT,
                [is_primary_key]       BIT,
                [is_unique]            BIT
            );

            CREATE TABLE #MissingIndex
            (
                ObjectId                    INT,
                [TotalObjetcId]             INT,
                SchemaName                  VARCHAR(140),
                TableName                   VARCHAR(140),
                [IndexName]                 VARCHAR(200),
                [Chave]                     VARCHAR(200),
                [PrimeiraChave]             VARCHAR(200),
                [ExisteIndiceNaChave]       INT,
                [ChavePertenceAOutroIndice] INT,
                [ColunaIncluida]            VARCHAR(1000),
                AvgEstimatedImpact          REAL,
                MagicBenefitNumber          REAL,
                PotentialReadOp             INT,
                [reads]                     INT,
                PercCusto                   DECIMAL(10, 2),
                [CreateIndex]               VARCHAR(8000)
            );

            CREATE TABLE #NovosIndices
            (
                RowId                       INT NOT NULL IDENTITY(1, 1) PRIMARY KEY,
                ObjectId                    INT,
                SchemaName                  VARCHAR(140),
                TableName                   VARCHAR(140),
                IndexName                   VARCHAR(200),
                [Chave]                     VARCHAR(200),
                [PrimeiraChave]             VARCHAR(200),
                [ExisteIndiceNaChave]       INT,
                [ChavePertenceAOutroIndice] INT,
                [QuantidadeIndiceTabela]    TINYINT,
                [ColunaIncluida]            VARCHAR(1000),
                AvgEstimatedImpact          REAL,
                MagicBenefitNumber          REAL,
                PotentialReadOp             INT,
                [reads]                     INT,
                PercCusto                   DECIMAL(10, 2),
                [CreateIndex]               VARCHAR(8000),
                AvgPercScan                 DECIMAL(10, 2)
            );

            INSERT INTO #MissingIndex
            EXEC HealthCheck.uspMissingIndex @defaultTunningPerform = @defaultTunningPerform;

            DELETE S
              FROM #MissingIndex S
                   INNER JOIN(SELECT SSE.SchemaName FROM #SchemasExcessao AS SSE)Filtro ON S.SchemaName LIKE Filtro.SchemaName;

            DELETE MI
              FROM #MissingIndex AS MI
             WHERE
                EXISTS (
                           SELECT *
                             FROM sys.indexes AS I
                            WHERE
                               I.object_id = MI.ObjectId
                               AND I.type_desc = 'CLUSTERED COLUMNSTORE'
                       );

            IF(EXISTS (SELECT * FROM #MissingIndex AS MI))
                BEGIN
                    INSERT INTO #InformacaoesOnTable
                    SELECT T.object_id,
                           IX.TotalIndiceTabela
                      FROM sys.tables T
                           JOIN(
                                   SELECT IX.object_id,
                                          TotalIndiceTabela = COUNT(*)
                                     FROM sys.indexes IX
                                    WHERE
                                       IX.is_disabled = 0
                                       AND IX.is_hypothetical = 0
                                       AND IX.type > 0
                                    GROUP BY
                                       IX.object_id
                               )IX ON T.object_id = IX.object_id
                     WHERE
                        EXISTS (
                                   SELECT * FROM #MissingIndex I WHERE I.ObjectId = IX.object_id
                               );

                    INSERT INTO #Parcial(
                                            ObjectId,
                                            TotalObjetcId,
                                            SchemaName,
                                            TableName,
                                            IndexName,
                                            Chave,
                                            PrimeiraChave,
                                            ExisteIndiceNaChave,
                                            ChavePertenceAOutroIndice,
                                            QuantidadeIndiceTabela,
                                            ColunaIncluida,
                                            AvgEstimatedImpact,
                                            MagicBenefitNumber,
                                            PotentialReadOp,
                                            reads,
                                            PercCusto,
                                            CreateIndex
                                        )
                    SELECT MI.ObjectId,
                           MI.TotalObjetcId,
                           MI.SchemaName,
                           MI.TableName,
                           MI.IndexName,
                           MI.Chave,
                           MI.PrimeiraChave,
                           MI.ExisteIndiceNaChave,
                           MI.ChavePertenceAOutroIndice,
                           Info.QuantidadeIndiceTabela,
                           MI.ColunaIncluida,
                           MI.AvgEstimatedImpact,
                           MI.MagicBenefitNumber,
                           MI.PotentialReadOp,
                           MI.reads,
                           MI.PercCusto,
                           MI.CreateIndex
                      FROM #MissingIndex AS MI
                           JOIN #InformacaoesOnTable Info ON MI.ObjectId = Info.ObjectId;

                    /*Indices de objetos únicos*/
                    INSERT INTO #NovosIndices(
                                                 ObjectId,
                                                 SchemaName,
                                                 TableName,
                                                 IndexName,
                                                 Chave,
                                                 PrimeiraChave,
                                                 ExisteIndiceNaChave,
                                                 ChavePertenceAOutroIndice,
                                                 QuantidadeIndiceTabela,
                                                 ColunaIncluida,
                                                 AvgEstimatedImpact,
                                                 MagicBenefitNumber,
                                                 PotentialReadOp,
                                                 reads,
                                                 PercCusto,
                                                 CreateIndex
                                             )
                    SELECT MI.ObjectId,
                           MI.SchemaName,
                           MI.TableName,
                           MI.IndexName,
                           MI.Chave,
                           MI.PrimeiraChave,
                           MI.ExisteIndiceNaChave,
                           MI.ChavePertenceAOutroIndice,
                           MI.QuantidadeIndiceTabela,
                           MI.ColunaIncluida,
                           MI.AvgEstimatedImpact,
                           MI.MagicBenefitNumber,
                           MI.PotentialReadOp,
                           MI.reads,
                           MI.PercCusto,
                           MI.CreateIndex
                      FROM #Parcial MI
                     WHERE
                        MI.TotalObjetcId = 1
                        AND MI.ExisteIndiceNaChave = 0
                        AND MI.ChavePertenceAOutroIndice = 0
                        AND MI.QuantidadeIndiceTabela < @QuantidadeMaximaIndiceTabela; --  -(quatro indices nonclustered)

                    ;

                    WITH EscolheMelhorIndice
                        AS
                        (
                            SELECT MI.ObjectId,
                                   MI.SchemaName,
                                   MI.TableName,
                                   MI.IndexName,
                                   MI.Chave,
                                   MI.PrimeiraChave,
                                   MI.ExisteIndiceNaChave,
                                   MI.ChavePertenceAOutroIndice,
                                   MI.QuantidadeIndiceTabela,
                                   MI.ColunaIncluida,
                                   MI.AvgEstimatedImpact,
                                   MI.MagicBenefitNumber,
                                   MelhorIndice = ROW_NUMBER() OVER (PARTITION BY MI.ObjectId,
                                                                                  MI.PrimeiraChave
                                                                         ORDER BY
                                                                         MI.MagicBenefitNumber DESC,
                                                                         MI.AvgEstimatedImpact DESC
                                                                    ),
                                   MI.PotentialReadOp,
                                   MI.reads,
                                   MI.PercCusto,
                                   MI.CreateIndex
                              FROM #Parcial AS MI
                             WHERE
                                MI.TotalObjetcId > 1
                                AND MI.QuantidadeIndiceTabela < @QuantidadeMaximaIndiceTabela
                                AND MI.ExisteIndiceNaChave = 0
                                AND MI.ChavePertenceAOutroIndice = 0
                        )
                    INSERT INTO #NovosIndices(
                                                 ObjectId,
                                                 SchemaName,
                                                 TableName,
                                                 IndexName,
                                                 Chave,
                                                 PrimeiraChave,
                                                 ExisteIndiceNaChave,
                                                 ChavePertenceAOutroIndice,
                                                 QuantidadeIndiceTabela,
                                                 ColunaIncluida,
                                                 AvgEstimatedImpact,
                                                 MagicBenefitNumber,
                                                 PotentialReadOp,
                                                 reads,
                                                 PercCusto,
                                                 CreateIndex
                                             )
                    SELECT Escolha.ObjectId,
                           Escolha.SchemaName,
                           Escolha.TableName,
                           Escolha.IndexName,
                           Escolha.Chave,
                           Escolha.PrimeiraChave,
                           Escolha.ExisteIndiceNaChave,
                           Escolha.ChavePertenceAOutroIndice,
                           Escolha.QuantidadeIndiceTabela,
                           Escolha.ColunaIncluida,
                           Escolha.AvgEstimatedImpact,
                           Escolha.MagicBenefitNumber,
                           Escolha.PotentialReadOp,
                           Escolha.reads,
                           Escolha.PercCusto,
                           Escolha.CreateIndex
                      FROM EscolheMelhorIndice Escolha
                     WHERE
                        Escolha.MelhorIndice = 1;

                    IF(EXISTS (
                                  SELECT NI.ObjectId,
                                         NI.PrimeiraChave,
                                         NI.MagicBenefitNumber,
                                         COUNT(*) Total
                                    FROM #NovosIndices AS NI
                                   GROUP BY
                                      NI.ObjectId,
                                      NI.PrimeiraChave,
                                      NI.MagicBenefitNumber
                                  HAVING
                                      COUNT(*) > 1
                              )
                      )
                        BEGIN
                            WITH Dados
                                AS
                                (
                                    SELECT NI.ObjectId,
                                           NI.PrimeiraChave,
                                           NI.Chave,
                                           NI.MagicBenefitNumber,
                                           ROW_NUMBER() OVER (PARTITION BY NI.ObjectId,
                                                                           NI.PrimeiraChave,
                                                                           NI.MagicBenefitNumber
                                                                  ORDER BY
                                                                  LEN(NI.Chave)
                                                             ) ordem
                                      FROM #NovosIndices AS NI
                                )
                            DELETE R FROM Dados R WHERE R.ordem > 1;
                        END;

                    IF(EXISTS (SELECT * FROM #Parcial AS P WHERE P.ExisteIndiceNaChave = 1))
                        BEGIN
                            ;WITH Duplicate
                                 AS
                                 (
                                     SELECT P.ObjectId,
                                            P.SchemaName,
                                            P.TableName,
                                            P.IndexName,
                                            P.PrimeiraChave,
                                            P.ColunaIncluida,
                                            P.MagicBenefitNumber,
                                            RN = ROW_NUMBER() OVER (PARTITION BY P.ObjectId,
                                                                                 P.PrimeiraChave
                                                                        ORDER BY
                                                                        P.MagicBenefitNumber DESC,
                                                                        P.AvgEstimatedImpact DESC
                                                                   )
                                       FROM #Parcial AS P
                                      WHERE
                                         P.ExisteIndiceNaChave = 1
                                 )
                            DELETE R FROM Duplicate R WHERE R.RN > 1;

                            ;WITH MelhoresColunas
                                AS
                                (
                                    SELECT P.ObjectId,
                                           P.SchemaName,
                                           P.TableName,
                                           P.Chave,
                                           P.PrimeiraChave,
                                           P.ColunaIncluida,
                                           P.CreateIndex,
                                           MagicBenefitNumber = CAST(P.MagicBenefitNumber AS DECIMAL(18, 2)),
                                           MaxMagicBenefitNumber = MAX(CAST(P.MagicBenefitNumber AS DECIMAL(18, 2))) OVER (PARTITION BY P.ObjectId, P.PrimeiraChave)
                                      FROM #Parcial AS P
                                     WHERE
                                        P.ExisteIndiceNaChave = 1
                                )
                            INSERT INTO #Alteracoes(
                                                       ObjectId,
                                                       SchemaName,
                                                       TableName,
                                                       Chave,
                                                       PrimeiraChave,
                                                       ColunaIncluida,
                                                       CreateIndex,
                                                       MagicBenefitNumber,
                                                       Melhor,
                                                       ScriptDrop,
                                                       ScriptCreate
                                                   )
                            SELECT P.ObjectId,
                                   P.SchemaName,
                                   P.TableName,
                                   P.Chave,
                                   P.PrimeiraChave,
                                   P.ColunaIncluida,
                                   P.CreateIndex,
                                   P.MagicBenefitNumber,
                                   P.MaxMagicBenefitNumber,
                                   NULL,
                                   NULL
                              FROM MelhoresColunas AS P
                             WHERE
                                P.MagicBenefitNumber = P.MaxMagicBenefitNumber;

                            INSERT INTO #ResultAllIndex
                            EXEC HealthCheck.uspAllIndex @TableObjectIds = @tableObjectsIds;

                            DELETE RAI FROM #ResultAllIndex AS RAI WHERE RAI.TypeIndex = 1;

                            IF(EXISTS (
                                          SELECT * FROM #Alteracoes AS A WHERE A.ColunaIncluida IS NOT NULL
                                      )
                              )
                                BEGIN

                                    /* declare variables */
                                    DECLARE @RowId              INT,
                                            @TempObjectId       INT,
                                            @TempSchemaName     VARCHAR(128),
                                            @TempTableName      VARCHAR(128),
                                            @TempChave          VARCHAR(500),
                                            @TempPrimeiraChave  VARCHAR(128),
                                            @TempColunaIncluida VARCHAR(999);

                                    DECLARE cursor_AlteraIndex CURSOR FAST_FORWARD READ_ONLY FOR
                                    SELECT A.RowId,
                                           A.ObjectId,
                                           A.SchemaName,
                                           A.TableName,
                                           A.Chave,
                                           A.PrimeiraChave,
                                           A.ColunaIncluida
                                      FROM #Alteracoes A;

                                    OPEN cursor_AlteraIndex;

                                    FETCH NEXT FROM cursor_AlteraIndex
                                     INTO @RowId,
                                          @TempObjectId,
                                          @TempSchemaName,
                                          @TempTableName,
                                          @TempChave,
                                          @TempPrimeiraChave,
                                          @TempColunaIncluida;

                                    WHILE @@FETCH_STATUS = 0
                                        BEGIN
                                            DECLARE @ColunaIncluidaAntiga VARCHAR(1000);

                                            ;WITH ColunaIncluidaAntiga
                                                AS
                                                (
                                                    SELECT RAI.ObjectId,
                                                           RAI.IndexName,
                                                           RAI.Chave,
                                                           RAI.ColunasIncluidas,
                                                           RAI.PercAproveitamento,
                                                           MenorAproveitamento = MIN(RAI.PercAproveitamento) OVER (PARTITION BY RAI.ObjectId,
                                                                                                                                RAI.PrimeiraChave
                                                                                                                       ORDER BY
                                                                                                                       RAI.PercAproveitamento
                                                                                                                  )
                                                      FROM #ResultAllIndex AS RAI
                                                     WHERE
                                                        RAI.ObjectId = @TempObjectId
                                                        AND RAI.ColunasIncluidas IS NOT NULL
                                                        AND RAI.PrimeiraChave = @TempPrimeiraChave
                                                )
                                            SELECT @ColunaIncluidaAntiga = (
                                                                               SELECT TOP 1 C.ColunasIncluidas
                                                                                 FROM ColunaIncluidaAntiga C
                                                                                WHERE
                                                                                   C.PercAproveitamento = C.MenorAproveitamento
                                                                           );

                                            DECLARE @indexNameTemp VARCHAR(128);

                                            ;WITH PiorIndice
                                                AS
                                                (
                                                    SELECT RAI.IndexName,
                                                           RAI.PercAproveitamento,
                                                           MIN(RAI.PercAproveitamento) OVER () AS MenorAproveitamento
                                                      FROM #ResultAllIndex AS RAI
                                                     WHERE
                                                        RAI.ObjectId = @TempObjectId
                                                        AND RAI.PrimeiraChave = @TempPrimeiraChave
                                                        AND RAI.TypeIndex > 1
                                                )
                                            SELECT @indexNameTemp = PiorIndice.IndexName
                                              FROM PiorIndice
                                             WHERE
                                                PiorIndice.PercAproveitamento = PiorIndice.MenorAproveitamento;

                                            IF(@ColunaIncluidaAntiga IS NOT NULL)
                                                BEGIN
                                                    DECLARE @NewColluns VARCHAR(999) = (
                                                                                           SELECT STUFF((
                                                                                                            SELECT ', ' + t2.Conteudo
                                                                                                              FROM(
                                                                                                                      SELECT FSV.Conteudo
                                                                                                                        FROM(
                                                                                                                                SELECT C2.Conteudo
                                                                                                                                  FROM sys.tables AS T
                                                                                                                                       JOIN sys.columns AS C ON T.object_id = C.object_id
                                                                                                                                       JOIN sys.types AS t2 ON C.user_type_id = t2.user_type_id
                                                                                                                                       CROSS APPLY(
                                                                                                                                                      SELECT FSV.Conteudo
                                                                                                                                                        FROM Sistema.fnSplitValues(@TempColunaIncluida, ',') FSV
                                                                                                                                                       WHERE
                                                                                                                                                          FSV.Conteudo COLLATE DATABASE_DEFAULT = C.name COLLATE DATABASE_DEFAULT
                                                                                                                                                  )C2
                                                                                                                                 WHERE
                                                                                                                                    T.object_id = @TempObjectId
                                                                                                                                    AND C.is_sparse = 0
                                                                                                                                    AND C.xml_collection_id = 0
                                                                                                                                    AND C.is_xml_document = 0
                                                                                                                                    AND C.is_computed = 0
                                                                                                                                    AND C.max_length <> -1
                                                                                                                                    AND t2.name NOT IN ('xml', 'varbinary', 'sql_variant', 'nvarchar')
                                                                                                                            ) AS FSV
                                                                                                                      UNION
                                                                                                                      SELECT FSV2.Conteudo
                                                                                                                        FROM(
                                                                                                                                SELECT C2.Conteudo
                                                                                                                                  FROM sys.tables AS T
                                                                                                                                       JOIN sys.columns AS C ON T.object_id = C.object_id
                                                                                                                                       JOIN sys.types AS t2 ON C.user_type_id = t2.user_type_id
                                                                                                                                       CROSS APPLY(
                                                                                                                                                      SELECT FSV.Conteudo
                                                                                                                                                        FROM Sistema.fnSplitValues(@ColunaIncluidaAntiga, ',') FSV
                                                                                                                                                       WHERE
                                                                                                                                                          FSV.Conteudo COLLATE DATABASE_DEFAULT = C.name COLLATE DATABASE_DEFAULT
                                                                                                                                                  )C2
                                                                                                                                 WHERE
                                                                                                                                    T.object_id = @TempObjectId
                                                                                                                                    AND C.is_sparse = 0
                                                                                                                                    AND C.xml_collection_id = 0
                                                                                                                                    AND C.is_xml_document = 0
                                                                                                                                    AND C.is_computed = 0
                                                                                                                                    AND C.max_length <> -1
                                                                                                                                    AND t2.name NOT IN ('xml', 'varbinary', 'sql_variant', 'nvarchar')
                                                                                                                            ) AS FSV2
                                                                                                                  ) AS t2
                                                                                                            FOR XML PATH(''), TYPE
                                                                                                        ).value('.', 'varchar(max)'), 1, 2, ''
                                                                                                       )
                                                                                       );
                                                END;

                                            IF(LEN(@indexNameTemp) > 0)
                                                BEGIN
                                                    UPDATE A
                                                       SET A.ScriptDrop = CONCAT('DROP INDEX ', QUOTENAME(@indexNameTemp), ' ON ', QUOTENAME(@TempSchemaName), '.', QUOTENAME(@TempTableName)),
                                                           A.CreateIndex = CONCAT('CREATE INDEX ', QUOTENAME(CONCAT('IX_', @TempSchemaName, @TempTableName, '_', REPLACE(@TempChave, ',', '_'))), ' ON ', QUOTENAME(@TempSchemaName), '.', QUOTENAME(@TempTableName), ' (', @TempChave, ') ', IIF(@NewColluns IS NOT NULL AND LEN(@NewColluns) > 0, ' INCLUDE (' + @NewColluns + ')', ''))
                                                      FROM #Alteracoes AS A
                                                     WHERE
                                                        A.RowId = @RowId;
                                                END;

                                            FETCH NEXT FROM cursor_AlteraIndex
                                             INTO @RowId,
                                                  @TempObjectId,
                                                  @TempSchemaName,
                                                  @TempTableName,
                                                  @TempChave,
                                                  @TempPrimeiraChave,
                                                  @TempColunaIncluida;
                                        END;

                                    CLOSE cursor_AlteraIndex;
                                    DEALLOCATE cursor_AlteraIndex;
                                END;
                        END;

                    DECLARE @whith VARCHAR(100) = CASE WHEN @TipoVersao IN ('Azure', 'Enterprise') THEN 'WITH(ONLINE =ON ,DATA_COMPRESSION =PAGE)'
                                                  WHEN @TipoVersao IN ('Standard') THEN 'WITH(DATA_COMPRESSION =PAGE)' ELSE '' END;

                    UPDATE #NovosIndices
                       SET CreateIndex = CONCAT(CreateIndex, SPACE(2), @whith);

                    UPDATE #Alteracoes SET CreateIndex = CONCAT(CreateIndex, SPACE(2), @whith);

                    IF(EXISTS (SELECT * FROM #NovosIndices AS NI) AND @Efetivar = 1)
                        BEGIN
                            /* declare variables */
                            DECLARE @ObjectId  VARCHAR(128),
                                    @IndexName VARCHAR(128);
                            DECLARE @Script NVARCHAR(1000);

                            DECLARE cursor_CriaIndice CURSOR FAST_FORWARD READ_ONLY FOR
                            SELECT NI.ObjectId, NI.IndexName, NI.CreateIndex FROM #NovosIndices AS NI;

                            OPEN cursor_CriaIndice;

                            FETCH NEXT FROM cursor_CriaIndice
                             INTO @ObjectId,
                                  @IndexName,
                                  @Script;

                            WHILE @@FETCH_STATUS = 0
                                BEGIN
                                    IF(@Script IS NOT NULL)
                                        BEGIN
                                            EXEC sys.sp_executesql @Script;
                                        END;

                                    FETCH NEXT FROM cursor_CriaIndice
                                     INTO @ObjectId,
                                          @IndexName,
                                          @Script;
                                END;

                            CLOSE cursor_CriaIndice;
                            DEALLOCATE cursor_CriaIndice;
                        END;

                    IF(EXISTS (SELECT * FROM #Alteracoes AS RA) AND @Efetivar = 1)
                        BEGIN

                            /* declare variables */
                            DECLARE @RaObjectId  VARCHAR(128),
                                    @DeleteIndex NVARCHAR(1000),
                                    @NewIndex    NVARCHAR(1000);

                            DECLARE cursor_DeletaIndiceECriaNovo CURSOR FAST_FORWARD READ_ONLY FOR
                            SELECT NI.ObjectId, NI.ScriptDrop, NI.CreateIndex FROM #Alteracoes AS NI;

                            OPEN cursor_DeletaIndiceECriaNovo;

                            FETCH NEXT FROM cursor_DeletaIndiceECriaNovo
                             INTO @RaObjectId,
                                  @DeleteIndex,
                                  @NewIndex;

                            WHILE @@FETCH_STATUS = 0
                                BEGIN
                                    EXEC sys.sp_executesql @DeleteIndex;

                                    EXEC sys.sp_executesql @NewIndex;

                                    FETCH NEXT FROM cursor_DeletaIndiceECriaNovo
                                     INTO @RaObjectId,
                                          @DeleteIndex,
                                          @NewIndex;
                                END;

                            CLOSE cursor_DeletaIndiceECriaNovo;
                            DEALLOCATE cursor_DeletaIndiceECriaNovo;
                        END;
                END;

            IF(@VisualizarMissing = 1)
                BEGIN
                    SELECT 'Missings' AS Sugestao,
                           MI.ObjectId,
                           MI.TotalObjetcId,
                           MI.SchemaName,
                           MI.TableName,
                           IOT.QuantidadeIndiceTabela,
                           MI.IndexName,
                           MI.Chave,
                           MI.PrimeiraChave,
                           MI.ExisteIndiceNaChave,
                           MI.ChavePertenceAOutroIndice,
                           MI.ColunaIncluida,
                           MI.AvgEstimatedImpact,
                           MI.MagicBenefitNumber,
                           MI.PotentialReadOp,
                           MI.reads,
                           PercCustoMedio = MI.PercCusto,
                           MI.CreateIndex
                      FROM #MissingIndex MI
                           JOIN #InformacaoesOnTable AS IOT ON MI.ObjectId = IOT.ObjectId;
                END;

            IF(@VisualizarCreate = 1)
                BEGIN
                    SELECT 'Create' AS Sugestao,
                           NI.RowId,
                           NI.ObjectId,
                           NI.SchemaName,
                           NI.TableName,
                           NI.QuantidadeIndiceTabela,
                           NI.IndexName,
                           NI.Chave,
                           NI.PrimeiraChave,
                           NI.ExisteIndiceNaChave,
                           NI.ChavePertenceAOutroIndice,
                           NI.ColunaIncluida,
                           NI.AvgEstimatedImpact,
                           NI.MagicBenefitNumber,
                           NI.PotentialReadOp,
                           NI.reads,
                           PercCustoMedio = NI.PercCusto,
                           NI.CreateIndex,
                           PercScan = NI.AvgPercScan
                      FROM #NovosIndices AS NI;
                END;

            IF(@VisualizarAlteracoes = 1)
                BEGIN
                    SELECT 'Alteracao' AS Sugestao,
                           A.RowId,
                           A.ObjectId,
                           A.SchemaName,
                           A.TableName,
                           A.Chave,
                           A.PrimeiraChave,
                           A.ColunaIncluida,
                           A.CreateIndex,
                           A.MagicBenefitNumber,
                           A.Melhor,
                           A.ScriptDrop,
                           A.ScriptCreate
                      FROM #Alteracoes AS A;
                END;
        END TRY
        BEGIN CATCH
            IF(@@TRANCOUNT > 0)
                ROLLBACK TRANSACTION;

            DECLARE @ErrorNumber INT = ERROR_NUMBER();
            DECLARE @ErrorLine INT = ERROR_LINE();
            DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
            DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
            DECLARE @ErrorState INT = ERROR_STATE();

            PRINT 'Actual error number: ' + CAST(@ErrorNumber AS VARCHAR(MAX));
            PRINT 'Actual line number: ' + CAST(@ErrorLine AS VARCHAR(MAX));
            PRINT '@ErrorMessage: ' + CAST(@ErrorMessage AS VARCHAR(MAX));
            PRINT '@ErrorSeverity: ' + CAST(@ErrorLine AS VARCHAR(MAX));
            PRINT '@ErrorState: ' + CAST(@ErrorLine AS VARCHAR(MAX));

            RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);

            PRINT 'Error detected, all changes reversed.';
        END CATCH;
    END;
GO

SET QUOTED_IDENTIFIER ON;

SET ANSI_NULLS ON;
GO

/* ==================================================================
--Data: 29/10/2018 
--Autor :Wesley Neves
--Observação: 
https://sqlperformance.com/2015/04/sql-indexes/mitigating-index-fragmentation
https://ola.hallengren.com/sql-server-index-and-statistics-maintenance.html
https://www.red-gate.com/simple-talk/sql/database-administration/defragmenting-indexes-in-sql-server-2005-and-2008/
https://www.sqlskills.com/blogs/paul/indexes-from-every-angle-how-can-you-tell-if-an-index-is-being-used/
https://blog.sqlserveronline.com/2017/11/18/sql-server-activity-monitor-and-page-splits-per-second-tempdb/
https://techcommunity.microsoft.com/t5/Premier-Field-Engineering/Three-Usage-Scenarios-for-sys-dm-db-index-operational-stats/ba-p/370298
 
-- ==================================================================
*/

--PK_CadastroEmails	70	90	2561
--IX_Emails_IdPessoa	100	90	2259

--exec HealthCheck.uspIndexDesfrag @Efetivar =1

CREATE OR ALTER PROCEDURE HealthCheck.uspIndexDesfrag
(
    @MostrarIndices BIT      = 1,
    @MinFrag        SMALLINT = 10,
    @MinPageCount   SMALLINT = 1000,
    @Efetivar       BIT      = 0
)
AS
    BEGIN
        SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

        SET NOCOUNT ON;

        DECLARE @SqlServerVersion VARCHAR(100) = (
                                                     SELECT @@VERSION
                                                 );
        DECLARE @TipoVersao VARCHAR(100) = CASE WHEN CHARINDEX('Azure', @SqlServerVersion) > 0 THEN 'Azure'
                                           WHEN CHARINDEX('Enterprise', @SqlServerVersion) > 0 THEN 'Enterprise' ELSE 'Standard' END;

        --DECLARE @MostrarIndices BIT      = 1,
        --        @MinFrag        SMALLINT = 10,
        --        @MinPageCount   SMALLINT = 1000,
        --        @Efetivar       BIT      = 0;
        DECLARE @SchemasExcecao TABLE
        (
            SchemaName VARCHAR(128)
        );

        DECLARE @TableExcecao TABLE
        (
            TableName VARCHAR(128)
        );

        INSERT INTO @SchemasExcecao(SchemaName)VALUES('Expurgo');

        INSERT INTO @TableExcecao(TableName)VALUES('LogsDetalhes');

        DECLARE @MinFillFactorLevel3 TINYINT = 15;
        DECLARE @MinFillFactorLevel4 TINYINT = 10;
        DECLARE @MinFillFactorLevel5 TINYINT = 5;
        DECLARE @MinFillFactorLevel6 TINYINT = 100; -- 100 %

        IF(OBJECT_ID('TEMPDB..#Fragmentacao') IS NOT NULL)
            DROP TABLE #Fragmentacao;

        IF(OBJECT_ID('TEMPDB..#IndicesDesfragmentar') IS NOT NULL)
            DROP TABLE #IndicesDesfragmentar;

        CREATE TABLE #Fragmentacao
        (
            ObjectId                     INT,
            IndexId                      INT,
            [index_type_desc]            NVARCHAR(60),
            AvgFragmentationInPercent    FLOAT(8),
            [fragment_count]             BIGINT,
            [avg_fragment_size_in_pages] FLOAT(8),
            PageCount                    BIGINT PRIMARY KEY(ObjectId, IndexId)
        );

        CREATE TABLE #IndicesDesfragmentar
        (
            ObjectId                        INT,
            IndexId                         SMALLINT,
            [SchemaName]                    VARCHAR(128),
            [TableName]                     VARCHAR(128),
            IndexName                       VARCHAR(128),
            FillFact                        TINYINT,
            NewFillFact                     TINYINT     NULL,
            PageSpltForIndex                INT,
            PageAllocationCausedByPageSplit INT,
            AvgFragmentationInPercent       FLOAT,
            PageCount                       INT,
            [Alteracoes]                    BIGINT      PRIMARY KEY(ObjectId, IndexId)
        );

        INSERT INTO #Fragmentacao
        SELECT A.object_id,
               A.index_id,
               A.index_type_desc,
               A.avg_fragmentation_in_percent,
               A.fragment_count,
               A.avg_fragment_size_in_pages,
               A.page_count
          FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, NULL) AS A
         WHERE
            A.alloc_unit_type_desc IN (N'IN_ROW_DATA', N'ROW_OVERFLOW_DATA')
            AND A.object_id NOT IN(
                                      SELECT T.object_id FROM sys.tables AS T WHERE T.name = 'LogsJson'
                                  )
            AND A.page_count > @MinPageCount
            AND A.avg_fragmentation_in_percent >= @MinFrag;

        IF(EXISTS (SELECT 1 FROM #Fragmentacao AS F))
            BEGIN
                INSERT INTO #IndicesDesfragmentar(
                                                     ObjectId,
                                                     IndexId,
                                                     SchemaName,
                                                     TableName,
                                                     IndexName,
                                                     FillFact,
                                                     PageSpltForIndex,
                                                     PageAllocationCausedByPageSplit,
                                                     AvgFragmentationInPercent,
                                                     PageCount,
                                                     Alteracoes
                                                 )
                SELECT CAST(IOS.object_id AS INT),
                       CAST(IOS.index_id AS SMALLINT),
                       CAST(S.name AS VARCHAR(128)) AS SchemaName,
                       CAST(T.name AS VARCHAR(128)) TableName,
                       CAST(I.name AS VARCHAR(128)) INDEX_NAME,
                       CAST(I.fill_factor AS TINYINT),
                       CAST(IOS.leaf_allocation_count AS INT) AS PAGE_SPLIT_FOR_INDEX,
                       CAST(IOS.nonleaf_allocation_count AS INT) PageAllocationCausedByPageSplit,
                       F.AvgFragmentationInPercent,
                       CAST(F.PageCount AS INT),
                       Alteracoes = (IOS.leaf_insert_count + IOS.leaf_delete_count + IOS.leaf_update_count)
                  FROM sys.dm_db_index_operational_stats(DB_ID(), NULL, NULL, NULL) IOS
                       JOIN #Fragmentacao AS F ON IOS.object_id = F.ObjectId
                                                  AND IOS.index_id = F.IndexId
                       JOIN sys.indexes I ON IOS.index_id = I.index_id
                                             AND IOS.object_id = I.object_id
                       JOIN sys.tables AS T ON I.object_id = T.object_id
                       JOIN sys.schemas AS S ON T.schema_id = S.schema_id
                 WHERE
                    I.type = 2 -- NO HEAP'
                    AND S.name NOT IN(
                                         SELECT SE.SchemaName COLLATE DATABASE_DEFAULT FROM @SchemasExcecao AS SE
                                     )
                    AND T.name NOT IN(
                                         SELECT TE.TableName COLLATE DATABASE_DEFAULT FROM @TableExcecao AS TE
                                     )
                OPTION(MAXDOP 0);

                UPDATE IX
                   SET IX.FillFact = CASE WHEN IX.FillFact = 0 THEN 100
                                     WHEN IX.FillFact = 10 THEN 90
                                     WHEN IX.FillFact = 20 THEN 80
                                     WHEN IX.FillFact = 30 THEN 70
                                     WHEN IX.FillFact = 40 THEN 60 ELSE 100 END
                  FROM #IndicesDesfragmentar IX;

                UPDATE FRAG
                   SET FRAG.NewFillFact = CASE WHEN(FRAG.PageSpltForIndex) >= 500 THEN FRAG.FillFact - @MinFillFactorLevel3 ELSE FRAG.NewFillFact END
                  FROM #IndicesDesfragmentar FRAG
                 WHERE
                    FRAG.NewFillFact IS NULL;

                UPDATE FRAG
                   SET FRAG.NewFillFact = CASE WHEN(FRAG.PageSpltForIndex) >= 100 THEN FRAG.FillFact - @MinFillFactorLevel4 ELSE FRAG.NewFillFact END
                  FROM #IndicesDesfragmentar FRAG
                 WHERE
                    FRAG.NewFillFact IS NULL;

                UPDATE FRAG
                   SET FRAG.NewFillFact = CASE WHEN(FRAG.PageSpltForIndex) >= 50 THEN FRAG.FillFact - @MinFillFactorLevel5 END
                  FROM #IndicesDesfragmentar FRAG
                 WHERE
                    FRAG.NewFillFact IS NULL;

                UPDATE FRAG
                   SET FRAG.NewFillFact = @MinFillFactorLevel6
                  FROM #IndicesDesfragmentar FRAG
                 WHERE
                    FRAG.NewFillFact IS NULL;

                /* declare variables */
                DECLARE @SchemaName                   VARCHAR(128),
                        @TableName                    VARCHAR(128),
                        @IndexName                    VARCHAR(128),
                        @fill_factor                  TINYINT,
                        @Newfill_factor               TINYINT,
                        @avg_fragmentation_in_percent DECIMAL(8, 2);
                DECLARE @StartTime DATETIME = GETDATE();
                DECLARE @Mensagem VARCHAR(1000);

                IF(EXISTS (SELECT 1 FROM #IndicesDesfragmentar AS FI) AND @Efetivar = 1)
                    BEGIN
                        DECLARE cursor_Fragmentacao CURSOR FAST_FORWARD READ_ONLY FOR
                        SELECT FI.SchemaName,
                               FI.TableName,
                               FI.IndexName,
                               FI.FillFact,
                               FI.NewFillFact,
                               FI.AvgFragmentationInPercent
                          FROM #IndicesDesfragmentar AS FI;

                        OPEN cursor_Fragmentacao;

                        FETCH NEXT FROM cursor_Fragmentacao
                         INTO @SchemaName,
                              @TableName,
                              @IndexName,
                              @fill_factor,
                              @Newfill_factor,
                              @avg_fragmentation_in_percent;

                        WHILE @@FETCH_STATUS = 0
                            BEGIN
                                DECLARE @Script NVARCHAR(1000);

                                SET @Script = CONCAT('ALTER INDEX ', QUOTENAME(@IndexName), SPACE(1), 'ON', SPACE(1), QUOTENAME(@SchemaName), '.', QUOTENAME(@TableName), IIF(@avg_fragmentation_in_percent <= 35, ' REORGANIZE ', ' REBUILD'));

                                IF(@avg_fragmentation_in_percent > 35)
                                    BEGIN
                                        SET @Script = CONCAT(@Script, ' WITH (' + IIF(@TipoVersao IN ('Azure', 'Enterprise'), 'ONLINE=ON ,DATA_COMPRESSION = PAGE,', '') + 'MAXDOP = 8, SORT_IN_TEMPDB= ON , FILLFACTOR =', @Newfill_factor, ')');
                                    END;

                                SET @StartTime = GETDATE();

                                EXEC sys.sp_executesql @Script;

                                IF(@MostrarIndices = 1)
                                    BEGIN
                                        SET @Mensagem = CONCAT('Comando :', @Script, ' Executado em :', DATEDIFF(MILLISECOND, @StartTime, GETDATE()), ' MS');

                                        RAISERROR(@Mensagem, 0, 1)WITH NOWAIT;
                                    END;

                                FETCH NEXT FROM cursor_Fragmentacao
                                 INTO @SchemaName,
                                      @TableName,
                                      @IndexName,
                                      @fill_factor,
                                      @Newfill_factor,
                                      @avg_fragmentation_in_percent;
                            END;

                        CLOSE cursor_Fragmentacao;
                        DEALLOCATE cursor_Fragmentacao;
                    END;
            END;

        IF(@MostrarIndices = 1)
            BEGIN
                SELECT * FROM #IndicesDesfragmentar AS FI;
            END;
    END;
GO

SET QUOTED_IDENTIFIER ON;

SET ANSI_NULLS ON;
GO

CREATE OR ALTER PROCEDURE HealthCheck.uspAutoCreateStats
(
    @MostrarStatistica              BIT = 1,
    @Efetivar                       BIT = 0,
    @NumberLinesToDetermineFullScan INT = 100000
)
AS
    BEGIN TRY
        SET NOCOUNT ON;

        SET TRAN ISOLATION LEVEL READ UNCOMMITTED;

        /* ==================================================================
--Data: 01/11/2018 
--Autor :Wesley Neves
--Observação:  Cria as Statisticas Colunares
-- ==================================================================
*/
        /*Region Logical Querys*/

        --DECLARE @MostrarStatistica BIT = 1;
        --DECLARE @Efetivar BIT = 1;
        IF(OBJECT_ID('TEMPDB..#CreateStats') IS NOT NULL)
            DROP TABLE #CreateStats;

        CREATE TABLE #CreateStats
        (
            ObjectId   INT,
            SchemaName VARCHAR(128),
            TableName  VARCHAR(128),
            Rows       BIGINT,
            ColumnId   INT,
            Collun     VARCHAR(128),
            Type       VARCHAR(128),
            UserTypeId INT,
            MaxLength  SMALLINT,
            precision  TINYINT,
            IsNullable BIT,
            IsComputed BIT,
            Script     VARCHAR(825)
        );

        WITH AllCollunsNotStatis
            AS
            (
                SELECT T.object_id,
                       SchemaName = S.name,
                       TableName = T.name,
                       SI.rowcnt AS Rows,
                       C.column_id,
                       Collun = C.name,
                       Type = T2.name,
                       C.user_type_id,
                       C.max_length,
                       C.precision,
                       C.is_nullable,
                       C.is_computed
                  FROM sys.tables AS T
                       JOIN sys.sysindexes AS SI ON SI.id = T.object_id
                                                    AND SI.indid = 1
                       JOIN sys.schemas AS S ON T.schema_id = S.schema_id
                       JOIN sys.columns AS C ON T.object_id = C.object_id
                       JOIN sys.types AS T2 ON T2.user_type_id = C.user_type_id
                 WHERE
                    NOT EXISTS (
                                   SELECT S.object_id,
                                          S.name,
                                          SC.column_id
                                     FROM sys.stats AS S
                                          JOIN sys.stats_columns AS SC ON S.object_id = SC.object_id
                                                                          AND S.stats_id = SC.stats_id
                                    WHERE
                                       S.object_id = T.object_id
                                       AND SC.column_id = C.column_id
                               )
                    AND C.is_replicated = 0
                    AND C.is_filestream = 0
                    AND C.is_xml_document = 0
                    AND T2.is_table_type = 0
                    AND SI.rowcnt > 200
                    AND C.column_id > 1
                    AND T2.name NOT IN ('varbinary', 'nvarchar', 'XML')
                    AND NOT(
                               T2.name = 'varchar'
                               AND C.max_length = -1
                           )
                    AND NOT(
                               T2.name = 'varchar'
                               AND C.max_length > 30
                           )
                    AND S.name NOT IN ('Log')
                    AND COLUMNPROPERTY(T.object_id, C.name, 'IsDeterministic') IS NULL
                    AND T.object_id IN(
                                          SELECT object_id
                                            FROM sys.dm_db_index_usage_stats A
                                           WHERE
                                              (A.user_seeks + A.user_scans + A.user_lookups) > 0
                                      )
            )
        INSERT INTO #CreateStats
        SELECT AX.object_id,
               AX.SchemaName,
               AX.TableName,
               AX.Rows,
               AX.column_id,
               AX.Collun,
               AX.Type,
               AX.user_type_id,
               AX.max_length,
               AX.precision,
               AX.is_nullable,
               AX.is_computed,
               Script = CONCAT('CREATE ', SPACE(1), 'STATISTICS', SPACE(1), '', 'Stats_', AX.SchemaName, AX.TableName, AX.Collun, '', SPACE(1), 'ON', SPACE(1), '', AX.SchemaName, '', '.', '', AX.TableName, '(', QUOTENAME(AX.Collun), ')', (IIF(AX.Rows <= @NumberLinesToDetermineFullScan, ' WITH  FULLSCAN', '')))
          FROM AllCollunsNotStatis AX;

        IF(EXISTS (SELECT 1 FROM #CreateStats) AND @Efetivar = 1)
            BEGIN

                /* declare variables */
                DECLARE @object_id INT;
                DECLARE @SchemaName VARCHAR(128);
                DECLARE @TableName VARCHAR(128);
                DECLARE @Collun VARCHAR(128);
                DECLARE @Script NVARCHAR(1000);
                DECLARE @StartTime DATETIME = GETDATE();
                DECLARE @Mensagem VARCHAR(1000);

                DECLARE cursor_CreatStats CURSOR FAST_FORWARD READ_ONLY FOR
                SELECT CS.ObjectId,
                       CS.SchemaName,
                       CS.TableName,
                       CS.Collun,
                       CS.Script
                  FROM #CreateStats AS CS;

                OPEN cursor_CreatStats;

                FETCH NEXT FROM cursor_CreatStats
                 INTO @object_id,
                      @SchemaName,
                      @TableName,
                      @Collun,
                      @Script;

                WHILE @@FETCH_STATUS = 0
                    BEGIN
                        SET @StartTime = GETDATE();

                        EXEC sys.sp_executesql @Script;

                        IF(@MostrarStatistica = 1)
                            BEGIN
                                SET @Mensagem = CONCAT('Comando :', @Script, ' Executado em :', DATEDIFF(MILLISECOND, @StartTime, GETDATE()), ' MS');

                                RAISERROR(@Mensagem, 0, 1)WITH NOWAIT;
                            END;

                        FETCH NEXT FROM cursor_CreatStats
                         INTO @object_id,
                              @SchemaName,
                              @TableName,
                              @Collun,
                              @Script;
                    END;

                CLOSE cursor_CreatStats;
                DEALLOCATE cursor_CreatStats;
            END;

        IF(@MostrarStatistica = 1)
            BEGIN
                SELECT * FROM #CreateStats AS CS;
            END;
    END TRY
    BEGIN CATCH
        DECLARE @ErrorNumber INT = ERROR_NUMBER();
        DECLARE @ErrorLine INT = ERROR_LINE();
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();

        PRINT 'Actual error number: ' + CAST(@ErrorNumber AS VARCHAR(MAX));
        PRINT 'Actual line number: ' + CAST(@ErrorLine AS VARCHAR(MAX));
        PRINT '@ErrorMessage: ' + CAST(@ErrorMessage AS VARCHAR(MAX));
        PRINT '@ErrorSeverity: ' + CAST(@ErrorLine AS VARCHAR(MAX));
        PRINT '@ErrorState: ' + CAST(@ErrorLine AS VARCHAR(MAX));

        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);

        PRINT 'Error detected, all changes reversed.';
    END CATCH;
GO

SET QUOTED_IDENTIFIER ON;

SET ANSI_NULLS ON;
GO

CREATE OR ALTER PROCEDURE Log.uspExpurgoLogsJson
AS
    BEGIN
        SET XACT_ABORT ON;

        IF(OBJECT_ID('TEMPDB..#Configuracoes') IS NOT NULL)
            DROP TABLE #Configuracoes;

        CREATE TABLE #Configuracoes
        (
            Configuracao VARCHAR(100),
            Valor        VARCHAR(100)
        );

        DECLARE @QuantidadeMesesPadraoExpurgarLogs TINYINT = 3;
        DECLARE @QuantidadeMesesPadraoLogsExpurgo TINYINT = 12;

        /*Region Logical Querys*/
        DECLARE @UtilizaArmazenamentoLogsJSON BIT = (
                                                        SELECT TOP 1 ISNULL(TRY_CAST(C.Valor AS BIT), 0)
                                                          FROM Sistema.Configuracoes AS C
                                                         WHERE
                                                            C.Configuracao = 'UtilizaArmazenamentoLogsJSON'
                                                    );
        DECLARE @ExecutouMigracaoLogsJSON BIT = (
                                                    SELECT TOP 1 ISNULL(TRY_CAST(C.Valor AS BIT), 0)
                                                      FROM Sistema.Configuracoes AS C
                                                     WHERE
                                                        C.Configuracao = 'ExecutouMigracaoLogsJSON'
                                                );

        IF(@UtilizaArmazenamentoLogsJSON = 0)
            BEGIN
                THROW 50000, 'Configuração @UtilizaArmazenamentoLogsJSON está com valor incorreto para a execução da procedure', 1;
            END;

        IF(@ExecutouMigracaoLogsJSON = 0)
            BEGIN
                THROW 50000, 'Configuração @ExecutouMigracaoLogsJSON está com valor incorreto para a execução da procedure', 1;
            END;

        DECLARE @DataExecucaoExpurgo DATE = (
                                                SELECT TOP 1 TRY_CAST(C.Valor AS DATE)
                                                  FROM Sistema.Configuracoes AS C
                                                 WHERE
                                                    C.Configuracao = 'DataExecucaoExpurgo'
                                            );
        DECLARE @hoje DATE = GETDATE();
        DECLARE @PrimeiroDiaMes DATE = DATEFROMPARTS(YEAR(@hoje), MONTH(@hoje), 1);

        INSERT INTO #Configuracoes(
                                      Configuracao,
                                      Valor
                                  )
        VALUES(   'Data Configurada para o expurgo', -- COnfiguracao - varchar(100)
                  @DataExecucaoExpurgo
              );

        DECLARE @QtdMesExpurgoLogsAuditoria TINYINT = (
                                                          SELECT TOP 1 ISNULL(TRY_CAST(C.Valor AS TINYINT), @QuantidadeMesesPadraoExpurgarLogs)
                                                            FROM Sistema.Configuracoes AS C
                                                           WHERE
                                                              C.Configuracao = 'QtdMesExpurgoLogsAuditoria'
                                                      );
        DECLARE @QtdMesDeletarRegistrosLogsExpurgo TINYINT = (
                                                                 SELECT TOP 1 ISNULL(TRY_CAST(C.Valor AS TINYINT), @QuantidadeMesesPadraoLogsExpurgo)
                                                                   FROM Sistema.Configuracoes AS C
                                                                  WHERE
                                                                     C.Configuracao = 'QtdMesDeletarRegistrosLogsExpurgo'
                                                             );
        DECLARE @DiaSubtraidoConfiguracaoExpurgarLogs DATE = DATEADD(MONTH, (-@QtdMesExpurgoLogsAuditoria), @PrimeiroDiaMes);
        DECLARE @DiaSubtraidoConfiguracaoDeletarExpurgo DATE = DATEADD(MONTH, (-(@QtdMesDeletarRegistrosLogsExpurgo)), @PrimeiroDiaMes);

        INSERT INTO #Configuracoes(
                                      Configuracao,
                                      Valor
                                  )
        VALUES(   'Data Limite para expurgar os logs', -- COnfiguracao - varchar(100)
                  @DiaSubtraidoConfiguracaoExpurgarLogs
              );

        INSERT INTO #Configuracoes(
                                      Configuracao,
                                      Valor
                                  )
        VALUES(   'Data Limite para excluir os logs da tabela expurgo', -- COnfiguracao - varchar(100)
                  @DiaSubtraidoConfiguracaoDeletarExpurgo
              );

        IF(OBJECT_ID('TEMPDB..#QuantidadeRegistrosParaExclusao') IS NOT NULL)
            DROP TABLE #QuantidadeRegistrosParaExclusao;

        CREATE TABLE #QuantidadeRegistrosParaExclusao
        (
            [Ano]   INT,
            [Mes]   INT,
            [Total] DECIMAL(18, 2)
        );

        IF(OBJECT_ID('TEMPDB..#QuantidadeRegistrosParaInserirExpurgo') IS NOT NULL)
            DROP TABLE #QuantidadeRegistrosParaInserirExpurgo;

        CREATE TABLE #QuantidadeRegistrosParaInserirExpurgo
        (
            [Ano]   INT,
            [Mes]   INT,
            [Total] DECIMAL(18, 2)
        );

        IF(@hoje >= @DataExecucaoExpurgo)
            BEGIN
                INSERT INTO #QuantidadeRegistrosParaInserirExpurgo(
                                                                      Ano,
                                                                      Mes,
                                                                      Total
                                                                  )
                SELECT YEAR(LJ.Data) Ano,
                       MONTH(LJ.Data) Mes,
                       COUNT(*) Total
                  FROM Log.LogsJson AS LJ
                 WHERE
                    CAST(LJ.Data AS DATE) < @DiaSubtraidoConfiguracaoExpurgarLogs
                 GROUP BY
                    YEAR(LJ.Data),
                    MONTH(LJ.Data);

                INSERT INTO #QuantidadeRegistrosParaExclusao(
                                                                Ano,
                                                                Mes,
                                                                Total
                                                            )
                SELECT YEAR(LJ.Data) Ano,
                       MONTH(LJ.Data) Mes,
                       COUNT(*) Total
                  FROM Expurgo.LogsJson AS LJ
                 WHERE
                    CAST(LJ.Data AS DATE) < @DiaSubtraidoConfiguracaoDeletarExpurgo
                 GROUP BY
                    YEAR(LJ.Data),
                    MONTH(LJ.Data);

                BEGIN TRY
                    IF(EXISTS (SELECT 1 FROM #QuantidadeRegistrosParaExclusao AS QRPE))
                        BEGIN

                            /* declare variables */
                            DECLARE @AnoExpurgo   INT,
                                    @MesExpurgo   INT,
                                    @TotalExpurgo NVARCHAR(4000);

                            DECLARE cursor_ExecutaDeleteExpurgo CURSOR FAST_FORWARD READ_ONLY FOR
                            SELECT IEL.Ano,
                                   IEL.Mes,
                                   IEL.Total
                              FROM #QuantidadeRegistrosParaExclusao AS IEL
                             ORDER BY
                                IEL.Ano,
                                IEL.Mes DESC;

                            OPEN cursor_ExecutaDeleteExpurgo;

                            FETCH NEXT FROM cursor_ExecutaDeleteExpurgo
                             INTO @AnoExpurgo,
                                  @MesExpurgo,
                                  @TotalExpurgo;

                            WHILE @@FETCH_STATUS = 0
                                BEGIN
                                    BEGIN TRAN Task_Expurgo;

                                    DELETE LJ
                                      FROM Expurgo.LogsJson AS LJ WITH(TABLOCK)
                                     WHERE
                                        YEAR(LJ.Data) = @AnoExpurgo
                                        AND MONTH(LJ.Data) = @MesExpurgo;

                                    COMMIT TRAN Task_Expurgo;

                                    FETCH NEXT FROM cursor_ExecutaDeleteExpurgo
                                     INTO @AnoExpurgo,
                                          @MesExpurgo,
                                          @TotalExpurgo;
                                END;

                            CLOSE cursor_ExecutaDeleteExpurgo;
                            DEALLOCATE cursor_ExecutaDeleteExpurgo;
                        END;

                    IF(EXISTS (SELECT 1 FROM #QuantidadeRegistrosParaInserirExpurgo AS QRPE))
                        BEGIN

                            /* declare variables */
                            DECLARE @AnoInsert   INT,
                                    @MesInsert   INT,
                                    @TotalInsert NVARCHAR(4000);

                            DECLARE cursor_ExecutaMigracaoLogsParaExpurgo CURSOR FAST_FORWARD READ_ONLY FOR
                            SELECT IEL.Ano,
                                   IEL.Mes,
                                   IEL.Total
                              FROM #QuantidadeRegistrosParaInserirExpurgo AS IEL
                             ORDER BY
                                IEL.Ano,
                                IEL.Mes DESC;

                            OPEN cursor_ExecutaMigracaoLogsParaExpurgo;

                            FETCH NEXT FROM cursor_ExecutaMigracaoLogsParaExpurgo
                             INTO @AnoInsert,
                                  @MesInsert,
                                  @TotalInsert;

                            WHILE @@FETCH_STATUS = 0
                                BEGIN
                                    BEGIN TRAN Task_InsertExpurgo;

                                    INSERT INTO Expurgo.LogsJson(
                                                                    IdPessoa,
                                                                    IdEntidade,
                                                                    Entidade,
                                                                    IdLogAntigo,
                                                                    Acao,
                                                                    Data,
                                                                    IdSistemaEspelhamento,
                                                                    IPAdress,
                                                                    Conteudo
                                                                )
                                    SELECT LJ.IdPessoa,
                                           LJ.IdEntidade,
                                           LJ.Entidade,
                                           LJ.IdLogAntigo,
                                           LJ.Acao,
                                           LJ.Data,
                                           LJ.IdSistemaEspelhamento,
                                           LJ.IPAdress,
                                           LJ.Conteudo
                                      FROM Log.LogsJson LJ WITH(TABLOCK)
                                     WHERE
                                        YEAR(LJ.Data) = @AnoInsert
                                        AND MONTH(LJ.Data) = @MesInsert;

                                    COMMIT TRAN Task_InsertExpurgo;

                                    BEGIN TRAN Task_DeleteLogs;

                                    DELETE LJ
                                      FROM Log.LogsJson LJ WITH(TABLOCK)
                                     WHERE
                                        YEAR(LJ.Data) = @AnoInsert
                                        AND MONTH(LJ.Data) = @MesInsert;

                                    COMMIT TRAN Task_DeleteLogs;

                                    FETCH NEXT FROM cursor_ExecutaMigracaoLogsParaExpurgo
                                     INTO @AnoExpurgo,
                                          @MesExpurgo,
                                          @TotalExpurgo;
                                END;

                            CLOSE cursor_ExecutaMigracaoLogsParaExpurgo;
                            DEALLOCATE cursor_ExecutaMigracaoLogsParaExpurgo;
                        END;

                    DECLARE @NovoDia DATE = DATEADD(MONTH, 1, GETDATE());

                    UPDATE Sistema.Configuracoes
                       SET Configuracoes.Valor = @NovoDia
                     WHERE
                        Configuracoes.Configuracao = 'DataExecucaoExpurgo';

                    INSERT INTO #Configuracoes(
                                                  Configuracao,
                                                  Valor
                                              )
                    VALUES(   'Proxima Data Configurada Para expurgar', -- Configuracao - varchar(100)
                              @NovoDia                                  -- Valor - varchar(100)
                          );
                END TRY
                BEGIN CATCH
                    IF(@@TRANCOUNT > 0)
                        ROLLBACK;

                    DECLARE @ErrorNumber INT = ERROR_NUMBER();
                    DECLARE @ErrorLine INT = ERROR_LINE();
                    DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
                    DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
                    DECLARE @ErrorState INT = ERROR_STATE();

                    PRINT 'Actual error number: ' + CAST(@ErrorNumber AS VARCHAR(MAX));
                    PRINT 'Actual line number: ' + CAST(@ErrorLine AS VARCHAR(MAX));
                    PRINT '@ErrorMessage: ' + CAST(@ErrorMessage AS VARCHAR(MAX));
                    PRINT '@ErrorSeverity: ' + CAST(@ErrorLine AS VARCHAR(MAX));
                    PRINT '@ErrorState: ' + CAST(@ErrorLine AS VARCHAR(MAX));

                    RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);

                    PRINT 'Error detected, all changes reversed.';
                END CATCH;
            END;
        ELSE
            BEGIN
                SELECT * FROM #Configuracoes AS C;

                SELECT 'DeleteExpurgo' AS Rotina,
                       *
                  FROM #QuantidadeRegistrosParaExclusao AS QRPE;

                SELECT 'InsertExpurgo' AS Rotina,
                       *
                  FROM #QuantidadeRegistrosParaInserirExpurgo AS QRPIE;
            END;
    END;
GO

SET QUOTED_IDENTIFIER ON;

SET ANSI_NULLS ON;
GO

--EXEC HealthCheck.ModifierPageCompression  @Limite =NULL,@FullTableName ='Financeiro.EmissoesRegistroOnline',@Compression ='PAGE'

CREATE OR ALTER PROCEDURE HealthCheck.ModifierPageCompression
(
    @Limite        DATETIME2    = NULL,
    @FullTableName VARCHAR(200) = NULL,
    @Compression   VARCHAR(20)  = 'PAGE'
)
AS
    BEGIN
        SET XACT_ABORT ON;

        DECLARE @VersionStandard BIT = IIF(CHARINDEX('Standard', @@VERSION) > 0, 1, 0);
        DECLARE @Data DATETIME2(2) = GETDATE();

        SELECT @Data = DATEADD(HOUR, -3, @Data);

        IF(@Limite IS NULL)
            BEGIN
                SET @Limite = DATETIME2FROMPARTS(YEAR(@Data), MONTH(@Data), DAY(DATEADD(DAY, 1, @Data)), 7, 0, 0, 0, 2);
            END;

        --DECLARE @HorarioPermitidoExecucaoInicial TIME = '11:00:00'
        --DECLARE @HorarioPermitidoExecucaoFinal TIME = '07:00:00'
        IF(OBJECT_ID('TEMPDB..#tabelas') IS NOT NULL)
            DROP TABLE #tabelas;

        CREATE TABLE #tabelas
        (
            [SchemaName]            NVARCHAR(128),
            [TableName]             NVARCHAR(128),
            [IndexName]             NVARCHAR(128),
            [IndexType]             TINYINT,
            [rows]                  BIGINT,
            [data_compression]      TINYINT,
            [data_compression_desc] NVARCHAR(60)
        );

        INSERT INTO #tabelas
        SELECT S.name AS SchemaName,
               T.name AS TableName,
               I.name AS IndexName,
               I.type AS IndexType,
               P.rows,
               P.data_compression,
               P.data_compression_desc
          --Script= 
          FROM sys.tables AS T
               JOIN sys.schemas AS S ON S.schema_id = T.schema_id
               JOIN sys.indexes AS I ON I.object_id = T.object_id
               JOIN sys.partitions AS P ON P.object_id = T.object_id
                                           AND P.index_id = I.index_id
         WHERE
            (
                @FullTableName IS NULL
                OR (T.object_id = OBJECT_ID(@FullTableName))
            );

        DECLARE @DataHoraAtual DATETIME2(2) = GETDATE();

        /* declare variables */
        DECLARE @SchemaName VARCHAR(256),
                @TableName  VARCHAR(256),
                @IndexName  VARCHAR(256),
                @IndexType  VARCHAR(256),
                @Script     NVARCHAR(1000);

        DECLARE cursor_CorrigeDataCompression_On_Table CURSOR FAST_FORWARD READ_ONLY FOR
        SELECT T.SchemaName,
               T.TableName,
               T.IndexName,
               T.IndexType,
               Script = CONCAT('ALTER TABLE ', '[', T.SchemaName, ']', '.', '[', T.TableName, ']', ' REBUILD PARTITION= ALL WITH(DATA_COMPRESSION = ', @Compression, '', IIF(@VersionStandard = 1, ')', ', ONLINE =ON)'))
          FROM #tabelas AS T
         WHERE
            T.IndexType = 1
            AND T.data_compression_desc = 'NONE';

        OPEN cursor_CorrigeDataCompression_On_Table;

        FETCH NEXT FROM cursor_CorrigeDataCompression_On_Table
         INTO @SchemaName,
              @TableName,
              @IndexName,
              @IndexType,
              @Script;

        WHILE @@FETCH_STATUS = 0
            BEGIN
                SET @DataHoraAtual = GETDATE();
                SET @DataHoraAtual = DATEADD(HOUR, -3, @DataHoraAtual);

                IF(@DataHoraAtual < @Limite)
                    BEGIN
                        BEGIN TRY
                            /*Region Logical Querys*/
                            EXEC sys.sp_executesql @Script;

                        /*End region */
                        END TRY
                        BEGIN CATCH
                            DECLARE @ErrorNumber INT = ERROR_NUMBER();
                            DECLARE @ErrorLine INT = ERROR_LINE();
                            DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
                            DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
                            DECLARE @ErrorState INT = ERROR_STATE();

                            PRINT 'Actual error number: ' + CAST(@ErrorNumber AS VARCHAR(MAX));
                            PRINT 'Actual line number: ' + CAST(@ErrorLine AS VARCHAR(MAX));
                            PRINT '@ErrorMessage: ' + CAST(@ErrorMessage AS VARCHAR(MAX));
                            PRINT '@ErrorSeverity: ' + CAST(@ErrorLine AS VARCHAR(MAX));
                            PRINT '@ErrorState: ' + CAST(@ErrorLine AS VARCHAR(MAX));

                            RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
                        END CATCH;
                    END;

                FETCH NEXT FROM cursor_CorrigeDataCompression_On_Table
                 INTO @SchemaName,
                      @TableName,
                      @IndexName,
                      @IndexType,
                      @Script;
            END;

        CLOSE cursor_CorrigeDataCompression_On_Table;
        DEALLOCATE cursor_CorrigeDataCompression_On_Table;

        DECLARE cursor_CorrigeDataCompression_On_Indexs CURSOR FAST_FORWARD READ_ONLY FOR
        SELECT T.SchemaName,
               T.TableName,
               T.IndexName,
               T.IndexType,
               Script = CONCAT('ALTER INDEX ', '[', T.IndexName, '] ON ', '[', T.SchemaName, ']', '.', '[', T.TableName, ']', ' REBUILD PARTITION= ALL WITH(DATA_COMPRESSION = ', @Compression, '', IIF(@VersionStandard = 1, ')', ', ONLINE =ON)'))
          FROM #tabelas AS T
         WHERE
            T.IndexType = 2
            AND T.data_compression_desc = 'NONE';

        OPEN cursor_CorrigeDataCompression_On_Indexs;

        FETCH NEXT FROM cursor_CorrigeDataCompression_On_Indexs
         INTO @SchemaName,
              @TableName,
              @IndexName,
              @IndexType,
              @Script;

        WHILE @@FETCH_STATUS = 0
            BEGIN
                SET @DataHoraAtual = GETDATE();
                SET @DataHoraAtual = DATEADD(HOUR, -3, @DataHoraAtual);

                IF(@DataHoraAtual < @Limite)
                    BEGIN
                        BEGIN TRY
                            /*Region Logical Querys*/
                            EXEC sys.sp_executesql @Script;

                        /*End region */
                        END TRY
                        BEGIN CATCH
                            DECLARE @ErrorNumber_ INT = ERROR_NUMBER();
                            DECLARE @ErrorLine_ INT = ERROR_LINE();
                            DECLARE @ErrorMessage_ NVARCHAR(4000) = ERROR_MESSAGE();
                            DECLARE @ErrorSeverity_ INT = ERROR_SEVERITY();
                            DECLARE @ErrorState_ INT = ERROR_STATE();

                            PRINT 'Actual error number: ' + CAST(@ErrorNumber_ AS VARCHAR(MAX));
                            PRINT 'Actual line number: ' + CAST(@ErrorLine_ AS VARCHAR(MAX));
                            PRINT '@ErrorMessage: ' + CAST(@ErrorMessage_ AS VARCHAR(MAX));
                            PRINT '@ErrorSeverity: ' + CAST(@ErrorLine_ AS VARCHAR(MAX));
                            PRINT '@ErrorState: ' + CAST(@ErrorLine_ AS VARCHAR(MAX));

                            RAISERROR(@ErrorMessage_, @ErrorSeverity_, @ErrorState_);
                        END CATCH;
                    END;

                FETCH NEXT FROM cursor_CorrigeDataCompression_On_Indexs
                 INTO @SchemaName,
                      @TableName,
                      @IndexName,
                      @IndexType,
                      @Script;
            END;

        CLOSE cursor_CorrigeDataCompression_On_Indexs;
        DEALLOCATE cursor_CorrigeDataCompression_On_Indexs;
    END;
GO

CREATE OR ALTER PROCEDURE HealthCheck.ExpurgarElmah
AS
    BEGIN
        DECLARE @DiaExecucao DATE = GETDATE();
        DECLARE @DataUltimaExecucaoExpurgoElmah DATE = (
                                                           SELECT TOP 1 ISNULL(APD.DataUltimaExecucao, APD.DataInicio)
                                                             FROM HealthCheck.AcoesPeriodicidadeDias AS APD
                                                            WHERE
                                                               APD.Nome = 'ExpurgarElmah'
                                                               AND APD.Ativo = 1
                                                       );
        DECLARE @PeriodicidadeExpurgoElmah SMALLINT = (
                                                          SELECT TOP 1 APD.Periodicidade
                                                            FROM HealthCheck.AcoesPeriodicidadeDias AS APD
                                                           WHERE
                                                              APD.Nome = 'ExpurgarElmah'
                                                              AND APD.Ativo = 1
                                                      );

        IF(DATEDIFF(DAY, @DataUltimaExecucaoExpurgoElmah, @DiaExecucao) >= @PeriodicidadeExpurgoElmah)
            BEGIN
                DELETE EE
                  FROM dbo.ELMAH_Error AS EE
                 WHERE
                    CAST(EE.TimeUtc AS DATE) < CAST(DATEADD(DAY, (@PeriodicidadeExpurgoElmah * -1), GETDATE()) AS DATE);
            END;
    END;
GO

CREATE OR ALTER PROCEDURE HealthCheck.uspExecutaShrink
(
    @dataFim DATETIME2(2) = NULL
)
AS
    BEGIN
        DECLARE @horaFinalExecucao TIME = '06:00:00';

        IF(OBJECT_ID('TEMPDB..#Dados') IS NOT NULL)
            DROP TABLE #Dados;

        CREATE TABLE #Dados
        (
            [Percentual Livre (> 25% )]     VARCHAR(42),
            [Percentual]                    DECIMAL(18, 2),
            [name]                          NVARCHAR(128),
            [file_id]                       INT,
            [type_desc]                     NVARCHAR(60),
            [FileName]                      NVARCHAR(128),
            [SizeInGB]                      DECIMAL(38, 6),
            [DatabaseSSpaceUsedInGB]        DECIMAL(18, 2),
            [SpaceNaoUsadoGB]               DECIMAL(18, 2),
            [Script]                        NVARCHAR(188),
            [TargetPercent]                 DECIMAL(21, 3),
            [user_access_desc]              NVARCHAR(60),
            [compatibility_level]           TINYINT,
            [collation_name]                NVARCHAR(128),
            [DatabaseSpaceUsedInMB]         DECIMAL(18, 2),
            [DatabaseSpaceUsedInBytes]      DECIMAL(38, 0),
            [snapshot_isolation_state_desc] NVARCHAR(60),
            [recovery_model_desc]           NVARCHAR(60),
            [page_verify_option_desc]       NVARCHAR(60),
            [state_desc]                    NVARCHAR(60),
            [is_read_committed_snapshot_on] BIT
        );

        WITH Dados
            AS
            (
                SELECT DB_NAME(DB_ID()) AS DataBaseName,
                       file_id,
                       name FileName,
                       type_desc,
                       ISNULL((SUM(S.size * 8192.) / 1024 / 1024 / 1024), 0) SizeInGB,
                       ISNULL(SUM(CAST(FILEPROPERTY(name, 'SpaceUsed') AS bigint) * 8192.), 0) AS DatabaseSpaceUsedInBytes,
                       ISNULL((SUM(CAST(FILEPROPERTY(NAME, 'SpaceUsed') AS bigint) * 8192.) / 1024 / 1024), 0) AS DatabaseSpaceUsedInMB,
                       ISNULL((SUM(CAST(FILEPROPERTY(NAME, 'SpaceUsed') AS bigint) * 8192.) / 1024 / 1024 / 1024), 0) AS DatabaseSSpaceUsedInGB
                  FROM sys.database_files S
                 GROUP BY
                    FILE_ID,
                    NAME,
                    type_desc
            ),
             Detalhes
            AS
            (
                SELECT DA.name,
                       D.file_id,
                       D.type_desc,
                       D.FileName,
                       D.SizeInGB,
                       CAST(D.DatabaseSSpaceUsedInGB AS DECIMAL(18, 2)) AS DatabaseSSpaceUsedInGB,
                       SpaceNaoUsadoGB = CAST((ROUND((D.SizeInGB - CAST(D.DatabaseSSpaceUsedInGB AS DECIMAL(18, 2))), 2)) AS DECIMAL(18, 2)),
                       Script = CONCAT('DBCC SHRINKFILE (', D.FileName, ',', CAST(D.DatabaseSSpaceUsedInGB AS DECIMAL(18, 2)) * 1.2, ')'),
                       TargetPercent = CAST(D.DatabaseSSpaceUsedInGB AS DECIMAL(18, 2)) * 1.2,
                       DA.user_access_desc,
                       DA.compatibility_level,
                       DA.collation_name,
                       CAST(D.DatabaseSpaceUsedInMB AS DECIMAL(18, 2)) AS DatabaseSpaceUsedInMB,
                       D.DatabaseSpaceUsedInBytes,
                       DA.snapshot_isolation_state_desc,
                       DA.recovery_model_desc,
                       DA.page_verify_option_desc,
                       DA.state_desc,
                       DA.is_read_committed_snapshot_on
                  FROM Dados D
                       JOIN sys.databases DA ON D.DataBaseName = DA.name
            )
        INSERT INTO #Dados
        SELECT [Percentual Livre (> 25% )] = CONCAT(CAST(((R.SpaceNaoUsadoGB / R.SizeInGB) * 100) AS DECIMAL(18, 2)), '%'),
               CAST(((R.SpaceNaoUsadoGB / R.SizeInGB) * 100) AS DECIMAL(18, 2)) AS Percentual,
               R.*
          FROM Detalhes R
         WHERE
            type_desc IN ('ROWS');

        DECLARE @HoraAtual DATETIME = GETDATE();

        SET @HoraAtual = DATEADD(HOUR, -3, @HoraAtual);

        IF(@dataFim IS NULL)
            BEGIN
                SET @dataFim = DATEADD(DAY, 1, @HoraAtual);
                SET @dataFim = CAST((CONVERT(VARCHAR(10), @dataFim, 121) + ' ' + CONVERT(VARCHAR(10), @horaFinalExecucao, 121)) AS DATETIME2(2));
            END;

        DECLARE @Executar BIT = IIF(@HoraAtual < @dataFim, 1, 0);

        IF(
              @Executar = 1
              AND (EXISTS (
                              SELECT * FROM #Dados AS D WHERE D.Percentual > 25
                          )
                  )
          )
            BEGIN
                DECLARE @DataBase VARCHAR(100) = DB_NAME();

                DBCC SHRINKDATABASE(@DataBase);
            END;
    END;
GO

SET QUOTED_IDENTIFIER ON;

SET ANSI_NULLS ON;
GO

--SELECT * FROM  HealthCheck.SizeDBHistory AS SDH
CREATE OR ALTER PROCEDURE HealthCheck.GetSizeDB
AS
    BEGIN
        WITH Dados
            AS
            (
                SELECT DB_NAME(DB_ID()) AS DataBaseName,
                       file_id,
                       name FileName,
                       type_desc,
                       CAST((ISNULL((SUM(S.size * 8192.) / 1024 / 1024 / 1024), 0)) AS DECIMAL(18, 2)) SizeInGB,
                       CAST((ISNULL(SUM(CAST(FILEPROPERTY(name, 'SpaceUsed') AS bigint) * 8192.), 0)) AS decimal(18, 2)) AS DatabaseSpaceUsedInBytes,
                       CAST((ISNULL((SUM(CAST(FILEPROPERTY(NAME, 'SpaceUsed') AS bigint) * 8192.) / 1024 / 1024), 0)) AS decimal(18, 2)) AS DatabaseSpaceUsedInMB,
                       CAST((ISNULL((SUM(CAST(FILEPROPERTY(NAME, 'SpaceUsed') AS bigint) * 8192.) / 1024 / 1024 / 1024), 0)) AS decimal(18, 2)) AS DatabaseSSpaceUsedInGB
                  FROM sys.database_files S
                 GROUP BY
                    FILE_ID,
                    NAME,
                    type_desc
            ),
             Detalhes
            AS
            (
                SELECT DataBaseName = DA.name,
                       D.type_desc,
                       D.SizeInGB,
                       CAST(D.DatabaseSSpaceUsedInGB AS DECIMAL(18, 2)) AS DatabaseSpaceUsedInGB,
                       DatabaseSpaceNonUsedInGB = CAST((ROUND((D.SizeInGB - CAST(D.DatabaseSSpaceUsedInGB AS DECIMAL(18, 2))), 2)) AS DECIMAL(18, 2))
                  FROM Dados D
                       JOIN sys.databases DA ON D.DataBaseName = DA.name
            )
        INSERT INTO HealthCheck.SizeDBHistory(
                                                 DataBaseName,
                                                 SizeInGB,
                                                 DatabaseSpaceUsedInGB,
                                                 DatabaseSpaceNonUsedInGB
                                             )
        SELECT R.DataBaseName,
               SizeInGB,
               DatabaseSpaceUsedInGB,
               DatabaseSpaceNonUsedInGB
          FROM Detalhes R
         WHERE
            type_desc IN ('ROWS')
            AND NOT EXISTS (
                               SELECT *
                                 FROM HealthCheck.SizeDBHistory AS SDH
                                WHERE
                                   SDH.Data = CAST(GETDATE() AS DATE)
                           );
    END;
GO

CREATE OR ALTER PROCEDURE HealthCheck.uspAutoHealthCheck
(
    @Efetivar                                BIT      = 1,
    @Visualizar                              BIT      = 0,
    @DiaExecucao                             DATETIME = NULL,
    @TableRowsInUpdateStats                  INT      = 1000,
    @NumberLinesToDetermineFullScan          INT      = 1000,
    @NumberOfDaysAnalyzedsForDuplicateIndexs TINYINT  = 7,
    @PercOfSafetyForDuplicateIndexs          TINYINT  = 10,
    @NumberOfDaysForInefficientIndex         TINYINT  = 60,
    @PercAccessForInefficientIndex           TINYINT  = 8,
    @PercMinFragmentation                    TINYINT  = 10,
    @QuantityPagesOfAnalyzedFragmentation    SMALLINT = 1000,
    @DefaultTunningPerform                   SMALLINT = 200
)
AS

--DECLARE @Efetivar                                BIT      = 1,
--        @Visualizar                              BIT      = 1,
--        @DiaExecucao                             DATETIME = GETDATE(),
--        @TableRowsInUpdateStats                  INT      = 1000,
--        @NumberLinesToDetermineFullScan          INT      = 10000,
--        @NumberOfDaysAnalyzedsForDuplicateIndexs TINYINT  = 7,
--        @PercOfSafetyForDuplicateIndexs          TINYINT  = 10,
--        @NumberOfDaysForInefficientIndex         TINYINT  = 7,
--        @PercAccessForInefficientIndex           TINYINT  = 9,
--        @PercMinFragmentation                    TINYINT  = 10,
--        @QuantityPagesOfAnalyzedFragmentation    SMALLINT = 1000,
--        @DefaultTunningPerform                   SMALLINT = 500;
SET @DiaExecucao = ISNULL(@DiaExecucao, GETDATE());

DECLARE @TableLogs TABLE
(
    NomeProcedure VARCHAR(200),
    DataInicio    DATETIME,
    DataTermino   DATETIME,
    Mensagem      AS CONCAT(NomeProcedure, SPACE(2), 'Tempo Decorrido:', DATEDIFF(MILLISECOND, DataInicio, DataTermino), ' MS')
);

DECLARE @ConfiguracaoHabilitarAutoHealthCheck BIT = (
                                                        SELECT CAST(C.Valor AS BIT)
                                                          FROM Sistema.Configuracoes AS C
                                                         WHERE
                                                            C.Configuracao = 'HabilitarAutoHealthCheck'
                                                    );

IF(@ConfiguracaoHabilitarAutoHealthCheck IS NULL)
    BEGIN
        INSERT INTO Sistema.Configuracoes(
                                             CodConfiguracao,
                                             CodSistema,
                                             Modulo,
                                             Configuracao,
                                             Valor,
                                             Ano
                                         )
        VALUES(   NEWID(),                                -- CodConfiguracao - uniqueidentifier
                  '00000000-0000-0000-0000-000000000000', -- CodSistema - uniqueidentifier
                  'Global',                               -- Modulo - varchar(100)
                  'HabilitarAutoHealthCheck',             -- Configuracao - varchar(100)
                  'True',                                 -- Valor - varchar(max)
                  0                                       -- Ano - int
              );

        SET @ConfiguracaoHabilitarAutoHealthCheck = CAST(1 AS BIT);
    END;

DECLARE @DayOfWeek TINYINT = (
                                 SELECT DATEPART(WEEKDAY, GETDATE())
                             );
DECLARE @DataUltimaExecucao DATE = (
                                       SELECT TOP 1 ISNULL(A.DataUltimaExecucao, A.DataInicio)
                                         FROM HealthCheck.AcoesPeriodicidadeDias AS A
                                        WHERE
                                           A.Nome = 'AtualizarStatisticas'
                                   );

SET @DataUltimaExecucao = ISNULL(@DataUltimaExecucao, CAST(GETDATE() AS DATE));

IF(@ConfiguracaoHabilitarAutoHealthCheck = 1)
    BEGIN
        DECLARE @StartTime DATETIME;
        DECLARE @AtualizarStatisticas BIT = CAST((
                                                     SELECT TOP 1 1
                                                       FROM HealthCheck.AcoesPeriodicidadeDias AS A
                                                      WHERE
                                                         A.Nome = 'AtualizarStatisticas'
                                                         AND A.Ativo = 1
                                                 ) AS BIT);
        DECLARE @CriarIndicesAutomaticamente BIT = CAST((
                                                            SELECT TOP 1 1
                                                              FROM HealthCheck.AcoesPeriodicidadeDias AS A
                                                             WHERE
                                                                A.Nome = 'CriarIndicesAutomaticamente'
                                                                AND A.Ativo = 1
                                                        ) AS BIT);
        DECLARE @CriarStatisticasColunas BIT = CAST((
                                                        SELECT TOP 1 1
                                                          FROM HealthCheck.AcoesPeriodicidadeDias AS A
                                                         WHERE
                                                            A.Nome = 'CriarStatisticasColunas'
                                                            AND A.Ativo = 1
                                                    ) AS BIT);
        DECLARE @DeletarIndicesDuplicados BIT = CAST((
                                                         SELECT TOP 1 1
                                                           FROM HealthCheck.AcoesPeriodicidadeDias AS A
                                                          WHERE
                                                             A.Nome = 'DeletarIndicesDuplicados'
                                                             AND A.Ativo = 1
                                                     ) AS BIT);
        DECLARE @AnalisarIndicesIneficientes BIT = CAST((
                                                            SELECT TOP 1 1
                                                              FROM HealthCheck.AcoesPeriodicidadeDias AS A
                                                             WHERE
                                                                A.Nome = 'AnalisarIndicesIneficientes'
                                                                AND A.Ativo = 1
                                                        ) AS BIT);
        DECLARE @DesfragmentacaoIndices BIT = CAST((
                                                       SELECT TOP 1 1
                                                         FROM HealthCheck.AcoesPeriodicidadeDias AS A
                                                        WHERE
                                                           A.Nome = 'DesfragmentacaoIndices'
                                                           AND A.Ativo = 1
                                                   ) AS BIT);
        DECLARE @DeletarIndicesNaoUsados BIT = CAST((
                                                        SELECT TOP 1 1
                                                          FROM HealthCheck.AcoesPeriodicidadeDias AS A
                                                         WHERE
                                                            A.Nome = 'DeletarIndicesNaoUsados'
                                                            AND A.Ativo = 1
                                                    ) AS BIT);
        DECLARE @EfetuarShrinkDatabase BIT = CAST((
                                                      SELECT TOP 1 1
                                                        FROM HealthCheck.AcoesPeriodicidadeDias AS A
                                                       WHERE
                                                          A.Nome = 'ShrinkDatabase'
                                                          AND A.Ativo = 1
                                                  ) AS BIT);
        DECLARE @ExpurgarElmah BIT = CAST((
                                              SELECT TOP 1 1
                                                FROM HealthCheck.AcoesPeriodicidadeDias AS A
                                               WHERE
                                                  A.Nome = 'ExpurgarElmah'
                                                  AND A.Ativo = 1
                                          ) AS BIT);
        DECLARE @ExpurgarLogs BIT = CAST((
                                             SELECT TOP 1 1
                                               FROM HealthCheck.AcoesPeriodicidadeDias AS A
                                              WHERE
                                                 A.Nome = 'ExpurgarLogs'
                                                 AND A.Ativo = 1
                                         ) AS BIT);
        DECLARE @PeriodicidadeEfetuarShrinkDatabase SMALLINT = (
                                                                   SELECT TOP 1 A.Periodicidade
                                                                     FROM HealthCheck.AcoesPeriodicidadeDias AS A
                                                                    WHERE
                                                                       A.Nome = 'ShrinkDatabase'
                                                                       AND A.Ativo = 1
                                                               );
        DECLARE @PeriodicidadeExpurgarElmah SMALLINT = (
                                                           SELECT TOP 1 A.Periodicidade
                                                             FROM HealthCheck.AcoesPeriodicidadeDias AS A
                                                            WHERE
                                                               A.Nome = 'ExpurgarElmah'
                                                               AND A.Ativo = 1
                                                       );
        DECLARE @PeriodicidadeDeletarIndicesDuplicados SMALLINT = (
                                                                      SELECT TOP 1 A.Periodicidade
                                                                        FROM HealthCheck.AcoesPeriodicidadeDias AS A
                                                                       WHERE
                                                                          A.Nome = 'DeletarIndicesDuplicados'
                                                                          AND A.Ativo = 1
                                                                  );
        DECLARE @PeriodicidadeDesfragmentacaoIndices SMALLINT = (
                                                                    SELECT TOP 1 A.Periodicidade
                                                                      FROM HealthCheck.AcoesPeriodicidadeDias AS A
                                                                     WHERE
                                                                        A.Nome = 'DesfragmentacaoIndices'
                                                                        AND A.Ativo = 1
                                                                );
        DECLARE @PeriodicidadeAnalisarIndicesIneficientes SMALLINT = (
                                                                         SELECT TOP 1 A.Periodicidade
                                                                           FROM HealthCheck.AcoesPeriodicidadeDias AS A
                                                                          WHERE
                                                                             A.Nome = 'AnalisarIndicesIneficientes'
                                                                             AND A.Ativo = 1
                                                                     );
        DECLARE @PeriodicidadeDeletarIndicesNaoUsados SMALLINT = (
                                                                     SELECT TOP 1 A.Periodicidade
                                                                       FROM HealthCheck.AcoesPeriodicidadeDias AS A
                                                                      WHERE
                                                                         A.Nome = 'DeletarIndicesNaoUsados'
                                                                         AND A.Ativo = 1
                                                                 );

        /* ==================================================================
	--Data: 9/2/2020 
	--Autor :Wesley Neves
	--Observação: guarda o tamanho do banco de dados
	 
	-- ==================================================================
	*/
        SET @StartTime = GETDATE();

        EXEC HealthCheck.GetSizeDB;

        INSERT INTO @TableLogs
        VALUES(   'HealthCheck.GetSizeDB', -- NomeProcedure - varchar(200)
                  @StartTime,              -- DataInicio - datetime
                  GETDATE()                -- DataTermino - datetime
              );

        /* ==================================================================
			  --Data: 9/4/2020 
			  --Autor :Wesley Neves
			  --Observação: Efetua ShrinkDatabase o somente a cadas 15 dias no domingo
			   
			  -- ==================================================================
			  */
        IF(@DayOfWeek = 1)
            BEGIN
                IF(
                      @EfetuarShrinkDatabase = 1
                      AND DATEDIFF(DAY, @DataUltimaExecucao, @DiaExecucao) >= @PeriodicidadeEfetuarShrinkDatabase
                  )
                    BEGIN
                        SET @StartTime = GETDATE();

                        EXEC HealthCheck.uspExecutaShrink;

                        INSERT INTO @TableLogs
                        VALUES(   'HealthCheck.uspExecutaShrink', -- NomeProcedure - varchar(200)
                                  @StartTime,                     -- DataInicio - datetime
                                  GETDATE()                       -- DataTermino - datetime
                              );

                        UPDATE HealthCheck.AcoesPeriodicidadeDias
                           SET DataUltimaExecucao = GETDATE()
                         WHERE
                            Nome = 'ShrinkDatabase';
                    END;
            END;

        /*Executa Snap shot dos indices  (Diario) exceto nos Fins de Semana e feriados*/
        IF(
              @DayOfWeek NOT IN (7, 1)
              AND (NOT EXISTS (
                                  SELECT *
                                    FROM Corporativo.Feriados AS F
                                   WHERE
                                      F.Mes = MONTH(@DiaExecucao)
                                      AND F.Dia = DAY(@DiaExecucao)
                              )
                  )
          )
            BEGIN
                SET @StartTime = GETDATE();

                EXEC HealthCheck.uspSnapShotIndex @Visualizar = @Visualizar,   -- bit
                                                  @DiaExecucao = @DiaExecucao, -- datetime
                                                  @Efetivar = @Efetivar;

                INSERT INTO @TableLogs
                VALUES(   'HealthCheck.uspSnapShotIndex', -- NomeProcedure - varchar(200)
                          @StartTime,                     -- DataInicio - datetime
                          GETDATE()                       -- DataTermino - datetime
                      );
            END;

        /* ==================================================================
	 --Data: 9/3/2020 
	 --Autor :Wesley Neves
	 --Rotinas diarias
	
	 -- Deleta Statisticas duplicadas dos objetos
	 -- Atualizar Statisticas quando necessário
	 --Criar Indices automáticos
	 --Criar statisticas de colunas

	  
	 -- ==================================================================
	 */
        IF(@AtualizarStatisticas = 1)
            BEGIN
                SET @StartTime = GETDATE();

                EXEC HealthCheck.uspDeleteOverlappingStats @MostarStatisticas = @Visualizar, -- bit
                                                           @Executar = @Efetivar;            -- bit

                INSERT INTO @TableLogs
                VALUES(   'HealthCheck.uspDeleteOverlappingStats', -- NomeProcedure - varchar(200)
                          @StartTime,                              -- DataInicio - datetime
                          GETDATE()                                -- DataTermino - datetime
                      );

                SET @StartTime = GETDATE();

                /*Atualiza Statisticas Necessárias (diario)*/
                EXEC HealthCheck.uspUpdateStats @MostarStatisticas = @Visualizar, -- bit
                                                @ExecutarAtualizacao = @Efetivar, -- bit
                                                @TableRowsInUpdateStats = 1000,
                                                @NumberLinesToDetermineFullScan = @NumberLinesToDetermineFullScan;

                INSERT INTO @TableLogs
                VALUES(   'HealthCheck.uspUpdateStats', -- NomeProcedure - varchar(200)
                          @StartTime,                   -- DataInicio - datetime
                          GETDATE()                     -- DataTermino - datetime
                      );

                UPDATE HealthCheck.AcoesPeriodicidadeDias
                   SET DataUltimaExecucao = GETDATE()
                 WHERE
                    Nome = 'AtualizarStatisticas';
            END;

        IF(@CriarIndicesAutomaticamente = 1)
            BEGIN
                SET @StartTime = GETDATE();

                /*Cria Automaticamente Missing Index (diario)*/
                EXEC HealthCheck.uspAutoCreateIndex @Efetivar = @Efetivar,            -- bit
                                                    @VisualizarMissing = @Visualizar, -- bit
                                                    @defaultTunningPerform = @DefaultTunningPerform;

                INSERT INTO @TableLogs
                VALUES(   'HealthCheck.uspAutoCreateIndex', -- NomeProcedure - varchar(200)
                          @StartTime,                       -- DataInicio - datetime
                          GETDATE()                         -- DataTermino - datetime
                      );

                UPDATE HealthCheck.AcoesPeriodicidadeDias
                   SET DataUltimaExecucao = GETDATE()
                 WHERE
                    Nome = 'CriarIndicesAutomaticamente';
            END;

        IF(@CriarStatisticasColunas = 1)
            BEGIN
                SET @StartTime = GETDATE();

                /*Cria os Statisticas Colunares de tabelas que foram acessados pelos indices*/
                EXEC HealthCheck.uspAutoCreateStats @MostrarStatistica = @Visualizar, -- bit
                                                    @Efetivar = @Efetivar,            -- bit
                                                    @NumberLinesToDetermineFullScan = 10000;

                INSERT INTO @TableLogs
                VALUES(   'HealthCheck.uspAutoCreateStats', -- NomeProcedure - varchar(200)
                          @StartTime,                       -- DataInicio - datetime
                          GETDATE()                         -- DataTermino - datetime
                      );

                UPDATE HealthCheck.AcoesPeriodicidadeDias
                   SET DataUltimaExecucao = GETDATE()
                 WHERE
                    Nome = 'CriarStatisticasColunas';
            END;

        /* ==================================================================
		--Data: 9/3/2020 
		--Autor :Wesley Neves
		--Observação: Rotina pra domingo
		 
		-- ==================================================================
		*/
        IF(@DayOfWeek = 1)
            BEGIN
                IF(
                      @DeletarIndicesDuplicados = 1
                      AND DATEDIFF(DAY, @DataUltimaExecucao, @DiaExecucao) >= @PeriodicidadeDeletarIndicesDuplicados
                  )
                    BEGIN
                        SET @StartTime = GETDATE();

                        EXEC HealthCheck.uspDeleteDuplicateIndex @Efetivar = @Efetivar,                            -- bit
                                                                 @MostrarIndicesDuplicados = @Visualizar,
                                                                 @MostrarIndicesMarcadosParaDeletar = @Visualizar, -- bit
                                                                 @QuantidadeDiasAnalizados = @NumberOfDaysAnalyzedsForDuplicateIndexs,
                                                                 @TaxaDeSeguranca = 10;                            -- Não deletar indices com acesso superior a 10 % mesmo duplicado(é necessário uma analise individual)

                        INSERT INTO @TableLogs
                        VALUES(   'HealthCheck.uspDeleteDuplicateIndex', -- NomeProcedure - varchar(200)
                                  @StartTime,                            -- DataInicio - datetime
                                  GETDATE()                              -- DataTermino - datetime
                              );

                        UPDATE HealthCheck.AcoesPeriodicidadeDias
                           SET DataUltimaExecucao = GETDATE()
                         WHERE
                            Nome = 'DeletarIndicesDuplicados';
                    END;

                --Somente Domingos
                IF(
                      @AnalisarIndicesIneficientes = 1
                      AND DATEDIFF(DAY, @DataUltimaExecucao, @DiaExecucao) >= @PeriodicidadeAnalisarIndicesIneficientes
                  )
                    BEGIN
                        SET @StartTime = GETDATE();

                        /*Executa de analize  eficiencia de indices*/
                        EXEC HealthCheck.uspInefficientIndex @percentualAproveitamento = @PercAccessForInefficientIndex,          --  (Acesso <= 9 %) smallint
                                                             @EfetivarDelecao = @Efetivar,                                        -- bit
                                                             @NumberOfDaysForInefficientIndex = @NumberOfDaysForInefficientIndex, -- smallint  (7 dias)
                                                             @MostrarIndiceIneficiente = @Visualizar;                             -- bit

                        INSERT INTO @TableLogs
                        VALUES(   'HealthCheck.uspInefficientIndex', -- NomeProcedure - varchar(200)
                                  @StartTime,                        -- DataInicio - datetime
                                  GETDATE()                          -- DataTermino - datetime
                              );

                        UPDATE HealthCheck.AcoesPeriodicidadeDias
                           SET DataUltimaExecucao = GETDATE()
                         WHERE
                            Nome = 'AnalisarIndicesIneficientes';
                    END;

                IF(
                      @DesfragmentacaoIndices = 1
                      AND DATEDIFF(DAY, @DataUltimaExecucao, @DiaExecucao) >= @PeriodicidadeDesfragmentacaoIndices
                  )
                    BEGIN
                        SET @StartTime = GETDATE();

                        /* Desfragmento dos indices */
                        EXEC HealthCheck.uspIndexDesfrag @MostrarIndices = @Visualizar,                         -- bit
                                                         @MinFrag = @PercMinFragmentation,                      -- smallint
                                                         @MinPageCount = @QuantityPagesOfAnalyzedFragmentation, -- smallint
                                                         @Efetivar = @Efetivar;                                 -- bit

                        INSERT INTO @TableLogs
                        VALUES(   'HealthCheck.uspIndexDesfrag', -- NomeProcedure - varchar(200)
                                  @StartTime,                    -- DataInicio - datetime
                                  GETDATE()                      -- DataTermino - datetime
                              );

                        UPDATE HealthCheck.AcoesPeriodicidadeDias
                           SET DataUltimaExecucao = GETDATE()
                         WHERE
                            Nome = 'DesfragmentacaoIndices';
                    END;
            END;

        /* ==================================================================
    --Observação:  A cada 30 dias 
	1)  Analise de indices não usados
	
    -- ==================================================================
    */
        IF(
              @DeletarIndicesNaoUsados = 1
              AND DATEDIFF(DAY, @DataUltimaExecucao, @DiaExecucao) >= @PeriodicidadeDeletarIndicesNaoUsados
          )
            BEGIN
                SET @StartTime = GETDATE();

                /*Deletar os indices que não estão sendo usados pelo otimizador por mais de X dias*/
                EXEC HealthCheck.uspUnusedIndex @EfetivarDelecao = @Efetivar,                                       -- bit
                                                @QuantidadeDiasConfigurado = @PeriodicidadeDeletarIndicesNaoUsados, -- smallint (30 dias)
                                                @MostrarIndice = @Visualizar;                                       -- bit

                INSERT INTO @TableLogs
                VALUES(   'HealthCheck.uspUnusedIndex', -- NomeProcedure - varchar(200)
                          @StartTime,                   -- DataInicio - datetime
                          GETDATE()                     -- DataTermino - datetime
                      );

                UPDATE HealthCheck.AcoesPeriodicidadeDias
                   SET DataUltimaExecucao = GETDATE()
                 WHERE
                    Nome = 'DeletarIndicesNaoUsados';
            END;

        EXEC HealthCheck.uspSnapShotClear @diasExpurgo = @PeriodicidadeDeletarIndicesNaoUsados; -- smallint

        IF(@ExpurgarElmah = 1)
            BEGIN
                DECLARE @DataUltimaExecucaoExpurgoElmah DATE = (
                                                                   SELECT TOP 1 ISNULL(APD.DataUltimaExecucao, APD.DataInicio)
                                                                     FROM HealthCheck.AcoesPeriodicidadeDias AS APD
                                                                    WHERE
                                                                       APD.Nome = 'ExpurgarElmah'
                                                                       AND APD.Ativo = 1
                                                               );

                IF(DATEDIFF(DAY, @DataUltimaExecucaoExpurgoElmah, @DiaExecucao) >= @PeriodicidadeExpurgarElmah)
                    BEGIN
                        SET @StartTime = GETDATE();

                        EXEC HealthCheck.ExpurgarElmah;

                        INSERT INTO @TableLogs
                        VALUES(   'HealthCheck.ExpurgarElmah', -- NomeProcedure - varchar(200)
                                  @StartTime,                  -- DataInicio - datetime
                                  GETDATE()                    -- DataTermino - datetime
                              );

                        UPDATE HealthCheck.AcoesPeriodicidadeDias
                           SET DataUltimaExecucao = GETDATE()
                         WHERE
                            Nome = 'ExpurgarElmah';
                    END;
            END;

        IF(@ExpurgarLogs = 1)
            BEGIN
                SET @StartTime = GETDATE();

                EXEC Log.uspExpurgoLogsJson;

                INSERT INTO @TableLogs
                VALUES(   'Log.uspExpurgoLogsJson', -- NomeProcedure - varchar(200)
                          @StartTime,               -- DataInicio - datetime
                          GETDATE()                 -- DataTermino - datetime
                      );

                UPDATE HealthCheck.AcoesPeriodicidadeDias
                   SET DataUltimaExecucao = GETDATE()
                 WHERE
                    Nome = 'ExpurgarLogs';
            END;
    END;



	SET QUOTED_IDENTIFIER ON
SET ANSI_NULLS ON
GO
