SET STATISTICS IO ON;
SELECT *
FROM dbo.Lancamentos AS l
WHERE l.idLancamento IN ( --4436 faz seek 
						 --4437 faz scan
                            SELECT TOP 4436 l2.idLancamento FROM dbo.Lancamentos AS l2
                        );
SET STATISTICS IO OFF;