DECLARE @NomeCampo NVARCHAR(128) = '%Data%';

SELECT [Schema] = S.name,
       [Coluna] = c.name,
       [Tabela] = t.name,
       [Type] = T2.name
  FROM sys.columns c
       JOIN sys.types AS T2 ON T2.system_type_id = c.system_type_id
       JOIN sys.tables t ON c.object_id = t.object_id
       JOIN sys.schemas AS S ON t.schema_id = S.schema_id
 WHERE
    c.name LIKE @NomeCampo
    AND T2.name NOT IN ('datetime','datetime2','date')
 ORDER BY
    Tabela,
    Coluna;