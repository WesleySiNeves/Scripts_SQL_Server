WITH Dados
  AS (SELECT [SchemaName] = S.name,
             [TableName] = T.name,
             [ObjectID ] = T.object_id,
             IndexName = I.name,
             T.type, --'U' -USER_TABLE
             [TotalIndexPorTable] = COUNT(I.object_id) OVER (PARTITION BY S.name,
                                                                          T.name,
                                                                          I.object_id
                                                            )
      FROM sys.tables AS T
           JOIN
           sys.schemas AS S ON T.schema_id = S.schema_id
           JOIN
           sys.indexes AS I ON T.object_id = I.object_id
     )
SELECT R.SchemaName,
       R.TableName,
       R.[ObjectID ],
       R.IndexName,
       R.type,
       R.TotalIndexPorTable
FROM Dados R
ORDER BY R.TotalIndexPorTable DESC
