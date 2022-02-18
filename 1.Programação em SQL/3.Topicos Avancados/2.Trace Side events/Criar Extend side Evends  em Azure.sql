/* ==================================================================
--Data: 30/10/2019 
--Autor :Wesley Neves
--Observação: Use a consulta T-SQL (Transact-SQL) a seguir para listar todos os eventos estendidos possíveis e suas descrições:
 
-- ==================================================================
*/

SELECT obj1.name AS [XEvent-name],
       col2.name AS [XEvent-column],
       obj1.description AS [Descr-name],
       col2.description AS [Descr-column]
  FROM sys.dm_xe_objects AS obj1
       JOIN sys.dm_xe_object_columns AS col2 ON col2.object_name = obj1.name
 ORDER BY
    obj1.name,
    col2.name;

CREATE EVENT SESSION azure_monitor
ON DATABASE
    ADD EVENT sqlserver.sql_statement_completed
    (ACTION (sqlserver.sql_text,
             sqlserver.database_name)
     WHERE ([sqlserver].[database_name] = N'15.3-implanta'))
WITH (MAX_MEMORY = 4096KB,
      EVENT_RETENTION_MODE = ALLOW_SINGLE_EVENT_LOSS,
      MAX_DISPATCH_LATENCY = 10 SECONDS,
      MAX_EVENT_SIZE = 10MB,
      MEMORY_PARTITION_MODE = NONE,
      TRACK_CAUSALITY = OFF,
      STARTUP_STATE = OFF);
GO


ALTER EVENT SESSION azure_monitor ON DATABASE STATE = START;



SELECT * FROM 
   sys.dm_xe_database_sessions AS s
  JOIN sys.dm_xe_database_session_targets AS t
    ON t.event_session_address = s.address

DECLARE @ShredMe XML;
SELECT @ShredMe = CAST(t.target_data AS XML)
  FROM sys.dm_xe_database_sessions AS s
  JOIN sys.dm_xe_database_session_targets AS t
    ON t.event_session_address = s.address
 WHERE s.name = N'azure_monitor';

SELECT q.QP.value('(data[@name="statement"]/value)[1]', 'varchar(max)') AS [SQL CODE],
       q.QP.value('(action[@name="database_name"]/value)[1]', 'varchar(max)') AS [Database],
       q.QP.value('(@timestamp)[1]', 'datetime2') AS [timestamp]
  FROM @ShredMe.nodes('RingBufferTarget/event[@name=''sql_statement_completed'']') AS q(QP);
GO



-- ==================================================================
--Observação: Deleta o Eventos
/*
 */
-- ==================================================================

ALTER EVENT SESSION azure_monitor ON DATABASE STATE = STOP;

ALTER EVENT SESSION azure_monitor
ON DATABASE
    DROP TARGET package0.ring_buffer;

DROP EVENT SESSION azure_monitor ON DATABASE;
GO
