

-- ==================================================================
--Observação: Forma 1

-- ==================================================================

SELECT OBJECT_NAME(Dep.referencing_id),
       Dep.referenced_database_name,
       Dep.referenced_schema_name,
       Dep.referenced_entity_name
  FROM sys.sql_expression_dependencies Dep
 WHERE OBJECT_NAME(Dep.referenced_id) = 'Pessoas'
   AND OBJECT_DEFINITION(Dep.referencing_id) LIKE '%ufnValorPagamentoLiquido%';

   SELECT OBJECT_NAME(Dep.referencing_id),
       Dep.referenced_database_name,
       Dep.referenced_schema_name,
       Dep.referenced_entity_name
  FROM sys.sql_expression_dependencies Dep
 WHERE OBJECT_DEFINITION(Dep.referencing_id) LIKE '%ufnValorPagamentoLiquido%';

 

 SELECT * FROM  Despesa.Pagamentos AS P
 SELECT Despesa.ufnValorPagamentoLiquido('94B9B89F-2A7C-46CE-990E-00001D695E5B')

-- ==================================================================
--Observação: Forma 2
-- ==================================================================
SELECT referencing_schema_name = SCHEMA_NAME(o.schema_id),
       referencing_object_name = o.name,
       referencing_object_type_desc = o.type_desc,
       sed.referenced_schema_name,
       referenced_object_name = sed.referenced_entity_name,
       referenced_object_type_desc = o1.type_desc,
       sed.referenced_server_name,
       sed.referenced_database_name
  FROM sys.sql_expression_dependencies sed
       INNER JOIN sys.objects o ON sed.referencing_id = o.object_id
       LEFT OUTER JOIN sys.objects o1 ON sed.referenced_id = o1.object_id
 WHERE
    sed.referenced_entity_name = 'Pessoas';