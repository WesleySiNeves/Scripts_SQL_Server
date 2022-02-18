/*master : http://www.dbinternals.com.br/?p=1223*/

--CREATE DATABASE [db_SandBox]
USE [db_SandBox]
 
GO
IF EXISTS (SELECT *
             FROM [sys].[tables]
            WHERE [name] = 'tb_Imovel') 
    BEGIN
        DROP TABLE [tb_Imovel];
    END;
 
CREATE TABLE [dbo].[tb_Imovel]
([cod_Imovel]        [INT] NULL,
 [val_Imovel]        DECIMAL(30, 5) NULL,
 [val_Area]          DECIMAL(30, 5) NULL,
 [val_IdadeAparente] [INT] NULL,
 [num_Andar]         [INT] NULL,
 [qtd_Suites]        [INT] NULL,
 [ind_Vista]         [INT] NULL,
 [val_Distbm]        [INT] NULL,
 [ind_Semruido]      [INT] NULL,
 [ind_AV200m]        [INT] NULL
)
ON [primary];
 
GO



BULK INSERT tb_Imovel FROM 'D:\2.TreinamentoSQLServer2016\Medias de tendencias Centrais em Tsql\Arquivo_Valorizacao_Ambiental.csv' WITH(FIELDTERMINATOR = ',', ROWTERMINATOR = '\n', FIRSTROW = 2);

SELECT * FROM tb_Imovel

/* ==================================================================
--Data: 17/10/2018 
--Autor :Wesley Neves
--Observa��o:
 M�dia Aritim�tica � Se n n�mero dados, 
 cada n�mero denotado por xi, onde i = 1, �, n, a m�dia aritm�tica � a soma dos valores xi�s divididos por n.
 
-- ==================================================================
*/

--M�dia aritm�tica
SELECT SUM(tb_Imovel.val_Imovel) / COUNT(tb_Imovel.cod_Imovel) AS val_MediaAritimetica,
       AVG(tb_Imovel.val_Imovel) AS val_AVG
FROM [tb_Imovel];


/* ==================================================================
--Data: 17/10/2018 
--Autor :Wesley Neves
--Observa��o: M�dia Geom�trica � A m�dia geom�trica de
 n n�meros � obtida pela multiplica��o de todos juntos e ent�o calcula-se a n-�sima raiz desse produto
 
-- ==================================================================
*/

--M�dia geom�trica
SELECT POWER(EXP(SUM(LOG(ABS([val_Imovel])))), (1.0000 / COUNT(cod_Imovel))) as val_MediaGeometrica
  FROM [tb_Imovel];


/* ==================================================================
--Data: 17/10/2018 
--Autor :Wesley Neves
--Observa��o: M�dia Harm�nica � A m�dia harm�nica 
para um conjunto de n�meros a1, a2, �, an � definida como a rec�proca da m�dia aritm�tica para os valores �ai�s.
 
-- ==================================================================
*/

--M�dia harm�nica
SELECT COUNT(cod_Imovel) / SUM(1 / [val_Imovel]) as val_MediaHarmonica
  FROM [tb_Imovel];

/* ==================================================================
--Data: 17/10/2018 
--Autor :Wesley Neves
--Observa��o: M�dia Heroniana
 
-- ==================================================================
*/
--M�dia heroniana entre 12 e 3
DECLARE @val_A DECIMAL(30, 6);
DECLARE @val_B DECIMAL(30, 6);

SET @val_A = 12;
SET @val_B = 3;

SELECT CAST(2 AS DECIMAL(30, 6)) / CAST(3 AS DECIMAL(30, 6))
       * CAST(((@val_A + @val_B) / CAST(2 AS DECIMAL(30, 6))) AS DECIMAL(30, 6)) + CAST(1 AS DECIMAL(30, 6))
       / CAST(3 AS DECIMAL(30, 6)) * CAST(SQRT(@val_A * @val_B) AS DECIMAL(30, 6)) AS val_MediaHarmonica;


/* ==================================================================
--Data: 17/10/2018 
--Autor :Wesley Neves
--Observa��o: M�dia Ponderada � 
� o Quociente da soma dos produtos desses n�meros pela soma dos respectivos pesos.
 
-- ==================================================================
*/



DROP TABLE IF EXISTS [#tb_MediaPonderada]
GO
CREATE TABLE [#tb_MediaPonderada]
([val_Valor] DECIMAL(30, 6),
 [val_Peso]  DECIMAL(30, 6)
);
 
 
INSERT INTO [#tb_MediaPonderada] VALUES
(7, 1),
(6, 2),
(8, 3),
(7.5, 4),
(4, 2),
(3, 1)
 
SELECT SUM([val_Valor] * [val_Peso]) / SUM([val_Peso]) as val_MediaPonderada
  FROM [#tb_MediaPonderada];

/* ==================================================================
--Data: 17/10/2018 
--Autor :Wesley Neves
--Observa��o: M�dia Quadr�tica � A m�dia quadr�tica de um
 conjunto finito de n�meros reais x_1, x_2, \ldots x_n\, � definida como
  a raiz quadrada da m�dia aritm�tica dos quadrados dos elementos.
 
-- ==================================================================
*/

SELECT SQRT(SUM(POWER(tb_Imovel.val_Imovel, 2)) / COUNT(tb_Imovel.cod_Imovel)) AS [val_MediaQuadratica]
FROM [tb_Imovel];

/* ==================================================================
--Data: 17/10/2018 
--Autor :Wesley Neves
--Observa��o: Mediana � Mediana � o valor num�rico que separa a metade superior de uma amostra de dados, popula��o ou distribui��o de probabilidade, 
em Rol ordenado de forma crescente ou decrescente, a partir da metade inferior.
 
-- ==================================================================
*/


--Mediana
WITH cte_Mediana
  AS (SELECT A.val_Imovel,
             [val_Linha] = ROW_NUMBER() OVER (ORDER BY
                                                  A.val_Imovel
                                             ),
             B.val_Count
      FROM [tb_Imovel] AS [A]
           CROSS JOIN (
                      SELECT [val_Count] = COUNT(*)
                      FROM [tb_Imovel]
                      ) AS [B]
     )
SELECT AVG(1.0 * cte_Mediana.val_Imovel) AS [val_Mediana]
FROM [cte_Mediana]
WHERE cte_Mediana.val_Linha IN (([val_Count] + 1) / 2, ([val_Count] + 2) / 2 );


	/*Implanta :  Outra forma de fazer*/
	SELECT DISTINCT
		PERCENTILE_CONT(0.5) WITHIN GROUP(
	ORDER BY
		tb_Imovel.val_Imovel) OVER () AS [val_Mediana]
	FROM [tb_Imovel];



;WITH Dados AS (
SELECT TI.cod_Imovel,
		Rn = ROW_NUMBER()OVER(ORDER BY TI.val_Imovel),
       TI.val_Imovel
FROM dbo.tb_Imovel AS TI

),
MaxNumber AS (
SELECT R.cod_Imovel,
       R.Rn,
       R.val_Imovel,
	   MaxNumber = MAX(R.Rn)OVER(),
	   IsPar = IIF(COUNT(Rn) OVER() % 2 =0,1,0)
	    FROM Dados R
)
SELECT R.cod_Imovel,
       R.Rn,
       R.val_Imovel,
       R.MaxNumber,
       R.IsPar FROM MaxNumber R
ORDER BY  R.val_Imovel


/* ==================================================================
--Data: 17/10/2018 
--Autor :Wesley Neves
--Observa��o: Moda � Moda � o valor que det�m o maior n�mero de observa��es, ou seja, 
 �o valor que ocorre com maior frequ�ncia num conjunto de dados, isto �, o valor mais comum�.
 
-- ==================================================================
*/

--Moda
WITH cte_Moda
  AS (SELECT TOP 1
          tb_Imovel.val_Imovel,
          COUNT(tb_Imovel.val_Imovel) AS [val_Count]
      FROM [tb_Imovel]
      GROUP BY
          tb_Imovel.val_Imovel
      HAVING COUNT(tb_Imovel.val_Imovel) > 1
      ORDER BY
          COUNT(tb_Imovel.val_Imovel) DESC
     )
SELECT cte_Moda.val_Imovel AS val_Moda
FROM [cte_Moda];


;WITH NovaFormaCalcularModa AS (
SELECT TI.cod_Imovel,
       TI.val_Imovel,
       COUNT(TI.val_Imovel) OVER (PARTITION BY TI.val_Imovel) AS Total
FROM dbo.tb_Imovel AS TI
)

SELECT TOP 1 R.val_Imovel AS Moda FROM NovaFormaCalcularModa R
ORDER BY R.Total DESC

GO


/* ==================================================================
--Data: 17/10/2018 
--Autor :Wesley Neves
--Observa��o: Desvio Padr�o � desvio padr�o � a medida mais comum da dispers�o estat�stica (representado pelo s�mbolo sigma, ?). Ele mostra o quanto de varia��o ou �dispers�o� existe em rela��o � m�dia (ou valor esperado). Um baixo desvio padr�o indica que os dados tendem a estar pr�ximos da m�dia; um desvio padr�o alto indica que os dados est�o espalhados por uma gama de valores.
 
-- ==================================================================
*/

WITH cte_Valores
  AS (SELECT ROUND(SQRT(SUM(A.val_X) / (COUNT(A.val_X) - 1)), 3) AS [val_DesvioPadrao],
             SUM(A.val_X) / (COUNT(A.val_X) - 1) AS [val_Variancia],
             AVG(A.val_Imovel) AS [val_Media]
      FROM (
           SELECT POWER((AVG(tb_Imovel.val_Imovel) OVER (PARTITION BY 1) - tb_Imovel.val_Imovel), 2) AS [val_X],
                  tb_Imovel.val_Imovel
           FROM dbo.tb_Imovel
           ) AS [A]
     )
SELECT cte_Valores.val_DesvioPadrao,
       cte_Valores.val_Variancia,
       (cte_Valores.val_DesvioPadrao * 3) + cte_Valores.val_Media AS [val_LimiteSuperior],
       (cte_Valores.val_DesvioPadrao * 3) - cte_Valores.val_Media AS [val_LimiteInferior]
FROM [cte_Valores];