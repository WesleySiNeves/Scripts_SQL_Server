
--USE Implanta



WITH Dados AS (
SELECT  rn = ROW_NUMBER() OVER(PARTITION BY T.SchemaName,
 T.TableName, T.Create_Statement ORDER BY T.Create_Statement ),
       T.Create_Statement FROM  dbo.temp AS T


)
DELETE Dados WHERE Dados.rn > 1

--INSERT INTO dbo.Resultado 
--SELECT * FROM dbo.temp AS T
--WHERE T.Create_Statement IN 
--(
--SELECT T.Create_Statement FROM  dbo.temp AS T
--EXCEPT
--SELECT R.Create_Statement FROM  dbo.Resultado AS R
--)

