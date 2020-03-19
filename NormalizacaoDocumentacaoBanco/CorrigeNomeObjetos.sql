--USE Implanta

GO

/*Remove objetos do Hangfire antes, pra evitar problemas de nomes*/

GO

DECLARE
	@Schema VARCHAR(200),
	@Tabela VARCHAR(200),
	@Coluna VARCHAR(200),
	@Defaul VARCHAR(200),
	@Check VARCHAR(200),
	@SQL VARCHAR(MAX)
	 

DECLARE crTipoNumeric CURSOR FAST_FORWARD READ_ONLY FOR
	SELECT
		SCHEMA_NAME(t2.[schema_id]) AS [SCHEMA],
		OBJECT_NAME(C.[object_id]) AS Tabela,
		C.name AS Coluna,
		DC.name AS Tipo,
		CC.name
	FROM
		SYS.[columns] C
		JOIN SYS.tables t2 ON t2.[object_id] = C.[object_id]
		LEFT JOIN SYS.default_constraints dc ON dc.parent_object_id = t2.[object_id] AND dc.parent_column_id = c.column_id
		LEFT JOIN SYS.[check_constraints] cc ON cc.parent_object_id = t2.[object_id] AND cc.parent_column_id = c.column_id 
		JOIN SYS.types t ON t.system_type_id = c.system_type_id 
	WHERE
		t.name IN ('Decimal')
		AND C.is_computed = 0
	ORDER BY
		1, 2

OPEN crTipoNumeric

FETCH FROM crTipoNumeric INTO @Schema, @Tabela, @Coluna, @Defaul, @Check

WHILE @@FETCH_STATUS = 0
BEGIN
	IF @Defaul IS NOT NULL
		BEGIN
			SET @SQL = 'ALTER TABLE ' +  @Schema + '.' + @Tabela + ' DROP CONSTRAINT ' + @Defaul
			EXEC(@SQL)
		END
		
	IF @Check IS NOT NULL
		BEGIN
			SET @SQL = 'ALTER TABLE ' +  @Schema + '.' + @Tabela + ' DROP CONSTRAINT ' + @Check
			EXEC(@SQL)
		END		
		
	SET @SQL = 'ALTER TABLE '+ @Schema + '.' + @Tabela + ' ALTER COLUMN ' + @Coluna + ' NUMERIC(18, 2) NOT NULL'
	EXEC(@SQL)
	
	SET @SQL = 'ALTER TABLE '+ @Schema + '.' + @Tabela + ' ADD CONSTRAINT DEF_' + @Schema + @Tabela + @Coluna + ' DEFAULT 0 FOR ['+ @Coluna +']'
	EXEC(@SQL)

	FETCH FROM crTipoNumeric INTO @Schema, @Tabela, @Coluna, @Defaul, @Check
END

CLOSE crTipoNumeric
DEALLOCATE crTipoNumeric



DECLARE crTipoNumeric2 CURSOR FAST_FORWARD READ_ONLY FOR
	SELECT
		SCHEMA_NAME(t2.[schema_id]) AS [SCHEMA],
		OBJECT_NAME(C.[object_id]) AS Tabela,
		C.name AS Coluna,
		DC.name AS Padrao,
		CC.name AS Ceck
	FROM
		SYS.[columns] C
		JOIN SYS.tables t2 ON t2.[object_id] = C.[object_id]
		LEFT JOIN SYS.default_constraints dc ON dc.parent_object_id = t2.[object_id] AND dc.parent_column_id = c.column_id
		LEFT JOIN SYS.[check_constraints] cc ON cc.parent_object_id = t2.[object_id] AND cc.parent_column_id = c.column_id 
		JOIN SYS.types t ON t.system_type_id = c.system_type_id 
	WHERE
		t.name IN ('Numeric')
		AND C.is_computed = 0
		AND (DC.name IS NULL OR CC.name IS NULL)
	ORDER BY
		1, 2

OPEN crTipoNumeric2

FETCH FROM crTipoNumeric2 INTO @Schema, @Tabela, @Coluna, @Defaul, @Check

WHILE @@FETCH_STATUS = 0
BEGIN
	IF @Defaul IS NULL
		BEGIN
			SET @SQL = 'ALTER TABLE '+ @Schema + '.' + @Tabela + ' ADD CONSTRAINT DEF_' + @Schema + @Tabela + @Coluna + ' DEFAULT 0 FOR ['+ @Coluna +']'
			EXEC(@SQL)	
		END	
	
	
	FETCH FROM crTipoNumeric2 INTO @Schema, @Tabela, @Coluna, @Defaul, @Check
END

CLOSE crTipoNumeric2
DEALLOCATE crTipoNumeric2

IF OBJECT_ID('dbo.ufnColunaIndice') IS NOT NULL
	DROP FUNCTION dbo.ufnColunaIndice

GO

CREATE FUNCTION ufnColunaIndice(@Indice VARCHAR(1000))
	RETURNS VARCHAR(2000)
AS
BEGIN 
	DECLARE
		@Coluna VARCHAR(300)
		
	SELECT
		@Coluna = ISNULL(@Coluna, '') + C.name
	FROM
		SYS.TABLES T
		JOIN SYS.SCHEMAS S ON S.SCHEMA_ID = T.SCHEMA_ID
		JOIN SYS.INDEXES I ON T.OBJECT_ID = I.OBJECT_ID
		JOIN SYS.INDEX_COLUMNS IC ON I.OBJECT_ID = IC.OBJECT_ID AND I.INDEX_ID = IC.INDEX_ID
		JOIN SYS.COLUMNS C ON IC.OBJECT_ID = C.OBJECT_ID AND IC.COLUMN_ID = C.COLUMN_ID
	WHERE
		I.name = @Indice
	ORDER BY
		C.column_id
		
	RETURN @Coluna
END

GO

IF OBJECT_ID('TEMPDB..#COMANDO') IS NOT NULL
	DROP TABLE #COMANDO
		
GO

CREATE TABLE #COMANDO
(
	CMD VARCHAR(MAX)	
)

INSERT INTO #COMANDO
	SELECT
		'EXEC sp_rename N''[' + X.SchemaNome + '].[' + X.Nome + ']'', N''' + X.NomeCorreto + ''', N''OBJECT'''
	FROM
		(	SELECT
				s.name AS SchemaNome,
				'PK_' + s.name + t.name AS NomeCorreto,
				i.name AS Nome
			FROM
				sys.tables t
				JOIN sys.schemas s ON s.schema_id = t.schema_id
				JOIN sys.indexes i ON t.object_id = i.object_id
				JOIN sys.index_columns ic ON i.object_id = ic.object_id AND i.index_id = ic.index_id
				JOIN sys.columns c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
			WHERE
				is_primary_key = 1) X
	WHERE
		X.NomeCorreto <> X.Nome
		
	UNION ALL
	
	SELECT
		'EXEC sp_rename N''[' + X.SchemaNome + '].[' + X.Nome + ']'', N''' + X.NomeCorreto + ''', N''OBJECT'''
	FROM
		(	SELECT
				SCHEMA_NAME(T.[schema_id]) AS SchemaNome,
				'DEF_' + SCHEMA_NAME(T.[schema_id]) + T.name + C.name AS NomeCorreto,
				O.name AS Nome
			FROM
				SYS.TABLES T
				JOIN SYS.COLUMNS C ON T.OBJECT_ID = C.OBJECT_ID
				JOIN SYS.OBJECTS O ON C.DEFAULT_OBJECT_ID = O.[OBJECT_ID]) X
	WHERE
		X.NomeCorreto <> X.Nome
	
	UNION ALL
	
	SELECT
		'EXEC sp_rename N''[' + X.SchemaNome + '].[' + X.Nome + ']'', N''' + X.NomeCorreto + ''', N''OBJECT'''
	FROM
		(	SELECT
				S.NAME AS SchemaNome,
				'UNQ_' + S.NAME + T.NAME + dbo.ufnColunaIndice(I.name) AS NomeCorreto,
				I.NAME AS NOME
			FROM
				SYS.TABLES T
				JOIN SYS.SCHEMAS S ON S.SCHEMA_ID = T.SCHEMA_ID
				JOIN SYS.INDEXES I ON T.OBJECT_ID = I.OBJECT_ID
			WHERE
				I.IS_UNIQUE_CONSTRAINT = 1) X
	WHERE
		X.NomeCorreto <> X.NOME
		
	UNION ALL
	
	SELECT
		'EXEC sp_rename N''[' + X.SchemaNome + '].[' + X.Nome + ']'', N''' + X.NomeCorreto + ''', N''OBJECT'''
	FROM
		(	SELECT
				fks.name AS SchemaNome,
				'FK_' + fkt.name + pc.name + '_' + rct.name + rc.name    AS NomeCorreto,
				fko.name AS Nome
			FROM
				sys.foreign_key_columns fk
				JOIN sys.columns pc ON fk.parent_object_id = pc.object_id AND fk.parent_column_id = pc.column_id
				JOIN sys.objects fkt ON pc.object_id = fkt.object_id
				JOIN sys.schemas AS fks ON fks.schema_id = fkt.schema_id
				JOIN sys.columns rc ON fk.referenced_object_id = rc.object_id AND fk.referenced_column_id = rc.column_id
				JOIN sys.objects rct ON rc.object_id = rct.object_id
				JOIN sys.schemas AS rcs ON rcs.schema_id = rct.schema_id
				JOIN sys.objects fko ON fk.constraint_object_id = fko.object_id) X
	WHERE
		X.NomeCorreto <> X.Nome
		
	UNION ALL
	
	SELECT
		'EXEC sp_rename N''[' + X.SchemaNome + '].[' + X.Nome + ']'', N''' + X.NomeCorreto + ''', N''OBJECT'''
	FROM
		(SELECT
			'CHECK_' + SCHEMA_NAME(CC.[schema_id]) + T.name + C.name AS NomeCorreto,
			CC.name AS Nome,
			SCHEMA_NAME(CC.[schema_id]) AS SchemaNome 	
		FROM
			SYS.[CHECK_CONSTRAINTS] CC
			JOIN SYS.TABLES T ON T.[OBJECT_ID] = CC.PARENT_OBJECT_ID
			JOIN SYS.[COLUMNS] C ON C.[OBJECT_ID] = T.[OBJECT_ID] AND C.COLUMN_ID = CC.PARENT_COLUMN_ID) X

	WHERE
		X.Nome <> X.NomeCorreto
		
	UNION ALL
	
	SELECT
		'ALTER TABLE ' + SCHEMA_NAME(T.[schema_id]) + '.' + T.NAME + ' ALTER COLUMN ' + CL.NAME + ' ADD ROWGUIDCOL'
	FROM
		SYS.INDEXES I
		JOIN SYS.INDEX_COLUMNS IC ON IC.INDEX_ID = I.INDEX_ID AND IC.[OBJECT_ID] = I.[OBJECT_ID]
		JOIN SYS.[COLUMNS] CL ON CL.[OBJECT_ID] = IC.[OBJECT_ID] AND CL.COLUMN_ID = IC.COLUMN_ID
		JOIN SYS.TABLES T ON T.[OBJECT_ID] = CL.[OBJECT_ID]
	WHERE
		I.IS_PRIMARY_KEY = 1
		AND CL.IS_ROWGUIDCOL = 0
		AND SCHEMA_NAME(T.[schema_id]) <> 'dbo' AND SCHEMA_NAME(T.[schema_id]) <> 'HangFire'
		
	--UNION ALL
	
	--SELECT
	--	'ALTER TABLE ' + SCHEMA_NAME(T.[SCHEMA_ID]) + '.' + T.NAME + ' ADD CONSTRAINT UNQ_' + SCHEMA_NAME(T.[SCHEMA_ID]) + T.NAME + dbo.ufnColunaIndice(I.name) + ' UNIQUE (' + CL.NAME  + ')'
	--FROM
	--	SYS.INDEXES I
	--	JOIN SYS.INDEX_COLUMNS IC ON IC.INDEX_ID = I.INDEX_ID AND IC.[OBJECT_ID] = I.[OBJECT_ID]
	--	JOIN SYS.[COLUMNS] CL ON CL.[OBJECT_ID] = IC.[OBJECT_ID] AND CL.COLUMN_ID = IC.COLUMN_ID
	--	JOIN SYS.TABLES T ON T.[OBJECT_ID] = CL.[OBJECT_ID]
	--WHERE
	--	I.IS_PRIMARY_KEY = 1
	--	AND SCHEMA_NAME(T.[SCHEMA_ID]) <> 'DBO' AND SCHEMA_NAME(T.[schema_id]) <> 'HangFire'
	--	AND CL.DEFAULT_OBJECT_ID = 0 
		
DECLARE
	@CMD VARCHAR(MAX) 

DECLARE crObjetos CURSOR FAST_FORWARD READ_ONLY FOR
	SELECT
		CMD
	FROM
		#COMANDO

OPEN crObjetos

FETCH FROM crObjetos INTO @CMD

WHILE @@FETCH_STATUS = 0
BEGIN
	EXEC(@CMD)

	FETCH FROM crObjetos INTO @CMD
END

CLOSE crObjetos
DEALLOCATE crObjetos

GO

IF OBJECT_ID('dbo.ufnColunaIndice') IS NOT NULL
	DROP FUNCTION dbo.ufnColunaIndice
