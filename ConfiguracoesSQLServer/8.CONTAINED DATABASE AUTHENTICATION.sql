
/*

Use a opção contained database authentication para habilitar bancos de dados independentes na instância
 do Mecanismo de Banco de Dados do SQL Server.

Essa opção de servidor permite controlar contained database authentication.

Quando contained database authentication estiver desativada (0) para a instância, os bancos de dados
 independentes não poderão ser criados, nem conectados ao Mecanismo de Banco de Dados.

Quando contained database authentication estiver ativada (1) para a instância, os bancos de dados 
independentes poderão ser criados ou conectados ao Mecanismo de Banco de Dados.

Um banco de dados independente inclui todas as configurações de banco de dados e metadados
 necessários para definir o banco de dados e não tem nenhuma dependência de configuração da instância do 
 Mecanismo de Banco de Dados onde o banco de dados está instalado. Os usuários podem se conectar 
 ao banco de dados sem autenticar um logon no nível do Mecanismo de Banco de Dados . O isolamento
  do banco de dados do Mecanismo de Banco de Dados facilita mover o banco de dados para
   outra instância do SQL Server. A inclusão de todas as configurações no banco de dados permite 
   que os proprietários do banco de dados gerenciem todas as configurações do banco de dados. 
   Para obter mais informações sobre bancos de dados independentes, consulte Contained Databases.
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
