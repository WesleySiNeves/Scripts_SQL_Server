 
DECLARE @TABELA TABLE (
	CODIGO	INT,
	CLIENTE	VARCHAR(25),
	PRODUTO VARCHAR(25)
);

-- Inserindo dados
INSERT INTO @TABELA VALUES(1,'JORGE','Piso');
INSERT INTO @TABELA VALUES(1,'JORGE','Porta');
INSERT INTO @TABELA VALUES(1,'JORGE','Torneira');

INSERT INTO @TABELA VALUES(2,'MARIA','Carriola');
INSERT INTO @TABELA VALUES(2,'MARIA','Torneira');



SELECT * FROM @TABELA AS T
-- Concatenando
SELECT  CODIGO,
		CLIENTE,
	COALESCE(
		(SELECT CAST(PRODUTO AS VARCHAR(10)) + ';' AS [text()]
		 FROM @TABELA AS O
		 WHERE O.CODIGO  = C.CODIGO
		 and   O.CLIENTE = C.CLIENTE
		 ORDER BY CODIGO
		 FOR XML PATH(''), TYPE).value('.[1]', 'VARCHAR(MAX)'), '') AS Produtos
FROM @TABELA AS C


SELECT CODIGO,CLIENTE
     , STRING_AGG(PRODUTO, ',') WITHIN GROUP (ORDER BY PRODUTO) AS FieldBs
  FROM @TABELA
   GROUP BY CODIGO,CLIENTE
 ORDER BY CODIGO;
 


 /* ==================================================================
 --Data: 18/09/2018 
 --Autor :Wesley Neves
 --Observação: Modo 3
  
 -- ==================================================================
 */

 DECLARE @textos TABLE (Coluna VARCHAR(200));

INSERT INTO @textos (
                    Coluna
                    )
VALUES (' [IdLiquidacao], [ValorPago]'),
(' [IdLiquidacao], [Valor]');


SELECT * FROM @textos AS T




SELECT string_agg(X.Conteudo, ',')
FROM (
     SELECT DISTINCT
         LE.Conteudo
     FROM (
	 SELECT B2.ColunaIncluida FROM BuscaChaves B2
 WHERE B2.TableName = R.TableName
	 ) AS T
          CROSS APPLY (
                      SELECT V.Conteudo
                      FROM Sistema.fnSplitValues(T.Coluna, ',') V
                      ) LE
     ) X


