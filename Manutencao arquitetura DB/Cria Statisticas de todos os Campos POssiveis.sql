
ALTER DATABASE Implanta SET AUTO_CREATE_STATISTICS OFF;


DECLARE @Tabela VARCHAR(128) = NULL; -- 'Despesa.ConciliacoesBancarias';

DECLARE @MostrarEstruturaBancoDeDados BIT = 0;

DECLARE @DeletarStatisticasAutoCriadas BIT = 1;

DECLARE @CamposEsclusao TABLE (Campo VARCHAR(300));

INSERT INTO @CamposEsclusao (Campo)
VALUES ('xml'),
('varbinary');


IF (OBJECT_ID('TEMPDB..#DadosIndices') IS NOT NULL)
    DROP TABLE #DadosIndices;

CREATE TABLE #DadosIndices (
    [object_id] INT,
    [name] NVARCHAR(128),
    [type_desc] NVARCHAR(60),
    [is_unique] BIT,
    [is_primary_key] BIT,
    [is_unique_constraint] BIT,
    [fill_factor] TINYINT,
    [index_column_id] INT);

IF (OBJECT_ID('TEMPDB..#DadosStatisticas') IS NOT NULL)
    DROP TABLE #DadosStatisticas;

CREATE TABLE #DadosStatisticas (
    [object_id] INT,
    [Nome Statistica] NVARCHAR(128),
    [auto_created] BIT,
    [filter_definition] NVARCHAR(MAX),
    [Id Coluna] INT);





IF (OBJECT_ID('TEMPDB..#Dados') IS NOT NULL)
    DROP TABLE #Dados;


CREATE TABLE #Dados (
    [object_id] INT,
    [SchemaName] VARCHAR(128),
    [TableName] VARCHAR(128),
    [Coluna] VARCHAR(128),
    [Type] VARCHAR(100),
    [max_length] SMALLINT,
    [column_id] SMALLINT,
    [is_nullable] BIT,
    [Indexable] BIT,
    [Nome Indice] NVARCHAR(128),
    [Nome Statisticas] NVARCHAR(128),
    [auto_created] BIT,
    [is_unique] BIT,
    [is_primary_key] BIT,
    [index_column_id] INT,
    iscomputed BIT);




IF (OBJECT_ID('TEMPDB..#DadosTabela') IS NOT NULL)
    DROP TABLE #DadosTabela;

CREATE TABLE #DadosTabela (
    SchemaName VARCHAR(128),
    TableName VARCHAR(128),
    object_id INT,
    Coluna VARCHAR(128),
    [Type] VARCHAR(100),
    max_length SMALLINT,
    column_id SMALLINT,
    is_nullable BIT,
    Indexable BIT,
    is_computed BIT);



;WITH DadosTabela
   AS (SELECT SchemaName = S.name,
              TableName = T.name,
              [object_id] = C.object_id,
              [Coluna] = C.name COLLATE DATABASE_DEFAULT,
              [Type] = T2.name,
              C.max_length,
              C.column_id,
              C.is_nullable,
              CAST(COLUMNPROPERTYEX(C.object_id, C.name, 'IsIndexable') AS bit) AS Indexable,
              C.is_computed
         FROM sys.tables AS T
         JOIN sys.schemas AS S
           ON S.SCHEMA_ID       = T.SCHEMA_ID
         JOIN sys.COLUMNS AS C
           ON C.OBJECT_ID       = T.OBJECT_ID
         JOIN sys.types AS T2
           ON T2.system_type_id = C.system_type_id)
INSERT INTO #DadosTabela (SchemaName,
                          TableName,
                          object_id,
                          Coluna,
                          Type,
                          max_length,
                          column_id,
                          is_nullable,
                          Indexable,
                          is_computed)
SELECT T.*
  FROM DadosTabela T
 WHERE T.TableName NOT IN ( 'HangFire.Set' );
WITH DadosIndices
  AS (SELECT I.object_id,
             I.name,
             I.type_desc,
             I.is_unique,
             I.is_primary_key,
             I.is_unique_constraint,
             I.fill_factor,
             IC.index_column_id
        FROM sys.indexes AS I
        JOIN sys.index_columns AS IC
          ON (   I.object_id = IC.object_id
           AND   I.index_id  = IC.index_id)
        JOIN sys.tables AS T
          ON I.object_id     = T.object_id)
INSERT INTO #DadosIndices
SELECT *
  FROM DadosIndices;




WITH Statisticas
  AS (SELECT S.object_id,
             [Nome Statistica] = S.name,
             S.auto_created,
             [filter_definition] = S.filter_definition,
             [Id Coluna] = SC.column_id
        FROM sys.stats AS S
        JOIN sys.stats_columns AS SC
          ON S.object_id  = SC.object_id
         AND S.stats_id   = SC.stats_id
        JOIN sys.tables AS T
          ON SC.object_id = T.object_id)
INSERT INTO #DadosStatisticas
SELECT *
  FROM Statisticas;


INSERT INTO #Dados (object_id,
                    SchemaName,
                    TableName,
                    Coluna,
                    Type,
                    max_length,
                    column_id,
                    is_nullable,
                    Indexable,
                    [Nome Indice],
                    [Nome Statisticas],
                    auto_created,
                    is_unique,
                    is_primary_key,
                    index_column_id,
                    iscomputed)
SELECT DT.object_id,
       DT.SchemaName,
       DT.TableName,
       DT.Coluna,
       DT.Type,
       DT.max_length,
       DT.column_id,
       DT.is_nullable,
       DT.Indexable,
       [Nome Indice] = DI.name,
       DS.[Nome Statistica],
       DS.auto_created,
       DI.is_unique,
       DI.is_primary_key,
       DI.index_column_id,
       DT.is_computed
  FROM #DadosTabela AS DT
  LEFT JOIN #DadosIndices AS DI
    ON DT.object_id       = DI.object_id
   AND DI.index_column_id = DT.column_id
  LEFT JOIN #DadosStatisticas AS DS
    ON DT.object_id       = DS.object_id
   AND DT.column_id       = DS.[Id Coluna];



IF (@DeletarStatisticasAutoCriadas = 1)
BEGIN
    SELECT D.object_id,
           D.SchemaName,
           D.TableName,
           D.Coluna,
           D.[Nome Statisticas],
           Script = CONCAT(
                        ' IF(EXISTS( SELECT 1 FROM sys.stats AS S WHERE S.name = ''',
                        D.[Nome Statisticas],
                        ''')) BEGIN',
                        ' DROP STATISTICS ',
                        D.TableName,
                        '.',
                        D.[Nome Statisticas],
                        ' END')
      FROM #Dados AS D
     WHERE D.auto_created = 1;

END;
WITH DadosGeraNome
  AS (SELECT D.object_id,
             D.SchemaName,
             D.TableName,
             D.Coluna,
             D.Type,
             D.column_id,
             D.auto_created,
             D.is_unique,
             D.iscomputed,
             D.[Nome Statisticas],
             D.is_primary_key,
             [Nova Statistica] = IIF(LEN(D.TableName) > 60,
                                     CONCAT(
                                         'Stats',
                                         REPLACE(
                                             dbo.RetornaSomenteLetrasMaiusculas(D.TableName) COLLATE DATABASE_DEFAULT,
                                             '.',
                                             ''),
                                         D.Coluna COLLATE DATABASE_DEFAULT),
                                     CONCAT(
                                         'Stats',
                                         REPLACE(D.TableName COLLATE DATABASE_DEFAULT, '.', ''),
                                         D.Coluna COLLATE DATABASE_DEFAULT))
        FROM #Dados AS D
       WHERE (   D.is_primary_key = 0
            OR   D.is_primary_key IS NULL))
SELECT R.object_id,
       R.SchemaName,
       R.TableName,
       R.Coluna,
       R.column_id,
       R.[Nome Statisticas],
       R.is_primary_key,
       R.[Nova Statistica],
       Script = CONCAT(
                    ' IF( NOT EXISTS(SELECT * FROM  sys.stats_columns AS SC  WHERE SC.object_id = ''',
                    R.object_id,
                    ''' AND SC.column_id =''',
                    R.column_id,
                    ''')) BEGIN',
                    ' CREATE STATISTICS ',
                    R.[Nova Statistica],
                    ' ON ',
                    QUOTENAME(R.SchemaName),
                    '.',
                    QUOTENAME(R.TableName),
                    '(',
                    QUOTENAME(R.Coluna),
                    ')  WITH FULLSCAN END')
  FROM DadosGeraNome R
 WHERE NOT EXISTS (   SELECT 1
                        FROM sys.stats_columns AS SC
                       WHERE SC.object_id = R.object_id
                         AND SC.column_id = R.column_id);



