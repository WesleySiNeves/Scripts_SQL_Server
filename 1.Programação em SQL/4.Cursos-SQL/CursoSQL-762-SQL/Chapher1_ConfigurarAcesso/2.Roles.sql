/* ==================================================================
--Data: 23/08/2019 
--Autor :Wesley Neves
--Observação: Fixed server roles

 db_accessadmin
Os membros podem adicionar ou remover o acesso ao banco de dados para logins do Windows, grupos do Windows e logons do SQL Server.

db_backupoperator

Os membros podem fazer backup do banco de dados.

db_datareader

Os membros podem ler todos os dados de todas as tabelas de usuários.

db_datawriter

Os membros podem adicionar, excluir ou alterar dados em todas as tabelas de usuários.

db_ddladmin

Os membros podem executar qualquer comando DDL (Data Definition Language) em um banco de dados.

db_denydatareader

Os membros não podem ler nenhum dado nas tabelas do usuário em um banco de dados.

db_denydatawriter

Os membros não podem adicionar, modificar ou excluir nenhum dado nas tabelas de usuários em um banco de dados.

db_owner

Os membros podem executar todas as atividades de configuração e manutenção no banco de dados e também podem descartar o banco de dados.

db_securityadmin

Os membros podem modificar a associação de função e gerenciar permissões. Adicionar entidades a essa função pode permitir o escalonamento de privilégio não intencional.

público

Cada usuário dentro do banco de dados pertence a essa função de banco de dados fixa. Conseqüentemente, ele mantém as permissões padrão para todos os usuários no banco de dados.
-- ==================================================================
*/



USE WideWorldImporters

/* ==================================================================
--Data: 23/08/2019 
--Autor :Wesley Neves
--Observação: Os membros podem adicionar ou remover o acesso ao banco de dados para logins do Windows, grupos do Windows e logons do SQL Server.
 
-- ==================================================================
*/
ALTER ROLE db_accessadmin ADD MEMBER Isabelle
ALTER ROLE db_accessadmin DROP MEMBER Isabelle


/* ==================================================================
--Data: 23/08/2019 
--Autor :Wesley Neves
--Observação: db_backupoperator
 
-- ==================================================================
*/

ALTER ROLE db_datareader


