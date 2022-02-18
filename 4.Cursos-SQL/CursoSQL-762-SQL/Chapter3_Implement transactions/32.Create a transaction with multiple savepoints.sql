USE ExamBook762Ch3;

BEGIN TRANSACTION;
INSERT INTO Examples.TestParent
(
    ParentId,
    ParentName
)
VALUES
(8, 'Ed');

SAVE TRANSACTION StartTran;

SELECT 'StartTran' AS Status,
       ParentId,
       ParentName
FROM Examples.TestParent;

DELETE Examples.TestParent
WHERE ParentId = 7;
SAVE TRANSACTION DeleteTran;

SELECT 'Delete 1' AS Status,
       ParentId,
       ParentName
FROM Examples.TestParent;


DELETE Examples.TestParent
WHERE ParentId = 6;
SELECT 'Delete 2' AS Status,
       ParentId,
       ParentName
FROM Examples.TestParent;


ROLLBACK TRANSACTION DeleteTran;
SELECT 'RollbackDelete2' AS Status,
       ParentId,
       ParentName
FROM Examples.TestParent;


ROLLBACK TRANSACTION StartTran;
SELECT @@TRANCOUNT AS 'TranCount';
SELECT 'RollbackStart' AS Status,
       ParentId,
       ParentName
FROM Examples.TestParent;
COMMIT TRANSACTION;
GO

SELECT * FROM  Examples.TestParent AS TP