USE master;

-- Create Windows login
CREATE LOGIN [SQL\Marcus] FROM WINDOWS;
GO

CREATE LOGIN [crq-mg.implanta.net.br\App] FROM WINDOWS 
WITH DEFAULT_DATABASE =[crq-mg.implanta.net.br]



/* ==================================================================
--Data: 02/10/2019 
--Autor :Wesley Neves
--Observação: Tambem podemos configurar uma politica de senha
https://docs.microsoft.com/pt-br/sql/relational-databases/security/password-policy?view=sql-server-2017
 
-- ==================================================================
*/
CREATE LOGIN [App] WITH PASSWORD ='$Senha$', CHECK_POLICY =ON,
DEFAULT_DATABASE =[crq-mg.implanta.net.br]



SELECT * FROM sys.sql_logins AS SL;

/* ==================================================================
--Data: 19/08/2019 
--Autor :Wesley Neves
--1)
 Observação: Criação de Login com autenticação do Sql 
 com o comando abaixo já e possivel logar no banco de dados 
 caso de erro acesse o menu de segurança da instancia e altere o modo de login.
-- ==================================================================
*/
SELECT * FROM sys.sql_logins AS SL;

DROP LOGIN Isabelle;

-- Create SQL login
CREATE LOGIN Isabelle
WITH PASSWORD = '123456789',
     CHECK_EXPIRATION = ON,
     CHECK_POLICY = ON;
GO

USE WideWorldImporters;

--DROP USER Isabelle
CREATE USER Isabelle FOR LOGIN Isabelle;

/* ==================================================================
--Data: 19/08/2019 
--Autor :Wesley Neves
--1)
 Observação: Criação de Login com autenticação do Sql 
 com o comando abaixo já e possivel logar no banco de dados 
 caso de erro acesse o menu de segurança da instancia e altere o modo de login.
-- ==================================================================
*/
SELECT * FROM sys.certificates AS C;

SELECT * FROM sys.sql_logins AS SL;

SELECT * FROM sys.syslogins AS S;

DROP LOGIN Christopher;

DROP CERTIFICATE ChristopherCertificate;

/* ==================================================================
--Data: 19/08/2019 
--Autor :Wesley Neves
--Observação: 2)
Criação do usuario com acesso em certificado.
 
-- ==================================================================
*/
-- Create login from a certificate
CREATE CERTIFICATE ChristopherCertificate
WITH SUBJECT = 'Christopher certificate in master database';
GO

CREATE LOGIN Christopher FROM CERTIFICATE ChristopherCertificate;
GO


/* ==================================================================
--Data: 02/10/2019 
--Autor :Wesley Neves
--Observação: Desabilitar um Login
 
-- ==================================================================
*/

ALTER LOGIN App DISABLE
ALTER LOGIN App ENABLE