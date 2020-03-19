-- ==================================================================
/* Dynamic data masking
O mascaramento dinâmico de dados permite que você mascara dado
s em uma coluna a partir da exibição do usuário
Documentação :https://docs.microsoft.com/en-us/sql/relational-databases/security/dynamic-data-masking
 */
-- ==================================================================

CREATE TABLE Examples.DataMasking (
    FirstName NVARCHAR(50) NULL,
    LastName NVARCHAR(50) NOT NULL,
    PersonNumber CHAR(10) NOT NULL,
    Status VARCHAR(10), --domain of values ('Active','Inactive','New')
    EmailAddress NVARCHAR(50) NULL, --(real email address ought to be longer)
    BirthDate DATE NOT NULL, --Time we first saw this person.
    CarCount TINYINT NOT NULL --just a count we can mask
);



INSERT INTO Examples.DataMasking (FirstName,
                                  LastName,
                                  PersonNumber,
                                  Status,
                                  EmailAddress,
                                  BirthDate,
                                  CarCount)
VALUES ('Jay', 'Hamlin', '0000000014', 'Active', 'jay@litwareinc.com',  CAST('1979-01-12' AS DATE), 0),
('Darya', 'Popkova', '0000000032', 'Active', 'darya.p@proseware.net',  CAST('1979-01-12' AS DATE), 1),
('Tomasz', 'Bochenek', '0000000102', 'Active', NULL, CAST('1959-03-30' AS DATE), 1 );


SELECT * FROM  Examples.DataMasking AS DM



CREATE USER MaskedView WITHOUT LOGIN;
GRANT SELECT ON Examples.DataMasking TO MaskedView;



ALTER TABLE Examples.DataMasking
ALTER COLUMN FirstName
ADD MASKED WITH(FUNCTION='default()');


ALTER TABLE Examples.DataMasking
ALTER COLUMN BirthDate
ADD MASKED WITH(FUNCTION='default()');

ALTER TABLE Examples.DataMasking
ALTER COLUMN EmailAddress
ADD MASKED WITH(FUNCTION='email()');


--Note that it uses double quotes in the function call
ALTER TABLE Examples.DataMasking
ALTER COLUMN PersonNumber
ADD MASKED WITH(FUNCTION='partial(2,"*******",1)');


ALTER TABLE Examples.DataMasking
ALTER COLUMN LastName
ADD MASKED WITH(FUNCTION='partial(3,"_____",2)');

ALTER TABLE Examples.DataMasking
ALTER COLUMN CarCount
ADD MASKED WITH(FUNCTION='random(1,3)');

-- ==================================================================
--Observação: Agora vamos logar com a conta criada
-- ================================================================== 
/*Vamos executar o Select na tabela com a visão do usuario criado*/


EXECUTE AS USER = 'MaskedView';
SELECT *
FROM Examples.DataMasking;