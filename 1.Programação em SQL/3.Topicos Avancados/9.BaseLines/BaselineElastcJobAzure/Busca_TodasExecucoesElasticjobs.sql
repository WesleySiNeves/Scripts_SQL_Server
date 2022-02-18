
select j.job_id,
       j.job_name,
	   j.job_execution_id,
       j.job_version,
       j.step_name,
	   j.target_type,
       j.step_id,
       j.is_active,
       j.lifecycle,
       j.create_time,
       j.start_time,
       j.end_time,
	   time_elapsed = DATEDIFF(SECOND,j.start_time,j.end_time),
       j.current_attempts,
       j.last_message,
       j.target_resource_group_name,
       j.target_server_name,
       j.target_database_name,
       j.target_elastic_pool_name from jobs.job_executions j
WHERE target_type IS NOT NULL
ORDER BY  j.start_time DESC


