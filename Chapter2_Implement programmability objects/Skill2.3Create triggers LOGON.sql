USE ExamBook762Ch2;

GO

CREATE TABLE Examples.DDLDatabaseChangeLog
(
    DDLDatabaseChangeLogId INT NOT NULL IDENTITY
        CONSTRAINT PKDDLDatabaseChangeLog PRIMARY KEY,
    LogTime DATETIME2(0) NOT NULL,
    DDLStatement NVARCHAR(MAX) NOT NULL,
    LoginName sysname NOT NULL
);


--Names used to make it clear where you have used examples from this book outside
--of primary database
GO


/*########################
# OBS: Codigo da trigger
*/

--Names used to make it clear where you have used examples from this book outside
--of primary database

/*########################
# OBS: criando um usuario padrao
*/
CREATE LOGIN Exam762Examples_DDLTriggerLogging WITH PASSWORD = 'PASSWORD$1';

GO

CREATE USER Exam762Examples_DDLTriggerLogging
FOR LOGIN
Exam762Examples_DDLTriggerLogging;

--fazendo permissão para inseir na tabela
GRANT INSERT ON Examples.DDLDatabaseChangeLog TO
Exam762Examples_DDLTriggerLogging;


GO
/*########################
# OBS: Criand a trigger
*/

USE master
GO

CREATE TRIGGER DatabaseCreations_ServerDDLTrigger
ON ALL SERVER WITH EXECUTE AS 'Exam762Examples_DDLTriggerLogging'
FOR CREATE_DATABASE, ALTER_DATABASE, DROP_DATABASE
AS
SET NOCOUNT ON;
--trigger is stored in master db, so must
INSERT INTO
ExamBook762Ch2.Examples.DDLDatabaseChangeLog(LogTime,DDLStatement,LoginName)
SELECT SYSDATETIME(),EVENTDATA().value('(/EVENT_INSTANCE/TSQLCommand/CommandText)
[1]','nvarchar(max)'),
ORIGINAL_LOGIN(); --Original login gives you the user that is connected.
--Otherwise we would get the EXECUTE AS USER



/*########################
# OBS: Criando outro login
*/

GO


CREATE LOGIN DatabaseCreator WITH PASSWORD ='a' ;
GRANT CREATE ANY DATABASE TO DatabaseCreator;
GRANT ALTER ANY DATABASE TO DatabaseCreator;



SELECT LogTime, DDLStatement, LoginName
FROM Examples.DDLDatabaseChangeLog;


DROP TRIGGER DatabaseCreations_ServerDDLTrigger ON ALL SERVER;


