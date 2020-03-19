USE Implanta

--Como encontrar tabelas que são usadas em Views 
--Este script ajuda a várias visualizações de refratores


SELECT   
       OBJECT_NAME(SED.referencing_id ),  
        [Table Dependent] = CONCAT(SED.referenced_schema_name,'.',SED.referenced_entity_name) ,  
       V.create_date ,  
       V.modify_date ,  
       V.is_published ,  
       V.is_schema_published ,  
       V.is_replicated ,  
       V.with_check_option   
        FROM sys.sql_expression_dependencies AS SED  
JOIN sys.views AS V ON V.object_id =SED.referencing_id  
WHERE v.name ='VwGetLancamentosEMovimentosDosExercicios' 
 
 
 /*Segunda opção*/

 SELECT
	OBJECT_NAME(id) ObjectName
	, [text] ObjectText 
FROM sys.syscomments
WHERE LOWER([text]) LIKE '%PlanoContas%'

