--Procedure Simples
CREATE PROCEDURE SimpleReturnValue
AS
DECLARE @NoOp INT;


--Execute o trecho abaixo para ver que a Sp so retorna 0
DECLARE @ReturnCode INT;
EXECUTE @ReturnCode = SimpleReturnValue;
SELECT @ReturnCode AS ReturnCode;

/*########################
# OBS: Vc pode alterar isso colocando o comando Return na procedure
*/

GO
CREATE PROCEDURE DoOperation (@Value INT) --Procedure returns via return code:
-- 1 - successful execution, with 0 entered
-- 0 - successful execution
-- -1 - invalid, NULL input
AS
IF @Value = 0
    RETURN 1;
ELSE IF @Value IS NULL
    RETURN -1;
ELSE
    RETURN 0;


DECLARE @ReturnCode INT;
EXECUTE @ReturnCode = DoOperation @Value = NULL;
SELECT @ReturnCode,
       CASE @ReturnCode
           WHEN 1 THEN
               'Success, 0 Entered'
           WHEN-1 THEN
               'Invalid Input'
           WHEN 0 THEN
               'Success'
       END AS ReturnMeaning;