/*
https://social.technet.microsoft.com/Forums/sqlserver/pt-BR/d4840649-9f17-4147-9f28-27b8593626f4/comando-while?forum=transactsqlpt
Preciso fazer  Forecast de quantos chamados (DP= Dentro Prazo) eu preciso para chegar ao percentual 80%, pensei em fazer um 
While para informar qual é a quantidade esperada (DP - Dentro Prazo), mas não conseguir evoluir.
*/
DECLARE @Table TABLE
    (
      IdRegistro INT PRIMARY KEY
                     IDENTITY(1, 1) ,
      Total INT ,
      DP INT ,
      PF INT ,
      Percentual NUMERIC(19, 2)
    );
INSERT  INTO @Table
        ( Total, DP, PF, Percentual )
VALUES  ( 9, 9, NULL, 1 ),
        ( 3622, 3380, 242, 0.9331 ),
        ( 2559, 2010, 242, 0.9331 );
 
SELECT  *
FROM    @Table AS T;
WITH    Dados
          AS ( SELECT   T.IdRegistro ,
                        T.Total ,
                        [Quantidade Para Atingir 80 %] = ( T.Total * 0.80 ) ,
                        [Quantidade Para Atingir 80 % Arredondado para menor] = FLOOR(( T.Total
                                                              * 0.80 )) ,  --Aqui estou arredondando,
                        T.DP ,
                        T.PF ,
                        T.Percentual
               FROM     @Table AS T
             )
    SELECT  R.IdRegistro ,
            R.Total ,
            R.[Quantidade Para Atingir 80 %] ,
            R.[Quantidade Para Atingir 80 % Arredondado para menor] ,
            R.DP ,
            [Meta Atingida] = CASE WHEN R.DP >= R.[Quantidade Para Atingir 80 % Arredondado para menor]
                                   THEN 'SIM'
                                   ELSE 'NÃO'
                              END ,
            R.PF ,
            R.Percentual
    FROM    Dados R;