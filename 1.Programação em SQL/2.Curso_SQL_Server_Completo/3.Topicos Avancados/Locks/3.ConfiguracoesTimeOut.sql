
use TSQLV4;




EXEC sp_configure 'show advanced options', 1;  
GO  
RECONFIGURE ;  


SELECT * FROM sys.configurations AS C
WHERE C.name LIKE '%query%'



SELECT * FROM sys.configurations AS C
WHERE C.name LIKE '%time%'



SELECT * FROM sys.configurations AS C
WHERE C.name LIKE '%blocked%'



SELECT * FROM sys.configurations AS C
WHERE C.name LIKE '%bu%'




GO  
EXEC sp_configure 'query wait', 10 ;  
GO  
RECONFIGURE;  
GO  

GO  
EXEC sp_configure 'remote query timeout', 10 ;  
GO  
RECONFIGURE ;  


GO 

sp_configure 'show advanced options', 1
GO
RECONFIGURE
GO 
sp_configure 'blocked process threshold', 20
GO 
RECONFIGURE 
GO 


SELECT * FROM sys.configurations AS C
WHERE C.name LIKE '%network packet size (B)%'
GO 



--Essa configuração so vale por query
 SET LOCK_TIMEOUT 5000;  --5 segundos

select * from TSQLV4.Sales.Customers