DBCC TRACESTATUS;

/* ==================================================================
--Data: 12/11/2019 
--Autor :Wesley Neves
--Observação: 
Por padrão, toda operação de backup bem-sucedida registra uma entrada no log de erros do mecanismo de banco de dados. 
Se os backups de log forem executados com muita frequência, 
essas mensagens poderão resultar em crescimento excessivo do log de erros e dificultar a solução de erros devido
 ao tamanho do log de erros. Considere suprimir essas mensagens usando o sinalizador
  de rastreamento 3226. Esse sinalizador de rastreamento se aplica a todas as operações de backup. 
  Operações de backup malsucedidas ainda são registradas no log de erros.

Para obter mais informações sobre sinalizadores de rastreamento e sinalizador de rastreamento 3226, visite https://docs.microsoft.com/en-us/sql/t-sql/database-console-commands/dbcc-traceon-trace-flags-transact-sql
 
-- ==================================================================
*/

--Exemplo
-- DBCC TRACESTATUS(6530, 6531);

DBCC TRACESTATUS(3226)WITH NO_INFOMSGS;

--DBCC TRACEON (3226) 
--DBCC TRACEOFF(3226) 