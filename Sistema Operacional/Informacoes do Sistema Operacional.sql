/*
Retorna um conjunto diverso de informações úteis sobre o computador e sobre os recursos disponíveis e consumidos pelo SQL Server.
*/


SELECT CONVERT(TIME,DATEADD(MILLISECOND,351825940+86400000,0),114);

IF(@@VERSION NOT LIKE '%Azure%')
BEGIN
		SELECT SO.cpu_ticks,
		SO.ms_ticks ,
       [Quantidade CPUs] = SO.cpu_count,
       [Memoria Fisica MB] = (SO.physical_memory_kb  / 1024),
       [Memoria Virtual MB] = (SO.virtual_memory_kb  / 1024),
	   
       SO.hyperthread_ratio,
       SO.committed_kb,
       SO.committed_target_kb,
       SO.visible_target_kb,
       SO.stack_size_in_bytes,
       SO.os_quantum,
       SO.os_error_mode,
       SO.os_priority_class,
       SO.max_workers_count,
       SO.scheduler_count,
       SO.scheduler_total_count,
       SO.deadlock_monitor_serial_number,
       SO.sqlserver_start_time_ms_ticks,
       SO.sqlserver_start_time,
       SO.affinity_type,
       SO.affinity_type_desc,
       SO.process_kernel_time_ms,
       SO.process_user_time_ms,
       SO.time_source,
       SO.time_source_desc,
       SO.virtual_machine_type,
       SO.virtual_machine_type_desc,
       SO.softnuma_configuration,
       SO.softnuma_configuration_desc,
       SO.process_physical_affinity,
       SO.sql_memory_model,
       SO.sql_memory_model_desc,
       SO.socket_count,
       SO.cores_per_socket,
       SO.numa_node_count
FROM sys.dm_os_sys_info SO;

END


