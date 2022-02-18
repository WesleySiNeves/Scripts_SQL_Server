-- ==================================================================
 --Observa��o: Em uma rode a query abaixo
-- ==================================================================

BEGIN TRANSACTION;
UPDATE Examples.LockingA
   SET ColumnText = 'Row 1 Updated'
 WHERE RowId = 1;

WAITFOR DELAY '00:00:05';

UPDATE Examples.LockingB
   SET ColumnText = 'Row 1 Updated Again'
 WHERE RowId = 1;


 -- ==================================================================
 --Observa��o: Em outra sess�o rode esta
 -- ==================================================================


 BEGIN TRANSACTION;
UPDATE Examples.LockingB
SET ColumnText = 'Row 1 Updated'
WHERE RowId = 1;
WAITFOR DELAY '00:00:05';
UPDATE Examples.LockingA;
SET ColumnText = 'Row 1 Updated Again'
WHERE RowId = 1;