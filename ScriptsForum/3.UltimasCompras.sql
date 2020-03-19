DECLARE @Itens TABLE
    (
      idTabela INT IDENTITY(1, 1) ,
      NomeItem VARCHAR(10)
    )


DECLARE @VendasItens TABLE
    (
      IdTabela INT IDENTITY(1, 1) ,
      IdItemComprado INT ,
      Valor DECIMAL(18, 2) ,
      Data DATE
    )

INSERT  INTO @Itens
        ( NomeItem )
VALUES  ( 'Item 1' ),
        ( 'Item 2' ) ,
        ( 'Item 3' )

INSERT  INTO @VendasItens
        ( IdItemComprado, Valor, Data )
VALUES  ( 1, 10, DATEADD(MONTH, -7, GETDATE()) ),
        ( 1, 20, DATEADD(MONTH, -6, GETDATE()) ),
        ( 1, 30, DATEADD(MONTH, -5, GETDATE()) ),
        ( 1, 40, DATEADD(MONTH, -4, GETDATE()) ),
        ( 1, 50, DATEADD(MONTH, -3, GETDATE()) ),
        ( 1, 60, DATEADD(MONTH, -2, GETDATE()) ),
        ( 1, 70, DATEADD(MONTH, -1, GETDATE()) ),
        ( 2, 10, DATEADD(MONTH, -7, GETDATE()) ),
        ( 2, 20, DATEADD(MONTH, -6, GETDATE()) ),
        ( 2, 30, DATEADD(MONTH, -5, GETDATE()) ),
        ( 2, 40, DATEADD(MONTH, -4, GETDATE()) ),
        ( 2, 50, DATEADD(MONTH, -3, GETDATE()) ),
        ( 2, 60, DATEADD(MONTH, -2, GETDATE()) ),
        ( 2, 70, DATEADD(MONTH, -1, GETDATE()) ),
        ( 3, 10, DATEADD(MONTH, -7, GETDATE()) ),
        ( 3, 20, DATEADD(MONTH, -6, GETDATE()) ),
        ( 3, 30, DATEADD(MONTH, -5, GETDATE()) ),
        ( 3, 40, DATEADD(MONTH, -4, GETDATE()) ),
        ( 3, 50, DATEADD(MONTH, -3, GETDATE()) ),
        ( 3, 60, DATEADD(MONTH, -2, GETDATE()) ),
        ( 3, 70, DATEADD(MONTH, -1, GETDATE()) )
		

SELECT  *
FROM    @Itens AS I
SELECT  *
FROM    @VendasItens AS CI


;
WITH    Dados
          AS ( SELECT   I.idTabela ,
                        I.NomeItem ,
                        CI.Valor ,
                        CI.Data ,
                        [OrdemVenda] = ROW_NUMBER() OVER ( PARTITION BY I.idTabela ORDER BY CI.Data )
               FROM     @Itens AS I
                        JOIN @VendasItens AS CI ON CI.IdItemComprado = I.idTabela
             )
    SELECT  R.idTabela ,
            R.NomeItem ,
            R.Valor ,
            R.Data ,
            R.[OrdemVenda]
    FROM    Dados R
    WHERE   R.OrdemVenda <= 3
    ORDER BY R.idTabela;


SELECT  I.idTabela ,
        I.NomeItem,
		Compras.IdItemComprado ,
        Compras.Valor ,
        Compras.Data
FROM    @Itens AS I
        CROSS APPLY ( SELECT TOP 3
                                CI.IdItemComprado ,
                                CI.Valor ,
                                CI.Data
                      FROM      @ComprasItens AS CI
                      WHERE     CI.IdItemComprado = I.idTabela
                      ORDER BY  CI.Data DESC
                    ) Compras
					ORDER BY I.idTabela


