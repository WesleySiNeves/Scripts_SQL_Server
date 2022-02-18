USE Implanta


DECLARE @Tabela VARCHAR(128) =NULL;-- 'Despesa.ConciliacoesBancarias';


DECLARE @CamposEsclusao TABLE
(
 Campo VARCHAR(300)
)

INSERT INTO @CamposEsclusao (Campo)
VALUES ('xml')

SELECT * FROM @CamposEsclusao AS CE



DECLARE @DeletarStatisticasAutoCriadas BIT = 1;

IF (OBJECT_ID('TEMPDB..#Dados') IS NOT NULL)
    DROP TABLE #Dados;


CREATE TABLE #Dados (
    [object_id] INT,
    [TableName] VARCHAR(128),
    [Coluna] VARCHAR(128),
    [Type] VARCHAR(100),
    [max_length] SMALLINT,
    [column_id] SMALLINT,
    [is_nullable] BIT,
    [Nome Indice] NVARCHAR(128),
    [Nome Statisticas] NVARCHAR(128),
    [auto_created] BIT,
    [is_unique] BIT,
    [is_primary_key] BIT,
    [index_column_id] INT);



DECLARE @DadosTabela AS TABLE (
    TableName VARCHAR(128),
    object_id INT,
    Coluna VARCHAR(128),
    [Type] VARCHAR(100),
    max_length SMALLINT,
    column_id SMALLINT,
    is_nullable BIT,
	Indexable bit);
WITH DadosTabela
  AS (SELECT TableName = CONCAT(S.name COLLATE DATABASE_DEFAULT, '.', T.name COLLATE DATABASE_DEFAULT),
             C.object_id,
             [Coluna] = C.name COLLATE DATABASE_DEFAULT,
             [Type] = T2.name,
             C.max_length,
             C.column_id,
             C.is_nullable,
			CAST(COLUMNPROPERTYEX(C.object_id, C.name, 'IsIndexable') AS bit) AS Indexable 
			 
        FROM sys.tables AS T
        JOIN sys.schemas AS S
          ON S.schema_id       = T.schema_id
        JOIN sys.columns AS C
          ON C.object_id       = T.object_id
        JOIN sys.types AS T2
          ON T2.system_type_id = C.system_type_id)
INSERT INTO @DadosTabela
SELECT T.*
  FROM DadosTabela T
  WHERE T.TableName NOT IN
  (
  'HangFire.Set'
  )
  AND T.Indexable = 1
 


;WITH DadosIndices
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
           ON I.object_id = IC.object_id
          AND I.index_id  = IC.index_id),
      Statisticas
   AS (SELECT S.object_id,
              S.name,
              S.auto_created,
              SC.column_id
         FROM sys.stats AS S
         JOIN sys.stats_columns AS SC
           ON S.object_id = SC.object_id
          AND S.stats_id  = SC.stats_id)
INSERT INTO #Dados
SELECT DT.object_id,
       DT.TableName,
       DT.Coluna,
       DT.Type,
       DT.max_length,
       DT.column_id,
       DT.is_nullable,
       [Nome Indice] = Idx.name,
       [Nome Statisticas] = S.name,
       S.auto_created,
       Idx.is_unique,
       Idx.is_primary_key,
       Idx.index_column_id
  FROM @DadosTabela AS DT
  LEFT JOIN DadosIndices Idx
    ON DT.object_id = Idx.object_id
   AND DT.column_id = Idx.index_column_id
  LEFT JOIN Statisticas S
    ON DT.object_id = S.object_id
   AND DT.column_id = S.column_id
 WHERE DT.TableName = ISNULL(@Tabela,DT.TableName);


SELECT D.object_id,
       D.TableName,
       D.Coluna,
       D.Type,
       D.max_length,
       D.column_id,
       D.is_nullable,
       D.[Nome Indice],
       D.[Nome Statisticas],
       D.auto_created,
       D.is_unique,
       D.is_primary_key,
       D.index_column_id
  FROM #Dados AS D
 WHERE D.auto_created = 1;


IF (@DeletarStatisticasAutoCriadas = 1)
BEGIN
    SELECT 'Script de Deleção';

    SELECT Id = ROW_NUMBER() OVER (ORDER BY (SELECT NULL)),
           D.TableName COLLATE DATABASE_DEFAULT,
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
     WHERE D.auto_created = 1
	 ORDER BY D.TableName,D.Coluna

END

;
WITH GeraNome
  AS (SELECT D.object_id,
             TableName= D.TableName COLLATE DATABASE_DEFAULT,
             Coluna= D.Coluna COLLATE DATABASE_DEFAULT,
             D.Type,
             D.max_length,
             D.column_id,
             D.is_nullable,
            [Nome Indice]= D.[Nome Indice] COLLATE DATABASE_DEFAULT,
            [Nome Statisticas]=  D.[Nome Statisticas] COLLATE DATABASE_DEFAULT,
             D.auto_created,
             D.is_unique,
             D.is_primary_key,
             D.index_column_id,
             [Nova Statistica] = CONCAT('Stats', REPLACE(D.TableName COLLATE DATABASE_DEFAULT, '.', ''), D.Coluna COLLATE DATABASE_DEFAULT)
        FROM #Dados AS D
       WHERE D.[Nome Statisticas] IS NULL)
SELECT R.object_id,
       R.TableName COLLATE DATABASE_DEFAULT,
       R.Coluna COLLATE DATABASE_DEFAULT,
       R.Type,
       R.max_length,
       R.column_id,
       R.is_nullable,
       R.[Nome Indice],
       R.[Nome Statisticas] COLLATE DATABASE_DEFAULT,
       R.auto_created,
       R.is_unique,
       R.is_primary_key,
       R.index_column_id,
       R.[Nova Statistica],
       Script = CONCAT(
                    ' IF(NOT EXISTS( SELECT 1 FROM sys.stats AS S WHERE S.name = ''',
                    R.[Nova Statistica],
                    ''')) BEGIN',
                    ' CREATE STATISTICS ',
                    R.[Nova Statistica],
                    ' ON ',
                    R.TableName,
                    '(',
                    R.Coluna,
                    ')  WITH FULLSCAN END')
  FROM GeraNome R
  WHERE R.Type NOT IN(SELECT CE.Campo COLLATE DATABASE_DEFAULT FROM @CamposEsclusao AS CE);


