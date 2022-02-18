

DECLARE @NomeTipoCampo VARCHAR(MAX) = 'date';
SELECT [Nome Tabela] = T2.name ,
		C.object_id ,
        C.name ,
        C.max_length ,
        C.collation_name ,
        [Nome Tipo] = T.name ,
        [Tipo ID] = T.user_type_id ,
		C.is_nullable ,
        [schema] = T.schema_id ,
        [Tamanho  Bytes] = T.max_length
FROM    sys.columns AS C
        JOIN sys.tables AS T2 ON T2.object_id = C.object_id
        JOIN sys.types AS T ON C.system_type_id = T.system_type_id
WHERE   T.name = ISNULL(@NomeTipoCampo, T.name)
ORDER BY C.user_type_id;