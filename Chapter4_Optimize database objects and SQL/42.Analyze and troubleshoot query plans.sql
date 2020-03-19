/*########################
# OBS: capiturando plano de execução com o Extend Events
*/

/*########################
# O uso de Eventos Estendidos é uma abordagem leve para capturar planos de consulta. Existem dois
Eventos estendidos que você pode usar para revisar planos de consulta:
*/


/*########################
# OBS: 1 )query_pre_execution_showplan Este evento estendido captura a consulta estimada
planejar uma consulta. Um plano de consulta estimado é preparado sem executar a consulta
*/


/*########################
# OBS: 2)
query_post_execution_showplan Este evento estendido captura a consulta real
planejar uma consulta. Um plano de consulta real é o plano de consulta estimado que inclui
informações de tempo de execução. Por esse motivo, não está disponível até que a consulta seja executada
*/


/*########################
# OBS: Criando um exntend events para capturar um plano de execução
Create and start an Extended Event session to capture an actual query plan
*/


IF EXISTS
(
    SELECT *
    FROM sys.server_event_sessions
    WHERE name = 'ActualQueryPlans'
)
    DROP EVENT SESSION ActualQueryPlans ON SERVER;
GO
CREATE EVENT SESSION ActualQueryPlans
ON SERVER
    ADD EVENT sqlserver.query_post_execution_showplan
    (ACTION
     (
         sqlserver.database_name,
         sqlserver.client_hostname,
         sqlserver.client_app_name,
         sqlserver.plan_handle,
         sqlserver.sql_text,
         sqlserver.tsql_stack,
         package0.callstack,
         sqlserver.query_hash,
         sqlserver.session_id,
         sqlserver.request_id
     )
     WHERE sqlserver.database_name = 'WideWorldImporters'
           AND object_type = 'ADHOC'
    )
    ADD TARGET package0.event_file
    (SET filename = N'C:\ExtendEvents\ActualQueryPlans.xel', max_file_size = (5), max_rollover_files = (4)),
    ADD TARGET package0.ring_buffer
WITH
(
    MAX_DISPATCH_LATENCY = 5 SECONDS,
    TRACK_CAUSALITY = ON
);
GO
ALTER EVENT SESSION ActualQueryPlans ON SERVER STATE = START;
GO


/*########################
# OBS: Abra o Xtend Events e rode a query abaixo 
*/

USE WideWorldImporters;
GO
SELECT *
FROM Warehouse.StockGroups;


/*########################
# OBS: Vc pode desabilitar oou dropar  um extend events
*/

--Disable extended event session
ALTER EVENT SESSION ActualQueryPlans ON SERVER STATE = STOP;
GO


--Drop extended event session
IF EXISTS
(
    SELECT *
    FROM sys.server_event_sessions
    WHERE name = 'ActualQueryPlans'
)
    DROP EVENT SESSION ActualQueryPlans ON SERVER;
GO


/*########################
# OBS: Criando um server side trace
Server-side tracing
*/


/*########################
# OBS: Para definir um rastreamento, use os seguintes procedimentos armazenados do sistema:
*/


/*########################
# OBS: sp_trace_create Este procedimento cria um novo rastreio e define um arquivo no qual
O SQL Server armazena dados de rastreamento. Ele retorna um ID de rastreamento que você faz referência no outro
procedimentos para gerenciar o rastreamento.


sp_trace_setevent Este procedimento deve ser chamado uma vez para cada coluna de dados do
eventos para capturar no rastreamento. Isso significa que você deve chamar este procedimento várias vezes para
qualquer traço único. Quando você chama esse procedimento, você passa os seguintes argumentos,
o identificador de rastreio capturado como saída quando você cria o rastreio, o identificador de evento,
o identificador da coluna e o status de ON (1) ou OFF (0).


*/

/*########################
# OBS: sp_trace_setfilter Este procedimento deve ser chamado uma vez para cada filtro em um evento
coluna de dados
*/


/*########################
# OBS: sp_trace_setstatus This procedure starts, stops, or removes a trace. It must be
stopped and removed before you can open the related trace file.
*/

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



