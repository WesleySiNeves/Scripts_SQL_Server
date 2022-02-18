

ALTER  SERVER CONFIGURATION SET BUFFER POOL EXTENSION ON 
( FILENAME ='D:\BufferSQL\cache.bpe',SIZE=10GB)


--VIEW extension buffer Detais
SELECT * FROM  sys.dm_os_buffer_pool_extension_configuration AS DOBPEC

-- Monitora buffer extension
SELECT DOBD.* FROM  sys.dm_os_buffer_descriptors AS DOBD


ALTER SERVER CONFIGURATION SET BUFFER POOL EXTENSION OFF


--SELECT ((10485760 * 8) /1024) / 1024

--Review current BPE configuration
SELECT [path], state_description, current_size_in_kb,
CAST(current_size_in_kb/1048576.0 AS DECIMAL(10,2)) AS [Size (GB)]
FROM sys.dm_os_buffer_pool_extension_configuration;