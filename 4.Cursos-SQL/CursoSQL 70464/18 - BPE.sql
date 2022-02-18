-- Demonstration 18 - BPE

-- Enable buffer pool extension
ALTER SERVER CONFIGURATION
SET BUFFER POOL EXTENSION ON
(FILENAME = 'C:\temp\MyCache.bpe', SIZE = 10GB );

-- View buffer pool extension details
SELECT * FROM sys.dm_os_buffer_pool_extension_configuration;

-- Monitor buffer pool extension
SELECT * FROM sys.dm_os_buffer_descriptors;

-- Disable buffer pool extension
ALTER SERVER CONFIGURATION
SET BUFFER POOL EXTENSION OFF;

-- View buffer pool extension details again
SELECT * FROM sys.dm_os_buffer_pool_extension_configuration;