SET QUOTED_IDENTIFIER ON
SET ANSI_NULLS ON
GO

CREATE  OR ALTER  PROCEDURE dbo.GetElmahErrosOnAplication
AS
    BEGIN
IF(EXISTS (SELECT * FROM sys.tables AS T WHERE T.name = 'ELMAH_Error'))
    BEGIN
        WITH Dados
            AS
            (
                SELECT EE.ErrorId,
                       EE.Application,
                       EE.Host,
                       EE.Type,
                       EE.Source,
                       EE.Message,
                       EE.[User],
                       EE.StatusCode,
                       EE.TimeUtc,
                       ServerName = DB_NAME(),
                        EE.AllXml
                  FROM dbo.ELMAH_Error AS EE
                 WHERE
                    EE.Type <> 'Info'
					AND TRY_CAST(EE.AllXml AS XML)  IS NOT NULL
            )
        SELECT R.ErrorId,
               R.Application,
               R.Host,
               R.Type,
               R.Source,
               R.Message,
               R.[User],
               R.StatusCode,
               R.TimeUtc,
               R.AllXml,
			   R.ServerName
          FROM Dados R
         WHERE
            R.ServerName IS NOT NULL;
    END;
ELSE
    BEGIN
        DROP TABLE IF EXISTS #retorno;

        CREATE TABLE #retorno
        (
            [ErrorId]     UNIQUEIDENTIFIER,
            [Application] VARCHAR(60),
            [Host]        VARCHAR(50),
            [Type]        VARCHAR(100),
            [Source]      VARCHAR(60),
            [Message]     VARCHAR(500),
            [User]        VARCHAR(50),
            [StatusCode]  INT,
            [TimeUtc]     DATETIME,
            [AllXml]      VARCHAR(MAX),
			ServerName  VARCHAR(40)
        );

        SELECT * FROM #retorno AS R;
    END;
END;

GO