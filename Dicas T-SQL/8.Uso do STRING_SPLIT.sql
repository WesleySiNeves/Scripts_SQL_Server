--Amigos,

--Estou tentando fazer um select  no sql server pra retornar os ids não encontrados na lista passada como parâmetro .

--Exemplo lista  ( 1,4,9,1000,2009 )  estes numero serão aleatórios.

--Preciso pesquisar na tabela item.codigo, e trazer os numero que não existam nesta tabela.

--Obrigado.

IF (OBJECT_ID('TEMPDB..#Demostracao') IS NOT NULL)
    DROP TABLE #Demostracao;

CREATE TABLE #Demostracao (
    Numero INT NOT NULL,
    Letra CHAR(1));

INSERT INTO #Demostracao (Numero,
                          Letra)
VALUES (1, CHAR(70)),
(4, CHAR(71)),
(9, CHAR(72)),
(10, CHAR(73));


DECLARE @Parametro VARCHAR(100) = '1,4,9,1000,2009';


--1º forma usando STRING_SPLIT (Sql server 2016)
--https://docs.microsoft.com/pt-br/sql/t-sql/functions/string-split-transact-sql
--Somente os que existem na tabela
SELECT D.Numero,
       D.Letra
  FROM #Demostracao AS D
  JOIN (SELECT value FROM STRING_SPLIT(@Parametro, ',')) AS Valores
    ON D.Numero = Valores.value;


	--Somente os que  não existem na tabela
SELECT D.Numero,
       D.Letra
  FROM #Demostracao AS D
  LEFT JOIN (SELECT value FROM STRING_SPLIT(@Parametro, ',')) AS Valores
    ON D.Numero = Valores.value
	WHERE Valores.value IS NULL





--2º Forma  Crie uma função para realizar o Split

SET QUOTED_IDENTIFIER ON
SET ANSI_NULLS ON
GO

CREATE FUNCTION [dbo].[SplitValues]
    (
      @texto VARCHAR(200) ,
      @delimiter NVARCHAR(5)
    )
RETURNS @Dados TABLE ( DATA VARCHAR(200) )
AS
    BEGIN
        DECLARE @valor VARCHAR(200) = LTRIM(RTRIM(@texto));
		
        DECLARE
            @prefixos NVARCHAR(MAX) ,
            @textXML XML;

        SELECT
            @prefixos = @valor;
        SELECT
            @textXML = CAST('<d>' + REPLACE(@prefixos, @delimiter, '</d><d>')
            + '</d>' AS XML);
        
        INSERT  INTO @Dados
                SELECT
                    X.DATA
                FROM
                    ( SELECT
                        T.split.value('.', 'nvarchar(max)') AS DATA
                      FROM
                        @textXML.nodes('/d') T ( SPLIT )
                    ) AS X;

        RETURN;
    END; 

--GO

--Somente os que existem
SELECT D.Numero,
       D.Letra
  FROM #Demostracao AS D
 JOIN dbo.SplitValues(@Parametro,',') AS SV ON D.Numero = SV.DATA

 --Somente os que não  existem
 SELECT D.Numero,
       D.Letra
  FROM #Demostracao AS D
 LEFT JOIN dbo.SplitValues(@Parametro,',') AS SV ON D.Numero = SV.DATA
 WHERE SV.DATA IS NULL;

 GO
 

 CREATE TYPE Codigos AS TABLE
 (
  Valor INT
 )

 DECLARE @Valores Codigos ;
 INSERT INTO @Valores (Valor)
 VALUES (1),(4),(9),(1000),(2009)

 SELECT * FROM @Valores AS V

 
--Somente os que existem
SELECT D.Numero,
       D.Letra
  FROM #Demostracao AS D
 JOIN @Valores AS SV ON D.Numero = SV.Valor


 --Somente os que não existem
SELECT D.Numero,
       D.Letra
  FROM #Demostracao AS D
 LEFT JOIN @Valores AS SV ON D.Numero = SV.Valor
 WHERE SV.Valor IS NULL

 GO

CREATE PROCEDURE BuscaDados (@Paramentros Codigos READONLY)
AS
BEGIN

    IF (OBJECT_ID('TEMPDB..#Demostracao') IS NOT NULL)
        DROP TABLE #Demostracao;

    CREATE TABLE #Demostracao (
        Numero INT NOT NULL,
        Letra CHAR(1));

    INSERT INTO #Demostracao (Numero,
                              Letra)
    VALUES (1, CHAR(70)),
    (4, CHAR(71)),
    (9, CHAR(72)),
    (10, CHAR(73));

    --Somente os que existem
    SELECT D.Numero,
           D.Letra
      FROM #Demostracao AS D
      JOIN @Paramentros AS SV
        ON D.Numero = SV.Valor


    --Somente os que não existem
    SELECT D.Numero,
           D.Letra
      FROM #Demostracao AS D
      LEFT JOIN @Paramentros AS SV
        ON D.Numero = SV.Valor
     WHERE SV.Valor IS NULL

END


DECLARE @Valores Codigos ;
 INSERT INTO @Valores (Valor)
 VALUES (1),(4),(9),(1000),(2009)

 EXEC dbo.BuscaDados @Paramentros = @Valores -- Codigos
 