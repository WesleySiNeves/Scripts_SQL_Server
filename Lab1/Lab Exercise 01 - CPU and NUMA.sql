---------------------------------------------------------------------
-- LAB 01
--
-- Exercise 1
---------------------------------------------------------------------

USE master;
GO

---------------------------------------------------------------------
-- Task 1 - Write a query to return details of the CPU and hyperthreading configuration of the server hosting the MIA-SQL instance. 
-- Hint: look for CPU count and hyperthreading ratio values in the output of the DMV sys.dm_os_sys_info.
---------------------------------------------------------------------
SELECT DOSI.cpu_count,
       DOSI.hyperthread_ratio,
       CAST((DOSI.physical_memory_kb / 1024.0) AS DECIMAL(18, 2)) AS MemoryMB,
       CAST((DOSI.virtual_memory_kb / 1024.0) AS DECIMAL(18, 2)) AS MemoryVirtualGB,
       DOSI.os_quantum,
       DOSI.max_workers_count,
       DOSI.scheduler_count,
       DOSI.affinity_type_desc,
       DOSI.socket_count,
       DOSI.cores_per_socket,
       DOSI.numa_node_count
FROM sys.dm_os_sys_info AS DOSI;
---------------------------------------------------------------------
-- Task 2 - Edit the following query to return the following configuration values:
--	 max degree of parallelism
--	 max worker threads
--	 priority boost
---------------------------------------------------------------------
SELECT * FROM sys.configurations 
WHERE name IN
	('affinity mask',
	'affinity64 mask',
	'cost threshold for parallelism',
	'lightweight pooling',
	'max degree of parallelism',
	'max worker threads',
	'priority boost'
	);


---------------------------------------------------------------------
-- Task 3 - Write a query to return details of the NUMA configuration for this server. 
-- Hint: The DMV sys.dm_os_nodes will provide the information you need.
---------------------------------------------------------------------
SELECT N.node_id,
       N.node_state_desc,
       N.cpu_affinity_mask,
       N.online_scheduler_count,
       N.idle_scheduler_count,
       N.active_worker_count,
       N.avg_load_balance,
       N.timer_task_affinity_mask,
       N.online_scheduler_count,
       N.cpu_count
FROM sys.dm_os_nodes N;

---------------------------------------------------------------------
-- Task 4 - Update the following query to join to sys.dm_os_nodes and include the node_state_desc column
-- Hint: You will need to join sys.dm_os_nodes with sys.dm_os_schedulers on node_id and parent_node_id.
---------------------------------------------------------------------
SELECT OSS.scheduler_id,
       OSS.status,
       OSS.parent_node_id,
       DON.node_state_desc
FROM sys.dm_os_schedulers AS OSS
     JOIN
     sys.dm_os_nodes AS DON ON OSS.parent_node_id = DON.node_id
WHERE OSS.status = 'VISIBLE ONLINE';


