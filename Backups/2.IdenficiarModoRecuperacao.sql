SELECT D.name,
       D.database_id,
       D.compatibility_level,
       D.collation_name,
       D.recovery_model_desc
FROM sys.databases AS D;

ALTER DATABASE AdventureWorks SET RECOVERY FULL
ALTER DATABASE [AdventureWorks]  SET RECOVERY BULK_LOGGED
ALTER DATABASE [AdventureWorks]  SET RECOVERY  SIMPLE


GO