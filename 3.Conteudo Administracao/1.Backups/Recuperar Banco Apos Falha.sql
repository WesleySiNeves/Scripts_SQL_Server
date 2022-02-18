/* ==================================================================
--Data: 08/11/2019 
--Autor :Wesley Neves
--Observação: 
Consider the following experiment in Listing 2-10 that performs the following actions:

1. Creates a new database.

2. Creates a new table.

3. Inserts the first record into the table.

4. Performs a full database backup.

5. Inserts the second record into the table.

6. Performs a log backup.

7. Inserts the third record into the table.

8. Simulates a disaster by deleting the database’s primary (MDF) data file.
 
-- ==================================================================
*/
-- Set up experiment: Run selectively as and if required
-- You might have to enable xp_cmdshell by running the following:

EXEC sp_configure 'show advanced' , '1';
RECONFIGURE;
GO
EXEC sp_configure 'xp_cmdshell' , '1';
RECONFIGURE;
GO

--Para essa demostração criaremos uma pasta no Drive C
EXEC xp_cmdshell'md C:\Exam764Ch2\';

EXEC xp_cmdshell'md C:\Exam764Ch2\Backups';

GO


DROP DATABASE IF EXISTS TailLogExperimentDB

-- Create database
CREATE DATABASE TailLogExperimentDB

ON PRIMARY (
			NAME = N'TailLogExperimentDB_data',
			FILENAME = N'C:\Exam764Ch2\TailLogExperimentDB.mdf'
			)
LOG ON (
		NAME = N'TailLogExperimentDB_log',
		 FILENAME = N'C:\Exam764Ch2\TailLogExperimentDB.ldf'
	   )
GO

-- Create table
USE TailLogExperimentDB
GO
CREATE TABLE [MyTable] (Payload VARCHAR(1000));
GO

SELECT * FROM [dbo].[MyTable] AS [MT]


-- Insert first record
INSERT [MyTable] VALUES ('Antes de um backup Full');
GO
-- Perform full backup
BACKUP DATABASE [TailLogExperimentDB] TO DISK = 'C:\Exam764Ch2\Backups\TailLogExperimentDB_FULL.bak' WITH INIT;
GO
-- Insert second record
INSERT [MyTable] VALUES ('Antes de um backup de log');
GO

-- Perform log backup
BACKUP LOG [TailLogExperimentDB] TO DISK = 'C:\Exam764Ch2\Backups\TailLogExperimentDB_LOG.bak'
WITH INIT;
GO
-- Insert third record
INSERT [MyTable] VALUES ('Apos de um backup de log');
GO


-- Simulate disaster
SHUTDOWN;
/*
Execute as seguintes ações:
    1. Use o Windows Explorer para excluir C: \ Exam764Ch2 \ TailLogExperimentDB.mdf
    2. Use o SQL Server Configuration Manager para iniciar o SQL Server
O banco de dados [TailLogExperimentDB] agora deve estar danificado quando você excluiu o
arquivo de dados principal .
*/

/*
Nesta fase, você tem um backup completo e de log que contém apenas os dois primeiros registros que foram inseridos.
 O terceiro registro foi inserido após o backup do log. Se você restaurar o banco de dados nesse estágio, 
você perde o terceiro registro. Conseqüentemente, você precisa fazer backup do log de transações órfão
*/


USE master;
SELECT name ,state_desc FROM sys.databases WHERE name ='TailLogExperimentDB';
GO

-- Try to back up the orphaned tail-log
BACKUP LOG [TailLogExperimentDB] TO DISK = 'C:\Exam764Ch2\Backups\TailLogExperimentDB_OrphanedLog.bak' WITH INIT;

/*
O mecanismo do banco de dados não pode fazer backup do log porque normalmente requer acesso ao arquivo MDF do banco de dados, ]
que contém o local dos arquivos LDF do banco de dados nas tabelas de sistema. O seguinte erro é gerado:
Msg 945' Level 14' State 2' Line 56

Database 'TailLogExperimentDB' cannot be opened due to inaccessible files or

insufficient memory or disk space.  See the SQL Server errorlog for details.

Msg 3013' Level 16' State 1' Line 56

BACKUP LOG is terminating abnormally.
*/


/* ==================================================================
--Data: 07/01/2020 
--Autor :Wesley Neves
--Observação:  Como vimos acima , não podemos executar e não devemos fazer isso dessa forma
 
 -- Abaixo tem a forma correta de fazer.

 -- Para isso devemos iserir a opção  WITH NO_TRUNCATE
-- ==================================================================
*/


BACKUP LOG [TailLogExperimentDB] TO DISK = 'C:\Exam764Ch2\Backups\TailLogExperimentDB_OrphanedLog.bak' WITH NO_TRUNCATE;