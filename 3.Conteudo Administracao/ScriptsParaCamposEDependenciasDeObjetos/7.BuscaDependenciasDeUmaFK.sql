

DECLARE @NomeProriedade VARCHAR(MAX) = 'IdEmpenho';

SELECT DISTINCT
        sysobjects.name AS Tabela ,
        syscolumns.name AS Coluna
FROM    sys.sysobjects
        INNER JOIN sys.syscolumns ON sysobjects.id = syscolumns.id
WHERE   syscolumns.name = @NomeProriedade
ORDER BY sysobjects.name ,
        syscolumns.name;
	
	
