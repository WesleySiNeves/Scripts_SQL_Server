/*########################
# OBS: Faça isso usando a instrução BEGIN TRANSACTION para iniciar um
transação e COMMIT TRANSACTION para salvar as alterações, ou ROLLBACK
TRANSACÇÃO para desfazer as alterações que foram feitas
*/


BEGIN TRANSACTION;
BEGIN TRANSACTION;


SELECT @@TRANCOUNT

--COMMIT

/*########################
# OBS:parte 2
*/

BEGIN TRANSACTION;
INSERT INTO Examples.ErrorTesting
(
    ErrorTestingId,
    PositiveInteger
)
VALUES
(9, 1);
BEGIN TRANSACTION;
SELECT *
FROM Examples.ErrorTesting
WHERE ErrorTestingId = 9;



/*########################
# OBS:parte 3
(XACT_ABORT é uma opção SET que termina o lote em uma transação
*/



/*########################
# Inicio da Demo
*/

CREATE TABLE Examples.Worker
(
    WorkerId INT NOT NULL IDENTITY(1, 1)
        CONSTRAINT PKWorker PRIMARY KEY,
    WorkerName NVARCHAR(50) NOT NULL
        CONSTRAINT AKWorker
        UNIQUE
);
CREATE TABLE Examples.WorkerAssignment
(
    WorkerAssignmentId INT IDENTITY(1, 1)
        CONSTRAINT PKWorkerAssignment PRIMARY KEY,
    WorkerId INT NOT NULL,
    CompanyName NVARCHAR(50) NOT NULL
        CONSTRAINT CHKWorkerAssignment_CompanyName CHECK (CompanyName <> 'Contoso, Ltd.'),
    CONSTRAINT AKWorkerAssignment
        UNIQUE
        (
            WorkerId,
            CompanyName
        )
);


--Usando Try Cath para manipular a procedure

GO
CREATE PROCEDURE Examples.Worker_AddWithAssignment
    @WorkerName NVARCHAR(50),
    @CompanyName NVARCHAR(50)
AS
SET NOCOUNT ON;
--do any non-data testing before starting the transaction
IF @WorkerName IS NULL
   OR @CompanyName IS NULL
    THROW 50000, 'Both parameters must be not null', 1;
DECLARE @Location NVARCHAR(30),
        @NewWorkerId INT;
BEGIN TRY
    BEGIN TRANSACTION;
    SET @Location = 'Creating Worker Row';
    INSERT INTO Examples.Worker
    (
        WorkerName
    )
    VALUES (@WorkerName);
    SELECT @NewWorkerId = SCOPE_IDENTITY(),
           @Location = 'Creating WorkAssignment Row';
    INSERT INTO Examples.WorkerAssignment
    (
        WorkerId,
        CompanyName
    )
    VALUES
    (@NewWorkerId, @CompanyName);
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    --at the end of the call, we want the transaction rolled back
    --rollback the transaction first, so it definitely occurs as the THROW
    --statement would keep it from happening.
    IF XACT_STATE() <> 0 --if there is a transaction in effect
        --commitable or not
        ROLLBACK TRANSACTION;

    --format a message that tells the error and then THROW it.
    DECLARE @ErrorMessage NVARCHAR(4000);
    SET @ErrorMessage
        = CONCAT('Error occurred during:''', @Location, '''', ' System Error: ', ERROR_NUMBER(), ':', ERROR_MESSAGE());
    THROW 50000, @ErrorMessage, 1;
END CATCH;


--Executar a procedure


EXEC Examples.Worker_AddWithAssignment @WorkerName = NULL,
@CompanyName = NULL;



EXEC Examples.Worker_AddWithAssignment
@WorkerName='David So',
@CompanyName='Margie''s Travel';


EXEC Examples.Worker_AddWithAssignment
@WorkerName='David So',
@CompanyName='Margie''s Travel';

/*

Msg 50000, Level 16, State 1, Procedure Examples.Worker_AddWithAssignment, 
Line 43 [Batch Start Line 130]
Error occurred during:'Creating Worker Row' System Error: 2627:
Violação da restrição UNIQUE KEY 'AKWorker'. 
Não é possível inserir a chave duplicada no objeto 'Examples.Worker'.

 O valor de chave duplicada é (David So).

*/


EXEC Examples.Worker_AddWithAssignment
@WorkerName='Ian Palangio',
@CompanyName='Humongous Insurance'


--Usando  Procedure to show realistic error checking with @@ERROR

go
ALTER PROCEDURE Examples.Worker_AddWithAssignment
    @WorkerName NVARCHAR(50),
    @CompanyName NVARCHAR(50)
AS
SET NOCOUNT ON;
DECLARE @NewWorkerId INT;
--still check the parameter values first
IF @WorkerName IS NULL
   OR @CompanyName IS NULL
    THROW 50000, 'Both parameters must be not null', 1;

--Start a transaction
BEGIN TRANSACTION;
INSERT INTO Examples.Worker
(
    WorkerName
)
VALUES (@WorkerName);
--check the value of the @@error system function
IF @@ERROR <> 0
BEGIN
    --rollback the transaction before the THROW (or RETURN if using), because
    --otherwise the THROW will end the batch and transaction stay open
    ROLLBACK TRANSACTION;
    THROW 50000, 'Error occurred inserting data into
Examples.Worker table', 1;
END;
SELECT @NewWorkerId = SCOPE_IDENTITY();
INSERT INTO Examples.WorkerAssignment
(
    WorkerId,
    CompanyName
)
VALUES
(@NewWorkerId, @CompanyName);
IF @@ERROR <> 0
BEGIN
    ROLLBACK TRANSACTION;
    THROW 50000, 'Error occurred inserting data into
Examples.WorkerAssignment table', 1;
END;
--if you get this far in the batch, you can commit the transaction
COMMIT TRANSACTION;