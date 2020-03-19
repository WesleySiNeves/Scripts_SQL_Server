USE ExamBook762Ch2


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

--Codigo da trigger

-- ==================================================================
--Observação:Essa trigger (AFTER)  ela roda apos apos o insert 
/*
 */
-- ==================================================================
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
        IF EXISTS (   SELECT AccountContact.AccountId
                        FROM Examples.AccountContact --correlates the changed rows in inserted to the other rows
                       --for the account, so we can check if the rows have changed
                       WHERE EXISTS (   SELECT *
                                          FROM inserted
                                         WHERE Inserted.AccountId = AccountContact.AccountId
                                        UNION ALL
                                        SELECT *
                                          FROM deleted
                                         WHERE Deleted.AccountId = AccountContact.AccountId)
                       GROUP BY AccountContact.AccountId
                      HAVING SUM(CASE
                                      WHEN AccountContact.PrimaryContactFlag = 1 THEN 1
                                      ELSE 0 END) <> 1)
            THROW 50000, 'Account(s) do not have only one
primary contact.', 1;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;

INSERT INTO Examples.AccountContact (AccountContactId,
                                     AccountId,
                                     PrimaryContactFlag)
VALUES (1, 1, 1);
--Success, two rows
INSERT INTO Examples.AccountContact (AccountContactId,
                                     AccountId,
                                     PrimaryContactFlag)
VALUES (2, 2, 1),
(3, 3, 1);
--Two rows, same account
INSERT INTO Examples.AccountContact (AccountContactId,
                                     AccountId,
                                     PrimaryContactFlag)
VALUES (4, 4, 1),
(5, 4, 0);
--Invalid, two accounts with primary
INSERT INTO Examples.AccountContact (AccountContactId,
                                     AccountId,
                                     PrimaryContactFlag)
VALUES (6, 5, 1),
(7, 5, 1);

INSERT INTO Examples.AccountContact (AccountContactId,
                                     AccountId,
                                     PrimaryContactFlag)
VALUES (9, 5, 1);




-- ==================================================================
--Observação: Running code in response to some action
-- ==================================================================



/*
ão importa a organização de caridade, existem alguns níveis de promessas que podem ser recebidas. Para
simplicidade, vamos definir dois: Normal e Extranormal. Uma promessa normal está em um típico
alcance que uma pessoa promete se eles são normais e sinceros. As promessas externas são
fora da Normal e precisa de verificação. Promessas extra-normais para este cenário são
aqueles com mais de US $ 10.000,00. Os requisitos são criar um registro de promessas para verificar quando
as linhas são criadas ou atualizadas.
*/

GO

CREATE TABLE Examples.Promise
(
PromiseId int NOT NULL CONSTRAINT PKPromise PRIMARY KEY,
PromiseAmount money NOT NULL
);

DROP TABLE IF EXISTS Examples.VerifyPromise

CREATE TABLE Examples.VerifyPromise (VerifyPromiseId INT NOT NULL
                                         CONSTRAINT PKVerifyPromise PRIMARY KEY,
PromiseId int NOT NULL CONSTRAINT AKVerifyPromise UNIQUE
--FK not included for simplicity
);


--Codigo da trigger
GO

CREATE TRIGGER Examples.Promise_TriggerInsertUpdate
ON Examples.Promise
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    SET ROWCOUNT 0; --in case the client has modified the rowcount
    BEGIN TRY
        INSERT INTO Examples.VerifyPromise (PromiseId)
        SELECT Inserted.PromiseId
          FROM inserted
         WHERE Inserted.PromiseAmount > 10000.00
           AND NOT EXISTS (   SELECT * --keep from inserting duplicates
                                FROM Examples.VerifyPromise
                               WHERE VerifyPromise.PromiseId = Inserted.PromiseId);
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
            ROLLBACK TRANSACTION;
        THROW; --will halt the batch or be caught by the caller's catch block
    END CATCH;
END;

GO
-- ==================================================================
--Observação: Ensuring columnar data is modified

-- ==================================================================


/*
Neste exemplo, utilizamos objetos INSTEAD OF TRIGGER, que são excelentes
ferramentas para garantir que alguma operação ocorra em uma declaração. Por exemplo, se você quiser
Certifique-se de que uma coluna lhe diga quando uma linha foi modificada pela última vez, um INSTEAD OF
O objeto TRIGGER pode ser usado para determinar se o usuário insere dados que não fazem sentido.
*/

/*Demo */
CREATE TABLE Examples.Lamp (
    LampId INT IDENTITY(1, 1) CONSTRAINT PKLamp PRIMARY KEY,
    Value VARCHAR(10) NOT NULL,
    RowCreatedTime DATETIME2(0) NOT NULL CONSTRAINT DFLTLamp_RowCreatedTime DEFAULT (SYSDATETIME()),
    RowLastModifiedTime DATETIME2(0) NOT NULL CONSTRAINT DFLTLamp_RowLastModifiedTime DEFAULT (SYSDATETIME())
	);


/*
Enquanto especificamos uma restrição DEFAULT, o usuário pode colocar qualquer coisa na tabela.
Em vez disso, vamos usar dois objetos TRIGGER. O primeiro é um INSTEAD OF INSERT TRIGGER
*/

GO
CREATE TRIGGER Examples.Lamp_TriggerInsteadOfInsert
ON Examples.Lamp
INSTEAD OF INSERT --No Momento da inserção
AS
BEGIN
    SET NOCOUNT ON;
    SET ROWCOUNT 0; --in case the client has modified the rowcount
    BEGIN TRY
        --skip columns to automatically set
        INSERT INTO Examples.Lamp (Value)
        SELECT Inserted.Value
          FROM inserted;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
            ROLLBACK TRANSACTION;
        THROW; --will halt the batch or be caught by the caller's catch block
    END CATCH;
END;

/*
Você só pode ter uma trigger INSTEAD OF por tabela. Enquanto
Você pode ter um objeto INSTEAD OF TRIGGER que faça múltiplos
operações, como INSERT, UPDATE e DELETE, normalmente não é tão útil
como pode ser para objetos APÓS TRIGGER. Um caso de uso é fazer um gatilho
não faça a operação real
*/

INSERT INTO Examples.Lamp(Value, RowCreatedTime,
RowLastModifiedTime) VALUES ('Original','1900-01-01','1900-01-01');

SELECT *
FROM Examples.Lamp;


/*
Em seguida, crie o INSTEAD OF UPDATE TRIGGER que garante que o
RowLastModifiedTime é modificado e o RowCreatedTime nunca foi modificado
*/

GO

CREATE TRIGGER Examples.Lamp_TriggerInsteadOfUpdate
ON Examples.Lamp
INSTEAD OF UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    SET ROWCOUNT 0; --in case the client has modified the rowcount
    BEGIN TRY
        UPDATE Lamp
           SET Lamp.Value = Inserted.Value,
               Lamp.RowLastModifiedTime = DEFAULT --use default constraint
          FROM Examples.Lamp
          JOIN inserted
            ON Lamp.LampId = Inserted.LampId;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
            ROLLBACK TRANSACTION;
        THROW; --will halt the batch or be caught by the caller's catch block
    END CATCH;
END;

--Veja o resultado desse UPDATE

UPDATE Examples.Lamp
   SET Lamp.Value = 'Modified',
       Lamp.RowCreatedTime = '1900-01-01',
       Lamp.RowLastModifiedTime = '1900-01-01'
 WHERE Lamp.LampId = 1;
SELECT *
FROM Examples.Lamp;