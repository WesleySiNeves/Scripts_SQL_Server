

DECLARE @DataInicio DATETIME =  DATEFROMPARTS(2017,5,1);


--GO
SELECT * FROM GetRlatorioMensal(@DataInicio)

CREATE FUNCTION GetRlatorioMensal ( @DataInicio DATETIME )
RETURNS @retorno TABLE
    (
      Numero INT ,
      Data VARCHAR(10) ,
      Total DECIMAL(18, 2)
    )
AS
    BEGIN

        DECLARE @DataTermino DATETIME = EOMONTH(@DataInicio);

        DECLARE @tabela TABLE
            (
              numero INT ,
              Data DATETIME ,
              Valor DECIMAL(18, 2)
            );

        INSERT  INTO @tabela
        VALUES  ( 231629, '2017-06-08 00:00:00.000', 29.93 ),
                ( 231149, '2017-05-29 00:00:00.000', 29.93 ),
                ( 231149, '2017-05-29 00:00:00.000', 29.93 ),
                ( 231149, '2017-05-29 00:00:00.000', 29.93 ),
                ( 231149, '2017-05-29 00:00:00.000', 29.93 ),
                ( 231149, '2017-05-29 00:00:00.000', 29.93 ),
                ( 231149, '2017-05-29 00:00:00.000', 29.93 ),
                ( 231095, '2017-05-26 00:00:00.000', 29.93 ),
                ( 230941, '2017-05-24 00:00:00.000', 29.93 ),
                ( 230941, '2017-05-24 00:00:00.000', 29.93 ),
                ( 230555, '2017-05-16 00:00:00.000', 29.93 );

        INSERT  INTO @retorno
                SELECT  T.numero ,
                        Data = CONVERT(VARCHAR(10), T.Data, 103) ,
                        [Total] = SUM(T.Valor)
                FROM    @tabela AS T
                WHERE   CAST(T.Data AS DATE) BETWEEN CAST(@DataInicio AS DATE)
                                             AND     CAST(@DataTermino AS DATE)
                GROUP BY T.numero ,
                        T.Data
                ORDER BY T.numero;


        RETURN;

    END;




 



	   
       