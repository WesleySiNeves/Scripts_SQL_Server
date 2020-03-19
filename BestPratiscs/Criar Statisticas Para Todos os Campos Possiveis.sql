






DECLARE @DeletarStatisticas BIT = 0;

DECLARE @CriarTodasStatisticasBanco BIT = 1;

DECLARE @tabela VARCHAR(128) = NULL;


IF (OBJECT_ID('TEMPDB..#Resultado') IS NOT NULL)
    DROP TABLE #Resultado;


CREATE TABLE #Resultado (
    [ObjectIdTable] INT,
    [SchemaName] NVARCHAR(128),
    [TableName] NVARCHAR(128),
    [ColunName] NVARCHAR(128),
    [column_id Table] INT,
    [Type Name] NVARCHAR(128),
    [ObjectIdIndex] INT,
    [IndexName] NVARCHAR(128),
    [Index_type_desc] NVARCHAR(60),
    [Index_is_primary_key] BIT,
    [Index_index_id] INT,
    [Index_index_column_id] INT,
    [Index_column_id] INT,
    [Stats_object_id] INT,
    [NomeStatistica] NVARCHAR(128),
    [Stats_stats_id] INT,
    [Stats_auto_created] BIT,
    [Stats_stats_column_id] INT,
    [Stats_column_id] INT,
    [PertencenteIndex] INT);

IF (OBJECT_ID('TEMPDB..#DadosTabela') IS NOT NULL)
    DROP TABLE #DadosTabela;

CREATE TABLE #DadosTabela (
    [object_id] INT,
    [SchemaName] NVARCHAR(128),
    [TableName] NVARCHAR(128),
    [ColunName] NVARCHAR(128),
    [column_id] INT,
    [Type Name] NVARCHAR(128),
    [Tamanho Maximo Coluna] SMALLINT,
    IsDeterministic BIT,
    [is_nullable] BIT,
    [is_computed] BIT);

IF (OBJECT_ID('TEMPDB..#DadosStatisticas') IS NOT NULL)
    DROP TABLE #DadosStatisticas;

CREATE TABLE #DadosStatisticas (
    [name] NVARCHAR(128),
    [object_id] INT,
    [NomeStatistica] NVARCHAR(128),
    [stats_id] INT,
    [auto_created] BIT,
    [stats_column_id] INT,
    [column_id] INT);


IF (OBJECT_ID('TEMPDB..#DadosIndices') IS NOT NULL)
    DROP TABLE #DadosIndices;

CREATE TABLE #DadosIndices (
    [object_id] INT,
    [name] NVARCHAR(128),
    [type_desc] NVARCHAR(60),
    [is_unique] BIT,
    [is_primary_key] BIT,
    [index_id] INT,
    [index_column_id] INT,
    [column_id] INT,
    [key_ordinal] TINYINT,
    [is_descending_key] BIT,
    [is_included_column] BIT);


WITH DadosTabela
  AS (SELECT T.object_id,
             [SchemaName] = S.name,
             [TableName] = T.name,
             [ColunName] = C.name,
             C.column_id,
             [Type Name] = T2.name,
             [Tamanho Maximo Coluna] = C.max_length,
             IsDeterministic = IIF(COLUMNPROPERTY(C.object_id, C.name, 'IsDeterministic') IS NULL,
                                   1,
                                   COLUMNPROPERTY(C.object_id, C.name, 'IsDeterministic')),
             C.is_nullable,
             C.is_computed
        FROM sys.tables AS T
        JOIN sys.schemas AS S
          ON T.schema_id       = S.schema_id
        JOIN sys.columns AS C
          ON T.object_id       = C.object_id
        JOIN sys.types AS T2
          ON T2.system_type_id = C.system_type_id)
INSERT INTO #DadosTabela
SELECT *
  FROM DadosTabela T;




WITH Statiscticas
  AS (SELECT T.name,
             T.object_id,
             [NomeStatistica] = S.name,
             S.stats_id,
             S.auto_created,
             SC.stats_column_id,
             SC.column_id
        FROM sys.stats AS S
        JOIN sys.stats_columns AS SC
          ON S.object_id = SC.object_id
         AND S.stats_id  = SC.stats_id
        JOIN sys.tables AS T
          ON S.object_id = T.object_id)
INSERT INTO #DadosStatisticas
SELECT S.name,
       S.object_id,
       S.NomeStatistica,
       S.stats_id,
       S.auto_created,
       S.stats_column_id,
       S.column_id
  FROM Statiscticas S;


WITH DadosIndices
  AS (SELECT I.object_id,
             I.name,
             I.type_desc,
             I.is_unique,
             I.is_primary_key,
             IC.index_id,
             IC.index_column_id,
             IC.column_id,
             IC.key_ordinal,
             IC.is_descending_key,
             IC.is_included_column
        FROM sys.indexes AS I
        JOIN sys.index_columns AS IC
          ON I.object_id = IC.object_id
         AND I.index_id  = IC.index_id
       WHERE I.object_id > 100)
INSERT INTO #DadosIndices
SELECT *
  FROM DadosIndices;


WITH Projecao
  AS (SELECT [ObjectIdTable] = DT.object_id,
             [SchemaName] = DT.SchemaName,
             [TableName] = DT.TableName,
             [ColunName] = DT.ColunName,
             [column_id Table] = DT.column_id,
             [Type Name] = DT.[Type Name],
             [ObjectIdIndex] = I.object_id,
             [IndexName] = I.name,
             [Index_type_desc] = I.type_desc,
             [Index_is_primary_key] = I.is_primary_key,
             [Index_index_id] = I.index_id,
             [Index_index_column_id] = I.index_column_id,
             [Index_column_id] = I.column_id,
             [Stats_object_id] = S.object_id,
             S.NomeStatistica,
             [Stats_stats_id] = S.stats_id,
             [Stats_auto_created] = S.auto_created,
             [Stats_stats_column_id] = S.stats_column_id,
             [Stats_column_id] = S.column_id,
             [PertencenteIndex] = IIF(I.name = S.NomeStatistica, 1, 0)
        FROM #DadosTabela AS DT
        LEFT JOIN #DadosIndices AS I
          ON DT.object_id    = I.object_id
         AND DT.column_id    = I.column_id
        LEFT JOIN #DadosStatisticas AS S
          ON DT.object_id    = S.object_id
         AND DT.column_id    = S.column_id
         AND (   I.object_id IS NULL
            OR   (I.index_id = S.stats_id))
       WHERE DT.IsDeterministic = 1
         /*Tipo de dados que não podem ter indices ou statisticas*/
         AND DT.[Type Name] NOT IN ( 'xml', 'varbinary' )
         AND NOT (
                     /*Colunas Com vachar(max)*/
                     DT.[Type Name] = 'varchar'
               AND   DT.[Tamanho Maximo Coluna] = -1)
         AND DT.object_id       = IIF(@tabela IS NULL, DT.object_id, OBJECT_ID(@tabela)))
INSERT INTO #Resultado
SELECT P.ObjectIdTable,
       P.SchemaName,
       P.TableName,
       P.ColunName,
       P.[column_id Table],
       P.[Type Name],
       P.ObjectIdIndex,
       P.IndexName,
       P.Index_type_desc,
       P.Index_is_primary_key,
       P.Index_index_id,
       P.Index_index_column_id,
       P.Index_column_id,
       P.Stats_object_id,
       P.NomeStatistica,
       P.Stats_stats_id,
       P.Stats_auto_created,
       P.Stats_stats_column_id,
       P.Stats_column_id,
       P.PertencenteIndex
  FROM Projecao P
 ORDER BY P.SchemaName,
          P.TableName,
          P.[column_id Table];




IF (@DeletarStatisticas = 1)
BEGIN
    SELECT 'Statisticas Colunares(que não pertencem a indices)';
    SELECT R.ObjectIdTable,
           R.SchemaName,
           R.TableName,
           R.ColunName,
           R.[column_id Table],
           R.[Type Name],
           R.ObjectIdIndex,
           R.IndexName,
           R.Index_type_desc,
           R.Index_is_primary_key,
           R.Index_index_id,
           R.Index_index_column_id,
           R.Index_column_id,
           R.Stats_object_id,
           R.NomeStatistica,
           R.Stats_stats_id,
           R.Stats_auto_created,
           R.Stats_stats_column_id,
           R.Stats_column_id,
           R.PertencenteIndex,
           ScriptDelecao = CONCAT(
                               ' IF(EXISTS( SELECT 1 FROM sys.stats AS S WHERE S.name = ''',
                               R.NomeStatistica,
                               ''')) BEGIN',
                               ' DROP STATISTICS ',
                               QUOTENAME(R.SchemaName),
                               '.',
                               QUOTENAME(R.TableName),
                               '.',
                               QUOTENAME(R.NomeStatistica),
                               ' END')
      FROM #Resultado AS R
     WHERE R.NomeStatistica IS NOT NULL
       AND R.PertencenteIndex = 0;
END;





IF (@CriarTodasStatisticasBanco = 1)
BEGIN
    ;WITH NovasStatisticas
       AS (SELECT R.ObjectIdTable,
                  R.SchemaName,
                  R.TableName,
                  R.ColunName,
                  R.[column_id Table],
                  R.[Type Name],
             
                  R.PertencenteIndex,
                  [Nova Statistica] = IIF(LEN(R.TableName) > 60,
                                          CONCAT(
                                              'Stats',
                                              REPLACE(
                                                  dbo.RetornaSomenteLetrasMaiusculas(R.TableName) COLLATE DATABASE_DEFAULT,
                                                  '.',
                                                  ''),
                                              R.ColunName COLLATE DATABASE_DEFAULT),
                                          CONCAT(
                                              'Stats',
                                              REPLACE(R.TableName COLLATE DATABASE_DEFAULT, '.', ''),
                                              R.ColunName COLLATE DATABASE_DEFAULT))
             FROM #Resultado AS R
            WHERE R.NomeStatistica IS NULL
              AND NOT EXISTS (   SELECT S.name,
                                        SC.*
                                   FROM sys.stats_columns AS SC
                                   JOIN sys.stats AS S
                                     ON SC.object_id = S.object_id
                                    AND SC.stats_id  = S.stats_id
                                  WHERE SC.object_id = R.ObjectIdTable
                                    AND SC.column_id = R.[column_id Table]))
    SELECT R.ObjectIdTable,
           R.SchemaName,
           R.TableName,
           R.ColunName,
           R.[column_id Table],
           R.[Type Name],
           R.PertencenteIndex,
           R.[Nova Statistica],
           Script = CONCAT(
                        ' IF( NOT EXISTS(SELECT * FROM  sys.stats_columns AS SC  WHERE SC.object_id = ''',
                        R.ObjectIdTable,
                        ''' AND SC.column_id =''',
                        R.[column_id Table],
                        ''')) BEGIN',
                        ' CREATE STATISTICS ',
                        R.[Nova Statistica],
                        ' ON ',
                        QUOTENAME(R.SchemaName),
                        '.',
                        QUOTENAME(R.TableName),
                        '(',
                        QUOTENAME(R.ColunName),
                        ')  WITH FULLSCAN END')
      FROM NovasStatisticas R;


END;

