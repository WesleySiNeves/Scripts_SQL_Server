
/*

Use a op��o contained database authentication para habilitar bancos de dados independentes na inst�ncia
 do Mecanismo de Banco de Dados do SQL Server.

Essa op��o de servidor permite controlar contained database authentication.

Quando contained database authentication estiver desativada (0) para a inst�ncia, os bancos de dados
 independentes n�o poder�o ser criados, nem conectados ao Mecanismo de Banco de Dados.

Quando contained database authentication estiver ativada (1) para a inst�ncia, os bancos de dados 
independentes poder�o ser criados ou conectados ao Mecanismo de Banco de Dados.

Um banco de dados independente inclui todas as configura��es de banco de dados e metadados
 necess�rios para definir o banco de dados e n�o tem nenhuma depend�ncia de configura��o da inst�ncia do 
 Mecanismo de Banco de Dados onde o banco de dados est� instalado. Os usu�rios podem se conectar 
 ao banco de dados sem autenticar um logon no n�vel do Mecanismo de Banco de Dados . O isolamento
  do banco de dados do Mecanismo de Banco de Dados facilita mover o banco de dados para
   outra inst�ncia do SQL Server. A inclus�o de todas as configura��es no banco de dados permite 
   que os propriet�rios do banco de dados gerenciem todas as configura��es do banco de dados. 
   Para obter mais informa��es sobre bancos de dados independentes, consulte Contained Databases.
*/

USE master;
GO
sys.sp_configure 'show advanced options', 1;
GO
RECONFIGURE;
GO
sys.sp_configure 'CONTAINED DATABASE AUTHENTICATION', 1;
GO
RECONFIGURE;
GO
