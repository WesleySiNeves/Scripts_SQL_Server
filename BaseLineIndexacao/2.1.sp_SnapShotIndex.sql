SET QUOTED_IDENTIFIER ON;

SET ANSI_NULLS ON;
GO

CREATE OR ALTER PROCEDURE HealthCheck.uspSnapShotIndex
(
    @Visualizar  BIT      = 1,
    @DiaExecucao DATETIME = NULL,
    @Efetivar    BIT      = 0
)
AS
    BEGIN
        SET NOCOUNT ON;

        SET TRAN ISOLATION LEVEL READ UNCOMMITTED;

        --   DECLARE @DiaExecucao DATETIME;
        --DECLARE @Visualizar BIT = 1;
        --DECLARE @Efetivar BIT = 1 ;
        SET @DiaExecucao = ISNULL(@DiaExecucao, GETDATE());

        IF(OBJECT_ID('TEMPDB..#SchemasExcessao') IS NOT NULL)
            DROP TABLE #SchemasExcessao;

        CREATE TABLE #SchemasExcessao
        (
            SchemaName VARCHAR(128)
        );

        INSERT INTO #SchemasExcessao(SchemaName)VALUES('%HangFire%');

        IF(OBJECT_ID('TEMPDB..#Snapshot') IS NOT NULL)
            DROP TABLE #Snapshot;

        CREATE TABLE #Snapshot
        (
            ObjectId           INT,
            [ObjectName]       VARCHAR(300),
            [RowsInTable]      INT,
            [IndexName]        VARCHAR(128),
            [Usado]            BIT,
            UserSeeks          INT,
            UserScans          INT,
            UserLookups        INT,
            UserUpdates        INT,
            [Reads]            BIGINT,
            [Write]            INT,
            CountPageSplitPage INT,
            PercAproveitamento DECIMAL(18, 2),
            PercCustoMedio     DECIMAL(18, 2),
            [IsBadIndex]       INT,
            IndexId            SMALLINT,
            IndexSizeKB        BIGINT,
            IndexSizeMB        DECIMAL(18, 2),
            IndexSizePorTipoMB DECIMAL(18, 2),
            [Chave]            VARCHAR(899),
            [ColunasIncluidas] VARCHAR(899),
            IsUnique           BIT,
            IgnoreDupKey       BIT,
            IsPrimaryKey       BIT,
            IsUniqueConstraint BIT,
            FillFact           TINYINT,
            AllowRowLocks      BIT,
            AllowPageLocks     BIT,
            HasFilter          BIT,
            TypeIndex          TINYINT PRIMARY KEY(ObjectId, IndexId)
        );

        INSERT INTO #Snapshot

        /*Faz uma analise completa de todos os indices*/
        EXEC HealthCheck.uspAllIndex @SomenteUsado = 1, -- bit
                                     @TableIsEmpty = 0; -- bit

        DELETE S
          FROM #Snapshot S
               INNER JOIN(SELECT SSE.SchemaName FROM #SchemasExcessao AS SSE)Filtro ON S.ObjectName LIKE Filtro.SchemaName;

        IF(EXISTS (SELECT 1 FROM #Snapshot) AND @Efetivar = 1)
            BEGIN
                /*Merge in SnapShotIndex */
                INSERT INTO HealthCheck.SnapShotIndex(
                                                         ObjectId,
                                                         [ObjectName],
                                                         [IndexName],
                                                         IndexId
                                                     )
                SELECT S.ObjectId,
                       S.ObjectName,
                       S.IndexName,
                       S.IndexId
                  FROM #Snapshot S
                 WHERE
                    NOT EXISTS (
                                   SELECT 1
                                     FROM HealthCheck.SnapShotIndex AS SSI
                                    WHERE
                                       SSI.ObjectId = S.ObjectId
                                       AND SSI.IndexId = S.IndexId
                               );

                INSERT INTO HealthCheck.SnapShotIndexHistory(
                                                                ObjectId,
                                                                IndexId,
                                                                SnapShotDate,
                                                                RowsInTable,
                                                                IndexSizePorTipoMB,
                                                                IsBadIndex,
                                                                UserSeeks,
                                                                UserScans,
                                                                UserLookups,
                                                                UserUpdates,
                                                                Reads,
                                                                Write,
                                                                CountPageSplitPage,
                                                                [FillFactor],
                                                                PercAproveitamento,
                                                                PercCustoMedio,
                                                                IndexsizeKB,
                                                                IndexsizeMB,
                                                                TypeIndex
                                                            )
                SELECT Source.ObjectId,
                       Source.IndexId,
                       @DiaExecucao,
                       Source.RowsInTable,
                       Source.IndexSizePorTipoMB,
                       Source.IsBadIndex,
                       Source.UserSeeks,
                       Source.UserScans,
                       Source.UserLookups,
                       Source.UserUpdates,
                       Source.Reads,
                       Source.Write,
                       Source.CountPageSplitPage,
                       CASE WHEN Source.FillFact = 0 THEN 100
                       WHEN Source.FillFact = 20 THEN 80
                       WHEN Source.FillFact = 30 THEN 70 ELSE Source.FillFact END,
                       Source.PercAproveitamento,
                       Source.PercCustoMedio,
                       Source.IndexSizeKB,
                       Source.IndexSizeMB,
                       Source.TypeIndex
                  FROM #Snapshot AS Source;
            END;

        IF(@Visualizar = 1)
            BEGIN
                SELECT * FROM #Snapshot AS S;
            END;
    END;
GO