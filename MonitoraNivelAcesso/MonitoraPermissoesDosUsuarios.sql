SELECT          
   S.name, 
   S.loginname, 
   S.password,
   l.sid, 
   l.is_disabled, 
   S.createdate, 
   S.denylogin,
   S.hasaccess,
   S.isntname,
   S.isntgroup,
   S.isntuser,
   S.sysadmin,
   S.securityadmin,
   S.serveradmin,
   S.processadmin,
   S.diskadmin,
   S.dbcreator,
   S.bulkadmin
FROM [sys].[syslogins] S
 LEFT JOIN       
  [sys].[sql_logins] L
 ON
 S.sid = L.sid


 EXEC Sp_helplogins
