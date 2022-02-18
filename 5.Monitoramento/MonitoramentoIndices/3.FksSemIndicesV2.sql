SELECT [SCHEMA] = SCHEMA_NAME(fk.schema_id) ,
        [Tabela] = OBJECT_NAME(fk.parent_object_id) ,
        fk.*
    FROM sys.foreign_keys fk
    WHERE EXISTS ( SELECT *
                    FROM sys.foreign_key_columns fkc
                    WHERE fkc.constraint_object_id = fk.object_id
                        AND NOT EXISTS ( SELECT *
                                            FROM sys.index_columns ic
                                            WHERE ic.object_id = fkc.parent_object_id
                                                AND ic.column_id = fkc.parent_column_id
                                                AND ic.index_column_id = fkc.constraint_column_id ) )
       




		

