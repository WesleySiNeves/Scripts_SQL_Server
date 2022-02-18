CREATE OR ALTER PROCEDURE HealthCheck.uspMissingIndex
(
    @defaultTunningPerform SMALLINT = 200
)
AS
    BEGIN
        BEGIN TRY

            --DECLARE @defaultTunningPerform SMALLINT = 200;
            SET TRAN ISOLATION LEVEL READ UNCOMMITTED;

            IF(OBJECT_ID('TEMPDB..#Retorno') IS NOT NULL)
                DROP TABLE #Retorno;

            CREATE TABLE #Retorno
            (
                [ObjectId]                  INT,
                [TotalObjetcId]             INT,
                [SchemaName]                VARCHAR(140),
                [TableName]                 VARCHAR(140),
                [IndexName]                 VARCHAR(200),
                [Chave]                     VARCHAR(200),
                [PrimeiraChave]             VARCHAR(200),
                [ExisteIndiceNaChave]       INT,
                [ChavePertenceAOutroIndice] INT,
                [ColunaIncluida]            VARCHAR(1000),
                [AvgEstimatedImpact]        REAL,
                [MagicBenefitNumber]        REAL,
                [PotentialReadOp]           INT,
                [reads]                     INT,
                [PercCustoMedio]            DECIMAL(10, 2),
                [CreateIndex]               VARCHAR(8000)
            );

            IF(OBJECT_ID('TEMPDB..#indexusage') IS NOT NULL)
                DROP TABLE #indexusage;

            IF(OBJECT_ID('TEMPDB..#Missings') IS NOT NULL)
                DROP TABLE #Missings;

            IF(OBJECT_ID('TEMPDB..#Candidates') IS NOT NULL)
                DROP TABLE #Candidates;

            IF(OBJECT_ID('TEMPDB..#FirtResultIntermediate') IS NOT NULL)
                DROP TABLE #FirtResultIntermediate;

            IF(OBJECT_ID('TEMPDB..#SecondResultIntermediate') IS NOT NULL)
                DROP TABLE #SecondResultIntermediate;

            IF(OBJECT_ID('TEMPDB..#Final') IS NOT NULL)
                DROP TABLE #Final;

            CREATE TABLE #Final
            (
                [object_id]            INT,
                [s]                    VARCHAR(140),
                [o]                    VARCHAR(140),
                [user_seeks]           INT,
                [user_scans]           INT,
                [unique_compiles]      INT,
                IndexName              VARCHAR(200),
                [Chave]                VARCHAR(200),
                [PrimeiraChave]        VARCHAR(200),
                [ColunaIncluida]       VARCHAR(1000),
                [Avg_Estimated_Impact] REAL,
                [magic_benefit_number] REAL,
                [potential_read_op]    INT,
                [reads]                INT,
                [write:read ratio]     DECIMAL(10, 2),
            );

            CREATE TABLE #FirtResultIntermediate
            (
                [object_id]            INT,
                [s]                    VARCHAR(140)  COLLATE DATABASE_DEFAULT,
                [o]                    VARCHAR(140)  COLLATE DATABASE_DEFAULT,
                [user_seeks]           INT,
                [user_scans]           INT,
                [unique_compiles]      INT,
                IndexName              VARCHAR(200),
                [Chave]                VARCHAR(200),
                [PrimeiraChave]        VARCHAR(200)  COLLATE DATABASE_DEFAULT,
                [ColunaIncluida]       VARCHAR(1000) COLLATE DATABASE_DEFAULT,
                [Avg_Estimated_Impact] REAL,
                [magic_benefit_number] REAL,
                [potential_read_op]    INT,
                [reads]                INT,
                [write:read ratio]     DECIMAL(10, 2),
            );

            CREATE TABLE #SecondResultIntermediate
            (
                [object_id]                 INT,
                [user_seeks]                INT,
                [user_scans]                INT,
                [unique_compiles]           INT,
                IndexName                   VARCHAR(200)  COLLATE DATABASE_DEFAULT,
                [Chave]                     VARCHAR(200)  COLLATE DATABASE_DEFAULT,
                [PrimeiraChave]             VARCHAR(200)  COLLATE DATABASE_DEFAULT,
                [ColunaIncluida]            VARCHAR(1000) COLLATE DATABASE_DEFAULT,
                [Avg_Estimated_Impact]      REAL,
                [magic_benefit_number]      REAL,
                [CountObjectId]             INT,
                [CountObjectIdAndChave]     INT,
                [TotalMagic_benefit_number] FLOAT(8),
                [MaxMagic_benefit_number]   REAL,
                [TotalAvg_Estimated_Impact] FLOAT(8),
                [MaxAvg_Estimated_Impact]   REAL
            );

            CREATE TABLE #indexusage
            (
                [object_id]    INT,
                [index_id]     TINYINT,
                [user_seeks]   INT,
                [user_scans]   INT,
                [user_lookups] INT,
                [user_updates] INT PRIMARY KEY(object_id, index_id)
            );

            CREATE TABLE #Missings
            (
                [object_id]            INT,
                [s]                    VARCHAR(140)  COLLATE DATABASE_DEFAULT,
                [o]                    VARCHAR(140)  COLLATE DATABASE_DEFAULT,
                [equality_columns]     VARCHAR(300)  COLLATE DATABASE_DEFAULT,
                [inequality_columns]   VARCHAR(300)  COLLATE DATABASE_DEFAULT,
                [included_columns]     VARCHAR(1000) COLLATE DATABASE_DEFAULT,
                [unique_compiles]      INT,
                [user_seeks]           INT,
                [last_user_seek]       DATETIME2(3),
                [user_scans]           INT,
                [last_user_scan]       DATETIME2(3),
                [NomeIndex]            VARCHAR(128)  COLLATE DATABASE_DEFAULT,
                [Avg_Estimated_Impact] FLOAT(8),
                [magic_benefit_number] FLOAT(8)
            );

            CREATE TABLE #Candidates
            (
                [object_id]            INT,
                [s]                    VARCHAR(140),
                [o]                    VARCHAR(140),
                [equality_columns]     VARCHAR(300)  COLLATE DATABASE_DEFAULT,
                [inequality_columns]   VARCHAR(300)  COLLATE DATABASE_DEFAULT,
                [included_columns]     VARCHAR(1000) COLLATE DATABASE_DEFAULT,
                [unique_compiles]      INT,
                [user_seeks]           INT,
                [last_user_seek]       DATETIME2(3),
                [user_scans]           INT,
                [last_user_scan]       DATETIME2(3),
                [NomeIndex]            VARCHAR(128),
                [Chave]                VARCHAR(200),
                PrimeiraChave          AS (IIF(CHARINDEX(',', [Chave], 0) > 0, SUBSTRING([Chave], 0, CHARINDEX(',', [Chave], 0)), [Chave])),
                [ColunaIncluida]       VARCHAR(1000) COLLATE DATABASE_DEFAULT,
                [Avg_Estimated_Impact] REAL,
                [magic_benefit_number] REAL,
            );

            INSERT INTO #indexusage
            SELECT s.object_id,
                   s.index_id,
                   s.user_seeks,
                   s.user_scans,
                   s.user_lookups,
                   s.user_updates
              FROM sys.dm_db_index_usage_stats AS s
             WHERE
                s.database_id = DB_ID();

            WITH Dados
                AS
                (
                    SELECT dm_mid.object_id,
                           s = CAST(OBJECT_SCHEMA_NAME(dm_mid.object_id) AS VARCHAR(128))COLLATE DATABASE_DEFAULT,
                           o = CAST(OBJECT_NAME(dm_mid.object_id) AS VARCHAR(128))COLLATE DATABASE_DEFAULT,
                           CAST(dm_mid.equality_columns AS VARCHAR(300)) equality_columns,
                           CAST(dm_mid.inequality_columns AS VARCHAR(300)) inequality_columns,
                           CAST(dm_mid.included_columns AS VARCHAR(1000)) included_columns,
                           dm_migs.unique_compiles,
                           dm_migs.user_seeks,
                           dm_migs.last_user_seek,
                           dm_migs.user_scans,
                           dm_migs.last_user_scan,
                           NomeIndex = CAST('IX_' + CAST(OBJECT_SCHEMA_NAME(dm_mid.object_id, dm_mid.database_id) AS VARCHAR(400)) + OBJECT_NAME(dm_mid.object_id, dm_mid.database_id) + '_' + REPLACE(REPLACE(REPLACE(ISNULL(dm_mid.equality_columns, ''), ', ', '_'), '[', ''), ']', '') + CASE WHEN dm_mid.equality_columns IS NOT NULL
                                                                                                                                                                                                                                                                                                       AND dm_mid.inequality_columns IS NOT NULL THEN CAST('_' AS VARCHAR(1))ELSE CAST('' AS VARCHAR(1))END + REPLACE(REPLACE(REPLACE(ISNULL(dm_mid.inequality_columns, CAST('' AS VARCHAR(1))), ', ', '_'), '[', CAST('' AS VARCHAR(1))), ']', CAST('' AS VARCHAR(1))) AS VARCHAR(128))COLLATE DATABASE_DEFAULT,
                           dm_migs.avg_user_impact * (dm_migs.user_seeks + dm_migs.user_scans) Avg_Estimated_Impact,
                           magic_benefit_number = dm_migs.avg_total_user_cost * dm_migs.avg_user_impact * (dm_migs.user_seeks + dm_migs.user_scans)
                      FROM sys.dm_db_missing_index_details AS dm_mid
                           INNER JOIN sys.dm_db_missing_index_groups AS dm_mig ON dm_mid.index_handle = dm_mig.index_handle
                           INNER JOIN sys.dm_db_missing_index_group_stats AS dm_migs ON dm_mig.index_group_handle = dm_migs.group_handle
                     WHERE
                        dm_mid.database_id = DB_ID()
                )
            INSERT INTO #Missings
            SELECT R.object_id,
                   R.s,
                   R.o,
                   R.equality_columns,
                   R.inequality_columns,
                   R.included_columns,
                   R.unique_compiles,
                   R.user_seeks,
                   R.last_user_seek,
                   R.user_scans,
                   R.last_user_scan,
                   R.NomeIndex,
                   R.Avg_Estimated_Impact,
                   R.magic_benefit_number
              FROM Dados R;

            IF(EXISTS (SELECT 1 FROM #Missings AS M))
                BEGIN
                    WITH Resumo
                        AS
                        (
                            SELECT R.object_id,
                                   R.s,
                                   R.o,
                                   R.equality_columns,
                                   R.inequality_columns,
                                   R.included_columns,
                                   R.unique_compiles,
                                   R.user_seeks,
                                   R.last_user_seek,
                                   R.user_scans,
                                   R.last_user_scan,
                                   R.NomeIndex,
                                   Chave = '' + ISNULL(R.equality_columns, '') + CASE WHEN R.equality_columns IS NOT NULL
                                                                                           AND R.inequality_columns IS NOT NULL THEN ',' ELSE '' END + ISNULL(R.inequality_columns, '') + '',
                                   ColunaIncluida = R.included_columns,
                                   R.Avg_Estimated_Impact,
                                   R.magic_benefit_number
                              FROM #Missings R
                        ),
                         ResultTwo
                        AS
                        (
                            SELECT R.object_id,
                                   R.s,
                                   R.o,
                                   R.equality_columns,
                                   R.inequality_columns,
                                   R.included_columns,
                                   R.unique_compiles,
                                   R.user_seeks,
                                   R.last_user_seek,
                                   R.user_scans,
                                   R.last_user_scan,
                                   R.NomeIndex,
                                   Chave = CAST(LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(R.Chave, CHAR(32), ''), '[', ''), ']', ''))) AS VARCHAR(200)),
                                   ColunaIncluida = CAST(LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(R.ColunaIncluida, '[', CHAR(32)), ']', CHAR(32)), CHAR(32), ''))) AS VARCHAR(1000)),
                                   R.Avg_Estimated_Impact,
                                   R.magic_benefit_number
                              FROM Resumo R
                        )
                    INSERT INTO #Candidates(
                                               object_id,
                                               s,
                                               o,
                                               equality_columns,
                                               inequality_columns,
                                               included_columns,
                                               unique_compiles,
                                               user_seeks,
                                               last_user_seek,
                                               user_scans,
                                               last_user_scan,
                                               NomeIndex,
                                               Chave,
                                               ColunaIncluida,
                                               Avg_Estimated_Impact,
                                               magic_benefit_number
                                           )
                    SELECT T.object_id,
                           T.s,
                           T.o,
                           T.equality_columns,
                           T.inequality_columns,
                           T.included_columns,
                           T.unique_compiles,
                           T.user_seeks,
                           T.last_user_seek,
                           T.user_scans,
                           T.last_user_scan,
                           T.NomeIndex,
                           T.Chave,
                           T.ColunaIncluida,
                           T.Avg_Estimated_Impact,
                           T.magic_benefit_number
                      FROM ResultTwo T;

                    WITH AnaliseObjetosUnicos
                        AS
                        (
                            SELECT C.object_id,
                                   C.s,
                                   C.o,
                                   C.user_seeks,
                                   C.user_scans,
                                   C.unique_compiles,
                                   C.NomeIndex,
                                   C.Chave,
                                   C.PrimeiraChave,
                                   C.ColunaIncluida,
                                   C.Avg_Estimated_Impact,
                                   C.magic_benefit_number,
                                   CountObjectId = COUNT(C.object_id) OVER (PARTITION BY C.object_id)
                              FROM #Candidates AS C
                        ),
                         Resumo1
                        AS
                        (
                            SELECT A.object_id,
                                   A.s,
                                   A.o,
                                   A.user_seeks,
                                   A.user_scans,
                                   A.unique_compiles,
                                   A.NomeIndex,
                                   A.Chave,
                                   A.PrimeiraChave,
                                   A.ColunaIncluida,
                                   A.CountObjectId,
                                   A.Avg_Estimated_Impact,
                                   A.magic_benefit_number,
                                   potential_read_op = (I.user_seeks + I.user_scans),
                                   reads = (I.user_seeks + I.user_scans + I.user_lookups),
                                   [write:read ratio] = CAST((I.user_updates * 1.0 / (I.user_scans + I.user_seeks + I.user_lookups)) AS DECIMAL(10, 2))
                              FROM AnaliseObjetosUnicos A
                                   JOIN(
                                           SELECT I.object_id,
                                                  SUM(I.user_seeks) user_seeks,
                                                  SUM(I.user_scans) user_scans,
                                                  SUM(I.user_lookups) user_lookups,
                                                  SUM(I.user_updates) user_updates
                                             FROM #indexusage AS I
                                            GROUP BY
                                               I.object_id
                                       ) AS I ON A.object_id = I.object_id
                        )
                    INSERT INTO #FirtResultIntermediate
                    SELECT R.object_id,
                           R.s,
                           R.o,
                           R.user_seeks,
                           R.user_scans,
                           R.unique_compiles,
                           R.NomeIndex,
                           R.Chave,
                           R.PrimeiraChave,
                           R.ColunaIncluida,
                           R.Avg_Estimated_Impact,
                           R.magic_benefit_number,
                           R.potential_read_op,
                           R.reads,
                           R.[write:read ratio]
                      FROM Resumo1 R
                     WHERE
                        R.CountObjectId = 1;

                    INSERT INTO #Final
                    SELECT R.object_id,
                           R.s,
                           R.o,
                           R.user_seeks,
                           R.user_scans,
                           R.unique_compiles,
                           R.IndexName,
                           R.Chave,
                           R.PrimeiraChave,
                           R.ColunaIncluida,
                           R.Avg_Estimated_Impact,
                           R.magic_benefit_number,
                           R.potential_read_op,
                           R.reads,
                           R.[write:read ratio]
                      FROM #FirtResultIntermediate R
                     WHERE
                        (
                            R.magic_benefit_number >= @defaultTunningPerform
                            AND R.Avg_Estimated_Impact >= @defaultTunningPerform
                            OR (R.magic_benefit_number >= @defaultTunningPerform * 10)
                               AND (
                                       R.[write:read ratio] < 1 -- Maior que 1 BAD Index
                                       AND R.potential_read_op > (@defaultTunningPerform / 20.0)
                                   )
                        );

                    DELETE FROM #Candidates
                     WHERE
                        #Candidates.object_id IN(
                                                    SELECT FRI.object_id FROM #FirtResultIntermediate AS FRI
                                                );

                    TRUNCATE TABLE #FirtResultIntermediate;

                    WITH Analise2
                        AS
                        (
                            SELECT C.object_id,
                                   C.user_seeks,
                                   C.s,
                                   C.o,
                                   C.user_scans,
                                   C.unique_compiles,
                                   C.NomeIndex,
                                   C.Chave,
                                   C.PrimeiraChave,
                                   C.ColunaIncluida,
                                   C.Avg_Estimated_Impact,
                                   C.magic_benefit_number,
                                   CountObjectId = COUNT(*) OVER (PARTITION BY C.object_id),
                                   CountObjectIdAndChave = COUNT(*) OVER (PARTITION BY C.object_id, C.PrimeiraChave),
                                   TotalMagic_benefit_number = SUM(C.magic_benefit_number) OVER (PARTITION BY C.object_id, C.PrimeiraChave),
                                   MaxMagic_benefit_number = MAX(C.magic_benefit_number) OVER (PARTITION BY C.object_id, C.PrimeiraChave),
                                   TotalAvg_Estimated_Impact = SUM(C.Avg_Estimated_Impact) OVER (PARTITION BY C.object_id, C.PrimeiraChave),
                                   MaxAvg_Estimated_Impact = MAX(C.Avg_Estimated_Impact) OVER (PARTITION BY C.object_id, C.PrimeiraChave)
                              FROM #Candidates AS C
                        ),
                         Custo2
                        AS
                        (
                            SELECT two.object_id,
                                   two.o,
                                   two.s,
                                   two.user_seeks,
                                   two.user_scans,
                                   two.unique_compiles,
                                   two.NomeIndex,
                                   two.Chave,
                                   two.PrimeiraChave,
                                   two.ColunaIncluida,
                                   two.Avg_Estimated_Impact,
                                   two.magic_benefit_number,
                                   two.CountObjectId,
                                   two.CountObjectIdAndChave,
                                   two.TotalMagic_benefit_number,
                                   two.MaxMagic_benefit_number,
                                   two.TotalAvg_Estimated_Impact,
                                   two.MaxAvg_Estimated_Impact,
                                   potential_read_op = (I.user_seeks + I.user_scans),
                                   reads = (I.user_seeks + I.user_scans + I.user_lookups),
                                   [write:read ratio] = CAST((I.user_updates * 1.0 / (I.user_scans + I.user_seeks + I.user_lookups)) AS DECIMAL(10, 2))
                              FROM Analise2 two
                                   JOIN(
                                           SELECT I.object_id,
                                                  SUM(I.user_seeks) user_seeks,
                                                  SUM(I.user_scans) user_scans,
                                                  SUM(I.user_lookups) user_lookups,
                                                  SUM(I.user_updates) user_updates
                                             FROM #indexusage AS I
                                            GROUP BY
                                               I.object_id
                                       ) AS I ON two.object_id = I.object_id
                        )
                    INSERT INTO #Final(
                                          object_id,
                                          s,
                                          o,
                                          user_seeks,
                                          user_scans,
                                          unique_compiles,
                                          IndexName,
                                          Chave,
                                          PrimeiraChave,
                                          ColunaIncluida,
                                          Avg_Estimated_Impact,
                                          magic_benefit_number,
                                          potential_read_op,
                                          reads,
                                          [write:read ratio]
                                      )
                    SELECT C.object_id,
                           C.s,
                           C.o,
                           C.user_seeks,
                           C.user_scans,
                           C.unique_compiles,
                           C.NomeIndex,
                           C.Chave,
                           C.PrimeiraChave,
                           C.ColunaIncluida,
                           C.Avg_Estimated_Impact,
                           C.magic_benefit_number,
                           C.potential_read_op,
                           C.reads,
                           C.[write:read ratio]
                      FROM Custo2 C
                     WHERE
                        (
                            C.TotalMagic_benefit_number > @defaultTunningPerform
                            AND C.TotalAvg_Estimated_Impact > @defaultTunningPerform
                        )
                        OR (
                               C.TotalMagic_benefit_number > (@defaultTunningPerform * 20)
                               AND (
                                       C.[write:read ratio] < 1 -- Maior que 1 is BAD Index
                                       AND C.potential_read_op > (@defaultTunningPerform / 20.0)
                                   )
                           );

                    WITH Final
                        AS
                        (
                            SELECT F.object_id,
                                   F.s,
                                   F.o,
                                   F.IndexName,
                                   F.Chave,
                                   F.PrimeiraChave,
                                   F.ColunaIncluida,
                                   MAX(F.Avg_Estimated_Impact) Avg_Estimated_Impact,
                                   MAX(F.magic_benefit_number) magic_benefit_number,
                                   MAX(F.potential_read_op) potential_read_op,
                                   MAX(F.reads) reads,
                                   MAX(F.[write:read ratio]) [write:read ratio]
                              FROM #Final AS F
                             GROUP BY
                                F.object_id,
                                F.s,
                                F.o,
                                F.IndexName,
                                F.Chave,
                                F.PrimeiraChave,
                                F.ColunaIncluida
                        )
                    INSERT INTO #Retorno
                    SELECT ObjectId = FI.object_id,
                           TotalObjetcId = COUNT(*) OVER (PARTITION BY FI.object_id),
                           SchemaName = FI.s,
                           TableName = FI.o,
                           FI.IndexName,
                           FI.Chave,
                           FI.PrimeiraChave,
                           ExisteIndiceNaChave = (CASE WHEN EXISTS (
                                                                       SELECT 1
                                                                         FROM sys.indexes AS I
                                                                              JOIN sys.index_columns AS IC ON I.object_id = IC.object_id
                                                                                                              AND I.index_id = IC.index_id
                                                                              JOIN sys.columns AS C ON I.object_id = C.object_id
                                                                                                       AND IC.column_id = C.column_id
                                                                                                       AND IC.is_included_column = 0
                                                                        WHERE
                                                                           I.object_id = FI.object_id
                                                                           AND C.name COLLATE DATABASE_DEFAULT = FI.PrimeiraChave
                                                                           AND IC.key_ordinal = 1
                                                                   ) THEN 1 ELSE 0 END
                                                 ),
                           ChavePertenceAOutroIndice = (CASE WHEN EXISTS (
                                                                             SELECT 1
                                                                               FROM sys.indexes AS I
                                                                                    JOIN sys.index_columns AS IC ON I.object_id = IC.object_id
                                                                                                                    AND I.index_id = IC.index_id
                                                                                    JOIN sys.columns AS C ON I.object_id = C.object_id
                                                                                                             AND IC.column_id = C.column_id
                                                                                                             AND IC.is_included_column = 0
                                                                              WHERE
                                                                                 I.object_id = FI.object_id
                                                                                 AND C.name COLLATE DATABASE_DEFAULT = FI.PrimeiraChave
                                                                                 AND IC.key_ordinal > 1
                                                                         ) THEN 1 ELSE 0 END
                                                       ),
                           FI.ColunaIncluida,
                           AvgEstimatedImpact = FI.Avg_Estimated_Impact,
                           MagicBenefitNumber = FI.magic_benefit_number,
                           PotentialReadOp = FI.potential_read_op,
                           FI.reads,
                           [PercCustoMedio] = FI.[write:read ratio],
                           CreateIndex = CONCAT('CREATE INDEX [IX_', FI.s, FI.o, REPLACE(FI.Chave, ',', ''), '] ON [', FI.s, '].[', FI.o, ']
			  (', FI.Chave, ')' + ISNULL(' INCLUDE (' + FI.ColunaIncluida + ')', SPACE(0)))
                      FROM Final FI;

                    SELECT * FROM #Retorno AS R;
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
    END;
GO