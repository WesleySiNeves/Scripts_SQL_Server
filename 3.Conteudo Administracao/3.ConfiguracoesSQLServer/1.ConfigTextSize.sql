/* ==================================================================
--Data: 27/07/2018 
--Autor :Wesley Neves
--Observação: @@TEXTSIZE (Transact-SQL)
 
-- ==================================================================
*/

/* ==================================================================
--Data: 27/07/2018 
--Autor :Wesley Neves
--Observação: @@TEXTSIZE
 
 Especifica o tamanho dos dados varchar(max), nvarchar(max), varbinary(max), text, ntext e
 image retornados por uma instrução SELECT.

 Os tipos de dados ntext, text e image serão removidos em uma versão futura do Microsoft SQL Server.
  Evite usar esses tipos de dados em novos trabalhos de desenvolvimento e planeje modificar os aplicativos 
 que os utilizam atualmente. Em vez disso, use nvarchar(max), varchar(max) e varbinary(max) .
-- ==================================================================
*/


DBCC USEROPTIONS;

SELECT @@TEXTSIZE;

--Comando 
--SET TEXTSIZE


/*
--SET TEXTSIZE  "number" onde 
É o tamanho dos dados varchar(max), nvarchar(max), varbinary(max), text, ntext ou image em bytes.
 number é um inteiro com um valor máximo de 2147483647 (2 GB). Um valor -1 indica um tamanho ilimitado. Um valor 0 redefine o
  tamanho para o valor padrão de 4 KB.

*/

SET TEXTSIZE  4096; --4kb
SET TEXTSIZE  1024 ; --1kb
SET TEXTSIZE  3495 ; --1kb

/*
O SQL Server Native Client (10.0 e superior) e o Driver ODBC para SQL 
Server especificam automaticamente -1 (ilimitado) durante a conexão.
*/



