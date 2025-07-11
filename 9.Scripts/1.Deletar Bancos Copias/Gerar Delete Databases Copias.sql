
SELECT CONCAT('DROP DATABASE ',QUOTENAME(name)) FROM sys.databases
WHERE name NOT LIKE '%implanta.net.br'
AND name NOT LIKE '%DBMigradoEArquivado%'
AND name NOT LIKE '%ESPELHO%'
AND name NOT LIKE '%conversor%'
AND name NOT LIKE '%hangfire%'
AND name NOT IN ('DNE','DNE_1711','master','prd-automationjobs-db')
ORDER BY name DESC