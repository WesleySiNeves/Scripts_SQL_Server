



CREATE OR ALTER FUNCTION  Monitor.ufnBuscaCollate(@Database NVARCHAR(200),@ValidarCollateDiferenteDoBanco BIT = 0)
RETURNS TABLE  AS
 RETURN  


WITH Dados AS (

--Verifica o Collation de todos os campos do banco de dados
SELECT   S.name AS SCHEMAName,
		 t2.name  AS Tabela ,
		c.name CollummName,
       t.name AS TypeName,
	   c.max_length,
       c.is_nullable,
       c.is_rowguidcol,
       c.is_identity,
       c.is_computed,
       c.collation_name
	 
  FROM sys.columns AS c
  JOIN sys.tables AS T2 ON t2.object_id = C.object_id
  JOIN sys.schemas AS S ON T2.schema_id = S.schema_id
  JOIN sys.types AS t
    ON t.user_type_id = c.user_type_id
 WHERE c.object_id IN ( SELECT objects.object_id FROM sys.objects WHERE objects.type = 'U' ) --Coluna
   AND (   (   @ValidarCollateDiferenteDoBanco = 1
         AND   c.collation_name                <> DATABASEPROPERTYEX(@Database, 'Collation'))
      OR   @ValidarCollateDiferenteDoBanco     = 0)
)
SELECT R.SCHEMAName,
       R.Tabela,
       R.CollummName,
       R.TypeName,
       R.max_length,
       R.is_nullable,
       R.is_rowguidcol,
       R.is_identity,
       R.is_computed,
       R.collation_name,
	     [Script] = CONCAT('ALTER TABLE ', QUOTENAME(R.SCHEMAName),'.', QUOTENAME(R.Tabela),' ALTER COLUMN ',
		 QUOTENAME( R.CollummName),' ',
		 R.TypeName,'(', IIF( R.max_length = -1,'MAX', CAST(R.max_length AS VARCHAR(5))),') COLLATE  DATABASE_DEFAULT') -- ALTER TABLE Financeiro.MotivosCancelamentos ALTER COLUMN Nome VARCHAR(250) COLLATE  DATABASE_DEFAULT 
		 FROM  Dados R
		 
 --ORDER BY R.SCHEMAName DESC;


 

 
 
