
USE master


DROP DATABASE IF EXISTS Demo_AlwaysEncrypted

CREATE DATABASE Demo_AlwaysEncrypted 


USE Demo_AlwaysEncrypted



CREATE TABLE dbo.Customers(
    CustomerID INT ,
    Name NVARCHAR(50) NULL,
    City NVARCHAR(50) NULL,
    BirthDate DATE NOT NULL
);


-- Insert sample data
INSERT Customers VALUES (1, 'Victor', 'Sydney', '19800909');
INSERT Customers VALUES (2, 'Sofia', 'Stockholm', '19800909');
INSERT Customers VALUES (3, 'Marcus', 'Sydney', '19900808');
INSERT Customers VALUES (4, 'Christopher', 'Sydney', '19800808');
INSERT Customers VALUES (5, 'Isabelle', 'Sydney', '20000909');
GO

/* ==================================================================
--Data: 11/03/2019 
--Autor :Wesley Neves

 
-- ==================================================================
*/
-- Query unencrypted data
SELECT * FROM Customers;
GO


/* ==================================================================
--Data: 12/06/2019 
--Autor :Wesley Neves
--Observação: Aqui nessa parte clique na tabela e configura a criptografia de coluna 
 
-- ==================================================================
*/



/* ==================================================================
--Data: 11/03/2019 
--Autor :Wesley Neves
--Observação:  Demo 2
 
-- ==================================================================
*/


/* ==================================================================
--Data: 11/03/2019 
--Autor :Wesley Neves
--Observação: Passo 1) primeiro Criar CMK (Collum Master Key)
 
-- ==================================================================
*/



CREATE COLUMN MASTER KEY [CMK_COLUMN_MASTER_KEY]
WITH
(
    KEY_STORE_PROVIDER_NAME = N'MSSQL_CERTIFICATE_STORE',
    KEY_PATH = N'CurrentUser/my/21CC13CA4E733072106BF516CB7BF51939C397A6'
);

SELECT * FROM  sys.column_master_keys AS CMK

GO


SELECT CAST('senha' AS VARBINARY(200))

CREATE COLUMN ENCRYPTION KEY [CEK_COLUMN_ENCRYPTION_KEY]
WITH VALUES
(
    COLUMN_MASTER_KEY = [CMK_COLUMN_MASTER_KEY],
    ALGORITHM = 'RSA_OAEP',
    ENCRYPTED_VALUE = 0x73656E6861
)
GO

SELECT * FROM sys.column_encryption_keys AS CEK

SELECT * FROM sys.column_encryption_key_values AS CEKV


SELECT * FROM  dbo.Customers AS C




CREATE TABLE [dbo].[Customers2]
(
    [CustomerID] [INT]          NULL,
    [Name]       [NVARCHAR](200) NULL,
    [City]       [NVARCHAR](200) COLLATE Latin1_General_BIN2 ENCRYPTED WITH(COLUMN_ENCRYPTION_KEY = [CEK_COLUMN_ENCRYPTION_KEY], ENCRYPTION_TYPE = DETERMINISTIC, ALGORITHM = 'AEAD_AES_256_CBC_HMAC_SHA_256') NULL,
    [BirthDate]  [DATE]         ENCRYPTED WITH(COLUMN_ENCRYPTION_KEY = [CEK_COLUMN_ENCRYPTION_KEY], ENCRYPTION_TYPE = RANDOMIZED, ALGORITHM = 'AEAD_AES_256_CBC_HMAC_SHA_256') NOT NULL
);
GO



INSERT INTO dbo.Customers2(
                              CustomerID,
                              Name,
                              City,
                              BirthDate
                          )





SELECT C.CustomerID,
       C.Name,
       ENCRYPTBYKEY(KEY_GUID('CEK_COLUMN_ENCRYPTION_KEY'),  C.City),
       ENCRYPTBYKEY(KEY_GUID('CEK_COLUMN_ENCRYPTION_KEY'),  C.BirthDate)
  FROM dbo.Customers AS C;