
--select  * from HealthCheck.StatsOnTables(NULL)

CREATE OR ALTER FUNCTION HealthCheck.StatsOnTables(@object_id int)
RETURNS TABLE
AS
RETURN 
(
    SELECT 
        st.object_id,
        sh.name AS schema_name,
        tab.name AS table_name,
        st.name AS stats_name,
        st.stats_id,
        sc.stats_column_id,
        co.name AS column_name,
        Sta.rows,
        Sta.rows_sampled,
        Sta.last_updated,
        Sta.modification_counter
    FROM 
        sys.stats st
    JOIN 
        sys.tables tab ON st.object_id = tab.object_id
    JOIN 
        sys.schemas sh ON tab.schema_id = sh.schema_id 
    JOIN 
        sys.stats_columns sc ON st.object_id = sc.object_id AND st.stats_id = sc.stats_id
    JOIN 
        sys.columns co ON tab.object_id = co.object_id AND sc.column_id = co.column_id
    CROSS APPLY 
        sys.dm_db_stats_properties(tab.object_id, st.stats_id) AS Sta
    WHERE 
        tab.object_id = @object_id or  @object_id is null
        AND st.auto_created = 1
    --ORDER BY 
    --    tab.name
);

