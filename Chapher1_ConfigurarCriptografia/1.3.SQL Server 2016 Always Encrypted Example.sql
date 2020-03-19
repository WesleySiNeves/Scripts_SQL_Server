
/* ==================================================================
--Data: 03/09/2018 
--Autor :Wesley Neves
--Observação: Demo  SQL Server 2016 Always Encrypted
 https://www.mssqltips.com/sqlservertip/4011/sql-server-2016-always-encrypted/
-- ==================================================================
*/

/*Criar o Banco de Dados de Exemplo*/


DROP DATABASE IF EXISTS  AEDemo;


CREATE DATABASE AEDemo;

/*criar uma Collums Master Key   demostrado no tutorial   */


/*3) Criar as tabelas*/

USE AEDemo;
CREATE TABLE dbo.EncryptedTable
(
    ID       INT          IDENTITY(1, 1) PRIMARY KEY,
    LastName NVARCHAR(32) COLLATE Latin1_General_BIN2 
	ENCRYPTED WITH(ENCRYPTION_TYPE = DETERMINISTIC, ALGORITHM = 'AEAD_AES_256_CBC_HMAC_SHA_256', COLUMN_ENCRYPTION_KEY = columkey) NOT NULL,
    Salary   INT         
	ENCRYPTED WITH(ENCRYPTION_TYPE = RANDOMIZED, ALGORITHM = 'AEAD_AES_256_CBC_HMAC_SHA_256', COLUMN_ENCRYPTION_KEY = columkey) NOT NULL
);
GO

/*Adicionando uma procedure de insert*/

CREATE PROCEDURE dbo.AddPerson
    @LastName NVARCHAR(32),
    @Salary   INT
AS
BEGIN
    INSERT dbo.EncryptedTable (
                              LastName,
                              Salary
                              )
    SELECT @LastName,
           @Salary;
END;
GO

/*Adicionando uma procedure que retorna pessoa*/
CREATE PROCEDURE dbo.GetPeopleByLastName
  @LastName NVARCHAR(32) 
AS
BEGIN
  SELECT ID, LastName, Salary
  FROM dbo.EncryptedTable
  WHERE LastName = @LastName COLLATE Latin1_General_BIN2;
END
GO

/*Agora vamos testar o Insert.*/

INSERT dbo.EncryptedTable(LastName,Salary) SELECT N'Bertrand',720000;
/*
Msg 206, Level 16, State 2, Line 65
Operand type clash: nvarchar is incompatible with nvarchar(4000) encrypted with
 (encryption_type = 'DETERMINISTIC', encryption_algorithm_name = 'AEAD_AES_256_CBC_HMAC_SHA_256', 
 column_encryption_key_name = 'columkey', column_encryption_key_database_name = 'AEDemo')

*/


/*Segundo teste de insert*/
USE AEDemo

DECLARE @LastName NVARCHAR(32) = N'Bertrand', @Salary INT = 720000;
INSERT dbo.EncryptedTable(LastName,Salary) SELECT @LastName, @Salary;
/*
Msg 33299, Level 16, State 6, Line 78
Encryption scheme mismatch for columns/variables '@LastName'. The encryption scheme for
 the columns/variables is (encryption_type = 'PLAINTEXT') and the expression near line '3' 
 expects it to be (encryption_type = 'DETERMINISTIC', encryption_algorithm_name = 'AEAD_AES_256_CBC_HMAC_SHA_256',
  column_encryption_key_name = 'columkey', column_encryption_key_database_name = 'AEDemo') (or weaker). 

*/

/*Terceira Tentativa de insert*/

DECLARE @LastName NVARCHAR(32) = N'Bertrand', @Salary INT = 720000;
EXEC dbo.AddPerson @LastName, @Salary;

/*
Msg 33299, Level 16, State 6, Line 90
Encryption scheme mismatch for columns/variables '@LastName'. The encryption 
scheme for the columns/variables is (encryption_type = 'PLAINTEXT') 
and the expression near line '0' expects it to be
 (encryption_type = 'DETERMINISTIC', encryption_algorithm_name = 'AEAD_AES_256_CBC_HMAC_SHA_256', 
 column_encryption_key_name = 'columkey', column_encryption_key_database_name = 'AEDemo') (or weaker). 

*/

/*Entao vamos criar um aplicativo simples windows forms para fazer alguns testes*/

SELECT * FROM dbo.EncryptedTable AS ET
