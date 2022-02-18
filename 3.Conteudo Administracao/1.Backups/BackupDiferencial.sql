-- Differential backup
BACKUP DATABASE AdventureWorks TO
DISK = 'R:\SQLBackup\AdventureWorks_BackupDevice1.bak'
DISK = 'R:\SQLBackup\AdventureWorks_BackupDevice 2.bak'
DISK = 'R:\SQLBackup\AdventureWorks_BackupDevice 3.bak'
DISK = 'R:\SQLBackup\AdventureWorks_BackupDevice 4.bak'
WITH
NOINIT
MEDIANAME = 'AdventureWorksMediaSet1'
DIFFERENTIAL;
GO