
SELECT CONCAT('DROP DATABASE ',QUOTENAME(name)) FROM sys.databases
WHERE name NOT LIKE '%implanta.net.br'
AND name NOT LIKE '%DBMigradoEArquivado%'
AND name NOT LIKE '%ESPELHO%'
AND name NOT LIKE '%conversor%'
AND name NOT LIKE '%hangfire%'
AND name NOT IN ('DNE','DNE_1711','master','prd-automationjobs-db')
AND NAMe not  in('crn-04.implanta.net.br_2024-12-24T06-00Z',
'crmv-sp.implanta.net.br_2025-05-22T20-02Z',
'crefito-04.implanta.net.br_2025-05-20T18-04Z')
ORDER BY name DESC