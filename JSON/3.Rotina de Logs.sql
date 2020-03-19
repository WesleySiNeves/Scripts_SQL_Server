


USE TSQLV4
DECLARE @json NVARCHAR(MAX)

SET @json='{"name":"John","surname":"Doe","age":45,"skills":["SQL","C#","MVC"]}';

SELECT *
FROM OPENJSON(@json);

GO


/* ==================================================================
--Data: 14/08/2018 
--Autor :Wesley Neves
--Observação:  Aqui temos um Valor JSON pronto para fazer uma função
 
-- ==================================================================
*/
SELECT L.idlog,
       L.Entidade,
       L.IdEntidade,
       L.Acao,
       Campo = X.[Key],
       Valor =  X.Value
     
FROM dbo.Logs AS L
    CROSS APPLY
(
    SELECT *
    FROM OPENJSON(
         (
             SELECT OJ.Value FROM OPENJSON(L.Valor) AS OJ
         )
                 ) B
) X;

