
/*Por padrão a recursividade maxima e 100 , se tirar o (OPTION(MAXRECURSION 102)) da erro*/
DECLARE @inicio INT = 1 ,
    @Fim INT = 101;


WITH    Dados 
          AS ( SELECT   @inicio AS Numero
               UNION ALL
               SELECT   D.Numero +1
               FROM     Dados D
               WHERE    D.Numero <= @Fim
              )
    SELECT  Dados.Numero
    FROM    Dados OPTION(MAXRECURSION 102);



