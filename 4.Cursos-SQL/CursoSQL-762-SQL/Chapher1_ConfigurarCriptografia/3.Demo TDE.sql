USE master

/* ==================================================================
--Data: 24/09/2018 
--Autor :Wesley Neves
--Observação: Demo sobre TDE
 
-- ==================================================================
*/

/*
DROP CERTIFICATE DemoTDE
DROP MASTER KEY
DROP DATABASE IF EXISTS TDEDemo;
*/



CREATE DATABASE TDEDemo;



/*
 1) Crie uma master key
*/

CREATE MASTER KEY ENCRYPTION BY PASSWORD ='PASSWORD'


/*
2) Crie ou obtenha um certificado
*/
CREATE CERTIFICATE  DemoTDE WITH SUBJECT ='DemoTDE'



SELECT * FROM  sys.certificates AS C
WHERE C.name ='DemoTDE'



/*
3) Crie uma database encryption key e proteja-a pelo certificado
*/

USE TDEDemo
CREATE DATABASE ENCRYPTION KEY WITH ALGORITHM =AES_256 ENCRYPTION BY SERVER CERTIFICATE DemoTDE



/*4) Habilite o TDE para o banco de dados*/
ALTER DATABASE TDEDemo SET ENCRYPTION ON


/*
Para desabilitar use o comando abaixo
*/

-- Use the following command to disable TDE
--ALTER DATABASE WorldWideImporters SET ENCRYPTION OFF;



/*
Agora faça BACKUP 
*/

--- Backup SMK
BACKUP SERVICE MASTER KEY
TO FILE = 'D:\SERVICE MASTER KEY\ServerMasterKey.key' ENCRYPTION BY PASSWORD = 'PASSWORD';
GO


-- Backup DMK
BACKUP MASTER KEY
TO FILE = 'D:\SERVICE MASTER KEY\DatabaseMasterKey.key' ENCRYPTION BY PASSWORD= 'PASSWORD';

GO


BACKUP CERTIFICATE DemoTDE
TO FILE = 'D:\SERVICE MASTER KEY\TDECertificate.cer'
WITH PRIVATE KEY(
    FILE = 'D:\SERVICE MASTER KEY\TDECertificate.key',
    ENCRYPTION BY PASSWORD = 'PASSWORD'
);


SELECT * FROM sys.dm_database_encryption_keys AS DDEK