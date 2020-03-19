-- ==================================================================
--se não existir cria a pk
-- ==================================================================
--ALTER TABLE dbo.Lancamentos ADD CONSTRAINT PKLancamentos PRIMARY KEY(idLancamento)


CREATE PROCEDURE BuscaLacancamentos(@ano INT)
AS 
BEGIN
		

		SELECT L.idLancamento,
               L.IdCliente,
               L.idBanco,
               L.Historico,
               L.NumeroLancamento,
               L.Data,
               L.Valor,
               L.Credito FROM dbo.Lancamentos AS L
		WHERE YEAR(L.Data) = @ano

END


EXEC dbo.BuscaLacancamentos @ano = 2016 -- int


-- ==================================================================
--Recupera do CACHE AS querys que geraram scan
--Observação:
-- ==================================================================
SELECT * FROM dbo.ScanInCacheFromDatabase('TSQL2017') AS SICFD
