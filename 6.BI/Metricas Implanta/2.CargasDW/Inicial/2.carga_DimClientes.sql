
DELETE FROM  Shared.DimClientes;


;WITH Dados
AS (SELECT cli.IdCliente,
           fed.SkConselhoFederal,
           REPLACE(REPLACE(REPLACE(cli.Nome, 'Cons.', 'Conselho'), 'Eng.', 'Engenharia'), 'Reg.', 'Regional') AS Nome,
           cli.SiglaConselhoRegional
    FROM Implanta.Clientes cli
        LEFT JOIN Shared.DimConselhosFederais fed
            ON fed.IdConselhoFederal = cli.IdConselhoFederal
--WHERE cli.SiglaConselhoRegional ='CONRE/DF'

),
      EnrriquecerDados
AS (SELECT R.IdCliente,
           R.SkConselhoFederal,
           R.SiglaConselhoRegional,
           REPLACE(R.Nome, 'Reg de', 'Regional de') AS Nome,
           UF = CASE
                    WHEN CHARINDEX('/', R.SiglaConselhoRegional) > 0
                         AND SUBSTRING(R.SiglaConselhoRegional, CHARINDEX('/', R.SiglaConselhoRegional) + 1)NOT LIKE '%BR%' THEN
                        SUBSTRING(R.SiglaConselhoRegional, CHARINDEX('/', R.SiglaConselhoRegional) + 1)
                    WHEN R.Nome LIKE '%Conselho Federal%'
                         OR R.Nome LIKE '%Brasil%'
                         OR R.Nome LIKE '%Nacional%' THEN
                        'BR'
                    ELSE
                        'NA'
                END,
           TipoCliente = CASE
                             WHEN TRIM(R.Nome) LIKE '%Conselho%' THEN
                                 'Conselho'
                             WHEN TRIM(R.Nome) LIKE '%Associação%' THEN
                                 'Associação'
                             WHEN TRIM(R.Nome) LIKE '%Cooperativa%' THEN
                                 'Cooperativa'
                             WHEN TRIM(R.Nome) LIKE '%Prefeitura%' THEN
                                 'Prefeitura'
                             WHEN TRIM(R.Nome) LIKE '%ORDEM%'
                                  OR R.Nome LIKE '%Advogado%' THEN
                                 'ORDEM'
                             WHEN TRIM(R.Nome) LIKE '%serviços%' THEN
                                 'serviços sociais autônomos'
                             ELSE
                                 'NA'
                         END



    FROM Dados R)

	INSERT INTO Shared.DimClientes
	(
	    IdCliente,
	    SkConselhoFederal,
	    Nome,
	    Sigla,
	    Estado,
	    TipoCliente
	   
	)

SELECT R.IdCliente,
       R.SkConselhoFederal,
       R.Nome,
	   R.SiglaConselhoRegional,
       R.UF,
       R.TipoCliente
FROM EnrriquecerDados R

ORDER BY R.SiglaConselhoRegional;


