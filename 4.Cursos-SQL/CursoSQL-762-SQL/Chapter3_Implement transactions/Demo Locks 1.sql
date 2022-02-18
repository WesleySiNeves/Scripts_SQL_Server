

-- ==================================================================
/*
 Demo sobre Locks
 */
-- ==================================================================
USE Certificacao70762;
GO

DROP TABLE IF EXISTS Examples.LockingA;


CREATE TABLE Examples.LockingA (
    RowId INT NOT NULL
        CONSTRAINT PKLockingARowId PRIMARY KEY,
    ColumnText VARCHAR(100) NOT NULL);


INSERT INTO Examples.LockingA (RowId,
                               ColumnText)
VALUES (1, 'Row 1'),
(2, 'Row 2'),
(3, 'Row 3'),
(4, 'Row 4');


DROP TABLE IF EXISTS Examples.LockingB;

CREATE TABLE Examples.LockingB
(
RowId int NOT NULL
CONSTRAINT PKLockingBRowId PRIMARY KEY,
ColumnText varchar(100) NOT NULL
);

INSERT INTO Examples.LockingB(RowId, ColumnText)
VALUES (1, 'Row 1'), (2, 'Row 2'), (3, 'Row 3'), (4, 'Row 4');


BEGIN TRANSACTION;
SELECT RowId, ColumnText
FROM Examples.LockingA
WITH (HOLDLOCK, ROWLOCK);

--ROLLBACK

-- ==================================================================
/* Em outra sessão rode o seguinte Script
 */
-- ==================================================================


BEGIN TRANSACTION;
UPDATE Examples.LockingA
SET ColumnText = 'Row 2 Updated'
WHERE RowId = 2;

--ROLLBACK
-- ==================================================================
--Observação: Veja o resultado
-- ==================================================================

SELECT Loc.request_session_id AS s_id,
       Loc.resource_type,
       Loc.resource_associated_entity_id,
       Loc.request_status,
       Loc.request_mode,
	   Re.Resource
  FROM sys.dm_tran_locks Loc
 CROSS APPLY (   SELECT OBJECT_NAME(partitions.object_id) AS Resource,
                        partitions.object_id,
                        partitions.hobt_id
                   FROM sys.partitions
                  WHERE partitions.hobt_id = Loc.resource_associated_entity_id) Re
 WHERE Loc.resource_database_id = DB_ID('Certificacao70762')
   AND Loc.resource_type        <> 'DATABASE';



SELECT [resource_type] = t1.resource_type,
       [Banco] = DB_NAME(t1.resource_database_id),
       t1.resource_associated_entity_id AS res_entid,
       t1.request_mode AS mode,
       [Sessao bloqueada] = t1.request_session_id,
       [Sessap Bloqueando] = t2.blocking_session_id
  FROM sys.dm_tran_locks AS t1
 INNER JOIN sys.dm_os_waiting_tasks AS t2
    ON t1.lock_owner_address = t2.resource_address;



SELECT dm_os_wait_stats.wait_type AS wait,
       dm_os_wait_stats.waiting_tasks_count AS wt_cnt,
       dm_os_wait_stats.wait_time_ms AS wt_ms,
       dm_os_wait_stats.max_wait_time_ms AS max_wt_ms,
       dm_os_wait_stats.signal_wait_time_ms AS signal_ms
  FROM sys.dm_os_wait_stats
 WHERE dm_os_wait_stats.wait_type LIKE 'LCK%'
 ORDER BY dm_os_wait_stats.wait_time_ms DESC;


 /*Vc pode limpar dos dados de dm_os_wait_stats , pois estes são cumulativos */
 DBCC SQLPERF (N'sys.dm_os_wait_stats', CLEAR); ?


