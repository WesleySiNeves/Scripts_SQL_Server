SET QUOTED_IDENTIFIER ON
SET ANSI_NULLS ON
GO
--EXEC HealthCheck.ModifierPageCompression  @Limite =NULL,@FullTableName ='Financeiro.EmissoesRegistroOnline',@Compression ='PAGE'


CREATE OR ALTER   PROCEDURE HealthCheck.ModifierPageCompression
(
	@Limite DATETIME2  = NULL,
	@FullTableName VARCHAR(200) = NULL,
	@Compression VARCHAR(20) ='PAGE'

)
AS
    BEGIN
        SET XACT_ABORT ON;

		

		DECLARE @VersionStandard  BIT = IIF(CHARINDEX('Standard',@@VERSION) > 0,1,0);

        DECLARE @Data DATETIME2(2) = GETDATE();

        SELECT @Data = DATEADD(HOUR, -3, @Data);

		IF(@Limite IS NULL)
		BEGIN
		SET @Limite = DATETIME2FROMPARTS(YEAR(@Data), MONTH(@Data), DAY(DATEADD(DAY, 1, @Data)), 7, 0, 0, 0, 2);		
		END
		

        --DECLARE @HorarioPermitidoExecucaoInicial TIME = '11:00:00'
        --DECLARE @HorarioPermitidoExecucaoFinal TIME = '07:00:00'

        IF(OBJECT_ID('TEMPDB..#tabelas') IS NOT NULL)
            DROP TABLE #tabelas;

        CREATE TABLE #tabelas
        (
            [SchemaName]            NVARCHAR(128),
            [TableName]             NVARCHAR(128),
            [IndexName]             NVARCHAR(128),
            [IndexType]             TINYINT,
            [rows]                  BIGINT,
            [data_compression]      TINYINT,
            [data_compression_desc] NVARCHAR(60)
        );

        INSERT INTO #tabelas
        SELECT S.name AS SchemaName,
               T.name AS TableName,
               I.name AS IndexName,
               I.type AS IndexType,
               P.rows,
               P.data_compression,
               P.data_compression_desc
          --Script= 
          FROM sys.tables AS T
               JOIN sys.schemas AS S ON S.schema_id = T.schema_id
               JOIN sys.indexes AS I ON I.object_id = T.object_id
               JOIN sys.partitions AS P ON P.object_id = T.object_id AND P.index_id = I.index_id                                           
			   WHERE 
			   (
			   @FullTableName IS NULL
			   OR (  t.object_id = OBJECT_ID(@FullTableName))
			   )
        DECLARE @DataHoraAtual DATETIME2(2) = GETDATE();

        /* declare variables */
        DECLARE @SchemaName VARCHAR(256),
                @TableName  VARCHAR(256),
                @IndexName  VARCHAR(256),
                @IndexType  VARCHAR(256),
                @Script     NVARCHAR(1000);

        DECLARE cursor_CorrigeDataCompression_On_Table CURSOR FAST_FORWARD READ_ONLY FOR
        SELECT T.SchemaName,
               T.TableName,
               T.IndexName,
               T.IndexType,
               Script = CONCAT('ALTER TABLE ', '[', T.SchemaName, ']', '.', '[', T.TableName, ']', ' REBUILD PARTITION= ALL WITH(DATA_COMPRESSION = ',@Compression,'',IIF(@VersionStandard =1,')',', ONLINE =ON)'))
          FROM #tabelas AS T
         WHERE
            T.IndexType = 1
            AND T.data_compression_desc = 'NONE';

        OPEN cursor_CorrigeDataCompression_On_Table;

        FETCH NEXT FROM cursor_CorrigeDataCompression_On_Table
         INTO @SchemaName,
              @TableName,
              @IndexName,
              @IndexType,
              @Script;

        WHILE @@FETCH_STATUS = 0
            BEGIN
                SET @DataHoraAtual = GETDATE();
                SET @DataHoraAtual = DATEADD(HOUR, -3, @DataHoraAtual);

                IF(@DataHoraAtual < @Limite)
                    BEGIN
                        BEGIN TRY
                            /*Region Logical Querys*/
                            EXEC sys.sp_executesql @Script;

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
                        END CATCH;
                    END;

                FETCH NEXT FROM cursor_CorrigeDataCompression_On_Table
                 INTO @SchemaName,
                      @TableName,
                      @IndexName,
                      @IndexType,
                      @Script;
            END;

        CLOSE cursor_CorrigeDataCompression_On_Table;
        DEALLOCATE cursor_CorrigeDataCompression_On_Table;

        DECLARE cursor_CorrigeDataCompression_On_Indexs CURSOR FAST_FORWARD READ_ONLY FOR
        SELECT T.SchemaName,
               T.TableName,
               T.IndexName,
               T.IndexType,
               Script = CONCAT('ALTER INDEX ', '[', T.IndexName, '] ON ', '[', T.SchemaName, ']', '.', '[', T.TableName, ']',   ' REBUILD PARTITION= ALL WITH(DATA_COMPRESSION = ',@Compression,'',IIF(@VersionStandard =1,')',', ONLINE =ON)'))
          FROM #tabelas AS T
         WHERE
            T.IndexType = 2
            AND T.data_compression_desc = 'NONE';

        OPEN cursor_CorrigeDataCompression_On_Indexs;

        FETCH NEXT FROM cursor_CorrigeDataCompression_On_Indexs
         INTO @SchemaName,
              @TableName,
              @IndexName,
              @IndexType,
              @Script;

        WHILE @@FETCH_STATUS = 0
            BEGIN
                SET @DataHoraAtual = GETDATE();
                SET @DataHoraAtual = DATEADD(HOUR, -3, @DataHoraAtual);

                IF(@DataHoraAtual < @Limite)
                    BEGIN
                        BEGIN TRY
                            /*Region Logical Querys*/
                            EXEC sys.sp_executesql @Script;

                        /*End region */
                        END TRY
                        BEGIN CATCH
                            DECLARE @ErrorNumber_ INT = ERROR_NUMBER();
                            DECLARE @ErrorLine_ INT = ERROR_LINE();
                            DECLARE @ErrorMessage_ NVARCHAR(4000) = ERROR_MESSAGE();
                            DECLARE @ErrorSeverity_ INT = ERROR_SEVERITY();
                            DECLARE @ErrorState_ INT = ERROR_STATE();

                            PRINT 'Actual error number: ' + CAST(@ErrorNumber_ AS VARCHAR(MAX));
                            PRINT 'Actual line number: ' + CAST(@ErrorLine_ AS VARCHAR(MAX));
                            PRINT '@ErrorMessage: ' + CAST(@ErrorMessage_ AS VARCHAR(MAX));
                            PRINT '@ErrorSeverity: ' + CAST(@ErrorLine_ AS VARCHAR(MAX));
                            PRINT '@ErrorState: ' + CAST(@ErrorLine_ AS VARCHAR(MAX));

                            RAISERROR(@ErrorMessage_, @ErrorSeverity_, @ErrorState_);
                        END CATCH;
                    END;

                FETCH NEXT FROM cursor_CorrigeDataCompression_On_Indexs
                 INTO @SchemaName,
                      @TableName,
                      @IndexName,
                      @IndexType,
                      @Script;
            END;

        CLOSE cursor_CorrigeDataCompression_On_Indexs;
        DEALLOCATE cursor_CorrigeDataCompression_On_Indexs;
    END;
GO