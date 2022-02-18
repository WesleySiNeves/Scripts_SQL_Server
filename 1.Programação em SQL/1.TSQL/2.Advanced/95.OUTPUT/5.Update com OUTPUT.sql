USE TSQLV4;

SELECT *
  FROM Production.Categories AS C;


IF (OBJECT_ID('TEMPDB..#DadosAlterados') IS NOT NULL)
    DROP TABLE #DadosAlterados;

ALTER TABLE Production.Categories ALTER COLUMN categoryname NVARCHAR(200)

CREATE TABLE #DadosAlterados (
    [Status] VARCHAR(100),
    [categoryid] INT,
    [categoryname antes] NVARCHAR(200),
    [description antes] NVARCHAR(200),
    [categoryname depois] NVARCHAR(200),
    [description depois] NVARCHAR(200));

SET IMPLICIT_TRANSACTIONS ON

UPDATE C
   SET C.categoryname = CONCAT(C.categoryname, 'Alter'),
       C.description = CONCAT(C.description, 'Alterado')
OUTPUT 'Dados Alterados',
       Deleted.categoryid,
       Deleted.categoryname,
       Deleted.description,
       Inserted.categoryname,
       Inserted.description
--INTO #DadosAlterados
  FROM Production.Categories C;

  
--ROLLBACK
