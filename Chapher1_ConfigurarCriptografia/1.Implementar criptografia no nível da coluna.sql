USE master;

DROP DATABASE IF EXISTS Demo_Criptografia_Coluna;

CREATE DATABASE Demo_Criptografia_Coluna;
GO

USE Demo_Criptografia_Coluna;

DROP TABLE IF EXISTS Funcionarios;

CREATE TABLE Funcionarios
(
    IdEmpregado INT PRIMARY KEY,
    Nome        VARCHAR(300),
    Cargo       VARCHAR(100),
    Salario     VARBINARY(128)
);


/* ==================================================================
--Data: 15/08/2019 
--Autor :Wesley Neves
--Observação: Criar a SYMMETRIC KEY
 
-- ==================================================================
*/



SELECT * FROM sys.symmetric_keys AS SK



CREATE SYMMETRIC KEY SMK_Empregado WITH ALGORITHM = AES_256 ENCRYPTION BY PASSWORD = 'sqlserver';


-- Open SMK with  incorrect is fail
--Msg 15313, Level 16, State 1, Line 25
--The key is not encrypted using the specified decryptor.
OPEN SYMMETRIC KEY SMK_Empregado
DECRYPTION BY PASSWORD = 'senha';
GO

OPEN SYMMETRIC KEY SMK_Empregado
DECRYPTION BY PASSWORD = 'sqlserver';
GO

-- Verify open keys
SELECT * FROM sys.openkeys;


SELECT * FROM dbo.Funcionarios AS F

-- Insert data
INSERT Funcionarios
VALUES(1, 'João', 'CTO', ENCRYPTBYKEY(KEY_GUID('SMK_Empregado'), '$100000'));

INSERT Funcionarios
VALUES(2, 'Felipe', 'CIO', ENCRYPTBYKEY(KEY_GUID('SMK_Empregado'), '$200000'));

INSERT Funcionarios
VALUES(3, 'Jóse', 'CEO', ENCRYPTBYKEY(KEY_GUID('SMK_Empregado'), '$300000'));
GO

SELECT F.IdEmpregado,
       F.Nome,
       F.Cargo,
       F.Salario
  FROM dbo.Funcionarios AS F;

SELECT *,
       CONVERT(VARCHAR, DECRYPTBYKEY(Funcionarios.Salario)) AS Salario
  FROM Funcionarios;
GO

-- Close SMK
CLOSE SYMMETRIC KEY SMK_Empregado;
GO

SELECT *,
       CONVERT(VARCHAR, DECRYPTBYKEY(Funcionarios.Salario)) AS Salario
  FROM Funcionarios;


UPDATE Funcionarios
   SET Funcionarios.Salario = (
                                  SELECT Salario FROM Funcionarios WHERE Funcionarios.Cargo = 'CEO'
                              )
 WHERE
    Funcionarios.Nome = 'Felipe';
GO

-- Open SMK and query table with decrypted values
OPEN SYMMETRIC KEY SMK_Empregado
DECRYPTION BY PASSWORD = 'sqlserver';

SELECT *,
       CONVERT(VARCHAR, DECRYPTBYKEY(Funcionarios.Salario)) AS Salario
  FROM Funcionarios;
GO

/* ==================================================================
--Data: 11/03/2019 
--Autor :Wesley Neves
--Observação: Segundo exemplo com certificado

Uma grande desvantagem de criptografar dados usando uma chave simétrica protegida por uma senha é que a senha precisa
 ser incorporada em algum lugar, o que representa um risco de segurança. Consequentemente, 
 o uso de certificados é geralmente a técnica preferida.
 
-- ==================================================================
*/

USE WideWorldImporters; 
GO 

DROP  SYMMETRIC KEY Key_BAN
DROP CERTIFICATE Certificate_DataBase
DROP MASTER KEY   



/* ==================================================================
--Data: 07/06/2019 
--Autor :Wesley Neves
--Observação: Passo 1) Criar a MASTER KEY
 
-- ==================================================================
*/
CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'sqlserver'



/* ==================================================================
--Data: 07/06/2019 
--Autor :Wesley Neves
--Observação: Passo 2) Criar o Certificado
 
-- ==================================================================
*/

-- Create certificate
CREATE CERTIFICATE Certificate_DataBase
   WITH SUBJECT = 'Certificado para criptografar e descriptografia de dados';
GO


SELECT * FROM  sys.certificates AS C


/* ==================================================================
--Data: 14/05/2019 
--Autor :Wesley Neves
--Observação: -- Create SYMMETRIC KEY encriptada pelo CERTIFICATE
 
-- ==================================================================
*/

CREATE SYMMETRIC KEY Key_DataBase
    WITH ALGORITHM = AES_256
    ENCRYPTION BY CERTIFICATE Certificate_DataBase;  -- Importante criando a chave simetrica e encriptando com o certificado
GO


SELECT S.SupplierID,
       S.SupplierName,
       S.SupplierCategoryID,
       S.SupplierReference,
       S.BankAccountName,
       S.BankAccountBranch,
       S.BankAccountCode,
       S.BankAccountNumber,
       S.BankInternationalCode
        FROM Purchasing.Suppliers AS S



IF(EXISTS (
              SELECT *
                FROM sys.tables AS T
                     JOIN sys.columns AS C ON T.object_id = C.object_id
               WHERE
                  T.object_id = OBJECT_ID('Purchasing.Suppliers')
                  AND C.name = 'EncryptedBankAccountNumber'
          )
  )
    BEGIN
			
			--DROP INDEX IxNaoResolveNada ON Purchasing.Suppliers
        ALTER TABLE Purchasing.Suppliers DROP COLUMN EncryptedBankAccountNumber;
    END;




-- Create a column to store encrypted data
ALTER TABLE Purchasing.Suppliers
    ADD EncryptedBankAccountNumber varbinary(128);
GO



SELECT S.SupplierID,S.BankAccountNumber, S.EncryptedBankAccountNumber FROM Purchasing.Suppliers AS S

-- Open the SMK to encrypt data
OPEN SYMMETRIC KEY Key_DataBase
DECRYPTION BY CERTIFICATE Certificate_DataBase;
GO

SELECT S.SupplierID,
       S.SupplierName,
       S.BankAccountNumber,
       S.EncryptedBankAccountNumber,
	  CAST( DECRYPTBYKEY(S.EncryptedBankAccountNumber) AS NVARCHAR(20)) AS Valor
FROM Purchasing.Suppliers AS S;

-- Encrypt Bank Account Number
UPDATE Purchasing.Suppliers
SET EncryptedBankAccountNumber = EncryptByKey(Key_GUID('Key_DataBase'), BankAccountNumber);
GO



SELECT S.SupplierID,
       S.SupplierName,
       S.BankAccountNumber,
       S.EncryptedBankAccountNumber,
	  CAST( DECRYPTBYKEY(S.EncryptedBankAccountNumber) AS NVARCHAR(20)) AS Valor
FROM Purchasing.Suppliers AS S;

CLOSE SYMMETRIC KEY Key_DataBase



/* ==================================================================
--Data: 11/03/2019 
--Autor :Wesley Neves
--Observação:  Fazendo Select com a chave simetrica fechada
 
-- ==================================================================
*/
SELECT S.SupplierID,
       S.SupplierName,
       S.BankAccountNumber,
       S.EncryptedBankAccountNumber,
	  CAST( DECRYPTBYKEY(S.EncryptedBankAccountNumber) AS NVARCHAR(20)) AS Valor
FROM Purchasing.Suppliers AS S;






/* ==================================================================
--Data: 11/03/2019 
--Autor :Wesley Neves
--Observação: Fazendo Filtros com Where (Ative o plano de execução)
 
-- ==================================================================
*/



-- Query 2: Open the SMK
OPEN SYMMETRIC KEY Key_DataBase
   DECRYPTION BY CERTIFICATE Certificate_DataBase;
GO

SELECT TOP 5 SupplierID, SupplierName, BankAccountNumber, EncryptedBankAccountNumber,
    CONVERT(NVARCHAR(50), DecryptByKey(EncryptedBankAccountNumber)) AS
DecryptedBankAccountNumber
FROM Purchasing.Suppliers
WHERE DecryptByKey(EncryptedBankAccountNumber) ='8575824136'



/* ==================================================================
--Data: 19/03/2019 
--Autor :Wesley Neves
--Observação: 

Por fim, esteja ciente do impacto no desempenho da criptografia de colunas nos bancos de dados. Para todos os efeitos, 
os índices em colunas criptografadas são inúteis e consomem recursos desnecessários na maioria dos casos. 
 
-- ==================================================================
*/

CREATE NONCLUSTERED INDEX IxNaoResolveNada  ON Purchasing.Suppliers(EncryptedBankAccountNumber)

/*Analise o Plano de execução , veja que ainda é um index Scan*/

SELECT TOP 1 SupplierID, EncryptedBankAccountNumber,
    CONVERT(NVARCHAR(50), DecryptByKey(EncryptedBankAccountNumber)) AS
DecryptedBankAccountNumber
FROM Purchasing.Suppliers
WHERE DecryptByKey(EncryptedBankAccountNumber) ='8575824136'