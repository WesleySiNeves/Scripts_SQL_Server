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