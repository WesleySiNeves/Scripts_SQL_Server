DECLARE @Campo VARCHAR(100) = 'datetime';

IF (OBJECT_ID('TEMPDB..#DadosTabela') IS NOT NULL)
    DROP TABLE #DadosTabela;

CREATE TABLE #DadosTabela (
    [object_id] INT,
    [Schema] NVARCHAR(128),
    [name] NVARCHAR(128),
    [schema_id] INT,
    [type] CHAR(2),
    [type_desc] NVARCHAR(60),
    [durability_desc] NVARCHAR(60),
    [temporal_type] TINYINT,
    [temporal_type_desc] NVARCHAR(60));


IF (OBJECT_ID('TEMPDB..#DadosColunas') IS NOT NULL)
    DROP TABLE #DadosColunas;

CREATE TABLE #DadosColunas (
    [object_id] INT,
    [Tabela] NVARCHAR(128),
    [Coluna] NVARCHAR(128),
    [column_id] INT,
    [user_type_id] INT,
    [max_length] SMALLINT,
    [precision] TINYINT,
    [Type] NVARCHAR(128),
    [scale] TINYINT,
    [is_nullable] BIT,
    [is_identity] BIT,
    [is_computed] BIT,
    [is_filestream] BIT);



WITH DadosTabela
  AS (SELECT T.object_id,
             [Schema] = S.name,
             T.name,
             T.schema_id,
             T.type,
             T.type_desc,
             T.durability_desc,
             T.temporal_type,
             T.temporal_type_desc
        FROM sys.tables AS T
        JOIN sys.schemas AS S
          ON T.schema_id = S.schema_id)
INSERT INTO #DadosTabela
SELECT *
  FROM DadosTabela AS DT;


INSERT INTO #DadosColunas
SELECT T.object_id,
       [Tabela] = T.name,
       [Coluna] = C.name,
       C.column_id,
       C.user_type_id,
       C.max_length,
       C.precision,
       [Type] = T2.name,
       C.scale,
       C.is_nullable,
       C.is_identity,
       C.is_computed,
       C.is_filestream
  FROM sys.tables AS T
  JOIN sys.columns AS C
    ON T.object_id    = C.object_id
  JOIN sys.types AS T2
    ON C.user_type_id = T2.user_type_id;



SELECT DC.object_id,
       DT.[Schema],
       DC.Tabela,
       DC.Coluna,
       DC.column_id,
       DC.user_type_id,
       DC.max_length,
       DC.precision,
       DC.Type,
       DC.scale,
       DC.is_nullable,
       DC.is_identity,
       DC.is_computed,
       DC.is_filestream
  FROM #DadosTabela AS DT
  JOIN #DadosColunas AS DC
    ON DT.object_id = DC.object_id
 WHERE DC.Type = @Campo
 ORDER BY DT.[Schema],
          DT.name;


