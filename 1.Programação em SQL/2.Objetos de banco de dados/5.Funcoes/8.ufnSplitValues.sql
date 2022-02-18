
ALTER FUNCTION dbo.SplitValues
    (
      @texto VARCHAR(MAX) ,
      @delimiter NVARCHAR(5)
    )
RETURNS @Dados TABLE ( DATA VARCHAR(MAX) )
AS
    BEGIN
        DECLARE @valor VARCHAR(MAX) = LTRIM(RTRIM(@texto));
		
        DECLARE
            @prefixos NVARCHAR(MAX) ,
            @textXML XML;

        SELECT
            @prefixos = @valor;
        SELECT
            @textXML = CAST('<d>' + REPLACE(@prefixos, @delimiter, '</d><d>')
            + '</d>' AS XML);
        
        INSERT  INTO @Dados
                SELECT
                    X.DATA
                FROM
                    ( SELECT
                        T.split.value('.', 'nvarchar(max)') AS DATA
                      FROM
                        @textXML.nodes('/d') T ( SPLIT )
                    ) AS X;

        RETURN;
    END; 

 SELECT * FROM  dbo.SplitValues('JOSÉ FERREIRA DE SOUZA',' ')
  SELECT * FROM  dbo.SplitValues('Wesley Everton de Jesus neves',' ')
  SELECT * FROM  dbo.SplitValues('1,2,3,4,5,6,7,8,9,10',',')
  SELECT * FROM  dbo.SplitValues('01;020;03;04;50;06;07;80;90;100',';')