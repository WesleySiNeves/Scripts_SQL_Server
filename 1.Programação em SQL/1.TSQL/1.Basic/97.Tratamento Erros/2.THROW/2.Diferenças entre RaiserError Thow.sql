DECLARE @inicio INT = 0;
DECLARE @Termino INT = 100;

THROW 50000, 'This is an error message', 1;
SELECT 'Batch continued';
WHILE (@inicio <= @Termino)
BEGIN
    PRINT @inicio;

    SELECT @inicio += 1;
END;



RAISERROR('This is an error message', 16, 1);
SELECT 'Batch continued';
DECLARE @inicio INT = 0;
DECLARE @Termino INT = 100;

WHILE (@inicio <= @Termino)
BEGIN
    PRINT @inicio;

    SELECT @inicio += 1;
END;