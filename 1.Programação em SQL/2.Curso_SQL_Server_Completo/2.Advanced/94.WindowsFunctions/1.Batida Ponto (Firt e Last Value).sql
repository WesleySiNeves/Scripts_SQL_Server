DECLARE @table TABLE (id INT ,dataAcesso VARCHAR(MAX) ,horario VARCHAR(5))

INSERT INTO @table
        ( id, dataAcesso, horario ) VALUES  ( 1,'20/11/2016', '09:30' )
									    	,( 1,'20/11/2016', '12:00' )
											,( 1,'20/11/2016', '13:00' )
											,( 1,'20/11/2016', '18:30' )
											,( 4,'20/11/2016', '08:30' )
											,( 4,'20/11/2016', '12:01' )
											,( 4,'20/11/2016', '13:10' )
											,( 4,'20/11/2016', '18:00' );
 


 WITH   Dados
          AS ( SELECT   T.id ,
                        T.dataAcesso ,
                        T.horario,
						PrimeiroAcesso = FIRST_VALUE(t.horario) OVER(PARTITION BY T.id ORDER BY T.id),
						UltimoAcesso = LAST_VALUE(t.horario) OVER(PARTITION BY T.id ORDER BY T.id)
               FROM     @table AS T
             )
    SELECT  Dados.id ,
            Dados.dataAcesso ,
            Dados.horario,
			Dados.PrimeiroAcesso,
			Dados.UltimoAcesso
    FROM    Dados
	WHERE Dados.horario = Dados.PrimeiroAcesso 
	ORDER BY Dados.id
