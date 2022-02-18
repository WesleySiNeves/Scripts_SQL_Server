-- Initial full backup
BACKUP DATABASE AdventureWorks  TO
DISK = 'R:\SQLBackup\AdventureWorks_BackupDevice1.bak',
DISK = 'R:\SQLBackup\AdventureWorks_BackupDevice2.bak',
DISK = 'R:\SQLBackup\AdventureWorks_BackupDevice 3.bak',
DISK = 'R:\SQLBackup\AdventureWorks_BackupDevice 4.bak'
WITH FORMAT
MEDIANAME = ' AdventureWorksMediaSet1';
GO