

/* ==================================================================
--Data: 22/01/2019 
--Autor :Wesley Neves
--Observação: Colunas UniqueIdentifier cque contem Tipo no nome que não são vinculadas as foren keys
 
-- ==================================================================
*/

DECLARE @ObjectName VARCHAR(256) = NULL;-- 'Processo.ProcessosAdministrativos';


WITH Dados
AS (SELECT T.object_id,
           S.name AS SchemaName,
           T.name AS TableName,
           S2.rowcnt,
           C.name AS Coluna,
           T2.name AS Tipo,
           C.column_id,
           C.max_length,
           C.is_nullable
    FROM sys.schemas AS S
        JOIN sys.tables AS T
            ON S.schema_id = T.schema_id
        JOIN sys.columns AS C
            ON T.object_id = C.object_id
        JOIN sys.types AS T2
            ON C.system_type_id = T2.system_type_id
        JOIN sys.sysindexes AS S2
            ON S2.id = T.object_id
               AND S2.indid = 1
    WHERE T2.name = 'uniqueidentifier'
          AND (
                  C.name LIKE '%status%'
                  OR C.name LIKE '%tipo%'
              )
   )
SELECT R.object_id,
       R.SchemaName,
       R.TableName,
       R.rowcnt,
       R.Coluna,
       R.Tipo,
       R.column_id,
       R.max_length,
       R.is_nullable,
       Refe.parent_object_id
FROM Dados R
    OUTER APPLY
(
    --Financeiro	Debitos	728620	IdDebitoTipo	uniqueidentifier	2	16	0
    SELECT FKC.*
    FROM sys.foreign_key_columns AS FKC
        JOIN sys.foreign_keys AS FK
            ON FKC.parent_object_id = FK.parent_object_id
               AND FKC.referenced_object_id = FK.referenced_object_id
    WHERE FKC.parent_object_id = R.object_id
          AND FKC.parent_column_id = R.column_id
) Refe
WHERE Refe.parent_object_id IS NULL
      AND NOT EXISTS
(
    SELECT *
    FROM sys.indexes AS I
        JOIN sys.index_columns IC
            ON I.object_id = IC.object_id
               AND I.index_id = IC.index_id
    WHERE I.object_id = R.object_id
          AND I.type = 1
          AND IC.column_id = R.column_id
)
AND 
(
@ObjectName IS NULL
OR CONCAT(R.SchemaName,'.',R.TableName) = @ObjectName
)
ORDER BY R.rowcnt DESC;

