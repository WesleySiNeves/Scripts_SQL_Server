


--EXEC [dbo].[usp_DeleteOldBackupFiles] @path='D:\TempSQLServerBackup\Logs\crm-sp.implanta.net.br' ,@extension='.trn', @age_hrs =3

CREATE OR ALTER PROCEDURE [dbo].[usp_DeleteOldBackupFiles]
    @path      NVARCHAR(256),
    @extension NVARCHAR(10),
    @age_hrs   INT
AS
    BEGIN
        SET NOCOUNT ON;

        DECLARE @DeleteDate NVARCHAR(50);
        DECLARE @DeleteDateTime DATETIME;

        SET @DeleteDateTime = DATEADD(hh, -@age_hrs, GETDATE());
        SET @DeleteDate = (
                              SELECT REPLACE(CONVERT(NVARCHAR, @DeleteDateTime, 111), '/', '-') + 'T' + CONVERT(NVARCHAR, @DeleteDateTime, 108)
                          );

			PRINT(CONCAT(' master.dbo.xp_delete_file 0 ', @path,' ', @extension,' ', @DeleteDate,' ', 1,';'));

        --EXECUTE master.dbo.xp_delete_file 0, @path, @extension, @DeleteDate, 1;
    END;