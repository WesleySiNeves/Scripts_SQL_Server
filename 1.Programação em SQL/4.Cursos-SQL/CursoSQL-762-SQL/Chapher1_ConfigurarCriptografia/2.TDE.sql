

/* ==================================================================
--Data: 05/09/2018 
--Autor :Wesley Neves
--Observação: Para configurar o TDE temos que seguir alguns passos
 
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
Uma vez que a chave mestra é criada junto com a senha forte (que você deve lembrar ou salvar em um local seguro), 
iremos em frente e criaremos o certificado real.

Passo 2) Criar o certificado 
O nome do certificado é "TDE_Cert" e eu dei a ele um assunto genérico.
 Alguns administradores de banco de dados gostam de colocar o nome do banco de dados real que vão criptografar lá. É totalmente com você
*/
SELECT * FROM sys.certificates AS C;

CREATE CERTIFICATE TDECertificate
WITH SUBJECT = 'implanta';
GO

/*
Agora, devemos utilizar nosso comando USE para alternar para o banco de dados que desejamos criptografar. 
Em seguida, criamos uma conexão ou associação entre o certificado que acabamos de criar e o banco de dados real.
 Em seguida, indicamos o tipo de algoritmo de criptografia que vamos usar.
 Neste caso, será a criptografia AES_256.
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
Depois que a criptografia é ativada, dependendo do tamanho do banco de dados,
 pode levar algum tempo para ser concluído. Você pode monitorar o status consultando o
 SELECT * FROM sys.dm_database_encryption_keys

*/

ALTER DATABASE TSQLV4 SET ENCRYPTION ON;

--ALTER DATABASE [crq-mg.implanta.net.br] SET ENCRYPTION OFF;



GO

/* ******************** IMPORTANTE ********************
Backup do Certificado 
É importante fazer backup do certificado criado e armazená-lo em um local seguro.
 Se o servidor ficar inativo e você precisar restaurá-lo em outro lugar, 
 será necessário importar o certificado para o servidor. Em determinados ambientes, 
 os servidores de recuperação de desastres já estão suspensos e em modo de espera hot / hot
 por isso é uma boa ideia apenas importar antecipadamente o certificado salvo para esses servidores.,


*/

USE master;

BACKUP CERTIFICATE TDE_Cert TO FILE = 'D:\Bases\TDE- Certificados'
WITH PRIVATE KEY(
                    FILE = 'D:\Bases\TDE- Certificados\TDE_CertKey.pvk',
                    ENCRYPTION BY PASSWORD = 'implanta'
                );

/*Restaurando um Certificado
Para restaurar o certificado, você terá que criar novamente uma chave mestra de serviço no servidor secundário.
*/

/*Isso na hora de restaurar o backup  se for outro servidor*/
USE master;
GO

CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'implanta';
GO

/*
no momento de restaurar o banco de dados em outro servidor
você deve se lembrar de onde fez o backup do certificado e da senha de criptografia / descriptografia
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
 Esteja atento aos caminhos usados ??neste exemplo. Você deve especificar o caminho que você armazenou o certificado
  e a chave privada. Também mantenha registros bons e seguros das senhas de criptografia.

Depois que o certificado for restaurado no servidor secundário, você poderá restaurar uma cópia do banco de dados
 criptografado.

Algumas coisas para observar antes de aplicar o TDE.
 Existem alguns inconvenientes. Lembre-se que o TDE criptografa os arquivos de banco de dados subjacentes,
incluindo os backups. Você não pode simplesmente pegar os arquivos e descarregá-los em outro SQL Server
sem as chaves e os certificados de criptografia apropriados.
NÃO permite criptografia em nível de usuário granular.
 Se esse for o tipo de criptografia que você está procurando, você deve investigar a criptografia em nível de coluna.
 
 */
SELECT * FROM sys.dm_database_encryption_keys AS DDEK;