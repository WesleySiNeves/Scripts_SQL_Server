-- ==================================================================
--1) Observação: Inicialmente vamos definir a quantidade de memoria maxima para o Sql server
/*
 */
-- ==================================================================

EXEC sys.sp_configure 'max server memory (MB)', '3048';
RECONFIGURE WITH OVERRIDE;




-- ==================================================================
--Observação: Definir a grau maximo de paralelismo do Sql server sendo a quantidade de nucleos logicos ddo servidor

-- ==================================================================
DECLARE @cpu_Countdop int
select @cpu_Countdop= cpu_count
from sys.dm_os_sys_info;

SELECT info.cpu_count,
       info.hyperthread_ratio,
       info.os_quantum,
       info.physical_memory_kb,
	   info.scheduler_count,
	   info.scheduler_total_count,
	   info.max_workers_count
  FROM sys.dm_os_sys_info info;


SELECT 'Quantidade CPUs na maquina:'+CAST(@cpu_Countdop AS VARCHAR(2))

exec sp_configure 'max degree of parallelism', @cpu_countdop;
RECONFIGURE WITH OVERRIDE;
