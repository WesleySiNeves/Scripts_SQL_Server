USE master
GO

-- Drop and restore Databases
IF EXISTS(SELECT * FROM sys.sysdatabases WHERE name = 'TSQL')
BEGIN
	DROP DATABASE TSQL
END
GO



RESTORE DATABASE [TSQL] FROM 
 DISK = N'D:\2.TreinamentoSQLServer2016\Treinamentos Oficiais\Setupfiles\TSQL.bak' WITH  REPLACE,
MOVE N'TSQL' TO N'D:\2.TreinamentoSQLServer2016\Treinamentos Oficiais\Setupfiles\TSQL.mdf', 
MOVE N'TSQL_Log' TO N'D:\2.TreinamentoSQLServer2016\Treinamentos Oficiais\Setupfiles\TSQL_log.ldf'
GO
ALTER AUTHORIZATION ON DATABASE::TSQL TO [ADVENTUREWORKS\Student];
GO

