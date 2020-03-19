SELECT T.name,
       C.name,
       C.user_type_id,
       T2.name,
       C.max_length
FROM sys.tables AS T
    JOIN sys.columns AS C
        ON T.object_id = C.object_id
    JOIN sys.types AS T2
        ON C.user_type_id = T2.user_type_id
WHERE T2.name = 'varchar'
      AND C.name LIKE '%Data%';

