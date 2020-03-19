
/*Identify DML statement results based on transaction behavior
Atomicity
Consistency
Isolation
Durability	

*/


SET XACT_ABORT OFF;
--drop database ExamBook762Ch3;

CREATE DATABASE ExamBook762Ch3;
GO
USE ExamBook762Ch3;
GO
CREATE SCHEMA Examples;
GO




DROP TABLE Examples.TestChild
DROP TABLE Examples.TestParent



CREATE TABLE Examples.TestParent
(
ParentId int NOT NULL
CONSTRAINT PKTestParent PRIMARY KEY,
ParentName varchar(100) NULL
);
CREATE TABLE Examples.TestChild
(
ChildId int NOT NULL
CONSTRAINT PKTestChild PRIMARY KEY,
ParentId int NOT NULL,
ChildName varchar(100) NULL
);

ALTER TABLE Examples.TestChild
ADD CONSTRAINT FKTestChild_Ref_TestParent
FOREIGN KEY (ParentId) REFERENCES
Examples.TestParent(ParentId);


INSERT INTO Examples.TestParent(ParentId, ParentName)
VALUES (1, 'Dean'),(2, 'Michael'),(3, 'Robert');
INSERT INTO Examples.TestChild (ChildId, ParentId, ChildName)
VALUES (1,1, 'Daniel'), (2, 1, 'Alex'), (3, 2, 'Matthew'), (4,
3, 'Jason');



select * from ExamBook762Ch3.Examples.TestParent

select * from ExamBook762Ch3.Examples.TestChild


/*Simles Update*/

UPDATE Examples.TestParent
SET ParentName = 'Bob'
WHERE ParentName = 'Robert';


/*Identificando Atomicity*/



BEGIN TRANSACTION;
UPDATE Examples.TestParent
SET ParentName = 'Mike'
WHERE ParentName = 'Michael';
UPDATE Examples.TestChild
SET ChildName = 'Matt'
WHERE ChildName = 'Matthew';
COMMIT TRANSACTION;

/*

1	Dean	1	Daniel
1	Dean	2	Alex
2	Mike	3	Matt
3	Bob	4	Jason
*/

SELECT TestParent.ParentId, ParentName, ChildId, ChildName
FROM Examples.TestParent
FULL OUTER JOIN Examples.TestChild ON TestParent.ParentId =
TestChild.ParentId;


/*
On the other hand, if any one of the statements in a transaction fails, the behavior
depends on the way in which you construct the transaction statements and whether you
change the SQL Server default settings.
*/


select * from Examples.TestParent
JOIN Examples.TestChild AS TC ON TestParent.ParentId = TC.ParentId
WHERE TC.ParentId =3
SELECT * FROM Examples.TestChild AS TC

/*rede somente a transacao para ver que mesmo ocorrendo uma falha o insert e comitado*/
BEGIN TRANSACTION;

INSERT INTO Examples.TestParent(ParentId,
ParentName)

VALUES (4, 'Linda');

DELETE Examples.TestParent
WHERE ParentName = 'Bob';

COMMIT TRANSACTION;


select * from Examples.TestParent

/*
If you want SQL Server to roll back the entire transaction and thereby guarantee
atomicity, one option is to use the SET XACT_ABORT option to ON prior to executing the
transaction like this:

ou seja vc tem que udentificar se o banco está configurado com  SET XACT_ABORT ON 

Veja o exemplo abaixo 
*/

SET XACT_ABORT ON;
BEGIN TRANSACTION;
INSERT INTO Examples.TestParent(ParentId, ParentName)
VALUES (5, 'Ana');
DELETE Examples.TestParent
WHERE ParentName = 'Bob';
COMMIT TRANSACTION;



select * from Examples.TestParent




/**/

/*Agora veja o seguinte*/

SET XACT_ABORT OFF;
BEGIN TRANSACTION;
INSERT INTO Examples.TestParent(ParentId, ParentName)
VALUES (6, 'Isabelle');
DELETE Examples.TestParent
where ParentName = 'Bob';
COMMIT TRANSACTION;



/*Agora veja que isso não acontece se o  bloco estiver dentro de um TRY
*/

BEGIN TRY
BEGIN TRANSACTION;
INSERT INTO Examples.TestParent(ParentId, ParentName)
VALUES (5, 'Isabelle');
DELETE Examples.TestParent
WHERE ParentName = 'Bob';
COMMIT TRANSACTION;
END TRY
BEGIN CATCH
IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
END CATCH


/*

For the exam, you should understand how nested transactions interact and how
transactions roll back in the event of failure.



/*Isolation*/

if you rely on the behavior of READ COMMITTED, the SQL Server default
isolation level.
*/



/*Rode esse comando abaixo e em ooutra sessão rode o mais abaixo*/


BEGIN TRANSACTION;
INSERT INTO Examples.TestParent(ParentId, ParentName)
VALUES (5, 'Isabelle');


/*esse rode em outra sessão*/

SELECT ParentId, ParentName
FROM Examples.TestParent;