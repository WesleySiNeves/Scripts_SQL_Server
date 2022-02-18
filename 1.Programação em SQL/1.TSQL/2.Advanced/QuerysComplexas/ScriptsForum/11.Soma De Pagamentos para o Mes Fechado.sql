https://social.technet.microsoft.com/Forums/sqlserver/pt-BR/2440e169-16bd-4a47-a4a5-7abcd002522a/relatrio-com-data?forum=520



DECLARE @DataInicio DATETIME = DATEFROMPARTS(2017, 1, 1);
DECLARE @DataTermino DATETIME = DATEFROMPARTS(2017, 5, 25);


DECLARE @MesInicio SMALLINT = MONTH(@DataInicio);
DECLARE @MesTermino SMALLINT = MONTH(@DataTermino);


DECLARE @UltimoDiaDoMesDaDataTermino DATETIME = ( SELECT DATEADD(s, -1,DATEADD(mm,DATEDIFF(m, 0,@DataTermino)+ 1, 0))
                                   );

--SELECT @DataTermino ,
--        @UltimoDiaDoMesDaDataTermino;


SET @MesTermino = ( SELECT CASE WHEN @DataTermino < @UltimoDiaDoMesDaDataTermino
                                THEN ( MONTH(@DataTermino) - 1 )
                                ELSE MONTH(@DataTermino)
                           END
                  );
--SELECT @MesTermino;

SELECT Mes = MONTH(P.DataPagamento) ,
        quantidade = COUNT(*) ,
        total = SUM(P.Valor)
    FROM Despesa.Pagamentos AS P
    WHERE MONTH(P.DataPagamento) BETWEEN @MesInicio
                                 AND     @MesTermino
    GROUP BY MONTH(P.DataPagamento)
    ORDER BY Mes;
