
USE ExamBook762Ch3


/*########################
# OBS: Criando proceduresde DML
*/

CREATE TABLE Examples.SimpleTable
(
    SimpleTableId INT NOT NULL IDENTITY(1, 1)
        CONSTRAINT PKSimpleTable PRIMARY KEY,
    Value1 VARCHAR(20) NOT NULL,
    Value2 VARCHAR(20) NOT NULL
);

GO


CREATE PROCEDURE Examples.SimpleTable_Insert
    @SimpleTableId INT,
    @Value1 VARCHAR(20),
    @Value2 VARCHAR(20)
AS
INSERT INTO Examples.SimpleTable
(
    Value1,
    Value2
)
VALUES
(@Value1, @Value2);
GO


GO
CREATE PROCEDURE Examples.SimpleTable_Update
    @SimpleTableId INT,
    @Value1 VARCHAR(20),
    @Value2 VARCHAR(20)
AS
UPDATE Examples.SimpleTable
SET Value1 = @Value1,
    Value2 = @Value2
WHERE SimpleTableId = @SimpleTableId;
GO


CREATE PROCEDURE Examples.SimpleTable_Delete
    @SimpleTableId INT,
    @Value VARCHAR(20)
AS
DELETE Examples.SimpleTable
WHERE SimpleTableId = @SimpleTableId;
GO


CREATE PROCEDURE Examples.SimpleTable_Select
AS
SELECT SimpleTableId,
       Value1,
       Value2
FROM Examples.SimpleTable
ORDER BY Value1;



 --usando  sp_describe_first_result_set
EXEC sys.sp_describe_first_result_set  @tsql = N'EXEC Examples.SimpleTable_Select'
