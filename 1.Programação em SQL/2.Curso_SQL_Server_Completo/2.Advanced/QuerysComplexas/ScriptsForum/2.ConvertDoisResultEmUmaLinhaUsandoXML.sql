
/*https://social.technet.microsoft.com/Forums/sqlserver/pt-BR/f77293b3-c697-4b8c-8486-835a407a5bb8/como-implementar-um-select-com-faixas-que-se-mesclam?forum=520*/

USE TSQL2012
 DECLARE @DataAtual DATE;          
 SET @DataAtual = GETDATE();


--Criei uma tabela temporária com os dados de demostração 
--na sua SP 
IF ( OBJECT_ID('TEMPDB..#TablePeriodos') IS NOT NULL )
    DROP TABLE #TablePeriodos;	

CREATE TABLE #TablePeriodos
    (
      PeriodoDe INT NOT NULL ,
      PeriodoAte INT NULL ,
      Descricao  varchar(max)
      
    );
 
--Inserir os dados que vc demostrou,(os intervalos e descrição)

 INSERT INTO #TablePeriodos
         ( PeriodoDe, PeriodoAte, Descricao )
 VALUES  ( 0, -- PeriodoDe - int
           14, -- PeriodoAte - int
           'Neonatal (nascimento aos 14 dias)'  -- Descricao - varchar(max)
           ),
		     ( 15, -- PeriodoDe - int
           21, -- PeriodoAte - int
           'Transição (de 15 a 21 dias)'  -- Descricao - varchar(max)
           ),
		      ( 21, -- PeriodoDe - int
           28, -- PeriodoAte - int
           'Reconhecimento (de 21 a 28 dias)'  -- Descricao - varchar(max)
           ),
 
               ( 21, -- PeriodoDe - int
           49, -- PeriodoAte - int
           'Socialização com animais (de 21 a 49 dias)'  -- Descricao - varchar(max)
           ),
		      ( 49, -- PeriodoDe - int
           84, -- PeriodoAte - int
           'Socializacao com humanos (de 7 a 12 semanas)'  -- Descricao - varchar(max)
           ),
		     ( 56, -- PeriodoDe - int
           77, -- PeriodoAte - int
           'Medo I(de 8 a 11 semana)'  -- Descricao - varchar(max)
           ),
		     ( 91, -- PeriodoDe - int
           112, -- PeriodoAte - int
           'Rebeldia ( de 13 a 16 semanas)'  -- Descricao - varchar(max)
           ),
             ( 120, -- PeriodoDe - int
           240, -- PeriodoAte - int
           'Surdez seletiva (4 a 8 meses)'  -- Descricao - varchar(max)
           ),
		     ( 180, -- PeriodoDe - int
           420, -- PeriodoAte - int
           'Medo II (de 6 as 14 meses)'  -- Descricao - varchar(max)
           ),
		       ( 365, -- PeriodoDe - int
           1460, -- PeriodoAte - int
           'Maturidade (1 a 4 anos)'  -- Descricao - varchar(max)
           ),
		      ( 1461, -- PeriodoDe - int
           99999, -- PeriodoAte - int
           'Senior'  -- Descricao - varchar(max)
           )


 --Select usando o Tipo XML

 SELECT A.Nome ,
        @DataAtual AS data_atual ,
        A.data_Nasc ,
        ( CONVERT(VARCHAR, DATEDIFF(YEAR, A.data_Nasc, @DataAtual))
          + ' ano(s)' ) AS 'Idade(anos)' ,
        ( CONVERT(VARCHAR, DATEDIFF(MONTH, A.data_Nasc, @DataAtual))
          + ' mes(es)' ) AS 'Idade(meses)' ,
        ( CONVERT(VARCHAR, DATEDIFF(SECOND, A.data_Nasc, @DataAtual) / 86400
          / 7) + ' semana(s)' ) AS 'Idade(Semanas)' ,
        SUBSTRING(( SELECT  '/' + P.Descricao AS [text()]
                    FROM    #TablePeriodos P
                    WHERE   DATEDIFF(DAY, A.data_Nasc, @DataAtual) BETWEEN P.PeriodoDe
                                                              AND
                                                              P.PeriodoAte
                  FOR
                    XML PATH('')
                  ), 2, 10000) AS 'PERÍODO'
 FROM   dbo.Animal_Companhia A
 ORDER BY A.data_Nasc;