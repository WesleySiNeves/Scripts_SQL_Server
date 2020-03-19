




/* ==================================================================
--Data: 27/11/2018 
--Autor :Wesley Neves
--Observação: Procura campos do Tipo UNIQUEIDENTIFIER que não são primary Keys e nem Foren Keys
 
-- ==================================================================
*/

--CREATE SCHEMA HealthCheck
CREATE OR ALTER PROCEDURE HealthCheck.uspGetFieldsUniqueIndentityFierNonContraints


AS 
BEGIN
		

IF (OBJECT_ID('TEMPDB..#CamposIdentier') IS NOT NULL)
    DROP TABLE #CamposIdentier;

IF (OBJECT_ID('TEMPDB..#TabelasExcecoes') IS NOT NULL)
    DROP TABLE #TabelasExcecoes;

CREATE TABLE #TabelasExcecoes (Name VARCHAR(200));

IF (OBJECT_ID('TEMPDB..#SchemaExcecoes') IS NOT NULL)
    DROP TABLE #SchemaExcecoes;

CREATE TABLE #SchemaExcecoes (Name VARCHAR(200));

INSERT INTO #TabelasExcecoes (Name)
VALUES
 ('ColetasRFID'),('Transparencia'),('SessoesRemotas')



INSERT INTO #SchemaExcecoes (Name)
VALUES
 ('dbo'),('Expurgo'),('DNE'),('TCU'),('TCU2016'),('Agenda'),('Log'),('Cielo'),('Forzip')

SELECT T.object_id,
       S.name AS SchemaName,
       T.name AS TableName,
       C.name AS CollumName,
       C.column_id,
       T2.name AS TipoDados,
       PK.name AS PK,
       ForenK.name,
       ForenK.object_id,
       ForenK.column_id
  FROM sys.tables AS T
  JOIN sys.columns AS C
    ON T.object_id     = C.object_id
  JOIN sys.types AS T2
    ON T2.user_type_id = C.user_type_id
  JOIN sys.schemas AS S
    ON T.schema_id     = S.schema_id
  LEFT JOIN (   SELECT I.object_id,
                       IC.index_id,
                       I.name,
                       IC.column_id
                  FROM sys.indexes AS I
                  JOIN sys.index_columns AS IC
                    ON I.object_id = IC.object_id
                   AND I.index_id  = IC.index_id
                 WHERE I.type = 1) AS PK
    ON T.object_id     = PK.object_id
   AND PK.column_id    = C.column_id
  LEFT JOIN (   SELECT FK.name,
                       FK.parent_object_id AS object_id,
                       FKC.parent_column_id AS column_id
                  FROM sys.foreign_keys AS FK
                  JOIN sys.foreign_key_columns AS FKC
                    ON FK.parent_object_id = FKC.parent_object_id) ForenK
    ON T.object_id     = ForenK.object_id
   AND C.column_id     = ForenK.column_id
 WHERE C.user_type_id = 36
   AND PK.object_id IS NULL
   AND ForenK.object_id IS NULL
   AND S.name NOT IN
   (
   SELECT SE.Name COLLATE DATABASE_DEFAULT FROM #SchemaExcecoes AS SE
   )
   AND 
   T.name NOT IN
   (
   SELECT TE.Name COLLATE DATABASE_DEFAULT FROM #TabelasExcecoes AS TE
   )
 ORDER BY S.name,
          T.name;


END

