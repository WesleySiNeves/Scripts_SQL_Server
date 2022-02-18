USE ExamBook762Ch3;

/*########################
# OBS: lock hierarchy
*/


/*
This lock mode, also known as a read lock, is used for SELECT,
INSERT, UPDATE, and DELETE operations and is released as soon as data has
been read from the locked resource. While the resource is locked, other transactions
cannot change its data. However, in theory, an unlimited number of shared (s) locks
can exist on a resource simultaneously. You can force SQL Server to hold the lock for
the duration of the transaction by adding the HOLDLOCK table hint like this:
*/


BEGIN TRANSACTION;
SELECT ParentId, ParentName
FROM Examples.TestParent WITH (HOLDLOCK);
WAITFOR DELAY '00:00:15';

