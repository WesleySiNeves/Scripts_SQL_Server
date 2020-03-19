declare @cpu_Countdop int
select @cpu_Countdop= cpu_count
from sys.dm_os_sys_info;





SELECT 'Quantidade CPUs na maquina:'+CAST(@cpu_Countdop AS VARCHAR(2))

exec sp_configure 'max degree of parallelism', @cpu_countdop;
RECONFIGURE WITH OVERRIDE;
