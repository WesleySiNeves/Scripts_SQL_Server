/*
Uma tarefa importante para quase qualquer programador de banco de dados � poder prever o resultado
dado algum c�digo de Idioma de Defini��o de Dados (DDL) Transact-SQL que configura um cen�rio,
seguido por alguns DML (Data Manipulation Language) que voc� precisa para determinar o
resultado de. Toda vez que criamos algum conceito novo, a pr�xima coisa a fazer � mostrar isso
trabalhando (uma das grandes coisas sobre trabalhar com um idioma interativo declarativo como
Transact-SQL).
*/

USE    ExamBook762Ch3

CREATE TABLE Examples.ScenarioTestType
(
ScenarioTestType varchar(10) NOT NULL CONSTRAINT
PKScenarioTestType PRIMARY KEY
);

CREATE TABLE Examples.ScenarioTest
(
ScenarioTestId int NOT NULL PRIMARY KEY,
ScenarioTestType varchar(10) NULL CONSTRAINT
CHKScenarioTest_ScenarioTestType CHECK( ScenarioTestType IN ('Type1','Type2'))
);


ALTER TABLE Examples.ScenarioTest
ADD CONSTRAINT FKScenarioTest_Ref_ExamplesScenarioTestType
FOREIGN KEY (ScenarioTestType) REFERENCES
Examples.ScenarioTestType;


SELECT * FROM Examples.ScenarioTest AS ST

INSERT INTO Examples.ScenarioTest(ScenarioTestId,
ScenarioTestType)
VALUES (1,'Type1');

INSERT INTO Examples.ScenarioTestType(ScenarioTestType)
VALUES ('Type1');

INSERT INTO Examples.ScenarioTest(ScenarioTestId,
ScenarioTestType)
VALUES (1,'Type1');

INSERT INTO Examples.ScenarioTest(ScenarioTestId,
ScenarioTestType)
VALUES (1,'Type2');

INSERT INTO Examples.ScenarioTest(ScenarioTestId,
ScenarioTestType)
VALUES (2,'Type1');

INSERT INTO Examples.ScenarioTest(ScenarioTestId,ScenarioTestType)
VALUES (3,'Type1');


/*########################
# OBS:Identify proper usage of PRIMARY KEY constraints

Escolher uma chave prim�ria durante a fase de projeto de um projeto � geralmente bonito
direto. Muitos designers usam a chave candidata mais simples escolhida durante o projeto. Para
Por exemplo, considere que voc� tem uma tabela que define as empresas com as quais voc� faz neg�cios:
*/

CREATE TABLE Examples.Company
(
    CompanyName NVARCHAR(50) NOT NULL
        CONSTRAINT PKCompany PRIMARY KEY,
    CompanyURL NVARCHAR(MAX) NOT NULL
);


INSERT INTO Examples.Company(CompanyName, CompanyURL)
VALUES ('Blue Yonder
Airlines','http://www.blueyonderairlines.com/'),
('Tailspin Toys','http://www.tailspintoys.com/');


SELECT *
FROM Examples.Company;


DROP TABLE IF EXISTS Examples.Company;
CREATE TABLE Examples.Company
(
    CompanyId INT NOT NULL IDENTITY(1, 1)
        CONSTRAINT PKCompany PRIMARY KEY,
    CompanyName NVARCHAR(50) NOT NULL CONSTRAINT AKCompany UNIQUE,
    CompanyURL NVARCHAR(MAX) NOT NULL

);



INSERT INTO Examples.Company
(
    CompanyName,
    CompanyURL
)
VALUES
('Blue Yonder
Airlines', 'http://www.blueyonderairlines.com/'),
('Tailspin Toys', 'http://www.tailspintoys.com/');



INSERT INTO Examples.Company(CompanyName, CompanyURL)
VALUES ('Blue Yonder
Airlines','http://www.blueyonderairlines.com/');

/*
Msg 2627, Level 14, State 1, Line 107
Viola��o da restri��o UNIQUE KEY 'AKCompany'. N�o � poss�vel inserir a chave duplicada no objeto 'Examples.Company'. O valor de chave duplicada � (Blue Yonder
Airlines).
A instru��o foi finalizada.

*/

SELECT * FROM Examples.Company AS C

INSERT INTO Examples.Company(CompanyName, CompanyURL)
VALUES ('Northwind
Traders','http://www.northwindtraders.com/');


SELECT * FROM Examples.Company AS C


/*
Olhando para as linhas na tabela, voc� v� que existe um valor faltando no esperado
sequ�ncia de valores. O valor IDENTITY � gerado antes do valor falhar e para
prop�sitos de concorr�ncia, o valor n�o � retornado para ser reutilizado.
Se voc� precisar obter o valor do valor IDENTITY ap�s a inser��o, voc� pode usar
SCOPE_IDENTITY () para obter o valor no escopo atual, ou @@ IDENTITY para obter o
�ltimo valor para a conex�o
*/



/*Traballhando  com Sequence*/


DROP TABLE IF EXISTS Examples.Company;
DROP SEQUENCE IF EXISTS Examples.Company_SEQUENCE;
CREATE SEQUENCE Examples.Company_SEQUENCE AS INT START WITH 1;

CREATE TABLE Examples.Company
(
    CompanyId INT NOT NULL
        CONSTRAINT PKCompany PRIMARY KEY
        CONSTRAINT DFLTCompany_CompanyId
            DEFAULT (NEXT VALUE FOR Examples.Company_SEQUENCE),
    CompanyName NVARCHAR(50) NOT NULL
        CONSTRAINT AKCompany
        UNIQUE,
    CompanyURL NVARCHAR(MAX) NOT NULL
);

INSERT INTO Examples.Company
(
    CompanyName,
    CompanyURL
)
VALUES
('Blue Yonder
Airlines', 'http://www.blueyonderairlines.com/'),
('Tailspin Toys', 'http://www.tailspintoys.com/');


SELECT * FROM Examples.Company AS C

DECLARE @CompanyId INT = NEXT VALUE FOR Examples.Company_SEQUENCE;

SELECT @CompanyId;
INSERT INTO Examples.Company
(
    CompanyId,
    CompanyName,
    CompanyURL
)
VALUES
(@CompanyId, 'Northwind
Traders', 'http://www.northwindtraders.com/');



DROP TABLE IF EXISTS Examples.Company;
CREATE TABLE Examples.Company
(
CompanyId uniqueidentifier NOT NULL CONSTRAINT
PKCompany PRIMARY KEY
CONSTRAINT DFLTCompany_CompanyId
DEFAULT (NEWID()),
CompanyName nvarchar(50) NOT NULL CONSTRAINT AKCompany
UNIQUE,
CompanyURL nvarchar(max) NOT NULL
);



CREATE TABLE Examples.DriversLicense
(
Locality char(10) NOT NULL,
LicenseNumber varchar(40) NOT NULL,
CONSTRAINT PKDriversLicense PRIMARY KEY (Locality,
LicenseNumber)
);


CREATE TABLE Examples.EmployeeDriverLicense
(
    EmployeeNumber CHAR(10) NOT NULL,   --Ref to Employee table
    Locality CHAR(10) NOT NULL,         --Ref to DriversLicense table
    LicenseNumber VARCHAR(40) NOT NULL, --Ref to DriversLicense table
    CONSTRAINT PKEmployeeDriversLicense
        PRIMARY KEY
        (
            EmployeeNumber,
            Locality,
            LicenseNumber
        )
);


CREATE TABLE Examples.DriversLicense
(
DriversLicenseId int CONSTRAINT PKDriversLicense
PRIMARY KEY,
Locality char(10) NOT NULL,
LicenseNumber varchar(40) NOT NULL,
CONSTRAINT AKDriversLicense UNIQUE (Locality,
LicenseNumber)
);

CREATE TABLE Examples.EmployeeDriverLicense
(
EmployeeDriverLicenseId int NOT NULL
CONSTRAINT PKEmployeeDriverLicense PRIMARY
KEY,
EmployeeId int NOT NULL, --Ref to Employee table
DriversLicenseId int NOT NULL, --Ref to DriversLicense table
CONSTRAINT AKEmployeeDriverLicense UNIQUE (EmployeeId,
DriversLicenseId)
);