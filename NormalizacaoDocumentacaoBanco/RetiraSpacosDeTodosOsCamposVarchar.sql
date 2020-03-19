

BEGIN
    DECLARE @Tabela VARCHAR(200) =  NULL --'DemonstracoesAtuacoesAuditoriasInternas';--;
    DECLARE @NomeSchema VARCHAR(200) = NULL;--'TCU';-- 'DemonstracoesAtuacoesAuditoriasInternas';
    
    IF (OBJECT_ID('TEMPDB..#Dados') IS NOT NULL)
        DROP TABLE #Dados;
    

    IF (OBJECT_ID('TEMPDB..#DadosParaTrabalhar') IS NOT NULL)
        DROP TABLE #DadosParaTrabalhar;
    
    IF (OBJECT_ID('TEMPDB..#Scripts') IS NOT NULL)
        DROP TABLE #Scripts;
    
    
	IF ( OBJECT_ID('TEMPDB..#Scripts') IS NOT NULL )
	    DROP TABLE #Scripts;	
	
	CREATE TABLE #Scripts
	    (
	      ObjectId INT NOT NULL ,
	      NomeTabela VARCHAR(max) NULL ,
	      ScriptSelect VARCHAR(max),
		  ScriptUpdate VARCHAR(max),
	    );
    
    CREATE TABLE #Dados (
        [Schema] VARCHAR(250),
        [Nome da Tabela] VARCHAR(250),
        [object_id] INT,
        [type_desc] VARCHAR(250),
        [create_date] DATETIME,
        [Nome Coluna] VARCHAR(250),
        [column_id] INT,
        [precision] TINYINT,
        [is_nullable] BIT,
        [is_rowguidcol] BIT,
        [Nome do Type] VARCHAR(250));
    
    

    
 
    
    CREATE TABLE #DadosParaTrabalhar (
        [Schema] NVARCHAR(250),
        [Nome da Tabela] VARCHAR(256),
        [object_id] INT,
        [type_desc] VARCHAR(250),
        [create_date] DATETIME,
        [Coluna PK] VARCHAR(256),
        [Colunas] NVARCHAR(max));
    
    
    
    
    
    WITH DadosTabela
      AS (SELECT [Schema] = S.name,
                 [Nome da Tabela] = T.name,
                 T.object_id,
                 T.type_desc,
                 T.create_date,
                 T.durability_desc,
                 T.temporal_type_desc,
                 T.lob_data_space_id
            FROM sys.tables AS T
            JOIN sys.schemas AS S
              ON T.schema_id = S.schema_id),
         Colunas
      AS (SELECT C.object_id,
                 [Nome Coluna] = C.name,
                 C.column_id,
                 C.precision,
                 C.is_nullable,
                 C.is_rowguidcol,
                 [Nome do Type] = T.name
            FROM sys.columns AS C
            JOIN sys.types AS T
              ON C.system_type_id = T.system_type_id
         )

    INSERT INTO #Dados ([Schema],
                        [Nome da Tabela],
                        object_id,
                        type_desc,
                        create_date,
                        [Nome Coluna],
                        column_id,
                        precision,
                        is_nullable,
                        is_rowguidcol,
                        [Nome do Type])
    SELECT T.[Schema],
           T.[Nome da Tabela],
           T.object_id,
           T.type_desc,
           T.create_date,
           C.[Nome Coluna],
           C.column_id,
           C.precision,
           C.is_nullable,
           C.is_rowguidcol,
           C.[Nome do Type]
      FROM DadosTabela T
      JOIN Colunas C
        ON T.object_id = C.object_id
     WHERE 
	 
	   (
	      C.column_id    = 1
		  OR   C.[Nome do Type] IN ( 'varchar','nvarchar' )
	   )
	 AND EXISTS( SELECT * FROM sys.columns AS C2
				JOIN sys.types t2 ON c2.user_type_id = t2.user_type_id
	 WHERE C2.object_id = T.object_id
	 AND t2.name IN ( 'varchar','nvarchar' ))
     ORDER BY T.[Nome da Tabela],
              C.column_id;
    
    
	
    INSERT INTO #DadosParaTrabalhar
    SELECT D.[Schema],
           D.[Nome da Tabela],
           D.object_id,
           D.type_desc,
           D.create_date,
           [Coluna PK] = D.[Nome Coluna],
           [Colunas] = (   SELECT STRING_AGG(D3.[Nome Coluna], ';')
                             FROM #Dados AS D3
                            WHERE D3.column_id > 1
							AND D3.object_id =D.object_id )
      FROM #Dados AS D
     WHERE D.column_id = 1
	 AND
	 (
	 @NomeSchema IS NULL OR   D.[Schema] = @NomeSchema
	 AND
	 @Tabela IS NULL OR   D.[Nome da Tabela] = @Tabela
	 )
	 
	
	 

END





/* declare variables */
DECLARE @Schema      NVARCHAR(250),
        @NomeTabela  NVARCHAR(250),
        @object_id   INT,
        @type_desc   NVARCHAR(250),
        @create_date DATETIME,
        @ColunaPK    NVARCHAR(250),
        @Colunas     NVARCHAR(max);


DECLARE cursosrValidacao CURSOR FAST_FORWARD READ_ONLY FOR
SELECT DPT.[Schema],
       DPT.[Nome da Tabela],
       DPT.object_id,
       DPT.type_desc,
       DPT.create_date,
       DPT.[Coluna PK],
       DPT.Colunas
  FROM #DadosParaTrabalhar AS DPT;

OPEN cursosrValidacao;

FETCH NEXT FROM cursosrValidacao
 INTO @Schema,
      @NomeTabela,
      @object_id,
      @type_desc,
      @create_date,
      @ColunaPK,
      @Colunas;

WHILE @@FETCH_STATUS = 0
BEGIN

    DECLARE @TempCampos AS TABLE (
        ObjetcId INT,
        NomeTabela VARCHAR(300) NOT NULL,
        IdColuna INT,
        NomeColuna VARCHAR(128));

    INSERT INTO @TempCampos (ObjetcId,
                             NomeTabela,
                             IdColuna,
                             NomeColuna)
    SELECT @object_id,
           @NomeTabela,
           RN = ROW_NUMBER() OVER (ORDER BY (SELECT NULL)),
           C.Conteudo
      FROM Sistema.fnSplitValues(@Colunas, ';') C;

	  --SELECT * FROM @TempCampos AS TC

	  
    WHILE(EXISTS(SELECT 1 FROM @TempCampos TC))
	  BEGIN

	   DECLARE @ScriptSelect VARCHAR(MAX);
	   DECLARE @ScripUpdate VARCHAR(MAX);


			  DECLARE @MenorValor INT;

			SET @MenorValor = (SELECT MIN(T.IdColuna) FROM @TempCampos AS T);


			DECLARE @CampoPesquisa VARCHAR(MAX) =(SELECT TC.NomeColuna FROM @TempCampos AS TC
															WHERE TC.IdColuna =@MenorValor);

			-- ==================================================================
			--Observação:Monta a query Por Coluna do Tipo Varchar
			-- ==================================================================


			SET @ScriptSelect = CONCAT('IF (EXISTS (   SELECT X.* FROM ',@Schema,'.[',@NomeTabela,'] AS X WHERE',SPACE(1), 'X.[',@CampoPesquisa,'] IS NOT NULL 
			AND LEN(X.[',@CampoPesquisa,']) <> LEN(RTRIM(LTRIM(X.[',@CampoPesquisa,']))))) BEGIN ')
					 

			SET @ScriptSelect += CONCAT(' ;WITH Dados',@CampoPesquisa,' AS ( SELECT',SPACE(1),CHAR(39),@Schema,CHAR(39),' AS NomeSchema,',
			SPACE(1),CHAR(39),@NomeTabela,CHAR(39),' AS NomeTabela,',SPACE(1),
			CHAR(39),@CampoPesquisa,CHAR(39),' AS CampoProcurado,',SPACE(1),
				'X.',@ColunaPK,',',
			'Tamanho =LEN(X.[',@CampoPesquisa,'])',SPACE(1),',',
			'TamanhoFormatado =','LEN(RTRIM(LTRIM(X.[',@CampoPesquisa,'])))',',',
			'Valor = ','LTRIM(LTRIM(X.[',@CampoPesquisa,']))',
			 SPACE(1),'FROM',SPACE(1), @Schema,'.[',@NomeTabela,'] AS X  WHERE X.[',@CampoPesquisa,'] IS NOT NULL',SPACE(1) ,
			 'AND LEN(X.[',@CampoPesquisa,'])  <> ',SPACE(1),'LEN(RTRIM(LTRIM(X.[',@CampoPesquisa,'])))) SELECT * FROM  Dados',@CampoPesquisa,' R END') 
			


			
			
				SET @ScripUpdate = CONCAT('IF (EXISTS (   SELECT X.* FROM ',@Schema,'.[',@NomeTabela,'] AS X WHERE',SPACE(1), 'X.[',@CampoPesquisa,'] IS NOT NULL 
			AND LEN(X.[',@CampoPesquisa,']) <> LEN(RTRIM(LTRIM(X.[',@CampoPesquisa,']))))) BEGIN ')

			 
			 SET @ScripUpdate +=CONCAT('SELECT',SPACE(1),CHAR(39),@Schema,CHAR(39),' AS NomeSchema,',SPACE(1),CHAR(39),@NomeTabela,CHAR(39),' AS NomeTabela,',SPACE(1),
			CHAR(39),@CampoPesquisa,CHAR(39),' AS CampoProcurado',SPACE(1))

			 SET @ScripUpdate += CONCAT(' ;WITH Dados',@CampoPesquisa,' AS ( SELECT',SPACE(1),'X.',@ColunaPK,',',
			'Tamanho =LEN(X.[',@CampoPesquisa,'])',',',
			'TamanhoFormatado =','LEN(RTRIM(LTRIM(X.[',@CampoPesquisa,'])))',',',
			'Valor = ','LTRIM(LTRIM(X.[',@CampoPesquisa,']))',
			 SPACE(1),' FROM ',SPACE(1), @Schema,'.[',@NomeTabela,'] AS X  WHERE X.[',@CampoPesquisa,'] IS NOT NULL',SPACE(1) ,
			 'AND LEN(X.[',@CampoPesquisa,'])  <> ','LEN(RTRIM(LTRIM(X.[',@CampoPesquisa,']))))  UPDATE UP  SET UP.[',@CampoPesquisa,']= Result.Valor',
			 SPACE(1),' FROM ',@Schema,'.[',@NomeTabela,'] AS UP JOIN Dados',@CampoPesquisa,' AS Result ON UP.',@ColunaPK,' = Result.',@ColunaPK,'; END ') 
			
			
			INSERT INTO #Scripts 
			SELECT @object_id,@NomeTabela,@ScriptSelect,@ScripUpdate


			DELETE TD FROM @TempCampos TD
			WHERE TD.NomeColuna  = @CampoPesquisa;

			  
			
			
	  END
	

     FETCH NEXT FROM cursosrValidacao
     INTO @Schema,
          @NomeTabela,
          @object_id,
          @type_desc,
          @create_date,
          @ColunaPK,
          @Colunas;

END;

SELECT * FROM #Scripts
ORDER BY #Scripts.NomeTabela



CLOSE cursosrValidacao;
DEALLOCATE cursosrValidacao;
