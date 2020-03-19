
/*
00000 rows affected)
Tabela 'Lancamentos'. N�mero de verifica��es 1, leituras l�gicas 1258, leituras f�sicas 0, leituras read-ahead 0, leituras l�gicas lob 0, leituras f�sicas lob 0, leituras read-ahead lob 0.
Tabela 'Clientes'. N�mero de verifica��es 1, leituras l�gicas 2, leituras f�sicas 0
*/
SET STATISTICS IO ON 
SELECT *
FROM dbo.Lancamentos AS L
    JOIN dbo.Clientes AS C
        ON C.IdCliente = L.IdCliente;



DECLARE @Cliente INT =1;
/*
(20081 rows affected)
Tabela 'Lancamentos'. N�mero de verifica��es 1, leituras l�gicas 1293,
*/
SELECT * FROM dbo.Lancamentos AS L
WHERE L.IdCliente =@Cliente


CREATE NONCLUSTERED INDEX idxClienteLancamentos
 ON dbo.Lancamentos(IdCliente) INCLUDE(idBanco,Historico,NumeroLancamento,Data,Valor,Credito)
WHERE IdCliente =1


GO


DECLARE @Cliente INT =1;
/*
Tabela 'Lancamentos'. N�mero de verifica��es 1, leituras l�gicas 254,
*/
SELECT * FROM dbo.Lancamentos AS L 
WHERE L.IdCliente =@Cliente OPTION(RECOMPILE)

GO


DECLARE @Cliente INT =1;
/*
Tabela 'Lancamentos'. N�mero de verifica��es 1, leituras l�gicas 254,
*/
SELECT * FROM dbo.Lancamentos AS L  WITH(INDEX =idxClienteLancamentos)
WHERE L.IdCliente =@Cliente OPTION(RECOMPILE)


