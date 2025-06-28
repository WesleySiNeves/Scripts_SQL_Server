USE ExamBook762Ch2;

GO

ALTER TRIGGER tgDMLOnCreateUpdateTable
ON DATABASE
FOR CREATE_TABLE, ALTER_TABLE
AS
BEGIN


    DECLARE @NomesNaoPermitidos AS TABLE (nome VARCHAR(128));
    DECLARE @ObjectName VARCHAR(128);


    INSERT INTO @NomesNaoPermitidos (nome)
    VALUES ('Temp' -- nome - varchar(128)
        );

    SELECT @ObjectName = EVENTDATA().value('(/EVENT_INSTANCE/ObjectName)[1]', 'nvarchar(128)');

    IF (EXISTS (   SELECT 1
                     FROM @NomesNaoPermitidos AS NNP
                    WHERE NNP.nome = @ObjectName))
    BEGIN

        RAISERROR('Nome da tabela não permitido',16,1);
		ROLLBACK;
    END;
    ELSE
        SELECT @ObjectName;
END;
