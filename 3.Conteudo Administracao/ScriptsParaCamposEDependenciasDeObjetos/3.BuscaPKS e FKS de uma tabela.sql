

/*Coloque o nome da tabela para verificar as chaves , caso contrario deixe null para verificar todas do banco*/
DECLARE @TabelName VARCHAR(MAX) = 'Despesa.Empenhos';

SELECT  *
FROM    sys.indexes
WHERE   object_id = OBJECT_ID(@TabelName);


SELECT  DC.name ,
        DC.type_desc ,
        DC.create_date ,
        DC.modify_date ,
        DC.is_ms_shipped ,
        DC.is_published ,
        DC.is_schema_published ,
        DC.is_system_named
FROM    sys.default_constraints AS DC
WHERE   parent_object_id = OBJECT_ID(@TabelName);

SELECT *
FROM sys.check_constraints
WHERE parent_object_id = OBJECT_ID(@TabelName);

SELECT * FROM  sys.foreign_keys AS FK 
 WHERE parent_object_id = OBJECT_ID(@TabelName);