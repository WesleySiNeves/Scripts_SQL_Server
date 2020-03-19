
USE ExamBook762Ch3 
GO


CREATE TABLE Examples.DDLChangeLogExam762Examples_DDLTriggerLogging
(
DDLChangeLogId int NOT NULL IDENTITY
CONSTRAINT PKDDLChangeLog PRIMARY KEY,
LogTime datetime2(0) NOT NULL,
DDLStatement nvarchar(max) NOT NULL,
LoginName sysname NOT NULL
);

GO

--DROP USER Exam762Examples_DDLTriggerLogging

CREATE USER Exam762Examples_DDLTriggerLogging WITHOUT LOGIN;



GRANT INSERT ON Examples.DDLChangeLog TO Exam762Examples_DDLTriggerLogging;


GO

DROP TRIGGER DatabaseChanges_DDLTrigger ;
GO


CREATE TRIGGER DatabaseChanges_DDLTrigger
ON DATABASE
WITH EXECUTE AS 'Exam762Examples_DDLTriggerLogging'
FOR CREATE_TABLE, ALTER_TABLE, DROP_TABLE
AS
SET NOCOUNT ON;
DECLARE @eventdata XML = EVENTDATA();
ROLLBACK; --Make sure the event doesn't occur
INSERT INTO Examples.DDLChangeLog
(
    LogTime,
    DDLStatement,
    LoginName
)
SELECT SYSDATETIME(),
       EVENTDATA().value('(/EVENT_INSTANCE/TSQLCommand/CommandText)
[1]', 'nvarchar(max)'),
       ORIGINAL_LOGIN();
THROW 50000, 'Alteracoes nao permitidas', 1;





