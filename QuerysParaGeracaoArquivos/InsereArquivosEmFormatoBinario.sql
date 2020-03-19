--CREATE TABLE dbo.Documents
--(
--id INT IDENTITY(1,1) NOT NULL,
--title NVARCHAR(100) NOT NULL,
--doctype NCHAR(4) NOT NULL,
--docexcerpt NVARCHAR(1000) NOT NULL,
--doccontent VARBINARY(MAX) NOT NULL,
--CONSTRAINT PK_Documents
--PRIMARY KEY CLUSTERED(id)
--);


INSERT  INTO dbo.Documents
        ( title ,
          doctype ,
          docexcerpt ,
          doccontent
        )
        SELECT  N'Introduction to Data Mining' ,
                N'odt' ,
                N'Using Data Mining is becoming more a necessity for every company
and not an advantage of some rare companies anymore. ' ,
                bulkcolumn
        FROM    OPENROWSET(BULK 'F:\Certficação SQL Server\Exercicios TSQL-Microsoft.Press.Training.Kit.Exam.70-461.odt',
                           SINGLE_BLOB) AS doc;