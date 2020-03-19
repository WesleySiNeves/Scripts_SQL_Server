DECLARE @TimeZone VARCHAR(50);
EXEC master.sys.xp_regread 'HKEY_LOCAL_MACHINE',
                           'SYSTEM\CurrentControlSet\Control\TimeZoneInformation',
                           'TimeZoneKeyName',
                           @TimeZone OUT;
SELECT @TimeZone;