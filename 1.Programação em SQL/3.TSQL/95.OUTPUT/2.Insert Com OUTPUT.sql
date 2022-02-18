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



INSERT INTO Production.Categories (categoryname,
                                   description)
OUTPUT 'Dados Inseridos',
       Inserted.*
INTO #DadosInseridos
VALUES (N'A', N'A'),
(N'B', N'B'),
(N'C', N'C');


SELECT *
  FROM #DadosInseridos AS DI;


