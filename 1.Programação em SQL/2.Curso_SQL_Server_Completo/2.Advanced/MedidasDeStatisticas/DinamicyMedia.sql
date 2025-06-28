DECLARE @test VARCHAR = 1
DECLARE @sqlCommand VARCHAR(1000)

IF ( OBJECT_ID('TEMPDB..#tempTable') IS NOT NULL )
    DROP TABLE #tempTable;	


CREATE TABLE #tempTable   (myValue INT)

INSERT INTO #tempTable ( myValue ) VALUES  ( 5)
INSERT INTO #tempTable ( myValue ) VALUES  ( 6)
INSERT INTO #tempTable ( myValue ) VALUES  ( 7)
INSERT INTO #tempTable ( myValue ) VALUES  ( 8)
INSERT INTO #tempTable ( myValue ) VALUES  ( 9)
INSERT INTO #tempTable ( myValue ) VALUES  ( 10)

SET @sqlCommand = 'SELECT myValue , SUM(myValue) OVER (ORDER BY myValue ROWS BETWEEN ' + @test + 
' PRECEDING AND CURRENT ROW) as Media
                  FROM #tempTable'

EXEC (@sqlCommand)