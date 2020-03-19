SELECT dm_os_wait_stats.wait_type AS wait,
       dm_os_wait_stats.wait_time_ms AS wt_ms,
       CONVERT(DECIMAL(9, 2), 100.0 * dm_os_wait_stats.wait_time_ms / SUM(dm_os_wait_stats.wait_time_ms) OVER ()) AS wait_pct
  FROM sys.dm_os_wait_stats
 --WHERE wait_type LIKE 'LCK%'
 WHERE
    dm_os_wait_stats.wait_time_ms > 0
 ORDER BY
    dm_os_wait_stats.wait_time_ms DESC;

SELECT DOS.current_tasks_count,
       DOS.current_workers_count,
       DOS.runnable_tasks_count,
       SUM(DOS.runnable_tasks_count) OVER () Totalrunnable_tasks_count,
       *
  FROM sys.dm_os_schedulers AS DOS
 WHERE
    DOS.scheduler_id < 255;

SELECT DES.login_name,
       DES.status,
       COUNT(*)
  FROM sys.dm_exec_sessions AS DES
 GROUP BY
    DES.login_name,
    DES.status
	ORDER BY COUNT(*) DESC




