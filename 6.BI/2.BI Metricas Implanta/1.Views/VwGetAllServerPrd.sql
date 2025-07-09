CREATE VIEW SqlServer.VwGetAllServerPrd
AS
SELECT Nome,
       Usuario,
       ResourceGroupName,
       AzureSubscriptionId,
       AzureKeyVaultPasswordKey
FROM SqlServer.Servidores
WHERE Ambiente = 'PROD';