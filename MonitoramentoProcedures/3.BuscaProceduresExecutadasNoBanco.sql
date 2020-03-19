
---- FREEPROCCACHE will purge all cached procedures from the procedure cache --
---- Starting in SQL Server 2008 you can purge a specific plan from plan cache --
--DBCC FREEPROCCACHE
--GO
SELECT  DB_NAME(st.dbid) DBNamee ,
        OBJECT_SCHEMA_NAME(st.objectid, st.dbid) SchemaName ,
        OBJECT_NAME(st.objectid, st.dbid) StoredProcedure ,
        MAX(cp.usecounts) Execution_count
FROM    sys.dm_exec_cached_plans cp
        CROSS APPLY sys.dm_exec_sql_text(cp.plan_handle) st
WHERE   DB_NAME(st.dbid) IS NOT NULL
        AND cp.objtype = 'proc'
		AND DB_NAME(st.dbid) = DB_NAME(DB_ID())
  --      AND OBJECT_NAME(st.objectid, st.dbid) LIKE 'uspGetEmployeeManagers'
GROUP BY cp.plan_handle ,
        DB_NAME(st.dbid) ,
        OBJECT_SCHEMA_NAME(st.objectid, st.dbid) ,
        OBJECT_NAME(st.objectid, st.dbid)
ORDER BY MAX(cp.usecounts) DESC;
GO