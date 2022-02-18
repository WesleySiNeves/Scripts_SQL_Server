/* ==================================================================
Observação: Essa parte NÃO deve ser removida
 ==================================================================
*/
IF(EXISTS( SELECT * FROM  sys.procedures AS P
WHERE P.name ='DeleteUserStats'))
BEGIN
		
		EXEC HealthCheck.DeleteUserStats
END



CREATE OR ALTER PROCEDURE HealthCheck.DeleteUserStats
AS
    BEGIN
        SET XACT_ABORT ON;

        BEGIN TRY
            /*Region Logical Querys*/

            DECLARE @Script NVARCHAR(2000);

            DECLARE cursor_DeletaStatisticas CURSOR FAST_FORWARD READ_ONLY FOR
            SELECT DISTINCT 'DROP STATISTICS ' + SCHEMA_NAME(ob.schema_id) + '.' + OBJECT_NAME(s.object_id) + '.' + s.name DropStatisticsStatement
              FROM sys.stats s
                   INNER JOIN sys.objects ob ON ob.object_id = s.object_id
             WHERE
                SCHEMA_NAME(ob.schema_id) <> 'sys'
                AND auto_created = 0
                AND user_created = 1;

            OPEN cursor_DeletaStatisticas;

            FETCH NEXT FROM cursor_DeletaStatisticas
             INTO @Script;

            WHILE @@FETCH_STATUS = 0
                BEGIN
                    PRINT @Script;

                    EXEC sp_executesql @Script;

                    FETCH NEXT FROM cursor_DeletaStatisticas
                     INTO @Script;
                END;

            CLOSE cursor_DeletaStatisticas;
            DEALLOCATE cursor_DeletaStatisticas;
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
        END CATCH;
    END;
