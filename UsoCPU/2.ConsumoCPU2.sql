/* ==================================================================
--Data: 19/09/2018 
--Autor :Wesley Neves
--Observação: Fonte
https://blogs.msdn.microsoft.com/fcatae/2010/10/28/monitorando-alta-cpu-atravs-da-ring-buffer/
https://blogs.msdn.microsoft.com/sql_pfe_blog/2009/07/17/sql-high-cpu-scenario-troubleshooting-using-sys-dm_exec_query_stats-and-ring_buffer_scheduler_monitor-ring-buffer-in-sys-dm_os_ring_buffers-2/

 
-- ==================================================================
*/

 DECLARE @ts_now bigint = (SELECT cpu_ticks/(cpu_ticks/ms_ticks)FROM sys.dm_os_sys_info); 

    SELECT  Top(60) 'CPU%' as [label],
            DATEADD(ms, -1 * (@ts_now - [timestamp]), GETDATE()) AS [Event Time],
            SQLProcessUtilization AS [CPU (SQL Server)],
                   SystemIdle AS [CPU (All Processes)],
                   100 - SystemIdle - SQLProcessUtilization AS [CPU (Outros Processos)]           
    FROM ( 
          SELECT record.value('(./Record/@id)[1]', 'int') AS record_id, 
                record.value('(./Record/SchedulerMonitorEvent/SystemHealth/SystemIdle)[1]', 'int') 
                AS [SystemIdle], 
                record.value('(./Record/SchedulerMonitorEvent/SystemHealth/ProcessUtilization)[1]', 
                'int') 
                AS [SQLProcessUtilization], [timestamp] 
          FROM ( 
                SELECT [timestamp], convert(xml, record) AS [record] 
                FROM sys.dm_os_ring_buffers 
                WHERE ring_buffer_type = N'RING_BUFFER_SCHEDULER_MONITOR' 
                AND record LIKE '%<SystemHealth>%') AS x 
          ) AS y 
    --ORDER BY record_id DESC;
    ORDER BY [Event Time] DESC;

