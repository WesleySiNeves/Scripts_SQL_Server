

/* ==================================================================
--Data: 03/09/2018 
--Autor :Wesley Neves
--Observação: https://docs.microsoft.com/pt-br/sql/relational-databases/indexes/reorganize-and-rebuild-indexes?view=sql-server-2017
-- :
 Valor avg_fragmentation_in_percent	Instrução corretiva
> 5% e < = 30%	ALTER INDEX REORGANIZE
> 30%	ALTER INDEX REBUILD WITH (ONLINE = ON) 1
 
 --Temos tambem uma solução do Tiger Team 
 disposta em https://github.com/Microsoft/tigertoolbox/tree/master/AdaptiveIndexDefrag
-- ==================================================================
*/
IF ( OBJECT_ID('TEMPDB..#DadosIndices') IS NOT NULL )
    DROP TABLE #DadosIndices;	

CREATE TABLE #DadosIndices
    (
      objectid INT NOT NULL,
      indexid INT NOT NULL ,
      partitionnum INT NOT NULL ,
      frag NUMERIC(18, 2) NOT NULL 
      
    );


-- Ensure a USE <databasename> statement has been executed first.  
SET NOCOUNT ON;
DECLARE @objectid INT;
DECLARE @indexid INT;
DECLARE @partitioncount BIGINT;
DECLARE @schemaname NVARCHAR(130);
DECLARE @objectname NVARCHAR(130);
DECLARE @indexname NVARCHAR(130);
DECLARE @partitionnum BIGINT;
DECLARE @partitions BIGINT;
DECLARE @frag FLOAT;
DECLARE @command NVARCHAR(4000);

INSERT INTO #DadosIndices
-- Conditionally select tables and indexes from the sys.dm_db_index_physical_stats function   
-- and convert object and index IDs to names.  
SELECT dm_db_index_physical_stats.object_id AS objectid,
       dm_db_index_physical_stats.index_id AS indexid,
       dm_db_index_physical_stats.partition_number AS partitionnum,
       dm_db_index_physical_stats.avg_fragmentation_in_percent AS frag

FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, 'DETAILED')
WHERE dm_db_index_physical_stats.avg_fragmentation_in_percent > 5.0
      AND dm_db_index_physical_stats.index_id > 0;


	  


-- Declare the cursor for the list of partitions to be processed.  
DECLARE partitions CURSOR FOR SELECT * FROM #DadosIndices AS DI;

-- Open the cursor.  
OPEN partitions;

-- Loop through the partitions.  
WHILE (1 = 1)
BEGIN;
    FETCH NEXT FROM partitions
    INTO @objectid,
         @indexid,
         @partitionnum,
         @frag;
    IF @@FETCH_STATUS < 0
        BREAK;
    SELECT @objectname = QUOTENAME(o.name),
           @schemaname = QUOTENAME(s.name)
    FROM sys.objects AS o
         JOIN
         sys.schemas AS s ON s.schema_id = o.schema_id
    WHERE o.object_id = @objectid;
    SELECT @indexname = QUOTENAME(indexes.name)
    FROM sys.indexes
    WHERE indexes.object_id = @objectid
          AND indexes.index_id = @indexid;
    SELECT @partitioncount = COUNT(*)
    FROM sys.partitions
    WHERE partitions.object_id = @objectid
          AND partitions.index_id = @indexid;

    -- 30 is an arbitrary decision point at which to switch between reorganizing and rebuilding.  
    IF @frag < 30.0
        SET @command = N'ALTER INDEX ' + @indexname + N' ON ' + @schemaname + N'.' + @objectname + N' REORGANIZE';
    IF @frag >= 30.0
        SET @command = N'ALTER INDEX ' + @indexname + N' ON ' + @schemaname + N'.' + @objectname + N' REBUILD';
    IF @partitioncount > 1
        SET @command = @command + N' PARTITION=' + CAST(@partitionnum AS NVARCHAR(10));
    SELECT (@command);
    PRINT N'Executed: ' + @command;
END;

-- Close and deallocate the cursor.  
CLOSE partitions;
DEALLOCATE partitions;

