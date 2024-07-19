
/*
00000 rows affected)
Tabela 'Lancamentos'. Número de verificações 1, leituras lógicas 1258, leituras físicas 0, leituras read-ahead 0, leituras lógicas lob 0, leituras físicas lob 0, leituras read-ahead lob 0.
Tabela 'Clientes'. Número de verificações 1, leituras lógicas 2, leituras físicas 0
*/
SET STATISTICS IO ON 
SELECT *
FROM dbo.Lancamentos AS L
    JOIN dbo.Clientes AS C
        ON C.IdCliente = L.IdCliente;



DECLARE @Cliente INT =1;
/*
(20081 rows affected)
Tabela 'Lancamentos'. Número de verificações 1, leituras lógicas 1293,
*/
SELECT * FROM dbo.Lancamentos AS L
WHERE L.IdCliente =@Cliente


CREATE NONCLUSTERED INDEX idxClienteLancamentos
 ON dbo.Lancamentos(IdCliente) INCLUDE(idBanco,Historico,NumeroLancamento,Data,Valor,Credito)
WHERE IdCliente =1


GO


DECLARE @Cliente INT =1;
/*
Tabela 'Lancamentos'. Número de verificações 1, leituras lógicas 254,
*/
SELECT * FROM dbo.Lancamentos AS L 
WHERE L.IdCliente =@Cliente OPTION(RECOMPILE)

GO


DECLARE @Cliente INT =1;
/*
Tabela 'Lancamentos'. Número de verificações 1, leituras lógicas 254,
*/
SELECT * FROM dbo.Lancamentos AS L  WITH(INDEX =idxClienteLancamentos)
WHERE L.IdCliente =@Cliente OPTION(RECOMPILE)


