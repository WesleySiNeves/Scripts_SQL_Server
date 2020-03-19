DECLARE @Campo VARCHAR(100) = 'datetime';

IF (OBJECT_ID('TEMPDB..#DadosTabela') IS NOT NULL)
    DROP TABLE #DadosTabela;



	IF ( OBJECT_ID('TEMPDB..#ScriptsGerados') IS NOT NULL )
	    DROP TABLE #ScriptsGerados;	
	
	CREATE TABLE #ScriptsGerados
	    (
	      ObjectId INT NOT NULL ,
	      [Schema] VARCHAR(128) NULL ,
	      Tabela VARCHAR(128)  ,
	      Script VARCHAR(MAX) ,
	      
	    );

CREATE TABLE #DadosTabela (
    [object_id] INT,
    [Schema] NVARCHAR(128),
    [name] NVARCHAR(128),
    [schema_id] INT,
    [type] CHAR(2),
    [type_desc] NVARCHAR(60),
    [durability_desc] NVARCHAR(60),
    [temporal_type] TINYINT,
    [temporal_type_desc] NVARCHAR(60));


IF (OBJECT_ID('TEMPDB..#DadosColunas') IS NOT NULL)
    DROP TABLE #DadosColunas;

CREATE TABLE #DadosColunas (
    [object_id] INT,
    [Tabela] NVARCHAR(128),
    [Coluna] NVARCHAR(128),
    [column_id] INT,
    [user_type_id] INT,
    [max_length] SMALLINT,
    [precision] TINYINT,
    [Type] NVARCHAR(128),
    [scale] TINYINT,
    [is_nullable] BIT,
    [is_identity] BIT,
    [is_computed] BIT,
    [is_filestream] BIT);



WITH DadosTabela
  AS (SELECT T.object_id,
             [Schema] = S.name,
             T.name,
             T.schema_id,
             T.type,
             T.type_desc,
             T.durability_desc,
             T.temporal_type,
             T.temporal_type_desc
        FROM sys.tables AS T
        JOIN sys.schemas AS S
          ON T.schema_id = S.schema_id)
INSERT INTO #DadosTabela
SELECT *
  FROM DadosTabela AS DT;


  -- ==================================================================
  --Observação: Recupera dados das tabelas que tem registros
  /* 
   */
  -- ==================================================================
INSERT INTO #DadosColunas
SELECT T.object_id,
       [Tabela] = T.name,
       [Coluna] = C.name,
       C.column_id,
       C.user_type_id,
       C.max_length,
       C.precision,
       [Type] = T2.name,
       C.scale,
       C.is_nullable,
       C.is_identity,
       C.is_computed,
       C.is_filestream
  FROM sys.tables AS T
  JOIN sys.columns AS C
    ON T.object_id    = C.object_id
  JOIN sys.types AS T2 ON C.user_type_id = T2.user_type_id
  JOIN 
  (
  SELECT I.object_id, S.rowcnt FROM sys.indexes AS I
	JOIN sys.sysindexes AS S ON  I.object_id = S.id
	WHERE 
	S.indid =1
  ) Quanti ON T.object_id = Quanti.object_id
  AND Quanti.rowcnt >0


	

SELECT DC.object_id,
       DT.[Schema],
       DC.Tabela,
       DC.Coluna,
       DC.column_id,
       DC.user_type_id,
       DC.max_length,
       DC.precision,
       DC.Type,
       DC.scale,
       DC.is_nullable,
       DC.is_identity,
       DC.is_computed,
       DC.is_filestream
  FROM #DadosTabela AS DT
  JOIN #DadosColunas AS DC
    ON DT.object_id = DC.object_id
 WHERE DC.Type = @Campo
 ORDER BY DT.[Schema],
          DT.name;



/* declare variables */
DECLARE @object_id     INT,
        @SCHEMA        VARCHAR(200),
        @Tabela        VARCHAR(200),
        @Coluna        VARCHAR(200),
        @column_id     INT,
        @user_type_id  INT,
        @max_length    INT,
        @PRECISION     INT,
        @TYPE          VARCHAR(200),
        @scale         INT,
        @is_nullable   BIT,
        @is_identity   BIT,
        @is_computed   BIT,
        @is_filestream BIT;


DECLARE CursorCampos CURSOR FAST_FORWARD READ_ONLY FOR
SELECT DC.object_id,
       DT.[Schema],
       DC.Tabela,
       DC.Coluna,
       DC.column_id,
       DC.user_type_id,
       DC.max_length,
       DC.precision,
       DC.Type,
       DC.scale,
       DC.is_nullable,
       DC.is_identity,
       DC.is_computed,
       DC.is_filestream
  FROM #DadosTabela AS DT
  JOIN #DadosColunas AS DC
    ON DT.object_id = DC.object_id
 WHERE DC.Type = @Campo
 ORDER BY DT.[Schema],
          DT.name;

OPEN CursorCampos;

FETCH NEXT FROM CursorCampos
 INTO @object_id,
      @SCHEMA,
      @Tabela,
      @Coluna,
      @column_id,
      @user_type_id,
      @max_length,
      @PRECISION,
      @TYPE,
      @scale,
      @is_nullable,
      @is_identity,
      @is_computed,
      @is_filestream;

WHILE @@FETCH_STATUS = 0
BEGIN
	
		
		DECLARE @query VARCHAR(MAX) ='';

		SET @query = CONCAT('IF(EXISTS(SELECT 1 FROM ','',QUOTENAME(@SCHEMA),'.',QUOTENAME(@Tabela),')) BEGIN  ');
		SET @query +=CONCAT(' SELECT * FROM ','',QUOTENAME(@SCHEMA),'.',QUOTENAME(@Tabela),' END');

		INSERT INTO #ScriptsGerados (ObjectId,
		                             [Schema],
		                             Tabela,
		                             Script)
		VALUES (@object_id, -- ObjectId - int
		       @SCHEMA, -- Schema - varchar(128)
		       @Tabela, -- Tabela - varchar(128)
		       @query -- Script - varchar(max)
		    )
		
	
	
		
		
		--SELECT DISTINCT L.IPAdress,
  --     LEN(L.IPAdress),
  --     TamanhoAtual = DATALENGTH(L.IPAdress),
  --     Correto = REPLACE(L.IPAdress, '.', ''),
  --     TamabnhoCorreto = DATALENGTH(REPLACE(L.IPAdress, '.', ''))
  --FROM Log.Logs AS L;

		
			--200.10.189.73
		--SELECT DataBloqueio FROM Acesso.BloqueiosUsuarios

  
		--ALTER TABLE Acesso.BloqueiosUsuarios
		--ALTER COLUMN DataBloqueio DATETIME2(3) NOT NULL;





    FETCH NEXT FROM CursorCampos
     INTO @object_id,
          @SCHEMA,
          @Tabela,
          @Coluna,
          @column_id,
          @user_type_id,
          @max_length,
          @PRECISION,
          @TYPE,
          @scale,
          @is_nullable,
          @is_identity,
          @is_computed,
          @is_filestream;
END;

CLOSE CursorCampos;
DEALLOCATE CursorCampos;


SELECT * FROM #ScriptsGerados AS SG