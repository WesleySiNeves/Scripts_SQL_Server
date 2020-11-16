----Incremental Shrink for data file - Azure SQL
--************************************************/
SET NOCOUNT ON;

DECLARE @CurrentFileSize INT;
DECLARE @DesiredFileSize INT;
DECLARE @ShrinkChunkSize INT;
DECLARE @ActualSizeMB INT;
DECLARE @ErrorIndication INT;
DECLARE @dbFileID INT = 1;
DECLARE @lastSize INT;
DECLARE @SqlCMD NVARCHAR(MAX);
DECLARE @MSG NVARCHAR(100);

/*set this values for the current operation, size is in MB*/
SET @DesiredFileSize = 45765;
SET @ShrinkChunkSize = 50;


PRINT(CONCAT('Decreasing for :',(@DesiredFileSize / 1024 ), ' GB'));



SELECT @CurrentFileSize = size / 128
  FROM sysfiles
 WHERE
    fileid = @dbFileID;


SELECT @ActualSizeMB = (SUM(total_pages) / 128)FROM sys.allocation_units;



SET @MSG = 'Current File Size: ' + CAST(@CurrentFileSize AS VARCHAR(10)) + 'MB';

RAISERROR(@MSG, 0, 0)WITH NOWAIT;

SET @MSG = 'Actual used Size: ' + CAST(@ActualSizeMB AS VARCHAR(10)) + 'MB';

RAISERROR(@MSG, 0, 0)WITH NOWAIT;

SET @MSG = 'Desired File Size: ' + CAST(@DesiredFileSize AS VARCHAR(10)) + 'MB';

RAISERROR(@MSG, 0, 0)WITH NOWAIT;

SET @MSG = 'Interation shrink size: ' + CAST(@ShrinkChunkSize AS VARCHAR(10)) + 'MB';

RAISERROR(@MSG, 0, 0)WITH NOWAIT;



SET @ErrorIndication = CASE WHEN @DesiredFileSize > @CurrentFileSize THEN 1
                       WHEN @ActualSizeMB > @DesiredFileSize THEN 2 ELSE 0 END;

-- check if there is paused resumable index operation on this DB
-- existance of these types of operations block the shrink operation from reducing the file size
IF(
      SELECT COUNT(*)FROM sys.index_resumable_operations
  ) > 0
    SET @ErrorIndication = 3;



IF @ErrorIndication = 1
    RAISERROR('[Error] Desired size bigger than current size', 16, 0)WITH NOWAIT;

IF @ErrorIndication = 2
    RAISERROR('[Error] Actual size is bigger then desired size', 16, 0)WITH NOWAIT;

IF @ErrorIndication = 3
    RAISERROR('[Error] Paused resumable index rebuild was detected, please abort or complete the operation before running shrink', 16, 0)WITH NOWAIT;

IF @ErrorIndication = 0
    RAISERROR('Desired Size check - OK', 0, 0)WITH NOWAIT;

SET @lastSize = @CurrentFileSize + 1;

WHILE @CurrentFileSize > @DesiredFileSize /*check if we got the desired size*/
      AND @lastSize > @CurrentFileSize /* check if there is progress*/
      AND @ErrorIndication = 0
    BEGIN
        SET @MSG = CAST(GETDATE() AS VARCHAR(100)) + ' - Iteration starting';

        RAISERROR(@MSG, 0, 0)WITH NOWAIT;

        SELECT @lastSize = size / 128 FROM sysfiles WHERE fileid = @dbFileID;

        SET @SqlCMD = 'dbcc shrinkfile(' + CAST(@dbFileID AS VARCHAR(7)) + ',' + CAST(@CurrentFileSize - @ShrinkChunkSize AS VARCHAR(7)) + ') with no_infomsgs;';

		PRINT(@SqlCMD)
        EXEC(@SqlCMD);

        SELECT @CurrentFileSize = size / 128
          FROM sysfiles
         WHERE
            fileid = @dbFileID;

        SET @MSG = CAST(GETDATE() AS VARCHAR(100)) + ' - Iteration completed. current size is: ' + CAST(@CurrentFileSize AS VARCHAR(10));

        RAISERROR(@MSG, 0, 0)WITH NOWAIT;
    END;

PRINT 'Done';