
------Listing 3-1 Create a test environment for exploring transaction behavior
CREATE DATABASE ExamBook762Ch3;
GO
USE ExamBook762Ch3;
GO
CREATE SCHEMA Examples;

GO

CREATE TABLE Examples.TestParent (
    ParentId INT NOT NULL
        CONSTRAINT PKTestParent PRIMARY KEY,
    ParentName VARCHAR(100) NULL);

CREATE TABLE Examples.TestChild (
    ChildId INT NOT NULL
        CONSTRAINT PKTestChild PRIMARY KEY,
    ParentId INT NOT NULL,
    ChildName VARCHAR(100) NULL);
ALTER TABLE Examples.TestChild
ADD CONSTRAINT FKTestChild_Ref_TestParent
    FOREIGN KEY (ParentId)
    REFERENCES Examples.TestParent (ParentId);
INSERT INTO Examples.TestParent (ParentId,
                                 ParentName)
VALUES (1, 'Dean'),
(2, 'Michael'),
(3, 'Robert');
INSERT INTO Examples.TestChild (ChildId,
                                ParentId,
                                ChildName)
VALUES (1, 1, 'Daniel'),
(2, 1, 'Alex'),
(3, 2, 'Matthew'),
(4, 3, 'Jason');



------Testing atomicity with foreign key constraint violation
BEGIN TRANSACTION;
INSERT INTO Examples.TestParent (ParentId,
                                 ParentName)
VALUES (4, 'Linda');
DELETE Examples.TestParent
 WHERE TestParent.ParentName = 'Bob';
COMMIT TRANSACTION;


SELECT *
  FROM Examples.TestParent AS TP;


/*Aqui garantimos a Atomicidade do banco*/
------Guaranteeing atomicity with XACT_ABORT ON
SET XACT_ABORT ON;
BEGIN TRANSACTION;
INSERT INTO Examples.TestParent (ParentId,
                                 ParentName)
VALUES (5, 'Isabelle');
DELETE Examples.TestParent
 WHERE TestParent.ParentName = 'Bob';
COMMIT TRANSACTION;


SELECT *
  FROM Examples.TestParent AS TP;

------Testing atomicity with syntax error
SET XACT_ABORT OFF;
BEGIN TRANSACTION;
INSERT INTO Examples.TestParent (ParentId,
                                 ParentName)
VALUES (5, 'Isabelle');
DELETE Examples.TestParent
 WHERE TestParent.ParentName = 'Bob';
COMMIT TRANSACTION;

SELECT *
  FROM Examples.TestParent AS TP;