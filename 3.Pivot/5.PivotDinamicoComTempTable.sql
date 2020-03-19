CREATE TABLE #TableDemostracao 
    (
      ID_PESS INT ,
      NOME VARCHAR(30) ,
      DATA DATE ,
      DATA_HORA DATETIME ,
      SEQUENCIAL INT
    );

INSERT  INTO #TableDemostracao
        ( ID_PESS, NOME, DATA, DATA_HORA, SEQUENCIAL )
VALUES  ( 8788, 'JOAO', '2017-01-01', '2017-01-01 13:01:01', 1 ),
        ( 8788, 'JOAO', '2017-01-01', '2017-01-01 15:07:01', 2 ),
        ( 8788, 'JOAO', '2017-01-01', '2017-01-01 17:08:01', 3 ),
        ( 8788, 'JOAO', '2017-01-01', '2017-01-01 19:03:01', 4 ),
        ( 8788, 'JOAO', '2017-01-02', '2017-01-02 19:03:01', 1 ),
        ( 8533, 'MARIA', '2017-01-03', '2017-01-03 11:01:01', 1 ),
        ( 8533, 'MARIA', '2017-01-03', '2017-01-03 14:07:01', 2 ),
        ( 8533, 'MARIA', '2017-01-03', '2017-01-03 16:08:01', 3 );




DECLARE @cols NVARCHAR (MAX)



SELECT @cols = COALESCE (@cols + ',[' + CAST([SEQUENCIAL] AS VARCHAR(10)) + ']', 
               '[' + CAST([SEQUENCIAL] AS VARCHAR(10)) + ']')
               FROM    (SELECT DISTINCT [SEQUENCIAL] FROM #TableDemostracao) PV  
               ORDER BY [SEQUENCIAL]


SELECT @cols

DECLARE @query NVARCHAR(MAX)

SET @query = '
WITH    DadosPivot
          AS ( SELECT   T.ID_PESS ,
                        T.NOME ,
                        T.DATA ,
                        T.DATA_HORA ,
                        T.SEQUENCIAL
               FROM     #TableDemostracao T
               
             )
    
    SELECT  *
    FROM    DadosPivot PIVOT ( MAX(DATA_HORA) FOR SEQUENCIAL IN ( '+@cols+') ) P';


EXEC(@query);