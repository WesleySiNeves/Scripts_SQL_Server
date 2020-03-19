

/* ==================================================================
--Data: 05/09/2018 
--Autor :Wesley Neves
--Observa��o: Para configurar o TDE temos que seguir alguns passos
 
 1) Crie uma chave mestra
 2) Criar ou obter um certificado protegido pela chave mestra
 3) Crie uma chave de criptografia do banco de dados e proteja-a pelo certificado
 4) Definir o banco de dados para usar criptografia
-- ==================================================================
*/

/*Criar a master key no banco master*/
USE master;

SELECT *
  FROM sys.symmetric_keys
 WHERE
    symmetric_keys.name LIKE '%DatabaseMasterKey%';



IF(NOT EXISTS (
                  SELECT *
                    FROM sys.symmetric_keys
                   WHERE
                      symmetric_keys.name LIKE '%DatabaseMasterKey%'
              )
  )
    BEGIN
        CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'implanta';
    END;

/*
Uma vez que a chave mestra � criada junto com a senha forte (que voc� deve lembrar ou salvar em um local seguro), 
iremos em frente e criaremos o certificado real.

Passo 2) Criar o certificado 
O nome do certificado � "TDE_Cert" e eu dei a ele um assunto gen�rico.
 Alguns administradores de banco de dados gostam de colocar o nome do banco de dados real que v�o criptografar l�. � totalmente com voc�
*/
SELECT * FROM sys.certificates AS C;

CREATE CERTIFICATE TDECertificate
WITH SUBJECT = 'implanta';
GO

/*
Agora, devemos utilizar nosso comando USE para alternar para o banco de dados que desejamos criptografar. 
Em seguida, criamos uma conex�o ou associa��o entre o certificado que acabamos de criar e o banco de dados real.
 Em seguida, indicamos o tipo de algoritmo de criptografia que vamos usar.
 Neste caso, ser� a criptografia AES_256.
Passo 3*/

--CREATE DATABASE TSQL2012

USE TSQLV4;
GO

CREATE DATABASE ENCRYPTION KEY WITH ALGORITHM = AES_256
ENCRYPTION BY SERVER CERTIFICATE TDECertificate;
GO

/*
Aqui ele mostra uma mensagem de waring
Warning: The certificate used for encrypting the database encryption key has not been backed up.
 You should immediately back up the certificate and the private key associated with the certificate.
 If the certificate ever becomes unavailable or if you must restore or attach the database on another server,
  you must have backups of both the certificate and the private key or you will not be able to open the database.

*/

/*Passo 4) Ativar criptografia 
Depois que a criptografia � ativada, dependendo do tamanho do banco de dados,
 pode levar algum tempo para ser conclu�do. Voc� pode monitorar o status consultando o
 SELECT * FROM sys.dm_database_encryption_keys

*/

ALTER DATABASE TSQLV4 SET ENCRYPTION ON;

--ALTER DATABASE [crq-mg.implanta.net.br] SET ENCRYPTION OFF;



GO

/* ******************** IMPORTANTE ********************
Backup do Certificado 
� importante fazer backup do certificado criado e armazen�-lo em um local seguro.
 Se o servidor ficar inativo e voc� precisar restaur�-lo em outro lugar, 
 ser� necess�rio importar o certificado para o servidor. Em determinados ambientes, 
 os servidores de recupera��o de desastres j� est�o suspensos e em modo de espera hot / hot
 por isso � uma boa ideia apenas importar antecipadamente o certificado salvo para esses servidores.,


*/

USE master;

BACKUP CERTIFICATE TDE_Cert TO FILE = 'D:\Bases\TDE- Certificados'
WITH PRIVATE KEY(
                    FILE = 'D:\Bases\TDE- Certificados\TDE_CertKey.pvk',
                    ENCRYPTION BY PASSWORD = 'implanta'
                );

/*Restaurando um Certificado
Para restaurar o certificado, voc� ter� que criar novamente uma chave mestra de servi�o no servidor secund�rio.
*/

/*Isso na hora de restaurar o backup  se for outro servidor*/
USE master;
GO

CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'implanta';
GO

/*
no momento de restaurar o banco de dados em outro servidor
voc� deve se lembrar de onde fez o backup do certificado e da senha de criptografia / descriptografia
*/

USE master;
GO

CREATE CERTIFICATE TDECert
FROM FILE = 'D:\Bases\TDE- Certificados'
WITH PRIVATE KEY(
                    FILE = 'D:\Bases\TDE- Certificados\TDE_CertKey.pvk',
                    DECRYPTION BY PASSWORD = 'implanta'
                );

/*
 Esteja atento aos caminhos usados ??neste exemplo. Voc� deve especificar o caminho que voc� armazenou o certificado
  e a chave privada. Tamb�m mantenha registros bons e seguros das senhas de criptografia.

Depois que o certificado for restaurado no servidor secund�rio, voc� poder� restaurar uma c�pia do banco de dados
 criptografado.

Algumas coisas para observar antes de aplicar o TDE.
 Existem alguns inconvenientes. Lembre-se que o TDE criptografa os arquivos de banco de dados subjacentes,
incluindo os backups. Voc� n�o pode simplesmente pegar os arquivos e descarreg�-los em outro SQL Server
sem as chaves e os certificados de criptografia apropriados.
N�O permite criptografia em n�vel de usu�rio granular.
 Se esse for o tipo de criptografia que voc� est� procurando, voc� deve investigar a criptografia em n�vel de coluna.
 
 */
SELECT * FROM sys.dm_database_encryption_keys AS DDEK;