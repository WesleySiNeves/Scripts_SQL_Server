
/* ==================================================================
--Data: 29/11/2018 
--Autor :Wesley Neves
--Observação: 
Query De exemplo de rotinas que não entra [
SELECT PJ.DataFundacao,
       TRY_CAST(PJ.DataFundacao AS TIME)
  FROM Cadastro.PessoasJuridicas AS PJ
 WHERE PJ.DataFundacao IS NOT NULL
   AND TRY_CAST(PJ.DataFundacao AS TIME) <> '00:00:00.0000000';
 
-- ==================================================================
*/


--EXEC HealthCheck.uspAlteraCamposVarchar @ObjectName = NULL, -- varchar(200)
--                                        @Efetivar = 1, -- bit
--                                        @Visualizar = 1; -- bit
                                      


--CREATE OR ALTER PROCEDURE HealthCheck.uspAlteraCamposVarchar
--(
--    @ObjectName VARCHAR(200) = NULL,
--    @Efetivar BIT = 0,
--    @Visualizar BIT = 1
--)
--AS
--BEGIN

DECLARE @ObjectName VARCHAR(200) = NULL;
DECLARE @SomenteCamposDate BIT = NULL;
DECLARE @Efetivar BIT = 1;
DECLARE @Visualizar BIT = 1;



DECLARE @ObjectId INT = OBJECT_ID(@ObjectName);


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


 IF (OBJECT_ID('TEMPDB..#Statisticas') IS NOT NULL)
        DROP TABLE #Statisticas;

    CREATE TABLE #Statisticas
    (
        [TableNamee] NVARCHAR(128),
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



IF (OBJECT_ID('TEMPDB..#CamposVarchar') IS NOT NULL)
    DROP TABLE #CamposVarchar;


CREATE TABLE #CamposVarchar (
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
    [is_computed] BIT);

IF (OBJECT_ID('TEMPDB..#TabelasModificaveisParaChar') IS NOT NULL)
    DROP TABLE #TabelasModificaveisParaChar;


CREATE TABLE #TabelasModificaveisParaChar (
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
    [NewDatatype] VARCHAR(7));

	
    IF (OBJECT_ID('TEMPDB..#GenerateDeleteDefaults') IS NOT NULL)
        DROP TABLE #GenerateDeleteDefaults;

    CREATE TABLE #GenerateDeleteDefaults (
        RowId INT NOT NULL IDENTITY(1, 1),
        [SchemaName] NVARCHAR(128),
        [TableName] NVARCHAR(128),
        [object_id] INT,
        [Coluna] NVARCHAR(128),
        [default_constraintsName] NVARCHAR(128),
        [default_constraintsDefinition] NVARCHAR(MAX),
        [Script] NVARCHAR(420)
            PRIMARY KEY ([object_id], RowId));




    IF (OBJECT_ID('TEMPDB..#GenerateAlterTable') IS NOT NULL)
        DROP TABLE #GenerateAlterTable;

    CREATE TABLE #GenerateAlterTable (
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
            PRIMARY KEY ([object_id], RowId));


IF (OBJECT_ID('TEMPDB..#GenerateDropContraints') IS NOT NULL)
    DROP TABLE #GenerateDropContraints;

CREATE TABLE #GenerateDropContraints (
    RowId INT NOT NULL IDENTITY(1, 1),
    [SchemaName] NVARCHAR(128),
    [TableName] NVARCHAR(128),
    [ObjecName] NVARCHAR(128),
    [type_desc] NVARCHAR(60),
    Script VARCHAR(600));



IF (OBJECT_ID('TEMPDB..#GenerateCreateDefaults') IS NOT NULL)
    DROP TABLE #GenerateCreateDefaults;

CREATE TABLE #GenerateCreateDefaults (
    RowId INT NOT NULL IDENTITY(1, 1),
    [SchemaName] NVARCHAR(128),
    [TableName] NVARCHAR(128),
    [object_id] INT,
    [Coluna] NVARCHAR(128),
    [default_constraintsName] NVARCHAR(128),
    [default_constraintsDefinition] NVARCHAR(MAX),
    [Script] NVARCHAR(MAX)
        PRIMARY KEY ([object_id], RowId));


IF (OBJECT_ID('TEMPDB..#DefaultConstraints') IS NOT NULL)
    DROP TABLE #DefaultConstraints;

CREATE TABLE #DefaultConstraints (
    [SchemaName] NVARCHAR(128),
    [TableName] NVARCHAR(128),
    [object_id] INT,
    [Coluna] NVARCHAR(128),
    [column_id] INT,
    [type] NVARCHAR(128),
    [default_constraintsName] NVARCHAR(128),
    [default_constraintsType] NVARCHAR(60),
    [default_constraintsDefinition] NVARCHAR(MAX)
        PRIMARY KEY (object_id, column_id));




IF (OBJECT_ID('TEMPDB..#GenerateDeleteStats') IS NOT NULL)
    DROP TABLE #GenerateDeleteStats;

CREATE TABLE #GenerateDeleteStats (
    RowId INT NOT NULL IDENTITY(1, 1),
    [SchemaName] NVARCHAR(128),
    [TableName] NVARCHAR(128),
    [Rows] INT,
    [object_id] INT,
    [Coluna] NVARCHAR(128),
    [StatisticasName] NVARCHAR(128),
    [ScriptDrop] NVARCHAR(403)
        PRIMARY KEY ([object_id], RowId));


IF (OBJECT_ID('TEMPDB..#GenerateCreateStats') IS NOT NULL)
    DROP TABLE #GenerateCreateStats;

CREATE TABLE #GenerateCreateStats (
    RowId INT NOT NULL IDENTITY(1, 1),
    [SchemaName] NVARCHAR(128),
    [TableName] NVARCHAR(128),
    [Rows] INT,
    [object_id] INT,
    [Coluna] NVARCHAR(128),
    [StatisticasName] NVARCHAR(128),
    [ScriptCreate] NVARCHAR(403)
        PRIMARY KEY ([object_id], RowId));

IF (OBJECT_ID('TEMPDB..#GenerateDeleteIndex') IS NOT NULL)
    DROP TABLE #GenerateDeleteIndex;

CREATE TABLE #GenerateDeleteIndex (
    RowId INT NOT NULL IDENTITY(1, 1),
    [SchemaName] NVARCHAR(128),
    [TableName] NVARCHAR(128),
    [object_id] INT,
    [IndexName] NVARCHAR(128),
    [DeleteScript] NVARCHAR(403)
        PRIMARY KEY ([object_id], RowId));


IF (OBJECT_ID('TEMPDB..#GenerateCreateIndex') IS NOT NULL)
    DROP TABLE #GenerateCreateIndex;

CREATE TABLE #GenerateCreateIndex (
    RowId INT NOT NULL IDENTITY(1, 1),
    [ObjectName] VARCHAR(300),
    [ObjectId] INT,
    [IndexName] VARCHAR(400),
    [ScriptCreate] NVARCHAR(3000)
        PRIMARY KEY ([ObjectId], RowId));

IF (OBJECT_ID('TEMPDB..#SchemasExcecao') IS NOT NULL)
    DROP TABLE #SchemasExcecao;



CREATE TABLE #SchemasExcecao (ShemaName VARCHAR(128), );

INSERT INTO #SchemasExcecao
VALUES ('HangFire');



IF (OBJECT_ID('TEMPDB..#CamposExcecao') IS NOT NULL)
    DROP TABLE #CamposExcecao;



CREATE TABLE #CamposExcecao (TableName VARCHAR(128), CollumName VARCHAR(128) );

INSERT INTO #CamposExcecao
VALUES ('ConfiguracoesMacrorregioesCEPs','CEPFinal'),
('ConfiguracoesMacrorregioesCEPs','CEPInicial');



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





;WITH DadosTabela
AS (SELECT SchemaName = S.name,
           TableName = T.name,
           S2.Rows,
           [object_id] = T.object_id,
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
          AND (
                  @ObjectId IS NULL
                  OR (T.OBJECT_ID = @ObjectId)
              )
   )
INSERT INTO #CamposVarchar
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
WHERE (
          [Type] = 'varchar'
          AND R.SchemaName <> 'HangFire'
      )
  



 INSERT INTO #TabelasModificaveisParaChar 
SELECT CV.SchemaName,
       CV.TableName,
       CV.Rows,
       CV.object_id,
       CV.Coluna,
       CV.Type,
       CV.max_length,
       CV.column_id,
       CV.is_nullable,
       CV.Indexable,
       CV.is_computed,
	   'char(2)' AS NewDatatype	 FROM #CamposVarchar AS CV
WHERE 
 CV.Type ='varchar'  AND CV.max_length =2
AND CV.is_nullable = 0

UNION
SELECT CV.SchemaName,
       CV.TableName,
       CV.Rows,
       CV.object_id,
       CV.Coluna,
       CV.Type,
       CV.max_length,
       CV.column_id,
       CV.is_nullable,
       CV.Indexable,
       CV.is_computed,
	   'char(1)' AS NewDatatype		 FROM #CamposVarchar AS CV
WHERE CV.Type ='varchar' AND CV.max_length =1
UNION
SELECT CV.SchemaName,
       CV.TableName,
       CV.Rows,
       CV.object_id,
       CV.Coluna,
       CV.Type,
       CV.max_length,
       CV.column_id,
       CV.is_nullable,
       CV.Indexable,
       CV.is_computed,
	   'char(8)'  AS NewDatatype	 FROM #CamposVarchar AS CV
WHERE CV.Coluna LIKE '%CEP%'
AND CV.Type ='varchar' AND CV.max_length =8
AND CV.is_nullable = 0

UNION
SELECT CV.SchemaName,
       CV.TableName,
       CV.Rows,
       CV.object_id,
       CV.Coluna,
       CV.Type,
       CV.max_length,
       CV.column_id,
       CV.is_nullable,
       CV.Indexable,
       CV.is_computed,
	   'char(8)'  AS NewDatatype	 FROM #CamposVarchar AS CV
WHERE  CV.Type ='varchar' AND CV.max_length > 0 AND CV.max_length <=4
	AND CV.is_nullable = 0

UNION
	SELECT CV.SchemaName,
       CV.TableName,
       CV.Rows,
       CV.object_id,
       CV.Coluna,
       CV.Type,
       CV.max_length,
       CV.column_id,
       CV.is_nullable,
       CV.Indexable,
       CV.is_computed,
	   'char(8)'  AS NewDatatype	 FROM #CamposVarchar AS CV
WHERE  CV.Type ='varchar' AND CV.Coluna
IN
(
'ChaveAcesso'
)



DELETE TMPC
  FROM #TabelasModificaveisParaChar AS TMPC
 WHERE EXISTS (   SELECT 1
                    FROM #CamposExcecao AS CE
                   WHERE CE.TableName  = TMPC.TableName
                     AND CE.CollumName = TMPC.Coluna);


 

 

    IF (@ObjectId IS NOT NULL)
    BEGIN

        DELETE D
        FROM #TabelasModificaveisParaChar D
        WHERE D.object_id <> @ObjectId;
    END;

	


     INSERT INTO #GenerateDropContraints
	SELECT SCHEMA_NAME(KC.schema_id) AS SchemaName,
		   OBJECT_NAME(KC.parent_object_id) AS TableName,
		   KC.name AS ObjecName,
		   KC.type_desc,
		   Script = CONCAT(
						'ALTER TABLE',
						SPACE(1),
						SCHEMA_NAME(KC.schema_id),
						'.',
						OBJECT_NAME(KC.parent_object_id),
						SPACE(1),
						'DROP CONSTRAINT ',
						KC.name)
	  FROM sys.key_constraints AS KC
	  JOIN sys.indexes AS I
		ON KC.parent_object_id = I.object_id
	   AND KC.unique_index_id  = I.index_id
	  JOIN sys.index_columns AS IC
		ON I.object_id         = IC.object_id
	   AND I.index_id          = IC.index_id
	  JOIN sys.columns AS C
		ON I.object_id         = C.object_id
	   AND IC.column_id        = C.column_id
	 WHERE KC.type <> 'PK'
	   AND EXISTS (   SELECT 1
						FROM #TabelasModificaveisParaChar AS Tm2
					   WHERE Tm2.object_id                       = I.object_id
						 AND Tm2.Coluna COLLATE DATABASE_DEFAULT = C.name COLLATE DATABASE_DEFAULT);



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
    FROM #TabelasModificaveisParaChar AS TM
        JOIN sys.default_constraints AS DC
            ON TM.object_id = DC.parent_object_id
               AND TM.column_id = DC.parent_column_id;




	 DECLARE @table AS TableIntegerIds
	 INSERT INTO @table (Id)
	 SELECT DISTINCT TMPC.object_id FROM #TabelasModificaveisParaChar AS TMPC


    INSERT INTO #Indices
    EXEC HealthCheck.uspAllIndex @typeIndex = 'NONCLUSTERED',      -- varchar(40)
                                 @SomenteUsado = NULL,             -- bit
                                 @TableIsEmpty = NULL,             -- bit
                                 @ObjectName = NULL,               -- varchar(128)
                                 @BadIndex = NULL, 
								 @TableObjectIds =@table,                -- bit
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
            JOIN sys.stats_columns AS SC
                ON S.object_id = SC.object_id
                   AND S.stats_id = SC.stats_id
            ON T.object_id = S.object_id
    WHERE SC.column_id > 1
          AND NOT EXISTS
    (
        SELECT *
        FROM sys.indexes AS I
            JOIN sys.index_columns AS IC
                ON I.object_id = IC.object_id
                   AND I.index_id = IC.index_id
        WHERE I.object_id = T.object_id
              AND IC.column_id = SC.column_id
    )
       AND EXISTS(SELECT 1 FROM #TabelasModificaveisParaChar AS TMPC
				WHERE TMPC.object_id = T.object_id 
				AND TMPC.column_id = SC.column_id)


 
    INSERT INTO #TempIndex
    SELECT DISTINCT T.object_id,
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
		  AND EXISTS(SELECT 1 FROM #TabelasModificaveisParaChar AS TMPC
							WHERE TMPC.object_id = I.object_id
							AND TMPC.column_id = IC.column_id)





    INSERT INTO #GenerateDeleteDefaults
    SELECT Def.SchemaName,
           Def.TableName,
           Def.object_id,
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

    INSERT INTO #GenerateCreateDefaults
    SELECT Def.SchemaName,
           Def.TableName,
           Def.object_id,
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
           S.StatisticasName,
           ScriptDrop = CONCAT('DROP STATISTICS ', SPACE(1), TM.SchemaName, '.', TM.TableName, '.', S.StatisticasName)
    FROM #TabelasModificaveisParaChar AS TM
        JOIN #Statisticas AS S
            ON TM.object_id = S.object_id
               AND TM.column_id = S.column_id;

    INSERT INTO #GenerateCreateStats
    SELECT TM.SchemaName,
           TM.TableName,
           TM.Rows,
           TM.object_id,
           TM.Coluna,
           S.StatisticasName,
           ScriptCreate = CONCAT(
                                    'CREATE STATISTICS ',
                                    SPACE(1),
                                    CONCAT('Stats_',TM.SchemaName,TM.TableName,TM.Coluna),
                                    ' ON ',
                                    TM.SchemaName,
                                    '.',
                                    TM.TableName,
                                    '(',
                                    TM.Coluna,
                                    ')'
                                )
    FROM #TabelasModificaveisParaChar AS TM
        JOIN #Statisticas AS S
            ON TM.object_id = S.object_id
               AND TM.column_id = S.column_id;

    INSERT INTO #GenerateDeleteIndex
    SELECT DISTINCT
        TM.SchemaName,
        TI.TableName,
        TI.object_id,
        TI.IndexName,
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
        JOIN #TabelasModificaveisParaChar AS TM
            ON TI.object_id = TM.object_id
               AND TI.column_id = TM.column_id;

    INSERT INTO #GenerateCreateIndex
    SELECT DISTINCT
        I.ObjectName,
        I.ObjectId,
        I.IndexName,
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
    WHERE CAST(I.IndexName AS VARCHAR(200))IN (
                                                      SELECT DISTINCT
                                                          CAST(TI.IndexName AS VARCHAR(200))
                                                      FROM #TempIndex AS TI
                                                          JOIN #TabelasModificaveisParaChar AS TM
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
           TM.NewDatatype,
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
                                    TM.NewDatatype,
                                    (CASE
                                         WHEN TM.is_nullable = 0 THEN
                                             ' NOT NULL '
                                     END
                                    ),
                                    ' ;',
                                    SPACE(1)
                                )
    FROM #TabelasModificaveisParaChar AS TM;








    IF (@Efetivar = 1)
    BEGIN

        IF (EXISTS (SELECT * FROM #GenerateDropContraints))
        BEGIN

            /* declare variables */
            DECLARE @RowUniqueDelete INT;
            DECLARE @bjectObjecNameDelete NVARCHAR(250);
            DECLARE @DeleteScriptUniqueDelete NVARCHAR(500);
            DECLARE @HasErrorOnUniqueDelete INT = 0;
            DECLARE cursor_DeletaUnique CURSOR FAST_FORWARD READ_ONLY FOR
            SELECT IX.RowId,
                   IX.ObjecName,
                   IX.Script
            FROM #GenerateDropContraints IX;

            OPEN cursor_DeletaUnique;

            FETCH NEXT FROM cursor_DeletaUnique
            INTO @RowUniqueDelete,
                 @bjectObjecNameDelete,
                 @DeleteScriptUniqueDelete;

            WHILE @@FETCH_STATUS = 0
            BEGIN

                PRINT @DeleteScriptUniqueDelete;
                EXEC @HasErrorOnUniqueDelete = sys.sp_executesql @DeleteScriptUniqueDelete;

                IF (@HasErrorOnUniqueDelete <> 0)
                BEGIN

                    BREAK;
                END;


                FETCH NEXT FROM cursor_DeletaUnique
                INTO @RowUniqueDelete,
                     @bjectObjecNameDelete,
                     @DeleteScriptUniqueDelete;
            END;

            CLOSE cursor_DeletaUnique;
            DEALLOCATE cursor_DeletaUnique;



        END;

        IF (EXISTS (SELECT * FROM #GenerateDeleteIndex))
        BEGIN

            /* declare variables */
            DECLARE @RowIdndexDelete INT;
            DECLARE @bjectIdIndexDelete INT;
            DECLARE @DeleteScriptIndexDelete NVARCHAR(500);
            DECLARE @HasError INT = 0;
            DECLARE cursor_DeletaIndex CURSOR FAST_FORWARD READ_ONLY FOR
            SELECT IX.RowId,
                   IX.object_id,
                   IX.DeleteScript
            FROM #GenerateDeleteIndex IX;

            OPEN cursor_DeletaIndex;

            FETCH NEXT FROM cursor_DeletaIndex
            INTO @RowIdndexDelete,
                 @bjectIdIndexDelete,
                 @DeleteScriptIndexDelete;

            WHILE @@FETCH_STATUS = 0
            BEGIN

                PRINT @DeleteScriptIndexDelete;
                EXEC @HasError = sys.sp_executesql @DeleteScriptIndexDelete;

                IF (@HasError <> 0)
                BEGIN

                    BREAK;
                END;


                FETCH NEXT FROM cursor_DeletaIndex
                INTO @RowIdndexDelete,
                     @bjectIdIndexDelete,
                     @DeleteScriptIndexDelete;
            END;

            CLOSE cursor_DeletaIndex;
            DEALLOCATE cursor_DeletaIndex;



        END;

        IF (EXISTS (SELECT * FROM #GenerateDeleteStats AS GDS))
        BEGIN

            /* declare variables */
            DECLARE @RowStatsDelete INT;
            DECLARE @bjectStatsDelete INT;
            DECLARE @DeleteScriptStatsDelete NVARCHAR(500);
            DECLARE @HasErrorStats INT = 0;
            DECLARE cursor_DeletaStats CURSOR FAST_FORWARD READ_ONLY FOR
            SELECT IX.RowId,
                   IX.object_id,
                   IX.ScriptDrop
            FROM #GenerateDeleteStats IX;

            OPEN cursor_DeletaStats;

            FETCH NEXT FROM cursor_DeletaStats
            INTO @RowStatsDelete,
                 @bjectStatsDelete,
                 @DeleteScriptStatsDelete;

            WHILE @@FETCH_STATUS = 0
            BEGIN

                PRINT @DeleteScriptStatsDelete;
                EXEC @HasErrorStats = sys.sp_executesql @DeleteScriptStatsDelete;

                IF (@HasErrorStats <> 0)
                BEGIN
                    BREAK;
                END;


                FETCH NEXT FROM cursor_DeletaStats
                INTO @RowStatsDelete,
                     @bjectStatsDelete,
                     @DeleteScriptStatsDelete;

            END;

            CLOSE cursor_DeletaStats;
            DEALLOCATE cursor_DeletaStats;



        END;

        IF (EXISTS (SELECT * FROM #GenerateDeleteDefaults AS GDD))
        BEGIN

            /* declare variables */
            DECLARE @RowDefaultsDelete INT;
            DECLARE @bjectDefaultsDelete INT;
            DECLARE @DeleteScriptDefaultsDelete NVARCHAR(500);
            DECLARE @HasErrorDefaults INT = 0;
            DECLARE cursor_DeletaDefaults CURSOR FAST_FORWARD READ_ONLY FOR
            SELECT IX.RowId,
                   IX.object_id,
                   IX.Script
            FROM #GenerateDeleteDefaults IX;

            OPEN cursor_DeletaDefaults;

            FETCH NEXT FROM cursor_DeletaDefaults
            INTO @RowDefaultsDelete,
                 @bjectDefaultsDelete,
                 @DeleteScriptDefaultsDelete;

            WHILE @@FETCH_STATUS = 0
            BEGIN

                PRINT @DeleteScriptDefaultsDelete;
                EXEC @HasErrorDefaults = sys.sp_executesql @DeleteScriptDefaultsDelete;

                IF (@HasErrorDefaults <> 0)
                BEGIN
                    BREAK;
                END;


                FETCH NEXT FROM cursor_DeletaDefaults
                INTO @RowDefaultsDelete,
                     @bjectDefaultsDelete,
                     @DeleteScriptDefaultsDelete;

            END;

            CLOSE cursor_DeletaDefaults;
            DEALLOCATE cursor_DeletaDefaults;



        END;

        IF (EXISTS (SELECT * FROM #GenerateAlterTable AS GAT))
        BEGIN

            --SELECT * FROM #GenerateAlterTable AS GAT
            /* declare variables */
            DECLARE @RowAlterTableDelete INT;
            DECLARE @bjectAlterTableDelete INT;
            DECLARE @ScriptAlterTableDelete NVARCHAR(500);
            DECLARE @HasErrorAlterTable INT = 0;
            DECLARE cursor_DeletaAlterTable CURSOR FAST_FORWARD READ_ONLY FOR
            SELECT GAT.RowId,
                   GAT.object_id,
                   GAT.ScriptCreate
            FROM #GenerateAlterTable AS GAT;

            OPEN cursor_DeletaAlterTable;

            FETCH NEXT FROM cursor_DeletaAlterTable
            INTO @RowAlterTableDelete,
                 @bjectAlterTableDelete,
                 @ScriptAlterTableDelete;

            WHILE @@FETCH_STATUS = 0
            BEGIN

                PRINT @ScriptAlterTableDelete;
                EXEC @HasErrorAlterTable = sys.sp_executesql @ScriptAlterTableDelete;

                IF (@HasErrorAlterTable <> 0)
                BEGIN
                    BREAK;
                END;


                FETCH NEXT FROM cursor_DeletaAlterTable
                INTO @RowAlterTableDelete,
                     @bjectAlterTableDelete,
                     @ScriptAlterTableDelete;

            END;

            CLOSE cursor_DeletaAlterTable;
            DEALLOCATE cursor_DeletaAlterTable;



        END;

		

        IF (EXISTS (SELECT * FROM #GenerateCreateDefaults AS GCD))
        BEGIN

            --SELECT * FROM #GenerateAlterTable AS GAT
            /* declare variables */
            DECLARE @RowCreateDefaults INT;
            DECLARE @bjectCreateDefaults INT;
            DECLARE @ScriptCreateDefaults NVARCHAR(500);
            DECLARE @HasErrorCreateDefault INT = 0;
            DECLARE cursor_CreateDefault CURSOR FAST_FORWARD READ_ONLY FOR
            SELECT GAT.RowId,
                   GAT.object_id,
                   GAT.Script
            FROM #GenerateCreateDefaults AS GAT;

            OPEN cursor_CreateDefault;

            FETCH NEXT FROM cursor_CreateDefault
            INTO @RowCreateDefaults,
                 @bjectCreateDefaults,
                 @ScriptCreateDefaults;

            WHILE @@FETCH_STATUS = 0
            BEGIN

                PRINT @ScriptCreateDefaults;
                EXEC @HasErrorCreateDefault = sys.sp_executesql @ScriptCreateDefaults;

                IF (@HasErrorCreateDefault <> 0)
                BEGIN
                    BREAK;
                END;


                FETCH NEXT FROM cursor_CreateDefault
                INTO @RowCreateDefaults,
                     @bjectCreateDefaults,
                     @ScriptCreateDefaults;

            END;

            CLOSE cursor_CreateDefault;
            DEALLOCATE cursor_CreateDefault;

	


        END;

        IF (EXISTS (SELECT * FROM #GenerateCreateIndex AS GCI))
        BEGIN

            --SELECT * FROM #GenerateAlterTable AS GAT
            /* declare variables */
            DECLARE @RowCreateIndex INT;
            DECLARE @bjectCreateIndex INT;
            DECLARE @ScriptCreateIndex NVARCHAR(500);
            DECLARE @HasErrorCreateIndex INT = 0;
            DECLARE cursor_CreateIndex CURSOR FAST_FORWARD READ_ONLY FOR
            SELECT GAT.RowId,
                   GAT.ObjectId,
                   GAT.ScriptCreate
            FROM #GenerateCreateIndex AS GAT;

            OPEN cursor_CreateIndex;

            FETCH NEXT FROM cursor_CreateIndex
            INTO @RowCreateIndex,
                 @bjectCreateIndex,
                 @ScriptCreateIndex;

            WHILE @@FETCH_STATUS = 0
            BEGIN

                PRINT @ScriptCreateIndex;
                EXEC @HasErrorCreateIndex = sys.sp_executesql @ScriptCreateIndex;

                IF (@HasErrorCreateIndex <> 0)
                BEGIN
                    BREAK;
                END;


                FETCH NEXT FROM cursor_CreateIndex
                INTO @RowCreateIndex,
                     @bjectCreateIndex,
                     @ScriptCreateIndex;

            END;

            CLOSE cursor_CreateIndex;
            DEALLOCATE cursor_CreateIndex;



        END;

        IF (EXISTS (SELECT * FROM #GenerateCreateStats AS GCS))
        BEGIN

            --SELECT * FROM #GenerateAlterTable AS GAT
            /* declare variables */
            DECLARE @RowCreateStats INT;
            DECLARE @bjectCreateStats INT;
            DECLARE @ScriptCreateStats NVARCHAR(500);
            DECLARE @HasErrorCreateStats INT = 0;
            DECLARE cursor_CreateStats CURSOR FAST_FORWARD READ_ONLY FOR
            SELECT GAT.RowId,
                   GAT.object_id,
                   GAT.ScriptCreate
            FROM #GenerateCreateStats AS GAT;

            OPEN cursor_CreateStats;

            FETCH NEXT FROM cursor_CreateStats
            INTO @RowCreateStats,
                 @bjectCreateStats,
                 @ScriptCreateStats;

            WHILE @@FETCH_STATUS = 0
            BEGIN

                PRINT @ScriptCreateStats;
                EXEC @HasErrorCreateStats = sys.sp_executesql @ScriptCreateStats;

                IF (@HasErrorCreateStats <> 0)
                BEGIN
                    BREAK;
                END;


                FETCH NEXT FROM cursor_CreateStats
                INTO @RowCreateStats,
                     @bjectCreateStats,
                     @ScriptCreateStats;

            END;

            CLOSE cursor_CreateStats;
            DEALLOCATE cursor_CreateStats;



        END;

    END;


	IF(@Visualizar = 1)
	BEGIN
			
			SELECT * FROM #TabelasModificaveisParaChar AS TM

			
	END

	  
--END;