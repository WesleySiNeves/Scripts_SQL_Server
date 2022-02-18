CREATE TRIGGER Examples.AccountContact_TriggerAfterInsertUpdate
ON Examples.AccountContact
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    SET ROWCOUNT 0; --in case the client has modified the rowcount
    BEGIN TRY
        --check to see if data is returned by the query from previously
        IF EXISTS (   SELECT AccountId
                        FROM Examples.AccountContact
                       --correlates the changed rows in inserted to the other rows
                       --for the account, so we can check if the rows have changed
                       WHERE EXISTS (   SELECT *
                                          FROM inserted
                                         WHERE inserted.AccountId = AccountContact.AccountId
                                        UNION ALL
                                        SELECT *
                                          FROM deleted
                                         WHERE deleted.AccountId = AccountContact.AccountId)
                       GROUP BY AccountId
                      HAVING SUM(CASE
                                      WHEN PrimaryContactFlag = 1 THEN 1
                                      ELSE 0 END) <> 1)
            THROW 50000, 'Account(s) do not have only one primary contact.', 1;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;


