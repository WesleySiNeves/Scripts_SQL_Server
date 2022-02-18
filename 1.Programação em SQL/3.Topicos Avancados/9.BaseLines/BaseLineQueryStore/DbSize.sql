
WITH Dados AS (
SELECT database_files.type_desc,
       ISNULL(SUM(CAST(FILEPROPERTY(database_files.name, 'SpaceUsed') AS bigint) * 8192.) / 1024 / 1024, 0) AS DatabaseSizeInMB,
       ISNULL(SUM(CAST(FILEPROPERTY(database_files.name, 'SpaceUsed') AS bigint) * 8192.) / 1024 / 1024 / 1024, 0) AS DatabaseSizeInGB
  FROM sys.database_files
 GROUP BY database_files.type_desc
)
SELECT R.*	 FROM Dados R




