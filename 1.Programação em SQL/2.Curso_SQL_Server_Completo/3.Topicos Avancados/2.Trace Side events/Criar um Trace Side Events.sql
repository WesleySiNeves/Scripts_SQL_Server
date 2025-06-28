/*########################
# OBS: Aqui Criamos um server side trace
*/

USE master;
GO
DECLARE @TraceID INT;
EXEC sp_trace_create @TraceID OUTPUT,
                     0,
                     N'C:\ExtendEvents\ActualQueryPlanTrc';
EXEC sp_trace_setevent @TraceID,
                       146, -- Showplan XML Statistics Profile
                       27,  -- BinaryData column
                       1;   -- Column is ON for this event
EXEC sp_trace_setevent @TraceID,
                       146,
                       1, -- TextData column
                       1;


EXEC sp_trace_setevent @TraceID,
                       146,
                       14, -- StartTime column
                       1;

EXEC sp_trace_setevent @TraceID,
                       146,
                       15, -- EndTime column
                       1;

-- Set filter for database
EXEC sp_trace_setfilter @TraceID,
                        @ColumnID = 35,          --Database Name
                        @LogicalOperator = 0,    -- Logical AND
                        @ComparisonOperator = 6, -- Comparison LIKE
                        @Value = N'WideWorldImporters';


-- Set filter for application name
EXEC sp_trace_setfilter @TraceID,
                        @ColumnID = 10,          --ApplicationName
                        @LogicalOperator = 0,    -- Logical AND
                        @ComparisonOperator = 6, -- Comparison LIKE
                        @Value = N'Microsoft SQL Server Management Studio - Query';



--- Start Trace (status 1 = start)
EXEC sp_trace_setstatus @TraceID, 1;
GO



/*########################
# OBS: Depois de executar , rode a query 
*/
	USE WideWorldImporters;
GO
SELECT *
FROM Warehouse.StockGroups;



/*########################
# OBS: Agora vamos obter informações do Trace
*/

USE master;
GO
SELECT *
FROM sys.fn_trace_getinfo(0)
WHERE value = 'C:\ExtendEvents\ActualQueryPlanTrc.trc';


-- Set the trace status to stop
EXEC sp_trace_setstatus @traceid = 2, @status = 0;
GO
-- Close and Delete the trace
EXEC sp_trace_setstatus @traceid = 2, @status = 2;
GO


/*########################
# OBS: Get event and column identifiers for use in a trace definition
*/

--Get event identifiers e events para criar eventos 
SELECT e.trace_event_id AS EventID,
       e.name AS EventName,
       c.name AS CategoryName
FROM sys.trace_events e
    JOIN sys.trace_categories c
        ON e.category_id = c.category_id
ORDER BY e.trace_event_id;



--Get column identifiers for events
SELECT
trace_column_id,
name AS ColumnName
FROM sys.trace_columns
ORDER BY trace_column_id;