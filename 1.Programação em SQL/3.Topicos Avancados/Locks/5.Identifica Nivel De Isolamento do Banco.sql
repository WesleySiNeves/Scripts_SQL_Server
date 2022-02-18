SELECT session_id, CASE  transaction_isolation_level 
WHEN 0 THEN 'Unspecified' 
WHEN 1 THEN 'ReadUncommitted' 
WHEN 2 THEN 'ReadCommitted' 
WHEN 3 THEN 'Repeatable' 
WHEN 4 THEN 'Serializable' 
WHEN 5 THEN 'Snapshot' END AS TRANSACTION_ISOLATION_LEVEL 
FROM sys.dm_exec_sessions 
where session_id IN(110)



	
DECLARE @DatabaseName VARCHAR(200) = DB_NAME();

EXEC HealthCheck.sp_WhoIsActive @filter = @DatabaseName,
                                @filter_type = 'database', -- varchar(10)
                                @show_own_spid = 0,        -- bit
                                @show_system_spids = 0,    -- bit
                                @show_sleeping_spids = 0,  -- tinyint
                                @get_full_inner_text = 1,  -- bit
                                @find_block_leaders = 1,
                                @get_plans = 1,
								@get_locks = 1,
                                @sort_order = '[blocked_session_count]DESC';
	
	
	