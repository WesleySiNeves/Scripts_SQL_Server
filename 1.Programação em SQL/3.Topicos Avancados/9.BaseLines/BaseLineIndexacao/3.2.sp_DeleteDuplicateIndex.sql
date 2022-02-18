CREATE OR ALTER PROCEDURE HealthCheck.uspDeleteDuplicateIndex (
    @Efetivar BIT = 0,
    @MostrarIndicesDuplicados BIT = 1,
    @MostrarIndicesMarcadosParaDeletar BIT = 1,
    @TableName VARCHAR(128) = NULL,
    @QuantidadeDiasAnalizados TINYINT = 7,
    @TaxaDeSeguranca TINYINT = 10)
AS
BEGIN

    SET NOCOUNT ON;


    /*
DECLARE @Efetivar                          BIT          = 1,
        @MostrarIndicesDuplicados          BIT          = 1,
        @TableName                         VARCHAR(128) = NULL, --  '[Tramitacao].[Tramitacoes]',
        @MostrarIndicesMarcadosParaDeletar BIT          = 1,
        @QuantidadeDiasAnalizados          TINYINT      = 3,
        @TaxaDeSeguranca                   TINYINT      = 10;
*/


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

    IF (NOT EXISTS (   SELECT 1
                         FROM HealthCheck.ufnIndexMedia(3) AS IUIM
                        WHERE IUIM.QtdAnalize >= 3))
    BEGIN
        SET @Efetivar = 0;
    END;




    CREATE TABLE #Medias (
        ObjectId INT,
        IndexId SMALLINT,
        [IndexName] VARCHAR(128),
        [QtdAnalize] INT,
        [Analize] SMALLINT,
        [Media IsBad] INT,
        [Media Aproveitamento] DECIMAL(10, 2),
        [Media Custo ] DECIMAL(10, 2),
        PRIMARY KEY (ObjectId, IndexId, Analize));



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
        [Reads] BIGINT,
        [Write] INT,
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
                                 @ObjectName = @TableName, -- varchar(128)
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
      FROM #Indices X;


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
                                                              AND IR.PrimeiraChave = I.PrimeiraChave) THEN 'S'
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
                               AND DU.IndexId       <> I.IndexId)
             AND I.ObjectName NOT LIKE 'HangFire%')
    INSERT INTO #Duplicates
    SELECT *
      FROM Duplicates DU
     WHERE DU.IndexId > 1 -- Is not PK
       AND DU.ObjectName NOT LIKE '%HangFire%';




    ;WITH Analises
       AS (SELECT Media.ObjectId,
                  Media.IndexName,
                  Media.IndexId,
                  Media.QtdAnalize,
                  Media.Analise,
                  Media.AvgIsBad,
                  Media.MaxAnaliseForIndex,
                  Media.AvgAproveitamento,
                  Media.AvgCusto
             FROM HealthCheck.ufnIndexMedia(@QuantidadeDiasAnalizados) AS Media
            WHERE Media.MaxAnaliseForIndex = Media.Analise
              AND Media.MaxAnaliseForIndex >= @QuantidadeDiasAnalizados
              AND Media.IsUniqueConstraint = 0
              AND Media.IsPrimaryKey       = 0
              AND Media.IsUnique           = 0
              AND Media.ObjectId IN ( SELECT D.ObjectId FROM #Duplicates AS D ))
    INSERT INTO #Medias
    SELECT AN.ObjectId,
           AN.IndexId,
           AN.IndexName,
           AN.QtdAnalize,
           AN.AvgIsBad,
           AN.AvgAproveitamento,
           AN.AvgCusto,
           AN.Analise
      FROM Analises AN
     WHERE AN.Analise = AN.MaxAnaliseForIndex;




    /*Marca para deletar os indices duplicados que aparecerem apenas uma vez*/
    UPDATE D
       SET D.Deletar = 'S'
      FROM #Duplicates AS D
     WHERE D.ObjectId IN (   SELECT d2.ObjectId
                               FROM #Duplicates AS d2
                              GROUP BY d2.ObjectId
                             HAVING COUNT(*) = 1 )
       AND D.PercAproveitamento < @TaxaDeSeguranca;


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
            LEFT JOIN #Medias AS M --(LEFT JOIN  não houve uso no 7 dias e o indice esá duplicado)
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
       AND D.PercAproveitamento <= @TaxaDeSeguranca;


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
       AND D.PercAproveitamento <= @TaxaDeSeguranca;





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





    IF (EXISTS (SELECT 1 FROM #MarcadosParaDeletar AS MPD) AND @Efetivar = 1)
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
                  D.IndexId;
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
                  MPD.IndexId;

    END;

END;

