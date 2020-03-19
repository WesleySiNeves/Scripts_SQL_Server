/* ==================================================================
--Data: 23/08/2019 
--Autor :Wesley Neves
--Observa��o: Fixed server roles

 db_accessadmin
Os membros podem adicionar ou remover o acesso ao banco de dados para logins do Windows, grupos do Windows e logons do SQL Server.

db_backupoperator

Os membros podem fazer backup do banco de dados.

db_datareader

Os membros podem ler todos os dados de todas as tabelas de usu�rios.

db_datawriter

Os membros podem adicionar, excluir ou alterar dados em todas as tabelas de usu�rios.

db_ddladmin

Os membros podem executar qualquer comando DDL (Data Definition Language) em um banco de dados.

db_denydatareader

Os membros n�o podem ler nenhum dado nas tabelas do usu�rio em um banco de dados.

db_denydatawriter

Os membros n�o podem adicionar, modificar ou excluir nenhum dado nas tabelas de usu�rios em um banco de dados.

db_owner

Os membros podem executar todas as atividades de configura��o e manuten��o no banco de dados e tamb�m podem descartar o banco de dados.

db_securityadmin

Os membros podem modificar a associa��o de fun��o e gerenciar permiss�es. Adicionar entidades a essa fun��o pode permitir o escalonamento de privil�gio n�o intencional.

p�blico

Cada usu�rio dentro do banco de dados pertence a essa fun��o de banco de dados fixa. Conseq�entemente, ele mant�m as permiss�es padr�o para todos os usu�rios no banco de dados.
-- ==================================================================
*/



USE WideWorldImporters

/* ==================================================================
--Data: 23/08/2019 
--Autor :Wesley Neves
--Observa��o: Os membros podem adicionar ou remover o acesso ao banco de dados para logins do Windows, grupos do Windows e logons do SQL Server.
 
-- ==================================================================
*/
ALTER ROLE db_accessadmin ADD MEMBER Isabelle
ALTER ROLE db_accessadmin DROP MEMBER Isabelle


/* ==================================================================
--Data: 23/08/2019 
--Autor :Wesley Neves
--Observa��o: db_backupoperator
 
-- ==================================================================
*/

ALTER ROLE db_datareader


