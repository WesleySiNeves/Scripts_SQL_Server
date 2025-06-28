
IF ( OBJECT_ID('TEMPDB..#CamposDateTime') IS NOT NULL )
    DROP TABLE #CamposDateTime;	


CREATE TABLE #CamposDateTime (
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
		 JOIN    sys.sysindexes  S2 ON T.OBJECT_ID = S2.id AND S2.indid =1
         JOIN sys.schemas AS S
           ON S.SCHEMA_ID       = T.SCHEMA_ID
         JOIN sys.COLUMNS AS C
           ON C.OBJECT_ID       = T.OBJECT_ID
         JOIN sys.types AS T2
           ON T2.system_type_id = C.system_type_id)

		    
SELECT *	
  FROM DadosTabela R
  --WHERE [Type] ='datetime'

  