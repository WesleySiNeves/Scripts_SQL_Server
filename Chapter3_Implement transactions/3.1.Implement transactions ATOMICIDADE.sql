
/*Identify DML statement results based on transaction behavior
Atomicity
Consistency
Isolation
Durability	

*/

--drop database ExamBook762Ch3;

--USE TSQLV4

CREATE SCHEMA Examples;
GO

/* ==================================================================
--Data: 21/09/2018 
--Autor :Wesley Neves
--Observação:  Parte 1 ) Alimentação dos dados
 
-- ==================================================================
*/

CREATE TABLE Examples.TestParent (
                                 ParentId   INT          NOT NULL
                                     CONSTRAINT PKTestParent PRIMARY KEY,
                                 ParentName VARCHAR(100) NULL
                                 );
CREATE TABLE Examples.TestChild (
                                ChildId   INT          NOT NULL
                                    CONSTRAINT PKTestChild PRIMARY KEY,
                                ParentId  INT          NOT NULL,
                                ChildName VARCHAR(100) NULL
                                );
ALTER TABLE Examples.TestChild
ADD CONSTRAINT FKTestChild_Ref_TestParent
    FOREIGN KEY (ParentId)
    REFERENCES Examples.TestParent (ParentId);
INSERT INTO Examples.TestParent (
                                ParentId,
                                ParentName
                                )
VALUES (1, 'Dean'),
(2, 'Michael'),
(3, 'Robert');
INSERT INTO Examples.TestChild (
                               ChildId,
                               ParentId,
                               ChildName
                               )
VALUES (1, 1, 'Daniel'),
(2, 1, 'Alex'),
(3, 2, 'Matthew'),
(4, 3, 'Jason');


SELECT PAI.ParentId,
       [PAI] = PAI.ParentName,
       Filho.ChildId,
       [FILHO] = Filho.ChildName
FROM Examples.TestParent PAI
     LEFT JOIN
     Examples.TestChild AS Filho ON PAI.ParentId = Filho.ParentId;



/*FIM*/

/*Saple Update*/

UPDATE Examples.TestParent
SET TestParent.ParentName = 'Bob'
WHERE TestParent.ParentName = 'Robert';


/*Identificando Atomicity*/



BEGIN TRANSACTION T1;

UPDATE Examples.TestParent
SET TestParent.ParentName = 'Mike'
WHERE TestParent.ParentName = 'Michael';


UPDATE Examples.TestChild
SET TestChild.ChildName = 'Matt'
WHERE TestChild.ChildName = 'Matthew';


COMMIT TRANSACTION T1;




SELECT PAI.ParentId,
       [PAI] = PAI.ParentName,
       Filho.ChildId,
       [FILHO] = Filho.ChildName
FROM Examples.TestParent PAI
     LEFT JOIN
     Examples.TestChild AS Filho ON PAI.ParentId = Filho.ParentId;
/*
On the other hand, if any one of the statements in a transaction fails, the behavior
depends on the way in which you construct the transaction statements and whether you
change the SQL Server default settings.
*/


SELECT *
FROM Examples.TestParent;


/* somente a transacao para ver que mesmo ocorrendo uma falha o insert e comitado*/
BEGIN TRANSACTION T2;

INSERT INTO Examples.TestParent (
                                ParentId,
                                ParentName
                                )
VALUES (4, 'Linda');


DELETE Examples.TestParent
WHERE TestParent.ParentName = 'Bob';

COMMIT TRANSACTION;


SELECT *
FROM Examples.TestParent;

/*
If you want SQL Server to roll back the entire transaction and thereby guarantee
atomicity, one option is to use the SET XACT_ABORT option to ON prior to executing the
transaction like this:

ou seja vc tem que udentificar se o banco está configurado com  SET XACT_ABORT ON 

Veja o exemplo abaixo 
*/

SET XACT_ABORT ON;
BEGIN TRANSACTION;
INSERT INTO Examples.TestParent (
                                ParentId,
                                ParentName
                                )
VALUES (5, 'Isabelle');
DELETE Examples.TestParent
WHERE TestParent.ParentName = 'Bob';
COMMIT TRANSACTION;



SELECT *
FROM Examples.TestParent;


/**/

/*Agora veja o seguinte*/

SET XACT_ABORT OFF;
BEGIN TRANSACTION;
INSERT INTO Examples.TestParent (
                                ParentId,
                                ParentName
                                )
VALUES (5, 'Isabelle');
DELETE Examples.TestParent
WHERE TestParent.ParentName = 'Bob';
COMMIT TRANSACTION;



/*Agora veja que isso não acontece se o  bloco estiver dentro de um TRY
*/

BEGIN TRY
    BEGIN TRANSACTION;
    INSERT INTO Examples.TestParent (
                                    ParentId,
                                    ParentName
                                    )
    VALUES (5, 'Isabelle');
    DELETE Examples.TestParent
    WHERE TestParent.ParentName = 'Bob';
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;
END CATCH;


/*

For the exam, you should understand how nested transactions interact and how
transactions roll back in the event of failure.



/*Isolation*/

if you rely on the behavior of READ COMMITTED, the SQL Server default
isolation level.
*/



/*Rode esse comando abaixo e em ooutra sessão rode o mais abaixo*/


BEGIN TRANSACTION;
INSERT INTO Examples.TestParent (
                                ParentId,
                                ParentName
                                )
VALUES (5, 'Isabelle');


/*esse rode em outra sessão*/

SELECT TestParent.ParentId,
       TestParent.ParentName
FROM Examples.TestParent;