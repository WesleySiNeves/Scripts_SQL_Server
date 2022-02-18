SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO





--DECLARE @bjectId INT = OBJECT_ID('Despesa.TiposDocumentos');

--SELECT * FROM  [HealthCheck].[ufnFindDepenciasOnPrimaryKey]( @bjectId)



CREATE OR ALTER FUNCTION [HealthCheck].[ufnFindDepenciasOnPrimaryKey] (@ObjectId INT)
RETURNS TABLE
AS RETURN
SELECT fk.referenced_object_id ObjectIdPai,
       OBJECT_SCHEMA_NAME(fk.referenced_object_id) AS SchemaNamePai,
       OBJECT_NAME(fk.referenced_object_id) AS TableNamePai,
	   (
	   SELECT C2.name FROM sys.indexes AS I
	   JOIN sys.index_columns AS IC ON IC.object_id = I.object_id AND IC.index_id = I.index_id
	   JOIN sys.columns AS C2 ON C2.object_id = IC.object_id AND C2.column_id = IC.column_id
	   WHERE I.object_id =fk.referenced_object_id
	   AND I.type =1
	   ) AS ColunaPK,
       t.name AS TableName,
       S2.name AS SchemaWithForeignKey,
       t.name AS TableWithForeignKey,
       S.rows,
       FK2.name AS ForeignkeysName,
       fk.constraint_column_id AS FK_PartNo,
       c.name AS ForeignKeyColumn,
       c.column_id AS ForeignKeyColumn_Id
FROM sys.foreign_key_columns AS fk
    JOIN sys.foreign_keys AS FK2
        ON fk.parent_object_id = FK2.parent_object_id AND fk.referenced_object_id = FK2.referenced_object_id
    INNER JOIN sys.tables AS t
        ON fk.parent_object_id = t.object_id
    JOIN sys.schemas AS S2
        ON t.schema_id = S2.schema_id
    JOIN sys.sysindexes AS S
        ON t.object_id = S.id
           AND S.indid = 1
    INNER JOIN sys.columns AS c
        ON fk.parent_object_id = c.object_id
           AND fk.parent_column_id = c.column_id
WHERE fk.referenced_object_id = @ObjectId;


GO


--SELECT * FROM sys.foreign_key_columns AS FKC
--JOIN sys.foreign_keys AS FK ON FKC.parent_object_id = FK.parent_object_id AND FKC.referenced_object_id = FK.referenced_object_id
--WHERE FK.referenced_object_id =1151343166