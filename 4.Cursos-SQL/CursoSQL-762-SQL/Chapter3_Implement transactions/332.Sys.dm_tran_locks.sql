

USE ExamBook762Ch3;
/*########################
# OBS: Cria as tabelas
*/

USE ExamBook762Ch3;

DROP TABLE IF  EXISTS Examples.LockingA;

CREATE TABLE Examples.LockingA
(
RowId int NOT NULL
CONSTRAINT PKLockingARowId PRIMARY KEY,
ColumnText varchar(100) NOT NULL
);


INSERT INTO Examples.LockingA(RowId, ColumnText)
VALUES (1, 'Row 1'), (2, 'Row 2'), (3, 'Row 3'), (4, 'Row 4');

DROP TABLE IF  EXISTS Examples.LockingB;


CREATE TABLE Examples.LockingB
(
RowId int NOT NULL
CONSTRAINT PKLockingBRowId PRIMARY KEY,
ColumnText varchar(100) NOT NULL
);
INSERT INTO Examples.LockingB(RowId, ColumnText)
VALUES (1, 'Row 1'), (2, 'Row 2'), (3, 'Row 3'), (4, 'Row 4');




/*########################
# OBS: Inicio da demo	
*/


BEGIN TRANSACTION;
SELECT RowId, ColumnText
FROM Examples.LockingA
WITH (HOLDLOCK, ROWLOCK);



/*########################
# OBS: In a separate session, start another transaction:
*/

BEGIN TRANSACTION;
UPDATE Examples.LockingA
SET ColumnText = 'Row 2 Updated'
WHERE RowId = 2;


/*########################
# OBS: Now let’s use the sys.dm_tran_locks DMV to view some details about the current locks:
*/
--ROLLBACK

SELECT
request_session_id as s_id,
resource_type,
object_name(P.object_id) as Resource,
request_status,
request_mode
FROM sys.dm_tran_locks LOC
JOIN sys.partitions AS P ON p.hobt_id =LOC.resource_associated_entity_id
WHERE resource_database_id = db_id('ExamBook762Ch3');

