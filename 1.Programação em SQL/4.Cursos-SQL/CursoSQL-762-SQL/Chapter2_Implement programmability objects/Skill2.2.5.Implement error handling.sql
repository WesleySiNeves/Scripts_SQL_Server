/*########################
# OBS: There are several topics in the process of error handling and transaction control logic
that we review in this section:
Throwing an error It is often useful to be able to throw our own error messages to
cause the stored procedure code (or really any code) to stop, telling the caller why.
Handling an error In order to manage the code flow after an error has occurred, you
need to be able to capture the error and act accordingly.
Transaction control logic in your error handling Transactions are used to control
grouping statements together to ensure that multiple statements complete or fail as an
atomic unit.

*/

--1)Throwing an error
/*
There are two methods of throwing an error in
Transact-SQL. First is using the THROW statement. THROW lets you specify an error
number (50000 or greater, as 49999 
*/

RAISERROR (' RAISERROR This is an error message',16,1);

THROW 50000, 'This is an error message',1;


/*THROW  interrompe o Batch*/

THROW 50000, 'This is an error message',1;
SELECT 'Batch continued'

/*RAISERROR não interrompe o Batch*/
RAISERROR ('This is an error message',16,1);
SELECT 'Batch continued'


/*########################
# OBS: Demostração em Procedures
*/


GO
USE ExamBook762Ch3
DROP PROC IF EXISTS dbo.DoOperation

GO


CREATE PROCEDURE DoOperation (@Value INT)
AS
SET NOCOUNT ON;
IF @Value = 0
    RETURN 1;
ELSE IF @Value IS NULL
BEGIN
    THROW 50000, 'The @value parameter should not be
NULL', 1;
    SELECT 'Continued to here';
    RETURN -1;
END;
ELSE
    RETURN 0;



	--Executar a Procedure
DECLARE @ReturnCode int
EXECUTE @ReturnCode = DoOperation @Value = NULL;
SELECT @ReturnCode AS ReturnCode;


/*########################
# OBS: Agora com a mesma procedure altere usando RAISERROR */


go

ALTER PROCEDURE DoOperation (@Value INT)
AS
SET NOCOUNT ON;
IF @Value = 0
    RETURN 1;
ELSE IF @Value IS NULL
BEGIN
  RAISERROR ('The @value parameter should not be NULL',16,1);
    SELECT 'Continued to here';
    RETURN -1;
END;
ELSE
    RETURN 0;


DECLARE @ReturnCode int
EXECUTE @ReturnCode = DoOperation @Value = NULL;
SELECT @ReturnCode AS ReturnCode;



/*########################
# OBS: Manipulação de um erro
Handling an error
Now that we have established how to throw our own error messages, we now need to look
at how to handle an error occurring. What makes this difficult is that most errors do not
stop processing (an unhandled error from a TRIGGER object is an example of one that
ends a batch, as does executing the statement: SET XACT_ABORT ON before your
queries that may cause an error, which we discuss in the next section), so when you have a
group of modification statements running in a batch without any error handling, they keep
running. For example, consider the following table set up to allow you to easily cause an
error:


*/


--demo
CREATE TABLE Examples.ErrorTesting
(
    ErrorTestingId INT NOT NULL
        CONSTRAINT PKErrorTesting PRIMARY KEY,
    PositiveInteger INT NOT NULL
        CONSTRAINT CHKErrorTesting_PositiveInteger CHECK (PositiveInteger > 0)
);

INSERT INTO Examples.ErrorTesting
(
    ErrorTestingId,
    PositiveInteger
)
VALUES
(1, 1); --Succeed
INSERT INTO Examples.ErrorTesting
(
    ErrorTestingId,
    PositiveInteger
)
VALUES
(1, 1); --Fail PRIMARY KEY violation
INSERT INTO Examples.ErrorTesting
(
    ErrorTestingId,
    PositiveInteger
)
VALUES
(2, -1); --Fail CHECK constraint violation
INSERT INTO Examples.ErrorTesting
(
    ErrorTestingId,
    PositiveInteger
)
VALUES
(2, 2); --Succeed
SELECT *
FROM Examples.ErrorTesting;




/*########################
# OBS: Using @@ERROR to deal with errors 

A função do sistema @@ ERROR (também referida como uma variável global, porque é
prefixado com @@, embora seja tecnicamente uma função de sistema), informa o nível de erro de
a declaração anterior.
*/

GO

CREATE PROCEDURE Examples.ErrorTesting_InsertTwo
AS
SET NOCOUNT ON;
INSERT INTO Examples.ErrorTesting
(
    ErrorTestingId,
    PositiveInteger
)
VALUES
(3, 3); --Succeeds
IF @@ERROR <> 0
BEGIN
    THROW 50000, 'First statement failed', 1;
    RETURN -1;
END;
INSERT INTO Examples.ErrorTesting
(
    ErrorTestingId,
    PositiveInteger
)
VALUES
(4, -1); --Fail Constraint
IF @@ERROR <> 0
BEGIN
    THROW 50000, 'Second statement failed', 1;
    RETURN -1;
END;
INSERT INTO Examples.ErrorTesting
(
    ErrorTestingId,
    PositiveInteger
)
VALUES
(5, 1); --Will succeed if statement executes
IF @@ERROR <> 0
BEGIN
    THROW 50000, 'Third statement failed', 1;
    RETURN -1;
END;




EXECUTE Examples.ErrorTesting_InsertTwo;

/*
Msg 547, Level 16, State 0, Procedure Examples.ErrorTesting_InsertTwo, Line 17 [Batch Start Line 208]
A instrução INSERT conflitou com a restrição do CHECK "CHKErrorTesting_PositiveInteger". 
O conflito ocorreu no banco de dados "ExamBook762Ch3", tabela "Examples.ErrorTesting", column 'PositiveInteger'.
A instrução foi finalizada.
Msg 50000, Level 16, State 1, Procedure Examples.ErrorTesting_InsertTwo, Line 26 [Batch Start Line 208]
Second statement failed

*/


/*########################
# OBS: Using TRY...CATCH
*/



GO

ALTER PROCEDURE Examples.ErrorTesting_InsertTwo
AS
SET NOCOUNT ON;
DECLARE @Location NVARCHAR(30);
BEGIN TRY
    SET @Location = 'First statement';
    INSERT INTO Examples.ErrorTesting
    (
        ErrorTestingId,
        PositiveInteger
    )
    VALUES
    (6, 3); --Succeeds
    SET @Location = 'Second statement';
    INSERT INTO Examples.ErrorTesting
    (
        ErrorTestingId,
        PositiveInteger
    )
    VALUES
    (7, -1); --Fail Constraint
    SET @Location = 'First statement';
    INSERT INTO Examples.ErrorTesting
    (
        ErrorTestingId,
        PositiveInteger
    )
    VALUES
    (8, 1); --Will succeed if statement executes
END TRY
BEGIN CATCH
    SELECT ERROR_PROCEDURE() AS ErrorProcedure,
           @Location AS ErrorLocation;
    SELECT ERROR_MESSAGE() AS ErrorMessage;
    SELECT ERROR_NUMBER() AS ErrorNumber,
           ERROR_SEVERITY() AS ErrorSeverity,
           ERROR_LINE() AS ErrorLine;
    THROW;
END CATCH;

EXECUTE Examples.ErrorTesting_InsertTwo;


