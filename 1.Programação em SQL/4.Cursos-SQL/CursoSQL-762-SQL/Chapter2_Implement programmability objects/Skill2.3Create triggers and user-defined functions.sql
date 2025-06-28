USE ExamBook762Ch3;
GO


/*########################
# OBS: Criando trigger para faze validação de integridade complexa
*/



DROP TABLE IF EXISTS Examples.AccountContact;

CREATE TABLE Examples.AccountContact
(
    AccountContactId INT NOT NULL
        CONSTRAINT PKAccountContact PRIMARY KEY,
    AccountId CHAR(4) NOT NULL,
    PrimaryContactFlag BIT NOT NULL
);


/*########################
# OBS: 
Você recebe o requisito de negócios para garantir que sempre haja um contato primário para
uma conta, se um contato existir. Um primeiro passo é identificar a consulta que mostra as linhas
que não correspondem a esta regra. Nesse caso
*/
SELECT AccountId,
       SUM(   CASE
                  WHEN PrimaryContactFlag = 1 THEN
                      1
                  ELSE
                      0
              END
          )
FROM Examples.AccountContact
GROUP BY AccountId
HAVING SUM(   CASE
                  WHEN PrimaryContactFlag = 1 THEN
                      1
                  ELSE
                      0
              END
          ) <> 1;


/*########################
# OBS: Se essa consulta retornar dados, então você sabe que algo está errado.
*/

GO
CREATE TRIGGER Examples.AccountContact_TriggerAfterInsertUpdate
ON Examples.AccountContact
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    SET ROWCOUNT 0; --in case the client has modified the rowcount
    BEGIN TRY
        --check to see if data is returned by the query from previously
        IF EXISTS
        (
            SELECT AccountId
            FROM Examples.AccountContact
            --correlates the changed rows in inserted to the other rows
            --for the account, so we can check if the rows have changed
            WHERE EXISTS
            (
                SELECT 
                       Inserted.AccountId
                FROM inserted
                WHERE inserted.AccountId = AccountContact.AccountId
                UNION ALL
                SELECT 
                       Deleted.AccountId
                FROM deleted
                WHERE deleted.AccountId = AccountContact.AccountId
                GROUP BY AccountId
                HAVING SUM(   CASE
                                  WHEN PrimaryContactFlag = 1 THEN
                                      1
                                  ELSE
                                      0
                              END
                          ) <> 1
            )
        )
            THROW 50000, 'Account(s) do not have only one primary contact.', 1;

    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;




--Success, 1 row
INSERT INTO Examples.AccountContact
(
    AccountContactId,
    AccountId,
    PrimaryContactFlag
)
VALUES
(1, 1, 1);
--Success, two rows
INSERT INTO Examples.AccountContact
(
    AccountContactId,
    AccountId,
    PrimaryContactFlag
)
VALUES
(2, 2, 1),
(3, 3, 1);
--Two rows, same account
INSERT INTO Examples.AccountContact
(
    AccountContactId,
    AccountId,
    PrimaryContactFlag
)
VALUES
(4, 4, 1),
(5, 4, 0);
--Invalid, two accounts with primary
INSERT INTO Examples.AccountContact
(
    AccountContactId,
    AccountId,
    PrimaryContactFlag
)
VALUES
(6, 5, 1),
(7, 5, 1);



/*########################
# OBS: Trigger de Deletes
*/


GO

CREATE TRIGGER Examples.AccountContact_TriggerAfterDelete
ON Examples.AccountContact
AFTER DELETE
AS
BEGIN
    SET NOCOUNT ON;
    SET ROWCOUNT 0; --in case the client has modified the rowcount
    BEGIN TRY
        IF EXISTS
        (
            SELECT AccountId
            FROM Examples.AccountContact
            WHERE EXISTS
            (
                SELECT *
                FROM deleted
                WHERE deleted.AccountId = AccountContact.AccountId
            )
            GROUP BY AccountId
            HAVING SUM(   CASE
                              WHEN PrimaryContactFlag = 1 THEN
                                  1
                              ELSE
                                  0
                          END
                      ) > 1
        )
            THROW 50000, 'One or more Accounts did not have one
primary contact.', 1;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;