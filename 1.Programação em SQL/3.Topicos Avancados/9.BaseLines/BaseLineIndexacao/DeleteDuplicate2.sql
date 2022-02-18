

CREATE OR ALTER PROCEDURE BaseLine.[Indexacao.sp_DeleteDuplicateIndex]
(
    @Efetivar BIT = 0,
    @MostrarIndicesDuplicados BIT = 1,
    @MostrarIndicesMarcadosParaDeletar BIT = 1,
    @TableName VARCHAR(128) = NULL
)
AS
BEGIN

/*
DECLARE @Efetivar BIT = 0,
        @MostrarIndicesDuplicados BIT = 1,
        @TableName VARCHAR(128) = NULL ,--  '[Tramitacao].[Tramitacoes]',
        @MostrarIndicesMarcadosParaDeletar BIT = 1;

*/
		

    IF (EXISTS
    (
        SELECT 1
        FROM BaseLine.[Indexacao.ufnIndexMedia](30) AS IUIM
        WHERE IUIM.QtdAnalize = 7
    )
       )
    BEGIN

        IF (OBJECT_ID('TEMPDB..#Indices') IS NOT NULL)
            DROP TABLE #Indices;

        IF (OBJECT_ID('TEMPDB..#MarcadosParaDeletar') IS NOT NULL)
            DROP TABLE #MarcadosParaDeletar;

        IF (OBJECT_ID('TEMPDB..#Duplicates') IS NOT NULL)
            DROP TABLE #Duplicates;

        IF (OBJECT_ID('TEMPDB..#IndicesResumo') IS NOT NULL)
            DROP TABLE #IndicesResumo;

        IF (OBJECT_ID('TEMPDB..#Medias') IS NOT NULL)
            DROP TABLE #Medias;

        CREATE TABLE #Medias
        (
            [object_id] INT,
            [index_id] SMALLINT,
            [IndexName] VARCHAR(128),
            [QtdAnalize] INT,
            [Analize] SMALLINT,
            [IsBad 7] INT,
            [Media Aproveitamento 7 dias] DECIMAL(18, 2),
            [Media Custo 7 dias] DECIMAL(18, 2),
            CONSTRAINT PkMedias
                PRIMARY KEY
                (
                    object_id,
                    index_id,
                    Analize
                )
        );

        CREATE TABLE #Duplicates
        (
            [object_id] INT,
            [ObjectName] VARCHAR(128),
            [IndexName] VARCHAR(128),
            [% Aproveitamento] DECIMAL(18, 2),
            [PrimeiraChave] VARCHAR(100),
            [Chave] VARCHAR(100),
            [TamanhoChave] INT,
            [TamanhoCInclude] INT,
            [MaximaChave] INT,
            [MaximaCInclude] INT,
            [MesmaPrimeiraChave] VARCHAR(1),
            [ColunasIncluidas] VARCHAR(500),
            [is_unique] BIT,
            [is_primary_key] BIT,
            [is_unique_constraint] BIT,
            [type_desc] TINYINT,
            [index_id] SMALLINT,
            [Deletar] VARCHAR(1)
        );

        CREATE TABLE #MarcadosParaDeletar
        (
            [object_id] INT,
            [ObjectName] VARCHAR(128),
            [IndexName] VARCHAR(128),
            [% Aproveitamento] DECIMAL(18, 2),
            [PrimeiraChave] VARCHAR(100),
            [MesmaPrimeiraChave] VARCHAR(1),
            [Chave] VARCHAR(100),
            [Deletar] VARCHAR(1),
            [ColunasIncluidas] VARCHAR(500),
            [TamanhoChave] INT,
            [MaximaChave] INT,
            [TamanhoCInclude] INT,
            [MaximaCInclude] INT,
            [is_unique] BIT,
            [is_primary_key] BIT,
            [is_unique_constraint] BIT,
            [type_desc] VARCHAR(40),
            [index_id] SMALLINT
        );

        CREATE TABLE #IndicesResumo
        (
            [object_id] INT,
            [ObjectName] VARCHAR(300),
            [IndexName] VARCHAR(128),
            [% Aproveitamento] DECIMAL(18, 2),
            [Chave] VARCHAR(100),
            [PrimeiraChave] VARCHAR(100),
            [ColunasIncluidas] VARCHAR(500),
            [type_index] TINYINT,
            [index_id] SMALLINT,
            [is_unique] BIT,
            [is_primary_key] BIT,
            [is_unique_constraint] BIT
        );

        CREATE TABLE #Indices
        (
            [object_id] INT,
            [ObjectName] VARCHAR(300),
            [RowsInTable] INT,
            [IndexName] VARCHAR(128),
            [Usado] BIT,
            [user_seeks] INT,
            [user_scans] INT,
            [user_lookups] INT,
            [Reads] BIGINT,
            [Write] INT,
            [% Aproveitamento] DECIMAL(18, 2),
            [write:Custo Medio] DECIMAL(18, 2),
            [IsBadIndex] INT,
            [index_id] SMALLINT,
            [Indexsize(KB)] BIGINT,
            [Indexsize(MB)] DECIMAL(18, 2),
            [Indexsize por tipo (MB)] DECIMAL(18, 2),
            [Chave] VARCHAR(100),
            [ColunasIncluidas] VARCHAR(500),
            [is_unique] BIT,
            [ignore_dup_key] BIT,
            [is_primary_key] BIT,
            [is_unique_constraint] BIT,
            [fill_factor] TINYINT,
            [allow_row_locks] BIT,
            [allow_page_locks] BIT,
            [has_filter] BIT,
            [compression_delay] INT,
            [type_index] TINYINT
        );

        INSERT INTO #Indices
        /*Faz uma analise completa de todos os indices*/
        EXEC BaseLine.spAllIndex @typeIndex = NULL,                -- varchar(30)
                                 @SomenteUsado = NULL,             -- bit
                                 @TableIsEmpty = NULL,             -- bit
                                 @ObjectName = @TableName,         -- varchar(128)
                                 @BadIndex = NULL,                 -- bit
                                 @percentualAproveitamento = NULL; -- smallint

        INSERT INTO #IndicesResumo
        SELECT X.object_id,
               X.ObjectName,
               X.IndexName,
               X.[% Aproveitamento],
               X.Chave,
               [PrimeiraChave] = IIF(CHARINDEX(',', X.Chave, 0) > 0,
                                     (SUBSTRING(X.Chave, 0, CHARINDEX(',', X.Chave, 0))),
                                     X.Chave),
               X.ColunasIncluidas,
               X.type_index,
               X.index_id,
               X.is_unique,
               X.is_primary_key,
               X.is_unique_constraint
        FROM #Indices X;
        WITH Duplicates
        AS (SELECT I.object_id,
                   I.ObjectName,
                   I.IndexName,
                   I.[% Aproveitamento],
                   I.PrimeiraChave,
                   I.Chave,
                   TamanhoChave = LEN(I.Chave),
                   TamanhoCInclude = ISNULL(LEN(I.ColunasIncluidas), 0),
                   MaximaChave = MAX(LEN(I.Chave)) OVER (PARTITION BY I.object_id ,I.PrimeiraChave),
                   MaximaCInclude = ISNULL(MAX(LEN(I.ColunasIncluidas)) OVER (PARTITION BY I.object_id), 0),
                   MesmaPrimeiraChave = CASE
                                            WHEN EXISTS
    (
        SELECT 1
        FROM #IndicesResumo AS IR
        WHERE IR.object_id = I.object_id
              AND IR.PrimeiraChave = I.PrimeiraChave
    )              THEN
                                                'S'
                                            ELSE
                                                'N'
                                        END,
                   I.ColunasIncluidas,
                   I.is_unique,
                   I.is_primary_key,
                   I.is_unique_constraint,
                   I.type_index,
                   I.index_id,
                   [Deletar] = NULL
            FROM #IndicesResumo AS I
            WHERE EXISTS
            (
                SELECT 1
                FROM #IndicesResumo DU
                WHERE DU.object_id = I.object_id
                      AND DU.PrimeiraChave = I.PrimeiraChave
                      AND DU.index_id <> I.index_id
            )
                  AND I.ObjectName NOT LIKE 'HangFire%'
           )
        INSERT INTO #Duplicates
        SELECT *
        FROM Duplicates DU
        WHERE DU.index_id > 1
              AND DU.ObjectName NOT LIKE '%HangFire%';



			  


 
        ;WITH Analises
        AS (SELECT Media.object_id,
				   Media.IndexName,
                   Media.index_id,
                   Media.QtdAnalize,
                   Media.Analize,
                   Media.[IsBad 7],
                   MaiorAnalize = MAX(Media.Analize) OVER (PARTITION BY Media.object_id, Media.index_id),
                   Media.[Media Aproveitamento 7 dias],
                   Media.[Media Custo 7 dias]
            FROM BaseLine.[Indexacao.ufnIndexMedia](30) AS Media
            WHERE Media.Analize >= 7
                  AND Media.is_unique_constraint = 0
                  AND Media.is_primary_key = 0
                  AND Media.is_unique = 0
                  AND Media.object_id IN (
                                             SELECT D.object_id FROM #Duplicates AS D
                                         )
           )
        INSERT INTO #Medias
        SELECT AN.object_id,
               AN.index_id,
               AN.IndexName,
               AN.QtdAnalize,
               AN.Analize,
               AN.[IsBad 7],
               AN.[Media Aproveitamento 7 dias],
               AN.[Media Custo 7 dias]
        FROM Analises AN
        WHERE AN.Analize = AN.MaiorAnalize;



	
		UPDATE D
		SET D.Deletar = 'S'
		FROM #Duplicates AS D
		WHERE D.object_id IN (
								 SELECT d2.object_id
									
								 FROM #Duplicates AS d2
								 GROUP BY d2.object_id
								 HAVING COUNT(*) = 1
							 )
			AND D.[% Aproveitamento] < 10




				;WITH BadIndexIn7DiasNonUsage
				AS (SELECT D.object_id,
						   RowId = ROW_NUMBER() OVER (PARTITION BY D.object_id,
																   D.PrimeiraChave
													  ORDER BY D.[% Aproveitamento] DESC , LEN(D.Chave) desc 
													 ),
						   D.ObjectName,
						  -- D.IndexName,
						   D.PrimeiraChave,
						   D.ColunasIncluidas,
						   D.Chave,
						   D.index_id,
						   D.Deletar,
						   D.[% Aproveitamento],
						   MenorAproveitamento = MIN(D.[% Aproveitamento]) OVER (PARTITION BY D.object_id, D.PrimeiraChave)
					FROM #Duplicates AS D
						LEFT JOIN #Medias AS M
							ON D.object_id = M.object_id
							   AND D.index_id = M.index_id
					WHERE D.Deletar IS NULL
				   )
				 UPDATE D
				SET D.Deletar = 'S'
				FROM #Duplicates AS D
					JOIN BadIndexIn7DiasNonUsage Bad
						ON D.object_id = Bad.object_id
						   AND D.index_id = Bad.index_id
				WHERE D.[% Aproveitamento] = Bad.MenorAproveitamento
					  AND Bad.RowId > 1
					  AND  D.[% Aproveitamento] < 10
				
				

        
        INSERT INTO #MarcadosParaDeletar
        SELECT F1.object_id,
               F1.ObjectName,
               F1.IndexName,
               F1.[% Aproveitamento],
               F1.PrimeiraChave,
               F1.MesmaPrimeiraChave,
               F1.Chave,
               F1.Deletar,
               F1.ColunasIncluidas,
               F1.TamanhoChave,
               F1.MaximaChave,
               F1.TamanhoCInclude,
               F1.MaximaCInclude,
               F1.is_unique,
               F1.is_primary_key,
               F1.is_unique_constraint,
               F1.type_desc,
               F1.index_id
        FROM #Duplicates F1
        WHERE F1.Deletar = 'S'
        ORDER BY F1.object_id,
                 F1.PrimeiraChave,
                 F1.Chave;




        IF (EXISTS (SELECT 1 FROM #MarcadosParaDeletar AS MPD) AND @Efetivar = 1)
        BEGIN

            /* declare variables */
            DECLARE @ObjectName VARCHAR(128),
                    @IndexName VARCHAR(128);
            DECLARE @Script NVARCHAR(1000);

            DECLARE cursor_DeletaIndiceDuplicado CURSOR FAST_FORWARD READ_ONLY FOR
            SELECT MPD.ObjectName,
                   MPD.IndexName
            FROM #MarcadosParaDeletar AS MPD;

            OPEN cursor_DeletaIndiceDuplicado;

            FETCH NEXT FROM cursor_DeletaIndiceDuplicado
            INTO @ObjectName,
                 @IndexName;

            WHILE @@FETCH_STATUS = 0
            BEGIN

                SET @Script = CONCAT('DROP INDEX', SPACE(1), @IndexName, SPACE(1), ' ON ', @ObjectName);

                EXEC sys.sp_executesql @Script;

                FETCH NEXT FROM cursor_DeletaIndiceDuplicado
                INTO @ObjectName,
                     @IndexName;
            END;

            CLOSE cursor_DeletaIndiceDuplicado;
            DEALLOCATE cursor_DeletaIndiceDuplicado;
        END;

        IF (@MostrarIndicesDuplicados = 1)
        BEGIN




            SELECT 'Duplicado=>',
                   D.ObjectName,
                   D.IndexName,
                   D.[% Aproveitamento],
                   D.PrimeiraChave,
                   D.Chave,
                   D.Deletar,
                   D.ColunasIncluidas,
                   D.TamanhoChave,
                   D.TamanhoCInclude,
                   D.MaximaChave,
                   D.MaximaCInclude,
                   D.MesmaPrimeiraChave,
                   D.is_unique,
                   D.is_primary_key,
                   D.is_unique_constraint,
                   D.type_desc,
                   D.index_id
            FROM #Duplicates AS D
            ORDER BY D.object_id,
                     D.index_id;
        END;

        IF (@MostrarIndicesMarcadosParaDeletar = 1)
        BEGIN

            SELECT 'A Deletar=>',
                   MPD.ObjectName,
                   MPD.IndexName,
                   MPD.[% Aproveitamento],
                   MPD.PrimeiraChave,
                   MPD.MesmaPrimeiraChave,
                   MPD.Chave,
                   MPD.Deletar,
                   MPD.ColunasIncluidas,
                   MPD.TamanhoChave,
                   MPD.MaximaChave,
                   MPD.TamanhoCInclude,
                   MPD.MaximaCInclude,
                   MPD.is_unique,
                   MPD.is_primary_key,
                   MPD.is_unique_constraint,
                   MPD.type_desc,
                   MPD.index_id
            FROM #MarcadosParaDeletar AS MPD
            ORDER BY MPD.object_id,
                     MPD.index_id;

        END;
    END;
	ELSE
	BEGIN
			SELECT 'E necessário no minimo 3 analises!';
	END
END;

