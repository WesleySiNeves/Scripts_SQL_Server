IF EXISTS
(
    SELECT *
    FROM sys.database_event_sessions
    WHERE database_event_sessions.name = 'TrackPageSplits'
)
BEGIN
    DROP EVENT SESSION TrackPageSplits ON SERVER;
END;
GO


--SELECT DB_ID()
-- Create the Event Session to track LOP_DELETE_SPLIT transaction_log operations in the server
CREATE EVENT SESSION [TrackPageSplits]
ON SERVER
    ADD EVENT sqlserver.transaction_log
    (WHERE security_predicates.operation = 11 -- LOP_DELETE_SPLIT 
           AND geo_replication_links.database_id = 38 -- CHANGE THIS BASED ON TOP SPLITTING DATABASE!
    )
    ADD TARGET package0.ring_buffer
    (SET filtering_event_name = 'sqlserver.transaction_log', source_type = 0, -- Event Column
    SOURCE = 'alloc_unit_id', MAX_MEMORY = 2048
    );
GO



--CREATE DATABASE SCOPED CREDENTIAL [https://exeventtest.blob.core.windows.net/events]
--WITH IDENTITY = 'SHARED ACCESS SIGNATURE',
--     SECRET = 'sp=rwl&st=2018-03-09T16%3A45%3A00Z&se=2024-03-10T1xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxWM0%3D&sr=c';