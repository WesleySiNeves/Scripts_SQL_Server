 

DECLARE @ContasBancarias TABLE
    (
      id INT NOT NULL PRIMARY KEY ( id )
             IDENTITY(1, 1) ,
      Nome VARCHAR(100)
    );
INSERT  INTO @ContasBancarias
        ( Nome )
VALUES  ( 'Banco Alfa S.A' ),
        ( 'Banco Alvorada S.A.' ),
        ( 'Banco Banerj S.A.' ),
        ( 'Banco BBM S.A.' ),
        ( 'Banco Beg S.A.' ),
        ( 'Banco BGN S.A.' ),
        ( 'Banco Bracce S.A.' ),
        ( 'Banco Bradesco S.A.' ),
        ( 'Banco Brascan S.A.' ),
        ( 'Banco Cacique S.A.' ),
        ( 'Banco Caixa Geral - Brasil S.A.' ),
        ( 'Banco Citibank S.A.' ),
        ( 'Banco Comercial e de Investimento Sudameris S.A.' ),
        ( 'Banco Credit Suisse (Brasil) S.A.' ),
        ( 'Banco Cruzeiro do Sul S.A.' ),
        ( 'Banco da Amazônia S.A.' ),
        ( 'Banco Daycoval S.A.' ),
        ( 'Banco do Brasil S.A.' ),
        ( 'Banco do Estado de Sergipe S.A.' ),
        ( 'Banco do Estado do Pará S.A.' ),
        ( 'Banco do Estado do Rio Grande do Sul S.A.' ),
        ( 'Banco Fator S.A.' ),
        ( 'Banco GE Capital S.A.' );

DECLARE @FiltroBancos TABLE ( Nome VARCHAR(100) );
INSERT  INTO @FiltroBancos
        ( Nome )
VALUES  ( '%Capital%' ),
        ( '%Fator%' ),
        ( '%Sul%' ),
        ( '%Amazônia%' );


SELECT  C.id ,
        C.Nome
FROM    @ContasBancarias C
        INNER JOIN ( SELECT FB.Nome
                     FROM   @FiltroBancos AS FB
                   ) Filtro ON C.Nome LIKE Filtro.Nome;