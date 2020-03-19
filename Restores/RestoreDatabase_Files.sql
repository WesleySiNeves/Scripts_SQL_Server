USE [master];
GO

-- Restore full backup
RESTORE DATABASE [WorldWideImporters]
FROM DISK = '\\SQLBACKUPS\SQLBackup\WordWideImporters\WordWideImporters_FULL.bak'
WITH NORECOVERY,
     MOVE 'WorldWideImporters_Data'
     TO 'D:\SQLData\WorldWideImporters_Data.mdf',
     MOVE 'WorldWideImporters_Log'
     TO 'L:\SQLLog\WorldWideImporters_Log.ldf';
GO

-- Restore differential backup
RESTORE DATABASE [WorldWideImporters]
FROM DISK = '\\SQLBACKUPS\SQLBackup\WordWideImporters\WordWideImporters_DIFF.bak'
WITH NORECOVERY;
GO

-- Restore last 3 log backups
RESTORE LOG [WorldWideImporters]
FROM DISK = '\\SQLBACKUPS\SQLBackup\WordWideImporters\WordWideImporters_LOG.bak'
WITH FILE = 11,
     NORECOVERY;
GO

RESTORE LOG [WorldWideImporters]
FROM DISK = '\\SQLBACKUPS\SQLBackup\WordWideImporters\WordWideImporters_LOG.bak'
WITH FILE = 12,
     NORECOVERY;
GO

RESTORE LOG [WorldWideImporters]
FROM DISK = '\\SQLBACKUPS\SQLBackup\WordWideImporters\WordWideImporters_LOG.bak'
WITH FILE = 13,
     NORECOVERY;
GO

-- Make database available
RESTORE DATABASE [WorldWideImporters] WITH RECOVERY;
GO