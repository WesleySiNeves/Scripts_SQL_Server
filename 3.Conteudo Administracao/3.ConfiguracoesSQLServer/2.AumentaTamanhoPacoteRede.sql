
/*
https://docs.microsoft.com/pt-br/sql/database-engine/configure-windows/configure-the-network-packet-size-server-configuration-option?view=sql-server-2017
https://docs.microsoft.com/pt-br/sql/relational-databases/policy-based-management/network-packet-size-should-not-exceed-8060-bytes?view=sql-server-2017
*/

SELECT * FROM sys.configurations AS C
WHERE C.name LIKE '%network packet size (B)%'


USE Implanta
EXEC sp_configure 'show advanced options', 1;  
GO  
RECONFIGURE ;  
GO  
EXEC sp_configure 'network packet size', 6500 ;  
GO  
RECONFIGURE;  
GO  