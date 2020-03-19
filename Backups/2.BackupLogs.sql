CREATE PROCEDURE HealthCheck.uspExecBackup (
                                           @DbName    VARCHAR(128),
                                           @diretorio VARCHAR(300),
                                           @Tipo      VARCHAR(10) = 'FULL'
                                           )
AS
BEGIN

    DECLARE @comand VARCHAR(MAX);


    BEGIN TRY
        /*Region Logical Querys*/

        DECLARE @fullDiretorio VARCHAR(MAX);

        SET @fullDiretorio
            = CONCAT(
                        @diretorio,
                        '/',
                        CONCAT(CONCAT(@DbName, ' ', FORMAT(GETDATE(), 'dd-MM-yyyy HH:ss:mm', 'Pt-Br')), '.Bak')
                    );

        IF (@Tipo = 'FULL')
        BEGIN
            SET @comand = CONCAT('BACKUP DATABASE ', @DbName, 'TO DISK = ', @fullDiretorio);
        END;
        IF (@Tipo = 'LOG')
        BEGIN
            SET @comand = CONCAT('BACKUP LOG ', @DbName, 'TO DISK = ', @fullDiretorio);
        END;


        PRINT (@comand);
        EXEC (@comand);



    /*End region */


    END TRY
    BEGIN CATCH


        DECLARE @ErrorNumber INT = ERROR_NUMBER();
        DECLARE @ErrorLine INT = ERROR_LINE();
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();

        PRINT 'Actual error number: ' + CAST(@ErrorNumber AS VARCHAR(MAX));
        PRINT 'Actual line number: ' + CAST(@ErrorLine AS VARCHAR(MAX));
        PRINT '@ErrorMessage: ' + CAST(@ErrorMessage AS VARCHAR(MAX));
        PRINT '@ErrorSeverity: ' + CAST(@ErrorLine AS VARCHAR(MAX));
        PRINT '@ErrorState: ' + CAST(@ErrorLine AS VARCHAR(MAX));
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);


        PRINT 'Error detected, all changes reversed.';
    END CATCH;

END;
