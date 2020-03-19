--- Identifica onde est�o as esperas do banco


WITH    Waits
          AS ( SELECT   wait_type ,
                        wait_time_ms / 1000.0 AS WaitS ,
                        ( wait_time_ms - signal_wait_time_ms ) / 1000.0 AS ResourceS ,
                        signal_wait_time_ms / 1000.0 AS SignalS ,
                        waiting_tasks_count AS WaitCount ,
                        100.0 * wait_time_ms / SUM(wait_time_ms) OVER ( ) AS Percentage ,
                        ROW_NUMBER() OVER ( ORDER BY wait_time_ms DESC ) AS RowNum
               FROM     sys.dm_os_wait_stats
               WHERE   
			   wait_time_ms   > 0 AND
			    wait_type NOT IN ( 'CLR_SEMAPHORE', 'LAZYWRITER_SLEEP',
                                           'RESOURCE_QUEUE', 'SLEEP_TASK',
                                           'SLEEP_SYSTEMTASK',
                                           'SQLTRACE_BUFFER_FLUSH', 'WAITFOR',
                                           'LOGMGR_QUEUE', 'CHECKPOINT_QUEUE',
                                           'REQUEST_FOR_DEADLOCK_SEARCH',
                                           'XE_TIMER_EVENT', 'BROKER_TO_FLUSH',
                                           'BROKER_TASK_STOP',
                                           'CLR_MANUAL_EVENT',
                                           'CLR_AUTO_EVENT',
                                           'DISPATCHER_QUEUE_SEMAPHORE',
                                           'FT_IFTS_SCHEDULER_IDLE_WAIT',
                                           'XE_DISPATCHER_WAIT',
                                           'XE_DISPATCHER_JOIN',
                                           'BROKER_EVENTHANDLER', 'TRACEWRITE',
                                           'FT_IFTSHC_MUTEX',
                                           'SQLTRACE_INCREMENTAL_FLUSH_SLEEP',
                                           'BROKER_RECEIVE_WAITFOR',
                                           'ONDEMAND_TASK_QUEUE',
                                           'DBMIRROR_EVENTS_QUEUE',
                                           'DBMIRRORING_CMD',
                                           'BROKER_TRANSMITTER',
                                           'SQLTRACE_WAIT_ENTRIES',
                                           'SLEEP_BPOOL_FLUSH',
                                           'SQLTRACE_LOCK' )
             )
    SELECT  W1.wait_type AS WaitType ,
            CAST(W1.WaitS AS DECIMAL(14, 2)) AS Wait_S ,
            CAST (W1.ResourceS AS DECIMAL(14, 2)) AS Resource_S ,
            CAST (W1.SignalS AS DECIMAL(14, 2)) AS Signal_S ,
            W1.WaitCount AS WaitCount ,
            CAST (W1.Percentage AS DECIMAL(4, 2)) AS Percentage ,
            CAST (( W1.WaitS / W1.WaitCount ) AS DECIMAL(14, 4)) AS AvgWait_S ,
            CAST (( W1.ResourceS / W1.WaitCount ) AS DECIMAL(14, 4)) AS AvgRes_S ,
            CAST (( W1.SignalS / W1.WaitCount ) AS DECIMAL(14, 4)) AS AvgSig_S
    FROM    Waits AS W1
            INNER JOIN Waits AS W2 ON W2.RowNum <= W1.RowNum
			WHERE CAST (W1.Percentage AS DECIMAL(4, 2)) > 0
    GROUP BY W1.RowNum ,
            W1.wait_type ,
            W1.WaitS ,
            W1.ResourceS ,
            W1.SignalS ,
            W1.WaitCount ,
            W1.Percentage
    HAVING  SUM(W2.Percentage) - W1.Percentage < 95; -- percentage threshold

	