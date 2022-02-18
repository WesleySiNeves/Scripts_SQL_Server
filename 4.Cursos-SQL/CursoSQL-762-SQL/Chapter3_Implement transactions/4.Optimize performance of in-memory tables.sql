/*########################
# OBS: Cria banco e dados com FileGroup im memory
*/

CREATE DATABASE ExamBook762Ch3_IMOLTP
ON PRIMARY
       (
           NAME = ExamBook762Ch3_IMOLTP_data,
           FILENAME = 'D:\Sql Server\Bancos\ExamBook762Ch3_IMOLTP.mdf',
           SIZE = 500MB	
       ),
   FILEGROUP ExamBook762Ch3_IMOLTP_FG CONTAINS MEMORY_OPTIMIZED_DATA
       (
           NAME = ExamBook762Ch3_IMOLTP_FG_Container,
           FILENAME = 'D:\Sql Server\Bancos\ExamBook762Ch3_IMOLTP_FG_Container'
       )
LOG ON
    (
        NAME = ExamBook762Ch3_IMOLTP_log,
        FILENAME = 'D:\Sql Server\Bancos\ExamBook762Ch3_IMOLTP_log.ldf',
        SIZE = 500MB
    );
GO





USE ExamBook762Ch3_IMOLTP;

GO


CREATE SCHEMA Examples;

GO
CREATE TABLE Examples.Order_Disk (
OrderId INT NOT NULL PRIMARY KEY NONCLUSTERED,
OrderDate DATETIME NOT NULL,
CustomerCode NVARCHAR(5) NOT NULL
);
GO

CREATE TABLE Examples.Order_IM
(
    OrderID INT NOT NULL PRIMARY KEY NONCLUSTERED,
    OrderDate DATETIME NOT NULL,
    CustomerCode NVARCHAR(5) NOT NULL
)
WITH (MEMORY_OPTIMIZED = ON);
GO


