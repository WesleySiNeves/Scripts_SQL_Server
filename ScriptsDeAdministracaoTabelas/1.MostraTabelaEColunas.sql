WITH Dados
    AS
    (
        SELECT TableName = CONCAT(S.name, '.', T.name),
               C.name AS CollumName,
               C.system_type_id AS Type_Id,
               T2.name AS Type_Name,
               C.max_length AS TamanhoMaximo,
               C.precision,
               C.scale,
               C.column_id,
               C.is_nullable
          FROM sys.tables AS T
               JOIN sys.schemas AS S ON S.schema_id = T.schema_id
               JOIN sys.columns AS C ON C.object_id = T.object_id
               JOIN sys.types AS T2 ON T2.system_type_id = C.system_type_id
         WHERE
            S.name NOT LIKE '%HangFire%'
    )
SELECT * FROM Dados R;
