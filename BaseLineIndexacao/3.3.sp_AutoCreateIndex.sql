SET QUOTED_IDENTIFIER ON;

SET ANSI_NULLS ON;
GO

--EXEC HealthCheck.uspAutoCreateIndex @Efetivar = 0,             -- bit
--                                    @VisualizarMissing = 1,    -- bit
--                                    @VisualizarCreate = 1,     -- bit
--                                    @VisualizarAlteracoes = 1, -- bit
--                                    @defaultTunningPerform = 100    -- smallint

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
