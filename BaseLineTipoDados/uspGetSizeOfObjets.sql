/****** Object:  StoredProcedure [HealthCheck].[uspGetSizeOfObjets2]    Script Date: 04/12/2018 11:16:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE [HealthCheck].[uspGetSizeOfObjets] --- 2003/05/19 14:00
@objname nvarchar(776) = null,		-- The object we want size on.
@updateusage varchar(5) = false,	-- Param. for specifying that usage info. should be updated.
@mode varchar(11) = 'ALL',			-- Param. for specifying whether to calculate space usage for
									-- local data only or remote data archive only or both.
@oneresultset bit = 0,				-- Param. for specifying whether to return only one result set.
@include_total_xtp_storage bit = 0  -- Param. for specifying whether to include xtp storage columns 
									-- for one result set.
as

declare @id	int			-- The object id that takes up space
		,@type	character(2) -- The object type.
		,@pages	bigint			-- Working variable for size calc.
		,@dbname sysname
		,@dbsize bigint
		,@logsize bigint
		,@reservedpages  bigint
		,@usedpages  bigint
		,@rowCount bigint
		,@remotesql nvarchar(1000)
		,@isupdateusage bit
		,@errormessage nvarchar(4000)
		,@errornumber int
		,@errorseverity int
		,@errorstate int
		,@errorline int
		,@ckptfilesize bigint
		,@xtpprecreated bigint
		,@xtpused bigint
		,@xtppendingtruncation bigint
		,@memoryoptimizeddatafg bit
		,@ismemoryoptimizedtable bit
		,@remotecolsegmentspages bigint
		,@remotecoldictionariespages bigint;

DECLARE @summary_tmp_table table(
			database_name nvarchar(128),
			database_size varchar(18),
			unallocated_space varchar(18),
			reserved varchar(18),
			data varchar(18),
			index_size varchar(18),
			unused varchar(18));

DECLARE @detail_tmp_table table(
			name nvarchar(128),
			rows bigint,
			reserved nvarchar(80),
			data nvarchar(80),
			index_size nvarchar(80),
			unused nvarchar(80));

/*
** Check to see if user wants usages updated.
*/
if @updateusage is not null
	begin
		select @updateusage=lower(@updateusage)

		if @updateusage ='true'
			begin
			set @isupdateusage = 1
		end
		else
		begin
			if @updateusage = 'false'
			begin
				set @isupdateusage = 0
			end
			else
			begin
				raiserror(15143,-1,-1,@updateusage)
				return(1)
			end
		end
	end

/*
** Validate the @mode parameter.
*/
IF UPPER(@mode) NOT IN('ALL', 'LOCAL_ONLY', 'REMOTE_ONLY')
	BEGIN
		raiserror (14822, -1, -1, @mode);
		return (1)
	END

set nocount on

/*
** Check to see that the objname is local.
*/
if @objname IS NOT NULL
begin

	select @dbname = parsename(@objname, 3)

	if @dbname is not null and @dbname <> db_name()
		begin
			raiserror(15250,-1,-1)
			return (1)
		end

	if @dbname is null
		select @dbname = db_name()

	/*
	**  Try to find the object.
	*/
	SELECT @id = object_id, @type = type FROM sys.objects WHERE object_id = object_id(@objname)

	-- Translate @id to internal-table for queue
	IF @type = 'SQ'
		SELECT @id = object_id FROM sys.internal_tables WHERE parent_id = @id and internal_type = 201 --ITT_ServiceQueue

	/*
	**  Does the object exist?
	*/
	if @id is null
		begin
			raiserror(15009,-1,-1,@objname,@dbname)
			return (1)
		end

	-- Is it a table, view or queue?
	IF @type NOT IN ('U ','S ','V ','SQ','IT')
	begin
		raiserror(15234,-1,-1)
		return (1)
	end
	ELSE
	begin

		/*
		** Now we know the object type is in ('U ','S ','V ','SQ','IT')
		** All types of objects always have physical size except for V (views). Only indexed views have actual sizes.
		** Since an un-indexed view does not occupy physical storage space, querying its space usage is meaningless.
		*/
		IF @type = 'V '
		begin
			IF NOT EXISTS
				(SELECT TOP 1 object_id
				FROM sys.dm_db_partition_stats
				WHERE object_id = @id) -- An un-indexed view DOES NOT have an row in sys.dm_db_partition_stats.
			begin
				SELECT
					OBJECT_NAME (@id) AS name,
					NULL AS rows,
					NULL AS reserved,
					NULL AS data,
					CONVERT(varchar(18), '0 KB') AS index_size,
					CONVERT(varchar(18), '0 KB') AS unused
				return (0)
			end
		end
	end
end

/*
**  Update usages if user specified to do so.
*/

if @isupdateusage = 1
	begin
		if @objname is null
			dbcc updateusage(0) with no_infomsgs
		else
			dbcc updateusage(0,@objname) with no_infomsgs
		print ' '
	end

/*
**  If @id is null, then we want summary data.
*/
if @id is null
begin
	/*
	** Calculate local space usage if mode is LOCAL_ONLY or ALL
	*/
	IF UPPER(@mode) IN ('ALL', 'LOCAL_ONLY')
	BEGIN
		select @dbsize = sum(convert(bigint,case when status & 64 = 0 then size else 0 end))
			, @logsize = sum(convert(bigint,case when status & 64 <> 0 then size else 0 end))
			from dbo.sysfiles

		/*
		** If there exist Azure Storage containers then DW Tiered Storage is enabled. Add the remote storage size for column store data to database size.
		*/
		declare @rv int = 0
		--Get the row count of container internal table by querying the sys.sysindexes.
		select @rv = i.rowcnt  from sys.sysindexes i, sys.sysobjects o  where i.id = o.id and o.name = 'syscscontainersinternal'

		IF @rv > 0
		BEGIN
			select @remotecolsegmentspages = sum (((on_disk_size + 8192 -1) / 8192))
				from sys.syscscolsegments
				where container_id != 0

			select @remotecoldictionariespages = sum (((on_disk_size + 8192 - 1) / 8192))
				from sys.syscsdictionaries
				where container_id != 0

			set @dbsize += (case when @remotecolsegmentspages is not null then @remotecolsegmentspages else 0 end) + (case when @remotecoldictionariespages is not null then @remotecoldictionariespages else 0 end)
		END

		select @reservedpages = sum(a.total_pages),
			@usedpages = sum(a.used_pages),
			@pages = sum(
					CASE
						-- XML-Index and FT-Index and semantic index internal tables are not considered "data", but is part of "index_size"
						When it.internal_type IN (202,204,207,211,212,213,214,215,216,221,222,236) Then 0
						When a.type <> 1 and p.index_id < 2 Then a.used_pages
						When p.index_id < 2 Then a.data_pages
						Else 0
					END
				)
		from sys.system_internals_partitions p join sys.allocation_units a on p.partition_id = a.container_id
			left join sys.internal_tables it on p.object_id = it.object_id

		select @ckptfilesize = sum(convert(bigint,size))
			from sys.database_files
			where data_space_id IN (SELECT data_space_id FROM sys.data_spaces WHERE type=N'FX')

		select @xtpprecreated = sum(convert(bigint,file_size_in_bytes))
			from sys.dm_db_xtp_checkpoint_files
			where state_desc = N'PRECREATED'

		select @xtpused = sum(convert(bigint,file_size_in_bytes))
			from sys.dm_db_xtp_checkpoint_files
			where state_desc = N'UNDER CONSTRUCTION' or state_desc = N'ACTIVE' or state_desc = N'MERGE TARGET'

		select @xtppendingtruncation = sum(convert(bigint,file_size_in_bytes))
			from sys.dm_db_xtp_checkpoint_files
			where state_desc = N'WAITING FOR LOG TRUNCATION'

		/*
		** If there exist checkpoint files in filegroup, set flag @memoryoptimizeddatafg to be true.
		*/
		set @memoryoptimizeddatafg = (case when @ckptfilesize is not null then 1 else 0 end)

		/*
		** Calculate the summary data and insert them into the cache table
		** reserved: sum(reserved) where indid in (0, 1, 255)
		** data: sum(data_pages) + sum(text_used)
		** index: sum(used) where indid in (0, 1, 255) - data
		** unused: sum(reserved) - sum(used) where indid in (0, 1, 255)
		** note that unallocated space could not be negative
		*/
		INSERT INTO @summary_tmp_table
			SELECT
				db_name(),
				LTRIM(STR((CONVERT (dec (15,2),@dbsize) + CONVERT (dec (15,2),@logsize) + 
					CONVERT (dec (15,2),CASE WHEN @ckptfilesize IS NOT NULL THEN @ckptfilesize ELSE 0 END)) *
					8192 / 1048576,15,2) + ' MB'),
				LTRIM(STR((CASE WHEN @dbsize >= @reservedpages THEN
					(CONVERT (dec (15,2),@dbsize) - CONVERT (dec (15,2),@reservedpages)) * 8192 / 1048576 ELSE 0 END) + 
					(CONVERT(dec (15,2), CASE WHEN @xtpprecreated IS NOT NULL THEN @xtpprecreated ELSE 0 END)) / 1048576,15,2) + ' MB'),
				LTRIM(STR(@reservedpages * 8192 / 1024.,15,0) + ' KB'),
				LTRIM(STR(@pages * 8192 / 1024.,15,0) + ' KB'),
				LTRIM(STR((@usedpages - @pages) * 8192 / 1024.,15,0) + ' KB'),
				LTRIM(STR((@reservedpages - @usedpages) * 8192 / 1024.,15,0) + ' KB')
	END
	/*
	** Include remote results if the user specified no arguments , or remote only.
	*/
	IF UPPER(@mode) IN ('ALL', 'REMOTE_ONLY')
	BEGIN
		/*
		** If the database is not stretched, it should not have a remote part, thus skipping remote results.
		*/
		IF NOT EXISTS(SELECT * FROM sys.remote_data_archive_databases)
		BEGIN
			IF UPPER(@mode) = 'REMOTE_ONLY'
			BEGIN
				raiserror(14821, 16, 1);
				return (1)
			END
		END
		/*
		** Since the database is stretched and the remote database should exist, we should include remote results
		*/
		ELSE
		BEGIN

			SET @remotesql = CONCAT(
				N'sys.sp_spaceused_remote_data_archive  ',
				@isupdateusage)
			BEGIN TRY
				INSERT INTO @summary_tmp_table EXECUTE(@remotesql);
			END TRY
			BEGIN CATCH
				set @errornumber = ERROR_NUMBER()
				set @errorseverity = ERROR_SEVERITY()
				set @errorstate = ERROR_STATE()
				set @errorline = ERROR_LINE()
				set @errormessage = ERROR_MESSAGE()
				raiserror(14827, 16, 2, @errornumber, @errorseverity, @errorstate, @errorline, @errormessage)
				IF UPPER(@mode) = 'REMOTE_ONLY'
				BEGIN
					return (1)
				END
			END CATCH
		END
	END
	IF @oneresultset = 1
	BEGIN
		IF @include_total_xtp_storage = 1
		BEGIN
			SELECT
				database_name = db_name(),
				database_size = LTRIM (STR ((SUM  (CONVERT (dec (15, 2), SUBSTRING(s.database_size, 1, CHARINDEX(' ', s.database_size))))),15,2) + ' MB'),
				'unallocated space' = LTRIM (STR ((SUM  (CONVERT (dec (15, 2), SUBSTRING(s.unallocated_space, 1, CHARINDEX(' ', s.unallocated_space))))),15,2) + ' MB'),
				reserved = LTRIM (STR (SUM  (CAST (SUBSTRING(s.reserved, 1, CHARINDEX(' ', s.reserved)) AS bigint)),15,0) + ' KB'),
				data = LTRIM (STR (SUM( CAST( SUBSTRING(s.data, 1, CHARINDEX(' ', s.data)) AS bigint)),15,0) + ' KB'),
				index_size = LTRIM (STR (SUM( CAST( SUBSTRING(s.index_size, 1, CHARINDEX(' ', s.index_size)) AS bigint)),15,0) + ' KB'),
				unused = LTRIM (STR (SUM( CAST( SUBSTRING(s.unused, 1, CHARINDEX(' ', s.unused)) AS bigint)),15,0) + ' KB'),
				xtp_precreated = LTRIM (STR (@xtpprecreated / 1024.,15,0) +' KB'),
				xtp_used = LTRIM(STR(@xtpused / 1024.,15,0) +' KB'),
				xtp_pending_truncation = LTRIM(STR(@xtppendingtruncation / 1024.,15,0) +' KB')
			FROM @summary_tmp_table AS s
		END
		ELSE
		BEGIN
			SELECT
				database_name = db_name(),
				database_size = LTRIM (STR ((SUM  (CONVERT (dec (15, 2), SUBSTRING(s.database_size, 1, CHARINDEX(' ', s.database_size))))),15,2) + ' MB'),
				'unallocated space' = LTRIM (STR ((SUM  (CONVERT (dec (15, 2), SUBSTRING(s.unallocated_space, 1, CHARINDEX(' ', s.unallocated_space))))),15,2) + ' MB'),
				reserved = LTRIM (STR (SUM  (CAST (SUBSTRING(s.reserved, 1, CHARINDEX(' ', s.reserved)) AS bigint)),15,0) + ' KB'),
				data = LTRIM (STR (SUM( CAST( SUBSTRING(s.data, 1, CHARINDEX(' ', s.data)) AS bigint)),15,0) + ' KB'),
				index_size = LTRIM (STR (SUM( CAST( SUBSTRING(s.index_size, 1, CHARINDEX(' ', s.index_size)) AS bigint)),15,0) + ' KB'),
				unused = LTRIM (STR (SUM( CAST( SUBSTRING(s.unused, 1, CHARINDEX(' ', s.unused)) AS bigint)),15,0) + ' KB')
			FROM @summary_tmp_table AS s
		END
	END
	ELSE
	BEGIN
		SELECT
			database_name = db_name(),
			database_size = LTRIM (STR ((SUM  (CONVERT (dec (15, 2), SUBSTRING(s.database_size, 1, CHARINDEX(' ', s.database_size))))),15,2) + ' MB'),
			'unallocated space' = LTRIM (STR ((SUM  (CONVERT (dec (15, 2), SUBSTRING(s.unallocated_space, 1, CHARINDEX(' ', s.unallocated_space))))),15,2) + ' MB')
		FROM @summary_tmp_table AS s
		SELECT
			reserved = LTRIM (STR (SUM  (CAST (SUBSTRING(s.reserved, 1, CHARINDEX(' ', s.reserved)) AS bigint)),15,0) + ' KB'),
			data = LTRIM (STR (SUM( CAST( SUBSTRING(s.data, 1, CHARINDEX(' ', s.data)) AS bigint)),15,0) + ' KB'),
			index_size = LTRIM (STR (SUM( CAST( SUBSTRING(s.index_size, 1, CHARINDEX(' ', s.index_size)) AS bigint)),15,0) + ' KB'),
			unused = LTRIM (STR (SUM( CAST( SUBSTRING(s.unused, 1, CHARINDEX(' ', s.unused)) AS bigint)),15,0) + ' KB')
		FROM @summary_tmp_table AS s
		IF @memoryoptimizeddatafg = 1
		BEGIN
			SELECT
				xtp_precreated = LTRIM(STR(@xtpprecreated / 1024.,15,0) +' KB'),
				xtp_used = LTRIM(STR(@xtpused / 1024.,15,0) +' KB'),
				xtp_pending_truncation = LTRIM(STR(@xtppendingtruncation / 1024.,15,0) +' KB')
		END	
	END
END

/*
** We want a particular object.
*/
ELSE
BEGIN
	/*
	** Include remote results if the user expects remote space usage.
	*/
	IF UPPER(@mode) = 'ALL' or UPPER(@mode) = 'REMOTE_ONLY'
	BEGIN
		/*
		** If the object is stretched, we should include remote space usage into the result.
		*/
		IF EXISTS (SELECT * FROM sys.remote_data_archive_tables WHERE object_id = @id AND remote_table_name IS NOT NULL)
		BEGIN
			SET @remotesql = CONCAT(
				N'sys.sp_spaceused_remote_data_archive  ',
				@isupdateusage,
				N' , ',
				@id)
				BEGIN TRY
					INSERT INTO @detail_tmp_table EXECUTE(@remotesql)
				END TRY
				BEGIN CATCH
					set @errornumber = ERROR_NUMBER()
					set @errorseverity = ERROR_SEVERITY()
					set @errorstate = ERROR_STATE()
					set @errorline = ERROR_LINE()
					set @errormessage = ERROR_MESSAGE()
					raiserror(14827, 16, 3, @errornumber, @errorseverity, @errorstate, @errorline, @errormessage)
					IF UPPER(@mode) = 'REMOTE_ONLY'
					BEGIN
						return (1)
					END
				END CATCH
		END
		/*
		** If the object is not stretched, the object shouldn't have a remote part, thus skipping remote results.
		*/
		ELSE
		BEGIN
			IF UPPER(@mode) = 'REMOTE_ONLY'
			BEGIN
				RAISERROR(14821, 16, 2);
				RETURN (1)
			END
		END
	END

	/*
	** Calculate local space usage if mode is LOCAL_ONLY or ALL
	*/
	IF UPPER(@mode) IN ('ALL', 'LOCAL_ONLY')
	BEGIN
		/*
		** Now calculate the summary data.
		*  Note that LOB Data and Row-overflow Data are counted as Data Pages for the base table
		*  For non-clustered indices they are counted towards the index pages
		*/
		SELECT
			@reservedpages = SUM (reserved_page_count),
			@usedpages = SUM (used_page_count),
			@pages = SUM (
				CASE
					WHEN (index_id < 2) THEN (in_row_data_page_count + lob_used_page_count + row_overflow_used_page_count)
					ELSE 0
				END
				),
			@rowCount = SUM (
				CASE
					WHEN (index_id < 2) THEN row_count
					ELSE 0
				END
				)
		FROM sys.dm_db_partition_stats
		WHERE object_id = @id;

		SELECT @ismemoryoptimizedtable = is_memory_optimized
		FROM sys.tables
		WHERE object_id = @id;

		IF @ismemoryoptimizedtable = 1
		BEGIN
			SELECT @rowCount = SUM (rows) 
			FROM sys.partitions
			WHERE index_id IN (0,1,5) AND object_id = @id;
		END

		/*
		** Check if table has XML Indexes or Fulltext Indexes which use internal tables tied to this table
		*/
		IF (SELECT COUNT(*) FROM sys.internal_tables WHERE parent_id = @id AND internal_type IN (202,204,207,211,212,213,214,215,216,221,222,236)) > 0
		BEGIN
			/*
			**  Now calculate the summary data. Row counts in these internal tables don't
			**  contribute towards row count of original table.
			*/
			SELECT
				@reservedpages = @reservedpages + SUM(reserved_page_count),
				@usedpages = @usedpages + SUM(used_page_count)
			FROM sys.dm_db_partition_stats p, sys.internal_tables it
			WHERE it.parent_id = @id AND it.internal_type IN (202,204,207,211,212,213,214,215,216,221,222,236) AND p.object_id = it.object_id;
		END

		INSERT INTO @detail_tmp_table
			SELECT
				OBJECT_NAME (@id),
				CONVERT (char(20), @rowCount),
				LTRIM (STR (@reservedpages * 8, 15, 0) + ' KB'),
				LTRIM (STR (@pages * 8, 15, 0) + ' KB'),
				LTRIM (STR ((CASE WHEN @usedpages > @pages THEN (@usedpages - @pages) ELSE 0 END) * 8, 15, 0) + ' KB'),
				LTRIM (STR ((CASE WHEN @reservedpages > @usedpages THEN (@reservedpages - @usedpages) ELSE 0 END) * 8, 15, 0) + ' KB')
	END
	/*
	** If the table is memory-optimized, return NULL for reserved, data, index_size and unused.
	*/
	IF @ismemoryoptimizedtable = 1
	BEGIN
		SELECT 
		@id AS ObjectId,
		OBJECT_SCHEMA_NAME(@id) AS SchemaName,
		OBJECT_NAME (@id) AS name,
		CONVERT (char(20), SUM(rows)) AS rows,
		NULL AS reserved,
		NULL AS data,
		NULL AS index_size,
		NULL AS unused
		FROM @detail_tmp_table
	END
	ELSE
	BEGIN
		SELECT
		@id AS ObjectId,
		OBJECT_SCHEMA_NAME(@id) AS SchemaName,
		OBJECT_NAME (@id) AS name,
		CONVERT (char(20), SUM(rows)) AS rows,
		@pages AS pages,
		LTRIM (STR (SUM (CAST (SUBSTRING(reserved, 1, CHARINDEX(' ', reserved)) AS bigint)),15,0) + ' KB' ) AS reserved,
		LTRIM (STR (SUM (CAST (SUBSTRING(data, 1, CHARINDEX(' ', data)) AS bigint)),15,0) + ' KB') AS data,
		LTRIM (STR (SUM (CAST (SUBSTRING(index_size, 1, CHARINDEX(' ', index_size)) AS bigint)),15,0) + ' KB') AS index_size,
		LTRIM (STR (SUM (CAST (SUBSTRING(unused, 1, CHARINDEX(' ', unused)) AS bigint)),15,0) + ' KB') AS unused
		FROM @detail_tmp_table
	END
END

return (0) -- sp_spaceused

