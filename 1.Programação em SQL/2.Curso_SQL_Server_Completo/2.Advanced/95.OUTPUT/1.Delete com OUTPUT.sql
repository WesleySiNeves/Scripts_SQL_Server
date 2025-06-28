USE TSQLV4;

SELECT *
  FROM Production.Categories AS C;


--  SET IMPLICIT_TRANSACTIONS ON

INSERT INTO Production.Categories (categoryname,
                                   description)
OUTPUT 'Dados Inseridos',
       Inserted.*
VALUES (N'A', N'A'),
(N'B', N'B'),
(N'C', N'C');




-- ==================================================================
--Observação: Gera os dados inseridos dentro de uma tabela temporário
-- ==================================================================


CREATE TABLE #DadosInseridos (
    [Status] VARCHAR(15),
    [categoryid] INT,
    [categoryname] NVARCHAR(15),
    [description] NVARCHAR(200));

CREATE TABLE #DadosExcluidos (
    [Status] VARCHAR(15),
    [categoryid] INT,
    [categoryname] NVARCHAR(15),
    [description] NVARCHAR(200));



DELETE C
OUTPUT 'Dados Excluidos',
       Deleted.*
INTO #DadosExcluidos
  FROM Production.Categories C
 WHERE C.categoryid > 8;


 SELECT * FROM #DadosExcluidos AS DE