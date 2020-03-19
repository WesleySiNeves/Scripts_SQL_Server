SELECT S.name, T.name,
              T.object_id,
              T.principal_id,
              T.type, --'U' -USER_TABLE
              T.create_date,
              T.lob_data_space_id,
              [Total Colunas] = T.max_column_id_used
              FROM  sys.tables AS T
JOIN sys.schemas AS S ON T.schema_id = S.schema_id


