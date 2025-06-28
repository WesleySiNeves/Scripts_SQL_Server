--CREATE DATABASE  Curso

--GO

--USE Curso 

--GO

CREATE TABLE Pessoas (
 NomePessoa VARCHAR(200)
)
GO
CREATE  SCHEMA  Cadastro
GO
SELECT * FROM dbo.Pessoas AS P
ALTER SCHEMA Cadastro TRANSFER dbo.Pessoas