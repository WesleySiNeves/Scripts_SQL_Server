
--EXEC HealthCheck.uspAlterCollunsIntToSMALLINT @Efetivar =1,@Visualizar =1

CREATE OR ALTER PROCEDURE HealthCheck.uspAlterCollunsDecimal
(
    @ObjectName VARCHAR(200) = NULL,
    @Efetivar BIT = 0,
    @Visualizar BIT = 1
)
AS
BEGIN


    --DECLARE @ObjectName VARCHAR(200);
    --DECLARE @Efetivar BIT = 1;
    --DECLARE @Visualizar BIT = 1;


    DECLARE @TamanhoDecimal18 TINYINT = 9;
    DECLARE @TamanhoDecimal9 SMALLINT = 5;



    DECLARE @ObjectIdTable INT = OBJECT_ID(@ObjectName);

    IF (OBJECT_ID('TEMPDB..#CamposDecimal') IS NOT NULL)
        DROP TABLE #CamposDecimal;

    CREATE TABLE #CamposDecimal
    (
        [SchemaName] NVARCHAR(128),
        [TableName] NVARCHAR(128),
        [Rows] INT,
        [object_id] INT,
        [Coluna] NVARCHAR(128),
        [Type] NVARCHAR(128),
        [max_length] SMALLINT,
        [column_id] INT,
        [is_nullable] BIT,
        [Indexable] BIT,
        [is_computed] BIT
    );

    IF (OBJECT_ID('TEMPDB..#Reducao') IS NOT NULL)
        DROP TABLE #Reducao;

    CREATE TABLE #Reducao
    (
        [SchemaName] NVARCHAR(128),
        [TableName] NVARCHAR(128),
        [Rows] INT,
        [Coluna] NVARCHAR(128),
        [Type] NVARCHAR(128),
        [NewType] VARCHAR(12),
        [TamanhoAtualParaColunaBytes] INT,
        [ReducaoBytes] INT,
        [TamanhoAtualParaColunaPaginas] INT,
        [TamanhoResuzidoParaColunaPaginas] INT
    );


    IF (OBJECT_ID('TEMPDB..#CheckContraints') IS NOT NULL)
        DROP TABLE #CheckContraints;

    CREATE TABLE #CheckContraints
    (
        [SchemaName] NVARCHAR(128),
        [TableName] NVARCHAR(128),
        [Rows] INT,
        [object_id] INT,
        [Coluna] NVARCHAR(128),
        [Type] NVARCHAR(128),
        [max_length] SMALLINT,
        [column_id] INT,
        [is_nullable] BIT,
        [Indexable] BIT,
        [is_computed] BIT,
        [NovoTipo] NVARCHAR(128),
        [ConstraintsName] NVARCHAR(128),
        [ConstraintsType] NVARCHAR(60),
        [ConstraintsDefinition] NVARCHAR(MAX)
    );


    IF (OBJECT_ID('TEMPDB..#Statisticas') IS NOT NULL)
        DROP TABLE #Statisticas;

    CREATE TABLE #Statisticas
    (
        [TableName] NVARCHAR(128),
        [object_id] INT,
        [StatisticasName] NVARCHAR(128),
        [stats_id] INT,
        [has_filter] BIT,
        [filter_definition] NVARCHAR(MAX),
        [stats_generation_method_desc] VARCHAR(80),
        [column_id] INT
            PRIMARY KEY
            (
                object_id,
                column_id,
                [StatisticasName]
            )
    );

    IF (OBJECT_ID('TEMPDB..#TempIndex') IS NOT NULL)
        DROP TABLE #TempIndex;

    CREATE TABLE #TempIndex
    (
        [object_id] INT,
        [TableName] NVARCHAR(150),
        [IndexName] NVARCHAR(150),
        [type_desc] NVARCHAR(60),
        [column_id] INT,
        [key_ordinal] TINYINT
            PRIMARY KEY
            (
                object_id,
                column_id,
                [IndexName]
            )
    );


    IF (OBJECT_ID('TEMPDB..#GenerateCreateCheckContraint') IS NOT NULL)
        DROP TABLE #GenerateCreateCheckContraint;


    CREATE TABLE #GenerateCreateCheckContraint
    (
        RowId INT NOT NULL IDENTITY(1, 1),
        [SchemaName] NVARCHAR(128),
        [TableName] NVARCHAR(128),
        [object_id] INT,
        Colum_Id INT,
        [Coluna] NVARCHAR(128),
        [ConstraintsName] NVARCHAR(128),
        [ConstraintsDefinition] NVARCHAR(MAX),
        [Script] NVARCHAR(MAX)
            PRIMARY KEY
            (
                [object_id],
                Colum_Id,
                RowId
            )
    );


    IF (OBJECT_ID('TEMPDB..#GenerateCreateDefaults') IS NOT NULL)
        DROP TABLE #GenerateCreateDefaults;

    CREATE TABLE #GenerateCreateDefaults
    (
        RowId INT NOT NULL IDENTITY(1, 1),
        [SchemaName] NVARCHAR(128),
        [TableName] NVARCHAR(128),
        [object_id] INT,
        Colum_Id INT,
        [Coluna] NVARCHAR(128),
        [default_constraintsName] NVARCHAR(128),
        [default_constraintsDefinition] NVARCHAR(MAX),
        [Script] NVARCHAR(MAX)
            PRIMARY KEY
            (
                [object_id],
                Colum_Id,
                RowId
            )
    );





    IF (OBJECT_ID('TEMPDB..#GenerateCreateIndex') IS NOT NULL)
        DROP TABLE #GenerateCreateIndex;

    CREATE TABLE #GenerateCreateIndex
    (
        RowId INT NOT NULL IDENTITY(1, 1),
        [ObjectName] VARCHAR(300),
        [ObjectId] INT,
        [IndexName] VARCHAR(400),
        Collum_Id INT,
        CollumName VARCHAR(128),
        [ScriptCreate] NVARCHAR(3000)
            PRIMARY KEY
            (
                [ObjectId],
                Collum_Id,
                RowId
            )
    );


    IF (OBJECT_ID('TEMPDB..#GenerateCreateStats') IS NOT NULL)
        DROP TABLE #GenerateCreateStats;

    CREATE TABLE #GenerateCreateStats
    (
        RowId INT NOT NULL IDENTITY(1, 1),
        [SchemaName] NVARCHAR(128),
        [TableName] NVARCHAR(128),
        [Rows] INT,
        [object_id] INT,
        [Coluna] NVARCHAR(128),
        Collum_Id INT,
        [StatisticasName] NVARCHAR(128),
        [ScriptCreate] NVARCHAR(403)
            PRIMARY KEY
            (
                [object_id],
                Collum_Id,
                RowId
            )
    );


    IF (OBJECT_ID('TEMPDB..#GenerateDeleteDefaults') IS NOT NULL)
        DROP TABLE #GenerateDeleteDefaults;

    CREATE TABLE #GenerateDeleteDefaults
    (
        RowId INT NOT NULL IDENTITY(1, 1),
        [SchemaName] NVARCHAR(128),
        [TableName] NVARCHAR(128),
        [object_id] INT,
        Colum_Id INT,
        [Coluna] NVARCHAR(128),
        [default_constraintsName] NVARCHAR(128),
        [default_constraintsDefinition] NVARCHAR(MAX),
        [Script] NVARCHAR(420)
            PRIMARY KEY
            (
                [object_id],
                Colum_Id,
                RowId
            )
    );

    IF (OBJECT_ID('TEMPDB..#GenerateDeleteCheck') IS NOT NULL)
        DROP TABLE #GenerateDeleteCheck;

    CREATE TABLE #GenerateDeleteCheck
    (
        RowId INT NOT NULL IDENTITY(1, 1),
        [SchemaName] NVARCHAR(128),
        [TableName] NVARCHAR(128),
        [object_id] INT,
        Colum_Id INT,
        [Coluna] NVARCHAR(128),
        [CconstraintsName] NVARCHAR(128),
        [ConstraintsDefinition] NVARCHAR(MAX),
        [Script] NVARCHAR(420)
            PRIMARY KEY
            (
                [object_id],
                Colum_Id,
                RowId
            )
    );



    IF (OBJECT_ID('TEMPDB..#GenerateDeleteStats') IS NOT NULL)
        DROP TABLE #GenerateDeleteStats;

    CREATE TABLE #GenerateDeleteStats
    (
        RowId INT NOT NULL IDENTITY(1, 1),
        [SchemaName] NVARCHAR(128),
        [TableName] NVARCHAR(128),
        [Rows] INT,
        [object_id] INT,
        [Coluna] NVARCHAR(128),
        Collum_Id INT,
        [StatisticasName] NVARCHAR(128),
        [ScriptDrop] NVARCHAR(403)
            PRIMARY KEY
            (
                [object_id],
                Collum_Id,
                RowId
            )
    );


    IF (OBJECT_ID('TEMPDB..#GenerateDeleteIndex') IS NOT NULL)
        DROP TABLE #GenerateDeleteIndex;


    CREATE TABLE #GenerateDeleteIndex
    (
        RowId INT NOT NULL IDENTITY(1, 1),
        [SchemaName] NVARCHAR(128),
        [TableName] NVARCHAR(128),
        [object_id] INT,
        [IndexName] NVARCHAR(128),
        Collum_Id INT,
        CollumName VARCHAR(128),
        [DeleteScript] NVARCHAR(403)
            PRIMARY KEY
            (
                [object_id],
                Collum_Id,
                RowId
            )
    );



    IF (OBJECT_ID('TEMPDB..#Indices') IS NOT NULL)
        DROP TABLE #Indices;

    CREATE TABLE #Indices
    (
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
        [CountPageSplitPage] INT,
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
        [TypeIndex] TINYINT
    );


    IF (OBJECT_ID('TEMPDB..#GenerateAlterTable') IS NOT NULL)
        DROP TABLE #GenerateAlterTable;

    CREATE TABLE #GenerateAlterTable
    (
        RowId INT NOT NULL IDENTITY(1, 1),
        [SchemaName] NVARCHAR(128),
        [TableName] NVARCHAR(128),
        [object_id] INT,
        [Coluna] NVARCHAR(128),
        [Type] NVARCHAR(128),
        [max_length] SMALLINT,
        [column_id] INT,
        [is_nullable] BIT,
        [NovoTipo] NVARCHAR(128),
        [ScriptCreate] NVARCHAR(3000)
            PRIMARY KEY
            (
                [object_id],
                RowId
            )
    );



    IF (OBJECT_ID('TEMPDB..#GenerateDropContraints') IS NOT NULL)
        DROP TABLE #GenerateDropContraints;

    CREATE TABLE #GenerateDropContraints
    (
        [SchemaName] NVARCHAR(128),
        [TableName] NVARCHAR(128),
        ObjectId INT,
        [ObjecName] NVARCHAR(128),
        [type_desc] NVARCHAR(60),
        [column_id] INT,
        [ColummName] NVARCHAR(128),
        [Script] NVARCHAR(414)
    );


    CREATE NONCLUSTERED INDEX IxGenerateDropContraints
    ON #GenerateDropContraints
    (
        TableName,
        column_id
    );




    IF (OBJECT_ID('TEMPDB..#DefaultConstraints') IS NOT NULL)
        DROP TABLE #DefaultConstraints;

    CREATE TABLE #DefaultConstraints
    (
        [SchemaName] NVARCHAR(128),
        [TableName] NVARCHAR(128),
        [object_id] INT,
        [Coluna] NVARCHAR(128),
        [column_id] INT,
        [type] NVARCHAR(128),
        [default_constraintsName] NVARCHAR(128),
        [default_constraintsType] NVARCHAR(60),
        [default_constraintsDefinition] NVARCHAR(MAX)
            PRIMARY KEY
            (
                object_id,
                column_id
            )
    );


    IF (OBJECT_ID('TEMPDB..#ObjetosExcecoes') IS NOT NULL)
        DROP TABLE #ObjetosExcecoes;

    CREATE TABLE #ObjetosExcecoes
    (
        SchemaName VARCHAR(128),
        TableName VARCHAR(128),
        Coluna VARCHAR(128)
    );




    IF (OBJECT_ID('TEMPDB..#CamposExcecoes') IS NOT NULL)
        DROP TABLE #CamposExcecoes;


    CREATE TABLE #CamposExcecoes (Name VARCHAR(200));
    INSERT INTO #CamposExcecoes
    (
        Name
    )
    VALUES ('%Total%'),
    --  ('Numero'),
    ('%Saldo%'),
    ('%Acumulado%');





    IF (OBJECT_ID('TEMPDB..#CamposPreferencialmenteDecimal9') IS NOT NULL)
        DROP TABLE #CamposPreferencialmenteDecimal9;


    CREATE TABLE #CamposPreferencialmenteDecimal9 (Coluna VARCHAR(200));
    INSERT INTO #CamposPreferencialmenteDecimal9
    (
        Coluna
    )
    VALUES ('%Parcela%');



    IF (OBJECT_ID('TEMPDB..#CamposDecimal9') IS NOT NULL)
        DROP TABLE #CamposDecimal9;

    CREATE TABLE #CamposDecimal9
    (
        SchemaName VARCHAR(128),
        TableName VARCHAR(128),
        Coluna VARCHAR(128),
    );





    IF (OBJECT_ID('TEMPDB..#SchemaExcecoes') IS NOT NULL)
        DROP TABLE #SchemaExcecoes;

    CREATE TABLE #SchemaExcecoes (Name VARCHAR(200));

    INSERT INTO #SchemaExcecoes
    (
        Name
    )
    VALUES ('HangFire'),
    ('HealthCheck');




    IF (OBJECT_ID('TEMPDB..#TabelasModificaveis') IS NOT NULL)
        DROP TABLE #TabelasModificaveis;


    CREATE TABLE #TabelasModificaveis
    (
        [SchemaName] NVARCHAR(128),
        [TableName] NVARCHAR(128),
        [Rows] INT,
        [object_id] INT,
        [Coluna] NVARCHAR(128),
        [Type] NVARCHAR(128),
        [max_length] SMALLINT,
        [column_id] INT,
        [is_nullable] BIT,
        [Indexable] BIT,
        [is_computed] BIT,
        [NovoTipo] NVARCHAR(128),
        PRIMARY KEY
        (
            object_id,
            column_id
        )
    );


    ;WITH DadosTabela
    AS (SELECT SchemaName = S.name,
               TableName = T.name,
               S2.Rows,
               [object_id] = C.object_id,
               [Coluna] = C.name COLLATE DATABASE_DEFAULT,
               [Type] = T2.name,
               C.max_length,
               C.column_id,
               C.is_nullable,
               CAST(COLUMNPROPERTYEX(C.object_id, C.name, 'IsIndexable') AS bit) AS Indexable,
               C.is_computed
        FROM sys.tables AS T
            JOIN sys.sysindexes S2
                ON T.OBJECT_ID = S2.id
                   AND S2.indid = 1
            JOIN sys.schemas AS S
                ON S.SCHEMA_ID = T.SCHEMA_ID
            JOIN sys.COLUMNS AS C
                ON C.OBJECT_ID = T.OBJECT_ID
            JOIN sys.types AS T2
                ON T2.system_type_id = C.system_type_id
        WHERE C.is_computed = 0
              AND C.PRECISION = 18
              AND C.scale = 2
              AND NOT EXISTS
        (
            SELECT 1
            FROM sys.computed_columns AS CC
            WHERE CC.definition LIKE CONCAT('%', C.name COLLATE DATABASE_DEFAULT, '%')
        )
       )
    INSERT INTO #CamposDecimal
    (
        SchemaName,
        TableName,
        Rows,
        object_id,
        Coluna,
        Type,
        max_length,
        column_id,
        is_nullable,
        Indexable,
        is_computed
    )
    SELECT R.*
    FROM DadosTabela R
        --INNER JOIN
        --(SELECT TPT.Coluna FROM # AS TPT) Filtro ON R.Coluna LIKE Filtro.Coluna
        LEFT JOIN
        (SELECT TPT.Name FROM #CamposExcecoes AS TPT) FiltroExc
            ON R.Coluna LIKE FiltroExc.Name
    WHERE [Type] = 'numeric'
          AND (
                  @ObjectIdTable IS NULL
                  OR (R.object_id = @ObjectIdTable)
              )
          AND FiltroExc.Name IS NULL;


    /* declare variables */
    DECLARE @SchemaName VARCHAR(128),
            @TableName VARCHAR(128),
            @Rows INT,
            @object_id INT,
            @Coluna VARCHAR(128),
            @Type VARCHAR(128),
            @max_length INT,
            @column_id TINYINT,
            @is_nullable BIT,
            @Indexable BIT,
            @is_computed BIT;




    /*%%%%%%%%%%%%%%%%%%%%%%%*/

    DECLARE cursor_CamposDecimal CURSOR FAST_FORWARD READ_ONLY FOR
    SELECT CDT.SchemaName,
           CDT.TableName,
           CDT.Rows,
           CDT.object_id,
           CDT.Coluna,
           CDT.Type,
           CDT.max_length,
           CDT.column_id,
           CDT.is_nullable,
           CDT.Indexable,
           CDT.is_computed
    FROM #CamposDecimal AS CDT
    WHERE CDT.Rows > 0
          AND (
                  (
                      CDT.TableName NOT LIKE '%Imovei%'
                      AND CDT.TableName NOT LIKE '%empenh%'
                      AND CDT.TableName NOT LIKE '%liqu%'
                      AND CDT.TableName NOT LIKE '%pag%'
                      AND CDT.TableName NOT LIKE '%contrato%'
                      AND CDT.TableName NOT LIKE '%licita%'
                      AND CDT.TableName NOT LIKE '%TCU%'
                      AND CDT.TableName NOT LIKE '%Dota%'
                      AND CDT.TableName NOT LIKE '%Refor%'
                      AND CDT.TableName NOT LIKE '%Transposicoes%'
                      AND CDT.TableName NOT LIKE '%Lanc%'
                      AND CDT.TableName <> 'Movimentos'
                  )
                  AND (CDT.SchemaName NOT LIKE '%TCU%')
                  AND (
                          CDT.Coluna NOT LIKE '%Orcado%'
                          AND CDT.Coluna NOT LIKE '%Inicial%'
                          AND CDT.Coluna NOT LIKE '%Principal%'
                          AND CDT.Coluna NOT LIKE '%Empenhado%'
                          AND CDT.Coluna NOT LIKE '%ExercicioAnterior%'
                          AND CDT.Coluna NOT LIKE '%ExercicioAtual%'
                          AND CDT.Coluna NOT LIKE '%Calcu%'
                          AND CDT.Coluna NOT LIKE '%Sequencial%'
                          AND CDT.Coluna NOT LIKE '%Contrato%'
                          AND CDT.Coluna NOT LIKE '%ValorDevido%'
                          AND CDT.Coluna NOT LIKE '%Pag%'
                          AND CDT.Coluna NOT LIKE '%Atual%'
                      )
              );

    OPEN cursor_CamposDecimal;

    FETCH NEXT FROM cursor_CamposDecimal
    INTO @SchemaName,
         @TableName,
         @Rows,
         @object_id,
         @Coluna,
         @Type,
         @max_length,
         @column_id,
         @is_nullable,
         @Indexable,
         @is_computed;





    WHILE @@FETCH_STATUS = 0
    BEGIN


        DECLARE @Sql NVARCHAR(3000);
        DECLARE @SqlInsertTempTableNumeric92 NVARCHAR(2000);
        DECLARE @SqlInsertTempTableDate NVARCHAR(2000);



        SET @Sql
            = CONCAT('IF (EXISTS (SELECT 1 FROM ', SPACE(1), QUOTENAME(@SchemaName), '.', QUOTENAME(@TableName), '))');
        SET @Sql += CONCAT(SPACE(1), 'BEGIN', SPACE(1));
        SET @Sql += CONCAT(SPACE(1), 'IF (EXISTS (   SELECT MAX(', @Coluna, ')');
        SET @Sql += CONCAT(SPACE(1), 'FROM ', QUOTENAME(@SchemaName), '.', QUOTENAME(@TableName), '');
        SET @Sql += CONCAT(SPACE(1), ' HAVING TRY_CAST(MAX(', @Coluna, ') AS NUMERIC(9, 2)) IS NOT NULL ))');

        SET @Sql += CONCAT(SPACE(1), 'BEGIN');


        SET @SqlInsertTempTableNumeric92
            = CONCAT(
                        SPACE(2),
                        'INSERT INTO #TabelasModificaveis  VALUES (',
                        CHAR(39),
                        @SchemaName,
                        CHAR(39),
                        ',',
                        CHAR(39),
                        @TableName,
                        CHAR(39),
                        ',',
                        CHAR(39),
                        @Rows,
                        CHAR(39),
                        ',',
                        CHAR(39),
                        @object_id,
                        CHAR(39),
                        ',',
                        CHAR(39),
                        @Coluna,
                        CHAR(39),
                        ',',
                        CHAR(39),
                        @Type,
                        CHAR(39),
                        ',',
                        CHAR(39),
                        @max_length,
                        CHAR(39),
                        ',',
                        CHAR(39),
                        @column_id,
                        CHAR(39),
                        ',',
                        CHAR(39),
                        @is_nullable,
                        CHAR(39),
                        ',',
                        CHAR(39),
                        @Indexable,
                        CHAR(39),
                        ',',
                        CHAR(39),
                        @is_computed,
                        CHAR(39),
                        ',',
                        CHAR(39),
                        'NUMERIC(9,2)',
                        CHAR(39),
                        SPACE(2),
                        ')'
                    );



        SET @Sql += @SqlInsertTempTableNumeric92;
        SET @Sql += CONCAT(SPACE(1), 'END  END');

        DECLARE @HasErrorOnInsertSelect INT = 0;

        PRINT @Sql;
        EXEC @HasErrorOnInsertSelect = sys.sp_executesql @Sql;

        IF (@HasErrorOnInsertSelect <> 0)
        BEGIN

            SELECT 'Esse Script deu Erro!';
            SELECT @Sql;
            BREAK;
        END;






        FETCH NEXT FROM cursor_CamposDecimal
        INTO @SchemaName,
             @TableName,
             @Rows,
             @object_id,
             @Coluna,
             @Type,
             @max_length,
             @column_id,
             @is_nullable,
             @Indexable,
             @is_computed;
    END;

    CLOSE cursor_CamposDecimal;
    DEALLOCATE cursor_CamposDecimal;



    /*%%%%%%%%%%%%%%%%%%%*/







    INSERT INTO #Reducao
    SELECT TM.SchemaName,
           TM.TableName,
           TM.Rows,
           TM.Coluna,
           TM.Type,
           'NUMERIC(9,2)' AS NewType,
           (TM.Rows * @TamanhoDecimal18) TamanhoAtualParaColunaBytes,
           (TM.Rows * @TamanhoDecimal9) AS ReducaoBytes,
           ((TM.Rows * @TamanhoDecimal18) / 8060) AS TamanhoAtualParaColunaPaginas,
           ((TM.Rows * @TamanhoDecimal9) / 8060) AS TamanhoResuzidoParaColunaPaginas
    FROM #TabelasModificaveis AS TM
    ORDER BY TM.Rows DESC;



    IF (@ObjectIdTable IS NOT NULL)
    BEGIN

        DELETE D
        FROM #TabelasModificaveis D
        WHERE D.object_id <> @ObjectIdTable;
    END;




    INSERT INTO #DefaultConstraints
    SELECT TM.SchemaName,
           TM.TableName,
           TM.object_id,
           TM.Coluna,
           TM.column_id,
           TM.Type,
           DC.name AS default_constraintsName,
           DC.type_desc AS default_constraintsType,
           DC.definition AS default_constraintsDefinition
    FROM #TabelasModificaveis AS TM
        JOIN sys.default_constraints AS DC
            ON TM.object_id = DC.parent_object_id
               AND TM.column_id = DC.parent_column_id;


    INSERT INTO #CheckContraints
    SELECT TM.*,
           CC.name AS ConstraintsName,
           CC.type_desc ConstraintsType,
           CC.definition ConstraintsDefinition
    FROM #TabelasModificaveis AS TM
        JOIN sys.check_constraints AS CC
            ON TM.object_id = CC.parent_object_id
               AND TM.column_id = CC.parent_column_id;




    INSERT INTO #Indices
    EXEC HealthCheck.uspAllIndex @typeIndex = 'NONCLUSTERED',      -- varchar(40)
                                 @SomenteUsado = NULL,             -- bit
                                 @TableIsEmpty = NULL,             -- bit
                                 @ObjectName = NULL,               -- varchar(128)
                                 @BadIndex = NULL,                 -- bit
                                 @percentualAproveitamento = NULL; -- smallint



    INSERT INTO #Statisticas
    SELECT T.name AS TableNamee,
           T.object_id,
           S.name AS StatisticasName,
           S.stats_id,
           S.has_filter,
           S.filter_definition,
           S.stats_generation_method_desc,
           SC.column_id
    FROM sys.tables AS T
        JOIN sys.stats AS S
            ON T.object_id = S.object_id
        JOIN sys.stats_columns AS SC
            ON S.object_id = SC.object_id
               AND S.stats_id = SC.stats_id
    WHERE (
              S.name LIKE '__WA%' ESCAPE '_'
              OR S.name LIKE 'S%'
          )
          AND EXISTS
    (
        SELECT 1
        FROM #TabelasModificaveis AS TM
        WHERE TM.object_id = T.object_id
              AND SC.column_id = TM.column_id
    );

    INSERT INTO #TempIndex
    SELECT T.object_id,
           T.name AS TableName,
           I.name AS IndexName,
           I.type_desc,
           IC.column_id,
           IC.key_ordinal
    FROM sys.tables AS T
        JOIN sys.indexes AS I
            ON T.object_id = I.object_id
        JOIN sys.index_columns AS IC
            ON I.object_id = IC.object_id
               AND I.index_id = IC.index_id
    WHERE I.type_desc = 'NONCLUSTERED'
          AND I.is_unique_constraint = 0
          AND EXISTS
    (
        SELECT 1
        FROM #TabelasModificaveis AS TM
        WHERE TM.object_id = T.object_id
              AND IC.column_id = TM.column_id
    );




    INSERT INTO #GenerateDropContraints
    SELECT SCHEMA_NAME(KC.schema_id) AS SchemaName,
           OBJECT_NAME(KC.parent_object_id) AS TableName,
           KC.parent_object_id,
           KC.name AS ObjecName,
           KC.type_desc,
           IC.column_id,
           C.name AS ColummName,
           Script = CONCAT(
                              'ALTER TABLE',
                              SPACE(1),
                              SCHEMA_NAME(KC.schema_id),
                              '.',
                              OBJECT_NAME(KC.parent_object_id),
                              SPACE(1),
                              'DROP CONSTRAINT ',
                              KC.name
                          )
    FROM sys.key_constraints AS KC
        JOIN sys.indexes AS I
            ON KC.parent_object_id = I.object_id
               AND KC.unique_index_id = I.index_id
        JOIN sys.index_columns AS IC
            ON I.object_id = IC.object_id
               AND I.index_id = IC.index_id
        JOIN sys.columns AS C
            ON I.object_id = C.object_id
               AND IC.column_id = C.column_id
    WHERE KC.type <> 'PK'
          AND EXISTS
    (
        SELECT 1
        FROM #TabelasModificaveis AS Tm2
        WHERE Tm2.object_id = I.object_id
              AND Tm2.Coluna COLLATE DATABASE_DEFAULT = C.name COLLATE DATABASE_DEFAULT
    );



    INSERT INTO #GenerateDeleteDefaults
    SELECT Def.SchemaName,
           Def.TableName,
           Def.object_id,
           Def.column_id,
           Def.Coluna,
           Def.default_constraintsName,
           Def.default_constraintsDefinition,
           Script = CONCAT(
                              ' ALTER TABLE ',
                              SPACE(1),
                              Def.SchemaName,
                              '.',
                              Def.TableName,
                              SPACE(1),
                              ' DROP CONSTRAINT ',
                              SPACE(1),
                              Def.default_constraintsName,
                              ' ;'
                          )
    FROM #DefaultConstraints Def;


    INSERT INTO #GenerateDeleteCheck
    SELECT CC.SchemaName,
           CC.TableName,
           CC.object_id,
           CC.column_id,
           CC.Coluna,
           CC.ConstraintsName,
           CC.ConstraintsDefinition,
           Script = CONCAT(
                              ' ALTER TABLE ',
                              SPACE(1),
                              CC.SchemaName,
                              '.',
                              CC.TableName,
                              SPACE(1),
                              ' DROP CONSTRAINT ',
                              SPACE(1),
                              CC.ConstraintsName,
                              ' ;'
                          )
    FROM #CheckContraints AS CC;



    INSERT INTO #GenerateCreateCheckContraint
    SELECT CC.SchemaName,
           CC.TableName,
           CC.object_id,
           CC.column_id,
           CC.Coluna,
           CC.ConstraintsName,
           CC.ConstraintsDefinition,
           Script = CONCAT(
                              ' ALTER TABLE ',
                              SPACE(1),
                              CC.SchemaName,
                              '.',
                              CC.TableName,
                              SPACE(1),
                              ' ADD CONSTRAINT ',
                              SPACE(1),
                              CC.ConstraintsName,
                              SPACE(1),
                              'CHECK (',
                              STUFF(
                                       CC.ConstraintsDefinition,
                                       (CHARINDEX('))', CC.ConstraintsDefinition, 0) + 1),
                                       10,
                                       ' AND [Valor] <=9999999.99 )'
                                   ),
                              ')',
                              ' ;'
                          )
    FROM #CheckContraints AS CC;




    INSERT INTO #GenerateCreateDefaults
    SELECT Def.SchemaName,
           Def.TableName,
           Def.object_id,
           Def.column_id,
           Def.Coluna,
           Def.default_constraintsName,
           Def.default_constraintsDefinition,
           Script = CONCAT(
                              ' ALTER TABLE ',
                              SPACE(1),
                              Def.SchemaName,
                              '.',
                              Def.TableName,
                              SPACE(1),
                              ' ADD CONSTRAINT ',
                              SPACE(1),
                              Def.default_constraintsName,
                              SPACE(1),
                              'DEFAULT',
                              SPACE(1),
                              Def.default_constraintsDefinition,
                              SPACE(1),
                              'FOR',
                              SPACE(1),
                              Def.Coluna,
                              ' ;'
                          )
    FROM #DefaultConstraints Def;

    INSERT INTO #GenerateDeleteStats
    SELECT TM.SchemaName,
           TM.TableName,
           TM.Rows,
           TM.object_id,
           TM.Coluna,
           S.column_id,
           S.StatisticasName,
           ScriptDrop = CONCAT('DROP STATISTICS ', SPACE(1), TM.SchemaName, '.', TM.TableName, '.', S.StatisticasName)
    FROM #TabelasModificaveis AS TM
        JOIN #Statisticas AS S
            ON TM.object_id = S.object_id
               AND TM.column_id = S.column_id;





    INSERT INTO #GenerateCreateStats
    SELECT TM.SchemaName,
           TM.TableName,
           TM.Rows,
           TM.object_id,
           TM.Coluna,
           S.column_id,
           S.StatisticasName,
           ScriptCreate = CONCAT(
                                    'CREATE STATISTICS ',
                                    SPACE(1),
                                    CONCAT('Stats_', TM.SchemaName, S.TableName, TM.Coluna),
                                    ' ON ',
                                    TM.SchemaName,
                                    '.',
                                    TM.TableName,
                                    '(',
                                    TM.Coluna,
                                    ')'
                                )
    FROM #TabelasModificaveis AS TM
        JOIN #Statisticas AS S
            ON TM.object_id = S.object_id
               AND TM.column_id = S.column_id;




    INSERT INTO #GenerateDeleteIndex
    SELECT DISTINCT
        TM.SchemaName,
        TI.TableName,
        TI.object_id,
        TI.IndexName,
        TM.column_id,
        TM.Coluna,
        DeleteScript = CONCAT(
                                 ' DROP INDEX ',
                                 SPACE(1),
                                 TI.IndexName,
                                 ' ON ',
                                 TM.SchemaName,
                                 '.',
                                 TI.TableName,
                                 SPACE(1)
                             )
    FROM #TempIndex AS TI
        JOIN #TabelasModificaveis AS TM
            ON TI.object_id = TM.object_id
               AND TI.column_id = TM.column_id;



    INSERT INTO #GenerateCreateIndex
    SELECT DISTINCT
        I.ObjectName,
        I.ObjectId,
        I.IndexName,
        GDI.Collum_Id,
        GDI.CollumName,
        ScriptCreate = CONCAT(
                                 ' CREATE ',
                                 CASE
                                     WHEN I.IsUniqueConstraint = 1
                                          OR I.IsUnique = 1 THEN
                                         ' UNIQUE '
                                 END,
                                 ' NONCLUSTERED INDEX',
                                 SPACE(1),
                                 CAST(I.IndexName AS VARCHAR(150)),
                                 ' ON ',
                                 I.ObjectName,
                                 '(',
                                 I.Chave,
                                 ')',
                                 CASE
                                     WHEN I.ColunasIncluidas IS NOT NULL THEN
                                         ' INCLUDE(' + I.ColunasIncluidas + ')'
                                 END,
                                 SPACE(1),
                                 ' WITH(FILLFACTOR = 100 ',
                                 ')',
                                 SPACE(1)
                             )
    FROM #Indices AS I
        JOIN #GenerateDeleteIndex AS GDI
            ON I.IndexName = GDI.IndexName
    WHERE I.ObjectId IN (
                            SELECT TM.object_id FROM #TabelasModificaveis AS TM
                        )
          AND CAST(I.IndexName AS VARCHAR(200))IN (
                                                      SELECT DISTINCT
                                                          CAST(TI.IndexName AS VARCHAR(200))
                                                      FROM #TempIndex AS TI
                                                          JOIN #TabelasModificaveis AS TM
                                                              ON TI.object_id = TM.object_id
                                                                 AND TI.column_id = TM.column_id
                                                  );



    INSERT INTO #GenerateAlterTable
    SELECT TM.SchemaName,
           TM.TableName,
           TM.object_id,
           TM.Coluna,
           TM.Type,
           TM.max_length,
           TM.column_id,
           TM.is_nullable,
           TM.NovoTipo,
           ScriptCreate = CONCAT(
                                    ' ALTER TABLE ',
                                    SPACE(1),
                                    TM.SchemaName,
                                    '.',
                                    TM.TableName,
                                    SPACE(1),
                                    ' ALTER COLUMN ',
                                    SPACE(1),
                                    TM.Coluna,
                                    SPACE(1),
                                    TM.NovoTipo,
                                    (CASE
                                         WHEN TM.is_nullable = 0 THEN
                                             ' NOT NULL '
                                     END
                                    ),
                                    ' ;',
                                    SPACE(1)
                                )
    FROM #TabelasModificaveis AS TM;



    IF (@Efetivar = 1)
    BEGIN


        /* declare variables */
        DECLARE @object_idAlter INT,
                @TableNameAlter VARCHAR(128),
                @ColunaAlter VARCHAR(128),
                @column_idAlter INT,
                @ScriptCreateAlter NVARCHAR(500);


        DECLARE cursor_AlteraColuna CURSOR FAST_FORWARD READ_ONLY FOR
        SELECT GAT.object_id,
               GAT.TableName,
               GAT.Coluna,
               GAT.column_id,
               GAT.ScriptCreate
        FROM #GenerateAlterTable AS GAT
        ORDER BY GAT.TableName;




        OPEN cursor_AlteraColuna;

        FETCH NEXT FROM cursor_AlteraColuna
        INTO @object_idAlter,
             @TableNameAlter,
             @ColunaAlter,
             @column_idAlter,
             @ScriptCreateAlter;

        WHILE @@FETCH_STATUS = 0
        BEGIN

            BEGIN TRY
                BEGIN TRANSACTION Task;

                DECLARE @TempScript NVARCHAR(1000);
                DECLARE @HasError INT = 0;

                IF (EXISTS
                (
                    SELECT *
                    FROM #GenerateDeleteCheck CK
                    WHERE CK.object_id = @object_idAlter
                          AND CK.Colum_Id = @column_idAlter
                )
                   )
                BEGIN


                    SET @TempScript =
                    (
                        SELECT DE.Script
                        FROM #GenerateDeleteCheck DE
                        WHERE DE.object_id = @object_idAlter
                              AND DE.Colum_Id = @column_idAlter
                    );


                    PRINT @TempScript;
                    EXEC @HasError = sys.sp_executesql @TempScript;

                    IF (@HasError <> 0)
                    BEGIN

                        SELECT 'Deu Erro';
                        SELECT @TempScript;
                        BREAK;
                    END;

                END;

                SET @TempScript = '';

                IF (EXISTS
                (
                    SELECT *
                    FROM #GenerateDropContraints CK
                    WHERE CK.ObjectId = @object_idAlter
                          AND CK.column_id = @column_idAlter
                )
                   )
                BEGIN



                    SET @TempScript =
                    (
                        SELECT DE.Script
                        FROM #GenerateDropContraints DE
                        WHERE DE.ObjectId = @object_idAlter
                              AND DE.column_id = @column_idAlter
                    );


                    PRINT @TempScript;
                    EXEC @HasError = sys.sp_executesql @TempScript;

                    IF (@HasError <> 0)
                    BEGIN

                        SELECT 'Deu Erro';
                        SELECT @TempScript;
                        BREAK;
                    END;

                END;
                SET @TempScript = '';




                IF (EXISTS
                (
                    SELECT *
                    FROM #GenerateDeleteIndex CK
                    WHERE CK.object_id = @object_idAlter
                          AND CK.Collum_Id = @column_idAlter
                )
                   )
                BEGIN

                    /* declare variables */
                    DECLARE @DeleteIndex NVARCHAR(1000);

                    DECLARE cursor_DeleteIndex CURSOR FAST_FORWARD READ_ONLY FOR
                    SELECT DE.DeleteScript
                    FROM #GenerateDeleteIndex DE
                    WHERE DE.object_id = @object_idAlter
                          AND DE.Collum_Id = @column_idAlter;

                    OPEN cursor_DeleteIndex;

                    FETCH NEXT FROM cursor_DeleteIndex
                    INTO @DeleteIndex;

                    WHILE @@FETCH_STATUS = 0
                    BEGIN

                        PRINT @TempScript;
                        EXEC @HasError = sys.sp_executesql @DeleteIndex;

                        IF (@HasError <> 0)
                        BEGIN

                            SELECT 'Deu Erro';
                            SELECT @DeleteIndex;
                            BREAK;
                        END;


                        SET @TempScript = '';

                        FETCH NEXT FROM cursor_DeleteIndex
                        INTO @DeleteIndex;
                    END;

                    CLOSE cursor_DeleteIndex;
                    DEALLOCATE cursor_DeleteIndex;

                END;
                SET @TempScript = '';


                --/*Delete Stats*/
                IF (EXISTS
                (
                    SELECT *
                    FROM #GenerateDeleteStats DE
                    WHERE DE.object_id = @object_idAlter
                          AND DE.Collum_Id = @column_idAlter
                )
                   )
                BEGIN

                    /* declare variables */
                    DECLARE @DeleteStats NVARCHAR(1000);

                    DECLARE cursor_DeleteStats CURSOR FAST_FORWARD READ_ONLY FOR
                    SELECT DE.ScriptDrop
                    FROM #GenerateDeleteStats DE
                    WHERE DE.object_id = @object_idAlter
                          AND DE.Collum_Id = @column_idAlter;

                    OPEN cursor_DeleteStats;

                    FETCH NEXT FROM cursor_DeleteStats
                    INTO @DeleteStats;

                    WHILE @@FETCH_STATUS = 0
                    BEGIN

                        PRINT @DeleteStats;
                        EXEC @HasError = sys.sp_executesql @DeleteStats;

                        IF (@HasError <> 0)
                        BEGIN

                            SELECT 'Deu Erro';
                            SELECT @DeleteStats;
                            BREAK;
                        END;


                        SET @TempScript = '';

                        FETCH NEXT FROM cursor_DeleteStats
                        INTO @DeleteStats;
                    END;

                    CLOSE cursor_DeleteStats;
                    DEALLOCATE cursor_DeleteStats;


                END;
                SET @TempScript = '';


                IF (EXISTS
                (
                    SELECT *
                    FROM #GenerateDeleteDefaults CK
                    WHERE CK.object_id = @object_idAlter
                          AND CK.Colum_Id = @column_idAlter
                )
                   )
                BEGIN



                    SET @TempScript =
                    (
                        SELECT CK.Script
                        FROM #GenerateDeleteDefaults CK
                        WHERE CK.object_id = @object_idAlter
                              AND CK.Colum_Id = @column_idAlter
                    );


                    PRINT @TempScript;
                    EXEC @HasError = sys.sp_executesql @TempScript;

                    IF (@HasError <> 0)
                    BEGIN

                        SELECT 'Deu Erro';
                        SELECT @TempScript;
                        BREAK;
                    END;

                END;
                SET @TempScript = '';


                IF (@HasError = 0)
                BEGIN
                    PRINT @ScriptCreateAlter;
                    EXEC @HasError = sys.sp_executesql @ScriptCreateAlter;

                    IF (@HasError <> 0)
                    BEGIN
                        SELECT 'Deu erro no Script Abaixo';
                        SELECT @ScriptCreateAlter;
                        BREAK;
                    END;

                    SET @TempScript = '';

                END;


                IF (EXISTS
                (
                    SELECT *
                    FROM #GenerateCreateDefaults CK
                    WHERE CK.object_id = @object_idAlter
                          AND CK.Colum_Id = @column_idAlter
                )
                   )
                BEGIN



                    SET @TempScript =
                    (
                        SELECT CK.Script
                        FROM #GenerateCreateDefaults CK
                        WHERE CK.object_id = @object_idAlter
                              AND CK.Colum_Id = @column_idAlter
                    );


                    PRINT @TempScript;
                    EXEC @HasError = sys.sp_executesql @TempScript;

                    IF (@HasError <> 0)
                    BEGIN

                        SELECT 'Deu Erro';
                        SELECT @TempScript;
                        BREAK;
                    END;

                END;


                IF (EXISTS
                (
                    SELECT *
                    FROM #GenerateCreateCheckContraint CK
                    WHERE CK.object_id = @object_idAlter
                          AND CK.Colum_Id = @column_idAlter
                )
                   )
                BEGIN



                    SET @TempScript =
                    (
                        SELECT CK.Script
                        FROM #GenerateCreateCheckContraint CK
                        WHERE CK.object_id = @object_idAlter
                              AND CK.Colum_Id = @column_idAlter
                    );


                    PRINT @TempScript;
                    EXEC @HasError = sys.sp_executesql @TempScript;

                    IF (@HasError <> 0)
                    BEGIN

                        SELECT 'Deu Erro';
                        SELECT @TempScript;
                        BREAK;
                    END;

                END;

                IF (EXISTS
                (
                    SELECT *
                    FROM #GenerateCreateIndex AS DE
                    WHERE DE.ObjectId = @object_idAlter
                          AND DE.Collum_Id = @column_idAlter
                )
                   )
                BEGIN

                    /* declare variables */
                    DECLARE @CreateIndex NVARCHAR(1000);

                    DECLARE cursor_CreateIndex CURSOR FAST_FORWARD READ_ONLY FOR
                    SELECT DE.ScriptCreate
                    FROM #GenerateCreateIndex DE
                    WHERE DE.ObjectId = @object_idAlter
                          AND DE.Collum_Id = @column_idAlter;

                    OPEN cursor_CreateIndex;

                    FETCH NEXT FROM cursor_CreateIndex
                    INTO @CreateIndex;

                    WHILE @@FETCH_STATUS = 0
                    BEGIN

                        PRINT @CreateIndex;
                        EXEC @HasError = sys.sp_executesql @CreateIndex;

                        IF (@HasError <> 0)
                        BEGIN

                            SELECT 'Deu Erro';
                            SELECT @CreateIndex;
                            BREAK;
                        END;


                        SET @TempScript = '';

                        FETCH NEXT FROM cursor_CreateIndex
                        INTO @CreateIndex;
                    END;

                    CLOSE cursor_CreateIndex;
                    DEALLOCATE cursor_CreateIndex;


                END;
                SET @TempScript = '';



                IF (EXISTS
                (
                    SELECT *
                    FROM #GenerateCreateStats AS DE
                    WHERE DE.object_id = @object_idAlter
                          AND DE.Collum_Id = @column_idAlter
                )
                   )
                BEGIN

                    /* declare variables */
                    DECLARE @CreateStats NVARCHAR(400);

                    DECLARE cursor_CreateStats CURSOR FAST_FORWARD READ_ONLY FOR
                    SELECT DE.ScriptCreate
                    FROM #GenerateCreateStats DE
                    WHERE DE.object_id = @object_idAlter
                          AND DE.Collum_Id = @column_idAlter;

                    OPEN cursor_CreateStats;

                    FETCH NEXT FROM cursor_CreateStats
                    INTO @CreateStats;

                    WHILE @@FETCH_STATUS = 0
                    BEGIN

                        PRINT @CreateStats;
                        EXEC @HasError = sys.sp_executesql @CreateStats;

                        IF (@HasError <> 0)
                        BEGIN

                            SELECT 'Deu Erro';
                            SELECT @CreateStats;
                            BREAK;
                        END;


                        SET @TempScript = '';

                        FETCH NEXT FROM cursor_CreateStats
                        INTO @CreateStats;
                    END;

                    CLOSE cursor_CreateStats;
                    DEALLOCATE cursor_CreateStats;


                END;
                SET @TempScript = '';


                COMMIT TRANSACTION Task;



                FETCH NEXT FROM cursor_AlteraColuna
                INTO @object_idAlter,
                     @TableNameAlter,
                     @ColunaAlter,
                     @column_idAlter,
                     @ScriptCreateAlter;

            END TRY
            BEGIN CATCH
                IF (@@TRANCOUNT > 0)
                BEGIN

                    ROLLBACK TRANSACTION Task;
                END;


                DECLARE @ErrorNumber INT = ERROR_NUMBER();
                DECLARE @ErrorLine INT = ERROR_LINE();
                DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
                DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
                DECLARE @ErrorState INT = ERROR_STATE();

                PRINT 'Actual error number: ' + CAST(@ErrorNumber AS VARCHAR(MAX));
                PRINT 'Actual line number: ' + CAST(@ErrorLine AS VARCHAR(MAX));
                PRINT '@ErrorMessage: ' + CAST(@ErrorMessage AS VARCHAR(MAX));
                PRINT '@ErrorSeverity: ' + CAST(@ErrorLine AS VARCHAR(MAX));
                PRINT '@ErrorState: ' + CAST(@ErrorLine AS VARCHAR(MAX));
                RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);

            END CATCH;

            Proximo:
            FETCH NEXT FROM cursor_AlteraColuna
            INTO @object_idAlter,
                 @TableNameAlter,
                 @ColunaAlter,
                 @column_idAlter,
                 @ScriptCreateAlter;
        END;

        CLOSE cursor_AlteraColuna;
        DEALLOCATE cursor_AlteraColuna;




    END;

    IF (@Visualizar = 1)
    BEGIN
        SELECT TM.*,
               CONCAT(
                         'SELECT  ',
                         CHAR(39),
                         TM.SchemaName,
                         '.',
                         TM.TableName,
                         CHAR(39),
                         ' AS Tabela ,',
                         CHAR(39),
                         TM.Coluna,
                         CHAR(39),
                         ' AS Coluna ,',
                         'MAX(RC.',
                         TM.Coluna,
                         ') ValorMaximoNaTabela FROM ',
                         TM.SchemaName,
                         '.',
                         TM.TableName,
                         ' AS RC',
                         SPACE(1),
                         ' UNION ALL'
                     ) AS ScriptAuditoria
        FROM #TabelasModificaveis AS TM
        ORDER BY TM.SchemaName,
                 TM.TableName;


        IF (@Visualizar = 1)
        BEGIN
            SELECT *
            FROM #Reducao AS R
            ORDER BY R.TamanhoAtualParaColunaPaginas DESC;

        END;


    END;
END;

