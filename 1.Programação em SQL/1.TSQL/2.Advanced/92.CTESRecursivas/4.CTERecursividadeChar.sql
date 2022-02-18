
DECLARE @Inicial INT = 32;
DECLARE @Final INT = 90;

WITH    Recursividade
          AS ( SELECT   @Inicial AS Campo ,
                        CHAR(@Inicial) AS Correspodente
               UNION ALL
               SELECT   R.Campo + 1 ,
                        CHAR(R.Campo + 1) AS Correspodente
               FROM     Recursividade R 
			   WHERE R.Campo <= @Final)
     SELECT *
     FROM   Recursividade;


