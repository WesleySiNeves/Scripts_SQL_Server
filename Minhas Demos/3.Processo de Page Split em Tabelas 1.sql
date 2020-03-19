


-- ==================================================================
--Observação: 
--1) faça a demo com a tabela no modo HEAP ,
--2) apos volte e altere colocando um PK
-- ==================================================================
--
/*

TRUNCATE TABLE TestStructure
CREATE TABLE dbo.TestStructure (
    id INT NOT NULL IDENTITY(1,1) PRIMARY KEY,
    filler1 CHAR(36) NOT NULL,
    filler2 CHAR(216) NOT NULL);
*/

CREATE TABLE dbo.TestStructure (
    id INT NOT NULL,
    filler1 CHAR(36) NOT NULL,
    filler2 CHAR(216) NOT NULL);



/* Mostra o tipo de tabela no caso e uma (HEAP)*/
SELECT OBJECT_NAME(indexes.object_id) AS table_name,
       indexes.name AS index_name,
       indexes.type,
       indexes.type_desc
  FROM sys.indexes
 WHERE indexes.object_id = OBJECT_ID(N'dbo.TestStructure', N'U');


 -- ==================================================================
 --Observação: Mostra a porcentagem de fragmentação do indice
 -- ==================================================================

SELECT Phisical.index_type_desc,
       Phisical.page_count,
       Phisical.record_count,
       Phisical.avg_page_space_used_in_percent
  FROM sys.dm_db_index_physical_stats(DB_ID(N'TSQL2017'), OBJECT_ID(N'dbo.TestStructure'),
   NULL, NULL, 
   'DETAILED') AS Phisical;


   /*
   Vamos fazer alguns inserts e verificar o quando? A pagina e preenchida com dados

   Apos a 31 linha inserida se rodarmos o select novamente vamos
    ver o banco de dados fez split nas paginas.
   */
INSERT INTO dbo.TestStructure (
                               filler1,
                               filler2)
VALUES ( 'a', 'b');
GO 30


-- ==================================================================
--Observação: Vamos rodar novamente para ver as alocações de paginas
/*Rodamos fazendo um Loop de 30 registros , caso iserimos mais um registro
como o percentual de dados chegou a (98,1961947121324)  vai iniciar o processo de page split
Assim ficando com duas paginas e o sql server move a metade para a proxima pagina
*/
-- ==================================================================

SELECT Phisical.index_type_desc,
       Phisical.page_count,
       Phisical.record_count,
       Phisical.avg_page_space_used_in_percent [Total Usado de dados na pagina]
  FROM sys.dm_db_index_physical_stats(DB_ID(N'TSQL2017'), OBJECT_ID(N'dbo.TestStructure'),
   NULL, NULL, 
   'DETAILED') AS Phisical;


   
INSERT INTO dbo.TestStructure (
                               filler1,
                               filler2)
VALUES ('a', 'b');
GO 1


--ALTER INDEX PK__TestStru__3213E83F534B7A2B ON dbo.TestStructure REBUILD