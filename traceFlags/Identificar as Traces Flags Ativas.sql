DBCC TRACESTATUS;

/* ==================================================================
--Data: 12/11/2019 
--Autor :Wesley Neves
--Observa��o: 
Por padr�o, toda opera��o de backup bem-sucedida registra uma entrada no log de erros do mecanismo de banco de dados. 
Se os backups de log forem executados com muita frequ�ncia, 
essas mensagens poder�o resultar em crescimento excessivo do log de erros e dificultar a solu��o de erros devido
 ao tamanho do log de erros. Considere suprimir essas mensagens usando o sinalizador
  de rastreamento 3226. Esse sinalizador de rastreamento se aplica a todas as opera��es de backup. 
  Opera��es de backup malsucedidas ainda s�o registradas no log de erros.

Para obter mais informa��es sobre sinalizadores de rastreamento e sinalizador de rastreamento 3226, visite https://docs.microsoft.com/en-us/sql/t-sql/database-console-commands/dbcc-traceon-trace-flags-transact-sql
 
-- ==================================================================
*/

--Exemplo
-- DBCC TRACESTATUS(6530, 6531);

DBCC TRACESTATUS(3226)WITH NO_INFOMSGS;

--DBCC TRACEON (3226) 
--DBCC TRACEOFF(3226) 