
/* ==================================================================
--Data: 29/11/2018 
--Autor :Wesley Neves
--Observação: 
Query De exemplo de rotinas que não entra 
SELECT PJ.DataFundacao,
       TRY_CAST(PJ.DataFundacao AS TIME)
  FROM Cadastro.PessoasJuridicas AS PJ
 WHERE PJ.DataFundacao IS NOT NULL
   AND TRY_CAST(PJ.DataFundacao AS TIME) <> '00:00:00.0000000';
 
-- ==================================================================
*/

EXEC HealthCheck.uspModifierAllCollunsDatetimeToDateTime2 @ObjectName = NULL,          -- varchar(200)
                                                          
                                                          @Efetivar = 0,          -- bit
                                                          @Visualizar = 1,        -- bit
                                                          @ParseToPrecision2 = 1  -- bit

--1000390633	Patrimonio	DepreciacoesBensMoveis	258905              	4626	63224 KB	37008 KB	24616 KB	1600 KB
--1000390633	Patrimonio	DepreciacoesBensMoveis	258905              	4317	60792 KB	34536 KB	24608 KB	1648 KB
--1000390633	Patrimonio	DepreciacoesBensMoveis	258905              	4179	59640 KB	33432 KB	24608 KB	1600 KB
--1000390633	Patrimonio	DepreciacoesBensMoveis	258905              	4111	59128 KB	32888 KB	24616 KB	1624 KB

--EXEC [HealthCheck].[uspGetSizeOfObjets] @objname = N'Patrimonio.DepreciacoesBensMoveis';                   -- nvarchar(776)

----ALTER TABLE Patrimonio.DepreciacoesBensMoveis REBUILD

--GO

CREATE OR ALTER PROCEDURE HealthCheck.uspModifierAllCollunsDatetimeToDateTime2
(
    @ObjectName        VARCHAR(200) = NULL,
    @Efetivar          BIT          = 1,
    @Visualizar        BIT          = 1,
    @ParseToPrecision2 BIT          = 1
)
AS
    BEGIN

        --DECLARE @ObjectName VARCHAR(200) = NULL;
        --DECLARE @Efetivar BIT = 1;
        --DECLARE @Visualizar BIT = 1;
        --DECLARE @ParseToDateTime2 BIT = 1;
        DECLARE @ObjectId INT = NULL; --1791345446;  --OBJECT_ID(@ObjectName);

        SET @ObjectId = OBJECT_ID(@ObjectName);

        DECLARE @TipoDateTime2Precision2 VARCHAR(12) = 'DATETIME2(2)';
        DECLARE @tamanhoDate TINYINT = 3;
        DECLARE @tamanhoDateTime TINYINT = 8;
        DECLARE @tamanhoDateTime2 TINYINT = 6;

        IF(OBJECT_ID('TEMPDB..#GenerateDeleteDefaults') IS NOT NULL)
            DROP TABLE #GenerateDeleteDefaults;

        CREATE TABLE #GenerateDeleteDefaults
        (
            RowId                           INT           NOT NULL IDENTITY(1, 1),
            [SchemaName]                    NVARCHAR(128),
            [TableName]                     NVARCHAR(128),
            [object_id]                     INT,
            [Coluna]                        NVARCHAR(128),
            Collum_Id                       INT,
            [default_constraintsName]       NVARCHAR(128),
            [default_constraintsDefinition] NVARCHAR(MAX),
            [Script]                        NVARCHAR(420) PRIMARY KEY([object_id], Collum_Id, RowId)
        );

        IF(OBJECT_ID('TEMPDB..#Reducao') IS NOT NULL)
            DROP TABLE #Reducao;

        CREATE TABLE #Reducao
        (
            [SchemaName]                                     NVARCHAR(128),
            [TableName]                                      NVARCHAR(128),
            [Coluna]                                         NVARCHAR(128),
            [Type]                                           NVARCHAR(128),
            [NewType]                                        NVARCHAR(128),
            [Rows]                                           INT,
            [TamanhoAtualParaColunaBytes]                    INT,
            [TotalDePaginasOcupadasAntesAlteracaoParaColuna] INT,
            [TotalPaginasAtualParaTodasColunas]              INT,
            [BytesDiminuidoPorRegistro]                      INT,
            [DiminuicaoEmBytes]                              INT,
            [DiminuicaoEmPaginas]                            INT,
            [TotalPaginasAposAlteracao]                      INT,
            [ValorAtual]                                     INT
        );

        IF(OBJECT_ID('TEMPDB..#GenerateCreateDefaults') IS NOT NULL)
            DROP TABLE #GenerateCreateDefaults;

        CREATE TABLE #GenerateCreateDefaults
        (
            RowId                           INT           NOT NULL IDENTITY(1, 1),
            [SchemaName]                    NVARCHAR(128),
            [TableName]                     NVARCHAR(128),
            [object_id]                     INT,
            [Coluna]                        NVARCHAR(128),
            Collum_Id                       INT,
            [default_constraintsName]       NVARCHAR(128),
            [default_constraintsDefinition] NVARCHAR(MAX),
            [Script]                        NVARCHAR(MAX) PRIMARY KEY([object_id], Collum_Id, RowId)
        );

        IF(OBJECT_ID('TEMPDB..#GenerateDeleteStats') IS NOT NULL)
            DROP TABLE #GenerateDeleteStats;

        CREATE TABLE #GenerateDeleteStats
        (
            RowId             INT           NOT NULL IDENTITY(1, 1),
            [SchemaName]      NVARCHAR(128),
            [TableName]       NVARCHAR(128),
            [Rows]            INT,
            [object_id]       INT,
            [Coluna]          NVARCHAR(128),
            Collum_Id         INT,
            [StatisticasName] NVARCHAR(128),
            [ScriptDrop]      NVARCHAR(403) PRIMARY KEY([object_id], Collum_Id, RowId)
        );

        IF(OBJECT_ID('TEMPDB..#GenerateCreateStats') IS NOT NULL)
            DROP TABLE #GenerateCreateStats;

        CREATE TABLE #GenerateCreateStats
        (
            RowId             INT           NOT NULL IDENTITY(1, 1),
            [SchemaName]      NVARCHAR(128),
            [TableName]       NVARCHAR(128),
            [Rows]            INT,
            [object_id]       INT,
            [Coluna]          NVARCHAR(128),
            Collum_Id         INT,
            [StatisticasName] NVARCHAR(128),
            [ScriptCreate]    NVARCHAR(403) PRIMARY KEY([object_id], Collum_Id, RowId)
        );

        IF(OBJECT_ID('TEMPDB..#GenerateDeleteIndex') IS NOT NULL)
            DROP TABLE #GenerateDeleteIndex;

        CREATE TABLE #GenerateDeleteIndex
        (
            RowId          INT           NOT NULL IDENTITY(1, 1),
            [SchemaName]   NVARCHAR(128),
            [TableName]    NVARCHAR(128),
            [object_id]    INT,
            [IndexName]    NVARCHAR(128),
            Collum_Id      INT,
            CollumName     VARCHAR(128),
            [DeleteScript] NVARCHAR(403) PRIMARY KEY([object_id], Collum_Id, RowId)
        );

        IF(OBJECT_ID('TEMPDB..#GenerateCreateIndex') IS NOT NULL)
            DROP TABLE #GenerateCreateIndex;

        CREATE TABLE #GenerateCreateIndex
        (
            RowId          INT            NOT NULL IDENTITY(1, 1),
            [ObjectName]   VARCHAR(300),
            [ObjectId]     INT,
            [IndexName]    VARCHAR(400),
            Collum_Id      INT,
            CollumName     VARCHAR(128),
            [ScriptCreate] NVARCHAR(3000) PRIMARY KEY([ObjectId], Collum_Id, RowId)
        );

        IF(OBJECT_ID('TEMPDB..#GenerateAlterTable') IS NOT NULL)
            DROP TABLE #GenerateAlterTable;

        CREATE TABLE #GenerateAlterTable
        (
            RowId          INT            NOT NULL IDENTITY(1, 1),
            [SchemaName]   NVARCHAR(128),
            [TableName]    NVARCHAR(128),
            [object_id]    INT,
            [Coluna]       NVARCHAR(128),
            [Type]         NVARCHAR(128),
            [max_length]   SMALLINT,
            [column_id]    INT,
            [is_nullable]  BIT,
            [NovoTipo]     NVARCHAR(128),
            [ScriptCreate] NVARCHAR(3000) PRIMARY KEY([object_id], RowId)
        );

        IF(OBJECT_ID('TEMPDB..#GenerateDropContraints') IS NOT NULL)
            DROP TABLE #GenerateDropContraints;

        CREATE TABLE #GenerateDropContraints
        (
            [SchemaName] NVARCHAR(128),
            [TableName]  NVARCHAR(128),
            ObjectId     INT,
            [ObjecName]  NVARCHAR(128),
            [type_desc]  NVARCHAR(60),
            [column_id]  INT,
            [ColummName] NVARCHAR(128),
            [Script]     NVARCHAR(414)
        );

        CREATE NONCLUSTERED INDEX IxGenerateDropContraints
        ON #GenerateDropContraints(TableName, column_id);

        IF(OBJECT_ID('TEMPDB..#DefaultConstraints') IS NOT NULL)
            DROP TABLE #DefaultConstraints;

        CREATE TABLE #DefaultConstraints
        (
            [SchemaName]                    NVARCHAR(128),
            [TableName]                     NVARCHAR(128),
            [object_id]                     INT,
            [Coluna]                        NVARCHAR(128),
            [column_id]                     INT,
            [type]                          NVARCHAR(128),
            [default_constraintsName]       NVARCHAR(128),
            [default_constraintsType]       NVARCHAR(60),
            [default_constraintsDefinition] NVARCHAR(MAX) PRIMARY KEY(object_id, column_id)
        );

        IF(OBJECT_ID('TEMPDB..#CamposDateTime') IS NOT NULL)
            DROP TABLE #CamposDateTime;

        CREATE TABLE #CamposDateTime
        (
            [SchemaName]  NVARCHAR(128),
            [TableName]   NVARCHAR(128),
            [Rows]        INT,
            [object_id]   INT,
            [Coluna]      NVARCHAR(128),
            [Type]        NVARCHAR(128),
            [max_length]  SMALLINT,
            [column_id]   INT,
            [is_nullable] BIT,
            [Indexable]   BIT,
            [is_computed] BIT
        );

        IF(OBJECT_ID('TEMPDB..#SchemasExcecao') IS NOT NULL)
            DROP TABLE #SchemasExcecao;

        CREATE TABLE #SchemasExcecao
        (
            ShemaName VARCHAR(128),
        );

        INSERT INTO #SchemasExcecao VALUES('HangFire');

        IF(OBJECT_ID('TEMPDB..#Indices') IS NOT NULL)
            DROP TABLE #Indices;

        CREATE TABLE #Indices
        (
            [ObjectId]           INT,
            [ObjectName]         VARCHAR(300),
            [RowsInTable]        INT,
            [IndexName]          VARCHAR(128),
            [Usado]              BIT,
            [UserSeeks]          INT,
            [UserScans]          INT,
            [UserLookups]        INT,
            [UserUpdates]        INT,
            [Reads]              BIGINT,
            [Write]              INT,
            [CountPageSplitPage] INT,
            [PercAproveitamento] DECIMAL(18, 2),
            [PercCustoMedio]     DECIMAL(18, 2),
            [IsBadIndex]         INT,
            [IndexId]            SMALLINT,
            [IndexsizeKB]        BIGINT,
            [IndexsizeMB]        DECIMAL(18, 2),
            [IndexSizePorTipoMB] DECIMAL(18, 2),
            [Chave]              VARCHAR(899),
            [ColunasIncluidas]   VARCHAR(899),
            [IsUnique]           BIT,
            [IgnoreDupKey]       BIT,
            [IsprimaryKey]       BIT,
            [IsUniqueConstraint] BIT,
            [FillFact]           TINYINT,
            [AllowRowLocks]      BIT,
            [AllowPageLocks]     BIT,
            [HasFilter]          BIT,
            [TypeIndex]          TINYINT
        );

        IF(EXISTS (
                      SELECT 1
                        FROM sys.syscursors AS S
                       WHERE
                          S.cursor_name = 'cursor_CamposDateTime'
                  )
          )
            BEGIN
                DEALLOCATE cursor_CamposDateTime;
            END;

        IF(EXISTS (
                      SELECT 1
                        FROM sys.syscursors AS S
                       WHERE
                          S.cursor_name = 'cursor_AlteraCampos'
                  )
          )
            BEGIN
                DEALLOCATE cursor_AlteraCampos;
            END;

        IF(EXISTS (
                      SELECT 1
                        FROM sys.syscursors AS S
                       WHERE
                          S.cursor_name = 'cursor_DeleteIndex'
                  )
          )
            BEGIN
                DEALLOCATE cursor_DeleteIndex;
            END;

        IF(OBJECT_ID('TEMPDB..#TabelasModificaveis') IS NOT NULL)
            DROP TABLE #TabelasModificaveis;

        CREATE TABLE #TabelasModificaveis
        (
            [SchemaName]  NVARCHAR(128),
            [TableName]   NVARCHAR(128),
            [Rows]        INT,
            [object_id]   INT,
            [Coluna]      NVARCHAR(128),
            [Type]        NVARCHAR(128),
            [max_length]  SMALLINT,
            [column_id]   INT,
            [is_nullable] BIT,
            [Indexable]   BIT,
            [is_computed] BIT,
            [NovoTipo]    NVARCHAR(128) PRIMARY KEY(object_id, column_id)
        );

        ;WITH DadosTabela
            AS
            (
                SELECT SchemaName = S.name,
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
                       JOIN sys.sysindexes S2 ON T.OBJECT_ID = S2.id
                                                 AND S2.indid = 1
                       JOIN sys.schemas AS S ON S.SCHEMA_ID = T.SCHEMA_ID
                       JOIN sys.COLUMNS AS C ON C.OBJECT_ID = T.OBJECT_ID
                       JOIN sys.types AS T2 ON T2.system_type_id = C.system_type_id
                 WHERE
                    C.is_computed = 0
                    AND T2.NAME = 'datetime'
                    AND NOT EXISTS (
                                       SELECT *
                                         FROM sys.computed_columns AS CC
                                        WHERE
                                           CC.object_id = T.object_id
                                           AND PATINDEX(CONCAT('%', C.name COLLATE DATABASE_DEFAULT, '%'), CC.definition COLLATE DATABASE_DEFAULT) > 1
                                   )
                    AND (
                            @ObjectId IS NULL
                            OR (T.object_id = @ObjectId)
                        )
            )
        INSERT INTO #CamposDateTime(
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
        SELECT R.* FROM DadosTabela R;

        DELETE CDT
          FROM #CamposDateTime AS CDT
         WHERE
            CDT.SchemaName LIKE 'HangFire%';

        --DELETE CDT FROM #CamposDateTime AS CDT
        --WHERE CDT.Rows = 0
        DECLARE @HasErrorOnInsertSelect INT = 0;

        INSERT INTO #TabelasModificaveis(
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
                                            is_computed,
                                            NovoTipo
                                        )
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
               CDT.is_computed,
               @TipoDateTime2Precision2
          FROM #CamposDateTime AS CDT;

        IF(@ObjectId IS NOT NULL)
            BEGIN
                DELETE D FROM #TabelasModificaveis D WHERE D.object_id <> @ObjectId;
            END;

            ;WITH Dados
                AS
                (
                    SELECT TM.SchemaName,
                           TM.TableName,
                           TM.Coluna,
                           TM.Type,
                           TM.NovoTipo AS NewType,
                           TM.Rows,
                           (TM.Rows * 8) TamanhoAtualParaColunaBytes,
                           (TM.Rows * 8) / 8060 TotalDePaginasOcupadasAntesAlteracaoParaColuna,
                           BytesDiminuidoPorRegistro = (8 - ((IIF(TM.NovoTipo = 'DATE', 3, @tamanhoDateTime2)))),
                           Diminuicao = ((TM.Rows * 8) - (TM.Rows * (IIF(TM.NovoTipo = 'DATE', 3, @tamanhoDateTime2)))),
                           DiminuicaoEmBytes = (((TM.Rows * 8)) - (((TM.Rows * 8) - (TM.Rows * (IIF(TM.NovoTipo = 'DATE', 3, @tamanhoDateTime2)))))),
                           DiminuicaoEmPaginas = (((TM.Rows * 8) - ((TM.Rows * 8) - (TM.Rows * (IIF(TM.NovoTipo = 'DATE', 3, @tamanhoDateTime2))))) / 8060)
                      FROM #TabelasModificaveis AS TM
                )
        INSERT INTO #Reducao(
                                SchemaName,
                                TableName,
                                Coluna,
                                Type,
                                NewType,
                                Rows,
                                TamanhoAtualParaColunaBytes,
                                TotalDePaginasOcupadasAntesAlteracaoParaColuna,
                                BytesDiminuidoPorRegistro,
                                DiminuicaoEmBytes,
                                DiminuicaoEmPaginas,
                                TotalPaginasAtualParaTodasColunas,
                                TotalPaginasAposAlteracao,
                                ValorAtual
                            )
        SELECT R.SchemaName,
               R.TableName,
               R.Coluna,
               R.Type,
               R.NewType,
               R.Rows,
               R.TamanhoAtualParaColunaBytes,
               R.TotalDePaginasOcupadasAntesAlteracaoParaColuna,
               R.BytesDiminuidoPorRegistro,
               R.DiminuicaoEmBytes,
               R.DiminuicaoEmPaginas,
               TotalPaginasAtual = SUM(R.TotalDePaginasOcupadasAntesAlteracaoParaColuna) OVER (PARTITION BY R.SchemaName, R.TableName),
               TotalPaginasAposAlteracao = SUM(R.DiminuicaoEmPaginas) OVER (PARTITION BY R.SchemaName, R.TableName),
               ValorAtual = (SUM(R.TotalDePaginasOcupadasAntesAlteracaoParaColuna) OVER (PARTITION BY R.SchemaName, R.TableName)) - (SUM(R.DiminuicaoEmPaginas) OVER (PARTITION BY R.SchemaName, R.TableName))
          FROM Dados R;

        INSERT INTO #GenerateDropContraints
        SELECT SCHEMA_NAME(KC.schema_id) AS SchemaName,
               OBJECT_NAME(KC.parent_object_id) AS TableName,
               KC.parent_object_id,
               KC.name AS ObjecName,
               KC.type_desc,
               IC.column_id,
               C.name AS ColummName,
               Script = CONCAT('ALTER TABLE', SPACE(1), SCHEMA_NAME(KC.schema_id), '.', OBJECT_NAME(KC.parent_object_id), SPACE(1), 'DROP CONSTRAINT ', KC.name)
          FROM sys.key_constraints AS KC
               JOIN sys.indexes AS I ON KC.parent_object_id = I.object_id
                                        AND KC.unique_index_id = I.index_id
               JOIN sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
               JOIN sys.columns AS C ON I.object_id = C.object_id
                                        AND IC.column_id = C.column_id
         WHERE
            KC.type <> 'PK'
            AND EXISTS (
                           SELECT 1
                             FROM #TabelasModificaveis AS Tm2
                            WHERE
                               Tm2.object_id = I.object_id
                               AND Tm2.Coluna COLLATE DATABASE_DEFAULT = C.name COLLATE DATABASE_DEFAULT
                       );

        INSERT INTO #DefaultConstraints
        SELECT TM.SchemaName,
               TM.TableName,
               TM.object_id,
               TM.Coluna,
               TM.column_id,
               TM.Type,
               DC.name AS default_constraintsName,
               DC.type_desc AS default_constraintsType,
               --DC.definition AS default_constraintsDefinition,
               IIF(CHARINDEX('getdate', DC.definition, 0) = 0, REPLACE(DC.definition, '(((1900)-(0))-(0))', CONCAT(CHAR(39), '1900-0-0', CHAR(39))), DC.definition)
          FROM #TabelasModificaveis AS TM
               JOIN sys.default_constraints AS DC ON TM.object_id = DC.parent_object_id
                                                     AND TM.column_id = DC.parent_column_id;

        INSERT INTO #Indices
        EXEC HealthCheck.uspAllIndex @typeIndex = 'NONCLUSTERED',      -- varchar(40)
                                     @SomenteUsado = NULL,             -- bit
                                     @TableIsEmpty = NULL,             -- bit
                                     @ObjectName = NULL,               -- varchar(128)
                                     @BadIndex = NULL,                 -- bit
                                     @percentualAproveitamento = NULL; -- smallint

        IF(OBJECT_ID('TEMPDB..#Statisticas') IS NOT NULL)
            DROP TABLE #Statisticas;

        CREATE TABLE #Statisticas
        (
            [TableName]                    NVARCHAR(128),
            [object_id]                    INT,
            [StatisticasName]              NVARCHAR(128),
            [stats_id]                     INT,
            [has_filter]                   BIT,
            [filter_definition]            NVARCHAR(MAX),
            [stats_generation_method_desc] VARCHAR(80),
            [column_id]                    INT,
            [column_Name]                  NVARCHAR(128) PRIMARY KEY(object_id, column_id, [StatisticasName])
        );

        INSERT INTO #Statisticas
        SELECT T.name AS TableName,
               T.object_id,
               S.name AS StatisticasName,
               S.stats_id,
               S.has_filter,
               S.filter_definition,
               S.stats_generation_method_desc,
               SC.column_id,
               C.name
          FROM sys.tables AS T
               JOIN sys.schemas AS S2 ON T.schema_id = S2.schema_id
               JOIN sys.stats AS S ON T.object_id = S.object_id
               JOIN sys.stats_columns AS SC ON S.object_id = SC.object_id
                                               AND S.stats_id = SC.stats_id
               JOIN sys.columns AS C ON T.object_id = C.object_id
                                        AND C.column_id = SC.column_id
               JOIN #TabelasModificaveis AS TM ON T.object_id = TM.object_id
                                                  AND C.column_id = TM.column_id
         WHERE
            S.name LIKE '__%' ESCAPE '_'
            OR S.name LIKE 'S%';

        IF(OBJECT_ID('TEMPDB..#TempIndex') IS NOT NULL)
            DROP TABLE #TempIndex;

        CREATE TABLE #TempIndex
        (
            [object_id]   INT,
            [TableName]   NVARCHAR(150),
            [IndexName]   NVARCHAR(150),
            [type_desc]   NVARCHAR(60),
            [column_id]   INT,
            [key_ordinal] TINYINT,
            CollumName    VARCHAR(128) PRIMARY KEY(object_id, column_id, [IndexName])
        );

        INSERT INTO #TempIndex
        SELECT T.object_id,
               T.name AS TableName,
               I.name AS IndexName,
               I.type_desc,
               IC.column_id,
               IC.key_ordinal,
               C.name AS CollumName
          FROM sys.tables AS T
               JOIN sys.indexes AS I ON T.object_id = I.object_id
               JOIN sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
               JOIN sys.columns AS C ON I.object_id = C.object_id
                                        AND IC.column_id = C.column_id
               JOIN sys.types AS T2 ON T2.user_type_id = C.user_type_id
         WHERE
            I.type_desc = 'NONCLUSTERED'
            AND I.is_unique_constraint = 0
            AND T2.name LIKE 'date%'
            AND T.object_id IN(
                                  SELECT TM.object_id FROM #TabelasModificaveis AS TM
                              );

        INSERT INTO #GenerateDeleteDefaults
        SELECT Def.SchemaName,
               Def.TableName,
               Def.object_id,
               Def.Coluna,
               Def.column_id,
               Def.default_constraintsName,
               Def.default_constraintsDefinition,
               Script = CONCAT(' ALTER TABLE ', SPACE(1), Def.SchemaName, '.', Def.TableName, SPACE(1), ' DROP CONSTRAINT ', SPACE(1), Def.default_constraintsName, ' ;')
          FROM #DefaultConstraints Def;

        INSERT INTO #GenerateCreateDefaults
        SELECT Def.SchemaName,
               Def.TableName,
               Def.object_id,
               Def.Coluna,
               Def.column_id,
               Def.default_constraintsName,
               Def.default_constraintsDefinition,
               Script = CONCAT(' ALTER TABLE ', SPACE(1), Def.SchemaName, '.', Def.TableName, SPACE(1), ' ADD CONSTRAINT ', SPACE(1), Def.default_constraintsName, SPACE(1), 'DEFAULT', SPACE(1), Def.default_constraintsDefinition, SPACE(1), 'FOR', SPACE(1), Def.Coluna, ' ;')
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
               JOIN #Statisticas AS S ON TM.object_id = S.object_id
                                         AND TM.column_id = S.column_id;

        INSERT INTO #GenerateCreateStats
        SELECT TM.SchemaName,
               TM.TableName,
               TM.Rows,
               TM.object_id,
               TM.Coluna,
               S.column_id,
               S.StatisticasName,
               ScriptCreate = CONCAT('CREATE STATISTICS ', SPACE(1), CONCAT('Stats_', TM.SchemaName, S.TableName, TM.Coluna), ' ON ', TM.SchemaName, '.', TM.TableName, '(', TM.Coluna, ')')
          FROM #TabelasModificaveis AS TM
               JOIN #Statisticas AS S ON TM.object_id = S.object_id
                                         AND TM.column_id = S.column_id;

        INSERT INTO #GenerateDeleteIndex
        SELECT DISTINCT TM.SchemaName,
               TI.TableName,
               TI.object_id,
               TI.IndexName,
               TM.column_id,
               TM.Coluna,
               DeleteScript = CONCAT(' DROP INDEX ', SPACE(1), QUOTENAME(TI.IndexName), ' ON ', TM.SchemaName, '.', TI.TableName, SPACE(1))
          FROM #TempIndex AS TI
               JOIN #TabelasModificaveis AS TM ON TI.object_id = TM.object_id
                                                  AND TI.column_id = TM.column_id;

        INSERT INTO #GenerateCreateIndex
        SELECT DISTINCT I.ObjectName,
               I.ObjectId,
               I.IndexName,
               GDI.Collum_Id,
               GDI.CollumName,
               ScriptCreate = CONCAT(' CREATE ', CASE WHEN I.IsUniqueConstraint = 1 OR I.IsUnique = 1 THEN ' UNIQUE ' END, ' NONCLUSTERED INDEX', SPACE(1), CAST(I.IndexName AS VARCHAR(150)), ' ON ', I.ObjectName, '(', I.Chave, ')', CASE WHEN I.ColunasIncluidas IS NOT NULL THEN ' INCLUDE(' + I.ColunasIncluidas + ')' END, SPACE(1), ' WITH(FILLFACTOR = 100,DATA_COMPRESSION =PAGE ', ')', SPACE(1))
          FROM #Indices AS I
               JOIN #GenerateDeleteIndex AS GDI ON I.IndexName = GDI.IndexName
         WHERE
            I.ObjectId IN(
                             SELECT TM.object_id FROM #TabelasModificaveis AS TM
                         )
            AND CAST(I.IndexName AS VARCHAR(200))IN(
                                                       SELECT DISTINCT CAST(TI.IndexName AS VARCHAR(200))
                                                         FROM #TempIndex AS TI
                                                              JOIN #TabelasModificaveis AS TM ON TI.object_id = TM.object_id
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
               ScriptCreate = CONCAT(' ALTER TABLE ', SPACE(1), TM.SchemaName, '.', TM.TableName, SPACE(1), ' ALTER COLUMN ', SPACE(1), TM.Coluna, SPACE(1), TM.NovoTipo, (CASE WHEN TM.is_nullable = 0 THEN ' NOT NULL ' END), ' ;', SPACE(1))
          FROM #TabelasModificaveis AS TM;

        IF(@Efetivar = 1)
            BEGIN

                /* declare variables */
                DECLARE @SchemaName_Alter VARCHAR(128);
                DECLARE @TableName_Alter VARCHAR(128);
                DECLARE @Object_id_Alter INT;
                DECLARE @Coluna_Alter VARCHAR(128);
                DECLARE @column_id_Alter INT;
                DECLARE @ScriptCreate_Alter NVARCHAR(900);
                DECLARE @TempScript NVARCHAR(2000);
                DECLARE @HasError INT = 0;

                DECLARE cursor_AlteraColuna CURSOR FAST_FORWARD READ_ONLY FOR
                SELECT GAT.SchemaName,
                       GAT.TableName,
                       GAT.object_id,
                       GAT.Coluna,
                       GAT.column_id,
                       GAT.ScriptCreate
                  FROM #GenerateAlterTable AS GAT
                 --WHERE GAT.object_id = 671341456
                 ORDER BY
                    GAT.TableName,
                    GAT.column_id;

                OPEN cursor_AlteraColuna;

                FETCH NEXT FROM cursor_AlteraColuna
                 INTO @SchemaName_Alter,
                      @TableName_Alter,
                      @Object_id_Alter,
                      @Coluna_Alter,
                      @column_id_Alter,
                      @ScriptCreate_Alter;

                WHILE @@FETCH_STATUS = 0
                    BEGIN
                        SET XACT_ABORT ON;

                        BEGIN TRANSACTION SCHEDULE;

                        BEGIN TRY
                            /*Region Logical Querys*/

                            /* DropContraints*/
                            IF(EXISTS (
                                          SELECT *
                                            FROM #GenerateDropContraints DE
                                           WHERE
                                              DE.ObjectId = @Object_id_Alter
                                              AND DE.column_id = @column_id_Alter
                                      )
                              )
                                BEGIN
                                    SET @TempScript = (
                                                          SELECT DE.Script
                                                            FROM #GenerateDropContraints DE
                                                           WHERE
                                                              DE.ObjectId = @Object_id_Alter
                                                              AND DE.column_id = @column_id_Alter
                                                      );

                                    PRINT @TempScript;

                                    EXEC @HasError = sys.sp_executesql @TempScript;

                                    IF(@HasError <> 0)
                                        BEGIN
                                            SELECT CONCAT('Deu Erro :', @TempScript);
                                        END;
                                END;

                            SET @TempScript = '';

                            IF(@HasError = 0)
                                /*Delete Index*/
                                IF(EXISTS (
                                              SELECT *
                                                FROM #GenerateDeleteIndex DE
                                               WHERE
                                                  DE.object_id = @Object_id_Alter
                                                  AND DE.Collum_Id = @column_id_Alter
                                          )
                                  )
                                    BEGIN
                                        IF(EXISTS (
                                                      SELECT *
                                                        FROM sys.syscursors AS S
                                                       WHERE
                                                          S.cursor_name = 'cursor_DeleteIndex'
                                                  )
                                          )
                                            BEGIN
                                                DEALLOCATE cursor_DeleteIndex;
                                            END;

                                        /* declare variables */
                                        DECLARE @DeleteIndex NVARCHAR(1000);

                                        DECLARE cursor_DeleteIndex CURSOR FAST_FORWARD READ_ONLY FOR
                                        SELECT DE.DeleteScript
                                          FROM #GenerateDeleteIndex DE
                                         WHERE
                                            DE.object_id = @Object_id_Alter
                                            AND DE.Collum_Id = @column_id_Alter;

                                        OPEN cursor_DeleteIndex;

                                        FETCH NEXT FROM cursor_DeleteIndex
                                         INTO @DeleteIndex;

                                        WHILE @@FETCH_STATUS = 0
                                            BEGIN
                                                PRINT @DeleteIndex;

                                                IF(EXISTS (
                                                              SELECT 1
                                                                FROM sys.indexes AS I
                                                                     JOIN sys.index_columns AS IC ON I.object_id = IC.object_id
                                                                                                     AND I.index_id = IC.index_id
                                                               WHERE
                                                                  I.object_id = @Object_id_Alter
                                                                  AND IC.column_id = @column_id_Alter
                                                          )
                                                  )
                                                    BEGIN
                                                        PRINT @DeleteIndex;

                                                        EXEC @HasError = sys.sp_executesql @DeleteIndex;

                                                        IF(@HasError <> 0)
                                                            BEGIN
                                                                SELECT CONCAT('Deu Erro :', @DeleteIndex);

                                                                BREAK;
                                                            END;
                                                    END;

                                                FETCH NEXT FROM cursor_DeleteIndex
                                                 INTO @DeleteIndex;
                                            END;

                                        CLOSE cursor_DeleteIndex;
                                        DEALLOCATE cursor_DeleteIndex;
                                    END;

                            SET @TempScript = '';

                            IF(@HasError = 0)
                                --/*Delete Stats*/
                                IF(EXISTS (
                                              SELECT *
                                                FROM #GenerateDeleteStats DE
                                               WHERE
                                                  DE.object_id = @Object_id_Alter
                                                  AND DE.Collum_Id = @column_id_Alter
                                          )
                                  )
                                    BEGIN

                                        /* declare variables */
                                        DECLARE @DeleteStats NVARCHAR(1000);

                                        DECLARE cursor_DeleteStats CURSOR FAST_FORWARD READ_ONLY FOR
                                        SELECT DE.ScriptDrop
                                          FROM #GenerateDeleteStats DE
                                         WHERE
                                            DE.object_id = @Object_id_Alter
                                            AND DE.Collum_Id = @column_id_Alter;

                                        OPEN cursor_DeleteStats;

                                        FETCH NEXT FROM cursor_DeleteStats
                                         INTO @DeleteStats;

                                        WHILE @@FETCH_STATUS = 0
                                            BEGIN
                                                PRINT @DeleteStats;

                                                EXEC @HasError = sys.sp_executesql @DeleteStats;

                                                IF(@HasError <> 0)
                                                    BEGIN
                                                        SELECT CONCAT('Deu Erro :', @DeleteStats);

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

                            IF(@HasError = 0)
                                /*Delete Defaults*/
                                IF(EXISTS (
                                              SELECT *
                                                FROM #GenerateDeleteDefaults DE
                                               WHERE
                                                  DE.object_id = @Object_id_Alter
                                                  AND DE.Collum_Id = @column_id_Alter
                                          )
                                  )
                                    BEGIN
                                        SET @TempScript = (
                                                              SELECT DE.Script
                                                                FROM #GenerateDeleteDefaults DE
                                                               WHERE
                                                                  DE.object_id = @Object_id_Alter
                                                                  AND DE.Collum_Id = @column_id_Alter
                                                          );

                                        PRINT @TempScript;

                                        EXEC @HasError = sys.sp_executesql @TempScript;

                                        IF(@HasError <> 0)
                                            BEGIN
                                                SELECT CONCAT('Deu Erro :', @TempScript);

                                                BREAK;
                                            END;
                                    END;

                            SET @TempScript = '';

                            /*Executa Alter table*/
                            PRINT @ScriptCreate_Alter;

                            IF(@HasError = 0)
                                BEGIN
                                    PRINT @ScriptCreate_Alter;

                                    EXEC @HasError = sys.sp_executesql @ScriptCreate_Alter;
                                END;

                            IF(@HasError <> 0)
                                BEGIN
                                    SELECT CONCAT('Deu Erro :', @ScriptCreate_Alter);

                                    BREAK;
                                END;

                            SET @TempScript = '';

                            IF(@HasError = 0)
                                /*Create Defaults*/
                                IF(EXISTS (
                                              SELECT *
                                                FROM #GenerateCreateDefaults GCD
                                               WHERE
                                                  GCD.object_id = @Object_id_Alter
                                                  AND GCD.Collum_Id = @column_id_Alter
                                          )
                                  )
                                    BEGIN
                                        SET @TempScript = (
                                                              SELECT DE.Script
                                                                FROM #GenerateCreateDefaults DE
                                                               WHERE
                                                                  DE.object_id = @Object_id_Alter
                                                                  AND DE.Collum_Id = @column_id_Alter
                                                          );

                                        PRINT @TempScript;

                                        EXEC @HasError = sys.sp_executesql @TempScript;

                                        IF(@HasError <> 0)
                                            BEGIN
                                                SELECT CONCAT('Deu Erro :', @TempScript);

                                                BREAK;
                                            END;
                                    END;

                            IF(@HasError = 0)
                                /*Create Index*/
                                IF(EXISTS (
                                              SELECT *
                                                FROM #GenerateCreateIndex AS GCI
                                               WHERE
                                                  GCI.ObjectId = @Object_id_Alter
                                                  AND GCI.Collum_Id = @column_id_Alter
                                          )
                                  )
                                    BEGIN

                                        /* declare variables */
                                        DECLARE @IndexNameCreate NVARCHAR(128);
                                        DECLARE @CreateIndex NVARCHAR(1500);

                                        DECLARE cursor_CreateIndex CURSOR FAST_FORWARD READ_ONLY FOR
                                        SELECT DE.IndexName,
                                               DE.ScriptCreate
                                          FROM #GenerateCreateIndex DE
                                         WHERE
                                            DE.ObjectId = @Object_id_Alter
                                            AND DE.Collum_Id = @column_id_Alter;

                                        OPEN cursor_CreateIndex;

                                        FETCH NEXT FROM cursor_CreateIndex
                                         INTO @IndexNameCreate,
                                              @CreateIndex;

                                        WHILE @@FETCH_STATUS = 0
                                            BEGIN
                                                IF(NOT EXISTS (
                                                                  SELECT 1
                                                                    FROM sys.indexes AS I
                                                                         JOIN sys.index_columns AS IC ON I.object_id = IC.object_id
                                                                                                         AND I.index_id = IC.index_id
                                                                   WHERE
                                                                      I.object_id = @Object_id_Alter
                                                                      AND I.name = @IndexNameCreate
                                                              )
                                                  )
                                                    BEGIN
                                                        PRINT @CreateIndex;

                                                        EXEC @HasError = sys.sp_executesql @CreateIndex;

                                                        IF(@HasError <> 0)
                                                            BEGIN
                                                                SELECT CONCAT('Deu Erro :', @CreateIndex);

                                                                BREAK;
                                                            END;
                                                    END;

                                                SET @TempScript = '';

                                                FETCH NEXT FROM cursor_CreateIndex
                                                 INTO @IndexNameCreate,
                                                      @CreateIndex;
                                            END;

                                        CLOSE cursor_CreateIndex;
                                        DEALLOCATE cursor_CreateIndex;
                                    END;

                            IF(@HasError = 0)
                                /*Create Stats*/
                                IF(EXISTS (
                                              SELECT *
                                                FROM #GenerateCreateStats AS GCI
                                               WHERE
                                                  GCI.object_id = @Object_id_Alter
                                                  AND GCI.Collum_Id = @column_id_Alter
                                          )
                                  )
                                    BEGIN
                                        SET @TempScript = (
                                                              SELECT DE.ScriptCreate
                                                                FROM #GenerateCreateStats DE
                                                               WHERE
                                                                  DE.object_id = @Object_id_Alter
                                                                  AND DE.Collum_Id = @column_id_Alter
                                                          );

                                        PRINT @TempScript;

                                        EXEC @HasError = sys.sp_executesql @TempScript;

                                        IF(@HasError <> 0)
                                            BEGIN
                                                SELECT CONCAT('Deu Erro :', @TempScript);

                                                BREAK;
                                            END;
                                    END;

                            /*End region */
                            COMMIT TRANSACTION SCHEDULE;
                        END TRY
                        BEGIN CATCH
                            ROLLBACK TRANSACTION SCHEDULE;

                            DECLARE @ErrorNumber INT = ERROR_NUMBER();
                            DECLARE @ErrorLine INT = ERROR_LINE();
                            DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
                            DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
                            DECLARE @ErrorState INT = ERROR_STATE();

                            SELECT @SchemaName_Alter,
                                   @TableName_Alter,
                                   @Object_id_Alter,
                                   @Coluna_Alter,
                                   @column_id_Alter,
                                   @ScriptCreate_Alter;

                            PRINT 'Actual error number: ' + CAST(@ErrorNumber AS VARCHAR(MAX));
                            PRINT 'Actual line number: ' + CAST(@ErrorLine AS VARCHAR(MAX));
                            PRINT '@ErrorMessage: ' + CAST(@ErrorMessage AS VARCHAR(MAX));
                            PRINT '@ErrorSeverity: ' + CAST(@ErrorLine AS VARCHAR(MAX));
                            PRINT '@ErrorState: ' + CAST(@ErrorLine AS VARCHAR(MAX));

                            RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);

                            PRINT 'Error detected, all changes reversed.';
                        END CATCH;

                        FETCH NEXT FROM cursor_AlteraColuna
                         INTO @SchemaName_Alter,
                              @TableName_Alter,
                              @Object_id_Alter,
                              @Coluna_Alter,
                              @column_id_Alter,
                              @ScriptCreate_Alter;
                    END;

                CLOSE cursor_AlteraColuna;
                DEALLOCATE cursor_AlteraColuna;
            END;

        IF(@Visualizar = 1)
            BEGIN
                SELECT * FROM #Reducao AS R;
            END;
    END;

--Financeiro.ParcelamentosParcelas.IX_ParcelamentosParcelas_DataVencimentoIdParcelaSituacaoPagamento