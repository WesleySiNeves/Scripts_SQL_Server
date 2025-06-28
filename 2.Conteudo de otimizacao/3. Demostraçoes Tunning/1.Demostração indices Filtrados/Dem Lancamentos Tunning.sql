

--ALTER TABLE dbo.Lancamentos ADD CONSTRAINT PKLancamentos PRIMARY KEY(idLancamento)

--DROP INDEX [idxBanco] ON [dbo].[Lancamentos]

SELECT  L.idBanco, quantidade = COUNT(*) FROM  dbo.Lancamentos AS L
GROUP BY L.idBanco 


/*########################
# OBS: Nesse caso aqui faz Scan popis só temos um indice PK
*/
--Número de verificações 1, leituras lógicas 1293, leituras físicas 0
SET STATISTICS IO  ON 
SELECT * FROM  dbo.Lancamentos AS L
WHERE L.idBanco =1
SET STATISTICS IO  OFF


/*faz o Primeiro teste com um indice non Cluster*/

/*########################
# OBS: Passo 2 criando um indice incompleto
Nesse ponto estou criando um indice baseado no where sem a coluna historico
e a pergunta aqui e por que o sql serveer nao usou o indice 
*/
CREATE NONCLUSTERED INDEX idxBanco ON dbo.Lancamentos(idBanco) 
INCLUDE(IdCliente,NumeroLancamento,Data,Valor,Credito)


--Número de verificações 1, leituras lógicas 1293
SET STATISTICS IO  ON 
SELECT * FROM  dbo.Lancamentos AS L
WHERE L.idBanco =1
SET STATISTICS IO  OFF


--vamos ver qual e o custo se ele utilizasse o indice "correto"

--veja o preco do lookup para  retornar 5000 mil registros
--Tabela 'Lancamentos'. Número de verificações 1, leituras lógicas 153463, leituras físicas 2, leituras read-ahead 270,
SET STATISTICS IO  ON 
SELECT * FROM  dbo.Lancamentos AS L WITH(INDEX =idxBanco)
WHERE L.idBanco =1
SET STATISTICS IO  OFF


/*########################
Vamos dropar o indice para fazer de forma completa
# OBS:  Passo 3 Criando um indice completo
*/

DROP INDEX idxBanco ON dbo.Lancamentos

CREATE NONCLUSTERED INDEX idxBanco ON dbo.Lancamentos(idBanco) 
INCLUDE(IdCliente,NumeroLancamento,Data,Valor,Historico, Credito)


--vamos ver agora o custo
/*########################
# OBS:  veja que o Sql erver preferiu fazer 5000 mil seeks do que fazer 1 index scan
*/
--Tabela 'Lancamentos'. Número de verificações 1, leituras lógicas 632,
SET STATISTICS IO  ON 
SELECT * FROM  dbo.Lancamentos AS L
WHERE L.idBanco =1
SET STATISTICS IO  OFF

--Número de verificações 1, leituras lógicas 1293,
--fazendo o scan
SET STATISTICS IO  ON 
SELECT * FROM  dbo.Lancamentos AS L WITH(INDEX =PKLancamentos)
WHERE L.idBanco =1
SET STATISTICS IO  OFF



/*########################
#Passo 5) OBS: Agora vamos testar logica de proposicao (argumento de paramentro)
*/


/*########################
# OBS: Vejamos que foi feito seek
*/
DECLARE @banco INT = 2;

SET STATISTICS IO  ON 
SELECT * FROM  dbo.Lancamentos AS L 
WHERE 
L.idBanco =@banco
SET STATISTICS IO  OFF



/*########################
# OBS: Agora veja o que acontece com a proprosicao  OR
*/


DECLARE @banco INT = 1;

SET STATISTICS IO  ON 
SELECT * FROM  dbo.Lancamentos AS L 
WHERE 
(
@banco IS NULL OR  L.idBanco =@banco
)

SET STATISTICS IO  OFF


/*########################
# OBS: Veja o problema do operador OR
*/
--vamos alterar 99 % da tabela para o banco 2
UPDATE dbo.Lancamentos SET idBanco =2
WHERE idLancamento IN 
(
 SELECT  TOP 99 PERCENT L.idLancamento FROM dbo.Lancamentos AS L
 WHERE L.idBanco =1
)


--Agora so temos 5 registros
SELECT * FROM dbo.Lancamentos AS L
WHERE L.idBanco =1

GO

--Tabela 'Lancamentos'. Número de verificações 1, leituras lógicas 1293, leituras físicas 2,
DECLARE @banco INT = 1;


SET STATISTICS IO  ON 
SELECT * FROM  dbo.Lancamentos AS L 
WHERE 
(
 @banco IS NULL OR  L.idBanco =@banco
)


SET STATISTICS IO  ON 
--Veja a diferença
--Agora so temos 5 registros
SELECT * FROM dbo.Lancamentos AS L
WHERE L.idBanco =1
SET STATISTICS IO  OFF



--Solucao 1

/*########################
# OBS: Uso de query Dinamica
*/
DECLARE @query NVARCHAR(max);

DECLARE @banco INT = 1;

SET @query = CONCAT(   'SELECT * FROM dbo.Lancamentos AS L',
                       (CASE WHEN @banco IS NOT NULL 
					   THEN ' WHERE L.idBanco =' + CAST(@banco AS VARCHAR(10)) ELSE '' END
                       )
                   );

--SELECT @query;
--SELECT * FROM dbo.Lancamentos AS L WHERE L.idBanco =1
--SELECT * FROM dbo.Lancamentos AS L

--Rode com o plano de execucao  veja o uso de seek
EXEC (@query)



