
GO

--EXEC HealthCheck.uspDeleteDuplicateIndex @Efetivar = 0, -- bit
--                                         @MostrarIndicesDuplicados = 1, -- bit
--                                         @MostrarIndicesMarcadosParaDeletar = 1, -- bit
--                                         @QuantidadeDiasAnalizados = 1, -- tinyint
--                                         @TaxaDeSeguranca = 10 -- tinyint


CREATE OR ALTER  PROCEDURE HealthCheck.uspDeleteDuplicateIndex (
    @Efetivar BIT = 0,
    @MostrarIndicesDuplicados BIT = 1,
    @MostrarIndicesMarcadosParaDeletar BIT = 1,
    @TableName VARCHAR(128) = NULL,
    @QuantidadeDiasAnalizados TINYINT = 7,
    @TaxaDeSeguranca TINYINT = 10)
AS
BEGIN

    SET NOCOUNT ON;
    SET TRAN ISOLATION LEVEL READ UNCOMMITTED;


	--DECLARE @Efetivar                          BIT          = 0,
 --           @MostrarIndicesDuplicados          BIT          = 1,
 --           @TableName                         VARCHAR(128) = NULL, --  '[Tramitacao].[Tramitacoes]',
 --           @MostrarIndicesMarcadosParaDeletar BIT          = 1,
 --           @QuantidadeDiasAnalizados          TINYINT      = 3,
 --           @TaxaDeSeguranca                   TINYINT      = 10;

    
	
	
	--Ids
	DECLARE @table AS TableIntegerIds;

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



    CREATE TABLE #Medias (
        [SnapShotDate] DATETIME2(3),
        [ObjectId] INT,
        [RowsInTable] INT,
        [ObjectName] VARCHAR(260),
        [IndexId] SMALLINT,
        [IndexName] VARCHAR(128),
        [Reads] BIGINT,
        [Write] INT,
        [PercAproveitamento] DECIMAL(18, 2),
        [PercCustoMedio] DECIMAL(18, 2),
        [PercScan] DECIMAL(18, 2),
        [AvgPercScan] DECIMAL(10, 2),
        [AvgIsBad] INT,
        [AvgReads] DECIMAL(10, 2),
        [AvgWrites] DECIMAL(10, 2),
        [AvgAproveitamento] DECIMAL(10, 2),
        [AvgCusto] DECIMAL(10, 2),
        [IsBadIndex] BIT,
        [MaxAnaliseForTable] SMALLINT,
        [MaxAnaliseForIndex] INT,
        [QtdAnalize] INT,
        [Analise] SMALLINT,
        [IsUniqueConstraint] BIT,
        [IsPrimaryKey] BIT,
        [IsUnique] BIT,
        PRIMARY KEY (ObjectId, IndexId, Analise));



    CREATE TABLE #Duplicates (
        ObjectId INT,
        [ObjectName] VARCHAR(128),
        [IndexName] VARCHAR(128),
        PercAproveitamento DECIMAL(18, 2),
        [PrimeiraChave] VARCHAR(200),
        [Chave] VARCHAR(998),
        [TamanhoChave] INT,
        [TamanhoCInclude] INT,
        [MaximaChave] INT,
        [MaximaCInclude] INT,
        [MesmaPrimeiraChave] VARCHAR(1),
        [ColunasIncluidas] VARCHAR(998),
        IsUnique BIT,
        IsPrimaryKey BIT,
        IsUniqueConstraint BIT,
        DescTipo TINYINT,
        IndexId SMALLINT,
        [Deletar] VARCHAR(1));

    CREATE TABLE #MarcadosParaDeletar (
        ObjectId INT,
        [ObjectName] VARCHAR(128),
        [IndexName] VARCHAR(128),
        PercAproveitamento DECIMAL(18, 2),
        [PrimeiraChave] VARCHAR(200),
        [MesmaPrimeiraChave] VARCHAR(1),
        [Chave] VARCHAR(998),
        [Deletar] VARCHAR(1),
        [ColunasIncluidas] VARCHAR(998),
        [TamanhoChave] INT,
        [MaximaChave] INT,
        [TamanhoCInclude] INT,
        [MaximaCInclude] INT,
        IsUnique BIT,
        IsPrimaryKey BIT,
        IsUniqueConstraint BIT,
        DescTipo VARCHAR(40),
        IndexId SMALLINT);

    CREATE TABLE #IndicesResumo (
	    RowId INT  NOT NULL PRIMARY KEY IDENTITY(1,1),
        ObjectId INT,
        [ObjectName] VARCHAR(300),
        [IndexName] VARCHAR(128),
        PercAproveitamento DECIMAL(18, 2),
        [Chave] VARCHAR(200),
        [PrimeiraChave] VARCHAR(899),
        [ColunasIncluidas] VARCHAR(899),
        [type_index] TINYINT,
        IndexId SMALLINT,
        IsUnique BIT,
        IsPrimaryKey BIT,
        IsUniqueConstraint BIT);

    CREATE TABLE #Indices (
        [ObjectId] INT,
        [ObjectName] VARCHAR(300),
        [RowsInTable] INT,
        [IndexName] VARCHAR(128),
        [Usado] BIT,
        [UserSeeks] INT,
        [UserScans] INT,
        [UserLookups] INT,
        [UserUpdates] INT,
        [Reads] BIGINT,
        [Write] INT,
		CountPageSplitPage INT,
        [PercAproveitamento] DECIMAL(18, 2),
        [PercCustoMedio] DECIMAL(18, 2),
        [IsBadIndex] INT,
        [IndexId] SMALLINT,
        [IndexsizeKB] BIGINT,
        [IndexsizeMB] DECIMAL(18, 2),
        [IndexSizePorTipoMB] DECIMAL(18, 2),
        [Chave] VARCHAR(899),
        [ColunasIncluidas] VARCHAR(899),
        [IsUnique] BIT,
        [IgnoreDupKey] BIT,
        [IsprimaryKey] BIT,
        [IsUniqueConstraint] BIT,
        [FillFact] TINYINT,
        [AllowRowLocks] BIT,
        [AllowPageLocks] BIT,
        [HasFilter] BIT,
        [TypeIndex] TINYINT);

    INSERT INTO #Indices
    /*Faz uma analise completa de todos os indices*/
    EXEC HealthCheck.uspAllIndex @typeIndex = NULL, -- varchar(30)
                                 @SomenteUsado = NULL, -- bit
                                 @TableIsEmpty = 0, -- bit
                                 @ObjectName = NULL, -- varchar(128)
                                 @BadIndex = NULL, -- bit
                                 @percentualAproveitamento = NULL; -- smallint






    INSERT INTO #IndicesResumo
    SELECT X.ObjectId,
           X.ObjectName,
           X.IndexName,
           X.PercAproveitamento,
           X.Chave,
           [PrimeiraChave] = IIF(CHARINDEX(',', X.Chave, 0) > 0,
                                 (SUBSTRING(X.Chave, 0, CHARINDEX(',', X.Chave, 0))),
                                 X.Chave),
           X.ColunasIncluidas,
           X.TypeIndex,
           X.IndexId,
           X.IsUnique,
           X.IsprimaryKey,
           X.IsUniqueConstraint
      FROM #Indices X
     WHERE X.ObjectName NOT LIKE '%HangFire%';

	
    WITH Duplicates
      AS (SELECT I.ObjectId,
                 I.ObjectName,
                 I.IndexName,
                 I.PercAproveitamento,
                 I.PrimeiraChave,
                 I.Chave,
                 TamanhoChave = LEN(I.Chave),
                 TamanhoCInclude = ISNULL(LEN(I.ColunasIncluidas), 0),
                 MaximaChave = MAX(LEN(I.Chave)) OVER (PARTITION BY I.ObjectId, I.PrimeiraChave),
                 MaximaCInclude = ISNULL(MAX(LEN(I.ColunasIncluidas)) OVER (PARTITION BY I.ObjectId), 0),
                 MesmaPrimeiraChave = CASE
                                           WHEN EXISTS (   SELECT 1
                                                             FROM #IndicesResumo AS IR
                                                            WHERE IR.ObjectId      = I.ObjectId
                                                              AND IR.PrimeiraChave = I.PrimeiraChave
															  AND I.RowId <> IR.RowId) THEN 'S'
                                           ELSE 'N' END,
                 I.ColunasIncluidas,
                 I.IsUnique,
                 I.IsPrimaryKey,
                 I.IsUniqueConstraint,
                 I.type_index,
                 I.IndexId,
                 [Deletar] = NULL
            FROM #IndicesResumo AS I
           WHERE EXISTS (   SELECT 1
                              FROM #IndicesResumo DU
                             WHERE DU.ObjectId      = I.ObjectId
                               AND DU.PrimeiraChave = I.PrimeiraChave
                               AND DU.IndexId       <> I.IndexId))
    INSERT INTO #Duplicates
    SELECT *
      FROM Duplicates DU
     WHERE DU.IndexId > 1; -- Is not PK

	 
	 

    IF (EXISTS (SELECT 1 FROM #Duplicates AS D))
    BEGIN

        INSERT INTO @table (Id)
        SELECT DISTINCT D.ObjectId
          FROM #Duplicates AS D;

        INSERT INTO #Medias
        EXEC HealthCheck.uspIndexMedia @SnapShotDayMedia = @QuantidadeDiasAnalizados, -- smallint
                                       @TableObjectIds = @table, -- TableIntegerIds
                                       @IsUniqueConstraint = 0, -- bit
                                       @IsUnique = 0, -- bit
                                       @IsPrimaryKey = 0; -- bit



        IF (EXISTS (SELECT 1 FROM #Medias AS M))
        BEGIN
		
		


            /*Marca para deletar os indices duplicados que aparecerem apenas uma vez*/
            UPDATE D
               SET D.Deletar = 'S'
              FROM #Duplicates AS D
             WHERE D.ObjectId IN (   SELECT d2.ObjectId
                                       FROM #Duplicates AS d2
                                      GROUP BY d2.ObjectId
                                     HAVING COUNT(*) = 1 )
               AND D.PercAproveitamento < 10;


            WITH BadIndexIn7DiasNonUsage
              AS (SELECT D.ObjectId,
                         RowId = ROW_NUMBER() OVER (PARTITION BY D.ObjectId,
                                                                 D.PrimeiraChave
                                                        ORDER BY D.PercAproveitamento DESC,
                                                                 LEN(D.Chave) DESC),
                         D.ObjectName,
                         D.PrimeiraChave,
                         D.ColunasIncluidas,
                         D.Chave,
                         D.IndexId,
                         D.Deletar,
                         D.PercAproveitamento,
                         MenorAproveitamento = MIN(D.PercAproveitamento) OVER (PARTITION BY D.ObjectId, D.PrimeiraChave)
                    FROM #Duplicates AS D
                    LEFT JOIN #Medias AS M --(LEFT JOIN  não houve uso no 7 dias e o indice está duplicado)
                      ON D.ObjectId = M.ObjectId
                     AND D.IndexId  = M.IndexId
                   WHERE D.Deletar IS NULL)
            UPDATE D
               SET D.Deletar = 'S'
              FROM #Duplicates AS D
              JOIN BadIndexIn7DiasNonUsage Bad
                ON D.ObjectId = Bad.ObjectId
               AND D.IndexId  = Bad.IndexId
             WHERE D.PercAproveitamento = Bad.MenorAproveitamento
               AND Bad.RowId            > 1
               AND D.PercAproveitamento <= 10;
			   

            ;WITH BadIndexIn7DiasUsage
               AS (SELECT D.ObjectId,
                          RowId = ROW_NUMBER() OVER (PARTITION BY D.ObjectId,
                                                                  D.PrimeiraChave
                                                         ORDER BY D.PercAproveitamento DESC,
                                                                  LEN(D.Chave) DESC),
                          D.ObjectName,
                          D.PrimeiraChave,
                          D.ColunasIncluidas,
                          D.Chave,
                          D.IndexId,
                          D.Deletar,
                          D.PercAproveitamento,
                          MenorAproveitamento = MIN(D.PercAproveitamento) OVER (PARTITION BY D.ObjectId, D.PrimeiraChave)
                     FROM #Duplicates AS D
                     JOIN #Medias AS M --(Inner)
                       ON D.ObjectId = M.ObjectId
                      AND D.IndexId  = M.IndexId)
            UPDATE D
               SET D.Deletar = 'S'
              FROM #Duplicates AS D
              JOIN BadIndexIn7DiasUsage Bad
                ON D.ObjectId = Bad.ObjectId
               AND D.IndexId  = Bad.IndexId
             WHERE D.PercAproveitamento = Bad.MenorAproveitamento
               AND Bad.RowId            > 1
               AND D.PercAproveitamento <= 10;

			   
            INSERT INTO #MarcadosParaDeletar
            SELECT F1.ObjectId,
                   F1.ObjectName,
                   F1.IndexName,
                   F1.PercAproveitamento,
                   F1.PrimeiraChave,
                   F1.MesmaPrimeiraChave,
                   F1.Chave,
                   F1.Deletar,
                   F1.ColunasIncluidas,
                   F1.TamanhoChave,
                   F1.MaximaChave,
                   F1.TamanhoCInclude,
                   F1.MaximaCInclude,
                   F1.IsUnique,
                   F1.IsPrimaryKey,
                   F1.IsUniqueConstraint,
                   F1.DescTipo,
                   F1.IndexId
              FROM #Duplicates F1
             WHERE F1.Deletar = 'S'
             ORDER BY F1.ObjectId,
                      F1.PrimeiraChave,
                      F1.Chave;

					  
            IF (EXISTS (SELECT 1 FROM #MarcadosParaDeletar AS MPD)  AND @Efetivar = 1
			)
            BEGIN

                /* declare variables */
                DECLARE @ObjectName VARCHAR(128),
                        @IndexName  VARCHAR(128);
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

        END;
    END;


    IF (@MostrarIndicesDuplicados = 1)
    BEGIN

        SELECT 'Duplicado=>' AS Descricao,
               D.ObjectId,
               D.ObjectName,
               D.IndexName,
               D.PercAproveitamento,
               D.PrimeiraChave,
               D.Chave,
               D.TamanhoChave,
               D.TamanhoCInclude,
               D.MaximaChave,
               D.MaximaCInclude,
               D.MesmaPrimeiraChave,
               D.ColunasIncluidas,
               D.IsUnique,
               D.IsPrimaryKey,
               D.IsUniqueConstraint,
               D.DescTipo,
               D.IndexId,
               D.Deletar
          FROM #Duplicates AS D
         ORDER BY D.ObjectId,
                  D.PrimeiraChave;
    END;

    IF (@MostrarIndicesMarcadosParaDeletar = 1)
    BEGIN

        SELECT 'A Deletar=>' AS Descricao,
               MPD.ObjectName,
               MPD.IndexName,
               MPD.PercAproveitamento,
               MPD.PrimeiraChave,
               MPD.MesmaPrimeiraChave,
               MPD.Chave,
               MPD.Deletar,
               MPD.ColunasIncluidas,
               MPD.TamanhoChave,
               MPD.MaximaChave,
               MPD.TamanhoCInclude,
               MPD.MaximaCInclude,
               MPD.IsUnique,
               MPD.IsPrimaryKey,
               MPD.IsUniqueConstraint,
               MPD.DescTipo,
               MPD.IndexId
          FROM #MarcadosParaDeletar AS MPD
         ORDER BY MPD.ObjectId,
                  MPD.PrimeiraChave;

    END;

END;

GO
