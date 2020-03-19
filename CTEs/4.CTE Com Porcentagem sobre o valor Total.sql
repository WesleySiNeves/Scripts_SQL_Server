

DECLARE @Produtos TABLE
    (
      IdProduto INT ,
      Nome VARCHAR(50)
    );
DECLARE @Lancamentos TABLE
    (
      IdProduto INT ,
      Valor DECIMAL(18, 2)
    );
INSERT INTO @Produtos
        ( IdProduto, Nome )
    VALUES ( 1, 'Camiseta Azul' );


INSERT INTO @Lancamentos
        ( IdProduto, Valor )
    VALUES  ( 1, 10 ) ,
            ( 1, 20 ),
            ( 1, 10 ),
            ( 1, 30 ),
            ( 1, 40 ),
            ( 1, 50 );

WITH Dados AS (
SELECT L.IdProduto ,
        P.Nome ,
        [Valor Unitario] = L.Valor ,
        [Total Lancamentos] = SUM(L.Valor) OVER ( ) ,
        QuantidadeLancamentos = COUNT(L.IdProduto) OVER ( PARTITION BY L.IdProduto )
    FROM @Produtos AS P
    JOIN @Lancamentos AS L ON L.IdProduto = P.IdProduto
	),
	DadosEmPorcentagem AS (

	SELECT R.IdProduto ,
           R.Nome ,
           R.[Valor Unitario] ,
		   [Porcentagem Unitario]=  CAST ( ((R.[Valor Unitario] / R.[Total Lancamentos]) * 100) AS  DECIMAL(18,2)) ,
           R.[Total Lancamentos] ,
           R.QuantidadeLancamentos FROM Dados R
		   )

		   SELECT R.IdProduto ,
                  R.Nome ,
                  R.[Valor Unitario] ,
                  R.[Porcentagem Unitario] ,
                  R.[Total Lancamentos] ,
				  [Total Porcentagem] = SUM(R.[Porcentagem Unitario]) OVER (),
                  R.QuantidadeLancamentos FROM DadosEmPorcentagem R