
DECLARE @tabela TABLE
    (
      Cliente CHAR(1) NOT NULL ,
      Preco DECIMAL(18, 2)
    );

INSERT  INTO @tabela
        ( Cliente, Preco )
VALUES  ( 'X', 11.00 ),
        ( 'Y', 12.00 ),
        ( 'Z', 13.00 ),
        ( 'K', 11.00 ),
        ( 'P', 11.00 ),
        ( 'U', 10.00 );


				

        SELECT  T.Cliente ,
                T.Preco,
				[Registro da Moda] = Moda.Preco
        FROM    @tabela AS T
                CROSS APPLY ( SELECT TOP 1
                                        T2.Preco ,
                                        quantidade = COUNT(T2.Preco)
                              FROM      @tabela AS T2
                              GROUP BY  T2.Preco
                              ORDER BY  quantidade DESC
                            ) AS Moda

			   
		


;WITH    CalculoModa
          AS ( SELECT   T.Cliente ,
                        T.Preco ,
                        Quantidade = COUNT(T.Preco) OVER ( PARTITION BY T.Preco )
               FROM     @tabela AS T
             ),
        Resumo
          AS ( SELECT   CalculoModa.Cliente ,
                        CalculoModa.Preco ,
                        CalculoModa.Quantidade ,
                        MaiorOcorrencia = MAX(CalculoModa.Quantidade) OVER ( )
               FROM     CalculoModa
             )
    SELECT  Resumo.Cliente ,
            Resumo.Preco ,
            Moda = ( SELECT TOP 1
                            RE.Preco
                     FROM   Resumo RE
                     WHERE  RE.Quantidade = RE.MaiorOcorrencia
                   ) ,
            Resumo.Quantidade ,
            Resumo.MaiorOcorrencia
    FROM    Resumo;

			 


			 