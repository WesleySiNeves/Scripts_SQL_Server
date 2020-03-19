

-- ==================================================================
--Observação: Esse Script foi feito com base na leitura  do manual
/* https://docs.microsoft.com/en-us/sql/t-sql/data-types/datetime-transact-sql?view=sql-server-2017
 */
-- ==================================================================




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
          JOIN sys.schemas AS S ON S.SCHEMA_ID       = T.SCHEMA_ID
          JOIN sys.COLUMNS AS C ON C.OBJECT_ID       = T.OBJECT_ID JOIN sys.types AS T2 ON T2.system_type_id = C.system_type_id
		 
		 
		   )
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




SELECT DT.SchemaName,
       DT.TableName,
       DT.object_id,
       DT.Coluna,
       DT.Type,
       DT.max_length,
       DT.column_id,
       DT.is_nullable,
       DT.Indexable,
       DT.is_computed,
       Script = CONCAT(
                    'IF (EXISTS (SELECT * FROM ',
                    QUOTENAME(DT.SchemaName),
                    '.',
                    QUOTENAME(DT.TableName),
                    ')) BEGIN',
                    ' IF (EXISTS (   SELECT X.',
                    DT.Coluna,
                    ' FROM ',
                    DT.SchemaName,
                    '.',
                    DT.TableName,
                    ' AS X ',
                    'WHERE TRY_CAST(X.',
                    DT.Coluna,
                    ' AS TIME) <>' ,CHAR(39),'00:00:00.0000000',CHAR(39),')) BEGIN ',
                    'ALTER TABLE ',
                    DT.SchemaName,
                    '.',
                    DT.TableName,
                    ' ALTER COLUMN ',
                    DT.Coluna,
                    ' DATETIME2(3) NOT NULL  END; END;',
                    'ELSE ',
                    ' BEGIN  ',
                    'ALTER TABLE ',
                    DT.SchemaName,
                    '.',
                    DT.TableName,
                    ' ALTER COLUMN  ',
                    DT.Coluna,
                    ' DATETIME2(3) NOT NULL END;')
  FROM #DadosTabela AS DT
 WHERE DT.Type = 'datetime'
 ORDER BY DT.SchemaName,
          DT.TableName;



		  


--		  IF (EXISTS (SELECT * FROM Acesso.BloqueiosUsuarios)) BEGIN

--          IF (EXISTS (   SELECT BU.DataBloqueio
--                     FROM Acesso.BloqueiosUsuarios AS BU
--                    WHERE TRY_CAST(BU.DataBloqueio AS TIME) <> '00:00:00.0000000'))
--    BEGIN
--        ALTER TABLE Acesso.BloqueiosUsuarios
--        ALTER COLUMN DataBloqueio DATETIME2(3) NOT NULL;

--    END;
--END;
--ELSE
--BEGIN

--    ALTER TABLE Acesso.BloqueiosUsuarios
--    ALTER COLUMN DataBloqueio DATETIME2(3) NOT NULL;
--END;


