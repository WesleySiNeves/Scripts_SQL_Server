--SELECT *  FROM SqlServer.VwGetAllServerPrd

go
CREATE OR ALTER VIEW SqlServer.VwGetAllServerPrd
AS
SELECT Nome AS ServerName,
       Usuario,
       ResourceGroupName,
       AzureSubscriptionId,
       AzureKeyVaultPasswordKey
FROM SqlServer.Servidores
WHERE Ambiente = 'PROD';