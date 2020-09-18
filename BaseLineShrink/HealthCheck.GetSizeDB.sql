SET QUOTED_IDENTIFIER ON;

SET ANSI_NULLS ON;
GO

/* ==================================================================
--Data: 9/15/2020 
--Autor :Wesley Neves
--Parametros->
1) @tableOnSave =  Tabela para quardar o o tamanho do banco de dados Default = HealthCheck.SizeDBHistory
padrão da tabela 

CREATE TABLE [HealthCheck].[SizeDBHistory]
(
    [IdSizeDBHistory]          [INT]            NOT NULL IDENTITY(1, 1),
    [DataBaseName]             [VARCHAR](128)   COLLATE Latin1_General_CI_AI NULL,
    [Data]                     [DATE]           NOT NULL CONSTRAINT [HealthCheckSizeDBHistoryData] DEFAULT(CONVERT([DATE], GETDATE())),
    [SizeInGB]                 [DECIMAL](18, 2) NULL,
    [DatabaseSpaceUsedInGB]    [DECIMAL](18, 2) NULL,
    [DatabaseSpaceNonUsedInGB] [DECIMAL](18, 2) NULL
) ON [PRIMARY]
WITH (DATA_COMPRESSION = PAGE);
GO

ALTER TABLE [HealthCheck].[SizeDBHistory]
ADD CONSTRAINT [PKHealthSizeDBHistoryIdSizeDBHistory] PRIMARY KEY CLUSTERED([IdSizeDBHistory])WITH(DATA_COMPRESSION = PAGE);
GO
 

 2) @typeFile  => tipo de retorno da procedure 
 --'All => retorna as informações dos datafiles de Rows e Logs
    ROW => retorna as informações dos datafiles de Rows
	LOG => retorna as informações dos datafiles de  Logs
   
-- ==================================================================
*/

--HealthCheck.uspGetSizeDB @typeFile ='All'

CREATE OR ALTER PROCEDURE HealthCheck.uspGetSizeDB
(
    @tableOnSave VARCHAR(128) = 'HealthCheck.SizeDBHistory',
    @persisted   BIT          = 0,
    @typeFile    VARCHAR(5)   = 'ROWS'
)
AS
    BEGIN

        --DECLARE @tableOnSave VARCHAR(128) = 'HealthCheck.SizeDBHistory'
        --DECLARE @persisted BIT = 0;
        --DECLARE @typeFile VARCHAR(5) = 'All'; --'All / ROWS/ LOG'
        DROP TABLE IF EXISTS #SizeOfDB;

        CREATE TABLE #SizeOfDB
        (
            [DataBaseName]             NVARCHAR(128),
            [type_desc]                NVARCHAR(60),
            [SizeInGB]                 DECIMAL(18, 2),
            [DatabaseSpaceUsedInGB]    DECIMAL(18, 2),
            [DatabaseSpaceNonUsedInGB] DECIMAL(18, 2)
        );

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
        INSERT INTO #SizeOfDB SELECT * FROM Detalhes R;

        IF(@persisted = 1 AND LEN(@tableOnSave) > 0)
            BEGIN
                INSERT INTO HealthCheck.SizeDBHistory(
                                                         DataBaseName,
                                                         SizeInGB,
                                                         DatabaseSpaceUsedInGB,
                                                         DatabaseSpaceNonUsedInGB
                                                     )
                SELECT SOD.DataBaseName,
                       SOD.SizeInGB,
                       SOD.DatabaseSpaceUsedInGB,
                       SOD.DatabaseSpaceNonUsedInGB
                  FROM #SizeOfDB AS SOD
                 WHERE
                    SOD.type_desc = 'ROWS';
            END;

        SELECT *
          FROM #SizeOfDB AS SOD
         WHERE
            @typeFile = 'ALL'
            OR (SOD.type_desc = @typeFile);
    END;
