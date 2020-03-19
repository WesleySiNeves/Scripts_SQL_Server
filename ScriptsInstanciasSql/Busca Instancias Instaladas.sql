--DECLARE @GetInstances TABLE (
--    Value NVARCHAR(100),
--    InstanceNames NVARCHAR(100),
--    Data NVARCHAR(100));

--INSERT INTO @GetInstances



EXECUTE sys.xp_regread @rootkey = 'HKEY_LOCAL_MACHINE',
                       @key = 'SOFTWARE\Microsoft\Microsoft SQL Server',
                       @value_name = 'InstalledInstances';

--SELECT [@GetInstances].InstanceNames
--  FROM @GetInstances;