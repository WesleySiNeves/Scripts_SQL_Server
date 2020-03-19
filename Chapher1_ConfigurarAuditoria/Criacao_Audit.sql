USE [master];
GO

-- Create audit
CREATE SERVER AUDIT [SQLAudit]
TO FILE(
           FILEPATH = N'D:\SQLAudit\',
           MAXSIZE = 4096MB,
           MAX_ROLLOVER_FILES = 2147483647,
           RESERVE_DISK_SPACE = OFF
       )
WITH(
        QUEUE_DELAY = 1000,
        ON_FAILURE = CONTINUE,
        AUDIT_GUID = '4ab952ef-97c4-4e02-8a9e-1b4324499705'
    );



ALTER SERVER AUDIT [SQLAudit]
WITH(
        STATE = ON
    );
GO



-- Create server audit specification
CREATE SERVER AUDIT SPECIFICATION [ServerAuditSpecification-Logins]
FOR SERVER AUDIT [SQLAudit]
    ADD(FAILED_LOGIN_GROUP),
    ADD(SUCCESSFUL_LOGIN_GROUP),
    ADD(LOGOUT_GROUP)
WITH(STATE = ON);
GO

-- Create database audit specification
USE [WideWorldImporters];
GO

CREATE DATABASE AUDIT SPECIFICATION [DatabaseAuditSpecification-Governance]
FOR SERVER AUDIT [SQLAudit]
    ADD(BACKUP_RESTORE_GROUP),
    ADD(AUDIT_CHANGE_GROUP),
    ADD(DATABASE_PERMISSION_CHANGE_GROUP),
    ADD(USER_CHANGE_PASSWORD_GROUP),
    ADD(UPDATE ON OBJECT::[Sales].[OrderLines] BY [public]),
    ADD(SELECT ON OBJECT::[Application].[People] BY [Isabelle])
WITH(STATE = ON);
GO