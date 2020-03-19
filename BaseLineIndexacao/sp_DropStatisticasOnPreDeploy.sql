

CREATE OR ALTER PROCEDURE [HealthCheck].[uspDropStatsOnColumn]
(
    @strTableName  NVARCHAR(100) = 'aowCompositeFact',
    @strColumnName NVARCHAR(100) = 'SystemSourceID',
    @blnPrintOnly  BIT           = 1
)
AS

/*

exec uspDropStatsOnColumn

*/
SET NOCOUNT ON;

DECLARE @StatsInfo TABLE
(
    strStatName VARCHAR(128),
    strColumns  VARCHAR(2100)
);

INSERT INTO @StatsInfo EXEC sys.sp_helpstats @strTableName;

DECLARE @strSQL VARCHAR(8000);

SET @strSQL = '';

SELECT @strSQL = @strSQL + 'DROP STATISTICS ' + @strTableName + '.' + [@StatsInfo].strStatName + '; ' + CHAR(13)
  FROM @StatsInfo
 WHERE
    [@StatsInfo].strColumns LIKE '%' + @strColumnName + '%';

IF @blnPrintOnly = 1
    PRINT @strSQL;
ELSE
    EXEC(@strSQL);
GO