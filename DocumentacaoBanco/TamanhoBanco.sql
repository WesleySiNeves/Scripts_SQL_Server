
--CREATE TABLE HealthCheck.SizeDBHistory
--(
--    IdSizeDBHistory INT   NOT NULL IDENTITY(1,1) CONSTRAINT PKHealthSizeDBHistoryIdSizeDBHistory PRIMARY KEY(IdSizeDBHistory),
--    [DataBaseName]             NVARCHAR(128),
--	Data  DATE NOT NULL CONSTRAINT HealthCheckSizeDBHistoryData DEFAULT(GETDATE()),
--    [SizeInGB]                 DECIMAL(18, 2),
--    [DatabaseSpaceUsedInGB]    DECIMAL(18, 2),
--    [DatabaseSpaceNonUsedInGB] DECIMAL(18, 2)
--);


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
			AND NOT EXISTS(SELECT * FROM HealthCheck.SizeDBHistory AS SDH
					WHERE SDH.Data = CAST(GETDATE() AS DATE))
    END;

